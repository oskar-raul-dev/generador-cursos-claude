# 🗄️ Fase 09 — SQL: PostgreSQL y SQLite

> Go para desarrolladores Java senior · Fase 9 de 17 · **9 horas**
> Época: **Go moderno (1.25)**
> Depende de: Fase 08 · Habilita: Fase 10
> Proyectos que avanzan: **OpsReport** persiste · **EventRelay** mueve su cola a la base · **ClearingHouse nace** (`storeagent` con SQLite)
> Mini proyectos: `pool-lab`, `tx-lab`, `cursor-vs-offset`

---

## 🎯 1. Propósito

Los dos servicios llevan nueve fases guardando todo en un mapa. Hoy se acabó, y
con ello se pagan las dos deudas más viejas del curso: la cola de OpsReport que se
perdía al reiniciar y el planificador de reintentos de EventRelay con un
`time.Timer` por entrega.

Esta es la fase más larga del curso y la que más reflejos de Java toca, porque es
donde vives desde hace años: JPA, Hibernate, `@Transactional`, Spring Data. Casi
todo lo que sabes de SQL y de modelado se traslada intacto 🩻. Lo que cambia es la
capa de acceso, y cambia de una forma muy concreta: **`database/sql` no es un
driver, es un pool**, y **en Go la propagación transaccional es un parámetro, no
una anotación.**

Y llega el debate del ORM, resuelto con los tres competidores medidos sobre la
misma consulta en vez de con dogma.

---

## ✅ 2. Qué queda listo al terminar

- [ ] PostgreSQL corre en el `compose.yaml` y las migraciones de OpsReport y
      EventRelay se aplican con `goose`.
- [ ] `internal/postgres` implementa las interfaces `Store` que los servicios
      declararon en la Fase 02, **sin que ningún servicio cambie**.
- [ ] El pool está configurado con los cuatro parámetros y sabes justificar cada
      número.
- [ ] EventRelay reclama entregas con `SELECT ... FOR UPDATE SKIP LOCKED` y N
      instancias no se pisan.
- [ ] La paginación de `/work-items` es por cursor, no por `OFFSET`, y tienes la
      medición que lo justifica.
- [ ] `storeagent` existe: una herramienta de línea de comandos con SQLite
      embebido que acumula movimientos sin red.
- [ ] La suite de contrato de la Fase 04 corre contra `memstore` **y** contra
      PostgreSQL, sin cambiar los tests.
- [ ] `make test-integration` levanta contenedores con `testcontainers-go` y pasa.
- [ ] La zona horaria por tienda está resuelta y probada con el caso de Bogotá y
      Ciudad de México.

---

## 🚫 3. Qué NO entra todavía

- MongoDB → Fase 11. AtlasSync ni siquiera existe aún.
- El cierre por lotes de ClearingHouse → Fase 13. Hoy nace solo el agente de
  tienda y el esquema del servicio central.
- Caché → Fase 12. Toda consulta va a la base de datos, y eso es correcto hasta
  que se mida que no lo es.
- El patrón outbox → Fase 13, donde OpsReport y EventRelay se encuentran de
  verdad.
- Métricas de base de datos y trazas del driver → Fase 14.
- Réplicas de lectura, particionado y *sharding* → **fuera del curso**. Se nombran
  en el ⚖️ veredicto.

---

## 🧠 4. Concepto mínimo

### `database/sql` es un pool, y eso lo explica casi todo

```go
db, err := sql.Open("pgx", dsn)
```

**`sql.Open` no abre una conexión.** No contacta con el servidor, no valida
credenciales, no falla si la base de datos está caída. Construye un objeto pool y
vuelve. La primera conexión real se abre en la primera consulta.

```go
// Por eso esto es obligatorio en el arranque, y por eso lleva contexto:
ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
defer cancel()

if err := db.PingContext(ctx); err != nil {
	return nil, fmt.Errorf("no se pudo conectar a la base de datos: %w", err)
}
```

Sin ese `Ping`, un servicio con la contraseña mal escrita **arranca
perfectamente**, el orquestador lo marca como sano, y falla en la primera
petición de un usuario. Es el equivalente exacto de no validar la configuración al
arrancar, y la Fase 03 ya dijo por qué eso está mal.

📖 El paralelo es HikariCP, y es bueno: `*sql.DB` **es** el pool, no la conexión.
La diferencia es que en Java `DataSource` y `Connection` son tipos distintos y lo
tienes interiorizado; aquí el mismo `*sql.DB` sirve para todo y la gente escribe
`db.Query` pensando que tiene una conexión en la mano.

De ahí sale el error número uno de esta fase:

```go
// ❌ Cada llamada toma una conexión del pool. Si no cierras las filas, NO VUELVE.
rows, err := db.QueryContext(ctx, "SELECT ...")
if err != nil {
	return err
}
for rows.Next() {
	// ... y aquí un `return` temprano ...
}
// rows.Close() nunca se ejecutó → una conexión menos en el pool, para siempre

// ✅
rows, err := db.QueryContext(ctx, "SELECT ...")
if err != nil {
	return err
}
defer rows.Close()   // ← inmediatamente después de comprobar el error
```

Con `MaxOpenConns = 25`, veinticinco peticiones con `return` temprano agotan el
pool y **el servicio se cuelga entero**: toda consulta siguiente se queda
esperando una conexión que nunca vuelve. Es el incidente clásico, no da error, y
se manifiesta como "la aplicación se quedó colgada".

> ⚠️ **`rows.Close()` es idempotente y `rows.Next()` cierra solo al llegar al
> final.** Si recorres todas las filas hasta que `Next()` devuelve `false`, se
> cierra sola. El `defer` cubre los caminos donde **no** llegas al final: un
> `return` por error, un `break`, un panic. Como esos son justamente los caminos
> que no pruebas, el `defer` no es opcional.

### Los cuatro parámetros del pool

```go
db.SetMaxOpenConns(25)                  // techo duro de conexiones simultáneas
db.SetMaxIdleConns(25)                  // cuántas se mantienen abiertas sin uso
db.SetConnMaxLifetime(5 * time.Minute)  // cuánto vive una conexión como máximo
db.SetConnMaxIdleTime(2 * time.Minute)  // cuánto puede estar ociosa antes de cerrarse
```

Y las cuatro justificaciones, porque copiar números de un blog es cómo se
producen incidentes:

**`MaxOpenConns`** es el límite real de concurrencia contra la base de datos.
PostgreSQL aguanta por defecto 100 conexiones **en total**, para todos los
clientes. Con seis réplicas de tu servicio a 25 cada una son 150, y la séptima
conexión falla con `too many clients already`. **El cálculo es: `max_connections`
del servidor, menos margen para mantenimiento, dividido entre el número de
instancias.** Ese número no sale de un blog.

**`MaxIdleConns`** por defecto es **2**, y ese valor por defecto es una trampa:
con `MaxOpenConns = 25` y `MaxIdleConns = 2`, bajo carga el pool abre 25
conexiones, y al bajar la carga cierra 23 — para volver a abrirlas en el siguiente
pico. Abrir una conexión a PostgreSQL cuesta milisegundos y un proceso en el
servidor. **La recomendación práctica es igualarlo a `MaxOpenConns`.**

**`ConnMaxLifetime`** existe por dos razones muy prácticas: permitir que un
balanceador o un `pgbouncer` redistribuya conexiones, y sobrevivir a un *failover*
de la base de datos sin conexiones muertas en el pool. Un valor de 5 minutos es
razonable; infinito (el valor por defecto) es lo que hace que tras un failover el
servicio siga intentando usar conexiones a un servidor que ya no es el primario.

**`ConnMaxIdleTime`** cierra lo que lleva mucho sin usarse, para no mantener
procesos ocupados en el servidor en horas valle.

> 🧭 **Regla del proyecto.** Los cuatro se configuran **siempre** y cada uno lleva
> un comentario con su porqué. Un `sql.Open` sin configuración de pool es un
> incidente esperando, exactamente como un `http.Server{}` sin timeouts.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El instinto:** *"pongo `@Transactional` en el método de servicio y las llamadas
de dentro participan en la transacción"*. Es correcto en Spring, lleva quince años
funcionando, y es de las cosas que mejor resuelve: la propagación es automática, la
anotación es declarativa, y el *proxy* se encarga.

**Qué pasa si lo aplicas aquí.** Buscas el equivalente, no lo hay, y acabas en uno
de estos dos sitios:

```go
// ☕ Opción A: el "contexto transaccional" escondido.
// Se mete la transacción en el context.Context y cada repositorio la saca.
func (r *Repo) Save(ctx context.Context, item WorkItem) error {
	tx := TxFrom(ctx)   // ← devuelve nil si no hay transacción
	if tx != nil {
		_, err := tx.ExecContext(ctx, insertSQL, ...)
		return err
	}
	_, err := r.db.ExecContext(ctx, insertSQL, ...)
	return err
}
```

Funciona, y reproduce exactamente la magia de `@Transactional` con sus mismos
problemas: **no se ve en la firma si una función participa en una transacción**,
`TxFrom` puede devolver nil y nadie lo comprueba, y el contexto vuelve a ser una
bolsa de parámetros — que es el ☕ de la Fase 07.

```go
// ☕ Opción B: el gestor de transacciones casero con callbacks anidados.
type TxManager struct{ db *sql.DB }

func (m *TxManager) InTransaction(ctx context.Context, fn func(context.Context) error) error {
	// ... y ahora hay que decidir qué pasa si alguien anida dos llamadas,
	// y acabas implementando REQUIRED, REQUIRES_NEW y NESTED a mano.
}
```

**Qué pensar en su lugar.** En Go la transacción es **un valor que se pasa**, y
eso tiene una consecuencia que hay que ver antes de juzgarla:

```go
// La interfaz que unifica *sql.DB y *sql.Tx. Cuatro métodos, y es lo único que
// hace falta para que un repositorio funcione dentro o fuera de transacción.
type DBTX interface {
	ExecContext(ctx context.Context, query string, args ...any) (sql.Result, error)
	QueryContext(ctx context.Context, query string, args ...any) (*sql.Rows, error)
	QueryRowContext(ctx context.Context, query string, args ...any) *sql.Row
	PrepareContext(ctx context.Context, query string) (*sql.Stmt, error)
}

// El repositorio recibe la transacción POR PARÁMETRO. Se ve en la firma.
func (r *WorkItemStore) Save(ctx context.Context, q DBTX, item workitem.WorkItem) error {
	_, err := q.ExecContext(ctx, insertWorkItemSQL,
		item.ID, item.ExternalReference, item.Kind, item.Priority, item.Status, item.CreatedAt)
	return err
}

// Y el caso de uso decide el alcance de la transacción, explícitamente.
func (s *Service) CreateWithOutbox(ctx context.Context, item workitem.WorkItem) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("abriendo transacción: %w", err)
	}
	// El patrón del curso: Rollback diferido SIEMPRE. Si el Commit ya ocurrió,
	// este Rollback devuelve sql.ErrTxDone y no hace nada. Si hay un return
	// temprano o un panic, deshace. Es imposible olvidarse.
	defer tx.Rollback()

	if err := s.store.Save(ctx, tx, item); err != nil {
		return fmt.Errorf("guardando work item: %w", err)
	}
	if err := s.outbox.Append(ctx, tx, eventFrom(item)); err != nil {
		return fmt.Errorf("encolando evento: %w", err)
	}

	return tx.Commit()
}
```

**El intercambio, dicho sin adornos.** Pierdes: una anotación de una línea, la
propagación automática, y la posibilidad de envolver métodos existentes sin
tocarlos. Escribes más: cada firma lleva un parámetro más, y cada caso de uso
declara su transacción.

Y ganas una cosa concreta: **nunca te preguntas si esta llamada está dentro de una
transacción.** Está en la firma. No hay que saber qué método llamó a cuál, ni
recordar que la propagación por defecto es `REQUIRED`, ni descubrir que
`@Transactional` no funciona en una llamada interna del mismo bean porque el proxy
no se activa —que es el bug de Spring que todo el mundo ha tenido una vez.

> 🧭 **Regla del proyecto.** La transacción viaja **por parámetro**, nunca en el
> `context`. El alcance lo decide el caso de uso, no el repositorio. Y todo
> repositorio acepta `DBTX`, para que funcione dentro y fuera de transacción sin
> saber en cuál está.

### 🩻 Esto sí funciona igual

Mucho, y esta es la fase donde más se traslada:

- **SQL es SQL.** Los índices, los planes de ejecución, `EXPLAIN ANALYZE`, los
  niveles de aislamiento, los bloqueos, el diseño de esquema — **todo tu criterio
  se traslada intacto**. No vamos a explicarte qué es un índice.
- **Las migraciones versionadas** son Flyway con otro nombre. `goose` numera,
  aplica en orden, registra en una tabla y falla si detecta divergencia.
- **La transacción como unidad de trabajo** es el mismo concepto. Lo que cambia es
  quién la declara.
- **El pool de conexiones** es HikariCP. Los parámetros tienen otros nombres y
  significan lo mismo.
- **Los tipos nulos** son el mismo problema que resuelves con `Optional` o con
  envoltorios: una columna `NULL` no cabe en un `int`.
- **Los tests de integración con contenedores** son Testcontainers, literalmente:
  el proyecto tiene versión para Go y la API se parece.
- **El problema N+1 existe igual**, solo que en Go es más difícil crearlo sin
  darte cuenta, porque no hay *lazy loading* que lo provoque solo.

---

## 🛠️ 5. CLI de la fase

