# 01 — Módulos alrededor de capacidades de negocio

Aprenderás a proponer módulos por lenguaje, invariantes y razones de cambio, no por tipo técnico. El
objetivo es que un cambio de negocio tenga un hogar reconocible sin convertir cada carpeta en un
servicio remoto imaginario.

## 1. 🎯 El problema de cortar por tecnología

En una estructura `controllers/services/repositories`, `CreateOrder` atraviesa tres carpetas y suele
compartir modelos con reserva, pago y correo. Añadir una política de expiración obliga a navegar por
capas y no deja claro quién posee la decisión.

```text
capas técnicas                    capacidades
controllers/                      orders/
services/                         inventory/
repositories/                     payments/
models/                           notifications/
```

Las capas siguen existiendo dentro de cada capacidad cuando aportan valor. Lo que cambia es la
unidad principal de comprensión y cambio.

## 2. 🧭 Capacidad, subdominio y contexto acotado

- **Capacidad de negocio:** qué sabe hacer la organización, como gestionar pedidos o cobrar.
- **Subdominio:** parte del espacio del problema que contiene conocimiento relacionado.
- **Contexto acotado (*bounded context*):** límite dentro del cual un modelo y lenguaje son
  consistentes; fuera puede existir otra interpretación.
- **Módulo:** mecanismo de software que protege una responsabilidad dentro del despliegue.

No son sinónimos uno a uno. Un contexto puede requerir varios módulos técnicos; una capacidad
pequeña puede convivir en un módulo mayor. DDD aporta lenguaje para descubrir fronteras, no una
fórmula que convierta sustantivos en carpetas.

## 3. 🛒 Un corte vertical del sistema de ejemplo

| Módulo | Decide | Posee | Publica |
|---|---|---|---|
| `orders` | ciclo y total del pedido | pedidos y líneas | creación, consulta y estado |
| `inventory` | disponibilidad y reservas | stock y reservas | reservar, liberar, consultar |
| `payments` | autorización y estado de cobro | intentos y autorizaciones | autorizar y consultar resultado |
| `notifications` | canal, plantilla y entrega | mensajes y preferencias | solicitar y consultar entrega |

```text
CreateOrder
   ├─► orders valida intención
   ├─► inventory decide reserva
   ├─► payments decide autorización
   └─► notifications recibe un hecho o solicitud posterior
```

El flujo no convierte a `orders` en dueño de todo. Cada módulo conserva sus invariantes y ofrece
una colaboración explícita. El despliegue sigue siendo uno y una transacción local puede cruzar
módulos cuando una garantía lo justifique.

## 4. 📐 Elegir granularidad

Un buen candidato reúne lenguaje, datos y cambios relacionados. Señales para dividir: dos políticas
evolucionan por motivos distintos, tienen owners distintos o una parte necesita controles propios.
Señales para fusionar: cada operación cruza ambos lados, el contrato repite el modelo entero y nadie
puede explicar una decisión independiente.

Empieza grueso. `inventory` puede incluir disponibilidad y reservas mientras el equipo aprende. Si
la reposición adquiere reglas y cadencia propias, se revisa con evidencia. El coste de demasiados
módulos es navegación, contratos y coordinación; el de muy pocos es radio de cambio y ownership
difuso.

## 5. 🔍 Evidencia antes del árbol

1. Toma cambios e incidentes reales.
2. Agrupa reglas y datos que cambian por la misma razón.
3. Identifica vocabulario ambiguo entre áreas.
4. Asigna quién decide y escribe cada estado.
5. Diseña una API mínima y prueba un flujo completo.
6. Mide si el siguiente cambio queda contenido.

La observación «precio significa catálogo en una conversación y monto pactado en otra» sugiere dos
modelos. La inferencia es una posible frontera. El diagnóstico requiere cambios, invariantes y
ownership; no basta un taller de notas adhesivas.

## 6. 🧰 Estructura idiomática mínima

El mismo corte —`orders` crea el pedido, `inventory` decide la reserva— en dos plataformas. El
objetivo no es la sintaxis: es comprobar **qué atajo impide el lenguaje y cuál deja pasar**, porque
eso decide cuánto control adicional necesitas.

### Java: el paquete como frontera

```text
commerce/
├── inventory/InventoryApi.java       public: comando, resultados y fábrica
├── inventory/InventoryService.java   sin modificador: invisible fuera del paquete
├── inventory/StockLedger.java        sin modificador: el stock no sale del módulo
└── orders/CreateOrder.java           public: usa solo InventoryApi
```

