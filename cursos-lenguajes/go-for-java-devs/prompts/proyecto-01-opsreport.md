# 🗂️ Proyecto 1 — OpsReport Service
## Trabajos operativos y reportes · Meridian Retail Group

> **Eje técnico:** CRUD empresarial, procesamiento asíncrono, PostgreSQL,
> generación de reportes con *streaming*.
> **Nace:** Fase 01, en Go 1.13 · **Migra:** Fase 08 · **Cierra:** Fase 17.
> **Módulo:** `services/opsreport` · **Binario:** `opsreport`.

---

## 1. El problema

Las áreas de Meridian —logística, tesorería, compras, soporte— lanzan cada día
trabajos operativos que hoy viven en hojas de cálculo y grupos de chat:
importaciones de catálogo, conciliaciones, recálculos de inventario, generación
de extractos, reprocesos de archivos de proveedor.

Nadie sabe cuántos hay en curso, cuántos fallaron ayer, ni cuánto tarda en
promedio una conciliación. Cuando dirección pide "el reporte de operación del
mes", alguien dedica dos días a juntarlo a mano.

**OpsReport** registra esos trabajos, los ejecuta en segundo plano con
concurrencia acotada, guarda el resultado de cada ejecución y produce reportes
descargables en CSV, JSON y HTML.

Es, deliberadamente, **el servicio más parecido a lo que un dev de Spring ya sabe
hacer**: CRUD, jobs, base de datos relacional, reportes. Por eso es el primero.
Lo que cambia no es el problema, es la forma de resolverlo — y esa es toda la
lección.

---

## 2. Objetivo funcional

1. Registrar un `WorkItem` con su referencia externa, tipo, descripción y
   prioridad.
2. Consultar y filtrar trabajos por estado, tipo, prioridad y rango de fechas.
3. Solicitar la ejecución de un trabajo.
4. Ejecutarlo de forma asíncrona, sin bloquear la petición HTTP.
5. Cancelar un trabajo encolado o en curso, cuando sea posible.
6. Registrar cada ejecución con su duración, su worker y su error si lo hubo.
7. Solicitar un reporte operativo con filtros.
8. Generar el reporte en segundo plano y consultar su estado.
9. Descargarlo en CSV, JSON o HTML.
10. Exponer `/health` y `/ready`.
11. Publicar eventos de dominio para que EventRelay los entregue a los socios
    (Fase 13, patrón outbox).

---

## 3. Entidades

### `WorkItem`

```text
ID                 string     identificador propio del servicio
ExternalReference  string     la referencia del sistema de origen (SAP-2026-000123)
Type               string     reconciliation | import | recalculation | statement | reprocess
Description        string
Priority           int        1 a 9; mayor es más urgente
Status             string     pending | queued | running | completed | failed | cancelled
CreatedAt          time.Time
UpdatedAt          time.Time
```

Transiciones legales, y **ninguna otra**:

```text
pending   -> queued | cancelled
queued    -> running | cancelled
running   -> completed | failed | cancelled
completed -> (final)
failed    -> queued            (reintento manual)
cancelled -> (final)
```

La máquina de estados se implementa en la Fase 02 como una función pura y se
prueba con una tabla exhaustiva en la Fase 04. **Es el primer sitio del curso
donde una interfaz sería un error**: es una función, y en Go se queda como
función.

### `JobExecution`

```text
ID            string
WorkItemID    string
AttemptNumber int
StartedAt     time.Time
FinishedAt    *time.Time    nulo mientras corre — y ese puntero es una decisión
Status        string        running | completed | failed | cancelled
ErrorMessage  string
WorkerID      int
DurationMS    int64
```

> 💡 El `*time.Time` frente a `time.Time` con valor cero es la primera discusión
> de modelado de la Fase 02, y la respuesta del curso es: **si "ausente" y "cero"
> significan cosas distintas, el puntero gana**. En Java esto era `null` y nadie
> lo pensaba.

### `ReportRequest`

```text
ID           string
Format       string     csv | json | html
Filter       Filter     embebido; ver abajo
Status       string     pending | generating | completed | failed
RequestedAt  time.Time
CompletedAt  *time.Time
FileName     string
SizeBytes    int64
RowCount     int
ErrorMessage string
```

```text
Filter:
  From, To       *time.Time
  Statuses       []string
  Types          []string
  MinPriority    *int
```

---

## 4. API objetivo

