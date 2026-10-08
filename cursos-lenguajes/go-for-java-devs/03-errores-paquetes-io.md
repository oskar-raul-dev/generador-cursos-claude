# 🧯 Fase 03 — Errores, paquetes, I/O y JSON

> Go para desarrolladores Java senior · Fase 3 de 17 · **7 horas**
> Época: **Go 1.13 (stdlib pura)**
> Depende de: Fase 02 · Habilita: Fase 04
> Proyectos que avanzan: **OpsReport** y **EventRelay** (errores, configuración, serialización)
> Mini proyectos: `error-chain`, `config-loader`, `json-codec`

---

## 🎯 1. Propósito

Hasta ahora hemos estado despachando los errores con `return err` y siguiendo
adelante. Se acabó.

Esta fase existe para que dejes de vivir el `if err != nil` como un castigo y
empieces a verlo como **información en la firma**. Es el punto donde más gente
abandona Go en la primera semana —"hay más manejo de errores que código"— y
también el punto donde más gente se convierte, normalmente después del primer
incidente de producción en el que el flujo de error estaba escrito delante de sus
ojos en vez de escondido en un `throws` que nadie leía.

Y llega en Go 1.13 con una novedad que no es menor: **el envoltorio con `%w`**,
`errors.Is` y `errors.As`. Es literalmente *la* aportación de esta versión, y por
eso el Bloque A del curso está aquí y no en 1.12.

Al terminar, los dos servicios tienen política de errores, configuración y
serialización JSON.

---

## ✅ 2. Qué queda listo al terminar

- [ ] `opsreport.Service` distingue con `errors.Is` entre "no existe", "estado
      inválido" y "fallo del almacén", **sin comparar strings**.
- [ ] `workitem.ValidationError` es un tipo de error que acumula varios fallos y
      se recupera con `errors.As`.
- [ ] `internal/config` lee configuración de entorno y archivo, con precedencia
      definida y validación al arrancar.
- [ ] `WorkItem` y `Delivery` se serializan y deserializan a JSON con las
      etiquetas y la representación correctas, y sus `time.Time` viajan en RFC
      3339 UTC.
- [ ] `labs/error-chain` demuestra una cadena de cuatro niveles y recupera el tipo
      del fondo con `errors.As`.
- [ ] `labs/json-codec` compara decodificación completa frente a streaming, y sus
      números están en **B-06**.
- [ ] Sabes explicar por qué `defer resp.Body.Close()` dentro de un bucle es un
      bug, y cómo se arregla.
- [ ] `go1.13 vet ./...` en verde, `golangci-lint run` sin avisos de `errcheck`.

---

## 🚫 3. Qué NO entra todavía

- `errors.Join` para agregar varios errores → Fase 08 🕰️ (Go 1.20). Hasta
  entonces, un tipo de error propio que lleva un slice dentro, que además es más
  explícito.
- `%w` con varios errores en un solo `fmt.Errorf` → Fase 08 🕰️ (Go 1.20). En 1.13
  solo se envuelve **uno**.
- `errors.As` con tipos genéricos → no existe; los genéricos son de la Fase 08 🕰️.
- Logging estructurado → Fase 14. Aquí el log es `log` de la stdlib con formato
  libre, y **está declarado como provisional**. 💸
- `embed` para las plantillas y archivos de configuración → Fase 08 🕰️ (Go 1.16).
  Aquí los archivos se leen con `ioutil.ReadFile`.
- Tests → Fase 04, otra vez. Es la última fase sin ellos.
- Errores en el borde HTTP (traducción a códigos de estado) → Fase 05, y allí se
  apoya directamente en la política que montamos hoy.

---

## 🧠 4. Concepto mínimo

### `error` es una interfaz de un método, y eso lo cambia todo

```go
type error interface {
	Error() string
}
```

Eso es todo. No hay jerarquía, no hay clase base, no hay `Throwable`. Un error es
**un valor** que se devuelve, se guarda en una variable, se compara, se mete en un
slice y se pasa por parámetro. Como un `int`.

De ahí sale la consecuencia que define el estilo del lenguaje: **el flujo de error
es flujo normal del programa**. No hay un canal paralelo por el que las cosas malas
viajan hacia arriba saltándose los `return`. Si una función puede fallar, lo dice
en su firma, y el que la llama tiene el error en la mano en la línea siguiente.

```go
item, err := store.FindByID(id)
if err != nil {
	return workitem.WorkItem{}, err
}
```

Sí, eso se repite. Mucho. Y aquí está el argumento honesto de las dos partes,
porque los dos modelos tienen razón en algo:

**Dónde gana Java.** Las excepciones comprobadas **te obligan a decidir**: o la
capturas o la declaras, y el compilador no te deja seguir. En Go puedes escribir
`_ = doSomething()` y el error desaparece sin dejar rastro, sin aviso del
compilador y sin que nadie se entere hasta que algo no cuadra en producción. Es un
agujero real y no tiene defensa; la única mitigación es el linter `errcheck`, que
por eso está activado desde la Fase 00. Y en la práctica, el manejo de errores de
Go es **verboso**: una función con cinco llamadas tiene quince líneas de
fontanería.

**Dónde gana Go.** El `throws IOException` de una firma no te dice de dónde sale;
el bloque `try` de cuarenta líneas con un `catch` al final no te dice qué línea
falló ni qué estado quedó a medias. En Go, cada punto de fallo está marcado en el
sitio exacto donde ocurre, y **decides qué hacer con él allí mismo**, con el
contexto delante. Además, las excepciones no comprobadas de Java —que son la
mayoría en la práctica— no obligan a nada: `RuntimeException` viaja igual de
invisible que un error ignorado en Go, solo que además desenrolla la pila.

> 🧭 **Regla del proyecto.** Un error se maneja donde ocurre o se propaga con
> contexto añadido. `_ = f()` solo se escribe con un comentario al lado que diga
> por qué se ignora, y `errcheck` lo va a exigir.

### Los tres sabores de error, y cuándo usar cada uno

**1. Error inmediato, sin identidad.** Cuando el llamador no va a preguntar nada
sobre él, solo reportarlo:

```go
return fmt.Errorf("el monto %q no es un número válido", raw)
```

**2. Error centinela.** Un valor de paquete comparable, para cuando el llamador
**sí** necesita distinguir ese caso concreto:

```go
var ErrNotFound = errors.New("no encontrado")

// y en el llamador:
if errors.Is(err, opsreport.ErrNotFound) {
	// devolver 404
}
```

**3. Tipo de error.** Cuando el error lleva **datos** que el llamador necesita:

```go
type ValidationError struct {
	Field  string
	Reason string
}

func (e *ValidationError) Error() string {
	return fmt.Sprintf("campo %s: %s", e.Field, e.Reason)
}

// y en el llamador:
var verr *ValidationError
if errors.As(err, &verr) {
	fmt.Println("el campo problemático es", verr.Field)
}
```

La regla de decisión: **si el llamador solo necesita saber *qué* pasó, centinela.
Si necesita saber *sobre qué*, tipo de error.**

### `%w`: la novedad de Go 1.13, y el porqué de esta fase

Antes de 1.13, añadir contexto a un error destruía su identidad:

```go
// Go 1.12 y anteriores. El llamador ya no puede preguntar por ErrNotFound.
return fmt.Errorf("buscando el work item %s: %v", id, err)
```

Con `%w` el error original queda **envuelto** y sigue siendo accesible:

```go
return fmt.Errorf("buscando el work item %s: %w", id, err)
```

Y arriba, a cualquier distancia de la pila:

```go
if errors.Is(err, memstore.ErrNotFound) {
	// funciona aunque haya cuatro capas de envoltorio en medio
}
```

**`errors.Is` recorre la cadena** llamando a `Unwrap()` hasta encontrar una
coincidencia. `errors.As` hace lo mismo pero buscando por tipo, y asigna.

> 🧠 **Modelo mental.** `%w` construye una lista enlazada de errores donde cada
> eslabón añade contexto y conserva el anterior. `errors.Is` es *"¿hay un `X` en
> esta cadena?"*. `errors.As` es *"¿hay algo de tipo `T` en esta cadena? Dámelo."*
> El paralelo de Java es `getCause()` encadenado, y `errors.Is` es el bucle de
> `while (cause != null)` que todos hemos escrito alguna vez — pero incluido en la
> stdlib y usado por convención.

### Cuándo envolver y cuándo no

```go
// ✅ Envolver: el llamador puede querer preguntar
if err := s.store.Save(item); err != nil {
	return fmt.Errorf("guardando %s: %w", item.ID, err)
}

// ✅ No envolver: el detalle solo va al log, y exponer el error interno filtraría
//    el motor de base de datos a los llamadores.
if err := s.store.Save(item); err != nil {
	log.Printf("error del almacén al guardar %s: %v", item.ID, err)
	return ErrStorageUnavailable
}
```

> ⚠️ **Envolver es parte de la API pública.** En el momento en que envuelves con
> `%w`, los llamadores pueden depender de lo que hay dentro, y cambiarlo se
> convierte en un cambio incompatible. Envolver todo por reflejo filtra tus
> detalles de implementación hacia arriba. La decisión se comenta en el código
> cuando no sea obvia.

Y el formato del mensaje, que es convención y no gusto:

```go
// ✅ minúscula inicial, sin punto final, sin "error:" al principio
fmt.Errorf("no se pudo abrir el archivo de configuración: %w", err)

// ❌
fmt.Errorf("Error: No se pudo abrir el archivo de configuración.")
```

La razón es mecánica: los errores se concatenan. `"guardando WI-1: buscando en el
almacén: clave no encontrada"` se lee; con mayúsculas y puntos, no.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El instinto:** *"envuelvo todo el bloque en un `try` y manejo los fallos al
final"*. En Java es correcto y además es lo legible: el camino feliz va seguido,
sin interrupciones, y el manejo de errores se agrupa abajo.

**Qué pasa si lo aplicas aquí.** Buscas el equivalente y encuentras
`panic`/`recover`, que **se parecen** a `throw`/`catch`, y escribes esto:

```go
// ☕ — esto compila, funciona y es una mala idea
func (s *Service) Create(item workitem.WorkItem) (result workitem.WorkItem, err error) {
	defer func() {
		if r := recover(); r != nil {
			err = fmt.Errorf("fallo al crear: %v", r)
		}
	}()

	item.ID = s.ids.NewID()
	mustValidate(item)          // hace panic si no valida
	mustSave(s.store, item)     // hace panic si el almacén falla
	return item, nil
}
```

