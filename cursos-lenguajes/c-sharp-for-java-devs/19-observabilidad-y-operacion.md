# 🔭 Fase 19 — Observabilidad que cruza el borde

> C# para desarrolladores Java senior · Fase 19 de 24 · Bloque D — servicios, datos y nube
> Depende de: 15, 16, 17, 18 · Habilita: 20
> Estilo de esta fase: **nuevo** (.NET 10, C# 14)
> Proyecto que avanza: **todos**. Es la primera fase que no construye funcionalidad: instrumenta lo que ya hay.

---

## 🎯 1. Propósito

Hay cuatro cosas en producción —el catálogo, el cierre de regalías, Redacción y el escritorio de existencias—,
dos runtimes distintos, y un sistema heredado de 1997 debajo de todo. Cuando algo va mal, la conversación de
Cordillera es siempre la misma:

> **Ximena:** "El catálogo está lento."
> **Duván:** "¿Lento cómo? A mí me responde bien."
> **Ximena:** "Lento. Se demora."

Y nadie puede pasar de ahí, porque no hay un solo número que las dos partes puedan mirar.

Lo concreto es esto: **una consulta del catálogo tarda cuatro segundos** y nadie sabe dónde se van. Puede ser
el API, puede ser EF Core generando algo tonto, puede ser `SP_CATALOGO` —el procedimiento de 1997—, puede ser
la red hacia la base en Azure. Cuatro candidatos, ninguna evidencia, y la práctica actual es adivinar en orden
de sospecha.

> 🧭 **La regla de la fase, y es la única razón por la que esta fase existe:** *una traza que se detiene en el
> borde 🧬 no sirve para nada.* El 80% del tiempo de Cordillera se va en código que nadie escribió en esta
> década, y una observabilidad que solo ve lo moderno mide el 20% con una precisión exquisita mientras el
> problema vive del otro lado.

Y una advertencia de tono, porque esta fase se presta al vicio: **la observabilidad no es un panel bonito**. Es
la capacidad de responder una pregunta concreta sobre producción en menos de cinco minutos. Todo lo que no
sirva para eso es decoración con costo mensual.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Las tres piezas —registros, métricas y trazas— están instrumentadas con **OpenTelemetry**, y está claro
      qué pregunta responde cada una.
- [ ] **La traza cruza el borde 🧬**: un identificador de correlación viaja desde la petición HTTP hasta la
      ejecución de `SP_CATALOGO`, y la traza muestra **cuánto tiempo se fue en el procedimiento de 1997**.
- [ ] Los cuatro segundos del catálogo tienen **un responsable identificado con evidencia**, no con sospecha.
- [ ] Los registros son **estructurados**, con el identificador de traza en cada línea, y se puede pasar de un
      registro a su traza.
- [ ] Está instrumentado el trabajo de fondo de la fase 17: una liquidación tiene su traza completa, y se ve
      dónde reintentó.
- [ ] 💸 Se paga la deuda de la fase 18: **queda registrado quién vio qué**, y la pregunta del incidente de
      marzo —¿qué consultó ese traductor en dos años?— tiene respuesta para adelante.
- [ ] Están definidas las **tres alertas** que valen la pena, con su justificación de por qué esas y no otras.
- [ ] 💸 Todo se exporta **sin muestreo**, declarado, con cobro en la fase 20 — donde el volumen se convierte
      en una línea de la factura.
- [ ] Ningún dato personal entra en un registro. Hay una prueba que lo verifica.
- [ ] La medición de la sección 6 está escrita con su comando, y la entrada quedó en `BENCHMARKS.md`.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **El costo de la telemetría** → fase 20, y es una de sus tres deudas cobradas.
- **El muestreo**, que es lo que controla ese costo → fase 20. Esta fase exporta todo a propósito, para poder
  medir cuánto es "todo".
- **Un panel para cada cosa.** Declarado fuera con su razón: **tres alertas y cuatro consultas guardadas
  valen más que veinte gráficas que nadie mira**, y un panel sin una pregunta detrás es la forma más caras de
  no observar nada.
- **Trazas distribuidas entre organizaciones.** Cordillera tiene un integrador —Almenara— y correlacionar con
  su sistema requiere que ellos también instrumenten. Fuera de alcance, y el ejercicio 24 explora qué se puede
  hacer sin su cooperación.
- **Perfilado de asignaciones y volcados de memoria.** Fuera con su razón: son herramientas de diagnóstico
  puntual, no de operación continua, y el curso ya usó el arnés de la fase 06 para lo que necesitaba.
- **Reemplazar el sistema heredado.** Esta fase lo **observa**; la fase 20 decide.

---

## 🧠 4. Concepto mínimo

### Las tres señales, y qué pregunta responde cada una

Se nombran juntas y se confunden todo el tiempo. Se distinguen mejor por la pregunta que contestan:

| Señal | Contesta | Forma | Costo |
|---|---|---|---|
| **Métricas** | *¿está pasando algo?* | números agregados en el tiempo | barato, constante |
| **Trazas** | *¿dónde se fue el tiempo?* | el recorrido de **una** petición | caro, proporcional al tráfico |
| **Registros** | *¿qué pasó exactamente?* | eventos con contexto | caro, y crece sin límite si nadie mira |

El error de operación más común es usar la señal equivocada: buscar en registros lo que una métrica ya
responde, o intentar deducir de una métrica agregada dónde se fue el tiempo de una petición. **Las tres son
necesarias y ninguna sustituye a otra**, y el instinto útil es: la métrica te despierta, la traza te lleva al
lugar, el registro te dice qué había ahí.

### OpenTelemetry, y por qué esto se parece tanto a lo que ya conoces

OpenTelemetry es un **estándar**, no un producto: define cómo se produce la telemetría y cómo se propaga el
contexto entre procesos, y deja abierto adónde se exporta. Eso significa que la instrumentación se escribe una
vez y el destino es una línea de configuración — Azure Monitor, Grafana, Jaeger, Prometheus, o un archivo en
disco mientras se desarrolla.

Y viene con la mejor noticia de la fase: **si usaste Micrometer, Sleuth o Brave, ya conoces esto**. Los
nombres cambian y los conceptos no: un *span* es un tramo, el contexto se propaga por cabeceras, y la
instrumentación automática cubre HTTP y base de datos sin que escribas nada.

Lo que .NET hace distinto, y conviene saberlo porque explica nombres raros en la documentación: **la API de
trazas de .NET es anterior a OpenTelemetry** y se llama `Activity`, del espacio `System.Diagnostics`. Cuando
OpenTelemetry se estandarizó, .NET no creó una API paralela: **mapeó la que ya tenía**. Así que un `Activity`
*es* un span, y `ActivitySource` es lo que OpenTelemetry llama un *tracer*. La consecuencia práctica es buena:
la instrumentación del propio marco —ASP.NET Core, `HttpClient`, EF Core— ya emite `Activity`, y activar
OpenTelemetry es **suscribirse a lo que ya se estaba produciendo**.

> 🧠 **El modelo mental de la fase, y es todo lo que hace falta:** una traza es un **árbol de tramos**. Cada
> tramo tiene un padre, una duración y unos atributos. El contexto del padre viaja al hijo — dentro del proceso
> por un `AsyncLocal`, entre procesos por una cabecera HTTP (`traceparent`), y hacia donde no hay estándar
> **por donde tú lo pongas**. El borde 🧬 es exactamente eso: un sitio donde no hay estándar y hay que ponerlo
> a mano.

### Cruzar el borde 🧬, que es el material de esta fase

La instrumentación automática de EF Core te da un tramo por consulta: el SQL, la duración, el resultado. Para
el catálogo moderno eso alcanza.

Y para `SP_CATALOGO` no alcanza, porque el tramo dice *"se ejecutó `EXEC SP_CATALOGO @ANIO=2026`, tardó 3.800
ms"* y ahí se detiene. El procedimiento tiene 340 líneas, un cursor, cuatro tablas y una lectura de
`VENTAS_2026`, y la traza no ve nada de eso. Sabes que el problema está adentro, y no dónde.

Hay tres maneras de pasar el borde, y las tres son legítimas en distintas situaciones:

**Primera, y es la que esta fase usa: instrumentar el procedimiento con eventos de SQL Server.** Los eventos
extendidos (*Extended Events*) capturan lo que pasa dentro del motor —cada instrucción, su duración, su plan— y
se pueden correlacionar con la traza si el identificador viaja hasta allí. Cómo hacerlo viajar es el truco de
la sección 5.2.

**Segunda: envolver el procedimiento en tramos manuales.** Si se puede modificar —y `SP_CATALOGO` se puede,
con cuidado— se le agregan marcas que emiten eventos con el identificador recibido. Es invasivo en código de
1997, y el curso lo hace en **uno** para mostrar el patrón, no en los once.

**Tercera, y hay que nombrarla porque a veces es la respuesta: no cruzar el borde y medir por fuera.** Si el
procedimiento tarda 3.800 ms de forma consistente y la decisión ya está tomada —se reescribe o se deja
quieto—, instrumentarlo por dentro es trabajo que no cambia ninguna decisión. El ejercicio 20 pide justificar
cuál de las tres corresponde.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**Primera: registrar todo por si acaso.**

```text
❌ El razonamiento, y viene de una experiencia real:
   "El almacenamiento es barato y el registro que no escribiste es el que vas a necesitar.
    Registro en INFO todo lo que pase y ya después filtro."
```

**Por qué falla:** por dos razones de distinto tamaño. La menor es el costo, y la fase 20 le pone número —la
telemetría es una línea de factura con el mismo mecanismo de crecimiento que un `SELECT *`—. La mayor es que
**un registro que nadie lee no es observabilidad: es basura con fecha**. Buscar en ochenta millones de líneas
de `INFO` para encontrar las tres que importan es el problema que la observabilidad venía a resolver.

Y hay una tercera razón que es específica de esta fase: **registrar todo es la forma más fácil de filtrar
datos personales**. El correo de un cliente, el nombre de un autor, el pago de un traductor — todo eso pasa
por un registro estructurado si nadie decidió qué **no** registrar. Es la trampa del miniproyecto.

```text
✅ Lo que el ecosistema espera en su lugar:
   Métricas para saber que algo pasa. Trazas para saber dónde. Registros para el
   contexto puntual, con nivel adecuado y sin datos personales. Y el identificador de
   traza en cada línea, que es lo que conecta las tres.
```

**Segunda: instrumentar solo lo nuevo.**

Es el reflejo natural: el proyecto nuevo se instrumenta porque es donde estás trabajando, y el sistema
heredado se deja. El resultado es una traza preciosa del 20% del tiempo y un muro donde está el 80% — y lleva
a la conclusión falsa de que el código moderno es el problema, porque es el único que se ve.

**Dónde se rompe el paralelo con lo que traes:** en el mundo de Java la propagación de contexto entre servicios
es casi automática, porque todos los servicios son tuyos y todos usan el mismo agente. Aquí **hay un borde
donde la instrumentación automática se termina**, y pasar al otro lado es trabajo manual y deliberado. No hay
agente que lo haga por ti.

> ⚰️ **Autopsia del anti-patrón: el registro que dice "algo falló".**
>
> **El caso, y está en el código de la fase 17 tal como salió:**
>
> ```csharp
> catch (Exception ex)
> {
>     _logger.LogError("Error procesando la liquidación");   // ← ni el identificador, ni la excepción
> }
> ```
>
> **Lo que cuesta:** el cierre de septiembre falla para tres contratos de 1.200. El registro tiene tres líneas
> idénticas que dicen "Error procesando la liquidación", sin el contrato, sin la excepción, sin la traza. Duván
> tiene que **reproducir el cierre completo en un entorno de prueba** para saber cuáles fueron — cuarenta
> minutos de ejecución y una tarde de trabajo.
>
> **Con el registro estructurado correcto**, la respuesta es una consulta de veinte segundos: los tres
> identificadores de contrato, la excepción y el tramo exacto donde reventó.
>
> **La diferencia medida:** una tarde contra veinte segundos. Y la lección no es "registra más": es **registra
> lo que te deja encontrar el caso concreto**, que es una cosa distinta y casi siempre más corta.
>
> **La defensa:** el registro estructurado con el objeto —no con el mensaje interpolado— y una regla de
> revisión: *un `catch` que registra sin el identificador de la entidad no pasa*.

### 🩻 Esto sí funciona igual

Prácticamente todo el criterio de operación, y eso hace esta fase más corta de lo que parece.

Los niveles de registro son los mismos y significan lo mismo. El registro estructurado con parámetros en vez
de interpolación es el mismo patrón que ya usas, con la misma razón. Los percentiles como forma correcta de
medir latencia —y el promedio como forma engañosa— son idénticos. Y el criterio de qué merece una alerta
—síntomas que el usuario nota, no causas internas— se transfiere completo.

También se transfiere la inyección del registrador, que en .NET es la misma idea con otro nombre, y el
concepto de ámbito de registro —`LogContext`, `MDC`— existe con el mismo propósito.

Y una que ahorra tiempo: **`ILogger<T>` se comporta como un SLF4J que ya viene configurado**. No hay que elegir
implementación ni pelear con dos bibliotecas de fachada.

### 📖 Diccionario de traducción

| Java | .NET | Dónde se rompe el paralelo |
|---|---|---|
| SLF4J + Logback | `ILogger<T>` + proveedores | Equivalente, y ya viene en el marco. No hay guerra de fachadas |
| MDC | `ILogger.BeginScope` | Mismo propósito. En .NET el identificador de traza se agrega solo |
| Micrometer | `System.Diagnostics.Metrics` (`Meter`) | Mismo modelo: contadores, histogramas, medidores |
| Spring Sleuth / Brave | `ActivitySource` + `Activity` | **`Activity` es anterior a OpenTelemetry** y se mapeó a él: un `Activity` *es* un span |
| `@NewSpan` | `ActivitySource.StartActivity` | En .NET es explícito, sin anotación. Más ruido y menos magia |
| `traceId` / `spanId` | `Activity.TraceId` / `SpanId` | Idénticos, y el formato del W3C es el mismo en los dos mundos |
| Actuator `/health` | `AddHealthChecks` + `/health` | Mismo concepto. Ojo: exponer **qué** está mal es información para un atacante |
| JMX | `dotnet-counters` + `EventCounters` | Sin consola gráfica equivalente. La herramienta es de línea de comandos |
| agente de APM que instrumenta sin tocar código | instrumentación automática de OTel | Cubre HTTP, `HttpClient` y EF Core. **Termina en el borde 🧬** |
| propagación entre servicios por cabeceras | la misma, `traceparent` del W3C | Igual — y **no hay estándar hacia un procedimiento de 1997**: eso es artesanía |

> ⚠️ **La fila de `/health` decide un incidente de seguridad.** Un chequeo de salud que responde *"la base de
> datos SIGE no responde en 10.12.4.7:1433"* le está dando a un atacante el nombre del servidor y su puerto. El
> chequeo público dice **sano o no sano**; el detallado va detrás de autenticación. Es el mismo razonamiento de
> la fase 16 aplicado a un endpoint que casi nadie revisa.

> 📝 **Nota de ecosistema.** Antes de OpenTelemetry, .NET tenía Application Insights con su SDK propio, y
> mucho material que vas a encontrar lo usa. Desde .NET 8 el camino recomendado es OpenTelemetry exportando a
> donde sea, y Azure Monitor es un exportador más. **No mezcles los dos**: instrumentar con el SDK viejo y con
> OTel a la vez produce trazas duplicadas y una factura doble. Si heredas código con el SDK viejo, migra antes
> de agregar.

---

## 💻 5. Código mínimo con comentarios

### 5.1 El montaje, que es corto

```csharp
// src/modern/Cordillera.Catalog.Api/Program.cs
//
// Las tres señales en un bloque. Y la decisión que importa está en el exportador: la instrumentación
// se escribe una vez y el destino es configuración. Eso permite desarrollar contra la consola y
// producir contra Azure Monitor sin tocar una línea de instrumentación.
builder.Services.AddOpenTelemetry()
    .ConfigureResource(resource => resource
        // El nombre del servicio es lo que distingue las cuatro cosas en producción. Sin esto, todas
        // las trazas se ven iguales y la telemetría es peor que no tenerla.
        .AddService(serviceName: "cordillera-catalogo-api", serviceVersion: ThisAssembly.Version))
    .WithTracing(tracing => tracing
        .AddAspNetCoreInstrumentation()          // la petición entrante
        .AddHttpClientInstrumentation()          // las llamadas salientes (Almenara)
        .AddSqlClientInstrumentation(options =>
        {
            // Sin esto el tramo de SQL no dice qué se ejecutó, y entonces no sirve. Y con esto hay que
            // mirar dos veces: el texto del comando puede llevar parámetros con datos personales.
            // La fase lo activa y el ejercicio 5 pide revisar qué queda expuesto.
            options.SetDbStatementForText = true;
        })
        .AddSource(CordilleraTelemetry.ActivitySourceName)   // los tramos propios, incluido el borde
        .AddOtlpExporter())
    .WithMetrics(metrics => metrics
        .AddAspNetCoreInstrumentation()
        .AddRuntimeInstrumentation()              // GC, hilos, excepciones: lo que la F06 midió a mano
        .AddMeter(CordilleraTelemetry.MeterName)
        .AddOtlpExporter());

// Los registros por el mismo camino, que es lo que hace que se puedan cruzar con las trazas.
builder.Logging.AddOpenTelemetry(logging =>
{
    logging.IncludeScopes = true;
    logging.AddOtlpExporter();
});

// 💸 Y falta algo, declarado: NO hay muestreo. Todo se exporta. Con el tráfico de Cordillera eso es
//    sostenible y hay que saber cuánto cuesta antes de decidir el muestreo — que es el argumento de
//    la fase 20 y la razón de dejarlo pendiente en vez de configurar un 10% a ojo.
```

**Detalles con intención**

- **El nombre del servicio no es decoración.** Con cuatro cosas en producción, una traza sin nombre de servicio
  es una traza que no se puede filtrar, y el panel se vuelve inútil el primer día.
- **`SetDbStatementForText = true` es necesario y es un riesgo.** Sin él, los tramos de SQL no dicen qué se
  ejecutó; con él, el texto del comando viaja al exportador y puede llevar un correo en un parámetro. Activarlo
  y no revisarlo es cómo se filtran datos sin querer.
- **`AddRuntimeInstrumentation` da gratis lo que la fase 06 midió a mano**: colecciones de GC, hilos,
  excepciones. La diferencia es que ahora es continuo y en producción.
- **No hay muestreo, a propósito.** Es la deuda declarada, y la razón de no configurar un 10% arbitrario es que
  el número correcto sale de medir el volumen — que es lo que la fase 20 hace.

### 5.2 El borde 🧬, que es el material de la fase

```csharp
// src/modern/Cordillera.Data/LegacyProcedureTracing.cs
//
// Lo que sigue es el único sitio del curso donde hay que inventar el mecanismo, porque no hay
// estándar. El objetivo es que la traza no se detenga en "EXEC SP_CATALOGO tardó 3.800 ms".
namespace Cordillera.Data;

public static class CordilleraTelemetry
{
    public const string ActivitySourceName = "Cordillera.Legacy";
    public const string MeterName = "Cordillera.Catalog";

    public static readonly ActivitySource Source = new(ActivitySourceName);
}

public sealed class TracedProcedureRunner(SqlConnection connection)
{
    /// <summary>
    /// Ejecuta un procedimiento del sistema heredado dejando rastro **de los dos lados del borde**.
    /// </summary>
    public async Task<T> ExecuteAsync<T>(
        string procedureName,
        Func<SqlCommand, Task<T>> read,
        Action<SqlCommand> bindParameters,
        CancellationToken token)
    {
        // El tramo propio, con el nombre del procedimiento. Esto ya da una mejora: la traza distingue
        // "el tiempo del procedimiento" del "tiempo de EF Core", que antes se confundían.
        using Activity? activity = CordilleraTelemetry.Source.StartActivity(
            $"legacy.{procedureName}", ActivityKind.Client);

        // 🧬 Y aquí está el cruce. El identificador de la traza tiene que llegar al motor de base de
        //    datos de un modo que los eventos extendidos puedan capturar, y no hay una vía diseñada
        //    para eso. La que funciona: el nombre de la aplicación en la cadena de conexión viaja al
        //    motor y aparece en cada evento. Se fija por sesión, antes de ejecutar.
        //
        //    Es artesanal y hay que decirlo. Ninguna documentación lo recomienda porque no es un
        //    mecanismo pensado para esto; es el que existe.
        string? traceId = activity?.TraceId.ToString();

        activity?.SetTag("legacy.procedure", procedureName);
        activity?.SetTag("legacy.generation", "1997");   // ← para poder agrupar el costo del borde

        using SqlCommand command = connection.CreateCommand();
        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = procedureName;
        bindParameters(command);

        // El contexto de sesión: SQL Server lo guarda por conexión y los eventos extendidos lo pueden
        // leer. Es la vía limpia cuando el motor la soporta, y la que esta fase usa.
        if (traceId is not null)
        {
            using SqlCommand setContext = connection.CreateCommand();
            setContext.CommandText = "EXEC sp_set_session_context @key = N'trace_id', @value = @t";
            setContext.Parameters.AddWithValue("@t", traceId);
            await setContext.ExecuteNonQueryAsync(token);
        }

        try
        {
            return await read(command);
        }
        catch (SqlException ex)
        {
            // El tramo tiene que registrar el fallo, o la traza muestra una operación que "terminó".
            activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
            activity?.SetTag("legacy.sql_error_number", ex.Number);
            throw;
        }
    }
}
```

**Detalles con intención**

- **`sp_set_session_context` es el mecanismo menos malo**, y hay que decir que es artesanía: guarda un valor
  por conexión que los eventos extendidos pueden leer, y así cada instrucción del procedimiento queda
  correlacionada con la traza que la originó. **Ninguna documentación lo presenta como patrón de
  observabilidad** porque no fue diseñado para eso.
- **Cuesta un viaje de ida y vuelta más**, y eso hay que medirlo: la sección 6 incluye el sobrecosto de
  instrumentar. Una observabilidad que hace la consulta más lenta tiene que justificar el precio.
- **La etiqueta `legacy.generation` parece decorativa y es la más útil**: permite preguntarle al panel *¿cuánto
  del tiempo total de Cordillera se va del otro lado del borde?* Ese número es un argumento de presupuesto, y
  la fase 20 lo usa.
- **El `catch` marca el tramo como fallido.** Sin eso, una traza con excepción se ve como una operación exitosa
  y rápida, que es la peor clase de dato erróneo.

```sql
-- src/legacy/Sige.Database/observabilidad/xe-procedimientos.sql
--
-- Los eventos extendidos que capturan lo que pasa DENTRO del procedimiento. Con el contexto de
-- sesión leído como acción, cada instrucción queda pegada a su traza.
--
-- ⚠️ Esto corre en el motor y tiene costo. La sesión se activa para diagnosticar y se apaga; dejarla
--    prendida todo el tiempo es una de las decisiones que la fase 20 tiene que costear.
CREATE EVENT SESSION [cordillera_legacy] ON SERVER
ADD EVENT sqlserver.sp_statement_completed (
    ACTION (sqlserver.session_context, sqlserver.sql_text, sqlserver.database_name)
    WHERE duration > 100000   -- microsegundos: solo instrucciones de más de 100 ms
)
ADD TARGET package0.event_file (SET filename = N'cordillera_legacy.xel', max_file_size = 64);
GO
```

### 5.3 La deuda de la fase 18: quién vio qué

```csharp
// src/modern/Cordillera.Redaccion.Web/Auditoria/AccessAuditMiddleware.cs
//
// 💸 PAGADA: la deuda de la fase 18. Redacción registraba quién CAMBIÓ qué y no quién VIO qué, y la
//    pregunta del incidente de marzo —¿qué consultó ese traductor en dos años?— no tenía respuesta.
//
//    Y aquí se ve por qué se aplazó hasta esta fase en vez de hacerlo a mano: con la telemetría
//    montada, la auditoría de acceso es un middleware de veinte líneas que se apoya en la traza que
//    ya existe. Hacerlo en la fase 18 habría sido construir la mitad de un sistema de trazas.
namespace Cordillera.Redaccion.Web.Auditoria;

public sealed class AccessAuditMiddleware(RequestDelegate next, ILogger<AccessAuditMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        await next(context);

        // Solo los recursos sensibles. Auditar todo sería el anti-patrón de la sección 4 con otro
        // nombre, y además haría imposible encontrar el acceso que importa.
        if (!IsAuditable(context.Request.Path))
        {
            return;
        }

        // Registro estructurado: los campos son campos, no texto interpolado. Eso es lo que permite
        // preguntar "todo lo que vio el usuario X entre enero y diciembre" en una consulta y no en un
        // script de expresiones regulares.
        //
        // Y nótese lo que NO está aquí: ni el nombre del autor, ni el título del manuscrito, ni el
        // monto del contrato. La auditoría registra QUÉ RECURSO se vio, no su contenido. El ejercicio
        // 8 pide justificar esa línea, que es más fina de lo que parece.
        logger.LogInformation(
            "Acceso a recurso sensible {ResourceKind} {ResourceId} por {SubjectId} desde {Office}",
            ClassifyResource(context.Request.Path),
            ExtractResourceId(context.Request.Path),
            context.User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "anonimo",
            ResolveOffice(context));

        // El identificador de traza se agrega automáticamente, así que desde este registro se puede
        // saltar a la traza completa de esa petición. Es lo que hace la auditoría investigable en vez
        // de solo archivable.
    }

    private static bool IsAuditable(PathString path) =>
        path.StartsWithSegments("/contratos") ||
        path.StartsWithSegments("/liquidaciones") ||
        path.StartsWithSegments("/manuscritos");
}
```

**El patrón a memorizar**

> **Un registro de auditoría anota qué recurso se vio, nunca su contenido.** La diferencia parece sutil y es la
> que separa una auditoría de una filtración: un registro que dice *"el usuario 41 vio el contrato 8823"* es
> auditoría; uno que dice *"el usuario 41 vio el contrato de Ximena Roldán por 18 millones"* es una copia de
> los datos sensibles en un sistema con menos controles que el original — y con retención más larga.

### 5.4 Las métricas que valen, y las alertas que salen de ellas

```csharp
// src/modern/Cordillera.Catalog.Api/Telemetria/CatalogMetrics.cs
//
// Tres métricas. La tentación es veinte, y veinte métricas que nadie mira cuestan lo mismo que
// veinte que sí — con la diferencia de que ninguna dispara nada.
public sealed class CatalogMetrics
{
    private readonly Histogram<double> _queryDuration;
    private readonly Counter<long> _legacyFallbacks;
    private readonly Histogram<double> _legacyProcedureDuration;

    public CatalogMetrics(IMeterFactory factory)
    {
        Meter meter = factory.Create(CordilleraTelemetry.MeterName);

        // 1. Latencia de la consulta, en percentiles. Es el síntoma que Ximena nota.
        _queryDuration = meter.CreateHistogram<double>(
            "cordillera.catalog.query.duration", unit: "ms",
            description: "Duración de una consulta de catálogo, extremo a extremo");

        // 2. Cuántas veces se cayó al sistema heredado. Es la métrica del strangler fig de la F10, y
        //    es la que dice si la estrangulación avanza o si se estancó hace ocho meses.
        _legacyFallbacks = meter.CreateCounter<long>(
            "cordillera.legacy.fallback.count",
            description: "Peticiones servidas por el camino heredado");

        // 3. Y el tiempo del otro lado del borde, separado. Es el número que convierte "el catálogo
        //    está lento" en "SP_CATALOGO se lleva el 80% y hay que decidir qué hacer con él".
        _legacyProcedureDuration = meter.CreateHistogram<double>(
            "cordillera.legacy.procedure.duration", unit: "ms",
            description: "Duración de un procedimiento del sistema heredado");
    }
}
```

> 🧭 **Las tres alertas, y la razón de que sean tres.** Una alerta que suena y no se atiende entrena a la gente
> a ignorar las alertas, así que el criterio no es "qué podría ir mal" sino **"qué me haría levantarme a las
> dos de la mañana"**. Para Cordillera:
>
> 1. **El p95 del catálogo pasa de su umbral** — porque es el síntoma que el usuario nota, y Almenara tiene un
>    contrato.
> 2. **El cierre de regalías no terminó antes de las 6 a.m.** — porque a las 8 hay gente esperando el número, y
>    es la métrica de la fase 17.
> 3. **El camino heredado devuelve error** — porque es el único que no tiene alternativa: si el moderno falla,
>    cae al heredado; si el heredado falla, no hay dónde caer.
>
> Nótese que **ninguna de las tres es de infraestructura**. Ni CPU, ni memoria, ni espacio en disco. Esas son
> causas, y una alerta de causa suena cuando nada está mal todavía — que es exactamente cómo se entrena a la
> gente a ignorarlas.

**Prueba de fuego**

```powershell
dotnet run --project src\modern\Cordillera.Catalog.Api
# y con la consulta de los cuatro segundos, la traza entera:
curl "http://localhost:5080/catalogo?anio=2026"
```

Mira la traza y contesta **en qué tramo se fueron los cuatro segundos**. Si la respuesta es "en el tramo de
`SP_CATALOGO`, y dentro de él en la lectura de `VENTAS_2026`", la fase funcionó. Si la respuesta es "en
`SP_CATALOGO`" y ahí se acaba, el borde no se cruzó.

Y la mentira que te va a contar la salida si miras el lugar equivocado: **el tramo del API va a decir 4.100
ms y eso no acusa al API**. Un tramo padre incluye a sus hijos, así que el tiempo del API *contiene* el del
procedimiento. Leer el padre como si fuera tiempo propio es el error de lectura más común de una traza, y hace
culpar a la capa de arriba de lo que hizo la de abajo.

---

## 📏 6. Medición

**Hipótesis:** de los cuatro segundos de la consulta del catálogo, **la mayor parte está del otro lado del
borde 🧬** —dentro de `SP_CATALOGO`— y no en el código moderno. Y una segunda hipótesis, que es la que decide
si esta fase es sostenible: **instrumentar cuesta menos del 5% de latencia**, con el viaje extra de
`sp_set_session_context` incluido.

**Condiciones:** SDK 10.0.401 · Release · Windows 11 · la consulta `/catalogo?anio=2026` contra la base del
generador con semilla `19970417` · exportador OTLP a un recolector local, **sin muestreo** · 30 repeticiones
con 3 de calentamiento descartadas · sesión de eventos extendidos activa en el motor, con su propio costo
medido aparte · arnés propio.

**Competidores:** cuatro configuraciones — sin instrumentación, con instrumentación automática solamente, con
el cruce del borde, y con el cruce más los eventos extendidos activos.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 19 --escenario catalogo-2026
```

**Resultado:** ⏳ pendiente de ejecución en tu máquina.

**A · El reparto de los cuatro segundos** — la pregunta que nadie podía contestar:

| Tramo | Duración (mediana) | % del total | ¿Qué generación? |
|---|---|---|---|
| API, trabajo propio (validación, serialización) | ⏳ | ⏳ | moderna |
| EF Core, consultas del catálogo moderno | ⏳ | ⏳ | moderna |
| `SP_CATALOGO`, total | ⏳ | ⏳ | **1997** 🧬 |
| ├─ cursor sobre `TITULOS` | ⏳ | ⏳ | 1997 |
| ├─ lectura de `VENTAS_2026` | ⏳ | ⏳ | 1997 |
| └─ resto del procedimiento | ⏳ | ⏳ | 1997 |
| Red hacia la base en Azure | ⏳ | ⏳ | — |

**B · Lo que cuesta instrumentar**

| Configuración | p50 | p95 | Sobrecosto vs. sin instrumentar | Volumen exportado por hora |
|---|---|---|---|---|
| Sin instrumentación | ⏳ | ⏳ | — | 0 |
| Automática (HTTP + SQL) | ⏳ | ⏳ | ⏳ | ⏳ |
| + cruce del borde 🧬 | ⏳ | ⏳ | ⏳ | ⏳ |
| + eventos extendidos activos | ⏳ | ⏳ | ⏳ | ⏳ |

> ⚖️ **Veredicto** *(expectativa, todavía sin ejecutar — `formato-de-mediciones.md` §2.6)*. Se espera que la
> tabla A muestre **la mayor parte del tiempo dentro del procedimiento de 1997**, y que el trabajo propio del
> API sea una fracción pequeña — lo cual convierte "el catálogo está lento" en una decisión sobre
> `SP_CATALOGO` y no en una optimización de C#. Se espera que la instrumentación automática sea prácticamente
> gratis, que el cruce del borde cueste un viaje de ida y vuelta visible pero pequeño, y que **los eventos
> extendidos sean el único componente con costo serio** — razón por la cual se activan para diagnosticar y se
> apagan.
>
> **Los tres umbrales que tu ejecución tiene que determinar:** (1) **qué porcentaje del total se va del otro
> lado del borde**, que es el número que decide el presupuesto de la fase 20 y probablemente el destino de
> `SP_CATALOGO`; (2) **cuánto cuesta el viaje extra de `sp_set_session_context`**, y si vale la pena dejarlo
> permanente o solo bajo bandera; y (3) **cuánto volumen genera una hora sin muestreo**, que es directamente
> una línea de la factura de la fase 20 y el dato con el que se elige el porcentaje de muestreo — en vez de
> poner 10% porque suena razonable.
>
> 📝 Y una advertencia de lectura que vale para cualquier traza: **un tramo padre incluye el tiempo de sus
> hijos**. La fila del API no dice "el API tardó eso"; dice "todo lo que pasó dentro de la petición tardó eso".
> Calcular el trabajo propio de una capa es restar a sus hijos, y olvidarlo es cómo se culpa a la capa
> equivocada.

---

## 🧱 7. Miniproyecto — encontrar los cuatro segundos

**El encargo**

De Duván, y es un correo que suena a rendición:

> *"Ximena dice que el catálogo está lento. Yo lo abro y me responde. Le pedí que me dijera qué consulta y me
> dijo 'todas'. Ya le puse un índice a `TITULOS` la semana pasada porque me pareció que era eso, y no cambió
> nada — o sí cambió y no sé cómo saberlo.*
>
> *Necesito poder decir 'son tantos segundos y están acá'. No necesito arreglarlo esta semana. Necesito saber
> dónde está, porque llevo tres semanas cambiando cosas al azar."*

**Por qué duele**

Porque el problema de Duván no es técnico: es que **no tiene evidencia**, y sin evidencia la optimización es
superstición. Puso un índice por intuición y no puede saber si sirvió — que es peor que no haberlo puesto,
porque ahora hay un índice más que mantener sin razón conocida.

Y duele porque el tramo interesante está en código que él no escribió, en un lenguaje que no es el del curso,
en un procedimiento que nadie quiere abrir. La instrumentación automática lo lleva hasta la puerta y ahí lo
deja.

**Datos de entrada**

| Qué | Detalle |
|---|---|
| La consulta lenta | `/catalogo?anio=2026`, ~4 s según Ximena |
| Lo que pasa por debajo | API → EF Core (catálogo moderno) → `SP_CATALOGO` (1997, 340 líneas, un cursor) |
| Base | Azure SQL, con la latencia de red que eso implica |
| Volumen | `VENTAS_2026` con las filas del generador, semilla `19970417` |
| Cosas en producción | 4: catálogo, cierre de regalías, Redacción, escritorio |
| Lo que Duván ya hizo | Un índice en `TITULOS`, por intuición, sin medir antes ni después |
| El incidente de marzo | Traductor externo con acceso a contratos por dos años; nadie sabe qué vio |

**Criterios de aceptación**

1. La traza de la consulta lenta está completa y **cruza el borde 🧬**: se ve el tiempo dentro de
   `SP_CATALOGO`, desglosado por instrucción.
2. **Los cuatro segundos tienen un reparto con números** (tabla A de la sección 6) y un responsable
   identificado con evidencia.
3. Está contestada la pregunta que Duván no podía contestar: **¿sirvió el índice de `TITULOS`?** Con medición
   antes y después, o con la explicación de por qué no podía servir.
4. Los registros son estructurados, llevan el identificador de traza, y **se puede pasar de un registro a su
   traza** en el recolector.
5. La liquidación de la fase 17 tiene su traza completa, y **se ve dónde reintentó**.
6. 💸 **La deuda de la fase 18 está pagada**: queda registrado quién vio qué en los recursos sensibles. Y está
   escrito qué respondería hoy la pregunta del traductor —para adelante—, y qué **no** puede responder hacia
   atrás.
7. Las **tres alertas** están definidas con su umbral y su justificación, y está escrito por qué **no** hay una
   alerta de CPU.
8. **Ningún dato personal en los registros**, con una prueba que lo verifica.
9. **Medición de cierre:** las dos tablas de la sección 6. Van en el mensaje del tag `mini-19`.

**Restricciones de estilo y alcance**

Código nuevo. Sin muestreo —es la deuda declarada, y el volumen medido es insumo de la fase 20—. Sin paneles
más allá de lo que hace falta para contestar la pregunta. **Y el procedimiento de 1997 se puede modificar, con
cuidado, en uno solo**: el patrón importa, replicarlo en los once es trabajo sin aprendizaje.

**La trampa**

Vas a instrumentar bien, vas a ver la traza cruzar el borde, vas a encontrar los cuatro segundos, y vas a
sentir que la fase salió perfecta.

Y en el registro estructurado de la auditoría va a haber un correo electrónico. O un nombre de autor. O el
monto de un contrato. Porque el modo natural de registrar algo útil es registrar lo que tienes a mano, y lo que
tienes a mano es el objeto completo:

```csharp
logger.LogInformation("Manuscrito consultado {Manuscript}", manuscript);
// ← el objeto entero, serializado: el autor, su correo, su teléfono, el monto del anticipo.
```

Eso pasa la revisión de código porque **se ve bien**: es registro estructurado, tiene contexto, ayuda a
depurar. Y acabas con datos personales en un sistema de telemetría que tiene retención más larga, controles
más flojos y más gente con acceso que la base de datos original.

Cuando lo encuentres —y búscalo, porque no va a saltar— escribe dos cosas: **qué campos había que no debían
estar**, y **cómo lo impedirías de forma que no dependa de que alguien se acuerde**. La segunda es la que vale:
una regla que depende de la memoria de quien escribe el `catch` falla el día que hay prisa.

<details><summary>Pista 1 — el enfoque</summary>

Instrumenta en tres pasos y mide después de cada uno: primero la instrumentación automática, que es gratis y
ya te dice si el problema está dentro o fuera del procedimiento. Solo si está dentro vale la pena el segundo
paso —el cruce del borde— y solo si necesitas la instrucción exacta, el tercero.

Ese orden importa porque **puede que el primer paso resuelva el caso**. Si el tramo de SQL dice 200 ms y el
del API 3.900, el borde no es el problema y cruzarlo es trabajo desperdiciado.

Para el criterio 3 —el índice de Duván— la traza vieja no existe, así que hay que medir el estado actual y
razonar. Y hay una respuesta posible que es mejor que medir: mirar si el plan de `SP_CATALOGO` **puede** usar
ese índice. Un cursor sobre un `SELECT` sin `WHERE` no lo usa, y eso se responde sin ejecutar nada.

</details>

<details><summary>Pista 2 — la herramienta</summary>

Para el montaje y qué instrumentación automática existe:
`https://learn.microsoft.com/dotnet/core/diagnostics/observability-with-otel`

Para los tramos propios y la relación con OpenTelemetry:
`https://learn.microsoft.com/dotnet/core/diagnostics/distributed-tracing`

Para el contexto de sesión, que es la mitad del cruce del borde:
`https://learn.microsoft.com/sql/relational-databases/system-stored-procedures/sp-set-session-context-transact-sql`

Para los eventos extendidos y sus acciones:
`https://learn.microsoft.com/sql/relational-databases/extended-events/extended-events`

Y para la trampa: busca cómo redactar campos en el registro, y qué hace `ILogger` con un objeto que le pasas
como parámetro estructurado. La respuesta explica por qué la trampa es tan fácil de caer.

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```csharp
public static class CordilleraTelemetry
{
    public const string ActivitySourceName = "Cordillera.Legacy";
    public static readonly ActivitySource Source = new(ActivitySourceName);
}

// El cruce, que es el material de la fase.
public sealed class TracedProcedureRunner
{
    public Task<T> ExecuteAsync<T>(string procedureName, /* … */ CancellationToken token);
}

// La deuda de la F18 pagada.
public sealed class AccessAuditMiddleware { /* … */ }

// Y lo que impide la trampa sin depender de la memoria de nadie: un tipo que solo expone lo
// registrable, de modo que pasar el objeto completo no compile.
public readonly record struct AuditableResource(string Kind, string Id);
```

</details>

**Cómo se entrega**

```powershell
dotnet test src\Cordillera.slnx -c Release
dotnet run --project src\modern\Cordillera.Catalog.Api
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 19 --escenario catalogo-2026
```

```bash
git tag -a mini-19 -m "Mini F19: los 4 s repartidos con evidencia · SP_CATALOGO = <P>% del total · sobrecosto de instrumentar = <S>% · <V> MB/hora sin muestreo · deuda de auditoria de la F18 pagada"
```

---

## 🧪 8. Ejercicios (24)

**🟢 Fácil (1–6)**

1. Monta OpenTelemetry con las tres señales exportando a la consola. Mira una traza completa de una petición
   cualquiera y nombra sus tramos.
2. Agrega el nombre de servicio a las cuatro cosas en producción y comprueba que el recolector las distingue.
3. Convierte tres registros interpolados del código existente a registro estructurado. Anota qué se puede
   consultar ahora que antes no.
4. Comprueba que el identificador de traza aparece en cada línea de registro, y salta de un registro a su
   traza.
5. Con `SetDbStatementForText` activado, revisa qué queda expuesto en los tramos de SQL. Decide si algo hay
   que redactar.
6. Configura `/health` para que responda sano o no sano **sin** revelar qué componente falló, y un endpoint
   detallado detrás de autenticación.

**🟡 Intermedio (7–13)**

7. Instrumenta `SP_CATALOGO` con un tramo propio y comprueba que la traza distingue su tiempo del de EF Core.
8. Paga la deuda de la fase 18: el middleware de auditoría. Y justifica **dónde pusiste la línea** entre
   registrar el recurso y registrar su contenido.
9. Define las tres métricas de la sección 5.4 y construye una consulta que conteste *¿cuánto del tiempo total
   de Cordillera se va del otro lado del borde?*
10. Instrumenta el trabajo de fondo de la fase 17 para que una liquidación tenga su traza completa, incluidos
    los reintentos. El reto está en que el trabajo no nace de una petición HTTP: no hay contexto que propagar.
11. Define las tres alertas con sus umbrales y escribe la justificación de cada una. Y escribe por qué **no**
    hay una alerta de CPU.
12. Escribe la prueba que impide que un dato personal entre en un registro. Que falle si alguien registra el
    objeto completo.
13. Mide cuánto volumen genera una hora de telemetría sin muestreo. Es el insumo directo de la fase 20.

**🟠 Difícil (14–20)**

14. **Diagnóstico.** Una traza muestra el tramo del API en 4.100 ms y el de SQL en 3.800 ms. Alguien concluye
    que el API se lleva 4.100. Explica el error y calcula el trabajo propio de cada capa.
15. **Diagnóstico.** Las trazas del cierre de regalías aparecen como cientos de trazas separadas en vez de una
    con cientos de tramos. Explica qué pasó con la propagación de contexto y arréglalo.
16. **Medición.** Ejecuta la medición completa de la sección 6, las dos tablas, y determina los tres umbrales.
17. **Medición.** Cruza el borde con los eventos extendidos y desglosa `SP_CATALOGO` por instrucción. Reporta
    cuál se lleva el tiempo.
18. Contesta la pregunta de Duván: **¿sirvió el índice de `TITULOS`?** Con evidencia, y si la respuesta es que
    no podía servir, explica por qué se puede saber sin ejecutar nada.
19. **Decisión.** Con el reparto de la tabla A, decide qué se hace con `SP_CATALOGO`: se optimiza, se reescribe
    en C#, o se deja quieto. Sostén la decisión con el número, no con el gusto.
20. **Decisión — ¿se migra, se envuelve o se deja quieto?** Los once procedimientos almacenados, para efectos
    de observabilidad. Decide cuáles se instrumentan por dentro, cuáles se miden solo por fuera, y cuáles no
    se tocan. El criterio no puede ser "los importantes".

**🔴 Muy difícil (21–24)**

21. **Adversarial.** Consigue que la instrumentación haga la aplicación medible más lenta —más del 20%—.
    Explica el mecanismo y qué configuración lo produce. Es más fácil de lo que parece.
22. **Adversarial.** Filtra un dato personal a la telemetría de tres formas distintas, todas pasando una
    revisión de código razonable. Después escribe la defensa que las impide a las tres.
23. **Diseño.** La pregunta del incidente de marzo hacia atrás: ¿qué vio ese traductor en dos años? Escribe
    honestamente qué se puede reconstruir, con qué fuentes, y qué **no**. Y escribe qué le dirías a un auditor
    externo.
24. **Defiende una decisión ante quien no es ingeniera.** Escríbele a Ximena media página con el reparto de los
    cuatro segundos y la recomendación sobre `SP_CATALOGO`, sabiendo que la recomendación puede ser "esto se
    queda lento hasta que valga la pena arreglarlo" — y que eso también hay que saber defenderlo.

**🔥 Opcionales**

- Correlaciona la telemetría con el sistema de Almenara sin su cooperación. Documenta qué se puede lograr y qué
  no, y qué les pedirías si hubiera oportunidad.
- Instrumenta el escritorio de WinForms. Tiene su propia dificultad: no hay petición HTTP, la sesión dura ocho
  horas, y una traza de ocho horas no es una traza.
- Reconstruye la traza de una petición de hace un mes con lo que quedó almacenado. Anota qué se perdió y por
  qué — es el argumento de retención de la fase 20.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://learn.microsoft.com/dotnet/core/diagnostics/observability-with-otel` — el montaje y qué cubre la
  instrumentación automática.
- `https://learn.microsoft.com/dotnet/core/diagnostics/distributed-tracing` — `Activity`, `ActivitySource`, y
  cómo se mapean a OpenTelemetry. **Es la página que explica los nombres raros.**
- `https://opentelemetry.io/docs/concepts/signals/` — las tres señales y qué pregunta responde cada una, desde
  el estándar.
- `https://learn.microsoft.com/sql/relational-databases/system-stored-procedures/sp-set-session-context-transact-sql`
  — el mecanismo del cruce del borde, presentado para lo que fue diseñado, que no es esto.
- `https://learn.microsoft.com/sql/relational-databases/extended-events/extended-events` — lo que pasa dentro
  del motor.
- `https://learn.microsoft.com/dotnet/core/extensions/logging` — `ILogger`, niveles y ámbitos.
- `https://www.w3.org/TR/trace-context/` — el formato de `traceparent`, idéntico al de Java.

**Libros / artículos**

- *Observability Engineering* (Charity Majors, Liz Fong-Jones, George Miranda) — la distinción entre
  monitoreo y observabilidad, y por qué los paneles predefinidos no alcanzan. **Verifica la edición antes de
  citarla.**
- El capítulo de monitoreo del *SRE Book* de Google, disponible en línea, es la mejor fuente sobre qué merece
  una alerta. Es de donde sale el criterio de "síntomas y no causas" que la sección 5.4 usa.

> ⚠️ Verifica las URLs. Y la advertencia propia de esta fase: **casi todo el material de observabilidad asume
> que todo tu sistema está instrumentado**. Los tutoriales muestran tres microservicios modernos con trazas
> perfectas, y ninguno enseña qué hacer cuando el 80% del tiempo vive en código de 1997 al que no llega ningún
> agente. Eso hay que inventarlo, y la sección 5.2 es una propuesta, no una práctica estándar. Y del otro lado:
> el material de .NET anterior a 2023 usa el SDK viejo de Application Insights; **no lo mezcles con
> OpenTelemetry**, o tendrás trazas duplicadas y factura doble.

**Orden de lectura sugerido:** antes de escribir, la página de las tres señales de OpenTelemetry — diez minutos
y evitan el error de usar la señal equivocada—. Durante el miniproyecto, la de trazas distribuidas de .NET,
**antes** de pelear con `Activity`. Al cerrar, el capítulo de monitoreo del SRE Book: se lee muy distinto
cuando acabas de decidir tres alertas y sabes por qué no pusiste una de CPU.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Los cuatro segundos tienen dueño, y lo tienen **con evidencia**. Duván puede decir "son tantos y están acá", y
eso cambia la conversación con Ximena de una discusión de percepciones a una decisión sobre un procedimiento
concreto.

Y quedó demostrada la propiedad que hace esta fase distinta de cualquier tutorial de telemetría: **la
instrumentación automática se detiene exactamente donde está el problema**. El 80% del tiempo de Cordillera
vive del otro lado del borde 🧬, y cruzarlo no es configuración: es artesanía —`sp_set_session_context`,
eventos extendidos, un tramo propio— que ninguna documentación recomienda porque ninguna documentación
contempla un sistema de 1997 debajo de uno de 2026.

Se pagó la deuda de la fase 18, y se pagó bien: **con la telemetría montada, la auditoría de acceso son veinte
líneas**. Eso justifica retroactivamente haberla aplazado, y es el mejor ejemplo del curso de una deuda tomada
por secuencia y no por prisa. Aunque la respuesta a la pregunta del traductor solo existe **hacia adelante**, y
eso también hay que decirlo: la observabilidad no reconstruye lo que no se registró.

Y esta fase tomó una deuda deliberada: **no hay muestreo, todo se exporta**. La razón no es pereza — es que el
porcentaje correcto de muestreo sale de saber cuántos megabytes por hora produce "todo", y ese número ahora
existe.

La fase 20 es donde todo esto se convierte en dinero, y no es una metáfora. Es **la factura**: el costo del
almacenamiento en la nube, el costo de la telemetría que esta fase dejó sin muestreo, el costo del volcado
completo del catálogo que la fase 15 dejó sin paginar, y el costo de la cola en tabla de la fase 17. **Tres
atajos cómodos de tres fases distintas, pagados juntos y en un solo número.** Y la pregunta incómoda que la
20 tiene que contestar sin absolver a nadie: el traslado de 2020 a Azure salió **un 30% por encima** de lo que
costaba el centro de datos, y hay que entender exactamente por qué antes de proponer el siguiente movimiento.

> **La señal de que quedó bien:** *"Ximena dijo que el catálogo estaba lento y en cinco minutos le mandé el
> reparto de los cuatro segundos. Tres semanas de cambiar cosas al azar se acabaron en una tarde de
> instrumentar."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el miniproyecto corriendo y
> `git status` limpio:
>
> ```bash
> git tag -a fase-19 -m "F19 cerrada:
> - las tres senales con OpenTelemetry, y la pregunta que responde cada una
> - la traza CRUZA el borde: de la peticion HTTP a SP_CATALOGO, desglosado
> - los 4 s del catalogo con dueno identificado por evidencia
> - trabajo de fondo de la F17 instrumentado, con sus reintentos visibles
> - tres alertas justificadas, y la razon de que no haya una de CPU
> - deuda de la F18 PAGADA: queda registrado quien vio que
> - sin muestreo: deuda declarada con cobro en la F20"
> ```
>
> **Y la factura de la deuda que esta fase pagó:**
>
> ```bash
> git diff fase-18 fase-19 -- src/modern/Cordillera.Redaccion.Web/
> ```
>
> Es un diff pequeño, y eso es el argumento: la auditoría de acceso costó veinte líneas **porque la telemetría
> ya estaba**. Haberla escrito en la fase 18 habría costado diez veces más y se habría tirado aquí.

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura.*

- **`INSTINTOS.md`** — tres entradas en la familia *servicios, identidad y operación*: registrar todo por si
  acaso; instrumentar solo lo nuevo; y **leer el tramo padre como tiempo propio**, que es el error de lectura
  de trazas más común y el que hace culpar a la capa equivocada. El primero necesita la razón menos obvia
  —**registrar todo es la forma más fácil de filtrar datos personales**—, no solo la del costo.
- **`BENCHMARKS.md`** — entrada ⏳ *F19 · Dónde se van los cuatro segundos, y qué cuesta saberlo*, con dos
  tablas. La tabla A es distinta de todas las demás del curso: **no compara competidores, reparte un total**.
  Conviene anotarlo en las reglas de honestidad, porque es un formato nuevo y legítimo.
- **Deuda 💸 pagada:** la auditoría de acceso de la F18. En el libro de §7.1 vale la pena registrar el tipo de
  pago: **deuda que se abarató por esperar**. Es distinto de todos los demás pagos del curso y es el argumento
  de que el orden de las fases no es arbitrario.
- **Deuda 💸 plantada:** sin muestreo, cobro en F20. Con la razón: el porcentaje correcto sale del volumen
  medido, no de un valor por omisión.
- **Tipos nuevos para el congelamiento:** `CordilleraTelemetry`, `TracedProcedureRunner`,
  `AccessAuditMiddleware`, `AuditableResource`, `CatalogMetrics`. Y el directorio nuevo
  `src/legacy/Sige.Database/observabilidad/` con `xe-procedimientos.sql`.
- **Y una decisión de alcance que conviene declarar:** esta fase **modifica el sistema heredado** por primera
  vez desde la F11 —el contexto de sesión y la sesión de eventos extendidos—. No es una migración: es
  instrumentación. Vale la pena que el congelamiento diga que `Sige.Database` puede recibir archivos de
  observabilidad sin cambiar de estilo ni moverse a `modern/`.
- **Para la fase 20:** cuatro insumos directos — el volumen por hora sin muestreo, el costo de la sesión de
  eventos extendidos, el porcentaje del tiempo que vive del otro lado del borde (que es un argumento de
  presupuesto), y la retención de la telemetría, que el ejercicio 🔥 de reconstrucción deja planteada.
- **Para la fase 24:** el ejercicio 23 —qué vio el traductor en dos años— es el mejor material del curso sobre
  los límites de lo que la ingeniería puede arreglar después. Y el 19 puede terminar en "se deja quieto", que
  es un veredicto legítimo y poco practicado.
