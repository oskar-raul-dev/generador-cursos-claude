# 05 — Respuestas

> Solucionario del bloque `11-los-diferentes`: Los diferentes. Cada respuesta en tres capas:
> **⏱️ 30 segundos** (lo que dices primero, sin que te lo pidan), **🗣️ 2 minutos** (lo que
> añades cuando dicen "cuéntame más") y **🔬 El detalle** (para estudiar, no para decir en voz
> alta). Los enunciados están copiados literalmente de su capítulo.
>
> **Vigencia:** 2026-10-03.
>
> **Versiones ejecutadas:** Go 1.27.1 · Node.js 24.21.0 · TypeScript 7.0.2 · Python 3.14.8 (SQLAlchemy 2.1.3, Django 6.1.1) (2026-10-04).

**Salto rápido:** [01](#01--go) · [02](#02--javascript-y-typescript) · [03](#03--python) · [04](#04--simulación-de-entrevista)

---

# 01 — Go

**01 → 1. ¿Es Go orientado a objetos? 🟢**

⏱️ Sí y no, como dice su FAQ: tiene tipos con métodos y permite un estilo orientado a objetos, pero no hay jerarquía de tipos
ni herencia; el polimorfismo es solo a través de interfaces.
🗣️ Lo que hay: *structs* con métodos, interfaces que se cumplen sin declararlo, y composición con *embedding*. No hay
clases, constructores, sobrecarga ni excepciones para el flujo normal.
🔬 La encapsulación es por paquete (mayúscula exportada, minúscula privada), no por tipo.

**01 → 2. ¿Qué es una interfaz implícita en Go? 🟢**

⏱️ Una interfaz que un tipo cumple con solo tener sus métodos, sin declarar que la implementa.
🗣️ Si `ValidadorPasaporte` tiene `Validar(Documento) error`, es un `Validador`, aunque el autor no conozca la interfaz. Por
eso la interfaz la escribe quien la usa, con los métodos que necesita.
🔬 Es tipado estructural para interfaces; en Java, el tipado es nominal: hay que escribir `implements`.

**01 → 3. ¿Qué son las *functional options*? 🟢**

⏱️ Funciones que se pasan a un constructor y configuran cada una un campo opcional: `NuevaCuenta(id, titular,
ConLimiteDiario(...))`.
🗣️ Ocupan el lugar del Builder en un lenguaje sin sobrecarga ni parámetros con nombre: lo obligatorio va como parámetro, lo
opcional como opción con nombre, y añadir una opción no rompe a nadie.
🔬 El tipo es `type OpcionCuenta func(*Cuenta)`, y el constructor las aplica en orden sobre los valores por defecto.

**01 → 4. ¿Qué hace `sync.OnceValue`? 🟢**

⏱️ Devuelve una función que ejecuta la inicialización una sola vez, segura entre *goroutines*, y después devuelve siempre el
mismo valor.
🗣️ `var catalogoTipos = sync.OnceValue(cargarCatalogo)`: la primera llamada carga, las demás reciben lo mismo. Es la
inicialización perezosa de `10/06` sin DCL que escribir mal.
🔬 Existe desde Go 1.21; antes se usaba `sync.Once` con una variable aparte. `OnceValues` hace lo mismo con un valor y un
error.

**01 → 5. ¿Qué diferencia hay entre el *embedding* de Go y la herencia de Java? 🟡**

⏱️ El *embedding* reenvía: los métodos del tipo embebido se pueden llamar sobre el exterior, pero se ejecutan con el embebido
como receptor. No hay despacho hacia el tipo exterior, que es lo que la herencia de Java sí hace.
🗣️ *Effective Go* lo dice: al invocar un método promovido, el receptor es el tipo interior, no el exterior. Por eso un
método de la base que llama a otro "suyo" llama siempre al de la base.
🔬 El tipo exterior tampoco "es un" embebido para el sistema de tipos: no se puede pasar donde se espera el embebido; sí donde
se espera una interfaz que los métodos promovidos cumplan.

**01 → 6. ¿Qué diferencia hay entre un receptor por valor y uno por puntero? 🟡**

⏱️ Con receptor por valor, el método recibe una copia y lo que cambie no se ve fuera; con receptor por puntero, opera sobre
el original.
🗣️ `func (c Cuenta) Depositar(m Dinero)` no mueve el saldo del llamador; `func (c *Cuenta) Depositar` sí. Lo que modifica, o
lo que es grande para copiar, va con puntero.
🔬 La convención es no mezclar: si un método de un tipo necesita puntero, todos los del tipo lo usan. Y el conjunto de métodos
de `T` no incluye los de `*T`, lo que decide qué interfaces cumple cada uno.

**01 → 7. ¿Qué diferencia hay entre un Builder de Java y las *functional options* de Go? 🟡**

⏱️ El Builder es un objeto aparte que acumula valores y construye en `build()`, donde valida; las *functional options* son
funciones que el propio constructor aplica, sin objeto intermedio.
🗣️ Las opciones son más ligeras y extensibles; lo que se pierde es validar combinaciones antes de construir, que con opciones
se hace al final del constructor.
🔬 Si la construcción tiene pasos con orden o muchas reglas entre campos, un Builder sigue siendo legítimo en Go.

**01 → 8. ¿Qué diferencia hay entre un *channel* con capacidad y una `BlockingQueue`? 🟡**

⏱️ Hacen lo mismo —una cola acotada que bloquea al productor si está llena y al consumidor si está vacía—, pero el *channel* es
del lenguaje: tiene sintaxis (`<-`), se cierra, y se espera en varios a la vez con `select`.
🗣️ `select` permite esperar un mensaje **o** la cancelación de un `context`, que con `BlockingQueue` requiere `poll` con plazo
y bucles.
🔬 Cerrar un *channel* avisa a todos los consumidores de que no habrá más; enviar a uno cerrado provoca un *panic*.

**01 → 9. ¿Qué diferencia hay entre el *type switch* de Go y el `switch` sellado de Java 21? 🟡**

⏱️ Los dos eligen por el tipo dinámico, pero Go no comprueba la exhaustividad: una variante nueva sin su caso cae en el
`default` o no hace nada, sin aviso del compilador.
🗣️ En Java 21, un `switch` sobre una interfaz sellada sin un caso no compila. En Go no hay tipos sellados; el *type switch*
reemplaza al Visitor con menos garantías.
🔬 Hay herramientas de análisis que comprueban la exhaustividad en Go, fuera del compilador.

**01 → 10. ¿Por qué un Template Method escrito con *embedding* no funciona en Go? 🟠**

⏱️ Porque el método con el algoritmo está declarado en la base, y su receptor es la base: cuando llama al paso, llama al de la
base, nunca al que el tipo exterior "redefinió".
🗣️ El pasaporte `"123"` pasa la validación porque nadie llama al `formato` de `ValidadorPasaporte`. En Go, el despacho dinámico
solo existe a través de interfaces.
🔬 La salida es inyectar el paso como interfaz o como función: el Template Method se vuelve Strategy.

**01 → 11. ¿Por qué en Go la interfaz se define en el paquete que la usa? 🟠**

⏱️ Porque se cumple sin declararla: quien la usa sabe qué métodos necesita y la define pequeña; quien implementa devuelve tipos
concretos y puede añadirles métodos sin romper a nadie.
🗣️ La guía de revisión de código de Go lo pide así. Es la segregación de interfaces de `03/02` llevada a la convención del
lenguaje: interfaces de uno o dos métodos, como `io.Reader`.
🔬 En Java la interfaz suele vivir con la implementación porque hay que declararla con `implements`; en Go esa dependencia no
existe.

**01 → 12. ¿Por qué el Adapter casi desaparece en Go? 🟠**

⏱️ Porque si el tipo ajeno ya tiene los métodos que la interfaz pide, la cumple sin declararlo: no hace falta envolverlo.
🗣️ Cuando los nombres o las firmas no coinciden, sigue haciendo falta un adaptador, que suele ser un tipo función
(`http.HandlerFunc` convierte una función en un `Handler`) o un *struct* pequeño.
🔬 Es la consecuencia directa del tipado estructural de las interfaces.

**01 → 13. ¿Por qué una función que devuelve un puntero nulo como `error` hace que `err != nil` sea verdadero? 🟠**

⏱️ Porque una interfaz guarda un tipo y un valor, y solo es `nil` si los dos lo son. Un `*ErrorFormato` nulo convertido a `error`
tiene tipo, así que la interfaz no es `nil`.
🗣️ La FAQ de Go lo explica en *"Why is my nil error value not equal to nil?"*. La corrección es devolver `nil` literal cuando no
hay error.
🔬 Pasa con cualquier interfaz, no solo con `error`, y es uno de los errores más citados de quien viene de Java.

**01 → 14. ¿Cómo se evita que una *goroutine* quede viva para siempre? 🟠**

⏱️ Dándole siempre una forma de terminar: que el *channel* del que lee se cierre, o un `context` que se cancele, escuchado con
`select`.
🗣️ Una *goroutine* bloqueada en un *channel* que nadie cierra no termina nunca y retiene su memoria: es la fuga de Go. El
`context` propaga cancelación y plazos por toda la cadena de llamadas.
🔬 La regla práctica: quien lanza una *goroutine* sabe cómo y cuándo termina.

**01 → 15. Escribe `NuevaCuenta` con *functional options* para el tipo y el límite diario. 🔴**

⏱️ Un tipo opción que es una función sobre `*Cuenta`, dos funciones que devuelven opciones, y un constructor que las aplica sobre
los valores por defecto.
🗣️

```go
type OpcionCuenta func(*Cuenta)

func ConLimiteDiario(d Dinero) OpcionCuenta { return func(c *Cuenta) { c.limiteDiario = d } }
func ConTipo(t TipoCuenta) OpcionCuenta     { return func(c *Cuenta) { c.tipo = t } }

func NuevaCuenta(id CuentaId, titular PersonaId, opciones ...OpcionCuenta) *Cuenta {
	c := &Cuenta{id: id, titular: titular, tipo: Ahorros}
	for _, op := range opciones {
		op(c)
	}
	return c
}
```

🔬 Lo que preguntará después: dónde se valida (al final de `NuevaCuenta`, devolviendo `(*Cuenta, error)` si alguna combinación es
inválida), y por qué no un *struct* de configuración (también es idiomático; las opciones ganan cuando hay valores por defecto
y crecen con el tiempo).

**01 → 16. Revisa este código y di qué falla: `ValidadorPasaporte` embebe `ValidadorBase` y redefine `formato`, y `Validar` está en la base. 🔴**

⏱️ El `formato` de `ValidadorPasaporte` nunca se llama: `Validar` tiene como receptor a `ValidadorBase` y llama a su propio
`formato`, que no comprueba nada. Los pasaportes inválidos pasan.
🗣️ Es la trampa del *embedding*: los métodos se promueven pero el receptor es el tipo embebido, y no hay despacho hacia el
exterior. Compila y no avisa.
🔬 Lo que preguntará después: cómo lo detectarías (un test con un pasaporte inválido; y desconfiar de cualquier "redefinición"
de un método que la base llama), y cómo lo corriges (el paso como interfaz).

**01 → 17. Reescribe esa validación en Go de forma que la regla de formato se aplique. 🔴**

⏱️ El algoritmo recibe la regla de formato como interfaz, y la llama por despacho de interfaz.
🗣️

```go
type ReglaFormato interface{ Formato(d Documento) error }

type ValidadorDocumento struct{ regla ReglaFormato }

func (v ValidadorDocumento) Validar(d Documento) error {
	if err := v.regla.Formato(d); err != nil {
		return err
	}
	return vigente(d)
}

type FormatoPasaporte struct{}

func (FormatoPasaporte) Formato(d Documento) error { return comprobar(`^[A-Z]{2}\d{6}$`, d.Numero) }

validador := ValidadorDocumento{regla: FormatoPasaporte{}}
```

🔬 Lo que preguntará después: si la regla podría ser una función (`type ReglaFormato func(Documento) error`, más ligera), y si
el formato debería venir de `TipoDocumento` como dato (sí, como el Type Object de `09/03`: una expresión regular por tipo).

**01 → 18. Escribe un *worker pool* con *channels* que procese solicitudes de transferencia y se pueda cancelar. 🔴**

⏱️ N *goroutines* que leen de un *channel* de solicitudes, terminan cuando se cierra o cuando el `context` se cancela, y un
`WaitGroup` para esperarlas.
🗣️

```go
func procesar(ctx context.Context, solicitudes <-chan Solicitud, trabajadores int) {
	var wg sync.WaitGroup
	for range trabajadores {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for {
				select {
				case s, abierto := <-solicitudes:
					if !abierto {
						return
					}
					ejecutar(ctx, s)
				case <-ctx.Done():
					return
				}
			}
		}()
	}
	wg.Wait()
}
```

🔬 Lo que preguntará después: cómo se pone contrapresión (el *channel* con capacidad: `make(chan Solicitud, 500)`, y el
productor bloquea o usa `select` con `default` para rechazar), cuántos trabajadores (los que el recurso escaso permita) y qué
hace `ejecutar` con el `ctx` (pasarlo a la base y al cliente HTTP, que respetan el plazo).

# 02 — JavaScript y TypeScript

**02 → 1. ¿Qué es la cadena de prototipos? 🟢**

⏱️ El mecanismo de herencia de JavaScript: cada objeto enlaza con otro, su prototipo, y si una propiedad no está en el objeto
se busca en el prototipo, y así hasta `null`.
🗣️ Es delegación a un objeto vivo: si el prototipo cambia, todos los que delegan en él ven el cambio. `class` y `extends` se
construyen sobre esta cadena.
🔬 Se puede crear un objeto con un prototipo concreto con `Object.create(p)`, y consultarlo con `Object.getPrototypeOf`.

**02 → 2. ¿Qué es una *closure*, y qué patrones reemplaza? 🟢**

⏱️ Una función que recuerda las variables del ámbito donde se creó, aunque se ejecute en otro sitio. Reemplaza a las clases de
Strategy y Command, y a muchas fábricas pequeñas.
🗣️ `const porcentaje = (p) => (monto) => monto * p;` devuelve una estrategia de comisión configurada: la *closure* guarda `p`.
Un Command con sus parámetros es una *closure* sin argumentos lista para ejecutar.
🔬 En Java, una lambda captura variables efectivamente finales; en JavaScript, la *closure* captura la variable misma, y ve sus
cambios posteriores.

**02 → 3. ¿Qué es una unión discriminada en TypeScript? 🟢**

⏱️ Un tipo que es una de varias formas de objeto, cada una con un campo literal común —`tipo: 'deposito'`— que el compilador usa
para saber cuál es en cada rama.
🗣️ En un `switch (m.tipo)`, dentro de `case 'comision'` el compilador sabe que `m` tiene `concepto`. Con un `never` en el
`default`, comprueba además que no falta ningún caso.
🔬 Es la versión de TypeScript de la jerarquía sellada de Java 21, y como ella reemplaza al Visitor.

**02 → 4. ¿Qué es el *event loop* de JavaScript? 🟢**

⏱️ El modelo de ejecución del lenguaje: un hilo que toma una tarea de la cola, la ejecuta entera y toma la siguiente. MDN llama
*run-to-completion* a esa regla.
🗣️ Las operaciones de E/S no bloquean: se inician, y su continuación (el *callback*, el `then`, lo que sigue a un `await`) entra a
la cola cuando terminan. Es el Reactor de `10/05` como modelo del lenguaje.
🔬 Las promesas resueltas van a una cola de microtareas que se vacía antes de pasar a la siguiente tarea.

**02 → 5. ¿Qué diferencia hay entre `class` en JavaScript y en Java? 🟡**

⏱️ En Java la clase es un tipo nominal y la herencia la resuelve el compilador; en JavaScript `class` es sintaxis sobre
prototipos: los métodos van al objeto prototipo y las instancias delegan en él en ejecución.
🗣️ Por eso en JavaScript se puede cambiar el prototipo de un objeto en ejecución, `this` depende de cómo se llama el método, y no
hay sobrecarga. MDN lo dice: las clases se construyen sobre prototipos, con alguna sintaxis propia.
🔬 Lo que `class` añade de verdad: campos privados con `#`, `super`, `static` y el modo estricto en su cuerpo.

**02 → 6. ¿Qué diferencia hay entre `Object.create` y el patrón Prototype? 🟡**

⏱️ `Object.create(p)` crea un objeto que **delega** en `p` y ve sus cambios; el Prototype del GoF **copia** un ejemplar, y la copia
no sigue al original.
🗣️ Si `p` cambia un método o un dato compartido, el objeto creado lo ve. Para copiar de verdad hace falta `structuredClone` o una
copia explícita.
🔬 Ver `04/04`: la confusión viene del nombre, porque JavaScript es "el lenguaje de prototipos".

**02 → 7. ¿Qué diferencia hay entre una función flecha y una función normal respecto de `this`? 🟡**

⏱️ La flecha no tiene `this` propio: usa el del sitio donde se escribió. La función normal recibe el `this` de quien la llama.
🗣️ `vencidos.forEach(d => servicio.avisar(d))` funciona porque la flecha llama a `avisar` como método de `servicio`. Pasar
`servicio.avisar` suelto pierde el objeto.
🔬 Por eso las flechas son lo normal para *callbacks*, y no sirven como métodos que dependen de `this` del objeto que las recibe.

**02 → 8. ¿Qué diferencia hay entre el tipado estructural de TypeScript y el nominal de Java? 🟡**

⏱️ En TypeScript dos tipos son compatibles si tienen los mismos miembros, sin importar su nombre; en Java, solo si uno declara
ser el otro (`implements`, `extends`).
🗣️ El *handbook* lo dice: la compatibilidad se basa en los miembros. La consecuencia: `type CuentaId = string` y
`type PersonaId = string` son el mismo tipo, y uno se cuela donde va el otro.
🔬 Para recuperar la distinción nominal se usa una marca (*brand*), que es el ítem 64 de *Effective TypeScript*.

**02 → 9. ¿Por qué `vencidos.forEach(servicio.avisar)` falla? 🟠**

⏱️ Porque `servicio.avisar` es solo la función, sin el objeto: `forEach` la llama suelta, `this` es `undefined` (modo estricto
en el cuerpo de la clase), y `this.correo` lanza.
🗣️ La corrección: `vencidos.forEach(d => servicio.avisar(d))`, o vincular en el constructor con
`this.avisar = this.avisar.bind(this)`.
🔬 En Java, `servicio::avisar` captura el objeto. En JavaScript, una función no pertenece a ningún objeto: `this` lo pone quien
llama.

**02 → 10. ¿Por qué TypeScript no garantiza los tipos al ejecutar, y qué haces con lo que viene de fuera? 🟠**

⏱️ Porque los tipos se borran al compilar: el *handbook* dice que las anotaciones nunca cambian el comportamiento en ejecución.
Lo que viene de fuera se valida al ejecutar, en la frontera.
🗣️ `(await respuesta.json()) as Persona` no comprueba nada; si el API manda otra forma, el error aparece lejos, en un acceso a
una propiedad. Se valida con código o con una librería de esquemas, y el tipo se obtiene de la validación.
🔬 Es el ítem 3 de *Effective TypeScript*: el código que se genera no depende de los tipos.

**02 → 11. ¿Por qué un módulo es un Singleton, y qué cuesta? 🟠**

⏱️ Porque se evalúa una sola vez, la primera vez que se importa, y queda en caché: todos los que lo importan reciben el mismo
objeto.
🗣️ Cuesta lo mismo que el Singleton de `04/05`: estado global, dependencias ocultas y pruebas que se contaminan entre sí. Para
probar hay que reemplazar el módulo o reiniciar la caché.
🔬 La salida también es la misma: exportar una función que crea el objeto y pasarlo como dependencia.

**02 → 12. ¿Por qué `EventEmitter` es un Observer síncrono, y qué implica? 🟠**

⏱️ Porque, según la documentación de Node, llama a todos los oyentes de forma síncrona, en el orden en que se registraron. El
`emit` no vuelve hasta que todos terminan.
🗣️ Un oyente lento frena al que emite, y una excepción en un oyente sube hasta quien emitió. Si un oyente debe ser asíncrono, lo
hace él (`setImmediate`, una promesa).
🔬 El riesgo del Observer de `06/03` sigue: un oyente que nunca se quita retiene memoria, y Node avisa cuando hay demasiados en
un evento.

**02 → 13. ¿Por qué una unión discriminada con `never` reemplaza a un Visitor? 🟠**

⏱️ Porque da lo que el Visitor fingía: una operación por variante, comprobada por el compilador. Si se añade una variante sin su
caso, la asignación a `never` del `default` no compila.
🗣️ El Visitor existía porque Java y C++ solo despachaban por el receptor; con el estrechamiento por un campo literal, el
`switch` es directo y exhaustivo.
🔬 Lo que se pierde frente al Visitor: añadir una operación es fácil, pero cada `switch` vive aparte, igual que con el `switch`
sellado de Java 21.

**02 → 14. ¿Cuándo usarías una marca (*brand*) en TypeScript? 🟠**

⏱️ Cuando dos valores con la misma representación no deben mezclarse: identificadores de cuenta y de persona, montos en monedas
distintas, una cadena ya validada.
🗣️ `type CuentaId = string & { readonly __marca: 'CuentaId' }` y una sola función que valida y marca. Es el identificador
tipado de `02/06` en un lenguaje estructural.
🔬 La marca no existe en ejecución: no ocupa memoria ni impide nada fuera del compilador. Por eso la función que la pone tiene
que validar.

**02 → 15. Escribe la tabla de comisiones por tipo de cuenta con funciones en lugar de clases. 🔴**

⏱️ Una función que fabrica estrategias de porcentaje, y un objeto que asocia cada tipo con su función.
🗣️

```js
const porcentaje = (p) => (monto) => monto * p;
const comisiones = {
  AHORROS: porcentaje(0.005),
  CORRIENTE: porcentaje(0.008),
  NOMINA: () => 0,
};
const comision = comisiones[cuenta.tipo](250_000);
```

🔬 Lo que preguntará después: qué pasa con un tipo que no está en la tabla (`comisiones[tipo]` es `undefined` y llamarlo lanza;
en TypeScript, `Record<TipoCuenta, (monto: number) => number>` obliga a cubrir todos), y por qué no `number` para dinero en
producción (centavos enteros o una librería decimal).

**02 → 16. Escribe la unión discriminada de movimientos con una función exhaustiva comprobada por el compilador. 🔴**

⏱️ Una unión con el campo literal `tipo`, un `switch` sobre él, y en el `default` una asignación a `never`.
🗣️

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
    default: { const imposible: never = m; return imposible; }
  }
}
```

🔬 Lo que preguntará después: qué pasa si se añade `transferencia` sin su caso (no compila: `m` no es `never` en el `default`),
y si eso protege en ejecución (no: si llega un objeto con otro `tipo` desde fuera, el `default` se ejecuta; la frontera valida).

**02 → 17. Revisa este código y di qué falla: `const persona = (await respuesta.json()) as Persona;` seguido de `persona.documentos.length`. 🔴**

⏱️ `as` no comprueba nada: le promete al compilador que el JSON es una `Persona`. Si el API manda otra forma, `documentos` es
`undefined` y `.length` lanza, lejos de donde entró el dato malo.
🗣️ La corrección es validar al ejecutar lo que entra —con código o con una librería de esquemas— y obtener el tipo de la
validación, rechazando la respuesta si no cumple.
🔬 Lo que preguntará después: dónde se valida (en la frontera, una vez, no en cada uso), y qué otras entradas necesitan lo mismo
(cuerpos de petición, mensajes de una cola, variables de entorno, `localStorage`).

**02 → 18. Escribe con `Proxy` un objeto de solo lectura y di qué patrón del GoF es. 🔴**

⏱️ Un `Proxy` con una trampa `set` que lanza y una `get` que delega con `Reflect`. Es un Proxy de protección.
🗣️

```js
const soloLectura = (objetivo) => new Proxy(objetivo, {
  set() { throw new TypeError('objeto de solo lectura'); },
  get(o, prop, receptor) { return Reflect.get(o, prop, receptor); },
});
```

🔬 Lo que preguntará después: si es inmutable (no del todo: los objetos anidados siguen siendo modificables, salvo que se
envuelvan también, y `defineProperty` y `deleteProperty` tienen sus propias trampas), y qué da `Object.freeze` en su lugar
(congela el objeto de verdad, superficialmente, sin interceptar nada).

# 03 — Python

**03 → 1. ¿Qué es el *duck typing*? 🟢**

⏱️ No mirar el tipo de un objeto para decidir si sirve, sino usarlo: si tiene el método que hace falta, sirve. El glosario de
Python lo define así.
🗣️ Una función que llama a `repo.guardar(cuenta)` acepta cualquier objeto con `guardar`, sin que herede ni declare nada. Se
falla al ejecutar si el método no está.
🔬 Los `Protocol` llevan esta idea al verificador de tipos, para detectarlo antes de ejecutar.

**03 → 2. ¿Qué es un `Protocol`? 🟢**

⏱️ Una clase de `typing` que describe métodos; el verificador de tipos acepta cualquier clase que los tenga, sin que lo
declare. Es tipado estructural, desde la PEP 544.
🗣️ `class RepositorioCuentas(Protocol)` con `guardar` y `por_id`: `RepositorioSqlCuentas` lo cumple solo por tener esos
métodos. Como las interfaces de Go, se define donde se usa.
🔬 En ejecución no se comprueba nada, salvo que se marque con `@runtime_checkable`, y aun así solo comprueba que los métodos
existan.

**03 → 3. ¿Qué es la MRO de Python? 🟢**

⏱️ El orden en que Python busca un método en una jerarquía con herencia múltiple, calculado con el algoritmo C3. Está en
`Clase.__mro__`.
🗣️ Garantiza que cada clase aparece antes que sus bases y que se respeta el orden en que se listaron las bases. `super()` sigue
esa lista, no "la clase de arriba".
🔬 Si las bases piden órdenes incompatibles, la clase no se puede crear: Python lanza `TypeError` al definirla.

**03 → 4. ¿Qué es un *context manager*? 🟢**

⏱️ Un objeto que se usa con `with`: `__enter__` se ejecuta al entrar y `__exit__` al salir, haya o no excepción. Es el recurso con
dueño de Python.
🗣️ `with sesion.begin():` confirma la transacción si el bloque termina bien y la deshace si sale con excepción. `contextlib`
permite escribir uno con una función generadora.
🔬 Es el equivalente de *try-with-resources* en Java y del RAII de C++, pero ligado a un bloque, no a la vida de un objeto.

**03 → 5. ¿Qué diferencia hay entre un `@decorator` de Python y el patrón Decorator? 🟡**

⏱️ El `@decorator` es una función que transforma otra función al definirla, una vez y para todos; el Decorator del GoF envuelve un
objeto al configurar, y se puede elegir por instancia.
🗣️ `@auditado` sobre `guardar` audita todas las instancias, también las de las pruebas. `RepositorioAuditado(repo)` audita solo
la que se envuelve. Un `@decorator` puede implementar un Decorator, pero también una caché o un registro.
🔬 El glosario lo dice: la sintaxis `@` es solo azúcar para `f = decorador(f)`.

**03 → 6. ¿Qué diferencia hay entre un `Protocol` y una clase abstracta de `abc`? 🟡**

⏱️ El `Protocol` es estructural: lo cumple quien tenga los métodos, y lo comprueba el verificador de tipos. La clase abstracta es
nominal: hay que heredarla (o registrarse), y Python impide instanciar una subclase que no implemente los métodos abstractos.
🗣️ `Protocol` para depender de una capacidad sin acoplar a quien la implementa; `abc` cuando se quiere obligar a heredar y
compartir código en la base.
🔬 Las ABC del módulo `collections.abc` (`Iterable`, `Mapping`) además reconocen algunas clases por sus métodos especiales.

**03 → 7. ¿Qué diferencia hay entre `@dataclass(frozen=True)` y un `record` de Java? 🟡**

⏱️ Se parecen: los dos dan igualdad por valor, `hash` y campos que no se reasignan. Los dos son superficiales: una lista dentro
sigue siendo modificable.
🗣️ El `record` es un tipo del lenguaje con constructor compacto para validar; la *dataclass* es un decorador que genera los
métodos, y se valida en `__post_init__`. Con `frozen=True`, asignar un atributo lanza `FrozenInstanceError`.
🔬 Para que sean inmutables de verdad, los campos van con tipos inmutables: `tuple`, `frozenset`, `Decimal`.

**03 → 8. ¿Qué diferencia hay entre SQLAlchemy y el ORM de Django? 🟡**

⏱️ SQLAlchemy es un Data Mapper con Unit of Work e Identity Map: la `Session` rastrea los cambios y los escribe juntos. Django es
Active Record: cada modelo se guarda a sí mismo con `save()`.
🗣️ En SQLAlchemy, cargar dos veces a Ana en la misma sesión da el mismo objeto; en Django, dos objetos. La documentación de Django
dice que sus modelos siguen el Active Record de Fowler.
🔬 Es la elección de `07/02`: Active Record es más simple y acopla el dominio a la tabla; el Data Mapper separa y cuesta más
piezas.

**03 → 9. ¿Qué diferencia hay entre `functools.singledispatch` y el `switch` sellado de Java 21? 🟡**

⏱️ Los dos eligen una implementación por el tipo, pero `singledispatch` no comprueba la exhaustividad: una variante nueva sin su
función cae en la base y falla al ejecutar.
🗣️ El `switch` sellado no compila si falta un caso. En Python, `match` con patrones de clase tampoco es exhaustivo; la
exhaustividad la puede comprobar un verificador de tipos con uniones y `assert_never`.
🔬 `singledispatch` despacha por el primer argumento; `singledispatchmethod` hace lo mismo para métodos.

**03 → 10. ¿Por qué `super()` puede llamar a una clase hermana? 🟠**

⏱️ Porque `super()` llama a la siguiente clase en la MRO del objeto, y esa MRO la decide la clase final. Con herencia múltiple, la
siguiente puede ser una hermana.
🗣️ En `RepositorioProduccion(Auditable, ConReintentos)`, el `super()` de `Auditable` llama a `ConReintentos`, que `Auditable` ni
conoce. Así se componen los *mixins*: cada uno hace lo suyo y pasa al siguiente.
🔬 Por eso los métodos cooperativos aceptan `**kwargs` y llaman siempre a `super()`; uno que no lo llame corta la cadena.

**03 → 11. ¿Por qué el Singleton con metaclase es un antipatrón en Python? 🟠**

⏱️ Porque esconde estado global detrás de una llamada que parece crear un objeto, complica las pruebas, y no aporta nada sobre una
variable de módulo, que ya se ejecuta una sola vez.
🗣️ `CatalogoTipos()` que siempre devuelve el mismo objeto engaña a quien lo lee. Un módulo con una instancia, o mejor una
instancia creada al arrancar y pasada como dependencia, es más claro.
🔬 Tiene los mismos costos que el Singleton de `04/05`; la metaclase solo añade magia.

**03 → 12. ¿Por qué "Python no tiene interfaces" es falso? 🟠**

⏱️ Porque tiene dos: `Protocol`, estructural y comprobado por el verificador de tipos, y las clases abstractas de `abc`,
nominales y comprobadas al instanciar.
🗣️ Lo que no tiene es la obligación de declararlas, por el *duck typing*. Muchos equipos las usan para documentar y verificar
dependencias, como en Java.
🔬 Ramalho dedica el cap. 13 de *Fluent Python* a las cuatro formas de tipar en Python: *duck typing*, *goose typing* (ABC),
tipado estático estructural (`Protocol`) y nominal.

**03 → 13. ¿Por qué un argumento por defecto mutable comparte estado entre llamadas? 🟠**

⏱️ Porque el valor por defecto se evalúa una sola vez, al definir la función, y todas las llamadas que no pasan el argumento
reciben el mismo objeto.
🗣️ `def nueva_persona(nombre, documentos=[])`: Ana y Luis comparten la misma lista. La corrección es `documentos=None` y crear la
lista dentro.
🔬 Es el mismo error que un atributo de clase mutable: compartido por todas las instancias porque vive en la clase.

**03 → 14. ¿Por qué en Python no se escriben *getters* y *setters*? 🟠**

⏱️ Porque un atributo público se puede convertir en `@property` el día que necesite lógica, sin cambiar a quien lo usa. En Java el
*getter* existe para poder cambiar después; en Python no hace falta.
🗣️ `cuenta.saldo` desde el primer día. Si mañana se calcula, `@property def saldo(self)`, y los llamadores no se enteran.
🔬 La encapsulación de `03/01` sigue valiendo: lo que no se quiere exponer va con un guion bajo, por convención, y lo que no debe
cambiar no lleva *setter*.

**03 → 15. Escribe un Decorator del GoF que audite un repositorio solo cuando se configure. 🔴**

⏱️ Una clase que recibe el repositorio interno, cumple el mismo `Protocol`, audita y delega; y la configuración decide si
envolver.
🗣️

```python
class RepositorioAuditado:
    def __init__(self, interno: RepositorioCuentas):
        self._interno = interno
    def guardar(self, cuenta: Cuenta) -> None:
        registrar("guardar", cuenta.id)
        self._interno.guardar(cuenta)
    def por_id(self, id: CuentaId) -> Cuenta:
        return self._interno.por_id(id)

