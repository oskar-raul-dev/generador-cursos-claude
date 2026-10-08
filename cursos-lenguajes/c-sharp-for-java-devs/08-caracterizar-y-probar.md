# 🔎 Fase 08 ⭐ — Caracterizar lo que no puedes leer

> C# para desarrolladores Java senior · Fase 08 de 24 · Bloque B ⭐ — el sistema heredado y la frontera
> Depende de: 07 · Habilita: 09
> Estilo de esta fase: **mixto 🧬** — el código de SIGE se escribe en .NET Framework 4.8 y estilo 2017;
> las pruebas, en .NET 10 con xUnit v3 y Testcontainers. **Nunca en el mismo archivo**, y cada cruce va
> marcado.
> Proyecto que avanza: **SIGE**. Entran catálogo y facturación, escritos **mientras se caracterizan**, y
> queda la red de pruebas sobre la que el resto del bloque va a trabajar.

---

## 🎯 1. Propósito

Poner la red antes del trapecio. Al terminar esta fase vas a poder cambiar un procedimiento almacenado
de setecientas líneas que nunca leíste completo y **saber si lo rompiste**, que es la única condición
bajo la cual las fases 09, 10 y 11 son posibles.

Y vas a hacer algo que ningún temario de lenguaje incluye: **caracterizar código que no entiendes sin
tocarlo**. No probar lo que debería hacer —eso no lo sabe nadie— sino fijar lo que **hace hoy**, y
después usar esa red para descubrir la diferencia entre las dos cosas. En el camino vas a encontrar la
regla que la editorial cree que tiene y no aplica, y no la vas a encontrar leyendo.

> 🧭 **La regla de la fase:** *primero la red, después el trapecio.* Nada se refactoriza —nada— hasta
> que exista una prueba que diga si se rompió. Y la prueba no se escribe contra la especificación:
> se escribe contra **el comportamiento observado**, incluido el que está mal.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Catálogo y facturación están implementados en `src/legacy/Sige.Database` —cinco procedimientos— y
      **cada uno tiene su prueba de caracterización escrita el mismo día**.
- [ ] **`SP_EXIST_ALMACEN` está caracterizado con el total del almacén de Lima** —4.300 movimientos,
      huérfanos incluidos—. No es opcional: es la foto contra la que la fase 09 comprueba que su borde
      cuadra con el sistema viejo, y sin ella ese criterio no tiene referencia.
- [ ] `SP_LIQREGAL_CALC` es **determinista bajo prueba** sin haber modificado el procedimiento, y sabes
      explicar cómo se logró y qué se sacrificó.
- [ ] Existe un *golden master* de la liquidación de un trimestre completo, y **falla** si alguien
      cambia el cálculo — probado rompiéndolo a propósito.
- [ ] La suite usa **Testcontainers con SQL Server 2025**, con la base poblada por el generador de la
      fase 07 con su semilla fija.
- [ ] Sabes decir qué es **cobertura útil** sobre código heredado, y por qué no es el porcentaje —con
      el número de la sección 6 al lado.
- [ ] **Está encontrada, documentada y probada la regla que no se aplica**: el hallazgo del
      miniproyecto, con su impacto en pesos.
- [ ] La medición de la sección 6 está escrita con su comando, y la entrada quedó en `BENCHMARKS.md`.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Refactorizar nada.** Es la regla de la fase. Ni el `catch` vacío del log, ni el filtro de `BORRADO`
  que falta en una rama, ni la regla de `BASELIQUI` que está mal. **Se documenta, se prueba, y se deja
  como está** — lo que se haga con eso es de las fases 09 y 10.
- **El ciclo de vida de xUnit** —instancia por prueba, `[Theory]`, `IDisposable`— ya está en la fase 04
  y no se repite. Lo que esta fase agrega es lo que la 04 no tenía: contexto compartido entre clases,
  contenedores, y cobertura.
- **El borde 🧬 tipado** —mapear `VLRUNIT` a `UnitPrice`— → fase 09. Aquí las pruebas leen `DataSet` y
  `DataTable` a propósito: caracterizar exige comparar **lo que el sistema devuelve hoy**, no una
  versión mejorada de eso.
- **Pruebas de interfaz** → Bloque C.
- **Rendimiento del acceso a datos** → fase 09. Esta fase mide **la suite**, no el sistema.

---

## 🧠 4. Concepto mínimo

### Qué es una prueba de caracterización, y en qué se diferencia de todo lo que ya sabes

Una prueba unitaria normal expresa una intención: *"el total debe ser la suma de las líneas menos el
descuento"*. La escribes porque sabes qué debería pasar.

Una **prueba de caracterización** expresa un hecho: *"hoy, con estos datos, esto devuelve 4.317.850,00"*.
No dice que ese número sea correcto. Dice que es **el que hay**, y que si cambia, alguien lo cambió.

Ese giro es todo el contenido de la fase, y tiene tres consecuencias que incomodan:

**La primera: se prueban también los errores.** Si `SP_CATALOGO_VIGENTE` trae 340 ediciones borradas en
una de sus ramas, la prueba de caracterización **fija las 340**. No se arregla: se documenta que está
así y se deja constancia de que el día que alguien lo arregle, la prueba va a fallar — y ese fallo es la
señal correcta, no un problema.

**La segunda: el valor esperado no se calcula, se observa.** No se escribe `Assert.Equal(4_317_850m, …)`
porque alguien hizo la cuenta: se ejecuta el procedimiento, se mira la salida, **se verifica que sea
plausible**, y se guarda. La verificación de plausibilidad es el único trabajo intelectual del proceso y
es donde se encuentran los hallazgos.

**La tercera, y es la que hace difícil la fase: hay que hacer determinista lo que no lo es.** Un
procedimiento que llama a `GETDATE()` devuelve algo distinto cada día, así que su salida no se puede
guardar. Y no se puede modificar el procedimiento —en una empresa real no te dejan tocarlo antes de
tener la red puesta—, así que **el determinismo tiene que venir de fuera**.

> 🧠 **El modelo mental:** una prueba de caracterización es **una fotografía con fecha**, no un
> contrato. Sirve para una sola cosa y la hace muy bien: decirte que algo cambió. No te dice si el
> cambio es bueno; eso lo decides tú mirando la foto vieja y la nueva.

### Cobertura útil sobre código heredado, que no es el porcentaje

El porcentaje de cobertura sobre código heredado es una medida casi inútil, y conviene decir por qué
con precisión en vez de repetir el eslogan.

Un procedimiento de setecientas líneas con cursores y `IF` anidados puede alcanzar un 70% de cobertura
de línea **con dos casos de prueba**, porque el camino feliz atraviesa casi todo el archivo. Y ese 70%
no protege nada: las decisiones están en las ramas, y las ramas son las que no se tocaron. Del otro
lado, llegar al 95% exigiría construir datos para caminos que en producción no ocurren desde 2019, y ese
esfuerzo compra muy poco.

**La cobertura útil se mide en decisiones cubiertas, no en líneas ejecutadas**, y en este curso son
tres preguntas concretas:

1. **¿Está cubierta cada rama que cambia un número que alguien factura?** La rama de `BASELIQUI = 'N'`
   decide cuánto se le paga a un autor. La rama del `ELSE` de `SP_CATALOGO_VIGENTE` decide qué ve un
   socio comercial. Esas dos importan; el `IF @TASA IS NULL SET @TASA = 1` importa mucho menos.
