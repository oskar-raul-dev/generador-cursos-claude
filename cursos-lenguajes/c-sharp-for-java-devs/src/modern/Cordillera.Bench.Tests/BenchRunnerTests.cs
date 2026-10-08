using Cordillera.Bench;

namespace Cordillera.Bench.Tests;

public class BenchRunnerTests
{
    private static readonly BenchOptions Fast = new(Iterations: 20, Warmup: 5, AllowDebugBuild: true);

    [Fact]
    public void El_calentamiento_se_ejecuta_y_no_se_cuenta()
    {
        int calls = 0;

        var result = BenchRunner.Run("contador", () => calls++, Fast);

        // Veinticinco invocaciones, veinte muestras. Es la propiedad que hace honesto al
        // arnés, y es la que se rompe cuando alguien "optimiza" el bucle de calentamiento.
        Assert.Equal(25, calls);
        Assert.Equal(20, result.Samples.Count);
    }

    [Fact]
    public void El_resultado_declara_el_entorno_en_que_se_tomo()
    {
        var result = BenchRunner.Run("nada", static () => { }, Fast with { DataSize = "3 sellos" });

        Assert.NotEqual("desconocida", result.Machine.SdkVersion);
        Assert.Equal("3 sellos", result.Options.DataSize);
        Assert.Contains("núcleos lógicos", result.Machine.ToString(), StringComparison.Ordinal);
    }

    [Fact]
    public void Menos_de_veinte_repeticiones_no_se_aceptan()
    {
        var options = new BenchOptions(Iterations: 10, AllowDebugBuild: true);

        var error = Assert.Throws<ArgumentOutOfRangeException>(
            () => BenchRunner.Run("muy corto", static () => { }, options));

        Assert.Contains("p95", error.Message, StringComparison.Ordinal);
    }

    [Fact]
    public void Comparar_devuelve_una_fila_por_competidor_y_en_su_orden()
    {
        (string, Action)[] competitors =
        [
            ("concatenación", static () => _ = string.Concat("MOVINVEN", "_2026")),
            ("interpolación", static () => _ = $"MOVINVEN_{2026}"),
        ];

        var results = BenchRunner.Compare(competitors, Fast);

        Assert.Collection(
            results,
            first => Assert.Equal("concatenación", first.Name),
            second => Assert.Equal("interpolación", second.Name));
    }

    [Fact]
    public void Una_medicion_sin_nombre_no_existe()
    {
        Assert.Throws<ArgumentException>(
            () => BenchRunner.Run("   ", static () => { }, Fast));
    }
}