repo = RepositorioAuditado(RepositorioSqlCuentas()) if produccion else RepositorioSqlCuentas()
```

🔬 Lo que preguntará después: si se puede delegar todo automáticamente (`__getattr__` reenvía lo que no se define, a costa de
esconder qué se expone), y por qué no un `@decorator` (se aplica a todas las instancias al definir la clase).

**03 → 16. Revisa este código y di qué falla: `@auditado` sobre `RepositorioCuentas.guardar` para auditar solo en producción. 🔴**

⏱️ El `@auditado` se aplica al definir la clase y cambia `guardar` para todas las instancias: auditan también las pruebas y
cualquier otro entorno. No hay forma de elegir por configuración.
🗣️ La corrección es un Decorator del GoF que envuelva la instancia de producción. Además, el envoltorio sin
`@functools.wraps` pierde el nombre de la función en las trazas.
🔬 Lo que preguntará después: si un `@decorator` con una bandera global serviría (sí, y mete una dependencia oculta en cada
llamada), y cuándo el `@decorator` es lo correcto (cuando la conducta es para todos: medir, reintentar una llamada idempotente,
cachear).

**03 → 17. Escribe con SQLAlchemy la carga de Ana, el alta de un documento y el guardado, y señala la Unit of Work y el Identity Map. 🔴**

⏱️ Una `Session` con una transacción, `get` para cargar, el cambio en el objeto, y el *commit* al salir del bloque, sin `save`.
🗣️

```python
with Session(motor) as sesion, sesion.begin():
    ana = sesion.get(Persona, id_ana)
    ana.agregar_documento(pasaporte)
    assert sesion.get(Persona, id_ana) is ana     # Identity Map: una instancia por fila
