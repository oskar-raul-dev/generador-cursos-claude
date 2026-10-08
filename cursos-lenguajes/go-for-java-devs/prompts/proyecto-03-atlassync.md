# 🌍 Proyecto 3 — AtlasSync Service
## Catálogo de datos de referencia · Meridian Retail Group

> **Eje técnico:** consumo de APIs externas, MongoDB, caché con Valkey, y la
> pirámide de pruebas completa con el mundo exterior mockeado.
> **Nace:** Fase 10, ya en **Go moderno** · **Cierra:** Fase 17.
> **Módulo:** `services/atlassync` · **Binario:** `atlassync`.

---

## 1. El problema

Meridian opera en once países. Cada uno tiene su moneda, su código ISO, su
formato de dirección, su zona horaria y su tipo de cambio del día. Esos datos los
necesitan los cuatro servicios de la plataforma, el ERP, el marketplace y tres
socios logísticos.

Hoy cada sistema los tiene copiados a mano en un archivo de configuración, y cada
sistema los tiene copiados de forma ligeramente distinta. El día que Meridian
abrió operación en un país nuevo, cuatro equipos hicieron el mismo cambio en
cuatro sitios, y uno se equivocó de código de moneda.

**AtlasSync** ingiere datos de referencia de fuentes públicas, los normaliza, los
almacena en MongoDB, los sirve por una API propia y los mantiene calientes en
Valkey. Es un servicio **de lectura intensiva**: pocas escrituras, muchísimas
lecturas, y una dependencia externa que puede estar caída.

---

## 2. Por qué este proyecto nace en Go moderno

Los dos primeros servicios nacieron en 1.13 y se migraron. AtlasSync **nace
después de la Fase 08**, ya con genéricos, `slog`, el `ServeMux` moderno e
iteradores disponibles desde la primera línea.

La asimetría es deliberada y didáctica: el estudiante va a escribir el mismo tipo
de código —un handler, un almacén, un cliente— con las dos cajas de herramientas,
y va a poder decir por experiencia propia dónde la moderna ayuda de verdad y
dónde es azúcar. Es la única forma honesta de contestar *"¿cuánto cambió Go en
diez años?"*.

---

## 3. Las fuentes externas

Todas públicas, **sin clave de API**, para que el curso funcione en cualquier
máquina y en cualquier momento:

- **REST Countries** — `https://restcountries.com/v3.1/all` — países, códigos
  ISO, monedas, idiomas, zonas horarias, región y subregión.
- **Frankfurter** — `https://api.frankfurter.app/latest` — tipos de cambio del
  Banco Central Europeo, con histórico por fecha.
- 🔥 **Open-Meteo** — `https://open-meteo.com` — opcional, como segunda fuente
  para los ejercicios de agregación de proveedores.

> ⚠️ **Estas APIs pueden cambiar, moverse o desaparecer.** El curso lo asume:
> todas las respuestas usadas en pruebas están **grabadas en `testdata/`**, el
> servicio arranca y funciona con ellas, y solo un test marcado 🔥 —excluido de
> CI— golpea la red de verdad. Que un curso dependa de que un servicio gratuito
> siga vivo en 2029 es un defecto de diseño, y aquí se evita a propósito.

---

## 4. Objetivo funcional

1. Ingerir el catálogo de países desde la fuente externa, de forma programada y
   bajo demanda.
2. Ingerir los tipos de cambio del día, y el histórico por rango.
3. Normalizar documentos de forma irregular a un modelo propio y estable.
4. Detectar y registrar cambios entre la versión anterior y la nueva.
5. Servir consultas por código, por región, por moneda y por texto libre.
6. Convertir importes entre monedas con el tipo de una fecha dada.
7. Mantener las lecturas calientes en caché, con invalidación al ingerir.
8. Seguir sirviendo —datos ligeramente viejos, pero sirviendo— cuando la fuente
   externa esté caída.
9. Exponer la antigüedad del dato en cada respuesta, para que el consumidor
   decida.
10. Exponer `/health`, `/ready` y `/metrics`.

El punto 8 es la tesis del servicio: **un catálogo de referencia nunca debe
devolver un error porque un tercero esté caído.** Los datos de ayer sirven; un
`503` no.

---

## 5. Entidades

MongoDB, y la justificación está en la forma del dato. Un país de REST Countries
trae nombres en nueve idiomas, monedas anidadas con símbolo y nombre, fronteras
como arreglo, y campos que unos países tienen y otros no. Normalizarlo a diez
tablas para volver a unirlo en cada lectura es trabajo sin destinatario.

### Colección `countries`

```go
type Country struct {
    Code       string            `bson:"_id"`          // ISO alfa-2, la clave natural
    Code3      string            `bson:"code3"`
    Names      map[string]string `bson:"names"`        // idioma -> nombre
    Currencies []Currency        `bson:"currencies"`
    Region     string            `bson:"region"`
    Subregion  string            `bson:"subregion"`
    Timezones  []string          `bson:"timezones"`
    Borders    []string          `bson:"borders"`
    Population int64             `bson:"population"`
    Raw        bson.Raw          `bson:"raw"`          // el documento original, intacto
    SourceETag string            `bson:"source_etag"`
    FetchedAt  time.Time         `bson:"fetched_at"`
    Version    int               `bson:"version"`
}
```

