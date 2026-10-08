# 🧱 Fase 02 — Structs, métodos, interfaces y composición

> Go para desarrolladores Java senior · Fase 2 de 17 · **7 horas**
> Época: **Go 1.13 (stdlib pura)**
> Depende de: Fase 01 · Habilita: Fase 03
> Proyectos que avanzan: **OpsReport** (dominio y servicio) · **EventRelay nace**
> Mini proyectos: `shapes`, `store-registry`, `notifier`

---

## 🎯 1. Propósito

La Fase 01 te dejó `WorkItem` como un struct plano con funciones sueltas al lado.
Funciona, y es exactamente donde se queda atascada la mayoría de la gente que
llega desde Java: escriben structs anémicos, les ponen un `Service` con
`Impl`, le sacan una interfaz de nueve métodos "por si acaso", y acaban con un
proyecto que compila, pasa los tests y ningún gopher querría mantener.

**Esta es la fase que decide si vas a escribir Go o Java con llaves distintas.**
Es la más importante del Bloque A para el objetivo del curso, y su idea central
cabe en una línea: **la interfaz se declara donde se consume, no donde se
implementa.** Eso invierte la dirección de las dependencias que traes de Spring y
es lo que permite que las interfaces sean diminutas.

Al terminar, OpsReport tiene servicio y almacén, EventRelay nace con su máquina de
estados, y sabes contar cuánto cuesta —en archivos, líneas e indirecciones— un
`ThingServiceImpl`.

---

## ✅ 2. Qué queda listo al terminar

- [ ] `internal/workitem` tiene métodos sobre `WorkItem` y una máquina de estados
      con `CanTransitionTo`.
- [ ] `internal/opsreport` declara **sus propias** interfaces `Store`, `Clock` e
      `IDGenerator`, cada una con lo mínimo que usa.
- [ ] `internal/memstore` implementa `Store` **sin importar** el paquete
      `opsreport`, y lo compruebas con `go1.13 list -f '{{.Imports}}'`.
- [ ] `cmd/opsreport/main.go` cablea todo en menos de cincuenta líneas legibles de
      arriba abajo, sin contenedor y sin registro global.
- [ ] `services/eventrelay` existe como módulo con `go 1.13`, y tiene `Endpoint`,
      `Event`, `Delivery` y su máquina de estados.
- [ ] `labs/shapes`, `labs/store-registry` y `labs/notifier` compilan y corren.
- [ ] Puedes explicar, con código delante, por qué `*T` implementa más interfaces
      que `T`.
- [ ] `go1.13 vet ./...` y `gofmt -l .` en verde.

---

## 🚫 3. Qué NO entra todavía

- Manejo serio de errores —centinelas, tipos de error, `%w`, `errors.Is`— → Fase
  03. Aquí los errores siguen siendo `errors.New` y se devuelven tal cual.
- Tests → Fase 04. Seguimos verificando con `main`, y la deuda 💸 de la Fase 01
  sigue viva.
- Genéricos → Fase 08 🕰️ (Go 1.18). Cuando escribas la segunda interfaz
  `Store` casi idéntica, vas a querer `Repository[T]`. Aguanta: en la Fase 08 lo
  vas a poder escribir y vas a ver **por qué no deberías**.
- HTTP → Fase 05. Los servicios de esta fase no tienen API; se ejercitan desde
  `main`.
- Concurrencia → Fase 06. El `memstore` de esta fase **no es seguro para uso
  concurrente** y lo dice en su documentación. 💸

---

## 🧠 4. Concepto mínimo

### Structs y métodos: el receptor es un parámetro con otro sitio

```go
type WorkItem struct {
	ID       string
	Priority Priority
	Status   Status
}

// El receptor va antes del nombre. Por lo demás, es un parámetro normal.
func (w WorkItem) IsTerminal() bool {
	return w.Status == StatusDone || w.Status == StatusFailed
}
```

Un método en Go **no vive dentro del tipo**: es una función de paquete con un
parámetro especial en primera posición. Eso tiene una consecuencia que sorprende:
los métodos se declaran en cualquier archivo del paquete, y el struct no sabe
cuántos tiene.

📖 En Java, el método está dentro de las llaves de la clase y el `this` es
implícito. Aquí el receptor tiene nombre —`w`— y **se elige por convención: una o
dos letras, la misma en todos los métodos del tipo**. Nunca `this`, nunca `self`.

### Receptor por valor o por puntero: la decisión que sí importa

```go
// Por VALOR: recibe una copia. No puede modificar el original.
func (w WorkItem) Label() string { return string(w.Kind) + ":" + w.ID }

// Por PUNTERO: recibe la dirección. Puede modificar el original.
func (w *WorkItem) MarkRunning(now time.Time) {
	w.Status = StatusRunning
	w.StartedAt = now
}
```

La regla práctica, que se sostiene todo el curso:

> 🧭 **Regla del proyecto.** Usa receptor por puntero si el método modifica el
> receptor, si el struct es grande, o si **algún** método del tipo ya lo usa.
> **La consistencia manda**: mezclar receptores por valor y por puntero en el
> mismo tipo es una fuente de confusión y de bugs sutiles.

Y aquí está la parte que hay que entender de verdad, porque es la trampa número
uno de esta fase:

```go
type Notifier interface {
	Notify(message string) error
}

type EmailNotifier struct{ sent int }

func (n *EmailNotifier) Notify(message string) error {   // ← receptor POR PUNTERO
	n.sent++
	return nil
}

func main() {
	var n Notifier

	n = &EmailNotifier{}  // ✅ compila
	n = EmailNotifier{}   // ❌ cannot use EmailNotifier{} as Notifier:
	                      //    Notify method has pointer receiver
}
```

**El conjunto de métodos de `T` incluye solo los métodos con receptor por valor.
El de `*T` incluye los dos.** Por eso `*T` implementa más interfaces que `T`.

La razón es coherente con el modelo de valores de la Fase 01: si `EmailNotifier{}`
satisficiera la interfaz, al guardarlo en ella se copiaría, y `n.sent++`
incrementaría un contador de una copia que nadie va a leer. Go prefiere no
compilar antes que hacer eso en silencio.

> ⚠️ El mensaje de error es literalmente *"method has pointer receiver"*, y es de
> los pocos mensajes del compilador de Go que te dice exactamente qué hacer:
> pon un `&`.

### Embedding: no es herencia, y la diferencia se ve en un método

Go permite incrustar un tipo dentro de otro sin nombre de campo:

```go
type Base struct {
	ID string
}

func (b Base) Describe() string { return "entidad " + b.ID }
func (b Base) Summary() string  { return "resumen de " + b.Describe() }

type Store struct {
	Base           // embedding: sin nombre de campo
	Name string
}

func (s Store) Describe() string { return "tienda " + s.Name }
```

Y ahora el experimento que hay que hacer una vez:

```go
s := Store{Base: Base{ID: "ST-014"}, Name: "Chapinero"}

fmt.Println(s.Describe())  // "tienda Chapinero"     ← el de Store, como esperabas
fmt.Println(s.Summary())   // "resumen de entidad ST-014"  ← ¿cómo?
```

**`Summary()` llamó al `Describe()` de `Base`, no al de `Store`.** En Java, con
herencia real, `Summary()` habría hecho *dispatch* dinámico y te habría devuelto
`"resumen de tienda Chapinero"`. Aquí no: `Base.Summary` fue compilado sabiendo
que su receptor es un `Base`, y un `Base` no sabe nada de `Store`.

> 🧠 **Modelo mental.** El embedding es **delegación con azúcar sintáctico**, no
> herencia. Go "promueve" los métodos del tipo incrustado al externo para que
> puedas escribir `s.Describe()` en vez de `s.Base.Describe()`, y ahí termina la
> magia. **No hay `super`, no hay `@Override`, no hay polimorfismo hacia arriba.**
> Si querías que `Base.Summary` usara el `Describe` del hijo, el patrón plantilla
> no está disponible: se resuelve pasando una interfaz o una función.

Esta es la diferencia de diseño que más código de Java portado rompe, y rompe en
silencio. El programa compila, los tests de la clase base pasan, y el
comportamiento polimórfico que dabas por hecho no ocurre.

### Interfaces implícitas, y quién las declara

No hay `implements`. Un tipo satisface una interfaz si tiene sus métodos, y punto:

```go
// El paquete que CONSUME declara lo que necesita.
package opsreport

type Store interface {
	Save(item workitem.WorkItem) error
	FindByID(id string) (workitem.WorkItem, error)
}
```

```go
// El paquete que IMPLEMENTA no sabe que esa interfaz existe.
package memstore

type Store struct{ items map[string]workitem.WorkItem }

func (s *Store) Save(item workitem.WorkItem) error { ... }
func (s *Store) FindByID(id string) (workitem.WorkItem, error) { ... }
```

`memstore` **no importa `opsreport`**. No hay acoplamiento en esa dirección, no hay
anotación, no hay registro. Y sin embargo `*memstore.Store` satisface
`opsreport.Store` perfectamente.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El instinto:** *"primero defino la interfaz del servicio, después la
implementación"*. Es correcto en Java y está institucionalizado: `UserService` +
`UserServiceImpl`, `@Service` en la implementación, `@Autowired` en el consumidor,
y el contenedor une las dos puntas. La interfaz vive **con la implementación**,
porque es su contrato público.

**Qué pasa si lo aplicas aquí.** Escribes esto:

```go
// internal/workitem/service.go   ← ☕
package workitem

type WorkItemService interface {
	Create(item WorkItem) (WorkItem, error)
	GetByID(id string) (WorkItem, error)
	List(status Status) ([]WorkItem, error)
	Start(id string) error
	Cancel(id string) error
	MarkDone(id string) error
	MarkFailed(id string, reason string) error
	Count() (int, error)
	DeleteByID(id string) error
}

type WorkItemServiceImpl struct{ store WorkItemStore }

func NewWorkItemServiceImpl(store WorkItemStore) WorkItemService {
	return &WorkItemServiceImpl{store: store}
}
```

Y lo que has construido es esto:

- Una interfaz de **nueve métodos con un solo implementador**, que por definición
  no abstrae nada: cada vez que añadas un método al servicio, tendrás que añadirlo
  a la interfaz, y eso no es abstracción, es transcripción.
- Un **constructor que devuelve la interfaz** en vez del tipo concreto, lo que
  impide al llamador usar cualquier método que no esté en ella y obliga a
  aserciones de tipo para salir del paso.
- Un nombre, `WorkItemServiceImpl`, que **repite el paquete** (`workitem.WorkItemService`
  es tartamudeo) y lleva un sufijo que en Go no significa nada.
- Y el efecto que de verdad duele: **para saber qué hace `Create`, tienes que
  saltar de la interfaz a la implementación.** Multiplica eso por cuarenta tipos.

