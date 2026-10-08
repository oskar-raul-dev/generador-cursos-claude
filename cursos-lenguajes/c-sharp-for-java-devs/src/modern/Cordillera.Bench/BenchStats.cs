namespace Cordillera.Bench;

/// <summary>
/// La aritmética del arnés. Es deliberadamente pequeña y deliberadamente explícita: es el
/// código que se rompe en silencio, así que es el primero que el curso cubre con pruebas.
/// </summary>
public static class BenchStats
{
    /// <summary>
    /// Mediana de la muestra. Con un número par de elementos promedia los dos centrales,
    /// que es la definición estadística y no la que escribe todo el mundo a la primera.
    /// </summary>
    public static TimeSpan Median(IReadOnlyList<TimeSpan> samples)
    {
        var ordered = Sorted(samples);
        int middle = ordered.Length / 2;

        return ordered.Length % 2 == 1
            ? ordered[middle]
            : new TimeSpan((ordered[middle - 1].Ticks + ordered[middle].Ticks) / 2);
    }

    /// <summary>
    /// Percentil por <b>rango más cercano</b>: el valor de la muestra en la posición
    /// ⌈p/100 · n⌉, contada desde 1. No interpola.
    /// </summary>
    /// <remarks>
    /// Que no interpole es una decisión, no un descuido. El p95 de una medición de latencia
    /// tiene que ser <i>un tiempo que ocurrió de verdad</i>: un valor interpolado entre dos
    /// muestras es un número que nadie observó, y a la hora de discutir un SLA eso importa.
    /// La contraparte es que con muestras pequeñas el p95 salta de golpe — con 20 muestras
    /// el p95 <b>es</b> la muestra 19, y con 10 es la 10, o sea el máximo. De ahí sale el
    /// mínimo de repeticiones que <see cref="BenchOptions"/> impone.
    /// </remarks>
    public static TimeSpan Percentile(IReadOnlyList<TimeSpan> samples, double percentile)
    {
        if (percentile is <= 0 or > 100)
        {
            throw new ArgumentOutOfRangeException(
                nameof(percentile), percentile, "El percentil tiene que estar en el rango (0, 100].");
        }

        var ordered = Sorted(samples);

        // Math.Ceiling sobre el producto, y el -1 por el índice base cero. El off-by-one de
        // esta línea es el bug clásico del arnés escrito a mano: un p95 que en realidad
        // reporta el p90 no se ve mal en ninguna tabla.
        int rank = (int)Math.Ceiling(percentile / 100d * ordered.Length);
        return ordered[Math.Clamp(rank, 1, ordered.Length) - 1];
    }

    /// <summary>
    /// Dispersión relativa de la muestra: desviación estándar sobre la mediana, en tanto por
    /// uno. Es lo que permite publicar un empate en vez de fingir un ganador
    /// (<c>formato-de-mediciones.md</c> §2.4).
    /// </summary>
    public static double RelativeSpread(IReadOnlyList<TimeSpan> samples)
    {
        if (samples.Count < 2)
        {
            return 0d;
        }

        double mean = samples.Average(s => (double)s.Ticks);
        double variance = samples.Sum(s => Math.Pow(s.Ticks - mean, 2)) / (samples.Count - 1);
        double median = Median(samples).Ticks;

        return median == 0d ? 0d : Math.Sqrt(variance) / median;
    }

    private static TimeSpan[] Sorted(IReadOnlyList<TimeSpan> samples)
    {
        ArgumentNullException.ThrowIfNull(samples);

        if (samples.Count == 0)
        {
            throw new ArgumentException("No hay muestras que resumir.", nameof(samples));
        }

        // Se copia antes de ordenar: el arnés no le reordena la lista a quien lo llama.
        var ordered = samples.ToArray();
        Array.Sort(ordered);
        return ordered;
    }
}
