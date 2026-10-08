# 🧪 Fase 04 — Testing idiomático, dobles y cobertura

> Go para desarrolladores Java senior · Fase 4 de 17 · **8 horas**
> Época: **Go 1.13 (stdlib pura)**
> Depende de: Fase 03 · Habilita: Fase 05
> Proyectos que avanzan: **OpsReport** y **EventRelay** (suites unitarias completas)
> Mini proyectos: `validator-tests`, `fake-clock`, `golden-report`

---

## 🎯 1. Propósito

Llevamos tres fases verificando el código mirando la pantalla. Esa deuda 💸 se
paga hoy, entera.

Pero esta fase no va solo de escribir tests. Va de instalar **el régimen de
pruebas del curso**, que a partir de aquí deja de ser una fase y pasa a ser una
condición: todo código que se escriba llega con sus pruebas, `go test -race ./...`
se corre por reflejo antes de abrir un PR, y la cobertura se mide con umbral.

Y va de algo más, que para alguien que viene de Java es casi contracultural:
**vas a ver que no necesitabas Mockito.** Un `FakeClock` de ocho líneas y un
`FakeStore` de veinte cubren todo lo que hemos escrito en tres fases. El generador
de mocks llega en la Fase 10, cuando la interfaz del cliente HTTP lo justifique, y
allí se explicará por qué tarda tanto.

---

## ✅ 2. Qué queda listo al terminar

- [ ] `go1.13 test ./...` corre en verde en los dos módulos y ya no dice
      `[no test files]` en ningún paquete de `internal/`.
- [ ] `workitem` tiene su suite de tabla: validación, máquina de estados y
      prioridad efectiva, con subtests nombrados por comportamiento.
- [ ] `opsreport.Service` se prueba contra `FakeStore`, `FakeClock` y
      `FakeIDGenerator` escritos a mano, sin ninguna librería de mocking.
- [ ] `relay` tiene su suite: `Endpoint.Matches`, la máquina de estados de
      `Delivery` y la política de reintentos.
- [ ] `labs/golden-report` compara contra un archivo esperado y se actualiza con
      `-update`.
- [ ] `make cover` produce el informe y el total; el umbral del curso —**80% en
      `internal/`**— se cumple o se justifica.
- [ ] `go1.13 test -race ./...` pasa (todavía no hay concurrencia, pero el hábito
      se instala hoy).
- [ ] El `main` de OpsReport que verificaba por pantalla ha desaparecido, y su
      contenido vive en tests.

---

## 🚫 3. Qué NO entra todavía

- **Mocks generados** → Fase 10. Y la razón está escrita: hasta que no haya que
  verificar *interacciones* —"reintentó exactamente tres veces"—, el fake gana.
- Tests HTTP con `httptest` → Fase 05, donde habrá handlers que probar.
- Tests de integración con contenedores → Fase 09, con `testcontainers-go`.
- Fuzzing con `testing.F` → Fase 08 🕰️ (Go 1.18). Se aplicará al parser de
  movimientos y al verificador de firmas.
- `t.Setenv` → Fase 08 🕰️ (Go 1.17). Aquí la manipulación del entorno se hace a
  mano con `os.Setenv` y `t.Cleanup`, que además enseña por qué `t.Setenv`
  existe.
- `testify` → Fase 09, y **acotado a los tests de integración**. Aquí las
  aserciones son `if got != want { t.Errorf(...) }`, que es la forma por defecto
  del curso.
- `goleak` para detectar fugas de goroutines → Fase 07 lo hace a mano, Fase 08
  introduce la librería.

---

## 🧠 4. Concepto mínimo

### El paquete `testing`, en tres reglas

**1. Un test es una función.** Sin anotaciones, sin clase, sin runner externo:

```go
func TestValidate_RejectsEmptyExternalReference(t *testing.T) {
	item := workitem.WorkItem{Kind: workitem.KindImport, Priority: 3}

	err := item.Validate()

	if err == nil {
		t.Fatal("se esperaba un error de validación, no llegó ninguno")
	}
}
```

Se llama `TestXxx`, recibe `*testing.T`, y vive en un archivo `_test.go`. El
comando `go test` compila esos archivos aparte, los enlaza con el paquete y corre
lo que encuentra.

**2. No hay aserciones, y es deliberado.**

```go
if got != want {
	t.Errorf("EffectivePriority() = %d, quería %d", got, want)
}
```

Viniendo de AssertJ esto parece pobre, y el argumento del equipo de Go es que
**`if` es el mismo `if` que usas en el código de producción**: no hay una DSL que
aprender, no hay dos niveles de abstracción, y el mensaje de error lo escribes tú
diciendo exactamente lo que hace falta para depurar.

El formato del mensaje es convención: **`función() = obtenido, quería esperado`**,
en ese orden. Lo vas a ver en toda la stdlib y hay que sostenerlo, porque un
mensaje al revés te hace perder diez minutos en cada fallo.

**3. `t.Error` continúa, `t.Fatal` aborta.** `Errorf` marca el test como fallido y
sigue ejecutando; `Fatalf` marca y sale de la función inmediatamente. La regla
práctica: **`Fatal` cuando seguir no tiene sentido** (el objeto que ibas a
inspeccionar es nulo), **`Error` cuando quieres ver todos los fallos de una vez**.

> ⚠️ `t.Fatal` **solo puede llamarse desde la goroutine del test**. Desde una
> goroutine lanzada dentro del test, `Fatal` no aborta el test: mata solo esa
> goroutine y el test sigue, normalmente hasta un `panic` confuso. Volveremos sobre
> esto en la Fase 06, que es donde muerde.

### Tests de tabla: el idioma del lenguaje

Esto es lo que en Java sería `@ParameterizedTest` con `@CsvSource`, y en Go es
simplemente un slice recorrido con un bucle:

```go
func TestEffectivePriority(t *testing.T) {
	created := time.Date(2026, 9, 1, 10, 0, 0, 0, time.UTC)

	// La tabla es un slice de structs anónimos. El primer campo se llama `name`
	// por convención y es lo que aparece en la salida del test.
	tests := []struct {
		name     string
		priority workitem.Priority
		status   workitem.Status
		now      time.Time
		want     workitem.Priority
	}{
		{
			name:     "recién creado conserva su prioridad",
			priority: 3,
			status:   workitem.StatusQueued,
			now:      created.Add(2 * time.Hour),
			want:     3,
		},
		{
			name:     "sube un punto por día completo esperando",
			priority: 3,
			status:   workitem.StatusQueued,
			now:      created.AddDate(0, 0, 4),
			want:     7,
		},
		{
			name:     "nunca supera el máximo",
			priority: 8,
			status:   workitem.StatusQueued,
			now:      created.AddDate(0, 0, 30),
			want:     workitem.MaxPriority,
		},
		{
			name:     "un trabajo en curso no envejece",
			priority: 3,
			status:   workitem.StatusRunning,
			now:      created.AddDate(0, 0, 10),
			want:     3,
		},
	}

	for _, tt := range tests {
		tt := tt // 🕰️ imprescindible en 1.13: la variable del bucle se comparte
		t.Run(tt.name, func(t *testing.T) {
			item := workitem.WorkItem{
				Priority:  tt.priority,
				Status:    tt.status,
				CreatedAt: created,
			}

			got := item.EffectivePriority(tt.now)

			if got != tt.want {
				t.Errorf("EffectivePriority(%v) = %d, quería %d", tt.now, got, tt.want)
			}
		})
	}
}
```

```bash
go1.13 test -v -run TestEffectivePriority ./internal/workitem
```

```text
=== RUN   TestEffectivePriority
=== RUN   TestEffectivePriority/recién_creado_conserva_su_prioridad
=== RUN   TestEffectivePriority/sube_un_punto_por_día_completo_esperando
=== RUN   TestEffectivePriority/nunca_supera_el_máximo
=== RUN   TestEffectivePriority/un_trabajo_en_curso_no_envejece
--- PASS: TestEffectivePriority (0.00s)
    --- PASS: TestEffectivePriority/recién_creado_conserva_su_prioridad (0.00s)
    ...
```

`t.Run` crea un **subtest** con nombre propio: aparece en la salida, se puede
ejecutar aislado (`-run 'TestEffectivePriority/nunca'`) y falla
independientemente de los demás.

> 🧭 **Regla del proyecto.** Todo test de más de un caso es de tabla, con `t.Run`
> y un nombre que **describe el comportamiento esperado**, no la función.
> `TestCreate_RejectsEmptyExternalReference`, no `TestCreate2`. El nombre del
> subtest se lee como una frase: *"sube un punto por día completo esperando"*.

> 🕰️ **`tt := tt` y por qué es obligatorio aquí.** En Go 1.13, la variable del
> bucle `for _, tt := range tests` es **una sola variable reutilizada** en cada
> iteración. Si la closure del subtest la captura y el subtest corre más tarde
> —con `t.Parallel()`—, todas las closures ven el último valor. La línea `tt := tt`
> crea una copia por iteración. **En Go 1.22 esto cambió**: la variable pasa a ser
> por iteración y la línea sobra. Es uno de los cambios más importantes de la Fase
> 08, y allí haremos el ejercicio de buscar en todo el código escrito hasta
> entonces dónde habría cambiado el comportamiento.

### `t.Helper`, `t.Cleanup` y `TestMain`

```go
// mustCreate construye un work item válido o falla el test. t.Helper() hace que,
// cuando este helper llame a t.Fatal, el número de línea reportado sea el del
// LLAMADOR y no el de esta función. Sin él, todos los fallos apuntan aquí.
func mustCreate(t *testing.T, svc *opsreport.Service, ref string) workitem.WorkItem {
	t.Helper()

	item, err := svc.Create(workitem.WorkItem{
		ExternalReference: ref,
		Kind:              workitem.KindImport,
		Priority:          5,
	})
	if err != nil {
		t.Fatalf("preparando el work item %s: %v", ref, err)
	}
	return item
}
```