2. **¿Está cubierto cada cruce con los datos sucios?** Un huérfano, un `BORRADO = 'S'`, una fecha
   `'00000000'`. Son los tres casos que una migración ingenua rompe.
3. **¿Está cubierto el camino que alguien va a tocar la semana que viene?** Si la fase 10 va a cortar
   existencias, la red tiene que estar ahí y no en facturación.

La medición de la sección 6 pone números a esto: **cobertura de línea contra cobertura de rama** sobre
el mismo procedimiento, para que la diferencia entre las dos deje de ser una opinión.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**Primera, y es la cara: reescribir antes de entender.**

El reflejo no se presenta como "voy a reescribir sin entender". Se presenta así:

> *"Este procedimiento es ilegible. Voy a leer qué hace, escribirlo limpio en C# con pruebas de
> verdad, y comparar los resultados."*

Suena responsable. Tiene pruebas. Y es el camino directo al incendio, por una razón que se ve en cuanto
se nombra: **"voy a leer qué hace" es el paso que no funciona.** Setecientas líneas de T-SQL con dos
cursores anidados, `IF` de cuatro niveles y SQL dinámico no se leen con exactitud suficiente; se leen
con un 90% de exactitud, y el 10% restante son las reglas que la editorial aplica de verdad y nadie
recuerda haber escrito.

```csharp
// ❌ El orden equivocado, y el más natural: primero la versión nueva, después comparar.
[Fact]
public void La_liquidacion_calcula_el_porcentaje_sobre_el_neto()
{
    // Escrita contra lo que el CONTRATO dice que debería pasar.
    var settlement = new SettlementCalculator().Calculate(contract, sales);

    Assert.Equal(new Money(4_317_850m), settlement.Royalty);
}
```

Esa prueba pasa, la implementación nueva es correcta **según el contrato**, y en producción los autores
de traducción empiezan a recibir un 30% menos de lo que venían recibiendo — porque el sistema viejo les
liquidaba sobre precio de lista por un error de 2017, y nueve años de liquidaciones se hicieron así.

```csharp
// ✅ El orden correcto: primero fijar lo que HACE, con el sistema viejo, tal cual.
[Fact]
public async Task La_liquidacion_del_2026T1_produce_los_mismos_numeros_de_siempre()
{
    // No calcula nada. Ejecuta el procedimiento heredado y compara contra la foto.
    DataTable actual = await RunLegacySettlementAsync("202601");

    await Verify(actual);   // el golden master
}
```

**Por qué falla el reflejo:** porque confunde *correcto* con *igual*, y en una migración las dos cosas
son decisiones distintas que toman personas distintas. Descubrir que el sistema liquida mal es un
hallazgo valioso — **y corregirlo es una decisión del negocio con efectos retroactivos y posiblemente
legales**, no un arreglo de programación. La presidenta es abogada. Esa conversación se tiene con
números y con la foto vieja en la mano.

**Segunda: traducir JUnit línea por línea.**

Esto ya se trató en la fase 04 con el ciclo de vida, y aquí aparece su versión de integración:

```csharp
// ❌ La traducción del hábito de @BeforeAll estático para levantar el contenedor una vez.
public class SettlementTests
{
    private static readonly MsSqlContainer Container = new MsSqlBuilder().Build();

    static SettlementTests() => Container.StartAsync().GetAwaiter().GetResult();
    //                                                 ^^^^^^^^^^^^^^^^^^^^^^^^
    //                                                 y ahí volvió el .Result que la F05 prohibió
}
```

```csharp
// ✅ El contexto compartido explícito: un tipo aparte, con su ciclo de vida asincrónico, declarado
//    en la firma de la clase. Si dos clases comparten el contenedor, se ve.
public sealed class SigeDatabaseFixture : IAsyncLifetime
{
    public MsSqlContainer Container { get; } = new MsSqlBuilder()
        .WithImage("mcr.microsoft.com/mssql/server:2025-latest")
        .Build();

    public async ValueTask InitializeAsync()
    {
        await Container.StartAsync();
        await ApplySchemaAsync();
        await GenerateDataAsync(seed: 19_970_417);
    }

    public ValueTask DisposeAsync() => Container.DisposeAsync();
}

[CollectionDefinition(nameof(SigeDatabaseCollection))]
public sealed class SigeDatabaseCollection : ICollectionFixture<SigeDatabaseFixture>;
```

**Dónde se rompe el paralelo:** en Java, `@Testcontainers` con `@Container static` hace esto en dos
anotaciones, y la biblioteca se encarga del ciclo de vida. Aquí el ciclo de vida es **tuyo**, con
`IAsyncLifetime`, y el compartir entre clases se declara con `[Collection]`. Es más ceremonia y a
cambio es visible: leyendo la firma de una clase de prueba sabes si comparte estado con otras.

### 🩻 Esto sí funciona igual — y Testcontainers es la sorpresa agradable

Toda tu disciplina de pruebas vale aquí íntegra: qué vale la pena probar, cómo diseñar para poder
probar, cuándo un doble es la herramienta y cuándo es una trampa, por qué una prueba que falla de forma
intermitente es peor que no tenerla. El curso no va a explicar nada de eso.

Y hay una que se transfiere **literalmente**: **Testcontainers es la misma biblioteca**. Si en tu
trabajo levantabas un PostgreSQL efímero para las pruebas de integración con `@Container`, aquí
levantas un SQL Server con `MsSqlBuilder` y el concepto es idéntico, el ciclo de vida es equivalente y
el compromiso —pruebas más lentas, mucho más realistas— es el mismo. No hay nada que desaprender.

También se transfiere el criterio de **contenedor contra doble**, que es la decisión de fondo de esta
fase: un doble es rápido y prueba tu código; un contenedor es lento y prueba **tu código contra el
motor**. Con un esquema hostil —sin llaves foráneas, con `char(8)` por fecha, con una intercalación que
se come tildes— la mitad de los defectos interesantes **están en el motor y en los datos**, no en el
código. Ahí el doble no sirve, y esa es la conclusión que la medición de la sección 6 respalda.

### 📖 Diccionario de traducción — pruebas de integración

> 📝 La parte del ciclo de vida —`@BeforeEach` contra el constructor, `[Theory]` contra
> `@ParameterizedTest`— está en el 📖 de la **fase 04** y no se repite. Esto es lo que allí no cabía.

