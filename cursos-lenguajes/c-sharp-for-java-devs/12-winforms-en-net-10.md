# 🪟 Fase 12 — WinForms sobre .NET 10, y lo que de verdad cuesta salir de Framework

> C# para desarrolladores Java senior · Fase 12 de 24 · Bloque C — el escritorio
> Depende de: 11 · Habilita: 13
> Estilo de esta fase: **mixto 🧬** — el formulario es de 2017 y se mueve de runtime conservando su
> estilo; lo que se agrega para que responda es código nuevo, en su propio archivo.
> Proyecto que avanza: **SIGE cliente**. Al terminar, el formulario de existencias corre sobre .NET 10 y
> **no congela la ventana** durante la consulta de ocho segundos.

---

## 🎯 1. Propósito

Abrir el bloque que el resto del curso no podría tener: **qué se hace con 340 formularios**.

Y abrirlo por lo más incómodo, que es averiguar cuánto cuesta de verdad salir de .NET Framework cuando hay
un diseñador visual, controles que compró alguien en 2018, noventa equipos que hay que actualizar sin
permisos de administrador, y una persona —Duván— que va a mantener el resultado cuando tú te vayas.

Y hay una cosa que esta fase tiene que sostener sin ironía y sin concesiones a regañadientes, porque el
veredicto del bloque tiene que poder salir por aquí:

> 🧭 **Quedarse en WinForms sobre .NET 10 es una opción legítima en 2026**, y para 340 formularios que
> funcionan puede ser la correcta. No es una concesión: es una de las cuatro respuestas que la fase 14
> va a medir con el mismo rigor que las otras tres.

---

## ✅ 2. Qué queda listo al terminar

- [ ] `Sige.Forms` corre sobre **.NET 10**, con `<UseWindowsForms>true</UseWindowsForms>`, y el formulario
      de existencias se ve y se comporta igual que antes — o **mejor**, y la diferencia está documentada.
- [ ] El formulario **no congela la ventana** durante la consulta de ocho segundos, y hay una forma de
      cancelarla.
- [ ] Está resuelto el problema de densidad de píxeles: el formulario ya no se ve borroso en un monitor
      moderno, y sabes qué línea lo resolvió.
- [ ] Están identificados los **controles de terceros** y qué pasó con cada uno: cuál tiene versión para
      .NET moderno, cuál no, y qué se hizo en cada caso.
- [ ] Está **medido** —no estimado— qué cuesta desplegar a noventa equipos sin permisos de administrador.
- [ ] 💸 La lógica de negocio **sigue en el manejador del botón**, declarada como deuda con su cobro en la
      fase 13. Esta fase no la saca de ahí, y eso es deliberado.
- [ ] Puedes defender, con argumentos y no con nostalgia, por qué quedarse en WinForms es una opción
      legítima — y también en qué caso no lo es.
- [ ] La medición de la sección 6 está escrita con su comando, y la entrada quedó en `BENCHMARKS.md`.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **MVVM y el modelo de vista comprobable** → fase 13. Aquí la lógica **se queda** en el `Click`, porque
  mover el runtime y rediseñar la arquitectura de presentación el mismo día produce un diff que nadie
  puede revisar. Es la misma regla de la fase 11 aplicada al escritorio.
- **El veredicto del escritorio** → fase 14. Esta fase mide una opción; la comparación de las cuatro es
  de allí.
- **WinUI 3, MAUI y Blazor Hybrid** → fase 14.
- **Los otros 339 formularios.** Se cuentan como historia: el curso toca **uno** —este, que la fase 13 rehace
  en WPF y la 14 vuelve a levantar como prototipo— y el reflejo que el lector se lleva es **no tocar los otros
  339 sin motivo**.
- **Estilos, temas y apariencia moderna.** Fuera, con su razón: un formulario que funciona y se ve como
  en 2017 es un formulario que funciona. Repintarlo es un proyecto de diseño y no de migración.

---

## 🧠 4. Concepto mínimo

### Qué cambia y qué no al mover WinForms a .NET 10

**WinForms existe en .NET moderno**, con el mismo modelo de programación, el mismo diseñador en Visual
Studio, y la mayoría de la superficie de API idéntica. No es una capa de compatibilidad: es un puerto
mantenido, con mejoras propias. Eso sorprende a quien asume que Microsoft lo abandonó, y es el dato que
hace posible el resto de la fase.

Lo que cambia son cuatro cosas, y ninguna es del modelo de programación:

**El proyecto.** `<UseWindowsForms>true</UseWindowsForms>` en un `.csproj` de formato SDK reemplaza las
sesenta líneas de referencias declaradas a mano. El `.Designer.cs` sigue funcionando igual y el diseñador
lo sigue editando.

**La densidad de píxeles.** El formulario de 2017 no declara compatibilidad con monitores de alta
densidad, así que Windows lo escala por su cuenta y se ve borroso — que es una de las quejas reales de las
noventa personas. En .NET moderno se resuelve con una llamada en el arranque, y ahí hay una **mejora
gratuita** que conviene cobrarse: el lector va a querer una victoria visible en esta fase.

**Los controles de terceros**, que es donde se acaba lo mecánico. Una biblioteca de rejillas o de
gráficos comprada en 2018 puede tener versión para .NET moderno, puede tenerla de pago, o puede no
tenerla. Y es la única categoría de esta fase donde la respuesta no depende de ti.

**El despliegue.** `ClickOnce` sigue existiendo y funciona con .NET moderno, con una diferencia que
importa: la aplicación necesita un runtime instalado, o hay que publicarla autocontenida —y entonces cada
actualización son 70 MB por equipo en vez de 2—. Con noventa equipos y la conexión del depósito de Lima,
esa aritmética decide.

### El hilo de interfaz, que es lo único que hay que entender bien

Todo lo demás de esta fase es logística. Esto es lo conceptual, y el lector ya lo sabe con otro nombre.

Una aplicación de escritorio tiene **un hilo que posee la ventana** y un bucle que procesa mensajes:
teclado, ratón, repintado. Cualquier cosa que bloquee ese hilo detiene el bucle, y la ventana deja de
repintar — Windows lo detecta y la marca como *"no responde"*, aunque el proceso esté trabajando
perfectamente.

