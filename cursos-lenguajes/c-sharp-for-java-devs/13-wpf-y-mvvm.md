# 🎛️ Fase 13 — WPF y MVVM: la interfaz que se puede probar

> C# para desarrolladores Java senior · Fase 13 de 24 · Bloque C — el escritorio
> Depende de: 12 · Habilita: 14
> Estilo de esta fase: **nuevo** (.NET 10, C# 14)
> Proyecto que avanza: **SIGE cliente**. Al terminar existe el mismo formulario de existencias en WPF, con
> su modelo de vista **cubierto por pruebas que corren sin levantar la interfaz**.

---

## 🎯 1. Propósito

Cobrar la deuda de la fase 12 y, al hacerlo, demostrar el argumento de MVVM como hay que demostrarlo:
**con las pruebas corriendo, no con un diagrama.**

Las sesenta líneas que la fase anterior dejó dentro del `Click` —el cálculo del total, el conteo de
movimientos sin título, el filtro— salen de ahí y pasan a un tipo que no sabe que existe una ventana. Y
entonces se pueden probar: en milisegundos, sin monitor, en CI.

Y de paso se construye la segunda de las cuatro opciones que la fase 14 va a medir, porque el mismo
formulario en WPF es una respuesta distinta a la pregunta del bloque.

> 🧭 **La regla de la fase:** *MVVM se justifica con la suite corriendo, no con la arquitectura dibujada.*
> Si al terminar no hay pruebas que ejerciten la lógica de presentación sin instanciar una ventana, el
> patrón no compró nada y solo agregó archivos.

---

## ✅ 2. Qué queda listo al terminar

- [ ] 💸 **Se cobra la deuda de la fase 12:** el formulario de existencias tiene su lógica en un
      `StockViewModel`, y **el manejador del botón no existe** — hay un comando enlazado.
- [ ] `StockViewModel` está **cubierto por pruebas que corren sin levantar la interfaz**: el total, el
      conteo de huérfanos, el filtro, los estados de carga y la cancelación.
- [ ] El mismo formulario existe en WPF, con búsqueda, grilla, edición y su resumen, y hace lo mismo que
      la versión WinForms.
- [ ] La lista **soporta 50.000 filas sin que el desplazamiento se sienta mal**, o **no las soporta y está
      declarado como deuda** con su medición en la fase 14.
- [ ] Sabes diagnosticar un binding roto, que es lo que hace difícil WPF: **no lanza nada**, y el único
      rastro está en la ventana de salida del depurador.
- [ ] Puedes decir dónde el paralelo con MVC funciona y **dónde se rompe**.
- [ ] La medición de la sección 6 está escrita con su comando, y la entrada quedó en `BENCHMARKS.md`.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Estilos, plantillas, temas y apariencia.** Fuera, con su razón escrita y sin apéndice al que mandarlos:
  esta fase trata de **cómo se separa la lógica de la vista**, y el aspecto visual es un proyecto de diseño.
  Lo que entra de XAML es lo mínimo para que el binding se entienda.
- **WinUI 3 y Blazor Hybrid** → fase 14.
- **El veredicto del escritorio** → fase 14. Aquí se construye y se mide una opción.
- **Un marco de MVVM** —con sus generadores de código, sus mensajeros y su contenedor— queda fuera a
  propósito: la fase escribe `INotifyPropertyChanged` y un comando **a mano una vez**, porque entender qué
  hace el marco antes de usarlo es la diferencia entre elegirlo y heredarlo.
- **Migrar los 340 formularios a WPF.** Aquí se construye **uno**, y si el veredicto de la fase 14 dice
  WPF, lo que sigue es un plan y no esta fase.

---

## 🧠 4. Concepto mínimo

### Qué es MVVM, y por qué existe

WPF tiene una propiedad que WinForms no tiene: **la vista puede observar un objeto y actualizarse sola**.
No hay que escribir `grid.DataSource = datos` ni `label.Text = resumen`: se declara en el XAML que la
etiqueta muestra la propiedad `Summary` de algo, y cuando ese algo avisa que `Summary` cambió, la etiqueta
se repinta.

Eso es el *binding*, y de ahí sale todo lo demás. Si la vista puede observar un objeto cualquiera, entonces
**ese objeto no necesita saber que la vista existe** — y si no sabe que la vista existe, se puede
instanciar en una prueba, ejercitar, y verificar sin monitor. Ese objeto es el **modelo de vista**.

Las tres piezas, en una línea cada una:

- **Modelo** — los tipos del dominio. `StockItem`, `Money`, `EditionId`. Ya existen desde la fase 01 y no
  cambian.
- **Modelo de vista** — el estado de *esta pantalla* y las operaciones que ofrece: qué almacén está
  seleccionado, qué filas se muestran, el total, si está cargando, el comando de consultar. **Nada de
  WPF adentro**, y esa es la propiedad que lo hace comprobable.
- **Vista** — el XAML. Declara qué se muestra y a qué se enlaza, y no tiene lógica.

> 🧠 **El modelo mental que hace encajar todo:** en WinForms el controlador **empuja** datos hacia los
> controles; en MVVM la vista **jala** datos del modelo de vista cuando este avisa que cambiaron. Esa
> inversión es la única idea nueva de la fase, y es también la que hace difícil la depuración: **cuando
> nadie llama a nadie, un enlace roto no produce un error — produce una pantalla vacía.**

### `INotifyPropertyChanged` y el comando, escritos a mano una vez

Hay marcos que generan esto y son buenos. Se escribe a mano **una vez** porque el mecanismo son doce líneas
y entenderlo cambia cómo se depura:

```csharp
// El contrato completo: un evento que dice qué propiedad cambió. WPF se suscribe y repinta.
public interface INotifyPropertyChanged
{
    event PropertyChangedEventHandler? PropertyChanged;
}
```

Y un comando es un objeto con dos cosas: **qué hacer** y **si se puede hacer ahora**. Esa segunda es la que
hace que el botón se deshabilite solo mientras la consulta corre, sin que nadie escriba
`btnConsultar.Enabled = false` — que es exactamente la línea que la fase 12 tenía que escribir dos veces en
cada manejador.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**Primera: el controlador que manipula controles por su nombre.**

Es el reflejo de once años de Swing, de JSF, y del propio formulario de la fase 12:

```csharp
// ❌ El modelo de vista escrito con la cabeza de un controlador. Y esto compila.
public sealed class StockViewModel
{
    private readonly DataGrid _grid;          // ← el modelo de vista conoce un control de WPF
    private readonly TextBlock _statusLabel;

    public StockViewModel(DataGrid grid, TextBlock statusLabel)
    {
        _grid = grid;
        _statusLabel = statusLabel;
    }

    public async Task LoadAsync(string warehouse, CancellationToken token)
    {
        _statusLabel.Text = "Consultando...";
        StockQueryResult result = await _client.GetStockAsync(warehouse, token);
        _grid.ItemsSource = result.Rows;                      // empujando datos al control
        _statusLabel.Text = $"Total: {result.TotalUnits:N0}";
    }
}
```

Funciona perfecto. Y acaba de perder **todo** lo que MVVM compraba: ese tipo necesita un `DataGrid` para
existir, un `DataGrid` necesita un contexto de WPF, y un contexto de WPF necesita un hilo de interfaz. **La
prueba que querías escribir es ahora una prueba de interfaz**, lenta, frágil y que no corre en CI.

```csharp
// ✅ El mismo trabajo, sin saber que WPF existe. Se instancia en una prueba con dos líneas.
public sealed partial class StockViewModel : ObservableObject
{
    private string _status = "Listo";
    public string Status
    {
        get => _status;
        private set => SetProperty(ref _status, value);   // avisa, y la vista se repinta sola
    }

    public ObservableCollection<StockRow> Rows { get; } = [];

    public async Task LoadAsync(WarehouseCode warehouse, CancellationToken token)
    {
        Status = "Consultando...";
        StockQueryResult result = await _client.GetStockAsync(warehouse, token);

        Rows.Clear();
        foreach (StockRow row in result.Rows) { Rows.Add(row); }

        Status = $"Total: {result.TotalUnits:N0} unidades en {result.Rows.Count:N0} registros";
    }
}
```

**Por qué falla el reflejo:** porque el patrón no es la estructura de archivos, es **la dirección de la
dependencia**. Tres carpetas llamadas `Models`, `ViewModels` y `Views` con un `DataGrid` inyectado en el
modelo de vista son MVVM en la forma y un controlador en el fondo. **La prueba de si el patrón está bien
aplicado es una sola: ¿se puede instanciar el modelo de vista en una prueba sin referenciar WPF?**

**Segunda: tratar el binding como magia en vez de como un contrato.**

```xml
<!-- ❌ Esto compila, se ejecuta, y la etiqueta se queda vacía. Sin error, sin excepción, sin log. -->
<TextBlock Text="{Binding Sumary}" />
<!--                       ^^^^^^ y el modelo de vista tiene `Summary` -->
```

Un nombre mal escrito en un binding **no es un error de compilación** —el XAML se resuelve por reflexión en
tiempo de ejecución— y **no lanza nada**. WPF busca la propiedad, no la encuentra, y deja el control con su
valor por omisión. La aplicación funciona; la etiqueta está vacía.

**Por qué falla el reflejo:** porque en el mundo del que vienes, una referencia a algo que no existe la
atrapa el compilador. Aquí el enlace es un contrato **por nombre y en tiempo de ejecución**, más parecido
a una expresión de una plantilla JSP que a una llamada a un método. Y las tres defensas son:

```csharp
// 1. Subir el diagnóstico de binding a excepción durante el desarrollo. Es la más importante y
//    casi nadie la conoce: convierte el fallo silencioso en un fallo ruidoso.
PresentationTraceSources.DataBindingSource.Switches[0].Level = SourceLevels.Error;
```

```xml
<!-- 2. Enlazar con tipo declarado, para que el editor y el compilador ayuden. -->
<Window x:Class="Sige.Desktop.StockWindow"
        xmlns:vm="clr-namespace:Sige.Desktop.ViewModels"
        d:DataContext="{d:DesignInstance Type=vm:StockViewModel}">
```

```text
3. Y la que de verdad sostiene: probar el modelo de vista. Un binding roto deja la pantalla vacía;
   una propiedad mal calculada da un número equivocado. Las pruebas atrapan la segunda, que es la
   que cuesta plata — y para la primera están las dos defensas de arriba.
```

### 🩻 Esto sí funciona igual

La separación de responsabilidades, que es el fondo del patrón: mantener la lógica de presentación fuera de
la vista es la misma idea que llevas años aplicando, con otro reparto. Y las pruebas de lógica de
presentación: lo que probabas de un controlador —que un estado produce cierta salida, que una operación
inválida no cambia nada— se prueba igual aquí y con menos ceremonia.

También se transfiere el instinto de **no poner lógica de negocio en la capa de presentación**. El total de
existencias no es una regla de la pantalla: es una regla del dominio, y el modelo de vista debería
*pedirla*, no calcularla. La fase la mueve al modelo de vista porque es donde está hoy, y el ejercicio 19
pregunta si no debería estar más abajo — **y la respuesta correcta es que sí**.

### 📖 Diccionario de traducción

| Java / MVC | WPF / MVVM | Dónde se rompe el paralelo |
|---|---|---|
| controlador | modelo de vista | **La dirección de la dependencia se invierte:** el controlador conoce la vista; el modelo de vista **no sabe que existe** |
| `model.addAttribute("total", x)` | una propiedad con `PropertyChanged` | No se empuja al renderizar: se avisa, y la vista jala cuando quiere |
| plantilla JSP / Thymeleaf | XAML con bindings | Se resuelve por **reflexión en tiempo de ejecución**: un nombre mal escrito no lo atrapa el compilador |
| `@RequestMapping` → método | `ICommand` enlazado a un botón | El comando trae `CanExecute`, así que **el botón se habilita solo**. No hay equivalente directo |
| validación con `BindingResult` | `INotifyDataErrorInfo` | La vista se suscribe a los errores y los muestra sin que nadie los pase |
| `List<T>` en el modelo | `ObservableCollection<T>` | Notifica altas y bajas: agregar un elemento repinta **una fila**, no la lista |
| recargar la página | nada | El estado vive en el modelo de vista y sobrevive. **Es la diferencia grande con la web**, y la fase 18 la mide |
| JSF con su árbol de componentes | árbol visual de WPF | Más parecido de lo que parece, y con el mismo problema: **depurarlo es mirar un árbol** |
| Swing con `invokeLater` | `Dispatcher.Invoke` | Y casi nunca hace falta: `await` vuelve al hilo correcto |
| un `@ControllerAdvice` para errores | nada equivalente | El manejo de errores de la interfaz es tuyo, por pantalla. Es más trabajo y más explícito |

> ⚠️ **La fila de la recarga de página merece atención porque es la que separa los dos mundos.** En una
> aplicación web, cada petición reconstruye el estado y eso **simplifica** el modelo mental — es
> desperdicio de cómputo y tranquilidad de diseño. En el escritorio el estado vive en memoria mientras la
> ventana esté abierta: ocho horas, en el caso de las noventa personas de Cordillera. Eso significa que un
> modelo de vista con una fuga de memoria, o que acumula suscripciones, **no se nota en una demo de cinco
> minutos y sí en una jornada**. Es el tipo de defecto que la fase 14 va a medir.

> 📝 **Nota de ecosistema.** WPF es de 2006 y MVVM se nombró en 2005 en el blog de John Gossman, que
> trabajaba en WPF — o sea que el patrón nació **para** esta tecnología y por eso encaja tan bien. Eso
> explica dos cosas: que todo el material de MVVM asuma XAML, y que al llevar el patrón a otros sitios
> —Blazor, MAUI, incluso WinForms con esfuerzo— siempre quede un poco forzado. Y explica una tercera:
> hay quince años de marcos de MVVM, muchos abandonados, y elegir uno es una decisión de mantenimiento.
> Por eso esta fase escribe el mecanismo a mano: **entender qué hace el marco antes de usarlo es la
> diferencia entre elegirlo y heredarlo.**

---

## 💻 5. Código mínimo con comentarios

### 5.1 El cobro de la deuda: la lógica sale del `Click`

```csharp
// src/modern/Sige.Desktop/ViewModels/StockViewModel.cs
//
// 💸 Cobro de la deuda de la fase 12. Estas son las sesenta líneas que estaban dentro de
//    btnConsultar_Click, sacadas a un tipo que **no sabe que existe una ventana**.
//
//    La factura: git diff fase-12 fase-13 -- src/modern/Sige.Forms/ src/modern/Sige.Desktop/
//
//    Y el argumento de MVVM no es este archivo: es el de pruebas de la sección 5.3.
namespace Sige.Desktop.ViewModels;

public sealed class StockViewModel : ViewModelBase
{
    private readonly IInventoryClient _client;
    private readonly QueryCoordinator _queries = new();

    private WarehouseCode? _selectedWarehouse;
    private string _searchText = string.Empty;
    private string _status = "Listo";
    private bool _isLoading;

    public StockViewModel(IInventoryClient client)
    {
        // Una interfaz aquí sí está justificada, y es el segundo de los tres casos legítimos de la
        // fase 04: hay que sustituirla en una prueba, y el doble necesita devolver datos.
        _client = client;

        // El comando, con su condición. Esto es lo que reemplaza a las cuatro líneas de
        // `btnConsultar.Enabled = false` / `= true` que el manejador de la fase 12 tenía repartidas
        // entre el try y el finally — y que se olvidaban en cuanto había un `return` temprano.
        LoadCommand = new AsyncCommand(
            execute: LoadAsync,
            canExecute: () => SelectedWarehouse is not null && !IsLoading);

        CancelCommand = new RelayCommand(
            execute: () => _queries.CancelCurrent(),
            canExecute: () => IsLoading);
    }

    public WarehouseCode? SelectedWarehouse
    {
        get => _selectedWarehouse;
        set
        {
            if (SetProperty(ref _selectedWarehouse, value))
            {
                // Cuando cambia el almacén, el comando puede pasar de deshabilitado a habilitado.
                // Avisarlo es responsabilidad del modelo de vista: WPF no adivina.
                LoadCommand.RaiseCanExecuteChanged();
            }
        }
    }

    /// <summary>
    /// El texto de búsqueda. **Filtra en memoria sobre lo ya cargado** y no vuelve a consultar: es la
    /// misma decisión que el formulario de 2017 tomaba, conservada a propósito porque el
    /// comportamiento que el almacén conoce no se cambia en una fase que solo mueve código.
    /// </summary>
    public string SearchText
    {
        get => _searchText;
        set
        {
            if (SetProperty(ref _searchText, value))
            {
                ApplyFilter();
            }
        }
    }

    public string Status
    {
        get => _status;
        private set => SetProperty(ref _status, value);
    }

    public bool IsLoading
    {
        get => _isLoading;
        private set
        {
            if (SetProperty(ref _isLoading, value))
            {
                LoadCommand.RaiseCanExecuteChanged();
                CancelCommand.RaiseCanExecuteChanged();
            }
        }
    }

    /// <summary>
    /// Las filas que la vista muestra. `ObservableCollection` notifica altas y bajas, así que la
    /// grilla repinta **una fila** y no la lista entera.
    /// </summary>
    public ObservableCollection<StockRow> Rows { get; } = [];

    public AsyncCommand LoadCommand { get; }

    public RelayCommand CancelCommand { get; }

    private async Task LoadAsync()
    {
        // El coordinador de consultas de la fase 12, reusado tal cual: cancela la anterior y
        // devuelve el token de la nueva. Los tres bugs de concurrencia siguen manejados, y ahora
        // **se pueden probar**, que es lo que no se podía antes.
        CancellationToken token = _queries.StartNew();

        IsLoading = true;
        Status = "Consultando...";

        try
        {
            StockQueryResult result = await _client.GetStockAsync(SelectedWarehouse!.Value, token);

            _allRows = result.Rows;
            ApplyFilter();

            // El resumen, que en la fase 12 se calculaba recorriendo la grilla a mano. Aquí es una
            // propiedad del resultado, y la conversación sobre si debería estar más abajo —en el
            // dominio— es el ejercicio 19. La respuesta es que sí.
            Status = result.RowsWithoutTitle > 0
                ? $"Total: {result.TotalUnits:N0} unidades en {result.Rows.Count:N0} registros " +
                  $"({result.RowsWithoutTitle} sin título)"
                : $"Total: {result.TotalUnits:N0} unidades en {result.Rows.Count:N0} registros";
        }
        catch (OperationCanceledException)
        {
            Status = "Consulta cancelada";
        }
        catch (InventoryUnavailableException ex)
        {
            // Ojo con lo que NO hay aquí: no hay `MessageBox`. El modelo de vista no puede abrir
            // ventanas —es lo que lo hace comprobable— así que el error se expone como estado y la
            // vista decide cómo mostrarlo.
            Status = $"No se pudo consultar: {ex.Message}";
        }
        finally
        {
            IsLoading = false;
        }
    }
}
```

**Detalles con intención**

- **No hay ni un tipo de WPF en este archivo.** Ni `DataGrid`, ni `MessageBox`, ni `Dispatcher`. Es la
  propiedad que se está comprando, y la prueba de que se compró está en la sección 5.3.
- **El error se expone como estado, no como ventana.** Un `MessageBox` dentro del modelo de vista lo
  volvería a hacer inejecutable en una prueba — y de paso impediría que la misma lógica sirviera para la
  versión web de la fase 18, que es un beneficio que nadie planeó.
- **`RaiseCanExecuteChanged` es explícito** y es el precio de haber escrito el comando a mano: un marco de
  MVVM lo hace con un generador de código. Escribirlo una vez es lo que permite decidir con criterio si se
  adopta uno.
- **El filtro sigue siendo en memoria**, igual que en 2017. Cambiar ese comportamiento en una fase que solo
  mueve código sería modificar lo que el almacén conoce sin decírselo.

### 5.2 El XAML, lo mínimo

```xml
<!-- src/modern/Sige.Desktop/Views/StockWindow.xaml -->
<Window x:Class="Sige.Desktop.Views.StockWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:vm="clr-namespace:Sige.Desktop.ViewModels"
        d:DataContext="{d:DesignInstance Type=vm:StockViewModel}"
        Title="SIGE - Existencias por almacén" Height="560" Width="900">

  <Grid Margin="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto" />
      <RowDefinition Height="*" />
      <RowDefinition Height="Auto" />
    </Grid.RowDefinitions>

    <!-- La fila de controles. Cada uno declara a qué se enlaza y nadie llama a nadie. -->
    <StackPanel Orientation="Horizontal">
      <ComboBox ItemsSource="{Binding Warehouses}"
                SelectedItem="{Binding SelectedWarehouse}" Width="220" />

      <!-- UpdateSourceTrigger=PropertyChanged: sin esto, el filtro se aplicaría al perder el foco
           y no al teclear, que es lo que el usuario espera. Es el detalle de binding que más
           tiempo cuesta descubrir. -->
      <TextBox Text="{Binding SearchText, UpdateSourceTrigger=PropertyChanged}"
               Width="300" Margin="8,0,0,0" />

      <!-- Y aquí está el argumento del comando: el botón se deshabilita solo mientras la consulta
           corre, porque CanExecute lo dice. Ninguna línea escribe IsEnabled. -->
      <Button Content="Consultar" Command="{Binding LoadCommand}" Width="96" Margin="8,0,0,0" />
      <Button Content="Cancelar"  Command="{Binding CancelCommand}" Width="96" Margin="8,0,0,0" />
    </StackPanel>

    <!-- La grilla. `VirtualizingStackPanel` está activado por omisión en WPF, y esa es la
         diferencia grande con WinForms — pero tiene condiciones, y la 💸 de abajo es una de ellas. -->
    <DataGrid Grid.Row="1" ItemsSource="{Binding Rows}" IsReadOnly="True"
              AutoGenerateColumns="False" Margin="0,12,0,0">
      <DataGrid.Columns>
        <DataGridTextColumn Header="Edición" Binding="{Binding Edition}" Width="120" />
        <DataGridTextColumn Header="Título"  Binding="{Binding Title}"  Width="*" />
        <DataGridTextColumn Header="Saldo"   Binding="{Binding Quantity, StringFormat=N0}" Width="90" />
      </DataGrid.Columns>
    </DataGrid>

    <TextBlock Grid.Row="2" Text="{Binding Status}" Margin="0,8,0,0" />
  </Grid>
</Window>
```

**El patrón a memorizar**

> **En el XAML no hay lógica y en el modelo de vista no hay WPF.** Si en el XAML aparece un `if`, un
> cálculo o un formato complicado, es lógica escondida en un sitio sin pruebas. Y si en el modelo de vista
> aparece un tipo de WPF, se acabó la comprobabilidad. **Las dos mitades de esa frase son la fase entera.**

> 💸 **Deuda declarada: la lista entra sin virtualización garantizada.**
>
> WPF virtualiza por omisión —crea solo los elementos visibles— y eso es una ventaja real sobre WinForms.
> Pero **la virtualización se pierde en silencio** en varios casos, y este proyecto tiene uno: envolver la
> grilla en un contenedor que le dé altura infinita —un `ScrollViewer` propio, o un `StackPanel`
> vertical— hace que el `DataGrid` crea que tiene espacio para todo y **materialice las 50.000 filas**.
> No hay error, no hay advertencia: hay una aplicación que tarda doce segundos en mostrar una pantalla.
>
> **Se paga en la fase 14**, midiendo qué cuesta con 50.000 filas en las cuatro opciones — porque es una
> de las comparaciones que la tabla del veredicto necesita. La factura será
> `git diff fase-13 fase-14 -- src/modern/Sige.Desktop/Views/`.
>
> **Por qué se deja:** porque con los datos de desarrollo —unos cientos de filas— la diferencia no existe,
> y arreglar hoy algo que no se puede demostrar convierte la lección en doctrina. La fase 14 lo demuestra
> con un número.

### 5.3 Las pruebas: el argumento entero de la fase

```csharp
// src/modern/Sige.Desktop.Tests/StockViewModelTests.cs
//
// Esta clase ES el argumento de MVVM. Nueve pruebas, ninguna levanta una ventana, todas corren en
// milisegundos y todas corren en CI — donde no hay monitor, ni sesión de escritorio, ni WPF.
//
// Con el manejador de la fase 12, ninguna de las nueve se podía escribir.
namespace Sige.Desktop.Tests;

public class StockViewModelTests
{
    private readonly IInventoryClient _client = Substitute.For<IInventoryClient>();

    [Fact]
    public async Task El_resumen_reporta_el_total_y_los_registros()
    {
        _client.GetStockAsync(WarehouseCode.Bog, Arg.Any<CancellationToken>())
               .Returns(new StockQueryResult(Rows: ThreeRows(), TotalUnits: 240, RowsWithoutTitle: 0));

        var viewModel = new StockViewModel(_client) { SelectedWarehouse = WarehouseCode.Bog };

        await viewModel.LoadCommand.ExecuteAsync();

        Assert.Equal("Total: 240 unidades en 3 registros", viewModel.Status);
    }

    [Fact]
    public async Task El_resumen_menciona_los_registros_sin_titulo_cuando_hay()
    {
        // Los huérfanos de la fase 09, que el almacén está acostumbrado a ver. Que esto tenga una
        // prueba significa que el día que alguien "limpie" el resumen, la suite lo detiene.
        _client.GetStockAsync(WarehouseCode.Lim, Arg.Any<CancellationToken>())
               .Returns(new StockQueryResult(Rows: ThreeRows(), TotalUnits: 240, RowsWithoutTitle: 2));

        var viewModel = new StockViewModel(_client) { SelectedWarehouse = WarehouseCode.Lim };

        await viewModel.LoadCommand.ExecuteAsync();

        Assert.Contains("(2 sin título)", viewModel.Status, StringComparison.Ordinal);
    }

    [Fact]
    public void El_comando_esta_deshabilitado_hasta_que_hay_almacen_seleccionado()
    {
        var viewModel = new StockViewModel(_client);

        Assert.False(viewModel.LoadCommand.CanExecute(null));

        viewModel.SelectedWarehouse = WarehouseCode.Bog;

        Assert.True(viewModel.LoadCommand.CanExecute(null));
    }

    [Fact]
    public async Task El_comando_esta_deshabilitado_mientras_la_consulta_corre()
    {
        // La prueba que en la fase 12 habría requerido levantar el formulario y mirar el botón.
        var gate = new TaskCompletionSource<StockQueryResult>();
        _client.GetStockAsync(WarehouseCode.Bog, Arg.Any<CancellationToken>()).Returns(gate.Task);

        var viewModel = new StockViewModel(_client) { SelectedWarehouse = WarehouseCode.Bog };

        Task loading = viewModel.LoadCommand.ExecuteAsync();

        Assert.False(viewModel.LoadCommand.CanExecute(null));
        Assert.True(viewModel.CancelCommand.CanExecute(null));

        gate.SetResult(new StockQueryResult(ThreeRows(), 240, 0));
        await loading;

        Assert.True(viewModel.LoadCommand.CanExecute(null));
    }

    [Fact]
    public async Task Una_segunda_consulta_cancela_la_primera()
    {
        // El primero de los tres bugs de la fase 12, ahora verificable sin hacer doble clic a mano.
        var first = new TaskCompletionSource<StockQueryResult>();
        CancellationToken firstToken = default;

        _client.GetStockAsync(WarehouseCode.Bog, Arg.Any<CancellationToken>())
               .Returns(call => { firstToken = call.Arg<CancellationToken>(); return first.Task; });

        var viewModel = new StockViewModel(_client) { SelectedWarehouse = WarehouseCode.Bog };

        Task firstLoad = viewModel.LoadCommand.ExecuteAsync();
        Task secondLoad = viewModel.LoadCommand.ExecuteAsync();

        Assert.True(firstToken.IsCancellationRequested);
    }

    [Fact]
    public void El_filtro_no_vuelve_a_consultar()
    {
        // El comportamiento que el almacén conoce, fijado con una prueba para que nadie lo
        // "mejore" sin darse cuenta.
        var viewModel = new StockViewModel(_client) { SelectedWarehouse = WarehouseCode.Bog };

        viewModel.SearchText = "páramo";

        _client.DidNotReceive().GetStockAsync(Arg.Any<WarehouseCode>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Un_fallo_del_servicio_queda_como_estado_y_no_como_excepcion()
    {
        _client.GetStockAsync(Arg.Any<WarehouseCode>(), Arg.Any<CancellationToken>())
               .Returns<StockQueryResult>(_ => throw new InventoryUnavailableException("la API no responde"));

        var viewModel = new StockViewModel(_client) { SelectedWarehouse = WarehouseCode.Mex };

        await viewModel.LoadCommand.ExecuteAsync();   // no lanza

        Assert.StartsWith("No se pudo consultar", viewModel.Status, StringComparison.Ordinal);
    }
}
```

**Detalles con intención**

- **Nueve pruebas, cero ventanas.** Es el entregable de la fase. Si alguna necesitara `Application` o un
  `Dispatcher`, el modelo de vista tendría WPF adentro y habría que arreglarlo.
- **NSubstitute con `Substitute.For<T>()`** — sin atributos, sin inicialización: una llamada. Es la
  traducción de Mockito que la fase 04 anunció, usada por primera vez en serio.
- **`TaskCompletionSource` para controlar el tiempo**: la forma de probar un estado intermedio —el botón
  deshabilitado *mientras* la consulta corre— sin esperas por reloj, que producen pruebas intermitentes.
- **La prueba del filtro fija un comportamiento que podría parecer un defecto.** Que el filtro no
  reconsulte es lo que el almacén conoce, y una prueba es la forma de decirle al próximo que es
  intencional.

**Prueba de fuego**

```powershell
dotnet test src\modern\Sige.Desktop.Tests -c Release
```

Nueve pruebas, en menos de un segundo, **en una máquina sin interfaz gráfica**. Ese es el número que
justifica la fase: en la 12, las nueve requerían un monitor y un humano.

Y la mentira que te va a contar la salida si miras el lugar equivocado: **las pruebas verdes no garantizan
que la pantalla funcione**. Un binding con el nombre mal escrito deja las nueve pruebas pasando y la
etiqueta vacía, porque el modelo de vista está perfecto y es el XAML el que falla. Por eso las dos defensas
de la sección 4 no son opcionales: **la suite cubre la lógica y el diagnóstico de binding cubre el
enlace**, y hacen falta las dos.

---

## 📏 6. Medición

**Hipótesis:** el mismo formulario en WPF arranca **más lento** que en WinForms —porque WPF inicializa un
sistema de composición más grande— y a cambio se desplaza con más fluidez con volumen, porque virtualiza
por omisión. La pregunta no es cuál gana: es **en qué gana cada uno y cuánto**, porque la fase 14 necesita
las dos columnas.

**Condiciones:** SDK 10.0.401 · Release · Windows 11 · el mismo formulario de existencias, con la misma
consulta contra la base del generador, semilla `19970417` · la grilla con **50.000 filas** · arranque en
frío en un equipo **sin SDK instalado**, con la caché de disco limpia · 20 repeticiones con 3 de
calentamiento descartadas · arnés propio; la fluidez medida como cuadros por segundo durante un
desplazamiento continuo de diez segundos.

**Competidores:** cuatro configuraciones, y las dos últimas existen para atribuir la diferencia a su causa:

- **WinForms en .NET 10**, tal como quedó en la fase 12. Es el competidor de verdad.
- **WinForms en .NET 10 con la grilla en modo virtual**, que es donde la fase 12 dejó su mejor número.
- **WPF con virtualización activa** — el caso sano.
- **WPF con la virtualización rota**, envolviendo la grilla en un contenedor de altura infinita. Es la
  deuda 💸 de esta fase, medida aquí para que la fase 14 sepa cuánto cuesta el error.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 13 --rows 50000 --cold-start
```

**Resultado:** ⏳ pendiente de ejecución en tu máquina.

| Configuración | Arranque en frío | Memoria a los 5 min | Pintado de 50.000 filas | Fluidez al desplazar |
|---|---|---|---|---|
| WinForms (.NET 10) | ⏳ | ⏳ | ⏳ | ⏳ |
| WinForms con modo virtual | ⏳ | ⏳ | ⏳ | ⏳ |
| WPF con virtualización | ⏳ | ⏳ | ⏳ | ⏳ |
| WPF con virtualización rota | ⏳ | ⏳ | ⏳ | ⏳ |

Y una columna que esta fase agrega y que no es de rendimiento:

| Configuración | Pruebas que corren sin interfaz | Líneas de lógica sin cubrir |
|---|---|---|
| WinForms (fase 12) | **0** | ~60, dentro del `Click` |
| WPF con MVVM | ⏳ | ⏳ |

> ⚖️ **Veredicto** *(expectativa, todavía sin ejecutar — `formato-de-mediciones.md` §2.6)*. Se espera que
> WinForms arranque más rápido, que WPF se desplace mejor, y que **las dos primeras filas queden empatadas
> en fluidez** una vez que WinForms usa modo virtual — lo que diría que la ventaja de WPF no es la
> virtualización en sí, sino **que viene activada por omisión**. Es un matiz importante: una ventaja por
> omisión es real, porque nadie la olvida.
>
> Y se espera que la última fila sea la peor de las cuatro por un margen amplio, lo cual es la lección: **la
> virtualización de WPF se pierde en silencio**, y una ventaja que se puede perder sin aviso hay que
> vigilarla.
>
> **Los dos umbrales que tu ejecución tiene que determinar:** (1) **a partir de cuántas filas la
> virtualización deja de ser opcional** en cada tecnología; y (2) **cuánto arranque de más cuesta WPF**,
> que es una de las cinco columnas del veredicto de la fase 14.
>
> 📝 Y la última tabla no lleva veredicto porque **no es una comparación de rendimiento**: es el argumento
> de la fase. Cero pruebas contra las que tengas, y sesenta líneas sin cubrir contra las que queden.

---

## 🧱 7. Miniproyecto — el formulario de existencias en WPF, probado sin interfaz

**El encargo**

Duván otra vez, y esta vez con escepticismo, que es lo que hace bueno el encargo: *"Ya vi que el de
WinForms quedó andando. Me dijiste que si lo hacemos en WPF se puede probar sin abrir la ventana, y eso lo
quiero ver — porque yo llevo nueve años probando formularios abriéndolos, y si hay una forma de saber que
el total está bien sin tener que consultar Bogotá y contar a mano, me interesa. Pero que se vea igual: el
almacén no tiene por qué notar el cambio."*

**Por qué duele**

Porque las dos condiciones de Duván son las dos mitades del patrón, y una es fácil de fingir. **Que se
pruebe sin abrir la ventana** exige que el modelo de vista no tenga ni un tipo de WPF, y la tentación de
inyectar la grilla "solo para el resumen" aparece a los veinte minutos. Y **que se vea igual** exige
reproducir un formulario que alguien posicionó a mano en 2017, con un sistema de diseño que funciona de
otra manera — WPF no posiciona en píxeles absolutos, y eso es una ventaja que aquí trabaja en contra.

**Datos de entrada**

| Qué | Detalle |
|---|---|
| `StockForm` de la fase 12 | Con su `Click` de sesenta líneas y sus tres bugs de concurrencia ya manejados |
| `QueryCoordinator` | Se reusa tal cual: la pieza que maneja los tres bugs |
| Existencias de Bogotá | ~50.000 filas; consulta de ocho segundos |
| … de ellas sin título | Las huérfanas de la fase 09, que el resumen tiene que seguir contando |
| El resumen actual | `"Total: 240 unidades en 3 registros (2 sin título)"` — **formato exacto**, porque el almacén lo lee todos los días |

**Criterios de aceptación**

1. `StockViewModel` **no referencia ningún tipo de WPF**. Una búsqueda en el repositorio lo demuestra, y el
   proyecto de pruebas **no referencia `PresentationFramework`**.
2. Hay **al menos ocho pruebas** que ejercitan la lógica sin instanciar una ventana: el resumen con y sin
   huérfanos, el estado de los comandos, la cancelación por segunda consulta, el filtro que no reconsulta,
   y el fallo del servicio como estado.
3. Las pruebas corren en **menos de dos segundos** y **en un entorno sin interfaz gráfica** — comprobado
   ejecutándolas sin sesión de escritorio, o al menos documentando que no requieren `[STAThread]`.
4. La ventana WPF hace lo mismo que el formulario WinForms: mismo resumen **con el formato exacto**, mismo
   filtro, mismos botones con el mismo comportamiento de habilitación.
5. El diagnóstico de binding está elevado a error en desarrollo, y hay **una prueba manual documentada** de
   que un binding mal escrito ahora falla ruidosamente.
6. **Medición de cierre:** las cuatro configuraciones de la tabla, más el conteo de pruebas sin interfaz y
   de líneas sin cubrir. Van en el mensaje del tag `mini-13`.

**Restricciones de estilo y alcance**

Código nuevo: nullable activado, advertencias como errores, `async` de punta a punta con token propagado.
Y una restricción que es el punto de la fase: **sin marco de MVVM**. `INotifyPropertyChanged`, el comando y
la clase base se escriben a mano — unas cuarenta líneas entre los tres— porque el ejercicio 20 pregunta si
conviene adoptar uno y esa pregunta no se puede responder sin haber escrito el mecanismo.

Del XAML entra lo mínimo. **Sin estilos, sin plantillas, sin temas**, y sin intentar que se vea moderno.

**La trampa**

Vas a escribir el modelo de vista, las pruebas van a pasar, la ventana va a abrir, y **la etiqueta del
resumen va a estar vacía**.

No va a haber error. No va a haber excepción. Las nueve pruebas van a seguir verdes, porque el modelo de
vista está perfecto: el que falla es el XAML, y el binding no avisa. El rastro está en la ventana de salida
del depurador, entre cien líneas de otras cosas, y dice algo como *"cannot resolve property"* con un nombre
que te va a parecer correcto hasta que lo mires tres veces.

Cuando te pase —y va a pasar, porque el nombre que vas a escribir mal es probablemente el mismo que escribí
yo en la sección 4— haz dos cosas: **eleva el diagnóstico de binding a error** antes de seguir, y escribe
en dos líneas por qué las pruebas verdes no te protegieron. La respuesta es la que hace difícil WPF y es lo
que el veredicto de la fase 14 tiene que pesar.

<details><summary>Pista 1 — el enfoque</summary>

Empieza por las pruebas. En serio: escribe primero las ocho pruebas contra un modelo de vista que todavía
no existe, y deja que su firma la decida lo que las pruebas necesitan. Si empiezas por el XAML, el modelo
de vista va a acabar teniendo forma de vista.

Y para "que se vea igual": WPF no posiciona en píxeles: usa `Grid` con filas y columnas. No intentes
reproducir las coordenadas — reproduce **el resultado visual**, que es lo que el almacén ve.

</details>

<details><summary>Pista 2 — la herramienta</summary>

Para la clase base, `INotifyPropertyChanged` con `[CallerMemberName]`, que evita escribir el nombre de la
propiedad como cadena:
`https://learn.microsoft.com/dotnet/api/system.componentmodel.inotifypropertychanged`

Para el comando, `ICommand` con sus dos miembros y el evento `CanExecuteChanged`:
`https://learn.microsoft.com/dotnet/api/system.windows.input.icommand`

Y para la trampa, **esta es la línea que hay que conocer y casi nadie conoce**:
`https://learn.microsoft.com/dotnet/desktop/wpf/data/how-to-debug-data-binding` — el diagnóstico de
binding, que convierte el fallo silencioso en ruidoso.

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```csharp
// Las tres piezas escritas a mano, y son cuarenta líneas entre las tres.
public abstract class ViewModelBase : INotifyPropertyChanged
{
    public event PropertyChangedEventHandler? PropertyChanged;
    protected bool SetProperty<T>(ref T field, T value, [CallerMemberName] string? name = null);
}

public sealed class RelayCommand(Action execute, Func<bool>? canExecute = null) : ICommand
{
    public event EventHandler? CanExecuteChanged;
    public bool CanExecute(object? parameter);
    public void Execute(object? parameter);
    public void RaiseCanExecuteChanged();
}

// La asincrónica, que es la interesante: tiene que evitar la reentrada y exponer la tarea para
// que las pruebas puedan esperarla. Ese segundo requisito es el que la hace comprobable.
public sealed class AsyncCommand(Func<Task> execute, Func<bool>? canExecute = null) : ICommand
{
    public Task ExecuteAsync();
}
```

</details>

**Cómo se entrega**

```powershell
dotnet test src\modern\Sige.Desktop.Tests -c Release
dotnet run -c Release --project src\modern\Sige.Desktop
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 13 --rows 50000 --cold-start
```

```bash
git tag -a mini-13 -m "Mini F13: existencias en WPF con MVVM · <N> pruebas sin interfaz en <T> ms · arranque <X> ms vs <Y> ms en WinForms · fluidez <F> fps"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Escribe `ViewModelBase` con `SetProperty` y `[CallerMemberName]`, y una prueba que verifique que el
   evento se dispara una vez y con el nombre correcto.
2. Implementa `RelayCommand` y enlázalo a un botón. Demuestra que el botón se deshabilita solo cuando
   `CanExecute` devuelve `false`.
3. Escribe la prueba que verifica el formato exacto del resumen, incluida la parte de los huérfanos.
4. Escribe mal un nombre en un binding a propósito y encuentra el mensaje en la ventana de salida del
   depurador. Anota cuánto tardaste.
5. Eleva el diagnóstico de binding a error y repite el ejercicio 4. Compara las dos experiencias.
6. Cambia una `List<T>` por `ObservableCollection<T>` y demuestra que agregar un elemento actualiza la
   grilla sin reasignar la fuente.

**🟡 Intermedio (7–14)**

7. Escribe `AsyncCommand` que evite la reentrada y exponga la tarea, y la prueba que verifica el estado
   intermedio con `TaskCompletionSource`.
8. Implementa `INotifyDataErrorInfo` para validar que el almacén está seleccionado, y muestra el error en
   la vista sin escribir código en la vista.
9. Rompe la virtualización envolviendo la grilla en un `ScrollViewer` y mide el pintado de 50.000 filas
   antes y después. Es la deuda 💸 de la fase, medida.
10. Usa `CollectionViewSource` para el filtro en vez de reconstruir la colección, y compara las dos
    versiones en asignaciones con el arnés.
11. Escribe una prueba que falle si alguien agrega un `MessageBox` al modelo de vista. *(Pista: se puede
    hacer con una prueba de arquitectura sobre los ensamblados referenciados.)*
12. Mide el arranque de WPF y de WinForms y explica a qué se debe la diferencia. Después busca qué se puede
    hacer al respecto y si vale la pena.
13. Enlaza la misma vista a **dos** modelos de vista distintos —uno real y uno de diseño con datos falsos—
    y explica para qué sirve el segundo.
14. Deja la ventana abierta ocho horas con una consulta cada cinco minutos y mide la memoria al final. Es
    el caso real de las noventa personas y el defecto que una demo no encuentra.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Una pantalla muestra los datos correctos y el total en blanco. Las pruebas del modelo
    de vista pasan todas. Escribe el procedimiento de diagnóstico completo y di en qué orden mirarías.
16. **Diagnóstico.** La aplicación consume 900 MB después de una jornada. Enumera tres causas típicas de
    WPF —una involucra suscripciones a eventos, otra el árbol visual— y di cómo distinguirlas con las
    herramientas de diagnóstico.
17. **Medición.** Ejecuta la medición completa de la sección 6, las cuatro configuraciones, y determina
    **los dos umbrales**. Publica el empate en fluidez si aparece, y explica qué implica que una ventaja
    venga "por omisión".
18. **Medición.** Mide cuánto tarda la suite de la fase 12 —la que necesita levantar el formulario, si la
    escribiste— contra la de esta fase. El cociente es el argumento de MVVM en su forma más simple.
19. La lógica del total y del conteo de huérfanos está en el modelo de vista. **Muévela al dominio** donde
    corresponde, y explica qué gana y qué pierde el modelo de vista con eso. *(La respuesta correcta es que
    sí debe moverse, y el ejercicio es hacerlo y notar por qué no se hizo antes.)*
20. **Decisión.** Adoptar un marco de MVVM con sus generadores de código, o quedarse con las cuarenta
    líneas escritas a mano. Decide **ahora que conoces el mecanismo**, y sostén la decisión con el costo de
    mantenimiento de las dos opciones para un equipo de dos personas.
21. **Decisión — ¿se migra, se envuelve o se deja quieto?** Con el formulario funcionando en WinForms y en
    WPF, decide qué se hace con los 339 restantes. Y una variante que la fase 14 va a retomar: **¿tiene
    sentido tener dos tecnologías de escritorio conviviendo?**

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Escribe un modelo de vista que pase todas sus pruebas y produzca una pantalla
    inutilizable. Hay al menos tres formas, y cada una revela algo que las pruebas del modelo de vista no
    pueden cubrir.
23. **Adversarial.** Consigue una fuga de memoria en el modelo de vista que solo se manifieste después de
    varias horas. Después arréglala, y escribe la prueba que la habría detectado en segundos.
24. **Diseño y medición.** Diseña la estrategia de pruebas completa del escritorio: qué se prueba en el
    modelo de vista, qué necesita interfaz de verdad, y **cuánto cuesta cada nivel**. Con los números de
    los ejercicios 17 y 18.
25. **Defiende una decisión.** Duván pregunta por qué el formulario WPF tiene cinco archivos donde el de
    WinForms tenía dos, y si eso no es complicar las cosas. Respóndele en media página, en su lenguaje,
    con el número de pruebas y el tiempo de la suite — y reconociendo la parte en que tiene razón.

**🔥 Opcionales**

- Investiga los generadores de código de un marco de MVVM moderno —los que convierten un campo en
  propiedad observable con un atributo— y compara el código resultante con el de esta fase.
- Escribe la misma pantalla con `CommunityToolkit.Mvvm` y cuenta las líneas. **No lo integres**: el
  ejercicio 20 es la decisión y conviene tener los dos números antes.
- Prueba la misma vista sobre .NET 10 con el modo oscuro de Windows y anota qué se rompe. Guárdalo: es un
  argumento de la fase 14 sobre el costo de mantener apariencia.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://learn.microsoft.com/dotnet/desktop/wpf/data/data-binding-overview` — el binding: qué es, cómo se
  resuelve y en qué momento.
- `https://learn.microsoft.com/dotnet/desktop/wpf/data/how-to-debug-data-binding` — **el diagnóstico de
  binding**. Es la página de la trampa, y es la que casi nadie conoce.
- `https://learn.microsoft.com/dotnet/api/system.componentmodel.inotifypropertychanged` — el contrato, con
  `[CallerMemberName]`.
- `https://learn.microsoft.com/dotnet/api/system.windows.input.icommand` — el comando y su `CanExecute`.
- `https://learn.microsoft.com/dotnet/desktop/wpf/controls/optimizing-performance-controls` —
  virtualización, **y las condiciones en que se pierde**. Es la lectura de la deuda 💸.
- `https://learn.microsoft.com/dotnet/desktop/wpf/data/how-to-sort-and-group-data-using-a-view` —
  `CollectionViewSource` para filtrar sin reconstruir.
- `https://nsubstitute.github.io/help/getting-started/` — NSubstitute, que aquí se usa en serio por primera
  vez.

**Libros / artículos**

- La entrada original de John Gossman sobre MVVM (2005) es corta y explica **por qué** el patrón existe, que
  es más útil que cualquier tutorial. Verifica la URL: es un blog de esa época y ha cambiado de sitio.

> ⚠️ Verifica las URLs. Y la advertencia propia de esta fase: **hay quince años de marcos de MVVM y muchos
> están abandonados**, así que el material que encuentres puede depender de una biblioteca que ya nadie
> mantiene. Lo que no cambia es el mecanismo —`INotifyPropertyChanged` e `ICommand`— y por eso esta fase lo
> escribe a mano. Y una segunda: **mucho material de WPF es de .NET Framework**; el modelo no cambió, pero
> el formato del proyecto y el despliegue sí.

**Orden de lectura sugerido:** antes de escribir, la visión general del binding y el contrato de
`INotifyPropertyChanged`. **Durante el miniproyecto, la página de diagnóstico de binding — y ábrela antes de
que la necesites**, no después. Al cerrar, la de virtualización: es la deuda que la fase 14 cobra.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Existe el mismo formulario en WPF, y existe algo que en la fase 12 no se podía tener: **una suite que
ejercita la lógica de presentación en menos de dos segundos, sin monitor y en CI**. Esas nueve pruebas son
el argumento de MVVM, y son la respuesta a la pregunta de Duván — que era escéptica y tenía razón en
serlo, porque el patrón se puede fingir con tres carpetas y un `DataGrid` inyectado.

Y quedó a la vista lo que WPF cobra por eso: **un enlace roto no produce un error**. Las pruebas verdes y
la pantalla vacía son compatibles, y la defensa son dos cosas que hay que activar a propósito. Es un
intercambio real y la fase 14 lo tiene que pesar: más comprobabilidad a cambio de una clase de fallo que
el compilador no ve.

La fase 14 cierra el bloque y **la medición es la fase**. Cuatro opciones, cinco criterios, y la columna
que decide no es ninguna de las técnicas: es **quién lo puede mantener cuando tú te vayas**, y tiene nombre
propio. Ahí se construye el prototipo de WinUI 3, se mide el despliegue a noventa equipos sin permisos de
administrador —que es donde el prototipo bonito que no se puede instalar deja de competir— y se publica la
tabla del veredicto **con tres columnas llenas y la cuarta declarada pendiente**, porque la web no existe
hasta la fase 18.

> **La señal de que quedó bien:** *"Puedo demostrar que el total está bien sin consultar Bogotá y sin
> contar a mano. Y cuando la pantalla se ve vacía, sé que el problema no está en la lógica."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el miniproyecto
> corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-13 -m "F13 cerrada:
> - StockViewModel sin un solo tipo de WPF, con 9 pruebas que corren sin interfaz
> - el manejador del Click ya no existe: hay comandos con CanExecute
> - deuda de la F12 cobrada: la logica salio del Click y ahora se prueba
> - diagnostico de binding elevado a error: el fallo silencioso ahora es ruidoso
> - la lista sin virtualizacion garantizada queda como deuda, con cobro medido en la F14"
> ```
>
> **Esta fase cobra la deuda más corta del curso** —una fase de distancia— y la factura es la más elocuente
> de todas:
>
> ```bash
> git diff fase-12 fase-13 -- src/modern/Sige.Forms/ src/modern/Sige.Desktop/
> ```
>
> Sesenta líneas que salieron de un manejador de evento y aparecieron en un tipo con nueve pruebas. **El
> diff es legible precisamente porque la fase 12 movió el runtime en un commit aparte** — y si las dos
> cosas se hubieran hecho juntas, este diff tendría cuatrocientas líneas y nadie podría decir qué hizo qué.
> Es el argumento de "una cosa por commit", demostrado en vez de recomendado.

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura.*

- **`INSTINTOS.md`** — dos entradas en la familia *interfaz de escritorio*: el controlador que manipula
  controles —con **la prueba de si el patrón está bien aplicado**: ¿se puede instanciar el modelo de vista
  sin referenciar WPF?— y el binding tratado como magia. La segunda necesita las tres defensas, porque sin
  ellas la entrada solo describe un problema.
- **`BENCHMARKS.md`** — entrada ⏳ *F13 · WinForms contra WPF, con virtualización sana y rota*. Y la
  segunda tabla —pruebas sin interfaz y líneas sin cubrir— **no lleva veredicto a propósito**, porque no es
  una comparación de rendimiento: es el argumento de la fase. Conviene que el archivo lo diga, porque es la
  primera entrada del curso con una tabla no comparativa.
- **Deuda 💸 cobrada:** la lógica en el `Click` (F12 → F13). Su factura es la más didáctica del curso y
  conviene anotarlo en el libro de §7.1: **el diff es legible porque la migración de runtime fue un commit
  aparte**, y eso convierte "una cosa por commit" en algo demostrado.
- **Deuda 💸 plantada:** la virtualización que se pierde en silencio, cobro en F14 **con medición**. Ya
  queda en el libro; conviene anotar que la deuda se cobra *midiendo el error*, no arreglándolo — es una
  forma de cobro que no se había usado.
- **Tipos y proyectos nuevos para el congelamiento:** `Sige.Desktop`, `Sige.Desktop.Tests`,
  `StockViewModel`, `ViewModelBase`, `RelayCommand`, `AsyncCommand`, `IInventoryClient`,
  `InventoryUnavailableException`.
- **Para la fase 14:** esta fase deja **tres datos** que la 14 no debe volver a medir: arranque de WPF,
  fluidez con 50.000 filas, y el costo de la virtualización rota. Más el conteo de pruebas sin interfaz, que
  es un criterio de la tabla del veredicto y no una curiosidad.
- **Para la fase 18:** el modelo de vista **no tiene WPF adentro**, así que en principio la misma lógica
  sirve para Blazor. Eso no estaba planeado y es un beneficio real que la 18 debería aprovechar y decir —
  o desmentir con datos, si resulta que no encaja tan bien.
- **Riesgo detectado:** el ejercicio 19 pide mover el total y el conteo de huérfanos al dominio, y **la
  respuesta correcta es que sí deben moverse** — o sea que la sección 5.1 deja lógica de negocio en el
  modelo de vista a sabiendas. Conviene decidir si eso merece ser una deuda 💸 declarada en vez de solo un
  ejercicio. **Recomendación: declararla**, con cobro en la F15, que es donde el dominio recibe su capa de
  servicios.
