# Prompts G0 (borrador de T2; la versión que funcionó se publica en a03)

## El marco común de G0

Se pega al principio de cada prompt de servicio.

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

## G0 · pricing (el piloto)

```markdown
{{marco común}}

**Servicio:** `pricing`, en `services/pricing/`. **Stack:** Go (la versión de a01), solo la biblioteca
estándar, un módulo `lab/pricing` con un `main.go`. **Sale de:** el `PriceService` de Contingencia
(`legacy/contingencia/src/main/java/co/coodrosan/contingencia/soap/PriceService.java`).

**El endpoint de G0:** `GET /prices/{sku}?store={storeId}` devuelve siempre un precio fijo de 12900
COP: `{"sku":"<sku>","store":"<store, o DRO-001 si no viene>","price":12900,"currency":"COP"}`.

**Dockerfile G0:** una etapa sobre `golang` (a01), que compila con `go build` y corre el binario.
```

## G0 · inventory

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

## G0 · catalog

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

## G0 · replenish

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

## G0 · storefront

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
