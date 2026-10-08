# inventory

Las existencias por droguería y sus movimientos; desde G5, la venta, y desde G11, el préstamo entre
droguerías como saga orquestada. Sale del `StockService` de Contingencia y de su procedimiento
`register_loan` (`../../legacy/contingencia/`).

## Stack

- Spring Boot (la versión de `a01`) con Java 25, Maven con su wrapper, solo `spring-boot-starter-webmvc`.
- **Actuator solo para `/metrics`** (G6): `management.endpoints.web.base-path=/`, expuesto únicamente
  `prometheus` y mapeado a `metrics`; la salud sigue siendo un controlador propio (G4).
- Imagen: `lab/inventory`. Escucha en `PORT` (8080 por defecto, por `server.port=${PORT:8080}`).
  Multi-stage desde la Fase 04: compila con el JDK, extrae el jar por capas, y corre con el JRE como
  el usuario `inventory` (uid 10001).

## Comandos

```bash
task build -- inventory               # construye la imagen con el motor activo
task compose:up                       # el sistema en compose
task conformance -- G1                # la suite del paso; tiene que pasar
```

## Convenciones

- Identificadores en inglés, comentarios en español con tildes.
- Desde G7, una línea JSON por evento a stdout (`time`, `level`, `service`, `msg`); la de cada petición,
  con `method`, `uri`, `path`, `status`, `duration_ms` y `request_id` (de `X-Request-Id`).
- La salud vive en `HealthController`; el log por petición, en `RequestLogFilter`.
- El contrato manda: `../../contracts/openapi/inventory.yaml`. Se cambia el contrato y la suite antes
  que el código.

## El contrato, paso a paso

| Paso | Qué | Estado |
|---|---|---|
| G0 | `/health/live`, `/health/ready` triviales; `GET /stock/{storeId}/{sku}` con existencia fija | ✅ hecho |
| G1 | almacén propio (SQLite con JDBC, en `DATA_DIR`), `PATCH /stock/...` (solo el umbral), `POST /stock/.../movements` (`RESTOCK`, `ADJUSTMENT` y `COUNT`: la existencia solo cambia por movimientos, y el primero la crea con umbral 0; `reasonCode` obligatorio en los ajustes, y `reference`), `GET /reason-codes` (tabla sembrada) | ✅ hecho |
| G3 | Postgres por `DATABASE_URL` (`StoreConfig` arma la URL de JDBC; sin ella, el SQLite de G1), esquema por motor (`schema-sqlite.sql`, `schema-postgresql.sql`) y `data.sql` común, `java -jar … migrate` para el `Job` | ✅ hecho |
| G4 | readiness real, sin Actuator (el contrato pide `{"status":"ready"}`, Actuator responde `UP`): `ApplicationAvailability` en `ACCEPTING_TRAFFIC` y la base válida en un segundo; 503 `{"status":"not_ready"}` si no. Hikari espera 2 s por una conexión, no 30 | ✅ hecho |
| G5 | `POST /sales` (`SalesController`): `catalog` valida, `pricing` pone el precio, la fila de la existencia se bloquea (`FOR UPDATE` con Postgres) y se descuenta con un movimiento `SALE`, tabla `sales`; bajo el umbral, aviso a `replenish` en un hilo virtual sin esperar. La carrera de los movimientos, cerrada igual. Apagado limpio: `server.shutdown=graceful`, 20 s | ✅ hecho |
| G6 | `/metrics` con Actuator y `micrometer-registry-prometheus` (versiones de Spring Boot): `http.server.requests` con histograma (`percentiles-histogram`), que agrega `outcome`, `error` y `exception` a las tres etiquetas del contrato; lo que no tiene ruta, `uri="/**"`. La métrica de negocio: `lab.sales` (`lab_sales_total`), en `SalesController` | ✅ hecho |
| G7 | logging estructurado de Spring Boot (`logstash`, renombrado y recortado por propiedades), sin banner; `request_id` en el MDC y reenviado a los vecinos por un interceptor de `RestClient` (y a mano al hilo virtual del aviso); `--enable-native-access` en el `CMD`. Única línea en texto: `Picked up JAVA_TOOL_OPTIONS`, de la JVM | ✅ hecho |
| G8 | con `PRICING_URL` en `https`, el cliente de `pricing` usa el *SSL bundle* `pricing` (PEM, con `reload-on-update`) en un `HttpClient` del JDK, y se rearma cuando el bundle cambia | ✅ hecho |
| G9 | timeouts (1 s / 2 s) en todos los clientes de los vecinos; `Guard.java` con Resilience4j (núcleo): 3 intentos con espera exponencial al azar y un circuito por vecino, solo para `catalog` y `pricing`; el aviso a `replenish` sin reintentos; ajustable con `lab.resilience.*` | ✅ hecho |
| G10 | el precio por gRPC (`PricingGrpc.java`, código generado al compilar desde `contracts/proto`), con el *SSL bundle* de G8, la política de `PRICING_GRPC_POLICY` y el plazo de G9; el agente de OpenTelemetry (`-javaagent`, apagado con `OTEL_JAVAAGENT_ENABLED=false`), y `Context.current().wrap(...)` en el hilo del aviso a `replenish` para que no parta la traza | ✅ hecho |
| G11 | `POST /loans` y `GET /loans/{loanId}` (`LoansController`): la saga del préstamo en `LoanSaga`, con su estado en `loans` y `loan_steps`; RESERVE (`LOAN_OUT`), DISPATCH (orden en `replenish`, sin reintentos), CHARGE (fila de `sales` en el destino, precio de `priceFor`) y RECEIVE (`LOAN_IN`); compensaciones en orden inverso (`LOAN_RELEASED`, cancelación con `SAGA_COMPENSATION`); sin existencia, `BACKORDERED`; un barrido con `@Scheduled` cada 30 s retoma lo que quedó a medias (`lab.saga.*`); un span por paso | ✅ hecho |
| G12 | `EventBus`: con `EVENT_BUS=valkey` (`valkey-java`, `VALKEY_URL`) o `nats` (`jnats`, `NATS_URL`, stream `LAB_EVENTS` asegurado al publicar), el aviso de la venta es el evento `lab.inventory.stock-low` (contrato: `x-lab-events`), publicado después de confirmar la venta, en el mismo hilo virtual; sin `EVENT_BUS`, sigue el `POST` de G5 | ✅ hecho |
| G13 | `Idempotency-Key` en `POST /sales` y `POST /loans` (columna `idempotency_key` con índice único parcial; la misma clave y el mismo cuerpo devuelven lo ya hecho, otro cuerpo es 422; `migrations-sqlite.sql` para las bases SQLite viejas); el `DISPATCH` de la saga manda la clave del préstamo, reintenta un timeout hasta 3 veces y, al compensar sin número de orden, la busca por la clave; con `EVENT_BUS=nats`, el evento va a la tabla `outbox` en la transacción de la venta, y lo publica `relay/` (Go, `pgx` y `nats.go`, `Nats-Msg-Id` = `eventId`) como sidecar nativo con la misma imagen; `jnats` salió del `pom.xml` | ✅ hecho |

**No agregues nada de un paso pendiente**, aunque sea fácil o el framework lo traiga de serie: una
capacidad antes de su fase invalida el paso.