Es tentador: el camino feliz queda limpio, tres líneas, sin fontanería. Y está mal
por cuatro razones concretas:

1. **`recover` solo funciona en un `defer` de la propia función.** Si `mustSave`
   entra en panic desde una goroutine que ella lanzó, tu `recover` no la ve y el
   proceso entero muere. Con concurrencia (Fase 06) esto pasa de sutil a fatal.
2. **Pierdes la identidad del error.** Lo que sale es un `error` construido a
   partir de un `interface{}`; `errors.Is` no sirve, `errors.As` tampoco.
3. **El panic desenrolla la pila y se salta tus `defer` de limpieza a medias**, o
   más bien los ejecuta en un orden que no pensaste.
4. **Nadie más en el ecosistema escribe así**, y tu código se vuelve ilegible para
   cualquier gopher que lo herede. Eso no es un argumento estético: es coste de
   mantenimiento.

**Qué pensar en su lugar.** `panic` tiene un lugar, y es estrecho:

- **Invariantes rotos en el arranque**: `regexp.MustCompile` con un patrón
  inválido, una plantilla que no parsea, una configuración obligatoria ausente. Si
  el programa no puede funcionar, que muera fuerte y temprano.
- **Errores del programador**: índice fuera de rango, mapa nulo. Esos ya entran en
  panic solos.
- **`recover` solo en el borde**: en un handler HTTP o en un worker, para que un
  bug en una petición no tumbe el proceso entero. Y ahí **se registra y se
  explica**, nunca se traga.

Para todo lo demás, el error se devuelve. Sí, son tres líneas más. Ese es el
intercambio.

### 🩻 Esto sí funciona igual

- **Añadir contexto al propagar** es la misma práctica que envolver una excepción
  con `new ServiceException("procesando el lote " + id, e)`. El reflejo es
  correcto; solo cambia la sintaxis.
- **`getCause()` encadenado** es `errors.Unwrap` en bucle. Mismo modelo mental.
- **No filtrar detalles de implementación en el error** es la misma regla de
  diseño de API que ya aplicas al decidir si una `SQLException` sale de tu capa de
  repositorio.
- **`finally` y `defer` cumplen el mismo papel**: liberar lo que se adquirió, pase
  lo que pase. Las diferencias son de alcance y de orden, no de intención.
- **`try-with-resources` y `defer Close()`** resuelven el mismo problema con la
  misma filosofía: el cierre va junto a la apertura, no cincuenta líneas después.
- **Los paquetes y la visibilidad** funcionan igual en espíritu: hay cosas
  públicas y cosas internas, y la buena práctica es exponer poco.
- **El streaming de JSON grande** es la misma decisión que tomas con Jackson entre
  `ObjectMapper.readValue` y `JsonParser`. Mismos motivos, mismos números.

---

## 🛠️ 5. CLI de la fase

```bash
# El linter que hace de "excepción comprobada" en Go. Es la razón por la que
# errcheck está en el .golangci.yml desde la Fase 00.
golangci-lint run --enable-only errcheck ./...

# check-blank en la configuración hace que también proteste por `_ = f()`.
# Compruébalo: comenta un error con _ y mira qué dice.
golangci-lint run ./...

# vet detecta errores de formato: %w con un argumento que no es error, verbos
# que no casan con el tipo, Errorf sin argumentos. Es gratis y atrapa mucho.
go1.13 vet ./...

# La documentación de los tres paquetes de la fase.
go1.13 doc errors
go1.13 doc errors.Is
go1.13 doc fmt.Errorf
go1.13 doc encoding/json Marshal
go1.13 doc io.Reader

# Lista los archivos de un paquete, incluidos los de test. Útil para entender un
# paquete ajeno antes de tocarlo.
go1.13 list -f '{{.GoFiles}} {{.TestGoFiles}}' ./internal/config

# El grafo de dependencias hacia una dirección concreta: quién importa qué.
# Es cómo se detecta un ciclo antes de que el compilador lo detecte por ti.
go1.13 list -deps ./internal/opsreport | grep meridian

# Benchmarks de la fase (B-06): decodificación completa frente a streaming.
go1.13 test -run '^$' -bench . -benchmem -count=10 ./labs/json-codec

# Y el que vas a usar cuando el JSON no salga como esperabas: imprimir la
# estructura con %#v, que muestra tipos y valores exactos.
#   fmt.Printf("%#v\n", decoded)
```

> 💡 **`-benchmem` y el JSON.** La decodificación de JSON en Go asigna memoria en
> proporción al documento, y la diferencia entre `Unmarshal` y `Decoder` se ve
> mucho más clara en `B/op` que en `ns/op`. Cuando midas B-06, mira primero esa
> columna.

---

## 💻 6. Construcción guiada

### 6.1 Mini proyecto: `error-chain`

Cuatro niveles de envoltorio y la recuperación del tipo del fondo. Es el
laboratorio más corto de la fase y el que más se usa después.

```go
// labs/error-chain/chain.go
package chain

import (
	"errors"
	"fmt"
)

// Nivel 4 — el fondo: un error del "driver", con datos dentro.
type DriverError struct {
	Code    int
	Query   string
}

func (e *DriverError) Error() string {
	return fmt.Sprintf("driver devolvió %d ejecutando %q", e.Code, e.Query)
}

// Nivel 3 — el almacén tiene su centinela y envuelve el del driver.
var ErrRowNotFound = errors.New("fila no encontrada")

func storeFind(id string) error {
	driverErr := &DriverError{Code: 1032, Query: "SELECT * FROM work_items WHERE id = $1"}
	// Se envuelven los DOS: el centinela como error principal y el del driver
	// como causa. En 1.13 solo se puede envolver UNO por Errorf, así que el
	// orden importa: aquí elegimos conservar el del driver, y el centinela va
	// como parte del mensaje... lo cual es exactamente el problema que
	// errors.Join resuelve en Go 1.20. 🕰️
	return fmt.Errorf("%s: %w", ErrRowNotFound, driverErr)
}

// Nivel 2 — el servicio añade el identificador.
func serviceGet(id string) error {
	if err := storeFind(id); err != nil {
		return fmt.Errorf("obteniendo work item %s: %w", id, err)
	}
	return nil
}

// Nivel 1 — el handler añade la petición.
func handleRequest(requestID, itemID string) error {
	if err := serviceGet(itemID); err != nil {
		return fmt.Errorf("petición %s: %w", requestID, err)
	}
	return nil
}

// Inspect demuestra las tres operaciones de la cadena.
func Inspect() {
	err := handleRequest("req-8821", "WI-0007")

	// 1. El mensaje completo: cada nivel añadió su contexto, separado por ": ".
	fmt.Println(err)
	// petición req-8821: obteniendo work item WI-0007: fila no encontrada: driver devolvió 1032 ejecutando "SELECT * FROM work_items WHERE id = $1"

	// 2. errors.As recupera el tipo del FONDO, a cuatro niveles de distancia.
	var driverErr *DriverError
	if errors.As(err, &driverErr) {
		fmt.Println("código del driver:", driverErr.Code)  // 1032
	}

	// 3. errors.Unwrap pela un nivel. Casi nunca se usa directamente; está aquí
	//    para que veas la mecánica.
	fmt.Println(errors.Unwrap(err))
	// obteniendo work item WI-0007: fila no encontrada: driver devolvió 1032 ...
}
```

Y el descubrimiento incómodo, que es la mitad del valor del laboratorio:

```go
// ¿Funciona errors.Is con el centinela?
fmt.Println(errors.Is(err, ErrRowNotFound))  // false ❌
```

**No funciona**, porque en `storeFind` envolvimos el `DriverError` con `%w` y el
centinela quedó como texto plano en el mensaje. En Go 1.13 **solo se puede
envolver un error por `fmt.Errorf`**, y hay que elegir cuál.

La solución de la época es un tipo que envuelva los dos:

```go
// storeError conserva el centinela Y la causa. Es lo que en Go 1.20 hace
// errors.Join en una línea. 🕰️
type storeError struct {
	sentinel error
	cause    error
}

func (e *storeError) Error() string {
	return fmt.Sprintf("%v: %v", e.sentinel, e.cause)
}

// Is permite que errors.Is encuentre el centinela.
func (e *storeError) Is(target error) bool { return target == e.sentinel }

// Unwrap permite que errors.As encuentre la causa.
func (e *storeError) Unwrap() error { return e.cause }
```

```go
errors.Is(err, ErrRowNotFound)  // true ✅
errors.As(err, &driverErr)      // true ✅
```

> 💡 **El método `Is(error) bool` es un punto de extensión oficial.** `errors.Is`
> lo llama si existe, antes de comparar por igualdad. Lo mismo con
> `As(interface{}) bool`. Es cómo un tipo de error decide con qué se considera
> equivalente, y casi nadie lo conoce.

### 6.2 Errores del dominio: OpsReport

Ahora aplicamos lo aprendido al servicio de verdad. Recuerda la deuda de la Fase
02: `memstore` tenía su `ErrNotFound` y `opsreport` el suyo, y no había forma de
relacionarlos. Hoy se paga.

```go
// services/opsreport/internal/workitem/errors.go
package workitem

import (
	"errors"
	"fmt"
	"strings"
)

// Los centinelas del dominio. Son valores comparables y forman parte de la API
// pública del paquete: cambiarlos rompe a los llamadores que preguntan por ellos.
var (
	ErrInvalidTransition = errors.New("transición de estado no permitida")
	ErrInvalidPriority   = errors.New("prioridad fuera de rango")
	ErrUnknownKind       = errors.New("tipo de trabajo desconocido")
)

// FieldError es un fallo de validación sobre un campo concreto.
type FieldError struct {
	Field  string
	Reason string
}

func (e FieldError) Error() string { return e.Field + ": " + e.Reason }

// ValidationError acumula todos los fallos de validación de un work item.
//
// Existe porque devolver solo el primer error obliga al usuario de la API a
// corregir de uno en uno: envía, falla, corrige, reenvía, falla otra vez. Con
// esto, una sola respuesta lleva los cuatro problemas.
//
// En Go 1.20 esto se escribiría con errors.Join, que hace exactamente lo mismo
// con menos código. 🕰️ Fase 08.
type ValidationError struct {
	Fields []FieldError
}

func (e *ValidationError) Error() string {
	parts := make([]string, 0, len(e.Fields))
	for _, f := range e.Fields {
		parts = append(parts, f.Error())
	}
	return "validación fallida: " + strings.Join(parts, "; ")
}

// add registra un fallo. No exportado: solo el propio paquete construye estos.
func (e *ValidationError) add(field, reason string) {
	e.Fields = append(e.Fields, FieldError{Field: field, Reason: reason})
}

// HasErrors dice si hay algo que reportar.
func (e *ValidationError) HasErrors() bool { return len(e.Fields) > 0 }

// TransitionError lleva los dos estados dentro, para que el llamador pueda
// construir un mensaje útil sin parsear texto.
type TransitionError struct {
	From Status
	To   Status
}

func (e *TransitionError) Error() string {
	return fmt.Sprintf("no se puede pasar de %s a %s", e.From, e.To)
}

// Is hace que errors.Is(err, ErrInvalidTransition) funcione sobre este tipo.
// Es el punto de extensión que permite tener identidad Y datos a la vez.
func (e *TransitionError) Is(target error) bool { return target == ErrInvalidTransition }
```