# Unit of Work: al salir, flush de lo cambiado y commit
```

🔬 Lo que preguntará después: qué hace el *flush* (escribe en la base lo que la sesión registró, en orden), qué pasa si el bloque
lanza (`begin()` deshace), y cuánto debe vivir una sesión (una por operación o por petición, nunca global: es la misma regla que
el `EntityManager` de `07/03`).

**03 → 18. Revisa este código y di qué falla: `def nueva_persona(nombre, documentos=[])` usado para crear a Ana y a Luis. 🔴**

⏱️ La lista por defecto se crea una sola vez, al definir la función: Ana y Luis comparten la misma lista de documentos, y el
pasaporte de Ana aparece en Luis.
🗣️ La corrección:

```python
def nueva_persona(nombre, documentos=None):
    documentos = [] if documentos is None else list(documentos)
```

🔬 Lo que preguntará después: por qué `list(documentos)` (copia defensiva: la persona no debe compartir la lista del llamador), y
dónde más aparece (atributos de clase mutables, y campos de *dataclass*, donde Python obliga a usar
`field(default_factory=list)`).

# 04 — Simulación de entrevista

Las `S#` que ya son preguntas de capítulo remiten a su respuesta; las demás, en tres capas. Los
ejercicios, desarrollados al final.

**04 → S1. ¿Es Go orientado a objetos? 🟢**

