# 🏁 Fase 17 — Capstone: la plataforma completa y el veredicto

> Go para desarrolladores Java senior · Fase 17 de 17 · **5 horas**
> Época: **Go moderno (1.25)**
> Depende de: Fase 16 · Habilita: ninguna
> Proyectos: **los cuatro**, funcionando juntos
> Mini proyectos: ninguno

---

## 🎯 1. Propósito

Tienes cuatro servicios. Hoy tienes que demostrar que son **una plataforma**, no
cuatro demos que comparten carpeta.

Esta fase es corta y no es ligera. Lo que se cierra aquí no es código nuevo: es la
integración real —un movimiento de caja que entra por una tienda y sale como una
notificación a un socio, atravesando los cuatro servicios—, la revisión final
contra el catálogo de reflejos que has ido construyendo, y **la defensa técnica**:
ocho preguntas con respuesta escrita.

De esas ocho, la última —*"¿qué le dirías a tu yo de la Fase 01?"*— es la que de
verdad mide si el curso funcionó. Las otras siete son el camino para poder
responderla.

---

## ✅ 2. Qué queda listo al terminar

- [ ] `docker compose up` levanta los cuatro servicios más PostgreSQL, MongoDB,
      Valkey y `fakeconsumer`, y todo llega a `healthy`.
- [ ] El **flujo integrado** completo funciona de punta a punta y puedes trazar un
      movimiento concreto por los cinco pasos.
- [ ] La suite de integración de la plataforma pasa con un solo comando.
- [ ] `golangci-lint run ./...` en verde en los cuatro módulos.
- [ ] La cobertura de `internal/` está sobre el umbral en los cuatro, y
      `make cover-check` **falla** si baja.
- [ ] La revisión final contra `INSTINTOS.md` está hecha, con los hallazgos
      anotados o corregidos.
- [ ] **Las ocho respuestas de la defensa técnica están escritas.**
- [ ] `INSTINTOS.md` está completo, ordenado por cuánto cuesta desaprender cada
      reflejo.
- [ ] `docs/veredicto-general.md` existe: cuándo **no** usar Go.

---

## 🚫 3. Qué NO entra

Nada nuevo. Esta fase **no añade features**, y eso es deliberado: la tentación de
cerrar un curso construyendo algo más es fuerte y produce un capstone que es otra
fase más. Lo que se cierra aquí es la **integración**, la **revisión** y el
**criterio**.

Lo que queda explícitamente fuera del curso entero, para que la lista esté en un
sitio:

- Kubernetes, service mesh y orquestación. Llegamos hasta la imagen y el
  `compose.yaml`.
- Kafka, RabbitMQ y NATS. Nombrados en el ⚖️ de la Fase 13 con su punto de
  ruptura.
- Arquitectura hexagonal, DDD táctico y patrones GoF como marco. Las capas
  aparecieron cuando algo las necesitó.
- Frontend de cualquier tipo.
- Autenticación y autorización: Meridian vive tras un gateway.
- WebAssembly, gRPC como columna, y todo lo que está en las rutas de continuación
  de §6.6.

---

## 🧠 4. Concepto mínimo

### Qué significa que cuatro servicios sean una plataforma

Cuatro binarios que arrancan no son un sistema. Lo que los convierte en uno es que
**el trabajo fluye entre ellos y las garantías se sostienen en las fronteras**.

```mermaid
flowchart TD
    SA["storeagent<br/>(SQLite)"] -- "sync HTTP · F10" --> CH["ClearingHouse<br/>(PostgreSQL)"]
    CH -- "cierre por lotes · F13" --> OR["OpsReport<br/>(PostgreSQL)"]
    OR -- "F13" --> OB["outbox<br/>(misma tx)"]
    OR -- "reporte en streaming · F13" --> RP["CSV/JSON/HTML"]
    OB -- "SKIP LOCKED" --> ER["EventRelay<br/>(PostgreSQL)"]
    ER -- "HMAC, reintentos · F10, F12" --> FC["fakeconsumer"]
    FC -- "tipo de cambio · F11, F12" --> AS["AtlasSync<br/>(Mongo+Valkey)"]
```

**Y las fronteras, que es donde vive todo lo que el curso enseñó:**

| Frontera | Garantía | Fase |
|---|---|---|
| `storeagent` → ClearingHouse | al menos una vez + hash de contenido | 10 |
| Movimientos → asientos | idempotencia por restricción única | 13 |
| Estado + evento | atomicidad transaccional (outbox) | 13 |
| outbox → EventRelay | al menos una vez + deduplicación en el consumidor | 13 |
| EventRelay → socio | reintento clasificado, firmado, con límite de tasa | 10, 12 |
| AtlasSync → todos | caché con TTL y *fail open* | 12 |

> 🧭 **La idea que ordena el capstone.** Una plataforma no se define por sus
> servicios: **se define por lo que garantiza en sus fronteras**. Si no puedes
> decir, para cada flecha del diagrama, qué pasa cuando el destino está caído, no
> tienes una plataforma: tienes cuatro programas que a veces se llaman.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El instinto:** *"ahora que están los cuatro, hay que extraer las piezas comunes a
una librería compartida"*. Es un reflejo razonable y en Java está institucionalizado:
el módulo `common`, el artefacto corporativo con los DTO, la librería interna de
utilidades que todos los servicios importan.

**Qué pasa si lo aplicas.** Miras los cuatro servicios y ves repetición real:

- Cuatro `middleware.RequestID` casi idénticos.
- Cuatro `writeError`/`classify` con la misma forma.
- Cuatro configuraciones de `slog`.
- Cuatro `Clock` con su `Fake`.
- Cuatro constructores de `http.Client`.

Y extraes todo a `meridian-commons`. Y al cabo de seis meses:

1. **Un cambio en `commons` obliga a desplegar los cuatro servicios.** Han dejado
   de ser independientes, que era el punto de tenerlos separados.
2. **`commons` acumula lo que no encaja en ningún sitio.** Es el `utils` de la Fase
   02 con un `go.mod` propio.
3. **La versión de `commons` se vuelve un problema**: un servicio necesita la 2.4 y
   otro no puede subir de la 1.9 porque rompió algo. Y `go.work` ocultaba el
   problema en desarrollo.
4. **Y el peor: la abstracción compartida impide la divergencia legítima.**
   AtlasSync necesita una política de errores distinta a la de EventRelay —uno
   habla con un tercero, el otro atiende a socios—, y `commons` les impone la misma.

**Qué pensar en su lugar.** Go tiene una respuesta que a un dev de Java le cuesta
aceptar, y está en los proverbios de Rob Pike:

> **"Un poco de copia es mejor que un poco de dependencia."**

**Lo que sí se comparte** —y en este curso se comparte— es lo que tiene **una sola
definición correcta y cero política de negocio dentro**:

```text
services/shared/
  clock/       Clock y Fake. Ocho líneas. Una sola forma correcta.
  logging/     redactSensitive y el tipo Secret. Es SEGURIDAD: divergir es un bug.
  safehttp/    SafeDialer contra SSRF. Ídem.
  contract/    La suite de contrato HTTP. Es un test, no código de producción.
```

**Lo que NO se comparte, aunque se parezca:**

```text
❌ middleware      → cada servicio tiene su cadena y su orden, y eso es correcto
❌ classify/errors → la política de errores es de dominio, no de infraestructura
❌ config          → cada servicio valida lo suyo; las claves comunes se repiten
❌ metrics         → cada uno mide su negocio
```

> 🧭 **La regla del curso, y es la lección de arquitectura del capstone.** Se
> comparte lo que tiene **una sola respuesta correcta** y **ninguna decisión de
> negocio dentro**. Todo lo demás se repite, y la repetición se acepta a cambio de
> independencia. **Si dudas, no compartas**: extraer después es fácil; deshacer una
> dependencia compartida entre cuatro servicios, no.

### 🩻 Esto sí funciona igual

Y en el cierre conviene decirlo, porque quince fases señalando diferencias pueden
dejar una impresión falsa. **La mayor parte de lo que sabes se trasladó intacto:**

- **Todo tu criterio de diseño de sistemas**: separar responsabilidades, definir
  fronteras, pensar en fallos, diseñar para la operación.
- **Todo tu conocimiento de SQL, de índices, de transacciones y de modelado.** La
  Fase 09 no te enseñó SQL: te enseñó una API distinta para el mismo SQL.
- **La pirámide de pruebas, los dobles, el criterio de qué probar.**
- **REST, los códigos de estado, el diseño de API, el versionado.**
- **Los patrones de resiliencia**: reintento, cortacircuitos, contrapresión,
  idempotencia. Son de sistemas distribuidos, no de un lenguaje.
- **La observabilidad**: los tres pilares, RED, la cardinalidad, los percentiles.
- **El procesamiento por lotes**: *chunk*, punto de control, reanudación.
- **Y la disciplina profesional**: medir antes de optimizar, documentar decisiones,
  revisar el código de otros, escribir para quien lo herede.

**Lo que cambió fue el modelo de valores, el manejo de errores, el modelo de
concurrencia y la ausencia de contenedor.** Cuatro cosas. Importantes, y cuatro.

---

## 🛠️ 5. CLI de la fase

