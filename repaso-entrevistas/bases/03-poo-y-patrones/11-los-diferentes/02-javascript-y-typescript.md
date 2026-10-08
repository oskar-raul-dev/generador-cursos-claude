# 02 — JavaScript y TypeScript

> Explicar el modelo de **prototipos** que hay debajo de `class`, por qué `this` depende de **cómo se llama** una función,
> qué patrones trae el lenguaje de serie —*closures*, módulos, `Proxy`, `EventEmitter`, `Promise`, el *event loop*— y qué
> cambia TypeScript, que tipa **solo al compilar**. **Lenguajes:** JavaScript y TypeScript, con Java al lado solo donde el
> contraste es el punto. Escrito contra **Node.js 24 LTS** y **TypeScript 7.0**, las versiones estables publicadas en
> `nodejs.org` y en npm el día de la tanda; las de la corrida se fijan en la revisión técnica. Asume leído
> [`01/05` — Polimorfismo y despacho](../01-modelo-de-objetos/05-polimorfismo-y-despacho.md).
>
> **Vigencia:** 2026-10-03.
>
> **Versiones ejecutadas:** Node.js 24.21.0 · TypeScript 7.0.2 (2026-10-04).

---

## 1. 🎯 El problema

Un equipo que viene de Java escribe el servicio de avisos como una clase y pasa el método como función a quien recorre los
documentos vencidos:

```js
class ServicioAvisos {
  constructor(correo) { this.correo = correo; }
  avisar(documento) {
    this.correo.enviar(documento.email, `Tu ${documento.tipo} venció`);
  }
}

const servicio = new ServicioAvisos(correo);
vencidos.forEach(servicio.avisar);   // TypeError: Cannot read properties of undefined (reading 'correo')
```

- En Java, `servicio::avisar` lleva el objeto consigo. En JavaScript, `servicio.avisar` es **solo la función**: el objeto se
  queda atrás. Cuando `forEach` la llama, `this` no es `servicio` sino `undefined` (el cuerpo de una clase está en modo
  estricto), y el aviso revienta.
- `class` hace que el código **parezca** Java. El modelo que hay debajo es otro: objetos que delegan en otros objetos, y un
  `this` que se decide en cada llamada.

---

## 2. 🧱 El modelo de objetos

**Prototipos.** Cada objeto tiene un enlace a otro objeto, su **prototipo**; si una propiedad no está en el objeto, se busca
en el prototipo, y en el prototipo de este, hasta `null`. Eso es la herencia en JavaScript: **delegación a un objeto vivo**,
no copia de una clase.

```js
const cuentaBase = { describir() { return `${this.id} (${this.estado})`; } };
const cta = Object.create(cuentaBase);   // cta delega en cuentaBase
cta.id = 'CTA-0001';
cta.estado = 'ABIERTA';
cta.describir();                          // 'CTA-0001 (ABIERTA)': el método se encontró en el prototipo
```

- Por eso el Prototype del GoF ([`04/04`](../04-creacionales/04-prototype.md)) **no** es esto: el patrón **copia** un ejemplar;
  `Object.create` crea un objeto que **delega** en otro, y que ve sus cambios.

**`class` es una sintaxis sobre prototipos.** MDN lo dice así: las clases de JavaScript se construyen sobre prototipos, con
algo de sintaxis y semántica propias. `class Cuenta { describir() {…} }` pone `describir` en `Cuenta.prototype`, y cada
instancia delega en él. Lo que `class` añade de verdad: campos privados con `#` (privados de verdad, no por convención),
`super`, `static`, y que el cuerpo corre en modo estricto.

**`this` se decide al llamar, no al definir.**

```text
servicio.avisar(d)            → this = servicio        (llamada como método)
const f = servicio.avisar; f(d) → this = undefined     (llamada suelta, modo estricto)
new Cuenta()                  → this = el objeto nuevo
servicio.avisar.bind(servicio)→ this fijado para siempre
(d) => servicio.avisar(d)     → la flecha no tiene this propio: usa el del sitio donde se escribió
```

- La salida del §1 es cualquiera de las dos últimas: `vencidos.forEach(d => servicio.avisar(d))`, o un `bind` en el
  constructor.

---

## 3. 🧱 Lo que el lenguaje ya trae

