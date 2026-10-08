# 📦 Fase 13 — Lotes, scheduling y trabajo asíncrono

> Go para desarrolladores Java senior · Fase 13 de 17 · **8 horas**
> Época: **Go moderno (1.25)**
> Depende de: Fase 12 · Habilita: Fase 14
> Proyectos que avanzan: **ClearingHouse** (el cierre nocturno) · **OpsReport** (reportes en streaming y outbox) · **EventRelay** (consume el outbox) · **AtlasSync** (ingesta programada)
> Mini proyectos: `chunked-stream`, `checkpoint-lab`, `outbox-lab`

---

## 🎯 1. Propósito

Esta es la fase donde los cuatro servicios se conectan entre sí, y es también **el
territorio donde Java es fuerte**. Spring Batch resuelve reanudación, reintento por
ítem, particionado y métricas de job. En Go eso se escribe. El curso lo escribe,
mide cuánto cuesta escribirlo, y da un veredicto honesto que en este terreno no
siempre favorece a Go.

El caso es el cierre nocturno de ClearingHouse: entre dos y cinco millones de
movimientos de ciento cuarenta tiendas, conciliados contra la pasarela de pagos y
el banco, produciendo asientos y cerrando el periodo. La ventana es de dos horas.
El proceso heredado tarda tres, no se puede reanudar si falla a la mitad, y nadie
se atreve a tocarlo.

Y aquí va el 🧨 más memorable del curso: **primero escribimos la versión ingenua
que carga todo en memoria, la medimos, y miramos subir la memoria residente hasta
que el proceso muere.** Después, la versión con fragmentos.

---

## ✅ 2. Qué queda listo al terminar

- [ ] El cierre de ClearingHouse procesa un millón de movimientos con memoria
      **acotada y constante**, y lo has medido.
- [ ] El lote es **reanudable**: lo matas a mitad, lo relanzas, y termina sin
      perder ni duplicar.
- [ ] Las **cinco propiedades** están probadas con un test cada una: reanudable,
      idempotente, acotado en memoria, observable y cancelable.
- [ ] El progreso es consultable **mientras corre**, no solo al terminar.
- [ ] El patrón **outbox** está implementado completo: OpsReport escribe estado y
      evento en la misma transacción, EventRelay los despacha.
- [ ] El scheduling tiene bloqueo en base de datos: con tres instancias, el cierre
      se ejecuta **una vez**.
- [ ] Los reportes de OpsReport se descargan en streaming en CSV, JSON y HTML, sin
      materializar.
- [ ] AtlasSync ingiere de forma programada, con su registro de ejecución.
- [ ] Has comparado el cierre con su equivalente en Spring Batch, con el código de
      los dos delante.

---

## 🚫 3. Qué NO entra todavía

- Observabilidad completa —métricas, trazas, `slog` con política— → Fase 14. Hoy
  hay contadores y logs, y el progreso se expone por un endpoint simple.
- Endurecimiento y despliegue → Fase 14.
- Perfilado del cierre → Fase 15, donde `pprof` dirá dónde se va el tiempo de
  verdad.
- El duelo medido contra Spring Boot → Fase 16. Hoy comparamos **el código**, no el
  rendimiento.
- **Kafka, RabbitMQ y NATS** → fuera del curso. Se nombran en el ⚖️ veredicto **con
  el punto exacto en el que la cola en base de datos deja de bastar**, que es la
  parte que importa.

---

## 🧠 4. Concepto mínimo

### Las cinco propiedades de un lote que funciona

Un proceso por lotes de producción tiene que ser cinco cosas, y **cada una tiene su
test**:

1. **Acotado en memoria.** Procesar diez millones de filas no puede consumir más
   que procesar diez mil. Si la memoria crece con el volumen, el proceso tiene una
   bomba de tiempo.
2. **Reanudable.** Si falla en el 70%, al relanzarlo empieza en el 70%, no en cero.
   Con una ventana de dos horas y un proceso de noventa minutos, no hay margen para
   repetir.
3. **Idempotente.** Relanzarlo produce el mismo resultado. Es lo que hace segura la
   reanudación: el fragmento que estaba a medias se reprocesa entero sin duplicar.
4. **Observable.** Se puede saber por dónde va **mientras corre**. Un proceso que
   solo dice algo al terminar es una caja negra durante noventa minutos.
5. **Cancelable.** Un `SIGTERM` lo para en segundos, no en horas — la lección de la
   Fase 07, aplicada donde de verdad duele.

> 🧭 **Regla del proyecto.** Estas cinco propiedades **se prueban**, no se
> declaran. Un lote sin el test de reanudación no es reanudable: es un lote que
> nadie ha interrumpido todavía.

### El fragmento con punto de control en la misma transacción

Aquí está el mecanismo central de la fase, y cabe en un diagrama:

```mermaid
flowchart TD
    subgraph TX["TRANSACCIÓN"]
        direction TB
        S1["1. leer N movimientos desde el último cursor"] --> S2["2. conciliarlos"]
        S2 --> S3["3. escribir los asientos resultantes"]
        S3 --> S4["4. ESCRIBIR EL PUNTO DE CONTROL<br/>(nuevo cursor)"]
    end
    TX --> CM(["COMMIT"])
```

**El punto de control va dentro de la misma transacción que el trabajo.** Esa es
toda la idea, y es lo que hace el lote reanudable de verdad:

- Si la transacción confirma, el trabajo **y** el registro de que se hizo están los
  dos guardados.
- Si falla, se deshacen los dos, y al reanudar se repite ese fragmento **desde un
  estado conocido**.

Si el punto de control se escribiera **fuera** de la transacción, habría dos
ventanas de error:

```mermaid
flowchart TD
    subgraph V1["Primero el trabajo, después el punto de control"]
        direction LR
        A1["commit del trabajo"] --> F1["☠️ fallo"] --> N1["punto de control NO escrito"]
        N1 --> R1["al reanudar, se reprocesa lo ya hecho<br/>→ DUPLICADOS (salvo idempotencia)"]
    end
    subgraph V2["Primero el punto de control, después el trabajo"]
        direction LR
        A2["punto de control escrito"] --> F2["☠️ fallo"] --> N2["commit del trabajo NO hecho"]
        N2 --> R2["al reanudar, se salta trabajo<br/>→ PÉRDIDA SILENCIOSA, que es peor"]
    end
    V1 ~~~ V2
    style R2 stroke:#d9534f,stroke-width:2px
```

**La segunda es la que mata**, porque no deja rastro: el lote termina "bien" y
faltan doce mil movimientos que nadie va a echar de menos hasta el cierre contable
del mes.

📖 Spring Batch hace exactamente esto con su `JobRepository`: guarda el
`ExecutionContext` del `Step` en la misma transacción que el *chunk*. **El
mecanismo es idéntico; la diferencia es que allí viene hecho y aquí se escribe.**

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El instinto:** *"cargo los datos, los proceso y los guardo"*. Es como se escribe
el 95% del código, funciona perfectamente con mil filas, y es lo que el ORM te
invitaba a hacer.

**Qué pasa si lo aplicas.** Esto:

```go
// ☕ — el cierre que mata el proceso
func (s *Service) CloseDay(ctx context.Context, storeID string, day time.Time) error {
	// 1. Cargar
	movements, err := s.store.MovementsForDay(ctx, storeID, day)
	if err != nil {
		return err
	}

	// 2. Procesar
	entries := make([]LedgerEntry, 0, len(movements))
	for _, m := range movements {
		entry, err := s.reconcile(ctx, m)
		if err != nil {
			return err
		}
		entries = append(entries, entry)
	}

	// 3. Guardar
	return s.store.SaveEntries(ctx, entries)
}
```

Se lee de maravilla. Y con un millón de movimientos:

```text
$ ./bin/clearinghouse close --day 2026-09-11
tiempo=0s    RSS=12 MB    movimientos cargados=0
tiempo=4s    RSS=340 MB   movimientos cargados=250000
tiempo=9s    RSS=712 MB   movimientos cargados=520000
tiempo=15s   RSS=1180 MB  movimientos cargados=840000
tiempo=19s   RSS=1490 MB  movimientos cargados=1000000
tiempo=19s   RSS=1490 MB  conciliando...
tiempo=31s   RSS=2740 MB  asientos construidos=1000000
signal: killed
```

**Muerto.** Y con cinco millones —que es la cifra real de una noche de Meridian—
muere antes de terminar de cargar.

Los **tres** problemas, y el tercero es el que la gente no ve:

1. **La memoria crece con el volumen.** Un millón de `Movement` a ~200 bytes son
   200 MB solo de datos, más la sobrecarga del slice al crecer, más el millón de
   `LedgerEntry`. El pico es más del doble de lo que ocupan los datos, porque
   `append` reserva el doble al crecer y durante la copia **existen las dos
   versiones a la vez**.
2. **No hay nada guardado hasta el final.** Un fallo en el minuto 28 de 30 pierde
   veintiocho minutos de trabajo.
3. **Y el que se olvida: no se puede cancelar.** El `SIGTERM` llega y el proceso
   está dentro de `MovementsForDay`, que no mira el contexto entre filas. La Fase
   07 entera va de esto.

**Qué pensar en su lugar.** *"¿Cuántos elementos hay en memoria a la vez?"* — y la
respuesta tiene que ser **una constante**, no una función del volumen.

```go
// El cierre con fragmentos: la memoria es la de UN fragmento.
func (s *Service) CloseDay(ctx context.Context, storeID string, day time.Time) (Report, error) {
	batch, err := s.resumeOrCreate(ctx, storeID, day)
	if err != nil {
		return Report{}, err
	}

	for {
		if err := ctx.Err(); err != nil {
			return batch.Report(), err   // cancelable entre fragmentos
		}

		processed, err := s.processChunk(ctx, batch)   // ← transacción por fragmento
		if err != nil {
			return batch.Report(), err
		}
		if processed == 0 {
			break   // no queda nada
		}
	}
	return s.finalize(ctx, batch)
}
```

> 🧭 **Regla del proyecto.** En un proceso por lotes, **el número de elementos en
> memoria es una constante de configuración, nunca una función del volumen de
> entrada**. Si ves un `[]T` que se llena con el resultado de una consulta sin
> `LIMIT`, eso es la bomba.

### 🩻 Esto sí funciona igual

Y aquí mucho, porque el procesamiento por lotes es un problema viejo con soluciones
maduras en los dos mundos:

- **El modelo de *chunk*** —leer N, procesar N, escribir N, confirmar— es
  exactamente el de Spring Batch. La estructura mental se traslada intacta.
- **El punto de control transaccional** es el `ExecutionContext` del `Step`. Mismo
  mecanismo, mismo porqué.
- **La idempotencia como requisito** es igual de necesaria en los dos.
- **El dimensionado del fragmento** es el mismo intercambio: fragmentos grandes
  reducen la sobrecarga de transacción y aumentan el trabajo que se pierde al
  fallar.
- **El patrón outbox** es idéntico en los dos ecosistemas, y por la misma razón:
  no se puede confirmar atómicamente en dos sistemas distintos.
- **La contrapresión** es el mismo problema de la Fase 06, a otra escala.
- **Y el criterio de cuándo un `cron` basta y cuándo hace falta un planificador**
  es el mismo debate de siempre.

---

## 🛠️ 5. CLI de la fase

