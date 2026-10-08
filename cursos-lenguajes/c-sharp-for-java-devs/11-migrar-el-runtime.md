# 🚚 Fase 11 — Migrar el runtime: de .NET Framework 4.8 a .NET 10

> C# para desarrolladores Java senior · Fase 11 de 24 · Bloque B ⭐ — el sistema heredado y la frontera
> Depende de: 10 · Habilita: 12
> Estilo de esta fase: **mixto 🧬** — durante toda la fase los dos runtimes conviven, y ese es el punto.
> Al terminar, el módulo de facturación corre en .NET 10 y el resto sigue en 4.8, a propósito.
> Proyecto que avanza: **SIGE**. Y cierra el Bloque B.

---

## 🎯 1. Propósito

Mover el runtime, por fin — y descubrir que es la parte fácil.

El orden de las cuatro fases anteriores no era casual: se leyó el sistema, se puso la red, se midió el
acceso a datos y se cortó la conexión directa del cliente a la base. **Solo entonces mover el runtime es
posible**, porque hacerlo antes habría sido cambiar de casa sin haber empacado. Esta fase convierte el
formato del proyecto, pasa los paquetes, lleva los ASMX de 2019 a minimal APIs, y hace lo único que
ninguna herramienta hace: **decidir el orden por riesgo y no por versión**, y publicar la lista honesta
de lo que no se pudo migrar.

> 🧭 **La regla de la fase:** *no se migra un proyecto porque le toque por orden alfabético ni porque sea
> el más fácil. Se migra el que menos duele si sale mal, y se migra uno a la vez con los dos runtimes
> vivos.* Es el mismo criterio de Clara en la fase 10, aplicado a los ensamblados.

---

## ✅ 2. Qué queda listo al terminar

- [ ] `Sige.Billing` corre en **.NET 10**, con su `.csproj` en formato SDK, y las fotos de la fase 08
      **siguen pasando** — es la única forma de saber que la migración no cambió el comportamiento.
- [ ] `packages.config` está convertido a `PackageReference` en lo que se pudo, y **lo que no se pudo
      está declarado** con su nombre, su razón y qué haría falta para resolverlo.
- [ ] Existe el **informe de compatibilidad de APIs** del módulo migrado, y las APIs que compilan contra
      el paquete de compatibilidad **y revientan en tiempo de ejecución** están identificadas una por una.
- [ ] Los ASMX de 2019 tienen su reemplazo en minimal APIs, con el **contrato compatible hacia atrás**:
      el socio comercial que lleva siete años consumiendo `DataSet` serializado sigue funcionando.
- [ ] Está escrita la decisión sobre **Crystal Reports**, con su medición y su costo.
- [ ] Está dicho, en voz alta, **por qué migrar desde 4.8 es más fácil que desde 4.5**, y qué tendría de
      más el camino que Cordillera no tuvo que hacer.
- [ ] La medición de la sección 6 está escrita con su comando, y la entrada quedó en `BENCHMARKS.md`.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Los 340 formularios WinForms** → Bloque C, fases 12 a 14. Esta fase migra bibliotecas y servicios;
  el escritorio tiene sus propias reglas y su propio veredicto.
- **El contenedor y el despliegue** → fase 20. Aquí el módulo migrado corre en la misma máquina virtual
  que el resto, y eso es deliberado: **una migración de runtime y un cambio de plataforma de ejecución no
  se hacen el mismo día.**
- **Migrar todo.** Al terminar la fase, tres de los cuatro módulos siguen en 4.8, y eso no es trabajo
  pendiente: es la decisión. La lista de lo que no se migró tiene su razón escrita.
- **Arreglar el esquema.** Sigue intacto. La fase 09 dejó medido lo que costaría; la decisión final es
  de la fase 24.
- **Reescribir el código de negocio**, que es justamente lo que esta fase demuestra que **no** hace falta.

---

## 🧠 4. Concepto mínimo

### Qué es migrar un runtime, y qué no es

Migrar de .NET Framework 4.8 a .NET 10 no es portar código: es **cambiar la implementación de la
biblioteca base debajo del mismo lenguaje**. El C# no cambia —el de 2017 compila igual en .NET 10, con
ajustes menores— y el código de dominio pasa casi entero sin tocarse. Lo que cambia son cuatro cosas
concretas:

**El formato del proyecto.** El `.csproj` viejo lista cada archivo `.cs` a mano, arrastra un GUID y
referencia paquetes por ruta relativa a una carpeta `packages\`. El formato SDK incluye los archivos por
convención y referencia paquetes por nombre. La conversión es mecánica y una herramienta la hace.

**El modelo de paquetes.** `packages.config` instala en una carpeta al lado de la solución y escribe las
referencias dentro del `.csproj`; `PackageReference` resuelve transitivas y no toca el proyecto. La
conversión también es mecánica **hasta que un paquete no tiene versión compatible**, y ahí se acaba lo
mecánico.

**Las APIs que no existen.** .NET Framework tiene APIs que nunca se llevaron a .NET moderno, y son de
tres clases distintas que conviene separar porque se resuelven distinto: las que **no existen** (WCF
servidor, AppDomain, Remoting), las que **existen con otra forma** (`ConfigurationManager` →
`IConfiguration`, `HttpContext.Current` → inyección explícita), y las peores, las que **existen, compilan,
y lanzan en tiempo de ejecución** — porque el paquete de compatibilidad las declara para que el código
compile y su implementación no hace nada.

**El modelo de configuración y de hospedaje.** `App.config` con secciones, `AppDomain.CurrentDomain`,
`System.Web` — todo eso se reemplaza por el modelo de configuración y el contenedor de dependencias que la
fase 15 usa en serio.

> 🧠 **El modelo mental:** la herramienta de actualización hace el **70%** —el formato, los paquetes que se
> pueden, los `using` obvios— y el curso vive en el **30% restante**, que es donde está todo lo que no se
> puede automatizar: qué APIs no existen, qué compila y revienta, qué paquete no tiene sucesor, y en qué
> orden conviene tocar los proyectos. Un tutorial de la herramienta te deja en el 70% creyendo que
> terminaste.

### Migrar por riesgo, no por versión

El reflejo de organización es migrar de abajo hacia arriba: primero las bibliotecas sin dependencias,
después las que dependen de ellas, y al final la aplicación. Es un orden **topológico**, y es correcto en
el sentido en que lo es un `make`.

Pero no responde la pregunta que importa, que es la misma de la fase 10 con otra forma: **si este
proyecto migrado falla en producción, ¿qué pasa y quién lo absorbe?**

Y hay una propiedad del ecosistema que lo hace posible: **un ensamblado de .NET Framework 4.8 y uno de
.NET 10 pueden convivir en el mismo sistema**, comunicándose por un proceso aparte, por HTTP o por la
base de datos. No pueden cargarse en el mismo proceso —eso sí es imposible— pero el sistema completo
puede tener una mitad en cada runtime durante meses. Eso convierte la migración en incremental y con
vuelta atrás, igual que el corte de la fase 10.

De ahí sale el orden de esta fase, y facturación va primero por una razón que no es técnica: **es el
módulo que la fase 10 dejó de último**, y por tanto el que sigue con su camino viejo intacto y su red de
pruebas completa. Migrar su runtime no toca nada de lo que la fase 10 movió.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**Primera: migrar por versión, subiendo de a poco.**

Once años en la JVM enseñan un camino: de Java 8 a 11, de 11 a 17, de 17 a 21, cada salto con sus notas
de compatibilidad, y cada uno desbloqueando el siguiente. Es un camino gradual y funciona.

```text
❌ El plan que sale de ese instinto:
   "Subimos 4.8 a .NET 6, que es LTS y tiene el paquete de compatibilidad más completo.
    Después de 6 a 8, y de 8 a 10. Tres saltos, cada uno probado."