Ver `01 → 1`.

**04 → S2. ¿Por qué el *embedding* no es herencia? 🟡**

Ver `01 → 5`.

**04 → S3. ¿Qué ocupa en Go el lugar del Builder? 🟢**

Ver `01 → 3` y `01 → 7`.

**04 → S4. ¿Por qué la interfaz se define en el paquete que la usa? 🟠**

Ver `01 → 11`.

**04 → S5. ¿Qué trampa tiene devolver un puntero nulo como `error`? 🟠**

Ver `01 → 13`.

**04 → S6. ¿Qué es `class` en JavaScript? 🟡**

Ver `02 → 5`.

**04 → S7. ¿Por qué se pierde `this` al pasar un método como función? 🟠**

Ver `02 → 9`.

**04 → S8. ¿Qué garantiza TypeScript en ejecución? 🟠**

Ver `02 → 10`.

**04 → S9. ¿Qué reemplaza al Visitor en TypeScript? 🟡**

Ver `02 → 13`.

**04 → S10. ¿Por qué Node atiende muchas conexiones con un hilo, y qué no se puede hacer en él? 🟠**

Ver `02 → 4` y, en el bloque de concurrencia, `10/08`: `05 → 9` y `05 → 10`.

**04 → S11. ¿Es el `@decorator` el patrón Decorator? 🟡**