```csharp
// ❌ Lo que hace el formulario de 2017. Ocho segundos con la ventana congelada.
private void btnConsultar_Click(object sender, EventArgs e)
{
    DataSet datos = this.dataAccess.GetStockByWarehouse(codigoAlmacen);   // bloquea el hilo de UI
    this.grdExistencias.DataSource = datos.Tables["EXISTENCIAS"];
}
```

```csharp
// ✅ La versión que responde. Y la firma es `async void`, que la fase 05 prohibió.
private async void btnConsultar_Click(object sender, EventArgs e)
{
    // …
}
```

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El reflejo: "esto hay que reescribirlo sí o sí".**

Es el reflejo más comprensible del curso, y viene de un sitio razonable: el lector viene de un mundo donde
"aplicación" significa servidor, donde la interfaz la hace otro equipo con otra tecnología, y donde un
cliente de escritorio de 2017 con 340 formularios es, a primera vista, la definición de deuda técnica.

```text
❌ El plan que sale de ese instinto, y es el que se presenta en la reunión:
   "WinForms está obsoleto. Reescribamos el cliente como aplicación web: cuarenta pantallas
    al año, empezando por las más usadas. En tres años estamos fuera del escritorio y encima
    nos ahorramos el despliegue."
```

**Por qué falla, y son cuatro razones con números:**

1. **WinForms no está obsoleto.** Está en .NET 10, con soporte de largo plazo hasta 2028 y sin fecha de
   fin de línea anunciada. Que no reciba novedades no es lo mismo que estar muerto: el código que no
   cambia no necesita novedades.
2. **Cuarenta pantallas al año son ocho años y medio, no tres.** Y durante esos años hay que mantener las
   dos versiones, porque nadie va a usar la mitad en el navegador y la mitad en el escritorio.
3. **La web no ahorra el despliegue: lo cambia de sitio.** Deja de haber noventa instalaciones y empieza
   a haber un servidor que tiene que estar disponible, una sesión que expira, y **el depósito de Lima con
   su conexión mala** — donde hoy el formulario funciona contra la base local y en la web funcionaría o
   no. La fase 18 lo va a medir.
4. **Y la razón que decide, que no es técnica:** quien lo mantiene es Duván, que sabe WinForms y C#. Una
   aplicación web con su cadena de construcción, su marco de componentes y su despliegue es una
   plataforma que **su único compañero no domina** — y una plataforma que tu único compañero no domina es
   una plataforma que dura lo que dures tú.

```text
✅ Lo que esta fase propone en su lugar, y es una de las cuatro opciones que la F14 mide:
   Mover los 340 formularios a .NET 10 —que es mecánico— y arreglar las tres cosas que de
   verdad molestan: que se congelan, que se ven borrosos, y que el despliegue es manual.
   Tiempo estimado: semanas, no años. Y las cuarenta pantallas nuevas que Redacción necesita
   se hacen en web, porque son nuevas.
```

**Dónde se rompe el paralelo con lo que traes:** en el banco, reescribir una interfaz era un proyecto con
su equipo y su presupuesto, y el criterio de decisión era el roadmap de producto. Aquí el criterio es
**quién queda sosteniéndolo**, y el equipo son dos personas. Eso no hace la decisión más pobre: la hace
más honesta, porque el costo de mantenimiento no se puede esconder en otro presupuesto.

### La excepción de `async void`, declarada

La fase 05 prohibió `async void` y dejó la excepción escrita de antemano para que esta fase no pareciera
una contradicción. Aquí se usa, y la razón es concreta:

```csharp
// ✅ `async void` es CORRECTO aquí, y es la única vez en las veinticinco fases.
private async void btnConsultar_Click(object sender, EventArgs e)
{
    // Tres razones por las que esto no es el error que la fase 05 describía:
    //
    // 1. La firma la impone el lenguaje: un manejador de evento de WinForms devuelve void, y
    //    no hay sobrecarga que devuelva Task. No es una decisión, es el contrato del delegado.
    //
    // 2. Quien invoca es el bucle de mensajes, que NO espera a nadie. El problema de `async void`
    //    era que el que llama sigue como si hubiera terminado — y aquí eso es exactamente lo que
    //    se quiere: el bucle sigue procesando mensajes, que es por lo que la ventana no se congela.
    //
    // 3. Sus excepciones sí se pueden atrapar, porque el try/catch está DENTRO del manejador. El
    //    problema de la fase 05 era el `catch` alrededor de la llamada, y aquí no hay llamada.
    try
    {
        await LoadStockAsync();
    }
    catch (Exception ex)
    {
        // Y este `catch` ancho también es correcto aquí, y es el segundo del curso que se defiende:
        // una excepción que escape de un manejador de evento **tumba la aplicación**, con las
        // noventa personas dentro. El manejador es la frontera del proceso, igual que el `Main`.
        ShowError(ex);
    }
}
```

> 🧭 **La regla completa, con su excepción adentro, tal como la fase 05 la escribió:** *`async void` solo
> es correcto en un manejador de eventos.* Fuera de ahí sigue siendo un error, y en este curso aparece
> exactamente una vez — en este archivo y en los dos formularios que el Bloque C construye.

### 🩻 Esto sí funciona igual

El modelo de interfaz de escritorio, completo. Si escribiste Swing o JavaFX, ya sabes todo lo conceptual
de esta fase: hay **un hilo que posee los componentes** y solo desde él se pueden tocar; hay un bucle de
eventos; bloquear ese hilo congela la ventana; y para volver al hilo de interfaz desde un hilo de trabajo
hace falta un mecanismo explícito.

| Lo que ya sabes | Aquí se llama |
|---|---|
| *Event Dispatch Thread* de Swing / *JavaFX Application Thread* | el hilo de interfaz, el que creó la ventana |
| `SwingUtilities.invokeLater` / `Platform.runLater` | `Control.Invoke` / `Control.BeginInvoke` — **y casi nunca hacen falta**, porque `await` ya vuelve al hilo correcto |
| `SwingWorker` | `async`/`await`, y es bastante menos ceremonia |
| bloquear el EDT congela la ventana | igual, y Windows además la marca "no responde" |

