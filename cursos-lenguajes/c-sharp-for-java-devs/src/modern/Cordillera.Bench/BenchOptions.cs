namespace Cordillera.Bench;

/// <summary>
/// Cómo se ejecuta una medición. Los valores por defecto son los del curso: si una fase los
/// cambia, lo dice en sus condiciones.
/// </summary>
/// <param name="Iterations">
/// Repeticiones que <b>cuentan</b>. Mínimo 20, porque con el percentil por rango más cercano
/// una muestra de 10 hace que el p95 sea el máximo y el número deja de significar algo.
/// </param>
/// <param name="Warmup">
/// Repeticiones que se ejecutan y <b>se descartan</b>. En .NET esto no es una precaución
/// decorativa: el JIT compila en el primer paso y vuelve a compilar en un nivel superior
/// cuando el método se vuelve caliente, así que las primeras iteraciones miden al compilador.
/// </param>
/// <param name="DataSize">
/// El volumen del dato, en las palabras de la fase: "500.000 filas", "1.900 movimientos
/// huérfanos". Va en la salida porque una medición sin su volumen no se puede comparar con
/// nada (<c>formato-de-mediciones.md</c> §2.3).
/// </param>
/// <param name="AllowDebugBuild">
/// Deja medir en una compilación Debug. Por omisión <c>false</c>, y el arnés se niega: un
/// número de Debug publicado en <c>BENCHMARKS.md</c> contamina todo lo que lo cite.
/// </param>
public sealed record BenchOptions(
    int Iterations = 100,
    int Warmup = 10,
    string? DataSize = null,
    bool AllowDebugBuild = false)
{
    public const int MinimumIterations = 20;

    /// <summary>Valida las opciones y explica qué está mal, no solo que está mal.</summary>
    public void Validate()
    {
        if (Iterations < MinimumIterations)
        {
            throw new ArgumentOutOfRangeException(
                nameof(Iterations),
                Iterations,
                $"Se necesitan al menos {MinimumIterations} repeticiones para que el p95 sea " +
                "algo distinto del máximo de la muestra.");
        }

        if (Warmup < 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(Warmup), Warmup, "El calentamiento no puede ser negativo.");
        }
    }
}