Y `Validate` pasa a devolver todos los fallos:

```go
// services/opsreport/internal/workitem/workitem.go (fragmento)

// Validate comprueba el work item completo y devuelve TODOS los problemas
// encontrados, no solo el primero.
//
// Devuelve un error de interfaz, no *ValidationError, por una razón concreta:
// devolver un puntero tipado y comparar el resultado con nil es la trampa de la
// interfaz nula, y está explicada en la autopsia de esta fase.
func (w WorkItem) Validate() error {
	var verr ValidationError

	if strings.TrimSpace(w.ExternalReference) == "" {
		verr.add("external_reference", "es obligatoria")
	}
	if !w.Kind.IsKnown() {
		verr.add("kind", "no es un tipo de trabajo conocido")
	}
	if w.Priority < MinPriority || w.Priority > MaxPriority {
		verr.add("priority", fmt.Sprintf("debe estar entre %d y %d", MinPriority, MaxPriority))
	}
	if len([]rune(w.Description)) > maxDescriptionRunes {
		verr.add("description", fmt.Sprintf("supera los %d caracteres", maxDescriptionRunes))
	}

	if verr.HasErrors() {
		return &verr
	}
	return nil // ← nil de interfaz, no un puntero nulo dentro de una interfaz
}
```

Y las transiciones devuelven el tipo con datos:

```go
func (w *WorkItem) MarkRunning(now time.Time) error {
	if !w.CanTransitionTo(StatusRunning) {
		return &TransitionError{From: w.Status, To: StatusRunning}
	}
	w.Status = StatusRunning
	w.StartedAt = now
	return nil
}
```

El servicio ahora puede distinguir de verdad:

```go
// services/opsreport/internal/opsreport/service.go (fragmento)

var (
	ErrNotFound = errors.New("el work item no existe")
	ErrConflict = errors.New("el work item está en un estado que no lo permite")
	ErrStorage  = errors.New("el almacén no está disponible")
)

func (s *Service) Start(id string) (workitem.WorkItem, error) {
	item, err := s.store.FindByID(id)
	if err != nil {
		if errors.Is(err, memstore.ErrNotFound) {
			// Se traduce el error del almacén al vocabulario del servicio, pero
			// se conserva la causa: quien depure tendrá la cadena completa.
			return workitem.WorkItem{}, fmt.Errorf("%w: %s", ErrNotFound, id)
		}
		return workitem.WorkItem{}, fmt.Errorf("%w: %v", ErrStorage, err)
	}

	if err := item.MarkRunning(s.clock.Now()); err != nil {
		// El error de transición lleva los estados dentro y satisface
		// ErrInvalidTransition a la vez. Se envuelve y sube intacto.
		return workitem.WorkItem{}, fmt.Errorf("%w: %v", ErrConflict, err)
	}

	if err := s.store.Update(item); err != nil {
		return workitem.WorkItem{}, fmt.Errorf("%w: %v", ErrStorage, err)
	}
	return item, nil
}
```

> 🧭 **Regla del proyecto: la traducción de errores ocurre en los límites.** El
> almacén tiene su vocabulario (`ErrNotFound` de `memstore`), el servicio el suyo
> (`opsreport.ErrNotFound`), y el borde HTTP el suyo (códigos de estado, Fase 05).
> Cada capa traduce **una vez**, en su frontera, y conserva la causa. Lo que no se
> hace nunca es dejar que un error de `database/sql` llegue hasta el handler.

> 🧪 **Prueba de fuego.** Desde `main`, crea un `WorkItem` inválido en tres campos
> a la vez y mira el error:
> ```text
> validación fallida: external_reference: es obligatoria; kind: no es un tipo de trabajo conocido; priority: debe estar entre 1 y 9
> ```
> Y después recupéralo con `errors.As` y recorre `verr.Fields`. **La mentira de la
> pantalla:** el mensaje concatenado se lee bien y es tentador dárselo tal cual al
> cliente de la API. No lo hagas: en la Fase 05, ese slice de `FieldError` se
> convierte en un array JSON con `field` y `reason`, que es lo que un frontend
> puede usar para marcar los campos en rojo. **Un error legible por humanos y un
> error procesable por máquinas son cosas distintas, y esta estructura te permite
> tener las dos.**

### 6.3 `defer` en serio

Ya lo usaste. Ahora la semántica exacta, que tiene tres partes y todas muerden.

**1. Los argumentos se evalúan cuando se declara el `defer`, no cuando se
ejecuta:**

```go
func demo() {
	start := time.Now()
	defer fmt.Println("tardó", time.Since(start))  // ❌ imprime ~0s
	time.Sleep(2 * time.Second)
}
```

`time.Since(start)` se evaluó en la línea del `defer`, cuando no había pasado
nada. La forma correcta es diferir una closure:

```go
defer func() { fmt.Println("tardó", time.Since(start)) }()  // ✅
```

**2. El orden es LIFO**, como una pila:

```go
for i := 1; i <= 3; i++ {
	defer fmt.Println(i)
}
// imprime 3, 2, 1
```

**3. Un `defer` con receptor nombrado puede modificar el valor de retorno:**

```go
// Este idioma se usa para añadir contexto a TODOS los caminos de error de una
// función de una sola vez. Úsalo con moderación: oculta el flujo.
func loadConfig(path string) (cfg Config, err error) {
	defer func() {
		if err != nil {
			err = fmt.Errorf("cargando configuración de %s: %w", path, err)
		}
	}()
	// ... cinco returns con error, todos quedan envueltos ...
}
```

🧨 **Rompe a propósito: el `defer` dentro del bucle.**

```go
// labs/error-chain/leak.go
package chain

import (
	"fmt"
	"os"
)

// ProcessAllBroken agota los descriptores de archivo del proceso. El defer NO se
// ejecuta al final de cada iteración: se ejecuta al salir de la FUNCIÓN, así que
// los diez mil archivos quedan abiertos a la vez.
func ProcessAllBroken(paths []string) error {
	for _, path := range paths {
		f, err := os.Open(path)
		if err != nil {
			return err
		}
		defer f.Close() // ❌ se acumulan; ninguno se cierra hasta el final

		// ... procesar f ...
	}
	return nil
}

// ProcessAllFixed extrae el cuerpo del bucle a una función, que es donde el
// defer tiene el alcance correcto.
func ProcessAllFixed(paths []string) error {
	for _, path := range paths {
		if err := processOne(path); err != nil {
			return fmt.Errorf("procesando %s: %w", path, err)
		}
	}
	return nil
}

func processOne(path string) error {
	f, err := os.Open(path)
	if err != nil {
		return err
	}
	defer f.Close() // ✅ se ejecuta al salir de processOne, una vez por archivo

	// ... procesar f ...
	return nil
}
```

Genera diez mil archivos temporales y corre las dos versiones. La primera falla
con `too many open files` en cuanto pasa del límite del sistema (`ulimit -n`, que
en macOS suele ser 256 por defecto). **En Java, `try-with-resources` dentro del
bucle cierra en cada iteración**, porque su alcance es el bloque. El de `defer` es
la función, y esa diferencia de una palabra es el bug.

> ⚠️ **Y el error que `defer f.Close()` se traga.** `Close()` devuelve un error, y
> al diferirlo lo estás descartando. Para un archivo de lectura da igual; **para
> uno de escritura no**, porque el `Close` es donde se vacía el buffer y donde te
> enteras de que el disco estaba lleno. La forma correcta:
> ```go
> defer func() {
>     if cerr := f.Close(); cerr != nil && err == nil {
>         err = fmt.Errorf("cerrando %s: %w", path, cerr)
>     }
> }()
> ```

### 6.4 Paquetes, visibilidad e `internal/`

Tres reglas y una consecuencia.

**1. La visibilidad la decide la mayúscula inicial.** `WorkItem` es exportado;
`workItem` no. No hay `public`, `private`, `protected` ni `package-private`: hay
dos niveles, y el segundo es el paquete entero.

📖 El equivalente más cercano en Java es `package-private`, y la diferencia es que
en Go **no hay nada más restrictivo**: dentro de un paquete, todo el mundo lo ve
todo. No existe el `private` de clase, porque no hay clases.

**2. `internal/` es una regla del compilador.** Un paquete bajo `internal/` solo
puede ser importado por código que comparta su directorio padre:

```text
services/opsreport/internal/workitem/   ← solo importable desde services/opsreport/...
```

Si otro módulo intenta importarlo, **no compila**. Es más fuerte que
`package-private` porque no depende de que nadie ponga una clase en tu paquete, y
más fuerte que los módulos de Java 9 porque no hay forma de abrirlo con una
bandera.

**3. Los ciclos de importación están prohibidos**, y el compilador los rechaza:

```text
import cycle not allowed
package github.com/meridian/opsreport/internal/opsreport
	imports github.com/meridian/opsreport/internal/memstore
	imports github.com/meridian/opsreport/internal/opsreport
```

En Java los ciclos entre paquetes son legales y se acumulan hasta que nadie
entiende el grafo. Aquí **no puedes crear uno**, y esa restricción te obliga a
tomar decisiones de diseño que de otro modo aplazarías indefinidamente.

> 🧠 **Modelo mental.** La prohibición de ciclos es la razón por la que el patrón
> "interfaz en el consumidor" de la Fase 02 no es solo estética: es lo que
> **hace posible** que `opsreport` use a `memstore` sin que `memstore` conozca a
> `opsreport`. Con la interfaz en el productor, tendrías un ciclo el día que el
> almacén necesitara un tipo del servicio.

Y la convención de nombres, que ya vimos y ahora tiene su porqué: `report`, no
`reports`; `worker`, no `workerutils`. Y nunca `utils`, `common`, `helpers`,
`models`, `dto` ni `impl`. **Si no sabes cómo llamar al paquete, el paquete
todavía no existe.**

