# 02 — API pública del módulo y encapsulación interna

Aprenderás a decidir qué puede conocer otro módulo y qué debe permanecer reemplazable. Una API
interna no necesita red: es la superficie deliberada que protege decisiones y datos dentro del
mismo proceso.

## 1. 🎯 El acceso accidental

`orders` importa `InventoryRepository`, carga una fila y cambia `reserved`. Compila, es rápido y
evita escribir una fachada; también salta la invariante de stock y hace que cualquier cambio de
persistencia afecte al consumidor.

```text
incorrecto: orders ──► repository/tabla de inventory
correcto:   orders ──► InventoryApi.reserve(command) ──► reglas y datos internos
```

La API expresa una capacidad y su resultado. Oculta entidad persistente, ORM y secuencia de
validación. Conserva la invariante; paga un mapeo y un contrato adicionales.

## 2. 🚪 Diseñar la superficie

Una API de módulo puede ofrecer:

- **comandos** que expresan intención: `ReserveInventory`;
- **consultas** con vistas publicadas: `ProductAvailability`;
- **resultados** explícitos: reserva creada, stock insuficiente o conflicto;
- **eventos** sobre hechos consumados: `InventoryReserved`.

No expongas un CRUD genérico si permite combinaciones inválidas. Tampoco devuelvas entidades
internas mutables: el consumidor aprenderá campos y ciclos de vida que el módulo debería poder
cambiar.

```java
public interface InventoryApi {
    ReservationResult reserve(ReserveInventory command);
}

public record ReserveInventory(String orderId, List<ReservationLine> lines) {}
public sealed interface ReservationResult permits ReservationCreated, InsufficientInventory {}
```

El contrato es pequeño porque modela una conversación, no porque esconda información necesaria.

## 3. 📦 Estabilidad dentro de un solo despliegue

Un monolito puede cambiar productor y consumidor atómicamente en un commit. Eso permite refactors
que un API remoto no admitiría, pero no elimina el valor de la estabilidad. Una superficie pequeña:

- reduce el radio de cambio y la carga cognitiva;
- permite probar consumidores sin detalles;
- muestra quién puede escribir estado;
- prepara convivencia de versiones solo si algún día es necesaria.

No versionar APIs internas por defecto. Si todos se despliegan juntos, `v2` puede acumular deuda sin
comprar compatibilidad real. Usa deprecación temporal cuando una migración grande no pueda ser
atómica y elimina la ruta antigua con fecha.

## 4. 🔍 Qué debe permanecer interno

| Elemento | Público cuando | Interno cuando |
|---|---|---|
| Comando | otro módulo necesita iniciar la capacidad | es un paso de implementación |
| Resultado | el consumidor debe decidir con él | solo sirve para persistir |
| Tipo | tiene semántica compartida estable | refleja ORM o regla local |
| Consulta | publica una vista con dueño | expone navegación arbitraria |
| Evento | otros reaccionan al hecho | disfraza una orden privada |

Revisa imports profundos, reflexión, inyección directa y SQL. La visibilidad del lenguaje cubre
algunas rutas; las pruebas arquitectónicas y la revisión cubren el resto.

## 5. 🧰 Java y Go: dos mecanismos, la misma decisión

### Java

`private` y package-private reducen visibilidad; JPMS puede exportar solo paquetes API. Aun así, un
framework de reflexión o paquetes mal cortados pueden abrir detalles.

```java
module commerce.inventory {
    exports commerce.inventory.api;
}
```

### Go

Los nombres en mayúscula se exportan desde un package, y un árbol `internal` impide imports desde
fuera de su padre permitido. Juntos dan dos niveles: qué nombra un consumidor dentro de un package, y
qué packages puede importar siquiera.

```text
commerce/                               módulo Go example.com/commerce
├── inventory/inventory.go              package inventory: API, error del contrato y fábrica
├── inventory/internal/ledger/ledger.go importable solo desde inventory/ y sus subdirectorios
└── orders/create_order.go              package orders: usa inventory.API
```

