namespace Cordillera.Bench;

/// <summary>
/// El resultado de una medición: las muestras que contaron, su resumen y el entorno en que se
/// tomaron. Es inmutable a propósito — un resultado que alguien puede editar después de leerlo
/// no sirve de evidencia.
/// </summary>
public sealed record BenchResult
{
    public BenchResult(string name, IReadOnlyList<TimeSpan> samples, BenchOptions options, MachineProfile machine)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(name);

        Name = name;
        Samples = samples;
        Options = options;
        Machine = machine;

        Median = BenchStats.Median(samples);
        P95 = BenchStats.Percentile(samples, 95);
        RelativeSpread = BenchStats.RelativeSpread(samples);
    }

    /// <summary>Qué se midió, en las palabras de la fase. Es el nombre de la fila en la tabla.</summary>
    public string Name { get; }

    /// <summary>Las muestras que contaron, en el orden en que ocurrieron. Sin el calentamiento.</summary>
    public IReadOnlyList<TimeSpan> Samples { get; }

    public BenchOptions Options { get; }

    public MachineProfile Machine { get; }

    public TimeSpan Median { get; }

    public TimeSpan P95 { get; }

    /// <summary>
    /// Desviación estándar sobre la mediana. Por encima de 0,15 la medición es demasiado
    /// ruidosa para sostener una diferencia pequeña, y el veredicto tiene que decir empate.
    /// </summary>
    public double RelativeSpread { get; }

    /// <summary>Umbral de ruido por encima del cual dos resultados cercanos son un empate.</summary>
    public const double NoisyThreshold = 0.15d;

    public bool IsNoisy => RelativeSpread > NoisyThreshold;
}
