# 📎 Apéndice a03 — Los contratos y los prompts de generación
## Laboratorio de contenedores y Kubernetes local

> **Curso:** Laboratorio de contenedores y Kubernetes local · De laboratorio · crece con cada paso de generación
> **Usado por:** la [Fase 02](02-compose-el-sistema-en-un-archivo.md) y cada fase que estrena un paso (G1 en la 09, G2 en la 11… G13 en la 26) · **Versiones cubiertas:** las de [a01](a01-el-laboratorio.md)
> **Fecha de verificación ejecutada:** 03/10/2026 (G0, con Docker y con Podman) a 05/10/2026 (G13 contra el cluster) · macOS arm64 · Windows 11 y Linux: no verificados por el autor; se confirman al hacer el curso

**Esto no se lee de corrido.** Se entra para leer o cambiar un contrato, correr la suite de un paso,
o tomar el prompt que genera un servicio, y se sale.

**El problema que resuelve:** el curso es de plataforma, y el código de los cinco servicios es
andamiaje. Escribirlo a mano en cuatro lenguajes no enseña nada que el curso quiera enseñar, y
hacerlo exigiría saber Spring, Laravel, Nest y Go antes de empezar. Así que los servicios **se
generan**, con prompts publicados, y lo que decide si un servicio está bien no es quién lo escribió
ni cómo: es que **pase la suite de conformidad de su paso**.

**Qué queda fuera:** enseñar a programar en cualquiera de los cinco stacks. Si quieres escribir un
servicio a mano, puedes: la suite lo juzga igual.

> 📝 **Este apéndice creció con el curso**, un paso por fase, y está completo: el método, los cuatro
> contratos, la suite y los prompts de G0 a G13, cada uno con lo que tuvo que agregársele para que el
> código pasara.

---

## Índice