```go
package inventory

import (
	"errors"
	"fmt"

	"example.com/commerce/inventory/internal/ledger"
)

// ErrInsufficientInventory es parte del contrato: el consumidor decide con errors.Is
var ErrInsufficientInventory = errors.New("insufficient inventory")

// API es la conversación que otros módulos pueden tener con inventory
type API interface {
	Reserve(orderID string, unitsBySKU map[string]int) (reservationID string, err error)
}

// service empieza en minúscula: no se exporta fuera del package
type service struct{ stock *ledger.Ledger }

func New(initial map[string]int) API { return &service{stock: ledger.New(initial)} }

func (s *service) Reserve(orderID string, unitsBySKU map[string]int) (string, error) {
	for sku, quantity := range unitsBySKU {
		if s.stock.Available(sku) < quantity {
			return "", fmt.Errorf("%w: %s", ErrInsufficientInventory, sku)
		}
	}
	for sku, quantity := range unitsBySKU {
		s.stock.Take(sku, quantity)
	}
	return "res-" + orderID, nil
}
```

```go
// Package ledger guarda el stock; por estar bajo internal/ solo lo importa inventory
package ledger

type Ledger struct{ units map[string]int }

func New(initial map[string]int) *Ledger {
	units := make(map[string]int, len(initial))
	for sku, quantity := range initial {
		units[sku] = quantity
	}
	return &Ledger{units: units}
}

func (l *Ledger) Available(sku string) int { return l.units[sku] }

func (l *Ledger) Take(sku string, quantity int) { l.units[sku] -= quantity }
```

```go
package orders

import (
	"errors"

	"example.com/commerce/inventory"
)

// CreateOrder depende de inventory.API, no del stock
func CreateOrder(inv inventory.API, orderID string, unitsBySKU map[string]int) string {
	reservationID, err := inv.Reserve(orderID, unitsBySKU)
	switch {
	case errors.Is(err, inventory.ErrInsufficientInventory):
		return "REJECTED " + err.Error()
	case err != nil:
		return "FAILED " + err.Error()
	}
	return "CONFIRMED " + reservationID
}
```

- El resultado de negocio viaja como error centinela envuelto con `%w`. `orders` lo reconoce con
  `errors.Is` sin comparar textos, y `inventory` puede añadir el SKU al mensaje sin romper a nadie.
  Go no tiene uniones cerradas: a diferencia del `sealed` de Java, un resultado nuevo **no** rompe la
  compilación del consumidor; por eso `CreateOrder` trata cualquier otro error como `FAILED`.
- `service` no se exporta; `New` devuelve la interfaz. El consumidor no puede construir ni inspeccionar
  la implementación.
- `Ledger` sí exporta `Available` y `Take`, porque `inventory` los necesita desde otro package. Lo que
  impide que `orders` los use no es la mayúscula, sino el directorio `internal/`.

Un atajo en `orders` que importe el libro de stock no compila:

```go
package orders

import "example.com/commerce/inventory/internal/ledger"

// Atajo que el límite debe impedir: restar stock sin pasar por inventory
func shortcut() { ledger.New(map[string]int{"SKU-001": 2}).Take("SKU-001", 1) }
```

```bash
go build ./...
```

- `go build` compila los packages sin producir binarios para los que no son `main`.
- `./...` recorre todos los packages del módulo, incluido `orders`, donde está el atajo.

```text
package example.com/commerce/orders
	orders/shortcut.go:3:8: use of internal package example.com/commerce/inventory/internal/ledger not allowed
```

La regla la aplica la herramienta `go`, no una convención: un import de `…/inventory/internal/…` solo
se acepta desde código bajo `inventory/`. Su límite es la otra cara de la misma regla: cualquier
subpackage de `inventory/` sí puede importarlo, así que dentro del módulo la disciplina vuelve a ser
tuya.

**Validación.** Ejemplo ilustrativo en memoria, sin transacción ni concurrencia. El 2026-09-29 se
compiló con `go1.27.1` y pasó `go vet ./...`; con dos unidades de `SKU-001`, un pedido de dos devuelve
`CONFIRMED res-o-1` y el siguiente de una, `REJECTED insufficient inventory: SKU-001`. La salida del
atajo es la literal.

Java ofrece más niveles de visibilidad; Go favorece packages pequeños y API por nombres exportados.
En ambos, hacer algo accesible no significa que forme parte de un contrato bien diseñado.

## 6. 🌐 Por qué no REST interno

Añadir HTTP entre módulos del mismo proceso introduce serialización, manejo de timeout y semántica
remota sin autonomía de despliegue. Una interfaz local explícita conserva llamada, error y
transacción locales. Si el módulo se extrae algún día, el contrato remoto se diseña según latencia,
compatibilidad y fallos de ese momento; no se simula hoy.