| Patrón | En Java | En JavaScript |
|---|---|---|
| Strategy, Command | Una interfaz y una clase por variante | Una función; una *closure* si necesita estado |
| Singleton | Holder, enum | El módulo: se evalúa una vez y quien lo importa recibe la misma instancia |
| Proxy | `java.lang.reflect.Proxy` con interfaces | `new Proxy(objetivo, manejador)` sobre cualquier objeto, con `Reflect` para el comportamiento normal |
| Observer | Oyentes a mano, o eventos de Spring | `EventEmitter` en Node, `EventTarget` en el navegador |
| Future/Promise | `CompletableFuture` | `Promise` y `async`/`await` |
| Reactor | Netty, el `Selector` de NIO | El *event loop*: es el modelo de ejecución del lenguaje |
| Iterator | `Iterable` e `Iterator` | El protocolo de iteración y las funciones generadoras (`function*`) |

- **El *event loop* es el Reactor de [`10/05`](../10-concurrencia/05-reactor-y-proactor.md)** puesto como modelo del
  lenguaje. MDN describe la regla que lo define, *run-to-completion*: cada tarea se ejecuta entera antes de que empiece otra,
  y una función no puede ser interrumpida. Por eso nada que bloquee puede ir en el código de usuario.
- **`Promise` y `async`/`await`** son el Future/Promise de [`10/04`](../10-concurrencia/04-future-y-active-object.md) en el
  lenguaje: `await` suspende la función y devuelve el control al bucle, sin bloquear el hilo. `Promise.all` es el `allOf`.
- **`EventEmitter`** llama a los oyentes, dice la documentación de Node, **de forma síncrona y en el orden en que se
  registraron**: es el Observer síncrono de [`06/03`](../06-comportamiento/03-observer.md), con su mismo riesgo de oyente
  olvidado.

---

## 4. 🔀 Los patrones que cambian de forma

**Strategy y Command → funciones y *closures*.** Una política de comisión es una función; si necesita configuración, una
*closure* la guarda:

```js
const porcentaje = (p) => (monto) => monto * p;            // una fábrica de estrategias
const comisiones = { AHORROS: porcentaje(0.005), CORRIENTE: porcentaje(0.008), NOMINA: () => 0 };

const comision = comisiones[cuenta.tipo](250_000);          // 1 250 para una cuenta de ahorros
```

- Es el `EnumMap` de estrategias de [`06/01`](../06-comportamiento/01-strategy.md) sin una sola clase. El `number` es solo
  del ejemplo: el dinero de verdad va en centavos enteros o con una librería decimal, por lo mismo que en
  [`02/06`](../02-modelado-oo/06-entidades-valores-y-primitivos.md).

**Decorator → funciones de orden superior.** `const auditada = (fn) => async (...args) => { registrar(args); return fn(...args); };`
envuelve cualquier operación; es el Decorator de [`05/02`](../05-estructurales/02-decorator.md) con funciones.

**Herencia horizontal → *mixins*.** Como no hay herencia múltiple, el comportamiento compartido se mezcla: copiando métodos
con `Object.assign(Cuenta.prototype, Auditable)`, o con una función que recibe una clase y devuelve una subclase. La copia
no sigue al original: si `Auditable` cambia después, `Cuenta` no se entera.

**Proxy en el lenguaje.** El Proxy de [`05/03`](../05-estructurales/03-proxy.md) sin generar clases:

```js
const soloLectura = (objetivo) => new Proxy(objetivo, {
  set() { throw new TypeError('objeto de solo lectura'); },
  get(o, prop, receptor) { return Reflect.get(o, prop, receptor); },   // el comportamiento normal
});
const ana = soloLectura({ nombre: 'Ana Rojas Medina' });
```

---

## 5. 🪦 Los patrones que desaparecen, y por qué

- **Singleton como clase.** El módulo ya lo es: se evalúa la primera vez que se importa y queda en caché.
- **Factory Method y Abstract Factory con jerarquías.** Una función que devuelve un objeto; sin tipos nominales, no hay
  jerarquía de productos que respetar.
