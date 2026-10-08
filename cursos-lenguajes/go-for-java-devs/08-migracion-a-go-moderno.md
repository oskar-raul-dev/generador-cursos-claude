# 🚀 Fase 08 — La migración a Go moderno ⭐

> Go para desarrolladores Java senior · Fase 8 de 17 · **8 horas**
> Época: **la frontera** — entra en Go 1.13 y sale en Go 1.25
> Depende de: Fase 07 · Habilita: Fase 09
> Proyectos que avanzan: **OpsReport** y **EventRelay** migran, sin reescribirse
> Mini proyectos: ninguno nuevo; `tiny-router` muere aquí con dignidad

---

## 🎯 1. Propósito

Tienes dos servicios completos escritos en Go 1.13 con stdlib pura: dominio,
errores, tests, API REST, concurrencia acotada y ciclo de vida. Hoy los llevas a
Go moderno **sin reescribirlos**, salto por salto, con la suite de tests como red.

Esta es la fase bisagra del curso, y migrar a mitad y no al final tiene su razón:
a partir de aquí, más de la mitad del material transcurre en el Go que de verdad
vas a escribir. Y la migración misma es rica porque migras dos servicios con
persistencia en memoria, concurrencia real y tests completos, no un puñado de
ejemplos de veinte líneas.

El entregable que diferencia esta fase de un tutorial de novedades no es la lista
de lo que adoptas. Es **la lista de lo que rechazas, con su motivo.**

> 🧭 **La regla que se lleva.** Modernizar no es sustituir cada API vieja por la
> nueva. Es preguntarse, una por una, **si el cambio hace el código más simple de
> mantener**. Las que no, se quedan como están. Un repositorio migrado por reflejo
> es tan malo como uno estancado, con el agravante de que el `git blame` ya no
> sirve para nada.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Los dos `go.mod` dicen `go 1.25` y hay una directiva `toolchain`; el
      comando del curso vuelve a ser `go`, no `go1.13`.
- [ ] `go.work` existe en la raíz del monorepo y `go build ./...` funciona desde
      allí, con los módulos referenciándose entre sí sin `replace`.
- [ ] Las plantillas HTML del reporte y las migraciones SQL están incrustadas con
      `embed`; el binario ya no depende de archivos sueltos.
- [ ] `log/slog` sustituye al logger propio, y has comparado las dos salidas.
- [ ] El `ServeMux` de la stdlib sustituye a `tiny-router`, que queda archivado
      con su comparación escrita.
- [ ] Hay al menos una función genérica en cada servicio, y **tienes escrito por
      qué no hay más**.
- [ ] El parser de movimientos y el verificador de firmas tienen fuzzing con
      `testing.F`, y el corpus está en `testdata/fuzz/`.
- [ ] `docs/rechazos.md` existe: lo que se evaluó y se descartó, con su motivo.
- [ ] `go test -race ./...` en verde, misma cobertura o mejor, y **ningún test
      cambiado salvo los que prueban lo que cambió a propósito**.

---

## 🚫 3. Qué NO entra todavía

- Persistencia real → Fase 09. Los dos servicios siguen en memoria; migramos el
  lenguaje, no la arquitectura, y mezclar las dos cosas es cómo se hacen las
  migraciones que nadie puede revisar.
- Librerías del ecosistema más allá de `golang.org/x/sync` → Fase 09 en adelante,
  cada una con su justificación.
- `log/slog` con salida estructurada en producción, correlación y niveles por
  entorno → Fase 14. Hoy lo introducimos y comparamos; la política de observabilidad
  es de allí.
- `go tool` con dependencias de herramientas en el `go.mod` (Go 1.24) → se evalúa
  en §6.6 y se decide.
- Reescribir la arquitectura "ya que estamos" → **nunca**. Ver §7.

---

## 🧠 4. Concepto mínimo

### Cómo se migra: la disciplina antes que las novedades

Antes de tocar una línea, tres reglas que hacen esta migración revisable:

**1. La suite de tests es la red, y no se toca.** Si un test hay que cambiarlo,
es porque el comportamiento cambió a propósito — y entonces el cambio del test es
la parte más importante del commit. Un PR de migración donde los tests cambian
"para adaptarse" es un PR donde nadie sabe si algo se rompió.

**2. Un salto de versión por commit.** No un commit por archivo ni un commit con
todo. El historial tiene que permitir leer la migración como una secuencia de
decisiones.

**3. Cada adopción se justifica en una frase, y cada rechazo también.** Esa frase
va en el mensaje del commit, y al final se agregan en `docs/rechazos.md`.

```bash
# El primer paso, y es solo este:
cd services/opsreport
# editar go.mod: go 1.13 → go 1.25
go mod tidy
go build ./...
go test -race ./...
```