```bash
# ─── LA PLATAFORMA COMPLETA ──────────────────────────────────────────────────
docker compose -f compose.yaml -f compose.platform.yaml up -d
docker compose ps --format 'table {{.Name}}\t{{.Status}}\t{{.Ports}}'

# Esperar a que los ocho estén healthy, no solo running (la lección de la F00).
scripts/wait-healthy.sh

# El flujo integrado, de punta a punta, con un comando.
make demo

# ─── TRAZAR UN MOVIMIENTO POR LOS CINCO PASOS ────────────────────────────────
MOVEMENT_ID=$(./bin/storeagent record --kind SALE --amount 145900 --currency COP --json | jq -r .id)

# 1. en el SQLite de la tienda
sqlite3 ~/.meridian/storeagent.db \
  "SELECT id, kind, amount_minor, synced_at FROM movements WHERE id = '$MOVEMENT_ID';"

# 2. tras sincronizar, en ClearingHouse
./bin/storeagent sync --endpoint http://localhost:8083
psql "$DSN" -c "SELECT id, store_id, batch_id FROM movements WHERE id = '$MOVEMENT_ID';"

# 3. su asiento, tras el cierre
./bin/clearinghouse close --day $(date -u +%F)
psql "$DSN" -c "SELECT account, amount_minor FROM ledger_entries WHERE movement_id = '$MOVEMENT_ID';"

# 4. el work item y el evento del outbox, en la MISMA transacción
psql "$DSN" -c "SELECT id, status FROM work_items WHERE external_reference LIKE '%$MOVEMENT_ID%';"
psql "$DSN" -c "SELECT id, event_type, status, published_at FROM outbox ORDER BY id DESC LIMIT 3;"

# 5. y la entrega al socio
psql "$DSN_RELAY" -c "SELECT id, endpoint_id, status, attempts FROM deliveries ORDER BY created_at DESC LIMIT 3;"
curl -s localhost:9100/stats | jq

# Y la traza completa en Jaeger: un trace_id atraviesa los cuatro servicios.
open "http://localhost:16686/search?service=clearinghouse&tags=%7B%22movement.id%22%3A%22$MOVEMENT_ID%22%7D"

# ─── LA REVISIÓN FINAL ───────────────────────────────────────────────────────
golangci-lint run ./...
make cover-check
make vuln
go test -tags=integration ./...
go test -shuffle=on -race -count=3 ./...

# Los grep de la revisión contra INSTINTOS.md: no son exhaustivos y encuentran
# mucho.
grep -rn --include='*.go' -E 'Impl\b|^type I[A-Z]|Factory|Manager' services/
grep -rn --include='*.go' -E 'package (utils|common|helpers|models|dto|impl)' services/
grep -rn --include='*.go' 'time.Now()' services/*/internal/ | grep -v _test.go
grep -rn --include='*.go' -E 'err (==|!=) [A-Z]' services/    # comparación sin errors.Is
grep -rn --include='*.go' 'context.Context' services/ | grep -v '^\S*:\s*func.*ctx context.Context'
grep -rn --include='*.go' -B2 'go func' services/ | grep -c 'for '   # goroutines en bucles

# Y el inventario del curso, que da perspectiva.
tokei services/ labs/ --exclude '*_test.go'
git tag -l 'fase-*' | wc -l
git log --oneline --since="$(git log --format=%aI --reverse | head -1)" | wc -l

# ─── LA DEFENSA ──────────────────────────────────────────────────────────────
# Las ocho respuestas, escritas, revisadas y commiteadas.
wc -w docs/defensa.md
```

> 💡 **`make demo` es el entregable ejecutable del capstone.** Un comando que
> levanta todo, ejecuta el flujo completo y verifica el resultado. Es lo que le
> enseñas a alguien en dos minutos, y es lo que demuestra que la plataforma existe.

---

## 💻 6. Construcción guiada

### 6.1 El `compose.yaml` completo

```yaml
# compose.platform.yaml — los cuatro servicios sobre la infraestructura de la F00.
services:
  opsreport:
    build:
      context: .
      dockerfile: services/opsreport/Dockerfile
    environment:
      MERIDIAN_ENVIRONMENT: local
      MERIDIAN_HTTP_ADDR: ":8080"
      MERIDIAN_ADMIN_ADDR: ":9080"      # separado del público (F14)
      MERIDIAN_DATABASE_URL: "postgres://meridian:meridian@postgres:5432/opsreport?sslmode=disable"
      MERIDIAN_LOG_FORMAT: json
      MERIDIAN_OTLP_ENDPOINT: "jaeger:4317"
      MERIDIAN_SHUTDOWN_TIMEOUT: "20s"  # menor que el periodo de gracia (F13, B-20)
    ports: ["8080:8080", "9080:9080"]
    depends_on:
      postgres: { condition: service_healthy }
      jaeger:   { condition: service_started }
    healthcheck:
      # El propio binario se comprueba a sí mismo: sin shell ni curl en
      # distroless, es la única forma. Y demuestra que --health-check existe.
      test: ["CMD", "/opsreport", "--health-check"]
      interval: 5s
      timeout: 3s
      retries: 10
      start_period: 10s
    # El periodo de gracia, con el número que salió de B-20.
    stop_grace_period: 30s

  eventrelay:
    # ... igual, puerto 8081 ...
    depends_on:
      postgres:     { condition: service_healthy }
      valkey:       { condition: service_healthy }
      fakeconsumer: { condition: service_started }

  atlassync:
    # ... puerto 8082; usa el corpus grabado de testdata/, NO la red (F10) ...
    environment:
      MERIDIAN_COUNTRIES_BASE_URL: "http://recorded:9200"
      MERIDIAN_FX_BASE_URL:        "http://recorded:9200"
    depends_on:
      mongo:    { condition: service_healthy }
      valkey:   { condition: service_healthy }
      recorded: { condition: service_started }

  clearinghouse:
    # ... puerto 8083 ...

  fakeconsumer:
    build: { context: ., dockerfile: services/eventrelay/Dockerfile.fakeconsumer }
    command: ["-addr", ":9100", "-slow-delay", "8s"]
    ports: ["9100:9100"]

  # El servidor de respuestas grabadas: la regla de la Fase 10 —la plataforma
  # entera corre SIN RED— llevada hasta el compose.
  recorded:
    build: { context: ., dockerfile: scripts/recorded/Dockerfile }
    volumes: ["./services/atlassync/testdata:/data:ro"]
    ports: ["9200:9200"]

  jaeger:
    image: jaegertracing/all-in-one:latest
    ports: ["16686:16686", "4317:4317"]
```

> 🧭 **Decisión del capstone: la plataforma completa no toca internet.** AtlasSync
> apunta al servidor de respuestas grabadas, igual que en los tests. Es la regla de
> la Fase 10 aplicada al entorno de demostración, y significa que `make demo`
> funciona en un avión, en 2029, y el día que REST Countries cambie de forma.

### 6.2 El flujo integrado

```bash
#!/usr/bin/env bash
# scripts/demo.sh — el flujo completo, verificado paso a paso.
set -euo pipefail

echo "═══ 1. AtlasSync ingiere los datos de referencia ═══"
curl -sf -X POST localhost:8082/sync > /dev/null
scripts/wait-for.sh 'curl -sf localhost:8082/sync/latest | jq -e ".status == \"completed\""'

RATE=$(curl -sf 'localhost:8082/rates/latest?base=EUR' | jq -r '.rates.COP')
echo "   tipo de cambio EUR→COP: $RATE"

echo "═══ 2. Una tienda registra movimientos sin red ═══"
for i in $(seq 1 500); do
  ./bin/storeagent record --store ST-014 --kind SALE \
    --amount $((100000 + RANDOM * 10)) --currency COP --quiet
done
PENDING=$(./bin/storeagent status --json | jq -r .pending)
echo "   $PENDING movimientos pendientes en SQLite"

echo "═══ 3. Sincroniza cuando hay red ═══"
./bin/storeagent sync --endpoint http://localhost:8083
echo "   sincronizados: $(./bin/storeagent status --json | jq -r .synced)"

echo "═══ 4. ClearingHouse concilia y cierra el periodo ═══"
BATCH=$(curl -sf -X POST localhost:8083/batches \
  -d "{\"day\":\"$(date -u +%F)\"}" | jq -r .id)

# El progreso es consultable MIENTRAS corre (F13).
while true; do
  S=$(curl -sf localhost:8083/batches/$BATCH)
  [[ $(jq -r .status <<<"$S") != "running" ]] && break
  printf "\r   progreso: %s%%" "$(jq -r '(.processed*100/.total)|floor' <<<"$S")"
  sleep 1
done
echo
jq -r '"   leídos=\(.processed) conciliados=\(.reconciled) omitidos=\(.failed)"' <<<"$S"

# LA ECUACIÓN DE LA FASE 13. Si no cuadra, la demostración falla aquí.
jq -e '.processed == (.reconciled + .failed)' <<<"$S" > /dev/null \
  || { echo "   ❌ el lote no cuadra"; exit 1; }
echo "   ✅ la ecuación cuadra"

echo "═══ 5. OpsReport registra el trabajo y emite el reporte ═══"
WI=$(curl -sf localhost:8080/work-items?status=done | jq -r '.items[0].id')
REPORT=$(curl -sf -X POST localhost:8080/reports -d "{\"batch_id\":\"$BATCH\"}" | jq -r .id)
scripts/wait-for.sh "curl -sf localhost:8080/reports/$REPORT | jq -e '.status == \"ready\"'"

# En streaming: el primer byte llega antes que el total (F13).
curl -s -o /tmp/report.csv -w '   primer byte: %{time_starttransfer}s · total: %{time_total}s · %{size_download} bytes\n' \
  "localhost:8080/reports/$REPORT/download?format=csv"

echo "═══ 6. El outbox despacha y EventRelay entrega al socio ═══"
scripts/wait-for.sh 'psql -Atc "SELECT count(*) FROM outbox WHERE status = '"'"'pending'"'"'" | grep -q "^0$"'

STATS=$(curl -sf localhost:9100/stats)
echo "   el socio recibió: $(jq -r .ok <<<"$STATS") entregas"

echo "═══ 7. Verificación de punta a punta ═══"
# Un movimiento concreto, trazado por los cinco pasos.
scripts/verify-flow.sh "$BATCH" "$WI" "$REPORT"
echo "✅ flujo completo verificado"
```