## 7. ⚖️ Decisión y coste

Expón la conversación mínima que otro módulo necesita y devuelve resultados que le permitan decidir
sin conocer el interior. El coste es mantener tipos, mapeos y pruebas de contrato. Se justifica por
contención de cambio y protección de invariantes, no por una extracción hipotética.

## ⚠️ Errores frecuentes

- «Una clase `public` es una API diseñada». Solo indica accesibilidad.
- «Cada módulo necesita REST interno». La red no crea encapsulación.
- «La API debe devolver la entidad completa». Eso filtra modelo y persistencia.
- «Una interfaz por clase mejora el límite». La interfaz debe representar una conversación.
- «Como desplegamos juntos, cualquier import vale». El coste aparece en el siguiente cambio.

## 8. ✅ Veredicto

Una API interna protege decisiones: nombra intenciones, publica vistas y conserva resultados útiles,
mientras deja modelo, persistencia y pasos internos detrás del límite. Usa el mecanismo de
visibilidad del lenguaje y un control complementario; evita pagar semántica de red dentro de un
despliegue que todavía es uno.

## 📚 Referencias

- [Exported identifiers, The Go Programming Language Specification](https://go.dev/ref/spec#Exported_identifiers)
- [Internal packages, comando go](https://pkg.go.dev/cmd/go#hdr-Internal_packages)
- [Controlling Access to Members of a Class, Oracle](https://docs.oracle.com/javase/tutorial/java/javaOO/accesscontrol.html)
- [JAR File Specification — Modular JAR files, Oracle](https://docs.oracle.com/en/java/javase/25/docs/specs/jar/jar.html#modular-jar-files)
- [Organizing a Go module, Go](https://go.dev/doc/modules/layout)
- [Go Doc Comments, Go](https://go.dev/doc/comment)

## 🧠 Preguntas

1. 🟢 ¿Qué es la API pública de un módulo?
2. 🟢 ¿Qué diferencia hay entre accesibilidad y contrato diseñado?
3. 🟢 ¿Qué expresa un comando interno?
4. 🟢 ¿Qué expresa una consulta publicada?
5. 🟢 ¿Por qué conviene devolver un resultado explícito?
6. 🟢 ¿Qué debería permanecer detrás del límite de `inventory`?
7. 🟢 ¿Qué protege el directorio `internal` de Go?
8. 🟡 ¿Por qué exponer un repository rompe la encapsulación del módulo?
9. 🟡 ¿Qué problema crea devolver una entidad ORM a otro módulo?
10. 🟡 ¿Cuándo un tipo merece formar parte de la API?
11. 🟡 ¿Por qué un CRUD genérico puede debilitar invariantes?
12. 🟡 ¿Qué ventaja tiene poder cambiar productor y consumidor en un mismo commit?
13. 🟡 ¿Por qué aun así importa mantener una superficie estable?
14. 🟡 ¿Cuándo usarías una deprecación temporal dentro del monolito?
15. 🟡 ¿Qué diferencia práctica hay entre package-private de Java y un nombre no exportado de Go?
16. 🟡 ¿Qué no resuelven por sí solos JPMS o `internal`?
17. 🟡 ¿Por qué REST interno añade coste sin garantizar autonomía?
18. 🟠 `orders` necesita mostrar disponibilidad de cien productos. ¿Diseñarías comando, consulta o acceso a tabla?
19. 🟠 Un consumidor depende de quince campos de `InventoryReservation`. ¿Cómo reducirías el contrato sin ocultar información necesaria?
20. 🟠 Un framework instancia por reflexión una clase interna. ¿Qué control adicional propones?
21. 🟠 Cambiar un resultado exige modificar seis consumidores. ¿Qué revisarías antes de versionar la API?
22. 🟠 Un equipo quiere una interfaz para cada repository «por si se extrae». ¿Cómo responderías?
23. 🟠 ¿Qué prueba demuestra que `orders` no conoce detalles de persistencia de `inventory`?
24. 🟠 ¿Qué criterio usarías para retirar una ruta de compatibilidad interna?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [01 — Módulos alrededor de capacidades de negocio](01-modulos-alrededor-de-capacidades-de-negocio.md).

**Siguiente:** [03 — Dirección de dependencias y ciclos entre módulos](03-direccion-de-dependencias-y-ciclos-entre-modulos.md).