- **Iterator como objeto aparte.** Una función generadora produce los valores con `yield`.
- **Visitor, en TypeScript.** Las **uniones discriminadas** con un campo literal (`tipo`) y el estrechamiento del compilador
  hacen lo que en Java hace el `switch` sobre una interfaz sellada ([`06/07`](../06-comportamiento/07-visitor.md)), con
  exhaustividad comprobada por `never`:

```ts
type Movimiento =
  | { tipo: 'deposito'; monto: number }
  | { tipo: 'retiro'; monto: number }
  | { tipo: 'comision'; monto: number; concepto: string };

function signo(m: Movimiento): number {
  switch (m.tipo) {
    case 'deposito': return m.monto;
    case 'retiro': return -m.monto;
    case 'comision': return -m.monto;
    default: {
      const imposible: never = m;    // si se añade una variante sin su caso, esto no compila
      return imposible;
    }
  }
}
```

- El *handbook* de TypeScript llama a esto *exhaustiveness checking*: en el `default`, `m` solo puede ser `never` si todos los
  casos están cubiertos.

**El objeto de valor, en TypeScript.** El tipado es **estructural**: el *handbook* dice que la compatibilidad se basa en los
miembros, no en el nombre. Dos alias de `string` son el mismo tipo, y un `PersonaId` se cuela donde se espera un `CuentaId`.
La salida es una **marca** (*brand*), que solo existe para el compilador:

```ts
type CuentaId = string & { readonly __marca: 'CuentaId' };

function cuentaId(valor: string): CuentaId {
  if (!/^CTA-\d{4}$/.test(valor)) throw new Error(`id de cuenta inválido: ${valor}`);
  return valor as CuentaId;        // la única puerta: valida y marca
}
```

---

## 6. 🩺 Las trampas

**El `this` perdido.** Es el §1. **Por qué parece correcto**: en Java, una referencia a método lleva su objeto. **Lo que lo
rompe**: pasar el método como función (`forEach`, `setTimeout`, un oyente). **La corrección**: una flecha o `bind`. **La
generalización**: en JavaScript una función no pertenece a un objeto; `this` lo pone quien la llama.

**TypeScript no comprueba nada al ejecutar.** El *handbook* lo dice sin ambigüedad: las anotaciones de tipo nunca cambian el
comportamiento del programa en ejecución; se borran al compilar.

```ts
const persona = (await respuesta.json()) as Persona;   // el compilador te cree; nadie lo comprueba
persona.documentos.length;                              // TypeError si el API mandó otra cosa
```

- Lo que entra de fuera —el cuerpo de una petición, un JSON leído, una variable de entorno— se **valida al ejecutar**, con
  código o con una librería de esquemas, y solo después tiene su tipo. `as` es una promesa del programador, no una
  comprobación.

