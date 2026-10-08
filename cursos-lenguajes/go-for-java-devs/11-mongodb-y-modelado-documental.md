# 🍃 Fase 11 — MongoDB y modelado documental

> Go para desarrolladores Java senior · Fase 11 de 17 · **7 horas**
> Época: **Go moderno (1.25)**
> Depende de: Fase 10 · Habilita: Fase 12
> Proyecto que avanza: **AtlasSync** (persistencia)
> Mini proyectos: `bson-lab`, `aggregation-lab`

---

## 🎯 1. Propósito

AtlasSync lleva una fase guardando países y tipos de cambio en memoria y en un
archivo JSON. Hoy recibe su persistencia definitiva.

Pero esta fase no va de aprender a usar un driver. Va de **saber cuándo un
documento es la forma correcta del dato y cuándo no**, que es una decisión de
diseño que se toma una vez y se paga durante años. La pregunta que hay que
responder antes de escribir una línea es por qué AtlasSync usa MongoDB y OpsReport
no — y la respuesta tiene que ser sobre la forma del dato, no sobre la moda ni
sobre qué había levantado en el `compose.yaml`.

Al terminar, sabes modelar en documentos con criterio y **sabes decir que no**,
que es la mitad más valiosa.

---

## ✅ 2. Qué queda listo al terminar

- [ ] MongoDB corre en el `compose.yaml` y AtlasSync persiste ahí sus tres
      colecciones: `countries`, `fx_rates` y `sync_runs`.
- [ ] Los índices están creados desde código, de forma idempotente, y sabes
      justificar cada uno contra una consulta concreta.
- [ ] `fx_rates` tiene un índice TTL que borra el histórico antiguo solo.
- [ ] Hay al menos una consulta de agregación real, con su paralelo a `GROUP BY`
      escrito al lado.
- [ ] Las actualizaciones son atómicas con operadores, no lectura-modificación-
      escritura.
- [ ] La ingesta es un `upsert` masivo con `BulkWrite`, no un bucle de
      `InsertOne`.
- [ ] El campo `Raw` guarda el documento de origen y **sabes cuándo se vuelve un
      vertedero**.
- [ ] Los tests de integración corren contra un MongoDB real en contenedor, y la
      suite rápida sigue sin tocar nada.
- [ ] Tienes escrito, en tu propio documento, cuándo **no** usarías MongoDB.

---

## 🚫 3. Qué NO entra todavía

- Caché con Valkey → Fase 12. Hoy toda lectura va a MongoDB, y en la Fase 12
  mediremos si eso importa — con la caché en memoria de la Fase 10 como línea base.
- Ingesta programada → Fase 13. Hoy se dispara con `POST /sync`.
- Replicación, *sharding* y particionado → **fuera del curso**. Se nombran en el
  ⚖️ veredicto.
- Mongo como base de datos primaria de un sistema transaccional → nunca en este
  curso, y se explica por qué.
- Métricas y trazas del driver → Fase 14.
- Change Streams → se nombran en el ⚖️ y se quedan fuera.

---

## 🧠 4. Concepto mínimo

### Por qué AtlasSync usa Mongo y OpsReport no

**Esta es la sección importante de la fase.** Todo lo demás es API.

Mira un país de REST Countries, recortado a lo que cabe en una página:

```json
{
  "name": {
    "common": "Colombia",
    "official": "Republic of Colombia",
    "nativeName": {
      "spa": { "official": "República de Colombia", "common": "Colombia" }
    }
  },
  "cca2": "CO", "cca3": "COL", "ccn3": "170",
  "currencies": {
    "COP": { "name": "Colombian peso", "symbol": "$" }
  },
  "languages": { "spa": "Spanish" },
  "timezones": ["UTC-05:00"],
  "region": "Americas", "subregion": "South America",
  "flags": { "png": "...", "svg": "...", "alt": "..." }
}
```

Y ahora Suiza, que tiene **cuatro idiomas oficiales** y por tanto cuatro nombres
nativos. Y Estados Unidos, con **once zonas horarias**. Y la Antártida, que **no
tiene moneda ni idioma**. Y Sudáfrica, con **once idiomas oficiales**.

**Normalizar esto a tablas relacionales:**

```sql
countries (cca3, common_name, official_name, region, subregion, population)
country_names       (cca3, lang_code, official, common)   -- 1:N
country_currencies  (cca3, code, name, symbol)            -- 1:N
country_languages   (cca3, lang_code, name)               -- 1:N
country_timezones   (cca3, tz)                            -- 1:N
country_flags       (cca3, png, svg, alt)                 -- 1:1
```

Seis tablas. Y ahora la pregunta que decide: **¿cuál es el patrón de acceso?**

En AtlasSync, el 99% de las lecturas es *"dame el país COL entero"*, para
devolverlo por la API. Con el modelo relacional, eso es un `JOIN` de seis tablas —
o seis consultas— **para volver a ensamblar exactamente el documento que la fuente
nos dio**.

> 🧭 **La regla que decide, y se aplica a las dos direcciones.** Si **siempre lees
> el agregado entero** y **casi nunca consultas sus partes por separado**,
> descomponerlo en tablas es trabajo sin destinatario. Si consultas las partes de
> forma independiente, o si las partes tienen su propio ciclo de vida, las tablas
> ganan.

**Y el contraejemplo, que es igual de importante: por qué OpsReport NO usa Mongo.**

Un `WorkItem` tiene forma fija: nueve campos, todos siempre presentes, todos del
mismo tipo. Y sus consultas son:

```sql
-- Filtrar por estado, ordenar por dos criterios, limitar.
WHERE status = 'queued' ORDER BY priority DESC, created_at ASC LIMIT 10

-- Reclamar atómicamente con bloqueo de fila.
SELECT ... FOR UPDATE SKIP LOCKED

-- Contar y agrupar para el reporte mensual.
SELECT kind, status, COUNT(*), AVG(duration_ms) FROM ... GROUP BY kind, status

-- Y lo que de verdad lo decide: una transacción que escribe el work item Y el
-- evento del outbox, atómicamente (Fase 13).
```

Forma fija, consultas por atributos, agregaciones, transacciones multi-tabla.
**Eso es una base de datos relacional**, y usar Mongo ahí sería la respuesta
equivocada aunque funcionara.

| | `Country` (AtlasSync) | `WorkItem` (OpsReport) |
|---|---|---|
| Forma del dato | irregular, anidada, cambiante | fija, plana |
| Patrón de lectura | el agregado entero, por clave | filtrado por atributos, ordenado |
| Escrituras | ingesta masiva diaria | alta frecuencia, campo a campo |
| ¿Necesita transacciones multi-entidad? | no | **sí** (outbox, Fase 13) |
| ¿Las partes tienen vida propia? | no | las ejecuciones, sí |
| ¿Quién define la forma? | **un tercero** | nosotros |
| **Decisión** | **documento** | **relacional** |

La última fila es la que más pesa y la que menos se dice: **cuando la forma del
dato la define un tercero que puede cambiarla sin avisarte, guardar el documento
tal como llega es más robusto que imponerle un esquema que se rompe cuando ese
tercero añade un campo.**

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El instinto:** *"esquemaless significa que no tengo que pensar el esquema"*. Es
el argumento de venta de hace diez años y suena a libertad: añades campos cuando
quieras, no hay migraciones, el desarrollo va más rápido.

**Qué pasa si lo aplicas.** A los seis meses, la colección `countries` tiene:

- Documentos con `population` como número y otros con `population` como cadena,
  porque alguien cambió el parser un martes.
- Documentos con `currencies` como array y otros como objeto, porque la fuente
  cambió de forma y nadie migró los viejos.
- Tres campos `updatedAt`, `updated_at` y `lastUpdate`, de tres épocas del código.
- Y un `metadata` con dieciocho claves distintas, ninguna documentada.

Y el código que los lee está lleno de esto:

```go
// ☕
if v, ok := doc["population"]; ok {
	switch n := v.(type) {
	case int32:
		c.Population = int64(n)
	case int64:
		c.Population = n
	case float64:
		c.Population = int64(n)
	case string:
		c.Population, _ = strconv.ParseInt(n, 10, 64)
	}
}
```

**Qué pensar en su lugar.** El esquema **existe siempre**. La pregunta es dónde
vive:

- En una base relacional, vive en la base de datos, lo impone el motor, y cambiarlo
  es una migración explícita y revisable.
- En una base documental, vive en **tu código** — en el struct con etiquetas BSON —
  y lo impone tu decodificador. Cambiarlo sigue siendo una migración; lo que
  cambia es que **nadie te obliga a hacerla**, y esa es toda la diferencia.

> 🧭 **Regla del proyecto.** *"Esquemaless"* significa **"esquema en el código"**,
> no "sin esquema". El struct de Go **es** el esquema de AtlasSync, lleva un campo
> `SchemaVersion`, y un cambio de forma es una migración que se escribe — aunque
> Mongo no la pida.

Y la herramienta que hace esto verificable, que casi nadie usa: **la validación de
esquema de MongoDB.**

```go
// MongoDB SÍ tiene validación de esquema desde la 3.6, con JSON Schema. Que sea
// opcional no significa que sea inútil: convierte "el código debería escribir
// bien" en "la base rechaza lo que esté mal".
//
// Es el equivalente de los CHECK de la Fase 09, y por la misma razón: defiende
// contra escrituras que no pasen por tu servicio.
validator := bson.M{
	"$jsonSchema": bson.M{
		"bsonType": "object",
		"required": []string{"_id", "cca3", "commonName", "schemaVersion", "updatedAt"},
		"properties": bson.M{
			"cca3": bson.M{
				"bsonType":    "string",
				"pattern":     "^[A-Z]{3}$",
				"description": "código ISO 3166-1 alfa-3",
			},
			"population": bson.M{
				"bsonType":    "long",
				"minimum":     0,
				"description": "población; entero, nunca cadena",
			},
			"schemaVersion": bson.M{"bsonType": "int", "minimum": 1},
		},
	},
}
```

### BSON: no es JSON, y las diferencias muerden

```go
type Country struct {
	// _id es la clave primaria y SIEMPRE existe. Si no la das, Mongo genera un
	// ObjectID. Aquí usamos el código ISO como clave natural: es estable, es
	// único, y evita un índice extra.
	Code string `bson:"_id"`

	CommonName   string            `bson:"commonName"`
	OfficialName string            `bson:"officialName"`
	NativeNames  map[string]Name   `bson:"nativeNames,omitempty"`
	Currencies   []Currency        `bson:"currencies"`
	Languages    map[string]string `bson:"languages,omitempty"`
	Timezones    []string          `bson:"timezones"`
	Region       string            `bson:"region"`
	Subregion    string            `bson:"subregion,omitempty"`
	Population   int64             `bson:"population"`

	// El esquema en el código, versionado. Un lector puede decidir qué hacer con
	// un documento de una versión que no conoce, en vez de decodificarlo mal.
	SchemaVersion int `bson:"schemaVersion"`

	UpdatedAt time.Time `bson:"updatedAt"`
	Source    string    `bson:"source"`

	// Raw guarda el documento de origen intacto. Ver §6.5: cuesta espacio, salva
	// el día que alguien pregunta por un campo no modelado, y tiene un punto en
	// el que se vuelve un vertedero.
	Raw bson.Raw `bson:"raw,omitempty"`
}
```