```bash
# La infraestructura, del compose.yaml de la Fase 00.
make up
docker compose ps

# psql dentro del contenedor, que es como se inspecciona sin instalar nada.
docker compose exec postgres psql -U meridian -d meridian

# Y los metacomandos de psql que más se usan:
#   \dt            listar tablas
#   \d work_items  describir una tabla, con sus índices y restricciones
#   \di            listar índices
#   \x             modo expandido: una fila por pantalla, imprescindible con
#                  tablas anchas
#   \timing        mostrar el tiempo de cada consulta

# Migraciones con goose. La instalación es un go install, como todo.
go install github.com/pressly/goose/v3/cmd/goose@latest

export GOOSE_DRIVER=postgres
export GOOSE_DBSTRING="postgres://meridian:meridian@localhost:5432/meridian?sslmode=disable"
export GOOSE_MIGRATION_DIR=services/opsreport/migrations

goose create add_work_items sql    # crea el archivo con su timestamp
goose status                       # qué está aplicado y qué no
goose up                           # aplicar todas las pendientes
goose up-by-one                    # aplicar solo la siguiente
goose down                         # revertir la última
goose redo                         # down + up de la última: prueba tu Down
goose version                      # en qué versión está la base

# EXPLAIN ANALYZE: el comando más importante de esta fase, y el que menos se usa.
# BUFFERS añade cuántos bloques se leyeron de caché y de disco.
docker compose exec postgres psql -U meridian -d meridian -c \
  "EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) SELECT * FROM work_items WHERE status = 'queued' ORDER BY created_at DESC LIMIT 50;"

# Ver las conexiones activas: es cómo se diagnostica un pool agotado.
docker compose exec postgres psql -U meridian -d meridian -c \
  "SELECT pid, state, wait_event_type, wait_event, query_start, left(query, 60) AS query
   FROM pg_stat_activity WHERE datname = 'meridian' ORDER BY query_start;"

# Y los bloqueos, para el laboratorio de transacciones.
docker compose exec postgres psql -U meridian -d meridian -c \
  "SELECT locktype, relation::regclass, mode, granted, pid FROM pg_locks WHERE NOT granted;"

# SQLite: el archivo se inspecciona con la herramienta oficial, o desde Go.
sqlite3 ~/.meridian/storeagent.db
#   .tables
#   .schema movements
#   .mode box
#   PRAGMA journal_mode;        → debería decir wal
#   PRAGMA integrity_check;

# TESTS DE INTEGRACIÓN: build tag propio, para que la suite rápida siga rápida.
go test -tags=integration ./...
go test -tags=integration -run TestPostgresStore ./internal/postgres -v

# Testcontainers deja los contenedores corriendo si el test entra en panic.
# Este comando los limpia.
docker ps --filter "label=org.testcontainers=true" -q | xargs -r docker rm -f

# Y el que da el diagnóstico cuando un test de integración falla sin explicación:
# los logs del contenedor que testcontainers levantó.
docker logs $(docker ps -a --filter "label=org.testcontainers=true" -q | head -1)
```

> 💡 **`goose redo` es el comando infravalorado.** Aplica y revierte la última
> migración. Si tu `-- +goose Down` está mal escrito —y casi siempre lo está,
> porque nadie lo prueba— te enteras en un segundo en vez de en el peor momento
> posible.

---

## 💻 6. Construcción guiada

### 6.1 Mini proyecto: `pool-lab`

Agotar el pool a propósito, que es la única forma de entender qué pasa cuando
ocurre en producción.

```go
// labs/pool-lab/main.go
package main

// LeakConnections hace veinte consultas sin cerrar las filas. Con
// MaxOpenConns=5, la sexta se queda esperando para siempre.
func LeakConnections(ctx context.Context, db *sql.DB) {
	for i := 0; i < 20; i++ {
		rows, err := db.QueryContext(ctx, "SELECT id FROM work_items LIMIT 1")
		if err != nil {
			log.Printf("consulta %d falló: %v", i, err)
			return
		}
		// SIN rows.Close() y SIN recorrer hasta el final: la conexión no vuelve.
		_ = rows

		stats := db.Stats()
		log.Printf("consulta %d → abiertas=%d en_uso=%d ociosas=%d esperando=%d espera_total=%s",
			i, stats.OpenConnections, stats.InUse, stats.Idle,
			stats.WaitCount, stats.WaitDuration)
	}
}
```

```text
consulta 0 → abiertas=1 en_uso=1 ociosas=0 esperando=0 espera_total=0s
consulta 1 → abiertas=2 en_uso=2 ociosas=0 esperando=0 espera_total=0s
consulta 4 → abiertas=5 en_uso=5 ociosas=0 esperando=0 espera_total=0s
   (y aquí se queda colgado para siempre)
```

**Fíjate en que no hay error.** El programa no falla: se queda esperando. En un
servicio HTTP, eso significa que todas las peticiones empiezan a agotar su plazo y
el panel de métricas muestra latencia infinita sin un solo log de error.

**`db.Stats()` es la herramienta de diagnóstico**, y merece estar expuesta:

```go
// internal/postgres/stats.go

// Stats expone el estado del pool para el endpoint de métricas de la Fase 14.
// Los tres campos que importan de verdad:
//   - WaitCount: cuántas veces alguien tuvo que ESPERAR una conexión. Si crece,
//     el pool es pequeño o hay fugas.
//   - WaitDuration: cuánto se esperó en total. Dividido entre WaitCount da la
//     espera media, que es latencia que el usuario nota.
//   - MaxIdleClosed: cuántas conexiones se cerraron por el límite de ociosas.
//     Si crece rápido, MaxIdleConns está demasiado bajo (el valor por defecto
//     es 2 y casi siempre está mal).
func (s *Store) PoolStats() sql.DBStats { return s.db.Stats() }
```

Y el experimento que cierra el laboratorio: el mismo servicio con `MaxIdleConns`
por defecto (2) y con `MaxIdleConns = MaxOpenConns`, bajo carga oscilante. Mira
`MaxIdleClosed` crecer en el primero.

### 6.2 Las migraciones

```sql
-- services/opsreport/migrations/20260911120000_create_work_items.sql
-- +goose Up
-- +goose StatementBegin

CREATE TABLE work_items (
    id                  TEXT PRIMARY KEY,
    external_reference  TEXT        NOT NULL,
    kind                TEXT        NOT NULL,
    description         TEXT        NOT NULL DEFAULT '',
    priority            SMALLINT    NOT NULL,
    status              TEXT        NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL,
    started_at          TIMESTAMPTZ,
    finished_at         TIMESTAMPTZ,
    failure_reason      TEXT        NOT NULL DEFAULT '',

    -- Las restricciones van en la base de datos ADEMÁS de en el dominio, no en
    -- lugar de. El dominio da mensajes útiles al usuario; la base de datos
    -- garantiza el invariante contra escrituras que no pasen por el servicio —
    -- un script de mantenimiento, una migración de datos, otro equipo.
    CONSTRAINT work_items_priority_range CHECK (priority BETWEEN 1 AND 9),
    CONSTRAINT work_items_status_valid   CHECK (status IN ('queued','running','done','failed','cancelled')),
    CONSTRAINT work_items_kind_valid     CHECK (kind IN ('reconciliation','import','recalculation','statement','reprocess'))
);

-- La referencia externa es única: el sistema de origen no debe poder crear dos
-- veces el mismo trabajo. Es la defensa contra el doble clic y contra el
-- reintento de un cliente que no recibió la respuesta.
CREATE UNIQUE INDEX work_items_external_reference_key ON work_items (external_reference);

-- El índice de la cola. La consulta que sirve es:
--   WHERE status = 'queued' ORDER BY priority DESC, created_at ASC
-- y el orden de las columnas del índice sigue el de la consulta: primero la
-- igualdad, después el orden.
CREATE INDEX work_items_queue_idx ON work_items (status, priority DESC, created_at ASC);

-- Índice para la paginación por cursor de /work-items.
CREATE INDEX work_items_cursor_idx ON work_items (created_at DESC, id DESC);

CREATE TABLE job_executions (
    id           BIGSERIAL PRIMARY KEY,
    work_item_id TEXT        NOT NULL REFERENCES work_items(id) ON DELETE CASCADE,
    worker_id    INTEGER     NOT NULL,
    started_at   TIMESTAMPTZ NOT NULL,
    finished_at  TIMESTAMPTZ NOT NULL,
    duration_ms  BIGINT      NOT NULL,
    error        TEXT        NOT NULL DEFAULT ''
);

CREATE INDEX job_executions_work_item_idx ON job_executions (work_item_id, started_at DESC);

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS job_executions;
DROP TABLE IF EXISTS work_items;
-- +goose StatementEnd
```

> 🧭 **Regla del proyecto: toda migración lleva su `Down` y se prueba con
> `goose redo`.** Un `Down` que nadie ejecutó nunca no es un plan de reversión: es
> un archivo. Y la excepción honesta: hay migraciones cuyo `Down` **no puede**
> revertir (borrar una columna pierde los datos). En esos casos, el `Down` lleva un
> comentario que lo dice explícitamente, y la reversión del despliegue se hace de
> otra forma.

📖 Flyway y goose hacen lo mismo con dos diferencias prácticas: goose numera por
*timestamp* en vez de por versión secuencial —lo que evita el conflicto cuando dos
ramas crean una migración a la vez, que en Flyway es un dolor— y permite
migraciones escritas en Go además de en SQL, para las transformaciones de datos que
SQL no expresa bien.

Y las de EventRelay, que traen la joya de la fase:

```sql
-- services/eventrelay/migrations/20260911121000_create_deliveries.sql
-- +goose Up
-- +goose StatementBegin

CREATE TABLE endpoints (
    id             TEXT PRIMARY KEY,
    partner_name   TEXT        NOT NULL,
    url            TEXT        NOT NULL,
    secret         TEXT        NOT NULL,
    event_patterns TEXT[]      NOT NULL,
    active         BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ NOT NULL
);

CREATE TABLE events (
    id              TEXT PRIMARY KEY,
    type            TEXT        NOT NULL,
    payload         JSONB       NOT NULL,
    idempotency_key TEXT,
    published_at    TIMESTAMPTZ NOT NULL
);

-- La clave de idempotencia es única cuando existe. El índice parcial (WHERE ...)
-- permite que muchos eventos tengan NULL sin colisionar, que es justo lo que un
-- índice único normal no permite.
CREATE UNIQUE INDEX events_idempotency_key_uniq
    ON events (idempotency_key) WHERE idempotency_key IS NOT NULL;

CREATE TABLE deliveries (
    id           TEXT PRIMARY KEY,
    event_id     TEXT        NOT NULL REFERENCES events(id),
    endpoint_id  TEXT        NOT NULL REFERENCES endpoints(id),
    status       TEXT        NOT NULL,
    attempts     INTEGER     NOT NULL DEFAULT 0,
    max_attempts INTEGER     NOT NULL,
    next_attempt TIMESTAMPTZ NOT NULL,
    last_error   TEXT        NOT NULL DEFAULT '',
    created_at   TIMESTAMPTZ NOT NULL,
    delivered_at TIMESTAMPTZ,

    -- Cuándo la reclamó una instancia. NULL mientras está pendiente. Es lo que
    -- permite al recuperador distinguir una entrega en curso de una huérfana:
    -- sin esta columna, una instancia que muere deja la fila en in_flight para
    -- siempre y nadie puede saber desde cuándo. Ver §6.4.
    claimed_at   TIMESTAMPTZ,

    CONSTRAINT deliveries_status_valid CHECK (
        status IN ('pending','in_flight','delivered','failing','dead','cancelled')
    )
);

-- EL ÍNDICE DE LA FASE. Sostiene la consulta de reclamación:
--   WHERE status = 'pending' AND next_attempt <= now() ORDER BY next_attempt
--
-- Es PARCIAL: solo indexa las filas pendientes. Una tabla con diez millones de
-- entregas entregadas y doscientas pendientes tiene un índice de doscientas
-- entradas, no de diez millones. Esa es la diferencia entre una cola que escala
-- y una que se degrada con el histórico.
CREATE INDEX deliveries_claim_idx
    ON deliveries (next_attempt, id)
    WHERE status = 'pending';

CREATE INDEX deliveries_endpoint_idx ON deliveries (endpoint_id, created_at DESC);

-- El índice del recuperador de huérfanas (§6.4). También parcial, y por el mismo
-- motivo: las in_flight son siempre unas pocas, y el barrido periódico tiene que
-- costar lo que cuestan ellas, no lo que ocupa el histórico.
CREATE INDEX deliveries_reaper_idx
    ON deliveries (claimed_at)
    WHERE status = 'in_flight';

CREATE TABLE delivery_attempts (
    id           BIGSERIAL PRIMARY KEY,
    delivery_id  TEXT        NOT NULL REFERENCES deliveries(id) ON DELETE CASCADE,
    number       INTEGER     NOT NULL,
    status_code  INTEGER     NOT NULL,
    latency_ms   BIGINT      NOT NULL,
    error        TEXT        NOT NULL DEFAULT '',
    attempted_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX delivery_attempts_delivery_idx ON delivery_attempts (delivery_id, number);

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS delivery_attempts;
DROP TABLE IF EXISTS deliveries;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS endpoints;
-- +goose StatementEnd
```

### 6.3 El almacén de PostgreSQL

Y aquí se ve por qué la Fase 02 insistió tanto en declarar las interfaces en el
consumidor: **`opsreport.Service` no cambia ni una línea.**

```go
// services/opsreport/internal/postgres/workitem.go

// Package postgres implementa los almacenes de OpsReport sobre PostgreSQL.
//
// Como en la Fase 02, este paquete NO importa internal/opsreport: satisface sus
// interfaces por tener los métodos, y nada más. Cambiar de memstore a postgres
// es cambiar una línea en main.
package postgres

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"

	"github.com/meridian/opsreport/internal/workitem"
)

type WorkItemStore struct {
	db *sql.DB
}

func NewWorkItemStore(db *sql.DB) *WorkItemStore { return &WorkItemStore{db: db} }

// ErrNotFound es el vocabulario de este paquete. El servicio lo traduce al suyo
// con errors.Is, igual que hacía con memstore (Fase 03).
var ErrNotFound = errors.New("la fila no existe")

// Las consultas van como constantes de paquete, no embebidas en el método.
// Se leen mejor, se pueden pegar en psql tal cual, y el diff de un cambio de
// consulta no se mezcla con el de la lógica.
const insertWorkItemSQL = `
INSERT INTO work_items (
    id, external_reference, kind, description, priority, status, created_at
) VALUES ($1, $2, $3, $4, $5, $6, $7)`

func (s *WorkItemStore) Save(ctx context.Context, q DBTX, item workitem.WorkItem) error {
	_, err := q.ExecContext(ctx, insertWorkItemSQL,
		item.ID, item.ExternalReference, item.Kind, item.Description,
		item.Priority, item.Status, item.CreatedAt)

	if err != nil {
		// La traducción de errores del driver ocurre AQUÍ, en la frontera.
		// Un pgconn.PgError NO debe llegar al servicio ni al handler: filtra el
		// motor de base de datos hacia arriba y acopla capas que no deberían.
		return translateError(err)
	}
	return nil
}

const selectWorkItemSQL = `
SELECT id, external_reference, kind, description, priority, status,
       created_at, started_at, finished_at, failure_reason
