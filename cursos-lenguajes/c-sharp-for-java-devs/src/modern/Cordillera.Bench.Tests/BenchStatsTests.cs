using Cordillera.Bench;

namespace Cordillera.Bench.Tests;

/// <summary>
/// La primera prueba del curso, y no es de juguete: cubre la aritmética que decide todos los
/// números de las veinticuatro fases siguientes. Un p95 mal calculado no se ve mal en ninguna
/// tabla.
/// </summary>
public class BenchStatsTests
{
    /// <summary>Muestra de 1 a 100 milisegundos, desordenada a propósito.</summary>
    private static IReadOnlyList<TimeSpan> OneToHundred() =>
        [.. Enumerable.Range(1, 100)
            .OrderBy(_ => Random.Shared.Next())
            .Select(ms => TimeSpan.FromMilliseconds(ms))];

    [Fact]
    public void La_mediana_de_una_muestra_impar_es_el_valor_central()
    {
        IReadOnlyList<TimeSpan> samples =
        [
            TimeSpan.FromMilliseconds(30),
            TimeSpan.FromMilliseconds(10),
            TimeSpan.FromMilliseconds(20),
        ];

        Assert.Equal(TimeSpan.FromMilliseconds(20), BenchStats.Median(samples));
    }

    [Fact]
    public void La_mediana_de_una_muestra_par_promedia_los_dos_centrales()
    {
        IReadOnlyList<TimeSpan> samples =
        [
            TimeSpan.FromMilliseconds(10),
            TimeSpan.FromMilliseconds(20),
            TimeSpan.FromMilliseconds(30),
            TimeSpan.FromMilliseconds(40),
        ];

        // 20 y 30 → 25. La implementación ingenua devuelve 30, y con distribuciones reales
        // la diferencia se esconde entre el ruido.
        Assert.Equal(TimeSpan.FromMilliseconds(25), BenchStats.Median(samples));
    }

    [Theory]
    [InlineData(50, 50)]
    [InlineData(95, 95)]
    [InlineData(99, 99)]
    [InlineData(100, 100)]
    public void El_percentil_por_rango_devuelve_la_muestra_de_esa_posicion(double percentile, int expectedMs)
    {
        // Con exactamente 100 muestras de 1 a 100 ms, el percentil p es la muestra p. Es el
        // caso donde el off-by-one se ve a simple vista, y por eso es el que se prueba.
        var actual = BenchStats.Percentile(OneToHundred(), percentile);

        Assert.Equal(TimeSpan.FromMilliseconds(expectedMs), actual);
    }

    [Fact]
    public void Con_veinte_muestras_el_p95_es_la_muestra_diecinueve_y_no_el_maximo()
    {
        IReadOnlyList<TimeSpan> samples =
            [.. Enumerable.Range(1, 20).Select(ms => TimeSpan.FromMilliseconds(ms))];

        // Es la razón por la que BenchOptions exige veinte repeticiones como mínimo: con diez,
        // el p95 y el máximo son el mismo número y la columna deja de informar.
        Assert.Equal(TimeSpan.FromMilliseconds(19), BenchStats.Percentile(samples, 95));
        Assert.Equal(TimeSpan.FromMilliseconds(20), BenchStats.Percentile(samples, 100));
    }

    [Fact]
    public void El_percentil_de_una_sola_muestra_es_esa_muestra()
    {
        IReadOnlyList<TimeSpan> samples = [TimeSpan.FromMilliseconds(7)];

        Assert.Equal(TimeSpan.FromMilliseconds(7), BenchStats.Percentile(samples, 95));
        Assert.Equal(TimeSpan.FromMilliseconds(7), BenchStats.Median(samples));
    }

    [Fact]
    public void El_resumen_no_reordena_la_lista_de_quien_llama()
    {
        var samples = new List<TimeSpan>
        {
            TimeSpan.FromMilliseconds(30),
            TimeSpan.FromMilliseconds(10),
            TimeSpan.FromMilliseconds(20),
        };

        BenchStats.Percentile(samples, 95);

        Assert.Equal(TimeSpan.FromMilliseconds(30), samples[0]);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    [InlineData(101)]
    public void Un_percentil_fuera_de_rango_no_se_negocia(double percentile)
    {
        Assert.Throws<ArgumentOutOfRangeException>(
            () => BenchStats.Percentile(OneToHundred(), percentile));
    }

    [Fact]
    public void Una_muestra_vacia_es_un_error_de_uso_y_no_un_cero()
    {
        // Devolver TimeSpan.Zero aquí sería el peor comportamiento posible: una fila de ceros
        // en BENCHMARKS.md que nadie cuestiona.
        Assert.Throws<ArgumentException>(() => BenchStats.Median([]));
    }

    [Fact]
    public void La_dispersion_de_una_muestra_constante_es_cero()
    {
        IReadOnlyList<TimeSpan> samples =
            [.. Enumerable.Repeat(TimeSpan.FromMilliseconds(42), 30)];

        Assert.Equal(0d, BenchStats.RelativeSpread(samples));
    }

    [Fact]
    public void La_dispersion_detecta_una_muestra_demasiado_ruidosa_para_decidir()
    {
        // Mitad rápida, mitad lenta: es la forma que tiene una medición contaminada por una
        // pausa del recolector o por otra cosa corriendo en la máquina.
        IReadOnlyList<TimeSpan> samples =
        [
            .. Enumerable.Repeat(TimeSpan.FromMilliseconds(10), 15),
            .. Enumerable.Repeat(TimeSpan.FromMilliseconds(60), 15),
        ];

        Assert.True(BenchStats.RelativeSpread(samples) > BenchResult.NoisyThreshold);
    }
}