**Las cinco diferencias con `encoding/json` que hay que saber:**

**1. La etiqueta es `bson`, no `json`, y son independientes.** Un struct puede
tener las dos, y de hecho las tiene: la etiqueta `json` gobierna la API pública y
la `bson` el almacenamiento. Que puedan divergir es una **feature**: permite
renombrar un campo en la API sin migrar la colección.

**2. El nombre por defecto es en minúsculas, no el del campo.** Si omites la
etiqueta, `CommonName` se guarda como `commonname` —todo junto y en minúsculas—,
no como `CommonName` ni como `commonName`. Es una fuente de sorpresa garantizada.
**Pon siempre la etiqueta.**

**3. `omitempty` tiene la misma trampa que en JSON:** omite el valor **cero**, no
el "vacío semántico". Un `population: 0` desaparece del documento.

**4. Hay tipos que JSON no tiene:** `ObjectID`, `Decimal128` —que es el tipo
correcto para dinero, a diferencia de `double`—, `Timestamp`, `Binary`,
`Date`. Y `time.Time` se guarda como `Date` con **precisión de milisegundos**: si
guardas un `time.Time` con nanosegundos y lo lees, **no es igual**. Ese es el bug
del ejercicio 5.

**5. El orden de los campos importa** en algunas operaciones. `bson.D` es un
documento **ordenado** (un slice de pares) y `bson.M` es un mapa **desordenado**.
Para un filtro simple da igual; para una clave compuesta de índice o para el
operador `$and`, no.

```go
bson.M{"cca3": "COL", "region": "Americas"}              // desordenado; para filtros
bson.D{{Key: "cca3", Value: 1}, {Key: "region", Value: 1}} // ORDENADO; para índices
bson.A{"COL", "MEX", "PER"}                               // array
```

> ⚠️ **`bson.M` en la definición de un índice compuesto es un bug.** El orden de
> las claves de un índice determina qué consultas puede servir, y un mapa de Go no
> tiene orden garantizado. Con `bson.M`, el índice que creas puede ser distinto en
> cada arranque. **Los índices se declaran siempre con `bson.D`.**

### 🩻 Esto sí funciona igual

- **Los índices son índices.** Un índice compuesto sirve consultas por su prefijo,
  el orden de las columnas importa, y un índice que no se usa cuesta espacio y
  escrituras. Todo tu criterio se traslada.
- **`explain()` es `EXPLAIN`.** Se lee distinto y dice lo mismo: qué índice se usó,
  cuántos documentos se examinaron, cuántos se devolvieron.
- **La agregación es SQL con otra sintaxis.** `$match` es `WHERE`, `$group` es
  `GROUP BY`, `$sort` es `ORDER BY`, `$project` es `SELECT`. El pensamiento es el
  mismo.
- **El N+1 existe igual**, y se produce igual: un bucle que consulta por cada
  elemento.
- **La paginación por cursor** es la misma técnica de la Fase 09, con la misma
  ventaja sobre `skip`.
- **Modelar pensando en las consultas** es buena práctica en los dos mundos. La
  diferencia es de grado: en Mongo es obligatorio, porque no puedes arreglar un mal
  modelo con un `JOIN`.
- **Y el driver se conecta con un pool**, igual que `database/sql`, con los mismos
  parámetros y las mismas consecuencias si no lo configuras.

---

## 🛠️ 5. CLI de la fase

```bash
make up
docker compose exec mongo mongosh meridian

# Los comandos de mongosh que más se usan:
#   show collections
#   db.countries.countDocuments()
#   db.countries.findOne({_id: "COL"})
#   db.countries.getIndexes()
#   db.countries.stats()          → tamaño, tamaño medio de documento, índices

# find con proyección: el segundo argumento limita qué campos vuelven. Es el
# equivalente de no hacer SELECT *, y en Mongo importa más porque los documentos
# pueden ser grandes.
docker compose exec mongo mongosh meridian --eval '
  db.countries.find({region: "Americas"}, {commonName: 1, currencies: 1}).limit(5)
'

# EXPLAIN. "executionStats" es el modo que da los números reales; el modo por
# defecto solo da el plan.
docker compose exec mongo mongosh meridian --eval '
  db.countries.find({region: "Americas"}).explain("executionStats").executionStats
'
# Los tres campos que importan:
#   nReturned            → documentos devueltos
#   totalDocsExamined    → documentos LEÍDOS. Si es mucho mayor que nReturned,
#                          falta un índice.
#   totalKeysExamined    → entradas de índice leídas
#   executionTimeMillis

# Ver si una consulta hizo COLLSCAN (escaneo completo) o IXSCAN (índice).
docker compose exec mongo mongosh meridian --eval '
  db.countries.find({population: {$gt: 1000000}}).explain().queryPlanner.winningPlan
'

# Las consultas lentas: el perfilador. Nivel 1 registra las que superan el umbral.
docker compose exec mongo mongosh meridian --eval '
  db.setProfilingLevel(1, {slowms: 50});
'
docker compose exec mongo mongosh meridian --eval '
  db.system.profile.find().sort({ts: -1}).limit(5).pretty()
'

# Tamaño real de un documento, para el laboratorio del límite de 16 MB.
docker compose exec mongo mongosh meridian --eval '
  Object.bsonsize(db.countries.findOne({_id: "COL"}))
'

# Exportar e importar, para el corpus de pruebas.
docker compose exec mongo mongoexport --db=meridian --collection=countries \
  --out=/tmp/countries.json --jsonArray
docker compose cp mongo:/tmp/countries.json ./services/atlassync/testdata/

# Tests de integración, con el mismo build tag de la Fase 09.
go test -tags=integration ./internal/mongodb -v

# Y la documentación del driver desde la terminal.
go doc go.mongodb.org/mongo-driver/v2/mongo Collection.FindOne
go doc go.mongodb.org/mongo-driver/v2/bson
```

> 💡 **`totalDocsExamined` frente a `nReturned` es el número que resuelve el 90% de
> los problemas de rendimiento en Mongo.** Si examinas 250.000 documentos para
> devolver 20, falta un índice o el que hay no sirve para esa consulta. Es el
> equivalente exacto de ver un `Seq Scan` en un `EXPLAIN` de PostgreSQL.

---

## 💻 6. Construcción guiada

### 6.1 Mini proyecto: `bson-lab`

Las trampas del mapeo, una por una.

```go
// labs/bson-lab/traps.go
package bsonlab

// 1. LA ETIQUETA AUSENTE.
type NoTags struct {
	CommonName string
	UpdatedAt  time.Time
}
// Se guarda como: { commonname: "...", updatedat: ... }
// Todo junto, todo en minúsculas. NO es CommonName ni commonName.

// 2. LA PRECISIÓN DE time.Time.
type Timestamped struct {
	At time.Time `bson:"at"`
}
// Mongo guarda las fechas como Date: milisegundos desde la época, UTC.
// Un time.Time con nanosegundos PIERDE los nanosegundos al guardarse, y además
// pierde la zona horaria (siempre vuelve en UTC).
//
// Consecuencia práctica: `saved.At.Equal(original.At)` es FALSO si el original
// tenía precisión de nanosegundos, y un golden test de ida y vuelta falla.
// Se resuelve truncando a milisegundos ANTES de guardar:
//     doc.At = t.UTC().Truncate(time.Millisecond)

// 3. DINERO EN float64.
type BadMoney struct {
	Rate float64 `bson:"rate"`   // ❌ double de IEEE 754
}
type GoodMoney struct {
	// Decimal128 es el tipo decimal exacto de Mongo, equivalente a NUMERIC de
	// PostgreSQL o a BigDecimal de Java. Para tipos de cambio importa: un
	// float64 acumula error al multiplicar.
	Rate bson.Decimal128 `bson:"rate"`
}

// 4. OMITEMPTY Y EL VALOR CERO.
type WithOmit struct {
	Population int64 `bson:"population,omitempty"`  // ❌ population: 0 desaparece
	Active     bool  `bson:"active,omitempty"`      // ❌ active: false desaparece
}
// Si necesitas distinguir "no se sabe" de "es cero", el campo es un puntero.

// 5. EL CAMPO AÑADIDO Y LOS DOCUMENTOS VIEJOS.
type V2 struct {
	Code       string `bson:"_id"`
	CommonName string `bson:"commonName"`
	// Campo nuevo, que los documentos guardados antes NO tienen.
	// Al decodificar un documento viejo, este campo queda en su valor cero SIN
	// ERROR. Eso es cómodo y es peligroso: un "" indistinguible de un valor real
	// vacío.
	//
	// La defensa es el campo de versión, y actuar sobre él.
	ISO4217    string `bson:"iso4217"`
	SchemaVersion int `bson:"schemaVersion"`
}

// 6. EL CAMPO ELIMINADO DEL STRUCT.
// Un campo que existe en el documento y NO en el struct se IGNORA en silencio al
// decodificar. Y si después guardas ese struct con ReplaceOne, el campo
// DESAPARECE del documento.
//
// Es la forma más fácil de perder datos en Mongo, y no da ningún error.
// Por eso la regla de §6.4: se actualiza con operadores ($set), no con Replace.
```

🧨 **Rompe a propósito.** El punto 6, que es el que de verdad duele:

```go
func TestReplaceOneLosesFields(t *testing.T) {
	coll := setupMongo(t)

	// Guardamos un documento con un campo extra que nuestro struct no conoce.
	_, err := coll.InsertOne(ctx, bson.M{
		"_id":          "COL",
		"commonName":   "Colombia",
		"legacyField":  "dato que alguien necesitaba",  // no está en el struct
	})

	// Leemos, modificamos y guardamos con ReplaceOne.
	var c Country
	coll.FindOne(ctx, bson.M{"_id": "COL"}).Decode(&c)
	c.CommonName = "República de Colombia"
	coll.ReplaceOne(ctx, bson.M{"_id": "COL"}, c)

	// Y legacyField YA NO EXISTE.
	var raw bson.M
	coll.FindOne(ctx, bson.M{"_id": "COL"}).Decode(&raw)
	if _, ok := raw["legacyField"]; ok {
		t.Log("el campo sobrevivió")
	} else {
		t.Log("❌ el campo desapareció, y no hubo ningún error")
	}
}
```

**Un servicio que lee, modifica y reemplaza borra en silencio todo lo que su
versión del struct no conoce.** Con dos versiones del servicio desplegadas a la vez
—que es lo normal durante un despliegue— la versión antigua borra los campos que
la nueva escribe, en bucle. Es un incidente muy desagradable de diagnosticar.

> 🧭 **Regla del proyecto.** Se actualiza con **operadores** (`$set`, `$inc`,
> `$push`), nunca con `ReplaceOne` sobre un struct parcial. `ReplaceOne` solo se
> usa cuando de verdad quieres sustituir el documento entero **y** sabes que tu
> struct lo cubre por completo.

### 6.2 La conexión y los índices