```go
// t.Cleanup registra algo que se ejecuta al terminar el test, pase lo que pase.
// Es el @AfterEach de JUnit, pero mejor: se declara JUNTO a lo que hay que
// limpiar, no en un método aparte, y se puede registrar varias veces.
func newTempReportFile(t *testing.T) string {
	t.Helper()

	f, err := ioutil.TempFile("", "report-*.csv")
	if err != nil {
		t.Fatalf("creando archivo temporal: %v", err)
	}
	name := f.Name()
	f.Close()

	t.Cleanup(func() { os.Remove(name) })
	return name
}
```

> 🩻 **Esto sí funciona igual.** La idea de `@BeforeEach`/`@AfterEach` se traslada;
> lo que cambia es que en Go es **una función normal que llamas** en vez de un
> método que el framework invoca por ti. Y eso tiene una ventaja concreta: el
> orden de ejecución es el orden del código, no el que decida el framework, y no
> hay herencia de clases de test que resolver mentalmente.

`TestMain` es el gancho para la preparación de **todo el paquete**:

```go
// TestMain corre una vez por paquete, antes y después de todos los tests.
// Aquí es donde en la Fase 09 arrancaremos el contenedor de PostgreSQL.
func TestMain(m *testing.M) {
	// preparación global

	code := m.Run()

	// limpieza global — ojo: os.Exit NO ejecuta los defer, así que la limpieza
	// va antes, explícita.
	os.Exit(code)
}
```

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El instinto:** *"hay que mockear el almacén"*. Es el primer movimiento en Java y
está bien fundado: las dependencias son clases concretas, el contenedor las
inyecta, y crear una implementación falsa a mano significaría implementar una
interfaz de quince métodos. Mockito existe porque ese problema es real.

**Qué pasa si lo aplicas aquí.** Traes el reflejo, buscas "mock library go" y
llegas a `gomock` o a `testify/mock`. Y escribes esto:

```go
// ☕ — el reflejo de Mockito, trasladado
func TestCreate_SavesTheItem(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockStore := mocks.NewMockStore(ctrl)
	mockClock := mocks.NewMockClock(ctrl)
	mockIDs := mocks.NewMockIDGenerator(ctrl)

	mockIDs.EXPECT().NewID().Return("WI-0001").Times(1)
	mockClock.EXPECT().Now().Return(fixedTime).Times(1)
	mockStore.EXPECT().
		Save(gomock.Any()).
		DoAndReturn(func(item workitem.WorkItem) error {
			if item.ID != "WI-0001" {
				t.Errorf("se guardó con ID %q", item.ID)
			}
			return nil
		}).
		Times(1)

	svc := opsreport.New(mockStore, mockClock, mockIDs)

	got, err := svc.Create(validItem())
	// ...
}
```

Doce líneas de configuración antes de la primera línea de lógica, un paso de
generación de código en el `Makefile`, y un test que verifica **que se llamó a
`Save`**, no que el item quedó guardado.

**Compara con el fake.** Esto es el equivalente completo:

```go
// internal/opsreport/fakes_test.go

// fakeStore es un almacén en memoria para los tests. Veinte líneas, un mapa
// dentro, comportamiento real.
type fakeStore struct {
	items   map[string]workitem.WorkItem
	saveErr error // para forzar el camino de error cuando haga falta
}

func newFakeStore() *fakeStore {
	return &fakeStore{items: make(map[string]workitem.WorkItem)}
}

func (s *fakeStore) Save(item workitem.WorkItem) error {
	if s.saveErr != nil {
		return s.saveErr
	}
	s.items[item.ID] = item
	return nil
}

func (s *fakeStore) FindByID(id string) (workitem.WorkItem, error) {
	item, ok := s.items[id]
	if !ok {
		return workitem.WorkItem{}, memstore.ErrNotFound
	}
	return item, nil
}

func (s *fakeStore) ListByStatus(status workitem.Status) ([]workitem.WorkItem, error) {
	var out []workitem.WorkItem
	for _, item := range s.items {
		if item.Status == status {
			out = append(out, item)
		}
	}
	return out, nil
}

func (s *fakeStore) Update(item workitem.WorkItem) error {
	if _, ok := s.items[item.ID]; !ok {
		return memstore.ErrNotFound
	}
	s.items[item.ID] = item
	return nil
}
```

```go
func TestCreate_SavesTheItem(t *testing.T) {
	store := newFakeStore()
	svc := opsreport.New(store, fixedClock(created), &seqIDs{})

	got, err := svc.Create(validItem())
	if err != nil {
		t.Fatalf("Create() error = %v", err)
	}

	// Se verifica el ESTADO, no la interacción: el item está guardado y es el
	// que esperábamos.
	saved, err := store.FindByID(got.ID)
	if err != nil {
		t.Fatalf("el item no quedó guardado: %v", err)
	}
	if saved.Status != workitem.StatusQueued {
		t.Errorf("Status = %q, quería %q", saved.Status, workitem.StatusQueued)
	}
	if saved.CreatedAt != created {
		t.Errorf("CreatedAt = %v, quería %v", saved.CreatedAt, created)
	}
}
```

**Las cuentas, sobre este código real:**

| | Con mock generado | Con fake |
|---|---|---|
| Líneas de preparación **por test** | 12 | 2 |
| Líneas totales del doble | 0 propias + ~180 generadas | 32, escritas una vez |
| Pasos en el build | `go generate` + revisar generados | ninguno |
| Qué verifica | que se llamó a `Save` | que el item **quedó** guardado |
| Qué pasa al añadir un método a la interfaz | regenerar | el compilador te dice dónde |

**Qué pensar en su lugar:** *"¿qué comportamiento quiero verificar?"*. Si la
respuesta es **el resultado** —el item quedó guardado, la entrega pasó a `dead`,
el reporte tiene tres filas—, un fake es más simple y prueba más. Si la respuesta
es **la interacción** —"se reintentó exactamente tres veces, no cuatro"—, ahí el
fake se queda corto y el mock generado se gana el sitio. **Ese caso llega en la
Fase 10**, con el cliente HTTP, y no antes.

> 🧭 **Regla del proyecto: el orden de los dobles es función → fake → generado.**
> Se sube un escalón solo cuando el anterior no alcanza, y se justifica el salto.

### El doble más barato: una función

Antes incluso del fake, está esto:

```go
// clockFunc adapta una función a la interfaz Clock. Es el mismo truco que
// NotifierFunc de la Fase 02 y que http.HandlerFunc de la Fase 05.
type clockFunc func() time.Time

func (f clockFunc) Now() time.Time { return f() }

// Y en el test:
fixed := clockFunc(func() time.Time { return created })
svc := opsreport.New(store, fixed, ids)
```

Tres líneas, una vez, y cualquier test puede fabricar el reloj que quiera en una
línea. **Si la dependencia es una operación, el doble es una función.** Go no
necesita una clase para eso.

### 🩻 Esto sí funciona igual

- **La pirámide de pruebas** es la misma: muchos unitarios rápidos, menos de
  integración, poquísimos de punta a punta. La estructura de la Fase 09 y la 10
  la respeta.
- **Los tests parametrizados** son la misma idea que `@ParameterizedTest`; cambia
  la sintaxis, no el concepto.
- **Nombrar el test por el comportamiento** es buena práctica en los dos
  lenguajes, y aquí es igual de importante.
- **Los golden files** son la misma técnica de *approval testing* que ya conoces;
  la única novedad es que en Go es tan barata que se usa más.
- **La cobertura mide líneas ejecutadas, no comportamiento verificado.** JaCoCo y
  `go tool cover` tienen exactamente la misma limitación y merecen exactamente la
  misma desconfianza.
- **Preparar datos con un helper** es el mismo patrón que un *object mother* o un
  *test data builder*. Aquí son funciones, no clases.

---

## 🛠️ 5. CLI de la fase

```bash
# Lo básico: corre todos los tests del módulo. Sin salida por test si pasan.
go1.13 test ./...

# -v muestra cada test y cada subtest. Úsalo cuando algo falle, no siempre:
# con cien tests la salida deja de ser legible.
go1.13 test -v ./internal/workitem

# -run filtra por expresión regular sobre el nombre. La barra separa niveles de
# subtest, así que se puede bajar a un caso concreto de la tabla.
go1.13 test -run TestEffectivePriority ./...
go1.13 test -run 'TestEffectivePriority/nunca_supera' ./internal/workitem

# -count=1 desactiva el CACHÉ de resultados. Go no vuelve a correr un test si
# nada cambió, y reimprime "(cached)". En CI da igual; depurando, es una tortura.
go1.13 test -count=1 ./...

# El detector de carreras. Todavía no hay concurrencia, pero el hábito se instala
# hoy: a partir de la Fase 06 esto es obligatorio antes de cada PR.
go1.13 test -race ./...

# -failfast para en el primer fallo. Útil con una suite grande y un cambio que
# rompió muchas cosas.
go1.13 test -failfast ./...

# -timeout mata la suite si se cuelga. El valor por defecto son 10 minutos; en un
# test que espera un canal que nadie cierra, bajarlo ahorra mucho tiempo.
go1.13 test -timeout 30s ./...

# -shuffle no existe en 1.13 🕰️ (llegó en Go 1.17). Hasta entonces, el orden de
# los tests dentro de un paquete es el del archivo, y los tests que dependen del
# orden no se detectan solos.

# COBERTURA
# -coverprofile escribe el perfil; -covermode=atomic es el modo correcto cuando
# hay concurrencia (cuenta con operaciones atómicas en vez de con un contador
# normal, que tendría carreras).
go1.13 test -race -covermode=atomic -coverprofile=cover.out ./...

# Resumen por función, con el total en la última línea.
go1.13 tool cover -func=cover.out
go1.13 tool cover -func=cover.out | tail -n 1

# El informe HTML: abre el navegador con el código coloreado. Verde = cubierto,
# rojo = no cubierto. Es la herramienta que de verdad se usa.
go1.13 tool cover -html=cover.out

# BENCHMARKS (los vimos en la Fase 01, aquí solo el recordatorio)
go1.13 test -run '^$' -bench . -benchmem ./...

# Y el comando que responde "¿qué tests hay?" sin correrlos.
go1.13 test -list '.*' ./internal/opsreport
```

> 💡 **`-covermode` tiene tres valores y solo dos se usan.** `set` (por defecto)
> registra si la línea se ejecutó; `count` cuenta cuántas veces; `atomic` es como
> `count` pero seguro con goroutines. **Usa siempre `atomic` cuando combines
> `-race` y cobertura**, o los contadores de cobertura provocan carreras que el
> detector va a reportar — y ese sería un falso positivo especialmente confuso.

