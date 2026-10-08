# L05 — Clientes HTTP y resiliencia

> **Objetivo:** que `inv-api` deje de llamar a un dominio que no existe y empiece a llamar
> a un proveedor real que se porta mal a propósito, y que al terminar puedas demostrar
> —con una métrica, un journal de peticiones y una lista de eventos, no con una opinión—
> cuántos hilos te costó una llamada sin timeout y cuántos fallos registró tu circuit
> breaker en cada orden de apilado.
> **Asume:** [`13`](13-clientes-http.md) y [`19`](19-resiliencia.md) leídos, y
> [`05`](05-proxies-y-aop.md) fresco. Este lab no repite su teoría: la ejecuta. Si no
> reconoces el diagrama de [`19` §7 — el orden en que se apilan](19-resiliencia.md#7--el-orden-en-que-se-apilan),
> vuelve ahí antes de seguir: la sección 6 de hoy vive de contarlo.
> **Prerrequisitos:** `L04` hecho. `inv-api` persiste en Postgres con Flyway, tiene
> `InventoryService` sobre `InventoryItemRepository`, un `@RestControllerAdvice` con
> `ProblemDetail` y un `SupplierProperties` de `L02` que apunta a
> `https://inv-supplier.invlab.example` — **un dominio reservado que nunca resolvió**. Hoy
> deja de ser decorativo.
> **Costo:** **$0.00**. Dos contenedores en `localhost` y nada más.
> **Duración:** entre 160 y 190 minutos. Cuatro de las seis secciones de mecanismo son
> fallos provocados, y ahí es donde tiene que irse el tiempo.
> **Qué deja levantado:** los perfiles `db` y `ext` de Compose corriendo
> (`inv-lab-postgres-1` e `inv-lab-wiremock-1`). `L06` asume los dos arriba. La aplicación
> se lanza y se mata en cada sección.
> **Qué toca:** el `pom.xml`, `application.yml`, una migración de Flyway nueva bajo
> `src/main/resources/db/migration/` y las clases de `com.invlab.invapi.supplier`
> (`SupplierGateway` y `OutboundLoggingInterceptor`). Fuera del proyecto, el directorio
> `wiremock/mappings/` del repositorio, junto al `docker-compose.yml`, que tampoco se amplía:
> solo se levanta su perfil `ext`.
> **Vigencia:** 18 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 ·
> Java 21 · Resilience4j 2.2.0 · WireMock 3.13.2.

**Salto rápido:** [Estado inicial](#1--el-problema-y-el-estado-inicial) ·
[WireMock como `inv-supplier`](#2--wiremock-como-inv-supplier-y-su-teardown) ·
[La llamada sin timeout](#3-️-la-llamada-sin-timeout-y-el-hilo-que-no-vuelve) ·
[Retry sin jitter](#4-️-retry-con-backoff-y-el-ariete-sincronizado) ·
[El circuito que abre](#5--el-circuito-que-abre-de-verdad) ·
[El orden de los decoradores](#6--el-orden-de-los-decoradores-invertido-a-propósito) ·
[Bulkhead y fallback](#7--bulkhead-saturado-y-el-fallback-honesto) ·
[Checklist](#8--checklist-de-salida) ·
[Preguntas rápidas](#-preguntas-rápidas) ·
[Ejercicios](#-ejercicios-16)

---

## 1. 🧭 El problema y el estado inicial

En `L04` aprendiste a no fiarte del código de estado: la verdad estaba en un `SELECT`. Hoy
el criterio de verdad se mueve otra vez, y a un sitio incómodo.

Hasta ahora todo lo que rompiste estaba **dentro de tu proceso**: un proxy que no
interceptaba, una transacción que no revertía, un pool que se agotaba. Todo eso lo
controlas tú. A partir de esta sección `inv-api` depende de alguien que no controlas, que
no se cae del todo y que un martes cualquiera decide tardar treinta segundos en contestar.

```text
L03  →  falla el borde HTTP        → lo ves en el código de estado
L04  →  falla la persistencia      → lo ves en un SELECT, o no lo ves nunca
L05  →  falla el otro              → no falla nada tuyo; se te acaban los hilos
```

Ese es el cambio de músculo de hoy, y por eso las verificaciones de este lab son las tres
que nunca usaste antes: **una métrica de Actuator** (`tomcat.threads.busy`), **el journal
de peticiones de WireMock** (cuántas llamadas llegaron de verdad al proveedor) y **la lista
de eventos del circuit breaker** (qué registró y cuándo). Las tres miden efectos, no
intenciones, que es justo lo que falta cuando alguien dice "le puse retry y circuit
breaker" sin poder decir cuántas veces salió a la red.

Primero confirma que vienes del estado correcto:

```bash
docker compose -p inv-lab ps
cd inv-api
./mvnw -q clean package
java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -o /dev/null -w '%{http_code}\n' localhost:8081/actuator/health
curl -s -X POST localhost:8080/api/items -H 'Content-Type: application/json' \
  -d '{"sku":"ABC-000123","name":"Tornillo M6","quantity":40}' -o /dev/null -w '%{http_code}\n'
docker exec -i inv-lab-postgres-1 psql -U inv_lab -d inv_lab \
  -c 'SELECT sku, quantity FROM inventory_item'
```

```text
NAME                IMAGE                    STATUS                   PORTS
inv-lab-postgres-1  postgres:17.11-alpine    Up 3 minutes (healthy)   0.0.0.0:5432->5432/tcp
200
201
    sku     | quantity
------------+----------
 ABC-000123 |       40
(1 row)
```

- **`docker compose -p inv-lab ps` tiene que listar Postgres en `(healthy)`.** Si no
  aparece, `L04` dejó el perfil `db` caído: vuelve a levantarlo con
  `docker compose --profile db up -d`. Si además faltan las tablas, el problema es que
  hiciste `down -v` entre sesiones y Flyway va a recrearlas en el arranque — eso es normal
  y no rompe nada.
- **`./mvnw -q clean package` sin `-DskipTests`**, igual que en `L04`: los tests de `L03`
  son la red de seguridad de todo lo que se va a mover hoy
  ([`L03` §9](l03-api-rest-filtros-y-errores.md#9--mockmvc-sobre-todo-lo-anterior)). Si fallan
  con `Connection to localhost:5432 refused`, el perfil `db` no está arriba.
- **El `201` seguido del `SELECT`** confirma que la capa de datos de `L04` sigue entera. Si
  te devuelve `409`, el `sku` ya existía de la sesión anterior y también sirve como prueba.
- **`> app.log 2>&1 &`** vuelve a ser la herramienta más usada del lab, y hoy por una razón
  nueva: a partir de la sección 4 la pregunta no es "¿qué dice el log?" sino **"¿a qué hora
  exacta lo dice?"**, y eso se contesta con `grep` y `cut` sobre el fichero, no mirando la
  pantalla.

**Lo que vas a construir hoy, en orden**, y el porqué del orden: primero el proveedor falso
(sección 2), porque sin alguien a quien llamar no hay nada que romper; después la llamada
desnuda y su timeout (sección 3), porque [`19` §2](19-resiliencia.md#2--el-timeout-es-el-primero-y-sin-él-nada-más-sirve)
dice que sin timeout el resto del capítulo es decorativo y hoy se demuestra; y después los
tres patrones apilados en el orden en que se descubren los errores: retry (sección 4),
circuit breaker (sección 5), el orden entre ambos (sección 6) y el bulkhead con su fallback
(sección 7).

> **📝 Lo que este lab deja fuera a propósito.** La **comparación de código entre Feign,
> HTTP Interfaces y `RestClient`** se queda en [`13` §9](13-clientes-http.md#9--los-cinco-y-el-veredicto):
> escribir la misma llamada tres veces enseña sintaxis, no runtime, y este lab existe para
> lo segundo. El **`ErrorDecoder` de Feign** y el **rate limiter** van como 🔥 opcionales,
> porque ninguno de los dos aporta un fallo silencioso nuevo: el primero es traducción de
> errores y el segundo protege al proveedor, no a ti. Y **las alertas sobre el cambio de
> estado del circuito** —que [`19` §9](19-resiliencia.md#9--sin-métricas-esto-es-fe)
> declara parte del patrón— son de
> [`L07` §9](l07-actuator-metricas-y-trazas.md#9-️-la-alerta-sobre-el-circuito-de-l05), donde ya
> habrá Prometheus para recibirlas; hoy se miran los eventos a mano y se dice en voz alta
> que eso no es una alerta.

---

## 2. 🧱 WireMock como `inv-supplier`, y su teardown

`SupplierProperties` apunta desde `L02` a `https://inv-supplier.invlab.example`, y ese
dominio **nunca resolvió**: `.example` está reservado para documentación precisamente para
que no resuelva. Necesitas un proveedor de verdad, y necesitas que se porte mal cuando tú
se lo pidas.

La tentación es `MockRestServiceServer` o un `@MockitoBean` del gateway. No sirven hoy, y
la razón es exactamente la doctrina de reparto de
[`L00` §2](l00-idea-lab-practico.md#2--la-doctrina-de-reparto): un mock **sustituye la
llamada**, así que no hay socket, no hay handshake, no hay hilo esperando bytes y no hay
pool de conexiones. Los cuatro fallos de hoy viven en esa capa. Un test con
`MockRestServiceServer` pasa en verde mientras tu servicio se muere por un proveedor lento,
y esa es la pregunta 13 de [`13`](13-clientes-http.md#-preguntas-rápidas).

WireMock sí es un proceso al otro lado de un socket. Y ya está declarado en el Compose de
la serie, en el perfil `ext`, publicado en el puerto 8090: el fichero está entero y
explicado servicio por servicio en
[`L00` §6](l00-idea-lab-practico.md#6--el-docker-composeyml-de-la-serie) y **no se toca**.

```bash
cd ..                              # a la raíz del repo, donde vive el docker-compose.yml
mkdir -p wiremock/mappings
docker compose --profile ext up -d
docker compose -p inv-lab ps
cd inv-api                         # de vuelta al proyecto: el resto del lab compila aquí
```

```text
NAME                IMAGE                            STATUS                  PORTS
inv-lab-postgres-1  postgres:17.11-alpine            Up 8 minutes (healthy)  0.0.0.0:5432->5432/tcp
inv-lab-wiremock-1  wiremock/wiremock:3.13.2-alpine  Up 2 seconds            0.0.0.0:8090->8080/tcp
```

- **`mkdir -p wiremock/mappings` va antes del `up`.** El Compose monta `./wiremock` en
  `/home/wiremock` dentro del contenedor; si el directorio no existe, Docker lo crea como
  **root** y después no vas a poder escribir los stubs sin `sudo`. Crearlo tú primero es
  medio segundo que ahorra diez minutos.
- **`--profile ext`** levanta solo WireMock. Postgres sigue arriba de `L04` porque ya
  estaba corriendo: los perfiles se suman, no se reemplazan, y `up` no toca lo que ya está.
- **`0.0.0.0:8090->8080/tcp`** es la traducción del `ports: ["8090:8080"]` del Compose:
  WireMock escucha en 8080 dentro del contenedor y se publica en 8090 fuera, para no chocar
  con `inv-api`. La URL que va a tu configuración es la de fuera.
- **WireMock no tiene `healthcheck` en el Compose** y por eso sale `Up` a secas, sin
  `(healthy)`. Arranca en menos de dos segundos, pero si tu primer `curl` da
  `Connection refused`, es eso y no un stub mal escrito.

Y **el teardown va aquí, no al final del lab**, porque es aquí donde se crea el recurso:

```bash
docker compose -p inv-lab stop wiremock      # lo para y conserva el contenedor
docker compose -p inv-lab rm -sf wiremock    # lo para y lo borra, sin tocar Postgres
docker compose -p inv-lab ps                 # solo debe quedar inv-lab-postgres-1
ls wiremock/mappings                         # los stubs SIGUEN en tu disco
```

- **`stop` frente a `rm -sf`:** el primero deja el contenedor parado y arrancable con
  `start`; el segundo lo borra. Ninguno de los dos toca Postgres, y esa es la diferencia
  con `down`, que se lleva **todo el proyecto** por delante — incluida la base que `L04` te
  dejó con datos.
- **`-s` para (stop) antes de borrar y `-f` no pregunta.** Sin `-s`, `rm` se niega a borrar
  un contenedor en ejecución con `Stop the container before attempting removal`.
- **WireMock no tiene volumen con nombre**, así que no hay nada que `-v` pueda borrar. Lo
  que sí sobrevive a todo es el **bind mount**: `./wiremock` es un directorio de tu
  repositorio, y los stubs que escribas ahí siguen existiendo después de cualquier `down`.
  Es lo contrario de `postgres-data`, y conviene tener las dos cosas claras: lo que vive en
  un volumen muere con `-v`, lo que vive en un bind mount muere cuando **tú** lo borras.
- **Lo que no muere con ninguno de los dos:** la imagen `wiremock/wiremock:3.13.2-alpine`
  descargada (unos 150 MB, se borra con `docker image rm`). Eso se limpia en [`L09` §8](l09-empaquetado-imagen-y-limpieza.md#8--la-limpieza-verificada).

Vuelve a levantarlo (`docker compose --profile ext up -d`) y escribe los stubs. Uno por
comportamiento, en `wiremock/mappings/`, y **el `sku` es el que elige cómo se porta el
proveedor** — así no hay que reconfigurar nada a media sección:

```json
{
  "priority": 1,
  "request": {
    "method": "GET",
    "urlPathPattern": "/suppliers/ABC-[0-9]{6}/quote"
  },
  "response": {
    "status": 200,
    "headers": { "Content-Type": "application/json" },
    "fixedDelayMilliseconds": 80,
    "jsonBody": {
      "sku": "{{request.pathSegments.[1]}}",
      "price": 12.50,
      "quotedAt": "2026-09-18T10:00:00Z"
    }
  }
}
```

- **`priority: 1`** es la prioridad más alta de WireMock (menor número gana). Con varios
  stubs que podrían casar, el de menor `priority` responde; el catch-all del final lleva
  `priority: 10` para que solo actúe cuando ningún otro case.
- **`urlPathPattern`** casa por expresión regular contra **la ruta sin query string**. Su
  hermano `urlPath` es literal y `url` incluye la query: elegir el equivocado produce el
  clásico "mi stub no responde" cuando alguien añade `?trace=true` a la llamada.
- **`fixedDelayMilliseconds: 80`** es el proveedor sano de
  [`13` §2](13-clientes-http.md#2-️-no-hay-timeout-por-defecto-y-ese-es-el-tema): 80 ms, el
  número con el que está hecha la cuenta de capacidad de ese capítulo. Un stub sin delay
  responde en menos de un milisegundo y te da una línea base irreal.
- **`{{request.pathSegments.[1]}}`** es response templating: devuelve el segmento 1 de la
  ruta —el `sku`— dentro del JSON. Funciona porque el Compose arranca WireMock con
  `--global-response-templating`; sin esa bandera verías la plantilla literal en la
  respuesta, con llaves y todo, y el `sku` de tu DTO quedaría en `{{request...}}`.
- **`jsonBody` frente a `body`:** el primero recibe JSON de verdad y se serializa solo; el
  segundo es una cadena y te obliga a escapar cada comilla. Con `body` y una comilla mal
  puesta, WireMock arranca igual y el stub simplemente no carga.

Los otros tres, en el mismo directorio:

```json
{
  "priority": 1,
  "request": { "method": "GET", "urlPathPattern": "/suppliers/SLW-000001/quote" },
  "response": {
    "status": 200,
    "headers": { "Content-Type": "application/json" },
    "fixedDelayMilliseconds": 30000,
    "jsonBody": { "sku": "SLW-000001", "price": 99.00, "quotedAt": "2026-09-18T10:00:00Z" }
  }
}
```

```json
{
  "priority": 1,
  "request": { "method": "GET", "urlPathPattern": "/suppliers/SLW-000002/quote" },
  "response": {
    "status": 200,
    "headers": { "Content-Type": "application/json" },
    "fixedDelayMilliseconds": 2000,
    "jsonBody": { "sku": "SLW-000002", "price": 45.00, "quotedAt": "2026-09-18T10:00:00Z" }
  }
}
```

```json
{
  "priority": 1,
  "request": { "method": "GET", "urlPathPattern": "/suppliers/ERR-000500/quote" },
  "response": {
    "status": 500,
    "headers": { "Content-Type": "application/json" },
    "jsonBody": { "error": "upstream pricing engine unavailable" }
  }
}
```

- **`SLW-000001` con 30 000 ms** es el proveedor enfermo del martes: responde `200`, no
  falla, y retiene tu hilo medio minuto. Es el único stub que necesita la sección 3.
- **`SLW-000002` con 2 000 ms** es el proveedor lento pero acotado: sirve para el bulkhead
  de la sección 7 y para el `slow-call-rate-threshold` de la 5, donde el circuito tiene que
  abrir **sin un solo error**.
- **`ERR-000500` devuelve un 500 con cuerpo**, y el cuerpo importa: un 500 vacío se
  diagnostica peor y el `ErrorDecoder` del 🔥 opcional necesita algo que decodificar.
- **Ningún stub devuelve 404 a propósito**: de eso se encarga el catch-all, y la diferencia
  entre "no casó ningún stub" y "el proveedor dice que ese `sku` no existe" es justo lo que
  la sección 4 va a necesitar distinguir.

Y el catch-all, que es el stub que casi nadie escribe y el que evita media hora de
confusión:

```json
{
  "priority": 10,
  "request": { "method": "GET", "urlPathPattern": "/suppliers/.*/quote" },
  "response": {
    "status": 404,
    "headers": { "Content-Type": "application/json" },
    "jsonBody": { "error": "unknown sku" }
  }
}
```

- **Sin este stub**, un `sku` que no casa con ninguno recibe el 404 por defecto de WireMock
  con un cuerpo HTML que dice `No response could be served as there are no stub mappings
  in this WireMock instance`. Ese mensaje confunde: parece que **ningún** stub cargó, y lo
  que pasa es que ninguno **casó**.
- **`priority: 10`** lo deja como último recurso. Con la misma prioridad que los demás,
  WireMock elegiría entre varios candidatos por orden de carga, que no es determinista.

Carga los stubs y comprueba los cuatro comportamientos:

```bash
curl -s -X POST localhost:8090/__admin/mappings/reset
curl -s -o /dev/null -w 'ABC %{http_code} en %{time_total}s\n' localhost:8090/suppliers/ABC-000123/quote
curl -s -o /dev/null -w 'SLW2 %{http_code} en %{time_total}s\n' localhost:8090/suppliers/SLW-000002/quote
curl -s -o /dev/null -w 'ERR %{http_code} en %{time_total}s\n' localhost:8090/suppliers/ERR-000500/quote
curl -s -o /dev/null -w 'XXX %{http_code} en %{time_total}s\n' localhost:8090/suppliers/ZZZ-999999/quote
```

```text
ABC 200 en 0.091810s
SLW2 200 en 2.007214s
ERR 500 en 0.004523s
XXX 404 en 0.003118s
```

- **`POST /__admin/mappings/reset`** relee el directorio `mappings/` sin reiniciar el
  contenedor. Es el comando que vas a usar cada vez que edites un stub, y olvidarlo es la
  causa número uno de "cambié el JSON y sigue devolviendo lo mismo".
- **`%{time_total}`** de `curl` imprime los segundos de la llamada completa. Fíjate en que
  el 500 tarda 4 ms: **un error es rápido y una lentitud no lo es**, que es la frase
  entera de [`19` §1](19-resiliencia.md#1--el-problema-el-fallo-parcial-y-la-latencia-como-fallo)
  en dos números.
- **El `__admin` es la API de administración de WireMock** y vive en el mismo puerto que
  los stubs. Además de `mappings`, expone `requests` —el journal que la sección 4 va a
  contar— y `requests/reset` para vaciarlo.

> **⏱️ Costo en runtime.** WireMock consume del orden de **180 MB de RAM** con estos cuatro
> stubs, y el journal de peticiones crece en memoria con cada llamada recibida: las tandas
> de la sección 4 dejan cientos de entradas ahí. `POST /__admin/requests/reset` lo vacía, y
> conviene hacerlo entre experimentos para que los conteos no arrastren la tanda anterior.

---

## 3. ⏱️ La llamada sin timeout, y el hilo que no vuelve

Primer fallo del lab, y el que hace posibles a los otros tres. Negocio pide algo mínimo:
que `GET /api/items/{sku}/quote` devuelva la cotización del proveedor junto al stock que ya
tienes en la base. Son treinta líneas de código y ninguna parece peligrosa.

Empieza por apuntar `SupplierProperties` al contenedor, en `application.yml`:

```yaml
inv:
  supplier:
    base-url: http://localhost:8090        # antes: https://inv-supplier.invlab.example
    timeout: 2s
    max-connections: 20
    mode: "on"                             # las comillas son de la trampa de L02 §10
```

- **`mode` sigue ahí, y con sus comillas.** Es el cuarto componente que
  [`L02` §10](l02-configuracion-y-profiles.md#10-️-el-error-clásico-de-yaml-reproducido-dos-veces)
  dejó en `SupplierProperties`, y es `@NotBlank`: si reescribes el bloque sin él, el arranque
  muere con `APPLICATION FAILED TO START` antes de llegar a ninguna llamada. Sin comillas, YAML
  1.1 lo enlaza como el booleano `true` y la validación pasa con un valor que no querías.
- **`http` y no `https`:** WireMock sirve en claro por el 8090. Dejar el `https` de `L02`
  produce un `SSLException` en la primera llamada que parece un problema de certificados y
  es un esquema mal copiado.
- **`timeout: 2s` y `max-connections: 20` siguen ahí y siguen sin usarse.** Eso es
  deliberado y es el chiste amargo de esta sección: las propiedades existen desde `L02`,
  están validadas con `@Min`/`@NotNull`, aparecen en `/actuator/configprops`… y **nadie las
  lee**. Tener el valor configurado no es tenerlo aplicado. 😉

Ahora el gateway, en `src/main/java/com/invlab/invapi/supplier/SupplierGateway.java`:

```java
record SupplierQuote(String sku, BigDecimal price, Instant quotedAt) { }   // DTO, no entidad

@Service
class SupplierGateway {

    private final RestClient restClient;

    SupplierGateway(RestClient.Builder builder, SupplierProperties properties) {
        this.restClient = builder.baseUrl(properties.baseUrl()).build();
    }

    SupplierQuote quote(String sku) {
        return restClient.get()
                .uri("/suppliers/{sku}/quote", sku)
                .retrieve()
                .body(SupplierQuote.class);
    }
}
```

- **`RestClient.Builder` se inyecta, no se instancia.** Boot expone uno `prototype` ya
  configurado con tus `HttpMessageConverter` y tus `RestClientCustomizer`;
  `RestClient.create()` devuelve uno crudo y sin nada de eso
  ([`13` §3](13-clientes-http.md#3--restclient-el-default-del-curso)). La diferencia se
  nota el día que alguien registra un módulo de Jackson y tu gateway lo ignora.
- **`SupplierProperties` se inyecta como bean** porque `@ConfigurationPropertiesScan` de
  `L02` ya lo registra. Leer `@Value("${inv.supplier.base-url}")` aquí funcionaría y sería
  un paso atrás: perderías la validación de arranque.
- **`uri("/suppliers/{sku}/quote", sku)`** expande la plantilla y **codifica** el valor. Si
  concatenas, un `sku` con `/` te cambia la ruta y un `sku` con `?` te inventa una query.
- **`record SupplierQuote`** y no la entidad `InventoryItem`: es un DTO del contrato ajeno,
  y mezclarlo con tu modelo ata tu esquema al de otro. La convención de `record` para DTOs
  y clase normal para entidades es la misma de `L04`.
- **Lo que no se ve aquí, y es todo el problema:** no hay un solo milisegundo declarado.
  Esta clase compila, pasa la revisión de código y no tiene ningún timeout.

El endpoint, en el controller de `L03`:

```java
@GetMapping("/{sku}/quote")
QuoteResponse quote(@PathVariable String sku) {
    InventoryItem item = service.findBySku(sku).orElseThrow(() -> new ItemNotFoundException(sku));
    SupplierQuote quote = gateway.quote(sku);            // llamada saliente, fuera de transacción
    return new QuoteResponse(item.sku(), item.quantity(), quote.price(), quote.quotedAt());
}

record QuoteResponse(String sku, int quantity, BigDecimal price, Instant quotedAt) { }
```

- **La llamada saliente está fuera de cualquier `@Transactional`**, y eso no es casualidad:
  `findBySku` abre y cierra su transacción de solo lectura antes de que el gateway toque la
  red. Hacerlo al revés es lo que prohíbe
  [`16` §8](16-transacciones.md#8--el-límite-de-la-transacción-no-es-el-límite-de-tu-método),
  y en la práctica significa retener una conexión de Hikari durante los treinta segundos
  que tarde el otro — el mismo pool que agotaste a mano en
  [`L04` §7](l04-datos-y-transacciones.md#7-️-requires_new-y-el-deadlock-de-pool), ahora
  agotado por alguien que ni siquiera está en tu red.
- **`QuoteResponse` es un `record` nuevo** y no se reutiliza `SupplierQuote`: uno es lo que
  el proveedor te dice y el otro es lo que tú publicas. Cuando el proveedor añada un campo,
  tu contrato no debería moverse solo.

Antes de ejecutar nada, **haz la predicción**. El escenario: Tomcat con diez hilos y doce
peticiones simultáneas contra el `sku` enfermo. ¿Cuántas responden, cuántas se quedan
esperando, y qué le pasa a `/actuator/health`?

Baja los hilos para que el experimento quepa en una pantalla:

```yaml
server:
  tomcat:
    threads:
      max: 10                 # el default son 200; con 10 el efecto se ve en segundos
    accept-count: 5           # cola del socket cuando los 10 hilos están ocupados

management:
  endpoints:
    web:
      exposure:
        include: health,env,configprops,metrics,threaddump
```

- **`threads.max: 10`** no cambia el fenómeno, solo la escala: con los 200 por defecto
  harían falta 200 peticiones para verlo, y el `curl` en paralelo se volvería el cuello de
  botella en vez del servidor. Es la misma cuenta de
  [`13` §2](13-clientes-http.md#2-️-no-hay-timeout-por-defecto-y-ese-es-el-tema) con números
  que caben en una terminal.
- **`accept-count: 5`** es la cola del socket: peticiones aceptadas por el sistema
  operativo que todavía no tienen hilo. Cuando se llena, el cliente deja de recibir un
  error de aplicación y empieza a recibir `Connection refused` del kernel — que es la parte
  que hace que el incidente parezca "la red".
- **`metrics` y `threaddump` en la lista blanca** son lo nuevo. Por defecto Boot solo
  expone `health`: sin esta línea, los `curl` de esta sección devuelven `404` y parece que
  Actuator no funciona.

Levanta y mide la línea base **antes** de romper nada:

```bash
cd inv-api && ./mvnw -q clean package
java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s localhost:8081/actuator/metrics/tomcat.threads.busy | jq -c '.measurements'
curl -s localhost:8080/api/items/ABC-000123/quote | jq -c
```

```text
[{"statistic":"VALUE","value":0.0}]
{"sku":"ABC-000123","quantity":40,"price":12.50,"quotedAt":"2026-09-18T10:00:00Z"}
```

- **`tomcat.threads.busy` es el contador que hay que aprender hoy.** Cuenta los hilos del
  conector de 8080 que están atendiendo una petición **ahora mismo**. En reposo marca `0.0`,
  y tu `curl` a la métrica no lo altera porque Actuator vive en el conector de 8081 y tiene
  sus propios hilos. Ese cero es el número contra el que vas a comparar dentro de un
  minuto.
- **`/actuator/metrics/<nombre>` devuelve un objeto con `measurements`**, no un número
  suelto. El `jq -c '.measurements'` es lo que lo deja en una línea legible; sin `jq`
  tendrías que leer cuarenta líneas de JSON para ver un `1.0`.
- **La respuesta del endpoint con el `sku` sano tarda 90 ms** y no enseña nada todavía. Es
  la línea base: cuando lo mismo tarde treinta segundos, la diferencia será el lab.

Ahora el fallo, provocado a propósito:

```bash
for i in $(seq 1 12); do
  curl -s -o /dev/null -w "$i:%{http_code}:%{time_total}\n" --max-time 40 \
    localhost:8080/api/items/SLW-000001/quote &
done
sleep 5
curl -s localhost:8081/actuator/metrics/tomcat.threads.busy | jq -c '.measurements'
curl -s -o /dev/null -w 'health -> %{http_code}\n' localhost:8081/actuator/health
curl -s -o /dev/null -w 'items  -> %{http_code} en %{time_total}s\n' --max-time 5 \
  localhost:8080/api/items
```

```text
[{"statistic":"VALUE","value":10.0}]
health -> 200
curl: (28) Operation timed out after 5001 milliseconds with 0 bytes received
items  -> 000 en 5.001082s
```

- **`value: 10.0` es la prueba, y es lo que separa este lab de una suposición.** Los diez
  hilos del conector están ocupados. No hay excepción, no hay error en el log, no hay nada
  en `/actuator/health`: simplemente no queda quién atienda.
- **`health -> 200` mientras la aplicación no responde** es el detalle más importante de la
  sección y el que engaña a los equipos de guardia. Actuator está en el conector de 8081
  (`management.server.port`, que escribió `L01` y `L02` trasladó al YAML; lo puso
  [`L01` §5](l01-esqueleto-cli-y-autoconfiguracion.md#5--el-resto-del-esqueleto-clase-principal-propiedades-y-wrapper)
  y `L02` trasladó al YAML), que tiene **su propio pool de hilos**. Si hubieras dejado
  Actuator en 8080, el `/health` también se habría colgado y el orquestador habría
  reiniciado el proceso — que a veces es mejor que un servicio verde y mudo.
- **`items -> 000` con `curl: (28)`** es el `GET /api/items` de siempre, un endpoint que
  **no llama al proveedor**, muriéndose igual. El pool de hilos es compartido: se cae el
  servicio entero, no el endpoint lento.
- **`--max-time 40`** en los doce `curl` del bucle evita que tu terminal se quede colgada
  cuarenta minutos si algo sale distinto. Es higiene, no parte del experimento.

Confirma la hipótesis mirando dónde están esos diez hilos, que es el diagnóstico que
[`13` §4](13-clientes-http.md#4--la-clienthttprequestfactory-timeouts-y-pool) describe y
aquí se ejecuta:

```bash
curl -s localhost:8081/actuator/threaddump \
  | jq -r '.threads[] | select(.threadName | startswith("http-nio-8080-exec"))
           | "\(.threadName) \(.threadState) \(.stackTrace[0].className).\(.stackTrace[0].methodName)"' \
  | sort | head -4
```

```text
http-nio-8080-exec-1 RUNNABLE sun.nio.ch.SocketDispatcher.read0
http-nio-8080-exec-10 RUNNABLE sun.nio.ch.SocketDispatcher.read0
http-nio-8080-exec-2 RUNNABLE sun.nio.ch.SocketDispatcher.read0
http-nio-8080-exec-3 RUNNABLE sun.nio.ch.SocketDispatcher.read0
```

- **`RUNNABLE`, no `BLOCKED`**, y por eso nadie lo encuentra. La JVM considera `RUNNABLE` a
  un hilo parado en una lectura de socket, porque desde su punto de vista está ejecutando
  una llamada al sistema. Quien busca un deadlock filtrando por `BLOCKED` no ve nada y
  concluye que la aplicación "está bien, solo lenta".
- **`SocketDispatcher.read0`** es el frame que hay que reconocer: espera de bytes que no
  llegan. Es el equivalente moderno del `SocketInputStream.socketRead0` que verás citado en
  material más viejo; el nombre cambió con la reimplementación de los sockets en JDK 13+,
  el síntoma no.
- **`.stackTrace[0]`** es el frame más profundo, el de arriba del todo. Si quieres ver
  **tu** código en lugar del de la JVM, filtra por `com.invlab` dentro del array.

> **🩺 Diagnóstico.** Hilos en `SocketDispatcher.read0` significa **timeout que falta**.
> Hilos esperando en `PoolingHttpClientConnectionManager.lease` significa **pool de
> conexiones pequeño**. El síntoma que ve el usuario es idéntico —todo va lento— y los
> arreglos son opuestos: en el primer caso subir `server.tomcat.threads.max` empeora las
> cosas, porque pone más hilos a esperar al mismo proveedor enfermo.

> **⏱️ Costo en runtime.** Cada una de esas doce peticiones cuesta **un hilo de plataforma
> (≈1 MB de pila) y una conexión del pool HTTP saliente durante todo el tiempo que el otro
> quiera tardar**. Treinta segundos no es el techo: si el proveedor acepta la conexión y no
> escribe nunca, esperas para siempre. El techo lo pones tú o no existe.

La corrección son dos líneas, y conviene ponerlas **por separado** para ver qué hace cada
una:

```yaml
spring:
  http:
    client:
      connect-timeout: 2s      # techo para ABRIR la conexión
      read-timeout: 3s         # techo entre dos bloques de bytes de la respuesta
```

- **`spring.http.client.*` es la configuración global del cliente de Boot 3.5** y aplica a
  todo `RestClient` construido desde el `Builder` inyectado — otra razón para no hacer
  `RestClient.create()`.
- **`connect-timeout: 2s`** cubre el handshake TCP (y el TLS si lo hubiera). Se agota
  cuando el host no existe, el puerto está cerrado o un firewall se come los paquetes.
  Pruébalo aparte: para WireMock con `docker compose -p inv-lab stop wiremock`, lanza una
  llamada y verás el fallo en dos segundos en vez de esperar el timeout del sistema
  operativo, que en Linux ronda los 130 segundos.
- **`read-timeout: 3s` es el que faltaba y el que importa.** Es un techo **por lectura**,
  no por llamada: una respuesta que gotea un byte cada 2,9 segundos no lo dispara nunca. El
  techo de la llamada entera lo pone un `TimeLimiter`, y por eso `19` los trata como dos
  cosas distintas.
- **Tres segundos, y no treinta:** el presupuesto del endpoint manda. Si `inv-api` promete
  responder en dos segundos, un `read-timeout` de treinta es un número que nunca va a
  actuar a tiempo.

Reinicia y repite exactamente la misma tanda:

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
for i in $(seq 1 12); do
  curl -s -o /dev/null -w "$i:%{http_code}:%{time_total}\n" localhost:8080/api/items/SLW-000001/quote &
done
wait
curl -s localhost:8081/actuator/metrics/tomcat.threads.busy | jq -c '.measurements'
grep -m1 'ResourceAccessException' app.log
```

```text
1:500:3.021455
2:500:3.024881
...
10:500:3.029640
11:500:6.038215
12:500:6.041907
[{"statistic":"VALUE","value":0.0}]
org.springframework.web.client.ResourceAccessException: I/O error on GET request for "http://localhost:8090/suppliers/SLW-000001/quote": Read timed out
```

- **Diez respuestas a los tres segundos, dos a los seis, y `tomcat.threads.busy` de vuelta
  en `0.0`.** El proveedor sigue igual de enfermo: lo que cambió es que ahora su enfermedad
  es **tuya durante tres segundos**, no durante treinta.
- **El escalón de las peticiones 11 y 12 es el `accept-count` a la vista, y conviene no
  pasarlo por alto.** Hay diez hilos y doce peticiones: las dos sobrantes esperan en la cola
  del socket **sin hilo y sin reloj propio** hasta que alguna de las diez termina a los 3 s;
  solo entonces empiezan su llamada, que también agota el `read-timeout`. De ahí los ~6 s
  de `%{time_total}`, que mide desde que `curl` salió, no desde que tu aplicación la miró.
  Es el mismo fenómeno de la tanda anterior —la cola existía también allí— con la
  diferencia de que ahora avanza: sin timeout, esas dos habrían esperado treinta segundos
  para empezar a esperar otros treinta.
- **`ResourceAccessException: … Read timed out`** es la excepción que hay que reconocer, y
  su rama importa: envuelve una `IOException` y significa que **no hubo respuesta**. No es
  `HttpServerErrorException`, que significa que el otro contestó con un 5xx. Los dos
  producen hoy un `500` hacia tu cliente, y la sección 4 los va a separar porque solo uno
  de los dos se reintenta ([`13` §6](13-clientes-http.md#6--errores-un-4xx-no-es-un-fallo-de-red)).
- **El `500` hacia tu cliente todavía es feo** —el proveedor falló, no tú— y la traducción
  correcta a `503` con `ProblemDetail` llega en la sección 5, cuando haya algo más
  interesante que traducir que un timeout.
- **`wait` sin argumentos** espera a que terminen todos los trabajos en segundo plano del
  bucle. Sin él, el `curl` a la métrica corre mientras las doce peticiones siguen vivas y
  te devuelve `10.0` otra vez — un falso negativo de la corrección que acabas de aplicar.

> **🧠 Modelo mental.** El timeout no arregla al proveedor: **convierte su latencia en tu
> error, rápido y acotado**. Todo lo que viene después —retry, circuit breaker, bulkhead—
> necesita que la llamada **termine** para poder actuar, y por eso este es el primer
> mecanismo del lab y no el cuarto.

---

## 4. ⚠️ Retry con backoff, y el ariete sincronizado

Segundo fallo, y el primero que **tú** provocas creyendo que estás mejorando algo. El
proveedor devuelve un 500 esporádico; la respuesta refleja de cualquier equipo es "ponle un
reintento". Hoy lo pones, mides lo que llega al otro lado y descubres que has construido un
ariete.

Primero la librería. En `pom.xml`, dentro de `<dependencies>`:

```xml
<dependency>
    <groupId>io.github.resilience4j</groupId>
    <artifactId>resilience4j-spring-boot3</artifactId>
    <version>2.2.0</version>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-aop</artifactId>
</dependency>
```

- **Resilience4j lleva `<version>` y las demás dependencias del proyecto no.** No es
  descuido: no está en el BOM de Boot 3.5.16, así que si no fijas la versión Maven falla
  con `'dependencies.dependency.version' for io.github.resilience4j:resilience4j-spring-boot3:jar is missing`.
  Es la regla de §5.2 de la guía del curso en acción: lo que está en el BOM, sin versión; lo
  que no, versión explícita y verificada.
- **El artefacto se llama `resilience4j-spring-boot3`, no `spring-boot-starter-resilience4j`.**
  La convención invertida delata que es de terceros: los `spring-boot-starter-*` los publica
  el equipo de Boot ([`01`](01-spring-boot-y-el-ecosistema.md)).
- **`spring-boot-starter-aop` no es opcional y este es el punto que conecta el lab entero
  con `05`.** Las anotaciones de Resilience4j funcionan con el mismísimo mecanismo de
  proxies que `@Transactional`: un aspecto que envuelve el bean. Sin AOP en el classpath no
  hay aspecto, **las anotaciones se ignoran en silencio** y tu retry no existe. Ni un error,
  ni un aviso: simplemente nada.
- **Quién ejecuta esto, en qué hilo y a través de qué proxy:** lo ejecuta el
  `RetryAspect` de Resilience4j, en **el mismo hilo del request** —no hay asincronía en
  juego—, a través del proxy CGLIB que el contenedor creó alrededor de `SupplierGateway`. Y
  con las mismas trampas: si `SupplierGateway` llamara a su propio `quote()` desde otro
  método suyo, no habría reintento
  ([`05` §5](05-proxies-y-aop.md#5-️-self-invocation-el-fallo-silencioso-número-uno)).

Necesitas ver cada intento con su hora, así que registra un interceptor de salida —el
mecanismo de [`13` §5](13-clientes-http.md#5--interceptores-logging-y-cabeceras-que-viajan)—
en `src/main/java/com/invlab/invapi/supplier/OutboundLoggingInterceptor.java`:

```java
@Component
class OutboundLoggingInterceptor implements ClientHttpRequestInterceptor {

    private static final Logger log = LoggerFactory.getLogger(OutboundLoggingInterceptor.class);

    @Override
    public ClientHttpResponse intercept(HttpRequest request, byte[] body,
                                        ClientHttpRequestExecution execution) throws IOException {
        long start = System.nanoTime();
        try {
            ClientHttpResponse response = execution.execute(request, body);
            log.info("saliente {} {} -> {} en {} ms", request.getMethod(), request.getURI().getPath(),
                    response.getStatusCode().value(), (System.nanoTime() - start) / 1_000_000);
            return response;
        } catch (IOException ex) {
            // el timeout de lectura entra por aquí: no hubo respuesta que loguear
            log.warn("saliente {} {} -> {} en {} ms", request.getMethod(), request.getURI().getPath(),
                    ex.getClass().getSimpleName(), (System.nanoTime() - start) / 1_000_000);
            throw ex;
        }
    }
}
```

- **El interceptor se sitúa por debajo de todo lo demás**: ve la llamada de red real, no la
  invocación del método. Por eso cuenta **intentos**, que es exactamente lo que esta sección
  necesita medir. Un log puesto en `SupplierGateway.quote()` contaría uno por request, y no
  te enterarías de los reintentos.
- **El `catch (IOException)` vuelve a lanzar.** Tragársela convertiría un timeout en un
  `null` y el retry no tendría nada que reintentar: capturar una excepción para que "no
  truene" es el mismo antipatrón que mató el rollback en `L04`, en otra capa.
- **`System.nanoTime()` y no `currentTimeMillis()`** porque mide un intervalo: `nanoTime` es
  monótono y no se mueve si el reloj del sistema se ajusta a mitad de la llamada.
- **Se registra en el `Builder`**, añadiendo `.requestInterceptor(interceptor)` a la
  construcción del `RestClient` en `SupplierGateway` e inyectando el interceptor por
  constructor. Un `@Component` que nadie registra en el cliente no intercepta nada.

Ahora la anotación y la configuración, en `SupplierGateway`:

```java
@Retry(name = "supplier")                 // io.github.resilience4j.retry.annotation.Retry
SupplierQuote quote(String sku) { … }     // el cuerpo no cambia
```

```yaml
resilience4j:
  retry:
    instances:
      supplier:
        max-attempts: 4
        wait-duration: 500ms
        enable-exponential-backoff: true
        exponential-backoff-multiplier: 2
        enable-randomized-wait: false      # a propósito: es el fallo de esta sección
```

- **`@Retry(name = "supplier")`** enlaza el método con la instancia `supplier` del YAML. Si
  el nombre no existe, Resilience4j **crea una instancia con la configuración por defecto**
  en vez de fallar: tres intentos con 500 ms fijos, que no es lo que escribiste. Un `name`
  mal tecleado no se nota, y esa es la trampa.
- **`max-attempts: 4` es el número de llamadas totales**, no el de reintentos: el intento
  original más **tres** más, y ni una cuarta. Eso multiplica por cuatro —no por cinco— el
  tráfico hacia el proveedor, que es justo lo que vas a contar en el journal de WireMock
  dentro de un momento. Quien lo lee como "cuatro reintentos" presupuesta con cinco
  llamadas por petición donde hay cuatro, un 25 % de más, y calcula el tiempo del endpoint
  con un intento que no existe.
- **`wait-duration: 500ms` con `multiplier: 2`** produce esperas de 500 ms, 1 s y 2 s: los
  cuatro intentos caen en los segundos 0, 0,5, 1,5 y 3,5 desde el inicio.
- **`enable-randomized-wait: false` es el bug del día**, escrito explícitamente en vez de
  omitido para que se vea que es una decisión y no un olvido. Es también el default.
- **No hay `retry-exceptions`** todavía, y eso significa **reintentar cualquier excepción**.
  Dentro de tres bloques eso nos va a costar cuatro llamadas por un `sku` inexistente.

Antes de ejecutar, **predice**: seis peticiones simultáneas contra `ERR-000500`, cuatro
intentos cada una. ¿Cuántas llamadas recibe el proveedor y cómo se reparten en el tiempo?

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -X POST localhost:8090/__admin/requests/reset
for i in $(seq 1 6); do curl -s -o /dev/null localhost:8080/api/items/ERR-000500/quote & done
wait
curl -s 'localhost:8090/__admin/requests?limit=500' \
  | jq '[.requests[] | select(.request.url | contains("ERR-000500"))] | length'
grep 'saliente GET /suppliers/ERR-000500' app.log | cut -c12-21 | sort | uniq -c
```

```text
24
      6 11:04:12.4
      6 11:04:12.9
      6 11:04:13.9
      6 11:04:15.9
```

- **24 llamadas por 6 peticiones.** Seis por cuatro, y el proveedor que ya estaba en
  problemas acaba de recibir **cuatro veces más tráfico** justo cuando peor le venía. Esa
  multiplicación es el primer dato que hay que poder decir en voz alta cuando alguien
  propone "subir los reintentos a cinco".
- **Los cuatro bloques de seis son el ariete.** Sin jitter, los seis clientes fallaron a la
  vez, esperaron exactamente lo mismo y volvieron a la vez. Si el proveedor se recupera en
  el segundo 13, recibe seis peticiones simultáneas en el 13,9 y se vuelve a caer: **tu
  retry le impide levantarse**, que es el aviso de
  [`19` §3](19-resiliencia.md#3--retry-cuándo-ayuda-y-cuándo-empeora-la-caída) con números
  propios. Con seiscientos clientes en vez de seis, el patrón es idéntico y el proveedor no
  vuelve.
- **`cut -c12-21`** recorta la línea de log de Boot desde el carácter 12 —justo después de
  `2026-09-18T`— hasta la décima de segundo. Es el histograma más barato que existe: `sort`
  agrupa, `uniq -c` cuenta.
- **`?limit=500` en el journal** importa: por defecto WireMock devuelve las últimas
  peticiones y con tandas grandes te deja fuera las primeras, así que el conteo saldría
  corto y parecería que el retry no actuó.

Ahora una variable a la vez. Enciende el jitter y **no toques nada más**:

```yaml
resilience4j:
  retry:
    instances:
      supplier:
        enable-randomized-wait: true
        randomized-wait-factor: 0.5        # cada espera sale de [50 %, 150 %] de la nominal
```

- **`randomized-wait-factor: 0.5`** define la amplitud: con espera nominal de 1 s, la real
  cae uniformemente entre 500 ms y 1,5 s. Con `0.0` no hay aleatoriedad —es el caso
  anterior— y con valores cercanos a `1.0` la espera mínima tiende a cero, lo que devuelve
  parte de la sincronía porque muchos clientes reintentan casi de inmediato.
- **El jitter no reduce el número de llamadas**, y esto se malentiende siempre: siguen
  siendo 24. Lo que cambia es **cuándo** llegan, y con eso basta para que el proveedor tenga
  huecos por los que respirar.

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -X POST localhost:8090/__admin/requests/reset
for i in $(seq 1 6); do curl -s -o /dev/null localhost:8080/api/items/ERR-000500/quote & done
wait
curl -s 'localhost:8090/__admin/requests?limit=500' \
  | jq '[.requests[] | select(.request.url | contains("ERR-000500"))] | length'
grep 'saliente GET /suppliers/ERR-000500' app.log | cut -c12-21 | sort | uniq -c
```

```text
24
      6 11:09:31.2
      2 11:09:31.5
      1 11:09:31.6
      2 11:09:31.7
      1 11:09:31.9
      1 11:09:32.4
      2 11:09:32.6
      1 11:09:32.8
      1 11:09:33.1
      1 11:09:33.3
      2 11:09:34.1
      1 11:09:34.6
      1 11:09:35.2
      1 11:09:35.8
      1 11:09:36.3
```

- **El primer bloque sigue teniendo seis**, y es la parte que casi nadie anticipa: el jitter
  **no separa el primer intento**, porque los seis clientes llegaron juntos por su cuenta.
  Solo desincroniza lo que tú controlas, que son los reintentos.
- **Los 18 reintentos se reparten en cinco segundos** en grupos de uno y de dos, en vez de
  caer en tres martillazos de seis. Esa es toda la diferencia entre un retry que ayuda y uno
  que impide la recuperación, y ahora la tienes medida en tu propia máquina.
- **Los dos experimentos son comparables porque cambió una sola propiedad.** Si además
  hubieras tocado `max-attempts`, el conteo se movería y no sabrías cuál de los dos cambios
  explica qué. Una variable a la vez, siempre.

Falta el segundo fallo de esta sección, que es más barato de cometer: **reintentar lo que
nunca va a cambiar de opinión**. Pide un `sku` que el proveedor no conoce y cuenta.

```bash
curl -s -X POST localhost:8090/__admin/requests/reset
curl -s -o /dev/null -w '%{http_code} en %{time_total}s\n' localhost:8080/api/items/ABC-000999/quote
curl -s 'localhost:8090/__admin/requests?limit=500' \
  | jq '[.requests[] | select(.request.url | contains("ABC-000999"))] | length'
```

```text
500 en 3.541218s
4
```

- **Cuatro llamadas por un 404.** El `sku` no existe y no va a existir dentro de dos
  segundos: los tres reintentos son gasto puro, tuyo y del proveedor. Y ese `sku` tiene que
  estar en tu base para llegar hasta aquí, así que el caso real es más común de lo que
  parece: alguien dio de alta un producto que el proveedor todavía no publicó.
- **El `500` hacia tu cliente es doblemente incorrecto**: el proveedor dijo `404`, que es
  información útil, y tú la conviertes en "algo se rompió". El arreglo de la traducción es
  de [`13` §6](13-clientes-http.md#6--errores-un-4xx-no-es-un-fallo-de-red) y se aplica
  abajo.
- **3,5 segundos de latencia para no dar ningún dato.** Si tu endpoint prometía responder en
  dos segundos, el retry acaba de incumplir el contrato **para no aportar nada**.

La corrección tiene dos mitades, y las dos van juntas:

```yaml
resilience4j:
  retry:
    instances:
      supplier:
        max-attempts: 3
        wait-duration: 200ms
        enable-exponential-backoff: true
        exponential-backoff-multiplier: 2
        enable-randomized-wait: true
        randomized-wait-factor: 0.5
        retry-exceptions:
          - org.springframework.web.client.ResourceAccessException
          - org.springframework.web.client.HttpServerErrorException
```

```java
SupplierQuote quote(String sku) {
    return restClient.get()
            .uri("/suppliers/{sku}/quote", sku)
            .retrieve()
            .onStatus(status -> status.value() == 404,
                    (req, res) -> { throw new UnknownSupplierSkuException(sku); })
            .body(SupplierQuote.class);
}
```

- **`retry-exceptions` es una lista blanca**: con ella, solo se reintenta lo que puede
  cambiar de resultado. `ResourceAccessException` es transporte —timeout, socket cerrado,
  DNS— y `HttpServerErrorException` es un 5xx del otro. Todo lo demás, incluidos los 4xx,
  falla al primer intento.
- **`HttpClientErrorException` no está en la lista, y esa ausencia es la corrección.** Su
  hermana `ignore-exceptions` existe para el caso inverso —lista negra sobre un `retry-exceptions`
  amplio— y aquí no hace falta: es más seguro enumerar lo que sí se reintenta.
- **`onStatus` convierte el 404 en una excepción tuya** antes de que el retry la vea. Es
  doble protección: aunque alguien amplíe la lista blanca mañana,
  `UnknownSupplierSkuException` no está en ella.
- **`max-attempts` baja de 4 a 3 y `wait-duration` de 500 a 200 ms**, y aquí está el
  porqué que casi nunca se escribe: con `read-timeout: 3s`, cuatro intentos más 3,5 s de
  backoff podían tardar **15,5 segundos**. Con tres intentos y esperas de 200 y 400 ms, el
  peor caso baja a unos 9,6 s. Sigue siendo mucho para un endpoint de dos segundos, y esa
  incomodidad es intencional: la resuelve el circuito de la sección 5, que hace que el peor
  caso deje de existir.

Registra el 404 en el advice de `L03` para cerrar el contrato hacia fuera:

```java
@ExceptionHandler(UnknownSupplierSkuException.class)
ProblemDetail handleUnknownSupplierSku(UnknownSupplierSkuException ex) {
    ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.BAD_GATEWAY, "el proveedor no conoce el sku " + ex.sku());
    problem.setTitle("Sku desconocido para el proveedor");
    return problem;
}
```

- **`502 Bad Gateway` y no `404`**, porque tu item **sí** existe: el que no lo conoce es el
  proveedor. Devolver `404` mentiría sobre tu propio recurso y haría que el cliente borrara
  algo que tiene stock.
- **El `ProblemDetail` es el mismo mecanismo de `L03`** y no hay que configurar nada nuevo:
  el advice ya extiende `ResponseEntityExceptionHandler` y el `@ExceptionHandler` se suma a
  los que ya había.

Verifica la corrección con el mismo comando de antes:

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -X POST localhost:8090/__admin/requests/reset
curl -s -o /dev/null -w '%{http_code} en %{time_total}s\n' localhost:8080/api/items/ABC-000999/quote
curl -s 'localhost:8090/__admin/requests?limit=500' \
  | jq '[.requests[] | select(.request.url | contains("ABC-000999"))] | length'
```

```text
502 en 0.098233s
1
```

- **Una llamada, 98 milisegundos, y un código que dice la verdad.** El mismo escenario que
  antes costaba cuatro llamadas y 3,5 segundos.

> **⏱️ Costo en runtime.** Un retry no es gratis para ti tampoco: **el hilo del request
> sigue ocupado durante todos los intentos y todos los backoffs**, porque
> `@Retry` es sincrónico y corre en el hilo del llamante. Tres intentos con `read-timeout`
> de 3 s son hasta 9,6 s de hilo retenido por petición. Reintentar es gastar tu capacidad
> para comprar la probabilidad de que el otro se recupere; el circuit breaker existe para
> dejar de comprarla cuando ya no vale nada.

---

## 5. 🩺 El circuito que abre de verdad

El retry te defiende de un fallo puntual. Lo que tienes delante desde hace veinte minutos
no es puntual: `ERR-000500` falla **siempre**, y cada petición gasta tres intentos y hasta
nueve segundos de hilo para llegar a la misma conclusión. Eso es lo que corta el circuit
breaker.

```yaml
resilience4j:
  circuitbreaker:
    instances:
      supplier:
        register-health-indicator: true
        sliding-window-type: COUNT_BASED
        sliding-window-size: 10
        minimum-number-of-calls: 5
        failure-rate-threshold: 50
        slow-call-duration-threshold: 1s
        slow-call-rate-threshold: 50
        wait-duration-in-open-state: 10s
        permitted-number-of-calls-in-half-open-state: 2
        automatic-transition-from-open-to-half-open-enabled: true
```

- **`sliding-window-size: 10` con `COUNT_BASED`** decide mirando las últimas diez llamadas.
  La alternativa, `TIME_BASED`, mira los últimos N segundos y es mejor con tráfico irregular
  porque no arrastra resultados viejos; aquí interesa `COUNT_BASED` porque queremos contar
  llamadas a mano y que los números cuadren.
- **`minimum-number-of-calls: 5`** impide que dos fallos abran el circuito en un servicio
  con poco tráfico. Es la diferencia entre un breaker y un interruptor nervioso.
- **`failure-rate-threshold: 50`** es un **porcentaje**, no un conteo: con cinco llamadas y
  tres fallos, la tasa es 60 % y abre.
- **`slow-call-duration-threshold: 1s` con `slow-call-rate-threshold: 50` es la mitad
  olvidada del patrón**, y la vas a usar al final de esta sección: una llamada que tarda más
  de un segundo cuenta como fallo **aunque devuelva `200`**. Sin esto, el proveedor de
  `SLW-000002` nunca abriría el circuito, y es el que más daño hace.
- **`wait-duration-in-open-state: 10s`** son diez segundos de circuito abierto antes de
  probar otra vez. En producción se parece más a 30 s o a un minuto; aquí son diez para que
  el lab quepa en una sesión y puedas ver el `HALF_OPEN` sin irte a por un café.
- **`automatic-transition-from-open-to-half-open-enabled: true`** hace que el paso a
  `HALF_OPEN` ocurra solo, con un hilo programado, en vez de esperar a que llegue una
  llamada. Sin él, un circuito abierto en un servicio sin tráfico se queda abierto
  indefinidamente y el `/actuator/circuitbreakers` te miente sobre el estado real.
- **`register-health-indicator: true`** añade el circuito a `/actuator/health`. Ojo con el
  efecto secundario, que sorprende: **un circuito abierto pone el health en `DOWN`**, y si
  tu orquestador reinicia por health, acabas reiniciando tu servicio porque el de otro está
  caído. Se controla con `allow-health-indicator-to-fail: false`.

La anotación va encima de la que ya estaba:

```java
@CircuitBreaker(name = "supplier")        // io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker
@Retry(name = "supplier")                 // el orden de las líneas NO decide el apilado
SupplierQuote quote(String sku) { … }
```

- **El orden en que escribes las anotaciones no cambia nada.** Quien decide el apilado es el
  `order` de cada aspecto, no la posición en el fichero — y eso es toda la sección 6.
- **Los dos comparten el nombre `supplier`** y aun así son instancias distintas: una del
  registro de retries y otra del de circuit breakers. Reutilizar el nombre es la convención
  que hace legible la configuración.

Y añade los endpoints nuevos a la lista blanca de Actuator:

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,env,configprops,metrics,threaddump,circuitbreakers,circuitbreakerevents,retryevents
```

- **`circuitbreakers` da el estado actual** y **`circuitbreakerevents` da la historia**: qué
  pasó, en qué orden y con qué error. Los dos los publica Resilience4j, no Boot, y por eso
  no aparecen si falta la librería.
- **`retryevents` es el equivalente para los reintentos** y te ahorra el `grep` de la
  sección 4 cuando solo quieres contar.

Arranca, y **predice antes de ejecutar**: ocho peticiones seguidas contra `ERR-000500`, con
tres intentos cada una. ¿Cuál es la primera que ve el circuito abierto?

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -X POST localhost:8090/__admin/requests/reset
for i in $(seq 1 8); do
  curl -s -o /dev/null -w "$i:%{http_code}:%{time_total}\n" localhost:8080/api/items/ERR-000500/quote
done
curl -s localhost:8081/actuator/circuitbreakers | jq -c '.circuitBreakers.supplier'
```

```text
1:500:0.612913
2:500:0.608204
3:500:0.004518
4:500:0.003911
5:500:0.003874
6:500:0.004102
7:500:0.004233
8:500:0.004017
{"failureRate":"100.0%","slowCallRate":"-1.0%","bufferedCalls":5,"failedCalls":5,"notPermittedCalls":7,"state":"OPEN"}
```

- **Las dos primeras tardan 600 ms y las seis siguientes cuatro milisegundos.** Ese salto es
  el circuito abriéndose, y es visible sin leer una sola línea de log: **el fallo pasó de
  costar tres llamadas de red a no costar ninguna**.
- **`state: OPEN` y `notPermittedCalls: 7`.** Siete invocaciones ni siquiera salieron a la
  red —el tercer intento de la petición 2 y las seis peticiones siguientes—. Eso es
  exactamente lo que salva tus hilos y lo que le da aire al proveedor para recuperarse.
- **`bufferedCalls: 5` y el circuito abierto en la segunda petición** es el detalle que hay
  que apuntar, y es el puente a la sección 6: el breaker registró **un fallo por cada
  intento del retry**, no uno por petición. Cinco intentos le bastaron para alcanzar
  `minimum-number-of-calls` y decidir. Ese número va a cambiar cuando inviertas el orden.
- **`slowCallRate: -1.0%`** no es un error de lectura: Resilience4j usa `-1` para "todavía no
  hay datos suficientes para calcularlo". Verlo y asumir un porcentaje negativo de llamadas
  lentas es un clásico de diagnóstico.

Ahora la excepción, que es la que hay que reconocer en un log ajeno:

```bash
grep -m1 'CallNotPermittedException' app.log
```

```text
io.github.resilience4j.circuitbreaker.CallNotPermittedException: CircuitBreaker 'supplier' is OPEN and does not permit further calls
```

- **`CallNotPermittedException` no la lanza el proveedor: la lanza tu propio proceso**, sin
  tocar la red. Quien la ve por primera vez en un log de producción suele buscar el problema
  en la red o en el otro servicio, y el problema está —correctamente— en tu decorador.
- **Es una `RuntimeException`**, así que se propaga por el mismo camino que cualquier otra y
  la recoge tu `@RestControllerAdvice`.

Y la historia completa, que es el endpoint que casi nadie conoce y el que convierte una
discusión en un dato:

```bash
curl -s localhost:8081/actuator/circuitbreakerevents/supplier \
  | jq -r '.circuitBreakerEvents[] | "\(.creationTime[11:23]) \(.type) \(.stateTransition // .errorMessage // "")"' \
  | tail -10
```

```text
11:31:02.104 ERROR org.springframework.web.client.HttpServerErrorException$InternalServerError: 500 Server Error: [{"error":"upstream pricing engine unavailable"}]
11:31:02.711 ERROR org.springframework.web.client.HttpServerErrorException$InternalServerError: 500 Server Error: [{"error":"upstream pricing engine unavailable"}]
11:31:02.712 FAILURE_RATE_EXCEEDED
11:31:02.713 STATE_TRANSITION CLOSED_TO_OPEN
11:31:02.717 NOT_PERMITTED
11:31:02.721 NOT_PERMITTED
11:31:12.714 STATE_TRANSITION OPEN_TO_HALF_OPEN
11:31:18.402 SUCCESS
11:31:18.559 SUCCESS
11:31:18.560 STATE_TRANSITION HALF_OPEN_TO_CLOSED
```

- **Los tres estados de [`19` §5](19-resiliencia.md#5--circuit-breaker-dejar-de-insistir-sobre-lo-que-está-roto)
  están ahí, con hora.** `CLOSED_TO_OPEN` a las 11:31:02, `OPEN_TO_HALF_OPEN` exactamente
  diez segundos después —el `wait-duration-in-open-state`— y `HALF_OPEN_TO_CLOSED` cuando
  las dos llamadas de prueba salieron bien.
- **`FAILURE_RATE_EXCEEDED` precede a la transición** y es el evento que explica *por qué*
  abrió. Cuando el circuito abre sin que nadie entienda la razón, este evento es la
  respuesta.
- **Las dos `SUCCESS` de las 11:31:18** son las llamadas de prueba del `HALF_OPEN`, y son
  las dos que permite `permitted-number-of-calls-in-half-open-state`. Para producirlas basta
  con pedir un `sku` sano después de los diez segundos: el circuito es **uno por instancia,
  no uno por `sku`**, así que cualquier llamada al proveedor sirve de prueba.
- **`.creationTime[11:23]`** recorta la marca ISO a `HH:mm:ss.SSS`. Es un *slice* de cadena
  de `jq`, no un rango de líneas.
- **Si las de prueba hubieran fallado**, verías `STATE_TRANSITION HALF_OPEN_TO_OPEN` y otros
  diez segundos de espera. Provócalo: pide `ERR-000500` en el segundo 11.

Falta traducir esto hacia fuera, porque un `500` opaco no sirve a nadie:

```java
@ExceptionHandler(CallNotPermittedException.class)
ProblemDetail handleCircuitOpen(CallNotPermittedException ex) {
    ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.SERVICE_UNAVAILABLE, "el proveedor no está disponible; reintenta en unos segundos");
    problem.setTitle("Proveedor no disponible");
    problem.setProperty("retryAfterSeconds", 10);
    return problem;
}
```

- **`503` y no `500`:** el `500` dice "me rompí" y el `503` dice "no puedo ahora, vuelve".
  Con el circuito abierto la segunda es literalmente cierta, y además es la única de las dos
  que un cliente bien escrito sabe reintentar.
- **`setProperty("retryAfterSeconds", 10)`** añade un campo al cuerpo `ProblemDetail`. La
  cabecera `Retry-After` de HTTP sería aún mejor y exige devolver `ResponseEntity` en vez de
  `ProblemDetail`; el ejercicio 12 la pide.
- **No se pone `fallbackMethod` todavía** y es deliberado: propagar un `503` rápido es una
  respuesta honesta, y a veces la correcta. El fallback llega en la sección 7, con su
  discusión sobre cuándo mentir es peor que fallar.

Queda la trampa que más servicios se comen: **el proveedor que no falla**.

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
for i in $(seq 1 8); do
  curl -s -o /dev/null -w "$i:%{http_code}:%{time_total}\n" localhost:8080/api/items/SLW-000002/quote
done
curl -s localhost:8081/actuator/circuitbreakers | jq -c '.circuitBreakers.supplier'
```

```text
1:200:2.041288
2:200:2.032907
3:200:2.028441
4:200:2.031655
5:200:2.029118
6:503:0.005992
7:503:0.006114
8:503:0.005781
{"failureRate":"-1.0%","slowCallRate":"100.0%","bufferedCalls":5,"failedCalls":0,"notPermittedCalls":3,"state":"OPEN"}
```

- **`failedCalls: 0` y el circuito abierto.** No hubo ni un error: las cinco llamadas
  devolvieron `200` con su JSON correcto. Lo que las condenó fue tardar 2 segundos contra un
  `slow-call-duration-threshold` de 1 s.
- **Este es el caso de [`19` §1](19-resiliencia.md#1--el-problema-el-fallo-parcial-y-la-latencia-como-fallo)
  ejecutado**: la latencia como fallo. Sin `slow-call-rate-threshold`, estas cinco llamadas
  habrían dejado el circuito cerrado para siempre y `inv-api` habría seguido regalando dos
  segundos de hilo por petición hasta quedarse sin ninguno.
- **`failureRate: -1.0%` y `slowCallRate: 100.0%`** son los dos indicadores intercambiando
  papeles respecto del experimento anterior. Leer solo `failureRate` en un tablero es como
  leer solo la mitad del patrón.

> **⚠️ Un circuito que abre sin que nadie se entere es peor que no tenerlo.** Los `503` de
> arriba no aparecen como errores del proveedor en ningún tablero: aparecen como errores
> **tuyos**, o ni siquiera aparecen si hay fallback. La alerta sobre `STATE_TRANSITION` es
> parte del patrón, no un extra, y se monta en `L07` cuando haya Prometheus leyendo
> `resilience4j_circuitbreaker_state`.

---

## 6. ⚖ El orden de los decoradores, invertido a propósito

Tienes `@Retry` y `@CircuitBreaker` sobre el mismo método. La pregunta que casi nadie se
hace —y que en una entrevista de Tech Lead sí te van a hacer— es cuál envuelve a cuál, y
qué se rompe al revés. [`19` §7](19-resiliencia.md#7--el-orden-en-que-se-apilan) te dio el
diagrama; hoy lo cuentas.

```text
orden A (el correcto)   Retry( CircuitBreaker( llamada ))
                        el retry reintenta llamadas que pasan por el breaker

orden B (el invertido)  CircuitBreaker( Retry( llamada ))
                        el breaker ve UNA llamada que por dentro hizo tres
```

El apilado no lo decide el orden en que escribes las anotaciones: lo decide el `order` de
cada aspecto, y se configura. Escríbelo explícito aunque coincida con el default, porque
esta sección consiste en cambiarlo:

```yaml
resilience4j:
  retry:
    retry-aspect-order: 1                 # menor order = más AFUERA
  circuitbreaker:
    circuit-breaker-aspect-order: 2
```

- **Las dos propiedades cuelgan de la sección, no de `instances`**: son globales al aspecto,
  no por instancia. Ponerlas dentro de `instances.supplier` no da error y no hace nada, que
  es la peor combinación posible.
- **Menor `order` significa más afuera**, porque son aspectos de Spring y se ordenan con la
  regla de `Ordered` de siempre: menor valor, mayor precedencia, más cerca del borde. Con
  `retry-aspect-order: 1` el retry envuelve al breaker.
- **Estos valores reproducen el default de Resilience4j**, que ya apila en el orden correcto.
  Escribirlos no cambia el comportamiento de hoy; sirve para que mañana alguien que lea el
  YAML sepa que hubo una decisión, y para poder invertirla en tres segundos.

Mide el orden A con ocho peticiones seguidas contra el proveedor roto, contando **las dos
cosas a la vez**: lo que llegó al proveedor y lo que registró el breaker.

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -X POST localhost:8090/__admin/requests/reset
for i in $(seq 1 8); do
  curl -s -o /dev/null -w "$i:%{http_code}:%{time_total}\n" localhost:8080/api/items/ERR-000500/quote
done
echo "--- llamadas que recibió el proveedor:"
curl -s 'localhost:8090/__admin/requests?limit=500' \
  | jq '[.requests[] | select(.request.url | contains("ERR-000500"))] | length'
echo "--- fallos que registró el breaker:"
curl -s localhost:8081/actuator/circuitbreakerevents/supplier \
  | jq '[.circuitBreakerEvents[] | select(.type == "ERROR")] | length'
```

```text
1:500:0.612913
2:500:0.608204
3:503:0.004518
4:503:0.003911
5:503:0.003874
6:503:0.004102
7:503:0.004233
8:503:0.004017
--- llamadas que recibió el proveedor:
5
--- fallos que registró el breaker:
5
```

- **Cinco llamadas al proveedor por ocho peticiones**, y el circuito abierto desde la
  segunda. Cada intento del retry atraviesa el breaker, así que los tres intentos de la
  primera petición y los dos primeros de la segunda suman los cinco que
  `minimum-number-of-calls` exigía.
- **En cuanto abrió, el propio retry dejó de salir a la red**: el tercer intento de la
  petición 2 recibió `CallNotPermittedException` y, como no está en `retry-exceptions`, no
  se reintentó. Reintentar rápido y en local cuesta microsegundos; eso es lo que quieres.
- **Llamadas al proveedor = fallos del breaker = 5.** En el orden A los dos números son el
  mismo, y ese es el rasgo que lo identifica.

Ahora invierte **una sola cosa** y repite el experimento sin tocar nada más:

```yaml
resilience4j:
  retry:
    retry-aspect-order: 2                 # ahora el retry queda por DENTRO
  circuitbreaker:
    circuit-breaker-aspect-order: 1       # y el breaker por fuera
```

```text
1:500:0.612913
2:500:0.609441
3:500:0.611002
4:500:0.607718
5:500:0.610244
6:503:0.005881
7:503:0.004993
8:503:0.005107
--- llamadas que recibió el proveedor:
15
--- fallos que registró el breaker:
5
```

- **Quince llamadas al proveedor, tres veces más que antes**, para llegar a la misma
  conclusión. El breaker sigue registrando cinco fallos porque ahora ve **una** llamada por
  petición: lo que ocurre dentro del retry le es invisible.
- **El circuito abrió en la quinta petición en vez de en la segunda.** Necesita cinco
  llamadas registradas y ahora cada petición aporta una sola, así que tarda dos veces y
  media más en protegerte — y el proveedor caído se come quince peticiones mientras tanto.
- **Las cinco primeras peticiones tardan 600 ms cada una**, contra las dos del orden A. La
  diferencia en latencia percibida por el usuario es pequeña; la diferencia en carga sobre
  un servicio que se está cayendo es de un factor `max-attempts`.
- **Y el detalle que lo vuelve indefendible:** con el circuito abierto, el retry ya no
  existe como amortiguador, porque está **dentro**. La petición 6 recibe
  `CallNotPermittedException` del aspecto exterior y se acabó — que aquí da igual, pero
  significa que ninguna de las dos capas está haciendo el trabajo que creías haberle
  asignado.

| | **Orden A** — `Retry(CircuitBreaker(…))` | **Orden B** — `CircuitBreaker(Retry(…))` |
|---|---|---|
| Llamadas al proveedor (8 peticiones) | **5** | **15** |
| Fallos registrados por el breaker | 5 (uno por intento) | 5 (uno por petición) |
| El circuito abre en la petición | **2** | 5 |
| Qué hace el retry con el circuito abierto | falla rápido, sin red | no llega a ejecutarse |

> **📝 La aritmética sorprende, y conviene precisarla.** La intuición dice que el orden
> invertido hace que el breaker cuente de más; lo que se mide es lo contrario: **es el orden
> recomendado el que registra un fallo por cada intento del retry**, y por eso el circuito
> abre antes de lo que sugeriría una lectura ingenua de `minimum-number-of-calls`. Ese
> adelanto no es un defecto: es la protección llegando a tiempo. El aviso de `19` §7 —"el
> circuito abre más rápido de lo que creías configurar"— describe exactamente este efecto, y
> hoy sabes en qué orden ocurre porque lo contaste tú. Si en una entrevista te preguntan por
> el orden, la respuesta corta no es "el breaker cuenta tres veces": es **"el retry va por
> fuera para que reintentar sea barato cuando el circuito está abierto, y el precio es que
> el breaker cuenta intentos, no peticiones — hay que ajustar `minimum-number-of-calls`
> sabiéndolo"**.

Deja el orden A puesto antes de seguir. Y hay una tercera capa que no vas a apilar hoy y
que conviene nombrar: **`@Transactional` no debe quedar por fuera de ninguna de las dos**.
Un retry que envuelve una transacción abierta retiene la conexión de Hikari durante todos
los backoffs, que es el agotamiento de pool de
[`L04` §7](l04-datos-y-transacciones.md#7-️-requires_new-y-el-deadlock-de-pool) con otro
disfraz. En `inv-api` no pasa porque la llamada saliente vive fuera de la transacción desde
la sección 3, y eso fue una decisión, no una casualidad.

---

## 7. 🧱 Bulkhead saturado, y el fallback honesto

Queda el escenario que ni el timeout ni el circuito resuelven: el proveedor **lento pero
correcto**. Responde en dos segundos, siempre, sin un solo error. Tu `read-timeout` de 3 s
no dispara, tu circuito puede abrir por llamadas lentas pero mientras tanto cada petición
te cuesta dos segundos de hilo, y con cincuenta peticiones concurrentes te quedas sin
ninguno para los endpoints que ni tocan al proveedor.

Eso es lo que limita un bulkhead: **cuántas llamadas concurrentes como máximo hacia esta
dependencia**, y ni una más.

```yaml
resilience4j:
  bulkhead:
    instances:
      supplier:
        max-concurrent-calls: 3
        max-wait-duration: 0
  circuitbreaker:
    instances:
      supplier:
        slow-call-duration-threshold: 5s   # TEMPORAL: aísla la variable de esta sección
```

- **`max-concurrent-calls: 3`** es un semáforo con tres permisos. Es el bulkhead **por
  semáforo**, que limita concurrencia en el hilo del llamante; el otro tipo,
  `thread-pool-bulkhead`, ejecuta en su propio pool y aísla más, a cambio de perder el
  `ThreadLocal` del request —incluido el `SecurityContext` de [`20` §6](20-spring-security-el-mecanismo.md#6--securitycontextholder-un-threadlocal-y-sus-dos-fugas) y el request id de
  `L03`— porque el trabajo cambia de hilo ([`08` §8](08-modelo-de-ejecucion-web.md#8--threadlocal-el-contexto-que-viaja-pegado-al-hilo)).
- **`max-wait-duration: 0`** significa **no esperar**: si no hay permiso libre, falla de
  inmediato. Con un valor mayor que cero, las peticiones sobrantes hacen cola —y una cola es
  otra forma de retener hilos—. Cero es la opción honesta para una dependencia en línea;
  esperar tiene sentido cuando el pico es corto y conocido.
- **El `slow-call-duration-threshold: 5s` es temporal y está declarado como tal.** Con el
  valor real de 1 s, el circuito de la sección 5 abriría a mitad del experimento y no
  sabrías cuál de los dos mecanismos produjo cada rechazo. Una variable a la vez, y se
  devuelve a su sitio al terminar la sección.

La anotación se suma a las dos que ya hay:

```java
@CircuitBreaker(name = "supplier")
@Retry(name = "supplier")
@Bulkhead(name = "supplier")              // io.github.resilience4j.bulkhead.annotation.Bulkhead
SupplierQuote quote(String sku) { … }
```

- **`@Bulkhead` sin `type`** usa `Type.SEMAPHORE`, que es el default. `Type.THREADPOOL`
  exige que el método devuelva `CompletableFuture`, y ponerlo sobre un método sincrónico
  falla en el arranque.
- **El bulkhead queda por dentro de todo** con los `order` por defecto, y eso es lo correcto
  ([`19` §7](19-resiliencia.md#7--el-orden-en-que-se-apilan)): mide la concurrencia real
  contra la dependencia, no la de los reintentos.

Predice: diez peticiones simultáneas contra `SLW-000002`, tres permisos. ¿Cuántas responden
`200`, cuánto tarda cada grupo y qué marca `tomcat.threads.busy`?

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
for i in $(seq 1 10); do
  curl -s -o /dev/null -w "$i:%{http_code}:%{time_total}\n" localhost:8080/api/items/SLW-000002/quote &
done
sleep 1
curl -s localhost:8081/actuator/metrics/tomcat.threads.busy | jq -c '.measurements'
wait
grep -c 'BulkheadFullException' app.log
```

```text
4:500:0.021554
6:500:0.022110
7:500:0.023004
8:500:0.021877
9:500:0.024119
10:500:0.022650
5:500:0.023991
[{"statistic":"VALUE","value":10.0}]
1:200:2.048812
2:200:2.051093
3:200:2.049775
7
```

- **Tres respuestas `200` a los dos segundos y siete rechazos inmediatos.** El bulkhead hizo
  exactamente lo que le pediste: la dependencia recibe como mucho tres llamadas a la vez.
- **`tomcat.threads.busy` marca `10.0` igual que antes, y esto es lo que hay que entender
  bien**: el bulkhead **no libera el hilo de Tomcat** de las siete rechazadas, solo hace que
  terminen en 20 ms en vez de en 2 segundos. Protege a la **dependencia** y acorta la
  ocupación; no es un límite de concurrencia de tu servidor. Quien espere que baje el número
  de hilos ocupados está midiendo el mecanismo equivocado.
- **Los rechazos salen desordenados en la terminal** porque los diez `curl` corren en
  paralelo y escriben al terminar. El orden de las líneas no significa nada; los tiempos sí.

La excepción, literal:

```bash
grep -m1 'BulkheadFullException' app.log
```

```text
io.github.resilience4j.bulkhead.BulkheadFullException: Bulkhead 'supplier' is full and does not permit further calls
```

- **Igual que `CallNotPermittedException`, la lanza tu proceso**, no el proveedor. Las dos
  se parecen tanto en el log que conviene fijarse en el sustantivo: `Bulkhead` es "hay
  demasiadas a la vez", `CircuitBreaker` es "están fallando demasiadas".
- **Merece su `503`** en el advice, con el mismo criterio de la sección 5: tu servicio está
  saturado hacia esa dependencia, y eso es temporal por definición.

Y ahora la pregunta incómoda: siete usuarios recibieron un error **porque tú decidiste
limitar**. ¿Es esa la mejor respuesta que puedes darles?

Aquí entra el fallback, y aquí es donde la mayoría de los servicios se rompen en silencio.
Guarda la última cotización buena para poder ofrecerla cuando no haya otra cosa.

```sql
-- src/main/resources/db/migration/V2__add_last_quote_columns.sql
ALTER TABLE inventory_item ADD COLUMN last_quoted_price NUMERIC(12,2);
ALTER TABLE inventory_item ADD COLUMN last_quoted_at    TIMESTAMPTZ;
```

- **Las dos columnas admiten `NULL`** porque un item recién creado no tiene cotización. Un
  `NOT NULL` con default `0` sería justo el tipo de dato mentiroso que esta sección combate.
- **`NUMERIC(12,2)` y no `DOUBLE PRECISION`** para un precio: el binario en coma flotante no
  representa exactamente `12.50` y en banca eso se paga en una reconciliación.
- **`TIMESTAMPTZ` y no `TIMESTAMP`** para que la hora lleve zona: un fallback tiene que poder
  decir *cuándo* es válido el dato que devuelve, y sin zona no se puede comparar con nada.
- **Si hiciste el ejercicio 1 de `L04`**, ya tienes una `V2__` y esta pasa a ser `V3__`. El
  orden lo decide el número, no el contenido, y Flyway se niega a arrancar con dos versiones
  iguales.

Dos columnas vacías no degradan nada: alguien tiene que escribirlas. Primero la entidad de
`L04` aprende a recordar su última cotización:

```java
// en InventoryItem, la entidad de L04
@Column(name = "last_quoted_price", precision = 12, scale = 2)
private BigDecimal lastQuotedPrice;

@Column(name = "last_quoted_at")
private Instant lastQuotedAt;

// las dos juntas o ninguna: un precio sin su fecha no se puede evaluar como rancio
void recordQuote(BigDecimal price, Instant quotedAt) {
    this.lastQuotedPrice = price;
    this.lastQuotedAt = quotedAt;
}

BigDecimal lastQuotedPrice() { return lastQuotedPrice; }
Instant lastQuotedAt()       { return lastQuotedAt; }
```

- **`@Column(name = ...)` explícito** porque el nombre de la columna lo fijó la migración y
  no la convención de Hibernate. Y con `ddl-auto: validate` de
  [`L04` §2](l04-datos-y-transacciones.md#2--postgres-en-compose-flyway-y-el-teardown), un
  nombre o un tipo que no casen rompen el **arranque**, no la primera consulta: es el único
  error de esta sección que sí se descubre al desplegar.
- **`precision = 12, scale = 2` repite lo que dice el `NUMERIC(12,2)` de la migración.**
  Repetirlo no crea nada —el esquema ya existe— pero es lo que `validate` compara; escribir
  `BigDecimal` a secas pasa igual, y el día que alguien active `ddl-auto: update` en otro
  entorno obtendrás una columna con la escala por defecto.
- **`Instant` para el `TIMESTAMPTZ`**, no `LocalDateTime`: `Instant` es un punto en la línea
  del tiempo y sobrevive a un cambio de zona del servidor, que es justo lo que el fallback
  necesita poder afirmar.
- **Sin `nullable = false` y sin valor inicial**, coherente con la migración: un item sin
  cotizar tiene `null`, y ese `null` es el que decide más abajo si hay algo que degradar.

Y el gateway guarda la cotización buena en cuanto llega, que es el único punto por el que
pasan todas:

```java
@Service
class SupplierGateway {

    private final RestClient restClient;
    private final InventoryItemRepository repository;      // nuevo: el respaldo vive en la base

    SupplierGateway(RestClient.Builder builder, SupplierProperties properties,
                    OutboundLoggingInterceptor interceptor, InventoryItemRepository repository) {
        this.restClient = builder.baseUrl(properties.baseUrl())
                .requestInterceptor(interceptor)
                .build();
        this.repository = repository;
    }

    @CircuitBreaker(name = "supplier")
    @Retry(name = "supplier")
    @Bulkhead(name = "supplier")                           // el fallbackMethod llega dos bloques más abajo
    SupplierQuote quote(String sku) {
        SupplierQuote quote = restClient.get()
                .uri("/suppliers/{sku}/quote", sku)
                .retrieve()
                .body(SupplierQuote.class);
        remember(quote);                                   // el respaldo de la próxima caída
        return quote;
    }

    // privado y sin @Transactional, y las dos cosas a propósito: ver el desglose
    private void remember(SupplierQuote quote) {
        repository.findBySku(quote.sku()).ifPresent(item -> {
            item.recordQuote(quote.price(), quote.quotedAt());
            repository.save(item);
        });
    }
}
```

- **El constructor gana un cuarto parámetro y no lleva `@Autowired`**: sigue habiendo un
  solo constructor, así que el contenedor lo usa tal cual ([`03`](03-inyeccion-de-dependencias.md)).
  Olvidarlo es el error de esta sección: el fallback lee de un repositorio que nadie
  inyectó y no compila.
- **`remember` es privado y sin `@Transactional`, y anotarlo no serviría de nada**: lo llama
  otro método de la misma clase, y una self-invocation no atraviesa el proxy
  ([`05` §5](05-proxies-y-aop.md#5-️-self-invocation-el-fallo-silencioso-número-uno)). No
  hace falta: `save()` de Spring Data ya abre la suya (`SimpleJpaRepository` está anotado
  entero).
- **El `save()` explícito tampoco sobra.** El `item` viene de una consulta que cerró su
  transacción antes de volver, así que llega **detached**: no hay dirty checking que emita
  el `UPDATE` por ti, como sí ocurría dentro del servicio en
  [`L04` §3](l04-datos-y-transacciones.md#3--jdbcclient-y-spring-data-jpa-lado-a-lado).
  Sin esa línea las columnas se quedan en `NULL` y el fallback siempre acaba en
  `QuoteUnavailableException` — un fallo que solo aparece el día que lo necesitas.
- **La escritura ocurre dentro de `quote()`, o sea dentro de los tres decoradores**, y eso
  tiene un precio que conviene decir en voz alta: si la base falla al guardar, el breaker
  contará ese fallo como si fuera del proveedor. Con un `UPDATE` por cotización buena el
  riesgo es asumible y el código cabe en cinco líneas; sacarlo del camino publicando un
  evento es el mecanismo de [`18`](18-asincronia-scheduling-y-eventos.md) y queda fuera del
  lab.

Falta que la respuesta pueda **decir** que viene del respaldo, y eso es un campo en el
contrato, no un comentario en el log:

```java
// el proveedor nunca manda "stale": Jackson lo deja en false
record SupplierQuote(String sku, BigDecimal price, Instant quotedAt, boolean stale) { }

record QuoteResponse(String sku, int quantity, BigDecimal price, Instant quotedAt, boolean stale) { }

@GetMapping("/{sku}/quote")
QuoteResponse quote(@PathVariable String sku) {
    InventoryItem item = service.findBySku(sku).orElseThrow(() -> new ItemNotFoundException(sku));
    SupplierQuote quote = gateway.quote(sku);
    return new QuoteResponse(item.sku(), item.quantity(), quote.price(), quote.quotedAt(), quote.stale());
}
```

- **El `boolean stale` que el proveedor no manda se deserializa como `false`**, que es el
  default correcto sin escribir una línea: una cotización recién traída no es rancia. El
  único sitio del proyecto que lo pone en `true` es el fallback, y por eso el campo no
  miente aunque nadie lo mantenga.
- **`QuoteResponse` lo copia y lo publica.** Sin ese campo, el cliente no tiene forma de
  distinguir un precio de hace un segundo de uno de ayer: `quotedAt` ya viajaba, pero
  compararlo con el reloj es trabajo que nadie hace. Un `boolean` en el cuerpo es el mínimo
  honesto.
- **Cambiar la aridad de los dos `record` rompe la compilación** de todo lo que los
  construya, tests de `L03` incluidos. Eso es una ventaja: un campo nuevo del contrato no
  debería poder colarse sin que alguien lo mire.

El fallback, en `SupplierGateway`, con el método de respaldo al lado:

```java
@CircuitBreaker(name = "supplier", fallbackMethod = "lastKnownQuote")
@Retry(name = "supplier")
@Bulkhead(name = "supplier", fallbackMethod = "lastKnownQuote")
SupplierQuote quote(String sku) { … }

// misma firma que el original + un Throwable al final
SupplierQuote lastKnownQuote(String sku, Throwable cause) {
    log.warn("fallback de cotización para {}: {}", sku, cause.toString());
    return repository.findBySku(sku)
            .filter(item -> item.lastQuotedPrice() != null)
            .map(item -> new SupplierQuote(sku, item.lastQuotedPrice(), item.lastQuotedAt(), true))
            .orElseThrow(() -> new QuoteUnavailableException(sku));
}
```

- **La firma del fallback repite la del método original y añade un `Throwable` final.** Si
  no coincide, Resilience4j no lo encuentra — y el siguiente bloque demuestra cuándo te
  enteras de eso, que no es cuando crees.
- **El `true` del último argumento es todo el contrato de honestidad**: es lo que sale como
  `"stale": true` en el JSON y lo único que distingue esta respuesta de una buena. Quitarlo
  deja un fallback que funciona y miente, que es peor que no tenerlo.
- **`orElseThrow` cuando no hay dato es la parte honesta.** Si nunca hubo cotización, no hay
  nada que degradar: propagar el error es mejor que inventar un precio. **A veces el
  fallback correcto es no tener fallback**, y con dinero de por medio esa es la opción por
  defecto.
- **`log.warn` con la causa, siempre.** Un fallback silencioso convierte la caída del
  proveedor en un misterio: todo "funciona", nadie ve errores y los números salen mal tres
  días después en la reconciliación.
- **El `quotedAt` que devuelve es el viejo, no `Instant.now()`.** Esa fecha es lo único que
  permite al cliente saber que el dato está rancio; sobrescribirla con la hora actual
  convertiría una degradación honesta en una mentira bien formateada.

Antes de verlo funcionar, rómpelo a propósito: cambia el nombre del método a
`lastKnownQuotes` en la anotación —una `s` de más, el error de refactor más común— y
arranca.

**Predice antes de ejecutar**: ¿falla el arranque, falla la primera petición, o falla la
primera petición que necesita el fallback? Fíjate en que la primera llamada del bloque va a
un `sku` **sano**, que responde `200` sin ayuda de nadie.

```bash
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s -o /dev/null -w 'arranque -> %{http_code}\n' localhost:8081/actuator/health
curl -s -o /dev/null -w 'sku sano -> %{http_code}\n' localhost:8080/api/items/ABC-000123/quote
grep -c 'No fallback method match found' app.log
for i in $(seq 1 10); do curl -s -o /dev/null localhost:8080/api/items/SLW-000002/quote & done
wait
grep -m1 -A1 'No fallback method match found' app.log
```

```text
arranque -> 200
sku sano -> 200
2
 WARN --- [nio-8080-exec-1] i.g.r.s.fallback.FallbackExecutor : No fallback method match found
java.lang.NoSuchMethodException: class com.invlab.invapi.supplier.SupplierQuote class com.invlab.invapi.supplier.SupplierGateway.lastKnownQuotes(class java.lang.String,class java.lang.Throwable)
```

- **El arranque fue limpio y la petición al `sku` sano también, y el aviso ya está en el
  log.** Esto es lo que hay que llevarse de aquí, y contradice lo que se repite en media
  internet: `FallbackExecutor.execute` llama a `FallbackMethod.create(...)` **en cada
  invocación del método anotado, antes de ejecutarlo**, no la primera vez que hace falta
  degradar. Por eso `grep -c` ya cuenta avisos después de una llamada que terminó en `200`.
- **Dos avisos por una llamada, y no es un error de conteo:** dos de las tres anotaciones
  declaran `fallbackMethod` y cada aspecto resuelve el suyo por separado; `@Retry` no lo
  declara y no dice nada. Las diez peticiones siguientes dejan veinte líneas más: el caché
  interno guarda el resultado vacío de la búsqueda, pero el aviso se repite en cada
  invocación.
- **Lo que buscas es un `WARN`, no un fallo.** Cuando la firma no casa, Resilience4j
  **captura** la `NoSuchMethodException`, escribe `No fallback method match found` y ejecuta
  el método **como si no hubieras configurado ningún fallback**. Ninguna petición se rompe
  por esto: las diez contra el `sku` lento siguen dando el mismo error de siempre. Por eso
  el defecto sobrevive a la suite de tests, al despliegue y a la primera semana en
  producción: el sistema no protesta, solo deja de tener la red de seguridad que creías
  haber puesto, y la noche que el proveedor se cae no encuentras un error nuevo — encuentras
  un `WARN` viejo que nadie leyó.
- **El mensaje de la excepción empieza por el tipo de retorno y lleva el prefijo `class` en
  cada tipo**, porque lo construye un `String.format` con los `Class` tal cual: primero
  `SupplierQuote`, después la clase y el método buscados, y entre paréntesis los parámetros
  más el `Throwable` final. Se lee incómodo y vale su peso: si te falta el `Throwable`, ahí
  está escrito lo que Resilience4j esperaba encontrar.
- **El `-A1` del `grep` no es decoración.** El texto del `WARN` no dice qué método buscó; eso
  va en la excepción que el logger imprime en la línea siguiente. Buscar solo
  `NoSuchMethodException` también sirve, pero deja fuera el aviso que es la señal real.
- **La prevención es un test**, no una revisión más cuidadosa: un caso que fuerce el fallo y
  afirme sobre la respuesta degradada. Una alerta sobre `No fallback method match found`
  ayuda, pero llega después del despliegue. El ejercicio 15 lo pide, y es la única forma de
  que esto no vuelva.

Arregla el nombre, guarda la cotización buena cada vez que llegue una y comprueba la
degradación:

```bash
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 10
curl -s localhost:8080/api/items/SLW-000002/quote | jq -c      # una buena, para tener dato
for i in $(seq 1 10); do curl -s localhost:8080/api/items/SLW-000002/quote & done | tail -3
```

```text
{"sku":"SLW-000002","quantity":40,"price":45.00,"quotedAt":"2026-09-18T10:00:00Z","stale":false}
{"sku":"SLW-000002","quantity":40,"price":45.00,"quotedAt":"2026-09-18T10:00:00Z","stale":true}
{"sku":"SLW-000002","quantity":40,"price":45.00,"quotedAt":"2026-09-18T10:00:00Z","stale":true}
{"sku":"SLW-000002","quantity":40,"price":45.00,"quotedAt":"2026-09-18T10:00:00Z","stale":true}
```

- **`"stale": true` es la diferencia entre degradar y mentir.** El campo lo pone
  `QuoteResponse` a partir de si la cotización vino del proveedor o del respaldo, y es lo
  que permite al cliente decidir: mostrar el precio con un aviso, o no mostrarlo.
- **Compara con las dos alternativas que se proponen siempre**: devolver `price: 0` convierte
  un fallo visible en corrupción silenciosa —alguien va a vender a cero—, y devolver `null`
  sin marcarlo hace que el cliente muestre un hueco sin saber por qué. Las dos "evitan el
  error", y las dos son peores que el error.
- **El fallback está en `@CircuitBreaker` y en `@Bulkhead`, pero no en `@Retry`.** Es
  deliberado: el fallback del retry se dispararía tras agotar los intentos, que es lo mismo
  que ya cubre el breaker, y tenerlo en tres sitios multiplica los caminos por los que una
  respuesta puede salir degradada sin que sepas cuál actuó.

Devuelve `slow-call-duration-threshold` a `1s` antes de cerrar el lab: era temporal y
dejarlo en `5s` desactiva, sin avisar, la mitad del circuito de la sección 5.

> **⏱️ Costo en runtime.** El bulkhead no cuesta hilos: son tres permisos de un semáforo en
> memoria. Lo que cuesta es **capacidad deliberadamente renunciada** —con tres permisos y
> llamadas de 2 s, el techo hacia `inv-supplier` es de 1,5 req/s y todo lo demás se rechaza—,
> y ese número tiene que salir de una conversación con quien opera el proveedor, no de un
> valor copiado de un blog.

---

## 8. 📋 Checklist de salida

- [ ] `docker compose -p inv-lab ps` lista `inv-lab-postgres-1` en `(healthy)` e `inv-lab-wiremock-1` en `Up`.
- [ ] `ls wiremock/mappings` muestra los cinco stubs y `curl -s -X POST localhost:8090/__admin/mappings/reset` los recarga sin error.
- [ ] Los cuatro comportamientos responden como toca: `ABC-000123` en ~90 ms, `SLW-000002` en ~2 s, `ERR-000500` con `500` y un `sku` desconocido con `404`.
- [ ] `inv.supplier.base-url` vale `http://localhost:8090` y `/actuator/configprops` lo confirma.
- [ ] `spring.http.client.connect-timeout` y `read-timeout` están puestos, y una llamada a `SLW-000001` falla en ~3 s con `ResourceAccessException: … Read timed out`.
- [ ] Doce peticiones concurrentes a `SLW-000001` terminan en dos escalones —diez en ~3 s y dos en ~6 s, por el `accept-count`— y `tomcat.threads.busy` vuelve a `0.0` al acabar.
- [ ] `grep -c 'org.springframework.boot:spring-boot-starter-aop' pom.xml` devuelve `1`; sin él las anotaciones de Resilience4j no hacen nada.
- [ ] Un `sku` desconocido produce **una sola** llamada en el journal de WireMock y un `502` con `ProblemDetail`.
- [ ] Con jitter activo, las marcas de tiempo de `grep 'saliente' app.log | cut -c12-21 | uniq -c` **no** forman bloques del mismo tamaño.
- [ ] Ocho peticiones a `ERR-000500` dejan `state: OPEN` en `/actuator/circuitbreakers` y al menos un `CallNotPermittedException` en el log.
- [ ] `/actuator/circuitbreakerevents/supplier` muestra `CLOSED_TO_OPEN`, `OPEN_TO_HALF_OPEN` y `HALF_OPEN_TO_CLOSED` en ese orden.
- [ ] Ocho peticiones a `SLW-000002` con `slow-call-duration-threshold: 1s` abren el circuito con `failedCalls: 0`.
- [ ] Con el orden A, las llamadas recibidas por WireMock y los eventos `ERROR` del breaker coinciden; con el orden B, las primeras triplican a los segundos.
- [ ] `retry-aspect-order` vale `1` y `circuit-breaker-aspect-order` vale `2` en el fichero final.
- [ ] Diez peticiones concurrentes a `SLW-000002` producen tres `200` y siete `BulkheadFullException`.
- [ ] La respuesta degradada lleva `"stale": true` y conserva el `quotedAt` viejo; ninguna devuelve `price: 0`.
- [ ] `slow-call-duration-threshold` volvió a `1s` después del experimento del bulkhead.
- [ ] `./mvnw -q clean package` pasa en verde con los tests de `L03` intactos y `jobs` no lista ningún `java -jar` al terminar.

---

## 🧠 Preguntas rápidas

1. ¿Qué significa exactamente `ResourceAccessException` y en qué se diferencia de
   `HttpServerErrorException`? ¿Cuál de las dos se reintenta y por qué?
2. Diferencia `connect-timeout` de `read-timeout` y di cuál de los dos no salta nunca con un
   proveedor que responde goteando un byte cada dos segundos.
3. "El timeout por defecto es razonable." Corrige la frase con la versión precisa y di quién
   decide ese valor en un `RestClient` construido desde el `Builder` de Boot.
4. En el threaddump, los hilos colgados aparecían como `RUNNABLE` y no como `BLOCKED`. ¿Por
   qué, y qué búsqueda equivocada hace esa diferencia?
5. `max-attempts: 3` con `read-timeout: 3s` y backoff de 200 ms y 400 ms: ¿cuánto puede
   tardar la operación completa en el peor caso, y qué le hace eso a un endpoint que promete
   dos segundos?
6. ¿Qué cambia el jitter y qué **no** cambia? Responde con los dos números del experimento de
   la sección 4.
7. Sin `retry-exceptions`, ¿qué reintenta Resilience4j, y cuántas llamadas costó en el lab un
   `sku` que el proveedor no conoce?
8. Explica `minimum-number-of-calls` y `failure-rate-threshold`: ¿cuál es un conteo y cuál un
   porcentaje, y qué pasa si quitas el primero en un servicio con poco tráfico?
9. Tu circuito no abre nunca aunque el proveedor tarda cinco segundos en cada respuesta.
   ¿Qué dos parámetros faltan y qué indicador lo confirma en `/actuator/circuitbreakers`?
10. ¿Quién lanza `CallNotPermittedException`, en qué hilo, y por qué esa llamada no gasta una
    conexión del pool HTTP?
11. Escribe el orden correcto de apilado entre retry y circuit breaker, y di cuántas llamadas
    recibe el proveedor en cada orden con ocho peticiones y `max-attempts: 3`.
12. ¿Por qué el bulkhead **no** hizo bajar `tomcat.threads.busy`, y de qué protege entonces?
13. ¿Cuándo eliges bulkhead por semáforo y cuándo por thread pool? Nombra lo que se pierde
    con el segundo.
14. Un fallback mal firmado no rompe el arranque. ¿Cuándo te enteras, con qué excepción, y
    cuál es la prevención que sí funciona?
15. Da los tres rasgos de un fallback honesto y el caso en el que el fallback correcto es no
    tener ninguno.

---

## 🧪 Ejercicios (16)

### 🟢 Fácil — repetir lo del lab con otro valor o en otro punto  (1–4)

#### 🟢 Ejercicio 1 — un quinto comportamiento

Añade a `wiremock/mappings/` un stub para `TMO-000001` que devuelva `200` con
`fixedDelayMilliseconds: 6000`, recarga con `/__admin/mappings/reset` y comprueba con
`curl -w '%{time_total}'` que tarda seis segundos crudo y tres desde `inv-api`.
**Objetivo:** ver que el `read-timeout` es tuyo y no del proveedor, y que un stub nuevo no
necesita reiniciar el contenedor.

#### 🟢 Ejercicio 2 — el timeout de conexión, aislado

Para WireMock con `docker compose -p inv-lab stop wiremock`, lanza una petición a
`/api/items/ABC-000123/quote` y mide. Compara el tiempo con y sin `connect-timeout: 2s`
configurado.
**Objetivo:** distinguir en la práctica los dos timeouts, y ver cuánto espera el sistema
operativo cuando no le pones techo.

#### 🟢 Ejercicio 3 — otro factor de jitter

Repite la tanda de seis peticiones con `randomized-wait-factor: 0.9` y con `0.1`, y arma una
tabla de tres columnas con los tres histogramas de `cut -c12-21 | uniq -c`.
**Objetivo:** ver que el jitter tiene dosis, y que acercarse a `1.0` devuelve parte de la
sincronía en vez de eliminarla.

#### 🟢 Ejercicio 4 — el circuito con otra ventana

Cambia a `sliding-window-type: TIME_BASED` con `sliding-window-size: 10`, repite las ocho
peticiones a `ERR-000500` y documenta en qué petición abre ahora y por qué el número cambió.
**Objetivo:** entender que la ventana define qué significa "últimas llamadas".

### 🟡 Intermedio — aplicarlo a otra clase, otro endpoint u otra propiedad  (5–9)

#### 🟡 Ejercicio 5 — el `503` del bulkhead

`BulkheadFullException` todavía sale como `500`. Añádele su `@ExceptionHandler` con
`ProblemDetail` y `503`, y demuéstralo con las diez peticiones concurrentes de la sección 7.
**Objetivo:** cerrar el contrato hacia fuera para los tres rechazos —circuito, bulkhead y
timeout— con códigos que digan la verdad.

#### 🟡 Ejercicio 6 — la self-invocation que mata el retry

Añade a `SupplierGateway` un método `quoteAll(List<String> skus)` que llame a su propio
`quote(sku)` en un bucle, pídele tres `sku` con `ERR-000500` entre ellos y cuenta las
llamadas en el journal de WireMock.
**Objetivo:** comprobar que las anotaciones de Resilience4j caen exactamente en la trampa de
[`05` §5](05-proxies-y-aop.md#5-️-self-invocation-el-fallo-silencioso-número-uno), igual que
`@Transactional`.

#### 🟡 Ejercicio 7 — el `name` mal escrito

Cambia `@Retry(name = "supplier")` por `@Retry(name = "suplier")` y demuestra con el journal
de WireMock cuántos intentos hace ahora y con qué esperas.
**Objetivo:** ver que un nombre inexistente no falla, sino que aplica una configuración por
defecto que tú no escribiste — y decidir si eso te parece aceptable.

#### 🟡 Ejercicio 8 — el segundo proveedor

Añade un stub `/shipping/{sku}/eta` con 500 ms de latencia y una segunda instancia
`resilience4j.circuitbreaker.instances.shipping` con sus propios umbrales. Satura solo a
`supplier` y demuestra que `shipping` sigue respondiendo.
**Objetivo:** ver que las instancias son independientes, y que un circuito por dependencia
es el mínimo — nunca uno global.

#### 🟡 Ejercicio 9 — presupuesto de tiempo repartido

`GET /api/items/{sku}/full` tiene que llamar a los dos proveedores en serie y responder en
menos de 2 s. Reparte el presupuesto, configura los timeouts y demuéstralo con
`%{time_total}` en el peor caso.
**Objetivo:** aplicar el reparto de [`19` §2](19-resiliencia.md#2--el-timeout-es-el-primero-y-sin-él-nada-más-sirve)
con números propios, en vez de copiar `3s` en los dos sitios.

### 🟠 Difícil — combinar, diagnosticar o decidir  (10–13)

#### 🟠 Ejercicio 10 — el diagnóstico a ciegas

Pídele a alguien que ponga uno de estos tres sabotajes sin decirte cuál: `read-timeout` a
`5m`, `max-concurrent-calls` a `1`, o `failure-rate-threshold` a `5`. Diagnostícalo usando
solo `tomcat.threads.busy`, el journal de WireMock y `/actuator/circuitbreakerevents`, y
escribe el razonamiento antes de mirar el YAML.
**Pregunta:** ¿cuál de los tres indicadores descartó primero cada hipótesis?

#### 🟠 Ejercicio 11 — el half-open que vuelve a abrir

Deja el circuito abierto, espera los diez segundos y haz que las dos llamadas de prueba
fallen. Captura el `STATE_TRANSITION HALF_OPEN_TO_OPEN` y calcula cuánto tiempo estuvo
abierto en total.
**Objetivo:** ver el tercer estado completo, y entender por qué
`permitted-number-of-calls-in-half-open-state` es un compromiso entre recuperarse rápido y
volver a tumbar al proveedor.

#### 🟠 Ejercicio 12 — `Retry-After` de verdad

Cambia el handler del `503` para que devuelva `ResponseEntity<ProblemDetail>` con la cabecera
`Retry-After` calculada a partir del tiempo que le queda al circuito en `OPEN`, y
compruébalo con `curl -i`.
**Objetivo:** convertir un detalle del cuerpo en el mecanismo estándar de HTTP, y descubrir
de dónde se saca ese tiempo restante sin inventarlo.

#### 🟠 Ejercicio 13 — el orden con tres capas

El bulkhead es la única capa cuyo orden **no** se configura: en Resilience4j 2.2.0,
`BulkheadConfigurationProperties.getBulkheadAspectOrder()` devuelve `LOWEST_PRECEDENCE - 1`
fijo. Así que déjalo donde está y sube el otro: pon `circuit-breaker-aspect-order` en
`org.springframework.core.Ordered.LOWEST_PRECEDENCE` (`2147483647`) para que el breaker
quede **por dentro** del bulkhead, repite el experimento de la sección 7 con el circuito ya
abierto y cuenta los `BulkheadFullException` de cada orden.
**Pregunta:** ¿en cuál de los dos órdenes el bulkhead consume un permiso para llamadas que
el circuito iba a rechazar sin tocar la red, y por qué eso hace inútil el número que
configuraste?

### 🔴 Muy difícil — abierto o adversarial  (14–16)

#### 🔴 Ejercicio 14 — el servicio saboteado

Te entregan `inv-api` con cuatro cambios hechos a la vez: el fallback devuelve `price: 0`,
`retry-exceptions` incluye `HttpClientErrorException`, el orden de aspectos está invertido y
`max-wait-duration` del bulkhead vale `30s`. El servicio responde `200` a todo y el tablero
está verde. Encuentra los cuatro y ordénalos por daño.
**Objetivo:** practicar el peor escenario real —un sistema que miente en verde— y defender
un criterio de gravedad, no una lista.

#### 🔴 Ejercicio 15 — el test que impide la regresión

Escribe un test de integración que arranque el contexto, fuerce el fallo del proveedor y
afirme que la respuesta llega degradada con `"stale": true`. Tiene que fallar si alguien
renombra el método de fallback o le quita el `Throwable`.
**Objetivo:** convertir el `NoSuchMethodException` de la sección 7 en un fallo de build,
que es el único sitio donde ese error es barato.

#### 🔴 Ejercicio 16 — la defensa del número

`max-concurrent-calls: 3` salió de un ejemplo. Calcula el valor correcto para `inv-api` a
partir de tres datos que tú elijas y justifiques —latencia del proveedor, capacidad que te
ha prometido, presupuesto de hilos de Tomcat— y escribe media página defendiéndolo ante
alguien que quiere subirlo a 50 porque "hay rechazos".
**Pregunta:** ¿qué le pasa al sistema completo si le das la razón, y qué pasa si el
proveedor mejora a 100 ms y nadie revisa el número?

### 🔥 Opcionales y ampliaciones

- **`ErrorDecoder` de Feign.** Añade `spring-cloud-openfeign-starter` con la versión del
  release train alineado a Boot 3.5, declara `SupplierClient` con `@FeignClient` y escribe un
  `ErrorDecoder` que traduzca el `404` a `UnknownSupplierSkuException` y el `500` a una
  excepción reintentable. Compara el resultado con el `onStatus` de la sección 4 y decide
  cuál prefieres mantener. Queda fuera del alcance base porque es traducción de errores, no
  un fallo silencioso nuevo, y porque la comparación de los cinco clientes ya está resuelta
  en [`13` §9](13-clientes-http.md#9--los-cinco-y-el-veredicto).
- **Rate limiter.** Configura `resilience4j.ratelimiter.instances.supplier` con
  `limit-for-period: 5` y `limit-refresh-period: 1s`, lanza veinte peticiones y captura
  `RequestNotPermitted`. Después explica en dos frases por qué esto **no** es un bulkhead:
  uno limita concurrencia y el otro limita llamadas por unidad de tiempo, y el segundo existe
  para respetar la cuota del proveedor, no para protegerte a ti.
- **`TimeLimiter` sobre `CompletableFuture`.** Convierte `quote` en asíncrono, ponle un
  `@TimeLimiter(name = "supplier")` y comprueba que ahora sí hay un techo para la llamada
  **entera**, no por lectura. De paso mira en qué hilo corre el fallback y qué le pasa al
  request id de `L03`.
- **Virtual threads.** Activa `spring.threads.virtual.enabled: true`, repite el experimento
  de la sección 3 **sin** timeout y mira qué hace `tomcat.threads.busy`. El resultado es la
  mitad de la discusión de `12`, y la otra mitad es que los treinta segundos de espera siguen
  existiendo: los virtual threads abaratan el hilo, no arreglan la falta de timeout.

### 💀 Boss fight — el contrato de resiliencia de `inv-api`

Entrega un artefacto que otro equipo pueda usar sin preguntarte nada, cumpliendo todo esto a
la vez:

- **Una tabla de presupuesto de tiempo** por endpoint de `inv-api`: lo que promete, lo que se
  lleva cada dependencia, cuántos intentos caben dentro de esa promesa y qué queda de margen.
  Cada número con su propiedad del YAML al lado.
- **Un `docker compose` y un script** que levanten los perfiles `db` y `ext`, carguen los
  stubs y reproduzcan los cuatro fallos del lab en menos de cinco minutos, con su teardown.
- **Un test de integración por cada mecanismo** —timeout, retry, circuito, bulkhead,
  fallback— que afirme sobre el número de llamadas recibidas por WireMock, no sobre el código
  de estado. Si mañana alguien invierte el orden de los aspectos, la suite falla diciendo
  cuál.
- **Una página de runbook** con los cinco síntomas del lab —hilos en `SocketDispatcher.read0`,
  ariete sincronizado, `CallNotPermittedException`, `BulkheadFullException` y
  `NoSuchMethodException` del fallback—, su primera línea literal, el comando de diagnóstico y
  la corrección.
- **Una decisión escrita y firmada** sobre el fallback de cada llamada saliente: degrada,
  propaga o falla, y por qué. Con dinero de por medio, la opción por defecto es propagar, y
  cualquier excepción a eso tiene que estar justificada por escrito.

**Objetivo:** convertir seis secciones de mecanismo en el artefacto que un Tech Lead entrega
cuando dice "nuestras llamadas salientes están bajo control": no una lista de anotaciones,
sino números defendibles y una suite que los vigila cuando tú ya no estás mirando.

---

## 🏁 La señal de que quedó bien

`docker compose -p inv-lab ps` lista dos contenedores —Postgres en `healthy` y WireMock en
`Up`— y los cinco stubs responden los cuatro comportamientos que pediste. `inv-api` arranca
limpio, los tests de `L03` siguen en verde y el `GET /api/items/{sku}/quote` devuelve la
cotización del proveedor en noventa milisegundos.

Y lo que de verdad cuenta: **ninguna de las formas de portarse mal del proveedor se lleva ya
tu servicio por delante**. Treinta segundos de latencia se convierten en un error tuyo a los
tres. Un 500 persistente deja de costarte tres llamadas por petición en cuanto el circuito
abre, y `/actuator/circuitbreakerevents` te dice a qué hora y por qué. Diez peticiones
concurrentes contra un proveedor lento producen tres llamadas y siete rechazos honestos en
veinte milisegundos. Y cuando no hay nada bueno que devolver, la respuesta dice `"stale":
true` en vez de inventar un precio.

Si dudas de alguno de esos cuatro, el criterio de verdad de hoy no es el log ni el código de
estado: es el journal de WireMock contando cuántas llamadas llegaron de verdad al otro lado.

Los perfiles `db` y `ext` se quedan arriba. `L06` añade el perfil `cache` y pone Redis
delante de esa misma cotización, que es la otra forma de no molestar al proveedor: en vez de
llamarlo mejor, no llamarlo.

---

## 📚 Referencias oficiales

- Spring Boot 3.5 — Llamar a servicios REST y configuración global del cliente (`spring.http.client.*`): https://docs.spring.io/spring-boot/3.5/reference/io/rest-client.html
- Spring Boot 3.5 — Endpoints de Actuator (`metrics`, `threaddump`, `circuitbreakers`, `circuitbreakerevents`): https://docs.spring.io/spring-boot/3.5/reference/actuator/endpoints.html
- Spring Boot 3.5 — Exponer endpoints de Actuator y puerto de management: https://docs.spring.io/spring-boot/3.5/reference/actuator/enabling.html
- Spring Boot 3.5 — Métricas soportadas, incluidas las de Tomcat: https://docs.spring.io/spring-boot/3.5/reference/actuator/metrics.html
- Spring Boot 3.5 — Índice de propiedades (`server.tomcat.*`, `spring.http.client.*`): https://docs.spring.io/spring-boot/3.5/appendix/application-properties/index.html
- Spring Boot 3.5 — Servidor web embebido y configuración de Tomcat: https://docs.spring.io/spring-boot/3.5/reference/web/servlet.html
- Spring Framework 6.2 — `RestClient`, `RestTemplate` e interceptores: https://docs.spring.io/spring-framework/reference/6.2/integration/rest-clients.html
- Spring Framework 6.2 — Mecanismo de proxy, que es de lo que viven `@Retry` y `@CircuitBreaker`: https://docs.spring.io/spring-framework/reference/6.2/core/aop/proxying.html
- Spring Framework 6.2 — Orden de los aspectos y `Ordered`: https://docs.spring.io/spring-framework/reference/6.2/core/aop/ataspectj/advice.html

### Documentación de terceros

- Resilience4j — Getting started con Spring Boot 3: https://resilience4j.readme.io/docs/getting-started-3
- Resilience4j — Retry, backoff y `enable-randomized-wait`: https://resilience4j.readme.io/docs/retry
- Resilience4j — CircuitBreaker, ventanas y estados: https://resilience4j.readme.io/docs/circuitbreaker
- Resilience4j — Bulkhead por semáforo y por thread pool: https://resilience4j.readme.io/docs/bulkhead
- Resilience4j — RateLimiter (para el 🔥 opcional): https://resilience4j.readme.io/docs/ratelimiter
- Resilience4j — TimeLimiter (para el 🔥 opcional): https://resilience4j.readme.io/docs/timeout
- Resilience4j — Métricas con Micrometer: https://resilience4j.readme.io/docs/micrometer
- WireMock — Stubbing y prioridades: https://wiremock.org/docs/stubbing/
- WireMock — Simular fallos y latencia: https://wiremock.org/docs/simulating-faults/
- WireMock — Emparejar peticiones (`urlPathPattern` y compañía): https://wiremock.org/docs/request-matching/
- WireMock — Response templating: https://wiremock.org/docs/response-templating/
- WireMock — Verificar peticiones recibidas (el journal): https://wiremock.org/docs/verifying/
- WireMock — Ejecución standalone con Docker: https://wiremock.org/docs/standalone/docker/
- Docker Compose — Perfiles: https://docs.docker.com/compose/how-tos/profiles/