Ver `03 → 5`.

**04 → S12. ¿Tiene Python interfaces? 🟠**

Ver `03 → 12`.

**04 → S13. ¿A quién llama `super()` en Python? 🟠**

Ver `03 → 10`.

**04 → S14. ¿Qué patrones hay detrás de SQLAlchemy y de Django ORM? 🟡**

Ver `03 → 8`.

**04 → S15. ¿Cómo se escribe un objeto de valor en Python? 🟢**

⏱️ Con `@dataclass(frozen=True)`: igualdad por valor, `hash` y campos que no se reasignan; con campos de tipos inmutables y la
validación en `__post_init__`.
🗣️ `@dataclass(frozen=True) class Dinero: monto: Decimal; moneda: str`, con un `__post_init__` que rechace monedas
desconocidas. Las operaciones devuelven uno nuevo con `dataclasses.replace` o un constructor.
🔬 Ver `03 → 7`: como el `record`, es superficial; una lista dentro sigue siendo modificable.

**04 → S16. ¿En cuál de los tres lenguajes las interfaces se cumplen sin declararlas, y qué cambia eso? 🟡**

⏱️ En los tres: Go con sus interfaces implícitas, TypeScript con su tipado estructural y Python con el *duck typing* y los
`Protocol`. Cambia que la interfaz la define quien la usa, pequeña, y que el Adapter casi desaparece.
🗣️ En Java la interfaz se declara con `implements`, y por eso vive con la implementación; en estos tres, el acoplamiento va al
revés: el consumidor dice qué necesita.
🔬 La diferencia entre ellos es cuándo se comprueba: Go al compilar, TypeScript al compilar (y nunca al ejecutar), Python solo
con un verificador de tipos externo.

