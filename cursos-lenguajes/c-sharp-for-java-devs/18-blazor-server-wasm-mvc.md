# 🧵 Fase 18 — Blazor Server ⇄ WebAssembly ⇄ MVC, medidos desde tres países

> C# para desarrolladores Java senior · Fase 18 de 24 · Bloque D — servicios, datos y nube
> Depende de: 17 · Habilita: 19
> Estilo de esta fase: **nuevo** (.NET 10, C# 14)
> Proyecto que avanza: **nace Redacción**. Y se completa **la cuarta columna del veredicto del escritorio**
> que la fase 14 dejó declarada pendiente.

---

## 🎯 1. Propósito

El camino de un manuscrito —recepción, lectura, informe, contrato, edición, maquetación, pruebas, imprenta—
vive hoy en correos, en una hoja compartida y en una carpeta de Drive cuyos permisos nadie audita desde 2019.
En marzo se descubrió que un traductor externo llevaba **dos años con acceso de edición a la carpeta de
contratos**.

Redacción es el back-office que reemplaza eso: cuarenta pantallas, roles, y un rastro de quién cambió qué. Y
como no hay equipo de frontend —hay dos personas que mantienen la tienda— el ecosistema ofrece tres modelos de
render y **esta fase los mide en serio** en vez de elegir por costumbre.

Y hace una segunda cosa que el curso debe desde la fase 14: **completar la cuarta columna del veredicto del
escritorio**, con la metodología que esa fase congeló y sin rediscutirla.

> 🧭 **La regla de la fase, y es la que la hace distinta de cualquier comparación de frameworks:** *el modelo
> de render es una decisión de latencia antes que de programación.* Lo que se siente bien en tu máquina, a un
> milisegundo del servidor, puede ser inusable en el depósito de Lima — y eso no se estima: se inyecta y se
> mide.

Y hay dos criterios que pesan más que la medición, y los ponen dos personas:

- **Nohora** tiene que poder corregir un registro mal grabado **a las siete de la tarde, sin llamar a nadie**.
- **Ximena** publica ocho títulos al mes con un equipo que debería publicar cuatro. **Si la herramienta le
  agrega un paso, no la usa** — y va a tener razón.

Una opción que falle esos dos criterios está mal **aunque gane la medición**.

---

## ✅ 2. Qué queda listo al terminar

- [ ] La pantalla de recepción de manuscritos existe **en los tres modelos** —Blazor Server, WebAssembly y MVC
      clásico— con la misma funcionalidad: formulario, validación, lista y edición.
- [ ] La latencia está **inyectada y medida** para las tres oficinas: Bogotá, Ciudad de México y el depósito de
      Lima. No estimada.
- [ ] Está medido el **peso de la carga inicial** y la **memoria de servidor por usuario conectado**, que es el
      número que decide si Blazor Server escala para noventa personas.
- [ ] Los formularios **comparten la validación con el servidor**: una regla escrita una vez, aplicada en los
      dos lados.
- [ ] Está verificado que **Nohora puede corregir un registro a las siete de la tarde** y que **el flujo de
      Ximena no ganó ningún paso**. Los dos, comprobados con ella y con ella, no supuestos.
- [ ] 💸 La primera versión sale **sin rastro de auditoría de quién vio qué**, declarado, con cobro en la
      fase 19.
- [ ] **La cuarta columna del veredicto del escritorio está completa** en la entrada consolidada de
      `BENCHMARKS.md`, con la metodología de la fase 14 — y si el veredicto cambió, está dicho **qué lo movió**.
- [ ] La medición de la sección 6 está escrita con su comando, y la entrada quedó en `BENCHMARKS.md`.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Un framework de JavaScript.** Declarado fuera, con su razón y sin condescendencia: React, Angular o Vue
  son opciones perfectamente buenas y **Cordillera no tiene equipo de frontend**. Hay dos personas que
  mantienen la tienda, y adoptar un ecosistema con su cadena de construcción, sus dependencias y su ciclo de
  actualización es una plataforma más que mantener con las mismas dos personas. **No es una decisión técnica
  sobre los frameworks: es una decisión sobre el equipo.**
- **Las cuarenta pantallas.** Esta fase construye **una**, tres veces. El plan de las cuarenta sale del
  veredicto, y la fase 24 lo revisa.
- **Auditoría de quién vio qué** → fase 19, y es la deuda de esta fase.
- **Observabilidad y trazas** → fase 19.
- **Despliegue y costo de servir la web** → fase 20.
- **Diseño visual y accesibilidad más allá de lo mínimo.** Fuera con su razón: la comparación es de modelos de
  render, y una opción que además se vea mejor contamina la medición. El ejercicio 🔥 de accesibilidad señala
  lo que la fase **no** cubrió.

---

## 🧠 4. Concepto mínimo

### Los tres modelos, y qué decide entre ellos

Los tres escriben C# y comparten el 80% del código. Lo que cambia es **dónde se ejecuta el componente y qué
viaja por la red**, y de ahí sale todo lo demás.

**MVC clásico.** El servidor renderiza HTML completo, el navegador lo muestra, y cada interacción que necesita
datos nuevos es una petición que devuelve una página. Es el modelo de 2009 y **funciona en cualquier conexión**:
si la red es mala, la página tarda en llegar y después se usa sin problema. Lo que se pierde es la
interactividad rica — un filtro que reacciona al teclear exige JavaScript.

**Blazor Server.** El componente se ejecuta **en el servidor** y el navegador mantiene una conexión abierta —un
*circuito*— por la que viajan los eventos de interfaz y las instrucciones de repintado. Escribir es cómodo: el
componente tiene acceso directo a la base de datos y a los servicios, sin API intermedia. Y el costo está en
dos sitios: **cada interacción es un viaje de ida y vuelta** —así que la latencia se siente en cada tecla— y
**cada usuario conectado consume memoria en el servidor** mientras su circuito viva.

**Blazor WebAssembly.** El componente se descarga y se ejecuta **en el navegador**. Después de la carga
inicial, la interacción es local e instantánea, y la conexión solo se usa para datos. El costo está en esa
carga inicial —varios megabytes de runtime y ensamblados— y en que el componente **ya no puede hablar con la
base**: necesita una API, que es justamente la que las fases 15 y 16 construyeron.

> 🧠 **El modelo mental, y es lo único que hay que retener:** en MVC viaja **la página**; en Blazor Server
> viaja **cada interacción**; en WebAssembly viaja **la aplicación, una vez**. Los tres tienen un momento caro
> y es distinto: MVC lo paga en cada navegación, Server en cada clic, y WebAssembly al principio y solo una
> vez. **Cuál duele más depende de la conexión de quien lo usa**, y por eso la medición es por oficina y no
> global.

### El circuito de Blazor Server, que es lo que hay que entender bien

Es lo único conceptualmente nuevo de la fase, y es donde están sus dos problemas.

Un circuito es el estado de la sesión de un usuario **viviendo en el servidor**: los componentes, sus campos,
lo que el usuario escribió y todavía no envió. Eso da una ergonomía notable —el estado sobrevive entre
interacciones sin que nadie lo serialice— y trae dos consecuencias que hay que mirar de frente:

**La memoria por usuario es real y hay que dimensionarla.** Noventa personas con una pantalla abierta ocho
horas son noventa circuitos vivos. Cuánto pesa cada uno es una de las columnas de la medición, y el resultado
decide si hace falta un servidor más.

**Y si la conexión se corta, el circuito se pierde.** El marco reintenta reconectar y, si el circuito ya se
recicló, **el usuario pierde lo que estaba escribiendo**. En Bogotá eso pasa poco; en el depósito de Lima, con
la conexión que tiene, pasa — y esa es la trampa de la fase.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**Primera: elegir el modelo de render por moda.**

```text
❌ El razonamiento, y viene con buena intención:
   "Una SPA es el estándar moderno. WebAssembly nos da una SPA en C#, sin JavaScript y sin
    equipo de frontend. Es obviamente la mejor de las tres."
```

**Por qué falla:** porque "el estándar moderno" describe lo que hace la industria, no lo que le conviene a
Cordillera. Y la SPA tiene un costo concreto que en este caso pega donde más duele: **la carga inicial**. Un
paquete de varios megabytes descargado desde el depósito de Lima, en una conexión mala, es una espera larga la
primera vez y en cada actualización del caché.

Y hay una segunda razón, menos obvia: **una SPA necesita una API para todo**, y eso es más código —el
servicio, el contrato, la serialización, el manejo de errores en dos lados— que el curso ya tiene construido
para el catálogo, sí, pero que **habría que construir para las cuarenta pantallas de Redacción**. Con Blazor
Server ese trabajo no existe: el componente llama al servicio directamente.

```text
✅ Lo que esta fase hace en su lugar:
   Las tres, la misma pantalla, medidas con la latencia de las tres oficinas inyectada.
   Y el veredicto puede ser distinto por oficina — que es un resultado legítimo y probablemente
   el correcto.
```

**Segunda: suponer que SPA es siempre la respuesta, y su gemelo — suponer que MVC está obsoleto.**

MVC clásico es de 2009 y sigue siendo la opción más robusta cuando la conexión es mala y la interactividad es
modesta. **Cuarenta pantallas de CRUD con formularios y listas son exactamente ese caso.** Descartarlo por
antiguo es el mismo reflejo que la fase 12 encontró con WinForms, en otra capa.

**Dónde se rompe el paralelo con lo que traes:** en el mundo de Java la elección equivalente —Thymeleaf contra
una SPA con una API— se resuelve casi siempre a favor de la SPA, porque el equipo de frontend existe y es otro
equipo. Aquí **no hay otro equipo**, y el criterio cambia de "qué produce mejor experiencia" a "qué pueden
mantener dos personas". Es la misma pregunta de la fase 14 con otra ropa, y su respuesta tiene el mismo nombre
propio.

> ⚰️ **Autopsia del anti-patrón: Blazor Server elegido en la reunión y medido después.**
>
> **El caso:** se construye la pantalla en Blazor Server en dos días —es genuinamente rápido—, se demuestra en
> la oficina de Bogotá, se ve instantánea, y se aprueba para las cuarenta.
>
> **Lo que pasa en Lima:** cada tecla del filtro es un viaje de ida y vuelta. Con la latencia del depósito, el
> filtro se siente pegajoso; con una pérdida de paquetes moderada, el circuito se cae y **Nohora pierde el
> formulario que estaba llenando**. Llama a Duván, que no puede reproducirlo porque en Bogotá funciona.
>
> **El costo medido:** dos días de desarrollo y **tres semanas** hasta entender que el problema no era el
> código. Es la misma proporción de uno a diez que la fase 14 encontró con el certificado de MSIX, y por la
> misma razón: **se midió en la máquina del desarrollador**.
>
> **La defensa:** inyectar la latencia **desde el primer día**, en la máquina de desarrollo, con los números
> reales de las tres oficinas. Es una línea de configuración y cambia la decisión.

### 🩻 Esto sí funciona igual

Los formularios y la validación, completos. Un formulario es un modelo, unas reglas y unos mensajes; la
validación se declara una vez y se aplica en los dos lados; los errores se muestran junto al campo. Todo eso
vale igual y el curso no lo explica.

Las sesiones y la autenticación también se transfieren: lo que la fase 16 construyó sirve aquí, y el concepto
de sesión con su expiración es el mismo. Y el diseño de un CRUD con roles —quién ve qué, quién edita qué— es
el mismo razonamiento que ya haces.

Y una que conviene decir porque hace fácil la fase: **el componente de Blazor y el modelo de vista de la fase
13 son la misma idea**. Estado, operaciones, y una vista que se enlaza. `StockViewModel` no tiene WPF adentro,
así que funciona en un componente de Blazor sin cambios — y eso no estaba planeado en la fase 13.

### 📖 Diccionario de traducción

| Java / web | .NET | Dónde se rompe el paralelo |
|---|---|---|
| Spring MVC + Thymeleaf | **ASP.NET Core MVC** o Razor Pages | Equivalente casi exacto. Razor es la plantilla y el modelo es tipado |
| JSF con su árbol de componentes en el servidor | **Blazor Server** | El paralelo más cercano que existe — y el más útil: si sufriste el estado de sesión de JSF, ya conoces el problema del circuito |
| SPA (React/Angular) + API REST | **Blazor WebAssembly** + la API de la F15 | Mismo modelo, con el componente en C#. La carga inicial pesa más que un paquete de JavaScript equivalente |
| `@Valid` en el controlador | anotaciones + `EditForm` | **La misma regla se aplica en cliente y servidor** sin escribirla dos veces. Es la mejor parte de Blazor |
| WebSocket a mano | el circuito de Blazor Server | Lo gestiona el marco: reconexión, reintentos y estado. Y **si el circuito muere, el estado muere** |
| sesión HTTP | el circuito (Server) o el estado del componente (WASM) | En Server el estado vive **en el servidor y en memoria**; en WASM, en el navegador |
| `jsessionid` y sesión distribuida | *sticky sessions* obligatorias con Server | Un circuito está atado a **una** instancia: escalar horizontalmente exige afinidad de sesión, y eso es un costo de la F20 |
| Thymeleaf fragments | componentes Razor | Los componentes son tipados y se prueban sin navegador, con el mismo criterio de la F13 |
| `web.xml` / filtros | middleware | Ya visto en la F15 |
| Vaadin | Blazor Server | Casi la misma idea, el mismo modelo mental y los mismos compromisos |

> ⚠️ **La fila de las sesiones adheridas decide más de lo que parece.** Un circuito de Blazor Server vive en
> **una** instancia del servidor, así que balancear peticiones entre dos instancias rompe el circuito a menos
> que el balanceador mande cada usuario siempre a la misma. Eso es *sticky sessions*, y significa que escalar
> no es tan simple como agregar instancias: hay que configurar afinidad, y un reinicio de la instancia tira a
> sus usuarios. **Con WebAssembly y con MVC el problema no existe**, porque no hay estado en el servidor. Es
> una de las columnas del costo de la fase 20.

> 📝 **Nota de ecosistema.** Blazor Server llegó en 2019 y WebAssembly en 2020, y desde .NET 8 los dos
> conviven en un mismo proyecto con **modo de render por componente** — se puede empezar en el servidor y pasar
> un componente concreto al navegador. Eso cambia la pregunta de esta fase: ya no es *"cuál elijo para todo"*
> sino *"qué pantallas conviene en cada modo"*. La fase mide los tres puros porque **hay que conocer el costo
> de cada uno antes de mezclar**, y la mezcla sin datos es la forma más fácil de acabar con lo peor de dos.

---

## 💻 5. Código mínimo con comentarios

### 5.1 El componente, que es el mismo en los tres modelos

```razor
@* src/modern/Cordillera.Redaccion.Web/Components/ManuscriptIntake.razor
   Este componente es IDÉNTICO en Blazor Server y en WebAssembly. Lo único que cambia es dónde se
   ejecuta y cómo llega a sus datos — y eso está en la inyección, no en el componente. *@
@inject IManuscriptService Manuscripts

<EditForm Model="_form" OnValidSubmit="SubmitAsync">
    @* La validación se declara UNA vez, en el modelo, y se aplica en el cliente y en el servidor.
       Es la mejor parte de Blazor y no tiene equivalente exacto en el mundo de JavaScript sin
       duplicar reglas o generarlas. *@
    <DataAnnotationsValidator />

    <label>
        Título provisional
        <InputText @bind-Value="_form.WorkingTitle" />
        <ValidationMessage For="() => _form.WorkingTitle" />
    </label>

    <label>
        Autor o remitente
        <InputText @bind-Value="_form.SenderName" />
        <ValidationMessage For="() => _form.SenderName" />
    </label>

    <label>
        Género
        <InputSelect @bind-Value="_form.Genre">
            @foreach (Genre genre in Genre.Published) { <option value="@genre">@genre.Name</option> }
        </InputSelect>
    </label>

    @* El botón se deshabilita mientras se envía, igual que el comando de la fase 13 — y por la
       misma razón: dos envíos crean dos manuscritos. *@
    <button type="submit" disabled="@_isSubmitting">Registrar recepción</button>
</EditForm>

@if (_lastError is not null)
{
    @* El error como estado y no como ventana, exactamente igual que en el modelo de vista de la
       fase 13. Esa decisión se tomó allí para poder probar, y aquí paga otra vez. *@
    <p class="error">@_lastError</p>
}

@code {
    private readonly ManuscriptIntakeForm _form = new();
    private bool _isSubmitting;
    private string? _lastError;

    private async Task SubmitAsync()
    {
        _isSubmitting = true;
        _lastError = null;

        try
        {
            // 💸 Aquí falta algo, y está declarado: NO se registra quién hizo esto ni cuándo lo vio.
            //    La auditoría de acceso es la deuda de esta fase, con cobro en la 19 — donde la
            //    observabilidad la vuelve casi gratis.
            await Manuscripts.RegisterAsync(_form.ToCommand(), CancellationToken.None);

            _form.Reset();
        }
        catch (ManuscriptRejectedException ex)
        {
            _lastError = ex.Message;
        }
        finally
        {
            _isSubmitting = false;
        }
    }
}
```

**Detalles con intención**

- **`IManuscriptService` es una interfaz y ahí está toda la diferencia entre los tres modelos.** En Blazor
  Server se registra la implementación que habla con la base; en WebAssembly, la que llama a la API de la fase
  15. **El componente no lo sabe** — y por eso el mismo archivo sirve para los dos.
- **La validación se declara en el modelo del formulario**, con anotaciones, y se aplica en los dos lados. Es
  el 🩻 de la fase hecho código: una regla, dos aplicaciones, cero duplicación.
- **El error se expone como estado**, igual que en la fase 13. Esa decisión se tomó para poder probar un
  modelo de vista, y aquí paga otra vez sin que nadie lo planeara.
- **`CancellationToken.None` es un olor y está a propósito**: en un componente de Blazor el token correcto es
  el que se cancela cuando el componente se destruye, y el ejercicio 11 pide arreglarlo. Dejarlo así es lo que
  escribe cualquiera la primera vez.

### 5.2 Lo único que cambia: cómo llega a sus datos

```csharp
// src/modern/Cordillera.Redaccion.Web/Program.cs — BLAZOR SERVER
// El componente corre en el servidor, así que el servicio puede hablar con la base directamente.
// Es cómodo de verdad: no hay API intermedia, no hay contrato, no hay serialización.
builder.Services.AddRazorComponents().AddInteractiveServerComponents();
builder.Services.AddScoped<IManuscriptService, DatabaseManuscriptService>();   // ← a la base
builder.Services.AddDbContext<SigeContext>(/* … */);
```

```csharp
// src/modern/Cordillera.Redaccion.Wasm/Program.cs — BLAZOR WEBASSEMBLY
// El componente corre en el navegador, así que **no puede** hablar con la base: necesita la API que
// las fases 15 y 16 construyeron. Ese trabajo ya está hecho para el catálogo — y habría que hacerlo
// para las cuarenta pantallas de Redacción. Es el costo oculto de este modelo.
builder.Services.AddScoped<IManuscriptService, ApiManuscriptService>();        // ← a la API
builder.Services.AddHttpClient<ApiManuscriptService>(client =>
    client.BaseAddress = new Uri(builder.HostEnvironment.BaseAddress));
```

**El patrón a memorizar**

> **La diferencia entre los tres modelos no está en el componente: está en el registro de sus dependencias.**
> Eso significa dos cosas útiles. La primera: se puede construir la pantalla una vez y medirla en los tres,
> que es lo que hace esta fase. La segunda, y es la que importa a largo plazo: **migrar de un modelo a otro
> cuesta lo que cueste construir la API**, no lo que cueste reescribir las pantallas — y con cuarenta
> pantallas ese número es el que decide.

### 5.3 La latencia inyectada, que es el instrumento de la fase

```csharp
// src/modern/Cordillera.Redaccion.Web/Testing/LatencyInjectionMiddleware.cs
//
// Sin esto, toda la fase mide la máquina del desarrollador y el veredicto es inútil. Con esto, la
// pantalla se siente como se siente en Lima **desde el primer día de desarrollo**, que es lo que
// cambia la decisión.
namespace Cordillera.Redaccion.Web.Testing;

/// <summary>
/// Inyecta latencia y pérdida de paquetes simulando la conexión de una oficina. **Solo se registra
/// cuando la configuración lo pide**, y el ejercicio 4 pide comprobar que en producción no está.
/// </summary>
/// <remarks>
/// Los perfiles salen de la historia y hay que medirlos, no inventarlos: la fase pide tomar la
/// latencia real de las tres oficinas antes de configurarlos. Lo que va aquí es la forma del
/// instrumento; los números son de tu red.
/// </remarks>
public sealed class LatencyInjectionMiddleware(RequestDelegate next, IOptionsMonitor<NetworkProfile> profile)
{
    public async Task InvokeAsync(HttpContext context)
    {
        NetworkProfile current = profile.CurrentValue;

        if (!current.Enabled)
        {
            await next(context);
            return;
        }

        // La latencia de ida. Para Blazor Server esto se paga en **cada interacción**, no solo en
        // la carga de la página, y ahí está todo el asunto de la fase.
        await Task.Delay(current.OneWayLatency, context.RequestAborted);

        // Y la pérdida de paquetes, que es lo que de verdad rompe el circuito. Una latencia alta
        // hace que se sienta pegajoso; una pérdida moderada **tira la conexión**, y entonces el
        // usuario pierde lo que estaba escribiendo.
        if (current.PacketLossRate > 0 && Random.Shared.NextDouble() < current.PacketLossRate)
        {
            context.Abort();
            return;
        }

        await next(context);
        await Task.Delay(current.OneWayLatency, context.RequestAborted);
    }
}

/// <summary>Los tres perfiles de la medición. Los valores se **miden**, no se suponen.</summary>
public sealed class NetworkProfile
{
    public bool Enabled { get; init; }

    /// <summary>Latencia de un sentido. Bogotá es el caso base; Lima es el adverso.</summary>
    public TimeSpan OneWayLatency { get; init; }

    /// <summary>Proporción de peticiones que se pierden. Es la que rompe circuitos.</summary>
    public double PacketLossRate { get; init; }
}
```

**Detalles con intención**

- **La pérdida de paquetes es tan importante como la latencia**, y casi nadie la simula. La latencia hace que
  una interfaz se sienta lenta; **la pérdida hace que el circuito se caiga**, y eso es lo que le pasa a Nohora
  en Lima.
- **Los números se miden, no se inventan.** El instrumento está aquí; los valores salen de medir las tres
  oficinas, y el criterio 2 del miniproyecto lo exige.
- **El middleware se registra condicionalmente**, y el ejercicio 4 pide comprobar que en producción no está —
  porque un instrumento de medición en el camino caliente de producción es un incidente esperando.

### 5.4 El circuito que se cae, y lo que se pierde con él

```csharp
// src/modern/Cordillera.Redaccion.Web/Program.cs
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents(options =>
    {
        // Cuánto vive un circuito desconectado antes de que el servidor lo recicle. El valor por
        // omisión es de minutos, y es un compromiso entre memoria y tolerancia a cortes.
        //
        // Subirlo ayuda a Lima —el usuario reconecta y su formulario sigue ahí— y **cuesta memoria
        // por cada circuito huérfano**. Es una de las columnas de la medición, y la decisión
        // depende de un número que esta fase produce.
        options.DisconnectedCircuitRetentionPeriod = TimeSpan.FromMinutes(3);
        options.DisconnectedCircuitMaxRetained = 100;   // 90 personas + margen
    });
```

```razor
@* Y lo que el usuario ve cuando se cae. El marco trae una interfaz de reconexión por omisión, y
   personalizarla es lo mínimo que esta fase exige — porque el mensaje por omisión no dice si lo
   que estaba escribiendo se perdió, y esa es la única pregunta que Nohora se hace. *@
<div id="components-reconnect-modal">
    <p>Se perdió la conexión. Reintentando…</p>
    <p><strong>Lo que escribiste no se ha guardado.</strong> Si la reconexión falla, vas a tener que
       volver a llenarlo.</p>
</div>
```

> 💸 **Deuda declarada: la primera versión sale sin rastro de auditoría de quién vio qué.**
>
> Redacción registra **quién cambió qué** —eso está en el modelo desde el principio, porque es un requisito de
> negocio— y **no registra quién vio qué**. Nadie sabe qué contratos consultó un usuario, ni cuándo, ni desde
> dónde.
>
> Y eso importa por una razón concreta de la historia: en marzo se descubrió que un traductor externo llevaba
> **dos años con acceso de edición a la carpeta de contratos**. Lo que nadie pudo responder entonces fue **qué
> vio en esos dos años**, y con Redacción tal como sale de esta fase, la respuesta seguiría siendo la misma.
>
> **Se paga en la fase 19**, y la razón de aplazarlo no es pereza: **la observabilidad hace esa auditoría casi
> gratis**. Instrumentar ahora un registro de accesos a mano sería construir la mitad de un sistema de trazas
> que la 19 va a construir entero, y después tirarlo. La factura será
> `git diff fase-18 fase-19 -- src/modern/Cordillera.Redaccion.Web/`.

**Prueba de fuego**

```powershell
# Las tres versiones, con el perfil de Lima activado.
dotnet run --project src\modern\Cordillera.Redaccion.Web -- --network-profile lima
dotnet run --project src\modern\Cordillera.Redaccion.Wasm -- --network-profile lima
dotnet run --project src\modern\Cordillera.Redaccion.Mvc -- --network-profile lima
```

Y **usa las tres, a mano, escribiendo en el filtro**. No mires el número: **siéntelo**. Es la única parte de
este curso donde eso es un método legítimo, porque la pregunta de la fase —¿se puede trabajar ocho horas con
esto?— no se responde con un percentil.

Y la mentira que te va a contar la salida si miras el lugar equivocado: **con el perfil de Bogotá las tres se
sienten idénticas**. Ahí está el problema entero de esta fase: la decisión se toma en la oficina donde está el
desarrollador, y el 15% de los usuarios está en la oficina donde la decisión falla.

---

## 📏 6. Medición

**Hipótesis:** los tres modelos son indistinguibles con la conexión de Bogotá; con la del depósito de Lima,
**Blazor Server se degrada de forma cualitativa y no gradual** —el filtro se siente pegajoso y el circuito se
cae— mientras MVC y WebAssembly siguen usables por razones distintas: MVC porque solo paga en la navegación, y
WebAssembly porque ya pagó todo al principio.

**Condiciones:** SDK 10.0.401 · Release · Windows 11 · **la misma pantalla de recepción de manuscritos en los
tres modelos**, contra la misma base del generador con semilla `19970417` · lista de 400 manuscritos, el
volumen real de un mes · **los tres perfiles de red medidos en las tres oficinas** e inyectados con el
middleware de la sección 5.3 · 20 repeticiones con 3 de calentamiento descartadas · memoria de servidor medida
con **90 circuitos simultáneos**, que es el número de personas de Cordillera · arnés propio.

**Competidores:** los tres modelos de render. Y **el escritorio de las fases 12 a 14 como cuarta referencia**,
porque esta medición completa su tabla.

**Los comandos:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 18 --profiles bog,mex,lim
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 18 --circuits 90
```

**Resultado:** ⏳ pendiente de ejecución en tu máquina.

**A · Latencia de interacción por oficina** — el tiempo desde que el usuario teclea hasta que la interfaz
responde:

| Modelo | Bogotá | Ciudad de México | **Lima** | Carga inicial | Circuitos caídos en 8 h |
|---|---|---|---|---|---|
| Blazor Server | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Blazor WebAssembly | ⏳ | ⏳ | ⏳ | ⏳ | n/a |
| MVC clásico | ⏳ | ⏳ | ⏳ | ⏳ | n/a |

**B · Costo en el servidor**

| Modelo | Memoria por usuario conectado | Con 90 usuarios | Sesiones adheridas | Peticiones por interacción |
|---|---|---|---|---|
| Blazor Server | ⏳ | ⏳ | **obligatorias** | 1 |
| Blazor WebAssembly | ~0 | ~0 | no | solo datos |
| MVC clásico | ⏳ (sesión) | ⏳ | según sesión | 1 por navegación |

> ⚖️ **Veredicto** *(expectativa, todavía sin ejecutar — `formato-de-mediciones.md` §2.6)*. Se espera **empate
> en Bogotá** entre los tres —y publicarlo es importante, porque explica por qué esta decisión se toma mal tan
> a menudo— y una separación clara en Lima. Se espera que WebAssembly tenga la peor carga inicial por un
> margen amplio, y que Blazor Server tenga la peor latencia de interacción y **la única columna de circuitos
> caídos que no es cero**.
>
> **Los tres umbrales que tu ejecución tiene que determinar:** (1) **a partir de qué latencia de ida y vuelta
> Blazor Server deja de sentirse instantáneo** — que es el número que decide por oficina; (2) **cuánta memoria
> cuestan 90 circuitos**, que decide si hace falta un servidor más y es una fila de la factura de la fase 20;
> y (3) **cuánta pérdida de paquetes hace falta para tirar un circuito**, que es lo que le pasa a Nohora y no
> aparece en ninguna medición de latencia.
>
> 📝 Y una advertencia sobre cómo leer la tabla A: **la columna de Lima no es una columna más**. El 15% de los
> usuarios está ahí, y una herramienta inusable para el 15% de la gente no es una herramienta con un problema
> menor: es una herramienta que va a tener dos versiones o ninguna.

### 🔜 → ⏳ La cuarta columna del veredicto del escritorio

Y aquí se paga lo que la fase 14 declaró pendiente. **La metodología es la de esa fase y no se rediscute**
(`prompts/propuesta-fases-y-alcance.md` §8): los cinco criterios, el módulo medido, el volumen de 50.000
filas, las tres oficinas con Lima como caso adverso, y la memoria a las ocho horas.

Hay una adaptación necesaria y hay que declararla: **el módulo medido en el escritorio es el formulario de
existencias, y la web de esta fase construye la recepción de manuscritos.** Para completar la columna con
honestidad, la pantalla de existencias se construye **también** en el modelo de render que gane esta fase — es
trabajo adicional y es el criterio 5 del miniproyecto. Rellenar la columna con los números de otra pantalla
sería romper la comparación por comodidad.

**La columna se completa en la entrada consolidada de `BENCHMARKS.md`**, no editando el documento de la fase
14. Y si el veredicto provisional cambia al entrar:

> ⚖️ **Si el veredicto cambia, esta fase lo dice y explica qué lo movió.** Un veredicto que cambia con un dato
> nuevo no es un error del curso: es el curso funcionando. Y el candidato más probable a moverlo es el criterio
> 4 —el despliegue—, donde la web gana por definición: **no hay nada que instalar en noventa equipos**. Si eso
> alcanza para vencer a WinForms depende de las otras cuatro columnas, y en particular de Lima.

---

## 🧱 7. Miniproyecto — la recepción de manuscritos, tres veces y medida desde tres países

**El encargo**

Dos correos el mismo día, y hay que satisfacer los dos.

**Nohora:** *"Lo que necesito es poder arreglar un registro cuando me doy cuenta del error, que suele ser
como a las siete de la tarde cuando estoy cerrando el día. Hoy le escribo a Duván y él lo cambia al día
siguiente. Si la herramienta nueva me deja corregirlo yo misma, me cambia la vida; si me toca pedir permiso,
prefiero seguir con la hoja."*

**Ximena:** *"Te voy a ser honesta: publicamos ocho títulos al mes con gente para cuatro. Todo lo que sea un
paso más, no lo vamos a hacer — no por mala voluntad, porque no da el tiempo. Si tu pantalla reemplaza el
correo, perfecto. Si es el correo **más** la pantalla, no la abrimos."*

**Por qué duele**

Porque los dos correos son criterios de aceptación y **ninguno es técnico**. El de Nohora es un requisito de
permisos que choca con el modelo de roles obvio —donde corregir es privilegio de un administrador—. El de
Ximena es la razón por la que la mitad de los back-office internos del mundo no se usan, y **no se resuelve
con funcionalidad: se resuelve quitando pasos**.

Y porque la medición honesta obliga a construir la misma pantalla tres veces, que es aburrido y es el único
modo de que la comparación valga.

**Datos de entrada**

| Qué | Detalle |
|---|---|
| Manuscritos no solicitados | **400 al mes** al correo `publicaconnosotros@` |
| Estados del flujo | `received` → `triaged` → `under_review` → `accepted` \| `rejected` |
| Usuarias | Nohora (operaciones), Ximena (dirección editorial), dos lectoras externas |
| Oficinas | Bogotá, Ciudad de México, y **el depósito de Lima** con su conexión |
| Personas conectadas a la vez | Hasta **90** en hora punta |
| Lo que reemplaza | Correos, una hoja compartida, y una carpeta de Drive sin auditar desde 2019 |
| El incidente de marzo | Un traductor externo con acceso de edición a contratos durante **dos años** |

**Criterios de aceptación**

1. La pantalla existe **en los tres modelos** con la misma funcionalidad, y **el componente es el mismo
   archivo** en los dos de Blazor — lo único que cambia es el registro de dependencias.
2. La latencia de las tres oficinas está **medida y después inyectada**. Si los números son estimados, el
   criterio no se cumple: la fase entera depende de que sean reales.
3. **Nohora puede corregir un registro ella misma**, y el modelo de roles lo permite sin convertirla en
   administradora. La solución está escrita y justificada.
4. **El flujo de Ximena no tiene ningún paso más que el actual.** Cuéntalos: los del correo hoy, y los de la
   pantalla. Si son más, la pantalla está mal diseñada.
5. La pantalla de **existencias** —la del escritorio— existe también en el modelo ganador, para poder
   completar la cuarta columna del veredicto **con el mismo módulo medido**.
6. La cuarta columna del veredicto está completa en `BENCHMARKS.md`, con la metodología de la fase 14, y **si
   el veredicto cambió, está dicho qué lo movió**.
7. **Medición de cierre:** las dos tablas de la sección 6, con los tres perfiles y los 90 circuitos. Van en el
   mensaje del tag `mini-18`.

**Restricciones de estilo y alcance**

Código nuevo. **Sin framework de JavaScript**, con la razón escrita — y la razón es el equipo, no la
tecnología. Sin auditoría de acceso, que es la deuda declarada. Sin observabilidad, que es la fase 19.

Y una restricción que es el punto de la fase: **el componente se escribe una vez**. Si acabas con dos versiones
del formulario, una para Server y otra para WebAssembly, la comparación mide dos implementaciones y no dos
modelos de render.

**La trampa**

Vas a construir la versión de Blazor Server primero porque es la más rápida de escribir —el componente habla
con la base directamente, sin API, sin contrato, sin serialización— y va a quedar **perfecta**. Rápida,
instantánea, con el filtro reaccionando a cada tecla.

En tu máquina.

Con el perfil de Lima activado, cada tecla del filtro es un viaje de ida y vuelta, y **el filtro se siente
pegajoso de una forma que ningún percentil describe bien**. Y con la pérdida de paquetes del depósito, el
circuito se cae: Nohora pierde el formulario que estaba llenando, llama a Duván, y Duván no puede reproducirlo
porque en Bogotá funciona.

Cuando lo sientas —y hay que **sentirlo**, no medirlo— escribe dos cosas: cuántos milisegundos de ida y vuelta
hicieron falta para que dejara de sentirse instantáneo, y qué habrías decidido si solo hubieras probado en
Bogotá. La segunda respuesta es la autopsia de la sección 4 ocurriéndote a ti.

<details><summary>Pista 1 — el enfoque</summary>

Empieza por el perfil de red, no por la pantalla. Mide las tres oficinas, configura el middleware, y **trabaja
con el perfil de Lima activado desde el primer día**. Si lo dejas para el final, vas a haber tomado todas las
decisiones de diseño con la conexión equivocada.

Para el criterio 3 —Nohora corrigiendo a las siete— la pregunta no es de permisos sino de diseño del flujo:
¿qué hace que corregir sea peligroso? En cuanto lo nombres, la solución probablemente no sea un rol nuevo.

Y para el 4, cuenta los pasos de Ximena **hoy**. Es el único modo de saber si agregaste uno.

</details>

<details><summary>Pista 2 — la herramienta</summary>

Para los modos de render y cómo conviven desde .NET 8:
`https://learn.microsoft.com/aspnet/core/blazor/components/render-modes`

Para el ciclo de vida del circuito y su retención:
`https://learn.microsoft.com/aspnet/core/blazor/fundamentals/signalr#circuit-handler-options`

Para los formularios con validación compartida:
`https://learn.microsoft.com/aspnet/core/blazor/forms/validation`

Y para el token que el componente debe usar en vez de `CancellationToken.None`, mira `ComponentBase` y qué
pasa cuando un componente se destruye a mitad de una llamada.

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```csharp
// Lo único que cambia entre los tres modelos. El componente no lo sabe.
public interface IManuscriptService
{
    Task<IReadOnlyList<ManuscriptSummary>> ListAsync(ManuscriptFilter filter, CancellationToken token);
    Task RegisterAsync(RegisterManuscript command, CancellationToken token);
    Task CorrectAsync(CorrectManuscript command, CancellationToken token);   // ← el criterio de Nohora
}

// Los perfiles de red, medidos y no supuestos.
public sealed record NetworkProfile(string Office, TimeSpan OneWayLatency, double PacketLossRate);

// Y la tabla del veredicto, con la columna que esta fase completa. Los tipos son los de la F14.
public sealed record DesktopOption(/* … */);   // ← se completa la instancia de la web
```

</details>

**Cómo se entrega**

```powershell
dotnet test src\Cordillera.slnx -c Release
dotnet run --project src\modern\Cordillera.Redaccion.Web -- --network-profile lima
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 18 --profiles bog,mex,lim --circuits 90
```

```bash
git tag -a mini-18 -m "Mini F18: recepción de manuscritos en 3 modelos · Lima: Server <A> ms / WASM <B> ms / MVC <C> ms · 90 circuitos = <M> MB · columna 4 del veredicto completada"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Mide la latencia real de ida y vuelta a las tres oficinas y configura los tres perfiles. Anota los números:
   son el instrumento de toda la fase.
2. Construye la pantalla en Blazor Server y úsala con el perfil de Bogotá y con el de Lima. Describe la
   diferencia **con palabras**, no con números.
3. Cambia el mismo componente de Server a WebAssembly tocando solo el registro de dependencias. Anota cuántas
   líneas cambiaron.
4. Verifica que el middleware de latencia **no está registrado** en producción. Escribe la prueba que lo
   garantiza.
5. Declara una regla de validación en el modelo del formulario y demuestra que se aplica en el cliente y en el
   servidor sin escribirla dos veces.
6. Mide el peso de la carga inicial de las tres versiones. Explica de qué está hecho el de WebAssembly.

**🟡 Intermedio (7–14)**

7. Simula pérdida de paquetes creciente y encuentra el punto donde el circuito de Blazor Server se cae.
   Reporta el porcentaje.
8. Personaliza la interfaz de reconexión para que diga si lo que el usuario escribió se perdió. Explica por qué
   el mensaje por omisión no sirve.
9. Sube `DisconnectedCircuitRetentionPeriod` y mide el efecto en memoria con 90 circuitos. Decide un valor con
   ese número.
10. Mide la memoria de servidor con 1, 30 y 90 circuitos y extrapola. Di si hace falta un servidor más.
11. Reemplaza `CancellationToken.None` por el token correcto del componente, y demuestra con una prueba qué
    pasa cuando el usuario navega a otra página a mitad de una llamada.
12. Implementa la lista de 400 manuscritos con `<Virtualize>` y sin él, y compara. Es el mismo problema de la
    fase 13 en otra tecnología.
13. Haz que la misma pantalla funcione en **modo de render por componente** —la lista en el servidor y el
    formulario en el navegador— y anota si mejora algo o solo complica.
14. Cuenta los pasos del flujo de Ximena hoy —con el correo y la hoja— y los de tu pantalla. Si son más,
    rediseña.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Nohora reporta que "la pantalla se congela y pierde lo que escribí", y solo le pasa a
    ella. Escribe el procedimiento de diagnóstico: qué preguntarías primero, qué mirarías, y por qué Duván no
    puede reproducirlo en Bogotá.
16. **Diagnóstico.** La aplicación de Blazor Server consume 4 GB al final del día y por la mañana 300 MB.
    Enumera tres causas relacionadas con circuitos y di cómo distinguirlas.
17. **Medición.** Ejecuta la medición completa de la sección 6, las dos tablas, con los tres perfiles reales.
    Determina **los tres umbrales** y publica el empate de Bogotá.
18. **Medición.** Completa la cuarta columna del veredicto del escritorio con la metodología de la fase 14,
    incluida la pantalla de existencias en el modelo ganador. Si el veredicto cambió, escribe qué lo movió.
19. Resuelve el criterio de Nohora: diseña el modelo de permisos que la deja corregir sin convertirla en
    administradora, y explica qué riesgo asume y cómo se mitiga.
20. **Decisión.** Elige el modelo de render para las cuarenta pantallas de Redacción, con los números de las
    dos tablas. Y decide si **es el mismo para las tres oficinas** o si Lima justifica una excepción — que es
    una respuesta legítima y tiene un costo.
21. **Decisión — ¿se migra, se envuelve o se deja quieto?** La hoja compartida de Nohora y la macro de Excel de
    600 líneas que usan tres sellos. Decide, y ten en cuenta que **nadie se atreve a tocar la macro** y que
    Nohora la escribió.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Construye una medición que "demuestre" que Blazor Server es la mejor opción, sin mentir en
    ningún número — eligiendo qué oficina se mide y qué interacción. Después explica qué la hace deshonesta.
23. **Adversarial.** Consigue que la validación compartida acepte en el cliente algo que el servidor rechaza.
    Explica el mecanismo y escribe la prueba que lo impide.
24. **Diseño.** Escribe el plan de las cuarenta pantallas: en qué orden, con qué modelo de render, cuánto
    tarda, y **qué pasa con Lima**. Incluye qué harías si a la pantalla doce descubres que el modelo elegido
    fue un error.
25. **Defiende una decisión ante quien no es ingeniera.** Escríbele a Ximena media página explicando qué va a
    ganar con Redacción y **por qué no le va a agregar pasos** — en su lenguaje, y sabiendo que si no la
    convences, no la usa.

**🔥 Opcionales**

- Prueba las tres versiones con el lector de pantalla y con el teclado solamente. Anota qué tan accesible es
  cada una: es el criterio que la fase 14 **no** incluyó y que la 24 debería admitir.
- Investiga cuánto pesaría la misma pantalla en React con una API, y compáralo con el paquete de WebAssembly.
  El ejercicio no es el número: es notar que la comparación honesta incluye el costo del equipo que lo mantiene.
- Mide el consumo de datos móviles de un día de trabajo con cada modelo. En el depósito de Lima hay gente con
  módem, y ese número puede decidir.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://learn.microsoft.com/aspnet/core/blazor/hosting-models` — los modelos de hospedaje, con sus
  compromisos declarados por Microsoft.
- `https://learn.microsoft.com/aspnet/core/blazor/components/render-modes` — el modo de render por componente,
  que desde .NET 8 cambia la pregunta de esta fase.
- `https://learn.microsoft.com/aspnet/core/blazor/fundamentals/signalr` — el circuito, su retención y sus
  opciones. **Es la página de la trampa.**
- `https://learn.microsoft.com/aspnet/core/blazor/forms/validation` — validación compartida entre cliente y
  servidor.
- `https://learn.microsoft.com/aspnet/core/blazor/components/virtualization` — `<Virtualize>`, el mismo
  problema de la fase 13 en otra tecnología.
- `https://learn.microsoft.com/aspnet/core/mvc/overview` — MVC clásico, que sigue siendo la opción robusta con
  conexión mala.
- `https://learn.microsoft.com/aspnet/core/blazor/host-and-deploy/webassembly` — el tamaño del paquete de
  WebAssembly y qué se puede hacer al respecto.

**Libros / artículos**

- Los artículos sobre presupuesto de rendimiento web —*performance budget*— son la mejor guía para decidir
  cuánto puede pesar una carga inicial. No se cita uno en particular: verifica antes de citar.

> ⚠️ Verifica las URLs. Y la advertencia propia de esta fase: **casi todo el material de Blazor asume una
> conexión buena**, porque se escribe en oficinas con fibra. Las comparaciones que encuentres de Server contra
> WebAssembly hablan de tamaño de descarga y de tiempo de arranque, y **casi ninguna mide la latencia de
> interacción ni la caída de circuitos** — que es exactamente lo que decide en Cordillera. Y del otro lado: el
> material anterior a .NET 8 no conoce el modo de render por componente, así que presenta la decisión como
> excluyente cuando ya no lo es.

**Orden de lectura sugerido:** antes de escribir, la página de modelos de hospedaje y la de modos de render —
quince minutos y encuadran la fase—. Durante el miniproyecto, la de SignalR y el circuito, **antes** de
necesitarla. Al cerrar, la del tamaño del paquete de WebAssembly: se lee distinto cuando ya mediste la carga
inicial desde Lima.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Existe Redacción, y existe la misma pantalla en tres modelos de render medidos con la latencia real de tres
oficinas — no estimada. Y se completó **la cuarta columna del veredicto del escritorio** que la fase 14 dejó
declarada pendiente, con su misma metodología y en la entrada consolidada, sin tocar el documento publicado de
esa fase.

Y quedó demostrada la propiedad que hace difícil esta decisión: **los tres modelos son indistinguibles en la
oficina donde está el desarrollador**. El empate de Bogotá no es un dato aburrido — es la explicación de por
qué esta elección se toma mal tan a menudo, y la razón por la que la latencia se inyecta desde el primer día
en vez de medirse al final.

Los dos criterios que no son técnicos siguen valiendo más que las dos tablas: Nohora tiene que poder corregir
a las siete de la tarde, y Ximena no puede recibir un paso más. Una herramienta que falle esos dos **está mal
aunque gane la medición**, y eso no es sentimentalismo: es que una herramienta que no se usa no tiene ningún
rendimiento.

La fase 19 es el paso natural por dos razones. La primera es la deuda: Redacción no registra **quién vio qué**,
y el incidente de marzo —dos años de acceso de un traductor externo a los contratos— es la razón por la que
eso importa. La segunda es más grande: con cuatro proyectos en producción, dos runtimes y un sistema heredado
al lado, **la pregunta ya no es si funciona sino qué está pasando ahí dentro**. Y el material que distingue la
19 de cualquier tutorial de telemetría es concreto: la traza tiene que **cruzar el borde 🧬**, desde una
petición HTTP hasta un procedimiento almacenado de 1997 — y encontrar dónde se van los cuatro segundos.

> **La señal de que quedó bien:** *"Probé la pantalla con la conexión de Lima antes de decidir, y elegí con
> esos números. Y Ximena abrió la pantalla dos veces sin que nadie se lo pidiera."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el miniproyecto corriendo y
> `git status` limpio:
>
> ```bash
> git tag -a fase-18 -m "F18 cerrada:
> - recepcion de manuscritos en Blazor Server, WebAssembly y MVC, con el mismo componente
> - latencia de las tres oficinas MEDIDA e inyectada, con perdida de paquetes
> - memoria de servidor con 90 circuitos, y el punto donde el circuito se cae
> - criterios de Nohora y Ximena verificados con ellas, no supuestos
> - cuarta columna del veredicto del escritorio completada con la metodologia de la F14
> - sin auditoria de quien vio que: deuda declarada con cobro en la F19"
> ```
>
> **Y esta fase cierra la tabla que la 14 abrió.** El diff que lo demuestra no está en un archivo de código:
>
> ```bash
> git diff fase-14 fase-18 -- BENCHMARKS.md
> ```
>
> Una columna que pasa de 🔜 a ⏳, cuatro fases después, con la misma metodología. Es la única actualización
> retroactiva del curso y quedó donde debía: **en la medición consolidada y no en el documento publicado**.

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura.*

- **`INSTINTOS.md`** — dos entradas en la familia *servicios, identidad y operación*: elegir el modelo de
  render por moda, y suponer que SPA es siempre la respuesta —con su gemelo, **suponer que MVC está
  obsoleto**, que es el mismo reflejo de la F12 con WinForms en otra capa—. La primera necesita el dato que la
  desarma: **los tres modelos son indistinguibles en la oficina del desarrollador**, y por eso la decisión se
  toma mal.
- **`BENCHMARKS.md`** — entrada ⏳ *F18 · Los tres modelos de render desde tres oficinas*, con dos tablas. **Y
  la actualización de la entrada de la F14**: la columna de la web pasa de 🔜 a ⏳, con la nota de qué
  adaptación hubo que hacer —construir la pantalla de existencias en el modelo ganador— para que el módulo
  medido fuera el mismo.
- **Deuda 💸 plantada:** sin auditoría de quién vio qué, cobro en F19. Conviene anotar en el libro de §7.1 que
  **la razón de aplazarla es que la observabilidad la vuelve casi gratis** — hacerla a mano aquí sería
  construir la mitad de un sistema de trazas y después tirarlo. Es el mejor ejemplo del curso de una deuda
  tomada por secuencia y no por prisa.
- **Tipos y proyectos nuevos para el congelamiento:** `Cordillera.Redaccion.Web`, `Cordillera.Redaccion.Wasm`,
  `Cordillera.Redaccion.Mvc`, `IManuscriptService`, `ManuscriptIntakeForm`, `ManuscriptSummary`,
  `ManuscriptFilter`, `RegisterManuscript`, `CorrectManuscript`, `ManuscriptRejectedException`,
  `LatencyInjectionMiddleware`, `NetworkProfile`, `Genre`.
- **Y una aclaración para el congelamiento:** el árbol de `src/` tenía **un solo** `Cordillera.Redaccion.Web`,
  y esta fase crea tres proyectos porque la comparación lo exige. Hay que decidir si los tres se quedan o si
  al cerrar el veredicto se borran dos. **Recomendación: se quedan**, marcados como prototipos de medición,
  porque la fase 24 va a querer revisar la decisión con el código delante.
- **Para la fase 19:** la deuda de auditoría se cobra allí, y el ejercicio 11 —el token del componente— es un
  caso de correlación de trazas que la 19 puede usar.
- **Para la fase 20:** tres entradas directas — la memoria de 90 circuitos (¿hace falta otro servidor?), las
  **sesiones adheridas obligatorias** de Blazor Server (que es un costo de balanceo y un amarre), y el peso de
  la carga inicial si se sirve desde una red de distribución.
- **Para la fase 24:** el ejercicio 🔥 de accesibilidad y el 24 —qué hacer si a la pantalla doce el modelo
  resulta equivocado— son material del veredicto. Y el criterio que esta fase **no** midió —accesibilidad—
  debería aparecer en la lista de decisiones del propio curso que pudieron ser otras.