### 6.5 `io.Reader` e `io.Writer`

Las dos interfaces más importantes del ecosistema, y las dos tienen un método:

```go
type Reader interface { Read(p []byte) (n int, err error) }
type Writer interface { Write(p []byte) (n int, err error) }
```

Lo que las hace importantes no es lo que hacen, es **cuántas cosas las
satisfacen**: archivos, conexiones de red, buffers en memoria, cuerpos de petición
HTTP, salida estándar, compresores, cifradores. Y como todas hablan el mismo
idioma, se componen:

```go
// Escribir a un archivo y a la salida estándar a la vez, sin código propio.
f, _ := os.Create("report.csv")
out := io.MultiWriter(f, os.Stdout)
fmt.Fprintln(out, "store_id,total")

// Leer solo los primeros 1024 bytes de lo que sea.
limited := io.LimitReader(someReader, 1024)

// Copiar de cualquier lector a cualquier escritor, con buffer interno.
n, err := io.Copy(dst, src)
```

`io.Copy` merece una nota: copia sin cargar el origen entero en memoria, con un
buffer de 32 KB, y si el origen o el destino implementan `WriterTo`/`ReaderFrom`
usa la ruta rápida. **Es la respuesta correcta al 90% de "necesito mover datos de
aquí a allá".**

📖 El paralelo en Java es `InputStream`/`OutputStream`, y el reflejo de componerlos
—`new BufferedReader(new InputStreamReader(...))`— se traslada tal cual 🩻. La
diferencia es que en Go la interfaz tiene **un** método en vez de nueve, y por eso
implementar la tuya cuesta cuatro líneas:

```go
// countingWriter cuenta los bytes que pasan por él. Cuatro líneas, y ya se puede
// usar en cualquier sitio que acepte un io.Writer.
type countingWriter struct {
	w io.Writer
	n int64
}

func (c *countingWriter) Write(p []byte) (int, error) {
	n, err := c.w.Write(p)
	c.n += int64(n)
	return n, err
}
```

Y `bufio`, que es la diferencia entre un programa lento y uno rápido cuando hay
muchas operaciones pequeñas:

```go
// Sin buffer: una llamada al sistema por línea. Con 500.000 líneas, 500.000
// syscalls.
for _, row := range rows {
	fmt.Fprintln(file, row)
}

// Con buffer: una llamada al sistema cada 4 KB.
w := bufio.NewWriter(file)
defer w.Flush()  // ⚠️ sin este Flush pierdes lo último que escribiste
for _, row := range rows {
	fmt.Fprintln(w, row)
}
```

> ⚠️ **El `Flush` olvidado es el bug de E/S más común de Go.** El programa termina
> sin error, el archivo existe, y le faltan los últimos kilobytes. Y como
> `w.Flush()` devuelve error, diferirlo sin comprobarlo lo oculta — mismo problema
> que `Close()`.

### 6.6 Mini proyecto: `config-loader`

Configuración desde entorno y archivo, con precedencia, validación y fallo rápido.
Es el germen de `internal/config` de los dos servicios.

```go
// labs/config-loader/config.go
package config

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"strconv"
	"strings"
	"time"
)

// Config es la configuración del servicio. Los valores por defecto viven en
// Default(), no repartidos por el código.
type Config struct {
	HTTPAddr        string        `json:"http_addr"`
	WorkerCount     int           `json:"worker_count"`
	ShutdownTimeout time.Duration `json:"shutdown_timeout"`
	LogLevel        string        `json:"log_level"`
	DatabaseURL     string        `json:"database_url"`
}

// Default devuelve la configuración de partida. Todo lo que tiene un valor
// razonable lo tiene aquí; lo que no lo tiene (DatabaseURL) queda vacío y la
// validación lo exige.
func Default() Config {
	return Config{
		HTTPAddr:        ":8080",
		WorkerCount:     4,
		ShutdownTimeout: 15 * time.Second,
		LogLevel:        "info",
	}
}

// Load construye la configuración aplicando la precedencia del curso:
//
//	valores por defecto  <  archivo JSON  <  variables de entorno
//
// Las variables de entorno ganan porque son lo que un orquestador inyecta, y
// porque poder sobrescribir un valor sin reconstruir la imagen es el punto
// entero de la configuración doce-factores.
func Load(path string) (Config, error) {
	cfg := Default()

	if path != "" {
		if err := applyFile(&cfg, path); err != nil {
			return Config{}, fmt.Errorf("configuración de archivo: %w", err)
		}
	}
	if err := applyEnv(&cfg); err != nil {
		return Config{}, fmt.Errorf("configuración de entorno: %w", err)
	}
	if err := cfg.Validate(); err != nil {
		return Config{}, err
	}
	return cfg, nil
}

func applyFile(cfg *Config, path string) error {
	// ioutil.ReadFile es lo que hay en 1.13; os.ReadFile llega en 1.16 🕰️.
	data, err := ioutil.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			// Un archivo de configuración ausente NO es un error: los valores
			// por defecto más el entorno pueden bastar. Que falte el archivo y
			// que el archivo esté corrupto son cosas distintas.
			return nil
		}
		return fmt.Errorf("leyendo %s: %w", path, err)
	}

	// Decodificar sobre cfg, que ya tiene los valores por defecto: los campos
	// ausentes en el JSON conservan su valor previo. Esa es la mecánica de la
	// precedencia y es gratis.
	if err := json.Unmarshal(data, cfg); err != nil {
		return fmt.Errorf("json inválido en %s: %w", path, err)
	}
	return nil
}

func applyEnv(cfg *Config) error {
	if v := os.Getenv("MERIDIAN_HTTP_ADDR"); v != "" {
		cfg.HTTPAddr = v
	}
	if v := os.Getenv("MERIDIAN_WORKER_COUNT"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil {
			return fmt.Errorf("MERIDIAN_WORKER_COUNT=%q no es un número: %w", v, err)
		}
		cfg.WorkerCount = n
	}
	if v := os.Getenv("MERIDIAN_SHUTDOWN_TIMEOUT"); v != "" {
		d, err := time.ParseDuration(v)
		if err != nil {
			return fmt.Errorf("MERIDIAN_SHUTDOWN_TIMEOUT=%q no es una duración: %w", v, err)
		}
		cfg.ShutdownTimeout = d
	}
	if v := os.Getenv("MERIDIAN_LOG_LEVEL"); v != "" {
		cfg.LogLevel = strings.ToLower(v)
	}
	if v := os.Getenv("MERIDIAN_DATABASE_URL"); v != "" {
		cfg.DatabaseURL = v
	}
	return nil
}

// ConfigError agrupa todos los problemas de configuración. Mismo patrón que
// ValidationError del dominio, y por la misma razón: arrancar, fallar, corregir
// un campo, arrancar otra vez, es una forma pésima de pasar la tarde.
type ConfigError struct{ Problems []string }

func (e *ConfigError) Error() string {
	return "configuración inválida:\n  - " + strings.Join(e.Problems, "\n  - ")
}

// Validate comprueba la configuración completa y devuelve TODOS los problemas.
func (c Config) Validate() error {
	var cerr ConfigError

	if c.HTTPAddr == "" {
		cerr.Problems = append(cerr.Problems, "http_addr no puede estar vacío")
	}
	if c.WorkerCount < 1 || c.WorkerCount > 256 {
		cerr.Problems = append(cerr.Problems,
			fmt.Sprintf("worker_count debe estar entre 1 y 256, llegó %d", c.WorkerCount))
	}
	if c.ShutdownTimeout < time.Second {
		cerr.Problems = append(cerr.Problems, "shutdown_timeout debe ser de al menos 1s")
	}
	switch c.LogLevel {
	case "debug", "info", "warn", "error":
	default:
		cerr.Problems = append(cerr.Problems,
			fmt.Sprintf("log_level %q no es válido (debug|info|warn|error)", c.LogLevel))
	}

	if len(cerr.Problems) > 0 {
		return &cerr
	}
	return nil
}

// String redacta los secretos. Una configuración se registra al arrancar —es
// buena práctica— y una URL de base de datos lleva la contraseña dentro.
func (c Config) String() string {
	return fmt.Sprintf("addr=%s workers=%d shutdown=%s log=%s db=%s",
		c.HTTPAddr, c.WorkerCount, c.ShutdownTimeout, c.LogLevel, redact(c.DatabaseURL))
}

func redact(dsn string) string {
	if dsn == "" {
		return "(vacía)"
	}
	if i := strings.Index(dsn, "@"); i > 0 {
		return "***@" + dsn[i+1:]
	}
	return "***"
}
```

> 🧭 **Regla del proyecto: fallo rápido.** La configuración se lee y se valida
> **entera, al arrancar**, antes de abrir un puerto o una conexión. Un servicio que
> arranca con `WorkerCount=0` y falla en la primera petición es peor que uno que no
> arranca: el orquestador lo marca como sano y le manda tráfico.

📖 En Spring esto lo resuelven `@ConfigurationProperties` con `@Validated` y las
anotaciones de Bean Validation, y lo resuelven bien: menos código y los mismos
mensajes. Lo que ganas escribiéndolo a mano es que **el orden de precedencia está
en una función de veinte líneas que puedes leer**, en vez de en la tabla de
prioridades de `PropertySource` que hay que consultar en la documentación. En la
Fase 14 volvemos sobre esto con la comparación completa.

### 6.7 Mini proyecto: `json-codec`

`encoding/json` con todas sus trampas, y la medición que cierra la fase.

```go
// labs/json-codec/codec.go
package codec

import (
	"encoding/json"
	"time"
)

// WorkItemJSON es la representación externa de un work item.
//
// Es un tipo APARTE del dominio, y esta vez sí se justifica —a diferencia del DTO
// de la autopsia de la Fase 02—: los nombres son snake_case porque es lo que
// espera el cliente, hay campos calculados que el dominio no tiene, y los
// tiempos nulos no se envían. Si el dominio cambia de forma interna, la API no
// tiene por qué cambiar con él.
type WorkItemJSON struct {
	ID                string     `json:"id"`
	ExternalReference string     `json:"external_reference"`
	Kind              string     `json:"kind"`
	Description       string     `json:"description,omitempty"`
	Priority          int        `json:"priority"`
	EffectivePriority int        `json:"effective_priority"` // calculado, no está en el dominio
	Status            string     `json:"status"`
	CreatedAt         time.Time  `json:"created_at"`
	StartedAt         *time.Time `json:"started_at,omitempty"`  // puntero: distingue "no empezó" de "época cero"
	FinishedAt        *time.Time `json:"finished_at,omitempty"`
	FailureReason     string     `json:"failure_reason,omitempty"`

	// internalNotes no se exporta, así que json lo ignora por completo. No hace
	// falta `json:"-"`: la mayúscula ya decide.
	internalNotes string
}
```

