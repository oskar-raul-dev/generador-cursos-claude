# 07 — Respuestas

> Solucionario del bloque `12-antipatrones`: Antipatrones. Cada respuesta en tres capas:
> **⏱️ 30 segundos** (lo que dices primero, sin que te lo pidan), **🗣️ 2 minutos** (lo que
> añades cuando dicen "cuéntame más") y **🔬 El detalle** (para estudiar, no para decir en voz
> alta). Los enunciados están copiados literalmente de su capítulo.
>
> **Vigencia:** 2026-10-03.
>
> **Versiones ejecutadas:** JDK 21.0.12, 17.0.20 y 25.0.4 · Spring Boot 4.1.1 (Spring Framework 7.0.9, Hibernate 7.4.5, H2 2.4.240) (2026-10-04).

**Salto rápido:** [01](#01--code-smells-dentro-de-una-clase) · [02](#02--code-smells-entre-clases) · [03](#03--antipatrones-de-diseño-oo) · [04](#04--el-patrón-mal-usado) · [05](#05--antipatrones-de-código-y-de-proceso) · [06](#06--simulación-de-entrevista)

---

# 01 — Code smells dentro de una clase

**01 → 1. ¿Qué es un *code smell*? 🟢**

⏱️ Un indicio superficial en el código que suele corresponder a un problema más profundo: no es un error, es una señal de que
conviene mirar.
🗣️ Fowler lo define así y atribuye el término a Kent Beck. Cada *smell* del catálogo de *Refactoring* tiene nombre y las
refactorizaciones que suelen quitarlo: Long Function con *Extract Function*, Primitive Obsession con *Replace Primitive with
Object*.
🔬 "Suele": a veces el indicio no esconde nada, y el criterio es decidir si el costo del cambio se paga.

**01 → 2. ¿Qué es Primitive Obsession? 🟢**

⏱️ Representar conceptos del dominio con tipos primitivos: el dinero en `double`, la moneda y el tipo de cuenta en `String`.
🗣️ Las reglas del concepto se repiten en cada uso, los valores se confunden entre sí y el `double` pierde centavos. Se quita con
*Replace Primitive with Object*: `Dinero`, `CuentaId`, `TipoCuenta`.
🔬 Es la obsesión por los primitivos de `02/06`, que es su dueño como concepto.

**01 → 3. ¿Qué es Data Clumps, y cómo se reconoce? 🟢**

⏱️ Datos que aparecen siempre juntos —monto y moneda, desde y hasta— en parámetros, campos y columnas, sin ser un objeto.
🗣️ La prueba: si se borra uno, ¿los demás siguen teniendo sentido? Si no, son un concepto sin nombre. Se quitan con *Extract
Class* o *Introduce Parameter Object*: `Dinero`, `RangoFechas`.
🔬 Al volverse objeto, el grupo gana sus reglas: la moneda del monto, el `desde` antes del `hasta`.

**01 → 4. ¿Qué es Temporary Field? 🟢**

⏱️ Un campo que solo tiene valor durante una operación y está vacío el resto del tiempo.
🗣️ `comisionCalculada`, llenado por `procesar` y leído por `avisar`: quien lee la clase cree que siempre vale algo, y dos hilos
sobre el mismo objeto se pisan.
🔬 Se quita pasando el valor como parámetro o variable local, o con *Extract Class* para el cálculo que lo necesita.

**01 → 5. ¿Qué refactorización quita una Long Function? 🟢**

⏱️ *Extract Function*: cada bloque que hace una cosa pasa a una función con un nombre que dice qué hace.
🗣️ Los comentarios que separan bloques (`// validar`, `// avisar`) son los nombres de las funciones que faltan. El método que
queda se lee como una lista de pasos.
🔬 A veces hace falta antes *Replace Temp with Query* o *Split Variable* para que el bloque se pueda extraer sin arrastrar diez
variables.

**01 → 6. ¿Qué diferencia hay entre Repeated Switches y un `switch` exhaustivo sobre una interfaz sellada? 🟡**

⏱️ El *smell* es el mismo `switch` por tipo repetido en varios sitios, que hay que cambiar todos cuando aparece un tipo. Un único
`switch` exhaustivo, en un solo sitio, es una decisión de diseño.
🗣️ Con una interfaz sellada, el compilador de Java 21 avisa en cada `switch` si falta un caso; aun así, si el mismo `switch`
aparece en cuatro sitios, la regla del tipo está repartida y conviene moverla al tipo.
🔬 Es la tensión de `06/07`: el `switch` sellado facilita añadir operaciones; el polimorfismo, añadir tipos.

**01 → 7. ¿Qué diferencia hay entre *Introduce Parameter Object* y *Preserve Whole Object*? 🟡**

⏱️ *Introduce Parameter Object* crea un objeto nuevo para parámetros que viajan juntos; *Preserve Whole Object* pasa un objeto que
ya existe en lugar de varios de sus campos.
🗣️ `SolicitudTransferencia` es lo primero; pasar la `Cuenta` en lugar de su moneda y su tipo es lo segundo.
🔬 *Preserve Whole Object* aumenta el acoplamiento con el objeto completo; si la función solo necesita dos campos de algo muy
grande, a veces es mejor pasar los dos.

**01 → 8. ¿Qué diferencia hay entre un comentario que es desodorante y uno que es documentación? 🟡**

⏱️ El desodorante explica **qué** hace un código que no se explica solo, y se reemplaza por un nombre. La documentación explica
**por qué**: la regla del negocio, la decisión rara, el error del proveedor que se rodea.
🗣️ `// calcular comisión` se vuelve `calcularComision()`. `// el banco central exige redondeo bancario desde 2024` se queda,
porque ningún nombre lo dice.
🔬 Ousterhout, en *A Philosophy of Software Design*, defiende más los comentarios que Fowler: los que describen lo que no es
obvio desde el código, como la intención de una interfaz.

**01 → 9. ¿Qué diferencia hay entre Large Class y God Object? 🟡**

⏱️ Large Class es el *smell*: una clase con demasiados campos y métodos. God Object es el antipatrón: una clase que concentra la
lógica del sistema y de la que todas dependen.
🗣️ Toda clase dios es grande, no toda clase grande es un dios: una clase grande pero cohesiva (un analizador de un formato
complejo) puede estar bien.
🔬 La salida de los dos es partir por motivo de cambio, y la del God Object está entera en `03`.

**01 → 10. ¿Por qué "un método largo siempre es malo" es falso? 🟠**

⏱️ Porque lo que cuesta no es el número de líneas, sino mezclar niveles de abstracción. Un método largo y lineal, como un mapeo
de cuarenta campos, se lee de arriba abajo; partirlo reparte la lectura en saltos.
🗣️ Un método corto que valida, calcula y persiste a la vez es peor que uno largo que solo copia campos. La pregunta es si para
saber qué hace hay que leer cómo lo hace.
🔬 La métrica de líneas sirve de alarma, no de regla: los analizadores la usan para señalar dónde mirar.

**01 → 11. ¿Por qué la 2.ª ed. de *Refactoring* cambió *Switch Statements* por *Repeated Switches*? 🟠**

⏱️ Porque el problema no es el `switch`, sino el mismo `switch` repetido: un `switch` aislado es código normal.
🗣️ La 1.ª ed., de 1999, reaccionaba contra el código procedural; con lenguajes que tienen `switch` más expresivos, el nombre nuevo
apunta a lo que de verdad cuesta, la duplicación de la decisión por tipo.
🔬 La 2.ª ed. cambió otros nombres en el mismo sentido: Long Method pasó a Long Function, Lazy Class a Lazy Element, e
Inappropriate Intimacy a Insider Trading.

**01 → 12. ¿Por qué no se refactoriza sin pruebas, y qué haces si no las hay? 🟠**

⏱️ Porque refactorizar es cambiar la estructura **sin** cambiar el comportamiento, y sin pruebas no hay forma de saber que no
cambió. Si no las hay, primero se escribe una prueba de caracterización: la que fija lo que el código hace hoy.
🗣️ Para `procesar`: unas cuantas transferencias con sus resultados actuales, incluido lo raro. Después, pasos pequeños, corriendo
las pruebas en cada uno.
🔬 Las refactorizaciones automáticas del IDE (renombrar, extraer) son seguras sin pruebas; las manuales, no.

**01 → 13. ¿Por qué Java 17 y Java 21 cambian la respuesta a un `switch` por tipo? 🟠**

⏱️ En Java 21, un `switch` de patrones sobre una interfaz sellada es exhaustivo y lo comprueba el compilador: un único `switch`
así es aceptable. En Java 17 solo hay exhaustividad sobre `enum` en las expresiones `switch`.
🗣️ Con un `enum` con comportamiento o con una Strategy, la respuesta es la misma en las dos versiones. Lo que cambia es que en 21
el `switch` sobre tipos deja de ser frágil.
🔬 Sigue valiendo que el `switch` **repetido** es el *smell*: la exhaustividad avisa de lo que falta, no evita repetir la decisión.

**01 → 14. Refactoriza la firma `procesar(String, String, double, String, String, boolean, String)` y di qué *smells* quitas. 🔴**

⏱️ Una `SolicitudTransferencia` con tipos del dominio, y el aviso y la prioridad fuera de la lista de banderas.
🗣️

```java
public record SolicitudTransferencia(CuentaId origen, CuentaId destino, Dinero monto, Prioridad prioridad) { }

ResultadoTransferencia procesar(SolicitudTransferencia s);      // la firma nueva
```

🔬 Se quitan Long Parameter List (*Introduce Parameter Object*), Primitive Obsession (`CuentaId`, `Dinero` con su moneda) y el
argumento bandera (`Prioridad` en lugar de `boolean urgente`, o dos métodos con *Remove Flag Argument*). El tipo de cuenta sale
de la `Cuenta` cargada, no del llamador, y el correo del aviso, del titular. Lo que preguntará después: por qué
`ResultadoTransferencia` y no `String` (el resultado tiene forma, y los errores van como excepciones o como resultado tipado).

**01 → 15. Revisa este método y nombra todos los *smells* que ves, en orden de prioridad: el `procesar` del §1. 🔴**

⏱️ Primero Primitive Obsession con el dinero en `double`, porque pierde centavos; después Repeated Switches en la comisión; Long
Function; Long Parameter List; Comments; Mysterious Name; y el `String` como resultado.
🗣️ Por prioridad: el `double` es un error de dinero; el `switch` está repetido en otros sitios y un tipo nuevo se olvida; la
función mezcla cuatro responsabilidades; siete parámetros con tres `String` intercambiables; comentarios que nombran funciones
que faltan; `o`, `d` y `procesar`; `"ERROR: monto"` como resultado, que obliga a comparar cadenas.
🔬 Además, fuera del catálogo: los *setters* de saldo en `Cuenta` (la regla de saldo no está en la cuenta: modelo anémico, de
`03`) y el aviso dentro de la operación (si la transacción falla, el correo ya salió).

**01 → 16. Extrae las cuatro funciones del `procesar` del §1 y escribe el método que queda. 🔴**

⏱️ `validar`, `comisiones.para`, `moverFondos` y `avisar`, con los comentarios convertidos en nombres.
🗣️

```java
public ResultadoTransferencia procesar(SolicitudTransferencia s) {
    validar(s);
    Dinero comision = comisiones.para(s);
    moverFondos(s, comision);
    avisar(s);
    return ResultadoTransferencia.ok();
}
```

🔬 Lo que preguntará después: dónde va cada función (la comisión a una `CalculadoraComisiones` con una estrategia por tipo;
`moverFondos` a `Cuenta.retirar` y `Cuenta.depositar`, que protegen el saldo), y si el aviso debería estar aquí (mejor como
reacción a un evento después del *commit*, como en `09/02`).

# 02 — Code smells entre clases

**02 → 1. ¿Qué es Feature Envy? 🟢**

⏱️ Un método que usa más los datos de otra clase que los de la suya: el generador de extractos que calcula el interés con el
saldo y la tasa de la cuenta.
🗣️ La regla vive lejos de sus datos, se duplica y cambia sin que la clase dueña se entere. Se quita con *Move Function*: el
cálculo va a `Cuenta`.
🔬 Es lo contrario del Information Expert de `03/03`: la responsabilidad va a quien tiene la información.

**02 → 2. ¿Qué es Message Chains? 🟢**

⏱️ Una cadena de llamadas que recorre la estructura de varios objetos: `c.getTitular().getDireccionPrincipal().getCiudad()`.
🗣️ El llamador depende de cada eslabón, y cualquier cambio de forma lo rompe. Se quita con *Hide Delegate* o, mejor, moviendo lo
que se hace con el resultado al primer objeto.
🔬 Las APIs fluidas y las cadenas sobre valores inmutables no son este *smell*: no exponen la estructura interna de nadie.

**02 → 3. ¿Qué es Refused Bequest? 🟢**

⏱️ Una subclase que hereda métodos que no quiere: los ignora, los deja vacíos o lanza `UnsupportedOperationException`.
🗣️ La subclase no cumple lo que la base promete, y rompe la sustitución de Liskov. `Stack extends Vector` y `Properties extends
Hashtable` son los ejemplos del JDK, con sus propias Javadoc desaconsejando lo heredado.
🔬 Se quita con *Replace Superclass with Delegate*: la herencia se vuelve composición.

**02 → 4. ¿Qué es Speculative Generality? 🟢**

⏱️ Abstracciones para un futuro que no llega: una interfaz con una sola implementación "por si acaso", un parámetro sin uso, una
fábrica que crea una sola clase.
🗣️ Cada una añade una indirección y algo que mantener, y no paga nada hasta que el futuro llegue, si llega. Se quita con *Inline
Class*, *Collapse Hierarchy* o *Change Function Declaration*.
🔬 Es el Factory Method o el Abstract Factory puestos sin una variación real, de `04/01` y `04/02`.

**02 → 5. ¿Qué diferencia hay entre Divergent Change y Shotgun Surgery? 🟡**

⏱️ Son opuestos: Divergent Change es **una** clase que cambia por **muchos** motivos; Shotgun Surgery, **un** motivo que obliga a
cambiar **muchas** clases.
🗣️ `ServicioCuentas` tocado por comisiones, extractos y avisos es lo primero; añadir `EMPRESARIAL` y tocar siete clases es lo
segundo. La salida de los dos es la misma idea: lo que cambia junto, vive junto.
🔬 El primero se arregla separando (*Extract Class*); el segundo, juntando (*Move Function*, *Combine Functions into Class*).

**02 → 6. ¿Qué diferencia hay entre *Hide Delegate* y *Remove Middle Man*? 🟡**

⏱️ Son refactorizaciones opuestas: *Hide Delegate* añade un método que esconde la navegación (contra Message Chains); *Remove
Middle Man* quita métodos que solo delegan (contra Middle Man).
🗣️ Entre los dos *smells* hay un equilibrio: esconder demasiado convierte a la clase en un intermediario; esconder poco deja las
cadenas a la vista. Cada refactorización empuja hacia un lado.
🔬 El criterio es cuántos clientes navegan y cuánto cambia la estructura navegada.

**02 → 7. ¿Qué diferencia hay entre un Middle Man y un Facade? 🟡**

⏱️ Los dos delegan; el Facade lo hace a propósito, para esconder un subsistema detrás de una interfaz simple. El Middle Man
delega sin añadir nada.
🗣️ `AltaPersonas` que coordina validación, verificación y guardado es un Facade; un `ServicioCuentas` con veinte métodos que son
`repositorio.porId(id).x()` es un Middle Man.
🔬 Lo mismo vale para el Proxy (añade control) y el Adapter (traduce): delegar no es el problema; delegar sin aportar, sí.

**02 → 8. ¿Qué diferencia hay entre Data Class y un DTO? 🟡**

⏱️ El DTO es una clase de datos a propósito, para transportar; Data Class es el *smell* de una clase del **dominio** sin
comportamiento, cuyas reglas viven en otras clases.
🗣️ Un `record` que cruza la frontera del API está bien vacío. Una `Cuenta` con *getters* y *setters* y las reglas de saldo en un
servicio es el *smell*, y a escala de sistema, el modelo anémico.
🔬 Se quita con *Encapsulate Record*, *Remove Setting Method* y *Move Function* hacia ella.

**02 → 9. ¿Qué diferencia hay entre los nombres de los *smells* de la 1.ª y la 2.ª ed. de *Refactoring*? 🟡**

⏱️ La 2.ª ed. cambió varios nombres y quitó otros: Long Method es Long Function, Switch Statements es Repeated Switches, Lazy
Class es Lazy Element, Inappropriate Intimacy es Insider Trading, y Parallel Inheritance Hierarchies ya no se lista aparte.
🗣️ Añadió además Global Data, Mutable Data y Loops. Los nombres viejos se siguen oyendo en entrevistas y en catálogos en línea,
así que conviene reconocer los dos.
🔬 El cambio de Switch Statements a Repeated Switches es el más instructivo: el problema nunca fue el `switch`, sino repetirlo.

**02 → 10. ¿Por qué "Middle Man es siempre malo" es falso? 🟠**

⏱️ Porque muchos patrones delegan a propósito: el Facade esconde un subsistema, el Proxy añade control de acceso, el Adapter
traduce. El *smell* es el intermediario que no añade nada.
🗣️ Quitar una fachada deliberada por "Middle Man" expone el subsistema a todos los clientes, que es lo que la fachada evitaba.
🔬 La pregunta para decidir: ¿qué perdería el cliente si llamara directamente al delegado?

**02 → 11. ¿Por qué `Stack extends Vector` es un ejemplo de Refused Bequest? 🟠**

⏱️ Porque una pila hereda de `Vector` operaciones que rompen su contrato —insertar o quitar en cualquier posición—, y nadie
impide usarlas.
🗣️ Su propia Javadoc recomienda usar `Deque` (por ejemplo `ArrayDeque`) en su lugar. Con composición, la pila habría expuesto solo
`push`, `pop` y `peek`.
🔬 `Properties extends Hashtable` es el mismo error: su Javadoc desaconseja con fuerza `put` y `putAll`, porque permiten guardar
claves que no son `String`.

**02 → 12. ¿Cuándo una interfaz con una sola implementación no es Speculative Generality? 🟠**

⏱️ Cuando hay una segunda implementación real —el doble de pruebas cuenta— o una frontera que proteger, como el repositorio del
dominio con su implementación JPA en otro módulo.
🗣️ `VerificadorIdentidad` con una implementación de producción y otra simulada para pruebas es un diseño, no una especulación.
La interfaz del dominio que invierte la dependencia hacia la infraestructura, también.
🔬 La especulación es la interfaz sin segundo uso ni frontera, puesta "por si mañana".

**02 → 13. ¿Por qué Feature Envy a veces es deliberado? 🟠**

⏱️ Porque algunos patrones separan a propósito la operación de los datos: un Visitor o una Strategy usan los datos de otros objetos
para que las operaciones se puedan añadir o cambiar sin tocarlos.
🗣️ Un cálculo de comisiones en una Strategy envidia a la cuenta y está bien: la variación es la estrategia. Lo que no está bien
es la envidia sin motivo, como el interés calculado en el extracto.
🔬 La pregunta es si la separación paga algo: variación, una dependencia que no se quiere en el objeto de datos, o una operación
de otra capa.

**02 → 14. Refactoriza el `encabezado` del §1 y di qué *smells* quitas. 🔴**

⏱️ El interés va a `Cuenta` (Feature Envy); la ciudad, detrás de un método del titular (Message Chains).
🗣️

```java
public Dinero interesMensual() { return saldo.por(tasa).dividido(12); }          // en Cuenta

public String encabezado(Cuenta c, Persona titular) {
    return titular.nombre() + " · " + titular.ciudadPrincipal() + " · interés: " + c.interesMensual();
}
```

🔬 El titular se pasa ya cargado: entre agregados se va por identificador (`09/01`), y quien arma el extracto lo carga. Lo que
preguntará después: si `ciudadPrincipal()` no convierte a `Persona` en un Middle Man (no, si es un dato que muchos piden; sí, si
crece a veinte métodos así), y dónde se formatea el dinero (en la presentación, como en `08/06`).

**02 → 15. Revisa este cambio y di qué *smell* revela: añadir el tipo de cuenta `EMPRESARIAL` obligó a tocar siete clases. 🔴**

⏱️ Shotgun Surgery: un solo motivo de cambio, el tipo de cuenta, repartido en siete clases. Casi siempre con Repeated Switches
debajo: el mismo `switch` por tipo en cada una.
🗣️ La salida es juntar lo que cambia por el tipo: un `enum` con comportamiento, una Strategy por tipo o un Type Object con su
política, de modo que un tipo nuevo sea una entrada o una fila.
🔬 Lo que preguntará después: cómo lo detectas antes (el historial: clases que siempre cambian juntas en los mismos *commits*), y
si alguna de las siete debía cambiar de todos modos (un informe que lista los tipos puede tocar su plantilla y estar bien).

**02 → 16. Revisa este código y di qué falla: `class ListaDocumentos extends ArrayList<Documento>` con `add` sobrescrito para lanzar si el documento está vencido. 🔴**

⏱️ Refused Bequest y una regla con agujeros: `ArrayList` tiene otras puertas —`addAll`, `set`, `add(int, E)`, `listIterator().add`—
que no pasan por el `add` sobrescrito, y un documento vencido entra por ellas.
🗣️ La corrección es composición: una clase que tiene una lista privada y expone solo las operaciones que quiere, con la regla en
cada una. Es la colección encapsulada de `02/04` y el agregado de `09/01`.
🔬 Lo que preguntará después: si basta con sobrescribir todas las puertas (frágil: una versión nueva de `ArrayList` puede añadir
otra, el problema de la clase base frágil), y qué dice *Effective Java* (favorecer la composición sobre la herencia, ítem 18).

# 03 — Antipatrones de diseño OO

**03 → 1. ¿Qué es un antipatrón, y en qué se diferencia de un error? 🟢**

⏱️ Una solución que parecía correcta cuando se tomó y que con el tiempo cuesta más de lo que resolvió. Un error es algo que no
funciona; un antipatrón funciona, y cada cambio cuesta más.
🗣️ El God Object empezó con tres métodos y una buena intención: tener todo a mano. Por eso los antipatrones tienen una salida en
pasos, no una corrección de una línea.
🔬 El libro *AntiPatterns* (Brown y otros, 1998) los describe con su síntoma, su causa y su refactorización, y el bloque 12 sigue
ese molde.

**03 → 2. ¿Qué es un God Object? 🟢**

⏱️ Una clase que sabe y hace demasiado: muchas dependencias, muchos métodos sin relación entre sí, y presente en casi todos los
cambios.
🗣️ `ServicioCuentas` con 3 400 líneas, 41 dependencias y siete responsabilidades. *AntiPatterns* lo llama *The Blob*: un objeto
con casi todas las responsabilidades, rodeado de objetos que solo guardan datos.
🔬 Suele ir con un modelo anémico al lado: las reglas están en el dios porque las entidades no tienen ninguna.

**03 → 3. ¿Qué es el modelo anémico? 🟢**

⏱️ Un modelo con clases de dominio que solo tienen datos, *getters* y *setters*, y servicios que contienen todas las reglas.
🗣️ Fowler dice que a primera vista parece un modelo de dominio de verdad, y que su horror fundamental es ir contra la idea básica
del diseño orientado a objetos: juntar datos y comportamiento.
🔬 Es un Transaction Script con clases de dominio; el antipatrón es creer que se tiene otra cosa.

**03 → 4. ¿Qué es Call Super? 🟢**

⏱️ Una base que exige que la subclase llame a `super.metodo()` en su sobrescritura para que todo funcione.
🗣️ Fowler lo describe como un *smell* menor de los marcos orientados a objetos: la regla vive en la documentación, y la subclase
que la olvida compila y falla en silencio.
🔬 La salida es un Template Method con gancho: la base hace su parte y llama a un método vacío que la subclase redefine.

**03 → 5. ¿Qué es Sequential Coupling? 🟢**

⏱️ Un objeto que exige que sus métodos se llamen en un orden concreto, sin que nada lo compruebe: `validar`, `calcularComision`,
`ejecutar`.
🗣️ Un llamador nuevo que ejecuta sin validar rompe la regla sin saberlo. La salida es que el objeto imponga el orden: un único
método público, o un constructor que lo deje válido.
🔬 Suele venir con Temporary Field: un método llena un campo que el siguiente lee.

**03 → 6. ¿Qué diferencia hay entre un God Object y una clase grande? 🟡**

⏱️ La clase grande es un tamaño; el God Object es una concentración de responsabilidades y dependencias. Una clase grande pero
cohesiva —un analizador de un formato complejo— puede estar bien.
🗣️ La señal del dios no son las líneas sino las islas: grupos de métodos que no se llaman entre sí, cada uno con sus
dependencias, y que cambian por motivos distintos.
🔬 Large Class es el *smell* de `01`; God Object es el antipatrón al que suele llevar.

**03 → 7. ¿Qué diferencia hay entre un modelo anémico y un Transaction Script? 🟡**

⏱️ En el código, casi ninguna: los dos ponen las reglas en procedimientos y dejan los datos en estructuras. La diferencia es la
intención: el Transaction Script lo elige a propósito; el modelo anémico cree ser un modelo de dominio.
🗣️ Para un CRUD con pocas reglas, el Transaction Script es honesto y barato. El anémico paga el mapeo de un modelo rico sin
recibir sus ventajas.
🔬 Ver `07/01`: la señal de pasar de uno a otro es que las mismas reglas aparecen en varios procedimientos.

**03 → 8. ¿Qué diferencia hay entre BaseBean y Refused Bequest? 🟡**

⏱️ BaseBean es heredar de una clase de utilidades para usar sus métodos; Refused Bequest es una subclase que rechaza parte de lo que
hereda. Los dos son herencia sin relación de tipo.
🗣️ `Cuenta extends AccesoBaseDatos` es BaseBean: la cuenta no es un acceso a base de datos. `Stack extends Vector` es Refused
Bequest: la pila sí "es" una colección, pero rechaza operaciones que rompen su contrato.
🔬 La salida de los dos es la misma: *Replace Superclass with Delegate*.

**03 → 9. ¿Qué diferencia hay entre Circle-Ellipse y el cuadrado y el rectángulo de LSP? 🟡**

⏱️ Ninguna de fondo: Circle-Ellipse es el nombre del antipatrón, y el cuadrado y el rectángulo, su ejemplo más citado. Un subtipo
que restringe lo que su base mutable permite.
🗣️ En el dominio, `RangoDeUnDia extends RangoFechas` con `setHasta`: cambiar el `hasta` rompe el subtipo. `01/06` lo explica con
LSP; aquí va su salida.
🔬 La salida es la inmutabilidad (sin `setHasta`, la restricción no se rompe) o no heredar.

**03 → 10. ¿Qué diferencia hay entre Object Orgy y una clase con *getters* y *setters*? 🟡**

⏱️ Object Orgy es el resultado de que muchas clases tengan *getters* y *setters* públicos para todo y se modifiquen unas a otras:
ninguna invariante se puede garantizar.
🗣️ Una clase con algún *getter* no es el antipatrón; lo es un sistema donde cualquier clase cambia el estado de cualquier otra. Es
el terreno del modelo anémico y del God Object.
🔬 La salida es la encapsulación de `03/01`: operaciones con nombre de negocio, *Remove Setting Method* y colecciones encapsuladas.

**03 → 11. ¿Por qué un God Object no se arregla partiéndolo en clases del mismo tamaño? 🟠**

⏱️ Porque el tamaño no es el problema: lo es mezclar motivos de cambio. Partir por líneas o por orden alfabético produce clases
que se llaman entre sí para todo, varios dioses pequeños con el acoplamiento intacto.
🗣️ Se parte por actor —quién pide los cambios—: comisiones para riesgo, bloqueos para cumplimiento, extractos para operaciones.
Las clases resultantes pueden tener tamaños muy distintos.
🔬 Es el SRP de `03/02` como herramienta de salida: un motivo de cambio, una clase.

**03 → 12. ¿Por qué el modelo anémico no es un antipatrón siempre? 🟠**

⏱️ Porque en un sistema con pocas reglas, entidades de datos y un Transaction Script son la elección honesta y barata. El
antipatrón es creer que se tiene un modelo de dominio y tener uno anémico.
🗣️ Un catálogo de países y tipos de documento, casi todo altas y cambios, no gana nada con reglas en las entidades. Una cuenta con
saldo, bloqueos y comisiones, sí.
🔬 La pregunta para decidir: ¿las mismas reglas aparecen en varios servicios? Si sí, van a la entidad.

**03 → 13. ¿Por qué la clase original queda como fachada durante la salida de un God Object? 🟠**

⏱️ Para que cada paso deje el sistema funcionando: se extrae una responsabilidad y el método viejo delega en la clase nueva, así
los llamadores no cambian todavía.
🗣️ Después se migran los llamadores uno a uno, y cuando nadie llama al método que delega, se borra. Es un Facade temporal y
deliberado.
🔬 Reescribir de una vez obliga a cambiar a todos los llamadores a la vez, sin red; la fachada temporal permite hacerlo en
*pull requests* pequeños.

**03 → 14. ¿Por qué la inmutabilidad casi elimina el problema de Circle-Ellipse? 🟠**

⏱️ Porque el problema aparece al **cambiar** el objeto: un rango de un día deja de serlo si alguien amplía su `hasta`. Sin
operaciones que modifiquen, el subtipo no puede violar lo que la base promete.
🗣️ Con `RangoFechas` inmutable, "extender el rango" devuelve un rango nuevo, que puede no ser de un día, y nadie rompe nada. Un
cuadrado inmutable es un rectángulo válido.
🔬 Por eso los objetos de valor inmutables de `02/06` y `08/05` evitan casi todas las violaciones de LSP.

**03 → 15. ¿Por qué un Template Method con gancho reemplaza a Call Super? 🟠**

⏱️ Porque la base controla el orden y hace su parte siempre; la subclase solo redefine el gancho, y no tiene nada que recordar.
🗣️ `public final void alAbrir(Cuenta c) { registrar(c); personalizar(c); }` con `personalizar` vacío: la subclase redefine
`personalizar`, y `registrar` se ejecuta aunque la subclase no lo sepa.
🔬 Es la forma NVI de `06/02`: el método público no es virtual, y el punto de extensión sí.

**03 → 16. ¿Cómo se detecta un God Object con el historial de cambios? 🟠**

⏱️ Es la clase con más *commits*, más autores distintos y más conflictos de fusión, y que aparece en cambios de temas sin
relación.
🗣️ Si una clase se toca por comisiones, por extractos y por avisos, cambia por tres motivos. Contar en el historial qué archivos
cambian juntos señala también qué partes conviene separar.
🔬 Combinado con métricas de cohesión (grupos de métodos que usan grupos disjuntos de campos), da el mapa para partirla.

**03 → 17. Planifica la salida del `ServicioCuentas` del §1 en pasos que dejen el sistema funcionando en cada uno. 🔴**

⏱️ Pruebas de caracterización, mapa de responsabilidades por actor, extraer de a una lo que más cambia dejando la clase como
fachada, mover las reglas a `Cuenta`, migrar llamadores, borrar.
🗣️

```text
1. Pruebas de caracterización sobre la API pública de ServicioCuentas
2. Mapa por actor: riesgo → comisiones · cumplimiento → bloqueos · operaciones → extractos · comunicaciones → avisos
3. Extraer CalculadoraComisiones (la que más cambia); ServicioCuentas.comision delega en ella
4. Mover retirar, depositar y bloquear a Cuenta, con sus invariantes; quitar los setters
5. Repetir 3 con extractos, bloqueos y avisos (los avisos, como reacción a eventos)
6. Migrar los llamadores a las clases nuevas, uno por pull request
7. Borrar los métodos que delegan; ServicioCuentas desaparece o queda como fachada pequeña
```

🔬 Lo que preguntará después: cuánto tarda (semanas, en paralelo con el trabajo normal; la ventaja es que se puede parar en
cualquier paso), qué haces con los métodos privados compartidos (se duplican al principio y se limpian después, o van a un
objeto de valor), y cómo convences al equipo (con el historial de conflictos y el tiempo de cada cambio en esa clase).

**03 → 18. Mueve la regla de retiro de un servicio anémico a `Cuenta` y di qué *setter* desaparece. 🔴**

⏱️ El método `retirar` va a `Cuenta` con sus comprobaciones, y `setSaldo` desaparece: el saldo solo cambia por una operación con
nombre.
🗣️

```java
public void retirar(Dinero monto) {
    if (estado != EstadoCuenta.ABIERTA) throw new IllegalStateException("cuenta " + estado);
    Dinero nuevo = saldo.menos(monto);
    if (nuevo.esNegativo()) throw new IllegalStateException("saldo insuficiente");
    saldo = nuevo;
}
```

🔬 Lo que preguntará después: qué pasa con el mapeo de JPA sin *setter* (JPA puede acceder por campo; no necesita *setters*), y
dónde queda el servicio (como servicio de aplicación: carga, llama a `retirar`, guarda).

**03 → 19. Revisa este código y di qué antipatrón hay y el primer paso para salir: `class Cuenta extends AccesoBaseDatos`. 🔴**

⏱️ BaseBean: la cuenta hereda de una clase de utilidades para usar sus métodos, sin ser un acceso a base de datos. Además mezcla
dominio y persistencia.
🗣️ El primer paso: *Replace Superclass with Delegate*, con el acceso como dependencia; el siguiente, sacar la persistencia de la
entidad a un repositorio (`07/02`).
🔬 Lo que preguntará después: qué hereda la cuenta que no debería (toda la API pública de `AccesoBaseDatos`, que cualquiera puede
llamar sobre una cuenta), y por qué no puede heredar de otra cosa ahora (Java tiene herencia simple).

**03 → 20. Revisa este código y di qué antipatrón hay: `interface ConstantesBanco { BigDecimal TASA_USURA = new BigDecimal("0.0275"); }` implementada por `Transferencia`. 🔴**

⏱️ Constant Interface: una interfaz que solo tiene constantes, implementada para usarlas sin prefijo. Bloch lo llama un mal uso de
las interfaces (ítem 22).
🗣️ La constante pasa a ser parte de la API pública de `Transferencia` y de sus subclases. La salida: una clase `final` con
constructor privado y `import static`.
🔬 Lo que preguntará después: si la tasa debería ser una constante (probablemente no: una tasa de usura cambia por regulación y va a
configuración o a una tabla), y si un `BigDecimal` en una constante es seguro (sí, porque es inmutable).

# 04 — El patrón mal usado

**04 → 1. ¿Qué es Singletonitis? 🟢**

⏱️ Usar Singletons por todas partes para tener acceso global cómodo: `X.instancia()` llamado desde el interior de los métodos de
negocio.
🗣️ Cada llamada es una dependencia escondida: no está en la firma, no se puede sustituir en una prueba y arrastra estado global.
La salida es separar las dos promesas: una instancia, la decide el contenedor; acceso global, ninguno.
🔬 Los costos completos están en `04/05` §9; las *C++ Core Guidelines* lo resumen en la regla I.3: evita los singletons.

**04 → 2. ¿Qué es un Service Locator? 🟢**

⏱️ Un registro global al que las clases piden sus dependencias desde dentro de sus métodos:
`LocalizadorServicios.obtener(RepositorioCuentas.class)`.
🗣️ Desacopla de las implementaciones, pero esconde las dependencias: hay que leer todo el código para saber qué necesita la clase, y
las pruebas tienen que llenar el registro. Seemann y van Deursen lo catalogan como antipatrón.
🔬 Fowler lo presentó en 2004 como alternativa a la inyección; en su artículo, lo importante era separar la configuración del uso.

**04 → 3. ¿Qué es el Golden Hammer? 🟢**

⏱️ Aplicar la misma herramienta o el mismo patrón a todos los problemas porque es lo que se conoce: todo es un evento, todo va en
el ORM, todo lleva una fábrica.
🗣️ *AntiPatterns* lo describe como una tecnología familiar aplicada de forma obsesiva. El costo son soluciones que encajan mal y la
pérdida de la capacidad de elegir.
🔬 La señal en una revisión: nadie puede nombrar qué alternativa se descartó y por qué.

**04 → 4. ¿Qué es el Inner-Platform Effect? 🟢**

⏱️ Un sistema tan configurable que reimplementa, peor, la plataforma sobre la que corre: un motor de reglas propio en tablas, con su
lenguaje de expresiones.
🗣️ El resultado es un lenguaje de programación sin compilador, pruebas, depurador ni control de versiones, y las reglas acaban
escribiéndolas los programadores, en filas.
🔬 Es el Interpreter de `06/09` llevado hasta construir una plataforma.

**04 → 5. ¿Qué diferencia hay entre un Service Locator y la inyección de dependencias? 🟡**

⏱️ Con inyección, la clase **recibe** sus dependencias por constructor y no conoce ningún registro; con el localizador, **pide** a un
registro global, y depende de él.
🗣️ Las dos desacoplan de la implementación concreta. La diferencia es dónde quedan las dependencias: en la firma, visibles y
comprobadas al construir, o dentro del código, descubiertas al ejecutar.
🔬 El contenedor de Spring es un registro; usarlo en la raíz de composición es inyección, y pedirle *beans* desde un servicio es
un Service Locator.

**04 → 6. ¿Qué diferencia hay entre *patternitis* y Speculative Generality? 🟡**

⏱️ Speculative Generality es el *smell* de las abstracciones para un futuro que no llega; *patternitis* es su versión con nombre de
patrón: Strategy sin segunda estrategia, fábrica sin segunda familia, puestos por currículum.
🗣️ Las dos se quitan igual: *Inline Class* e *Inline Function* hasta llegar al código directo, y volver a introducir la abstracción
cuando aparezca la variación real.
🔬 *Patternitis* tiene además un costo de lectura propio: los nombres de patrón (`FactoryProvider`) no dicen nada del dominio.

**04 → 7. ¿Qué diferencia hay entre una capa que reenvía y un Facade? 🟡**

⏱️ El Facade simplifica: una operación suya coordina varias del subsistema. La capa que reenvía tiene un método por cada método de
la capa siguiente, con los mismos parámetros, y no decide nada.
🗣️ `AltaPersonas.alta` que valida, verifica y guarda es una fachada. `ServicioPersonasFacade.cambiarCorreo` que llama a
`ServicioPersonas.cambiarCorreo`, que llama al repositorio, es una lasaña.
🔬 Ousterhout llama a esos métodos *pass-through*: no aportan nada y señalan capas con abstracciones demasiado parecidas.

**04 → 8. ¿Qué diferencia hay entre el Singleton del contenedor y el Singleton del GoF? 🟡**

⏱️ El del contenedor es un **alcance**: una instancia por contenedor, que llega por inyección. El del GoF es una **clase** que se
asegura su única instancia y da acceso global estático.
🗣️ El del contenedor conserva lo bueno (una instancia) y quita lo caro (el acceso global): las dependencias siguen en la firma, y
en las pruebas se da otra.
🔬 La documentación de Spring lo dice al describir sus alcances: el Singleton del GoF fija una instancia por cargador de clases;
el de Spring, por contenedor y por *bean*.

**04 → 9. ¿Por qué "más patrones, mejor diseño" es falso? 🟠**

⏱️ Porque cada patrón cuesta indirección, clases y lectura, y solo paga si resuelve una tensión real. Sin la tensión, es
ceremonia: el §1 usa cinco tipos para una línea.
🗣️ El mejor diseño es el más simple que resuelve las variaciones que existen hoy. Cuando aparece la segunda variante, se introduce
el patrón refactorizando, que es el camino de `13/03`.
🔬 La moneda que más se olvida es la legibilidad para quien llega después: un IDE que no lleva a la implementación en un clic.

**04 → 10. ¿Por qué un `getBean` dentro de un servicio es un Service Locator aunque lo provea Spring? 🟠**

⏱️ Porque el servicio pide la dependencia a un registro en lugar de recibirla: que el registro sea el `ApplicationContext` no
cambia nada.
🗣️ Las dependencias desaparecen de la firma, el servicio depende del contenedor entero y las pruebas necesitan un contexto. La
corrección es pedir la dependencia por constructor.
🔬 Hay usos legítimos en el código de infraestructura (resolver *beans* por nombre en una fábrica de *plugins*); en el código de
negocio, no.

**04 → 11. ¿Cómo sales de Singletonitis sin romper a los llamadores? 🟠**

⏱️ En pasos: añadir la dependencia al constructor de quien la usa, con un constructor de conveniencia que pasa el Singleton;
migrar a los llamadores; quitar el constructor de conveniencia y el acceso estático.
🗣️ Cada paso compila y pasa las pruebas. Al final, el contenedor crea una sola instancia y la inyecta, y las pruebas pasan la suya.
🔬 Es la misma técnica de la fachada temporal del God Object (`03` §2): convivencia del camino viejo y el nuevo hasta que nadie usa
el viejo.

**04 → 12. ¿Por qué un repositorio que solo ofrece `todas()` es una Abstraction Inversion? 🟠**

⏱️ Porque esconde lo que la base hace bien —filtrar con un índice— y obliga a los clientes a reconstruirlo encima, peor: cargar un
millón de personas para encontrar los documentos vencidos.
🗣️ La salida es exponer la operación en el idioma del dominio: `documentosVencidosAl(fecha)`, con su consulta, o una Specification
traducida a consulta.
🔬 La regla "el repositorio solo tiene CRUD" produce esto; el repositorio de `07/05` tiene las operaciones que sus clientes
necesitan.

**04 → 13. ¿Cuándo una tabla de configuración se convierte en un Inner-Platform Effect? 🟠**

⏱️ Cuando empieza a describir **lógica** —operadores, condiciones, saltos al registro siguiente— en lugar de **datos**.
🗣️ Una tabla de tarifas por tipo de cuenta son datos: está bien. Una tabla `REGLA(campo, operador, valor, siguiente)` es un
lenguaje: ya no tiene pruebas ni depurador.
🔬 Si las reglas de verdad cambian a menudo y las cambia el negocio, se valora un motor de reglas existente, con sus herramientas,
antes que uno propio.

**04 → 14. Revisa el código del §1 y di qué quitas y qué queda. 🔴**

⏱️ Quito los cinco tipos: la estrategia sin segunda estrategia, la fábrica sin segunda familia y el Singleton sin unicidad. Queda una
línea: `documento.tipo().admite(documento.numero())`.
🗣️ El formato ya es un dato del Type Object `TipoDocumento`, con su expresión regular. Si mañana un tipo necesita una validación
que no cabe en una expresión, se introduce una estrategia **en ese tipo**, como la política de vencimiento de `09/03`.
🔬 Lo que preguntará después: cómo se quita sin romper (primero el `FactoryProvider`, que nadie necesita; después la fábrica; al
final la interfaz, con *Inline Class*), y cómo lo evitas en el futuro (preguntar en la revisión qué variación real protege cada
patrón).

**04 → 15. Convierte un servicio que usa `LocalizadorServicios.obtener` en dos sitios en uno con inyección por constructor. 🔴**

⏱️ Cada llamada al localizador se vuelve un campo `final` inicializado en el constructor, y el localizador desaparece del servicio.
🗣️

```java
public class ServicioTransferencias {
    private final RepositorioCuentas cuentas;
    private final Clock reloj;

    public ServicioTransferencias(RepositorioCuentas cuentas, Clock reloj) {
        this.cuentas = cuentas;
        this.reloj = reloj;
    }
}
```

🔬 Lo que preguntará después: quién crea el servicio (la raíz de composición o el contenedor), cómo se prueba (con un repositorio en
memoria y `Clock.fixed`), y qué pasa si el constructor crece a ocho parámetros (la clase hace demasiado: es la señal de partirla).

**04 → 16. Revisa este diseño y di qué antipatrón hay: siete capas para cambiar el correo de una persona, cinco de ellas con un único método que llama a la siguiente. 🔴**

⏱️ Capas de más, *lasagna code*: cinco capas que solo reenvían. Cada cambio toca siete archivos y depurar es saltar por siete
clases.
🗣️ La salida es medir qué capa decide algo en este caso de uso y fundir las que solo reenvían (*Remove Middle Man*, *Inline
Class*), conservando las que protegen una frontera real: el API, el dominio, la persistencia.
🔬 Lo que preguntará después: si eso no rompe la arquitectura (la arquitectura está para separar decisiones, no para tener un número
de capas), y cómo se decide por caso de uso (un CRUD de correo puede ir del controlador al repositorio; una transferencia necesita
más).

# 05 — Antipatrones de código y de proceso

**05 → 1. ¿Qué es un Big Ball of Mud? 🟢**

⏱️ Un sistema sin estructura reconocible: todo depende de todo, cada arreglo fue rápido y la información se comparte entre partes
lejanas. Foote y Yoder lo llaman la arquitectura de facto más desplegada.
🗣️ Su artículo no lo trata como un fracaso moral: explica las fuerzas que lo producen —plazos, rotación, un dominio que se entiende
tarde— y las formas de vivir con él y de salir, como *Piecemeal Growth* y *Keep It Working*.
🔬 *Reconstruction* (tirarlo y empezar de nuevo) es una de esas formas, y el artículo la presenta como el último recurso.

**05 → 2. ¿Qué es Lava Flow? 🟢**

⏱️ Código que nadie entiende ni se atreve a borrar, congelado en el sistema: versiones viejas de funciones, experimentos que quedaron,
ramas para clientes que ya no existen.
🗣️ *AntiPatterns* lo describe como código muerto e información de diseño olvidada, solidificados en un diseño que sigue cambiando.
Aparece por prototipos que pasaron a producción y por miedo a borrar.
🔬 La salida es medir el uso y borrar: el control de versiones guarda lo borrado.

**05 → 3. ¿Qué es un Boat Anchor? 🟢**

⏱️ Una pieza que no sirve para nada pero se sigue manteniendo, por lo que costó o "por si se necesita": una clase genérica sin
usuarios, una librería comprada que nadie usa.
🗣️ Cuesta compilación, dependencias que actualizar y lectura. Se detecta porque no tiene llamadores, o solo en pruebas, y se borra.
🔬 La diferencia con Speculative Generality es la escala: el ancla suele ser un componente o una herramienta entera.

**05 → 4. ¿Qué es un número mágico, y qué lo reemplaza? 🟢**

⏱️ Un literal con significado de negocio suelto en el código: `0.005`, `18`, `"AHORROS"`. Lo reemplaza una constante con nombre, un
`enum`, o configuración si el negocio lo cambia.
🗣️ `EDAD_MAYORIA = 18` dice qué es y se cambia en un sitio; `TipoCuenta.AHORROS` no se escribe mal. Una tarifa no es una constante:
va en datos.
🔬 Los analizadores estáticos los marcan; los valores obvios (`0`, `1`, `100` en un porcentaje) no necesitan nombre.

**05 → 5. ¿Qué diferencia hay entre Lava Flow y código muerto? 🟡**

⏱️ El código muerto no se ejecuta nunca; Lava Flow es código que quizás se ejecuta, pero nadie entiende para qué está ni se atreve a
tocar.
🗣️ El código muerto se borra en cuanto se comprueba que no se ejecuta. El Lava Flow pide primero averiguar si se usa —llamadores,
cobertura en producción, registros— y luego borrar o documentar.
🔬 *Refactoring* 2.ª ed. tiene una refactorización propia, *Remove Dead Code*.

**05 → 6. ¿Qué diferencia hay entre Copy-Paste Programming y dos fragmentos que se parecen por casualidad? 🟡**

⏱️ Copy-Paste Programming es la misma **regla** copiada: cambiará junta, y las copias divergen. Dos fragmentos parecidos por
casualidad representan reglas distintas que hoy coinciden.
🗣️ La comisión por transferencia en cinco clases es lo primero: una regla, un sitio. Dos validaciones de longitud de campos distintos
son lo segundo: juntarlas acopla cosas que cambiarán por motivos distintos.
🔬 La pregunta es si un cambio del negocio obligaría a cambiar todas las copias a la vez.

**05 → 7. ¿Qué diferencia hay entre una constante y un valor de configuración? 🟡**

⏱️ La constante es un valor que no cambia sin cambiar el código: la mayoría de edad, el número de días de una semana. La
configuración es un valor que el negocio o el entorno cambian: tarifas, límites, URLs.
🗣️ Poner una tarifa en una constante obliga a desplegar para cambiarla; poner la mayoría de edad en configuración invita a que alguien
la cambie sin querer.
🔬 Lo que cambia mucho y lo administra el negocio va en datos (una tabla), con su historial.

**05 → 8. ¿Qué diferencia hay entre Spaghetti Code y un Big Ball of Mud? 🟡**

⏱️ Spaghetti es un problema de flujo dentro de un método o una clase; el Big Ball of Mud es un problema de estructura del sistema
entero.
🗣️ Un sistema bien modularizado puede tener métodos espagueti, que se arreglan con cláusulas de guarda y *Extract Function*. El barro
no se arregla método a método: pide fronteras.
🔬 Foote y Yoder describen el barro precisamente como una jungla de código espagueti: suelen ir juntos.

**05 → 9. ¿Por qué "un Big Ball of Mud se arregla reescribiendo" casi nunca funciona? 🟠**

⏱️ Porque la reescritura compite con un sistema que sigue cambiando, tarda más de lo previsto y pierde las reglas que el barro tenía y
nadie había escrito. Mientras tanto, no entrega nada.
🗣️ Salir por partes —pruebas, una interfaz delante, una parte por vez, funcionando en cada paso— entrega valor en cada paso y se puede
detener en cualquiera.
🔬 Foote y Yoder dejan la reconstrucción para cuando el sistema ya no se puede mantener ni por partes; es el último recurso, no el
primero.

**05 → 10. ¿Por qué antes de unir cinco copias de una regla hay que averiguar cuál es la buena? 🟠**

⏱️ Porque las copias divergieron, y la diferencia puede ser un error o una regla: el 0,0055 de una de ellas puede ser una equivocación o
la tarifa de un tipo de cliente.
🗣️ Unir a ciegas o arregla un error o introduce uno. Se pregunta al negocio, se mira el historial de esa línea, y se escribe una
prueba con la regla correcta antes de unir.
🔬 Si las dos son correctas para casos distintos, la regla única lleva un parámetro, y el caso queda con nombre.

**05 → 11. ¿Cómo decides que un código se puede borrar? 🟠**

⏱️ Midiendo su uso: llamadores en el código (el IDE), ejecuciones en producción (cobertura, registros, métricas) y referencias desde
fuera (reflexión, configuración, otros servicios).
🗣️ Si nada lo usa, se borra, con el historial como red. Si hay duda, se registra cada uso durante un tiempo, y se borra si nadie llega.
🔬 Lo que no se hace es dejarlo "por si acaso": ese es el origen del Lava Flow.

**05 → 12. ¿Cómo reconoces *cargo cult* en una revisión de código? 🟠**

⏱️ Preguntando para qué está algo y recibiendo "siempre se hizo así" o "lo vi en otro proyecto": interfaces para cada clase,
`@Transactional` en cada método, capas que no protegen nada.
🗣️ La salida es escribir, para cada práctica, qué problema resuelve en este código; las que no tienen respuesta se quitan.
🔬 No toda práctica sin explicación es incorrecta: a veces la razón existe y nadie la escribió. Por eso se pregunta antes de quitar.

**05 → 13. Planifica la salida del módulo de comisiones del §1 en pasos que no detengan las entregas. 🔴**

⏱️ Pruebas de caracterización, averiguar la regla correcta, un solo sitio para el cálculo, borrar lo que no se usa, y nombrar los
literales, cada paso en su propio *pull request*.
🗣️

```text
1. Pruebas de caracterización de las cinco rutas que calculan comisión, con sus resultados de hoy
2. Averiguar con el negocio qué significa el 0,0055 (¿error o regla?); escribir la prueba de la regla buena
3. Extract Function de la regla a CalculadoraComisiones; las cinco clases la llaman
4. Medir el uso de calcularV2, la rama "X7" y ProcesadorBatchGenerico; borrar lo que no se usa
5. Las tarifas, de literales a la tabla de tarifas; los tipos, de String a TipoCuenta
```

🔬 Lo que preguntará después: cuánto tiempo (cada paso es pequeño y se puede intercalar con el trabajo normal), y cómo se convence a
quien quiere reescribir (cada paso entrega algo; la reescritura no entrega nada hasta el final).

**05 → 14. Endereza este fragmento con cláusulas de guarda: tres `if` anidados que comprueban que la cuenta exista, esté abierta y el monto no sea negativo antes de transferir. 🔴**

⏱️ Cada comprobación que termina se convierte en una cláusula de guarda al principio, y el caso normal queda al final, sin sangría.
🗣️

```java
if (cuenta == null) throw new CuentaInexistenteException();
if (!cuenta.abierta()) throw new CuentaNoDisponibleException(cuenta.id());
if (monto.esNegativo()) throw new IllegalArgumentException("monto negativo");
transferir(cuenta, monto);
```

🔬 Es *Replace Nested Conditional with Guard Clauses*, del cap. 10 de *Refactoring*. Lo que preguntará después: si una cuenta
inexistente debería llegar hasta aquí (mejor que el repositorio lance al no encontrarla, con `orElseThrow`), y si la comprobación de
"abierta" no es de `Cuenta` (sí: va en `Cuenta.retirar`, como en `09/01`).

# 06 — Simulación de entrevista

Las `S#` que ya son preguntas de capítulo remiten a su respuesta; las demás, en tres capas. Los
fragmentos de la revisión, desarrollados al final.

**06 → S1. ¿Qué es un *code smell*, y por qué no es un error? 🟢**

Ver `01 → 1`.

**06 → S2. ¿Qué *smell* tiene un método que pasa siete parámetros de tipos primitivos? 🟢**

Ver `01 → 14`.

**06 → S3. ¿Qué diferencia hay entre Divergent Change y Shotgun Surgery? 🟡**

Ver `02 → 5`.

**06 → S4. ¿Cuándo un Middle Man no es un *smell*? 🟠**

Ver `02 → 7` y `02 → 10`.

**06 → S5. ¿Qué hace la 2.ª ed. de *Refactoring* con *Switch Statements*? 🟡**

Ver `01 → 11`.

**06 → S6. ¿Por qué un comentario puede ser desodorante? 🟡**

Ver `01 → 8`.

**06 → S7. ¿Cómo sales de un God Object? 🟠**

Ver `03 → 11` y `03 → 17`.

**06 → S8. ¿Cuándo el modelo anémico es aceptable? 🟠**

Ver `03 → 12`.

**06 → S9. ¿Qué es Call Super y qué lo reemplaza? 🟢**

Ver `03 → 4` y `03 → 15`.

**06 → S10. ¿Por qué Circle-Ellipse es un problema de mutabilidad? 🟠**

Ver `03 → 14`.

**06 → S11. ¿Qué es Sequential Coupling? 🟢**

Ver `03 → 5`.

**06 → S12. ¿Por qué un Service Locator no es inyección de dependencias? 🟡**

Ver `04 → 5`.

**06 → S13. ¿Cómo reconoces *patternitis*? 🟠**

Ver `04 → 6` y `04 → 9`.

**06 → S14. ¿Qué es el Golden Hammer? 🟢**

Ver `04 → 3`.

**06 → S15. ¿Cuándo sobra una capa? 🟠**

Ver `04 → 7` y `04 → 16`.

**06 → S16. ¿Qué es Abstraction Inversion? 🟡**

Ver `04 → 12`.

**06 → S17. ¿Por qué no se reescribe un Big Ball of Mud? 🟠**

Ver `05 → 9`.

**06 → S18. ¿Cómo decides si un código se puede borrar? 🟠**

Ver `05 → 11`.

**06 → S19. ¿Cuándo dos fragmentos parecidos no deben unirse? 🟡**

Ver `05 → 6`.

**06 → S20. ¿Qué haces con un número mágico que el negocio cambia? 🟡**

Ver `05 → 7`.

**06 → S21. ¿Cómo priorizas los defectos de un *pull request*? 🟠**

⏱️ Primero lo que rompe dinero, datos o seguridad; después lo que hace frágil el cambio (reglas duplicadas, dependencias ocultas);
al final lo que cuesta leer (nombres, comentarios).
🗣️ Un `double` para el dinero va antes que un nombre feo; un correo enviado dentro de una transacción, antes que una lista de
parámetros larga. Y se separa lo que bloquea la aprobación de lo que puede ir en otro *pull request*.
🔬 Una regla útil: si el defecto llega a producción, ¿qué pasa? Lo que produce un error de negocio bloquea; lo que solo encarece el
mantenimiento se negocia.

**06 → S22. ¿Qué es una prueba de caracterización y cuándo la escribes? 🟡**

⏱️ Una prueba que fija lo que el código hace **hoy**, correcto o no, para poder refactorizarlo sabiendo que no cambia el
comportamiento. Se escribe antes de tocar código sin pruebas.
🗣️ Para el módulo de comisiones: varias transferencias con los resultados actuales, incluidos los raros. Si una refactorización
cambia un resultado, la prueba avisa y se decide si era un error.
🔬 Ver `01 → 12`. El nombre viene de que caracteriza el comportamiento existente; no afirma que sea el deseado.

**06 → S23. ¿Qué pides en un *pull request* que refactoriza y cambia comportamiento a la vez? 🟠**

⏱️ Que se separe en dos: primero la refactorización, sin cambios de comportamiento y con las pruebas en verde; después el cambio,
pequeño y fácil de revisar.
🗣️ Mezclados, la revisión no puede distinguir qué diferencia es intencional; y si algo falla, no se sabe qué lo causó. Fowler lo
llama los dos sombreros: o se refactoriza, o se añade funcionalidad.
🔬 Si separar cuesta demasiado, al menos en *commits* distintos dentro del mismo *pull request*.

**06 → S24. ¿Cómo escribes un comentario de revisión que no suene a juicio? 🟡**

⏱️ Describiendo el costo y proponiendo el paso, sobre el código y no sobre la persona: "si mañana cambia la tarifa, hay que
tocarla en tres sitios; ¿la movemos a `CalculadoraComisiones`?".
🗣️ Se separa lo que bloquea de lo opcional, se pregunta cuando no se entiende la intención, y se reconoce lo que está bien.
🔬 En la entrevista, el tono es parte de lo que se evalúa: un revisor certero y desagradable es un problema de equipo.

**06 → S25. ¿Qué antipatrón de Java aparece distinto en C++? 🟡**

⏱️ La Singletonitis: en C++ suma el orden de inicialización y destrucción de las variables estáticas entre unidades de compilación,
que puede hacer que un Singleton use a otro ya destruido.
🗣️ La estática local (el Singleton de Meyers) resuelve la inicialización, no la destrucción. Y el God Object en C++ además arrastra
tiempos de compilación: una cabecera que todos incluyen.
🔬 Ver `04/05`. Al revés, BaseBean es menos dañino en C++ con herencia privada, que no expone la interfaz heredada, aunque sigue
siendo herencia para reutilizar.

**06 → S26. ¿Qué antipatrón es propio de quien escribe Java en Go? 🟡**

⏱️ El Template Method con *embedding*: el método de la base llama a sus propios pasos y nunca a los "redefinidos" del tipo
exterior, así que el comportamiento especializado no se ejecuta.
🗣️ Es un Refused Bequest silencioso: compila, y la subclase cree que participa. La salida es inyectar el paso como interfaz.
🔬 Ver `11/01`.

**06 → S27. "Este código tiene diez años y funciona: no lo toques." ¿Qué respondes? 🔴**

⏱️ Que tiene razón en no reescribirlo, y que no tocarlo nunca también es una decisión con costo: cada cambio que pide el negocio se
hace más lento y más arriesgado.
🗣️ Propongo lo mínimo que reduce el riesgo: pruebas de caracterización sobre lo que más cambia, y refactorizar solo la parte que el
próximo requisito toca, dejándola mejor de lo que estaba.
🔬 Si de verdad no cambia nunca, dejarlo es lo correcto; el problema es el código que cambia cada mes y nadie quiere tocar.

**06 → S28. "Para no tener *smells*, usamos un analizador estático con todas las reglas activadas." ¿Qué riesgo ves? 🔴**

⏱️ Que el analizador encuentra síntomas, no problemas: con todas las reglas, el ruido hace que se ignoren todos los avisos, o que se
"arreglen" partiendo métodos lineales y añadiendo comentarios para cumplir.
🗣️ Un *smell* es un indicio que pide criterio. Conviene activar pocas reglas que el equipo acuerde, tratarlas como obligatorias, y
dejar el resto a la revisión humana.
🔬 Los analizadores sirven bien para lo mecánico (código muerto, duplicados, números mágicos); mal para lo que depende del dominio
(dónde va una regla).

**06 → S29. El autor del *pull request* responde a tu comentario con "así lo hace el resto del código". ¿Qué haces? 🔴**

⏱️ Separo dos cosas: si el defecto rompe algo, se corrige igual; si es una convención discutible, se discute aparte para todo el código,
no en este *pull request*.
🗣️ La consistencia tiene valor, y no justifica propagar un error de dinero. Para lo demás, propongo abrir una tarea o una conversación
de equipo, y aprobar sin bloquear.
🔬 Si el patrón problemático está en todo el código, es candidato a una refactorización planificada, no a pelearlo *pull request* por
*pull request*.

**06 → S30. El entrevistador te muestra código que escribiste tú hace años, con un God Object. ¿Cómo lo manejas? 🔴**

⏱️ Lo reconozco sin defenderlo ni disculparme de más: digo qué presión lo produjo, qué cuesta hoy y cómo saldría, en pasos.
🗣️ "Creció porque era el sitio cómodo para cada requisito; hoy lo partiría por motivo de cambio, con pruebas de caracterización y la
clase como fachada temporal." Mostrar que lo veo es lo que la pregunta busca.
🔬 La respuesta que resta es la defensa: "funcionaba". Un antipatrón siempre funcionaba; por eso es un antipatrón y no un error.

**06 → E1. El servicio que lo hace todo.**

**Enunciado.** `ServicioCuentas.retirar` con `ApplicationContext`, `double`, estado en `String`, *setters* y un Singleton de auditoría.

**El primer diseño que sale.** Aprobarlo pidiendo solo que el `String` del estado sea un `enum`.

**El bueno.** Los defectos, por prioridad:

1. **Dinero en `double`** (Primitive Obsession): pierde centavos. `Dinero`.
2. **Sin comprobación de saldo, y la regla fuera de la cuenta** (modelo anémico): `setSaldo` permite saldo negativo y el retiro de una
   cuenta bloqueada no hace nada en silencio. La regla va a `Cuenta.retirar`, que lanza.
3. **Service Locator**: `contexto.getBean` dentro del método esconde la dependencia. Repositorio por constructor.
4. **Singletonitis**: `Auditoria.instancia()`, otra dependencia escondida; y la auditoría dentro de la operación debería ser una
   reacción a un evento.
5. **Magic String** `"ABIERTA"` y `numeroCuenta` como `String` (`CuentaId`).

El primer paso: mover el retiro a `Cuenta.retirar` con `Dinero`, porque es el que protege el dinero; los demás, en el mismo *pull
request* si son pequeños.

**Lo que cuesta.** Un tipo `Dinero` si no existía, un método en `Cuenta` y un constructor con dos dependencias.

**Lo que preguntará después.** Qué pasa con los llamadores del método viejo (cambian la firma: `CuentaId` y `Dinero`), y si el
`@Transactional` falta (sí: el retiro y el guardado van en una transacción, y la auditoría después del *commit*).

**06 → E2. Las comisiones.**

**Enunciado.** La misma fórmula en el controlador, en el proceso nocturno (con 0,0055) y en el simulador (sin el cargo de urgencia).

**El primer diseño que sale.** Unir las tres en una función con 0,005.

**El bueno.**

- **Copy-Paste Programming** de una regla de negocio, con **divergencia**: antes de unir, preguntar al negocio si el 0,0055 del
  proceso nocturno es un error (se ha estado cobrando de más) o una regla (otra tarifa para otro caso), y escribir la prueba de la
  regla correcta.
- El simulador **no** incluye el cargo de urgencia: ¿es un error (el cliente ve menos de lo que se le cobra) o el simulador no
  permite urgencia? También se pregunta.
- **Magic Numbers** y dinero en `double`: la tarifa va a la tabla de tarifas y el cargo a una constante o a la misma tabla; el
  monto, `Dinero`.
- Después: `CalculadoraComisiones.para(monto, prioridad)` en un solo sitio, y las tres llamadas.

**Lo que cuesta.** Una conversación con el negocio y una clase. Si el 0,0055 era un error, hay un problema mayor: cobros de más que
quizás haya que devolver; se dice.

**Lo que preguntará después.** Qué haces si el negocio no sabe (se mira el historial de esa línea y se elige con quien decide, por
escrito), y por qué no unir directamente (porque se puede introducir o corregir un error de dinero sin que nadie lo decida).

**06 → E3. La cuenta de nómina.**

**Enunciado.** `CuentaNomina extends CuentaAhorros` que lanza en `depositar` y olvida `super.alAbrir()`.

**El primer diseño que sale.** Añadir `super.alAbrir()` y aprobar.

**El bueno.**

1. **Refused Bequest**: `depositar` lanza `UnsupportedOperationException`. Todo código que deposita en una `CuentaAhorros` falla
   con una nómina: viola la sustitución de Liskov. La restricción ("solo del empleador") es una regla de la nómina, no una negación
   del depósito: se modela como una política de depósito que la cuenta tiene (composición), o la nómina deja de ser una subclase.
2. **Call Super**: `alAbrir` exige llamar a `super`, y la nómina lo olvidó: la apertura no se registra. La base hace `final void
   alAbrir() { registrarApertura(); personalizar(); }` con un gancho vacío.
3. **Campo `protected saldo`**: las subclases pueden saltarse las reglas de `retirar`. `private`.

El primer paso: el gancho (corrige el error que ya ocurre: aperturas sin registrar); después, sacar la nómina de la herencia.

**Lo que cuesta.** Un método `final` y un gancho en la base; una política de depósito o un tipo de cuenta como dato.

**Lo que preguntará después.** Si el tipo de cuenta debería ser una subclase (con reglas que difieren poco, un Type Object o un `enum`
con su política, como en `09/03`), y cómo encontrar las aperturas sin registrar (consultar las nóminas abiertas sin su registro).

**06 → E4. El extracto.**

**Enunciado.** `generar` con una cadena de cuatro `get`, el interés calculado con los datos de la cuenta y los movimientos filtrados en
memoria.

**El primer diseño que sale.** Aprobarlo: funciona y es corto.

**El bueno.**

1. **Feature Envy**: el interés se calcula con el saldo y la tasa de la cuenta; va a `Cuenta.interesMensual()`.
2. **Abstraction Inversion y agregado demasiado grande**: `c.getMovimientos()` carga todos los movimientos de la cuenta para filtrar
   un mes. Se piden al repositorio: `movimientos.de(c.id(), mes)`, con su consulta.
3. **Message Chains**: la ciudad del titular, a través de cuatro objetos. Un método en `Persona` (`ciudadPrincipal()`), y el titular
   cargado por su identificador.

El primer paso: la consulta de movimientos por mes, porque es la que va a fallar con cuentas grandes.

**Lo que cuesta.** Un método en `Cuenta`, uno en `Persona` y una consulta en el repositorio.

**Lo que preguntará después.** Por qué es peor el segundo que el primero (el primero es mantenimiento; el segundo es memoria y
tiempo que crecen con los años de la cuenta), y dónde se formatea el interés (en la presentación).

**06 → E5. El retiro.**

**Enunciado.** `Cuenta.retirar` con su invariante y `RetirarFondos` con dependencias por constructor y transacción.

**El primer diseño que sale.** Pedir una interfaz para `RetirarFondos`, un Builder para el movimiento o un comentario por línea.

**El bueno.** **Aprobarlo.** Lo que está bien, dicho para que se sepa que se revisó:

- La regla vive en la entidad: estado y saldo se comprueban en `Cuenta.retirar`, con excepciones con nombre.
- `Dinero` y `CuentaId` en lugar de primitivos; el movimiento es inmutable y lo devuelve la raíz.
- Dependencias por constructor, un `Clock` inyectado (se puede probar el tiempo), y la transacción en el servicio de aplicación, que
  no tiene reglas.

Como mucho, un comentario no bloqueante: si dos retiros concurrentes sobre la misma cuenta son posibles, ¿hay `@Version` en
`Cuenta`? Es una pregunta, no un defecto del fragmento.

**Lo que cuesta.** Nada.

**Lo que preguntará después.** Por qué no pediste una interfaz para `RetirarFondos` (no hay una segunda implementación ni una frontera:
sería *patternitis*), y qué mirarías fuera del fragmento (el mapeo de `Cuenta`, la versión para la concurrencia, y las pruebas).
