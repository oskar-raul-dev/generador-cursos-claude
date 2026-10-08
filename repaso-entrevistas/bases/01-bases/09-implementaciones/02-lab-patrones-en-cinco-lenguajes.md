# 02 — Lab: los patrones aplicados en cinco lenguajes

> **Documento opcional.** Está fuera del hilo principal. Su teoría **no está en este corpus**: los
> patrones GoF se estudian en
> [`repaso-arquitectura-entrevistas/01-bases/04`](../../../arquitectura/01-bases/01-bases/04-patrones-gof.md)
> y en [`preguntas-entrevista/01`](../../../../preguntas-entrevista/01-poo-solid-patrones.md). Esto es el
> **lab**: los mismos diez patrones escritos en Java, Python, JavaScript, TypeScript y Go, para ver
> cuáles sobreviven al cambio de lenguaje y cuáles se evaporan.
> **Versiones ejecutadas:** Java **21.0.12 y 17.0.15** (Zulu, vía sdkman), Python 3.13, Node 24.21,
> Go 1.27. La sección [8](#8--visitor-el-patrón-que-java-21-elimina) es la única que exige 21, y trae
> el error real de compilación en 17 como prueba. TypeScript se comprueba con `tsc --noEmit
> --strict`, y sus mensajes de error van copiados literales.
>
> **Vigencia:** 2026-09-18.

**Salto rápido:** [1 — la tesis](#1--la-tesis-del-lab) · [2 — Strategy](#2--strategy) ·
[3 — Decorator](#3--decorator) · [4 — Observer](#4--observer) ·
[5 — Singleton](#5--singleton) · [6 — Builder y Factory](#6--builder-y-factory) ·
[7 — Template Method y Command](#7--template-method-y-command) ·
[8 — Visitor](#8--visitor-el-patrón-que-java-21-elimina) ·
[9 — la tabla de supervivencia](#9-️-la-tabla-de-supervivencia)

---

## 1. 🎯 La tesis del lab

El catálogo GoF se escribió en 1994 contra C++ y Smalltalk. **Varios de sus patrones son rodeos
alrededor de limitaciones del lenguaje**, no verdades eternas: cuando el lenguaje gana funciones de
primera clase, módulos o tipos algebraicos, el patrón deja de ser una estructura de clases y pasa a
ser una línea.

Este lab lo hace visible escribiendo los mismos diez patrones en cinco lenguajes. La conclusión
adelantada, porque es la que vale en una entrevista:

```text
Patrones que sobreviven intactos:      Adapter, Proxy, Command
Patrones que se vuelven una función:   Strategy, Decorator, Template Method, Factory Method
Patrones que se vuelven sintaxis:      Builder (record/dataclass), Observer (eventos nativos)
Patrones que desaparecen:              Singleton (el módulo ya lo es), Visitor (sealed + switch, §8)
```

> **Regla de entrevista:** la mejor respuesta a *"¿qué opinas de los patrones de diseño?"* no es una
> opinión: es un ejemplo concreto de un patrón que el lenguaje absorbió. `sealed` + pattern matching
> matando a Visitor, o el módulo de Python siendo un Singleton, valen más que cualquier declaración
> general.

---

## 2. 🧱 Strategy

**El problema.** Un algoritmo que varía —el cálculo de comisión por tipo de cuenta— resuelto con un
`switch` que crece en cada release.

**Java.** Una interfaz funcional, y el `Map` inyectado que es el idioma de Spring:

```java
interface CalculoDeComision { long calcular(long monto); }

Map<String, CalculoDeComision> estrategias = Map.of(
        "CORRIENTE", monto -> monto / 100,      // una lambda: no hace falta una clase por estrategia
        "PREMIUM",   monto -> 0L);

estrategias.get("CORRIENTE").calcular(50_000);   // → 500
```

- **Con un solo método, la interfaz es funcional y la estrategia es una lambda.** Las tres clases
  que pedía el GoF se convierten en tres líneas.
- En una aplicación Spring, el `Map<String, T>` se inyecta solo con todas las implementaciones, y el
  nombre del bean es la clave. Añadir una estrategia es añadir un bean.

**Python.** Un diccionario de funciones. **No hay interfaz porque no hace falta**:

```python
estrategias = {
    "CORRIENTE": lambda monto: monto // 100,
    "PREMIUM":   lambda monto: 0,
}
estrategias["CORRIENTE"](50_000)     # → 500
```

**Go.** Un **tipo función**, que es la forma más explícita de las cinco:

```go
type CalculoDeComision func(monto int64) int64

estrategias := map[string]CalculoDeComision{
	"CORRIENTE": func(m int64) int64 { return m / 100 },
	"PREMIUM":   func(m int64) int64 { return 0 },
}
estrategias["CORRIENTE"](50000)      // → 500
```

- `type X func(...)` le da **nombre al contrato** sin necesidad de interfaz ni de clase. Es
  probablemente la expresión más limpia de Strategy de los cinco lenguajes.

**JavaScript.** Un objeto de funciones, idéntico a Python.

**TypeScript.** Aquí **sí aporta**, y es uno de los dos únicos patrones de este documento donde el
tipo cambia la respuesta —el otro es [Visitor, §8](#8--visitor-el-patrón-que-java-21-elimina)—: un
tipo unión de claves literales convierte el `switch` exhaustivo en una comprobación de compilación.

```typescript
type TipoCuenta = "CORRIENTE" | "PREMIUM";
const estrategias: Record<TipoCuenta, (monto: number) => number> = {
  CORRIENTE: (monto) => Math.floor(monto / 100),
  PREMIUM:   () => 0,
};
// Añadir un TipoCuenta sin añadir su estrategia NO COMPILA. Eso es exhaustividad estática.
```

Añadiendo `"AHORRO"` al tipo y no al objeto, `tsc --strict` dice exactamente esto:

```text
error TS2741: Property 'AHORRO' is missing in type
  '{ CORRIENTE: (monto: number) => number; PREMIUM: () => number; }'
  but required in type 'Record<TipoCuenta, (monto: number) => number>'.
```

- **Es la única de las cinco plataformas que lo detecta antes de ejecutar.** En Java, un
  `Map<String, T>` con una clave que falta devuelve `null` en producción; aquí no compila.

> **Veredicto:** Strategy sobrevive en los cinco, y en ninguno necesita la jerarquía de clases del
> GoF. Es el patrón que mejor demuestra que "patrón" no significa "jerarquía".

---

## 3. 🧱 Decorator

**El problema.** Añadir comportamiento —un tope, un caché, una traza— sin tocar la implementación ni
heredar de ella.

**Java.** Una función que recibe la estrategia y devuelve otra:

```java
static CalculoDeComision conTope(CalculoDeComision base, long tope) {
    return monto -> Math.min(base.calcular(monto), tope);   // envuelve y delega
}

CalculoDeComision limitada = conTope(estrategias.get("CORRIENTE"), 600);
limitada.calcular(50_000);      // → 500   (el tope no se alcanza)
limitada.calcular(1_000_000);   // → 600   (el tope corta)
```

**Python.** Es **literalmente sintaxis del lenguaje**:

```python
def con_tope(tope):
    def envoltura(fn):
        def interior(monto):
            return min(fn(monto), tope)
        return interior
    return envoltura

@con_tope(600)
def comision_corriente(monto):
    return monto // 100

comision_corriente(50_000)      # → 500
comision_corriente(1_000_000)   # → 600
```

- **El `@` de Python se llama "decorador" por este patrón.** Es el caso más claro de un patrón GoF
  absorbido por la gramática de un lenguaje, y decirlo en una entrevista conecta los dos mundos.

**Go y JavaScript.** Funciones de orden superior, idénticas en forma a la de Java:

```go
func conTope(base CalculoDeComision, tope int64) CalculoDeComision {
	return func(monto int64) int64 {
		if c := base(monto); c < tope { return c }
		return tope
	}
}
```

```javascript
const conTope = (base, tope) => (monto) => Math.min(base(monto), tope);
```

**TypeScript.** No aporta nada sobre JavaScript en runtime. Tiene decoradores de clase desde la
versión 5, pero son otra cosa —metaprogramación sobre clases— y no este patrón.

> 💡 **Truco.** Decorator y Proxy tienen **el mismo mecanismo y distinta intención**: Decorator
> **añade** funcionalidad opcional y se apilan varios; Proxy **controla el acceso** y suele ser uno.
> Es la distinción que más se falla, y en los cinco lenguajes se escribe igual — lo que refuerza que
> la diferencia es de intención, no de código.

---

## 4. 🧱 Observer

**Java.** El `ApplicationEvent` de Spring, y la anotación que casi nadie usa:

```java
@TransactionalEventListener(phase = AFTER_COMMIT)
void alConfirmarPedido(PedidoConfirmado evento) { ... }
```

- Sin `AFTER_COMMIT`, el listener corre **dentro** de la transacción: si esta hace rollback, ya
  mandaste el correo de un pedido que no existe.
- Los eventos de Spring son **síncronos y en memoria**. No son mensajería: sin durabilidad, sin
  reintento, sin cola de mensajes muertos.

**JavaScript.** Viene en la plataforma, sin biblioteca:

```javascript
const emisor = new EventTarget();
emisor.addEventListener("PedidoConfirmado", (e) => console.log("listener:", e.detail));
emisor.dispatchEvent(new CustomEvent("PedidoConfirmado", { detail: "P-1" }));
// → listener: P-1
```

**Go.** No hay Observer: hay **canales**, que son un mecanismo distinto y mejor para el mismo
problema.

```go
eventos := make(chan string, 10)
go func() { for e := range eventos { fmt.Println("listener:", e) } }()
eventos <- "P-1"
```

- El canal desacopla **en el tiempo** además de en el tipo, y trae backpressure de serie si tiene
  capacidad acotada. Es una respuesta mejor que Observer al mismo problema, y Go la puso en el
  lenguaje en vez de en un catálogo.

**Python.** No hay nada nativo equivalente; se usa una lista de *callables* o una biblioteca de
señales (`blinker`, las señales de Django).

**TypeScript.** No aporta en runtime; sí permite tipar el mapa de evento a payload, lo que evita
despachar un evento con el detalle equivocado.

---

## 5. 🧱 Singleton

**El patrón que desaparece en cuatro de los cinco lenguajes.**

| Lenguaje | Cómo se consigue una única instancia | ¿Hay patrón que escribir? |
|---|---|---|
| **Java** | Scope singleton del contenedor, o `enum` de un solo valor | **No**: lo da Spring, inyectable y sustituible |
| **Python** | **El módulo**: se evalúa una sola vez al importarse | **No**, y escribirlo es un error de novato |
| **JavaScript** | **El módulo ESM**: se evalúa una sola vez | **No** |
| **TypeScript** | Igual que JavaScript | **No** |
| **Go** | Variable de paquete, con `sync.Once` si hay inicialización perezosa | **No**, es una construcción del lenguaje |

- **En Python y en JavaScript, un módulo importado dos veces se ejecuta una sola vez.** Sus
  variables de nivel superior **son** un singleton, con inicialización perezosa incluida. Implementar
  la clase con `__new__` sobrescrito es reinventar algo que ya tienes.
- En Java, el scope singleton de Spring da lo mismo **sin los defectos**: una instancia, pero
  inyectable, sustituible en test y sin estado global estático. El `enum` de un solo valor es la
  forma correcta cuando no hay contenedor, y es el ítem 3 de *Effective Java*.
- En Go, `sync.Once` garantiza que la inicialización ocurra exactamente una vez incluso con
  goroutines concurrentes. Es el patrón resuelto por la biblioteca estándar.

> ⚠️ **Advertencia.** El problema del Singleton nunca fue "cómo tener una instancia": era el
> **estado global** y la **dependencia estática**, que hacen imposible sustituirlo en un test. Las
> cinco soluciones de arriba resuelven lo primero; solo la inyección resuelve lo segundo. Decir eso
> es lo que distingue la respuesta.

---

## 6. 🧱 Builder y Factory

**Builder.** Su valor real no es la legibilidad: es **garantizar que no existe un objeto a medio
construir**. En los lenguajes modernos, el caso trivial lo resuelve la sintaxis.

```java
record Pedido(String id, long total) { }          // equals, hashCode y toString generados
new Pedido("P-1", 9950).equals(new Pedido("P-1", 9950));   // → true
```

```python
from dataclasses import dataclass

@dataclass(frozen=True)          # frozen: inmutable y hashable
class Pedido:
    id: str
    total: int
```

- **Java 16+ y Python con `dataclass` cubren el Builder trivial** con una línea. El Builder escrito a
  mano solo se justifica cuando hay **validación al construir**: el `build()` que rechaza un objeto
  inválido es la versión que aporta.
- En Go no hay ni una cosa ni la otra: el idioma es un struct con campos exportados y una función
  `NuevoPedido(...)` que valida y devuelve `(Pedido, error)`. **El error como valor de retorno hace
  innecesario el Builder** para el caso de validación, que era su único caso fuerte.
- En JavaScript y TypeScript, un objeto literal con desestructuración y valores por defecto cubre
  casi todo; TypeScript añade que el compilador exija los campos obligatorios.

**Factory Method.** En una aplicación con contenedor de dependencias, **el contenedor es la
fábrica** y apenas escribes ninguna. Fuera de ahí, en los cinco lenguajes se reduce a una función
que devuelve la implementación correcta —no hace falta jerarquía—. En Go es especialmente directo,
porque una función que devuelve una interfaz **es** el patrón entero.

---

## 7. 🧱 Template Method y Command

**Template Method.** El esqueleto fijo con pasos variables. En Java es el sufijo `Template` de
Spring —`JdbcTemplate`, `RestTemplate`, `TransactionTemplate`— y **por eso se llaman así**: la clase
pone abrir recurso, manejar errores y cerrar recurso, y tú pones el trozo variable.

En los lenguajes con funciones de primera clase, el patrón **se reduce a pasar una función**:

```python
def con_transaccion(operacion):          # el esqueleto
    conexion = abrir()
    try:
        resultado = operacion(conexion)  # el hueco
        conexion.commit()
        return resultado
    except Exception:
        conexion.rollback()
        raise
    finally:
        conexion.close()
```

- Es el mismo patrón sin herencia ni clase abstracta. Y es **exactamente** lo que hace
  `TransactionTemplate.execute(...)` en Java con una lambda.

**Command.** Convertir una petición en un objeto para poder encolarla, registrarla, reintentarla o
deshacerla. **Es el patrón que mejor sobrevive**, porque su valor no es sintáctico sino estructural:

| Lenguaje | Encarnación |
|---|---|
| **Java** | `Runnable`, `Callable`, los `Step` de Spring Batch, un mensaje de broker |
| **Python** | Un *callable*, o una tupla `(funcion, args)` serializable para una cola |
| **JavaScript** | Una función o un objeto `{tipo, payload}` — que es una acción de Redux |
| **TypeScript** | Lo mismo, con el tipo unión discriminado que da exhaustividad |
| **Go** | Una `func()` enviada por un canal a un pool de workers |

- En los cinco, lo que hace útil a Command es que el comando **es un dato**: se puede serializar,
  persistir, reintentar y auditar. Por eso es el patrón que sostiene CQRS, event sourcing y las colas
  de trabajo.

---

## 8. 🪦 Visitor: el patrón que Java 21 elimina

**El problema que resolvía.** Aplicar una operación distinta a cada subtipo de una jerarquía, sin
meter esa operación dentro de las clases. En 1994 exigía *double dispatch*: cada subtipo con un
`aceptar(Visitor v)` que llamaba al método correspondiente del visitante, y una interfaz `Visitor`
con un método por subtipo. Entre diez y quince archivos para lo que conceptualmente es un `switch`.

**Lo único que aportaba de verdad** no era la indirección: era que **el compilador te obligara a
tratar todos los casos**. Añadir un subtipo rompía la compilación de todos los visitantes, que es
justo lo que querías.

**Java 21 da eso sin el patrón.** Una jerarquía `sealed` y un `switch` con patrones:

```java
sealed interface Evento permits PedidoConfirmado, PagoRechazado, PedidoEnviado {}
record PedidoConfirmado(String id) implements Evento {}
record PagoRechazado(String id, String motivo) implements Evento {}
record PedidoEnviado(String id, String transportista) implements Evento {}

static String describir(Evento evento) {
    return switch (evento) {                       // SIN default: el compilador exige los tres
        case PedidoConfirmado p -> "confirmado " + p.id();
        case PagoRechazado r    -> "rechazado " + r.id() + ": " + r.motivo();
        case PedidoEnviado e    -> "enviado " + e.id() + " por " + e.transportista();
    };
}
```

Salida real con Zulu 21.0.12:

```text
confirmado P-1
rechazado P-2: fondos
enviado P-3 por SEUR
```

- **`sealed` es lo que lo hace posible**: al declarar los subtipos permitidos, el compilador sabe que
  la lista es cerrada y puede comprobar que el `switch` los cubre todos.
- **Sin `default`, a propósito.** Un `default` apagaría la comprobación: el compilador daría el
  `switch` por completo siempre. Omitirlo es lo que convierte un olvido en un error de compilación.

**La demostración de que la exhaustividad es real**, que es lo que hay que poder enseñar. Borrando el
caso `PedidoEnviado`:

```text
Java21Incompleto.java:12: error: the switch expression does not cover all possible input values
        return switch (evento) {
               ^
1 error
```

**Y la demostración de que es de 21 y no de antes.** El mismo archivo con Zulu 17.0.15:

```text
Java21.java:13: error: patterns in switch statements are a preview feature and are disabled by default.
            case PedidoConfirmado p    -> "confirmado " + p.id();
  (use --enable-preview to enable patterns in switch statements)
```

**Qué se pierde.** Visitor permitía añadir **operaciones nuevas** sin tocar la jerarquía; con
`sealed` la jerarquía es cerrada a propósito, así que añadir un **subtipo** obliga a tocar todos los
`switch`. Es el *expression problem* de siempre: se elige qué eje quieres que sea barato de extender.
En un dominio —tipos de evento, estados de un pedido, formas de pago— lo que casi nunca cambia son
los subtipos y lo que cambia a diario son las operaciones, y ahí `sealed` es la elección correcta.

**En los otros cuatro lenguajes** el patrón nunca llegó a existir en esta forma:

| Lenguaje | Equivalente | ¿Hay exhaustividad comprobada? |
|---|---|---|
| **Python** | `match` estructural, o `functools.singledispatch` | ❌ nada lo comprueba |
| **JavaScript** | `switch` sobre `{tipo, payload}` | ❌ nada lo comprueba |
| **TypeScript** | **Unión discriminada** + `never` en el `default` | ✅ **sí**, y es su mejor argumento |
| **Go** | *type switch* sobre una interfaz | ❌ Go no tiene uniones cerradas |

```typescript
type Evento =
  | { tipo: "PedidoConfirmado"; id: string }
  | { tipo: "PagoRechazado"; id: string; motivo: string };

function describir(e: Evento): string {
  switch (e.tipo) {
    case "PedidoConfirmado": return `confirmado ${e.id}`;
    case "PagoRechazado":    return `rechazado ${e.id}: ${e.motivo}`;
    default: {
      const _exhaustivo: never = e;   // si falta un caso, ESTO no compila
      return _exhaustivo;
    }
  }
}
```

- El truco del `never` es el equivalente de TypeScript al `sealed` de Java, y es **la única razón
  por la que TypeScript aparece en este documento**: aquí el tipo sí cambia la respuesta.
- **Comprobado con `tsc --strict`.** Añadiendo un tercer evento a la unión sin su `case`:

```text
error TS2322: Type '{ tipo: "PedidoEnviado"; id: string; transportista: string; }'
              is not assignable to type 'never'.
```

- Compara los dos mensajes, que es lo que hace instructivo el paralelismo: Java dice *"the switch
  expression does not cover all possible input values"* y TypeScript dice *"no es asignable a
  `never`"*. **Java lo comprueba en la gramática del `switch`; TypeScript lo deduce del estrechamiento
  de tipos** —si todos los casos están cubiertos, en el `default` no queda ningún tipo posible, y eso
  es `never`—. El mismo resultado por dos caminos muy distintos.
- Y la diferencia que importa en la práctica: el centinela de TypeScript es **opcional**. Si nadie
  escribe la línea del `never`, no hay comprobación ninguna. En Java, omitir el `default` es lo que
  la activa: la exhaustividad es el comportamiento por defecto, no un truco que hay que recordar.

> 📝 **Contexto.** Que `sealed` más pattern matching deje obsoleto a Visitor es, probablemente, el
> mejor ejemplo concreto para responder *"¿qué opinas de los patrones de diseño?"*: un patrón del
> catálogo de 1994 que existía para suplir una carencia del lenguaje, y que desaparece en cuanto el
> lenguaje la cubre. Con el mensaje de error del compilador delante, deja de ser una opinión.

---

## 9. ⚖️ La tabla de supervivencia

| Patrón | Java | Python | JavaScript | TypeScript | Go | Veredicto |
|---|---|---|---|---|---|---|
| **Strategy** | lambda + `Map` | dict de funciones | objeto de funciones | + exhaustividad de tipos | `type func` | Sobrevive, sin jerarquía |
| **Decorator** | función que envuelve | **`@` es sintaxis** | orden superior | igual que JS | orden superior | Absorbido por el lenguaje |
| **Observer** | eventos de Spring | lista de callables | **`EventTarget`** | + tipar el payload | **canales** | Go lo sustituye por algo mejor |
| **Singleton** | scope o `enum` | **el módulo** | **el módulo** | el módulo | var + `sync.Once` | **Desaparece** |
| **Builder** | `record` | `dataclass` | objeto literal | + campos obligatorios | struct + `(T, error)` | Solo sobrevive con validación |
| **Factory Method** | el contenedor | función | función | función | func → interfaz | Se reduce a una función |
| **Template Method** | `...Template` | función de orden superior | orden superior | igual que JS | orden superior | Se reduce a pasar una función |
| **Command** | `Runnable` | callable | `{tipo, payload}` | unión discriminada | `func()` por canal | **Sobrevive intacto** |
| **Visitor** | **`sealed` + `switch`** | `match` | `switch` | unión + `never` | *type switch* | **Desaparece** en Java 21 |
| **Adapter / Proxy** | interfaz + envoltura | igual | igual | igual | igual | **Sobreviven intactos** |

**Las tres conclusiones que valen en una entrevista:**

1. **Los patrones que sobreviven al cambio de lenguaje son los estructurales** —Adapter, Proxy,
   Command—, porque resuelven problemas de arquitectura y no carencias de sintaxis.
2. **Los que se evaporan son los que simulaban funciones de primera clase**: Strategy, Decorator,
   Template Method y Factory Method. Nombrar esa causa común es la respuesta cara.
3. **El Singleton no se evapora: se descubre que era un antipatrón.** Los cinco lenguajes dan una
   instancia única sin esfuerzo, y el problema que quedaba —el estado global y la dependencia
   estática— solo lo resuelve la inyección.

---

## 📚 Para profundizar

- **Libro** — Bloch, *Effective Java*, 3ª ed. (Addison-Wesley, 2018). Ítems 1–6 (fábricas estáticas,
  builder, singleton como `enum`) y 18 (composición sobre herencia). **Más útil que el GoF original
  para una entrevista de Java.**
- **Libro** — Gamma, Helm, Johnson y Vlissides, *Design Patterns* (Addison-Wesley, 1994). El
  original; se consulta, no se lee entero. Su prólogo ya avisa de que varios patrones son rodeos
  alrededor del lenguaje.
- **Libro** — Freeman y Robson, *Head First Design Patterns*, 2ª ed. (O'Reilly, 2021). Para fijar
  Strategy, Decorator y Observer si están flojos.
- [Refactoring Guru — Catálogo de patrones](https://refactoring.guru/design-patterns/catalog): la
  mejor referencia visual, con ejemplos en varios lenguajes y la sección de relaciones entre
  patrones.
- [The Go Blog — Go maps in action](https://go.dev/blog/maps) y
  [Go slices](https://go.dev/blog/slices-intro): el contexto de por qué Go prefiere construcciones
  del lenguaje a catálogos de patrones.
- [Python — `functools`](https://docs.python.org/3/library/functools.html): `wraps`, `partial` y
  `cache`, que son tres patrones del catálogo convertidos en funciones de biblioteca.
- **Teoría de los patrones en este repositorio** —
  [`repaso-arquitectura-entrevistas/01-bases/04`](../../../arquitectura/01-bases/01-bases/04-patrones-gof.md)
  y [`preguntas-entrevista/01`](../../../../preguntas-entrevista/01-poo-solid-patrones.md).

---

**Anterior:** [`01` — Estructuras a pie contra prehechas](01-estructuras-a-pie-vs-prehechas.md) ·
**Siguiente:** [`03` — Ejercicios comparativos](03-ejercicios-comparativos.md)
