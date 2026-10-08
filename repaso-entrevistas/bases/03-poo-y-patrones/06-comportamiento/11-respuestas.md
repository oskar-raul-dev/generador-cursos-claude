# 11 — Respuestas

> Solucionario del bloque `06-comportamiento`: Comportamiento. Cada respuesta en tres capas:
> **⏱️ 30 segundos** (lo que dices primero, sin que te lo pidan), **🗣️ 2 minutos** (lo que
> añades cuando dicen "cuéntame más") y **🔬 El detalle** (para estudiar, no para decir en voz
> alta). Los enunciados están copiados literalmente de su capítulo.
>
> **Vigencia:** 2026-10-03.
>
> **Versiones ejecutadas:** GCC 14.4 (C++23) · JDK 21.0.12, 17.0.20 y 25.0.4 · Spring Boot 4.1.1 (Spring Framework 7.0.9, Hibernate 7.4.5, H2 2.4.240) (2026-10-04).

**Salto rápido:** [01](#01--strategy) · [02](#02--template-method) · [03](#03--observer) · [04](#04--command) · [05](#05--chain-of-responsibility) · [06](#06--state) · [07](#07--visitor-y-lo-que-lo-reemplaza) · [08](#08--iterator-y-mediator) · [09](#09--memento-e-interpreter) · [10](#10--simulación-de-entrevista)

---

# 01 — Strategy

**01 → 1. ¿Cuál es la intención del Strategy? 🟢**

⏱️ Encapsular cada algoritmo de una familia detrás de una interfaz común para que sean intercambiables, y que
quien los usa no dependa de cuál se eligió.
🗣️ La comisión de una transferencia: en lugar de un `switch` por tipo de cuenta, una `PoliticaComision` con una
implementación por regla. El servicio recibe la política y la llama; la regla de ahorros, la de corriente o la
campaña de diciembre son intercambiables.
🔬 El GoF lo presenta con algoritmos de partición de texto en líneas. El valor está en que la variación crece sin
tocar el contexto: es el OCP aplicado a un algoritmo.

**01 → 2. ¿Qué participantes tiene el Strategy, y quién elige la estrategia? 🟢**

⏱️ La interfaz Strategy, las estrategias concretas y el Context que las usa. La elige alguien de fuera del
contexto: quien lo construye, una configuración o un registro por tipo.
🗣️ En el ejemplo, `ServicioTransferencias` tiene un mapa de `TipoCuenta` a `PoliticaComision` armado en la raíz de
composición. El servicio no decide qué regla existe: solo busca la del tipo y la llama.
🔬 Que la elección venga de fuera es lo que separa al Strategy del State (ver `06 → 5`), donde el propio objeto cambia de
comportamiento según su estado.

**01 → 3. ¿Por qué una lambda puede ser una estrategia en Java? 🟢**

⏱️ Porque una lambda es una implementación de una interfaz de un solo método, y la interfaz de una estrategia
suele tener uno: `PoliticaComision` con `comision(cuenta, monto)`.
🗣️ `(c, m) -> Dinero.cero(m.moneda())` es una estrategia completa, sin clase. Desde Java 8 la mitad del patrón —una
clase por algoritmo— desapareció para los algoritmos cortos.
🔬 `@FunctionalInterface` hace que el compilador compruebe que la interfaz tiene un solo método abstracto; sin la
anotación también funciona, pero un método más rompería todas las lambdas sin aviso claro.

**01 → 4. ¿Por qué `Comparator` es un Strategy? 🟢**

⏱️ Porque encapsula el algoritmo de comparación y se lo pasa a un algoritmo de ordenación que no sabe nada de lo
que ordena: `personas.sort(Comparator.comparing(Persona::fechaNacimiento))`.
🗣️ `List.sort` es el contexto, `Comparator` la interfaz de la estrategia, y cada comparador una estrategia concreta.
`TreeMap` recibe la suya al construirse y la usa durante toda su vida.
🔬 Los combinadores (`thenComparing`, `reversed`) son estrategias hechas de otras estrategias, y por eso `Comparator`
es también el mejor ejemplo de estrategias que se componen.

**01 → 5. ¿Qué diferencia hay entre Strategy y State? 🟡**

⏱️ La forma es la misma: un objeto delega en otro detrás de una interfaz. La diferencia es quién cambia el
delegado: en el Strategy lo elige alguien de fuera y no cambia solo; en el State lo cambia el propio objeto según
su estado, con transiciones.
🗣️ La comisión por tipo de cuenta es Strategy: el tipo no cambia por operar. Que una cuenta bloqueada rechace
débitos y una abierta los acepte, y que pase de una a otra al bloquearse, es State.
🔬 Los estados suelen conocerse entre sí (cada uno decide el siguiente); las estrategias no se conocen. Ese detalle
es la señal más fiable en un código ajeno.

**01 → 6. ¿Qué diferencia hay entre Strategy y Template Method? 🟡**

⏱️ El Template Method fija el esqueleto en una clase base y deja variar **un paso** por **herencia**; el Strategy
deja variar **el algoritmo entero** por **composición**.
🗣️ Con Template Method, una validación de documento con pasos fijos y uno que cada país sobrescribe; con Strategy,
el contexto recibe el algoritmo como objeto y lo puede cambiar al ejecutar. El Template Method se fija al
compilar la subclase; la estrategia, al construir o en cada llamada.
🔬 Un Template Method se puede convertir en Strategy pasando el paso variable como objeto: es la forma en que hoy se
evita la herencia. Ver `02 → 5`.

**01 → 7. ¿Qué diferencia hay entre `std::function` y un parámetro de plantilla como estrategia en C++? 🟡**

⏱️ `std::function` elige la estrategia al ejecutar y cuesta una llamada indirecta; el parámetro de plantilla la
fija al compilar y no cuesta nada, a cambio de que cada estrategia produzca un tipo de contexto distinto.
🗣️ Para la comisión por tipo de cuenta, que se elige leyendo la cuenta, `std::function` en un mapa. Para el
comparador de una ordenación en un bucle caliente, la plantilla, como hace `std::sort`.
🔬 `std::function` además puede asignar memoria si la lambda captura mucho (más allá de la optimización de objetos
pequeños de la implementación), y exige que lo guardado sea copiable; `std::move_only_function` (C++23) relaja eso
último.

**01 → 8. ¿Qué diferencia hay entre Strategy y Bridge? 🟡**

⏱️ Estructura casi igual; en el Strategy varía un algoritmo de un contexto que no tiene jerarquía propia, y se puede
cambiar; en el Bridge las dos partes tienen jerarquía y el vínculo dura lo que el objeto.
🗣️ La comisión intercambiable de un servicio es Strategy. Avisos con subclases que usan canales con subclases es
Bridge. El Strategy es de comportamiento; el Bridge, estructural.
🔬 Ver `05/06 → 5`. En la práctica, si hay jerarquía en los dos lados y se quiere evitar su producto, se habla de
Bridge; si no, de Strategy.

**01 → 9. ¿Qué diferencia hay entre una estrategia como clase y como lambda, y cuándo eliges cada una? 🟡**

⏱️ La lambda es para reglas cortas y sin estado; la clase, para reglas con parámetros, estado, dependencias o un
nombre que alguien va a buscar.
🗣️ `SIN_COMISION` es una lambda; `ComisionAhorros(3)`, con su número de transferencias gratuitas configurable y su
nombre, es una clase. Una lambda de quince líneas en un mapa es más difícil de leer, probar y encontrar que una
clase.
🔬 Una regla que necesita un repositorio o un reloj inyectados pide clase: la lambda tendría que capturarlos de un
ámbito que quizá no los tiene.

**01 → 10. ¿Por qué "Strategy necesita una clase por algoritmo" es falso hoy? 🟠**

⏱️ Porque en Java 8+ una lambda implementa una interfaz funcional, y en C++11+ `std::function` guarda cualquier
invocable. Un mapa de tres lambdas es el patrón entero.
🗣️ La frase venía del GoF en C++ y Smalltalk de 1994, donde cada algoritmo era una clase con su destructor virtual.
Lo que el lenguaje absorbió es la ceremonia; la idea —el algoritmo como objeto intercambiable— sigue igual.
🔬 Es el ejemplo más claro de la tesis del corpus: el patrón no desapareció, cambió de forma. Ramalho lo desarrolla
para Python en el capítulo de patrones con funciones de primera clase de *Fluent Python*.

**01 → 11. ¿Cuándo un `switch` es mejor que un Strategy? 🟠**

⏱️ Cuando el conjunto es cerrado y estable, y las reglas son cortas: tres `case` de una línea se leen de un vistazo,
y tres clases no.
🗣️ Con el `switch` exhaustivo de Java 21 sobre un `enum`, el compilador avisa si falta un caso al añadir una
constante, que es la mitad de lo que daba el Strategy. El Strategy gana cuando las reglas crecen, se eligen al
ejecutar o cambian por separado.
🔬 La pregunta útil no es "¿hay un `switch`?" sino "¿con qué frecuencia y por qué motivos cambia?". Un `switch` que
nadie toca desde hace años no es un problema.

**01 → 12. ¿Qué haces si una estrategia nueva necesita un dato que las demás no usan? 🟠**

⏱️ Primero, ver si el dato puede ser de la estrategia y no de la llamada: la cuenta empresarial puede recibir por
constructor el servicio que da el volumen mensual. Si no, se amplía la firma con un objeto de contexto.
🗣️ Añadir un parámetro a la interfaz obliga a cambiar todas las estrategias para que lo ignoren. Un objeto
`ContextoComision` con lo que podría necesitarse (cuenta, monto, fecha) permite añadir campos sin romper firmas.
🔬 Si las estrategias necesitan datos muy distintos, quizá no son la misma familia: el Strategy exige una firma
común, y forzarla es una señal de que la abstracción no es la correcta.

**01 → 13. ¿Cuándo el costo de `std::function` importa? 🟠**

⏱️ En bucles calientes con millones de llamadas, donde la llamada indirecta impide la expansión en línea, y cuando la
lambda captura más de lo que cabe en la optimización de objetos pequeños y cada copia asigna memoria.
🗣️ Para calcular la comisión de una transferencia, nunca importa: la base de datos cuesta órdenes de magnitud más.
Para el comparador de una ordenación de diez millones de elementos, sí: por eso `std::sort` toma el comparador
como plantilla.
🔬 Medir antes de cambiar: el compilador a veces desvirtualiza, y una plantilla multiplica el código generado.

**01 → 14. Reescribe el `switch` de comisiones de §1 con un Strategy en Java, con la cuenta empresarial añadida. 🔴**

⏱️ Una interfaz funcional `PoliticaComision`, una clase para la regla de ahorros, lambdas para las cortas y una
clase para la empresarial, que necesita un dato inyectado; todo en un `EnumMap` por tipo.
🗣️

```java
@FunctionalInterface
public interface PoliticaComision { Dinero comision(Cuenta origen, Dinero monto); }

public final class ComisionEmpresarial implements PoliticaComision {
    private final VolumenMensual volumen;                 // dato que las demás no usan, inyectado
    public ComisionEmpresarial(VolumenMensual volumen) { this.volumen = volumen; }
    public Dinero comision(Cuenta c, Dinero m) {
        boolean grande = volumen.de(c.titular()).esMayorQue(Dinero.cop("500000000.00"));
        return grande ? Dinero.cero(COP) : m.por(new BigDecimal("0.002"));
    }
}

Map<TipoCuenta, PoliticaComision> politicas = new EnumMap<>(Map.<TipoCuenta, PoliticaComision>of(
        TipoCuenta.AHORROS,     new ComisionAhorros(3),
        TipoCuenta.CORRIENTE,   (c, m) -> m.por(new BigDecimal("0.004")).minimo(Dinero.cop("2500.00")),
        TipoCuenta.NOMINA,      (c, m) -> Dinero.cero(m.moneda()),
        TipoCuenta.EMPRESARIAL, new ComisionEmpresarial(volumen)));
```

🔬 Lo que preguntará después: qué pasa con un tipo sin política (el mapa devuelve `null`; mejor comprobar al arrancar
que cada constante de `TipoCuenta` tiene una, recorriendo `values()`); y cómo se prueba cada regla (por separado,
sin el servicio: es una de las ganancias del patrón).

**01 → 15. Escribe en C++ una estrategia de comisión por plantilla y otra con `std::function`, y di cuándo usarías cada una. 🔴**

⏱️ Por plantilla, el contexto es una clase plantilla que guarda la política como miembro; con `std::function`, el
contexto guarda un `std::function<Dinero(const Cuenta&, const Dinero&)>`. La plantilla para bucles calientes y
estrategias fijas; `std::function` para elegir al ejecutar.
🗣️

```cpp
template <class Politica>
class CalculadoraLote {                                   // fija al compilar, sin llamada indirecta
public:
    explicit CalculadoraLote(Politica p) : politica_{std::move(p)} {}
    Dinero total(std::span<const Transferencia> lote) const {
        Dinero t = Dinero::cero();
        for (const auto& x : lote) t = t + politica_(x.origen(), x.monto());
        return t;
    }
private:
    Politica politica_;
};

class ServicioTransferencias {                            // elegida al ejecutar, por tipo de cuenta
public:
    using Politica = std::function<Dinero(const Cuenta&, const Dinero&)>;
    explicit ServicioTransferencias(std::unordered_map<TipoCuenta, Politica> p) : politicas_{std::move(p)} {}
    Dinero comision(const Cuenta& c, const Dinero& m) const { return politicas_.at(c.tipo())(c, m); }
private:
    std::unordered_map<TipoCuenta, Politica> politicas_;
};
```

🔬 Lo que preguntará después: cómo restringir lo que acepta la plantilla (con un *concept* que exija que `Politica`
se pueda invocar con una cuenta y un monto y devuelva `Dinero`: `std::invocable` más un `requires`); y qué pasa con
el tamaño del binario (cada política instancia una `CalculadoraLote` distinta).

**01 → 16. Un compañero creó `IComisionStrategy`, `ComisionStrategyFactory` y una clase por tipo para tres reglas de una línea que no cambian desde hace años. Revísalo. 🔴**

⏱️ Es ceremonia: cinco tipos para tres reglas estables de una línea. Un `switch` exhaustivo sobre el `enum`, o como
mucho un mapa de tres lambdas, dice lo mismo y se lee de un vistazo.
🗣️ El comentario: "¿Qué cambio esperas? Si las reglas no cambian y el conjunto de tipos es cerrado, propongo el
`switch` exhaustivo; el compilador avisa cuando aparezca un tipo nuevo. Si llega una regla compleja o configurable,
la extraemos entonces". El prefijo `I` y el sufijo `Strategy` son además ruido de nomenclatura.
🔬 Lo que preguntará después: si no se viola el OCP (el OCP pide puntos de extensión donde se espera el cambio; aquí
no se espera); y qué harías si el compañero insiste en que es "buena práctica" (preguntar por el costo de leerlo,
y por cuántas veces ha cambiado en los últimos años).

# 02 — Template Method

**02 → 1. ¿Cuál es la intención del Template Method? 🟢**

⏱️ Fijar el esqueleto de un algoritmo en una clase base y dejar que las subclases redefinan algunos pasos sin
cambiar el orden ni los pasos comunes.
🗣️ Validar un documento es siempre formato, vigencia y reglas del país. La base `ValidadorDocumento` tiene ese
esqueleto en `validar`, que no se puede sobrescribir, y cada país solo implementa `reglasDelPais`.
🔬 El GoF lo llama una técnica fundamental de reutilización de código, y lo asocia con el "principio de
Hollywood": la base llama a la subclase, no al revés.

**02 → 2. ¿Qué diferencia hay entre una operación primitiva y un gancho? 🟢**

⏱️ La primitiva es abstracta: la subclase **tiene** que implementarla. El gancho tiene una implementación por
defecto, normalmente vacía: la subclase **puede** sobrescribirlo.
🗣️ `reglasDelPais` es primitiva: no hay validación sin reglas del país. `alAceptar` es gancho: por defecto no hace
nada, y un país que quiera registrar algo al aceptar lo sobrescribe.
🔬 El lenguaje no distingue las dos cosas salvo por `abstract`; el GoF recomienda documentarlo. Demasiados ganchos
convierten la base en un enjambre de puntos de extensión.

**02 → 3. ¿Qué es el idioma NVI de C++? 🟢**

⏱️ *Non-Virtual Interface*: la interfaz pública de la clase es no virtual, y las funciones virtuales son privadas.
Es el Template Method aplicado como regla general de diseño de clases.
🗣️ `validar` es público y no virtual; `reglasDelPais` es virtual y privado. La derivada lo redefine, pero solo la
base decide cuándo se llama, y puede poner antes y después lo que toda llamada debe hacer.
🔬 Herb Sutter lo formuló en su artículo *Virtuality* de 2001: preferir interfaces no virtuales usando Template
Method, y observa que la librería estándar ya lo sigue casi siempre.

**02 → 4. ¿Por qué `AbstractList` es un Template Method? 🟢**

⏱️ Porque implementa casi toda la interfaz `List` —iterador, `contains`, `indexOf`, `equals`, `hashCode`— en
términos de dos operaciones primitivas que la subclase da: `get(int)` y `size()`.
🗣️ Su Javadoc lo dice: para una lista no modificable basta con implementar esos dos; para una modificable, además
`set`, y para una de tamaño variable, `add` y `remove`. El resto lo hereda escrito.
🔬 Es Template Method a escala de clase: muchos métodos plantilla que comparten las mismas primitivas.

**02 → 5. ¿Qué diferencia hay entre Template Method y Strategy? 🟡**

⏱️ El Template Method varía un paso por herencia, con el esqueleto en la base; el Strategy varía el algoritmo entero
por composición, con el algoritmo en un objeto que se pasa.
🗣️ El Template Method se fija al compilar la subclase y una clase solo tiene una base; el Strategy se elige al
construir o al llamar, y se combinan varias estrategias. El Template Method reutiliza más código; el Strategy
acopla menos.
🔬 Un Template Method con un solo paso variable se convierte en Strategy pasando ese paso como objeto: es lo que hizo
`JdbcTemplate`. Ver `01 → 6`.

**02 → 6. ¿Qué diferencia hay entre Template Method y Factory Method? 🟡**

⏱️ El Factory Method es un caso particular de Template Method: el paso que varía es crear un objeto.
🗣️ En el importador del bloque de creacionales, `importar` es el método plantilla y `crearDocumento` el paso
variable. El GoF dice que los Factory Methods se llaman normalmente desde Template Methods.
🔬 Ver `04/01 → 7`. Comparten el precio: la variación por herencia.

**02 → 7. ¿Qué diferencia hay entre el método plantilla en Java y en C++? 🟡**

⏱️ En Java se protege con `final`; en C++, con no ser virtual. Y en C++ los pasos pueden ser virtuales privados, que
la derivada redefine sin poder llamar; en Java los pasos son `protected` y la subclase puede llamarlos.
🗣️ El NVI de C++ es más estricto que el Template Method de Java: en Java nada impide que la subclase llame a
`reglasDelPais` por su cuenta; en C++, si es privada, no puede.
🔬 En C++ además existe el Template Method estático con CRTP, que resuelve los pasos al compilar sin llamada virtual.
Java no tiene equivalente.

**02 → 8. ¿Qué diferencia hay entre una clase base con utilidades y un Template Method? 🟡**

⏱️ La dirección de las llamadas: en una base de utilidades, la subclase llama a los métodos de la base; en el
Template Method, la base llama a los de la subclase.
🗣️ Una `RepositorioBase` con `ejecutarConsulta(...)` que las subclases usan es reutilización por herencia, sin
inversión de control. Un `ValidadorDocumento` que llama a `reglasDelPais` de la subclase es Template Method.
🔬 Las bases de utilidades se suelen reemplazar mejor por composición (un ayudante inyectado); heredar solo para
reutilizar métodos es la herencia que el bloque de modelo de objetos desaconseja.

**02 → 9. ¿Por qué `JdbcTemplate` no es un Template Method en sentido estricto? 🟠**

⏱️ Porque fija el esqueleto de la operación JDBC, pero los pasos variables no se sobrescriben en una subclase: se le
pasan como *callbacks* (`RowMapper`, `ResultSetExtractor`, `PreparedStatementCreator`). El mecanismo es de Strategy.
🗣️ La intención sí es de Template Method: abrir, preparar, ejecutar, recorrer, traducir excepciones y cerrar
siempre igual, con un hueco para lo que varía. Pero el hueco se llena por composición, con una lambda, y nadie hereda
de `JdbcTemplate`.
🔬 Su Javadoc lo dice: el código que lo usa solo implementa interfaces de *callback*. Es la versión moderna del patrón:
plantilla por composición.

**02 → 10. ¿Por qué el método plantilla debe ser `final` o no virtual? 🟠**

⏱️ Porque si la subclase puede sobrescribirlo, puede cambiar el orden o saltarse pasos, y el esqueleto deja de estar
garantizado: el patrón queda en una convención.
🗣️ Una subclase que sobrescribe `validar` y olvida comprobar la vigencia acepta documentos vencidos, y nadie lo nota
leyendo la base. Con `final`, el compilador lo impide.
🔬 El revisor de código tiene que buscar justamente eso: métodos plantilla sin `final` sobrescritos en alguna
subclase. Es el defecto de la pregunta 16.

**02 → 11. ¿Qué es la clase base frágil, y cómo la agrava el Template Method? 🟠**

⏱️ Que un cambio interno en la base, aparentemente seguro, rompe subclases que dependían de cómo funcionaba por
dentro. El Template Method lo agrava porque las subclases dependen del orden y del estado en que la base llama a
sus pasos.
🗣️ Si la base empieza a llamar a `alAceptar` antes de `reglasDelPais`, o deja de llamarlo en un caso, una subclase
que registraba algo en `alAceptar` cambia de comportamiento sin que nadie tocara su código.
🔬 Bloch, ítem 19: diseñar y documentar para la herencia, o prohibirla. La composición reduce el problema porque el
contrato entre las partes es una interfaz explícita.

**02 → 12. ¿Cuándo cambiarías un Template Method por composición? 🟠**

⏱️ Cuando varía un solo paso, cuando hay varias dimensiones que se combinan, o cuando la base no es tuya.
🗣️ Con un solo paso, una lambda es más simple que una jerarquía. Con reglas de país y auditoría por canal, el
Template Method multiplicaría subclases; dos estrategias se combinan. Y heredar de una base ajena ata tu código a
sus cambios internos.
🔬 La refactorización es mecánica: la base se vuelve `final`, el paso abstracto se vuelve una interfaz funcional, y
cada subclase se vuelve una implementación o una lambda. La pregunta 15 lo hace.

**02 → 13. ¿Por qué en C++ se puede sobrescribir una función virtual privada, y para qué sirve? 🟠**

⏱️ Porque en C++ el control de acceso decide quién puede **llamar** a una función, no quién puede **redefinirla**. La
derivada puede redefinir una virtual privada de la base aunque no pueda llamarla.
🗣️ Sirve para el NVI: la derivada aporta el paso, y solo la base decide cuándo se ejecuta. Así la base puede poner
antes y después del paso lo que haga falta (comprobar, medir, bloquear) sin confiar en la subclase.
🔬 En Java no hay equivalente: un método `private` no se hereda ni se sobrescribe, y por eso los pasos son
`protected`.

**02 → 14. Refactoriza los dos validadores de §1 a un Template Method en Java. 🔴**

⏱️ Una base abstracta con `validar` `final` que hace formato y vigencia y llama a `reglasDelPais`, abstracto; cada
país implementa solo sus reglas.
🗣️

```java
public abstract class ValidadorDocumento {
    public final Resultado validar(Documento d, LocalDate hoy) {
        if (!d.tipo().formato().matcher(d.numero()).matches()) return Resultado.rechazado("formato");
        if (d.vencimiento() != null && d.vencimiento().isBefore(hoy)) return Resultado.rechazado("vencido");
        return reglasDelPais(d, hoy);
    }
    protected abstract Resultado reglasDelPais(Documento d, LocalDate hoy);
}

public final class ValidadorColombia extends ValidadorDocumento {
    protected Resultado reglasDelPais(Documento d, LocalDate hoy) {
        if (d.tipo().codigo().equals("TI") && !d.titular().esMenor(hoy)) return Resultado.rechazado("TI de un adulto");
        return Resultado.aceptado();
    }
}
```

La regla "vence hoy, sigue vigente" (`isBefore`, no `!isAfter`) está ahora una sola vez.
🔬 Lo que preguntará después: dónde se elige el validador de cada documento (por el país emisor, con un mapa: un
registro de validadores); y cómo se prueban los pasos comunes (una vez, con una subclase de prueba que acepta todo).

**02 → 15. Convierte ese Template Method en un validador `final` que recibe las reglas del país como estrategia. 🔴**

⏱️ La base deja de ser abstracta: recibe una interfaz funcional `ReglasPais` por constructor y la llama en el paso
variable. Cada país pasa a ser una implementación o una lambda.
🗣️

```java
@FunctionalInterface
public interface ReglasPais { Resultado aplicar(Documento d, LocalDate hoy); }

public final class ValidadorDocumento {
    private final ReglasPais reglas;
    public ValidadorDocumento(ReglasPais reglas) { this.reglas = reglas; }
    public Resultado validar(Documento d, LocalDate hoy) {
        if (!d.tipo().formato().matcher(d.numero()).matches()) return Resultado.rechazado("formato");
        if (d.vencimiento() != null && d.vencimiento().isBefore(hoy)) return Resultado.rechazado("vencido");
        return reglas.aplicar(d, hoy);
    }
}

ReglasPais colombia = (d, hoy) -> d.tipo().codigo().equals("TI") && !d.titular().esMenor(hoy)
        ? Resultado.rechazado("TI de un adulto") : Resultado.aceptado();
var validadorCo = new ValidadorDocumento(colombia);
```

🔬 Lo que preguntará después: qué se gana (las reglas se prueban solas, se combinan —reglas del país más reglas de
campaña— y se eligen al ejecutar); y qué se pierde (los ganchos múltiples: si cada país necesitara varios pasos
relacionados, la interfaz tendría varios métodos y la lambda ya no bastaría).

**02 → 16. Revisa esta clase y di qué falla: `abstract class Exportador { public void exportar(Persona p) { abrir(); escribir(p); cerrar(); } protected abstract void escribir(Persona p); protected void abrir() {} protected void cerrar() {} }`, con una subclase que sobrescribe `exportar`. 🔴**

⏱️ El método plantilla no es `final`, y la subclase lo sobrescribió: puede saltarse `abrir` o `cerrar` y dejar el
recurso abierto. Además, `cerrar` no está en un `finally`: si `escribir` lanza, no se cierra nunca.
🗣️ El arreglo: `exportar` `final`, con `cerrar` en un `finally` (o mejor, el recurso como `AutoCloseable` en un
`try-with-resources` dentro de la plantilla), y la subclase limitada a `escribir`. Si la subclase necesitaba
cambiar el orden, su caso no encaja en esta plantilla y debería ser otra clase.
🔬 Lo que preguntará después: por qué `abrir` y `cerrar` son ganchos vacíos (porque algunos exportadores no abren
nada; pero si el recurso es obligatorio, deberían ser primitivas); y si no sería mejor por composición (con un solo
paso variable, `escribir`, sí: un exportador `final` que recibe el escritor).

# 03 — Observer

**03 → 1. ¿Cuál es la intención del Observer? 🟢**

⏱️ Definir una dependencia de uno a muchos: cuando un objeto cambia, se notifica a todos los que dependen de él, sin
que el emisor sepa quiénes son.
🗣️ El proceso nocturno detecta que el pasaporte de Ana vence en treinta días y publica eso; los avisos, el panel y la
auditoría se suscribieron y reaccionan cada uno a su manera. El proceso no conoce a ninguno.
🔬 El GoF lo presenta con hojas de cálculo y gráficos que se actualizan al cambiar los datos: el modelo y sus vistas.
De ahí viene el MVC.

**03 → 2. ¿Qué participantes tiene el Observer? 🟢**

⏱️ El Subject, que mantiene la lista y notifica; la interfaz Observer, que el sujeto llama; y los observadores
concretos.
🗣️ `RevisionVencimientos` es el sujeto, con `suscribir` y la notificación; `ObservadorVencimientos` es la interfaz,
con `porVencer(documento)`; `AvisoTitular`, `PanelOperaciones` y `Auditoria` son los concretos.
🔬 En Java moderno la interfaz es funcional y los observadores suelen ser lambdas o referencias a métodos. Lo que no
debe faltar es la forma de desuscribirse.

**03 → 3. ¿Por qué se marcó obsoleto `java.util.Observer`? 🟢**

⏱️ Su Javadoc da tres razones: el modelo de eventos es muy limitado, el orden de notificación no está especificado y
los cambios de estado no se corresponden uno a uno con las notificaciones. Se marcó obsoleto en Java 9.
🗣️ Además `Observable` es una clase, así que para ser observable había que heredar de ella, y el `update(Observable,
Object)` recibía un `Object` sin tipo. La Javadoc remite a `java.beans` para eventos, a `java.util.concurrent` para
mensajería entre hilos y a `Flow` para flujos reactivos.
🔬 Sigue en el JDK por compatibilidad, pero no se usa en código nuevo. En entrevista, mencionarlo como "lo que no hay
que usar, y por qué" suma.

**03 → 4. ¿Qué es la contrapresión en `Flow`? 🟢**

⏱️ Que el suscriptor dice cuántos elementos está dispuesto a recibir (`Subscription.request(n)`), y el emisor no le
manda más. Evita que un productor rápido desborde a un consumidor lento.
🗣️ En el Observer clásico el sujeto empuja todo lo que pasa, quiera o no el observador. En `Flow` el flujo lo regula
el consumidor. Es la diferencia entre un Observer y un *reactive stream*.
🔬 `Flow` (Java 9) solo define las interfaces de la especificación de *reactive streams*; `SubmissionPublisher` es la
implementación del JDK, y las librerías reactivas implementan las mismas interfaces.

**03 → 5. ¿Qué diferencia hay entre Observer y publicar/suscribir con un *broker*? 🟡**

⏱️ El Observer es un patrón dentro de un proceso: el sujeto conoce su lista y llama a los observadores. El
*pub/sub* con *broker* pone un intermediario —una cola, Kafka— que desacopla en el tiempo y el espacio: emisor y
receptores no se conocen ni tienen que estar vivos a la vez.
🗣️ El Observer no tiene persistencia, ni reintentos, ni orden garantizado entre procesos; si el servidor se cae
durante la notificación, se pierde. El *broker* da esas garantías a cambio de infraestructura y latencia.
🔬 Comparten la idea (el emisor no conoce a los receptores), y por eso se confunden. La mensajería entre procesos queda
fuera de este corpus.

**03 → 6. ¿Qué diferencia hay entre notificación *push* y *pull*? 🟡**

⏱️ En *push* la notificación lleva los datos (`porVencer(documento)`); en *pull* solo avisa de que algo cambió y el
observador le pregunta al sujeto lo que necesita.
🗣️ *Push* es lo habitual hoy: el observador no necesita conocer al sujeto. *Pull* evita mandar datos que nadie usa y
deja que cada observador pida lo suyo, pero acopla al observador con la interfaz del sujeto y puede leer un estado
que ya cambió otra vez.
🔬 El `update(Observable o, Object arg)` de `java.util` mezclaba las dos cosas: pasaba el sujeto (para *pull*) y un
argumento opcional (para *push*), sin tipo.

**03 → 7. ¿Qué diferencia hay entre notificación síncrona y asíncrona? 🟡**

⏱️ Síncrona: el sujeto llama a los observadores en su hilo y espera a que terminen. Asíncrona: los observadores corren
en otro hilo y el sujeto sigue.
🗣️ La síncrona conserva el orden, el contexto (la transacción, el usuario) y la propagación de errores, pero un
observador lento hace lento al emisor. La asíncrona desacopla el tiempo, y pierde todo eso. Los eventos de Spring son
síncronos por defecto: `publishEvent` bloquea.
🔬 En asíncrono, un observador que necesita la transacción del emisor ya no la tiene; y una excepción del observador
no llega al emisor, así que hay que registrarla en algún sitio.

**03 → 8. ¿Qué diferencia hay entre el Observer en C++, en Java y con `event` en C#? 🟡**

⏱️ En C++ la librería estándar no lo trae: se escribe con una lista de `std::function` y una suscripción RAII o con
`weak_ptr`. En Java tampoco hay uno estándar vigente (el de `java.util` está obsoleto): se escribe con una interfaz
funcional. En C#, `event` lo trae en el lenguaje.
🗣️ En C++ el riesgo es el puntero colgante: el observador destruido sin desuscribirse. En Java y en C#, el contrario:
el observador que no se puede recolectar porque el sujeto lo mantiene vivo.
🔬 La suscripción que se cierra (RAII en C++, `AutoCloseable` en Java, `IDisposable` en C#) resuelve los dos
problemas con la misma idea.

**03 → 9. ¿Qué diferencia hay entre Observer y Mediator? 🟡**

⏱️ El Observer es uno a muchos y en un sentido: el sujeto notifica y los observadores reaccionan. El Mediator
coordina objetos que se hablan a través de él, en las dos direcciones.
🗣️ En el Observer el sujeto no sabe qué hace cada observador; en el Mediator, el mediador sí sabe quién debe
reaccionar a qué y lo decide. Un mediador puede usar Observer por dentro para enterarse de los cambios.
🔬 El Mediator tiene ficha en `08` de este bloque, junto con el Iterator. Ver `08 → 6`.

**03 → 10. ¿Por qué un observador olvidado provoca una fuga de memoria? 🟠**

⏱️ Porque el sujeto guarda una referencia fuerte al observador, y mientras el sujeto viva, el recolector no puede
reclamar al observador, ni a todo lo que el observador referencia.
🗣️ Una pantalla que se suscribe a un servicio de vida larga y no se desuscribe al cerrarse queda viva para siempre,
con todos sus objetos. Cuarenta mil pantallas cerradas son cuarenta mil objetos que ocupan memoria y que además
reciben cada notificación.
🔬 Es el *lapsed listener*. Se evita con una suscripción que se cierra, o con referencias débiles en el sujeto
(`WeakReference`, `weak_ptr`) cuando no hay un momento claro de cierre.

**03 → 11. ¿Qué pasa si un observador lanza una excepción durante la notificación? 🟠**

⏱️ En un bucle síncrono simple, la excepción corta el bucle: los observadores que venían después no reciben la
notificación, y la excepción llega al emisor.
🗣️ Si el aviso por correo lanza, el panel y la auditoría no se enteran, y el proceso nocturno puede detenerse en ese
documento. Hay que decidir: capturar por observador y seguir (registrando el error), o dejar que falle todo.
🔬 En Spring, una excepción de un `@EventListener` síncrono se propaga a quien publicó, y si había una transacción,
puede deshacerla. En asíncrono, la excepción no llega al emisor y se pierde si nadie la registra.

**03 → 12. ¿Qué es la reentrada en un Observer, y cómo se evita? 🟠**

⏱️ Que un observador, al ser notificado, vuelva a llamar al sujeto —modificándolo, suscribiéndose o disparando otra
notificación— mientras la primera notificación sigue en curso.
🗣️ Puede producir bucles infinitos (A notifica a B, B modifica A, A notifica a B…), observadores que ven el estado a
medio cambiar, o una `ConcurrentModificationException` si alguien se desuscribe durante el recorrido.
🔬 Se evita con una lista que tolere cambios durante el recorrido (`CopyOnWriteArrayList`), notificando solo cuando
el estado ya es coherente, y encolando las notificaciones que se disparen durante otra notificación.

**03 → 13. ¿Por qué `CopyOnWriteArrayList` es una buena lista de observadores? 🟠**

⏱️ Porque recorrerla no se ve afectado por altas o bajas concurrentes: cada cambio crea una copia, y el recorrido sigue
sobre la versión que empezó. Un observador puede desuscribirse durante la notificación sin excepción.
🗣️ Las listas de observadores se recorren mucho y cambian poco, que es justo el caso para el que está hecha. Además es
segura entre hilos sin sincronizar el recorrido.
🔬 El costo es copiar el arreglo entero en cada alta o baja: con miles de suscripciones que cambian a menudo, deja de
ser adecuada.

**03 → 14. ¿Cuándo no usarías Observer? 🟠**

⏱️ Cuando los interesados son uno o dos y no cambian (una llamada directa se lee mejor), cuando el orden importa
(es una secuencia, no un evento), y cuando la reacción debe sobrevivir a una caída (es mensajería).
🗣️ El Observer esconde el flujo: para saber qué pasa al detectar un vencimiento hay que buscar quién se suscribió. Con
dos interesados fijos, ese costo no compensa.
🔬 También cuando la reacción tiene que estar en la misma transacción y fallar con ella: un Observer síncrono lo
permite, pero entonces conviene que sea explícito y no un efecto lateral de un evento.

**03 → 15. Refactoriza `revisarVencimientos` de §1 con un Observer en Java. 🔴**

⏱️ El proceso mantiene una lista de `ObservadorVencimientos`, ofrece `suscribir` que devuelve un `AutoCloseable`, y en
la revisión notifica a todos; los cuatro interesados se suscriben desde fuera.
🗣️

```java
@FunctionalInterface
public interface ObservadorVencimientos { void porVencer(Documento d); }

public final class RevisionVencimientos {
    private final RepositorioDocumentos documentos;
    private final List<ObservadorVencimientos> observadores = new CopyOnWriteArrayList<>();

    public RevisionVencimientos(RepositorioDocumentos documentos) { this.documentos = documentos; }

    public AutoCloseable suscribir(ObservadorVencimientos o) {
        observadores.add(o);
        return () -> observadores.remove(o);
    }

    public void revisar(LocalDate hoy) {
        for (Documento d : documentos.porVencerEn(hoy, 30))
            for (var o : observadores) o.porVencer(d);
    }
}

// en la raíz de composición
revision.suscribir(d -> avisos.enviarPorVencer(d.titular(), d));
revision.suscribir(d -> { if (d.titular().esMenor(LocalDate.now(reloj))) avisos.enviarPorVencer(d.titular().tutor(), d); });
revision.suscribir(panel::marcar);
revision.suscribir(d -> auditoria.registrar("por vencer: " + d.numero()));
```

🔬 Lo que preguntará después: qué pasa si el aviso por correo lanza (corta la notificación; decidir si se captura por
observador); y si la regla del tutor debería estar en un observador (es discutible: es una regla del negocio sobre a
quién avisar, y podría vivir en el propio servicio de avisos).

**03 → 16. Escribe en C++ una suscripción RAII que se desuscriba sola al destruirse. 🔴**

⏱️ Un objeto `Suscripcion` que guarda el sujeto y un identificador, se puede mover pero no copiar, y en su destructor
borra al observador de la lista del sujeto.
🗣️

```cpp
class Suscripcion {
public:
    Suscripcion(RevisionVencimientos& r, std::size_t id) : r_{&r}, id_{id} {}
    Suscripcion(Suscripcion&& o) noexcept : r_{std::exchange(o.r_, nullptr)}, id_{o.id_} {}
    Suscripcion& operator=(Suscripcion&& o) noexcept {
        if (this != &o) { cancelar(); r_ = std::exchange(o.r_, nullptr); id_ = o.id_; }
        return *this;
    }
    Suscripcion(const Suscripcion&) = delete;
    Suscripcion& operator=(const Suscripcion&) = delete;
    ~Suscripcion() { cancelar(); }
private:
    void cancelar() { if (r_) r_->quitar(id_); r_ = nullptr; }
    RevisionVencimientos* r_;
    std::size_t id_;
};
```

El sujeto devuelve la suscripción con `[[nodiscard]]`, para que nadie la descarte sin querer.
🔬 Lo que preguntará después: qué pasa si el sujeto muere antes que la suscripción (el destructor accede a memoria
liberada: o se garantiza el orden de vida, o el sujeto vive en un `shared_ptr` y la suscripción guarda un `weak_ptr`
a él); y por qué el movimiento deja el origen en `nullptr` (para que el destructor del objeto movido no cancele una
suscripción que ya no es suya).

**03 → 17. Diagnostica: la memoria del servidor crece una semana después del despliegue, y el volcado muestra cuarenta mil `PantallaDocumento` vivas. 🔴**

⏱️ Es un *lapsed listener*: cada `PantallaDocumento` se suscribió a un servicio de vida larga y nadie la desuscribió al
cerrarse. El servicio mantiene cuarenta mil referencias fuertes, y ninguna pantalla se puede recolectar.
🗣️ Se confirma en el volcado siguiendo el camino de referencias desde una pantalla hasta una raíz: pasará por la lista
de observadores del servicio. El arreglo es guardar la suscripción en la pantalla y cerrarla con ella (la autopsia
de §6).
🔬 Lo que preguntará después: por qué no apareció en las pruebas (abren pocas pantallas y terminan; la fuga necesita
tiempo y volumen); y cómo evitar que vuelva a pasar (que `suscribir` devuelva algo que hay que cerrar, y un test que
abra y cierre mil pantallas y compruebe que la lista vuelve a cero).

**03 → 18. Revisa este código: un `@EventListener` que envía el correo de bienvenida dentro de la misma transacción en la que se guarda la persona. Di qué puede fallar. 🔴**

⏱️ Como los eventos de Spring son síncronos por defecto, el correo se envía dentro de la transacción. Si la transacción
se deshace después, la persona no queda guardada y el correo ya salió; y si el envío falla, puede deshacer el alta.
🗣️ El arreglo es enviar el correo **después** de que la transacción se confirme: `@TransactionalEventListener` con la
fase posterior a la confirmación, o un evento asíncrono publicado al confirmar. El correo no es transaccional y no
debe ir dentro.
🔬 Lo que preguntará después: qué pasa si el servidor se cae entre la confirmación y el envío (el correo se pierde; si
no se puede perder, hace falta guardar el evento en la misma transacción y enviarlo después, que ya es mensajería
fiable); y si un oyente asíncrono resuelve todo (no: pierde la transacción y el contexto de seguridad del emisor).

# 04 — Command

**04 → 1. ¿Cuál es la intención del Command? 🟢**

⏱️ Convertir una petición en un objeto, para poder guardarla, encolarla, registrarla y deshacerla, en lugar de
ejecutarla y que desaparezca.
🗣️ La transferencia de Ana a Luis como un `record` con origen, destino y monto: se programa para el día 1, se mete en
la cola del lote nocturno, queda en la auditoría aunque falle, y se revierte con la transferencia inversa.
🔬 El GoF lo presenta con los menús de un editor y su deshacer. La idea de fondo es que la petición pase de ser una
llamada a ser un dato.

**04 → 2. ¿Qué participantes tiene el Command? 🟢**

⏱️ La interfaz Command, el comando concreto con sus datos, el Receiver que hace el trabajo, el Invoker que ejecuta
comandos sin saber qué hacen, y el Client que los crea.
🗣️ `Operacion` es la interfaz; `Transferencia`, el comando; las cuentas, el receptor; `ProcesadorOperaciones`, el
invocador que audita, ejecuta y guarda el historial; el controlador o el programador de tareas, el cliente.
🔬 El invocador es la pieza que da valor: como solo conoce la interfaz, se le pueden dar comandos nuevos sin tocarlo, y
es el sitio único donde se audita o se encola.

**04 → 3. ¿Por qué `Runnable` es un Command incompleto? 🟢**

⏱️ Porque solo sabe ejecutarse. No tiene datos visibles, ni nombre, ni inverso: no se puede auditar qué petición era,
ni guardarla en una tabla, ni revertirla.
🗣️ Sirve para la mitad del patrón —ejecutar después o en otro hilo—, que es lo que hace un `ExecutorService`. Para
registrar, programar con persistencia o deshacer, hace falta un tipo con los datos de la petición.
🔬 `Callable` añade un resultado, y `javax.swing.Action` añade nombre y estado habilitado: cada uno es un Command con
más o menos capacidades.

**04 → 4. ¿Qué diferencia hay entre Command y Strategy? 🟡**

⏱️ La estrategia encapsula **cómo** se hace algo y se reutiliza en muchas llamadas; el comando encapsula **una
petición concreta**, con sus datos, para hacerla una vez.
🗣️ `PoliticaComision` decide cómo se calcula la comisión de cualquier transferencia; `Transferencia(CTA-0001,
CTA-0003, 250 000,00 COP)` es una transferencia concreta. Las dos son objetos con un método, y por eso se confunden.
🔬 Iglberger les dedica el mismo capítulo precisamente por eso: la estructura es casi la misma y la intención,
distinta.

**04 → 5. ¿Qué diferencia hay entre un comando y un evento? 🟡**

⏱️ El comando es una intención: "transfiere", y puede fallar o rechazarse. El evento es un hecho: "se transfirió", ya
ocurrió y no se rechaza.
🗣️ Los comandos se nombran en imperativo y tienen un destinatario que decide; los eventos, en pasado, y los recibe
quien quiera. Un comando procesado con éxito suele producir eventos.
🔬 Confundirlos lleva a eventos que "piden" cosas y a comandos que nadie valida. La distinción es la base de
arquitecturas que quedan fuera de este corpus.

**04 → 6. ¿Qué diferencia hay entre deshacer con un comando inverso y con un Memento? 🟡**

⏱️ Con el comando inverso se ejecuta otra operación que compensa la primera; con un Memento se guarda el estado antes
de ejecutar y se restaura.
🗣️ En un banco, el inverso es lo correcto: la transferencia compensatoria queda en la historia. En un editor, el
Memento suele ser más simple: guardar el texto antes del cambio y volver a él.
🔬 El inverso no siempre existe (un redondeo, un correo); el Memento no siempre es barato (un estado grande). Se
combinan: comando para la operación, instantánea para lo que no se puede invertir.

**04 → 7. ¿Qué diferencia hay entre un comando en C++ como `std::function` y como tipo con nombre? 🟡**

⏱️ `std::function` (o `std::move_only_function`) basta cuando el comando solo tiene que ejecutarse; un tipo con nombre
hace falta cuando hay que deshacerlo, registrarlo o inspeccionar sus datos.
🗣️ La lambda captura sus datos por valor y se mete en una cola; nadie puede preguntarle después de qué cuenta a qué
cuenta era. Un `struct Transferencia` con sus campos y `revertir()` se guarda en un `std::vector` por valor y se
inspecciona.
🔬 `std::move_only_function` (C++23) admite capturas que no se copian (un `unique_ptr`), que `std::function` rechaza
porque exige copiar.

**04 → 8. ¿Por qué deshacer una transferencia no es borrarla? 🟠**

⏱️ Porque en un dominio con dinero la historia no se reescribe: se registra la operación compensatoria. El saldo
vuelve a ser el de antes, y queda constancia de las dos.
🗣️ Borrar el movimiento dejaría un extracto que no cuadra con lo que el cliente vio, y una auditoría con huecos.
`revertir()` devuelve otra `Transferencia`, de Luis a Ana, que pasa por el mismo procesador y la misma auditoría.
🔬 Es la contabilidad de partida doble aplicada al patrón. El deshacer por borrado del GoF tiene sentido en un editor,
no en un libro contable.

**04 → 9. ¿Qué debe guardar un comando que se ejecuta un mes después, y qué no? 🟠**

⏱️ Debe guardar identificadores y valores: los códigos de las cuentas y el monto. No debe guardar entidades cargadas,
conexiones ni referencias a una sesión, que dentro de un mes ya no existen.
🗣️ Un comando con objetos `Cuenta` cargados hoy ejecutaría el mes que viene con saldos viejos, o fallaría porque la
sesión cerró. Con identificadores, carga el estado actual al ejecutarse.
🔬 Por eso los comandos persistentes son *records* serializables. Si el comando depende de una regla que puede cambiar
(la comisión), hay que decidir si guarda el resultado de hoy o la recalcula al ejecutar.

**04 → 10. ¿Qué haces con un comando que no tiene inverso? 🟠**

⏱️ No inventar uno. Separar los comandos reversibles de los irreversibles, y que el invocador no ofrezca deshacer en
los segundos.
🗣️ Un correo enviado no se desenvía; lo más parecido es mandar otro de corrección, que es otra operación con otro
significado. Un `revertir()` que no hace nada, o que lanza, en un comando que lo prometía en la interfaz, engaña.
🔬 Una interfaz `Reversible` aparte, que solo implementan los que lo son, deja que el compilador sepa qué se puede
deshacer.

**04 → 11. ¿Cuándo un Command es ceremonia? 🟠**

⏱️ Cuando la petición se ejecuta en el acto y nadie la guarda, la encola ni la deshace: entonces es una llamada a método
con una clase de más.
🗣️ Para "ejecuta esto en otro hilo", una lambda en un `Executor` basta. El patrón completo se justifica cuando la
petición tiene que existir como dato: programarse, auditarse, reintentarse o revertirse.
🔬 Una jerarquía de comandos para operaciones que solo se ejecutan una vez desde un controlador es la señal típica:
mucha estructura y ninguna de las capacidades que el patrón ofrece.

**04 → 12. Escribe en Java `Transferencia` como comando con `revertir()`, y un procesador que la audite y la ejecute. 🔴**

⏱️ Un `record` que implementa `Operacion` con `ejecutar(cuentas)` y `revertir()` que devuelve la inversa, y un
procesador transaccional que registra, ejecuta y guarda en el historial.
🗣️

```java
public interface Operacion {
    void ejecutar(RepositorioCuentas cuentas);
    Operacion revertir();
}

public record Transferencia(CuentaId origen, CuentaId destino, Dinero monto) implements Operacion {
    public Transferencia {
        if (origen.equals(destino)) throw new IllegalArgumentException("misma cuenta");
        if (!monto.esPositivo()) throw new IllegalArgumentException("monto no positivo");
    }
    public void ejecutar(RepositorioCuentas cuentas) {
        cuentas.obtener(origen).debitar(monto);
        cuentas.obtener(destino).acreditar(monto);
    }
    public Transferencia revertir() { return new Transferencia(destino, origen, monto); }
}

public final class ProcesadorOperaciones {
    private final RepositorioCuentas cuentas;
    private final RepositorioOperaciones operaciones;     // el historial, persistido
    private final Auditoria auditoria;

    public ProcesadorOperaciones(RepositorioCuentas c, RepositorioOperaciones o, Auditoria a) {
        this.cuentas = c; this.operaciones = o; this.auditoria = a;
    }
    @Transactional
    public void procesar(Operacion op) {
        auditoria.registrar(op);
        op.ejecutar(cuentas);
        operaciones.guardar(op);
    }
}
```

🔬 Lo que preguntará después: si la auditoría de una operación fallida se pierde con el *rollback* (sí, si está en la
misma transacción; para auditar los intentos fallidos, se registra en una transacción aparte); y quién puede revertir
(una regla de permisos del invocador, no del comando).

**04 → 13. Escribe un macro comando para la nómina de una empresa que, si falla una transferencia, revierta las anteriores. 🔴**

⏱️ Un comando que contiene una lista de transferencias, las ejecuta en orden guardando las hechas, y si una falla,
ejecuta los inversos de las hechas en orden inverso y relanza.
🗣️

```java
public record Nomina(List<Transferencia> pagos) implements Operacion {
    public void ejecutar(RepositorioCuentas cuentas) {
        Deque<Transferencia> hechas = new ArrayDeque<>();
        try {
            for (Transferencia t : pagos) { t.ejecutar(cuentas); hechas.push(t); }
        } catch (RuntimeException e) {
            while (!hechas.isEmpty()) hechas.pop().revertir().ejecutar(cuentas);   // en orden inverso
            throw e;
        }
    }
    public Nomina revertir() {
        List<Transferencia> inversas = new ArrayList<>(pagos.stream().map(Transferencia::revertir).toList());
        Collections.reverse(inversas);
        return new Nomina(inversas);
    }
}
```

Es un Composite de comandos: la nómina se ejecuta y se revierte como una operación más.
🔬 Lo que preguntará después: si no bastaría una transacción de base de datos (sí, si todo está en la misma base y la
nómina cabe en una transacción; la compensación hace falta cuando no es así, por ejemplo con cuentas de otro banco);
y qué pasa si falla una compensación (queda un estado parcial que hay que registrar y resolver a mano: por eso la
compensación es el último recurso).

**04 → 14. Revisa este código y di qué falla: `executor.submit(() -> transferir(origen, destino, monto));` usado como "registro de operaciones programadas" que auditoría consulta. 🔴**

⏱️ Una lambda en la cola de un `ExecutorService` no es un registro: no se puede consultar qué transferencias faltan
por ejecutar, se pierde si el servidor se reinicia, y no se puede revertir ni auditar después.
🗣️ El arreglo es un comando con datos —`Transferencia` como record— guardado en una tabla de operaciones programadas;
un proceso las lee y las pasa al procesador cuando toca. Auditoría consulta la tabla, no la cola de un hilo.
🔬 Lo que preguntará después: qué pasa con dos servidores leyendo la misma tabla (hay que marcar la operación como
tomada de forma atómica para no ejecutarla dos veces); y si la cola del `Executor` tiene algún papel (sí, para
ejecutar en paralelo lo que ya se leyó de la tabla, no para guardarlo).

# 05 — Chain of Responsibility

**05 → 1. ¿Cuál es la intención de Chain of Responsibility? 🟢**

⏱️ Desacoplar a quien emite una petición de quien la atiende, pasándola por una cadena de candidatos hasta que uno
la atienda.
🗣️ La aprobación de una transferencia: listas restrictivas, aprobación automática, supervisor, gerencia y comité.
Cada eslabón mira el monto y decide si es suya; si no, la pasa. Quien pide la aprobación solo conoce el primer
eslabón.
🔬 El GoF lo presenta con la ayuda contextual de una interfaz: el botón, su diálogo, la ventana. La propagación de
excepciones hasta el primer `catch` que las acepta es la misma idea hecha lenguaje.

**05 → 2. ¿Qué participantes tiene, y qué sabe el cliente? 🟢**

⏱️ El Handler (la interfaz y, en la forma clásica, la referencia al siguiente), los manejadores concretos y el
cliente. El cliente solo sabe a qué eslabón entregar la petición, no quién la atenderá.
🗣️ En la forma del GoF cada manejador guarda el siguiente y lo llama si no atiende. En la forma moderna, la cadena es
una lista y un objeto la recorre; los manejadores devuelven "atendí" o "no es mía".
🔬 La forma moderna evita dos errores de la clásica: el eslabón que olvida pasar la petición y el que la pasa dos
veces.

**05 → 3. ¿Qué hace un filtro de servlet con su `FilterChain`? 🟢**

⏱️ Recibe la petición, hace su trabajo, y decide si llama a `cadena.doFilter(req, res)` para pasarla al siguiente
filtro o al servlet. Puede trabajar antes y después de esa llamada.
🗣️ Un filtro de auditoría mide el tiempo alrededor de `doFilter`; uno de autenticación no llama a `doFilter` si no
hay credenciales, y la cadena se corta con un 401.
🔬 Es la variante que acumula: todos los filtros procesan, salvo que alguno detenga la cadena. El contenedor arma la
cadena según la configuración, y el orden importa.

**05 → 4. ¿Qué es la `SecurityFilterChain` de Spring? 🟢**

⏱️ La lista de filtros de seguridad por la que pasa cada petición en Spring Security: autenticación, CSRF, gestión de
excepciones, autorización, en un orden fijo.
🗣️ Spring Security la registra como un único filtro de servlet que delega en su propia cadena. Cada filtro puede
autenticar, rechazar o dejar pasar; si la autorización falla, la cadena se corta y la petición nunca llega al
controlador.
🔬 Puede haber varias `SecurityFilterChain` y Spring elige una según la ruta: una cadena de cadenas. Depurar la
seguridad es, casi siempre, mirar en qué filtro se cortó.

**05 → 5. ¿Qué diferencia hay entre la cadena que se corta y la que acumula? 🟡**

⏱️ En la que se corta, la petición se detiene en el primer eslabón que la atiende y los demás no la ven. En la que
acumula, todos procesan, antes y después del resto, y cualquiera puede detenerla.
🗣️ La aprobación por monto es la primera: el supervisor atiende y el comité nunca se entera. Los filtros de servlet
son la segunda: auditoría, autenticación y compresión procesan todos la misma petición.
🔬 Hay una tercera, la que acumula sin cortar (todas las validaciones devuelven sus errores), que ya es un recorrido
de una lista más que el patrón del GoF.

**05 → 6. ¿Qué diferencia hay entre Chain of Responsibility y Decorator? 🟡**

⏱️ El decorador siempre delega en el objeto que envuelve; el eslabón de una cadena puede no pasar la petición.
🗣️ La variante de filtros se parece mucho a una pila de decoradores: cada filtro envuelve al resto. La diferencia está
en que el filtro de autenticación puede no llamar a `doFilter`, y un decorador que no llama al envuelto ya no
decora, sustituye.
🔬 Además, la cadena la suele armar un marco a partir de configuración, y los decoradores los compone el código. Ver
`05/02`.

**05 → 7. ¿Qué diferencia hay entre Chain of Responsibility y Observer? 🟡**

⏱️ El Observer entrega la notificación a **todos** los suscriptores, sin orden relevante; la cadena busca **uno** que
atienda la petición, en orden.
🗣️ Que un documento vence interesa a varios (avisos, panel, auditoría): Observer. Quién aprueba una transferencia lo
decide uno: cadena.
🔬 En el Observer, que nadie escuche no es un problema; en la cadena, que nadie atienda sí lo es, y hay que decidir qué
pasa al final.

**05 → 8. ¿Qué cambia en la cadena entre C++98 y una lista de `std::function` con `std::optional`? 🟡**

⏱️ En C++98 cada manejador guarda un puntero al siguiente y lo llama a mano; con una lista de invocables, la cadena es
un `vector` que un bucle recorre, y cada eslabón dice "no es mía" devolviendo `std::nullopt`.
🗣️ El orden pasa de estar repartido en punteros a estar en un solo sitio, el `vector`. Y el tipo de retorno dice lo
que antes era convención: un `optional` vacío es "pasa".
🔬 Se pierde la posibilidad de que un eslabón haga algo **después** de los siguientes (la variante de filtros); para
eso cada eslabón necesita recibir "el resto de la cadena", como el `FilterChain`.

**05 → 9. ¿Por qué el orden de la cadena es parte de la regla? 🟠**

⏱️ Porque la petición llega al primero que la acepta: si el aprobador automático va antes que el filtro de listas
restrictivas, aprueba transferencias a cuentas que deberían rechazarse.
🗣️ El orden no aparece en ningún eslabón: está donde se arma la cadena. Por eso conviene armarla en un solo sitio, a la
vista, y probarla entera además de cada eslabón.
🔬 En Spring Security el orden de los filtros es fijo y está documentado; insertar un filtro propio exige decir antes
o después de cuál, y equivocarse es un hueco de seguridad.

**05 → 10. ¿Qué haces si nadie atiende la petición? 🟠**

⏱️ Decidirlo explícitamente al final de la cadena: rechazar, lanzar, o poner un último eslabón que atiende siempre. Lo
que no se debe es dejar que la petición caiga sin respuesta.
🗣️ En la aprobación, el comité atiende todo lo que llega: es el eslabón por defecto. Si no existiera, la cadena
devuelve "rechazada: nadie la atendió", que con dinero es lo prudente.
🔬 El GoF lo menciona como consecuencia del patrón: la recepción no está garantizada. Un test que mande una petición
fuera de todos los rangos lo comprueba.

**05 → 11. ¿Cuándo una cadena es ceremonia? 🟠**

⏱️ Cuando hay pocos casos fijos que no cambian (un `if` ordenado se lee mejor), y cuando se sabe de antemano quién
atiende por un dato (un mapa o una estrategia elegida bastan).
🗣️ Tres umbrales que nunca cambian son tres líneas; tres clases y una cadena esconden el orden y añaden saltos al
depurar. La cadena se justifica cuando los candidatos cambian o se configuran.
🔬 Señal típica de cadena innecesaria: cada eslabón comprueba el mismo campo contra un valor distinto. Eso es un mapa de
rangos.

**05 → 12. ¿Por qué validar un documento devolviendo todos sus errores no es una cadena en sentido estricto? 🟠**

⏱️ Porque todos los validadores procesan siempre y se juntan sus resultados: nadie "atiende" ni corta. Es un recorrido
de una lista de validadores.
🗣️ Se le sigue llamando "cadena de validadores", y es lo correcto cuando el usuario quiere ver todos los errores a la
vez en lugar de corregir uno por intento. La forma del GoF devolvería solo el primero.
🔬 Si hay que cortar ante un error grave (sin formato válido no tiene sentido comprobar duplicados), se mezclan:
validadores que acumulan y alguno que detiene.

**05 → 13. Refactoriza `aprobar` de §1 a una cadena en Java, con un nivel nuevo para transferencias internacionales. 🔴**

⏱️ Una interfaz `Aprobador` que devuelve `Optional<Aprobacion>`, un eslabón por regla, el internacional insertado
después del filtro de listas, y una `CadenaAprobacion` que recorre la lista.
🗣️

```java
@FunctionalInterface
public interface Aprobador { Optional<Aprobacion> aprobar(Transferencia t); }

static Aprobador hastaMonto(Dinero limite, Function<Transferencia, Aprobacion> accion) {
    return t -> t.monto().menorOIgual(limite) ? Optional.of(accion.apply(t)) : Optional.empty();
}

Aprobador internacional = t -> t.esInternacional()
        ? Optional.of(cumplimiento.pedir(t))            // toda internacional va a cumplimiento, sea cual sea el monto
        : Optional.empty();

var cadena = new CadenaAprobacion(List.of(
        new FiltroListasRestrictivas(listas),
        internacional,
        hastaMonto(Dinero.cop("5000000.00"),   t -> Aprobacion.automatica()),
        hastaMonto(Dinero.cop("50000000.00"),  supervisores::pedir),
        hastaMonto(Dinero.cop("500000000.00"), gerencia::pedir),
        t -> Optional.of(comite.pedir(t))));
```

🔬 Lo que preguntará después: por qué el internacional va antes de la automática (porque si fuera después, una
internacional pequeña se aprobaría sola: el orden es la regla); y cómo se prueba (cada eslabón solo, y la cadena entera
con una transferencia por rango).

**05 → 14. Escribe un filtro de servlet que rechace con 401 las peticiones sin cabecera `Authorization` y deje pasar las demás. 🔴**

⏱️ Un `Filter` que lee la cabecera; si falta, escribe un 401 y **no** llama a `cadena.doFilter`; si está, la llama.
🗣️

```java
public final class FiltroAutorizacion implements Filter {
    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain cadena)
            throws IOException, ServletException {
        var http = (HttpServletRequest) req;
        if (http.getHeader("Authorization") == null) {
            ((HttpServletResponse) res).sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;                                          // la cadena se corta aquí
        }
        cadena.doFilter(req, res);
    }
}
```

🔬 Lo que preguntará después: dónde va en el orden (antes que cualquier filtro que use el usuario autenticado, y después
de los que deben ver todas las peticiones, como el de auditoría); y por qué en un proyecto con Spring no lo escribirías
(Spring Security ya trae esa cadena, con el orden resuelto y probado).

# 06 — State

**06 → 1. ¿Cuál es la intención del State? 🟢**

⏱️ Que un objeto cambie de comportamiento cuando cambia su estado interno, de modo que parezca haber cambiado de
clase, con cada estado y sus transiciones explícitos.
🗣️ Una `Cuenta` abierta admite débitos; bloqueada, no; cerrada, nada. En lugar de *flags* y cascadas de `if`, la
cuenta tiene un `EstadoCuenta` que decide qué operaciones admite y a qué estado se pasa.
🔬 El GoF lo presenta con una conexión TCP. Lo que el patrón gana es que las combinaciones imposibles de *flags* dejan
de poder escribirse.

**06 → 2. ¿Qué participantes tiene el State? 🟢**

⏱️ El Context, que tiene un estado actual y le delega; la interfaz State, con una operación por evento; y los estados
concretos, que implementan el comportamiento y las transiciones.
🗣️ `Cuenta` es el contexto; `EstadoCuenta`, la interfaz (o el `enum`); `ABIERTA`, `BLOQUEADA` y `CERRADA`, los
estados. El cliente solo habla con la cuenta.
🔬 Los estados pueden conocerse entre sí si son ellos quienes deciden la transición: es la decisión de diseño más
importante del patrón.

**06 → 3. ¿Por qué el GoF comparte los objetos estado entre todos los contextos? 🟢**

⏱️ Porque un estado sin datos propios es igual para todas las cuentas: no hay razón para crear un objeto `Abierta` por
cuenta. Es un Flyweight.
🗣️ El contexto guarda los datos (el saldo); el estado solo aporta comportamiento. En C++98 el GoF lo escribe con un
Singleton por estado; en Java, un `enum` lo da gratis.
🔬 En cuanto un estado necesita datos propios (el motivo de un bloqueo), deja de poder compartirse y pasa a ser un
valor por cuenta: un record o una alternativa de `std::variant`.

**06 → 4. ¿Qué hace un `enum` de Java con un método por constante? 🟢**

⏱️ Cada constante puede tener su propio cuerpo y sobrescribir métodos del `enum`: el comportamiento depende de la
constante sin ningún `switch`.
🗣️ `ABIERTA { EstadoCuenta bloquear() { return BLOQUEADA; } }` y un `bloquear()` por defecto que lanza: así se escribe
el patrón State en pocas líneas para un ciclo de vida cerrado.
🔬 Por dentro cada constante con cuerpo es una subclase anónima del `enum`. Bloch lo trata en el ítem 34 de *Effective
Java* como "constant-specific method implementations".

**06 → 5. ¿Qué diferencia hay entre State y Strategy? 🟡**

⏱️ La estructura es la misma; la diferencia es quién cambia el objeto delegado. La estrategia la elige alguien de fuera
y no cambia sola; el estado lo cambian las propias operaciones del contexto, con transiciones.
🗣️ La comisión por tipo de cuenta es Strategy: el tipo no cambia por operar. Bloquear una cuenta es una transición de
estado: después de `bloquear()`, `debitar` se comporta distinto.
🔬 Señal en el código: los estados suelen conocerse (uno devuelve al otro) y las estrategias no. Ver `01 → 5`.

**06 → 6. ¿Qué diferencia hay entre un `enum` con comportamiento y un `enum` con un `switch` en cada método? 🟡**

⏱️ El primero pone el comportamiento de cada estado en su constante: es el patrón. El segundo reparte un `switch` sobre
el estado por todos los métodos de la cuenta: es la versión con *flags* con constantes en lugar de `boolean`.
🗣️ Con el `switch` repetido, para saber qué hace una cuenta bloqueada hay que leer cuatro métodos, y un estado nuevo
obliga a tocarlos todos. Con el comportamiento en la constante, se lee un bloque.
🔬 El `switch` exhaustivo de Java 21 al menos avisa del caso que falta; no quita la repetición. Es el defecto de la
pregunta 16.

**06 → 7. ¿Qué diferencia hay entre el State con objetos y con `std::variant` en C++? 🟡**

⏱️ Con objetos, cada estado es una clase con métodos virtuales y las transiciones viven en los estados. Con
`std::variant`, cada estado es un valor (que puede llevar datos) y las transiciones viven en el contexto, con
`std::visit`.
🗣️ El `variant` no necesita heap ni herencia, y deja que `Bloqueada` lleve su motivo. Los objetos reparten mejor la
lógica cuando cada estado tiene mucho comportamiento.
🔬 Con `std::visit` y un *overload set* de lambdas, el compilador falla si falta un estado: la exhaustividad que los
objetos no dan.

**06 → 8. ¿Qué diferencia hay entre que la transición la decida el estado o el contexto? 🟡**

⏱️ Si la decide el estado, cada estado devuelve el siguiente y la regla vive junto al comportamiento, a costa de que los
estados se conozcan. Si la decide el contexto, los estados solo dan comportamiento y todas las transiciones se ven en
un sitio.
🗣️ Lo habitual es que decida el estado, porque las transiciones dependen de en qué estado se está. Decide el contexto
cuando la transición depende de datos del contexto o cuando se quiere ver la tabla entera.
🔬 La tercera opción es una tabla de (estado, evento) a estado siguiente, que puede venir de configuración: la máquina
de estados declarada.

**06 → 9. ¿Por qué dos *flags* booleanos son peores que un estado? 🟠**

⏱️ Porque dos `boolean` son cuatro combinaciones, y alguna —bloqueada y cerrada a la vez— no significa nada pero se
puede alcanzar. Un estado solo puede valer uno de los casos que existen.
🗣️ Además, cada operación repite la cascada de `if` sobre los *flags*, y la regla de cada estado queda repartida por
toda la clase. Con un estado, las combinaciones imposibles no se pueden escribir.
🔬 Es la idea de "hacer irrepresentables los estados ilegales": el tipo impide el error en lugar de comprobarlo en
cada método.

**06 → 10. ¿Cuándo usarías una interfaz sellada con records en lugar de un `enum`? 🟠**

⏱️ Cuando los estados llevan datos propios: el motivo y la fecha del bloqueo, la fecha del cierre. Un `enum` tiene los
mismos campos en todas sus constantes y no puede tener datos por instancia.
🗣️ `record Bloqueada(String motivo, LocalDate desde)` solo existe cuando la cuenta está bloqueada; con un `enum`, el
motivo sería un campo de `Cuenta` que vale `null` en los otros estados.
🔬 Con Java 21, el `switch` exhaustivo sobre la interfaz sellada da el comportamiento por estado; en Java 17 se
escribe con `instanceof` o con métodos en cada record.

**06 → 11. ¿Cómo se persiste un estado, y qué problema aparece con los estados que llevan datos? 🟠**

⏱️ Un estado sin datos se guarda como su nombre en una columna (`'BLOQUEADA'`) y se reconstruye con `valueOf`. Con datos
propios, hacen falta columnas que solo valen para un estado (`motivo_bloqueo`), nulas en los demás.
🗣️ Con JPA, un `enum` se mapea con `@Enumerated(EnumType.STRING)`, nunca por ordinal: reordenar las constantes
cambiaría el significado de los datos guardados. Los records sellados necesitan un mapeo propio: un discriminador y
columnas por estado.
🔬 Es el mismo problema que mapear una jerarquía a tablas: ver [`07/04` §7](../07-fowler-dominio-y-datos/04-estructura-objeto-relacional.md#7--los-tres-mapeos-de-herencia).

**06 → 12. ¿Cuándo un State es ceremonia? 🟠**

⏱️ Con dos estados y una sola diferencia de comportamiento (un `boolean activa` y un `if` bastan), con estados que no
cambian el comportamiento (solo se muestran), y con flujos grandes que el negocio configura (eso es una máquina de
estados declarada).
🗣️ Tres clases de estado para "activa / inactiva" añaden indirección sin quitar ningún error. El patrón paga cuando hay
varias operaciones y varias reglas por estado.
🔬 La señal para pasar de `boolean` a State es el segundo *flag* que interactúa con el primero.

**06 → 13. ¿Qué haces si aparece un estado nuevo, `EMBARGADA`, que solo admite créditos? 🟠**

⏱️ Añadir la constante al `enum` con su comportamiento (admite créditos, no débitos) y revisar desde qué estados se
llega a ella: un evento `embargar()` que `ABIERTA` y `BLOQUEADA` aceptan.
🗣️ Los demás estados lanzan por defecto en `embargar()` salvo los que lo admitan. Hay que decidir también cómo se sale:
`levantarEmbargo()` hacia `ABIERTA`, y si se puede cerrar una cuenta embargada.
🔬 Con un `switch` repetido, este cambio tocaría todos los métodos de `Cuenta`; con el patrón, toca la constante nueva
y las transiciones que llegan a ella. Con una interfaz sellada, el compilador además señala todos los `switch` que no
la tratan.

**06 → 14. Refactoriza la `Cuenta` de §1 con un `enum` `EstadoCuenta` con comportamiento. 🔴**

⏱️ Un `enum` con un método por evento que devuelve el siguiente estado y lanza por defecto, constantes que sobrescriben
lo que admiten, y una `Cuenta` con un solo campo de estado.
🗣️

```java
public enum EstadoCuenta {
    ABIERTA {
        EstadoCuenta bloquear() { return BLOQUEADA; }
        EstadoCuenta cerrar(Dinero saldo) { return cerrarSiVacia(saldo); }
        boolean admiteDebitos() { return true; }
    },
    BLOQUEADA {
        EstadoCuenta desbloquear() { return ABIERTA; }
        EstadoCuenta cerrar(Dinero saldo) { return cerrarSiVacia(saldo); }
    },
    CERRADA;

    EstadoCuenta bloquear()           { throw new OperacionNoPermitidaException(this, "bloquear"); }
    EstadoCuenta desbloquear()        { throw new OperacionNoPermitidaException(this, "desbloquear"); }
    EstadoCuenta cerrar(Dinero saldo) { throw new OperacionNoPermitidaException(this, "cerrar"); }
    boolean admiteDebitos()           { return false; }
    boolean admiteCreditos()          { return this != CERRADA; }

    private static EstadoCuenta cerrarSiVacia(Dinero saldo) {
        if (!saldo.esCero()) throw new OperacionNoPermitidaException(ABIERTA, "cerrar con saldo");
        return CERRADA;
    }
}

public final class Cuenta {
    private EstadoCuenta estado = EstadoCuenta.ABIERTA;
    private Dinero saldo;
    public void debitar(Dinero m)   { exigir(estado.admiteDebitos(), "debitar");   saldo = saldo.menos(m); }
    public void acreditar(Dinero m) { exigir(estado.admiteCreditos(), "acreditar"); saldo = saldo.mas(m); }
    public void bloquear()    { estado = estado.bloquear(); }
    public void desbloquear() { estado = estado.desbloquear(); }
    public void cerrar()      { estado = estado.cerrar(saldo); }
    private void exigir(boolean ok, String op) { if (!ok) throw new OperacionNoPermitidaException(estado, op); }
}
```

🔬 Lo que preguntará después: por qué los métodos del `enum` no son públicos (para que solo `Cuenta` pueda provocar
transiciones); y cómo se registra el historial de estados (cada transición puede publicar un evento de dominio, que
tiene su capítulo en [`09/02`](../09-ddd-tactico-y-otros/02-eventos-servicios-y-fabricas.md)).

**06 → 15. Escribe los estados de la cuenta como interfaz sellada con records en Java, con el motivo del bloqueo. 🔴**

⏱️ Una interfaz sellada con tres records; `Bloqueada` lleva motivo y fecha; las transiciones son métodos de `Cuenta` con
un `switch` exhaustivo sobre el estado actual.
🗣️

```java
public sealed interface Estado permits Abierta, Bloqueada, Cerrada {}
public record Abierta() implements Estado {}
public record Bloqueada(String motivo, LocalDate desde) implements Estado {}
public record Cerrada(LocalDate fecha) implements Estado {}

public void bloquear(String motivo, LocalDate hoy) {
    estado = switch (estado) {
        case Abierta a   -> new Bloqueada(motivo, hoy);
        case Bloqueada b -> throw new OperacionNoPermitidaException("ya está bloqueada desde " + b.desde());
        case Cerrada c   -> throw new OperacionNoPermitidaException("cerrada el " + c.fecha());
    };
}
```

🔬 Lo que preguntará después: cómo se escribe en Java 17 (con `if (estado instanceof Abierta)` encadenados, sin
exhaustividad comprobada); y dónde vive ahora la regla de transición (en el contexto: es la variante en la que decide
la cuenta, más legible con pocos estados).

**06 → 16. Revisa este código y di qué falla: `switch (cuenta.estado()) { case ABIERTA -> …; case BLOQUEADA -> …; }` repetido en `debitar`, `acreditar`, `bloquear` y `cerrar`. 🔴**

⏱️ Es la versión con *flags* con constantes: la regla de cada estado está repartida en cuatro `switch`, y un estado
nuevo obliga a tocarlos todos. Además el `switch` del ejemplo no trata `CERRADA`.
🗣️ El arreglo es mover el comportamiento a cada constante del `enum` (o a cada record de una interfaz sellada): un
método por evento, con la transición dentro. Los cuatro `switch` desaparecen.
🔬 Lo que preguntará después: si un `switch` exhaustivo de Java 21 no basta (avisa del caso que falta, pero no quita la
repetición); y cuándo un único `switch` está bien (cuando hay **uno** solo, en un sitio, por ejemplo para traducir el
estado a un texto de pantalla).

# 07 — Visitor, y lo que lo reemplaza

**07 → 1. ¿Cuál es la intención del Visitor? 🟢**

⏱️ Definir operaciones nuevas sobre los elementos de una estructura sin cambiar sus clases, con un caso por cada
tipo de elemento.
🗣️ La línea del extracto, la exportación a CSV y el informe para el regulador sobre los movimientos de una cuenta:
cada operación es un visitante con un método por tipo de movimiento, y los movimientos no se tocan.
🔬 El GoF lo presenta con el árbol de sintaxis de un compilador. Por debajo, el patrón es una forma de fabricar el
*double dispatch* que el lenguaje no tiene.

**07 → 2. ¿Qué es el *double dispatch*? 🟢**

⏱️ Elegir el método que se ejecuta por el tipo dinámico de **dos** objetos a la vez. Java y C++ solo despachan por
uno, el receptor.
🗣️ En el Visitor, el primer despacho es `movimiento.aceptar(v)`, que elige por el tipo del movimiento; dentro,
`v.visitar(this)` elige la sobrecarga por el tipo estático de `this` (que ya es el concreto) y despacha por el tipo
del visitante. Dos despachos simples encadenados dan uno doble.
🔬 Algunos lenguajes tienen *multimethods* (despacho múltiple) en el propio lenguaje, como Common Lisp o Julia; ahí
Visitor no existe. Ver `01/05` §4.

**07 → 3. ¿Qué hace `std::visit`? 🟢**

⏱️ Llama al invocable que se le pasa con la alternativa que el `std::variant` contiene en ese momento, con su tipo
exacto. Es el despacho por el tipo de un valor sin jerarquía.
🗣️ Con un objeto que reúne varias lambdas, una por alternativa, `std::visit` elige la que corresponde. Si falta una
alternativa, no compila.
🔬 Acepta varios `variant` a la vez y elige por la combinación de sus tipos: un despacho múltiple de verdad, resuelto
con una tabla generada al compilar.

**07 → 4. ¿Qué es un *record pattern* en Java? 🟢**

⏱️ Un patrón que comprueba que un valor es de un record concreto y a la vez lo desestructura en sus componentes:
`case Retiro(var monto, var cajero) ->`.
🗣️ Se usa en `instanceof` y en `switch`, y se puede anidar. Junto con el `switch` de patrones y los tipos sellados, es
lo que hace que el `switch` reemplace al Visitor con poco código.
🔬 Es la JEP 440, final en Java 21. En Java 22 se añadió el `_` para ignorar componentes (JEP 456).

**07 → 5. ¿Qué diferencia hay entre Visitor y un `switch` exhaustivo sobre tipos sellados? 🟡**

⏱️ Dan la misma garantía —una operación con un caso por tipo, y el compilador avisa si falta uno—, pero el `switch` lo
hace sin `aceptar`, sin interfaz de visitante y sin la doble llamada.
🗣️ Con Visitor, añadir un tipo obliga a tocar la interfaz del visitante; con `sealed`, a tocar la lista `permits`; en
los dos casos el compilador señala cada operación por completar. El `switch` tiene un tercio del código y se lee de arriba
abajo.
🔬 El `switch` exige poder sellar la jerarquía (mismo módulo o paquete) y Java 21; el Visitor funciona en Java 17 y sobre
jerarquías ajenas.

**07 → 6. ¿Qué diferencia hay entre Visitor e Iterator? 🟡**

⏱️ El Iterator recorre los elementos de una colección; el Visitor despacha una operación por el tipo de cada
elemento. Uno decide **qué elemento sigue**, el otro **qué se hace con él**.
🗣️ Se combinan a menudo: se itera una lista de movimientos y a cada uno se le aplica un visitante. Pero un Visitor sobre
un solo elemento sigue siendo un Visitor, y un Iterator sobre elementos del mismo tipo no necesita ninguno.
🔬 La confusión viene de los ejemplos con árboles, donde el `aceptar` del nodo compuesto recorre a los hijos y mezcla
las dos cosas.

**07 → 7. ¿Qué diferencia hay entre el Visitor clásico en C++ y `std::variant` con `std::visit`? 🟡**

⏱️ El clásico necesita una jerarquía con `aceptar` virtual y una interfaz de visitante con un `visitar` por tipo; el
`variant` usa valores sin base común y `std::visit` hace el despacho doble.
🗣️ Con `variant` no hay heap, ni punteros, ni `aceptar` repetido, y el resultado se devuelve directamente (en el
clásico, `visitar` devuelve `void` porque no hay plantillas virtuales). La exhaustividad la comprueba el compilador.
🔬 El `variant` exige conocer todas las alternativas al compilar: es una jerarquía cerrada. Para una jerarquía abierta
a tipos de terceros, el clásico sigue siendo la opción. Iglberger lo desarrolla en el cap. 4 de *C++ Software Design*.

**07 → 8. ¿Qué diferencia hay entre añadir una operación y añadir un tipo con Visitor? 🟡**

⏱️ Una operación es barata: un visitante nuevo, sin tocar los elementos. Un tipo es caro: un método nuevo en la interfaz
del visitante y en todos los visitantes concretos.
🗣️ Es la asimetría del *expression problem*: con métodos en los elementos, añadir tipos es barato y operaciones caro;
con Visitor, al revés. Elegir Visitor es apostar a que los tipos son estables y las operaciones crecen.
🔬 Con tipos sellados la asimetría es la misma; lo que cambia es la cantidad de código y que el compilador señala los
sitios.

**07 → 9. ¿Qué diferencia hay entre Visitor y sobrecarga de métodos? 🟡**

⏱️ La sobrecarga se resuelve al compilar por el tipo estático del argumento; por sí sola, con un `Movimiento` en la mano,
siempre elige `visitar(Movimiento)`. El Visitor la usa donde el tipo estático ya es el concreto: dentro de `aceptar`.
🗣️ Por eso no basta con escribir varios `visitar` sobrecargados y llamarlos con un `Movimiento`: hace falta el primer
despacho dinámico (`aceptar`) para llegar a un contexto donde `this` tenga el tipo exacto.
🔬 Es la trampa de `01/05` §3: sobrecarga al compilar, sobrescritura al ejecutar.

**07 → 10. ¿Por qué `aceptar` se repite en cada clase concreta y no se hereda? 🟠**

⏱️ Porque dentro de la clase base, `this` tiene el tipo estático de la base, y `v.visitar(this)` elegiría la sobrecarga
de la base. Solo en la clase concreta `this` tiene el tipo exacto que elige el `visitar` correcto.
🗣️ El cuerpo es idéntico en todas (`return v.visitar(this);`), y aun así hay que escribirlo en cada una: es el
*boilerplate* característico del patrón, y una fuente de errores si alguien lo copia mal.
🔬 En C++ se puede generar con CRTP o, desde C++23, con *deducing this*, que da a la base el tipo de la derivada.

**07 → 11. ¿Por qué "Visitor es para recorrer árboles" es impreciso? 🟠**

⏱️ Porque el patrón es el *double dispatch*, no el recorrido. Una lista plana de movimientos lo necesita igual que un
árbol de sintaxis.
🗣️ La confusión viene de los ejemplos (compiladores, sistemas de archivos) y de nombres como `FileVisitor`, que es
sobre todo un recorrido con *callbacks*. Recorrer es Iterator; visitar es elegir la operación por el tipo.
🔬 En un Composite, el Visitor puede encargarse además del recorrido si el `aceptar` del compuesto visita a los hijos;
es una combinación, no la definición.

**07 → 12. ¿Cuándo Visitor todavía gana a los tipos sellados? 🟠**

⏱️ En Java 17, sin `switch` de patrones; sobre jerarquías ajenas y abiertas que ofrecen un visitante; cuando los tipos
no pueden estar en el mismo módulo; y cuando la estructura debe controlar el recorrido.
🗣️ `ElementVisitor` del compilador de Java y los visitantes de ASM son ejemplos de la segunda: no puedes sellar sus
jerarquías. La JLS exige que una clase sellada y sus permitidas compartan módulo (o paquete sin módulos), que es la
tercera.
🔬 La cuarta es un matiz de diseño: con Visitor el árbol decide el orden de visita; con `switch`, cada operación escribe
su recorrido.

**07 → 13. ¿Qué haces en Java 17 si quieres exhaustividad sobre una jerarquía? 🟠**

⏱️ El Visitor clásico: la interfaz del visitante tiene un método por tipo, y un tipo nuevo obliga a todos los visitantes
a implementarlo o no compilan.
🗣️ La cadena de `instanceof` no avisa de nada. Otra opción es poner un método abstracto en la interfaz sellada por cada
operación, que también obliga a cada tipo a implementarlo; pero mete las operaciones en los elementos.
🔬 En 17, el `switch` sobre un `enum` sí es exhaustivo como expresión; si la variación se puede expresar con un `enum`
de tipos, es otra salida.

**07 → 14. ¿Por qué el `instanceof` encadenado de §1 es peor que las dos alternativas? 🟠**

⏱️ Porque no tiene comprobación de exhaustividad: si falta un tipo, como la comisión, compila y falla al ejecutar. El
Visitor y el `switch` sellado no compilan si falta un caso.
🗣️ Además se repite en cada operación, y cada repetición es otra oportunidad de olvidar un tipo. El último `throw` es
la única defensa, y llega en producción.
🔬 Desde Java 16 el `instanceof` con patrón es cómodo de escribir, y eso hace que esta forma aparezca más. La pregunta
de revisión es siempre: ¿qué pasa cuando llegue un tipo nuevo?

**07 → 15. Escribe el Visitor clásico en Java para `lineaExtracto` sobre tres tipos de movimiento. 🔴**

⏱️ Una interfaz `VisitanteMovimiento<R>` con un `visitar` por tipo, un `aceptar` genérico en cada movimiento, y una clase
`LineaExtracto` que implementa los tres casos.
🗣️

```java
public interface VisitanteMovimiento<R> {
    R visitar(Deposito d);
    R visitar(Retiro r);
    R visitar(Comision c);
}
public interface Movimiento { <R> R aceptar(VisitanteMovimiento<R> v); }

public record Deposito(Dinero monto) implements Movimiento {
    public <R> R aceptar(VisitanteMovimiento<R> v) { return v.visitar(this); }
}
public record Retiro(Dinero monto, String cajero) implements Movimiento {
    public <R> R aceptar(VisitanteMovimiento<R> v) { return v.visitar(this); }
}
public record Comision(Dinero monto, String concepto) implements Movimiento {
    public <R> R aceptar(VisitanteMovimiento<R> v) { return v.visitar(this); }
}

public final class LineaExtracto implements VisitanteMovimiento<String> {
    public String visitar(Deposito d) { return "Depósito " + d.monto(); }
    public String visitar(Retiro r)   { return "Retiro en " + r.cajero() + " " + r.monto(); }
    public String visitar(Comision c) { return "Comisión: " + c.concepto() + " " + c.monto(); }
}

String linea = movimiento.aceptar(new LineaExtracto());
```

🔬 Lo que preguntará después: qué pasa si añades `TransferenciaEnviada` (no compila hasta que la interfaz y todos los
visitantes la traten: es la garantía del patrón); y por qué el genérico `<R>` en `aceptar` (para que cada visitante
devuelva su tipo sin acumular el resultado en un campo, como en el C++98).

**07 → 16. Reemplaza ese Visitor por una interfaz sellada con records y un `switch` exhaustivo. 🔴**

⏱️ Se borra la interfaz del visitante y los `aceptar`; se sella la interfaz con los tres records; la operación es una
función con un `switch` sin `default`.
🗣️

```java
public sealed interface Movimiento permits Deposito, Retiro, Comision { Dinero monto(); }
public record Deposito(Dinero monto) implements Movimiento {}
public record Retiro(Dinero monto, String cajero) implements Movimiento {}
public record Comision(Dinero monto, String concepto) implements Movimiento {}

static String lineaExtracto(Movimiento m) {
    return switch (m) {
        case Deposito d                    -> "Depósito " + d.monto();
        case Retiro(var monto, var cajero) -> "Retiro en " + cajero + " " + monto;
        case Comision c                    -> "Comisión: " + c.concepto() + " " + c.monto();
    };
}
```

🔬 Lo que preguntará después: dónde viven ahora las operaciones (en funciones o clases de servicio, no en los
movimientos: cada formato, con su módulo); y qué pasa si los records están en otro módulo que la interfaz (no se puede
sellar, y se vuelve al Visitor o a un método abstracto por operación).

**07 → 17. Escribe en C++ el efecto de cada movimiento en el saldo con `std::variant` y `std::visit`. 🔴**

⏱️ Un `std::variant` con los tipos de movimiento, el ayudante `overloads`, y una función que devuelve el efecto con
signo de cada uno.
🗣️

```cpp
template <class... Ts> struct overloads : Ts... { using Ts::operator()...; };

Dinero efectoEnSaldo(const Movimiento& m) {
    return std::visit(overloads{
        [](const Deposito& d)              { return d.monto; },
        [](const Retiro& r)                { return -r.monto; },
        [](const TransferenciaEnviada& t)  { return -t.monto; },
        [](const TransferenciaRecibida& t) { return t.monto; },
        [](const Comision& c)              { return -c.monto; },
    }, m);
}

Dinero saldo = std::accumulate(movs.begin(), movs.end(), Dinero::cero(),
                               [](Dinero acc, const Movimiento& m) { return acc + efectoEnSaldo(m); });
```

🔬 Lo que preguntará después: qué pasa si las lambdas devuelven tipos distintos (no compila: `std::visit` exige un tipo
de retorno común); y si se podría poner el signo en cada tipo (sí, como método de cada `struct`, si el efecto en el
saldo se considera propio del movimiento: entonces no hace falta visitar).

**07 → 18. Revisa este código: un `switch (m)` sobre `Movimiento` sellado con `default -> throw new IllegalStateException()`. Di qué pierde y cómo lo corriges. 🔴**

⏱️ Pierde la exhaustividad: con `default`, el compilador ya no avisa cuando aparece un tipo nuevo, y el error llega al
ejecutar. Sobre una jerarquía sellada, se quita el `default` y se tratan todos los casos.
🗣️ El `default` es el reflejo de la época sin sellados, cuando el compilador no podía saber que la lista estaba cerrada.
Con `sealed`, el `switch` sin `default` es exhaustivo y el compilador lo comprueba; con `default`, se vuelve a la
cadena de `instanceof` con otra sintaxis.
🔬 Lo que preguntará después: qué pasa si los records se compilan por separado y llega un tipo que el `switch` no
conocía (la JVM lanza `MatchException` al ejecutar; el compilador inserta esa red de seguridad); y cuándo un `default`
sí tiene sentido (sobre tipos abiertos, como `Object`, donde no hay exhaustividad posible).

# 08 — Iterator y Mediator

**08 → 1. ¿Cuál es la intención del Iterator? 🟢**

⏱️ Recorrer los elementos de una colección uno a uno sin exponer cómo está guardada: un objeto aparte lleva la
posición y ofrece "¿hay otro?" y "dame el siguiente".
🗣️ En Java es `Iterable` e `Iterator`, y el `for` mejorado los llama sin que se vea; en C++, `begin()` y `end()`, que
usa el `for` de rango. Es el patrón del GoF más absorbido por los lenguajes.
🔬 El GoF distingue iterador externo (el cliente pide el siguiente, como `Iterator`) e interno (la colección aplica una
función a cada elemento, como `forEach`).

**08 → 2. ¿Qué es un iterador *fail-fast*? 🟢**

⏱️ Uno que lanza `ConcurrentModificationException` si la colección cambia estructuralmente durante el recorrido por
otra vía que el propio iterador. Los de `ArrayList` y `HashMap` lo son.
🗣️ Falla pronto y de forma clara en lugar de dar resultados arbitrarios más tarde. Lo provoca también un solo hilo:
quitar un elemento de la lista dentro de un `for` mejorado.
🔬 La Javadoc avisa de que no está garantizado: es una ayuda para detectar errores. Las colecciones concurrentes usan
iteradores "débilmente consistentes", que no lanzan.

**08 → 3. ¿Cuál es la intención del Mediator? 🟢**

⏱️ Concentrar en un objeto la coordinación entre varios objetos, para que no se conozcan entre sí: cada uno avisa al
mediador y el mediador decide a quién afecta.
🗣️ En el formulario de alta, el selector de país, el de tipo, el campo del número y el botón de guardar solo conocen al
formulario; las reglas —cambiar el país cambia los tipos— viven en él.
🔬 El GoF lo presenta con los "directores de diálogo" de las interfaces gráficas. En el *backend* el equivalente es un
servicio que orquesta a varios colaboradores para un caso de uso.

**08 → 4. ¿Qué es `std::generator`? 🟢**

⏱️ Un tipo de C++23 que convierte una corrutina en un rango: la función entrega elementos con `co_yield`, y quien la
usa la recorre con un `for` de rango.
🗣️ Es la forma más corta de escribir un iterador a mano en C++: el estado del recorrido lo guarda la corrutina, sin
clase de iterador. Leer movimientos por páginas sería un bucle con `co_yield` por movimiento.
🔬 Java no tiene generadores en el lenguaje; lo más parecido es escribir un `Iterator` o un `Spliterator`, o usar
`Stream.iterate` y `Stream.generate` para casos simples.

**08 → 5. ¿Qué diferencia hay entre `Iterable` y `Stream`? 🟡**

⏱️ Un `Iterable` da un iterador nuevo en cada recorrido y se puede recorrer muchas veces; un `Stream` se consume una
sola vez y está pensado para encadenar operaciones.
🗣️ Por eso un método que devuelve `Iterable` o una colección deja recorrer de nuevo, y uno que devuelve `Stream`
obliga al cliente a decidir en una sola pasada. Un `Stream` además puede ser perezoso y paralelo.
🔬 Bloch, ítem 47 de *Effective Java*: preferir devolver `Collection` a `Stream` como tipo de retorno, porque sirve
para los dos usos.

**08 → 6. ¿Qué diferencia hay entre Mediator y Observer? 🟡**

⏱️ En el Observer el emisor notifica y cada suscriptor reacciona por su cuenta: nadie decide. En el Mediator, el
mediador recibe los avisos y **decide** a quién más afecta y cómo.
🗣️ Los colegas de un Mediator suelen avisarle con un Observer, y el mediador los manda directamente. El Mediator es
coordinación con reglas; el Observer, difusión sin reglas.
🔬 Ver `03 → 9`. Un sistema de eventos con muchos oyentes que se disparan entre sí sin un coordinador termina siendo
un Mediator implícito y difícil de seguir.

**08 → 7. ¿Qué diferencia hay entre Mediator y Facade? 🟡**

⏱️ La fachada simplifica el acceso a un subsistema que no la conoce, en un solo sentido; los colegas de un Mediator sí
conocen al mediador y le hablan, en los dos sentidos.
🗣️ `AltaPersonas` llama al repositorio y al notificador, que no saben de ella: es una fachada. El formulario recibe
avisos de sus componentes y les da órdenes: es un mediador.
🔬 Los dos centralizan y los dos pueden degenerar en clase dios. Ver `05/04 → 6`.

**08 → 8. ¿Qué diferencia hay entre el par `begin()`/`end()` de C++ y el `Iterator` de Java? 🟡**

⏱️ En C++ un recorrido son dos iteradores, el inicio y el final, y el iterador se parece a un puntero (`*it`, `++it`);
en Java es un solo objeto con `hasNext()` y `next()`.
🗣️ El par de C++ permite recorrer un subrango y que los algoritmos de la STL trabajen con cualquier contenedor; desde
C++20, los rangos agrupan el par en un objeto y se componen con `|`. El `Iterator` de Java es más simple y menos
general.
🔬 Los iteradores de C++ tienen categorías (de entrada, bidireccionales, de acceso aleatorio) que dicen qué algoritmos
admiten; Java no tiene esa jerarquía, salvo `ListIterator`.

**08 → 9. ¿Por qué "hay que implementar Iterator a mano" es una idea vieja? 🟠**

⏱️ Porque cada colección del lenguaje trae su iterador y la sintaxis lo llama: el `for` mejorado de Java y el `for` de
rango de C++. Escribirlo es la excepción.
🗣️ La idea viene de los libros escritos antes de que el lenguaje lo absorbiera. Hoy, para recorrer, se usa la colección;
para transformar mientras se recorre, `Stream` o los rangos.
🔬 Es el mejor ejemplo de la tesis del corpus: el patrón no desapareció, se volvió una característica del lenguaje.

**08 → 10. ¿Cuándo sí escribirías un iterador a mano? 🟠**

⏱️ Para fuentes que no están en memoria —páginas de una base, un archivo grande, un cursor— y para estructuras propias,
como un árbol que se recorre en profundidad.
🗣️ Los movimientos de un año de la cuenta de Ana, leídos de quinientos en quinientos: el iterador pide la siguiente
página solo cuando se agota la actual, y quien recorre usa un `for` normal.
🔬 Hay que cuidar que cada `iterator()` empiece un recorrido nuevo, que `next()` lance `NoSuchElementException` al
final, y qué pasa si los datos cambian entre páginas.

**08 → 11. ¿Cuándo un Mediator se convierte en un God Object? 🟠**

⏱️ Cuando un solo mediador coordina demasiados colegas y conversaciones: diez pantallas, cuarenta componentes, todas
las reglas de interacción de la aplicación en una clase.
🗣️ Cambia por cualquier motivo y nadie se atreve a tocarlo. La salida es un mediador por conversación (un formulario,
un caso de uso), no uno para la aplicación.
🔬 El síntoma en el código es un mediador con decenas de métodos privados `xCambio` y dependencias de todo. El antipatrón
y su salida son de [`12/03` §2](../12-antipatrones/03-antipatrones-de-diseno-oo.md#2-️-god-object).

**08 → 12. ¿Por qué quitar elementos dentro de un `for` mejorado lanza `ConcurrentModificationException`, y cómo se hace bien? 🟠**

⏱️ Porque el `for` mejorado usa un iterador, y quitar con `lista.remove(x)` modifica la colección por fuera del
iterador; el iterador *fail-fast* lo detecta en el siguiente `next()` y lanza.
🗣️ Se hace bien con `documentos.removeIf(d -> d.vencido(hoy))`, que lo resuelve la colección, o con el iterador
explícito y su propio `remove()`:

```java
for (Iterator<Documento> it = documentos.iterator(); it.hasNext(); )
    if (it.next().vencido(hoy)) it.remove();
```

🔬 La excepción no indica otro hilo: es un solo hilo violando el contrato del recorrido. Con varios hilos de verdad, hace
falta una colección concurrente o sincronización, no esquivar la excepción.

**08 → 13. Escribe un `Iterable<Movimiento>` que lea los movimientos de una cuenta por páginas. 🔴**

⏱️ Una clase `Iterable` cuyo `iterator()` guarda la página actual y la posición, y pide la siguiente página al
repositorio cuando se agota la actual.
🗣️

```java
public final class MovimientosDeCuenta implements Iterable<Movimiento> {
    private final RepositorioMovimientos repo;
    private final CuentaId cuenta;
    private final int tamanio;

    public MovimientosDeCuenta(RepositorioMovimientos repo, CuentaId cuenta, int tamanio) {
        this.repo = repo; this.cuenta = cuenta; this.tamanio = tamanio;
    }
    @Override public Iterator<Movimiento> iterator() {
        return new Iterator<>() {
            private List<Movimiento> pagina = List.of();
            private int pos = 0, numero = 0;
            private boolean agotado = false;
            @Override public boolean hasNext() {
                if (pos < pagina.size()) return true;
                if (agotado) return false;
                pagina = repo.pagina(cuenta, numero++, tamanio);
                pos = 0;
                agotado = pagina.size() < tamanio;
                return !pagina.isEmpty();
            }
            @Override public Movimiento next() {
                if (!hasNext()) throw new NoSuchElementException();
                return pagina.get(pos++);
            }
        };
    }
}
```

🔬 Lo que preguntará después: qué pasa si se insertan movimientos mientras se recorre (con paginación por número de
página, uno puede saltarse o repetirse; mejor paginar por "después del último identificador leído"); y cómo lo
convertirías en `Stream` (`StreamSupport.stream(iterable.spliterator(), false)`).

**08 → 14. Rediseña con un Mediator el formulario de alta en el que país, tipo y número se actualizan unos a otros con referencias cruzadas. 🔴**

⏱️ Los componentes dejan de conocerse: cada uno expone un `alCambiar(...)`, y un `FormularioAltaDocumento` se suscribe a
todos y aplica las reglas de coordinación.
🗣️

```java
public final class FormularioAltaDocumento {
    private final SelectorPais pais;
    private final SelectorTipo tipo;
    private final CampoNumero numero;
    private final BotonGuardar guardar;
    private final CatalogoTipos catalogo;

    public FormularioAltaDocumento(SelectorPais p, SelectorTipo t, CampoNumero n, BotonGuardar g, CatalogoTipos c) {
        pais = p; tipo = t; numero = n; guardar = g; catalogo = c;
        pais.alCambiar(x -> { tipo.opciones(catalogo.dePais(x)); numero.limpiar(); guardar.habilitado(false); });
        tipo.alCambiar(x -> { numero.formato(x.formato()); validar(); });
        numero.alCambiar(x -> validar());
    }
    private void validar() {
        TipoDocumento t = tipo.seleccionado();
        guardar.habilitado(t != null && t.formato().matcher(numero.valor()).matches());
    }
}
```

🔬 Lo que preguntará después: cómo se prueba (con componentes falsos, comprobando que cambiar el país vacía el número
y deshabilita el botón: las reglas están en una clase); y qué pasa si el formulario crece a veinte campos (se parte por
grupos de campos que se coordinan entre sí, cada grupo con su mediador).

# 09 — Memento e Interpreter

**09 → 1. ¿Cuál es la intención de Memento? 🟢**

⏱️ Guardar el estado interno de un objeto sin romper su encapsulación, para poder restaurarlo después: deshacer.
🗣️ Un borrador de persona en edición crea una instantánea antes de cada cambio; un historial las guarda sin poder
leerlas ni modificarlas, y solo el borrador sabe restaurarse desde una.
🔬 El GoF lo presenta con un editor gráfico que deshace movimientos. Hoy se escribe poco: la inmutabilidad ocupa su
lugar.

**09 → 2. ¿Cuál es la intención de Interpreter? 🟢**

⏱️ Representar cada regla de una gramática pequeña como una clase, y evaluar una frase recorriendo el árbol de objetos
que la representa.
🗣️ Los requisitos de una campaña, `edad >= 18 Y pais = CO`, como un árbol: un `Y` con un `EdadMinima` y un `PaisEs`.
Evaluar sobre una persona es recorrer el árbol.
🔬 El patrón no cubre cómo se convierte el texto en el árbol: eso es un *parser*. Es un Composite con una operación de
evaluación.

**09 → 3. ¿Qué papeles tienen el *originator* y el *caretaker*? 🟢**

⏱️ El *originator* es el objeto cuyo estado se guarda: crea el memento y es el único que sabe aplicarlo. El *caretaker*
guarda los mementos y los devuelve, sin mirar dentro.
🗣️ El borrador es el *originator*; la pila de deshacer, el *caretaker*. Así la pila no depende de los campos del
borrador, y el borrador no expone sus campos a la pila.
🔬 En C++ el GoF lo protegía con un memento de interfaz estrecha para todos y ancha para el originador (`friend`). En
Java, un record anidado inmutable y métodos de restaurar en el originador cumplen lo mismo.

**09 → 4. ¿Qué son las *expression trees* de C#? 🟢**

⏱️ Lambdas que el compilador no convierte en código ejecutable sino en un árbol de objetos que describe la expresión,
cuando se asignan a `Expression<Func<...>>`.
🗣️ Ese árbol se puede recorrer y traducir: los proveedores de LINQ, como Entity Framework, lo convierten en SQL. Es el
árbol del Interpreter, generado por el lenguaje.
🔬 Java no tiene un equivalente en el lenguaje; los *Criteria* de JPA construyen árboles parecidos a mano, con una API.

**09 → 5. ¿Qué diferencia hay entre deshacer con Memento y con objetos inmutables? 🟡**

⏱️ Con Memento, el objeto es mutable y se guardan instantáneas para restaurarlo; con objetos inmutables, cada cambio
produce un objeto nuevo y deshacer es volver a la referencia anterior.
🗣️ La inmutabilidad elimina el memento, el método de restaurar y el riesgo de que la instantánea comparta algo mutable
con el original. El historial es simplemente una lista de versiones.
🔬 El precio es crear un objeto por cambio; con objetos pequeños es despreciable, y las estructuras persistentes
comparten lo que no cambió.

**09 → 6. ¿Qué diferencia hay entre Interpreter y Composite? 🟡**

⏱️ El Interpreter es un Composite con una operación concreta: evaluar una gramática. Las reglas compuestas (`Y`, `O`)
son los compuestos y las simples (`EdadMinima`) las hojas.
🗣️ El Composite es la estructura parte-todo; el Interpreter le da el significado de un lenguaje. Por eso el árbol de
reglas de validación de `05/08` E5 se parece tanto a este.
🔬 La operación de interpretar puede vivir en los nodos (la forma del GoF) o fuera, en un `switch` sellado o un Visitor.

**09 → 7. ¿Qué diferencia hay entre Memento y Command para deshacer? 🟡**

⏱️ El Memento guarda el estado anterior y lo restaura; el Command guarda la operación y ejecuta su inversa.
🗣️ En un editor, el memento suele ser más simple: guardar el texto y volver. En una cuenta, el inverso es lo correcto:
la transferencia compensatoria queda en la historia. El Memento no sirve para deshacer efectos fuera del objeto (un
correo enviado).
🔬 Se combinan cuando una operación no tiene inverso: el comando guarda un memento antes de ejecutar. Ver `04 → 6`.

**09 → 8. ¿Por qué "Interpreter se usa para escribir lenguajes" es una sobregeneralización? 🟠**

⏱️ Porque el patrón solo sirve para gramáticas pequeñas y estables, y no cubre el análisis del texto. Para un lenguaje
de verdad, el propio GoF recomienda herramientas como los generadores de *parsers*.
🗣️ Con precedencia, paréntesis y funciones, la jerarquía de clases crece sin control y el intérprete de árbol es lento.
Lo que queda útil del patrón es la idea de la regla como árbol de objetos.
🔬 Nystrom lo explica en el capítulo "Bytecode": los intérpretes serios compilan el árbol a instrucciones de una máquina
virtual en lugar de recorrerlo.

**09 → 9. ¿Qué reemplazó a Memento, y por qué? 🟠**

⏱️ La inmutabilidad: si cada cambio produce un objeto nuevo, guardar el estado anterior es guardar la referencia al
objeto anterior, sin memento ni restauración.
🗣️ Para la historia del negocio, un historial de eventos del que se reconstruye el estado; para operaciones
reversibles, el comando con su inverso. El Memento queda para objetos mutables, encapsulados y sin inverso.
🔬 En interfaces de usuario, el estado como secuencia de valores inmutables hace que "deshacer" sea mover un índice.

**09 → 10. ¿Cuándo usarías SpEL o un motor de reglas en lugar de escribir un Interpreter? 🟠**

⏱️ Cuando las reglas se escriben como texto y cambian sin desplegar, y su lenguaje es el de las expresiones comunes:
comparaciones, operadores lógicos, acceso a propiedades. SpEL ya lo evalúa contra un objeto.
🗣️ Un motor de reglas compensa cuando hay muchas reglas, con prioridades y encadenamiento, mantenidas por el negocio.
Escribir un Interpreter propio solo tiene sentido con una gramática pequeña y muy específica del dominio.
🔬 Evaluar texto que escribe un usuario con un lenguaje de expresión potente es un riesgo de seguridad: SpEL puede
llamar a métodos arbitrarios. Hay que restringir el contexto de evaluación.

**09 → 11. Escribe un Memento para un borrador de persona con nombre y dirección, y un historial de deshacer. 🔴**

⏱️ Un record anidado e inmutable como instantánea, `guardar()` y `restaurar()` en el borrador, y una pila de
instantáneas como historial.
🗣️

```java
public final class BorradorPersona {
    private String nombre;
    private Direccion domicilio;                        // Direccion es inmutable: se puede compartir

    public record Instantanea(String nombre, Direccion domicilio) {}

    public Instantanea guardar() { return new Instantanea(nombre, domicilio); }
    public void restaurar(Instantanea i) { this.nombre = i.nombre(); this.domicilio = i.domicilio(); }
    public void cambiarNombre(String n) { this.nombre = n; }
    public void mudarse(Direccion d) { this.domicilio = d; }
}

public final class HistorialEdicion {
    private final Deque<BorradorPersona.Instantanea> pila = new ArrayDeque<>();
    public void antesDeCambiar(BorradorPersona b) { pila.push(b.guardar()); }
    public void deshacer(BorradorPersona b) { if (!pila.isEmpty()) b.restaurar(pila.pop()); }
}
```

🔬 Lo que preguntará después: qué pasa si el borrador tuviera una lista de contactos (la instantánea tendría que copiarla:
`List.copyOf`, o el pasado cambiaría con el presente); y cómo lo harías sin Memento (con una `Persona` inmutable y una
lista de versiones).

**09 → 12. Extiende el árbol de requisitos de §3 con una negación (`NO`) y evalúa "mayor de edad y no mexicano". 🔴**

⏱️ Un record `No(Requisito r)` en la lista `permits`, un caso más en el `switch`, y el árbol `Y(EdadMinima(18),
No(PaisEs("MX")))`.
🗣️

```java
public sealed interface Requisito permits EdadMinima, PaisEs, Y, O, No {}
public record No(Requisito r) implements Requisito {}

static boolean cumple(Requisito r, Persona p, LocalDate hoy) {
    return switch (r) {
        case EdadMinima e -> p.edad(hoy) >= e.anios();
        case PaisEs c     -> p.nacionalidad().codigoIso().equals(c.iso());
        case Y y          -> cumple(y.izq(), p, hoy) && cumple(y.der(), p, hoy);
        case O o          -> cumple(o.izq(), p, hoy) || cumple(o.der(), p, hoy);
        case No n         -> !cumple(n.r(), p, hoy);
    };
}

Requisito r = new Y(new EdadMinima(18), new No(new PaisEs("MX")));
boolean anaCumple = cumple(r, ana, LocalDate.of(2026, 10, 3));       // → true: 38 años, colombiana
boolean carmenCumple = cumple(r, carmen, LocalDate.of(2026, 10, 3)); // → false: mexicana
```

🔬 Lo que preguntará después: qué pasa con los `switch` que ya existían sobre `Requisito` (dejan de compilar hasta que
traten `No`: la exhaustividad avisa); y cómo se leería esto desde un texto (con un *parser*; para una gramática así de
pequeña, un descendente recursivo escrito a mano cabe en cincuenta líneas, y más allá, ANTLR).

# 10 — Simulación de entrevista

Las `S#` que ya son preguntas de capítulo remiten a su respuesta; las demás, en tres capas. Los
ejercicios, desarrollados al final.

**10 → S1. ¿Qué diferencia hay entre Strategy, State y Template Method? 🟡**

Ver `01 → 5`, `01 → 6` y `06 → 5`.

**10 → S2. ¿Por qué una lambda puede ser una estrategia? 🟢**

Ver `01 → 3`.

**10 → S3. ¿Por qué `JdbcTemplate` no es un Template Method en sentido estricto? 🟠**

Ver `02 → 9`.

**10 → S4. ¿Cuándo un `switch` es mejor que un Strategy? 🟠**

Ver `01 → 11`.

**10 → S5. ¿Qué es el idioma NVI de C++? 🟢**

Ver `02 → 3`.

**10 → S6. ¿Qué diferencia hay entre Observer y publicar/suscribir con un *broker*? 🟡**

Ver `03 → 5`.

**10 → S7. ¿Por qué un observador olvidado provoca una fuga de memoria? 🟠**

Ver `03 → 10`.

**10 → S8. ¿Los eventos de Spring son síncronos o asíncronos, y qué implica? 🟡**

Ver `03 → 7` y `03 → 18`.

**10 → S9. ¿Por qué `Runnable` es un Command incompleto? 🟢**

Ver `04 → 3`.

**10 → S10. ¿Por qué deshacer una transferencia no es borrarla? 🟠**

Ver `04 → 8`.

**10 → S11. ¿Qué diferencia hay entre la cadena que se corta y la que acumula? 🟡**

Ver `05 → 5`.

**10 → S12. ¿Qué diferencia hay entre Chain of Responsibility, Observer y Mediator? 🟡**

⏱️ La cadena busca **uno** que atienda la petición, en orden; el Observer entrega la notificación a **todos**, sin que
nadie decida; el Mediator recibe los avisos y **decide** quién reacciona y cómo.
🗣️ La aprobación por monto es una cadena; el aviso de vencimiento, un Observer; el formulario de alta donde el país
cambia los tipos y el tipo cambia el formato, un Mediator. Tres formas de que objetos que no se conocen colaboren.
🔬 Ver `05 → 7` y `08 → 6`. La pregunta que los separa es cuántos reciben la petición y quién decide.

**10 → S13. ¿Por qué dos *flags* booleanos son peores que un estado? 🟠**

Ver `06 → 9`.

**10 → S14. ¿Cuándo usarías una interfaz sellada con records en lugar de un `enum` para los estados? 🟠**

Ver `06 → 10`.

**10 → S15. ¿Qué es el *double dispatch*, y por qué existe Visitor? 🟢**

Ver `07 → 2`.

**10 → S16. ¿Cuándo Visitor todavía gana a los tipos sellados? 🟠**

Ver `07 → 12`.

**10 → S17. ¿Qué pierde un `switch` sobre un tipo sellado si tiene `default`? 🟠**

Ver `07 → 18`.

**10 → S18. ¿Por qué casi nunca se escribe un Iterator a mano? 🟠**

Ver `08 → 9` y `08 → 10`.

**10 → S19. ¿Qué reemplazó a Memento? 🟠**

Ver `09 → 9`.

**10 → S20. ¿Qué queda vivo de Interpreter? 🟡**

⏱️ La idea de que una regla puede ser un árbol de objetos que se evalúa. Lo que se dejó de escribir es la jerarquía de
clases por cada regla de una gramática y el intérprete hecho a mano.
🗣️ El árbol sigue en el patrón Specification (reglas combinables con nombre de dominio), en las *expression trees* de
C#, en los *Criteria* de JPA y en cualquier `sealed interface` de reglas con un `switch` que las evalúa. El análisis del
texto lo hacen los lenguajes de expresión (SpEL) y los generadores de *parsers*.
🔬 Ver `09 → 8` y `09 → 10`.

**10 → S21. Nombra tres patrones de este bloque que una lambda reduce a una línea, y uno que no. 🟡**

⏱️ Strategy (la lambda es la estrategia), Command sin deshacer (la lambda es la petición) y Observer (la lambda es el
suscriptor). State no: los estados llevan transiciones y, a menudo, datos, y una lambda no los representa.
🗣️ El patrón común es que una interfaz de un solo método, sin estado, se vuelve una lambda. En cuanto hacen falta varias
operaciones relacionadas, datos o identidad (un comando que se audita y se revierte), vuelve el tipo con nombre.
🔬 Template Method también se reduce si el paso variable se pasa como lambda, pero entonces deja de ser Template Method:
es una estrategia.

**10 → S22. ¿Qué diferencia hay entre `std::function` y un parámetro de plantilla como estrategia? 🟡**

Ver `01 → 7`.

**10 → S23. ¿Qué diferencia hay entre el Visitor clásico en C++ y `std::variant` con `std::visit`? 🟡**

Ver `07 → 7`.

**10 → S24. ¿Cómo evita C++ moderno el observador colgante? 🟠**

⏱️ Con una suscripción RAII que se desuscribe al destruirse, o guardando `std::weak_ptr` a los observadores y
descartando los que expiraron al notificar.
🗣️ El problema de C++ es el contrario que el de Java: un observador destruido sin desuscribirse deja un puntero
colgante en el sujeto. La suscripción RAII ata la desuscripción a la vida de un objeto; el `weak_ptr`, a la vida del
observador, sin mantenerlo vivo.
🔬 Ver `03 → 16`. La suscripción debe morir antes que el sujeto; si no se puede garantizar, el sujeto vive en un
`shared_ptr` y la suscripción guarda un `weak_ptr` a él.

**10 → S25. ¿Qué aportan los `event` de C# al Observer, y qué no resuelven? 🟡**

⏱️ Aportan el patrón en el lenguaje: la lista de suscriptores, la suscripción con `+=` y la notificación. No resuelven
la desuscripción: un suscriptor olvidado queda vivo mientras viva el objeto que publica.
🗣️ Es la misma fuga que en Java, con otra sintaxis. Las salidas también son las mismas: desuscribirse con `-=` al
terminar, objetos `IDisposable` que lo hagan, o patrones de eventos débiles.
🔬 Ver `03 → 8`.

**10 → S26. "Strategy y State son el mismo patrón con otro nombre." ¿Qué respondes? 🔴**

⏱️ Que tienen el mismo diagrama y distinta intención. En Strategy, el algoritmo lo elige alguien de fuera y no cambia
solo; en State, el comportamiento lo cambian las propias operaciones del objeto, con transiciones.
🗣️ La comisión por tipo de cuenta no cambia porque la cuenta opere; el estado de la cuenta sí cambia al bloquearla, y
después `debitar` se comporta distinto. En el código se nota en que los estados se conocen entre sí (uno devuelve al
otro) y las estrategias no.
🔬 Se puede conceder que la mecánica es la misma: un objeto que delega en otro detrás de una interfaz. La diferencia es
de diseño, y por eso los dos nombres sirven: dicen quién decide.

**10 → S27. "En mi equipo prohibimos los `switch`: todo se resuelve con polimorfismo." ¿Estás de acuerdo? 🔴**

⏱️ No del todo. Un `switch` repetido por todo el código sobre un tipo que crece es un problema; un `switch` exhaustivo
sobre un `enum` o un tipo sellado, en un solo sitio, es la forma más legible y el compilador comprueba que no falte un
caso.
🗣️ El polimorfismo es mejor cuando el comportamiento es del objeto y los tipos crecen; el `switch` sellado, cuando las
operaciones crecen y los tipos son estables. Es el *expression problem*: ninguna de las dos formas es mejor siempre.
🔬 Con Java 21, el `switch` de patrones sobre tipos sellados es justamente lo que reemplaza a Visitor. Prohibirlo obliga
a volver al patrón más difícil de leer del GoF.

**10 → S28. El entrevistador te pide implementar Visitor en Java 21. ¿Qué haces? 🔴**

⏱️ Lo escribo si lo pide, porque está evaluando si conozco el *double dispatch*: interfaz del visitante, `aceptar` en
cada elemento. Y después digo que en Java 21 usaría una interfaz sellada con un `switch` exhaustivo.
🗣️ Explico por qué `aceptar` no se hereda, y cuándo seguiría usando Visitor: jerarquías ajenas abiertas, Java 17, tipos
en varios módulos. Mostrar las dos formas y el criterio vale más que solo una.
🔬 Ver `07 → 15` y `07 → 16`. Si el entrevistador insiste en que Visitor es "la forma correcta", se puede preguntar qué
ventaja busca sobre el `switch`: a menudo es el recorrido de un árbol, y ahí Visitor sí aporta.

**10 → S29. "Los eventos de Spring desacoplan, así que todo debería comunicarse por eventos." ¿Qué le dices? 🔴**

⏱️ Que desacoplan al emisor de los receptores, a cambio de esconder el flujo: para saber qué pasa al guardar una persona
hay que buscar todos los oyentes. Los uso donde los receptores cambian y el emisor no debe conocerlos, no para todo.
🗣️ Además, por defecto son síncronos: no desacoplan en el tiempo ni aíslan fallos, y un oyente que lanza afecta al
emisor y puede deshacer su transacción. Una secuencia que tiene orden y dependencias se escribe como secuencia.
🔬 Un sistema donde todo se comunica por eventos acaba siendo un Mediator implícito que nadie puede leer. Ver `03 → 14`.

**10 → S30. "¿Para qué Command si existe `Runnable`?" 🔴**

⏱️ Porque `Runnable` es la mitad del patrón: ejecutar después. El Command completo es la petición como dato: con sus
campos visibles, que se guarda, se audita, se programa y se revierte.
🗣️ Una transferencia programada para el mes que viene en una cola de `Runnable` se pierde con un reinicio y nadie puede
consultar cuál era. Como `record Transferencia`, se guarda en una tabla, se audita y se compensa.
🔬 Para "ejecuta esto en otro hilo", `Runnable` basta y es lo correcto. Ver `04 → 3` y `04 → 14`.

**10 → S31. Te piden "el patrón de comportamiento que más usas". ¿Qué respondes, y cómo lo defiendes? 🔴**

⏱️ Strategy, casi siempre como una interfaz funcional y lambdas: cada `Comparator`, cada política de negocio que se
inyecta. Y lo defiendo por lo que evita: un `switch` que crece con cada caso.
🗣️ Doy un ejemplo propio del dominio (la comisión por tipo de cuenta en un mapa de lambdas) y digo cuándo no lo uso:
con tres reglas estables, el `switch` exhaustivo. Mencionar el precio es lo que convierte la respuesta en criterio.
🔬 Otras respuestas válidas: Observer (eventos de dominio), Command (operaciones que se auditan), Chain (filtros). Lo
que importa no es cuál, sino el caso concreto y el "cuándo no".

**10 → S32. "Template Method es herencia, y la herencia es mala: nunca lo usaría." ¿Qué matizas? 🔴**

⏱️ Que la herencia de implementación tiene precio —la clase base frágil, el flujo *yo-yo*— pero no es mala por sí misma.
Template Method con el esqueleto `final` y pocos pasos relacionados es razonable cuando la jerarquía ya existe.
🗣️ El JDK lo usa bien en `AbstractList` y `HttpServlet`. Lo que sí haría es preferir composición cuando varía un solo
paso (pasarlo como lambda) o cuando hay varias dimensiones que combinar.
🔬 Ver `02 → 11` y `02 → 12`. "Nunca" es la palabra que hay que evitar: la respuesta precisa dice cuándo.

---

**10 → E1. Tres enunciados, tres patrones.**

**Enunciado.** Interés por producto que crece; trámite con estados y acciones permitidas por estado; exportaciones con
los mismos pasos y formato distinto.

**El primer diseño que sale.** Strategy para los tres, porque "todo es algo intercambiable".

**El bueno.**

1. **Interés por producto: Strategy.** Lo que varía es el cálculo, lo elige el producto contratado y no cambia por
   operar. Una interfaz funcional `CalculoInteres` y un mapa por producto; los productos nuevos son entradas.
2. **Trámite de apertura: State.** El comportamiento depende del estado, y las propias acciones (`aprobar`,
   `rechazar`) lo cambian. Un `enum` con un método por acción que devuelve el estado siguiente, o una interfaz sellada si
   los estados llevan datos (el motivo del rechazo).
3. **Exportaciones: Template Method, o composición.** Los pasos y su orden son fijos y varían dos pasos relacionados
   (cabecera y filas): un `Exportador` abstracto con `exportar` `final`. Si solo variara un paso, un exportador `final`
   que recibe el formato como estrategia.

**Lo que cuesta.** Strategy: la regla de cada producto lejos de quien la usa. State: los estados se conocen entre sí.
Template Method: herencia y clase base frágil.

**Lo que preguntará después.** Si el trámite no podría ser una tabla de transiciones (sí, si los estados los configura
el negocio); y si las exportaciones no serían mejor un Builder del GoF (si lo que varía es la representación y hay un
director que recorre algo, es justamente eso; el Template Method es más simple si no hay recorrido).

**10 → E2. El Visitor de los movimientos.**

**Enunciado.** Cuatro visitantes sobre cinco records con `aceptar`, en un proyecto que pasó a Java 21.

**El primer diseño que sale.** Dejarlo como está "porque funciona".

**El bueno.** Sellar la interfaz `Movimiento` con sus cinco records, borrar `aceptar` y la interfaz del visitante, y
convertir cada visitante en una función con un `switch` exhaustivo, sin `default`:

```java
public sealed interface Movimiento
        permits Deposito, Retiro, TransferenciaEnviada, TransferenciaRecibida, Comision { Dinero monto(); }

static Dinero efectoEnSaldo(Movimiento m) {
    return switch (m) {
        case Deposito d               -> d.monto();
        case Retiro r                 -> r.monto().negado();
        case TransferenciaEnviada t   -> t.monto().negado();
        case TransferenciaRecibida t  -> t.monto();
        case Comision c               -> c.monto().negado();
    };
}
```

Se **conserva** la garantía: un tipo nuevo hace que no compile ninguna operación que no lo trate. Se **gana** un tercio
del código, la lectura de arriba abajo y el poder desestructurar con *record patterns*.

**Lo que cuesta.** Que los records y la interfaz tienen que vivir en el mismo módulo (o paquete); y una refactorización
que toca los cuatro visitantes, que se puede hacer de a uno.

**Lo que preguntará después.** Si hay algún visitante que convenga dejar (si recorre un árbol y la estructura controla el
recorrido, sí); y qué pasa si alguien añade `default` "por si acaso" (se pierde la exhaustividad: ver `07 → 18`).

**10 → E3. Los avisos de vencimiento sin fugas.**

**Enunciado.** Avisar al titular y a su tutora, marcar en las pantallas abiertas del panel y auditar, sin enviar correos si
la revisión falla a mitad.

**El primer diseño que sale.** Que las pantallas se suscriban en su constructor a un servicio *singleton* y que el
correo se envíe dentro del bucle de la revisión.

**El bueno.** Un Observer con suscripciones que se cierran, y dos momentos distintos:

- **Suscripción con ciclo de vida**: `suscribir` devuelve un `AutoCloseable`; cada pantalla guarda su suscripción y la
  cierra al cerrarse. Sin eso, la fuga de `03` §6.
- **Lo que debe ir con la revisión** (marcar en el panel, auditar): síncrono, en el mismo hilo.
- **Lo que no debe salir si falla** (el correo): después de que la revisión termine y confirme. Con Spring, un
  `@TransactionalEventListener` en la fase posterior a la confirmación.

```java
public AutoCloseable suscribir(ObservadorVencimientos o) {
    observadores.add(o);
    return () -> observadores.remove(o);
}

@TransactionalEventListener                          // AFTER_COMMIT por defecto
void avisar(DocumentoPorVencer e) {
    avisos.enviarPorVencer(e.titular(), e.documento());
    if (e.titularEsMenor()) avisos.enviarPorVencer(e.tutor(), e.documento());
}
```

**Lo que cuesta.** Dos mecanismos (el Observer propio para las pantallas y los eventos de Spring para el correo) y la
disciplina de cerrar suscripciones. Y si el servidor se cae entre la confirmación y el envío, el correo se pierde.

**Lo que preguntará después.** Cómo garantizar el correo ante una caída (guardar el evento en la misma transacción y
enviarlo después: mensajería fiable, fuera de este corpus); y por qué no referencias débiles para las pantallas (porque
hay un momento claro de cierre: la suscripción explícita es más predecible).

**10 → E4. El texto del estado.**

**Enunciado.** Texto y color por estado de cuenta en una pantalla; un compañero propone una interfaz, tres
implementaciones y un mapa.

**El primer diseño que sale.** El del compañero, o peor: un método `color()` en el `enum` de dominio, mezclando
presentación con dominio.

**El bueno.** Un `switch` exhaustivo sobre el `enum` cerrado, en la capa de presentación:

```java
static Presentacion de(EstadoCuenta e) {
    return switch (e) {
        case ABIERTA   -> new Presentacion("Abierta", "verde");
        case BLOQUEADA -> new Presentacion("Bloqueada", "ámbar");
        case CERRADA   -> new Presentacion("Cerrada", "gris");
    };
}
```

**Lo que cuesta.** Nada. Si aparece `EMBARGADA`, este `switch` no compila hasta que la trate, que es exactamente lo que se
quiere. El `switch` sobre un `enum` como expresión es exhaustivo también en Java 17.

**Lo que preguntará después.** Por qué no en el `enum` (porque el color es de la pantalla, no del dominio, y otra pantalla
podría usar otros); y cuándo cambiarías de opinión (si la presentación por estado se configura por cliente: entonces es
un dato en un mapa, no código).

**10 → E5. La aprobación que nadie atiende.**

**Enunciado.** Una cadena con el filtro de listas después de la aprobación automática, sin eslabón final, y un `aprobar`
que devuelve `null` si nadie atiende.

**El primer diseño que sale.** Cambiar el `return null` por una excepción y dejarlo así.

**El bueno.** Los defectos, por gravedad:

1. **Orden**: la aprobación automática va antes que el filtro de listas, así que una transferencia pequeña a una cuenta
   restringida se aprueba sin pasar por el filtro. El orden es la regla.
2. **Final**: por encima de 50 000 000 COP nadie atiende y `aprobar` devuelve `null`; el llamador probablemente lo trata
   como aprobada o falla con `NullPointerException` lejos de aquí.
3. **Cadena incompleta**: faltan gerencia y comité.

```java
var cadena = List.<Aprobador>of(
        new FiltroListasRestrictivas(listas),                               // primero, siempre
        hastaMonto(Dinero.cop("5000000.00"),   t -> Aprobacion.automatica()),
        hastaMonto(Dinero.cop("50000000.00"),  supervisores::pedir),
        hastaMonto(Dinero.cop("500000000.00"), gerencia::pedir),
        t -> Optional.of(comite.pedir(t)));                                 // el último atiende siempre

public Aprobacion aprobar(Transferencia t) {
    for (Aprobador a : cadena) {
        Optional<Aprobacion> r = a.aprobar(t);
        if (r.isPresent()) return r.get();
    }
    return Aprobacion.rechazada("nadie la atendió");                       // no debería pasar, y si pasa, se rechaza
}
```

**Lo que cuesta.** Nada que no se debiera pagar. Un test por rango de monto, y uno con una cuenta restringida y un monto
pequeño, habrían encontrado los dos primeros defectos.

**Lo que preguntará después.** Cómo evitar que alguien vuelva a desordenar la cadena (armarla en un solo sitio con un
nombre, y un test que la recorra); y si devolver `Optional<Aprobacion>` desde `aprobar` sería mejor que rechazar (no: con
dinero, la ausencia de aprobación es un rechazo explícito).