| Java | C# / .NET | Dónde se rompe el paralelo |
|---|---|---|
| Testcontainers (`@Container`) | **Testcontainers para .NET** (`MsSqlBuilder`) | **Es la misma biblioteca.** El ciclo de vida es tuyo: `IAsyncLifetime` en vez de la anotación |
| `@BeforeAll static` | `IClassFixture<T>` | Estado compartido dentro de **una** clase, inyectado por constructor |
| singleton de contenedor entre clases | `ICollectionFixture<T>` + `[Collection]` | Compartir entre clases **se declara en la firma** de cada clase que participa |
| JaCoCo | **coverlet** (`dotnet test --collect:"XPlat Code Coverage"`) | Integrado en el SDK; el informe se genera con `reportgenerator` |
| cobertura de rama en JaCoCo | `/p:CoverletOutputFormat=cobertura` + rama | Hay que pedirla: por omisión el informe que todo el mundo mira es de línea |
| ApprovalTests | **Verify** | Mismo patrón: la salida se guarda en un archivo `.verified.txt` que se versiona y se revisa en el diff |
| `assertThat(...).usingRecursiveComparison()` | comparación sobre `DataTable`, a mano | No hay equivalente directo para `DataSet`, y en esta fase se compara a mano a propósito |
| `@Sql` de Spring Test | script ejecutado en el fixture | Sin integración con el framework: es código que tú llamas |
| `@Transactional` con rollback por prueba | transacción a mano, o base por clase | **No existe el rollback automático.** Es la diferencia más costosa de esta fase |
| perfiles de Spring para la base de prueba | cadena de conexión del contenedor, inyectada | El contenedor da el puerto en tiempo de ejecución: la cadena se construye, no se configura |

> ⚠️ **La fila de `@Transactional` es la que más duele y conviene mirarla de frente.** En Spring Test,
> anotar una prueba hace que todo lo que escriba se deshaga al terminar, y eso permite compartir una
> base entre cientos de pruebas sin que se pisen. En .NET **no hay equivalente**, y con un esquema sin
> llaves foráneas envolver cada prueba en una transacción propia es posible pero frágil —los
> procedimientos abren sus propias transacciones, y anidarlas cambia su comportamiento—. Las dos
> salidas honestas son **una base por clase de prueba** o **datos disjuntos por prueba**, y la
> medición de la sección 6 dice lo que cuesta cada una.

> 📝 **Nota de ecosistema.** Testcontainers para .NET es un puerto de la biblioteca de Java y la deuda
> está reconocida por sus autores; llegó unos años después y hoy es equivalente en lo esencial. Eso
> explica una asimetría del ecosistema que conviene saber: **en .NET la cultura de pruebas de
> integración con contenedores es más joven que en Java**, así que vas a encontrar mucho material que
> prueba acceso a datos con dobles sobre un repositorio inventado. Con un esquema como el de SIGE, ese
> material no aplica: el defecto está en el motor.

---

## 💻 5. Código mínimo con comentarios

### 5.1 El contenedor y la base, una vez para toda la suite

```csharp
// src/modern/Sige.Characterization.Tests/SigeDatabaseFixture.cs
// 🧬 BORDE DE GENERACIONES. Este proyecto es .NET 10 y lo que prueba es .NET Framework 4.8 con
//    un esquema de 1997. Las pruebas son código nuevo y se escriben en estilo nuevo; lo que
//    ejecutan es heredado y no se toca. El cruce vive aquí y en `LegacyProcedure`.
using Testcontainers.MsSql;

namespace Sige.Characterization.Tests;

/// <summary>
/// Levanta SQL Server, aplica el esquema de `src/legacy/Sige.Database` y lo puebla con el
/// generador de la fase 07 **con su semilla fija**. Una vez para toda la suite.
/// </summary>
/// <remarks>
/// La semilla es 19.970.417 y no se cambia: el <i>golden master</i> de esta fase compara contra
/// los números que salen de **esos** datos. Cambiar la semilla invalida todas las fotos, y eso es
/// la deuda 💸 declarada de la fase.
/// </remarks>
public sealed class SigeDatabaseFixture : IAsyncLifetime
{
    public const int Seed = 19_970_417;

    private readonly MsSqlContainer _container = new MsSqlBuilder()
        .WithImage("mcr.microsoft.com/mssql/server:2025-latest")
        // En 2025 los valores de MSSQL_PID cambiaron: la edición de desarrollo ya no es
        // `Developer` sino `EnterpriseDeveloper`. Es el detalle que rompe los `docker run`
        // copiados de tutoriales de 2019.
        .WithEnvironment("MSSQL_PID", "EnterpriseDeveloper")
        .Build();

    public string ConnectionString => _container.GetConnectionString();

    public async ValueTask InitializeAsync()
    {
        await _container.StartAsync();

        // El esquema sale de los mismos archivos que la fase 07 escribió, sin una copia
        // paralela: si el esquema cambia, estas pruebas lo ven.
        await ExecuteScriptsAsync("../../../../legacy/Sige.Database/esquema");
        await ExecuteScriptsAsync("../../../../legacy/Sige.Database/procedimientos");
        await SigeDataGenerator.PopulateAsync(ConnectionString, Seed);
    }

    public async ValueTask DisposeAsync() => await _container.DisposeAsync();
}

/// <summary>
/// La colección que comparte el contenedor entre clases de prueba. Levantar SQL Server cuesta
/// segundos, así que compartirlo es obligatorio — y **declararlo es el precio**: cualquier clase
/// que lleve `[Collection(nameof(SigeDatabaseCollection))]` renuncia al paralelismo con las demás
/// de la colección, y eso se ve en su firma.
/// </summary>
[CollectionDefinition(nameof(SigeDatabaseCollection))]
public sealed class SigeDatabaseCollection : ICollectionFixture<SigeDatabaseFixture>;
```

**Detalles con intención**

- **El esquema se aplica desde los archivos de `src/legacy/`**, no desde una copia. Una segunda copia
  del esquema en el proyecto de pruebas sería la forma más rápida de que las pruebas dejen de probar el
  sistema real.
- **`IAsyncLifetime` con `ValueTask`** es la forma de xUnit v3; en v2 era `Task` y la interfaz vivía en
  otro sitio. Es el tipo de detalle por el que el material de v2 no compila aquí.
- **La cadena de conexión se construye, no se configura.** El contenedor asigna un puerto libre en
  tiempo de ejecución, así que no hay `appsettings` que apunte a él. Esa diferencia con un perfil de
  Spring es pequeña y cambia cómo se escribe el montaje.

### 5.2 Cómo se hace determinista lo que llama a `GETDATE()`

Este es el problema central de la fase, y tiene tres soluciones posibles. **Dos son malas y hay que
saber por qué**, porque las dos son lo primero que se le ocurre a cualquiera.

```sql
-- ❌ Solución 1: modificar el procedimiento para que reciba la fecha.
--    Es la correcta a largo plazo y está PROHIBIDA aquí: modificar el
--    procedimiento antes de tener la red es exactamente lo que la fase evita.
--    Y en una empresa real no te dan permiso, con razón.
ALTER PROCEDURE SP_LIQREGAL_CALC @PERIODO char(6), @FECHA char(8) AS …
```

```csharp
// ❌ Solución 2: excluir de la comparación las columnas que dependen de la fecha.
//    Funciona, es tentador, y deja sin cubrir precisamente la columna que la
//    impugnación de la traductora puso en duda: FECLIQUI.
Assert.Equal(expected.Rows.Count, actual.Rows.Count);
// … y comparar solo VLRREGAL, ignorando FECLIQUI
```

