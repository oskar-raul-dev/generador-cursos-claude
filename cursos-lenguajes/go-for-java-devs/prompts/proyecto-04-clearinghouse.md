# 🧾 Proyecto 4 — ClearingHouse Service
## Conciliación y cierre contable por lotes · Meridian Retail Group

> **Eje técnico:** SQLite en el borde, procesamiento por lotes reanudable,
> scheduling, y **el duelo medido contra Spring Boot**.
> **Nace:** Fase 09, ya en **Go moderno** · **Cierra:** Fase 17.
> **Módulos:** `services/clearinghouse` (central) y `services/storeagent` (borde).
> **Binarios:** `clearinghouse`, `storeagent`.
> **Gemelo Java:** `reference/clearinghouse-spring/`, entregado hecho.

---

## 1. El problema

Meridian tiene ciento cuarenta tiendas. Cada una registra movimientos de caja
—ventas, devoluciones, anulaciones, retiros, depósitos— en un punto de venta que
funciona **con o sin red**, porque una tienda no puede dejar de vender porque el
enlace esté caído.

Cada noche hay que conciliar: juntar los movimientos de las ciento cuarenta
tiendas, cruzarlos con lo que reportó la pasarela de pagos y el banco, detectar
descuadres, producir los asientos y cerrar el periodo. Son entre dos y cinco
millones de movimientos por noche, y la ventana es de dos horas.

Hoy lo hace un proceso heredado que tarda tres horas cuando todo va bien, no se
puede reanudar si falla a la mitad, y nadie se atreve a tocar.

**ClearingHouse** son dos piezas: un **agente** que vive en cada tienda,
acumula movimientos en SQLite y los sincroniza cuando hay red; y un **servicio
central** que recibe, concilia por lotes reanudables, produce asientos y cierra
periodos.

---

## 2. Por qué este proyecto existe

Tres razones, y las tres son didácticas:

**Primera: SQLite en el borde tiene sentido de verdad.** No es un ejemplo
forzado. Un agente que corre en un mini-PC de una tienda, sin servidor de base de
datos, que sobrevive a cortes de luz y sincroniza cuando puede, es exactamente el
caso de SQLite — y es también exactamente el caso donde un binario estático de
quince megas gana a un JAR con una JVM.

**Segunda: el lote es el territorio donde Java es fuerte.** Spring Batch resuelve
reanudación, reintento por ítem, particionado y métricas de job. En Go eso se
escribe. El curso lo escribe, mide cuánto cuesta escribirlo, y da un veredicto
honesto — que en este terreno no siempre favorece a Go.

**Tercera: es el servicio del duelo.** ClearingHouse está implementado dos veces
con el mismo esquema, los mismos endpoints y el mismo cierre. La versión Spring
Boot **se entrega hecha** —el lector ya sabe escribirla— y existe para que la
Fase 16 tenga algo real que medir.

---

## 3. Las dos piezas

### 3.1 `storeagent` — el agente de tienda

Una **herramienta de línea de comandos**, y es el sitio donde el curso trabaja el
diseño de CLI en serio.

```bash
storeagent init --store-id ST-042 --db ./agent.db
storeagent record --type sale --amount 149900 --currency COP --ref TKT-889231
storeagent import --file ./pos-export.csv
storeagent status
storeagent sync --server https://clearing.meridian.internal --once
storeagent sync --daemon --interval 5m
storeagent export --from 2026-03-01 --to 2026-03-04 --format csv
```

Guarda en SQLite con WAL activo, marca cada movimiento como pendiente o
sincronizado, reintenta con retroceso, y **nunca borra un movimiento que el
central no haya confirmado**. Se compila para `linux/amd64`, `linux/arm64`,
`darwin/arm64` y `windows/amd64` en un comando, sin runtime que instalar — que es
el argumento comercial de Go resumido en una línea de `make`.

En la Fase 13 se discute `flag` frente a `cobra` con el código delante, y el
veredicto del curso es que `flag` bastaba hasta el cuarto subcomando.

### 3.2 `clearinghouse` — el servicio central

Recibe lotes del agente, valida, deduplica por `(store_id, external_ref)`,
persiste en PostgreSQL, y ejecuta el cierre nocturno.

---

## 4. Entidades

### `Store`

```text
ID, Name, Country, Currency, TimeZone, Active
```

La zona horaria de la tienda **no es decorativa**: el cierre del día 4 de marzo en
Bogotá y en Ciudad de México no cubre el mismo intervalo UTC, y ese es el bug
más caro que este servicio puede tener. La Fase 09 lo trata y hay un ejercicio 🔴
dedicado.

### `Movement`

```text
ID           string
StoreID      string
ExternalRef  string     único por tienda; la clave de idempotencia
Type         string     sale | refund | void | withdrawal | deposit
AmountMinor  int64      en unidades mínimas: 149900 son $1.499,00
Currency     string
OccurredAt   time.Time  hora del punto de venta, con zona
ReceivedAt   time.Time
BatchID      *string
Status       string     received | matched | unmatched | disputed | settled
```

