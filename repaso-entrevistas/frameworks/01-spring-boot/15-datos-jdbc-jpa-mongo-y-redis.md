# 15 — Datos: JDBC, JPA, Mongo y Redis

> **Objetivo:** elegir capa de acceso a datos con criterio, saber qué hace Hibernate a tus
> espaldas, y diagnosticar el problema de rendimiento antes de que lo note el negocio.
> **Asume:** [`05`](05-proxies-y-aop.md), [`07`](07-configuracion-externalizada.md), [`09`](09-rest-con-spring-mvc.md).
> **Vigencia:** 18 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21 · Postgres 17.11 · Hibernate 6.6.

> **📝 Dónde termina este capítulo.** Aquí está **cómo se llega a la base y qué cuesta
> llegar**; propagación, aislamiento y rollback son el capítulo [`16`](16-transacciones.md). El eje es el
> relacional, y Mongo, Redis y Flyway entran al nivel de "qué te da Spring Data y cuándo lo
> eliges"; lo que quedó fuera se declara en §10.

---

## 1. 🧭 El problema: entre tu servicio y la tabla hay cuatro capas

Tu endpoint de [`09`](09-rest-con-spring-mvc.md) guarda un `InventoryEvent` y el test pasa en dos milisegundos. En
producción tarda cuatro segundos bajo carga y el `/health` deja de responder. No hay una
línea de tu código que lo explique, porque entre tu método y la tabla `inventory_event` hay
cuatro capas y cada una falla distinto:

```text
tu servicio
  └─► repositorio de Spring Data    ¿qué SQL genera, y cuántas veces?
        └─► Hibernate               persistence context, dirty checking, lazy loading
              └─► DataSource/Hikari ¿hay conexión libre? ¿quién la tiene retenida?
                    └─► driver JDBC → Postgres
```

Quien solo aprendió `JpaRepository` ve la primera capa y opina sobre la cuarta; este
capítulo va de abajo hacia arriba, que es el orden en que se diagnostica.

---

## 2. 🧱 El `DataSource` y HikariCP

Abrir una conexión a Postgres cuesta entre 5 y 50 ms: handshake, autenticación y un proceso
nuevo del lado del servidor. Hacerlo por request es absurdo, así que
`spring-boot-starter-data-jpa` trae **HikariCP** y lo autoconfigura en cuanto ve una URL.

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/inv_lab
    username: inv_lab                 # triviales a propósito: mueren con `compose down -v`
    password: inv_lab
    hikari:
      maximum-pool-size: 10           # el default también es 10
      connection-timeout: 3000        # ms que espera un hilo por una conexión libre
```

- **`maximum-pool-size`** es el límite real de concurrencia de tu servicio: con 10
  conexiones y 200 hilos de Tomcat ([`08`](08-modelo-de-ejecucion-web.md)), como mucho hay 10 requests tocando la base a la
  vez y los otros 190 esperan. `minimum-idle` con el mismo valor lo vuelve fijo.
- **`connection-timeout: 3000`** es lo que un hilo espera antes de rendirse con excepción.
  El default son 30 000 ms, y treinta segundos colgado es cómo un pool agotado se vuelve
  caída total: fallar rápido es mejor dato que esperar mucho.
- **`leak-detection-threshold: 20000`**, que no está arriba y deberías añadir, no cierra
  nada: escribe un `WARN` con el stack trace de quien retuvo una conexión más de 20 s.

Cuando el pool se agota, el log es este, y hay que reconocerlo de memoria:

```text
java.sql.SQLTransientConnectionException: HikariPool-1 - Connection is not available, request timed out after 3000ms.
	at com.zaxxer.hikari.pool.HikariPool.getConnection(HikariPool.java:197)