Y la fila que es mejor noticia de lo que parece: **después de un `await` en un manejador de evento, el
código sigue en el hilo de interfaz**. El contexto de sincronización de WinForms se encarga, así que se
puede tocar la grilla directamente sin un `invokeLater` equivalente. Eso elimina la mitad de la ceremonia
que recuerdas de `SwingWorker`.

> ⚠️ **Y el contexto de sincronización trae de vuelta un peligro que la fase 05 dejó anunciado.** Ese
> mismo mecanismo que hace tan cómodo `await` aquí es el que produce **interbloqueos con `.Result`**: el
> hilo de interfaz se bloquea esperando la tarea, y la tarea necesita el hilo de interfaz para
> continuar. En una aplicación de consola el mismo código funciona; aquí se cuelga para siempre. Es el
> ejercicio 22 de la fase 05, y esta es la fase donde ocurre de verdad.

### 📖 Diccionario de traducción

| Java / escritorio | .NET Framework → .NET 10 | Dónde se rompe el paralelo |
|---|---|---|
| Swing / JavaFX | WinForms / WPF | WinForms sigue soportado en .NET 10 y **no tiene fecha de fin de línea** anunciada |
| `.jar` con `Main-Class` | `.exe` con `Main` | Y con tres modos de publicación: el autocontenido pesa 70 MB y no necesita runtime instalado |
| Java Web Start (muerto) | **ClickOnce** (vivo) | Sigue funcionando con .NET moderno, y es la única opción de despliegue sin permisos de administrador |
| `jpackage` | `dotnet publish` + MSIX o ClickOnce | MSIX necesita firma de código; ClickOnce, no. Eso decide en Cordillera |
| HiDPI con `-Dsun.java2d.uiScale` | `Application.SetHighDpiMode` | Una línea en el arranque, y es una mejora visible gratis |
| `SwingWorker.doInBackground` | `await` en el manejador | Se elimina la ceremonia: después del `await` ya estás en el hilo de interfaz |
| Look and Feel | estilos visuales de Windows | No se toca en esta fase, con su razón escrita |
| JasperReports | Crystal Reports | **Ninguno de los dos existe para .NET moderno**, y es la deuda no pagable de la fase 11 |

> 📝 **Nota de ecosistema, y es la que desarma el reflejo.** WinForms es de 2002 y tuvo su sucesor
> anunciado en 2006 —WPF— que no lo reemplazó. En 2018, cuando Microsoft llevó WinForms y WPF a .NET Core
> 3.0, mucha gente lo leyó como un gesto de compatibilidad; ocho años después las dos siguen ahí, con el
> diseñador funcionando y con soporte de largo plazo. **Esa es la evidencia**, y es más relevante que
> cualquier declaración: una tecnología que sobrevivió a su propio sucesor y a dos cambios de plataforma
> no está obsoleta, está estable. Lo que sí es cierto es que **no va a recibir novedades**, y para un
> formulario que no cambia eso no es un problema — para una aplicación que sí cambia, sí lo es, y esa
> distinción es el veredicto de la fase 14.

---

## 💻 5. Código mínimo con comentarios

### 5.1 El proyecto: sesenta líneas a cuatro

```xml
<!-- ANTES: src/legacy/Sige.Forms/Sige.Forms.csproj -->
<Project ToolsVersion="15.0" DefaultTargets="Build" xmlns="...">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFrameworkVersion>v4.8</TargetFrameworkVersion>
    <!-- … veinte propiedades … -->
  </PropertyGroup>
  <ItemGroup>
    <Reference Include="System.Windows.Forms" />
    <Reference Include="System.Drawing" />
    <!-- … -->
  </ItemGroup>
  <ItemGroup>
    <Compile Include="StockForm.cs"><SubType>Form</SubType></Compile>
    <Compile Include="StockForm.Designer.cs"><DependentUpon>StockForm.cs</DependentUpon></Compile>
  </ItemGroup>
</Project>
```

```xml
<!-- DESPUÉS: src/modern/Sige.Forms/Sige.Forms.csproj -->
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <UseWindowsForms>true</UseWindowsForms>

    <!-- El .Designer.cs se sigue incluyendo por convención y el diseñador de Visual Studio lo
         sigue editando. No hay que declarar nada: es el mismo diseñador. -->

    <!-- 💸 Mismo criterio que la fase 11: el estilo de 2017 se conserva, así que el nullable
         queda desactivado en este proyecto aunque viva en modern/. -->
    <Nullable>disable</Nullable>
    <TreatWarningsAsErrors>false</TreatWarningsAsErrors>
  </PropertyGroup>

  <ItemGroup>
    <ProjectReference Include="..\Sige.Billing\Sige.Billing.csproj" />
  </ItemGroup>

</Project>
```

**Detalles con intención**

- **`UseWindowsForms` hace todo el trabajo** de las referencias: es una propiedad del SDK que agrega el
  marco entero. Los `Reference` a mano desaparecen.
- **El proyecto se mueve a `src/modern/` con su estilo declarado**, igual que `Sige.Billing` en la fase
  11. Es la regla del congelamiento: no hay un tercer subárbol para el código a medio migrar.
- **La referencia a `Sige.DataAccess` cambió a `Sige.Billing`**, porque la fase 11 migró ese módulo. Es la
  primera vez que se nota que el Bloque B dejó las piezas en su sitio.

### 5.2 La mejora gratuita: densidad de píxeles

```csharp
// src/modern/Sige.Forms/Program.cs
[STAThread]
static void Main()
{
    // Estas tres líneas son toda la solución al formulario borroso, y es la victoria visible que
    // esta fase se cobra el primer día. En .NET Framework había que escribir un manifiesto y
    // tocar el registro; aquí es una llamada.
    Application.SetHighDpiMode(HighDpiMode.PerMonitorV2);
    Application.EnableVisualStyles();
    Application.SetCompatibleTextRenderingDefault(false);

    Application.Run(new StockForm());
}
```

**Detalles con intención**

- **`PerMonitorV2` y no `SystemAware`**: en Cordillera hay gente con un portátil y un monitor externo de
  otra densidad, y `SystemAware` se ve mal al mover la ventana entre los dos.
