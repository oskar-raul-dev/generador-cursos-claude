# ⚙️ Fase 05 ⭐ — `async`/`await` de punta a punta

> C# para desarrolladores Java senior · Fase 05 de 24 · Bloque A — el lenguaje y el runtime
> Depende de: 04 · Habilita: 06
> Estilo de esta fase: **nuevo** (.NET 10, C# 14)
> Proyecto que avanza: **el modelo de dominio**. Al terminar, la carga de los tres distribuidores es
> asincrónica de punta a punta, con concurrencia limitada, cancelación que funciona y cierre
> asincrónico que no pierde una línea de auditoría.

---

## 🎯 1. Propósito

Que el modelo asincrónico deje de ser una herramienta para llamadas de red y pase a ser lo que es:
**el modelo del runtime entero**. Todo el Bloque D —los servicios, el trabajo de fondo, la web— lo da
por sabido, y el código que no lo respeta no falla en la demo: falla bajo carga, que es cuando ya hay
noventa personas trabajando.

Esta fase es ⭐ por eso y por una razón práctica: un desarrollador senior no cambia un reflejo porque
se lo digan. Lo cambia cuando ve el número de hilos. Así que **la medición no es el cierre de la
fase, es su pieza central**.

---

## ✅ 2. Qué queda listo al terminar

- [ ] La cadena completa de carga es asincrónica **de punta a punta**, sin un solo `.Result` ni
      `.Wait()`, y sin `async void`.
- [ ] Todo método asincrónico del modelo **recibe y propaga un `CancellationToken`**, salvo dos que
      quedan declarados como 💸 con su fase de cobro.
- [ ] La carga de los tres distribuidores corre en paralelo **con límite configurable**, y hay una
      prueba que demuestra que el límite se respeta.
- [ ] Cancelar a mitad deja todos los recursos cerrados **y no pierde ni una línea de auditoría**:
      es la deuda que dejó el miniproyecto de la fase 04, cobrada aquí con `await using`.
- [ ] Sabes probar código asincrónico: pruebas que devuelven `Task`, pruebas de cancelación, y por
      qué el `.Result` que esta fase prohíbe aparece en tantas suites ajenas.
- [ ] La medición de la sección 6 está escrita con su comando, y la entrada quedó en `BENCHMARKS.md`.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Colas, reintentos y reanudación** → fase 17. Aquí hay concurrencia limitada y cancelación; el
  proceso reanudable por lotes, la idempotencia y el outbox son de la 17, que es donde se cobran las
  deudas de esta fase.
- **`IAsyncEnumerable`** → fase 06. Aparece nombrado porque es la respuesta natural a "y si el
  archivo no cabe en memoria", y esa pregunta es de la fase siguiente.
- **Inyección de dependencias y `IHostedService`** → fases 15 y 17.
- **Trabajo asincrónico en una interfaz de usuario** → fase 12, y es **la única fase del curso donde
  se levanta la prohibición de `async void`**. Se explica aquí por qué la prohibición se escribe con
  esa excepción dentro, en vez de como una regla absoluta que después habría que romper.
- **`Parallel.For` y PLINQ como herramienta recomendada.** Aparecen en la medición para mostrar
  dónde **no** sirven.

---

## 🧠 4. Concepto mínimo

Lo primero, porque ordena todo lo demás: **`async` no es concurrencia y `await` no es esperar**.

Un método `async` no arranca un hilo. `await` no bloquea. Lo que hace el compilador es partir el
método en pedazos: todo lo que va antes del primer `await` se ejecuta en el hilo que llamó, y cuando
se llega al `await` de una operación que todavía no terminó, **el método devuelve el control y el
hilo se va a hacer otra cosa**. Cuando la operación termina, alguien —el grupo de hilos, normalmente—
retoma el método en el punto donde se quedó.

De ahí sale la propiedad que importa y que casi nadie enuncia bien: **`async` no hace nada más
rápido**. Una operación que tarda 80 ms tarda 80 ms. Lo que cambia es **cuántas de esas operaciones
puedes tener en vuelo con el mismo número de hilos**, y eso es todo el asunto: con 200 peticiones
concurrentes esperando a la base de datos, el modelo asincrónico necesita un puñado de hilos y el
bloqueante necesita 200.

**`Task` es la promesa de un resultado futuro**, y tiene una propiedad que sorprende a quien llega de
`CompletableFuture`: en .NET, una `Task` devuelta por un método `async` **ya está corriendo**. No hay
que arrancarla. `Task.Run` es otra cosa —encolar trabajo de CPU en el grupo de hilos— y confundir las
dos es la fuente de la mitad de los problemas de este perfil.

**`ValueTask` existe para el caso en que la respuesta suele estar lista.** Si un método consulta una
caché y acierta el 95% de las veces, devolver `Task` asigna un objeto en el montón 95 veces por nada.
`ValueTask` evita esa asignación, y a cambio tiene una regla estricta: **se consume una sola vez**.
Guardarla, esperarla dos veces o acceder a `.Result` antes de que termine es comportamiento
indefinido, no una excepción clara.

Y la cancelación, que en .NET no es una interrupción: es **cooperativa**. Un `CancellationToken` es
una señal que alguien puede levantar; el código que hace el trabajo tiene que **mirarla**. Nadie mata
nada, nadie lanza `ThreadInterruptedException` desde fuera. Si tu bucle no comprueba el token, tu
bucle no se puede cancelar, y el proceso nocturno de seis horas que falló en la hora cinco es
exactamente ese bucle.

> 🧠 **El modelo mental:** un hilo es un trabajador y una `Task` es un pedido. El código bloqueante
> le asigna un trabajador a cada pedido y lo deja mirando el horno; el asincrónico deja el pedido
> anotado y manda al trabajador a atender a otro. Con cuatro pedidos da igual. Con doscientos, el
> primero necesita doscientos trabajadores y el segundo cuatro.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**Primera, y es la que cuesta producción: `.Result` y `.Wait()`.**

```csharp
// ❌ Lo que escribe alguien que necesita el valor y no quiere "contaminar" la firma con async.
//    Compila. Funciona en una prueba. Funciona en la demo. Cae con carga.
public IReadOnlyList<SalesRow> Load(string path)
{
    return LoadAsync(path).Result;   // ← también: .Wait(), .GetAwaiter().GetResult()
}
```

Qué pasa de verdad: el hilo que llama se queda **bloqueado** esperando a que la tarea termine. Ese
hilo es del grupo de hilos, y mientras espera no hace nada. Con doscientas peticiones concurrentes
hacen falta doscientos hilos bloqueados; el grupo los crea de a poco —uno o dos por segundo cuando se
queda corto— así que el sistema no explota: **se degrada**, con latencias que suben y suben mientras
el uso de CPU se queda en el 5%. Es el diagnóstico más difícil de hacer sin haberlo visto antes,
porque todos los indicadores parecen sanos.

```csharp
// ✅ La firma cambia, y eso no es contaminación: es información. El que llama también tiene que
//    decidir qué hace mientras espera, y eso es un hecho del diseño, no un detalle.
public async Task<IReadOnlyList<SalesRow>> LoadAsync(string path, CancellationToken token)
{
    // …
}
```

**Por qué falla el reflejo:** porque en la JVM bloquear un hilo de plataforma era caro pero
**previsible**, y llevabas once años dimensionando pools para eso. Aquí el grupo de hilos está
diseñado bajo el supuesto de que **nadie lo bloquea**, y su heurística de crecimiento es
deliberadamente lenta. Bloquearlo no es ineficiente: es usar la herramienta contra su diseño.

> 🧭 **La regla, y aplica a todo el curso:** **cero `.Result`, cero `.Wait()`, cero
> `.GetAwaiter().GetResult()`.** Si necesitas el valor, `await`. Si no puedes `await` porque la firma
> de arriba no es asincrónica, el problema está en la firma de arriba, y se arregla hacia arriba hasta
> el punto de entrada.

**Segunda: `async void`.**

```csharp
// ❌ Compila sin una advertencia. Y es una trampa completa.
public async void LoadAll(string directory)
{
    await LoadAsync(Path.Combine(directory, "dismex.csv"), CancellationToken.None);
}
```

Tres cosas pasan aquí, y las tres son malas. **No se puede esperar**: quien llama no tiene nada que
`await`, así que sigue adelante como si hubiera terminado. **No se pueden atrapar sus excepciones**:
un `try`/`catch` alrededor de la llamada no ve nada, porque la excepción se lanza después, en el
contexto de sincronización, y en una aplicación de consola **tumba el proceso**. Y no se puede probar:
no hay forma de saber cuándo acabó.

```csharp
// ✅ Task, siempre. Aunque no devuelva un valor.
public async Task LoadAllAsync(string directory, CancellationToken token)
{
    await LoadAsync(Path.Combine(directory, "dismex.csv"), token);
}
```

> 🧭 **La prohibición, escrita con su excepción dentro para que no haya que romperla después:**
> **`async void` solo es correcto en un manejador de eventos**, porque ahí la firma la impone el
> lenguaje y el que invoca es el bucle de mensajes, que no espera a nadie. En este curso eso pasa
> **una vez**, en la fase 12, con los formularios de SIGE — y entender por qué ahí sí es la lección de
> esa fase. Fuera de un manejador de eventos, `async void` es un error.

**Tercera: pensar en hilos en vez de en tareas.**

```csharp
// ❌ El reflejo del que dimensionó pools once años: si hay que hacer tres cosas a la vez, tres
//    hilos. Y para trabajo de entrada/salida, la herramienta que parece obvia:
Parallel.ForEach(distributors, distributor =>
{
    LoadAsync(distributor.Path, CancellationToken.None).Wait();   // ← dos errores en una línea
});
```

`Parallel.ForEach` está diseñado para **trabajo de CPU**: parte el rango entre los núcleos
disponibles y los mantiene ocupados. Con trabajo de entrada y salida, lo que hace es ocupar un hilo
por elemento para que se quede esperando — y encima obliga a bloquear, porque su delegado es
sincrónico.

```csharp
// ✅ Para trabajo de entrada/salida, las tareas se lanzan y se esperan juntas. Sin hilos de por
//    medio y sin bloquear ninguno.
IEnumerable<Task<LoadSummary>> loads = distributors.Select(d => LoadAsync(d, token));
LoadSummary[] summaries = await Task.WhenAll(loads);
```

**Dónde se rompe el paralelo, y es una diferencia de fondo:** Java resolvió este mismo problema de
otra manera. Los **hilos virtuales** hacen que bloquear sea baratísimo, así que el código sigue
siendo secuencial y el runtime se encarga. .NET eligió el camino contrario: **colorear las
funciones** — un método asincrónico se declara `async`, devuelve `Task`, y quien lo llama tiene que
saberlo. Las dos respuestas resuelven el mismo problema y las dos tienen su costo: los hilos
virtuales no te piden cambiar el código y a cambio esconden dónde está la espera; `async`/`await` te
obliga a propagarlo por toda la cadena y a cambio la espera es visible en la firma.

No hay ganador y el curso no lo va a fingir. Lo que sí hay es una consecuencia práctica: **en .NET la
asincronía es viral y tiene que ser de punta a punta**, y el sitio donde la cadena se rompe es donde
aparece el `.Result`.

### 🩻 Esto sí funciona igual

Todo el razonamiento sobre concurrencia. Las condiciones de carrera son las mismas, la necesidad de
sincronizar el acceso a estado compartido es la misma, los límites de recursos son los mismos, y el
`backpressure` es el mismo problema con el mismo nombre. Si sabes por qué un pool sin límite es una
bomba, ese conocimiento vale aquí íntegro.

Los primitivos tienen otros nombres y el mismo significado: `synchronized` es `lock`, un semáforo es
un `SemaphoreSlim`, una cola concurrente es una `ConcurrentQueue<T>`, y `volatile` es `volatile`. El
modelo de memoria es distinto en los detalles y equivalente en lo que decide tu código.

Y una que conviene decir en voz alta: **el instinto de no compartir estado mutable entre tareas se
transfiere entero y aquí hace más falta**, porque la continuación de un `await` puede ejecutarse en un
hilo distinto del que empezó el método. Ese hecho, que suena inquietante, es exactamente el mismo
problema que ya manejas.

### 📖 Diccionario de traducción

| Java | C# / .NET | Dónde se rompe el paralelo |
|---|---|---|
| `CompletableFuture<T>` | `Task<T>` | La `Task` de un método `async` **ya está corriendo**: no hay que arrancarla |
| `supplyAsync(() -> …)` | `Task.Run(() => …)` | `Task.Run` es para trabajo de **CPU**. Para entrada/salida no hace falta: el método `async` ya no bloquea |
| `.thenApply` / `.thenCompose` | `await` | El `await` deja el código lineal: no hay cadena de callbacks que leer al revés |
| `.get()` / `.join()` | `.Result` / `.Wait()` | **Prohibidos en este curso.** Bloquean un hilo del grupo, diseñado para que nadie lo bloquee |
| `allOf(...)` | `Task.WhenAll(...)` | Devuelve los resultados en un arreglo, en el orden de entrada |
| `anyOf(...)` | `Task.WhenAny(...)` | Devuelve **la tarea** que terminó, no su resultado |
| hilos virtuales | `async`/`await` | **Dos respuestas al mismo problema.** Los virtuales no te piden cambiar el código y esconden la espera; `async` la hace visible y te obliga a propagarla |
| `ExecutorService` con pool fijo | `SemaphoreSlim` como límite | No se limita el pool: se limita **cuántas tareas están en vuelo**. El pool no es tuyo |
| `Thread.interrupt()` | `CancellationToken` | **Cooperativa**: nadie interrumpe a nadie. Si tu bucle no mira el token, no se puede cancelar |
| `InterruptedException` | `OperationCanceledException` | La lanza tu propio código al mirar el token, no el runtime desde fuera |
| `BlockingQueue<T>` | `Channel<T>` | Asincrónica de raíz: `WriteAsync`/`ReadAsync` no bloquean, y el límite da backpressure |
| `synchronized` | `lock` (y `System.Threading.Lock` desde .NET 9) | **No se puede `await` dentro de un `lock`**: el compilador lo prohíbe. Para eso, `SemaphoreSlim` |
| `AtomicInteger` | `Interlocked` | Métodos estáticos sobre la variable, no un tipo envolvente |
| `parallelStream()` | `Parallel.ForEach` / PLINQ | Los dos son para **CPU**. Con entrada/salida hacen exactamente lo que no quieres |

> ⚠️ **La fila de `lock` merece atención porque el compilador la convierte en error.** No se puede
> `await` dentro de un `lock`, y no es un capricho: la continuación podría retomar en otro hilo, y un
> `Monitor` es de propiedad del hilo que lo tomó, así que liberarlo desde otro es corrupción. La
> alternativa es `SemaphoreSlim` con `WaitAsync`. Si vienes de `synchronized` alrededor de un bloque
> que hace entrada y salida, esa traducción no existe y hay que rediseñar.

> 📝 **Nota de ecosistema.** `async`/`await` llegó con C# 5 en 2012 —nueve años antes de que Java
> tuviera hilos virtuales en vista previa— y eso explica dos cosas del código que vas a encontrar. La
> primera: hay una generación entera de bibliotecas .NET con dos versiones de cada método, una
> sincrónica y una `Async`, porque había que mantener compatibilidad. La segunda, y es la que importa
> en este curso: **`Sige.DataAccess` es de 2017 y no tiene una sola línea asincrónica**, aunque el
> lenguaje ya lo tenía cinco años. Cuando la fase 09 tenga que llamar a ese código desde un servicio
> asincrónico, el `.Result` va a ser la tentación — y ahí es donde esta fase se cobra.

---

## 💻 5. Código mínimo con comentarios

### 5.1 La cadena completa, asincrónica de punta a punta

```csharp
// src/modern/Cordillera.Domain/Import/SalesImporter.cs
namespace Cordillera.Domain.Import;

/// <summary>
/// Carga los archivos de los tres distribuidores. Asincrónica de punta a punta, con concurrencia
/// limitada y cancelación cooperativa.
/// </summary>
public sealed class SalesImporter
{
    private readonly int _maxConcurrency;

    public SalesImporter(int maxConcurrency = 3)
    {
        // El límite es un parámetro y no una constante porque la medición de la sección 6 barre
        // varios valores, y porque el valor correcto depende de la máquina y del disco.
        if (maxConcurrency < 1)
        {
            throw new ArgumentOutOfRangeException(
                nameof(maxConcurrency), maxConcurrency, "El límite de concurrencia tiene que ser al menos 1.");
        }

        _maxConcurrency = maxConcurrency;
    }

    /// <summary>
    /// Carga los tres archivos con concurrencia limitada. Si uno falla, los otros terminan: el
    /// aislamiento es el mismo requisito que en la fase 04, ahora con tareas.
    /// </summary>
    public async Task<IReadOnlyList<LoadSummary>> ImportAllAsync(
        IReadOnlyList<DistributorFile> files,
        CancellationToken token)
    {
        // El límite se aplica a cuántas tareas están EN VUELO, no a cuántos hilos hay. El grupo de
        // hilos no es nuestro y no se dimensiona desde aquí.
        using var gate = new SemaphoreSlim(_maxConcurrency);

        IEnumerable<Task<LoadSummary>> loads = files.Select(file => ImportOneAsync(file, gate, token));

        // WhenAll espera a todas y devuelve los resultados en el orden de entrada. Si varias
        // lanzaron, la excepción que sale es la primera — y las demás están en InnerExceptions.
        return await Task.WhenAll(loads);
    }

    private async Task<LoadSummary> ImportOneAsync(
        DistributorFile file,
        SemaphoreSlim gate,
        CancellationToken token)
    {
        // WaitAsync y no Wait: esperar el turno no bloquea un hilo. Y respeta la cancelación, así
        // que un proceso encolado que todavía no empezó se cancela sin haber abierto nada.
        await gate.WaitAsync(token);

        try
        {
            return await ImportFileAsync(file, token);
        }
        catch (OperationCanceledException)
        {
            // La cancelación no es un error: es lo que pedimos. Se reporta como interrupción y se
            // devuelve — no se traga y no se convierte en un fallo.
            return LoadSummary.Interrupted(file.DistributorCode);
        }
        catch (IOException ex)
        {
            // Archivo inaccesible: es esperado y aislado. Los otros dos siguen (política de la F04).
            return LoadSummary.CouldNotOpen(file.DistributorCode, ex.Message);
        }
        finally
        {
            gate.Release();
        }
    }
}
```

**Detalles con intención**

- **`SemaphoreSlim` y no un pool de hilos dimensionado.** Es la traducción correcta del
  `ExecutorService` con pool fijo: lo que se limita es el número de operaciones en vuelo. El grupo de
  hilos se administra solo y dimensionarlo a mano es pelear con el runtime.
- **`WaitAsync(token)` recibe el token**, así que cancelar mientras un archivo espera turno lo cancela
  antes de abrir nada. Es gratis y casi nadie lo escribe.
- **`catch (OperationCanceledException)` va antes** que los demás, y no se registra como error. Una
  cancelación registrada como fallo es cómo se acaba con un log lleno de alarmas que nadie mira.
- **El `finally` con `gate.Release()`** es uno de los pocos `finally` legítimos del curso: no hay
  `using` que lo exprese, porque lo que hay que liberar es un permiso, no el semáforo.

### 5.2 La cancelación, que solo funciona si alguien mira

```csharp
private async Task<LoadSummary> ImportFileAsync(DistributorFile file, CancellationToken token)
{
    int accepted = 0;
    int rejected = 0;
    int lineNumber = 0;

    // 💸 Cobro de la deuda de la fase 04: `await using`, no `using`. Con el cierre sincrónico el
    // búfer pendiente se perdía y el archivo de auditoría quedaba corto. La factura:
    //    git diff fase-04 fase-05 -- src/modern/Cordillera.Domain/Import/
    await using var audit = new AuditTrailWriter(file.AuditPath);
    using var reader = new DistributorFileReader(file.Path, file.Format);

    // El lector devuelve el resultado de interpretar cada línea: o una fila, o el motivo por el que
    // no lo es. Es la misma política de la fase 04 —el dato sucio es parte del trabajo, no una
    // excepción— y por eso `SalesRow` no tiene una propiedad `IsValid`: una fila que existe es
    // válida por construcción.
    await foreach (ParsedLine parsed in reader.ReadLinesAsync(token))
    {
        lineNumber++;

        // La comprobación explícita del token. Sin esto, el bucle no se puede cancelar aunque
        // todas las llamadas de dentro reciban el token: cancelar es cooperativo y este bucle es
        // el que tiene que cooperar.
        token.ThrowIfCancellationRequested();

        if (parsed.Row is SalesRow row)
        {
            accepted++;
            await audit.WriteAsync($"ok|{file.DistributorCode}|{lineNumber}|{row.EditionCode}", token);
        }
        else
        {
            rejected++;
            await audit.WriteAsync($"rechazo|{file.DistributorCode}|{lineNumber}|{parsed.Reason}", token);
        }
    }

    return LoadSummary.Complete(file.DistributorCode, accepted, rejected);
}
```

**El patrón a memorizar**

> **Un `CancellationToken` se recibe, se propaga y se mira.** Recibirlo en la firma y no pasarlo a la
> llamada de dentro es tan inútil como no recibirlo; pasarlo a todo y no comprobarlo en el bucle
> propio deja un proceso que no se puede detener en la única parte que tarda. Las tres cosas, o
> ninguna sirve.

> 💸 **Deuda declarada: dos métodos sin `CancellationToken`.**
>
> ```csharp
> // 💸 F17 — Estos dos no reciben token, a propósito y declarado. `RecalculateTotalsAsync` recorre
> // lo ya cargado en memoria y tarda milisegundos; `FlushSummaryAsync` escribe el resumen final y
> // cancelarlo dejaría el resumen a medias, que es peor que esperarlo.
> //
> // El argumento parece razonable y es exactamente el que se usa para no propagar el token. Se
> // cobra en la F17, cuando el mismo recorrido sea la liquidación trimestral de seis horas: ahí
> // "tarda milisegundos" deja de ser cierto y "cancelarlo dejaría todo a medias" se convierte en el
> // requisito de reanudación.
> public Task RecalculateTotalsAsync();
> public Task FlushSummaryAsync();
> ```
>
> **Por qué se dejan:** porque son el caso genuinamente discutible. Un token en un método que tarda
> dos milisegundos es ruido, y el curso no va a fingir que siempre es obvio. Lo que la F17 demuestra
> es que **la duración de una operación no es una propiedad del método, es una propiedad de los
> datos** — y los datos crecen.

### 5.3 `ValueTask`, y su única regla

```csharp
/// <summary>
/// Busca una edición en la caché del catálogo, y solo va al origen si no está. Devuelve
/// `ValueTask` porque **acierta el 95% de las veces**: con `Task` serían 95 asignaciones por cada
/// 100 llamadas para devolver algo que ya estaba en memoria.
/// </summary>
public ValueTask<Edition?> FindAsync(EditionId id, CancellationToken token)
{
    if (_cache.TryGetValue(id, out Edition? cached))
    {
        // Camino rápido: sin asignación, sin máquina de estados, sin cambio de contexto.
        return new ValueTask<Edition?>(cached);
    }

    return new ValueTask<Edition?>(LoadAsync(id, token));
}
```

> ⚠️ **La regla de `ValueTask` es estricta y el compilador no la vigila: se consume una vez.** No se
> guarda en un campo, no se espera dos veces, no se le pide `.Result`. Si necesitas cualquiera de esas
> cosas, `AsTask()` primero. Y el criterio para usarla: **solo donde el camino rápido sea el común y
> la asignación se haya medido**. En una API pública que alguien más va a consumir, `Task` es la
> respuesta por defecto, porque es la que no tiene trampas.

### 5.4 Cómo se prueba código asincrónico

```csharp
public class SalesImporterTests
{
    // La prueba devuelve Task y xUnit la espera. Nada de .Result y nada de async void: una prueba
    // `async void` en xUnit v3 ni siquiera se ejecuta como esperas.
    [Fact]
    public async Task Un_archivo_inaccesible_no_impide_que_los_otros_dos_carguen()
    {
        var importer = new SalesImporter(maxConcurrency: 3);
        IReadOnlyList<DistributorFile> files =
        [
            ValidFile("DISMEX"),
            MissingFile("DISCOL"),          // no existe
            ValidFile("DISARG"),
        ];

        IReadOnlyList<LoadSummary> summaries = await importer.ImportAllAsync(files, TestContext.Current.CancellationToken);

        Assert.Equal(LoadOutcome.Complete, summaries[0].Outcome);
        Assert.Equal(LoadOutcome.CouldNotOpen, summaries[1].Outcome);
        Assert.Equal(LoadOutcome.Complete, summaries[2].Outcome);
    }

    [Fact]
    public async Task Cancelar_a_mitad_interrumpe_y_deja_el_resto_cerrado()
    {
        using var cts = new CancellationTokenSource();
        var importer = new SalesImporter(maxConcurrency: 1);

        // Se cancela cuando el primer archivo ya empezó: un token cancelado desde el principio
        // probaría otra cosa —que no se empieza— y esa es una prueba distinta, que también hay que
        // escribir.
        await cts.CancelAsync();

        IReadOnlyList<LoadSummary> summaries = await importer.ImportAllAsync([LargeFile("DISMEX")], cts.Token);

        Assert.Equal(LoadOutcome.Interrupted, summaries[0].Outcome);

        // Y la garantía que importa: el archivo quedó cerrado, así que se puede reescribir.
        File.WriteAllText(summaries[0].AuditPath, "reescrito");
    }

    [Fact]
    public async Task El_limite_de_concurrencia_se_respeta()
    {
        int concurrent = 0;
        int maxObserved = 0;

        // Interlocked y no ++: esto se lee y se escribe desde varias tareas a la vez, y es el mismo
        // razonamiento de concurrencia que ya traes de Java.
        async Task<LoadSummary> Tracked(DistributorFile file, CancellationToken token)
        {
            int now = Interlocked.Increment(ref concurrent);

            // No existe `Interlocked.Max`: el máximo se actualiza con un bucle de comparación e
            // intercambio, que es el patrón estándar cuando la operación no viene atómica de
            // fábrica. Es el mismo razonamiento de un `compareAndSet` de Java.
            int observed;
            do
            {
                observed = Volatile.Read(ref maxObserved);
            }
            while (now > observed &&
                   Interlocked.CompareExchange(ref maxObserved, now, observed) != observed);

            await Task.Delay(50, token);
            Interlocked.Decrement(ref concurrent);
            return LoadSummary.Complete(file.DistributorCode, 0, 0);
        }

        var importer = new SalesImporter(maxConcurrency: 2, importOne: Tracked);
        await importer.ImportAllAsync([.. SixFiles()], TestContext.Current.CancellationToken);

        Assert.Equal(2, maxObserved);
    }
}
```

**Detalles con intención**

- **`TestContext.Current.CancellationToken`** en vez de `CancellationToken.None`: xUnit v3 provee un
  token que se cancela cuando la prueba excede su tiempo límite, así que una prueba colgada falla en
  vez de bloquear la suite.
- **La prueba del límite inyecta la operación** como delegado — la lección de la fase 04 usada en
  serio. Sin ese punto de inyección, la única forma de probar el límite sería medir tiempos, que es
  una prueba frágil.
- **Hay dos pruebas de cancelación distintas** y las dos hacen falta: cancelar antes de empezar y
  cancelar a mitad. El segundo caso es el que se rompe cuando alguien mueve el
  `ThrowIfCancellationRequested`.

**Prueba de fuego**

```powershell
# El servicio de la medición, con 200 peticiones concurrentes, en sus dos versiones.
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 05 --concurrency 200
```

Mira **el número de hilos del proceso**, no la latencia media. La versión con `.Result` va a tener
decenas o cientos de hilos y un uso de CPU bajísimo; la versión con `await`, un puñado.

Y la mentira que te va a contar la salida si miras el lugar equivocado: **con 10 peticiones
concurrentes las dos versiones dan lo mismo**, y con 50 también, casi. El grupo de hilos absorbe el
abuso hasta que deja de poder, y el punto donde deja de poder no es una pendiente suave: es un codo.
Si mides con poca carga, concluyes que `.Result` está bien — que es lo que concluyó todo el que puso
un `.Result` en producción.

---

## 📏 6. Medición

**Esta es la pieza central de la fase**, no su cierre. Un desarrollador senior no cambia un reflejo
porque un curso se lo pida; lo cambia cuando ve el número de hilos.

**Hipótesis:** el mismo servicio, implementado con `.Result` y con `await`, atiende la misma carga con
un número de hilos radicalmente distinto — y a partir de cierta concurrencia la versión bloqueante no
se degrada suavemente sino que **se cae de un codo**, con la CPU casi libre.

**Condiciones:** SDK 10.0.401 · Release · Windows 11 · el mismo endpoint que consulta el catálogo con
una latencia simulada de 80 ms —el tiempo real de la consulta contra el `UNION ALL` que la fase 07 va
a medir— · barrido de concurrencia en 10, 50, 100, 200 y 400 peticiones · 30 segundos por punto,
calentamiento descartado · arnés propio, que para esto es lo correcto: la pregunta es de trabajo
completo y no de microbenchmark.

**Competidores:** cuatro implementaciones del mismo servicio, todas correctas en el sentido de que
devuelven lo mismo:

- **`await` de punta a punta** — lo que el curso enseña.
- **`.Result` en el borde** — un solo `.Result`, en el controlador, "porque la firma de arriba no era
  asincrónica". Es el caso realista, y el que hay que medir.
- **`.Result` en el medio** — el `.Result` dentro de un método que sí es asincrónico. Es peor y hay
  que mostrar cuánto.
- **`Parallel.ForEach` con `.Wait()`** — el reflejo del que dimensionó pools, sobre trabajo de
  entrada y salida.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 05 --sweep 10,50,100,200,400
```

**Resultado:** ⏳ pendiente de ejecución en tu máquina.

| Implementación | Concurrencia | Throughput (req/s) | Latencia p95 | Hilos del proceso | CPU % |
|---|---|---|---|---|---|
| `await` de punta a punta | 200 | ⏳ | ⏳ | ⏳ | ⏳ |
| `.Result` en el borde | 200 | ⏳ | ⏳ | ⏳ | ⏳ |
| `.Result` en el medio | 200 | ⏳ | ⏳ | ⏳ | ⏳ |
| `Parallel.ForEach` + `.Wait()` | 200 | ⏳ | ⏳ | ⏳ | ⏳ |

Y la tabla del barrido, que es la que enseña de verdad:

| Concurrencia | `await`: hilos / p95 | `.Result`: hilos / p95 |
|---|---|---|
| 10 | ⏳ | ⏳ |
| 50 | ⏳ | ⏳ |
| 100 | ⏳ | ⏳ |
| 200 | ⏳ | ⏳ |
| 400 | ⏳ | ⏳ |

> ⚖️ **Veredicto** *(expectativa, todavía sin ejecutar — `formato-de-mediciones.md` §2.6)*. Se espera
> que con 10 y 50 las dos versiones queden **empatadas** —y hay que publicarlo así, porque explica por
> qué este bug sobrevive a las pruebas de carga tibias— y que a partir de cierto punto la versión
> bloqueante muestre un número de hilos que crece con la concurrencia mientras la CPU se queda baja.
>
> **El umbral que tu ejecución tiene que determinar, y es el número que el lector se lleva a su
> trabajo:** **la concurrencia del codo** — a partir de qué número de peticiones simultáneas la
> versión bloqueante deja de degradarse suavemente. Ese número, comparado con el tráfico real de
> Cordillera, es lo que decide si un `.Result` heredado es una bomba o una fealdad tolerable. Las dos
> respuestas son posibles y la medición dice cuál.
>
> Y una advertencia sobre cómo leer la columna de CPU: **la CPU baja con latencia alta es la firma del
> problema.** Si la CPU estuviera al 90%, el diagnóstico sería otro y la solución también.

---

## 🧱 7. Miniproyecto — la consolidación de los tres distribuidores, en paralelo y cancelable

**El encargo**

Wilson otra vez, y ahora con más detalle: *"La carga que arreglaste anda bien, pero se demora: son
los tres archivos uno detrás del otro y el de México es el grande. Quiero que vayan juntos. Y quiero
poder pararla — pero pararla de verdad, que la vez pasada le dimos Ctrl+C y quedó una fila escrita a
medias en la auditoría y estuvimos una mañana averiguando si esa venta había entrado o no. Ah, y
Duván pregunta cuántos archivos a la vez conviene: dice que si ponemos los tres el disco se pelea."*

**Por qué duele**

Porque las tres cosas que pide se contradicen entre sí si no se diseñan juntas. **Paralelo** quiere
más tareas en vuelo; **cancelable de verdad** quiere que ninguna quede a medio escribir; y la
pregunta de Duván no tiene una respuesta teórica — **hay que medirla**, y el óptimo depende del disco
de la máquina.

Y porque el "a medias" de Wilson es un requisito difícil escondido en una queja: cancelar no puede
dejar una línea de auditoría partida, y eso obliga a decidir qué es una unidad indivisible en este
proceso.

**Datos de entrada**

Los tres archivos de la fase 04, ahora con volumen real: **`DISMEX` con 78.000 filas**, `DISCOL` con
31.000 y `DISARG` con 11.000. Los generas repitiendo y variando los fragmentos de la fase 04 con
semilla fija.

Y tres condiciones que hay que poder provocar a voluntad:

- **Latencia artificial por fila** configurable, para simular que el origen no es un archivo local
  sino el recurso compartido de red donde viven de verdad. Sin esto, el paralelismo no se puede medir
  con honestidad: en un SSD local la entrada y salida casi no espera.
- **Cancelación en un punto conocido** —por ejemplo, a los dos segundos o en la fila N— para poder
  probar el cierre.
- **Un fallo del sistema** a mitad del archivo grande: el disco de auditoría inaccesible.

**Criterios de aceptación**

1. Los tres archivos se cargan **con concurrencia limitada y configurable**, y una prueba demuestra
   que el límite se respeta —sin medir tiempos, que es una prueba frágil—.
2. **Cero `.Result`, cero `.Wait()`, cero `async void`** en todo el proyecto. Un analizador o una
   búsqueda en el repositorio lo demuestra, y el resultado se pega en el commit.
3. Cancelar deja el proceso en un estado **explicable**: el resumen dice qué archivo se interrumpió y
   en qué fila, ninguna línea de auditoría queda partida, y todos los recursos quedan cerrados. Una
   prueba lo demuestra reescribiendo los archivos después.
4. **Ninguna línea de auditoría se pierde** con el cierre asincrónico. Es la deuda de la fase 04,
   cobrada: el mismo conteo que allí fallaba, aquí cuadra.
5. El `CancellationToken` se propaga por **toda** la cadena, y los métodos que no lo reciben están
   declarados con su razón y su fase de cobro.
6. **Medición de cierre:** el barrido de concurrencia de 1 a 6 archivos en vuelo sobre los tres
   archivos completos, con el tiempo total de cada punto, y **la respuesta a la pregunta de Duván con
   su número**. Va en el mensaje del tag `mini-05`.

**Restricciones de estilo y alcance**

Código nuevo, asincrónico de punta a punta. **Sin `IAsyncEnumerable` propio** —es la fase 06— así que
si necesitas leer las filas de a una, usa lo que la fase 04 dejó y espera la línea con `ReadLineAsync`.
Sin paquetes, sin `Task.Run` alrededor de trabajo de entrada y salida, y sin `Parallel.ForEach`.

**La trampa**

Vas a poner el límite de concurrencia en tres, uno por archivo, porque son tres archivos. Va a
funcionar y va a ser más rápido que la versión secuencial.

Y después vas a probar con seis y con uno, y **el resultado te va a sorprender en al menos una de las
dos direcciones**, porque el cuello de botella no es el que crees: con latencia artificial alta el
óptimo se va hacia arriba, y con archivos locales en un disco ocupado puede estar en **uno**. La
respuesta "tres porque son tres archivos" es la que suena razonable y no está medida.

Hay una segunda trampa, y es la del criterio 3. Vas a comprobar el token al principio de cada fila y
te va a parecer suficiente. Pero entre "leí la fila" y "escribí las dos líneas de auditoría" hay un
`await`, y una cancelación que caiga justo ahí deja la fila contada y no auditada — o auditada y no
contada. Cuál de las dos ocurre depende del orden en que escribiste tu código, y el requisito de
Wilson dice que **ninguna de las dos es aceptable**. Decide dónde está la unidad indivisible y
escríbelo.

<details><summary>Pista 1 — el enfoque</summary>

Separa tres decisiones que la versión natural mezcla: **cuántas tareas en vuelo** (un semáforo),
**qué pasa cuando una falla** (el coordinador decide, la tarea informa) y **dónde se puede cancelar
sin dejar nada a medias** (la unidad indivisible).

Para lo tercero, la pregunta útil no es "¿dónde compruebo el token?" sino "¿qué grupo de operaciones
tiene que ocurrir completo o no ocurrir?". En cuanto la nombres, el sitio de la comprobación es obvio.

</details>

<details><summary>Pista 2 — la herramienta</summary>

`SemaphoreSlim.WaitAsync(token)` para el límite, y `Task.WhenAll` para esperar. Lee con cuidado qué
hace `WhenAll` cuando **varias** tareas lanzan, porque no es lo que parece:
`https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.whenall`

Para el barrido de la pregunta de Duván, el arnés de la fase 00 con el parámetro de concurrencia.

Y mira `CancellationTokenSource.CreateLinkedTokenSource`: te va a servir para combinar la cancelación
del usuario con un tiempo límite, que es lo que la fase 17 va a necesitar de verdad.

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```csharp
internal sealed class ImportCoordinator(int maxConcurrency, IAuditSink audit)
{
    public Task<IReadOnlyList<LoadSummary>> RunAsync(
        IReadOnlyList<DistributorFile> files,
        CancellationToken token);
}

// La unidad indivisible: la fila se cuenta Y se audita, o no pasa ninguna de las dos cosas.
internal sealed record AuditedRow(SalesRow Row, string AuditLine);

// El barrido que responde a Duván. Devuelve tiempo total por punto de concurrencia.
internal static Task<IReadOnlyDictionary<int, TimeSpan>> SweepConcurrencyAsync(
    IReadOnlyList<DistributorFile> files,
    IReadOnlyList<int> concurrencyLevels,
    CancellationToken token);
```

</details>

**Cómo se entrega**

```powershell
dotnet test src\Cordillera.slnx -c Release
dotnet run -c Release --project src\fases\05-async-await-y-cancelacion\mini -- datos\ --concurrency 3
dotnet run -c Release --project src\fases\05-async-await-y-cancelacion\mini -- datos\ --sweep 1,2,3,4,6
```

```bash
git tag -a mini-05 -m "Mini F5: consolidación paralela y cancelable · 120.000 filas en <X> s con límite <N> · óptimo medido en <N> archivos en vuelo · 0 líneas de auditoría perdidas"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Convierte un método sincrónico del modelo a asincrónico y propaga el cambio hacia arriba hasta el
   punto de entrada. Cuenta cuántas firmas tuviste que tocar: ese número es el costo de colorear las
   funciones, y conviene sentirlo.
2. Escribe una prueba `async Task` que verifique que un método asincrónico lanza
   `OperationCanceledException` con un token ya cancelado.
3. Reemplaza un `Thread.Sleep` por `await Task.Delay` en una prueba y explica qué cambió para el
   grupo de hilos.
4. Escribe un método que devuelva `Task` sin ser `async` —devolviendo directamente la tarea de
   dentro— y di en qué caso eso es mejor y en qué caso es peor.
5. Usa `Task.WhenAny` para quedarte con el primer archivo que termine de cargar, y explica por qué
   devuelve la tarea y no el resultado.
6. Provoca un `async void` en una aplicación de consola, haz que lance, y observa qué pasa con el
   proceso. Escribe una línea sobre por qué ese `try`/`catch` no sirvió.

**🟡 Intermedio (7–14)**

7. Limita la concurrencia con `SemaphoreSlim` y después con `Parallel.ForEachAsync`. Compara las dos
   versiones en legibilidad y di cuál dejarías, con argumentos.
8. Escribe un método que devuelva `ValueTask` con camino rápido de caché, y mide con el arnés las
   asignaciones frente a la versión con `Task` sobre un millón de llamadas con 95% de aciertos.
9. Consume la misma `ValueTask` dos veces y documenta qué pasa. Después arréglalo con `AsTask()` y
   explica el costo.
10. Usa `CancellationTokenSource.CreateLinkedTokenSource` para combinar la cancelación del usuario con
    un tiempo límite de treinta segundos, y prueba los dos caminos.
11. Escribe un `Channel<T>` acotado con un productor y dos consumidores, y demuestra el backpressure:
    el productor se frena cuando los consumidores no alcanzan.
12. Intenta poner un `await` dentro de un `lock` y explica el error del compilador. Después resuelve
    el mismo problema con `SemaphoreSlim` y di qué garantía perdiste.
13. Registra con el arnés en qué hilo se ejecuta cada parte de un método `async` —antes del primer
    `await`, después del primero, después del segundo— y explica el resultado.
14. Escribe una prueba que falle de forma intermitente por depender del orden de dos tareas, y
    después arréglala **sin** usar esperas por tiempo.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Un servicio responde bien con 50 usuarios y con 300 las latencias se van a
    veinte segundos con la CPU al 8%. Escribe el procedimiento de diagnóstico: qué mirarías primero,
    con qué herramienta, y cuál es la firma que confirma la hipótesis.
16. **Diagnóstico.** Un proceso nocturno "no responde a Ctrl+C". Recibe el `CancellationToken` en
    todas sus firmas y lo propaga. Encuentra las dos razones posibles y escribe la prueba que
    distingue una de la otra.
17. **Medición.** Ejecuta la medición de la sección 6 completa, con el barrido, y determina **la
    concurrencia del codo**. Publica las dos tablas con su veredicto, incluido el empate de las
    concurrencias bajas.
18. **Medición.** Compara `Task.WhenAll` sobre 1.000 tareas contra procesarlas en lotes de 50 con
    límite. Reporta tiempo, memoria y número de hilos, y determina a partir de cuántas tareas el
    límite deja de ser opcional.
19. Toma la versión con `.Result` de la medición y arréglala **hacia arriba** hasta el punto de
    entrada. Cuenta las firmas tocadas y el tiempo que te llevó: es el número que necesitas para
    defender que la asincronía se diseña al principio y no se agrega después.
20. **Decisión — ¿se migra, se envuelve o se deja quieto?** `Sige.DataAccess` es sincrónico entero y
    la fase 09 va a tener que llamarlo desde un servicio asincrónico. Las opciones son envolverlo con
    `Task.Run`, dejar un `.Result` en el borde y documentarlo, o reescribir sus 40 métodos. Decide y
    sostén la decisión con el umbral del ejercicio 17.
21. **Decisión — ¿se migra, se envuelve o se deja quieto?** El proceso de carga nocturno tarda seis
    horas y falló dos veces en la hora cinco. Con lo de esta fase puedes hacerlo paralelo y
    cancelable, pero **no reanudable** —eso es la fase 17—. Decide si se despliega así o se espera, y
    di qué riesgo asume cada opción.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Escribe un interbloqueo con `.Result` que ocurra de forma determinista.
    *(Requiere un contexto de sincronización; en una consola no pasa, y entender por qué es media
    respuesta.)* Explica por qué el mismo código funciona en una consola y se cuelga en una
    aplicación de escritorio — lo cual anticipa la fase 12.
23. **Adversarial.** Consigue que una excepción lanzada dentro de una tarea **desaparezca sin
    rastro**, sin `catch` alguno. Después explica qué cambió en .NET respecto de las primeras
    versiones sobre excepciones no observadas, y cómo detectarlas hoy.
24. **Diseño y medición.** Diseña la unidad indivisible del miniproyecto —qué tiene que ocurrir
    completo o no ocurrir— y demuestra con una prueba que una cancelación en el peor momento posible
    no deja estado inconsistente. Mide cuánto cuesta esa garantía en filas por segundo.
25. **Defiende una decisión.** Clara pregunta por qué hay que "reescribir" el acceso a datos si el
    sistema funciona, y por qué no se puede simplemente "poner más servidor". Responde en media
    página, en su lenguaje, con los números del ejercicio 17: cuántas peticiones simultáneas aguanta
    cada versión y qué cuesta cada una al mes.

**🔥 Opcionales**

- Investiga `ConfigureAwait(false)` y escribe por qué este curso **no** lo usa: qué cambió cuando
  ASP.NET Core dejó de tener contexto de sincronización, y en qué proyecto de este curso sí haría
  falta. *(Pista: en el Bloque C.)*
- Mide el costo de la máquina de estados de un método `async` que nunca espera de verdad —porque su
  camino rápido siempre acierta— y decide si vale la pena el camino con `ValueTask`.
- Lee sobre `TaskCompletionSource` y escribe un adaptador que convierta una API de callbacks de 2017
  en una `Task`. Guárdalo: la fase 11 lo va a necesitar con los ASMX.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/` — el modelo completo, y la
  distinción entre trabajo ligado a entrada/salida y ligado a CPU. Es la lectura de la fase.
- `https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/async-scenarios` — qué hace el
  compilador con un método `async`, paso a paso.
- `https://learn.microsoft.com/dotnet/standard/asynchronous-programming-patterns/` — los tres
  patrones históricos, que importan porque **los dos viejos están en el código que vas a heredar**.
- `https://learn.microsoft.com/dotnet/standard/threading/cancellation-in-managed-threads` —
  cancelación cooperativa: quién levanta la señal y quién tiene que mirarla.
- `https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.whenall` — `WhenAll`, y **qué
  excepción sale cuando varias tareas lanzan**, que no es lo que parece.
- `https://learn.microsoft.com/dotnet/api/system.threading.channels` — `Channel<T>` y el
  backpressure, que la fase 17 va a usar en serio.
- `https://learn.microsoft.com/dotnet/csharp/language-reference/operators/await` — las reglas de
  `await`, incluida la prohibición dentro de `lock`.
- `https://xunit.net/docs/getting-started/v3/getting-started` — pruebas asincrónicas en xUnit v3 y el
  `TestContext.Current.CancellationToken`.

**Especificación y propuestas del lenguaje**

- `https://github.com/dotnet/csharplang/blob/main/proposals/csharp-8.0/async-streams.md` — la
  propuesta de flujos asincrónicos. Se lee aquí y se usa en la fase 06.
- El artículo de Stephen Toub sobre cómo funciona `async`/`await` por dentro, en el blog de .NET, es
  la mejor explicación que existe del tema. El título y la URL pueden haber cambiado; búscalo por
  autor y tema y verifica antes de citarlo.

> ⚠️ Verifica las URLs. Y dos advertencias propias de esta fase. La primera: **casi todo el material
> sobre `ConfigureAwait(false)` es anterior a ASP.NET Core** y da un consejo que ya no aplica a un
> servicio moderno, aunque sí aplica al bloque de escritorio. La segunda: el material sobre
> `async`/`await` de 2012-2015 describe un mundo con contexto de sincronización en todas partes, y
> ese mundo es justo el de `Sige` — así que ese material **no está obsoleto para el Bloque C**, que es
> la clase de matiz que este curso tiene que señalar.

**Orden de lectura sugerido:** antes de escribir, la página de programación asincrónica completa.
Durante el miniproyecto, la de cancelación y la de `WhenAll`. Después, el artículo de Stephen Toub: se
entiende bastante mejor cuando ya viste el número de hilos de la medición.

---

## 🚀 10. Cierre y conexión con la siguiente fase

La cadena de carga es asincrónica de punta a punta, con concurrencia limitada y medida —no adivinada—,
cancelación que funciona de verdad y cierre asincrónico que no pierde una línea. Se cobró la deuda que
el miniproyecto de la fase 04 dejó plantada, y quedan dos métodos sin `CancellationToken` declarados
con el argumento que suena razonable y que la fase 17 va a desmontar.

La fase 06 cierra el Bloque A, y lo hace con la pregunta que este bloque fue dejando abierta tres
veces: **¿qué pasa cuando el archivo no cabe en memoria?** La fase 03 dejó un `ToList()` que
"arreglaba" el conteo de recorridos moviendo el problema; la fase 04 materializaba las filas; y esta
fase las procesó de a una pero sin un tipo que lo expresara. La respuesta —`IAsyncEnumerable`, `Span`,
y medir antes de optimizar— es la fase 06. Y ahí, por primera vez en el bloque, el 🩻 va a ser
generoso: **todo el instinto de recolección de basura que traes de la JVM sirve aquí**, y después de
cinco fases corrigiéndote reflejos, eso es un descanso merecido.

> **La señal de que quedó bien:** *"No tengo un solo `.Result` y no me costó trabajo, porque la cadena
> nació asincrónica. Y si alguien me muestra un servicio con latencias altas y CPU baja, sé qué
> buscar."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el miniproyecto
> corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-05 -m "F5 cerrada:
> - cadena de carga asincrónica de punta a punta: cero .Result, cero .Wait, cero async void
> - concurrencia limitada con SemaphoreSlim, con prueba que verifica el límite
> - cancelación cooperativa con unidad indivisible definida, y prueba de cierre tras cancelar
> - deuda 💸 del cierre sincrónico de la F04 cobrada con await using: 0 líneas perdidas
> - medición del codo de concurrencia escrita, con su barrido"
> ```
>
> **Esta fase cobra la deuda del miniproyecto de la fase 04**, y la factura es corta y elocuente:
>
> ```bash
> git diff fase-04 fase-05 -- src/modern/Cordillera.Domain/Import/
> ```
>
> Un `using` que pasó a `await using`, una firma que ganó un `CancellationToken`, y un conteo de
> auditoría que ahora cuadra. Y **planta dos deudas** —los dos métodos sin token— cuyo cobro está a
> doce fases de distancia: cuando llegues a la 17 vas a ver por qué el argumento de "tarda
> milisegundos" no era una propiedad del método.
>
> Los commits llevan su prefijo (`fase 05: …`) y el miniproyecto el tag `mini-05` con sus números. La
> convención está en [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura.*

- **`INSTINTOS.md`** — cuatro entradas en la familia *asincronía*: `.Result`/`.Wait()`, `async void`,
  pensar en hilos en vez de en tareas, y `Parallel.ForEach` sobre trabajo de entrada y salida. La
  primera es la más importante de la familia y necesita **la firma del problema** —latencia alta con
  CPU baja— porque es lo que el lector va a reconocer en producción. Y la de `async void` tiene que
  decir la excepción de la F12 en su propio texto, o la F12 va a parecer una contradicción.
- **`BENCHMARKS.md`** — entrada ⏳ *F05 · `.Result` contra `await` bajo carga*, con dos tablas: el
  punto de 200 y el barrido. El número que sale de aquí —**la concurrencia del codo**— lo citan la
  F09, la F15 y la F20, así que conviene que el índice lo marque como dato transversal.
- **Deudas 💸 registradas:** dos métodos sin `CancellationToken`, cobro en F17. Ya está en el libro de
  §7.1. Conviene anotar allí que el argumento con que se justifican —"tarda milisegundos"— es parte
  del material: la F17 lo cita textualmente para desmontarlo.
- **Deuda 💸 cobrada:** el cierre sincrónico del escritor de auditoría, que nació en el miniproyecto
  de la F04. Es la primera deuda del curso nacida en un miniproyecto, y quedó pagada en la fase
  siguiente. Hay que agregarla al libro de §7.1 con esa genealogía.
- **Para la fase 06:** queda prometido el `IAsyncEnumerable` como respuesta al "y si no cabe en
  memoria", y queda el ejercicio 🔥 de la máquina de estados de un `async` que nunca espera.
- **Para la fase 09:** el ejercicio 20 es literalmente la decisión que la F09 tiene que tomar con
  `Sige.DataAccess`. Si alguien lo resolvió, la 09 debería partir de ahí.
- **Para la fase 11:** el adaptador con `TaskCompletionSource` del ejercicio 🔥 es lo que hace falta
  para envolver los ASMX de 2019.
- **Para la fase 12:** el ejercicio 22 —el interbloqueo que solo ocurre con contexto de
  sincronización— es el puente exacto hacia la excepción de `async void`. La F12 debería citarlo.
- **Riesgo atrapado al revisar:** el borrador de la prueba del límite usaba `InterlockedExtensions.Max`,
  que **no existe en la biblioteca**. Quedó reescrito con el bucle de comparación e intercambio, que
  además enseña algo. Conviene recordar la regla: un método inventado en un ejemplo es el peor error
  posible de un curso, porque el lector lo copia, no compila, y desconfía de todo lo demás.