**Qué pensar en su lugar.** Invierte la pregunta. No es *"¿qué contrato expone mi
servicio?"*, es **"¿qué necesita el que me llama?"**. Y resulta que el llamador
—el handler HTTP de la Fase 05, el motor de jobs de la Fase 06— casi nunca
necesita nueve métodos. Necesita dos.

```go
// internal/httpapi/handler.go   (Fase 05)
package httpapi

// El handler declara lo que usa, y no más. Si mañana el servicio crece a veinte
// métodos, esta interfaz no cambia.
type WorkItemCreator interface {
	Create(item workitem.WorkItem) (workitem.WorkItem, error)
}
```

El servicio, mientras tanto, es un **struct concreto** con sus métodos, exportado
tal cual:

```go
// internal/opsreport/service.go
package opsreport

type Service struct {
	store Store
	clock Clock
	ids   IDGenerator
}

func New(store Store, clock Clock, ids IDGenerator) *Service {
	return &Service{store: store, clock: clock, ids: ids}
}
```

> 🧭 **Regla del proyecto, y es la más importante del curso.** Las interfaces se
> declaran **donde se consumen**. Un paquete exporta structs concretos y funciones;
> las interfaces aparecen en el paquete que las necesita, con el tamaño mínimo que
> necesita. Si una interfaz tiene más de tres o cuatro métodos, párate y pregunta
> quién la consume y para qué.

☕ **La pregunta recurrente del curso**, que te vas a hacer en voz alta a partir de
aquí:

> **¿Esta abstracción existe porque el dominio la necesita, o porque así la
> escribiríamos en Spring?**

### La interfaz vacía y las aserciones de tipo

```go
var anything interface{} = 42

// Aserción con el idioma de dos valores: nunca en la forma de un valor, que
// entra en panic si el tipo no coincide.
if n, ok := anything.(int); ok {
	fmt.Println(n + 1)
}

// Type switch: el switch sobre el tipo dinámico.
switch v := anything.(type) {
case int:
	fmt.Println("entero", v)
case string:
	fmt.Println("cadena", v)
default:
	fmt.Printf("tipo no esperado: %T\n", v)
}
```

`interface{}` es el `Object` de Go, con la misma advertencia: **cada vez que lo
usas, pierdes ayuda del compilador**. En el Bloque A aparece exactamente en dos
sitios legítimos: `fmt.Printf` y `encoding/json` (Fase 03). En el resto, si estás
escribiendo `interface{}`, casi siempre lo que quieres es una interfaz pequeña con
un método.

> 🕰️ **Fuera de época.** En Go 1.18 llegó `any` como alias exacto de
> `interface{}` —mismo tipo, nombre más corto— y con él los genéricos, que son la
> respuesta correcta a la mitad de los usos de `interface{}`. Fase 08.

### `Stringer` y `error`: las dos interfaces que todo el mundo implementa

```go
// fmt.Stringer — una sola operación, y fmt la usa automáticamente.
type Stringer interface{ String() string }

// error — la interfaz más importante del lenguaje. Un método.
type error interface{ Error() string }
```

Implementar `String()` en un tipo del dominio hace que `fmt.Printf("%s", item)`
imprima algo legible, y es gratis:

```go
func (s Status) String() string { return string(s) }

func (w WorkItem) String() string {
	return fmt.Sprintf("%s[%s/%s p%d]", w.ID, w.Kind, w.Status, w.Priority)
}
```

> ⚠️ **La trampa del `String()` recursivo.** Si dentro de `String()` usas
> `fmt.Sprintf("%v", w)` sobre el propio receptor, `fmt` vuelve a llamar a
> `String()` y tienes un desbordamiento de pila. Usa los campos, nunca el receptor
> entero.

### Constructores por convención y el cableado sin contenedor

En Go no hay constructores del lenguaje. Hay una convención:

```go
// New cuando el paquete devuelve su tipo principal.
func New(store Store, clock Clock) *Service { ... }

// NewX cuando hay varios tipos.
func NewWorkItemStore(db *sql.DB) *WorkItemStore { ... }
```

Y el cableado es una función que se lee de arriba abajo:

```go
func main() {
	clock := systemClock{}
	ids := newULIDGenerator()
	store := memstore.New()

	service := opsreport.New(store, clock, ids)
	// ...
}
```

Eso es todo. **No hay contenedor, no hay escaneo de paquetes, no hay grafo de
dependencias resuelto en tiempo de ejecución.** Si `main` crece a ciento cincuenta
líneas, se parte en funciones; si crece a quinientas, el problema es el diseño, no
el cableado.

📖 Lo que pierdes respecto a Spring: la configuración por perfil que cambia una
implementación sin tocar código, el *lazy loading* de beans, y los *proxies*
que envuelven tus métodos con transacciones o caché. Lo que ganas: **puedes leer
el grafo completo de dependencias de tu aplicación en un archivo**, y ninguna
dependencia aparece por arte de magia. En la Fase 09 vas a ver el precio exacto de
perder `@Transactional`.

### 🩻 Esto sí funciona igual

- **Separar dominio de infraestructura sigue siendo correcto.** El paquete
  `workitem` no sabe que existe una base de datos; `memstore` no sabe que existe
  un servicio. Esa es la misma arquitectura que ya aplicas, y se traslada intacta.
- **Inyectar dependencias por constructor sigue siendo correcto.** Lo que
  desaparece es el contenedor, no la práctica.
- **Probar contra interfaces sigue siendo correcto.** Solo que las interfaces son
  más pequeñas y los dobles son más baratos (Fase 04).
- **Un tipo del dominio con su propia validación y su máquina de estados** es tan
  buena idea aquí como allí. El struct anémico es un antipatrón en los dos
  lenguajes.
- **`toString()` es `String()`.** Mismo propósito, misma utilidad al depurar, y en
  Go además lo usa `fmt` sin que hagas nada.

---

## 🛠️ 5. CLI de la fase

```bash
# El comando estrella de la fase: ver qué importa un paquete. Es cómo se verifica
# que la dirección de las dependencias es la correcta y que memstore no conoce a
# opsreport.
go1.13 list -f '{{.ImportPath}} imports {{.Imports}}' ./internal/...

# Solo los imports del propio módulo, que es lo que interesa para la arquitectura.
go1.13 list -deps ./internal/opsreport | grep meridian

# La documentación de tu propio código, como la va a ver quien lo herede. Si
# go doc no se entiende, tus comentarios de documentación están mal escritos.
go1.13 doc ./internal/opsreport
go1.13 doc ./internal/opsreport Service
go1.13 doc ./internal/workitem WorkItem.CanTransitionTo

# vet detecta el método que "casi" implementa la interfaz: firma con un puntero
# de más, un valor de retorno de menos, o el receptor equivocado.
go1.13 vet ./...

# Ver la interfaz que satisface un tipo no lo hace el toolchain: se comprueba en
# tiempo de compilación con la aserción de nil, que es el idioma del ecosistema.
#   var _ opsreport.Store = (*memstore.Store)(nil)
go1.13 build ./...

# Benchmarks de la fase (B-05): coste de una llamada por interfaz.
go1.13 test -run '^$' -bench . -benchmem -count=10 ./labs/shapes
```

> 💡 **El idioma `var _ Iface = (*Tipo)(nil)`.** Es una declaración de variable
> descartada cuyo único efecto es que el compilador verifique que `*Tipo`
> satisface `Iface`. No cuesta nada en tiempo de ejecución —no hay valor, no hay
> asignación— y convierte un error de integración en un error de compilación. Es
> lo más parecido que Go tiene a `implements`, y es opcional a propósito: se pone
> **en el paquete que implementa**, cuando quieres esa garantía.

---

## 💻 6. Construcción guiada

### 6.1 Mini proyecto: `shapes`

El "hola mundo" de las interfaces, que además nos sirve para medir su coste
(B-05) y para hacer la primera autopsia. Empezamos por la versión que **no**
queremos:

```go
// labs/shapes/java_style.go   ☕ — esto es lo que NO hay que escribir
package shapes

// AbstractShape intenta ser una clase base. En Go no hay clase base.
type AbstractShape struct {
	name string
}

func (a *AbstractShape) GetName() string     { return a.name }
func (a *AbstractShape) SetName(n string)    { a.name = n }
func (a *AbstractShape) Area() float64       { return 0 } // "los hijos lo sobrescriben"
func (a *AbstractShape) Describe() string    { return a.GetName() + " con área " + fmt.Sprint(a.Area()) }

type Rectangle struct {
	AbstractShape
	Width, Height float64
}

func (r *Rectangle) Area() float64 { return r.Width * r.Height }
```

```go
r := &Rectangle{AbstractShape: AbstractShape{name: "rect"}, Width: 3, Height: 4}
fmt.Println(r.Area())      // 12   ✅
fmt.Println(r.Describe())  // "rect con área 0"   ❌
```

**`Describe()` devuelve área 0.** El método promovido de `AbstractShape` llama a
`AbstractShape.Area`, que devuelve 0, porque no hay *dispatch* dinámico hacia el
tipo externo. En Java este patrón —método plantilla en la clase abstracta— funciona
y es correcto. Aquí produce un cero silencioso.

Ahora la versión de Go:

```go
// labs/shapes/shapes.go
package shapes

import (
	"fmt"
	"math"
)

// Shape es todo lo que tiene área. Una operación, un método: la interfaz más
// útil del paquete cabe en tres líneas.
type Shape interface {
	Area() float64
}

// Named es una capacidad aparte. Un tipo puede tener área y no tener nombre, o
// al revés, y componerlas cuando hace falta es gratis.
type Named interface {
	Name() string
}

type Rectangle struct{ Width, Height float64 }
type Circle struct{ Radius float64 }

func (r Rectangle) Area() float64 { return r.Width * r.Height }
func (r Rectangle) Name() string  { return "rectángulo" }

func (c Circle) Area() float64 { return math.Pi * c.Radius * c.Radius }
func (c Circle) Name() string  { return "círculo" }

// Describe recibe la interfaz combinada declarada AQUÍ, en el consumidor. Ni
// Rectangle ni Circle saben que existe.
func Describe(s interface {
	Shape
	Named
}) string {
	return fmt.Sprintf("%s con área %.2f", s.Name(), s.Area())
}

// TotalArea trabaja con la interfaz mínima: solo necesita Area.
func TotalArea(shapes []Shape) float64 {
	var total float64
	for _, s := range shapes {
		total += s.Area()
	}
	return total
}
```

Ninguna clase base, ningún `abstract`, ninguna fábrica. Y `Describe` funciona con
cualquier tipo futuro que tenga los dos métodos, sin tocar nada.

Y el benchmark que responde la pregunta que todo el mundo hace:

```go
// labs/shapes/dispatch_bench_test.go
package shapes

import "testing"

var sink float64 // evita que el compilador elimine el cálculo

func BenchmarkDirectCall(b *testing.B) {
	r := Rectangle{Width: 3, Height: 4}
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		sink += r.Area() // llamada directa, el compilador puede hacer inline
	}
}

func BenchmarkInterfaceCall(b *testing.B) {
	var s Shape = Rectangle{Width: 3, Height: 4}
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		sink += s.Area() // llamada indirecta a través de la itable
	}
}

func BenchmarkInterfaceSlice(b *testing.B) {
	shapes := []Shape{
		Rectangle{Width: 3, Height: 4},
		Circle{Radius: 2},
		Rectangle{Width: 1, Height: 9},
	}
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		sink += TotalArea(shapes)
	}
}
```

> 📐 **Cómo se mide.** Entrada **B-05** de `BENCHMARKS.md`: *coste de una llamada
> a través de interfaz frente a llamada directa*. Comando:
> `go1.13 test -run '^$' -bench . -benchmem -count=10 ./labs/shapes`.
>
> **El veredicto está escrito de antemano y no es "las interfaces son caras".** Lo
> que la medición enseña es dónde está el coste real: no en el salto indirecto,
> sino en que **la llamada por interfaz impide el *inlining***, y a veces en que
> meter un valor en una interfaz lo hace escapar al montículo (mira la columna
> `allocs/op` del tercer benchmark). Con una diferencia de nanosegundos por
> llamada, **evitar interfaces por rendimiento es optimización prematura en el
> 99,9% de los casos**; en el 0,1% restante —un bucle interno de millones de
> iteraciones— se mide y se decide, que es de lo que va la Fase 15.

### 6.2 Mini proyecto: `store-registry`

Composición frente a herencia, con un caso que en Java sería una jerarquía de tres
niveles. Meridian tiene tiendas de tres clases: las normales, las que además son
punto de recogida de un marketplace, y las de franquicia, que tienen su propio
régimen contable.

En Java el reflejo es `Store` → `PickupStore extends Store` → `FranchisePickupStore
extends PickupStore`, y en cuanto aparece una franquicia que **no** es punto de
recogida, la jerarquía se rompe y empieza el `instanceof`.

```go
// labs/store-registry/store.go
package registry

import "fmt"

// Store es el núcleo, y no tiene jerarquía: tiene capacidades.
type Store struct {
	ID       string
	Name     string
	City     string
	Timezone string
}

func (s Store) Label() string { return s.ID + " · " + s.Name }

// Pickup es una capacidad: la tienda recibe y entrega paquetes de marketplace.
// Es un struct propio, no un subtipo.
type Pickup struct {
	MaxPackages int
	CutoffHour  int
}

// Franchise es otra capacidad, independiente de la anterior.
type Franchise struct {
	OperatorTaxID string
	FeePercent    float64
}

// PickupStore compone tienda y capacidad. No hereda: contiene.
type PickupStore struct {
	Store
	Pickup
}

// FranchiseStore compone las otras dos. Y una franquicia que además es punto de
// recogida es esto, sin tocar nada de lo anterior:
type FranchisePickupStore struct {
	Store
	Pickup
	Franchise
}

// Y cuando alguien necesita "algo con etiqueta", declara la interfaz ahí:
type Labeler interface{ Label() string }

func PrintAll(stores []Labeler) {
	for _, s := range stores {
		fmt.Println(s.Label())
	}
}
```

El punto que esto demuestra: **las capacidades se combinan; los tipos no se
ordenan en un árbol.** Una franquicia sin recogida es `struct { Store; Franchise }`
y existe sin que nadie reestructure nada. En la jerarquía de Java, ese caso
obliga a mover `Pickup` a una interfaz, y ahí es donde empieza el refactor de dos
días.

⚠️ **El conflicto de nombres, que es la única regla que hay que saber.** Si
`Pickup` y `Franchise` tuvieran los dos un método `Fee()`, `FranchisePickupStore.Fee()`
**no compila**: es ambiguo y Go no elige por ti. Se resuelve calificando
(`s.Franchise.Fee()`) o escribiendo un `Fee()` propio en el tipo externo, que es
lo que en Java sería resolver el problema del diamante — con la ventaja de que
aquí el compilador te obliga a hacerlo explícito.

### 6.3 Mini proyecto: `notifier`

Una interfaz de un método, tres implementaciones, cero fábricas. Es el laboratorio
del que sale el notificador de EventRelay.

```go
// labs/notifier/notifier.go
package notifier

import (
	"fmt"
	"io"
	"strings"
)

// Notifier envía un aviso. Un método, y el nombre acaba en -er porque hace una
// sola cosa: es la convención del lenguaje.
type Notifier interface {
	Notify(subject, body string) error
}

// WriterNotifier escribe el aviso en cualquier io.Writer. Un struct de un campo.
type WriterNotifier struct{ Out io.Writer }

func (n WriterNotifier) Notify(subject, body string) error {
	_, err := fmt.Fprintf(n.Out, "[%s] %s\n", subject, body)
	return err
}

// CollectingNotifier guarda lo que recibe. Es el doble de prueba de la Fase 04,
// escrito aquí sin saberlo todavía: veinte líneas, comportamiento real.
type CollectingNotifier struct{ Messages []string }

func (n *CollectingNotifier) Notify(subject, body string) error {
	n.Messages = append(n.Messages, subject+": "+body)
	return nil
}

// FanOut manda a varios a la vez. Fíjate en que es un TIPO, no una fábrica ni un
// registro: componer implementaciones es crear otro valor del mismo tipo.
type FanOut []Notifier

func (f FanOut) Notify(subject, body string) error {
	var failures []string
	for _, n := range f {
		if err := n.Notify(subject, body); err != nil {
			failures = append(failures, err.Error())
		}
	}
	if len(failures) > 0 {
		// En la Fase 03 esto se convierte en un error tipado; en la Fase 08,
		// en errors.Join 🕰️ (Go 1.20).
		return fmt.Errorf("fallaron %d notificadores: %s",
			len(failures), strings.Join(failures, "; "))
	}
	return nil
}

// NotifierFunc adapta una función a la interfaz. Es el mismo truco que
// http.HandlerFunc usa en la stdlib, y lo vas a reconocer en la Fase 05.
type NotifierFunc func(subject, body string) error

func (f NotifierFunc) Notify(subject, body string) error { return f(subject, body) }
```

Cuatro implementaciones, ninguna fábrica, ninguna anotación, ningún registro. Y
`FanOut` —que en Java sería un `CompositeNotifier` con su lista y su constructor—
es **un slice con un método encima**.

> 💡 **`NotifierFunc` merece que lo mires dos veces.** Un tipo con nombre cuyo
> subyacente es una función puede tener métodos, y con eso una función suelta
> satisface una interfaz sin que exista ningún struct. Es el patrón que hace que
> `http.HandlerFunc(miFuncion)` funcione, y una vez que lo reconoces lo ves en
> toda la stdlib.

### 6.4 OpsReport: dominio con métodos y máquina de estados

Refactorizamos lo de la Fase 01. Las funciones sueltas se convierten en métodos, y
aparece la máquina de estados:

```go
// services/opsreport/internal/workitem/workitem.go
package workitem

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

// ... Status, Kind, Priority y sus constantes, como en la Fase 01 ...

type WorkItem struct {
	ID                string
	ExternalReference string
	Kind              Kind
	Description       string
	Priority          Priority
	Status            Status
	CreatedAt         time.Time
	StartedAt         time.Time
	FinishedAt        time.Time
	FailureReason     string
}

// String hace que un WorkItem sea legible en logs y en depuración sin esfuerzo.
// Usa los campos, nunca el receptor completo: %v sobre w volvería a llamar aquí.
func (w WorkItem) String() string {
	return fmt.Sprintf("%s[%s/%s p%d]", w.ID, w.Kind, w.Status, w.Priority)
}

// Validate comprueba que el trabajo es aceptable. Receptor por valor: no
// modifica nada.
func (w WorkItem) Validate() error {
	if strings.TrimSpace(w.ExternalReference) == "" {
		return errEmptyExternalReference
	}
	if !w.Kind.IsKnown() {
		return errUnknownKind
	}
	if w.Priority < MinPriority || w.Priority > MaxPriority {
		return errPriorityOutOfRange
	}
	if len([]rune(w.Description)) > maxDescriptionRunes {
		return errDescriptionTooLong
	}
	return nil
}

// IsKnown es un método de Kind, no una función del paquete. El tipo con nombre
// de la Fase 01 acaba de ganar comportamiento, y eso es todo lo que separa un
// alias de un tipo de dominio.
func (k Kind) IsKnown() bool {
	switch k {
	case KindReconciliation, KindImport, KindRecalculation, KindStatement, KindReprocess:
		return true
	default:
		return false
	}
}

func (s Status) IsTerminal() bool {
	switch s {
	case StatusDone, StatusFailed, StatusCancelled:
		return true
	default:
		return false
	}
}

// allowedTransitions es la máquina de estados, declarada como DATOS y no como
// una cadena de ifs repartida por el código. Que viva en un solo sitio es lo que
// impide que el handler HTTP y el motor de jobs tengan reglas distintas.
var allowedTransitions = map[Status][]Status{
	StatusQueued:  {StatusRunning, StatusCancelled},
	StatusRunning: {StatusDone, StatusFailed, StatusCancelled},
	// Los estados terminales no tienen salida; su ausencia aquí es la regla.
}

// CanTransitionTo dice si el trabajo puede pasar al estado dado.
func (w WorkItem) CanTransitionTo(next Status) bool {
	for _, allowed := range allowedTransitions[w.Status] {
		if allowed == next {
			return true
		}
	}
	return false
}

// ErrInvalidTransition se devuelve cuando alguien intenta un salto imposible.
// En la Fase 03 se convierte en un centinela comparable con errors.Is y en un
// tipo de error que lleva los dos estados dentro.
var ErrInvalidTransition = errors.New("transición de estado no permitida")

// MarkRunning mueve el trabajo a running. Receptor por PUNTERO porque modifica.
// Todos los métodos mutadores de este tipo usan puntero; los de consulta, valor.
func (w *WorkItem) MarkRunning(now time.Time) error {
	if !w.CanTransitionTo(StatusRunning) {
		return ErrInvalidTransition
	}
	w.Status = StatusRunning
	w.StartedAt = now
	return nil
}

func (w *WorkItem) MarkDone(now time.Time) error {
	if !w.CanTransitionTo(StatusDone) {
		return ErrInvalidTransition
	}
	w.Status = StatusDone
	w.FinishedAt = now
	return nil
}

func (w *WorkItem) MarkFailed(now time.Time, reason string) error {
	if !w.CanTransitionTo(StatusFailed) {
		return ErrInvalidTransition
	}
	w.Status = StatusFailed
	w.FinishedAt = now
	w.FailureReason = reason
	return nil
}

func (w *WorkItem) Cancel(now time.Time) error {
	if !w.CanTransitionTo(StatusCancelled) {
		return ErrInvalidTransition
	}
	w.Status = StatusCancelled
	w.FinishedAt = now
	return nil
}

// EffectivePriority sigue recibiendo el reloj por parámetro. En el servicio, ese
// reloj pasa a ser una dependencia inyectada.
func (w WorkItem) EffectivePriority(now time.Time) Priority {
	if w.Status != StatusQueued {
		return w.Priority
	}
	days := int(now.Sub(w.CreatedAt).Hours() / 24)
	if days <= 0 {
		return w.Priority
	}
	if effective := w.Priority + Priority(days*agingBoost); effective < MaxPriority {
		return effective
	}
	return MaxPriority
}
```