```java
package commerce.inventory;

import java.util.Map;

// Superficie pública de inventory: lo único que otro módulo puede nombrar
public interface InventoryApi {
    ReservationResult reserve(String orderId, Map<String, Integer> unitsBySku);

    sealed interface ReservationResult permits Reserved, InsufficientInventory {}
    record Reserved(String reservationId) implements ReservationResult {}
    record InsufficientInventory(String sku) implements ReservationResult {}

    // El ejecutable compone el módulo sin conocer sus clases internas
    static InventoryApi create(Map<String, Integer> initialStock) {
        return new InventoryService(new StockLedger(initialStock));
    }
}
```

```java
package commerce.inventory;

import java.util.HashMap;
import java.util.Map;

// El stock es interno: ningún otro módulo puede leerlo ni restarlo
final class StockLedger {
    private final Map<String, Integer> units;

    StockLedger(Map<String, Integer> initial) { units = new HashMap<>(initial); }

    int available(String sku) { return units.getOrDefault(sku, 0); }

    void take(String sku, int quantity) { units.merge(sku, -quantity, Integer::sum); }
}
```

```java
package commerce.inventory;

import java.util.Map;

// Sin modificador: visible solo dentro del paquete commerce.inventory
final class InventoryService implements InventoryApi {
    private final StockLedger ledger;

    InventoryService(StockLedger ledger) { this.ledger = ledger; }

    @Override
    public ReservationResult reserve(String orderId, Map<String, Integer> unitsBySku) {
        for (var line : unitsBySku.entrySet()) {
            if (ledger.available(line.getKey()) < line.getValue()) {
                return new InsufficientInventory(line.getKey());
            }
        }
        unitsBySku.forEach(ledger::take);
        return new Reserved("res-" + orderId);
    }
}
```

```java
package commerce.orders;

import commerce.inventory.InventoryApi;
import commerce.inventory.InventoryApi.InsufficientInventory;
import commerce.inventory.InventoryApi.Reserved;
import java.util.Map;

// Caso de uso de orders: depende de la API de inventory, no de su stock
public final class CreateOrder {
    private final InventoryApi inventory;

    public CreateOrder(InventoryApi inventory) { this.inventory = inventory; }

    public String handle(String orderId, Map<String, Integer> unitsBySku) {
        return switch (inventory.reserve(orderId, unitsBySku)) {
            case Reserved r -> "CONFIRMED " + r.reservationId();
            case InsufficientInventory i -> "REJECTED missing " + i.sku();
        };
    }
}
```

- `InventoryApi` es la única puerta: un comando (`reserve`), dos resultados cerrados con `sealed` y
  una fábrica. El `switch` de `CreateOrder` es exhaustivo; si `inventory` añade un tercer resultado,
  `orders` deja de compilar y el cambio de contrato se vuelve visible.
- `StockLedger` e `InventoryService` no llevan modificador de acceso, así que son *package-private*.
  Esa es la garantía: el stock solo cambia a través de la regla de reserva.
- La regla vive en el paquete raíz del módulo a propósito. En Java, un subpaquete
  `inventory.internal` **no** hereda privacidad: para que `inventory` lo usara, sus clases tendrían
  que ser `public` y cualquier otro módulo podría importarlas. Ese es el agujero que cierran JPMS o
  una prueba arquitectónica ([`02/06`](06-codigo-compartido-shared-kernel-y-controles-arquitectonicos.md)).

Un atajo en `orders` que intente restar stock directamente no llega a compilar:

```java
package commerce.orders;

import commerce.inventory.StockLedger;
import java.util.Map;

// Atajo que el límite debe impedir: restar stock sin pasar por inventory
class ShortcutReservation {
    void reserve() {
        new StockLedger(Map.of("SKU-001", 2)).take("SKU-001", 1);
    }
}
```

```text
bad/commerce/orders/ShortcutReservation.java:3: error: StockLedger is not public in commerce.inventory; cannot be accessed from outside package
import commerce.inventory.StockLedger;
                         ^
bad/commerce/orders/ShortcutReservation.java:9: error: StockLedger is not public in commerce.inventory; cannot be accessed from outside package
        new StockLedger(Map.of("SKU-001", 2)).take("SKU-001", 1);
            ^
2 errors
```

### Node/TypeScript: `export` es visible para todo el programa

```text
src/
├── inventory/index.ts                        superficie deliberada
├── inventory/internal/stock-ledger.ts        exportado, porque el servicio lo necesita
├── inventory/internal/inventory-service.ts   la regla de reserva
└── orders/create-order.ts                    importa solo desde inventory/index.ts
```