```bash
# El cierre, como herramienta de línea de comandos. El eje transversal del curso.
./bin/clearinghouse close --day 2026-09-11 --chunk-size 5000
./bin/clearinghouse close --day 2026-09-11 --resume
./bin/clearinghouse status --batch b-2026-09-11
./bin/clearinghouse cancel --batch b-2026-09-11

# Medir la memoria residente mientras corre. Es LA medición de esta fase.
#
# macOS: -o rss da kilobytes
while true; do
  ps -o rss= -p $(pgrep -f 'clearinghouse close') | awk '{printf "%.0f MB\n", $1/1024}'
  sleep 1
done

# Linux: /usr/bin/time -v da el pico de una vez, que es más fiable que muestrear
/usr/bin/time -v ./bin/clearinghouse close --day 2026-09-11 2>&1 | \
  grep -E 'Maximum resident|Elapsed'

# GODEBUG=gctrace=1 muestra cada recolección: cuánta memoria había antes y
# después. En la versión ingenua se ve la curva subir sin bajar.
GODEBUG=gctrace=1 ./bin/clearinghouse close --day 2026-09-11 2>&1 | head -40

# GOMEMLIMIT convierte el OOM en presión sobre el recolector. Con la versión
# ingenua, el proceso se vuelve lentísimo en vez de morir — que es peor de
# diagnosticar y mejor para el 🧨.
GOMEMLIMIT=512MiB ./bin/clearinghouse close --day 2026-09-11

# El progreso, consultable mientras corre.
curl -s localhost:8080/batches/b-2026-09-11 | jq '{
  status, processed, total, percent: (.processed*100/.total | floor),
  chunks_done, last_checkpoint, eta
}'

# Ver el estado de la cola outbox.
docker compose exec postgres psql -U meridian -d meridian -c "
  SELECT status, count(*), min(created_at), max(created_at)
  FROM outbox GROUP BY status ORDER BY status;"

# Y las filas atascadas, que es lo primero que se mira en un incidente.
docker compose exec postgres psql -U meridian -d meridian -c "
  SELECT id, aggregate_type, attempts, last_error, created_at
  FROM outbox WHERE status = 'pending' AND created_at < now() - interval '5 minutes'
  ORDER BY created_at LIMIT 20;"

# El bloqueo del planificador: quién lo tiene.
docker compose exec postgres psql -U meridian -d meridian -c "
  SELECT name, holder, acquired_at, expires_at, now() FROM scheduler_locks;"

# Descargar un reporte grande y comprobar que se sirve en streaming: si el
# primer byte llega rápido y el tamaño total es grande, no se materializó.
curl -s -o /dev/null -w 'primer byte: %{time_starttransfer}s  total: %{time_total}s  tamaño: %{size_download}\n' \
  'localhost:8080/reports/r-001/download?format=csv'

# Generar un millón de movimientos de prueba, con semilla fija para que el
# experimento sea reproducible.
./bin/clearinghouse seed --movements 1000000 --stores 140 --seed 42

# Y los benchmarks de la fase.
go test -run '^$' -bench BenchmarkChunkSize -benchmem -count=5 ./internal/batch
go test -tags=integration -run TestBatchResumable -v ./internal/batch
```

> 💡 **`/usr/bin/time -v` frente a muestrear con `ps`.** Muestrear cada segundo
> **se pierde el pico** si la subida es rápida: en la versión ingenua, el pico
> ocurre durante la copia de un `append` que duplica el slice, y dura
> milisegundos. `Maximum resident set size` lo captura siempre. En macOS, donde no
> está `time -v`, se usa `runtime.ReadMemStats` desde dentro del proceso.

---

## 💻 6. Construcción guiada

### 6.1 🧨 Rompe a propósito: el cierre que carga todo

**Este es el experimento central de la fase y hay que hacerlo antes de leer nada
más.** Escribe la versión ingenua, córrela con un millón de movimientos, y mira.

```go
// services/clearinghouse/internal/batch/naive.go

// CloseDayNaive es la versión que NO hay que escribir. Existe para medirla.
//
// ⚠️ Está en el repositorio a propósito, con este comentario, y con un test que
// verifica que muere. Borrarla haría que la lección se perdiera con el tiempo.
func (s *Service) CloseDayNaive(ctx context.Context, day time.Time) (Report, error) {
	movements, err := s.store.AllMovementsForDay(ctx, day)   // sin LIMIT
	if err != nil {
		return Report{}, err
	}

	entries := make([]ledger.Entry, 0, len(movements))
	for _, m := range movements {
		e, err := s.reconcile(ctx, m)
		if err != nil {
			return Report{}, err
		}
		entries = append(entries, e)
	}
	return s.store.SaveEntries(ctx, entries)
}
```

```go
// Y el instrumental para verlo.
func logMemory(label string, count int) {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)
	log.Printf("%-22s n=%-9d heap=%6d MB  sys=%6d MB  gc=%d",
		label, count, m.HeapAlloc/1<<20, m.Sys/1<<20, m.NumGC)
}
```

```text
$ GODEBUG=gctrace=1 ./bin/clearinghouse close --day 2026-09-11 --naive

cargando movimientos    n=0         heap=     3 MB  sys=    12 MB  gc=0
cargando movimientos    n=200000    heap=   287 MB  sys=   341 MB  gc=14
cargando movimientos    n=400000    heap=   573 MB  sys=   698 MB  gc=19
cargando movimientos    n=600000    heap=   861 MB  sys=  1042 MB  gc=22
cargando movimientos    n=800000    heap=  1147 MB  sys=  1390 MB  gc=24
cargando movimientos    n=1000000   heap=  1433 MB  sys=  1736 MB  gc=26
conciliando             n=1000000   heap=  1433 MB  sys=  1736 MB  gc=26
construyendo asientos   n=400000    heap=  2104 MB  sys=  2498 MB  gc=31
construyendo asientos   n=800000    heap=  2681 MB  sys=  3190 MB  gc=34
signal: killed
```

**Tres cosas que mirar en esa salida**, y ninguna es "se acabó la memoria":

1. **`heap` sube y nunca baja.** El recolector corre 34 veces y no libera nada,
   porque el slice mantiene vivo todo. Un recolector no puede salvarte de un
   diseño que retiene.
2. **`sys` es mayor que `heap`, y bastante.** Esa diferencia es memoria que el
   proceso pidió al sistema y no ha devuelto: en el momento del `append` que
   duplica el slice, **coexisten el slice viejo y el nuevo**. El pico real es mayor
   que la suma de los datos.
3. **El salto de `1433` a `2104` al construir los asientos.** Ahora hay dos
   estructuras de un millón de elementos vivas a la vez, porque `movements` sigue
   referenciado por el bucle.

Ahora con `GOMEMLIMIT`, que es lo que pasa en un contenedor con límite:

```bash
GOMEMLIMIT=512MiB ./bin/clearinghouse close --day 2026-09-11 --naive
```

```text
cargando movimientos    n=400000    heap=   498 MB  sys=   520 MB  gc=847
cargando movimientos    n=420000    heap=   501 MB  sys=   521 MB  gc=1912
cargando movimientos    n=430000    heap=   503 MB  sys=   522 MB  gc=3201
   ...
```

**No muere: se vuelve inútil.** El recolector corre miles de veces intentando
liberar memoria que está viva, el proceso pasa el 95% del tiempo recolectando, y el
cierre que tardaba treinta minutos no termina nunca. **Ese síntoma —lentitud
extrema sin errores— es más difícil de diagnosticar que un OOM limpio**, y es lo
que de verdad pasa en producción con límites de memoria configurados.

### 6.2 Mini proyecto: `chunked-stream`

La versión correcta, y la lección de que **`sql.Rows` se recorre de verdad**.

```go
// labs/chunked-stream/stream.go

// StreamMovements recorre los movimientos de un día SIN materializarlos.
//
// La clave está en que sql.Rows es un CURSOR sobre el resultado del servidor, no
// un slice. Recorrerlo con Next() trae las filas a medida que se piden.
//
// ⚠️ Y aquí hay un detalle que sorprende y hay que saber: el driver de PostgreSQL
// por defecto lee TODO el resultado en memoria antes de devolver Rows. Para que
// el cursor sea de verdad incremental hace falta pedirlo:
//
//   - con database/sql + pgx: la consulta debe ejecutarse dentro de una
//     transacción y usar un cursor declarado, o
//   - con pgx nativo: QueryRow con QueryExecModeCacheStatement y un tamaño de
//     lote, que es lo que hacemos aquí.
//
// Sin eso, "streaming" es una ilusión: el resultado ya está entero en el cliente.
func (s *Store) StreamMovements(ctx context.Context, day time.Time, fn func(ledger.Movement) error) error {
	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{ReadOnly: true})
	if err != nil {
		return fmt.Errorf("abriendo transacción de lectura: %w", err)
	}
	defer tx.Rollback()

	// El cursor declarado obliga al servidor a mantener el resultado y
	// entregarlo por lotes.
	if _, err := tx.ExecContext(ctx,
		`DECLARE movement_cursor CURSOR FOR
		 SELECT id, store_id, occurred_at, kind, amount_minor, currency
		 FROM movements WHERE day = $1 ORDER BY id`, day); err != nil {
		return fmt.Errorf("declarando el cursor: %w", err)
	}

	for {
		rows, err := tx.QueryContext(ctx, `FETCH 1000 FROM movement_cursor`)
		if err != nil {
			return fmt.Errorf("leyendo del cursor: %w", err)
		}

		n := 0
		for rows.Next() {
			var m ledger.Movement
			if err := rows.Scan(&m.ID, &m.StoreID, &m.OccurredAt,
				&m.Kind, &m.AmountMinor, &m.Currency); err != nil {
				rows.Close()
				return fmt.Errorf("escaneando movimiento: %w", err)
			}
			if err := fn(m); err != nil {
				rows.Close()
				return err
			}
			n++
		}
		if err := rows.Err(); err != nil {
			rows.Close()
			return fmt.Errorf("recorriendo el lote: %w", err)
		}
		rows.Close()

		if n == 0 {
			return nil   // el cursor se agotó
		}
	}
}
```

Y la versión con iterador, que es la adopción de la Fase 08 rindiendo por segunda
vez:

```go
// Movements devuelve un iterador. El consumidor usa `for range` y la memoria
// sigue siendo la de un lote.
//
// Compárese con devolver []Movement: el iterador impide materializar por
// accidente, y ese es su valor principal aquí.
func (s *Store) Movements(ctx context.Context, day time.Time) iter.Seq2[ledger.Movement, error] {
	return func(yield func(ledger.Movement, error) bool) {
		err := s.StreamMovements(ctx, day, func(m ledger.Movement) error {
			if !yield(m, nil) {
				return errStopIteration
			}
			return nil
		})
		if err != nil && !errors.Is(err, errStopIteration) {
			yield(ledger.Movement{}, err)
		}
	}
}
```

> 📐 **Cómo se mide.** Entrada **B-19**: *reporte de 500.000 filas, streaming
> frente a carga completa*. Se mide **memoria residente máxima**, tiempo total,
> **tiempo hasta el primer byte** —que es lo que el usuario percibe— y número de
> recolecciones.
>
> La hipótesis: *"el streaming mantiene la memoria máxima por debajo de 60 MB
> frente a los más de 1.500 MB de la carga completa, con un coste en tiempo total
> inferior al 15%"*. **Y el veredicto tiene que decir qué se pierde**: en streaming
> no se puede saber el tamaño total de antemano —así que no hay `Content-Length` ni
> barra de progreso— y **un error a mitad de la respuesta ya no se puede convertir
> en un 500**, porque el 200 ya salió. Esa tensión se resolvió en §6.6.

### 6.3 Mini proyecto: `checkpoint-lab`

El punto de control transaccional, que es el corazón de la reanudación.

```sql
-- services/clearinghouse/migrations/20260912100000_create_batches.sql
-- +goose Up

CREATE TABLE batches (
    id              TEXT PRIMARY KEY,
    period_day      DATE        NOT NULL,
    status          TEXT        NOT NULL,

    -- EL PUNTO DE CONTROL. Es el identificador del último movimiento procesado,
    -- y se actualiza en la MISMA transacción que los asientos de su fragmento.
    --
    -- Se usa el id y no un desplazamiento numérico por la lección de la Fase 09:
    -- un cursor sobre una clave ordenada no se degrada y es estable ante
    -- inserciones concurrentes.
    checkpoint      TEXT        NOT NULL DEFAULT '',

    total_expected  BIGINT      NOT NULL DEFAULT 0,
    processed       BIGINT      NOT NULL DEFAULT 0,
    failed          BIGINT      NOT NULL DEFAULT 0,
    chunks_done     INTEGER     NOT NULL DEFAULT 0,

    started_at      TIMESTAMPTZ NOT NULL,
    updated_at      TIMESTAMPTZ NOT NULL,
    finished_at     TIMESTAMPTZ,
    last_error      TEXT        NOT NULL DEFAULT '',

    -- Quién lo está ejecutando y hasta cuándo se le supone vivo. Es lo que
    -- permite detectar un lote huérfano cuyo proceso murió.
    holder          TEXT,
    lease_expires   TIMESTAMPTZ,

    CONSTRAINT batches_status_valid CHECK (
        status IN ('pending','running','completed','failed','cancelled')
    )
);

CREATE UNIQUE INDEX batches_day_uniq ON batches (period_day)
    WHERE status IN ('pending','running','completed');

-- Los asientos llevan la referencia al movimiento que los originó, con
-- restricción única. ESTA es la garantía de idempotencia: si un fragmento se
-- reprocesa, el INSERT del asiento duplicado es rechazado por la base de datos.
--
-- La idempotencia NO se confía a la lógica: se confía al esquema.
CREATE TABLE ledger_entries (
    id          BIGSERIAL PRIMARY KEY,
    batch_id    TEXT        NOT NULL REFERENCES batches(id),
    movement_id TEXT        NOT NULL,
    account     TEXT        NOT NULL,
    amount_minor BIGINT     NOT NULL,
    currency    TEXT        NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL
);

CREATE UNIQUE INDEX ledger_entries_movement_uniq ON ledger_entries (movement_id, account);
-- +goose StatementEnd
```