```go
// services/atlassync/internal/mongodb/client.go

// Package mongodb implementa los almacenes de AtlasSync sobre MongoDB.
package mongodb

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
	"go.mongodb.org/mongo-driver/v2/mongo/readconcern"
	"go.mongodb.org/mongo-driver/v2/mongo/writeconcern"
)

func Connect(ctx context.Context, cfg Config) (*mongo.Client, error) {
	opts := options.Client().
		ApplyURI(cfg.URI).

		// El pool, con los mismos parámetros y las mismas consecuencias que el
		// de database/sql en la Fase 09. Aquí los valores por defecto son más
		// razonables (MaxPoolSize=100), pero el techo sigue siendo tuyo.
		SetMaxPoolSize(cfg.MaxPoolSize).
		SetMinPoolSize(cfg.MinPoolSize).
		SetMaxConnIdleTime(2 * time.Minute).

		// Plazos. ServerSelectionTimeout es cuánto se espera a encontrar un
		// servidor disponible: con un conjunto de réplicas en failover, es el
		// tiempo que el servicio tolera sin primario.
		SetServerSelectionTimeout(5 * time.Second).
		SetConnectTimeout(5 * time.Second).
		SetTimeout(10 * time.Second).

		// Write concern: cuántos nodos deben confirmar la escritura.
		// "majority" es lo correcto para datos que no se pueden perder; w=1 es
		// más rápido y pierde escrituras en un failover.
		//
		// Para AtlasSync —datos de referencia que se pueden volver a ingerir—
		// w=1 sería defendible. Usamos majority porque el coste es bajo (pocas
		// escrituras) y el razonamiento hay que dejarlo escrito.
		SetWriteConcern(writeconcern.Majority()).

		// Read concern "majority" evita leer datos que puedan revertirse en un
		// failover.
		SetReadConcern(readconcern.Majority())

	client, err := mongo.Connect(opts)
	if err != nil {
		return nil, fmt.Errorf("conectando a mongodb: %w", err)
	}

	// Igual que el Ping de la Fase 09: Connect no contacta con el servidor.
	// Sin esto, el servicio arranca con una URI mal escrita.
	pingCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	if err := client.Ping(pingCtx, nil); err != nil {
		return nil, fmt.Errorf("verificando la conexión a mongodb: %w", err)
	}
	return client, nil
}
```

Y los índices, **creados desde el código y de forma idempotente**:

```go
// EnsureIndexes crea los índices si no existen. Es idempotente: CreateMany sobre
// un índice que ya existe con la misma definición no hace nada.
//
// Que los índices vivan en el código y no en un script suelto es una decisión:
// en Mongo no hay migraciones como en la Fase 09, así que si no están aquí,
// están en la memoria de quien montó el entorno — y en el entorno nuevo, no
// están.
//
// ⚠️ El intercambio: con una colección grande, crear un índice en el arranque
// bloquea. En producción se crean con `background: true` o fuera de la ruta de
// arranque. Para AtlasSync, con 250 documentos, esto es correcto.
func EnsureIndexes(ctx context.Context, db *mongo.Database) error {
	countries := db.Collection("countries")

	_, err := countries.Indexes().CreateMany(ctx, []mongo.IndexModel{
		{
			// Consulta: buscar por moneda. "¿qué países usan COP?"
			// El índice sobre un array indexa CADA elemento: es un índice
			// multiclave, y es una de las cosas que Mongo hace mejor que una
			// columna con un array en SQL.
			Keys: bson.D{{Key: "currencies.code", Value: 1}},
			Options: options.Index().SetName("currencies_code_idx"),
		},
		{
			// Consulta: listar por región, ordenado por nombre. El ORDEN de las
			// claves importa: este índice sirve {region} y {region, commonName},
			// pero NO {commonName} solo.
			Keys: bson.D{
				{Key: "region", Value: 1},
				{Key: "commonName", Value: 1},
			},
			Options: options.Index().SetName("region_name_idx"),
		},
		{
			// Índice de TEXTO para la búsqueda por nombre. Tokeniza, quita
			// palabras vacías y aplica raíces según el idioma.
			//
			// ⚠️ Solo puede haber UN índice de texto por colección, y eso es una
			// limitación seria. Para búsqueda de verdad, Atlas Search o
			// Elasticsearch; este sirve para un buscador simple.
			Keys: bson.D{
				{Key: "commonName", Value: "text"},
				{Key: "officialName", Value: "text"},
			},
			Options: options.Index().
				SetName("name_text_idx").
				SetDefaultLanguage("spanish").
				// Los pesos hacen que una coincidencia en el nombre común valga
				// más que en el oficial.
				SetWeights(bson.D{
					{Key: "commonName", Value: 10},
					{Key: "officialName", Value: 3},
				}),
		},
	})
	if err != nil {
		return fmt.Errorf("creando índices de countries: %w", err)
	}

	rates := db.Collection("fx_rates")
	_, err = rates.Indexes().CreateMany(ctx, []mongo.IndexModel{
		{
			// La clave natural del histórico: par de monedas y fecha.
			// Único: no puede haber dos tipos para el mismo par el mismo día.
			Keys: bson.D{
				{Key: "base", Value: 1},
				{Key: "quote", Value: 1},
				{Key: "day", Value: -1},
			},
			Options: options.Index().SetName("rate_key_idx").SetUnique(true),
		},
		{
			// ÍNDICE TTL: Mongo borra solo los documentos cuyo campo `expiresAt`
			// ya pasó. No hay que escribir una tarea de limpieza.
			//
			// ⚠️ Tres cosas que hay que saber:
			//  1. El proceso de borrado corre cada 60 SEGUNDOS. No es inmediato,
			//     así que un documento puede sobrevivir hasta un minuto tras
			//     expirar. No sirve para expirar una sesión con precisión.
			//  2. El campo TIENE que ser una fecha (o un array de fechas). Si es
			//     un número o una cadena, el índice se crea y NO BORRA NADA.
			//     Silenciosamente.
			//  3. ExpireAfterSeconds(0) significa "borra cuando la fecha del
			//     campo haya pasado", que es lo que queremos.
			Keys:    bson.D{{Key: "expiresAt", Value: 1}},
			Options: options.Index().SetName("rates_ttl_idx").SetExpireAfterSeconds(0),
		},
	})
	if err != nil {
		return fmt.Errorf("creando índices de fx_rates: %w", err)
	}
	return nil
}
```

> 🧪 **Prueba de fuego.** Crea un índice TTL sobre un campo que sea un `int64` con
> la marca de tiempo Unix en vez de una fecha. El índice se crea sin error y
> **nunca borra nada**. Espera cinco minutos y comprueba que los documentos siguen
> ahí.
>
> **La mentira de la pantalla:** `getIndexes()` muestra el índice con su
> `expireAfterSeconds`, todo parece correcto, y la colección crece sin parar hasta
> que alguien se pregunta por qué el disco está lleno. Es un fallo silencioso
> clásico de Mongo y solo se detecta con un test que espere de verdad.

### 6.3 La ingesta: `upsert` masivo con `BulkWrite`

```go
// services/atlassync/internal/mongodb/countries.go

// UpsertAll guarda o actualiza todos los países de una ingesta.
//
// UN BulkWrite en vez de 250 UpdateOne. La diferencia no es solo de rendimiento:
// con 250 llamadas, un fallo a mitad deja la colección en un estado mezclado y
// no hay forma limpia de reanudar. Con BulkWrite, el resultado dice exactamente
// qué se escribió.
func (s *CountryStore) UpsertAll(ctx context.Context, countries []countries.Country, now time.Time) (UpsertResult, error) {
	if len(countries) == 0 {
		return UpsertResult{}, nil
	}

	models := make([]mongo.WriteModel, 0, len(countries))
	for _, c := range countries {
		doc := toDocument(c, now)

		models = append(models, mongo.NewUpdateOneModel().
			SetFilter(bson.M{"_id": c.Code}).
			// $set actualiza los campos dados y DEJA INTACTO todo lo demás.
			// Es la diferencia con ReplaceOne del 🧨 de §6.1.
			//
			// $setOnInsert pone campos SOLO si el documento se crea: así
			// firstSeenAt refleja cuándo apareció el país por primera vez y no
			// se pisa en cada ingesta.
			SetUpdate(bson.M{
				"$set": doc,
				"$setOnInsert": bson.M{
					"firstSeenAt": now,
				},
				// $inc lleva la cuenta de ingestas sin leer el valor anterior:
				// es atómico y no tiene carrera.
				"$inc": bson.M{"ingestCount": 1},
			}).
			SetUpsert(true))
	}

	// ordered=false permite que Mongo siga tras un fallo individual y los
	// ejecute en paralelo. Con ordered=true (el valor por defecto), un país que
	// falla aborta los 200 siguientes.
	//
	// Para una ingesta idempotente donde cada documento es independiente,
	// unordered es lo correcto.
	opts := options.BulkWrite().SetOrdered(false)

	res, err := s.coll.BulkWrite(ctx, models, opts)
	if err != nil {
		// Un BulkWriteException con ordered=false puede traer errores parciales
		// Y resultados válidos. Hay que mirar los dos.
		var bwe mongo.BulkWriteException
		if errors.As(err, &bwe) {
			s.logger.Warn("la ingesta tuvo fallos parciales",
				slog.Int("fallos", len(bwe.WriteErrors)),
				slog.Int("insertados", int(res.UpsertedCount)),
				slog.Int("modificados", int(res.ModifiedCount)))

			// Se devuelve el resultado parcial Y el error: quien llama decide.
			return UpsertResult{
				Inserted: res.UpsertedCount,
				Updated:  res.ModifiedCount,
				Failed:   len(bwe.WriteErrors),
			}, fmt.Errorf("ingesta parcial: %d de %d fallaron: %w",
				len(bwe.WriteErrors), len(models), err)
		}
		return UpsertResult{}, fmt.Errorf("escribiendo la ingesta: %w", err)
	}

	return UpsertResult{
		Inserted: res.UpsertedCount,
		Updated:  res.ModifiedCount,
		Matched:  res.MatchedCount,
	}, nil
}
```

📖 En Spring Data MongoDB esto sería `BulkOperations` con
`BulkMode.UNORDERED`, y el paralelo es exacto. La diferencia es que aquí la
construcción de los modelos es explícita y ves qué operadores se aplican.

### 6.4 Actualizaciones atómicas: los operadores

```go
// ❌ Lectura-modificación-escritura: tiene una CARRERA.
//    Entre el Find y el Replace, otra goroutine (o otra instancia) pudo
//    modificar el documento, y su cambio se pierde.
var c Country
coll.FindOne(ctx, bson.M{"_id": code}).Decode(&c)
c.Population = newPopulation
coll.ReplaceOne(ctx, bson.M{"_id": code}, c)

// ✅ Atómico con operadores: una sola operación en el servidor, sin ventana.
coll.UpdateOne(ctx,
	bson.M{"_id": code},
	bson.M{
		"$set": bson.M{"population": newPopulation, "updatedAt": now},
		"$inc": bson.M{"revision": 1},
	})
```

Es exactamente la lección de la actualización perdida de la Fase 09 (§6.5), en
otro motor. **El problema es el mismo y la solución tiene la misma forma: que el
servidor haga la operación, no tú.**

Los operadores que AtlasSync usa:

```go
// $set, $unset — asignar y borrar campos
// $inc          — incrementar sin leer
// $push, $addToSet, $pull — operar sobre arrays
// $min, $max    — "guarda solo si es menor/mayor que lo que hay"
// $currentDate  — la fecha del SERVIDOR, no la del cliente

// El caso de $max, que es elegante y poco conocido: registrar el valor más alto
// visto sin leer el anterior ni tener una carrera.
coll.UpdateOne(ctx,
	bson.M{"_id": code},
	bson.M{"$max": bson.M{"peakPopulation": current}})
```