> 🧪 **Prueba de fuego.** Ejecuta `make demo` y después **mata un servicio a mitad
> y vuelve a ejecutarlo**:
>
> ```bash
> make demo & sleep 8 && docker compose kill eventrelay
> docker compose start eventrelay
> make demo
> ```
>
> **La mentira de la pantalla:** que la segunda ejecución termine no basta.
> Comprueba los **duplicados**: `SELECT event_id, count(*) FROM deliveries GROUP BY
> event_id HAVING count(*) > 1`. La garantía es "al menos una vez" con
> deduplicación en el consumidor (Fase 13), así que un duplicado en `deliveries` es
> aceptable **si `fakeconsumer` lo rechazó por la clave de idempotencia**. Esa
> distinción es exactamente lo que el curso enseñó, y aquí se verifica.

> ⚠️ **La trampa que aparece el día que despliegas esto en un clúster: la doble
> capa de reintento.** La Fase 10 la dejó anotada para el cierre, y este es el
> sitio porque es la primera vez que ves la plataforma entera junta.
>
> EventRelay reintenta en la aplicación: hasta 8 intentos con retroceso
> exponencial y jitter. Una malla de servicios —Istio, Linkerd— reintenta en la
> capa de red, típicamente 2 o 3 veces por petición, y **lo hace por defecto**. Las
> dos capas no se ven entre sí, así que **se multiplican**: 8 × 3 son 24 peticiones
> al socio por cada entrega, y el socio caído recibe el triple de lo que tú crees
> que le mandas. Si además hay un balanceador con reintentos —y suele haberlo—, son
> tres capas.
>
> Peor: la malla reintenta **antes** de que tu retroceso entre en juego, sin jitter
> y en milisegundos. Es exactamente el pico que B-25 mide y que tu política
> existía para evitar. **Tu retroceso cuidadoso queda debajo de un martillo.**
>
> **La regla: el reintento vive en UNA capa, y se declara cuál.** Para EventRelay
> es la aplicación, porque es la única que sabe qué es idempotente, cuántos
> intentos quedan y cuándo dar una entrega por muerta. Entonces la malla se
> configura con `retries: 0` para esa ruta, **explícitamente y con un comentario
> que diga por qué**, porque el valor por defecto volverá en cuanto alguien
> regenere la configuración.
>
> 📖 En Spring es la misma conversación con otros nombres: `@Retryable` de
> Spring Retry, más los reintentos de Feign, más los de Ribbon o el gateway. El
> problema no es del lenguaje; es de que cada capa cree que es la única.

### 6.3 La suite de integración de la plataforma

```go
//go:build platform

// tests/platform/flow_test.go
//
// La suite que verifica la PLATAFORMA, no los servicios. Corre contra el
// compose levantado, y su build tag propio la mantiene fuera de todo lo demás.
package platform_test

// TestFullFlow es la demostración de §6.2, como test.
func TestFullFlow(t *testing.T) {
	p := setupPlatform(t)

	p.AtlasSync.TriggerSync(t)
	p.AtlasSync.WaitForSync(t, 30*time.Second)

	movements := p.StoreAgent.RecordMovements(t, "ST-014", 500)
	p.StoreAgent.Sync(t)

	batch := p.ClearingHouse.CloseDay(t, today())
	p.ClearingHouse.WaitForBatch(t, batch, 60*time.Second)

	// La ecuación, como aserción.
	st := p.ClearingHouse.BatchStatus(t, batch)
	if st.Processed != st.Reconciled+st.Failed {
		t.Fatalf("el lote no cuadra: leídos=%d conciliados=%d omitidos=%d",
			st.Processed, st.Reconciled, st.Failed)
	}

	// Cada movimiento tiene su asiento. Sin duplicados.
	for _, m := range movements {
		entries := p.ClearingHouse.EntriesFor(t, m.ID)
		if len(entries) == 0 {
			t.Errorf("el movimiento %s no produjo asiento", m.ID)
		}
	}

	p.EventRelay.WaitForOutboxDrained(t, 30*time.Second)

	stats := p.FakeConsumer.Stats(t)
	if stats.OK == 0 {
		t.Fatal("el socio no recibió ninguna entrega")
	}
	if dup := p.FakeConsumer.DuplicatesRejected(t); dup > 0 {
		t.Logf("el socio rechazó %d duplicados por idempotencia (esperado)", dup)
	}
}

// TestResilience mata servicios a mitad y verifica que el flujo se recupera.
//
// Es el test que de verdad demuestra que esto es una plataforma: cada servicio
// puede caerse y el trabajo no se pierde ni se duplica.
func TestResilience(t *testing.T) {
	for _, svc := range []string{"eventrelay", "clearinghouse", "atlassync", "opsreport"} {
		t.Run("kill/"+svc, func(t *testing.T) {
			p := setupPlatform(t)

			done := make(chan error, 1)
			go func() { done <- p.RunFullFlow() }()

			time.Sleep(5 * time.Second)
			p.Kill(t, svc)              // SIGKILL, sin apagado ordenado
			time.Sleep(2 * time.Second)
			p.Start(t, svc)

			select {
			case err := <-done:
				if err != nil {
					t.Logf("el flujo falló durante la caída (aceptable): %v", err)
				}
			case <-time.After(90 * time.Second):
				t.Fatal("el flujo no terminó tras reiniciar el servicio")
			}

			// Reintentar el flujo y verificar los invariantes.
			if err := p.RunFullFlow(); err != nil {
				t.Fatalf("el flujo no se recuperó: %v", err)
			}
			p.AssertNoDuplicateEntries(t)
			p.AssertNoLostMovements(t)
			p.AssertBatchEquationHolds(t)
		})
	}
}
```

### 6.4 La revisión final contra `INSTINTOS.md`

**Esto no es opcional y es media fase.** Vuelve al código con el catálogo delante.

```bash
# La lista de comprobación, por categorías. Ninguna es exhaustiva; todas
# encuentran cosas.

# ── Diseño (Fase 02) ──────────────────────────────────────────────────────────
grep -rn --include='*.go' -E '\bImpl\b|^type I[A-Z][a-z]' services/
grep -rn --include='*.go' -E 'Factory|Manager|Helper' services/
grep -rn --include='*.go' -E 'package (utils|common|helpers|models|dto|impl)\b' services/
# Interfaces con más de cuatro métodos:
grep -rn -A12 --include='*.go' '^type .* interface {' services/ | \
  awk '/interface \{/{n=0} /^\s*[A-Z].*\(/{n++} /^\s*\}/{if(n>4) print FILENAME": interfaz de "n" métodos"}'

# ── Errores (Fase 03) ─────────────────────────────────────────────────────────
grep -rn --include='*.go' -E 'err (==|!=) Err[A-Z]' services/        # sin errors.Is
grep -rn --include='*.go' 'strings.Contains(err.Error()' services/    # peor todavía
grep -rn --include='*.go' -E 'func .* \*[A-Z][a-zA-Z]*Error \{' services/  # interfaz nula
grep -rn --include='*.go' -B1 'defer.*\.Close()' services/ | grep -A1 'for '  # defer en bucle

# ── Concurrencia (Fase 06) ────────────────────────────────────────────────────
grep -rn --include='*.go' -B3 'go func' services/ | grep -E 'for (_|\w+), ' # goroutine por elemento
grep -rn --include='*.go' 'time.After' services/ | grep -v _test.go          # en bucle = fuga
grep -rn --include='*.go' 'sync.Map' services/                                # justificar

# ── Contexto (Fase 07) ────────────────────────────────────────────────────────
grep -rn --include='*.go' -A6 '^type .* struct {' services/ | grep 'ctx.*context.Context'
grep -rn --include='*.go' 'context.Value("' services/                         # clave string
grep -rn --include='*.go' -E 'func .*\((?!ctx context\.Context)' services/ | grep -E '\bdb\b|\bclient\b'

# ── Reloj (Fases 01, 02, 04) ──────────────────────────────────────────────────
grep -rn --include='*.go' 'time.Now()' services/*/internal/ | grep -v _test.go

# ── Datos (Fases 09, 11) ──────────────────────────────────────────────────────
grep -rn --include='*.go' -A3 'QueryContext' services/ | grep -v 'defer rows.Close'
grep -rn --include='*.go' 'float64' services/ | grep -iE 'amount|price|rate|money'

# ── Caché y seguridad (Fases 12, 14) ─────────────────────────────────────────
grep -rn --include='*.go' -E '\.Set\(ctx, [^,]+, [^,]+\)$' services/          # SET sin TTL
grep -rn --include='*.go' -E 'signature ==|token ==|secret ==' services/       # sin hmac.Equal
grep -rn --include='*.go' 'slog.Any' services/                                  # revisar cada uno
```

> 🧭 **La regla de la revisión: cada hallazgo se resuelve de una de tres formas.**
> (1) Se **corrige**. (2) Se **justifica** con un comentario que explique por qué
> ahí es correcto. (3) Se **anota** en `docs/deuda.md` con su motivo y su momento.
> **Lo que no vale es dejarlo sin decidir**, porque entonces el siguiente que lo
> lea no sabrá si es un descuido o una decisión.

### 6.5 La defensa técnica

**Ocho preguntas, ocho respuestas escritas.** No son un examen: son la forma de
comprobar que lo que aprendiste es transferible a tu trabajo.

```markdown
# docs/defensa.md
```