```go
// services/clearinghouse/internal/batch/chunk.go

// processChunk procesa un fragmento COMPLETO en una transacción: lee, concilia,
// escribe los asientos y avanza el punto de control.
//
// Es la unidad atómica del lote. Todo lo que está dentro ocurre o no ocurre.
func (s *Service) processChunk(ctx context.Context, batch *Batch) (int, error) {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return 0, fmt.Errorf("abriendo la transacción del fragmento: %w", err)
	}
	defer tx.Rollback()

	// 1. LEER: desde el punto de control, N movimientos.
	//    El WHERE id > checkpoint es paginación por cursor (Fase 09), y por la
	//    misma razón: no se degrada con el avance.
	movements, err := s.store.MovementsAfter(ctx, tx, batch.PeriodDay, batch.Checkpoint, s.chunkSize)
	if err != nil {
		return 0, fmt.Errorf("leyendo el fragmento desde %q: %w", batch.Checkpoint, err)
	}
	if len(movements) == 0 {
		return 0, nil
	}

	// 2. PROCESAR. Se acumulan los asientos del fragmento: como máximo
	//    chunkSize elementos en memoria, que es la constante prometida.
	entries := make([]ledger.Entry, 0, len(movements))
	var failed int

	for _, m := range movements {
		entry, err := s.reconcile(ctx, tx, m)
		if err != nil {
			if errors.Is(err, ErrUnreconcilable) {
				// Un movimiento que no concilia NO aborta el lote: se registra
				// como excepción y el proceso sigue.
				//
				// Es la decisión de diseño más importante del lote. Abortar por
				// un movimiento malo entre un millón significa que una noche se
                // pierde por un dato corrupto.
				//
				// 📖 Spring Batch llama a esto skip policy, con su skipLimit, y
				// lo trae hecho. Aquí se escribe, y el límite también.
				if err := s.recordException(ctx, tx, batch.ID, m, err); err != nil {
					return 0, fmt.Errorf("registrando la excepción de %s: %w", m.ID, err)
				}
				failed++
				continue
			}
			// Cualquier otro error SÍ aborta: es un fallo del sistema, no del
			// dato, y seguir sería procesar sobre un estado desconocido.
			return 0, fmt.Errorf("conciliando el movimiento %s: %w", m.ID, err)
		}
		entries = append(entries, entry...)
	}

	// Y el límite de excepciones: si falla demasiado, algo está mal de verdad y
	// seguir es tirar el trabajo.
	if batch.Failed+int64(failed) > s.maxFailures {
		return 0, fmt.Errorf("%w: %d excepciones supera el límite de %d",
			ErrTooManyFailures, batch.Failed+int64(failed), s.maxFailures)
	}

	// 3. ESCRIBIR los asientos. La restricción única los hace idempotentes:
	//    ON CONFLICT DO NOTHING convierte un reproceso en una no-operación.
	written, err := s.store.InsertEntries(ctx, tx, entries)
	if err != nil {
		return 0, fmt.Errorf("escribiendo %d asientos: %w", len(entries), err)
	}

	// 4. AVANZAR EL PUNTO DE CONTROL, en la MISMA transacción.
	//    Esta línea es la que hace el lote reanudable.
	last := movements[len(movements)-1]
	if err := s.store.AdvanceCheckpoint(ctx, tx, batch.ID, last.ID,
		int64(len(movements)), int64(failed)); err != nil {
		return 0, fmt.Errorf("avanzando el punto de control a %s: %w", last.ID, err)
	}

	// 5. RENOVAR EL ARRENDAMIENTO, también dentro: si el proceso muere, el
	//    arrendamiento expira y otro puede retomar el lote.
	if err := s.store.RenewLease(ctx, tx, batch.ID, s.holder, s.clock.Now().Add(s.leaseTTL)); err != nil {
		return 0, fmt.Errorf("renovando el arrendamiento: %w", err)
	}

	if err := tx.Commit(); err != nil {
		return 0, fmt.Errorf("confirmando el fragmento: %w", err)
	}

	// Solo DESPUÉS del commit se actualiza el estado en memoria.
	batch.Checkpoint = last.ID
	batch.Processed += int64(len(movements))
	batch.Failed += int64(failed)
	batch.ChunksDone++

	s.logger.Info("fragmento confirmado",
		slog.String("batch", batch.ID),
		slog.Int("movimientos", len(movements)),
		slog.Int("asientos", written),
		slog.Int("excepciones", failed),
		slog.String("checkpoint", last.ID),
		slog.Float64("progreso", batch.Progress()))

	return len(movements), nil
}
```

> 🧭 **Regla del proyecto.** La idempotencia se garantiza **en el esquema**, no en
> la lógica. `UNIQUE (movement_id, account)` con `ON CONFLICT DO NOTHING` hace que
> reprocesar un fragmento sea seguro por construcción. Confiarlo a un
> `if yaExiste()` en Go tiene una carrera y depende de que nadie escriba por otra
> vía.

> 🧪 **Prueba de fuego.** El test de reanudación, que es el que de verdad importa:
>
> ```bash
> ./bin/clearinghouse seed --movements 100000 --seed 42
> ./bin/clearinghouse close --day 2026-09-11 &
> sleep 4 && kill -9 $!          # SIGKILL: sin oportunidad de limpiar
> ./bin/clearinghouse close --day 2026-09-11 --resume
>
> # Y la verificación:
> psql -c "SELECT count(*) FROM ledger_entries WHERE batch_id = 'b-2026-09-11';"
> psql -c "SELECT count(DISTINCT movement_id) FROM ledger_entries;"
> ```
>
> Los dos números tienen que cuadrar con lo esperado, y el segundo tiene que ser
> exactamente el número de movimientos conciliables. **La mentira de la pantalla:**
> si usas `kill` (SIGTERM) en vez de `kill -9`, el apagado ordenado de la Fase 07
> cierra el fragmento en curso limpiamente y el test es mucho más flojo. **Prueba
> con `-9`**, que es lo que hace un OOM o un fallo de hardware.

### 6.4 Mini proyecto: `outbox-lab`

Donde OpsReport y EventRelay se encuentran de verdad.

**El problema.** OpsReport termina un trabajo y hay que notificar al socio. Dos
operaciones:

1. `UPDATE work_items SET status = 'done'`
2. Publicar el evento en EventRelay

**No se pueden hacer atómicamente**, porque están en sistemas distintos. Y las dos
formas ingenuas fallan:

```go
// ❌ Publicar y luego guardar: si el guardado falla, el socio recibió un evento
//    de algo que no ocurrió. Imposible de deshacer.
publish(event)
tx.Commit()

// ❌ Guardar y luego publicar: si el proceso muere entre las dos, el trabajo está
//    hecho y el socio nunca se entera. Pérdida silenciosa.
tx.Commit()
publish(event)   // ← ☠️ aquí
```

**La solución: escribir el evento en la MISMA base de datos, en la MISMA
transacción**, y despacharlo aparte.

```sql
-- +goose Up
CREATE TABLE outbox (
    id              BIGSERIAL PRIMARY KEY,
    aggregate_type  TEXT        NOT NULL,   -- work_item, batch, delivery
    aggregate_id    TEXT        NOT NULL,
    event_type      TEXT        NOT NULL,   -- work_item.completed
    payload         JSONB       NOT NULL,
    status          TEXT        NOT NULL DEFAULT 'pending',
    attempts        INTEGER     NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL,
    published_at    TIMESTAMPTZ,
    last_error      TEXT        NOT NULL DEFAULT '',

    CONSTRAINT outbox_status_valid CHECK (status IN ('pending','published','failed'))
);

-- Índice PARCIAL, como el de las entregas en la Fase 09: solo indexa lo
-- pendiente. Una tabla con diez millones de eventos publicados y cincuenta
-- pendientes tiene un índice de cincuenta entradas.
CREATE INDEX outbox_pending_idx ON outbox (id) WHERE status = 'pending';
```

```go
// services/opsreport/internal/opsreport/service.go

// Complete marca el trabajo como terminado Y encola el evento, atómicamente.
//
// Esta función es la razón por la que OpsReport usa PostgreSQL y no Mongo: el
// invariante "el estado y el evento se guardan juntos o no se guarda ninguno"
// abarca dos tablas, y eso necesita una transacción.
func (s *Service) Complete(ctx context.Context, id string, failureReason string) (workitem.WorkItem, error) {
	var result workitem.WorkItem

	err := s.withTx(ctx, func(tx *sql.Tx) error {
		item, err := s.store.FindByID(ctx, tx, id)
		if err != nil {
			return err
		}

		now := s.clock.Now()
		if failureReason == "" {
			err = item.MarkDone(now)
		} else {
			err = item.MarkFailed(now, failureReason)
		}
		if err != nil {
			return fmt.Errorf("%w: %v", ErrConflict, err)
		}

		if err := s.store.Update(ctx, tx, item); err != nil {
			return err
		}

		// EL OUTBOX, en la misma transacción. Si el Commit falla, no hay ni
		// cambio de estado ni evento. Si tiene éxito, están los dos.
		event := WorkItemCompleted{
			WorkItemID:        item.ID,
			ExternalReference: item.ExternalReference,
			Kind:              string(item.Kind),
			Status:            string(item.Status),
			FinishedAt:        item.FinishedAt,
		}
		if err := s.outbox.Append(ctx, tx, outbox.Record{
			AggregateType: "work_item",
			AggregateID:   item.ID,
			EventType:     "work_item." + string(item.Status),
			Payload:       mustJSON(event),
			CreatedAt:     now,
		}); err != nil {
			return fmt.Errorf("encolando el evento: %w", err)
		}

		result = item
		return nil
	})

	return result, err
}
```

Y el despachador, que es un consumidor del mismo `SKIP LOCKED` de la Fase 09:

```go
// services/opsreport/internal/outbox/dispatcher.go

// Dispatcher lee el outbox y publica. Corre como una goroutine del servicio, o
// como un proceso aparte — las dos opciones tienen su argumento y la elección
// está en §6.5.
func (d *Dispatcher) Run(ctx context.Context) error {
	ticker := time.NewTicker(d.interval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-ticker.C:
		}

		// Un lote cada vez. Si hubo trabajo, se sondea INMEDIATAMENTE otra vez
		// en vez de esperar al tic: bajo carga, el despachador va tan rápido
		// como pueda; en reposo, sondea cada `interval`.
		for {
			n, err := d.dispatchBatch(ctx)
			if err != nil {
				d.logger.Error("error despachando el outbox", slog.String("err", err.Error()))
				break
			}
			if n < d.batchSize {
				break   // no quedaba nada más
			}
		}
	}
}

func (d *Dispatcher) dispatchBatch(ctx context.Context) (int, error) {
	tx, err := d.db.BeginTx(ctx, nil)
	if err != nil {
		return 0, err
	}
	defer tx.Rollback()

	// El mismo patrón de la Fase 09: reclamar con SKIP LOCKED. Varias
	// instancias del despachador no se pisan.
	records, err := d.store.ClaimPending(ctx, tx, d.batchSize)
	if err != nil {
		return 0, fmt.Errorf("reclamando eventos: %w", err)
	}
	if len(records) == 0 {
		return 0, tx.Commit()
	}

	published := make([]int64, 0, len(records))
	for _, r := range records {
		// ⚠️ LA GARANTÍA QUE ESTO DA ES "AL MENOS UNA VEZ", NO "EXACTAMENTE UNA".
		//
		// Si publicamos con éxito y el Commit posterior falla, el evento se
		// vuelve a despachar. Es INEVITABLE: no hay transacción entre PostgreSQL
		// y EventRelay.
		//
		// Por eso el evento lleva su identificador y EventRelay lo deduplica con
		// la clave de idempotencia (Fases 09 y 12). La garantía de "exactamente
		// una vez" la da el CONSUMIDOR, nunca el productor.
		if err := d.publisher.Publish(ctx, r); err != nil {
			d.logger.Warn("no se pudo publicar", slog.Int64("id", r.ID))
			continue   // se reintentará; el arrendamiento del SKIP LOCKED expira
		}
		published = append(published, r.ID)
	}

	if len(published) > 0 {
		if err := d.store.MarkPublished(ctx, tx, published, d.clock.Now()); err != nil {
			return 0, fmt.Errorf("marcando %d eventos como publicados: %w", len(published), err)
		}
	}
	return len(records), tx.Commit()
}
```