```typescript
// inventory/index.ts — superficie deliberada de inventory
export type ReservationResult =
  | { kind: "reserved"; reservationId: string }
  | { kind: "insufficient_inventory"; sku: string };

export interface InventoryApi {
  reserve(orderId: string, unitsBySku: ReadonlyMap<string, number>): ReservationResult;
}

export { createInventory } from "./internal/inventory-service.ts";
```

```typescript
// inventory/internal/stock-ledger.ts — interno de inventory, pero exportado para el servicio
export class StockLedger {
  private readonly units: Map<string, number>;
  constructor(initial: Record<string, number>) { this.units = new Map(Object.entries(initial)); }
  available(sku: string): number { return this.units.get(sku) ?? 0; }
  take(sku: string, quantity: number): void { this.units.set(sku, this.available(sku) - quantity); }
}
```

```typescript
// inventory/internal/inventory-service.ts
import type { InventoryApi } from "../index.ts";
import { StockLedger } from "./stock-ledger.ts";

export function createInventory(initial: Record<string, number>): InventoryApi {
  const ledger = new StockLedger(initial);
  return {
    reserve(orderId, unitsBySku) {
      for (const [sku, quantity] of unitsBySku) {
        if (ledger.available(sku) < quantity) return { kind: "insufficient_inventory", sku };
      }
      for (const [sku, quantity] of unitsBySku) ledger.take(sku, quantity);
      return { kind: "reserved", reservationId: `res-${orderId}` };
    },
  };
}
```

```typescript
// orders/create-order.ts — caso de uso de orders: solo conoce la superficie de inventory
import type { InventoryApi } from "../inventory/index.ts";

export function createOrder(inventory: InventoryApi) {
  return (orderId: string, unitsBySku: ReadonlyMap<string, number>): string => {
    const result = inventory.reserve(orderId, unitsBySku);
    switch (result.kind) {
      case "reserved": return `CONFIRMED ${result.reservationId}`;
      case "insufficient_inventory": return `REJECTED missing ${result.sku}`;
    }
  };
}
```

- `index.ts` reexporta la fábrica y los tipos, no `StockLedger`. Un consumidor disciplinado importa
  solo desde ahí.
- La unión discriminada por `kind` cumple el papel del `sealed` de Java: con `--strict`, un tercer
  resultado sin su `case` hace fallar la función por no devolver `string` en todos los caminos.
- `StockLedger` lleva `export` porque otro archivo del **mismo** módulo lo usa. TypeScript no tiene
  nada parecido a *package-private*: lo que se exporta para un vecino se exporta para todos.

El mismo atajo que Java rechazó aquí compila sin una advertencia:

```typescript
// orders/shortcut.ts — resta stock sin pasar por inventory
import { StockLedger } from "../inventory/internal/stock-ledger.ts";

new StockLedger({ "SKU-001": 2 }).take("SKU-001", 1);
```

```bash
tsc --strict --noEmit --module nodenext --target es2022 --allowImportingTsExtensions \
  src/main.ts src/orders/shortcut.ts
echo "tsc exit=$?"
```

- `--strict` activa las comprobaciones que hacen útil la unión discriminada.
- `--noEmit` solo verifica tipos; no genera JavaScript.
- `--module nodenext` resuelve imports como Node; `--allowImportingTsExtensions` permite escribir la
  extensión `.ts` en los imports, que es lo que Node 24 necesita para ejecutar el archivo sin compilar.
- `--target es2022` fija la versión de JavaScript contra la que se comprueban los tipos.
- `src/main.ts` compone los dos módulos; `src/orders/shortcut.ts` es el atajo.

```text
tsc exit=0
```

El compilador no ve ningún límite. Lo imponen `exports` de `package.json` cuando cada módulo es un
paquete del workspace, *project references* o una regla de imports en el linter; cuál elegir es la
decisión de [controles arquitectónicos](06-codigo-compartido-shared-kernel-y-controles-arquitectonicos.md).
Go ofrece un punto intermedio con los directorios `internal`, que el compilador sí respeta (se ve en
[`02/02`](02-api-publica-del-modulo-y-encapsulacion-interna.md)); Python depende de convenciones y
reglas de importación. En las cuatro plataformas el mecanismo protege un límite ya elegido: no
descubre la capacidad.

**Validación.** Ejemplo ilustrativo en memoria, sin transacción ni concurrencia (su dueño es
[concurrencia e idempotencia](../03-datos-ejecucion-y-operacion/02-concurrencia-locking-e-idempotencia.md)).
El 2026-09-29 se compiló con `javac 25.0.4` y se comprobó con `tsc 5.8.3` y Node 24.21.0: con dos
unidades de `SKU-001`, un pedido de dos devuelve `CONFIRMED res-o-1` y el siguiente de una,
`REJECTED missing SKU-001`, en las dos plataformas. Las salidas de error de arriba son las literales.