Y ahora la parte que sorprende: **casi todo compila y pasa.** Go tiene una promesa
de compatibilidad (https://go.dev/doc/go1compat) que se ha sostenido desde 2012:
un programa válido en Go 1.x sigue siendo válido en Go 1.y. Trece versiones de
diferencia y el código de la Fase 07 funciona tal cual.

**Esa es la primera lección de la fase, y conviene decirla antes que las
novedades:** en Go, "migrar de versión" y "adoptar las novedades de la versión" son
dos operaciones distintas. La primera es gratis. La segunda es trabajo y hay que
justificarla.

📖 En Java el paralelo más cercano es subir el `<release>` del compilador sin
tocar código. Y la diferencia real: Java ha tenido rupturas de verdad —el módulo
`javax` → `jakarta`, la eliminación de `sun.misc.Unsafe`, los internos cerrados en
Java 9— que obligaron a cambiar código. **Go no ha tenido ninguna de ese calibre**,
y eso es una ventaja genuina que conviene reconocer.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El instinto:** *"aprovechamos la migración para arreglar lo que quedó mal"*. Es
el reflejo más humano que hay y en Java está casi institucionalizado: subes de
Spring Boot 2 a 3, y ya que tocas cada archivo, cambias los `javax` por `jakarta`,
actualizas Hibernate, reorganizas paquetes y de paso arreglas ese `Service` que
nunca te gustó.

**Qué pasa si lo aplicas aquí.** El PR tiene 340 archivos cambiados. Nadie lo
revisa de verdad. Cuando algo se rompe tres semanas después, `git bisect` te lleva
a un commit de 12.000 líneas titulado *"migración a Go moderno"* y no sirve de
nada. Y lo peor: **no sabes si lo que se rompió fue la migración o el refactor**,
porque van juntos.

**Qué pensar en su lugar:** la migración cambia **una** variable. Si al migrar ves
algo que quieres arreglar —y vas a ver mucho—, se anota y se arregla **después**,
en su propio PR, con la suite ya en verde sobre la versión nueva.

> 🧭 **Regla del proyecto.** Migrar y refactorizar son dos operaciones y van en dos
> commits distintos. La única excepción es cuando la API nueva **es** el refactor:
> sustituir tu `tiny-router` por el `ServeMux` de 1.22 borra código y no lo mueve,
> y eso es adoptar, no refactorizar.

### 🩻 Esto sí funciona igual

- **Leer las notas de versión antes de migrar** es la misma disciplina que
  aplicas con Spring Boot o con el JDK. Aquí el documento se llama igual
  (https://go.dev/doc/devel/release) y se lee igual.
- **La suite de tests como red** es el mismo principio, y es la razón por la que la
  Fase 04 llegaba tan pronto.
- **Fijar la versión en el proyecto** es `<release>17</release>` y es `go 1.25`.
  Mismo propósito: que el compilador te impida usar lo que no toca.
- **El escepticismo ante lo nuevo** se traslada intacto. El primer equipo que puso
  *records* en todos sus DTOs sin pensar también se arrepintió de algunos.
- **Y la lista de rechazos** es exactamente lo que un buen ADR (*architecture
  decision record*) contiene. La práctica es la misma; aquí le ponemos nombre.

---

## 🛠️ 5. CLI de la fase

```bash
# A partir de hoy, el comando vuelve a ser `go`. Guarda go1.13 por si quieres
# volver a compilar el Bloque A para comparar (y en el ejercicio 24 lo harás).
go version
go1.13 version

# La directiva toolchain (Go 1.21+) hace que el módulo EXIJA una versión mínima
# del toolchain, no solo del lenguaje, y que Go se la descargue si no la tiene.
# Es lo más parecido a un `mvnw` que existe.
go get go@1.25.1
cat go.mod

# go.work: el workspace. Permite que varios módulos del monorepo se vean entre sí
# sin `replace` en cada go.mod, que era el parche de la época anterior.
go work init ./services/opsreport ./services/eventrelay
go work use ./labs/text-toolkit
go work edit -json          # ver el workspace resuelto
cat go.work

# Qué versión del lenguaje entiende cada módulo del workspace.
go list -m -f '{{.Path}} {{.GoVersion}}' all

# gopls tiene un modernizador: sugiere sustituciones seguras de API vieja por
# nueva. NO lo apliques a ciegas: úsalo para descubrir candidatos y decide tú.
go run golang.org/x/tools/gopls/internal/analysis/modernize/cmd/modernize@latest ./...

# El vet moderno trae analizadores que en 1.13 no existían, como el de los
# bucles y el de `loopclosure` actualizado.
go vet ./...

# FUZZING (Go 1.18+). -fuzz corre indefinidamente hasta encontrar un fallo;
# -fuzztime lo acota, que es lo que se pone en CI.
go test -run '^$' -fuzz FuzzParseMovement ./labs/movement-parser
go test -run '^$' -fuzz FuzzParseMovement -fuzztime 30s ./labs/movement-parser

# El corpus que el fuzzer descubre se guarda en testdata/fuzz/ y SE COMMITEA:
# es una regresión permanente.
ls services/clearinghouse/testdata/fuzz/FuzzParseMovement/

# -shuffle (Go 1.17): ejecuta los tests en orden aleatorio. Detecta la
# dependencia entre tests que en el Bloque A era indetectable.
go test -shuffle=on ./...
go test -shuffle=1699887654 ./...   # reproducir un orden concreto

# t.Setenv y los tests con entorno ya no necesitan limpieza manual (Go 1.17).

# El analizador de la variable de bucle, para el salto 1.22. Con GOEXPERIMENT se
# podía probar antes de que fuera el comportamiento por defecto.
go build -gcflags=all=-d=loopvar=2 ./...   # informa de cada bucle afectado

# Comparar el binario de las dos épocas (B-11).
go1.13 build -ldflags "-s -w" -o bin/opsreport-113 ./cmd/opsreport
go     build -ldflags "-s -w" -o bin/opsreport-125 ./cmd/opsreport
ls -lh bin/opsreport-*

# Y el comando que más vale de toda la fase: leer la migración como un diff.
git diff bloque-a-completo fase-08 -- services/opsreport/internal/httpapi/
git diff bloque-a-completo fase-08 --stat
```

> 💡 **`go test -shuffle=on` es el regalo escondido de esta migración.** En el
> Bloque A, un test que dependía del orden pasaba siempre y nadie lo sabía.
> Actívalo ya sobre la suite completa: si algo falla, acabas de encontrar un bug
> real que llevaba siete fases escondido.

---

## 💻 6. Construcción guiada

Los saltos, en orden. Cada uno es un commit.

### 6.1 Salto 1.14–1.16: E/S, `embed` y el fin de `GOPATH`

**Lo que llegó y nos sirve:**

```go
// ANTES (1.13) — ioutil, que hoy está obsoleto por completo
data, err := ioutil.ReadFile(path)
err = ioutil.WriteFile(path, data, 0o644)
all, err := ioutil.ReadAll(r)
tmp, err := ioutil.TempFile("", "report-*.csv")

// DESPUÉS (1.16) — todo volvió a os y a io, donde debía estar
data, err := os.ReadFile(path)
err = os.WriteFile(path, data, 0o644)
all, err := io.ReadAll(r)
tmp, err := os.CreateTemp("", "report-*.csv")
```

Es una sustitución mecánica y segura: las funciones son idénticas, solo cambiaron
de casa. `ioutil` sigue funcionando —compatibilidad— pero está marcado como
obsoleto y `staticcheck` lo señala.

**Y la adopción que de verdad cambia algo: `embed`.**

En la Fase 05, OpsReport generaba su reporte HTML con una plantilla que vivía en
un archivo suelto. Eso significaba que el binario **no era autosuficiente**: había
que copiar `templates/` al lado, y si faltaba, el servicio arrancaba y fallaba en
la primera petición de reporte.

```go
// ANTES (1.13)
func loadTemplates(dir string) (*template.Template, error) {
	// Las plantillas se leen del disco al arrancar. Si el directorio no está
	// donde esperamos, nos enteramos aquí — o peor, en la primera petición.
	return template.ParseGlob(filepath.Join(dir, "*.html"))
}
```

```go
// DESPUÉS (1.16)
package report

import (
	"embed"
	"html/template"
)

// El comentario //go:embed NO es un comentario: es una directiva del compilador.
// Tiene que ir pegado a la declaración, sin línea en blanco en medio, o se
// ignora en silencio — que es el error número uno con embed.
//
//go:embed templates/*.html
var templateFS embed.FS

// templates se parsea UNA VEZ, al cargar el paquete. Si una plantilla está mal
// escrita, el programa no arranca: template.Must entra en panic, y eso es
// exactamente lo que queremos para un invariante de compilación.
var templates = template.Must(template.ParseFS(templateFS, "templates/*.html"))

func RenderHTML(w io.Writer, data ReportData) error {
	return templates.ExecuteTemplate(w, "monthly.html", data)
}
```

Lo que ganas: **un binario y nada más**. Se copia, se ejecuta, funciona. Es la
misma propiedad que hacía atractiva la compilación cruzada de la Fase 00, y ahora
alcanza a los recursos.

📖 En Java el paralelo es empaquetar recursos en el JAR y leerlos con
`getResourceAsStream`. Mismo objetivo; la diferencia es que `embed` **falla en
tiempo de compilación** si el archivo no existe, mientras que
`getResourceAsStream` devuelve `null` en tiempo de ejecución y produce un
`NullPointerException` a las tres de la mañana.

> ⚠️ **Tres trampas de `embed` que hay que saber antes de usarlo.**
> 1. Solo funciona con archivos **dentro del directorio del paquete o por debajo**.
>    No se puede incrustar `../../config`.
> 2. Ignora archivos que empiecen por `.` o `_` salvo que uses `all:`.
> 3. Los archivos incrustados **no se pueden cambiar sin recompilar**, que es el
>    punto. Si la plantilla la edita el equipo de negocio, `embed` es la
>    herramienta equivocada.

**Y lo que decidimos NO adoptar en este salto:**

- **`io/fs` como abstracción del sistema de archivos.** Es una buena interfaz y
  Meridian no la necesita: ningún servicio tiene que trabajar indistintamente con
  disco, un ZIP y un `embed.FS`. Adoptarla añadiría una capa que solo tiene una
  implementación — que es el ☕ de la Fase 02 con otro nombre. **Rechazado, motivo
  documentado.**
- **La interrupción asíncrona del planificador (1.14)** no requiere nada nuestro:
  funciona sola y mejora el comportamiento ante bucles apretados. Se anota como
  contexto, no como adopción.

### 6.2 Salto 1.17–1.18: `go.work`, genéricos y fuzzing

**`go.work` primero, porque arregla una molestia real.** Hasta ahora, los cuatro
módulos del monorepo no se veían entre sí: si `opsreport` quisiera usar un paquete
de `labs/text-toolkit`, haría falta un `replace` en el `go.mod` — y un `replace`
que nunca debe llegar a producción.

```bash
cd ~/dev/meridian
go work init ./services/opsreport ./services/eventrelay
go work use ./labs/text-toolkit
```

```text
# go.work
go 1.25

use (
	./services/opsreport
	./services/eventrelay
	./labs/text-toolkit
)
```

```gitignore
# .gitignore
go.work.sum
```

> 🧭 **Decisión del curso: `go.work` SÍ se commitea, `go.work.sum` no.** La
> documentación oficial recomienda no commitear `go.work` en general, porque en un
> repositorio de librerías impone tu configuración local a todo el mundo. **En un
> monorepo de aplicaciones es al revés**: quieres que todos trabajen con el mismo
> workspace, y que un clon recién hecho compile sin pasos manuales. Es una
> divergencia consciente de la recomendación oficial, y así se documenta.

📖 Es el equivalente funcional del `<modules>` del POM padre de Maven, y más
ligero: no hay POM padre, no hay herencia de configuración, solo una lista de
directorios.

---

**Y ahora los genéricos, que es donde esta fase se gana el sueldo.**

Los genéricos llegaron en 1.18 y son la novedad más grande de la historia de Go.
También son el sitio donde más fácil es escribir `AbstractBaseService<T>` con
sintaxis moderna.

```go
// La sintaxis, en tres líneas.
func Map[T, U any](in []T, f func(T) U) []U {
	out := make([]U, 0, len(in))
	for _, v := range in {
		out = append(out, f(v))
	}
	return out
}
```

**Dónde el curso SÍ los usa**, y son tres sitios concretos:

```go
// internal/collections/set.go
//
// 1. CONTENEDORES. Es el caso canónico: antes había que escribir un Set por cada
// tipo, o usar map[string]struct{} con aserciones por todas partes.

// Set es un conjunto sin orden. Su valor cero NO es usable: usa New.
type Set[T comparable] struct {
	items map[T]struct{}
}

func NewSet[T comparable](items ...T) *Set[T] {
	s := &Set[T]{items: make(map[T]struct{}, len(items))}
	for _, item := range items {
		s.items[item] = struct{}{}
	}
	return s
}

func (s *Set[T]) Add(item T)           { s.items[item] = struct{}{} }
func (s *Set[T]) Has(item T) bool      { _, ok := s.items[item]; return ok }
func (s *Set[T]) Len() int             { return len(s.items) }
```

```go
// internal/httpapi/decode.go
//
// 2. FIRMAS DONDE LA ALTERNATIVA ERA interface{} CON ASERCIONES. Este es el que
// más valor aporta en un servicio HTTP.

// ANTES (1.13): cada handler repetía las mismas quince líneas de decodificación,
// con su límite de tamaño, su DisallowUnknownFields y su manejo de error.
//
// DESPUÉS: una función, tipada, y el handler queda en tres líneas.
func decodeJSON[T any](w http.ResponseWriter, r *http.Request) (T, error) {
	var v T

	dec := json.NewDecoder(http.MaxBytesReader(w, r.Body, maxBodyBytes))
	dec.DisallowUnknownFields()

	if err := dec.Decode(&v); err != nil {
		var maxErr *http.MaxBytesError   // 🎁 Go 1.19: tipo en vez de comparar texto
		switch {
		case errors.As(err, &maxErr):
			return v, fmt.Errorf("%w: máximo %d bytes", errBodyTooLarge, maxErr.Limit)
		case errors.Is(err, io.EOF):
			return v, fmt.Errorf("%w: el cuerpo está vacío", errBadJSON)
		default:
			return v, fmt.Errorf("%w: %v", errBadJSON, err)
		}
	}
	return v, nil
}

// Y el handler, que antes tenía quince líneas de fontanería:
func (h *WorkItemHandler) create(w http.ResponseWriter, r *http.Request) {
	req, err := decodeJSON[createRequest](w, r)
	if err != nil {
		writeError(w, r, err)
		return
	}
	// ...
}
```

Fíjate de paso en `*http.MaxBytesError`: es la deuda de época de la Fase 05, donde
teníamos que comparar el **texto** del error. Go 1.19 le dio un tipo. Eso es una
adopción que borra un parche, y son las mejores.

```go
// internal/collections/slices.go
//
// 3. UTILIDADES DE SLICES Y MAPAS que se repetían por tipo.

// GroupBy agrupa por una clave derivada. Reemplaza cuatro funciones casi
// idénticas que teníamos: por estado, por tipo, por prioridad, por endpoint.
func GroupBy[T any, K comparable](items []T, key func(T) K) map[K][]T {
	out := make(map[K][]T)
	for _, item := range items {
		k := key(item)
		out[k] = append(out[k], item)
	}
	return out
}
```

**Y dónde el curso los RECHAZA, explícitamente:**

```go
// ❌ RECHAZADO — el Repository genérico
type Repository[T any] interface {
	Save(ctx context.Context, entity T) error
	FindByID(ctx context.Context, id string) (T, error)
	FindAll(ctx context.Context) ([]T, error)
	Delete(ctx context.Context, id string) error
}
```

Es elegante, es lo primero que se le ocurre a todo el mundo que viene de Spring
Data, y es **el ☕ más sofisticado que existe**. Los motivos, concretos:

1. **Las consultas reales no son genéricas.** `FindByID` sí; `ListByStatus`,
   `ListPendingBefore(time.Time)`, `ClaimNextBatch(n int)` no. En cuanto aparecen
   —y aparecen en la Fase 09— acabas con una interfaz genérica más una interfaz
   específica por entidad, que es más código que no tener la genérica.
2. **Empuja hacia un modelo de persistencia uniforme** que no existe: `WorkItem`
   va a PostgreSQL, `Country` a MongoDB, `Movement` a SQLite. Sus operaciones no se
   parecen.
3. **Rompe la regla de la Fase 02**: una interfaz genérica de cuatro métodos vive
   necesariamente en un paquete compartido, no en el consumidor. La dirección de
   las dependencias se invierte.
4. **Y la prueba definitiva:** escríbela y cuenta cuántos consumidores usan los
   cuatro métodos. En Meridian, ninguno.

```go
// ❌ RECHAZADO — la capa de servicio genérica
type Service[T Entity, ID comparable] struct { ... }
```

Es `AbstractBaseService<T>` con sintaxis nueva, y es el mismo error.

> 🧭 **Regla del proyecto sobre genéricos.** **Escribe la versión concreta primero.
> Generaliza cuando tengas el tercer caso de uso delante, no antes.** Un genérico
> prematuro es la forma moderna de `AbstractBaseService<T>`, con el agravante de
> que ahora el compilador te ayuda a construirlo.
>
> Y la prueba práctica: si tu tipo genérico tiene un `switch` sobre el tipo
> concreto dentro, o una restricción con cinco métodos, **no era genérico**: era
> una interfaz.

---

**Fuzzing**, que es la tercera adopción de este salto y la más infravalorada.

```go
// labs/movement-parser/parse_fuzz_test.go

// FuzzParseMovement alimenta el parser con entradas generadas. El fuzzer parte
// del corpus semilla y muta: trunca, cambia bytes, inserta caracteres raros.
//
// El objetivo NO es encontrar entradas que fallen —un parser DEBE rechazar
// basura—: es encontrar entradas que hagan PANIC, o que produzcan un resultado
// incoherente. Una función que devuelve un error es correcta; una que entra en
// panic con una entrada del mundo real es un incidente.
func FuzzParseMovement(f *testing.F) {
	// El corpus semilla: casos reales, incluidos los raros que ya conocemos.
	f.Add("ST-014|2026-09-11T08:14:02Z|SALE|145900|COP")
	f.Add("ST-014|2026-09-11T08:15:41Z|REFUND|-32000|COP")
	f.Add("")
	f.Add("|||||")
	f.Add("ST-014|2026-09-11T08:14:02Z|SALE|99999999999999999999|COP")
	f.Add("ST-ñ|2026-09-11T08:14:02Z|SALE|145900|COP")

	f.Fuzz(func(t *testing.T, line string) {
		// Lo único que se exige: no entrar en panic, pase lo que pase.
		m, err := parseMovement(line)
		if err != nil {
			return // rechazar es correcto
		}

		// Y si lo aceptó, el resultado tiene que ser coherente. Estos son
		// INVARIANTES, y son la parte valiosa del fuzzing: lo que se puede
		// afirmar sin conocer la entrada.
		if m.StoreID == "" {
			t.Errorf("aceptó una línea sin tienda: %q", line)
		}
		if m.Kind == "" {
			t.Errorf("aceptó una línea sin tipo: %q", line)
		}
		if m.Currency == "" {
			t.Errorf("aceptó una línea sin moneda: %q", line)
		}

		// Ida y vuelta: si lo parseamos y lo volvemos a formatear, tiene que
		// volver a parsear igual. Es el invariante más potente que existe para
		// un parser y encuentra bugs que ningún test de tabla encuentra.
		reparsed, err := parseMovement(m.String())
		if err != nil {
			t.Errorf("el resultado de String() no vuelve a parsear: %q → %q: %v",
				line, m.String(), err)
		}
		if reparsed != m {
			t.Errorf("ida y vuelta no es idempotente:\n  original: %+v\n  vuelta:   %+v", m, reparsed)
		}
	})
}
```

```bash
go test -run '^$' -fuzz FuzzParseMovement -fuzztime 60s ./labs/movement-parser
```

```text
fuzz: elapsed: 3s, gathering baseline coverage: 6/6 completed
fuzz: elapsed: 12s, execs: 284917 (28491/sec), new interesting: 14
--- FAIL: FuzzParseMovement (12.04s)
    parse_fuzz_test.go:31: aceptó una línea sin moneda: "0|0|0|0|"

    Failing input written to testdata/fuzz/FuzzParseMovement/8f2a9c1b...
    To re-run:
    go test -run=FuzzParseMovement/8f2a9c1b...
```

**El fuzzer encontró en doce segundos que `"0|0|0|0|"` produce cinco campos con la
moneda vacía**, y el parser lo aceptaba. Ningún test de tabla de la Fase 01 lo
cubría, porque a nadie se le ocurre escribir ese caso.

Y el archivo que escribió en `testdata/fuzz/` **se commitea**: a partir de ahora,
`go test ./...` normal lo ejecuta como caso de regresión, sin necesidad de correr
el fuzzer.

> 🧭 **Decisión del curso sobre fuzzing en CI.** El fuzzing **no corre** en el
> pipeline normal: es no determinista y consume tiempo indefinido. Lo que sí corre
> es el corpus guardado, que es determinista y gratis. El fuzzing de verdad se
> lanza a mano con `-fuzztime 10m` cuando se toca un parser, y en una tarea
> nocturna si el proyecto lo justifica.

📖 En Java el paralelo es jqwik para property-based testing o Jazzer para fuzzing
de verdad. Los dos son librerías; aquí está en el toolchain, y esa diferencia hace
que se use.

---

**Y `golang.org/x/sync`**, que sale del régimen de stdlib pura:

```go
// ANTES (Fase 06) — el semáforo escrito a mano con un canal con búfer
sem := make(chan struct{}, limit)
sem <- struct{}{}
defer func() { <-sem }()

// DESPUÉS — semaphore.Weighted, que además soporta pesos y contexto
if err := sem.Acquire(ctx, 1); err != nil {
	return err   // el contexto se canceló mientras esperábamos: mejor que colgarse
}
defer sem.Release(1)
```

```go
// Y errgroup, que es el patrón "lanza N, espera a todas, quédate con el primer
// error" que en la Fase 06 escribimos a mano tres veces.

func (s *Service) FanOutDeliveries(ctx context.Context, deliveries []relay.Delivery) error {
	g, ctx := errgroup.WithContext(ctx)
	g.SetLimit(s.maxConcurrent)   // ← el límite, que es la regla de la Fase 06

	for _, d := range deliveries {
		d := d   // 🕰️ innecesario desde 1.22; ver §6.4
		g.Go(func() error {
			return s.deliver(ctx, d)
		})
	}

	// Wait devuelve el PRIMER error no nulo, y el ctx derivado se cancela en
	// cuanto una falla: las demás se enteran y paran. Eso, escrito a mano, son
	// treinta líneas y es donde la gente se equivoca.
	return g.Wait()
}
```

**Adoptado**, y con una comparación honesta contra lo que escribimos: `errgroup`
son unas 130 líneas de código ajeno que sustituyen a unas 30 nuestras y además
manejan bien la cancelación en cascada. El intercambio compensa **porque es del
equipo de Go** (`golang.org/x` es semi-oficial), es estable desde hace años y no
arrastra dependencias.

### 6.3 Salto 1.19–1.21: `slog`, `slices`, `errors.Join`

**`log/slog` sustituye al logger propio**, y esta es la adopción que más se nota.

```go
// ANTES (Fase 05) — log.Printf con formato libre
log.Printf("%s %s %s %d %dB %s",
	requestID, r.Method, r.URL.Path, rec.status, rec.bytes, elapsed)
// req-8821 POST /work-items 201 312B 4.21ms
```

Ese log es legible por un humano en una terminal y **es inconsultable en un
agregador**: para saber "cuántas peticiones a `/work-items` devolvieron 5xx la
semana pasada", hay que parsear texto con expresiones regulares.

```go
// DESPUÉS (1.21) — log/slog
func Logging(logger *slog.Logger) Middleware {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()
			rec := &statusRecorder{ResponseWriter: w}

			next.ServeHTTP(rec, r)

			logger.LogAttrs(r.Context(), slog.LevelInfo, "petición servida",
				slog.String("request_id", RequestIDFrom(r.Context())),
				slog.String("method", r.Method),
				slog.String("path", r.URL.Path),
				slog.Int("status", rec.status),
				slog.Int("bytes", rec.bytes),
				slog.Duration("elapsed", time.Since(start)),
			)
		})
	}
}
```

```json
{"time":"2026-09-11T14:03:22.118Z","level":"INFO","msg":"petición servida","request_id":"req-8821","method":"POST","path":"/work-items","status":201,"bytes":312,"elapsed":4210000}
```

Ahora `status >= 500` es una consulta, no una expresión regular.

Tres decisiones del curso que se toman aquí:

```go
// 1. El logger se INYECTA, no se usa el global. Es la regla 7 de la guía: cero
//    estado global mutable. slog.Default() existe y no lo usamos.
type Service struct {
	store  Store
	logger *slog.Logger
}

// 2. LogAttrs en vez de Info(msg, args...). La forma variádica acepta pares
//    clave-valor sueltos y un número impar de argumentos NO da error de
//    compilación: produce un log corrupto en tiempo de ejecución.
//    LogAttrs es tipada y además no asigna.
logger.LogAttrs(ctx, slog.LevelInfo, "mensaje", slog.String("k", "v"))

// 3. El logger se deriva con contexto en el borde, y baja por los parámetros.
//    NO se mete en el context. Un *slog.Logger es un valor barato de pasar.
reqLogger := logger.With(slog.String("request_id", id))
```

> ⚠️ **La trampa de la forma variádica de `slog`.** `logger.Info("msg", "clave")`
> —con un número impar de argumentos— compila y produce un registro con una clave
> especial `!BADKEY`. Es el tipo de error que `vet` no atrapa y que llega a
> producción. Por eso este curso usa `LogAttrs` en el código de librería y permite
> la forma corta solo en `main`.

**`slices`, `maps` y `cmp`** sustituyen utilidades escritas a mano:

```go
// ANTES — sort.Slice con un comparador booleano
sort.Slice(items, func(i, j int) bool {
	pi, pj := items[i].EffectivePriority(now), items[j].EffectivePriority(now)
	if pi != pj {
		return pi > pj
	}
	return items[i].CreatedAt.Before(items[j].CreatedAt)
})

// DESPUÉS — slices.SortStableFunc con un comparador de tres estados, que
// compone mejor: cmp.Or encadena criterios sin ifs anidados.
slices.SortStableFunc(items, func(a, b workitem.WorkItem) int {
	return cmp.Or(
		cmp.Compare(b.EffectivePriority(now), a.EffectivePriority(now)), // desc
		a.CreatedAt.Compare(b.CreatedAt),                                // asc
	)
})
```

📖 El comparador de tres estados es exactamente el `Comparator.compare` de Java, y
`cmp.Or` es `thenComparing`. Curiosamente, Go **empezó** con el booleano (más
difícil de equivocar en el caso simple) y **añadió** el de tres estados cuando
llegaron los genéricos, porque compone mejor. Las dos formas coexisten y las dos
son correctas.

**`errors.Join`**, que paga la deuda de la Fase 03:

```go
// ANTES — un tipo propio que acumula, con su Error() y su recorrido
type ValidationError struct{ Fields []FieldError }
func (e *ValidationError) Error() string { /* 8 líneas */ }

// DESPUÉS — errors.Join, si lo único que necesitas es agregar
var errs []error
if ref == "" {
	errs = append(errs, fmt.Errorf("%w: external_reference es obligatoria", ErrValidation))
}
if !kind.IsKnown() {
	errs = append(errs, fmt.Errorf("%w: kind no es válido", ErrValidation))
}
return errors.Join(errs...)   // nil si el slice está vacío: gratis
```

> 🧭 **Y aquí el curso toma una decisión que va contra el reflejo de modernizar.**
> `ValidationError` **se queda**, no se sustituye por `errors.Join`.
>
> El motivo es concreto: el borde HTTP necesita convertir los fallos en un array
> JSON con `field` y `reason`, para que el frontend marque los campos en rojo.
> `errors.Join` produce una cadena de errores cuyo texto hay que **parsear** para
> extraer el campo. Nuestro tipo lleva `[]FieldError` estructurado dentro.
>
> **`errors.Join` es mejor para agregar; nuestro tipo es mejor para estructurar.**
> Sí adoptamos `Join` en tres sitios donde solo agregábamos: el `FanOut` de
> `notifier`, la validación de configuración del arranque, y los errores del
> apagado. **Esa es la forma de la decisión que esta fase enseña.**

**`context.WithoutCancel` y `AfterFunc`**, que pagan tres deudas de la Fase 07:

```go
// ANTES (Fase 07) — contexto nuevo para el guardado, perdiendo los valores
saveCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)

// DESPUÉS (1.21) — conserva los valores (el request_id, el trace_id) y descarta
// la cancelación. Es exactamente lo que hacía falta.
saveCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), 5*time.Second)
defer cancel()
```

Y `AfterFunc`, que simplifica el registro de cancelaciones:

```go
// ANTES — una goroutine por trabajo solo para vigilar la cancelación
go func() {
	<-jobCtx.Done()
	e.logger.Warn("trabajo cancelado", slog.String("id", item.ID))
}()

// DESPUÉS — sin goroutine propia; el runtime lo invoca al cancelar
stop := context.AfterFunc(jobCtx, func() {
	e.logger.Warn("trabajo cancelado", slog.String("id", item.ID))
})
defer stop()
```

**Y `GOMEMLIMIT` (1.19)**, que no es código sino operación:

```bash
# Un límite SUAVE de memoria: el recolector se vuelve más agresivo al acercarse,
# en vez de que el sistema mate el proceso por OOM.
GOMEMLIMIT=512MiB ./bin/opsreport
```

Es la respuesta de Go al problema de correr en un contenedor con límite de
memoria. Se anota aquí y **se configura de verdad en la Fase 14**; se mide en
B-22 (Fase 15).

### 6.4 Salto 1.22–1.23: el `ServeMux` y la variable de bucle

**La muerte de `tiny-router`**, y es la mejor clase de diseño de API del curso.

```go
// ANTES — tiny-router (Fase 05), 60 líneas de enrutador propio
r := router.New()
r.POST("/work-items", h.create)
r.GET("/work-items", h.list)
r.GET("/work-items/:id", h.get)
r.POST("/work-items/:id/start", h.start)
r.DELETE("/work-items/:id", h.cancel)

// La firma del handler era ESPECIAL: recibía router.Params.
func (h *Handler) get(w http.ResponseWriter, r *http.Request, p router.Params) {
	item, err := h.svc.Get(r.Context(), p["id"])
	// ...
}
```

```go
// DESPUÉS — el ServeMux de la stdlib (1.22)
mux := http.NewServeMux()
mux.HandleFunc("POST /work-items", h.create)
mux.HandleFunc("GET /work-items", h.list)
mux.HandleFunc("GET /work-items/{id}", h.get)
mux.HandleFunc("POST /work-items/{id}/start", h.start)
mux.HandleFunc("DELETE /work-items/{id}", h.cancel)

// Y la firma vuelve a ser http.HandlerFunc, la estándar.
func (h *Handler) get(w http.ResponseWriter, r *http.Request) {
	item, err := h.svc.Get(r.Context(), r.PathValue("id"))
	// ...
}
```

**Pon las dos versiones lado a lado y mira qué cambió de verdad**, porque no es
solo que se borren sesenta líneas:

| | `tiny-router` | `ServeMux` 1.22 |
|---|---|---|
| Líneas de enrutador propio | 60 | **0** |
| Firma del handler | especial (`+ router.Params`) | **`http.HandlerFunc` estándar** |
| Compatible con middleware de terceros | solo tras adaptar | sí, directamente |
| Algoritmo de coincidencia | lineal, primero que casa | árbol con **precedencia por especificidad** |
| `/work-items/new` frente a `/work-items/{id}` | gana el registrado primero | gana **el más específico**, siempre |
| 405 con cabecera `Allow` | escrito a mano | automático |
| Comodín de cola | no soportado | `{path...}` |
| Anclaje exacto de ruta | por construcción | `{$}` para "solo esta ruta" |
| Tests que hubo que cambiar | — | **los de `router`, que se borran** |

**El cambio de la firma es el importante y es una lección de diseño de API.** Al
guardar los valores de ruta **dentro de la petición** en vez de pasarlos como
parámetro extra, el `ServeMux` de la stdlib mantiene la compatibilidad con todo el
ecosistema: cualquier middleware, cualquier `http.Handler`, cualquier librería que
espere la firma estándar sigue funcionando. Nuestro enrutador, al cambiar la
firma, creaba un dialecto incompatible.

**Ese es el precio oculto de las abstracciones propias que alteran una interfaz
estándar**, y es una lección que se transfiere a cualquier lenguaje.

📖 Y el cierre del círculo con Spring: `mux.HandleFunc("GET /work-items/{id}", h)`
es, letra por letra, `@GetMapping("/work-items/{id}")`. La diferencia que queda es
la conversión de tipos: `@PathVariable Long id` convierte y responde 400 solo;
`r.PathValue("id")` devuelve un `string` y la conversión es tuya. **Esa sigue
siendo la diferencia real entre los dos mundos, y ahora la puedes medir en líneas
de código.**

> 📐 **Cómo se mide.** Entrada **B-12**: *`ServeMux` moderno frente al enrutado a
> mano*. Con 5, 50 y 200 rutas registradas, y una tercera variante si hiciste el
> ejercicio 23 de la Fase 05 (el enrutador con árbol). **El resultado esperado con
> 5 rutas es "no se distingue", y esa es media lección**: la razón para adoptar el
> `ServeMux` no es el rendimiento, es que son sesenta líneas menos y una firma
> estándar.

---

**El cambio de la variable de bucle (1.22)**, que es el más sutil de toda la
migración.

```go
// En Go 1.13–1.21: `tt` es UNA variable reutilizada. Las closures la comparten.
for _, tt := range tests {
	tt := tt            // ← esta línea existía para crear una copia por iteración
	t.Run(tt.name, func(t *testing.T) { ... })
}

// En Go 1.22+: `tt` es una variable NUEVA en cada iteración. La copia sobra.
for _, tt := range tests {
	t.Run(tt.name, func(t *testing.T) { ... })
}
```

**Y aquí está el ejercicio más valioso de esta fase**: buscar en las siete fases
anteriores dónde este cambio habría alterado el comportamiento.

```bash
# Localizar todas las copias defensivas:
grep -rn --include="*.go" -E '^\s+(\w+) := \1$' services/ labs/

# Y todas las closures dentro de bucles, que es donde el cambio importa:
grep -rn --include="*.go" -B2 -A2 'go func' services/ | grep -A2 'for '
```

En el código del curso hay tres categorías:

1. **Copias defensivas que ahora sobran** (los `tt := tt` de todos los tests de
   tabla). Se borran. **El comportamiento no cambia.**
2. **Argumentos pasados a la goroutine** (`go func(item T){...}(item)` del motor de
   jobs). Siguen siendo correctos y **se quedan**: pasar el valor explícitamente
   se lee bien y funciona en las dos épocas.
3. **Y el caso que hay que buscar de verdad: un bucle con una closure que capture
   la variable y se ejecute más tarde, sin copia.** Ese código estaba **mal** en
   1.13 y con 1.22 se arregló solo. Si lo encuentras, tienes un bug que llevaba
   siete fases latente.

> ⚠️ **El caso peligroso, el que va en la otra dirección.** Existe código que
> **dependía** de compartir la variable:
> ```go
> var last *Item
> for _, item := range items {
>     last = &item   // en 1.21 apunta a la ÚNICA variable; en 1.22, a la última copia
> }
> ```
> En 1.21, `last` apunta a la variable del bucle, que tras terminar contiene el
> último elemento — el mismo resultado, por casualidad. Pero código que guardaba
> `&item` de **varios** elementos obtenía punteros al mismo sitio en 1.21 (bug) y
> punteros distintos en 1.22 (correcto). **Casi siempre el cambio arregla bugs; en
> algún caso raro, altera un comportamiento del que alguien dependía sin saberlo.**
> Por eso este salto se hace con la suite verde y `-shuffle=on`.

**Y `range` sobre enteros y sobre funciones:**

```go
// range sobre entero (1.22): el bucle de N iteraciones, sin variable inútil.
for range workerCount {
	go worker()
}
for i := range workerCount {
	go worker(i)
}
```

```go
// Iteradores (1.23). El curso los ADOPTA en un sitio concreto y los rechaza en
// el resto, y esa decisión merece explicarse.

// ADOPTADO: recorrer resultados de base de datos sin materializar el slice.
// Es el caso de la Fase 13, con un millón de movimientos.
func (s *Store) PendingDeliveries(ctx context.Context) iter.Seq2[relay.Delivery, error] {
	return func(yield func(relay.Delivery, error) bool) {
		rows, err := s.db.QueryContext(ctx, pendingDeliveriesSQL)
		if err != nil {
			yield(relay.Delivery{}, err)
			return
		}
		defer rows.Close()

		for rows.Next() {
			var d relay.Delivery
			if err := rows.Scan(&d.ID, &d.EventID /* ... */); err != nil {
				yield(relay.Delivery{}, err)
				return
			}
			if !yield(d, nil) {
				return   // el consumidor hizo break: paramos limpiamente
			}
		}
		if err := rows.Err(); err != nil {
			yield(relay.Delivery{}, err)
		}
	}
}

// Y el consumidor:
for delivery, err := range store.PendingDeliveries(ctx) {
	if err != nil {
		return err
	}
	// ...
}
```

Eso es genuinamente mejor que devolver `[]Delivery` con un millón de elementos, y
mejor que exponer `*sql.Rows` al llamador. **Adoptado, con su justificación.**

```go
// ❌ RECHAZADO: convertir todo lo que devuelve un slice en un iterador.
//
// func (s *Store) All() iter.Seq[WorkItem]   ← no
//
// Un slice de cien elementos ya está en memoria. Convertirlo en un iterador
// añade una closure, impide usar len(), impide indexar, impide ordenarlo, y
// obliga a materializarlo otra vez a la mitad de los consumidores.
// Los iteradores son para lo que NO cabe o NO existe todavía.
```

### 6.5 Hasta Go 1.25: lo que se adopta y lo que no

Los saltos finales, con menos superficie y decisiones igual de explícitas:

**Adoptado:**

- **`math/rand/v2` (1.22).** La versión nueva no tiene el estado global con lock
  que serializaba las goroutines, la API es más limpia y `rand.N` es genuinamente
  útil. EventRelay lo usa para el *jitter* de los reintentos, y la mejora es real.
- **`unique` (1.23)** — **no**, ver rechazos.
- **`sync.OnceFunc` / `OnceValue` (1.21).** Sustituyen el par `sync.Once` +
  variable por una línea. Adoptado donde había ese par.
- **`slices.Chunk` (1.23).** Sustituye exactamente la función `SplitBatches` del
  ejercicio 9 de la Fase 01. Adoptado, y borrar código propio a favor de la stdlib
  es siempre buen negocio.
- **`testing.B.Loop` (1.24).** Sustituye a `for i := 0; i < b.N; i++` y además
  evita que el compilador elimine el código medido, que era una fuente real de
  benchmarks mentirosos. **Adoptado en todos los benchmarks**, y se explica en la
  Fase 15.
- **`for range` sobre enteros** en los arranques de workers y en los bucles de
  repetición.
- **`go.uber.org/goleak`.** No es una novedad del lenguaje sino una librería, y
  entra aquí porque la Fase 07 lo dejó escrito: el detector de fugas de su §6.4
  está hecho a mano a propósito, y **ahora se sustituye para ver la diferencia.**
  Ver abajo.

**Rechazado, con motivo:**

- **`unique.Make` (1.23).** Interna cadenas para ahorrar memoria con muchos
  duplicados. Meridian no tiene ese problema: los identificadores son distintos
  entre sí y los valores de `status` son constantes de paquete. **Adoptarlo sería
  optimizar sin medir, que es lo que la Fase 15 enseña a no hacer.**
- **`go tool` con herramientas en el `go.mod` (1.24).** Permite declarar
  `golangci-lint` y compañía como dependencias del módulo, versionadas. Es
  atractivo —resuelve el problema de que cada dev tenga una versión distinta—, y
  el curso lo rechaza por una razón pedagógica declarada: **añade una capa de
  indirección justo donde queremos que el estudiante vea los comandos desnudos.**
  En un proyecto real de equipo, adóptalo. Aquí, no.
- **`maps.Collect`, `slices.Collect` y compañía.** Útiles, y en este código no
  sustituyen nada: no tenemos iteradores que recolectar salvo el de §6.4, y allí lo
  que queremos es no materializar.
- **Reescribir los tests con `synctest` (1.24, experimental).** Permite controlar
  el tiempo virtual en tests concurrentes y es exactamente lo que nuestro
  `fakeClock` hace a mano. **Se evalúa, se anota como candidato, y se rechaza por
  ser experimental**; se revisa en la Fase 15.

**Y una librería, no una novedad del lenguaje: `goleak`.**

La Fase 07 §6.4 escribió un detector de fugas a mano —cuenta goroutines antes y
después del test— y dijo explícitamente que esta fase lo sustituiría. Se cumple:

```go
// services/opsreport/internal/jobs/main_test.go
package jobs

import (
	"testing"

	"go.uber.org/goleak"
)

// TestMain envuelve TODOS los tests del paquete. Es la forma correcta de usarlo:
// la fuga se comprueba al final de la suite, no test a test, porque una goroutine
// legítima puede tardar en morir y test a test da falsos positivos.
func TestMain(m *testing.M) {
	goleak.VerifyTestMain(m,
		// El pool de database/sql mantiene goroutines vivas legítimamente
		// mientras viva el proceso. Sin esta exclusión, goleak grita en cada
		// paquete que toca la base de datos.
		goleak.IgnoreTopFunction("database/sql.(*DB).connectionOpener"),
	)
}
```

> 🪞 **Lo que el contador a mano no podía hacer.** El detector de la Fase 07
> contaba goroutines: sabía **cuántas** sobraban, no **cuáles**. `goleak` inspecciona
> las pilas, así que nombra la función donde cada goroutine fugada quedó parada
> —que es el 90% del trabajo de arreglarla— y distingue las legítimas del runtime
> y de las librerías. Ese es el salto, y solo se aprecia habiendo escrito antes el
> contador.

> ⚠️ **La lista de `Ignore...` es deuda, no configuración.** Cada exclusión es una
> fuga que decides no mirar. Escribe al lado **por qué** es legítima, como arriba.
> Ocho exclusiones sin comentarios significan que el paquete tiene fugas y nadie lo
> sabe.

### 6.6 El entregable: `docs/rechazos.md`

Esta es la pieza que hace que la fase valga más que un tutorial de novedades.

```markdown
# Lo que evaluamos y decidimos no adoptar

Este documento vale tanto como la lista de adopciones. Cada entrada dice qué se
evaluó, por qué se rechazó, y **qué tendría que cambiar para reconsiderarlo** —
porque un rechazo sin condición de revisión es un dogma.

## io/fs como abstracción del sistema de archivos  (Go 1.16)
**Rechazado.** Ningún servicio de Meridian necesita trabajar indistintamente con
disco, un ZIP y un `embed.FS`. Adoptarlo añade una interfaz con una sola
implementación, que es el antipatrón de la Fase 02.
**Se reconsidera si:** aparece un servicio que lea plantillas de varios orígenes
(por ejemplo, plantillas de reporte personalizables por cliente, cargadas de un
bucket).

## Repository[T] genérico  (Go 1.18)
**Rechazado.** Las consultas reales no son genéricas: `ListPendingBefore`,
`ClaimNextBatch` y `ListByStatus` no caben en la interfaz. Empuja hacia un modelo
de persistencia uniforme que no existe —PostgreSQL, MongoDB y SQLite tienen
operaciones distintas— y rompe la regla de declarar interfaces en el consumidor.
**Se reconsidera si:** aparecen tres entidades con exactamente el mismo conjunto
de operaciones y el mismo almacén. (Contamos: hoy son cero.)

## Service[T] genérico  (Go 1.18)
**Rechazado.** Es `AbstractBaseService<T>` con sintaxis nueva.
**Se reconsidera si:** nunca.

## errors.Join en lugar de ValidationError  (Go 1.20)
**Rechazado parcialmente.** Adoptado donde solo agregamos errores (FanOut de
notifier, validación de configuración, errores del apagado). **Rechazado** para la
validación de dominio: el borde HTTP necesita `[]FieldError` estructurado para
producir el JSON que el frontend usa; `errors.Join` obligaría a parsear texto.
**Se reconsidera si:** la API deja de exponer los campos con error por separado.

## unique.Make  (Go 1.23)
**Rechazado.** Optimiza un problema que no tenemos: los identificadores de
Meridian son únicos por diseño y los `status` ya son constantes de paquete.
Adoptarlo es optimizar sin medir.
**Se reconsidera si:** un perfil de memoria (Fase 15) muestra duplicación
significativa de cadenas.

## go tool con herramientas en el go.mod  (Go 1.24)
**Rechazado por motivo pedagógico**, no técnico. El curso quiere que los comandos
se vean desnudos. **En un proyecto de equipo real, adóptalo**: resuelve el
problema de versiones divergentes de `golangci-lint` entre desarrolladores.

## testing/synctest  (Go 1.24, experimental)
**Aplazado.** Resuelve exactamente lo que nuestro `fakeClock` resuelve a mano, y
mejor. Rechazado hoy por ser experimental y estar tras un `GOEXPERIMENT`.
**Se reconsidera en:** la Fase 15, y cuando deje de ser experimental.

## Convertir todo lo que devuelve []T en iter.Seq[T]  (Go 1.23)
**Rechazado.** Un slice pequeño ya está en memoria; convertirlo en iterador impide
`len`, impide indexar, impide ordenar, y obliga a la mitad de los consumidores a
materializarlo otra vez. Los iteradores son para lo que no cabe en memoria o no
existe todavía — y ahí sí lo adoptamos (cursores de base de datos, Fase 13).

## Reescribir la arquitectura durante la migración
**Rechazado.** Ver la autopsia de la Fase 08. Migrar y refactorizar van en
commits distintos, o el `git bisect` deja de servir.
```

### 6.7 El resultado: dos ramas comparables

```bash
git diff bloque-a-completo fase-08 --stat
```

```text
 go.work                                       |  10 ++
 services/opsreport/go.mod                     |   6 +-
 services/opsreport/internal/router/router.go  | 128 ---------------
 services/opsreport/internal/router/router_test.go | 210 --------------------
 services/opsreport/internal/httpapi/routes.go |  18 +--
 services/opsreport/internal/httpapi/decode.go |  34 ++++
 services/opsreport/internal/report/embed.go   |  14 ++
 ...
 47 files changed, 412 insertions(+), 689 deletions(-)
```

**Menos código del que había**, y el servicio hace lo mismo. Ese `--stat` es el
entregable más honesto de la fase: no es que hayas añadido features modernas, es
que **borraste lo que la stdlib acabó trayendo**.

> 📐 **Cómo se mide.** Entrada **B-11**: *el mismo servicio en 1.13 y en Go
> moderno*. Tamaño del binario, tiempo de arranque en frío hasta la primera
> petición servida, memoria residente en reposo, y tiempo de compilación desde
> limpio. Los dos binarios se compilan con `-ldflags "-s -w"` y `CGO_ENABLED=0`,
> desde el mismo código salvo los cambios de esta fase.
>
> **La hipótesis que hay que declarar antes de medir**, y es deliberadamente
> incómoda: *"el binario de Go moderno será más grande que el de 1.13, y el
> arranque y la memoria serán similares"*. Trece versiones de stdlib añadida pesan;
> el rendimiento del recolector mejoró mucho en ese periodo, pero un servicio en
> reposo no lo nota. **Si tu medición dice que todo mejoró, desconfía y revisa las
> condiciones.**

> 🧪 **Prueba de fuego.** Corre la suite completa con el orden aleatorio, que hasta
> hoy no existía:
> ```bash
> go test -shuffle=on -race -count=3 ./...
> ```
> **La mentira de la pantalla:** si pasa, no celebres todavía — corre `-count=10`.
> Un test que depende del orden falla en una de cada varias permutaciones, no
> siempre. Y si falla, acabas de encontrar un bug que llevaba siete fases dormido,
> lo cual es una buena noticia disfrazada de mala.

---

## ⚰️ 7. Autopsia y errores comunes

### ⚰️ Autopsia: la migración que se convirtió en reescritura

**El cadáver.** Es el PR que todos hemos visto, y en Java tiene su propia
categoría: *"Spring Boot 2 → 3"*, 340 archivos, 12.000 líneas.

Aquí sería el equivalente: alguien empieza a migrar OpsReport y, ya que toca cada
archivo, decide que:

- los `WorkItemStore`, `DeliveryStore` y `ReportStore` deberían ser un
  `Repository[T]` genérico;
- la capa de servicio cabría en un `Service[T, ID]`;
- ya que `slog` estructura los logs, hay que cambiar todos los mensajes de texto;
- los iteradores son mejores, así que todo lo que devuelve slice pasa a
  `iter.Seq`;
- y como estamos, `internal/opsreport` debería llamarse `internal/application`.

Todo compila. Los tests, después de "adaptarlos", pasan.

**El informe forense:**

| | Migración disciplinada | Migración-reescritura |
|---|---|---|
| Archivos tocados | 47 | 340 |
| Líneas netas | **−277** | +4.100 |
| Commits | 6 (uno por salto) | 1 |
| Revisable de verdad por un colega | sí | **no** |
| Tests modificados | 11 (los de `router`, borrados) | 180 ("adaptados") |
| `git bisect` útil si algo se rompe | sí | **no** |
| Se puede separar "qué rompió la migración" de "qué rompió el refactor" | sí | **no** |
| Tiempo hasta poder desplegar | 1 día | 3 semanas de revisión |

**Y el coste que no está en la tabla y es el que mata:** cuando tres semanas
después el motor de jobs empieza a perder trabajos bajo carga, `git bisect` te
lleva a un commit titulado *"migración a Go moderno"* con 12.000 líneas. Ahí se
acabó el diagnóstico y empieza la arqueología.

**La causa de la muerte:** confundir dos operaciones con distinto riesgo y
distinta reversibilidad. Migrar de versión es **casi sin riesgo** en Go, gracias a
la promesa de compatibilidad. Refactorizar la arquitectura es **todo el riesgo**.
Juntarlas hace que la operación entera herede el riesgo de la peor.

**Y los "tests adaptados" son el síntoma que delata el caso.** Si migrar obliga a
cambiar 180 tests, no migraste: reescribiste. Los únicos tests que esta fase
cambia son los de `router` —que se borran porque el paquete desaparece— y los que
verifican las salidas de log, que cambiaron a propósito.

> ☕ **El patrón a memorizar.** **Una migración buena se lee en el `--stat`.** Si
> el número de archivos tocados es del orden del número de novedades adoptadas,
> vas bien. Si es del orden del número de archivos del proyecto, estás
> reescribiendo con otro nombre.

### Errores comunes

**1. `//go:embed` con una línea en blanco encima.**
*Síntoma:* el `embed.FS` está vacío y no hay ningún error.
*Causa:* la directiva tiene que ir **pegada** a la declaración. Con una línea en
blanco en medio es un comentario normal.
*Fix mínimo:* quitar la línea en blanco. Y añadir un test que compruebe que el
`FS` tiene contenido.

**2. `slog` con número impar de argumentos.**
*Síntoma:* aparece `!BADKEY` en los logs.
*Causa:* la forma variádica acepta pares y no lo verifica en compilación.
*Fix mínimo:* `LogAttrs` con `slog.String(...)` tipado.

**3. `go.work` commiteado en un repositorio de librerías.**
*Síntoma:* los usuarios de tu módulo compilan contra rutas locales que no existen.
*Causa:* `go.work` sobrescribe la resolución de módulos para todo el árbol.
*Fix mínimo:* en un monorepo de aplicaciones, commitearlo (nuestro caso). En una
librería publicada, `.gitignore`.

**4. Borrar el `tt := tt` en un módulo que todavía declara `go 1.21`.**
*Síntoma:* los subtests paralelos usan todos el último caso.
*Causa:* el comportamiento de la variable de bucle **depende de la directiva `go`
del `go.mod`**, no de la versión del compilador. Con `go 1.21` en el `go.mod`, un
compilador 1.25 sigue usando la semántica antigua.
*Fix mínimo:* subir la directiva **antes** de borrar las copias. Es un detalle
poco conocido de la compatibilidad por módulo y es la causa de bugs muy raros.

**5. Adoptar genéricos en la capa de repositorio.**
*Síntoma:* una interfaz genérica más una interfaz específica por entidad.
*Causa:* el reflejo de Spring Data.
*Fix mínimo:* borrar la genérica. Ver `docs/rechazos.md`.

**6. Confiar en el modernizador automático.**
*Síntoma:* un PR con doscientas sustituciones mecánicas, alguna de las cuales
cambia el comportamiento.
*Causa:* `modernize` y herramientas parecidas son buenas encontrando candidatos y
no conocen tu dominio.
*Fix mínimo:* usarlas para **descubrir**, revisar cada sugerencia, y aplicar en
commits temáticos.

**7. Migrar sin correr `-shuffle=on` después.**
*Síntoma:* un test que dependía del orden sigue oculto.
*Causa:* la suite pasaba antes por casualidad.
*Fix mínimo:* `-shuffle=on -count=10` como parte de la verificación de la
migración.

**8. Dejar el `go.mod` en una versión y usar API de otra.**
*Síntoma:* `undefined: slices.Chunk` con un compilador que sí la tiene.
*Causa:* la directiva `go` del módulo limita qué API de la stdlib está disponible
(desde Go 1.21 esto se aplica de verdad).
*Fix mínimo:* subir la directiva. Y entender que esto es una **feature**: es lo
que hacía que la disciplina de época del Bloque A fuera verificable.

### 🧨 Rompe a propósito

**Demuestra que la directiva `go` del `go.mod` manda sobre el compilador**, que es
el mecanismo que sostuvo todo el Bloque A y casi nadie conoce:

```bash
cd /tmp && mkdir epoch-demo && cd epoch-demo
go mod init epochdemo
```

```go
// main.go
package main

import (
	"fmt"
	"slices"
)

func main() {
	for _, chunk := range slices.Chunk([]int{1, 2, 3, 4, 5}, 2) {
		fmt.Println(chunk)
	}
}
```

```bash
# Con go 1.25 en el go.mod: compila.
go build .

# Ahora baja la directiva SIN cambiar de compilador:
go mod edit -go=1.21
go build .
```

```text
./main.go:10:21: slices.Chunk requires go1.23 or later (module is go1.21)
```

**Mismo compilador, mismo código, y no compila.** El módulo declara qué versión
del lenguaje y de la stdlib entiende, y el compilador lo respeta.

Y ahora el segundo experimento, con la variable de bucle:

```go
// loopvar.go
package main

import "fmt"

func main() {
	var fns []func()
	for _, v := range []int{1, 2, 3} {
		fns = append(fns, func() { fmt.Print(v, " ") })
	}
	for _, f := range fns {
		f()
	}
}
```

```bash
go mod edit -go=1.21 && go run .   # 3 3 3
go mod edit -go=1.22 && go run .   # 1 2 3
```

**El mismo código produce resultados distintos según una línea del `go.mod`.** Eso
es lo que hay que interiorizar antes de borrar los `tt := tt`, y es la razón por la
que el error común #4 existe.

---

## 🧪 8. Ejercicios (26)

**🟢 Fácil (1–6)**

1. Sube los dos módulos a `go 1.25` y comprueba que todo compila y pasa sin tocar
   una línea. *Criterio:* pegas la salida de `go test ./...` y cuentas cuántos
   archivos tuviste que cambiar (la respuesta correcta es cero).
2. Sustituye todo `ioutil` por `os`/`io`. *Criterio:* `staticcheck` deja de
   protestar, y explicas por qué `ioutil` sigue existiendo.
3. Crea `go.work` con los dos servicios. *Criterio:* `go build ./...` funciona
   desde la raíz, y explicas la decisión de commitearlo o no.
4. Añade la directiva `toolchain` y comprueba qué hace en una máquina con una
   versión distinta. *Criterio:* explicas la diferencia entre `go` y `toolchain` en
   el `go.mod`.
5. Reproduce el 🧨 de la directiva `go` con `slices.Chunk`. *Criterio:* pegas el
   error y explicas cómo eso sostuvo la disciplina de época del Bloque A.
6. Corre `go test -shuffle=on -count=10 ./...`. *Criterio:* reportas si algo falla;
   si no, explicas por qué ese comando ahora es parte de tu rutina.

**🟡 Intermedio (7–16)**

7. Incrusta las plantillas del reporte con `embed` y comprueba que el binario
   funciona movido a otro directorio. *Criterio:* provocas el fallo de la línea en
   blanco antes de la directiva y explicas por qué no da error.
8. Sustituye el logger por `slog` en el middleware de OpsReport. *Criterio:* pegas
   las dos salidas —texto y JSON— y escribes una consulta que sea trivial sobre la
   segunda e imposible sobre la primera.
9. Provoca el `!BADKEY` de `slog` y arréglalo con `LogAttrs`. *Criterio:* explicas
   por qué el compilador no lo detecta.
10. Sustituye `tiny-router` por el `ServeMux` de la stdlib. *Criterio:* borras el
    paquete `router` y sus tests, la firma de los handlers vuelve a
    `http.HandlerFunc`, y **todos los tests HTTP pasan sin cambios**.
11. Mide B-12 con 5, 50 y 200 rutas. *Criterio:* tu conclusión dice explícitamente
    que el rendimiento **no** es la razón para adoptar el `ServeMux`, y dice cuál
    sí lo es.
12. Escribe `decodeJSON[T]` genérico y aplícalo a los cinco handlers. *Criterio:*
    cuentas las líneas que desaparecen, y usas `*http.MaxBytesError` para retirar
    el parche de época de la Fase 05.
13. Escribe `Set[T]` y `GroupBy[T,K]`, y localiza en el código de las siete fases
    anteriores dónde sustituyen a algo. *Criterio:* al menos dos sustituciones
    reales; si no las encuentras, **no adoptes los genéricos ahí** y explica por
    qué.
14. Escribe el fuzz test del parser de movimientos con el invariante de ida y
    vuelta. *Criterio:* encuentras al menos un caso que el test de tabla no
    cubría, y commiteas el corpus.
15. Sustituye el semáforo a mano por `errgroup` con `SetLimit` en EventRelay.
    *Criterio:* cuentas las líneas de las dos versiones y explicas qué hace
    `errgroup` que tu versión no hacía.
16. **Línea de comandos.** Usa `grep` para encontrar todas las copias defensivas
    `x := x` del repositorio y clasifícalas en las tres categorías de §6.4.
    *Criterio:* la clasificación está justificada caso por caso.

**🟠 Difícil (17–22)**

17. **Qué NO migrar (1).** Escribe el `Repository[T]` genérico completo para
    `WorkItem` y `Delivery`, úsalo de verdad, y después argumenta su rechazo.
    *Criterio:* (a) funciona; (b) cuentas cuántas operaciones reales de los dos
    servicios **no** caben en él; (c) el argumento no dice "los genéricos son
    malos".
18. **Qué NO migrar (2).** Sustituye `ValidationError` por `errors.Join` y llega
    hasta el borde HTTP. *Criterio:* demuestras qué se rompe en la respuesta JSON,
    y escribes la entrada de `docs/rechazos.md` con su condición de revisión.
19. **Qué NO migrar (3).** Convierte `Store.ListByStatus` en `iter.Seq[WorkItem]` y
    mira qué pasa en sus consumidores. *Criterio:* identificas al menos dos que
    tienen que materializarlo otra vez, y decides con ese dato.
20. **Qué NO migrar (4).** Evalúa `unique.Make` sobre los identificadores de
    Meridian. *Criterio:* mides la duplicación real de cadenas antes de decidir, y
    tu rechazo cita el número.
21. **Qué NO migrar (5).** Evalúa `go tool` con herramientas en el `go.mod`.
    *Criterio:* lo montas, funciona, y **lo rechazas para el curso pero lo
    recomiendas para un equipo real**, explicando la diferencia.
22. **Qué NO migrar (6).** Busca en el código del Bloque A tres cosas que un
    modernizador automático sustituiría y que **no deberían** sustituirse.
    *Criterio:* para cada una, qué sugeriría la herramienta, por qué está mal, y
    qué señal debería haberte hecho desconfiar.

**🔴 Muy difícil (23–26)**

23. **La migración, commit por commit.** Rehaz la migración completa desde
    `bloque-a-completo` en seis commits, uno por salto. *Rúbrica:* (a) cada commit
    compila y pasa la suite por sí solo; (b) el mensaje de cada uno dice qué se
    adoptó, qué se rechazó y por qué, en tres líneas; (c) `git bisect` entre los
    dos extremos funciona de verdad —demuéstralo introduciendo un bug en un commit
    intermedio y encontrándolo—; (d) el `--stat` final tiene **más borrados que
    añadidos**.
24. **Mide B-11 en serio.** Compila OpsReport con `go1.13` y con `go 1.25`, y
    compara. *Rúbrica:* (a) tamaño del binario, arranque en frío hasta la primera
    petición servida, memoria residente en reposo y bajo carga, y tiempo de
    compilación desde limpio (`go clean -cache` antes); (b) declaras la hipótesis
    **antes** y dices si te equivocaste; (c) explicas cada diferencia con una causa,
    no con un adjetivo; (d) el veredicto incluye la pregunta incómoda: si el binario
    creció y el rendimiento no mejoró de forma medible, **¿qué ganaste migrando?** —
    y la respuesta honesta es sobre mantenimiento, no sobre números.
25. **El informe de migración.** Escribe `docs/migracion-1.13-a-1.25.md`, dirigido
    a un arquitecto que tiene que aprobar la misma operación sobre un servicio de
    producción. *Rúbrica:* (a) el inventario completo de lo adoptado con su
    justificación en una línea; (b) `docs/rechazos.md` integrado, con condiciones de
    revisión; (c) los riesgos reales encontrados —el cambio de la variable de bucle
    el primero— con cómo se verificaron; (d) el plan de despliegue: qué se
    despliega junto, qué se puede revertir y cómo; (e) los números de B-11 y B-12;
    (f) una sección de "qué haría distinto la próxima vez".
26. **El servicio bilingüe.** Consigue que la rama de 1.13 y la de Go moderno
    coexistan y sean comparables en caliente: los dos binarios corriendo a la vez
    contra la misma carga. *Rúbrica:* (a) los dos sirven la misma API y pasan la
    misma suite de contrato HTTP de la Fase 05; (b) mides latencia p50/p95/p99 y
    memoria de los dos bajo carga idéntica; (c) identificas al menos una diferencia
    de comportamiento —no solo de rendimiento— y explicas de qué salto viene; (d)
    documentas qué te dice este experimento sobre migrar un servicio de producción
    con despliegue gradual.

**🔥 Opcionales**

- Lee las notas de versión completas de 1.14 a 1.25 (https://go.dev/doc/devel/release)
  y haz tu propia lista de adopciones y rechazos. Son unas dos horas y es el
  ejercicio que más te va a servir en tu trabajo.
- Corre el fuzzer del parser durante diez minutos (`-fuzztime 10m`) y mira cuántos
  casos nuevos encuentra después de los primeros treinta segundos. La curva dice
  mucho sobre cuándo parar.
- Investiga `GOEXPERIMENT` y qué hay detrás hoy. Es la ventana a lo que viene, y
  saber mirarla te da un año de ventaja.

---

### 🔴 Desafíos de cierre

> Tres ejercicios de dificultad alta que **no cuentan en el total de la sección** y
> no son parte del recorrido base.

**D1 — Tu propio modernizador.**
Escribe una herramienta con `go/ast` y `golang.org/x/tools/go/analysis` que
sustituya una construcción antigua por su equivalente moderno **en todo el
repositorio**, de forma segura.
*Rúbrica:* (a) elige una sustitución concreta —`ioutil.ReadFile` → `os.ReadFile`, o
el `tt := tt` redundante—; (b) **no toca los casos donde la sustitución no es
equivalente**, y demuestras que los detecta; (c) produce un diff aplicable con
`-fix`, no reescribe a ciegas; (d) la corres sobre el código del curso y comparas
su salida con la de `gopls modernize`; (e) explicas por qué una herramienta de
reescritura automática **siempre** necesita revisión humana, con un caso concreto
donde la tuya se equivocaría.

**D2 — El módulo `v2`.**
Publica `internal/workitem` como un módulo independiente y llévalo a `v2` con un
cambio incompatible.
*Rúbrica:* (a) entiendes y aplicas la regla de la ruta de importación: `v2` va en la
ruta del módulo, no solo en el tag; (b) demuestras que `v1` y `v2` **pueden convivir
en el mismo binario**, que es una propiedad que Maven no tiene; (c) decides entre
las dos estrategias —subdirectorio `/v2` o rama— y justificas; (d) escribes la guía
de migración para un consumidor; (e) comparas con lo que exigiría el mismo cambio en
un artefacto Maven y dices cuál te parece mejor diseño.

**D3 — La arqueología de la variable de bucle.**
Usa `git bisect` y el compilador para encontrar, en las siete fases del Bloque A,
**todos** los sitios donde el cambio de Go 1.22 alteró el comportamiento.
*Rúbrica:* (a) construyes el procedimiento automático: compilar cada tag con
`go 1.21` y con `go 1.22` en el `go.mod` y comparar la salida de los tests; (b)
clasificas los hallazgos en las tres categorías de §6.4; (c) encuentras —o
demuestras que no existe— el caso donde el código **dependía** del comportamiento
antiguo; (d) explicas por qué el equipo de Go pudo hacer este cambio sin romper la
promesa de compatibilidad, y qué mecanismo lo permitió; (e) dices qué otro cambio
del lenguaje podría hacerse con el mismo mecanismo, y cuál no.

---

## 📚 9. Referencias

### Documentación oficial

- **Release History** — https://go.dev/doc/devel/release — **el documento central
  de esta fase.** Cada versión con sus cambios. Se lee por saltos.
- **Go 1 and the Future of Go Programs** — https://go.dev/doc/go1compat — la
  promesa de compatibilidad. Explica qué garantiza y qué no, y por qué esta
  migración fue tan barata.
- **Notas por versión, las que más importan aquí:**
  https://go.dev/doc/go1.16 (`embed`, `os.ReadFile`, módulos por defecto) ·
  https://go.dev/doc/go1.18 (genéricos, fuzzing, workspaces) ·
  https://go.dev/doc/go1.21 (`slog`, `slices`, `maps`, `toolchain`) ·
  https://go.dev/doc/go1.22 (`ServeMux`, variable de bucle, `math/rand/v2`) ·
  https://go.dev/doc/go1.23 (iteradores, `unique`) ·
  https://go.dev/doc/go1.24 (`go tool`, `testing.B.Loop`, `synctest`)
- **Tutorial: Generics** — https://go.dev/doc/tutorial/generics
- **An Introduction To Generics** — https://go.dev/blog/intro-generics — oficial, y
  la sección *When To Use Generics* es la que sostiene §6.2.
- **Go Fuzzing** — https://go.dev/doc/security/fuzz/ — la guía oficial completa.
- **`log/slog`** — https://pkg.go.dev/log/slog y https://go.dev/blog/slog
- **Routing Enhancements for Go 1.22** — https://go.dev/blog/routing-enhancements —
  el artículo del `ServeMux` nuevo, con las reglas de precedencia.
- **Fixing For Loops in Go 1.22** — https://go.dev/blog/loopvar-preview — **léelo
  entero antes del salto 1.22.** Explica el cambio, cómo se evaluó su riesgo, y el
  mecanismo de compatibilidad por módulo.
- **Range Over Function Types** — https://go.dev/blog/range-functions — los
  iteradores explicados por quien los diseñó.
- **Workspaces tutorial** — https://go.dev/doc/tutorial/workspaces
- **`golang.org/x/sync`** — https://pkg.go.dev/golang.org/x/sync/errgroup

### Libros

- **Learning Go (2ª edición)** — Jon Bodner. **Es el libro del Bloque C.** Cubre
  genéricos, `slog`, iteradores y el Go moderno con el nivel de detalle adecuado
  para este perfil.
- **100 Go Mistakes** — Harsanyi. Los errores sobre genéricos (#9) y sobre
  `context` siguen vigentes.
- **Effective Go** — sigue siendo válido y **no cubre nada posterior a 2012**.
  Saberlo es importante: es el documento oficial más citado y el más fechado.

### Artículos y charlas

- **When To Use Generics** — Ian Lance Taylor, https://go.dev/blog/when-generics —
  **la lectura obligatoria de §6.2.** Escrito por el diseñador, y es sorprendentemente
  restrictivo: la recomendación oficial se parece mucho a la de este curso.
- **Why Generics?** — https://go.dev/blog/why-generics — el porqué, antes del cómo.
- **Structured Logging with slog** — https://go.dev/blog/slog
- **Fuzzing is Beta Ready** / **Go Fuzzing** — https://go.dev/blog/fuzz-beta
- **Backward Compatibility, Go 1.21, and Go 2** — Russ Cox,
  https://go.dev/blog/compat — **el mejor texto que existe sobre cómo evolucionar
  un lenguaje sin romper a nadie**, y explica el mecanismo de la directiva `go` del
  `go.mod` que sostuvo todo el Bloque A.
- **Go Modules Reference: go.work** — https://go.dev/ref/mod#workspaces

### Video

- **GopherCon: Generics in Go** — busca las charlas de Ian Lance Taylor y de
  Robert Griesemer de 2021–2022.
- **GopherCon: Range Over Func** — sobre iteradores, posterior a 2023.
- **Russ Cox sobre compatibilidad** — cualquier charla suya sobre la evolución de
  Go; el tema del `go.mod` como declaración de época aparece siempre.

> ⚠️ **La advertencia más importante de esta fase.** Todo el contenido sobre Go
> anterior a marzo de 2022 **no conoce los genéricos**; el anterior a agosto de
> 2023, no conoce `slog`; el anterior a febrero de 2024, da por hecho que
> necesitas un enrutador de terceros. Un artículo que dice *"en Go tendrás que
> repetir esta función para cada tipo"* no está mintiendo: está fechado. **A
> partir de esta fase, verifica la fecha de todo lo que leas sobre Go.**

### Orden de lectura sugerido

**Antes de migrar:** *Go 1 and the Future of Go Programs* y *Backward
Compatibility, Go 1.21, and Go 2* de Russ Cox. Los dos juntos son una hora y
explican por qué esta migración es barata y por qué el `go.mod` declara época.
**Durante:** las notas de cada versión según llegues a su salto, y
*Fixing For Loops in Go 1.22* **antes** de tocar los `tt := tt`.
**Después:** *When To Use Generics* de Ian Lance Taylor, con calma, y después
relee tu propio `docs/rechazos.md`. Si tu lista de rechazos y la recomendación
oficial se parecen, vas bien.

---

## ⚖️ 10. Veredicto y cierre

### ⚖️ Cuándo NO usar esto

Sobre migrar, y sobre adoptar:

- **No migres si no tienes suite de tests.** En serio. La promesa de
  compatibilidad de Go hace que la migración sea segura *en el compilador*; lo que
  cambia comportamiento —la variable de bucle, la precedencia del `ServeMux`, el
  orden de `map` que nunca fue estable— solo lo atrapan los tests. Un servicio sin
  tests migra bien el 95% de las veces, y el 5% restante es una noche mala.
- **No adoptes genéricos en la capa de datos.** Es el error más caro de esta fase
  y el más tentador para quien viene de Spring Data. Está en `docs/rechazos.md` con
  su condición de revisión.
- **No migres y refactorices a la vez.** La autopsia entera va de esto.
- **No adoptes `slog` si tu log solo lo lee un humano en una terminal.** Una
  herramienta de línea de comandos con salida para personas está mejor con `fmt`.
  `slog` gana cuando hay un agregador detrás, y si no lo hay, es ceremonia.
- **Y no adoptes los iteradores por elegancia.** Un slice de cien elementos con
  `len()` e indexación es mejor que un `iter.Seq` que hay que materializar en la
  mitad de los consumidores. Los iteradores son para lo que no cabe en memoria.

Y una reflexión honesta sobre el resultado, que hay que hacer mirando B-11: **el
binario creció y el rendimiento en reposo apenas cambió.** Lo que ganaste con esta
migración no son milisegundos: son sesenta líneas de enrutador que ya no
mantienes, un logger que se puede consultar, un binario autosuficiente, un parser
al que un fuzzer le encontró un bug, y una plantilla de decodificación en vez de
cinco copias. **Todo eso es mantenimiento, y el mantenimiento es donde se va el
dinero de verdad.** Si alguien te pide justificar una migración con un gráfico de
latencia, la respuesta honesta es que ese no es el argumento.

### 📖 Diccionario Java ⇄ Go de esta fase

| Java | Go | Dónde se rompe la equivalencia |
|---|---|---|
| `<release>17</release>` en el POM | directiva `go 1.25` en el `go.mod` | **Mismo propósito y más fuerte**: en Go limita también qué API de la stdlib está disponible |
| `--enable-preview` | `GOEXPERIMENT` | Similar en intención; en Go casi nunca hace falta tocarlo |
| `mvnw` / `gradlew` (wrapper) | directiva `toolchain` | El toolchain se descarga solo si falta. Sin script que commitear |
| POM padre con `<modules>` | `go.work` | Sin herencia de configuración: solo una lista de directorios |
| `javax` → `jakarta` | *(no existe equivalente)* | Go **no ha tenido** una ruptura de ese calibre desde 1.0. Es una ventaja genuina |
| Java 9: módulos y encapsulación de internos | *(no aplica)* | `internal/` lleva ahí desde 1.4 y no cambió |
| `List.of` / `var` / *records* / `sealed` | genéricos, `slices`, `maps` | Go llegó tarde a los genéricos (2022) y con un diseño más restrictivo a propósito |
| Generics de Java (borrado de tipos) | genéricos de Go (*stenciling*/*gcshape*) | **No hay borrado**: el tipo está disponible en ejecución. Sin comodines (`? extends`), sin genéricos en métodos de un tipo genérico |
| `Comparator.comparing().thenComparing()` | `cmp.Or(cmp.Compare(...), ...)` | Mismo modelo de tres estados. Go añadió esta forma con los genéricos; antes era booleana |
| Recursos en el JAR + `getResourceAsStream` | `//go:embed` | **Falla en compilación** si el archivo no existe, en vez de devolver `null` en ejecución |
| SLF4J + Logback | `log/slog` | Una sola fachada oficial en la stdlib, sin *bindings* ni conflictos de classpath |
| MDC | `logger.With(...)` derivado y pasado por parámetro | Explícito, no implícito por hilo |
| `@SuppressWarnings("removal")` | *(nada)* | Las APIs obsoletas de Go siguen funcionando indefinidamente; solo las marcan los linters |
| jqwik / Jazzer | `testing.F` | **En el toolchain.** El corpus descubierto se commitea y se convierte en regresión |
| `CompletableFuture.allOf` + manejo de error | `errgroup.Group` con `SetLimit` | `errgroup` cancela el contexto derivado en cuanto una falla; `allOf` no |
| ADR (*architecture decision record*) | `docs/rechazos.md` | Misma práctica. Aquí con condición de revisión obligatoria |
| `mvn versions:display-dependency-updates` | `go list -m -u all` | Mismo propósito |

### Qué sigue

**Empieza el Bloque C, y con él el Go que de verdad vas a escribir.**

La Fase 09 es la más larga del curso (9 h) y trae la persistencia real:
`database/sql` explicado por lo que es —**un pool, no una conexión**—, `pgx` en
modo nativo, transacciones con `defer tx.Rollback()` como patrón, migraciones
versionadas con `goose`, paginación por cursor frente a `OFFSET`, y
`SELECT ... FOR UPDATE SKIP LOCKED` para la cola de EventRelay, que es la joya de
la fase y paga dos deudas de la Fase 06 de una vez.

Con el debate del ORM resuelto con los tres competidores medidos —SQL a mano,
`sqlc` y `GORM`— y el veredicto: **en Go la propagación transaccional es un
parámetro, no una anotación**, y eso se paga en verbosidad y se cobra en que nunca
te preguntas si esta llamada está dentro de una transacción.

Y **ClearingHouse nace**: el agente de tienda, como herramienta de línea de
comandos, con su SQLite embebido que sobrevive sin red.

### La señal de que quedó bien

> *"Miro el `--stat` de mi migración y hay más líneas borradas que añadidas. Y
> cuando alguien me pregunta por qué no usé el `Repository[T]` genérico, tengo un
> documento con la respuesta y con la condición que me haría cambiar de opinión."*

Si tu migración añadió código neto, párate y mira qué. Casi siempre es una
abstracción que la novedad del lenguaje hizo *posible* y que nadie había pedido.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en
> verde, `go test -shuffle=on -race -count=3 ./...` en verde, `golangci-lint run`
> limpio, `docs/rechazos.md` escrito y `git status` sin cambios pendientes:
>
> ```bash
> git tag -a fase-08 -m "F8 cerrada: OpsReport y EventRelay migrados a Go 1.25 salto por salto; go.work; embed de plantillas; slog; ServeMux de la stdlib sustituye a tiny-router; genéricos acotados; fuzzing del parser; errgroup; docs/rechazos.md; B-11 y B-12 medidos"
> git tag -a opsreport/v0.8 -m "OpsReport: migrado a Go moderno"
> git tag -a eventrelay/v0.7 -m "EventRelay: migrado a Go moderno"
> ```
>
> Y el comando que te va a servir el resto del curso:
> ```bash
> git diff bloque-a-completo fase-08 --stat
> git diff bloque-a-completo fase-08 -- services/opsreport/internal/httpapi/
> ```
>
> Los commits de la fase llevan su prefijo (`fase 08: …`) y los de ejercicio su
> número (`fase 08 ej23: …`). Todo eso está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).

---

# 📌 Bloque de autoría (fuera de lo que lee el estudiante)

## 📌 Pendientes sugeridos

- **`testing/synctest`** — evaluado y aplazado en §6.5 con revisión declarada en la
  **Fase 15**. **Verificar que la Fase 15 lo recoge**; si no, el aplazamiento queda
  huérfano y hay que quitarlo de `docs/rechazos.md` o resolverlo aquí.
- **`GOMEMLIMIT`** — introducido en §6.3 como contexto, configurado en la **Fase
  14**, medido en **B-22 (Fase 15)**. Cadena verificada en los tres alcances.
- **`goleak`** — la Fase 07 dejó escrito que esta fase lo introduciría sustituyendo
  la implementación a mano, y **se cumple en §6.5**, con `VerifyTestMain` y la
  advertencia de que cada `Ignore...` es deuda. El valor didáctico depende de que
  el estudiante haya escrito antes el contador a mano: si se salta la Fase 07,
  `goleak` parece magia en vez de una mejora medible sobre algo propio. Cadena
  cerrada.
- **El tag `bloque-a-completo`** — la Fase 07 lo crea y esta fase lo usa dos veces
  (§6.7 y el cierre). **Sigue sin estar en `00-convencion-de-git-y-tags.md`.**
  Hay que añadirlo allí.
- **B-12 con tres variantes** — la Fase 05 propuso incluir el enrutador con árbol
  del ejercicio 23. Recogido en §6.4 y en el ejercicio 11.
- **`math/rand/v2` y el *jitter*** — adoptado aquí, se usa de verdad en la **Fase
  10** (retroceso exponencial con jitter). Verificar que allí se usa `rand/v2` y no
  el antiguo.
- **El patrón "handler que devuelve error"** — la Fase 05 lo propuso como
  candidato a ejercicio de esta fase (qué se adopta y qué se rechaza). **No se
  incluyó.** Candidato a séptimo ejercicio de "qué NO migrar" si se quiere ampliar.

## ☕ Reflejos para `INSTINTOS.md`

- **"Ya que migramos, arreglamos lo demás"** — el reflejo raíz de la fase. Coste
  medido: 340 archivos frente a 47, `git bisect` inutilizado, y la imposibilidad de
  separar qué rompió la migración de qué rompió el refactor. Antídoto: **una
  migración buena se lee en el `--stat`**.
- **"Los genéricos por fin permiten hacer `Repository<T>`"** — el ☕ más
  sofisticado que existe, porque ahora el compilador ayuda a construirlo.
  Antídoto: escribe la versión concreta primero; generaliza con el tercer caso
  delante.
- **"Modernizar es sustituir lo viejo por lo nuevo"** — el `ValidationError` que
  no se sustituye por `errors.Join` es el ejemplo del curso.
- **"Los tests hay que adaptarlos a la migración"** — si migrar obliga a cambiar
  180 tests, reescribiste.
- **"El compilador nuevo acepta la API nueva"** — no: la directiva `go` del
  `go.mod` manda. Es lo que sostuvo el Bloque A entero.

## 📐 Mediciones para `BENCHMARKS.md`

- **B-11 — El mismo servicio en 1.13 y en Go moderno.** ⚠️ **La hipótesis tiene que
  declararse incómoda a propósito**: *"el binario será más grande y el arranque y
  la memoria serán similares"*. Es la entrada donde `prompts/formato-de-benchmarks.md` §3
  regla 5 —*"se publica el resultado incómodo"*— tiene más filo: si el resultado es
  "no mejoró nada medible", **esa es la entrada que hay que escribir**, y el
  veredicto tiene que decir que el argumento de la migración es de mantenimiento,
  no de rendimiento.
- **B-12 — `ServeMux` moderno frente al enrutado a mano.** Tres variantes (lineal,
  árbol propio, `ServeMux`) × tres tamaños (5, 50, 200 rutas). **El resultado
  esperado con 5 rutas es indistinguible**, y el veredicto debe decirlo antes que
  cualquier otra cosa: la razón para adoptar no es el rendimiento.
- Anotado para la Fase 15: el coste del middleware por petición (propuesto por la
  Fase 05 sin ID) sigue sin asignar. Con el banco de pruebas de la Fase 15 montado,
  es barato y desmonta una preocupación habitual.