> 🧠 **Modelo mental: dónde vive la regla.** `CanTransitionTo` está en el dominio,
> no en el servicio. El servicio orquesta —busca, llama, guarda—; el tipo decide
> si el cambio es legal. Ese reparto es el mismo que aplicarías en Java con un
> agregado de DDD 🩻, y es de los reflejos que se trasladan sin tocar.

### 6.5 OpsReport: el servicio y sus interfaces

Y aquí está el corazón de la fase. El servicio declara **sus propias** interfaces,
cada una del tamaño de lo que usa:

```go
// services/opsreport/internal/opsreport/service.go

// Package opsreport contiene los casos de uso del servicio: registrar trabajos,
// consultarlos y moverlos por su ciclo de vida.
//
// Este paquete DECLARA las interfaces de todo lo que necesita del exterior
// —almacén, reloj, generador de identificadores— y no conoce ninguna
// implementación concreta. Quien las implementa no importa este paquete.
package opsreport

import (
	"errors"
	"time"

	"github.com/meridian/opsreport/internal/workitem"
)

// Store guarda y recupera work items.
//
// Tiene cuatro métodos porque el servicio usa cuatro. Si mañana hiciera falta
// borrar, se añade aquí y el compilador dirá qué implementaciones faltan por
// actualizar; no se añade "por completitud".
type Store interface {
	Save(item workitem.WorkItem) error
	FindByID(id string) (workitem.WorkItem, error)
	ListByStatus(status workitem.Status) ([]workitem.WorkItem, error)
	Update(item workitem.WorkItem) error
}

// Clock entrega la hora actual. Existe para que el servicio se pueda probar sin
// depender del reloj de la máquina, que es la razón por la que en la Fase 01
// EffectivePriority recibía `now` por parámetro.
type Clock interface {
	Now() time.Time
}

// IDGenerator produce identificadores de work item. Un método, porque es lo que
// hace falta. En la Fase 09 habrá una implementación que delega en la secuencia
// de PostgreSQL y esta interfaz no cambiará.
type IDGenerator interface {
	NewID() string
}

// Los errores del caso de uso. En la Fase 03 se vuelven centinelas comparables y
// se les añade contexto con %w.
var (
	ErrNotFound = errors.New("el work item no existe")
	ErrConflict = errors.New("el work item está en un estado que no lo permite")
)

// Service implementa los casos de uso de OpsReport.
//
// Es un struct concreto y exportado. NO hay una interfaz `WorkItemService` al
// lado: quien consuma este servicio declarará la interfaz mínima que necesite,
// en su propio paquete.
type Service struct {
	store Store
	clock Clock
	ids   IDGenerator
}

// New construye el servicio con sus dependencias. Devuelve el tipo concreto, no
// una interfaz: el llamador decide qué parte le interesa.
func New(store Store, clock Clock, ids IDGenerator) *Service {
	return &Service{store: store, clock: clock, ids: ids}
}

// Create registra un trabajo nuevo. El identificador, la fecha y el estado
// inicial los pone el servicio: el llamador no puede inventárselos.
func (s *Service) Create(item workitem.WorkItem) (workitem.WorkItem, error) {
	item.ID = s.ids.NewID()
	item.CreatedAt = s.clock.Now()
	item.Status = workitem.StatusQueued

	if err := item.Validate(); err != nil {
		return workitem.WorkItem{}, err
	}
	if err := s.store.Save(item); err != nil {
		return workitem.WorkItem{}, err
	}
	return item, nil
}

// Start mueve un trabajo a running.
func (s *Service) Start(id string) (workitem.WorkItem, error) {
	item, err := s.store.FindByID(id)
	if err != nil {
		return workitem.WorkItem{}, err
	}
	if err := item.MarkRunning(s.clock.Now()); err != nil {
		return workitem.WorkItem{}, ErrConflict
	}
	if err := s.store.Update(item); err != nil {
		return workitem.WorkItem{}, err
	}
	return item, nil
}

// Complete marca un trabajo como terminado, con éxito o con fallo.
func (s *Service) Complete(id string, failureReason string) (workitem.WorkItem, error) {
	item, err := s.store.FindByID(id)
	if err != nil {
		return workitem.WorkItem{}, err
	}

	now := s.clock.Now()
	if failureReason == "" {
		err = item.MarkDone(now)
	} else {
		err = item.MarkFailed(now, failureReason)
	}
	if err != nil {
		return workitem.WorkItem{}, ErrConflict
	}

	if err := s.store.Update(item); err != nil {
		return workitem.WorkItem{}, err
	}
	return item, nil
}

// Queue devuelve los trabajos encolados, ordenados por prioridad efectiva
// descendente y, a igualdad, por antigüedad. Es lo que el motor de jobs de la
// Fase 06 va a consumir.
func (s *Service) Queue() ([]workitem.WorkItem, error) {
	items, err := s.store.ListByStatus(workitem.StatusQueued)
	if err != nil {
		return nil, err
	}

	now := s.clock.Now()
	sort.Slice(items, func(i, j int) bool {
		pi, pj := items[i].EffectivePriority(now), items[j].EffectivePriority(now)
		if pi != pj {
			return pi > pj
		}
		return items[i].CreatedAt.Before(items[j].CreatedAt)
	})
	return items, nil
}
```

Y las implementaciones triviales de `Clock` e `IDGenerator`, que van donde se
construyen —en `main`— porque son tres líneas cada una:

```go
// services/opsreport/cmd/opsreport/main.go (fragmento)

// systemClock es el reloj real. Un struct vacío: no tiene estado, y en Go un
// struct vacío no ocupa memoria.
type systemClock struct{}

func (systemClock) Now() time.Time { return time.Now().UTC() }

// sequentialIDs genera identificadores legibles para la fase. En la Fase 09
// lo sustituye un ULID de verdad.
type sequentialIDs struct{ n int }

func (g *sequentialIDs) NewID() string {
	g.n++
	return fmt.Sprintf("WI-%04d", g.n)
}
```

> 💡 Fíjate en `func (systemClock) Now()`: **el receptor puede no tener nombre** si
> el método no lo usa. Es un detalle, pero es idioma, y lo vas a ver en la stdlib.

### 6.6 OpsReport: el almacén que no conoce al servicio

```go
// services/opsreport/internal/memstore/store.go

// Package memstore guarda work items en memoria.
//
// Este paquete NO importa internal/opsreport. No sabe que existe una interfaz
// llamada Store ni le hace falta: satisface lo que satisface por tener los
// métodos, y eso es todo lo que Go necesita.
package memstore

import (
	"github.com/meridian/opsreport/internal/workitem"
)

// Store guarda work items en un mapa.
//
// NO es seguro para uso concurrente: dos goroutines escribiendo a la vez
// corrompen el mapa y el programa entra en panic. Es deliberado: el motor de
// jobs llega en la Fase 06 y allí se resuelve con un mutex, después de haber
// visto el problema.
type Store struct {
	items map[string]workitem.WorkItem
}

// New construye un almacén vacío y listo para usar.
// El mapa se crea aquí: un mapa nulo se lee pero no se escribe, y esa es la
// razón por la que un constructor no es opcional en este tipo.
func New() *Store {
	return &Store{items: make(map[string]workitem.WorkItem)}
}

// ErrNotFound lo devuelve este almacén cuando la clave no existe.
// Que el servicio tenga su propio ErrNotFound y el almacén el suyo es el
// problema que la Fase 03 resuelve con el envoltorio %w y errors.Is.  💸
var ErrNotFound = errors.New("work item no encontrado en el almacén")

func (s *Store) Save(item workitem.WorkItem) error {
	s.items[item.ID] = item
	return nil
}

func (s *Store) FindByID(id string) (workitem.WorkItem, error) {
	item, ok := s.items[id]
	if !ok {
		return workitem.WorkItem{}, ErrNotFound
	}
	return item, nil
}

func (s *Store) ListByStatus(status workitem.Status) ([]workitem.WorkItem, error) {
	// El slice se pre-dimensiona con la capacidad máxima conocida: es la lección
	// de B-04 aplicada donde toca.
	out := make([]workitem.WorkItem, 0, len(s.items))
	for _, item := range s.items {
		if item.Status == status {
			out = append(out, item)
		}
	}
	return out, nil
}

func (s *Store) Update(item workitem.WorkItem) error {
	if _, ok := s.items[item.ID]; !ok {
		return ErrNotFound
	}
	s.items[item.ID] = item
	return nil
}
```

> 🧪 **Prueba de fuego.** Verifica la dirección de las dependencias con el comando
> de §5:
> ```bash
> go1.13 list -f '{{.ImportPath}} → {{.Imports}}' ./internal/...
> ```
> `internal/memstore` importa `internal/workitem` y nada más. `internal/opsreport`
> importa `internal/workitem` y nada más. **Ninguno importa al otro.**
>
> **La mentira de la pantalla:** que compile no prueba que `*memstore.Store`
> satisfaga `opsreport.Store` — lo prueba el cableado de `main`, y si te equivocas
> en una firma, el error va a aparecer allí, lejos del archivo que lo causó. Por
> eso existe el idioma de la aserción; ponlo al final de `memstore/store.go`:
> ```go
> // Verificación en tiempo de compilación: si la firma se desalinea, el error
> // aparece aquí y no a doscientas líneas de distancia, en main.
> // (Requiere importar internal/opsreport SOLO para esta línea; si prefieres
> //  cero acoplamiento, ponla en un archivo _test.go del paquete, que es lo que
> //  haremos en la Fase 04.)
> ```

### 6.7 El cableado: una `main` que se lee entera