> 🧭 **`AmountMinor int64`, nunca `float64`.** La regla la fija AtlasSync y aquí
> se hereda. Un centavo perdido por redondeo, cinco millones de veces, es
> cincuenta mil unidades monetarias que alguien va a buscar.

### `Batch`

```text
ID, PeriodID, StoreID
Status        pending | running | paused | completed | failed
TotalCount, ProcessedCount, MatchedCount, UnmatchedCount
Checkpoint    string     desde dónde reanudar
StartedAt, FinishedAt, ErrorMessage
```

### `LedgerEntry`

```text
ID, BatchID, MovementID, Account, DebitMinor, CreditMinor, Currency, PostedAt
```

### `Period`

```text
ID, StoreID, Date, Status (open | closing | closed | reopened), ClosedAt, ClosedBy
```

---

## 5. API objetivo

```http
POST /sync/batches                      el agente empuja un lote
GET  /sync/batches/{id}                 acuse y estado

GET  /movements?store=&status=&from=&to=&cursor=
GET  /movements/{id}
POST /movements/{id}/dispute

POST /periods/{storeId}/{date}/close
POST /periods/{storeId}/{date}/reopen
GET  /periods?store=&status=

POST /runs                              lanza un cierre
GET  /runs/{id}                         progreso: procesados, tasa, estimación
POST /runs/{id}/pause
POST /runs/{id}/resume
GET  /runs/{id}/report

GET  /health · /ready · /metrics
```

El endpoint `GET /runs/{id}` devolviendo progreso en vivo es una de las cosas que
Spring Batch da hecho con su `JobRepository` y aquí hay que escribir. Se dice.

---

## 6. El cierre por lotes: la pieza central

Lo que la Fase 13 construye, y el orden importa:

1. **Selección** del universo: movimientos `received` de la tienda y el día, con
   la zona horaria de la tienda aplicada.
2. **Recorrido en *streaming***, con cursor y fragmentos de N filas. Nunca un
   `[]Movement` de cinco millones — y la versión ingenua se escribe primero, se
   mide 📐, y se ve la memoria subir hasta que el proceso muere. Es el 🧨 más
   memorable del curso.
3. **Conciliación** contra el reporte de la pasarela: coincidencia exacta,
   coincidencia por tolerancia, y no coincidencia.
4. **Producción de asientos**, en transacción por fragmento, no por movimiento
   ni por lote entero. La elección del tamaño se discute con números.
5. **Punto de control** tras cada fragmento, en la misma transacción. Es lo que
   hace el lote reanudable, y es lo que Spring Batch te da con `@StepScope`.
6. **Cierre del periodo** si no quedan descuadres, o informe de excepciones si
   los hay.
7. **Informe final** y evento al outbox para que OpsReport lo registre y
   EventRelay lo notifique.

Y las propiedades que se prueban, cada una con su test:

- **Reanudable**: matar el proceso al 60% y relanzarlo produce el mismo resultado
  que no haberlo matado.
- **Idempotente**: correr el cierre dos veces no duplica un solo asiento.
- **Acotado**: la memoria residente no crece con el tamaño del lote.
- **Observable**: el progreso se consulta mientras corre.
- **Cancelable**: una pausa deja el lote en un estado consistente.

---

## 7. El gemelo Spring Boot

`reference/clearinghouse-spring/` contiene la implementación Java: Spring Boot 3,
Spring Web, Spring Data JPA sobre el **mismo esquema PostgreSQL** y las **mismas
migraciones**, Spring Batch para el cierre, Actuator para las métricas.

Tres reglas que lo mantienen honesto:

1. **El mismo esquema y las mismas migraciones.** Si cada versión tuviera su
   modelo, la comparación no valdría nada.
2. **Escrito como lo escribiría un equipo Java competente**, usando lo que Spring
   da. Una versión Java deliberadamente mala para que Go gane sería una estafa
   pedagógica.
3. **No se enseña a escribirlo.** El lector ya sabe. Se entrega, se lee, y se
   mide.

El curso lo usa en dos momentos: en la Fase 13, para comparar el código del lote
lado a lado —y ahí Spring Batch se ve bien, porque lo hace bien—, y en la Fase 16
para el duelo completo.

---

## 8. Avance por fase

**Fase 09 — nace.** `storeagent` con SQLite: esquema, WAL, `record`, `import`,
`status`, `export`. Y la comparación honesta SQLite frente a PostgreSQL: qué
comparten, qué no (tipos flexibles, concurrencia de escritura, `ALTER TABLE`
limitado), y cuándo cada uno. En el central, el modelo PostgreSQL y las
migraciones.

**Fase 10.** `storeagent sync` con el cliente HTTP robusto: lotes, reintento,
retroceso, y la confirmación antes de marcar como sincronizado. Aquí se ve la
diferencia entre "lo mandé" y "lo recibieron".