> 💡 El campo `Raw` guarda el documento de origen sin tocar. Cuesta espacio y
> salva el día que alguien pregunta por un campo que no se modeló. Es una
> decisión que en un esquema relacional sería impensable y aquí es barata —y el
> curso dice también cuándo se vuelve un vertedero.

### Colección `fx_rates`

```go
type FxRate struct {
    ID        string             `bson:"_id"`        // "2026-03-04:EUR"
    Date      string             `bson:"date"`
    Base      string             `bson:"base"`
    Rates     map[string]float64 `bson:"rates"`
    FetchedAt time.Time          `bson:"fetched_at"`
}
```

> ⚠️ **`float64` para dinero es un error**, y el curso lo aprovecha: los *tipos de
> cambio* sí son `float64` porque son factores, pero **los importes convertidos
> se calculan con enteros de centavos**. La diferencia se demuestra con un caso
> donde el redondeo se come dos centavos por transacción, y con quinientas mil
> transacciones al día eso es dinero real. ClearingHouse hereda la regla.

### Colección `sync_runs`

Bitácora de cada ingesta: cuándo, de qué fuente, cuántos documentos, cuántos
cambiaron, cuánto tardó, y el error si lo hubo.

---

## 6. API objetivo

```http
GET  /countries?region=&currency=&q=&limit=&cursor=
GET  /countries/{code}
GET  /countries/{code}/neighbors

GET  /fx/latest?base=EUR
GET  /fx/{date}?base=EUR
GET  /fx/convert?from=USD&to=COP&amount=149900&date=2026-03-04

POST /sync/countries          dispara ingesta bajo demanda
POST /sync/fx
GET  /sync/runs

GET  /health · /ready · /metrics
```

Toda respuesta lleva la antigüedad del dato, y eso es parte del contrato:

```json
{
  "data": { "...": "..." },
  "meta": { "fetchedAt": "2026-03-04T06:00:00Z", "ageSeconds": 7320, "stale": false, "cache": "hit" }
}
```

`amount` viaja **en la unidad mínima de la moneda** —centavos— como entero. Es la
misma decisión que toma Stripe y por la misma razón.

---

## 7. Arquitectura objetivo

```text
services/atlassync/
  cmd/atlassync/main.go
  internal/catalog/       dominio: país, moneda, tipo de cambio, conversión
  internal/atlassync/     casos de uso; declara CountryStore, RateStore, Cache, Source
  internal/mongo/         implementación de los almacenes
  internal/cache/         implementación sobre Valkey
  internal/source/        clientes de REST Countries y Frankfurter
  internal/httpapi/
  internal/sync/          orquestación de la ingesta, programada y bajo demanda
  testdata/               respuestas grabadas de las fuentes reales
```

La interfaz que hace posible todo el testing del servicio vive en `atlassync` y
tiene tres métodos:

```go
// Source obtiene datos de referencia de un proveedor externo. La implementación
// real habla por HTTP; la de pruebas lee de testdata/ y no toca la red.
type Source interface {
    Countries(ctx context.Context) ([]catalog.Country, error)
    Rates(ctx context.Context, date time.Time, base string) (catalog.FxRate, error)
    Name() string
}
```

---

## 8. La pirámide de pruebas, que es la razón de ser de este proyecto

Este es **el proyecto donde el curso enseña a probar en serio**, porque es el que
depende de algo que no controla.

**Nivel 1 — unitarios.** La normalización, la conversión de importes, la
selección de nombre por idioma, la lógica de "está viejo pero sirve". Sin E/S,
sin red, sin Mongo, en milisegundos. El doble de `Source` es un fake de treinta
líneas que lee `testdata/`.

**Nivel 2 — componente.** `httptest.Server` sirviendo las respuestas grabadas, y
el cliente real de `internal/source` hablando contra él. Aquí se prueba lo que el
fake no puede: que el cliente maneja el `ETag`, que reintenta el `503`, que
respeta el tiempo límite, que no explota con un JSON truncado. **Sin red.**

**Nivel 3 — integración.** `testcontainers-go` levanta MongoDB y Valkey de
verdad. Se prueban los índices, las agregaciones, el TTL, la invalidación. Build
tag `integration`, objetivo `make test-integration`.

**Nivel 4 — punta a punta.** El servicio completo arrancado en el test, con
MongoDB y Valkey en contenedores y **la fuente externa sustituida por el
`httptest.Server`**. Se ejercita el flujo entero: ingesta → almacenamiento →
consulta → caché → segunda consulta servida desde caché. Es la prueba que
demuestra que "end to end" no significa "depende de internet".

**Nivel 5 — 🔥 contrato, fuera de CI.** Un único test, marcado y excluido, que
golpea la API real y verifica que la forma del JSON sigue siendo la que
`testdata/` supone. Es la alarma de que la fuente cambió, y se corre a mano.

