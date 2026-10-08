# 🧬 Fase 01 — Tipos, valor y referencia, `record`, propiedades, igualdad

> C# para desarrolladores Java senior · Fase 01 de 24 · Bloque A — el lenguaje y el runtime
> Depende de: 00 · Habilita: 02
> Estilo de esta fase: **nuevo** (.NET 10, C# 14)
> Proyecto que avanza: **nace el modelo de dominio**. Al terminar existe `Cordillera.Domain` con
> `Isbn`, `Money`, `Imprint`, `Title`, `Edition` y `StockItem`, con igualdad correcta y medida.

---

## 🎯 1. Propósito

Fijar el modelo de dominio que veintitrés fases van a arrastrar, y usarlo para tomar la primera
decisión de tipos que en Java no existía: **qué es un objeto y qué es un valor**. Al terminar vas a
poder defender, con la medición al lado, por qué `Isbn` es un `readonly record struct` y `Title` es
una `class` — y por qué invertir esas dos decisiones cuesta lo que cuesta.

Y hay algo que se decide aquí y no se vuelve a discutir: **los nombres**. Un modelo bien nombrado
en la fase 01 es la diferencia entre veintitrés fases que se leen como un curso y veintitrés fases
que se contradicen.

---

## ✅ 2. Qué queda listo al terminar

- [ ] `src/modern/Cordillera.Domain` compila en Release sin advertencias, con nullable activado.
- [ ] `Isbn` **se valida al construirse**: no existe una instancia de `Isbn` con un valor inválido,
      y lo demuestra una prueba que intenta crear uno y falla.
- [ ] `Title`, `Edition` y `StockItem` existen con la igualdad que el dominio necesita, y hay una
      prueba por tipo que la fija: dos `Edition` con el mismo ISBN **no** son la misma `Edition`.
- [ ] `Money` existe y **lleva su deuda 💸 declarada por escrito**, con su fase de cobro.
- [ ] `Imprint` y los cuatro sellos de Cordillera están en el modelo con sus códigos reales, y
      `Edition` lleva su sello y su estado con la razón de la desnormalización escrita.
- [ ] La medición de la sección 6 está escrita con su comando, y la entrada quedó en
      `BENCHMARKS.md`.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Nullable reference types**, más allá de una línea: el contexto está activado desde la fase 00 y
  el compilador te lo va a recordar. Qué garantiza y **qué no** es la fase 02 entera.
- **LINQ** → fase 03. En esta fase los recorridos son `foreach`, y no es nostalgia: cuando llegue
  LINQ va a importar mucho *cuándo* se ejecuta, y para eso hay que haber visto primero el bucle.
- **Genéricos más allá de lo obvio** (`List<T>`, `IEquatable<T>`) → fase 04, con la varianza y los
  genéricos reificados, que es donde el paralelo con el borrado de tipos de Java se rompe.
- **Persistencia.** Nada de este modelo toca la base de datos todavía: el borde 🧬 que traduce
  `VLRUNIT` a `UnitPrice` nace en la fase 09. Aquí el dato entra de un CSV.
- **`Money` con moneda adentro** → fase 17, y es deuda declarada, no olvido.

---

## 🧠 4. Concepto mínimo

En Java hay dos clases de tipos: primitivos y referencias. Los primitivos son ocho, los escribió
alguien en 1995, y no puedes crear más — si quieres un tipo pequeño con semántica de valor, escribes
una clase y confías en que el compilador y el recolector se arreglen. En C# esa distinción no es una
lista cerrada: **puedes escribir tus propios tipos por valor**, y eso cambia dos decisiones de
diseño que en Java no tenías que tomar.

**La primera es dónde vive la instancia y qué pasa al copiarla.** Un `struct` se copia por valor: al
pasarlo a un método, al asignarlo a otra variable o al meterlo en una lista, se copia el contenido.
No hay identidad de referencia que comparar, no hay `null` que verificar, y no hay una asignación en
el montón por cada instancia. A cambio, copiar cuesta — y copiar algo grande cuesta más que copiar
la referencia a algo grande.

**La segunda es qué significa que dos cosas sean iguales.** Y aquí es donde el modelo de dominio de
Cordillera deja de ser un ejercicio de sintaxis. Dos ediciones con el mismo ISBN: ¿son la misma
edición? Dos ISBN con los mismos trece dígitos: ¿son el mismo ISBN? Las dos respuestas son
distintas, y el tipo que elijas para cada uno **es** esa respuesta:

- Un **ISBN** es un valor. `978-958-30-1234-5` no tiene identidad, no tiene ciclo de vida, no
  cambia. Dos ISBN con los mismos dígitos son el mismo ISBN, siempre, y punto.
- Un **título** es una entidad. Tiene identidad propia —`CODTITULO`—, tiene estados que cambian
  (`borrador` → `programado` → `vigente` → `descatalogado`), y dos títulos que hoy se llaman igual
  son dos títulos distintos. Del Sur publicó un ensayo en 2006 y Cordillera compró otro en 2024 que
  resultó ser, en un 40%, el mismo libro: eran **dos títulos**, con dos contratos y dos regalías, y
  tratarlos como iguales porque coincide el texto es el bug más caro de la historia de la editorial.

> 🧠 **El modelo mental que hace encajar el resto:** un tipo por valor responde *"¿cuánto vale?"*;
> un tipo por referencia responde *"¿cuál es?"*. `Money`, `Isbn`, `EditionFormat` responden lo
> primero. `Title`, `Edition`, `Warehouse` responden lo segundo. Casi todas las decisiones de esta
> fase salen de aplicar esa pregunta con honestidad.

Y una tercera cosa, que no es de tipos sino de ceremonia: **las propiedades existen desde 2002**. El
par `getTitle()`/`setTitle()` no es una convención en C#, es un olor. Una propiedad es un miembro
del lenguaje con sintaxis de campo y semántica de método, y desde C# 14 ni siquiera hace falta
escribir el campo de respaldo.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

Este reflejo tiene tres mitades, y las tres producen código que compila y funciona.

**Primera mitad: el par de métodos.**

```csharp
// ❌ Lo que escribe el primer día alguien con once años de Java. Funciona. Y a la tercera clase
//    ya son doscientas líneas de nada.
public class Title
{
    private string _name;
    private string _imprintCode;

    public string GetName() { return _name; }
    public void SetName(string value) { _name = value; }
    public string GetImprintCode() { return _imprintCode; }
    public void SetImprintCode(string value) { _imprintCode = value; }
}
```

```csharp
// ✅ Lo mismo, en C#. Y lo que importa no es que sea más corto: es que `init` dice algo que el
//    setter no podía decir — "esto se fija al construir y después no cambia".
public class Title
{
    public required string Name { get; init; }
    public required ImprintCode Imprint { get; init; }
}
```

**Por qué falla el reflejo:** el setter público no es solo ruido, es una **afirmación falsa** sobre
tu dominio. El nombre de un título cambia (hay erratas, hay subtítulos que se agregan), pero el
sello con el que se publicó no cambia nunca — y con un setter para cada cosa, el modelo no puede
decir la diferencia. `init` y `required` la dicen, y el compilador la hace cumplir.

**Segunda mitad: `equals` y `hashCode` a pares.**

```csharp
// ❌ La traducción mecánica de lo que el IDE de Java genera. Son treinta líneas por tipo, y el
//    error clásico es actualizar una y no la otra cuando se agrega un campo.
public class Isbn
{
    private readonly string _value;

    public override bool Equals(object? obj)
    {
        if (obj is not Isbn other) { return false; }
        return _value == other._value;
    }

    public override int GetHashCode() => _value.GetHashCode();
}
```

```csharp
// ✅ Un record te da igualdad estructural, GetHashCode consistente, deconstrucción y un
//    ToString legible. Escrito una vez, correcto siempre — con una excepción que la sección 7
//    te va a hacer descubrir a golpes.
public readonly record struct Isbn(string Value);
```

**Por qué falla el reflejo:** no por ser largo. Por ser **frágil de una forma que las pruebas no
atrapan**: el día que alguien agregue un campo a la clase y no toque los dos métodos, la igualdad
queda mal y todo sigue compilando. En un `record`, la igualdad se deriva de los miembros, así que
agregar un miembro la actualiza sola.

**Tercera mitad, y es la que de verdad sorprende: creer que todo es referencia.**

```csharp
// Un struct se copia. Esto no es un detalle académico: es el bug que vas a escribir en tu
// primer mes, y compila sin una advertencia.
var movements = new List<StockCount>
{
    new StockCount(edition, quantity: 10),
};

StockCount first = movements[0];   // ← COPIA. No es una referencia al elemento de la lista.
first = first with { Quantity = 25 };

Console.WriteLine(movements[0].Quantity);   // 10. No 25.
```

**Por qué falla el reflejo:** en Java, `list.get(0)` te da la referencia al objeto y mutarlo cambia
lo que está en la lista. Aquí `movements[0]` te da **una copia del valor**, y modificar la copia no
toca la lista. La defensa del lenguaje es que `readonly record struct` no se puede mutar en
absoluto —`with` produce un valor nuevo— así que el error se vuelve visible en vez de silencioso.
Un `struct` mutable, en cambio, te deja escribir exactamente el bug de arriba.

> 🧭 **La regla que se lleva de esta fase:** si escribes un `struct`, es `readonly`. Y si no puede
> ser `readonly`, probablemente querías una `class`.

### 🩻 Esto sí funciona igual

Todo el diseño de objetos que ya sabes. Herencia con una sola base, interfaces múltiples,
visibilidad, composición sobre herencia, clases sellada y abstracta, polimorfismo, el principio de
sustitución. Nada de eso cambia y nada de eso se va a explicar en este curso.

Los modificadores tienen casi los mismos nombres y una diferencia que conviene saber: `internal` es
"visible dentro del ensamblado", que es lo más cercano al *package-private* que usas cuando no
escribes modificador — pero el ensamblado es la unidad de despliegue, no el paquete, así que es
bastante más ancho de lo que crees. El equivalente exacto del *package-private* de Java no existe.

Y el hábito de hacer inmutable lo que pueda serlo se transfiere entero: aquí es más barato de
escribir, así que se hace más.

### 📖 Diccionario de traducción

| Java | C# / .NET | Dónde se rompe el paralelo |
|---|---|---|
| `getX()` / `setX()` | propiedad `X { get; set; }` | La propiedad puede ser `init`-only: se fija al construir y no hay setter. Java no tiene eso |
| `final` en campo | `readonly` en campo | En un `struct`, `readonly` sobre el **tipo** garantiza que ningún miembro muta — no hay equivalente |
| `record` de Java 16 | `record` de C# 9 | Casi honesto. Diferencia: el `record` de C# tiene `with`, y su igualdad **no** mira dentro de un arreglo miembro |
| `@Override equals`/`hashCode` | los genera el `record` | Derivados de los miembros: agregar un miembro actualiza la igualdad sola |
| `Objects.equals(a, b)` | `a == b` en un `record` | `==` está sobrecargado por el `record`. En una `class` cualquiera, `==` sigue comparando referencias |
| `int`, `double`, `boolean` | `int`, `double`, `bool` | Son `struct` de la biblioteca, no primitivos del lenguaje: `42.ToString()` compila |
| `Integer` / autoboxing | `int?` / boxing explícito al convertir a `object` | No hay una clase envolvente por tipo. El boxing existe y es visible, y `int?` no es una clase |
| clase de valor inmutable con 30 líneas | `readonly record struct` de una línea | Aquí **no se asigna en el montón**, y eso es lo que mide la sección 6 |
| `BigDecimal` | `decimal` | `decimal` es un tipo del lenguaje con operadores: `a + b` y no `a.add(b)`. 128 bits, base 10, 28-29 dígitos |
| `Comparable<T>` | `IComparable<T>` + operadores | Puedes sobrecargar `<`, `>`, `==`: el código de dominio se lee como aritmética |
| `enum` con campos y métodos | `enum` (solo constantes) o `record` | El `enum` de C# es **más pobre**: es un entero con nombres. Si necesitas comportamiento, es un `record` o una clase |

> ⚠️ **La fila del `enum` es la que más muerde.** El `enum` de Java es una clase con instancias
> fijas, con campos, constructor y métodos. El de C# es un entero con nombres y **acepta cualquier
> entero por conversión**: `(EditionFormat)99` compila y no lanza nada. Por eso un `switch` sobre un
> `enum` que venga de datos externos necesita su rama para lo desconocido — y en este curso todos
> los `enum` vienen de datos externos, porque vienen de `char(2)` de 1997.

> 📝 **Nota de ecosistema.** `record` llegó con C# 9 (2020) y `record struct` con C# 10 (2021);
> `init` es de C# 9 y `required` de C# 11 (2022). Antes de eso, una clase de valor inmutable eran
> las treinta líneas del ejemplo ❌, y por eso vas a encontrar tantas: todo el código anterior a
> 2020 —y **todo** el de SIGE, que es de 2017— está escrito así. C# 14 agrega la palabra clave
> contextual `field`, que da acceso al campo de respaldo generado sin declararlo:
>
> ```csharp
> // Una propiedad con validación en el setter, sin campo privado a la vista.
> public string Name
> {
>     get;
>     set => field = value.Trim();
> }
> ```
>
> Es la respuesta final del lenguaje al par `get`/`set` escrito a mano, veintitrés años después de
> las propiedades.

---

## 💻 5. Código mínimo con comentarios

Aquí nace `Cordillera.Domain`. Tres decisiones y sus consecuencias.

### 5.1 `Isbn` — un valor que se valida al construirse

```csharp
// src/modern/Cordillera.Domain/Isbn.cs
namespace Cordillera.Domain;

/// <summary>
/// El ISBN de una edición, normalizado y validado. No existe una instancia de este tipo con un
/// valor inválido: es la garantía que hace que el resto del modelo no tenga que comprobar nada.
/// </summary>
/// <remarks>
/// Es un <c>readonly record struct</c> y no una clase porque es un valor puro: no tiene
/// identidad, no cambia, y el catálogo tiene 18.000 títulos con unas 26.000 ediciones. Cuánto
/// ahorra esa decisión es exactamente lo que mide la sección 6.
/// </remarks>
public readonly record struct Isbn
{
    private Isbn(string value) => Value = value;

    /// <summary>Los 13 dígitos, sin guiones ni espacios.</summary>
    public string Value { get; }

    /// <summary>
    /// Construye un ISBN a partir de lo que venga del mundo real: con guiones, con espacios, o
    /// con los 10 dígitos de antes de 2007.
    /// </summary>
    /// <exception cref="ArgumentException">Si no es un ISBN.</exception>
    public static Isbn Parse(string candidate)
    {
        if (!TryParse(candidate, out Isbn isbn))
        {
            // El mensaje dice qué llegó, porque este error lo va a leer alguien mirando un CSV
            // de 40.000 líneas y "ISBN inválido" no le sirve de nada.
            throw new ArgumentException(
                $"«{candidate}» no es un ISBN válido: ni 13 dígitos con dígito de control " +
                "correcto, ni 10 dígitos convertibles.",
                nameof(candidate));
        }

        return isbn;
    }

    /// <summary>
    /// La versión que no lanza. Existe porque en el borde de datos —la fase 09— la mitad de las
    /// filas traen basura y una excepción por fila es la forma más cara de recorrer un archivo.
    /// </summary>
    public static bool TryParse(string? candidate, out Isbn isbn)
    {
        isbn = default;

        if (string.IsNullOrWhiteSpace(candidate))
        {
            return false;
        }

        string digits = Normalize(candidate);

        // El catálogo de Cordillera empieza en 1979 y el ISBN-13 solo es obligatorio desde enero
        // de 2007: las ediciones anteriores traen 10 dígitos. Se convierten, no se rechazan —
        // rechazarlas dejaría fuera media dorsal del fondo editorial.
        if (digits.Length == 10)
        {
            digits = ConvertFromIsbn10(digits);
        }

        if (digits.Length != 13 || !IsChecksumValid(digits))
        {
            return false;
        }

        isbn = new Isbn(digits);
        return true;
    }

    /// <summary>Con los guiones donde el mundo editorial espera verlos.</summary>
    public override string ToString() =>
        $"{Value[..3]}-{Value[3..6]}-{Value[6..8]}-{Value[8..12]}-{Value[12..]}";

    private static string Normalize(string candidate)
    {
        // Nada de Replace en cadena: una asignación por cada carácter que se quita, y esto se
        // ejecuta 26.000 veces al cargar el catálogo. La fase 06 lleva esta idea hasta el final.
        Span<char> buffer = stackalloc char[candidate.Length];
        int length = 0;

        foreach (char c in candidate)
        {
            if (char.IsAsciiDigit(c))
            {
                buffer[length++] = c;
            }
            else if (c is 'X' or 'x')
            {
                // La 'X' de un ISBN-10 es un dígito de control con valor 10.
                buffer[length++] = 'X';
            }
        }

        return new string(buffer[..length]);
    }

    private static string ConvertFromIsbn10(string isbn10)
    {
        // Prefijo 978 y se recalcula el dígito de control: el de un ISBN-10 no sirve.
        string body = string.Concat("978", isbn10[..9]);
        return string.Concat(body, CheckDigit(body));
    }

    private static bool IsChecksumValid(string digits) =>
        CheckDigit(digits[..12]) == digits[12];

    private static char CheckDigit(string twelveDigits)
    {
        int sum = 0;

        for (int i = 0; i < twelveDigits.Length; i++)
        {
            int digit = twelveDigits[i] - '0';
            sum += i % 2 == 0 ? digit : digit * 3;
        }

        return (char)('0' + ((10 - (sum % 10)) % 10));
    }
}
```

**Detalles con intención**

- **El constructor es privado y la única entrada es `Parse`/`TryParse`.** Es lo que convierte la
  validación en una garantía de tipo en vez de una comprobación que alguien va a olvidar. En Java
  harías lo mismo con un constructor privado y un factory estático; la diferencia es que aquí el
  tipo no se asigna en el montón, así que la garantía no cuesta memoria.
- **`Parse` y `TryParse` es el par idiomático de .NET**, no un capricho: lo tienen `int`,
  `DateTime`, `Guid` y todo el framework. Un tipo de dominio que sigue esa convención se usa sin
  leer documentación, y eso vale más que cualquier nombre ingenioso.
- **El `default` de un `struct` existe y no se puede prohibir.** `default(Isbn)` tiene `Value` en
  `null` y **no pasó por `Parse`**. Es el precio de la semántica de valor, y la forma de convivir
  con él es no permitir que un `Isbn` sin valor llegue al modelo: por eso `Edition` lo recibe por
  constructor. Es el tipo de agujero que el `record struct` te obliga a mirar de frente.

### 5.2 `Money` — el valor que nace con una deuda

```csharp
// src/modern/Cordillera.Domain/Money.cs
namespace Cordillera.Domain;

/// <summary>
/// Un importe. <c>decimal</c> y nunca <c>double</c>: una liquidación trimestral de regalías es
/// exactamente donde el error de redondeo binario se vuelve una impugnación.
/// </summary>
public readonly record struct Money(decimal Amount) :
    IComparable<Money>
{
    public static Money Zero => new(0m);

    // Sobrecarga de operadores donde el dominio la pide, y solo ahí. `total + line` se lee como
    // aritmética porque es aritmética; escribir `total.Add(line)` sería traer ceremonia de Java
    // a un lenguaje que no la necesita.
    public static Money operator +(Money left, Money right) => new(left.Amount + right.Amount);

    public static Money operator -(Money left, Money right) => new(left.Amount - right.Amount);

    public static Money operator *(Money money, int quantity) => new(money.Amount * quantity);

    public static bool operator <(Money left, Money right) => left.Amount < right.Amount;

    public static bool operator >(Money left, Money right) => left.Amount > right.Amount;

    public static bool operator <=(Money left, Money right) => left.Amount <= right.Amount;

    public static bool operator >=(Money left, Money right) => left.Amount >= right.Amount;

    public int CompareTo(Money other) => Amount.CompareTo(other.Amount);

    public override string ToString() => Amount.ToString("N2");
}
```

> 💸 **Deuda declarada: `Money` es un `decimal` desnudo, sin moneda.**
>
> Lo correcto sería `Money(decimal Amount, Currency Currency)`, con operadores que **se nieguen** a
> sumar pesos colombianos con pesos mexicanos. Hoy `new Money(1000m) + new Money(1000m)` da 2000 y
> nadie pregunta de qué. Con un solo país eso no se nota; Cordillera vende en nueve.
>
> **Se paga en la fase 17**, cuando la liquidación trimestral cruce tres monedas con tres tasas y el
> tipo tenga que llevar dentro lo que el negocio no puede perder. La factura será
> `git diff fase-01 fase-17 -- src/modern/Cordillera.Domain/Money.cs`.
>
> **Por qué no se paga ahora**, que es la parte que importa: porque la moneda sin la tasa de cambio
> y sin el momento en que se aplicó resuelve un tercio del problema y da una falsa sensación de
> haberlo resuelto. El problema real de Cordillera no es sumar monedas distintas: es **no poder
> reproducir un número de hace ocho meses** porque la tasa que se usó no se guardó en ninguna parte.
> Eso necesita la fase 17 completa.

Así se lee un 💸 en este curso, y así se escriben todos: qué sería lo correcto, en qué fase se paga,
y por qué esperar es una decisión y no un descuido.

### 5.3 `Imprint` y el `enum` que viene de `char(2)`

```csharp
// src/modern/Cordillera.Domain/Imprint.cs
namespace Cordillera.Domain;

/// <summary>Los códigos de sello, tal como están en `SELLOS.CODSELLO` desde 1997.</summary>
public enum ImprintCode
{
    /// <summary>Cordillera — el sello fundador, textos escolares y literatura.</summary>
    Cor,

    /// <summary>Cometa — literatura infantil, comprada en Lima en 1991.</summary>
    Com,

    /// <summary>Del Sur — ensayo y ciencias sociales, comprada en Buenos Aires en 1998.</summary>
    Sur,

    /// <summary>Universitaria del Bajío — editorial universitaria mexicana, adquirida en 2004.</summary>
    Uba,
}

/// <summary>
/// El sello editorial. Es una entidad —tiene identidad y datos que cambian— pero de las que casi
/// no cambian: cuatro filas que se leen una vez.
/// </summary>
public sealed record Imprint(ImprintCode Code, string Name, string City);
```

**Detalles con intención**

- **`ImprintCode` es un `enum` y `Imprint` es un `record`**, y la diferencia es la del 📖: el `enum`
  es un entero con nombres, así que no puede llevar el nombre ni la ciudad adentro. En Java
  `ImprintCode` habría sido un `enum` con campos y ahí habría terminado el diseño; aquí hacen falta
  los dos tipos, y el que viaja por el modelo es el `enum`.
- **`Imprint` es `record` y no `class`** aunque sea una entidad, porque es una entidad **inmutable
  de referencia**: cuatro filas que nadie edita. La igualdad estructural es correcta y gratis.
- **Los valores del `enum` se llaman `Cor`, `Com`, `Sur`, `Uba`** y no `Cordillera`, `Cometa`… No es
  descuido: son los códigos de `CODSELLO`, y que el nombre del miembro coincida con el dato hace que
  el borde de la fase 09 sea una conversión trivial en vez de una tabla de traducción.

### 5.4 `Title` y `Edition` — las entidades, y por qué son `class`

```csharp
// src/modern/Cordillera.Domain/Title.cs
namespace Cordillera.Domain;

/// <summary>El título como obra: lo que se contrata, se edita y genera regalías.</summary>
/// <remarks>
/// Es una <c>class</c> y no un <c>record</c>, y la razón es de dominio y no de rendimiento: dos
/// títulos con los mismos datos son **dos títulos**. Del Sur publicó un ensayo en 2006 y en 2024
/// se compró otro que resultó ser, en un 40%, el mismo libro: eran dos obras, con dos contratos y
/// dos regalías. Un <c>record</c> los declararía iguales y el modelo mentiría.
/// </remarks>
public sealed class Title
{
    public Title(TitleId id, string name, ImprintCode imprint)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(name);

        Id = id;
        Name = name;
        Imprint = imprint;
    }

    /// <summary>La identidad. Es lo único que decide si dos títulos son el mismo.</summary>
    public TitleId Id { get; }

    /// <summary>
    /// El nombre sí cambia —hay erratas, hay subtítulos que se agregan— y por eso tiene setter.
    /// Se normaliza al asignarlo, con la palabra clave `field` de C# 14: no hace falta declarar
    /// el campo de respaldo.
    /// </summary>
    public string Name
    {
        get;
        set => field = value.Trim();
    }

    /// <summary>El sello con el que se publicó, que no cambia nunca.</summary>
    public ImprintCode Imprint { get; }

    public TitleStatus Status { get; private set; } = TitleStatus.Draft;

    /// <summary>
    /// Los estados de un título, en el orden en que ocurren. La transición se valida aquí y no en
    /// quien llama: que el estado solo se pueda cambiar con un método es lo que hace que
    /// `private set` valga la pena.
    /// </summary>
    public void MoveTo(TitleStatus next)
    {
        bool allowed = (Status, next) switch
        {
            (TitleStatus.Draft, TitleStatus.Scheduled) => true,
            (TitleStatus.Scheduled, TitleStatus.Published) => true,
            (TitleStatus.Published, TitleStatus.OutOfPrint) => true,
            // Un título descatalogado puede reeditarse: pasa dos o tres veces al año con el fondo.
            (TitleStatus.OutOfPrint, TitleStatus.Scheduled) => true,
            _ => false,
        };

        if (!allowed)
        {
            throw new InvalidOperationException(
                $"Un título en estado {Status} no puede pasar a {next}.");
        }

        Status = next;
    }

    /// <summary>
    /// La igualdad de una entidad es por identidad, y se escribe a mano **una vez** porque es lo
    /// que el dominio dice. Es el único tipo de esta fase donde el código de Java de la 🪞 era
    /// casi correcto — con la diferencia de que aquí compara el `Id`, no todos los campos.
    /// </summary>
    public override bool Equals(object? obj) => obj is Title other && Id == other.Id;

    public override int GetHashCode() => Id.GetHashCode();

    public override string ToString() => $"{Id} · {Name}";
}

/// <summary>La identidad de un título: `TITULOS.CODTITULO`, diez caracteres desde 1997.</summary>
public readonly record struct TitleId(string Value)
{
    public override string ToString() => Value;
}

public enum TitleStatus
{
    Draft,
    Scheduled,
    Published,
    OutOfPrint,
}
```

```csharp
// src/modern/Cordillera.Domain/Edition.cs
namespace Cordillera.Domain;

/// <summary>
/// La edición concreta de un título: la que tiene ISBN, precio, formato y existencias. Es la que
/// se vende y la que se cuenta en un almacén.
/// </summary>
public sealed class Edition
{
    public Edition(
        EditionId id,
        TitleId titleId,
        Isbn isbn,
        EditionFormat format,
        Money listPrice,
        ImprintCode imprint,
        TitleStatus status)
    {
        Id = id;
        TitleId = titleId;
        Isbn = isbn;
        Format = format;
        ListPrice = listPrice;
        Imprint = imprint;
        Status = status;
    }

    /// <summary>`EDICION.CODEDIT`. La clave que aparece en media docena de tablas del esquema.</summary>
    public EditionId Id { get; }

    public TitleId TitleId { get; }

    /// <summary>
    /// El ISBN se recibe construido, no como cadena: así este constructor no puede recibir uno
    /// inválido y `Edition` no tiene que validar nada.
    /// </summary>
    public Isbn Isbn { get; }

    public EditionFormat Format { get; }

    public Money ListPrice { get; private set; }

    /// <summary>
    /// El sello con el que se publicó. **No está en `EDICION`**: el esquema lo tiene en
    /// `TITULOS.CODSELLO`, y el borde 🧬 de la fase 09 lo resuelve al cargar.
    /// </summary>
    /// <remarks>
    /// Es una desnormalización deliberada y conviene justificarla, porque un modelo que copia datos
    /// del padre se defiende o se borra. Se defiende por dos razones: el sello de un título **no
    /// cambia nunca** —a diferencia del nombre—, así que no hay riesgo de quedar desactualizado; y
    /// casi todas las consultas del catálogo filtran por sello, de modo que obligarlas a cargar el
    /// `Title` completo para leer un `char(3)` sería un `N+1` autoinfligido. La alternativa —un tipo
    /// de lectura que junte `Title` y `Edition`— llega cuando haga falta de verdad: en la fase 15,
    /// con los DTO del contrato público.
    /// </remarks>
    public ImprintCode Imprint { get; }

    /// <summary>
    /// `EDICION.ESTADO`. Sí está en el esquema, y es **independiente** del estado del título: hay
    /// títulos vigentes con una edición descatalogada y otra en imprenta.
    /// </summary>
    public TitleStatus Status { get; private set; }

    /// <summary>Cambiar el precio es una operación del negocio, no una asignación.</summary>
    public void Reprice(Money newPrice)
    {
        if (newPrice <= Money.Zero)
        {
            throw new ArgumentOutOfRangeException(
                nameof(newPrice), newPrice, "El precio de lista tiene que ser positivo.");
        }

        ListPrice = newPrice;
    }

    // Dos ediciones son la misma si tienen el mismo CODEDIT. Y no: **no** basta con que
    // coincida el ISBN. Hay 340 ediciones con ISBN en blanco, de antes de que fuera obligatorio,
    // y si la igualdad se apoyara en el ISBN todas esas serían "la misma edición".
    public override bool Equals(object? obj) => obj is Edition other && Id == other.Id;

    public override int GetHashCode() => Id.GetHashCode();

    public override string ToString() => $"{Id} · {Isbn} · {Format}";
}

/// <summary>`EDICION.CODEDIT`.</summary>
public readonly record struct EditionId(string Value)
{
    public override string ToString() => Value;
}

/// <summary>
/// `EDICION.FORMATO`, un `char(2)` de 1997. Los nombres de los miembros son los códigos del
/// esquema para que el borde de la fase 09 sea trivial.
/// </summary>
public enum EditionFormat
{
    /// <summary>Tapa dura.</summary>
    Td,

    /// <summary>Tapa blanda.</summary>
    Tb,

    /// <summary>Libro electrónico.</summary>
    Eb,

    /// <summary>Audiolibro.</summary>
    Au,
}
```

**El patrón a memorizar**

> **La igualdad no es una decisión de implementación: es una afirmación sobre el dominio.** Un
> `record` dice *"dos cosas con los mismos datos son la misma cosa"*. Una entidad con `Equals` por
> identidad dice *"dos cosas son la misma solo si son la misma"*. Elegir mal no produce un error de
> compilación: produce un informe de regalías que paga dos veces, o uno que no paga.

### 5.5 `StockItem` — el valor que se copia, y la trampa que trae

```csharp
// src/modern/Cordillera.Domain/StockItem.cs
namespace Cordillera.Domain;

/// <summary>
/// Las existencias de una edición en un almacén, en un momento dado. Es un valor: no tiene
/// identidad propia, es un conteo. Y es `readonly`, así que la trampa de la copia mutable no
/// existe — `with` devuelve un valor nuevo y el original no se toca.
/// </summary>
public readonly record struct StockItem(
    EditionId Edition,
    WarehouseCode Warehouse,
    int Quantity)
{
    /// <summary>
    /// Las existencias pueden ser negativas, y no es un error de modelo: `MOVINVEN` tiene ajustes
    /// con cantidad negativa desde 1997 y hay saldos que quedaron por debajo de cero. Un modelo
    /// que lo prohibiera no podría leer los datos que existen.
    /// </summary>
    public bool IsBackordered => Quantity < 0;

    public StockItem Add(int delta) => this with { Quantity = Quantity + delta };
}

/// <summary>`ALMACEN.CODALMA`: `BOG`, `MEX`, `LIM`.</summary>
public enum WarehouseCode
{
    Bog,
    Mex,
    Lim,
}
```

**Prueba de fuego**

```csharp
// Esto es lo que hay que ejecutar una vez, mirando la salida, antes de seguir a la fase 02.
var items = new List<StockItem>
{
    new(new EditionId("ED00001234"), WarehouseCode.Bog, Quantity: 10),
};

StockItem copy = items[0].Add(15);

Console.WriteLine(items[0].Quantity);   // 10 — la lista no se tocó
Console.WriteLine(copy.Quantity);       // 25

var titles = new List<Title>
{
    new(new TitleId("TI00000042"), "Cartas desde el páramo", ImprintCode.Sur),
};

Title sameReference = titles[0];
sameReference.Name = "Cartas desde el páramo (2.ª ed.)";

Console.WriteLine(titles[0].Name);      // el nombre NUEVO — es el mismo objeto
```

Y la mentira que te va a contar la salida si miras el lugar equivocado: **si `StockItem` fuera una
`class`, las dos primeras líneas imprimirían 25 y 25, y el programa seguiría funcionando**. En un
modelo de dominio no hay ninguna prueba que falle por haber elegido mal entre valor y referencia:
falla el informe, tres meses después, y la causa se busca en la consulta.

---

## 📏 6. Medición

**Hipótesis:** implementar `Isbn` como `class` cuesta una asignación en el montón por instancia, y
sobre el catálogo completo de Cordillera esa diferencia es visible en pico de memoria y en tiempo de
comparación; como `readonly record struct` no asigna nada.

**Condiciones:** SDK 10.0.401 · compilación Release · Windows 11 · **un millón de `Isbn`** —26.000
ediciones reales del catálogo, repetidas para llegar al volumen donde la diferencia se mide sin
ruido— · 100 repeticiones con 10 de calentamiento descartadas · arnés propio para la carga completa,
y BenchmarkDotNet para la comparación individual, que es un microbenchmark de libro.

**Competidores:** las tres implementaciones del **mismo** tipo, las tres correctas y las tres
defendibles en una revisión:

- `class Isbn` con `Equals`/`GetHashCode` escritos a mano — lo que produce la traducción desde Java.
- `record class Isbn` — igualdad estructural generada, y sigue siendo de referencia.
- `readonly record struct Isbn` — lo que el curso eligió.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 01
```

**Resultado:** ⏳ pendiente de ejecución en tu máquina.

| Implementación | Mediana (carga de 1M) | p95 | Asignado | Pico | Comparación (ns) |
|---|---|---|---|---|---|
| `class` con `Equals` a mano | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| `record class` | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| `readonly record struct` | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |

> ⚖️ **Veredicto** *(expectativa, todavía sin ejecutar — `formato-de-mediciones.md` §2.6)*. Se
> espera que las dos versiones de referencia asignen del orden de 24 bytes por instancia más la
> cadena, y que el `struct` no asigne nada por sí mismo — aunque **la cadena de dentro sigue
> estando en el montón**, y ese es el matiz que la medición tiene que hacer visible: el `struct` no
> es gratis, es *menos*.
>
> **Los dos umbrales que tu ejecución tiene que determinar:** (1) a partir de cuántas instancias
> vivas la diferencia de pico de memoria pasa de anecdótica a decisión, y (2) **a partir de qué
> tamaño del `struct` la copia cuesta más que la indirección** — que es la pregunta que decide si
> `StockItem`, con tres miembros, debió ser un `struct`.

> 📝 Si la diferencia entre `class` y `record class` queda dentro del ruido —y es probable—, el
> veredicto lo dice: **empate**. La decisión entre esas dos no es de rendimiento, es de cuántas
> líneas mantienes y de si la igualdad se actualiza sola cuando alguien agrega un miembro.

---

## 🧱 7. Miniproyecto — el catálogo que llega del distribuidor mexicano

**El encargo**

Nohora te reenvía un correo: *"Me llegó el archivo de `DISMEX` con las ediciones que ellos tienen
cargadas, y quieren que confirmemos cuáles coinciden con nuestro catálogo. Son como cuarenta mil
líneas. Lo abrí en Excel y ya me di cuenta de que hay ISBN raros, hay unos en blanco, y hay títulos
con las tildes comidas — los de Cometa, los peruanos. Necesito una lista de qué entró, qué no entró
y por qué no entró, porque si les digo «no cuadra» me van a preguntar cuál."*

**Por qué duele**

Porque el archivo es del mundo real y el modelo es estricto a propósito: `Isbn` no admite un valor
inválido, `Edition` no admite un `Isbn` sin construir, y `Money` no admite un precio negativo. La
tentación es relajar el modelo para que el archivo entre. **El trabajo es el contrario:** que el
modelo siga siendo estricto y que el archivo se convierta en dos listas —lo que entró y lo que no,
con el motivo— sin perder una sola línea en silencio.

**Datos de entrada**

Un fragmento literal, con sus casos sucios. El archivo completo lo generas repitiendo y variando
estas filas hasta cuarenta mil, con semilla fija.

```text
CODEDIT;ISBN;TITULO;SELLO;FORMATO;PRECIO;MONEDA;CANTIDAD
ED00001234;978-958-30-1234-5;Cartas desde el páramo;SUR;TB;68000;COP;12
ED00001235;9789583012352;El río que no vimos;COR;TD;95000;COP;4
ED00001236;9586142035;Cuentos de la quebrada;COM;TB;42000;COP;7
ED00001237;;Antología del sur;SUR;TB;55000;COP;2
ED00001238;978-958-30-1238-9;Los d?as de Chincha;COM;TB;38000;PEN;31
ED00001239;978-958-30-9999-9;Manual de estilo;COR;EB;25000;COP;0
ED00001240;9789583012383;Cartas desde el páramo;SUR;TB;68000;COP;5
ED00001241;978-958-30-1241-X;Geografía del olvido;SUR;TD;110000;MXN;-3
```

Qué tiene cada línea rara, y ninguna es inventada para el ejercicio:

- **`ED00001236`** trae **diez dígitos**: es una edición anterior a 2007, y el ISBN-10 es legítimo.
  Se convierte, no se descarta.
- **`ED00001237`** trae el ISBN **en blanco**: son las 340 ediciones del fondo antiguo. Tienen que
  entrar al catálogo igual, porque existen y se venden.
- **`ED00001238`** dice `Los d?as de Chincha`: es la tilde que se comió la intercalación
  `Modern_Spanish_CI_AS` en la importación de 2017. **No se corrige** — no se puede reconstruir— y
  se reporta.
- **`ED00001239`** tiene un **dígito de control incorrecto**. Ese sí es un error de datos.
- **`ED00001240`** tiene el mismo título que `ED00001234` **con otro ISBN y otro `CODEDIT`**: son
  dos ediciones del mismo título, y el modelo tiene que dejar clarísimo que no son la misma cosa.
- **`ED00001241`** trae una `X` en el ISBN-13 —donde no puede haberla— y **cantidad negativa**, que
  sí es válida: `MOVINVEN` tiene ajustes negativos desde 1997.

**Criterios de aceptación**

1. Un programa de consola que lee el archivo y emite dos salidas: `catalogo.csv` con lo que entró al
   modelo, y `rechazos.csv` con una fila por línea rechazada, **su motivo y su número de línea**. La
   suma de las dos es exactamente el número de líneas del archivo: ninguna se pierde.
2. `Isbn`, `Title`, `Edition`, `Money` y `StockItem` **no se modifican** para que el archivo entre.
   Si crees que uno necesita cambiar, escribe en dos líneas por qué y hazlo explícito.
3. Pruebas que fijen las cuatro afirmaciones del dominio: dos `Edition` con el mismo `CODEDIT` son
   iguales; dos con el mismo ISBN y distinto `CODEDIT` **no** lo son; dos `Isbn` con los mismos
   dígitos escritos distinto —con guiones y sin— son iguales; y un ISBN-10 convertido es igual a su
   ISBN-13 equivalente.
4. Las ediciones con ISBN en blanco **entran al catálogo** y el modelo dice cómo las representa. La
   decisión es tuya y hay dos caminos defendibles.
5. **Medición de cierre:** el tiempo y las asignaciones de cargar el archivo de 40.000 líneas
   completo, medidos con el arnés. Ese número va en el mensaje del tag `mini-01`.

**Restricciones de estilo y alcance**

Código nuevo: nullable activado, advertencias como errores, identificadores en inglés, comentarios y
mensajes en español. **Sin LINQ** —llega en la fase 03 y quiero que este recorrido sea un `foreach`
que tú controlas— y sin paquetes: `File.ReadLines` y `string.Split` alcanzan, aunque la fase 06 va a
volver sobre ese `Split` con una medición que te va a incomodar.

Los nombres de las columnas del archivo están en español y en mayúsculas porque **son los del
esquema heredado**: se escriben tal cual y no se traducen.

**La trampa**

Vas a querer que `Edition` lleve dentro la lista de sus contribuidores —autor, traductor,
ilustrador— porque el archivo del distribuidor los trae en una columna que no está en el fragmento
de arriba, y el modelo se ve mejor con ellos adentro.

En cuanto lo hagas, convierte `Edition` en un `record` para no escribir otro `Equals` a mano. Va a
compilar, las pruebas del criterio 3 van a pasar, y **la igualdad va a quedar mal de una forma que
ninguna prueba tuya va a ver**: dos ediciones con exactamente los mismos contribuidores dejarán de
ser iguales. Nadie te va a avisar, ni el compilador ni el analizador.

Cuando te pase —y va a pasar— escribe en dos líneas qué lo causó. La respuesta está en una fila del
📖 de esta fase.

<details><summary>Pista 1 — el enfoque</summary>

Dos responsabilidades, dos piezas. Una lee líneas y produce, por cada una, o una `Edition` o un
motivo de rechazo — nunca las dos, nunca ninguna. La otra escribe los dos CSV. El tipo que devuelve
la primera es la decisión de diseño interesante de esta parte.

Y no uses excepciones para el flujo normal: con 40.000 líneas y un 5% de rechazos, son dos mil
excepciones. La fase 04 le pone número a lo que eso cuesta.

</details>

<details><summary>Pista 2 — la herramienta</summary>

`Isbn.TryParse` existe justamente para esto. Para el ISBN en blanco, mira qué te ofrece el lenguaje
para representar "este valor puede no estar" en un tipo por valor:
`https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/nullable-value-types`

Para decidir si `Edition.Isbn` debería ser `Isbn?` o si el catálogo necesita otra cosa, lee sobre
igualdad de tipos anulables por valor — y ten presente que la fase 02 entera trata de esta decisión.

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```csharp
internal sealed record CatalogRow(int LineNumber, string RawLine);

// Uno de los dos, nunca ambos. Cómo se representa eso es tu decisión.
internal sealed record ImportOutcome(Edition? Edition, string? RejectionReason);

internal static ImportOutcome ParseRow(CatalogRow row);

internal static void WriteCatalog(string path, IReadOnlyList<Edition> editions);

internal static void WriteRejections(string path, IReadOnlyList<(int Line, string Reason)> rejections);
```

</details>

**Cómo se entrega**

```powershell
dotnet test src\Cordillera.slnx -c Release
dotnet run -c Release --project src\fases\01-tipos-valor-y-referencia\mini -- datos\dismex.csv
```

```bash
git tag -a mini-01 -m "Mini F1: catálogo de DISMEX contra el modelo · 40.000 líneas en <X> ms, <Y> MB asignados, <N> rechazos"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Agrega `Warehouse` al modelo —código, nombre, ciudad, país— y decide si es `class`, `record` o
   `record struct`. Escribe la razón en un comentario de tres líneas.
2. Escribe la prueba que demuestra que `Isbn.Parse("978-958-30-1234-5")` y
   `Isbn.Parse("9789583012345")` producen valores iguales.
3. Sobrecarga en `Money` el operador de división por un entero, y decide qué hace con el residuo de
   dividir 100 entre 3. Justifica la decisión en el comentario.
4. Convierte `Imprint` de `record` a `class` con `Equals` por identidad y mide cuántas líneas
   ganaste o perdiste. Di cuál dejarías en el curso.
5. Agrega a `Title` el subtítulo, que puede no existir, **sin** usar todavía nada de la fase 02 más
   allá de `?`. Anota la pregunta que te quedó abierta: la fase 02 la responde.
6. Escribe una prueba que falle si alguien cambia la igualdad de `Edition` de `Id` a `Isbn`, y que
   el mensaje de fallo explique por qué está mal.

**🟡 Intermedio (7–14)**

7. Implementa `IComparable<Isbn>` para poder ordenar el catálogo por ISBN, y explica por qué el
   `record struct` no te lo dio gratis aunque sí te dio la igualdad.
8. Haz que `Money` implemente `IParsable<Money>` para poder leer `"68000"` del CSV con la misma
   convención que `int.Parse`. Documenta qué gana el código que lo consume.
9. Escribe un `struct` **mutable** de tres campos, guárdalo en una `List<T>`, y reproduce el bug de
   la tercera mitad del 🪞. Después hazlo `readonly` y muestra qué error de compilación aparece.
10. `default(Isbn)` existe y no pasó por `Parse`. Escribe una prueba que lo demuestre y propón dos
    formas de que ese valor no llegue nunca al modelo. Elige una.
11. Mide con el arnés el costo de `ToString()` de `Isbn` —que hace cinco cortes de cadena— contra
    devolver `Value` crudo, sobre 100.000 llamadas. Di si la diferencia justifica algo.
12. Agrega el estado `Withdrawn` (retirado por orden judicial, pasa una vez cada tantos años) a
    `TitleStatus` y a la máquina de transiciones. Di qué otra cosa del modelo tuviste que tocar.
13. Escribe `EditionFormat.Parse(string codigo)` que convierta el `char(2)` del esquema —`TD`,
    `TB`, `EB`, `AU`— y decide qué hace con `"XX"`. Recuerda la advertencia del 📖 sobre `(EditionFormat)99`.
14. Convierte `StockItem` de `readonly record struct` a `sealed record` y corre las pruebas de la
    fase. Explica por qué **todas pasan** y qué acabas de romper.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Te entregan un `record` con un `int[]` adentro y un informe que dice que "dos
    ediciones idénticas aparecen duplicadas en el diccionario". Escribe la prueba que lo reproduce,
    explica la causa en dos líneas y propón dos arreglos con su costo.
16. **Diagnóstico.** Un `Dictionary<Title, int>` pierde entradas después de que alguien renombra un
    título. Explica por qué, y por qué el `GetHashCode` de `Title` de esta fase **no** tiene ese
    problema. Escribe la versión que sí lo tendría.
17. **Medición.** Implementa las tres versiones de `Isbn` de la sección 6 y ejecuta la medición
    completa, con BenchmarkDotNet para la comparación individual. Publica la tabla con su veredicto
    y **sus dos umbrales**.
18. **Medición.** Determina experimentalmente a partir de cuántos campos un `readonly record struct`
    pasado por parámetro cuesta más que una clase. Usa `in` en una de las variantes y explica qué
    cambia.
19. Diseña `Money` con moneda adentro —la versión que la fase 17 va a necesitar— y **no la
    integres**. Escribe qué se rompería hoy en el modelo si la metieras, y por qué esperar es la
    decisión correcta y no pereza.
20. **Decisión — ¿se migra, se envuelve o se deja quieto?** `TITULOS` tiene un solo `CODAUTOR`, así
    que una obra con dos autores hoy está duplicada en dos filas. El modelo nuevo podría
    representarlo bien desde el primer día. Decide qué hace este curso con esa discrepancia, y qué
    cuesta cada camino cuando haya que escribir de vuelta a la tabla.
21. **Decisión — ¿se migra, se envuelve o se deja quieto?** El dominio de regalías necesita
    porcentajes (`PORCREGAL decimal(5,2)`). Decide si merece un tipo propio `Percentage`, si se
    queda como `decimal` desnudo, o si se envuelve solo en el borde. Sostén la decisión con el costo
    de las otras dos.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Escribe dos instancias de un `record` que sean `Equals` y tengan distinto
    `GetHashCode`, o demuestra que con `record` no se puede. Si no se puede, escribe la `class`
    donde sí se puede y explica qué se rompe en un `HashSet`.
23. **Adversarial.** Haz que `Edition.Reprice` deje el modelo en un estado que el dominio considera
    imposible, sin usar reflexión y sin modificar `Edition`. *(Pista: mira qué pasa con una `struct`
    de sólo lectura expuesta como propiedad y qué garantiza —y qué no— `private set`.)*
24. **Diseño y medición.** El catálogo vivo son 11.000 títulos con unas 26.000 ediciones, y varias
    fases van a necesitar buscar una edición por ISBN. Diseña la estructura que las sostenga,
    mídela contra un recorrido lineal, y determina el umbral de tamaño por debajo del cual el
    recorrido lineal gana.
25. **Defiende una decisión.** Duván revisa tu modelo y pregunta: *"¿por qué `Title` es una clase
    con `Equals` escrito a mano si me acabas de decir que los `record` son mejores?"*. Respóndele
    por escrito, en su lenguaje, con un ejemplo del catálogo de Cordillera donde la respuesta
    contraria produce un error de plata.

**🔥 Opcionales**

- Implementa `Isbn` como `struct` **sin** la cadena adentro —13 dígitos caben en un `long`— y mide
  qué cambia en asignaciones. Anota qué se pierde en legibilidad y en depuración.
- Escribe un analizador de Roslyn que marque como error cualquier `struct` no `readonly` en
  `Cordillera.Domain`. Es más fácil de lo que parece y es la forma de que la regla de esta fase la
  sostenga el compilador y no la revisión de código.
- Investiga `[StructLayout]` y `Unsafe.SizeOf<T>()`, y publica el tamaño real de los cinco tipos
  por valor del modelo. Guárdalo: la fase 06 lo va a usar.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/record` — `record`,
  `record struct`, `with` y la igualdad generada.
- `https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/struct` — tipos por
  valor, `readonly struct` y semántica de copia.
- `https://learn.microsoft.com/dotnet/csharp/properties` — propiedades, `init`, y la palabra clave
  `field` de C# 14.
- `https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/required` — `required` y
  qué garantiza en el constructor.
- `https://learn.microsoft.com/dotnet/csharp/language-reference/operators/operator-overloading` —
  sobrecarga de operadores, y las reglas sobre qué pares hay que definir juntos.
- `https://learn.microsoft.com/dotnet/api/system.decimal` — `decimal`: 128 bits, base 10, y por qué
  es el tipo del dinero.
- `https://learn.microsoft.com/dotnet/standard/design-guidelines/choosing-between-class-and-struct`
  — la guía oficial para elegir. Es breve, es vieja y sigue siendo correcta.

**Especificación y propuestas del lenguaje**

- `https://github.com/dotnet/csharplang/blob/main/proposals/csharp-9.0/records.md` — la propuesta de
  `record`, que explica **por qué** la igualdad estructural no mira dentro de un arreglo. Es la
  lectura que resuelve la trampa del miniproyecto.
- `https://github.com/dotnet/csharplang/blob/main/proposals/field-keyword.md` — la propuesta de
  `field`, con el problema que venía a resolver.

**Video / apoyo**

- Las charlas de Mads Torgersen sobre el diseño de `record` en las conferencias de .NET explican el
  criterio de "igualdad por valor con miembros de referencia". No se cita un identificador concreto:
  cambian y no se inventan aquí.

> ⚠️ Verifica las URLs: pueden haber cambiado. Y fija la versión en el selector de
> learn.microsoft.com — la mayoría de estas páginas tienen una variante para .NET Framework donde
> `record` no existe, y ese es justo el material que el Bloque B te va a hacer leer por otras
> razones.

**Orden de lectura sugerido:** antes de escribir código, la guía de `class` contra `struct` —tres
páginas y decide la mitad de la fase—. Durante, la referencia de `record` y la de propiedades. Al
terminar, la propuesta de `record` en `csharplang`: se lee distinto cuando ya te mordió la trampa.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Existe `Cordillera.Domain` con seis tipos, cada uno con su decisión de valor o referencia tomada a
propósito y con la igualdad que el dominio necesita. Existe una deuda 💸 declarada —`Money` sin
moneda— con su fase de cobro escrita. Y existe una medición que, cuando la ejecutes, te va a dar los
dos umbrales que sostienen todas las decisiones de tipos del resto del curso.

La fase 02 es el paso natural porque esta fase dejó tres preguntas abiertas y las tres son la misma:
qué significa que un ISBN **no esté**. El fondo antiguo tiene 340 ediciones sin ISBN, `FECNACIM`
tiene `'00000000'` en 4.100 filas, y `SUBTITULO` puede venir vacío o venir `NULL` y no es lo mismo.
El contexto anulable lleva activado desde la fase 00 y el compilador ya te estuvo hablando; la fase
02 es donde se le contesta.

> **La señal de que quedó bien:** *"Puedo explicarle a Duván, sin hablar de rendimiento, por qué
> `Isbn` es un `struct` y `Title` es una clase — y puedo explicarle con un número por qué eso además
> conviene."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el miniproyecto
> corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-01 -m "F1 cerrada:
> - Cordillera.Domain con Isbn, Money, Imprint, Title, Edition y StockItem
> - Isbn validado al construirse: no existe una instancia inválida
> - igualdad por identidad en las entidades, estructural en los valores, con prueba por tipo
> - Money nace con su deuda 💸 declarada y su cobro en la F17
> - medición de las tres implementaciones de Isbn escrita, con su comando"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 01: …`), los de ejercicio su número
> (`fase 01 ej12: …`) y el miniproyecto el suyo (`fase 01 mini: …`), más el tag `mini-01` con el
> número de su medición. La convención está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
>
> Esta fase **no cobra ninguna deuda y planta la primera de verdad**. Cuando llegues a la 17, el
> comando `git diff fase-01 fase-17 -- src/modern/Cordillera.Domain/Money.cs` va a ser la factura de
> haber empezado con un `decimal` desnudo, y va a ser corta — que es justamente el argumento de por
> qué la deuda estaba bien tomada.

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura.*

- **`INSTINTOS.md`** — tres entradas nuevas en la familia de tipos e igualdad: el par
  `get`/`set` a mano, `equals`/`hashCode` a pares, y "todo es referencia" con el bug de la copia en
  la lista. La tercera es la que más vale: es la única que produce un error silencioso.
- **`BENCHMARKS.md`** — entrada ⏳ *F01 · `Isbn` como `class`, `record class` y `record struct`*.
  Al ejecutarla hay que rellenar **los dos umbrales**, porque el segundo —a partir de qué tamaño la
  copia cuesta más que la indirección— lo citan la 06 y la 09.
- **Deuda 💸 registrada:** `Money` sin moneda, cobro en F17. Ya está en el libro de deudas de la
  propuesta §7.1.
- **Para la fase 02:** quedan tres bucles abiertos a propósito — el ISBN en blanco de las 340
  ediciones del fondo, `default(Isbn)`, y la decisión de si `Edition.Isbn` es `Isbn?`. Si la 02 no
  los cierra los tres, esta fase queda debiendo.
- **Para la fase 04:** el miniproyecto prohíbe usar excepciones para el flujo normal y promete el
  número. La 04 tiene que darlo, o la prohibición queda como dogma.
- **Para la fase 06:** el `string.Split` del miniproyecto y el `stackalloc` de `Isbn.Normalize` son
  los dos anzuelos plantados. La 06 debería medir el primero y explicar el segundo.
- **Riesgo detectado:** el modelo tiene `TitleId` y `EditionId` como `record struct` de una cadena.
  Cuando la fase 09 lea `char(10)` con relleno de espacios, hay que decidir **en un solo sitio** si
  el recorte pasa dentro del tipo o en el borde. Anotado para no improvisarlo allí.