Las cinco trampas, con su demostración:

**1. `omitempty` no hace lo que crees.** Omite el valor **cero**, no el "vacío
semántico":

```go
type Filter struct {
	Status   string `json:"status,omitempty"`
	MinPrio  int    `json:"min_priority,omitempty"`
	Active   bool   `json:"active,omitempty"`
}

f := Filter{Status: "queued", MinPrio: 0, Active: false}
b, _ := json.Marshal(f)
fmt.Println(string(b))  // {"status":"queued"}
```

`MinPrio: 0` y `Active: false` desaparecieron, y son valores **legítimos**. Si tu
API necesita distinguir "no lo mandaron" de "mandaron false", el campo tiene que
ser un puntero (`*bool`) y `omitempty` entonces sí significa lo que esperabas.

**2. Los campos no exportados no se serializan ni se deserializan.** No hay
excepción, no hay anotación que lo cambie, y es la causa del "el JSON sale vacío"
más común del principiante:

```go
type broken struct {
	id   string  // minúscula → json lo ignora
	Name string
}
json.Marshal(broken{id: "x", Name: "y"})  // {"Name":"y"}
```

**3. Un `interface{}` decodifica los números como `float64`.** Siempre:

```go
var data map[string]interface{}
json.Unmarshal([]byte(`{"count": 42}`), &data)

n := data["count"].(int)      // panic: interface {} is float64, not int
n := int(data["count"].(float64))  // ✅
```

Por eso este curso decodifica a structs tipados salvo cuando de verdad no se
conoce la forma, y para eso existe `json.RawMessage`.

**4. `json.RawMessage` difiere la decodificación.** Es un `[]byte` que el
decodificador deja tal cual:

```go
// El payload de un evento de EventRelay lo publica el productor y su forma
// depende del tipo de evento. Guardarlo crudo y decodificarlo cuando se sepa
// el tipo es más honesto que un map[string]interface{}.
type EventJSON struct {
	ID      string          `json:"id"`
	Type    string          `json:"type"`
	Payload json.RawMessage `json:"payload"`
}

var ev EventJSON
json.Unmarshal(data, &ev)

switch ev.Type {
case "order.created":
	var order OrderCreated
	if err := json.Unmarshal(ev.Payload, &order); err != nil { ... }
}
```

**5. `time.Time` se serializa en RFC 3339** y eso es lo que quieres — pero
**guarda la zona horaria del valor**:

```go
t := time.Date(2026, 9, 11, 8, 0, 0, 0, time.FixedZone("COT", -5*3600))
b, _ := json.Marshal(t)
fmt.Println(string(b))  // "2026-09-11T08:00:00-05:00"
```

Si en la base de datos guardas UTC y en el JSON sale `-05:00`, dos clientes van a
comparar strings y a discrepar. La regla del curso: **`time.Time` se normaliza a
UTC en el borde**, y el formateo en zona local es cosa de la presentación.

Y ahora la medición:

```go
// labs/json-codec/decode_bench_test.go
package codec

import (
	"bytes"
	"encoding/json"
	"testing"
)

// Un documento grande: el reporte operativo mensual de OpsReport, con 50.000
// work items. Es exactamente el caso de la Fase 13.
func buildLargeDocument(n int) []byte { /* ... genera el JSON ... */ }

var docSink int

// BenchmarkUnmarshalAll carga el documento entero en memoria y lo decodifica de
// una vez. Es lo que hace json.Unmarshal y lo que hace ObjectMapper.readValue.
func BenchmarkUnmarshalAll(b *testing.B) {
	data := buildLargeDocument(50000)
	b.SetBytes(int64(len(data)))
	b.ResetTimer()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		var items []WorkItemJSON
		if err := json.Unmarshal(data, &items); err != nil {
			b.Fatal(err)
		}
		docSink += len(items)
	}
}

// BenchmarkDecodeStream lee el array elemento a elemento con json.Decoder.
// La memoria máxima es la de UN elemento, no la del documento.
func BenchmarkDecodeStream(b *testing.B) {
	data := buildLargeDocument(50000)
	b.SetBytes(int64(len(data)))
	b.ResetTimer()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		dec := json.NewDecoder(bytes.NewReader(data))

		// Consumir el '[' de apertura.
		if _, err := dec.Token(); err != nil {
			b.Fatal(err)
		}
		count := 0
		for dec.More() {
			var item WorkItemJSON
			if err := dec.Decode(&item); err != nil {
				b.Fatal(err)
			}
			count++
		}
		docSink += count
	}
}
```

> 📐 **Cómo se mide.** Entrada **B-06**: *decodificación completa frente a
> streaming*. Comando:
> `go1.13 test -run '^$' -bench . -benchmem -count=10 ./labs/json-codec`.
>
> La hipótesis está escrita en `BENCHMARKS.md` y es falsable: *"el decodificador
> en streaming mantiene la memoria máxima por debajo del 5% de la del documento,
> con un coste en tiempo inferior al 20%"*. **Mira `B/op`:** ahí está la historia.
> El tiempo puede ser parecido; la memoria no lo es, y en la Fase 13, cuando
> ClearingHouse procese millones de movimientos, esa diferencia es la que separa un
> proceso que termina de uno que muere por OOM.

Y el lado de la escritura, que tiene la misma forma:

```go
// EncodeStream escribe un array JSON sin construirlo entero en memoria.
// Es lo que el endpoint de descarga de reportes de la Fase 05 va a necesitar.
func EncodeStream(w io.Writer, items []WorkItemJSON) error {
	buf := bufio.NewWriter(w)
	defer buf.Flush()

	if _, err := buf.WriteString("["); err != nil {
		return err
	}
	enc := json.NewEncoder(buf)
	for i, item := range items {
		if i > 0 {
			if _, err := buf.WriteString(","); err != nil {
				return err
			}
		}
		if err := enc.Encode(item); err != nil {
			return fmt.Errorf("codificando el ítem %d: %w", i, err)
		}
	}
	_, err := buf.WriteString("]")
	return err
}
```

> ⚠️ **`json.Encoder.Encode` añade un salto de línea al final de cada valor.** Es
> deliberado: está pensado para JSON delimitado por líneas (NDJSON), que es el
> formato natural para streams. Si construyes un array a mano como arriba, el JSON
> resultante tiene saltos de línea dentro y es válido igualmente — pero conviene
> saberlo antes de comparar salidas byte a byte en un test.

### 6.8 EventRelay: serialización y configuración

Lo mismo aplicado al segundo servicio, con una diferencia que importa: el
`Payload` de un evento es opaco.

```go
// services/eventrelay/internal/relay/json.go
package relay

import (
	"encoding/json"
	"fmt"
	"time"
)

// EventJSON es lo que un productor publica en POST /events.
type EventJSON struct {
	Type           string          `json:"type"`
	Payload        json.RawMessage `json:"payload"`
	IdempotencyKey string          `json:"idempotency_key,omitempty"`
}

// Validate comprueba la petición entrante. El payload se valida como JSON
// sintácticamente correcto y con un tamaño máximo, pero NO se interpreta: su
// forma es asunto del socio que lo recibe, no nuestro.
func (e EventJSON) Validate() error {
	var verr ValidationError

	if e.Type == "" {
		verr.add("type", "es obligatorio")
	}
	if len(e.Payload) == 0 {
		verr.add("payload", "es obligatorio")
	} else if len(e.Payload) > maxPayloadBytes {
		verr.add("payload", fmt.Sprintf("supera los %d bytes", maxPayloadBytes))
	} else if !json.Valid(e.Payload) {
		verr.add("payload", "no es json válido")
	}

	if verr.HasErrors() {
		return &verr
	}
	return nil
}

const maxPayloadBytes = 256 * 1024

// DeliveryJSON es la vista externa de una entrega. Fíjate en que NO expone
// Secret ni el cuerpo de la respuesta del socio: un endpoint puede consultar sus
// propias entregas y no tiene por qué ver lo que respondieron otros.
type DeliveryJSON struct {
	ID          string     `json:"id"`
	EventID     string     `json:"event_id"`
	EndpointID  string     `json:"endpoint_id"`
	Status      string     `json:"status"`
	Attempts    int        `json:"attempts"`
	MaxAttempts int        `json:"max_attempts"`
	NextAttempt *time.Time `json:"next_attempt,omitempty"`
	LastError   string     `json:"last_error,omitempty"`
	CreatedAt   time.Time  `json:"created_at"`
	DeliveredAt *time.Time `json:"delivered_at,omitempty"`
}
```

> 💸 **Deuda técnica intencional.** El logging de los dos servicios sigue siendo
> `log.Printf` con formato libre: sin niveles, sin campos estructurados, sin
> correlación de petición. **Se paga en la Fase 14** con `log/slog`, y allí se
> comparan las dos salidas lado a lado. Que quede escrito: `log.Printf("error al
> guardar %s: %v", id, err)` es imposible de consultar en un agregador de logs, y
> ese es exactamente el problema.

---

## ⚰️ 7. Autopsia y errores comunes

### ⚰️ Autopsia: la interfaz nula que no es nula

**El cadáver.** Este es el bug más elegante de Go y el que más veces he visto
llegar a producción. Alguien escribe esto, y es razonable:

```go
// ☕ — compila, se lee bien, y está mal
func (w WorkItem) Validate() *ValidationError {
	var verr ValidationError
	// ... acumula problemas ...
	if verr.HasErrors() {
		return &verr
	}
	return nil
}

// Y en el llamador:
func (s *Service) Create(item workitem.WorkItem) error {
	if err := validateItem(item); err != nil {   // ← siempre entra aquí
		return err
	}
	return s.store.Save(item)
}

func validateItem(item workitem.WorkItem) error {  // ← devuelve error, la interfaz
	return item.Validate()                          // ← pero Validate devuelve *ValidationError
}
```

**Todos los work items son rechazados, incluso los válidos.**

**El informe forense.** Una interfaz en Go son **dos palabras**: el tipo dinámico y
el valor. `err != nil` es falso solo si **las dos** son nil.

```text
Validate() devuelve:            (*ValidationError)(nil)
Al asignarlo a un `error`:      tipo = *ValidationError,  valor = nil
Comparación err != nil:         tipo ≠ nil  →  TRUE
```

