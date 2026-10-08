# ⚖️ Fase 14 — WinUI 3, Blazor Hybrid y el veredicto del escritorio

> C# para desarrolladores Java senior · Fase 14 de 24 · Bloque C — el escritorio
> Depende de: 13 · Habilita: 15
> Estilo de esta fase: **nuevo** (.NET 10, C# 14)
> Proyecto que avanza: **SIGE cliente**. Al terminar existe el prototipo en WinUI 3, está medido el
> despliegue a noventa equipos, y **está publicada la tabla del veredicto con tres columnas llenas y la
> cuarta declarada pendiente**.

---

## 🎯 1. Propósito

Decidir. Y decidir con una tabla que alguien pueda firmar, no con una preferencia.

Las fases 12 y 13 construyeron dos opciones y las midieron. Esta construye la tercera —un prototipo en
WinUI 3—, mide lo que ninguna de las dos midió todavía —**el despliegue a noventa equipos sin permisos de
administrador**— y pone las cuatro opciones en la misma tabla con los mismos cinco criterios.

> 🧭 **La medición es la fase.** No es el cierre: es el contenido. Todo lo demás —el prototipo, el
> empaquetado, las secciones de concepto— existe para llenar celdas de una tabla que después se firma.

Y hay una columna que decide, y no es ninguna de las técnicas: **quién lo puede mantener cuando tú te
vayas**. Tiene nombre propio y se llama Duván.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Existe el **prototipo en WinUI 3** del mismo formulario de existencias: búsqueda, grilla, resumen.
      Lo justo para medirlo con los mismos criterios que las otras dos.
- [ ] Existe el **prototipo en Blazor Hybrid** del mismo formulario, al mismo nivel.
- [ ] Está **medido, no estimado**, el despliegue de las tres opciones a noventa equipos sin permisos de
      administrador, incluido el depósito de Lima.
- [ ] 💸 **Se cobra la deuda de la fase 13**: la virtualización que se pierde en silencio, medida con
      50.000 filas en las tres opciones. La deuda se cobra **midiendo el error**, no arreglándolo.
- [ ] **La tabla del veredicto está publicada**, con cinco criterios, tres columnas llenas y **la cuarta
      —la web— declarada pendiente con su fecha**, no vacía y no estimada.
- [ ] La metodología está **congelada por escrito**: los cinco criterios, el módulo medido y las
      condiciones de red, para que la fase 18 complete la columna sin rediscutirla.
- [ ] Existe una **recomendación firmada** para Cordillera, con su razón, y dice qué la haría cambiar.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Construir la cuarta opción.** La web nace en la **fase 18**, con Blazor Server, WebAssembly y MVC
  medidos desde tres países. Esta fase **no la estima**: declara la columna pendiente con su criterio ya
  definido, y la 18 la rellena.
- **MAUI.** Queda fuera con su razón escrita: su caso de uso es la aplicación multiplataforma con móvil, y
  Cordillera necesita noventa equipos Windows en tres oficinas. Meterlo en la tabla sería agregar una
  opción que nadie va a elegir para inflar la comparación.
- **Rediseñar la interfaz.** Los prototipos reproducen el formulario que existe. Un rediseño es un
  proyecto aparte y contaminaría la comparación: no se puede medir una tecnología contra otra si una
  además cambia la pantalla.
- **Migrar los 339 formularios restantes.** Esta fase produce la **decisión**; el plan es lo que sigue, y
  la fase 24 lo revisa.
- **Observabilidad del cliente** → fase 19.

---

## 🧠 4. Concepto mínimo

### Las cuatro opciones, en una línea cada una

**WinForms sobre .NET 10** (fase 12). Lo que hay, movido de runtime. Soportado, con diseñador, sin
novedades. 340 formularios que funcionan y una persona que los domina.

**WPF con MVVM** (fase 13). Interfaz de escritorio moderna, con binding y lógica comprobable. Más arranque,
más fluidez con volumen, y una clase de fallo nueva que el compilador no ve.

**WinUI 3** (esta fase). La plataforma de interfaz actual de Windows: el mismo XAML conceptual que WPF, con
el motor de composición nuevo, controles alineados con el aspecto del sistema, y empaquetado propio. Es la
opción que un lector diría "la moderna".

**Web** (fase 18). Nada que instalar, un servidor que tiene que estar disponible, y la conexión del depósito
de Lima como variable.

### Los cinco criterios, y por qué son esos

Aquí está la decisión metodológica de la fase, y hay que tomarla antes de medir o la tabla acaba midiendo lo
que fue fácil de medir:

**1. Arranque en frío.** Porque noventa personas abren la aplicación cada mañana y varias la reabren después
de almorzar. Cuatro segundos contra uno no es una molestia: son cuatro minutos al día en la oficina.

**2. Memoria después de una jornada.** No al arrancar: **a las ocho horas**, con la ventana abierta y
consultas cada tanto. Es el caso real y es el que una demo de cinco minutos no encuentra.

**3. Comportamiento con 50.000 filas.** El volumen del histórico de Bogotá. Y no solo el pintado: la
fluidez al desplazar, que es lo que el usuario siente.

**4. Despliegue a noventa equipos sin permisos de administrador.** Con el depósito de Lima incluido. **Es
el criterio donde el prototipo bonito deja de competir**, y por eso no se deja para el final.

**5. Quién lo puede mantener.** La columna que decide. No es "qué tan difícil es la tecnología": es si
**Duván** —que lleva nueve años sosteniendo el sistema, es autodidacta, y va a seguir aquí cuando el lector
se vaya— puede abrir una pantalla, cambiar un ancho de columna, y desplegar. Una opción que él no pueda
mantener es una opción que dura lo que dure el lector.

> 🧭 **El criterio 5 puede vencer a los cuatro primeros juntos, y eso no es una concesión sentimental.** Es
> aritmética de riesgo: una plataforma que el único compañero no domina tiene una probabilidad alta de
> quedar congelada el día que el lector se va, y una pantalla congelada que nadie puede tocar cuesta más que
> dos segundos de arranque.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**Primera: elegir por modernidad.**

```text
❌ El razonamiento, y es tan común que casi no se nota que es un razonamiento:
   "WinForms es de 2002, WPF de 2006, WinUI 3 es la plataforma actual de Windows.
    Si vamos a invertir en migrar, invirtamos en la más nueva — así no hay que
    volver a hacerlo en cinco años."
```

Suena a prudencia y es una apuesta. **Por qué falla:** porque "la más nueva" no es una propiedad del
resultado, es una propiedad del calendario. WPF era "la más nueva" en 2006 y no reemplazó a WinForms;
Silverlight era "la más nueva" en 2009 y no existe; UWP era "la más nueva" en 2015 y su sucesor es
justamente WinUI 3. **La tecnología que sobrevivió a tres sucesores anunciados es la que sigue ahí**, y eso
es evidencia, no nostalgia.

Y falla por una segunda razón más concreta: *"así no hay que volver a hacerlo en cinco años"* asume que
migrar es un costo único. Con 340 formularios, migrar es un costo de **años**, y durante esos años hay dos
tecnologías conviviendo y dos personas manteniéndolas.

**Segunda, y es la que esta fase mide: suponer que lo nuevo despliega mejor.**

```text
❌ La suposición: "WinUI 3 es la plataforma moderna, así que el despliegue también
    será más moderno y más simple."
```

**Por qué falla:** porque es al revés, y es contraintuitivo. WinUI 3 se empaqueta con MSIX, que es
tecnología de 2018 y bastante más limpia que ClickOnce — **y necesita un certificado de firma de código en
el que los noventa equipos confíen**. Conseguir eso en Cordillera significa comprar un certificado, o
instalar uno propio en noventa equipos, y las dos cosas requieren exactamente lo que no hay: **permisos de
administrador y una gestión con sistemas de tres oficinas**.

Mientras que ClickOnce —tecnología de 2002, que nadie llamaría moderna— **instala sin permisos de
administrador** porque fue diseñada precisamente para eso, en una época en que los usuarios corporativos no
los tenían. La restricción de 2002 sigue siendo la restricción de 2026.

> ⚰️ **Autopsia del anti-patrón: el prototipo que no se pudo instalar.**
>
> **El caso, y es el más común de este bloque:** alguien construye el prototipo en la tecnología nueva en
> dos días, lo presenta, se ve mejor que lo que hay, y la reunión termina con un "adelante".
>
> **Lo que pasa después:** el empaquetado necesita firma, la firma necesita un certificado, el certificado
> necesita una compra o una instalación en noventa equipos, y la instalación necesita permisos que Wilson
> ya intentó conseguir dos veces. Tres semanas de gestión, y el proyecto no ha avanzado una pantalla.
>
> **El costo medido:** el prototipo se hizo en dos días; ponerlo en un equipo que no fuera el del
> desarrollador llevó tres semanas. **La proporción es de uno a diez**, y la reunión donde se decidió no
> tenía ese dato porque nadie lo había medido.
>
> **La defensa:** medir el despliegue **antes** de la reunión, no después. Es el criterio 4 y por eso esta
> fase lo pone en la tabla con el mismo peso que el arranque.

### 🩻 Esto sí funciona igual

El criterio de evaluación. Todo lo que sabes de elegir tecnología en un equipo con restricciones se
transfiere entero: que la decisión se toma por el costo total y no por la sintaxis, que el soporte a largo
plazo es un dato duro, que quién lo mantiene pesa más que cualquier benchmark, y que una comparación sin
números es una preferencia con vocabulario técnico.

Y se transfiere una cosa más, que es la que hace bueno a un senior en esta conversación: **saber que la
respuesta puede ser "lo que ya tenemos"**, y saber defenderla sin que parezca pereza. Eso no se aprende en
un curso de tecnología; se aprende habiendo visto dos reescrituras que no terminaron.

### 📖 Diccionario de traducción — las cuatro opciones desde el mundo Java

| Si vienes de… | La opción equivalente aquí | Dónde se rompe el paralelo |
|---|---|---|
| Swing con `.jar` desplegado en red | **WinForms + ClickOnce** | ClickOnce **sigue vivo y soportado**, a diferencia de Java Web Start |
| JavaFX con FXML y binding | **WPF con MVVM** | El binding se resuelve por nombre en tiempo de ejecución: un nombre mal escrito **no lo atrapa el compilador** |
| JavaFX empaquetado con `jpackage` | **WinUI 3 + MSIX** | MSIX **necesita firma de código**; `jpackage` produce un instalador que no la exige |
| aplicación web con Spring MVC | **la web de la fase 18** | Y trae de vuelta una variable que el escritorio no tenía: **la conexión de Lima** |
| Electron | **Blazor Hybrid** | Mismo modelo —web dentro de una ventana nativa— con el código en C# en vez de JavaScript, y sin empaquetar un navegador entero |
| "usamos la última versión del framework" | — | **No hay equivalente y es el punto:** aquí la "última" ha cambiado cuatro veces y la de 2002 sigue soportada |

> 📝 **Nota de ecosistema, y es la que sostiene el veredicto.** La genealogía de la interfaz de Windows tiene
> cuatro generaciones y **ninguna mató a la anterior**: WinForms (2002) sigue soportada en .NET 10; WPF
> (2006) fue anunciada como su sucesora y tampoco la reemplazó; UWP (2015) fue la siguiente apuesta y hoy su
> camino es WinUI 3; y WinUI 3 (2021) es la plataforma actual. Cuatro generaciones en veinticuatro años, y
> las tres primeras **con soporte vigente**.
>
> Eso no significa que WinUI 3 vaya a fracasar: significa que **"es la plataforma actual" no es un
> argumento suficiente**, porque las tres anteriores también lo fueron. El argumento suficiente es una tabla
> con cinco criterios — y por eso la fase existe.

---

## 💻 5. Código mínimo con comentarios

### 5.1 El prototipo de WinUI 3, y en qué se parece a WPF

```xml
<!-- src/modern/Sige.WinUI/StockPage.xaml -->
<!-- El XAML es reconociblemente el mismo lenguaje que WPF, con otro conjunto de controles. Si
     vienes de la fase 13, esto no tiene nada nuevo — y ese es un dato de la tabla: la curva de
     aprendizaje de WPF a WinUI 3 es corta. -->
<Page x:Class="Sige.WinUI.StockPage"
      xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

  <Grid Padding="12" RowSpacing="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto" />
      <RowDefinition Height="*" />
      <RowDefinition Height="Auto" />
    </Grid.RowDefinitions>

    <StackPanel Orientation="Horizontal" Spacing="8">
      <ComboBox ItemsSource="{x:Bind ViewModel.Warehouses}"
                SelectedItem="{x:Bind ViewModel.SelectedWarehouse, Mode=TwoWay}" Width="220" />
      <TextBox Text="{x:Bind ViewModel.SearchText, Mode=TwoWay}" Width="300" />
      <Button Content="Consultar" Command="{x:Bind ViewModel.LoadCommand}" />
    </StackPanel>

    <!-- Y aquí está la primera diferencia que importa: WinUI 3 no trae DataGrid. No existe en la
         plataforma, y hay que usar un control de la comunidad o un ItemsRepeater a mano.
         Para una aplicación con 340 formularios de rejillas, eso no es un detalle: es una
         dependencia externa en el control más usado del sistema. Va a la tabla. -->
    <ItemsView Grid.Row="1" ItemsSource="{x:Bind ViewModel.Rows}" />

    <TextBlock Grid.Row="2" Text="{x:Bind ViewModel.Status, Mode=OneWay}" />
  </Grid>
</Page>
```

**Detalles con intención**

- **`x:Bind` en vez de `Binding`**, y es una mejora real de WinUI 3: se resuelve **en compilación**, así que
  un nombre mal escrito **es un error de compilación**. Eso arregla exactamente la trampa de la fase 13, y
  es un punto a favor de WinUI 3 que la tabla tiene que registrar.
- **`Mode=OneWay` explícito** porque `x:Bind` por omisión es `OneTime` — al contrario que `Binding`. Es el
  primer tropiezo de quien llega de WPF, y es el tipo de diferencia pequeña que multiplica por 340 pantallas.
- **No hay `DataGrid`**, y es el hallazgo técnico de la fase. El control más usado de SIGE no existe en la
  plataforma nueva, así que hay que traerlo de la comunidad o escribirlo. **Eso es una dependencia externa en
  el corazón del sistema**, y va a la tabla con su nombre.
- **El modelo de vista se reusa tal cual.** `StockViewModel` de la fase 13 no tiene WPF adentro, así que
  funciona aquí sin cambios. Es el beneficio no planeado del patrón, y es el dato que hace que la curva de
  WPF → WinUI 3 sea corta.

### 5.2 El prototipo de Blazor Hybrid, que reusa más de lo que parece

```csharp
// src/modern/Sige.Hybrid/MainWindow.xaml.cs
// Blazor Hybrid: una ventana nativa con un componente web adentro, y el código en C#. El modelo
// mental es el de Electron sin empaquetar un navegador: usa el motor de WebView2 que Windows ya
// tiene instalado.
public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();

        var services = new ServiceCollection();
        services.AddWpfBlazorWebView();

        // Y el mismo modelo de vista otra vez. Tercera tecnología, mismo tipo, sin cambios: es la
        // mejor noticia del bloque y no estaba planeada.
        services.AddSingleton<IInventoryClient, InventoryApiClient>();
        services.AddTransient<StockViewModel>();

        Resources.Add("services", services.BuildServiceProvider());
    }
}
```

```razor
@* src/modern/Sige.Hybrid/Components/StockView.razor
   El componente, que es el MISMO que la fase 18 va a servir por web. Eso es lo que hace
   interesante a Blazor Hybrid en esta comparación: la cuarta columna de la tabla y esta tercera
   comparten implementación. *@
@inject StockViewModel ViewModel

<div class="toolbar">
    <select @bind="ViewModel.SelectedWarehouse">
        @foreach (WarehouseCode warehouse in ViewModel.Warehouses) { <option>@warehouse</option> }
    </select>
    <input @bind="ViewModel.SearchText" @bind:event="oninput" />
    <button @onclick="ViewModel.LoadCommand.ExecuteAsync"
            disabled="@(!ViewModel.LoadCommand.CanExecute(null))">Consultar</button>
</div>

@* Y la diferencia de rendimiento del bloque: aquí no hay virtualización por omisión. Con 50.000
   filas hay que usar <Virtualize>, y olvidarlo produce 50.000 nodos en el DOM — que es peor que
   cualquiera de los otros tres casos. La medición lo va a mostrar. *@
<Virtualize Items="ViewModel.Rows" Context="row">
    <div class="row">@row.Edition · @row.Title · @row.Quantity.ToString("N0")</div>
</Virtualize>

<p>@ViewModel.Status</p>
```

**El patrón a memorizar**

> **El modelo de vista sin dependencias de interfaz sirvió para tres tecnologías distintas sin un cambio.**
> Ese es el retorno real de MVVM y **no era el que la fase 13 prometía**: prometía comprobabilidad, y de
> paso trajo portabilidad. Cuando una decisión de diseño paga dos veces, conviene notarlo — y también
> conviene no generalizar: pagó aquí porque las cuatro opciones son .NET, y con una web en otro lenguaje no
> habría pagado nada.

### 5.3 El despliegue, medido y no supuesto

```powershell
# WinForms y WPF: ClickOnce, autocontenido, sin permisos de administrador.
dotnet publish src\modern\Sige.Desktop -c Release -r win-x64 --self-contained true
mage -New Application -Processor amd64 -FromDirectory .\publish -ToFile Sige.exe.manifest

# WinUI 3: MSIX, y aquí empieza el problema.
dotnet publish src\modern\Sige.WinUI -c Release -r win-x64 -p:GenerateAppxPackageOnBuild=true
# ⚠️ El paquete resultante NO SE INSTALA sin un certificado en el que el equipo confíe.
#    Las tres opciones:
#      a) certificado comercial de firma de código   → compra anual, y hay que renovarlo
#      b) certificado propio instalado en 90 equipos  → requiere permisos de administrador
#      c) modo de desarrollador activado en 90 equipos → requiere permisos de administrador
#
#    Ninguna de las tres es gratis y dos requieren exactamente lo que no hay.
```

**Detalles con intención**

- **Las tres opciones de certificado están escritas con su costo**, porque el error de esta decisión no es
  técnico: es descubrir en la semana tres que hace falta una compra que nadie presupuestó.
- **ClickOnce no necesita nada de eso.** Firma el manifiesto con un certificado autofirmado y Windows lo
  acepta para instalación por usuario. Es la razón por la que una tecnología de 2002 gana el criterio 4.
- **Y el tamaño importa por Lima:** setenta megas por equipo son 6,3 GB para noventa, y la conexión del
  depósito es la que es. El número exacto es la última columna de la tabla de despliegue.

---

## 📏 6. Medición

**Esta es la fase.** Todo lo anterior existe para llenar esta tabla.

**Hipótesis:** ninguna de las cuatro opciones gana en los cinco criterios, y la que gana en los criterios
técnicos **no es la que gana en los dos últimos** —despliegue y mantenibilidad—, que son los que deciden en
una empresa de dos desarrolladores.

**Condiciones:** SDK 10.0.401 · Release · Windows 11 · **el mismo formulario de existencias** en las cuatro
—búsqueda, grilla, resumen, contra la misma API— · base del generador, semilla `19970417`, grilla con
**50.000 filas** · arranque en frío en un equipo **sin SDK instalado**, caché de disco limpia · memoria
medida **a las ocho horas** con una consulta cada cinco minutos · despliegue medido a los noventa equipos
reales de las tres oficinas, **incluido el depósito de Lima** · 20 repeticiones con 3 de calentamiento
descartadas para lo que se repite; el despliegue y la jornada, una vez cada uno con su fecha.

> 🧭 **La metodología queda congelada aquí**, y esta sección es el contrato con la fase 18: **los cinco
> criterios, el módulo medido —el formulario de existencias—, el volumen —50.000 filas—, las condiciones de
> red —las tres oficinas, con la de Lima como caso adverso— y la forma de medir la memoria —a las ocho
> horas—**. La fase 18 completa la cuarta columna **con estas mismas condiciones y sin rediscutirlas**. Es
> la única actualización retroactiva que el curso permite y está declarada en los dos sitios
> (`propuesta-fases-y-alcance.md` §8).

**Competidores:** las cuatro opciones. Tres se miden aquí; la cuarta se declara pendiente.

**Los comandos:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 14 --rows 50000 --cold-start
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 14 --soak 8h
dotnet run -c Release --project src\modern\Cordillera.Ops -- deploy --measure --offices bog,mex,lim
```

**Resultado:** ⏳ pendiente de ejecución en tu máquina.

### 📋 La tabla del veredicto

| Criterio | WinForms (.NET 10) | WPF + MVVM | WinUI 3 | Web (Blazor) |
|---|---|---|---|---|
| **1. Arranque en frío** | ⏳ | ⏳ | ⏳ | 🔜 **fase 18** |
| **2. Memoria a las 8 horas** | ⏳ | ⏳ | ⏳ | 🔜 **fase 18** |
| **3. 50.000 filas: pintado / fluidez** | ⏳ | ⏳ | ⏳ | 🔜 **fase 18** |
| **4. Despliegue a 90 equipos sin permisos** | ⏳ | ⏳ | ⏳ | 🔜 **fase 18** |
| **5. Quién lo puede mantener** | ⏳ | ⏳ | ⏳ | 🔜 **fase 18** |

> 📝 **Dónde vive esta tabla.** La versión consolidada está en
> [`BENCHMARKS.md`](BENCHMARKS.md), y es la que la fase 18 completa. Esta copia es la que se lee aquí, con
> su columna pendiente: **la fase 18 no edita este documento**, agrega la columna en la entrada
> consolidada. Es la decisión que evita el único caso del curso en que una fase tendría que reescribir el
> material publicado de otra.

> ⚠️ **La cuarta columna está declarada pendiente, no vacía y no estimada.** La web nace en la fase 18 y
> hasta entonces **cualquier número en esa columna sería inventado**. El veredicto de abajo es por tanto
> **provisional y explícitamente parcial**, con su fecha de completado. Si al entrar la cuarta columna el
> veredicto cambia, **la fase 18 lo dice y explica qué lo movió** — un veredicto que cambia con un dato
> nuevo no es un error del curso: es el curso funcionando.

### Las tablas de respaldo

**A · Los tres criterios técnicos, con su detalle**

| Opción | Arranque en frío | Memoria inicial | Memoria a 8 h | Pintado 50.000 | Fluidez al desplazar |
|---|---|---|---|---|---|
| WinForms, modo virtual | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| WPF, virtualización sana | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| WPF, **virtualización rota** 💸 | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| WinUI 3 | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Blazor Hybrid, con `<Virtualize>` | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Blazor Hybrid, **sin `<Virtualize>`** | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |

> 💸 **La tercera fila es el cobro de la deuda de la fase 13**, y se cobra **midiendo el error** en vez de
> arreglándolo: cuánto cuesta que la virtualización de WPF se pierda en silencio. La sexta es su
> equivalente en Blazor, y las dos juntas dicen algo que ninguna dice sola: **las dos tecnologías que
> virtualizan tienen una forma de dejar de hacerlo sin avisar.** La factura:
> `git diff fase-13 fase-14 -- src/modern/Sige.Desktop/Views/`.

**B · Despliegue a noventa equipos — el criterio 4, en detalle**

| Opción | Empaquetado | Tamaño | Necesita permisos de administrador | Certificado | 90 equipos | Desde Lima |
|---|---|---|---|---|---|---|
| WinForms | ClickOnce autocontenido | ⏳ | **No** | autofirmado basta | ⏳ | ⏳ |
| WPF | ClickOnce autocontenido | ⏳ | **No** | autofirmado basta | ⏳ | ⏳ |
| WinUI 3 | MSIX | ⏳ | **Sí**, salvo con certificado de confianza | **comercial o instalado** | ⏳ | ⏳ |
| Blazor Hybrid | ClickOnce o MSIX | ⏳ | según empaquetado | según empaquetado | ⏳ | ⏳ |

**C · El criterio 5 — quién lo puede mantener**

No se mide con el arnés, y por eso conviene decir **cómo sí se mide**: con cuatro preguntas verificables
sobre la persona que va a quedarse con esto.

| Pregunta | WinForms | WPF | WinUI 3 | Web |
|---|---|---|---|---|
| ¿Hay diseñador visual? | **Sí** | parcial | parcial | no aplica |
| ¿Puede Duván cambiar un ancho de columna sin ayuda? | ⏳ | ⏳ | ⏳ | 🔜 **fase 18** |
| ¿Puede desplegar una corrección él solo? | ⏳ | ⏳ | ⏳ | 🔜 **fase 18** |
| ¿Cuánto le costó entender el prototipo? *(medido en horas, preguntándole)* | ⏳ | ⏳ | ⏳ | 🔜 **fase 18** |
| ¿Se puede contratar a alguien que lo sepa, en Bogotá? | ⏳ | ⏳ | ⏳ | 🔜 **fase 18** |

> 📝 **La cuarta fila se mide preguntándole a Duván y cronometrando**, y eso es una medición legítima
> aunque no salga del arnés: es reproducible, tiene condiciones, y responde la pregunta. Inventarla sería
> lo que este curso prohíbe; omitirla porque "no es técnica" sería peor, porque **es la que decide**.

> ⚖️ **Veredicto provisional** *(expectativa, todavía sin ejecutar — `formato-de-mediciones.md` §2.6, y
> parcial hasta la fase 18)*.
>
> Se espera que **WinForms gane el arranque y el despliegue**, que **WPF gane la fluidez y la
> comprobabilidad**, que **WinUI 3 gane la apariencia y el binding comprobado en compilación** —que es una
> ventaja real sobre WPF— **y pierda el criterio 4 por el certificado**, y que Blazor Hybrid quede en medio
> con la ventaja de compartir implementación con la cuarta columna.
>
> **Los tres umbrales que tu ejecución tiene que determinar:** (1) **cuántos segundos de arranque de más
> justifican un cambio de tecnología**, que es una pregunta de negocio y no técnica; (2) **cuánto cuesta el
> certificado de MSIX**, en dinero y en gestión, que es el número que puede descalificar a WinUI 3 sin
> discutir una sola línea de código; y (3) **cuántas horas le cuesta a Duván cada opción**, que es la
> columna 5 convertida en número.
>
> **Y el veredicto no está prejuzgado.** Si los números dicen WinForms, el veredicto dice WinForms — y no
> como concesión: como resultado. Si dicen WPF, dice WPF. La fase está escrita para que las tres respuestas
> sean posibles, y la recomendación del miniproyecto es la que sale de **tus** números, no de los míos.

---

## 🧱 7. Miniproyecto — el prototipo en WinUI 3 y la tabla de decisión firmada

**El encargo**

Clara, y es el encargo más corto del curso: *"Necesito una hoja. Una, no diez. Que diga qué recomiendas
para los formularios, por qué, qué cuesta, y qué tendría que pasar para que la recomendación cambie. Y que
la pueda leer alguien que no es ingeniero — porque la voy a llevar a la junta y ahí no hay ninguno."*

**Por qué duele**

Porque una hoja obliga a decidir qué se queda fuera, y porque la última pregunta es la difícil: *"qué
tendría que pasar para que la recomendación cambie"*. Una recomendación sin esa frase es una opinión
disfrazada; con esa frase, es una decisión que se puede revisar cuando llegue un dato nuevo — y va a llegar
uno en la fase 18.

Y porque hay una tentación grande: recomendar la opción que te gustó más de escribir. Las tres son
agradables de programar, y ninguna de las cinco columnas pregunta eso.

**Datos de entrada**

| Qué | De dónde sale |
|---|---|
| Arranque, memoria y fluidez de WinForms | **Fase 12** — no se vuelve a medir |
| Arranque, memoria y fluidez de WPF | **Fase 13** — no se vuelve a medir |
| Costo de la virtualización rota | **Fase 13**, cobrado aquí midiendo |
| Lo mismo para WinUI 3 y Blazor Hybrid | Esta fase |
| Despliegue de las tres | Esta fase, con los noventa equipos reales |
| Las cuatro preguntas del criterio 5 | Esta fase, **preguntándole a Duván y cronometrando** |
| La cuarta columna | **Fase 18** — declarada pendiente, con su fecha |

**Criterios de aceptación**

1. Existe el prototipo en WinUI 3 del formulario de existencias, funcionando contra la misma API, con
   búsqueda, grilla y resumen. **Lo justo para medirlo**: no es una aplicación terminada.
2. Existe el prototipo en Blazor Hybrid al mismo nivel, y **reusa `StockViewModel` sin cambios** — o si tuvo
   que cambiarlo, está documentado qué y por qué.
3. **El despliegue está medido en las tres opciones**, con los noventa equipos, incluido Lima. Si alguna no
   se pudo instalar, **eso es el resultado** y se reporta con su causa.
4. La **tabla del veredicto está completa en sus tres columnas**, con la cuarta marcada 🔜 y su fecha de
   completado. Ninguna celda pendiente lleva un número.
5. La **metodología está congelada por escrito** en un párrafo que la fase 18 pueda seguir: criterios,
   módulo, volumen, condiciones de red y forma de medir la memoria.
6. Existe **la hoja para Clara**: una página, en su lenguaje, con la recomendación, su costo, y **qué
   tendría que pasar para que cambiara**.

**Restricciones de estilo y alcance**

Código nuevo. Los prototipos son **prototipos**: lo mínimo para llenar las celdas, y está bien que se vean
sin terminar. Escribir una aplicación completa en cada tecnología convertiría la fase en tres fases y
contaminaría la comparación con decisiones de acabado.

**No se rediseña la pantalla.** Las cuatro reproducen el formulario que existe, porque una comparación donde
una opción además mejora la interfaz no mide tecnología: mide dos cosas a la vez.

**La trampa**

El prototipo de WinUI 3 te va a salir en una tarde y te va a gustar. `x:Bind` comprobado en compilación
arregla la trampa de la fase 13, los controles se ven como el sistema, y el XAML es el que ya conoces.

Y **no lo vas a poder instalar en el equipo de Nohora**.

No por un error tuyo: porque MSIX exige un certificado en el que el equipo confíe, y las tres formas de
conseguirlo requieren una compra o permisos de administrador. Vas a perder entre media tarde y tres días
averiguándolo, y vas a acabar activando el modo de desarrollador en tu propia máquina —donde sí tienes
permisos— y concluyendo que funciona.

**Ahí está la trampa completa:** funcionar en tu máquina no es el criterio 4. El criterio 4 es **noventa
equipos sin permisos**, y la única forma de medirlo es intentarlo en uno que no sea el tuyo.

Cuando llegues, escribe el resultado tal como salió —aunque sea "no se pudo"— y **anota cuánto tiempo te
llevó descubrirlo**. Ese número, comparado con la tarde que te costó el prototipo, es la autopsia de la
sección 4 medida en tu propio proyecto.

<details><summary>Pista 1 — el enfoque</summary>

Llena la tabla **antes** de escribir la hoja para Clara, y llénala con las celdas que ya tienes de las fases
12 y 13. Vas a descubrir que la mitad del trabajo estaba hecho, y que lo que falta son exactamente las dos
columnas que nadie mide: despliegue y mantenibilidad.

Para la hoja: empieza por la última pregunta. *"Qué tendría que pasar para que cambiara"* obliga a nombrar el
supuesto más frágil de tu recomendación, y en cuanto lo nombres, el resto de la hoja se escribe solo.

</details>

<details><summary>Pista 2 — la herramienta</summary>

Para el prototipo de WinUI 3, la plantilla del SDK de aplicaciones de Windows, y ojo con que **no hay
`DataGrid`**:
`https://learn.microsoft.com/windows/apps/winui/winui3/`

Para el empaquetado y su firma, que es donde está la trampa:
`https://learn.microsoft.com/windows/msix/package/signing-package-overview`

Para Blazor Hybrid en una ventana WPF:
`https://learn.microsoft.com/aspnet/core/blazor/hybrid/tutorials/wpf`

Y para el criterio 2 —la memoria a las ocho horas— `dotnet-counters` con volcado periódico, o el arnés con
una corrida larga.

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```csharp
// La tabla como dato, no como documento: así se puede publicar y versionar, y la fase 18
// completa una columna sin reescribir prosa.
public sealed record DesktopOption(
    string Name,
    TimeSpan? ColdStart,
    long? MemoryAfterShift,
    TimeSpan? RenderFiftyThousand,
    int? FramesPerSecond,
    DeploymentCost Deployment,
    MaintainabilityScore Maintainability);

public sealed record DeploymentCost(
    string Packaging,
    long SizeBytes,
    bool NeedsAdminRights,
    string CertificateRequirement,
    TimeSpan? TimeToNinetyMachines,
    TimeSpan? TimeFromLima);

// El criterio 5, como cuatro respuestas verificables y no como una impresión.
public sealed record MaintainabilityScore(
    bool HasVisualDesigner,
    bool CanDuvanChangeAColumn,
    bool CanDuvanDeployAFix,
    TimeSpan HoursToUnderstand,
    bool HirableInBogota);

// Y la columna pendiente, que se declara en el tipo para que no se pueda rellenar con un número
// inventado por descuido: si es null, la tabla la imprime como 🔜.
```

</details>

**Cómo se entrega**

```powershell
dotnet run -c Release --project src\modern\Sige.WinUI
dotnet run -c Release --project src\modern\Sige.Hybrid
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 14 --rows 50000 --cold-start
dotnet run -c Release --project src\modern\Cordillera.Ops -- deploy --measure --offices bog,mex,lim
```

```bash
git tag -a mini-14 -m "Mini F14: veredicto provisional del escritorio · recomendación <X> · arranque <A>/<B>/<C> ms · MSIX requiere certificado: <resultado> · columna web pendiente para F18"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Construye el prototipo de WinUI 3 con `x:Bind` y provoca un error de nombre. Compara la experiencia con
   el binding roto de la fase 13.
2. Reusa `StockViewModel` en el prototipo de WinUI 3 y documenta si hizo falta cambiar algo.
3. Publica el paquete MSIX e intenta instalarlo en una máquina virtual sin permisos de administrador.
   Reporta el resultado exacto.
4. Mide el arranque en frío de las tres opciones y ponlas en la tabla. No estimes ninguna.
5. Escribe el párrafo que congela la metodología, en un formato que la fase 18 pueda seguir literalmente.
6. Pregúntale a alguien que no escribió el código cuánto tarda en entender cada prototipo, y cronométralo.
   Es la fila 4 del criterio 5.

**🟡 Intermedio (7–14)**

7. Mide la memoria de las tres opciones a las ocho horas con una consulta cada cinco minutos. Explica las
   diferencias.
8. Rompe la virtualización en WPF y en Blazor, y mide las dos. Es el cobro de la deuda de la fase 13.
9. Construye el prototipo de Blazor Hybrid **sin** `<Virtualize>` y mide 50.000 filas. Anota el número y
   por qué es el peor de la tabla.
10. Calcula el costo real de un certificado de firma de código a tres años, con su renovación, y ponlo en la
    tabla de despliegue.
11. Mide cuánto tarda la actualización de los noventa equipos en cada opción, con el ancho de banda real de
    cada oficina.
12. Implementa una grilla usable en WinUI 3 sin `DataGrid` —con `ItemsRepeater` o un control de la
    comunidad— y anota cuánto tardaste. Es un dato de la tabla.
13. Escribe la tabla como dato —los tipos de la pista 3— y genera el Markdown desde ahí. Así la fase 18
    completa una columna sin editar prosa.
14. Compara la curva de aprendizaje WPF → WinUI 3 contra WinForms → WPF, cronometrando el mismo cambio
    pequeño en las tres.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** El prototipo de WinUI 3 arranca en 800 ms en tu máquina y en 4 segundos en la de
    Nohora. Enumera cuatro causas posibles y di cómo distinguirlas.
16. **Diagnóstico.** Blazor Hybrid consume 400 MB más que WPF a las ocho horas. Explica dónde está esa
    memoria y si se puede reducir.
17. **Medición.** Completa **la tabla del veredicto entera** en sus tres columnas, con las tres tablas de
    respaldo. Determina los **tres umbrales** y escribe el veredicto provisional con su fecha de
    completado.
18. **Medición.** Determina experimentalmente cuántos segundos de arranque de más nota un usuario. Es una
    medición con personas y es perfectamente válida: describe el protocolo antes de hacerla.
19. Toma la opción que **perdió** en tu tabla y escribe el mejor argumento posible a su favor. Si no puedes
    escribir uno convincente, probablemente la comparación tenía un sesgo — y encontrarlo es el ejercicio.
20. **Decisión firmada.** Escribe la recomendación para Cordillera con las cinco columnas y **qué tendría
    que pasar para que cambiara**. Es el miniproyecto, y aquí se pide defenderla ante una objeción concreta
    de Duván y otra de Clara.
21. **Decisión — ¿se migra, se envuelve o se deja quieto?** Con la tabla delante, decide el destino de los
    340 formularios. Y decide también la pregunta incómoda: **¿se migran todos, o solo los veinte más
    usados y el resto se queda?**

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Construye una comparación que "demuestre" que WinUI 3 es la mejor opción, sin mentir en
    ningún número — solo eligiendo qué criterios entran y cómo se ponderan. Después explica qué la hace
    deshonesta. Es el ejercicio más útil de la fase.
23. **Adversarial.** Haz que las cuatro opciones se comporten idénticamente en tu medición, escondiendo la
    diferencia real en una condición de prueba. Sirve para reconocerlo cuando alguien más lo hace.
24. **Diseño y medición.** Escribe el plan de migración completo de los 340 formularios en la tecnología que
    recomendaste: en qué orden, cuánto tarda, qué pasa mientras conviven dos tecnologías, cuántos quedan sin
    migrar y por qué. Con los números de las fases 12, 13 y 14.
25. **Defiende una decisión ante quien no es ingeniero.** Escribe la hoja de Clara y después **preséntala** a
    alguien sin formación técnica. Anota las tres preguntas que te hizo y reescribe la hoja para que las
    responda sin que haya que preguntar.

**🔥 Opcionales**

- Construye el prototipo también en MAUI y anota por qué el curso lo dejó fuera. Es un ejercicio de
  alcance, no de tecnología.
- Investiga Uno Platform o Avalonia y decide si merecían estar en la tabla. Justifica la exclusión con el
  criterio 5.
- Prueba las tres opciones con el lector de pantalla de Windows y anota qué tan accesible es cada una.
  Guárdalo: es un criterio que esta fase no incluyó y que podría haber cambiado el veredicto.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://learn.microsoft.com/windows/apps/get-started/tech-stacks` — la comparación oficial de las
  opciones de interfaz de Windows. Es corta y es el punto de partida de esta fase.
- `https://learn.microsoft.com/windows/apps/winui/winui3/` — WinUI 3 y el SDK de aplicaciones de Windows.
- `https://learn.microsoft.com/windows/msix/package/signing-package-overview` — la firma de MSIX, que es el
  criterio 4 en una página.
- `https://learn.microsoft.com/aspnet/core/blazor/hybrid/` — Blazor Hybrid, y en qué se diferencia de la web.
- `https://learn.microsoft.com/aspnet/core/blazor/components/virtualization` — `<Virtualize>`, sin el cual
  Blazor pierde la comparación de 50.000 filas.
- `https://learn.microsoft.com/visualstudio/deployment/clickonce-security-and-deployment` — ClickOnce, la
  tecnología de 2002 que gana el criterio 4.
- `https://dotnet.microsoft.com/platform/support/policy/dotnet-core` — la política de soporte, que es el dato
  duro detrás de cualquier discusión sobre obsolescencia.

**Libros / artículos**

- La guía *Modernize existing .NET applications* de Microsoft tiene un capítulo de escritorio con un árbol
  de decisión parecido al de esta fase. Verifica el enlace.

> ⚠️ Verifica las URLs. Y la advertencia central de esta fase: **casi todo el material que compara
> tecnologías de interfaz de Windows lo escribe alguien que ya eligió**, y se nota en qué criterios incluye.
> La forma de leerlo es mirar **cuáles de los cinco criterios de esta fase faltan** — y el que falta más a
> menudo es el quinto, porque no se puede medir en un artículo.

**Orden de lectura sugerido:** antes de construir, la comparación oficial de stacks —quince minutos y ahorra
una tarde—. Durante el miniproyecto, la página de firma de MSIX **antes** de necesitarla. Al cerrar, la
política de soporte: es el dato que convierte "está obsoleto" en una afirmación falsable.

---

## 🚀 10. Cierre y conexión con la siguiente fase

**Aquí cierra el Bloque C**, y cierra con una tabla en vez de una opinión: cinco criterios, tres columnas
llenas, una declarada pendiente con su fecha, y una recomendación de una hoja que Clara puede llevar a una
junta donde no hay ingenieros.

Y cierra con dos cosas que el bloque no había prometido. La primera: **el modelo de vista de la fase 13
funcionó en tres tecnologías sin un cambio**, y eso no era el objetivo de MVVM — el objetivo era
comprobabilidad, y la portabilidad vino de regalo. La segunda, más incómoda: **la opción técnicamente más
capaz puede perder por un certificado**. Tres días de gestión frente a una tarde de prototipo es la
proporción que ninguna reunión tiene delante cuando decide.

El Bloque D empieza en la fase 15 y cambia de lado del sistema. Hasta aquí el curso tocó el sistema
heredado, su frontera y su cliente; a partir de ahora construye lo que Cordillera no tiene: **CatalogAPI con
un contrato que Grupo Almenara pueda consumir de verdad**, con validación en el borde, versionado, y el
ultimátum de noviembre como fecha. La fase 09 le dio su capa de datos; la 15 le da la cara pública, que es
donde un contrato mal diseñado se vuelve permanente.

Y queda una columna abierta. La fase 18 la va a llenar con la misma metodología que esta fase congeló, y si
el veredicto cambia cuando entre, **lo va a decir y va a explicar qué lo movió**.

> **La señal de que quedó bien:** *"Tengo una hoja que Clara puede llevar a la junta, dice qué recomiendo y
> qué me haría cambiar de opinión, y ninguna de sus cifras la inventé."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el miniproyecto
> corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-14 -m "F14 cerrada:
> - prototipos en WinUI 3 y Blazor Hybrid, reusando StockViewModel sin cambios
> - despliegue a 90 equipos MEDIDO en las tres opciones, Lima incluido
> - MSIX y su certificado: el criterio donde la opcion mas nueva pierde
> - deuda de la F13 cobrada midiendo el costo de la virtualizacion rota
> - tabla del veredicto publicada: 3 columnas llenas, la 4.a declarada pendiente para la F18
> - metodologia congelada por escrito, y la recomendacion firmada en una hoja"
> ```
>
> **Y esta fase deja algo que ningún tag puede cerrar: una tabla incompleta a propósito.** Es la única
> actualización retroactiva que el curso permite, y está declarada en los dos sitios. Cuando la fase 18
> rellene la columna, `git diff fase-14 fase-18 -- BENCHMARKS.md` va a mostrar **nueve celdas que pasan de
> 🔜 a ⏳ porque llegó un dato**, y eso es lo más parecido que un curso puede ofrecer a cómo se decide de
> verdad. El cambio entra en la entrada consolidada y **no en este documento**, que es la regla de §6: una
> fase no reescribe el material publicado de otra.

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura.*

- **`INSTINTOS.md`** — dos entradas en la familia *interfaz de escritorio*: elegir por modernidad —con la
  genealogía de cuatro generaciones donde **ninguna mató a la anterior**, que es el dato y no el argumento—
  y suponer que lo nuevo despliega mejor, con la autopsia del prototipo que no se pudo instalar y su
  proporción de uno a diez.
- **`BENCHMARKS.md`** — entrada ⏳ *F14 · La tabla del veredicto del escritorio*, que es la entrada más
  grande del curso hasta ahora y **la única con una columna declarada pendiente**. El archivo tiene que
  explicar la convención 🔜, que es distinta de ⏳: ⏳ es "escrita y sin ejecutar"; 🔜 es **"no se puede
  ejecutar todavía porque el competidor no existe"**. Conviene agregarla a la sección de cómo se lee una
  entrada.
- **Deuda 💸 cobrada:** la virtualización de la F13, cobrada **midiendo el error**. Es una forma de cobro
  nueva —ni borrando código ni agregándolo, sino cuantificando el costo de equivocarse— y conviene anotarla
  en el libro de §7.1 como el tercer tipo atípico, después del diff vacío de la F09 y el código agregado de
  la F10.
- **Deuda 💸 pendiente de declarar, de la F13:** el total y el conteo de huérfanos siguen calculándose en el
  modelo de vista cuando deberían estar en el dominio. La F13 lo dejó como ejercicio 19 y **recomendó
  declararla con cobro en la F15**; hay que hacerlo en el libro de §7.1 o queda como un ejercicio sin
  consecuencia.
- **Tipos nuevos para el congelamiento:** `Sige.WinUI`, `Sige.Hybrid`, `DesktopOption`, `DeploymentCost`,
  `MaintainabilityScore`. Los tres últimos son la tabla como dato, y la F18 los va a completar.
- **Para la fase 18, y es un contrato:** la metodología está congelada en la sección 6 —cinco criterios,
  formulario de existencias, 50.000 filas, tres oficinas con Lima como caso adverso, memoria a las ocho
  horas—. La 18 **completa la columna con esas condiciones y sin rediscutirlas**, y si el veredicto cambia,
  lo dice. Si la 18 cambia la metodología, las tres columnas de aquí quedan incomparables y la tabla no
  vale nada.
- **Para la fase 18, y es una oportunidad:** `StockViewModel` no tiene dependencias de interfaz y el
  componente Razor de Blazor Hybrid es **el mismo** que la web va a servir. La 18 debería aprovecharlo — o
  desmentirlo con datos si resulta que el modelo de vista de escritorio no encaja en un modelo de render
  por circuito.
- **Para la fase 24:** el ejercicio 21 —¿se migran todos los formularios o solo los veinte más usados?— y
  el 24 —el plan completo— son material directo del veredicto final. Y el ejercicio 🔥 de accesibilidad
  señala un criterio que esta fase **no incluyó**: la 24 debería admitirlo como una de las decisiones del
  propio curso que pudieron ser otras.
- **Riesgo detectado y resuelto:** la tabla del veredicto no puede vivir solo en este documento, porque
  entonces la fase 18 tendría que **editar el `.md` publicado de otra fase** — el único caso así del curso.
  🪦 Decidido y subido a la propuesta §8: **la tabla se consolida en `BENCHMARKS.md`** y este documento
  enlaza a esa entrada. La F18 completa la columna allí. Así el material que el lector leyó no cambia bajo
  sus pies, y la tabla sí crece.