- **Y hay que verificarlo, no asumirlo:** con densidad por monitor, los controles posicionados en píxeles
  absolutos —que son todos los que puso el diseñador en 2017— pueden quedar mal alineados. Es el tipo de
  regresión que solo se ve en un monitor de verdad, y por eso es parte del checklist del miniproyecto.

### 5.3 Que la ventana no se congele

```csharp
// src/modern/Sige.Forms/StockForm.cs — lo que esta fase cambia del manejador
//
// 🧬 El archivo sigue siendo de 2017 en su estilo. Lo que se agrega es el mínimo para que
//    responda, y el trabajo de verdad —sacar la lógica de aquí— es la fase 13.
private CancellationTokenSource cancelacion;

private async void btnConsultar_Click(object sender, EventArgs e)
{
    if (this.cmbAlmacen.SelectedItem == null)
    {
        MessageBox.Show("Seleccione un almacén.", "SIGE");
        return;
    }

    // Si ya había una consulta corriendo, se cancela. Sin esto, dos clics rápidos producen dos
    // consultas y la que termina segunda pinta la grilla — que puede ser la primera. Es un bug
    // que no existía cuando todo era sincrónico, y es el precio de que la ventana responda.
    this.cancelacion?.Cancel();
    this.cancelacion = new CancellationTokenSource();
    CancellationToken token = this.cancelacion.Token;

    string codigoAlmacen = this.cmbAlmacen.SelectedItem.ToString().Substring(0, 3);

    this.btnConsultar.Enabled = false;
    this.btnCancelar.Enabled = true;
    this.lblEstado.Text = "Consultando...";

    try
    {
        // La llamada a la API de la fase 10 —o al procedimiento, según la bandera de corte— sin
        // bloquear el hilo de interfaz. Mientras esto espera, el bucle de mensajes sigue
        // procesando: la ventana repinta, se puede mover, y el botón de cancelar responde.
        StockQueryResult resultado = await this.inventoryClient.GetStockAsync(codigoAlmacen, token);

        // Y aquí ya estamos de vuelta en el hilo de interfaz, sin Invoke y sin ceremonia: el
        // contexto de sincronización de WinForms se encargó. Es la fila del 🩻 que elimina la
        // mitad del SwingWorker que recuerdas.
        this.grdExistencias.DataSource = resultado.Rows;
        this.lblEstado.Text = FormatSummary(resultado);
    }
    catch (OperationCanceledException)
    {
        // La cancelación no es un error: es lo que el usuario pidió.
        this.lblEstado.Text = "Consulta cancelada";
    }
    catch (Exception ex)
    {
        // Este `catch` ancho es correcto y es el segundo del curso que se defiende: una excepción
        // que escape de un manejador de evento tumba la aplicación con las noventa personas
        // dentro. El manejador es la frontera del proceso.
        MessageBox.Show("Error al consultar: " + ex.Message, "SIGE",
                        MessageBoxButtons.OK, MessageBoxIcon.Error);
        this.lblEstado.Text = "Error";
    }
    finally
    {
        this.btnConsultar.Enabled = true;
        this.btnCancelar.Enabled = false;
    }
}
```

**El patrón a memorizar**

> **Hacer que una ventana responda no es una optimización: cambia el modelo de concurrencia de la
> aplicación.** En cuanto la consulta no bloquea, el usuario puede hacer clic dos veces, cambiar de
> almacén a mitad, o cerrar el formulario mientras la consulta corre. Los tres son bugs nuevos que
> **no existían cuando todo era sincrónico**, y los tres hay que manejar. Es el intercambio real, y el
> tutorial que dice "solo agrega `async` y `await`" no lo menciona.

> 💸 **Deuda declarada: la lógica de negocio sigue en el manejador del botón.**
>
> El cálculo del total —que un ajuste negativo resta y una devolución suma—, el conteo de movimientos sin
> título, y el filtro de búsqueda **siguen dentro del `Click`**, exactamente donde los puso 2017. Hoy son
> sesenta líneas que no se pueden probar sin levantar el formulario.
>
> **Se paga en la fase 13**, donde el mismo formulario pasa a tener un modelo de vista comprobable — y el
> argumento de MVVM no va a ser un diagrama: van a ser **las pruebas corriendo sin interfaz**. La factura
> será `git diff fase-12 fase-13 -- src/modern/Sige.Forms/`.
>
> **Por qué no se paga ahora:** porque mover el runtime y rediseñar la arquitectura de presentación el
> mismo día produce un diff que nadie puede revisar, y si algo se rompe no hay forma de saber cuál de las
> dos cosas fue. Es la misma regla de la fase 11 aplicada al escritorio: **una cosa por commit**.

### 5.4 Los controles de terceros, y el despliegue que decide

```text
Controles de terceros en los 340 formularios, y qué les pasó:

  Grilla comercial comprada en 2018, v14        → ✅ tiene versión para .NET 8+; licencia vigente
  Componente de calendario, v3.2 (2016)         → ⚠️ tiene versión, pero de pago y otra licencia
  Control de código de barras, v1.1 (2013)      → ❌ el proveedor no existe. Hay dos formularios
                                                     que lo usan, y uno se puede reescribir
  Visor de Crystal Reports                      → ❌ la deuda no pagable de la fase 11
```

Y el despliegue, que es donde la fase deja su dato más útil:

```powershell
# Las tres opciones, y la aritmética que decide con noventa equipos.
dotnet publish -c Release -r win-x64 --self-contained false   # ~3 MB, necesita runtime instalado
dotnet publish -c Release -r win-x64 --self-contained true    # ~70 MB, no necesita nada
dotnet publish -c Release -r win-x64 -p:PublishSingleFile=true -p:PublishTrimmed=true  # ~40 MB
```

| Opción | Tamaño por actualización | Qué hay que instalar antes | Permisos de administrador |
|---|---|---|---|
| ClickOnce dependiente del framework | ~3 MB | el runtime de .NET 10, **una vez** | **Sí**, para el runtime |
| ClickOnce autocontenido | ~70 MB | nada | **No** |
| MSIX | ~70 MB | nada, pero necesita **certificado de firma** | No, si el certificado es de confianza |

**Detalles con intención**

- **La fila del medio es la que gana en Cordillera**, y la razón es una sola: **no hay permisos de
  administrador** en los noventa equipos, y conseguirlos para instalar un runtime es una gestión que
  Wilson ya intentó dos veces. Setenta megas por actualización son caros; una gestión con sistemas de
  cada oficina, más.