```go
// services/opsreport/cmd/opsreport/main.go
package main

import (
	"fmt"
	"os"
	"time"

	"github.com/meridian/opsreport/internal/memstore"
	"github.com/meridian/opsreport/internal/opsreport"
	"github.com/meridian/opsreport/internal/workitem"
)

type systemClock struct{}

func (systemClock) Now() time.Time { return time.Now().UTC() }

type sequentialIDs struct{ n int }

func (g *sequentialIDs) NewID() string {
	g.n++
	return fmt.Sprintf("WI-%04d", g.n)
}

func main() {
	// El grafo de dependencias completo del servicio, en cuatro líneas, leído de
	// arriba abajo. No hay contenedor, no hay escaneo de paquetes y no hay nada
	// que aparezca por magia.
	store := memstore.New()
	clock := systemClock{}
	ids := &sequentialIDs{}

	service := opsreport.New(store, clock, ids)

	created, err := service.Create(workitem.WorkItem{
		ExternalReference: "SAP-2026-000123",
		Kind:              workitem.KindReconciliation,
		Description:       "Conciliación de tiendas del norte",
		Priority:          3,
	})
	if err != nil {
		fmt.Fprintln(os.Stderr, "no se pudo crear:", err)
		os.Exit(1)
	}
	fmt.Println("creado:", created)

	started, err := service.Start(created.ID)
	if err != nil {
		fmt.Fprintln(os.Stderr, "no se pudo iniciar:", err)
		os.Exit(1)
	}
	fmt.Println("iniciado:", started)

	// Y ahora el intento ilegal: un trabajo ya terminado no se puede reiniciar.
	done, _ := service.Complete(started.ID, "")
	fmt.Println("terminado:", done)

	if _, err := service.Start(done.ID); err != nil {
		fmt.Println("rechazado como se esperaba:", err)
	}
}
```

```bash
go1.13 run ./cmd/opsreport
# creado: WI-0001[reconciliation/queued p3]
# iniciado: WI-0001[reconciliation/running p3]
# terminado: WI-0001[reconciliation/done p3]
# rechazado como se esperaba: el work item está en un estado que no lo permite
```

Cuarenta y ocho líneas, y puedes seguir cualquier llamada hasta el final sin
abrir un archivo de configuración. Ese es el intercambio que el curso está
comprando: más líneas escritas a cambio de cero magia que depurar.

### 6.8 EventRelay nace

El segundo servicio. Si OpsReport es el que un dev de Spring ya sabe hacer,
**EventRelay es el que Go hace notablemente mejor**: miles de entregas
concurrentes, cada una esperando E/S de red. Pero eso es la Fase 06; hoy solo nace
su dominio, y su máquina de estados es más rica que la de OpsReport.

```bash
mkdir -p services/eventrelay/internal/relay
cd services/eventrelay && go mod init github.com/meridian/eventrelay
# y edita go.mod para poner: go 1.13
```

```go
// services/eventrelay/internal/relay/endpoint.go

// Package relay contiene el dominio de EventRelay: los endpoints de los socios
// comerciales, los eventos publicados y las entregas con su ciclo de vida.
package relay

import (
	"errors"
	"net/url"
	"strings"
	"time"
)

// Endpoint es el destino de un socio comercial.
type Endpoint struct {
	ID           string
	PartnerName  string
	URL          string
	Secret       string   // se usa para firmar con HMAC; la firma llega en la Fase 10
	EventPattern []string // "order.*", "payment.approved"
	Active       bool
	CreatedAt    time.Time
}

var (
	ErrEmptyURL        = errors.New("la url del endpoint es obligatoria")
	ErrInsecureURL     = errors.New("la url del endpoint debe ser https")
	ErrEmptySecret     = errors.New("el secreto de firma es obligatorio")
	ErrNoEventPatterns = errors.New("el endpoint debe suscribirse a al menos un patrón")
)

// Validate comprueba que el endpoint se puede usar.
//
// La validación de URL es deliberadamente básica en esta fase. La validación real
// —contra SSRF, resolviendo la IP y rechazando rangos privados— entra en la
// Fase 14, y es un tema serio: un socio puede registrar
// http://169.254.169.254/latest/meta-data/ y usar tu servicio como proxy hacia
// los metadatos de tu propia nube.  💸
func (e Endpoint) Validate() error {
	if strings.TrimSpace(e.URL) == "" {
		return ErrEmptyURL
	}
	parsed, err := url.Parse(e.URL)
	if err != nil {
		return ErrEmptyURL
	}
	if parsed.Scheme != "https" {
		return ErrInsecureURL
	}
	if strings.TrimSpace(e.Secret) == "" {
		return ErrEmptySecret
	}
	if len(e.EventPattern) == 0 {
		return ErrNoEventPatterns
	}
	return nil
}

// Matches dice si este endpoint está suscrito al tipo de evento dado.
// El patrón admite un comodín final: "order.*" cubre "order.created".
func (e Endpoint) Matches(eventType string) bool {
	for _, pattern := range e.EventPattern {
		if pattern == eventType {
			return true
		}
		if strings.HasSuffix(pattern, ".*") &&
			strings.HasPrefix(eventType, strings.TrimSuffix(pattern, "*")) {
			return true
		}
	}
	return false
}
```

```go
// services/eventrelay/internal/relay/delivery.go
package relay

import (
	"errors"
	"time"
)

// Event es algo que pasó en la plataforma y que puede interesarle a un socio.
type Event struct {
	ID             string
	Type           string // order.created, payment.approved, shipment.dispatched
	Payload        []byte // el JSON tal cual lo publicó el productor
	IdempotencyKey string
	PublishedAt    time.Time
}

// DeliveryStatus es el estado de una entrega concreta a un endpoint concreto.
//
// La máquina de estados de EventRelay es más rica que la de OpsReport porque
// aquí hay reintentos: una entrega puede volver de failing a pending tantas
// veces como su política permita, y eso es un ciclo, no una línea recta.
type DeliveryStatus string

const (
	DeliveryPending   DeliveryStatus = "pending"    // esperando su turno
	DeliveryInFlight  DeliveryStatus = "in_flight"  // petición HTTP en curso
	DeliveryDelivered DeliveryStatus = "delivered"  // 2xx recibido
	DeliveryFailing   DeliveryStatus = "failing"    // falló, quedan intentos
	DeliveryDead      DeliveryStatus = "dead"       // agotó los intentos
	DeliveryCancelled DeliveryStatus = "cancelled"  // el endpoint se dio de baja
)

// Delivery es el intento de hacer llegar un evento a un endpoint.
type Delivery struct {
	ID          string
	EventID     string
	EndpointID  string
	Status      DeliveryStatus
	Attempts    int
	MaxAttempts int
	NextAttempt time.Time
	LastError   string
	CreatedAt   time.Time
	DeliveredAt time.Time
}

// DeliveryAttempt es el registro de UN intento. Se guardan todos: cuando un
// socio dice "nunca me llegó", esta tabla es la que responde.
type DeliveryAttempt struct {
	ID         string
	DeliveryID string
	Number     int
	StatusCode int
	LatencyMS  int64
	Error      string
	AttemptedAt time.Time
}

// deliveryTransitions es la máquina de estados. Fíjate en el ciclo:
// failing vuelve a pending, y ahí está toda la política de reintentos.
var deliveryTransitions = map[DeliveryStatus][]DeliveryStatus{
	DeliveryPending:  {DeliveryInFlight, DeliveryCancelled},
	DeliveryInFlight: {DeliveryDelivered, DeliveryFailing, DeliveryDead},
	DeliveryFailing:  {DeliveryPending, DeliveryDead, DeliveryCancelled},
}

var ErrInvalidDeliveryTransition = errors.New("transición de entrega no permitida")

func (d Delivery) CanTransitionTo(next DeliveryStatus) bool {
	for _, allowed := range deliveryTransitions[d.Status] {
		if allowed == next {
			return true
		}
	}
	return false
}

// RecordFailure registra un intento fallido y decide el siguiente estado:
// failing si quedan intentos, dead si se agotaron.
//
// El retroceso exponencial con jitter se escribe de verdad en la Fase 10; aquí
// el cálculo es lineal y está marcado como provisional.  💸
func (d *Delivery) RecordFailure(now time.Time, reason string) error {
	if !d.CanTransitionTo(DeliveryFailing) && !d.CanTransitionTo(DeliveryDead) {
		return ErrInvalidDeliveryTransition
	}

	d.Attempts++
	d.LastError = reason

	if d.Attempts >= d.MaxAttempts {
		d.Status = DeliveryDead
		return nil
	}

	d.Status = DeliveryFailing
	d.NextAttempt = now.Add(time.Duration(d.Attempts) * time.Minute)
	return nil
}

// RecordSuccess cierra la entrega.
func (d *Delivery) RecordSuccess(now time.Time) error {
	if !d.CanTransitionTo(DeliveryDelivered) {
		return ErrInvalidDeliveryTransition
	}
	d.Status = DeliveryDelivered
	d.DeliveredAt = now
	d.LastError = ""
	return nil
}

// Retry devuelve una entrega en failing a la cola.
func (d *Delivery) Retry() error {
	if !d.CanTransitionTo(DeliveryPending) {
		return ErrInvalidDeliveryTransition
	}
	d.Status = DeliveryPending
	return nil
}
```

> 💸 **Deudas declaradas en esta fase.** (1) El retroceso de reintentos es lineal
> y sin *jitter*; **se paga en la Fase 10**, donde se escribe exponencial con
> jitter y clasificación de errores recuperables. (2) La validación de URL no
> protege contra SSRF; **se paga en la Fase 14**. (3) `memstore` no es seguro para
> uso concurrente; **se paga en la Fase 06**. (4) La verificación sigue siendo por
> pantalla; **se paga en la Fase 04**.

---

## ⚰️ 7. Autopsia y errores comunes

### ⚰️ Autopsia: `WorkItemServiceImpl`

**El cadáver.** Esta es la versión Java-en-Go del servicio de OpsReport. La he
visto en producción, escrita por gente buena, y compila perfectamente.

```text
internal/workitem/
  work_item.go                  el struct, con getters y setters
  work_item_service.go          la interfaz de 9 métodos
  work_item_service_impl.go     la implementación
  work_item_service_factory.go  la fábrica
  work_item_repository.go       la interfaz del repositorio, 6 métodos
  work_item_repository_impl.go  la implementación en memoria
  work_item_dto.go              el DTO de entrada
  work_item_mapper.go           el mapeo DTO ⇄ dominio
```

```go
// work_item_service_impl.go (extracto representativo)
type WorkItemServiceImpl struct {
	repository WorkItemRepository
	mapper     *WorkItemMapper
	factory    *WorkItemFactory
}

func NewWorkItemServiceImpl(r WorkItemRepository, m *WorkItemMapper, f *WorkItemFactory) WorkItemService {
	return &WorkItemServiceImpl{repository: r, mapper: m, factory: f}
}

func (s *WorkItemServiceImpl) CreateWorkItem(dto *WorkItemDTO) (*WorkItemDTO, error) {
	entity := s.mapper.ToEntity(dto)
	entity.SetID(s.factory.GenerateID())
	entity.SetStatus(StatusQueued)
	if err := s.validator.Validate(entity); err != nil {
		return nil, err
	}
	saved, err := s.repository.Save(entity)
	if err != nil {
		return nil, err
	}
	return s.mapper.ToDTO(saved), nil
}
```

**El informe forense**, contando sobre el código real de este curso:

| Métrica | La versión ☕ | La versión de §6.5 | Diferencia |
|---|---|---|---|
| Archivos para el mismo caso de uso | 8 | 3 (`workitem.go`, `service.go`, `store.go`) | **−5** |
| Métodos en la interfaz del servicio | 9 | 0 (no hay interfaz; el consumidor declara 1–2) | **−9** |
| Métodos en la interfaz del almacén | 6 | 4, y cada uno se usa | **−2** |
| Tipos intermedios (DTO, mapper, factory, validator) | 4 | 0 | **−4** |
| Saltos para leer `Create` de punta a punta | 5 (iface → impl → mapper → factory → repo) | 2 (`Service.Create` → `Store.Save`) | **−3** |
| Conversiones DTO ⇄ dominio por petición | 2 | 0 | **−2** |

**Y el coste que no sale en la tabla y es el que duele:** para responder *"¿qué
pasa exactamente cuando se crea un work item?"*, en la versión ☕ hay que abrir
cinco archivos y mantener el estado mental de tres. En la versión de Go, `Create`
tiene doce líneas y se leen seguidas.

**La causa de la muerte.** Ninguna de las ocho piezas es absurda por sí sola. La
interfaz existe "para poder cambiar la implementación" —que nunca se cambió—; el
DTO existe "para no exponer el dominio" —aunque tiene exactamente los mismos
campos—; la fábrica existe "para centralizar la creación" —de un struct con
tres campos—; el mapper existe porque existe el DTO. **Cada pieza se justifica por
la anterior**, y la primera se justificó por un reflejo.

**Cuándo cada pieza sí vale la pena, para ser justos:**

- **El DTO** sí vale cuando el formato de la API y el dominio **divergen de
  verdad**: campos calculados, nombres distintos, versiones de la API. Eso pasa en
  la Fase 05 con `WorkItem` y su representación JSON, y allí el DTO aparece — con
  su justificación escrita.
- **La interfaz del almacén** sí vale: la hay, tiene cuatro métodos, y en la Fase
  09 va a tener una segunda implementación de verdad (PostgreSQL). Es abstracción
  real, no especulativa.
- **La fábrica de IDs** sí vale, y existe: se llama `IDGenerator`, tiene un método
  y es una dependencia inyectada. Lo que sobra no es la idea, es el envoltorio.

> ☕ **El patrón a memorizar.** Una abstracción se gana el sitio cuando tiene **dos
> implementaciones reales o una razón concreta de prueba**. Una interfaz con un
> solo implementador y sin doble de prueba no abstrae: transcribe.

### Errores comunes

**1. `cannot use X (type T) as type I: method has pointer receiver`.**
*Síntoma:* el tipo tiene el método, y el compilador dice que no.
*Causa:* declaraste el método con receptor `*T` y estás asignando un `T`.
*Fix mínimo:* `&X` en vez de `X`. Y revisa si el receptor debería ser por valor.

**2. El método promovido que no hace lo que esperas.**
*Síntoma:* un método del tipo incrustado llama a otro método del tipo incrustado
en vez de al tuyo.
*Causa:* no hay *dispatch* dinámico hacia el tipo externo; el embedding es
delegación.
*Fix mínimo:* pasa la dependencia como interfaz en vez de incrustar, o sobrescribe
el método completo en el tipo externo.

**3. La interfaz devuelta por el constructor.**
*Síntoma:* el llamador no puede usar un método que sabes que existe, y acaba
escribiendo `s.(*Service).OtroMetodo()`.
*Causa:* `func New(...) Store` en vez de `func New(...) *Store`.
*Fix mínimo:* **devuelve el tipo concreto.** La regla del ecosistema es *"acepta
interfaces, devuelve structs"*.

**4. El mapa nulo en un struct sin constructor.**
*Síntoma:* `panic: assignment to entry in nil map` la primera vez que se guarda.
*Causa:* alguien construyó `memstore.Store{}` en vez de `memstore.New()`.
*Fix mínimo:* si un tipo necesita construcción, **que su valor cero no sea
usable** y documéntalo; o mejor, haz que el valor cero sí funcione, que es lo que
hace la stdlib con `bytes.Buffer` y `sync.Mutex`.

**5. Tartamudeo en los nombres.**
*Síntoma:* `workitem.WorkItemService`, `relay.RelayDelivery`.
*Causa:* traducir el nombre de la clase de Java tal cual.
*Fix mínimo:* el paquete ya dice de qué habla. `relay.Delivery`, `opsreport.Service`.

### 🧨 Rompe a propósito

Demuestra en tu propia cara que el embedding no es herencia:

```go
// labs/shapes/embedding_break.go
package shapes

import "fmt"

type Job struct{ id string }

func (j Job) Name() string  { return "job-" + j.id }
func (j Job) Banner() string { return ">>> " + j.Name() + " <<<" }

type ReportJob struct {
	Job
	Format string
}

// "Sobrescribimos" Name. En Java esto sería @Override y Banner lo usaría.
func (r ReportJob) Name() string { return "report-" + r.id + "." + r.Format }

func Demo() {
	r := ReportJob{Job: Job{id: "42"}, Format: "csv"}
	fmt.Println(r.Name())    // report-42.csv     ← el tuyo
	fmt.Println(r.Banner())  // >>> job-42 <<<    ← NO el tuyo
}
```

Córrelo. Después piensa en cuántos patrones plantilla tienes escritos en tu código
Java actual y qué pasaría si los portaras literalmente. La respuesta correcta en
Go es pasar la pieza variable **como parámetro o como interfaz**, no incrustarla:

```go
type Namer interface{ Name() string }

// Banner deja de ser un método de Job y pasa a ser una función que recibe lo que
// necesita. Más simple, y funciona con cualquier tipo.
func Banner(n Namer) string { return ">>> " + n.Name() + " <<<" }
```

---

## 🧪 8. Ejercicios (26)

**🟢 Fácil (1–6)**

1. Añade `String()` a `Status`, `Kind` y `Delivery`. *Criterio:* `fmt.Printf("%v")`
   sobre una entrega imprime algo legible y no una volcada de campos.
2. Escribe la misma interfaz de dos formas —`type Reader interface { Read() }` en
   el paquete que implementa y en el que consume— y explica cuál prefiere este
   curso y por qué. *Criterio:* tres líneas, con la palabra "acoplamiento" usada
   correctamente.
3. Provoca el error `method has pointer receiver` y arréglalo. *Criterio:* pegas
   el mensaje exacto y explicas en una línea qué habría pasado si Go lo hubiera
   permitido.
4. Añade `var _ opsreport.Store = (*memstore.Store)(nil)` y rompe deliberadamente
   una firma de `memstore`. *Criterio:* el error aparece en `memstore` y no en
   `main`, y explicas por qué eso es mejor.
5. Convierte las funciones sueltas de la Fase 01 (`Validate`, `IsKnownKind`,
   `IsTerminal`) en métodos. *Criterio:* el paquete no exporta ninguna función
   suelta que debería ser método, y `go1.13 doc ./internal/workitem` se lee bien.
6. Usa `go1.13 list -f '{{.ImportPath}} → {{.Imports}}' ./internal/...` y pega la
   salida. *Criterio:* verificas que `memstore` no importa `opsreport` y explicas
   qué se rompería si lo hiciera.

**🟡 Intermedio (7–15)**

7. Implementa `FanOut` de `notifier` y añádele un modo "todos o nada": si uno
   falla, ninguno se considera enviado. *Criterio:* explicas por qué eso es
   imposible de garantizar de verdad con notificadores remotos, y qué ofreces en su
   lugar.
8. Escribe `NotifierFunc` y úsalo para pasar una función anónima donde se espera un
   `Notifier`. *Criterio:* localizas el mismo patrón en la stdlib de 1.13 con
   `go1.13 doc net/http HandlerFunc` y lo citas.
9. Implementa `store-registry` completo, incluido el caso "franquicia que no es
   punto de recogida". *Criterio:* añadir ese caso no obliga a tocar ningún tipo
   existente, y lo demuestras con el `git diff`.
10. Provoca el conflicto de nombres del embedding: dos tipos incrustados con el
    mismo método. *Criterio:* pegas el error de ambigüedad y lo resuelves de las
    dos formas posibles.
11. Diseña la interfaz mínima que necesitaría un hipotético "exportador de cola a
    CSV" sobre `opsreport.Service`. *Criterio:* tiene uno o dos métodos, se declara
    en el paquete del exportador, y explicas por qué no reutilizaste `Store`.
12. Convierte `memstore.Store` para que su **valor cero sea usable** (sin `New`),
    creando el mapa perezosamente. *Criterio:* funciona, y después explicas por qué
    este curso prefiere el constructor explícito aquí — y en qué casos la stdlib
    prefiere lo contrario.
13. Implementa `Endpoint.Matches` con patrones más ricos: comodín en el medio
    (`order.*.created`). *Criterio:* una tabla de al menos diez casos, ninguna
    expresión regular compilada dentro del bucle.
14. Añade a `Delivery` un método `NextBackoff(now time.Time) time.Duration` que por
    ahora sea lineal, con un `// TODO 💸 Fase 10` explicando qué falta.
    *Criterio:* el método es puro, recibe el reloj, y no lee `time.Now()`.
15. Mide B-05 con las tres variantes de `labs/shapes` y anota los resultados.
    *Criterio:* la conclusión que escribes menciona el *inlining* y la columna
    `allocs/op`, no solo los nanosegundos.

**🟠 Difícil (16–22)**

16. **Detección de ☕ (1).** Te dan este fragmento y lo reescribes:
    ```go
    type IDeliveryRepository interface {
        Save(d *Delivery) error
        FindById(id string) (*Delivery, error)
        FindAll() ([]*Delivery, error)
        FindByStatus(s string) ([]*Delivery, error)
        FindByEndpointId(id string) ([]*Delivery, error)
        Update(d *Delivery) error
        Delete(id string) error
        Count() (int64, error)
    }
    ```
    *Criterio:* justificas cada método que eliminas, señalas los tres problemas de
    nombrado, y dices qué pasaría si el consumidor solo necesitara `FindByStatus`.
17. **Detección de ☕ (2).** Un `AbstractDeliveryHandler` con método plantilla que
    se porta a Go con embedding. Reprodúcelo, demuestra el fallo silencioso, y
    reescríbelo con una interfaz. *Criterio:* muestras la salida de las dos
    versiones lado a lado.
18. **Detección de ☕ (3).** Un paquete `internal/common` con `StringUtils`,
    `DateUtils` y `ValidationUtils`. Repártelo. *Criterio:* cada función acaba en
    un paquete cuyo nombre dice de qué habla, o desaparece porque la stdlib ya lo
    tenía — y dices cuáles eran esas.