**Y la actualización condicional, que es el bloqueo optimista de toda la vida:**

```go
// El filtro incluye la revisión esperada. Si otro la cambió, MatchedCount es 0 y
// sabemos que perdimos la carrera.
//
// Es exactamente @Version de JPA, escrito a mano. Y como en la Fase 09, la
// diferencia es que aquí se ve.
res, err := coll.UpdateOne(ctx,
	bson.M{"_id": code, "revision": expectedRevision},
	bson.M{
		"$set": bson.M{"population": newPopulation},
		"$inc": bson.M{"revision": 1},
	})
if err != nil {
	return fmt.Errorf("actualizando %s: %w", code, err)
}
if res.MatchedCount == 0 {
	return fmt.Errorf("%w: el documento %s cambió bajo nuestros pies", ErrConflict, code)
}
```

Y `FindOneAndUpdate`, que devuelve el documento y lo modifica en una operación:

```go
// ReturnDocument(options.After) devuelve el documento YA modificado.
// Es la versión Mongo del RETURNING de PostgreSQL (Fase 09), y sirve para lo
// mismo: reclamar trabajo de forma atómica.
var run SyncRun
err := s.runs.FindOneAndUpdate(ctx,
	bson.M{"status": "pending"},
	bson.M{"$set": bson.M{"status": "running", "startedAt": now}},
	options.FindOneAndUpdate().
		SetSort(bson.D{{Key: "scheduledAt", Value: 1}}).
		SetReturnDocument(options.After),
).Decode(&run)
```

### 6.5 El campo `Raw`: cuándo salva el día y cuándo es un vertedero

```go
type Country struct {
	// ... campos modelados ...

	// Raw guarda el documento de origen tal como llegó de REST Countries.
	//
	// POR QUÉ EXISTE: la fuente tiene cuarenta campos y modelamos doce. El día
	// que alguien de negocio pregunte "¿tenemos el prefijo telefónico?", la
	// respuesta es sí, está en Raw, y se puede modelar sin reingerir todo.
	//
	// QUÉ CUESTA: espacio. El documento completo de un país son unos 8 KB frente
	// a los 2 KB del modelado. Con 250 países da igual; con 250 millones de
	// registros, no.
	//
	// CUÁNDO SE VUELVE UN VERTEDERO, y esto es lo que hay que saber:
	//  - cuando alguien empieza a CONSULTAR contra Raw en vez de modelar el
	//    campo. Una consulta sobre raw.idd.root no tiene índice y hace COLLSCAN;
	//  - cuando el código de negocio lee de Raw, porque entonces el esquema
	//    real es el de la fuente y hemos perdido la capa de traducción;
	//  - cuando nadie recuerda por qué está y lleva dos años sin leerse.
	//
	// LA REGLA DEL CURSO: Raw es para INSPECCIÓN y MIGRACIÓN, nunca para
	// consulta ni para lógica de negocio. Si necesitas consultar un campo, se
	// modela. Y si en una revisión ves un filtro sobre `raw.`, eso es la señal.
	Raw bson.Raw `bson:"raw,omitempty"`
}
```

Y la decisión honesta, que merece estar escrita:

> ⚖️ **¿Merece la pena `Raw`?** Para AtlasSync, sí: la fuente es un tercero que
> puede cambiar, los volúmenes son pequeños (250 documentos), y el coste de
> reingerir para recuperar un campo perdido sería una llamada a una API que
> quizá ya no devuelva el histórico.
>
> **Para una colección de millones de documentos, casi nunca.** Duplicar el
> almacenamiento para un campo que quizá alguien necesite algún día es un coste
> real a cambio de una opción especulativa. La alternativa honesta es guardar el
> crudo **en otro sitio más barato** —un bucket, comprimido, por fecha de
> ingesta— y dejar la colección limpia.

### 6.6 Mini proyecto: `aggregation-lab`

La agregación con su paralelo a SQL al lado, que es como se aprende de verdad.

```go
// labs/aggregation-lab/pipelines.go
package agglab

// CountriesByRegion: cuántos países por región, con su población total.
//
// EN SQL:
//   SELECT region, COUNT(*) AS countries, SUM(population) AS population
//   FROM countries
//   WHERE region <> ''
//   GROUP BY region
//   ORDER BY population DESC
func CountriesByRegion(ctx context.Context, coll *mongo.Collection) ([]RegionStats, error) {
	pipeline := mongo.Pipeline{
		// $match = WHERE. VA PRIMERO SIEMPRE, y no es estético: si va después
		// de un $group, Mongo ya procesó todos los documentos. Poner el $match
		// al principio permite además usar un índice.
		{{Key: "$match", Value: bson.M{"region": bson.M{"$ne": ""}}}},

		// $group = GROUP BY. El _id es la clave de agrupación; puede ser un
		// campo, una expresión, o un documento con varios campos.
		{{Key: "$group", Value: bson.M{
			"_id":        "$region",
			"countries":  bson.M{"$sum": 1},
			"population": bson.M{"$sum": "$population"},
			// $avg, $min, $max, $first, $last — los mismos de SQL.
			"avgPop":     bson.M{"$avg": "$population"},
			// $push acumula en un array. NO tiene equivalente directo en SQL
			// estándar (se parece a array_agg de PostgreSQL), y es una de las
			// cosas que la agregación hace con naturalidad.
			"currencies": bson.M{"$addToSet": "$currencies.code"},
		}}},

		// $sort = ORDER BY
		{{Key: "$sort", Value: bson.D{{Key: "population", Value: -1}}}},

		// $project = SELECT. Renombra y calcula.
		{{Key: "$project", Value: bson.M{
			"_id":        0,
			"region":     "$_id",
			"countries":  1,
			"population": 1,
			"avgPop":     bson.M{"$round": bson.A{"$avgPop", 0}},
		}}},
	}

	cursor, err := coll.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, fmt.Errorf("agregando países por región: %w", err)
	}
	defer cursor.Close(ctx)

	// All decodifica TODO el resultado en memoria. Para 6 regiones es correcto.
	// Para un resultado grande, se recorre con cursor.Next — ver §6.7.
	var out []RegionStats
	if err := cursor.All(ctx, &out); err != nil {
		return nil, fmt.Errorf("decodificando el resultado: %w", err)
	}
	return out, nil
}

// RateVolatility: la volatilidad de cada moneda en los últimos 30 días.
//
// EN SQL sería una consulta con funciones de ventana:
//   SELECT quote, STDDEV(rate), MIN(rate), MAX(rate)
//   FROM fx_rates
//   WHERE base = 'EUR' AND day >= CURRENT_DATE - 30
//   GROUP BY quote
//   HAVING COUNT(*) >= 20
func RateVolatility(ctx context.Context, coll *mongo.Collection, base string, since time.Time) ([]Volatility, error) {
	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: bson.M{
			"base": base,
			"day":  bson.M{"$gte": since},
		}}},
		{{Key: "$group", Value: bson.M{
			"_id":     "$quote",
			"stdDev":  bson.M{"$stdDevSamp": "$rate"},
			"min":     bson.M{"$min": "$rate"},
			"max":     bson.M{"$max": "$rate"},
			"samples": bson.M{"$sum": 1},
		}}},
		// $match DESPUÉS de $group = HAVING.
		{{Key: "$match", Value: bson.M{"samples": bson.M{"$gte": 20}}}},
		{{Key: "$sort", Value: bson.D{{Key: "stdDev", Value: -1}}}},
		{{Key: "$limit", Value: 10}},
	}
	// ...
}

// $lookup = LEFT JOIN. Existe, y conviene saber tres cosas antes de usarlo:
//
//  1. NO es tan rápido como un JOIN en una base relacional: no hay optimizador
//     que reordene, y si la colección de la derecha no tiene índice sobre el
//     campo de unión, es un escaneo por cada documento de la izquierda. Un N+1
//     con otro nombre.
//  2. Si necesitas $lookup a menudo, es una SEÑAL de que el modelo debería estar
//     normalizado en una base relacional, o desnormalizado en Mongo. Es la
//     pregunta que hay que hacerse.
//  3. Para una consulta ocasional de informe, está bien y es legítimo.
func CountryWithLatestRate(ctx context.Context, db *mongo.Database, code string) (Enriched, error) {
	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: bson.M{"_id": code}}},
		{{Key: "$lookup", Value: bson.M{
			"from":         "fx_rates",
			"localField":   "currencies.code",
			"foreignField": "quote",
			"as":           "rates",
			// El pipeline interno limita lo que se trae: sin él, se traerían
			// TODOS los tipos históricos de esa moneda.
			"pipeline": mongo.Pipeline{
				{{Key: "$sort", Value: bson.D{{Key: "day", Value: -1}}}},
				{{Key: "$limit", Value: 1}},
			},
		}}},
	}
	// ...
}
```

> ⚠️ **`$match` primero, siempre.** Es la regla número uno de la agregación y la
> que más se incumple. Un `$match` al principio puede usar un índice y reduce el
> conjunto antes de trabajar; después de un `$group`, opera sobre el resultado
> completo. Compruébalo con `explain("executionStats")` y mira `totalDocsExamined`
> en las dos versiones.

### 6.7 `Decode` frente a `All`, y por qué importa

```go
// All decodifica TODO en memoria de una vez. Cómodo y correcto cuando el
// resultado es acotado y pequeño.
var countries []Country
if err := cursor.All(ctx, &countries); err != nil { ... }

// El bucle con Decode procesa UNO a la vez. La memoria es la de un documento,
// no la del resultado.
//
// Es exactamente B-06 de la Fase 03 (streaming frente a carga completa) aplicado
// a Mongo, y con el mismo criterio: si el resultado puede crecer, se recorre.
for cursor.Next(ctx) {
	var c Country
	if err := cursor.Decode(&c); err != nil {
		return fmt.Errorf("decodificando país: %w", err)
	}
	if err := process(ctx, c); err != nil {
		return err
	}
}
// cursor.Err() es OBLIGATORIO, por la misma razón que rows.Err() en la Fase 09:
// el bucle también termina por error, y sin esta comprobación devuelves un
// resultado parcial sin error.
if err := cursor.Err(); err != nil {
	return fmt.Errorf("recorriendo el cursor: %w", err)
}
```

Y la versión con iterador, que es la adopción de la Fase 08 rindiendo:

```go
// All devuelve un iterador en vez de un slice. El consumidor usa `for range` y
// la memoria sigue siendo la de un documento.
//
// Es el caso de uso que justificó adoptar iter.Seq2 en la Fase 08, y el único.
func (s *CountryStore) All(ctx context.Context) iter.Seq2[Country, error] {
	return func(yield func(Country, error) bool) {
		cursor, err := s.coll.Find(ctx, bson.M{})
		if err != nil {
			yield(Country{}, fmt.Errorf("consultando países: %w", err))
			return
		}
		defer cursor.Close(ctx)

		for cursor.Next(ctx) {
			var c Country
			if err := cursor.Decode(&c); err != nil {
				yield(Country{}, fmt.Errorf("decodificando país: %w", err))
				return
			}
			if !yield(c, nil) {
				return   // el consumidor hizo break; cerramos limpiamente
			}
		}
		if err := cursor.Err(); err != nil {
			yield(Country{}, fmt.Errorf("recorriendo países: %w", err))
		}
	}
}
```