```

> **⏱️ Costo en runtime: por qué más conexiones no es mejor.** Cada conexión de Postgres es un
> proceso con su memoria, y la base solo ejecuta en paralelo tantas consultas como núcleos y
> discos tenga: la fórmula de HikariCP es `conexiones ≈ (núcleos × 2) + spindles`, entre 8 y 12 en
> una máquina de 4 núcleos con SSD. Subir el pool a 100 hace que compitan 100 consultas por 4
> núcleos y que el timeout salte igual, más tarde y con la base de rodillas. **Lo que se mira no
> es el tamaño sino el tiempo de retención** (está en
> `/actuator/metrics/hikaricp.connections.usage`, [`23` §7](23-actuator-y-observabilidad.md#7--micrometer-meterregistry-los-cuatro-medidores-y-las-anotaciones)), y a una conexión la retienen una
> transacción que abarca una llamada HTTP, `open-in-view` (§7), una consulta sin índice y una
> anidada que toma una segunda conexión (`16`).

> Nunca respondas: ~~"si va lento, subimos el pool"~~
>
> Mejor: "primero mido cuánto retiene cada request su conexión y por qué. Si la retiene
> 800 ms para 20 ms de consulta, el problema es lo que hace el método con la conexión
> abierta, y subir el pool solo mueve la cola de mi aplicación a la base."

---

## 3. 🧱 `JdbcClient` y la jerarquía de `DataAccessException`

Hay consultas que no quieres que nadie genere por ti: un reporte con tres `JOIN`, un
`INSERT ... ON CONFLICT`, una agregación que revisó el DBA. Desde Spring Framework 6.1
(Boot 3.2), `JdbcClient` es la fachada fluida sobre `JdbcTemplate` para eso.

```java
record StockLine(String sku, long total) {}
List<StockLine> stockByWarehouse(String warehouse) {
    return jdbc.sql("SELECT sku, SUM(quantity) AS total FROM inventory_event "
                  + "WHERE warehouse = :warehouse GROUP BY sku")
            .param("warehouse", warehouse)   // parámetro nombrado, nunca concatenado
            .query(StockLine.class)          // mapeo por nombre de componente del record
            .list();
}
```

- **`JdbcClient` se inyecta por constructor**: Boot lo autoconfigura sobre el `DataSource`
  del §2, sin pool ni conexiones propias.
- **`.param(...)`** produce un `PreparedStatement`: el valor viaja aparte del SQL y no hay
  inyección posible. Concatenarlo es el bug de seguridad más viejo del oficio.
- **`.query(StockLine.class)`** aplica el `SimplePropertyRowMapper` de Spring 6.1: por cada
  componente del `record` busca su columna por nombre y, si falla, la misma en *snake_case*
  (`sumTotal` → `sum_total`). Al revés no: **una columna que no case con ningún componente se
  ignora**, y lo que revienta es un componente sin columna. `single()` en vez de `list()`
  lanza `IncorrectResultSizeDataAccessException` con cero o con dos filas.

Ese nombre de excepción no es de JDBC, es de Spring: el driver habla `SQLState` —`23505` en
Postgres, `ORA-00001` en Oracle— y capturar eso casa tu servicio con el motor, así que Spring
lo traduce a una jerarquía propia y **no chequeada** bajo `DataAccessException` —en un
`@Repository` con JDBC crudo lo hace un proxy
([`05` §2](05-proxies-y-aop.md#2--quién-crea-el-proxy-y-cuándo))—. `DuplicateKeyException`
es tu 409 ([`10`](10-diseno-de-api-validacion-errores-e-hipermedia.md)), `CannotAcquireLockException` un deadlock reintentable ([`19` §3](19-resiliencia.md#3--retry-cuándo-ayuda-y-cuándo-empeora-la-caída)) y
`OptimisticLockingFailureException` sale de `@Version` (§5); que sean `RuntimeException` es
deliberado, porque el rollback por defecto se dispara con ellas y no con una chequeada.

**Veredicto:** `JdbcClient` cuando el SQL es el producto —reportes, agregaciones, cargas
masivas— y JPA cuando lo es el grafo de objetos y su ciclo de vida; conviven.

---

## 4. 🧱 Spring Data: el repositorio que nadie implementa

El denominador común de todos los módulos —JPA, Mongo, Redis— es el mismo: declaras una
interfaz y en el arranque el contenedor registra un bean que la implementa. No hay
generación de código en compilación: hay un `FactoryBean` que crea un proxy que traduce el
nombre de cada método a una consulta del store.

```java
interface InventoryItemRepository extends JpaRepository<InventoryItem, Long> {
    // derived query: el nombre del método ES la consulta
    List<InventoryItem> findByWarehouseAndQuantityGreaterThan(String warehouse, int min);

