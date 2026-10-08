# 17 — Caché

> **Objetivo:** poner una caché que sirva de verdad, elegir entre local y distribuida con
> un argumento, y saber exactamente qué se rompe cuando el dato cambia.
> **Asume:** [`05`](05-proxies-y-aop.md) y [`15`](15-datos-jdbc-jpa-mongo-y-redis.md).
> **Vigencia:** 18 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21.

---

## 1. 🧭 El problema: la misma respuesta, calculada mil veces

`GET /items/{sku}` de `inv-api` consulta tres tablas, arma un DTO y responde en 80 ms. El catálogo
cambia dos veces al día y el 90 % del tráfico pide los mismos doscientos SKU: pagas 80 ms y una
conexión del pool por repetir un cálculo cuyo resultado ya tenías. Ahí sirve una caché —**lectura
repetida, resultado caro, dato que cambia despacio y tolerancia declarada al dato viejo**—.

Si falta una, la caché no es una mejora sino una capa más que puede mentirte: una con 10 % de
aciertos paga la consulta del store **más** el almacenamiento, retiene en heap objetos inútiles
y alarga las pausas de GC. Sale más cara que no tenerla.

> Nunca respondas: ~~"ponemos una caché y mejora el rendimiento"~~.
> Mejor: "una caché mejora la **latencia de lecturas repetidas** y a cambio te da datos viejos,
> más memoria retenida y un modo de fallo nuevo. Si el hit ratio es bajo, solo añadiste trabajo".

---

## 2. 🧱 La abstracción de Spring: anotaciones sobre un contrato

Spring no implementa ninguna caché: define dos interfaces —`Cache` (get, put, evict) y
`CacheManager` (dame la caché `inventory-items`)— más un interceptor que las invoca por ti. El
store real lo pone otro: Caffeine, Ehcache, Redis o un `ConcurrentHashMap`.

```java
@Configuration
@EnableCaching  // registra el CacheInterceptor y el advisor que lo aplica
class CacheConfig { }
```

```java
@Cacheable(cacheNames = "inventory-items", key = "#sku")
public InventoryItem findBySku(String sku) { ... }
@CachePut(cacheNames = "inventory-items", key = "#item.sku()")
public InventoryItem save(InventoryItem item) { ... }
@CacheEvict(cacheNames = "inventory-items", key = "#sku", beforeInvocation = true)
public void delete(String sku) { ... }
```

- **`@EnableCaching`** no crea ninguna caché: registra el `CacheInterceptor`. Sin él las tres
  anotaciones son comentarios de lujo y el método corre siempre, sin error ni log.
- **`@Cacheable`** mira primero: si hay entrada, **no ejecuta el método**; si no, lo ejecuta y
  guarda el retorno, incluido un `null` salvo que lo vetes (§6).
- **`@CachePut`** hace lo contrario: **siempre ejecuta** y después escribe, para dejar la
  entrada fresca tras una escritura. Junto a `@Cacheable` en el mismo método pide dos cosas
  incompatibles —saltarse el método y ejecutarlo siempre— y **Spring no lo rechaza**:
  `SpringCacheAnnotationParser.validateCacheOperation()` solo veta `key` + `keyGenerator` y
  `cacheManager` + `cacheResolver`. Arranca y el resultado queda indefinido, peor que un fallo.
- **`@CacheEvict`** borra, y con `allEntries = true` vacía la caché completa;
  **`beforeInvocation = true`** borra **antes** de ejecutar, que es lo que quieres si el método
  puede lanzar (por defecto es `false` y la entrada vieja sobrevive al fallo).
- **`@Caching`** agrupa varias de las anteriores sobre un método, sin semántica propia; y
  **`cacheNames`** es el nombre lógico —`inventory-items`, el del laboratorio—, el que verás en la métrica y
  dentro de la clave de Redis.

---

## 3. 🧱 La clave: `key`, `condition`, `unless` y el `KeyGenerator`

Sin `key`, Spring usa el `SimpleKeyGenerator`: sin argumentos genera `SimpleKey.EMPTY`, con uno
usa ese argumento tal cual y con varios construye un `SimpleKey` con todos. Es razonable hasta
que el método recibe un objeto grande: ahí la clave depende de su `equals`/`hashCode`, y con
una entidad JPA sin `equals` cada llamada genera una clave distinta y no aciertas nunca.