- **Y hay que medirlo, no estimarlo:** setenta megas por noventa equipos son 6,3 GB por actualización, y
  el depósito de Lima tiene la conexión que tiene. **Cuánto tarda una actualización completa** es el dato
  que la fase 14 necesita, y se toma aquí.

**Prueba de fuego**

```powershell
msbuild src\Sige.sln /t:Rebuild /p:Configuration=Release    # lo que queda en 4.8
dotnet build src\Cordillera.slnx -c Release                 # y el formulario, ya en .NET 10
dotnet run -c Release --project src\modern\Sige.Forms
```

Y la mentira que te va a contar la salida si miras el lugar equivocado: **el formulario va a arrancar y
verse perfecto en tu máquina**. Tu máquina tiene el SDK instalado, un solo monitor, y la base a un
milisegundo. Los tres datos que importan —arranque en frío sin SDK, apariencia en dos monitores de
densidad distinta, y la grilla con 50.000 filas contra la base real— no aparecen en esa ejecución. El
único sitio donde esta fase se comprueba de verdad es **un equipo que no sea el tuyo**.

---

## 📏 6. Medición

**Hipótesis:** el mismo formulario sobre .NET 10 arranca más rápido y usa menos memoria que sobre 4.8, y
el pintado de la grilla con 50.000 filas mejora poco — porque el cuello de botella de una grilla con
volumen no es el runtime, es **el control y su modo de enlace**. Y esa diferencia entre lo que mejora
mucho y lo que no mejora es lo que hay que separar.

**Condiciones:** SDK 10.0.401 y .NET Framework 4.8 · Release · Windows 11 · el mismo formulario contra la
base del generador, semilla `19970417` · la grilla con **50.000 filas**, que es el volumen real del
almacén de Bogotá en el histórico · arranque en frío medido **en un equipo sin SDK instalado**, con la
caché de disco limpia · 20 repeticiones con 3 de calentamiento descartadas · arnés propio, y el tiempo de
pintado medido desde que llega el dato hasta que la grilla responde al desplazamiento.

**Competidores:** cuatro configuraciones del **mismo** formulario:

- **4.8 tal como está**, que es el statu quo y lleva nueve años funcionando.
- **.NET 10, sin tocar el modo de enlace** — la migración mecánica y nada más.
- **.NET 10 con la grilla en modo virtual** (`VirtualMode`), que es el cambio que de verdad afecta al
  pintado. Se mide para saber **a qué atribuir la mejora**.
- **.NET 10 autocontenido**, para medir el arranque en frío sin runtime instalado, que es el caso real de
  los noventa equipos.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 12 --rows 50000 --cold-start
```

**Resultado:** ⏳ pendiente de ejecución en tu máquina.

| Configuración | Arranque en frío | Memoria de trabajo | Pintado de 50.000 filas | Desplazamiento fluido |
|---|---|---|---|---|
| .NET Framework 4.8 | ⏳ | ⏳ | ⏳ | ⏳ |
| .NET 10, enlace igual | ⏳ | ⏳ | ⏳ | ⏳ |
| .NET 10, grilla en modo virtual | ⏳ | ⏳ | ⏳ | ⏳ |
| .NET 10 autocontenido | ⏳ | ⏳ | ⏳ | ⏳ |

Y el dato de despliegue, que no es un benchmark pero es el número que la fase 14 necesita:

| Opción de despliegue | Tamaño | Actualizar 90 equipos | Desde el depósito de Lima |
|---|---|---|---|
| ClickOnce dependiente del framework | ⏳ | ⏳ | ⏳ |
| ClickOnce autocontenido | ⏳ | ⏳ | ⏳ |

> ⚖️ **Veredicto** *(expectativa, todavía sin ejecutar — `formato-de-mediciones.md` §2.6)*. Se espera que
> .NET 10 arranque mejor y use menos memoria, y que **el pintado de la grilla quede casi igual** entre las
> dos primeras filas —posiblemente **empate**— porque ahí el runtime no es el problema. Lo que debería
> mover ese número es el modo virtual, y si es así, la conclusión honesta es que **la mejora de fluidez no
> vino de migrar: vino de un cambio que se podía hacer en 4.8 también.** Decirlo es importante: separa lo
> que la migración compra de lo que no.
>
> **Los dos umbrales que tu ejecución tiene que determinar:** (1) **a partir de cuántas filas el modo de
> enlace importa más que el runtime**, que es el número que la fase 13 necesita para su deuda de
> virtualización; y (2) **cuánto tarda actualizar noventa equipos con el paquete autocontenido**, incluido
> Lima — que es una de las cinco columnas del veredicto de la fase 14 y **no se estima**.

---

## 🧱 7. Miniproyecto — el formulario de existencias, migrado y que responde

**El encargo**

Duván, y por primera vez en el curso el encargo es sobre su propio trabajo: *"Si movemos los formularios a
.NET 10, yo tengo que poder seguir abriéndolos en el diseñador y arreglar un ancho de columna sin
preguntarle a nadie. Eso es lo que necesito que compruebes con este. Y lo otro: el almacén se queja de que
la ventana se queda pegada cuando consultan Bogotá — si eso se arregla, me quito de encima tres llamadas
por semana."*

**Por qué duele**

Porque el encargo tiene una condición que no es de código: **que el diseñador siga funcionando**. Una
migración que dejara los formularios compilando pero no editables visualmente le quitaría a Duván la única
herramienta con la que mantiene 340 pantallas, y eso convierte una mejora técnica en un problema
operativo. Hay que comprobarlo, no suponerlo.

Y porque arreglar el congelamiento **introduce tres bugs nuevos** que no existían: el doble clic, el cambio
de almacén a mitad de consulta, y el formulario que se cierra mientras la consulta corre.

**Datos de entrada**

El formulario tal como quedó en la fase 07, más la base del generador:

| Qué | Detalle |
|---|---|
| `StockForm` | El `Click` de 2017 con sus 60 líneas: validación, consulta, filtro, total y pintado |
| Su `.Designer.cs` | Controles posicionados en píxeles absolutos, como los puso el diseñador en 2017 |
| Existencias de Bogotá | ~50.000 filas en el histórico; la consulta tarda **ocho segundos** |
| … de ellas sin título | Las huérfanas de la fase 09: el almacén está acostumbrado a verlas en blanco |
| Controles de terceros | La grilla comercial —con versión moderna— y el calendario —de pago— |
| Equipos de destino | 90, **sin permisos de administrador**, uno de ellos en el depósito de Lima |

**Criterios de aceptación**

1. `Sige.Forms` corre sobre .NET 10 y **el formulario se abre en el diseñador de Visual Studio 2026**.
   Comprobado abriéndolo, moviendo un control y compilando. Este criterio no es negociable: es el encargo.
2. La ventana **no se congela** durante la consulta de ocho segundos: se puede mover, repinta, y el botón
   de cancelar funciona. Una grabación de pantalla o una prueba de interfaz lo demuestra.
3. Los **tres bugs nuevos** están manejados: doble clic, cambio de almacén a mitad, y cierre del formulario
   con la consulta en vuelo. Una prueba o un procedimiento manual documentado por cada uno.
4. El formulario **se ve bien en dos monitores de densidad distinta**, y si algún control quedó mal
   alineado, está corregido y anotado.
5. El paquete de despliegue está construido en las dos variantes, con su tamaño medido, y **está calculado
   —no estimado— cuánto tarda actualizar los noventa equipos**, incluido Lima.
6. **Medición de cierre:** las cuatro configuraciones de la tabla, con arranque en frío en un equipo sin
   SDK. Van en el mensaje del tag `mini-12`.

**Restricciones de estilo y alcance**

🧬 Mixta, y con una regla estricta: **el archivo del formulario conserva su estilo de 2017**. Se agrega lo
mínimo para que responda —`async`, el token, el manejo de los tres bugs— y **no se toca nada más**: ni los
nombres, ni el `this.` explícito, ni el cálculo del total, que es la deuda 💸 de la fase 13.

Lo que nace nuevo —el cliente HTTP hacia la API de la fase 10— va en su propio archivo, en estilo nuevo.

**La trampa**

Vas a poner `async` y `await` en el manejador, y el compilador te va a dar una advertencia sobre `async
void` que te va a hacer dudar. La vas a buscar, vas a encontrar diez artículos diciendo que `async void`
es un error, y **vas a intentar arreglarlo** — probablemente con `async Task` y un `.Wait()` en el
manejador, o con `Task.Run(...).Wait()`.

Y la aplicación se va a colgar. No lentamente: **para siempre**, sin consumir CPU, sin error.

La causa es el contexto de sincronización de WinForms, y es el ejercicio 22 de la fase 05 ocurriendo de
verdad: el hilo de interfaz se bloquea esperando la tarea, y la continuación de la tarea necesita el hilo
de interfaz para ejecutarse. En una aplicación de consola el mismo código funciona, y eso es lo que hace
tan difícil el diagnóstico.

Cuando te pase, escribe en tres líneas por qué `async void` **es** la respuesta correcta aquí y por qué la
advertencia existe igual. Y si te tienta silenciarla con un `#pragma`, lee primero la sección 4: la
prohibición de la fase 05 ya traía esta excepción escrita.