---

**1. ¿Qué reflejos de Java trasladaste y cuáles descartaste?**

*Qué se espera:* no una lista de lo que dice `INSTINTOS.md`, sino **cuáles te
costaron a ti**. Cita código tuyo. El reflejo que más veces tuviste que corregir es
el dato interesante, y suele ser uno de estos tres: la interfaz antes que la
implementación, el `context` como bolsa, o la goroutine sin dueño.

Y la otra mitad, que es igual de importante: **qué trasladaste sin cambios y
funcionó**. La separación dominio/infraestructura, la inyección por constructor, la
disciplina de pruebas. Si tu respuesta solo tiene la lista de lo que descartaste,
está a medias.

---

**2. ¿Dónde Go te obligó a escribir más, y valió la pena?**

*Qué se espera:* casos concretos con números del curso. Los candidatos fuertes:

- El enrutado a mano de la Fase 05 (60 líneas frente a una anotación) — **y la Fase
  08 lo borró**, así que la respuesta honesta incluye que fue temporal.
- La transacción por parámetro de la Fase 09 (un parámetro en cada firma) — **valió
  la pena**: el alcance se ve, y la autopsia muestra qué pasa cuando se esconde.
- El cierre por lotes de la Fase 13 (520 líneas frente a 180 de Spring Batch) —
  **valió la pena con un job, no con quince**.
- El manejo de errores. Más líneas, y el flujo de error es visible.

La respuesta buena distingue **lo que valió la pena** de **lo que fue puro coste**.
No todo lo que Go te hace escribir es una lección.

---

**3. ¿Dónde escribiste menos y el resultado fue más claro?**

*Qué se espera:*

- La autopsia de la Fase 02: 8 archivos → 3, 9 métodos de interfaz → 0, 5 saltos de
  lectura → 2.
- `main` como grafo de dependencias completo y legible, frente a un contenedor.
- Los fakes de la Fase 04 frente a los mocks: 2 líneas de preparación frente a 12.
- La concurrencia de la Fase 06: un worker pool con límite, cola y apagado en diez
  líneas.
- Y el `--stat` de la Fase 08: **menos líneas después de migrar que antes**.

---

**4. ¿Qué se rompió al migrar de 1.13 a moderno, y qué no?**

*Qué se espera:* casi nada se rompió, **y esa es la respuesta**. La promesa de
compatibilidad de Go aguantó trece versiones sin tocar código.

Lo que sí requirió atención:

- El cambio de la variable de bucle en 1.22, que arregló bugs latentes — y **el
  caso raro donde alguien dependía del comportamiento antiguo**.
- El `tt := tt` que sobraba en todos los tests.
- Y el descubrimiento que más vale: **la directiva `go` del `go.mod` manda sobre la
  versión del compilador**, que es lo que sostuvo la disciplina del Bloque A entero.

Compara honestamente con una migración de Spring Boot 2 a 3, si la has hecho.

---

**5. ¿Qué features modernas decidiste NO usar, y por qué?**

*Qué se espera:* `docs/rechazos.md` de la Fase 08, defendido. Los cuatro grandes:

- **`Repository[T]` genérico** — las consultas reales no son genéricas; hoy hay
  cero entidades con el mismo conjunto de operaciones.
- **`errors.Join` para la validación del dominio** — el borde HTTP necesita
  `[]FieldError` estructurado, no una cadena que parsear. **Y sí se adoptó donde
  solo se agregaba.**
- **Iteradores para todo** — un slice pequeño ya está en memoria.
- **`go tool` con herramientas en el `go.mod`** — rechazado por motivo **pedagógico**
  y recomendado para un proyecto real, que es una distinción que hay que saber
  hacer.

La respuesta buena incluye **la condición de revisión** de cada rechazo. Un rechazo
sin condición es un dogma.

---

**6. ¿Qué medición te sorprendió?**

*Qué se espera:* una de verdad, con el número. Candidatos frecuentes:

- **B-05**: el coste de una interfaz es despreciable, y el argumento real es el
  *inlining* perdido, no el salto.
- **B-17**: un mapa en memoria con TTL resolvía el caso de AtlasSync y Valkey
  aportaba poco para la caché — aunque es imprescindible para el límite de tasa.
- **B-11**: el binario de Go moderno es **más grande** que el de 1.13 y el
  rendimiento en reposo apenas cambió. La migración se justifica por mantenimiento.
- **B-24**: la JVM ajustada y caliente está mucho más cerca de lo que la reputación
  sugiere.
- Y `docs/optimizaciones-fallidas.md` de la Fase 15: la que no funcionó.

---

**7. ¿Qué servicio de tu trabajo actual migrarías, y cuál no tocarías?**

*Qué se espera:* **la pregunta más importante de las ocho**, porque es la única
sobre tu realidad y no sobre Meridian.

Un servicio concreto, con nombre, y el criterio de la Fase 16 aplicado: ¿cuál es su
perfil de ejecución? ¿arranca a menudo? ¿escala elásticamente? ¿su coste está en
memoria? ¿depende de Spring Batch o Spring Security? ¿el equipo puede aprender Go
mientras entrega?

Y el que **no** tocarías, con el mismo detalle. **Si tu respuesta es "migraría
todo", vuelve a la autopsia de la Fase 16.** Si es "no migraría nada", comprueba
que has buscado el caso donde Go gana de verdad.

---

**8. ¿Qué le dirías a tu yo de la Fase 01?**

*Qué se espera:* es la pregunta del cierre y la que mide si el curso funcionó.
Personal, breve, y honesta. Algunas que suelen salir:

- *"El `if err != nil` no es el problema; el problema es que estás diseñando APIs
  que fallan de cinco formas distintas."*
- *"Deja de buscar el contenedor de inyección. `main` es el contenedor y eso es
  bueno."*
- *"La interfaz la escribe quien te llama. Tú escribe el struct."*
- *"Mide antes de opinar, y publica lo que no funcionó."*
- *"Go no te quita herramientas: te quita intermediarios. Y a veces el
  intermediario valía la pena."*

---

### 6.6 El veredicto general: cuándo NO usar Go

**El cierre del curso, y tiene que ser tan honesto como el de la Fase 16.**

```markdown
# docs/veredicto-general.md

## Cuándo NO usar Go

### 1. Cuando el ecosistema que necesitas solo existe en otro sitio

- **Científico, datos y aprendizaje automático** → Python. No hay discusión.
- **Seguridad empresarial** (SAML, OIDC federado, method security) → Spring
  Security no tiene equivalente.
- **Lotes complejos** → Spring Batch. La Fase 13 lo midió.
- **Escritorio y móvil** → no es su terreno.
- **Sistemas embebidos con memoria muy limitada** → el runtime y el recolector
  pesan; ahí están C, C++ o Rust.
- **Latencia de tiempo real duro** → hay recolector, y aunque las pausas sean
  cortas, existen. Rust o C.

### 2. Cuando el dominio es genuinamente jerárquico

Una taxonomía con veinte tipos que comparten el 80% del comportamiento se expresa
mejor con herencia. El embedding delega y no hace *dispatch* dinámico hacia
arriba, así que cada "override" cuesta un método completo. **Java gana ahí.**

### 3. Cuando tu equipo es grande y ya domina otro stack

No es un argumento técnico y es el que más proyectos decide. Cuarenta personas
productivas en Spring, una plataforma montada, arquetipos, librerías internas y
quince años de conocimiento. **Migrar tira todo eso.**

### 4. Cuando el problema no era el lenguaje

El más frecuente. La mayoría de los servicios lentos lo son por la base de datos,
por el diseño o por una llamada de red en un bucle. Migrar de lenguaje no arregla
ninguna de las tres.

### 5. Cuando echas de menos lo que Go no tiene, y con razón

- **Sin excepciones comprobadas**: `_ = f()` compila.
- **Sin genéricos en métodos** de un tipo genérico.
- **Sin enumeraciones de verdad**: sin exhaustividad comprobada por el compilador.
- **Sin inmutabilidad en el tipo**: no se puede congelar un slice.
- **Sin composición asíncrona**: no hay `CompletableFuture` encadenado.
- **Sin ArchUnit**: las reglas de arquitectura se revisan a mano.
- **Y la reflexión es más limitada y más incómoda**, que es a la vez una virtud y
  un límite.

## Dónde Go sí es la respuesta

Servicios de red concurrentes con E/S dominante. Herramientas de línea de comandos.
Procesos efímeros y funciones sin servidor. Sistemas donde arranque y huella
importan. Equipos que valoran un lenguaje pequeño que se aprende en semanas. Y
cualquier sitio donde el despliegue sea "copia este binario".
```

### 6.7 El recorrido por `INSTINTOS.md`

**La sección que solo puede ir aquí**, porque hace falta el curso entero para
escribirla: los reflejos **ordenados por cuánto cuesta desaprenderlos**.

