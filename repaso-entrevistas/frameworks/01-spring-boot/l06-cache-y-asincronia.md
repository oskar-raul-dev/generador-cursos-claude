# L06 — Caché y asincronía

> **Objetivo:** que `inv-api` deje de repetir la misma consulta cara, y que al terminar
> puedas demostrar —con un contador de llamadas al repositorio, dos procesos corriendo a la
> vez y las claves de Redis a la vista, no con una opinión— por qué una caché local miente
> en cuanto hay una segunda instancia, qué te cobra Redis por arreglarlo, y qué se queda
> pegado al hilo del request cuando el trabajo salta a otro hilo.
> **Asume:** [`17`](17-cache.md) y [`18`](18-asincronia-scheduling-y-eventos.md) leídos, y
> [`05`](05-proxies-y-aop.md) fresco. Este lab no repite su teoría: la ejecuta. Si no
> puedes explicar de memoria por qué [`17` §4](17-cache.md#4-️-el-proxy-otra-vez-self-invocation)
> y [`18` §3](18-asincronia-scheduling-y-eventos.md#3-️-las-dos-formas-de-que-async-no-haga-nada)
> son el mismo párrafo con distinta anotación, vuelve ahí: las secciones 3 y 8 de hoy viven
> de eso.
> **Prerrequisitos:** `L05` hecho. `inv-api` persiste en Postgres con Flyway y JPA, tiene
> `InventoryService` sobre `InventoryItemRepository`, un `SupplierGateway` decorado con
> Resilience4j, el `RequestIdFilter` de `L03` poniendo `requestId` en el MDC, y
> `server.tomcat.threads.max: 10` heredado de [`L05`](l05-clientes-y-resiliencia.md).
> **Costo:** **$0.00**. Tres contenedores en `localhost` y dos JVM de la misma aplicación.
> **Duración:** entre 170 y 200 minutos. Las secciones 5, 6 y 8 son el corazón del lab y
> ahí es donde tiene que irse el tiempo.
> **Qué deja levantado:** los perfiles `db` y `ext` que ya venían, más el perfil `cache`
> (`inv-lab-redis-1`). `L07` asume los tres arriba. La aplicación se lanza y se mata en
> cada sección, y en dos secciones se lanza **dos veces**.
> **Qué toca:** el `pom.xml`, `application.yml` y clases nuevas bajo
> `com.invlab.invapi.config` (`CacheConfig`, `AsyncConfig`, `MdcTaskDecorator`, `RedissonConfig`)
> y bajo `com.invlab.invapi.inventory` (`InventoryValuationService`, su fachada y
> `ValuationRefreshJob`). El `docker-compose.yml` no se amplía: solo se levanta su perfil
> `cache`. En el directorio del proyecto quedan además los `app-a.log` y `app-b.log` de las dos
> instancias.
> **Vigencia:** 18 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 ·
> Java 21 · Redis 8.6.6 · Redisson 3.52.0.

**Salto rápido:** [Estado inicial](#1--el-problema-y-el-estado-inicial) ·
[Caffeine y el contador](#2--caffeine-cacheable-y-el-contador-que-no-miente) ·
[Self-invocation con caché](#3-️-self-invocation-otra-vez-ahora-con-caché) ·
[TTL y `@CacheEvict`](#4-️-ttl-que-expira-y-cacheevict-que-invalida) ·
[Dos instancias, dos verdades](#5-️-dos-instancias-dos-cachés-dos-verdades) ·
[Redis con Lettuce](#6--redis-con-lettuce-arregla-la-incoherencia-y-cobra-la-serialización) ·
[Stampede](#7--stampede-la-clave-fría-y-el-sync) ·
[`@Async` y el `requestId`](#8--async-el-hilo-nuevo-y-el-requestid-que-se-queda-atrás) ·
[`@Scheduled` y el lock](#9-️-scheduled-por-duplicado-el-rlock-y-shedlock) ·
[Checklist](#10--checklist-de-salida) ·
[Preguntas rápidas](#-preguntas-rápidas) ·
[Ejercicios](#-ejercicios-15)

---

## 1. 🧭 El problema y el estado inicial

`L05` te enseñó a no molestar al proveedor cuando se porta mal. Hoy aprendes la otra forma
de no molestarlo, que es **no llamarlo**, y de paso la misma para tu propia base de datos.

El cambio de músculo de hoy es de criterio de verdad, otra vez:

```text
L04  →  ¿grabó?            → lo dices con un SELECT
L05  →  ¿salió a la red?   → lo dices con el journal de WireMock
L06  →  ¿ejecutó el método? → lo dices con un contador, porque el método que NO corre
                              no deja log, ni traza, ni excepción, ni nada
```

Ese es el problema pedagógico de la caché y de la asincronía: **los dos mecanismos se
manifiestan como ausencia**. Una caché que funciona es un método que no se ejecutó; un
`@Async` que funciona es un método que se ejecutó en otro lado. Ninguna de las dos cosas
se ve mirando el código de estado, y las dos fallan en silencio exactamente por la misma
razón que ya conoces: si la llamada no atraviesa el proxy, la anotación es un comentario.

Por eso el instrumento de hoy no es el log: es un **contador de llamadas al repositorio**
que vas a construir en la sección 2 y que no se va a callar en todo el lab.

Primero confirma que vienes del estado correcto:

```bash
docker compose -p inv-lab ps
cd inv-api
./mvnw -q clean package
java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -o /dev/null -w 'health -> %{http_code}\n' localhost:8081/actuator/health
curl -s -o /dev/null -w 'quote  -> %{http_code}\n' localhost:8080/api/items/ABC-000123/quote
docker exec -i inv-lab-postgres-1 psql -U inv_lab -d inv_lab \
  -c 'SELECT sku, quantity FROM inventory_item ORDER BY sku LIMIT 3'
```

- **`docker compose -p inv-lab ps` tiene que listar Postgres en `(healthy)` y WireMock en
  `Up`.** Si falta alguno, `L05` los dejó caídos: `docker compose --profile db --profile ext up -d`
  los devuelve. Si además faltan las tablas, hiciste `down -v` entre sesiones y Flyway las
  recrea en el arranque; el `ABC-000123` del `curl` sí tendrás que volver a crearlo con el
  `POST /api/items` de `L05`.
- **`./mvnw -q clean package` sin `-DskipTests`**, igual que en `L04` y `L05`: los tests de
  `L03` son la red de seguridad de todo lo que se va a mover hoy, y hoy se mueve la firma de
  una respuesta.
- **El `quote -> 200` confirma que el gateway y los decoradores de `L05` siguen enteros.**
  No vas a tocarlos, pero la sección 9 los usa de excusa para un job periódico.
- **`> app.log 2>&1 &`** sigue siendo la herramienta más usada de la serie, y hoy con un uso
  nuevo: a partir de la sección 8 lo que importa del log es **el nombre del hilo y el
  corchete del `requestId`**, y eso se cuenta con `grep`, no mirando la pantalla.

**Lo que vas a construir hoy, en orden**, y el porqué del orden: primero una consulta cara y
un contador que la mida (sección 2), porque sin instrumento no hay experimento; después la
caché local con sus dos fallos clásicos —el proxy (sección 3) y la invalidación (sección
4)—; después el fallo que solo existe cuando hay más de un proceso (sección 5), que es el
que justifica Redis (sección 6) y el que arrastra el stampede (sección 7). La segunda mitad
cambia de anotación pero no de mecanismo: `@Async` pierde el contexto del request (sección
8) y `@Scheduled` se duplica igual que la caché (sección 9), y el remedio de las dos vuelve
a ser el mismo proceso externo que montaste para cachear.

> **📝 Lo que este lab deja fuera a propósito.** **Ehcache 3** se queda en
> [`17` §5](17-cache.md#5--local-o-distribuida-el-veredicto) con su veredicto: su aporte
> —JSR-107 y memoria fuera del heap— se entiende leyendo y practicarlo sería escribir el
> mismo `@Cacheable` contra otro XML. **Los eventos de aplicación y el
> `@TransactionalEventListener`** de [`18` §9](18-asincronia-scheduling-y-eventos.md#9--el-evento-que-espera-al-commit)
> van como 🔥 opcional: el mecanismo ya lo demostró `L04` con la transacción, y aquí solo
> cambiaría quién publica. **El `traceId` de Micrometer Tracing** no existe todavía en el
> proyecto —llega con la observabilidad, en [`23` §10](23-actuator-y-observabilidad.md#10--trazas-traceid-spanid-w3c-y-sampling) y en `L07`—, así que el
> identificador que hoy se pierde y se propaga es el **`requestId`** del MDC que puso
> [`L03` §6](l03-api-rest-filtros-y-errores.md#6-️-el-x-request-id-que-se-filtra-a-la-petición-siguiente).
> Es el mismo `ThreadLocal` y el mismo fallo; solo cambia quién escribe la clave. Y el
> **`SecurityContext`** se nombra en la sección 8 pero no se ejecuta: no hay Spring Security
> en el classpath hasta `L08`, y montarlo hoy para perder un contexto sería levantar un IdP
> para probar un `ThreadLocal`.

---

## 2. 🧱 Caffeine, `@Cacheable` y el contador que no miente

El `GET /api/items/{sku}` de `L03` devuelve la fila y ya. Lo que de verdad piden los
consumidores de `inv-api` es la **valoración**: el item más la suma de todos sus
movimientos, que es un `join` con agregación sobre `inventory_event` y crece con el
histórico. Es la lectura repetida, cara y que cambia despacio de
[`17` §1](17-cache.md#1--el-problema-la-misma-respuesta-calculada-mil-veces).

Antes de cachear nada hace falta poder contar. Empieza por el pom:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-cache</artifactId>
</dependency>
<dependency>
    <groupId>com.github.ben-manes.caffeine</groupId>
    <artifactId>caffeine</artifactId>
</dependency>
```

- **`spring-boot-starter-cache`** trae la abstracción (`Cache`, `CacheManager`, el
  `CacheInterceptor`) y su autoconfiguración. **No trae ningún store**: sin nada más, Boot
  cae a un `ConcurrentMapCacheManager`, que es un `ConcurrentHashMap` sin límite de tamaño
  ni expiración — útil para un test, una fuga de memoria en producción.
- **`caffeine` sin `<version>`** porque está en el BOM de Boot 3.5.16 (§5.2 de la guía).
  Ponerle versión a mano aquí es cómo se rompe un upgrade de Boot seis meses después.
- **Basta con que esté en el classpath** para que `CacheAutoConfiguration` elija Caffeine:
  no hace falta `spring.cache.type`. Lo vas a escribir igual en la sección 6, cuando haya
  dos candidatos y la elección deje de ser obvia.

Ahora la consulta. En `InventoryItemRepository`, al lado de `totalsBySku()` de `L04`:

```java
@Query("""
       select new com.invlab.invapi.inventory.ItemView(
              i.sku, i.name, i.quantity, coalesce(sum(e.delta), 0))
       from InventoryItem i left join i.events e
       where i.sku = :sku
       group by i.sku, i.name, i.quantity
       """)
Optional<ItemView> findValuationBySku(@Param("sku") String sku);
```

```java
// DTO de salida: un record, no la entidad. La razón completa está tres bloques más abajo.
record ItemView(String sku, String name, int quantity, long movements) { }
```

- **`select new ...ItemView(...)`** es una proyección por constructor: la base devuelve
  cuatro columnas y Hibernate construye el `record`, sin sesión abierta y sin colección
  perezosa detrás. Es el patrón de `SkuTotal` en
  [`L04` §3](l04-datos-y-transacciones.md#3--jdbcclient-y-spring-data-jpa-lado-a-lado), y
  exige el **nombre completamente cualificado** de la clase: con el simple, el arranque
  falla al parsear la consulta, no la primera llamada.
- **`left join` y no `join`**: un item sin movimientos tiene que devolver `0`, no
  desaparecer del resultado. Con `join` a secas, un SKU recién creado responde `404` y el
  bug tarda semanas en aparecer porque en tu base de pruebas todo tiene eventos.
- **`coalesce(sum(e.delta), 0)`** convierte el `null` del agregado vacío en un cero. Sin él,
  `movements` sería `null` y el constructor del `record` reventaría con un `long` primitivo.
- **`@Param("sku")`** es obligatorio en `@Query` con parámetro nombrado salvo que compiles
  con `-parameters`; el plugin de Boot lo activa, pero escribirlo es gratis y sobrevive a
  que alguien cambie la configuración del compilador.

Y el servicio que la llama, en `src/main/java/com/invlab/invapi/inventory/InventoryValuationService.java`:

```java
@Service
class InventoryValuationService {

    private static final Logger log = LoggerFactory.getLogger(InventoryValuationService.class);

    private final InventoryItemRepository repository;
    private final Counter repositoryCalls;

    InventoryValuationService(InventoryItemRepository repository, MeterRegistry registry) {
        this.repository = repository;
        // el contador se registra una vez, en el arranque, no en cada llamada
        this.repositoryCalls = registry.counter("inventory.repository.calls");
    }

    @Cacheable(cacheNames = "inventory-items", key = "#sku")
    ItemView valuation(String sku) {
        repositoryCalls.increment();
        log.info("valoración de {} calculada contra la base", sku);
        return repository.findValuationBySku(sku)
                .orElseThrow(() -> new ItemNotFoundException(sku));
    }
}
```

- **`MeterRegistry` se inyecta y ya está**: lo publica el `spring-boot-starter-actuator` que
  tienes desde `L01`. Es el mismo registro del que salían `tomcat.threads.busy` y las
  métricas del circuit breaker en `L05`.
- **`registry.counter(...)` en el constructor y no dentro del método.** Buscar el `Meter` en
  cada llamada funciona, pero hace un `lookup` en un mapa concurrente por invocación; el
  patrón correcto es resolverlo una vez y guardar la referencia ⏱️.
- **`inventory.repository.calls` es el nombre en la convención de Micrometer** —puntos,
  minúsculas—, y cuando `L07` lo exporte a Prometheus se leerá como
  `inventory_repository_calls_total`. La traducción la hace el exportador, no tú: escribirlo
  ya con guiones bajos es el error que rompe el nombre en los demás backends.
- **`@Cacheable(cacheNames = "inventory-items", key = "#sku")`** es el nombre de caché fijo
  del laboratorio (§5.3 de la guía) y la clave explícita de
  [`17` §3](17-cache.md#3--la-clave-key-condition-unless-y-el-keygenerator). Con un solo
  argumento el `SimpleKeyGenerator` habría hecho lo mismo, y aun así se escribe: el día que
  el método reciba un segundo parámetro, la clave cambia sola y sin avisar.
- **No hay `@Transactional` aquí, y es deliberado.** La consulta es una sola y
  `SimpleJpaRepository` ya abre la suya. Anotarlo obligaría a preguntarse qué interceptor
  envuelve a cuál —los dos, el de caché y el de transacción, tienen el mismo `order` por
  defecto y el orden entre ellos no está definido—, y ese es un problema que se evita, no se
  resuelve.
- **Devuelve un `record` y no la entidad `InventoryItem`**, por tres razones que se cobran
  en tres secciones distintas: la entidad llega **detached** fuera de la transacción y su
  `events` es perezosa (`LazyInitializationException` de
  [`L04` §5](l04-datos-y-transacciones.md#5-️-lazyinitializationexception-con-open-in-view-false)),
  cachearla duplica en heap objetos que Hibernate cree suyos, y en la sección 6 habría que
  serializar un grafo con proxies dentro. **Se cachean DTOs.**

Falta encender la abstracción y exponer el endpoint:

```java
// src/main/java/com/invlab/invapi/config/CacheConfig.java
@Configuration
@EnableCaching          // registra el CacheInterceptor; sin esto no pasa absolutamente nada
class CacheConfig { }
```

```java
// en InventoryController, junto a los endpoints de L03
@GetMapping("/{sku}/valuation")
ItemView valuation(@PathVariable String sku) {
    return valuationService.valuation(sku);
}
```

- **`@EnableCaching` en su propia `@Configuration`** y no en la clase de arranque: el día que
  alguien busque "quién encendió la caché", `CacheConfig` aparece en el primer `grep`. En la
  sección 6 esta clase gana el `RedisCacheManagerBuilderCustomizer` y se agradece que exista.
- **El `ItemNotFoundException` del servicio ya lo traduce el `@RestControllerAdvice` de
  `L03`** a un `ProblemDetail` con `404`: el endpoint no necesita una línea de manejo de
  errores, y eso es exactamente lo que compraste en `L03`.
- **`valuationService` es un cuarto parámetro del constructor del controller**, sin
  `@Autowired`, porque sigue habiendo un solo constructor
  ([`03`](03-inyeccion-de-dependencias.md)).

La configuración de Caffeine, en `application.yml`:

```yaml
spring:
  cache:
    caffeine:
      spec: maximumSize=500,expireAfterWrite=30s,recordStats
```

- **`maximumSize=500`** es el techo **en entradas**, no en bytes, y es lo que convierte el
  mapa en una caché: al llegar desaloja por frecuencia y recencia en vez de crecer hasta el
  `OutOfMemoryError`.
- **`expireAfterWrite=30s`** es absurdo para producción —un catálogo tolera minutos— y es lo
  correcto para un lab: en la sección 4 vas a **verlo expirar** sin pasarte diez minutos
  mirando una terminal. El valor real se discute en la sección 4, con el TTL como red de
  seguridad de la invalidación.
- **`recordStats`** enciende los contadores de Caffeine. **Sin él, `cache.gets` no existe** y
  el hit ratio de Actuator devuelve un `404` que parece un bug de Boot y es tuyo.
- **`spec` aplica a todas las cachés de ese manager.** Hoy solo hay una; en cuanto haya dos
  con vidas distintas, hay que declarar el `CaffeineCacheManager` a mano
  ([`17` §5](17-cache.md#5--local-o-distribuida-el-veredicto)).

Y añade `caches` a lo expuesto por Actuator, que lo vas a usar en cuatro secciones:

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,env,configprops,metrics,threaddump,caches,scheduledtasks,circuitbreakers,circuitbreakerevents,retryevents
```

- **`caches`** lista las cachés vivas con su `CacheManager`, y responde a un `DELETE` que
  vacía una sin reiniciar. Es el vaciado manual que evita el `FLUSHDB` de la sección 6.
- **`scheduledtasks`** lista lo que el scheduler tiene agendado, con su cron o su periodo:
  la sección 9 lo usa como prueba de que un `@Scheduled` quedó registrado de verdad.
- **Los tres de Resilience4j siguen ahí** porque `L05` los puso y nada de hoy los quita. La
  lista crece documento a documento y en `L09`, con el perfil `prod`, se cierra casi entera.

**Predice antes de ejecutar.** Dos peticiones idénticas seguidas: ¿qué marca el contador
después de cada una, y qué se imprime en el log?

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s localhost:8080/api/items/ABC-000123/valuation
echo
curl -s localhost:8080/api/items/ABC-000123/valuation
echo
curl -s 'localhost:8081/actuator/metrics/inventory.repository.calls' | jq '.measurements[0].value'
grep -c 'calculada contra la base' app.log
```

```text
{"sku":"ABC-000123","name":"Tornillo M6","quantity":40,"movements":0}
{"sku":"ABC-000123","name":"Tornillo M6","quantity":40,"movements":0}
1
1
```

- **Las dos respuestas son idénticas y el contador marca `1`.** La segunda petición no
  ejecutó el método: el `CacheInterceptor` encontró la entrada y devolvió el valor sin bajar
  a `InventoryValuationService`. El `grep -c` lo confirma desde el otro lado: **una sola**
  línea de log.
- **`jq '.measurements[0].value'`** saca el único número que importa del JSON de
  `/actuator/metrics`, que trae además el nombre, la descripción y la lista de tags. Sin
  `jq` esto se lee, pero no se compara de un vistazo.
- **El contador es un `double` en Micrometer**, así que `jq` lo imprime como `1` y no como
  `1.0` solo porque el valor es exacto; no te sorprendas si en otra máquina lo ves con
  decimal.

Ahora el hit ratio, que es la única forma de defender la caché en una reunión:

```bash
curl -s 'localhost:8081/actuator/metrics/cache.gets?tag=cache:inventory-items&tag=result:hit'  | jq '.measurements[0].value'
curl -s 'localhost:8081/actuator/metrics/cache.gets?tag=cache:inventory-items&tag=result:miss' | jq '.measurements[0].value'
curl -s localhost:8081/actuator/caches | jq '.cacheManagers | keys'
```

```text
1
1
[
  "cacheManager"
]
```

- **Un `hit` y un `miss`**: el ratio es `1/(1+1) = 0,5`, que con dos peticiones no significa
  nada y con dos mil lo significa todo. Bajo ~0,8 en lecturas repetidas, lo primero que se
  revisa es la **clave**, no el TTL ([`17` §10](17-cache.md#10--sin-hit-ratio-esto-es-una-suposición)).
- **`?tag=cache:inventory-items&tag=result:hit`** filtra por dos dimensiones a la vez. Sin el
  segundo `tag`, `/actuator/metrics/cache.gets` devuelve la **suma** de hits y misses, que es
  el número que más gente enseña creyendo que son aciertos.
- **`/actuator/caches` te dice qué `CacheManager` está mandando de verdad.** Hoy dice
  `cacheManager` a secas —el de Caffeine— y en la sección 6 vas a volver aquí para comprobar
  que cambió sin tener que creerte la propiedad.

> **⏱️ Lo que acabas de comprar y lo que acabas de pagar.** Ganaste una consulta con
> agregación por cada acierto. Pagaste **hasta 500 `ItemView` vivos en heap** —con
> `maximumSize=500`, y ese número es el único que impide que la caché crezca sin tope— más
> una entrada que puede estar hasta **30 segundos por detrás** de la base. Los dos precios
> son explícitos y elegidos; el peligro está en la caché que no declara ninguno de los dos.

---

## 3. ⚠️ Self-invocation otra vez, ahora con caché

Lo viste con `@Transactional` en [`L04` §6](l04-datos-y-transacciones.md#6--el-gran-experimento-el-rollback-que-no-ocurre)
y lo vas a ver dos veces más hoy. No es repetición perezosa: es que **el 70 % de los fallos
silenciosos de Spring son este mismo**, y la única forma de que deje de sorprenderte es
reconocerlo con tres anotaciones distintas.

El requisito nuevo es razonable: un endpoint que valore varios SKU de una vez.

```java
// en InventoryValuationService — escrito mal a propósito
List<ItemView> valuations(List<String> skus) {
    return skus.stream()
            .map(this::valuation)      // llamada interna: el proxy NO participa
            .toList();
}
```

```java
// en InventoryController
@GetMapping("/valuations")
List<ItemView> valuations(@RequestParam List<String> skus) {
    return valuationService.valuations(skus);
}
```

- **`this::valuation` apunta al objeto real**, no al proxy, y el `CacheInterceptor` vive en
  el proxy. Da igual que sea una referencia a método o una llamada con `this.` escrito: el
  bytecode es el mismo `invokevirtual` sobre `this`.
- **`@RequestParam List<String> skus`** acepta `?skus=A,B,C` y también `?skus=A&skus=B`: el
  binder de Spring trata las dos formas igual. No lleva `@Valid` ni tope de tamaño a
  propósito, y el ejercicio 12 te va a pedir cuentas por eso.
- **Lo que no se ve aquí, y es todo el problema:** esta clase compila, pasa la revisión de
  código y no hay ninguna anotación mal escrita. El `@Cacheable` del método de al lado está
  perfecto. Lo que está roto es **desde dónde se llama**.

**Predice antes de ejecutar.** La caché ya tiene `ABC-000123` de la sección anterior. Pides
el mismo SKU tres veces en una sola petición: ¿cuánto sube el contador, cero, uno o tres?

```bash
BEFORE=$(curl -s localhost:8081/actuator/metrics/inventory.repository.calls | jq '.measurements[0].value')
curl -s -o /dev/null 'localhost:8080/api/items/valuations?skus=ABC-000123,ABC-000123,ABC-000123'
AFTER=$(curl -s localhost:8081/actuator/metrics/inventory.repository.calls | jq '.measurements[0].value')
echo "antes=$BEFORE despues=$AFTER"
```

```text
antes=1 despues=4
```

- **Tres llamadas a la base para un SKU que estaba cacheado.** No hubo acierto, no hubo
  error, no hubo log del interceptor: el método corrió tres veces como si la anotación no
  existiera. Y fíjate en lo peor: **la caché sí tenía el dato**.
- **La comprobación de `cache.gets` remata el diagnóstico.** Los contadores de `hit` y
  `miss` no se movieron, porque nadie consultó la caché. Ese es el síntoma que
  [`17` §10](17-cache.md#10--sin-hit-ratio-esto-es-una-suposición) describe como "si no hay
  ni `miss`, el problema es el proxy": una caché ignorada no registra ni fallos.

```text
llamada desde otro bean  → pasa por el proxy → hay CacheInterceptor → hit o miss
llamada desde this       → no hay proxy      → no hay interceptor   → ni hit, ni miss, ni log
```

La corrección tiene tres formas y el curso elige la misma que eligió en `L04`: **sacar el
método a otro bean**, porque es la única que sobrevive a una lectura apurada.

```java
@Service
class InventoryValuationFacade {

    private final InventoryValuationService valuations;     // otro bean: hay proxy

    InventoryValuationFacade(InventoryValuationService valuations) {
        this.valuations = valuations;
    }

    List<ItemView> valuations(List<String> skus) {
        return skus.stream().map(valuations::valuation).toList();
    }
}
```

- **`valuations::valuation` apunta al proxy**, porque el contenedor inyectó el proxy y no el
  objeto. Ese es el cambio entero: una referencia de campo en vez de `this`.
- **Las otras dos salidas existen y se nombran para poder descartarlas en una entrevista:**
  inyectarse a sí mismo el proxy —con `@Lazy` o un `ObjectProvider`, que es lo que hizo
  [`L04` §6](l04-datos-y-transacciones.md#6--el-gran-experimento-el-rollback-que-no-ocurre)
  para no mover la clase— y el modo AspectJ con weaving, que quita la limitación y añade una
  herramienta de build a tu proyecto ([`05` §6](05-proxies-y-aop.md#6--lo-que-un-proxy-no-puede-interceptar)).
- **`private` seguiría sin funcionar ni desde fuera**, y esa es la parte que casi todo el
  mundo dice mal: no es cuestión de `public`, es cuestión de si el proxy CGLIB puede
  sobrescribir el método y de si la llamada entra desde fuera del bean.

Apunta el controller al nuevo bean, reconstruye y repite el experimento:

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -o /dev/null 'localhost:8080/api/items/valuations?skus=ABC-000123,ABC-000123,ABC-000123'
curl -s localhost:8081/actuator/metrics/inventory.repository.calls | jq '.measurements[0].value'
curl -s 'localhost:8081/actuator/metrics/cache.gets?tag=cache:inventory-items&tag=result:hit' | jq '.measurements[0].value'
```

```text
1
2
```

- **Una llamada a la base y dos aciertos**, sobre una caché que arranca vacía porque
  reiniciaste el proceso. Esa es la otra cara de Caffeine que la sección 5 va a cobrar: **la
  caché vive en el heap, y el heap muere con la JVM**.
- **El contador reinició a cero con el proceso**, como toda métrica de Micrometer en
  memoria. Si te desconcierta ver `1` donde antes había `4`, esa es la razón, y es la misma
  por la que `L07` necesita Prometheus para poder comparar dos días.

> **🧠 El modelo mental, por tercera vez y ya sin analogía.** La anotación no está en tu
> método: está en el **envoltorio** que el contenedor puso alrededor de tu bean. Todo lo que
> entre por dentro se salta el envoltorio. `@Transactional`, `@Cacheable`, `@Retry`,
> `@Async`, `@PreAuthorize`: la misma frase, cinco veces.

---

## 4. ⏱️ TTL que expira y `@CacheEvict` que invalida

Tienes una caché que acierta. Ahora tienes el problema que la caché crea: **el dato cambió y
tú sigues contestando el viejo**. Con `expireAfterWrite=30s` esa ventana dura medio minuto y
se puede mirar de frente.

**Predice antes de ejecutar.** Vas a registrar un movimiento de `+10` y consultar la
valoración inmediatamente después. ¿Qué `quantity` te devuelve?

```bash
curl -s localhost:8080/api/items/ABC-000123/valuation
echo
curl -s -o /dev/null -w 'movimiento -> %{http_code}\n' -X POST \
  localhost:8080/api/items/ABC-000123/events -H 'Content-Type: application/json' \
  -d '{"delta":10,"reason":"recepcion"}'
curl -s localhost:8080/api/items/ABC-000123/valuation
echo
docker exec -i inv-lab-postgres-1 psql -U inv_lab -d inv_lab \
  -c "SELECT quantity FROM inventory_item WHERE sku = 'ABC-000123'"
```

```text
{"sku":"ABC-000123","name":"Tornillo M6","quantity":40,"movements":0}
movimiento -> 200
{"sku":"ABC-000123","name":"Tornillo M6","quantity":40,"movements":0}
 quantity
----------
       50
(1 row)
```

- **La base dice `50` y tu API dice `40`.** No hay error, no hay log, no hay código de
  estado raro: la aplicación está **mintiendo con toda confianza**, y esta es la forma más
  cara de fallar que tiene una caché.
- **Es el mismo patrón de `L04`**, con los papeles cambiados: allí el `SELECT` desmentía a un
  `200` que decía haber grabado; aquí el `SELECT` desmiente a un `200` que dice no haber
  cambiado. **El criterio de verdad sigue siendo la base.**
- **Espera treinta segundos y repite el `GET`**: sin tocar una línea de código, la respuesta
  pasa a `"quantity":50`. Eso es el `expireAfterWrite` haciendo su trabajo, y es la razón
  por la que el TTL se llama **red de seguridad**: incluso si nunca invalidas bien, el error
  tiene fecha de caducidad.

```bash
sleep 31
curl -s localhost:8080/api/items/ABC-000123/valuation
echo
```

```text
{"sku":"ABC-000123","name":"Tornillo M6","quantity":50,"movements":10}
```

- **`sleep 31` y no `sleep 30`**: `expireAfterWrite` cuenta desde la escritura de la entrada,
  que ocurrió unos milisegundos **antes** de tu primer `curl`. Pedirlo en el segundo exacto
  es cómo se consiguen experimentos que "a veces fallan".
- **`movements` pasó de `0` a `10`** además de la cantidad: el agregado y la fila se
  recalcularon juntos, que es justo lo que se cachea como una unidad.

Treinta segundos de mentira son inaceptables para un dato que **tú mismo acabas de
cambiar**. Ahí entra `@CacheEvict`, en la ruta de escritura:

```java
// en InventoryService, sobre el record(...) de L04
@CacheEvict(cacheNames = "inventory-items", key = "#sku")
@Transactional
InventoryItem record(String sku, int delta, String reason) { … }
```

- **`key = "#sku"` tiene que producir exactamente la misma clave que el `@Cacheable`.** Si
  uno usa el `sku` y el otro el objeto entero, la entrada que borras no es la que lees, y el
  bug es invisible: la invalidación "funciona" y la caché sigue vieja.
- **`beforeInvocation` se queda en `false`, que es el default**, y eso es una decisión: si
  `record` lanza `InsufficientStockException` —el caso de `L04`— no hay nada que invalidar
  porque no cambió nada. Con `beforeInvocation = true` borrarías la entrada en cada intento
  fallido y le regalarías una consulta a la base por cada movimiento rechazado.
- **El `@CacheEvict` y el `@Transactional` sobre el mismo método plantean una pregunta
  incómoda** y conviene decirla en voz alta antes de que la haga un entrevistador: el
  interceptor de caché borra **cuando el método retorna**, y el commit puede ocurrir después.
  Entre los dos instantes hay una ventana en la que otro hilo puede leer la base vieja y
  **repoblar la caché con el valor que acabas de invalidar**. Es microscópica y aquí es
  asumible porque el TTL la tapa a los 30 segundos; la solución limpia es invalidar desde un
  `@TransactionalEventListener(AFTER_COMMIT)`
  ([`18` §9](18-asincronia-scheduling-y-eventos.md#9--el-evento-que-espera-al-commit)), y va
  como 🔥 opcional.
- **Toda ruta de escritura sin anotar deja una entrada mintiendo hasta el TTL.** Hoy hay una
  sola; en cuanto haya un job, un consumidor de eventos o un `UPDATE` administrativo, la
  invalidación por evento deja de ser fiable. Por eso
  [`17` §9](17-cache.md#9--invalidación-coherencia-y-qué-no-se-cachea) dice que el TTL es la
  red **bajo** el evento y no su alternativa.

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -o /dev/null localhost:8080/api/items/ABC-000123/valuation
curl -s -o /dev/null -X POST localhost:8080/api/items/ABC-000123/events \
  -H 'Content-Type: application/json' -d '{"delta":5,"reason":"recepcion"}'
curl -s localhost:8080/api/items/ABC-000123/valuation
echo
```

```text
{"sku":"ABC-000123","name":"Tornillo M6","quantity":55,"movements":15}
```

- **La respuesta ya no espera a los 30 segundos.** El `POST` borró la entrada y el `GET`
  siguiente pagó un `miss` y trajo el dato nuevo. El precio es exactamente ese `miss`: una
  consulta a la base por cada escritura, que es lo que cuesta una invalidación correcta.
- **Comprueba la otra mitad** —que borra lo que tiene que borrar y nada más— con el endpoint
  de Actuator, que vacía la caché entera sin reiniciar:

```bash
curl -s -o /dev/null -w 'evict manual -> %{http_code}\n' -X DELETE localhost:8081/actuator/caches/inventory-items
```

```text
evict manual -> 204
```

- **`DELETE /actuator/caches/{nombre}`** vacía esa caché y devuelve `204`. Es el equivalente
  operativo de `@CacheEvict(allEntries = true)` y es la herramienta que evita el `FLUSHDB`
  a mano cuando algo se queda pegado en producción — con Actuator protegido, que es de
  `L08`. Hoy está abierto en `8081` porque en este lab `8081` no sale de tu máquina.

---

## 5. ⚠️ Dos instancias, dos cachés, dos verdades

Todo lo anterior es correcto y todo lo anterior deja de valer en cuanto despliegas la
segunda réplica. Esta es la sección que justifica el resto del lab, y la única forma de
entenderla de verdad es verla, porque **cada instancia por separado se comporta bien**.

La escena: `inv-api` detrás de un balanceador, dos pods, un `GET` que cae en cualquiera de
los dos. En tu máquina son dos `java -jar` con puertos distintos contra la misma base.

```bash
java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app-a.log 2>&1 &
java -jar target/inv-api-0.0.1-SNAPSHOT.jar \
  --server.port=8082 --management.server.port=8083 > app-b.log 2>&1 &
sleep 12
curl -s -o /dev/null -w 'A -> %{http_code}\n' localhost:8081/actuator/health
curl -s -o /dev/null -w 'B -> %{http_code}\n' localhost:8083/actuator/health
```

```text
A -> 200
B -> 200
```

- **`--server.port` y `--management.server.port` como argumentos de línea de comandos** ganan
  a todo lo que diga el `application.yml`: son la fuente de máxima precedencia de
  [`L02`](l02-configuracion-y-profiles.md) después de las variables de entorno con
  `SPRING_APPLICATION_JSON`. No hace falta un segundo fichero de configuración ni un perfil
  nuevo para levantar una réplica.
- **Los dos puertos de management también tienen que separarse.** Si solo cambias el 8080,
  la segunda instancia muere en el arranque con el 8081 ocupado, y el mensaje —un
  `BindException: Address already in use`— aparece enterrado en el segundo intento de
  arranque del contexto de management, no en la primera línea.
- **Las dos instancias comparten Postgres y no comparten absolutamente nada más.** Ese es el
  experimento entero: mismo estado en la base, dos heaps distintos.
- **Dos JVM son dos veces la memoria** ⏱️: cada `inv-api` pide del orden de 300 MB de heap
  reservado con los defaults de Java 21 en una máquina de 8 GB. Con Postgres, WireMock y el
  IDE abiertos ya se nota, y por eso la segunda instancia se mata al final de cada sección.

**Predice antes de ejecutar.** Vas a calentar la caché en las dos instancias, registrar un
movimiento **en la A** y volver a preguntar a las dos. ¿Qué contesta cada una?

```bash
echo "A: $(curl -s localhost:8080/api/items/ABC-000123/valuation)"
echo "B: $(curl -s localhost:8082/api/items/ABC-000123/valuation)"
curl -s -o /dev/null -X POST localhost:8080/api/items/ABC-000123/events \
  -H 'Content-Type: application/json' -d '{"delta":100,"reason":"recepcion"}'
echo "A: $(curl -s localhost:8080/api/items/ABC-000123/valuation)"
echo "B: $(curl -s localhost:8082/api/items/ABC-000123/valuation)"
```

```text
A: {"sku":"ABC-000123","name":"Tornillo M6","quantity":55,"movements":15}
B: {"sku":"ABC-000123","name":"Tornillo M6","quantity":55,"movements":15}
A: {"sku":"ABC-000123","name":"Tornillo M6","quantity":155,"movements":115}
B: {"sku":"ABC-000123","name":"Tornillo M6","quantity":55,"movements":15}
```

- **La cuarta línea es el corazón de este lab.** Las mismas dos peticiones al mismo recurso,
  con un segundo de diferencia, devuelven cien unidades de diferencia. Ninguna de las dos
  instancias tiene un bug: la A invalidó su caché correctamente, la B nunca se enteró de que
  había algo que invalidar.
- **`@CacheEvict` es local al `CacheManager` del proceso.** No es un broadcast, no hay
  protocolo, no hay nada escuchando en la otra JVM. La anotación hizo exactamente lo que
  promete; lo que estaba mal era lo que tú creías que prometía.
- **Detrás de un balanceador esto no se ve como un dato viejo: se ve como intermitencia.**
  El cliente refresca dos veces y obtiene dos números distintos porque cayó en pods
  distintos, y el ticket llega escrito como "a veces sale bien y a veces mal", que es el
  reporte más caro de diagnosticar que existe.
- **Y el TTL lo tapa, que es lo peor de todo.** A los 30 segundos las dos vuelven a
  coincidir, así que cuando alguien va a reproducirlo, ya no pasa.

> **⚠️ La sobregeneralización que esta sección existe para matar.** *"Le puse `@CacheEvict`,
> la caché queda coherente"*. La versión precisa: `@CacheEvict` invalida la caché **de este
> proceso**. Con N instancias tienes N cachés independientes, y una invalidación en una no
> toca a las otras N−1, que seguirán respondiendo el valor viejo hasta que su propio TTL
> expire. La coherencia entre réplicas **no es una propiedad de la anotación, es una
> propiedad del store**.

Las tres salidas, en orden de coste, y esto es material directo de entrevista:

```text
bajar el TTL local     → barato, no arregla nada: acorta la mentira a N segundos
mover la caché a Redis → un store compartido: una entrada, una invalidación
declarar la divergencia→ gratis y honesto, si el negocio tolera N segundos de desfase
```

**La tercera es una respuesta legítima y casi nadie la da.** Un catálogo de productos con
TTL de 60 segundos y dos réplicas no necesita Redis: necesita que alguien escriba en el
contrato que el dato puede tener un minuto. Lo que no se puede hacer es tener el desfase
**sin haberlo decidido**, que es exactamente donde estás ahora.

Aquí el dato es el stock y el consumidor es un proceso de conciliación, así que la respuesta
es la segunda. Antes de seguir, mata la segunda instancia:

```bash
kill %2
jobs
```

- **`kill %2` mata la instancia B**, que fue el segundo `java -jar` que lanzaste desde esta
  terminal. **`jobs` tiene que listar solo uno**; si no estás seguro de los números, un
  `pkill -f 'inv-api-0.0.1-SNAPSHOT.jar'` mata las dos y empiezas limpio.
- **La caché de la B muere con ella y no deja rastro**, que es la otra mitad del mismo
  hecho: lo que vive en el heap no sobrevive a un despliegue. En cuanto pasemos a Redis,
  esto se invierte —y eso también tiene precio, que la sección siguiente cobra.

---

## 6. 🧱 Redis con Lettuce: arregla la incoherencia y cobra la serialización

Un store compartido convierte N cachés en una. Levanta Redis, que es el perfil `cache` del
Compose que escribiste en [`L00` §6](l00-idea-lab-practico.md#6--el-docker-composeyml-de-la-serie)
y que hasta hoy no habías usado:

```bash
docker compose -p inv-lab --profile cache up -d
docker compose -p inv-lab ps
docker exec -i inv-lab-redis-1 redis-cli ping
```

```text
PONG
```

- **`--profile cache`** levanta solo Redis: ningún servicio de este Compose arranca sin su
  perfil, que es la decisión de `L00` que evita cargar siete contenedores para probar uno.
- **`redis-cli ping` respondiendo `PONG`** es la comprobación de que acepta conexiones, no de
  que el contenedor arrancó. Es el mismo `healthcheck` que declara el fichero, ejecutado a
  mano.
- **El teardown, aquí mismo y no en `L09`:**

```bash
docker compose -p inv-lab --profile cache down
docker compose -p inv-lab ps -a | grep -c redis
```

- **`down` sin `-v` basta para Redis y solo para Redis.** El servicio `redis` del Compose
  **no declara volumen**, así que lo que haya escrito muere con el contenedor: no hay
  `redis-data` que se quede por ahí con las claves de hace tres semanas. Postgres sí tiene
  volumen y por eso su teardown sí necesita `-v` ([`L04` §2](l04-datos-y-transacciones.md#2--postgres-en-compose-flyway-y-el-teardown)).
- **El `grep -c` tiene que devolver `0`.** La limpieza no se da por buena porque el comando
  no diera error, sino porque el listado sale vacío; es la misma disciplina de `L00 §9`.
- **Para vaciar la caché sin bajar nada** está `redis-cli FLUSHDB`, y conviene decir en voz
  alta por qué en producción es una mala idea: esa instancia de Redis suele ser compartida, y
  `FLUSHDB` se lleva por delante las cachés de los otros servicios que la usan. La forma
  quirúrgica es el `DELETE /actuator/caches/inventory-items` de la sección 4, o el prefijo
  por versión de clave de [`17` §9](17-cache.md#9--invalidación-coherencia-y-qué-no-se-cachea).

Vuelve a levantarlo y pasa la aplicación a Redis. En el pom:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
```

Y en `application.yml`:

```yaml
spring:
  cache:
    type: redis                 # ahora hay dos candidatos: la elección deja de ser obvia
  data:
    redis:
      host: localhost
      port: 6379
      timeout: 2s               # ⏱️ techo de espera por comando; sin él, el default son 60 s
      client-type: lettuce      # el default de Boot; se escribe porque hoy importa cuál es
```

- **`spring-boot-starter-data-redis` trae Lettuce**, que es el cliente por defecto desde Boot
  2.0 y multiplexa **una** conexión entre todos los hilos: el protocolo de Redis es
  secuencial y las respuestas vuelven en orden, así que no hay pool que dimensionar
  ([`17` §7](17-cache.md#7--lettuce-jedis-y-redisson)). Con Jedis sí lo habría, y sería otro
  pool más que se agota igual que el de Hikari.
- **`spring.cache.type: redis` no "enciende" la caché** —eso lo hizo `@EnableCaching`—: elige
  la implementación. Ahora hay dos en el classpath, Caffeine y Redis, y sin esta línea el
  orden de resolución de `CacheAutoConfiguration` decide por ti. **La dependencia de Caffeine
  se queda en el pom a propósito**: la sección 7 la va a necesitar para comparar, y el
  ejercicio 4 te pide volver con una sola propiedad.
- **`timeout: 2s`** es el equivalente para Redis del `read-timeout` que peleaste en
  [`L05` §3](l05-clientes-y-resiliencia.md#3-️-la-llamada-sin-timeout-y-el-hilo-que-no-vuelve):
  si Redis se queda mudo, tu hilo de Tomcat espera **sesenta segundos** con el default de
  Lettuce, y tu caché —que existe para ir más rápido— se convierte en la causa de la caída.
  Es la primera cosa que se configura y la última que se recuerda.
- **`client-type: lettuce` es redundante hoy y no lo va a ser en la sección 9**, cuando
  aparezca Redisson en el classpath y convenga que el fichero diga en voz alta quién habla
  con Redis para la caché.

**Predice antes de ejecutar.** La entidad no cambió, el `@Cacheable` no cambió, la clave no
cambió. Solo cambió el store. ¿Arranca y funciona, arranca y falla, o no arranca?

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -o /dev/null -w 'health -> %{http_code}\n' localhost:8081/actuator/health
curl -s -o /dev/null -w 'valuation -> %{http_code}\n' localhost:8080/api/items/ABC-000123/valuation
```

```text
health -> 200
valuation -> 500
```

Arranca perfectamente y revienta en la primera petición. En `app.log`:

```text
org.springframework.core.serializer.support.SerializationFailedException: Failed to serialize object using DefaultSerializer
	... 63 more
Caused by: java.lang.IllegalArgumentException: DefaultSerializer requires a Serializable payload but received an object of type [com.invlab.invapi.inventory.ItemView]
```

- **La primera línea nombra al culpable, y no es Redis ni es tu consulta:** es el
  **serializador**. `RedisCacheConfiguration.defaultCacheConfig()` usa
  `JdkSerializationRedisSerializer` para los valores, y la serialización de Java exige que el
  objeto implemente `java.io.Serializable`. Tu `record ItemView` no lo implementa.
- **La traza se poda con `... 63 more`** porque en medio hay sesenta frames de interceptores
  y proxies que no dicen nada; lo que nunca se recorta es la línea del `Caused by`, que es
  la que trae el nombre de tu clase.
- **El fallo llega en runtime y en la primera petición, no en el arranque.** Nada en el
  contexto sabe qué tipos vas a cachear, así que no hay validación posible: es el mismo
  patrón del `fallbackMethod` mal escrito de
  [`L05` §7](l05-clientes-y-resiliencia.md#7--bulkhead-saturado-y-el-fallback-honesto), y la
  prevención también es la misma, un test que ejerza la ruta.
- **La tentación es `record ItemView(...) implements Serializable`**, y funciona. Es
  exactamente lo que no vas a hacer, y el motivo es
  [`17` §6](17-cache.md#6--redis-como-caché-ttl-por-caché-y-serialización): la serialización
  JDK **ata el valor binario a la clase y a su `serialVersionUID`**. El día que añadas un
  campo y despliegues de forma gradual, la instancia vieja lee lo que escribió la nueva y
  falla al deserializar, con la caché llena de bombas que explotan una por una.

La corrección son doce líneas en `CacheConfig`:

```java
@Bean
RedisCacheManagerBuilderCustomizer cacheCustomizer(ObjectMapper mapper) {
    RedisCacheConfiguration items = RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(Duration.ofSeconds(30))                  // el mismo TTL corto del lab
            .prefixCacheNameWith("inv:")                       // inv:inventory-items::ABC-000123
            .serializeValuesWith(SerializationPair.fromSerializer(
                    new GenericJackson2JsonRedisSerializer(mapper)));
    return builder -> builder
            .withCacheConfiguration("inventory-items", items)
            .enableStatistics();                               // sin esto no hay hit ratio
}
```

- **`RedisCacheManagerBuilderCustomizer` ajusta el manager que autoconfigura Boot**, en vez
  de reemplazarlo. Si declaras tú el bean `CacheManager`, pierdes el resto de la
  autoconfiguración —incluida la integración con métricas— y te enteras cuando falte algo.
- **`entryTtl(Duration.ofSeconds(30))` es por caché.** El TTL por defecto del
  `RedisCacheManager` de Boot es **infinito**: una entrada mal invalidada vive hasta que
  alguien ejecute un `FLUSHDB`. En Caffeine el olvido te costaba memoria; aquí te cuesta un
  dato viejo para siempre, que es peor.
- **`prefixCacheNameWith("inv:")`** produce `inv:inventory-items::ABC-000123` en vez de
  `inventory-items::ABC-000123`. Sin prefijo, dos servicios con una caché del mismo nombre
  sobre la misma instancia de Redis se pisan los datos, y el síntoma es un `ClassCastException`
  en el servicio que menos culpa tiene. El prefijo del laboratorio es `inv:` (§5.3).
- **`GenericJackson2JsonRedisSerializer(mapper)` recibe el `ObjectMapper` del contexto**, el
  que Boot ya configuró con tus módulos —`JavaTimeModule` incluido, que es el que impide que
  un `Instant` acabe serializado como un número que nadie sabe leer—. Construir uno nuevo
  aquí es cómo se consigue que la caché y la API serialicen las fechas distinto.
- **`enableStatistics()`** es el `recordStats` de Caffeine en versión Redis. Sin esa línea,
  `cache.gets` deja de existir en cuanto cambias de store, y el hit ratio que montaste en la
  sección 2 desaparece sin que nadie lo diga.
- **Las claves no eran el problema y conviene tenerlo claro para no repetir el error del
  diagnóstico:** `defaultCacheConfig()` ya serializa las **claves** con `StringRedisSerializer`,
  así que son legibles desde el principio. Lo ilegible eran los **valores**. El caso de las
  claves binarias es el del `RedisTemplate` crudo, que sí usa el serializador JDK a los dos
  lados, y es el que enseñó [`15` §8](15-datos-jdbc-jpa-mongo-y-redis.md#8--mongo-y-redis-qué-te-da-spring-data-y-cuál-es-la-trampa).

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -o /dev/null -w 'valuation -> %{http_code}\n' localhost:8080/api/items/ABC-000123/valuation
docker exec -i inv-lab-redis-1 redis-cli KEYS 'inv:*'
docker exec -i inv-lab-redis-1 redis-cli TTL 'inv:inventory-items::ABC-000123'
docker exec -i inv-lab-redis-1 redis-cli GET 'inv:inventory-items::ABC-000123'
```

```text
valuation -> 200
1) "inv:inventory-items::ABC-000123"
(integer) 27
{"@class":"com.invlab.invapi.inventory.ItemView","sku":"ABC-000123","name":"Tornillo M6","quantity":155,"movements":115}
```

- **La clave se lee entera y dice de dónde sale**: prefijo, nombre de caché, `::`, clave. Ese
  `::` es el separador que pone Spring Data Redis entre el nombre y la clave, y es lo que te
  permite borrar una caché completa con un patrón sin tocar las demás.
- **`TTL` devuelve los segundos que le quedan**, contando hacia abajo desde 30. Si devolviera
  `-1` —que significa "sin expiración"— es que el `entryTtl` no se aplicó a esta caché, casi
  siempre por escribir mal el nombre en `withCacheConfiguration`.
- **`KEYS 'inv:*'` es para tu máquina y para nada más.** Recorre el keyspace completo y
  bloquea Redis mientras lo hace, porque Redis ejecuta los comandos en un solo hilo; en
  producción se usa `SCAN`, que itera en trozos. Decirlo aquí evita el incidente de mañana.
- **El JSON lleva `"@class"` delante**, y eso no es decorativo: es lo que permite a Jackson
  reconstruir el tipo al leer. La contrapartida está en la letra pequeña de
  [`17` §6](17-cache.md#6--redis-como-caché-ttl-por-caché-y-serialización): **renombrar o
  mover la clase invalida todo lo cacheado**, porque el nombre viajó dentro del dato. Es
  mucho mejor compromiso que el binario de JDK —esto se lee con `redis-cli` y no ata el
  campo a un `serialVersionUID`—, pero neutro no es.

⏱️ **Y ahora el precio, que es la parte que casi nadie cuenta.** Cada acierto ya no son
~100 nanosegundos de heap: son **una ida y vuelta por la red** —del orden de décimas de
milisegundo contra `localhost`, más en un clúster real— **más deserializar el JSON dentro
del hilo del request**. Delante de una consulta que ya tardaba un milisegundo, esta caché te
hace más lento; delante de la agregación con `join` que estás cacheando, sigue ganando. La
regla es la de [`17` §5](17-cache.md#5--local-o-distribuida-el-veredicto), y ahora la has
pagado: **Redis no es una caché más rápida, es una caché compartida**.

Ahora la prueba que justifica todo el capítulo. Levanta otra vez las dos instancias y repite
el experimento de la sección 5, sin cambiar nada más:

```bash
java -jar target/inv-api-0.0.1-SNAPSHOT.jar \
  --server.port=8082 --management.server.port=8083 > app-b.log 2>&1 &
sleep 12
echo "A: $(curl -s localhost:8080/api/items/ABC-000123/valuation)"
echo "B: $(curl -s localhost:8082/api/items/ABC-000123/valuation)"
curl -s -o /dev/null -X POST localhost:8080/api/items/ABC-000123/events \
  -H 'Content-Type: application/json' -d '{"delta":7,"reason":"recepcion"}'
echo "A: $(curl -s localhost:8080/api/items/ABC-000123/valuation)"
echo "B: $(curl -s localhost:8082/api/items/ABC-000123/valuation)"
docker exec -i inv-lab-redis-1 redis-cli KEYS 'inv:*'
```

```text
A: {"sku":"ABC-000123","name":"Tornillo M6","quantity":155,"movements":115}
B: {"sku":"ABC-000123","name":"Tornillo M6","quantity":155,"movements":115}
A: {"sku":"ABC-000123","name":"Tornillo M6","quantity":162,"movements":122}
B: {"sku":"ABC-000123","name":"Tornillo M6","quantity":162,"movements":122}
1) "inv:inventory-items::ABC-000123"
```

- **Las dos instancias contestan lo mismo**, y la razón está en la última línea: hay **una
  sola clave** para las dos. El `@CacheEvict` de la instancia A borró la entrada compartida,
  y la B pagó un `miss` en su siguiente lectura. La incoherencia de la sección 5 desapareció
  sin tocar una línea del código de negocio.
- **Lo que compraste es coherencia; lo que pagaste es una dependencia de infraestructura
  nueva en el camino de cada lectura.** Si Redis se cae ahora, tus lecturas fallan —a menos
  que lo trates como lo que es, un servicio externo, con el `timeout` que pusiste arriba y
  con la conversación sobre resiliencia que `L05` ya te dio.
- **Mata la segunda instancia antes de seguir** con `kill %2`, y déjala lista para volver:
  la sección 9 la necesita otra vez.

---

## 7. 🩺 Stampede: la clave fría y el `sync`

La caché coherente tiene un modo de fallo propio y contraintuitivo: **no amortigua el pico,
lo sincroniza**. Si mil peticiones llegan sobre una clave que acaba de expirar, la caché no
está ahí para ninguna, y las mil bajan a la base en el mismo segundo.

Para verlo hacen falta más peticiones simultáneas de las que tu Tomcat acepta hoy, porque
`L05` te dejó con diez hilos:

```yaml
server:
  tomcat:
    threads:
      max: 50                 # solo para esta sección; vuelve a 10 en el checklist
    accept-count: 5
```

- **Subir a 50 cambia la escala, no el fenómeno**, igual que bajarlo a 10 lo cambiaba en
  `L05`. Con diez hilos verías el stampede igual, pero con un techo de diez consultas
  simultáneas, y el número no se distinguiría del ruido.
- **`accept-count: 5` se queda como está**: la cola del socket no participa aquí, y cambiar
  dos cosas a la vez es lo que convierte un experimento en una anécdota. **Una variable a la
  vez.**

**Predice antes de ejecutar.** Treinta peticiones simultáneas sobre un SKU que **no** está en
la caché: ¿cuántas veces sube el contador de llamadas al repositorio?

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -o /dev/null -X POST localhost:8080/api/items -H 'Content-Type: application/json' \
  -d '{"sku":"CAC-000001","name":"Arandela M6","quantity":500}'
BEFORE=$(curl -s localhost:8081/actuator/metrics/inventory.repository.calls | jq '.measurements[0].value')
seq 1 30 | xargs -P 30 -I{} curl -s -o /dev/null localhost:8080/api/items/CAC-000001/valuation
AFTER=$(curl -s localhost:8081/actuator/metrics/inventory.repository.calls | jq '.measurements[0].value')
echo "llamadas a la base: $BEFORE -> $AFTER"
```

- **`seq 1 30 | xargs -P 30 -I{}`** lanza treinta `curl` **en paralelo**: `-P 30` es el grado
  de paralelismo y `-I{}` obliga a un comando por línea de entrada. Es el mismo ariete que
  usaste contra WireMock en `L05`, y sigue siendo la forma más corta de generar concurrencia
  real sin instalar nada.
- **El SKU es nuevo (`CAC-000001`)** para garantizar la clave fría. Repetir la prueba exige
  volver a enfriarla: `redis-cli DEL 'inv:inventory-items::CAC-000001'`, o el `DELETE` de
  Actuator.

El número exacto varía entre ejecuciones —depende de cuántos `curl` alcanzan el
`CacheInterceptor` antes de que el primero escriba en Redis—, pero está siempre **muy por
encima de uno y por debajo de treinta**: con esta máquina y este `maximumSize` verás del
orden de una o dos decenas de llamadas donde debería haber una. Eso es el stampede, y el
patrón es el que importa: **treinta lectores y ninguno encontró nada, porque ninguno había
terminado todavía de poner el dato**.

La corrección es un atributo:

```java
@Cacheable(cacheNames = "inventory-items", key = "#sku", sync = true)
ItemView valuation(String sku) { … }
```

- **`sync = true`** hace que, ante un fallo concurrente **sobre la misma clave**, un hilo
  ejecute el método y los demás esperen su resultado en vez de ejecutarlo también.
- **No admite `unless` y no todos los stores lo implementan.** Caffeine sí, a través de su
  `LoadingCache`; el `RedisCache` de Spring Data Redis también, y aquí viene el matiz que
  hay que saber decir: **esa espera es dentro de la JVM**. Con dos instancias tienes dos
  hilos ejecutando, uno por proceso, no uno en total. Para que fuera uno de verdad haría
  falta un lock distribuido —el `RLock` de la sección 9— o el cache writer con bloqueo de
  Spring Data Redis, y ninguna de las dos cosas es gratis.
- **Corta la avalancha por clave, no la expiración simultánea de claves distintas.** Si a las
  10:10:00 caducan doscientas entradas escritas a la vez, `sync` no te salva: ahí lo que
  sirve es el **TTL con jitter** de [`17` §8](17-cache.md#8--cache-stampede-el-minuto-en-que-todo-expira-a-la-vez),
  con el mismo argumento que el jitter de los reintentos de `L05`.

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
docker exec -i inv-lab-redis-1 redis-cli DEL 'inv:inventory-items::CAC-000001'
BEFORE=$(curl -s localhost:8081/actuator/metrics/inventory.repository.calls | jq '.measurements[0].value')
seq 1 30 | xargs -P 30 -I{} curl -s -o /dev/null localhost:8080/api/items/CAC-000001/valuation
AFTER=$(curl -s localhost:8081/actuator/metrics/inventory.repository.calls | jq '.measurements[0].value')
echo "llamadas a la base: $BEFORE -> $AFTER"
grep -c 'valoración de CAC-000001 calculada contra la base' app.log
```

El contador sube **una sola vez** y el `grep` devuelve `1`: veintinueve peticiones esperaron
a la primera y se llevaron su resultado. Las treinta respondieron `200`, y ninguna de las
veintinueve se enteró de que estuvo esperando.

- **El `DEL` explícito es parte del experimento**, no un detalle: sin enfriar la clave, las
  treinta peticiones aciertan y el contador no se mueve, lo cual "demuestra" algo que no es.
- **Si el `grep` devuelve más de uno**, revisa que reconstruiste el jar: `sync = true` es un
  atributo de anotación y vive en el bytecode, no en el `application.yml`.

> **⚠️ `sync = true` no es gratis y no es el default por algo.** Los hilos que esperan están
> **bloqueados** ⏱️: si el método tarda dos segundos, tienes veintinueve hilos de Tomcat
> retenidos dos segundos en vez de veintinueve consultas. Cambias carga en la base por
> hilos en el servidor, y esa es exactamente la palanca que agotó el pool en `L05`. Es el
> intercambio correcto cuando el método es caro y la clave es popular, y el incorrecto
> cuando el método puede colgarse.

---

## 8. 🧱 `@Async`, el hilo nuevo y el `requestId` que se queda atrás

Cambiamos de anotación y no de mecanismo. El problema de hoy: invalidar la caché en la
escritura deja la siguiente lectura pagando el `miss`, y ese `miss` cae sobre un cliente que
no tiene la culpa. Lo razonable es **recalentar la entrada en cuanto se invalida**, sin que
el `POST` espere por ello.

```java
// src/main/java/com/invlab/invapi/config/AsyncConfig.java
@Configuration
@EnableAsync                  // sin esto, @Async es un comentario decorado
class AsyncConfig {

    @Bean("inventoryExecutor")
    TaskExecutor inventoryExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(4);            // los hilos que de verdad gobiernan
        executor.setMaxPoolSize(8);
        executor.setQueueCapacity(50);          // acotada: una cola infinita es un OOM diferido
        executor.setThreadNamePrefix("inv-task-");
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(20);
        executor.initialize();                  // obligatorio al construirlo a mano
        return executor;
    }
}
```

- **`@EnableAsync` no lo pone Boot por ti.** La autoconfiguración crea un executor
  (`applicationTaskExecutor`), no activa la anotación: sin esta línea el método corre en el
  hilo del llamante, sin error y sin log ([`18` §2](18-asincronia-scheduling-y-eventos.md#2--async-quién-lo-ejecuta-y-qué-devuelve)).
- **`corePoolSize` es el número que gobierna tu concurrencia**, no `maxPoolSize`.
  `ThreadPoolTaskExecutor` **llena la cola antes de crecer**: con `queueCapacity: 50`, el
  hilo número cinco solo se crea cuando hay cincuenta tareas esperando. Con la cola por
  defecto —ilimitada— ese momento no llega nunca y `maxPoolSize` es decorativo
  ([`18` §4](18-asincronia-scheduling-y-eventos.md#4-️-el-executor-los-tres-números-y-la-cola-traicionera)).
- **La cola acotada obliga a elegir política de rechazo**, y aquí se queda el default:
  `AbortPolicy`, que lanza `TaskRejectedException` al que envía. Es ruidosa, y eso es
  deseable: una tarea descartada en silencio es trabajo perdido que nadie va a echar de menos
  hasta la conciliación.
- **`waitForTasksToCompleteOnShutdown` + `awaitTerminationSeconds`** son la pareja que impide
  que un `SIGTERM` vacíe la cola. **Van juntos**: sin el segundo, el apagado se compromete a
  drenar toda la cola sin techo mientras el resto del contexto se cierra, y tus tareas pueden
  encontrarse el `DataSource` ya cerrado.
- **`initialize()` no es opcional** cuando construyes el pool a mano: sin esa llamada el
  `ThreadPoolExecutor` interno no existe y la primera tarea revienta.
- **Declarar este bean apaga el `applicationTaskExecutor` de Boot**, porque el de
  `TaskExecutionAutoConfiguration` lleva `@ConditionalOnMissingBean(Executor.class)`. Por eso
  este pool trae sus tamaños a mano: los `spring.task.execution.*` del `application.yml` ya
  no aplicarían a nadie.
- **`inv-task-` es el prefijo que vas a buscar en el log** y en el `threaddump`. Un pool sin
  prefijo aparece como `pool-3-thread-2`, y averiguar de quién es ese pool a las dos de la
  mañana cuesta más que escribir esta línea.

Y el método asíncrono, en `InventoryValuationFacade` —otro bean, para que haya proxy:

```java
@Async("inventoryExecutor")                    // por nombre de bean, no por tipo
void warmUp(String sku) {
    log.info("recalentando la valoración de {}", sku);
    valuations.valuation(sku);                 // repuebla la caché: es una llamada normal
}
```

```java
// en InventoryController, después del POST de movimientos
@PostMapping(path = "/{sku}/events", consumes = MediaType.APPLICATION_JSON_VALUE)
ItemResponse record(@PathVariable String sku, @Valid @RequestBody EventRequest request) {
    ItemResponse response = ItemResponse.from(service.record(sku, request.delta(), request.reason()));
    facade.warmUp(sku);                        // vuelve de inmediato: el trabajo va a otro hilo
    return response;
}
```

- **`@Async("inventoryExecutor")` elige el executor por nombre de bean.** Sin el nombre, con
  dos candidatos de tipo `TaskExecutor`, **el arranque no falla**: el interceptor atrapa la
  `NoUniqueBeanDefinitionException`, lo dice en un log de nivel `INFO` y cae a un
  `SimpleAsyncTaskExecutor` **sin pool y con un hilo nuevo por tarea** ⏱️. Es degradación
  silenciosa, y el nombre entre comillas es lo único que la evita.
- **El retorno es `void` a propósito y tiene consecuencias.** Nadie va a esperar por el
  recalentamiento, así que no hay `CompletableFuture` que devolver; el precio es que **la
  excepción se la traga el handler por defecto** y el llamante nunca se entera. Si esto
  fuera dinero y no un caché, el retorno sería `CompletableFuture` y alguien lo consultaría.
- **`warmUp` se llama desde el controller, que es otro bean**, así que hay proxy. Llamarlo
  desde `InventoryService.record(...)` —dentro del mismo bean que acaba de invalidar— sería
  la self-invocation de la sección 3 por tercera vez, y correría en el hilo del request sin
  decir nada.
- **La llamada va después del `service.record(...)`**, que es transaccional. Lanzarla antes
  significaría recalentar con el dato viejo: la tarea asíncrona puede ganarle la carrera al
  commit, y entonces cacheas exactamente lo que acabas de invalidar.

**Predice antes de ejecutar.** El `POST` entra con un `X-Request-Id` tuyo. ¿Qué verás en las
dos líneas de log: el mismo `requestId` en las dos, o no?

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -o /dev/null -X POST localhost:8080/api/items/ABC-000123/events \
  -H 'Content-Type: application/json' -H 'X-Request-Id: movimiento-42' \
  -d '{"delta":3,"reason":"recepcion"}'
sleep 1
grep -E 'recalentando|calculada contra la base' app.log
```

```text
 INFO [sin-request-id] --- [   inv-task-1] c.i.i.InventoryValuationFacade  : recalentando la valoración de ABC-000123
 INFO [sin-request-id] --- [   inv-task-1] c.i.i.InventoryValuationService : valoración de ABC-000123 calculada contra la base
```

- **`[inv-task-1]` es la buena noticia:** el trabajo salió del hilo de Tomcat y corrió en tu
  pool, con el nombre que le pusiste. El `@Async` funciona.
- **`[sin-request-id]` es la mala, y es la que importa.** Ese literal lo escribiste tú en
  `L03` como valor por defecto del patrón `%X{requestId:-sin-request-id}` precisamente para
  este momento: **si lo ves, ese log corrió fuera del alcance del filtro**. El `requestId`
  `movimiento-42` se quedó en el hilo `http-nio-8080-exec-N`, porque el MDC vive en un
  `ThreadLocal` y **un `ThreadLocal` no cruza a otro hilo**
  ([`18` §5](18-asincronia-scheduling-y-eventos.md#5--propagación-de-contexto-lo-que-se-queda-en-el-hilo-del-request)).
- **En un incidente esto es la diferencia entre diez minutos y una tarde.** Tienes el
  `requestId` que te dio el cliente, haces `grep`, y las líneas que explican qué pasó
  **después** de la respuesta no aparecen: están en otro hilo, sin correlación, mezcladas con
  las de las otras doscientas peticiones.
- **El mismo mecanismo se lleva otras dos cosas**, y hay que poder enumerarlas: el
  `SecurityContext` —cuyo síntoma es una `AccessDeniedException` con un usuario que sí tiene
  el rol— y el `RequestContextHolder`, que da `IllegalStateException: No thread-bound request
  found`. Ninguna de las dos se ejerce hoy porque no hay Security en el classpath hasta
  [`L08` §7](l08-security-y-batch.md#7-️-el-securitycontext-que-no-cruza-al-async); el mecanismo es idéntico y el remedio también.

El remedio es el gancho oficial, un `TaskDecorator`:

```java
// src/main/java/com/invlab/invapi/config/MdcTaskDecorator.java
class MdcTaskDecorator implements TaskDecorator {

    @Override
    public Runnable decorate(Runnable task) {
        // esto corre en el hilo que ENVÍA la tarea: aquí el contexto todavía existe
        Map<String, String> context = MDC.getCopyOfContextMap();
        return () -> {
            // y esto, en el hilo que la EJECUTA
            if (context != null) {
                MDC.setContextMap(context);
            }
            try {
                task.run();
            } finally {
                MDC.clear();                 // el hilo del pool se reutiliza: esto NO es opcional
            }
        };
    }
}
```

```java
// en AsyncConfig, antes del initialize()
executor.setTaskDecorator(new MdcTaskDecorator());
```

- **`decorate` se ejecuta en el hilo del llamante**, en el momento de enviar la tarea, y ese
  es todo el truco: es el único instante en el que los dos contextos —el de origen y el
  `Runnable` de destino— están al alcance a la vez.
- **`getCopyOfContextMap` devuelve una copia**, no una vista. Propagar es **copiar**: si el
  filtro limpia el MDC al terminar el request —y lo hace, en su `finally`—, tu copia sigue
  viva en el otro hilo, que es justo lo que quieres.
- **Puede devolver `null`** cuando no hay nada en el MDC, y `MDC.setContextMap(null)` lanza
  `NullPointerException`. Ese `if` no es defensivo por costumbre: la tarea del `@Scheduled`
  de la sección 9 va a llegar aquí sin ningún contexto.
- **El `MDC.clear()` en el `finally` es la lección de
  [`L03` §6](l03-api-rest-filtros-y-errores.md#6-️-el-x-request-id-que-se-filtra-a-la-petición-siguiente)
  aplicada al pool.** Los hilos de `ThreadPoolTaskExecutor` se reutilizan igual que los de
  Tomcat: sin limpiar, la tarea siguiente hereda el `requestId` de la anterior y el log
  atribuye trabajo a la petición equivocada. Aquí sí es `clear()` y no `remove("requestId")`,
  porque lo que restauramos fue el mapa entero.
- **Lo que este decorador no hace, y lo hacen los oficiales:** para el contexto de
  observación de Micrometer —el `traceId` de verdad, el que llega con la observabilidad y el
  capítulo `23`— existe `ContextPropagatingTaskDecorator`, de Spring Framework 6.1+, que
  arrastra todo lo registrado en Micrometer Context Propagation; y para el
  `SecurityContext`, `DelegatingSecurityContextAsyncTaskExecutor`, que **decora al pool por
  fuera** en vez de sustituir el decorador. Los dos aparecen cuando aparezcan sus
  dependencias, en `L07` y `L08`. Escribir el tuyo primero no es trabajo tirado: es la única
  forma de saber qué hacen esos dos por dentro.

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -o /dev/null -X POST localhost:8080/api/items/ABC-000123/events \
  -H 'Content-Type: application/json' -H 'X-Request-Id: movimiento-43' \
  -d '{"delta":3,"reason":"recepcion"}'
sleep 1
grep 'movimiento-43' app.log
```

```text
 INFO [movimiento-43] --- [nio-8080-exec-3] c.i.i.InventoryController       : consultando sku ABC-000123
 INFO [movimiento-43] --- [   inv-task-2] c.i.i.InventoryValuationFacade  : recalentando la valoración de ABC-000123
 INFO [movimiento-43] --- [   inv-task-2] c.i.i.InventoryValuationService : valoración de ABC-000123 calculada contra la base
```

- **Un solo `grep` recupera la historia completa**, atravesando el salto de hilo: la columna
  del hilo cambia de `nio-8080-exec-3` a `inv-task-2` y el corchete no se mueve. Eso es lo
  que compraste con veinte líneas.
- **El número del hilo puede ser otro en tu máquina** —`inv-task-1`, `nio-8080-exec-5`—
  porque depende de cuántas peticiones haya atendido el proceso. Lo que no puede cambiar es
  que los dos últimos digan `inv-task-` y que los tres corchetes coincidan.

---

## 9. ⚠️ `@Scheduled` por duplicado, el `RLock` y ShedLock

Última vuelta a la misma tuerca. `inv-api` necesita un job periódico: refrescar la caché de
los SKU más consultados antes de que expiren, para que ningún cliente pague el `miss`. En
una instancia es trivial y correcto. Con dos, es el problema de la sección 5 otra vez, con
otra anotación.

```java
// src/main/java/com/invlab/invapi/inventory/ValuationRefreshJob.java
@Component
class ValuationRefreshJob {

    private static final Logger log = LoggerFactory.getLogger(ValuationRefreshJob.class);
    private static final List<String> HOT_SKUS = List.of("ABC-000123", "CAC-000001");

    private final InventoryValuationService valuations;
    private final CacheManager cacheManager;

    ValuationRefreshJob(InventoryValuationService valuations, CacheManager cacheManager) {
        this.valuations = valuations;
        this.cacheManager = cacheManager;
    }

    @Scheduled(fixedDelay = 20_000, initialDelay = 5_000)      // milisegundos
    void refreshHotSkus() {
        log.info("refrescando {} SKU calientes", HOT_SKUS.size());
        Cache cache = cacheManager.getCache("inventory-items");
        HOT_SKUS.forEach(sku -> {
            cache.evict(sku);            // invalida por API, sin anotación y sin proxy
            valuations.valuation(sku);   // y repuebla pagando el miss aquí, no el cliente
        });
    }
}
```

```java
// en AsyncConfig, junto a @EnableAsync
@EnableScheduling
```

```yaml
spring:
  task:
    scheduling:
      pool:
        size: 2                      # tantos como jobs puedan solaparse, no cuantos tengas
      thread-name-prefix: inv-sched-
```

- **`@EnableScheduling` es obligatorio** y es independiente de `@EnableAsync`: son dos
  infraestructuras distintas con dos pools distintos. Sin él, el `@Scheduled` no se registra
  y no hay ningún aviso; la comprobación barata es `curl localhost:8081/actuator/scheduledtasks`,
  que tiene que listar tu método con su `fixedDelay`.
- **`fixedDelay` cuenta desde que termina una ejecución hasta que empieza la siguiente**, así
  que se autorregula si el trabajo se alarga. Con `fixedRate` —de inicio a inicio— una tarea
  más lenta que el periodo acumula retraso y después dispara varias seguidas para ponerse al
  día. Para un refresco, `fixedDelay` es la elección obvia.
- **`initialDelay = 5_000`** evita que el job corra durante el arranque, cuando el pool de
  Hikari todavía se está llenando. Sin él, el primer disparo compite con la inicialización y
  el log del arranque se mezcla con el del job.
- **`cacheManager.getCache(...)` y `cache.evict(...)` son la API programática**, sin
  anotación. Se usa aquí a propósito: `@CacheEvict` necesita que la clave salga de los
  argumentos del método, y este método no recibe ninguno. Es también la prueba de que la
  abstracción de [`17` §2](17-cache.md#2--la-abstracción-de-spring-anotaciones-sobre-un-contrato)
  existe debajo de las anotaciones y se puede llamar directamente.
- **`spring.task.scheduling.pool.size` vale 1 por defecto**, y *todas* las tareas
  `@Scheduled` de la aplicación —las tuyas y las de tus librerías— comparten ese único hilo.
  Una que tarde cuarenta segundos retrasa cuarenta a todas las demás, sin un solo error en
  su log ([`18` §6](18-asincronia-scheduling-y-eventos.md#6--scheduled-el-reloj-y-el-pool-de-un-solo-hilo)).
- **`inv-sched-` separa el scheduler del executor de `@Async` en el log y en el thread
  dump.** Son pools distintos a propósito: compartirlos deja que un `@Async` lento bloquee
  el reloj ⏱️.

**Predice antes de ejecutar.** Dos instancias, un job cada veinte segundos. En un minuto,
¿cuántas veces se refresca cada SKU?

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app-a.log 2>&1 &
java -jar target/inv-api-0.0.1-SNAPSHOT.jar \
  --server.port=8082 --management.server.port=8083 > app-b.log 2>&1 &
sleep 60
grep -c 'refrescando' app-a.log
grep -c 'refrescando' app-b.log
```

```text
3
3
```

- **Seis ejecuciones donde el negocio pedía tres.** Cada JVM tiene su propio reloj y su
  propio scheduler, y ninguno sabe del otro. Con tres pods serían nueve.
- **Aquí el daño es barato** —unas consultas de más— y por eso es un buen sitio para
  aprenderlo. Cambia el job por "enviar el correo de cierre diario" o "aplicar el interés a
  las cuentas" y las seis ejecuciones son seis correos o un interés triplicado.

> Nunca respondas: ~~"`@Scheduled` se ejecuta una vez aunque haya tres réplicas"~~
>
> Mejor: "`@Scheduled` es **local al proceso**. Con N instancias hay N ejecuciones, y si el
> job no es idempotente, eso es N veces el daño. Para ejecutarlo una sola vez hace falta un
> **lock distribuido**, que Spring no trae."

Las tres salidas de [`18` §7](18-asincronia-scheduling-y-eventos.md#7-️-tres-réplicas-tres-ejecuciones),
aplicadas a este job concreto: **hacerlo idempotente** —que es lo que ya es, porque refrescar
una caché tres veces deja el mismo resultado y solo cuesta consultas—, **un lock
distribuido**, o **un scheduler externo** cuando la ejecución ya es una operación de negocio
con su auditoría. Para el resto de la sección vamos por la segunda, porque ya tienes el
Redis donde apoyarla.

En el pom:

```xml
<dependency>
    <groupId>org.redisson</groupId>
    <artifactId>redisson</artifactId>
    <version>3.52.0</version>
</dependency>
```

- **Versión explícita y verificada**, porque Redisson está **fuera del BOM de Boot** (§5.2 de
  la guía), igual que Resilience4j en `L05`. La `3.52.0` es la última de la línea 3.x y se
  construye contra Spring Boot 3.5: la línea **4.x existe y no sirve aquí**, porque apunta al
  BOM de Boot 4.1 y a Spring Framework 7 📝.
- **Se usa `redisson` y no `redisson-spring-boot-starter` a propósito.** El starter sustituye
  la `RedisConnectionFactory` del contexto por la suya, y entonces tu caché —que ahora mismo
  habla por Lettuce— pasaría a hablar por Redisson sin que tú lo pidieras. Hoy queremos
  exactamente lo contrario: Lettuce para la caché, Redisson **solo** para el lock, y las dos
  cosas visibles en el `application.yml` y en la configuración. Es la aplicación literal de
  "una variable a la vez".

```java
// src/main/java/com/invlab/invapi/config/RedissonConfig.java
@Configuration
class RedissonConfig {

    @Bean(destroyMethod = "shutdown")
    RedissonClient redissonClient(RedisProperties properties) {
        Config config = new Config();
        config.useSingleServer()
                // reusa el host y el puerto que ya configuraste para la caché
                .setAddress("redis://%s:%d".formatted(properties.getHost(), properties.getPort()))
                .setConnectionMinimumIdleSize(1)
                .setConnectionPoolSize(4);
        return Redisson.create(config);
    }
}
```

- **`destroyMethod = "shutdown"`** cierra el cliente cuando el contexto se cierra. Sin él,
  los hilos de Netty de Redisson siguen vivos y el `graceful shutdown` de [`L09` §7](l09-empaquetado-imagen-y-limpieza.md#7--graceful-shutdown-con-una-petición-en-vuelo) se queda
  esperando a un proceso que no muere.
- **`RedisProperties` es el bean de `spring.data.redis`** que ya llenaste arriba: leer de ahí
  evita tener el host escrito en dos sitios, que es cómo se consigue que la caché apunte a
  un Redis y el lock a otro. En Boot 4.x esta clase cambió de módulo con la partición de la
  autoconfiguración 📝.
- **`redis://` es el esquema sin TLS**; con TLS sería `rediss://`. En el lab es correcto —es
  `localhost`— y fuera de tu máquina no lo sería, porque el lock viaja en claro igual que
  todo lo demás.
- **`setConnectionPoolSize(4)` acota lo que este cliente reserva** ⏱️: Redisson mantiene sus
  propias conexiones, aparte de la que multiplexa Lettuce. Cuatro sobran para un lock que se
  toma tres veces por minuto, y dejar el default —que es bastante mayor— es memoria y sockets
  para nada.

Y el job toma el lock:

```java
@Scheduled(fixedDelay = 20_000, initialDelay = 5_000)
void refreshHotSkus() throws InterruptedException {
    RLock lock = redisson.getLock("inv:lock:valuation-refresh");
    // no espera nada por el lock; lo suelta solo a los 15 s aunque el proceso muera
    if (!lock.tryLock(0, 15, TimeUnit.SECONDS)) {
        log.info("otra instancia tiene el lock, no refresco");
        return;
    }
    try {
        log.info("refrescando {} SKU calientes", HOT_SKUS.size());
        …
    } finally {
        lock.unlock();
    }
}
```

- **`tryLock(0, 15, TimeUnit.SECONDS)`**: el primer número es cuánto esperas a que se libere
  —cero, porque si otro nodo ya está refrescando no hay nada que hacer aquí— y el segundo es
  el `leaseTime`, cuánto lo retienes como máximo **aunque tu proceso muera**. **Sin
  `leaseTime`, un proceso que se cae con el lock tomado bloquea a los demás para siempre.**
- **El `leaseTime` es una apuesta y hay que decirlo:** si el refresco tardara más de quince
  segundos, otra instancia entraría mientras la primera sigue trabajando, y el lock que creías
  exclusivo deja de serlo sin ningún aviso.
- **`tryLock` declara `InterruptedException`** porque `RLock` extiende `Lock`. Aquí se
  propaga en la firma del método; la alternativa es capturarla restaurando el flag con
  `Thread.currentThread().interrupt()`. Tragársela sin más deja un hilo que ya no sabe que le
  pidieron parar.
- **El `unlock()` va en `finally`**, y aun así, si la JVM muere, solo el lease libera. Las
  dos cosas juntas —el `finally` para el caso normal, el lease para el catastrófico— son el
  patrón completo.
- **La clave lleva el prefijo `inv:`**, el mismo del laboratorio, para que un `KEYS 'inv:*'`
  muestre a la vez las entradas de caché y los locks y quede claro que **es el mismo Redis
  haciendo dos trabajos distintos** ([`17` §7](17-cache.md#7--lettuce-jedis-y-redisson)).

```bash
pkill -f 'inv-api-0.0.1-SNAPSHOT.jar'
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app-a.log 2>&1 &
java -jar target/inv-api-0.0.1-SNAPSHOT.jar \
  --server.port=8082 --management.server.port=8083 > app-b.log 2>&1 &
sleep 60
echo "A refrescó: $(grep -c 'refrescando' app-a.log), cedió: $(grep -c 'no refresco' app-a.log)"
echo "B refrescó: $(grep -c 'refrescando' app-b.log), cedió: $(grep -c 'no refresco' app-b.log)"
```

La suma de los dos "refrescó" es tres —una ejecución por ventana, no dos— y el resto son
cedidas. **Cuál de las dos instancias gana cada vuelta no es determinista** y depende de
milisegundos de arranque: si en tu ejecución la A se lleva las tres y la B cede tres veces,
el experimento salió bien igual. Lo que no puede pasar es que la suma dé seis.

- **`pkill -f` mata las dos instancias de una vez**, buscando por la línea de comandos
  completa. Es más seguro que `kill %1 %2` cuando ya perdiste la cuenta de los jobs de la
  terminal, que a esta altura del lab es lo normal.
- **Comprueba el lock en vivo** mientras el job corre, con `redis-cli KEYS 'inv:lock:*'`: la
  clave aparece durante el refresco y desaparece al soltarse. Si se queda ahí quince segundos
  después de que el job terminó, el `unlock()` no se está ejecutando.

> **⚠️ Lo que acabas de montar es una optimización, no una garantía de corrección.** Este es
> un lock sobre **una sola** instancia de Redis: si hace failover a una réplica que no
> alcanzó a recibir la clave, dos procesos lo tienen a la vez. Redlock —el algoritmo sobre N
> instancias— nació para eso y está discutido, y la crítica vale para ambos: **sin fencing
> token no hay exclusión mutua** ante una pausa de GC o un reloj desviado. Una pausa larga
> puede dejar a tu proceso creyendo que tiene el lock cuando el lease ya expiró y otro lo
> tomó; el fencing token —un número que crece con cada concesión y que el recurso protegido
> verifica y rechaza si viene atrasado— es lo que cierra ese hueco, y **exige colaboración
> del recurso**, no del lock. Si de la exclusión depende la corrección, se resuelve donde
> está el dato: restricción única, `UPDATE ... WHERE version = ?`, idempotencia.

**Para un `@Scheduled` con lock, el estándar de hecho no es esto: es ShedLock**, y conviene
saber por qué antes de que te lo pregunten. Redisson te dio una primitiva de coordinación de
propósito general —`RLock`, `RSemaphore`, `RRateLimiter`— y tú escribiste el cableado a mano;
ShedLock hace justo una cosa, envolver métodos `@Scheduled` con `@SchedulerLock`, y trae los
dos parámetros que aquí quedaron implícitos: `lockAtMostFor`, que es el lease con otro
nombre, y `lockAtLeastFor`, que **impide que dos relojes ligeramente desfasados ejecuten dos
veces seguidas**. Su proveedor puede ser Redis, una tabla de Postgres o media docena más, y
en la línea 6.x —`net.javacrumbs.shedlock:shedlock-spring:6.10.0`— corre sobre Spring
Framework 6.2, que es el baseline del curso; la línea 7.x ya exige Spring 7 📝. Y tampoco
garantiza nada más allá de esto: **si quien tomó el lock muere a la mitad, esa ejecución se
pierde hasta la vuelta siguiente**, que en un job diario significa hasta mañana. El ejercicio
15 te pide montarlo y comparar.

Antes de cerrar, mata la segunda instancia y deja una sola corriendo:

```bash
kill %2
jobs
```

- **`jobs` tiene que listar un solo `java -jar`.** Dejar dos instancias vivas entre sesiones
  es la forma más rápida de que el `L07` de mañana empiece con un puerto ocupado y un job
  ejecutándose el doble de veces sin que nadie recuerde por qué.

---

## 10. 📋 Checklist de salida

- [ ] `docker compose -p inv-lab ps` lista `inv-lab-postgres-1` en `(healthy)`, `inv-lab-wiremock-1` en `Up` e `inv-lab-redis-1` en `Up`.
- [ ] `docker exec -i inv-lab-redis-1 redis-cli ping` responde `PONG`.
- [ ] `grep -c 'spring-boot-starter-cache' pom.xml` devuelve `1`, y `caffeine`, `spring-boot-starter-data-redis` y `redisson` con versión `3.52.0` están declarados.
- [ ] Dos `GET /api/items/ABC-000123/valuation` seguidos dejan `inventory.repository.calls` en el mismo valor, y `cache.gets` con `result:hit` sube en uno.
- [ ] `GET /api/items/valuations?skus=ABC-000123,ABC-000123,ABC-000123` produce **una** llamada al repositorio y dos aciertos.
- [ ] Un `POST` de movimiento seguido de un `GET` devuelve la cantidad nueva sin esperar al TTL.
- [ ] `DELETE localhost:8081/actuator/caches/inventory-items` responde `204`.
- [ ] Con las dos instancias y `spring.cache.type: redis`, el `GET` en `8080` y en `8082` devuelven lo mismo después de un `POST` en `8080`.
- [ ] `redis-cli KEYS 'inv:*'` muestra **una sola** clave `inv:inventory-items::ABC-000123`, `TTL` devuelve un número positivo y `GET` devuelve JSON legible con `@class`.
- [ ] Treinta peticiones concurrentes sobre una clave recién borrada producen **una** línea `calculada contra la base` con `sync = true`.
- [ ] `server.tomcat.threads.max` volvió a `10` después del experimento de la sección 7.
- [ ] `grep 'movimiento-43' app.log` devuelve tres líneas, dos de ellas en un hilo `inv-task-`.
- [ ] `curl -s localhost:8081/actuator/scheduledtasks | jq '.fixedDelay'` lista `refreshHotSkus` con `20000` ms.
- [ ] Con dos instancias y un minuto de espera, las líneas `refrescando` de `app-a.log` y `app-b.log` **suman** tres, no seis.
- [ ] `./mvnw -q clean package` pasa en verde con los tests de `L03` intactos y `jobs` lista como mucho un `java -jar` al terminar.

---

## 🧠 Preguntas rápidas

1. Con `@Cacheable` puesto y `@EnableCaching` ausente, ¿qué pasa exactamente y cuál es el
   primer indicio que lo delata?
2. Tu `@Cacheable` no registra ni un `hit` ni un `miss` en `cache.gets`, y el contador de
   llamadas al repositorio sube en cada petición. ¿Qué descartas y qué concluyes?
3. ¿Por qué el lab cachea un `record ItemView` y no la entidad `InventoryItem`? Da las tres
   razones, cada una con el problema concreto que evita.
4. `recordStats` en Caffeine y `enableStatistics()` en el `RedisCacheManagerBuilder`: ¿qué
   se rompe si migras de store y olvidas el segundo?
5. Explica por qué `@CacheEvict` sobre el método de escritura deja una ventana en la que otro
   hilo puede repoblar la caché con el valor viejo, y cuál es la forma limpia de cerrarla.
6. "Le puse `@CacheEvict`, la caché queda coherente." Corrige la frase con la versión precisa
   y di de qué depende la coherencia entre réplicas.
7. Enumera las tres salidas al problema de dos cachés locales incoherentes y di cuándo eliges
   la que no cuesta infraestructura.
8. Tu primera petición tras pasar a Redis falla con `DefaultSerializer requires a Serializable
   payload`. ¿Por qué no falla el arranque, y por qué la solución **no** es implementar
   `Serializable`?
9. ¿Qué serializa Boot con `StringRedisSerializer` y qué con `JdkSerializationRedisSerializer`
   en la configuración de caché por defecto? ¿Dónde estaba entonces el caso de las claves
   binarias ilegibles?
10. ¿Qué corta `sync = true` y qué no corta? Responde con lo que ocurre con treinta peticiones
    a una clave fría en una instancia y en dos.
11. Un `@Async` corre en `inv-task-2` y su log sale con `[sin-request-id]`. Nombra el
    mecanismo exacto que falta, en qué hilo hay que resolverlo y por qué ahí y no en otro.
12. ¿Por qué el `MDC.clear()` del `TaskDecorator` va en un `finally`, y qué síntoma produce
    olvidarlo? Relaciónalo con el bug del filtro de `L03`.
13. `tryLock(0, 15, TimeUnit.SECONDS)`: di qué es cada número y qué pasa si el trabajo
    protegido tarda veinte segundos.
14. ¿Qué te da un `RLock` de Redisson, qué no te da, y qué aporta ShedLock que aquí tuviste
    que escribir a mano?

---

## 🧪 Ejercicios (15)

### 🟢 Fácil — repetir lo del lab con otro valor o en otro punto  (1–5)

#### 🟢 Ejercicio 1 — otro TTL, medido

Cambia `expireAfterWrite` de Caffeine a `10s`, vuelve a `spring.cache.type: caffeine`,
calienta la caché y mide con `date +%s` cuántos segundos pasan hasta que la respuesta refleja
un cambio hecho directamente con `UPDATE` en Postgres.
**Objetivo:** que el TTL deje de ser un número del fichero y pase a ser una ventana de
mentira que puedes cronometrar.

#### 🟢 Ejercicio 2 — una segunda caché con otro nombre

Cachea `totalsBySku()` de `L04` en una caché llamada `inventory-totals`. Comprueba con
`/actuator/caches` que aparecen las dos y con `redis-cli KEYS 'inv:*'` que las claves no se
pisan.
**Pregunta:** con `spring.cache.caffeine.spec`, ¿puedes darle a esta caché un TTL distinto
del de `inventory-items`? ¿Por qué?

#### 🟢 Ejercicio 3 — el `condition` que apaga la caché

Añade `condition = "#sku.startsWith('CAC')"` al `@Cacheable` de `valuation`. Demuestra con el
contador que `ABC-000123` deja de cachearse y `CAC-000001` sigue haciéndolo.
**Objetivo:** ver que `condition` se evalúa **antes** y que cuando es `false` la caché ni se
consulta ni se escribe.

#### 🟢 Ejercicio 4 — volver a Caffeine con una sola propiedad

Con todo el código de hoy intacto, vuelve a la caché local cambiando únicamente
`spring.cache.type`. Comprueba con `/actuator/caches` que el `CacheManager` cambió y con
`redis-cli KEYS 'inv:*'` que ya no se escribe nada en Redis.
**Pregunta:** ¿qué le pasa al `RedisCacheManagerBuilderCustomizer` que escribiste, y por qué
eso no rompe el arranque?

#### 🟢 Ejercicio 5 — el segundo hilo del scheduler

Añade un segundo `@Scheduled` que tarde treinta segundos (con un `Thread.sleep`) y baja
`spring.task.scheduling.pool.size` a `1`. Mide con las marcas de tiempo del log cuánto se
retrasa `refreshHotSkus`.
**Objetivo:** reproducir el job que "se salta ejecuciones" sin un solo error en su log.

### 🟡 Intermedio — aplicarlo a otra clase, otro endpoint u otra propiedad  (6–10)

#### 🟡 Ejercicio 6 — cachear la cotización del proveedor

Pon `@Cacheable` sobre `SupplierGateway.quote(...)` de `L05`, en una caché
`supplier-quotes` con TTL de 60 segundos. Demuestra con el journal de WireMock
(`/__admin/requests`) que las llamadas al proveedor bajan.
**Pregunta:** ¿qué pasa con el `fallbackMethod` del circuit breaker cuando la respuesta viene
de la caché, y en qué orden se apilan ahora los interceptores?

#### 🟡 Ejercicio 7 — el `@CachePut` que no debía estar

Pon `@CachePut` **junto** a `@Cacheable` en el mismo método y arranca. Documenta qué hace la
aplicación y con qué contador lo demuestras.
**Objetivo:** comprobar que Spring **no rechaza** esa combinación en el arranque y que el
resultado es peor que un fallo, porque queda indefinido.

#### 🟡 Ejercicio 8 — el TTL con jitter

Escribe un `RedisCacheConfiguration` cuyo TTL sea de 30 segundos ± 10 % por entrada. Calienta
veinte claves de golpe y comprueba con `TTL` en `redis-cli` que no expiran todas en el mismo
segundo.
**Objetivo:** cortar la expiración simultánea, que es lo que `sync = true` no cubre.

#### 🟡 Ejercicio 9 — el `@Async` que devuelve algo

Cambia `warmUp` para que devuelva `CompletableFuture<ItemView>` y haz que el controller lo
ignore. Después provoca una excepción dentro del método (un SKU inexistente) y responde:
¿quién se entera, y qué habría cambiado con retorno `void`?
**Pregunta:** ¿en qué caso una excepción de un `@Async` no aparece en ningún log?

#### 🟡 Ejercicio 10 — la cola que se llena

Baja `queueCapacity` a `2` y `maxPoolSize` a `2`, y lanza cincuenta `POST` de movimientos en
paralelo. Encuentra en el log la excepción del rechazo y di cuántas tareas se perdieron.
**Objetivo:** ver `AbortPolicy` en acción y entender por qué una política ruidosa es
preferible a una silenciosa.

### 🟠 Difícil — combinar, diagnosticar o decidir  (11–13)

#### 🟠 Ejercicio 11 — la fuga de datos por clave incompleta

Añade a `valuation` un segundo parámetro `String clientId` que filtre los movimientos por
cliente, **sin tocar la anotación** (`key = "#sku"`). Demuestra con dos peticiones de
clientes distintos que el segundo recibe los datos del primero, y después corrígelo.
**Pregunta:** ¿por qué esto es peor que un bug de rendimiento, y qué regla de
[`17` §9](17-cache.md#9--invalidación-coherencia-y-qué-no-se-cachea) se incumplió?

#### 🟠 Ejercicio 12 — el endpoint de valoraciones sin techo

`GET /api/items/valuations?skus=…` acepta la lista que le manden. Mide qué pasa con
doscientos SKU, decide un límite, impleméntalo con validación de `L03` y justifica el número.
**Objetivo:** cerrar el hueco que la sección 3 dejó abierto a propósito, con un `400` honesto
en vez de una caché llena de basura.

#### 🟠 Ejercicio 13 — diagnóstico a ciegas

Un compañero dice: "la valoración devuelve datos viejos en producción, pero en mi máquina
funciona". Sin ver su código, escribe la lista ordenada de cinco comprobaciones que le pides,
cada una con el comando exacto y con lo que descarta cada resultado.
**Pregunta:** ¿cuál de las cinco distingue "caché local con varias réplicas" de "ruta de
escritura sin invalidar"?

### 🔴 Muy difícil — abierto o adversarial  (14–15)

#### 🔴 Ejercicio 14 — el refresco que se cuelga

Modifica `refreshHotSkus` para que tarde treinta segundos (con un `Thread.sleep`) manteniendo
`lockAtMostFor` en quince. Ejecuta dos instancias, demuestra con los logs que **las dos
acaban dentro de la sección protegida a la vez**, y propón dos correcciones distintas
diciendo qué garantiza cada una.
**Objetivo:** entender que el lease no es una garantía, es una apuesta sobre la duración.

#### 🔴 Ejercicio 15 — ShedLock contra tu cableado

Sustituye el `RLock` a mano por `net.javacrumbs.shedlock:shedlock-spring:6.10.0` con el
proveedor de Redis, usando `@SchedulerLock` con `lockAtMostFor` y `lockAtLeastFor`. Entrega
una tabla de cuatro filas comparando ambas soluciones: líneas de código, qué pasa si el
proceso muere con el lock, qué pasa si los relojes están desfasados 200 ms, y qué dependencia
añade cada una.
**Pregunta:** ¿para qué sirve `lockAtLeastFor` y qué problema tuyo de hoy habría evitado?

### 🔥 Opcionales y ampliaciones

- **Invalidar después del commit.** Sustituye el `@CacheEvict` de `record(...)` por un
  `@TransactionalEventListener(AFTER_COMMIT)` que invalide la entrada, y demuestra con dos
  hilos que la ventana de repoblación de la sección 4 desapareció.
- **Refresh-ahead con Caffeine.** Añade `refreshAfterWrite=20s` a la `spec` y observa que el
  request nunca ve el fallo porque un hilo carga el valor nuevo mientras se sirve el viejo.
  Mide cuántos refrescos ocurren que nadie pidió.
- **`RRateLimiter` de Redisson** delante de `SupplierGateway`, para no pasar de N llamadas por
  segundo al proveedor **entre todas las instancias**, que es lo que el rate limiter local de
  Resilience4j no puede hacer.
- **Virtual threads y el executor.** Arranca con `spring.threads.virtual.enabled=true` y
  observa qué pasa con tu `inventoryExecutor` declarado a mano y con el nombre de los hilos en
  el log. Di qué límite desapareció y dónde hay que reponerlo.

### 💀 Boss fight — el contrato de caché de `inv-api`

Escribe y entrega un documento de una página, **el contrato de caché del servicio**, que
cualquier persona del equipo pueda usar para decidir si añade una caché nueva. Tiene que
contener, con evidencia del lab detrás de cada punto: qué se cachea y qué no, y por qué (con
el caso de los datos por usuario resuelto); el TTL elegido para cada caché con el desfase
máximo que el negocio acepta, firmado como una decisión y no como un default; la ruta de
invalidación completa —todas las escrituras, incluidas las del job y las de un `UPDATE`
administrativo— y qué las cubre cuando una se olvida; el store elegido con el argumento de la
coherencia entre réplicas; el hit ratio mínimo por debajo del cual la caché se retira, con el
comando que lo mide; y el comportamiento esperado cuando Redis no responde.

Después **demuéstralo**: deja el sistema con dos instancias corriendo, ejecuta un guion que
recorra lectura, escritura, invalidación, expiración y refresco programado, y adjunta la
salida de `inventory.repository.calls`, `cache.gets` y `redis-cli KEYS 'inv:*'` antes y
después. Si alguna afirmación del documento no se puede comprobar con un comando, no es parte
del contrato: es una intención.

---

## 🏁 La señal de que quedó bien

`docker compose -p inv-lab ps` lista tres contenedores —Postgres en `healthy`, WireMock y
Redis en `Up`— y una sola instancia de `inv-api` corriendo. `redis-cli KEYS 'inv:*'` muestra
las claves de tu caché con nombres que se leen, sus valores en JSON y un `TTL` que baja.
`./mvnw -q clean package` sigue en verde con los tests de `L03` intactos.

Y lo que de verdad cuenta, que son las tres cosas que hoy pasaron de creencia a hecho
comprobado. **La primera:** una caché local con dos instancias no es una caché lenta de
invalidar, es una caché que **responde dos verdades distintas al mismo `GET`**, y lo viste en
dos líneas consecutivas de tu terminal antes de arreglarlo. **La segunda:** migrar a Redis no
es cambiar una propiedad, es aceptar una serialización que te reventó en la primera petición,
un TTL que por defecto es infinito y un salto de red en el camino de cada lectura. **La
tercera:** el trabajo que salta a otro hilo se lleva el hilo y deja el contexto, y un log con
`[sin-request-id]` es la forma que tiene tu aplicación de decirte que acabas de perder la
correlación justo cuando más falta iba a hacerte.

Si dudas de alguna de las tres, el criterio de verdad de hoy no es el código de estado ni el
log: es el contador de llamadas al repositorio. Un método cacheado que se ejecuta no deja
ninguna otra huella.

Los perfiles `db`, `ext` y `cache` se quedan arriba. `L07` añade el perfil `obs` y pone
Prometheus a recoger estas mismas métricas —el hit ratio, el contador, los eventos del
circuito de `L05`— para que dejen de morir con el proceso, que es la limitación con la que
has tropezado cuatro veces hoy. El capítulo de Actuator y observabilidad, que es el `23`,
llega en esa misma tanda.

---

## 📚 Referencias oficiales

- Spring Boot 3.5 — Caché: proveedores soportados y `spring.cache.type`: https://docs.spring.io/spring-boot/3.5/reference/io/caching.html
- Spring Boot 3.5 — Ejecución de tareas y scheduling (`spring.task.*`): https://docs.spring.io/spring-boot/3.5/reference/features/task-execution-and-scheduling.html
- Spring Boot 3.5 — Redis: conexión, `spring.data.redis.*` y clientes: https://docs.spring.io/spring-boot/3.5/reference/data/nosql.html
- Spring Boot 3.5 — Endpoints de Actuator (`caches`, `metrics`, `scheduledtasks`): https://docs.spring.io/spring-boot/3.5/reference/actuator/endpoints.html
- Spring Boot 3.5 — Métricas de caché en Micrometer: https://docs.spring.io/spring-boot/3.5/reference/actuator/metrics.html
- Spring Boot 3.5 — Índice de propiedades (`spring.cache.*`, `spring.task.*`, `spring.data.redis.*`): https://docs.spring.io/spring-boot/3.5/appendix/application-properties/index.html
- Spring Framework 6.2 — Abstracción de caché: https://docs.spring.io/spring-framework/reference/6.2/integration/cache.html
- Spring Framework 6.2 — Anotaciones declarativas (`@Cacheable`, `@CachePut`, `@CacheEvict`): https://docs.spring.io/spring-framework/reference/6.2/integration/cache/annotations.html
- Spring Framework 6.2 — Configuración del store y `CacheManager`: https://docs.spring.io/spring-framework/reference/6.2/integration/cache/store-configuration.html
- Spring Framework 6.2 — Estrategias: `KeyGenerator` y caché sincronizada (`sync`): https://docs.spring.io/spring-framework/reference/6.2/integration/cache/strategies.html
- Spring Framework 6.2 — Task execution y scheduling (`@Async`, `@Scheduled`, `TaskDecorator`): https://docs.spring.io/spring-framework/reference/6.2/integration/scheduling.html
- Spring Framework 6.2 — Mecanismo de proxy, que es de lo que viven `@Cacheable` y `@Async`: https://docs.spring.io/spring-framework/reference/6.2/core/aop/proxying.html
- Spring Data Redis 3.5 — `RedisCacheManager`, TTL por caché y prefijos: https://docs.spring.io/spring-data/redis/reference/3.5/redis/redis-cache.html
- Spring Data Redis 3.5 — Serializadores y `RedisTemplate`: https://docs.spring.io/spring-data/redis/reference/3.5/redis/template.html
- Spring Data Redis 3.5 — Drivers: Lettuce y Jedis: https://docs.spring.io/spring-data/redis/reference/3.5/redis/drivers.html

### Documentación de terceros

- Caffeine — Eviction (`maximumSize`, `expireAfterWrite`): https://github.com/ben-manes/caffeine/wiki/Eviction
- Caffeine — Statistics (`recordStats`): https://github.com/ben-manes/caffeine/wiki/Statistics
- Caffeine — Refresh (`refreshAfterWrite`, para el 🔥 opcional): https://github.com/ben-manes/caffeine/wiki/Refresh
- Redisson — Locks y sincronizadores (`RLock`): https://redisson.pro/docs/data-and-services/locks-and-synchronizers/
- Redisson — Integración con Spring: https://redisson.pro/docs/integration-with-spring/
- Redis — Locks distribuidos y las limitaciones de Redlock: https://redis.io/docs/latest/develop/use/patterns/distributed-locks/
- Redis — `redis-cli`: https://redis.io/docs/latest/develop/tools/cli/
- ShedLock — lock distribuido para `@Scheduled` con múltiples instancias: https://github.com/lukas-krecan/ShedLock
- Micrometer Context Propagation — el mecanismo detrás de `ContextPropagatingTaskDecorator`: https://docs.micrometer.io/context-propagation/reference/
- Docker Compose — Perfiles: https://docs.docker.com/compose/how-tos/profiles/