```

**Por qué falla aquí:** porque **no hay una escalera**. .NET Framework y .NET moderno no son dos versiones
de lo mismo: son **dos implementaciones distintas** de la misma plataforma, y el salto es uno solo — de
Framework a .NET, punto. Una vez del otro lado, subir de .NET 6 a 10 sí es un cambio de versión trivial.
Migrar a .NET 6 primero significa hacer el trabajo difícil apuntando a un runtime que ya está fuera de
soporte, y después hacer otra migración encima.

```text
✅ El plan de esta fase:
   Un salto, a .NET 10, un proyecto a la vez, con los dos runtimes vivos y el orden
   decidido por lo que duele si falla.
```

**Segunda, y es la que produce estimaciones de dieciocho meses: creer que el código de negocio se
reescribe.**

Es el miedo razonable de quien mira 250.000 líneas y calcula. Y es falso, y conviene decirlo con
precisión:

| Qué | Cuánto de SIGE | Qué le pasa al migrar |
|---|---|---|
| Lógica de dominio en C# —cálculos, validaciones, reglas— | ~40% | **Pasa sin tocarse.** El lenguaje es el mismo |
| Acceso a datos con `SqlConnection`/`DataSet` | ~15% | Pasa con el paquete de `System.Data.SqlClient` cambiado por `Microsoft.Data.SqlClient` |
| Configuración con `ConfigurationManager` | ~3% | Existe con otra forma: hay que tocarlo, y es mecánico |
| Formularios WinForms | ~35% | Pasan sobre .NET 10, y es el Bloque C |
| APIs que no existen —ASMX servidor, Crystal— | ~5% | **Es el trabajo de verdad**, y es donde va todo el presupuesto |
| Paquetes sin sucesor | 2 paquetes | Puede que no se resuelva, y esa es una respuesta legítima |

**Por qué falla el reflejo:** porque el 5% de la tabla ocupa el 80% del esfuerzo, y estimar por líneas de
código da un número diez veces mayor que la realidad. La estimación correcta no se hace contando
líneas: se hace **corriendo el informe de compatibilidad**, que en media hora dice exactamente cuántas
llamadas a APIs inexistentes hay y dónde.

> ⚰️ **Autopsia del anti-patrón: la API que compila y revienta.**
>
> **El caso:** `ConfigurationManager.AppSettings` existe en .NET 10 —el paquete
> `System.Configuration.ConfigurationManager` lo declara— así que el código de 2017 **compila sin una
> advertencia**. Y devuelve `null`, siempre, porque no hay `App.config` que leer: en .NET moderno la
> configuración es otra cosa.
>
> **Antes:** la ruta de reportes se leía del `App.config` y el módulo escribía ahí sus salidas.
>
> **Después de migrar:** la ruta es `null`, el `Path.Combine` produce una ruta relativa, y los reportes
> se escriben **en el directorio de trabajo del proceso** — que en el servidor es `C:\Windows\System32`.
>
> **Cuánto costó:** dos días hasta que alguien encontró cuarenta PDF de liquidaciones en una carpeta del
> sistema. Ningún error, ningún log, ninguna excepción: el código hizo exactamente lo que decía.
>
> **La defensa:** el informe de compatibilidad marca estas APIs con una categoría propia, y **la regla de
> la fase es que ninguna de ellas se deja como está**: o se reemplaza, o se envuelve con una comprobación
> que lanza si el valor no está. Un `null` silencioso en configuración es peor que un fallo al arrancar.

### 🩻 Esto sí funciona igual — y es casi todo

El 🩻 de esta fase es grande y es la buena noticia que el lector necesita antes de empezar: **el lenguaje
es el mismo y el código de dominio pasa sin tocarse.** Un cálculo de regalías escrito en C# 2 en 2017
compila en .NET 10 y produce el mismo número. Los `decimal` se comportan igual, las cadenas se comparan
igual, las excepciones se lanzan igual.

Y del lado del oficio, se transfiere entero lo que sabes de migraciones de plataforma: correr el análisis
antes de estimar, migrar hoja por hoja del grafo de dependencias, mantener las dos versiones vivas, tener
una suite que diga si algo cambió. El instinto de **no migrar y refactorizar en el mismo commit** se
transfiere y aquí es más importante que nunca: un diff de migración tiene que ser legible, y si lleva
mejoras adentro, nadie puede revisarlo.

Lo que también se transfiere —y conviene decirlo porque tranquiliza— es que **el informe de
compatibilidad se lee como un informe de `jdeps`**: te dice qué usas que no va a estar. La herramienta
tiene otro nombre y hace lo mismo.

### 📖 Diccionario de traducción

| Mundo Java | .NET Framework → .NET moderno | Dónde se rompe el paralelo |
|---|---|---|
| Java 8 → 11 → 17 → 21 | **4.8 → .NET 10, un solo salto** | No hay escalera: Framework y .NET son **dos implementaciones**, no dos versiones. Después del salto, subir de versión sí es trivial |
| `jdeps --jdk-internals` | **.NET Upgrade Assistant** + análisis de portabilidad | Reporta lo mismo con otro nombre, y clasifica por "no existe / cambió / compila y falla" |
| `--add-opens` / `--illegal-access` | **paquete de compatibilidad de Windows** | Es la diferencia peligrosa: el paquete hace que **compile**, y algunas implementaciones no hacen nada |
| módulos de JPMS | ensamblados y `PackageReference` | No hay módulos: la unidad sigue siendo el ensamblado. Menos ceremonia, menos garantías |
| `javax.*` → `jakarta.*` | `System.Web` → **no existe** | Aquí no hay renombrado: el espacio de nombres de web de Framework simplemente no se llevó |
| `web.xml` / `application.properties` | `App.config` → `IConfiguration` | La forma cambia de XML con secciones a un modelo de claves y proveedores, y **es un cambio de código** |
| JAX-WS (SOAP) | ASMX / WCF → **CoreWCF o minimal APIs** | WCF servidor **no está** en .NET moderno. CoreWCF cubre parte; el resto se reescribe |
| `Class.forName` / reflexión sobre el classpath | reflexión sobre ensamblados cargados | No hay classpath dinámico: los ensamblados se resuelven distinto, y el código que los cargaba a mano se rompe |
| dos JAR con versiones distintas del mismo artefacto | **no se pueden cargar los dos runtimes en un proceso** | Conviven en el **sistema**, comunicándose por HTTP o base de datos. Nunca en el mismo proceso |
| `mvn dependency:analyze` | `dotnet list package --outdated` / `--vulnerable` | Equivalente práctico, con menos análisis de uso |

> 📝 **Nota de ecosistema, y es la obligación declarada de esta fase.** Los pasantes escribieron SIGE
> sobre **.NET Framework 4.5** en 2016, y en 2021 Wilson subió el destino a **4.8** porque una
> actualización de Windows rompió un controlador de impresora fiscal. Fue el único cambio que ese código
> recibió en nueve años.
>
> **Y hay que decir en voz alta que eso hizo esta fase más barata**, porque si no, el curso vende una
> migración más fácil de la que el lector va a encontrar en su empresa. Desde 4.8, buena parte del camino
> está andado: 4.8 ya implementa casi toda la superficie de .NET Standard 2.0, así que las bibliotecas
> compartidas compilan para los dos mundos; el compilador ya es Roslyn; y el paquete de compatibilidad de
> Windows cubre la mayoría de lo que falta.
>
> **Lo que Cordillera no tuvo que hacer, y tu empresa quizás sí:** desde 4.5 hay que subir primero a
> 4.6.2 o más —porque .NET Standard 2.0 no está soportado por debajo—, revisar los cambios de
> comportamiento de cada salto intermedio (que son varios y están documentados), y en algunos casos
> reemplazar paquetes que no tienen versión compatible con 4.5. **Ese trabajo previo puede ser semanas**, y
> el curso no lo simula porque su ficción lo resolvió en 2021 con un parche de una tarde. Si vienes de
> 4.5, cuenta ese tramo aparte.

---

## 💻 5. Código mínimo con comentarios

### 5.1 El `.csproj`: de sesenta líneas a doce

```xml
<!-- ANTES: src/legacy/Sige.Billing/Sige.Billing.csproj (formato anterior al SDK) -->
<Project ToolsVersion="15.0" DefaultTargets="Build"
         xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <ProjectGuid>{A1B2C3D4-...}</ProjectGuid>
    <TargetFrameworkVersion>v4.8</TargetFrameworkVersion>
    <!-- … veinte propiedades más, la mitad con valores por omisión … -->
  </PropertyGroup>
  <ItemGroup>
    <Reference Include="System.Data" />
    <Reference Include="System.Configuration" />
    <!-- Y la referencia a un paquete, por RUTA RELATIVA a la carpeta packages\ -->
    <Reference Include="CrystalDecisions.CrystalReports.Engine">
      <HintPath>..\..\packages\CrystalReports.Engine.13.0.33\lib\net48\CrystalDecisions...dll</HintPath>
    </Reference>
  </ItemGroup>
  <ItemGroup>
    <!-- Cada archivo .cs, a mano. Agregar uno y olvidar esta línea produce el error
         "el tipo no existe" sobre código que está ahí, y es el clásico de 2017. -->
    <Compile Include="InvoiceService.cs" />
    <Compile Include="InvoiceCalculator.cs" />
    <Compile Include="Properties\AssemblyInfo.cs" />
  </ItemGroup>
  <Import Project="$(MSBuildToolsPath)\Microsoft.CSharp.targets" />
