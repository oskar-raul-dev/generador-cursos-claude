# L07 — Actuator, métricas y trazas

> **Objetivo:** que `inv-api` deje de contestar "¿está sano?" y "¿por qué está lento?" con
> opiniones. Al terminar tendrás un tablero con las cuatro señales doradas, una alerta que se
> dispara cuando el circuito de `L05` se abre, y un `traceId` que empieza en tu `curl`, aparece
> en el log de `inv-api` y llega hasta `inv-supplier` — y vas a poder demostrar cada una de las
> tres con un comando, no con una captura de pantalla.
> **Asume:** [`23`](23-actuator-y-observabilidad.md) leído entero. Este lab no repite su teoría:
> la pone a correr. Si no puedes explicar de memoria por qué
> [`23` §8](23-actuator-y-observabilidad.md#8-️-tags-y-cardinalidad-el-error-que-tumba-prometheus)
> dice que un `sku` no es un tag, vuelve ahí antes de la sección 6, que es donde vas a verlo.
> **Prerrequisitos:** `L06` hecho. `inv-api` cachea en Redis con `@Cacheable`, tiene el
> `InventoryValuationService` con su contador `inventory.repository.calls`, el `SupplierGateway`
> decorado con `@CircuitBreaker`, `@Retry` y `@Bulkhead` de [`L05`](l05-clientes-y-resiliencia.md),
> el `RequestIdFilter` de `L03` poniendo `requestId` en el MDC, el `MdcTaskDecorator` de
> [`L06` §8](l06-cache-y-asincronia.md#8--async-el-hilo-nuevo-y-el-requestid-que-se-queda-atrás) y
> `server.tomcat.threads.max: 10`.
> **Costo:** **$0.00**. Cinco contenedores en `localhost` y una JVM.
> **Duración:** entre 180 y 220 minutos. Las secciones 6, 9 y 10 son el corazón del lab.
> **Qué deja levantado:** los perfiles `db`, `ext` y `cache` que ya venían, más el perfil `obs`
> (`inv-lab-prometheus-1` e `inv-lab-grafana-1`). [`L08`](l08-security-y-batch.md) asume los cuatro arriba.
> **Qué toca:** el `pom.xml`, `application.yml` y dos clases nuevas, `MetricsConfig` bajo
> `com.invlab.invapi.config` y `SupplierHealthIndicator` bajo `com.invlab.invapi.supplier`.
> Fuera del proyecto, el directorio `observability/` del repositorio —`prometheus.yml`,
> `alerts.yml` y `dashboard-golden.json`—, junto al `docker-compose.yml`, que **no se toca**:
> solo se levanta su perfil `obs`.
> **Vigencia:** 18 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21 ·
> Micrometer 1.15.12 · Micrometer Tracing 1.5.12 (los dos por el BOM de Boot) · Prometheus v3.13.3 ·
> Grafana 13.0.9.

**Salto rápido:** [Estado inicial](#1--el-problema-y-el-estado-inicial) ·
[Exposición y el 8081](#2--exposición-con-criterio-y-el-8081-que-ya-tenías) ·
[Health groups](#3--health-groups-y-un-indicator-que-se-pone-rojo-a-demanda) ·
[`loggers` en caliente](#4--loggers-subir-el-nivel-sin-reiniciar-y-encontrar-el-problema) ·
[Métricas propias](#5--métricas-propias-timer-counter-y-el-timed-que-no-aparece) ·
[Cardinalidad](#6-️-el-experimento-de-la-cardinalidad) ·
[Prometheus](#7--prometheus-en-compose-y-el-target-que-no-responde) ·
[Grafana y las cuatro señales](#8--grafana-y-el-tablero-de-las-cuatro-señales) ·
[La alerta del circuito](#9-️-la-alerta-sobre-el-circuito-de-l05) ·
[Trazas de punta a punta](#10--micrometer-tracing-el-traceid-de-punta-a-punta) ·
[`threaddump` bajo saturación](#11--threaddump-en-plena-saturación) ·
[`httpexchanges`](#12--httpexchanges-y-por-qué-no-sustituye-a-las-trazas) ·
[Checklist](#13--checklist-de-salida) ·
[Preguntas rápidas](#-preguntas-rápidas) ·
[Ejercicios](#-ejercicios-16)

---

## 1. 🧭 El problema y el estado inicial

Los seis labs anteriores te dejaron una aplicación que se defiende bien y que **no sabe contar
lo que le pasa**. Cada vez que mataste el proceso perdiste el contador de llamadas al
repositorio, el hit ratio de la caché y el estado del circuito; cada diagnóstico salió de un
`grep` sobre un `app.log` que se borra solo, y cada afirmación sobre latencia salió del
`%{time_total}` de `curl`, que mide **una** petición.

El cambio de músculo de hoy es el último de la serie de criterios de verdad:

```text
L04  →  ¿grabó?             → lo dices con un SELECT
L05  →  ¿salió a la red?    → lo dices con el journal de WireMock
L06  →  ¿ejecutó el método? → lo dices con un contador en memoria
L07  →  ¿cómo se comporta?  → lo dices con una serie de tiempo que sobrevive al proceso,
                              y con una traza que cruza dos servicios
```

Y trae una pregunta nueva que ninguno de los anteriores podía contestar: **¿esto que está
pasando ahora es peor que lo de ayer?** Un contador en memoria no puede responderla nunca,
porque nació hace cuarenta segundos.

Primero confirma que vienes del estado correcto:

```bash
docker compose -p inv-lab ps
cd inv-api
./mvnw -q clean package
java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -o /dev/null -w 'health     -> %{http_code}\n' localhost:8081/actuator/health
curl -s -o /dev/null -w 'valuation  -> %{http_code}\n' localhost:8080/api/items/ABC-000123/valuation
curl -s -o /dev/null -w 'quote      -> %{http_code}\n' localhost:8080/api/items/ABC-000123/quote
docker exec -i inv-lab-redis-1 redis-cli KEYS 'inv:*'
```

- **`docker compose -p inv-lab ps` tiene que listar tres contenedores**: `inv-lab-postgres-1` en
  `(healthy)`, `inv-lab-wiremock-1` y `inv-lab-redis-1` en `Up`. Si falta alguno,
  `docker compose -p inv-lab --profile db --profile ext --profile cache up -d` los devuelve; si
  faltan además las tablas o el item `ABC-000123`, hiciste `down -v` entre sesiones y toca
  recrear el item con el `POST /api/items` de `L05`.
- **`./mvnw -q clean package` sin `-DskipTests`**, igual que en los cuatro labs anteriores: los
  tests de `L03` son la red de seguridad de todo lo que se mueve hoy, y hoy se tocan el `pom.xml`,
  el `application.yml` y tres clases.
- **Los tres `curl` cubren las tres capas que vas a instrumentar**: Actuator responde en el 8081,
  el endpoint cacheado responde en el 8080 y el que sale al proveedor sigue entero. Si el
  `quote` da `500`, el circuito de `L05` quedó abierto de la sesión anterior: espera diez segundos
  (`wait-duration-in-open-state`) y repite.
- **`redis-cli KEYS 'inv:*'`** confirma que la caché de `L06` sigue viva. Hoy vas a graficar su hit
  ratio, así que conviene que tenga algo dentro.

**Lo que vas a construir hoy, en orden, y el porqué del orden.** Primero se decide qué se publica
y por dónde (sección 2), porque todo lo demás entra por ahí; después las dos respuestas baratas
—`health` bien diseñado (sección 3) y `loggers` en caliente (sección 4)—, que son las que resuelven
un incidente sin desplegar. Después las métricas: las propias (sección 5) y el error que las
convierte en un problema de infraestructura (sección 6), en ese orden porque la cardinalidad solo
asusta cuando la mediste tú. Con eso ya hay algo que raspar, y entran Prometheus (sección 7),
el tablero (sección 8) y la alerta (sección 9), que es el criterio de terminado de este lab. La
última parte es la que las métricas no pueden dar: el `traceId` que cruza a `inv-supplier`
(sección 10), el `threaddump` para el "se quedó colgado" (sección 11) y `httpexchanges`, que
parece lo mismo que una traza y no lo es (sección 12).

> **📝 Lo que este lab deja fuera a propósito, y dónde se practica en su lugar.**
> **Un collector de trazas** —Zipkin, Tempo, Jaeger— no entra: el `docker-compose.yml` de la serie
> se fijó en [`L00` §6](l00-idea-lab-practico.md#6--el-docker-composeyml-de-la-serie) y añadirle un
> contenedor más para ver en una UI lo que la sección 10 demuestra con el journal de WireMock y un
> `grep` sería pagar 400 MB de RAM por una captura de pantalla. Lo que hay que entender —quién
> genera el `traceId`, en qué cabecera viaja, qué lo corta— se ve entero sin exportador, y el
> ejercicio 🔥 de esta sección te pide montarlo si quieres la UI.
> **Alertmanager** tampoco: enrutar, silenciar y agrupar notificaciones es operación, no Spring, y
> la regla de alerta —que es la parte que sí depende de cómo instrumentaste— sí se escribe, en la
> sección 9.
> **Asegurar Actuator con autenticación** se nombra en la sección 2 y no se ejecuta: la
> `SecurityFilterChain` sobre `EndpointRequest.toAnyEndpoint()` necesita Spring Security en el
> classpath, que llega con el capítulo de Spring Security y con el lab de seguridad y batch. Ninguno
> de los dos está escrito todavía, así que van sin enlace.
> **Y el catálogo de errores de esta serie** —el apéndice que recopila la primera línea de cada
> excepción que has visto reproducida— se escribe en esta misma tanda y tampoco tiene enlace aún.

---

## 2. 🧱 Exposición con criterio, y el 8081 que ya tenías

La primera sorpresa de este lab es que la mitad ya está hecha, y conviene saber **quién** la hizo
antes de tocar nada:

```bash
grep -n 'management' src/main/resources/application.yml
curl -s localhost:8081/actuator | jq -r '._links | keys[]'
```

- **`management.server.port: 8081` lo puso [`L01`](l01-esqueleto-cli-y-autoconfiguracion.md)** con
  el `application.properties` inicial, y [`L02`](l02-configuracion-y-profiles.md) lo tradujo a YAML
  al montar los profiles. No es una decoración: es lo que hizo que en
  [`L05` §3](l05-clientes-y-resiliencia.md#3-️-la-llamada-sin-timeout-y-el-hilo-que-no-vuelve) el
  `/actuator/health` siguiera respondiendo `200` mientras los diez hilos de Tomcat estaban
  colgados en el proveedor. Ese conector tiene **su propio pool**, y esa es toda la diferencia.
- **`management.endpoint.health.show-details: always` también viene de `L01`**, y es una decisión
  de laboratorio: en un entorno real se deja en `when-authorized`, porque el detalle del health
  nombra tus dependencias internas.
- **La lista de `exposure.include` creció lab a lab** —`conditions` y `beans` en `L01`, `env` y
  `configprops` en `L02`, `metrics` y `threaddump` en `L05` con los tres de Resilience4j, `caches`
  y `scheduledtasks` en `L06`— y hoy le tocan los últimos tres.
- **`curl localhost:8081/actuator` lista lo que está publicado**, con su URL, y es la forma barata
  de contestar "¿esto está expuesto?" sin leer el YAML. Lo que no aparece ahí devuelve `404`, no
  `403`: por defecto Actuator publica **solo `health`**, y todo lo demás existe pero no se sirve
  ([`23` §2](23-actuator-y-observabilidad.md#2--qué-expone-actuator-por-defecto-y-cómo-se-asegura)).

Lo que hoy se añade, en `application.yml`:

```yaml
management:
  server:
    port: 8081
    address: 127.0.0.1            # solo loopback; la sección 7 va a chocar con esto a propósito
  endpoints:
    web:
      exposure:
        include: health,env,configprops,metrics,threaddump,caches,scheduledtasks,circuitbreakers,circuitbreakerevents,retryevents,prometheus,loggers,httpexchanges
  endpoint:
    health:
      probes:
        enabled: true             # publica los grupos liveness y readiness como probes
```

- **`address: 127.0.0.1`** liga el conector de management al loopback, que es la segunda capa de
  defensa de [`23` §2](23-actuator-y-observabilidad.md#2--qué-expone-actuator-por-defecto-y-cómo-se-asegura):
  aunque alguien exponga `env` por error, desde fuera de la máquina no se alcanza. **En un pod, esto
  es casi obligatorio**, porque el puerto de negocio cruza el firewall y el de management no. Lo
  escribes ahora sabiendo que en la sección 7 te va a romper el scrape de Prometheus: ese choque es
  el contenido de aquella sección, no un descuido de esta.
- **`prometheus`, `loggers` y `httpexchanges` son los tres que faltaban**, uno por sección: el
  primero es el que raspa Prometheus, el segundo es la escritura que usa la sección 4 y el tercero
  es el que la sección 12 monta para desmontarlo.
- **`probes.enabled: true`** publica `/actuator/health/liveness` y `/actuator/health/readiness`
  aunque no estés en Kubernetes. Sin esta propiedad, Boot solo las activa cuando detecta un entorno
  de orquestación, y aquí las necesitas en tu máquina.
- **`heapdump` y `shutdown` no están en la lista y no van a estarlo.** `heapdump` baja la memoria
  del proceso entera —con los datos de clientes que hubiera dentro— y `shutdown` apaga la
  aplicación con un `POST`. Los dos son endpoints legítimos y los dos se abren con autenticación
  delante, que es material del capítulo de Spring Security y del lab que lo acompaña, todavía sin
  escribir.

> **⚠️ Actuator no autentica nada por sí mismo.** Sin Spring Security en el classpath —y hoy no lo
> hay— todo lo que expongas está abierto a quien alcance el puerto. Las tres capas son **exponer
> poco**, **ligar el conector a la red interna** (lo acabas de hacer) y **exigir un rol** con una
> `SecurityFilterChain` sobre `EndpointRequest.toAnyEndpoint()`. La tercera llega con Spring
> Security; hoy tienes las dos primeras y conviene decirlo en voz alta en vez de creerse cubierto.

**Predice antes de ejecutar.** Acabas de exponer `prometheus`. ¿Qué devuelve
`GET /actuator/prometheus`: `200` con las métricas, `404`, o `500`?

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -o /dev/null -w 'prometheus -> %{http_code}\n' localhost:8081/actuator/prometheus
curl -s localhost:8081/actuator | jq -r '._links | keys[]' | grep -c prometheus
```

```text
prometheus -> 404
0
```

- **`404` y ni siquiera aparece en el índice**, aunque lo pusiste en `include`. Esta es la primera
  de las dos causas de un `404` en Actuator y la que más tiempo hace perder, porque el YAML dice
  claramente que está expuesto: **el endpoint no existe**. `PrometheusScrapeEndpoint` se
  autoconfigura solo si hay un `PrometheusMeterRegistry` en el contexto, y para eso hace falta una
  dependencia que todavía no está.
- **La segunda causa es la contraria** —el endpoint existe pero no está en `include`—, y se
  distingue en un comando: si no aparece en el índice y **tampoco** tras añadirlo a `include`, es
  dependencia; si aparece al añadirlo, era exposición.
- **`exclude` gana a `include`**, y es la tercera causa, la más difícil de ver: un endpoint
  listado en los dos sale `404` sin un solo aviso.

La dependencia, en el `pom.xml`:

```xml
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

- **Sin `<version>`**, porque Micrometer entra por el BOM de Boot 3.5.16, que fija **1.15.12**
  (§5.2 de la guía). Escribirle versión a mano aquí es cómo se rompe un upgrade de Boot.
- **`micrometer-registry-prometheus` es el registro, no el servidor.** Traduce tus medidores al
  formato de texto de Prometheus y publica el endpoint; quien guarda el histórico es el proceso de
  Prometheus, que aún no existe y llega en la sección 7. El modelo es *pull*: nadie envía nada.
- **Hay un segundo artefacto con nombre casi igual**, `micrometer-registry-prometheus-simpleclient`,
  que es el que habla con el cliente Java 0.x de Prometheus y está deprecado. El que se usa hoy es
  el de arriba 📝.

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -o /dev/null -w 'prometheus -> %{http_code}\n' localhost:8081/actuator/prometheus
curl -s localhost:8081/actuator/prometheus | grep -c '^# TYPE'
curl -s localhost:8081/actuator/prometheus | grep '^jvm_threads_live_threads'
```

```text
prometheus -> 200
```

- **El `200` es lo único fijo de esta salida**, y por eso los otros dos comandos se dejan sin
  bloque de resultado: el número de `# TYPE` depende de cuántos medidores tenga registrados tu
  proceso en ese instante —las métricas de caché aparecen cuando la caché se usa, las de
  Resilience4j cuando el gateway se invoca— y el valor de `jvm_threads_live_threads` cambia entre
  dos ejecuciones seguidas. Lo que sí tiene que verse es la **forma**: una línea `# HELP`, una
  `# TYPE` y una o más líneas `nombre{tags} valor`.
- **Fíjate en el nombre traducido.** Tú registraste `jvm.threads.live` con puntos y el exportador
  publica `jvm_threads_live_threads`: guiones bajos, y un sufijo con la **unidad base**. Lo mismo
  le pasa a tu contador de `L06`, que sale como `inventory_repository_calls_total` —el sufijo
  `_total` es obligatorio para un counter en el formato de Prometheus—. Esa traducción la hace el
  registro, no tú, y es la razón por la que [`23` §7](23-actuator-y-observabilidad.md#7--micrometer-meterregistry-los-cuatro-medidores-y-las-anotaciones)
  insiste en escribir los nombres con puntos.

> **⏱️ Costo en runtime.** El endpoint serializa **todo** el registro en cada scrape: con unos
> cientos de series son decenas de kilobytes y unos pocos milisegundos de CPU cada quince segundos,
> que es despreciable. Con las decenas de miles de series que vas a fabricar a propósito en la
> sección 6, deja de serlo — y ahí está la mitad del daño de la cardinalidad.

---

## 3. 🩺 Health groups, y un indicator que se pone rojo a demanda

`/actuator/health` responde `{"status":"UP"}` desde `L01` y hasta hoy no ha dicho nada útil: mira
la base de datos, el disco y Redis, y no sabe nada del proveedor del que depende la mitad de tu
API. El problema real es peor que eso, y es el que decide si tu servicio se reinicia solo a las
tres de la mañana: **quién mira qué, y qué hace el orquestador con la respuesta**.

```java
// src/main/java/com/invlab/invapi/supplier/SupplierHealthIndicator.java
@Component                                  // el bean se llama supplierHealthIndicator
class SupplierHealthIndicator implements HealthIndicator {

    private final RestClient restClient;

    SupplierHealthIndicator(RestClient.Builder builder, SupplierProperties properties) {
        // el builder inyectado trae los timeouts de L05; RestClient.create() no los traería
        this.restClient = builder.baseUrl(properties.baseUrl()).build();
    }

    @Override
    public Health health() {
        try {
            restClient.get().uri("/__admin/mappings").retrieve().toBodilessEntity();
            return Health.up().build();
        } catch (RestClientException ex) {
            // solo el tipo: el mensaje crudo publica hosts y puertos internos
            return Health.down().withDetail("error", ex.getClass().getSimpleName()).build();
        }
    }
}
```

- **El nombre del bean es la clave del informe**: Boot recorta el sufijo `HealthIndicator` y esta
  clase aparece como `"supplier"` dentro de `components`. Si la llamas `SupplierCheck`, aparece
  como `supplierCheck`, y el grupo que la incluye deja de encontrarla por el nombre viejo.
- **`SupplierProperties` se inyecta como bean**, el mismo `@ConfigurationProperties` validado que
  usa el `SupplierGateway` desde `L05`: la URL del proveedor se escribe en un sitio, no en dos.
- **`RestClient.Builder` inyectado y no `RestClient.create()`**, por la misma razón que en
  [`L05` §3](l05-clientes-y-resiliencia.md#3-️-la-llamada-sin-timeout-y-el-hilo-que-no-vuelve): el
  builder del contexto ya trae `connect-timeout: 2s` y `read-timeout: 3s`. Un health check sin
  timeout es el peor de todos los sitios donde falta uno, porque **corre en el hilo que atiende la
  petición al endpoint** y el que pregunta suele ser el orquestador.
- **`/__admin/mappings` es la API de administración de WireMock** y devuelve la lista de stubs
  cargados. No nos interesa el cuerpo —por eso `toBodilessEntity()`, que descarta la respuesta sin
  deserializarla—, solo que conteste. Contra un proveedor real, el equivalente es su endpoint de
  ping documentado, nunca un endpoint de negocio: un health check que crea cotizaciones es un
  generador de basura con permiso.
- **`withDetail("error", ...)` publica ese par** cuando `show-details` está en `always`, que es tu
  caso desde `L01`. Ahí va el **tipo** de la excepción y no su mensaje: un
  `ResourceAccessException` con el mensaje completo publica el host y el puerto internos del
  proveedor en un endpoint sin autenticar.
- **Devolver `Health.unknown()` es la tercera opción** y existe para cuando no puedes decidir; se
  traduce a HTTP `200`, así que no saca la instancia del balanceador.

Y los grupos, en `application.yml`:

```yaml
management:
  endpoint:
    health:
      group:
        readiness:
          include: readinessState,db,redis,supplier     # todo lo que hace falta para atender
        liveness:
          include: livenessState                        # solo "el proceso está vivo"
```

- **Los grupos se consultan por separado**, en `/actuator/health/readiness` y
  `/actuator/health/liveness`, y cada uno agrega **solo** los indicators que lista.
- **`readiness` en `DOWN` saca la instancia del balanceador** y la devuelve sola cuando la
  dependencia se recupera. Por eso aquí van las externas: no poder hablar con Postgres, con Redis o
  con el proveedor significa que no puedes atender, pero no que estés roto.
- **`liveness` en `DOWN` provoca un reinicio**, y ese es el error caro que
  [`23` §4](23-actuator-y-observabilidad.md#4--health-grupos-indicators-propios-y-show-details)
  nombra: con Postgres caído, un `db` dentro de `liveness` hace que el orquestador reinicie
  **todas** tus réplicas a la vez, justo cuando la base va a volver y va a recibir N arranques
  simultáneos. En `liveness` va lo que solo se arregla reiniciando: un deadlock del proceso, un
  heap agotado.
- **`readinessState` y `livenessState` son los indicators de Boot**, no los tuyos: los alimenta el
  `ApplicationAvailability` del framework, y son los que marcan `OUT_OF_SERVICE` durante el
  arranque y durante el `graceful shutdown` de `L09`.

**Predice antes de ejecutar.** Vas a parar WireMock. ¿Qué devuelve `/actuator/health`, qué
devuelve `/actuator/health/liveness`, y con qué código HTTP cada uno?

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s localhost:8081/actuator/health | jq -c '{status, supplier: .components.supplier}'
docker compose -p inv-lab stop wiremock
sleep 1
curl -s -o /dev/null -w 'health    -> %{http_code}\n' localhost:8081/actuator/health
curl -s -o /dev/null -w 'readiness -> %{http_code}\n' localhost:8081/actuator/health/readiness
curl -s -o /dev/null -w 'liveness  -> %{http_code}\n' localhost:8081/actuator/health/liveness
curl -s localhost:8081/actuator/health | jq -c '{status, supplier: .components.supplier}'
```

```text
{"status":"UP","supplier":{"status":"UP"}}
health    -> 503
readiness -> 503
liveness  -> 200
{"status":"DOWN","supplier":{"status":"DOWN","details":{"error":"ResourceAccessException"}}}
```

- **Un solo indicator en `DOWN` arrastra el agregado entero**, porque `health` toma el peor estado
  de todos sus componentes. No hay grados: con Postgres, Redis y el disco perfectos, el agregado
  dice `DOWN` porque el proveedor no contesta, y esa es justamente la razón por la que los grupos
  existen — el agregado sirve para mirarlo tú, los grupos sirven para que decida una máquina.
- **`503` en `health` y en `readiness`, `200` en `liveness`.** Esa es exactamente la repartición
  que querías: el balanceador deja de mandarte tráfico y **nadie te reinicia**, porque el proceso
  está perfectamente vivo — el que está caído es otro.
- **`ResourceAccessException` es el tipo que envuelve un fallo de transporte** en los clientes de
  Spring: conexión rechazada, host inalcanzable, timeout de lectura. Es el mismo que viste en
  `L05`, y publicar solo su nombre es suficiente para el diagnóstico sin filtrar nada.
- **`DOWN` y `OUT_OF_SERVICE` se traducen a `503`**; `UP` y `UNKNOWN`, a `200`. El mapeo se toca con
  `management.endpoint.health.status.http-mapping`, y casi nunca hay razón para hacerlo.

Devuelve el proveedor a la vida y comprueba que el health se recupera solo:

```bash
docker compose -p inv-lab start wiremock
sleep 3
curl -s -o /dev/null -w 'health -> %{http_code}\n' localhost:8081/actuator/health
```

```text
health -> 200
```

- **Se recupera sin reiniciar nada**, porque el indicator se evalúa en cada consulta. Esa es
  justamente la razón por la que tiene que ser barato: si tu health check tarda dos segundos y el
  kubelet lo pregunta cada diez, has comprado un 20 % de un hilo para siempre ⏱️.
- **`start` y no `up -d`**: el contenedor sigue existiendo porque lo paraste con `stop`, y `start`
  lo revive con la misma configuración. El teardown completo de WireMock —`rm -sf`— está escrito en
  [`L05` §2](l05-clientes-y-resiliencia.md#2--wiremock-como-inv-supplier-y-su-teardown), donde se
  creó el recurso, y sigue siendo el que vale.

> **🧠 Modelo mental.** `health` no dice "funciona". Dice "los indicators que yo agrego contestaron
> `UP`". No sabe nada de latencia, ni de tasa de error, ni de si el circuito de `L05` está
> devolviendo fallbacks a todo el mundo con un `200` impecable. Para eso están las métricas, y por
> eso el resto del lab existe.

---

## 4. 💡 `loggers`: subir el nivel sin reiniciar, y encontrar el problema

Escena real, y la vas a reconocer: alguien reporta que el endpoint de valoración "a veces tarda".
Tu sospecha es que la caché de `L06` no está acertando y que cada petición baja a Postgres. Podrías
reiniciar con `--logging.level.org.hibernate.SQL=DEBUG`, como hiciste en `L03`… y al reiniciar
**vacías la caché local, reinicias los contadores y destruyes exactamente el estado que querías
observar**. El diagnóstico se lleva por delante la evidencia.

Eso es lo que resuelve el endpoint `loggers`, que ya expusiste en la sección 2.

```bash
curl -s localhost:8081/actuator/loggers/org.hibernate.SQL | jq -c
```

```text
{"effectiveLevel":"INFO"}
```

- **`effectiveLevel` es el nivel que está actuando**, heredado del logger padre; **`configuredLevel`
  es el que alguien fijó explícitamente** para este logger, y aquí ni siquiera aparece porque no hay
  ninguno. La distinción importa: para devolver las cosas a su sitio hay que borrar el
  `configuredLevel`, no poner `INFO` a mano, que dejaría este logger clavado aunque mañana cambies
  el nivel del paquete padre.
- **El `GET` es de lectura y no necesita nada más**; el `POST` que viene ahora sí, y ahí está el
  primer error de esta sección.

**Reproduce el error antes de la corrección**, que es el que da todo el mundo la primera vez:

```bash
curl -s -o /dev/null -w 'sin content-type -> %{http_code}\n' -X POST \
  localhost:8081/actuator/loggers/org.hibernate.SQL -d '{"configuredLevel":"DEBUG"}'
```

```text
sin content-type -> 415
```

- **`415 Unsupported Media Type`**, no `400` ni `404`. `curl -d` manda
  `application/x-www-form-urlencoded` por defecto, y el endpoint solo acepta JSON. Es el mismo
  `415` que reprodujiste en [`L03` §4](l03-api-rest-filtros-y-errores.md#4--cinco-peticiones-mal-hechas-415-400-406-y-dos-500-que-mienten), con la misma causa y en el otro extremo de la aplicación.
- **Un `403` aquí querría decir otra cosa**: que hay seguridad delante y que tu usuario no tiene
  permiso de escritura sobre los endpoints. Hoy no la hay, así que ese caso no puede pasarte — pero
  conviene saber distinguir los dos, porque con Spring Security puesto es el síntoma normal.

Ahora sí, el diagnóstico completo, sin reiniciar el proceso:

```bash
curl -s -o /dev/null -w 'subir a DEBUG -> %{http_code}\n' -X POST \
  localhost:8081/actuator/loggers/org.hibernate.SQL \
  -H 'Content-Type: application/json' -d '{"configuredLevel":"DEBUG"}'
docker exec -i inv-lab-redis-1 redis-cli DEL 'inv:inventory-items::ABC-000123'
curl -s -o /dev/null localhost:8080/api/items/ABC-000123/valuation
curl -s -o /dev/null localhost:8080/api/items/ABC-000123/valuation
grep -c 'org.hibernate.SQL' app.log
```

```text
subir a DEBUG -> 204
1
```

- **`204 No Content` es la respuesta correcta de una escritura en `loggers`**: acepta y no devuelve
  cuerpo. Si esperabas un `200` con el nuevo estado, no lo hay; se comprueba con otro `GET`.
- **`redis-cli DEL` enfría la clave a propósito** para que la primera petición sea un `miss` seguro.
  Sin eso estarías midiendo una caché caliente y concluirías que todo está bien, que es el error de
  método más común en este tipo de diagnóstico.
- **Una sola línea de SQL para dos peticiones** es el veredicto: la caché acierta, el problema está
  en otro lado. Si hubieras visto **dos**, el `@Cacheable` no estaría interceptando y tocaría mirar
  el proxy, que es la sección 3 de `L06` otra vez.
- **El nivel se aplica al logger y a todos sus hijos**, así que `org.hibernate` habría traído
  también el `binder` con los parámetros de cada consulta. Se sube por el paquete **más estrecho**
  que conteste la pregunta.

Y lo que casi nadie hace, que es bajarlo:

```bash
curl -s -o /dev/null -w 'devolver al heredado -> %{http_code}\n' -X POST \
  localhost:8081/actuator/loggers/org.hibernate.SQL \
  -H 'Content-Type: application/json' -d '{"configuredLevel":null}'
curl -s localhost:8081/actuator/loggers/org.hibernate.SQL | jq -c
```

```text
devolver al heredado -> 204
{"effectiveLevel":"INFO"}
```

- **`{"configuredLevel":null}` borra la configuración explícita** y devuelve el logger a lo que
  herede de su padre. Mandar `{"configuredLevel":"INFO"}` habría dejado el logger fijado en `INFO`
  para siempre, que es distinto y se nota el día que subes el nivel del paquete entero y este no
  se mueve.
- **El cambio vivía solo en memoria de todos modos**: muere con el proceso y con el próximo
  despliegue, y **afecta únicamente a la instancia que consultaste**. Con seis réplicas detrás de un
  balanceador, o repites la llamada seis veces o el log que buscas está en la que no tocaste — que
  es, de largo, el motivo número uno de "lo subí a DEBUG y no salió nada".

> **⏱️ Costo en runtime.** `DEBUG` en `org.hibernate.SQL` imprime una línea por consulta;
> `org.hibernate` entero imprime además cada parámetro, y `DEBUG` en el paquete raíz multiplica el
> volumen por órdenes de magnitud, con su E/S, su ingesta y su factura de indexación. La disciplina
> es la misma de un `strace`: se enciende sobre el paquete más estrecho, se captura lo que se
> buscaba y **se apaga en el mismo minuto**.

---

## 5. 🧱 Métricas propias: `Timer`, `Counter` y el `@Timed` que no aparece

Boot ya te instrumenta HTTP, la JVM, Hikari, Logback, las cachés y Resilience4j. Lo que ningún
framework puede instrumentar por ti es **el dominio**: cuántas valoraciones se piden, cuánto tardan
las que bajan a la base y cuántas se rechazan por SKU inexistente. Esos tres números son los que
acaban en un tablero de negocio, y los tres se registran a mano.

El contador ya existe desde `L06`. Lo que falta es un `Timer`:

```java
// en InventoryValuationService, junto al Counter de L06
private final Counter repositoryCalls;
private final Timer valuationTimer;

InventoryValuationService(InventoryItemRepository repository, MeterRegistry registry) {
    this.repository = repository;
    this.repositoryCalls = registry.counter("inventory.repository.calls");
    this.valuationTimer = Timer.builder("inventory.valuation")
            .description("tiempo de calcular una valoración contra la base")
            .publishPercentileHistogram()          // buckets, no percentiles precalculados
            .register(registry);
}

@Cacheable(cacheNames = "inventory-items", key = "#sku")
ItemView valuation(String sku) {
    return valuationTimer.record(() -> {           // mide solo lo que de verdad se ejecuta
        repositoryCalls.increment();
        log.info("valoración de {} calculada contra la base", sku);
        return repository.findValuationBySku(sku)
                .orElseThrow(() -> new ItemNotFoundException(sku));
    });
}
```

- **`Timer.builder(...).register(registry)` en el constructor**, igual que el contador de `L06`:
  resolver el medidor una vez y guardar la referencia, en vez de buscarlo en un mapa concurrente en
  cada invocación ⏱️.
- **`publishPercentileHistogram()` publica buckets acumulativos** —`inventory_valuation_seconds_bucket`
  con una serie por `le`— para que el p95 se calcule **al agregar**, en Prometheus, sobre las seis
  réplicas juntas. Los percentiles calculados dentro de la JVM (`publishPercentiles(0.95)`) salen
  como un número por instancia y **no se pueden promediar**: la media de dos p99 no es el p99 de
  nada, y ese error está en la mitad de los tableros que verás.
- **`timer.record(Supplier)` mide el bloque y devuelve su valor**, así que el `return` sigue
  funcionando igual. La alternativa, `Timer.Sample` con `start`/`stop`, es la que se usa cuando el
  inicio y el fin están en métodos distintos.
- **Está **dentro** del `@Cacheable` y eso es deliberado**: el interceptor de caché envuelve al
  método, así que un acierto ni siquiera entra aquí. El `Timer` mide **el coste real de calcular**,
  no la latencia del endpoint, que ya la mide `http.server.requests`. Medir las dos cosas con el
  mismo medidor es cómo se consigue un p95 que baja cuando la caché acierta y que no dice nada de
  la base.
- **La excepción también cuenta**: si `findValuationBySku` lanza, el `Timer` registra igual el
  tiempo transcurrido, porque `record` mide en un `finally`. Un `Timer` no distingue éxito de
  fallo salvo que le pongas un tag, y ese tag tiene que tener un conjunto **cerrado** de valores.

Falta que `http.server.requests` publique también buckets, o el p95 del tablero no se podrá
calcular:

```yaml
management:
  metrics:
    distribution:
      percentiles-histogram:
        http.server.requests: true      # buckets para el p95 agregado en Prometheus
      slo:
        http.server.requests: 50ms,200ms,500ms,2s
```

- **`percentiles-histogram` por nombre de métrica**: acepta el nombre exacto o un prefijo, y
  `true` enciende los buckets acumulativos. Sin esta línea, `http_server_requests_seconds_bucket`
  no existe y `histogram_quantile` en Prometheus devuelve vacío — que es el síntoma de "mi panel de
  p95 está en blanco y la métrica sí está".
- **`slo` añade buckets exactos en esos límites**, que en Micrometer son *service level objectives*:
  te permiten preguntar "¿qué proporción de peticiones bajó de 200 ms?" con una sola división, que
  es como se calcula un error budget. Cuatro valores elegidos, no veinte: **cada bucket es una serie
  más por combinación de tags** ⏱️.
- **Los dos son configuración, no código.** Poder cambiar la resolución del histograma sin
  recompilar es una de las cosas que compras al instrumentar contra Micrometer y no contra el
  cliente de un backend concreto.

Ahora la anotación, que es donde está el error de esta sección. Sobre el método del *facade* de
`L06`, que recorre varios SKU:

```java
// en InventoryValuationFacade
@Timed(value = "inventory.valuations.batch", description = "valoración de varios SKU de una vez")
List<ItemView> valuations(List<String> skus) {
    return skus.stream().map(valuations::valuation).toList();
}
```

- **`@Timed` es de `io.micrometer.core.annotation`**, no de Spring, y su `value` es el nombre de la
  métrica con la convención de Micrometer: minúsculas y puntos.
- **Va sobre el *facade* de `L06` y no sobre `InventoryValuationService`** porque el método que
  interesa medir es el que recorre la lista entera; y porque una anotación de este tipo sobre un
  método al que se llama desde dentro de su propia clase no mediría nada, que es lo que la tercera
  viñeta de más abajo explica.

**Predice antes de ejecutar.** Compila, arranca, llama al endpoint y pregunta por la métrica.
¿`200` con el número, o `404`?

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -o /dev/null 'localhost:8080/api/items/valuations?skus=ABC-000123'
curl -s -o /dev/null -w 'metrica @Timed -> %{http_code}\n' \
  localhost:8081/actuator/metrics/inventory.valuations.batch
curl -s -o /dev/null -w 'metrica Timer  -> %{http_code}\n' \
  localhost:8081/actuator/metrics/inventory.valuation
grep -ci 'timedaspect' app.log
```

```text
metrica @Timed -> 404
metrica Timer  -> 200
0
```

- **El `Timer` que registraste a mano funciona y la anotación no existe**, y no hay una sola línea
  de log que lo diga. Es el fallo silencioso de siempre con otro sombrero: la anotación compila,
  se lee bien en la revisión de código y **no hace absolutamente nada**.
- **Son dos causas a la vez y hay que arreglar las dos.** La primera:
  `management.observations.annotations.enabled` vale **`false`** por defecto, así que Boot no
  registra el `TimedAspect` ni el `CountedAspect`. La segunda: ese aspecto está condicionado a que
  `org.aspectj.weaver.Advice` esté en el classpath, y `spring-boot-starter-aop` no está entre tus
  dependencias — nunca hizo falta, porque Resilience4j trae el suyo.
- **Y hay una tercera que hoy no te toca pero cae en entrevista**: `@Timed` se aplica con un
  **aspecto sobre un proxy**, así que una llamada desde otro método de la misma clase no mide nada.
  Es la self-invocation de [`05` §5](05-proxies-y-aop.md#5-️-self-invocation-el-fallo-silencioso-número-uno)
  por enésima vez, y por eso la anotación está en el *facade* y no en el servicio.

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-aop</artifactId>
</dependency>
```

```yaml
management:
  observations:
    annotations:
      enabled: true          # registra TimedAspect y CountedAspect; por defecto es false
```

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -o /dev/null 'localhost:8080/api/items/valuations?skus=ABC-000123'
curl -s -o /dev/null -w 'metrica @Timed -> %{http_code}\n' \
  localhost:8081/actuator/metrics/inventory.valuations.batch
curl -s localhost:8081/actuator/metrics/inventory.valuations.batch | jq -c '.measurements'
```

```text
metrica @Timed -> 200
```

- **El `200` es el dato; el contenido de `measurements` no lo es.** Trae tres medidas
  —`COUNT`, `TOTAL_TIME` y `MAX`— y los dos últimos son tiempos en segundos que cambian en cada
  ejecución, así que no tiene sentido fijarlos aquí. Lo que sí puedes comprobar es que `COUNT` vale
  `1` tras una sola llamada.
- **`@Timed` y el `Timer` a mano hacen lo mismo**, y la elección es de estilo: la anotación no
  ensucia el método y no puede medir un tramo interno; el `Timer` explícito mide exactamente lo que
  quieres y se ve en el código. En este lab tienes los dos a propósito, para poder comparar.
- **Lo que la anotación te quita es el control de los tags**, y eso es justo lo que la sección
  siguiente va a convertir en un problema.

---

## 6. ⚠️ El experimento de la cardinalidad

Esta es la sección que más pesa en una entrevista de senior, porque es la única forma de fallar con
métricas que no se arregla con un despliegue: cuando tumbas el backend de métricas, te quedas sin
**todas** las métricas, incluidas las de los servicios de los demás.

El requisito parece de lo más razonable: *"queremos saber qué SKU se piden más"*. Y la
implementación obvia es un tag.

```java
// en InventoryValuationService — escrito mal a propósito
// el MeterRegistry ya llegaba por el constructor desde L06; aquí se guarda en un campo
private final MeterRegistry registry;

ItemView valuation(String sku) {
    // un tag con el identificador: una serie de tiempo NUEVA por cada SKU distinto
    registry.counter("inventory.valuation.requests", "sku", sku).increment();
    …
}
```

- **`registry.counter(nombre, clave, valor)` resuelve o crea el medidor en cada llamada**, y esa es
  la mitad del problema: con un valor nuevo, **crea**. No hay tope, no hay aviso y no hay error.
- **El tag entra en la identidad del medidor.** `inventory.valuation.requests{sku="ABC-000123"}` y
  `inventory.valuation.requests{sku="ABC-000124"}` no son dos valores de la misma serie: son dos
  series distintas, cada una con su nombre, sus tags y su valor, vivas en el heap del proceso y
  replicadas en el backend.
- **Lo que hace que esto pase la revisión de código** es que el requisito era legítimo y el código
  es correcto. Lo que está mal no es el `Counter`: es **haber elegido como dimensión algo que no
  tiene un conjunto cerrado de valores**.

**Predice antes de ejecutar.** Vas a pedir 300 SKU distintos, todos inexistentes, así que las 300
peticiones responden `404`. ¿Cuántas series nuevas quedan en `/actuator/prometheus`?

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -o /dev/null -w 'antes: %{size_download} bytes\n' localhost:8081/actuator/prometheus
for i in $(seq 1 300); do
  curl -s -o /dev/null "localhost:8080/api/items/CAR-$(printf '%06d' "$i")/valuation"
done
curl -s localhost:8081/actuator/prometheus | grep -c '^inventory_valuation_requests_total'
curl -s -o /dev/null -w 'despues: %{size_download} bytes\n' localhost:8081/actuator/prometheus
curl -s localhost:8081/actuator/metrics/inventory.valuation.requests \
  | jq '.availableTags[] | select(.tag=="sku") | .values | length'
```

```text
300
300
```

- **300 peticiones, 300 series.** No 300 incrementos de una serie: **300 series**, cada una con
  valor `1` y ninguna que se vaya a incrementar nunca más, porque nadie vuelve a pedir ese SKU. Es
  la peor forma posible de gastar cardinalidad: series que nacen, se escriben una vez y no mueren.
- **Los dos `size_download` son la medida del daño y por eso el bloque no los fija**: dependen de
  cuántos medidores tenga tu proceso. Lo que tienes que anotar tú es la **diferencia** entre los dos
  números, y la cuenta que sale de ahí: son del orden de cien bytes por serie en cada scrape, cada
  quince segundos, para siempre.
- **El `404` de la respuesta no te salvó.** El contador se incrementa antes de la consulta, así que
  **cualquiera que pueda inventar SKU en la URL puede fabricarte series de tiempo**. Con un tag así
  sobre un identificador que viene del cliente, la cardinalidad deja de ser un error de diseño y
  pasa a ser un vector de denegación de servicio contra tu backend de métricas.
- **Y ahora escala la cuenta**, que es lo que hay que poder decir en voz alta: 50 000 SKU reales por
  tres valores de `outcome` son 150 000 series **de una sola métrica**; con un `Timer` con
  histograma, multiplica además por el número de buckets. El proceso de Prometheus crece hasta que
  el kernel lo mata, y cuando eso pasa **pierdes el tablero entero**, no solo el panel mal
  etiquetado.

```text
tag con conjunto cerrado   → outcome, status, method, cache, reason   →  decenas de series
tag con identificador      → sku, customerId, traceId, mensaje de error →  una serie por valor
                                                                          y ningún techo
```

La corrección tiene dos mitades y las dos se escriben hoy. La primera es quitar el tag y quedarse
con la pregunta bien planteada: *"¿qué SKU se piden más?"* no es una métrica, **es una consulta de
log**, y se contesta con el log estructurado de la sección 10 o con la base de datos. La segunda es
poner un fusible, porque el próximo tag mal elegido no lo vas a escribir tú:

```java
// src/main/java/com/invlab/invapi/config/MetricsConfig.java
@Configuration
class MetricsConfig {

    @Bean
    MeterFilter cardinalityGuard() {
        // techo duro por dimensión: a partir de 100 valores distintos de sku, se descarta
        return MeterFilter.maximumAllowableTags(
                "inventory.valuation.requests", "sku", 100, MeterFilter.deny());
    }
}
```

```yaml
management:
  metrics:
    web:
      server:
        max-uri-tags: 100        # fusible equivalente para la métrica http.server.requests
```

- **`MeterFilter` es un bean y se aplica a todo el registro**, sin tocar el código que instrumenta.
  Es la costura que te permite arreglar la cardinalidad de una librería de terceros que no
  controlas.
- **`maximumAllowableTags(nombre, tag, máximo, filtroSiSeExcede)`** cuenta valores distintos de esa
  dimensión y, al pasarse, aplica el filtro que le des; `MeterFilter.deny()` descarta la serie
  nueva. **No borra las 100 que ya entraron** ni arregla la explosión que ya ocurrió: es un tope,
  no una cura.
- **`max-uri-tags` es el mismo fusible para `http.server.requests`**, y vale `100` por defecto. Está
  ahí porque la trampa clásica es la URI: la métrica de MVC etiqueta con la **plantilla**
  (`/api/items/{sku}/valuation`), pero si mides a mano en un `Filter` —o si tu ruta no casa con
  ningún handler y cae en el `404`— acabas con una serie por URL distinta.
- **Cuando el fusible actúa, lo dice en el log** con un `WARNING` de Micrometer sobre el límite
  alcanzado. Ese aviso es el que hay que buscar cuando un panel "deja de tener datos nuevos".

Quita el tag del código —la línea entera, no solo el valor— y comprueba que las series se van con
el proceso:

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -o /dev/null localhost:8080/api/items/ABC-000123/valuation
curl -s localhost:8081/actuator/prometheus | grep -c '^inventory_valuation_requests_total'
```

```text
0
```

- **Cero, porque la métrica ya no se registra en absoluto.** Si en su lugar hubieras dejado el
  contador sin tag, verías `1`: una sola serie para todo el servicio, que es lo que se instrumenta
  cuando la pregunta es "¿cuántas valoraciones se piden?".
- **Y aquí está la parte incómoda del experimento:** en tu máquina las 300 series desaparecieron al
  reiniciar, porque el registro vive en memoria. En Prometheus **no desaparecen**: quedan en el
  almacenamiento hasta que expira la retención, y el índice sigue pagando por ellas aunque nadie
  las consulte. El daño de la cardinalidad sobrevive al despliegue que la arregla, y eso es lo que
  convierte un error de una tarde en una semana de compactaciones.

> Nunca respondas: ~~"pongo el `sku` como tag y ya puedo filtrar por producto"~~. Mejor: **un tag es
> una dimensión con un conjunto cerrado y pequeño de valores. Si el valor lo elige el cliente o
> crece con el catálogo, no es un tag: es un campo de log, y la pregunta se contesta en el sistema
> de logs o en la base de datos, no en el de métricas.**

---

## 7. 🧱 Prometheus en Compose, y el target que no responde

Todo lo que llevas medido hoy muere cuando matas la JVM, y ya te ha pasado cuatro veces. Prometheus
existe para eso: raspa tu endpoint cada quince segundos, guarda la serie con su marca de tiempo y
te deja preguntar por lo de hace una hora. El modelo es **pull**: tu aplicación no envía nada, el
servidor va a buscarlo.

El servicio ya estaba declarado en el Compose de
[`L00` §6](l00-idea-lab-practico.md#6--el-docker-composeyml-de-la-serie), en el perfil `obs`, con el
tag `prom/prometheus:v3.13.3` fijado, `extra_hosts` para que `host.docker.internal` resuelva también
en Docker Engine sobre Linux, y un bind mount de **todo el directorio** `./observability` en
`/etc/prometheus`. **El `docker-compose.yml` no se toca en este lab**: lo que falta son los dos
ficheros que ese directorio tiene que contener. Y el directorio es `observability/` **en la raíz del
repositorio**, junto al `docker-compose.yml` que lo monta, no dentro de `inv-api/` — el `cd ..` del
bloque de más abajo es justamente eso. El primero de los dos ficheros es la configuración:

```yaml
# observability/prometheus.yml
global:
  scrape_interval: 15s              # resolución de todas las series; a 5s triplicas el disco
  evaluation_interval: 15s          # cada cuánto se evalúan las reglas de alerta de la sección 9

rule_files:
  - /etc/prometheus/alerts.yml      # ruta DENTRO del contenedor, no de tu disco

scrape_configs:
  - job_name: inv-api
    metrics_path: /actuator/prometheus     # el default es /metrics: hay que escribirlo
    static_configs:
      - targets: ["host.docker.internal:8081"]
        labels:
          instance: inv-api-a               # etiqueta fija: distingue réplicas en el tablero
```

- **`scrape_interval: 15s` fija la resolución de todo lo que vas a poder preguntar.** Un pico de
  cinco segundos no existe para Prometheus si raspa cada quince; bajarlo a 5 s triplica el
  almacenamiento y el trabajo de ingesta, y casi nunca cambia una decisión ⏱️.
- **`metrics_path` es obligatorio aquí** porque Boot publica en `/actuator/prometheus` y el default
  de Prometheus es `/metrics`. Olvidarlo da un target en `down` con un `404` como último error, que
  es el fallo más fácil de arreglar de esta sección y el más fácil de confundir con el siguiente.
- **`host.docker.internal` es el nombre con el que un contenedor alcanza a la máquina anfitriona**,
  y hace falta porque `inv-api` corre como `java -jar` fuera de Docker. Cuando el servicio también
  vive en Compose —que es lo que hace [`L09` §5](l09-empaquetado-imagen-y-limpieza.md#5-️-inv-api-dentro-de-compose-cuatro-localhost-que-dejan-de-existir) al construir la imagen— el target pasa a ser el nombre
  del servicio, `inv-api:8081`, y este párrafo deja de aplicar.
- **`labels.instance`** sobrescribe la etiqueta que Prometheus pondría sola (el `host:puerto`), y
  eso es lo que te permite volver a levantar la segunda instancia de `L06` sin que las dos series se
  mezclen. Fíjate en que la etiqueta la pone **el que raspa**, no la aplicación: la identidad de la
  réplica no es responsabilidad de tu código.
- **`rule_files` apunta a una ruta del contenedor.** Es el enganche de la sección 9, y por eso el
  fichero de alertas se declara ya aquí: un `rule_files` que apunta a algo inexistente **impide que
  Prometheus arranque**, y prefiero que ese error te pase leyendo esto y no dentro de tres
  secciones.

Antes de levantar nada, vuelve a mirar el servicio tal como lo copiaste en `L01`. **No hay nada que
editar**: las dos líneas que hacen falta hoy ya venían puestas.

```yaml
  # docker-compose.yml, tal como se escribió en L01 — no se toca
  prometheus:
    image: prom/prometheus:v3.13.3
    profiles: ["obs"]
    ports: ["9090:9090"]
    volumes: ["./observability:/etc/prometheus:ro"]        # el directorio, no un solo fichero
    extra_hosts: ["host.docker.internal:host-gateway"]     # para que el target resuelva en Linux
```

- **El bind mount es del directorio y no de un fichero** justamente por lo que acabas de escribir:
  Prometheus tiene que ver **dos** ficheros en `/etc/prometheus` —la configuración y las reglas del
  `rule_files`—, y montar `./observability/prometheus.yml` suelto dejaría fuera al segundo. Hay un
  segundo motivo, más práctico: si el origen de un bind mount no existe, Docker lo crea **como
  directorio**, así que un mount de fichero te dejaría un *directorio* llamado `prometheus.yml` y un
  Prometheus que no arranca. El razonamiento entero está en
  [`L00` §6](l00-idea-lab-practico.md#6--el-docker-composeyml-de-la-serie).
- **`extra_hosts` con `host-gateway` es lo que hace existir `host.docker.internal`** en Docker
  Engine sobre Linux, donde no viene de fábrica; en Docker Desktop el nombre ya resuelve y la línea
  no cambia nada. Está escrita para todos desde `L00` en vez de partir el lab en dos caminos.

```bash
cd ..                      # a la raíz del repo, donde vive el docker-compose.yml
mkdir -p observability
docker compose -p inv-lab --profile obs up -d
docker compose -p inv-lab ps --format '{{.Name}}\t{{.Status}}' | grep -E 'prometheus|grafana'
```

- **El `cd ..` no es un detalle.** Vienes de `inv-api/` desde la sección 1, y el bind mount
  `./observability` del Compose se resuelve **relativo al directorio del `docker-compose.yml`**,
  que vive en la raíz del repositorio desde
  [`L01` §14](l01-esqueleto-cli-y-autoconfiguracion.md#14--el-docker-composeyml-se-escribe-aquí-y-no-se-levanta).
  Crear `observability/` dentro de `inv-api/` deja los dos ficheros donde nadie los lee y hace que
  Docker cree un `observability/` **vacío** en la raíz al levantar el perfil: Prometheus arranca sin
  configuración y el error que ves —un target que no existe— no menciona el directorio por ningún
  lado. Es el mismo `cd ..` de [`L04` §2](l04-datos-y-transacciones.md) y de
  [`L05` §2](l05-clientes-y-resiliencia.md).
- **`mkdir -p observability` antes del `up`**, por la misma razón que el `wiremock/mappings` de
  `L05`: si el directorio no existe, Docker lo crea como **root** y después no puedes escribir
  dentro sin `sudo`.
- **`--profile obs` levanta Prometheus y Grafana juntos**, que son los dos servicios que llevan ese
  perfil. Los otros tres contenedores siguen arriba: los perfiles se suman, no se reemplazan.
- **El teardown, aquí mismo y no en `L09`:**

```bash
docker compose -p inv-lab --profile obs down
docker compose -p inv-lab ps -a | grep -cE 'prometheus|grafana'
ls observability
```

- **`down` sin `-v` basta**, y conviene entender por qué: ni `prometheus` ni `grafana` declaran
  volumen con nombre en el Compose de `L00`, así que **sus datos viven dentro del contenedor y
  mueren con él**. Es una decisión de laboratorio con una consecuencia que vas a notar: cada vez que
  bajes y subas el perfil pierdes el histórico y el tablero, y hay que volver a crearlo con los
  comandos de la sección 8. En una instalación real, los dos llevan volumen.
- **El `grep -c` tiene que devolver `0`**: la limpieza se da por buena porque el listado sale vacío,
  no porque el comando no diera error. Es la disciplina de [`L00` §9](l00-idea-lab-practico.md#9--cómo-se-limpia-todo).
- **`ls observability` sigue mostrando tus ficheros**, porque es un bind mount de tu repositorio: lo
  que escribas ahí sobrevive a cualquier `down` y solo lo borras tú.

Vuelve a levantarlo con `docker compose -p inv-lab --profile obs up -d`, y **predice antes de
ejecutar**: Prometheus arranca, la configuración es correcta y tu `/actuator/prometheus` responde
`200`. ¿En qué estado está el target?

```bash
sleep 5
curl -s localhost:9090/api/v1/targets \
  | jq -c '.data.activeTargets[] | {job: .labels.job, health, lastError}'
```

```text
{"job":"inv-api","health":"down","lastError":"Get \"http://host.docker.internal:8081/actuator/prometheus\": dial tcp 192.168.65.254:8081: connect: connection refused"}
```

- **`connection refused`, y la dirección IP de la línea es la única parte que cambia** en tu
  máquina: es la del gateway de Docker, distinta en Desktop y en Engine. Lo demás es literal y es el
  diagnóstico entero.
- **La causa la escribiste tú en la sección 2**: `management.server.address: 127.0.0.1`. El conector
  de management está ligado al loopback de tu máquina, y un contenedor **no es** tu loopback: viene
  por la interfaz del gateway, así que el sistema operativo rechaza la conexión antes de que Tomcat
  se entere. Tu `curl` desde la terminal sigue funcionando perfectamente, y por eso el error parece
  imposible: *"si yo lo estoy viendo"*.
- **`connection refused` frente a `context deadline exceeded`**: el primero es "alguien contestó que
  no hay nadie escuchando ahí" —binding, puerto o firewall—; el segundo es "nadie contestó" —red,
  DNS o un proceso demasiado lento—. Distinguirlos ahorra la mitad del tiempo de diagnóstico.

La corrección va en el perfil `local`, que es donde tiene que estar:

```yaml
# application.yml, en el bloque del perfil local
management:
  server:
    address: 0.0.0.0        # solo en local: el scrape llega desde un contenedor
```

- **`0.0.0.0` liga el conector a todas las interfaces** de la máquina, que es lo contrario de lo que
  quieres en producción y exactamente lo que necesitas aquí. Va en el perfil `local` de
  [`L02`](l02-configuracion-y-profiles.md) y **no** en el bloque común, para que el `prod` simulado
  de `L09` conserve el loopback.
- **En un despliegue real este problema no existe** y merece decirse, porque si no parece que la
  regla de `23` esté mal: allí el proceso de scrape vive **dentro** de la misma red del pod o del
  namespace, así que alcanza el loopback o la IP interna sin salir a ninguna parte. Lo que aquí
  fuerza el `0.0.0.0` es la frontera artificial entre tu JVM y los contenedores.

```bash
cd inv-api                 # de vuelta al proyecto: los bloques de Compose te dejaron en la raíz
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 20
curl -s localhost:9090/api/v1/targets | jq -c '.data.activeTargets[] | {health, scrapeUrl}'
curl -s 'localhost:9090/api/v1/query?query=up{job="inv-api"}' | jq -r '.data.result[0].value[1]'
```

```text
{"health":"up","scrapeUrl":"http://host.docker.internal:8081/actuator/prometheus"}
1
```

- **El `cd inv-api` cierra el paréntesis que abrió el `cd ..`** de la sección: `./mvnw` y el
  `java -jar` son del proyecto, no del repositorio. El `kill %1` habría funcionado desde cualquier
  sitio —el control de trabajos es del shell y no del directorio— pero el build no.
- **`sleep 20` y no `sleep 10`**: hay que darle al menos un `scrape_interval` completo para que
  Prometheus vuelva a intentarlo. Preguntar antes es cómo se consigue un "no funciona" que sí
  funcionaba.
- **`up` es una métrica que genera Prometheus, no tu aplicación**: vale `1` si el último scrape tuvo
  éxito y `0` si falló. Es la primera que se grafica en cualquier tablero serio, porque un panel
  vacío puede significar "todo bien, cero errores" o "llevo dos horas sin raspar nada", y solo `up`
  distingue las dos cosas.
- **La API `/api/v1/query` es la misma que usa la interfaz web** (`localhost:9090`), y usarla desde
  `curl` es lo que te permite verificar un tablero sin capturas de pantalla. Todo lo que sigue se
  comprueba así.

---

## 8. 🩺 Grafana y el tablero de las cuatro señales

Con el histórico guardado ya se puede contestar la pregunta del principio: *"¿esto es peor que lo de
ayer?"*. Las cuatro señales doradas de
[`23` §9](23-actuator-y-observabilidad.md#9--prometheus-el-scrape-y-las-cuatro-señales-doradas)
son el mínimo, y en `inv-api` se traducen así:

| Señal | Consulta sobre tus métricas | Qué delata |
|---|---|---|
| Latencia | p95 de `http_server_requests_seconds_bucket` por `uri` | la degradación antes de la caída |
| Tráfico | tasa de `http_server_requests_seconds_count` | si el "está lento" es carga o es bug |
| Errores | proporción con `outcome="SERVER_ERROR"` | el 5xx que el usuario ya vio |
| Saturación | `hikaricp_connections_pending` y `tomcat_threads_busy_threads` | el recurso que se agota |

Grafana ya está corriendo con el perfil `obs`. Lo primero es decirle dónde están los datos:

```bash
curl -s -o /dev/null -w 'datasource -> %{http_code}\n' -X POST \
  -u admin:inv_lab -H 'Content-Type: application/json' \
  localhost:3000/api/datasources -d '{
    "name": "Prometheus",
    "type": "prometheus",
    "url": "http://prometheus:9090",
    "access": "proxy",
    "isDefault": true
  }'
```

```text
datasource -> 200
```

- **Se hace por API y no por la interfaz** a propósito: un tablero creado a mano no es reproducible,
  no se puede versionar y no se puede comprobar en un checklist. Todo lo de esta sección es un
  fichero o un comando.
- **`-u admin:inv_lab`** es el usuario administrador de Grafana con la contraseña que fija el
  Compose en `GF_SECURITY_ADMIN_PASSWORD`. Trivial a propósito, igual que las de Postgres, y por las
  mismas razones de [`L00` §6](l00-idea-lab-practico.md#6--el-docker-composeyml-de-la-serie).
- **`"url": "http://prometheus:9090"` es el nombre del servicio de Compose**, no `localhost`: los
  dos contenedores comparten la red del proyecto `inv-lab` y se ven por nombre. Poner `localhost`
  aquí apunta a **Grafana consigo mismo** y da un error de conexión que desconcierta.
- **`"access": "proxy"`** hace que las consultas salgan del servidor de Grafana; la alternativa
  (`direct`, del navegador) exige que Prometheus sea alcanzable desde tu navegador y traiga CORS.
  `proxy` es la correcta salvo casos muy concretos.
- **Un segundo `POST` idéntico devuelve `409`**, porque el nombre ya existe. No es un error: es la
  forma de saber que ya lo habías creado.

Y el tablero, en un fichero versionable:

```json
{
  "dashboard": {
    "title": "inv-api — cuatro señales",
    "uid": "inv-api-golden",
    "panels": [
      { "type": "timeseries", "title": "Latencia p95 por uri",
        "gridPos": { "h": 8, "w": 12, "x": 0, "y": 0 },
        "targets": [ { "expr": "histogram_quantile(0.95, sum by (le, uri) (rate(http_server_requests_seconds_bucket{job=\"inv-api\"}[5m])))", "legendFormat": "{{uri}}" } ] },
      { "type": "timeseries", "title": "Tasa de error 5xx",
        "gridPos": { "h": 8, "w": 12, "x": 12, "y": 0 },
        "targets": [ { "expr": "sum(rate(http_server_requests_seconds_count{job=\"inv-api\",outcome=\"SERVER_ERROR\"}[5m])) / sum(rate(http_server_requests_seconds_count{job=\"inv-api\"}[5m]))", "legendFormat": "error ratio" } ] },
      { "type": "timeseries", "title": "Hikari: conexiones en espera y activas",
        "gridPos": { "h": 8, "w": 12, "x": 0, "y": 8 },
        "targets": [ { "expr": "hikaricp_connections_pending{job=\"inv-api\"}", "legendFormat": "pending" },
                     { "expr": "hikaricp_connections_active{job=\"inv-api\"}", "legendFormat": "active" } ] },
      { "type": "stat", "title": "Circuito supplier",
        "gridPos": { "h": 8, "w": 12, "x": 12, "y": 8 },
        "targets": [ { "expr": "resilience4j_circuitbreaker_state{job=\"inv-api\",name=\"supplier\"} == 1", "legendFormat": "{{state}}" } ] }
    ],
    "time": { "from": "now-30m", "to": "now" },
    "refresh": "10s"
  },
  "overwrite": true
}
```

- **`histogram_quantile(0.95, sum by (le, uri) (rate(..._bucket[5m])))`** es el patrón completo y hay
  que leerlo de dentro afuera: `rate` convierte el contador acumulativo de cada bucket en
  incrementos por segundo sobre los últimos cinco minutos, `sum by (le, uri)` junta las réplicas
  conservando el límite del bucket y la ruta, y `histogram_quantile` interpola el p95 sobre esa
  distribución. **Si olvidas `le` en el `by`, la función no tiene con qué trabajar y devuelve
  vacío**; es el error número uno con histogramas.
- **La tasa de error es una división de dos `rate`**, no un contador de errores: lo que importa es
  la **proporción**, porque cien errores con diez mil peticiones y cien errores con ciento diez son
  incidentes distintos. `outcome` es un tag que pone Boot, con valores `SUCCESS`, `CLIENT_ERROR`,
  `SERVER_ERROR` y `REDIRECTION`: conjunto cerrado, que es justo lo que la sección 6 pedía de un tag.
- **`hikaricp_connections_pending` sostenido sobre cero es el pool agotado** de
  [`15` §2](15-datos-jdbc-jpa-mongo-y-redis.md#2--el-datasource-y-hikaricp): hilos **esperando una
  conexión**, que no es lo mismo que una base lenta, y se arreglan de forma opuesta. Va junto a
  `active` porque el número solo significa algo comparado con el tamaño del pool.
- **`resilience4j_circuitbreaker_state` es un gauge con un tag `state`** y vale `1` en el estado
  actual y `0` en los demás; el `== 1` filtra la serie que está activa, y `legendFormat` la pinta
  con su nombre (`closed`, `open`, `half_open`). Ese panel es el único de los cuatro que **no
  sirve para vigilar**, y la sección 9 explica por qué.
- **`"overwrite": true`** permite volver a publicar el mismo `uid` sin que la API se queje, que es lo
  que convierte este fichero en algo que puedes corregir y reenviar diez veces.
- **`[5m]` es la ventana de suavizado**, y es una decisión: más corta reacciona antes y tiembla más;
  más larga es estable y esconde los picos. Cinco minutos es el valor por defecto razonable con un
  scrape de quince segundos.

```bash
cd ..                      # otra vez a la raíz: el tablero y las alertas viven en observability/
curl -s -o /dev/null -w 'dashboard -> %{http_code}\n' -X POST \
  -u admin:inv_lab -H 'Content-Type: application/json' \
  localhost:3000/api/dashboards/db -d @observability/dashboard-golden.json
```

```text
dashboard -> 200
```

- **`-d @fichero` manda el contenido del fichero** tal cual, que es como se versiona un tablero. El
  JSON de arriba va en `observability/dashboard-golden.json`, **en la raíz del repositorio**: es el
  mismo directorio que Prometheus tiene montado, y de ahí el `cd ..`. El `alerts.yml` de la sección
  9 vive al lado, así que te quedas aquí hasta la sección 10.
- **Ábrelo en `http://localhost:3000/d/inv-api-golden`** —el `uid` es parte de la URL— y déjalo
  abierto para el resto del lab: las secciones 9 y 11 se ven mejor ahí que en una terminal.
- **Genera tráfico antes de juzgar los paneles.** Recién creado, el tablero está casi vacío porque
  Prometheus tiene tres minutos de datos; un bucle de treinta `curl` contra `/valuation` y contra
  `/quote` lo llena lo suficiente para que las curvas signifiquen algo.

> **🩺 Diagnóstico.** Un panel en blanco tiene tres causas y se descartan en este orden: la métrica
> no existe (`curl localhost:8081/actuator/prometheus | grep <nombre>` en la aplicación), el target
> no está raspando (`up{job="inv-api"}` en Prometheus), o la consulta está mal (pruébala en
> `localhost:9090` antes de meterla en el panel). Empezar por la consulta es lo natural y casi
> siempre es lo último que falla.

---

## 9. ⚠️ La alerta sobre el circuito de `L05`

El tablero de errores tiene un punto ciego enorme, y es el mismo que
[`19` §9](19-resiliencia.md#9--sin-métricas-esto-es-fe) anunció: **mientras el circuito está abierto
y el gateway devuelve el fallback, la tasa de 5xx baja**. Tu proveedor lleva veinte minutos caído,
tus clientes están recibiendo la última cotización conocida y el panel de errores se ve mejor que
ayer. Ojo con la variante: si el fallback contestara `503` en vez de una cotización vieja, la tasa
de 5xx **no** bajaría — el punto ciego existe precisamente porque el fallback responde con éxito.

```text
proveedor sano      → 5xx bajo    → todo bien
proveedor roto      → 5xx alto    → alerta de errores: suena
circuito abierto    → 5xx BAJA    → alerta de errores: calla, y el incidente sigue
```

Por eso el circuito **se alerta, no se grafica**: lo que importa no es su valor instantáneo sino su
**cambio de estado**, y eso es un evento, no una curva que alguien tenga que estar mirando.

```yaml
# observability/alerts.yml
groups:
  - name: inv-api-resiliencia
    rules:
      - alert: SupplierCircuitOpen
        expr: resilience4j_circuitbreaker_state{name="supplier",state="open"} == 1
        for: 30s
        labels:
          severity: page
          service: inv-api
        annotations:
          summary: "El circuito hacia inv-supplier lleva 30 s abierto"
          description: "inv-api está devolviendo fallbacks: la tasa de 5xx NO va a subir."
```

- **`expr` se evalúa cada `evaluation_interval`** —los quince segundos que fijaste en la sección 7—
  y la alerta entra en estado `pending` en cuanto la expresión devuelve algo.
- **`for: 30s` es el antirrebote y es la parte que más se discute**: la alerta no pasa a `firing`
  hasta que la condición se mantiene treinta segundos seguidos. Sin él, un circuito que abre y
  cierra en una ventana mala te despierta por algo que ya se arregló solo; con un `for` demasiado
  largo, te enteras tarde. Treinta segundos es corto a propósito para que quepa en este lab: en
  producción, con `wait-duration-in-open-state` de un minuto, `for: 2m` es más razonable.
- **`== 1` no es cosmética.** El gauge publica **una serie por estado** —`closed`, `open`,
  `half_open`, `disabled`, `forced_open`— y solo la del estado actual vale `1`. Sin el `== 1`, la
  expresión devuelve la serie de `open` valiendo `0` y la alerta estaría disparada permanentemente.
- **`severity: page` es una etiqueta tuya**, no de Prometheus: sirve para que el enrutador decida a
  quién despertar. Quien lo usa es Alertmanager, que este lab no monta (sección 1) — y eso no
  invalida la regla, porque la parte que depende de cómo instrumentaste es esta, no el enrutado.
- **`annotations` es el texto que lee la persona de guardia a las tres de la mañana**, y la segunda
  línea es la que evita el diagnóstico equivocado: dice explícitamente que **no** hay que esperar
  5xx. Una anotación que repite el nombre de la alerta no sirve para nada.

Prometheus no relee su configuración solo:

```bash
docker compose -p inv-lab restart prometheus
sleep 5
curl -s localhost:9090/api/v1/rules \
  | jq -c '.data.groups[].rules[] | {name, state, health}'
```

```text
{"name":"SupplierCircuitOpen","state":"inactive","health":"ok"}
```

- **`restart` y no `up -d`**: el contenedor no cambió, cambió un fichero de su bind mount. La
  alternativa elegante es el `POST /-/reload`, que exige arrancar Prometheus con
  `--web.enable-lifecycle`; el Compose de `L00` no lo hace, así que aquí se reinicia.
- **`health: "ok"` dice que la regla compila.** Si te equivocaste en el YAML o en la expresión,
  Prometheus **no arranca** y el contenedor se queda reiniciándose: `docker compose -p inv-lab logs
  prometheus` te da la línea exacta con el número de línea del fichero.
- **`state: "inactive"` es el tercer estado**, junto a `pending` y `firing`, y significa que la
  expresión no devuelve nada ahora mismo — que es lo correcto, porque el circuito está cerrado.

**Predice antes de ejecutar.** Vas a machacar el SKU que siempre falla, como en
[`L05` §5](l05-clientes-y-resiliencia.md#5--el-circuito-que-abre-de-verdad). ¿Cuánto tarda la
alerta en pasar a `firing` desde la primera petición: inmediatamente, unos 30 s, o unos 45 s?

```bash
for i in $(seq 1 8); do
  curl -s -o /dev/null localhost:8080/api/items/ERR-000500/quote
done
curl -s localhost:8081/actuator/circuitbreakers | jq -r '.circuitBreakers.supplier.state'
sleep 20
curl -s localhost:9090/api/v1/alerts | jq -c '.data.alerts[] | {alertname: .labels.alertname, state}'
sleep 30
curl -s localhost:9090/api/v1/alerts | jq -c '.data.alerts[] | {alertname: .labels.alertname, state}'
```

```text
OPEN
{"alertname":"SupplierCircuitOpen","state":"pending"}
{"alertname":"SupplierCircuitOpen","state":"firing"}
```

- **El circuito abre en tu proceso al instante y la alerta tarda**, y esa diferencia es la que hay
  que tener clara: entre el evento y la notificación hay **un scrape** (hasta 15 s), **una
  evaluación** (hasta 15 s más) y **el `for`** (30 s). Con los números de este lab son unos
  cuarenta y cinco segundos de media y **hasta sesenta en el peor caso**, que es cuando el evento
  cae justo después de un scrape y justo después de una evaluación. Alertar sobre métricas nunca es inmediato, y quien
  promete "detección en tiempo real" con este montaje no ha hecho la cuenta.
- **Si en tu ejecución el primer `curl` ya sale `pending` o incluso `firing`**, es que el scrape
  cayó justo antes; el orden de los estados es lo que no cambia, los segundos exactos sí.
- **`/actuator/circuitbreakers` y `/api/v1/alerts` cuentan la misma historia desde los dos lados**:
  el primero es el estado **ahora**, en un proceso concreto; el segundo es el estado **sostenido**,
  ya agregado y con memoria. Esa es exactamente la diferencia entre un endpoint de diagnóstico y un
  sistema de monitorización, y es lo que este lab existe para hacerte tocar.

Y ahora la otra mitad del experimento, que casi nadie prueba: **la alerta tiene que apagarse sola**.

```bash
sleep 15
curl -s -o /dev/null localhost:8080/api/items/ABC-000123/quote
curl -s -o /dev/null localhost:8080/api/items/ABC-000123/quote
curl -s localhost:8081/actuator/circuitbreakers | jq -r '.circuitBreakers.supplier.state'
sleep 30
curl -s localhost:9090/api/v1/alerts | jq -c '.data.alerts | length'
```

```text
CLOSED
0
```

- **`wait-duration-in-open-state: 10s` más `automatic-transition-from-open-to-half-open-enabled`**
  llevan el circuito a `HALF_OPEN` solo, y las dos llamadas buenas lo cierran —son exactamente las
  `permitted-number-of-calls-in-half-open-state: 2` que configuraste en `L05`—. Si en tu ejecución
  ves `HALF_OPEN`, manda una tercera llamada buena.
- **La alerta se resuelve sola en cuanto la expresión deja de devolver la serie**, sin `for` de
  vuelta y sin que nadie la toque. Una alerta que hay que cerrar a mano es una alerta mal escrita.
- **Con esto queda cerrado el criterio de terminado de este lab**: hay un tablero con las cuatro
  señales y una alerta sobre el circuito de `L05` que se dispara y se apaga sola, y las dos cosas se
  comprueban con un `curl`, no con una captura.

---

## 10. 🧱 Micrometer Tracing: el `traceId` de punta a punta

Las métricas te dicen **que** el p95 subió. No te dicen **dónde** se fue el tiempo de la petición
que tardó nueve segundos, ni si el culpable fue tu consulta, tu caché o `inv-supplier`. Para eso
hace falta que cada petición lleve un identificador que sobreviva al salto de proceso.

Y aquí hay un hilo abierto que este lab tiene que cerrar. En
[`L06` §8](l06-cache-y-asincronia.md#8--async-el-hilo-nuevo-y-el-requestid-que-se-queda-atrás) lo
que perdiste y propagaste a través del `@Async` fue el **`requestId`** del MDC que puso
[`L03` §6](l03-api-rest-filtros-y-errores.md#6-️-el-x-request-id-que-se-filtra-a-la-petición-siguiente),
y allí se dijo explícitamente por qué: Micrometer Tracing no existía en el proyecto y no había
ningún `traceId` que perder. Hoy sí lo hay, y hay que decidir qué pasa con los dos.

```xml
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-tracing-bridge-otel</artifactId>
</dependency>
```

- **Sin `<version>`**: Micrometer Tracing entra por el BOM de Boot 3.5.16, que fija **1.5.12**, y
  el bridge arrastra el SDK de OpenTelemetry **1.49.0**, también gestionado por el BOM.
- **El bridge decide la implementación, no el destino.** `micrometer-tracing-bridge-otel` usa
  OpenTelemetry por dentro; `...-bridge-brave` usa Brave, el de Zipkin. Se elige **uno**: con los
  dos en el classpath, Boot se queda con el que encuentre primero y el comportamiento deja de ser el
  que crees.
- **Generar trazas y exportarlas son dos dependencias distintas**, y esa separación es deliberada.
  Hoy solo añades la primera: los `traceId` se generan, viajan en las cabeceras y se escriben en el
  log, y **no se envían a ningún sitio** porque no hay exportador. Eso es exactamente lo que este
  lab necesita, y es la razón por la que no hay un contenedor más (sección 1).
- **Trae `context-propagation` como dependencia transitiva**, que es la librería que va a hacer
  falta al final de esta sección para el `@Async`.

```yaml
management:
  tracing:
    sampling:
      probability: 1.0        # ⏱️ SOLO para el lab: el default es 0.1 y casi nunca se sube

logging:
  pattern:
    correlation: "[${spring.application.name:inv-api},%X{traceId:-},%X{spanId:-}] "
```

- **`probability: 1.0` muestrea todas las peticiones**, que es lo que quieres cuando haces doce
  `curl` a mano y necesitas ver los doce. El default es `0.1` —una de cada diez— y hay una razón de
  costo: cada traza exportada son bytes de red y de almacenamiento **por span**, y un servicio con
  mil peticiones por segundo genera varios miles de spans por segundo ⏱️. **La decisión se toma en
  la raíz** y viaja en el flag del `traceparent`: o se muestrea la petición entera, o ninguna parte
  de ella.
- **`logging.pattern.correlation` es un hueco propio del patrón de consola de Boot**, distinto del
  `logging.pattern.level` que `L03` sobrescribió con el `requestId`. Por eso las dos cosas conviven
  en la misma línea sin pisarse: el nivel y el `requestId` en un lado, el nombre de la aplicación,
  el `traceId` y el `spanId` en el otro.
- **`%X{traceId:-}` lee la clave del MDC y `:-` es el valor por defecto cuando falta** —aquí, cadena
  vacía—, que evita imprimir el literal en las peticiones que no atraviesan una observación.

```bash
cd inv-api                 # de vuelta al proyecto tras escribir el tablero y las alertas
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -o /dev/null -X POST localhost:8090/__admin/requests/reset
curl -s -o /dev/null -H 'X-Request-Id: traza-01' localhost:8080/api/items/ABC-000123/quote
grep 'traza-01' app.log
```

- **El `cd inv-api` es el último salto del lab**: a partir de aquí todo es `./mvnw` y `java -jar`.
  La regla que conviene fijar es simple — `observability/` y el `docker compose … up` viven en la
  raíz del repositorio, el build y la aplicación en `inv-api/` — y los `ps`, `stop`, `restart` y
  `down` con `-p inv-lab` funcionan desde cualquiera de los dos, porque Compose los resuelve por
  las etiquetas de los contenedores y no por el fichero.
- **`/__admin/requests/reset` vacía el journal de WireMock** antes del experimento, para que el
  `requests[0]` de dentro de un momento sea **tu** petición y no una de la sección 3.
- **`/quote` y no `/valuation`**, porque es el único endpoint que sale a la red: sin llamada
  saliente no hay cabecera que inspeccionar.

La línea que sale tiene esta forma, y **los treinta y dos caracteres del `traceId` y los dieciséis
del `spanId` son distintos en cada ejecución**, así que aquí van con su forma y no con un valor
fijo:

```text
 INFO [traza-01] [inv-api,<32 hex>,<16 hex>] --- [nio-8080-exec-2] c.i.i.InventoryController : ...
```

- **Los dos identificadores conviven y no compiten.** El `requestId` es **tuyo**: lo pone el cliente
  en `X-Request-Id`, lo entiendes tú y sirve para que soporte y desarrollo hablen del mismo caso.
  El `traceId` es **del sistema**: lo genera Micrometer Tracing, es opaco y sirve para pegar los
  tramos de varios servicios.
- **El que se propaga entre servicios es el `traceId`**, porque viaja en una cabecera estándar que
  el otro extremo entiende sin acuerdo previo. El `requestId` solo lo propaga quien tú hayas
  convencido de propagarlo.
- **La decisión limpia para un proyecto real es quedarse con uno**, y casi siempre es el `traceId`:
  se hace que el filtro de `L03` **use el `X-Request-Id` como `baggage`** o simplemente lo registre
  como campo del log, y se deja de mantener dos identificadores. Aquí se conservan los dos porque el
  lab necesita enseñar que son mecanismos distintos, y porque un servicio real en migración vive
  exactamente así durante meses.

Ahora la parte que de verdad importa: **¿llegó al otro servicio?**

```bash
curl -s localhost:8090/__admin/requests | jq -r '.requests[0].request.headers.traceparent'
grep 'traza-01' app.log | head -1
```

- **La cabecera `traceparent` tiene el formato `00-<traceId>-<spanId>-01`** del estándar W3C Trace
  Context: versión, los 32 hex del trace, los 16 del span que la emitió, y el flag de muestreo —`01`
  muestreada, `00` no—. **El `traceId` de esa cabecera es el mismo que el de tu línea de log**, y
  compararlos con los dos comandos de arriba es la prueba de punta a punta: la petición que entró
  por tu `curl` y la que salió hacia `inv-supplier` son la misma para cualquier sistema que sepa
  leer trazas.
- **El `spanId` de la cabecera NO es el de la línea de log del controller**, y eso también es
  correcto: la llamada saliente abre su propio span, hijo del anterior. Un `traceId` compartido y
  `spanId` distintos es la forma de un árbol de spans.
- **El journal de WireMock (`/__admin/requests`) guarda la petición entera**, cabeceras incluidas, y
  es la misma herramienta que usaste en `L05` para contar reintentos. Aquí sirve como "el otro
  servicio": no necesitas un segundo Spring Boot para demostrar que la propagación funciona.
- **Y funciona por una razón concreta que hay que poder nombrar**: el `SupplierGateway` construye su
  cliente desde el **`RestClient.Builder` inyectado**, al que Boot le añade el interceptor de
  observación. Un `RestClient.create()` suelto no lo lleva, la cabecera no sale, y la traza aparece
  **cortada en tu borde**: ves los spans del llamador y ninguno del proveedor. Es la misma razón por
  la que `L05` insistía en el builder, con otra consecuencia.

Falta el salto de hilo, que es donde `L06` te dejó el hilo suelto:

```bash
curl -s -o /dev/null -X POST localhost:8080/api/items/ABC-000123/events \
  -H 'Content-Type: application/json' -H 'X-Request-Id: traza-02' \
  -d '{"delta":2,"reason":"recepcion"}'
sleep 1
grep 'traza-02' app.log
```

- **Las tres líneas salen con el mismo `requestId`**, porque el `MdcTaskDecorator` de `L06` sigue
  copiando el MDC entero al hilo del pool — y el `traceId`, que **también** vive en el MDC, viaja
  con él. El log queda correlacionado.
- **Y aun así falta algo, que es la trampa fina de esta sección.** Copiar el MDC propaga los
  **textos** que se imprimen; no propaga el **contexto de observación** de Micrometer. Si el trabajo
  asíncrono abriera un span propio —una llamada HTTP saliente, por ejemplo—, ese span no sería hijo
  del de la petición: arrancaría una traza nueva, con el log diciendo un `traceId` y el sistema de
  trazas diciendo otro. Log correlacionado y traza rota a la vez es lo peor de los dos mundos,
  porque nadie lo sospecha.

La corrección es componer decoradores en vez de elegir uno:

```java
// en AsyncConfig, sustituyendo el setTaskDecorator de L06
executor.setTaskDecorator(new CompositeTaskDecorator(List.of(
        new ContextPropagatingTaskDecorator(),   // el contexto de observación: traceId y spanId de verdad
        new MdcTaskDecorator())));               // el tuyo: requestId, que nadie más conoce
```

- **`ContextPropagatingTaskDecorator`** (de `org.springframework.core.task.support`, desde Spring
  Framework 6.1) arrastra todo lo registrado en Micrometer Context Propagation: la observación
  actual y, con ella, el `traceId` y el `spanId` **como contexto**, no solo como texto en el MDC.
  Es el decorador oficial que `L06` te anunció.
- **`CompositeTaskDecorator` aplica los decoradores en orden** y existe por esto mismo: un executor
  solo admite **un** `TaskDecorator`, así que sin él, poner el oficial significa perder el tuyo. El
  `requestId` no lo propaga nadie más, porque no es un contexto conocido por Micrometer.
- **La alternativa elegante, y es un buen 🔥**, es registrar el `requestId` como `ThreadLocalAccessor`
  en el `ContextRegistry` de Micrometer: entonces `ContextPropagatingTaskDecorator` lo propaga solo y
  el decorador propio desaparece. Es más código hoy y menos cableado mañana.
- **El `MDC.clear()` del decorador de `L06` sigue siendo obligatorio** por la razón de siempre: los
  hilos del pool se reutilizan y una tarea que herede el contexto de la anterior atribuye trabajo a
  la petición equivocada.

> **📝 Qué cambia en la línea 4.x.** Boot 4 sube a Micrometer 1.16 y Micrometer Tracing 1.6, y
> renombra `management.tracing.enabled` a **`management.tracing.export.enabled`**: instrumentar y
> exportar dejan de ser el mismo interruptor, que es exactamente la distinción que este lab explota
> al no montar exportador. El apéndice de migración lo desarrolla; todavía no está escrito.

---

## 11. 🩺 `threaddump` en plena saturación

Llega el reporte más común de todos —*"se quedó colgado"*— y es el único donde las métricas y las
trazas se quedan cortas: te dicen que la latencia subió y que los hilos están ocupados, pero no
**en qué línea** están parados. Eso lo contesta un volcado de hilos, y Actuator lo sirve por HTTP
sin necesidad de `jstack` ni de entrar al contenedor.

`L05` ya te enseñó a leer uno: doce peticiones al proveedor colgado, diez hilos en `RUNNABLE` sobre
`sun.nio.ch.SocketDispatcher.read0`, y el diagnóstico de "falta un timeout". Hoy el escenario es
distinto a propósito, porque **el timeout ya está puesto y el sistema se satura igual**.

```yaml
resilience4j:
  bulkhead:
    instances:
      supplier:
        max-concurrent-calls: 3
        max-wait-duration: 5s     # TEMPORAL: en L05 era 0. Vuelve a 0 en el checklist.
```

- **`max-wait-duration: 5s` cambia el bulkhead de "rechaza" a "haz cola"**, y ese es todo el
  experimento: en `L05`, con `0`, las peticiones sobrantes fallaban en 20 ms con
  `BulkheadFullException`; ahora **esperan**, y un hilo que espera es un hilo que no atiende a nadie.
- **Una variable a la vez**: no se toca nada más, ni el número de hilos de Tomcat —que sigue en
  `10` desde `L05`— ni el SKU que se usa.
- **Esta configuración es peor que la de `L05` y se pone a propósito.** Encolar hacia una dependencia
  lenta convierte un rechazo rápido y honesto en una saturación lenta y silenciosa, y es una decisión
  que se toma a menudo por parecer más amable con el cliente.

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
for i in $(seq 1 12); do
  curl -s -o /dev/null --max-time 20 localhost:8080/api/items/SLW-000002/quote &
done
sleep 2
curl -s localhost:8081/actuator/metrics/tomcat.threads.busy | jq -c '.measurements'
curl -s -o /dev/null -w 'health -> %{http_code}\n' localhost:8081/actuator/health
curl -s localhost:8081/actuator/threaddump \
  | jq -r '.threads[] | select(.threadName | startswith("http-nio-8080-exec"))
           | "\(.threadState)"' | sort | uniq -c
wait
```

```text
[{"statistic":"VALUE","value":10.0}]
health -> 200
```

- **`tomcat.threads.busy` en `10.0` con `health` en `200`** es el mismo par de números de `L05` y la
  misma lección, ahora con el tablero delante: el panel de saturación de la sección 8 se está
  poniendo rojo mientras el de errores no se mueve, porque todavía nadie ha fallado — están
  esperando. **Y el health responde porque vive en el 8081**, con su propio pool. Esa decisión, que
  tomaste en `L01` sin entenderla del todo, es la que impide que el orquestador reinicie una
  instancia que solo está llena.
- **La salida del `uniq -c` se queda en prosa a propósito, porque no es determinista**: los conteos
  dependen de cuántas peticiones estén en vuelo en el milisegundo del volcado. Lo que vas a ver son
  **dos grupos**. Unos pocos hilos en `RUNNABLE`, nunca más de tres —el `max-concurrent-calls`—,
  parados en la lectura del socket hacia WireMock; y el resto en `TIMED_WAITING`, que es la firma de
  la espera **con plazo**: están dentro del semáforo del bulkhead, esperando su permiso hasta los
  cinco segundos que configuraste.
- **`TIMED_WAITING` frente a `RUNNABLE` es todo el diagnóstico**, y es lo que separa este caso del de
  `L05`. `RUNNABLE` en un socket significa "estoy esperando bytes de otro": falta un timeout, o el
  otro es lento. `TIMED_WAITING` dentro de tu propio proceso significa "me estoy esperando a mí
  mismo": un límite tuyo —semáforo, pool de conexiones, lock— es el que está frenando. Subir
  `server.tomcat.threads.max` en el primer caso empeora las cosas; en el segundo no cambia nada,
  porque el cuello está más adentro.
- **Para ver quién es tu código dentro del volcado**, filtra por paquete en vez de por estado:

```bash
curl -s localhost:8081/actuator/threaddump \
  | jq -r '.threads[] | select(.threadName | startswith("http-nio-8080-exec"))
           | .stackTrace[] | select(.className | startswith("com.invlab")) | .className + "." + .methodName' \
  | sort | uniq -c | sort -rn | head -3
```

- **`.stackTrace[]` recorre la pila entera** en vez de quedarse en el primer frame, y el filtro por
  `com.invlab` deja solo **tus** métodos. Es la diferencia entre saber que hay diez hilos parados y
  saber que los diez pasaron por `SupplierGateway.quote`.
- **`sort | uniq -c | sort -rn` agrupa y ordena por frecuencia**, que es como se lee un volcado de
  doscientos hilos: no se lee, se cuenta. El método que más aparece es el sospechoso.
- **Los conteos vuelven a depender del instante del volcado**, así que se leen como proporciones y
  no como cifras. La regla de método es tomar **dos o tres volcados separados por unos segundos**:
  si los mismos hilos siguen en el mismo frame, hay un bloqueo; si cambian, hay lentitud.

> **🩺 Diagnóstico.** `threaddump` es la primera parada de un "se quedó colgado" y contesta en
> treinta segundos. `heapdump` es la primera parada de un "se está quedando sin memoria" y **no** es
> un endpoint más: pausa la JVM mientras escribe un archivo del tamaño del heap, con datos reales de
> clientes dentro. Por eso no está en tu `exposure.include` y por eso Boot lo deja fuera del acceso
> sin restricciones, junto con `shutdown`.

Devuelve el bulkhead a como lo dejó `L05` antes de seguir:

```bash
kill %1
# en application.yml: resilience4j.bulkhead.instances.supplier.max-wait-duration vuelve a 0
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s localhost:8081/actuator/configprops | jq -e '.. | .maxWaitDuration? // empty' | head -1
```

- **Se verifica con `configprops`, no leyendo el YAML**, y esa es la idea: el endpoint dice lo que el
  contexto **cargó**, que es lo único que importa. Es el mismo criterio de `L02` con la precedencia
  de propiedades.
- **`jq -e` devuelve un código de salida distinto de cero si no encuentra nada**, lo que convierte
  esta línea en algo que se puede poner en un script de verificación sin leer la salida.

---

## 12. ⚖ `httpexchanges`, y por qué no sustituye a las trazas

Queda un endpoint que parece resolver lo mismo que la sección 10 con una fracción del trabajo, y
que en cada equipo alguien propone: `httpexchanges` guarda las últimas peticiones HTTP que atendió
tu aplicación, con su método, su URI, su código y su duración. Sin dependencias, sin cabeceras
nuevas y sin un segundo sistema. Conviene montarlo para entender exactamente por qué no alcanza.

```java
// en MetricsConfig, junto al MeterFilter
@Bean
HttpExchangeRepository httpExchangeRepository() {
    // sin este bean, /actuator/httpexchanges responde 404 aunque esté expuesto
    return new InMemoryHttpExchangeRepository();
}
```

```yaml
management:
  httpexchanges:
    recording:
      include: request-headers,response-headers,time-taken
```

- **Boot no registra ningún `HttpExchangeRepository` por ti**, y es deliberado: guardar peticiones
  reales en memoria es una decisión con implicaciones de privacidad, no un default. Sin el bean, el
  endpoint devuelve `404` aunque esté en `exposure.include` — es la **cuarta** causa de `404` de
  este lab, sumada a las tres de §2: falta la dependencia, no está en `include`, o `exclude` gana.
  Las cuatro dan el mismo código y se distinguen con comandos distintos.
- **`InMemoryHttpExchangeRepository` guarda las últimas 100** en una lista circular, y ese número se
  cambia con `setCapacity`. Cien peticiones en un servicio con tráfico son **unos pocos segundos**
  de historia.
- **`recording.include` decide qué se guarda de cada intercambio**, y la lista es corta a propósito.
  `request-headers` es la opción peligrosa: ahí van `Authorization`, `Cookie` y cualquier cabecera
  con un token, y quedarían legibles en un endpoint HTTP. Se activa sabiendo lo que se activa, y en
  banca normalmente no se activa.

```bash
curl -s -o /dev/null -H 'X-Request-Id: intercambio-01' localhost:8080/api/items/ABC-000123/valuation
curl -s localhost:8081/actuator/httpexchanges \
  | jq -c '.exchanges[0] | {uri: .request.uri, status: .response.status, timeTaken}'
curl -s localhost:8081/actuator/httpexchanges | jq '.exchanges | length'
```

- **El primer `jq` devuelve la última petición atendida** con su URI completa, su código y su
  duración en formato ISO-8601 (`PT0.0123S`). Los milisegundos cambian en cada ejecución, así que
  aquí no hay bloque de salida que fijar: lo que hay que comprobar es que tu `/valuation` aparece
  el primero de la lista.
- **`length` te devuelve cuántos intercambios hay guardados**, con tope en 100. Haz cien peticiones
  más y comprueba que el número no sube: ahí está la mitad del argumento de esta sección.

Y el veredicto, que es lo que se pregunta en entrevista:

| | `httpexchanges` | Trazas (sección 10) |
|---|---|---|
| Alcance | una instancia, su propia memoria | todos los servicios que propaguen la cabecera |
| Historia | las últimas 100, muertas al reiniciar | lo que retenga el backend |
| Granularidad | la petición entera, un número | un span por tramo: controller, base, proveedor |
| Correlación | ninguna: no hay identificador común | `traceId` compartido, de punta a punta |

- **El punto ciego que lo descalifica es el primero**: `httpexchanges` solo ve **lo que entró**. La
  llamada a `inv-supplier` que se llevó el 90 % del tiempo no aparece por ninguna parte, y con seis
  réplicas la petición que buscas está en la memoria de una de ellas, sin forma de saber en cuál.
- **Para lo que sí sirve es para un caso concreto y honesto**: estás en tu máquina o en un entorno
  de integración, acabas de recibir un `400` que no esperabas, y quieres ver **qué te mandaron de
  verdad** sin levantar un proxy ni activar `DEBUG` en el paquete web. Para eso es inmejorable, y
  por eso está en el catálogo.
- **Lo que nunca es**: un sistema de auditoría. Una lista circular en memoria que se pierde con el
  proceso no cumple ningún requisito de retención, y proponerla para eso en banca es la clase de
  respuesta que termina una entrevista.

---

## 13. 📋 Checklist de salida

- [ ] `docker compose -p inv-lab ps` lista cinco contenedores: Postgres `(healthy)`, WireMock, Redis, Prometheus y Grafana en `Up`.
- [ ] `curl -s localhost:8081/actuator | jq -r '._links | keys[]'` incluye `prometheus`, `loggers` y `httpexchanges`.
- [ ] `curl -s -o /dev/null -w '%{http_code}' localhost:8081/actuator/prometheus` responde `200` y la salida trae líneas `# TYPE`.
- [ ] Con WireMock parado, `/actuator/health` y `/actuator/health/readiness` responden `503` y `/actuator/health/liveness` responde `200`.
- [ ] Un `POST` a `/actuator/loggers/org.hibernate.SQL` sin `Content-Type` responde `415`, y con él responde `204`.
- [ ] `curl -s localhost:8081/actuator/metrics/inventory.valuations.batch` responde `200`, con `spring-boot-starter-aop` en el `pom.xml` y `management.observations.annotations.enabled: true`.
- [ ] `curl -s localhost:8081/actuator/prometheus | grep -c '^inventory_valuation_requests_total'` devuelve `0` o `1`, nunca 300: el tag `sku` ya no está y existe el `MeterFilter`.
- [ ] `curl -s 'localhost:9090/api/v1/query?query=up{job="inv-api"}' | jq -r '.data.result[0].value[1]'` devuelve `1`.
- [ ] `curl -s -u admin:inv_lab localhost:3000/api/dashboards/uid/inv-api-golden | jq -r '.dashboard.panels | length'` devuelve `4`.
- [ ] `curl -s localhost:9090/api/v1/rules | jq -r '.data.groups[].rules[].health'` devuelve `ok`.
- [ ] Ocho peticiones a `ERR-000500` dejan el circuito en `OPEN` y, menos de un minuto después, `SupplierCircuitOpen` en `firing`; al cerrarse el circuito la alerta desaparece sola.
- [ ] Una petición con `X-Request-Id` produce una línea de log con el `requestId` **y** con un `traceId` de 32 hex, y ese mismo `traceId` aparece en la cabecera `traceparent` del journal de WireMock.
- [ ] `grep 'traza-02' app.log` devuelve tres líneas, dos de ellas en un hilo `inv-task-`, todas con el mismo `traceId`.
- [ ] `resilience4j.bulkhead.instances.supplier.max-wait-duration` volvió a `0` y `server.tomcat.threads.max` sigue en `10`.
- [ ] `curl -s localhost:8081/actuator/httpexchanges | jq '.exchanges | length'` devuelve como mucho `100`.
- [ ] `./mvnw -q clean package` pasa en verde con los tests de `L03` intactos y `jobs` lista un solo `java -jar`.

---

## 🧠 Preguntas rápidas

1. `GET /actuator/prometheus` devuelve `404` y la propiedad `include` lo menciona. Enumera las tres
   causas posibles y el comando que distingue cada una de las otras dos.
2. ¿Qué gana exactamente el puerto de management separado que no gane exponer menos endpoints, y
   qué prueba de `L05` lo demuestra?
3. Tu `SupplierHealthIndicator` está en el grupo `liveness` y el proveedor lleva diez minutos
   caído. Describe qué hace el orquestador y por qué es el peor resultado posible.
4. "El health está verde, así que el servicio funciona." Corrige la afirmación con precisión y di
   qué señal sí lo contestaría.
5. Cambias un nivel con `POST /actuator/loggers/...` y no aparece nada nuevo en el log. Enumera las
   causas en el orden en que las revisarías, contando la que tiene que ver con las réplicas.
6. ¿Por qué el `Timer` de este lab está **dentro** del `@Cacheable` y no alrededor del endpoint?
   ¿Qué mediría cada una de las dos opciones?
7. Pusiste `@Timed` y la métrica no existe: nombra las dos condiciones que hay que cumplir para que
   la anotación se registre, y la tercera que la deja sin efecto aunque se cumplan las dos.
8. Explica por qué `publishPercentileHistogram()` y no `publishPercentiles(0.95)` cuando hay seis
   réplicas detrás de un balanceador.
9. Trescientas peticiones con un tag `sku` dejaron 300 series. ¿Por qué el daño no se limita a esa
   métrica, y por qué tampoco desaparece al desplegar la corrección?
10. `up{job="inv-api"}` vale `0` y tu `curl localhost:8081/actuator/prometheus` responde `200` desde
    la terminal. ¿Cuál es la causa más probable con este montaje y cómo se confirma?
11. Tu tasa de 5xx **bajó** mientras el proveedor está caído. Explica el mecanismo y di sobre qué
    métrica y con qué condición escribes la alerta.
12. Entre que el circuito se abre y que la alerta pasa a `firing` pasan unos cuarenta segundos.
    Desglosa de dónde sale cada tramo de esa espera.
13. ¿Qué lleva dentro la cabecera `traceparent`, quién decide si la traza se muestrea y en qué
    momento se toma esa decisión?
14. `L06` propagaba el `requestId` y hoy hay además un `traceId`. Di qué aporta cada uno, cuál se
    propaga entre servicios y por qué copiar el MDC no basta cuando el hilo nuevo abre un span.
15. En un `threaddump`, ¿qué te dice un hilo en `RUNNABLE` sobre `SocketDispatcher.read0` y qué te
    dice uno en `TIMED_WAITING` dentro de tu proceso? ¿Cuál de los dos empeora si subes
    `server.tomcat.threads.max`?

---

## 🧪 Ejercicios (16)

### 🟢 Fácil — repetir lo del lab con otro valor o en otro punto  (1–5)

#### 🟢 Ejercicio 1 — un indicator más, y su grupo

Escribe un `RedisHealthIndicator` propio —llámalo distinto del autoconfigurado, por ejemplo
`CacheStoreHealthIndicator`— que haga un `PING` a Redis y devuelva `UP` o `DOWN`, e inclúyelo en el
grupo `readiness`. Para Redis con `docker compose -p inv-lab stop redis` y comprueba los códigos.
**Objetivo:** ver que el nombre del bean manda sobre la clave del informe, y que un grupo solo
agrega lo que lista explícitamente.

#### 🟢 Ejercicio 2 — otro logger en caliente

Sube `io.github.resilience4j` a `DEBUG` con el endpoint `loggers`, lanza cinco peticiones a
`ERR-000500` y cuenta las líneas nuevas; después devuélvelo al nivel heredado con
`{"configuredLevel":null}` y comprueba con un `GET` que `configuredLevel` desapareció.
**Objetivo:** distinguir `effectiveLevel` de `configuredLevel` y no dejar loggers clavados.

#### 🟢 Ejercicio 3 — un `Counter` con un tag legítimo

Añade a `InventoryValuationService` un contador `inventory.valuation.outcome` con un tag `outcome`
de dos valores —`found` y `not_found`— e incrementa el que corresponda. Comprueba en
`/actuator/prometheus` que aparecen exactamente **dos** series, hagas las peticiones que hagas.
**Objetivo:** tener en la misma clase el contraejemplo del `sku` de la sección 6 y un tag bien
elegido, y poder señalar la diferencia en una frase.

#### 🟢 Ejercicio 4 — el quinto panel

Añade al tablero un panel con la tasa de aciertos de la caché de `L06`:
`sum(rate(cache_gets_total{job="inv-api",result="hit"}[5m])) / sum(rate(cache_gets_total{job="inv-api"}[5m]))`.
Vuelve a publicarlo con `overwrite: true` y comprueba que el tablero tiene cinco paneles.
**Objetivo:** comprobar que el hit ratio que en `L06` moría con el proceso ahora tiene histórico, y
practicar el ciclo completo de editar y republicar un tablero versionado.

#### 🟢 Ejercicio 5 — el `for` que importa

Baja el `for` de la alerta a `0s`, reinicia Prometheus y repite el experimento de la sección 9
midiendo cuánto tarda en pasar a `firing`. Después súbelo a `2m` y repítelo.
**Objetivo:** medir tú el antirrebote en vez de creerte el número, y poder defender un valor
concreto cuando te pregunten por qué `for: 30s`.

### 🟡 Intermedio — aplicarlo a otra clase, otro endpoint u otra propiedad  (6–10)

#### 🟡 Ejercicio 6 — el health check que cuelga

Apunta el `SupplierHealthIndicator` al stub `SLW-000001`, el que tarda 30 segundos, y mide cuánto
tarda `/actuator/health`. Después arregla el problema sin tocar el `read-timeout` global: dale al
indicator su propio cliente con un timeout de 500 ms.
**Objetivo:** entender que el health corre en el hilo de quien pregunta, y que su presupuesto de
tiempo no es el del negocio.

#### 🟡 Ejercicio 7 — una alerta de latencia

Escribe una segunda regla, `ValuationLatencyHigh`, que se dispare cuando el p95 de
`/api/items/{sku}/valuation` pase de 500 ms durante un minuto. Provócala bajando el pool de Hikari
a una conexión y lanzando veinte peticiones concurrentes.
**Objetivo:** escribir una alerta sobre un histograma —con `le` en el `by`— y comprobar que se
dispara por una causa que tú provocaste, no esperando a que pase.

#### 🟡 Ejercicio 8 — el `MeterFilter` que renombra

Añade un `MeterFilter` que le ponga a **todos** los medidores un tag común `application: inv-api`
(pista: `MeterFilter.commonTags`). Comprueba en `/actuator/prometheus` que aparece en todas las
líneas y explica por qué esto **no** es un problema de cardinalidad.
**Objetivo:** distinguir una dimensión de valor único —que multiplica las series por uno— de una
dimensión abierta, con el ejemplo delante.

#### 🟡 Ejercicio 9 — la traza que se corta

Sustituye el `RestClient.Builder` inyectado del `SupplierGateway` por un `RestClient.create()` con
la URL a mano, repite la petición de la sección 10 y mira el journal de WireMock.
**Pregunta:** ¿qué cabecera desapareció, y qué vería alguien mirando el sistema de trazas?

#### 🟡 Ejercicio 10 — `scrape_interval` y resolución

Baja el `scrape_interval` a `5s` para el job `inv-api`, reinicia Prometheus, y compara durante cinco
minutos la curva de `tomcat_threads_busy_threads` con la que tenías a 15 s mientras lanzas ráfagas
cortas de peticiones.
**Objetivo:** ver con tus datos qué picos existen solo a 5 s, y poder argumentar el coste de
almacenamiento que eso compra.

### 🟠 Difícil — combinar, diagnosticar o decidir  (11–14)

#### 🟠 Ejercicio 11 — el circuito en el health, decidido

Comprueba qué le hace a `/actuator/health` un circuito abierto con
`register-health-indicator: true` de `L05`, y después con `allow-health-indicator-to-fail: false`.
Decide, y escríbelo en tres líneas, si ese indicator debe entrar en el grupo `readiness` de este
servicio.
**Pregunta:** si el circuito abierto saca tu instancia del balanceador, ¿qué pasa cuando **todas**
las réplicas tienen el circuito abierto porque el caído es el proveedor?

#### 🟠 Ejercicio 12 — diagnóstico a ciegas

Pídele a alguien —o escríbelo tú y espera un día— que introduzca **uno** de estos tres fallos sin
decirte cuál: un tag de alta cardinalidad en una métrica nueva, un `metrics_path` equivocado en
`prometheus.yml`, o un `exclude` que tapa un endpoint. Diagnostícalo usando solo Actuator,
`/api/v1/targets` y el tablero, anotando el orden de tus comprobaciones.
**Objetivo:** tener un procedimiento escrito para "el tablero no muestra nada", que es la mitad de
los incidentes de observabilidad.

#### 🟠 Ejercicio 13 — el `traceId` en el `@Scheduled`

El `ValuationRefreshJob` de `L06` corre cada veinte segundos fuera de cualquier petición. Mira qué
sale en su `traceId` y en su `requestId`, y consigue que el job tenga una traza propia envolviendo
su cuerpo en una `Observation`.
**Objetivo:** entender que una traza nace en un borde —HTTP, mensaje, reloj— y que el trabajo de
fondo no tiene una salvo que tú la crees.

#### 🟠 Ejercicio 14 — la alerta que miente

Provoca el escenario completo: circuito abierto, fallback devolviendo la última cotización buena, y
`SupplierCircuitOpen` en `firing`. Con el tablero delante, anota qué hace cada uno de los cuatro
paneles durante el incidente.
**Pregunta:** ¿cuál de las cuatro señales doradas se ve **mejor** durante el incidente que antes de
él, y qué conclusión sacaría alguien que solo mirara esa?

### 🔴 Muy difícil — abierto o adversarial  (15–16)

#### 🔴 Ejercicio 15 — el presupuesto de cardinalidad

Calcula, con los datos de tu propio `/actuator/prometheus`, cuántas series publica hoy `inv-api`
—`grep -c` sobre las líneas que no empiezan por `#`— y estima cuántas publicaría con 50 000 SKU
reales si añadieras un tag `sku` a `http.server.requests` y a tu `Timer` con histograma. Escribe
medio folio defendiendo un techo por servicio y qué mecanismos lo hacen cumplir.
**Objetivo:** convertir "la cardinalidad es mala" en un número con una unidad, que es la única
forma de que la discusión termine.

#### 🔴 Ejercicio 16 — observabilidad de una réplica que no ves

Levanta la segunda instancia de `L06` (`--server.port=8082 --management.server.port=8083`), añádela
al `prometheus.yml` con `instance: inv-api-b`, y consigue que el tablero distinga las dos: latencia
por instancia, y un panel que muestre **la suma** del tráfico. Después mata la B y explica qué le
pasa a cada panel y a `up`.
**Pregunta:** ¿por qué `sum(rate(...))` sin `by (instance)` sigue siendo correcto cuando muere una
réplica, y qué panel te habría mentido si hubieras graficado el valor absoluto de un contador?

### 🔥 Opcionales y ampliaciones

- **Un collector de trazas de verdad.** Añade `opentelemetry-exporter-otlp` al `pom.xml` y levanta
  un Zipkin o un Grafana Tempo **fuera** del Compose de la serie (`docker run` suelto, para no
  tocar el fichero), configura `management.otlp.tracing.endpoint` y mira el árbol de spans de una
  petición a `/quote`. Compara lo que ves con lo que dedujiste en la sección 10 con `grep`.
- **El `requestId` como contexto de Micrometer.** Registra un `ThreadLocalAccessor` para la clave
  `requestId` en el `ContextRegistry` y borra el `MdcTaskDecorator`. Comprueba que el `@Async` sigue
  correlacionado con un solo decorador.
- **Log estructurado.** Pon `logging.structured.format.console=ecs` y vuelve a lanzar los
  experimentos de las secciones 10 y 11. Mira qué se gana —campos consultables, `traceId` como
  campo y no como texto— y qué se pierde al leerlo con los ojos.
- **Métricas de la JVM que sí se miran.** Añade al tablero `jvm_gc_pause_seconds_max` y
  `jvm_memory_used_bytes{area="heap"}`, y provoca una pausa larga cargando la caché con miles de
  entradas.
- **`@Counted` y `@Observed`.** Sustituye el `@Timed` de la sección 5 por `@Observed` y mira qué
  publica de más: una observación genera métrica **y** span con el mismo nombre.

### 💀 Boss fight — el contrato de observabilidad de `inv-api`

Escribe, como artefacto entregable, el **contrato de observabilidad** de `inv-api`, y móntalo entero
sobre lo que tienes: un documento de una página más los ficheros que lo implementan.

1. **Los SLI y un SLO.** Define el indicador de disponibilidad y el de latencia sobre métricas que
   tu aplicación ya publica, y fija un objetivo con número y ventana (por ejemplo, 99 % de las
   valoraciones bajo 300 ms en 30 días). Escribe la consulta de Prometheus de cada uno.
2. **El tablero definitivo.** Las cuatro señales más el SLO, con el panel de `up` arriba del todo, y
   publicado por API desde un fichero versionado.
3. **Tres alertas, cada una con su justificación de por qué esa y no otra**: una de síntoma visible
   para el cliente (latencia o errores), una de causa que el síntoma tapa (el circuito de `L05`), y
   una de saturación (Hikari o hilos). Cada una con su `for` defendido y su anotación escrita para
   alguien dormido.
4. **El presupuesto de cardinalidad**, con el número de series de hoy, el techo que propones y el
   `MeterFilter` que lo hace cumplir.
5. **El procedimiento de diagnóstico en cinco pasos** para "está lento", empezando por qué endpoint
   de Actuator abres primero y terminando en qué te dice cada resultado. Pruébalo contra un fallo
   que provoques tú y ajústalo con lo que aprendas.

Se entrega cuando alguien que no hizo el lab puede seguir el procedimiento con tu documento
delante y llegar al mismo diagnóstico que tú.

---

## 🏁 La señal de que quedó bien

`docker compose -p inv-lab ps` lista cinco contenedores y una sola instancia de `inv-api`.
`http://localhost:3000/d/inv-api-golden` pinta cuatro paneles con datos de los últimos treinta
minutos, `curl -s localhost:9090/api/v1/rules | jq -r '.data.groups[].rules[].health'` dice `ok`, y
una petición con `X-Request-Id` deja en `app.log` una línea con tu identificador, un `traceId` de
treinta y dos caracteres y el mismo `traceId` dentro de la cabecera `traceparent` que guardó
WireMock.

Y lo que de verdad cuenta, que son las cuatro cosas que hoy pasaron de creencia a hecho comprobado.
**La primera:** el `health` verde no significa nada por sí solo —lo viste devolver `200` con diez
hilos ocupados y `503` con el proceso perfectamente sano—, y lo que decide si te reinician o si
solo dejan de mandarte tráfico es en qué grupo pusiste cada indicator. **La segunda:** un tag mal
elegido no es una métrica fea, son trescientas series de una tarde y un índice que sigue pagándolas
después de que arreglaste el código. **La tercera:** mientras el circuito de `L05` está abierto, tu
tablero de errores mejora, y por eso la alerta que hoy escribiste va sobre el estado del circuito y
no sobre los 5xx. **La cuarta:** el `traceId` no es un campo del log, es un contexto que hay que
propagar, y copiar el MDC arregla el log dejando la traza rota — que es la forma más silenciosa de
todas las de hoy.

Si dudas de alguna de las cuatro, el criterio de verdad de este lab no es el tablero: es el par de
comandos que lo comprueban sin abrir un navegador, `/api/v1/query` y `/api/v1/alerts`. Un tablero
que nadie puede verificar por API es una captura de pantalla con más pasos.

Los perfiles `db`, `ext`, `cache` y `obs` se quedan arriba. El siguiente lab pone Spring Security
delante —incluido delante de estos endpoints, que hoy están abiertos a quien alcance el puerto— y
después un proceso de Batch reiniciable; el capítulo de Security y el lab que lo acompaña llegan en
la tanda siguiente, y con ellos se cierra la tercera capa de defensa de Actuator que la sección 2
dejó nombrada y sin ejecutar.

---

## 📚 Referencias oficiales

- Spring Boot 3.5 — Actuator: exposición y acceso a endpoints: https://docs.spring.io/spring-boot/3.5/reference/actuator/endpoints.html
- Spring Boot 3.5 — Habilitar Actuator y el starter: https://docs.spring.io/spring-boot/3.5/reference/actuator/enabling.html
- Spring Boot 3.5 — Monitorización sobre HTTP y puerto de management: https://docs.spring.io/spring-boot/3.5/reference/actuator/monitoring.html
- Spring Boot 3.5 — Métricas: medidores autoconfigurados, `MeterFilter` y distribuciones: https://docs.spring.io/spring-boot/3.5/reference/actuator/metrics.html
- Spring Boot 3.5 — Trazas: bridges, sampling, propagación y correlación: https://docs.spring.io/spring-boot/3.5/reference/actuator/tracing.html
- Spring Boot 3.5 — Logging: patrones, niveles y `logging.pattern.correlation`: https://docs.spring.io/spring-boot/3.5/reference/features/logging.html
- Spring Boot 3.5 — Cómo se configura Actuator (recetas de `how-to`): https://docs.spring.io/spring-boot/3.5/how-to/actuator.html
- Spring Boot 3.5 — Índice de propiedades (`management.*`, `logging.*`): https://docs.spring.io/spring-boot/3.5/appendix/application-properties/index.html
- Spring Boot 3.5 — API de `HealthIndicator`: https://docs.spring.io/spring-boot/3.5/api/java/org/springframework/boot/actuate/health/HealthIndicator.html
- Spring Framework 6.2 — Observabilidad: observaciones, métricas y trazas: https://docs.spring.io/spring-framework/reference/6.2/integration/observability.html
- Spring Framework 6.2 — Task execution y scheduling (`TaskDecorator`): https://docs.spring.io/spring-framework/reference/6.2/integration/scheduling.html

### Documentación de terceros

- Micrometer 1.15 — conceptos, medidores y tags: https://docs.micrometer.io/micrometer/reference/1.15/concepts.html
- Micrometer 1.15 — el registro de Prometheus: https://docs.micrometer.io/micrometer/reference/1.15/implementations/prometheus.html
- Micrometer Tracing 1.5 — configuración, bridges y propagación: https://docs.micrometer.io/tracing/reference/1.5/configuring.html
- Micrometer Context Propagation — el mecanismo detrás de `ContextPropagatingTaskDecorator`: https://docs.micrometer.io/context-propagation/reference/
- Prometheus — configuración y `scrape_configs`: https://prometheus.io/docs/prometheus/latest/configuration/configuration/
- Prometheus — reglas de alerta: https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/
- Prometheus — funciones de consulta (`rate`, `histogram_quantile`): https://prometheus.io/docs/prometheus/latest/querying/functions/
- Prometheus — API HTTP (`/api/v1/targets`, `/api/v1/rules`, `/api/v1/alerts`): https://prometheus.io/docs/prometheus/latest/querying/api/
- Grafana — API HTTP de tableros: https://grafana.com/docs/grafana/latest/developer-resources/api-reference/http-api/dashboard/
- Grafana — configurar el origen de datos de Prometheus: https://grafana.com/docs/grafana/latest/datasources/prometheus/configure/
- Resilience4j — métricas de Micrometer (`resilience4j_circuitbreaker_state`): https://resilience4j.readme.io/docs/micrometer
- W3C — Trace Context (`traceparent`): https://www.w3.org/TR/trace-context/
- WireMock — documentación y API de administración: https://wiremock.org/docs/