> 🧭 **Regla del proyecto, y es la que hay que memorizar del outbox.** El productor
> garantiza **al menos una vez**. La deduplicación es responsabilidad del
> **consumidor**. Cualquier diseño que prometa "exactamente una vez" entre dos
> sistemas sin transacción distribuida está mintiendo o está escondiendo la
> deduplicación en algún sitio.

📖 En Spring, esto se hace con `@TransactionalEventListener(phase = AFTER_COMMIT)`
—que **no** es lo mismo: el evento se publica en memoria después del commit, y si
el proceso muere entre el commit y la publicación, se pierde— o con un outbox
escrito igual que este. **La anotación es cómoda y no da la garantía; el outbox
sí.** Conviene saberlo, porque mucha gente cree que `AFTER_COMMIT` resuelve el
problema.

### 6.5 Scheduling: `Ticker`, cron y el bloqueo

**Primero, la decisión sencilla:**

```go
// Para "cada N tiempo", time.Ticker basta y no necesita dependencias.
ticker := time.NewTicker(5 * time.Minute)
defer ticker.Stop()

for {
	select {
	case <-ctx.Done():
		return ctx.Err()
	case <-ticker.C:
		run()
	}
}
```

> ⚠️ **`Ticker` no es un cron y la diferencia importa.** Un `Ticker` de 24 horas
> dispara 24 horas **después de arrancar el proceso**: si despliegas a las 15:30,
> tu "cierre nocturno" corre a las 15:30. Y si el proceso se reinicia, el contador
> vuelve a empezar. Para "todos los días a las 02:00" hace falta un cron de verdad
> o calcular el siguiente instante a mano.

```go
// El cálculo a mano, que son quince líneas y evita una dependencia.
func nextRunAt(now time.Time, hour, minute int, loc *time.Location) time.Time {
	local := now.In(loc)
	next := time.Date(local.Year(), local.Month(), local.Day(), hour, minute, 0, 0, loc)
	if !next.After(local) {
		// AddDate, no Add(24h): la lección de la zona horaria de la Fase 09.
		next = next.AddDate(0, 0, 1)
	}
	return next
}
```

> ⚖️ **La decisión sobre `robfig/cron`, evaluada.** Es una librería madura que
> entiende la sintaxis cron, maneja zonas horarias y tiene una API limpia.
> **Meridian no la usa**, y el motivo es que tiene **dos** trabajos programados —el
> cierre nocturno y la ingesta de AtlasSync—, y quince líneas de `nextRunAt` los
> cubren.
>
> **Cuándo sí valdría la pena:** con más de cinco trabajos, con expresiones cron
> configurables por el operador, o si necesitas la semántica exacta de cron
> (`0 2 * * 1-5`). Entra en `docs/rechazos.md` con esa condición.

**Y ahora el problema de verdad: con tres instancias, el cierre se ejecuta tres
veces.**

```go
// services/clearinghouse/internal/scheduler/lock.go

// TryAcquire intenta tomar el arrendamiento de un trabajo programado.
//
// Es el equivalente de ShedLock de Spring, escrito en veinte líneas. El
// mecanismo es un UPSERT condicional: solo lo consigue quien encuentre el
// arrendamiento libre o caducado.
//
// ⚠️ Y a diferencia del bloqueo en Valkey de la Fase 12, ESTE SÍ SIRVE PARA
// CORRECCIÓN, porque la garantía la da la transacción de PostgreSQL, no un TTL
// esperanzado. La distinción es exactamente la que el ⚠️ de aquella fase
// explicaba, y aquí está el lado bueno.
const acquireLockSQL = `
INSERT INTO scheduler_locks (name, holder, acquired_at, expires_at)
VALUES ($1, $2, $3, $4)
ON CONFLICT (name) DO UPDATE
SET holder = EXCLUDED.holder,
    acquired_at = EXCLUDED.acquired_at,
    expires_at = EXCLUDED.expires_at
WHERE scheduler_locks.expires_at < $3       -- solo si el anterior caducó
RETURNING holder`

func (l *Locker) TryAcquire(ctx context.Context, name string, ttl time.Duration) (bool, error) {
	now := l.clock.Now()

	var holder string
	err := l.db.QueryRowContext(ctx, acquireLockSQL,
		name, l.holder, now, now.Add(ttl)).Scan(&holder)

	if errors.Is(err, sql.ErrNoRows) {
		return false, nil   // otro lo tiene y no ha caducado
	}
	if err != nil {
		return false, fmt.Errorf("adquiriendo el arrendamiento %q: %w", name, err)
	}
	return holder == l.holder, nil
}

// Renew alarga el arrendamiento mientras el trabajo sigue vivo.
//
// Es imprescindible para trabajos largos: el cierre tarda noventa minutos y un
// arrendamiento de dos horas fijo significa que, si el proceso muere a los diez
// minutos, nadie puede retomarlo hasta dentro de dos horas.
//
// Con renovación cada treinta segundos y TTL de dos minutos, un proceso muerto
// libera el trabajo en dos minutos.
func (l *Locker) Renew(ctx context.Context, name string, ttl time.Duration) error {
	// ...
}
```

> 🧭 **Regla del proyecto.** Todo trabajo programado que pueda correr en varias
> instancias adquiere un arrendamiento **con renovación**, y el TTL se dimensiona
> para que un proceso muerto libere pronto, no para que cubra la duración del
> trabajo. Un arrendamiento sin renovación obliga a elegir entre "se ejecuta dos
> veces" y "nadie lo retoma en horas".

### 6.6 Los reportes en streaming

La otra mitad de B-19, y donde se resuelve la tensión del error a mitad de la
respuesta.

```go
// services/opsreport/internal/httpapi/reports.go

// downloadReport sirve el reporte SIN materializarlo.
func (h *ReportHandler) downloadReport(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	format := r.URL.Query().Get("format")

	// ⚠️ LA TENSIÓN DEL STREAMING, y hay que decidirla explícitamente:
	//
	// En cuanto se escribe el primer byte, el código de estado ya salió. Un
	// error a mitad NO se puede convertir en un 500: lo único que se puede hacer
	// es cortar la conexión y registrar el fallo.
	//
	// Las tres opciones, y la que elegimos:
	//
	//  a) Materializar en memoria y responder de una vez.
	//     → error limpio, memoria proporcional al tamaño. Es el 🧨 de esta fase.
	//
	//  b) Materializar en un archivo temporal y servirlo con http.ServeContent.
	//     → error limpio, memoria constante, soporta Range y reanudación.
	//       Cuesta E/S de disco y espacio temporal.
	//
	//  c) Streaming directo.
	//     → memoria constante, primer byte inmediato, y un error a mitad
	//       produce una descarga truncada que el cliente tiene que detectar.
	//
	// Meridian elige (c) para CSV y JSON —donde el cliente es un script que
	// puede verificar—, y (b) para HTML, donde un documento truncado se
	// renderiza a medias y el usuario no se entera.
	//
	// La defensa de (c): el "checksum trailer" de abajo.

	meta, err := h.svc.ReportMeta(r.Context(), id)
	if err != nil {
		writeError(w, r, err)   // aquí TODAVÍA se puede
		return
	}
	if meta.Status != report.StatusReady {
		writeError(w, r, fmt.Errorf("%w: el reporte está en estado %s", ErrConflict, meta.Status))
		return
	}

	w.Header().Set("Content-Type", contentTypeFor(format))
	w.Header().Set("Content-Disposition",
		fmt.Sprintf(`attachment; filename=%q`, meta.Filename(format)))
	// Trailer anuncia cabeceras que llegarán DESPUÉS del cuerpo. Es la forma
	// estándar de decir "esto terminó bien" en una respuesta en streaming, y
	// casi nadie la usa.
	w.Header().Set("Trailer", "X-Meridian-Row-Count, X-Meridian-Status")

	w.WriteHeader(http.StatusOK)   // ← a partir de aquí no hay vuelta atrás

	buf := bufio.NewWriterSize(w, 64<<10)

	rows, err := h.svc.StreamRows(r.Context(), id, format, buf)
	if err != nil {
		// No se puede cambiar el estado. Lo que sí se puede:
		//  - registrar el fallo con todo el contexto
		//  - anunciarlo en el trailer, para el cliente que lo mire
		//  - NO vaciar el buffer, para que la respuesta quede visiblemente corta
		h.logger.Error("fallo sirviendo el reporte en streaming",
			slog.String("report", id), slog.Int64("filas_escritas", rows),
			slog.String("err", err.Error()))
		w.Header().Set("X-Meridian-Status", "error")
		return
	}

	if err := buf.Flush(); err != nil {   // ← el Flush de la Fase 03, otra vez
		h.logger.Error("no se pudo vaciar el buffer del reporte",
			slog.String("report", id), slog.String("err", err.Error()))
		w.Header().Set("X-Meridian-Status", "error")
		return
	}

	w.Header().Set("X-Meridian-Row-Count", strconv.FormatInt(rows, 10))
	w.Header().Set("X-Meridian-Status", "complete")
}
```

> ⚠️ **`WriteTimeout` del servidor y las descargas largas.** El `WriteTimeout` de
> 30 s de la Fase 05 corta una descarga de quinientas mil filas a mitad. Hay dos
> soluciones y **la mala es subirlo globalmente**, porque entonces todos los
> endpoints quedan expuestos a un cliente lento.
>
> La buena, desde Go 1.20: `http.ResponseController` permite ajustar el plazo **de
> esa conexión concreta**:
> ```go
> rc := http.NewResponseController(w)
> if err := rc.SetWriteDeadline(time.Now().Add(10 * time.Minute)); err != nil {
>     h.logger.Warn("no se pudo ampliar el plazo de escritura")
> }
> ```
> Es la adopción de la Fase 08 que no vimos entonces y aquí resuelve un problema
> real.

#### Por qué `?format=csv` y no `Accept`

La Fase 05 dejó anotado que la negociación de contenido por `Accept` se volvería
necesaria aquí, con tres formatos de descarga. **Y la decisión es la contraria**,
así que hay que justificarla:

- **El cliente de esta ruta es un navegador o un `curl` en un cron**, no un
  cliente de API. Un enlace `<a href="...?format=csv">` funciona; pedirle a un
  usuario que ponga una cabecera `Accept` no.
- **`Accept` es negociación, no selección.** Un navegador manda
  `Accept: text/html,application/xhtml+xml,*/*;q=0.8`, con lo que la elección
  correcta según el estándar es HTML — que no es lo que el usuario quiso al pulsar
  "descargar CSV". Implementar `q` bien es más código del que parece, y el
  resultado sigue siendo ambiguo.
- **La URL con el formato dentro es cacheable y compartible.** Con `Accept`, dos
  respuestas distintas viven en la misma URL y hace falta `Vary: Accept` para que
  las cachés intermedias no mientan. Es otra cosa que hacer bien y que casi nadie
  hace.

> 🧭 **La regla, que vale más que el caso.** `Accept` para **representaciones** del
> mismo recurso a clientes que negocian de verdad; parámetro en la URL para
> **descargas** que un humano inicia. El ejercicio 🔥 de la Fase 05 sigue siendo
> útil: implementa `Accept` una vez, con su `Vary`, para ver por qué aquí no se usó.

#### El `errWriter` de Pike, en el escritor de CSV

La Fase 03 anotó este patrón para esta fase, y el escritor de CSV es su caso
literal: veinte escrituras seguidas con el mismo manejo de error.