</Project>
```

```xml
<!-- DESPUÉS: src/modern/Sige.Billing/Sige.Billing.csproj -->
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <!-- Los archivos se incluyen por convención. El GUID no hace falta. Y el TargetFramework
         y el nullable vienen de ../Directory.Build.props, salvo uno: -->
    <RootNamespace>Sige.Billing</RootNamespace>

    <!-- 💸 El nullable queda DESACTIVADO en este proyecto, a propósito y declarado. Activarlo
         sobre 8.000 líneas de 2017 produce cientos de advertencias que nadie va a atender, y el
         umbral que la medición de la fase 02 determinó dice que por encima de cierta proporción
         de ruido no vale la pena. Es la misma decisión que el .editorconfig de legacy/, tomada
         de nuevo cuando el proyecto cruza la frontera. -->
    <Nullable>disable</Nullable>
    <TreatWarningsAsErrors>false</TreatWarningsAsErrors>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.Data.SqlClient" />
    <PackageReference Include="System.Configuration.ConfigurationManager" />
  </ItemGroup>

</Project>
```

**Detalles con intención**

- **El proyecto migrado se mueve de `src/legacy/` a `src/modern/`**, y eso no es cosmético: cambia de
  qué `Directory.Build.props` hereda. Por eso hay que **reafirmar `Nullable=disable` en el proyecto**, o
  heredaría las reglas del subárbol nuevo y se llenaría de errores.
- **`System.Data.SqlClient` → `Microsoft.Data.SqlClient`.** Es el cambio de paquete que más aparece: el
  primero está en mantenimiento y el segundo es el que recibe las mejoras. El cambio es mecánico —un
  `using`— **y tiene una trampa**: el nuevo es más estricto con el cifrado de la conexión por omisión, y
  una cadena de 2017 sin `Encrypt=False` o sin certificado válido **falla al conectar**. Es el primer
  error de casi toda migración, y no está en el informe de compatibilidad.
- **Nada de mejoras en este commit.** El diff de una migración tiene que ser legible; si lleva
  refactorizaciones adentro, nadie puede revisarlo y el `git bisect` del mes que viene no sirve.

### 5.2 El informe de compatibilidad, y las tres categorías que importan

```powershell
# La herramienta hace el 70%. Se corre primero, antes de estimar nada.
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze src\legacy\Sige.Billing\Sige.Billing.csproj
```

Y la salida se clasifica a mano en tres categorías, porque **la herramienta no distingue la tercera** y es
la peligrosa:

Cada caja es una categoría, y cada flecha va de la API heredada a lo que la reemplaza:

```mermaid
flowchart TB
    subgraph C1["1 · NO EXISTE — falla al compilar. Es la mejor de las tres: te enteras enseguida."]
        direction LR
        A1["System.Web.HttpContext"] --> R1["inyección explícita del contexto"]
        A2["System.ServiceModel (WCF servidor)"] --> R2["CoreWCF, o minimal APIs"]
        A3["AppDomain.CreateDomain"] --> R3["no hay equivalente; hay que rediseñar"]
        A4["CrystalDecisions.*"] --> R4["no existe para .NET moderno (ver 5.4)"]
    end
    subgraph C2["2 · EXISTE CON OTRA FORMA — falla al compilar y la conversión es mecánica."]
        direction LR
        B1["System.Data.SqlClient"] --> S1["Microsoft.Data.SqlClient"]
        B2["BinaryFormatter"] --> S2["System.Text.Json (y es una mejora)"]
        B3["Thread.Abort"] --> S3["CancellationToken (fase 05)"]
    end
    subgraph C3["3 · COMPILA Y REVIENTA — la categoría que la herramienta no marca ⚠️"]
        direction LR
        D1["ConfigurationManager.AppSettings"] --> T1["devuelve null. Silenciosamente."]
        D2["ConfigurationManager.ConnectionStrings"] --> T2["lo mismo, y es peor: la cadena"]
        D3["Registry.* (paquete de compat.)"] --> T3["existe; en no-Windows lanza en ejecución"]
        D4["System.Drawing.Common"] --> T4["existe; fuera de Windows, no"]
    end
    C1 ~~~ C2 ~~~ C3
    style C3 stroke:#d9534f,stroke-width:2px