**04 → S17. ¿Qué ocupa el lugar del Singleton en Go, en JavaScript y en Python? 🟡**

⏱️ En Go, una variable de paquete con `sync.OnceValue`; en JavaScript y en Python, el módulo, que se evalúa una vez y queda en
caché.
🗣️ En los tres, el costo de fondo es el del Singleton de `04/05`: estado global y dependencias ocultas. La salida también es la
misma: crear la instancia al arrancar y pasarla como dependencia.
🔬 El Singleton con metaclase de Python es un antipatrón; en Go no hay constructor privado que esconder, porque lo no exportado
ya es privado del paquete.

**04 → S18. ¿Qué tienen en común el *type switch* de Go, `singledispatch` de Python y las uniones de TypeScript frente al `switch` sellado de Java? 🟠**

⏱️ Los tres reemplazan al Visitor eligiendo por el tipo o por un campo, pero solo TypeScript comprueba la exhaustividad (con
`never`); Go y Python fallan, o no hacen nada, al ejecutar con una variante nueva.
🗣️ Java 21 con `switch` sobre una interfaz sellada y TypeScript con uniones discriminadas dan la garantía del compilador; en Go y
Python hay que suplirla con pruebas o con análisis externos.
🔬 Es la razón por la que el Visitor desapareció en Java 21: el compilador da lo que el patrón fingía.

**04 → S19. ¿Qué ocupa el lugar de Strategy en los tres? 🟢**

⏱️ Una función. En Go, un tipo función (`type Politica func(Dinero) Dinero`); en JavaScript, una función o una *closure*; en
Python, una función o un objeto con `__call__`.
🗣️ La interfaz de un solo método de Java era la forma de pasar comportamiento en un lenguaje sin funciones de primera clase. Con
ellas, la estrategia es el valor mismo.
🔬 Cuando la estrategia necesita estado o varios métodos, vuelve a ser un objeto: un *struct* que cumple una interfaz en Go, una
clase en Python.

