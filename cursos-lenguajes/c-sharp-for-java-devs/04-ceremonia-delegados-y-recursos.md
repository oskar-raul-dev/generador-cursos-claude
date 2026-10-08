# 🎩 Fase 04 — Ceremonia que sobra y ceremonia que falta

> C# para desarrolladores Java senior · Fase 04 de 24 · Bloque A — el lenguaje y el runtime
> Depende de: 03 · Habilita: 05
> Estilo de esta fase: **nuevo** (.NET 10, C# 14)
> Proyecto que avanza: **el modelo de dominio**. Al terminar, `Cordillera.Domain` tiene su política
> de errores decidida y sus recursos cerrados de forma garantizada, y la suite de pruebas del curso
> tiene su ciclo de vida fijado.

---

## 🎯 1. Propósito

Esta fase tiene dos mitades y **una sola tesis que las une**, y conviene dejarla escrita antes de
empezar porque si no se lee como dos fases pegadas:

> 🧭 **C# te pide menos ceremonia que Java en cómo se pasa el comportamiento, y más en cómo se
> cierra lo que se abre.** Menos: no hace falta una interfaz para pasar una función, ni una clase
> `Utils` para agrupar métodos, ni declarar las excepciones que un método lanza. Más: nadie te obliga
> a atrapar nada, así que decidir **qué** atrapas es tu trabajo y no del compilador; y nada te
> recuerda cerrar un recurso, así que `using` no es una comodidad, es la única defensa.

Lo que el lector se lleva es un criterio: dónde borrar ceremonia que traía de Java, y dónde poner
ceremonia que en Java no le hacía falta porque el compilador se la exigía.

---

## ✅ 2. Qué queda listo al terminar

- [ ] El modelo no tiene ni una interfaz de un solo método creada "por si acaso", y donde había una
      ahora hay un delegado — o hay una interfaz **con su razón escrita**.
- [ ] `Cordillera.Domain` tiene su **política de errores decidida por escrito**: qué es excepción,
      qué es resultado, y el número que sostiene la decisión.
- [ ] Los lectores de archivos del modelo implementan `IDisposable` correctamente, y hay una prueba
      que demuestra que **cierran incluso cuando el recorrido se interrumpe a mitad**.
- [ ] 💸 **Se cobra la deuda de esta fase dentro de esta fase:** el `finally` escrito a mano queda
      reescrito a `using`, y el `git diff` es la factura.
- [ ] La suite tiene su ciclo de vida fijado: instancia nueva por prueba, `IClassFixture` donde el
      montaje es caro, y `[Theory]`/`[InlineData]` donde hay casos.
- [ ] No hay ni un `catch (Exception)` sin comentario que explique qué se está tragando y por qué.
- [ ] La medición de la sección 6 está escrita con su comando, y la entrada quedó en `BENCHMARKS.md`.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **`async`/`await`** → fase 05. Aquí aparece `IAsyncDisposable` porque el miniproyecto se estrella
  con él, pero **no se explica la asincronía**: se explica que existe y que el `using` sincrónico no
  es su amigo.
- **Inyección de dependencias y tiempos de vida** → fase 15. En esta fase los delegados se pasan a
  mano, que es además la mejor forma de entender qué hace un contenedor cuando llegue.
- **Genéricos avanzados.** Entra lo que cambia para escribir código —`typeof(T)` en tiempo de
  ejecución, restricciones, `where T : struct`, y la covarianza donde el curso la usa— y queda fuera
  la varianza en firmas propias, los tipos genéricos anidados y los números genéricos
  (`INumber<T>`), que se enlazan.
- **`IAsyncEnumerable`** → fase 06.
- **Excepciones del borde de una API** —qué código HTTP, qué cuerpo— → fase 15.

---

## 🧠 4. Concepto mínimo

### Primera mitad: la ceremonia que sobra

**Un delegado es un tipo que representa una función.** No es una interfaz con un método, no es una
clase anónima: es un tipo del sistema de tipos cuyas instancias son funciones invocables. Y como
existen desde C# 1, toda la biblioteca está construida sobre ellos:

```csharp
// Los tres nombres que hay que saber y ni uno más.
Func<Edition, bool>        predicate;   // recibe y devuelve
Action<Edition>            handler;     // recibe y no devuelve
Func<Money>                factory;     // no recibe y devuelve
```

En Java, pasar comportamiento requiere un tipo nominal: `Predicate<T>`, `Consumer<T>`,
`Function<T,R>` o la interfaz funcional que te escribas. Aquí `Func` y `Action` son genéricos con
sobrecargas hasta dieciséis parámetros, y **cualquier lambda con la forma correcta encaja sin
declarar nada**.

**Un método de extensión es un método estático que se invoca como si fuera de instancia.** Es lo que
hace que `editions.Where(...)` funcione cuando `Where` no está en `IEnumerable<T>`. Y es lo que
reemplaza a la clase `Utils`:

```csharp
// El mecanismo completo: `this` en el primer parámetro de un método estático.
public static class MoneyExtensions
{
    /// <summary>La regalía de un importe, al porcentaje del contrato.</summary>
    public static Money RoyaltyAt(this Money amount, decimal percentage) =>
        new(Math.Round(amount.Amount * percentage / 100m, 2, MidpointRounding.ToEven));
}

// Y se usa como si el método fuera del tipo:
Money royalty = sales.RoyaltyAt(12.5m);
```

**Y las excepciones no se declaran.** No hay `checked exceptions`, no hay `throws` en la firma, y no
hay nada que te obligue a atrapar ni a propagar. Eso elimina de golpe el ruido que llevas once años
escribiendo —`try { … } catch (IOException e) { throw new RuntimeException(e); }`— y a cambio te
quita la red: **el compilador ya no te dice qué puede fallar**. La documentación XML y el nombre del
método pasan a ser la única señal.

### Segunda mitad: la ceremonia que falta

Aquí el lenguaje pide más que Java, y son dos cosas.

**Cerrar lo que se abre es tuyo, y nada te lo recuerda.** El recolector libera memoria, no
recursos: un `FileStream` abierto tiene un manejador del sistema operativo, una `SqlConnection`
tiene una conexión en el pool, y el recolector no sabe ni cuándo ni si va a pasar por ahí. El patrón
es `IDisposable` + `using`, y el paralelo con `try-with-resources` es casi exacto.

```csharp
// using como declaración: libera al salir del ámbito. No hay llaves extra y no hay finally.
using var reader = new StreamReader(path);
foreach (string line in ReadLines(reader))
{
    // …
}
// Aquí ya se llamó a reader.Dispose(), incluso si lo de arriba lanzó.
```

**Y decidir qué se atrapa también es tuyo.** Sin excepciones declaradas, `catch (Exception)` es la
tentación permanente: atrapa todo, el programa no se cae, y el error que importaba desaparece. El
criterio del curso es el que ya usas en Java, solo que ahora sin ayuda del compilador: **se atrapa
lo que se sabe manejar**, y se deja pasar lo demás.

> 🧠 **El modelo mental que ordena la fase:** Java pone la ceremonia **en la firma** —las
> excepciones declaradas, la interfaz funcional nominal— y C# la pone **en el cuerpo** —el `using`,
> el `catch` específico—. Ninguno de los dos te la ahorra: cambian de sitio, y con ella cambia quién
> te avisa cuando falta. En Java te avisa el compilador; aquí te avisa el incidente.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**Primera: la interfaz de un solo método, con su implementación anónima.**

```csharp
// ❌ La traducción directa. Dos tipos, un archivo más, y una indirección para pasar una función.
public interface IEditionFilter
{
    bool Matches(Edition edition);
}

public sealed class ImprintFilter : IEditionFilter
{
    private readonly ImprintCode _imprint;
    public ImprintFilter(ImprintCode imprint) => _imprint = imprint;
    public bool Matches(Edition edition) => edition.Imprint == _imprint;
}

// Y su uso:
var results = catalog.Filter(new ImprintFilter(ImprintCode.Com));
```

```csharp
// ✅ Lo mismo. El tipo de la función ya existe y se llama Func<Edition, bool>.
var results = catalog.Where(e => e.Imprint == ImprintCode.Com);
```

**Por qué falla el reflejo:** no por verboso. Por **inventar un concepto de dominio que no existe**.
`IEditionFilter` no es una idea del negocio de Cordillera: es un envoltorio para poder pasar una
función en un lenguaje que no lo permitía. Nombrar cosas que no son ideas hace que la próxima
persona busque significado donde no hay.

**Cuándo la interfaz sí va**, porque hay tres casos legítimos y el curso los usa: cuando hay **más
de una implementación real** que conviven; cuando hay que **sustituirla en una prueba** y el doble
necesita estado; y cuando la abstracción tiene **más de un método** que van juntos. Fuera de eso, un
delegado.

**Segunda: la clase estática `Utils`.**

```csharp
// ❌ El basurero con nombre de virtud. Crece, nadie lo borra, y a los dos años tiene 40 métodos
//    que no tienen nada que ver entre sí.
public static class IsbnUtils
{
    public static string Format(string isbn) { … }
    public static bool IsValid(string isbn) { … }
    public static string StripHyphens(string isbn) { … }
}

string formatted = IsbnUtils.Format(raw);
```

```csharp
// ✅ El comportamiento va donde vive el dato: en el tipo, si es del tipo; en una extensión, si
//    extiende algo ajeno. `Isbn` ya sabe formatearse y validarse (fase 01).
string formatted = isbn.ToString();
```

**Dónde se rompe el paralelo:** en Java la clase de utilidades es la única opción cuando el tipo no
es tuyo — no puedes agregarle un método a `String`. En C# **sí puedes**, con un método de extensión,
y ahí desaparece el 80% de las razones para tener un `Utils`.

**Tercera, y esta es la que cuesta plata: `catch (Exception)`.**

```csharp
// ❌ Escrito con la mejor intención: "que no se caiga el proceso nocturno".
foreach (string line in File.ReadLines(path))
{
    try
    {
        ProcessSalesLine(line);
    }
    catch (Exception ex)
    {
        _log.Warning($"Línea con problema: {ex.Message}");
    }
}
```

Ese bloque se traga, con la misma cara, tres cosas completamente distintas: una línea con un ISBN
mal formado —que es un dato sucio y hay que reportarlo—, un disco lleno —que es un fallo del sistema
y hay que abortar— y un `NullReferenceException` en tu propio código —que es un bug y hay que
arreglarlo—. Las tres quedan como una advertencia en un log que nadie lee, y el proceso termina
"correctamente" con la mitad de las ventas sin cargar.

```csharp
// ✅ Se atrapa lo que se sabe manejar, y se deja pasar lo demás. La política es explícita y
//    cabe en el switch.
foreach (string line in File.ReadLines(path))
{
    try
    {
        ProcessSalesLine(line);
    }
    catch (SalesLineFormatException ex)
    {
        // Dato sucio: es esperado, se cuenta y se sigue. Es la mitad del Bloque B.
        rejected.Add((ex.LineNumber, ex.Message));
    }
    // IOException, OutOfMemoryException y cualquier bug propio suben. Si el disco se llenó,
    // seguir procesando 400.000 líneas para fallar al final es la peor opción posible.
}
```

**Por qué falla el reflejo:** porque en Java el compilador te obligaba a **nombrar** lo que podía
fallar, y ese trámite te hacía pensar. Sin él, `catch (Exception)` es lo que sale solo — y el
programa que nunca se cae es indistinguible del programa que nunca funciona.

**Cuarta: el `@BeforeEach` sobre una instancia compartida.**

```csharp
// ❌ La traducción mecánica del hábito de JUnit: un campo, un método de montaje, y la suposición
//    de que se limpia entre pruebas.
public class CatalogTests
{
    private List<Edition> _catalog = [];

    private void SetUp()          // lo que en JUnit sería @BeforeEach
    {
        _catalog.Add(SomeEdition());
    }
}
```

```csharp
// ✅ En xUnit el montaje va en el CONSTRUCTOR, porque se construye una instancia nueva de la
//    clase por cada prueba. No hace falta limpiar: no hay nada que sobreviva.
public class CatalogTests
{
    private readonly List<Edition> _catalog;

    public CatalogTests() => _catalog = [SomeEdition(), AnotherEdition()];

    // Y si hay algo que limpiar —un archivo temporal, un contenedor—, la clase implementa
    // IDisposable y el desmontaje va en Dispose().
}
```

**Dónde se rompe el paralelo, y es la fila más valiosa del 📖 de esta fase:** JUnit crea una
instancia por prueba **desde JUnit 5** y antes también lo hacía, pero el hábito de `@BeforeEach` con
campos mutables convive con `@BeforeAll` estático y con el `@TestInstance(PER_CLASS)` que lo cambia
todo. En xUnit **no hay configuración que cambie eso**: una instancia por prueba, siempre. Lo que en
JUnit sería `@BeforeAll` aquí es un tipo aparte compartido explícitamente con `IClassFixture<T>`, y
esa explicitud es el punto: **si dos pruebas comparten estado, se ve en la firma de la clase.**

### 🩻 Esto sí funciona igual

`try-with-resources` es `using`, y el paralelo es casi exacto: el mismo propósito, la misma
garantía, el mismo comportamiento ante excepciones. `AutoCloseable` es `IDisposable` y `close()` es
`Dispose()`. Si ya tienes el hábito de abrir recursos dentro del bloque que los usa, se transfiere
entero.

También se transfiere el razonamiento sobre excepciones: cuándo envolver, cuándo dejar subir, cuándo
agregar contexto, por qué una excepción de dominio propia se lee mejor que una genérica con un
mensaje largo. Todo eso vale igual. **La diferencia es que aquí nadie te obliga a declarar nada**, y
por eso se dice explícito: la disciplina que en Java sostenía el compilador aquí la sostienes tú.

Y toda tu experiencia de pruebas se transfiere: qué es una prueba unitaria, qué vale la pena
probar, cómo se diseña para poder probar, cuándo un doble es la herramienta y cuándo es una trampa.
El curso no va a explicar nada de eso. Lo que cambia son los nombres y una decisión de diseño del
framework — la instancia por prueba.

### 📖 Diccionario de traducción

**Delegados, extensiones y genéricos**

| Java | C# / .NET | Dónde se rompe el paralelo |
|---|---|---|
| `Predicate<T>` / `Consumer<T>` / `Function<T,R>` | `Func<T,bool>` / `Action<T>` / `Func<T,R>` | Son tipos genéricos de la biblioteca, no interfaces que cada quien redeclara. Cualquier lambda con la forma encaja |
| interfaz funcional propia con `@FunctionalInterface` | `delegate` propio | Se declara cuando el **nombre** aporta: `delegate bool RoyaltyRule(Contract c, Money sales)` se lee mejor que el `Func` de tres parámetros |
| clase `StringUtils` | método de extensión | Puedes extender tipos que no son tuyos, incluidos los de la biblioteca. Ahí muere el `Utils` |
| `Observer` / listeners | `event` + `delegate` | Hay sintaxis del lenguaje (`+=`, `-=`), y un `event` **no se puede invocar desde fuera** del tipo que lo declara |
| `throws IOException` | **nada** | No existen las excepciones declaradas. La documentación XML es la única señal, y no la comprueba nadie |
| borrado de tipos: `List<String>` es `List` | genéricos **reificados** | `typeof(T)` funciona en tiempo de ejecución, `new T[10]` funciona, y `List<int>` **no hace boxing** |
| `List<Object> l = (List) stringList` | no compila, y no hay forma | Sin borrado no hay hueco por donde colarlo. Se gana seguridad y se pierde un truco sucio que a veces servía |
| `? extends T` en un parámetro | `IEnumerable<out T>` (covarianza declarada en el tipo) | La varianza se declara **una vez, en la interfaz**, no en cada uso. Menos ruido, menos flexibilidad |
| `<T extends Comparable<T>>` | `where T : IComparable<T>` | Más restricciones disponibles: `struct`, `class`, `notnull`, `new()`, `unmanaged` |
| `AutoCloseable` / `close()` | `IDisposable` / `Dispose()` | Casi exacto |
| `try (var r = …)` | `using var r = …;` | No hace falta un bloque nuevo: libera al salir del ámbito actual |
| `finalize()` | finalizador `~Type()` | Existe y **casi nunca es la respuesta**: no hay garantía de cuándo corre, ni de que corra |

**JUnit ⇄ xUnit**

| JUnit 5 | xUnit v3 | Dónde se rompe el paralelo |
|---|---|---|
| `@Test` | `[Fact]` | "Un hecho": una prueba sin parámetros |
| `@ParameterizedTest` + `@ValueSource` | `[Theory]` + `[InlineData]` | "Una teoría": cierta para todos estos datos. Los casos van en atributos, comprobados en compilación |
| `@BeforeEach` | **el constructor** | **La fila que importa:** xUnit construye una instancia nueva de la clase por prueba, siempre, sin configuración que lo cambie |
| `@AfterEach` | `IDisposable.Dispose()` | El desmontaje es el mismo mecanismo del lenguaje, no un atributo |
| `@BeforeAll` / `@AfterAll` estático | `IClassFixture<T>` | El estado compartido es **un tipo aparte inyectado por constructor**: si dos pruebas comparten algo, se ve en la firma |
| compartir entre clases | `ICollectionFixture<T>` + `[Collection]` | Es lo que va a sostener el contenedor de SQL Server en la fase 08 |
| `assertThrows(E.class, …)` | `Assert.Throws<E>(…)` | Devuelve la excepción para poder inspeccionarla, igual |
| `@Disabled("razón")` | `[Fact(Skip = "razón")]` | La razón es obligatoria en la práctica: aparece en la salida |
| `@DisplayName` | el nombre del método | Por eso los nombres de prueba de este curso son frases en español |
| Mockito | **NSubstitute** | `Substitute.For<T>()`. Sin `@Mock`, sin `openMocks`: es una llamada |
| `@Execution(CONCURRENT)` | paralelo **por defecto entre clases** | xUnit paraleliza clases distintas sin pedirlo. Es la causa del primer fallo intermitente de todo el que llega |

> ⚠️ **La última fila es la que muerde en la primera semana.** xUnit ejecuta **en paralelo las
> pruebas de clases distintas** por omisión. Si dos clases de prueba escriben el mismo archivo
> temporal o tocan la misma base, el fallo es intermitente y parece un misterio. La solución no es
> apagar el paralelismo: es dejar de compartir estado, y cuando compartirlo es inevitable —el
> contenedor de la fase 08—, declararlo con `[Collection]`.

> 📝 **Nota de ecosistema.** Los delegados son de C# 1 (2002), los genéricos de C# 2 (2005), las
> lambdas y los métodos de extensión de C# 3 (2007) — **traídos por LINQ**, como vimos en la fase
> 03—, `IAsyncDisposable` y `await using` de C# 8 (2019). Eso explica la forma del código que vas a
> encontrar: en `Sige.DataAccess`, que es de 2017 escrito como C# 2, **no hay ni una lambda ni un
> método de extensión**, aunque el lenguaje ya los tenía diez años. No es que no pudieran: es que
> quien lo escribió aprendió C# de un libro anterior y nadie le mostró otra cosa. Es el ejemplo más
> claro del curso de que la versión del lenguaje y el estilo del código son dos cosas distintas.

---

## 💻 5. Código mínimo con comentarios

### 5.1 La deuda de esta fase, escrita como la escribiría el primer día

Esta es la parte donde el curso hace algo que no repite: **escribe mal a propósito y lo arregla en
la misma sección**, para que el mecanismo de las deudas 💸 quede claro con un ejemplo corto antes de
que las siguientes se cobren quince fases después.

```csharp
// src/modern/Cordillera.Domain/Import/SalesFileReader.cs — PRIMERA VERSIÓN
//
// 💸 Deuda, y se paga en esta misma fase, doce párrafos más abajo. Esto es exactamente lo que
// escribe el primer día alguien con once años de Java: un try/finally a mano, con la comprobación
// de null antes de cerrar, porque es lo que hacía antes de que existiera try-with-resources.
public static IReadOnlyList<SalesRow> Read(string path)
{
    List<SalesRow> rows = [];
    StreamReader? reader = null;

    try
    {
        reader = new StreamReader(path);
        string? line;

        while ((line = reader.ReadLine()) is not null)
        {
            rows.Add(SalesRow.Parse(line));
        }
    }
    finally
    {
        // Y aquí está el problema que no se ve: si Parse lanza, esto cierra el lector — bien — pero
        // la excepción sube sin decir en qué línea, porque el número de línea se quedó dentro del
        // bucle. Además, si alguien agrega un segundo recurso, hay que anidar otro try/finally.
        if (reader is not null)
        {
            reader.Dispose();
        }
    }

    return rows;
}
```

**Qué tiene de malo, y no es el estilo:** son tres cosas concretas. El `finally` con comprobación de
nulo es ruido que el lenguaje ya resuelve. Materializa toda la lista, que es lo que la fase 03 acabó
de enseñar a no hacer por defecto. Y **no tiene política de errores**: una línea sucia tumba el
archivo completo.

Ahora la versión cobrada:

```csharp
// src/modern/Cordillera.Domain/Import/SalesFileReader.cs — VERSIÓN COBRADA
//
// 💸 Deuda pagada en la fase 04. La factura:
//    git diff fase-03 fase-04 -- src/modern/Cordillera.Domain/Import/SalesFileReader.cs
namespace Cordillera.Domain.Import;

/// <summary>
/// Lee un archivo de ventas de un distribuidor. Perezoso, con política de errores explícita y con
/// cierre garantizado — incluso si quien lo consume abandona el recorrido a mitad.
/// </summary>
public sealed class SalesFileReader : IDisposable
{
    private readonly StreamReader _reader;
    private readonly Action<SalesLineError> _onBadLine;
    private bool _disposed;

    /// <param name="onBadLine">
    /// Qué hacer con una línea que no se puede interpretar. Es un delegado y no una interfaz porque
    /// es **una** función: quien llama decide si cuenta, registra o acumula, y no hace falta
    /// inventar un `ISalesLineErrorHandler` para eso.
    /// </param>
    public SalesFileReader(string path, Action<SalesLineError> onBadLine)
    {
        ArgumentNullException.ThrowIfNull(onBadLine);

        // Si el archivo no existe o no se puede abrir, la excepción sube tal cual. No es un dato
        // sucio: es que el encargo no se puede empezar, y ocultarlo aquí sería el `catch (Exception)`
        // de la sección 4 con otro disfraz.
        _reader = new StreamReader(path);
        _onBadLine = onBadLine;
    }

    /// <summary>
    /// Las filas del archivo, de a una. Es perezoso: no lee nada hasta que alguien enumere, y no
    /// materializa nada (fase 03).
    /// </summary>
    public IEnumerable<SalesRow> Rows()
    {
        ObjectDisposedException.ThrowIf(_disposed, this);

        int lineNumber = 0;
        string? line;

        while ((line = _reader.ReadLine()) is not null)
        {
            lineNumber++;

            // La política de errores, en un solo sitio y por tipo de fallo. Lo que es dato sucio se
            // reporta y se sigue; lo que es fallo del sistema sube.
            if (!SalesRow.TryParse(line, lineNumber, out SalesRow row, out string? reason))
            {
                _onBadLine(new SalesLineError(lineNumber, line, reason));
                continue;
            }

            yield return row;
        }
    }

    public void Dispose()
    {
        if (_disposed)
        {
            return;
        }

        _reader.Dispose();
        _disposed = true;
    }
}

/// <summary>Una línea que no se pudo interpretar, con lo necesario para investigarla.</summary>
public sealed record SalesLineError(int LineNumber, string RawLine, string Reason);
```

```csharp
// Y así se usa. El `using` garantiza el cierre incluso si el consumidor abandona a mitad —un
// `break`, una excepción, un `return` dentro del foreach— que es justo lo que el try/finally a
// mano hacía frágil.
int rejected = 0;
using var reader = new SalesFileReader(path, error =>
{
    rejected++;
    Console.Error.WriteLine($"línea {error.LineNumber}: {error.Reason}");
});

foreach (SalesRow row in reader.Rows())
{
    if (row.Quantity == 0)
    {
        break;   // se abandona el recorrido, y el archivo se cierra igual
    }

    Accumulate(row);
}
```

**Detalles con intención**

- **`onBadLine` es un `Action<T>` y no una interfaz.** Es el ejemplo canónico de la primera mitad de
  la tesis: una función, un delegado. Si mañana hicieran falta tres operaciones relacionadas
  —empezar, fallar, terminar—, entonces sí sería una interfaz, y el criterio queda escrito.
- **`ObjectDisposedException.ThrowIf`** en vez de la comprobación a mano: existe desde .NET 7 y dice
  exactamente lo que pasa.
- **`Dispose` es idempotente** y no hay finalizador. No hace falta: esta clase no posee un recurso
  no administrado directamente, solo otro `IDisposable`. El finalizador es para quien envuelve un
  `IntPtr`, y en veinticuatro fases este curso no va a escribir ninguno.

**El patrón a memorizar**

> **Un delegado para una función; una interfaz para un rol.** Si lo que pasas responde una sola
> pregunta, es un `Func` o un `Action`. Si lo que pasas es una pieza con varias responsabilidades
> que van juntas, o que alguien va a sustituir en una prueba con estado, es una interfaz. Y el
> nombre lo delata: si tuviste que llamarla `IEditionFilter`, era una función.

### 5.2 La política de errores del dominio, decidida

```csharp
// src/modern/Cordillera.Domain/DomainException.cs
namespace Cordillera.Domain;

/// <summary>
/// Base de las excepciones del dominio. La jerarquía es mínima a propósito: dos niveles, no siete.
/// </summary>
public abstract class DomainException(string message, Exception? inner = null)
    : Exception(message, inner);

/// <summary>
/// Una regla del negocio que se violó. Es un error del que llama, no un fallo del sistema.
/// </summary>
public sealed class BusinessRuleException(string message) : DomainException(message);

/// <summary>
/// Un dato del sistema heredado que no se puede interpretar. Lleva dónde estaba, porque sin eso
/// el mensaje no sirve para nada.
/// </summary>
public sealed class LegacyDataException(string message, string source, int? lineNumber = null)
    : DomainException(message)
{
    public string Source { get; } = source;

    public int? LineNumber { get; } = lineNumber;
}
```

Y la regla que decide cuál de las dos formas se usa, escrita para que no se vuelva a discutir en
veinte fases:

> 🧭 **Excepción cuando el fallo es excepcional; resultado cuando el fallo es parte del trabajo.**
>
> Construir un `Isbn` desde el ISBN que un editor tecleó en un formulario: si está mal, es
> excepcional → `Isbn.Parse` lanza. Construir un `Isbn` desde una de 40.000 líneas de un archivo del
> distribuidor, donde un 5% viene sucio: el fallo **es el trabajo** → `Isbn.TryParse` devuelve
> `bool`. El mismo tipo ofrece las dos, y quien llama elige según su situación — que es exactamente
> lo que hace todo el framework con `Parse`/`TryParse`, y el número de la sección 6 explica por qué.

### 5.3 `IAsyncDisposable`, lo justo para no estrellarse

```csharp
// Un tipo puede implementar las DOS interfaces, y entonces hay dos formas de cerrarlo que NO
// hacen lo mismo. Es la trampa del miniproyecto, y aquí está el mecanismo.
public sealed class AuditTrailWriter : IDisposable, IAsyncDisposable
{
    private readonly StreamWriter _writer;

    /// <summary>
    /// Cierre sincrónico. Suelta el manejador del archivo, y **no** vacía el búfer pendiente:
    /// hacerlo aquí obligaría a bloquear el hilo, que es justo lo que la fase 05 enseña a no hacer.
    /// </summary>
    public void Dispose() => _writer.Dispose();

    /// <summary>
    /// Cierre asincrónico. Vacía el búfer y después suelta el manejador. **Es el correcto** para
    /// este tipo, y el único que garantiza que lo último escrito llegó al disco.
    /// </summary>
    public ValueTask DisposeAsync() => _writer.DisposeAsync();
}
```

```csharp
// ❌ Compila. No avisa. Y pierde el último bloque escrito.
using var audit = new AuditTrailWriter(path);

// ✅ Lo correcto para este tipo, y la razón por la que la fase 05 existe.
await using var audit = new AuditTrailWriter(path);
```

**Prueba de fuego**

```csharp
// Escribe 10.000 líneas de auditoría con cada una de las dos formas de cierre y cuenta las líneas
// del archivo resultante. Los dos programas terminan sin error.
//
//   con `using`        → menos de 10.000 líneas
//   con `await using`  → 10.000
```

Y la mentira que te va a contar la salida si miras el lugar equivocado: **con pocos datos las dos
dan lo mismo**, porque el búfer nunca se llenó lo suficiente para que la diferencia se note. Si
pruebas con cien líneas, los dos escriben cien y concluyes que da igual. Es el mismo mecanismo por
el que este bug llega a producción: en desarrollo el archivo es chico.

### 5.4 El ciclo de vida de las pruebas del curso

```csharp
// src/modern/Cordillera.Domain.Tests/SalesFileReaderTests.cs
using Cordillera.Domain.Import;

namespace Cordillera.Domain.Tests;

/// <summary>
/// El montaje va en el constructor y el desmontaje en Dispose, porque xUnit construye **una
/// instancia nueva de esta clase por cada prueba**. No hay estado que sobreviva, así que no hay
/// nada que limpiar entre pruebas — y por eso no existe `@BeforeEach` aquí.
/// </summary>
public class SalesFileReaderTests : IDisposable
{
    private readonly string _path = Path.Combine(Path.GetTempPath(), $"ventas-{Guid.NewGuid():N}.csv");

    public SalesFileReaderTests() =>
        File.WriteAllLines(_path,
        [
            "20260112;ED00001234;12;68000.00;COP;I",
            "esto no es una línea de ventas",
            "20260115;ED00001235;300;95000.00;MXN;I",
        ]);

    // El nombre del archivo lleva un GUID porque xUnit ejecuta **en paralelo las clases distintas**:
    // un nombre fijo haría que dos clases de prueba se pisaran, y el fallo sería intermitente.
    public void Dispose() => File.Delete(_path);

    [Fact]
    public void Las_lineas_validas_se_leen_y_las_sucias_se_reportan()
    {
        List<SalesLineError> errors = [];
        using var reader = new SalesFileReader(_path, errors.Add);

        List<SalesRow> rows = [.. reader.Rows()];

        Assert.Equal(2, rows.Count);
        Assert.Single(errors);
        Assert.Equal(2, errors[0].LineNumber);
    }

    [Fact]
    public void El_archivo_se_cierra_aunque_se_abandone_el_recorrido()
    {
        List<SalesLineError> errors = [];

        using (var reader = new SalesFileReader(_path, errors.Add))
        {
            foreach (SalesRow row in reader.Rows())
            {
                break;   // se abandona en la primera fila
            }
        }

        // Si el lector no hubiera cerrado, esto lanzaría IOException en Windows: el archivo
        // seguiría bloqueado. Es la prueba que el try/finally a mano pasaba por casualidad y que
        // se rompía en cuanto alguien agregaba un segundo recurso.
        File.Delete(_path);
        File.WriteAllText(_path, "reescrito");
    }

    [Theory]
    [InlineData("20260112;ED00001234;12;68000.00;COP;I", true)]
    [InlineData("20260112;ED00001234;12;68000.00;COP", false)]      // falta una columna
    [InlineData("20260112;ED00001234;doce;68000.00;COP;I", false)]  // cantidad no numérica
    [InlineData("", false)]
    public void TryParse_distingue_una_fila_de_una_linea_cualquiera(string line, bool expected)
    {
        // [Theory] con [InlineData] es el @ParameterizedTest que ya usas, con una diferencia: los
        // casos se comprueban en compilación, así que un tipo equivocado no llega a ejecutarse.
        bool parsed = SalesRow.TryParse(line, lineNumber: 1, out _, out _);

        Assert.Equal(expected, parsed);
    }
}
```

**Detalles con intención**

- **La segunda prueba no comprueba un valor: comprueba una garantía.** Es la clase de prueba que
  vale la pena escribir sobre `IDisposable`, y la que habría atrapado el problema del `finally` a
  mano el día que alguien agregara un segundo recurso.
- **El nombre del archivo temporal lleva un GUID.** No es paranoia: es la consecuencia directa del
  paralelismo por omisión de xUnit, y el primer fallo intermitente que sufre todo el que llega.
- **`IClassFixture<T>` no aparece aquí porque no hace falta.** Aparece en la fase 08, cuando el
  montaje sea un contenedor de SQL Server y construirlo por prueba sea inviable. Introducirlo ahora,
  con un montaje que cuesta microsegundos, enseñaría a compartir estado sin razón.

---

## 📏 6. Medición

**Hipótesis:** lanzar una excepción cuesta órdenes de magnitud más que devolver un resultado, y por
eso usar excepciones para un fallo que **es parte del trabajo** —el 5% de líneas sucias de un
archivo de 40.000— es una decisión medible y no una preferencia de estilo.

**Condiciones:** SDK 10.0.401 · Release · Windows 11 · **un millón de invocaciones** de la misma
operación, variando la proporción de fallos: 0%, 5% y 100% · 100 repeticiones con 10 de
calentamiento descartadas · **BenchmarkDotNet**, porque esto es un microbenchmark de libro y hacerlo
a mano es equivocarse (`formato-de-mediciones.md` §1).

**Competidores:** tres formas de informar un fallo, las tres correctas y las tres defendibles:

- **Excepción** — `Isbn.Parse`, que lanza `ArgumentException`. Es lo que el framework hace, y es lo
  correcto para el formulario del editor.
- **Patrón `TryParse`** — `bool` + `out`, que es lo que hace todo el framework para el mismo trabajo
  cuando el fallo es esperado.
- **Tipo de resultado** — un `record` con el valor o el motivo. Es lo que escribe quien viene de un
  lenguaje funcional, y hay que medirlo antes de opinar de él.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 04 --benchmarkdotnet
```

**Resultado:** ⏳ pendiente de ejecución en tu máquina.

| Forma | 0% de fallos | 5% de fallos | 100% de fallos | Asignado (5%) |
|---|---|---|---|---|
| Excepción | ⏳ | ⏳ | ⏳ | ⏳ |
| `TryParse` (`bool` + `out`) | ⏳ | ⏳ | ⏳ | ⏳ |
| Tipo de resultado | ⏳ | ⏳ | ⏳ | ⏳ |

> ⚖️ **Veredicto** *(expectativa, todavía sin ejecutar — `formato-de-mediciones.md` §2.6)*. Se
> espera que con 0% de fallos las tres formas queden dentro del ruido —**empate**, y hay que
> publicarlo así— y que la columna del 5% ya separe a la excepción de las otras dos por un factor
> grande, porque una excepción captura la pila de llamadas y eso es lo caro, no el `throw`.
>
> **El umbral que tu ejecución tiene que determinar, y es el que se lleva el lector:** **a partir de
> qué proporción de fallos la excepción deja de ser aceptable**. Por debajo de ese porcentaje,
> escribir un tipo de resultado es complejidad sin retorno y la excepción es la opción legible; por
> encima, la excepción es un costo que se paga en cada archivo que se carga.
>
> Y una advertencia sobre cómo leer la tabla: **el 100% no es un caso realista**, está para que se
> vea la pendiente. Ninguna decisión del curso se toma con esa columna.

---

## 🧱 7. Miniproyecto — el lector de los tres distribuidores, que cierra aunque lo interrumpan

**El encargo**

Wilson te escribe: *"Los tres archivos de los distribuidores los baja un proceso a las once de la
noche y los carga una cosa que hizo Duván hace años. Cuando uno de los tres viene mal, el proceso se
queda a medias y a la mañana siguiente hay que mirar a mano qué entró y qué no — y dos veces nos
quedó un archivo bloqueado y la carga del día siguiente no pudo ni empezar. Necesito que si uno
falla, los otros dos entren, y que quede escrito qué pasó con cada uno. Y necesito poder pararlo:
la vez que se llenó el disco estuvo diez minutos escribiendo errores."*

**Por qué duele**

Porque son tres fuentes con tres formatos, cada una con su calendario, y el encargo tiene cuatro
requisitos que tiran en direcciones distintas: **aislamiento** (que uno malo no tumbe a los otros),
**política de errores por tipo de fallo** (no todo lo que falla se trata igual), **cierre
garantizado** (incluso si se interrumpe), y **auditoría** de lo que pasó con cada archivo. Y porque
el recurso de auditoría es el que trae la trampa.

**Datos de entrada**

Tres archivos, uno por distribuidor, con los códigos congelados del esquema. Los tres traen lo
mismo y ninguno lo trae igual.

**`DISMEX`** — semanas ISO, separador `;`, cantidades con signo, encabezado.

```text
SEMANA;CODEDIT;CANTIDAD;VLRUNIT;MONEDA;TIPOVENTA
2026-W03;ED00001235;300;95000.00;MXN;I
2026-W03;ED00001236;-45;42000.00;MXN;D
2026-W04;ED00001240;150;68000.00;MXN;O
```

**`DISCOL`** — mes natural, ancho fijo, sin encabezado. Las posiciones son 8-10-6-12-3-1.

```text
20260112ED00001234000012000068000.00COPI
20260118ED00001237000003000055000.00COPO
20260131ED00009999000005000038000.00COPI
```

**`DISARG`** — quincenal, separador tabulador, y **los importes con coma decimal**, porque así los
manda Buenos Aires desde 1998.

```text
2026-01-Q1	ED00001241	9	110000,00	ARS	I
2026-01-Q2	ED00001234	4	68000,00	ARS	I
2026-01-Q2	ED00001238	-2	38000,00	ARS	D
```

Y los fallos que hay que provocar para probar de verdad, uno de cada clase:

- **Dato sucio** — una línea de `DISCOL` con dos caracteres de menos, que descuadra el ancho fijo.
- **Archivo inaccesible** — `DISARG` bloqueado por otro proceso, o inexistente.
- **Fallo del sistema** — el disco de la auditoría sin espacio. Simúlalo escribiendo en una ruta
  inválida.
- **Interrupción** — una señal de cancelación a mitad del archivo más grande.

**Criterios de aceptación**

1. Un programa que carga los tres archivos y **termina con un resumen por distribuidor**: filas
   aceptadas, filas rechazadas con su motivo, y si el archivo se procesó completo, a medias o no se
   pudo abrir. Un archivo que falla **no impide** que los otros dos se procesen.
2. La política de errores está **en un solo sitio y es explícita por tipo de fallo**: dato sucio se
   cuenta y se sigue; archivo inaccesible se reporta y se pasa al siguiente; fallo del sistema
   aborta todo. Un `catch (Exception)` en el código es un criterio no cumplido.
3. Si se cancela a mitad, **todos los recursos quedan cerrados** y el resumen dice exactamente en
   qué fila de qué archivo se detuvo. Una prueba lo demuestra abriendo el archivo para escritura
   después de la cancelación.
4. El archivo de auditoría contiene **todas** las líneas que el programa dijo haber escrito. Este
   criterio parece trivial y es el de la trampa.
5. Ninguna interfaz de un solo método. Si escribes una, el comentario explica cuál de los tres
   casos legítimos de la sección 4 aplica.
6. **Medición de cierre:** filas por segundo sobre los tres archivos completos —unas 120.000 filas
   entre los tres— y el porcentaje de rechazos, medidos con el arnés. Van en el mensaje del tag
   `mini-04`.

**Restricciones de estilo y alcance**

Código nuevo. **Sin `async`** —es la fase 05— así que la cancelación se comprueba de forma
sincrónica, con `token.ThrowIfCancellationRequested()` dentro del bucle. Sin paquetes: los tres
formatos se parsean con lo que trae el SDK.

Y una restricción que es el punto de la fase: **los tres lectores comparten el 80% de la lógica y
difieren en el 20%**. Esa diferencia se resuelve con delegados o con una jerarquía, y la decisión es
tuya — pero si terminas con `IDistributorFileParser`, `DismexParser`, `DiscolParser` y
`DisargParser` de un método cada uno, ese es exactamente el reflejo que la fase está atacando.

**La trampa**

El escritor de auditoría que vas a usar implementa `IDisposable` **y** `IAsyncDisposable`. Vas a
escribir `using var audit = new AuditTrailWriter(path);` porque es lo que la fase acaba de enseñar,
el compilador no va a decir nada, y el programa va a terminar limpio.

Y el criterio 4 va a fallar. Con los tres archivos completos, no con el fragmento de arriba.

Cuando te pase, no lo arregles con un `Flush()` extra: averigua **por qué** el tipo tiene dos formas
de cerrarse y qué hace cada una. La respuesta te va a dejar con un problema que esta fase no puede
resolver —cerrar bien exige `await`, y `await` es la fase 05— así que escribe en dos líneas cómo lo
resolviste provisionalmente y qué deuda 💸 estás dejando. **Esa deuda es legítima y la fase 05 la
cobra.**

<details><summary>Pista 1 — el enfoque</summary>

Un solo lector, parametrizado por lo que cambia entre los tres formatos. Lo que cambia es: cómo se
parte una línea, cómo se interpreta el período, y cómo se lee un número decimal. Tres funciones.

Y para el aislamiento: el bucle que recorre los tres distribuidores es el que decide qué hacer con
cada fallo, no el lector. El lector informa; el coordinador decide.

</details>

<details><summary>Pista 2 — la herramienta</summary>

Para los importes con coma decimal, `CultureInfo` y `decimal.TryParse` con `NumberStyles`:
`https://learn.microsoft.com/dotnet/api/system.decimal.tryparse`
No uses `Replace(",", ".")` — funciona con estos datos y se rompe con el primer separador de miles.

Para el ancho fijo, `ReadOnlySpan<char>` y sus cortes, que además no asignan una cadena por columna.

Y para la trampa, lee la página de `IAsyncDisposable` completa, en particular la parte sobre tipos
que implementan las dos interfaces:
`https://learn.microsoft.com/dotnet/standard/garbage-collection/implementing-disposeasync`

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```csharp
// Lo que cambia entre los tres formatos, como datos y no como jerarquía.
internal sealed record DistributorFormat(
    string Code,                                   // DISMEX, DISCOL, DISARG
    Func<string, string[]> SplitLine,
    Func<string, SalesPeriod> ParsePeriod,
    Func<string, decimal> ParseAmount,
    bool HasHeader);

internal sealed class DistributorFileReader(string path, DistributorFormat format, Action<SalesLineError> onBadLine)
    : IDisposable
{
    public IEnumerable<SalesRow> Rows(CancellationToken token);
    public void Dispose();
}

// Lo que el coordinador produce, y lo que Wilson quería leer en la mañana.
internal sealed record LoadSummary(
    string DistributorCode,
    int Accepted,
    int Rejected,
    LoadOutcome Outcome,          // Complete, Interrupted, CouldNotOpen
    int? StoppedAtLine);
```

</details>

**Cómo se entrega**

```powershell
dotnet test src\Cordillera.slnx -c Release
dotnet run -c Release --project src\fases\04-ceremonia-delegados-y-recursos\mini -- datos\
```

```bash
git tag -a mini-04 -m "Mini F4: carga aislada de los tres distribuidores · 120.000 filas en <X> ms, <N>% rechazos, cierre verificado tras cancelación"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Escribe un método de extensión sobre `Money` que calcule la regalía a un porcentaje, y una
   prueba `[Theory]` con cuatro casos incluido el que redondea a la mitad exacta.
2. Convierte una interfaz de un solo método del modelo en un delegado y muestra cuántos archivos
   desaparecieron.
3. Declara un `delegate` propio con nombre —`RoyaltyRule`— y di en dos líneas qué aporta frente al
   `Func<Contract, Money, Money>` equivalente.
4. Escribe una clase que implemente `IDisposable` y una prueba que demuestre que `Dispose` se llama
   aunque el bloque `using` lance.
5. Convierte una prueba con montaje en un método `SetUp()` a la forma de xUnit —constructor y
   `Dispose`— y explica qué garantía ganaste.
6. Escribe una prueba `[Theory]` con `[InlineData]` para `LegacyDate.FromLegacy` cubriendo los cinco
   sabores de `LegacyDateKind` de la fase 02.

**🟡 Intermedio (7–14)**

7. Escribe un `event` en el lector de ventas que se dispare por cada mil filas, y explica por qué un
   `event` no se puede invocar desde fuera del tipo que lo declara.
8. Usa `typeof(T)` y `new T()` en un método genérico —con la restricción que haga falta— y escribe
   tres líneas sobre por qué eso **no** se puede hacer en Java.
9. Escribe un método genérico con restricción `where T : struct` y otro con `where T : class`, y
   demuestra con una llamada que el compilador elige distinto.
10. Toma `IEnumerable<out T>` y demuestra con código que un `IEnumerable<Edition>` se puede asignar
    a un `IEnumerable<object>`. Después intenta lo mismo con `IList<T>` y explica el error.
11. Escribe un `catch` con filtro (`catch (SqlException ex) when (ex.Number == 1205)`) y explica qué
    hace distinto de un `if` dentro del `catch`. La diferencia importa y no es de estilo.
12. Escribe un finalizador en una clase, provoca que se ejecute, y mide cuánto tarda en correr desde
    que el objeto quedó inalcanzable. Documenta por qué el curso no va a escribir ninguno más.
13. Convierte el lector de ventas para que acepte una `Func<string, SalesRow?>` en vez de tener el
    parseo adentro, y di qué ganaste y qué perdiste en legibilidad.
14. Provoca a propósito el fallo intermitente del paralelismo de xUnit: dos clases de prueba que
    escriban el mismo archivo temporal. Arréglalo de las dos formas —nombre único y `[Collection]`—
    y di cuándo usarías cada una.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Un proceso nocturno "termina bien" todas las noches y la mitad de las ventas no
    aparece. Te dan el código: tiene un `catch (Exception)` con un `_log.Warning`. Escribe el
    informe: qué tres fallos distintos se están mezclando, cómo lo comprobarías, y qué cambio mínimo
    los separa.
16. **Diagnóstico.** Un archivo queda bloqueado una vez cada tantas ejecuciones y la carga del día
    siguiente no puede empezar. El código usa `try`/`finally`. Encuentra el camino por el que
    `Dispose` no se llama y escribe la prueba que lo reproduce.
17. **Medición.** Ejecuta la medición de la sección 6 completa con BenchmarkDotNet y determina **el
    umbral de proporción de fallos** donde la excepción deja de ser aceptable. Publica la tabla con
    su veredicto, incluido el empate del 0% si lo hay.
18. **Medición.** Compara el costo de capturar la pila (`throw new ...`) contra relanzar (`throw;`)
    contra envolver (`throw new X("...", inner)`), un millón de veces. El resultado explica por qué
    `throw ex;` es un error y no solo mala práctica.
19. Implementa el patrón completo de `Dispose` —con `Dispose(bool)` y finalizador— para un tipo que
    envuelva un `SafeHandle`, y después **bórralo** y usa `SafeHandle` directamente. Explica por qué
    la segunda versión es la correcta en .NET moderno.
20. **Decisión — ¿se migra, se envuelve o se deja quieto?** `Sige.DataAccess` tiene 40 métodos que
    abren una `SqlConnection`, la usan y la cierran en un `finally` escrito a mano, y funciona desde
    2017. Decide qué hace el curso con eso cuando llegue a la fase 09, y sostén la decisión con el
    costo de las otras dos.
21. **Decisión — ¿se migra, se envuelve o se deja quieto?** El proceso de carga de Duván es un
    ejecutable de consola de 2019 que funciona todas las noches salvo cuando falla. Tu lector del
    miniproyecto hace lo mismo mejor. Decide, y di qué pasa con el proceso viejo el día del cambio y
    la semana siguiente.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Escribe un tipo cuyo `Dispose` se llame **dos veces** en una ejecución normal,
    sin llamarlo a mano, y explica el mecanismo. Después hazlo idempotente y demuéstralo con una
    prueba.
23. **Adversarial.** Consigue que un recurso **no** se libere aunque esté dentro de un `using`, sin
    matar el proceso y sin usar `GC.SuppressFinalize`. *(Hay al menos dos caminos; uno involucra un
    iterador con `yield return` que nadie termina de recorrer.)*
24. **Diseño y medición.** El miniproyecto dejó una deuda 💸 por el cierre asincrónico. Diseña la
    solución completa —la que la fase 05 va a poder escribir— y **mide** cuántas líneas de auditoría
    se pierden hoy con el cierre sincrónico, en función del tamaño del búfer. Ese número es la
    factura que la fase 05 va a cobrar.
25. **Defiende una decisión.** Duván revisa tu lector y dice: *"antes cada distribuidor tenía su
    clase y yo sabía dónde mirar; ahora hay un lector y tres funciones y no sé dónde está el parseo
    de Argentina"*. Tiene parte de razón. Responde por escrito, media página, y di en qué caso
    concreto volverías a tres clases.

**🔥 Opcionales**

- Escribe un analizador de Roslyn que marque como error cualquier `catch (Exception)` sin comentario
  en la línea anterior. Es la regla de esta fase sostenida por el compilador.
- Investiga `System.Threading.Lock` de .NET 9 y compáralo con `lock` sobre un `object`. No lo uses
  todavía: la fase 05 y la 17 lo van a necesitar.
- Reescribe `SalesFileReader` con un `ref struct` y `Span<char>` sin asignar una cadena por línea.
  **No lo integres**: guárdalo para la fase 06 y mide entonces si valió la pena.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://learn.microsoft.com/dotnet/csharp/programming-guide/delegates/` — delegados, `Func`,
  `Action` y eventos.
- `https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/extension-methods`
  — métodos de extensión, y las reglas de resolución que conviene conocer antes de abusar.
- `https://learn.microsoft.com/dotnet/standard/garbage-collection/implementing-dispose` — el patrón
  `IDisposable`, cuándo hace falta un finalizador (casi nunca) y por qué.
- `https://learn.microsoft.com/dotnet/standard/garbage-collection/implementing-disposeasync` —
  `IAsyncDisposable`, y **qué hacer cuando un tipo implementa las dos**. Es la lectura de la trampa.
- `https://learn.microsoft.com/dotnet/csharp/language-reference/statements/exception-handling-statements`
  — `try`/`catch`/`finally`, y los filtros `when`, que no tienen equivalente en Java.
- `https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/` — genéricos reificados,
  restricciones y varianza.
- `https://learn.microsoft.com/dotnet/standard/design-guidelines/exceptions` — las guías de diseño
  de excepciones: cuándo lanzar, qué tipo, y por qué `TryParse` existe. Cuatro páginas, muy densas.
- `https://xunit.net/docs/shared-context` — `IClassFixture` e `ICollectionFixture`, que es lo que la
  fase 08 va a usar para el contenedor de SQL Server.
- `https://xunit.net/docs/running-tests-in-parallel` — el paralelismo por omisión, que es la causa
  del primer fallo intermitente de todo el que llega.

**Especificación y propuestas del lenguaje**

- `https://github.com/dotnet/csharplang/blob/main/proposals/csharp-8.0/using.md` — la propuesta de
  `using` como declaración y de `await using`, con el problema que venían a resolver.

**Video / apoyo**

- Las charlas sobre el diseño de `IAsyncDisposable` en las conferencias de .NET explican por qué no
  se pudo simplemente cambiar `IDisposable`. No se citan identificadores: cambian.

> ⚠️ Verifica las URLs. Y la advertencia de esta fase: **mucho material sobre `IDisposable` es
> anterior a 2019** y enseña el patrón completo con finalizador y `Dispose(bool)` como si fuera
> obligatorio. Hoy, con `SafeHandle`, casi nunca lo es — y `Sige.DataAccess`, que es de 2017, está
> lleno de ese patrón escrito a medias, que es peor que no tenerlo.

**Orden de lectura sugerido:** antes de escribir, las guías de diseño de excepciones —deciden la
mitad de la fase—. Durante el miniproyecto, `implementing-disposeasync` y la página de `CultureInfo`.
Después, la propuesta de `using` en `csharplang` y las dos páginas de xUnit sobre contexto compartido
y paralelismo: son las que evitan el primer fallo intermitente.

---

## 🚀 10. Cierre y conexión con la siguiente fase

El modelo tiene su política de errores decidida **con un número detrás**, sus recursos cerrados de
forma que una prueba lo demuestra, y ni una interfaz inventada para pasar una función. La suite tiene
su ciclo de vida fijado. Y se cobró la primera deuda del curso dentro de la misma fase en que nació,
que era el punto: ver el mecanismo completo en corto antes de que las siguientes se cobren quince
fases después.

La fase 05 es el paso natural porque esta fase se quedó a mitad de camino a propósito, y el
miniproyecto lo demuestra: **cerrar bien el escritor de auditoría exige `await`**, y sin él lo único
que se puede hacer es dejar una deuda declarada. Además, la fase 05 es ⭐ por una razón que va más
allá del cierre de un archivo: en .NET `async` no es una utilidad para el código de entrada y salida,
**es el modelo del runtime entero**, y todo el Bloque D lo da por sabido. Ahí llega también el número
que vuelve la regla inolvidable: cuántos hilos consume el mismo servicio con `.Result` y con `await`
bajo doscientas peticiones concurrentes.

> **La señal de que quedó bien:** *"Ya no escribo una interfaz para pasar una función, y cuando pongo
> un `catch` sé qué estoy atrapando y qué estoy dejando subir — y puedo decir por qué."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el miniproyecto
> corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-04 -m "F4 cerrada:
> - delegados en vez de interfaces de un método, y el criterio de cuándo sí va una interfaz
> - política de errores del dominio decidida, con la medición que la sostiene
> - lectores con IDisposable correcto y prueba de cierre tras abandono del recorrido
> - deuda 💸 del finally a mano cobrada en esta misma fase
> - ciclo de vida de xUnit fijado: instancia por prueba, Theory/InlineData, paralelismo entendido"
> ```
>
> **Y esta es la primera fase que cobra una deuda**, así que aquí está la factura completa, que en
> las siguientes va a estar quince fases más lejos:
>
> ```bash
> git diff fase-03 fase-04 -- src/modern/Cordillera.Domain/Import/SalesFileReader.cs
> ```
>
> Doce líneas menos, un `finally` menos, una política de errores más y una prueba que antes no se
> podía escribir. Cuando en la fase 17 cobres las de la 05, el comando va a ser el mismo y el diff
> va a ser mucho más grande — y esa diferencia de tamaño **es** el argumento de por qué una deuda
> corta es sana y una larga hay que declararla con cuidado.
>
> Los commits llevan su prefijo (`fase 04: …`), y el miniproyecto el tag `mini-04` con sus números.
> La convención está en [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura.*

- **`INSTINTOS.md`** — cuatro entradas en una familia nueva, *ceremonia, delegados y recursos*: la
  interfaz de un solo método, la clase `Utils`, el `catch (Exception)` —que es la más cara del
  documento— y el `@BeforeEach` sobre instancia compartida. La del `catch` necesita los tres fallos
  distintos que se mezclan, o se lee como dogma.
- **`BENCHMARKS.md`** — entrada ⏳ *F04 · Excepción contra resultado, por proporción de fallos*. Es
  la segunda del curso que usa **BenchmarkDotNet** y no el arnés; el archivo tiene que decir por qué.
  Al ejecutarla, el umbral de proporción de fallos lo citan la F09 y la F17.
- **Deuda 💸 cobrada:** el `finally` a mano de la F04, pagado en la F04. El libro de deudas de la
  propuesta §7.1 ya la tiene marcada como "a la vista"; conviene anotar allí que **la factura quedó
  escrita en el bloque 🏷️ de la fase**, porque es el ejemplo que las demás citan.
- **Deuda 💸 nueva, no prevista en el libro:** el miniproyecto deja el cierre sincrónico del escritor
  de auditoría, con pérdida de líneas medible, y su cobro natural es la **F05**. Hay que agregarla al
  libro de §7.1 — es la primera deuda que nace de un miniproyecto y no de la sección 5, y conviene
  decidir si eso se permite como norma o si fue una excepción. **Recomendación: permitirlo y
  declararlo**, porque una deuda que nace donde el lector se estrella se entiende mejor.
- **Para la fase 05:** queda prometido el número de líneas de auditoría perdidas por el cierre
  sincrónico (ejercicio 24) y la prohibición de `async void` **escrita de forma que la excepción de
  la F12 encaje**: la prohibición es "fuera de un manejador de eventos", no absoluta.
- **Para la fase 08:** `IClassFixture` se nombró y no se usó, a propósito. La 08 lo estrena con el
  contenedor de SQL Server, y también `ICollectionFixture` con `[Collection]`.
- **Para la fase 09:** el ejercicio 20 plantea qué hacer con los 40 `finally` de `Sige.DataAccess`.
  La respuesta correcta es no tocarlos, y la 09 tiene que decirlo con su razón — si los moderniza, el
  curso comete el error que enseña a evitar.
- **Riesgo detectado:** la fase usa `SalesRow` y `SalesPeriod`, que no estaban en el congelamiento de
  nombres. Hay que agregarlos antes de que la F21 los necesite para separar sell-in de sell-out, o
  aparecerán dos tipos para lo mismo.