```go
// services/opsreport/internal/report/csv.go

// errWriter acumula el primer error y convierte en no-op todo lo posterior.
// Es el patrón de "Errors are values" de Rob Pike, y existe por una razón muy
// concreta: sin él, escribir una fila de CSV son ocho `if err != nil` que
// devuelven el mismo error, y el ruido esconde la lógica.
type errWriter struct {
	w   *csv.Writer
	err error
}

func (ew *errWriter) write(record []string) {
	if ew.err != nil {
		return // ya falló antes: no se intenta más y no se pisa el error original
	}
	ew.err = ew.w.Write(record)
}

func WriteCSV(ctx context.Context, w io.Writer, rows iter.Seq2[report.Row, error]) (int64, error) {
	ew := &errWriter{w: csv.NewWriter(w)}
	ew.write([]string{"id", "tienda", "fecha", "concepto", "importe", "moneda", "estado"})

	var n int64
	for row, err := range rows {
		if err != nil {
			return n, fmt.Errorf("leyendo la fila %d: %w", n, err)
		}
		// Siete campos, ninguna comprobación de error entre ellos. Esa es toda
		// la ganancia del patrón, y es suficiente para justificarlo.
		ew.write([]string{
			row.ID, row.StoreID, row.Date.Format(time.RFC3339),
			row.Concept, row.Amount.String(), row.Currency, string(row.Status),
		})
		n++

		// El error se comprueba una vez por fila, no una vez por campo. Salir
		// temprano importa: si el cliente cortó la conexión, seguir leyendo
		// medio millón de filas de PostgreSQL es trabajo tirado.
		if ew.err != nil {
			return n, fmt.Errorf("escribiendo la fila %d: %w", n, ew.err)
		}
	}

	ew.w.Flush()                        // el Flush de la Fase 03, una vez más
	if err := ew.w.Error(); err != nil {
		return n, fmt.Errorf("vaciando el csv: %w", err)
	}
	return n, nil
}
```

> 🪞 **Tu instinto de Java dice** que esto es un `try/catch` envolviendo el bucle y
> ya está. **Y esta vez tiene razón a medias:** el `try` hace lo mismo con menos
> código. Lo que gana el `errWriter` es que **el error sigue siendo un valor**: se
> puede inspeccionar, envolver con `%w`, guardar en el struct, o decidir seguir
> escribiendo el resto y reportar al final. Un `catch` te saca del bucle y esa
> decisión ya no es tuya.
>
> ⚠️ **Y la trampa del patrón:** si `write` se llama cien veces sin comprobar
> `ew.err` ni una, el trabajo se hace igual —cien llamadas que no hacen nada— y el
> error llega cien iteraciones tarde. Por eso arriba se comprueba **una vez por
> fila**. El patrón elimina comprobaciones; no elimina pensar dónde va la que queda.

### 6.7 La comparación con Spring Batch, con el código delante

El gemelo Java de `reference/clearinghouse-spring/` existe para esto. Pon los dos
lado a lado.

**Spring Batch:**

```java
@Bean
public Step reconcileStep(JobRepository jobRepository,
                          PlatformTransactionManager txManager) {
    return new StepBuilder("reconcile", jobRepository)
        .<Movement, LedgerEntry>chunk(5000, txManager)
        .reader(movementReader())        // JdbcCursorItemReader: cursor, no lista
        .processor(reconcileProcessor())
        .writer(ledgerWriter())          // JdbcBatchItemWriter: INSERT por lotes
        .faultTolerant()
          .skip(UnreconcilableException.class)
          .skipLimit(1000)               // ← la skip policy, en una línea
          .retry(DeadlockLoserDataAccessException.class)
          .retryLimit(3)                 // ← reintento por ítem, en una línea
        .listener(new ChunkProgressListener())
        .build();
}
```

**Go, lo equivalente** (§6.3, resumido):

```go
for {
    if err := ctx.Err(); err != nil { return err }
    n, err := s.processChunk(ctx, batch)   // ~70 líneas con todo dentro
    if err != nil { return err }
    if n == 0 { break }
}
```

**La comparación honesta, característica por característica:**

| | Spring Batch | Go, escrito |
|---|---|---|
| Modelo de *chunk* con transacción | **declarativo**, `.chunk(5000, txManager)` | ~70 líneas |
| Punto de control / reanudación | **`JobRepository`, automático** | tabla `batches` + `AdvanceCheckpoint`, ~40 líneas |
| Reintento **por ítem** | `.retry(X.class).retryLimit(3)` | **no implementado**; hay que escribirlo |
| Política de omisión (*skip*) | `.skip(X.class).skipLimit(1000)` | ~15 líneas |
| Particionado / paralelismo | `PartitionHandler`, declarativo | goroutines + `errgroup`, ~30 líneas |
| Métricas de job | **Micrometer integrado** | contadores propios (Fase 14) |
| Historial de ejecuciones | **`JobRepository`, consultable con SQL** | tabla `batches`, escrita |
| Reinicio desde la línea de comandos | `JobOperator.restart(id)` | bandera `--resume`, escrita |
| Escuchadores de ciclo de vida | `StepExecutionListener`, etc. | llamadas explícitas |
| Configuración de un job nuevo | ~20 líneas de `@Bean` | ~150 líneas de código |
| **Total del cierre completo** | **~180 líneas** de configuración + lógica | **~520 líneas** |
| Dependencias | spring-batch-core + infraestructura | stdlib + `database/sql` |
| Tamaño del binario / artefacto | JAR + JVM | binario de ~18 MB |
| Tiempo hasta el primer lote funcionando | **horas** (si conoces el framework) | días |
| ¿Sabes exactamente qué hace? | no del todo | **sí, lo escribiste** |
| Depurar un comportamiento raro | leer la documentación y el framework | leer tu código |

> ⚖️ **El veredicto honesto, y es el corazón de esta fase.**
>
> **Spring Batch resuelve reanudación, reintento por ítem, particionado y métricas
> de job que aquí hay que escribir. Si tu proceso por lotes es complejo de verdad,
> eso es un argumento real a favor de Java, y así se dice.**
>
> Lo que es "complejo de verdad": más de tres o cuatro jobs distintos, pasos
> encadenados con flujos condicionales, reintento por ítem con políticas
> diferenciadas, particionado sobre varias máquinas, o un operador que necesita
> reiniciar jobs desde una consola sin tocar código.
>
> **Y dónde Go gana aquí**, que también hay que decirlo: en un solo proceso por
> lotes, bien delimitado, que tiene que arrancar rápido y consumir poco —el agente
> de tienda, un job en un contenedor efímero que se ejecuta y muere—, las 520
> líneas son código que entiendes entero, sin framework que aprender, en un binario
> de 18 MB que arranca en milisegundos. Y **el particionado con goroutines es
> genuinamente más simple** que la configuración de particionado de Spring Batch.
>
> La pregunta no es cuál es mejor. Es **cuántos lotes vas a escribir**: uno, o
> quince.

### 6.8 El dimensionado del fragmento

```go
// El intercambio, con los cuatro ejes:
//
// FRAGMENTOS GRANDES (50.000):
//   ✅ menos transacciones → menos sobrecarga de commit
//   ✅ menos viajes a la base de datos
//   ❌ más memoria por fragmento
//   ❌ más trabajo perdido al fallar
//   ❌ MÁS LATENCIA DE CANCELACIÓN: el SIGTERM espera al fragmento en curso
//   ❌ transacciones largas → más bloqueos y más trabajo para el vacuum
//
// FRAGMENTOS PEQUEÑOS (100):
//   ✅ memoria mínima, cancelación casi inmediata, poco trabajo perdido
//   ❌ sobrecarga de commit por fragmento: con 1M de filas son 10.000 commits
```

> 📐 **Cómo se mide.** Entrada **B-20**: *tamaño de fragmento frente a tiempo total
> del cierre*. Con 1.000.000 de movimientos y tamaños de 100, 500, 1.000, 5.000,
> 10.000 y 50.000. Se reportan **cuatro** columnas, no una: tiempo total, memoria
> máxima, **latencia de cancelación** (el tiempo entre el `SIGTERM` y la salida) y
> trabajo perdido al matar el proceso a mitad.
>
> **La latencia de cancelación es la columna que nadie mide y la que decide el
> despliegue**: es la que determina el `terminationGracePeriodSeconds` que tu
> plataforma necesita, y es la conexión directa con el ejercicio 19 de la Fase 07.
>
> La hipótesis: *"el tiempo total mejora hasta unos 5.000 elementos por fragmento y
> se estabiliza; la memoria y la latencia de cancelación crecen linealmente a partir
> de ahí"*. El veredicto recomienda un valor **con su condición**: si la ventana de
> apagado es corta, se baja aunque cueste tiempo.

### 6.9 AtlasSync: la ingesta programada

```go
// services/atlassync/internal/ingest/scheduler.go

// Run programa la ingesta diaria, con arrendamiento y registro de ejecución.
func (s *Scheduler) Run(ctx context.Context) error {
	for {
		next := nextRunAt(s.clock.Now(), s.hour, s.minute, s.loc)
		wait := next.Sub(s.clock.Now())

		s.logger.Info("próxima ingesta programada",
			slog.Time("at", next), slog.Duration("in", wait))

		timer := time.NewTimer(wait)
		select {
		case <-ctx.Done():
			timer.Stop()
			return ctx.Err()
		case <-timer.C:
		}

		// Solo una instancia ejecuta.
		acquired, err := s.locker.TryAcquire(ctx, "atlassync.daily-ingest", 30*time.Minute)
		if err != nil {
			s.logger.Error("no se pudo comprobar el arrendamiento", slog.String("err", err.Error()))
			continue
		}
		if !acquired {
			s.logger.Info("la ingesta la ejecuta otra instancia; omitiendo")
			continue
		}

		if err := s.runIngest(ctx); err != nil {
			s.logger.Error("la ingesta falló", slog.String("err", err.Error()))
			// NO se propaga: un fallo de ingesta no debe matar el planificador.
			// Mañana se vuelve a intentar, y el registro queda para el operador.
		}
	}
}
```

Y la invalidación de la caché al terminar, que cierra el círculo con la Fase 12:

```go
func (s *Ingester) runIngest(ctx context.Context) error {
	run := ingest.NewRun(s.clock.Now())

	// ... ingesta de países y tipos de cambio ...

	// La invalidación por versión de generación (Fase 12, §6.7): UN comando,
	// O(1), sin importar cuántas claves haya.
	if err := s.cache.InvalidateAll(ctx); err != nil {
		// La invalidación fallida NO invalida la ingesta: los datos están
		// guardados. La caché servirá datos viejos hasta que expire su TTL, y
		// por eso el TTL existe.
		s.logger.Warn("no se pudo invalidar la caché tras la ingesta",
			slog.String("err", err.Error()))
	}
	return s.store.SaveRun(ctx, run.Complete(s.clock.Now()))
}
```

---

## ⚰️ 7. Autopsia y errores comunes

### ⚰️ Autopsia: el lote que decía que había terminado

**El cadáver.** El cierre de ClearingHouse llevaba tres meses funcionando. Cada
noche terminaba con un informe:

```text
cierre 2026-06-14 completado: 3.214.887 movimientos, 4.102.331 asientos, 78 min
```

Y en el cierre contable del mes, faltaban **catorce mil movimientos**. Repartidos
por varias noches, sin patrón aparente.

```go
// ☕ — el código, y el bug está en dos sitios a la vez
func (s *Service) processChunk(ctx context.Context, batch *Batch) (int, error) {
	movements, err := s.store.MovementsAfter(ctx, batch.Checkpoint, s.chunkSize)
	if err != nil {
		return 0, err
	}
	if len(movements) == 0 {
		return 0, nil
	}

	entries := make([]ledger.Entry, 0, len(movements))
	for _, m := range movements {
		e, err := s.reconcile(ctx, m)
		if err != nil {
			// "Un movimiento que no concilia no debe parar el cierre."
			s.logger.Warn("movimiento omitido", slog.String("id", m.ID))
			continue                                          // ← BUG 1
		}
		entries = append(entries, e...)
	}

	if err := s.store.InsertEntries(ctx, entries); err != nil {   // transacción A
		return 0, err
	}

	last := movements[len(movements)-1]
	if err := s.store.AdvanceCheckpoint(ctx, batch.ID, last.ID); err != nil {  // transacción B
		return 0, err                                          // ← BUG 2
	}
	return len(movements), nil
}
```

**Bug 1: la omisión silenciosa sin registro ni límite.** Un movimiento que no
concilia se registra en el log —que nadie lee— y **no se cuenta en ningún sitio**.
El informe final dice "3.214.887 movimientos" porque cuenta los **leídos**, no los
**conciliados**. Con setenta y ocho omisiones por noche y treinta noches, salen los
catorce mil.

**Bug 2: el punto de control fuera de la transacción del trabajo.** Son dos
transacciones. En la ventana entre ellas:

```text
t0  transacción A confirma: 5.000 asientos escritos
t1  ☠️ el proceso muere (OOM, despliegue, fallo de red)
t2  al reanudar: el punto de control sigue en el fragmento ANTERIOR
t3  se reprocesan 5.000 movimientos → ON CONFLICT DO NOTHING → sin duplicados ✅
```

Ese orden funciona. **Y el inverso, no**: si alguien "optimizó" adelantando el
punto de control para no perder trabajo al reintentar, la ventana produce
**pérdida** en vez de repetición.