### 6.8 Transacciones multi-documento, con su advertencia

```go
// Mongo tiene transacciones ACID multi-documento desde la 4.0, y funcionan.
//
// ⚠️ TRES ADVERTENCIAS ANTES DE USARLAS:
//
//  1. REQUIEREN un conjunto de réplicas (o un clúster fragmentado). Una
//     instancia suelta —como la del compose.yaml por defecto— NO las soporta, y
//     el error que da no es obvio. Para los tests hay que arrancar Mongo con
//     --replSet e iniciarlo.
//
//  2. CUESTAN. Mucho más que en una base relacional: hay coordinación, y una
//     transacción larga bloquea recursos en el servidor. El límite por defecto
//     son 60 segundos.
//
//  3. Y la advertencia de diseño, que es la importante: SI NECESITAS
//     TRANSACCIONES MULTI-DOCUMENTO A MENUDO, EL MODELO ESTÁ MAL. La promesa
//     del modelo documental es que el agregado que cambia junto vive junto y una
//     escritura de un documento ya es atómica. Necesitarlas siempre significa
//     que has normalizado, y entonces la pregunta es por qué no usas una base
//     relacional.
func (s *SyncStore) RecordRunAtomically(ctx context.Context, run SyncRun, countries []Country) error {
	session, err := s.client.StartSession()
	if err != nil {
		return fmt.Errorf("abriendo sesión: %w", err)
	}
	defer session.EndSession(ctx)

	_, err = session.WithTransaction(ctx, func(ctx context.Context) (any, error) {
		if _, err := s.runs.InsertOne(ctx, run); err != nil {
			return nil, fmt.Errorf("guardando la ejecución: %w", err)
		}
		if _, err := s.countries.BulkWrite(ctx, upsertModels(countries)); err != nil {
			return nil, fmt.Errorf("guardando países: %w", err)
		}
		return nil, nil
	})
	if err != nil {
		return fmt.Errorf("transacción de ingesta: %w", err)
	}
	return nil
}
```

> 🧭 **Decisión del curso.** AtlasSync **no usa transacciones multi-documento** en
> su camino normal. La ingesta es idempotente: si falla a mitad, se vuelve a
> ejecutar y el `upsert` deja el mismo resultado. **La idempotencia es más barata y
> más robusta que la transacción**, y cuando está disponible es la respuesta
> correcta. El código de arriba existe para el ejercicio 20 y para que sepas que
> existe.

### 6.9 Modelado: incrustar frente a referenciar

Lo que de verdad se transfiere de esta fase, porque el driver se olvida y esto no.

**Las tres preguntas que deciden:**

1. **¿Se leen juntos?** Si siempre que lees A lees B, incrustar.
2. **¿Cambian juntos?** Si B cambia mucho más que A, referenciar — o tendrás que
   reescribir A entero en cada cambio de B.
3. **¿Cuántos B hay por A?** Si son pocos y acotados, incrustar. Si crecen sin
   límite, referenciar: el documento tiene **16 MB** de techo.

| Relación | Decisión | Por qué |
|---|---|---|
| País → sus monedas (1–3) | **incrustar** | se leen juntos, cambian con el país, son pocos |
| País → sus idiomas (1–11) | **incrustar** | igual |
| País → su histórico de tipos de cambio (∞) | **referenciar** | crece sin límite, se consulta por su cuenta |
| Tipo de cambio → su día | **incrustar** (es un campo) | es un atributo, no una entidad |
| Ejecución de ingesta → países afectados | **referenciar** (solo los códigos) | 250 documentos completos no caben ni tienen sentido duplicados |

**El límite de 16 MB** parece enorme y se alcanza más rápido de lo que parece: un
documento que incrusta un array que crece —comentarios, eventos, mediciones— acaba
ahí. Y mucho antes de los 16 MB, el rendimiento se degrada: **cada actualización
reescribe el documento entero**, así que un documento de 2 MB al que le añades un
elemento mueve 2 MB.

> 🧭 **Regla del proyecto: nunca incrustes un array que crece sin cota.** Si no
> puedes escribir el número máximo de elementos en un comentario, no lo incrustes.

**Y los dos patrones que conviene conocer por nombre:**

**El patrón de atributo.** Cuando tienes muchos campos opcionales sobre los que a
veces se consulta:

```go
// ❌ Un campo por atributo: cada uno necesita su índice, y la mayoría son nulos.
type Bad struct {
	ISO4217   string
	ISO3166_1 string
	FIPS      string
	// ... y veinte más
}

// ✅ Patrón de atributo: un array de pares, con UN índice compuesto que los
// sirve todos.
type Country struct {
	Codes []Attribute `bson:"codes"`
}
type Attribute struct {
	Key   string `bson:"k"`
	Value string `bson:"v"`
}
// Índice: {"codes.k": 1, "codes.v": 1}
// Consulta: {"codes": {"$elemMatch": {"k": "fips", "v": "CO"}}}
```

**El patrón de cubo.** Cuando tienes series temporales con muchos puntos:

```go
// ❌ Un documento por punto: 365 documentos por moneda y año, con la sobrecarga
//    de _id e índices multiplicada por 365.
type RateBad struct {
	Base, Quote string
	Day         time.Time
	Rate        float64
}

// ✅ Patrón de cubo: un documento por mes, con los puntos dentro. Menos
//    documentos, menos índices, y la lectura de un mes es UN documento.
type RateBucket struct {
	Base, Quote string    `bson:"base,quote"`
	Month       time.Time `bson:"month"`
	Points      []Point   `bson:"points"`   // acotado: 31 como máximo
	Count       int       `bson:"count"`
	Min, Max    float64   `bson:"min,max"`  // precalculados en la escritura
}
```

El cubo tiene un tamaño **acotado por diseño** (31 puntos), que es lo que lo
distingue de incrustar un array sin cota. Y precalcular `min`/`max` al escribir
evita agregar al leer, que es la idea central de modelar para las consultas.

📖 MongoDB tiene desde la 5.0 *time series collections* que hacen esto
automáticamente. Conocer el patrón sigue importando: te dice **qué** está haciendo
esa colección especial por debajo.

---

## ⚰️ 7. Autopsia y errores comunes

### ⚰️ Autopsia: la colección relacional

**El cadáver.** Un equipo con Mongo ya levantado en la plataforma decidió usarlo
para el catálogo de productos de Meridian. Y lo modeló como habría modelado en SQL,
porque era lo que sabía:

```text
products      { _id, sku, name, categoryId, brandId, supplierId, ... }
categories    { _id, name, parentId }
brands        { _id, name, supplierId }
suppliers     { _id, name, countryCode }
prices        { _id, productId, storeId, amount, validFrom, validTo }
stock         { _id, productId, storeId, quantity }
```

Seis colecciones, con referencias entre ellas. Y la consulta más frecuente del
servicio —*"dame el producto con su categoría, su marca, su precio en esta tienda y
su stock"*— se resolvió así:

```go
// ☕ — el N+1 en Mongo, que es el mismo N+1 de siempre
func (r *Repo) GetProduct(ctx context.Context, sku string) (*Product, error) {
	var p Product
	r.products.FindOne(ctx, bson.M{"sku": sku}).Decode(&p)

	r.categories.FindOne(ctx, bson.M{"_id": p.CategoryID}).Decode(&p.Category)
	r.brands.FindOne(ctx, bson.M{"_id": p.BrandID}).Decode(&p.Brand)
	r.suppliers.FindOne(ctx, bson.M{"_id": p.Brand.SupplierID}).Decode(&p.Supplier)
	r.prices.FindOne(ctx, bson.M{"productId": p.ID, "storeId": storeID}).Decode(&p.Price)
	r.stock.FindOne(ctx, bson.M{"productId": p.ID, "storeId": storeID}).Decode(&p.Stock)

	return &p, nil
}
```

**Seis viajes de ida y vuelta por producto.** Para una página de catálogo con
cuarenta productos: doscientos cuarenta consultas.

**El informe forense:**

| | Mongo "relacional" ☕ | PostgreSQL | Mongo bien modelado |
|---|---|---|---|
| Consultas para un producto completo | **6** | 1 (con `JOIN`) | **1** |
| Consultas para 40 productos | **240** | 1 | 40, o 1 con `$in` |
| ¿El motor puede optimizar la unión? | **no** | sí, el planificador | n/a |
| Integridad referencial | **ninguna** | claves foráneas | n/a (está incrustado) |
| Atomicidad al cambiar producto y precio | **ninguna**, sin transacciones | garantizada | garantizada (un documento) |
| ¿Qué pasa si borras una categoría? | **referencias colgando** | lo impide la FK | n/a |
| Índices necesarios | 6+ | 4 | 2 |

**Las tres causas de la muerte, en orden de gravedad:**

**1. Se perdió lo que la base relacional daba** —integridad referencial,
atomicidad multi-tabla, un optimizador que reordena uniones— **sin ganar nada a
cambio.** Los datos tenían forma fija y regular: eran tablas.

**2. `$lookup` no rescata el diseño.** Se puede escribir la agregación, y sigue
sin haber optimizador: el orden de las uniones es el que escribas, y sin índice en
la colección de la derecha, cada documento de la izquierda provoca un escaneo.

**3. Y la causa raíz, que es la que hay que nombrar:** la decisión se tomó por
disponibilidad —*"ya lo tenemos levantado"*— y no por la forma del dato. Después,
el modelo se copió del esquema relacional que el equipo conocía.

**El fix, y el modelo correcto para ese caso:**

```go
// Si los datos son relacionales, van a PostgreSQL. Fin.
//
// Y SI hay una razón para que estén en Mongo —por ejemplo, que los atributos del
// producto varíen radicalmente por categoría: una camisa tiene talla y color, un
// televisor tiene pulgadas y resolución—, entonces el modelo correcto es
// desnormalizar lo que se lee junto:
type Product struct {
	SKU  string `bson:"_id"`
	Name string `bson:"name"`

	// Incrustado: categoría y marca se leen SIEMPRE con el producto y cambian
	// muy poco. El precio de duplicar el nombre de la categoría en 50.000
	// productos es un $set masivo el día que se renombra — que ocurre dos veces
	// al año y tarda segundos.
	Category Category `bson:"category"`
	Brand    Brand    `bson:"brand"`

	// El patrón de atributo para lo que varía por categoría. ESTO es lo que
	// justificaría Mongo aquí.
	Attributes []Attribute `bson:"attributes"`

	// Precio y stock NO se incrustan: cambian mil veces más que el producto y
	// son por tienda. Colección aparte, consultada con $in para un lote.
}
```

> ☕ **El patrón a memorizar.** **Usar Mongo con un modelo relacional es la peor de
> las dos opciones**: pierdes las garantías de la base relacional y no ganas las
> ventajas del modelo documental. Si vas a normalizar, usa una base relacional. Si
> vas a usar Mongo, desnormaliza — y si no puedes desnormalizar porque el dato es
> relacional, ahí tienes tu respuesta.

### Errores comunes