---

## 💻 6. Construcción guiada

### 6.1 Mini proyecto: `validator-tests`

El laboratorio que compara lado a lado lo que en JUnit serían veinte métodos.
Tomamos la validación de `WorkItem` de la Fase 03.

**Lo que sería en Java** (para tenerlo delante, no para escribirlo):

```java
@ParameterizedTest
@CsvSource({
    "'',           import,          3, external_reference",
    "SAP-1,        cosa_rara,       3, kind",
    "SAP-1,        import,          0, priority",
    "SAP-1,        import,         10, priority"
})
void rejectsInvalidWorkItems(String ref, String kind, int prio, String expectedField) {
    var item = new WorkItem(ref, Kind.valueOf(kind), prio);
    var ex = assertThrows(ValidationException.class, item::validate);
    assertThat(ex.getFields()).contains(expectedField);
}
```

**Y en Go:**

```go
// labs/validator-tests/validate_test.go
package validator_test

import (
	"errors"
	"strings"
	"testing"

	"github.com/meridian/opsreport/internal/workitem"
)

func TestValidate(t *testing.T) {
	tests := []struct {
		name       string
		item       workitem.WorkItem
		wantFields []string // vacío = se espera que sea válido
	}{
		{
			name: "un work item completo es válido",
			item: workitem.WorkItem{
				ExternalReference: "SAP-2026-000123",
				Kind:              workitem.KindImport,
				Priority:          3,
			},
		},
		{
			name: "sin referencia externa",
			item: workitem.WorkItem{
				Kind:     workitem.KindImport,
				Priority: 3,
			},
			wantFields: []string{"external_reference"},
		},
		{
			name: "la referencia en blanco cuenta como vacía",
			item: workitem.WorkItem{
				ExternalReference: "   \t  ",
				Kind:              workitem.KindImport,
				Priority:          3,
			},
			wantFields: []string{"external_reference"},
		},
		{
			name: "tipo de trabajo desconocido",
			item: workitem.WorkItem{
				ExternalReference: "SAP-2026-000123",
				Kind:              workitem.Kind("limpieza_general"),
				Priority:          3,
			},
			wantFields: []string{"kind"},
		},
		{
			name: "prioridad por debajo del mínimo",
			item: workitem.WorkItem{
				ExternalReference: "SAP-2026-000123",
				Kind:              workitem.KindImport,
				Priority:          0,
			},
			wantFields: []string{"priority"},
		},
		{
			name: "prioridad por encima del máximo",
			item: workitem.WorkItem{
				ExternalReference: "SAP-2026-000123",
				Kind:              workitem.KindImport,
				Priority:          10,
			},
			wantFields: []string{"priority"},
		},
		{
			name: "descripción de más de 500 caracteres",
			item: workitem.WorkItem{
				ExternalReference: "SAP-2026-000123",
				Kind:              workitem.KindImport,
				Priority:          3,
				Description:       strings.Repeat("ó", 501), // 501 runas, 1002 bytes
			},
			wantFields: []string{"description"},
		},
		{
			name:       "todos los campos mal a la vez se reportan juntos",
			item:       workitem.WorkItem{Priority: 99},
			wantFields: []string{"external_reference", "kind", "priority"},
		},
	}

	for _, tt := range tests {
		tt := tt
		t.Run(tt.name, func(t *testing.T) {
			err := tt.item.Validate()

			if len(tt.wantFields) == 0 {
				if err != nil {
					t.Fatalf("Validate() = %v, quería nil", err)
				}
				return
			}

			if err == nil {
				t.Fatalf("Validate() = nil, quería errores en %v", tt.wantFields)
			}

			var verr *workitem.ValidationError
			if !errors.As(err, &verr) {
				t.Fatalf("Validate() devolvió %T, quería *workitem.ValidationError", err)
			}

			got := fieldNames(verr)
			if !sameStrings(got, tt.wantFields) {
				t.Errorf("campos con error = %v, quería %v", got, tt.wantFields)
			}
		})
	}
}

// fieldNames extrae los nombres de campo del error de validación.
func fieldNames(verr *workitem.ValidationError) []string {
	names := make([]string, 0, len(verr.Fields))
	for _, f := range verr.Fields {
		names = append(names, f.Field)
	}
	return names
}

// sameStrings compara dos slices sin importar el orden.
// Nota: en la Fase 08, slices.Sort + reflect.DeepEqual, o mejor, un helper
// genérico. 🕰️ Aquí se escribe a mano, que son ocho líneas.
func sameStrings(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	counts := make(map[string]int, len(a))
	for _, s := range a {
		counts[s]++
	}
	for _, s := range b {
		counts[s]--
		if counts[s] < 0 {
			return false
		}
	}
	return true
}
```

**La comparación honesta:** el test de Go es más largo. Unas sesenta líneas de
tabla frente a diez de `@CsvSource`. A cambio:

- Los casos llevan **structs completos**, no cadenas que hay que parsear. El caso
  `"   \t  "` con espacios y tabuladores en un CSV es un dolor; aquí es literal.
- El nombre de cada caso es **una frase en español** que aparece en la salida, no
  el índice `[3]` que te da `@CsvSource`.
- No hay conversión de tipos por reflexión: si te equivocas de tipo, **no
  compila**.
- Y puedes poner en la tabla cosas que no caben en un CSV: slices, structs
  anidados, funciones.

El último caso —tres campos mal a la vez— es el que en Java necesitaría un
`@MethodSource` aparte, y aquí es una fila más.

### 6.2 Mini proyecto: `fake-clock`

Ocho líneas que se van a usar en los cuatro servicios del curso.

```go
// labs/fake-clock/clock.go
package clock

import "time"

// Clock entrega la hora actual. Se declara en cada paquete que la consume —es la
// regla de la Fase 02—, pero el fake se escribe una vez y sirve para todos,
// porque la interfaz es estructural.
type Clock interface {
	Now() time.Time
}

// System es el reloj real.
type System struct{}

func (System) Now() time.Time { return time.Now().UTC() }

// Fake es un reloj controlado por el test. No es seguro para uso concurrente;
// en la Fase 06, cuando los workers lo compartan, aprenderá a serlo.  💸
type Fake struct {
	current time.Time
}

// NewFake crea un reloj parado en el instante dado.
func NewFake(at time.Time) *Fake { return &Fake{current: at} }

func (f *Fake) Now() time.Time { return f.current }

// Advance mueve el reloj hacia adelante. Es lo que convierte "esperar cuatro
// días" en una línea de test que corre en microsegundos.
func (f *Fake) Advance(d time.Duration) { f.current = f.current.Add(d) }

// Set coloca el reloj en un instante concreto.
func (f *Fake) Set(t time.Time) { f.current = t }
```

Y su uso, que es donde se ve por qué la Fase 01 insistía tanto en no llamar a
`time.Now()` dentro de la lógica:

```go
func TestQueue_AgedItemsOvertakeRecentOnes(t *testing.T) {
	start := time.Date(2026, 9, 1, 8, 0, 0, 0, time.UTC)
	fake := clock.NewFake(start)

	store := newFakeStore()
	svc := opsreport.New(store, fake, &seqIDs{})

	// Un trabajo de prioridad baja, creado ahora.
	low, _ := svc.Create(itemWithPriority(2))

	// Cinco días después, uno de prioridad alta.
	fake.Advance(5 * 24 * time.Hour)
	high, _ := svc.Create(itemWithPriority(6))

	queue, err := svc.Queue()
	if err != nil {
		t.Fatalf("Queue() error = %v", err)
	}

	// El viejo envejeció de 2 a 7 y adelanta al nuevo, que sigue en 6.
	if queue[0].ID != low.ID {
		t.Errorf("primero de la cola = %s, quería %s (el envejecido)", queue[0].ID, low.ID)
	}
	_ = high
}
```

**Cinco días de espera, en un test que tarda microsegundos.** Sin `Thread.sleep`,
sin `Clock.fixed()` de `java.time`, sin `@MockBean`. Ocho líneas de fake.

> 🧭 **Regla del proyecto.** `time.Now()` **no aparece nunca** en código de
> dominio ni de servicio. El reloj es una dependencia y se inyecta. La única
> excepción es `main` y la implementación de `System`.

### 6.3 Mini proyecto: `golden-report`

La técnica de comparar contra un archivo esperado, que en Go es tan barata que se
usa mucho más que en Java.

```go
// labs/golden-report/report.go
package report

import (
	"fmt"
	"io"
	"sort"
)

// Row es una fila del reporte operativo.
type Row struct {
	Kind      string
	Status    string
	Count     int
	AvgSecs   float64
}

// WriteCSV escribe el reporte en formato CSV. Es la función bajo prueba: tiene
// formato, ordenación y redondeo, que es exactamente el tipo de salida donde un
// golden file gana a veinte aserciones.
func WriteCSV(w io.Writer, rows []Row) error {
	sorted := make([]Row, len(rows))
	copy(sorted, rows)
	sort.Slice(sorted, func(i, j int) bool {
		if sorted[i].Kind != sorted[j].Kind {
			return sorted[i].Kind < sorted[j].Kind
		}
		return sorted[i].Status < sorted[j].Status
	})

	if _, err := fmt.Fprintln(w, "kind,status,count,avg_seconds"); err != nil {
		return err
	}
	for _, r := range sorted {
		if _, err := fmt.Fprintf(w, "%s,%s,%d,%.2f\n",
			r.Kind, r.Status, r.Count, r.AvgSecs); err != nil {
			return err
		}
	}
	return nil
}
```