```java
@Cacheable(
    cacheNames = "inventory-items",
    key = "#sku",                               // SpEL sobre los argumentos
    condition = "#sku != null and #sku.length() == 8",
    unless = "#result == null or #result.quantity() == 0",
    sync = true)
public InventoryItem findBySku(String sku) { ... }
```

- **`key = "#sku"`** es SpEL sobre el contexto del método: `#sku` por nombre de parámetro
  (requiere `-parameters`, que activa el plugin de Boot), `#p0` por posición, `#root.*` el resto.
- **`condition`** se evalúa **antes** de ejecutar: si es `false` la caché ni se consulta ni se
  escribe. Ve los argumentos y el `#root` completo —`method`, `target`, `caches`—; lo que no
  puede ver es `#result`, porque todavía no existe.
- **`unless`** se evalúa **después**: veta la escritura, no la lectura, y es el único que usa
  `#result`. *Condition decide si participas, unless decide si guardas*.
- **`sync = true`** hace que, ante un fallo concurrente sobre la misma clave, solo un hilo
  ejecute el método y los demás esperen su resultado (§8).
- **Un `KeyGenerator` propio** se declara como bean y se usa con `keyGenerator = "elBean"`; es
  incompatible con `key`. Y la clave viaja al nombre de la clave de Redis (§6): si metes ahí un
  objeto cuyo `toString` cambia entre despliegues, invalidas la caché entera sin notarlo.

---

## 4. ⚠️ El proxy otra vez: self-invocation

`@Cacheable` no es magia declarativa: es **el mismo mecanismo de proxy** que
`@Transactional`, con otro interceptor. Y sufre exactamente el mismo fallo.

```java
public List<InventoryItem> findAll(List<String> skus) {
    // llamada interna: el proxy NO participa, no hay caché
    return skus.stream().map(this::findBySku).toList();
}
```

- **`this::findBySku`** apunta al objeto real, no al proxy, y el `CacheInterceptor` vive en el
  proxy: no se ejecuta, y cada SKU va a la base todas las veces.
- **No hay excepción ni log.** La única señal es que `cache.gets{result="hit"}` se queda en cero
  mientras el servicio parece sano.