19. Implementa el motor de transiciones de `Delivery` como **datos verificables**:
    escribe un programa que recorra todos los pares de estados y produzca una
    tabla de transiciones permitidas. *Criterio:* la tabla impresa coincide con el
    diagrama de la máquina de estados, y detectas al menos un estado desde el que
    no se puede salir (y dices si es correcto).
20. Añade a `opsreport.Service` un método `Cancel(id string)` completo, con su
    transición y su error. *Criterio:* un trabajo en estado terminal no se puede
    cancelar, y el error que devuelve el servicio distingue "no existe" de "no se
    puede".
21. **Interfaces en el consumidor, aplicado.** Escribe un paquete
    `internal/digest` que produzca un resumen diario de la cola. *Criterio:*
    declara su propia interfaz de una sola operación, no importa `opsreport`, y
    `main` lo cablea en dos líneas.
22. **Línea de comandos.** Con `go1.13 doc` y `go1.13 list`, produce el inventario
    de todos los tipos exportados de `internal/...` con su primera línea de
    documentación. *Criterio:* lo haces sin escribir un parser; si alguna línea
    sale vacía, ese tipo está mal documentado y lo arreglas.

**🔴 Muy difícil (23–26)**

23. **La autopsia, en tu propio código.** Escribe la versión ☕ completa de
    `opsreport.Service` —con interfaz de nueve métodos, DTO, mapper y fábrica— y
    mídela contra la de §6.5. *Rúbrica:* (a) cuentas archivos, líneas, métodos de
    interfaz y saltos de lectura, con números reales de `wc -l`; (b) la versión ☕
    **funciona** y pasa las mismas comprobaciones, porque una autopsia sobre un
    cadáver mal hecho no vale; (c) identificas cuál de las cuatro piezas sí
    tendría sentido conservar y por qué; (d) escribes el veredicto en tres líneas
    que le dirías a un colega en una revisión de código, sin sonar condescendiente.
24. **El adaptador honesto.** Meridian tiene un sistema heredado que expone un
    `LegacyWorkItemFacade` con una interfaz de doce métodos que no controlas.
    Escribe el adaptador que lo conecta a `opsreport.Store`. *Rúbrica:* (a) la
    interfaz de doce métodos se queda encapsulada en un solo paquete; (b) tu
    adaptador expone exactamente cuatro métodos; (c) documentas qué operaciones de
    la fachada quedan sin usar y por qué está bien; (d) el paquete adaptador es el
    único que importa la fachada, y lo verificas con `go1.13 list -deps`.
25. **Composición sobre herencia, caso real.** Modela los tres regímenes de
    entrega de EventRelay: entrega simple, entrega con firma HMAC, y entrega con
    firma más compresión del cuerpo. *Rúbrica:* (a) sin jerarquía de tipos y sin
    un solo `if tipo == ...`; (b) añadir un cuarto régimen (cifrado del cuerpo) no
    toca ninguno de los tres; (c) la composición se hace en `main` y se lee de
    corrido; (d) comparas explícitamente con cómo lo harías con
    `AbstractDeliveryStrategy` en Java y dices qué pierdes.
26. **El diseño defendido.** Dado el requisito *"OpsReport tiene que poder
    notificar a un canal externo cuando un trabajo falla"*, diséñalo de dos formas
    —con una interfaz `Notifier` inyectada en el servicio, y con el servicio
    emitiendo eventos que otro componente consume— e implementa las dos. *Rúbrica:*
    (a) las dos funcionan; (b) cuentas líneas y dependencias de cada una; (c)
    recomiendas una **para esta fase** y dices en qué momento del curso la otra
    pasaría a ser mejor (pista: Fase 13, patrón outbox); (d) el argumento no
    menciona "mejores prácticas" ni una sola vez.

**🔥 Opcionales**

- Lee `net/http`'s `Handler`, `HandlerFunc` y `ServeMux` en tu `GOROOT` de 1.13.
  Son tres tipos y menos de cuatrocientas líneas, y contienen casi todas las
  decisiones de diseño de esta fase aplicadas por el equipo de Go. En la Fase 05
  lo vas a agradecer.
- Busca en la stdlib de 1.13 tres interfaces de **un solo método** y tres de dos.
  ¿Encuentras alguna de más de cuatro? (`sort.Interface` tiene tres;
  `net.Conn` tiene ocho y es la excepción que confirma la regla — investiga por qué
  se le permite.)

---

### 🔴 Desafíos de cierre

> Tres ejercicios de dificultad alta que **no cuentan en el total de la sección** y
> no son parte del recorrido base.

**D1 — El contenedor de inyección casero, y su autopsia.**
Escribe un contenedor de inyección de dependencias para Go —registro por tipo,
resolución recursiva con `reflect`, ciclo de vida singleton— y cablea OpsReport con
él.
*Rúbrica:* (a) **funciona de verdad**: el servicio arranca y los tests pasan; (b)
cuentas las líneas del contenedor y las que ahorra en `main`; (c) enumeras qué se
pierde: verificación en compilación, orden de construcción legible, mensajes de
error comprensibles cuando falta una dependencia; (d) provocas los tres fallos que
solo aparecen en tiempo de ejecución —dependencia no registrada, ciclo, tipo
ambiguo— y comparas sus mensajes con el error del compilador equivalente; (e)
escribes el veredicto. **Si tu conclusión es que el contenedor no compensa en Go,
acabas de entender por qué `wire` y `fx` existen y por qué este curso los deja
fuera.**

**D2 — La API pública, diseñada como si se publicara.**
Rediseña `internal/workitem` como si fuera un módulo que vas a publicar y mantener
durante cinco años.
*Rúbrica:* (a) decides qué exportar y qué no, con el criterio escrito; (b)
`go doc ./workitem` se lee de corrido y es suficiente para usar el paquete sin
abrir el código; (c) identificas qué decisiones te atarían —un campo exportado, un
tipo de retorno, una constante— y cuáles podrías cambiar sin romper a nadie; (d)
aplicas la regla de compatibilidad de Go 1 a tu propio paquete y dices qué cambio
concreto exigiría una `v2`.

**D3 — El detector de interfaces innecesarias.**
Escribe una herramienta con `go/ast` y `go/types` que encuentre, en cualquier
repositorio Go, las interfaces con **un solo implementador y ningún uso en tests**.
*Rúbrica:* (a) funciona sobre un repositorio ajeno de verdad, no solo sobre el
tuyo; (b) distingue el caso legítimo —una interfaz con un implementador **y** un
doble de prueba— del ☕; (c) reporta también las interfaces de más de cuatro métodos
y las declaradas en el mismo paquete que su única implementación; (d) la corres
sobre el código del curso y **explicas cada hallazgo**: corregido, justificado o
anotado.

---

## 📚 9. Referencias

### Documentación oficial

- **Effective Go** — https://go.dev/doc/effective_go — las secciones
  *Interfaces and other types*, *Embedding* y *Methods* son exactamente esta fase,
  escritas por el equipo que tomó las decisiones.
- **Especificación: Method sets** — https://go.dev/ref/spec#Method_sets — la
  regla formal de por qué `*T` implementa más que `T`. Media página y resuelve la
  duda para siempre.
- **Especificación: Struct types** — https://go.dev/ref/spec#Struct_types — la
  definición de embedding y la regla de resolución de nombres en conflicto.
- **Go Code Review Comments** — https://go.dev/wiki/CodeReviewComments — las
  entradas *Interfaces*, *Receiver Names*, *Receiver Type* y *Package Names* son
  normativas en este curso.
- **Google Go Style Guide** — https://google.github.io/styleguide/go/ — en
  particular *Style Decisions → Receiver names* y la sección sobre cuándo declarar
  una interfaz.
- **`sort`** — https://pkg.go.dev/sort — `sort.Interface` es el ejemplo canónico de
  interfaz pequeña bien diseñada; míralo antes de diseñar la tuya.
- **`fmt`** — https://pkg.go.dev/fmt — `Stringer`, `Formatter` y los verbos. La
  sección de verbos es la que más vas a volver a mirar.

### Libros

- **The Go Programming Language** — Donovan y Kernighan, capítulos 6 (*Methods*) y
  7 (*Interfaces*). El capítulo 7 es, en mi opinión, el mejor texto que existe
  sobre interfaces en cualquier lenguaje; la sección sobre `sort.Interface` y la de
  `error` valen la compra del libro.
- **Learning Go** — Jon Bodner, capítulo *Types, Methods and Interfaces*. Trata
  explícitamente el "acepta interfaces, devuelve structs" y la trampa de la
  interfaz nula, que vemos en la Fase 03.
- **100 Go Mistakes** — Harsanyi. Los errores #5 (*interface pollution*), #6
  (*interfaces on the producer side*) y #7 (*returning interfaces*) son literalmente
  la autopsia de §7.

### Artículos y charlas

- **Go Proverbs** — Rob Pike, https://go-proverbs.github.io/ — *"The bigger the
  interface, the weaker the abstraction"* y *"Don't design with interfaces,
  discover them"* son los dos ejes de esta fase, en ocho palabras cada uno.
- **Accept interfaces, return structs** — busca el artículo de Jack Lindamood con
  ese título; es la discusión más matizada del principio, **incluidas sus
  excepciones**, que también existen.
- **Preemptive Interface Anti-Pattern in Go** — Burcu Doğan,
  https://rakyll.org/interface-pollution/ — corto y directo al ☕ de esta fase.
- **Embedding in Go** — Eli Bendersky, https://eli.thegreenplace.net/2020/embedding-in-go-part-1-structs-in-structs/
  — serie de tres partes; la primera cubre exactamente el fallo del método
  promovido.
- **Codebase Refactoring (with help from Go)** — Russ Cox, https://go.dev/talks/2016/refactor.article
  — sobre cómo evolucionan las APIs en Go, y por qué los structs concretos
  envejecen mejor que las interfaces especulativas.

### Video

- **Go Proverbs** — Rob Pike, GopherFest 2015. Veinte minutos, y explica el
  porqué de la mitad de las reglas de esta fase.
- **Golang UK Conference: Understanding nil** — Francesc Campoy. Toca la interfaz
  nula, que es la trampa de la Fase 03; míralo ahora para llegar preparado.
- **GopherCon: Best Practices for Industrial Programming** — Peter Bourgon. La
  parte sobre cableado en `main` y dependencias explícitas es exactamente §6.7.

> ⚠️ Casi todo este material es anterior a los genéricos, y para esta fase **eso
> no importa**: el modelo de interfaces no ha cambiado. Lo que sí conviene saber
> es que algunos consejos sobre `interface{}` han quedado matizados por los
> genéricos — y eso lo tratamos en la Fase 08.

### Orden de lectura sugerido

**Antes de escribir código:** los *Go Proverbs* (cinco minutos) y la sección
*Interfaces* de *Go Code Review Comments* (diez minutos). Con eso ya no escribes
`IWorkItemService`.
**Durante:** *Effective Go*, sección *Embedding*, cuando llegues a
`store-registry`; y la de *Method sets* de la especificación cuando el compilador
te diga *"pointer receiver"*.
**Después:** el capítulo 7 de Donovan y Kernighan entero, y el artículo de
rakyll.org. Los dos se leen en una tarde y consolidan toda la fase.