```go
// labs/golden-report/report_test.go
package report

import (
	"bytes"
	"flag"
	"io/ioutil"
	"path/filepath"
	"testing"
)

// update es una bandera propia del paquete de test. Con -update, el test
// REESCRIBE el archivo esperado en vez de comparar. Es el idioma estándar del
// ecosistema y lo usa la propia stdlib.
var update = flag.Bool("update", false, "reescribe los archivos golden")

func TestWriteCSV(t *testing.T) {
	rows := []Row{
		{Kind: "reconciliation", Status: "done", Count: 142, AvgSecs: 38.4517},
		{Kind: "import", Status: "failed", Count: 3, AvgSecs: 1.0},
		{Kind: "import", Status: "done", Count: 87, AvgSecs: 12.25},
		{Kind: "statement", Status: "queued", Count: 12, AvgSecs: 0},
	}

	var buf bytes.Buffer
	if err := WriteCSV(&buf, rows); err != nil {
		t.Fatalf("WriteCSV() error = %v", err)
	}

	golden := filepath.Join("testdata", "monthly_report.csv.golden")

	if *update {
		if err := ioutil.WriteFile(golden, buf.Bytes(), 0o644); err != nil {
			t.Fatalf("actualizando el golden: %v", err)
		}
		t.Logf("golden actualizado: %s", golden)
		return
	}

	want, err := ioutil.ReadFile(golden)
	if err != nil {
		t.Fatalf("leyendo el golden (¿falta correr con -update?): %v", err)
	}

	if !bytes.Equal(buf.Bytes(), want) {
		// El mensaje tiene que dar el diff, no solo "no son iguales". Con
		// salidas de texto, imprimir las dos es suficiente.
		t.Errorf("la salida no coincide con el golden\n--- obtenido ---\n%s\n--- esperado ---\n%s",
			buf.String(), want)
	}
}
```

```bash
# La primera vez, y cada vez que el formato cambie A PROPÓSITO:
go1.13 test -run TestWriteCSV -update ./labs/golden-report

# A partir de ahí:
go1.13 test ./labs/golden-report
```

> ⚠️ **El peligro del golden file.** Es tan cómodo actualizar con `-update` que la
> tentación es correrlo cada vez que el test falla, mirar el diff por encima y
> aceptar. Así es como un bug se convierte en el comportamiento esperado.
>
> **La regla del curso:** `-update` se corre cuando el cambio de formato es
> **deliberado**, y el diff del archivo golden **se revisa en el PR como código**.
> Si el golden cambia y nadie sabe por qué, el PR no entra.

> 🧪 **Prueba de fuego.** Cambia `%.2f` por `%.3f` en `WriteCSV` y corre el test
> sin `-update`. Vas a ver el diff exacto, con las dos versiones completas.
> **La mentira de la pantalla:** si tu golden tiene finales de línea de Windows y
> tu máquina escribe Unix, el test falla con dos salidas que en pantalla se ven
> idénticas. Configura `.gitattributes` con `*.golden -text` para que Git no
> traduzca finales de línea en esos archivos.

### 6.4 OpsReport: la suite completa

Aquí muere el `main` que verificaba por pantalla. Su contenido se reparte en tests.

```go
// services/opsreport/internal/opsreport/service_test.go
package opsreport_test  // ← paquete _test externo: ver la nota de abajo

import (
	"errors"
	"testing"
	"time"

	"github.com/meridian/opsreport/internal/memstore"
	"github.com/meridian/opsreport/internal/opsreport"
	"github.com/meridian/opsreport/internal/workitem"
)

var created = time.Date(2026, 9, 11, 9, 0, 0, 0, time.UTC)

// newService arma el servicio con dobles. Es el helper que todos los tests de
// este archivo usan, y por eso lleva t.Helper().
func newService(t *testing.T) (*opsreport.Service, *fakeStore, *fakeClock) {
	t.Helper()

	store := newFakeStore()
	clock := &fakeClock{now: created}
	svc := opsreport.New(store, clock, &seqIDs{})
	return svc, store, clock
}

func validItem() workitem.WorkItem {
	return workitem.WorkItem{
		ExternalReference: "SAP-2026-000123",
		Kind:              workitem.KindReconciliation,
		Description:       "Conciliación de tiendas del norte",
		Priority:          3,
	}
}

func TestCreate(t *testing.T) {
	t.Run("asigna id, fecha y estado inicial", func(t *testing.T) {
		svc, store, _ := newService(t)

		got, err := svc.Create(validItem())
		if err != nil {
			t.Fatalf("Create() error = %v", err)
		}

		if got.ID == "" {
			t.Error("Create() no asignó un ID")
		}
		if got.Status != workitem.StatusQueued {
			t.Errorf("Status = %q, quería %q", got.Status, workitem.StatusQueued)
		}
		if !got.CreatedAt.Equal(created) {
			t.Errorf("CreatedAt = %v, quería %v", got.CreatedAt, created)
		}

		// Y lo que de verdad importa: quedó guardado.
		saved, err := store.FindByID(got.ID)
		if err != nil {
			t.Fatalf("el item no quedó en el almacén: %v", err)
		}
		if saved.ID != got.ID {
			t.Errorf("el almacén tiene %q, el servicio devolvió %q", saved.ID, got.ID)
		}
	})

	t.Run("ignora el id que venga del cliente", func(t *testing.T) {
		svc, _, _ := newService(t)

		item := validItem()
		item.ID = "WI-INVENTADO"

		got, err := svc.Create(item)
		if err != nil {
			t.Fatalf("Create() error = %v", err)
		}
		if got.ID == "WI-INVENTADO" {
			t.Error("Create() aceptó el ID del cliente; tiene que generarlo el servicio")
		}
	})

	t.Run("rechaza un item inválido sin tocar el almacén", func(t *testing.T) {
		svc, store, _ := newService(t)

		item := validItem()
		item.ExternalReference = ""

		_, err := svc.Create(item)
		if err == nil {
			t.Fatal("Create() = nil, quería error de validación")
		}

		var verr *workitem.ValidationError
		if !errors.As(err, &verr) {
			t.Errorf("Create() devolvió %T, quería *workitem.ValidationError", err)
		}
		if len(store.items) != 0 {
			t.Errorf("el almacén tiene %d items, quería 0", len(store.items))
		}
	})

	t.Run("propaga el fallo del almacén", func(t *testing.T) {
		svc, store, _ := newService(t)
		store.saveErr = errors.New("disco lleno")

		_, err := svc.Create(validItem())
		if err == nil {
			t.Fatal("Create() = nil, quería error del almacén")
		}
		if !errors.Is(err, opsreport.ErrStorage) {
			t.Errorf("Create() = %v, quería que fuera ErrStorage", err)
		}
	})
}

func TestStart(t *testing.T) {
	tests := []struct {
		name        string
		setupStatus workitem.Status
		wantErr     error
	}{
		{name: "desde queued arranca", setupStatus: workitem.StatusQueued},
		{name: "desde running es conflicto", setupStatus: workitem.StatusRunning, wantErr: opsreport.ErrConflict},
		{name: "desde done es conflicto", setupStatus: workitem.StatusDone, wantErr: opsreport.ErrConflict},
		{name: "desde cancelled es conflicto", setupStatus: workitem.StatusCancelled, wantErr: opsreport.ErrConflict},
	}

	for _, tt := range tests {
		tt := tt
		t.Run(tt.name, func(t *testing.T) {
			svc, store, _ := newService(t)

			item, err := svc.Create(validItem())
			if err != nil {
				t.Fatalf("preparando: %v", err)
			}
			// Colocar el estado de partida directamente en el almacén: el
			// servicio no permitiría llegar ahí, y no es lo que se prueba.
			item.Status = tt.setupStatus
			if err := store.Update(item); err != nil {
				t.Fatalf("preparando el estado: %v", err)
			}

			got, err := svc.Start(item.ID)

			if tt.wantErr != nil {
				if !errors.Is(err, tt.wantErr) {
					t.Fatalf("Start() error = %v, quería %v", err, tt.wantErr)
				}
				return
			}
			if err != nil {
				t.Fatalf("Start() error = %v", err)
			}
			if got.Status != workitem.StatusRunning {
				t.Errorf("Status = %q, quería %q", got.Status, workitem.StatusRunning)
			}
			if !got.StartedAt.Equal(created) {
				t.Errorf("StartedAt = %v, quería %v", got.StartedAt, created)
			}
		})
	}
}

func TestStart_NotFound(t *testing.T) {
	svc, _, _ := newService(t)

	_, err := svc.Start("WI-NO-EXISTE")

	if !errors.Is(err, opsreport.ErrNotFound) {
		t.Errorf("Start() error = %v, quería ErrNotFound", err)
	}
	// Y la cadena de errores sigue completa: el error del almacén está dentro.
	if !errors.Is(err, memstore.ErrNotFound) {
		t.Errorf("se perdió la causa original del almacén en %v", err)
	}
}
```

> 💡 **`package opsreport_test` y no `package opsreport`.** Go permite dos
> paquetes de test: el interno (mismo paquete, ve todo) y el **externo**
> (`_test` como sufijo, ve solo lo exportado). Este curso prefiere el externo por
> defecto, y la razón es de diseño: **te obliga a probar a través de la API
> pública**, que es la que tus usuarios van a tener. Si un test necesita acceder a
> algo no exportado para verificar algo importante, eso suele ser una señal de que
> la API pública se quedó corta.
>
> El paquete interno se usa cuando de verdad hace falta —probar un algoritmo
> privado complejo— y se justifica.

### 6.5 EventRelay: la suite de la máquina de estados

El segundo servicio, con su política de reintentos, que es donde una tabla se luce:

```go
// services/eventrelay/internal/relay/delivery_test.go
package relay_test

import (
	"testing"
	"time"

	"github.com/meridian/eventrelay/internal/relay"
)

func TestDelivery_RecordFailure(t *testing.T) {
	now := time.Date(2026, 9, 11, 10, 0, 0, 0, time.UTC)

	tests := []struct {
		name         string
		attempts     int
		maxAttempts  int
		wantStatus   relay.DeliveryStatus
		wantAttempts int
	}{
		{
			name:         "primer fallo con intentos de sobra",
			attempts:     0,
			maxAttempts:  5,
			wantStatus:   relay.DeliveryFailing,
			wantAttempts: 1,
		},
		{
			name:         "penúltimo intento sigue vivo",
			attempts:     3,
			maxAttempts:  5,
			wantStatus:   relay.DeliveryFailing,
			wantAttempts: 4,
		},
		{
			name:         "el último intento la mata",
			attempts:     4,
			maxAttempts:  5,
			wantStatus:   relay.DeliveryDead,
			wantAttempts: 5,
		},
		{
			name:         "con un solo intento permitido muere al primer fallo",
			attempts:     0,
			maxAttempts:  1,
			wantStatus:   relay.DeliveryDead,
			wantAttempts: 1,
		},
	}

	for _, tt := range tests {
		tt := tt
		t.Run(tt.name, func(t *testing.T) {
			d := relay.Delivery{
				Status:      relay.DeliveryInFlight,
				Attempts:    tt.attempts,
				MaxAttempts: tt.maxAttempts,
			}

			if err := d.RecordFailure(now, "502 Bad Gateway"); err != nil {
				t.Fatalf("RecordFailure() error = %v", err)
			}

			if d.Status != tt.wantStatus {
				t.Errorf("Status = %q, quería %q", d.Status, tt.wantStatus)
			}
			if d.Attempts != tt.wantAttempts {
				t.Errorf("Attempts = %d, quería %d", d.Attempts, tt.wantAttempts)
			}
			if d.LastError != "502 Bad Gateway" {
				t.Errorf("LastError = %q, quería el motivo del fallo", d.LastError)
			}
		})
	}
}

// TestDeliveryStateMachine recorre TODOS los pares de estados y verifica que la
// máquina permite exactamente lo que debe. Es una tabla exhaustiva, y detecta el
// día que alguien añade un estado y se olvida de las transiciones.
func TestDeliveryStateMachine(t *testing.T) {
	all := []relay.DeliveryStatus{
		relay.DeliveryPending, relay.DeliveryInFlight, relay.DeliveryDelivered,
		relay.DeliveryFailing, relay.DeliveryDead, relay.DeliveryCancelled,
	}

	allowed := map[relay.DeliveryStatus]map[relay.DeliveryStatus]bool{
		relay.DeliveryPending:  {relay.DeliveryInFlight: true, relay.DeliveryCancelled: true},
		relay.DeliveryInFlight: {relay.DeliveryDelivered: true, relay.DeliveryFailing: true, relay.DeliveryDead: true},
		relay.DeliveryFailing:  {relay.DeliveryPending: true, relay.DeliveryDead: true, relay.DeliveryCancelled: true},
	}

	for _, from := range all {
		for _, to := range all {
			from, to := from, to
			t.Run(string(from)+"→"+string(to), func(t *testing.T) {
				d := relay.Delivery{Status: from}

				got := d.CanTransitionTo(to)
				want := allowed[from][to]

				if got != want {
					t.Errorf("CanTransitionTo(%s) desde %s = %v, quería %v", to, from, got, want)
				}
			})
		}
	}
}
```

Treinta y seis subtests de una tabla de tres filas. Y cuando alguien añada un
estado `DeliveryPaused` en la Fase 12, este test va a fallar hasta que decida
conscientemente sus transiciones — que es exactamente lo que queremos.

### 6.6 Cobertura, con su advertencia

```bash
make cover
# o, sin el Makefile:
go1.13 test -race -covermode=atomic -coverprofile=cover.out ./...
go1.13 tool cover -func=cover.out | tail -n 1
# total:  (statements)  84.2%
go1.13 tool cover -html=cover.out
```

Y ahora la advertencia, que se escribe una vez y se sostiene todo el curso.
**Demuéstrala, no te fíes de que te la crean:**

```go
// ❌ Este test da 100% de cobertura sobre Validate y no vale absolutamente nada.
func TestValidate_Coverage(t *testing.T) {
	items := []workitem.WorkItem{
		{},                                    // falla por todo
		{ExternalReference: "X"},              // falla por kind y priority
		{ExternalReference: "X", Kind: workitem.KindImport},
		{ExternalReference: "X", Kind: workitem.KindImport, Priority: 3},
		{ExternalReference: "X", Kind: workitem.KindImport, Priority: 3,
			Description: strings.Repeat("a", 501)},
	}
	for _, item := range items {
		_ = item.Validate()   // ← se ejecutan todas las ramas, no se afirma nada
	}
}
```

Corre la cobertura solo con ese test: **100% sobre `Validate`**. Y si alguien
cambia `Priority < MinPriority` por `Priority <= MinPriority`, el test sigue
pasando y la cobertura sigue en 100%.

> 🧭 **Regla del proyecto.** La cobertura mide **líneas ejecutadas**, no
> comportamiento verificado. Es útil para lo contrario de lo que la gente cree:
> **para encontrar lo que NO se probó**, no para presumir del número. El umbral
> del curso es **80% en `internal/`, con `cmd/` excluido**, y el número se
> defiende: si un paquete está en 62% y las líneas descubiertas son manejo de
> errores de E/S imposibles de provocar en un unitario, eso se argumenta en el PR
> y se acepta.

El `Makefile` de la Fase 00 imprimía el total pero no fallaba. Sigue así 💸 —se
paga en la Fase 14, con el umbral en CI—, pero el objetivo se afina ya:

```makefile
COVER_PKGS = ./internal/...

cover: ## Cobertura sobre internal/, con informe
	$(GO113) test -race -covermode=atomic -coverprofile=$(COVER_FILE) $(COVER_PKGS)
	$(GO113) tool cover -func=$(COVER_FILE) | tail -n 1

cover-html: cover ## Abre el informe HTML
	$(GO113) tool cover -html=$(COVER_FILE)
```

---

## ⚰️ 7. Autopsia y errores comunes

### ⚰️ Autopsia: el mock que probaba el mock

**El cadáver.** Este test existió, pasaba, y no probaba nada:

```go
// ☕
func TestService_Create(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	store := mocks.NewMockStore(ctrl)
	clock := mocks.NewMockClock(ctrl)
	ids := mocks.NewMockIDGenerator(ctrl)

	expected := workitem.WorkItem{
		ID:                "WI-0001",
		ExternalReference: "SAP-1",
		Kind:              workitem.KindImport,
		Priority:          3,
		Status:            workitem.StatusQueued,
		CreatedAt:         fixedTime,
	}

	ids.EXPECT().NewID().Return("WI-0001")
	clock.EXPECT().Now().Return(fixedTime)
	store.EXPECT().Save(expected).Return(nil)

	svc := opsreport.New(store, clock, ids)

	got, err := svc.Create(workitem.WorkItem{
		ExternalReference: "SAP-1",
		Kind:              workitem.KindImport,
		Priority:          3,
	})

	assert.NoError(t, err)
	assert.Equal(t, expected, got)
}
```

**El informe forense.** Este test verifica que `Create` llama a `Save` con el
objeto que el propio test construyó a partir de las mismas reglas que `Create`
aplica. Es un espejo: **la expectativa y la implementación dicen lo mismo porque
las escribió la misma persona el mismo día.**

Concretamente:

| Qué parece que prueba | Qué prueba de verdad |
|---|---|
| Que el item se guarda | Que se llamó a `Save` con un argumento concreto |
| Que el ID se genera | Que `Create` llamó a `NewID()` una vez |
| Que el estado inicial es `queued` | Que el test escribió `StatusQueued` en `expected` |
| Que el item es recuperable después | **Nada.** No hay almacén; no hay nada que recuperar |

Y el coste de mantenimiento, que es la otra mitad:

| Cambio en el código | Qué pasa con el test de mock | Qué pasa con el test de fake |
|---|---|---|
| `Create` consulta el reloj dos veces en vez de una | **Falla** (`Times(1)` incumplido), aunque el comportamiento es idéntico | Pasa |
| `Create` normaliza la referencia externa a mayúsculas | **Falla** (el argumento de `Save` no coincide) — y está bien que falle | Falla, y el mensaje dice qué campo cambió |
| Se añade un método a la interfaz `Store` | Hay que **regenerar** los mocks | El compilador dice exactamente qué fake actualizar |
| `Create` guarda y después vuelve a leer para devolver lo persistido | **Falla** (llamada a `FindByID` no esperada), aunque es una mejora | Pasa, y sigue verificando lo correcto |

Tres de esos cuatro cambios son **refactorizaciones sin cambio de comportamiento**,
y el test de mock falla en todas. Eso es la definición de un test frágil: rompe
cuando el código mejora.

**La causa de la muerte:** se verificó **interacción** donde lo que importaba era
**estado**. El reflejo viene de Java, donde crear un almacén falso significaba
implementar una interfaz de quince métodos y por eso el mock era la opción
razonable. En Go la interfaz tiene cuatro métodos porque **la declaró el
consumidor** (Fase 02), y el fake completo son treinta y dos líneas que se
escriben una vez.

**Cuándo el mock sí gana, para ser justos:** cuando lo que quieres verificar *es*
la interacción y no hay estado observable. El caso canónico llega en la **Fase
10**:

> *"El cliente HTTP tiene que reintentar exactamente tres veces ante un 503, con
> retroceso creciente, y no reintentar nunca ante un 400."*

Ahí no hay estado que mirar: el resultado final es el mismo error en los dos
casos. Lo que importa es **cuántas veces se llamó y con qué espera entre
llamadas**, y para eso el fake tendría que convertirse en un contador con
expectativas — es decir, en un mock escrito a mano y peor. Ese es el momento en
que `go.uber.org/mock` entra en el curso, con su justificación escrita.

> ☕ **El patrón a memorizar.** Verifica **estado** cuando lo haya. Verifica
> **interacción** solo cuando no lo haya. Y si el test se rompe cuando refactorizas
> sin cambiar comportamiento, el test está mal, no el refactor.

### Errores comunes

**1. El test de tabla sin `tt := tt`.**
*Síntoma:* con `t.Parallel()`, todos los subtests usan el último caso de la tabla.
*Causa:* la variable del bucle es una sola, compartida por todas las closures.
*Fix mínimo:* `tt := tt` como primera línea del bucle. 🕰️ Innecesario desde Go
1.22; lo veremos en la Fase 08.

**2. `t.Fatal` desde una goroutine.**
*Síntoma:* el test "pasa" aunque la goroutine falló, o aparece un panic raro.
*Causa:* `Fatal` llama a `runtime.Goexit`, que solo termina **esa** goroutine.
*Fix mínimo:* desde una goroutine, usa `t.Errorf` y comunica el fallo por un
canal. En la Fase 06 esto es central.