El puntero es nulo. La interfaz que lo contiene, no. Y como el tipo dinámico está
presente, `err != nil` da verdadero.

Demostración, para que lo veas con tus ojos:

```go
var p *ValidationError = nil
var err error = p

fmt.Println(p == nil)    // true
fmt.Println(err == nil)  // false   ← el mismo nil, dos respuestas
fmt.Printf("%T %v\n", err, err)  // *codec.ValidationError <nil>
```

**El coste, en números de este curso:**

| | |
|---|---|
| Líneas que hay que cambiar para arreglarlo | **1** (el tipo de retorno) |
| Tiempo medio hasta encontrarlo sin conocer el patrón | horas |
| Tests unitarios que lo detectan | **todos los del camino feliz**, si existen |
| Herramientas que lo avisan | `staticcheck` lo detecta en algunos casos; el compilador, nunca |

**La causa de la muerte:** se devolvió un **tipo concreto** donde el contrato es
una **interfaz**. El reflejo viene de Java, donde `return null` de un método que
devuelve `ValidationException` y luego se asigna a `Exception` no tiene ninguna
sorpresa, porque `null` es `null` y no hay dos palabras.

**El fix, y la regla que se lleva:**

> 🧭 **Regla del proyecto.** Una función que puede fallar devuelve **`error`**, la
> interfaz, nunca un tipo de error concreto. Y devuelve `nil` literal en el camino
> feliz, nunca una variable de tipo puntero.
>
> ```go
> func (w WorkItem) Validate() error {   // ← error, no *ValidationError
>     var verr ValidationError
>     // ...
>     if verr.HasErrors() {
>         return &verr
>     }
>     return nil   // ← nil literal: interfaz completamente nula
> }
> ```

Y la corrección mínima frente a la refactorización correcta, que es la distinción
del curso: **el parche del viernes** es cambiar el tipo de retorno de esa función y
recompilar. **La refactorización del lunes** es buscar en todo el repositorio
funciones que devuelvan `*AlgoError` o `*MiTipo` como resultado de error, porque
si hay una, hay más:

```bash
grep -rn "func.*) \*[A-Z].*Error {" --include="*.go" .
```

### Errores comunes

**1. `%w` sobre algo que no es un error.**
*Síntoma:* `go vet` dice `Errorf format %w has arg x of wrong type`.
*Causa:* `%w` solo acepta un `error`.
*Fix mínimo:* usa `%v`. Y agradece a `vet`, porque en tiempo de ejecución esto
produce un mensaje con `%!w(...)` que nadie entiende.

**2. Comparar errores con `==`.**
*Síntoma:* la comparación falla cuando alguien añadió un envoltorio en medio.
*Causa:* `err == ErrNotFound` no atraviesa la cadena de `%w`.
*Fix mínimo:* `errors.Is(err, ErrNotFound)`. El linter `errorlint` lo detecta y
está activado desde la Fase 00.

**3. `errors.As` con un valor en vez de un puntero al puntero.**
*Síntoma:* `panic: errors: target must be a non-nil pointer`.
*Causa:* `errors.As(err, verr)` en vez de `errors.As(err, &verr)`.
*Fix mínimo:* el `&`. `As` necesita escribir en tu variable.

**4. El error del `defer Close()` que desaparece.**
*Síntoma:* un archivo escrito queda truncado y nadie se entera.
*Causa:* `defer f.Close()` descarta el error, que es donde se reporta el fallo del
vaciado del buffer.
*Fix mínimo:* el `defer` con closure que asigna al error nombrado (§6.3). Para
archivos de **lectura**, `defer f.Close()` a secas está bien y es lo idiomático.

**5. `json.Unmarshal` que no falla con campos desconocidos.**
*Síntoma:* el cliente manda `prioriti` en vez de `priority`, la petición tiene
éxito y el campo se queda en cero.
*Causa:* `encoding/json` ignora campos desconocidos por defecto.
*Fix mínimo:* `dec := json.NewDecoder(r); dec.DisallowUnknownFields()`. Lo
aplicaremos en el borde HTTP en la Fase 05, y es una decisión con matices: rechaza
clientes que mandan campos de más, lo cual rompe la compatibilidad hacia adelante.

**6. El ciclo de importación descubierto tarde.**
*Síntoma:* `import cycle not allowed` después de una refactorización grande.
*Causa:* dos paquetes se necesitan mutuamente, casi siempre porque una interfaz
está declarada en el sitio equivocado.
*Fix mínimo:* mover la interfaz al consumidor (Fase 02), o extraer los tipos
compartidos a un tercer paquete que no dependa de ninguno de los dos.

### 🧨 Rompe a propósito

Ya rompiste el `defer` en el bucle. Rompe ahora el `Flush`:

```go
func WriteReportBroken(path string, rows []string) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()

	w := bufio.NewWriter(f)
	for _, row := range rows {
		if _, err := w.WriteString(row + "\n"); err != nil {
			return err
		}
	}
	return nil  // ❌ falta w.Flush(): los últimos bytes se quedan en el buffer
}
```

Escribe 100.000 líneas, corre, y cuenta las del archivo con `wc -l`. Vas a
encontrar que faltan las últimas. **No hay error, no hay panic, no hay aviso.** El
programa devolvió `nil` y el archivo está incompleto.

Esa es la categoría de bug que el manejo de errores explícito de Go **no** te
salva, y conviene decirlo: Go te obliga a mirar el error, no a acordarte de vaciar
el buffer. Lo que sí ayuda es el linter, y `errcheck` marca el `w.Flush()` sin
comprobar en cuanto lo añades.

---

## 🧪 8. Ejercicios (24)

**🟢 Fácil (1–6)**

1. Escribe tres errores del dominio de EventRelay: uno inmediato con
   `fmt.Errorf`, un centinela y un tipo con datos. *Criterio:* para cada uno
   justificas en una línea por qué elegiste esa forma.
2. Envuelve un error en cuatro niveles y recupera el del fondo con `errors.As`.
   *Criterio:* el mensaje completo se lee de fuera hacia adentro y los cuatro
   contextos están presentes.
3. Provoca el error de `vet` con `%w` sobre un string. *Criterio:* pegas el
   mensaje de `vet` y el resultado que habrías obtenido en tiempo de ejecución sin
   él.
4. Demuestra la evaluación temprana de argumentos de `defer` con el ejemplo del
   cronómetro. *Criterio:* muestras la versión rota y la corregida con closure, con
   sus dos salidas.
5. Serializa un `WorkItem` con `StartedAt` vacío, primero como `time.Time` y
   después como `*time.Time` con `omitempty`. *Criterio:* explicas la diferencia
   entre `"0001-01-01T00:00:00Z"` y la ausencia del campo, y cuál quiere un
   cliente.
6. Usa `go1.13 doc errors` y localiza `Is`, `As` y `Unwrap`. *Criterio:* explicas
   en tres líneas qué hace cada una y con qué la confundirías.

**🟡 Intermedio (7–15)**

7. Implementa `ValidationError` con su método `Is` para que
   `errors.Is(err, ErrValidation)` funcione. *Criterio:* funciona a través de dos
   niveles de envoltorio.
8. Convierte `Validate` de `WorkItem` para que devuelva **todos** los fallos.
   *Criterio:* un work item con tres campos malos produce un error con tres
   entradas, y el llamador puede recorrerlas con `errors.As`.
9. Traduce en `opsreport.Service` los errores de `memstore` a los del servicio,
   conservando la causa. *Criterio:* `errors.Is(err, opsreport.ErrNotFound)` es
   verdadero **y** `errors.As` todavía encuentra el error original del almacén.
10. Reproduce el agotamiento de descriptores con `defer` en un bucle. *Criterio:*
    llegas al `too many open files` real de tu sistema, dices cuál es tu
    `ulimit -n`, y lo arreglas extrayendo la función.
11. Escribe `config-loader` con la precedencia completa y compruébala: un valor
    por defecto sobrescrito por archivo y después por entorno. *Criterio:* un solo
    programa demuestra los tres niveles con la misma clave.
12. Añade a `Config.Validate` la acumulación de problemas y provoca un arranque
    con cuatro fallos a la vez. *Criterio:* la salida los lista todos en formato
    legible, y el proceso sale con código distinto de cero.
13. Implementa `redact` para una URL de PostgreSQL con usuario y contraseña.
    *Criterio:* no filtra la contraseña ni siquiera parcialmente, y sigue mostrando
    host y base de datos, que es lo que sirve para depurar.
14. Usa `json.RawMessage` en `EventJSON` y decodifica el payload según el tipo del
    evento. *Criterio:* tres tipos de evento distintos, cada uno con su struct, y
    un tipo desconocido que produce un error claro en vez de un panic.
15. Escribe un `countingWriter` y úsalo para saber cuántos bytes ocupa un reporte
    sin guardarlo. *Criterio:* funciona envolviendo `ioutil.Discard` y el resultado
    coincide con el tamaño real del archivo si lo escribieras.

**🟠 Difícil (16–21)**

16. **Mide B-06.** Genera un documento de 50.000 work items y compara
    `json.Unmarshal` con `json.Decoder` en streaming. *Criterio:* anotas `ns/op`,
    `B/op` y `allocs/op` de las dos en `BENCHMARKS.md`, y tu veredicto menciona
    explícitamente en qué caso **no** compensa el streaming.
17. **Detección de ☕ (1).** Te dan una jerarquía de errores con siete tipos
    (`NotFoundError`, `ValidationError`, `ConflictError`, `StorageError`,
    `TimeoutError`, `PermissionError`, `InternalError`), cada uno con su struct y
    su constructor. Redúcela. *Criterio:* justificas cuáles se convierten en
    centinelas, cuáles sobreviven como tipos y por qué; cuentas líneas antes y
    después.
18. **Detección de ☕ (2).** Un servicio que usa `panic`/`recover` como
    `try`/`catch` (el ejemplo de §4). Reescríbelo. *Criterio:* muestras un caso
    donde la versión con `recover` **falla de verdad** —una goroutine, o un
    `defer` de limpieza que no se ejecuta— y no solo donde es fea.
19. Implementa el `defer` con error nombrado que envuelve todos los caminos de
    error de una función con cinco `return`. *Criterio:* funciona, y después
    escribes en dos líneas por qué este idioma se usa con moderación.