```

**El patrón a memorizar**

> **Una API que no existe es buena noticia; una que compila y no funciona es el problema.** El paquete de
> compatibilidad de Windows existe para que el código viejo compile, y en varios casos su implementación
> **no hace nada** o lanza solo en cierto sistema operativo. La regla de esta fase: **ninguna API de la
> categoría 3 se deja como está.** O se reemplaza, o se envuelve con una comprobación que lance al
> arrancar. Un `null` silencioso en la cadena de conexión es peor que un fallo al iniciar.

```csharp
// Así se envuelve una API de la categoría 3, cuando reemplazarla ahora no toca.
// 🧬 Este archivo es el borde entre el modelo de configuración de 2017 y el de .NET 10.
internal static class LegacySettings
{
    /// <summary>
    /// Lee una clave de configuración. Si no está, **lanza al arrancar** en vez de devolver `null`
    /// y dejar que el `Path.Combine` de más abajo produzca una ruta relativa que acabe escribiendo
    /// en el directorio del proceso. Ese fue el incidente de los cuarenta PDF en System32.
    /// </summary>
    public static string Required(IConfiguration configuration, string key) =>
        configuration[key]
        ?? throw new InvalidOperationException(
            $"Falta la clave de configuración «{key}». En .NET Framework esto venía del App.config " +
            "y devolvía null en silencio; ahora falla al arrancar, que es lo correcto.");
}
```

### 5.3 Los ASMX de 2019, con el contrato intacto

El socio comercial lleva **siete años** consumiendo un `DataSet` serializado sobre SOAP. No se le puede
cambiar el contrato: es un tercero, tiene su propio cronograma, y "actualízate" no es una respuesta que
Cordillera pueda dar a quien representa el 14% de su facturación.

```csharp
// src/modern/Sige.Billing.Api/Program.cs
// La minimal API que reemplaza al ASMX, con el contrato compatible hacia atrás.
var builder = WebApplication.CreateBuilder(args);
WebApplication app = builder.Build();

// El endpoint nuevo, con el contrato que el curso quiere: JSON, tipos reales, versionado.
app.MapGet("/v1/invoices/{number}", async (string number, IInvoiceQueries queries, CancellationToken token) =>
    await queries.FindAsync(number, token) is { } invoice
        ? Results.Ok(invoice)
        : Results.NotFound());

// Y el de compatibilidad, que devuelve EXACTAMENTE lo que devolvía el ASMX: un DataSet
// serializado en XML con los nombres de columna del esquema de 1997.
//
// 🧬 Este endpoint es el borde con el socio comercial, y su forma no es negociable. Lo que sí es
//    negociable es cuánto tiempo vive: la fase 15 le pone una fecha de retiro y un encabezado que
//    la anuncia, que es la forma civilizada de retirar un contrato.
app.MapPost("/asmx-compat/ConsultarFactura", async (HttpRequest request, IInvoiceQueries queries, CancellationToken token) =>
{
    string number = await SoapEnvelope.ReadInvoiceNumberAsync(request.Body, token);
    DataSet legacyShape = await queries.FindAsLegacyDataSetAsync(number, token);

    // El DataSet se serializa con su esquema XML igual que antes. `WriteXml` sigue existiendo en
    // .NET 10 y produce el mismo formato — que es el único motivo por el que este endpoint es
    // posible sin reescribir el consumidor.
    return Results.Text(SoapEnvelope.Wrap(legacyShape), "text/xml");
});

app.Run();
```

**Detalles con intención**

- **Los dos endpoints conviven** y el viejo no está marcado como obsoleto todavía: retirarlo es una
  conversación comercial con fecha, no una decisión técnica. La fase 15 la tiene.
- **`DataSet.WriteXml` sigue existiendo**, y es la razón de que esto funcione. Es un ejemplo de por qué
  la compatibilidad de .NET importa: si ese método no se hubiera llevado, el endpoint de compatibilidad
  habría sido un serializador escrito a mano.
- **`BinaryFormatter` no se llevó**, y si el ASMX lo usara —no es el caso aquí— el contrato **no se
  podría reproducir** y habría que negociar con el socio. Es el tipo de cosa que el informe de
  compatibilidad encuentra en media hora y que una estimación por líneas de código no ve.

### 5.4 Crystal Reports, y las deudas que no se pagan

```text
Paquetes de packages.config, y qué les pasó:

  CrystalReports.Engine 13.0.33          → ❌ no tiene versión para .NET moderno
  Microsoft.ReportViewer.Common 12.0     → ❌ no tiene versión para .NET moderno
