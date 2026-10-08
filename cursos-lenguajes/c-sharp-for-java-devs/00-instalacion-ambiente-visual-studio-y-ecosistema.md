# 🛠️ Fase 00 — Ambiente, Visual Studio y el mapa del ecosistema

> C# para desarrolladores Java senior · Fase 00 de 24 · Bloque 0 — el ambiente
> Depende de: ninguna · Habilita: 01
> Estilo de esta fase: **nuevo** (.NET 10, C# 14)
> Proyecto que avanza: **nace el arnés de medición**. Al terminar existe `Cordillera.Bench` con su
> suite de pruebas, y `Cordillera.Bench.Cli` produce una tabla lista para pegar en `BENCHMARKS.md`.

---

## 🎯 1. Propósito

Dejarte con un ambiente que no te va a mentir: un SDK fijado por repositorio, una solución que
compila igual en tu máquina y en CI, paquetes con versión reproducible, y **el arnés con el que se
miden las veinticuatro fases siguientes**.

No es un capítulo de instalación. Es el primero en el que decides cosas: qué SDK responde cuando
escribes `dotnet`, qué se fija en un archivo y qué se deja al criterio de cada máquina, y qué
significa que un número sea publicable. La regla que sale de aquí y que no se suelta más:

> 🧭 **Si no lo puedes medir con el arnés, no lo afirmas.**

---

## ✅ 2. Qué queda listo al terminar

- [ ] `dotnet --list-sdks` y `dotnet --info` te dicen qué SDK responde, y sabes **por qué ese**.
- [ ] `src/global.json` fija el SDK del repositorio, y cambiarlo cambia la respuesta anterior.
- [ ] `src/Cordillera.slnx` compila en Release sin una sola advertencia, con nullable activado y
      advertencias como errores heredadas de un solo archivo.
- [ ] `src/legacy/` existe, vacío de proyectos, **con su propio `Directory.Build.props` y su
      `.editorconfig` que apagan el análisis**: la frontera entre generaciones está puesta antes de
      que haya código a los dos lados.
- [ ] `dotnet restore --locked-mode` pasa, y `packages.lock.json` está versionado.
- [ ] `dotnet test` corre y las pruebas de `Cordillera.Bench.Tests` pasan — **incluida la que
      demuestra que el p95 de veinte muestras es la muestra 19 y no el máximo**.
- [ ] El arnés se niega a medir en Debug y con el depurador enganchado, y lo demuestras.
- [ ] WSL 2 y el runtime de contenedores están instalados y verificados, sin usarse todavía.
- [ ] `BENCHMARKS.md` e `INSTINTOS.md` existen en la raíz, con su forma y sin un solo número.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **El sistema heredado, la base de datos y los contenedores en uso** → fases 07 y 08. WSL 2 se
  instala aquí porque instalarlo el día que lo necesitas es el día que no avanzas, pero no se
  levanta ni un contenedor todavía.
- **Medir código asíncrono** → fase 05. El arnés de esta fase mide operaciones sincrónicas, y eso
  alcanza para las seis fases del Bloque A.
- **Aislar el recolector y contar colecciones por generación** → fase 06. Es la deuda 💸 declarada
  de esta fase.
- **`dotnet publish` y sus tres modos** —autocontenido, dependiente del framework y AOT nativo— se
  nombran aquí y se **eligen con números** en la fase 20.
- **CI** → se nombra el principio (todo lo que el curso pide se puede hacer sin IDE, porque en CI
  no hay IDE) y el pipeline se arma en la fase 20, junto a la factura.

---

## 🧠 4. Concepto mínimo

Hay tres cosas que en este ecosistema funcionan distinto de como esperas, y las tres te van a
morder en la primera semana si nadie te las dice.

**La primera: el SDK es global y el proyecto no lo sabe.** En tu máquina puede haber cinco SDK
instalados, y el que responde a `dotnet build` es el más reciente que encuentre, no el que el
proyecto necesita. El equivalente de fijar la versión del compilador en el `pom` es un archivo
aparte, `global.json`, que hay que crear a propósito — y si no está, el proyecto compila con lo que
haya, que es exactamente el tipo de diferencia que produce un fallo que solo pasa en CI.

**La segunda: el `.csproj` es el build.** No es un descriptor que otra herramienta interpreta: es
un archivo de MSBuild, con propiedades, ítems y objetivos, que se **ejecuta**. De ahí sale algo que
en Maven no tiene equivalente directo: los archivos `Directory.Build.props` y
`Directory.Packages.props` se importan **por posición en el árbol de directorios**, así que una
propiedad puesta en `src/modern/` aplica a todo lo que esté debajo y no aplica a `src/legacy/`. Eso
es lo que le permite a este curso tener dos generaciones de C# en el mismo repositorio con reglas
opuestas, sin un solo `#if`.

**La tercera: la reproducibilidad hay que pedirla.** `PackageReference` acepta rangos y versiones
flotantes; la caché es por máquina; y una restauración sin lockfile puede traerte hoy una versión
distinta de la de ayer sin que nada cambie en tu repositorio. El famoso *"en mi máquina compila"*
de .NET casi siempre vive aquí.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El reflejo:** *"el IDE me resuelve el proyecto"*. Abres Visual Studio, `Archivo → Nuevo
proyecto`, el asistente escribe el `.csproj`, el gestor de NuGet elige la versión del paquete, y
compilas con F5 sin haber leído nada.

En Java hacías lo mismo con el arquetipo de Maven y no pasaba gran cosa, porque después el `pom`
quedaba ahí, declarativo, revisable, y la reproducibilidad te la daba `~/.m2` casi gratis. Aquí el
resultado es otro: te queda un `.csproj` que nadie leyó, una versión de paquete que eligió una
ventana, y un build que depende del SDK que esa máquina tenga instalado.

**El código que produce** —lo que el asistente escribiría, comparado con lo que el curso escribe:

```xml
<!-- ❌ Lo que sale del asistente si nadie lo toca. Compila. También compila distinto en la
     máquina de al lado. -->
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <!-- Sin nullable. Sin advertencias como errores. Repetido en cada .csproj. -->
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="xunit.v3" Version="4.*" />
  </ItemGroup>
</Project>
```

```xml
<!-- ✅ Lo que el curso escribe. Lo compartido vive arriba, una vez, y la versión del paquete
     no está aquí: está en Directory.Packages.props. -->
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <RootNamespace>Cordillera.Bench</RootNamespace>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="xunit.v3" />
  </ItemGroup>
</Project>
```

**Por qué falla el reflejo:** `4.*` no es una comodidad, es una bomba de tiempo con retardo
variable — el día que salga la 4.1 tu build cambia sin que tú cambies nada, y el build de tu
compañero cambia otro día distinto. Y el `<Nullable>` ausente no es un detalle de estilo: es la
diferencia entre que el compilador te avise de un `null` y que te enteres en producción.

**Qué se escribe en su lugar:** el SDK fijado con `global.json`, lo transversal en
`Directory.Build.props`, las versiones exactas en `Directory.Packages.props`, el `packages.lock.json`
versionado, y `--locked-mode` en CI. Cuatro archivos, una vez, para veinticinco fases.

### 🩻 Esto sí funciona igual

Casi todo el oficio que tienes alrededor del código. Un proyecto es un artefacto con dependencias
declaradas y un grafo que se resuelve; hay una fuente central de paquetes y puedes tener fuentes
privadas; el build se puede ejecutar entero desde la línea de comandos y eso es lo que corre en
CI; las pruebas se descubren, se ejecutan y se reportan igual; y el depurador hace lo que hace un
depurador — puntos de interrupción, inspección, pila de llamadas, expresiones condicionales.

Y hay una que conviene decir en voz alta porque tranquiliza: **lo que sabes de perfilado y de
recolección de basura sirve aquí**. Generaciones, promoción, pausas, presión de asignación: los
nombres cambian poco y los razonamientos no cambian. Lo trataremos en la fase 06 asumiendo que ya
lo sabes.

### 📖 Diccionario de traducción

| Mundo Java | Mundo .NET | Dónde se rompe el paralelo |
|---|---|---|
| `pom.xml` / `build.gradle` | `.csproj` | Es un archivo de MSBuild: el proyecto **es** el build, no lo declara |
| Maven Central | NuGet | Sin *groupId*: el nombre es de quien lo registra primero, y no hay namespace que te proteja |
| `~/.m2` compartido | caché global + restauración por proyecto | La reproducibilidad la da el lockfile, y **hay que pedirla** |
| módulos de un `pom` padre | `.slnx` y `Directory.Build.props` | La solución es del IDE; el build real es proyecto por proyecto, y lo compartido se hereda **por directorio** |
| `mvn test` | `dotnet test` | Sin ciclo de vida de fases: MSBuild ejecuta objetivos, no etapas, y no hay un orden canónico que memorizar |
| JAR ejecutable | `dotnet publish` con sus modos | Autocontenido, dependiente del framework o AOT nativo: tres respuestas distintas, y se eligen con números en la fase 20 |
| `mvn versions:set` | `Directory.Packages.props` | La versión vive en un solo archivo del repositorio, no en cada módulo |
| `-SNAPSHOT` | prerelease con sufijo (`4.1.0-pre.2`) | No hay noción de "instantánea que se sobrescribe": cada versión publicada es inmutable |
| perfil de Maven (`-P`) | `Configuration` y condiciones de MSBuild | No hay activación por entorno: la condición se escribe explícita en el `.csproj` o en los props |

> 📝 **Nota de ecosistema.** El formato SDK del `.csproj` —el de diez líneas— llegó con .NET Core
> 1.0 en 2016, y el formato anterior, el que lista cada archivo `.cs` a mano y arrastra GUID, es
> el que vas a encontrar en **todo** el código de SIGE, porque es de 2017 y es de .NET Framework.
> La fase 11 lo convierte. El archivo de solución también cambió: `dotnet new sln` en el SDK 10 ya
> genera **SLNX**, XML y sin GUID, y Visual Studio 2026 lo abre nativo. Este curso usa `.slnx` para
> lo nuevo y deja `Sige.sln` en su formato de 2017, porque es el archivo que los pasantes
> commitearon y porque tener los dos delante enseña más que explicarlo.

---

## 💻 5. Código mínimo con comentarios

### 5.1 Qué SDK te está respondiendo

Antes de escribir una línea, la pregunta que casi nadie se hace:

```powershell
dotnet --list-sdks
# 8.0.414 [C:\Program Files\dotnet\sdk]
# 9.0.305 [C:\Program Files\dotnet\sdk]
# 10.0.401 [C:\Program Files\dotnet\sdk]

dotnet --info   # runtime, arquitectura, y la ruta que de verdad se está usando
```

Con tres SDK instalados, `dotnet build` usa el **más reciente** que encuentre. No el que el
proyecto necesita: el más reciente. Y eso se arregla por repositorio, con un archivo:

```json
// src/global.json — el SDK del repositorio, fijado. Es el equivalente funcional de fijar la
// versión del compilador en el pom, y hay que crearlo a mano: no viene con nada.
{
  "sdk": {
    "version": "10.0.401",
    "rollForward": "latestPatch"
  }
}
```

**Detalles con intención**

- `rollForward: latestPatch` acepta 10.0.4xx pero **no** 10.1 ni 11.0 — dejas entrar correcciones
  y no cambios de comportamiento. `disable` sería más estricto y te rompería el build en cada
  máquina que tenga un patch distinto; `latestMajor` sería no haber escrito el archivo.
- El archivo va en `src/`, no en la raíz del repositorio, porque la resolución **sube** por el
  árbol desde el directorio actual: así cubre las dos soluciones y no cubre a los scripts de
  herramientas que viven más arriba.

> 💡 `dotnet --version` dentro de `src/` y fuera de `src/` te va a responder distinto. Ese es el
> mecanismo funcionando, y es la forma más rápida de comprobar que `global.json` está donde crees.

### 5.2 La anatomía de la solución, y la frontera entre generaciones

```text
src/
  global.json           ← el SDK, fijado
  nuget.config          ← una sola fuente, declarada
  .editorconfig         ← formato y analizadores de lo nuevo
  Sige.sln              ← la solución heredada, formato de 2017 · net48
  Cordillera.slnx       ← la solución nueva, formato SLNX · net10.0
  legacy/               ← código de 2017. Su propio props, su propio editorconfig
  modern/               ← lo nuevo. Nullable, advertencias como errores, CPM
  fases/NN-nombre/mini/ ← el miniproyecto 🧱 de una fase, que no toca legacy/ ni modern/
```

Lo transversal se declara **una vez**, y lo hereda todo lo que esté debajo:

```xml
<!-- src/modern/Directory.Build.props — aplica a TODO lo que esté debajo de modern/ -->
<Project>

  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <AnalysisLevel>latest-all</AnalysisLevel>
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
    <ImplicitUsings>enable</ImplicitUsings>
    <NeutralLanguage>es</NeutralLanguage>
  </PropertyGroup>

  <!-- Restauración reproducible: el lockfile se versiona, y en CI la compilación falla si el
       lockfile no coincide con lo que se pide. Es lo que Maven te daba con el pom. -->
  <PropertyGroup>
    <RestorePackagesWithLockFile>true</RestorePackagesWithLockFile>
    <RestoreLockedMode Condition="'$(ContinuousIntegrationBuild)' == 'true'">true</RestoreLockedMode>
  </PropertyGroup>

</Project>
```

```xml
<!-- src/legacy/Directory.Build.props — el mismo mecanismo, decisiones opuestas. Todavía no hay
     ningún proyecto debajo: los escribe la fase 07. Se crea ahora porque la frontera se define
     antes de que haya código a los dos lados. -->
<Project>

  <PropertyGroup>
    <TargetFrameworkVersion>v4.8</TargetFrameworkVersion>
    <Nullable>disable</Nullable>
    <TreatWarningsAsErrors>false</TreatWarningsAsErrors>
    <EnableNETAnalyzers>false</EnableNETAnalyzers>
    <LangVersion>7.3</LangVersion>
  </PropertyGroup>

</Project>
```

**El patrón a memorizar**

> En .NET lo compartido se hereda **por posición en el árbol de directorios**, no por herencia de
> un proyecto padre. Mover una carpeta cambia lo que un proyecto hereda, y eso es tanto la
> potencia del mecanismo como su trampa.

Y el corolario que este curso necesita: con dos subárboles y dos props, **el código de 2017 no
puede recibir las reglas de 2026 por accidente**. Ni un `var` de más, ni una advertencia
convertida en error sobre un archivo que nadie va a arreglar. `dotnet format` sobre `legacy/`
produciría el diff más peligroso del curso: doscientos archivos cambiados, ninguna prueba
fallando, y tres cosas rotas que aparecen en dos semanas.

### 5.3 NuGet, que es donde este perfil se estrella

Tres archivos y una regla.

```xml
<!-- src/nuget.config — el <clear/> es la línea importante: sin él, el orden de las fuentes lo
     decide la configuración de cada máquina, y basta una fuente interna con un paquete del
     mismo nombre para que dos personas compilen contra binarios distintos. -->
<configuration>
  <packageSources>
    <clear />
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" />
  </packageSources>
  <packageSourceMapping>
    <packageSource key="nuget.org">
      <package pattern="*" />
    </packageSource>
  </packageSourceMapping>
</configuration>
```

```xml
<!-- src/modern/Directory.Packages.props — Central Package Management. La versión de cada
     paquete se declara aquí y en ningún .csproj; si alguien escribe una Version en un
     PackageReference, la compilación falla. Eso es lo que queremos. -->
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
    <CentralPackageTransitivePinningEnabled>true</CentralPackageTransitivePinningEnabled>
  </PropertyGroup>

  <ItemGroup>
    <PackageVersion Include="xunit.v3" Version="4.0.0" />
    <PackageVersion Include="xunit.runner.visualstudio" Version="4.0.0" />
    <PackageVersion Include="Microsoft.NET.Test.Sdk" Version="18.10.0" />
  </ItemGroup>
</Project>
```

**Detalles con intención**

- **Nada de versiones flotantes.** Ni `4.*`, ni `[4.0,5.0)`. Una versión flotante convierte tu
  build en una función del calendario.
- **`CentralPackageTransitivePinningEnabled`** fija también las transitivas, que es el caso que en
  Maven resolvías con `dependencyManagement` y aquí se pide con una propiedad.
- **El `packages.lock.json` se versiona.** Con `--locked-mode`, una restauración que necesite algo
  que el lockfile no tiene **falla** en vez de resolverlo por su cuenta.

```powershell
dotnet restore src\Cordillera.slnx --locked-mode
dotnet nuget locals all --list      # dónde vive la caché que explica el "en mi máquina compila"
```

> ⚠️ La caché global de NuGet es por usuario y **no distingue configuraciones**. Si borras un
> paquete de tu `Directory.Packages.props` pero sigue en la caché, el build local puede seguir
> funcionando por razones que no están en tu repositorio. `dotnet nuget locals all --clear` antes
> de un diagnóstico serio no es paranoia: es la mitad de los diagnósticos.

### 5.4 El arnés — lo que esta fase construye

Aquí nace el proyecto que avanza. La biblioteca hace tres cosas y ninguna más: ejecuta N veces,
descarta el calentamiento y resume. No imprime, no formatea, no decide nada.

Primero la aritmética, porque es lo que se rompe en silencio:

```csharp
// src/modern/Cordillera.Bench/BenchStats.cs
namespace Cordillera.Bench;

public static class BenchStats
{
    /// <summary>
    /// Percentil por <b>rango más cercano</b>: el valor de la muestra en la posición
    /// ⌈p/100 · n⌉, contada desde 1. No interpola.
    /// </summary>
    /// <remarks>
    /// Que no interpole es una decisión. El p95 de una latencia tiene que ser un tiempo que
    /// ocurrió de verdad: un valor interpolado entre dos muestras es un número que nadie
    /// observó, y discutir un SLA con eso es discutir con una invención. La contraparte es que
    /// con muestras pequeñas el p95 salta de golpe, y de ahí sale el mínimo de repeticiones.
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
    /// Dispersión relativa: desviación estándar sobre la mediana. Es lo que permite publicar un
    /// empate en vez de fingir un ganador.
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
```

Después el bucle, con lo único que tiene de sutil bien marcado:

```csharp
// src/modern/Cordillera.Bench/BenchRunner.cs
public static BenchResult Run(string name, Action operation, BenchOptions? options = null)
{
    ArgumentNullException.ThrowIfNull(operation);

    options ??= new BenchOptions();
    options.Validate();

    var machine = MachineProfile.Current();
    GuardAgainstDishonestNumbers(machine, options);

    // El calentamiento se ejecuta igual que el resto —misma ruta, mismo dato— y no se cuenta.
    // Sin esto se mide al JIT: compila en el primer paso y vuelve a compilar en un nivel
    // superior cuando el método se vuelve caliente.
    for (int i = 0; i < options.Warmup; i++)
    {
        operation();
    }

    var samples = new TimeSpan[options.Iterations];
    var stopwatch = new Stopwatch();

    for (int i = 0; i < options.Iterations; i++)
    {
        // Se reinicia y se detiene alrededor de la operación y de nada más. Todo lo que quede
        // dentro del cronómetro y no sea la operación es error de medición: por eso aquí no hay
        // asignaciones, no hay logging y no hay comprobaciones.
        stopwatch.Restart();
        operation();
        stopwatch.Stop();

        samples[i] = stopwatch.Elapsed;
    }

    return new BenchResult(name, samples, options, machine);
}
```

Y la parte que hace al arnés confiable, que no es el cronómetro sino las dos negativas:

```csharp
/// <summary>
/// Las dos formas de producir un número que no se puede publicar: compilar en Debug y medir
/// con el depurador enganchado. Las dos se detectan, y las dos se rechazan.
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
```

**Detalles con intención**

- **Mínimo veinte repeticiones**, y el mensaje de error explica por qué: con diez muestras y
  percentil por rango, el p95 **es** el máximo, y la columna deja de informar.
- **`BenchResult` es inmutable y guarda las muestras**, no solo el resumen. Sin las muestras no
  hay dispersión, y sin dispersión no se puede declarar un empate.
- **La configuración de compilación no está disponible en tiempo de ejecución** y MSBuild sí la
  conoce, así que se inyecta desde el `.csproj`. Es el `.csproj`-es-el-build en dos líneas:

  ```xml
  <ItemGroup>
    <AssemblyMetadata Include="SdkVersion" Value="$(NETCoreSdkVersion)" />
    <AssemblyMetadata Include="BuildConfiguration" Value="$(Configuration)" />
  </ItemGroup>
  ```

> 💸 **Deuda declarada: el arnés no aísla el recolector.** Mide tiempo y reporta dispersión, pero
> no fuerza una recolección entre iteraciones, no cuenta colecciones por generación y no separa la
> presión de asignación del costo de recolectarla. Lo correcto sería hacer las tres cosas, y **se
> paga en la fase 06**, que es donde ese número cambia una decisión y no antes. Hasta entonces,
> cuando una medición de esta fase o del Bloque A tenga una dispersión alta, la explicación más
> probable es una pausa de GC que el arnés todavía no sabe ver.

### 5.5 La primera prueba del curso

xUnit v3, y no es una prueba de juguete: cubre la aritmética de la que dependen todos los números
del curso.

```csharp
// src/modern/Cordillera.Bench.Tests/BenchStatsTests.cs
public class BenchStatsTests
{
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

        Assert.Equal(TimeSpan.FromMilliseconds(19), BenchStats.Percentile(samples, 95));
        Assert.Equal(TimeSpan.FromMilliseconds(20), BenchStats.Percentile(samples, 100));
    }

    [Fact]
    public void Una_muestra_vacia_es_un_error_de_uso_y_no_un_cero()
    {
        // Devolver TimeSpan.Zero aquí sería el peor comportamiento posible: una fila de ceros
        // en BENCHMARKS.md que nadie cuestiona.
        Assert.Throws<ArgumentException>(() => BenchStats.Median([]));
    }
}
```

```powershell
dotnet test src\Cordillera.slnx -c Release
```

**Detalles con intención**

- `[Theory]` con `[InlineData]` es el `@ParameterizedTest` que ya usas, y el mapa completo del
  ciclo de vida —instancia nueva por prueba, `IClassFixture`, `IAsyncLifetime`— va en la fase 04,
  donde el tema es `IDisposable` y el paralelo cae solo.
- **Los nombres de las pruebas son frases en español**, y es deliberado: el identificador es lo
  único del curso que puede llevar la frase que explica el caso, y `dotnet test` las imprime. Los
  identificadores del código de producción siguen en inglés, sin excepción.
- El proyecto de pruebas no lleva `Version` en ningún `PackageReference`: las versiones viven en
  `Directory.Packages.props` y escribir una aquí rompe el build a propósito.

### 5.6 Visual Studio, cuatro cosas bien

**Las cargas de trabajo: cuatro, no catorce.** El criterio es que **una sola instalación tiene que
poder abrir el legado y lo nuevo**:

- **Desarrollo de escritorio de .NET** — trae el diseñador de WinForms y de WPF, y es la que
  permite abrir los formularios de 2017 y los de .NET 10.
- **Desarrollo web y ASP.NET** — para el Bloque D, y también para los ASMX de 2019 que la fase 11
  migra.
- **Almacenamiento y procesamiento de datos** — las herramientas de SQL Server dentro del IDE, que
  desde la fase 07 se usan a diario.
- **Desarrollo de aplicaciones de Windows** — solo por el prototipo de WinUI 3 de la fase 14.

Más un componente individual que no viene con ninguna de las cuatro y sin el cual el Bloque B no
compila: **el paquete de destino de .NET Framework 4.8**.

**Y cuatro cosas del IDE que valen la pena aprender de verdad**, porque son las que vas a usar en
las veinticuatro fases siguientes:

- **Punto de interrupción condicional y punto de traza.** Clic derecho sobre el punto rojo →
  `Condiciones`. Un punto de interrupción con condición `movement.Quantity < 0` te ahorra las
  quinientas iteraciones anteriores; un **punto de traza** (`Acciones`) imprime y no detiene, que
  es lo que quieres cuando el problema aparece una vez de cada seis.
- **La ventana Inmediato** (`Ctrl+Alt+I`). Evalúa expresiones y **llama métodos** en el estado
  actual del proceso. Es lo más parecido a un REPL con tu programa dentro, y es la herramienta que
  convierte una sesión de depuración en una exploración.
- **Recarga en caliente.** Cambias el cuerpo de un método y sigue corriendo. Tiene límites reales
  —cambiar una firma, agregar un campo— y el IDE te lo dice; en el Bloque C, con un formulario
  abierto y datos cargados, es la diferencia entre iterar en segundos y en minutos.
- **El Explorador de pruebas y las ventanas de diagnóstico.** El primero descubre y ejecuta lo que
  `dotnet test` ejecuta, con la misma lista. Las segundas —uso de CPU, asignación de memoria— son
  el perfilador, y tienen una regla en este curso: **sirven para encontrar dónde mirar, no para
  publicar un número**. Los números publicables salen del arnés.

> ⚠️ **Lo que el IDE hace y no debe volverse costumbre.** F5 compila en Debug y engancha el
> depurador: los dos rechazos del arnés existen porque medir así es el error más fácil de cometer
> en este ecosistema. Cuando vayas a medir, `Ctrl+F5` o la CLI.

### 5.7 WSL 2, instalado hoy y usado en la fase 08

```powershell
wsl --install
wsl --status          # versión 2, y la distribución por defecto
docker --version      # el runtime de contenedores, respondiendo desde WSL 2
```

Aquí van a correr SQL Server, los emuladores de Azure y las pruebas con Testcontainers. Se instala
ahora y no se vuelve a montar. **No se levanta nada todavía**: la fase 08 es la que lo necesita, y
adelantar el contenedor solo adelantaría el problema de mantenerlo.

### 5.8 Los otros dos IDE, sin condescendencia

**VS Code + C# Dev Kit** para quien vive en el terminal: depura, ejecuta pruebas y entiende
soluciones. Le falta el diseñador de WinForms y de WPF, que es justo lo que el Bloque C necesita,
así que si eliges este camino vas a abrir Visual Studio tres fases.

**Rider**, y el mapa para quien viene de IntelliJ, que es la mitad de los lectores:

| En IntelliJ | En Rider | Nota |
|---|---|---|
| `Ctrl+N` / `Ctrl+Shift+N` | igual | Navegar a tipo y a archivo |
| `Ctrl+Alt+B` ir a implementación | igual | Con interfaz de una sola implementación, salta directo |
| `Alt+Enter` acciones de contexto | igual | El mismo atajo y casi el mismo catálogo |
| `Shift+F10` ejecutar | igual | Y `Shift+F9` depurar |
| Maven/Gradle tool window | ventana **NuGet** + explorador de soluciones | No hay una vista del "ciclo de vida" porque no hay fases |
| `mvn dependency:tree` | `dotnet nuget why <paquete>` o el árbol del explorador | Responde la misma pregunta con otro nombre |
| Ejecutar pruebas del módulo | Ejecutar pruebas del proyecto | Misma idea, misma tecla |

Los tres corren en Windows, que es donde se toma el curso, y los tres compilan lo mismo porque el
build no es del IDE: es de MSBuild.

---

## 📏 6. Medición

**Hipótesis:** incluir las primeras iteraciones en la muestra infla la mediana de una operación
corta lo suficiente para **invertir el resultado** de una comparación entre dos alternativas
parejas.

**Condiciones:** SDK 10.0.401 · compilación Release · Windows 11 · la misma operación medida con 0
y con 10 iteraciones de calentamiento descartadas, 120 repeticiones · arnés propio, y
BenchmarkDotNet sobre la misma operación como tercer punto.

**Competidores:** las dos configuraciones del arnés, y **BenchmarkDotNet**, que es el estándar del
ecosistema y por tanto el competidor defendible. Si el arnés con descarte no queda cerca de
BenchmarkDotNet, el arnés está mal y hay que arreglarlo antes de seguir — para eso sirve esta
medición, que es la única del curso cuyo objeto es el propio instrumento.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 00
```

> 📝 **Sí, el comando es la herramienta que construyes en la sección 7.** Es la única fase del
> curso donde la medición se ejecuta *después* del miniproyecto, y no es un descuido de
> ordenamiento: el instrumento se construye en esta fase y la primera cosa que se mide con él es
> él mismo. En las veinticuatro siguientes, la sección 6 se puede correr con lo que la sección 5
> dejó.

**Resultado:** ⏳ pendiente de ejecución en tu máquina.

| Opción | Mediana | p95 | Dispersión | Asignado |
|---|---|---|---|---|
| Sin descartar calentamiento | ⏳ | ⏳ | ⏳ | ⏳ |
| Descartando 10 iteraciones | ⏳ | ⏳ | ⏳ | ⏳ |
| BenchmarkDotNet | ⏳ | ⏳ | ⏳ | ⏳ |

> ⚖️ **Veredicto** *(expectativa, todavía sin ejecutar — `formato-de-mediciones.md` §2.6)*. Se
> espera que la mediana sin descarte quede por encima y con una dispersión bastante mayor, porque
> las primeras iteraciones miden al JIT. Y se espera que el arnés con descarte quede cerca de
> BenchmarkDotNet: si no queda, la conclusión no es "BenchmarkDotNet es raro".
>
> **El umbral que tu ejecución tiene que determinar:** a partir de qué duración de operación deja
> de importar el calentamiento. Por debajo de ese tiempo, ninguna comparación del curso se publica
> sin descarte; por encima, el descarte da igual y gastar iteraciones en él es desperdicio.

**Prueba de fuego**

```powershell
dotnet run -c Debug --project src\modern\Cordillera.Bench.Cli -- --fase 00
# Debe fallar con: "Esta es una compilación Debug y el arnés no publica números de Debug."
```

Y la mentira que te va a contar la salida si miras el lugar equivocado: **los números de la
primera ejecución después de un `dotnet build` son más lentos que los de la segunda**, y no es tu
código — es el SDK escribiendo en caché, el antivirus mirando el ensamblado nuevo y el JIT en
nivel cero. Si comparas dos alternativas y mides cada una en su primera ejecución, mediste el
orden en que las escribiste.

---

## 🧱 7. Miniproyecto — `Cordillera.Bench.Cli`, la herramienta con la que se mide el curso

**El encargo**

Duván te escribe: *"Vi que armaste algo para medir. Necesito poder correrlo yo, desde la consola,
sin abrir tu solución y sin que me expliques nada — y necesito que lo que saque lo pueda pegar en
el documento sin acomodar columnas a mano. La última vez que alguien midió algo acá, el número
llegó en un correo sin decir en qué máquina era, y estuvimos dos semanas discutiendo un 15% que
resultó ser que él lo había corrido con el antivirus apagado."*

**Por qué duele**

La biblioteca de la sección 5 mide **tiempo**. Lo que Duván pide es la otra mitad: una herramienta
que cualquiera pueda ejecutar, que **reporte también memoria**, que declare el entorno sola, y que
emita la tabla en el formato exacto que `BENCHMARKS.md` espera. Y la memoria en .NET no se mide
con una línea: hay dos formas de contar asignaciones y **no dan lo mismo**, y elegir entre las dos
es una decisión que el enunciado no te va a tomar.

**Datos de entrada**

No hay archivo: las operaciones a medir las registra la propia herramienta. Tres, de costo
conocido de antemano, que es lo que te permite comprobar que la herramienta no miente:

| Operación | Qué debería pasar |
|---|---|
| `string.Concat` de dos literales, 120 veces | asignación mínima y constante |
| Construir 1.000 cadenas de 100 caracteres | asignación calculable a mano: ~200 bytes por cadena más la sobrecarga del objeto |
| Ordenar un arreglo de 50.000 `int` ya ordenado | trabajo real, asignación cercana a cero |

La segunda es la importante: **si tu herramienta no reporta una cifra del orden de la que puedes
calcular con lápiz, está mal y no importa qué tan bonita sea la tabla.**

**Criterios de aceptación**

1. `dotnet run -c Release --project src/modern/Cordillera.Bench.Cli -- --fase 00` imprime una tabla
   Markdown con una fila por operación y las columnas **Mediana · p95 · Dispersión · Asignado ·
   Pico**, y una línea de condiciones con SDK, configuración, sistema operativo, núcleos y
   repeticiones.
2. La salida **se pega en `BENCHMARKS.md` sin editar una sola columna**, y la entrada resultante
   pasa el checklist de `formato-de-mediciones.md` §6.
3. Para la operación de las 1.000 cadenas, la cifra de asignación reportada está **dentro del 20%
   del valor calculado a mano**, y tu entrega incluye el cálculo en dos líneas.
4. Acepta `--iterations`, `--warmup` y `--only <nombre>`, y **rechaza con un mensaje útil** lo que
   la biblioteca ya rechaza: menos de veinte repeticiones, Debug, depurador enganchado.
5. Corre sin abrir Visual Studio, y el `exit code` es distinto de cero cuando se rechaza algo — que
   es lo que permitirá meterlo en CI en la fase 20.
6. **Medición de cierre:** el número que reporte para la tercera operación es el que va en el
   mensaje del tag `mini-00`.

**Restricciones de estilo y alcance**

Esto es código nuevo: nullable activado, advertencias como errores, identificadores en inglés,
comentarios y mensajes en español. Vive en `src/modern/Cordillera.Bench.Cli` y **no toca
`Cordillera.Bench`**: si te descubres cambiando la biblioteca para que la herramienta sea más
fácil, para y pregúntate si lo que te falta es una propiedad pública o una decisión que estás
evitando.

Sin paquetes nuevos. Ni un parseador de argumentos de NuGet, ni una librería de tablas: con lo que
trae el SDK alcanza, y parte del ejercicio es comprobarlo.

**La trampa**

Vas a medir asignaciones con `GC.GetAllocatedBytesForCurrentThread()`, porque es lo primero que
aparece y porque es barato y preciso. Con estas tres operaciones va a funcionar perfecto.

Y en la fase 05 vas a medir una operación que reparte trabajo en el grupo de hilos, y la columna
va a reportar casi cero bytes con toda seriedad.

**La decisión que el enunciado no toma:** hay dos formas de contar asignaciones, y cada una es
correcta para una pregunta distinta. Elige una, **escribe en dos líneas por qué**, y deja dicho
qué pasa cuando la operación medida no se queda en un solo hilo. La solución de referencia elige
una de las dos y explica la otra sin descalificarla.

<details><summary>Pista 1 — el enfoque</summary>

La herramienta no calcula nada: envuelve. Toma la operación, pide a la biblioteca el resultado de
tiempo, y alrededor de esa llamada toma dos lecturas de memoria —antes y después— para restarlas.
El pico es una tercera lectura, y no es un delta.

</details>

<details><summary>Pista 2 — la herramienta</summary>

Mira la clase `GC` y compara la documentación de `GetAllocatedBytesForCurrentThread`,
`GetTotalAllocatedBytes(bool precise)` y `GetTotalMemory(bool forceFullCollection)`. Las tres
responden preguntas distintas, y el parámetro booleano de las dos últimas es justo lo que tienes
que decidir:
`https://learn.microsoft.com/dotnet/api/system.gc`

Para los argumentos, `args` y un `switch` de expresión alcanzan. Para la tabla, cadenas
interpoladas con formato de alineación (`{valor,10:F2}`).

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```csharp
internal static int Main(string[] args);

private sealed record BenchOperation(string Name, Action Run);

private static IReadOnlyList<BenchOperation> Operations(string? only);

// Devuelve el resultado de tiempo de la biblioteca más las dos cifras de memoria.
private static MeasuredOperation Measure(BenchOperation operation, BenchOptions options);

// La tabla Markdown completa, con su línea de condiciones. Nada de imprimir por el camino.
private static string ToMarkdown(IReadOnlyList<MeasuredOperation> results, MachineProfile machine);
```

</details>

**Cómo se entrega**

```powershell
dotnet test src\Cordillera.slnx -c Release
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 00
```

```bash
git tag -a mini-00 -m "Mini F0: arnés de consola con memoria y salida en formato BENCHMARKS · ordenar 50.000 int: mediana <X> ms, p95 <Y> ms, <Z> KB asignados"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Instala dos SDK de la línea 10 y demuestra con `dotnet --list-sdks` y `dotnet --version` que
   `global.json` decide cuál responde. Cambia `rollForward` a `disable` y explica en una línea qué
   se rompió.
2. Crea un `.csproj` nuevo dentro de `src/modern/` que **no declare** `TargetFramework` ni
   `Nullable`, compílalo, y muestra con `dotnet build -v:d` de dónde salieron esas propiedades.
3. Escribe una prueba que demuestre que `BenchStats.Median` de una muestra par promedia los dos
   centrales, y otra que falle si alguien la cambia por "el elemento de la derecha".
4. Añade un paquete cualquiera a `Cordillera.Bench.Tests` **con** su atributo `Version` y explica
   el error de compilación que produce Central Package Management.
5. Corre `dotnet test` y el Explorador de pruebas de Visual Studio sobre la misma solución y
   confirma que descubren exactamente las mismas pruebas. Di dónde se leería primero un fallo.
6. Documenta en `BENCHMARKS.md` una entrada ⏳ nueva para una operación tuya, respetando el formato
   completo. Que la revise el checklist de `formato-de-mediciones.md` §6.

**🟡 Intermedio (7–14)**

7. Convierte `Cordillera.slnx` a `.sln` con `dotnet sln migrate` (o al revés) y compara los dos
   archivos. Escribe tres líneas sobre qué información desaparece y qué información aparece.
8. Haz que `RestoreLockedMode` esté activo también en local y provoca el fallo: cambia una versión
   en `Directory.Packages.props` sin actualizar el lockfile. Explica el mensaje.
9. Agrega una segunda fuente de NuGet ficticia al `nuget.config` **sin** `packageSourceMapping` y
   describe qué riesgo concreto acabas de introducir.
10. Escribe un objetivo de MSBuild en `Directory.Build.props` que imprima el SDK y la
    configuración al compilar. Documenta en qué se parece y en qué no a un plugin de Maven
    enganchado a una fase.
11. Usa un punto de interrupción **condicional** y un **punto de traza** para descubrir en qué
    iteración exacta `BenchRunner.Run` deja de calentar y empieza a medir, sin agregar un solo
    `Console.WriteLine`.
12. Mide con el arnés el costo de `string.Concat` contra interpolación sobre nombres de tabla
    (`"VENTAS_" + año`). Reporta dispersión y di si tu resultado sostiene una diferencia o es un
    empate.
13. Añade a `MachineProfile` una propiedad que diga si el equipo está con batería o enchufado, y
    argumenta en dos líneas si eso pertenece a las condiciones de una medición.
14. Instala el C# Dev Kit en VS Code y ejecuta build, pruebas y depuración de esta fase sin abrir
    Visual Studio. Anota las dos cosas que echaste de menos.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Te entregan un arnés donde `Percentile` usa `(int)(p/100 * n)` sin
    `Math.Ceiling`. Escribe la prueba que lo delata, calcula con qué tamaño de muestra el error
    desaparece, y explica por qué nadie lo habría notado mirando una tabla.
16. **Diagnóstico.** Una medición en tu máquina da 40 ms de mediana y 400 ms de p95, con
    dispersión de 0,9. Enumera cuatro causas posibles en orden de probabilidad y di cómo
    descartarías cada una con lo que tienes en esta fase.
17. **Medición.** Compara el tiempo de `dotnet build` en frío y en caliente sobre
    `Cordillera.slnx`, con y sin `dotnet nuget locals all --clear`. Publica la tabla con su
    veredicto **y su umbral**.
18. Haz que el arnés acepte una operación que devuelva un valor y no solo una `Action`, sin
    romper ninguna prueba existente y sin agregar una segunda sobrecarga de `Run` por cada
    combinación. Justifica la firma que elegiste.
19. **Medición.** Mide la misma operación con `AnalysisLevel` en `latest-all` y sin analizadores.
    Responde con números si activar el análisis completo cuesta tiempo de compilación medible, y
    cuánto.
20. **Decisión — ¿se migra, se envuelve o se deja quieto?** El build de SIGE hoy es un `.bat` de
    2018 que llama a `msbuild` con nueve parámetros y copia archivos con `xcopy`. Nadie lo entiende
    completo y funciona todos los días. Decide, y sostén la decisión con el costo de las otras dos.
21. **Decisión — ¿se migra, se envuelve o se deja quieto?** Duván tiene Visual Studio 2015
    instalado porque la solución de SIGE abre ahí sin pelear. Con las cuatro cargas de trabajo de
    esta fase, VS 2026 abre las dos soluciones. Decide qué hacer con el VS 2015 de su máquina, y
    di qué se rompe si te equivocas.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Escribe una operación cuyo tiempo medido por el arnés sea **sistemáticamente
    menor** que el real, sin modificar el arnés y sin hacer trampa evidente. Explica el mecanismo y
    propón la defensa mínima que habría que agregarle. *(Pista: el JIT tiene permiso para eliminar
    trabajo cuyo resultado nadie usa.)*
23. **Adversarial.** Haz que `dotnet build` pase en tu máquina y falle en una recién clonada, sin
    tocar el código fuente: solo configuración, caché o entorno. Documéntalo como un informe de
    incidente y cierra con la línea de defensa que lo habría impedido.
24. **Medición y decisión.** Implementa la medición de la sección 6 completa, incluido
    BenchmarkDotNet como tercer punto, y determina **el umbral de duración por debajo del cual el
    calentamiento importa**. Con ese número, decide si el arnés del curso debería descartar
    calentamiento siempre o solo por debajo del umbral, y qué le cuesta cada opción.
25. **Defiende una decisión.** Clara pregunta por qué el equipo debería fijar el SDK con
    `global.json` si *"hasta ahora nunca hizo falta"*. Escribe media página en su lenguaje —riesgo
    y costo, no ingeniería— citando un número que hayas medido en esta fase.

**🔥 Opcionales**

- Emite la tabla del arnés también como CSV y mide si serializar la salida aparece en la medición.
- Publica `Cordillera.Bench.Cli` como herramienta global de .NET (`dotnet tool install -g`) y
  escribe qué se gana y qué se pierde frente a `dotnet run --project`.
- Investiga `dotnet publish -p:PublishAot=true` sobre la herramienta, anota los dos errores que
  aparecen, y **no los arregles**: guárdalos para la fase 20, que es donde AOT se decide con
  números.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://learn.microsoft.com/dotnet/core/tools/global-json` — `global.json` y las opciones de
  `rollForward`. Fija la versión en el selector de la página: por omisión sirve la más reciente.
- `https://learn.microsoft.com/dotnet/core/project-sdk/overview` — el formato SDK del `.csproj`, y
  qué se hereda de dónde.
- `https://learn.microsoft.com/nuget/consume-packages/central-package-management` — Central Package
  Management y el fijado de transitivas.
- `https://learn.microsoft.com/nuget/consume-packages/package-references-in-project-files#locking-dependencies`
  — `packages.lock.json` y `--locked-mode`.
- `https://learn.microsoft.com/nuget/consume-packages/package-source-mapping` — asignación de
  fuentes, que es la defensa contra el paquete homónimo.
- `https://learn.microsoft.com/dotnet/api/system.gc` — las tres formas de preguntarle al
  recolector cuánto se asignó. Es la lectura obligada del miniproyecto.
- `https://learn.microsoft.com/dotnet/core/tools/dotnet-test` — `dotnet test`, y cómo se filtra.
- `https://xunit.net/docs/getting-started/v3/getting-started` — xUnit v3. **Ojo:** buena parte del
  material que vas a encontrar sobre xUnit describe la v2, donde el proyecto de pruebas no era
  ejecutable y los paquetes se llamaban distinto.
- `https://learn.microsoft.com/visualstudio/debugger/using-breakpoints` — condiciones, filtros y
  puntos de traza.
- `https://learn.microsoft.com/windows/wsl/install` — WSL 2.

**Notas de versión y cambios de comportamiento**

- `https://github.com/dotnet/core/blob/main/release-notes/10.0/README.md` — de dónde salió el
  10.0.401 que este curso fija.
- `https://learn.microsoft.com/dotnet/core/compatibility/sdk/10.0/dotnet-new-sln-slnx-default` —
  el cambio que hace que `dotnet new sln` genere SLNX. Es el tipo de nota que explica por qué el
  tutorial que encontraste no coincide con lo que te salió.

**Video / apoyo**

- El canal de .NET en YouTube (`https://www.youtube.com/@dotnet`) tiene material de la salida de
  .NET 10 sobre el SDK y las herramientas. No se cita ningún video en particular: los
  identificadores cambian y no se inventan aquí.

> ⚠️ URLs, títulos y contenidos pueden haber cambiado; verifícalos. Y una advertencia propia de
> este ecosistema: **mucho de lo que vas a encontrar sobre configuración, hosting y acceso a datos
> describe .NET Framework y no .NET moderno**. En este curso esa confusión es peligrosa de verdad,
> porque el sistema heredado **es** .NET Framework y el material viejo parece aplicar.

**Orden de lectura sugerido:** antes de escribir código, `global.json` y el overview del SDK de
proyecto. Durante, la documentación de Central Package Management y de `System.GC` mientras haces
el miniproyecto. Después, la nota de cambio de SLNX y los puntos de interrupción condicionales —
son los dos que vas a agradecer en la fase 12.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Queda un repositorio con el SDK fijado, dos subárboles con reglas opuestas y la frontera entre
generaciones hecha física, paquetes con versión reproducible, y **el arnés funcionando con su
suite de pruebas**. Queda también un archivo, `BENCHMARKS.md`, que todavía no tiene un solo número
y que al final del curso va a tener veinticuatro entradas con sus condiciones.

La fase 01 es el paso natural porque a partir de aquí todo lo que se escriba hay que poder medirlo
y probarlo, y porque el modelo de dominio que nace allí —`Title`, `Edition`, `Isbn`, `Money`— es lo
que veintitrés fases van a arrastrar. La primera pregunta que responde es de las que solo se
pueden responder con el arnés en la mano: si `Isbn` debería ser una clase, un `record` o un
`record struct`, y **cuánto cuesta cada respuesta** sobre un millón de ediciones.

> **La señal de que quedó bien:** *"Puedo borrar `bin`, `obj` y la caché de NuGet, clonar en una
> máquina limpia, y obtener exactamente el mismo build — y si alguien me manda un número, sé qué
> preguntarle antes de creerlo."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el miniproyecto
> corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-00 -m "F0 cerrada:
> - SDK fijado con global.json y comprobado con dotnet --version
> - Cordillera.slnx compila en Release sin advertencias; legacy/ con su props y su editorconfig
> - restauración reproducible: packages.lock.json versionado y --locked-mode pasando
> - arnés con pruebas: el p95 de veinte muestras es la muestra 19
> - WSL 2 y runtime de contenedores verificados, sin usar
> - BENCHMARKS.md e INSTINTOS.md creados, sin un solo número"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 00: …`), los de ejercicio su número
> (`fase 00 ej12: …`) y el miniproyecto el suyo (`fase 00 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `mini-00`, **con el número de su medición en el mensaje**. La
> convención completa está en [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
>
> Esta fase no cobra ninguna deuda —es la primera— pero **deja una plantada**: el arnés no aísla el
> recolector, y la fase 06 va a mostrar con `git diff fase-00 fase-06` qué costó medir tiempo sin
> mirar las asignaciones.

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura.*

- **`INSTINTOS.md`** — entrada agregada: *"El IDE me resuelve el proyecto"*, en la familia del
  ecosistema. Falta decidir si la sección de arquitectura debería abrirse con un reflejo de esta
  fase; hoy abre con los de la 10.
- **`BENCHMARKS.md`** — entrada ⏳ agregada: *F00 · El costo del calentamiento*. Al ejecutarla hay
  que rellenar además el umbral del veredicto, que es el dato que la fase 06 va a citar.
- **Decisión que sube a la propuesta:** la estructura de `src/` quedó con `legacy/` y `modern/`
  como subárboles con props propios, no con un único `projects/`. Ya está reflejada en
  `congelamiento-de-nombres.md` §3 y en `00-convencion-de-git-y-tags.md`.
- **Para la fase 04:** el ciclo de vida de xUnit se prometió aquí y se debe allí — instancia nueva
  por prueba, `IClassFixture`, `IAsyncLifetime` frente a `@BeforeEach`/`@BeforeAll`. Si la 04 no lo
  trae, esta fase queda con un bucle abierto.
- **Para la fase 05:** la trampa del miniproyecto —asignaciones por hilo contra asignaciones del
  proceso— tiene que **cobrarse** explícitamente cuando aparezca la primera operación que reparte
  trabajo en el grupo de hilos. Vale un ejercicio de diagnóstico allí.
- **Para la fase 20:** los dos errores de AOT del ejercicio 🔥 se guardaron a propósito. La 20 los
  necesita como caso de entrada y debería citarlos.
- **Riesgo de envejecimiento:** el número de versión de Visual Studio queda desactualizado en
  semanas, porque Community solo se soporta en la última del canal Stable. La fase dice el criterio
  —las cuatro cargas de trabajo— además del número, que es lo que no envejece. Revisar en cada
  edición del curso.