```csharp
// ✅ Solución 3: hacer determinista el ENTORNO, no el código.
//    El procedimiento llama a GETDATE(), que devuelve la fecha del servidor de
//    base de datos. El servidor es un contenedor que nosotros levantamos.
public sealed class FrozenClockFixture : IAsyncLifetime
{
    // El 15 de abril de 2026, un miércoles, a media mañana. Fijo y arbitrario:
    // lo importante es que no cambie nunca.
    public static readonly DateTimeOffset Frozen =
        new(2026, 4, 15, 10, 30, 0, TimeSpan.FromHours(-5));

    public async ValueTask InitializeAsync()
    {
        // El contenedor corre con su reloj congelado en esa fecha. GETDATE() dentro
        // del procedimiento devuelve eso, sin que el procedimiento sepa nada.
        await _container.ExecAsync(["date", "-s", Frozen.ToString("yyyy-MM-dd HH:mm:ss")]);
    }
}
```

**Detalles con intención**

- **La solución 3 es la que un equipo real puede aplicar sin permiso de nadie**, y eso es lo que la hace
  correcta para esta fase: el contenedor es tuyo.
- **Tiene un costo y hay que declararlo:** congelar el reloj del contenedor hace que **todas** las
  pruebas de la colección compartan esa fecha, así que una prueba que dependa de "hoy" y otra de "el
  mes pasado" tienen que construir sus datos alrededor de la fecha congelada. Es menos cómodo que
  inyectar la fecha, y es el precio de no tocar el procedimiento.
- **Y hay una cuarta fuente de no determinismo que el reloj no arregla:** el `SELECT TOP 1 … ORDER BY
  FECTASA DESC` sin desempate. Si dos filas de `TASACAMB` tienen la misma fecha, el motor puede
  devolver cualquiera de las dos, y el resultado cambia entre corridas sin que nada cambie. El
  generador de la fase 07 garantiza una sola tasa por moneda, y **por eso lo garantiza**.

> 🧭 **La regla que fija esta fase:** *el determinismo se consigue controlando el entorno, no el código
> heredado.* Reloj del contenedor, semilla del generador, orden explícito en la consulta de
> verificación. Si después de las tres cosas la salida sigue variando, **hay una fuente de azar en el
> sistema que nadie conocía** — y encontrarla es más valioso que la prueba.

### 5.3 El *golden master*, y cómo se rompe a propósito

```csharp
// src/modern/Sige.Characterization.Tests/SettlementCharacterizationTests.cs
[Collection(nameof(SigeDatabaseCollection))]
public class SettlementCharacterizationTests(SigeDatabaseFixture fixture)
{
    /// <summary>
    /// La foto de la liquidación completa del primer trimestre de 2026. No dice que estos números
    /// sean correctos: dice que son los que hay. Si cambian, alguien los cambió.
    /// </summary>
    [Fact]
    public async Task La_liquidacion_del_2026T1_produce_los_numeros_de_siempre()
    {
        // 🧬 Se ejecuta el procedimiento heredado tal cual, y se lee su salida como DataTable —
        //    que es lo que devuelve— sin mapearla a nada. Mapearla sería introducir una
        //    interpretación en el sitio donde solo queremos una fotografía.
        DataTable settlements = await LegacyProcedure
            .Run(fixture.ConnectionString, "SP_LIQREGAL_CALC")
            .WithParameter("@PERIODO", "202601")
            .AsDataTableAsync(TestContext.Current.CancellationToken);

        // El orden explícito es obligatorio: sin ORDER BY, el motor puede devolver las filas en
        // otro orden y la foto falla por una razón que no es un cambio de comportamiento.
        DataTable snapshot = await LegacyProcedure
            .Query(fixture.ConnectionString,
                   "SELECT NROLIQUI, NROCONTRA, PERIODO, FECLIQUI, VLRBASE, VLRREGAL, MONEDA, ESTADO " +
                   "FROM LIQREGAL WHERE PERIODO = '202601' AND BORRADO = 'N' ORDER BY NROLIQUI")
            .AsDataTableAsync(TestContext.Current.CancellationToken);

        // Verify escribe la salida en un archivo .verified.txt la primera vez, y compara contra él
        // las siguientes. El archivo se versiona: el diff de una foto que cambia es el material
        // más valioso de esta fase.
        await Verify(snapshot);
    }

    /// <summary>
    /// La prueba que demuestra que la red funciona. Cambia un dato de entrada que **debería**
    /// cambiar el resultado, y verifica que la foto falla.
    /// </summary>
    /// <remarks>
    /// Una prueba de caracterización que nadie rompió a propósito es una prueba en la que nadie
    /// confía. Esta es la contraparte obligatoria del <i>golden master</i>, y en esta fase se
    /// escribe siempre.
    /// </remarks>
    [Fact]
    public async Task La_foto_falla_si_alguien_cambia_el_porcentaje_de_un_contrato()
    {
        await using var scope = await fixture.BeginIsolatedScopeAsync();

        await scope.ExecuteAsync(
            "UPDATE CONTRATO SET PORCREGAL = PORCREGAL + 1 WHERE NROCONTRA = 'CT0000000042'");

        DataTable afterChange = await RunSettlementAsync(scope, "202601");

        // Se espera que NO coincida con la foto. Si coincide, el procedimiento no está usando
        // PORCREGAL como creemos, y eso es un hallazgo.
        await Assert.ThrowsAnyAsync<Exception>(() => Verify(afterChange).ToTask());
    }
}
```

**El patrón a memorizar**

> **Una foto sin una prueba que la rompa no es una red: es un adorno.** Por cada *golden master* que se
> escribe, se escribe la prueba que demuestra que falla cuando debe fallar. Si no falla, la foto está
> comparando algo que no es lo que crees — el conteo de filas en vez de los valores, o una columna que
> el procedimiento no usa.

> 💸 **Deuda declarada: el *golden master* está atado a un conjunto de datos concreto.**
>
> Las fotos de esta fase valen **solo** con la base que produce el generador con la semilla `19970417`.
> Cambiar la semilla, agregar una fila al generador o corregir una anomalía invalida todas las fotos a
> la vez, y el mensaje de fallo va a ser un diff enorme que no dice qué pasó.
>
> Lo correcto sería comparar **estados reconciliados** en vez de salidas literales: que la prueba
> verifique propiedades —"la suma de las regalías de un trimestre es igual a la suma de las bases por
> su porcentaje"— en vez de números exactos. Eso resiste un cambio de datos y sigue detectando un
> cambio de comportamiento.
>
> **Se discute y se resuelve en la fase 10**, donde la conciliación de la doble escritura necesita
> exactamente esa forma más robusta de comparar y no puede depender de una semilla. La factura será
> `git diff fase-08 fase-10 -- src/modern/Sige.Characterization.Tests/`.
>
> **Por qué se deja:** porque una foto literal se escribe en diez minutos y encuentra el 90% de los
> cambios accidentales, y porque escribir aserciones por propiedades **antes** de entender el
> procedimiento es imposible: no sabes qué propiedades tiene. La foto es cómo se averigua.

### 5.4 Catálogo y facturación, escritos mientras se caracterizan

El orden de esta sección es el de la fase y conviene que se vea: **un procedimiento, y acto seguido su
prueba**. No es un atajo de producción — es el orden real de quien hereda un sistema, y es más eficiente
de lo que parece, porque la prueba se escribe contra código que acabas de leer y todavía no entiendes
del todo, así que no la contaminas con suposiciones.