**3. El test que depende del orden.**
*Síntoma:* pasa al correr el paquete entero, falla con `-run TestX`.
*Causa:* estado compartido a nivel de paquete —una `var` global que un test deja
modificada.
*Fix mínimo:* nada de estado de paquete en tests. Cada test construye lo suyo.
(Y 🕰️ en Go 1.17 llegó `-shuffle` para detectarlo automáticamente.)

**4. El test que depende del reloj real.**
*Síntoma:* falla a las 23:59, o el último día del mes, o en CI porque el
contenedor está en UTC y tu máquina en `America/Bogota`.
*Causa:* `time.Now()` en la lógica, o una expectativa que asume el huso local.
*Fix mínimo:* `fakeClock`, y todas las fechas de test en UTC explícito.

**5. Comparar structs con `reflect.DeepEqual` sin pensar.**
*Síntoma:* falla comparando dos `time.Time` que representan el mismo instante.
*Causa:* `time.Time` lleva un campo de ubicación y a veces un reloj monótono;
`DeepEqual` compara campos.
*Fix mínimo:* comparar tiempos con `.Equal()`, y los structs campo a campo, o
normalizar antes.

**6. El `defer` que no limpia porque el test hizo `Fatal` antes.**
*Síntoma:* archivos temporales acumulados tras una suite con fallos.
*Causa:* `t.Fatal` hace `runtime.Goexit`, que **sí** ejecuta los `defer` de la
función del test... pero no los de un helper que ya retornó.
*Fix mínimo:* `t.Cleanup` en vez de `defer` en los helpers. Se ejecuta siempre, al
final del test, en orden inverso.

**7. El error ignorado en el `setup` del test.**
*Síntoma:* un test falla con un mensaje incomprensible tres líneas después.
*Causa:* `item, _ := svc.Create(...)` en la preparación.
*Fix mínimo:* nunca `_` en la preparación de un test. Un helper con `t.Helper()` y
`t.Fatalf`.

**8. Probar el fake en vez del código.**
*Síntoma:* el test pasa y el código de producción está roto.
*Causa:* el fake y el código real divergieron —el fake acepta algo que el
`memstore` rechaza.
*Fix mínimo:* correr la **misma tabla de tests** contra el fake y contra la
implementación real. Es el ejercicio 22 de esta fase, y es una técnica muy
infravalorada.

### 🧨 Rompe a propósito

El experimento que hay que hacer para no volver a fiarse de un número de
cobertura:

1. Borra todos los tests de `workitem` menos el `TestValidate_Coverage` de §6.6 —
   el que ejecuta todo y no afirma nada.
2. Corre `make cover`. Anota el porcentaje de `internal/workitem`.
3. Ahora **introduce un bug**: cambia `if w.Priority < MinPriority` por
   `if w.Priority < 0`.
4. Corre los tests: **pasan**. Corre la cobertura: **el mismo número**.

Una prioridad de `0` ahora se acepta y llegaría a la base de datos.

Restaura los tests reales de §6.1 y repite el paso 3: el subtest
*"prioridad por debajo del mínimo"* falla con un mensaje que dice exactamente qué
pasó.

**La lección:** cobertura alta con aserciones pobres es peor que cobertura baja
honesta, porque da una falsa sensación de seguridad que se usa para tomar
decisiones. (Si esta idea te interesa, el concepto formal es *mutation testing*, y
hay herramientas para Go; el curso no las usa, pero el experimento de arriba es
mutation testing hecho a mano.)

---

## 🧪 8. Ejercicios (26)

**🟢 Fácil (1–6)**

1. Convierte tres comprobaciones del `main` de OpsReport en tests de verdad, y
   borra ese `main`. *Criterio:* `go1.13 test ./...` cubre lo mismo que
   verificabas por pantalla, y `cmd/opsreport/main.go` ya no imprime nada de
   diagnóstico.
2. Escribe un test de tabla para `Kind.IsKnown` con los cinco tipos válidos y tres
   inválidos. *Criterio:* ocho subtests con nombre legible, y `-run` puede aislar
   uno solo.
3. Escribe `fakeClock` como tipo función (`clockFunc`) y como struct. *Criterio:*
   los dos funcionan en el mismo test, y explicas en dos líneas cuándo preferirías
   cada uno.
4. Usa `t.Cleanup` para borrar un archivo temporal, y provoca un `t.Fatal` antes
   del final. *Criterio:* el archivo se borra igual, y explicas por qué con
   `defer` en un helper no habría pasado.
5. Corre `go1.13 test -v -run 'TestDeliveryStateMachine/failing'` y consigue
   ejecutar solo las transiciones desde `failing`. *Criterio:* pegas el comando y
   la salida.
6. Genera el informe HTML de cobertura y encuentra la función menos cubierta de
   `internal/`. *Criterio:* dices cuál es, por qué está descubierta y si merece
   un test.

**🟡 Intermedio (7–16)**

7. Escribe la suite completa de `Endpoint.Matches` con al menos doce casos,
   incluidos comodines y coincidencias parciales que **no** deben coincidir.
   *Criterio:* cubre el caso `"order.*"` contra `"orders.created"`, que es el bug
   sutil del prefijo.
8. Escribe `fakeStore` completo y úsalo para probar `Service.Complete` en sus dos
   caminos —éxito y fallo—. *Criterio:* verificas el estado guardado, no las
   llamadas.
9. Añade a `fakeStore` la capacidad de forzar errores en cada método por separado.
   *Criterio:* un test cubre el camino "el almacén falla al actualizar después de
   haber leído bien", que es el más difícil de provocar en producción.
10. Escribe un helper `mustCreate(t, svc, ref)` con `t.Helper()`. Después quítale
    el `t.Helper()` y provoca un fallo. *Criterio:* muestras las dos salidas y
    explicas la diferencia en el número de línea reportado.
11. Implementa `golden-report` con `-update` y cambia el formato a propósito.
    *Criterio:* el diff del archivo golden es legible en un `git diff` y explicas
    por qué eso importa en una revisión de código.
12. Escribe el test que verifica que `Create` **ignora** el `ID`, el `Status` y el
    `CreatedAt` que vengan del cliente. *Criterio:* los tres, y explicas por qué
    esto es una prueba de seguridad y no solo de corrección.
13. Mide la cobertura antes y después de añadir la suite de `relay`. *Criterio:*
    anotas los dos números y dices qué paquete subió más y por qué.
14. Escribe un test que verifique que `ValidationError` reporta **todos** los
    campos malos, no solo el primero. *Criterio:* usa `errors.As` y compara el
    conjunto de campos sin depender del orden.
15. Provoca el fallo del `tt := tt` ausente: añade `t.Parallel()` a un test de
    tabla sin la copia. *Criterio:* reproduces el fallo, lo explicas, y lo
    arreglas. Anota que en Go 1.22 esto deja de pasar 🕰️.
16. **Línea de comandos.** Usa `go1.13 test -list` y `go1.13 test -run` para
    contar cuántos tests hay en cada paquete de `internal/` sin correrlos.
    *Criterio:* un comando o una tubería; sin contar a mano.

**🟠 Difícil (17–22)**

17. **Diagnóstico (1).** Te dan un test que pasa y no debería:
    ```go
    func TestMarkDone(t *testing.T) {
        item := workitem.WorkItem{Status: workitem.StatusQueued}
        item.MarkDone(time.Now())
        if item.Status == workitem.StatusDone {
            t.Log("ok")
        }
    }
    ```
    *Criterio:* identificas los **tres** problemas distintos, los arreglas, y el
    test corregido falla contra el código actual (porque `queued → done` no es una
    transición válida).
18. **Diagnóstico (2).** Un test que pasa en local y falla en CI. El código usa
    `time.Now()` y compara fechas formateadas. *Criterio:* reproduces el fallo
    cambiando `TZ` (`TZ=Pacific/Auckland go1.13 test ./...`), lo explicas, y lo
    arreglas de forma que no dependa del huso.
19. **Diagnóstico (3).** Un test que pasa aislado y falla en la suite completa.
    Constrúyelo tú: dos tests que comparten una `var` de paquete. *Criterio:*
    demuestras el fallo, lo arreglas, y explicas por qué `-shuffle` lo habría
    detectado 🕰️.
20. **Diagnóstico (4).** El mapa de `fakeStore` corrompiéndose. Lanza diez
    goroutines que llamen a `Save` a la vez y corre con `-race`. *Criterio:*
    pegas el informe de `-race` completo, explicas qué línea lo causó, y **no lo
    arregles todavía** — anota que se arregla en la Fase 06 y por qué el fake de
    hoy no necesita ser seguro.
21. **Diagnóstico (5).** Un test de `golden-report` que falla en Windows y pasa en
    macOS. *Criterio:* identificas el problema de finales de línea, lo arreglas con
    `.gitattributes` o normalizando en el test, y dices cuál de las dos soluciones
    prefieres y por qué.
22. **La misma tabla contra dos implementaciones.** Escribe un conjunto de tests
    de contrato para `opsreport.Store` y córrelo contra `fakeStore` **y** contra
    `memstore.Store`. *Criterio:* (a) la tabla se escribe una vez y se ejecuta dos;
    (b) encuentras al menos una divergencia real entre las dos implementaciones o
    demuestras que no la hay; (c) explicas por qué esta técnica es la que evita el
    error común #8.

**🔴 Muy difícil (23–26)**

23. **La suite de contrato completa.** Extiende el ejercicio 22 a una suite
    reutilizable que cualquier implementación futura de `Store` tenga que pasar —
    pensando en la de PostgreSQL de la Fase 09. *Rúbrica:* (a) la suite es una
    función exportada desde un paquete de test compartido que recibe un
    constructor; (b) cubre los casos límite: guardar dos veces la misma clave,
    actualizar lo que no existe, listar cuando está vacío, y la independencia del
    slice devuelto (que un `append` del llamador no corrompa el almacén — lección
    de la Fase 01); (c) documenta qué garantías exige el contrato y cuáles deja
    libres; (d) la corres contra `memstore` y pasa.
24. **El experimento de mutación.** Introduce cinco mutaciones distintas en
    `workitem` —cambiar `<` por `<=`, invertir una condición, eliminar una rama,
    cambiar una constante, cambiar el orden de dos operaciones— y mide cuántas
    detecta tu suite. *Rúbrica:* (a) las cinco mutaciones son plausibles, del tipo
    que produce un despiste real, no absurdas; (b) reportas cuántas se detectaron y
    cuáles no; (c) para cada superviviente, escribes el test que falta; (d)
    comparas el porcentaje de mutaciones detectadas con el porcentaje de cobertura
    y comentas la diferencia.