```

Aquí la fase toma una decisión y **declara que no la resuelve**:

> 💸 **Deuda declarada: dos paquetes sin equivalente, aislados tras una interfaz. Y no se paga en este
> curso.**
>
> Los dos son de reportes: Crystal Reports 13 genera los PDF de liquidación y los formatos fiscales, y
> tiene sus **propias conexiones a la base**, por fuera de la aplicación. Ninguno tiene versión para .NET
> moderno.
>
> Lo que esta fase hace: **aislarlos tras una interfaz** —`IReportRenderer`, con dos métodos— e
> implementarla en un **proceso aparte que sigue en .NET Framework 4.8**, invocado por línea de comandos.
> El módulo migrado no conoce Crystal; conoce la interfaz.
>
> ```csharp
> // El único contrato que el código nuevo conoce sobre los reportes.
> public interface IReportRenderer
> {
>     Task<byte[]> RenderAsync(string reportName, IReadOnlyDictionary<string, string> parameters, CancellationToken token);
> }
> // La implementación lanza Sige.Reports.exe —4.8, sin migrar— y lee su salida.
> ```
>
> **Y no se paga en este curso**, que es lo importante y es una respuesta que el lector va a tener que
> dar alguna vez: **la solución depende de un proveedor**. Las tres salidas reales son comprar una
> licencia del sucesor comercial si existe, reescribir los reportes con otra herramienta —que son
> semanas de trabajo de diseño gráfico, no de programación—, o dejar ese proceso en 4.8 indefinidamente,
> que es lo que hace la mayoría.
>
> El curso elige la tercera **y lo dice**: un proceso de 4.8 que genera PDF y que nadie toca es una
> dependencia estable, no una deuda urgente. Lo que sí hace falta es que el resto del sistema no
> dependa de Crystal directamente, y eso sí se resuelve aquí.

**Prueba de fuego**

```powershell
# Las tres cosas, en este orden.
msbuild src\Sige.sln /t:Rebuild /p:Configuration=Release     # lo que sigue en 4.8
dotnet build src\Cordillera.slnx -c Release                  # lo nuevo, ahora con Sige.Billing
dotnet test src\modern\Sige.Characterization.Tests -c Release # y las fotos de la fase 08
```

**Las fotos son el criterio.** Si pasan, la migración no cambió el comportamiento; si alguna falla, hay
que saber exactamente cuál y por qué **antes** de seguir.

Y la mentira que te va a contar la salida si miras el lugar equivocado: **todo compila y todas las
pruebas pasan, y el módulo falla al arrancar en el servidor**. Las pruebas usan la cadena de conexión del
contenedor de Testcontainers, que es local y sin cifrado; el servidor usa la cadena del `App.config` de
2017, que no dice nada de `Encrypt` — y `Microsoft.Data.SqlClient` **cifra por omisión** y exige un
certificado válido. Es el primer error de casi toda migración, no aparece en ningún informe de
compatibilidad, y se descubre en el primer despliegue.

---

## 📏 6. Medición

**Hipótesis:** el mismo módulo compilado para .NET 10 arranca más rápido y consume menos memoria que en
.NET Framework 4.8, y el tamaño del `publish` depende mucho más del **modo** de publicación que del
runtime. Lo que la medición tiene que separar es **cuánto de la mejora es el runtime y cuánto es el modo
de publicación**, porque se suelen atribuir juntas.

**Condiciones:** SDK 10.0.401 · .NET Framework 4.8 · Release · Windows 11 · el mismo módulo de
facturación, con la misma lógica y el mismo trabajo —emitir cien facturas contra la base del generador—
· 30 repeticiones con 5 de calentamiento descartadas · arnés propio, y el arranque medido desde el
proceso frío con la caché de disco limpia entre corridas.

**Competidores:** cuatro compilaciones del **mismo** código:

- **.NET Framework 4.8**, tal como está hoy. Es el statu quo y el competidor a vencer.
- **.NET 10 dependiente del framework** —el modo por omisión—, que necesita el runtime instalado.
- **.NET 10 autocontenido**, que lleva el runtime dentro.
- **.NET 10 autocontenido con recorte** (`PublishTrimmed`), para ver qué cuesta el tamaño.

> 📝 **AOT nativo no está en esta tabla, y es deliberado.** Es la fase 20, con el contenedor y la factura
> delante, y allí tiene su propia medición — porque el arranque en frío solo cuesta dinero cuando algo lo
> cobra por segundo.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 11 --cold-start
```

**Resultado:** ⏳ pendiente de ejecución en tu máquina.

| Compilación | Arranque en frío | Memoria de trabajo | Tamaño del publish | Emitir 100 facturas |
|---|---|---|---|---|
| .NET Framework 4.8 | ⏳ | ⏳ | ⏳ | ⏳ |
| .NET 10, dependiente del framework | ⏳ | ⏳ | ⏳ | ⏳ |
| .NET 10, autocontenido | ⏳ | ⏳ | ⏳ | ⏳ |
| .NET 10, autocontenido con recorte | ⏳ | ⏳ | ⏳ | ⏳ |

> ⚖️ **Veredicto** *(expectativa, todavía sin ejecutar — `formato-de-mediciones.md` §2.6)*. Se espera que
> .NET 10 arranque más rápido y use menos memoria que 4.8, y que el autocontenido pese **mucho** más en
> disco a cambio de no depender de un runtime instalado. En el trabajo real —emitir cien facturas— se
> espera que la diferencia sea **menor de lo que el titular sugiere**, posiblemente un empate, porque el
> tiempo lo domina la base de datos y no el runtime. Publicar ese empate es importante: **migrar el
> runtime no es una optimización de rendimiento**, y venderlo así es cómo se pierde credibilidad en la
> siguiente propuesta.
>
> **Los dos umbrales que tu ejecución tiene que determinar:** (1) **cuánto del arranque es el runtime y
> cuánto el modo de publicación**, comparando las tres filas de .NET 10 entre sí; y (2) **a partir de qué
> tamaño de despliegue el autocontenido deja de ser cómodo**, que es el número que la fase 20 necesita
> cuando el mismo artefacto tenga que caber en una imagen de contenedor.

---

## 🧱 7. Miniproyecto — migrar facturación completo, con la lista de lo que no se pudo

**El encargo**

Wilson, y es un encargo con una condición que parece menor y no lo es: *"Si vas a mover facturación a lo
nuevo, necesito dos cosas. Que el socio mexicano no se entere — llevan siete años consumiendo el mismo
servicio y si les cambia algo me llaman a mí, no a ti. Y necesito la lista de lo que quedó sin migrar,
por escrito, porque cuando alguien pregunte el año que viene «¿ya estamos en .NET 10?» la respuesta va a
ser «a medias» y quiero poder decir exactamente qué mitad."*

**Por qué duele**

Porque las dos condiciones tiran en direcciones opuestas. **Que el socio no se entere** obliga a
reproducir un contrato de 2019 —`DataSet` serializado en XML, con nombres de columna de 1997— desde un
runtime que no tiene la mitad de las piezas con que se construyó. Y **la lista de lo que no se pudo**
obliga a algo más incómodo que migrar: a decidir qué **no** se migra y defenderlo por escrito, que es lo
contrario del instinto de terminar el trabajo.

Y porque hay una tercera cosa que Wilson no pidió y que vas a descubrir: el módulo migrado **arranca bien
en tu máquina y no arranca en el servidor**.

**Datos de entrada**

El módulo de facturación tal como quedó en las fases 07 y 08:

| Qué | Detalle |
|---|---|
| `Sige.Billing` | ~8.000 líneas de C# de 2017: cálculo de factura, impuestos, anulación |
| Sus procedimientos | `SP_FACTURA_EMITIR` y `SP_FACTURA_ANULAR` — **no se tocan** |
| Sus pruebas de caracterización | Las de la fase 08, incluidas las dos que documentan defectos conocidos |
| `packages.config` | Dos paquetes, los dos de reportes, los dos sin sucesor |
| El ASMX de 2019 | `ConsultarFactura`, consumido por el socio mexicano desde hace siete años |
| Referencias a APIs de Framework | `ConfigurationManager` (11 sitios), `System.Data.SqlClient` (todo el acceso a datos), `CrystalDecisions` (3 sitios) |