    // proyección a record: solo dos columnas salen de la base
    @Query("select new com.invlab.invapi.inventory.SkuQuantity(i.sku, i.quantity) "
         + "from InventoryItem i where i.warehouse = :w")
    List<SkuQuantity> byWarehouse(@Param("w") String w, Pageable page);
    @Modifying(clearAutomatically = true)
    @Query("update InventoryItem i set i.quantity = i.quantity + :d where i.sku = :sku")
    int addQuantity(@Param("sku") String sku, @Param("d") int delta);
}
```

- **La derived query se parsea en el arranque**, no en la primera llamada: una propiedad mal
  escrita rompe el contexto con `PropertyReferenceException: No property 'warehous' found
  for type 'InventoryItem'`. Su límite es la legibilidad: más de dos condiciones, `@Query`.
- **`@Query` con JPQL habla de entidades y propiedades**, no de tablas y columnas, y se valida
  en el arranque; con `nativeQuery = true` pierdes las dos cosas, y si vas a escribir SQL nativo
  plantéate `JdbcClient` (§3). **La proyección a `record`** trae dos columnas y no la fila
  entera, y **`Pageable`** añade `LIMIT`/`OFFSET` y el `ORDER BY` (su contrato HTTP es `10`).
- **`@Modifying`** es obligatorio en `UPDATE`/`DELETE` de JPQL: sin él, Spring Data lo trata
  como consulta y falla. **`clearAutomatically = true`** vacía el persistence context, porque
  el `UPDATE` masivo pasa **por encima** de Hibernate y las entidades ya cargadas se
  quedarían con el valor viejo (§5).

> Nunca respondas: ~~"Spring Data JPA es Hibernate con menos código"~~
>
> Mejor: "es una capa de repositorios **encima** de JPA; el proveedor sigue siendo Hibernate
> y es quien decide el SQL, el persistence context y el orden de los flush. Te ahorra
> escribir el `EntityManager`, no entender a Hibernate: el N+1, el lazy loading y el dirty
> checking son suyos y te van a morder igual."

---

## 5. 🧱 El persistence context, de donde salen las sorpresas

El `EntityManager` no es un ejecutor de SQL: es una caché de primer nivel con estado, y una
entidad vive en uno de cuatro estados que deciden qué SQL emite Hibernate.

```text
transient   new InventoryItem(...)      no la conoce nadie
managed     persist() / find()          en el persistence context, vigilada
detached    la transacción terminó      ya no la vigila nadie
removed     delete()                    marcada para el DELETE del flush
```

- **Dirty checking:** a una entidad *managed* le basta con que le cambies un campo; al hacer
  flush, Hibernate compara contra el snapshot que guardó al cargarla y emite el `UPDATE`,
  así que **no hace falta llamar a `save()`**. Y el flush **no es el commit**: vuelca lo
  pendiente antes de cualquier consulta afectada, y el orden del log no es el de tu código.
- **`save()` no es un `INSERT`:** es `persist()` si la entidad es nueva y `merge()` si ya
  tiene id, y `merge()` sobre una *detached* **devuelve una copia gestionada**: si sigues
  usando la instancia que le pasaste, tus cambios no se guardan. Usa el valor retornado.
- **`equals`/`hashCode` no se basan en el id generado**: una entidad *transient* metida en
  un `HashSet` cambia de hash cuando la base le asigna el id y el `Set` deja de encontrarla;
  usa la clave de negocio, en `inventory_item` el `sku`. Y **`@Version` sobre un `long`**
  añade `WHERE version = ?` a cada `UPDATE`: si otro lo cambió, afecta cero filas y salta
  `OptimisticLockingFailureException`, que tu API traduce a 409.

---

## 6. ⚠️ N+1: una consulta que se convierte en doscientas

Pides veinte ítems y quieres el nombre del almacén de cada uno. Hibernate emite un `SELECT`
para los veinte y, cuando tocas `item.getWarehouse().getName()`, uno más por cada uno. Y el
problema es que **no se ve**: `spring.jpa.show-sql=true` imprime por `System.out`, sin
parámetros y sin decir cuántas veces corrió cada sentencia. Lo que sí sirve:

```yaml
logging:
  level:
    org.hibernate.SQL: DEBUG               # cada sentencia, por el logger, con timestamp
    org.hibernate.orm.jdbc.bind: TRACE     # los parámetros; en Hibernate 5 era otro logger