20. Escribe un lector que **limite el tamaño** del cuerpo JSON aceptado y
    devuelva un error distinguible al superarlo. *Criterio:* usa `io.LimitReader`
    o `http.MaxBytesReader`, el error es reconocible con `errors.Is`, y explicas
    por qué esto es una defensa y no una validación.
21. **Línea de comandos.** Con `go1.13 list -deps` y `grep`, verifica que ningún
    paquete de `internal/` importa a otro formando ciclo, y produce el grafo de
    dependencias internas del módulo. *Criterio:* un comando o una tubería; si
    dibujas el grafo, mejor.

**🔴 Muy difícil (22–24)**

22. **La política de errores de la plataforma.** Escribe
    `docs/errores.md`: la política de errores de Meridian que los cuatro servicios
    van a seguir. *Rúbrica:* (a) define cuándo centinela, cuándo tipo y cuándo
    error inmediato, con un ejemplo real de cada uno tomado del código escrito
    hasta ahora; (b) define en qué fronteras se traduce y qué se conserva; (c)
    define qué se registra y qué no —incluidos los secretos—; (d) incluye la regla
    de la interfaz nula con el ejemplo; (e) es lo bastante concreta como para que
    alguien la use en una revisión de código sin preguntarte nada.
23. **El agregador de errores, escrito a mano.** Implementa un tipo
    `multiError` que acumule errores, satisfaga `error`, permita `errors.Is` sobre
    **cualquiera** de los que contiene, y se pueda recorrer. *Rúbrica:* (a)
    funciona con cero, uno y N errores, y con cero devuelve `nil` desde su
    constructor; (b) `errors.Is` encuentra cualquiera de los contenidos; (c) el
    mensaje resultante es legible con diez errores dentro; (d) comparas tu
    implementación con `errors.Join` de Go 1.20 leyendo su documentación y dices
    qué hace distinto. 🕰️
24. **El pipeline de reportes con streaming.** Escribe un programa que lea un
    archivo JSON de un millón de work items y produzca un CSV agregado por tipo y
    estado, **sin superar los 50 MB de memoria residente**. *Rúbrica:* (a) usa
    `json.Decoder` en streaming y `bufio.Writer` con su `Flush` comprobado; (b)
    mides la memoria con `runtime.ReadMemStats` y la reportas; (c) todos los
    errores de E/S se propagan con contexto suficiente para saber en qué registro
    falló; (d) el `Close` y el `Flush` del archivo de salida se comprueban de
    verdad, y demuestras que un disco lleno produce un error y no un archivo
    truncado silencioso (puedes simularlo con un `io.Writer` que falle a propósito).

**🔥 Opcionales**

- Lee el código de `errors` en tu `GOROOT` de 1.13. Son menos de cien líneas entre
  `errors.go` y `wrap.go`, y contienen `Is`, `As` y `Unwrap` completos. Es de lo
  mejor escrito de la stdlib.
- Compara el manejo de errores de Go con el de Rust (`Result<T, E>` y `?`). No es
  ocioso: `?` es exactamente el azúcar sintáctico que la comunidad de Go lleva una
  década debatiendo y rechazando, y las propuestas rechazadas
  (https://go.dev/doc/faq#exceptions) explican el porqué mejor que ningún artículo.

---

### 🔴 Desafíos de cierre

> Tres ejercicios de dificultad alta que **no cuentan en el total de la sección** y
> no son parte del recorrido base.

**D1 — La cadena de `io.Writer` componible.**
Construye una cadena de escritura donde cada eslabón es un `io.Writer` que envuelve
al siguiente: contador de bytes → compresor (`compress/gzip`) → cifrador
(`crypto/cipher` en modo flujo) → archivo.
*Rúbrica:* (a) el orden de la cadena importa y lo demuestras: comprimir después de
cifrar no comprime nada, y explicas por qué; (b) todos los `Close` se llaman en el
orden correcto y **sus errores se comprueban** —el `Close` del compresor es donde se
escribe el pie del formato—; (c) un fallo en cualquier eslabón se propaga con
contexto suficiente para saber cuál falló; (d) lo verificas leyendo de vuelta con la
cadena inversa y comparando byte a byte.

**D2 — El decodificador tolerante a versiones.**
Diseña el formato JSON de `WorkItem` para que dos versiones del servicio, con
esquemas distintos, puedan leer y escribir el mismo documento sin perder datos.
*Rúbrica:* (a) la v2 añade un campo y renombra otro; (b) la v1 lee un documento v2
sin fallar y **sin perder el campo que no conoce** al reescribirlo —pista:
`json.RawMessage` para lo no modelado—; (c) la v2 lee un documento v1 y sabe que le
falta información, en vez de asumir el valor cero; (d) escribes la regla de
compatibilidad que tu formato promete, y el test que la verifica en las dos
direcciones.

**D3 — El analizador de errores ignorados.**
Escribe una herramienta con `go/ast` que encuentre todos los `_ = f()` donde `f`
devuelve un `error`, y que **distinga los justificados de los que no**.
*Rúbrica:* (a) detecta la asignación en blanco sobre una llamada que devuelve
error; (b) considera justificado el que lleva un comentario en la misma línea o en
la anterior explicando por qué se ignora, y lo reporta aparte; (c) la corres sobre
la stdlib de Go y comentas qué encuentras —hay casos, y son instructivos—; (d)
comparas tu salida con la de `errcheck` y explicas en qué se diferencia y por qué
escribir la tuya te enseñó más que configurar la suya.

---

## 📚 9. Referencias

### Documentación oficial

- **`errors`** — https://pkg.go.dev/errors — corto y hay que leerlo entero.
- **`fmt`** — https://pkg.go.dev/fmt — la sección de verbos, y en particular `%w`,
  `%v` y `%+v`.
- **`encoding/json`** — https://pkg.go.dev/encoding/json — la documentación de
  `Marshal` describe **todas** las reglas de etiquetas y de tipos; léela una vez
  entera y ahórrate cinco búsquedas.
- **`io`** — https://pkg.go.dev/io · **`bufio`** — https://pkg.go.dev/bufio ·
  **`os`** — https://pkg.go.dev/os
- **Notas de la versión 1.13** — https://go.dev/doc/go1.13 — la sección *Error
  wrapping* es la razón de ser de esta fase.
- **Effective Go: Errors** — https://go.dev/doc/effective_go#errors
- **Go FAQ: Why does Go not have exceptions?** —
  https://go.dev/doc/faq#exceptions — la respuesta oficial, y es más matizada de
  lo que la gente cita.
- **Especificación: Package initialization y visibilidad** —
  https://go.dev/ref/spec#Exported_identifiers
- **Sobre `internal/`** — https://go.dev/doc/go1.4#internalpackages y la
  referencia de módulos.

### Libros

- **The Go Programming Language** — Donovan y Kernighan, capítulo 5 (*Functions*),
  secciones 5.4 (*Errors*), 5.8 (*Deferred Function Calls*) y 5.9
  (*Panic and Recover*). Anterior a `%w`, así que **léelo sabiendo que le falta esa
  parte**; todo lo demás sigue vigente.
- **Learning Go** — Jon Bodner, capítulo *Errors*. Es el que mejor cubre `%w`,
  `errors.Is`/`As` y la interfaz nula, con la profundidad correcta para este perfil.
- **100 Go Mistakes** — Harsanyi. Errores #48 a #56 son el manejo de errores
  completo, y #78 es la interfaz nula.

### Artículos y charlas

- **Working with Errors in Go 1.13** — https://go.dev/blog/go1.13-errors — el
  artículo oficial que introdujo `%w`. **Es la lectura obligatoria de esta fase.**
- **Error handling and Go** — https://go.dev/blog/error-handling-and-go — el
  original de 2011; explica el modelo, y está bien saber que lleva ahí desde el
  principio.
- **Defer, Panic, and Recover** — https://go.dev/blog/defer-panic-and-recover —
  oficial, y cubre la semántica exacta de §6.3.
- **Errors are values** — Rob Pike, https://go.dev/blog/errors-are-values — corto,
  y contiene la idea que cambia la forma de escribir Go: si el `if err != nil` se
  repite demasiado, **el problema es el diseño de la API**, no el lenguaje. El
  ejemplo del `errWriter` es el que hay que robar.
- **JSON and Go** — https://go.dev/blog/json — oficial, y cubre `RawMessage`.
- **Why you should use `errors.Is`** — busca el artículo de Dave Cheney,
  *Don't just check errors, handle them gracefully*
  (https://dave.cheney.net/2016/04/27/dont-just-check-errors-handle-them-gracefully).
  Es anterior a 1.13 y propone el paquete `pkg/errors`, que fue el prototipo de lo
  que acabó en la stdlib. **Advertencia: no uses `pkg/errors` en proyectos nuevos**;
  el artículo se lee por las ideas, no por la API.

### Video

- **Understanding nil** — Francesc Campoy, GopherCon 2016. Los últimos diez
  minutos son la autopsia de esta fase, explicada mejor que aquí.
- **GopherCon: Handling Go errors** — hay varias charlas con títulos parecidos;
  busca las posteriores a 2019 para que cubran `%w`.

> ⚠️ Todo el material anterior a septiembre de 2019 **no conoce `%w`** y muchos
> recomiendan `github.com/pkg/errors`. Ese paquete está archivado y su
> funcionalidad está en la stdlib. Mira la fecha.

### Orden de lectura sugerido

**Antes de escribir código:** *Working with Errors in Go 1.13*. Quince minutos y
es exactamente lo que vas a usar.
**Durante:** la documentación de `encoding/json.Marshal` cuando una etiqueta no
haga lo que esperas, y *Defer, Panic, and Recover* cuando el `defer` te sorprenda.
**Después:** *Errors are values* de Pike, con calma, y el capítulo de Bodner. El
primero te va a hacer reescribir alguna función con menos `if err != nil`, que es
el objetivo.

---

## ⚖️ 10. Veredicto y cierre

### ⚖️ Cuándo NO usar esto

Los errores como valores son un intercambio, no una victoria, y estos son los
casos donde el modelo de Java es honestamente mejor:

- **Cuando el flujo de error es raro y el camino feliz es largo.** Un parser de
  cuarenta pasos donde cualquiera puede fallar y el manejo es siempre el mismo
  —abortar— se lee mucho mejor con un `try` alrededor. En Go hay que escribir
  cuarenta `if err != nil` idénticos, o inventar el patrón `errWriter` de Pike,
  que es ingenioso pero no es obvio para quien lo hereda.
- **Cuando necesitas que el error no se pueda ignorar.** `_ = f()` compila. El
  linter ayuda, y el linter se puede desactivar con un `//nolint`. La excepción
  comprobada de Java no se puede desactivar, y en un dominio donde ignorar un
  fallo tiene consecuencias regulatorias —pagos, salud— ese es un argumento serio.
- **Cuando quieres el stack trace gratis.** Un `error` de Go no lleva pila. Si
  quieres saber de dónde salió, tienes que haberla añadido con contexto en cada
  nivel, a mano. Java te da la pila completa sin que hagas nada, y para depurar un
  incidente a las tres de la mañana eso vale mucho. (Hay librerías que añaden pila;
  este curso no las usa, porque el contexto escrito a mano suele ser más útil que
  cuarenta líneas de marcos internos.)
- **Cuando el manejo de errores es transversal.** `@ControllerAdvice` traduce
  cualquier excepción del sistema a una respuesta HTTP en un solo sitio, sin que
  ninguna capa intermedia participe. En Go eso se monta en el borde (Fase 05) y
  funciona bien, pero solo para lo que llegue hasta allí: un error tragado en el
  camino no llega nunca.
- **Y sobre `panic`/`recover`:** no los uses como control de flujo, pero tampoco
  los demonices. Hay un caso legítimo poco conocido —un parser recursivo profundo
  donde propagar el error por treinta niveles sería absurdo— y la propia stdlib lo
  usa así internamente en `encoding/json`. La regla es que **el panic no cruza la
  frontera del paquete**: se recupera dentro y se convierte en un `error` normal.

### 📖 Diccionario Java ⇄ Go de esta fase

| Java | Go | Dónde se rompe la equivalencia |
|---|---|---|
| `Exception` (comprobada) | `error` devuelto | Nada te obliga a manejarlo: `_ = f()` compila. `errcheck` es la mitigación, no una garantía |
| `RuntimeException` | `error` devuelto, o `panic` | En Go casi todo es "comprobado por convención"; el `panic` es para invariantes rotos, no para errores esperables |
| `throws IOException` | `(T, error)` en la firma | El error está en el tipo de retorno, no en una cláusula aparte. Lo ves donde ocurre, no solo donde se declara |
| `try/catch` | `if err != nil` | No hay agrupación: cada punto de fallo se maneja en su línea. Más verboso, más preciso |
| `catch (SpecificException e)` | `errors.As(err, &target)` | Por tipo, y atraviesa la cadena de envoltorios |
| `catch` por jerarquía de excepciones | `errors.Is(err, Sentinel)` | No hay jerarquía. La "familia" se expresa con un centinela y el método `Is` |
| `e.getCause()` | `errors.Unwrap(err)` | Igual en espíritu. `errors.Is`/`As` recorren la cadena por ti |
| `new X("msg", cause)` | `fmt.Errorf("msg: %w", err)` | En Go 1.13 **solo un `%w` por `Errorf`**. Varios llegan en 1.20 🕰️ |
| `addSuppressed` | *(no existe en 1.13)* | Se resuelve con un tipo propio que acumule; `errors.Join` lo formaliza en 1.20 🕰️ |
| Stack trace automático | *(no existe)* | El contexto lo añades tú al envolver. Menos automático, y normalmente más legible |
| `finally` | `defer` | El alcance es la **función**, no el bloque. Esa diferencia es el bug del `defer` en un bucle |
| `try-with-resources` | `defer f.Close()` | Igual en intención 🩻. En un bucle hay que extraer una función; y el error del `Close` se descarta si no lo capturas |
| `throw` como control de flujo | `panic` | `panic` desenrolla y mata el proceso si nadie recupera; `recover` solo funciona en un `defer` de la misma goroutine |
| `@ControllerAdvice` | traducción de errores en el borde HTTP (Fase 05) | Explícita y local: solo cubre lo que llegue hasta el handler |
| `package-private` | identificador en minúscula | Dos niveles nada más. Dentro del paquete, todo es visible |
| `module-info.java` con `exports` | `internal/` | Regla del compilador, no configuración. No hay `--add-exports` que la abra |
| Ciclos entre paquetes | *(prohibidos)* | El compilador los rechaza. Obliga a decidir la dirección de las dependencias desde el principio |
| `InputStream` / `OutputStream` | `io.Reader` / `io.Writer` | Una interfaz de **un** método en vez de nueve. Implementar la tuya cuesta cuatro líneas |
| `BufferedReader` / `BufferedWriter` | `bufio.Reader` / `bufio.Writer` | Mismo propósito. En Go el `Flush` es tuyo y olvidarlo trunca el archivo en silencio |
| `Files.readAllBytes` | `ioutil.ReadFile` (1.13) / `os.ReadFile` (1.16+) 🕰️ | Idéntico; solo cambió de paquete |
| Jackson `ObjectMapper` | `encoding/json` | Sin configuración global, sin módulos, sin anotaciones más allá de las etiquetas de campo. Menos potente y mucho más predecible |
| `@JsonProperty("x")` | `json:"x"` | Etiqueta de struct, verificada por `vet` pero no por el compilador |
| `@JsonIgnore` | minúscula inicial, o `json:"-"` | La visibilidad ya decide: un campo no exportado nunca se serializa |
| `@JsonInclude(NON_NULL)` | `json:",omitempty"` | **No es lo mismo**: omite el valor **cero**, no el nulo. `0` y `false` desaparecen |
| `JsonParser` (streaming) | `json.Decoder` | Mismo modelo, misma decisión de cuándo usarlo (B-06) |
| `ObjectMapper` con `FAIL_ON_UNKNOWN_PROPERTIES` | `dec.DisallowUnknownFields()` | Por defecto Go **ignora** los campos desconocidos, igual que Jackson con esa opción desactivada |

### Qué sigue

La Fase 04 cierra la deuda que llevamos arrastrando desde la Fase 01: **los
tests**. El `main` que verifica por pantalla desaparece y su contenido se convierte
en tests de tabla con subtests, `t.Cleanup`, golden files y cobertura medida con
umbral.

Y con ellos, los dobles de prueba **en el orden del curso: función, fake, y aquí
nos detenemos a propósito**. Un `FakeClock` y un `FakeStore` de veinte líneas
cubren todo lo que hemos escrito, y vas a ver con tus ojos que no te hizo falta
Mockito. El generador llega en la Fase 10, cuando la interfaz del cliente HTTP lo
justifique, y allí se explica por qué tarda tanto.

### La señal de que quedó bien

> *"Leo una firma que devuelve `(Report, error)` y sé, sin abrir la
> implementación, que puede fallar y que el fallo es asunto mío. Y cuando lo
> manejo, `errors.Is` me dice qué pasó sin que yo tenga que leer un mensaje."*

Si todavía comparas errores con `==` o `strings.Contains(err.Error(), "not found")`,
vuelve a §6.2. Esa segunda forma, en particular, es la que rompe el día que alguien
traduce un mensaje.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en
> verde, `go1.13 vet ./...`, `gofmt -l .` y `golangci-lint run` limpios y
> `git status` sin cambios pendientes:
>
> ```bash
> git tag -a fase-03 -m "F3 cerrada: política de errores con centinelas, tipos y %w; ValidationError acumulativo; internal/config con precedencia y fallo rápido; JSON de WorkItem y Delivery; error-chain, config-loader y json-codec; B-06 medido"
> git tag -a opsreport/v0.3 -m "OpsReport: errores del dominio, configuración y serialización"
> git tag -a eventrelay/v0.2 -m "EventRelay: errores, configuración y JSON de eventos y entregas"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 03: …`) y los de ejercicio su
> número (`fase 03 ej22: …`). Todo eso está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).