**Criterios de aceptación**

1. `Sige.Billing` compila y corre en **.NET 10**, con su `.csproj` en formato SDK y sus paquetes en
   `PackageReference`.
2. **Las fotos de la fase 08 pasan sin cambios.** Si alguna falla, el commit explica exactamente cuál,
   por qué, y qué decisión se tomó — un fallo explicado es válido; uno sin explicar no.
3. El endpoint de compatibilidad devuelve **byte por byte** lo mismo que el ASMX de 2019 para tres
   facturas de prueba. Una prueba lo compara contra una respuesta capturada del servicio viejo.
4. **Ninguna API de la categoría 3 queda como está.** Una búsqueda en el repositorio lo demuestra: cada
   `ConfigurationManager` está reemplazado o envuelto con una comprobación que lanza al arrancar.
5. **Existe la lista de lo que no se pudo migrar**, con una fila por elemento: qué es, por qué no se
   pudo, qué haría falta, y **si se paga alguna vez o no**. La de Crystal Reports dice "no", con su razón.
6. **Medición de cierre:** las cuatro compilaciones de la tabla, con arranque en frío, memoria y tamaño.
   Van en el mensaje del tag `mini-11`.

**Restricciones de estilo y alcance**

🧬 Mixta durante toda la fase. El módulo migrado **conserva su estilo de 2017**: `Nullable=disable`,
advertencias no como errores, y ni una modernización de paso. **Migrar y refactorizar en el mismo commit
está prohibido** y es el criterio que hace revisable el diff.

Lo único que se escribe en estilo nuevo es lo que nace nuevo: el endpoint de compatibilidad, el borde de
configuración y la interfaz de reportes.

**La trampa**

`ConfigurationManager.ConnectionStrings["SigeConnection"]` **compila**. El paquete de compatibilidad lo
declara, así que el código de 2017 pasa sin una advertencia.

Y devuelve `null`.

Tu código va a hacer `.ConnectionString` sobre ese `null`, vas a tener un `NullReferenceException` al
arrancar, y lo vas a arreglar rápido porque es ruidoso. **Ese no es el problema.** El problema es el
hermano silencioso: `ConfigurationManager.AppSettings["RutaReportes"]` también devuelve `null`, y el
código de 2017 no lo comprueba — hace `Path.Combine(ruta, archivo)`, que con `null` produce una ruta
**relativa**, y el módulo escribe cuarenta PDF de liquidación en el directorio de trabajo del proceso.
Sin error, sin log, sin excepción.

Cuando lo encuentres —y la única forma de encontrarlo es buscarlo— haz dos cosas: envuelve **todas** las
lecturas de configuración para que fallen al arrancar, y escribe cuántos sitios eran. Ese número es el
argumento de por qué la categoría 3 del informe es la peligrosa.

Y la segunda trampa, la del servidor: tu módulo va a arrancar perfecto contra Testcontainers y **va a
fallar al conectar** contra el servidor de verdad. La causa no está en tu código ni en la configuración:
está en un valor por omisión que cambió entre los dos paquetes de acceso a datos.

<details><summary>Pista 1 — el enfoque</summary>

Tres pasos y en este orden: **analizar** antes de tocar nada —el informe da la estimación real—,
**convertir** el proyecto sin cambiar una línea de lógica, y **reemplazar** las APIs una categoría a la
vez, empezando por las que no compilan.

La lista de lo que no se pudo no se escribe al final: se escribe **mientras**, cada vez que decides no
resolver algo. Al final nadie recuerda las razones.

</details>

<details><summary>Pista 2 — la herramienta</summary>

`upgrade-assistant analyze` primero, y después `upgrade`:
`https://learn.microsoft.com/dotnet/core/porting/upgrade-assistant-overview`

Para las diferencias de comportamiento entre los dos paquetes de acceso a datos —incluida la del
cifrado por omisión, que es la trampa del servidor:
`https://learn.microsoft.com/sql/connect/ado-net/introduction-microsoft-data-sqlclient-namespace`

Y para el `DataSet` serializado del endpoint de compatibilidad, `DataSet.WriteXml` con
`XmlWriteMode.WriteSchema` — el modo importa, porque el consumidor de 2019 espera el esquema incluido.

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```csharp
// El borde de configuración: el único sitio que sabe que antes esto venía del App.config.
internal static class LegacySettings
{
    public static string Required(IConfiguration configuration, string key);
    public static string ConnectionString(IConfiguration configuration);
}

// El aislamiento de lo que no se pudo migrar. El código nuevo conoce esto y no conoce Crystal.
public interface IReportRenderer
{
    Task<byte[]> RenderAsync(string reportName, IReadOnlyDictionary<string, string> parameters, CancellationToken token);
}

// La lista de lo que no se pudo, como dato y no como documento suelto: así se puede publicar
// en la comprobación de salud de la fase 19 y nadie tiene que buscarla.
public sealed record UnmigratedItem(
    string What,
    string WhyNot,
    string WhatWouldBeNeeded,
    bool WillBePaid);
```

</details>

**Cómo se entrega**

```powershell
upgrade-assistant analyze src\legacy\Sige.Billing\Sige.Billing.csproj
dotnet build src\Cordillera.slnx -c Release
msbuild src\Sige.sln /t:Rebuild /p:Configuration=Release
dotnet test src\modern\Sige.Characterization.Tests -c Release
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 11 --cold-start
```