<details><summary>Pista 1 — el enfoque</summary>

Tres cosas separadas: **migrar** el proyecto (mecánico, y se comprueba abriendo el diseñador), **hacer que
responda** (el manejador y sus tres bugs nuevos), y **empaquetar** (dos variantes y su aritmética). No las
mezcles en el mismo commit: si algo se rompe, querrás saber cuál de las tres fue.

Para los tres bugs, el patrón es el mismo en los tres: **qué pasa con la operación anterior cuando llega
la siguiente**. En cuanto lo nombres así, la solución es una sola pieza.

</details>

<details><summary>Pista 2 — la herramienta</summary>

Para migrar el proyecto, `upgrade-assistant` también entiende WinForms, o se hace a mano con
`UseWindowsForms`:
`https://learn.microsoft.com/dotnet/desktop/winforms/migration/`

Para la densidad de píxeles, `Application.SetHighDpiMode` y las diferencias entre sus modos:
`https://learn.microsoft.com/dotnet/desktop/winforms/high-dpi-support-in-windows-forms`

Para la grilla con volumen, `DataGridView.VirtualMode` — que es lo que de verdad mueve el número del
pintado:
`https://learn.microsoft.com/dotnet/desktop/winforms/controls/implementing-virtual-mode-wf-datagridview-control`

Y para el cierre del formulario con la consulta en vuelo, mira `FormClosing` y qué hacer con el
`CancellationTokenSource` ahí.

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```csharp
// El cliente de la API, en estilo nuevo y en su propio archivo. 🧬 Es el borde del formulario.
internal sealed class InventoryApiClient(HttpClient http)
{
    public Task<StockQueryResult> GetStockAsync(string warehouseCode, CancellationToken token);
}

// Lo que el formulario necesita para manejar los tres bugs nuevos, en una sola pieza.
internal sealed class QueryCoordinator : IDisposable
{
    // Cancela la anterior y devuelve el token de la nueva.
    public CancellationToken StartNew();
    public void CancelCurrent();
    public void Dispose();
}

// Y el resumen que el formulario pinta, que por ahora sigue calculándose en el Click (deuda F13).
internal sealed record StockQueryResult(
    IReadOnlyList<StockRow> Rows,
    int TotalUnits,
    int RowsWithoutTitle);
```

</details>

**Cómo se entrega**

```powershell
dotnet build src\Cordillera.slnx -c Release
dotnet publish src\modern\Sige.Forms -c Release -r win-x64 --self-contained true
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 12 --rows 50000 --cold-start
```