```markdown
# INSTINTOS.md — recorrido final

## Nivel 1 — Se desaprenden en un día (el compilador te obliga)

| Reflejo ☕ | Fase | Qué lo corrige |
|---|---|---|
| Imports sin usar toleradas | 00 | no compila |
| `getters`/`setters` sobre campos públicos | 02 | el campo ya es accesible |
| Prefijo `I` y sufijo `Impl` | 02 | la revisión de código, y da vergüenza |
| Tartamudeo (`workitem.WorkItemService`) | 02 | ídem |
| `utils`, `common`, `helpers` | 03 | ídem |

## Nivel 2 — Se desaprenden en una semana (te muerden pronto y visiblemente)

| Reflejo ☕ | Fase | Coste medido |
|---|---|---|
| "Un slice es un `ArrayList`" | 01 | corrupción silenciosa de datos |
| "Primero el layout de directorios" | 00 | directorios muertos |
| "`sql.Open` abre una conexión" | 09 | arranque con credenciales malas |
| "Cerrar el cuerpo basta" (sin drenar) | 10 | keep-alive roto |
| "`Ticker` de 24 h es un cron diario" | 13 | el cierre corre al desplegar |

## Nivel 3 — Se desaprenden en un mes (funcionan hasta que no)

| Reflejo ☕ | Fase | Coste medido |
|---|---|---|
| "Interfaz primero, implementación después" | 02 | 5 archivos y 3 saltos de lectura extra |
| "Hay que mockear el almacén" | 04 | 12 líneas de preparación frente a 2 |
| "El controlador orquesta" | 05 | validación duplicada que diverge |
| "Un pool es un `for` con `go` dentro" | 06 | 2.000.000 de goroutines, ~4 GB |
| "`@Retryable` y ya reintenta" | 10 | 40 s de caída convertidos en 19 minutos |
| "`@Cacheable` y ya está cacheado" | 12 | cuatro decisiones tomadas por omisión |

## Nivel 4 — Cuestan meses (son modelos mentales, no hábitos)

| Reflejo ☕ | Fase | Por qué cuesta |
|---|---|---|
| "El `context` es un `ThreadLocal`" | 07 | el modelo de propagación es distinto |
| "Reimplementar `@Transactional`" | 09 | quince años de infraestructura detrás |
| "Modelar en Mongo como en SQL" | 11 | el modelo de datos es otro |
| "Esquemaless = sin esquema" | 11 | ídem |
| "Cargo, proceso y guardo" | 13 | es cómo se escribe el 95% del código |
| "Tenemos observabilidad: el panel está verde" | 14 | la instrumentación parece completa |

## Nivel 5 — El que no se desaprende nunca del todo

**"Ya que estamos, lo arreglamos."** (Fase 08)

No es un reflejo de Java: es un reflejo humano. Aparece en cada migración, en cada
refactor y en cada revisión de código. La única defensa es un proceso: un commit
por cosa, y anotar lo demás.

**Es el último de la lista a propósito.** Si te llevas uno solo de los cuarenta,
que sea este.
```

---

## ⚰️ 7. Autopsia y errores comunes

### ⚰️ Autopsia: la plataforma que eran cuatro demos

**El cadáver.** Un equipo terminó su curso equivalente al de Meridian. Los cuatro
servicios compilaban, cada uno tenía su suite en verde, y el `docker compose up`
levantaba los ocho contenedores.

Y la primera vez que alguien hizo el flujo completo, falló en cuatro sitios
distintos.

| Fallo | Causa | Por qué ningún test lo detectó |
|---|---|---|
| El agente subía movimientos y ClearingHouse los rechazaba | el `content_hash` se calculaba sobre campos distintos en cada lado | cada servicio probaba **su** cálculo |
| El outbox se llenaba y no se vaciaba | EventRelay esperaba `event_type` con punto (`work_item.done`); OpsReport escribía `work_item_done` | los dos probaban con **sus propias** fixtures |
| Las trazas aparecían cortadas | un servicio usaba B3 y los otros W3C | nadie probó la traza **entre** servicios |
| El cierre cuadraba y los asientos no | dos zonas horarias distintas en el mismo flujo | cada uno probaba **su** día de negocio |

**El informe forense:**

| | Lo que había | Lo que faltaba |
|---|---|---|
| Tests unitarios | 1.240, en verde | — |
| Tests de integración por servicio | 180, en verde | — |
| **Tests de la PLATAFORMA** | **0** | los cuatro fallos estaban aquí |
| Contratos entre servicios | implícitos, en fixtures duplicadas | un contrato compartido y verificado |
| Fixtures compartidas | **ninguna**: cada uno tenía las suyas | el mismo dato en los dos lados |
| Traza de punta a punta probada | **no** | un test que la siga |

**La causa de la muerte: se probó cada servicio contra su idea del contrato, no
contra el contrato.** Cada fixture era una **suposición** sobre lo que el otro lado
hacía, y las suposiciones divergieron sin que nada lo detectara.

Y el detalle que lo hace didáctico: **los cuatro fallos eran triviales de
arreglar** —un nombre de campo, un separador, un propagador, una zona horaria—.
Ninguno era un problema de diseño. Todos eran problemas de **integración no
probada**.

**El fix, y son tres cosas distintas:**

```go
// 1. UN paquete de contrato compartido, con los tipos que cruzan la frontera.
//    Es de las pocas cosas que el capstone SÍ comparte (§4), porque tiene una
//    sola definición correcta y ninguna política dentro.
package contract

type MovementUpload struct {
	ID          string    `json:"id"`
	StoreID     string    `json:"store_id"`
	OccurredAt  time.Time `json:"occurred_at"`
	Kind        string    `json:"kind"`
	AmountMinor int64     `json:"amount_minor"`
	Currency    string    `json:"currency"`
	ContentHash string    `json:"content_hash"`
}

// ContentHash se calcula AQUÍ, una vez. Los dos lados llaman a esta función, y
// así es imposible que diverjan.
func (m MovementUpload) ComputeHash() string {
	h := sha256.New()
	fmt.Fprintf(h, "%s|%s|%s|%d|%s",
		m.StoreID, m.OccurredAt.UTC().Format(time.RFC3339), m.Kind, m.AmountMinor, m.Currency)
	return hex.EncodeToString(h.Sum(nil))
}

// Y las constantes de los tipos de evento, que también cruzan la frontera.
const (
	EventWorkItemDone   = "work_item.done"
	EventWorkItemFailed = "work_item.failed"
	EventBatchClosed    = "batch.closed"
)
```

```go
// 2. FIXTURES COMPARTIDAS. El mismo archivo alimenta los tests de los dos lados,
//    así que si el formato cambia, los dos fallan a la vez.
//
//    tests/fixtures/movement_upload.json  ← usado por storeagent Y ClearingHouse
```

```go
// 3. UN TEST DE LA PLATAFORMA que ejercite la frontera de verdad (§6.3).
```

> ☕ **El patrón a memorizar.** **Un test que usa tus propias fixtures no prueba un
> contrato: prueba que eres coherente contigo mismo.** El contrato se prueba con
> una definición compartida, fixtures compartidas, y un test que cruce la frontera
> de verdad.
>
> Es lo mismo que en Java se resuelve con *consumer-driven contract testing*
> (Pact, Spring Cloud Contract). **Aquí lo resolvimos con un paquete compartido y
> un test de integración**, que es más simple y cubre este caso; con veinte
> servicios y equipos distintos, las herramientas de contrato ganan.

### Errores comunes

**1. Extraer una librería `commons`.**
*Síntoma:* los cuatro servicios se despliegan juntos; `commons` acumula todo.
*Fix mínimo:* compartir solo lo que tiene una sola respuesta correcta y ninguna
política dentro.

**2. Probar contra fixtures propias.**
*Síntoma:* la autopsia.
*Fix mínimo:* contrato y fixtures compartidas.

**3. `depends_on` sin `condition: service_healthy`.**
*Síntoma:* servicios que arrancan contra una base que no acepta conexiones.
*Fix mínimo:* la condición, y `healthcheck` de verdad. Es la lección de la Fase 00.

**4. Healthcheck que usa `curl` en una imagen distroless.**
*Síntoma:* el contenedor nunca llega a `healthy`.
*Causa:* no hay shell ni `curl`.
*Fix mínimo:* `--health-check` en el propio binario.

**5. Propagadores de traza distintos.**
*Síntoma:* trazas cortadas entre servicios.
*Fix mínimo:* el propagador compuesto de la Fase 14, igual en los cuatro.

**6. Zonas horarias inconsistentes.**
*Síntoma:* el cierre cuadra y los asientos de un día no.
*Fix mínimo:* el `BusinessDayRange` de la Fase 09, compartido.

**7. La demostración depende de internet.**
*Síntoma:* `make demo` falla en un avión.
*Fix mínimo:* el servidor de respuestas grabadas de §6.1.

**8. Cerrar el curso sin la revisión contra `INSTINTOS.md`.**
*Síntoma:* el código tiene reflejos que el propio curso enseñó a detectar.
*Fix mínimo:* §6.4, con los hallazgos resueltos de una de las tres formas.

### 🧨 Rompe a propósito

**El último del curso: mata todo y comprueba que nada se pierde.**

```bash
#!/usr/bin/env bash
# scripts/chaos.sh — el experimento de cierre.
set -euo pipefail

./bin/storeagent seed --movements 5000 --seed 42
make demo &
DEMO=$!

# Matar un servicio al azar cada diez segundos, durante dos minutos.
SERVICES=(opsreport eventrelay atlassync clearinghouse postgres valkey mongo)
END=$(( $(date +%s) + 120 ))
while [ $(date +%s) -lt $END ]; do
  sleep 10
  SVC=${SERVICES[$RANDOM % ${#SERVICES[@]}]}
  echo "💥 matando $SVC"
  docker compose kill "$SVC"
  sleep 3
  docker compose start "$SVC"
done

wait $DEMO || echo "la demostración falló durante el caos (aceptable)"

echo "═══ reintentando el flujo tras el caos ═══"
make demo

echo "═══ INVARIANTES ═══"
scripts/verify-invariants.sh
```