---

# 📌 Bloque de autoría (fuera de lo que lee el estudiante)

## 📌 Pendientes sugeridos

- **El patrón `errWriter` de Rob Pike** (acumular el error en un struct para no
  repetir `if err != nil` en veinte escrituras seguidas) — mencionado solo en las
  referencias. Su sitio natural es la **Fase 13**, en el generador de reportes CSV
  de ClearingHouse, donde hay exactamente ese problema. **Anotar allí.**
- **`DisallowUnknownFields` y la compatibilidad hacia adelante** — nombrado en
  §7.5. La decisión de activarlo o no se toma de verdad en la **Fase 05**, en el
  borde HTTP, con el argumento de versionado de API. Verificado en su alcance.
- **Stack traces en errores** (librerías como `pkg/errors` o `cockroachdb/errors`)
  — se nombra en el ⚖️ y se descarta. Si alguien lo pide, su sitio es el ⚖️ de la
  **Fase 14** junto a la observabilidad, no aquí.
- **`errors.Join`** — 🕰️ declarado tres veces en esta fase. Verificar que la Fase
  08 lo recoge y que el `multiError` del ejercicio 23 se compara explícitamente con
  él.
- **El `Payload` opaco de EventRelay y su validación de tamaño** — el límite de
  256 KB está puesto aquí sin justificación medida. Candidato a fila de
  `BENCHMARKS.md` en la **Fase 15** (coste de validar JSON grande), o a decisión
  documentada en la Fase 05.

## ☕ Reflejos para `INSTINTOS.md`

- **"La interfaz nula que no es nula"** — devolver `*MiError` donde el contrato es
  `error`. Coste: todos los caminos felices se convierten en errores; una línea
  para arreglarlo y horas para encontrarlo. Antídoto: **devuelve siempre `error` y
  `nil` literal**.
- **"`panic`/`recover` como `try`/`catch`"** — pierde identidad del error, no
  cruza goroutines y nadie más escribe así.
- **"Comparar errores con `==` o con `strings.Contains`"** — se rompe con el primer
  envoltorio, o con la primera traducción del mensaje.
- **"Envolver todo con `%w` por reflejo"** — convierte los detalles internos en
  API pública.
- **"Jerarquía de siete tipos de error"** — el reflejo de `extends Exception`.
  Casi siempre son tres centinelas y un tipo con datos.
- **"`defer` dentro del bucle"** — el alcance es la función, no el bloque. Coste:
  agotamiento de descriptores en producción, con carga alta y no en desarrollo.

## 📐 Mediciones para `BENCHMARKS.md`

- **B-06 — Decodificación JSON completa frente a streaming.** Documento de 50.000
  work items, las dos implementaciones en `labs/json-codec`. **Lo importante es
  `B/op`**, no `ns/op`; el veredicto tiene que decir en qué caso el streaming no
  compensa (documentos pequeños, donde la sobrecarga del `Decoder` gana).
- Anotado para la Fase 13: B-19 (reporte de 500.000 filas) es la versión a escala
  real de esta misma medición, y debería citar a B-06 como antecedente.