## 7. ⚖️ Decisión y coste

Organiza verticalmente cuando necesitas contener cambios y hacer visible ownership sin perder las
garantías locales. Conserva capas simples si el sistema es pequeño y sus cambios son previsibles.
Paga estructura y controles solo donde exista una razón de cambio; no diseñes cada módulo como HTTP
ni prometas que será extraíble.

## ⚠️ Errores frecuentes

- «Controllers, services y repositories son módulos de negocio». Son roles técnicos.
- «Un sustantivo crea un módulo». El límite necesita comportamiento e invariantes.
- «Un bounded context equivale a un microservicio». Es un límite de modelo, no de despliegue.
- «Cuantos más módulos, mejor». La fragmentación también acopla.
- «Vertical slice significa duplicar todo». Comparte mecanismos estables sin mezclar ownership.

## 8. ✅ Veredicto

El módulo es una unidad de cambio protegida, no una carpeta. Descúbrelo con lenguaje, invariantes,
datos y co-cambios; materialízalo con una API y controles proporcionales. Empieza con límites gruesos
y revisables, manteniendo una sola unidad de despliegue mientras la autonomía operativa no aporte
valor suficiente.

## 📚 Referencias

- [Bounded Context, Martin Fowler](https://martinfowler.com/bliki/BoundedContext.html)
- [Presentation Domain Data Layering, Martin Fowler](https://martinfowler.com/bliki/PresentationDomainDataLayering.html)
- [Organizing a Go module, Go](https://go.dev/doc/modules/layout)
- [Project References, TypeScript](https://www.typescriptlang.org/docs/handbook/project-references)
- [Controlling Access to Members of a Class, Oracle Java Tutorials](https://docs.oracle.com/javase/tutorial/java/javaOO/accesscontrol.html)
- [Package entry points, Node.js](https://nodejs.org/api/packages.html#package-entry-points)

## 🧠 Preguntas

1. 🟢 ¿Qué diferencia hay entre una capa técnica y una capacidad de negocio?
2. 🟢 ¿Qué es un subdominio?
3. 🟢 ¿Qué es un contexto acotado?
4. 🟢 ¿Qué es un módulo en un monolito modular?
5. 🟢 ¿Por qué capacidad, contexto y módulo no son equivalentes uno a uno?
6. 🟢 ¿Qué significa organizar por vertical slices?
7. 🟢 ¿Qué decisiones pertenecen a `inventory` en el sistema de ejemplo?
8. 🟡 ¿Por qué `controllers/services/repositories` no expresa ownership de negocio?
9. 🟡 ¿Qué evidencia usarías para proponer una frontera entre `orders` e `inventory`?
10. 🟡 ¿Cómo ayuda un cambio de significado en el lenguaje a descubrir límites?
11. 🟡 ¿Qué indica que dos módulos candidatos deberían fusionarse?
12. 🟡 ¿Qué indica que un módulo debería dividirse?
13. 🟡 ¿Por qué conviene empezar con límites relativamente gruesos?
14. 🟡 ¿Qué coste introduce una granularidad excesiva?
15. 🟡 ¿Cómo compruebas que un módulo contiene cambios en la práctica?
16. 🟡 ¿Por qué una clase Java `public` o un `index.ts` no constituyen una API diseñada?
17. 🟡 ¿Qué preserva un corte vertical dentro de un único despliegue?
18. 🟠 Un cambio de promociones toca `orders`, `payments` y `notifications`. ¿Qué investigarías antes de crear un módulo `promotions`?
19. 🟠 Dos equipos usan «reserva» con significados distintos. ¿Qué experimento de diseño propondrías?
20. 🟠 Cada operación de dos módulos cruza sus APIs y tablas. ¿Qué hipótesis formularías sobre el límite?
21. 🟠 El equipo quiere un módulo por entidad de base de datos. ¿Cómo reorientarías la decisión?
22. 🟠 Un módulo crece, pero todos sus cambios siguen una misma política. ¿Lo dividirías?
23. 🟠 ¿Qué primera costura crearías en un monolito por capas sin mover todos los archivos?
24. 🟠 ¿Qué criterio de parada usarías al reorganizar por capacidades?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [08 — Respuestas: Fundamentos y modelo mental](../01-fundamentos-y-modelo-mental/08-respuestas.md).

**Siguiente:** [02 — API pública del módulo y encapsulación interna](02-api-publica-del-modulo-y-encapsulacion-interna.md).