FROM work_items
WHERE id = $1`

func (s *WorkItemStore) FindByID(ctx context.Context, q DBTX, id string) (workitem.WorkItem, error) {
	row := q.QueryRowContext(ctx, selectWorkItemSQL, id)

	item, err := scanWorkItem(row)
	if errors.Is(err, sql.ErrNoRows) {
		// sql.ErrNoRows es el centinela de la stdlib para "QueryRow no encontró
		// nada". Se traduce al vocabulario del paquete y se conserva la causa.
		return workitem.WorkItem{}, fmt.Errorf("%w: work item %s", ErrNotFound, id)
	}
	if err != nil {
		return workitem.WorkItem{}, fmt.Errorf("leyendo work item %s: %w", id, err)
	}
	return item, nil
}

// rowScanner unifica *sql.Row y *sql.Rows, que tienen el mismo Scan pero no
// comparten interfaz en la stdlib. Cuatro líneas y evita duplicar el escaneo.
type rowScanner interface {
	Scan(dest ...any) error
}

// scanWorkItem es el único sitio donde se mapea la fila al struct. Que esté en
// un solo sitio es lo que impide que la consulta de listado y la de detalle
// diverjan en el orden de las columnas — que es un bug silencioso y muy feo:
// compila, corre, y pone la descripción en el campo del estado.
func scanWorkItem(row rowScanner) (workitem.WorkItem, error) {
	var (
		item       workitem.WorkItem
		// Las columnas NULLABLE necesitan un tipo que sepa representar NULL.
		// sql.NullTime es el envoltorio de la stdlib; su alternativa es *time.Time,
		// y las dos son válidas. Este curso usa sql.NullX en el escaneo y
		// convierte al tipo del dominio inmediatamente, para que el NULL no se
		// propague hacia adentro.
		startedAt  sql.NullTime
		finishedAt sql.NullTime
	)

	err := row.Scan(
		&item.ID, &item.ExternalReference, &item.Kind, &item.Description,
		&item.Priority, &item.Status, &item.CreatedAt,
		&startedAt, &finishedAt, &item.FailureReason,
	)
	if err != nil {
		return workitem.WorkItem{}, err
	}

	if startedAt.Valid {
		item.StartedAt = startedAt.Time
	}
	if finishedAt.Valid {
		item.FinishedAt = finishedAt.Time
	}
	return item, nil
}

const listQueuedSQL = `
SELECT id, external_reference, kind, description, priority, status,
       created_at, started_at, finished_at, failure_reason
FROM work_items
WHERE status = $1
ORDER BY priority DESC, created_at ASC
LIMIT $2`

func (s *WorkItemStore) ListByStatus(ctx context.Context, q DBTX, status workitem.Status, limit int) ([]workitem.WorkItem, error) {
	rows, err := q.QueryContext(ctx, listQueuedSQL, status, limit)
	if err != nil {
		return nil, fmt.Errorf("listando work items por estado %s: %w", status, err)
	}
	defer rows.Close()   // ← inmediatamente, y siempre

	// Pre-dimensionado con el límite conocido: es B-04 de la Fase 01 aplicado.
	items := make([]workitem.WorkItem, 0, limit)
	for rows.Next() {
		item, err := scanWorkItem(rows)
		if err != nil {
			return nil, fmt.Errorf("escaneando fila: %w", err)
		}
		items = append(items, item)
	}

	// rows.Err() es OBLIGATORIO y es el error olvidado número uno de esta fase.
	// El bucle también termina cuando hay un fallo de red a mitad de la lectura,
	// y sin esta comprobación devolverías un resultado PARCIAL sin error — que
	// es peor que fallar.
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("recorriendo work items: %w", err)
	}
	return items, nil
}
```

Y la traducción de errores del driver, que es una pieza que merece existir:

```go
// services/opsreport/internal/postgres/errors.go
package postgres

import (
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5/pgconn"
)

// Los códigos de error de PostgreSQL son estándar (SQLSTATE) y están
// documentados. Traducirlos por código y no por texto del mensaje es lo correcto:
// el texto depende del idioma del servidor y de la versión.
const (
	pgUniqueViolation     = "23505"
	pgForeignKeyViolation = "23503"
	pgCheckViolation      = "23514"
	pgSerializationFail   = "40001"
	pgDeadlockDetected    = "40P01"
)

var (
	ErrDuplicate    = errors.New("la fila ya existe")
	ErrInvalidRef   = errors.New("referencia a una fila inexistente")
	ErrConstraint   = errors.New("la fila viola una restricción del esquema")
	ErrRetryable    = errors.New("conflicto de concurrencia; se puede reintentar")
)

func translateError(err error) error {
	if err == nil {
		return nil
	}

	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) {
		return err
	}

	switch pgErr.Code {
	case pgUniqueViolation:
		// ConstraintName dice CUÁL restricción se violó, y eso permite dar un
		// mensaje útil en vez de "algo está duplicado".
		return fmt.Errorf("%w (%s): %v", ErrDuplicate, pgErr.ConstraintName, err)
	case pgForeignKeyViolation:
		return fmt.Errorf("%w (%s): %v", ErrInvalidRef, pgErr.ConstraintName, err)
	case pgCheckViolation:
		return fmt.Errorf("%w (%s): %v", ErrConstraint, pgErr.ConstraintName, err)
	case pgSerializationFail, pgDeadlockDetected:
		// Estos DOS son reintentables por definición: PostgreSQL abortó la
		// transacción para romper un conflicto, y volver a intentarla es la
		// respuesta correcta. Distinguirlos del resto es lo que permite un
		// reintento automático que no sea temerario.
		return fmt.Errorf("%w: %v", ErrRetryable, err)
	default:
		return err
	}
}
```

> 💡 **Traducir por código SQLSTATE y no por texto** es la diferencia entre un
> manejo de errores que sobrevive a una actualización del servidor y uno que se
> rompe cuando alguien cambia `lc_messages`.

### 6.4 `SELECT ... FOR UPDATE SKIP LOCKED`: la joya de la fase

Este es el mecanismo que convierte una tabla en una cola de trabajo distribuida
correcta, y paga la deuda del `time.Timer` por entrega de la Fase 06.

**El problema.** Tres instancias de EventRelay corren a la vez. Las tres consultan
"dame las entregas pendientes cuyo momento ya llegó". Sin coordinación, las tres
cogen las mismas y el socio recibe el evento tres veces.

**Lo que la gente intenta primero**, y por qué falla:

```sql
-- ❌ Intento 1: leer y después marcar. Hay una carrera entre las dos sentencias.
SELECT id FROM deliveries WHERE status = 'pending' AND next_attempt <= now() LIMIT 10;
UPDATE deliveries SET status = 'in_flight' WHERE id = ANY($1);

-- ❌ Intento 2: FOR UPDATE. Correcto pero SERIALIZA: la instancia B espera a
--    que A termine su transacción, en vez de coger otras filas.
SELECT id FROM deliveries WHERE status = 'pending' LIMIT 10 FOR UPDATE;
```

**La solución:**

```sql
-- services/eventrelay/internal/postgres/queries.sql (fragmento)
--
-- SKIP LOCKED: si una fila ya está bloqueada por otra transacción, NO esperes:
-- SÁLTALA y coge la siguiente. Cada instancia se lleva un lote distinto, sin
-- coordinación, sin bloqueo distribuido y sin cola externa.
--
-- El UPDATE ... FROM (SELECT ...) hace la reclamación y la marca en UNA
-- sentencia atómica, y el RETURNING devuelve lo reclamado. Es el patrón
-- completo en una consulta.
UPDATE deliveries d
SET status = 'in_flight',
    attempts = d.attempts + 1,
    -- Se sella la reclamación con la hora. Es lo único que el recuperador de
    -- §6.4 necesita para decidir si esta entrega sigue viva o su instancia murió.
    claimed_at = $1
FROM (
    SELECT id
    FROM deliveries
    WHERE status = 'pending'
      AND next_attempt <= $1
    ORDER BY next_attempt
    LIMIT $2
    FOR UPDATE SKIP LOCKED
) AS claimed
WHERE d.id = claimed.id
RETURNING d.id, d.event_id, d.endpoint_id, d.status, d.attempts,
          d.max_attempts, d.next_attempt, d.last_error, d.created_at,
          d.claimed_at;
```

```go
// services/eventrelay/internal/postgres/delivery.go

// ClaimPending reclama hasta `limit` entregas listas para intentar, marcándolas
// como in_flight de forma atómica.
//
// Varias instancias pueden llamar a esto simultáneamente sin coordinación
// externa: SKIP LOCKED garantiza que cada fila la reclama una sola.
//
// Esto sustituye al time.Timer por entrega de la Fase 06 (💸 pagada). Ventajas
// sobre aquello: sobrevive a reinicios, escala a N instancias, y el estado de la
// cola es consultable con una SELECT en vez de estar en la memoria de un proceso.
func (s *DeliveryStore) ClaimPending(ctx context.Context, now time.Time, limit int) ([]relay.Delivery, error) {
	rows, err := s.db.QueryContext(ctx, claimPendingSQL, now, limit)
	if err != nil {
		return nil, fmt.Errorf("reclamando entregas: %w", translateError(err))
	}
	defer rows.Close()

	claimed := make([]relay.Delivery, 0, limit)
	for rows.Next() {
		d, err := scanDelivery(rows)
		if err != nil {
			return nil, fmt.Errorf("escaneando entrega reclamada: %w", err)
		}
		claimed = append(claimed, d)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("recorriendo entregas reclamadas: %w", err)
	}
	return claimed, nil
}
```

> ⚠️ **El problema que `SKIP LOCKED` no resuelve: la entrega huérfana.** Si la
> instancia que reclamó una entrega muere antes de terminarla, esa fila se queda en
> `in_flight` para siempre. La solución es un **recuperador**: una consulta
> periódica que devuelve a `pending` lo que lleva demasiado tiempo `in_flight`.
>
> ```sql
> UPDATE deliveries
> SET status = 'pending', next_attempt = now()
> WHERE status = 'in_flight'
>   AND claimed_at < now() - INTERVAL '5 minutes';
> ```
>
> Por eso la tabla lleva la columna `claimed_at` y el índice parcial
> `deliveries_reaper_idx` que viste en §6.2, y por eso la consulta de reclamación
> la sella: **es exactamente el tipo de detalle que separa una cola de juguete de
> una que funciona**, y se paga en el esquema, no en el código.
>
> Dos reglas al configurarlo, y las dos se aprenden rompiéndolas:
>
> - **El plazo del recuperador tiene que ser mayor que el plazo máximo de una
>   entrega.** Si no, recuperas trabajo que sigue en curso y entregas dos veces.
>   Con el `timeout` de cliente que la Fase 10 le pone a EventRelay, cinco minutos
>   sobra de largo.
> - **Recuperar no es reintentar gratis.** La fila vuelve a `pending` con su
>   `attempts` ya incrementado, porque el intento ocurrió aunque no sepamos cómo
>   acabó. Restarlo convertiría una instancia que muere en bucle en entregas
>   infinitas contra el socio.
>
> El recuperador es un trabajo periódico, y el sitio donde se programa de verdad
> —con su `context`, su cancelación y su solapamiento— es la Fase 13.

📖 En Java esto es lo que hace Spring Integration con `JdbcChannelMessageStore`, o
lo que resuelves con una cola de verdad (Kafka, Rabbit). **La cola en base de
datos es una decisión deliberada** y tiene su punto de ruptura; lo discutimos en
el ⚖️ veredicto de la Fase 13.

### 6.5 Mini proyecto: `tx-lab`

Transacciones, aislamiento y el laboratorio de bloqueos.

```go
// labs/tx-lab/tx.go
package txlab

// El patrón del curso, en una función. Todo caso de uso transaccional tiene esta
// forma, y no hay gestor de transacciones ni anotación.
func WithTx(ctx context.Context, db *sql.DB, opts *sql.TxOptions, fn func(tx *sql.Tx) error) error {
	tx, err := db.BeginTx(ctx, opts)
	if err != nil {
		return fmt.Errorf("abriendo transacción: %w", err)
	}

	// Rollback diferido SIEMPRE. Después de un Commit exitoso devuelve
	// sql.ErrTxDone, que se ignora a propósito. Cubre el return temprano, el
	// error, y el panic.
	defer func() {
		if rbErr := tx.Rollback(); rbErr != nil && !errors.Is(rbErr, sql.ErrTxDone) {
			// Un Rollback que falla es grave: la transacción puede seguir
			// abierta ocupando una conexión y bloqueos.
			log.Printf("ERROR: rollback falló: %v", rbErr)
		}
	}()

	if err := fn(tx); err != nil {
		return err   // el defer hace rollback
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("confirmando transacción: %w", err)
	}
	return nil
}

// WithTxRetry añade reintento para los conflictos de serialización, que en
// SERIALIZABLE son NORMALES, no excepcionales: PostgreSQL aborta una de las dos
// transacciones en conflicto y espera que la reintentes.
//
// Es la parte que la gente olvida al subir el nivel de aislamiento, y produce
// errores esporádicos en producción que nadie sabe explicar.
func WithTxRetry(ctx context.Context, db *sql.DB, maxAttempts int, fn func(tx *sql.Tx) error) error {
	opts := &sql.TxOptions{Isolation: sql.LevelSerializable}

	var lastErr error
	for attempt := 1; attempt <= maxAttempts; attempt++ {
		err := WithTx(ctx, db, opts, fn)
		if err == nil {
			return nil
		}
		if !errors.Is(err, ErrRetryable) {
			return err
		}

		lastErr = err
		// Retroceso con jitter, para que dos transacciones en conflicto no
		// vuelvan a chocar a la vez. math/rand/v2 desde la Fase 08.
		backoff := time.Duration(attempt*attempt) * 10 * time.Millisecond
		jitter := time.Duration(rand.N(int64(backoff / 2)))

		select {
		case <-time.After(backoff + jitter):
		case <-ctx.Done():
			return ctx.Err()
		}
	}
	return fmt.Errorf("agotados %d intentos: %w", maxAttempts, lastErr)
}
```

Y los niveles de aislamiento, demostrados en vez de explicados:

```go
// DemoLostUpdate muestra la actualización perdida en READ COMMITTED (el valor
// por defecto de PostgreSQL) y cómo se evita de tres formas distintas.
func DemoLostUpdate(ctx context.Context, db *sql.DB) {
	// Dos transacciones leen el mismo contador, suman 1, y escriben.
	// En READ COMMITTED, el resultado es 1, no 2: una pisa a la otra.

	// Solución 1: UPDATE atómico. SIEMPRE la primera opción, y la que la gente
	// olvida por venir de un mundo de objetos.
	//   UPDATE counters SET value = value + 1 WHERE id = $1

	// Solución 2: SELECT ... FOR UPDATE. Bloquea la fila hasta el commit.
	//   SELECT value FROM counters WHERE id = $1 FOR UPDATE

	// Solución 3: SERIALIZABLE + reintento. Correcto y más caro; se usa cuando
	// el invariante abarca VARIAS filas y no cabe en un UPDATE.
}
```