```bash
git tag -a mini-11 -m "Mini F11: facturación en .NET 10 · arranque <X> ms vs <Y> ms en 4.8 · publish <Z> MB · <N> APIs de categoría 3 envueltas · 2 paquetes sin migrar, declarados"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Corre `upgrade-assistant analyze` sobre `Sige.DataAccess` y clasifica su salida en las tres
   categorías de la sección 5.2. Anota cuántos elementos hay en cada una.
2. Convierte un `.csproj` viejo al formato SDK a mano, sin la herramienta, y cuenta las líneas que
   desaparecieron.
3. Cambia `System.Data.SqlClient` por `Microsoft.Data.SqlClient` en un proyecto y provoca el fallo de
   cifrado a propósito. Anota el mensaje exacto.
4. Lee una clave de configuración con `ConfigurationManager` en .NET 10 y demuestra con una prueba que
   devuelve `null`.
5. Convierte `packages.config` a `PackageReference` con la herramienta y compara los dos archivos.
   Señala qué información se perdió y qué se ganó.
6. Serializa un `DataSet` con `WriteXml` en 4.8 y en .NET 10 y compara los dos XML byte por byte.

**🟡 Intermedio (7–14)**

7. Escribe el borde de configuración que lanza al arrancar, y una prueba que verifica que el mensaje de
   error nombra la clave que falta.
8. Envuelve Crystal Reports tras `IReportRenderer` con la implementación que invoca al proceso de 4.8, y
   prueba el camino completo.
9. Migra `Sige.DataAccess` a .NET 10 **sin** activar nullable, y explica por qué reafirmar
   `Nullable=disable` en el `.csproj` es necesario cuando el proyecto se mueve a `src/modern/`.
10. Haz que el endpoint de compatibilidad y el nuevo devuelvan datos del mismo origen, y escribe la
    prueba que verifica que los dos dicen lo mismo con formas distintas.
11. Encuentra en `Sige.Billing` los once sitios que leen configuración y envuélvelos todos. Reporta el
    número y cuántos habrían producido un fallo silencioso.
12. Usa `dotnet list package --vulnerable` y `--outdated` sobre el proyecto migrado, y compara la
    información con la que daba `packages.config`.
13. Provoca a propósito que una foto de la fase 08 falle después de migrar, identifica la causa, y
    escribe la explicación que el commit necesitaría.
14. Publica el módulo en los tres modos —dependiente, autocontenido, con recorte— y compara los tamaños.
    Anota qué se rompió con el recorte, si algo se rompió.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** El módulo migrado arranca en local y falla en el servidor con un error de conexión.
    Escribe el procedimiento de diagnóstico completo: qué cambió entre los dos paquetes, cómo se
    confirma, y las dos formas de resolverlo con sus implicaciones de seguridad.
16. **Diagnóstico.** Después de migrar, los PDF de liquidación aparecen en `C:\Windows\System32`. Explica
    la cadena completa de causas, desde el `App.config` hasta el `Path.Combine`, y di en qué punto se
    corta con una sola línea de código.
17. **Medición.** Ejecuta la medición de la sección 6 completa y determina **los dos umbrales**. Publica
    el empate del trabajo real si lo hay, y explica por qué ese empate es el dato importante.
18. **Medición.** Mide el arranque en frío con la caché de disco limpia y con ella caliente, en los
    cuatro casos. Explica cuál de los dos números es el que importa para el servidor de Cordillera y
    cuál para la fase 20.
19. Escribe la lista completa de lo que no se pudo migrar de **todo SIGE** —no solo facturación— con sus
    cuatro columnas. Es el documento que Wilson pidió, y el que la fase 24 va a revisar.
20. **Decisión — ¿se migra, se envuelve o se deja quieto?** El proceso de reportes en 4.8 funciona y nadie
    lo toca. Decide si se deja indefinidamente, si se reescriben los reportes con otra herramienta, o si
    se compra el sucesor comercial. Sostén la decisión con el costo de las tres y con quién la firma.
21. **Decisión — ¿se migra, se envuelve o se deja quieto?** El endpoint de compatibilidad del socio
    mexicano funciona. Decide cuándo se retira, cómo se le comunica, y qué pasa si el socio no se mueve
    en el plazo. *(Y recuerda que representa el 14% de la facturación.)*

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Encuentra una API que en .NET 10 compile, no lance, y **haga algo distinto** de lo
    que hacía en 4.8 — ni error ni excepción, otro comportamiento. Escribe la prueba de caracterización
    que lo habría atrapado.
23. **Adversarial.** Consigue que el endpoint de compatibilidad devuelva un XML **casi** idéntico al del
    ASMX —que pase una revisión visual y falle en el consumidor—. Después escribe la prueba que lo
    detecta.
24. **Diseño.** Escribe el plan de migración de runtime de los cuatro módulos y los 340 formularios, con
    el orden por riesgo, qué convive con qué, y cuánto tiempo el sistema queda partido en dos runtimes.
    Incluye la respuesta a "¿y si nos quedamos así para siempre?".
25. **Defiende una decisión.** Clara pregunta qué ganó la empresa con esta fase, porque el sistema hace
    exactamente lo mismo que antes. Respóndele en media página, en su lenguaje, sin usar los números de
    rendimiento —que son un empate— y **sin decir que estaba viejo**.

**🔥 Opcionales**

- Investiga CoreWCF y escribe media página sobre si habría servido para el ASMX de Cordillera. Incluye
  qué habría cambiado para el socio mexicano.
- Prueba el módulo migrado sobre Linux en un contenedor y anota qué se rompe. **No lo arregles**:
  guárdalo para la fase 20, que es donde esa pregunta tiene sentido.
- Migra un proyecto desde **4.5** en vez de 4.8 —crea uno a propósito— y cronometra la diferencia. Es la
  forma de comprobar la obligación declarada de esta fase en vez de creerla.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://learn.microsoft.com/dotnet/core/porting/` — la guía de portabilidad completa: el orden, el
  análisis y las decisiones.
- `https://learn.microsoft.com/dotnet/core/porting/upgrade-assistant-overview` — la herramienta que hace
  el 70%.
- `https://learn.microsoft.com/dotnet/core/porting/net-framework-tech-unavailable` — **la lista oficial
  de lo que no se llevó**. Es la lectura que convierte una estimación en un número.
- `https://learn.microsoft.com/dotnet/core/compatibility/` — cambios de comportamiento entre versiones,
  que es donde vive la categoría 3.
- `https://learn.microsoft.com/sql/connect/ado-net/introduction-microsoft-data-sqlclient-namespace` — las
  diferencias entre los dos paquetes de acceso a datos, **incluido el cifrado por omisión**.
- `https://learn.microsoft.com/dotnet/core/deploying/` — los modos de publicación, que son tres respuestas
  distintas y se eligen con números.
- `https://learn.microsoft.com/dotnet/core/porting/third-party-deps` — cómo se evalúa una dependencia sin
  sucesor, que es la deuda de esta fase.
- `https://learn.microsoft.com/dotnet/framework/migration-guide/versions-and-dependencies` — qué trae cada
  versión de Framework. Es la lectura que respalda la obligación sobre 4.8 contra 4.5.

**Libros / artículos**

- La guía *Modernize existing .NET applications* de Microsoft es gratuita y cubre el camino completo,
  incluido el escritorio. Verifica el enlace y la edición: se ha reorganizado varias veces.

> ⚠️ Verifica las URLs. Y la advertencia propia de esta fase, que es doble. Primero: **mucho material de
> portabilidad apunta a .NET Core 3.1, a .NET 5 o a .NET 6**, y aunque el procedimiento es el mismo, las
> listas de APIs disponibles han cambiado a favor —cada versión llevó más cosas—, así que un documento de
> 2020 es **pesimista**. Segundo, y al contrario: **los tutoriales del Upgrade Assistant son optimistas**,
> porque muestran el 70% que la herramienta resuelve y no el 30% que queda.

**Orden de lectura sugerido:** antes de tocar nada, la lista de tecnologías no disponibles —media hora, y
te da la estimación real— y la guía de portabilidad. Durante el miniproyecto, la página del paquete de
acceso a datos y la de cambios de comportamiento. Al cerrar, la de modos de publicación: es la
preparación de la fase 20.

---

## 🚀 10. Cierre y conexión con la siguiente fase

