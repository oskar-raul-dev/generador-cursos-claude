# 🕳️ Fase 02 — Nullable reference types y pattern matching

> C# para desarrolladores Java senior · Fase 02 de 24 · Bloque A — el lenguaje y el runtime
> Depende de: 01 · Habilita: 03
> Estilo de esta fase: **nuevo** (.NET 10, C# 14)
> Proyecto que avanza: **el modelo de dominio**. Al terminar, `Cordillera.Domain` distingue por
> tipo entre "no hay ISBN", "hay un ISBN vacío" y "hay un dato que alguien puso en 1997 para que no
> quedara en blanco".

---

## 🎯 1. Propósito

Contestarle al compilador. El contexto anulable lleva activado desde la fase 00 y desde entonces te
viene diciendo cosas; esta fase es donde se aprende **qué te está garantizando de verdad, qué no te
garantiza en absoluto, y cuál de las dos cosas es la que va a romper en producción**.

Y de paso, fijar la decisión de dominio que la fase 01 dejó abierta tres veces: cuando un dato no
está, **eso significa algo**, y el modelo tiene que poder decir qué. En Cordillera la ausencia viene
en tres sabores que el sistema confunde desde 2017, y distinguirlos es la mitad del trabajo del
Bloque B.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Sabes decir en una frase **qué garantiza y qué no garantiza** el contexto anulable, y por qué
      la segunda mitad es la importante.
- [ ] `Edition.Isbn` es `Isbn?` y el modelo explica, en su documentación, qué significa ese `null`.
- [ ] Los tres sabores de ausencia —`NULL`, cadena vacía y `'00000000'`— están representados en el
      modelo de forma que **no se puedan confundir**, y hay una prueba por sabor.
- [ ] `Title.Subtitle` cierra el bucle que dejó la fase 01, con su decisión escrita.
- [ ] Hay exactamente **dos `!` en el código del curso**, los dos con comentario, los dos declarados
      como 💸 y los dos con su fase de cobro.
- [ ] El modelo tiene un `switch` de expresión sobre patrones que el compilador declara exhaustivo,
      y sabes por qué en este curso eso no alcanza.
- [ ] La medición de la sección 6 está escrita con su comando, y la entrada quedó en `BENCHMARKS.md`.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Validación en el borde de una API** —qué devolver, con qué código, con qué formato de error— →
  fase 15. Aquí el borde es un archivo, no una petición HTTP.
- **El esquema heredado de verdad** → fase 07. En esta fase los nombres `MOVINVEN`, `FECMOVTO` y
  `BORRADO` aparecen porque el hábito de escribirlos tal cual se fija ahora, pero no hay ni una
  tabla ni un procedimiento todavía.
- **LINQ** → fase 03. Un `switch` con patrones sobre una colección se escribe aquí con `foreach`.
- **`Result<T>` como tipo de retorno del dominio** y la discusión excepción-contra-resultado →
  fase 04, donde además llega el número que la decide.
- **El mapeo a EF Core y qué hace el ORM con un `Isbn?`** → fase 09, que es donde se cobran las dos
  deudas de esta fase.

---

## 🧠 4. Concepto mínimo

El contexto anulable es **un analizador de flujo, no un sistema de tipos nuevo**. Esa frase es toda
la fase, y conviene desarmarla en las dos mitades que importan.

**Lo que hace.** Cuando declaras `string name`, el compilador se compromete a avisarte si en algún
camino de ejecución ese valor puede ser `null`: al asignarlo, al devolverlo, al pasarlo a un método
que no lo acepta. Y cuando declaras `string? name`, se compromete a avisarte si lo usas sin haber
comprobado antes. El análisis es **por flujo**, así que entiende cosas que parecen sutiles:

```csharp
string? subtitle = LookUpSubtitle(titleId);

if (subtitle is null)
{
    return "sin subtítulo";
}

// Aquí el compilador YA SABE que no es null, porque el camino donde lo era terminó en el return.
// No hace falta el `!`, no hace falta una variable nueva, y usarlos aquí es ruido.
return subtitle.Trim();
```

**Lo que no hace, y es lo que rompe.** No genera ni una comprobación en tiempo de ejecución. Nada.
Las anotaciones se compilan a atributos de metadatos y el CLR las ignora por completo. Eso tiene
tres consecuencias que hay que tener presentes todo el curso:

- **Un dato que entra desde fuera no lo revisa nadie.** Un JSON deserializado, una fila de SQL
  Server, un archivo del distribuidor: el deserializador va a poner `null` en una propiedad
  declarada `string` sin pestañear, y el compilador ya había dado su bendición.
- **Una biblioteca sin anotar te miente sin mala intención.** Si el ensamblado no declara su
  contexto anulable, el compilador asume que todo es "no anulable, sin garantía" y deja de avisarte.
  En este curso eso pasa **en todo el Bloque B**, porque `Sige.DataAccess` es de 2017.
- **El `!` es una afirmación tuya, no una comprobación.** `value!` no verifica nada: le dice al
  compilador *"confía en mí"*. Si te equivocas, el `NullReferenceException` llega igual, solo que
  ahora sin advertencia previa.

> 🧠 **El modelo mental:** el contexto anulable es **un contrato entre tú y el compilador sobre lo
> que escribiste**, no una barrera alrededor de tu programa. Todo lo que cruza la frontera del
> programa —archivos, base de datos, red, reflexión, deserialización— entra sin revisar, y el único
> sitio donde eso se puede atajar es un borde que tú escribas a propósito.

Y de ahí sale la segunda mitad de la fase. Si el trabajo es convertir datos crudos en un modelo
donde la ausencia signifique algo, hace falta una herramienta para **decidir por forma**: eso es el
pattern matching, y en C# es bastante más que un `switch` con tipos.

```csharp
// Un switch de expresión sobre patrones de propiedad: la forma del dato decide el resultado.
// No es azúcar sobre if-else: el compilador comprueba exhaustividad y te avisa de lo que falta.
string Describe(StockItem item) => item switch
{
    { Quantity: 0 } => "agotado",
    { Quantity: < 0 } => "sobrevendido",
    { Quantity: < 10, Warehouse: WarehouseCode.Lim } => "bajo, y en Lima reponer tarda tres semanas",
    { Quantity: < 10 } => "bajo",
    _ => "disponible",
};
```

Las cuatro familias de patrones que este curso usa, y ni una más: **de tipo** (`is Edition edition`),
**de propiedad** (`{ Quantity: 0 }`), **de constante y relacional** (`< 10`, `is not null`), y **de
lista** (`[var first, .., var last]`), que aparece una vez en el Bloque B partiendo una fecha en
`char(8)` y vale su peso en oro justo ahí.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**Primera mitad: `null` como estado válido del dominio.**

En Java, `null` es lo que devuelves cuando no hay nada, y lo que guardas cuando algo todavía no se
sabe. Un `null` significa "no hay ISBN", "no se capturó la fecha", "el sistema no llegó a
calcularlo" y "hubo un error y quedó así", todo con el mismo valor.

```csharp
// ❌ La traducción directa, y el problema no es que compile: es que el modelo no puede responder
//    la pregunta que el negocio hace.
public sealed class Edition
{
    public string? Isbn { get; init; }          // ¿no tiene, o no se capturó?
    public DateTime? PublishedOn { get; init; }  // ¿no se ha publicado, o no se sabe cuándo?
}
```

En Cordillera esas dos preguntas tienen respuestas distintas y consecuencias distintas. 340
ediciones **no tienen** ISBN porque son anteriores a que fuera obligatorio: es un hecho, es
definitivo y es correcto. Otras tienen el campo vacío porque la importación de 2017 no encontró el
dato: eso es una pérdida de información y alguien debería ir a buscarla. Y en once tablas hay
`'00000000'`, que no es ninguna de las dos: es **un valor que alguien escribió para que el campo no
quedara en blanco**, porque en FoxPro una fecha vacía daba problemas al indexar.

```csharp
// ✅ La ausencia se modela cuando significa algo. `null` queda para "no hay", y lo que no es
//    ausencia sino desconocimiento se dice con un tipo.
public sealed class Edition
{
    /// <summary>
    /// Ausente cuando la edición es anterior a 2007 y nunca tuvo ISBN. No se usa para
    /// representar "no lo sabemos": eso es <see cref="IsbnStatus"/>.
    /// </summary>
    public Isbn? Isbn { get; }

    public IsbnStatus IsbnStatus { get; }
}

public enum IsbnStatus
{
    /// <summary>Tiene ISBN y está validado.</summary>
    Assigned,

    /// <summary>Anterior a 2007: no tiene, y es correcto que no tenga.</summary>
    NotApplicable,

    /// <summary>Debería tener y no lo encontramos. Alguien tiene que ir al archivo físico.</summary>
    Missing,
}
```

**Por qué falla el reflejo:** porque `null` no tiene semántica. Dos meses después, cuando Nohora
pregunte *"¿cuántos títulos del fondo hay que ir a buscar al archivo?"*, la respuesta con el primer
modelo es "no se puede saber" — y con el segundo es un filtro.

**Segunda mitad: traducir `Optional<T>` mecánicamente.**

```csharp
// ❌ Lo que escribe alguien que viene de Java 8 y busca el equivalente de Optional.
//    Existe una clase que se parece, y usarla así es peor que no usarla.
public Nullable<Isbn> FindIsbn(EditionId id) { ... }

// Y su primo, el que envuelve todo "por si acaso":
public Maybe<Edition> Find(EditionId id) { ... }   // tipo propio, escrito a mano, 80 líneas
```

```csharp
// ✅ Lo que hace un tipo por valor anulable, que es lo que Nullable<T> es, y el patrón que
//    el framework entero usa para "puede no haber".
public Isbn? FindIsbn(EditionId id) { ... }

// Y para tipos de referencia, la anotación es del tipo y no una envoltura:
public Edition? Find(EditionId id) { ... }
```

**Dónde se rompe el paralelo, y es una diferencia de fondo:** `Optional<T>` de Java es **un objeto
en el montón** que envuelve otro, con su `map` y su `flatMap`. `T?` en C# son dos cosas distintas
según el tipo: para un `struct` es `Nullable<T>`, que es otro `struct` con una bandera adentro —no
asigna—; y para una clase **no es nada en tiempo de ejecución**, solo una anotación para el
compilador. Así que el hábito de encadenar `map` sobre `Optional` no tiene equivalente idiomático:
lo que tiene C# es el operador `?.`, `??`, `??=` y el pattern matching. Escribir un `Maybe<T>`
propio en C# es traer el peso de `Optional` sin ninguno de sus beneficios.

**Tercera mitad, la que este curso persigue con más ganas: el `!` que silencia.**

```csharp
// ❌ El compilador dijo algo. Esto lo hace callar. Compila, y el bug sigue ahí.
var edition = FindEdition(id)!;
Console.WriteLine(edition.Isbn!.Value);
```

Un `!` no arregla nada: apaga la advertencia. Y lo peor no es el `NullReferenceException` que puede
llegar — es que el siguiente que lea el código no va a saber si ese `!` está ahí porque **alguien
verificó y el análisis de flujo no lo entiende** (legítimo) o porque **alguien tenía prisa**
(deuda). Por eso en este curso un `!` sin comentario es un error de estilo, y con comentario es un
💸 con fase de cobro.

### 🩻 Esto sí funciona igual

La disciplina de contratos. Llevas años escribiendo en javadoc *"@param puede ser null"* y
*"@return nunca null"*, y decidiendo en cada método si valida o confía. Todo ese criterio se
transfiere completo — y la única diferencia es que aquí **el compilador lee tu javadoc y te lo hace
cumplir**. La anotación `?` es esa frase, movida de un comentario a la firma.

También se transfiere el instinto de dónde poner la comprobación: una vez en la frontera, no
quinientas veces por dentro. Y los `Objects.requireNonNull` del principio de cada método público
tienen su equivalente exacto, `ArgumentNullException.ThrowIfNull`, que es el que usa el modelo desde
la fase 01.

Y el `switch` con patrones, en lo que respecta al **razonamiento**, es el `sealed interface` +
`switch` que ya escribes en Java moderno. La diferencia es que en C# el compilador no puede
garantizar exhaustividad sobre jerarquías abiertas, así que la rama `_` casi nunca sobra.

### 📖 Diccionario de traducción

| Java | C# / .NET | Dónde se rompe el paralelo |
|---|---|---|
| `@Nullable String s` | `string? s` | Es parte del tipo y el compilador lo hace cumplir; no es una anotación de una herramienta externa |
| `Optional<T>` | `T?` | Para un `struct` es `Nullable<T>` (no asigna); para una clase **no existe en tiempo de ejecución**. No hay `map`/`flatMap` |
| `Optional.orElse(x)` | `valor ?? x` | Operador del lenguaje, no un método. Y `??=` asigna solo si era `null` |
| `Optional.map(f).orElse(null)` | `valor?.Metodo()` | `?.` corta la cadena entera y devuelve `null`; no hay envoltura que desenvolver |
| `Objects.requireNonNull(x)` | `ArgumentNullException.ThrowIfNull(x)` | Igual, y el nombre del parámetro lo captura el compilador |
| `if (x != null)` | `if (x is not null)` | `is not null` no se puede sobrecargar; `!=` sí, y en un tipo con operadores puede hacer otra cosa |
| `instanceof Edition e` | `is Edition edition` | Igual, y además admite patrones de propiedad anidados |
| `switch` con `sealed interface` | `switch` de expresión | El compilador **no** garantiza exhaustividad sobre jerarquías abiertas: la rama `_` sigue hacia falta |
| `@SuppressWarnings("null")` | `!` (null-forgiving) | Es por expresión, no por método o clase. Más quirúrgico, y por eso más fácil de auditar |
| `NullPointerException` | `NullReferenceException` | Mismo fallo, otro nombre. Los mensajes de .NET modernos dicen **qué** era null, y eso ahorra tiempo |

> ⚠️ **La fila del `is not null` merece un comentario.** En un tipo que sobrecarga `==` —como
> `Money`, de la fase 01— `x != null` invoca **tu** operador, y si tu operador hace algo raro con
> `null`, el resultado es raro. `is not null` es una comprobación del lenguaje que nadie puede
> redefinir. En código de dominio con operadores sobrecargados, la diferencia importa.

> 📝 **Nota de ecosistema.** El contexto anulable llegó con C# 8 en 2019, y **es opcional por
> proyecto** precisamente porque activarlo sobre código existente produce cientos de advertencias.
> Eso explica dos cosas que vas a ver todo el curso: que las plantillas nuevas lo traigan activado y
> que casi ningún proyecto real de más de cinco años lo tenga. `Sige.DataAccess`, que es de 2017, no
> solo no lo tiene: **es anterior a que existiera**, así que cuando el código nuevo lo consuma, el
> compilador va a callarse justo donde más falta hace hablar. Esa es la conversación de la fase 09.

---

## 💻 5. Código mínimo con comentarios

### 5.1 Los tres sabores de ausencia, con nombre

Esto es lo que la fase agrega al modelo, y es una decisión de dominio antes que de lenguaje.

```csharp
// src/modern/Cordillera.Domain/LegacyDate.cs
namespace Cordillera.Domain;

/// <summary>
/// Una fecha que viene de un `char(8)` del esquema de 1997, con los tres estados que el sistema
/// confunde desde entonces.
/// </summary>
/// <remarks>
/// Existe porque `DateOnly?` no alcanza: un `null` no distingue "la columna venía NULL" de "la
/// columna traía '00000000'", y esas dos cosas se originaron de formas distintas y se arreglan de
/// formas distintas. `'00000000'` es lo que la importación de 2017 escribió donde FoxPro tenía una
/// fecha vacía, porque una fecha vacía daba problemas al indexar; `NULL` es lo que quedó donde
/// nadie escribió nada.
/// </remarks>
public readonly record struct LegacyDate
{
    private LegacyDate(DateOnly? value, LegacyDateKind kind)
    {
        Value = value;
        Kind = kind;
    }

    /// <summary>La fecha, cuando hay una de verdad.</summary>
    public DateOnly? Value { get; }

    public LegacyDateKind Kind { get; }

    public bool HasValue => Kind == LegacyDateKind.Present;

    /// <summary>
    /// Interpreta lo que venga de la columna. Es el único sitio del curso donde se decide qué
    /// significa cada forma de vacío, y por eso está aquí y no repartido en veinte consultas.
    /// </summary>
    public static LegacyDate FromLegacy(string? raw) => raw switch
    {
        // El orden importa: '00000000' es una cadena con contenido, así que tiene que ir antes
        // que la comprobación de vacío o nunca se alcanzaría.
        null => new LegacyDate(null, LegacyDateKind.WasNull),
        "00000000" => new LegacyDate(null, LegacyDateKind.PlaceholderFrom2017),
        "" or " " => new LegacyDate(null, LegacyDateKind.WasBlank),

        // Patrón de lista sobre los caracteres: ocho dígitos, año-mes-día. Es más claro que tres
        // Substring y no asigna cadenas intermedias.
        [var y1, var y2, var y3, var y4, var m1, var m2, var d1, var d2]
            when IsAllDigits(y1, y2, y3, y4, m1, m2, d1, d2) =>
                Parse(raw),

        _ => new LegacyDate(null, LegacyDateKind.Unparseable),
    };

    private static LegacyDate Parse(string raw)
    {
        int year = int.Parse(raw.AsSpan(0, 4));
        int month = int.Parse(raw.AsSpan(4, 2));
        int day = int.Parse(raw.AsSpan(6, 2));

        // Hay 60 filas con mes 00 y día 00 pero año válido: alguien capturó solo el año. No es
        // una fecha, y decir que es el 1 de enero sería inventar un dato.
        if (month is < 1 or > 12 || day < 1)
        {
            return new LegacyDate(null, LegacyDateKind.PartialOnlyYear);
        }

        // Y hay 14 filas con día 31 en meses de 30. DateOnly se niega, y el modelo lo reporta en
        // vez de corregirlo: corregir aquí sería perder la evidencia de que el dato está mal.
        if (day > DateTime.DaysInMonth(year, month))
        {
            return new LegacyDate(null, LegacyDateKind.Unparseable);
        }

        return new LegacyDate(new DateOnly(year, month, day), LegacyDateKind.Present);
    }

    private static bool IsAllDigits(params ReadOnlySpan<char> characters)
    {
        foreach (char c in characters)
        {
            if (!char.IsAsciiDigit(c))
            {
                return false;
            }
        }

        return true;
    }

    public override string ToString() => Kind switch
    {
        LegacyDateKind.Present => Value!.Value.ToString("yyyy-MM-dd"),
        LegacyDateKind.PlaceholderFrom2017 => "sin fecha (relleno de 2017)",
        LegacyDateKind.PartialOnlyYear => "solo año",
        LegacyDateKind.WasNull => "sin dato",
        LegacyDateKind.WasBlank => "en blanco",
        _ => "ilegible",
    };
}

/// <summary>
/// Por qué una fecha del esquema heredado no tiene valor. Cada miembro corresponde a un origen
/// distinto y a una acción distinta de quien tenga que arreglarlo.
/// </summary>
public enum LegacyDateKind
{
    Present,

    /// <summary>La columna traía `NULL`. Nadie escribió nunca ahí.</summary>
    WasNull,

    /// <summary>La columna traía cadena vacía. Alguien borró el contenido.</summary>
    WasBlank,

    /// <summary>La columna traía `'00000000'`: el relleno que dejó la importación de 2017.</summary>
    PlaceholderFrom2017,

    /// <summary>Año válido, mes y día en cero: se capturó solo el año.</summary>
    PartialOnlyYear,

    /// <summary>Ocho caracteres que no forman una fecha.</summary>
    Unparseable,
}
```

**Detalles con intención**

- **`ToString` tiene un `!` y no es deuda.** `Value!.Value` dentro de la rama `Present` es correcto
  por construcción: esa rama solo existe cuando `Value` tiene valor. El análisis de flujo no puede
  ver la relación entre `Kind` y `Value` —son dos miembros independientes para él— y esa es
  exactamente la clase de sitio donde el `!` es legítimo. **Va con su comentario, siempre.**
- **El orden de las ramas del `switch` es semántico**, no estético: `"00000000"` antes que la
  comprobación de vacío. Es el tipo de error que el compilador no atrapa y una prueba sí.
- **`params ReadOnlySpan<char>`** es de C# 13 en adelante y evita asignar un arreglo por llamada.
  Aparece aquí porque el método se ejecuta una vez por fila y las filas son 500.000 en el Bloque B;
  la fase 06 vuelve sobre esto con la medición.
- **Nada se corrige.** Un día 31 en un mes de 30 se reporta como ilegible, no se mueve al 30.
  Corregir en el borde es perder la única evidencia de que el dato está mal, y en un sistema donde
  la evidencia sostiene una liquidación impugnada, eso no es inocuo.

### 5.2 El ISBN ausente, y el bucle que la fase 01 dejó abierto

```csharp
// src/modern/Cordillera.Domain/Edition.cs — lo que esta fase cambia
public sealed class Edition
{
    public Edition(
        EditionId id,
        TitleId titleId,
        Isbn? isbn,
        IsbnStatus isbnStatus,
        EditionFormat format,
        Money listPrice)
    {
        // La combinación imposible se cierra en el constructor: no existe una Edition que diga
        // "tiene ISBN asignado" y no lo traiga. Es la misma idea que valida `Isbn` al construirse,
        // un nivel más arriba.
        if (isbnStatus == IsbnStatus.Assigned && isbn is null)
        {
            throw new ArgumentException(
                "Una edición con ISBN asignado tiene que traer el ISBN.", nameof(isbn));
        }

        if (isbnStatus != IsbnStatus.Assigned && isbn is not null)
        {
            throw new ArgumentException(
                $"Una edición con estado {isbnStatus} no puede traer ISBN.", nameof(isbnStatus));
        }

        Id = id;
        TitleId = titleId;
        Isbn = isbn;
        IsbnStatus = isbnStatus;
        Format = format;
        ListPrice = listPrice;
    }

    /// <summary>
    /// El ISBN, cuando hay. `null` significa **una** cosa y lo dice
    /// <see cref="IsbnStatus"/>: si es `NotApplicable`, la edición es anterior a 2007 y nunca tuvo;
    /// si es `Missing`, debería tener y hay que ir a buscarlo al archivo físico.
    /// </summary>
    public Isbn? Isbn { get; }

    public IsbnStatus IsbnStatus { get; }

    // … el resto, igual que en la fase 01
}
```

Y el subtítulo, que era el tercer bucle:

```csharp
/// <summary>
/// El subtítulo. `null` cuando el título no tiene, que es el caso normal. **Nunca cadena vacía**:
/// el borde de datos convierte `""` en `null` porque en este dominio no significan cosas
/// distintas — a diferencia de las fechas, donde sí.
/// </summary>
public string? Subtitle
{
    get;
    set => field = string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
```

**El patrón a memorizar**

> **Una ausencia sin significado es `null`; una ausencia con significado es un tipo.** El subtítulo
> que no está no necesita explicación, así que `null` alcanza. La fecha que no está tiene cinco
> orígenes distintos y cada uno le cuesta a alguien un trabajo distinto, así que necesita un tipo.
> Confundir esos dos casos produce, en el primer sentido, ceremonia; y en el segundo, un informe que
> nadie puede accionar.

### 5.3 Cómo se contesta a una advertencia, con los cuatro casos reales

Hay exactamente cuatro respuestas legítimas a un `CS8600`, y saber cuál toca es el oficio de esta
fase:

```csharp
// 1. El compilador tiene razón y hay un bug. Se arregla el código.
// ❌ antes
Edition edition = FindEdition(id);       // CS8600: puede ser null
// ✅ después
Edition? edition = FindEdition(id);
if (edition is null)
{
    return ImportOutcome.Rejected("la edición no está en el catálogo");
}

// 2. El compilador tiene razón y la anotación estaba mal. Se arregla la firma.
// ❌ antes: devuelve null en tres caminos y lo declara no anulable
public static Edition FindEdition(EditionId id)
// ✅ después
public static Edition? FindEdition(EditionId id)

// 3. Tú tienes razón y el análisis de flujo no puede verlo. Va `!` CON comentario.
//    Esta rama solo existe cuando Value tiene valor: Kind y Value son dos miembros
//    independientes para el compilador, y la relación entre ellos la garantiza el constructor.
LegacyDateKind.Present => Value!.Value.ToString("yyyy-MM-dd"),

// 4. Tú tienes razón y se puede DEMOSTRAR en vez de afirmar. Es la mejor de las cuatro, y la
//    que casi nadie usa: los atributos de anulabilidad enseñan al análisis de flujo.
public static bool TryParse(string? candidate, [NotNullWhen(true)] out Isbn? isbn)
```

**Detalles con intención**

- **El caso 4 es el que separa a quien sabe usar esto.** `[NotNullWhen(true)]`,
  `[MemberNotNull]`, `[NotNullIfNotNull]` mueven la garantía del comentario al metadato, y entonces
  **quien llame a tu método deja de necesitar `!`**. Es contagioso en el buen sentido: una firma
  bien anotada borra advertencias en el código de otros.
- **El caso 3 se audita.** `grep -rn '!\.' src/modern/` tiene que caber en una pantalla, y cada
  ocurrencia debe tener su comentario arriba.

> 💸 **Deuda declarada: dos `!` en el borde de datos.**
>
> ```csharp
> // 💸 F09 — El lector del archivo del distribuidor asume dos cosas que el archivo no garantiza:
> // que la columna CODEDIT nunca viene vacía, y que MONEDA siempre trae tres letras. Con los
> // datos de DISMEX es cierto hoy. Lo correcto es decidir qué hacer con cada caso en el borde,
> // y el borde de verdad —el que traduce el esquema al modelo— nace en la fase 09.
> var editionId = new EditionId(columns[0]!);
> var currency = columns[6]!;
> ```
>
> **Se pagan en la fase 09**, que es donde el borde 🧬 existe y donde hay un sitio correcto para
> tomar esa decisión. La factura será
> `git diff fase-02 fase-09 -- src/fases/02-nullable-y-pattern-matching/`.
>
> **Por qué se dejan:** porque el borde de esta fase lee **un archivo**, y el borde que importa lee
> **el esquema**. Escribir hoy la política completa de nulos para un CSV de cuarenta mil líneas y
> reescribirla entera en la fase 09 sería trabajo tirado; declararla es más honesto que fingir que
> no está.

### 5.4 Lo que el compilador cree y el dato desmiente

```csharp
// Esta es la sección que hay que ejecutar una vez, porque leerla no alcanza.
public sealed class ImportRow
{
    // Declarado no anulable. El compilador está tranquilo.
    public string EditionCode { get; init; } = string.Empty;
    public string Currency { get; init; } = string.Empty;
}

// Y ahora el dato entra desde fuera:
string json = """{ "editionCode": null, "currency": "COP" }""";
ImportRow row = JsonSerializer.Deserialize<ImportRow>(json)!;

Console.WriteLine(row.EditionCode is null);   // True.
Console.WriteLine(row.EditionCode.Length);    // NullReferenceException, sin una advertencia previa
```

**Prueba de fuego**

Compila lo de arriba con advertencias como errores. **Compila sin una sola advertencia**, y explota
en tiempo de ejecución.

Y la mentira que te va a contar la salida si miras el lugar equivocado: el `!` de
`Deserialize<ImportRow>(json)!` parece el culpable, porque es el único `!` a la vista. No lo es: ese
`!` solo afirma que el resultado de `Deserialize` no es `null`, y es verdad. El problema está dos
líneas arriba, en un `init` declarado no anulable que el deserializador rellenó con `null` sin
consultar a nadie.

> 🧭 **La regla que fija esta fase:** *el contexto anulable es un contrato sobre el código que tú
> escribes. Todo lo que entra al programa desde fuera —archivo, base, red, deserialización— cruza
> sin revisar, y el único sitio donde eso se ataja es un borde que tú escribas a propósito.*

---

## 📏 6. Medición

**Hipótesis:** activar el contexto anulable sobre código que no lo tenía produce muchas advertencias,
**y la mayoría no son bugs**: son anotaciones que faltan. La proporción de bugs reales es lo bastante
baja como para que el valor del ejercicio esté en las pocas que sí lo son, y lo bastante alta como
para que valga la pena hacerlo.

**Condiciones:** SDK 10.0.401 · compilación Release · el mismo código en dos configuraciones,
`<Nullable>disable</Nullable>` y `enable` · el objeto de medida son **`Cordillera.Domain` y el
importador del miniproyecto de la fase 01 reescritos sin anotaciones**, unas 900 líneas, que es el
tamaño de un módulo real y no de un ejemplo.

> 📝 **El instrumento de esta medición no es el arnés, es el compilador.** Está permitido y se
> declara (`formato-de-mediciones.md` §1): lo que se cuenta son advertencias, clasificaciones y
> minutos, no milisegundos. El arnés reaparece en la fase 03.

**Competidores:** no hay dos implementaciones compitiendo; hay **una clasificación**, y el rigor
está en que la haga alguien que no escribió el código. Las tres categorías se fijan antes de
contar, para no acomodar el resultado:

- **Bug real** — existe un camino de ejecución donde ese valor es `null` y el programa falla o hace
  algo incorrecto.
- **Anotación faltante** — el código es correcto, la firma mentía. Se arregla la firma.
- **Ruido** — el análisis de flujo no puede ver una garantía que sí existe. Se resuelve con un
  atributo de anulabilidad, o con un `!` comentado si no hay atributo que sirva.

**El comando:**

```powershell
# Contar: se desactivan las advertencias como errores para que el build llegue al final
dotnet build src\modern\Cordillera.Domain -c Release -p:Nullable=enable -p:TreatWarningsAsErrors=false `
  /warnaserror:none /nologo /v:q /p:GenerateFullPaths=true | Select-String "CS86|CS87" | Measure-Object
```

**Resultado:** ⏳ pendiente de ejecución en tu máquina.

| Categoría | Advertencias | % del total | Minutos hasta cero |
|---|---|---|---|
| Bug real | ⏳ | ⏳ | ⏳ |
| Anotación faltante | ⏳ | ⏳ | ⏳ |
| Ruido (atributo o `!` comentado) | ⏳ | ⏳ | ⏳ |
| **Total** | ⏳ | 100% | ⏳ |

> ⚖️ **Veredicto** *(expectativa, todavía sin ejecutar — `formato-de-mediciones.md` §2.6)*. Se
> espera que los bugs reales sean **minoría clara** y que la mayor parte sean anotaciones que
> faltaban. Lo que hace valiosa la medición no es el total: es que **cada bug real de esa columna
> era un `NullReferenceException` en producción esperando su turno**, y que el precio de encontrarlos
> fue una tarde de anotaciones.
>
> **El umbral que tu ejecución tiene que determinar:** a partir de qué proporción de ruido sobre
> total deja de valer la pena activarlo módulo por módulo y conviene hacerlo por proyecto entero.
> Ese número es el que decide, en la fase 09 y en la 11, **si el código de 2017 se anota o se deja
> con el contexto desactivado** — y anticipo la respuesta incómoda: para las 250.000 líneas de SIGE,
> la respuesta va a ser que no se anota.

---

## 🧱 7. Miniproyecto — lo que devuelve `SP_EXIST_ALMACEN`, convertido en un modelo que significa algo

**El encargo**

Duván te manda un archivo: *"Te exporté lo que devuelve `SP_EXIST_ALMACEN` para el almacén de Lima,
tal cual sale, con las columnas como están. Es lo que consume el formulario de existencias. Ojo con
las fechas: hay de todo. Lo que necesito saber es cuántos de esos movimientos podemos reportarle a
la contadora con fecha confiable y cuántos no, porque ella me pidió el corte del trimestre y yo no
sé qué contestarle. Y no me los borres: si no sirven, quiero saber cuáles son."*

**Por qué duele**

Porque todas las columnas llegan anulables —es lo que devuelve un procedimiento sin `NOT NULL` en
ninguna parte— y el trabajo no es hacerlas no anulables: es **decidir, columna por columna, qué
significa que no esté**, y que el modelo resultante pueda responder la pregunta de la contadora sin
que nadie tenga que volver al archivo.

Y porque el compilador te va a acompañar hasta la puerta y ahí te va a soltar: dentro de tu código
te avisa de todo, y el dato entra por un `string.Split` que no revisa nada.

**Datos de entrada**

La exportación literal, con las columnas como las devuelve el procedimiento — **nombres del esquema,
sin traducir**. El archivo completo son 4.300 filas; este fragmento tiene un caso de cada cosa.

```text
NROMOVTO|CODALMA|CODEDIT|FECMOVTO|TIPOMOVTO|CANTIDAD|VLRUNIT|NRODOCTO|CODUSUA|BORRADO
118423|LIM|ED00001234|20260304|S|12|68000.00|FAC-0098231|dcifuente|N
118424|LIM|ED00001235|00000000|E|200|95000.00|OC-2026-0044|dcifuente|N
118425|LIM|ED00001236||A|-3|42000.00||wpardo|N
118426|LIM|ED00009999|20260215|S|4|38000.00|FAC-0098240|dcifuente|N
118427|LIM|ED00001237|20260231|E|50|55000.00|OC-2026-0051|dcifuente|N
118428|LIM|ED00001238|20260000|S|7|38000.00|FAC-0098255|nprieto|S
118429|LIM|ED00001239|20260118|D|-15|25000.00|NC-2026-0009||N
118430|LIM|ED00001240|20251228|S|9|NULL|FAC-0097112|dcifuente|N
```

Qué tiene cada fila, y todas salen de la historia del sistema:

- **118424** — `FECMOVTO = '00000000'`: el relleno de 2017. Hay 210 filas así.
- **118425** — `FECMOVTO` vacío y `NRODOCTO` vacío: es un **ajuste** (`TIPOMOVTO = 'A'`) de los que
  se hicieron en 2018 sin documento de respaldo. Cantidad negativa, que es válida.
- **118426** — `CODEDIT` apunta a una edición **que no existe**. Hay 1.900 así, y no es un error de
  este archivo: es el estado de la base desde que no hay llaves foráneas.
- **118427** — `20260231`: 31 de febrero. Ocho caracteres, todos dígitos, y no es una fecha.
- **118428** — mes y día en cero, **y `BORRADO = 'S'`**. Ojo con este: media consulta del sistema
  olvida filtrar esa bandera.
- **118429** — `CODUSUA` vacío: movimiento hecho por un proceso automático antes de que el campo se
  volviera obligatorio.
- **118430** — `VLRUNIT` con el literal `NULL`, porque así lo escribió la exportación. No es la
  cadena vacía y no es un número.

**Criterios de aceptación**

1. Un programa que lee el archivo y produce tres salidas: los movimientos **con fecha confiable**,
   los movimientos **sin fecha confiable con su motivo** —y el motivo distingue los cinco sabores de
   `LegacyDateKind`—, y un conteo por motivo que responda la pregunta de la contadora en una línea.
2. Ninguna fila se pierde y **ninguna fila se corrige**: el 31 de febrero no se convierte en 28, y
   `'00000000'` no se convierte en nada.
3. Las filas con `BORRADO = 'S'` se excluyen del reporte **y se cuentan aparte**, porque la pregunta
   "¿cuántas había borradas?" es la que va a aparecer después.
4. El modelo distingue por **tipo** —no por comentario ni por convención de cadena— entre `NULL`,
   cadena vacía, el literal `"NULL"`, `'00000000'` y una fecha de verdad. Una prueba por caso.
5. En todo tu código hay **como máximo dos `!`**, los dos con comentario, y ninguno en el camino que
   procesa las filas.
6. **Medición de cierre:** el conteo total por categoría y el tiempo de procesar las 4.300 filas,
   medido con el arnés. Esos números van en el mensaje del tag `mini-02`.

**Restricciones de estilo y alcance**

Código nuevo, nullable activado, advertencias como errores. **Los nombres de las columnas se
escriben tal cual** —`NROMOVTO`, `FECMOVTO`, `BORRADO`— y el mapeo al modelo vive en un solo sitio
marcado 🧬: es el primer borde del curso, en pequeño, y en la fase 09 vas a escribir el de verdad.

Sin LINQ —fase 03— y sin paquetes. `File.ReadLines` y `Split` alcanzan.

**La trampa**

El compilador te va a dejar tranquilo, y va a tener razón: dentro de tu código no hay ni un camino
donde un valor no comprobado se use. Vas a terminar el miniproyecto con cero advertencias.

Y va a fallar con el archivo completo.

Porque hay una fila, entre las 4.300, donde el `Split` devuelve **menos columnas de las que
esperas** —un `NRODOCTO` con el separador adentro, cortesía de alguien que escribió un número de
factura a mano en 2019— y `columns[7]` no existe. El contexto anulable no dice nada de eso: `null`
y "no hay elemento" son dos problemas distintos, y solo del primero te avisa el compilador.

Cuando te pase, arréglalo **sin** poner un `try`/`catch` alrededor del bucle, y escribe en dos
líneas por qué el contexto anulable no podía haberte protegido de esto.

<details><summary>Pista 1 — el enfoque</summary>

Dos capas, y la de arriba no sabe nada de cadenas. Una convierte una línea cruda en algo con forma
—donde cada columna ya está interpretada y su ausencia tiene nombre— y la otra decide qué reportar.
El tipo intermedio es el que hace fácil el resto, y no es `string[]`.

Y para el conteo por motivo, un diccionario indexado por el `enum` de la sección 5.1 basta; no hace
falta nada más elaborado.

</details>

<details><summary>Pista 2 — la herramienta</summary>

`LegacyDate.FromLegacy` de la sección 5.1 resuelve la mitad, pero **no el literal `"NULL"`**: eso lo
tienes que decidir tú, y es la decisión de diseño de este miniproyecto. ¿Es `WasNull`, porque eso es
lo que la exportación quiso decir? ¿O es `Unparseable`, porque el modelo no debería conocer los
detalles de cómo alguien exportó un archivo? Las dos se defienden; elige y escribe por qué.

Para los patrones sobre el arreglo de columnas, lee patrones de lista y el patrón `..`:
`https://learn.microsoft.com/dotnet/csharp/language-reference/operators/patterns#list-patterns`

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```csharp
// Lo que sale de una línea, con cada columna ya interpretada. Ninguna es `string` cruda.
internal sealed record MovementRow(
    int Number,
    WarehouseCode Warehouse,
    EditionId Edition,
    LegacyDate MovedOn,
    MovementKind Kind,
    int Quantity,
    Money? UnitPrice,
    string? DocumentNumber,
    string? UserCode,
    bool IsLogicallyDeleted);

// Devuelve la fila, o el motivo por el que la línea no es una fila. Nunca las dos.
internal static bool TryParseLine(ReadOnlySpan<char> line, out MovementRow row, out string reason);

internal sealed record DateConfidenceReport(
    int Reliable,
    IReadOnlyDictionary<LegacyDateKind, int> Unreliable,
    int LogicallyDeleted);
```

</details>

**Cómo se entrega**

```powershell
dotnet test src\Cordillera.slnx -c Release
dotnet run -c Release --project src\fases\02-nullable-y-pattern-matching\mini -- datos\sp-exist-almacen-lim.txt
```

```bash
git tag -a mini-02 -m "Mini F2: existencias de LIM con la ausencia tipada · 4.300 filas en <X> ms · <N> con fecha confiable, <M> sin, <K> borradas"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Convierte `Title.Name` en `string` no anulable garantizado por el constructor y muestra qué
   advertencia desaparece. Después quita la validación y muestra qué advertencia aparece.
2. Escribe el `switch` de expresión que convierte `TIPOMOVTO` —`E`, `S`, `A`, `D`— en
   `MovementKind`, y decide qué hace con un valor desconocido. Recuerda que `(MovementKind)99`
   compila.
3. Reemplaza tres `if (x != null)` del modelo por `is not null` y explica en qué caso concreto del
   modelo de la fase 01 la diferencia importaría.
4. Escribe una prueba que demuestre que `LegacyDate.FromLegacy("00000000")` y
   `LegacyDate.FromLegacy(null)` producen valores **distintos**, y que explique en su nombre por qué
   eso importa.
5. Usa `??=` para dar un valor por defecto a `Subtitle` solo si no hay ninguno, y di por qué el
   modelo de la sección 5.2 **no** lo hace.
6. Agrega al modelo un `switch` con patrón de propiedad que clasifique un `StockItem` en agotado,
   bajo, normal o sobrevendido, y que el compilador acepte sin rama `_`. ¿Se pudo? Explica.

**🟡 Intermedio (7–14)**

7. Anota `Isbn.TryParse` con `[NotNullWhen(true)]` y muestra, con el código que lo llama, qué
   advertencia deja de aparecer. Es el caso 4 de la sección 5.3.
8. Escribe un método con `[MemberNotNull]` que garantice que después de llamarlo un campo ya no es
   `null`. Di qué problema resuelve que no resuelva mover la asignación al constructor.
9. Usa `[NotNullIfNotNull]` en un método que devuelve `null` solo si su entrada era `null`.
   Encuentra un caso real en el modelo donde sirva.
10. Deserializa con `System.Text.Json` un objeto con una propiedad `required` ausente y otra
    declarada no anulable con valor `null`. Explica por qué una lanza y la otra no.
11. Escribe el patrón de lista que parte `'20260304'` en año, mes y día, y compáralo en
    legibilidad con tres `Substring`. Mide si hay diferencia de asignaciones con el arnés.
12. Toma un método del modelo, declara todos sus parámetros anulables y arregla las advertencias
    resultantes **sin usar `!`**. Cuenta cuántas líneas creció.
13. Escribe un tipo `Maybe<T>` como lo escribiría alguien que viene de Java, úsalo en tres sitios y
    después quítalo. Anota qué se ganó y qué se perdió en cada versión.
14. Activa `<Nullable>annotations</Nullable>` —solo anotaciones, sin advertencias— en un proyecto de
    prueba y explica en qué situación real del Bloque B ese modo intermedio sería el correcto.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Un servicio devuelve `Edition` declarado no anulable y en producción llega un
    `NullReferenceException` desde el código que lo llama, que sí comprueba `is not null`. Enumera
    tres causas posibles —una de ellas involucra un ensamblado sin anotar— y di cómo distinguirlas.
16. **Diagnóstico.** Te entregan un módulo con 40 `!` y cero advertencias. Escribe el procedimiento
    para auditarlo: en qué orden mirarías, qué clasificarías como legítimo, y cuál es la primera
    pregunta que harías por cada uno.
17. **Medición.** Ejecuta la medición de la sección 6 completa sobre el modelo sin anotar, con la
    clasificación hecha por alguien más si puedes. Publica la tabla con su veredicto y **su umbral**.
18. **Medición.** Compara el costo en tiempo de validar con `ArgumentNullException.ThrowIfNull` en
    cada método público contra validar solo en la frontera, sobre un millón de llamadas. Di si el
    resultado cambia tu criterio.
19. El modelo tiene dos miembros relacionados que el compilador ve como independientes —`Isbn` e
    `IsbnStatus`— y por eso hace falta un `!`. Rediseña el tipo para que la relación sea
    estructural y el `!` desaparezca. Compara las dos versiones y elige, con argumentos.
20. **Decisión — ¿se migra, se envuelve o se deja quieto?** `Sige.DataAccess` son unas 8.000 líneas
    de 2017 sin contexto anulable. Decide qué hace este curso: anotarlo, envolverlo tras una capa
    anotada, o dejarlo y anotar solo la frontera. Sostén la decisión con el umbral del ejercicio 17.
21. **Decisión — ¿se migra, se envuelve o se deja quieto?** Las 210 filas con `'00000000'` en
    `FECMOVTO` podrían corregirse con un `UPDATE` de una línea, y el modelo se simplificaría.
    Decide, y di qué se pierde al corregir y qué se paga al convivir.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Escribe código que compile sin una sola advertencia con el contexto anulable
    activado y lance `NullReferenceException` de forma **determinista**, sin usar `!`, sin
    reflexión y sin deserialización. *(Hay más de una respuesta; una tiene que ver con `struct` y
    otra con inicialización.)*
23. **Adversarial.** Haz que el análisis de flujo del compilador "sepa" algo falso: consigue que
    trate un valor como no nulo cuando puede serlo, usando únicamente atributos de anulabilidad
    correctamente escritos. Explica qué implica eso sobre en quién se está confiando.
24. **Diseño y medición.** Diseña la política de nulos del borde 🧬 que la fase 09 va a necesitar:
    qué se rechaza, qué se acepta con su sabor de ausencia, qué se registra y qué se cuenta.
    Escríbela como una página que la fase 09 pueda seguir, y **mide** cuántas de las 4.300 filas del
    miniproyecto caen en cada categoría.
25. **Defiende una decisión.** Clara pregunta por qué el reporte de existencias del trimestre tiene
    tres números en vez de uno, y si eso no es complicar las cosas. Respóndele en media página, en
    su lenguaje, usando los conteos del miniproyecto y explicando qué riesgo legal cubre distinguir
    "no hay fecha" de "la fecha dice 31 de febrero".

**🔥 Opcionales**

- Escribe un analizador de Roslyn que exija que todo `!` tenga un comentario en la línea anterior.
  Es la regla de esta fase, sostenida por el compilador en vez de por la revisión de código.
- Investiga `NullabilityInfoContext` —la API que lee anotaciones por reflexión— y escribe una
  herramienta que liste los miembros no anulables de un tipo. Sirve para auditar un ensamblado ajeno.
- Toma un paquete popular sin anotar, escribe su archivo de anotaciones externas, y anota qué tan
  lejos llegaste antes de aburrirte. Es el ejercicio que explica por qué la respuesta del ejercicio
  20 va a ser "no se anota".

---

## 📚 9. Referencias

**Documentación oficial**

- `https://learn.microsoft.com/dotnet/csharp/nullable-references` — el contexto anulable, qué
  garantiza, y los modos `enable`, `annotations`, `warnings` y `disable`.
- `https://learn.microsoft.com/dotnet/csharp/language-reference/attributes/nullable-analysis` — los
  atributos de anulabilidad. **Es la página que separa a quien usa esto bien**: es el caso 4 de la
  sección 5.3, y casi nadie la lee.
- `https://learn.microsoft.com/dotnet/csharp/language-reference/operators/patterns` — todos los
  patrones, incluidos los de lista y el `..`.
- `https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression` — el
  `switch` de expresión y qué exhaustividad comprueba el compilador.
- `https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/nullable-value-types`
  — `Nullable<T>`, que es otra cosa que `string?` aunque se escriba igual.
- `https://learn.microsoft.com/dotnet/csharp/nullable-migration-strategies` — cómo se activa esto
  sobre código existente. Es la lectura del ejercicio 20 y de la fase 09.

**Especificación y propuestas del lenguaje**

- `https://github.com/dotnet/csharplang/blob/main/proposals/csharp-8.0/nullable-reference-types-specification.md`
  — la especificación. El apartado sobre el estado de flujo explica por qué el compilador "sabe" más
  de lo que parece en algunos sitios y menos en otros.

**Video / apoyo**

- Las charlas de Mads Torgersen sobre el diseño del contexto anulable explican por qué se eligió
  advertir en vez de impedir, que es la decisión que lo hace útil y a la vez insuficiente. No se
  cita identificador: cambian.

> ⚠️ Verifica las URLs. Y una advertencia específica: **casi todo el material sobre "cómo evitar
> NullReferenceException" que vas a encontrar es anterior a 2019** y por tanto anterior al contexto
> anulable; propone patrones defensivos que hoy son ruido. En este curso el material viejo es
> peligroso porque el sistema heredado **es** de esa época y parece darle la razón.

**Orden de lectura sugerido:** antes de escribir, la página de `nullable-references` completa —es
larga y vale—. Durante el miniproyecto, la de patrones. Y al cerrar, la de atributos de
anulabilidad: se lee distinto cuando ya te peleaste con un `!` que no querías poner.

---

## 🚀 10. Cierre y conexión con la siguiente fase

El modelo ya puede decir tres cosas que antes no: que una edición **no tiene** ISBN y es correcto,
que **debería tenerlo** y hay que ir a buscarlo, y que una fecha no está por cinco razones
distintas, cada una con un dueño distinto. Quedan dos `!` en el curso, los dos declarados, y una
regla que no se suelta: lo que entra desde fuera no lo revisa el compilador.

La fase 03 es el paso natural por una razón concreta: el miniproyecto de esta fase recorre 4.300
filas con `foreach` porque LINQ estaba prohibido, y el de la siguiente recorre el catálogo entero
componiendo consultas. Ahí aparece el bug más caro que produce este perfil al cruzar —**recorrer dos
veces un `IEnumerable`**— y no hay ninguna excepción que te avise, a diferencia del Stream consumido
de Java, que sí te lo dice. Es la fase ⭐ del bloque, y no por gusto.

> **La señal de que quedó bien:** *"No tengo `!` que no pueda explicar, y cuando el compilador se
> calla, sé si es porque no hay problema o porque no puede verlo."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el miniproyecto
> corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-02 -m "F2 cerrada:
> - Edition.Isbn es Isbn? con IsbnStatus, y la combinación imposible la cierra el constructor
> - LegacyDate distingue los cinco sabores de ausencia del esquema de 1997
> - Title.Subtitle cierra el bucle de la F01, con su decisión escrita
> - dos ! en todo el curso, los dos comentados y declarados 💸 con cobro en F09
> - medición de advertencias del contexto anulable escrita, con su comando"
> ```
>
> Los commits llevan su prefijo (`fase 02: …`), los ejercicios el suyo (`fase 02 ej12: …`) y el
> miniproyecto el tag `mini-02` con sus números. La convención está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
>
> Esta fase **no cobra deuda y planta dos**, y las dos son del mismo sitio: el borde de datos. Es a
> propósito — cuando la fase 09 escriba el borde de verdad, `git diff fase-02 fase-09` va a mostrar
> las dos desapareciendo en la misma línea, y eso es el argumento de por qué un borde disperso es
> más caro que uno concentrado.

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura.*

- **`INSTINTOS.md`** — tres entradas en una familia nueva, *ausencia y nulabilidad*: `null` como
  estado válido del dominio, `Optional<T>` traducido mecánicamente, y el `!` que silencia. La
  tercera necesita el matiz de que **hay un `!` legítimo**, o el lector va a creer que están
  prohibidos y va a escribir peor código para evitarlos.
- **`BENCHMARKS.md`** — entrada ⏳ *F02 · Advertencias del contexto anulable, clasificadas*. Es la
  primera entrada del curso cuyo instrumento no es el arnés, y el archivo tiene que decirlo.
- **Deudas 💸 registradas:** dos `!` en el borde de datos, cobro en F09. Está en el libro de
  deudas de la propuesta §7.1 como una sola entrada; conviene que allí siga siendo una, porque se
  cobran juntas.
- **Decisión que sube a la propuesta:** `LegacyDate` y `LegacyDateKind` son tipos nuevos que no
  estaban en el congelamiento de nombres. Ya quedaron agregados a `congelamiento-de-nombres.md` §2;
  la fase 09 los tiene que usar y **no puede inventar otro tipo para lo mismo**.
- **Para la fase 09:** el ejercicio 24 pide escribir la política de nulos del borde. Si alguien lo
  hizo, la 09 debería partir de ahí en vez de rediscutirla.
- **Para la fase 11:** el umbral del ejercicio 17 es el argumento con el que la 11 decide no anotar
  las 250.000 líneas de SIGE. Si la medición no se ejecuta, esa decisión queda sin sustento y hay
  que decirlo allí.
- **Riesgo detectado:** el literal `"NULL"` del archivo exportado es un artefacto de **cómo se
  exportó**, no del esquema. Si la fase 07 genera sus exportaciones de otra manera, este
  miniproyecto queda con un caso que el resto del curso no reproduce. Revisar al escribir la 07.