**1. Etiqueta `bson` ausente.**
*Síntoma:* los campos se guardan en minúsculas todo junto y las consultas no
encuentran nada.
*Causa:* el nombre por defecto no es el del campo.
*Fix mínimo:* etiqueta explícita siempre.

**2. `bson.M` en la definición de un índice compuesto.**
*Síntoma:* el índice no sirve la consulta que debería.
*Causa:* un mapa de Go no tiene orden.
*Fix mínimo:* `bson.D` para índices y para claves ordenadas.

**3. Índice TTL sobre un campo que no es fecha.**
*Síntoma:* la colección crece sin parar; el índice existe.
*Causa:* Mongo ignora el TTL si el campo no es `Date`.
*Fix mínimo:* que el campo sea `time.Time`, y un test que espere de verdad.

**4. `ReplaceOne` que borra campos.**
*Síntoma:* desaparecen campos que otra versión del servicio escribía.
*Causa:* `Replace` sustituye el documento entero.
*Fix mínimo:* `$set` con operadores.

**5. Lectura-modificación-escritura.**
*Síntoma:* actualizaciones perdidas bajo concurrencia.
*Causa:* hay una ventana entre el `Find` y el `Replace`.
*Fix mínimo:* operadores atómicos, o filtro con revisión.

**6. `cursor.Err()` no comprobado.**
*Síntoma:* resultados parciales silenciosos.
*Causa:* el bucle también termina por error.
*Fix mínimo:* comprobarlo siempre, como `rows.Err()`.

**7. `cursor.Close` olvidado.**
*Síntoma:* cursores abiertos en el servidor consumiendo recursos.
*Causa:* no hay `defer`.
*Fix mínimo:* `defer cursor.Close(ctx)` tras comprobar el error.

**8. `$match` después de `$group`.**
*Síntoma:* la agregación es lenta y no usa índices.
*Causa:* filtrar al final procesa todo primero.
*Fix mínimo:* `$match` primero; comprobar con `explain`.

**9. `All` sobre un resultado sin cota.**
*Síntoma:* memoria que crece hasta OOM.
*Causa:* `All` materializa todo.
*Fix mínimo:* recorrer con `Next`/`Decode`, o el iterador.

**10. `time.Time` con nanosegundos y comparaciones que fallan.**
*Síntoma:* un test de ida y vuelta falla por microsegundos.
*Causa:* Mongo guarda milisegundos.
*Fix mínimo:* `Truncate(time.Millisecond)` y `UTC()` antes de guardar.

**11. `float64` para dinero o para tipos de cambio.**
*Síntoma:* descuadres de céntimos al multiplicar.
*Causa:* `double` de IEEE 754.
*Fix mínimo:* `Decimal128`, o enteros en unidad mínima como en la Fase 09.

**12. Transacciones contra una instancia suelta.**
*Síntoma:* error poco claro sobre sesiones o sobre el tipo de topología.
*Causa:* las transacciones necesitan un conjunto de réplicas.
*Fix mínimo:* `--replSet` en el contenedor, e iniciarlo. O, mejor: no
necesitarlas.

**13. Consultar contra `raw.`**
*Síntoma:* `COLLSCAN` en producción.
*Causa:* el campo crudo no tiene índices.
*Fix mínimo:* modelar el campo. Y ponerlo en la lista de revisión de código.

**14. Incrustar un array que crece.**
*Síntoma:* documentos que se acercan a 16 MB; escrituras cada vez más lentas.
*Causa:* cada actualización reescribe el documento entero.
*Fix mínimo:* referenciar, o el patrón de cubo con tamaño acotado.

### 🧨 Rompe a propósito

**El documento que crece hasta romperse.** Modela el histórico de tipos de cambio
como un array incrustado y mira qué pasa:

```go
func TestDocumentGrowth(t *testing.T) {
	coll := setupMongo(t)
	ctx := context.Background()

	// Un documento por par de monedas, con TODO el histórico dentro.
	_, _ = coll.InsertOne(ctx, bson.M{"_id": "EUR/COP", "points": bson.A{}})

	for i := 0; i < 200000; i++ {
		start := time.Now()
		_, err := coll.UpdateOne(ctx,
			bson.M{"_id": "EUR/COP"},
			bson.M{"$push": bson.M{"points": bson.M{
				"day":  time.Now().AddDate(0, 0, -i),
				"rate": 4300.0 + float64(i%100),
			}}})
		elapsed := time.Since(start)

		if i%20000 == 0 {
			var doc bson.Raw
			coll.FindOne(ctx, bson.M{"_id": "EUR/COP"}).Decode(&doc)
			t.Logf("puntos=%d tamaño=%d KB último push=%s",
				i, len(doc)/1024, elapsed.Round(time.Microsecond))
		}
		if err != nil {
			t.Fatalf("falló en el punto %d: %v", i, err)
		}
	}
}
```

```text
puntos=0      tamaño=0 KB      último push=412µs
puntos=20000  tamaño=1152 KB   último push=1.84ms
puntos=60000  tamaño=3456 KB   último push=5.21ms
puntos=140000 tamaño=8064 KB   último push=12.7ms
    falló en el punto 187431: ... object to insert too large ...
```

**Dos lecciones en un experimento.** La primera, obvia: el límite de 16 MB existe y
se alcanza. La segunda, la que importa: **el `$push` se vuelve más lento
proporcionalmente al tamaño del documento**, porque cada actualización reescribe el
documento completo. Mucho antes de romperse, ya era inaceptable.

Ahora hazlo con el patrón de cubo —un documento por mes— y repite la medición. El
tiempo de `$push` es constante.

---

## 🧪 8. Ejercicios (24)

**🟢 Fácil (1–6)**

1. Conecta a Mongo con el driver y comprueba que `mongo.Connect` no contacta con
   el servidor. *Criterio:* explicas dónde falla de verdad y por qué el `Ping` es
   obligatorio, con el paralelo a `sql.Open` de la Fase 09.
2. Define el struct `Country` con sus etiquetas BSON y guarda uno. *Criterio:*
   inspeccionas el documento en `mongosh` y coincide con lo que esperabas.
3. Quita las etiquetas a un struct y observa cómo se guardan los campos.
   *Criterio:* pegas el documento resultante y explicas la regla del nombre por
   defecto.
4. Crea los tres índices de `countries` con `bson.D` y verifícalos con
   `getIndexes()`. *Criterio:* para cada uno, la consulta que lo justifica.
5. Guarda un `time.Time` con nanosegundos, léelo, y comprueba que no es igual.
   *Criterio:* muestras la diferencia exacta y lo arreglas truncando.
6. Usa `explain("executionStats")` sobre una consulta con y sin índice.
   *Criterio:* comparas `totalDocsExamined` frente a `nReturned` en los dos casos.

**🟡 Intermedio (7–15)**

7. Implementa `UpsertAll` con `BulkWrite` no ordenado. *Criterio:* un corpus con
   tres documentos inválidos produce fallos parciales, el resto se escribe, y el
   resultado lo reporta.
8. Reproduce la pérdida de campos con `ReplaceOne` del 🧨. *Criterio:* lo
   demuestras y lo arreglas con `$set`, explicando el escenario de dos versiones
   desplegadas a la vez.
9. Implementa el bloqueo optimista con `revision` en el filtro. *Criterio:* dos
   goroutines concurrentes, una gana y la otra recibe `ErrConflict`; lo verificas
   con `-race`.
10. Crea el índice TTL de `fx_rates` y **comprueba que borra de verdad**.
    *Criterio:* esperas los 60 s del proceso de borrado; y después haces la versión
    con un campo numérico y demuestras que no borra nada.
11. Escribe `CountriesByRegion` con su paralelo SQL al lado. *Criterio:* las dos
    consultas producen el mismo resultado sobre los mismos datos.
12. Mueve el `$match` al final de una agregación y mide con `explain`.
    *Criterio:* anotas `totalDocsExamined` en las dos posiciones y explicas la
    diferencia.
13. Implementa la versión con `All` y la versión con `Next`/`Decode` de la misma
    consulta. *Criterio:* mides la memoria máxima de las dos con un resultado de
    100.000 documentos.
14. Implementa el índice de texto y una búsqueda por nombre. *Criterio:* la
    búsqueda de "republica" encuentra "República de Colombia", y explicas qué hace
    la configuración de idioma.
15. **Línea de comandos.** Activa el perfilador con `slowms: 10` y encuentra la
    consulta más lenta de tu servicio bajo carga. *Criterio:* la identificas y
    dices qué índice le falta.

**🟠 Difícil (16–21)**

16. **Modelado (1).** Meridian quiere guardar, por país, el histórico de
    poblaciones anuales desde 1960. Decide el modelo. *Criterio:* justificas
    incrustar o referenciar con las tres preguntas de §6.9, calculas el tamaño
    máximo del documento, y dices qué cambiaría si fuera mensual en vez de anual.
17. **Modelado (2).** Un socio pide que AtlasSync guarde también los feriados de
    cada país, con su fecha, nombre y si es nacional o regional. Modélalo.
    *Criterio:* justificas la decisión, defines los índices para "¿qué feriados hay
    en COL en diciembre?" y "¿qué países tienen feriado el 25 de diciembre?", y
    dices si las dos consultas caben en el mismo modelo.
18. **Modelado (3).** Te dan el esquema relacional del catálogo de la autopsia y
    te piden migrarlo a Mongo. *Criterio:* (a) decides qué se incrusta y qué no,
    con las tres preguntas; (b) calculas el coste del `$set` masivo al renombrar
    una categoría; (c) **dices honestamente si migrarías o no**, y por qué.
19. **Modelado (4).** ClearingHouse tiene `Movement`, `Batch` y `LedgerEntry`
    (Fase 09, PostgreSQL). Alguien propone moverlos a Mongo. *Criterio:*
    argumentas en contra con al menos cuatro razones concretas de este dominio, y
    después argumenta **a favor** lo mejor que puedas: si no encuentras ningún
    argumento, probablemente no entendiste bien la propuesta.
20. Implementa la ingesta con transacción multi-documento contra un conjunto de
    réplicas en contenedor: `docker compose --profile rs up -d mongo-rs`, y la
    cadena `mongodb://localhost:27018/?replicaSet=rs0&directConnection=true`.
    *Criterio:* (a) funciona; (b) demuestras que falla contra la instancia suelta
    del compose —el `mongo` del puerto 27017— y pegas el error literal, que es de
    los menos obvios de Mongo; (c) explicas por qué AtlasSync **no** la usa en su
    camino normal.
21. Reproduce el 🧨 del documento que crece y después implementa el patrón de
    cubo. *Criterio:* mides el tiempo de escritura en función del tamaño en las dos
    versiones y muestras que el cubo es constante.

**🔴 Muy difícil (22–24)**

22. **La migración de esquema sin migraciones.** AtlasSync necesita cambiar
    `currencies` de array de objetos a mapa indexado por código, con dos versiones
    del servicio desplegadas a la vez. *Rúbrica:* (a) diseñas la estrategia de
    lectura tolerante a las dos formas, usando `SchemaVersion`; (b) implementas la
    migración perezosa —al leer un documento viejo, se reescribe en la forma
    nueva— y la masiva, y comparas las dos; (c) demuestras con un test que las dos
    versiones del código conviven sin perder datos; (d) defines cómo saber cuándo
    se puede retirar el código de compatibilidad, con una consulta concreta; (e)
    comparas el esfuerzo con hacer lo mismo en PostgreSQL con `goose` y dices
    honestamente cuál prefieres.