```bash
# scripts/verify-invariants.sh — lo que TIENE que cumplirse pase lo que pase.

# 1. Ningún movimiento perdido.
[ "$(sqlite3 "$AGENT_DB" 'SELECT count(*) FROM movements')" = \
  "$(psql -Atc 'SELECT count(*) FROM movements')" ] || fail "movimientos perdidos"

# 2. Ningún asiento duplicado (la restricción única de la F13).
[ "$(psql -Atc 'SELECT count(*) FROM (SELECT movement_id, account FROM ledger_entries GROUP BY 1,2 HAVING count(*)>1) d')" = "0" ] \
  || fail "asientos duplicados"

# 3. La ecuación del lote cuadra.
psql -Atc "SELECT processed = reconciled + failed FROM batches WHERE status='completed'" | grep -qv f \
  || fail "el lote no cuadra"

# 4. El outbox se vació.
[ "$(psql -Atc "SELECT count(*) FROM outbox WHERE status='pending'")" = "0" ] \
  || fail "outbox atascado"

# 5. Ninguna entrega murió por NUESTRA culpa (F07: los apagados no gastan intentos).
[ "$(psql -Atc "SELECT count(*) FROM deliveries WHERE status='dead' AND last_error LIKE '%context canceled%'")" = "0" ] \
  || fail "entregas muertas por cancelación propia"

# 6. El socio no recibió duplicados sin deduplicar.
[ "$(curl -sf localhost:9100/stats | jq -r .duplicates_accepted)" = "0" ] \
  || fail "el socio aceptó duplicados"

echo "✅ los seis invariantes se cumplen"
```

**Si los seis pasan tras dos minutos de matar servicios al azar, tienes una
plataforma.** Y cada invariante corresponde a una lección concreta del curso: la
idempotencia de la Fase 13, la ecuación del lote, el apagado ordenado de la Fase
07, la deduplicación del consumidor.

---

## 🧪 8. Ejercicios (20)

**🟢 Fácil (1–5)**

1. Levanta la plataforma completa y verifica que los ocho llegan a `healthy`.
   *Criterio:* ninguno se queda en `starting`, y explicas por qué el healthcheck no
   puede usar `curl`.
2. Ejecuta `make demo` y traza un movimiento por los cinco pasos. *Criterio:* el
   mismo identificador aparece en SQLite, PostgreSQL, los asientos, el outbox y
   `fakeconsumer`.
3. Encuentra la traza completa en Jaeger. *Criterio:* un `trace_id` atraviesa los
   cuatro servicios y explicas qué lo hace posible.
4. Corre `golangci-lint`, `make cover-check` y la suite completa con
   `-shuffle=on -count=3`. *Criterio:* todo en verde, o documentas cada excepción.
5. Ejecuta el inventario del curso: líneas, tags, commits. *Criterio:* la tabla, y
   un comentario sobre la proporción entre código y tests.

**🟡 Intermedio (6–13)**

6. Escribe la suite de integración de la plataforma. *Criterio:* verifica los seis
   invariantes de §7 y falla si rompes cualquiera.
7. Escribe `TestResilience` para los cuatro servicios. *Criterio:* cada uno se mata
   con `SIGKILL` y el flujo se recupera sin perder ni duplicar.
8. Extrae el paquete `contract` con los tipos de frontera. *Criterio:* los dos
   lados de cada frontera usan la misma definición, y provocas la divergencia de la
   autopsia para demostrar que ahora es imposible.
9. Monta las fixtures compartidas. *Criterio:* cambias un campo y **los dos lados
   fallan a la vez**.
10. Ejecuta la revisión de §6.4 completa. *Criterio:* reportas todos los hallazgos,
    resueltos de una de las tres formas, y **al menos uno es una corrección real**.
11. Verifica que la plataforma funciona sin internet. *Criterio:* desconectas la
    red y `make demo` pasa.
12. Escribe el `chaos.sh` y ejecútalo. *Criterio:* los seis invariantes se cumplen
    tras dos minutos de caos, con semilla fija.
13. **Línea de comandos.** Escribe el guion que traza un movimiento por los cinco
    almacenes con un solo comando. *Criterio:* recibe el identificador y produce un
    informe legible.

**🟠 Difícil (14–17)**

14. **Responde las ocho preguntas de la defensa.** *Criterio:* (a) cada una cita
    código o mediciones tuyas; (b) la 7 nombra un servicio real de tu trabajo; (c)
    la 1 incluye lo que **sí** trasladaste; (d) ninguna respuesta es genérica.
15. Completa `INSTINTOS.md` con los cinco niveles. *Criterio:* (a) todos los ☕ del
    curso clasificados; (b) cada uno con su coste medido; (c) **añades al menos dos
    que descubriste tú** y no están en el material; (d) justificas el nivel de tres
    de ellos.
16. Escribe `docs/veredicto-general.md`. *Criterio:* (a) los cinco casos de §6.6
    desarrollados con un ejemplo real cada uno; (b) al menos tres cosas que Go **no
    tiene** y echas de menos con razón; (c) la sección de dónde sí es la respuesta;
    (d) se lee como un consejo, no como una defensa.
17. Haz la revisión de código del curso **de otra persona** —o del tuyo con seis
    meses de distancia—. *Criterio:* (a) usas `INSTINTOS.md` como lista; (b)
    encuentras al menos cinco cosas; (c) **las escribes como las escribirías en un
    PR**: concretas, con el porqué, sin condescendencia; (d) distingues lo que es un
    error de lo que es una preferencia.

**🔴 Muy difícil (18–20)**

18. **Amplía la plataforma con un requisito real.** Elige uno: (a) un quinto
    servicio que agregue métricas de negocio de los otros cuatro; (b) un segundo
    tipo de socio que reciba por SFTP en vez de webhook; (c) multi-inquilino: cada
    tienda pertenece a una filial con su propia contabilidad. *Rúbrica:* (a) el
    diseño se justifica contra los cuatro servicios existentes; (b) **no rompes
    ninguna frontera existente**, y lo demuestras con la suite de plataforma; (c)
    los invariantes se mantienen; (d) aplicas lo que el curso enseñó y **citas qué
    fase de dónde**; (e) escribes qué decidiste **no** hacer y por qué.
19. **El post mortem del curso.** Escribe `docs/postmortem.md` sobre tu propio
    recorrido. *Rúbrica:* (a) las tres decisiones de diseño que más te costó tomar,
    con lo que decidiste y por qué; (b) los dos bugs que más tardaste en encontrar,
    y qué los habría detectado antes; (c) las tres cosas que harías distinto desde
    la Fase 01; (d) **lo que sigues sin entender bien**, dicho sin adornos —es la
    parte más valiosa y la que más cuesta escribir—; (e) qué parte del curso te
    parece que sobra o falta, con argumento.
20. **La presentación al equipo.** Prepara la sesión real de cuarenta minutos para
    tus compañeros de Java. *Rúbrica:* (a) empieza por **qué problema resuelve Go**
    para vuestro contexto concreto, no por sintaxis; (b) tres demostraciones en vivo
    que muestren algo que en Java cuesta más, con el código de los dos lados; (c)
    **la sección honesta de qué se pierde**, con los cinco casos del veredicto
    general; (d) los números de B-24 con sus condiciones y sus límites; (e) una
    recomendación concreta —qué probaríais primero, con qué servicio, con qué
    criterio de éxito— y **una fecha para decidir**; (f) responde las cinco
    preguntas difíciles: *¿y el equipo?*, *¿y lo que ya funciona?*, *¿cuánto
    tardamos?*, *¿y si nos arrepentimos?*, *¿por qué no Kotlin/Rust/quedarnos como
    estamos?*; (g) **si tu conclusión es que no merece la pena, la presentación está
    igual de bien hecha** — y probablemente sea la más valiosa.

**🔥 Opcionales**

- Despliega la plataforma en una nube real con el mínimo esfuerzo y mide el coste
  mensual. Compáralo con la estimación del ejercicio 26 de la Fase 16.
- Escribe el `CONTRIBUTING.md` de Meridian: qué tiene que saber alguien que se
  incorpora mañana. Es la prueba definitiva de si el proyecto está bien organizado.
- Reescribe uno de los cuatro servicios desde cero, con todo lo que sabes ahora.
  Compara el resultado con el original y mide cuánto has aprendido de verdad.

---

### 🔴 Desafíos de cierre

> Tres ejercicios de dificultad alta que **no cuentan en el total de la sección**.
> Son los últimos del curso y los tres se hacen **con otra persona delante**, que es
> lo que los distingue de todo lo anterior.

**D1 — El onboarding de un día, verificado.**
Siéntate con alguien que no haya hecho este curso y consigue que, en un día, tenga
la plataforma corriendo y entregue un cambio pequeño con su test.
*Rúbrica:* (a) parte de `docs/onboarding.md` de la Fase 00 y de `CONTRIBUTING.md`;
(b) **no le ayudas de palabra**: si se atasca, el fallo es de la documentación y lo
anotas; (c) registras cada punto de fricción con su minuto; (d) corriges la
documentación y repites con otra persona; (e) el criterio de éxito es duro: **cero
preguntas que la documentación no responda**. Si no lo consigues, di qué falta —esa
lista vale más que el ejercicio.

**D2 — El caos de treinta minutos.**
Extiende `chaos.sh` de dos minutos a treinta, con carga sostenida y fallos más
duros.
*Rúbrica:* (a) añade a la lista: disco lleno, latencia de red inyectada, reloj
desplazado, y la base de datos rechazando conexiones nuevas; (b) los **seis
invariantes** se cumplen al final, y lo verificas; (c) mides la degradación de
servicio durante el caos: cuántas peticiones fallaron y cuántas se sirvieron
degradadas; (d) encuentras **al menos un invariante nuevo** que no estaba en la
lista y que el caos te enseñó; (e) el experimento es reproducible con semilla; (f)
escribes el informe como lo escribirías tras un incidente real.