**Aquí cierra el Bloque B**, que era el corazón del curso, y conviene mirar las cinco fases juntas porque
el valor está en el orden y no en cada una.

La 07 escribió el sistema y lo midió sin juzgarlo. La 08 puso la red **antes** de tocar nada, y encontró
una regla que llevaba nueve años liquidando mal. La 09 escribió el borde y midió las tres formas de
hablarle a un esquema hostil. La 10 puso una API en medio sin apagar nada y **ejecutó la vuelta atrás**.
Y la 11 movió el runtime, que resultó ser la parte fácil — y publicó la lista de lo que no se pudo.

Ese orden es la tesis del curso, y ahora se puede enunciar en una frase que la primera fase no habría
podido sostener: **se lee, se prueba, se mide, se corta y solo entonces se mueve** — y en cada paso se
puede volver atrás. La alternativa que el protagonista propuso el día once habría llegado al final de
dos años sin ninguna de las cinco cosas.

Y quedó algo que no está en ningún tag: tres de los cuatro módulos siguen en 4.8, un proceso de reportes
va a seguir ahí indefinidamente, y "el Fox" de Lima sigue mandando su archivo plano los viernes. **Nada
de eso es trabajo pendiente.** Es la respuesta *"se deja quieto"*, tomada tres veces con su razón escrita,
y la fase 24 la va a revisar con la factura en la mano.

La fase 12 abre el Bloque C con lo único del sistema que sigue sin tocarse: **los 340 formularios**. Y la
pregunta de ese bloque no es cómo migrarlos — es **si**. WinForms sobre .NET 10 sigue siendo una opción
legítima en 2026, y decirlo con la medición al lado es el tipo de veredicto que este curso existe para
producir. Empieza por lo más incómodo: qué cuesta de verdad salir de Framework cuando hay un diseñador
visual, controles de terceros y noventa equipos que hay que actualizar sin permisos de administrador.

> **La señal de que quedó bien:** *"Puedo decir qué parte del sistema está en .NET 10, qué parte no, y
> por qué cada una está donde está — y ninguna de las razones es «no hemos tenido tiempo»."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el miniproyecto
> corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-11 -m "F11 cerrada:
> - Sige.Billing en .NET 10, formato SDK, con las fotos de la F08 pasando
> - packages.config convertido, y los dos paquetes sin sucesor aislados tras IReportRenderer
> - informe de compatibilidad con sus tres categorias, y la 3 envuelta una por una
> - ASMX reemplazado con contrato compatible: el socio mexicano no se entero
> - la lista de lo que no se pudo migrar, con su razon y si se paga o no
> - dicho en voz alta: migrar desde 4.8 es mas facil que desde 4.5"
> ```
>
> **Esta fase cierra el Bloque B y planta la única deuda del curso que no se paga nunca:**
>
> ```bash
> git diff fase-07 fase-11 -- src/legacy/
> ```
>
> Ese diff es el resumen del bloque, y es más pequeño de lo que cualquiera esperaría: el sistema heredado
> **casi no se tocó**. Lo que cambió fue lo que hay a su alrededor — la red de pruebas, el borde, la API
> en medio, un módulo movido de runtime. Un sistema de treinta años que sigue facturando todos los días y
> al que se le cambió la arquitectura sin una ventana de parada: eso es lo que el tag `fase-11` marca.
>
> Y la deuda de los dos paquetes de reportes **queda declarada como no pagable en este curso**, con su
> razón: depende de un proveedor. Es una respuesta legítima y el lector va a tener que darla alguna vez.

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura.*

- **`INSTINTOS.md`** — dos entradas en la familia *datos y esquema*, o mejor en una familia nueva de
  *plataforma y runtime*: migrar por versión en vez de por riesgo, y creer que el código de negocio se
  reescribe. La segunda necesita **la tabla de porcentajes** —qué pasa sin tocarse, qué es mecánico, qué
  es el trabajo real— porque es lo que desmonta la estimación de dieciocho meses. Hay que decidir si se
  abre familia nueva; **recomendación: sí**, porque el Bloque C y la fase 20 van a aportar a ella.
- **`BENCHMARKS.md`** — entrada ⏳ *F11 · Cuatro compilaciones del mismo módulo*. El umbral del tamaño
  del publish **lo necesita la F20**, y el empate en el trabajo real es una de las entradas más
  importantes del archivo: es la que impide vender la migración como una mejora de rendimiento.
- **Deuda 💸 declarada como no pagable:** los dos paquetes de reportes sin sucesor. Ya está en el libro
  de §7.1 como "nunca". Conviene anotar allí **la forma concreta de la respuesta** —aislar tras una
  interfaz y dejar el proceso viejo corriendo— porque es la parte reutilizable de la decisión.
- **Deudas 💸 cobradas: el runtime 4.8 de la F07, parcialmente.** Un módulo de cuatro. Hay que anotar en
  el libro que esta deuda **se cobra en parte y a propósito**, y que las otras tres partes son decisión y
  no pendiente — si no, la tabla de deudas sugiere que quedó a medias por falta de tiempo.
- **Tipos y proyectos nuevos para el congelamiento:** `Sige.Billing` y `Sige.Billing.Api` (que nacen en
  `src/modern/` al migrar), `IReportRenderer`, `LegacySettings`, `UnmigratedItem`, `SoapEnvelope`. El
  movimiento de `src/legacy/` a `src/modern/` cuando un proyecto migra **tiene que quedar escrito en el
  árbol del congelamiento**, o la próxima fase no sabrá dónde buscar.
- **Para el Bloque C:** el ejercicio 🔥 de correr el módulo en Linux queda sin arreglar a propósito, y la
  F20 lo retoma. Y la decisión de `Nullable=disable` al cruzar la frontera es la misma que el Bloque C va
  a tener que tomar con los formularios.
- **Para la fase 19:** `UnmigratedItem` se diseñó como dato y no como documento **para que la
  comprobación de salud pueda publicarlo**. Si la 19 no lo recoge, esa decisión de diseño queda sin
  justificación.
- **Para la fase 24:** el ejercicio 19 —la lista completa de lo que no se migró— y el 24 —el plan de los
  cuatro módulos y los 340 formularios— son material directo del veredicto. Y el ejercicio 25 es el que
  más se parece a lo que la 24 tiene que responder.
- **Riesgo detectado:** esta fase mueve `Sige.Billing` de `src/legacy/` a `src/modern/` y eso cambia de
  qué `Directory.Build.props` hereda — lo cual está tratado en el texto, pero **la estructura de `src/`
  del congelamiento no contempla proyectos que cruzan**. Hay que decidir si un proyecto migrado se queda
  en `modern/` con su estilo viejo declarado (lo que la fase hace) o si hace falta un tercer subárbol.
  **Recomendación: `modern/` con `Nullable=disable` declarado**, porque un tercer subárbol sería un sitio
  donde esconder código que nadie termina de migrar.