- Las salidas son las de siempre —otro bean, inyectarse el proxy con `@Lazy`, AspectJ—, con el
  detalle en [`05` §5](05-proxies-y-aop.md#5-️-self-invocation-el-fallo-silencioso-número-uno).
  La regla: misma clase, `private` o `final` → no hay proxy → no hay caché, ni error, ni log.

---

## 5. ⚖ Local o distribuida: el veredicto

|  | Caffeine (local) | Ehcache 3 (local, JSR-107) | Redis (distribuida) |
|---|---|---|---|
| Dónde vive | heap de la JVM | heap + offheap + disco | proceso aparte, por red |
| Coherencia entre réplicas | ninguna | ninguna sin clustering | total |
| Cuándo gana | una instancia, dato estable | banca: JSR-107 y offheap | varias réplicas, dato compartido |

Con **una sola instancia** y un dato que tolera minutos de antigüedad, **Caffeine** es la
respuesta correcta y la que Boot autoconfigura al ver la dependencia: nanosegundos, cero
infraestructura, cero serialización. **Ehcache 3** es el de banca porque implementa JSR-107
(`javax.cache`) y empuja la caché fuera del heap, a cambio de peso y de la API del estándar.
**Redis** gana con varias réplicas y una incoherencia inaceptable —un límite de crédito, una
sesión, un contador—, y pierde en todo lo demás.

```yaml
spring:
  cache:
    type: caffeine
    caffeine:
      spec: maximumSize=500,expireAfterWrite=10m,recordStats
```

- **`spec`** es la cadena de `CaffeineSpec` y **aplica a todas las cachés** de ese manager —un
  TTL por caché exige declarar el `CaffeineCacheManager` a mano—. Sin `spec`, Caffeine arranca
  **sin límite de tamaño y sin expiración**.
- **`maximumSize=500`** es el techo en entradas, no en bytes, y es lo que hace que la caché sea
  caché: al llegar, desaloja por frecuencia y recencia (W-TinyLFU) en vez de crecer. Es contra
  ese número que se lee `cache.size` (§10).
- **`expireAfterWrite=10m`** caduca la entrada 10 minutos después de **escrita**: esa es la
  ventana de dato viejo que aceptas. `expireAfterAccess` reinicia el reloj en cada lectura, así
  que un dato caliente no caduca nunca — en un catálogo, servir el precio de ayer.
- **`recordStats`** enciende los contadores; sin él `cache.gets` no existe para Caffeine (§10).

> **⏱️ Lo que cuesta una caché, con su unidad.** **Memoria retenida:** una caché local sin
> `maximumSize` es una fuga con buen nombre —los objetos son alcanzables, el GC no los toca y el
> `OutOfMemoryError` llega semanas después—. **Serialización:** en Redis cada `get` deserializa
> y cada `put` serializa **dentro del hilo del request**; un DTO de 50 KB en JSON cuesta más CPU
> que la consulta que evitaste. **El salto de red:** ~100 ns locales contra 0,3–2 ms en Redis
> —cuatro órdenes— reteniendo una conexión: delante de una consulta de 1 ms te hace más lento.

---

## 6. 🧱 Redis como caché: TTL por caché y serialización

[`15` §8](15-datos-jdbc-jpa-mongo-y-redis.md#8--mongo-y-redis-qué-te-da-spring-data-y-cuál-es-la-trampa)
ya explica qué te da Spring Data Redis y por qué el serializador por defecto deja basura binaria
en las claves; seguimos desde ahí. Con `spring-boot-starter-data-redis` y
`spring.cache.type=redis`, Boot construye un `RedisCacheManager` cuyo TTL por defecto es
**infinito**, y eso casi nunca es lo que quieres.

```java
@Bean
RedisCacheManagerBuilderCustomizer cacheCustomizer(ObjectMapper mapper) {
    RedisCacheConfiguration items = RedisCacheConfiguration.defaultCacheConfig()
        .entryTtl(Duration.ofMinutes(10))
        .prefixCacheNameWith("inv:")
        .serializeValuesWith(SerializationPair.fromSerializer(new GenericJackson2JsonRedisSerializer(mapper)));
    return builder -> builder.withCacheConfiguration("inventory-items", items);
}
```

- **`RedisCacheManagerBuilderCustomizer`** ajusta el manager que autoconfigura Boot en vez de
  reemplazarlo; si declaras tú el `CacheManager`, pierdes el resto de la autoconfiguración.
- **`entryTtl`** es por caché, no global: sin TTL, una entrada mal invalidada vive hasta que
  alguien ejecute `FLUSHDB`. Y **`prefixCacheNameWith("inv:")`** produce
  `inv:inventory-items::SKU-0042`; sin prefijo, dos servicios con una caché del mismo nombre
  sobre la misma instancia se pisan los datos.
- **`disableCachingNullValues()`** no está aquí **a propósito**: haría que un `null` lance en
  vez de guardarse, y el curso deja el `null` cacheable porque es lo que corta el bucle de
  consultas al SKU inexistente, con la memoria de esas respuestas vacías acotada por el mismo
  TTL. Se activa cuando `null` significa "todavía no cargado", no "no existe".
- **`GenericJackson2JsonRedisSerializer`** guarda JSON legible con `redis-cli`. El default,
  `JdkSerializationRedisSerializer`, **ata el valor a la clase y a su `serialVersionUID`**: añade
  un campo, despliega, y la instancia vieja lee lo que escribió la nueva con
  `SerializationException`. El JSON tampoco es neutro —escribe el nombre de la clase (`@class`)
  para reconstruir el tipo, así que renombrarla invalida lo cacheado—, pero es el mejor
  compromiso disponible; si el consumidor no eres solo tú, se cachea un `record` estable.

---

## 7. ⚖ Lettuce, Jedis y Redisson

| | Lettuce | Jedis | Redisson |
|---|---|---|---|
| Modelo de conexión | una conexión multiplexada, thread-safe | una conexión por hilo, vía pool | multiplexado + objetos |
| En Boot 3.5 | **default** del starter | alternativa soportada | integración propia |
| Qué añade | cliente, nada más | cliente, API clásica | `RLock`, `RMap`, `RSemaphore`, `RRateLimiter` |
| Coste | el más bajo | un pool más que dimensionar | dependencia grande, fuera del BOM |

**Lettuce** es el default desde Boot 2.0 y la respuesta correcta por defecto: una conexión sirve
a todos los hilos porque el protocolo de Redis es secuencial y las respuestas vuelven en orden.
**Jedis** toma una conexión del pool por operación, y ese pool se agota igual que el de Hikari.
**Redisson** añade estructuras distribuidas, y su peso lo justifican las **primitivas de
coordinación**, no la caché: para cachear es una dependencia grande y fuera del BOM.

> Nunca respondas: ~~"Redis es una caché"~~.
> Mejor: "Redis es un almacén de estructuras de datos en memoria; caché es **un** uso entre varios,
> junto con broker, lock distribuido, rate limiter y store de sesiones. Y eso importa
> porque persiste: lo que cacheas ahí sobrevive a tu despliegue".

---

## 8. 🧱 Cache stampede: el minuto en que todo expira a la vez

Un despliegue calienta la caché: a las 10:00:00 se cargan doscientas entradas con TTL de 10
minutos, a las 10:10:00 expiran las doscientas **a la vez** y las mil peticiones en vuelo van a
la base en el mismo segundo. La caché no amortiguó el pico: lo **sincronizó**.

- **`sync = true`** en `@Cacheable`: ante un fallo sobre la misma clave, un hilo ejecuta y los
  demás esperan. Corta la avalancha **por clave** —cien peticiones al mismo SKU, una consulta—
  pero no la expiración simultánea de claves distintas; no admite `unless` y no todos los stores
  lo implementan (Caffeine sí, vía `LoadingCache`).
- **TTL con jitter:** 10 minutos ± un 10 % aleatorio por entrada, para desparramar las
  expiraciones; mismo argumento que el jitter de los reintentos ([`19` §3](19-resiliencia.md#3--retry-cuándo-ayuda-y-cuándo-empeora-la-caída)).
- **Refresh-ahead:** refrescar la entrada **antes** de que caduque, en segundo plano, para que el
  request nunca vea el fallo. Caffeine lo da con `refreshAfterWrite` —devuelve el valor viejo
  mientras un hilo carga el nuevo— y se paga en refrescos que nadie pidió.

---

## 9. 🧱 Invalidación, coherencia y qué no se cachea

Hay tres formas de que una entrada deje de valer. **Por TTL** es la más simple y la única sin
bugs: el dato vive N minutos y se acabó, con un precio explícito. **Por evento** —un
`@CacheEvict` en la escritura o un listener que borra— es exacta y frágil: cada ruta de
escritura sin anotar deja una entrada mintiendo para siempre, y por eso **el TTL es la red bajo
el evento**, no su alternativa. **Por versión de clave** (`inv:inventory-items:v3::SKU-0042`)
no borra nada: deja de leer lo viejo, que caduca solo — la forma limpia de invalidar **todo**
tras un cambio de formato, sin un `FLUSHDB` que tiraría las cachés de los demás servicios.

Con **caché local** aparece además el problema de las réplicas: un `@CacheEvict` en la instancia
A no toca la copia de la B, así que durante el TTL restante dos réplicas responden cosas
distintas al mismo `GET` y el cliente lo vive como intermitencia. Las salidas: mover esa caché a
Redis, bajar mucho el TTL local o declarar la divergencia. Y hay cosas que no se cachean:

- **Datos por usuario en una caché compartida sin el usuario en la clave.** Es la fuga clásica:
  `@Cacheable("items")` sobre un método que filtra por el `SecurityContext` devuelve al segundo
  usuario lo que calculó el primero. Si el resultado depende de la identidad, la identidad va en
  la clave — y ahí pregúntate si el hit ratio lo vale.
- **Lo que cambia más rápido que el TTL.** Un saldo que se mueve cada segundo con TTL de cinco
  minutos no es una caché: es un generador de respuestas incorrectas. Y **lo que no cabe**:
  cien mil elementos "porque la consulta es lenta" cambian la base lenta por un `OutOfMemoryError`.
- **El resultado de una transacción en vuelo.** El interceptor escribe cuando el método retorna,
  **no cuando la transacción hace commit**: si el commit falla después, queda cacheado un dato
  que nunca existió. El punto correcto es después del commit
  —`@TransactionalEventListener(AFTER_COMMIT)`, que desarrolla [`18` §9](18-asincronia-scheduling-y-eventos.md#9--el-evento-que-espera-al-commit)—, no un `@CachePut`
  dentro del `@Transactional` ([`16` §8](16-transacciones.md#8--el-límite-de-la-transacción-no-es-el-límite-de-tu-método)).

---

## 10. 🩺 Sin hit ratio, esto es una suposición

Una caché sin métricas no se puede defender: no sabes si acierta ni qué cuesta. Boot publica las
de cada caché en Micrometer si el store las expone —en Caffeine, con el `recordStats` de §5—.

```bash
curl -s localhost:8081/actuator/metrics/cache.gets?tag=cache:inventory-items
```

- **`cache.gets`** llega con la etiqueta `result` en `hit` o `miss`: el hit ratio es
  `hit / (hit + miss)`, y bajo ~0,8 en lecturas repetidas se revisa la clave antes que el TTL.
- **`cache.size`** contra tu `maximumSize` dice si estás desalojando: si van pegados, cada entrada
  nueva expulsa una útil y el ratio no sube tocando el TTL; **`cache.evictions`** creciendo con el
  tráfico es caché pequeña, no caché sana. El `8081` es el puerto de Actuator en el lab.

> **🩺 "Mi `@Cacheable` no cachea", en orden.** ¿Está `@EnableCaching`? ¿La llamada viene de otro
> bean (§4)? ¿`condition` o `unless` la vetan? ¿La clave es estable entre llamadas? ¿`cache.gets`
> registra siquiera un `miss`? Si no hay ni `miss`, el problema es el proxy, no la caché.

---

## 11. 🧱 Bloqueo distribuido con Redisson, y su advertencia

El lock distribuido no es caché, pero llega con la misma dependencia y el problema es real:
tres réplicas de `inv-api`, una reconciliación que debe correr una sola vez.

```java
// el método que contiene esto declara throws InterruptedException
RLock lock = redissonClient.getLock("inv:lock:reconciliation");
// espera hasta 5 s por el lock; si lo toma, lo suelta solo a los 30 s
if (lock.tryLock(5, 30, TimeUnit.SECONDS)) {
    try { reconcile(); } finally { lock.unlock(); }
}
```

- **`tryLock(waitTime, leaseTime, unit)`**: el primero es cuánto esperas a que se libere; el
  segundo, cuánto lo retienes como máximo aunque tu proceso muera. **Sin `leaseTime`, un proceso
  que muere con el lock tomado bloquea a los demás indefinidamente**, y el `leaseTime` es una
  apuesta: si `reconcile()` tarda 40 s y el lease son 30, otra réplica entra mientras trabajas.
- **`tryLock` declara `InterruptedException`** porque `RLock` extiende `Lock`: o la propaga el
  método —como aquí—, o se captura restaurando el flag con `Thread.currentThread().interrupt()`.
- **El `unlock()` va en `finally`**; aun así, si la JVM muere, solo el lease libera.

> **⚠️ Esto es un lock de un solo nodo, y Redlock tampoco garantiza lo que parece.** Lo de arriba
> se apoya en **una** instancia de Redis: si hace failover a una réplica que no alcanzó a recibir
> el lock, dos procesos lo tienen a la vez. Redlock —el algoritmo sobre N instancias— nació para
> eso y está discutido, y la crítica vale para ambos: sin fencing token no hay exclusión mutua
> ante una pausa de GC ni con un reloj desviado. Sirve como **optimización para no duplicar
> trabajo**, no como garantía de corrección; si de la exclusión depende la corrección, se
> resuelve donde está el dato —restricción única, `UPDATE ... WHERE version = ?`, idempotencia—.

---

## 12. ⚠️ Errores frecuentes

> Nunca respondas: ~~"le puse `@Cacheable` al método y listo"~~.
> Mejor: "`@Cacheable` elige **qué** se cachea. Falta decidir el store, el TTL, la clave, la
> invalidación y cómo se mide — y sin `@EnableCaching`, o llamado desde el mismo bean, ni siquiera
> hace lo primero".

- **`@CacheEvict` sin `beforeInvocation` sobre un método que lanza**, y **`spring.cache.type`
  para "activar" la caché**: elige la implementación, la enciende `@EnableCaching`.
- **Caché local delante de un dato que el negocio cree consistente entre réplicas.** No lo es, y
  el síntoma es el soporte diciendo "a veces sale bien, a veces mal".

---

## 🧠 Preguntas rápidas

1. Nombra las cuatro condiciones que hacen que cachear una lectura sea una mejora.
2. ¿Qué hace exactamente `@EnableCaching` y cuál es el síntoma de que falta?
3. Diferencia `@Cacheable` de `@CachePut` según si el método se ejecuta, y di qué cambia
   `beforeInvocation = true` en un `@CacheEvict` sobre un método que lanza.
4. `condition` y `unless`: ¿cuándo se evalúa cada uno y cuál puede mirar `#result`?
5. Tu `@Cacheable` nunca registra un `hit` y tampoco hay errores. ¿Qué miras, y en qué orden?
6. ¿Por qué `@Cacheable` falla en self-invocation exactamente igual que `@Transactional`?
7. Un acierto en Caffeine y uno en Redis: ¿qué orden de magnitud tiene cada uno, y qué
   implica para una consulta que ya tardaba 1 ms?
8. ¿Por qué el serializador JDK te ata a la clase, y qué excepción verás tras añadir un campo?
9. Explica el cache stampede y di qué corta `sync = true` y qué no corta.
10. ¿Por qué el TTL sigue haciendo falta aunque invalides por evento?
11. Con caché local y tres réplicas, ¿qué ocurre tras un `@CacheEvict` en una de ellas?
12. ¿Por qué un `@CachePut` dentro de un `@Transactional` puede cachear algo que nunca existió?
13. "Redis es una caché": ¿qué le corriges a esa frase en una entrevista?
14. ¿Qué garantiza y qué no un `RLock` de Redisson, y dónde resuelves la exclusión si de ella
    depende la corrección?

---

## 📚 Referencias oficiales

- Spring Framework 6.2 — Abstracción de caché: https://docs.spring.io/spring-framework/reference/6.2/integration/cache.html
- Spring Framework 6.2 — Anotaciones declarativas (`@Cacheable`, `@CachePut`, `@CacheEvict`, `@Caching`): https://docs.spring.io/spring-framework/reference/6.2/integration/cache/annotations.html
- Spring Framework 6.2 — Configuración del store y `CacheManager`: https://docs.spring.io/spring-framework/reference/6.2/integration/cache/store-configuration.html
- Spring Framework 6.2 — Estrategias: `KeyGenerator` y caché sincronizada (`sync`): https://docs.spring.io/spring-framework/reference/6.2/integration/cache/strategies.html
- Spring Boot 3.5 — Caché: proveedores soportados y `spring.cache.type`: https://docs.spring.io/spring-boot/3.5/reference/io/caching.html
- Spring Boot 3.5 — Métricas de caché en Micrometer: https://docs.spring.io/spring-boot/3.5/reference/actuator/metrics.html
- Spring Data Redis 3.5 — `RedisCacheManager` y TTL por caché: https://docs.spring.io/spring-data/redis/reference/3.5/redis/redis-cache.html
- Spring Data Redis 3.5 — Drivers: Lettuce y Jedis: https://docs.spring.io/spring-data/redis/reference/3.5/redis/drivers.html

### Documentación de terceros

- Caffeine — Eviction (`maximumSize`, `expireAfterWrite`): https://github.com/ben-manes/caffeine/wiki/Eviction
- Caffeine — Refresh (`refreshAfterWrite`): https://github.com/ben-manes/caffeine/wiki/Refresh
- Caffeine — Statistics (`recordStats`): https://github.com/ben-manes/caffeine/wiki/Statistics
- Ehcache 3.10 — Tiering: heap, offheap y disco: https://www.ehcache.org/documentation/3.10/tiering.html
- Ehcache 3.10 — Soporte de JSR-107 (`javax.cache`): https://www.ehcache.org/documentation/3.10/107.html
- Redisson — Locks y sincronizadores (`RLock`): https://redisson.pro/docs/data-and-services/locks-and-synchronizers/
- Redis — Locks distribuidos y las limitaciones de Redlock: https://redis.io/docs/latest/develop/use/patterns/distributed-locks/