> 🧭 **Regla del proyecto sobre aislamiento.** El valor por defecto
> (`READ COMMITTED`) es el correcto para el 95% de los casos. Se sube a
> `SERIALIZABLE` cuando el invariante abarca varias filas y no se puede expresar
> como un `UPDATE` atómico o un `FOR UPDATE` — el cierre contable de la Fase 13 es
> el caso. **Y subir el aislamiento sin implementar el reintento es un bug**, no
> una mejora de rigor.

📖 En Java, `@Transactional(isolation = SERIALIZABLE)` tiene exactamente el mismo
requisito de reintento, y Spring Retry existe en buena parte por eso. La diferencia
es que aquí el bucle de reintento es visible en el código.

### 6.6 Mini proyecto: `cursor-vs-offset`

La paginación que se degrada y la que no.

```sql
-- ❌ OFFSET: PostgreSQL tiene que LEER Y DESCARTAR las primeras N filas.
-- En la página 1, lee 50. En la página 2000, lee 100.050 y tira 100.000.
SELECT * FROM work_items ORDER BY created_at DESC LIMIT 50 OFFSET 100000;

-- ✅ Cursor: la posición se codifica en el WHERE, y el índice lleva directo.
-- El coste es el MISMO en la página 1 que en la 2000.
SELECT * FROM work_items
WHERE (created_at, id) < ($1, $2)     -- la tupla del último visto
ORDER BY created_at DESC, id DESC
LIMIT 50;
```

**La comparación de tuplas `(created_at, id) < ($1, $2)` es la clave**, y casi
nadie la conoce: PostgreSQL compara lexicográficamente y puede usar el índice
compuesto `(created_at DESC, id DESC)` directamente. La alternativa escrita a mano
—`created_at < $1 OR (created_at = $1 AND id < $2)`— es equivalente y el
planificador la aprovecha peor.

```go
// services/opsreport/internal/postgres/pagination.go

// Cursor codifica la posición de la última fila devuelta. Se serializa en base64
// para que el cliente lo trate como opaco: si parece un token, nadie intenta
// construirlo a mano, y podemos cambiar su formato sin romper a nadie.
type Cursor struct {
	CreatedAt time.Time `json:"c"`
	ID        string    `json:"i"`
}

func (c Cursor) Encode() string {
	raw, _ := json.Marshal(c)
	return base64.RawURLEncoding.EncodeToString(raw)
}

func DecodeCursor(s string) (Cursor, error) {
	raw, err := base64.RawURLEncoding.DecodeString(s)
	if err != nil {
		return Cursor{}, fmt.Errorf("cursor inválido: %w", err)
	}
	var c Cursor
	if err := json.Unmarshal(raw, &c); err != nil {
		return Cursor{}, fmt.Errorf("cursor inválido: %w", err)
	}
	return c, nil
}
```

> 📐 **Cómo se mide.** Entrada **B-15**: *paginación por cursor frente a `OFFSET` a
> las 100.000 filas*. Se mide en las páginas 1, 100, 1.000 y 2.000, con
> `EXPLAIN ANALYZE` de las dos consultas. La hipótesis es falsable y está en
> `BENCHMARKS.md`: *"la latencia del cursor se mantiene constante mientras la de
> `OFFSET` crece linealmente con el desplazamiento"*.
>
> **Y el veredicto tiene que decir qué se pierde con el cursor**, porque se pierde
> algo real: **no se puede saltar a la página 47**, y no hay número total de
> páginas sin un `COUNT(*)` aparte. Si tu interfaz tiene paginación numerada,
> `OFFSET` es la respuesta correcta y hay que decirlo.

### 6.7 `pgx` nativo frente a `database/sql`

```go
// Opción A: database/sql con el driver de pgx en modo stdlib.
import _ "github.com/jackc/pgx/v5/stdlib"
db, err := sql.Open("pgx", dsn)

// Opción B: pgx nativo, sin pasar por database/sql.
import "github.com/jackc/pgx/v5/pgxpool"
pool, err := pgxpool.New(ctx, dsn)
```

**Qué gana cada uno**, y esto hay que decirlo con precisión:

`database/sql` te da una **interfaz estándar**: el mismo código funciona con
PostgreSQL, MySQL y SQLite cambiando el driver, los tests de contrato se comparten,
y cualquier librería del ecosistema que espere `*sql.DB` funciona.

`pgx` nativo te da el **protocolo binario de PostgreSQL sin traducción**, soporte
de tipos nativo (arrays, `JSONB`, `hstore`, tipos compuestos) sin envoltorios,
`CopyFrom` para carga masiva —que es órdenes de magnitud más rápido que un
`INSERT` por fila—, y `LISTEN/NOTIFY`.

> 📐 **Cómo se mide.** Entrada **B-13**: *`database/sql` frente a `pgx` nativo*,
> sobre la misma consulta de listado, con 10, 100 y 1.000 filas, y con y sin
> `CopyFrom` para la inserción masiva.
>
> **El veredicto que el curso sostiene:** usa `database/sql` con el driver de pgx
> por defecto, **porque la portabilidad y el ecosistema valen más que la diferencia
> en la mayoría de las rutas**; y usa `pgx` nativo donde el tipo de dato o el
> volumen lo justifiquen — `CopyFrom` en la ingesta de movimientos de
> ClearingHouse (Fase 13) es el caso claro.
>
> Meridian usa `database/sql` en OpsReport y EventRelay, y `pgx` nativo en la
> ingesta de ClearingHouse. **Esa asimetría es la decisión, y está justificada por
> la medición, no por gusto.**

### 6.8 El debate del ORM, con los tres medidos

La pregunta que toda persona que viene de JPA hace en la primera semana: *"¿y el
ORM?"*. La respondemos midiendo, sobre **la misma consulta**: listar work items por
estado con paginación.

**SQL a mano** (lo que hemos escrito):

```go
const listQueuedSQL = `SELECT ... FROM work_items WHERE status = $1 ...`

func (s *WorkItemStore) ListByStatus(ctx context.Context, q DBTX, status workitem.Status, limit int) ([]workitem.WorkItem, error) {
	// ... ~25 líneas, incluido el escaneo
}
```

**`sqlc`** — genera código Go **a partir del SQL**:

```sql
-- query.sql
-- name: ListWorkItemsByStatus :many
SELECT * FROM work_items
WHERE status = $1
ORDER BY priority DESC, created_at ASC
LIMIT $2;
```

```bash
sqlc generate   # produce el struct, el método y el escaneo, tipados
```

```go
items, err := queries.ListWorkItemsByStatus(ctx, db.ListWorkItemsByStatusParams{
	Status: string(status),
	Limit:  int32(limit),
})
```

**`GORM`** — el ORM completo, el más parecido a JPA:

```go
var items []WorkItemModel
err := gormDB.WithContext(ctx).
	Where("status = ?", status).
	Order("priority DESC, created_at ASC").
	Limit(limit).
	Find(&items).Error
```

**La comparación, sobre este caso concreto:**

| | SQL a mano | `sqlc` | `GORM` |
|---|---|---|---|
| Líneas escritas a mano por consulta | ~25 | ~6 (el SQL) | ~5 |
| Código generado que hay que commitear | 0 | sí, y mucho | 0 |
| Paso en el build | no | **sí** (`sqlc generate`) | no |
| Errores de tipo detectados en compilación | los del escaneo | **todos, incluido el SQL** | **ninguno**: las cadenas se validan en ejecución |
| ¿Sabes qué SQL se ejecuta? | sí, lo escribiste | sí, lo escribiste | **no siempre** |
| Riesgo de N+1 | bajo (sin *lazy loading*) | bajo | **alto** (precarga implícita, asociaciones) |
| Consulta compleja (CTE, ventana, `SKIP LOCKED`) | natural | **natural** | se acaba escribiendo SQL crudo igual |
| Curva para quien viene de JPA | media | media | **baja** |
| Refactor de renombrar una columna | compila igual, falla en ejecución | **falla en `sqlc generate`** | falla en ejecución |

> 📐 **Cómo se mide.** Entrada **B-14**: *SQL a mano frente a `sqlc` frente a
> `GORM`*, la misma consulta, 1.000 filas, con `-benchmem`. **Los tres se miden**,
> como manda `prompts/formato-de-benchmarks.md` §3 regla 1: si el curso menciona GORM, GORM
> se mide.
>
> Lo que la medición va a mostrar —y hay que reportarlo aunque no sea el titular—
> es que la diferencia de **tiempo** entre SQL a mano y `sqlc` es despreciable
> (`sqlc` genera el mismo código que escribirías), y que GORM añade una sobrecarga
> por reflexión que se nota más en `allocs/op` que en `ns/op`. **Pero el argumento
> de esta sección no es el rendimiento**, y el veredicto tiene que decirlo.

> ⚖️ **El veredicto del curso, con sus condiciones.**
>
> **SQL a mano** es la elección de Meridian para OpsReport y EventRelay: consultas
> pocas y no triviales (`SKIP LOCKED`, índices parciales, paginación por tupla),
> donde escribir el SQL **es** el trabajo y generarlo no ahorra nada.
>
> **`sqlc` es la recomendación por defecto para un proyecto nuevo con muchas
> consultas CRUD**, y el curso lo dice aunque no lo use: escribes SQL de verdad,
> el generador valida las consultas **contra el esquema en tiempo de compilación**
> —que es más de lo que JPA hace— y el código generado es el que escribirías.
> El precio es un paso en el build y código generado en el repositorio.
>
> **GORM** se descarta como opción por defecto, y el motivo no es que sea malo:
> es que **reproduce el modelo mental de JPA sin sus veinte años de madurez** — el
> *lazy loading*, las asociaciones implícitas, las convenciones mágicas de
> nombrado— y eso empuja a quien viene de Java hacia los errores que en Java ya
> sabe evitar, en un ecosistema con menos herramientas para detectarlos. Si tu
> equipo va a escribir un CRUD grande y viene de JPA, GORM es defendible; y si lo
> eliges, desactiva la precarga implícita y revisa el SQL que genera.

**Y el diccionario que cierra el debate:**

📖 **`@Entity`** no tiene equivalente: no hay entidades gestionadas, no hay
*dirty checking*, no hay caché de primer nivel. Un struct leído de la base de
datos es un valor, y si lo modificas no pasa nada hasta que ejecutes un `UPDATE`.
**Eso elimina de un plumazo `LazyInitializationException`, el detach/merge, y la
pregunta de si esta entidad está gestionada** — y a cambio, tienes que escribir el
`UPDATE`.

📖 **El caché de primer nivel** es la diferencia conceptual más grande y conviene
entenderla: en JPA, leer dos veces la misma entidad en la misma transacción
devuelve **el mismo objeto**. Aquí devuelve dos structs distintos con el mismo
contenido. Menos mágico, y sin la clase de bug donde modificas un objeto en un
sitio y aparece cambiado en otro.

📖 **El N+1** existe igual, y se produce igual: un bucle que consulta por cada
elemento. La diferencia es que en JPA lo produce el *lazy loading* **sin que
escribas el bucle** — el bucle está escondido en el `getter` de una colección. En
Go, si hay N+1, es porque escribiste el bucle, y eso lo hace visible en la revisión
de código.

**Y una omisión que conviene declarar aquí, antes de que la Fase 11 la cobre.**

Este debate compara tres formas de hablar con PostgreSQL **asumiendo un modelo
relacional**. Hay una cuarta que no entra: **`JSONB`**. PostgreSQL guarda
documentos con índices GIN, consultas por camino (`payload -> 'address' ->> 'city'`)
y operadores de contención (`@>`), y `pgx` lo soporta de forma nativa sin
envoltorios. Para buena parte de lo que se resuelve con una base documental, **una
columna `JSONB` en una base que ya tienes montada es la respuesta correcta**, y no
tener que operar un segundo motor vale más que casi cualquier ventaja de modelado.

El curso no lo usa —AtlasSync va a MongoDB en la Fase 11— y esa decisión se toma
**allí, con el argumento delante**, no aquí por omisión. El desafío D1 de la Fase
11 pide precisamente modelar el catálogo de países en `JSONB` y comparar. Si al
hacerlo te sale que PostgreSQL bastaba, **ese es el resultado correcto y hay que
escribirlo**: es exactamente el tipo de conclusión que la regla 5 de honestidad del
banco de pruebas obliga a publicar.

> 🧭 **La regla que se lleva de aquí.** Antes de añadir un motor nuevo a la
> plataforma, comprueba si el que ya operas cubre el caso. El coste de un motor no
> es la librería: es la copia de seguridad, el monitoreo, la rotación de guardia,
> el parcheo y la persona que sepa depurarlo a las tres de la mañana.

### 6.9 ClearingHouse nace: `storeagent` con SQLite

El tercer servicio del curso, y su primera pieza vive en el borde: un mini-PC en
cada una de las ciento cuarenta tiendas de Meridian, que registra movimientos de
caja **con o sin red**.

**Por qué SQLite aquí no es un ejemplo forzado:** no hay servidor de base de
datos en una tienda, el enlace se cae, y el punto de venta no puede dejar de
vender. Un archivo local con transacciones ACID es exactamente la respuesta. Y un
binario estático de quince megas frente a un JAR con su JVM, en un mini-PC, es
exactamente donde Go gana.