23. **El validador de esquema en producción.** Activa la validación JSON Schema
    sobre `countries` en una colección que ya tiene datos. *Rúbrica:* (a)
    descubres cuántos documentos existentes la violarían, **sin romper nada**
    (pista: `validationLevel` y `validationAction`); (b) diseñas el camino de
    `warn` a `error` sin caída de servicio; (c) el esquema cubre los tipos, los
    campos obligatorios y el patrón del código ISO; (d) demuestras que rechaza una
    escritura mal formada hecha desde `mongosh`, no solo desde tu código; (e)
    escribes el argumento de por qué esto **debería** ser obligatorio y no lo es.
24. **El veredicto propio.** Escribe `docs/cuando-mongo.md`: la guía de decisión
    que Meridian usará cuando alguien proponga Mongo para un servicio nuevo.
    *Rúbrica:* (a) las preguntas de decisión, en orden, con la respuesta que
    descarta; (b) al menos cinco casos reales del dominio de Meridian resueltos
    —dos a favor, tres en contra—; (c) la sección "señales de que lo estás usando
    mal", con la autopsia de §7 y al menos tres señales más; (d) qué se pierde
    respecto a PostgreSQL, dicho sin suavizar; (e) la respuesta explícita a
    *"pero ya lo tenemos levantado"*; (f) es utilizable por alguien que no ha hecho
    este curso.

**🔥 Opcionales**

- Investiga las *time series collections* de MongoDB 5.0 y compáralas con tu
  patrón de cubo del ejercicio 21. Mide las dos.
- Lee la documentación de Change Streams y diseña —sin implementarlo— cómo
  AtlasSync notificaría a los otros servicios cuando cambia un tipo de cambio.
  Después compáralo con el outbox de la Fase 13 y di cuál elegirías.
- Explora `$graphLookup` con la jerarquía de regiones y subregiones. Es lo más
  parecido a una consulta recursiva (`WITH RECURSIVE`) que Mongo tiene.

---

### 🔴 Desafíos de cierre

> Tres ejercicios de dificultad alta que **no cuentan en el total de la sección** y
> no son parte del recorrido base.

**D1 — La comparación que falta: `JSONB` de PostgreSQL.**
El curso decidió Mongo para AtlasSync **sin evaluar `JSONB`**, y esa es una omisión
real. Ciérrala.
*Rúbrica:* (a) modelas `countries` en PostgreSQL con una columna `JSONB` y los
índices GIN correspondientes; (b) implementas las mismas cuatro consultas: por
clave, por moneda, por región ordenado, y la agregación por región; (c) mides las
dos con el mismo volumen y la misma carga; (d) comparas también lo que no se mide:
transacciones con el resto del sistema, una sola base que operar, y qué pierdes de
Mongo; (e) **escribes el veredicto honesto**, aunque contradiga la decisión del
curso — y si la contradice, esa es la respuesta más valiosa del ejercicio.

**D2 — La migración de esquema con doble escritura.**
Cambia `currencies` de array de objetos a mapa indexado, con el servicio en
producción y sin caída.
*Rúbrica:* (a) fase de doble escritura: el código escribe las dos formas y lee la
vieja; (b) migración de fondo de los documentos existentes, reanudable y acotada en
memoria; (c) cambio de lectura a la forma nueva; (d) retirada de la escritura vieja,
**con la consulta que demuestra que ya no queda ningún documento en la forma
antigua**; (e) en cada paso, las dos versiones del servicio conviven y lo
demuestras; (f) comparas el esfuerzo con hacerlo en PostgreSQL con `goose` y dices
cuál prefieres.

**D3 — El validador retroactivo.**
Escribe una herramienta que recorra la colección `countries` y encuentre los
documentos que **no encajan** en el struct de Go actual.
*Rúbrica:* (a) decodifica cada documento y detecta campos ausentes, tipos que no
coinciden y campos presentes que el struct no modela; (b) recorre la colección en
streaming, sin materializarla; (c) produce un informe agrupado por tipo de
divergencia, con ejemplos; (d) lo comparas con activar la validación JSON Schema en
modo `warn` y dices qué encuentra cada uno; (e) lo dejas como tarea programada y
explicas qué alerta definirías.

---

## 📚 9. Referencias

### Documentación oficial

- **MongoDB Go Driver** — https://www.mongodb.com/docs/drivers/go/current/ — la
  guía de uso, con ejemplos por operación.
- **`go.mongodb.org/mongo-driver/v2`** — https://pkg.go.dev/go.mongodb.org/mongo-driver/v2
- **BSON types** — https://www.mongodb.com/docs/manual/reference/bson-types/ — los
  tipos que JSON no tiene, y `Decimal128`.
- **Data Modeling** — https://www.mongodb.com/docs/manual/data-modeling/ — **la
  sección más importante de la documentación de Mongo**, y la que menos se lee.
- **Data Model Design (embedding vs. referencing)** —
  https://www.mongodb.com/docs/manual/core/data-model-design/
- **Aggregation Pipeline** — https://www.mongodb.com/docs/manual/core/aggregation-pipeline/
  y la referencia de operadores.
- **SQL to Aggregation Mapping Chart** —
  https://www.mongodb.com/docs/manual/reference/sql-aggregation-comparison/ — **la
  tabla que traduce `GROUP BY` a `$group`.** Tenla abierta al escribir tu primera
  agregación.
- **Indexes** — https://www.mongodb.com/docs/manual/indexes/ · **TTL Indexes** —
  https://www.mongodb.com/docs/manual/core/index-ttl/ (lee la parte del proceso de
  60 segundos)
- **Schema Validation** — https://www.mongodb.com/docs/manual/core/schema-validation/
- **Transactions** — https://www.mongodb.com/docs/manual/core/transactions/ — y su
  sección de limitaciones.
- **Building with Patterns** — https://www.mongodb.com/blog/post/building-with-patterns-a-summary
  — **la serie de doce patrones de modelado**, de donde salen el de atributo y el
  de cubo. Es el mejor material que MongoDB ha publicado.

### Libros

- **MongoDB: The Definitive Guide** — Bradshaw, Brazil y Chodorow. La referencia
  completa; los capítulos de modelado y de agregación son los que valen.
- **Designing Data-Intensive Applications** — Kleppmann, capítulo 2 (*Data Models
  and Query Languages*). **La mejor explicación que existe del intercambio entre
  documento y relación**, sin vender ninguno de los dos. Si solo lees una cosa de
  esta lista, que sea este capítulo.
- **Learning Go** — Bodner, para los iteradores de §6.7.

### Artículos y charlas

- **Building with Patterns** (serie de 12) — MongoDB Blog. Atributo, cubo,
  polimórfico, subconjunto, precálculo, árbol, valor atípico… Cada uno con su caso.
- **Mongo Schema Design** — busca las charlas de Daniel Coupal; son la mejor
  exposición del proceso de decisión.
- **The 6 Rules of Thumb for MongoDB Schema Design** — serie de tres partes en el
  blog de MongoDB. Antigua y sigue siendo correcta.
- **Why You Should Never Use MongoDB** — Sarah Mei. **De 2013, crítico, y hay que
  leerlo**: describe exactamente la autopsia de §7 con un caso real, y el
  argumento sobre cuándo los datos "son relacionales aunque no lo parezcan" sigue
  vigente. Léelo sabiendo que Mongo ha mejorado mucho desde entonces (transacciones,
  validación de esquema) y que **la crítica al modelado no ha caducado**.
- **MongoDB is Web Scale** — el vídeo satírico de 2010. Tres minutos, y es cultura
  general del gremio.
- **Use The Index, Luke** — https://use-the-index-luke.com — sobre índices en
  general; casi todo se transfiere.

### Video

- **MongoDB University** — https://learn.mongodb.com — los cursos de modelado de
  datos son gratuitos y buenos.
- **MongoDB World: Advanced Schema Design Patterns** — busca las charlas de
  Coupal y Alger.
- **GopherCon: MongoDB in Go** — hay pocas y no son imprescindibles; el driver está
  bien documentado.

> ⚠️ **Advertencia de versiones importante en esta fase.** El driver de Go cambió
> de forma notable entre la v1 y la v2 (2024): `mongo.Connect` ya no recibe
> contexto, `options` cambió, y los tipos BSON se movieron de paquete. **Casi todo
> el material que encuentres es de la v1.** Verifica el import antes de copiar un
> ejemplo. Y el material anterior a 2018 no conoce las transacciones, así que sus
> críticas en ese punto están fechadas.

### Orden de lectura sugerido

**Antes de escribir código:** el capítulo 2 de Kleppmann y *Data Model Design* de
la documentación. Hora y media, y son las que evitan la autopsia.
**Durante:** la *SQL to Aggregation Mapping Chart* abierta en una pestaña, y la
documentación de TTL cuando crees ese índice.
**Después:** la serie *Building with Patterns* completa, con calma. Son doce
artículos cortos y te dan vocabulario para discusiones de modelado durante años.

---

## ⚖️ 10. Veredicto y cierre

### ⚖️ Cuándo NO usar MongoDB

Los tres casos, en orden de frecuencia. **Y el primero es el que más proyectos
arruina, y no es técnico.**

**1. "Porque el equipo ya lo tenía levantado."**

Es la razón más común y la peor. Es entendible: hay un clúster funcionando, hay
alguien que sabe operarlo, y montar PostgreSQL parece trabajo extra. Pero elegir el
almacén por disponibilidad y no por la forma del dato es cómo se produce la
autopsia de §7: se acaba con un modelo relacional en un motor que no da integridad
referencial, ni atomicidad multi-entidad, ni optimizador de uniones.

**El coste de añadir PostgreSQL al `compose.yaml` es una tarde. El coste de un
modelo equivocado son años.**

Y el mismo razonamiento vale en dirección contraria: *"usamos PostgreSQL porque es
lo que hay"* cuando el dato es genuinamente documental y variable también es un
error, solo que menos frecuente y menos grave —porque `JSONB` de PostgreSQL cubre
buena parte de ese caso, que es algo que conviene saber antes de decidir.

**2. Cuando los datos son relacionales y las consultas también.**

Forma fija, entidades que se relacionan, consultas que las cruzan, invariantes que
abarcan varias entidades, y necesidad de transacciones. Eso es una base relacional.
`$lookup` existe y no es un `JOIN`: no hay optimizador que reordene, no hay
integridad referencial, y necesitarlo a menudo es la señal de que el modelo está
mal.

**3. Cuando necesitas garantías transaccionales fuertes de forma rutinaria.**

Mongo tiene transacciones ACID multi-documento desde la 4.0 y funcionan. Y son
caras, requieren un conjunto de réplicas, y sobre todo: **si las necesitas a
menudo, el modelo está mal**. La promesa del modelo documental es que el agregado
que cambia junto vive junto. El cierre contable de ClearingHouse —donde un lote,
sus asientos y el estado del periodo tienen que cambiar atómicamente— pertenece a
PostgreSQL, y por eso ahí está.

**Y tres cosas más, breves:**