**Y los mocks generados**, aquí sí: `go.uber.org/mock` sobre `Source`, para
verificar que la ingesta llamó una vez y no dos cuando el `ETag` no cambió. Eso
es verificación de interacción y el fake no la da.

---

## 9. Avance por fase

**Fase 10 — nace.** El cliente de REST Countries y Frankfurter, con
`http.Client` bien configurado, tiempos límite, reintentos, `ETag`, y los cinco
niveles de prueba montados de una vez. Almacenamiento todavía en memoria: el
foco de la fase es el mundo exterior.

**Fase 11.** MongoDB: el modelo documental, los índices —incluido el de texto
para la búsqueda libre y el TTL sobre `fx_rates` antiguos—, las agregaciones para
"monedas por región", la actualización con detección de cambios, y la discusión
de incrustar frente a referenciar con `borders` como caso.

**Fase 12.** Valkey: *cache-aside* sobre las lecturas por código, TTL con
*jitter*, `singleflight` contra la estampida, invalidación al terminar una
ingesta, y las métricas de acierto y fallo medidas 📐. Y el experimento que
cierra la fase: cuánto gana realmente la caché aquí, porque a veces la respuesta
es "poco, y acabas de añadir un servicio al `compose.yaml`".

**Fase 13.** La ingesta programada, con su bloqueo para que dos instancias no la
corran a la vez, su punto de control y su bitácora en `sync_runs`.

**Fase 14.** Métricas de antigüedad del dato, alerta cuando la ingesta lleva N
horas fallando, trazas que cruzan al proveedor externo, y el modo degradado
declarado: qué devuelve y con qué cabecera cuando la fuente lleva tres días
caída.

**Fase 15.** Perfilado del camino de lectura, que es el 99% del tráfico: cuánto
cuesta la serialización JSON, cuánto el `Decode` de BSON, cuánto se gana
sirviendo bytes ya codificados desde la caché en vez de codificar en cada
petición 📐.

**Fase 17.** Sirve los tipos de cambio a ClearingHouse en el flujo integrado.

---

## 10. Los temas que este proyecto enseña y los otros no

- **Depender de algo que no controlas**, y que el servicio propio no se degrade
  con él.
- **Modelado documental** con criterio, y el contraejemplo de cuándo no.
- **Caché con invalidación pensada**, que es el problema difícil de verdad.
- **La pirámide de pruebas completa**, con la pregunta que todo el mundo hace en
  una entrevista: *"¿y cómo pruebas eso sin llamar a la API real?"*.
- **Los mocks generados**, con su justificación tardía y honesta.
- **El dinero como entero**, que es una lección que sobrevive al lenguaje.

---

## 11. Qué NO se construye aquí

Autenticación de la API propia, interfaz de administración, resolución de
conflictos entre dos fuentes que se contradicen —queda como ejercicio 🔴—, y
sincronización bidireccional: AtlasSync solo lee de fuera.

---

## 12. Criterio de finalización

1. Ingiere el catálogo completo y los tipos de cambio, programado y bajo demanda.
2. Una segunda ingesta sin cambios upstream no reescribe ningún documento.
3. Sirve por código, región, moneda y texto libre, con paginación por cursor.
4. Convierte importes con aritmética entera y sin perder centavos.
5. Con la fuente externa caída, sigue respondiendo y lo declara en `meta.stale`.
6. La caché invalida al terminar una ingesta, y el acierto medido supera el
   objetivo de su entrada en `BENCHMARKS.md`.
7. La suite completa corre **sin acceso a internet**.
8. El test de contrato 🔥 existe, está excluido de CI y está documentado.
9. `go test -race ./...` y `make test-integration` en verde.
10. Cobertura de `internal/` sobre el umbral.

---

## 13. 📖 El diccionario de este proyecto

| Spring | AtlasSync en Go | Dónde se rompe |
|---|---|---|
| `@FeignClient` | Un struct con `*http.Client` y métodos | No hay interfaz declarativa; escribes la petición, y ves los timeouts |
| `@MockBean` | Un fake que implementa `Source` | No hay contexto de test que sustituya beans; pasas el doble al constructor |
| WireMock | `httptest.Server` con `testdata/` | Sin DSL ni servidor aparte; es un handler en el mismo proceso |
| `MongoRepository` | Una interfaz de 5 métodos + `mongo.Collection` | Sin consultas derivadas del nombre del método; escribes el filtro BSON |
| `@Document` / `@Indexed` | Etiquetas `bson` + creación explícita de índices | El índice no aparece solo: hay una migración que lo crea |
| `MongoTemplate` | El `Collection` del driver oficial | Más cerca del protocolo; menos conversión mágica de tipos |
| `@Cacheable` | `cache-aside` escrito a mano | La invalidación es tuya — que es donde estaban los bugs igualmente |
| `RedisTemplate` | `valkey-go` con comandos tipados | Sin serializador configurable: decides qué bytes escribes |
| `@Scheduled(cron=...)` | `time.Ticker` + bloqueo en almacén | Dos instancias corren dos veces si no lo resuelves tú |
| `BigDecimal` | `int64` de unidades mínimas | No hay tipo decimal en la stdlib, y es a propósito: decides la escala |