```go
// services/storeagent/internal/sqlite/db.go

// Package sqlite abre y configura la base local del agente de tienda.
package sqlite

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	// modernc.org/sqlite es una traducción de SQLite a Go puro: SIN cgo.
	// Eso permite compilación cruzada (Fase 00) y un binario estático, que es
	// justo lo que hace desplegable el agente en ciento cuarenta mini-PC.
	//
	// La alternativa, mattn/go-sqlite3, usa cgo: es más rápida y obliga a tener
	// toolchain de C para cada plataforma destino. El intercambio se mide en el
	// ejercicio 26.
	_ "modernc.org/sqlite"
)

func Open(ctx context.Context, path string) (*sql.DB, error) {
	// Los PRAGMA van en la cadena de conexión porque SQLite los aplica POR
	// CONEXIÓN, no por base de datos. Configurarlos con un Exec después de
	// abrir solo afecta a la conexión que lo ejecutó — que con un pool es una
	// de varias, y ese es un bug muy desconcertante.
	dsn := path + "?" +
		"_pragma=journal_mode(WAL)" +      // lectores y escritor concurrentes
		"&_pragma=busy_timeout(5000)" +    // esperar 5s en vez de fallar al instante
		"&_pragma=synchronous(NORMAL)" +   // durabilidad razonable con WAL
		"&_pragma=foreign_keys(ON)"        // ⚠️ SQLite las ignora si no se activan

	db, err := sql.Open("sqlite", dsn)
	if err != nil {
		return nil, fmt.Errorf("abriendo %s: %w", path, err)
	}

	// ⚠️ LA CONFIGURACIÓN QUE HAY QUE ENTENDER, y es lo contrario de PostgreSQL:
	//
	// SQLite admite MUCHOS lectores concurrentes y UN SOLO escritor. Con un pool
	// de N conexiones escribiendo, obtienes SQLITE_BUSY constantemente.
	//
	// La configuración correcta para un agente que escribe mucho:
	//   MaxOpenConns(1) → serializa TODO en el proceso, cero SQLITE_BUSY.
	//
	// Se paga en que las lecturas también se serializan. Para el agente —un
	// proceso, escrituras frecuentes, lecturas escasas— compensa. Para una
	// aplicación de lectura intensiva sobre SQLite, la respuesta sería otra:
	// dos pools, uno de escritura con 1 conexión y otro de lectura con N.
	db.SetMaxOpenConns(1)
	db.SetMaxIdleConns(1)
	db.SetConnMaxLifetime(0) // sin límite: es un archivo local, no hay failover

	pingCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	if err := db.PingContext(pingCtx); err != nil {
		return nil, fmt.Errorf("verificando %s: %w", path, err)
	}
	return db, nil
}
```

> ⚠️ **Las cuatro diferencias de SQLite que muerden de verdad**, y no son las que
> la gente espera:
>
> **1. Tipado dinámico.** SQLite tiene *afinidad* de tipo, no tipos: puedes
> insertar el texto `"abc"` en una columna `INTEGER` y lo acepta. Las restricciones
> `CHECK` son tu única defensa, y hay que ponerlas.
>
> **2. `ALTER TABLE` es muy limitado.** No hay `ALTER COLUMN`, no hay `DROP
> CONSTRAINT`. Cambiar una columna es: crear tabla nueva, copiar, borrar la vieja,
> renombrar. Las migraciones de SQLite se escriben así y hay que saberlo antes de
> diseñar el esquema.
>
> **3. Sin `TIMESTAMPTZ`.** No hay tipo fecha: se guarda texto ISO-8601 o un entero
> Unix. **La zona horaria es enteramente tu responsabilidad**, y enlaza con §6.10.
>
> **4. Las claves foráneas están DESACTIVADAS por defecto**, por compatibilidad
> histórica. Sin `PRAGMA foreign_keys(ON)`, tus `REFERENCES` son documentación.

Y la herramienta de línea de comandos, que es el eje transversal del curso:

```go
// services/storeagent/cmd/storeagent/main.go

// Command storeagent registra movimientos de caja en la tienda y los sincroniza
// con ClearingHouse cuando hay red.
//
// Subcomandos:
//   storeagent record   -kind SALE -amount 145900 -currency COP
//   storeagent list     -since 2026-09-11 -status pending
//   storeagent sync     -endpoint https://clearing.meridian.internal
//   storeagent status
//
// Se usa `flag` de la stdlib con un FlagSet por subcomando, que es el patrón
// para herramientas multi-comando sin dependencias. cobra se evalúa contra esto
// en la Fase 13.
func main() {
	if len(os.Args) < 2 {
		usage()
		os.Exit(2)
	}

	ctx, stop := signal.NotifyContext(context.Background(),
		syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	var err error
	switch os.Args[1] {
	case "record":
		err = runRecord(ctx, os.Args[2:])
	case "list":
		err = runList(ctx, os.Args[2:])
	case "sync":
		err = runSync(ctx, os.Args[2:])
	case "status":
		err = runStatus(ctx, os.Args[2:])
	case "-h", "--help", "help":
		usage()
		return
	default:
		fmt.Fprintf(os.Stderr, "subcomando desconocido: %q\n\n", os.Args[1])
		usage()
		os.Exit(2)
	}

	if err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
}
```

> 💡 **`signal.NotifyContext`** (Go 1.16) sustituye al `signal.Notify` + canal +
> `select` de la Fase 07 en una línea: devuelve un contexto que se cancela con la
> señal. Es otra adopción de la Fase 08 que aquí rinde. En un servidor con apagado
> complejo sigue haciendo falta el control fino; en una herramienta de línea de
> comandos, esto basta.

```sql
-- services/storeagent/migrations/001_create_movements.sql
-- +goose Up
CREATE TABLE movements (
    id            TEXT PRIMARY KEY,
    store_id      TEXT    NOT NULL,
    -- Sin TIMESTAMPTZ: se guarda ISO-8601 en UTC, SIEMPRE, y la conversión a la
    -- zona de la tienda ocurre en el borde. Ver §6.10.
    occurred_at   TEXT    NOT NULL,
    kind          TEXT    NOT NULL,
    -- El monto en unidad mínima (centavos), como entero. NUNCA float para
    -- dinero, y en SQLite con menos razón todavía porque REAL es IEEE 754.
    amount_minor  INTEGER NOT NULL,
    currency      TEXT    NOT NULL,
    -- Estado de sincronización: el agente marca lo que ya subió.
    synced_at     TEXT,
    -- Hash del contenido: permite que ClearingHouse detecte duplicados sin
    -- confiar en el identificador que generó el agente.
    content_hash  TEXT    NOT NULL,

    CHECK (kind IN ('SALE','REFUND','VOID','DEPOSIT','WITHDRAWAL')),
    CHECK (currency GLOB '[A-Z][A-Z][A-Z]'),
    CHECK (length(occurred_at) = 20)   -- 2026-09-11T08:14:02Z
);

CREATE INDEX movements_pending_idx ON movements (occurred_at) WHERE synced_at IS NULL;
CREATE UNIQUE INDEX movements_hash_idx ON movements (content_hash);
```

### 6.10 La zona horaria por tienda

Este es **el bug más caro que ClearingHouse puede tener**, y entra aquí porque el
esquema es donde se decide.

**El problema, con números:** el cierre del día 4 de septiembre en una tienda de
Bogotá (UTC−5) cubre de `2026-09-04T05:00:00Z` a `2026-09-05T05:00:00Z`. En Ciudad
de México (UTC−6) cubre de `2026-09-04T06:00:00Z` a `2026-09-05T06:00:00Z`. **Son
intervalos distintos.** Si el cierre usa un único rango UTC, una tienda pierde una
hora de movimientos y la otra la cuenta dos veces.

Y se pone peor: **México tiene horario de verano y Colombia no.** Un rango
calculado con un desplazamiento fijo falla dos veces al año, y falla exactamente
en las noches en las que nadie quiere depurar.

```go
// services/clearinghouse/internal/calendar/business_day.go

// Package calendar resuelve el día de negocio de una tienda a un intervalo UTC.
//
// Esta es la pieza que evita el error más caro de ClearingHouse. Se prueba con
// tiendas en Bogotá (sin horario de verano), Ciudad de México (con él) y Santiago
// (hemisferio sur, cambios invertidos).
package calendar

import (
	"fmt"
	"time"
)

// BusinessDayRange devuelve el intervalo [desde, hasta) en UTC que corresponde al
// día `day` en la zona horaria de la tienda.
//
// La zona se pasa como IANA ("America/Bogota"), NUNCA como un desplazamiento
// fijo ("-05:00"): el desplazamiento cambia con el horario de verano y la base de
// datos de zonas horarias lo sabe; una constante en tu código, no.
func BusinessDayRange(day time.Time, tz string) (from, to time.Time, err error) {
	loc, err := time.LoadLocation(tz)
	if err != nil {
		return time.Time{}, time.Time{}, fmt.Errorf("zona horaria %q desconocida: %w", tz, err)
	}

	y, m, d := day.Date()

	// Medianoche local del día, y medianoche local del siguiente.
	//
	// ⚠️ AddDate(0,0,1) y NO Add(24*time.Hour): en el día del cambio de horario,
	// el día tiene 23 o 25 horas. Sumar 24 horas fijas produce un intervalo
	// desplazado una hora exactamente en la noche en que nadie quiere depurar.
	start := time.Date(y, m, d, 0, 0, 0, 0, loc)
	end := start.AddDate(0, 0, 1)

	return start.UTC(), end.UTC(), nil
}
```

```go
// Y el test, que es lo que de verdad prueba que esto está bien:
func TestBusinessDayRange(t *testing.T) {
	tests := []struct {
		name       string
		day        string
		tz         string
		wantFrom   string
		wantTo     string
		wantHours  float64
	}{
		{
			name:      "Bogotá, día normal: UTC-5 todo el año",
			day:       "2026-09-04", tz: "America/Bogota",
			wantFrom:  "2026-09-04T05:00:00Z", wantTo: "2026-09-05T05:00:00Z",
			wantHours: 24,
		},
		{
			name:      "Ciudad de México, día normal",
			day:       "2026-09-04", tz: "America/Mexico_City",
			wantFrom:  "2026-09-04T06:00:00Z", wantTo: "2026-09-05T06:00:00Z",
			wantHours: 24,
		},
		{
			name:      "Santiago, día del cambio de horario: el día tiene 23 horas",
			day:       "2026-09-06", tz: "America/Santiago",
			wantHours: 23,   // ← el caso que Add(24*time.Hour) rompe
		},
	}
	// ...
}
```

> ⚠️ **Y el requisito de despliegue que se olvida:** `time.LoadLocation` lee la
> base de datos de zonas horarias **del sistema**. Una imagen `scratch` o
> `distroless` **no la trae**, y `LoadLocation` falla con *"unknown time zone"* en
> producción aunque funcionara en tu Mac.
>
> La solución en Go moderno es una línea:
> ```go
> import _ "time/tzdata"   // incrusta la base de datos en el binario (~450 KB)
> ```
> Cuesta 450 KB y elimina una clase entera de fallos de despliegue. **Lo hacemos
> en los binarios que resuelven zonas**, y lo volveremos a ver en la Fase 14.

### 6.11 Tests de integración con `testcontainers-go`

```go
//go:build integration

// services/opsreport/internal/postgres/store_integration_test.go
//
// El build tag mantiene esto FUERA de la suite rápida. `go test ./...` no lo
// compila siquiera; `go test -tags=integration ./...` sí. Esa separación es lo
// que permite que la suite unitaria siga tardando menos de un segundo.
package postgres_test

import (
	"context"
	"database/sql"
	"testing"
	"time"

	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/postgres"
	"github.com/testcontainers/testcontainers-go/wait"
)

// setupPostgres levanta un contenedor por PAQUETE, no por test: arrancar
// PostgreSQL cuesta un par de segundos y multiplicarlo por cuarenta tests es
// una suite que nadie corre.
//
// El aislamiento entre tests se consigue con transacciones que se revierten
// (§6.11) o con esquemas separados, no con contenedores separados.
func setupPostgres(t *testing.T) *sql.DB {
	t.Helper()
	ctx := context.Background()

	container, err := postgres.Run(ctx, "postgres:16-alpine",
		postgres.WithDatabase("meridian_test"),
		postgres.WithUsername("test"),
		postgres.WithPassword("test"),
		testcontainers.WithWaitStrategy(
			// Esperar a que el LOG diga que acepta conexiones, y dos veces:
			// PostgreSQL arranca, se reinicia para aplicar la inicialización, y
			// vuelve a arrancar. Esperar solo la primera produce tests
			// intermitentes que todo el mundo achaca a "cosas de Docker".
			wait.ForLog("database system is ready to accept connections").
				WithOccurrence(2).
				WithStartupTimeout(30*time.Second),
		),
	)
	if err != nil {
		t.Fatalf("levantando postgres: %v", err)
	}

	// t.Cleanup y no defer: se ejecuta aunque el test haga Fatal (Fase 04).
	t.Cleanup(func() {
		if err := container.Terminate(context.Background()); err != nil {
			t.Logf("terminando el contenedor: %v", err)
		}
	})

	dsn, err := container.ConnectionString(ctx, "sslmode=disable")
	if err != nil {
		t.Fatalf("obteniendo el dsn: %v", err)
	}

	db, err := sql.Open("pgx", dsn)
	if err != nil {
		t.Fatalf("abriendo la conexión: %v", err)
	}
	t.Cleanup(func() { db.Close() })

	// Las migraciones REALES, las mismas de producción. Un esquema de test
	// escrito a mano diverge del real, y entonces los tests de integración
	// prueban un esquema que no existe.
	if err := goose.Up(db, "../../migrations"); err != nil {
		t.Fatalf("aplicando migraciones: %v", err)
	}
	return db
}
```

**Y aquí se cobra la inversión de la Fase 04:** la suite de contrato del ejercicio
23 corre tal cual contra PostgreSQL.

```go
// La MISMA tabla de tests que se escribió para memstore, contra la
// implementación real. Sin cambiar una línea.
func TestPostgresWorkItemStore_Contract(t *testing.T) {
	db := setupPostgres(t)

	storetest.RunContractSuite(t, func(t *testing.T) storetest.Store {
		// Cada caso en su propia transacción, revertida al terminar: aislamiento
		// perfecto entre tests, sin recrear el esquema y sin contenedor nuevo.
		tx, err := db.Begin()
		if err != nil {
			t.Fatalf("abriendo transacción de test: %v", err)
		}
		t.Cleanup(func() { _ = tx.Rollback() })

		return postgres.NewWorkItemStoreTx(tx)
	})
}
```

> 🧪 **Prueba de fuego.** Corre la suite de contrato contra las dos
> implementaciones:
> ```bash
> go test ./internal/memstore -run Contract
> go test -tags=integration ./internal/postgres -run Contract
> ```
> **La mentira de la pantalla:** si las dos pasan, todavía puede haber divergencia.
> `memstore` ordena los resultados por iteración de mapa —aleatoria—, y PostgreSQL
> por el `ORDER BY`. Si tu suite de contrato no verifica el orden, ese contrato
> está incompleto. **Añade un caso que lo verifique y comprueba si `memstore`
> falla.** Si falla, acabas de encontrar una divergencia real entre tu doble y tu
> implementación, que es exactamente el error común #8 de la Fase 04.

#### Y aquí, y solo aquí, entra `testify/require`

