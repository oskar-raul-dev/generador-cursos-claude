using System.Reflection;
using System.Runtime;
using System.Runtime.InteropServices;

namespace Cordillera.Bench;

/// <summary>
/// El entorno en que se tomó una medición. Sin esto, una medición es una anécdota con
/// decimales (<c>formato-de-mediciones.md</c> §5).
/// </summary>
public sealed record MachineProfile(
    string SdkVersion,
    string RuntimeVersion,
    string Configuration,
    string OperatingSystem,
    string Architecture,
    int LogicalCores,
    bool ServerGarbageCollector,
    bool DebuggerAttached)
{
    /// <summary>Lee el entorno de esta ejecución.</summary>
    public static MachineProfile Current()
    {
        var assembly = typeof(MachineProfile).Assembly;

        return new MachineProfile(
            SdkVersion: Metadata(assembly, "SdkVersion") ?? "desconocida",
            RuntimeVersion: RuntimeInformation.FrameworkDescription,
            Configuration: Metadata(assembly, "BuildConfiguration") ?? "desconocida",
            OperatingSystem: RuntimeInformation.OSDescription,
            Architecture: RuntimeInformation.ProcessArchitecture.ToString(),
            LogicalCores: Environment.ProcessorCount,
            ServerGarbageCollector: GCSettings.IsServerGC,
            DebuggerAttached: System.Diagnostics.Debugger.IsAttached);
    }

    /// <summary>Una línea, para la cabecera de la tabla que va a <c>BENCHMARKS.md</c>.</summary>
    public override string ToString() =>
        $"SDK {SdkVersion} · {RuntimeVersion} · compilación {Configuration} · " +
        $"{OperatingSystem} {Architecture} · {LogicalCores} núcleos lógicos · " +
        $"GC {(ServerGarbageCollector ? "servidor" : "estación de trabajo")}";

    private static string? Metadata(Assembly assembly, string key) =>
        assembly.GetCustomAttributes<AssemblyMetadataAttribute>()
            .FirstOrDefault(a => a.Key == key)
            ?.Value;
}