25. **Detección de ☕.** Te dan un archivo de test de 300 líneas escrito con
    reflejos de JUnit: una `struct` `ServiceTestSuite` con campos compartidos, un
    `SetUp` y un `TearDown` invocados a mano al principio y al final de cada test,
    mocks para todo, y aserciones con una librería. Reescríbelo. *Rúbrica:* (a) la
    versión de Go usa tablas, subtests, `t.Cleanup` y fakes; (b) cuentas líneas
    antes y después; (c) identificas qué parte de la suite original **sí** era
    buena idea y la conservas; (d) explicas por qué este curso deja fuera
    `testify/suite`, en tus propias palabras y sin descalificar a quien lo usa.
26. **El régimen de pruebas, documentado.** Escribe `docs/testing.md`: la política
    de pruebas de Meridian. *Rúbrica:* (a) define los niveles de la pirámide con
    el nombre que van a tener en este curso y qué va en cada uno; (b) fija la regla
    de los dobles —función, fake, generado— con el criterio exacto para subir de
    escalón y un ejemplo de cada uno tomado del código escrito; (c) fija la
    política de cobertura, el umbral, qué se excluye y cómo se defiende una
    excepción; (d) incluye los ocho errores comunes de §7 como lista de revisión;
    (e) es utilizable por alguien que llega al equipo el lunes.

**🔥 Opcionales**

- Lee los tests de `strings` en tu `GOROOT` de 1.13
  (`$(go1.13 env GOROOT)/src/strings/strings_test.go`). Es la mejor colección de
  tests de tabla que vas a encontrar, escrita por el equipo que inventó el estilo.
- Investiga `testing.T.Log` y por qué su salida solo aparece con `-v` o cuando el
  test falla. Después decide si eso te parece bien y defiéndelo.
- Prueba una herramienta de *mutation testing* para Go sobre `internal/workitem` y
  compara su resultado con tu ejercicio 24 hecho a mano.

---

### 🔴 Desafíos de cierre

> Tres ejercicios de dificultad alta que **no cuentan en el total de la sección** y
> no son parte del recorrido base.

**D1 — Pruebas basadas en propiedades con `testing/quick`.**
La stdlib de 1.13 trae `testing/quick`, que genera entradas aleatorias y verifica
propiedades. Aplícalo al parser de movimientos y a `EffectivePriority`.
*Rúbrica:* (a) defines al menos tres **propiedades** —afirmaciones que se cumplen
para toda entrada válida, no casos concretos—: por ejemplo, que la prioridad
efectiva nunca supera `MaxPriority`, que nunca es menor que la declarada, y que es
monótona en el tiempo de espera; (b) `quick.Check` las verifica con generación
aleatoria; (c) escribes un generador propio con `quick.Value` para producir
`WorkItem` válidos, porque el generador por defecto produce basura; (d) encuentras
**al menos una propiedad que falla** y decides si el bug está en la propiedad o en
el código; (e) comparas la técnica con el test de tabla: qué encuentra cada uno que
el otro no.

**D2 — El detector de tests que no afirman nada.**
Escribe una herramienta con `go/ast` que encuentre funciones `TestXxx` que **no
llamen nunca** a `t.Error`, `t.Errorf`, `t.Fatal`, `t.Fatalf` ni a un helper que lo
haga.
*Rúbrica:* (a) sigue las llamadas a helpers un nivel, para no reportar falsos
positivos sobre los que usan `t.Helper()`; (b) distingue el test vacío del test que
solo verifica que algo **no entra en panic**, que es legítimo y hay que reportar
aparte; (c) la corres sobre el código del curso y sobre un repositorio ajeno; (d)
explicas por qué esta herramienta encuentra lo que la cobertura no puede encontrar
**por construcción**.

**D3 — El golden file determinista.**
Haz que un golden file sea reproducible aunque la salida contenga fechas,
identificadores generados y recorridos de mapa.
*Rúbrica:* (a) identificas las **tres** fuentes de no determinismo y las neutralizas
—reloj falso, generador de identificadores secuencial, orden explícito—; (b) el test
pasa mil veces seguidas con `-count=1000`; (c) el golden sigue siendo legible en un
`git diff`, que es la mitad de su valor; (d) documentas qué hacer cuando la salida
**tiene que** llevar un identificador aleatorio: normalizarlo antes de comparar, y
cómo hacerlo sin ocultar un bug.

---

## 📚 9. Referencias

### Documentación oficial

- **`testing`** — https://pkg.go.dev/testing — la documentación del paquete es
  **la** referencia. La sección inicial cubre tests, benchmarks y ejemplos; léela
  entera una vez.
- **`go test` y sus banderas** — https://pkg.go.dev/cmd/go#hdr-Testing_flags —
  todas las banderas, con su significado exacto. Es donde se resuelve la duda de
  `-count`, `-run` y `-timeout`.
- **Cobertura** — https://go.dev/blog/cover — el artículo oficial que introdujo
  `go tool cover`; explica cómo funciona la instrumentación, que es útil saberlo.
- **`testing/quick`** — https://pkg.go.dev/testing/quick — property-based testing
  en la stdlib de 1.13. Poco conocido, algo limitado, y el precursor del fuzzing
  que llega en 1.18. 🕰️
- **Go Wiki: TableDrivenTests** — https://go.dev/wiki/TableDrivenTests — corto y
  normativo.
- **Go Code Review Comments: Useful Test Failures** —
  https://go.dev/wiki/CodeReviewComments#useful-test-failures — el formato
  `got, want` viene de aquí.
- **Google Go Style Guide: Tests** — https://google.github.io/styleguide/go/decisions#tests
  — la sección más útil de esa guía para esta fase.

### Libros

- **The Go Programming Language** — Donovan y Kernighan, capítulo 11 (*Testing*).
  Cubre tests de tabla, cobertura, benchmarks y `testing/quick`. Anterior a
  `t.Cleanup` (Go 1.14), así que esa parte le falta.
- **Learning Go** — Jon Bodner, capítulo *Writing Tests*. El más actualizado:
  cubre `t.Cleanup`, `t.Setenv`, fuzzing y el paquete `_test` externo.
- **100 Go Mistakes** — Harsanyi, capítulo 11 entero (*Testing*). Los errores
  #82 a #90 son exactamente la lista de §7.
- **Let's Go** — Alex Edwards. Su enfoque de tests sobre servicios HTTP con stdlib
  pura es el mismo de este curso; el capítulo de testing prepara la Fase 05.

### Artículos y charlas

- **Table driven tests in Go** — Dave Cheney,
  https://dave.cheney.net/2019/05/07/prefer-table-driven-tests — el artículo
  canónico sobre el estilo.
- **Testing Techniques** — Andrew Gerrand, https://go.dev/talks/2014/testing.slide
  — de 2014 y sigue siendo la mejor introducción a fakes, golden files e
  inyección para tests.
- **Advanced Testing with Go** — Mitchell Hashimoto. Busca la charla de GopherCon
  2017; la parte sobre helpers, golden files y estructura de suites es oro.
- **Mocks Aren't Stubs** — Martin Fowler,
  https://martinfowler.com/articles/mocksArentStubs.html — no es de Go, es de 2007
  y es la mejor explicación que existe de la diferencia entre verificar estado y
  verificar interacción. **Es la lectura que sostiene la autopsia de esta fase.**
- **Test Doubles** — Martin Fowler, https://martinfowler.com/bliki/TestDouble.html
  — el vocabulario (dummy, fake, stub, spy, mock) que este curso usa.
- **Go Test Comments** — https://go.dev/wiki/TestComments — la lista de
  observaciones que los revisores de Go hacen en los tests. Cortísima y muy densa.

### Video

- **Advanced Testing with Go** — Mitchell Hashimoto, GopherCon 2017.
- **GopherCon: Writing Beautiful Tests** — busca charlas con ese enfoque
  posteriores a 2019, para que cubran `t.Cleanup`.
- **JetBrains Go** — su serie sobre el ejecutor de tests de GoLand muestra la
  visualización de subtests, que es genuinamente mejor que la salida de terminal.

> ⚠️ El material anterior a 2020 no conoce `t.Cleanup` (1.14) ni `t.Setenv`
> (1.17), y todo el anterior a 2022 lleva el `tt := tt` que en 1.22 dejó de hacer
> falta. Nada de eso lo invalida; solo hay que leerlo sabiendo la fecha.

### Orden de lectura sugerido

**Antes de escribir tests:** *Table driven tests in Go* de Cheney y la sección
*Useful Test Failures* de Code Review Comments. Veinte minutos entre las dos.
**Durante:** la documentación de `testing` cuando dudes de una API, y
*Go Test Comments* antes de abrir tu primer PR con tests.
**Después, y esto es lo que de verdad cambia cómo escribes:** *Mocks Aren't Stubs*
de Fowler, entero. Es largo, es de 2007, y explica por qué la autopsia de esta
fase no es una opinión sobre Go sino una distinción de diseño de pruebas que se
aplica en cualquier lenguaje.

---

## ⚖️ 10. Veredicto y cierre

### ⚖️ Cuándo NO usar esto

El régimen de pruebas de Go es minimalista, y eso tiene costes concretos:

- **Sin aserciones ricas, los tests de estructuras complejas son verbosos.**
  Comparar dos slices de structs anidados con `if` a mano son veinte líneas;
  `assertThat(actual).usingRecursiveComparison().isEqualTo(expected)` es una. Por
  eso `testify/require` entra en la Fase 09 **acotado a integración**, y por eso
  mucha gente lo usa en todas partes — y no están locos.
- **Sin un framework de suites, el estado compartido entre tests hay que
  gestionarlo a mano.** `@Nested` de JUnit con su jerarquía de `@BeforeEach`
  expresa bien un árbol de contextos; en Go eso son funciones helper y algo de
  repetición. Cuando el setup es caro y jerárquico —cinco niveles de contexto—,
  JUnit es más expresivo.