**El informe forense:**

| | El lote ☕ | El de §6.3 |
|---|---|---|
| Movimientos omitidos, contabilizados | **no** | sí, `failed` en la tabla |
| Límite de omisiones | **ninguno** | `maxFailures`, y aborta |
| Las excepciones quedan registradas | solo en el log | tabla `batch_exceptions`, consultable |
| El informe distingue leídos de conciliados | **no** | sí |
| Punto de control en la misma transacción | **no**, dos transacciones | sí |
| Una caída entre transacciones produce | repetición (tolerable) o pérdida (mortal) | nada: un fragmento se repite entero |
| Detectable por alguien que mire el informe | **no** | sí: `failed > 0` salta a la vista |
| Tiempo hasta descubrir el problema | **un mes** | inmediato |

**Las dos causas de la muerte, y la que más enseña es la primera:**

**El lote no distinguía "procesado" de "procesado con éxito".** Un proceso por
lotes **tiene que cuadrar**: leídos = conciliados + omitidos + fallidos. Si esa
ecuación no está escrita en el código y verificada al final, el proceso puede
perder trabajo y decir que fue bien. **Es una invariante, y se comprueba como tal:**

```go
// El cierre del lote comprueba la ecuación. Si no cuadra, el lote falla — porque
// un lote que no cuadra ya falló, solo que todavía no lo sabía.
func (s *Service) finalize(ctx context.Context, batch *Batch) (Report, error) {
	read := batch.Processed
	ok := batch.Reconciled
	failed := batch.Failed

	if read != ok+failed {
		return Report{}, fmt.Errorf(
			"%w: leídos=%d conciliados=%d omitidos=%d (faltan %d)",
			ErrInconsistentBatch, read, ok, failed, read-ok-failed)
	}
	// ...
}
```

**Y la segunda:** el punto de control fuera de la transacción del trabajo. Los dos
órdenes posibles tienen una ventana; solo uno de ellos falla hacia el lado seguro,
y depender de eso es depender de que nadie lo "optimice" el año que viene.

> ☕ **El patrón a memorizar.** Un lote que solo dice cuántos elementos **leyó** no
> te está diciendo nada. **La ecuación tiene que cuadrar y hay que comprobarla en
> el código**, porque un lote que pierde trabajo en silencio es peor que uno que
> falla: el que falla te avisa.

### Errores comunes

**1. Cargar el resultado entero en un slice.**
*Síntoma:* memoria proporcional al volumen; OOM, o lentitud extrema con
`GOMEMLIMIT`.
*Causa:* consulta sin `LIMIT` a un `[]T`.
*Fix mínimo:* cursor con fragmentos. Y la pregunta de control: *¿cuántos elementos
hay en memoria a la vez?*

**2. "Streaming" que no lo es.**
*Síntoma:* la memoria sube igual pese a usar `rows.Next()`.
*Causa:* el driver leyó todo el resultado antes de devolver `Rows`.
*Fix mínimo:* cursor declarado dentro de una transacción, o el modo de lotes de
`pgx`.

**3. Punto de control fuera de la transacción.**
*Síntoma:* trabajo duplicado o, peor, perdido tras una caída.
*Causa:* dos transacciones con una ventana entre medias.
*Fix mínimo:* una sola transacción por fragmento, con el punto de control dentro.

**4. Idempotencia confiada a la lógica.**
*Síntoma:* duplicados al reanudar bajo concurrencia.
*Causa:* un `if yaExiste()` tiene una carrera.
*Fix mínimo:* restricción única en el esquema y `ON CONFLICT DO NOTHING`.

**5. Omisiones sin contar ni limitar.**
*Síntoma:* el lote termina "bien" y faltan datos.
*Causa:* la autopsia.
*Fix mínimo:* contarlas, registrarlas en una tabla, poner un límite, y comprobar
la ecuación al cerrar.

**6. El fragmento no mira el contexto.**
*Síntoma:* el `SIGTERM` tarda minutos u horas.
*Causa:* la comprobación está fuera del bucle, o el fragmento es enorme.
*Fix mínimo:* comprobar entre fragmentos, y dimensionar el fragmento pensando en
el apagado (B-20).

**7. Transacción de fragmento demasiado larga.**
*Síntoma:* bloqueos, `idle in transaction`, y el vacuum que no puede limpiar.
*Causa:* fragmentos de cincuenta mil elementos con proceso lento dentro.
*Fix mínimo:* fragmentos más pequeños, y **sacar de la transacción todo lo que no
la necesite** — sobre todo las llamadas de red.

**8. Llamadas HTTP dentro de la transacción del fragmento.**
*Síntoma:* transacciones de varios segundos; un socio lento bloquea la base de
datos.
*Causa:* conciliar contra un servicio externo dentro del `BeginTx`.
*Fix mínimo:* leer, cerrar la transacción, llamar, y abrir otra para escribir. O
mejor: precargar lo externo antes del lote.

**9. `@TransactionalEventListener` (o su equivalente) en vez de outbox.**
*Síntoma:* eventos perdidos cuando el proceso muere tras el commit.
*Causa:* la publicación está fuera de la transacción.
*Fix mínimo:* outbox.

**10. Prometer "exactamente una vez" desde el productor.**
*Síntoma:* duplicados en el consumidor, y nadie los espera.
*Causa:* no existe tal garantía entre dos sistemas sin transacción distribuida.
*Fix mínimo:* "al menos una vez" + deduplicación en el consumidor, y **decirlo en
el contrato**.

**11. `Ticker` usado como cron.**
*Síntoma:* el "cierre nocturno" corre a las 15:30.
*Causa:* `Ticker` cuenta desde el arranque.
*Fix mínimo:* calcular el siguiente instante absoluto.

**12. Trabajo programado sin arrendamiento.**
*Síntoma:* con tres instancias, el cierre corre tres veces.
*Causa:* no hay coordinación.
*Fix mínimo:* arrendamiento en base de datos con renovación.

**13. Arrendamiento sin renovación.**
*Síntoma:* o se ejecuta dos veces, o nadie retoma el trabajo en horas.
*Causa:* el TTL tiene que cubrir la duración del trabajo.
*Fix mínimo:* renovar periódicamente y bajar el TTL.

**14. El informe cuenta leídos en vez de procesados.**
*Síntoma:* el de la autopsia.
*Fix mínimo:* la ecuación comprobada.

**15. `WriteTimeout` que corta una descarga larga.**
*Síntoma:* los reportes grandes se truncan a los 30 s.
*Causa:* el plazo global del servidor.
*Fix mínimo:* `http.ResponseController.SetWriteDeadline` en ese handler, no subir
el global.

### 🧨 Rompe a propósito

Ya hiciste el principal en §6.1. El segundo es más sutil y enseña tanto como el
primero: **la pérdida silenciosa por punto de control adelantado.**

```go
// Invierte el orden a propósito: primero el punto de control, después el trabajo.
func (s *Service) processChunkBroken(ctx context.Context, batch *Batch) (int, error) {
	movements, _ := s.store.MovementsAfter(ctx, batch.Checkpoint, s.chunkSize)
	if len(movements) == 0 {
		return 0, nil
	}

	// "Así, si falla la escritura, al menos no reprocesamos."
	last := movements[len(movements)-1]
	_ = s.store.AdvanceCheckpoint(ctx, batch.ID, last.ID)

	// Y aquí matamos el proceso, un fragmento de cada veinte.
	if batch.ChunksDone%20 == 19 {
		os.Exit(137)   // simula un OOM
	}

	entries := s.reconcileAll(ctx, movements)
	_ = s.store.InsertEntries(ctx, entries)
	return len(movements), nil
}
```

```bash
./bin/clearinghouse seed --movements 100000 --seed 42
while ! ./bin/clearinghouse close --day 2026-09-11 --resume --broken; do :; done

psql -c "SELECT count(*) FROM movements WHERE day = '2026-09-11';"
# 100000
psql -c "SELECT count(DISTINCT movement_id) FROM ledger_entries;"
# 94873
```

**Faltan 5.127 movimientos, y el lote terminó diciendo que había ido bien.** Nada
en el log dice que se perdió nada. La única forma de detectarlo es la ecuación de
la autopsia.

**Y la lección más importante del experimento:** con el orden correcto, el mismo
test produce 100.000 y cero duplicados. **La diferencia entre un lote correcto y
uno que pierde datos en silencio son dos líneas en orden distinto.**

---

## 🧪 8. Ejercicios (28)

**🟢 Fácil (1–6)**

1. Ejecuta el cierre ingenuo con un millón de movimientos y registra la memoria
   cada 100.000. *Criterio:* la curva, el punto de muerte, y explicas por qué `sys`
   supera a `heap`.
2. Repite con `GOMEMLIMIT=512MiB`. *Criterio:* describes el síntoma —lentitud
   extrema sin error— y explicas por qué es peor de diagnosticar que un OOM.
3. Escribe `nextRunAt` y pruébalo con el cambio de horario. *Criterio:* el test
   del día de 23 horas pasa; falla si usas `Add(24*time.Hour)`.
4. Consulta el progreso de un lote mientras corre. *Criterio:* el porcentaje
   avanza y el `eta` es razonable.
5. Provoca una omisión conciliable y verifica que se registra en la tabla de
   excepciones. *Criterio:* el informe final la cuenta y la ecuación cuadra.
6. Usa `curl -w` para comprobar que un reporte se sirve en streaming.
   *Criterio:* `time_starttransfer` es mucho menor que `time_total`.

**🟡 Intermedio (7–17)**

7. Implementa `StreamMovements` con cursor declarado. *Criterio:* demuestras con
   `ReadMemStats` que la memoria es constante, y muestras qué pasa **sin** el
   cursor declarado.
8. Implementa `processChunk` con punto de control en la misma transacción.
   *Criterio:* el test de reanudación con `kill -9` pasa.
9. Reproduce el 🧨 del punto de control adelantado. *Criterio:* cuantificas la
   pérdida y demuestras que el orden correcto la elimina.
10. Implementa la ecuación de cierre y haz que falle. *Criterio:* introduces una
    omisión no contada y el lote aborta con un mensaje que dice cuántos faltan.
11. Implementa la idempotencia con restricción única y `ON CONFLICT DO NOTHING`.
    *Criterio:* ejecutas el lote completo dos veces y el número de asientos no
    cambia.
12. Implementa el límite de omisiones. *Criterio:* con 1.001 omisiones y límite de
    1.000, el lote aborta y **el trabajo ya confirmado se conserva**.
13. Implementa el outbox de OpsReport. *Criterio:* matas el proceso justo después
    del commit y el evento se despacha al reiniciar.
14. Implementa el despachador con `SKIP LOCKED`. *Criterio:* tres despachadores
    concurrentes no publican ningún evento dos veces, verificado contra
    `fakeconsumer`.
15. Demuestra que el outbox da "al menos una vez" y no "exactamente una".
    *Criterio:* provocas el fallo entre publicación y commit, muestras el
    duplicado, y demuestras que la idempotencia del consumidor lo absorbe.
16. Implementa el arrendamiento del planificador con renovación. *Criterio:* tres
    instancias ejecutan el cierre **una** vez; matas a la que lo tiene y otra lo
    retoma en menos de dos TTL.
17. **Línea de comandos.** Escribe la consulta que encuentra lotes huérfanos
    —`running` con arrendamiento caducado— y el comando que los libera.
    *Criterio:* es seguro de ejecutar con un lote sano corriendo.

**🟠 Difícil (18–24)**

18. Mide **B-19**: el reporte de 500.000 filas en streaming y materializado.
    *Criterio:* memoria máxima, tiempo total, tiempo hasta el primer byte, y el
    veredicto dice qué se pierde con el streaming.
19. Mide **B-20**: tamaño de fragmento frente a tiempo total. *Criterio:* las
    **cuatro** columnas, incluida la latencia de cancelación, y tu recomendación es
    condicional.
20. Implementa las cinco propiedades con un test cada una. *Criterio:* los cinco
    tests fallan si rompes la propiedad que prueban, y lo demuestras rompiéndolas.
21. Implementa el particionado: N fragmentos en paralelo con `errgroup.SetLimit`.
    *Criterio:* (a) mides la mejora real y dices dónde deja de escalar; (b)
    identificas el nuevo cuello de botella; (c) el punto de control sigue siendo
    correcto con paralelismo —**esto es lo difícil**, y quizá la respuesta sea un
    punto de control por partición; (d) la reanudación sigue funcionando.