**El bucle bloqueado.** Un cálculo de dos segundos en un manejador de un servidor de Node congela a todos los clientes, por
el *run-to-completion* del §3. Es la autopsia de [`10/05` §4](../10-concurrencia/05-reactor-y-proactor.md#4--por-qué-bloquear-el-bucle-lo-detiene-todo).

**El prototipo compartido.** Un arreglo definido en el prototipo lo comparten todas las instancias: modificarlo desde una lo
cambia en todas. Los datos van en el constructor (o como campos de clase); en el prototipo, solo métodos.

---

## 7. 🧭 Cómo se traduce

| Patrón o idioma de Java | Forma idiomática en JavaScript / TypeScript |
|---|---|
| Herencia de clases | `class` y `extends` sobre prototipos, con moderación; *mixins* para lo horizontal |
| Strategy, Command, Template Method | Funciones, *closures* y funciones pasadas como parámetro |
| Decorator | Funciones de orden superior; *middleware* |
| Proxy dinámico | `Proxy` y `Reflect` |
| Singleton | Un módulo |
| Observer | `EventEmitter` o `EventTarget` |
| `CompletableFuture` | `Promise`, `async`/`await`, `Promise.all` |
| Visitor, `switch` sellado | Unión discriminada con estrechamiento y `never` (TS) |
| Objeto de valor con identificador tipado | Tipo con marca y una función que valida (TS) |
| Validación por tipos | Validación al ejecutar en la frontera; los tipos de TS no existen en ejecución |

**La frase en voz alta:** *"`class` en JavaScript es sintaxis sobre prototipos, y `this` lo decide quien llama: por eso
pasar un método como función pierde el objeto. TypeScript me ayuda a escribir, pero no comprueba nada al ejecutar: lo que
viene de fuera lo valido en la frontera."*

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "`class` en JS es como en Java" | Es sintaxis sobre prototipos: delegación a objetos vivos, y `this` decidido en cada llamada |
| "TypeScript garantiza los tipos al ejecutar" | Las anotaciones se borran; nunca cambian el comportamiento en ejecución |
| "`servicio.avisar` es como `servicio::avisar`" | Es solo la función; el objeto se pierde si no se vincula |
| "Node es multihilo para el código del usuario" | El JavaScript del usuario corre en el hilo del *event loop*, de principio a fin de cada tarea |
| "`EventEmitter` es asíncrono" | Llama a los oyentes de forma síncrona, en el orden de registro |
| "`Object.create` es el Prototype del GoF" | Crea un objeto que delega en otro; el patrón copia |
| "Dos tipos con nombres distintos en TS son incompatibles" | El tipado es estructural; para distinguirlos hace falta una marca |

---

## 📚 Para profundizar

- **Libro** — Vanderkam, *Effective TypeScript*, 2.ª ed. (O'Reilly, 2024), ítem 3 (la generación de código es independiente
  de los tipos), ítem 4 (tipado estructural) e ítem 64 (marcas para tipos nominales). **El que destaca.**
- [MDN — *Inheritance and the prototype chain*](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Inheritance_and_the_prototype_chain)
- [MDN — `this`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/this)
- [MDN — *JavaScript execution model*](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Execution_model):
  el *event loop* y *run-to-completion*.
- [Node.js — *Events*](https://nodejs.org/api/events.html): `EventEmitter` y sus oyentes síncronos.
- [TypeScript — *Narrowing*, *Exhaustiveness checking*](https://www.typescriptlang.org/docs/handbook/2/narrowing.html#exhaustiveness-checking)
- [TypeScript — *Type Compatibility*](https://www.typescriptlang.org/docs/handbook/type-compatibility.html): el tipado
  estructural.
- **Tutorial en línea** — Hallie y Osmani, *Learning Patterns*, en [patterns.dev](https://www.patterns.dev/): los patrones
  en JavaScript moderno.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`05` — Respuestas](05-respuestas.md#02--javascript-y-typescript).

1. ¿Qué es la cadena de prototipos? 🟢
2. ¿Qué es una *closure*, y qué patrones reemplaza? 🟢
3. ¿Qué es una unión discriminada en TypeScript? 🟢
4. ¿Qué es el *event loop* de JavaScript? 🟢
5. ¿Qué diferencia hay entre `class` en JavaScript y en Java? 🟡
6. ¿Qué diferencia hay entre `Object.create` y el patrón Prototype? 🟡
7. ¿Qué diferencia hay entre una función flecha y una función normal respecto de `this`? 🟡
8. ¿Qué diferencia hay entre el tipado estructural de TypeScript y el nominal de Java? 🟡
9. ¿Por qué `vencidos.forEach(servicio.avisar)` falla? 🟠
10. ¿Por qué TypeScript no garantiza los tipos al ejecutar, y qué haces con lo que viene de fuera? 🟠
11. ¿Por qué un módulo es un Singleton, y qué cuesta? 🟠
12. ¿Por qué `EventEmitter` es un Observer síncrono, y qué implica? 🟠
13. ¿Por qué una unión discriminada con `never` reemplaza a un Visitor? 🟠
14. ¿Cuándo usarías una marca (*brand*) en TypeScript? 🟠
15. Escribe la tabla de comisiones por tipo de cuenta con funciones en lugar de clases. 🔴
16. Escribe la unión discriminada de movimientos con una función exhaustiva comprobada por el compilador. 🔴
17. Revisa este código y di qué falla: `const persona = (await respuesta.json()) as Persona;` seguido de
    `persona.documentos.length`. 🔴
18. Escribe con `Proxy` un objeto de solo lectura y di qué patrón del GoF es. 🔴

---

**Anterior:** [`01` — Go](01-go.md) ·
**Siguiente:** [`03` — Python](03-python.md) ·
**Relacionado:** [`10/05` — Reactor y Proactor](../10-concurrencia/05-reactor-y-proactor.md)
