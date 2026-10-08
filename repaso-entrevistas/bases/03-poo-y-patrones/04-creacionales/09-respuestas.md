# 09 — Respuestas

> Solucionario del bloque `04-creacionales`: Creacionales. Cada respuesta en tres capas:
> **⏱️ 30 segundos** (lo que dices primero, sin que te lo pidan), **🗣️ 2 minutos** (lo que
> añades cuando dicen "cuéntame más") y **🔬 El detalle** (para estudiar, no para decir en voz
> alta). Los enunciados están copiados literalmente de su capítulo.
>
> **Vigencia:** 2026-10-03.
>
> **Versiones ejecutadas:** GCC 14.4 (C++23) · JDK 21.0.12, 17.0.20 y 25.0.4 · Spring Boot 4.1.1 (Spring Framework 7.0.9, Hibernate 7.4.5, H2 2.4.240) · Lombok 1.18.48 (2026-10-04).

**Salto rápido:** [01](#01--factory-method-y-fábricas-estáticas) · [02](#02--abstract-factory) · [03](#03--builder) · [04](#04--prototype) · [05](#05--singleton-y-por-qué-casi-nunca) · [06](#06--contenedores-de-inyección-e-ioc) · [07](#07--más-allá-del-gof) · [08](#08--simulación-de-entrevista)

---

# 01 — Factory Method y fábricas estáticas

**01 → 1. ¿Cuál es la intención del Factory Method del GoF? 🟢**

⏱️ Definir una interfaz para crear un objeto y dejar que las subclases decidan qué se crea: la clase base
usa un objeto que no sabe crear, y delega su creación en un método que la subclase sobrescribe.
🗣️ El ejemplo del capítulo es `ImportadorDocumentos`: su método `importar` lee, crea y asocia al titular, y
el paso "crear" es un gancho `crearDocumento` que `ImportadorRegistraduria` y `ImportadorSre` sobrescriben,
porque cada fuente trae columnas y reglas distintas. El algoritmo no nombra ninguna clase concreta.
🔬 La parte que se olvida es "la clase base usa lo creado". Sin un algoritmo en la base que consuma el
objeto, un método que crea cosas es solo un método, no el patrón del GoF.

**01 → 2. ¿Qué es una fábrica estática, y qué cuatro ventajas tiene sobre un constructor? 🟢**

⏱️ Un método `static` que devuelve una instancia en lugar de un constructor público. Gana nombre, puede
no crear (devolver una compartida), puede devolver un subtipo y puede elegir la clase según el argumento.
🗣️ `TipoDocumento.deCodigo("CC")` dice qué hace y devuelve la instancia del catálogo; `Integer.valueOf`
cachea de −128 a 127; `List.of()` devuelve una clase interna del JDK que no es pública; `EnumSet.noneOf`
elige entre dos implementaciones según el tamaño del `enum`. Es el ítem 1 de *Effective Java*.
🔬 No es el Factory Method del GoF: no hay subclase ni gancho. El nombre "factory method" que usa Bloch
genera la confusión que la entrevista suele explorar.

**01 → 3. ¿Qué es un registro de fábricas? 🟢**

⏱️ Un mapa de código a fábrica: para crear, se busca la fábrica por código y se la llama. Reemplaza un
`switch` que crece por una tabla que se amplía con una entrada.
🗣️ En Java, un `Map<String, FabricaDocumento>` con una lambda por tipo de documento; en C++, un
`std::unordered_map<std::string, std::function<Documento(const Solicitud&)>>`. Añadir `PAS-MX` no toca
las entradas de los demás tipos.
🔬 Se puede llenar a mano, por configuración o por descubrimiento (`ServiceLoader`). Lo que se pierde es
la comprobación del compilador: un código mal escrito falla al ejecutar.

**01 → 4. ¿Qué convenciones de nombre siguen las fábricas estáticas en Java? 🟢**

⏱️ `of` y `from` para crear a partir de valores o convertir, `valueOf` como versión larga de las dos,
`getInstance` cuando puede devolver una compartida y `newInstance` cuando garantiza una nueva.
🗣️ Con otro tipo de retorno que la clase, `getType` y `newType` (`Files.newBufferedReader`). Existen
porque las fábricas no se distinguen de otros estáticos en la documentación: el nombre es la señal.
🔬 La lista es la del ítem 1 de Bloch. En el dominio del corpus, `deCodigo` es una fábrica con nombre en
español; la convención importa más en APIs públicas que en el dominio propio.

**01 → 5. ¿Qué diferencia hay entre el Factory Method del GoF y una fábrica estática? 🟡**

⏱️ El del GoF es un método de instancia que una subclase sobrescribe para que la base use un objeto sin
saber crearlo; la fábrica estática es un método de clase que reemplaza al constructor, sin herencia.
🗣️ El primero resuelve "el algoritmo es común y el objeto varía por subclase"; la segunda resuelve
"necesito nombre, caché o esconder la clase concreta". `Iterable.iterator()` es lo primero;
`List.of` es lo segundo.
🔬 Una fábrica estática no se puede sobrescribir (los estáticos no se despachan dinámicamente), así que no
puede ser un Factory Method del GoF por construcción.

**01 → 6. ¿Qué diferencia hay entre Factory Method y Abstract Factory? 🟡**

⏱️ Factory Method es **un método** que una subclase sobrescribe para crear **un** producto; Abstract
Factory es **un objeto** con varios métodos que crean una **familia** de productos que van juntos.
🗣️ En el dominio: un gancho `crearDocumento` en el importador es Factory Method; un objeto
`FabricaDocumentosPais` que da el validador y el formateador de un mismo país es Abstract Factory. Cada
método de un Abstract Factory suele ser, a su vez, un Factory Method.
🔬 La diferencia de mecanismo es herencia contra composición: el Factory Method se elige al subclasificar;
el Abstract Factory se elige al inyectar el objeto fábrica. Ver `02 → 5`.

**01 → 7. ¿Qué relación hay entre Factory Method y Template Method? 🟡**

⏱️ El Factory Method es un caso particular de Template Method: el algoritmo vive en la base y uno de sus
pasos, el que crea el objeto, lo decide la subclase.
🗣️ En `ImportadorDocumentos`, `importar` es el método plantilla y `crearDocumento` el paso variable. El
GoF lo dice en la sección del patrón: los Factory Methods se llaman normalmente dentro de Template
Methods.
🔬 Comparten el precio: herencia para variar un paso. Por eso los dos tienden a disolverse en composición
(pasar el paso por constructor), que es lo que hace la versión de `01 → 16`.

**01 → 8. ¿Qué cambia entre el Factory Method en C++98 y en C++ moderno? 🟡**

⏱️ La propiedad: en C++98 el gancho devuelve `Documento*` y nadie sabe quién lo borra; en C++ moderno
devuelve `std::unique_ptr<Documento>`, o el valor si el producto no es polimórfico.
🗣️ Además, `override` y `final` hacen que el compilador compruebe la sobrescritura, `= default` declara el
destructor virtual, y `std::make_unique` evita el `new` desnudo. El patrón es el mismo; lo que mejora es lo
que el tipo dice.
🔬 Con un registro de `std::function` muchas veces ni siquiera hace falta la jerarquía de Creator. Y en
C++ un parámetro de plantilla puede hacer de fábrica en tiempo de compilación, sin llamada virtual.

**01 → 9. ¿Por qué `Iterable.iterator()` es un Factory Method del GoF y `List.of` no? 🟠**

⏱️ Porque `AbstractCollection` escribe `contains`, `remove` y `toString` usando un iterador que no sabe
crear, y cada colección sobrescribe `iterator()` para dar el suyo. `List.of` es estático: no hay subclase
que lo sobrescriba.
🗣️ Es exactamente la estructura del GoF: Creator (`AbstractCollection`), Factory Method (`iterator()`),
Concrete Creator (`ArrayList`, `HashSet`) y Product (cada implementación de `Iterator`). `List.of` es una
fábrica estática: da nombre y esconde la clase devuelta.
🔬 Es el mejor ejemplo para la entrevista porque todo el mundo lo ha usado sin saber que era el patrón.

**01 → 10. ¿Cuándo eliges un registro de fábricas en lugar de una subclase por tipo? 🟠**

⏱️ Cuando lo que varía es una regla por un código que crece —tipos de documento, países— y no hay otra
razón para que existan subclases. Una entrada en un mapa cuesta menos que una clase.
🗣️ El registro deja la regla de cada tipo en una línea, se amplía sin tocar a los demás y se puede llenar
desde configuración o por descubrimiento. La subclase por tipo obliga a una clase por código y a decidir
la subclase en algún sitio, que suele ser otro `switch`.
🔬 El registro pierde la comprobación del compilador; un test que recorra el catálogo de tipos y compruebe
que cada código tiene fábrica la recupera.

**01 → 11. ¿Cuándo la variación por tipo de documento no necesita ninguna fábrica? 🟠**

⏱️ Cuando lo que varía es un dato —el formato del número, si vence—: eso va en los campos de
`TipoDocumento`, y la creación es un constructor.
🗣️ Es el Type Object: un objeto cuyas instancias son los tipos. Un país nuevo es una fila en el catálogo,
no código. La fábrica se justifica cuando la regla es lógica que no cabe en un dato, como "vence el día
que el titular cumple 18".
🔬 Ver `02/06` §7. El orden de preferencia es dato, después función registrada, y por último subclase.

**01 → 12. ¿Qué inconvenientes tiene una fábrica estática, y cómo los mitigas? 🟠**

⏱️ Dos, los de Bloch: una clase con solo constructores privados no se puede extender, y las fábricas se
pierden entre los demás métodos estáticos.
🗣️ El primero casi siempre es una ventaja disfrazada: empuja a la composición, y una clase de valor
inmutable debe ser `final` de todos modos. El segundo se mitiga con las convenciones de nombre (`of`,
`from`, `valueOf`, `getInstance`, `newInstance`).
🔬 Un tercero que Bloch no lista pero muerde: la fábrica esconde si el objeto es nuevo o compartido, y
`==` entre dos `Integer.valueOf(200)` da `false` mientras con 100 da `true`.

**01 → 13. ¿Por qué en C++ moderno una fábrica devuelve `unique_ptr` o un valor, y no un puntero crudo? 🟠**

⏱️ Porque el tipo de retorno tiene que decir quién es el dueño. `unique_ptr` dice "ahora es tuyo y se
destruye solo"; un valor dice "es una copia tuya"; un puntero crudo no dice nada.
🗣️ El valor es la primera opción cuando el producto no es polimórfico: sin heap, sin indirección y con
eliminación de copia garantizada desde C++17. `unique_ptr` cuando el producto es una jerarquía y hace
falta el despacho dinámico. `shared_ptr` solo si la propiedad se comparte de verdad.
🔬 Las *C++ Core Guidelines* lo fijan en la sección de gestión de recursos: un puntero crudo `T*` no
posee. Devolver `unique_ptr` además se convierte implícitamente a `shared_ptr` si quien llama lo necesita.

**01 → 14. Reescribe el `switch` de §1 como un registro de fábricas en Java, con `PAS-MX` añadido. 🔴**

⏱️ Un `Map<String, FabricaDocumento>` con una lambda por código, y un `crear` que busca y lanza si no
encuentra. `PAS-MX` es una entrada más, con el vencimiento que trae el archivo.
🗣️

```java
@FunctionalInterface
interface FabricaDocumento { Documento crear(Solicitud s); }

record Solicitud(String codigoTipo, String numero, LocalDate emision,
                 LocalDate vencimientoDeclarado, Persona titular) {}

private final Map<String, FabricaDocumento> fabricas = Map.of(
    "CC",     s -> new Documento(TipoDocumento.deCodigo("CC"), s.numero(), s.emision(), null),
    "TI",     s -> new Documento(TipoDocumento.deCodigo("TI"), s.numero(), s.emision(),
                                 s.titular().fechaNacimiento().plusYears(18)),
    "PAS-CO", s -> new Documento(TipoDocumento.deCodigo("PAS-CO"), s.numero().toUpperCase(),
                                 s.emision(), s.emision().plusYears(10).minusDays(1)),
    "PAS-MX", s -> new Documento(TipoDocumento.deCodigo("PAS-MX"), s.numero().toUpperCase(),
                                 s.emision(), Objects.requireNonNull(s.vencimientoDeclarado())));

public Documento crear(Solicitud s) {
    FabricaDocumento f = fabricas.get(s.codigoTipo());
    if (f == null) throw new IllegalArgumentException("tipo desconocido: " + s.codigoTipo());
    return f.crear(s);
}
```

🔬 Lo que preguntará después: por qué `PAS-MX` usa el vencimiento declarado (México emite pasaportes con
varias vigencias, así que la regla no es calculable y el dato viene de la fuente); cómo se prueba que
todos los códigos del catálogo tienen fábrica (un test que recorre el catálogo); y si el mapa debería ser
configurable desde fuera (solo si los tipos los añade alguien que no despliega código).

**01 → 15. Revisa esta clase y di qué le sobra: `class DocumentoFactory { Documento crear(TipoDocumento t, String n) { return new Documento(t, n); } }`. 🔴**

⏱️ Le sobra entera: es una clase cuyo único método llama al constructor con los mismos argumentos. No da
nombre, no cachea, no elige subtipo y no aísla ninguna regla.
🗣️ Añade una clase, una dependencia que inyectar y un salto al leer, a cambio de nada. Si la creación de
`Documento` tiene una regla (calcular el vencimiento), la regla va en el constructor o en una fábrica
estática de `Documento` con nombre; si no la tiene, `new Documento(t, n)` es la respuesta.
🔬 Es generalización especulativa. El argumento habitual —"para poder sustituirla en los tests"— no
aplica: no hay nada que sustituir en crear un objeto de valor. Lo que se sustituye en un test son las
dependencias volátiles, no los `new`.

**01 → 16. Escribe en C++ moderno un `ImportadorDocumentos` cuyo gancho se pasa por constructor en lugar de sobrescribirse, y di qué ganas y qué pierdes. 🔴**

⏱️ La fábrica entra como `std::function` en el constructor y el importador deja de ser abstracto: una
clase, varias configuraciones. Gano composición y pierdo el sitio obvio donde la subclase agrupaba
otras variaciones.
🗣️

```cpp
class ImportadorDocumentos {
public:
    using Fabrica = std::function<Documento(const std::string& linea)>;
    explicit ImportadorDocumentos(Fabrica crear) : crear_{std::move(crear)} {}

    void importar(std::span<const std::string> lineas, Persona& titular) const {
        for (const auto& linea : lineas) titular.agregarDocumento(crear_(linea));
    }
private:
    Fabrica crear_;
};

ImportadorDocumentos registraduria{[](const std::string& l) {
    return Documento{Tipos::cc(), l.substr(3), Paises::colombia()};
}};
```

Gano que la variación se elige al construir, no al compilar la jerarquía; que se combina con otras
variaciones sin multiplicar subclases; y que se prueba pasando una lambda. Pierdo una llamada indirecta
por documento y la posibilidad de que una subclase sobrescriba varios ganchos relacionados a la vez.
🔬 Lo que preguntará después: si eso ya es Strategy (sí: el Factory Method por composición es una
estrategia de creación); y si se podría hacer con una plantilla (`template <class F>`), que evita la
indirección y fija la fábrica en tiempo de compilación, a costa de que cada importador sea un tipo
distinto.

# 02 — Abstract Factory

**02 → 1. ¿Cuál es la intención de Abstract Factory? 🟢**

⏱️ Dar una interfaz para crear familias de objetos relacionados sin nombrar sus clases concretas, de modo
que el cliente reciba una familia entera y coherente.
🗣️ En el dominio: `FabricaDocumentosPais` da el validador y el formateador de un país. El servicio recibe
una fábrica y saca de ella las dos piezas, así que nunca combina el validador de Colombia con el formateador
de México.
🔬 La ganancia real no es "desacoplar la creación" sino **impedir la mezcla**. Si no hay nada que mezclar,
no hay patrón que justificar.

**02 → 2. ¿Qué es una familia de productos, en el sentido del patrón? 🟢**

⏱️ Un conjunto de objetos de tipos distintos que solo tienen sentido juntos: si se combina uno de una familia
con otro de otra, el resultado es incorrecto.
🗣️ El validador y el formateador de documentos de un mismo país; los nodos de un mismo documento DOM; las
sentencias de una misma conexión JDBC. Cada familia es una variante, y cada tipo de pieza es un producto.
🔬 Una familia de un solo producto no es familia: es una implementación. Por eso el patrón pide al menos
dos productos que varíen juntos.

**02 → 3. ¿Qué papel tiene `org.w3c.dom.Document` como Abstract Factory? 🟢**

⏱️ Es la fábrica de la familia: `createElement`, `createTextNode` y `createAttribute` crean nodos que
pertenecen a ese documento y a su implementación.
🗣️ La Javadoc explica que los nodos no pueden existir fuera del contexto de un documento, y por eso los
métodos de fábrica viven en él. Insertar en un documento un nodo creado por otro lanza `DOMException` con
`WRONG_DOCUMENT_ERR`: la regla de no mezclar familias, comprobada al ejecutar.
🔬 `DocumentBuilderFactory.newInstance()` es la puerta: una fábrica estática que elige la implementación de
JAXP. A partir de ahí, toda la familia sale de la misma.

**02 → 4. ¿Qué diferencia hay entre Abstract Factory y Factory Method? 🟡**

⏱️ Factory Method es un método que crea un producto y se elige subclasificando al cliente; Abstract Factory
es un objeto que crea una familia y se elige inyectándolo.
🗣️ Uno es herencia, el otro composición. Cada método de un Abstract Factory es, por dentro, un Factory
Method que la fábrica concreta sobrescribe; pero el cliente no hereda de nada: recibe la fábrica.
🔬 Por eso Abstract Factory se lleva bien con la inyección de dependencias: la familia se decide en la raíz
de composición. Ver `01 → 6`.

**02 → 5. ¿Qué diferencia hay entre Abstract Factory y un registro de fábricas? 🟡**

⏱️ El registro elige una fábrica por código para crear **un** objeto; el Abstract Factory entrega **varios**
objetos de una misma familia. Se combinan: un registro cuyas entradas son fábricas abstractas.
🗣️ `Map<Pais, FabricaDocumentosPais>` es exactamente eso: el mapa elige la familia por país, y la fábrica
da las piezas. Si cada entrada creara una sola pieza, el mapa bastaría y la fábrica sobraría.
🔬 El registro aporta la elección por dato; el Abstract Factory aporta la coherencia. Son ejes distintos.

**02 → 6. ¿Qué diferencia hay entre añadir una familia y añadir un producto? 🟡**

⏱️ Añadir una familia es barato: una fábrica concreta y sus productos, sin tocar nada existente. Añadir un
producto es caro: un método nuevo en la interfaz y en todas las fábricas.
🗣️ Un país nuevo (`FabricaPeru`) entra sin tocar Colombia ni México. Un producto nuevo (un
`GeneradorCarta` por país) obliga a cambiar la interfaz y a implementar el método en cada fábrica, y hasta
que todas lo tengan no compila.
🔬 Es la asimetría del *expression problem*: el patrón está abierto a nuevas variantes y cerrado a nuevas
operaciones. Antes de proponerlo, conviene preguntar cuál de los dos ejes va a crecer.

**02 → 7. ¿Qué cambia entre un Abstract Factory en Java y una clase de rasgos como parámetro de plantilla en C++? 🟡**

⏱️ En Java la familia se elige al ejecutar, inyectando un objeto, y se paga con llamadas virtuales y objetos
en el heap. En C++ una clase de rasgos la fija al compilar: sin heap ni despacho dinámico.
🗣️ `struct Colombia { using Validador = ValidadorColombia; using Formateador = FormateadorColombia; };` y un
`RegistroDocumentos<Colombia>` que crea `typename Familia::Validador{}`. La mezcla es imposible y el
compilador lo resuelve todo.
🔬 El precio es que la familia ya no se puede elegir leyendo el país del documento: cada familia es un tipo
distinto de registro. Si el país llega en los datos, hace falta la versión dinámica, o un `std::variant` de
familias.

**02 → 8. ¿Por qué "Abstract Factory es un Factory Method más grande" es impreciso? 🟠**

⏱️ Porque no es cuestión de tamaño. Lo distinto es qué crea (una familia coherente, no un objeto) y cómo se
elige (inyectando un objeto, no subclasificando).
🗣️ Un Factory Method con diez ganchos sigue siendo herencia aplicada a la creación, y un Abstract Factory con
dos métodos sigue siendo un objeto inyectado que garantiza coherencia. La pregunta útil es si hay familias
que no se deben mezclar.
🔬 La frase nace de que los métodos de un Abstract Factory son Factory Methods. Es cierto por dentro, y
engaña sobre el propósito.

**02 → 9. ¿Cuándo un Abstract Factory es ceremonia? 🟠**

⏱️ Cuando hay un solo producto, una sola familia, o la variación es de datos. En los tres casos se pagan
muchos tipos por nada.
🗣️ Con un producto, es un Factory Method o una estrategia con otro nombre. Con una familia "por si mañana
llega otra", son nueve tipos para dos clases. Si entre países solo cambia un separador y un patrón de
formato, eso va como datos en `Pais` o `TipoDocumento`.
🔬 La regla práctica: escribir las clases concretas, y extraer la fábrica cuando llegue la segunda familia
real. La refactorización es mecánica y el IDE la hace en minutos.

**02 → 10. ¿Dónde se elige la fábrica concreta, y por qué ahí? 🟠**

⏱️ En un solo sitio: la raíz de composición si la familia es fija para la aplicación, o el punto donde se lee
el dato que la decide (el país del documento) si varía por petición.
🗣️ Si la elección se hace en cada servicio, se vuelve a tener el `if` de §1 repartido. Lo bueno es un mapa
de país a fábrica, armado al arrancar e inyectado en quien lo necesita.
🔬 El contenedor de inyección puede hacer esa elección por configuración (un bean por perfil), y entonces la
fábrica concreta no aparece en el código de negocio. Ver `06 → 2`.

**02 → 11. Rediseña el `registrar` de §1 para que validador y formateador no se puedan mezclar, y di cuántos tipos añades. 🔴**

⏱️ Una interfaz `FabricaDocumentosPais` con `validador()` y `formateador()`, una fábrica por país, y el
servicio recibe un `Map<Pais, FabricaDocumentosPais>` y saca las dos piezas de la misma fábrica.
🗣️

```java
public interface FabricaDocumentosPais {
    ValidadorDocumento validador();
    FormateadorDocumento formateador();
}

public final class FabricaMexico implements FabricaDocumentosPais {
    public ValidadorDocumento validador()     { return new ValidadorMexico(); }
    public FormateadorDocumento formateador() { return new FormateadorMexico(); }
}

public void registrar(Persona titular, Documento d) {
    FabricaDocumentosPais pais = fabricas.get(d.emisor());
    pais.validador().validar(d);
    titular.agregarDocumento(d);
    notificador.avisar(titular, "Registrado: " + pais.formateador().formatear(d));
}
```

Tipos añadidos: la interfaz de fábrica y dos fábricas concretas, tres. Las interfaces de producto y sus
cuatro implementaciones ya existían.
🔬 Lo que preguntará después: qué pasa con un país sin fábrica (el mapa devuelve `null`; mejor fallar con un
mensaje claro, o comprobar al arrancar que todo país del catálogo tiene fábrica); y si las piezas deberían
crearse una vez y reutilizarse (si no tienen estado, sí: la fábrica puede devolver siempre la misma
instancia).

**02 → 12. Un compañero propone `FabricaNotificaciones` con un solo método `crearNotificacion()` y una sola implementación. Revísalo. 🔴**

⏱️ No es un Abstract Factory: no hay familia (un producto) ni variantes (una implementación). Es una clase y
una interfaz que no aportan nada sobre `new Notificacion(...)`.
🗣️ El comentario de revisión: "¿Qué variación esperas, y cuándo? Si hoy hay una sola forma de crear la
notificación, créala donde se usa; cuando aparezca un segundo canal, sacamos la fábrica con el caso real
delante". Señalo el costo: dos tipos más, un salto más al leer y una dependencia más que inyectar.
🔬 Lo que preguntará después: si no conviene para los tests (no: lo que se sustituye en un test es el envío,
el `Notificador`, no la creación de un objeto de datos); y qué harías si el compañero insiste (pedir el
segundo caso concreto; si existe, quizás la respuesta es un registro por canal, no una fábrica abstracta).

# 03 — Builder

**03 → 1. ¿Qué problema resuelve el Builder de Bloch? 🟢**

⏱️ Construir objetos con muchos parámetros, sobre todo opcionales, sin constructores telescópicos y sin
objetos a medias: cada argumento con nombre, y el objeto entregado solo cuando está validado.
🗣️ `Persona` con dos obligatorios y ocho opcionales: el telescópico obliga a diez argumentos posicionales
con `null`, y JavaBeans deja el objeto usable antes de que tenga tutor. El builder junta los argumentos y
`build()` comprueba las reglas antes de crear un objeto inmutable.
🔬 Es el ítem 2 de *Effective Java*. Bloch añade una variante para jerarquías con un genérico
autorreferente, que se usa poco fuera de librerías.

**03 → 2. ¿Cuál es la intención del Builder del GoF? 🟢**

⏱️ Separar la construcción de un objeto complejo de su representación, para que el mismo proceso de
construcción pueda crear representaciones distintas.
🗣️ Un director conoce el orden (persona, documentos, contactos) y llama a los pasos de un constructor; cada
constructor concreto arma su formato —CSV, JSON— y lo entrega al final. Cambiar de formato es pasar otro
constructor.
🔬 El ejemplo del libro es un lector de RTF con convertidores a ASCII, TeX y un widget de texto. Su pariente
más claro en Java es el parser SAX con sus `ContentHandler`.

**03 → 3. ¿Qué es un constructor telescópico? 🟢**

⏱️ Una cadena de constructores sobrecargados, cada uno con un parámetro más que el anterior, para cubrir las
combinaciones de opcionales.
🗣️ Escala mal y se lee peor: con diez parámetros, quien llama cuenta posiciones y pasa `null` en las que no
usa, y dos parámetros del mismo tipo invertidos compilan.
🔬 El nombre es de Bloch. El problema de fondo es la falta de argumentos con nombre en Java y C++; lenguajes
que los tienen (Kotlin, Python, C#) apenas necesitan el builder para esto.

**03 → 4. ¿Qué son los *designated initializers* de C++20? 🟢**

⏱️ Una forma de inicializar un agregado nombrando cada campo: `DatosPersona{.nombre = "Luis", .tutor = &ana}`.
Los campos omitidos toman su inicializador por defecto.
🗣️ Dan argumentos con nombre sin escribir un builder: se define un agregado con los campos y un constructor
de la clase de dominio que lo recibe y valida.
🔬 Tres diferencias con C: el orden de los designadores debe ser el de declaración, no se admiten
designadores anidados ni de arreglos, y no se pueden mezclar con inicializadores posicionales.

**03 → 5. ¿Qué diferencia hay entre el Builder del GoF y el de Bloch? 🟡**

⏱️ El del GoF separa un proceso de construcción de varias representaciones, con un director que fija el
orden; el de Bloch es un auxiliar para un objeto con muchos parámetros, que se llama en cualquier orden y
valida al final.
🗣️ En el del GoF hay varios constructores intercambiables y lo que se entrega es una representación; en el
de Bloch hay uno por clase y se entrega un objeto de esa clase. Solo comparten el nombre y la idea de
construir por partes.
🔬 En la entrevista conviene preguntar a cuál se refieren: casi siempre es el de Bloch. Decir que hay dos
ya es una señal de que se leyó la fuente.

**03 → 6. ¿Qué diferencia hay entre un builder y el patrón JavaBeans? 🟡**

⏱️ En JavaBeans el objeto existe desde el `new` y se completa con setters, así que hay un intervalo en que
está a medias y puede usarse; con un builder, el objeto no existe hasta `build()`, y nace completo.
🗣️ JavaBeans además obliga a que el objeto sea mutable (los setters son públicos) e impide comprobar las
reglas que cruzan campos en un solo sitio. El builder concentra esa comprobación en `build()`.
🔬 Un builder cuyos métodos encadenados mutan el propio objeto final (setters que devuelven `this`) es
JavaBeans con otra sintaxis.

**03 → 7. ¿Qué diferencia hay entre un builder y una fábrica estática? 🟡**

⏱️ La fábrica entrega el objeto en una llamada, con sus argumentos fijos; el builder lo arma en varias
llamadas, con los argumentos que se quieran, y lo entrega al final.
🗣️ `TipoDocumento.deCodigo("CC")` es una fábrica: un argumento, una llamada. `Persona.builder(...)` es la
entrada a un builder: el método estático es una fábrica que devuelve el builder, no el objeto.
🔬 Se combinan siempre: la fábrica estática `builder()` evita exponer el constructor del builder y puede
recibir los obligatorios.

**03 → 8. ¿Qué diferencia hay entre un builder de Java y un agregado con *designated initializers* en C++? 🟡**

⏱️ Los dos dan argumentos con nombre; el builder es código que escribes y mantienes, el agregado es una
característica del lenguaje. El agregado exige campos públicos y orden de declaración.
🗣️ En C++ la validación se pone en el constructor de la clase de dominio que recibe el agregado, que hace de
`build()`. En Java no hay equivalente en el lenguaje, y por eso el builder sigue siendo el patrón.
🔬 El agregado no admite validar campo a campo mientras se llena ni métodos con lógica (un `conTutor` que
además fije la nacionalidad); el builder sí. Para el caso común, el agregado gana por no duplicar campos.

**03 → 9. ¿Qué diferencia hay entre un builder y una *fluent interface*? 🟡**

⏱️ La *fluent interface* es un estilo de API, de llamadas encadenadas que se leen como una frase; el builder
es un patrón de construcción. Casi todo builder es fluido, pero no todo API fluido construye algo.
🗣️ `stream().filter().map()` es fluido y no es un builder. Un builder podría no ser fluido (métodos `void`)
y seguir siendo un builder, aunque sería incómodo.
🔬 El término lo popularizaron Fowler y Eric Evans en el bliki de Fowler. Encadenar llamadas sobre el mismo
objeto no viola Demeter: se habla siempre con el mismo.

**03 → 10. ¿Por qué "con records ya no hace falta Builder" es falso? 🟠**

⏱️ Porque un record con diez componentes tiene un constructor canónico de diez argumentos posicionales: el
mismo problema telescópico, sin nombres y sin opcionales.
🗣️ El record resuelve otra cosa: la inmutabilidad y el `equals` sin código. Para muchos campos, un builder
encima del record sigue teniendo sentido, con la validación en el constructor compacto del record para que
el builder no pueda saltársela.
🔬 Java estudia copiar records con cambios (JEP 468, *Derived Record Creation*), pero es una JEP candidata,
sin versión, y no resuelve la primera construcción. Ver `01/03` §5 para los records.

**03 → 11. ¿Dónde van los campos obligatorios en un builder, y por qué? 🟠**

⏱️ En la entrada del builder —el constructor o la fábrica `builder(nombre, fecha)`—, no en un método más.
Así no se pueden olvidar, y el compilador lo comprueba.
🗣️ Si los obligatorios fueran métodos del builder, la omisión solo se detectaría en `build()`, al ejecutar.
`build()` queda para las reglas que cruzan campos: un menor necesita tutor.
🔬 Con muchos obligatorios, la entrada vuelve a ser telescópica; ahí aparece el builder por pasos, que hace
que cada paso obligatorio sea un tipo distinto. Rara vez compensa.

**03 → 12. ¿Qué pasa si pones `@Builder` de Lombok en la clase en lugar de en el constructor? 🟠**

⏱️ Lombok genera un constructor con todos los campos y el builder construye a través de él, sin ninguna
validación: el builder entrega objetos que no cumplen los invariantes.
🗣️ Si se pone en el constructor que valida, `build()` pasa por esa validación. La documentación de Lombok
dice que `@Builder` se puede poner en una clase, un constructor o un método, y el efecto cambia según dónde.
🔬 Además, los campos no asignados quedan en `null`, `0` o `false`, salvo los marcados con
`@Builder.Default`. Con Lombok, la pregunta de revisión es siempre dónde está la anotación.

**03 → 13. ¿Cuándo un builder es ceremonia? 🟠**

⏱️ Con pocos parámetros de tipos distintos, cuando todos son obligatorios, y en el caso del GoF cuando hay
una sola representación.
🗣️ Un `Dinero(monto, moneda)` con builder duplica dos campos para nada. Con todos obligatorios, el builder
cambia la comprobación del compilador por una al ejecutar. Y un director con un solo constructor concreto
es un método con pasos de más.
🔬 El costo oculto es el mantenimiento: cada campo existe dos veces, y un campo nuevo olvidado en el builder
no da error, solo queda siempre vacío.

**03 → 14. Escribe el builder de `Persona` en Java con nombre y fecha obligatorios, tutor y email opcionales, y la regla "un menor necesita tutor". 🔴**

⏱️ Obligatorios en `builder(nombre, fecha)`, opcionales como métodos que devuelven el builder, y la regla en
`build(hoy)` antes de llamar al constructor privado.
🗣️

```java
public static final class Builder {
    private final String nombre;
    private final LocalDate fechaNacimiento;
    private Persona tutor;
    private String email;

    private Builder(String nombre, LocalDate fechaNacimiento) {
        this.nombre = Objects.requireNonNull(nombre);
        this.fechaNacimiento = Objects.requireNonNull(fechaNacimiento);
    }
    public Builder tutor(Persona t) { this.tutor = t; return this; }
    public Builder email(String e)  { this.email = e; return this; }

    public Persona build(LocalDate hoy) {
        if (fechaNacimiento.plusYears(18).isAfter(hoy) && tutor == null)
            throw new IllegalStateException("un menor necesita tutor");
        return new Persona(this);
    }
}
```

🔬 Lo que preguntará después: por qué `build` recibe la fecha (para probar la regla sin depender del reloj);
si la validación no debería estar en el constructor de `Persona` (también vale, y es más seguro si hay otros
caminos de construcción: el builder delega y nadie se la salta); y si el tutor debe ser mayor de edad (sí,
es parte del mismo invariante).

**03 → 15. Escribe el director y un constructor CSV del Builder del GoF que exporte a Ana con sus dos documentos. 🔴**

⏱️ El director recorre la persona y llama a los pasos en orden; el constructor CSV escribe una línea por
documento y entrega el texto en `resultado()`.
🗣️

```java
interface ConstructorExportacion {
    void inicioPersona(String nombre);
    void documento(Documento d);
    void fin();
}

final class ExportadorPersona {                       // el director
    void exportar(Persona p, ConstructorExportacion c) {
        c.inicioPersona(p.nombre());
        p.documentos().forEach(c::documento);
        c.fin();
    }
}

final class ConstructorCsv implements ConstructorExportacion {
    private final StringBuilder sb = new StringBuilder();
    private String persona;
    public void inicioPersona(String nombre) { persona = nombre; }
    public void documento(Documento d) {
        sb.append(persona).append(';').append(d.tipo().codigo()).append(';').append(d.numero()).append('\n');
    }
    public void fin() { }
    public String resultado() { return sb.toString(); }
}

var csv = new ConstructorCsv();
new ExportadorPersona().exportar(ana, csv);
String texto = csv.resultado();
// Ana Rojas Medina;CC;1020304050
// Ana Rojas Medina;PAS-CO;AQ482915
```

🔬 Lo que preguntará después: por qué `resultado()` no está en la interfaz (cada constructor devuelve un
tipo distinto: `String`, un árbol JSON, un `Map`); y si esto no es un Visitor (se parece: los dos recorren
una estructura llamando a un objeto, pero el Builder acumula una representación y el Visitor despacha por
el tipo de cada nodo).

**03 → 16. Revisa este builder y di qué falla: `Persona build() { return new Persona(nombre, fecha, tutor); }` con `nombre` y `fecha` puestos por setters del builder. 🔴**

⏱️ Dos defectos: los obligatorios llegan por métodos que se pueden olvidar, y `build()` no valida nada. Puede
entregar una persona sin nombre o un menor sin tutor.
🗣️ El arreglo: `nombre` y `fecha` en la entrada del builder, con `requireNonNull`, y la regla del tutor en
`build()` (o en el constructor de `Persona`, que el builder llama). Sin eso, el builder es JavaBeans con
sintaxis encadenada.
🔬 Lo que preguntará después: si se podría delegar la validación a Bean Validation (`@NotNull` y una regla de
clase), y la respuesta es que eso valida cuando alguien llama al validador; un invariante del dominio se
comprueba al construir, sin depender de que alguien se acuerde.

# 04 — Prototype

**04 → 1. ¿Cuál es la intención de Prototype? 🟢**

⏱️ Crear objetos copiando un ejemplar ya configurado, y que la copia la haga el propio objeto, para no tener
que conocer su clase concreta.
🗣️ El aviso de vencimiento toma la plantilla del canal —correo o SMS—, le pide `copiar()` y personaliza la
copia. Quien copia no sabe si recibió una `PlantillaEmail` o una `PlantillaSms`, ni le hace falta.
🔬 El GoF lo presenta con un editor gráfico que crea figuras copiando las de una paleta. El núcleo es la
copia polimórfica; el registro de prototipos es lo que lo hace útil.

**04 → 2. ¿Qué es un registro de prototipos? 🟢**

⏱️ Un mapa de nombre a prototipo ya configurado: crear un objeto es buscar el prototipo y copiarlo.
🗣️ `"vencimiento-email"` y `"vencimiento-sms"` apuntan a plantillas armadas al arrancar con remitente,
asunto y firma. Una plantilla nueva es una entrada nueva, sin tocar a quien crea.
🔬 El GoF lo llama *prototype manager*. Es parecido a un registro de fábricas, pero sus entradas son
objetos configurados, no funciones de creación.

**04 → 3. ¿Por qué un constructor no puede copiar un objeto polimórfico sin conocer su clase? 🟢**

⏱️ Porque un constructor siempre crea la clase que nombra: `new PlantillaNotificacion(p)` crea una
`PlantillaNotificacion` (o no compila si es abstracta), nunca la subclase que `p` es en realidad.
🗣️ El tipo dinámico de `p` solo lo conoce `p`. Por eso la copia se pide al objeto con un método que cada
clase sobrescribe; dentro de ese método, la clase concreta sí puede usar su constructor de copia.
🔬 Es la misma razón por la que los constructores no pueden ser virtuales en C++: el "constructor virtual"
que a veces se menciona es justamente este idioma de `clonar()`.

**04 → 4. ¿Qué diferencia hay entre el patrón Prototype y `clone()` de Java? 🟡**

⏱️ El patrón es la copia polimórfica pedida al objeto; `clone()` es un mecanismo de Java para copiar, roto
en varios sentidos, que se puede usar para implementar el patrón pero no conviene.
🗣️ `clone()` hace una copia superficial sin llamar a ningún constructor, choca con los campos `final`,
depende de una interfaz `Cloneable` sin métodos y lanza una excepción comprobada. Un `copiar()` que llama
a un constructor de copia privado implementa el mismo patrón sin ninguno de esos problemas.
🔬 Bloch, ítem 13: `clone()` solo para arreglos. Ver `01/04` §3.

**04 → 5. ¿Qué diferencia hay entre el patrón Prototype y el *scope* `prototype` de Spring? 🟡**

⏱️ Solo el nombre. El *scope* `prototype` crea una instancia nueva desde la definición del bean cada vez que
se pide; no copia ninguna instancia existente.
🗣️ El contraste es con el *scope* `singleton`, que da siempre la misma. En los dos casos el contenedor
construye desde cero con su definición; ningún objeto se clona.
🔬 Un bean `prototype` inyectado en un `singleton` se crea una sola vez, al crear el singleton; para tener
uno nuevo por uso hace falta un `ObjectProvider` o inyección por método. Es el tropiezo clásico del
*scope*, y no tiene nada que ver con el patrón.

**04 → 6. ¿Qué diferencia hay entre Prototype en C++, en Java y con `with` en C#? 🟡**

⏱️ En C++ es un `clonar()` virtual que devuelve `unique_ptr` y es la única forma correcta de copiar un
polimórfico; en Java es un `copiar()` sobre un constructor de copia; en C#, para los `record`, lo da el
lenguaje con `with`.
🗣️ En C++ el patrón evita además el *slicing*, por eso las guías lo exigen. En Java no hay *slicing*
(todo objeto se maneja por referencia) y el patrón solo resuelve conocer la clase. En C#, `with` copia con
cambios y conserva el tipo en tiempo de ejecución, porque el compilador genera un método de copia virtual.
🔬 Las tres copias son superficiales por defecto: lo mutable interno (una lista de destinatarios) hay que
copiarlo a mano en el constructor de copia, también en C#.

**04 → 7. ¿Por qué en C++ una clase polimórfica cierra su copia pública y ofrece `clonar()`? 🟠**

⏱️ Porque copiarla por valor a través de la base parte el objeto: se copia solo la parte de la base, y la
copia pierde los campos y el comportamiento de la derivada. `clonar()` copia el tipo entero.
🗣️ Las *C++ Core Guidelines* lo dicen en C.67 (una clase polimórfica suprime la copia pública) y C.130 (para
copias profundas, un `clone` virtual). La copia de la base queda `protected`, para que las derivadas la
usen en su propio constructor de copia.
🔬 Con *deducing this* o con CRTP se puede escribir `clonar()` una sola vez en un ayudante y heredarlo, para
no repetirlo en cada clase. El ahorro es pequeño y el costo de legibilidad, real.

**04 → 8. ¿Por qué un objeto inmutable no necesita Prototype? 🟠**

⏱️ Porque una copia de un objeto inmutable es indistinguible del original y nunca va a divergir: se comparte
el mismo objeto y listo.
🗣️ Si `personalizar` devolviera una plantilla nueva en lugar de modificar la copia, el registro guardaría
plantillas inmutables y cada aviso derivaría la suya sin copiar nada antes. El patrón existe para objetos
que se van a modificar después de crearlos.
🔬 Es el mismo argumento de `01/04`: cuantos más objetos de valor inmutables tiene el modelo, menos copias
hacen falta. El costo es crear un objeto nuevo por cambio.

**04 → 9. ¿Qué riesgo tiene un registro de prototipos, y cómo lo evitas? 🟠**

⏱️ Que alguien modifique el prototipo en lugar de una copia: desde ese momento todas las copias salen con
el cambio, por ejemplo con el nombre de Ana en el saludo.
🗣️ Se evita haciendo que el registro solo entregue copias (`registro.copiaDe("vencimiento-email")`) y nunca
el prototipo, o haciendo los prototipos inmutables. Y el registro es estado global si se pone en un
estático: mejor inyectarlo.
🔬 En concurrencia el riesgo se multiplica: varios hilos personalizando el prototipo compartido es una
carrera de datos. La regla "el registro solo da copias" la elimina.

**04 → 10. ¿Qué bug aparece si añades un campo mutable y olvidas el constructor de copia? 🟠**

⏱️ El campo queda compartido entre el prototipo y todas sus copias: la primera copia que lo modifica lo
cambia para todas, prototipo incluido.
🗣️ Por ejemplo, una `List<String> destinatarios` añadida a `PlantillaEmail` y no copiada en el constructor
de copia: el aviso de Ana añade su correo a la lista, y el aviso de Carmen sale a los dos.
🔬 Es la copia superficial de `01/04` §2. La defensa es que el constructor de copia pase por el constructor
normal, que hace la copia defensiva de las colecciones; y un test que modifique una copia y compruebe que
el prototipo no cambió.

**04 → 11. Escribe `PlantillaSms` en Java con su `copiar()`, de modo que la copia pase por las validaciones del constructor. 🔴**

⏱️ Un constructor público que valida, un constructor de copia privado que delega en él con `this(...)`, y
`copiar()` que llama al de copia.
🗣️

```java
public final class PlantillaSms implements PlantillaNotificacion {
    private final int longitudMaxima;
    private String texto;

    public PlantillaSms(int longitudMaxima, String texto) {
        if (longitudMaxima <= 0) throw new IllegalArgumentException("longitud no positiva");
        if (texto.length() > longitudMaxima) throw new IllegalArgumentException("texto demasiado largo");
        this.longitudMaxima = longitudMaxima;
        this.texto = texto;
    }
    private PlantillaSms(PlantillaSms otra) { this(otra.longitudMaxima, otra.texto); }

    @Override public PlantillaSms copiar() { return new PlantillaSms(this); }
    @Override public void personalizar(Persona p, Documento d) {
        String nuevo = texto.replace("{fecha}", d.vencimiento().toString());
        if (nuevo.length() > longitudMaxima) throw new IllegalStateException("el SMS no cabe");
        texto = nuevo;
    }
}
```

🔬 Lo que preguntará después: por qué `copiar()` devuelve `PlantillaSms` y no la interfaz (retorno
covariante, permitido desde Java 5: quien tiene una `PlantillaSms` no necesita convertir); y si no sería
mejor que `personalizar` devolviera una plantilla nueva (sí, si se puede: el objeto sería inmutable y el
patrón sobraría).

**04 → 12. Revisa este código y di qué falla: `class PlantillaEmail implements Cloneable { List<String> destinatarios; public PlantillaEmail clone() { return (PlantillaEmail) super.clone(); } }`. 🔴**

⏱️ Tres cosas: no compila, porque `super.clone()` lanza `CloneNotSupportedException` y el método no la
declara ni la captura; la copia es superficial, así que la lista de destinatarios queda compartida; y
`clone()` no pasa por ningún constructor.
🗣️ Por gravedad: la lista compartida es el bug de negocio (un aviso con destinatarios de otro); la excepción
es el error de compilación; y saltarse el constructor salta sus validaciones. El arreglo es un `copiar()`
con constructor de copia que haga `new ArrayList<>(otra.destinatarios)`.
🔬 Lo que preguntará después: si se puede arreglar sin abandonar `clone()` (sí: capturar la excepción y
reasignar `destinatarios` con una copia, pero entonces el campo no puede ser `final`); y por qué Bloch dice
que `clone()` sí está bien para arreglos (en un arreglo de elementos inmutables la copia superficial es la
correcta, y el `clone()` de los arreglos devuelve el tipo exacto sin excepción).

# 05 — Singleton, y por qué casi nunca

**05 → 1. ¿Cuál es la intención del Singleton, y cuáles son sus dos promesas? 🟢**

⏱️ Asegurar que una clase tenga una sola instancia y dar un punto de acceso global a ella. Las dos promesas
son "una sola instancia" y "acceso global", y conviene separarlas.
🗣️ La primera a veces es una regla real: un catálogo que no debe cargarse dos veces, un recurso del
proceso. La segunda es la que trae los problemas: dependencias ocultas, pruebas difíciles, estado global.
Un contenedor de inyección da la primera sin la segunda.
🔬 Casi toda la crítica moderna al patrón (Nystrom, las *Core Guidelines*, Seemann) ataca el acceso global,
no la unicidad.

**05 → 2. ¿Qué es el *holder idiom*? 🟢**

⏱️ Guardar la instancia en un campo `static final` de una clase anidada privada, que la JVM solo inicializa
cuando alguien llama a `instancia()`. Es perezoso y seguro entre hilos sin sincronizar.
🗣️ `private static final class Portador { static final CatalogoTipos INSTANCIA = new CatalogoTipos(); }` y
`instancia()` devuelve `Portador.INSTANCIA`. La seguridad la da la inicialización de clases de la JVM, que
toma un cerrojo por clase.
🔬 También se le llama *initialization-on-demand holder*. Si el constructor lanza, la clase portadora queda
en estado de error: la primera llamada recibe `ExceptionInInitializerError` y las siguientes
`NoClassDefFoundError`, sin reintento.

**05 → 3. ¿Qué es el *Meyers singleton*? 🟢**

⏱️ El Singleton de C++ con una variable estática local dentro de la función de acceso, que devuelve una
referencia. Desde C++11 su inicialización es única y segura entre hilos.
🗣️ `static CatalogoTipos& instancia() { static CatalogoTipos unico; return unico; }`. Se construye la
primera vez que se pasa por la línea, se destruye al terminar el programa y no hay puntero que borrar.
🔬 El nombre es por Scott Meyers, que lo popularizó en *More Effective C++*. La garantía entre hilos la
añadió C++11; antes, dos hilos podían construirlo dos veces.

**05 → 4. ¿Por qué Bloch recomienda el `enum` de un elemento? 🟢**

⏱️ Porque es la única forma que resiste reflexión y serialización sin código extra, además de ser segura
entre hilos y corta.
🗣️ La JLS prohíbe instanciar un enum por reflexión, y la serialización de un enum guarda solo su nombre: al
leerlo devuelve la constante existente. Con constructor privado hacen falta un `readResolve` y una
comprobación en el constructor contra la reflexión.
🔬 Es el ítem 3 de *Effective Java*. El límite es que un enum no puede extender una clase. Y la crítica de
diseño (acceso global) se aplica igual: el enum es el mejor Singleton, no un Singleton mejor justificado.

**05 → 5. ¿Qué diferencia hay entre el Singleton del GoF y el bean singleton de Spring? 🟡**

⏱️ El del GoF es una instancia por cargador de clases, que se busca con un método estático; el de Spring es
una instancia por contenedor y por definición de bean, que se inyecta.
🗣️ Spring lo dice en su documentación de *scopes*: su singleton no es el del GoF. Puede haber dos beans de
la misma clase con nombres distintos, y la clase no sabe que es única: no tiene constructor privado ni
estático.
🔬 Esa es la salida al antipatrón: la unicidad la decide quien arma la aplicación, y la clase sigue siendo
normal y probable con otra instancia en los tests.

**05 → 6. ¿Qué diferencia hay entre un Singleton y una clase de utilidades estática? 🟡**

⏱️ La clase de utilidades no tiene instancia ni estado (`Math`, `Collections`); el Singleton tiene una
instancia, normalmente con estado, y puede implementar interfaces y pasarse como objeto.
🗣️ Por eso un Singleton se puede convertir en dependencia inyectada sin cambiar su API, y una clase estática
no. Si la "utilidad" tiene estado (una caché estática), es un Singleton disfrazado con los mismos problemas.
🔬 Una clase de funciones puras sin estado está bien como estática: no hay nada que sustituir en un test.

**05 → 7. ¿Qué diferencia hay entre la inicialización ansiosa y el holder en Java? 🟡**

⏱️ La ansiosa crea la instancia al inicializar la clase; el holder, al llamar a `instancia()`. Las dos son
seguras entre hilos por la inicialización de clases.
🗣️ En la práctica la diferencia es pequeña, porque la inicialización de una clase ya es perezosa: ocurre
la primera vez que se usa. Solo importa si la clase tiene otros miembros estáticos que se usan antes y no
deben disparar la carga.
🔬 Con la ansiosa, un fallo del constructor rompe la clase entera desde el primer uso de cualquier estático;
con el holder, solo la clase portadora.

**05 → 8. ¿Qué diferencia hay entre el Singleton en C++98 y en C++ moderno? 🟡**

⏱️ En C++98 era un puntero estático con un `if` perezoso, no seguro entre hilos y nunca destruido; en C++
moderno es una estática local, segura entre hilos desde C++11, que devuelve una referencia.
🗣️ La copia se borra con `= delete` en lugar de declararla privada sin definir, y el objeto se destruye al
terminar el programa. El problema que queda es el orden de destrucción entre estáticos.
🔬 La alternativa de C++98, un objeto global, tenía el problema del orden de inicialización entre unidades
de traducción; la estática local lo resuelve porque se construye al primer uso.

**05 → 9. ¿Por qué el `getInstance` con `if (instancia == null)` no es seguro entre hilos? 🟠**

⏱️ Porque dos hilos pueden comprobar el `if` antes de que cualquiera asigne: los dos ven `null` y los dos
crean una instancia. Uno se queda con una y el resto del sistema con la otra.
🗣️ Además, sin sincronización, un hilo puede ver la referencia asignada antes de que los campos del objeto
estén escritos, y usar un catálogo a medio llenar.
🔬 Es una condición de carrera de tipo *check-then-act*: la comprobación y la acción no son atómicas. Las
salidas son las formas de §5, no un `synchronized` alrededor de la asignación.

**05 → 10. ¿Por qué "con `synchronized` en `getInstance` está resuelto" es una respuesta incompleta? 🟠**

⏱️ Porque resuelve la carrera, pero sincroniza **cada** llamada para siempre, aunque la creación ocurra una
sola vez, y no resuelve ninguno de los problemas de diseño del patrón.
🗣️ El costo de un cerrojo sin contención es pequeño en la JVM actual, pero bajo carga sí se nota. El holder y
el enum dan lo mismo sin sincronizar nada después de la inicialización. Y el acceso global, las pruebas y
el ciclo de vida siguen igual.
🔬 Es correcta, que no es poco: es mejor que el DCL mal escrito. La respuesta completa nombra el holder o el
enum, y después dice por qué inyectarías la instancia.

**05 → 11. ¿Por qué el *double-checked locking* necesita `volatile` en Java? 🟠**

⏱️ Porque sin `volatile` el compilador y el procesador pueden reordenar la asignación de la referencia y la
construcción del objeto: otro hilo, en el primer `if` sin cerrojo, ve la referencia no nula y usa un
objeto a medio construir.
🗣️ `volatile` establece una relación *happens-before* entre la escritura del campo y su lectura, así que
quien ve la referencia ve también el objeto completo. Funciona así desde el modelo de memoria de Java 5.
🔬 El mecanismo, con su autopsia, es de [`10/06` §3](../10-concurrencia/06-inicializacion-perezosa-segura.md#3--autopsia-el-dcl-sin-volatile). Para un Singleton, el holder lo hace mejor:
el DCL tiene sentido para campos de instancia perezosos, donde no hay clase que inicializar.

**05 → 12. ¿Cómo rompen la reflexión y la serialización un Singleton, y cómo se protege? 🟠**

⏱️ La reflexión llama al constructor privado con `setAccessible(true)` y crea otra instancia; la
deserialización crea un objeto nuevo sin pasar por `instancia()`. El `enum` resiste las dos.
🗣️ Con constructor privado, la serialización se arregla con `readResolve()` que devuelva la instancia, y la
reflexión con un constructor que lance si la instancia ya existe. Las dos defensas son código frágil que
el enum da gratis.
🔬 La JLS §8.9 prohíbe instanciar enums por reflexión, y la especificación de serialización dice que de un
enum solo se guarda el nombre y se resuelve con `Enum.valueOf`. Con dos *classloaders* no hay defensa: cada
uno carga su clase y su instancia.

**05 → 13. ¿Por qué el Singleton dificulta las pruebas? 🟠**

⏱️ Porque quien lo usa lo busca con un estático en lugar de recibirlo, así que un test no puede darle otro:
el test de `Documento` necesita el catálogo real, con su base de datos.
🗣️ Y como la instancia sobrevive entre tests, el estado que deja uno lo ve el siguiente, y el orden de
ejecución empieza a cambiar los resultados. Las salidas de emergencia —un `setInstanceForTesting`, *mocks*
de estáticos— son parches sobre el diseño.
🔬 Si el Singleton implementa una interfaz y el código de negocio recibe la interfaz por constructor, el
problema desaparece aunque el Singleton siga existiendo: el acceso global queda confinado a la raíz de
composición.

**05 → 14. ¿Cuándo un Singleton sí está justificado? 🟠**

⏱️ Cuando la unicidad es una regla y no una comodidad —un recurso del proceso que de verdad es uno— y no hay
contenedor ni raíz de composición que pueda crear la instancia y pasarla.
🗣️ `Runtime.getRuntime()` es el ejemplo del JDK. En una librería que no controla cómo se arma la aplicación
que la usa (un *logging* simple), el acceso global puede ser el menor de los males.
🔬 Incluso entonces, la buena práctica es que el código de negocio reciba una interfaz: el Singleton queda
como un detalle de cómo se obtiene, no como una dependencia de cada clase.

**05 → 15. Escribe el holder idiom para `CatalogoTipos` y explica por qué es seguro sin sincronizar. 🔴**

⏱️ Una clase anidada privada con el campo `static final`, y un `instancia()` que lo devuelve. Es seguro
porque la JVM inicializa cada clase una sola vez, con un cerrojo, y después nadie escribe el campo.
🗣️

```java
public final class CatalogoTipos {
    private final Map<String, TipoDocumento> porCodigo;

    private CatalogoTipos() { porCodigo = cargarDesdeBase(); }

    private static final class Portador {
        static final CatalogoTipos INSTANCIA = new CatalogoTipos();
    }

    public static CatalogoTipos instancia() { return Portador.INSTANCIA; }

    public TipoDocumento deCodigo(String codigo) { return porCodigo.get(codigo); }
}
```

La inicialización de `Portador` ocurre en la primera llamada a `instancia()`; la JLS §12.4.2 garantiza que
un solo hilo la ejecuta y que los demás esperan y ven el resultado completo. Los campos `final` del catálogo
añaden la garantía de publicación segura de la JLS §17.5.
🔬 Lo que preguntará después: qué pasa si `cargarDesdeBase` lanza (la clase portadora queda en error y las
llamadas siguientes reciben `NoClassDefFoundError`, sin reintento); y cómo lo probarías (no lo probarías:
sacarías la carga a una clase inyectable y dejarías el Singleton, si queda, como cáscara).

**05 → 16. Refactoriza `Documento.esValido()`, que llama a `CatalogoTipos.getInstance()`, para que se pueda probar sin base de datos. 🔴**

⏱️ Sacar la validación a un servicio que recibe el catálogo por constructor, convertir `CatalogoTipos` en una
clase normal con una fábrica de carga, y crearlo una vez en la raíz de composición.
🗣️

```java
public final class ServicioDocumentos {
    private final CatalogoTipos catalogo;
    public ServicioDocumentos(CatalogoTipos catalogo) { this.catalogo = catalogo; }
    public boolean esValido(Documento d, LocalDate hoy) {
        return catalogo.deCodigo(d.codigoTipo()).admite(d, hoy);
    }
}

// en el test
var catalogo = CatalogoTipos.de(List.of(new TipoDocumento("CC", COLOMBIA, Pattern.compile("\\d{6,10}"), false)));
var servicio = new ServicioDocumentos(catalogo);
boolean r = servicio.esValido(cedulaDeAna, LocalDate.of(2026, 10, 3));   // → true, sin base de datos
```

🔬 Lo que preguntará después: si no sería mejor que `Documento` tuviera su `TipoDocumento` ya resuelto (sí:
si el documento guarda el objeto tipo en lugar del código, `d.tipo().admite(d, hoy)` no necesita catálogo
ninguno, y es lo que hace el modelo de `02/06`); y quién garantiza ahora que haya un solo catálogo (la raíz
de composición, que crea uno).

**05 → 17. Escribe el Meyers singleton en C++ y di qué pasa si su constructor lanza. 🔴**

⏱️ Una función estática con una variable estática local que devuelve una referencia, y la copia borrada. Si
el constructor lanza, la variable no queda inicializada y el siguiente que llame lo vuelve a intentar.
🗣️

```cpp
class CatalogoTipos {
public:
    static CatalogoTipos& instancia() {
        static CatalogoTipos unico;      // inicialización única y segura entre hilos desde C++11
        return unico;
    }
    CatalogoTipos(const CatalogoTipos&) = delete;
    CatalogoTipos& operator=(const CatalogoTipos&) = delete;
private:
    CatalogoTipos();                     // puede lanzar si la base no responde
};
```

La excepción sale de `instancia()` hacia quien llamó; la estática queda sin inicializar, y la próxima
llamada repite la construcción. Es distinto de Java, donde la clase portadora queda rota para siempre.
🔬 Lo que preguntará después: dónde está escrito (cppreference, en "Storage duration": si la inicialización
lanza, la variable no se considera inicializada y se reintenta la próxima vez que el control pase por la
declaración); y el orden de destrucción (si el destructor de
otro estático usa el catálogo después de destruido, comportamiento indefinido).

**05 → 18. Revisa este código y di qué falla: `public static CatalogoTipos getInstance() { if (instancia == null) { synchronized (CatalogoTipos.class) { instancia = new CatalogoTipos(); } } return instancia; }`. 🔴**

⏱️ Es un *double-checked locking* al que le falta la segunda comprobación y el `volatile`: dos hilos pueden
pasar el `if`, esperar el cerrojo por turnos y crear dos instancias; y sin `volatile` otro hilo puede ver
un objeto a medio construir.
🗣️ El arreglo mínimo es repetir `if (instancia == null)` dentro del bloque sincronizado y declarar el campo
`volatile`. El arreglo bueno es no escribir esto: el holder o el enum dan lo mismo sin riesgo.
🔬 Lo que preguntará después: por qué el `volatile` es necesario aunque haya `synchronized` (porque la
primera lectura está fuera del bloque sincronizado y no tiene *happens-before* con la escritura); y si el DCL
tiene algún uso legítimo (campos de instancia perezosos, donde no hay una clase que inicializar; lo desarrolla
[`10/06`](../10-concurrencia/06-inicializacion-perezosa-segura.md)).

# 06 — Contenedores de inyección e IoC

**06 → 1. ¿Qué es la inversión de control? 🟢**

⏱️ Un principio por el que el marco llama a tu código, en lugar de que tu código llame a una librería: "no
nos llames, nosotros te llamamos".
🗣️ El contenedor de servlets llama a tu `doGet`; JUnit llama a tus métodos `@Test`; `sort` llama a tu
`Comparator`. Tú das las piezas y el marco decide cuándo se usan. Es lo que distingue un marco de una
librería.
🔬 Fowler lo describe en su bliki como la característica que define a un *framework*. La inyección de
dependencias es una forma particular de inversión de control, aplicada a quién crea los colaboradores.

**06 → 2. ¿Qué hace un contenedor de inyección, en cuatro verbos? 🟢**

⏱️ Registra qué clases hay y cómo crearlas, resuelve el grafo creando primero lo que cada constructor pide,
gestiona cuántas instancias hay de cada una (los *scopes*) y cierra los objetos en orden al apagar.
🗣️ Es una raíz de composición automática. Lo que en un `main` se escribe a mano —el orden de creación, quién
recibe qué, cerrar la fuente de datos— el contenedor lo deduce de las anotaciones o de los métodos `@Bean`.
🔬 Spring añade encima configuración externa, perfiles, AOP con proxies y eventos. Pero los cuatro verbos
son el núcleo, y caben en una clase de veinte líneas con un mapa de fábricas.

**06 → 3. ¿Qué es un Service Locator? 🟢**

⏱️ Un registro global al que cada clase le pide sus dependencias por tipo o por nombre:
`LocalizadorServicios.obtener(RepositorioCuentas.class)`.
🗣️ Desacopla de la implementación concreta, como la inyección, pero las dependencias desaparecen de la
firma: hay que leer el cuerpo de la clase para saber qué necesita, y los tests tienen que llenar el registro
global antes de cada prueba.
🔬 Fowler lo presenta como alternativa válida en su artículo de 2004; Seemann lo cataloga como antipatrón en
su libro de 2019. Es, en esencia, un Singleton con un mapa dentro.

**06 → 4. ¿Qué *scopes* tiene Spring, y cuál es el de por defecto? 🟢**

⏱️ `singleton` por defecto, una instancia por contenedor y definición; `prototype`, una nueva cada vez; y en
aplicaciones web `request`, `session` y `application`.
🗣️ Casi todo lo que se escribe —servicios, repositorios— es `singleton` y por eso tiene que ser seguro entre
hilos y sin estado de petición. Lo que depende del usuario o de la petición va en `request` o se pasa como
parámetro.
🔬 Spring permite además `websocket` y *scopes* propios. Un `prototype` no se destruye: el contenedor lo
crea y se olvida de él, así que sus métodos de cierre no se llaman.

**06 → 5. ¿Qué diferencia hay entre IoC, inyección de dependencias y contenedor? 🟡**

⏱️ IoC es un principio (el marco te llama); la inyección de dependencias es una técnica (el objeto recibe sus
colaboradores); el contenedor es una herramienta que aplica la técnica automáticamente.
🗣️ Puede haber IoC sin inyección (JUnit), inyección sin contenedor (una raíz de composición en `main`) y
contenedor usado sin inyección (un `getBean` en medio de un servicio, que es un Service Locator).
🔬 Spring se llama a sí mismo "contenedor de IoC", y por eso se mezclan. En una entrevista, separar los tres
en una frase es lo que se espera.

**06 → 6. ¿Qué diferencia hay entre inyección de dependencias e inversión de dependencias? 🟡**

⏱️ La inyección es cómo llega la dependencia (desde fuera, por constructor); la inversión es hacia dónde
apunta (hacia una abstracción que define el módulo de política).
🗣️ Se puede inyectar una clase concreta (`new Servicio(new RepositorioJdbc())`): hay inyección y no hay
inversión. Y se puede depender de una interfaz pero obtener la implementación con un localizador: hay
inversión y no hay inyección. Lo habitual y lo bueno es tener las dos.
🔬 DIP es la "D" de SOLID; DI es una técnica de construcción. Ver `03/04 → 8`.

**06 → 7. ¿Qué diferencia hay entre un contenedor y un Service Locator? 🟡**

⏱️ Con un contenedor, la clase recibe sus dependencias y no sabe que el contenedor existe; con un Service
Locator, la clase pide sus dependencias a un registro que conoce.
🗣️ La diferencia está en la clase, no en la herramienta: Spring es un contenedor, pero un servicio que hace
`ctx.getBean(...)` lo usa como localizador. La prueba es si la clase se puede crear con `new` y sus
dependencias en un test, sin nada más.
🔬 Hay usos legítimos de un localizador en la raíz de composición o en código de infraestructura (resolver
un *handler* por tipo de mensaje); el problema es usarlo en las clases de negocio.

**06 → 8. ¿Qué diferencia hay entre la raíz de composición en C++ y un contenedor en Java? 🟡**

⏱️ En C++ la raíz se escribe a mano y además decide la propiedad: quién vive en `main` y quién recibe
referencias. El contenedor de Java deduce el grafo por reflexión y deja la memoria al recolector.
🗣️ En C++ el *scope* por petición es una variable local de la función que atiende, y el cierre ordenado lo
dan los destructores en orden inverso. En Java hacen falta anotaciones de *scope* y métodos de cierre.
🔬 C++ no tiene reflexión en tiempo de ejecución, que es en lo que se apoyan Spring o Guice; las librerías de
inyección de C++ resuelven el grafo con plantillas, en compilación, y se usan poco.

**06 → 9. ¿Por qué la inyección por constructor es la recomendada? 🟠**

⏱️ Porque deja las dependencias en la firma, permite que los campos sean `final`, garantiza que el objeto
nace completo y se puede crear con `new` en un test.
🗣️ La documentación de Spring lo dice: permite objetos inmutables y asegura que las dependencias
obligatorias no sean nulas. Y un constructor demasiado largo es una señal útil: la clase tiene demasiadas
responsabilidades.
🔬 Con un solo constructor, Spring lo usa sin `@Autowired`, así que la clase no depende del contenedor en
absoluto salvo la anotación de registro.

**06 → 10. ¿Por qué la inyección por campo es peor, si funciona igual? 🟠**

⏱️ Porque las dependencias desaparecen de la firma, los campos no pueden ser `final`, y el objeto no se puede
crear correctamente sin el contenedor o sin reflexión.
🗣️ Un test unitario tiene que levantar Spring o usar herramientas que escriben campos privados por
reflexión. Y una clase con quince `@Autowired` en campos no protesta: el olor del constructor de quince
parámetros queda escondido.
🔬 "Funciona igual" en producción, con el contenedor arrancado. La diferencia está en todo lo demás: pruebas,
inmutabilidad, legibilidad y la posibilidad de usar la clase fuera de Spring.

**06 → 11. ¿Qué pasa si inyectas un bean de *scope* `request` en uno `singleton`, y cómo lo resuelves? 🟠**

⏱️ El singleton se crea una vez y recibe una sola instancia del bean de petición, así que todas las
peticiones compartirían la misma; Spring, de hecho, falla al arrancar si no hay petición activa. Se resuelve
con un proxy de *scope* o pidiendo el bean a un `ObjectProvider` en cada uso.
🗣️ El proxy de *scope* (`proxyMode = ScopedProxyMode.TARGET_CLASS`, o las anotaciones `@RequestScope`, que
lo traen) inyecta un objeto intermedio que en cada llamada busca la instancia de la petición actual. Con
`ObjectProvider<T>`, el singleton llama a `getObject()` cuando lo necesita.
🔬 A menudo la mejor solución es no tener ese bean: pasar el dato de la petición (el usuario) como parámetro
del método en lugar de inyectarlo. En .NET el mismo error se detecta al arrancar en desarrollo.

**06 → 12. ¿Cuándo no usarías un contenedor? 🟠**

⏱️ En aplicaciones pequeñas, en librerías y para los objetos del dominio.
🗣️ Diez objetos se conectan en un `main` legible. Una librería no debe exigir un contenedor a quien la usa:
expone constructores. Y las entidades y objetos de valor se crean con `new`, por miles, sin dependencias de
infraestructura.
🔬 También cuando el arranque importa (funciones *serverless*, herramientas de línea de comandos): ahí, o raíz
a mano, o inyección en compilación como Dagger.

**06 → 13. ¿Qué indica un ciclo de dependencias entre constructores, y qué haces? 🟠**

⏱️ Casi siempre una responsabilidad mal repartida: A necesita algo de B y B algo de A, y ese algo debería ser
una tercera clase de la que dependan las dos.
🗣️ Spring lo detecta al arrancar con `BeanCurrentlyInCreationException`, y su documentación sugiere pasar
alguna dependencia a *setter*. Eso lo hace arrancar, pero conserva el ciclo. Lo bueno es extraer lo
compartido o invertir una de las dependencias con un evento.
🔬 Con inyección por campo el ciclo no da error en muchos casos, y por eso pasa desapercibido: es otra razón
para preferir constructores.

**06 → 14. Reescribe este servicio para que no use el contenedor como localizador: `@Service class RegistroPersonas { @Autowired ApplicationContext ctx; void registrar(Persona p) { ctx.getBean(RepositorioPersonas.class).guardar(p); } }`. 🔴**

⏱️ El repositorio entra por constructor como campo `final`, y el `ApplicationContext` desaparece de la clase.
🗣️

```java
@Service
class RegistroPersonas {
    private final RepositorioPersonas personas;

    RegistroPersonas(RepositorioPersonas personas) { this.personas = personas; }

    void registrar(Persona p) { personas.guardar(p); }
}
```

La dependencia queda en la firma, la clase no importa nada de Spring salvo `@Service`, y se prueba con un
repositorio en memoria.
🔬 Lo que preguntará después: si hay casos en que `getBean` está justificado (en código de infraestructura que
resuelve dinámicamente por tipo, como un despachador de mensajes; nunca en negocio); y qué hacer si el
repositorio solo se necesita a veces (`ObjectProvider<RepositorioPersonas>`, que sigue en la firma).

**06 → 15. Escribe un test de `ServicioTransferencias` sin levantar Spring, y di qué lo hace posible. 🔴**

⏱️ Se crea el servicio con `new`, pasándole un repositorio en memoria, un `Clock.fixed` y una auditoría
falsa. Lo hace posible la inyección por constructor: la clase no sabe que existe un contenedor.
🗣️

```java
@Test
void noTransfiereDespuesDeLas22() {
    var reloj = Clock.fixed(Instant.parse("2026-10-03T03:30:00Z"), ZoneId.of("America/Bogota")); // 22:30 en Bogotá
    var cuentas = new RepositorioCuentasEnMemoria(cuentaDeAna(), cuentaDeLuis());
    var servicio = new ServicioTransferencias(cuentas, reloj, new AuditoriaFalsa());

    assertThrows(FueraDeHorarioException.class, () -> servicio.transferir(
            new CuentaId("CTA-0001"), new CuentaId("CTA-0003"), Dinero.cop("250000.00")));
}
```

Con inyección por campo haría falta levantar el contexto de Spring o escribir campos privados por reflexión.
🔬 Lo que preguntará después: si no conviene un test con Spring también (sí, pocos, para comprobar que el
grafo arranca y la configuración es correcta; las reglas de negocio se prueban sin él); y por qué el reloj
lleva zona (porque "las 22:00" es una hora local del banco).

**06 → 16. Un compañero tiene un constructor de once parámetros inyectados y propone pasar a inyección por campo "para que se lea mejor". ¿Qué le respondes? 🔴**

⏱️ Que el problema no es el constructor sino la clase: once dependencias son once motivos de cambio. Pasar a
campos esconde el síntoma y deja el problema.
🗣️ Propondría mirar qué métodos usan qué dependencias: casi siempre aparecen dos o tres grupos que son
clases distintas. Partirla deja varios constructores de tres o cuatro parámetros. La documentación de Spring
lo dice en la misma página que recomienda constructores: muchos argumentos son un mal olor.
🔬 Lo que preguntará después: si un objeto de parámetros (agrupar las once en una clase) lo arregla (no: es la
misma clase con un paso más); y qué haces si no hay tiempo de partirla (dejar el constructor como está, que
al menos es honesto, y abrir la tarea).

# 07 — Más allá del GoF

**07 → 1. ¿Qué es RAII? 🟢**

⏱️ Atar la vida de un recurso a la de un objeto: el constructor lo adquiere y el destructor lo libera. Como el
destructor corre siempre al salir del ámbito, también con excepciones, el recurso no se puede olvidar.
🗣️ `std::lock_guard` toma el cerrojo al crearse y lo suelta al destruirse; una `TransaccionBd` propia hace
*rollback* en su destructor si nadie la confirmó. El código que la usa no tiene un solo `unlock` ni un solo
`rollback`.
🔬 La sigla, *Resource Acquisition Is Initialization*, describe la mitad menos importante; la que da el valor
es "la liberación es la destrucción". Stroustrup la usa desde los primeros C++.

**07 → 2. ¿Qué es un Object Pool? 🟢**

⏱️ Un conjunto de objetos ya creados que se toman prestados y se devuelven, en lugar de crearlos y destruirlos
en cada uso. Sirve para objetos caros de crear y escasos.
🗣️ El caso canónico es el pool de conexiones: abrir una cuesta TCP, TLS y autenticación, así que el pool
mantiene unas cuantas abiertas. En Java se configura (HikariCP detrás de un `DataSource`) y `close()` devuelve
la conexión en lugar de cerrarla.
🔬 El pool decide el mínimo, el máximo y qué hacer cuando no queda ninguna: esperar con un tiempo límite,
fallar o crear una más. El agotamiento del pool es un síntoma clásico de fugas.

**07 → 3. ¿Qué es la inicialización perezosa? 🟢**

⏱️ Crear un objeto la primera vez que se pide y guardarlo para las siguientes, en lugar de crearlo al
construir su dueño.
🗣️ Sirve cuando el objeto es caro y muchas ejecuciones no lo usan, como un catálogo de plantillas que la
importación nocturna nunca toca. La dificultad está en la concurrencia: que dos hilos no lo creen dos veces
ni vean uno a medias.
🔬 Las formas seguras: el holder para estáticos en Java, un `Supplier` memoizado con `volatile` para campos,
la estática local y `std::call_once` en C++. En Java 25, `StableValue` en *preview*.

**07 → 4. ¿Qué es un Multiton, y qué ejemplo tiene el JDK? 🟢**

⏱️ Un Singleton por clave: una sola instancia para cada valor de la clave. El JDK lo usa en `Currency`, que
garantiza una instancia por moneda.
🗣️ `Currency.getInstance("COP") == Currency.getInstance("COP")` es `true`, y la clase no tiene constructor
público. Un `enum` de Java es un Multiton con un conjunto de claves cerrado.
🔬 El GoF no lo nombra como patrón; lo menciona al decir que el Singleton puede controlar un número variable de
instancias. Es nivel C: se reconoce y casi nunca se escribe.

**07 → 5. ¿Qué hace `std::scoped_lock` que no hace `std::lock_guard`? 🟢**

⏱️ Toma varios cerrojos a la vez con un algoritmo que evita el interbloqueo; `lock_guard` toma uno solo.
🗣️ En una transferencia hay que bloquear las dos cuentas. Con dos `lock_guard`, una transferencia de Ana a
Luis y otra de Luis a Ana pueden tomar cada una su primer cerrojo y esperar para siempre el segundo.
`std::scoped_lock cerrojos{origen.cerrojo(), destino.cerrojo()}` los toma juntos sin ese riesgo.
🔬 Es de C++17. Por dentro usa `std::lock`, que evita el interbloqueo probando y soltando. Con un solo cerrojo,
`scoped_lock` y `lock_guard` son equivalentes.

**07 → 6. ¿Qué diferencia hay entre RAII en C++ y `try-with-resources` en Java? 🟡**

⏱️ En C++ el objeto se libera solo al salir de su ámbito, lo use quien lo use; en Java la liberación depende
de que quien usa el objeto escriba el `try`. RAII ata la liberación al objeto; `try-with-resources`, a un
bloque.
🗣️ Por eso en Java un recurso guardado en un campo no cabe en un `try`: su dueño tiene que ser `AutoCloseable`
y alguien más arriba lo cierra. En C++, el destructor del dueño destruye sus miembros en cadena sin escribir
nada.
🔬 `try-with-resources` cierra en orden inverso y guarda las excepciones de `close()` como suprimidas de la
principal; en C++, un destructor que lanza durante otra excepción termina el programa. Ver `01/04` §7.

**07 → 7. ¿Qué diferencia hay entre RAII y `Cleaner`? 🟡**

⏱️ RAII libera en un momento determinado, al salir del ámbito; `Cleaner` libera cuando el recolector reclama
el objeto, que puede ser tarde o nunca.
🗣️ `Cleaner` es una red de seguridad para el caso en que alguien olvidó cerrar: el recurso no queda filtrado
para siempre, pero sí durante un tiempo que nadie controla. Lo que cierra de verdad es `close()` llamado por un
`try-with-resources`.
🔬 Bloch, ítem 8: evitar *finalizers* y *cleaners* salvo como red de seguridad o para recursos nativos sin
importancia crítica. `finalize` está deprecado para eliminación.

**07 → 8. ¿Qué diferencia hay entre un Multiton y un `enum`? 🟡**

⏱️ El `enum` es un Multiton con claves cerradas y conocidas al compilar, y con las garantías de la JVM; el
Multiton clásico es un mapa estático de clave a instancia, con claves abiertas.
🗣️ El `enum` no necesita mapa, ni sincronización, ni defensa contra reflexión o serialización. El Multiton con
mapa sí, y además es estado global por clave, con los problemas del Singleton.
🔬 Para claves abiertas, la alternativa moderna no es el Multiton sino un registro normal, creado en la raíz
de composición e inyectado.

**07 → 9. ¿Qué diferencia hay entre un holder y un `Supplier` memoizado para inicializar algo perezosamente? 🟡**

⏱️ El holder sirve para un estático: la JVM inicializa la clase portadora una vez. El `Supplier` memoizado sirve
para un campo de instancia, donde no hay clase que inicializar, y necesita `volatile` y un doble chequeo.
🗣️ El holder no tiene costo después de la primera llamada y no se puede escribir mal. El `Supplier` paga una
lectura `volatile` por acceso y es fácil de escribir mal si falta el `volatile` o la segunda comprobación.
🔬 Por eso conviene escribir el `Supplier` una vez, como clase genérica, y no repetir el doble chequeo en cada
sitio. El mecanismo es de [`10/06`](../10-concurrencia/06-inicializacion-perezosa-segura.md).

**07 → 10. ¿Por qué "RAII es solo para memoria" es falso? 🟠**

⏱️ Porque RAII sirve para cualquier recurso que haya que soltar: cerrojos, archivos, transacciones,
conexiones, hilos. La memoria es solo el ejemplo más famoso.
🗣️ De hecho es el menos interesante, porque es el único que un recolector de basura ya gestiona. Lo que RAII da
y un recolector no es el **momento**: el cerrojo se suelta al salir de la función, no cuando haga falta memoria.
🔬 En C++ la librería estándar lo aplica en todas partes: `lock_guard`, `scoped_lock`, `fstream`, `jthread`,
`unique_ptr`. En Java, todo lo que implementa `AutoCloseable` es una aproximación.

**07 → 11. ¿Por qué no se deben agrupar en un pool los hilos virtuales? 🟠**

⏱️ Porque son baratos y abundantes: la razón del pool —que crear un hilo es caro— no existe. La JEP 444 dice
que se cree uno nuevo por tarea.
🗣️ Un pool de hilos de plataforma servía también para limitar cuántas tareas corren a la vez. Con hilos
virtuales, ese límite se pone donde está el recurso escaso: un semáforo, o el tamaño del pool de conexiones.
🔬 Además, un hilo virtual está pensado para una sola tarea en su vida; reutilizarlo arrastra estado de
`ThreadLocal` de una tarea a otra, que es justo lo que se quiere evitar.

**07 → 12. ¿Cuándo un Object Pool empeora el rendimiento? 🟠**

⏱️ Cuando el objeto es barato de crear: el pool añade sincronización al tomar y devolver, estado que hay que
limpiar al devolver y fugas posibles, a cambio de nada.
🗣️ En la JVM una asignación pequeña es casi gratis y el recolector de generaciones está optimizado para objetos
de vida corta. Un pool de objetos pequeños los mantiene vivos más tiempo, los promociona a la generación vieja
y empeora el trabajo del recolector.
🔬 Los pools de objetos tenían sentido con recolectores antiguos o en C++ con asignadores lentos; hoy, fuera de
conexiones, hilos de plataforma y *buffers* grandes, se miden antes de escribirse.

**07 → 13. ¿Por qué Bloch desaconseja la inicialización perezosa por defecto? 🟠**

⏱️ Porque en la mayoría de los casos la inicialización normal es preferible: más simple, sin riesgos de
concurrencia, y con los errores al arrancar en lugar de a mitad del trabajo.
🗣️ Lo perezoso mueve el costo a la primera petición, que es la que ve el usuario, y añade una comprobación a
cada acceso. Solo compensa si el objeto es caro y muchas ejecuciones no lo usan. Es el ítem 83 de *Effective
Java*.
🔬 Si se hace, Bloch da las formas: holder para estáticos, doble chequeo con `volatile` para campos de
instancia, y el chequeo simple si se tolera inicializar más de una vez.

**07 → 14. ¿Por qué un destructor de C++ no debe lanzar? 🟠**

⏱️ Porque los destructores corren también mientras se propaga una excepción, y si uno lanza en ese momento el
programa termina con `std::terminate`. Además, desde C++11 los destructores son `noexcept` por defecto.
🗣️ Un destructor RAII que hace *rollback* o cierra un archivo tiene que tragarse sus errores (registrarlos) o
ofrecer un método explícito (`cerrar()`) que sí lance, para quien quiera enterarse.
🔬 Las *C++ Core Guidelines* lo dicen en la sección de destructores: un destructor no debe fallar. En Java el
problema no existe igual: `try-with-resources` guarda la excepción de `close()` como suprimida.

**07 → 15. Escribe en Java una `TransaccionBd` que haga *rollback* si no se confirmó, y úsala en una transferencia. 🔴**

⏱️ Una clase `AutoCloseable` que desactiva el *autocommit* al crearse, confirma en `confirmar()` y en `close()`
hace *rollback* si no se confirmó; se usa en un `try-with-resources`.
🗣️

```java
public final class TransaccionBd implements AutoCloseable {
    private final Connection conexion;
    private boolean confirmada;

    public TransaccionBd(Connection c) throws SQLException { conexion = c; c.setAutoCommit(false); }
    public void confirmar() throws SQLException { conexion.commit(); confirmada = true; }
    @Override public void close() throws SQLException { if (!confirmada) conexion.rollback(); }
}

try (Connection c = fuenteDatos.getConnection();
     var tx = new TransaccionBd(c)) {
    cuentas.debitar(c, origen, monto);      // si lanza: rollback, y la conexión vuelve al pool
    cuentas.acreditar(c, destino, monto);
    tx.confirmar();
}
```

🔬 Lo que preguntará después: en qué orden se cierran (en orden inverso: primero la transacción, después la
conexión, que es lo correcto); y por qué no `@Transactional` (en Spring sería lo normal: es este mismo patrón
aplicado por un proxy, con su trampa de la llamada interna: ver
[`05/03` §6](../05-estructurales/03-proxy.md#6--autopsia-transactional-en-la-llamada-interna)).

**07 → 16. Revisa este código y di qué falla: `Connection c = fuenteDatos.getConnection(); c.prepareStatement(sql).executeUpdate(); c.close();`. 🔴**

⏱️ Si `executeUpdate` lanza, `close()` nunca se ejecuta y la conexión no vuelve al pool: es una fuga. Además
el `PreparedStatement` no se cierra nunca.
🗣️ Bajo carga, cada error filtra una conexión hasta que el pool se agota y todas las peticiones esperan. El
arreglo es `try-with-resources` sobre la conexión y la sentencia:

```java
try (Connection c = fuenteDatos.getConnection();
     PreparedStatement ps = c.prepareStatement(sql)) {
    ps.executeUpdate();
}
```

🔬 Lo que preguntará después: cómo se detecta en producción (los pools tienen detección de fugas que avisa
cuando una conexión lleva prestada más de un tiempo); y si el `Cleaner` del driver no la cerraría (quizás, cuando
pase el recolector, y para entonces el pool ya se agotó).

**07 → 17. Escribe en C++ el acceso perezoso a un miembro con `std::call_once`. 🔴**

⏱️ Un `std::once_flag` y un `std::optional` como miembros `mutable`, y un método que llama a `std::call_once`
con la carga antes de devolver la referencia.
🗣️

```cpp
class ServicioAvisos {
public:
    explicit ServicioAvisos(FuenteDatos& f) : fuente_{f} {}
    const CatalogoPlantillas& plantillas() const {
        std::call_once(cargadas_, [this] { plantillas_.emplace(CatalogoPlantillas::cargar(fuente_)); });
        return *plantillas_;
    }
private:
    FuenteDatos& fuente_;
    mutable std::once_flag cargadas_;
    mutable std::optional<CatalogoPlantillas> plantillas_;
};
```

🔬 Lo que preguntará después: qué pasa si la carga lanza (la excepción sale hacia quien llamó y el `once_flag`
no queda marcado, así que la próxima llamada reintenta); y por qué `mutable` (porque cargar perezosamente no
cambia el estado observable del servicio, y el método puede seguir siendo `const`).

**07 → 18. Un compañero propone un pool de objetos `Movimiento` "para no crear tanta basura". Revísalo. 🔴**

⏱️ No lo haría: `Movimiento` es barato de crear y de vida corta, que es justo para lo que está optimizado el
recolector. Un pool añadiría sincronización, estado mutable y fugas, y probablemente empeoraría el rendimiento.
🗣️ Además, `Movimiento` debería ser inmutable; un objeto que se devuelve al pool y se reutiliza tiene que ser
mutable y limpiarse, y un movimiento reutilizado con datos del anterior es un bug contable. Si hay un problema
de memoria, primero se mide con un perfilador.
🔬 Lo que preguntará después: qué medirías (tasa de asignación, pausas del recolector, objetos promocionados a
la generación vieja); y cuándo sí aceptarías un pool (conexiones, hilos de plataforma, *buffers* grandes de
E/S).

# 08 — Simulación de entrevista

Las `S#` que ya son preguntas de capítulo remiten a su respuesta; las demás, en tres capas. Los
ejercicios, desarrollados al final.

**08 → S1. ¿Qué diferencia hay entre el Factory Method del GoF y una fábrica estática? 🟡**

Ver `01 → 5`.

**08 → S2. ¿Por qué `Iterable.iterator()` es un Factory Method del GoF? 🟠**

Ver `01 → 9`.

**08 → S3. ¿Cuándo un `switch` por código de tipo se convierte en un registro de fábricas, y cuándo en datos? 🟠**

Ver `01 → 10` y `01 → 11`.

**08 → S4. ¿Qué diferencia hay entre Abstract Factory y Factory Method? 🟡**

Ver `01 → 6` y `02 → 4`.

**08 → S5. ¿Qué gana una fábrica estática sobre un constructor, y qué pierde? 🟡**

Ver `01 → 2` y `01 → 12`.

**08 → S6. Nombra tres fábricas estáticas del JDK y di qué ventaja aprovecha cada una. 🟢**

⏱️ `Integer.valueOf`, que no crea si el valor está en la caché; `List.of`, que devuelve una clase interna que
no es pública; y `EnumSet.noneOf`, que elige la implementación según el tamaño del `enum`.
🗣️ Son tres de las cuatro ventajas de Bloch: no obligar a crear, poder devolver un subtipo oculto y poder
variar la clase según el argumento. La cuarta, el nombre, la tienen todas: `List.of` dice más que
`new ImmutableCollections.ListN(...)`.
🔬 Otras que valen: `Optional.of`, `LocalDate.of`, `Path.of`, `Charset.forName`. Ver `01 → 2`.

**08 → S7. ¿Qué diferencia hay entre el Builder del GoF y el de Bloch? 🟡**

Ver `03 → 5`.

**08 → S8. ¿Por qué "con records ya no hace falta Builder" es falso? 🟠**

Ver `03 → 10`.

**08 → S9. ¿Dónde se valida en un builder, y qué pasa si no se valida? 🟠**

Ver `03 → 11` y `03 → 16`.

**08 → S10. ¿Qué es Prototype, y por qué no es `clone()`? 🟡**

Ver `04 → 1` y `04 → 4`.

**08 → S11. ¿Por qué un objeto inmutable no necesita Prototype ni constructor de copia? 🟠**

Ver `04 → 8`.

**08 → S12. Escribe un Singleton seguro entre hilos en Java, en la forma que prefieras, y di por qué es seguro. 🟡**

Ver `05 → 2` y `05 → 15`.

**08 → S13. ¿Qué diferencia hay entre el Singleton del GoF y el bean singleton de Spring? 🟡**

Ver `05 → 5`.

**08 → S14. ¿Por qué el Singleton dificulta las pruebas? 🟠**

Ver `05 → 13`.

**08 → S15. ¿Qué diferencia hay entre un contenedor de inyección y un Service Locator? 🟡**

Ver `06 → 7`.

**08 → S16. ¿Por qué la inyección por constructor es la recomendada? 🟠**

Ver `06 → 9`.

**08 → S17. ¿Qué diferencia hay entre IoC, inyección de dependencias y contenedor? 🟡**

Ver `06 → 5`.

**08 → S18. ¿Qué hace un contenedor que una raíz de composición a mano no hace? 🟡**

Ver `06 → 2` y `06 → 8`.

**08 → S19. ¿Qué es RAII, y por qué no es solo para memoria? 🟢**

Ver `07 → 1` y `07 → 10`.

**08 → S20. ¿Cuándo un pool mejora el rendimiento y cuándo lo empeora? 🟠**

Ver `07 → 2` y `07 → 12`.

**08 → S21. ¿Cuándo inicializarías algo de forma perezosa? 🟠**

Ver `07 → 3` y `07 → 13`.

**08 → S22. ¿Qué tienen en común RAII y un pool de conexiones? 🟠**

⏱️ Que el préstamo de una conexión es un recurso, y RAII es lo que garantiza que se devuelva. Un pool sin RAII
alrededor filtra conexiones en cuanto algo lanza.
🗣️ En Java, `try (Connection c = fuenteDatos.getConnection())` hace que `close()` —que en un pool devuelve,
no cierra— corra en todos los caminos. En C++, un `unique_ptr` con un borrador que devuelve al pool hace lo
mismo sin `try`.
🔬 La fuga de conexiones se ve como un pool agotado bajo carga, y casi siempre es un `getConnection()` fuera de
un `try-with-resources`. Ver `07 → 16`.

**08 → S23. ¿Qué cambia en las fábricas de C++ moderno respecto de C++98? 🟡**

Ver `01 → 8` y `01 → 13`.

**08 → S24. ¿Cómo se resuelven los argumentos con nombre en C++20, en Java y en C#? 🟡**

⏱️ En C++20, con un agregado y *designated initializers*; en Java, con un builder, porque el lenguaje no los
tiene; en C#, con argumentos con nombre y opcionales en la propia llamada, o con inicializadores de objeto.
🗣️ El agregado de C++ exige campos públicos y el orden de declaración, y la validación va en el constructor
de la clase que lo recibe. El builder de Java es código que se mantiene. C# lo trae en el lenguaje, y por eso
el builder es menos frecuente allí.
🔬 Ver `03 → 8`. Python y Kotlin también tienen argumentos con nombre; en Go, el lugar lo ocupan las
*functional options*.

**08 → S25. ¿Por qué en C++ el Singleton no necesita `mutex` y en Java el DCL necesita `volatile`? 🟠**

⏱️ Porque en C++11 el estándar garantiza que una estática local se inicializa una sola vez entre hilos, y el
compilador pone la sincronización; el DCL de Java lee el campo fuera del cerrojo, y sin `volatile` esa lectura
no tiene garantía de ver el objeto completo.
🗣️ Son mecanismos distintos para el mismo problema. En Java el equivalente al Meyers singleton es el holder,
que tampoco necesita `volatile` porque se apoya en la inicialización de clases. El DCL solo hace falta cuando
no hay ni estática local ni clase que inicializar.
🔬 Ver `05 → 3`, `05 → 11` y `05 → 15`. La implementación habitual de la estática local en C++ es, por
dentro, un doble chequeo que escribe el compilador.

**08 → S26. "En mi equipo todas las clases tienen su `Factory`, por si mañana cambia la implementación." ¿Qué le dices? 🔴**

⏱️ Que una fábrica que solo llama al constructor no compra nada: si mañana cambia la implementación, cambiar
un `new` cuesta lo mismo que cambiar una fábrica, y hoy se paga una clase más por cada clase.
🗣️ Preguntaría qué cambio concreto esperan y dónde. Lo que se sustituye en los tests son las dependencias
volátiles (repositorios, relojes, clientes HTTP), y eso se resuelve con inyección por constructor, no con
fábricas. Una fábrica se justifica con nombre, caché, subtipo oculto o lógica de creación; si no tiene
ninguna, es generalización especulativa.
🔬 Sin entrar en guerra: proponer quitar las fábricas vacías de un módulo, medir que nada se rompe y que el
código baja, y dejar las que sí hacen algo. Ver `01 → 15`.

**08 → S27. "¿Para qué inyectar el catálogo si con un Singleton lo tengo en una línea?" 🔴**

⏱️ Porque esa línea esconde una dependencia: cualquier clase que la usa necesita la base de datos para
probarse, y nadie sabe qué clases dependen del catálogo sin buscar la llamada en todo el código.
🗣️ Con inyección sigue habiendo un solo catálogo —lo crea la raíz de composición o el contenedor—, pero cada
clase lo declara en su constructor y el test le pasa uno con dos tipos escritos a mano. La línea de más está
en el constructor, y es información.
🔬 El argumento que convence suele ser el test: escribir juntos el de una clase que usa el Singleton y el de
la que lo recibe. Ver `05 → 13` y `05 → 16`.

**08 → S28. El entrevistador te pide un Singleton "a prueba de todo". ¿Qué escribes y qué le preguntas? 🔴**

⏱️ Escribo el `enum` de un elemento, que es seguro entre hilos y resiste reflexión y serialización. Y pregunto
para qué lo necesita, porque casi siempre lo que hace falta es una instancia que cree el contenedor.
🗣️ El "todo" tiene un límite que conviene decir: ni el enum resiste dos *classloaders*, que cargan dos clases
distintas con una instancia cada una. Y si la clase tiene que extender otra, el holder con `readResolve` y una
comprobación en el constructor.
🔬 La pregunta de vuelta es la que suma: "¿la unicidad es una regla del dominio o una comodidad de acceso?".
Ver `05 → 4` y `05 → 12`.

**08 → S29. "Los patrones creacionales sobran en un lenguaje con Spring." ¿Estás de acuerdo? 🔴**

⏱️ En parte. Spring absorbe el Singleton y la mayoría de las fábricas de servicios, pero no los objetos del
dominio: un `Documento` con reglas de creación, una `Persona` con muchos opcionales o una transacción que hay
que soltar no son beans.
🗣️ Spring resuelve el grafo de servicios. Las fábricas estáticas, el builder, el registro por código y RAII
siguen apareciendo dentro de ese grafo, y Spring mismo los usa: `FactoryBean`, `UriComponentsBuilder`,
`TransactionTemplate`.
🔬 Lo que sobra con Spring es el Singleton escrito a mano y el Service Locator. Ver `05 → 5` y `06 → 12`.

**08 → S30. "¿Usarías Abstract Factory aquí?" sobre un sistema con un solo país. ¿Qué respondes? 🔴**

⏱️ No: con una sola familia, son tres tipos más para elegir entre una opción. Escribiría las clases concretas y
extraería la fábrica cuando llegue el segundo país.
🗣️ La refactorización es mecánica: extraer las interfaces de producto y la de fábrica, y crear la fábrica del
país existente. El IDE la hace en minutos. Lo caro sería mantener desde hoy una abstracción cuyo segundo uso no
conocemos.
🔬 Si el entrevistador insiste en que el segundo país es seguro, la respuesta cambia: con dos familias reales y
piezas que no se deben mezclar, sí. Ver `02 → 9`.

**08 → S31. "Lombok `@Builder` y listo, ¿no?" 🔴**

⏱️ Depende de dónde se ponga. En la clase, genera un builder que construye por un constructor sin validar
nada, y entrega objetos inválidos. En el constructor que valida, sí sirve.
🗣️ El valor del builder está en que `build()` no deje salir un objeto inválido. Lombok ahorra escribir el
builder, no pensar los invariantes. Además, los campos no asignados quedan en `null` y los obligatorios no se
distinguen de los opcionales.
🔬 Ver `03 → 12` y el ejercicio E3 de esta simulación.

**08 → S32. Te piden nombrar los cinco creacionales del GoF y uno que no esté en el libro. ¿Qué añades para que la respuesta no sea una lista? 🔴**

⏱️ Factory Method, Abstract Factory, Builder, Prototype y Singleton; y fuera del libro, RAII. Y añado para qué
uso cada uno hoy y cuál casi nunca escribo.
🗣️ Por ejemplo: la fábrica estática es lo que más escribo en Java, y no es el Factory Method del GoF; el Builder
que uso es el de Bloch; Prototype en C++ para copiar polimórficos; el Singleton se lo dejo al contenedor; y RAII
es para todo recurso que no sea memoria.
🔬 La lista sola demuestra memoria; el criterio sobre cuándo no usarlos es lo que se evalúa.

---

**08 → E1. Documentos de varios países.**

**Enunciado.** Aceptar documentos de Perú y Chile además de Colombia y México: formato de número por país,
vencimiento de la TI a los 18 años del titular, y número mostrado a la manera de cada país.

**El primer diseño que sale.** Una subclase de `Documento` por país y tipo (`CedulaColombia`,
`PasaporteMexico`, `DniPeru`…), cada una con su `validar()` y su `formatear()`.

**El bueno.** Separar lo que es dato de lo que es lógica:

- **Formato y si vence** son datos de `TipoDocumento` (Type Object): `\d{8}` para el DNI de Perú es una fila en
  el catálogo, no una clase.
- **La regla de vencimiento** que no cabe en un dato (la TI a los 18 años) va en un **registro de fábricas** por
  código, con una entrada por tipo que tenga regla propia y una por defecto.
- **Validador y formateador** del país van juntos: si de verdad difieren en lógica, un **Abstract Factory** por
  país elegido en un mapa; si solo difiere el separador, un dato más de `Pais`.

```java
public final class TipoDocumento {                     // datos: formato, si vence
    public boolean admite(String numero) { return formato.matcher(numero).matches(); }
}

Map<String, FabricaDocumento> fabricas;                // lógica de creación por código, cuando la hay
Map<Pais, FabricaDocumentosPais> porPais;             // validador + formateador, solo si difieren en lógica

public Documento crear(Solicitud s) {
    var f = fabricas.getOrDefault(s.codigoTipo(), FabricaDocumento.porDefecto());
    return f.crear(s);
}
```

**Lo que cuesta.** Tres mecanismos en lugar de uno, cada uno justificado por un tipo de variación distinto. Si el
formateo resulta ser solo un separador, el Abstract Factory desaparece y quedan dos.

**Lo que preguntará después.** Cómo se añade un país sin desplegar (si todo lo que varía es dato, con una fila en
el catálogo; si hay lógica, con código); y cómo se prueba que cada código del catálogo tiene fábrica o usa la de
por defecto (un test que recorre el catálogo).

**08 → E2. El catálogo global.**

**Enunciado.** Reemplazar el Singleton `CatalogoTipos`, usado en cuarenta sitios, por inyección, en pasos
desplegables por separado.

**El primer diseño que sale.** Borrar `getInstance()` y arreglar los cuarenta sitios en un solo cambio enorme.

**El bueno.** Por pasos, cada uno desplegable:

1. **Hacer la clase normal**: constructor público (o fábrica `cargar`) que recibe la fuente de datos, y
   `getInstance()` que delega en una instancia creada así. Nada cambia para los usuarios.
2. **Crear el catálogo en la raíz de composición** (o como bean) y hacer que `getInstance()` devuelva **esa**
   instancia. Sigue habiendo una.
3. **Migrar los usuarios uno a uno**: cada clase recibe `CatalogoTipos` por constructor. Las de dominio, mejor
   aún, reciben el `TipoDocumento` ya resuelto y no necesitan catálogo.
4. **Borrar `getInstance()`** cuando no quede nadie que lo llame.

```java
public final class CatalogoTipos {
    private final Map<String, TipoDocumento> porCodigo;
    public static CatalogoTipos cargar(FuenteDatos f) { return new CatalogoTipos(leerTipos(f)); }
    public static CatalogoTipos de(Collection<TipoDocumento> tipos) { return new CatalogoTipos(tipos); }   // para tests
    private CatalogoTipos(Collection<TipoDocumento> tipos) { /* ... */ }
    public TipoDocumento deCodigo(String c) { return porCodigo.get(c); }
}
```

**Lo que cuesta.** Un periodo con las dos formas conviviendo, y la disciplina de no añadir nuevos usos de
`getInstance()` mientras dura (un test de arquitectura o una regla del analizador lo impide).

**Lo que preguntará después.** Si el `synchronized` de `getInstance` era un problema (correcto, pero sincroniza cada
llamada; desaparece con el paso 4); y qué hacer si el catálogo tiene que recargarse en caliente (entonces es
estado mutable compartido: o un objeto inmutable que se reemplaza entero de forma atómica, o un evento que avisa a
quien cachea tipos).

**08 → E3. El builder que deja pasar menores sin tutor.**

**Enunciado.** Revisar una `Persona` con `@Builder` de Lombok en la clase, y una construcción de Luis sin fecha de
nacimiento ni tutor.

**El primer diseño que sale.** Añadir `@NonNull` de Lombok a `nombre` y dar el resto por bueno.

**El bueno.** Los defectos, por gravedad:

1. **`build()` no valida nada**: `@Builder` en la clase construye por un constructor con todos los campos sin
   comprobar. Luis sale sin tutor, y el invariante "un menor tiene tutor" no tiene dueño.
2. **Los obligatorios no se distinguen**: Luis sale sin fecha de nacimiento, y nada lo impide.
3. **Los campos no son `final`**: `@Getter` sin `@Setter` no los hace inmutables por diseño, solo por omisión.

```java
public final class Persona {
    private final String nombre;
    private final LocalDate fechaNacimiento;
    private final Persona tutor;
    private final String email;

    @Builder
    private Persona(String nombre, LocalDate fechaNacimiento, Persona tutor, String email, LocalDate hoy) {
        this.nombre = Objects.requireNonNull(nombre, "nombre");
        this.fechaNacimiento = Objects.requireNonNull(fechaNacimiento, "fechaNacimiento");
        if (fechaNacimiento.plusYears(18).isAfter(hoy) && tutor == null)
            throw new IllegalArgumentException("un menor necesita tutor");
        this.tutor = tutor;
        this.email = email;
    }
}
```

`@Builder` puesto en el constructor que valida: `build()` pasa por la validación. `hoy` entra como un argumento
más del builder, para poder probar la regla.

**Lo que cuesta.** Pasar `hoy` en cada construcción, y una excepción en lugar de un objeto inválido. A cambio, ningún
camino de construcción salta la regla.

**Lo que preguntará después.** Si no sería mejor el builder escrito a mano con los obligatorios en la entrada (sí,
cuando se quiere que el compilador obligue a pasarlos; Lombok no lo hace); y si la regla del tutor no debería
comprobar también que el tutor sea mayor de edad (sí, es el mismo invariante).

**08 → E4. El `Movimiento` con fábrica.**

**Enunciado.** `Movimiento` con cuatro campos obligatorios; un compañero propone interfaz de fábrica, su
implementación inyectada en `Cuenta` y un builder.

**El primer diseño que sale.** El del compañero: `FabricaMovimientos`, `FabricaMovimientosImpl`, `MovimientoBuilder`
y un campo más en `Cuenta`.

**El bueno.** Un `record` con validación en el constructor compacto, creado por `Cuenta` con `new`:

```java
public record Movimiento(CuentaId cuenta, Dinero importe, LocalDate fecha, String concepto) {
    public Movimiento {
        Objects.requireNonNull(cuenta); Objects.requireNonNull(importe);
        Objects.requireNonNull(fecha);  Objects.requireNonNull(concepto);
    }
}

// en Cuenta, que tiene los datos (Creator de GRASP)
movimientos.add(new Movimiento(id, monto.negado(), hoy, "Transferencia a " + destino));
```

**Lo que cuesta.** Nada: cuatro argumentos de tipos distintos se leen bien en un constructor, y el compilador
comprueba que estén todos. La fábrica no tendría nombre, ni caché, ni subtipo que esconder; el builder cambiaría
una comprobación del compilador por una al ejecutar.

**Lo que preguntará después.** Qué cambiaría si `Movimiento` tuviera ocho campos, la mitad opcionales (entonces sí, un
builder o fábricas estáticas con nombre como `Movimiento.debito(...)` y `Movimiento.credito(...)`); y si no se
pierde la "extensibilidad" (no hay ningún eje de variación conocido; cuando aparezca, la refactorización es
pequeña).

**08 → E5. La transferencia que deja cuentas bloqueadas.**

**Enunciado.** Una transferencia en C++ que bloquea las dos cuentas a mano, abre una transacción y a veces deja
cuentas bloqueadas o transacciones abiertas.

**El primer diseño que sale.** Envolver el cuerpo en un `try/catch(...)` que haga `ROLLBACK` y los dos `unlock`, y
relanzar.

**El bueno.** Las dos causas: **interbloqueo** (una transferencia de Ana a Luis toma el cerrojo de Ana y espera el de
Luis mientras la de Luis a Ana hace lo contrario) y **fuga en las excepciones** (si `debitar` lanza, ni `COMMIT`, ni
`ROLLBACK`, ni `unlock`). La salida es RAII para los tres recursos y `std::scoped_lock` para los dos cerrojos:

```cpp
void transferir(Conexion& bd, Cuenta& origen, Cuenta& destino, Dinero monto) {
    std::scoped_lock cerrojos{origen.cerrojo(), destino.cerrojo()};   // los dos, sin interbloqueo
    TransaccionBd tx{bd};                                              // BEGIN; ROLLBACK si no se confirma
    origen.debitar(monto);
    destino.acreditar(monto);
    tx.confirmar();
}                                                                      // se libera en orden inverso
```

**Lo que cuesta.** Una clase `TransaccionBd` de diez líneas (en `07` §2). El `try/catch` del primer diseño arregla
las fugas pero no el interbloqueo, y repite la limpieza en cada función que toque cuentas.

**Lo que preguntará después.** Qué pasa si `ROLLBACK` falla dentro del destructor (no puede lanzar: se registra el
error, y la conexión se descarta del pool); y cómo se resolvería en Java (`try-with-resources` para la transacción y,
para los cerrojos, adquirirlos siempre en un orden fijo, por ejemplo por número de cuenta, porque `ReentrantLock` no
tiene un `scoped_lock`).