```bash
git tag -a mini-12 -m "Mini F12: StockForm en .NET 10, sin congelarse · arranque <X> ms vs <Y> ms · paquete <Z> MB · 90 equipos en <T>"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Convierte `Sige.Forms` al formato SDK y abre el formulario en el diseñador. Anota si algo se rompió.
2. Agrega `Application.SetHighDpiMode(HighDpiMode.PerMonitorV2)` y compara el formulario antes y después
   en un monitor de alta densidad.
3. Haz que la consulta no congele la ventana con `async`/`await`, y comprueba que se puede mover mientras
   corre.
4. Agrega un botón de cancelar que funcione, y verifica que la cancelación no deja la interfaz en un
   estado raro.
5. Publica el formulario en las tres variantes y anota los tres tamaños.
6. Provoca el doble clic en el botón de consultar y describe qué pasa con la grilla. No lo arregles
   todavía: descríbelo.

**🟡 Intermedio (7–14)**

7. Maneja los tres bugs nuevos con una sola pieza —el coordinador de consultas— y escribe una prueba por
   cada uno.
8. Convierte la grilla a `VirtualMode` y mide el pintado con 50.000 filas antes y después. Reporta los dos
   números.
9. Cierra el formulario mientras una consulta está en vuelo y documenta qué excepción aparece y dónde.
   Después arréglalo desde `FormClosing`.
10. Reemplaza `async void` por `async Task` con un `.Wait()` en el manejador y **reproduce el
    interbloqueo**. Explica la cadena completa: quién espera a quién.
11. Ejecuta el mismo código del ejercicio 10 en una aplicación de consola y demuestra que **no** se
    cuelga. Explica por qué, y qué implica para el material que encuentres en internet.
12. Identifica los controles de terceros del formulario y busca si tienen versión para .NET moderno.
    Documenta el resultado por control, con su licencia.
13. Mide el arranque en frío en tu máquina y en un equipo sin SDK instalado. Explica la diferencia.
14. Configura ClickOnce para el paquete autocontenido y despliégalo en una máquina virtual sin permisos
    de administrador. Documenta si funcionó.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Después de hacer la consulta asincrónica, el almacén reporta que "a veces la grilla
    muestra los datos del almacén anterior". Explica el mecanismo exacto y escribe la prueba que lo
    reproduce.
16. **Diagnóstico.** El formulario se ve bien en tu monitor y los controles quedan solapados en el de
    Nohora. Enumera tres causas posibles relacionadas con densidad de píxeles y di cómo distinguirlas.
17. **Medición.** Ejecuta la medición de la sección 6 completa, con el arranque en frío en un equipo sin
    SDK, y determina **los dos umbrales**. Publica el empate del pintado si lo hay, y di a qué se debe
    atribuir la mejora de fluidez.
18. **Medición.** Calcula el tiempo real de actualizar noventa equipos con cada variante de despliegue,
    midiendo el ancho de banda disponible en cada oficina. Es una de las cinco columnas del veredicto de
    la fase 14.
19. Mantén la interfaz viva durante la consulta **sin usar `async`** —con un hilo y `Control.Invoke`, como
    se habría hecho en 2017— y compara las dos versiones en líneas de código y en legibilidad.
20. **Decisión — ¿se migra, se envuelve o se deja quieto?** Los 340 formularios. Con lo medido en esta
    fase, decide qué se hace con ellos y sostén la decisión con el costo de las otras dos. *(Guarda tu
    respuesta: la fase 14 la va a comparar con la tabla de cinco criterios.)*
21. **Decisión — ¿se migra, se envuelve o se deja quieto?** El control de código de barras cuyo proveedor
    no existe, usado en dos formularios. Decide, y calcula qué cuesta cada camino — incluido dejar esos
    dos formularios en 4.8 indefinidamente.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Consigue que el formulario asincrónico deje la grilla y el resumen **inconsistentes
    entre sí** —el total de un almacén con las filas de otro— y después arréglalo de forma que sea
    imposible por construcción.
23. **Adversarial.** Haz que la aplicación se cuelgue de tres formas distintas relacionadas con el
    contexto de sincronización, y documenta cada una con su diagnóstico. Es el catálogo que te va a servir
    el resto de tu carrera en escritorio.
24. **Diseño y medición.** Escribe el plan de migración de los 340 formularios a .NET 10: en qué orden,
    cuánto tarda, qué se rompe, qué necesita licencia nueva, y **cuántos quedarían sin migrar y por qué**.
    Con el número de esta fase extrapolado, no inventado.
25. **Defiende una decisión.** Clara pregunta por qué el cliente sigue siendo "una aplicación instalada en
    noventa computadores como en 2005" cuando todo el mundo hace las cosas en el navegador. Respóndele en
    media página, en su lenguaje, con los números de esta fase — y sin decir que la web es peor, porque no
    lo es.

**🔥 Opcionales**

- Investiga el diseñador de WinForms en .NET moderno y por qué durante un tiempo no funcionó. Anota qué
  implica eso para la confianza en una tecnología "estable".
- Prueba `PublishAot` sobre el formulario y anota qué pasa. **No lo arregles**: es la fase 20.
- Escribe el mismo formulario con el diseñador desde cero en .NET 10 y compáralo con el migrado. El
  ejercicio no es el código: es cronometrar las dos cosas y ver cuál conviene con 340 pantallas.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://learn.microsoft.com/dotnet/desktop/winforms/migration/` — la guía de migración de WinForms a
  .NET moderno, con lo que cambia y lo que no.
- `https://learn.microsoft.com/dotnet/desktop/winforms/high-dpi-support-in-windows-forms` — densidad de
  píxeles y sus modos.
- `https://learn.microsoft.com/dotnet/desktop/winforms/controls/implementing-virtual-mode-wf-datagridview-control`
  — `VirtualMode`, que es lo que de verdad mueve el pintado con volumen.
- `https://learn.microsoft.com/visualstudio/deployment/clickonce-security-and-deployment` — ClickOnce, que
  sigue vivo y es la única opción sin permisos de administrador.
- `https://learn.microsoft.com/dotnet/core/deploying/` — los tres modos de publicación y su aritmética.
- `https://learn.microsoft.com/dotnet/core/compatibility/windows-forms` — cambios de comportamiento entre
  WinForms de Framework y de .NET moderno. Es corta y vale.
- `https://dotnet.microsoft.com/platform/support/policy/dotnet-core` — la política de soporte, que es el
  dato duro detrás de "WinForms no está obsoleto".

**Libros / artículos**

- La guía *Modernize existing .NET applications* de Microsoft cubre el escritorio además del servidor.
  Verifica el enlace: se ha reorganizado.