**D3 — La prueba de la frontera: extraer un servicio.**
Saca uno de los cuatro servicios a **otro repositorio** y haz que la plataforma siga
funcionando.
*Rúbrica:* (a) eliges cuál y justificas por qué es el más fácil —o el más
instructivo—; (b) descubres **todo** lo que compartían sin saberlo: el paquete
`contract`, las fixtures, el `go.work`, las utilidades de test; (c) para cada
acoplamiento, decides: publicar como módulo, duplicar, o rediseñar la frontera; (d)
la suite de plataforma sigue pasando con los dos repositorios; (e) mides qué se
perdió —el cambio atómico entre servicios, sobre todo— y **dices si volverías
atrás**; (f) es la prueba definitiva de la lección de §4: si la extracción fue
dolorosa, `commons` era más grande de lo que debía.

---

## 📚 9. Referencias

### Documentación oficial

- **Go: todo lo del curso**, en un sitio: https://go.dev/doc/ — y las *Release
  Notes* (https://go.dev/doc/devel/release), que a partir de ahora vas a leer cada
  seis meses.
- **Go Code Review Comments** — https://go.dev/wiki/CodeReviewComments — la lista
  que vas a usar en cada revisión de PR. Reléela ahora, con el curso hecho: vas a
  entender por qué está cada punto.
- **Google Go Style Guide** — https://google.github.io/styleguide/go/ — más
  completa y más opinada; útil para fijar convenciones de equipo.
- **Effective Go** — https://go.dev/doc/effective_go — el documento fundacional, y
  **no cubre nada posterior a 2012**. Saber eso es parte de leerlo bien.
- **Go Proverbs** — https://go-proverbs.github.io/ — ocho minutos. Ahora significan
  algo.

### Libros — el orden de continuación

- **100 Go Mistakes and How to Avoid Them** — Harsanyi. **El primero que leer
  después de este curso.** Es prácticamente el catálogo de `INSTINTOS.md` por otros
  medios, con cien casos y sus mediciones.
- **Learning Go (2ª ed.)** — Bodner. Para consolidar y cubrir los huecos.
- **Concurrency in Go** — Cox-Buday. Si la Fase 06 te dejó con ganas.
- **Efficient Go** — Płotka. Si la Fase 15 te dejó con ganas.
- **Let's Go** y **Let's Go Further** — Edwards. El enfoque stdlib pura, llevado
  más lejos.
- **Designing Data-Intensive Applications** — Kleppmann. **No es de Go y es el
  libro más valioso de esta lista** para lo que viene después.
- **Release It!** — Nygard. Para todo lo que las Fases 10 y 14 rozaron.

### Artículos y charlas — las que resumen el curso

- **Go Proverbs** — Rob Pike, GopherFest 2015. Ahora los entiendes todos.
- **Concurrency is not Parallelism** — Rob Pike. Vuelve a verla; se ve distinta.
- **Rethinking Classical Concurrency Patterns** — Bryan C. Mills, GopherCon 2018.
- **How I Write HTTP Services after Eight Years** — Mat Ryer. Compara con lo que
  escribiste.
- **Choose Boring Technology** — Dan McKinley. **Léelo al terminar el curso**, no
  antes.
- **Errors are values** — Rob Pike. Corto, y ahora significa algo distinto.
- **Codebase Refactoring (with help from Go)** — Russ Cox.

### Comunidad y continuación

- **Go Blog** — https://go.dev/blog/ — la fuente de primera mano.
- **Go Weekly** — https://golangweekly.com — el boletín semanal.
- **r/golang** y **Gophers Slack** (https://invite.slack.golangbridge.org).
- **GopherCon** — las grabaciones están en YouTube, y las de diseño de API y
  concurrencia envejecen muy bien.
- **El código fuente de la stdlib.** En serio: `$(go env GOROOT)/src`. Es legible,
  está bien escrito, y es la mejor documentación que existe sobre cómo escribir Go.

### Rutas de continuación

- **gRPC y Protocol Buffers** — https://grpc.io/docs/languages/go/ — el paso
  natural si haces servicios que hablan entre sí.
- **Kafka en Go** — `segmentio/kafka-go` o `confluent-kafka-go`, cuando la cola en
  base de datos deje de bastar (Fase 13).
- **Kubernetes** — el ecosistema está **escrito en Go**, así que `client-go` y los
  operadores son territorio natural.
- **WebAssembly** — Go compila a WASM; es un nicho que crece.
- **Herramientas de línea de comandos** — donde Go no tiene rival. `cobra`,
  `bubbletea` para interfaces de terminal.
- **Contribuir a un proyecto de código abierto en Go** — es la mejor forma de
  consolidar. Casi toda la infraestructura moderna está escrita en Go, y casi todos
  aceptan contribuciones pequeñas.

> ⚠️ **La advertencia final sobre las referencias.** Después de este curso vas a
> leer mucho Go, y **la mitad va a estar fechada**. Anterior a 2022: sin genéricos.
> Anterior a 2023: sin `slog`. Anterior a 2024: da por hecho que necesitas un
> enrutador de terceros. **Mira siempre la fecha**, y ten presente que un artículo
> de 2019 no está equivocado: está describiendo el Go de 2019, que es exactamente
> el que escribiste en el Bloque A.

### Orden de lectura sugerido para después del curso

**Los tres primeros meses:** *100 Go Mistakes*, de tapa a tapa, contrastando cada
error con tu propio código. Es donde más vas a ganar.
**Después:** *Designing Data-Intensive Applications*, que no es de Go y te va a
hacer mejor ingeniero independientemente del lenguaje.
**Y de forma continua:** el Go Blog, las notas de cada versión, y el código fuente
de la stdlib cuando algo te sorprenda.

---

## ⚖️ 10. Veredicto y cierre

### ⚖️ Cuándo NO usar lo que acabas de aprender

El veredicto general está en §6.6 y se resume en cinco casos: cuando el ecosistema
está en otro sitio, cuando el dominio es jerárquico, cuando tu equipo domina otro
stack, cuando el problema no era el lenguaje, y cuando echas de menos con razón lo
que Go no tiene.

**Y aquí, al cerrar, el más importante de todos, que no es sobre Go:**

> 🧭 **No uses nada de esto para tomar una decisión que no te toca tomar.**
>
> Has terminado un curso de 131 horas y sabes más de Go que casi nadie en tu
> equipo. Ese conocimiento nuevo genera un impulso reconocible: querer usarlo. **Es
> exactamente el sesgo que produjo la autopsia de la Fase 16**: 2.400 días-persona
> para ahorrar 40.000 euros al año.
>
> Lo que este curso te dio no es la capacidad de migrar. Es la de **medir, comparar
> y decidir con criterio** — incluida la decisión de no hacer nada. La Fase 16
> termina recomendando no migrar tres de cuatro servicios, y eso no es un fracaso
> del curso: es su resultado.

### 📖 Diccionario Java ⇄ Go: las diez entradas que más vas a usar

Los dieciséis diccionarios de las fases anteriores, juntos, están en
`docs/diccionario.md`. Las diez entradas que más vas a usar, para tenerlas a mano:

| Java / Spring | Go | Dónde se rompe |
|---|---|---|
| `interface` + `Impl` | struct concreto; la interfaz la declara **el consumidor** | La diferencia de diseño más importante del curso |
| `@Autowired` | parámetro del constructor | `main` es el contenedor, y se lee entero |
| `try/catch` | `if err != nil` | Nada obliga a manejarlo; el linter es la mitigación |
| `ThreadLocal` | `context.Context` (solo cancelación y valores de petición) | Explícito, por parámetro. No es un sustituto general |
| `ExecutorService` | canal + N goroutines | Un patrón, no un tipo. El límite, la cola y el apagado se ven |
| `@Transactional` | `tx` por parámetro | El alcance se ve en la firma |
| `@Entity` | un struct | Sin entidades gestionadas, sin *lazy loading*, sin caché de primer nivel |
| `@Cacheable` | un decorador escrito | Las cuatro decisiones se toman a conciencia |
| Spring Batch | ~520 líneas | **La brecha más grande del ecosistema** |
| Actuator | endpoints escritos | Spring Boot da mucho hecho. Ventaja real |

### Lo que sigue

**Nada. El curso termina aquí.**

Tienes cuatro servicios funcionando, un banco de pruebas, un veredicto con números,
un catálogo de cuarenta reflejos y ocho respuestas escritas. Eso es más de lo que
la mayoría de la gente tiene después de un año usando un lenguaje.

Lo que viene ahora es de verdad: el lunes, un repositorio Go ajeno, un PR que
entregar, y una decisión de arquitectura que defender.

**Tres cosas para llevarte, y solo tres:**

1. **`INSTINTOS.md` es tu documento.** Ábrelo en la primera revisión de código que
   hagas. Y añádele lo que encuentres: el catálogo no se acabó, solo se empezó.
2. **Mide antes de opinar.** El curso entero descansa en eso, y es lo único de aquí
   que sirve igual en cualquier lenguaje.
3. **Y la respuesta correcta puede ser "no migres".** Si el curso te enseñó a decir
   eso con datos delante, ya se pagó solo.

### La señal de que quedó bien

> *"El lunes abro un repositorio Go que no escribí, leo un paquete entero sin
> traducirlo mentalmente a Java, veo dos cosas que cambiaría y sé explicar por qué
> — sin decir 'mejores prácticas' ni una vez."*

Y la otra, que es la que de verdad cierra el curso:

> *"Mi arquitecto me preguntó si migramos. Le enseñé ocho números, una estimación
> de coste y un punto de equilibrio. Y le recomendé que no."*

> 🏷️ **No cierres el curso sin el tag.** Con el checklist de la sección 2 en
> verde, `make demo` funcionando sin internet, los seis invariantes del caos
> cumpliéndose, `golangci-lint` y la cobertura en verde en los cuatro módulos, las
> ocho respuestas escritas y `git status` limpio:
>
> ```bash
> git tag -a fase-17 -m "F17 cerrada: la plataforma Meridian completa con los cuatro servicios integrados; flujo de punta a punta verificado; suite de plataforma y prueba de caos con seis invariantes; revisión final contra INSTINTOS.md; defensa técnica escrita; veredicto general"
> git tag -a meridian/v1.0 -m "La plataforma Meridian, completa"
> git tag -a curso-completo -m "Go para desarrolladores Java senior: 18 fases, 4 servicios, 28 mini proyectos, 24 mediciones"
> ```
>
> Y el comando con el que se cierra:
>
> ```bash
> git log --oneline --graph --decorate --tags
> ```
>
> Dieciocho tags de fase, cuatro servicios con su historia, y un `git diff
> bloque-a-completo fase-08` que sigue siendo el documento más instructivo que
> escribiste.
>
> Gracias por llegar hasta aquí. 🐹

---

# 📌 Bloque de autoría (fuera de lo que lee el estudiante)

## 📌 Estado del curso al cierre

### Deudas 💸 — inventario completo

| Deuda | Declarada | Pagada | Estado |
|---|---|---|---|
| `Makefile` sin validación | F00 | F14 | ✅ |
| Umbral de cobertura que no falla | F00/F04 | F14 | ✅ |
| Verificación por pantalla | F01 | F04 | ✅ |
| `memstore` no concurrente | F02 | F06 | ✅ |
| Retroceso lineal sin jitter | F02 | F10 | ✅ |
| **SSRF en la URL del endpoint** | **F02** | **F14** | ✅ (12 fases) |
| Logger provisional | F03 | F14 | ✅ |
| Enrutado a mano | F05 | F08 | ✅ |
| Sin apagado ordenado | F05 | F07 | ✅ |
| Cola en memoria | F06 | F09 | ✅ |
| `time.Timer` por entrega | F06 | F09 | ✅ |
| Apagado sin plazo | F06 | F07 | ✅ |
| Firma HMAC sin verificar | F10 | F14 | ✅ |
| Caché en memoria de AtlasSync | F10 | F12 | ✅ |
| AtlasSync sin persistencia | F10 | F11 | ✅ |
| `time/tzdata` en imagen mínima | F09 | F14 | ✅ |
| Hook de pre-commit | F00 | F14 | ✅ |

> ✅ **Diecisiete de diecisiete.** La del hook de pre-commit fue la última y estuvo
> a punto de quedarse implícita en `make ci`. Se implementó explícitamente porque
> la guía de estilo §8.1 dice que **un 💸 sin destino es un error de escritura**, y
> quedarse a una de diecisiete habría sido justo ese error — el mismo que el curso
> le reprocha a cualquier equipo que declara deuda técnica y no la cobra nunca.

### Mediciones — cobertura del plan

**Las 29 entradas de `prompts/formato-de-benchmarks.md` §5 están asignadas a su
fase.** Empezaron siendo 24; siete propuestas quedaron sueltas durante la escritura
y el repaso de cierre las resolvió, cada una por la vía que le correspondía:

| Propuesta | Pedida por | Resolución |
|---|---|---|
| Amplificación del reintento (histograma) | F10 | ✅ **B-25** — la más didáctica de la F10 |
| `$push` frente al tamaño del documento | F11 | ✅ **B-26** |
| Rendimiento del outbox por instancias | F13 | ✅ **B-27** — sostiene el ⚖️ de la F13 |
| Coste del middleware por petición | F05, F10, F14 | ✅ **B-28**, medida en la F15 |
| Fake frente a mock en tiempo de suite | F04, F10, formato §1 | ✅ **B-29** |
| `slog` frente a `log.Printf` | F14 | 🔤 afirmación suavizada; la fila de logging de B-28 la cubre |
| `ctx.Value` por profundidad | F07 | 🔤 afirmación suavizada a lo estructural |
| Efecto de `MaxIdleConnsPerHost` | F10 | 📎 sección de B-23 |

> 🧭 **Las dos suavizadas son la parte interesante.** El formato admite dos salidas
> ante una afirmación sin medición —medir o no afirmar— y las dos se usaron. Que
> `ctx.Value` sea una búsqueda lineal por la cadena de padres es **estructural**: se
> verifica leyendo `context.valueCtx`, no midiendo. Ponerle un número habría
> debilitado el argumento, porque el motivo para no meter datos de negocio en el
> contexto es de diseño y sigue en pie aunque la búsqueda fuera gratis.
>
> **Nunca se usó la tercera salida**, que es escribir la frase igual y suavizarla
> con un "suele ser". Esa es la que el curso prohíbe, y por eso conviene que quede
> escrito que no se usó.

### Convención de tags — ampliación ya recogida

El curso amplía la convención original de `prompts/propuesta-fases-y-alcance.md`
§4 —que solo contemplaba `fase-NN` y los de proyecto— con cinco tags de hito:

- `bloque-a-completo` (F07) — **usado dos veces en la F08** y en el cierre. Es un
  entregable declarado de la migración.
- `plataforma/v1.0-rc1` y `-rc2` (F14, F15).
- `duelo/v1.0` (F16), `meridian/v1.0` y `curso-completo` (F17).

**Los cinco están recogidos en `00-convencion-de-git-y-tags.md` §3.3**, que es la
fuente de verdad de los tags. El más importante es el primero: sin él, el
`git diff bloque-a-completo fase-08` que la Fase 08 promete no funciona. Resuelto.

## 📌 Cabos sueltos: cómo se cerraron

El repaso de continuidad del cierre encontró catorce cadenas abiertas entre fases
—una fase promete algo para otra y la otra no lo recoge—. **Se cerraron todas**, y
el inventario queda aquí porque la forma de cerrar cada una dice más que la lista:

| Cabo | Abierto en | Cerrado |
|---|---|---|
| `compose.yaml` sin conjunto de réplicas | F11 (ej. 20, bloqueante) | F00 §6.8: servicio `mongo-rs` tras un perfil, y la instancia suelta se queda a propósito |
| `rowserrcheck` no configurado | F09 | F00 §6.9, con `sqlclosecheck` de paso |
| Columna `claimed_at` ausente | F09 §6.4 | F09 §6.2: columna, índice parcial del recuperador y sellado en la reclamación |
| Hook de pre-commit (💸 sin pagar) | F00 | F14 §6.6: `.githooks/` + `core.hooksPath` + `--new-from-rev` |
| `goleak` prometido y no entregado | F07 | F08 §6.5, con el 🪞 de qué añade sobre el contador a mano |
| `testify/require` en la guía y no en el código | guía §7.4 | F09 §6.11, acotado al andamiaje y con su 🪞 |
| `errWriter` de Pike | F03 | F13 §6.6, en el escritor de CSV |
| Negociación de contenido: contradicción | F05 ⇄ F13 | F13 §6.6 documenta por qué query param, y la regla general que queda |
| `container/heap` sin dueño | F01 → F06 → F13 | F06 ej. 27, y se declara que no tendrá sección propia |
| Métricas de caché no exportadas | F12 | F14 §6.3, reutilizando los contadores de la F12 |
| `http.ResponseController` | F13 | F14 §6.10, como el sexto sitio de timeouts |
| `httptrace` para uso serio | F10 | F15 §5, como perfilador del lado cliente |
| `JSONB` como alternativa documental | F11 | F09 §6.8 declara la omisión; el D1 de la F11 la mide |
| Doble capa de reintento | F10 | F17 §6.2 |

**Y la comparación del duelo sin Mongo ni Valkey**, que la F11 pidió: está en el
"qué NO demuestra" de **B-24**, con la instrucción de no extrapolar nada sobre
ellos. No se amplió el duelo a propósito — añadir dos motores a una comparación de
lenguajes la habría vuelto ilegible, y el veredicto de la F16 no depende de ellos.

> 🧭 **Lo que el ejercicio enseña, y por qué queda escrito.** De catorce cabos,
> **once eran una fase prometiendo algo que otra tenía que recoger**. Ninguno era
> un error de contenido: eran errores de *cadena*. En un curso de dieciocho fases
> escritas a lo largo de meses, ese es el modo de fallo dominante, y la única
> defensa es un repaso que siga cada promesa hasta su destino. **Es el mismo
> argumento que el curso hace sobre las deudas 💸: declararlas no sirve de nada si
> nadie comprueba que se pagaron.**

## ☕ Reflejos para `INSTINTOS.md`

- **"Ahora extraemos las piezas comunes a `commons`"** — el reflejo del capstone.
  Coste: cuatro servicios que se despliegan juntos, una librería que acumula todo, y
  abstracciones que impiden la divergencia legítima. Antídoto: **se comparte lo que
  tiene una sola respuesta correcta y ninguna política de negocio dentro**.
- **"Cada servicio tiene su suite en verde, luego la plataforma funciona"** — la
  autopsia: cuatro fallos triviales, ninguno detectado, porque cada uno probaba
  contra **su idea** del contrato.
- **"Ya que estamos, lo arreglamos"** — nivel 5 del recorrido. **No es un reflejo
  de Java: es humano**, y es el único que no se desaprende del todo.
- **"Ahora que sé Go, migremos"** — el sesgo del conocimiento nuevo, que es el que
  produjo la autopsia de la F16.

## 📐 Mediciones

Esta fase no produce entradas nuevas y **cierra el inventario**. Ver arriba las
siete propuestas sin asignar, que son la decisión editorial pendiente más grande
del curso.