- [El método, en una página](#-el-método-en-una-página)
- [Cómo se lee un contrato](#-cómo-se-lee-un-contrato)
- [Los cuatro contratos, de un vistazo](#️-los-cuatro-contratos-de-un-vistazo)
- [Swagger UI](#-swagger-ui)
- [La suite de conformidad](#-la-suite-de-conformidad)
- [La matriz de generación](#-la-matriz-de-generación)
- [Los prompts de G0](#-los-prompts-de-g0) · [G1](#-los-prompts-de-g1) · [G2](#-el-prompt-de-g2) ·
  [G3](#-los-prompts-de-g3) · [G4](#-los-prompts-de-g4) · [G5](#-los-prompts-de-g5-) · [G6](#-los-prompts-de-g6) ·
  [G7](#-los-prompts-de-g7) · [G8](#-el-prompt-de-g8) · [G9](#-el-prompt-de-g9-y-el-del-generador-de-caos) ·
  [G10](#-los-prompts-de-g10) · [G11](#-los-prompts-de-g11) · [G12](#-los-prompts-de-g12) · [G13](#-los-prompts-de-g13)
- [Los `CLAUDE.md` de cada servicio](#-los-claudemd-de-cada-servicio)
- [Cuando el código generado no pasa](#️-cuando-el-código-generado-no-pasa)
- [Cuándo usar qué](#-cuándo-usar-qué)
- [Advertencias](#️-advertencias)
- [Referencias](#-referencias)
- [Ejercicios](#-ejercicios-8)

---

## 🧭 El método, en una página

```mermaid
flowchart LR
    C["el contrato (OpenAPI)<br/><code>contracts/openapi/</code>"] --> S["la suite del paso (Hurl)<br/><code>contracts/conformance/</code>"]
    S --> P["el prompt del paso<br/>este apéndice"]
    P --> K["el código<br/><code>services/#lt;svc#gt;/</code>"]
    K -- "si no pasa, se corrige el prompt, no el código" --> P
```

Cuatro reglas lo sostienen, y ninguna tiene excepciones:

1. **El contrato es la fuente de verdad.** Si un payload cambia de forma, se cambia primero el
   OpenAPI, después la suite y al final el código. Desde la [Fase 02](02-compose-el-sistema-en-un-archivo.md), el contrato está congelado.
2. **Un paso está hecho cuando su suite pasa contra el entorno**: contra compose en las Partes 0 y I,
   contra el cluster desde la Parte II.
3. **Una capacidad no llega antes que su paso.** Si el servicio de G0 tiene `/metrics`, está mal,
   aunque funcione. Cada prompt dice lo que el servicio **no** debe tener todavía, y la suite lo
   comprueba donde puede: en G0, `/metrics` tiene que dar 404.
4. **Si el código generado no pasa, se corrige el prompt.** El código no se arregla a mano, porque el
   próximo que regenere el servicio se encontraría el mismo error. Este apéndice publica el prompt que
   funcionó, no el primero.

La herramienta de referencia es **Claude Code**. Los prompts funcionan con cualquier asistente que
pueda leer los archivos del repositorio y correr comandos; con uno que no corra comandos, tú corres
la suite y le pegas el resultado. Lo que cambia entre herramientas es cuánto hay que insistir en lo
que el servicio **no** debe tener: los asistentes tienden a agregar lo que el framework sugiere.

---

## 📜 Cómo se lee un contrato

Los cuatro contratos están en `src/lab/contracts/openapi/`, uno por backend, en OpenAPI 3.1. El
`storefront` no tiene: su contrato es su suite. Tres cosas los distinguen de un OpenAPI cualquiera:

- **Cada operación declara su paso** en `x-lab-paso`. El servicio implementa solo las de su paso y
  las anteriores; las demás responden 404 (o 405, si la ruta ya existe con otro método) hasta que
  llegue su paso. Así, el contrato de hoy ya tiene la venta (G5) y la saga (G11), y el lector sabe
  desde la [Fase 02](02-compose-el-sistema-en-un-archivo.md) adónde va el sistema.
- **Las rutas de plataforma se repiten en los cuatro**: `/health/live`, `/health/ready` y
  `/metrics`, con el paso en que cada una cobra sentido.
- **Los nombres son los de la casa**: `SKU-0003`, `DRO-007`, precios en pesos enteros con
  `currency: COP`. Salen del patrimonio, de donde se extrae cada servicio.

Un extracto de `pricing.yaml`:

```yaml
  /prices/{sku}:
    get:
      tags: [precios]
      summary: El precio vigente de un producto en una droguería. En G0 devuelve un precio fijo.
      x-lab-paso: G0
    put:
      tags: [precios]
      summary: Fija el precio de un producto en una droguería. Pendiente hasta G1 (Fase 09).
      x-lab-paso: G1
```

**Cambiar un contrato**, después de la [Fase 02](02-compose-el-sistema-en-un-archivo.md), es un cambio en tres archivos y en este orden: el
OpenAPI, la suite del paso que lo usa, y el prompt del paso. Un cambio en el código sin esos tres es
deuda, aunque la suite pase.

> 💡 **Los datos maestros se editan; el estado se cambia con hechos.** El catálogo, los precios y el
> umbral de reposición se editan con `PUT` o `PATCH`. La existencia y las órdenes no: la existencia
> cambia con un movimiento y la orden con una cancelación, y los dos llevan un **código de razón**
> que sale de una tabla (`GET /reason-codes` en cada servicio), no de un enum del contrato. Por eso
> una corrección queda con su porqué y su `reference` —el archivo de traslados que no llegó, la
> orden que se reemplaza—, y por eso la [Fase 26](26-idempotencia-y-outbox.md) tiene algo que deduplicar.

Los cuatro son OpenAPI 3.1 válidos; se comprobó con `openapi-spec-validator` en un contenedor.

---

## 🗂️ Los cuatro contratos, de un vistazo

| Servicio | Operación | Paso |
|---|---|---|
| `pricing` | `GET /prices/{sku}?store=` | **G0** |
| | `GET /prices?store=` · `PUT /prices/{sku}` | G1 |
| `inventory` | `GET /stock/{storeId}/{sku}` | **G0** |
| | `PATCH /stock/{storeId}/{sku}` (umbral) · `POST /stock/{storeId}/{sku}/movements` (`RESTOCK`, `ADJUSTMENT` y `COUNT`) · `GET /reason-codes` | G1 |
| | `POST /sales` (con `Idempotency-Key` desde G13) | G5 |
| | `POST /loans` · `GET /loans/{loanId}` | G11 |
| `catalog` | `GET /products` | **G0** |
| | `POST /products` · `GET /products/{sku}` · `PATCH /products/{sku}` (estado) · `GET /categories` · `GET /reason-codes` | G1 |
| `replenish` | `GET /replenishment-orders` | **G0** |
| | `POST /replenishment-orders` · `GET /replenishment-orders/{id}` · `POST /replenishment-orders/{id}/cancel` · `GET /reason-codes` | G1 |
| los cuatro | `/health/live` · `/health/ready` (trivial) | **G0** |
| | `/health/ready` real · `/metrics` | G4 · G6 |

El gRPC de `pricing` (G10) no es OpenAPI: su contrato es `contracts/proto/pricing/v1/pricing.proto`, un servicio
`Pricing` con un solo método, `GetPrice`, que la [Fase 23](23-grpc-y-el-balanceo.md) presenta.

---

## 📖 Swagger UI

Para leer los contratos con una página en vez de con el YAML:

```bash
task contracts:docs
```

Debajo: `docker compose -f compose/compose.yaml --profile docs up -d contracts-docs`, que levanta
Swagger UI en un contenedor con los cuatro contratos montados, en `http://localhost:8090`. Corre en
compose y **nunca entra al cluster**: es una herramienta para leer, no un servicio del sistema. La
fuente de verdad sigue siendo el YAML y la suite, no la página.

```text
swagger 200
inventory.yaml 200
"name":"pricing" "name":"inventory" "name":"catalog" "name":"replenish"
```

Se apaga con el resto del proyecto de compose (`task compose:down`).

---

## 🧪 La suite de conformidad

Está en `src/lab/contracts/conformance/`, escrita en **Hurl**: un archivo por servicio y por paso,
con el nombre `<servicio>.<paso>.hurl`. Cada paso prueba **su** estado, no el acumulado: G0 exige que
`/metrics` dé 404, y G6 va a exigir lo contrario. Por eso `task conformance -- G1` no corre los
archivos de G0.

```bash
task conformance -- G0
```

Debajo: `docker compose -f compose/compose.yaml --profile conformance run --rm conformance`, con
`STEP=g0` en el entorno. La suite corre en un contenedor **dentro de la red de compose** y llama a
los servicios por su nombre (`http://pricing:8080`), así que ningún servicio necesita publicar un
puerto para probarse. Las direcciones salen de `compose.env`.

```text
Success /suite/pricing.g0.hurl (6 request(s) in 2 ms)
Success /suite/storefront.g0.hurl (2 request(s) in 13 ms)
Success /suite/replenish.g0.hurl (5 request(s) in 10 ms)
Success /suite/inventory.g0.hurl (5 request(s) in 22 ms)
Success /suite/catalog.g0.hurl (5 request(s) in 22 ms)
--------------------------------------------------------------------------------
Executed files:    5
Executed requests: 23 (718.8/s)
Succeeded files:   5 (100.0%)
Failed files:      0 (0.0%)
```

Un caso de la suite de `pricing`:

```hurl
GET {{pricing}}/prices/SKU-0003?store=DRO-007
HTTP 200
[Asserts]
header "Content-Type" contains "application/json"
jsonpath "$.sku" == "SKU-0003"
jsonpath "$.store" == "DRO-007"
jsonpath "$.price" isInteger
jsonpath "$.currency" == "COP"

# Lo que todavía no existe: la lista de precios (G1) y las métricas (G6).
GET {{pricing}}/metrics
HTTP 404
```

Desde la Parte II la suite corre **contra el cluster**, en un pod de Hurl dentro de `apps`, con la suite montada desde
un `ConfigMap` y las direcciones de `cluster.env` (el nombre de cada `Service`, sin pasar por la puerta):

```bash
task conformance PROFILE=lab TARGET=cluster -- G13
```

```text
Success /suite/inventory.g13.hurl (15 request(s) in 624 ms)
Executed files:    1
Succeeded files:   1 (100.0%)
```

El pod se borra al terminar, y la tarea sale con el código de Hurl. Sin `PROFILE`, el contexto es el del perfil por
defecto (`kind-minimo`): con el cluster `lab`, `PROFILE=lab`.

---

## 🌊 La matriz de generación

| Paso | Fase | Qué agrega | Servicios | Estado |
|---|---|---|---|---|
| **G0 · Esqueleto** 🌊 | 02 | salud trivial y un endpoint con JSON fijo | los cinco | ✅ prompts y suite |
| **G1 · Almacén propio** 🌊 | 09 | SQLite dentro del pod, lectura y escritura | los cuatro backends; `storefront` lista productos | ✅ prompts y suite |
| **G2 · Configuración en arranque** | 11 | `storefront` lee su configuración al arrancar | `storefront` | ✅ prompt y suite |
| **G3 · Postgres** | 12 | `DATABASE_URL`, migraciones como `Job` | los cuatro backends | ✅ prompts; su suite es la de G1 |
| **G4 · Readiness real** | 15 | la readiness comprueba lo que el servicio necesita | los cuatro backends | ✅ prompts y suite |
| **G5 · El flujo de venta** 🌊 | 16 | la venta completa y el apagado limpio | los cuatro backends y `storefront` | ✅ prompts y suite |
| **G6 · Métricas** | 17 | `/metrics` con las métricas RED | los cuatro backends | ✅ prompts y suite |
| **G7 · Logs estructurados** | 18 | una línea JSON por evento | los cuatro backends | ✅ prompts, suite y verificador |
| **G8 · Cliente mTLS** | 19 | `inventory` presenta certificado a `pricing` | `inventory`, `pricing` | ✅ prompt y suite |
| **G9 · Resiliencia** | 22 | timeouts, reintentos, circuit breaker | `inventory` | ✅ prompt; su prueba es la [Fase 22](22-resiliencia-y-caos.md) |
| **G10 · gRPC y trazas** | 23 | `pricing` sirve gRPC; los cuatro propagan contexto | los cuatro backends | ✅ prompts; su prueba es B-23 y la traza de la venta |
| **G11 · Saga orquestada** | 24 | el préstamo como saga: pasos y compensaciones coordinados por `inventory` | `inventory`, `replenish` | ✅ prompts y suite |
| **G12 · Coreografía** | 25 | el aviso de la venta como evento, por Valkey o por NATS JetStream | `inventory`, `replenish` | ✅ prompts y suite (con el bus encendido) |
| **G13 · Idempotencia y outbox** | 26 | claves de idempotencia, consumidor idempotente y outbox con su publicador como *sidecar* | `inventory`, `replenish` | ✅ prompts y suite |

`pricing` va primero en cada fila: es el piloto, y los otros tres lo siguen.

---

## 🤖 Los prompts de G0

**El patrimonio es insumo.** Cada prompt le pasa al asistente el código del que sale el servicio
([a16](a16-el-patrimonio.md)), para que respete los nombres y los datos de la casa; no para que copie
su arquitectura ni sus mañas.

### El marco común

```markdown
Vas a generar el paso **G0 · Esqueleto** de un servicio del laboratorio de Droguerías La Vecina.
Trabajas dentro de `src/lab/`.

**La fuente de verdad es el contrato, no este texto:** `contracts/openapi/<servicio>.yaml`. Implementa
solo las operaciones con `x-lab-paso: G0`, con la forma exacta de sus esquemas. La suite que decide
si terminaste es `contracts/conformance/<servicio>.g0.hurl`: el paso está hecho cuando pasa contra
compose, y no antes.

**La interfaz de plataforma, igual en todos los backends:**
- Escucha en el puerto de la variable `PORT`, 8080 por defecto.
- `GET /health/live` responde 200 con `{"status":"live"}`. Nunca consulta dependencias.
- `GET /health/ready` responde 200 con `{"status":"ready"}`. En G0 es trivial.
- Escribe una línea de texto por petición a la salida estándar (método, ruta, estado). Texto libre,
  no JSON.
- Cualquier ruta que no esté en G0 responde 404 (o el 405 que el framework dé de serie si la ruta
  existe con otro método).

**Lo que el servicio NO debe tener todavía**, aunque sea fácil o el framework lo traiga de serie:
base de datos ni archivos de datos, llamadas a otros servicios, `/metrics` ni métricas de ningún tipo,
logs en JSON, manejo propio de `SIGTERM`, gRPC, trazas, configuración por archivo, autenticación ni
pruebas automatizadas propias (la prueba es la suite). Si el framework trae algo de esto activado,
desactívalo o bórralo. Una capacidad antes de su paso hace inválido el paso.

**El patrimonio es insumo, no molde:** se te pasa el código del que sale este servicio para que
respetes los nombres y los datos de la casa (códigos `SKU-0003` y `DRO-007`, precios en pesos
enteros). No copies su arquitectura, ni sus mañas, ni su forma de hablar con otros sistemas.

**El Dockerfile de G0 es de una sola etapa**, a propósito: la imagen base del runtime con todo lo
que trae, el build adentro y el proceso corriendo ahí mismo. La Fase 04 lo reescribe; hoy tiene que
funcionar y nada más. La base va por digest, con el tag en un comentario (las de `a01`). Comentarios
en español con tildes; identificadores en inglés.

**Y un `CLAUDE.md` corto** (menos de 150 líneas) en la carpeta del servicio: el stack, los comandos
para construir y correr, las convenciones, y el contrato del servicio con los pasos futuros marcados
como pendientes.

Entregables: el código, el `Dockerfile`, el `.dockerignore` y el `CLAUDE.md`, en
`services/<servicio>/`. Nada fuera de esa carpeta.
```

### G0 · pricing (el piloto)

```markdown
{{marco común}}

**Servicio:** `pricing`, en `services/pricing/`. **Stack:** Go (la versión de a01), solo la biblioteca
estándar, un módulo `lab/pricing` con un `main.go`. **Sale de:** el `PriceService` de Contingencia
(`legacy/contingencia/src/main/java/co/coodrosan/contingencia/soap/PriceService.java`).

**El endpoint de G0:** `GET /prices/{sku}?store={storeId}` devuelve siempre un precio fijo de 12900
COP: `{"sku":"<sku>","store":"<store, o DRO-001 si no viene>","price":12900,"currency":"COP"}`.

**Dockerfile G0:** una etapa sobre `golang` (a01), que compila con `go build` y corre el binario.
```

### G0 · inventory

```markdown
{{marco común}}

**Servicio:** `inventory`, en `services/inventory/`. **Stack:** Spring Boot (la versión de a01) con
Java 25, Maven con su wrapper, solo la dependencia `web` de Initializr (en Spring Boot 4 se llama
`spring-boot-starter-webmvc`); sin su dependencia de pruebas. El puerto, con
`server.port=${PORT:8080}`. Créalo con Spring Initializr
(`groupId` `co.coodrosan.lab`, `artifactId` `inventory`, paquete `co.coodrosan.lab.inventory`).
**Sale de:** el `StockService` de Contingencia y su procedimiento `register_loan`
(`legacy/contingencia/`).

**El endpoint de G0:** `GET /stock/{storeId}/{sku}` devuelve siempre una existencia fija:
`{"store":"<storeId>","sku":"<sku>","quantity":24,"reorderThreshold":8}`.

**La salud es un controlador propio, no Actuator**: Actuator trae métricas y endpoints que no
corresponden a G0, y no se agrega. (La Fase 15 decide cómo remapearlo.)

**Dockerfile G0:** una etapa sobre `eclipse-temurin` 25 JDK (a01), que construye con `./mvnw` y corre
el JAR.
```

### G0 · catalog

```markdown
{{marco común}}

**Servicio:** `catalog`, en `services/catalog/`. **Stack:** PHP (la versión de a01) con Laravel 13,
creado con `composer create-project --no-scripts` (sin `.env` ni `APP_KEY`: G0 no lee configuración
de archivos). Las rutas van en el grupo `api`, que no usa sesión ni cookies, con `apiPrefix: ''`
para que las rutas sean las del contrato, y lo que no existe cae en `Route::fallback` con 404. **Sale de:** el portal (`legacy/portal/`), que tiene su
catálogo propio.

**El endpoint de G0:** `GET /products` devuelve siempre la misma lista de dos productos:
`[{"sku":"SKU-0001","name":"Acetaminofén 500 mg x 10 tabletas","category":"venta libre"},
{"sku":"SKU-0003","name":"Salbutamol inhalador 100 mcg","category":"venta libre"}]`.

**Lo que Laravel trae y G0 no quiere:** la base de datos (ni SQLite: sesiones, caché y colas en
`array` o `file`), las migraciones, las vistas de bienvenida, la ruta `/up`, Vite y las pruebas de
ejemplo. Los logs, a `stderr`.

**Dockerfile G0:** una etapa sobre `php` CLI (a01) con `composer` copiado de su imagen (a01), que
instala las dependencias y corre `php artisan serve` en el puerto 8080. Un solo proceso; los dos
procesos de PHP-FPM con nginx llegan en la Fase 04.
```

### G0 · replenish

```markdown
{{marco común}}

**Servicio:** `replenish`, en `services/replenish/`. **Stack:** Node (la versión de a01) con NestJS
(la versión de a01), creado con su CLI. **Sale de:** la Braqui (`legacy/braqui/`).

**El endpoint de G0:** `GET /replenishment-orders` devuelve siempre la misma lista de una orden:
`[{"id":"RO-0001","sku":"SKU-0003","destinationStore":"DRO-007","originStore":"DRO-003",
"quantity":2,"status":"PENDING"}]`.

**Lo que Nest trae y G0 no quiere:** el controlador y el servicio de ejemplo (`app.controller`,
`app.service`), las pruebas de ejemplo con Vitest y Supertest, `@nestjs/testing`, y los tipos de
Vitest en `tsconfig.json` (si quedan, el build falla con `TS2688`). El log por petición, con un
middleware de una línea en `main.ts`.

**Dockerfile G0:** una etapa sobre `node` (a01), que instala, compila con `npm run build` y corre
`node dist/main.js`.
```

### G0 · storefront

```markdown
{{marco común, sin la parte de backends}}

**Servicio:** `storefront`, en `services/storefront/`. **Stack:** React (la versión de a01) con Vite y
TypeScript, creado con `npm create vite`. No sale del patrimonio: el portal tenía su propia página, y
el storefront la reemplaza.

**Lo de G0:** una página con el título `Droguerías La Vecina`, el lema `Siempre llega` y una línea que
diga que el catálogo llega en la Fase 09. **No llama a ninguna API todavía.** `GET /health/live`
responde 200 (un archivo estático basta).

**Las versiones de la plantilla no son las de a01:** `create-vite` fija versiones anteriores de React
y de Vite; se suben a las de a01 con `npm install`.

**Dockerfile G0:** una etapa sobre `node` (a01), que instala, construye con `npm run build` y sirve
`dist/` con `vite preview` en el puerto de `PORT` y en todas las interfaces, con
`preview.allowedHosts: true` en `vite.config.ts` (sin eso, `vite preview` responde 403 al nombre
`storefront` que le da compose). El nginx sin privilegios llega en la Fase 04.
```

---

## 🤖 Los prompts de G1

G1 le da a cada servicio **su propio almacén**, en SQLite y dentro del contenedor, y sus operaciones
de lectura y escritura, **sin que ningún servicio llame a otro**. El SQLite dentro del pod es una
deuda declarada: la [Fase 12](12-estado-y-almacenamiento.md) la cobra con dos réplicas. Los prompts siguen la forma de G0: un marco
común y uno por servicio, con `pricing` primero.

### El marco común de G1

```markdown
Vas a generar el paso **G1 · Almacén propio** de un servicio del laboratorio de Droguerías La Vecina,
sobre el código de G0 que ya existe en `services/<servicio>/`. Trabajas dentro de `src/lab/`.

**La fuente de verdad es el contrato:** implementa las operaciones con `x-lab-paso: G1` de
`contracts/openapi/<servicio>.yaml`, con la forma exacta de sus esquemas y sus códigos de error. El paso
está hecho cuando `contracts/conformance/<servicio>.g1.hurl` pasa, dos veces seguidas, contra compose
y contra el cluster.

**El almacén:** SQLite, en un archivo dentro de la carpeta de la variable `DATA_DIR` (por defecto
`/var/lib/<servicio>`). Esa carpeta **existe en la imagen y es del usuario que corre el proceso**, o
el primer volumen que se monte ahí nace de `root` y el servicio muere con `Permission denied` (Fase 03).
El esquema se crea al arrancar, con `IF NOT EXISTS`; las migraciones de verdad son de G3. Lo único que
se siembra es la tabla de códigos de razón del servicio, con los códigos que dice el contrato y sin
duplicarlos en cada arranque.

**Los códigos de razón son datos, no un enum del código:** se validan contra su tabla (que el código
exista y esté activo), nunca contra una lista escrita en el programa.

**Lo que el servicio NO debe tener todavía:** llamadas a otros servicios (las URL de los vecinos
llegan como variables y no se usan hasta G5), `/metrics`, logs en JSON, manejo propio de `SIGTERM`,
readiness que consulte la base (G4), Postgres, autenticación ni pruebas propias. La salud y el log
por petición quedan como en G0.

**El Dockerfile** es el multi-stage de la Fase 04: se le agrega la carpeta de `DATA_DIR` con su dueño,
y nada más. Si el driver de SQLite necesita compilar código nativo, cambia de driver: ninguna imagen del
laboratorio tiene un toolchain de C.

**Y el `CLAUDE.md`** del servicio, con G1 marcado como hecho.
```

### G1 · pricing (el piloto)

```markdown
{{marco común de G1}}

**Servicio:** `pricing`. **El driver:** `modernc.org/sqlite`, en Go puro, porque el binario se compila
con `CGO_ENABLED=0` y corre sobre distroless (un driver con cgo no corre ahí). El `go.sum` se genera
dentro de un contenedor de `golang` (a01): no hay Go en el host.

**Las operaciones:** `PUT /prices/{sku}` guarda el precio de una droguería (400 si el precio es
negativo o falta la droguería); `GET /prices/{sku}?store=` lo lee (404 si no hay; sin `store`,
`DRO-001`); `GET /prices?store=` lista los de una droguería (400 sin `store`).

**El tope regulado (D23):** si `REGULATED_CAP_ENABLED=true`, se lee una tabla `SKU,tope` del archivo
de `REGULATED_CAP_FILE` (por defecto `/etc/pricing/regulated-caps.csv`). El precio guardado no cambia:
la respuesta trae `regulatedCap` y, si el precio lo pasa, `price` recortado y `capped: true`. Sin la
variable o sin el archivo, no hay topes. La Fase 11 pone esa tabla en un `ConfigMap`.
```

### G1 · inventory

```markdown
{{marco común de G1}}

**Servicio:** `inventory`. **El acceso a datos:** `spring-boot-starter-jdbc` con `JdbcTemplate` y el
driver `org.xerial:sqlite-jdbc` (la versión la maneja Spring Boot); sin JPA. El esquema en
`schema.sql` y la siembra en `data.sql` con `INSERT OR IGNORE`, con `spring.sql.init.mode=always`, y
**un pool de una conexión**: SQLite escribe de a uno.

**La existencia solo cambia por movimientos (D33)**, y no hay `PUT /stock`. `POST
/stock/{storeId}/{sku}/movements` acepta `RESTOCK` (suma, cantidad positiva), `ADJUSTMENT` (con signo,
exige un `reasonCode` activo que aplique a `ADJUSTMENT`) y `COUNT` (lo contado: la existencia pasa a
ese valor y el movimiento guarda la diferencia con signo). El primer movimiento crea la existencia con
umbral 0. Un ajuste que deja la existencia en negativo es 409; lo demás inválido, 422. `PATCH` cambia
**solo** `reorderThreshold` (cualquier otro campo, 422).
```

### G1 · catalog

```markdown
{{marco común de G1}}

**Servicio:** `catalog`. **El acceso a datos:** el constructor de consultas de Laravel sobre SQLite
(`DB_CONNECTION=sqlite`, la base en `DATA_DIR`), con una migración que crea las tablas y siembra las
categorías y los códigos de razón. **El arranque:** un `start.sh` que crea el archivo de la base,
corre `php artisan migrate --force` y termina con `exec php-fpm`, para que FPM siga siendo el proceso
1 (Fase 03).

**Las operaciones:** `POST /products` (siempre en `ACTIVE`; 409 si el SKU existe; 422 si falta algo o
la categoría no existe), `GET /products/{sku}`, `GET /products?status=` (`ACTIVE` por defecto,
`DISCONTINUED` o `all`), `PATCH /products/{sku}` con `merge-patch` (solo `name`, `category` y `status`;
descontinuar exige un `reasonCode` activo; reactivar lo borra), `GET /categories` y `GET /reason-codes`.
```

### G1 · replenish

```markdown
{{marco común de G1}}

**Servicio:** `replenish`. **El acceso a datos:** el módulo `node:sqlite` que trae Node 24, sin
paquetes nativos (un paquete que compila con node-gyp no entra en la imagen de Alpine sin toolchain).

**Una orden no se edita (D33):** `POST /replenishment-orders` crea (con `originStore` opcional para un
préstamo, y `replacesOrderId` que tiene que ser una orden existente y cancelada, o 422);
`POST /replenishment-orders/{id}/cancel` exige un `reasonCode` activo (422 si no) y solo cancela en
`PENDING` (409 si no). Los identificadores son `RO-0001`, `RO-0002`…
```

### G1 · storefront

```markdown
{{marco común de G1, sin la parte de almacén}}

**Servicio:** `storefront`. **Lo de G1:** la página lista los productos de `catalog`, pidiendo
`GET {API_BASE_URL}/catalog/products` desde el navegador, con un aviso legible si no puede. La dirección
del API se **hornea al compilar** desde `VITE_API_BASE_URL` (un `ARG` del Dockerfile, por defecto
`http://api.localhost:8080`, el host del contrato). Es una decisión deliberada de G1: la Fase 11 la cobra
y G2 la cambia.
```

Lo que la generación de G1 necesitó corregir al pasarla por la suite se cuenta en la
[Fase 09](09-los-cuatro-servicios-dentro.md).


---

## 🤖 El prompt de G2

G2 toca un solo servicio y cambia **cuándo** se decide la configuración, no qué hace la página. Es el
primer paso en que los servicios dejan de avanzar juntos: desde aquí cada imagen lleva el tag del
último paso que la cambió (`STEP_TAGS` en el `Taskfile.yml`), y el `storefront` va en `:g2` mientras
los otros cuatro siguen en `:g1`.

```markdown
Vas a generar el paso **G2 · Configuración en arranque** del `storefront` de Droguerías La Vecina,
sobre el código de G1 que ya existe en `services/storefront/`. Trabajas dentro de `src/lab/`.

**El problema:** en G1, `VITE_API_BASE_URL` se hornea en el JavaScript al compilar. Una imagen sirve
para un solo ambiente, y desplegarla en otro con otra variable no cambia nada.

**Lo que tiene que pasar:** la página pide `/config.json` al cargar y usa lo que trae: `apiBaseUrl`
(la dirección del API) y `brandName` (el nombre visible de la casa, en el título y en el encabezado;
el contrato dice que el nombre de la empresa va en configuración, nunca en un identificador). Nada de
configuración se lee de `import.meta.env`.

**Quién arma `/config.json`:** el nginx de la imagen, al arrancar el contenedor, con las variables
`API_BASE_URL` y `BRAND_NAME`. Usa el mecanismo de plantillas que trae la imagen oficial de nginx
(`/etc/nginx/templates/*.template`, que su entrypoint convierte en `conf.d/` con `envsubst`, y que
solo reemplaza las variables definidas: las de nginx, como `$uri`, quedan intactas). Sin script de
arranque propio. Los valores por defecto van como `ENV` en el Dockerfile: `http://api.localhost:8080`
y `Droguerías La Vecina`.

**La caché, que es donde G2 falla sin que nadie lo note:** `/config.json` con `Cache-Control:
no-store`, e `index.html` con `Cache-Control: no-cache`, para que el navegador revalide la página
después de cada despliegue. Los archivos de `assets/` llevan un hash en el nombre y no necesitan nada.

**Lo que el servicio NO debe tener todavía:** lo mismo que en G1; y no se agrega ruteo del lado del
cliente ni ningún cambio de la página que no sea de dónde sale su configuración.

**El paso está hecho** cuando `contracts/conformance/storefront.g2.hurl` pasa dos veces contra compose
y contra el cluster, y cuando **la misma imagen**, desplegada dos veces con dos `ConfigMap` distintos,
muestra en el navegador dos nombres y dos catálogos. Y el `CLAUDE.md` del servicio, con G2 hecho.
```

Lo que necesitó corregirse al pasarlo por el navegador —la caché de `index.html`, que la primera
versión no tenía— se cuenta en la [Fase 11](11-configuracion-y-secretos.md).

---

## 🤖 Los prompts de G3

G3 lleva los cuatro almacenes a Postgres **sin cambiar ninguna interfaz**: por eso no tiene suite
propia, y el paso está hecho cuando la suite de G1 pasa contra los servicios con Postgres. Lo que sí
cambia es el orden de las cosas: el esquema ya no lo crea cada réplica al arrancar, sino un `Job`, una
sola vez y antes del rollout.

### El marco común de G3

```markdown
Vas a generar el paso **G3 · Postgres** de un servicio del laboratorio de Droguerías La Vecina, sobre
el código de G1 que ya existe en `services/<servicio>/`. Trabajas dentro de `src/lab/`.

**El almacén:** si la variable `DATABASE_URL` existe (con la forma `postgres://usuario:clave@host:puerto/base`,
la del contrato), el servicio usa Postgres; si no, el SQLite de G1 en `DATA_DIR`, que sigue siendo el
de compose. Las consultas se escriben una vez, en el subconjunto que entienden los dos motores
(`ON CONFLICT … DO NOTHING` en lugar de `INSERT OR IGNORE`; `RETURNING` en lugar de pedir el último
identificador); lo único que puede diferir por motor es el DDL de una columna autoincremental.

**Las migraciones:** idempotentes (`CREATE TABLE IF NOT EXISTS`, siembras con `ON CONFLICT`) y
ejecutables **solas**, con un comando del propio servicio que migra y termina sin servir nada. Con
SQLite, el servicio sigue migrando al arrancar, como en G1; **con Postgres, no**: lo hace el `Job`. Un
servicio con Postgres y sin esquema responde 500, y eso es correcto: el orden lo garantiza el despliegue.

**Lo que el servicio NO debe tener todavía:** lo mismo que en G1 (sin llamadas a otros servicios, sin
`/metrics`, sin readiness que consulte la base, que es G4). Y nada de crear bases ni usuarios: eso es de
la plataforma, que le da a cada servicio su base, su usuario y un `Secret` con su `DATABASE_URL`.

**El Dockerfile** solo cambia si el driver de Postgres lo exige (una extensión que compilar).
**Y el `CLAUDE.md`** del servicio, con G3 marcado como hecho y el comando de migración.
```

### G3 · pricing (el piloto)

```markdown
{{marco común de G3}}

**Servicio:** `pricing`. **El driver:** `github.com/jackc/pgx/v5/stdlib` sobre `database/sql`, en Go
puro: el binario sigue siendo estático. El SQLite de G1 se queda para cuando no hay `DATABASE_URL`, y
los parámetros pasan a `$1, $2…`, que entienden los dos. **El comando de migración:** `pricing migrate`.

**Y sus pruebas** (las primeras del laboratorio, para B-12): `main_test.go`, contra el almacén y los
manejadores HTTP con `httptest`, que corren contra SQLite en una carpeta temporal o, con
`TEST_DATABASE=postgres`, contra un Postgres de Testcontainers (`testcontainers-go`, módulo
`postgres`, la imagen de a01), un contenedor por corrida. Entre las pruebas, una que guarda un precio
de 3.000.000.000: el contrato no le pone techo.
```

### G3 · inventory

```markdown
{{marco común de G3}}

**Servicio:** `inventory`. **El acceso a datos:** el mismo `JdbcTemplate`, con un `DataSource` propio
que arma la URL de JDBC desde `DATABASE_URL` (JDBC no entiende `postgres://`) y el driver
`org.postgresql:postgresql` (la versión la maneja Spring Boot). `spring.sql.init` se apaga: el esquema
va en `schema-sqlite.sql` y `schema-postgresql.sql`, la siembra en un `data.sql` común, y los aplica una
clase propia. **El comando de migración:** `java -jar inventory-0.0.1-SNAPSHOT.jar migrate`, sin
servidor web.
```

### G3 · catalog

```markdown
{{marco común de G3}}

**Servicio:** `catalog`. **El acceso a datos:** el mismo constructor de consultas de Laravel; con
`DATABASE_URL`, la conexión por defecto pasa a `pgsql` con esa URL. **El Dockerfile:** la extensión
`pdo_pgsql`, compilada con las cabeceras de libpq, que se borran después (queda `libpq`). **El
arranque:** `start.sh` migra solo si no hay `DATABASE_URL`. **El comando de migración:** `php artisan
migrate --force`.
```

### G3 · replenish

```markdown
{{marco común de G3}}

**Servicio:** `replenish`. **El acceso a datos:** el paquete `pg` (JavaScript puro) para Postgres y el
`node:sqlite` de G1 para SQLite, detrás de una clase con dos métodos asíncronos (`all` y `one`) y las
consultas escritas con `?`, que se numeran para Postgres. Los manejadores pasan a ser `async`. Postgres
devuelve los `BIGINT` como texto: el consecutivo de la orden se convierte antes de formatearlo. **El
comando de migración:** `node dist/migrate.js`.
```

Lo que el paso mostró al correrlo —el `INTEGER` que SQLite no defiende, el servicio que arranca antes
que su esquema, y las dos migraciones a la vez— se cuenta en la [Fase 12](12-estado-y-almacenamiento.md).
---

## 🤖 Los prompts de G4

G4 hace que la readiness diga la verdad: **lista solo si el servicio puede atender**, que en este
sistema quiere decir *su base contesta*. Tiene suite propia (`<servicio>.g4.hurl`), corta: la readiness
dice `ready` con la base arriba y la liveness sigue sin preguntar por nada. El 503 con la base caída lo
provoca la [Fase 15](15-salud-y-recursos.md) a mano.

### El marco común de G4

```markdown
Vas a generar el paso **G4 · Readiness real** de un servicio del laboratorio de Droguerías La Vecina,
sobre el código de G3 que ya existe en `services/<servicio>/`. Trabajas dentro de `src/lab/`.

**La readiness:** `GET /health/ready` responde 200 con `{"status":"ready"}` solo si el servicio puede
atender de verdad: su almacén contesta (Postgres con `DATABASE_URL`, o el SQLite de G1) **en menos de un
segundo**. Si no, 503 con `{"status":"not_ready"}`, y una línea en el log que diga por qué. **No pregunta
por ningún vecino**: si un servicio no está listo porque otro no lo está, una caída se vuelve una cascada.

**La liveness no cambia:** `GET /health/live` responde 200 sin consultar nada. Si el proceso contesta,
está vivo.

**Que nada se cuelgue:** el tiempo para conseguir una conexión a la base baja a dos segundos (el valor
por defecto de varios drivers es de treinta o infinito). Con la base caída, la readiness y cualquier
petición tienen que fallar rápido, no quedarse esperando.

**Lo que el servicio NO debe tener todavía:** llamadas a otros servicios, apagado limpio ante `SIGTERM`
(G5), `/metrics` (G6), logs JSON (G7). Y nada de un framework de salud que cambie la forma de la
respuesta: el contrato pide `{"status":"ready"}`.

**Y el `CLAUDE.md`** del servicio, con G4 marcado como hecho y cómo decide la readiness.
```

### G4 · pricing (el piloto)

```markdown
{{marco común de G4}}

**Servicio:** `pricing`. **La comprobación:** `db.PingContext` con un `context.WithTimeout` de un
segundo, en el manejador de `/health/ready`.
```

### G4 · inventory

```markdown
{{marco común de G4}}

**Servicio:** `inventory`. **Sin Actuator:** Actuator responde `{"status":"UP"}` y el contrato pide
`ready`; el `HealthController` propio se queda. **La comprobación:** el `ApplicationAvailability` de
Spring Boot (que viene sin Actuator) en `ACCEPTING_TRAFFIC`, que llega después de que el servidor abrió el
puerto, y una conexión del `DataSource` que pase `isValid(1)`. **Hikari:** `connectionTimeout` de 2000 ms
en el `StoreConfig`.
```

### G4 · catalog

```markdown
{{marco común de G4}}

**Servicio:** `catalog`. **La comprobación:** `DB::select('select 1')` en un `try`, en la ruta de
`/health/ready`; el fallo va a `error_log`. Llega por nginx y por PHP-FPM, así que también dice que los
dos procesos atienden. **La conexión:** `PDO::ATTR_TIMEOUT => 2` en las opciones de `pgsql` de
`config/database.php`.
```

### G4 · replenish

```markdown
{{marco común de G4}}

**Servicio:** `replenish`. **La comprobación:** un método `ping(ms)` en la clase del almacén, que corre
`select 1` contra una promesa que vence a los `ms` milisegundos (`Promise.race`); con SQLite, la consulta
directa. El controlador responde 503 con `HttpException`. **El pool de `pg`:**
`connectionTimeoutMillis: 2000`, y **un manejador del evento `error` del pool**: cuando la base corta una
conexión que estaba quieta, `pg` emite `error` en el pool, y sin manejador Node lo trata como una
excepción no atendida y el proceso muere.
```

El manejador del pool no estaba en la primera versión del prompt: lo agregó la [Fase 15](15-salud-y-recursos.md), cuando una caída de
Postgres reinició `replenish` sin que ninguna sonda tuviera nada que ver.

---

## 🤖 Los prompts de G5 🌊

G5 es la segunda oleada de dominio: **la venta completa**, y la primera vez que un servicio llama a
otro por trabajo de negocio. Trae además el apagado limpio en los cuatro servicios y cierra la carrera de
`inventory` que dejó abierta la [Fase 12](12-estado-y-almacenamiento.md). Su suite es `inventory.g5.hurl`, que recorre
`pricing`, `inventory` y `replenish`; la de G1 sigue valiendo.

### El marco común de G5

```markdown
Vas a generar el paso **G5 · El flujo de venta** de un servicio del laboratorio de Droguerías La Vecina,
sobre el código de G4 que ya existe en `services/<servicio>/`. Trabajas dentro de `src/lab/`.

**El contrato manda:** la operación `POST /sales` de `contracts/openapi/inventory.yaml` (`x-lab-paso:
G5`), con su descripción completa: el orden de los pasos y qué responde cada fallo.

**El apagado limpio, en los cuatro:** ante `SIGTERM`, el servicio deja de aceptar conexiones nuevas,
termina las que tiene en vuelo y sale con código 0, en menos de 20 s (el pod le da 30). Si el runtime
ya lo hace solo, se dice en el `CLAUDE.md` y no se agrega nada.

**Lo que el servicio NO debe tener todavía:** timeouts, reintentos o circuit breaker propios en las
llamadas a otros servicios (G9: la Fase 22 los extraña a propósito); `/metrics` (G6); logs JSON (G7);
colas o eventos (G12).

**Y el `CLAUDE.md`** del servicio, con G5 marcado como hecho.
```

### G5 · pricing (el piloto)

```markdown
{{marco común de G5}}

**Servicio:** `pricing`. No cambia su contrato: `inventory` le pide `GET /prices/{sku}?store=…`, que ya
existe. **El apagado:** el `http.Server` en su goroutine, `signal.NotifyContext` con `SIGTERM` y
`SIGINT`, y `srv.Shutdown` con un contexto de 20 s; después, cerrar la base.
```

### G5 · inventory

```markdown
{{marco común de G5}}

**Servicio:** `inventory`. **La venta** (`SalesController`): valida el cuerpo; pide el producto a
`catalog` (`GET /products/{sku}`: 404 o `DISCONTINUED` son 422); pide el precio a `pricing` (404 es
422); un vecino que no contesta es 503. Después, en una transacción, la fila de la existencia **bloqueada**
(`SELECT … FOR UPDATE` con Postgres; SQLite no lo entiende y no lo necesita, porque su pool tiene una
conexión), el descuento, la fila en una tabla `sales` nueva (en los dos esquemas, `CREATE TABLE IF NOT
EXISTS`) y un movimiento `SALE` con la venta como referencia. Si la existencia queda por debajo del umbral,
un `POST /replenishment-orders` a `replenish` por la cantidad del umbral, **en un hilo virtual y sin
esperarlo**, con el resultado en el log. Los vecinos, de `CATALOG_URL`, `PRICING_URL` y `REPLENISH_URL`,
con `RestClient.builder()`: en Spring Boot 4 el `RestClient.Builder` autoconfigurado vive en otro módulo.

**La carrera de la Fase 12**, en los movimientos: el primer movimiento crea la fila con `INSERT … ON
CONFLICT DO NOTHING`, y la fila se bloquea antes de leerla; si el movimiento no procede, la transacción
se marca para deshacer (que no quede una existencia en 0 creada por un ajuste rechazado).

**El apagado:** `server.shutdown=graceful` y `spring.lifecycle.timeout-per-shutdown-phase=20s`.
```

### G5 · catalog y replenish

```markdown
{{marco común de G5}}

**`catalog`:** su contrato no cambia (`inventory` le pide `GET /products/{sku}`). **El apagado:** la imagen
de PHP-FPM y la de nginx traen `STOPSIGNAL SIGQUIT`, y los dos atienden `SIGQUIT` terminando lo que
tienen; `start.sh` ya termina con `exec php-fpm`. No se agrega nada: se comprueba y se anota.

**`replenish`:** su contrato no cambia (`inventory` le pide `POST /replenishment-orders`). **El apagado:**
`app.enableShutdownHooks(['SIGTERM', 'SIGINT'])` en `main.ts`: Nest cierra el servidor y llama a
`onModuleDestroy`, que cierra el pool.
```

### G5 · storefront

```markdown
{{marco común de G5}}

**Servicio:** `storefront`. **La venta desde la página:** la droguería sale de la dirección (`?store=`,
`DRO-007` por defecto); la página pide los precios de esa droguería a `pricing` (`GET
{apiBaseUrl}/pricing/prices?store=…`; si fallan, lista el catálogo sin precios) y pone un botón por
producto, con `data-sku`, que hace `POST {apiBaseUrl}/inventory/sales` con una unidad y muestra el
resultado o el mensaje del error en un párrafo `.resultado`. Los dos pedidos son de otro origen: la
puerta tiene que autorizar `GET` en la ruta de `pricing` y `POST` con `Content-Type` en la de `inventory`
(el navegador pregunta antes con un `OPTIONS`). **El apagado:** nginx con `STOPSIGNAL SIGQUIT`, de serie.
```

El paso pasó la suite al primer intento. Lo que mostró al correrlo —el aviso que no espera, el apagado
que no alcanza sin `preStop`, la carrera cerrada— se cuenta en la [Fase 16](16-escalado-y-rollout.md).

---

## 🤖 Los prompts de G6

G6 hace que cada backend diga cuánto trabaja, cuánto falla y cuánto tarda: **`/metrics` en el formato de
Prometheus**, con un histograma que es igual en los cuatro para que un solo tablero los lea. Su suite es
`<servicio>.g6.hurl`: el endpoint existe, trae el histograma y cuenta la petición de recién con el
patrón de su ruta. La suite de G4 deja de pasar con estas imágenes, como toda suite de un paso anterior:
pedía un 404 en `/metrics`.

### El marco común de G6

```markdown
Vas a generar el paso **G6 · Métricas** de un servicio del laboratorio de Droguerías La Vecina, sobre el
código de G5 que ya existe en `services/<servicio>/`. Trabajas dentro de `src/lab/`.

**El contrato manda:** la operación `GET /metrics` del OpenAPI del servicio, con su descripción. En
resumen: el formato de texto de Prometheus, con un histograma `http_server_requests_seconds` (en
segundos) y las etiquetas `method`, `uri` y `status`. Cada servicio puede sumar las suyas.

**La etiqueta `uri` es el patrón de la ruta, nunca la ruta cruda:** `/prices/{sku}`, no
`/prices/SKU-0001`. Con la cruda habría una serie por producto. Lo que no cae en ninguna ruta se cuenta
junto, como `/**`. El patrón se lee **después** de que el framework eligió la ruta, no antes.

**La librería es la oficial del runtime**, o la que el framework trae; nada de escribir el formato a mano.
Las métricas del proceso que la librería da de serie, se dejan.

**Lo que el servicio NO debe tener todavía:** logs JSON (G7), trazas o propagación de contexto (G10),
alertas de ningún tipo. Y nada de Actuator, consola de administración ni endpoint de depuración que
venga de regalo con la librería: solo `/metrics`.

**Y el `CLAUDE.md`** del servicio, con G6 marcado como hecho.
```

### G6 · pricing (el piloto)

```markdown
{{marco común de G6}}

**Servicio:** `pricing`. **La librería:** `github.com/prometheus/client_golang`. **El middleware:** el
mismo envoltorio que ya escribe la línea de log mide el tiempo y, después de `mux.ServeHTTP`, toma el
patrón de `r.Pattern` (`"GET /prices/{sku}"` → `/prices/{sku}`; el `ServeMux` lo deja en la petición
al elegir la ruta). `/metrics` es `promhttp.Handler()` en el mismo mux.
```

### G6 · inventory

```markdown
{{marco común de G6}}

**Servicio:** `inventory`. **Actuator, pero solo para esto:** `spring-boot-starter-actuator` y
`micrometer-registry-prometheus`, con `management.endpoints.web.base-path=/`,
`management.endpoints.web.exposure.include=prometheus` y
`management.endpoints.web.path-mapping.prometheus=metrics`. La salud sigue siendo el `HealthController`
de G4. **El histograma:** `management.metrics.distribution.percentiles-histogram.http.server.requests=true`
(sin eso, Micrometer publica un resumen sin buckets). **La métrica de negocio:** un `Counter` `lab.sales`
que `SalesController` incrementa con cada venta registrada.
```

### G6 · catalog

```markdown
{{marco común de G6}}

**Servicio:** `catalog`. **La librería:** `promphp/prometheus_client_php`, **con APCu**: en PHP-FPM
nada sobrevive a una petición, así que los contadores tienen que vivir en la memoria compartida de los
hijos de FPM. APCu no viene con la imagen de PHP: `pecl install apcu-<versión>` y
`docker-php-ext-enable apcu`, en la misma capa que compila `pdo_pgsql`. **El middleware:**
`MeasureRequest`, agregado después de `LogRequest`, con `$request->route()->uri()`; la ruta de reserva
(`isFallback`) es `/**`. `/metrics` es una ruta más, que responde con `RenderTextFormat`.
```

### G6 · replenish

```markdown
{{marco común de G6}}

**Servicio:** `replenish`. **La librería:** `@prometheus-io/client`, la heredera oficial de
`prom-client` (que quedó deprecado), con `collectDefaultMetrics()`. **El middleware:** en `main.ts`,
uno que arranca el temporizador y, en el evento `finish` de la respuesta, toma `req.baseUrl +
req.route.path` y cambia `:id` por `{id}`. `/metrics` es un controlador de Nest que responde con
`register.contentType`.
```

Los cuatro pasaron la suite al primer intento; dos cosas salieron al construirlos. `prom-client`, la
librería que el prompt nombraba al principio, se instaló con un aviso de deprecación, y el prompt pasó a
la heredera. Y en `catalog`, el almacenamiento en memoria del proceso pasaba la suite pero no contaba nada:
la [Fase 17](17-metricas-y-dashboards.md) lo mide.

---

## 🤖 Los prompts de G7

G7 no cambia ninguna respuesta: cambia **el log**. Cada servicio escribe una línea JSON por evento a
stdout, con los mismos campos, y la línea de cada petición lleva el `request_id` que trae `X-Request-Id`.
Hurl no ve el log, así que la suite tiene dos mitades: `<servicio>.g7.hurl` hace peticiones con un
`X-Request-Id` conocido, y `scripts/conformance/logs.py` (que `task conformance TARGET=cluster -- G7`
corre después) lee el log de los cuatro y comprueba el contrato.

### El marco común de G7

```markdown
Vas a generar el paso **G7 · Logs estructurados** de un servicio del laboratorio de Droguerías La Vecina,
sobre el código de G6 que ya existe en `services/<servicio>/`. Trabajas dentro de `src/lab/`.

**El contrato del log:** cada línea que el servicio escribe es **un objeto JSON**, a stdout (o stderr, si el
runtime no deja otra cosa), con cuatro campos siempre: `time` (RFC 3339), `level` (`DEBUG`, `INFO`,
`WARN` o `ERROR`), `service` (el nombre del servicio) y `msg`. Lo demás va en campos propios, nunca
dentro del texto de `msg`.

**La línea de cada petición:** `msg` es `request`, con `method`, `uri` (el mismo patrón de ruta que la
etiqueta de G6), `path` (la ruta cruda: aquí sí va, porque un log no tiene el problema de las series),
`status` (número), `duration_ms` (número) y `request_id`.

**El `request_id`:** el valor de la cabecera `X-Request-Id`, o uno nuevo si no vino. Cualquier otra línea
que se escriba durante la petición lo lleva también, si el runtime tiene cómo (un contexto, un MDC).

**Nada en texto:** ni el banner del framework, ni los avisos de arranque, ni los colores de la consola. Si
algo del runtime no se puede callar, se dice en el `CLAUDE.md`.

**Lo que el servicio NO debe tener todavía:** trazas ni `traceparent` (G10): el `request_id` es la
correlación pobre, a propósito. Y ningún archivo de log dentro del contenedor.

**Y el `CLAUDE.md`** del servicio, con G7 marcado como hecho.
```

### G7 · pricing (el piloto)

```markdown
{{marco común de G7}}

**Servicio:** `pricing`. **`log/slog`** con `slog.NewJSONHandler(os.Stdout, nil)`, `With("service",
"pricing")` y `slog.SetDefault`: con eso, los `log.Printf` que ya existen salen en JSON con nivel `INFO`.
Los avisos de la readiness, con `slog.Warn`. La línea de la petición, en el middleware que ya mide.
```

### G7 · inventory

```markdown
{{marco común de G7}}

**Servicio:** `inventory`. **El logging estructurado de Spring Boot** en formato `logstash`, ajustado con
propiedades: `logging.structured.json.rename[@timestamp]=time` (con corchetes: la clave lleva `@`),
`rename.message=msg`, `exclude` de `@version`, `level_value`, `thread_name`, `logger_name` y `tags`, y
`add.service=inventory`; `spring.main.banner-mode=off`. **La petición:** `RequestLogFilter` pone el
`request_id` en el MDC y escribe la línea con la API fluida de SLF4J (`atInfo().addKeyValue(…)`); el patrón
sale de `HandlerMapping.BEST_MATCHING_PATTERN_ATTRIBUTE`. **Los vecinos:** cada `RestClient` lleva un
interceptor que copia el `request_id` del MDC a `X-Request-Id`; el hilo virtual del aviso lo copia a mano,
porque no hereda el MDC. **La JVM:** `--enable-native-access=ALL-UNNAMED` en el `CMD`, para que la carga de
sqlite-jdbc no avise en texto.
```

### G7 · catalog

```markdown
{{marco común de G7}}

**Servicio:** `catalog`. **Monolog**, con un formateador propio (`App\Logging\JsonLineFormatter`, que
extiende `NormalizerFormatter`) puesto en `LOG_STDERR_FORMATTER`: el `JsonFormatter` de Monolog usa
otros nombres y anida el contexto. **La petición:** `LogRequest` usa `Log::withContext` para el
`request_id`. **PHP-FPM:** sin su línea de acceso (`access.log = /dev/null`) y con `log_level = warning`.
**nginx:** su línea de acceso en JSON (`log_format … escape=json`, `msg` `nginx`, con el `request_id` de
la cabecera) y un `nginx.conf` principal propio, con `error_log /dev/stderr warn`; y
`NGINX_ENTRYPOINT_QUIET_LOGS=1` en el contenedor.
```

### G7 · replenish

```markdown
{{marco común de G7}}

**Servicio:** `replenish`. **Un `LoggerService` propio** (`src/logger.ts`) que escribe una línea JSON por
llamada, pasado a `NestFactory.create(AppModule, { logger })`: así salen en JSON también los mensajes del
arranque de Nest, que por defecto son texto con colores. La línea de la petición, en un middleware
(`logRequests`) que reemplaza al de texto.
```

Los cuatro pasaron la suite; lo que costó estuvo fuera del código de cada servicio: la clave con `@` de
Spring, los 22 avisos de arranque de nginx, y una línea de la JVM que no se puede callar cuando el chart le pasa
`JAVA_TOOL_OPTIONS` (`Picked up JAVA_TOOL_OPTIONS: …`, que el verificador acepta como única excepción). La [Fase 18](18-logs.md) lo cuenta.

---

## 🤖 El prompt de G8

G8 es el primer paso que solo toca a dos servicios: **`inventory` le habla a `pricing` con TLS mutuo**. Los
certificados no los genera el servicio: los emite cert-manager y los monta el pod, y la CA la reparte
trust-manager ([Fase 19](19-tls-y-certificados.md)). Su suite es `inventory.g8.hurl`: una venta que solo pasa si el saludo TLS pasa.
Que sin certificado no se entre lo prueba la fase a mano.

```markdown
Vas a generar el paso **G8 · Cliente mTLS** del laboratorio de Droguerías La Vecina, en `pricing` y en
`inventory`, sobre el código de G7 que ya existe. Trabajas dentro de `src/lab/`.

**`pricing`, el servidor.** Un segundo listener en el 8443 con TLS que **exige** certificado de cliente firmado
por la CA del laboratorio (`RequireAndVerifyClientCert`), con el mismo manejador del 8080, que no cambia: la
puerta, las sondas y Prometheus siguen en HTTP. Los archivos llegan por variables: `TLS_CERT_FILE`,
`TLS_KEY_FILE` y `TLS_CLIENT_CA_FILE`; si falta alguna, no hay 8443 (como hasta G7). **El certificado del
servidor se relee cuando el archivo cambia** (cert-manager lo renueva y el kubelet actualiza el archivo
montado): `GetCertificate` que compara la fecha del archivo. Los saludos fallidos van al log como advertencia,
en JSON. El apagado limpio cierra los dos servidores. En un archivo aparte, `tls.go`.

**`inventory`, el cliente.** Si `PRICING_URL` empieza con `https://`, el cliente de `pricing` usa el *SSL bundle*
`pricing` de Spring Boot (`spring.ssl.bundle.pem.pricing.*`: el certificado y la clave de cliente, y la CA como
`truststore`; con `reload-on-update`), con un `JdkClientHttpRequestFactory` sobre un `HttpClient` armado con el
`SSLContext` del bundle (el `RestClient.Builder` autoconfigurado vive en un módulo que el servicio no trae). Un
`addBundleUpdateHandler` rearma el cliente cuando el bundle cambia. Si `PRICING_URL` es `http://`, todo sigue
como en G7.

**Lo que NO debe tener todavía:** timeouts, reintentos ni circuit breaker (G9); ningún certificado dentro de la
imagen; ninguna verificación del nombre del cliente más allá de la CA (es un ejercicio).

**Y el `CLAUDE.md`** de los dos, con G8 marcado como hecho.
```

Pasó la suite al primer intento. Lo que costó estuvo en el chart (los `Certificate`, los montajes sin `subPath`,
el interruptor `global.mtls.enabled` y la dirección mTLS de `pricing`, que va solo en el `Deployment` de `inventory`:
en el `ConfigMap` de vecinos rompió el seed, que también la lee), y en una trampa del kubelet que la fase cuenta en
su sección 5.7.

---

## 🤖 El prompt de G9, y el del generador de caos

G9 no tiene suite propia: lo que promete se ve con un vecino en problemas, y eso lo pone el **generador de caos**
de la [Fase 22](22-resiliencia-y-caos.md), que se genera igual que los servicios. Las suites de G5 y G8 siguen valiendo con `inventory:g9`.

### El generador de caos

```markdown
Vas a generar el **generador de caos** del laboratorio de Droguerías La Vecina, en `src/lab/chaos/`. Es código
propio, en Go, corto y legible: el lector lo va a leer de una sentada.

**Qué es:** un proxy inverso (`httputil.ReverseProxy`) hacia `CHAOS_UPSTREAM`, que a cada petición le sortea, en
este orden: colgarse (no contestar hasta que el cliente se canse), fallar (un 503 con JSON, sin pasarle nada al
vecino), demorar (esperar y después pasar), y romper la respuesta (un 200 con JSON cortado). Los porcentajes y la
demora en un objeto `faults`, que se lee de `CHAOS_FAULTS` al arrancar y se cambia en caliente con `PUT /chaos`; `GET
/chaos` devuelve la configuración y las cuentas (recibidas, pasadas, demoradas, fallidas, rotas, colgadas).
`/health/live` y `/health/ready` triviales. Log en JSON como G7. Apagado limpio como G5.

**Lo que NO debe tener:** dependencias fuera de la biblioteca estándar, TLS, ni nada que no sean esas cuatro fallas.

**El Dockerfile** con el mismo molde que `pricing` (distroless, usuario 65532).
```

### G9 · inventory

```markdown
Vas a generar el paso **G9 · Resiliencia** en `inventory`, sobre el código de G8. Trabajas dentro de `src/lab/`.

**Timeouts, en todos los clientes de los vecinos:** conectar en 1 s y esperar la respuesta 2 s (variables
`LAB_RESILIENCE_CONNECT_TIMEOUT_MS` y `LAB_RESILIENCE_READ_TIMEOUT_MS`), en el `HttpClient` del JDK con
`JdkClientHttpRequestFactory.setReadTimeout`; también en el de `pricing` con mTLS.

**Reintentos y circuit breaker, solo para las lecturas (`catalog` y `pricing`),** con el núcleo de Resilience4j
(`resilience4j-circuitbreaker`, `resilience4j-retry` y `resilience4j-micrometer`, sin la integración con Spring), en
una clase `Guard` con un método `call(vecino, supplier)`: reintentos (3 intentos, espera exponencial al azar desde
100 ms) solo ante `RestClientException` que no sea un 4xx; un circuito por vecino (50 % de fallas en las últimas 20,
con al menos 10; abierto 10 s; 3 llamadas de prueba). Con el circuito abierto, la venta responde 503 con
`<vecino> no disponible (circuito abierto)`. Todo ajustable con `lab.resilience.*`, para que la Fase 22 pueda medir la
versión ingenua (más intentos, sin espera, sin circuito). Las métricas de los dos, en `/metrics`.

**El aviso a `replenish` (un `POST`) lleva timeout y NO reintentos**: reintentarlo puede pedir dos reposiciones.

**Lo que NO debe tener todavía:** idempotencia (G13), colas (G12), *bulkheads* ni límites de tasa.

**Y el `CLAUDE.md`**, con G9 marcado como hecho.
```

Los dos salieron funcionando; lo que costó estuvo en el chart (el subchart `chaos`, el interruptor
`global.chaos.enabled` y la variable `CATALOG_URL` de `inventory` apuntando al generador) y en la medición: la [Fase 22](22-resiliencia-y-caos.md)
cuenta por qué la configuración por defecto del circuito es agresiva para un vecino degradado.

---

## 🤖 Los prompts de G10

G10 tiene dos mitades. **gRPC**: `pricing` sirve el precio también por gRPC, con el contrato en
`contracts/proto/pricing/v1/pricing.proto`, e `inventory` lo pide por ahí en la venta. **Trazas**: los cuatro abren
spans y propagan el `traceparent` (W3C Trace Context) con OpenTelemetry, y los mandan a Tempo. La prueba de la
primera es B-23 y la suite de G8, que con gRPC encendido pasa por el 9090; la de la segunda, una venta que aparece
en Tempo como una sola traza con los cuatro servicios ([Fase 23](23-grpc-y-el-balanceo.md)).

### El marco común de G10

```markdown
Vas a generar el paso **G10 · gRPC y trazas** de un servicio del laboratorio de Droguerías La Vecina, sobre el
código del paso anterior. Trabajas dentro de `src/lab/`.

**Las trazas, en los cuatro:** OpenTelemetry con las variables estándar (`OTEL_SERVICE_NAME`,
`OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf`, `OTEL_TRACES_EXPORTER=otlp`, métricas y
logs de OpenTelemetry en `none`), el propagador W3C, un span por petición HTTP que entra y por llamada que sale, y la
base de datos donde la instrumentación la dé. Sin `OTEL_EXPORTER_OTLP_ENDPOINT`, o con `OTEL_SDK_DISABLED=true`, nada
se exporta y nada falla. La forma de instrumentar es **la idiomática de cada runtime**, y el prompt de cada uno la dice.

**Lo que NO debe tener:** métricas ni logs por OpenTelemetry (ya tienen su camino), muestreo propio, ni ningún
`X-Request-Id` quitado: sigue conviviendo con el `traceparent`.

**Y el `CLAUDE.md`** del servicio, con G10 marcado como hecho.
```

### G10 · pricing (el piloto)

```markdown
{{marco común de G10}}

**Servicio:** `pricing`. **gRPC:** el código de Go del `.proto` se genera con `task proto` y se versiona
(`pricingv1/`); un servidor en el 9090 (`grpc.go`) con el **mismo `tls.Config` del 8443** (mTLS, con el certificado
que se relee), un interceptor que cuenta cada llamada en `grpc_server_requests_total{method,code}` y escribe la
línea `request` de G7 con el `x-request-id` de los metadatos, `GracefulStop` en el apagado y, si
`GRPC_MAX_CONNECTION_AGE` trae una duración, esa edad máxima por conexión (con 5 s de gracia). **Trazas:** el SDK
(`otel.go`) con el exportador OTLP/HTTP, `otelhttp` envolviendo el manejador (con el nombre del span por el patrón de
la ruta) y `otelgrpc` como `StatsHandler` del servidor; el `trace_id` en la línea `request`.
```

### G10 · inventory

```markdown
{{marco común de G10}}

**Servicio:** `inventory`. **gRPC:** el código de Java se genera al compilar (`protobuf-maven-plugin` con el protoc y
el `protoc-gen-grpc-java` de Maven Central), con el `.proto` llegando por un contexto de build aparte
(`--build-context proto=contracts/proto`). Un `PricingGrpc` con `grpc-netty-shaded`: el canal con el `SslContext`
armado desde el **mismo *SSL bundle* `pricing` de G8** (y rearmado cuando se renueva), la política de balanceo y el
destino de `PRICING_GRPC_POLICY` y `PRICING_GRPC_TARGET`, el `x-request-id` del MDC en los metadatos, y el plazo de G9
en cada llamada. Si `PRICING_GRPC_TARGET` no está, el precio sigue por HTTP. `Guard` reintenta y cuenta como falla
`UNAVAILABLE` y `DEADLINE_EXCEEDED`; `NOT_FOUND` es un 422. **Trazas:** el agente de OpenTelemetry para Java,
descargado en el Dockerfile con su suma (`ADD --checksum --chmod=644`) y cargado con `-javaagent`; se apaga con
`OTEL_JAVAAGENT_ENABLED=false`. El hilo del aviso a `replenish` recibe el contexto con `Context.current().wrap(...)`
(`opentelemetry-api`, la versión de Spring Boot): un hilo nuevo no lo hereda, y sin eso el aviso es otra traza.
```

### G10 · catalog

```markdown
{{marco común de G10}}

**Servicio:** `catalog`. **La extensión `opentelemetry` de PECL** (en la misma capa que APCu) y los paquetes
`open-telemetry/sdk`, `open-telemetry/exporter-otlp` y `open-telemetry/opentelemetry-auto-laravel`, con los
*plugins* de Composer que piden (`php-http/discovery`, `tbachert/spi`) permitidos. `OTEL_PHP_AUTOLOAD_ENABLED=true`
para que el SDK se cargue en cada petición.
```

### G10 · replenish

```markdown
{{marco común de G10}}

**Servicio:** `replenish`. **`@opentelemetry/auto-instrumentations-node`**, cargado antes que la aplicación con
`node --import @opentelemetry/auto-instrumentations-node/register`, y `OTEL_NODE_ENABLED_INSTRUMENTATIONS` con las que
importan (`http`, `express`, `nestjs-core`, `pg`): las demás llenan la traza de ruido.
```

---

## 🤖 Los prompts de G11

G11 trae el préstamo entre droguerías como **saga orquestada**: `inventory` coordina tres pasos —reservar en la vecina,
despachar la moto con `replenish` y cobrar en el destino— y, si uno falla, deshace los anteriores con operaciones de
negocio. El contrato de `POST /loans` dice el orden y la compensación de cada paso, y su suite es `inventory.g11.hurl`:
el préstamo que sale bien, el pendiente (la vecina no tiene) y el que se compensa porque el destino no tiene precio. Lo
que la suite no puede provocar —el vecino lento, el orquestador que muere— lo pone el generador de caos de la
[Fase 24](24-la-saga-orquestada.md).

### G11 · inventory

```markdown
Vas a generar el paso **G11 · Saga orquestada** en `inventory`, sobre el código de G10. Trabajas dentro de `src/lab/`.

**El contrato manda:** `POST /loans` y `GET /loans/{loanId}` de `contracts/openapi/inventory.yaml` (`x-lab-paso: G11`),
con la descripción completa de los pasos, sus compensaciones y los estados. La suite es
`contracts/conformance/inventory.g11.hurl`.

**El orquestador** es una clase `LoanSaga`, y su estado vive en la base de `inventory`, nunca en memoria: una tabla
`loans` (el préstamo y su estado) y una `loan_steps` (una fila por cada paso hecho o deshecho, con `action` DO o UNDO y
`outcome` OK o FAILED), en los dos esquemas. `POST /loans` valida (origen distinto del destino), guarda el préstamo en
`STARTED`, arranca la saga en un **hilo virtual** con el contexto de OpenTelemetry envuelto (`Context.current().wrap`,
como el aviso de G10) y el `request_id` copiado al MDC, y contesta 202 sin esperarla.

**Los pasos**, cada uno en su propia transacción local o en una sola llamada:
- `RESERVE`: con la fila del origen bloqueada (`findForUpdate`), un movimiento `LOAN_OUT`; sin existencia suficiente,
  `BACKORDERED` con el motivo, un log de aviso al cliente, y nada que compensar.
- `DISPATCH`: `POST /replenishment-orders` con `originStore`, con el cliente de `replenish` de G5 (timeouts de G9, **sin
  reintentos**). Cualquier excepción es una falla del paso.
- `CHARGE`: el precio del destino con el mismo camino que la venta (extrae de `SalesController` un `priceFor(sku, store)`
  y un `insertSale(...)`) y una fila en `sales` del destino, **sin** movimiento `SALE`.
- `RECEIVE`: la existencia del destino (créala si no existe, como el primer `RESTOCK`) y un `LOAN_IN`; `COMPLETED`.

**Las compensaciones**, cuando un paso falla: el préstamo pasa a `COMPENSATING` con el motivo en `failure`, y se deshacen
en orden inverso los pasos hechos que todavía no se deshicieron (`RESERVE` con un `ADJUSTMENT` positivo y el código
`LOAN_RELEASED`, sembrado en `data.sql`; `DISPATCH` con `POST /replenishment-orders/{id}/cancel` y `SAGA_COMPENSATION`).
Si una compensación falla, queda anotada y el préstamo sigue en `COMPENSATING`. Con todas hechas, `COMPENSATED`.

**El barrido:** `@Scheduled` cada `lab.saga.sweep-ms` (30 s) busca préstamos sin estado final cuya `updated_at` sea más
vieja que `lab.saga.stale-ms` (30 s). Los reclama con un `UPDATE … WHERE id = ? AND updated_at = ?` (si no actualiza
ninguna fila, otra réplica lo tomó). Antes del cobro (`STARTED`, `RESERVED`, `DISPATCHED`) los pasa a `COMPENSATING`; con
el cobro hecho (`CHARGED`), los termina; en `COMPENSATING`, sigue. `updated_at` con milisegundos fijos, porque se
compara como texto.

**Las trazas:** un span `saga DO <paso>` o `saga UNDO <paso>` por cada paso, con `loan.id`, y estado de error cuando
falla; el barrido abre un span raíz propio, `saga sweep`. **Las métricas:** `lab.loans` por estado final.

**Lo que NO debe tener todavía:** reintentos en el `DISPATCH` ni clave de idempotencia (G13), eventos ni colas (G12), ni
un motor de sagas o de flujos de trabajo: el orquestador se escribe a mano para que se vea.

**Y el `CLAUDE.md`**, con G11 marcado como hecho.
```

### G11 · replenish

```markdown
Vas a generar el paso **G11 · Saga orquestada** en `replenish`, sobre el código de G10. Trabajas dentro de `src/lab/`.

**Solo datos:** el código de razón `SAGA_COMPENSATION` en la siembra de `reason_codes` (`'Compensación de una saga: un
paso posterior falló'`). La cancelación es la de G1 y no cambia: solo en `PENDING`, 409 si la orden ya salió.

**Y el `CLAUDE.md`**, con G11 marcado como hecho.
```

Los dos pasaron la suite al primer intento. Lo que mostró el laboratorio —la orden que se crea después de que la saga la
dio por fallida, el `preStop` que salvó una saga, el barrido de dos réplicas— está en la
[Fase 24](24-la-saga-orquestada.md). Y una consecuencia de método: desde G11 la suite de G1 falla en `replenish` (cuenta
cuatro códigos de razón y hay cinco), igual que falla desde G6 en las tres rutas `/metrics` que pedía en 404. **La suite
de un paso valida ese paso cuando se genera, no después**; la que se corre en cada tanda es la del último paso de cada
servicio y las que no comprueban ausencias (G5, G7, G8).

---

## 🤖 Los prompts de G12

G12 cambia **cómo** viaja el aviso de reposición de la venta: en vez del `POST` que `inventory` hacía sin esperar (G5),
un evento, `lab.inventory.stock-low`, que `inventory` publica sin saber quién escucha y que `replenish` consume. El
evento está en el contrato de `inventory` (`x-lab-events`, con su esquema `StockLowEvent`), y la orden de `replenish`
gana `sourceEventId`. Hay dos buses, con el mismo código detrás de un interruptor (`EVENT_BUS`): Valkey pub/sub, que
la [Fase 25](25-la-coreografia.md) usa para romper, y NATS JetStream, que usa para arreglar. Su suite,
`inventory.g12.hurl`, solo aplica con un bus encendido (`task bus:on`).

### El marco común de G12

```markdown
Vas a generar el paso **G12 · Coreografía** de un servicio del laboratorio de Droguerías La Vecina, sobre el código del
paso anterior. Trabajas dentro de `src/lab/`.

**El contrato manda:** el evento `lab.inventory.stock-low` de `x-lab-events` en `contracts/openapi/inventory.yaml`, con su
esquema `StockLowEvent` (un `eventId` nuevo por evento), y `sourceEventId` en la orden de `replenish.yaml`.

**El interruptor:** `EVENT_BUS=valkey` (con `VALKEY_URL`) o `EVENT_BUS=nats` (con `NATS_URL`). Sin `EVENT_BUS`, nada
cambia: el aviso sigue siendo el `POST` de G5. El nombre del canal de Valkey y el sujeto de NATS son el mismo. Con NATS,
el stream `LAB_EVENTS` (sujetos `lab.>`, en disco, 24 h) lo asegura quien llegue primero, con la misma configuración.

**Lo que NO debe tener todavía:** idempotencia (ni `Nats-Msg-Id`, ni una restricción única sobre el evento), outbox,
reintentos propios al publicar (G13). El bus no entra en la readiness (G4): un vecino nunca la decide.

**Y el `CLAUDE.md`** del servicio, con G12 marcado como hecho.
```

### G12 · inventory

```markdown
{{marco común de G12}}

**Servicio:** `inventory`. Una clase `EventBus` con `publishStockLow(saleId, store, sku, quantity)` que devuelve qué pasó,
para el log: con Valkey (`io.valkey:valkey-java`, `JedisPooled`), `PUBLISH` y **a cuántos suscriptores llegó**; con NATS
(`io.nats:jnats`, conexión con `Nats.connectReconnectOnConnect` y reintentos sin fin), `jetStream.publish` y el número
de secuencia del ack. La venta lo llama **en el mismo hilo virtual del aviso** de G5, después de confirmar la venta; si
el bus falla, la venta sigue hecha y el log dice `aviso perdido`. El JSON del evento, armado a mano (los campos son
identificadores sin comillas que escapar).
```

### G12 · replenish

```markdown
{{marco común de G12}}

**Servicio:** `replenish`. Un proveedor `Events` (`src/events.ts`) que al arrancar la aplicación se suscribe según
`EVENT_BUS`: con Valkey (`iovalkey`; el `import` con nombre, `{ Valkey }`), `SUBSCRIBE` al canal y un manejador de
`message`; con NATS (`@nats-io/transport-node` y `@nats-io/jetstream`), el consumidor durable `replenish-stock-low`
(ack explícito, `ack_wait` de 30 s, filtro por el sujeto) y un `consume()` que crea la orden y **después** hace `ack`;
si falla, `nak` con 5 s. La orden se crea con el mismo `INSERT` del controlador más `source_event_id`, una columna nueva
(con `ADD COLUMN IF NOT EXISTS` en Postgres; en SQLite, un `ALTER` que puede fallar si ya existe). El log de cada orden
creada lleva `eventId`, `saleId` y el número de entrega (`deliveryCount`). Cierre: `close` de los mensajes, `drain` de
la conexión.
```

Los dos compilaron al primer intento salvo por el `import` de `iovalkey` (agregado al prompt). Lo que mostró el
laboratorio —el aviso publicado a cero suscriptores, y las órdenes repetidas con dos suscriptores— está en la
[Fase 25](25-la-coreografia.md).

---

## 🤖 Los prompts de G13

G13 paga la factura de la Parte IV: lo que llega dos veces y lo que se escribe en dos sitios. Tres piezas. **Claves de
idempotencia** en las tres operaciones que alguien puede reintentar (`POST /sales`, `POST /loans`, `POST
/replenishment-orders`): la misma clave con el mismo cuerpo devuelve lo ya hecho. **Un consumidor idempotente** en
`replenish`: cada `eventId` se procesa una vez. **Un outbox** en `inventory`: el evento se escribe en la misma transacción
que la venta, y un proceso aparte lo publica. Su suite es `inventory.g13.hurl`, con claves nuevas en cada corrida
(`{{newUuid}}`); la prueba de lo demás —el pod que muere en el peor momento— está en la
[Fase 26](26-idempotencia-y-outbox.md).

### G13 · inventory

```markdown
Vas a generar el paso **G13 · Idempotencia y outbox** en `inventory`, sobre el código de G12. Trabajas dentro de `src/lab/`.

**El contrato manda:** `Idempotency-Key` en `POST /sales` y `POST /loans` (`IdempotencyKey` en `inventory.yaml`), y la
descripción de `x-lab-events` (outbox, `Nats-Msg-Id`). La suite es `inventory.g13.hurl`.

**Las claves:** una columna `idempotency_key` en `sales` y en `loans`, con un índice único parcial (`WHERE
idempotency_key IS NOT NULL`); en Postgres, `ADD COLUMN IF NOT EXISTS` en el esquema; en SQLite, un
`migrations-sqlite.sql` que `Migrator` corre con `setContinueOnError(true)`. Con la clave, antes de nada se busca lo ya
hecho: el mismo cuerpo devuelve la venta (201) o el préstamo (202) sin llamar a nadie ni descontar; otro cuerpo, 422.
Dos peticiones a la vez con la misma clave: el índice deja pasar una, y la otra captura `DuplicateKeyException` y
devuelve la primera. La venta repetida no trae `replenishmentRequested` (no se guarda): `@JsonInclude(NON_NULL)`.

**La saga (G11):** el `DISPATCH` manda `Idempotency-Key` igual al id del préstamo. Un timeout o un error de E/S
(`ResourceAccessException`) es "no sé": se repite hasta 3 veces con la misma clave (espera de 500 ms × intento); un
error que `replenish` contestó (4xx, 5xx) es una falla. Al compensar un `DISPATCH` que falló sin número de orden, se
busca la orden con `GET /replenishment-orders?idempotencyKey=<préstamo>` y, si existe, se cancela.

**El outbox:** una tabla `outbox` (`id` = el `eventId`, `subject`, `payload`, `created_at`, `published_at`). Con
`EVENT_BUS=nats`, la venta inserta el evento en el outbox **dentro de su transacción** y no publica nada; con `valkey`,
publica directo como en G12 (es el bus frágil a propósito). El cliente de NATS sale del `pom.xml`.

**El publicador**, en `relay/` (Go, `pgx` y `nats.go` en las versiones de `a01`), un binario estático que el
Dockerfile compila en una etapa propia y copia a `/app/outbox-relay` de la misma imagen: asegura el stream `LAB_EVENTS`
una vez al arrancar; cada 500 ms toma hasta 100 eventos sin publicar con `FOR UPDATE SKIP LOCKED`, los publica con la
cabecera `Nats-Msg-Id` igual al `id`, y les pone `published_at` en la misma transacción; si el ack dice `Duplicate`, lo
anota. Log JSON con los campos de G7 y `component: outbox-relay`. Apagado limpio con `SIGTERM`.

**Lo que NO debe tener:** *event sourcing* ni CQRS (exclusión del curso); `LISTEN/NOTIFY` (el sondeo cada 500 ms basta y
se ve); un segundo publicador por réplica fuera del pod.

**Y el `CLAUDE.md`**, con G13 marcado como hecho.
```

### G13 · replenish

```markdown
Vas a generar el paso **G13 · Idempotencia y outbox** en `replenish`, sobre el código de G12. Trabajas dentro de `src/lab/`.

**El consumidor idempotente:** una tabla `processed_events` (`event_id` como clave primaria, `order_id`,
`processed_at`). En una transacción (un `Store.transaction` nuevo: una conexión del pool para todas las consultas; con
SQLite, `BEGIN`/`COMMIT`), primero `INSERT … ON CONFLICT (event_id) DO NOTHING RETURNING`; si no insertó, es una entrega
repetida: no se crea nada y el log dice `evento repetido: ya tiene su orden`. El `ack` sigue después del commit.

**La clave de idempotencia** en `POST /replenishment-orders`: columna `idempotency_key` con índice único parcial; la misma
clave y el mismo cuerpo devuelven la orden ya creada (201), otro cuerpo es 422, y la carrera se resuelve con el índice.
`GET /replenishment-orders?idempotencyKey=` devuelve la orden de esa clave o una lista vacía.

**La cancelación idempotente:** cancelar una orden que ya está en `CANCELLED` devuelve la orden con 200; 409 solo si salió.
Una compensación se reintenta, y su primer intento pudo haber llegado.

**Y el `CLAUDE.md`**, con G13 marcado como hecho.
```

Los dos pasaron la suite al primer intento. La última regla de `replenish`, la cancelación idempotente, **no estaba en
la primera versión del prompt**: la agregó el laboratorio, cuando tres préstamos se quedaron diez minutos compensando
contra un 409 que no iba a cambiar nunca ([Fase 26](26-idempotencia-y-outbox.md), sección 8). Es el método de la sección
siguiente aplicado a un caso que la suite no cubre.

---

## 📄 Los `CLAUDE.md` de cada servicio

Cada servicio lleva en su carpeta un `CLAUDE.md` de menos de cincuenta líneas: el stack, los
comandos, las convenciones y **la tabla de su contrato paso a paso**, con lo hecho y lo pendiente.
Es lo que lee el asistente cada vez que trabaja en esa carpeta, y lo que evita que en G1 le agregue
métricas "porque ya que estaba". Se actualizan con cada paso, en la misma tanda que el código:
[pricing](src/lab/services/pricing/CLAUDE.md) · [inventory](src/lab/services/inventory/CLAUDE.md) ·
[catalog](src/lab/services/catalog/CLAUDE.md) · [replenish](src/lab/services/replenish/CLAUDE.md) ·
[storefront](src/lab/services/storefront/CLAUDE.md).

---

## 🛠️ Cuando el código generado no pasa

Pasa, y el método dice qué hacer: **leer el fallo, entender qué le faltó al prompt, corregir el
prompt y regenerar**. Los cuatro tropiezos de G0, y lo que se agregó al prompt por cada uno:

| Lo que falló | El síntoma | Lo que se agregó al prompt |
|---|---|---|
| el `storefront` en compose | `HTTP 200 … actual value is <403>`: `vite preview` rechaza el nombre de host `storefront` | `preview.allowedHosts: true`, con el porqué |
| el build de `replenish` | `error TS2688: Cannot find type definition file for 'vitest/globals'` | quitar los tipos de Vitest del `tsconfig.json` junto con las pruebas |
| el esqueleto de `catalog` | Laravel crea `.env`, `APP_KEY` y una base SQLite en la instalación | crearlo con `--no-scripts` y las rutas en el grupo `api` |
| la plantilla del `storefront` | trae versiones anteriores de React y de Vite | subirlas a las de `a01` |

Y uno de la suite, no del código: en Hurl 8, el predicado `includes` sobre una colección está
obsoleto (`warning: <includes> predicate is now deprecated in favor of <contains> predicate`); la
suite usa `contains`.

---

## 🧭 Cuándo usar qué

| Quieres… | Usa | Por qué |
|---|---|---|
| saber si un servicio está bien | `task conformance -- <paso>` | es la única definición de "bien" |
| leer un contrato | `task contracts:docs`, o el YAML | la página es cómoda; el YAML manda |
| cambiar la forma de un payload | contrato → suite → prompt → código | en ese orden |
| regenerar un servicio | el prompt de su paso, con el marco común | el código sale del prompt |
| escribir un servicio a mano | adelante | la suite lo juzga igual |

---

## ⚠️ Advertencias

- **Los frameworks traen cosas de pasos futuros activadas de serie**: Actuator en Spring, la ruta
  `/up` en Laravel, las pruebas de ejemplo en Nest. Cada prompt dice cuáles quitar; si tu asistente
  las deja, la suite de G0 lo atrapa en `/metrics` y no en todo lo demás. Revisa.
- **Las plantillas no traen las versiones de `a01`**: `create-vite` y el esqueleto de Nest fijan las
  suyas. La versión que manda es la de `a01`.
- **El Dockerfile de G0 es de una sola etapa a propósito.** La imagen de `pricing` pesa 507 MB así; la
  [Fase 04](04-empaquetar-los-cuatro-runtimes.md) la reescribe y mide la diferencia.

---

## 📚 Referencias

- OpenAPI Specification 3.1.1: https://spec.openapis.org/oas/v3.1.1.html
- Hurl, *Manual* y *Asserting Response*: https://hurl.dev/docs/manual.html ·
  https://hurl.dev/docs/asserting-response.html
- Swagger UI, *Configuration* (la variable `URLS`):
  https://swagger.io/docs/open-source-tools/swagger-ui/usage/configuration/
- Spring Initializr: https://start.spring.io/ · Spring Boot: https://docs.spring.io/spring-boot/index.html
  (apunta a la versión vigente, no a la 4.1 fija)
- Laravel 13, *Installation*: https://laravel.com/framework/docs/13.x/installation
- NestJS, *CLI Overview*: https://docs.nestjs.com/cli/overview
- Vite, *Getting Started* y *Preview Options*: https://vite.dev/guide/ ·
  https://vite.dev/config/preview-options
- Go, `net/http.ServeMux` (los patrones con método): https://pkg.go.dev/net/http#ServeMux
- Claude Code: https://code.claude.com/docs/en/overview

> ⚠️ Las URL y los contenidos cambian; las de Spring, Vite y Nest no fijan versión.

---

## 🧪 Ejercicios (8)

### 🟢 Ejercicio 1 — Un contrato, por su paso
Con `task contracts:docs`, encuentra en `inventory.yaml` las operaciones de G11 y G13.

**Criterio:** la lista de operaciones con su `x-lab-paso`, y la cabecera que G13 le agrega a `POST /sales`.

### 🟢 Ejercicio 2 — La misma suite, en dos entornos
Corre la suite de G1 contra compose y la de tu último paso contra el cluster.

**Criterio:** las dos salidas con `Failed files: 0`, y la diferencia en cómo llega Hurl a los servicios (la red de
compose o el `Service` del cluster).

### 🟡 Ejercicio 3 — La capacidad que llegó antes
En una copia de `pricing` de G0, agrega una ruta `/metrics` que conteste 200, y corre la suite de G0.

**Criterio:** la línea de Hurl que falla (`HTTP 404 … actual value is <200>`) y una frase sobre por qué la regla 3
existe.

### 🟡 Ejercicio 4 — Un cambio de contrato, en orden
Agrega a la respuesta de `GET /prices/{sku}` un campo `validFrom` (fecha desde la que rige el precio): contrato, suite,
prompt, código.

**Criterio:** la suite del paso en verde, y los cuatro archivos tocados en ese orden (el historial de tu repositorio lo
muestra).

### 🟠 Ejercicio 5 — Regenerar desde el prompt
Borra `services/pricing/` en una rama y regenéralo con el prompt de G1 y tu asistente, sin mirar el código anterior.

**Criterio:** la suite de G1 en verde dos veces seguidas, y la lista de lo que tuviste que agregarle al prompt (vacía es
una respuesta válida).

### 🟠 Ejercicio 6 — Un servicio a mano
Escribe `pricing` de G0 en un lenguaje que no sea Go, sin asistente.

**Criterio:** `task conformance -- G0` en verde con tu imagen, y el tamaño de la imagen comparado con el de la
[Fase 04](04-empaquetar-los-cuatro-runtimes.md).

### 🔴 Ejercicio 7 — Lo que la suite no cubre
Busca en los prompts de G11 a G13 una regla que ninguna suite compruebe (la cancelación idempotente de `replenish` es un
ejemplo que ya se escapó una vez) y escribe el caso de Hurl.

**Criterio:** el caso falla contra la imagen del paso anterior y pasa contra la actual.

### 🔴 Ejercicio 8 — Una fila más en la matriz
El proyecto final ([Fase 27](27-el-veredicto-y-el-proyecto-final.md)) pide el contrato y la suite de tu servicio, no su
prompt. Escribe su fila en la matriz y el prompt que lo genera de cero, en el estado de G13, con el marco común.

**Criterio:** una generación en una carpeta vacía, con tu prompt y sin el código anterior, que pasa tu
`<svc>.g13.hurl`; y en la fila, qué capacidades de G0 a G13 le corresponden y cuáles no, con el porqué.

---

> 🏷️ **Este apéndice deja archivos en el repositorio**: `src/lab/contracts/` (los cuatro contratos,
> la suite y su configuración) y los `CLAUDE.md` de los servicios. Con `task conformance -- G0`
> pasando, el commit se etiqueta `apendice-a03-contratos` (ver la
> [convención de git](00-convencion-de-git-y-tags.md)).