- **Los mocks generados tienen su sitio y este curso lo retrasa mucho.** Si tu
  código está lleno de interfaces que te vienen dadas por una librería —un SDK de
  nube con treinta métodos—, escribir el fake **sí** es prohibitivo y el generador
  es la respuesta correcta desde el día uno.
- **No hay nada como `@SpringBootTest`.** Levantar la aplicación entera con una
  anotación, con el contexto cacheado entre clases de test, es genuinamente
  cómodo. En Go eso se escribe: una función que cablea todo para tests, y en la
  Fase 09 la vamos a escribir. Es más código y es más predecible; el intercambio
  es real en las dos direcciones.
- **Y `testing/quick` se queda muy corto** frente a jqwik o a las librerías de
  property-based testing de otros ecosistemas. El fuzzing de 1.18 mejora esto
  bastante y llega en la Fase 08, pero no es lo mismo.

### 📖 Diccionario Java ⇄ Go de esta fase

| Java / JUnit | Go | Dónde se rompe la equivalencia |
|---|---|---|
| `@Test` | `func TestXxx(t *testing.T)` | Sin anotación: la convención de nombre y la firma bastan. El archivo debe acabar en `_test.go` |
| Clase de test | archivo `_test.go` | No hay clase, no hay estado de instancia compartido entre tests. Cada test es una función independiente |
| `@BeforeEach` | una función helper que el test llama | Explícito: el orden es el del código, no el que decida el framework |
| `@AfterEach` | `t.Cleanup(func(){...})` | Se declara **junto a** lo que hay que limpiar, no en un método aparte. Se puede registrar varias veces |
| `@BeforeAll` / `@AfterAll` | `TestMain(m *testing.M)` | Uno por paquete. `os.Exit` no ejecuta los `defer`: la limpieza va antes, explícita |
| `@ParameterizedTest` + `@CsvSource` | test de tabla + `t.Run` | Los casos son structs tipados, no cadenas. Más líneas, cero parseo, y el compilador verifica |
| `@MethodSource` | una función que devuelve el slice de casos | Misma idea, sin reflexión |
| `@Nested` | subtests anidados con `t.Run` dentro de `t.Run` | Funciona, pero sin la herencia de setup de `@Nested`. La jerarquía profunda se vuelve incómoda |
| `@DisplayName` | el primer argumento de `t.Run` | El nombre aparece con espacios convertidos en `_` en la salida |
| `assertEquals(want, got)` | `if got != want { t.Errorf(...) }` | Sin DSL. El orden convencional del mensaje es `got, want`, al revés que `assertEquals` |
| `assertThat` de AssertJ | *(nada)* | La comparación profunda se escribe o se usa `reflect.DeepEqual` (con cuidado). `testify` llega en la Fase 09, acotado |
| `assertThrows` | `if err == nil { t.Fatal(...) }` + `errors.Is`/`As` | Más explícito; además verificas *qué* error, no solo que hubo uno |
| `fail()` | `t.Fatal(...)` | `Fatal` aborta; `Error` marca y continúa. En Java `fail()` siempre aborta |
| `@Disabled` | `t.Skip("motivo")` | En Go el skip es en tiempo de ejecución y lleva motivo obligatorio, que se ve en la salida |
| `@Timeout` | `-timeout` global, o `context.WithTimeout` dentro | No hay timeout por test en la stdlib; es por paquete |
| Mockito `mock()` | un fake escrito a mano | El primer movimiento en Go es el fake, no el mock. El generado llega cuando hay que verificar interacción |
| `when(...).thenReturn(...)` | un campo del fake que controla la respuesta | Sin DSL: el fake tiene un campo `saveErr` y se le asigna |
| `verify(mock).save(x)` | comprobar el **estado** del fake | Se verifica que el item quedó guardado, no que se llamó a `Save` |
| `@Mock` / `@InjectMocks` | construcción explícita en el test | Dos líneas: `store := newFakeStore(); svc := opsreport.New(store, ...)` |
| `@SpringBootTest` | una función `newTestApp(t)` escrita a mano | Sin contexto cacheado entre clases. Más código, más predecible (Fase 09) |
| `@MockBean` | pasar otro doble al constructor | No hay contenedor que sustituir: le pasas lo que quieras |
| JaCoCo | `go test -coverprofile` + `go tool cover` | Integrado en el toolchain. Mismas limitaciones: mide líneas, no comportamiento |
| Umbral de JaCoCo en el `pom.xml` | un script sobre la salida de `cover -func` | No hay umbral nativo; se escribe (Fase 14) |
| Surefire | `go test ./...` | Sin plugin, sin configuración, sin fase del ciclo de vida |
| *Approval testing* / snapshots | golden files con bandera `-update` | Idéntico en concepto, mucho más barato de montar: son veinte líneas |
| `Clock.fixed()` de `java.time` | un `fakeClock` de ocho líneas | Mismo patrón. En Go lo escribes tú, y por eso encaja exactamente con tu interfaz |

### Qué sigue

La Fase 05 saca los dos servicios al mundo: **HTTP y REST con la stdlib**, y con el
enrutado escrito a mano, que es lo que fuerza la época de 1.13 y resulta ser una
ventaja pedagógica enorme. Vas a descubrir que `@GetMapping("/work-items/{id}")`
es un `switch` sobre el método y un corte de cadena, y vas a dejar de tenerle
respeto reverencial.

Middleware como composición de handlers, traducción de errores del dominio a
códigos HTTP **en un solo sitio** —apoyada directamente en la política de la Fase
03—, `httptest` para probarlo todo sin abrir un puerto, y los tiempos de espera del
servidor, porque `http.Server{}` por defecto no tiene ninguno y eso es un
incidente esperando.

Y nace `fakeconsumer`, el segundo binario de EventRelay, con sus endpoints `/ok`,
`/slow` y `/fail/{code}`.

### La señal de que quedó bien

> *"Añado un caso a la tabla y el test tarda tres segundos en escribirse. Cuando
> algo falla, el nombre del subtest me dice qué comportamiento se rompió antes de
> que lea el mensaje."*

Si escribir un test todavía te cuesta más que escribir el código que prueba,
mira dos cosas: si estás usando tabla, y si tus dobles son fakes o mocks. Casi
siempre es una de las dos.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en
> verde, `go1.13 test -race ./...` en verde, la cobertura de `internal/` sobre el
> umbral y `git status` limpio:
>
> ```bash
> git tag -a fase-04 -m "F4 cerrada: suites de tabla en workitem, opsreport y relay; fakes escritos a mano sin librerías de mocking; golden files con -update; cobertura medida sobre internal/ con umbral del 80%; validator-tests, fake-clock y golden-report"
> git tag -a opsreport/v0.4 -m "OpsReport: suite unitaria completa del dominio y el servicio"
> git tag -a eventrelay/v0.3 -m "EventRelay: suite unitaria de endpoints, entregas y reintentos"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 04: …`) y los de ejercicio su
> número (`fase 04 ej24: …`). Todo eso está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).

---

# 📌 Bloque de autoría (fuera de lo que lee el estudiante)

## 📌 Pendientes sugeridos

- **La suite de contrato de `Store`** (ejercicio 23) es una pieza real que la
  **Fase 09** va a necesitar cuando aparezca la implementación de PostgreSQL.
  **Verificar que la Fase 09 la reutiliza en vez de escribir tests nuevos**; si no,
  el ejercicio queda huérfano y hay que decirlo.
- **Mutation testing** — aparece como ejercicio 24 hecho a mano y como 🔥 con
  herramienta. No hay fase que lo adopte formalmente. Candidato a sección 🔥 de la
  **Fase 15** (donde ya se habla de medir en serio) o a quedarse como está.
- **`testing/quick`** — solo en referencias. Su sucesor natural es el fuzzing de la
  **Fase 08**; comprobar que allí se menciona la continuidad.
- **`-shuffle`** — 🕰️ nombrado dos veces (error común #3 y ejercicio 19).
  Verificar que la **Fase 08** lo recoge en el salto 1.17.
- **El umbral de cobertura que falla el build** — deuda 💸 desde la Fase 00,
  prometida a la **Fase 14**. Está en el alcance de esa fase; verificado.
- **`fakeClock` sin seguridad concurrente** — deuda 💸 declarada en §6.2, prometida
  a la **Fase 06**. Comprobar que allí se le añade el mutex y se explica por qué
  un doble de prueba también necesita ser correcto bajo `-race`.

## ☕ Reflejos para `INSTINTOS.md`

- **"Hay que mockear el almacén"** — el reflejo raíz de la fase. Coste medido: 12
  líneas de preparación por test frente a 2, un paso de generación en el build, y
  tres de cuatro refactorizaciones sin cambio de comportamiento rompen el test.
  Antídoto: fake de veinte líneas; verifica estado, no interacción.
- **"Verificar que se llamó al método"** — el test espejo que repite la
  implementación. Se rompe cuando el código mejora.
- **"La cobertura alta significa que está probado"** — el experimento del 🧨 lo
  desmonta en cinco minutos. Cobertura = líneas ejecutadas.
- **"Una clase `ServiceTestSuite` con `setUp` y `tearDown`"** — el reflejo de
  JUnit que reintroduce estado compartido. En Go: tablas, helpers y `t.Cleanup`.
- **"`assertEquals(esperado, obtenido)`"** — el orden invertido respecto a la
  convención de Go (`got, want`), y es una fuente real de confusión al leer
  mensajes de fallo.

## 📐 Mediciones para `BENCHMARKS.md`

Esta fase no produce entradas nuevas. Dos apuntes para las que vienen:

- **B-10 (coste de `-race`, Fase 06)** — la línea base honesta se puede tomar ya:
  el tiempo de `go1.13 test ./...` frente a `go1.13 test -race ./...` sobre la
  suite completa de esta fase, que ya no es trivial. **Anotar el dato aquí para que
  la Fase 06 lo compare con la suite concurrente**, donde el sobrecoste es otro.
- Comparación fake vs. mock generado en **tiempo de suite** — es **B-29**, y se
  mide en la Fase 10, donde entra `go.uber.org/mock`. Aquí solo se anota la
  intuición que esta fase deja: el fake gana en legibilidad del fallo, no
  necesariamente en tiempo. La entrada existe para comprobar si esa intuición
  aguanta.