spring:
  jpa:
    properties:
      hibernate.generate_statistics: true  # al cerrar la sesión: cuántas consultas hubo
```

- **`org.hibernate.SQL` en `DEBUG`** manda el SQL al logger real, con el `traceId` del MDC
  (`23`); `show-sql` escribe a `stdout` y en un agregador de logs es basura.
  **`org.hibernate.orm.jdbc.bind` en `TRACE`** muestra el valor de cada `?` —ojo, **eso
  escribe datos personales en el log**—, y **`generate_statistics`** cuenta las consultas.

La corrección tiene tres formas, y se prefieren en este orden:

- **`@EntityGraph(attributePaths = "warehouse")`** sobre el método derivado declara qué
  traer sin escribir el `JOIN` ni duplicar la consulta; `attributePaths` nombra propiedades,
  no columnas, y admite rutas anidadas (`"warehouse.region"`).
- **`JOIN FETCH` dentro de un `@Query`** es lo mismo escrito a mano para una consulta
  concreta, y sobre dos colecciones a la vez produce un producto cartesiano.
  **`@BatchSize(size = 20)`** no elimina los N `SELECT`: los agrupa en `N/20` con un
  `IN (...)`, la red de seguridad para colecciones que siempre se recorren.
- **`FetchType.EAGER` en el mapeo no es la solución**: mueve el problema, porque ahora
  *todas* las consultas cargan la asociación, incluida la que no la necesita. El default de
  `@ManyToOne` es `EAGER` por especificación, y ponerlo `LAZY` es casi siempre correcto.

---

## 7. ⚠️ `LazyInitializationException` y `open-in-view`

Sacas una entidad de la transacción y la serializas en el controller (`09`): el persistence
context ya se cerró, el proxy de la asociación no tiene a quién preguntar y Jackson se topa
con esto a media respuesta:

```text
org.hibernate.LazyInitializationException: could not initialize proxy [com.invlab.invapi.inventory.InventoryItem#42] - no Session
```

Boot lo evita con `spring.jpa.open-in-view`, **activa por defecto**, que mantiene la sesión de
Hibernate abierta durante todo el request — y avisa en el arranque con un `WARN` de
`JpaBaseConfiguration$JpaWebConfiguration`: *"database queries may be performed during view rendering"*.

> **⏱️ Costo en runtime de dejarlo en `true`.** La sesión abierta implica **la conexión del
> pool retenida hasta el último byte de la respuesta**, no hasta el commit: un cliente lento
> o una respuesta de 2 MB ocupan una de tus diez conexiones (§2) todo ese tiempo, y el pool
> se agota con una carga que la base ni siente. Y las consultas que dispare la serialización
> corren **fuera de transacción**, cada una en su autocommit: el endpoint puede devolver un
> estado que nunca existió en la base.

El curso lo apaga con `spring.jpa.open-in-view: false`, y hay que saber qué se rompe:

- **Se rompe todo lo que tocaba una asociación `LAZY` fuera del servicio**, que es justo lo
  que queríamos: la excepción aparece ahora en el test de integración y no en producción.
- **La corrección no es volver a `true`**: es decidir en el servicio qué necesita la
  respuesta y traerlo con `@EntityGraph` o con una proyección (§4, §6), y devolver un DTO en
  vez de la entidad — el argumento está en
  [`09` §7](09-rest-con-spring-mvc.md#7--httpmessageconverter-y-jackson). Y no arregla el
  N+1: lo hace visible.

---

## 8. ⚖ Mongo y Redis: qué te da Spring Data y cuál es la trampa

El contrato del §4 es idéntico en los tres módulos y por eso moverse entre ellos cuesta
poco; lo que no se traslada es el modelo. En **Mongo**, `@Document(collection =
"inventory_snapshot")` marca la clase, los repositorios derivan consultas igual que en JPA y
`MongoTemplate` es la vía para las agregaciones. La trampa: **Boot no crea los índices por
ti** —`spring.data.mongodb.auto-index-creation` es `false` desde Spring Data MongoDB 3.0, la
de Boot 2.3, porque crear uno en caliente sobre una colección grande bloquea—, así que un
`findBySku` sin índice es un scan completo. Mongo gana cuando el documento es la unidad de lectura y escritura —una
proyección de consulta, un snapshot, un payload heterogéneo— y es JPA disfrazado si modelas
tres colecciones y las cruzas a mano en el servicio.

En **Redis**, `RedisTemplate` da acceso a las estructuras (`opsForValue`, `opsForHash`,
`opsForZSet`) y a los TTL, y la trampa es el serializador: el que trae un `RedisTemplate`
construido a mano es `JdkSerializationRedisSerializer`, así que tus claves salen en
`redis-cli KEYS 'inv:*'` como `\xac\xed\x00\x05t\x00...` y nadie que no sea Java las lee.
Las salidas son inyectar el **`StringRedisTemplate`** que Boot autoconfigura —trae
`StringRedisSerializer` en clave y valor— o fijar tú `setKeySerializer(...)` y un serializador
JSON para el valor; el JDK además ata el valor a la clase, y cambiar un campo revienta lo
cacheado. La caché declarativa sobre Redis es
[`17` §6](17-cache.md#6--redis-como-caché-ttl-por-caché-y-serialización).

---

## 9. 🧱 Flyway, y por qué el esquema no lo genera Hibernate

`spring.jpa.hibernate.ddl-auto=update` compara tus entidades con la base y emite el DDL que
falte. Funciona en tu máquina, y por eso sobrevive tanto. Lo que hace de verdad: **añade**
columnas y tablas, **nunca** borra, renombra ni cambia un tipo; no se puede revisar antes;
no queda registro de qué corrió; y el resultado depende del orden en que se desplegaron las
versiones. En banca, además, la cuenta de la aplicación no tiene permisos de DDL.

Flyway (en el BOM de Boot: `flyway-core` más `flyway-database-postgresql`) invierte el
control: el esquema son ficheros bajo `src/main/resources/db/migration` que corren en orden
antes del contexto.

- **`V1__create_inventory_item.sql`** —`V`, versión, doble guion bajo, descripción— y el
  orden lo da la versión, no el nombre. Flyway registra en `flyway_schema_history` qué
  migración corrió, cuándo y con qué **checksum**: editar un `V` ya aplicado hace fallar el
  arranque con `Migration checksum mismatch`, que es justo el punto — para corregir, otra
  migración. **`R__inventory_stock_view.sql`** (repeatable) no lleva versión y se reejecuta
  al cambiar, y **`baseline-on-migrate`** adopta Flyway sobre una base viva.
- **Flyway corre antes que la validación de Hibernate**, y la pareja natural es
  `ddl-auto: validate`: Flyway crea el esquema, Hibernate comprueba que tus entidades encajan
  y rompe el arranque si no; `/actuator/flyway` lista lo aplicado (`23`).

> Nunca respondas: ~~"`ddl-auto=update` está bien para empezar"~~
>
> Mejor: "`update` solo sabe añadir, nunca renombrar ni borrar, y no deja constancia de qué
> corrió en cada entorno. Empezar así significa migrar a Flyway más tarde con una base cuyo
> esquema nadie escribió a propósito. El esquema es código versionado desde el primer día;
> `ddl-auto` se queda en `validate`, o en `none`."

---

## 10. ⚠️ Errores frecuentes

- **"H2 sirve para probar la capa de datos."** H2 no es Postgres: tipos, funciones, `ON CONFLICT` y el
  comportamiento de los bloqueos difieren, y el bug aparece en producción. Testcontainers con `@ServiceConnection` es el camino, y eso es [`24` §9](24-testing.md#9--testcontainers-y-serviceconnection-y-por-qué-no-h2).
- **"`open-in-view` evita el `LazyInitializationException`, así que mejor dejarlo."** Lo evita reteniendo
  la conexión hasta el último byte y consultando fuera de transacción (§7); la salida es devolver un DTO.
- **📝 En la línea 4.x** el baseline de Spring Data sube a 4.x y el de Hibernate a 7, con
  cambios de paquete y de algún default de los repositorios; el mecanismo no cambia (`A04`).

> **📝 Alcance recortado, declarado.** Quedaron fuera por longitud y viven en otro sitio:
> `@Transactional`, propagación, aislamiento y rollback (`16`); la caché declarativa sobre Redis y
> Lettuce/Jedis/Redisson (`17`); `@DataJpaTest`, `@DataMongoTest` y Testcontainers (`24`); `@Version`
> y la proyección a Mongo tras el commit, los opcionales de [`L04`](l04-datos-y-transacciones.md); y
> R2DBC, de [`11`](11-webflux-y-reactor.md), excluido del lab por [`L00`](l00-idea-lab-practico.md).
> El multi-datasource con `@Primary`, la auditoría de JPA, el modelado y las agregaciones de Mongo y
> `Specification`/Criteria API **quedan para cuando haya un caso que los pida**.

---

## 🧠 Preguntas rápidas

1. ¿Qué límite real impone `maximum-pool-size` sobre un Tomcat con 200 hilos?
2. Proponen subir el pool de 10 a 100 porque el servicio va lento: da dos razones técnicas
   para no hacerlo y di qué medirías en su lugar.
3. Nombra las cuatro cosas que retienen una conexión del pool más de lo necesario.
4. ¿Cuándo eliges `JdbcClient` sobre un repositorio de Spring Data JPA, y al revés?
5. ¿Para qué existe `DataAccessException` si el driver ya lanzaba `SQLException`?
6. Explica por qué "Spring Data JPA es Hibernate con menos código" te deja mal parado.
7. ¿Qué hace `@Modifying(clearAutomatically = true)` y qué pasa si omites ese atributo?
8. Cambias un campo de una entidad en una transacción y no llamas a `save()`: ¿se guarda?
9. `spring.jpa.show-sql=true` no te dejó ver el N+1: ¿qué configuras en su lugar?
10. Diferencia `JOIN FETCH`, `@EntityGraph` y `@BatchSize`, y di cuándo usas cada uno.
11. `open-in-view` viene en `true`: di qué cuesta en runtime y qué se rompe al apagarlo.
12. Tus claves de Redis aparecen ilegibles en `redis-cli`: ¿qué pasó y cómo se arregla?
13. Da tres razones para no usar `ddl-auto=update` ni siquiera al principio de un proyecto.
14. Editas un `V2__` que ya se aplicó en pruebas: ¿qué hace Flyway al arrancar de nuevo?

---

## 📚 Referencias oficiales

- Spring Framework 6.2 — JDBC y `JdbcClient`: https://docs.spring.io/spring-framework/reference/6.2/data-access/jdbc/core.html
- Spring Framework 6.2 — `DataSource` y control de conexiones: https://docs.spring.io/spring-framework/reference/6.2/data-access/jdbc/connections.html
- Spring Framework 6.2 — Jerarquía de `DataAccessException`: https://docs.spring.io/spring-framework/reference/6.2/data-access/dao.html
- Spring Boot 3.5 — Bases de datos SQL, `DataSource` y Hikari: https://docs.spring.io/spring-boot/3.5/reference/data/sql.html
- Spring Boot 3.5 — Bases de datos NoSQL (Mongo y Redis): https://docs.spring.io/spring-boot/3.5/reference/data/nosql.html
- Spring Boot 3.5 — Inicialización de datos y migraciones: https://docs.spring.io/spring-boot/3.5/how-to/data-initialization.html
- Spring Data 3.5 — Conceptos del repositorio: https://docs.spring.io/spring-data/jpa/reference/3.5/repositories/core-concepts.html
- Spring Data JPA 3.5 — Query methods, `@Query` y `@EntityGraph`: https://docs.spring.io/spring-data/jpa/reference/3.5/jpa/query-methods.html
- Spring Data MongoDB 4.5 — `MongoTemplate`: https://docs.spring.io/spring-data/mongodb/reference/4.5/mongodb/template-api.html
- Spring Data Redis 3.5 — `RedisTemplate` y serializadores: https://docs.spring.io/spring-data/redis/reference/3.5/redis/template.html

### Documentación de terceros

- HikariCP — configuración completa: https://github.com/brettwooldridge/HikariCP
- HikariCP — cálculo del tamaño del pool: https://github.com/brettwooldridge/HikariCP/wiki/About-Pool-Sizing
- Hibernate ORM 6.6 — User Guide: https://docs.hibernate.org/orm/6.6/userguide/html_single/
- Flyway — migraciones versionadas: https://documentation.red-gate.com/flyway/flyway-concepts/migrations/versioned-migrations