```http
POST   /work-items
GET    /work-items?status=&type=&from=&to=&limit=&cursor=
GET    /work-items/{id}
PUT    /work-items/{id}
DELETE /work-items/{id}
POST   /work-items/{id}/execute
POST   /work-items/{id}/cancel
GET    /work-items/{id}/executions

POST   /reports
GET    /reports
GET    /reports/{id}
GET    /reports/{id}/download

GET    /health
GET    /ready
GET    /metrics
```

Paginación **por cursor, no por número de página**, desde la Fase 09. Es una
decisión de diseño que el curso defiende con un número: el `OFFSET 100000` de la
paginación clásica hace que PostgreSQL recorra cien mil filas para descartarlas.

Ejemplo de alta:

```json
{
  "externalReference": "SAP-2026-000123",
  "type": "reconciliation",
  "description": "Conciliación diaria de tiendas del norte",
  "priority": 5
}
```

```json
{ "id": "wi_01HQ...", "status": "pending", "createdAt": "2026-03-04T08:12:00Z" }
```

---

## 5. Arquitectura objetivo

No se crea de golpe. Cada paquete aparece en la fase que lo necesita.

```text
services/opsreport/
  cmd/opsreport/main.go        ensambla y arranca; nada más
  internal/workitem/           dominio: tipos, estados, validación   (F01-F02)
  internal/opsreport/          casos de uso; declara sus interfaces  (F02)
  internal/memstore/           almacén en memoria                    (F02)
  internal/postgres/           almacén real                          (F09)
  internal/httpapi/            handlers, middleware, codificación    (F05)
  internal/worker/             cola y pool de ejecución              (F06-F07)
  internal/report/             generadores csv/json/html             (F13)
  internal/outbox/             publicación transaccional de eventos  (F13)
  internal/config/             configuración validada                (F03, F14)
  internal/obs/                logs, métricas, trazas                (F14)
  migrations/                  SQL versionado con goose              (F09)
  testdata/                    golden files                          (F04)
```

> 🧭 **Ninguna capa se crea vacía.** Si en la Fase 02 no hay nada que poner en
> `internal/httpapi`, el directorio no existe. La estructura es consecuencia, no
> plantilla.

---

## 6. Avance por fase

**Fase 01 — nace.** El tipo `WorkItem`, sus constantes de estado y tipo, la
validación y el cálculo de prioridad efectiva. Todo en un paquete, todo en
memoria, sin servicio. Aquí se pelea con slices y mapas por primera vez.

**Fase 02.** Separación real: el paquete `workitem` con el dominio y la máquina
de estados; el paquete `opsreport` con el servicio, que **declara** las
interfaces `Store`, `Clock` e `IDGenerator`; y `memstore` que las implementa sin
saberlo. Es la fase donde se ve por qué la interfaz vive en el consumidor.

**Fase 03.** Errores del paquete (`ErrNotFound`, `ErrInvalidTransition`,
`ErrDuplicateReference`), envoltorio con `%w`, configuración desde entorno y
archivo, y la serialización JSON del dominio con sus etiquetas.

**Fase 04.** Suite completa: tabla exhaustiva de transiciones, fakes de reloj y
almacén, golden files para la serialización, cobertura medida y umbral.

**Fase 05.** La API REST en memoria: los siete endpoints de work items, el
enrutado escrito a mano, la cadena de middleware, la traducción de errores de
dominio a códigos HTTP en un solo sitio, y la suite con `httptest`.

**Fase 06.** El motor asíncrono: cola con búfer acotado, N workers, el estado
avanzando de `queued` a `running` a `completed`, `sync.WaitGroup` para el
apagado, y el registro de `JobExecution`. Pasa `-race`.

💸 Aquí la cola vive **solo en memoria**: si el proceso muere, los trabajos
encolados se pierden. **Se paga en la Fase 09**, cuando la cola pasa a PostgreSQL
y la recuperación tras reinicio se vuelve un test.

**Fase 07.** `context` de punta a punta: el `DELETE` cancela el trabajo en curso,
el `SIGTERM` drena la cola con un límite de tiempo, y un test verifica que no
queda ninguna goroutine viva.

**Fase 08.** Migra. `embed` para las plantillas HTML del reporte, `slog` en lugar
del logger propio, el `ServeMux` moderno reemplazando el enrutado a mano
—comparación lado a lado—, `errors.Join` para los errores de validación
agregados, y la decisión explícita de **no** generalizar el almacén con
`Store[T]`.