```sql
-- src/legacy/Sige.Database/procedimientos/SP_CATALOGO.sql
-- El defecto está a la vista para quien lo busque, y en producción lleva nueve años.
CREATE PROCEDURE SP_CATALOGO_VIGENTE @CODSELLO char(3) = NULL, @SOLOCONISBN char(1) = 'N'
AS
BEGIN
  IF @CODSELLO IS NOT NULL
  BEGIN
    SELECT … FROM EDICION E INNER JOIN TITULOS T ON T.CODTITULO = E.CODTITULO
    WHERE T.CODSELLO = @CODSELLO AND E.ESTADO = 'V'
      AND E.BORRADO = 'N' AND T.BORRADO = 'N';
  END
  ELSE
  BEGIN
    -- Aquí falta AND E.BORRADO = 'N' y falta el de TITULOS.
    SELECT … FROM EDICION E LEFT JOIN TITULOS T ON T.CODTITULO = E.CODTITULO
    WHERE E.ESTADO = 'V';
  END
END
```

```csharp
// Y su prueba, escrita el mismo día. Fija el defecto: no lo arregla.
[Fact]
public async Task El_catalogo_sin_filtro_de_sello_incluye_ediciones_borradas()
{
    DataTable withImprint = await RunCatalogAsync(imprint: "COM");
    DataTable withoutImprint = await RunCatalogAsync(imprint: null);

    int deletedInSecond = withoutImprint.AsEnumerable()
        .Count(row => row.Field<string>("BORRADO") == "S");

    // 340 ediciones borradas que la rama sin filtro de sello devuelve y la otra no.
    // ⚠️ Esto NO es el comportamiento correcto. Es el comportamiento ACTUAL, y esta prueba
    // existe para que el día que alguien lo arregle, se sepa. El arreglo es de la fase 09,
    // donde el filtro global de BORRADO se decide en un solo sitio.
    Assert.Equal(340, deletedInSecond);
    Assert.DoesNotContain(withImprint.AsEnumerable(), row => row.Field<string>("BORRADO") == "S");
}
```

**Detalles con intención**

- **El nombre de la prueba dice lo que pasa, no lo que debería pasar.** `El_catalogo_sin_filtro_…
  incluye_ediciones_borradas` es una descripción; `El_catalogo_no_debe_incluir_…` sería una
  especificación, y esta fase no escribe especificaciones.
- **El `Assert.Equal(340, …)` lleva su comentario de advertencia.** Sin él, el próximo que lea la prueba
  va a creer que 340 es lo correcto. Con él, la prueba documenta un defecto conocido con su número.
- **Aquí sí se usa LINQ sobre `DataTable`** (`AsEnumerable`), y es código nuevo: la prueba es de 2026.
  El procedimiento es de 2017. Es el borde 🧬 de la fase, y por eso están en archivos distintos.

**Prueba de fuego**

```powershell
dotnet test src\modern\Sige.Characterization.Tests -c Release
```

La primera ejecución **crea** los archivos `.verified.txt` y todas las pruebas de foto pasan por
definición. Eso no significa nada todavía: la señal de que la red sirve es la **segunda** ejecución, y
sobre todo la tercera, después de romper algo a propósito.

Y la mentira que te va a contar la salida si miras el lugar equivocado: **la suite va a estar verde con
un 70% de cobertura de línea** sobre `SP_LIQREGAL_CALC`, y eso parece un buen resultado. La medición de
la sección 6 muestra que la cobertura de **rama** sobre el mismo procedimiento es mucho más baja, y que
las ramas que faltan son justamente las que deciden cuánto se le paga a alguien.

---

## 📏 6. Medición

**Hipótesis A:** la cobertura de línea sobre un procedimiento heredado con cursores y ramas anidadas
**sobreestima groseramente** la protección real; la cobertura de rama sobre el mismo código es mucho
menor, y la diferencia entre las dos son precisamente las decisiones que cambian un número que alguien
factura.

**Hipótesis B:** un contenedor por clase de prueba cuesta lo suficiente como para cambiar cómo se
organiza la suite, y un contenedor compartido con datos disjuntos es el compromiso correcto — pero
**con un límite medible** a partir del cual el aislamiento vuelve a ganar.

**Condiciones:** SQL Server 2025 en contenedor sobre WSL 2 · la base del generador de la fase 07,
semilla `19970417` · SDK 10.0.401, xUnit v3 4.0.0, Testcontainers 4.15.0 · la suite de caracterización
completa —unas 40 pruebas sobre los cuatro módulos— · 10 ejecuciones con 2 de calentamiento
descartadas · cobertura con `coverlet` y el informe con `reportgenerator`; tiempos con el arnés.

**Competidores** — para la hipótesis B, tres formas de aislar, las tres defendibles:

- **Un contenedor por clase de prueba.** Aislamiento perfecto, y es lo que haría alguien que viene de
  `@Transactional` y descubre que no existe.
- **Un contenedor compartido con datos disjuntos por prueba** — cada prueba trabaja sobre su propio
  rango de códigos. Es el compromiso que esta fase propone.
- **Un contenedor compartido con transacción por prueba y rollback.** Es lo más parecido a
  `@Transactional`, y hay que medirlo **y** decir por qué falla con este esquema: los procedimientos
  abren sus propias transacciones.

**Los comandos:**

```powershell
# Cobertura de línea y de rama sobre el mismo código
dotnet test src\modern\Sige.Characterization.Tests -c Release `
  --collect:"XPlat Code Coverage" -- DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.Format=cobertura
reportgenerator -reports:**\coverage.cobertura.xml -targetdir:cobertura -reporttypes:Html

