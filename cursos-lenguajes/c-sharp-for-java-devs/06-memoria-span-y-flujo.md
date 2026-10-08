# 🧠 Fase 06 — Memoria, GC, `Span<T>` y flujo

> C# para desarrolladores Java senior · Fase 06 de 24 · Bloque A — el lenguaje y el runtime
> Depende de: 05 · Habilita: 07
> Estilo de esta fase: **nuevo** (.NET 10, C# 14)
> Proyecto que avanza: **el modelo de dominio y el arnés**. Al terminar, el reporte histórico corre en
> memoria constante y el arnés mide asignaciones y colecciones por generación — que es la deuda de la
> fase 00, cobrada.

---

## 🎯 1. Propósito

Cerrar el Bloque A respondiendo la pregunta que las tres fases anteriores fueron dejando abierta:
**¿qué pasa cuando el dato no cabe en memoria?** La fase 03 dejó un `ToList()` que arreglaba el conteo
de recorridos moviendo el problema; la 04 materializaba las filas; la 05 las procesó de a una pero sin
un tipo que lo expresara. Aquí llega la respuesta, y llega con su límite: `IAsyncEnumerable` para el
flujo, `Span<T>` para el parseo, y **la regla de que ninguna de las dos se usa sin haber medido
primero**.

Y una cosa más, que es la que cierra el bloque: a partir de aquí el lector escribe C# sin acento y está
listo para leer código que no escribió. Eso es la fase 07.

---

## ✅ 2. Qué queda listo al terminar

- [ ] 💸 **Se cobra la deuda de la fase 00:** el arnés mide asignaciones, pico de memoria administrada
      y **colecciones por generación**, y el `git diff fase-00 fase-06` es la factura.
- [ ] El reporte histórico de 500.000 filas corre con **pico de memoria constante**, medido, y hay una
      prueba que falla si alguien vuelve a materializar la fuente.
- [ ] El parseo de una línea de ventas **no asigna una cadena por campo**, y el número está medido
      contra la versión con `Split`.
- [ ] Sabes leer la salida del recolector: qué significa una colección de generación 2, qué es la
      promoción, y por qué el pico importa más que el total asignado.
- [ ] Sabes decir **dónde `Span<T>` no sirve**, y en particular por qué no puede cruzar un `await`.
- [ ] La medición de la sección 6 está escrita con su comando, y la entrada quedó en `BENCHMARKS.md`.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **AOT nativo y arranque en frío** → fase 20, donde se decide con la factura al lado.
- **Perfilado de producción** —trazas, muestreo continuo, telemetría— → fase 19. Aquí el perfilador
  es una herramienta de escritorio para encontrar dónde mirar, no un sistema.
- **Ajustar el recolector** (`ServerGarbageCollection`, `ConcurrentGarbageCollection`) más allá de
  saber que existen y qué cambian. La decisión se toma en la fase 20, con el contenedor y su límite de
  memoria delante, que es el único sitio donde tiene sentido.
- **`ref struct` propios y `ref` returns** más allá de lo que el miniproyecto necesita. Entran
  `Span<T>`, `Memory<T>`, `stackalloc` y `ArrayPool`; queda fuera escribir tipos `ref struct` propios,
  que se enlaza.
- **El reporte contra la base de datos real** → fase 09. Aquí el reporte histórico lee de un archivo
  generado, con los mismos volúmenes que va a tener `SP_VENTAS_HIST`.

---

## 🧠 4. Concepto mínimo

### 🩻 Esto sí funciona igual — y esta vez es casi todo

Empiezo por aquí, contra el orden habitual de la plantilla, porque después de cinco fases
corrigiéndote reflejos esta merece ir primero: **todo tu instinto de recolección de basura sirve.**

Las generaciones son generaciones: los objetos nacen en la generación 0, los que sobreviven se
promueven, y recolectar la generación 2 es caro porque implica recorrer mucho más. La hipótesis
generacional es la misma —la mayoría de los objetos muere joven— y las consecuencias prácticas son las
mismas: reducir la presión de asignación es lo que baja las pausas, y un objeto que sobrevive por
accidente es peor que diez que mueren rápido. Hay un montón de objetos grandes que se trata distinto,
igual que en la JVM. Las pausas importan más que el rendimiento total en cualquier cosa interactiva.
El recolector es generacional, con un modo de estación de trabajo y uno de servidor cuya diferencia es
la que esperas.

Y el instinto de **medir antes de optimizar** vale exactamente igual. En este ecosistema hay una
tentación adicional, que es `Span<T>`, y la fase existe en buena parte para poner ese entusiasmo en su
sitio.

Lo que cambia son tres cosas concretas, y ninguna es un concepto nuevo:

**Primera: no todo se asigna en el montón.** Un `struct` local vive en la pila, un `struct` dentro de
un arreglo vive dentro del arreglo, y un `record struct` como los de la fase 01 no produce presión de
asignación. En la JVM esto llegó con los tipos de valor mucho después; aquí está desde el principio, y
es lo que hace que el modelo de la fase 01 tenga un perfil de memoria distinto del equivalente en Java.

**Segunda: se puede trabajar sobre memoria que no es tuya.** `Span<T>` es una vista —un puntero y una
longitud— sobre memoria que está en otra parte: un arreglo, la pila, un bloque de una cadena. No copia,
no asigna, y por eso permite parsear sin producir basura. No hay equivalente en Java hasta hace muy
poco, y el precio es una restricción severa: **un `Span<T>` no puede sobrevivir a un `await` ni vivir
en un campo**, porque el compilador no puede garantizar que la memoria que apunta siga ahí.

**Tercera: el flujo tiene un tipo.** `IAsyncEnumerable<T>` es lo que la fase 03 y la 05 necesitaban y
no tenían: una secuencia que se produce de a un elemento y **con `await` en medio**. Es un
`IEnumerable` asincrónico, con `await foreach` para consumirlo, y es la respuesta a "el archivo no cabe
en memoria".

> 🧠 **El modelo mental que ordena la fase:** hay tres preguntas distintas y casi todo el mundo las
> mezcla. **¿Cuánto asigno?** (presión sobre el recolector — la baja `Span<T>`). **¿Cuánto tengo vivo a
> la vez?** (el pico — lo baja el flujo). **¿Cuánto tarda?** (el tiempo — lo puede bajar cualquiera de
> las dos, o ninguna). Optimizar la primera cuando el problema era la segunda es cómo se pierde una
> tarde sin mover el número que importaba.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**Primera: cargar el archivo entero, porque con más heap funcionaba.**

```csharp
// ❌ El reflejo de once años dimensionando la JVM: si no cabe, se le da más memoria. Con las
//    500.000 filas del reporte histórico, esto son cientos de megas vivos a la vez.
public IReadOnlyList<SalesRow> LoadHistory(string path)
{
    List<SalesRow> all = [];

    foreach (string line in File.ReadAllLines(path))   // ← y ReadAllLines ya trajo todo
    {
        all.Add(SalesRow.Parse(line));
    }

    return all;
}
```

```csharp
// ✅ El flujo: se produce una fila, se consume, se olvida. El pico no depende del tamaño del
//    archivo, y esa propiedad es lo que se está comprando.
public async IAsyncEnumerable<SalesRow> ReadHistoryAsync(
    string path,
    [EnumeratorCancellation] CancellationToken token)
{
    using var reader = new StreamReader(path);
    string? line;

    while ((line = await reader.ReadLineAsync(token)) is not null)
    {
        yield return SalesRow.Parse(line);
    }
}
```

**Por qué falla el reflejo:** porque "darle más memoria" funciona hasta que el proceso vive en un
contenedor con un límite —fase 20— o hasta que dos reportes coinciden. Y porque **el pico de memoria no
es un problema de eficiencia, es un problema de previsibilidad**: un proceso cuyo pico depende del
tamaño del dato es un proceso que un día no arranca, y ese día no lo eliges tú.

**Segunda, y es la propia de este ecosistema: optimizar sin medir, con `Span<T>` por delante.**

```csharp
// ❌ Lo que escribe alguien que acaba de leer sobre Span<T>: un parseo sin asignaciones, con
//    stackalloc, cuatro veces más largo que el original… para una operación que se ejecuta una vez
//    por reporte y cuyo costo real estaba en la consulta SQL.
Span<char> buffer = stackalloc char[256];
// … cuarenta líneas …
```

**Por qué falla el reflejo:** por el mismo motivo por el que falla en Java, solo que aquí la
herramienta es más seductora porque **es nueva y funciona**. La medición de la sección 6 tiene una
columna específica para esto: `Span<T>` cambia el número cuando la operación se ejecuta **cientos de
miles de veces**, y no lo cambia cuando se ejecuta una.

> 🧭 **La regla que fija esta fase:** **`Span<T>` es la última optimización, no la primera.** Primero
> el algoritmo, después el flujo, después las asignaciones, y solo entonces la vista sobre memoria
> ajena. Y cuando el trabajo toque la base de datos, antes que todo eso va el plan de consulta.

**Tercera, la que duele: `Span<T>` no cruza un `await`.**

```csharp
// ❌ No compila, y el mensaje del compilador no es obvio la primera vez.
async Task ProcessAsync(string path, CancellationToken token)
{
    string? line = await File.ReadAllTextAsync(path, token);
    Span<char> fields = stackalloc char[line.Length];      // ← ya estás en un método async…

    await WriteAsync(fields);   // ❌ CS4007: no se puede usar un Span en un método async
}
```

El motivo es de fondo y conviene entenderlo en vez de memorizar la prohibición: un método `async` se
convierte en una máquina de estados, y las variables locales que sobreviven a un `await` **se guardan
en un objeto en el montón**. Un `Span<T>` apunta a memoria de la pila o a memoria prestada; guardarlo
en el montón haría que apuntara a algo que ya no existe. Así que el compilador lo prohíbe, y hace bien.

```csharp
// ✅ Dos formas de convivir con eso, y las dos son legítimas.

// (a) El trabajo con Span vive en un método sincrónico que el asincrónico llama. La frontera es
//     explícita y es el patrón más común.
async Task ProcessAsync(string path, CancellationToken token)
{
    await foreach (string line in ReadLinesAsync(path, token))
    {
        SalesRow row = ParseLine(line);   // ← sincrónico, y aquí dentro Span<char> es libre
        Accumulate(row);
    }
}

static SalesRow ParseLine(ReadOnlySpan<char> line) { /* … */ }

// (b) `Memory<T>` sí puede cruzar un `await`, y se convierte en `Span<T>` con `.Span` justo donde
//     se usa. A cambio es un poco menos eficiente y bastante menos ergonómica.
async Task ProcessAsync(Memory<byte> buffer, CancellationToken token)
{
    int read = await _stream.ReadAsync(buffer, token);
    Consume(buffer.Span[..read]);
}
```

**Dónde se rompe el paralelo:** en Java no hay nada que se prohíba por esta razón, porque no hay un
tipo que represente una vista sobre la pila. Lo más cercano es un `ByteBuffer`, que es un objeto del
montón y por tanto no tiene la restricción ni la ventaja.

### 📖 Diccionario de traducción

| Java | C# / .NET | Dónde se rompe el paralelo |
|---|---|---|
| generaciones (young/old) | generaciones 0, 1 y 2 | Mismo modelo, tres generaciones nombradas por número. El razonamiento es idéntico |
| `-Xmx` | sin equivalente directo | No se dimensiona el montón: el recolector crece según el sistema. En contenedor se limita **el contenedor** (fase 20) |
| G1 / ZGC / Parallel | GC de estación de trabajo / de servidor, con o sin concurrencia | Dos modos, no un catálogo. Se eligen con dos propiedades del `.csproj` |
| `System.gc()` | `GC.Collect()` | Igual de mala idea, con la misma excepción: **medir**. El arnés de esta fase lo usa a propósito |
| `ByteBuffer` | `Span<byte>` / `Memory<byte>` | `Span` es un `ref struct`: **vive en la pila y no puede cruzar un `await`** ni estar en un campo |
| `char[]` + `System.arraycopy` | `Span<char>` + `CopyTo` | Sin copia cuando solo hay que ver: `span[2..8]` es una vista, no un arreglo nuevo |
| `String.substring` (copia desde Java 7) | `AsSpan()[2..8]` | La vista **no asigna**. `Substring` en C# sí asigna, igual que en Java |
| `Stream` de Java | `IEnumerable<T>` / `IAsyncEnumerable<T>` | El asincrónico es lo que no tiene equivalente: una secuencia con `await` entre elementos |
| `Flow.Publisher` / reactive streams | `IAsyncEnumerable<T>` | Mucho más simple: sin operadores reactivos, sin suscripción. Y el backpressure es implícito — el consumidor pide |
| pool de objetos escrito a mano | `ArrayPool<T>.Shared` | Viene en la biblioteca, y **hay que devolver** lo que se toma. Un alquiler sin devolución es una fuga silenciosa |
| `sun.misc.Unsafe` | `stackalloc` / `Unsafe` | `stackalloc` es del lenguaje y es seguro dentro de sus reglas; no hace falta salirse del sistema de tipos |
| JFR / async-profiler | ventanas de diagnóstico de Visual Studio, `dotnet-counters`, `dotnet-trace` | Herramientas distintas, mismas preguntas. **Ninguna produce un número publicable** en este curso: eso es del arnés |

> 📝 **Nota de ecosistema.** `Span<T>` llegó en 2018 con .NET Core 2.1 e `IAsyncEnumerable` en 2019 con
> C# 8. Las dos son posteriores a todo el código de SIGE, y eso importa por una razón concreta: cuando
> llegues a la fase 09 y veas `SP_VENTAS_HIST` devolviendo un `DataSet` con 500.000 filas, la pregunta
> "¿por qué no lo hicieron por flujo?" tiene una respuesta legítima — **en 2017 el tipo no existía**, y
> el `DataSet` era la forma normal de traer un resultado. Ese es exactamente el tipo de juicio que la
> fase 07 enseña a no hacer: leer una decisión de 2017 con las herramientas de 2026.

---

## 💻 5. Código mínimo con comentarios

### 5.1 El cobro de la deuda de la fase 00

El arnés medía tiempo. A partir de esta fase mide memoria, y la diferencia no es una columna más: es
la que convierte media historia en una historia.

```csharp
// src/modern/Cordillera.Bench/MemoryProbe.cs
namespace Cordillera.Bench;

/// <summary>
/// Lo que el arnés no sabía mirar hasta esta fase: cuánto se asignó, cuánto quedó vivo en el pico, y
/// **cuántas veces se despertó el recolector en cada generación**.
/// </summary>
/// <remarks>
/// 💸 Cobro de la deuda de la fase 00. Allí el arnés reportaba mediana y p95 de tiempo, y eso cuenta
/// media historia: dos implementaciones con el mismo tiempo pueden tener perfiles de memoria
/// completamente distintos, y la que asigna más va a producir pausas **en otro sitio del proceso**,
/// que es lo que hace tan difícil el diagnóstico. La factura:
///    git diff fase-00 fase-06 -- src/modern/Cordillera.Bench/
/// </remarks>
public readonly record struct MemoryReading(
    long AllocatedBytes,
    long PeakManagedBytes,
    int Gen0Collections,
    int Gen1Collections,
    int Gen2Collections)
{
    /// <summary>
    /// Toma la lectura de referencia, **después** de forzar una recolección completa para partir de un
    /// estado conocido. Es uno de los dos sitios de todo el curso donde `GC.Collect` es correcto: aquí
    /// el objeto de la medición es el recolector, así que aislarlo es el trabajo y no una trampa.
    /// </summary>
    public static MemoryReading Baseline()
    {
        GC.Collect();
        GC.WaitForPendingFinalizers();
        GC.Collect();

        return Current();
    }

    public static MemoryReading Current() => new(
        // Del proceso y no del hilo: una operación que reparte trabajo en el grupo de hilos asigna
        // en varios, y `GetAllocatedBytesForCurrentThread` reportaría casi cero con toda seriedad.
        // Es exactamente la trampa del miniproyecto de la fase 00, ahora resuelta donde correspondía.
        AllocatedBytes: GC.GetTotalAllocatedBytes(precise: true),
        PeakManagedBytes: GC.GetTotalMemory(forceFullCollection: false),
        Gen0Collections: GC.CollectionCount(0),
        Gen1Collections: GC.CollectionCount(1),
        Gen2Collections: GC.CollectionCount(2));

    /// <summary>La diferencia entre dos lecturas: lo que costó la operación que las separa.</summary>
    public static MemoryReading Delta(MemoryReading before, MemoryReading after) => new(
        after.AllocatedBytes - before.AllocatedBytes,
        Math.Max(before.PeakManagedBytes, after.PeakManagedBytes),
        after.Gen0Collections - before.Gen0Collections,
        after.Gen1Collections - before.Gen1Collections,
        after.Gen2Collections - before.Gen2Collections);

    public override string ToString() =>
        $"{AllocatedBytes / 1024d / 1024d:N1} MB asignados · pico {PeakManagedBytes / 1024d / 1024d:N1} MB · " +
        $"GC {Gen0Collections}/{Gen1Collections}/{Gen2Collections}";
}
```

**Detalles con intención**

- **`GetTotalAllocatedBytes(precise: true)` y no la variante por hilo.** Es la corrección de la
  decisión que el miniproyecto de la fase 00 pedía tomar: la variante por hilo es más rápida y miente
  en cuanto la operación usa el grupo de hilos. La lección es que **el instrumento se corrige cuando
  se descubre su límite**, y eso queda en el historial de git.
- **El pico se toma sin forzar recolección** (`forceFullCollection: false`): forzarla daría "cuánto
  sobrevive", que es otra pregunta y también útil, pero el pico es lo que decide si el proceso cabe en
  su contenedor.
- **Las tres generaciones se cuentan por separado.** Muchas colecciones de generación 0 son normales y
  baratas; **una sola de generación 2 en una operación de 200 ms es un hallazgo**, y sin esta columna
  no se ve.

### 5.2 El reporte histórico, por flujo

```csharp
// src/modern/Cordillera.Domain/Reporting/HistoricalSalesReport.cs
namespace Cordillera.Domain.Reporting;

/// <summary>
/// El reporte histórico de ventas: 500.000 filas de treinta años, agregadas por sello y canal. El
/// pico de memoria **no depende del tamaño del archivo**, y eso es la propiedad que se está
/// comprando — no la velocidad.
/// </summary>
public static class HistoricalSalesReport
{
    /// <summary>
    /// Lee las filas de a una. El atributo `[EnumeratorCancellation]` es lo que permite que
    /// `WithCancellation` funcione desde quien consume; sin él el token se ignora en silencio, que es
    /// el error más común de este tipo.
    /// </summary>
    public static async IAsyncEnumerable<SalesRow> ReadAsync(
        string path,
        [EnumeratorCancellation] CancellationToken token = default)
    {
        using var reader = new StreamReader(path);

        // Se salta el encabezado sin materializar nada.
        await reader.ReadLineAsync(token);

        string? line;
        int lineNumber = 1;

        while ((line = await reader.ReadLineAsync(token)) is not null)
        {
            lineNumber++;

            // El parseo es sincrónico a propósito: aquí dentro `ReadOnlySpan<char>` es libre, y
            // arriba no lo sería porque este método es `async`. Es la frontera de la sección 4.
            if (SalesRow.TryParse(line, lineNumber, out SalesRow row, out _))
            {
                yield return row;
            }
        }
    }

    /// <summary>
    /// Agrega por sello y canal en **un solo recorrido y sin materializar la fuente**, que es la
    /// respuesta a la trampa del miniproyecto de la fase 03.
    /// </summary>
    /// <param name="imprintOf">
    /// Resuelve el sello de una edición. **La fila de ventas no lo trae** —`VENTAS_AAAA` solo tiene
    /// `CODEDIT`— así que hay que buscarlo, y devuelve `null` para las 1.900 filas huérfanas cuya
    /// edición ya no existe. Es un delegado y no una interfaz porque es una función (fase 04), y es
    /// un parámetro porque en la fase 09 el origen del catálogo va a ser otro.
    /// </param>
    public static async Task<SalesSummary> SummarizeAsync(
        IAsyncEnumerable<SalesRow> rows,
        Func<EditionId, ImprintCode?> imprintOf,
        CancellationToken token)
    {
        var totals = new Dictionary<ReportKey, SalesFigures>();

        await foreach (SalesRow row in rows.WithCancellation(token))
        {
            // Un sello nulo no es un error: es una fila huérfana, y el reporte tiene que poder
            // decir cuántas hay. Por eso `ReportKey.Imprint` es `ImprintCode?` y no `ImprintCode`.
            ReportKey key = new(imprintOf(row.EditionCode), row.Channel);

            // El acumulador es un `record struct`: no hay una asignación por fila, solo una
            // actualización del valor dentro del diccionario. Con 500.000 filas, esa diferencia es
            // la mitad de la columna de asignaciones.
            totals.TryGetValue(key, out SalesFigures current);
            totals[key] = current.Add(row);
        }

        return new SalesSummary(totals);
    }
}
```

**El patrón a memorizar**

> **El flujo baja el pico; no baja el tiempo.** Un `IAsyncEnumerable` procesa las mismas 500.000 filas
> y hace el mismo trabajo: lo que cambia es que no hay 500.000 objetos vivos a la vez. Si tu problema
> era la velocidad, el flujo no te va a ayudar — y si tu problema era que el proceso se muere con el
> archivo de diciembre, es exactamente la respuesta.

### 5.3 El parseo sin asignar una cadena por campo

```csharp
// src/modern/Cordillera.Domain/SalesRow.cs — el parseo que la fase 04 escribió con Split
namespace Cordillera.Domain;

public readonly record struct SalesRow
{
    /// <summary>
    /// Interpreta una línea sin asignar una cadena por campo. `Split` asigna un arreglo más una
    /// cadena por columna: con once columnas y 500.000 filas son 6.000.000 de asignaciones que no
    /// hacen falta.
    /// </summary>
    public static bool TryParse(
        ReadOnlySpan<char> line,
        int lineNumber,
        out SalesRow row,
        out string? reason)
    {
        row = default;
        reason = null;

        // El enumerador de particiones recorre los separadores sin cortar la cadena: cada `Range`
        // es un par de índices, no un trozo nuevo. Existe desde .NET 8.
        var fields = line.Split(';');

        Span<Range> ranges = stackalloc Range[11];
        int count = 0;

        foreach (Range field in fields)
        {
            if (count == ranges.Length)
            {
                reason = "la línea tiene más columnas de las esperadas";
                return false;
            }

            ranges[count++] = field;
        }

        if (count != 11)
        {
            // El mensaje dice cuántas había: es lo que alguien va a necesitar mirando el archivo.
            reason = $"se esperaban 11 columnas y llegaron {count}";
            return false;
        }

        // Y a partir de aquí se trabaja sobre vistas. `int.TryParse` y `decimal.TryParse` aceptan
        // `ReadOnlySpan<char>` desde .NET Core 2.1, así que no hay que materializar ni para
        // convertir un número.
        if (!int.TryParse(line[ranges[5]], out int quantity))
        {
            reason = "la cantidad no es un número";
            return false;
        }

        if (!decimal.TryParse(line[ranges[6]], NumberStyles.Number, CultureInfo.InvariantCulture, out decimal unitPrice))
        {
            reason = "el valor unitario no es un número";
            return false;
        }

        // La única asignación que queda es la del código de edición, porque el modelo lo guarda como
        // cadena. Y eso es una decisión consciente: el ejercicio 🔥 de la fase 01 —guardar el ISBN en
        // un `long`— es la misma idea llevada al extremo, con su costo en legibilidad.
        row = new SalesRow
        {
            EditionCode = new EditionId(line[ranges[1]].ToString()),
            Quantity = quantity,
            UnitPrice = new Money(unitPrice),
            LineNumber = lineNumber,
        };

        return true;
    }
}
```

**Detalles con intención**

- **`stackalloc Span<Range>` de tamaño fijo** y no una lista: once columnas es una constante del
  formato, y la pila es gratis. Si el número de columnas fuera variable y grande, esto sería
  `ArrayPool<Range>.Shared.Rent(...)` con su `Return` en un `finally` — y **una devolución olvidada es
  una fuga silenciosa**, que es la razón de no usar el pool cuando no hace falta.
- **`CultureInfo.InvariantCulture` explícito.** Sin él, el mismo archivo se parsea distinto en una
  máquina con configuración regional colombiana y en una con la de Estados Unidos, y el bug aparece en
  el equipo de una persona. El archivo de `DISARG` con coma decimal —fase 04— es el caso contrario y
  necesita su propia cultura.
- **`line.Split(';')` sobre un `ReadOnlySpan<char>` no es `string.Split`.** Devuelve un enumerador de
  rangos y no asigna; se llaman igual y hacen cosas distintas, y esa coincidencia de nombres es una
  trampa del ecosistema que vale señalar.

**Prueba de fuego**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 06
```

Mira **la columna de generación 2**, no el tiempo. La versión que materializa va a tener al menos una
colección de generación 2 —probablemente varias— y la de flujo debería tener cero. Esa es la diferencia
que produce las pausas que en producción aparecen en otro endpoint, y por eso el arnés ahora la cuenta.

Y la mentira que te va a contar la salida si miras el lugar equivocado: **con 50.000 filas las dos
versiones dan casi lo mismo en tiempo, y la que materializa puede ganar**, porque no paga el costo de
la máquina de estados del iterador asincrónico. El flujo no es más rápido: es constante. Si mides con
un archivo chico, concluyes que el flujo es una complicación — que es la conclusión correcta para un
archivo chico.

---

## 📏 6. Medición

**Hipótesis:** materializar las 500.000 filas del reporte histórico produce un pico de memoria
proporcional al archivo y al menos una colección de generación 2; procesarlas por flujo mantiene el
pico constante. **En tiempo, las dos van a estar cerca** — y ahí está la lección, porque el argumento
del flujo no es la velocidad.

**Condiciones:** SDK 10.0.401 · Release · Windows 11 · el reporte histórico con **500.000 filas**, el
volumen real de `VENTAS_1997`…`VENTAS_2026`, y un barrido en 10.000, 100.000 y 500.000 para encontrar
el umbral · 100 repeticiones con 10 de calentamiento descartadas · **el arnés con la medición de
memoria de la sección 5.1**, que es lo que esta fase acaba de agregar.

**Competidores:** cuatro versiones del mismo reporte, todas correctas:

- **`List<SalesRow>` materializada con `Split`** — lo que produce la traducción desde Java, y lo que
  el propio curso escribió en la fase 04.
- **`List<SalesRow>` materializada con parseo sobre `Span`** — para separar el efecto del parseo del
  efecto del flujo. Sin esta fila no se puede atribuir la mejora.
- **`IAsyncEnumerable` con `Split`** — el flujo sin la optimización del parseo.
- **`IAsyncEnumerable` con parseo sobre `Span`** — las dos cosas.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 06 --rows 10000,100000,500000
```

**Resultado:** ⏳ pendiente de ejecución en tu máquina.

| Versión | Mediana | p95 | Asignado | Pico | GC 0/1/2 |
|---|---|---|---|---|---|
| `List` + `Split` | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| `List` + `Span` | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Flujo + `Split` | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Flujo + `Span` | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |

Y el barrido, que es el que da el umbral:

| Filas | `List` + `Split`: pico / GC2 | Flujo + `Span`: pico / GC2 |
|---|---|---|
| 10.000 | ⏳ | ⏳ |
| 100.000 | ⏳ | ⏳ |
| 500.000 | ⏳ | ⏳ |

> ⚖️ **Veredicto** *(expectativa, todavía sin ejecutar — `formato-de-mediciones.md` §2.6)*. Se espera
> que el pico de la versión materializada crezca linealmente con las filas y el del flujo se quede
> plano; que las colecciones de generación 2 aparezcan solo en las versiones materializadas; y que en
> **tiempo** las cuatro queden mucho más cerca de lo que el entusiasmo sugiere — posiblemente
> **empatadas** con 10.000 filas, y ahí hay que publicar el empate.
>
> **Los dos umbrales que tu ejecución tiene que determinar:** (1) **a partir de cuántas filas la
> versión materializada produce su primera colección de generación 2** — ese es el punto donde el flujo
> deja de ser una preferencia y pasa a ser la respuesta; y (2) **cuánto aporta `Span` por separado**,
> porque si aporta poco, la conclusión honesta del curso es que el parseo sobre `Span` **no valía la
> complejidad** en este caso, y eso hay que decirlo con la misma tranquilidad que lo contrario.
>
> 📝 Y un aviso sobre cómo no leer esta tabla: **estos números no dicen nada sobre `SP_VENTAS_HIST`.**
> Cuando el origen sea la base de datos, el primer orden de magnitud va a estar en el plan de consulta
> del `UNION ALL` de treinta tablas y no en cómo .NET recorre el resultado. La fase 07 mide eso, y en
> ese orden.

---

## 🧱 7. Miniproyecto — el reporte histórico que no tumba el servidor

**El encargo**

Duván te escribe, y es el correo que ya conoces de otra forma: *"El reporte histórico del comercial se
está demorando cuatro minutos y el servidor se queda sin memoria dos de cada cinco veces. Ya lo miré y
no entiendo por qué, si la consulta en Management Studio vuelve en ocho segundos. Gustavo lo pide una
vez al mes y siempre el mismo día, así que cuando falla es el mismo día que hay junta."*

**Por qué duele**

Porque el síntoma señala a un sitio y la causa está en otro, y hay que separar tres cosas que el
enunciado mezcla: **cuatro minutos** (tiempo), **se queda sin memoria** (pico), y **la consulta vuelve
en ocho segundos** (que es un dato importantísimo y todavía no lo puedes verificar, porque la base de
datos es de la fase 07).

Y porque el requisito real no es "que sea rápido": es **que no falle nunca**. Un reporte que tarda
cuatro minutos y siempre funciona es mejor que uno que tarda cuarenta segundos y falla dos de cada
cinco veces el día de la junta.

**Datos de entrada**

El volcado histórico, con la forma de `SP_VENTAS_HIST`: el `UNION ALL` de las treinta tablas anuales,
exportado a un archivo. **500.000 filas**, generadas con semilla fija, con la distribución real del
negocio y sus casos sucios:

```text
FECVENTA;CODEDIT;CODCLIEN;CODALMA;CODDISTR;CANTIDAD;VLRUNIT;VLRTOTAL;MONEDA;CANALVTA;TIPOVENTA
19970312;ED00000012;CL00000003;BOG;;25;12500.00;312500.00;COP;L;I
20031118;ED00000481;CL00000019;MEX;DISMEX;120;48000.00;5760000.00;MXN;C;I
20261231;ED00001240;CL00000088;MEX;DISMEX;150;68000.00;10200000.00;MXN;P;O
```

Y la distribución que hace realista el ejercicio, toda de la historia:

- **Treinta años de datos**, con el volumen creciendo: 1997 tiene pocos miles de filas y 2026 tiene
  decenas de miles.
- **Un 8% de filas con `TIPOVENTA = 'D'`** y cantidad negativa. Las devoluciones llegan al 30% en
  algunos títulos y aparecen meses después: **la fila de devolución de marzo está fechada en julio**, y
  eso rompe cualquier agregación ingenua por fecha.
- **Un 4% de filas huérfanas**, con `CODEDIT` que no existe.
- **Tres monedas**, y `Money` todavía sin moneda adentro — la deuda de la fase 01, que aquí estorba de
  verdad y hay que resolver de alguna forma explícita.
- **Unas 200 filas** con once columnas pero basura en la fecha: `'00000000'` y el 31 de febrero de la
  fase 02.

**Criterios de aceptación**

1. El reporte agrega por **año, sello y canal**, separando sell-in, sell-out y devolución, sobre las
   500.000 filas completas.
2. **El pico de memoria administrada se mantiene por debajo de 80 MB**, medido con el arnés de esta
   fase, y **no crece** cuando el archivo pasa de 100.000 a 500.000 filas. Una prueba con los dos
   tamaños lo demuestra.
3. **Cero colecciones de generación 2** durante la ejecución del reporte, medidas y reportadas.
4. Una prueba falla si alguien vuelve a materializar la fuente. No basta con que el pico sea bajo hoy:
   la garantía tiene que estar sostenida por una prueba, como en la fase 03.
5. El reporte declara qué hace con las tres monedas y con las filas huérfanas, y ninguna se pierde en
   silencio.
6. **Medición de cierre:** tiempo, asignaciones, pico y colecciones por generación del reporte
   completo, más el barrido de 10.000/100.000/500.000 filas. Van en el mensaje del tag `mini-06`.

**Restricciones de estilo y alcance**

Código nuevo, asincrónico, con el token propagado. El parseo va sobre `ReadOnlySpan<char>`; la
agregación, en un solo recorrido sin materializar.

Y una restricción que es el punto de la fase: **primero haz que funcione con el pico bajo, y solo
después mira si `Span` aporta algo**. Si empiezas por `Span`, vas a optimizar el 5% del problema
primero y te vas a quedar sin ganas para el 95%.

**La trampa**

Vas a lograr el pico constante con `IAsyncEnumerable` y vas a estar satisfecho. Después vas a agregar
la agrupación por año, sello y canal, y el diccionario de acumuladores va a crecer con las claves —lo
cual está bien, son unos pocos cientos— hasta que llegue el requisito que no viste venir: **Gustavo
quiere el detalle de los títulos que explican cada celda**.

Y ahí el diccionario deja de tener cientos de entradas y pasa a tener miles con listas adentro, y tu
pico constante vuelve a crecer con el archivo. La fuente está en flujo y **el resultado no**.

Cuando llegues, resuélvelo o **declara honestamente que no se puede con esta arquitectura y di qué
haría falta**. Las dos respuestas son válidas y una de las dos es la que da la fase 09 con un `GROUP BY`
en la base de datos. Escribe en tres líneas la que elijas y por qué.

<details><summary>Pista 1 — el enfoque</summary>

Tres piezas separadas: **producir** las filas (flujo), **acumular** (un estado que no crece con las
filas sino con las claves) y **presentar**. La pregunta del pico se responde mirando solo la segunda:
¿de qué depende el tamaño de tu acumulador?

Para el detalle por título de la trampa: la pregunta correcta no es cómo guardarlo todo, sino **qué es
lo mínimo que hay que guardar** para responder lo que Gustavo pregunta. Los títulos que explican una
celda casi nunca son todos.

</details>

<details><summary>Pista 2 — la herramienta</summary>

`IAsyncEnumerable` con `[EnumeratorCancellation]` —sin el atributo, `WithCancellation` no hace nada y
no te avisa:
`https://learn.microsoft.com/dotnet/csharp/language-reference/attributes/nullable-analysis`
(la referencia de atributos; busca `EnumeratorCancellation` en la de compilador)

Para el parseo, `MemoryExtensions.Split` sobre `ReadOnlySpan<char>` — que **no es** `string.Split`:
`https://learn.microsoft.com/dotnet/api/system.memoryextensions.split`

Y para medir, `GC.GetTotalAllocatedBytes` y `GC.CollectionCount`:
`https://learn.microsoft.com/dotnet/api/system.gc`

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```csharp
// La clave del reporte: año, sello, canal. Tres valores pequeños en un `record struct`, así que el
// diccionario no asigna una clave por fila.
internal readonly record struct HistoryKey(int Year, ImprintCode? Imprint, SalesChannel Channel);

// El acumulador. Lo que importa de este tipo es que su tamaño depende de las CLAVES y no de las
// filas — y que responder eso por escrito es la mitad del criterio 2.
internal sealed class HistoryAccumulator
{
    public void Add(SalesRow row);
    public IReadOnlyDictionary<HistoryKey, SalesFigures> Totals { get; }
    public int OrphanRows { get; }
    public IReadOnlyDictionary<string, int> UnparseableDates { get; }
}

internal static Task<HistoryAccumulator> RunAsync(
    IAsyncEnumerable<SalesRow> rows,
    CancellationToken token);
```

</details>

**Cómo se entrega**

```powershell
dotnet test src\Cordillera.slnx -c Release
dotnet run -c Release --project src\fases\06-memoria-span-y-flujo\mini -- datos\ventas-historico.csv
```

```bash
git tag -a mini-06 -m "Mini F6: reporte histórico en memoria constante · 500.000 filas en <X> s, pico <Y> MB, GC2=0"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Ejecuta el reporte con la versión materializada y con la de flujo sobre 100.000 filas y pega las
   dos salidas del arnés. Señala qué columna cambió y qué columna no.
2. Convierte un `IEnumerable<T>` del modelo en `IAsyncEnumerable<T>` y consúmelo con `await foreach`.
   Explica qué cambió en la firma de quien lo consume.
3. Olvida a propósito el `[EnumeratorCancellation]` y demuestra con una prueba que `WithCancellation`
   deja de funcionar **sin avisar**. Es el error más común de este tipo.
4. Parsea una fecha `AAAAMMDD` con `Substring` y con `AsSpan()[..4]`, y mide las asignaciones de un
   millón de llamadas con el arnés.
5. Escribe un método que reciba `ReadOnlySpan<char>` y llámalo con una cadena, con un `char[]` y con
   un `stackalloc`. Explica por qué los tres compilan.
6. Cuenta las colecciones por generación de una operación que asigne un millón de cadenas cortas, y
   otra que asigne mil arreglos de un megabyte. Compara los dos perfiles y explica la diferencia.

**🟡 Intermedio (7–14)**

7. Intenta declarar un `Span<char>` que sobreviva a un `await` y documenta el error del compilador.
   Después resuélvelo de las dos formas de la sección 4 y compáralas.
8. Usa `ArrayPool<byte>.Shared` para un búfer de lectura, con su `Return` en un `finally`. Después
   **olvida** el `Return` a propósito y mide qué pasa con el pico después de mil iteraciones.
9. Escribe un `IAsyncEnumerable` que lea de dos archivos y los intercale, y demuestra con el arnés que
   el pico no depende del tamaño de ninguno.
10. Mide el costo de la máquina de estados de un `IAsyncEnumerable` comparado con un `IEnumerable`
    sincrónico sobre datos ya en memoria. Es la medida del peaje que el flujo cobra.
11. Convierte el acumulador del reporte de `class` a `record struct` y mide el cambio en asignaciones.
    Explica si valió la pena y qué perdiste.
12. Investiga el montón de objetos grandes: escribe código que asigne ahí a propósito, demuéstralo con
    una medición, y di qué umbral de tamaño lo dispara.
13. Compara `Encoding.UTF8.GetString` con leer directamente sobre `Span<byte>` para las 500.000 filas.
    Reporta la diferencia y di si el archivo en UTF-8 cambia el resultado frente a uno en la
    codificación de 1997.
14. Activa `ServerGarbageCollection` en el `.csproj`, repite la medición del reporte y compara los dos
    perfiles. **No cambies el valor por defecto del curso**: anota el resultado para la fase 20.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Un proceso "se queda sin memoria dos de cada cinco veces" y el perfilador muestra
    la memoria plana. Enumera cuatro causas posibles —una involucra el montón de objetos grandes, otra
    un `ArrayPool` sin devolver— y di cómo distinguirlas con el arnés.
16. **Diagnóstico.** Un reporte por flujo tiene pico constante en desarrollo y crece en producción.
    Encuentra las dos razones más probables *(una está en el acumulador y la otra en el consumidor)* y
    escribe la prueba que las distingue.
17. **Medición.** Ejecuta la medición de la sección 6 completa con el barrido y determina **los dos
    umbrales**: la primera colección de generación 2 de la versión materializada, y cuánto aporta
    `Span` por separado. Publica la tabla con su veredicto, empates incluidos.
18. **Medición.** Mide el reporte con el archivo en un disco local y en un recurso compartido de red.
    Determina qué fracción del tiempo total es entrada y salida, y usa ese número para decidir si
    optimizar el parseo tenía sentido.
19. Implementa el detalle por título de la trampa del miniproyecto **con pico acotado**, usando una
    cota explícita —los N títulos más grandes por celda— y demuéstralo con una prueba. Documenta qué
    pregunta de Gustavo deja sin responder.
20. **Decisión — ¿se migra, se envuelve o se deja quieto?** `SP_VENTAS_HIST` devuelve un `DataSet` con
    todas las filas, y en 2017 eso era lo normal porque `IAsyncEnumerable` no existía. Decide qué hace
    el curso con ese procedimiento cuando llegue a la fase 09: reescribirlo, envolverlo con un lector
    por flujo, o dejarlo y cambiar solo quién lo llama. Sostén la decisión con el costo de las otras
    dos.
21. **Decisión — ¿se migra, se envuelve o se deja quieto?** Tu reporte por flujo funciona. El de Duván
    tarda cuatro minutos y falla dos de cada cinco veces, pero Gustavo ya sabe usarlo y su salida
    alimenta una hoja de cálculo que alguien más mantiene. Decide el plan de reemplazo, y di qué pasa
    el día del cambio y el mes siguiente.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Consigue que un `IAsyncEnumerable` tenga pico de memoria **proporcional al
    archivo**, sin materializarlo explícitamente. *(Hay al menos dos caminos; uno pasa por el
    acumulador y otro por una clausura que captura más de lo que parece.)*
23. **Adversarial.** Escribe una optimización con `Span<T>` y `stackalloc` que sea **medible pero
    peor**: que baje las asignaciones y suba el tiempo. Explica el mecanismo y usa el resultado como
    argumento de la regla de esta fase.
24. **Diseño y medición.** Toma la deuda de la fase 00 cobrada en esta fase y ve más allá: extiende el
    arnés para reportar **cuánto sobrevive** a una recolección completa, además del pico. Después mide
    el reporte con las dos versiones y explica qué pregunta responde cada número.
25. **Defiende una decisión.** Clara pregunta por qué hay que dedicarle tiempo a un reporte que
    "funciona casi siempre", cuando hay cuarenta pantallas sin migrar. Respóndele en media página, en
    su lenguaje, usando los números del ejercicio 17 y el hecho de que las dos de cada cinco veces
    caen el día de la junta.

**🔥 Opcionales**

- Reescribe `SalesRow.TryParse` como `ref struct` con un enumerador propio y mide si aporta algo sobre
  la versión de la sección 5.3. Sospecho que no, y el valor del ejercicio es comprobarlo.
- Investiga `System.IO.Pipelines` y escribe media página sobre en qué caso de este curso sería la
  herramienta correcta. *(Pista: no es el reporte histórico; es algo de la fase 17.)*
- Ejecuta `dotnet-counters` contra el reporte mientras corre y compara lo que ves con lo que reporta
  el arnés. Anota en qué se complementan y por qué el número publicable sigue siendo el del arnés.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://learn.microsoft.com/dotnet/standard/garbage-collection/fundamentals` — generaciones,
  promoción, el montón de objetos grandes y los dos modos del recolector. Se lee rápido si ya conoces
  la JVM.
- `https://learn.microsoft.com/dotnet/standard/garbage-collection/performance` — qué mirar cuando la
  memoria es el problema, y qué contadores significan qué.
- `https://learn.microsoft.com/dotnet/api/system.gc` — `GetTotalAllocatedBytes`, `CollectionCount` y
  `GetTotalMemory`, que son las tres que el arnés usa ahora.
- `https://learn.microsoft.com/dotnet/api/system.span-1` y
  `https://learn.microsoft.com/dotnet/api/system.memory-1` — las dos vistas, y **por qué una no puede
  cruzar un `await` y la otra sí**.
- `https://learn.microsoft.com/dotnet/csharp/language-reference/operators/stackalloc` — `stackalloc`
  y sus límites reales de tamaño.
- `https://learn.microsoft.com/dotnet/api/system.buffers.arraypool-1` — `ArrayPool`, y la advertencia
  sobre devolver lo alquilado.
- `https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/generate-consume-asynchronous-stream`
  — `IAsyncEnumerable` de punta a punta, con `[EnumeratorCancellation]`.
- `https://learn.microsoft.com/dotnet/core/diagnostics/dotnet-counters` — el contador en vivo, para
  encontrar dónde mirar.

**Especificación y propuestas del lenguaje**

- `https://github.com/dotnet/csharplang/blob/main/proposals/csharp-7.2/span-safety.md` — las reglas de
  seguridad de `Span<T>`. Es **la** lectura que explica la prohibición del `await` en vez de hacértela
  memorizar.

**Libros / artículos**

- La serie de Konrad Kokosa y su libro sobre el recolector de .NET son la referencia profunda del
  tema. Título, edición y URL pueden haber cambiado: verifícalos, y no cites páginas de memoria.
- Los artículos anuales de Stephen Toub sobre mejoras de rendimiento en cada versión de .NET son la
  mejor fuente para saber qué ya está optimizado y no hace falta que optimices tú. Búscalos por autor
  y año y verifica antes de citar.

> ⚠️ Verifica las URLs. Y la advertencia propia de esta fase: **mucho material sobre rendimiento en
> .NET es anterior a `Span<T>`** —o sea, anterior a 2018— y propone trucos que hoy son innecesarios o
> contraproducentes. Y otro tanto es de .NET Framework, donde el recolector y el montón de objetos
> grandes se comportan distinto: eso importa para el Bloque B, porque **SIGE corre sobre ese
> recolector**.

**Orden de lectura sugerido:** antes de escribir, los fundamentos del recolector —una hora, y si ya
conoces la JVM son treinta minutos—. Durante el miniproyecto, la página de flujos asincrónicos y la de
`Span`. Y al cerrar, `span-safety.md`: es la que convierte la prohibición en un razonamiento.

---

## 🚀 10. Cierre y conexión con la siguiente fase

**Aquí cierra el Bloque A**, y conviene mirar hacia atrás antes de mirar hacia adelante. Seis fases
atrás, el modelo de dominio no existía; ahora hay un modelo con las decisiones de tipo tomadas a
propósito, una política de nulos que distingue cinco clases de ausencia, consultas compuestas cuyo
número de recorridos se verifica con una prueba, una política de errores con un número detrás, una
cadena asincrónica de punta a punta con su cancelación probada, y un reporte de 500.000 filas que corre
en memoria constante. Y un arnés que mide las cuatro cosas que hacen falta para no opinar.

Eso es lo que significaba "C# sin acento de Java", y a partir de aquí el curso cambia de problema.

Porque la fase 07 no enseña nada moderno: **enseña a leer**. Vas a escribir el trozo de SIGE que el
resto del bloque va a cortar —el esquema de 1997 con sus nombres de diez caracteres, los
procedimientos almacenados donde vive la lógica de negocio, la capa de datos con `DataSet`, la cadena
de conexión en el `App.config` de noventa equipos— y lo vas a escribir **en el estilo de 2017, sin
arreglar nada**. Ni un `var`, ni un `using`, ni un nombre en inglés en una tabla de 1997.

Eso va a ser más incómodo de lo que suena, y es el punto. Las seis fases que acabas de terminar te
dieron los reflejos correctos; la siguiente te pide suspenderlos a propósito, porque **la primera
habilidad de una migración no es escribir bien: es leer sin juzgar**. Cada decisión incómoda de ese
esquema tiene un origen razonable y datable, y confundir "está fechado" con "está mal hecho" es el
error que convierte una migración en un incendio.

> **La señal de que quedó bien:** *"Cuando alguien me dice que algo va lento, ya no pregunto qué
> optimizar: pregunto qué se midió. Y sé distinguir un problema de tiempo de uno de pico y de uno de
> asignaciones, porque son tres."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el miniproyecto
> corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-06 -m "F6 cerrada:
> - arnés midiendo asignaciones, pico y colecciones por generación: deuda de la F00 cobrada
> - reporte histórico de 500.000 filas con pico constante y GC2=0, con prueba que lo sostiene
> - parseo sobre ReadOnlySpan<char> sin una cadena por campo, medido contra Split
> - la regla escrita: Span es la última optimización, no la primera
> - Bloque A completo: el modelo de dominio está listo para tocar el sistema heredado"
> ```
>
> **Esta fase cobra la deuda más antigua del curso**, la de la fase 00, y la factura se lee de un tirón:
>
> ```bash
> git diff fase-00 fase-06 -- src/modern/Cordillera.Bench/
> ```
>
> Seis fases de mediciones tomadas con un arnés que solo miraba el tiempo. Ninguna de esas mediciones
> estaba mal —el tiempo era correcto— pero **todas contaban media historia**, y las tablas de la 01 y la
> 03 tienen una columna de asignaciones que hasta ahora había que llenar a mano. Cuando ejecutes las
> mediciones del bloque con el arnés completo, si alguna contradice lo que estaba escrito, se marca 🪦
> en `BENCHMARKS.md` y se deja la vieja con su puntero. Eso no es un fracaso del curso: es el curso
> funcionando.
>
> Los commits llevan su prefijo (`fase 06: …`) y el miniproyecto el tag `mini-06` con sus números. La
> convención está en [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura.*

- **`INSTINTOS.md`** — dos entradas en la familia *memoria y flujo*: cargar el archivo entero porque
  con más heap funcionaba, y optimizar sin medir con `Span<T>` por delante. Y conviene que esta familia
  abra con una nota distinta a las demás: **aquí el instinto de Java casi todo sirve**, y decirlo en el
  documento consolidado es tan útil como listar los reflejos que fallan.
- **`BENCHMARKS.md`** — entrada ⏳ *F06 · Reporte histórico: cuatro versiones, con barrido*. Y una
  nota importante para el archivo: **a partir de esta fase el arnés reporta colecciones por
  generación**, así que las entradas de la F01 a la F05 tienen columnas que se llenaron con un
  instrumento más pobre. Si al reejecutarlas con el arnés completo algún veredicto cambia, se marca 🪦
  la entrada vieja con su puntero. Hay que dejarlo escrito en el encabezado del archivo.
- **Deuda 💸 cobrada:** el arnés que no aislaba el recolector (F00 → F06). Es la más antigua del curso
  y la primera cuya factura abarca seis fases; conviene que el libro de §7.1 anote que **se cobró con
  la extensión del instrumento y no con un cambio de código medido**, porque es un tipo de cobro
  distinto de los demás y el único así en todo el curso.
- **Decisión que sube al congelamiento:** `MemoryReading`, `HistoryKey`, `SalesFigures`,
  `SalesSummary`, `ReportKey` y `SalesChannel` son tipos que las fases 03 a 06 fueron necesitando y que
  no están en `congelamiento-de-nombres.md`. Hay que agregarlos **antes** de la F21, que va a separar
  sell-in de sell-out y necesita exactamente estos nombres.
- **Y la decisión pendiente de la F03:** `CountingEnumerable<T>` seguía sin casa. Vive en
  `Cordillera.Bench`, junto a `MemoryReading`: los dos son instrumentos de medición y no dominio.
  Queda resuelto aquí y hay que anotarlo en el congelamiento.
- **Para la fase 07:** el ejercicio 20 plantea qué hacer con `SP_VENTAS_HIST`, y la 07 tiene que medir
  **el plan de consulta antes que .NET**. Esta fase dejó dicho explícitamente que sus números no dicen
  nada sobre ese procedimiento; si la 07 no toma la línea base, el aviso queda sin cumplir.
- **Para la fase 09:** la trampa del miniproyecto —el detalle por título que rompe el pico constante—
  tiene su respuesta natural en un `GROUP BY` del motor. La 09 debería citarla como caso de "esto no lo
  arregla .NET, lo arregla SQL".
- **Para la fase 20:** el ejercicio 14 deja medido el efecto de `ServerGarbageCollection` sin cambiar
  el valor por defecto. Ese número es entrada de la 20, con el límite de memoria del contenedor
  delante.