22. Implementa el reintento **por ítem** —lo que Spring Batch da en una línea—.
    *Criterio:* (a) un movimiento que falla por un error transitorio se reintenta
    tres veces antes de omitirse; (b) distingues transitorio de permanente con la
    clasificación de la Fase 10; (c) cuentas las líneas que te costó y las comparas
    con la línea de Spring Batch.
23. Resuelve la tensión del error a mitad del streaming. *Criterio:* (a)
    implementas las tres opciones de §6.6; (b) demuestras qué ve el cliente en cada
    una ante un fallo a mitad; (c) implementas el trailer con el recuento y
    verificas que un cliente lo puede comprobar; (d) recomiendas una por formato y
    lo justificas.
24. **Detección de ☕.** Te dan el lote de la autopsia. *Criterio:* identificas los
    **dos** bugs, los arreglas por separado midiendo el efecto de cada arreglo, y
    escribes la ecuación de cierre.

**🔴 Muy difícil (25–28)**

25. **El cierre completo, probado bajo caos.** Somete el cierre de un millón de
    movimientos a fallos inyectados durante una hora. *Rúbrica:* (a) `SIGKILL`
    aleatorio, caída de la base de datos durante 30 s, disco lleno, y movimientos
    corruptos con semilla fija; (b) tras cada recuperación, la ecuación cuadra y no
    hay duplicados; (c) mides cuánto trabajo se pierde por muerte y lo relacionas
    con B-20; (d) el informe final es correcto en todos los casos; (e) el
    experimento es reproducible con la semilla.
26. **El duelo de código con Spring Batch.** Implementa el mismo cierre en el
    gemelo Java y compara. *Rúbrica:* (a) los dos producen resultados **idénticos**
    sobre los mismos datos, y lo verificas con un diff de los asientos; (b) cuentas
    líneas de configuración y de lógica por separado; (c) implementas en los dos
    una feature nueva —reintento por ítem con retroceso— y cronometras cuánto
    cuesta en cada uno; (d) el veredicto es honesto en las dos direcciones y dice
    **a partir de cuántos jobs** recomendarías Spring Batch; (e) mides también el
    arranque en frío de los dos, que es la otra mitad del argumento.
27. **La plataforma conectada.** Haz que el flujo completo funcione de punta a
    punta: `storeagent` sincroniza → ClearingHouse concilia y cierra → OpsReport
    registra el trabajo y emite el reporte → EventRelay notifica al socio →
    AtlasSync provee el tipo de cambio. *Rúbrica:* (a) todo con `docker compose
    up`, sin pasos manuales; (b) trazas el camino de un movimiento concreto por los
    cinco pasos; (c) matas cualquiera de los servicios a mitad y el flujo se
    recupera; (d) mides el tiempo de punta a punta; (e) **identificas el eslabón
    más frágil y explicas por qué**.
28. **El documento de operación del cierre.** Escribe
    `docs/runbook-cierre.md`, dirigido al operador de guardia. *Rúbrica:* (a) qué
    es normal y qué no, con números del cierre real; (b) los cinco fallos más
    probables con su diagnóstico y su acción, con las consultas SQL exactas; (c)
    cómo reanudar, cómo cancelar y **cómo saber si es seguro hacerlo**; (d) cómo
    detectar y liberar un lote huérfano; (e) qué alertas definirías y con qué
    umbrales, justificados; (f) qué **no** hay que hacer nunca, con el porqué; (g)
    utilizable a las 3 de la mañana por alguien que no escribió el código.

**🔥 Opcionales**

- Implementa el cierre con `LISTEN/NOTIFY` para que el despachador del outbox
  reaccione al instante en vez de sondear. Descubre por qué el sondeo sigue
  haciendo falta como red (pista: la notificación se pierde si el consumidor está
  desconectado) y mide la mejora de latencia.
- Compara el outbox con los Streams de Valkey (Fase 12) y con Change Streams de
  Mongo (Fase 11) como mecanismo de publicación. Escribe el argumento de por qué el
  curso eligió el outbox.
- Implementa `http.ServeContent` para las descargas de reportes, con soporte de
  `Range`. Un reporte de 2 GB con descarga reanudable es un requisito real.

---

### 🔴 Desafíos de cierre

> Tres ejercicios de dificultad alta que **no cuentan en el total de la sección** y
> no son parte del recorrido base.

**D1 — `LISTEN/NOTIFY` con sondeo de respaldo.**
Haz que el despachador del outbox reaccione en milisegundos en vez de esperar al
tic, sin perder la garantía.
*Rúbrica:* (a) `NOTIFY` en el mismo `INSERT` del outbox, y `LISTEN` en el
despachador con `pgx` nativo; (b) **el sondeo sigue existiendo como red**, y
explicas exactamente por qué: la notificación se pierde si el consumidor está
desconectado, y con un `NOTIFY` dentro de una transacción que se revierte, no se
emite; (c) mides la latencia de publicación con y sin `NOTIFY`; (d) demuestras que
el sistema sigue siendo correcto si desconectas el `LISTEN` durante un minuto; (e)
**escribes la entrada del ⚖️ veredicto que esta fase debería llevar**: por qué el
curso eligió sondeo puro.

**D2 — El lote que sabe si cabe en la ventana.**
El cierre tiene dos horas. Haz que **se dé cuenta a mitad** de si no va a llegar.
*Rúbrica:* (a) a partir del ritmo observado de los primeros fragmentos, estima el
tiempo restante y lo publica como métrica; (b) si la estimación supera la ventana,
toma una decisión declarada: abortar limpiamente, reducir el alcance, o alertar y
seguir — y justificas cuál; (c) la estimación se recalcula y converge, y lo
demuestras con una carga que se ralentiza a mitad; (d) el operador puede consultar
la previsión mientras corre; (e) comparas con lo que Spring Batch ofrece aquí
—poco— y dices si eso te sorprende.

**D3 — La reconciliación de la reconciliación.**
Un lote puede cuadrar y estar mal. Escribe la verificación independiente.
*Rúbrica:* (a) una consulta que compruebe, sin usar los contadores del lote, que la
suma de los asientos cuadra con la suma de los movimientos por tienda y moneda; (b)
detecta al menos tres clases de error que la ecuación de §7 **no** detecta —un
asiento en la cuenta equivocada, un signo invertido, una moneda mal convertida—;
(c) la corres sobre un lote correcto y sobre tres corrompidos a propósito; (d) se
ejecuta después de cada cierre y su resultado bloquea el cierre del periodo; (e)
explicas por qué un sistema contable necesita esto **además** de los tests, con el
argumento que le darías a un auditor.

---

## 📚 9. Referencias

### Documentación oficial

- **`database/sql` y cursores** — https://go.dev/doc/database/ — y la documentación
  de `pgx` sobre modos de consulta, que es donde está el detalle del error común #2.
- **PostgreSQL: `DECLARE` / `FETCH`** —
  https://www.postgresql.org/docs/current/sql-declare.html
- **PostgreSQL: `ON CONFLICT`** —
  https://www.postgresql.org/docs/current/sql-insert.html#SQL-ON-CONFLICT
- **`golang.org/x/sync/errgroup`** — https://pkg.go.dev/golang.org/x/sync/errgroup
  — y `SetLimit`, que es lo que acota el particionado.
- **`http.ResponseController`** — https://pkg.go.dev/net/http#ResponseController —
  la solución al error común #15.
- **HTTP Trailers (RFC 9110 §6.5)** —
  https://www.rfc-editor.org/rfc/rfc9110#section-6.5
- **Spring Batch Reference** — https://docs.spring.io/spring-batch/reference/ —
  **hay que leer al menos el capítulo de *chunk-oriented processing***, porque es
  contra lo que comparamos.

### Libros

- **Designing Data-Intensive Applications** — Kleppmann, capítulo 11 (*Stream
  Processing*) y capítulo 10 (*Batch Processing*). **El capítulo 11 explica "al
  menos una vez" frente a "exactamente una vez"** mejor que ningún otro texto, y es
  lo que sostiene la regla del outbox.
- **Enterprise Integration Patterns** — Hohpe y Woolf. El patrón *Transactional
  Client* y el *Idempotent Receiver* son literalmente §6.4.
- **Release It!** — Nygard, otra vez: el capítulo sobre trabajos por lotes y los
  fallos en cascada que provocan.
- **Spring Batch in Action** — para el ejercicio 26; conviene saber qué estás
  comparando.

### Artículos y charlas

- **Pattern: Transactional outbox** — Chris Richardson,
  https://microservices.io/patterns/data/transactional-outbox.html — **la
  referencia canónica**, con sus variantes (*polling publisher* y *transaction log
  tailing*).
- **Transactional Outbox in Go** — busca implementaciones reales; casi todas usan
  `SKIP LOCKED` como la nuestra.
- **Exactly-once delivery is a myth** — hay varios artículos con este título; el
  argumento es el del ⚠️ de §6.4 y merece leerse una vez.
- **ShedLock** — https://github.com/lukas-krecan/ShedLock — el README explica bien
  el problema del scheduling con varias instancias, y nuestro arrendamiento es su
  equivalente.
- **Postgres job queues & failure by MVCC** — Brandur Leach — ya citado en la Fase
  09; aquí importa por el efecto de las transacciones largas sobre el vacuum.
- **Batch processing patterns** — busca el material de Spring sobre *chunk*,
  *skip*, *retry* y particionado: el vocabulario es útil aunque no uses el
  framework.

### Video

- **GopherCon: Building batch processing systems** — busca las posteriores a 2020.
- **Spring Batch deep dive** — para el ejercicio 26.
- **Kleppmann: Stream processing** — sus clases de Cambridge sobre entrega
  garantizada.

> ⚠️ El material sobre el outbox suele asumir Kafka como destino. El patrón es el
> mismo con cualquier destino —aquí es EventRelay por HTTP—, y la garantía también:
> "al menos una vez", con deduplicación en el consumidor.

### Orden de lectura sugerido

**Antes de escribir código:** el capítulo de *chunk-oriented processing* de Spring
Batch, aunque no vayas a usarlo. Te da el vocabulario y el modelo mental, y hace
que el diseño de §6.3 se lea como algo conocido.
**Durante:** el artículo del outbox de Richardson cuando llegues a §6.4.
**Después:** los capítulos 10 y 11 de Kleppmann, con calma. El 11 te va a cambiar
cómo hablas de garantías de entrega, y eso es útil mucho más allá de esta fase.

---

## ⚖️ 10. Veredicto y cierre

### ⚖️ Cuándo NO usar esto

**Sobre la cola en base de datos, que es la decisión más grande del curso en esta
área.**

El outbox y la cola de EventRelay viven en PostgreSQL. Es una decisión deliberada y
tiene un punto de ruptura concreto. **Cuándo deja de bastar:**

- **Cuando el volumen supera lo que una base de datos transaccional aguanta
  cómodamente.** El orden de magnitud: unos pocos miles de mensajes por segundo con
  un PostgreSQL bien dimensionado. Por encima, la contención en el índice de la
  cola y la presión sobre el vacuum se vuelven el problema. **Ese número hay que
  medirlo en tu hardware, no creérselo** — es el ejercicio 27 de la Fase 09.
- **Cuando necesitas retención y reproducción.** Kafka guarda el log y permite que
  un consumidor nuevo lea desde el principio. Una tabla con `DELETE` tras publicar,
  no. Si alguien va a querer reprocesar seis meses de eventos, Kafka es la
  respuesta.
- **Cuando hay muchos consumidores independientes** con su propio ritmo. Con una
  tabla, cada consumidor necesita su propia columna de estado o su propia tabla, y
  eso se vuelve incómodo pasados tres o cuatro.
- **Cuando el orden por partición es un requisito.** Kafka lo garantiza por clave;
  con `SKIP LOCKED` **el orden se pierde a propósito**, que es justo lo que permite
  el paralelismo.
- **Y cuando el productor y el consumidor no comparten base de datos.** El outbox
  funciona porque el evento se escribe en la misma transacción que el cambio de
  estado. Si están en bases distintas, esa garantía desaparece.

**Hasta ese punto, la cola en base de datos gana**, y por razones que conviene
tener presentes: cero infraestructura nueva, transaccionalidad con los datos,
consultable con SQL en un incidente, y con las mismas copias de seguridad. La
mayoría de los sistemas que despliegan Kafka no lo necesitaban.

**Sobre el procesamiento por lotes en Go:**

- **Si vas a escribir quince jobs, Spring Batch gana.** El framework amortiza su
  curva de aprendizaje con el segundo o tercer job, y la infraestructura —
  `JobRepository`, reinicio desde consola, métricas— ya está. Escribir quince veces
  lo de §6.3 es una mala idea.