# Tiempo de la suite en las tres estrategias de aislamiento
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 08 --strategy container-per-class,shared-disjoint,shared-transaction
```

**Resultado:** ⏳ pendiente de ejecución en tu máquina.

**A · Cobertura sobre `SP_LIQREGAL_CALC`**

| Métrica | Con 2 pruebas | Con la suite completa | Ramas que deciden un pago |
|---|---|---|---|
| Cobertura de línea | ⏳ | ⏳ | — |
| Cobertura de rama | ⏳ | ⏳ | ⏳ |

**B · Tiempo de la suite por estrategia de aislamiento**

| Estrategia | Mediana | p95 | Aislamiento | Falla con este esquema |
|---|---|---|---|---|
| Contenedor por clase | ⏳ | ⏳ | total | no |
| Compartido, datos disjuntos | ⏳ | ⏳ | por convención | si dos pruebas eligen el mismo rango |
| Compartido, transacción por prueba | ⏳ | ⏳ | total en teoría | **sí** — los procedimientos abren sus propias transacciones |

> ⚖️ **Veredicto** *(expectativa, todavía sin ejecutar — `formato-de-mediciones.md` §2.6)*. Se espera
> que la cobertura de línea con dos pruebas ya esté alta —porque el camino feliz atraviesa casi todo el
> archivo— y que la de rama se quede muy por debajo incluso con la suite completa. Y se espera que el
> contenedor por clase sea varias veces más lento que el compartido, con una diferencia que crece con
> el número de clases y no con el de pruebas.
>
> **Los dos umbrales que tu ejecución tiene que determinar:** (1) **cuántas ramas decisorias quedan sin
> cubrir cuando el porcentaje de línea ya se ve bien** — ese número es el argumento contra la cobertura
> como métrica de gestión; y (2) **a partir de cuántas clases de prueba el contenedor por clase deja de
> ser viable**, que es lo que decide la organización de la suite para las fases 09 a 11.
>
> 📝 La tercera fila de la tabla B **se publica aunque falle**, y ahí está su valor: es la traducción
> obvia de `@Transactional` y no funciona, y saber por qué —los procedimientos abren transacciones
> propias, y anidarlas cambia su comportamiento— evita que alguien lo intente durante dos días.

---

## 🧱 7. Miniproyecto — caracterizar la liquidación, y encontrar la regla que no se aplica

**El encargo**

Clara, por escrito, y es el correo que nadie quiere recibir: *"La traductora de la colección peruana
volvió a escribir. Su abogado pregunta por qué en 2019 le liquidamos sobre precio de lista y el
contrato dice neto facturado. Necesito saber tres cosas antes del jueves: si el contrato dice eso, si el
sistema hace eso, y si hay más autores en la misma situación. Y necesito que lo que me digas se pueda
sostener, porque si la respuesta es que llevamos nueve años liquidando mal, eso no es un problema de
sistemas."*

**Por qué duele**

Porque la pregunta de Clara no se puede responder leyendo. `SP_LIQREGAL_CALC` tiene la decisión
repartida entre un `IF` anidado, un cursor y una llamada a otro procedimiento, y **quien lo escribió en
2017 no está**. La única forma de responder con algo que se sostenga es **ejecutarlo y observar**, con
casos construidos a propósito para aislar la variable.

Y porque la respuesta correcta a la tercera pregunta —*"¿hay más autores así?"*— es un número, y ese
número tiene consecuencias que no son técnicas.

**Datos de entrada**

La base del generador de la fase 07, con la semilla `19970417`, y **cuatro contratos que tienes que
construir a propósito** porque el generador no garantiza que existan todas las combinaciones:

| Contrato | `TIPOCONTR` | `BASELIQUI` | Qué aísla |
|---|---|---|---|
| `CT0000000101` | `A` autoría | `P` precio de lista | El caso base, sin ambigüedad |
| `CT0000000102` | `A` autoría | `N` neto facturado | La rama que **sí** descuenta |
| `CT0000000103` | `T` traducción | `P` precio de lista | Control: traducción sin descuento pactado |
| `CT0000000104` | `T` traducción | `N` neto facturado | **El caso de la traductora** |

Cada uno con ventas en el trimestre y **con facturas que tengan descuento**, porque sin descuento las
dos ramas dan el mismo número y el defecto es invisible. Ese detalle es la mitad del ejercicio.

**Criterios de aceptación**

1. Existe un *golden master* de la liquidación del trimestre completo, con la base y la semilla
   declaradas, y una prueba que **demuestra que la foto falla** cuando se cambia un dato que debe
   cambiar el resultado.
2. `SP_LIQREGAL_CALC` es determinista bajo prueba: **dos ejecuciones consecutivas producen la misma
   salida**, y el procedimiento **no se modificó**. Una prueba lo demuestra ejecutándolo dos veces.
3. Cuatro pruebas, una por contrato de la tabla, que fijan el número que el sistema produce hoy para
   cada combinación. Los nombres de las pruebas describen **lo que pasa**, no lo que debería pasar.
4. Un documento corto —media página— que responde las tres preguntas de Clara: qué dice el contrato,
   qué hace el sistema, y **cuántos autores están en la misma situación**, con la consulta que lo
   cuenta y el impacto en pesos del trimestre.
5. El defecto **no se arregla**. Si en tu entrega `SP_LIQREGAL_CALC` cambió, el criterio no se cumple —
   y el porqué está en la sección 3.
6. **Medición de cierre:** cobertura de rama sobre el procedimiento antes y después de las cuatro
   pruebas, y tiempo de la suite. Van en el mensaje del tag `mini-08`.

**Restricciones de estilo y alcance**

🧬 **Mixta, con el borde explícito.** Las pruebas son .NET 10, nullable activado, `async` de punta a
punta. Lo que ejecutan es .NET Framework 4.8 y T-SQL de 2017, y **no se toca**. Los dos lados no
comparten archivo.

Las pruebas leen `DataTable` y comparan a propósito: mapear la salida a un modelo tipado sería
introducir una interpretación justo donde solo queremos una fotografía. El borde tipado es de la fase 09.

**La trampa**

El procedimiento no es determinista, y hasta que eso no se resuelva **ninguna prueba sirve de nada**.
Vas a descubrirlo cuando la segunda ejecución falle con un diff en la columna `FECLIQUI`.

Lo vas a arreglar congelando el reloj del contenedor, y va a funcionar. Y la tercera ejecución **también
va a fallar**, en otra columna, por otra razón: hay una segunda fuente de azar que el reloj no cubre.
Está en el procedimiento, en una línea de tres palabras, y cuando la encuentres vas a entender por qué
el generador de la fase 07 garantiza una sola tasa de cambio por moneda.

Cuando llegues ahí, escribe las **tres** fuentes de no determinismo que encontraste —hay una más, y es
de las pruebas y no del sistema— y qué hiciste con cada una. Ese texto vale más que las cuatro pruebas.

<details><summary>Pista 1 — el enfoque</summary>

Cuatro contratos idénticos salvo en una variable cada vez. Es diseño experimental, no programación: si
cambias dos cosas entre dos casos, no puedes atribuir la diferencia a ninguna.

Y para la tercera pregunta de Clara, la consulta no busca en el código: busca en los datos. ¿Qué
contratos tienen la combinación que cae en la rama equivocada, y cuánto se les liquidó?

</details>

<details><summary>Pista 2 — la herramienta</summary>

Para las fotos, **Verify** —el equivalente de ApprovalTests— que guarda la salida en un archivo
versionado:
`https://github.com/VerifyTests/Verify`

Para el reloj del contenedor, `IContainer.ExecAsync` de Testcontainers. Y para la segunda fuente de
azar, busca en `SP_LIQREGAL_CALC` un `SELECT TOP 1` y pregúntate qué garantiza su `ORDER BY` cuando hay
empate:
`https://learn.microsoft.com/sql/t-sql/queries/select-order-by-clause-transact-sql`

Para la cobertura de rama, `coverlet` pedida explícitamente — por omisión el informe que todo el mundo
mira es el de línea.

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```csharp
// El ejecutor del procedimiento heredado. 🧬 Es el único sitio de las pruebas que habla con el
// mundo de 2017, y por eso está en un archivo propio.
internal static class LegacyProcedure
{
    public static LegacyCall Run(string connectionString, string procedureName);
    public static LegacyCall Query(string connectionString, string sql);
}

// El caso experimental: un contrato con una sola variable cambiada.
internal sealed record SettlementCase(
    string ContractNumber,
    char ContractType,     // A autoría, T traducción
    char SettlementBase,   // P precio de lista, N neto facturado
    decimal Percentage,
    decimal ExpectedDiscountApplied);   // lo que el contrato dice que debería descontar

// La respuesta a Clara: cuántos contratos caen en la rama equivocada y cuánto costó.
internal sealed record AffectedContractsReport(
    int ContractCount,
    Money UnderpaidInQuarter,
    IReadOnlyList<string> ContractNumbers);
```

