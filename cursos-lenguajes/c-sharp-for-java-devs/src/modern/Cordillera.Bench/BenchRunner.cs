using System.Diagnostics;

namespace Cordillera.Bench;

/// <summary>
/// El arnés del curso. Ejecuta una operación, descarta el calentamiento y devuelve las
/// muestras con su resumen. No formatea, no imprime, no decide nada: eso es de la herramienta
/// de consola que se construye encima.
/// </summary>
public static class BenchRunner
{
    /// <summary>
    /// Ejecuta <paramref name="operation"/> el número de veces que digan las opciones y
    /// devuelve el resultado. El calentamiento se ejecuta igual que el resto — misma ruta,
    /// mismo dato — y simplemente no se cuenta.
    /// </summary>
    public static BenchResult Run(string name, Action operation, BenchOptions? options = null)
    {
        ArgumentNullException.ThrowIfNull(operation);

        options ??= new BenchOptions();
        options.Validate();

        var machine = MachineProfile.Current();
        GuardAgainstDishonestNumbers(machine, options);

        for (int i = 0; i < options.Warmup; i++)
        {
            operation();
        }

        var samples = new TimeSpan[options.Iterations];
        var stopwatch = new Stopwatch();

        for (int i = 0; i < options.Iterations; i++)
        {
            // Se reinicia y se detiene alrededor de la operación y de nada más. Todo lo que
            // quede dentro del cronómetro y no sea la operación es error de medición: por eso
            // aquí no hay asignaciones, no hay logging y no hay comprobaciones.
            stopwatch.Restart();
            operation();
            stopwatch.Stop();

            samples[i] = stopwatch.Elapsed;
        }

        return new BenchResult(name, samples, options, machine);
    }

    /// <summary>
    /// Mide varias alternativas de lo mismo, en el orden en que se declaran, y devuelve una
    /// fila por competidor. Es la forma normal de invocarlo en el curso: una medición sin
    /// competidor no decide nada (<c>formato-de-mediciones.md</c> §2.1).
    /// </summary>
    public static IReadOnlyList<BenchResult> Compare(
        IEnumerable<(string Name, Action Operation)> competitors,
        BenchOptions? options = null)
    {
        ArgumentNullException.ThrowIfNull(competitors);

        return [.. competitors.Select(c => Run(c.Name, c.Operation, options))];
    }

    /// <summary>
    /// Las dos formas de producir un número que no se puede publicar: compilar en Debug y
    /// medir con el depurador enganchado. Las dos se detectan, y las dos se rechazan.
    /// </summary>
    private static void GuardAgainstDishonestNumbers(MachineProfile machine, BenchOptions options)
    {
        if (machine.DebuggerAttached)
        {
            throw new InvalidOperationException(
                "Hay un depurador enganchado: cualquier número que salga de aquí mide al " +
                "depurador. Ejecuta con Ctrl+F5, o `dotnet run -c Release`.");
        }

        if (!options.AllowDebugBuild &&
            machine.Configuration.Equals("Debug", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException(
                "Esta es una compilación Debug y el arnés no publica números de Debug. " +
                "Compila en Release, o pasa AllowDebugBuild = true si de verdad estás " +
                "midiendo el costo de Debug a propósito.");
        }
    }
}