Mira el `setupPostgres` de arriba: cinco bloques `if err != nil { t.Fatalf(...) }`
seguidos, todos diciendo lo mismo. En un test unitario ese ruido no existe porque
hay una o dos comprobaciones; en un arranque de integración hay ocho, y ninguna
aporta nada al leerlo.

```go
import "github.com/stretchr/testify/require"

func setupPostgres(t *testing.T) *sql.DB {
	t.Helper()
	ctx := context.Background()

	container, err := postgres.Run(ctx, "postgres:16-alpine" /* ... */)
	require.NoError(t, err, "levantando postgres")
	t.Cleanup(func() { _ = container.Terminate(context.Background()) })

	dsn, err := container.ConnectionString(ctx, "sslmode=disable")
	require.NoError(t, err, "obteniendo el dsn")

	db, err := sql.Open("pgx", dsn)
	require.NoError(t, err, "abriendo la conexión")
	t.Cleanup(func() { db.Close() })

	require.NoError(t, goose.Up(db, "../../migrations"), "aplicando migraciones")
	return db
}
```

> 🧭 **La regla del curso, y es estrecha a propósito.** `testify/require` **solo en
> tests de integración**, y solo para el andamiaje: levantar el contenedor, aplicar
> migraciones, abrir conexiones. **Las aserciones sobre el comportamiento siguen
> siendo `if got != want { t.Errorf(...) }`**, porque ahí el `want` explícito es lo
> que hace el test legible, y porque `require` aborta: una comprobación de
> comportamiento que aborta te oculta las tres que venían detrás.
>
> `require`, no `assert`: si el contenedor no levantó, seguir ejecutando solo
> produce una cascada de fallos que no dicen nada.
>
> Y **`testify/mock` y `testify/suite` no entran en el curso**. El primero compite
> con `go.uber.org/mock` (Fase 10) sin ninguna ventaja; el segundo reintroduce el
> `setUp`/`tearDown` de JUnit que Go ya resolvió con `t.Cleanup`, y volver a él es
> justo el reflejo que la Fase 04 desmonta.

🪞 **Tu instinto de Java dice** que si `require` mejora estas ocho líneas, mejorará
las doscientas del resto de la suite — es lo que hizo AssertJ en tu proyecto. **Y
esta vez se equivoca por un detalle de Go:** `require.Equal` compara con reflexión
y su mensaje de fallo es un volcado de dos structs, mientras que `if got != want`
falla en tiempo de compilación si los tipos no son comparables y te deja escribir
el mensaje que de verdad explica el caso. La stdlib no trae aserciones a propósito;
el sitio donde eso duele es el andamiaje, y por eso el parche llega solo hasta ahí.

---

## ⚰️ 7. Autopsia y errores comunes

### ⚰️ Autopsia: el repositorio que reinventó `@Transactional`

**El cadáver.** Lo escribió alguien con diez años de Spring, y su razonamiento era
impecable: *"si el repositorio recibe la transacción por parámetro, cada firma
lleva un parámetro más y el caso de uso tiene que saber de transacciones. Lo
escondo en el contexto, como hace Spring, y las firmas quedan limpias."*

```go
// ☕
type txKey struct{}

func WithTx(ctx context.Context, tx *sql.Tx) context.Context {
	return context.WithValue(ctx, txKey{}, tx)
}

func txFrom(ctx context.Context) *sql.Tx {
	tx, _ := ctx.Value(txKey{}).(*sql.Tx)
	return tx
}

// Cada método del repositorio empieza igual.
func (r *Repo) Save(ctx context.Context, item workitem.WorkItem) error {
	if tx := txFrom(ctx); tx != nil {
		_, err := tx.ExecContext(ctx, insertSQL, ...)
		return err
	}
	_, err := r.db.ExecContext(ctx, insertSQL, ...)
	return err
}

// Y el gestor, que reproduce la propagación REQUIRED de Spring.
func (m *TxManager) Transactional(ctx context.Context, fn func(context.Context) error) error {
	if txFrom(ctx) != nil {
		return fn(ctx)   // ya hay transacción: participar (REQUIRED)
	}
	tx, err := m.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	if err := fn(WithTx(ctx, tx)); err != nil {
		return err
	}
	return tx.Commit()
}
```

Funciona. Las firmas quedan limpias. Y tiene **cuatro problemas**, tres de ellos
compartidos con el original de Spring:

**1. No se ve en la firma si una función participa en una transacción.**
`Save(ctx, item)` puede estar dentro o fuera, y para saberlo hay que rastrear
quién llamó a quién. Es exactamente la crítica que se le hace a `@Transactional`, y
la hemos reproducido a mano.

**2. El `txFrom` que devuelve nil y nadie comprueba.** Si alguien olvida envolver
con `Transactional`, `Save` ejecuta **fuera** de transacción, en silencio. Dos
`Save` que debían ser atómicos dejan de serlo y no hay error. **Este es el bug de
verdad**, y el que produce datos inconsistentes que nadie explica.

**3. La goroutine que se lleva la transacción.** Si un caso de uso lanza una
goroutine pasándole el `ctx`, esa goroutine tiene la transacción **y `*sql.Tx` no
es seguro para uso concurrente**. Dos sentencias simultáneas sobre la misma
transacción producen corrupción del protocolo o un error del driver. Con la
transacción por parámetro, alguien lo habría visto al escribir la firma.

**4. Y el contexto vuelve a ser una bolsa de parámetros**, que es el ☕ de la Fase
07 con un envoltorio más elegante.

**El informe forense:**

| | `tx` en el contexto | `tx` por parámetro |
|---|---|---|
| Parámetros por firma de repositorio | 2 | 3 |
| ¿Se ve el alcance transaccional en la firma? | **no** | sí |
| Un olvido de envolver produce... | escritura **fuera** de transacción, en silencio | **no compila** |
| Un `*sql.Tx` compartido con una goroutine | posible y no se ve | visible al escribir la firma |
| Líneas del "gestor de transacciones" | 28 (y crece con cada tipo de propagación) | 0 |
| Propagación `REQUIRES_NEW`, `NESTED` | hay que implementarlas | el caso de uso abre otra transacción, y se ve |
| Herramienta que lo detecta | ninguna | el compilador |

**La causa de la muerte.** Un intercambio mal valorado: se cambió **un parámetro
por firma** por **la invisibilidad del alcance transaccional**. En Spring ese
intercambio está amortizado por quince años de herramienta, documentación y
personas que conocen las reglas de propagación. Reimplementarlo a mano en un
proyecto de Go te da los costes sin los beneficios.

**Y la parte justa:** `@Transactional` es una buena solución para su ecosistema.
Elimina muchísimo código repetitivo, la propagación declarativa resuelve casos
reales, y la mayoría de los equipos Spring nunca tienen problemas con ella. **El
error no es que Spring lo haga; es traerlo aquí sin la infraestructura que lo
sostiene.**

> ☕ **El patrón a memorizar.** **Si tu transacción no aparece en ninguna firma, no
> sabes cuál es su alcance.** Y en Go, donde no hay *proxies* ni contenedor, esa
> invisibilidad no la compensa nadie.

### Errores comunes

**1. `rows.Close()` olvidado.**
*Síntoma:* el servicio se cuelga tras N peticiones; las métricas no muestran
errores.
*Causa:* las conexiones no vuelven al pool.
*Fix mínimo:* `defer rows.Close()` inmediatamente tras comprobar el error de
`Query`. El linter `sqlclosecheck` lo detecta, y está en el `.golangci.yml` desde
la Fase 00.

**2. `rows.Err()` no comprobado.**
*Síntoma:* resultados parciales silenciosos ante un fallo de red a mitad de la
lectura.
*Causa:* el bucle `for rows.Next()` también termina por error.
*Fix mínimo:* comprobarlo siempre después del bucle. `rowserrcheck` lo detecta, y
también está puesto desde la Fase 00.

**3. `sql.Open` sin `Ping`.**
*Síntoma:* el servicio arranca con credenciales incorrectas y falla en la primera
petición de usuario.
*Causa:* `Open` no conecta.
*Fix mínimo:* `PingContext` con plazo en el arranque, y fallo rápido.

**4. `MaxIdleConns` con el valor por defecto.**
*Síntoma:* latencia alta e irregular bajo carga oscilante; `MaxIdleClosed` crece.
*Causa:* el valor por defecto es 2; el pool abre y cierra conexiones sin parar.
*Fix mínimo:* igualarlo a `MaxOpenConns`.

**5. `QueryRow` sin comprobar `sql.ErrNoRows`.**
*Síntoma:* un "no encontrado" se reporta como error interno 500.
*Causa:* `QueryRow().Scan()` devuelve `sql.ErrNoRows`, que no es un fallo del
sistema.
*Fix mínimo:* `errors.Is(err, sql.ErrNoRows)` y traducir a `ErrNotFound`.

**6. `NULL` escaneado a un tipo que no lo admite.**
*Síntoma:* `converting NULL to string is unsupported`.
*Causa:* la columna es nullable y el destino es `string`.
*Fix mínimo:* `sql.NullString`/`sql.NullTime`, o `*T`, y convertir al dominio
inmediatamente.

**7. Concatenar SQL en vez de usar parámetros.**
*Síntoma:* inyección SQL.
*Causa:* `fmt.Sprintf("... WHERE id = '%s'", id)`.
*Fix mínimo:* `$1`. Y si necesitas SQL dinámico —columna de orden variable—,
**valida contra una lista blanca**, nunca interpoles la entrada.

**8. `PRAGMA` de SQLite ejecutado con `Exec` tras abrir.**
*Síntoma:* el WAL no se activa, o las claves foráneas no se aplican, de forma
intermitente.
*Causa:* los PRAGMA son **por conexión**, y el pool tiene varias.
*Fix mínimo:* ponerlos en la cadena de conexión.

**9. `SQLITE_BUSY` bajo escrituras concurrentes.**
*Síntoma:* `database is locked` esporádico.
*Causa:* SQLite admite un solo escritor y el pool tiene N conexiones.
*Fix mínimo:* `SetMaxOpenConns(1)` para el pool de escritura, y `busy_timeout`.

**10. `Add(24*time.Hour)` para "el día siguiente".**
*Síntoma:* el cierre de un día concreto, dos veces al año, cubre mal el intervalo.
*Causa:* en el cambio de horario, el día tiene 23 o 25 horas.
*Fix mínimo:* `AddDate(0, 0, 1)` sobre una hora en la zona local.

**11. `time.LoadLocation` en una imagen `scratch`.**
*Síntoma:* `unknown time zone America/Bogota` en producción, funcionando en local.
*Causa:* la imagen no trae la base de datos de zonas horarias.
*Fix mínimo:* `import _ "time/tzdata"`.

**12. Subir a `SERIALIZABLE` sin reintento.**
*Síntoma:* errores esporádicos `could not serialize access` bajo concurrencia.
*Causa:* en ese nivel, los conflictos son normales y hay que reintentar.
*Fix mínimo:* `WithTxRetry` con retroceso y jitter.

**13. Un `defer tx.Rollback()` cuyo error se ignora del todo.**
*Síntoma:* transacciones abiertas ocupando conexiones y bloqueos.
*Causa:* si el `Rollback` falla de verdad —no con `ErrTxDone`—, nadie se entera.
*Fix mínimo:* el `defer` con closure que registra si el error no es
`sql.ErrTxDone`.

### 🧨 Rompe a propósito

**Provoca el agotamiento del pool en un servicio HTTP real** y mira cómo se ve
desde fuera, que es lo que vas a encontrar en un incidente:

```go
// Un handler con una fuga de conexión en el camino de error. Es el bug real:
// nadie olvida el Close en el camino feliz; se olvida en el `return` de error.
func (h *Handler) leaky(w http.ResponseWriter, r *http.Request) {
	rows, err := h.db.QueryContext(r.Context(), "SELECT id, status FROM work_items LIMIT 10")
	if err != nil {
		writeError(w, r, err)
		return
	}
	// FALTA: defer rows.Close()

	var items []string
	for rows.Next() {
		var id, status string
		if err := rows.Scan(&id, &status); err != nil {
			writeError(w, r, err)
			return    // ← AQUÍ. Salimos sin cerrar, y la conexión no vuelve.
		}
		items = append(items, id)
	}
	writeJSON(w, http.StatusOK, items)
}
```

Provoca el error de escaneo (cambia el orden de las columnas), lanza treinta
peticiones con `MaxOpenConns=5`, y observa:

```bash
for i in $(seq 1 30); do curl -s -o /dev/null -w "%{http_code} %{time_total}\n" localhost:8080/leaky & done; wait
```

```text
500 0.004
500 0.003
500 0.004
500 0.003
500 0.004
    (y a partir de aquí, nada: las peticiones se quedan colgadas)
```

**Cinco errores y después silencio.** Ni logs, ni errores, ni timeouts —hasta que
vence el contexto de cada petición.

Y ahora el diagnóstico, que es lo que hay que practicar:

```bash
curl -s localhost:8080/debug/vars | jq .db_stats
# {"OpenConnections":5,"InUse":5,"Idle":0,"WaitCount":25,"WaitDuration":"1m12s"}
```

`InUse: 5` con `Idle: 0` y `WaitCount` creciendo: **el pool está agotado y nadie
devuelve nada.** Eso, más `pg_stat_activity` mostrando cinco conexiones en estado
`idle in transaction` o con una consulta vieja, cierra el caso.

**La lección:** exponer `db.Stats()` en el endpoint de métricas cuesta tres líneas
y convierte un incidente de horas en un diagnóstico de treinta segundos. Lo
haremos formalmente en la Fase 14.

---

## 🧪 8. Ejercicios (30)

**🟢 Fácil (1–7)**

1. Abre una conexión con credenciales incorrectas y comprueba que `sql.Open` no
   falla. *Criterio:* explicas dónde falla de verdad y por qué el `Ping` es
   obligatorio.
2. Configura los cuatro parámetros del pool y justifica cada número para un
   despliegue de seis réplicas contra un PostgreSQL con `max_connections=100`.
   *Criterio:* el cálculo está escrito.
3. Escribe la primera migración de OpsReport con `goose` y aplícala. *Criterio:*
   `goose status` muestra el estado y `goose redo` funciona.
4. Provoca la violación de cada una de las tres restricciones `CHECK` y observa el
   SQLSTATE. *Criterio:* los tres códigos anotados con su significado.
5. Escanea una columna nullable a un `string` y provoca el error. *Criterio:*
   pegas el mensaje y lo arreglas con `sql.NullTime`.
6. Usa `EXPLAIN ANALYZE` sobre la consulta de la cola con y sin el índice.
   *Criterio:* identificas el cambio de `Seq Scan` a `Index Scan` y anotas los dos
   tiempos.