- **Si el proceso necesita reintento por ítem con políticas diferenciadas**,
  particionado sobre varias máquinas, o flujos condicionales entre pasos, Spring
  Batch resuelve problemas que aquí son proyectos.
- **Si un operador tiene que reiniciar jobs desde una consola**, Spring Batch trae
  `JobOperator` y una interfaz. Aquí se escribe.
- **Y si tu lote es realmente grande** —decenas de millones de filas, varias horas,
  varias máquinas—, el terreno es de Spark, Flink o Beam, y esa conversación no va
  ni de Go ni de Java.

**Dónde Go gana, para no dejar el veredicto cojo:** un lote bien delimitado que
arranca rápido, consume poco y se ejecuta en un contenedor efímero. El agente de
tienda. Un job en un `CronJob` que se ejecuta y muere. Ahí, un binario de 18 MB que
arranca en milisegundos frente a una JVM con el contexto de Spring Batch es una
diferencia real —y la Fase 16 la mide.

### 📖 Diccionario Java ⇄ Go de esta fase

| Spring Batch / Spring | Go | Dónde se rompe la equivalencia |
|---|---|---|
| `Job` | una función con su tabla de estado | Sin registro de jobs ni ciclo de vida gestionado |
| `Step` | una fase del proceso, escrita | Sin encadenamiento declarativo ni flujos condicionales |
| `.chunk(5000, txManager)` | el bucle de `processChunk` | **~70 líneas frente a una.** Es la diferencia más grande |
| `ItemReader` | cursor de `sql.Rows` o `iter.Seq` | ⚠️ El driver puede materializar: hay que pedir el cursor explícitamente |
| `JdbcCursorItemReader` | `DECLARE CURSOR` + `FETCH` | Equivalente, escrito |
| `ItemProcessor` | una función `func(T) (U, error)` | Más simple: es una función |
| `ItemWriter` | `InsertEntries` con inserción por lotes | Equivalente |
| `JobRepository` | la tabla `batches` | **Se diseña y se escribe.** Spring Batch trae su esquema |
| `ExecutionContext` | la columna `checkpoint` | Mismo papel; aquí es un campo, allí un mapa serializado |
| `.faultTolerant().skip(X).skipLimit(N)` | contar, registrar y comparar con `maxFailures` | ~15 líneas frente a dos |
| `.retry(X).retryLimit(3)` | **no implementado por defecto** | Hay que escribirlo (ejercicio 22) |
| `PartitionHandler` | goroutines + `errgroup.SetLimit` | **Más simple en Go**, y el punto de control con particiones es más difícil |
| `JobLauncher` / `JobOperator` | la herramienta de línea de comandos | Sin consola de operación |
| `@StepScope` | parámetros de función | No hace falta: no hay contenedor |
| `StepExecutionListener` | llamadas explícitas antes y después | Sin ciclo de vida invertido |
| Métricas de job en Micrometer | contadores propios (Fase 14) | Se escriben |
| `@Scheduled(cron = "0 2 * * *")` | `nextRunAt` calculado, o `robfig/cron` | ⚠️ `time.Ticker` **no** es un cron: cuenta desde el arranque |
| `@Scheduled(fixedDelay = 5000)` | `time.Ticker` | Aquí sí es equivalente |
| ShedLock | arrendamiento en tabla con renovación | ~20 líneas. **Y sirve para corrección**, a diferencia del bloqueo en Valkey |
| Quartz | *(fuera del curso)* | Para persistencia de trabajos y clustering; `robfig/cron` no llega ahí |
| `@Async` + `TaskExecutor` | goroutine con dueño y tope (Fase 06) | Sin pool gestionado; el límite es tuyo |
| `@TransactionalEventListener(AFTER_COMMIT)` | **outbox** | ⚠️ **No son equivalentes**: la anotación publica en memoria tras el commit y **se pierde** si el proceso muere. El outbox no |
| `ApplicationEventPublisher` | escribir en la tabla `outbox` | Duradero frente a en memoria |
| Kafka + `@KafkaListener` | cola en base de datos con `SKIP LOCKED` | Hasta unos miles de mensajes por segundo. Ver ⚖️ |
| `StreamingResponseBody` | escribir en el `ResponseWriter` con `bufio` | Misma tensión: el código de estado ya salió |
| `ResponseEntity` con `InputStreamResource` | `http.ServeContent` | Equivalente, y soporta `Range` |

### Qué sigue

La Fase 14 deja los cuatro servicios **en estado de producción**: se pueden
configurar, observar, apagar y desplegar sin sorpresas.

`log/slog` bien usado, con el logger inyectado y la correlación por identificador
de petición. Métricas con `prometheus/client_golang`, las métricas RED, y **la
cardinalidad de etiquetas como la forma más común de tumbar un Prometheus**. Trazas
con OpenTelemetry. Health y readiness con la diferencia que importa — y el `/ready`
que consulta la base de datos en cada petición como ataque de denegación de
servicio que te haces a ti mismo.

Y el endurecimiento, donde por fin se pagan las deudas más antiguas del curso: la
**validación de URL contra SSRF** de EventRelay, viva desde la Fase 02; la
verificación de la firma HMAC con comparación en tiempo constante; el `Makefile`
sin validación de la Fase 00; y el umbral de cobertura que nunca falló el build.

Con un 🧨 que va a doler: **registra un secreto a propósito y mira qué queda en la
salida, en el log agregado y en la traza.**

### La señal de que quedó bien

> *"Mi lote tarda ochenta minutos y puedo matarlo en cualquier momento sabiendo
> exactamente cuánto trabajo pierdo: como mucho, un fragmento. Y cuando termina, la
> ecuación cuadra."*

Si tu proceso por lotes no tiene una ecuación que cuadre al final, vuelve a la
autopsia. Un lote que solo cuenta lo que leyó puede estar perdiendo trabajo desde
hace tres meses.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en
> verde, los cinco tests de propiedades pasando, `go test -race ./...` y
> `go test -tags=integration ./...` en verde, `golangci-lint run` limpio y
> `git status` sin cambios pendientes:
>
> ```bash
> git tag -a fase-13 -m "F13 cerrada: cierre de ClearingHouse con fragmentos y punto de control transaccional, reanudable e idempotente; las cinco propiedades probadas; outbox completo entre OpsReport y EventRelay; scheduling con arrendamiento en base de datos; reportes en streaming con trailer; ingesta programada de AtlasSync; B-19 y B-20 medidos"
> git tag -a clearinghouse/v0.5 -m "ClearingHouse: cierre por lotes reanudable"
> git tag -a opsreport/v0.10 -m "OpsReport: outbox y reportes en streaming"
> git tag -a eventrelay/v0.11 -m "EventRelay: consume el outbox de OpsReport"
> git tag -a atlassync/v0.4 -m "AtlasSync: ingesta programada"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 13: …`) y los de ejercicio su
> número (`fase 13 ej26: …`). Todo eso está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).

---

# 📌 Bloque de autoría (fuera de lo que lee el estudiante)

## 📌 Pendientes sugeridos

- **El patrón `errWriter` de Rob Pike** — aplicado en §6.6, en el escritor de CSV,
  que es su caso literal. Lleva su 🪞 (el `try/catch` de Java hace lo mismo con
  menos código; lo que gana el patrón es que el error sigue siendo un valor) y su
  ⚠️ sobre la trampa real: si nadie comprueba el acumulador, el error llega cien
  iteraciones tarde. Cadena cerrada con la Fase 03.
- **`LISTEN/NOTIFY`** — la **Fase 09** lo anotó como candidato a sección de esta
  fase. Está como ejercicio 🔥. **Aceptable, pero conviene decidirlo**: si el
  sondeo del despachador es el mecanismo del curso, el ⚖️ debería decir por qué no
  se usa `NOTIFY`, aunque sea en una línea.
- **Streams de Valkey y Change Streams de Mongo** — las Fases 11 y 12 pidieron que
  el ⚖️ de esta fase los recogiera. **Están en el ejercicio 🔥 pero NO en el ⚖️.**
  Recomiendo añadir un párrafo al ⚖️ que los nombre junto a Kafka: son la misma
  discusión y las dos fases anteriores lo anunciaron.
- **`http.ServeContent` y peticiones de rango** — la **Fase 05** lo anotó como
  candidato a sección corta aquí. Está como ejercicio 🔥. Correcto.
- **Negociación de contenido (`Accept`)** — la **Fase 05** anotó que aquí se
  volvería necesaria, y §6.6 elige lo contrario: query param. **Resuelto
  documentando la decisión** en un bloque propio de §6.6, con los tres argumentos
  (el cliente es un navegador, `Accept` negocia en vez de seleccionar, y la URL con
  formato es cacheable sin `Vary`) y con la regla general que queda: `Accept` para
  representaciones, parámetro para descargas. El 🔥 de la Fase 05 sigue en pie y
  ahora tiene sentido: implementarlo una vez para ver por qué aquí no se usa.
- **La prueba de estrés con invariantes** — la **Fase 06** (ejercicio 30) propuso
  reutilizar esa forma de test aquí para las cinco propiedades. **Recogido** en el
  ejercicio 20 y en el 25. Cadena verificada.
- **`container/heap`** — cerrado como ejercicio 🔴 de la Fase 06 (el 27), que es
  donde la complicación concurrente lo hace interesante. **Esta fase no lo
  necesita** y no lo reabre.
- **El `terminationGracePeriodSeconds`** — B-20 produce la latencia de cancelación
  que lo determina. **Verificar que la Fase 14 usa este número** y no uno inventado.

## ☕ Reflejos para `INSTINTOS.md`

- **"Cargo, proceso y guardo"** — el reflejo raíz de la fase. Coste medido: 2,7 GB
  y muerte con un millón de filas; con `GOMEMLIMIT`, lentitud extrema sin error.
  Antídoto: **el número de elementos en memoria es una constante, no una función
  del volumen**.
- **"El lote terminó, luego fue bien"** — la autopsia. Un lote que cuenta leídos en
  vez de conciliados puede perder catorce mil movimientos en un mes sin decir nada.
  Antídoto: **la ecuación tiene que cuadrar y se comprueba en el código**.
- **"Adelanto el punto de control para no reprocesar"** — convierte repetición
  (tolerable) en pérdida silenciosa (mortal).
- **"Omito el que falla y sigo"** — sin contarlo, sin registrarlo y sin límite.
- **"`@TransactionalEventListener` resuelve el outbox"** — publica en memoria tras
  el commit; se pierde si el proceso muere. Es el error más común de esta área en
  el mundo Spring.
- **"Exactamente una vez"** — no existe entre dos sistemas sin transacción
  distribuida. Al menos una vez, y deduplicación en el consumidor.
- **"`Ticker` de 24 horas es un cron diario"** — cuenta desde el arranque, así que
  el cierre nocturno corre cuando despliegas.
- **"Con tres instancias, el `@Scheduled` corre tres veces"** — y aquí no hay
  ShedLock: se escribe.

## 📐 Mediciones para `BENCHMARKS.md`

- **B-19 — Reporte de 500.000 filas: streaming frente a carga completa.** Añadir
  **tiempo hasta el primer byte** como columna: es lo que el usuario percibe y es
  donde el streaming gana de forma más visible. El "qué NO demuestra" debe incluir
  que el streaming pierde el `Content-Length` y la capacidad de convertir un error
  a mitad en un 500.
- **B-20 — Tamaño de fragmento frente a tiempo total del cierre.** ⚠️ **Cuatro
  columnas obligatorias**: tiempo total, memoria máxima, **latencia de
  cancelación** y trabajo perdido al matar el proceso. La tercera es la que nadie
  mide y la que determina el periodo de gracia del orquestador — **y es la que la
  Fase 07 pidió que se midiera aquí** (su pendiente sobre granularidad de
  fragmento). Cadena verificada.
- **B-27 — rendimiento del despachador del outbox frente al número de
  instancias.** Sale del ejercicio 14 y del 27 de la Fase 09. Responde la pregunta
  del ⚖️ —cuándo la cola en base de datos deja de bastar— con un número propio en
  vez de con un orden de magnitud citado, y por eso **es la medición que sostiene
  el veredicto de esta fase**: sin ella, "unos pocos miles por segundo" sería una
  afirmación sin respaldo. Asignada al cerrar el curso, como entrada propia y no
  como fila de B-24: el duelo compara con Spring, y esto compara la cola consigo
  misma al escalar, que es otra pregunta.