**Fase 13 ⭐.** El cierre por lotes completo, con sus cinco propiedades probadas.
El planificador. El outbox. Y la comparación con Spring Batch, con el código de
los dos delante.

**Fase 14.** Métricas del lote —filas por segundo, tamaño del fragmento, tiempo
por fase—, trazas del cierre, configuración, y la imagen del agente frente a la
del central.

**Fase 15.** Perfilado del cierre: dónde se va el tiempo de verdad, cuánto cuesta
el `Scan`, cuánto la asignación por fila, y qué gana pre-dimensionar el
fragmento.

**Fase 16 ⭐.** El duelo. Ver `propuesta-fases-y-alcance.md` §3, Fase 16.

**Fase 17.** Integración: el agente sincroniza, el central concilia, OpsReport
registra el trabajo, EventRelay notifica, AtlasSync provee el tipo de cambio.

---

## 9. Qué se mide en la Fase 16

Con el mismo banco, la misma máquina, el mismo esquema y la misma carga:

- Arranque en frío hasta la primera petición servida.
- Memoria residente en reposo y a rendimiento sostenido.
- Latencia p50/p95/p99 y peticiones por segundo en `GET /movements`.
- CPU por petición.
- **El cierre de un millón de movimientos, extremo a extremo.**
- Tamaño de la imagen y tiempo de compilación desde limpio.
- Consumo bajo un pico de diez veces el tráfico normal.
- La JVM en tres configuraciones: por defecto, ajustada, y `native-image`.

Y lo que no sale en un gráfico y decide proyectos igual: líneas de código,
dependencias de tercero, tiempo hasta el primer endpoint funcionando, madurez de
librería por área, y facilidad de contratar.

> ⚖️ **El veredicto tiene que doler un poco en las dos direcciones.** Si el
> resultado de la Fase 16 es "Go gana en todo", la fase está mal escrita.

---

## 10. Qué NO se construye aquí

Contabilidad de verdad —partida doble completa, plan de cuentas, cierre anual—:
el modelo es suficiente para el problema técnico y se dice que es una
simplificación. Tampoco hay interfaz, ni firma digital de asientos, ni
integración bancaria real: el reporte de la pasarela es un CSV que el curso
genera.

---

## 11. Criterio de finalización

1. El agente registra movimientos sin red y sobrevive a un corte de luz.
2. Compila para cuatro plataformas en un comando, sin runtime externo.
3. Sincroniza sin perder ni duplicar movimientos, con red intermitente.
4. El central deduplica por `(store_id, external_ref)`.
5. El cierre de un millón de movimientos entra en la ventana declarada en
   `BENCHMARKS.md`, con memoria acotada.
6. Matarlo al 60% y relanzarlo produce idénticos asientos.
7. Correrlo dos veces no duplica nada.
8. El progreso se consulta mientras corre.
9. Las zonas horarias por tienda son correctas, con test que cruza tres husos.
10. El gemelo Spring Boot corre contra el mismo esquema y pasa los mismos casos.
11. La Fase 16 tiene sus números en `BENCHMARKS.md` y su veredicto escrito.
12. `go test -race ./...` y la suite de integración en verde.

---

## 12. 📖 El diccionario de este proyecto

| Spring | ClearingHouse en Go | Dónde se rompe |
|---|---|---|
| `Job` / `Step` | Una función con su bucle de fragmentos | Sin `JobRepository`: el estado del lote es una tabla tuya |
| `ItemReader` | `sql.Rows` recorrido en streaming | No hay paginación automática; el cursor es tuyo |
| `ItemProcessor` | Una función pura `(Movement) (LedgerEntry, error)` | Aquí Go gana claro: es una función y se prueba como tal |
| `ItemWriter` | Un `INSERT` por lote dentro de la transacción | Sin `flush` automático; decides el tamaño y lo mides |
| `@StepScope` + `ExecutionContext` | Columna `checkpoint` en `batches` | Reanudación escrita a mano — es el mayor coste de no usar Spring Batch |
| `RetryTemplate` por ítem | Clasificación + tabla de excepciones | Sin política declarativa; más código, más visible |
| `JobLauncher` / `JobOperator` | `POST /runs` y un registro en memoria | El control de ejecuciones es tuyo, incluido el "ya hay una corriendo" |
| `@Scheduled` + ShedLock | Ticker + bloqueo en PostgreSQL | Dos instancias: sin bloqueo corren las dos, y aquí eso duele |
| `BigDecimal` | `int64` en unidades mínimas | Sin decimal en la stdlib; la escala es una decisión explícita |
| `picocli` / `CommandLineRunner` | `flag` y, desde el cuarto subcomando, `cobra` | Sin inyección en el comando; el CLI cablea igual que `main` |
| Un JAR + JRE en la tienda | Un binario estático de ~15 MB | Aquí Go gana sin discusión, y la Fase 16 lo mide |