> ⚠️ Verifica las URLs. Y la advertencia central de esta fase: **casi todo lo que vas a encontrar sobre
> WinForms en internet es de .NET Framework**, porque es lo que se escribió entre 2002 y 2018. Mucho sigue
> siendo correcto —el modelo no cambió— y algunas cosas concretas no: el manifiesto de densidad de
> píxeles, el despliegue, y el formato del proyecto. Y la otra cara: **mucho material moderno da por
> muerto a WinForms** sin decir que sigue soportado. Las dos distorsiones existen y conviene saber en qué
> dirección corrige cada fuente.

**Orden de lectura sugerido:** antes de escribir, la guía de migración y la página de compatibilidad —las
dos son cortas—. Durante el miniproyecto, la de densidad de píxeles y la de `VirtualMode`. Al cerrar, la
de ClickOnce y la política de soporte: son las dos que sostienen el argumento del veredicto.

---

## 🚀 10. Cierre y conexión con la siguiente fase

El formulario corre sobre .NET 10, se abre en el diseñador, no congela la ventana, se ve bien en dos
monitores, y hay un paquete que se puede instalar en noventa equipos sin pedirle permisos a nadie. La
migración del runtime fue mecánica; lo que costó trabajo fue **lo que aparece cuando la ventana deja de
congelarse**, que son tres bugs de concurrencia que antes no podían existir.

Y quedó dicho lo que esta fase tenía que sostener: **quedarse en WinForms es una opción legítima**. No
porque migrarlo sea difícil, sino porque WinForms sigue soportado, el diseñador funciona, quien lo mantiene
lo domina, y las 340 pantallas hacen su trabajo. La fase 14 va a medirlo contra las otras tres con el mismo
rigor, y si gana, gana.

La fase 13 es el paso natural y su motivo es la deuda de esta: **sesenta líneas de lógica de negocio dentro
del `Click`**, que no se pueden probar sin levantar el formulario. La 13 las saca a un modelo de vista y
demuestra el argumento de MVVM como hay que demostrarlo — no con un diagrama, sino con **las pruebas
corriendo sin interfaz**. Y de paso construye el mismo formulario en WPF, que es la segunda de las cuatro
opciones del veredicto.

> **La señal de que quedó bien:** *"Duván abrió el formulario en el diseñador, cambió un ancho de columna
> y compiló, sin preguntarme nada. Y el almacén dejó de llamar por la ventana pegada."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el miniproyecto
> corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-12 -m "F12 cerrada:
> - Sige.Forms en .NET 10, con el diseñador funcionando: comprobado, no supuesto
> - la ventana no se congela, y los tres bugs nuevos de concurrencia estan manejados
> - densidad de pixeles resuelta: PerMonitorV2 y los controles verificados en dos monitores
> - controles de terceros inventariados, con su licencia y su destino
> - despliegue a 90 equipos MEDIDO en las dos variantes, Lima incluido
> - la logica sigue en el Click: deuda declarada con cobro en la F13"
> ```
>
> Esta fase **no cobra deuda y planta una**, la más corta del curso: una fase de distancia. Y eso es
> deliberado — el diff de `git diff fase-12 fase-13 -- src/modern/Sige.Forms/` va a ser el argumento
> entero de MVVM, y va a ser legible precisamente porque la migración de runtime se hizo en un commit
> aparte.

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura.*

- **`INSTINTOS.md`** — abre la familia *interfaz de escritorio* con el reflejo de esta fase: *"esto hay
  que reescribirlo sí o sí"*. La entrada necesita **las cuatro razones con números** —soporte vigente,
  ocho años y medio de reescritura, el despliegue que cambia de sitio y no desaparece, y Duván— porque sin
  ellas se lee como defensa de lo viejo. Y conviene un puntero desde la familia de asincronía: la
  excepción de `async void` **se explica aquí**, y la entrada de la F05 ya la anuncia.
- **`BENCHMARKS.md`** — entrada ⏳ *F12 · El mismo formulario en 4.8 y en .NET 10, con y sin modo
  virtual*. Y el dato de despliegue, que no es un benchmark pero **es una de las cinco columnas del
  veredicto de la F14**: conviene que el índice lo marque como dato transversal, igual que la concurrencia
  del codo de la F05.
- **Deuda 💸 plantada:** la lógica en el `Click`, cobro en F13. Ya está en el libro de §7.1. Conviene
  anotar allí que es **la deuda de distancia más corta del curso** —una fase— y por qué: el diff entre los
  dos tags es el argumento de MVVM, y solo es legible si la migración de runtime va en un commit aparte.
- **Tipos y proyectos nuevos para el congelamiento:** `Sige.Forms` se mueve a `src/modern/` con su estilo
  declarado, `InventoryApiClient`, `QueryCoordinator`, `StockQueryResult`, `StockRow`.
- **Para la fase 13:** la deuda se cobra allí, y el `StockQueryResult` de esta fase es el germen del modelo
  de vista. Y la virtualización aparece aquí como medición y allí como deuda propia — conviene que la 13
  cite el número de esta fase en vez de volver a medirlo.
- **Para la fase 14:** esta fase deja **tres datos** que la 14 necesita y que no debería volver a tomar: el
  arranque en frío, la memoria, y el tiempo de actualizar noventa equipos incluido Lima. Si la 14 los
  vuelve a medir, la comparación de las cuatro opciones deja de ser homogénea.
- **Para la fase 18:** el argumento 3 del 🪞 —"la web no ahorra el despliegue, lo cambia de sitio"— es una
  afirmación que la 18 tiene que **medir**, no repetir. Es la latencia desde Lima.
- **Para la fase 20:** el ejercicio 🔥 de AOT sobre el formulario queda sin arreglar a propósito.
- **Riesgo detectado y resuelto:** el criterio 1 del miniproyecto pide abrir el formulario en el
  diseñador, y sin `.Designer.cs` el diseñador no tiene qué abrir. Se agregó
  `src/legacy/Sige.Forms/StockForm.Designer.cs` con **los cinco controles que el curso usa**, con la forma
  que el diseñador genera —posiciones en píxeles absolutos, que es justo lo que se rompe con densidad por
  monitor— y una nota de que el original tiene 400 líneas y veintitrés controles. El criterio se mantiene
  porque **es el encargo de Duván y es el corazón de la fase**.