7. Abre `storeagent.db` con `sqlite3` y verifica que `PRAGMA journal_mode`
   devuelve `wal`. *Criterio:* explicas qué cambia respecto al modo por defecto.

**🟡 Intermedio (8–19)**

8. Implementa `WorkItemStore` completo sobre PostgreSQL. *Criterio:*
   `opsreport.Service` **no cambia ni una línea**, y lo demuestras con `git diff`.
9. Escribe `translateError` con los cinco SQLSTATE. *Criterio:* un test de
   integración provoca cada uno y verifica la traducción.
10. Reproduce el agotamiento del pool del 🧨. *Criterio:* llegas al cuelgue,
    diagnosticas con `db.Stats()` y `pg_stat_activity`, y lo arreglas.
11. Implementa `WithTx` con el `defer tx.Rollback()` y comprueba que tras el
    `Commit` devuelve `sql.ErrTxDone`. *Criterio:* explicas por qué ese error se
    ignora y qué haces si el `Rollback` falla de verdad.
12. Implementa `ClaimPending` con `SKIP LOCKED`. *Criterio:* un test de
    integración lanza tres goroutines reclamando a la vez y verifica que **ninguna
    entrega se reclama dos veces**.
13. Añade el recuperador de entregas huérfanas. *Criterio:* el plazo del
    recuperador es mayor que el plazo máximo de entrega, y explicas qué pasaría si
    no lo fuera.
14. Implementa la paginación por cursor con comparación de tuplas. *Criterio:* el
    `EXPLAIN ANALYZE` muestra el índice usado, y el cursor es opaco para el
    cliente.
15. Mide B-15 en las páginas 1, 100, 1.000 y 2.000. *Criterio:* tu veredicto dice
    también **qué se pierde** con el cursor.
16. Migra la cola de OpsReport a PostgreSQL y demuestra que sobrevive a un
    reinicio. *Criterio:* encolas, matas el proceso, arrancas, y los trabajos
    siguen ahí. (💸 pagada.)
17. Escribe `storeagent record` y `storeagent list` con `flag` y subcomandos.
    *Criterio:* `-h` funciona en el comando y en cada subcomando, y un subcomando
    desconocido sale con código 2 y un mensaje útil.
18. Implementa `BusinessDayRange` y pruébalo con Bogotá, Ciudad de México y
    Santiago. *Criterio:* el test del día de 23 horas pasa, y falla si cambias
    `AddDate` por `Add(24*time.Hour)`.
19. **Línea de comandos.** Consulta `pg_stat_activity` mientras corre una
    transacción larga e identifica el estado `idle in transaction`. *Criterio:*
    explicas por qué ese estado es peligroso y qué lo produce.

**🟠 Difícil (20–26)**

20. Monta los tests de integración con `testcontainers-go` y corre la suite de
    contrato de la Fase 04 contra PostgreSQL. *Criterio:* los tests **no cambian**;
    si alguno falla, encontraste una divergencia real entre `memstore` y la
    implementación — documéntala.
21. Implementa el aislamiento por transacción revertida en los tests de
    integración. *Criterio:* cuarenta tests corren contra **un** contenedor en
    menos de diez segundos, y son independientes del orden (`-shuffle=on`).
22. Mide B-13: `database/sql` frente a `pgx` nativo, con 10, 100 y 1.000 filas, y
    con `CopyFrom` para la inserción masiva. *Criterio:* tu recomendación es
    condicional —cuándo cada uno— y cita los números.
23. Mide B-14: SQL a mano, `sqlc` y `GORM` sobre la misma consulta. *Criterio:*
    (a) los tres implementados de verdad y funcionando; (b) reportas `ns/op`,
    `B/op` y `allocs/op`; (c) tu veredicto **no** se basa solo en los números, y
    dices explícitamente qué pesa más que el rendimiento.
24. Provoca un conflicto de serialización con dos transacciones `SERIALIZABLE`
    concurrentes e implementa el reintento. *Criterio:* sin reintento falla de
    forma esporádica; con reintento, nunca. Mides cuántos reintentos hicieron
    falta.
25. Demuestra la actualización perdida en `READ COMMITTED` y resuélvela de las
    **tres** formas de §6.5. *Criterio:* mides las tres bajo concurrencia y
    recomiendas una con su condición.
26. Compila `storeagent` con `modernc.org/sqlite` y con `mattn/go-sqlite3`.
    *Criterio:* comparas tamaño del binario, si la compilación cruzada funciona, y
    el rendimiento de inserción de 100.000 movimientos. Tu recomendación cita el
    caso de despliegue de las 140 tiendas.

**🔴 Muy difícil (27–30)**

27. **La cola distribuida, probada en serio.** Somete `ClaimPending` a cinco
    procesos concurrentes durante un minuto, con fallos inyectados. *Rúbrica:* (a)
    ninguna entrega se procesa dos veces, y lo verificas contra `fakeconsumer`;
    (b) ninguna entrega se queda huérfana indefinidamente; (c) matas un proceso a
    mitad y sus entregas se recuperan; (d) mides el rendimiento total y dices a
    partir de cuántos consumidores deja de escalar **y por qué** —investiga la
    contención en el índice—; (e) documentas el punto en que recomendarías una cola
    de verdad.
28. **La migración con cero tiempo de caída.** Diseña e implementa el cambio de
    `work_items.priority` de `SMALLINT` a un tipo enumerado, **sin parar el
    servicio**. *Rúbrica:* (a) la secuencia de migraciones expansiva/contractiva
    completa, con los despliegues intercalados; (b) en cada paso, las versiones
    antigua y nueva del código funcionan contra el mismo esquema; (c) el plan de
    reversión de cada paso; (d) lo demuestras con dos binarios corriendo a la vez;
    (e) explicas por qué esto es más fácil o más difícil que en un proyecto con JPA
    y `ddl-auto`.
29. **El presupuesto de conexiones de la plataforma.** Meridian va a tener cuatro
    servicios, con réplicas, contra un PostgreSQL. *Rúbrica:* (a) calculas el
    presupuesto de conexiones por servicio, con el número de réplicas y el margen
    de mantenimiento; (b) mides bajo carga qué `MaxOpenConns` da la mejor latencia
    p99 **por servicio** y demuestras que más conexiones no es mejor; (c) evalúas
    `pgbouncer` en modo transacción y dices qué dejarías de poder usar con él
    (pista: sentencias preparadas, `SET`, `LISTEN`); (d) escribes la recomendación
    para el equipo de plataforma con números.
30. **El agente que sobrevive a todo.** Endurece `storeagent` contra los fallos
    reales de un mini-PC en una tienda. *Rúbrica:* (a) corte de luz a mitad de una
    escritura: ningún movimiento a medias, y lo demuestras matando el proceso con
    `SIGKILL` durante inserciones; (b) disco lleno: falla con un mensaje accionable,
    no corrompe la base; (c) archivo corrupto: se detecta al arrancar con
    `PRAGMA integrity_check` y hay un procedimiento de recuperación; (d) reloj del
    sistema retrasado o adelantado: los movimientos siguen siendo ordenables y
    explicas cómo; (e) un millón de movimientos acumulados sin red: la sincronización
    es reanudable, acotada en memoria, y mides cuánto tarda.

**🔥 Opcionales**

- Implementa `LISTEN/NOTIFY` con `pgx` nativo para que EventRelay reaccione a
  nuevas entregas sin sondeo. Es elegante, y tiene una trampa: las notificaciones
  se pierden si el consumidor está desconectado, así que el sondeo sigue haciendo
  falta como red. Descubre por qué.
- Lee el código de `database/sql` en tu `GOROOT`, en concreto `connRequest` y la
  gestión del pool. Son unas mil líneas y explican exactamente qué pasa cuando el
  pool se agota.
- Mide el efecto de `SetConnMaxLifetime` provocando un *failover*: arranca dos
  PostgreSQL, apunta el servicio a uno, mátalo, y observa cuánto tarda el pool en
  recuperarse con distintos valores.

---

### 🔴 Desafíos de cierre

> Tres ejercicios de dificultad alta que **no cuentan en el total de la sección** y
> no son parte del recorrido base.

**D1 — `sqlc` de verdad, no como demostración.**
Migra **todo** el acceso a datos de OpsReport a `sqlc` y vívelo un rato.
*Rúbrica:* (a) las diez consultas del servicio, incluida la de `SKIP LOCKED` y la
paginación por cursor —que son las que ponen a prueba al generador—; (b) el código
generado se commitea y se revisa como código; (c) **provocas el fallo útil**:
renombra una columna en la migración y demuestra que `sqlc generate` falla antes de
compilar, mientras que el SQL a mano habría fallado en ejecución; (d) mides el
tiempo de añadir una consulta nueva en los dos modelos; (e) escribes el veredicto
para un proyecto con cuarenta consultas, no con diez.

**D2 — El índice que falta, encontrado bajo carga.**
Activa `pg_stat_statements`, somete OpsReport a carga real, y encuentra la consulta
que necesita un índice **sin saber de antemano cuál es**.
*Rúbrica:* (a) configuras la extensión y explicas qué columnas importan
—`total_exec_time`, `mean_exec_time`, `calls`— y por qué la suma pesa más que la
media; (b) identificas la consulta más cara y la analizas con `EXPLAIN (ANALYZE,
BUFFERS)`; (c) creas el índice, **mides el antes y el después**, y compruebas que no
degradaste las escrituras; (d) encuentras también un índice **que sobra** con
`pg_stat_user_indexes` y lo borras; (e) documentas el procedimiento como parte del
runbook.

**D3 — El *failover* y el pool.**
Arranca dos PostgreSQL en replicación, apunta OpsReport al primario, y mátalo bajo
carga.
*Rúbrica:* (a) mides cuánto tarda el servicio en recuperarse con
`ConnMaxLifetime` infinito y con 5 minutos, y explicas la diferencia; (b)
identificas qué peticiones fallan durante la transición y con qué error; (c)
implementas el reintento de las que son seguras de reintentar —y **solo** esas,
usando la clasificación de SQLSTATE de §6.3—; (d) compruebas si las sentencias
preparadas sobreviven al *failover* y qué implica eso; (e) escribes lo que le
pedirías al equipo de plataforma para que el servicio se recupere solo.

---

## 📚 9. Referencias

### Documentación oficial

- **`database/sql`** — https://pkg.go.dev/database/sql — lee la documentación del
  paquete **entera**: el modelo de pool está explicado ahí y casi nadie lo lee.
- **Accessing relational databases** — https://go.dev/doc/database/ — la guía
  oficial, con secciones sobre el pool, transacciones y sentencias preparadas.
- **Managing connections** — https://go.dev/doc/database/manage-connections — los
  cuatro parámetros del pool, oficialmente.
- **`pgx`** — https://pkg.go.dev/github.com/jackc/pgx/v5 — y el README del
  repositorio, que explica cuándo usar el modo nativo y cuándo `database/sql`.
- **PostgreSQL: error codes** — https://www.postgresql.org/docs/current/errcodes-appendix.html
  — la tabla de SQLSTATE que traduce `translateError`.
- **PostgreSQL: `SELECT ... FOR UPDATE SKIP LOCKED`** —
  https://www.postgresql.org/docs/current/sql-select.html#SQL-FOR-UPDATE-SHARE
- **PostgreSQL: transaction isolation** —
  https://www.postgresql.org/docs/current/transaction-iso.html — **la sección de
  `SERIALIZABLE` explica por qué hay que reintentar.**
- **SQLite: WAL mode** — https://www.sqlite.org/wal.html ·
  **When to use SQLite** — https://www.sqlite.org/whentouse.html — honesto sobre
  sus límites y merece leerse antes de decidir.
- **SQLite: datatypes** — https://www.sqlite.org/datatype3.html — la afinidad de
  tipo, que sorprende.
- **`modernc.org/sqlite`** — https://pkg.go.dev/modernc.org/sqlite
- **goose** — https://github.com/pressly/goose
- **testcontainers-go** — https://golang.testcontainers.org
- **`sqlc`** — https://docs.sqlc.dev · **GORM** — https://gorm.io/docs/

### Libros

- **Let's Go Further** — Alex Edwards. Su tratamiento de `database/sql`,
  migraciones y el pool es el más cercano al de este curso.
- **Designing Data-Intensive Applications** — Martin Kleppmann. El capítulo 7
  (*Transactions*) es la mejor explicación que existe de los niveles de
  aislamiento, con los anomalías que cada uno permite. **No es de Go y es la
  lectura más valiosa de esta fase.**
- **PostgreSQL 16 Administration Cookbook** — para los detalles operativos:
  conexiones, *vacuum*, planes.
- **100 Go Mistakes** — Harsanyi, errores #78 a #81: `sql.Open`, `rows.Close`,
  sentencias preparadas y transacciones.

### Artículos y charlas

- **Go database/sql tutorial** — http://go-database-sql.org — **la referencia no
  oficial más citada**, y sigue siendo la mejor introducción práctica. Cubre el
  pool, `NULL`, las sentencias preparadas y los errores comunes.
- **Common Pitfalls When Using database/sql** — busca el artículo de VividCortex
  (hoy SolarWinds); es la fuente original de la mitad de §7.
- **Configuring sql.DB for Better Performance** — Alex Edwards,
  https://www.alexedwards.net/blog/configuring-sqldb — **el artículo de §6.1**,
  con mediciones de cada parámetro.
- **How to Implement a Job Queue in PostgreSQL** — busca artículos sobre
  `SKIP LOCKED`; el de Brandur Leach (*Postgres job queues & failure by MVCC*) es
  el más completo y advierte del problema de los *bloats* de MVCC.
- **Pagination: you're doing it wrong** — sobre la paginación por cursor frente a
  `OFFSET`; hay varios buenos, busca los que muestren el `EXPLAIN`.
- **Use The Index, Luke** — https://use-the-index-luke.com — **el mejor recurso
  gratuito sobre índices que existe**, agnóstico de lenguaje. La sección sobre
  paginación por cursor es exactamente §6.6.
- **SQLite as an Application File Format** — https://www.sqlite.org/appfileformat.html
- **Squeezing Performance from SQLite** — serie de artículos de optimización;
  útiles para el ejercicio 30.

### Video

- **GopherCon: Advanced SQL in Go** — busca charlas posteriores a 2020.
- **PGConf: Job queues in Postgres** — sobre `SKIP LOCKED` en producción.
- **JetBrains Go: Database Tools** — para quien use GoLand, ahorra salir a `psql`.