- **Si tu equipo no tiene a nadie que sepa operarlo.** Un conjunto de réplicas con
  su *failover*, sus copias de seguridad y su monitorización es trabajo real.
  PostgreSQL tiene más gente que sabe.
- **Si necesitas búsqueda de texto seria.** El índice de texto de Mongo es básico y
  solo puede haber uno por colección. Atlas Search o Elasticsearch.
- **Si el dato es una serie temporal grande de verdad.** Hay bases diseñadas para
  eso —TimescaleDB, InfluxDB, ClickHouse— que ganan por mucho.

### 📖 Diccionario Java ⇄ Go de esta fase

| Java / Spring Data MongoDB | Go | Dónde se rompe la equivalencia |
|---|---|---|
| `MongoClient` | `*mongo.Client` | `mongo.Connect` **no contacta**: hace falta `Ping`, igual que `sql.Open` |
| `MongoTemplate` | `*mongo.Collection` directamente | Sin capa de plantilla: se usa el driver. Menos azúcar, cero indirección |
| `@Document(collection="x")` | el nombre al obtener la colección: `db.Collection("x")` | Explícito en el código, no en una anotación |
| `@Id` | etiqueta `bson:"_id"` | `_id` **siempre existe**; si no lo das, Mongo genera un `ObjectID` |
| `@Field("nombre")` | etiqueta `bson:"nombre"` | ⚠️ Sin etiqueta, el nombre por defecto es **todo en minúsculas y junto** |
| `@Indexed` / `@CompoundIndex` | `Indexes().CreateMany` en el arranque | Se escribe; a cambio, se ve qué índices existen sin leer anotaciones de doce clases |
| `@Transient` | campo no exportado, o `bson:"-"` | La visibilidad ya decide |
| `MongoRepository<T, ID>` | un struct con métodos | **Sin consultas derivadas de nombres de método** |
| `findByRegionAndPopulationGreaterThan` | un filtro `bson.M` escrito | Explícito. Más verboso y sin sorpresas de interpretación |
| `@Query("{...}")` | `bson.M` / `bson.D` | Lo mismo, con tipos de Go en vez de una cadena JSON |
| `Criteria.where("x").is(y)` | `bson.M{"x": y}` | Sin DSL: el filtro **es** el documento que va al servidor |
| `Sort.by(...)` | `options.Find().SetSort(bson.D{...})` | ⚠️ `bson.D` (ordenado), nunca `bson.M` |
| `Pageable` / `Page<T>` | `Skip`/`Limit`, o mejor paginación por cursor | `skip` se degrada igual que `OFFSET` (Fase 09) |
| `Aggregation.newAggregation(...)` | `mongo.Pipeline{...}` | Misma estructura; en Go se ve el BSON que se envía |
| `BulkOperations` | `BulkWrite` con `WriteModel` | Idéntico. `SetOrdered(false)` es el equivalente de `UNORDERED` |
| `@Version` (bloqueo optimista) | revisión en el filtro + `$inc` | Escrito a mano: 4 líneas, y se ve |
| `MongoTransactionManager` + `@Transactional` | `session.WithTransaction(...)` | Explícito, y con la misma advertencia: si las necesitas mucho, el modelo está mal |
| `MongoRepository.save()` | `UpdateOne` con `$set` + `upsert` | ⚠️ **No uses `ReplaceOne`**: borra los campos que tu struct no conoce |
| `MongoTemplate.upsert` | `SetUpsert(true)` | Igual |
| `@DBRef` | guardar el identificador y consultar aparte | **No hay resolución automática**, y eso es bueno: evita el N+1 invisible |
| `mongock` / migraciones | *(no hay estándar)* | Se escribe. El campo `schemaVersion` y la lectura tolerante son el patrón |
| `BigDecimal` | `bson.Decimal128` | Mismo propósito. `float64` para dinero está igual de mal en los dos |
| `Instant` / `LocalDateTime` | `time.Time` | ⚠️ Mongo guarda **milisegundos** y devuelve **UTC** siempre |
| Validación con Bean Validation | JSON Schema en la colección | La de Mongo actúa **en el servidor**: protege contra escrituras que no pasen por tu código |
| Testcontainers MongoDB | `testcontainers-go` con el módulo de Mongo | Prácticamente igual |

### Qué sigue

La Fase 12 es corta (6 h) y trata el problema difícil de verdad: **la caché con
invalidación pensada**. Valkey —el fork de Redis bajo la Linux Foundation— con
`valkey-go`, *cache-aside* y su condición de carrera, TTL con *jitter*, la
estampida resuelta con `singleflight` local **más** bloqueo distribuido —que no es
lo mismo—, invalidación por clave y por etiqueta, y el diseño de las claves, que es
el 80% de la calidad de una caché y casi nunca se discute.

Y los usos de Valkey que **no** son caché: limitación de tasa por socio, bloqueos
distribuidos con su advertencia grande sobre corrección, e idempotencia con
`SET NX`.

Con un experimento que cierra la fase y puede doler: **medir cuánto gana realmente
la caché aquí**. A veces la respuesta es *"poco, y acabas de añadir un servicio al
`compose.yaml`"*, y esa es una lección mejor que la contraria. La caché en memoria
con TTL que escribiste en la Fase 10 es la línea base contra la que se mide.

### La señal de que quedó bien

> *"Cuando alguien propone Mongo para un servicio nuevo, mi primera pregunta no es
> sobre el volumen ni sobre el rendimiento. Es: ¿siempre lees el agregado entero?
> Y si la respuesta es no, ya sé por dónde va la conversación."*

Si tu modelo tiene cinco colecciones que se referencian entre sí y consultas que
las cruzan, vuelve a la autopsia. La pregunta no es cómo optimizar ese `$lookup`:
es por qué esos datos no están en PostgreSQL.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en
> verde, `go test -race ./...` y `go test -tags=integration ./...` en verde,
> `golangci-lint run` limpio y `git status` sin cambios pendientes:
>
> ```bash
> git tag -a fase-11 -m "F11 cerrada: AtlasSync persiste en MongoDB con countries, fx_rates y sync_runs; índices declarados en código incluido el TTL y el de texto; ingesta con BulkWrite no ordenado; actualizaciones atómicas con operadores; agregaciones con su paralelo SQL; campo Raw acotado a inspección; tests de integración con testcontainers"
> git tag -a atlassync/v0.2 -m "AtlasSync: persistencia documental en MongoDB"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 11: …`) y los de ejercicio su
> número (`fase 11 ej22: …`). Todo eso está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).

---

# 📌 Bloque de autoría (fuera de lo que lee el estudiante)

## 📌 Pendientes sugeridos

- **`JSONB` de PostgreSQL** — resuelto por las dos vías. La **Fase 09 §6.8** cierra
  el debate del ORM declarando la omisión: dice que hay una cuarta forma que no
  entra, la nombra con sus operadores e índices, y remite aquí; y añade la regla
  general de comprobar si el motor que ya operas cubre el caso antes de añadir
  otro, porque el coste de un motor es la guardia, no la librería. Y el **desafío
  D1 de esta fase** pide modelarlo y compararlo, con la instrucción explícita de
  publicar el resultado aunque salga que PostgreSQL bastaba. Cadena cerrada.
- **Transacciones multi-documento y el `compose.yaml`** — resuelto en la Fase 00
  §6.8: el compose lleva ahora un segundo servicio, `mongo-rs`, con `--replSet` y
  su inicialización idempotente en el healthcheck, **tras un perfil de Docker
  Compose para que no arranque con `make up`**. La instancia suelta se queda como
  está a propósito, porque el criterio (b) del ejercicio 20 pide demostrar que la
  transacción falla contra ella. Cadena cerrada.
- **El driver v1 frente a v2** — la advertencia de referencias lo cubre, pero
  conviene fijar en `prompts/alcance-del-proyecto.md` §6.3 que la versión es la v2, porque
  hoy solo dice `go.mongodb.org/mongo-driver`.
- **La caché en memoria de la Fase 10** — es la línea base declarada para el ⚖️ de
  la Fase 12. Cadena verificada en las dos direcciones.
- **Change Streams** — ejercicio 🔥 que pide compararlo con el outbox de la Fase
  13. **Verificar que la Fase 13 lo recoge en su ⚖️ veredicto**, porque es una
  alternativa legítima que el curso descarta y debería decir por qué.
- **Time series collections** — ejercicio 🔥. No hay fase que las trate; correcto
  que quede así.
- **El patrón de cubo y el 🧨 del documento que crece** — la medición del tiempo de
  `$push` frente al tamaño del documento **es un benchmark real y no tiene ID**.
  Ver la sección de mediciones.

## ☕ Reflejos para `INSTINTOS.md`

- **"Esquemaless significa que no tengo que pensar el esquema"** — el reflejo raíz
  de la fase. Coste: seis meses después, `population` es entero en unos documentos
  y cadena en otros, y el código se llena de `switch` sobre tipos. Antídoto: **el
  esquema vive en el struct, lleva versión, y un cambio de forma es una migración
  aunque nadie la pida**.
- **"Ya tenemos Mongo levantado"** — elegir el almacén por disponibilidad y no por
  la forma del dato. Es la causa raíz de la autopsia y la razón número uno del ⚖️.
- **"Modelar en Mongo como modelaría en SQL"** — seis colecciones referenciadas y
  N+1 en el código. Pierdes las garantías de la relacional sin ganar las del
  documento.
- **"`$lookup` es un `JOIN`"** — no hay optimizador, no hay integridad referencial,
  y sin índice en la derecha es un escaneo por documento.
- **"`save()` guarda el objeto"** — `ReplaceOne` borra los campos que tu versión
  del struct no conoce, en silencio, y con dos versiones desplegadas es un bucle de
  pérdida de datos.
- **"El índice TTL borrará esto"** — si el campo no es una fecha, el índice se crea
  y no borra nada. Fallo silencioso.
- **"Guardo el crudo por si acaso"** — `Raw` es para inspección y migración; un
  filtro sobre `raw.` es la señal de que había que modelar el campo.

## 📐 Mediciones para `BENCHMARKS.md`

Esta fase **no tiene entradas asignadas** en `prompts/formato-de-benchmarks.md` §5, y
produce dos candidatas con valor didáctico alto:

- **Sin ID — Tiempo de `$push` frente al tamaño del documento.** Sale del 🧨 de §7
  y del ejercicio 21. Demuestra que la escritura se degrada linealmente con el
  tamaño porque el documento se reescribe entero, y que el patrón de cubo la
  mantiene constante. **Es la medición que convierte "no incrustes arrays que
  crecen" de consejo en hecho.** Asignada al cerrar el curso: **B-26**.
- **Sin ID — `All` frente a cursor con `Decode`, memoria máxima.** Es B-06 (Fase
  03) aplicado a Mongo, con 100.000 documentos. Barato de medir y refuerza una
  lección que el curso ya sostiene. Propuesta: **sección de B-19 (Fase 13)**, que ya
  mide streaming frente a carga completa sobre un reporte grande — serían el mismo
  argumento en dos motores.

Y una anotación para la Fase 16: **el duelo compara ClearingHouse (PostgreSQL) en
Go y en Spring Boot, y no toca Mongo.** Está bien así, pero conviene que el ⚖️ de
la Fase 16 diga explícitamente que la comparación de *stacks* no incluye el
almacén documental, para que nadie extrapole.