</details>

**Cómo se entrega**

```powershell
dotnet test src\modern\Sige.Characterization.Tests -c Release
dotnet test src\modern\Sige.Characterization.Tests -c Release --collect:"XPlat Code Coverage"
```

```bash
git tag -a mini-08 -m "Mini F8: liquidacion caracterizada y determinista · <N> contratos afectados, <X> COP del trimestre · cobertura de rama <A>% -> <B>%"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Levanta la suite con Testcontainers y mide cuánto tarda el primer arranque frente al segundo.
   Explica la diferencia.
2. Escribe una prueba de caracterización sobre `SP_EXIST_ALMACEN` para el almacén de Lima que fije el
   número de filas y la suma de saldos.
3. Rompe a propósito una foto —cambia un dato— y lee el diff que produce Verify. Anota qué tan útil es
   el mensaje.
4. Escribe la prueba que fija el comportamiento de `SP_TITULO_BUSCAR` con un título peruano cuya tilde
   se comió la importación. La prueba debe **documentar que no lo encuentra**.
5. Genera el informe de cobertura y compara el porcentaje de línea con el de rama sobre el mismo
   procedimiento. Anota los dos números.
6. Convierte una clase de prueba de `IClassFixture` a `[Collection]` y explica qué cambió en el
   paralelismo.

**🟡 Intermedio (7–14)**

7. Escribe una prueba que demuestre que `SP_FACTURA_ANULAR` anula **dos** facturas cuando el mismo
   cliente tuvo dos el mismo día. No la arregles: caracterízala.
8. Congela el reloj del contenedor y demuestra con dos ejecuciones consecutivas que `FECLIQUI` ya no
   varía.
9. Encuentra la segunda fuente de no determinismo de `SP_LIQREGAL_CALC` y escribe la prueba que la
   expone insertando una segunda tasa con la misma fecha.
10. Implementa la estrategia de **datos disjuntos** —cada prueba con su propio rango de códigos— y
    demuestra que dos pruebas que antes se pisaban ahora pueden correr en paralelo.
11. Intenta la estrategia de **transacción por prueba con rollback** y documenta exactamente dónde
    falla con estos procedimientos. Es la fila que la medición publica aunque falle.
12. Escribe una prueba de caracterización **por propiedades** en vez de por foto: que verifique que la
    suma de regalías es igual a la suma de bases por su porcentaje. Compárala con la foto y di qué
    detecta cada una.
13. Mide cuánto tarda la suite con el contenedor compartido y con uno por clase, con cinco clases y con
    quince. Extrapola el umbral.
14. Escribe la prueba que fija el comportamiento de `SP_CATALOGO_VIGENTE` en sus **dos** ramas, y deja
    documentado en el nombre de cada una cuál trae ediciones borradas.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** La suite pasa en tu máquina y falla en la de Duván, en la misma prueba de foto.
    Enumera cuatro causas posibles —una es la intercalación, otra la zona horaria— y di cómo
    distinguirlas.
16. **Diagnóstico.** Una prueba de caracterización empieza a fallar de forma intermitente, una vez de
    cada diez, sin que nadie haya tocado nada. Encuentra las dos causas más probables con este esquema
    y escribe la prueba que confirma cada una.
17. **Medición.** Ejecuta la medición completa de la sección 6, las dos hipótesis, y determina **los
    dos umbrales**. Publica las dos tablas con su veredicto, incluida la fila que falla.
18. **Medición.** Determina cuántas pruebas hacen falta para cubrir **todas** las ramas de
    `SP_LIQREGAL_CALC` que afectan un pago, y cuánto sube la cobertura de rama con cada una. Grafica la
    curva y di dónde deja de valer la pena.
19. Escribe la especificación de cómo se compararían **estados reconciliados** en vez de salidas
    literales —la deuda 💸 de esta fase— y prueba el enfoque en un caso. Es el trabajo que la fase 10
    va a necesitar.
20. **Decisión — ¿se migra, se envuelve o se deja quieto?** La regla de `BASELIQUI` está mal desde
    2017. Las opciones son corregirla y liquidar retroactivamente, corregirla solo hacia adelante, o
    dejarla y documentarla. Decide, con el costo legal, contable y técnico de cada una — y ten en
    cuenta que la presidenta es abogada.
21. **Decisión — ¿se migra, se envuelve o se deja quieto?** Los cuatro volcados CSV nocturnos están
    desincronizados porque usan ramas distintas de `SP_CATALOGO_VIGENTE`. Decide si se unifican ahora,
    si se espera a CatalogAPI en la fase 09, o si se deja — y di qué le pasa a Almenara en cada caso.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Escribe una prueba de caracterización que pase siempre, incluso cuando el
    comportamiento cambia. Hay varias formas —comparar conteos, ignorar columnas, redondear— y todas
    son errores reales que la gente comete. Después arréglala.
23. **Adversarial.** Consigue que la suite entera pase con el procedimiento de liquidación **roto**:
    encuentra qué cambio puedes hacerle que ninguna de tus pruebas detecte. Ese hueco es la respuesta
    real a "¿qué tan buena es mi red?", y vale más que cualquier porcentaje.
24. **Diseño.** Escribe el plan de caracterización de los **690 procedimientos que el curso no
    escribe**: en qué orden los cubrirías, con qué criterio decidirías cuáles no vale la pena cubrir, y
    cuánto estimarías. Es el documento que un equipo real necesita en la semana tres.
25. **Defiende una decisión.** Responde el correo de Clara con las tres respuestas y su respaldo, en
    media página, en su lenguaje. Y agrega la parte que ella no pidió y necesita: qué garantiza que
    esto no vuelva a pasar sin que nadie se dé cuenta.

**🔥 Opcionales**

- Investiga SQL Server Data Tools y las pruebas unitarias de base de datos, y escribe por qué este
  curso no las usa. *(Pista: tiene que ver con qué se está probando.)*
- Escribe un generador de casos que produzca todas las combinaciones de `TIPOCONTR` × `BASELIQUI` ×
  moneda y ejecute la liquidación para cada una. Anota cuántas combinaciones tienen comportamiento
  sorprendente.
- Prueba `Verify` con salida en formato de tabla legible en vez de texto plano, y decide cuál produce
  mejores diffs en una revisión de código.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://xunit.net/docs/shared-context` — `IClassFixture`, `ICollectionFixture` y `[Collection]`.
- `https://dotnet.testcontainers.org/modules/mssql/` — Testcontainers para .NET con SQL Server.
- `https://learn.microsoft.com/dotnet/core/testing/unit-testing-code-coverage` — cobertura con
  `coverlet`, y **cómo pedir la de rama**, que no viene por omisión.
- `https://learn.microsoft.com/sql/t-sql/queries/select-order-by-clause-transact-sql` — y en particular
  qué **no** garantiza `TOP` sin un `ORDER BY` determinista.
- `https://learn.microsoft.com/sql/relational-databases/collations/collation-and-unicode-support` — la
  intercalación, que es la causa de las tildes comidas y de un fallo intermitente entre máquinas.
- `https://github.com/VerifyTests/Verify` — el equivalente de ApprovalTests en .NET.

**Libros / artículos**