> ⚠️ Mucho contenido sobre `database/sql` es anterior a `context` (2016) y muestra
> `db.Query` en vez de `db.QueryContext`. **Las variantes sin contexto no se usan
> en este curso**: sin contexto no hay plazo, no hay cancelación, y el `noctx` del
> linter protesta. Si un ejemplo no lleva `ctx`, es de antes de 2016.

### Orden de lectura sugerido

**Antes de escribir código:** *go-database-sql.org* entero (una hora, y es la mejor
inversión de la fase) y *Configuring sql.DB for Better Performance* de Edwards.
**Durante:** la tabla de SQLSTATE de PostgreSQL cuando escribas `translateError`, y
*Use The Index, Luke* cuando diseñes un índice.
**Después:** el capítulo 7 de Kleppmann, con calma. Es el que convierte "sé usar
transacciones" en "sé qué anomalía permite cada nivel y por qué".

---

## ⚖️ 10. Veredicto y cierre

### ⚖️ Cuándo NO usar esto

- **Cuando tu equipo escribe CRUD masivo y viene de JPA**, `database/sql` a mano
  es genuinamente más trabajo. Cuarenta entidades con operaciones estándar son
  cuarenta repositorios escritos a mano frente a cuarenta interfaces de Spring Data
  con cero implementación. **`sqlc` cierra buena parte de esa brecha y es la
  recomendación del curso para ese caso**, aunque Meridian no lo use.
- **Cuando el modelo de dominio es un grafo profundo con relaciones bidireccionales
  que se navegan**, un ORM con gestión de identidad y *dirty checking* hace un
  trabajo real que aquí hay que escribir. JPA resuelve ese problema bien y llevarlo
  a Go a mano es doloroso.
- **Cuando necesitas consultas derivadas de nombres de método**
  (`findByStatusAndPriorityGreaterThan`), no hay nada parecido. Es genuinamente
  cómodo para prototipar y no existe.
- **Cuando la transaccionalidad es compleja y transversal** —propagación
  `REQUIRES_NEW`, transacciones anidadas, eventos post-commit—, `@Transactional` lo
  resuelve declarativamente y aquí se escribe. La autopsia va de no reimplementarlo
  mal, no de que no haga falta nunca. **Y este es uno de los argumentos serios a
  favor de quedarse en Spring**, que retomamos en la Fase 16.
- **Y SQLite no es la respuesta** cuando hay varios procesos escribiendo, cuando
  necesitas control de acceso por usuario, cuando el archivo vive en un sistema de
  archivos en red (NFS y SQLite es una combinación conocida por corromper datos), o
  cuando necesitas replicación. Para el agente de tienda es perfecto; como base de
  datos del servicio central, no.
- **Réplicas de lectura, particionado y *sharding*** quedan fuera del curso. Si tu
  problema es ese, `database/sql` no te estorba pero tampoco te ayuda: el
  enrutamiento de lecturas a réplicas hay que escribirlo, y en el ecosistema de
  Java hay más herramienta hecha.

### 📖 Diccionario Java ⇄ Go de esta fase

| Java / Spring | Go | Dónde se rompe la equivalencia |
|---|---|---|
| `DataSource` / HikariCP | `*sql.DB` | **`*sql.DB` ES el pool**, no una conexión. `sql.Open` no conecta: hay que hacer `Ping` |
| `hikari.maximumPoolSize` | `SetMaxOpenConns` | Idéntico. Ninguno tiene valor por defecto sensato para producción |
| `hikari.minimumIdle` | `SetMaxIdleConns` | ⚠️ El valor por defecto de Go es **2** y casi siempre está mal |
| `hikari.maxLifetime` | `SetConnMaxLifetime` | Idéntico, y por las mismas razones (failover, balanceo) |
| `Connection` | una conexión del pool, no expuesta | No se manipula directamente salvo con `db.Conn()` |
| `PreparedStatement` | `db.PrepareContext` / parámetros en `Query` | Los parámetros `$1` ya usan sentencias preparadas por debajo. `Prepare` explícito solo para reutilización intensiva |
| `ResultSet` | `*sql.Rows` | **`defer rows.Close()` obligatorio**, y `rows.Err()` después del bucle |
| `rs.getString(1)` | `rows.Scan(&dest)` | Por punteros y por posición; el compilador no verifica el orden contra el SQL |
| `Optional<T>` para nullable | `sql.NullString` / `*T` | Se convierte al tipo del dominio inmediatamente para que el `NULL` no se propague |
| `SQLException` | `error` + SQLSTATE con `pgconn.PgError` | Se traduce **por código**, nunca por texto del mensaje |
| `EmptyResultDataAccessException` | `sql.ErrNoRows` | Centinela de la stdlib; se comprueba con `errors.Is` |
| `@Transactional` | `tx` **por parámetro** | **La diferencia central de la fase.** El alcance se ve en la firma; no hay propagación automática |
| `@Transactional(propagation=REQUIRES_NEW)` | abrir otra transacción explícitamente | Visible en el código en vez de en una anotación |
| `@Transactional(isolation=SERIALIZABLE)` | `sql.TxOptions{Isolation: LevelSerializable}` | **Los dos exigen reintento**; aquí el bucle es visible |
| `TransactionTemplate` | `WithTx(ctx, db, opts, func(tx) error)` | Doce líneas, escritas una vez |
| Spring Retry para conflictos | `WithTxRetry` con retroceso y jitter | Escrito a mano, y por eso sabes qué reintenta |
| `@Entity` | un struct normal | **No hay entidades gestionadas**: sin *dirty checking*, sin caché de primer nivel, sin detach/merge |
| `EntityManager` | *(no existe)* | No hay contexto de persistencia. Un struct leído es un valor |
| `LazyInitializationException` | *(no existe)* | No hay *lazy loading*, así que no hay esta clase de error |
| Caché de primer nivel | *(no existe)* | Leer dos veces devuelve dos structs distintos. Menos mágico y sin bugs de identidad |
| Problema N+1 | existe igual | **Pero lo escribes tú**: sin *lazy loading*, el bucle es visible en la revisión |
| `@Repository` + Spring Data | un struct con métodos | Sin consultas derivadas de nombres de método |
| `Pageable` / `Page<T>` | paginación por cursor escrita a mano | El cursor no permite saltar a la página N ni dar el total sin un `COUNT` |
| Flyway / Liquibase | `goose` | Numeración por *timestamp* (mejor para ramas paralelas) y migraciones en Go además de SQL |
| `ddl-auto: update` | *(no existe, y es bueno)* | El esquema siempre es explícito y versionado |
| Testcontainers (Java) | `testcontainers-go` | Prácticamente la misma API. Un contenedor por paquete, aislamiento por transacción |
| `@DataJpaTest` con rollback | transacción revertida en `t.Cleanup` | Mismo patrón, escrito a mano en cuatro líneas |
| H2 en memoria para tests | **no se usa** | Un motor distinto en test que en producción esconde divergencias. Contenedor real |
| `@Query(nativeQuery=true)` | lo normal | En Go todo el SQL es nativo |
| `java.time.ZoneId` | `time.LoadLocation` | ⚠️ Necesita la base de datos de zonas del sistema; `import _ "time/tzdata"` la incrusta |

### Qué sigue

La Fase 10 sale al mundo exterior: **clientes HTTP, APIs externas y dobles
generados**. El `http.Client` bien configurado —que es un tema en sí mismo, porque
el cliente por defecto **no tiene tiempo límite**—, reintentos con retroceso
exponencial y *jitter* escritos a mano, clasificación de errores recuperables
frente a permanentes como función pura probada con tabla, `singleflight` contra el
rebaño atronador, limitación de tasa, y un cortacircuitos mínimo.

**AtlasSync nace** consumiendo REST Countries y Frankfurter, dos APIs públicas sin
clave. Y con él llega el tema que el curso venía aplazando: **cómo se prueba un
servicio que depende de internet**, con los cinco niveles montados y la regla de
que la suite entera corre **sin red**.

Y entra por fin `go.uber.org/mock`, seis fases después de que la Fase 04 lo
aplazara, con su justificación: verificar que el cliente reintentó exactamente tres
veces y no cuatro es verificación de interacción, y para eso el fake se queda
corto.

### La señal de que quedó bien

> *"Leo una firma de repositorio y sé, sin abrir nada más, si esa operación
> participa en una transacción y cuál es su alcance. Y cuando el servicio se queda
> colgado, lo primero que miro es `db.Stats()`, no el log."*

Si todavía buscas dónde poner `@Transactional`, vuelve a §4 y mira la firma de
`Save(ctx, q DBTX, item)`. Ese `q` es toda la respuesta.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en
> verde, `go test -race ./...` y `go test -tags=integration ./...` en verde,
> `golangci-lint run` limpio y `git status` sin cambios pendientes:
>
> ```bash
> git tag -a fase-09 -m "F9 cerrada: OpsReport y EventRelay sobre PostgreSQL con goose; pool configurado y justificado; SKIP LOCKED para la cola de entregas con recuperador; paginación por cursor; storeagent con SQLite en WAL; zona horaria por tienda resuelta; tests de integración con testcontainers; B-13, B-14, B-15 y B-16 medidos"
> git tag -a opsreport/v0.9 -m "OpsReport: persistencia en PostgreSQL"
> git tag -a eventrelay/v0.8 -m "EventRelay: cola de entregas en base de datos con SKIP LOCKED"
> git tag -a clearinghouse/v0.1 -m "ClearingHouse: nace storeagent con SQLite"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 09: …`) y los de ejercicio su
> número (`fase 09 ej27: …`). Todo eso está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).

---

# 📌 Bloque de autoría (fuera de lo que lee el estudiante)

## 📌 Pendientes sugeridos

- **`testify/require`** — introducido en §6.11 como manda la guía de estilo §7.4:
  **acotado al andamiaje de los tests de integración**, con la regla explícita de
  que las aserciones de comportamiento siguen en `if got != want`. Lleva su 🪞,
  porque el reflejo de extenderlo a toda la suite es exactamente lo que hace
  AssertJ en Java. Cadena cerrada.

- **La columna `claimed_at`** — el recuperador de entregas huérfanas de §6.4 la
  necesitaba y el esquema de §6.2 no la tenía. **Corregido:** la columna, el índice
  parcial `deliveries_reaper_idx` y el sellado en la consulta de reclamación están
  en §6.2, y §6.4 añade las dos reglas de configuración del recuperador (plazo
  mayor que el de entrega, y no restar el intento al recuperar).
- **`rowserrcheck`** — nombrado en los errores comunes #1 y #2 como el linter que
  los detecta. **Añadido al `.golangci.yml` de la Fase 00 §6.9**, junto a
  `sqlclosecheck`, que cubre la otra mitad del mismo error. Los dos se quedan
  puestos desde la Fase 00 aunque no vean SQL hasta aquí, igual que `bodyclose` y
  `noctx`. Cadena cerrada.
- **`pgbouncer`** — aparece en el ejercicio 29. Está fuera del alcance declarado
  (que llega hasta el `compose.yaml`), y como ejercicio 🔴 es legítimo. Verificar
  que no se convierte en material obligatorio.
- **`LISTEN/NOTIFY`** — ejercicio 🔥. Podría ser una sección corta de la **Fase 13**
  (trabajo asíncrono), donde el sondeo de la cola se discute de verdad. Anotarlo
  allí.
- **La suite de contrato** (ejercicio 23 de la Fase 04) — **se reutiliza aquí como
  estaba previsto**. Cadena verificada.
- **`import _ "time/tzdata"`** — introducido aquí, se vuelve crítico en la **Fase
  14** con la imagen `distroless`. Verificar que allí se menciona.
- **Migración expansiva/contractiva** (ejercicio 28) — es una técnica que la Fase
  14 (despliegue) podría necesitar. No está en su alcance; queda como ejercicio.

## ☕ Reflejos para `INSTINTOS.md`

- **"Reimplementar `@Transactional`"** — el reflejo raíz de la fase. Coste: el
  alcance transaccional deja de verse en la firma, un olvido de envolver escribe
  fuera de transacción **en silencio**, y un `*sql.Tx` puede acabar compartido con
  una goroutine sin que nadie lo vea. Antídoto: **la transacción viaja por
  parámetro**.
- **"`sql.Open` abre una conexión"** — no conecta. Sin `Ping`, el servicio arranca
  con credenciales malas.
- **"El pool se configura solo"** — `MaxIdleConns` por defecto es 2 y produce
  latencia irregular bajo carga oscilante.
- **"Un repositorio por entidad con los mismos ocho métodos"** — el reflejo de
  Spring Data. La mitad no se usan (autopsia de la Fase 02).
- **"H2 en memoria para los tests"** — un motor distinto en test que en producción
  esconde divergencias. Contenedor real.
- **"El día siguiente es `Add(24*time.Hour)`"** — falla dos veces al año, en la
  noche del cambio de horario.
- **"Los `PRAGMA` de SQLite se ejecutan después de abrir"** — son por conexión, y
  el pool tiene varias.

## 📐 Mediciones para `BENCHMARKS.md`

- **B-13 — `database/sql` frente a `pgx` nativo.** Con 10, 100 y 1.000 filas, más
  `INSERT` masivo frente a `CopyFrom`. **El veredicto debe ser condicional**, no un
  ganador: es lo que justifica la asimetría deliberada de Meridian.
- **B-14 — SQL a mano frente a `sqlc` frente a GORM.** Los tres, como manda la
  regla 1 de honestidad. **El veredicto tiene que decir explícitamente que el
  rendimiento no es el argumento principal**, y cuáles sí lo son.
- **B-15 — Paginación por cursor frente a `OFFSET`.** Páginas 1, 100, 1.000, 2.000,
  con `EXPLAIN ANALYZE` de las dos. **Y el "qué NO demuestra" tiene que incluir que
  el cursor pierde el salto a página arbitraria y el total** — que para algunas
  interfaces es descalificatorio.
- **B-16 — SQLite con WAL y sin WAL, escrituras por segundo.** Con
  `MaxOpenConns=1` y con N, para mostrar el `SQLITE_BUSY`. **Añadir una fila con
  `synchronous=FULL` frente a `NORMAL`**, porque es el intercambio durabilidad /
  rendimiento que el agente de tienda tiene que decidir de verdad.
- Nueva propuesta, sin ID: **coste de `MaxOpenConns` sobre la latencia p99** bajo
  carga (ejercicio 29b). Demuestra que más conexiones **no** es mejor, que es
  contraintuitivo y valioso. Candidata a entrada propia o a sección de B-13.