**Fase 09.** PostgreSQL: esquema, migraciones, el almacén real, transacciones en
las transiciones de estado, paginación por cursor, recuperación de trabajos
encolados al arrancar, y la suite de integración con testcontainers.

**Fase 13.** El generador de reportes como job de larga duración: agregaciones en
SQL, recorrido de `sql.Rows` en *streaming* hacia el `io.Writer` de la respuesta
—sin cargar el dataset en memoria, y medido 📐 contra la versión ingenua—, los
tres formatos, y el patrón **outbox** publicando eventos de dominio para
EventRelay.

**Fase 14.** Logs estructurados con identificador de petición, métricas RED,
trazas, `/health` y `/ready` honestos, configuración validada al arrancar,
imagen de contenedor mínima.

**Fase 15.** Perfilado del endpoint de listado, del generador de reportes y del
pool de workers. Optimización **solo con evidencia**, y el registro de una mejora
que no lo fue.

**Fase 17.** Integración con los otros tres servicios y revisión final.

---

## 7. Los temas que este proyecto enseña y los otros no

- **El CRUD empresarial completo** sin un framework que lo genere, que es donde
  se ve cuánto hacía Spring Data y cuánto cuesta no tenerlo.
- **El job asíncrono clásico**: cola, workers, estados, reintento, cancelación.
- **El reporte grande**, que es el problema de *streaming* por excelencia: el
  momento en que `[]WorkItem` deja de caber en memoria y hay que pensar en
  `io.Writer`.
- **La paginación que escala.**
- **El patrón outbox**, que es la respuesta correcta a "cómo publico un evento
  dentro de una transacción" y que en Spring suele resolverse con una librería.

---

## 8. Qué NO se construye aquí

Autenticación real (el servicio vive tras un gateway y se dice así), interfaz de
usuario, exportación a Excel, programación por calendario —eso es ClearingHouse—,
y cualquier cola externa: la cola es PostgreSQL, y en la Fase 13 se explica en
qué punto eso deja de bastar y empieza el territorio de Kafka o NATS.

---

## 9. Criterio de finalización

1. Arranca con configuración externa y falla rápido si le falta algo.
2. Se conecta a PostgreSQL con el pool dimensionado y declarado.
3. Sirve los quince endpoints con sus códigos correctos.
4. Ejecuta trabajos concurrentes con tope, y el tope se puede configurar.
5. Recupera trabajos encolados tras un reinicio.
6. Cancela un trabajo en curso en menos de un segundo.
7. Genera un reporte de 500.000 filas sin que la memoria residente suba más de
   lo que dice su entrada en `BENCHMARKS.md`.
8. Apaga limpio ante `SIGTERM`, sin goroutines vivas.
9. Publica eventos por outbox sin perder ninguno ante caída entre commit y envío.
10. `go test ./...`, `go test -race ./...` y `make test-integration` en verde.
11. Cobertura de `internal/` sobre el umbral del curso.
12. Tiene benchmarks y perfiles de sus tres rutas calientes.

---

## 10. 📖 El diccionario de este proyecto

| Spring | OpsReport en Go | Dónde se rompe |
|---|---|---|
| `@RestController` + `@RequestMapping` | `http.Handler` registrado en el mux | No hay descubrimiento: si no lo registras, no existe |
| `@Service` | Un struct con sus dependencias por constructor | Nadie lo instancia por ti; `main` lo cablea |
| `@Repository` + `JpaRepository` | Una interfaz de 4 métodos en el consumidor | No hay consultas derivadas del nombre; escribes el SQL |
| `@Transactional` | `tx` pasado explícitamente | La propagación es un parámetro, no una anotación |
| `@Async` + `TaskExecutor` | Cola con búfer + pool de goroutines | No hay pool por defecto: lo dimensionas tú o no hay tope |
| `@Scheduled` | `time.Ticker` en una goroutine con `ctx` | Sin `ShedLock`: con dos instancias corren las dos |
| `ResponseEntity` | `w.WriteHeader` + `json.NewEncoder(w)` | Se escribe una vez; un segundo `WriteHeader` es un bug silencioso |
| `@ControllerAdvice` | Una función `writeError` en el borde | No es global: si no la llamas, no traduce |
| Jackson | `encoding/json` con etiquetas | Sin anotaciones de módulo; las fechas se deciden a mano |
| `Pageable` / `Page<T>` | Cursor opaco + `[]WorkItem` + `nextCursor` | No hay `totalElements` gratis, y contar cuesta |