**04 → S20. ¿Qué ocupa el lugar de *try-with-resources* en los tres? 🟡**

⏱️ En Go, `defer`; en Python, `with` y los *context managers*; en JavaScript, `try`/`finally`.
🗣️ `defer cerrar()` se ejecuta al salir de la función, haya error o no; `with` llama a `__exit__` al salir del bloque, también
con excepción.
🔬 Los tres atan la liberación a un bloque o a una función, no a la vida del objeto como el RAII de C++.

**04 → S21. ¿Dónde se comprueban los tipos en Go, en TypeScript y en Python? 🟠**

⏱️ Go, al compilar y también en ejecución (los tipos existen); TypeScript, solo al compilar, porque los tipos se borran; Python,
con un verificador externo, y en ejecución solo por *duck typing*.
🗣️ La consecuencia práctica: en TypeScript y en Python, lo que entra de fuera se valida en ejecución; en Go, el decodificador de
JSON ya convierte a un tipo concreto, aunque los campos que faltan quedan en su valor cero.
🔬 En Go, las conversiones de interfaz a tipo concreto (`v.(Tipo)`) se comprueban al ejecutar y pueden fallar.

**04 → S22. ¿Qué patrón de concurrencia trae cada uno en el lenguaje? 🟠**

⏱️ Go trae Producer-Consumer con *channels* y *goroutines* baratas; JavaScript, el Reactor como modelo de ejecución con su
*event loop* y el Future con `Promise`; Python, *threads* y `asyncio`, que es también un bucle de eventos.
🗣️ En Go se escribe código bloqueante en muchas *goroutines*; en JavaScript nada puede bloquear el bucle; en Python, `asyncio`
tiene la misma regla que Node.
🔬 Python 3.13 añadió, como opción, una compilación sin el bloqueo global del intérprete (*free threading*); la compilación por
defecto sigue limitando el paralelismo de CPU en hilos.

**04 → S23. ¿Qué patrones del GoF desaparecen al pasar de Java a un lenguaje con funciones de primera clase? 🟠**

⏱️ Los que existían para pasar comportamiento: Strategy, Command y Template Method se vuelven funciones; el Iterator se vuelve
un generador; el Observer, una lista de funciones.
🗣️ No desaparece la tensión —sigue habiendo algo que varía—, desaparece la ceremonia: la interfaz de un método y la clase por
variante.
🔬 Es la tesis del corpus: parte de los patrones era un rodeo para lo que al lenguaje le faltaba, y Ramalho dedica el cap. 10 de
*Fluent Python* a mostrarlo con Strategy y Command.

**04 → S24. ¿Qué pierdes al dejar el `switch` sellado de Java 21? 🟡**

⏱️ La exhaustividad comprobada por el compilador: en Go y en Python, una variante nueva sin su caso no avisa.
🗣️ TypeScript la conserva con uniones y `never`. En los demás, la garantía pasa a las pruebas, o a herramientas de análisis.
🔬 Ver S18.

**04 → S25. "En Go hacemos Template Method con *embedding*, como siempre." ¿Qué preguntas? 🔴**

⏱️ Pregunto quién llama a los pasos. Si el algoritmo está en el tipo embebido, llama a sus propios pasos y nunca a los del tipo
exterior: los "redefinidos" no se ejecutan.
🗣️ Pediría ver una prueba con el caso que redefine un paso. La salida es inyectar el paso como interfaz o como función: el
Template Method se convierte en Strategy.
🔬 Ver `01 → 10`. Es la trampa más cara de Go para quien viene de Java, porque compila y casi siempre pasa las pruebas del caso
base.

**04 → S26. "Tipamos todo con TypeScript, así que no validamos las respuestas del API." ¿Qué respondes? 🔴**

⏱️ Que los tipos se borran al compilar: el *handbook* dice que nunca cambian el comportamiento en ejecución. Un `as` sobre un JSON
es una promesa, y el error aparece lejos de donde entró el dato.
🗣️ Lo que entra de fuera se valida al ejecutar, una vez, en la frontera, y el tipo sale de la validación. Lo de dentro sí lo
protege el compilador.
🔬 Ver `02 → 10` y `02 → 17`.

**04 → S27. "Para auditar en producción, ponemos `@auditado` en todos los métodos." ¿Qué propones? 🔴**

⏱️ Un Decorator del GoF que envuelva la instancia de producción. El `@auditado` se aplica al definir la clase y audita todas las
instancias, en todos los entornos.
🗣️ Con un `Protocol` como interfaz, el envoltorio cumple el mismo tipo sin declararlo, y la configuración decide si envolver. Si
se quisiera auditar siempre, el `@decorator` sí sería razonable, con `functools.wraps`.
🔬 Ver `03 → 15` y `03 → 16`.

**04 → S28. "Patrones de diseño son cosas de Java; en Python no hacen falta." ¿Estás de acuerdo? 🔴**

⏱️ En parte. Desaparece la ceremonia de los patrones que suplían funciones de primera clase; las tensiones siguen, y los patrones
que las nombran también: Unit of Work, Repository, Decorator de objetos, Adapter de un sistema externo.
🗣️ SQLAlchemy es Unit of Work e Identity Map; Django es Active Record; `with` es un recurso con dueño. Saber el nombre permite
elegir, y discutir el precio.
🔬 Lo que sí sobra en Python: el Singleton de clase, el Builder, el Iterator como clase y las jerarquías de fábricas.

**04 → S29. "Para pasar de Java a Go, traducimos las clases a *structs* y las interfaces a interfaces." ¿Qué sale mal? 🔴**

⏱️ Lo que dependía de la herencia: el *embedding* no despacha hacia el exterior, así que los Template Method y las
"redefiniciones" se rompen sin aviso. Y las interfaces grandes, declaradas junto a la implementación, van contra el idioma.
🗣️ Además: excepciones convertidas en `panic` en lugar de errores devueltos, Builders donde irían opciones, y Singletons de clase
donde irían variables de paquete.
🔬 La migración que funciona reescribe por casos de uso, con interfaces pequeñas definidas donde se consumen.

**04 → S30. Te piden elegir entre Go, Node y Python para un servicio de consultas de saldo con mucho tráfico. ¿Qué preguntas haces? 🔴**

⏱️ Qué hace cada consulta (casi todo E/S o también cálculo), qué sabe el equipo, qué hay ya en la casa para operar y observar, y
qué latencia y volumen hay que sostener.
🗣️ Los tres atienden mucho tráfico de E/S: Go con *goroutines* y código secuencial, Node con su *event loop* si nada bloquea,
Python con `asyncio` y más cuidado. Si hay cálculo pesado, Node y Python lo pagan en el hilo; Go no.
🔬 El lenguaje rara vez es el cuello de botella de una consulta de saldo: lo son la base y las conexiones. Elegir lo que el equipo
domina y la casa sabe operar suele pesar más.

**04 → E1. Un Strategy en cuatro lenguajes.**

**Enunciado.** La comisión por tipo de cuenta, de una interfaz y tres clases con `EnumMap` en Java, a Go, JavaScript y Python.