- *Working Effectively with Legacy Code*, de Michael Feathers — el capítulo de pruebas de
  caracterización es literalmente el contenido de esta fase, y la definición de "código heredado es
  código sin pruebas" es de ahí. Verifica edición y disponibilidad; no se inventan páginas aquí.

**Video / apoyo**

- Las charlas sobre *approval testing* y caracterización en conferencias de pruebas cubren el mismo
  material con otros ejemplos. No se citan identificadores: cambian.

> ⚠️ Verifica las URLs. Y dos advertencias propias de esta fase. La primera: **casi todo el material
> sobre xUnit describe la v2**, donde `IAsyncLifetime` devolvía `Task`, vivía en otro espacio de
> nombres y el proyecto de pruebas no era ejecutable. La segunda: **mucho material sobre pruebas de
> acceso a datos en .NET usa dobles sobre un repositorio inventado**, y con un esquema como el de SIGE
> eso no prueba nada — la mitad de los defectos interesantes están en el motor y en los datos.

**Orden de lectura sugerido:** antes de escribir, el capítulo de caracterización de Feathers y la
página de contexto compartido de xUnit. Durante el miniproyecto, la ficha de Testcontainers y la de
`ORDER BY`. Al cerrar, la de cobertura: se lee distinto cuando ya viste la diferencia entre línea y
rama en tu propio informe.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Hay red. Los cuatro módulos de SIGE tienen pruebas de caracterización, el procedimiento de liquidación
es determinista sin haberlo tocado, hay un *golden master* que se rompe cuando debe romperse, y hay un
número que Clara puede llevar a una reunión: cuántos contratos se liquidaron sobre la base equivocada y
cuánto costó.

Y hay una cosa más, que es el resultado menos esperado de esta fase: **el hallazgo no salió de leer
código**. Salió de construir cuatro casos y observar. La habilidad que acabas de ejercer no aparece en
ningún temario de lenguaje, y es la que separa una migración de un incendio.

La fase 09 es el paso natural porque ahora sí se puede tocar. Con la red puesta, la pregunta pasa a ser
la primera de verdad del curso: **cómo se lee y se escribe contra un esquema hostil sin que el esquema
gane.** ADO.NET, Dapper y EF Core midiéndose sobre los mismos datos, el `char(8)` convertido a
`DateOnly` en un solo borde 🧬, el filtro global de `BORRADO` **y sus tres agujeros**, y la tabla por
año convertida en algo consultable. Ahí nace CatalogAPI, y ahí se cobran tres deudas de golpe: los dos
`!` de la fase 02 y el `IQueryable` de la 03 — las tres en el mismo archivo, que es el argumento de por
qué el borde va concentrado.

> **La señal de que quedó bien:** *"Puedo cambiar algo en un procedimiento que no entiendo y saber en
> treinta segundos si rompí algo — y cuando encuentro un defecto de nueve años, sé que arreglarlo no es
> mi decisión."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el miniproyecto
> corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-08 -m "F8 cerrada:
> - catalogo y facturacion implementados y caracterizados el mismo dia
> - SP_LIQREGAL_CALC determinista bajo prueba, sin modificar el procedimiento
> - golden master con su prueba de ruptura, y las tres fuentes de azar documentadas
> - Testcontainers con SQL Server 2025 y la base del generador con semilla 19970417
> - hallazgo: la regla de BASELIQUI no se aplica a traducciones, con su impacto en pesos
> - cobertura de linea contra cobertura de rama medida: el porcentaje no protege nada"
> ```
>
> Esta fase **no cobra deuda y planta una**: el *golden master* atado a la semilla, con cobro en la
> fase 10. Es una deuda de un tipo nuevo en el curso —no está en el código del sistema, está **en las
> pruebas**— y por eso conviene decir en voz alta que las pruebas también acumulan deuda, y que una
> suite frágil se paga igual que un módulo frágil.
>
> Los commits llevan su prefijo (`fase 08: …`), y como esta fase toca los dos lados de la frontera,
> `git log --oneline -- src/legacy/` y `git log --oneline -- src/modern/` cuentan dos historias
> distintas del mismo día. El tag cubre las dos mitades: si `Sige.sln` compila y la suite pasa, la
> fase está cerrada.

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura.*

- **`INSTINTOS.md`** — dos entradas en la familia *datos y esquema*: reescribir antes de entender —que
  es de **arquitectura** y merece puntero desde esa sección— y traducir el `@BeforeAll` estático con un
  `.Result` adentro. La primera necesita el matiz que la hace útil: el reflejo no se presenta como
  "reescribo sin entender", se presenta como "leo qué hace y lo reescribo limpio", y **el paso que
  falla es el de leer**.
- **`BENCHMARKS.md`** — entrada ⏳ *F08 · Cobertura de línea contra rama, y tiempo de la suite por
  estrategia de aislamiento*. Es la primera del curso con **dos hipótesis en una entrada**; si eso
  incomoda, se parte en dos, pero las dos salen de la misma ejecución.
- **Deuda 💸 registrada:** el *golden master* atado a la semilla, cobro en F10. Ya está en el libro de
  §7.1. Conviene anotar allí que es **la única deuda del curso que vive en las pruebas y no en el
  sistema**, porque eso la hace didácticamente distinta.
- **Decisión que sube a la propuesta:** el 📖 JUnit ⇄ xUnit quedó **partido en dos** — el ciclo de vida
  en la F04 y la integración en la F08— y el alcance de §5 decía "el 📖 completo" en la F08. La
  división es mejor: el ciclo de vida cae solo en la fase de `IDisposable`, y repetirlo aquí sería
  relleno. Hay que corregir §5 de la propuesta para que diga qué mitad va en cada fase.
- **Para la fase 09:** el ejercicio 21 —qué hacer con los cuatro volcados desincronizados— es el
  planteamiento de CatalogAPI. Y las pruebas de esta fase son las que van a decir si el borde 🧬 de la
  09 cambió el comportamiento: **la 09 no puede tocar el filtro de `BORRADO` sin que las fotos de aquí
  fallen**, y ese fallo es la prueba de que el cambio hizo algo.
- **Para la fase 10:** la deuda del *golden master* se cobra allí, y el ejercicio 19 tiene escrito el
  enfoque. Si alguien lo hizo, la 10 debería partir de ahí en vez de rediscutirlo.
- **Para la fase 24:** el ejercicio 20 —qué hacer con nueve años de liquidaciones mal calculadas— es
  una de las decisiones que el veredicto final tiene que revisar. No hay respuesta correcta y eso es el
  punto.
- **Riesgo detectado al escribir la F09 y resuelto aquí:** la caracterización de `SP_EXIST_ALMACEN` con
  el total de Lima estaba como ejercicio 2 y no en el checklist, pero **la F09 la necesita como
  referencia** para comprobar que su borde cuadra. Subió al checklist de la sección 2.
- **Riesgo detectado:** esta fase asume que el generador de la F07 produce contratos con **todas** las
  combinaciones de `TIPOCONTR` × `BASELIQUI` y facturas con descuento. La tabla de volúmenes de la F07
  no lo garantiza explícitamente. Hay que agregarlo allí o el miniproyecto no se puede hacer sin
  construir los cuatro contratos a mano — que es lo que el enunciado pide, pero conviene que sea una
  decisión y no un descubrimiento.
