# L04 — Datos y transacciones

> **Objetivo:** que `inv-api` deje de guardar sus datos en un `Map` y empiece a guardarlos
> en Postgres, y que al terminar puedas demostrar —con un `SELECT`, no con una opinión—
> que un método anotado con `@Transactional` grabó la fila que debía haber revertido.
> **Asume:** [`05`](05-proxies-y-aop.md), [`15`](15-datos-jdbc-jpa-mongo-y-redis.md) y
> [`16`](16-transacciones.md) leídos. Este lab no repite su teoría: la ejecuta. Si no
> reconoces la tabla de [`16` §7 — los seis silencios](16-transacciones.md#7--los-seis-silencios),
> vuelve ahí antes de seguir: este lab reproduce tres de los seis.
> **Prerrequisitos:** `L03` hecho. `inv-api` responde `201`, `404`, `409`, `415` y `422`,
> tiene `@RestControllerAdvice` con `ProblemDetail`, un `RequestIdFilter` de correlación y
> un `InventoryStore` sobre un `ConcurrentHashMap`. **Ese `Map` es lo primero que muere.**
> **Costo:** **$0.00**. Un contenedor de Postgres en `localhost` y nada más.
> **Duración:** entre 150 y 180 minutos. Más de la mitad se va en los cuatro fallos que se
> provocan a propósito, que es exactamente donde tiene que irse.
> **Qué deja levantado:** el perfil `db` de Compose corriendo (`inv-lab-postgres-1`) con su
> volumen `inv-lab_postgres-data`. [`L05`](l05-clientes-y-resiliencia.md) asume ese perfil arriba. La aplicación se lanza y
> se mata en cada sección.
> **Qué toca:** el `pom.xml`, `application.yml`, el directorio nuevo
> `src/main/resources/db/migration/` con la primera migración de Flyway, y las clases de
> persistencia y servicio bajo `com.invlab.invapi.inventory`. El `docker-compose.yml` **no se
> amplía**: está escrito desde `L01` y hoy solo se levanta su perfil `db`. Fuera del proyecto,
> el volumen de datos de Postgres que gestiona Compose.
> **Vigencia:** 18 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 ·
> Java 21 · Postgres 17.11 · Hibernate 6.6.

**Salto rápido:** [Estado inicial](#1--el-problema-y-el-estado-inicial) ·
[Postgres y Flyway](#2--postgres-en-compose-flyway-y-el-teardown) ·
[`JdbcClient` vs JPA](#3--jdbcclient-y-spring-data-jpa-lado-a-lado) ·
[El N+1](#4-️-el-n1-provocado-y-por-qué-show-sql-no-basta) ·
[`LazyInitializationException`](#5-️-lazyinitializationexception-con-open-in-view-false) ·
[El rollback que no ocurre](#6--el-gran-experimento-el-rollback-que-no-ocurre) ·
[El deadlock de pool](#7-️-requires_new-y-el-deadlock-de-pool) ·
[Checklist](#8--checklist-de-salida) ·
[Preguntas rápidas](#-preguntas-rápidas) ·
[Ejercicios](#-ejercicios-16)

---

## 1. 🧭 El problema y el estado inicial

En `L03` construiste una API que contesta bien. Contesta tan bien que nadie se fija en que
reiniciar el proceso borra el inventario entero, y que dos peticiones simultáneas sobre el
mismo `sku` pueden perder un movimiento sin que aparezca nada en el log.

Hoy cambiamos el almacenamiento, y en cuanto lo hagamos empiezan a aparecer fallos de una
familia nueva: los que **no rompen nada visible**. Un 500 se ve. Un `@Transactional` que no
hace rollback devuelve `201`, escribe en el log `evento registrado` y deja la base en un
estado inconsistente que nadie descubre hasta el cierre contable.

```text
L03  →  falla el borde HTTP    → lo ves en el código de estado
L04  →  falla la persistencia  → lo ves en un SELECT, o no lo ves nunca
```

Ese es el cambio de músculo de este lab. A partir de la sección 3, **la verificación deja
de ser `curl -i` y pasa a ser `psql -c "SELECT ..."`**: la respuesta HTTP ya no es prueba de
nada.

Primero confirma que vienes del estado correcto:

```bash
cd inv-api
./mvnw -q clean package
java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 8
curl -s -o /dev/null -w '%{http_code}\n' localhost:8081/actuator/health
curl -s -X POST localhost:8080/api/items -H 'Content-Type: application/json' \
  -d '{"sku":"ABC-000123","name":"Tornillo M6","quantity":40}' -o /dev/null -w '%{http_code}\n'
curl -s localhost:8080/api/items
```

```text
200
201
[{"sku":"ABC-000123","name":"Tornillo M6","quantity":40}]
```

- **`./mvnw -q clean package`** sin `-DskipTests` porque los tres tests de `MockMvc` de
  `L03` tienen que seguir pasando: son tu red de seguridad para todo lo que vas a mover hoy.
  Si fallan, el problema es de `L03` y se arregla allí antes de tocar nada.
- **`> app.log 2>&1 &`** es nuevo y va a ser la herramienta más usada del lab. Manda salida
  estándar y error al fichero, y deja el proceso en segundo plano. Lo necesitamos porque a
  partir de la sección 4 la pregunta deja de ser "¿qué dice el log?" y pasa a ser **"¿cuántas
  veces lo dice?"**, y eso se contesta con `grep -c`, no leyendo la pantalla. `kill %1` lo
  mata, `jobs` lo lista.
- **`sleep 8`** da margen al arranque. Encadenar el `curl` con `&&` sin esperar produce un
  *Connection refused* que parece un fallo de configuración y no lo es.
- **El `201` seguido del `[{...}]`** confirma que el `InventoryStore` en memoria sigue en su
  sitio. Reinicia el proceso y repite el `GET`: devuelve `[]`. Esa es la línea base que vamos
  a destruir.

**Lo que vas a construir hoy, en orden**, y el porqué de ese orden: primero el esquema
(sección 2), porque sin tablas no hay nada que romper; después las dos formas de leerlo
(sección 3), porque los fallos de las secciones siguientes se diagnostican leyendo SQL;
y después los cuatro fallos, de menos a más silencioso — N+1 (se ve si miras), lazy loading
(se ve porque explota), rollback ausente (no se ve) y pool agotado (se ve tarde y en el
sitio equivocado).

> **📝 Lo que este lab deja fuera a propósito.** La proyección en Mongo desde un
> `@TransactionalEventListener(AFTER_COMMIT)` y el bloqueo optimista con `@Version` son
> mecanismos que **sí** pertenecen a este tema, pero que no aportan un fallo silencioso
> nuevo: van como 🔥 opcionales al final, con el esquema ya preparado para los dos.
> `@DataJpaTest`, `@ServiceConnection` y Testcontainers son el capítulo [`24` §9](24-testing.md#9--testcontainers-y-serviceconnection-y-por-qué-no-h2) y su lab, y
> usarlos hoy escondería justamente lo que queremos ver: una base real, con su contenedor y
> su volumen. El multi-datasource con `@Primary` y la auditoría de JPA quedan para cuando
> haya un caso que los pida, y `R2DBC` está excluido de toda la serie por
> [`L00` §3](l00-idea-lab-practico.md#3--el-catálogo-de-exclusiones-una-por-una).

---

## 2. 🧱 Postgres en Compose, Flyway y el teardown

Necesitas una base de datos real. No H2, no una embebida: **Postgres**, porque el 60 % de lo
que este lab enseña —el bloqueo, el `ON CONFLICT`, el comportamiento del pool, `pg_stat_activity`—
no existe o se comporta distinto en cualquier otra cosa, y porque el bug que veas en H2 no es
el bug que tienes en producción ([`15` §10](15-datos-jdbc-jpa-mongo-y-redis.md#10-️-errores-frecuentes)).

El `docker-compose.yml` ya está escrito desde
[`L01` §14](l01-esqueleto-cli-y-autoconfiguracion.md#14--el-docker-composeyml-se-escribe-aquí-y-no-se-levanta)
y **no se toca**: está entero, con su
explicación servicio por servicio, en
[`L00` §6](l00-idea-lab-practico.md#6--el-docker-composeyml-de-la-serie). Lo único que hace
este lab es levantar su perfil `db`.

```bash
cd ..                      # a la raíz del repo, donde vive el docker-compose.yml
docker compose --profile db up -d
docker compose -p inv-lab ps
cd inv-api                 # de vuelta al proyecto: el resto del lab compila aquí
```

```text
NAME                IMAGE                     STATUS                    PORTS
inv-lab-postgres-1  postgres:17.11-alpine     Up 12 seconds (healthy)   0.0.0.0:5432->5432/tcp
```

- **`--profile db`** es obligatorio: el Compose de la serie declara `profiles:` en todos los
  servicios, así que `docker compose up -d` a secas **no levanta nada**. Es deliberado, para
  que no cargues siete contenedores cuando necesitas uno.
- **`inv-lab-postgres-1`** es el nombre que sale de `name: inv-lab` + servicio + índice. Lo
  vas a escribir muchas veces hoy; anótalo.
- **`(healthy)`**, y no solo `Up`, es lo que hay que esperar. Viene del `healthcheck` con
  `pg_isready` del Compose: `Up` significa que el contenedor arrancó, `healthy` significa que
  Postgres acepta conexiones. Entre los dos hay dos o tres segundos en los que tu aplicación
  fallaría al conectar con un `Connection refused`, y esa es la mitad de los "en mi máquina no
  arranca" con Compose.

Y **el teardown va aquí, no al final del lab**, porque es aquí donde se crea el recurso:

```bash
docker compose -p inv-lab down          # para el contenedor, CONSERVA el volumen
docker volume ls | grep inv-lab         # el volumen sigue ahí
docker compose -p inv-lab down -v       # ahora sí: contenedor y volumen
docker volume ls | grep inv-lab         # ya no devuelve nada
```

- **`down` sin `-v` no borra los datos.** El volumen `inv-lab_postgres-data` sobrevive, y al
  volver a levantar el perfil encuentras las tablas, las filas y el historial de Flyway de la
  sesión anterior. Esa es la fuente número uno de "el lab me da un resultado distinto al del
  documento": estás ejecutando las secciones 4 a 7 sobre datos de ayer.
- **`down -v` borra el volumen**, y con él la base entera. Es lo que quieres entre sesiones de
  este lab, y lo que **no** quieres hacer a media sesión sin acordarte de que después hay que
  volver a sembrar los datos de la sección 4.
- **`-p inv-lab`** hace que los dos comandos funcionen desde cualquier directorio, sin tener
  el `docker-compose.yml` delante. Con el proyecto nombrado en el fichero, `-p` y el nombre
  coinciden siempre.
- **Lo que no muere con ninguno de los dos:** la imagen `postgres:17.11-alpine` descargada
  (unos 240 MB, se borra con `docker image rm`), el `~/.m2` con las dependencias nuevas que
  estás a punto de bajar, y `target/`. Eso se limpia en [`L09` §8](l09-empaquetado-imagen-y-limpieza.md#8--la-limpieza-verificada) y no antes.

Ahora las dependencias. En `pom.xml`, dentro de `<dependencies>`:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>
</dependency>
<dependency>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-core</artifactId>
</dependency>
<dependency>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-database-postgresql</artifactId>
</dependency>
```

- **Ninguna lleva `<version>`**, y eso no es descuido: las cuatro están en el BOM de Spring
  Boot 3.5.16 que heredas del `<parent>`, así que la versión la decide Boot y es la que él
  probó. Fijarla a mano es cómo se consigue un `NoSuchMethodError` en el arranque seis meses
  después.
- **`spring-boot-starter-data-jpa`** arrastra Hibernate 6.6, `spring-orm`, `spring-jdbc`,
  Jakarta Persistence y **HikariCP**. En cuanto esté en el classpath, la autoconfiguración de
  `06` va a buscar una URL de base de datos y va a **romper el arranque si no la encuentra**;
  por eso la configuración va en la misma edición.
- **`postgresql` en `runtime`** porque tu código no importa una sola clase del driver: lo
  carga el `DriverManager` por el `ServiceLoader`. Ponerlo en `compile` deja que alguien
  escriba `import org.postgresql.*` en un servicio y ate la aplicación al motor.
- **`flyway-database-postgresql` es un artefacto aparte desde Flyway 10** y es el error de
  migración más común del año: sin él el arranque falla con `Unsupported Database: PostgreSQL 17.11`
  aunque `flyway-core` esté presente.

La configuración, en `src/main/resources/application.yml`, bajo el `spring:` que ya existe:

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/inv_lab
    username: inv_lab                     # triviales a propósito: mueren con `down -v`
    password: inv_lab
    hikari:
      maximum-pool-size: 10
      connection-timeout: 3000            # ms que un hilo espera por una conexión libre
      leak-detection-threshold: 20000     # WARN con stack trace si alguien la retiene 20 s
  jpa:
    open-in-view: false                   # el default de Boot es true; sección 5
    hibernate:
      ddl-auto: validate                  # el esquema lo hace Flyway, no Hibernate
    properties:
      hibernate.generate_statistics: true # cuántas consultas hubo por sesión; sección 4
  flyway:
    enabled: true
```

- **`maximum-pool-size: 10`** es el default de Hikari escrito en voz alta, porque en la
  sección 7 lo vamos a bajar a 2 y conviene que el punto de partida esté a la vista.
- **`connection-timeout: 3000`** contra los 30 000 ms del default. Tres segundos convierten
  un pool agotado en un error legible; treinta segundos lo convierten en una caída total en
  la que nadie sabe qué pasa. **Fallar rápido es mejor dato que esperar mucho.**
- **`leak-detection-threshold: 20000`** no cierra ninguna conexión: escribe un `WARN` con el
  stack trace de quien la retuvo más de 20 segundos. Es gratis y te da el nombre del método
  culpable el día que lo necesites.
- **`open-in-view: false`** invierte el default de Boot. El porqué completo es la sección 5,
  y se pone ya para que la sección 5 pueda demostrarlo sin tocar nada.
- **`ddl-auto: validate`** hace que Hibernate compare tus entidades con el esquema real y
  **rompa el arranque si no encajan**, sin tocar una sola tabla. Con `update` tendrías un
  esquema que nadie escribió a propósito; con `none` perderías la comprobación. `validate` es
  la pareja natural de Flyway.
- **`hibernate.generate_statistics: true`** imprime, al cerrar cada sesión, cuántas sentencias
  JDBC se ejecutaron. Es caro para producción y es exactamente lo que necesitamos en la
  sección 4.

El esquema, en `src/main/resources/db/migration/V1__create_inventory_schema.sql`:

```sql
CREATE TABLE inventory_item (
    id        BIGSERIAL PRIMARY KEY,
    sku       VARCHAR(10)  NOT NULL UNIQUE,
    name      VARCHAR(80)  NOT NULL,
    quantity  INTEGER      NOT NULL,
    version   BIGINT       NOT NULL DEFAULT 0
);

CREATE TABLE inventory_event (
    id           BIGSERIAL    PRIMARY KEY,
    item_id      BIGINT       NOT NULL REFERENCES inventory_item(id),
    delta        INTEGER      NOT NULL,
    reason       VARCHAR(40)  NOT NULL,
    occurred_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX idx_inventory_event_item ON inventory_event(item_id);
```

- **`V1__create_inventory_schema.sql`**: `V` de versionada, `1` la versión, **doble guion
  bajo**, y después la descripción. Un solo guion bajo y Flyway no reconoce el fichero; el
  orden lo da la versión, no el nombre alfabético.
- **`BIGSERIAL`** crea la secuencia y el default en una línea. La clave primaria es técnica
  y el `sku` es la clave de negocio con su `UNIQUE`: así el `409` de duplicado de `L03` lo
  garantiza ahora la base y no un `Map`.
- **`REFERENCES inventory_item(id)`** es lo que hace imposible un evento huérfano. Y es la
  restricción que usaremos en un ejercicio para provocar un `DataIntegrityViolationException`.
- **`VARCHAR(10)` en `sku` y `VARCHAR(80)` en `name`** repiten a propósito los límites que
  `L03` puso en Bean Validation. Duplicar la restricción no es redundancia: la validación
  devuelve un `400` legible y la columna impide que un camino sin validar meta basura.
- **`idx_inventory_event_item`** existe porque toda la sección 4 consulta eventos por item.
  Sin índice, el N+1 que vamos a provocar sería además un *sequential scan* por iteración y
  estaríamos mezclando dos problemas en un mismo síntoma — **una variable a la vez**.
- **`version BIGINT NOT NULL DEFAULT 0`** no lo usa ninguna entidad todavía. Está para el
  🔥 opcional de bloqueo optimista, y sobra sin romper nada: `ddl-auto: validate` comprueba
  que **las propiedades de tus entidades existan como columnas**, no al revés, así que una
  columna de más no falla el arranque.

Arranca y mira el log de Flyway:

```bash
cd inv-api
./mvnw -q clean package -DskipTests
java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
grep -E 'Flyway|Migrating|migration' app.log
```

```text
2026-09-18T09:22:41.118-05:00  INFO 42118 --- [           main] o.f.c.i.license.VersionPrinter           : Flyway Community Edition 11.7.2 by Redgate
2026-09-18T09:22:41.402-05:00  INFO 42118 --- [           main] o.f.core.internal.command.DbValidate     : Successfully validated 1 migration (execution time 00:00.048s)
2026-09-18T09:22:41.511-05:00  INFO 42118 --- [           main] o.f.c.i.s.JdbcTableSchemaHistory         : Creating Schema History table "public"."flyway_schema_history" ...
2026-09-18T09:22:41.640-05:00  INFO 42118 --- [           main] o.f.core.internal.command.DbMigrate      : Current version of schema "public": << Empty Schema >>
2026-09-18T09:22:41.644-05:00  INFO 42118 --- [           main] o.f.core.internal.command.DbMigrate      : Migrating schema "public" to version "1 - create inventory schema"
2026-09-18T09:22:41.771-05:00  INFO 42118 --- [           main] o.f.core.internal.command.DbMigrate      : Successfully applied 1 migration to schema "public", now at version v1 (execution time 00:00.093s)
```

- **`flyway_schema_history`** es la tabla que Flyway crea para sí mismo: qué migración corrió,
  cuándo, cuánto tardó y su **checksum**. Es lo que permite que el arranque número doscientos
  no vuelva a ejecutar `V1`.
- **`Migrating schema "public" to version "1 - create inventory schema"`**: la descripción sale
  del nombre del fichero con los guiones bajos convertidos en espacios. Por eso el nombre del
  fichero es documentación y no un identificador cualquiera.
- **Flyway corre antes de que Hibernate valide**, y ese orden lo garantiza la
  autoconfiguración de Boot: si se invirtiera, `validate` fallaría siempre en una base nueva.

> **🩺 Diagnóstico: el fallo de Flyway que te vas a encontrar.** Si editas un `V1__` ya
> aplicado, el siguiente arranque muere con
> `FlywayValidateException: Validate failed: Migrations have failed validation ... Migration checksum mismatch for migration version 1`.
> No es un bug: es el contrato. Una migración aplicada es inmutable, y lo que se corrige se
> corrige con **otra migración**. Durante este lab, si necesitas rehacer el esquema, el camino
> es `docker compose -p inv-lab down -v` y volver a levantar, no editar el `V1`.

Comprueba el esquema desde dentro del contenedor, que es el comando que vas a repetir todo el
lab:

```bash
docker exec -i inv-lab-postgres-1 psql -U inv_lab -d inv_lab -c '\dt'
```

```text
                List of relations
 Schema |         Name          | Type  |  Owner
--------+-----------------------+-------+---------
 public | flyway_schema_history | table | inv_lab
 public | inventory_event       | table | inv_lab
 public | inventory_item        | table | inv_lab
(3 rows)
```

- **`docker exec -i`** y no `-it`: sin `-t` no necesitas una TTY, y así el comando funciona
  igual dentro de un script o de un pipe. Con `-it` en un pipeline obtienes
  `the input device is not a TTY`.
- **`-U inv_lab -d inv_lab`** son usuario y base del Compose. No hay contraseña en el comando
  porque dentro del contenedor la conexión local está en `trust`; desde fuera sí te la pediría.
- **`\dt`** lista tablas. Los otros dos que vas a usar hoy: `\d inventory_event` para ver una
  tabla y sus restricciones, y `\x` para salida vertical cuando una fila no cabe a lo ancho.

---

## 3. ⚖ `JdbcClient` y Spring Data JPA, lado a lado

Ya hay tablas y no hay quien las use: el `InventoryStore` de `L03` sigue guardando en un
`ConcurrentHashMap`. Este es el momento de matarlo, y de hacerlo enseñando algo: **la misma
consulta resuelta por las dos vías que tiene Spring**, con el SQL a la vista en las dos, para
que el veredicto de cuándo usar cada una salga de mirar la salida y no de una opinión.

La consulta que vamos a resolver dos veces es la que pedirá negocio en cuanto haya datos:
*el total de movimientos acumulados por `sku`*.

Primero las entidades, en `src/main/java/com/invlab/invapi/inventory/InventoryModel.java`,
que sustituye a los dos `record` de `L03`:

```java
@Entity
@Table(name = "inventory_item")
class InventoryItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 10)
    private String sku;

    @Column(nullable = false, length = 80)
    private String name;

    @Column(nullable = false)
    private int quantity;

    // LAZY explícito: el default de @OneToMany ya es LAZY, pero escribirlo evita
    // que alguien lo "arregle" a EAGER en una revisión apurada
    @OneToMany(mappedBy = "item", fetch = FetchType.LAZY, cascade = CascadeType.ALL)
    private List<InventoryEvent> events = new ArrayList<>();

    protected InventoryItem() { }                      // exigido por JPA, no lo uses tú

    InventoryItem(String sku, String name, int quantity) {
        this.sku = sku;
        this.name = name;
        this.quantity = quantity;
    }

    void applyDelta(int delta) {
        this.quantity += delta;                        // dirty checking: no hace falta save()
    }

    void addEvent(InventoryEvent event) {
        events.add(event);
        event.setItem(this);                           // los dos lados, o el FK queda null
    }

    Long id() { return id; }
    String sku() { return sku; }
    String name() { return name; }
    int quantity() { return quantity; }
    List<InventoryEvent> events() { return events; }
}
```

- **`InventoryItem` deja de ser un `record`**, y esa es la primera renuncia del lab. JPA
  necesita un constructor sin argumentos y campos mutables para el dirty checking; un `record`
  es final e inmutable por definición. La convención de §5.1 de la guía —`record` para DTOs,
  clases normales para entidades— es exactamente esta línea divisoria. Los DTOs de `L03`
  (`ItemResponse`, `CreateItemRequest`) **siguen siendo `record` y no se tocan**.
- **`@GeneratedValue(strategy = IDENTITY)`** delega el id a la secuencia del `BIGSERIAL`.
  Tiene un costo escondido: con `IDENTITY`, Hibernate **no puede agrupar los `INSERT` en lote**,
  porque necesita el id de vuelta en cada uno. Con `SEQUENCE` y un `allocationSize` sí puede.
  Para este lab da igual; en una carga masiva no.
- **`protected InventoryItem()`** existe solo para Hibernate, que lo invoca por reflexión al
  materializar una fila. `private` también funcionaría para Hibernate pero no para el proxy
  de carga diferida, que necesita heredar: por eso `protected` y no menos.
- **`mappedBy = "item"`** declara que **el dueño de la relación es `InventoryEvent`**, que es
  quien tiene la columna `item_id`. Sin `mappedBy`, JPA asumiría dos relaciones distintas y
  pediría una tabla de unión que no existe, y `ddl-auto: validate` rompería el arranque.
- **`cascade = ALL`** hace que guardar el item guarde sus eventos nuevos. Es cómodo y es un
  cuchillo: `ALL` incluye `REMOVE`, así que borrar un item borra sus eventos. Aquí es lo que
  queremos; en una tabla de auditoría sería inaceptable.
- **`applyDelta` no llama a `save()`** y aun así persiste, siempre que la entidad esté
  *managed* dentro de una transacción. Eso es dirty checking
  ([`15` §5](15-datos-jdbc-jpa-mongo-y-redis.md#5--el-persistence-context-de-donde-salen-las-sorpresas)),
  y es la primera cosa de este lab que parece magia hasta que la ves en el log.
- **`addEvent` toca los dos lados.** Añadir a la lista sin hacer `event.setItem(this)` produce
  un `INSERT` con `item_id` nulo y un `null value in column "item_id" violates not-null constraint`.
  Mantener las dos puntas de una relación bidireccional es responsabilidad tuya, no de JPA.

```java
@Entity
@Table(name = "inventory_event")
class InventoryEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "item_id", nullable = false)
    private InventoryItem item;

    @Column(nullable = false)
    private int delta;

    @Column(nullable = false, length = 40)
    private String reason;

    @Column(name = "occurred_at", nullable = false)
    private Instant occurredAt = Instant.now();

    protected InventoryEvent() { }

    InventoryEvent(int delta, String reason) {
        this.delta = delta;
        this.reason = reason;
    }

    void setItem(InventoryItem item) { this.item = item; }

    Long id() { return id; }
    int delta() { return delta; }
    String reason() { return reason; }
    Instant occurredAt() { return occurredAt; }
}
```

- **`@ManyToOne(fetch = LAZY)` es la línea más importante del bloque.** El default de
  `@ManyToOne` **es `EAGER` por especificación**, y dejarlo así significa que cada vez que
  cargues un evento, Hibernate carga también su item, lo necesites o no. Ponerlo `LAZY` es casi
  siempre correcto y es lo que hace que la sección 5 tenga algo que romper.
- **`optional = false` y `nullable = false`** dicen lo mismo a dos destinatarios: el primero a
  Hibernate, que puede optimizar el `JOIN`; el segundo a la validación del esquema.
- **`Instant` y no `LocalDateTime`** para casar con `TIMESTAMPTZ`. Un `LocalDateTime` contra
  una columna con zona es cómo se pierden cinco horas en producción sin que nadie lo note hasta
  que el reporte diario sale corrido.

Ahora las dos vías de consulta. La declarativa, en `InventoryItemRepository`:

```java
interface InventoryItemRepository extends JpaRepository<InventoryItem, Long> {

    Optional<InventoryItem> findBySku(String sku);

    // proyección a record: la base devuelve dos columnas, no la fila entera
    @Query("""
           select new com.invlab.invapi.inventory.SkuTotal(i.sku, coalesce(sum(e.delta), 0))
           from InventoryItem i left join i.events e
           group by i.sku
           order by i.sku
           """)
    List<SkuTotal> totalsBySku();
}

record SkuTotal(String sku, long total) { }
```

- **`findBySku` es una derived query**: el nombre del método **es** la consulta, y se parsea en
  el arranque, no en la primera llamada. Escribe `findBySkuu` y el contexto no levanta:
  `PropertyReferenceException: No property 'skuu' found for type 'InventoryItem'`. Fallar en el
  arranque es un regalo.
- **El bloque de texto de Java 21 (`"""`)** deja el JPQL legible sin concatenar. Es la única
  razón por la que está aquí: tres líneas de `+ "…"` esconden un espacio faltante entre
  cláusulas y eso es un error de sintaxis a las dos de la mañana.
- **`select new com.invlab...SkuTotal(...)`** exige el **nombre completo con paquete** —JPQL no
  ve tus imports— y un constructor que case en tipos exactos. Con `long total` y un `sum()` que
  devuelve `Long`, encaja; con `int` fallaría en tiempo de ejecución.
- **JPQL habla de entidades, no de tablas:** `i.events` es la propiedad, no la columna, y `left
  join i.events e` no necesita `ON` porque la relación ya está declarada en el mapeo.
- **`coalesce(sum(e.delta), 0)`** convierte el `null` de un item sin eventos en un cero. Sin él,
  el `record` recibe `null` en un `long` y obtienes un `NullPointerException` al desempaquetar,
  con un stack trace que no menciona tu consulta.

La misma consulta con SQL a la vista, en un `InventoryQueries` nuevo:

```java
@Component
class InventoryQueries {

    private final JdbcClient jdbc;

    InventoryQueries(JdbcClient jdbc) {          // Boot lo autoconfigura sobre el DataSource
        this.jdbc = jdbc;
    }

    List<SkuTotal> totalsBySku() {
        return jdbc.sql("""
                        SELECT i.sku AS sku, COALESCE(SUM(e.delta), 0) AS total
                        FROM inventory_item i
                        LEFT JOIN inventory_event e ON e.item_id = i.id
                        GROUP BY i.sku
                        ORDER BY i.sku
                        """)
                .query(SkuTotal.class)
                .list();
    }
}
```

- **`JdbcClient` no tiene pool ni conexiones propias:** usa el mismo `DataSource` de Hikari que
  JPA, así que las dos vías compiten por las mismas diez conexiones. Eso importa en la sección 7.
- **`.query(SkuTotal.class)`** casa columnas con componentes del `record` por nombre, con
  *relaxed binding* (`occurred_at` ↔ `occurredAt`). Por eso los alias `AS sku` y `AS total`
  están escritos: sin el alias, la columna calculada se llamaría `coalesce` y no tendría destino.
- **`.list()` frente a `.single()`**: el segundo lanza
  `IncorrectResultSizeDataAccessException` con cero filas o con dos, que es justo lo que quieres
  cuando la consulta debe devolver exactamente una.
- **No hay un solo parámetro concatenado**, y cuando lo haya será con `.param("sku", sku)`. Un
  `PreparedStatement` manda el valor aparte del SQL; concatenar es el agujero de seguridad más
  viejo del oficio y no tiene ninguna excusa en 2026.

Cablea las dos y compáralas. Sube el SQL de Hibernate en `application.yml`:

```yaml
logging:
  level:
    org.hibernate.SQL: DEBUG                 # cada sentencia, por el logger real
    org.hibernate.orm.jdbc.bind: TRACE       # el valor de cada '?'
    org.springframework.jdbc.core.JdbcTemplate: DEBUG   # el SQL de JdbcClient
```

- **`org.hibernate.SQL` en `DEBUG`** manda el SQL al logger de verdad, con timestamp, hilo y el
  `requestId` del MDC que pusiste en `L03`. **`spring.jpa.show-sql=true` no sirve para esto**:
  escribe por `System.out`, sin timestamp, sin hilo y sin correlación, y en un agregador de logs
  es basura. Es la sección 4 en una línea.
- **`org.hibernate.orm.jdbc.bind` en `TRACE`** imprime los parámetros. Ojo: **eso escribe datos
  personales en el log**, así que es una configuración de tu máquina y nunca de un entorno con
  datos reales.
- **`JdbcTemplate` en `DEBUG`** es el equivalente para `JdbcClient`, que por dentro sigue siendo
  `JdbcTemplate`. Dos loggers distintos para dos caminos distintos: si solo subes uno, media
  aplicación queda muda y parece que no consulta.

Llama a las dos desde un endpoint temporal y mira el log:

```bash
kill %1
./mvnw -q clean package -DskipTests && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s localhost:8080/api/items/totals?engine=jpa  | head -c 120; echo
curl -s localhost:8080/api/items/totals?engine=jdbc | head -c 120; echo
grep -E 'select|SELECT' app.log | tail -4
```

```text
[{"sku":"ABC-000123","total":0}]
[{"sku":"ABC-000123","total":0}]
2026-09-18T09:41:12.882-05:00 DEBUG 42330 --- [nio-8080-exec-2] org.hibernate.SQL : select i1_0.sku,coalesce(sum(e1_0.delta),0) from inventory_item i1_0 left join inventory_event e1_0 on i1_0.id=e1_0.item_id group by i1_0.sku order by i1_0.sku
2026-09-18T09:41:18.104-05:00 DEBUG 42330 --- [nio-8080-exec-4] o.s.jdbc.core.JdbcTemplate : Executing SQL query [SELECT i.sku AS sku, COALESCE(SUM(e.delta), 0) AS total FROM inventory_item i LEFT JOIN inventory_event e ON e.item_id = i.id GROUP BY i.sku ORDER BY i.sku]
```

- **El SQL que genera Hibernate es equivalente, no idéntico.** Los alias `i1_0` son suyos y no
  se pueden fijar; el `JOIN` lo dedujo del mapeo. Eso es exactamente lo que ganas y lo que
  pierdes: no escribes el `JOIN`, y tampoco lo controlas.
- **El de `JdbcClient` sale tal cual lo escribiste**, incluidos los saltos de línea del bloque
  de texto. Si el DBA te pide el plan de ejecución, puedes pegárselo; con JPQL primero tienes
  que arrancar la aplicación para saber qué SQL sale.
- **`head -c 120`** corta la salida para que el `curl` no inunde la terminal; los dos cuerpos
  son idénticos, que es el punto.

**Veredicto**, que es lo que hay que poder decir en una entrevista:

| Criterio | `JdbcClient` | Spring Data JPA |
|---|---|---|
| El producto es el SQL (reportes, agregaciones, cargas) | ✅ lo escribes y lo controlas | ❌ Hibernate decide |
| El producto es el grafo de objetos y su ciclo de vida | ❌ mapeas a mano | ✅ dirty checking, cascadas |
| Sorpresas en runtime | ninguna: lo que escribes es lo que corre | N+1, lazy loading, flush |

> **🧠 Modelo mental.** No compiten: conviven en el mismo servicio y sobre el **mismo**
> `DataSource`. La pregunta correcta no es "¿JPA o JDBC?", es "¿esta consulta concreta la quiero
> escribir yo o la quiero deducir de un mapeo?". Un servicio de banca serio tiene las dos.

Ahora sí, **el `Map` muere**. Sustituye el `InventoryStore` de `L03` por un servicio sobre el
repositorio:

```java
@Service
class InventoryService {

    private final InventoryItemRepository repository;

    InventoryService(InventoryItemRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    Optional<InventoryItem> findBySku(String sku) {
        return repository.findBySku(sku);
    }

    @Transactional
    InventoryItem create(String sku, String name, int quantity) {
        return repository.save(new InventoryItem(sku, name, quantity));
    }
}
```

- **`@Service` y no `@Component`**: los dos producen el mismo bean, la diferencia es semántica.
  Aquí sí es honesto, porque esto es lógica de negocio y el `InventoryStore` de `L03` nunca lo
  fue.
- **El import correcto es `org.springframework.transaction.annotation.Transactional`.** El IDE
  te va a ofrecer también `jakarta.transaction.Transactional`, que compila, funciona a medias y
  **no tiene `readOnly`, ni `rollbackFor`, ni `isolation`**. Escribe el import a mano la primera
  vez; es el sexto silencio de
  [`16` §7](16-transacciones.md#7--los-seis-silencios) y se comete solo.
- **`readOnly = true`** le dice a Hibernate que no haga dirty checking —ahorro real, no
  cosmético, en consultas que devuelven muchas filas— y a la base que puede optimizar. **No es
  una garantía de nada:** en Postgres no impide escribir, así que no lo uses como medida de
  seguridad.
- **`@Transactional` en `create` no es decorativo:** sin él, el `save()` correría en la
  transacción propia de `SimpleJpaRepository` y en cuanto la operación necesite dos escrituras
  —que es lo que pasa en la sección 6— dejarían de ser atómicas.

Borra `InventoryStore.java` y cambia el controller para que dependa de `InventoryService`. El
contrato HTTP no cambia ni una coma: los mismos `record` de DTO, los mismos códigos, el mismo
`ProblemDetail`. Compruébalo con los tests que ya tenías:

```bash
kill %1
docker compose -p inv-lab down -v && docker compose --profile db up -d && sleep 10
cd inv-api && ./mvnw -q clean package
java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -X POST localhost:8080/api/items -H 'Content-Type: application/json' \
  -d '{"sku":"ABC-000123","name":"Tornillo M6","quantity":40}' -o /dev/null -w '%{http_code}\n'
docker exec -i inv-lab-postgres-1 psql -U inv_lab -d inv_lab \
  -c 'SELECT id, sku, quantity FROM inventory_item'
```

```text
201
 id |    sku     | quantity
----+------------+----------
  1 | ABC-000123 |       40
(1 row)
```

- **Ese `SELECT` es el nuevo criterio de verdad del lab.** El `201` ya no demuestra nada: lo
  único que demuestra que el dato existe es leerlo desde fuera de la aplicación.
- **`down -v` antes de arrancar** limpia los restos de las pruebas anteriores. Si te lo saltas,
  el `201` se convierte en un `409` porque el `sku` ya estaba, y perderás diez minutos buscando
  un bug que no existe.
- **Los tests de `MockMvc` de `L03` siguen pasando** y eso merece un segundo de atención: usan
  el contexto completo, que ahora necesita Postgres. Si `./mvnw test` te falla con
  `Connection to localhost:5432 refused`, es que el perfil `db` no está arriba. Levantarlo es
  la respuesta hoy; aislarlo con Testcontainers es `24`.

---

## 4. ⚠️ El N+1 provocado y por qué `show-sql` no basta

Primer fallo del lab, y el más común de todos: el endpoint que va bien con tres filas de prueba
y tarda cuatro segundos con doscientas.

El escenario: negocio pide que `GET /api/items` devuelva, junto a cada item, **cuántos
movimientos tiene**. Es una línea de código.

```java
// dentro de InventoryService
@Transactional(readOnly = true)
List<ItemSummary> summaries(int limit) {
    return repository.findAll(PageRequest.of(0, limit)).getContent().stream()
            .map(item -> new ItemSummary(item.sku(), item.quantity(), item.events().size()))
            .toList();                       // item.events().size() dispara la carga diferida
}

record ItemSummary(String sku, int quantity, int eventCount) { }
```

- **`item.events().size()`** parece gratis y no lo es: la colección es `LAZY`, así que al
  preguntarle el tamaño Hibernate emite un `SELECT` **por cada item**. Es la definición exacta
  del N+1, y no hay en este código una sola pista de que vaya a ocurrir.
- **`PageRequest.of(0, limit)`** añade `LIMIT`/`OFFSET` a la consulta principal. Es el `limit`
  del contrato de `L03` traducido a la capa de datos, y no toca el problema en absoluto.
- **`@Transactional(readOnly = true)`** es lo que mantiene el persistence context abierto
  durante el `map`. Sin él —y con `open-in-view: false`— esto no sería un N+1: sería la
  excepción de la sección 5. Los dos fallos son el mismo mecanismo visto desde dos lados.

Siembra datos suficientes para que se note:

```bash
for i in $(seq 1 20); do
  SKU=$(printf 'SKU-%06d' "$i")
  curl -s -o /dev/null -X POST localhost:8080/api/items -H 'Content-Type: application/json' \
    -d "{\"sku\":\"$SKU\",\"name\":\"Item $i\",\"quantity\":100}"
  for j in 1 2 3; do
    curl -s -o /dev/null -X POST "localhost:8080/api/items/$SKU/events" \
      -H 'Content-Type: application/json' -d '{"delta":-1,"reason":"consumo"}'
  done
done
docker exec -i inv-lab-postgres-1 psql -U inv_lab -d inv_lab \
  -c 'SELECT count(*) AS items FROM inventory_item' \
  -c 'SELECT count(*) AS events FROM inventory_event'
```

```text
 items
-------
    21
(1 row)

 events
--------
     60
(1 row)
```

- **`printf 'SKU-%06d'`** genera `SKU-000001` … `SKU-000020`, que cumplen el
  `@Pattern("[A-Z]{3}-[0-9]{6}")` que `L03` puso en el DTO. Un `sku` de otra forma te devuelve
  `400` y el bucle sigue sin avisar, así que si ves menos de 21 items, mira el patrón antes de
  mirar la base.
- **`21` y no `20`** porque el `ABC-000123` de la sección anterior sigue ahí. Contarlo bien
  importa: en un momento vamos a contar consultas y un item de más son dos consultas de más.
- **`psql` con dos `-c`** ejecuta dos sentencias en una conexión. Es más rápido que dos
  `docker exec` y evita la confusión de ver dos veces "1 row".

**Antes de ejecutar, predice:** ¿cuántas sentencias SQL crees que va a emitir un
`GET /api/items?limit=20`? Escribe el número antes de seguir.

```bash
: > app.log                    # vacía el log para contar solo esta petición
curl -s -o /dev/null 'localhost:8080/api/items?limit=20'
grep -c 'org.hibernate.SQL' app.log
grep 'Session Metrics' -A 6 app.log | tail -7
```

```text
21
2026-09-18T10:12:44.118-05:00  INFO 42330 --- [nio-8080-exec-3] i.StatisticalLoggingSessionEventListener : Session Metrics {
    412700 nanoseconds spent acquiring 1 JDBC connections;
    0 nanoseconds spent releasing 0 JDBC connections;
    1881800 nanoseconds spent preparing 21 JDBC statements;
    21341900 nanoseconds spent executing 21 JDBC statements;
    0 nanoseconds spent executing 0 flushes (flushing a total of 0 entities and 0 collections);
    0 nanoseconds spent executing 0 partial-flushes (flushing a total of 0 entities and 0 collections)
}
```

- **`: > app.log`** vacía el fichero sin borrarlo, lo que mantiene válido el redireccionamiento
  del proceso que ya está corriendo. Si haces `rm app.log`, la JVM sigue escribiendo en un
  fichero que ya no tiene nombre y no ves nada más.
- **`22` sentencias para devolver 20 items**: una para la página y veinte para las colecciones.
  Esa es la aritmética del N+1, y crece lineal con el tamaño de la página: con `limit=100` son
  101, y con `limit=1000` tu endpoint tarda segundos mientras la base trabaja en ráfagas
  minúsculas.
- **`Session Metrics` lo imprime `generate_statistics`** al cerrar la sesión. Es el contador
  objetivo: `grep -c` cuenta líneas de log, la métrica cuenta sentencias reales, y cuando las dos
  coinciden puedes fiarte de la primera, que es más barata.

Ahora el punto que da nombre a la sección. Prueba el atajo que todo el mundo usa:

```yaml
spring:
  jpa:
    show-sql: true          # NO hagas esto: está aquí para ver por qué no sirve
```

```text
Hibernate: select i1_0.id,i1_0.name,i1_0.quantity,i1_0.sku from inventory_item i1_0 offset ? rows fetch first ? rows only
Hibernate: select e1_0.item_id,e1_0.id,e1_0.delta,e1_0.occurred_at,e1_0.reason from inventory_event e1_0 where e1_0.item_id=?
Hibernate: select e1_0.item_id,e1_0.id,e1_0.delta,e1_0.occurred_at,e1_0.reason from inventory_event e1_0 where e1_0.item_id=?
```

- **Sin timestamp, sin hilo, sin nivel y sin `requestId`.** `show-sql` escribe por `System.out`
  saltándose el sistema de logging entero. En tu terminal se lee; en un agregador con cuarenta
  instancias es imposible saber qué petición emitió qué.
- **Sin los parámetros**: ese `item_id=?` no te dice qué item lo causó, y sin eso no puedes
  saber si son veinte items distintos o el mismo veinte veces —que son dos bugs diferentes—.
- **Y lo peor: no se puede contar.** No hay logger al que subir el nivel, ni fichero al que
  hacerle `grep -c` con garantías de que no falta nada por el buffer de `stdout`.

> **🩺 Diagnóstico correcto, en tres claves.** `org.hibernate.SQL: DEBUG` para las sentencias
> con su contexto, `org.hibernate.orm.jdbc.bind: TRACE` para los parámetros —recuerda que eso
> escribe datos en claro— y `hibernate.generate_statistics: true` para el contador por sesión.
> Las tres están ya en tu `application.yml`. **Quita `show-sql` antes de seguir**; estaba aquí
> para verlo fallar.

La corrección es declarar qué quieres traer, en el repositorio:

```java
@EntityGraph(attributePaths = "events")
@Query("select i from InventoryItem i")
List<InventoryItem> findAllWithEvents(Pageable pageable);
```

- **`@EntityGraph(attributePaths = "events")`** le dice a Hibernate que cargue la asociación en
  la misma consulta, con un `LEFT JOIN`, sin que tú escribas el `JOIN`. `attributePaths` nombra
  **propiedades de la entidad**, no columnas, y admite rutas anidadas (`"events.item"`).
- **Va acompañado de un `@Query` trivial** porque `findAll(Pageable)` lo hereda de
  `JpaRepository` y no puedes anotar un método que no declaras. Declararlo cuesta dos líneas y
  te deja poner el grafo.
- **El `Pageable` sigue ahí y ahora tiene consecuencias**, que es el siguiente bloque.

```bash
kill %1
./mvnw -q clean package -DskipTests && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
: > app.log
curl -s -o /dev/null 'localhost:8080/api/items?limit=20'
grep -c 'org.hibernate.SQL' app.log
grep 'HHH90003004' app.log
```

```text
1
2026-09-18T10:31:07.554-05:00  WARN 42418 --- [nio-8080-exec-2] org.hibernate.orm.query : HHH90003004: firstResult/maxResults specified with collection fetch; applying in memory
```

- **De 21 a 1.** Ese es el número que se lleva a la entrevista: no "mejoró el rendimiento", sino
  *veintiuna consultas pasaron a ser una*.
- **Y a cambio apareció un `WARN` que hay que saber leer.** `HHH90003004` dice que Hibernate no
  puede aplicar `LIMIT` en SQL cuando la consulta trae una colección con `JOIN FETCH`: el `JOIN`
  multiplica las filas —tres eventos por item son tres filas por item— y un `LIMIT 20` cortaría
  por la mitad de un item. Así que **trae todo y pagina en memoria**.
- **En una tabla de veintiún items da igual; en una de un millón es una caída.** La salida real
  es traer solo los ids paginados y después los datos (dos consultas, no N+1), o proyectar
  directamente a un `record` con `count(e)` en vez de cargar la colección. Esta segunda es lo que
  pide el ejercicio 10.

Tres formas de resolver el N+1, y se prefieren en este orden:

- **`@EntityGraph`** cuando el método derivado ya existe y solo falta decir qué traer.
- **`JOIN FETCH` dentro de un `@Query`** para una consulta concreta: es lo mismo escrito a mano.
  **Sobre dos colecciones a la vez produce un producto cartesiano** y Hibernate lanza
  `MultipleBagFetchException` en el arranque si las dos son `List`.
- **`@BatchSize(size = 20)`** sobre la colección **no elimina** los N `SELECT`: los agrupa en
  `N/20` con un `IN (...)`. Es la red de seguridad para colecciones que siempre se recorren.

Y la que no es solución: **`FetchType.EAGER` en el mapeo**. Mueve el problema, porque ahora
*todas* las consultas cargan la asociación, incluida la que solo quería el `sku`.

> **⏱️ Costo en runtime del N+1.** Veintiún viajes de ida y vuelta a Postgres son veintiún
> *round-trips* de red: en `localhost` cada uno son décimas de milisegundo y no se nota, pero
> contra una base en otra subred son 1–2 ms cada uno, y el endpoint pasa de 15 ms a 40 ms **sin
> que la base aparezca cargada en ninguna gráfica**. Peor: cada una de esas 21 sentencias corre
> con la misma conexión del pool retenida, así que un endpoint con N+1 multiplica por N el
> tiempo de retención de la conexión, que es la variable que de verdad agota un pool
> ([`15` §2](15-datos-jdbc-jpa-mongo-y-redis.md#2--el-datasource-y-hikaricp)).

---

## 5. ⚠️ `LazyInitializationException` con `open-in-view: false`

Segundo fallo. Este sí explota, y explota en el peor sitio posible: **a media respuesta**, con
los primeros bytes del JSON ya enviados al cliente.

El escenario es una tentación real: alguien añade un endpoint "para depurar" que devuelve la
entidad tal cual, sin pasar por el DTO. Añádelo, porque el fallo hay que verlo:

```java
// en InventoryController — endpoint deliberadamente incorrecto, se borra al final de la sección
@GetMapping("/{sku}/raw")
InventoryItem raw(@PathVariable String sku) {
    return service.findBySku(sku).orElseThrow(() -> new ItemNotFoundException(sku));
}
```

- **Devuelve la entidad, no un DTO.** Jackson va a serializar todos sus getters, incluido
  `events()`, que es una colección `LAZY`.
- **`service.findBySku` es `@Transactional(readOnly = true)`**, así que la transacción abre y
  **cierra dentro del método**. Cuando el `HttpMessageConverter` de `09` empieza a escribir el
  JSON, el persistence context ya no existe.

**Predice:** ¿qué código de estado devuelve este endpoint, y qué se ve en el cuerpo?

```bash
kill %1
./mvnw -q clean package -DskipTests && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -i localhost:8080/api/items/SKU-000001/raw | head -12
```

```text
HTTP/1.1 500
Content-Type: application/problem+json
X-Request-Id: 0f2a1c7e-5b3d-4a19-9d11-8c7e2a4f6b30

{"type":"about:blank","title":"Internal Server Error","status":500,"detail":"Error interno","instance":"/api/items/SKU-000001/raw","requestId":"0f2a1c7e-5b3d-4a19-9d11-8c7e2a4f6b30"}
```

- **El `ProblemDetail` de `L03` hizo su trabajo** y convirtió el desastre en una respuesta con
  formato. Eso es bueno para el cliente y **malo para ti**, porque el cuerpo no dice nada: hay
  que ir al log.
- **Un 500, no un 200 truncado**, porque en este caso concreto el error saltó antes de que
  Jackson escribiera el primer byte del cuerpo. Si la asociación estuviera más abajo en el
  objeto, el cliente recibiría un `200` con un JSON cortado a la mitad y un `Content-Length` que
  no cuadra. Ese es el escenario que de verdad asusta.

La primera línea, literal, es la que hay que reconocer de memoria:

```bash
grep -m 1 'LazyInitializationException' app.log
```

```text
org.hibernate.LazyInitializationException: failed to lazily initialize a collection of role: com.invlab.invapi.inventory.InventoryItem.events: could not initialize proxy - no Session
```

- **`grep -m 1`** corta en la primera coincidencia: lo que importa es el mensaje, no los frames.
  Debajo de esa línea vienen los de
  `AbstractPersistentCollection.throwLazyInitializationException` →
  `withTemporarySessionIfNeeded` → `initialize`, y después medio centenar de frames de reflexión
  de Jackson y de MVC. Podar frames está bien; editar el mensaje o el nombre de la excepción,
  nunca.
- **`- no Session`** son las dos palabras que importan. No dice "no hay conexión" ni "error de
  base de datos": dice que el objeto que tienes en la mano sabe cómo pedir lo que le falta y ya
  no tiene a quién pedírselo, porque el `EntityManager` que lo creó se cerró con la transacción.
- **`of role: com.invlab.invapi.inventory.InventoryItem.events`** nombra la asociación exacta que
  se tocó tarde. Con eso y el `X-Request-Id` de la respuesta tienes el caso reproducible
  completo, que es la mitad del trabajo de diagnóstico.
- **Hay un segundo mensaje para el mismo fallo**, y conviene reconocer los dos: cuando lo que se
  toca tarde no es una colección sino el proxy de un `@ManyToOne` `LAZY`, Hibernate dice
  `could not initialize proxy [com.invlab.invapi.inventory.InventoryItem#3] - no Session`, con el
  id de la entidad entre corchetes. Es el de
  [`15` §7](15-datos-jdbc-jpa-mongo-y-redis.md#7-️-lazyinitializationexception-y-open-in-view).

Ahora la parte incómoda: **el "arreglo" que encuentra todo el mundo en internet funciona**.
Ponlo y míralo funcionar, porque el objetivo es que sepas por qué no lo vas a usar.

```yaml
spring:
  jpa:
    open-in-view: true        # el default de Boot; aquí para verlo y descartarlo
```

```text
2026-09-18T10:52:19.883-05:00  WARN 42501 --- [           main] JpaBaseConfiguration$JpaWebConfiguration : spring.jpa.open-in-view is enabled by default. Therefore, database queries may be performed during view rendering. Explicitly configure spring.jpa.open-in-view to disable this warning
```

```text
HTTP/1.1 200
{"id":3,"sku":"SKU-000001","name":"Item 1","quantity":97,"events":[{"id":4,"delta":-1,"reason":"consumo","occurredAt":"2026-09-18T15:04:11.210Z"}, ...]}
```

- **Boot avisa en el arranque desde 2.0** y casi nadie lee ese `WARN`. Fíjate en lo que dice:
  *"database queries may be performed during view rendering"* — no es una advertencia de estilo,
  es la descripción exacta del problema.
- **`OpenEntityManagerInViewInterceptor` mantiene la sesión abierta durante todo el request**,
  así que la colección se carga cuando Jackson la toca. El endpoint pasó a `200` sin tocar una
  línea de código.
- **Y mira lo que acabas de publicar:** el `id` interno y la lista entera de eventos, que nadie
  pidió. El endpoint "de depuración" es ahora una fuga de modelo interno con formato JSON.

> **⏱️ Costo en runtime de `open-in-view: true`.** La sesión abierta implica **la conexión del
> pool retenida hasta el último byte de la respuesta**, no hasta el commit. Un cliente lento o
> una respuesta de 2 MB ocupan una de tus diez conexiones todo ese tiempo, y el pool se agota con
> una carga que la base ni siente. Y hay algo peor que el costo: las consultas que dispara la
> serialización corren **fuera de transacción**, cada una en su autocommit, así que el endpoint
> puede devolver un estado que nunca existió a la vez en la base.

> Nunca respondas: ~~"`open-in-view` evita el `LazyInitializationException`"~~
>
> Mejor: "lo evita escondiéndolo, y a cambio ata la conexión del pool a la velocidad del cliente
> y deja que la serialización dispare consultas fuera de transacción. Yo lo apago, y lo que se
> rompe me dice dónde faltaba decidir qué traer."

Vuelve a `false` y arréglalo de verdad: **decide en el servicio qué necesita la respuesta**.

```java
// en InventoryService
@Transactional(readOnly = true)
ItemDetail detail(String sku) {
    InventoryItem item = repository.findWithEventsBySku(sku)
            .orElseThrow(() -> new ItemNotFoundException(sku));
    // el mapeo ocurre DENTRO de la transacción: aquí la colección sí está cargada
    List<EventResponse> events = item.events().stream()
            .map(e -> new EventResponse(e.delta(), e.reason(), e.occurredAt()))
            .toList();
    return new ItemDetail(item.sku(), item.name(), item.quantity(), events);
}

record ItemDetail(String sku, String name, int quantity, List<EventResponse> events) { }
record EventResponse(int delta, String reason, Instant occurredAt) { }
```

```java
// en InventoryItemRepository
@EntityGraph(attributePaths = "events")
Optional<InventoryItem> findWithEventsBySku(String sku);
```

- **El mapeo a DTO ocurre dentro del método transaccional**, que es la regla entera en una
  frase: *la entidad no sale del servicio*. Lo que sale es un `record` inmutable que Jackson
  serializa sin tocar la base.
- **`findWithEventsBySku` es una derived query con grafo, y el orden de las palabras no es
  decorativo**: Spring Data corta el nombre en el **primer `By`** y solo parsea lo que viene
  **después** como propiedades (`Sku`); lo que va entre el verbo y ese `By` —aquí `WithEvents`—
  se ignora y sirve para darle nombre al método. Escrito al revés, `findBySkuWithEvents`, el
  parser leería `SkuWithEvents` como una propiedad y el contexto no levantaría:
  `PropertyReferenceException`. El `@EntityGraph` hace el trabajo de traer la colección: una
  consulta, sin N+1 y sin lazy loading.
- **`ItemDetail` no expone el `id`**, y esa es la otra mitad del arreglo: el DTO decide el
  contrato, no el mapeo.
- **Borra el endpoint `/raw`.** Cumplió su función pedagógica y dejarlo es dejar una fuga.

> **🧠 Modelo mental.** `LazyInitializationException` no es un problema de Hibernate: es
> Hibernate avisándote de que **tu límite transaccional está mal puesto**. Apagar
> `open-in-view` no crea el bug, lo adelanta del entorno de producción al test de integración,
> que es exactamente donde lo quieres.

---

## 6. 🩺 El gran experimento: el rollback que no ocurre

Aquí está el lab. Si mañana solo te acuerdas de una sección, que sea esta.

El caso de negocio es el de siempre: registrar un movimiento son **dos escrituras** —insertar
una fila en `inventory_event` y actualizar la cantidad en `inventory_item`— y una regla: si la
cantidad queda negativa, **no se guarda nada**. En `L03` esa regla lanzaba
`InsufficientStockException`, que es una `RuntimeException`, que es exactamente la familia que
dispara rollback por defecto.

Así que escribimos lo evidente:

```java
// en InventoryService
@Transactional
InventoryItem record(String sku, int delta, String reason) {
    InventoryItem item = repository.findWithEventsBySku(sku)
            .orElseThrow(() -> new ItemNotFoundException(sku));
    item.addEvent(new InventoryEvent(delta, reason));   // INSERT en inventory_event
    item.applyDelta(delta);                             // UPDATE de inventory_item
    InventoryItem saved = repository.save(item);        // las dos escrituras salen aquí
    if (saved.quantity() < 0) {
        throw new InsufficientStockException(sku, saved.quantity() - delta, delta);
    }
    return saved;
}
```

- **El orden es deliberado y es realista:** primero se escribe, después se valida. Nadie diseña
  así a propósito, pero es lo que queda cuando la validación se añade seis meses después del
  método. Toda la sección depende de ese orden: si la regla se comprobara antes del `save()`,
  no habría nada que revertir y no habría nada que enseñar.
- **La consulta es `findWithEventsBySku`**, la de la sección 5, y aquí el `@EntityGraph` no está
  por rendimiento: **es lo que hace que el método sobreviva a no tener transacción**. Sin
  transacción de negocio, `findWithEventsBySku` abre y cierra la suya y la entidad vuelve
  *detached*; con `open-in-view: false` (sección 5), `addEvent` tocando una colección `LAZY`
  detached lanzaría el `LazyInitializationException` de la sección anterior en vez del silencio
  que queremos ver. Con la colección ya resuelta, `addEvent` trabaja en memoria.
- **`save()` está ahí a propósito y no sobra.** Dentro de una transacción de negocio sería
  redundante —la entidad está *managed* y el dirty checking emitiría el `UPDATE` igual, más la
  cascada del `@OneToMany`—, pero es lo que hace que el método **siga escribiendo cuando esa
  transacción no existe**, que es justo lo que vamos a provocar: sobre una entidad *detached*,
  `save()` es un `merge()` que emite el `UPDATE` y arrastra el evento nuevo por la cascada. Y
  devuelve la **copia gestionada**, no la instancia que le pasaste
  ([`15` §5](15-datos-jdbc-jpa-mongo-y-redis.md#5--el-persistence-context-de-donde-salen-las-sorpresas)):
  por eso la regla se comprueba sobre `saved` y no sobre `item`.
- **`InsufficientStockException extends RuntimeException`** desde `L03`. Es *unchecked*, así que
  **la regla por defecto de Spring es hacer rollback**. Sobre el papel, este método es correcto.

Y ahora las tres formas de que ese método correcto no haga absolutamente nada. Las tres compilan,
ninguna avisa, y las tres se demuestran con el mismo `SELECT`.

### El método que las tres comparten

```bash
docker exec -i inv-lab-postgres-1 psql -U inv_lab -d inv_lab -c \
  "SELECT (SELECT count(*) FROM inventory_event) AS eventos,
          (SELECT quantity FROM inventory_item WHERE sku = 'SKU-000001') AS cantidad"
```

```text
 eventos | cantidad
---------+----------
      60 |       97
(1 row)
```

- **Esta es la foto de antes**, y se toma antes de cada variante. Sesenta eventos y el item
  `SKU-000001` con 97 unidades.
- **Las dos subconsultas en un solo `SELECT`** te dan las dos mitades de la atomicidad de un
  vistazo: si después del fallo cambia una sola de las dos columnas, ya sabes que la transacción
  no era tal.

### Variante A — self-invocation

Negocio pide registrar varios movimientos de una vez. Alguien añade el bucle en la misma clase:

```java
// en InventoryService — el método que llama el controller
List<InventoryItem> recordBatch(String sku, List<EventRequest> requests) {
    List<InventoryItem> result = new ArrayList<>();
    for (EventRequest request : requests) {
        // llamada interna: this.record(...), aunque el 'this' no se escriba
        result.add(record(sku, request.delta(), request.reason()));
    }
    return result;
}
```

- **`recordBatch` no está anotado** —se anotó `record`, que es donde "está la transacción"— y
  llama a `record()` **sobre `this`**, no sobre el proxy.
- **Es el fallo silencioso número uno del curso** y la causa raíz está en
  [`05` §5](05-proxies-y-aop.md#5-️-self-invocation-el-fallo-silencioso-número-uno): el proxy
  envuelve al bean **por fuera**, así que solo intercepta las llamadas que entran desde fuera.
  Una llamada interna va directa al objeto y la anotación no la ve nadie.

**Predice:** mandas dos movimientos, el segundo deja el stock en negativo. ¿Qué queda en la base?

```bash
curl -s -o /dev/null -w '%{http_code}\n' -X POST localhost:8080/api/items/SKU-000001/events/batch \
  -H 'Content-Type: application/json' \
  -d '[{"delta":-5,"reason":"consumo"},{"delta":-200,"reason":"consumo"}]'
docker exec -i inv-lab-postgres-1 psql -U inv_lab -d inv_lab -c \
  "SELECT (SELECT count(*) FROM inventory_event) AS eventos,
          (SELECT quantity FROM inventory_item WHERE sku = 'SKU-000001') AS cantidad"
```

```text
422
 eventos | cantidad
---------+----------
      62 |       -108
(1 row)
```

- **Sesenta y dos eventos, no sesenta.** Se grabaron **los dos**: el legítimo y el que disparó
  la excepción. Y la cantidad quedó en `-108`, que es precisamente el estado que la regla de
  negocio existía para impedir.
- **El cliente recibió un `422` impecable**, con su `ProblemDetail` y sus campos `available` y
  `requested`. La API dijo "no se guardó" y la base dice otra cosa. **Nadie va a descubrir esto
  hasta el cierre contable.**
- **¿Por qué se grabó, si no había transacción?** Porque `SimpleJpaRepository` —la
  implementación que Spring Data genera para tu repositorio— **está anotada con `@Transactional`
  en sus métodos**. Sin transacción de fuera, cada `findWithEventsBySku()` y cada `save()` abre y
  confirma la suya. El resultado es lo peor de los dos mundos: **cada escritura es atómica por
  separado y ninguna lo es en conjunto.** Esta es la frase que separa una respuesta de entrevista
  buena de una excelente.

El diagnóstico, sin abrir el debugger:

```yaml
logging:
  level:
    org.springframework.transaction.interceptor: TRACE
```

```bash
kill %1
./mvnw -q clean package -DskipTests && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
: > app.log
curl -s -o /dev/null -X POST localhost:8080/api/items/SKU-000002/events/batch \
  -H 'Content-Type: application/json' -d '[{"delta":-500,"reason":"consumo"}]'
grep 'TransactionInterceptor' app.log | sed 's/.*: //'
```

```text
Getting transaction for [org.springframework.data.jpa.repository.support.SimpleJpaRepository.findWithEventsBySku]
Completing transaction for [org.springframework.data.jpa.repository.support.SimpleJpaRepository.findWithEventsBySku]
Getting transaction for [org.springframework.data.jpa.repository.support.SimpleJpaRepository.save]
Completing transaction for [org.springframework.data.jpa.repository.support.SimpleJpaRepository.save]
```

- **El log no está vacío, y ahí está la trampa.** Quien busca "¿corrió el interceptor?" ve
  líneas y respira tranquilo. La pregunta correcta no es *si* corrió, es **sobre qué clase**.
- **No aparece ni una sola línea con `InventoryService.record`.** Eso es la prueba: el
  interceptor nunca envolvió tu método, porque la llamada nunca pasó por el proxy.
- **`Getting transaction for` y `Completing transaction for`** son los dos mensajes que hay que
  reconocer. El primero se imprime antes de tu método, el segundo después. Si tu método está
  entre los dos, hubo transacción; si no aparece, no la hubo.
- **`sed 's/.*: //'`** recorta el prefijo de timestamp, nivel e hilo para que la línea quepa. El
  log completo sigue en `app.log`.

**La corrección.** Hay tres caminos y solo uno es bueno:

```java
// ❌ el parche que circula: auto-inyección. Funciona, y esconde el problema.
private final ObjectProvider<InventoryService> self;
...
self.getObject().record(sku, request.delta(), request.reason());

// ✅ lo correcto aquí: la transacción va donde está el límite de la unidad de trabajo
@Transactional
List<InventoryItem> recordBatch(String sku, List<EventRequest> requests) { ... }
```

- **La auto-inyección con `ObjectProvider`** rompe el ciclo de dependencias que daría una
  inyección directa por constructor, y hace que la llamada pase por el proxy. Funciona. Y deja
  en el código una línea que nadie entiende en seis meses, así que se usa cuando de verdad no
  puedes mover el límite.
- **Mover `@Transactional` a `recordBatch` es la respuesta de diseño**, porque ahí **está** el
  límite de la unidad de trabajo: o entran los cinco movimientos o no entra ninguno. Que el
  método interno la tenga también da igual: con `REQUIRED` se une a la de fuera.
- **La tercera vía, extraer `record` a otro bean**, es la que se elige cuando el método interno
  debe poder llamarse por separado desde varios sitios. Dos beans, una llamada entre ellos, un
  proxy en medio.

> **⚠️ Y si de verdad querías una transacción por movimiento**, `@Transactional` en el bucle **no
> es la forma**: con `REQUIRED` todas se unen a la de fuera y un fallo tumba el lote entero. Eso
> es `TransactionTemplate` ([`16` §3](16-transacciones.md#3--declarativo-y-programático)) o
> `REQUIRES_NEW` con el precio que se paga en la sección 7.

Verifica que la corrección funciona, que es la mitad del ejercicio que casi nadie hace:

```bash
docker exec -i inv-lab-postgres-1 psql -U inv_lab -d inv_lab -c \
  "SELECT count(*) AS antes FROM inventory_event"
curl -s -o /dev/null -w '%{http_code}\n' -X POST localhost:8080/api/items/SKU-000003/events/batch \
  -H 'Content-Type: application/json' \
  -d '[{"delta":-5,"reason":"consumo"},{"delta":-200,"reason":"consumo"}]'
docker exec -i inv-lab-postgres-1 psql -U inv_lab -d inv_lab -c \
  "SELECT count(*) AS despues FROM inventory_event"
```

```text
 antes
-------
    63
(1 row)
422
 despues
---------
      63
(1 row)
```

- **El mismo número antes y después.** Eso es un rollback, y es la única prueba que vale.
- **El `422` no cambió**, y es importante: el contrato HTTP era correcto desde el principio. Lo
  que estaba roto era invisible desde fuera.

### Variante B — la excepción capturada

Segunda forma, y la más frecuente en código real. Alguien no quiere que "truene" el log:

```java
@Transactional
List<InventoryItem> recordBatchQuiet(String sku, List<EventRequest> requests) {
    List<InventoryItem> result = new ArrayList<>();
    for (EventRequest request : requests) {
        try {
            result.add(recorder.record(sku, request.delta(), request.reason()));
        } catch (InsufficientStockException e) {
            // "para que no se caiga el lote entero por uno malo"
            log.warn("movimiento rechazado para {}: {}", sku, e.getMessage());
        }
    }
    return result;
}
```

- **Ahora sí hay proxy**: `recorder` es otro bean y la llamada sale de esta clase. El
  interceptor corre. El log lo confirma.
- **Y aun así no hay rollback**, porque el `catch` se come la excepción **antes** de que llegue
  al proxy de `recordBatchQuiet`. Para el interceptor de fuera, el método terminó
  perfectamente. **Commit.**
- **La intención era buena**, y ese es el problema: "que un movimiento malo no tumbe el lote" es
  un requisito legítimo. Lo que está mal es la implementación, no el deseo.

```bash
docker exec -i inv-lab-postgres-1 psql -U inv_lab -d inv_lab -c \
  "SELECT count(*) AS eventos FROM inventory_event"
curl -s -o /dev/null -w '%{http_code}\n' -X POST localhost:8080/api/items/SKU-000004/events/batch-quiet \
  -H 'Content-Type: application/json' \
  -d '[{"delta":-5,"reason":"consumo"},{"delta":-200,"reason":"consumo"}]'
docker exec -i inv-lab-postgres-1 psql -U inv_lab -d inv_lab -c \
  "SELECT count(*) AS eventos FROM inventory_event,
   (SELECT quantity FROM inventory_item WHERE sku = 'SKU-000004') q"
```

```text
 eventos
---------
      63
(1 row)
200
 eventos
---------
      65
(1 row)
```

- **Un `200` limpio y dos filas nuevas**, incluida la del movimiento que la regla rechazó. El
  segundo evento se grabó con su `delta` de `-200` y el item quedó negativo.
- **La respuesta ni siquiera fue un `422`**: como nadie lanzó nada hacia arriba, MVC devolvió la
  lista de resultados parciales. El cliente cree que todo salió bien.
- **En el log hay un `WARN`** que dice exactamente lo que pasó. Nadie lee los `WARN`.

**Y la versión cruel**, que es la que de verdad aparece en producción. Si el método interno
hubiera marcado la transacción como condenada —porque tenía su propia `@Transactional` con
`REQUIRED` y la excepción llegó a **su** proxy antes de que tú la capturaras— el commit final
falla:

```text
org.springframework.transaction.UnexpectedRollbackException: Transaction silently rolled back because it has been marked as rollback-only
	at org.springframework.transaction.support.AbstractPlatformTransactionManager.processRollback(AbstractPlatformTransactionManager.java:873)
```

- **Lo desconcertante es dónde aparece**: en el método de fuera, que no falló, al hacer commit.
  El culpable ya terminó hace rato.
- **Quién lo marcó:** el proxy del método interno, al ver la excepción, marcó el
  `TransactionStatus` compartido como `rollback-only`. Tu `catch` evitó que la excepción subiera,
  pero no borró la marca.
- **Y es una buena noticia**, aunque no lo parezca: es el único de los tres silencios que **sí
  avisa**. Prefiere esto mil veces al `200` silencioso de arriba.

**Las dos correcciones**, según lo que de verdad quieras:

```java
// ✅ si el lote es atómico: no captures, o vuelve a lanzar
catch (InsufficientStockException e) {
    log.warn("movimiento rechazado para {}", sku);
    throw e;
}

// ✅ si quieres decidir sin usar una excepción como control de flujo
catch (InsufficientStockException e) {
    TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
}
```

- **`throw e` es la respuesta por defecto** y la que hay que dar en una entrevista: capturar y
  registrar no es manejar.
- **`setRollbackOnly()`** condena la transacción sin lanzar nada. Es lo que usas cuando el flujo
  tiene que seguir para construir una respuesta de negocio, y lanza `NoTransactionException` si
  lo llamas fuera de una transacción, que es una comprobación gratis.
- **Y si de verdad el lote no es atómico**, ninguna de las dos es la respuesta: es
  `REQUIRES_NEW` o `TransactionTemplate` por elemento, decidido a propósito y no por accidente.

### Variante C — el método `private`

Tercera forma, la más corta de explicar y la que más gente sigue diciendo mal en entrevistas:

```java
@Service
class InventoryService {

    @Transactional
    private InventoryItem recordInternal(String sku, int delta, String reason) {   // ❌ nunca corre
        ...
    }

    InventoryItem record(String sku, int delta, String reason) {
        return recordInternal(sku, delta, reason);
    }
}
```

- **Un proxy no puede interceptar un método `private`.** Ni CGLIB, que crea una subclase y no
  puede sobrescribir lo privado, ni un proxy JDK, que implementa la interfaz y ni siquiera lo ve.
- **No hay error de compilación, ni de arranque, ni un `WARN`.** La anotación queda ahí como
  documentación de una intención que no se cumple. El `SELECT` da el mismo resultado que la
  variante A: **las filas quedan grabadas**.
- **La corrección es de una palabra:** quita el `private`.

> **📝 La sobregeneralización de esta sección, y la versión precisa.** La respuesta clásica que
> vas a encontrar en cualquier blog de 2019 es *"`@Transactional` solo funciona en métodos
> `public`"*. Desde Spring Framework 6.0 **eso ya no es exacto**: con proxies **CGLIB** —que es
> el default de Boot desde 2.0— la anotación también se respeta en métodos `protected` y
> package-private, porque la subclase puede sobrescribirlos. Lo que **nunca** funciona es
> `private`, y lo que nunca funciona con proxies JDK es cualquier cosa que no esté en la
> interfaz. La respuesta que gana en una entrevista es: *"no es cuestión de `public`, es cuestión
> de si el proxy puede sobrescribir el método y de si la llamada entra desde fuera del bean"*.

### El resumen de los tres silencios

```text
variante A (self-invocation)  → el interceptor NO corre  → el log no nombra tu método
variante B (catch interno)    → el interceptor SÍ corre  → el log lo nombra, y hace commit
variante C (método private)   → el interceptor NO corre  → el log no nombra tu método
```

| Variante | ¿Corre el interceptor? | ¿Qué devuelve la API? | ¿Qué dice el `SELECT`? |
|---|---|---|---|
| A — self-invocation | ❌ | `422` correcto | filas grabadas |
| B — excepción capturada | ✅ | `200` engañoso | filas grabadas |
| C — método `private` | ❌ | `422` correcto | filas grabadas |

- **En las tres el `SELECT` dice lo mismo**, y esa es la conclusión del lab: el código de estado
  y el log de la aplicación **no son evidencia** sobre lo que pasó en la base.
- **La variante B es la más peligrosa** precisamente porque el diagnóstico rápido —"¿corrió el
  interceptor?"— sale en verde.
- **Los otros tres silencios de [`16` §7](16-transacciones.md#7--los-seis-silencios)** —método
  `final`, llamada desde `@PostConstruct`, import de `jakarta.transaction`— no se reproducen
  aquí porque los tres son variaciones del mismo mecanismo; dos de ellos son ejercicios.

> **🧠 La frase que hay que poder decir en voz alta.** `@Transactional` no abre una transacción:
> le pide a un proxy que le pida al `TransactionManager` que abra una. **Si no hay proxy en medio,
> o si el proxy no ve la excepción, la anotación es un comentario.**

---

## 7. ⏱️ `REQUIRES_NEW` y el deadlock de pool

Último fallo, y el que más caro sale: no rompe una petición, **rompe el servicio entero**,
mientras la base de datos está sin hacer nada.

El escenario es el más razonable de todo el lab. Auditoría pide que cada intento de movimiento
quede registrado **aunque el movimiento falle**. Y para eso existe `REQUIRES_NEW`:

```java
@Service
class AuditService {

    private final JdbcClient jdbc;

    AuditService(JdbcClient jdbc) { this.jdbc = jdbc; }

    // suspende la transacción del llamador y abre otra, con OTRA conexión
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    void recordAttempt(String sku, int delta) {
        jdbc.sql("INSERT INTO inventory_event (item_id, delta, reason) "
               + "SELECT id, :delta, 'intento' FROM inventory_item WHERE sku = :sku")
            .param("delta", delta)
            .param("sku", sku)
            .update();
    }
}
```

- **`REQUIRES_NEW` hace exactamente lo que promete:** suspende la transacción de fuera y abre
  una nueva e independiente. Si la de fuera hace rollback, esta ya confirmó y el registro de
  auditoría sobrevive. El diseño es correcto.
- **Y aquí está el precio que casi nadie menciona: suspender no libera la conexión.** La
  transacción externa **retiene la suya** mientras la interna corre con **otra**. Este método
  consume **dos conexiones del pool a la vez**.
- **`INSERT ... SELECT`** evita una consulta previa para resolver el id. No es el punto de la
  sección, pero es la forma correcta de escribirlo.
- **`AuditService` es otro bean**, así que el proxy sí interviene. Si fuera un método de
  `InventoryService`, estaríamos en la variante A de la sección anterior y `REQUIRES_NEW` no
  haría nada — dos bugs distintos con el mismo síntoma invisible.

Llámalo desde dentro de la transacción de negocio:

```java
// en InventoryService.record(...), como primera línea
audit.recordAttempt(sku, delta);
```

Con un pool de 10 esto funciona en tu máquina y se rompe en producción un martes por la tarde.
Para que se rompa **hoy y en segundos**, baja el pool a dos:

```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: 2         # provocado: el default es 10
      connection-timeout: 3000
```

- **Bajar el pool no crea el bug: lo acelera.** La aritmética es la misma con 2 conexiones y 3
  peticiones que con 10 y 6; lo único que cambia es cuánta carga hace falta para llegar ahí.
  **Una variable a la vez**: no cambiamos el código, solo el tamaño del pool.
- **`connection-timeout: 3000`** es lo que hace que el fallo sea observable en tres segundos en
  vez de en treinta.

> **⏱️ La aritmética del deadlock, que es lo que se dice en una entrevista.** Con
> `maximum-pool-size = N`, un método que necesita **dos** conexiones simultáneas se bloquea en
> cuanto hay **N peticiones concurrentes** por ese camino: las N toman su primera conexión, y
> ninguna consigue la segunda porque las N están repartidas. Nadie puede avanzar y nadie puede
> soltar. Con N = 2 bastan dos peticiones a la vez. **La regla:
> `pool ≥ concurrencia × conexiones por request`.**

**Predice:** ocho peticiones en paralelo con un pool de dos. ¿Cuántas responden, cuántas fallan,
y qué está haciendo Postgres mientras tanto?

```bash
kill %1
./mvnw -q clean package -DskipTests && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
: > app.log
for i in $(seq 1 8); do
  curl -s -o /dev/null -w '%{http_code} ' -X POST localhost:8080/api/items/SKU-000005/events \
    -H 'Content-Type: application/json' -d '{"delta":-1,"reason":"consumo"}' &
done
wait; echo
```

```text
500 500 500 500 500 200 500 200
```

- **El `&` al final del `curl` lanza cada petición como un proceso aparte**, y `wait` espera a
  los ocho. Sin el `&` las peticiones serían secuenciales y **no habría deadlock**: el bug
  necesita concurrencia y por eso no aparece en tus pruebas manuales.
- **Dos respondieron y seis murieron.** Las dos afortunadas pillaron las dos conexiones en un
  momento en que nadie más las quería; el resto se quedó esperando la segunda.
- **Repite el comando y el reparto cambia.** Eso también es un dato: un fallo que depende del
  entrelazado de hilos no se reproduce igual dos veces, y por eso se diagnostica con métricas y
  no con intuición.

La excepción, literal y completa hasta la causa:

```bash
grep -B 2 -A 6 'Connection is not available' app.log | head -14
```

```text
org.springframework.transaction.CannotCreateTransactionException: Could not open JPA EntityManager for transaction
	at org.springframework.orm.jpa.JpaTransactionManager.doBegin(JpaTransactionManager.java:466)
	...
Caused by: org.hibernate.exception.JDBCConnectionException: Unable to acquire JDBC Connection [HikariPool-1 - Connection is not available, request timed out after 3001ms.]
	...
Caused by: java.sql.SQLTransientConnectionException: HikariPool-1 - Connection is not available, request timed out after 3001ms.
	at com.zaxxer.hikari.pool.HikariPool.createTimeoutException(HikariPool.java:696)
	at com.zaxxer.hikari.pool.HikariPool.getConnection(HikariPool.java:197)
	at com.zaxxer.hikari.pool.HikariPool.getConnection(HikariPool.java:162)
	... 118 more
```

- **`SQLTransientConnectionException: HikariPool-1 - Connection is not available, request timed
  out after 3001ms.`** es la línea que hay que reconocer de memoria. Aparece en el 90 % de las
  caídas de servicios Spring en banca y casi nunca significa lo que la gente cree que significa.
- **`Transient` es una promesa que aquí es mentira.** El nombre dice "vuelve a intentarlo, esto
  pasa"; en un deadlock de pool reintentar consume otra conexión y empeora el problema.
- **Fíjate en lo que NO hay en el stack trace: una sola línea de tu código.** Todo son frames de
  Hikari, Hibernate y Spring. Por eso la primera reacción de todo el mundo es "el pool es
  pequeño", que es exactamente la conclusión equivocada.
- **`CannotCreateTransactionException` es la de arriba**, y también informa: el fallo ocurrió al
  **abrir** la transacción, no ejecutando una consulta. Es decir, el problema es de acceso al
  recurso, no de SQL.

Y ahora la evidencia que cambia el diagnóstico. Mientras el servicio se muere, pregúntale a
Postgres qué está haciendo:

```bash
docker exec -i inv-lab-postgres-1 psql -U inv_lab -d inv_lab -c \
  "SELECT state, count(*), max(now() - state_change) AS mas_antigua
   FROM pg_stat_activity WHERE datname = 'inv_lab' GROUP BY state"
```

```text
        state        | count |   mas_antigua
---------------------+-------+-----------------
 idle in transaction |     2 | 00:00:02.914
(1 row)
```

- **Dos conexiones, las dos ociosas.** `idle in transaction` significa: hay una transacción
  abierta y **la base no está ejecutando nada**, está esperando a que el cliente le mande la
  siguiente sentencia o el commit.
- **Ese cliente es un hilo de Tomcat que está bloqueado esperando una segunda conexión que
  nunca va a llegar.** Toda la cadena está parada por sí misma. Eso es un deadlock, y no
  interviene ni un solo `LOCK` de base de datos.
- **Cero consultas en ejecución, cero espera de disco, CPU de Postgres al 0 %.** Si tu única
  gráfica es la de la base, el incidente es invisible: la base está perfecta. **El recurso
  agotado es tuyo, no suyo.**
- **`max(now() - state_change)`** te dice cuánto llevan así. Casi tres segundos, que es el
  `connection-timeout`: las conexiones se sueltan justo cuando los que esperaban se rinden.

La segunda evidencia, desde el lado de Hikari:

```yaml
logging:
  level:
    com.zaxxer.hikari.pool.HikariPool: DEBUG
```

```text
2026-09-18T11:24:03.117-05:00 DEBUG 42610 --- [l-1 housekeeper] com.zaxxer.hikari.pool.HikariPool : HikariPool-1 - Pool stats (total=2, active=2, idle=0, waiting=6)
```

- **`waiting=6`** es el número que cierra el caso: seis hilos en la cola por una conexión.
  Con `active=2` e `idle=0`, el pool está lleno y nadie suelta.
- **`[l-1 housekeeper]`** es el hilo interno de Hikari que imprime estas estadísticas cada 30
  segundos. En producción esta línea es oro y casi nadie la tiene activada.
- **Lo mismo está en Actuator**, y es lo que se pone en un dashboard:
  `/actuator/metrics/hikaricp.connections.pending` y `hikaricp.connections.usage`. El segundo es
  **el tiempo de retención**, que es la variable que de verdad predice este incidente
  ([`L07` §8](l07-actuator-metricas-y-trazas.md#8--grafana-y-el-tablero-de-las-cuatro-señales)).

> Nunca respondas: ~~"`Connection is not available` significa que el pool es pequeño"~~
>
> Mejor: "significa que alguien retiene conexiones más tiempo del que el pool puede sostener.
> Primero miro **cuántas conexiones necesita un solo request** —un `REQUIRES_NEW` anidado
> necesita dos— y **cuánto las retiene**. Subir el pool sin contestar eso solo mueve la cola de
> mi aplicación a la base."

**La corrección**, en tres niveles y en este orden:

```java
// ✅ primera opción: la auditoría no necesita otra transacción si no tiene que sobrevivir al fallo
@Transactional                              // REQUIRED: se une, una sola conexión
void recordAttempt(String sku, int delta) { ... }

// ✅ si de verdad debe sobrevivir al rollback: audita FUERA del límite transaccional,
//    en el método que orquesta y que NO está anotado
void handle(String sku, int delta, String reason) {
    audit.recordAttempt(sku, delta);        // abre, confirma y SUELTA su conexión
    inventory.record(sku, delta, reason);   // y solo entonces se abre la de negocio
}
```

- **Primera pregunta, siempre: ¿de verdad tiene que sobrevivir al rollback?** En la mitad de los
  casos "auditar el intento" se resuelve con un log estructurado y no con una fila en la misma
  base que estamos intentando no escribir. Si la respuesta es no, `REQUIRED` y el problema
  desaparece.
- **Si tiene que sobrevivir, el arreglo es secuencial, no anidado.** Las dos transacciones siguen
  existiendo, pero **una después de la otra**: la de auditoría confirma y devuelve su conexión al
  pool antes de que la de negocio pida la suya. Una conexión a la vez por petición, y la regla
  `pool ≥ concurrencia × conexiones por request` vuelve a `× 1`. El precio es que auditas el
  intento antes de saber si el item existe, que para una auditoría de *intentos* es exactamente
  lo que se quería.
- **Tercer nivel, y solo si los dos anteriores no aplican: dimensiona el pool.** `pool ≥
  concurrencia × 2`. Y déjalo escrito en un comentario al lado de la propiedad, porque el próximo
  que lo baje "para no saturar la base" va a reproducir este incidente.

> **⚠️ El arreglo que parece obvio y no arregla el pool.** La respuesta que circula es mover la
> auditoría a un `@TransactionalEventListener(AFTER_COMMIT)` o `(AFTER_COMPLETION)` con
> `REQUIRES_NEW`. Eso **corrige la semántica** —el efecto ocurre cuando debe— y **no corrige el
> consumo de pool**: `AbstractPlatformTransactionManager.processCommit` dispara el listener en
> `triggerAfterCompletion` y solo suelta la conexión de la transacción original en
> `cleanupAfterCompletion`, que corre **después**, en el `finally`. El javadoc de
> `TransactionSynchronization.afterCompletion` lo dice sin rodeos: *"the transactional resources
> might still be active and accessible… Use `PROPAGATION_REQUIRES_NEW` for any transactional
> operation that is called from here"*. Durante el listener sigues reteniendo la primera conexión
> y el `REQUIRES_NEW` pide la segunda: mismas dos conexiones simultáneas, mismo deadlock. Lo que
> sí rompe la cadena es sacar el efecto **del hilo**: un listener `@Async`
> ([`18` §5](18-asincronia-scheduling-y-eventos.md#5--propagación-de-contexto-lo-que-se-queda-en-el-hilo-del-request)),
> donde el hilo del request ya no espera nada mientras retiene su conexión, o un **outbox**, que
> escribe el aviso en la misma transacción y lo publica aparte
> ([`16` §8](16-transacciones.md#8--el-límite-de-la-transacción-no-es-el-límite-de-tu-método)).

Restaura el pool y comprueba que las ocho peticiones vuelven a pasar:

```bash
# devuelve maximum-pool-size a 10 en application.yml y reconstruye
kill %1
./mvnw -q clean package -DskipTests && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
for i in $(seq 1 8); do
  curl -s -o /dev/null -w '%{http_code} ' -X POST localhost:8080/api/items/SKU-000006/events \
    -H 'Content-Type: application/json' -d '{"delta":-1,"reason":"consumo"}' &
done
wait; echo
grep -c 'Connection is not available' app.log
```

```text
200 200 200 200 200 200 200 200
0
```

- **Ocho de ocho y cero excepciones.** Ojo con la lectura: esto **no demuestra que el bug esté
  arreglado**, demuestra que con este pool y esta concurrencia no se manifiesta. El bug de
  diseño —dos conexiones por request— sigue ahí hasta que apliques una de las dos primeras
  correcciones.
- **Esa distinción es la respuesta de Tech Lead**: distinguir el parche que desbloquea hoy
  (subir el pool) de la solución que uno haría con calma (no anidar transacciones).
- **La prevención** es un test de carga mínimo —el ejercicio 15— o, más barato, una regla de
  revisión: *ningún `REQUIRES_NEW` entra sin que su autor diga cuántas conexiones consume el
  request completo*.

---

## 8. 📋 Checklist de salida

- [ ] `docker compose -p inv-lab ps` lista `inv-lab-postgres-1` en estado `(healthy)`.
- [ ] `docker exec -i inv-lab-postgres-1 psql -U inv_lab -d inv_lab -c '\dt'` lista `flyway_schema_history`, `inventory_item` e `inventory_event`.
- [ ] El log de arranque dice `Successfully applied 1 migration to schema "public"` y no vuelve a decirlo en el segundo arranque.
- [ ] No queda ni una referencia a `InventoryStore` en el proyecto: `grep -r InventoryStore src/` no devuelve nada.
- [ ] `./mvnw -q clean package` pasa en verde con los tests de `MockMvc` de `L03` intactos.
- [ ] Un `POST /api/items` devuelve `201` y la fila aparece en un `SELECT` hecho desde `psql`.
- [ ] Un reinicio del proceso **no** borra los datos, y un `docker compose -p inv-lab down -v` sí.
- [ ] `GET /api/items?limit=20` emite **una** sentencia SQL: `grep -c 'org.hibernate.SQL' app.log` devuelve `1`.
- [ ] `spring.jpa.show-sql` **no** está en `application.yml`, y `org.hibernate.SQL` sí está en `DEBUG`.
- [ ] `spring.jpa.open-in-view` está explícitamente en `false` y el endpoint `/raw` ya no existe.
- [ ] `GET /api/items/{sku}` devuelve un DTO con sus eventos y ninguna respuesta expone el `id` de la entidad.
- [ ] Con `@Transactional` mal puesto, el `SELECT` posterior a un `422` muestra las filas grabadas; con la corrección, el conteo antes y después es idéntico.
- [ ] El log con `org.springframework.transaction.interceptor` en `TRACE` nombra `InventoryService.recordBatch`, y no solo `SimpleJpaRepository`.
- [ ] Con `maximum-pool-size: 2`, ocho `curl` en paralelo producen al menos un `SQLTransientConnectionException: HikariPool-1 - Connection is not available`.
- [ ] Durante ese fallo, `pg_stat_activity` muestra las conexiones en `idle in transaction` y ninguna consulta ejecutándose.
- [ ] Con el pool restaurado a 10, las ocho peticiones devuelven `200` y `grep -c 'Connection is not available' app.log` devuelve `0`.
- [ ] `jobs` no lista ningún `java -jar` al terminar la sesión.

---

## 🧠 Preguntas rápidas

1. Tu endpoint devuelve `422` con un `ProblemDetail` impecable y la fila quedó grabada en
   `inventory_event`. Explica por qué las dos cosas son compatibles y cuál es el único comando
   que resuelve la duda.
2. En la variante de self-invocation **no había transacción**, y sin embargo las filas se
   guardaron. ¿Quién las confirmó?
3. Subes `org.springframework.transaction.interceptor` a `TRACE`, ves líneas de
   `Getting transaction for` y concluyes que hubo transacción. ¿Por qué esa conclusión puede ser
   falsa, y qué hay que mirar en cada línea?
4. "`@Transactional` solo funciona en métodos `public`." Corrige la frase con la versión precisa
   para Spring Framework 6.2 y di qué es lo que de verdad decide si la anotación se aplica.
5. Un `try/catch` dentro de un método transaccional convirtió un rollback en un commit. Da las
   dos correcciones posibles y di en qué caso eliges cada una.
6. Explica `UnexpectedRollbackException: Transaction silently rolled back because it has been
   marked as rollback-only`: quién puso la marca, por qué la excepción aparece en un método que
   no falló, y por qué es preferible a la alternativa.
7. Con `maximum-pool-size: 2`, ¿cuántas peticiones concurrentes hacen falta para bloquear un
   método que llama a otro con `REQUIRES_NEW`? Escribe la regla general.
8. El servicio lanza `Connection is not available` y en la base no hay una sola consulta
   ejecutándose. ¿Qué estado muestra `pg_stat_activity`, y qué te dice eso sobre dónde está el
   recurso agotado?
9. `spring.jpa.show-sql=true` no te sirvió para diagnosticar el N+1. Nombra las tres cosas que
   configuras en su lugar y qué aporta cada una.
10. Añades `@EntityGraph(attributePaths = "events")` a una consulta paginada y aparece
    `HHH90003004: firstResult/maxResults specified with collection fetch; applying in memory`.
    ¿Qué está haciendo Hibernate, por qué, y en qué tamaño de tabla se convierte en un incidente?
11. `LazyInitializationException: failed to lazily initialize a collection of role: … - no
    Session`: ¿qué objeto concreto lanzó eso, qué le faltaba, y por qué poner
    `open-in-view: true` es una mala respuesta aunque el endpoint pase a `200`?
12. ¿Qué garantiza `ddl-auto: validate` y qué **no** detecta? Di si una columna de más en la
    tabla rompe el arranque.
13. Editas un `V1__` que ya se aplicó y el arranque muere. ¿Qué mensaje da Flyway, por qué ese
    comportamiento es una característica y cuál es el procedimiento correcto?
14. Diferencia `docker compose -p inv-lab down` de `down -v` y di cuál de los dos explica que el
    lab te dé un resultado distinto al del documento.
15. ¿Cuándo eliges `JdbcClient` sobre un repositorio de Spring Data JPA en este mismo servicio, y
    qué comparten los dos aunque parezcan caminos separados?

---

## 🧪 Ejercicios (16)

### 🟢 Fácil — repetir lo del lab con otro valor o en otro punto  (1–5)

#### 🟢 Ejercicio 1 — la segunda migración

Escribe `V2__add_inventory_item_category.sql` que añada una columna `category VARCHAR(30)` con
default `'general'`, arranca, y comprueba con `SELECT * FROM flyway_schema_history` que hay dos
filas y dos checksums distintos.
**Objetivo:** ver que el esquema evoluciona hacia adelante y nunca editando lo aplicado.

#### 🟢 Ejercicio 2 — el N+1 con otro tamaño

Repite el conteo de sentencias de la sección 4 con `limit=5` y con `limit=100`, antes y después
del `@EntityGraph`, y arma una tabla de cuatro filas con los números.
**Pregunta:** ¿la mejora es constante o proporcional al tamaño de la página?

#### 🟢 Ejercicio 3 — el silencio en otro método

Aplica la variante A —self-invocation— al método `create` en vez de a `record`: llama a
`create()` desde otro método sin anotar de la misma clase y haz que falle después del `save()`.
Demuestra con un `SELECT` que el item quedó grabado.
**Objetivo:** comprobar que el silencio no depende del método, sino de por dónde entra la llamada.

#### 🟢 Ejercicio 4 — el teardown que no borra

Con datos en la base, ejecuta `docker compose -p inv-lab down`, vuelve a levantar el perfil y
cuenta las filas. Después repite con `-v`.
**Objetivo:** fijar de una vez la diferencia que produce la mitad de los resultados irreproducibles.

#### 🟢 Ejercicio 5 — el pool en Actuator

Con el pool en 2 y las ocho peticiones en paralelo corriendo, consulta
`/actuator/metrics/hikaricp.connections.pending` y `/actuator/metrics/hikaricp.connections.acquire`
y anota los valores.
**Pregunta:** ¿cuál de las dos métricas pondrías en una alerta, y con qué umbral?

### 🟡 Intermedio — aplicarlo a otra clase, otro endpoint u otra propiedad  (6–10)

#### 🟡 Ejercicio 6 — el tercer silencio: `final`

Marca `record` como `final` dentro de `InventoryService` y arranca. Documenta exactamente qué
pasa: si el arranque falla, copia el mensaje; si arranca, demuestra con el `SELECT` que la
transacción no se aplicó.
**Objetivo:** distinguir los silencios que avisan de los que no, y saber por qué CGLIB decide eso.

#### 🟡 Ejercicio 7 — el import que importa

Cambia el import de `@Transactional` a `jakarta.transaction.Transactional` en `recordBatch`,
compila, y después intenta añadirle `readOnly = true`.
**Pregunta:** ¿en qué momento exacto te enteras del cambio, y qué habría pasado si el método no
necesitara ningún atributo?

#### 🟡 Ejercicio 8 — la misma consulta, tercera vía

Resuelve `totalsBySku()` una tercera vez con una **proyección de interfaz** de Spring Data
(`interface SkuTotalView { String getSku(); long getTotal(); }`) y compara el SQL generado con el
de las otras dos.
**Objetivo:** ver que la proyección también recorta columnas y decidir cuál de las tres formas
leerías con más gusto dentro de seis meses.

#### 🟡 Ejercicio 9 — `rollbackFor` sobre una excepción comprobada

Crea una `NotifierException extends Exception` (comprobada), lánzala desde `record` después de
las dos escrituras, y demuestra con un `SELECT` que **hubo commit**. Después arréglalo con
`@Transactional(rollbackFor = Exception.class)` y vuelve a demostrarlo.
**Objetivo:** fijar que el rollback por defecto es solo para `RuntimeException` y `Error`, con la
prueba en la mano y no de memoria.

#### 🟡 Ejercicio 10 — paginar sin traerlo todo

Elimina el `HHH90003004` sin renunciar a la paginación: trae primero la página de ids con una
consulta y después los items con sus eventos con un `IN (:ids)`. Cuenta las sentencias.
**Pregunta:** ¿por qué dos consultas deterministas son mejores que una que pagina en memoria?

### 🟠 Difícil — combinar, diagnosticar o decidir  (11–14)

#### 🟠 Ejercicio 11 — el diagnóstico a ciegas

Pídele a alguien (o a ti mismo dentro de una semana) que introduzca **uno** de los tres silencios
de la sección 6 en cualquier punto del servicio, sin decirte cuál. Diagnostícalo usando solo el
log del `TransactionInterceptor` en `TRACE` y `psql`, y escribe en tres líneas cuál era y cómo lo
supiste.
**Objetivo:** convertir la sección 6 en un procedimiento, que es lo que se usa en un incidente.

#### 🟠 Ejercicio 12 — el deadlock sin `REQUIRES_NEW`

Provoca el mismo `Connection is not available` **sin usar `REQUIRES_NEW`**: un método
transaccional que dentro hace una llamada HTTP lenta a `httpbin`-style o simplemente un
`Thread.sleep(4000)`, con el pool en 2 y cuatro peticiones concurrentes.
**Pregunta:** ¿en qué se diferencia este incidente del de la sección 7 al mirar
`pg_stat_activity`, y cuál de los dos arreglarías primero?

#### 🟠 Ejercicio 13 — atomicidad por elemento, bien hecha

El lote debe seguir procesando aunque un movimiento sea inválido, **y cada movimiento válido
debe quedar guardado**. Impleméntalo con `TransactionTemplate` —no con `@Transactional` en el
bucle— y demuestra con un `SELECT` que de cinco movimientos con el tercero inválido quedan
cuatro filas.
**Objetivo:** resolver bien el requisito que en la variante B se resolvió mal, y entender por qué
la anotación no podía expresarlo.

#### 🟠 Ejercicio 14 — el índice que faltaba

Borra `idx_inventory_event_item` con una migración `V3__`, siembra 50 000 eventos con un
`INSERT ... SELECT generate_series(...)`, y compara `EXPLAIN ANALYZE` de la consulta de detalle
con y sin índice.
**Pregunta:** ¿cuánto de "lento" era N+1 y cuánto era el *sequential scan*? Relaciónalo con la
regla de una variable a la vez.

### 🔴 Muy difícil — abierto o adversarial  (15–16)

#### 🔴 Ejercicio 15 — el test que impide la regresión

Escribe un test de integración que **falle** si alguien reintroduce cualquiera de los tres
silencios de la sección 6. Tiene que ejecutar el caso que debe revertir y afirmar sobre el
conteo de filas en la base, no sobre el código de estado ni sobre el log. Correrlo no puede
tardar más de unos segundos.
**Objetivo:** convertir el lab entero en una red de seguridad automática, que es la única forma
de que esto no vuelva a pasar en un equipo de ocho personas.

#### 🔴 Ejercicio 16 — el servicio saboteado

Se te entrega `inv-api` con cuatro defectos introducidos a la vez y sin pistas: uno de la
sección 4, uno de la 5, uno de la 6 y uno de la 7. El síntoma que reporta negocio es solo
*"el inventario no cuadra y a veces la API se cae"*. Escribe un informe de diagnóstico con el
orden en que los buscaste, el comando o el log que confirmó cada uno, la corrección y la medida
que evita la repetición.
**Objetivo:** ordenar la búsqueda por observabilidad —lo que deja rastro primero, lo silencioso
al final— en vez de por el orden del documento.

### 🔥 Opcionales y ampliaciones

- **La proyección en Mongo desde `AFTER_COMMIT`.** Levanta el perfil `nosql`
  (`docker compose --profile nosql up -d`), añade `spring-boot-starter-data-mongodb` y proyecta
  cada movimiento confirmado a la colección `inventory_snapshot` desde un
  `@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)`. Después **provoca el
  caso que importa**: haz que la transacción falle y comprueba que el listener no corrió; y
  después mata el proceso entre el commit y el listener y comprueba que el snapshot se perdió
  para siempre. Ese agujero es el argumento del patrón **outbox**, y el diseño completo vive en
  el corpus de arquitectura. Está fuera del alcance base porque no aporta un silencio nuevo:
  aporta un mecanismo correcto, que es otra cosa. Recuerda `docker compose -p inv-lab down -v`
  para el volumen `mongo-data`.
- **Bloqueo optimista con `@Version`.** La columna `version` ya está en el esquema desde `V1`.
  Añade `@Version private long version;` a `InventoryItem` y lanza dos `POST` de evento
  simultáneos sobre el mismo `sku`: uno de los dos recibe
  `ObjectOptimisticLockingFailureException`. Tradúcelo a un `409` con tu `ProblemDetail` de
  `L03`. Después compáralo con la alternativa que casi todo el mundo propone —subir el nivel de
  aislamiento a `SERIALIZABLE`— y mide las dos.
- **`@Transactional` desde `@PostConstruct`.** El cuarto silencio de
  [`16` §7](16-transacciones.md#7--los-seis-silencios). Anota un método de inicialización y
  comprueba con el log del interceptor que la transacción no existe, y razona por qué el
  contenedor todavía no tiene el proxy listo en ese punto del ciclo de vida (`02`).
- **`NESTED` y savepoints.** Cambia el `REQUIRES_NEW` de la sección 7 por
  `Propagation.NESTED` y documenta qué pasa con `JpaTransactionManager`. Pista: no lo que
  esperas, y el mensaje de error es la respuesta.

### 💀 Boss fight — el informe de integridad de `inv-api`

Entrega un artefacto que otro equipo pueda usar sin preguntarte nada, cumpliendo todo esto a la
vez:

- **Un `docker compose` y un script** que levanten el perfil `db`, siembren 500 items con 5
  eventos cada uno y dejen el entorno listo en menos de dos minutos, con su teardown.
- **Una tabla de garantías transaccionales** de cada método público de `InventoryService`:
  límite de la transacción, propagación, qué excepciones revierten, cuántas conexiones del pool
  consume un request por ese camino y quién lo verifica.
- **Un test de integración por cada fila de esa tabla**, que afirme sobre el estado de la base y
  no sobre el código de estado HTTP. Si mañana alguien mueve un `@Transactional`, la suite falla
  con un mensaje que dice cuál.
- **Un endpoint `/actuator/health/inventory`** que se ponga rojo si detecta inconsistencia entre
  `inventory_item.quantity` y la suma de `inventory_event.delta`. Ese indicador es la única
  defensa real contra los silencios de la sección 6, porque no depende de que alguien mire.
- **Una página de runbook** con los cuatro síntomas del lab —N+1, `LazyInitializationException`,
  rollback ausente y pool agotado—, su primera línea de log literal, el comando de diagnóstico y
  la corrección, en el formato de una entrada de catálogo de errores.

**Objetivo:** convertir siete secciones de mecanismo en el artefacto que un Tech Lead entrega
cuando dice "nuestra capa de datos es correcta": no una afirmación, una comprobación automática
que sigue corriendo cuando tú ya no estás mirando.

---

## 🏁 La señal de que quedó bien

`docker compose -p inv-lab ps` lista un solo contenedor, `inv-lab-postgres-1`, en `healthy`, y
`psql -c '\dt'` muestra las tres tablas. `inv-api` arranca aplicando cero migraciones nuevas,
responde los mismos códigos de `L03` y ahora sobrevive a un reinicio: los datos están en el
volumen, no en el heap. `GET /api/items?limit=20` emite **una** sentencia SQL y `grep -c` lo
demuestra. No queda un solo `InventoryStore` en `src/`, ni un `show-sql`, ni un endpoint que
devuelva una entidad.

Y lo que de verdad cuenta: un `POST` que deja el stock negativo devuelve `422` **y el conteo de
filas de `inventory_event` es idéntico antes y después**. Si mueves el `@Transactional` a la
clase equivocada, ese conteo cambia y el `422` sigue viéndose igual de correcto — y ya sabes que
la única forma de distinguir los dos casos es el `SELECT`, no el log ni el código de estado.

El perfil `db` se queda arriba: `L05` levanta además el perfil `ext` con WireMock y le pone
delante a `inv-api` un proveedor lento, que es la otra forma de retener una conexión del pool
durante segundos sin que la base haga nada.

---

## 📚 Referencias oficiales

- Spring Framework 6.2 — Gestión de transacciones: https://docs.spring.io/spring-framework/reference/6.2/data-access/transaction.html
- Spring Framework 6.2 — Estrategias y `PlatformTransactionManager`: https://docs.spring.io/spring-framework/reference/6.2/data-access/transaction/strategies.html
- Spring Framework 6.2 — `@Transactional` y sus atributos (incluida la visibilidad de método): https://docs.spring.io/spring-framework/reference/6.2/data-access/transaction/declarative/annotations.html
- Spring Framework 6.2 — Propagación: https://docs.spring.io/spring-framework/reference/6.2/data-access/transaction/declarative/tx-propagation.html
- Spring Framework 6.2 — Rollback declarativo y `rollbackFor`: https://docs.spring.io/spring-framework/reference/6.2/data-access/transaction/declarative/rolling-back.html
- Spring Framework 6.2 — Transacciones programáticas y `TransactionTemplate`: https://docs.spring.io/spring-framework/reference/6.2/data-access/transaction/programmatic.html
- Spring Framework 6.2 — Eventos ligados a la transacción: https://docs.spring.io/spring-framework/reference/6.2/data-access/transaction/event.html
- Spring Framework 6.2 — Mecanismo de proxy (por qué `private` nunca se intercepta): https://docs.spring.io/spring-framework/reference/6.2/core/aop/proxying.html
- Spring Framework 6.2 — `JdbcClient` y JDBC core: https://docs.spring.io/spring-framework/reference/6.2/data-access/jdbc/core.html
- Spring Framework 6.2 — Control de conexiones y `DataSource`: https://docs.spring.io/spring-framework/reference/6.2/data-access/jdbc/connections.html
- Spring Framework 6.2 — Jerarquía de `DataAccessException`: https://docs.spring.io/spring-framework/reference/6.2/data-access/dao.html
- Spring Boot 3.5 — Bases de datos SQL, `DataSource` y Hikari: https://docs.spring.io/spring-boot/3.5/reference/data/sql.html
- Spring Boot 3.5 — Inicialización de datos y migraciones con Flyway: https://docs.spring.io/spring-boot/3.5/how-to/data-initialization.html
- Spring Boot 3.5 — Endpoints de Actuator (`metrics`, `flyway`): https://docs.spring.io/spring-boot/3.5/reference/actuator/endpoints.html
- Spring Boot 3.5 — Índice de propiedades (`spring.datasource.hikari.*`, `spring.jpa.*`, `spring.flyway.*`): https://docs.spring.io/spring-boot/3.5/appendix/application-properties/index.html
- Spring Data JPA 3.5 — Conceptos del repositorio: https://docs.spring.io/spring-data/jpa/reference/3.5/repositories/core-concepts.html
- Spring Data JPA 3.5 — Query methods, `@Query` y `@EntityGraph`: https://docs.spring.io/spring-data/jpa/reference/3.5/jpa/query-methods.html
- Spring Data JPA 3.5 — Transaccionalidad de los repositorios: https://docs.spring.io/spring-data/jpa/reference/3.5/jpa/transactions.html
- Spring Data JPA 3.5 — Bloqueo optimista y `@Version`: https://docs.spring.io/spring-data/jpa/reference/3.5/jpa/locking.html
- Spring Data MongoDB 4.5 — `MongoTemplate` (para el 🔥 opcional): https://docs.spring.io/spring-data/mongodb/reference/4.5/mongodb/template-api.html

### Documentación de terceros

- Hibernate ORM 6.6 — User Guide: https://docs.hibernate.org/orm/6.6/userguide/html_single/
- HikariCP — configuración completa: https://github.com/brettwooldridge/HikariCP
- HikariCP — cálculo del tamaño del pool: https://github.com/brettwooldridge/HikariCP/wiki/About-Pool-Sizing
- Flyway — migraciones versionadas: https://documentation.red-gate.com/flyway/flyway-concepts/migrations/versioned-migrations
- PostgreSQL 17 — Aislamiento de transacciones: https://www.postgresql.org/docs/17/transaction-iso.html
- PostgreSQL 17 — Bloqueo explícito: https://www.postgresql.org/docs/17/explicit-locking.html
- Docker Compose — perfiles: https://docs.docker.com/compose/how-tos/profiles/