---

## ⚖️ 10. Veredicto y cierre

### ⚖️ Cuándo NO usar esto

Las interfaces implícitas y el cableado manual ganan mucho, y pierden en sitios
concretos que conviene tener presentes:

- **Cuando necesitas saber quién implementa una interfaz, Go te deja peor que
  Java.** En IntelliJ, `Ctrl+Alt+B` sobre una interfaz te lista las
  implementaciones porque el `implements` está escrito. En Go hay que buscar por
  conjunto de métodos: `gopls` lo hace bien, pero es una búsqueda, no una lectura.
  En una base de código grande y desconocida, esa diferencia se nota.
- **Cuando el grafo de dependencias es realmente grande**, el cableado a mano
  cansa. Una aplicación con setenta componentes y tres perfiles de configuración
  produce una `main` que ya no se lee de corrido, y ahí `wire` o `fx` empiezan a
  tener argumento. Este curso los deja explícitamente fuera de alcance, y el
  motivo es pedagógico, no técnico: si empiezas con un contenedor, nunca ves qué
  te estaba dando.
- **Cuando la variación de comportamiento es realmente jerárquica** —una taxonomía
  con veinte tipos que comparten el 80% del comportamiento—, la composición te
  obliga a repetir. El embedding ayuda, pero sin *dispatch* dinámico hacia arriba
  cada "override" cuesta un método completo. Java gana ahí, y no poco.
- **Cuando quieres imponer un contrato arquitectónico**, no hay ArchUnit. El
  `internal/` del compilador es fuerte pero grueso: impide importar desde fuera del
  módulo, no impide que `httpapi` importe `postgres` directamente. Se resuelve con
  revisión de código y con un linter propio, y eso es más artesanal.
- **Y si tu equipo usa Lombok intensivamente**, prepárate: en Go no hay generación
  de getters, `equals`, `hashCode` ni `builder`. Parte de eso no hace falta (los
  campos públicos son públicos); parte se escribe a mano. Un *builder* de verdad
  son treinta líneas.

### 📖 Diccionario Java ⇄ Go de esta fase

| Java / Spring | Go | Dónde se rompe la equivalencia |
|---|---|---|
| `class` con campos y métodos | `struct` + métodos con receptor | Los métodos viven en el paquete, no dentro del tipo; se pueden declarar en cualquier archivo del paquete |
| `this` | el receptor, con nombre elegido (`w`, `s`) | Nunca `this` ni `self`; una o dos letras, consistentes en todo el tipo |
| `extends` | *(no existe)* — embedding | El embedding **delega**, no hereda: no hay *dispatch* dinámico hacia el tipo externo. Un método plantilla en el padre llama al método del padre |
| `implements` | *(implícito)* | No se declara. `var _ I = (*T)(nil)` es la verificación opcional, y se pone en quien implementa |
| `abstract class` | interfaz pequeña + struct concreto | No hay clase base con estado y comportamiento parcial. Lo que compartían pasa a ser un tipo incrustado o una función |
| `@Override` | *(no existe)* | Nada verifica que "sobrescribes" un método promovido; si te equivocas en la firma, tienes dos métodos distintos y ningún aviso |
| `super.method()` | `t.Embedded.Method()` | Explícito y calificado. No hay cadena automática hacia arriba |
| `interface` con muchos métodos | interfaz de 1–3 métodos | Se declara **en el consumidor**, no junto a la implementación. Una interfaz grande es la señal de un struct disfrazado |
| `Object` | `interface{}` | Pierdes toda ayuda del compilador. Legítimo en `fmt` y `encoding/json`; sospechoso en el resto. `any` es su alias desde 1.18 🕰️ |
| `instanceof` | aserción de tipo `v, ok := x.(T)` | La forma de un valor entra en panic; usa **siempre** la de dos valores. El `type switch` es la versión legible |
| `record` (Java 16) | `struct` con campos exportados | Sin `equals`/`hashCode`/`toString` generados. `==` funciona si todos los campos son comparables |
| `sealed` (Java 17) | *(no existe)* | No hay jerarquías cerradas ni exhaustividad comprobada. Se suple con un tipo no exportado dentro de la interfaz, y es artesanal |
| `toString()` | `String() string` (`fmt.Stringer`) | `fmt` lo usa automáticamente. Cuidado con la recursión si formateas el receptor entero |
| Lombok `@Getter`/`@Setter` | *(innecesario)* | Un campo exportado ya es accesible. Escribir getters sobre campos públicos es ☕ puro |
| Lombok `@Builder` | función `New...` con parámetros, o struct literal con nombres | El literal con nombres de campo (`WorkItem{Priority: 3}`) cubre el 90% de los casos del builder |
| `@Service` / `@Component` | *(nada)* | El tipo existe porque alguien lo construye en `main`. No hay escaneo de paquetes |
| `@Autowired` | parámetro del constructor | Explícito y verificado en compilación. No hay inyección por campo ni por reflexión |
| `@Qualifier` | *(innecesario)* | Si hay dos implementaciones, pasas la que quieras. El "cuál de las dos" lo decide la línea de `main` que lo escribe |
| `ApplicationContext` | la función `main` | El grafo completo cabe en un archivo y se lee de arriba abajo. Sin *lazy loading* y sin sorpresas en tiempo de ejecución |
| `@Configuration` con perfiles | un `if` o un `switch` en `main` sobre la configuración | Más verboso; a cambio, el flujo es rastreable sin conocer el orden de resolución del contenedor |
| Clase interna / anónima | closure, o tipo función con método (`NotifierFunc`) | Más ligero: no hace falta un tipo para adaptar una función a una interfaz |
| Fábrica (`XFactory`) | función `New` del paquete | Un tipo dedicado a construir otro tipo casi nunca se justifica |

### Qué sigue

La Fase 03 se ocupa de lo que hasta ahora hemos estado despachando con
`return err`: **los errores como valores**. Centinelas, tipos de error, el
envoltorio con `%w` —que es *la* novedad de Go 1.13—, `errors.Is` y `errors.As`, y
el momento incómodo de decir con todas las letras dónde Java gana: las excepciones
comprobadas te obligan a decidir, y el `_` de Go te deja ignorar un error en
silencio.

Y con ellos, `defer` en serio —incluido el que dentro de un bucle agota
descriptores—, los paquetes y `internal/`, `io.Reader`/`io.Writer` como las dos
interfaces más importantes del ecosistema, y `encoding/json` con todas sus
trampas. OpsReport y EventRelay estrenan política de errores y configuración.

### La señal de que quedó bien

> *"Abro un paquete nuevo y lo primero que escribo es el struct concreto. La
> interfaz la escribe el que me llame, cuando sepa qué necesita — y casi siempre
> resulta que necesita menos de lo que yo iba a exponerle."*

Si todavía empiezas por la interfaz, vuelve a §6.5 y cuenta: `opsreport.Service`
tiene cinco métodos públicos y **cero interfaces propias**. Las tres que declara
son de lo que *consume*, no de lo que *es*.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en
> verde, `go1.13 vet ./...` y `gofmt -l .` limpios y `git status` sin cambios
> pendientes:
>
> ```bash
> git tag -a fase-02 -m "F2 cerrada: workitem con métodos y máquina de estados; opsreport.Service con Store, Clock e IDGenerator declaradas en el consumidor; memstore sin conocer al servicio; eventrelay nace con Endpoint, Event y Delivery; shapes, store-registry y notifier; B-05 medido"
> git tag -a opsreport/v0.2 -m "OpsReport: dominio con estados, servicio y almacén en memoria"
> git tag -a eventrelay/v0.1 -m "EventRelay: dominio de endpoints, eventos y entregas"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 02: …`) y los de ejercicio su
> número (`fase 02 ej23: …`). Los tags por proyecto permiten leer la evolución de
> un servicio sin el ruido de los otros tres. Todo eso está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).

---

# 📌 Bloque de autoría (fuera de lo que lee el estudiante)

## 📌 Pendientes sugeridos

- **La interfaz nula (`nil` dentro de una interfaz no nula)** — mencionada de
  refilón en la referencia al vídeo de Campoy. Su sitio natural es la **Fase 03**,
  junto al `error` que "no es nil" y rompe un `if err != nil`. Verificar que allí
  se escribe.
- **El *builder* a mano** — nombrado en el ⚖️ veredicto. Si alguna fase lo
  necesita de verdad, es la **Fase 14** (configuración con muchas opciones), donde
  además se puede comparar con el patrón *functional options*, que este curso
  todavía no ha introducido. **Candidato firme a sección de la Fase 14.**
- **`wire` / `fx`** — están fuera de alcance por decisión cerrada. Se nombran en
  el ⚖️ de esta fase y **no deben reaparecer** salvo en el veredicto de la Fase 16.
- **SSRF en la validación de URL de EventRelay** — deuda 💸 declarada aquí, se paga
  en la **Fase 14**. Está en el alcance de esa fase; verificado.
- **Lint propio para reglas de arquitectura** (impedir que `httpapi` importe
  `postgres`) — mencionado en el ⚖️. Candidato a **ejercicio 🔥 de la Fase 14**.

## ☕ Reflejos para `INSTINTOS.md`

- **"Interfaz primero, implementación después"** — el reflejo raíz de la fase.
  Coste medido en la autopsia: 5 archivos, 9 métodos de interfaz y 3 saltos de
  lectura extra por caso de uso. Antídoto: struct concreto primero; la interfaz la
  declara el consumidor.
- **"`XServiceImpl` y `IX`"** — nombres que en Go no significan nada.
- **"Devolver la interfaz desde el constructor"** — acepta interfaces, devuelve
  structs.
- **"Embedding es `extends`"** — el método plantilla que devuelve cero. Coste: un
  bug silencioso que ningún test de la clase base detecta.
- **"DTO + mapper por reflejo"** — el DTO se gana el sitio cuando el formato
  externo diverge del dominio; con los mismos campos, es transcripción.
- **"Un paquete `common`/`utils`"** — la señal de que un tipo todavía no encontró
  su sitio.

## 📐 Mediciones para `BENCHMARKS.md`

- **B-05 — Coste de una llamada a través de interfaz frente a llamada directa.**
  Tres variantes en `labs/shapes`: directa, por interfaz, y sobre un slice de
  interfaces. El veredicto está pre-escrito en §6.1 y hay que sostenerlo con los
  números: **el coste está en el *inlining* perdido y en las asignaciones, no en
  el salto indirecto**, y no es motivo para evitar interfaces.
- Anotado para la Fase 15: el tercer benchmark (`BenchmarkInterfaceSlice`) es el
  ejemplo natural para el escape analysis con `-gcflags=-m`.