**El primer diseño que sale.** Una interfaz `PoliticaComision` y tres clases o *structs* en cada lenguaje.

**El bueno.** Una función por política y un mapa, en los tres:

```go
type Politica func(monto Dinero) Dinero

var comisiones = map[TipoCuenta]Politica{
	Ahorros:   porcentaje(0.005),
	Corriente: porcentaje(0.008),
	Nomina:    func(Dinero) Dinero { return Cero },
}
```

```js
const comisiones = { AHORROS: porcentaje(0.005), CORRIENTE: porcentaje(0.008), NOMINA: () => 0 };
```

```python
COMISIONES: dict[TipoCuenta, Callable[[Decimal], Decimal]] = {
    TipoCuenta.AHORROS: porcentaje(Decimal("0.005")),
    TipoCuenta.CORRIENTE: porcentaje(Decimal("0.008")),
    TipoCuenta.NOMINA: lambda monto: Decimal("0"),
}
```

- `porcentaje` es en los tres una función que devuelve otra (una *closure*). El patrón —variar el cálculo por tipo sin un
  `switch` que crezca— sigue; la clase por variante desaparece.

**Lo que cuesta.** Nada en clases; lo que se pierde es la exhaustividad del `EnumMap` respecto del `enum`: un tipo nuevo sin entrada
falla al ejecutar. En TypeScript, `Record<TipoCuenta, …>` la recupera.

**Lo que preguntará después.** Cuándo volverías a un objeto (si la política necesita varios métodos o estado, como un tope
mensual acumulado); y cómo representarías el dinero en JavaScript (centavos enteros o una librería decimal, no `number`).

**04 → E2. La validación que no valida.**

**Enunciado.** `NotificadorSMS` embebe `Notificador` y redefine `enviar` y `formatear`; los avisos llegan por correo y sin
recortar.

**El primer diseño que sale.** Copiar `Avisar` en `NotificadorSMS`.

**El bueno.** El diagnóstico: `Avisar` está declarado en `Notificador`, su receptor es un `Notificador`, y llama a
`n.enviar` y `n.formatear` de `Notificador`. Los métodos de `NotificadorSMS` no los llama nadie. La corrección, con el canal
como interfaz:

```go
type Canal interface {
	Formatear(msg string) string
	Enviar(destino, texto string) error
}

type Notificador struct{ canal Canal }

func (n Notificador) Avisar(p Persona, msg string) error {
	return n.canal.Enviar(destinoDe(p), n.canal.Formatear(msg))
}
```

- `CanalCorreo` y `CanalSMS` cumplen `Canal`; el `Notificador` recibe el que corresponda. Copiar `Avisar` funcionaría y
  duplicaría el algoritmo en cada canal.

**Lo que cuesta.** Una interfaz y dos tipos pequeños. A cambio, el despacho es real.

**Lo que preguntará después.** Por qué compiló (los métodos promovidos y los propios conviven sin conflicto; el exterior
"oculta" los del embebido solo cuando se llaman sobre el exterior), y cómo lo habrías detectado (una prueba de `NotificadorSMS`
que compruebe el canal usado).

**04 → E3. El número de cuenta enmascarado.**

**Enunciado.** `CTA-0001` debe mostrarse como `CTA-••01` en los servicios de Go, Node y Python.

**El primer diseño que sale.** Una interfaz `Enmascarador`, una implementación por tipo de dato y una fábrica, en los tres.

**El bueno.** Una función, sin patrón, en cada lenguaje:

```go
func Enmascarar(numero string) string { return numero[:4] + "••" + numero[len(numero)-2:] }
```

```js
const enmascarar = (numero) => `${numero.slice(0, 4)}••${numero.slice(-2)}`;
```

```python
def enmascarar(numero: str) -> str:
    return f"{numero[:4]}••{numero[-2:]}"
```

- Si mañana hay que enmascarar otros datos con otras reglas, se escribe otra función. Una jerarquía por tipo de dato es ceremonia
  hasta que haya una variación real que elegir en ejecución.

**Lo que cuesta.** Nada que valga la pena discutir. En Go, `numero[:4]` corta bytes, no caracteres: con números de cuenta ASCII da
igual; con texto general, se convierte a `[]rune`.

**Lo que preguntará después.** Qué pasa con un número más corto de seis caracteres (validarlo antes; el identificador de cuenta
ya tiene formato), y dónde va la función (junto al tipo `CuentaId`, como método en Go o en Python).

**04 → E4. El servicio de avisos en TypeScript.**

**Enunciado.** `vencidos.forEach(servicio.avisar)` con `vencidos` obtenido con `as DocumentoVencido[]`.

**El primer diseño que sale.** Añadir `any` y un `try`/`catch` alrededor.

**El bueno.** Los defectos, por prioridad:

1. **El `this` perdido**: `servicio.avisar` se pasa sin el objeto y `this.correo` es `undefined`: no se envía ningún aviso. La
   corrección: `vencidos.forEach(d => servicio.avisar(d))`.
2. **El `as` sin validación**: si el API cambia la forma o devuelve un error en JSON, nada lo detecta y el fallo aparece dentro
   de `avisar`. Se valida la respuesta (comprobar `respuesta.ok` y la forma de cada elemento) antes de tiparla.
3. **El `fetch` sin comprobar el estado**: un `500` con cuerpo JSON pasa como lista.

**Lo que cuesta.** Una flecha y una función de validación en la frontera.

**Lo que preguntará después.** Si `bind` en el constructor sería mejor (equivalente; la flecha en el sitio de la llamada es más
local), y qué pasa si `avisar` es asíncrona (`forEach` no espera promesas: `for ... of` con `await`, o `Promise.all` con un
límite).

**04 → E5. El ORM del nuevo servicio en Python.**

**Enunciado.** Un servicio de catálogos casi CRUD y uno de cuentas con reglas que cruzan objetos.

**El primer diseño que sale.** El mismo ORM para los dos, el que el equipo ya conoce.

**El bueno.**

- **Catálogos: Django ORM (Active Record)**, o el ORM que el equipo ya use en ese estilo. Las operaciones son leer, validar campos
  y guardar; el objeto que se guarda a sí mismo es lo más directo, y el administrador de Django da las pantallas casi gratis.
- **Cuentas: SQLAlchemy (Data Mapper con Unit of Work)**. Las reglas viven en un modelo de dominio que no sabe de tablas; la
  `Session` registra los cambios de una transferencia (dos cuentas, dos movimientos) y los escribe juntos; el mapa de identidad
  evita dos objetos para la misma cuenta.

**Lo que cuesta.** Dos estilos en la casa, y más piezas en el de cuentas (mapeos, repositorios). Se justifica por la forma de la
lógica de cada uno, que es el criterio de `07/01` y `07/02`.

**Lo que preguntará después.** Si se podría hacer todo con SQLAlchemy (sí; el costo es escribir a mano lo que el administrador de
Django daba), y dónde va la transacción (en el servicio de aplicación, con `with sesion.begin()`).
