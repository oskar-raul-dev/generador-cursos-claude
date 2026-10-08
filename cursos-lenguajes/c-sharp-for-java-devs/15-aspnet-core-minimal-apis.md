# 🌐 Fase 15 — ASP.NET Core: minimal APIs y contrato

> C# para desarrolladores Java senior · Fase 15 de 24 · Bloque D — servicios, datos y nube
> Depende de: 14 · Habilita: 16
> Estilo de esta fase: **nuevo** (.NET 10, C# 14)
> Proyecto que avanza: **CatalogAPI**. La fase 09 le dio su capa de datos; esta le da la cara pública que
> Grupo Almenara va a consumir.

---

## 🎯 1. Propósito

Hay un correo de cuatro líneas del área de compras de **Grupo Almenara** —la cadena minorista más grande de
México, el 14% de la facturación del grupo— y dice esto:

> *"Para la renovación del contrato de 2027 requerimos integración por API con SLA de disponibilidad
> publicado. Los volcados CSV nocturnos ya no son viables para nuestra operación. Agradecemos confirmar
> antes del 30 de noviembre."*

No fue una negociación. Fue un correo, y el comité entendió el mensaje. **Esta fase existe por eso**, y no
porque toque ver minimal APIs.

Lo que el lector ya sabe hacer —HTTP, REST, un endpoint— no se explica. Lo que esta fase enseña es lo único
que de verdad cuesta: **diseñar un contrato público que no filtre el esquema heredado**, porque un contrato
publicado a un socio que representa el 14% de la facturación **es permanente**, y el esquema al que está
atado tiene decisiones de 1997.

> 🧭 **La regla de la fase:** *un contrato público es la única parte del sistema que no se puede refactorizar.*
> Todo lo demás —el esquema, el borde, el runtime, el cliente— el curso lo movió. Esto, una vez publicado, se
> mantiene o se versiona, y las dos cosas cuestan.

---

## ✅ 2. Qué queda listo al terminar

- [ ] `Cordillera.Catalog.Api` expone el catálogo con un contrato **que Almenara podría consumir de verdad**:
      OpenAPI publicado, versionado, paginación, filtrado y errores como respuesta.
- [ ] **Ni un nombre del esquema heredado aparece en el contrato.** Una búsqueda por `CODEDIT`, `VLRUNIT` o
      `BORRADO` en la especificación de OpenAPI devuelve cero resultados.
- [ ] Los DTO son **tipos propios del contrato**, distintos de las entidades, y hay una prueba que falla si
      alguien devuelve una entidad de EF Core directamente.
- [ ] La validación está **en el borde**: una petición mal formada no llega al dominio, y la respuesta de
      error tiene un formato estándar y documentado.
- [ ] El versionado está decidido y **escrito con su política de retiro**: cuánto vive una versión y cómo se
      anuncia su fin.
- [ ] 💸 **Se cobra la deuda de la fase 13**: el total y el conteo de huérfanos salen del modelo de vista y
      pasan a un servicio de aplicación que las dos interfaces —escritorio y API— consumen.
- [ ] 💸 El endpoint de catálogo **sale sin paginación en su primera versión**, declarado, con cobro en la
      fase 20 y en pesos.
- [ ] La medición de la sección 6 está escrita con su comando, y la entrada quedó en `BENCHMARKS.md`.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Autenticación y autorización** → fase 16. Los endpoints de esta fase son internos o anónimos, y eso está
  marcado en el código: publicar un catálogo sin autenticación es una decisión de la 16, no un olvido de la 15.
- **Despliegue, contenedor y el SLA de verdad** → fase 20. El correo de Almenara pide un SLA publicado, y
  **un SLA sin medición ni despliegue es una promesa**: la 19 lo instrumenta y la 20 lo costea.
- **Caché.** Aplazada desde la fase 09 a propósito y sigue fuera: es la respuesta fácil a la mitad de los
  números de esta fase, y primero hay que saber cuánto cuesta el camino sin ella.
- **Webhooks de cambio de precio y disponibilidad.** El correo de Almenara los va a pedir tarde o temprano y
  son trabajo de fondo → fase 17.
- **gRPC.** Fuera, con su razón: el consumidor es un socio comercial con su propio equipo y su propio
  calendario, y un contrato HTTP con OpenAPI es lo que puede consumir sin depender de nuestras herramientas.

---

## 🧠 4. Concepto mínimo

### El contrato es el producto

Esta es la idea que ordena la fase, y es la que separa un endpoint de una API.

Cuando publicas un endpoint que un tercero consume, dejas de ser dueño de esa forma. Almenara va a escribir
código contra tu respuesta, ese código va a entrar en su ciclo de pruebas, y va a estar en producción de su
lado. A partir de ese momento **cualquier cambio incompatible es un proyecto conjunto con otra empresa**, con
su calendario y su negociación.

De ahí salen tres consecuencias concretas:

**El contrato no puede filtrar el esquema.** Si la respuesta trae un campo `CODEDIT`, el nombre de una
decisión de 1997 queda escrito en el código de un tercero — y el día que el curso quiera renombrar esa
columna, el costo incluye a Almenara. **El borde 🧬 de la fase 09 protegía el dominio del esquema; el DTO de
esta fase protege al mundo del dominio.** Son dos bordes y hacen falta los dos.

**Los errores son parte del contrato.** Qué código HTTP, qué cuerpo, qué campos: eso se diseña y se
documenta, igual que los datos. Un `500` con una traza de pila no es un error de implementación: es un
contrato mal diseñado, porque el consumidor no puede programar contra él.

**Lo que se publica, se mantiene.** Y por tanto lo que no está listo **no se publica todavía**. Es la
decisión más difícil de la fase, porque la presión de mostrar algo el 30 de noviembre empuja a lo contrario.

> 🧠 **El modelo mental:** el DTO no es un mapeo de la entidad con otro nombre — es **una decisión sobre qué
> le prometes al mundo**. Si se genera automáticamente desde la entidad, no decidiste nada: dejaste que el
> esquema decidiera, y el esquema es de 1997.

### Minimal APIs y controladores, sin volverlo el tema

Las dos formas existen, las dos son idiomáticas, y la fase las mide porque el curso mide. Pero conviene decir
en una línea qué las diferencia de verdad: **un endpoint de minimal API es una función registrada en una
ruta; un controlador es una clase con convenciones**. Lo primero produce menos ceremonia y una unidad más
pequeña; lo segundo agrupa endpoints relacionados y trae filtros y convenciones que a cierta escala ahorran
repetición.

Para un servicio con doce endpoints —el caso de CatalogAPI— la diferencia es de estilo. Para uno con
doscientos, las convenciones empiezan a pagar. Ese es todo el asunto, y el número de la sección 6 dice si
además hay diferencia de rendimiento.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**Primera, y es la que Almenara va a heredar: devolver la entidad del ORM directamente.**

```csharp
// ❌ Funciona. Se escribe en un minuto. Y ata el esquema de 1997 al contrato público para siempre.
app.MapGet("/editions/{id}", async (string id, SigeContext db, CancellationToken token) =>
    await db.Editions.FindAsync([new EditionId(id)], token));
```

Lo que Almenara recibe:

```json
{
  "id": { "value": "ED00001234" },
  "titleId": { "value": "TI00000042" },
  "isbn": { "value": "9789583012345" },
  "isbnStatus": 0,
  "format": 1,
  "listPrice": { "amount": 68000.00 },
  "imprint": 2,
  "status": 2,
  "isDeleted": false
}
```

**Cinco problemas, y ninguno es de rendimiento:**

1. **`isbnStatus`, `format`, `imprint` y `status` son números.** Son `enum` serializados por su valor, así
   que Almenara va a escribir `if (format == 1)` en su código — y el día que alguien agregue un formato en
   medio del `enum`, los números cambian de significado y **nadie se enterará hasta que un pedido salga mal**.
2. **`isDeleted` no es asunto de Almenara.** Es la bandera `BORRADO` de FoxPro, filtrada por el borde de la
   fase 09, y aquí se vuelve a filtrar hacia afuera.
3. **Los identificadores salen envueltos** (`{"value": "..."}`) porque son `record struct` del dominio. Es
   una decisión interna filtrándose al contrato.
4. **`titleId` es un identificador interno** que Almenara no puede usar para nada, y sin embargo ahora lo
   conoce y alguien lo va a guardar en su base.
5. **Y lo peor: el contrato cambia cuando cambia la entidad.** Alguien agrega una propiedad al modelo de
   dominio en la fase 21 y **el contrato público cambia sin que nadie lo decida.**

```csharp
// ✅ El DTO como decisión. Cada campo está ahí porque alguien lo quiso, con el nombre y el tipo que
//    tiene sentido para quien lo consume — no para quien lo guarda.
public sealed record EditionResponse
{
    /// <summary>El ISBN-13, que es el identificador que el mundo editorial usa de verdad.</summary>
    public required string Isbn { get; init; }

    public required string Title { get; init; }

    /// <summary>El sello, por su nombre y no por su código de tres letras de 1997.</summary>
    public required string Imprint { get; init; }

    /// <summary>Formato, como cadena estable: "hardcover", "paperback", "ebook", "audiobook".</summary>
    public required string Format { get; init; }

    public required decimal ListPrice { get; init; }

    public required string Currency { get; init; }

    /// <summary>`true` si hay existencias en algún almacén. Es lo que Almenara pregunta de verdad.</summary>
    public required bool Available { get; init; }
}
```

**Por qué falla el reflejo:** porque en un servicio interno devolver la entidad es una simplificación
razonable y todo el mundo la ha hecho. Lo que cambia aquí es **quién está al otro lado**: un tercero con su
propio código en producción. Y el instinto de "ya lo arreglo en la v2" no aplica, porque la v2 con un socio
externo es una negociación, no un despliegue.

**Segunda: validar dentro del servicio.**

```csharp
// ❌ La validación adentro, que es donde estaba en el sistema de 2017 — y también donde la pone
//    casi todo el mundo la primera vez.
app.MapGet("/editions", async (string? imprint, int page, ICatalogService service, CancellationToken token) =>
    await service.SearchAsync(imprint, page, token));

// … y dentro del servicio:
public async Task<IReadOnlyList<EditionResponse>> SearchAsync(string? imprint, int page, CancellationToken token)
{
    if (page < 1) { throw new ArgumentException("La página debe ser positiva."); }
    if (imprint is not null && !Enum.TryParse<ImprintCode>(imprint, out _))
    {
        throw new ArgumentException("Sello desconocido.");
    }
    // …
}
```

Eso produce un `500` con una traza, porque una `ArgumentException` que sube hasta el marco no es una
respuesta HTTP. Y peor: **el dominio queda con código de validación de entrada**, que no es su trabajo.

```csharp
// ✅ La validación en el borde, y el resultado es una RESPUESTA y no una excepción.
app.MapGet("/v1/editions", async (
    [AsParameters] EditionQuery query,
    ICatalogService service,
    CancellationToken token) =>
{
    // La validación devuelve problemas, no lanza. Y el formato de la respuesta de error es
    // `ProblemDetails`, que es un estándar (RFC 9457) y no un invento de esta casa — así Almenara
    // puede programar contra él sin leer nuestra documentación.
    if (query.Validate() is { Count: > 0 } errors)
    {
        return Results.ValidationProblem(errors);
    }

    CatalogPage page = await service.SearchAsync(query.ToCriteria(), token);
    return Results.Ok(page);
});
```

**Dónde se rompe el paralelo:** el hábito de `@Valid` con anotaciones en el DTO se transfiere en la idea y no
en el mecanismo. ASP.NET Core no valida por omisión un parámetro de consulta contra anotaciones como lo hace
Spring con `@Validated`; hay que pedirlo, con un filtro de endpoint o con validación explícita. **Es más
trabajo y más visible**, y el precio de la omisión es un `500` en vez de un `400`.

**Tercera: el controlador con doce dependencias inyectadas.**

```csharp
// ❌ El constructor que delata un diseño. Cada dependencia se justificaba sola; juntas, no.
public CatalogController(
    ICatalogService catalog, IInventoryService inventory, IPricingService pricing,
    IImprintRepository imprints, ILogger<CatalogController> log, IMapper mapper,
    IMemoryCache cache, IConfiguration config, IDateTimeProvider clock,
    IFeatureManager features, IAuditWriter audit, IMetrics metrics)
```

**Por qué falla:** porque doce dependencias significan que esa clase hace doce cosas, y en un controlador casi
siempre significa que **la lógica de aplicación está ahí**. La señal no es el número: es que para probar un
endpoint haya que construir doce dobles.

Con minimal APIs el problema se nota antes, porque las dependencias se declaran **por endpoint** y un
endpoint con seis parámetros de servicio se ve mal enseguida. Es una de las ventajas reales del estilo: **la
presión del diseño es visible en la firma.**

### 🩻 Esto sí funciona igual

Todo HTTP, y es mucho. Verbos, códigos de estado, cabeceras, negociación de contenido, idempotencia de `PUT`
frente a `POST`, `ETag` y peticiones condicionales, `Cache-Control`. Nada de eso cambia y el curso no lo
explica.

También REST como estilo, el diseño de recursos, y la disciplina de compatibilidad hacia atrás: **un campo se
agrega y no se quita, una respuesta puede crecer y no encoger, un enumerado puede recibir valores nuevos y el
consumidor tiene que tolerarlos**. Esa última regla tiene un nombre —el principio de robustez— y vale igual
aquí.

Y la inyección de dependencias, en lo conceptual: los tiempos de vida son los mismos tres con otros nombres
—`Singleton`, `Scoped`, `Transient` contra *singleton*, *request* y *prototype*— y el error clásico es el
mismo: **inyectar algo de vida corta en algo de vida larga**. En .NET eso tiene una consecuencia concreta que
Spring evita por otro camino, y está en el 📖.

### 📖 Diccionario de traducción

| Java / Spring Boot | ASP.NET Core | Dónde se rompe el paralelo |
|---|---|---|
| `@RestController` + `@GetMapping` | `MapGet` de una minimal API, o un `ControllerBase` | Las dos formas coexisten y son idiomáticas. La minimal API **declara sus dependencias por endpoint** |
| `@Service` / `@Component` + escaneo | registro explícito en el contenedor | **No hay escaneo por omisión**: cada servicio se registra a mano. Más ruido, y ningún registro sorpresa |
| `@Autowired` | inyección por constructor | Igual, y sin la variante por campo — que en Spring existe y aquí no. Es una mejora |
| `singleton` / `request` / `prototype` | `Singleton` / `Scoped` / `Transient` | Mismo modelo. Y **capturar un `Scoped` dentro de un `Singleton` es un error que el contenedor detecta al arrancar**, si se lo pides |
| `@Valid` + `BindingResult` | validación explícita o filtro de endpoint | **No valida por omisión.** Hay que pedirlo, y omitirlo produce un `500` donde debía haber un `400` |
| `@ControllerAdvice` + `@ExceptionHandler` | `IExceptionHandler` / middleware | Equivalente, y el formato estándar de error se llama `ProblemDetails` (RFC 9457) y viene en la caja |
| `ResponseEntity<T>` | `Results.*` / `TypedResults.*` | `TypedResults` declara el tipo en la firma, y de ahí sale el OpenAPI **sin anotaciones** |
| springdoc / swagger-annotations | OpenAPI integrado en el SDK | Se genera del código y de los tipos: **menos anotaciones, y lo que no está en el tipo no está en el documento** |
| `@RequestParam` uno por uno | `[AsParameters]` sobre un `record` | Agrupa la consulta en un tipo, que además se puede validar y probar aparte |
| `spring.profiles` | `ASPNETCORE_ENVIRONMENT` + `appsettings.{Env}.json` | Mismo concepto. La composición de fuentes es explícita y ordenada — es la fase 16 |
| `@Transactional` en el servicio | **nada equivalente** | La transacción se abre a mano donde toca. Ya apareció en la F08 y sigue doliendo igual |
| MapStruct / ModelMapper | mapeo **a mano**, o un generador | Este curso mapea a mano y lo declara: un mapeador automático entre entidad y DTO **reintroduce el acoplamiento** que el DTO venía a cortar |
| Actuator | comprobaciones de salud de ASP.NET Core | Equivalentes en lo básico; el resto es la fase 19 |

> ⚠️ **La fila del mapeador automático es una decisión de este curso y conviene defenderla.** Un mapeador que
> copia propiedades por nombre entre la entidad y el DTO ahorra veinte líneas y **devuelve el acoplamiento que
> el DTO existía para cortar**: cuando alguien agregue una propiedad a la entidad, aparecerá en el contrato
> sin que nadie lo decida. El mapeo a mano es tedioso una vez y es **una lista explícita de lo que se
> promete**. En un proyecto con cuatrocientos DTO la aritmética podría ser otra; en CatalogAPI, con doce, no
> lo es.

> 📝 **Nota de ecosistema.** Las minimal APIs llegaron con .NET 6 en 2021, veinte años después de que ASP.NET
> empezara con páginas y controladores, y su motivación fue doble: bajar la ceremonia para servicios pequeños
> y **reducir el arranque**, que en un contenedor que escala a cero cuesta dinero. Eso explica dos cosas: que
> todo el material anterior a 2021 use controladores —y siga siendo correcto—, y que la comparación de la
> sección 6 tenga una columna de arranque, que es la que va a importar en la fase 20.

---

## 💻 5. Código mínimo con comentarios

### 5.1 El contrato: DTO, y el mapeo explícito

```csharp
// src/modern/Cordillera.Catalog.Api/Contracts/V1/EditionResponse.cs
//
// 🧬 ESTE ES EL SEGUNDO BORDE DEL CURSO. El de la fase 09 protege el dominio del esquema de 1997;
//    este protege al mundo del dominio. Lo que se escriba aquí, Almenara lo va a tener en
//    producción, así que cada campo es una promesa.
namespace Cordillera.Catalog.Api.Contracts.V1;

public sealed record EditionResponse
{
    /// <summary>El ISBN-13 sin guiones. Es el identificador que el mundo editorial usa de verdad.</summary>
    /// <remarks>
    /// Ojo: **no es `CODEDIT`**. El identificador interno no sale al contrato, y por eso las 340
    /// ediciones sin ISBN de la fase 01 **no aparecen en esta API** — y eso es una decisión, no un
    /// descuido: son ediciones del fondo antiguo que no se venden por canal externo. Está en la
    /// documentación del endpoint.
    /// </remarks>
    public required string Isbn { get; init; }

    public required string Title { get; init; }

    /// <summary>El sello por su nombre: "Cordillera", "Cometa", "Del Sur", "Universitaria del Bajío".</summary>
    public required string Imprint { get; init; }

    /// <summary>
    /// Formato como **cadena estable**, no como número: `hardcover`, `paperback`, `ebook`,
    /// `audiobook`. Un `enum` serializado por valor haría que agregar un formato en medio cambiara
    /// el significado de los números que Almenara ya tiene en su código.
    /// </summary>
    public required string Format { get; init; }

    public required decimal ListPrice { get; init; }

    /// <summary>Código ISO de tres letras.</summary>
    public required string Currency { get; init; }

    /// <summary>
    /// `true` si hay existencias en algún almacén. Es lo que Almenara pregunta de verdad, y es
    /// mejor que exponer el saldo: el saldo cambia cada minuto y lo obligaría a consultar en bucle.
    /// </summary>
    public required bool Available { get; init; }
}
```

```csharp
// src/modern/Cordillera.Catalog.Api/Contracts/V1/EditionMapping.cs
//
// El mapeo, a mano y en un solo sitio. Son veinte líneas tediosas y son **la lista explícita de lo
// que se promete**: cuando alguien agregue una propiedad al dominio, este archivo NO cambia, y el
// contrato tampoco. Ese es el punto entero.
internal static class EditionMapping
{
    public static EditionResponse? ToResponse(this CatalogEntry entry, bool available)
    {
        // Sin ISBN no hay recurso que exponer: el contrato se identifica por ISBN. Devolver null
        // aquí y filtrar arriba es más honesto que inventar un identificador.
        if (entry.Isbn is not { } isbn)
        {
            return null;
        }

        return new EditionResponse
        {
            Isbn = isbn.Value,
            Title = entry.Title,
            Imprint = ImprintName(entry.Imprint),
            Format = FormatName(entry.Format),
            ListPrice = entry.ListPrice.Amount,
            Currency = entry.Currency,
            Available = available,
        };
    }

    // Las dos traducciones de `enum` a cadena estable. Son un `switch` exhaustivo a propósito: si
    // alguien agrega un valor al `enum` del dominio, **esto no compila** — y eso obliga a decidir
    // qué nombre público tiene, en vez de dejar que se filtre un número.
    private static string FormatName(EditionFormat format) => format switch
    {
        EditionFormat.Td => "hardcover",
        EditionFormat.Tb => "paperback",
        EditionFormat.Eb => "ebook",
        EditionFormat.Au => "audiobook",
        _ => throw new UnreachableException($"Formato sin nombre público: {format}."),
    };

    private static string ImprintName(ImprintCode imprint) => imprint switch
    {
        ImprintCode.Cor => "Cordillera",
        ImprintCode.Com => "Cometa",
        ImprintCode.Sur => "Del Sur",
        ImprintCode.Uba => "Universitaria del Bajío",
        _ => throw new UnreachableException($"Sello sin nombre público: {imprint}."),
    };
}
```

**El patrón a memorizar**

> **Un `switch` exhaustivo en el borde del contrato es un guardia de compilación contra filtraciones.** El
> día que alguien agregue `EditionFormat.Pdf` al dominio, este archivo deja de compilar y **alguien tiene
> que decidir cómo se llama hacia afuera**. Con un mapeador automático, `Pdf` habría aparecido en la
> respuesta como el número 4 y Almenara lo habría recibido sin que nadie lo decidiera.

### 5.2 La validación en el borde, y el error como respuesta

```csharp
// src/modern/Cordillera.Catalog.Api/Contracts/V1/EditionQuery.cs
//
// Los parámetros de consulta agrupados en un tipo. Se valida y se prueba aparte, sin levantar un
// servidor — que es la misma idea del modelo de vista de la fase 13, aplicada al borde HTTP.
public sealed record EditionQuery
{
    public string? Imprint { get; init; }
    public string? Format { get; init; }
    public bool? Available { get; init; }
    public int Page { get; init; } = 1;
    public int PageSize { get; init; } = 50;

    /// <summary>
    /// Devuelve los problemas, **no lanza**. Es la política de errores de la fase 04 aplicada aquí:
    /// una petición mal formada no es un fallo excepcional del sistema — es parte del trabajo de un
    /// endpoint público, y llega varias veces al día.
    /// </summary>
    public Dictionary<string, string[]> Validate()
    {
        Dictionary<string, string[]> errors = [];

        if (Page < 1)
        {
            errors["page"] = ["La página tiene que ser 1 o mayor."];
        }

        // El tope de tamaño de página no es una cortesía: es la defensa contra que alguien pida
        // 100.000 registros. Y aquí es donde se ve que la deuda 💸 de la paginación no es la
        // ausencia de `PageSize`, sino que el endpoint de volcado completo sigue existiendo.
        if (PageSize is < 1 or > 200)
        {
            errors["pageSize"] = ["El tamaño de página tiene que estar entre 1 y 200."];
        }

        if (Imprint is not null && !ImprintNames.IsKnown(Imprint))
        {
            errors["imprint"] = [$"Sello desconocido. Valores válidos: {ImprintNames.All}."];
        }

        if (Format is not null && !FormatNames.IsKnown(Format))
        {
            errors["format"] = [$"Formato desconocido. Valores válidos: {FormatNames.All}."];
        }

        return errors;
    }
}
```

```csharp
// src/modern/Cordillera.Catalog.Api/Endpoints/CatalogEndpoints.cs
internal static class CatalogEndpoints
{
    public static void MapCatalog(this IEndpointRouteBuilder app)
    {
        // El grupo lleva la versión en la ruta, y eso es una decisión que la sección 5.3 justifica.
        RouteGroupBuilder v1 = app.MapGroup("/v1").WithTags("Catálogo");

        v1.MapGet("/editions", GetEditions)
          .WithName("ListEditions")
          .WithSummary("Lista las ediciones disponibles del catálogo.")
          // TypedResults en la firma: de aquí sale el OpenAPI, sin anotaciones. Lo que no esté en
          // el tipo no está en el documento, y eso mantiene los dos sincronizados por construcción.
          .Produces<CatalogPage<EditionResponse>>(StatusCodes.Status200OK)
          .ProducesValidationProblem();

        v1.MapGet("/editions/{isbn}", GetEdition)
          .WithName("GetEdition")
          .Produces<EditionResponse>(StatusCodes.Status200OK)
          .ProducesProblem(StatusCodes.Status404NotFound);
    }

    private static async Task<Results<Ok<CatalogPage<EditionResponse>>, ValidationProblem>> GetEditions(
        [AsParameters] EditionQuery query,
        ICatalogQueries catalog,
        CancellationToken token)
    {
        if (query.Validate() is { Count: > 0 } errors)
        {
            // ProblemDetails: RFC 9457. Un estándar, así que Almenara programa contra él sin leer
            // nuestra documentación — y sin que nadie tenga que inventar un formato de error.
            return TypedResults.ValidationProblem(errors);
        }

        CatalogPage<EditionResponse> page = await catalog.SearchAsync(query.ToCriteria(), token);
        return TypedResults.Ok(page);
    }
}
```

**Detalles con intención**

- **`Results<Ok<T>, ValidationProblem>` como tipo de retorno** declara en la firma todas las respuestas
  posibles, y de ahí sale el OpenAPI. Es la diferencia con anotar a mano: **el documento no se puede
  desincronizar del código**, porque es el código.
- **`[AsParameters]` sobre un `record`** agrupa la consulta y la hace comprobable: hay una prueba de
  `EditionQuery.Validate()` que no levanta un servidor.
- **La validación devuelve y no lanza**, y es la política de la fase 04 aplicada: una petición mal formada
  llega varias veces al día, así que **es parte del trabajo y no un fallo excepcional**.

### 5.3 El versionado, con su política de retiro

```csharp
// La decisión de esta fase, y hay tres opciones defendibles. Se elige una y se escribe por qué.
//
//   ❌ Sin versión            → imposible cambiar nada sin romper a Almenara
//   ✅ En la ruta (/v1/...)   → visible, cacheable, trivial de enrutar y de documentar
//   ⚠️ En una cabecera        → más "correcto" según algunos, y más difícil de probar con curl,
//                               de cachear en un intermediario y de explicarle a un socio
//
// Se elige **la ruta**, y la razón decide: el consumidor es un socio comercial con su propio
// equipo. La opción que puede probar con un navegador y pegar en un correo gana a la más elegante.
app.MapGroup("/v1");
```

Y la parte que casi nadie escribe, que es la política:

```csharp
// src/modern/Cordillera.Catalog.Api/Versioning/DeprecationPolicy.cs
/// <summary>
/// Cuánto vive una versión y cómo se anuncia su retiro. **Publicar una versión sin política de
/// retiro es publicarla para siempre**, y eso es la decisión que la fase 11 ya encontró con el
/// endpoint de compatibilidad del ASMX: siete años de un contrato que nadie decidió mantener.
/// </summary>
internal static class DeprecationPolicy
{
    /// <summary>Una versión vive al menos 18 meses desde que se anuncia su sucesora.</summary>
    public static readonly TimeSpan MinimumLifetime = TimeSpan.FromDays(548);

    /// <summary>
    /// Las dos cabeceras estándar del anuncio. `Deprecation` dice desde cuándo está obsoleta y
    /// `Sunset` cuándo deja de responder — y las dos son estándar, así que las herramientas del
    /// socio las pueden detectar sin que nadie las avise por correo.
    /// </summary>
    public static void AnnounceSunset(HttpResponse response, DateOnly sunsetOn) =>
        response.Headers.Append("Sunset", sunsetOn.ToString("R"));
}
```

> 💸 **Deuda declarada: el endpoint de catálogo sale sin paginación obligatoria.**
>
> `GET /v1/editions` acepta `page` y `pageSize` con un tope de 200 — pero **sigue existiendo
> `GET /v1/editions/all`**, el volcado completo, porque es lo que reemplaza al CSV nocturno que Almenara
> consume hoy y **pedirle que cambie su integración el mismo día que estrena la API sería perder el
> argumento**. Son 26.000 ediciones por llamada, y Almenara la va a llamar cada hora.
>
> **Se paga en la fase 20, y en pesos.** Ahí la factura de egreso de datos y de cómputo va a mostrar
> cuánto cuesta servir el catálogo entero cada hora, y ese número es el argumento para negociar la
> migración a paginación con el socio. La factura será
> `git diff fase-15 fase-20 -- src/modern/Cordillera.Catalog.Api/Endpoints/`.
>
> **Por qué se deja:** porque es una decisión de negociación y no de ingeniería. Retirar el volcado completo
> sin un número que lo justifique es pedirle trabajo a un socio porque a nosotros nos parece mejor. Con la
> factura en la mano, la conversación es otra — y la fase 20 la tiene.

### 5.4 El cobro de la deuda de la fase 13

```csharp
// src/modern/Cordillera.Domain/Inventory/StockSummary.cs
//
// 💸 Cobro de la deuda de la fase 13. El total y el conteo de movimientos sin título se calculaban
//    en el modelo de vista, y no son reglas de la pantalla: son del dominio. Que un ajuste negativo
//    reste y una devolución sume es una regla del negocio de Cordillera, no de WPF.
//
//    La factura: git diff fase-13 fase-15 -- src/modern/Sige.Desktop/ src/modern/Cordillera.Domain/
//
//    Y el retorno es inmediato y era previsible: la misma regla la necesitan **las dos interfaces**
//    —el escritorio y esta API— y con la lógica en el modelo de vista habría habido dos
//    implementaciones que algún día habrían discrepado.
public sealed record StockSummary(int TotalUnits, int RowsWithoutTitle, int OrphanRows)
{
    /// <summary>
    /// Se calcula sobre `StockLine`, que es un **tipo de lectura** y no una entidad: el título
    /// requiere un cruce con `TITULOS` y "la edición existe" es un dato derivado de que ese cruce
    /// encontró algo. `InventoryMovement` no los tiene ni debe tenerlos — es la misma decisión que
    /// `CatalogEntry` en la fase 09, y conviene que sea la misma para que el curso tenga un solo
    /// patrón de lectura y no dos.
    /// </summary>
    public static StockSummary From(IReadOnlyList<StockLine> lines)
    {
        int total = 0;
        int withoutTitle = 0;
        int orphans = 0;

        foreach (StockLine line in lines)
        {
            // La regla, en un solo sitio del sistema: los ajustes negativos restan porque su
            // cantidad ya viene negativa desde 1997, y las devoluciones suman.
            total += line.Quantity;

            if (line.Title is null) { withoutTitle++; }
            if (!line.EditionExists) { orphans++; }
        }

        return new StockSummary(total, withoutTitle, orphans);
    }
}

/// <summary>
/// El tipo de lectura de existencias: una fila de `EXISTENC` cruzada con su edición y su título,
/// tal como la devuelve el borde 🧬 de la fase 09. El `Title` es anulable porque hay 1.900
/// movimientos cuya edición ya no existe, y `EditionExists` lo dice sin obligar a inferirlo de un
/// `null`.
/// </summary>
public sealed record StockLine(
    EditionId Edition,
    string? Title,
    bool EditionExists,
    WarehouseCode Warehouse,
    int Quantity);
```

**Prueba de fuego**

```powershell
dotnet run --project src\modern\Cordillera.Catalog.Api
curl "http://localhost:5080/v1/editions?imprint=Cometa&pageSize=5" | jq
curl "http://localhost:5080/openapi/v1.json" | jq '.components.schemas'
```

Y aquí está la comprobación que de verdad importa, y es la del checklist:

```powershell
# Ni un nombre del esquema de 1997 en el contrato público. Cero resultados, o la fase no está cerrada.
curl -s http://localhost:5080/openapi/v1.json | Select-String "CODEDIT|VLRUNIT|BORRADO|CODSELLO|FECMOVTO"
```

Y la mentira que te va a contar la salida si miras el lugar equivocado: **el JSON de la respuesta puede verse
limpio y el contrato estar filtrado igual**. Si `format` sale como `1` en vez de `"paperback"`, no hay ningún
nombre de 1997 a la vista — y sin embargo Almenara acaba de recibir el orden de declaración de un `enum`
interno como parte del contrato. **Los nombres son la mitad de la filtración; los tipos son la otra.**

---

## 📏 6. Medición

> 📝 **Esta medición no es el tema de la fase y conviene decirlo.** El tema es el contrato; esto es la
> comparación que el curso debe porque el curso mide. Si el resultado es un empate —y probablemente lo sea—
> el empate es el dato útil: **la elección entre minimal APIs y controladores es de estilo y no de
> rendimiento**, y saberlo evita una discusión de equipo que no lleva a nada.

**Hipótesis:** al volumen de CatalogAPI la diferencia de throughput y latencia entre minimal APIs y
controladores queda dentro del ruido; **la diferencia medible está en el arranque**, que es lo que va a
importar en la fase 20 con un contenedor que escala a cero.

**Condiciones:** SDK 10.0.401 · Release · Windows 11 · SQL Server 2025 en contenedor con la base del
generador, semilla `19970417` · **el mismo endpoint implementado dos veces**, con el mismo servicio, el mismo
DTO y el mismo mapeo · carga de 200 peticiones concurrentes durante 60 segundos, que es el barrido donde la
fase 05 encontró el codo · arranque en frío medido con la caché de disco limpia · 20 repeticiones con 3 de
calentamiento descartadas · arnés propio.

**Competidores:** cuatro, y las dos últimas están para separar el efecto del estilo del efecto de lo demás:

- **Minimal API** con `TypedResults` y validación en el borde.
- **Controlador** (`ControllerBase`) con el mismo cuerpo y los mismos tipos.
- **Minimal API devolviendo la entidad directamente** — el anti-patrón de la 🪞, medido: si además fuera más
  rápido, habría que decirlo.
- **El volcado CSV nocturno**, que es el statu quo y el competidor de verdad: es lo que Almenara consume hoy,
  y si la API no le gana en algo que a Almenara le importe, el proyecto no tiene caso.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 15 --concurrency 200 --cold-start
```

**Resultado:** ⏳ pendiente de ejecución en tu máquina.

| Implementación | Throughput (req/s) | Latencia p50 | p95 | Arranque en frío | Asignado por petición |
|---|---|---|---|---|---|
| Minimal API con DTO | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Controlador con DTO | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Minimal API devolviendo la entidad | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Volcado CSV nocturno (statu quo) | n/a | **24 h de desfase** | — | — | — |

> ⚖️ **Veredicto** *(expectativa, todavía sin ejecutar — `formato-de-mediciones.md` §2.6)*. Se espera
> **empate** en throughput y latencia entre las dos primeras —y publicarlo es el punto— y una diferencia
> medible en arranque a favor de la minimal API, que es la razón por la que existen. Y se espera que la
> tercera fila quede **igual o mejor** que la primera, porque saltarse el mapeo ahorra trabajo: **si es así,
> queda demostrado que el DTO no se defiende con rendimiento, se defiende con el contrato** — y eso es más
> honesto que insinuar que además es rápido.
>
> **Los dos umbrales que tu ejecución tiene que determinar:** (1) **a partir de cuántos endpoints las
> convenciones de un controlador empiezan a ahorrar más de lo que cuestan** — que es una medida de
> mantenimiento y no de rendimiento, y se estima contando repetición; y (2) **cuánto arranque de más cuesta
> el controlador**, que es el número que la fase 20 va a usar cuando el contenedor escale a cero.
>
> 📝 La última fila no es comparable en las mismas unidades y está a propósito: **el competidor real no es
> el otro estilo de API, es el CSV de anoche.** Veinticuatro horas de desfase contra una respuesta en
> milisegundos es la única comparación que a Almenara le importa, y es la que justifica el proyecto.

---

## 🧱 7. Miniproyecto — el endpoint que Almenara podría consumir de verdad

**El encargo**

El correo de Almenara, íntegro, y después lo que Clara escribió abajo al reenviarlo:

> *"Para la renovación del contrato de 2027 requerimos integración por API con SLA de disponibilidad
> publicado. Los volcados CSV nocturnos ya no son viables para nuestra operación. Agradecemos confirmar antes
> del 30 de noviembre."*
>
> — *"Necesito confirmar que sí. Dime qué les mando: qué van a poder consultar, con qué garantía, y qué
> necesito prometerles que podamos cumplir. No me mandes documentación técnica: mándame lo que yo les
> contesto."*

**Por qué duele**

Porque Clara no pidió un endpoint: pidió **un contrato y una promesa que se pueda cumplir**. Y las dos cosas
son decisiones que no se pueden deshacer: lo que se le prometa a Almenara en noviembre va a estar en su
código en enero, y el curso todavía no tiene ni autenticación (fase 16) ni despliegue (fase 20) ni
observabilidad para sostener un SLA (fase 19).

Así que el trabajo real es **decidir qué se promete ahora y qué no**, y que lo prometido no filtre el
esquema de 1997.

**Datos de entrada**

| Qué | Detalle |
|---|---|
| El catálogo | 26.400 ediciones, de las cuales ~11.000 vivas comercialmente |
| … sin ISBN | **340**, del fondo anterior a 2007. **No tienen identificador público** |
| … con tildes comidas | **1.240** títulos peruanos, irreversible. Almenara los va a ver así |
| Existencias | Tres almacenes; la disponibilidad es "hay en alguno" |
| Lo que Almenara consume hoy | Un CSV nocturno de 26.000 líneas, con **24 h de desfase** |
| Lo que Almenara pregunta de verdad | ¿Existe este ISBN? ¿A qué precio? ¿Hay? ¿Cambió algo desde ayer? |
| La fecha | **30 de noviembre** |

**Criterios de aceptación**

1. Tres endpoints versionados, documentados en OpenAPI, con **paginación, filtrado y errores como
   `ProblemDetails`**: listar, obtener por ISBN, y el volcado completo que reemplaza al CSV.
2. **Cero nombres del esquema heredado en la especificación de OpenAPI**, comprobado con la búsqueda del
   comando de la sección 5.4. Y cero `enum` serializados como número.
3. Una prueba que **falla si alguien devuelve una entidad del dominio o de EF Core** desde un endpoint.
   *(Pista: se puede hacer con una prueba de arquitectura sobre los tipos de retorno.)*
4. Las 340 ediciones sin ISBN **no aparecen** en la API, y esa decisión está **documentada en el endpoint**,
   no escondida en el código.
5. Existe la **respuesta para Clara**: media página, en su lenguaje, con qué va a poder consultar Almenara,
   con qué garantía, y **qué no se les promete todavía y por qué** — incluido que el SLA se publica cuando
   la fase 20 lo pueda sostener.
6. **Medición de cierre:** las cuatro filas de la tabla, con el arranque en frío. Van en el mensaje del tag
   `mini-15`.

**Restricciones de estilo y alcance**

Código nuevo. **Sin autenticación** —es la fase 16— y el endpoint lo declara explícitamente con un
`.AllowAnonymous()` comentado, para que quede claro que es una decisión aplazada y no un olvido. Sin caché.
Sin mapeador automático: el mapeo se escribe a mano y en un solo archivo.

Y una restricción que es el punto: **el DTO se diseña antes de mirar la entidad**. Escribe primero qué
necesita Almenara —está en la tabla de datos de entrada— y solo después mira qué tiene el dominio para
llenarlo. Al revés, el contrato sale con forma de esquema.

**La trampa**

Vas a diseñar el DTO bien, vas a mapear a mano, y el JSON va a salir limpio. Y **el contrato va a estar
filtrado igual**, por dos sitios que no se ven en una respuesta de ejemplo:

El primero: `format` va a salir como `1`. Los `enum` de .NET se serializan por su valor numérico por
omisión, así que el `switch` exhaustivo que escribiste en el mapeo puede estar perfecto y el serializador
deshacerlo — si el DTO declara el campo como `EditionFormat` en vez de `string`. Almenara recibe un número y
lo guarda.

El segundo es peor y solo aparece con datos reales: **la paginación sin orden estable**. `Skip`/`Take` sobre
una consulta sin `ORDER BY` determinista devuelve filas en el orden que el motor decida, que puede cambiar
entre llamadas — así que la página 2 puede repetir o perder ediciones que estaban en la página 1. Almenara
va a recorrer las 26.000 en 530 llamadas y va a acabar con un catálogo incompleto **sin que nada falle**.

Cuando encuentres los dos, escribe en tres líneas por qué un contrato se verifica con **la especificación y
una prueba de recorrido completo**, y no mirando una respuesta de ejemplo.

<details><summary>Pista 1 — el enfoque</summary>

Empieza por la tabla de "lo que Almenara pregunta de verdad" y escribe el DTO desde ahí, sin abrir el
dominio. Vas a notar que sobran la mitad de las propiedades de `Edition` y que falta una —la
disponibilidad— que no está en ninguna entidad: es una pregunta que cruza dos módulos.

Para la respuesta de Clara: la parte difícil es el párrafo de lo que **no** se promete. Escríbelo primero.

</details>

<details><summary>Pista 2 — la herramienta</summary>

Para OpenAPI desde el SDK, sin anotaciones:
`https://learn.microsoft.com/aspnet/core/fundamentals/openapi/overview`

Para los errores estándar, `ProblemDetails` y el RFC:
`https://learn.microsoft.com/aspnet/core/web-api/handle-errors#problem-details`

Para la trampa de los `enum`, `JsonStringEnumConverter` — **y la decisión de este curso es no usarlo**:
declarar el campo como `string` en el DTO es más explícito que configurar el serializador, porque el que lee
el DTO ve el contrato sin tener que conocer la configuración.
`https://learn.microsoft.com/dotnet/api/system.text.json.serialization.jsonstringenumconverter`

Y para la segunda trampa, busca *keyset pagination* o paginación por cursor, y compárala con `Skip`/`Take`.

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```csharp
// El contrato: tres tipos, y ninguno es una entidad.
public sealed record EditionResponse { /* … */ }
public sealed record CatalogPage<T>(IReadOnlyList<T> Items, string? NextCursor, int? TotalCount);
public sealed record EditionQuery { public Dictionary<string, string[]> Validate(); }

// La prueba del criterio 3: arquitectura, no comportamiento.
[Fact]
public void Ningun_endpoint_devuelve_una_entidad_del_dominio();

// Y lo que el dominio tiene que ganar, porque es una pregunta que cruza módulos.
public interface ICatalogQueries
{
    Task<CatalogPage<EditionResponse>> SearchAsync(CatalogCriteria criteria, CancellationToken token);
    Task<EditionResponse?> FindByIsbnAsync(Isbn isbn, CancellationToken token);
}
```

</details>

**Cómo se entrega**

```powershell
dotnet test src\Cordillera.slnx -c Release
dotnet run --project src\modern\Cordillera.Catalog.Api
curl -s http://localhost:5080/openapi/v1.json | Select-String "CODEDIT|VLRUNIT|BORRADO"
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 15 --concurrency 200 --cold-start
```

```bash
git tag -a mini-15 -m "Mini F15: contrato de CatalogAPI v1 · 3 endpoints, OpenAPI sin nombres de 1997 · <X> req/s, arranque <Y> ms · volcado completo pendiente de paginar (deuda F20)"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Expón el mismo endpoint con una minimal API y con un controlador, y compara el OpenAPI que genera cada
   uno. Anota las diferencias.
2. Devuelve una entidad del dominio a propósito y mira el JSON. Señala los cinco problemas de la 🪞 en la
   salida real.
3. Declara un campo del DTO como `EditionFormat` y observa que sale como número. Arréglalo de las dos
   formas —campo `string` o convertidor— y di cuál eligió el curso y por qué.
4. Provoca un `500` con una validación que lanza, y después conviértelo en un `400` con `ProblemDetails`.
   Compara las dos respuestas como las vería Almenara.
5. Registra un servicio como `Singleton` que dependa de un `Scoped` y observa qué pasa al arrancar. Después
   activa la validación del ámbito y compara el mensaje.
6. Publica la cabecera `Sunset` en un endpoint y verifica que aparece. Explica para qué sirve que sea
   estándar.

**🟡 Intermedio (7–14)**

7. Escribe la prueba de arquitectura del criterio 3: que ningún endpoint devuelva un tipo del dominio.
8. Implementa paginación con `Skip`/`Take` y demuestra con una prueba que **puede perder o repetir filas**
   sin un orden determinista.
9. Cámbiala a paginación por cursor y demuestra que el recorrido completo devuelve exactamente 26.400
   ediciones, sin repetir ninguna.
10. Agrega un campo nuevo al DTO y demuestra que es un cambio compatible. Después quita uno y explica por
    qué no lo es, y qué implica con un socio externo.
11. Agrega un valor al `enum` `EditionFormat` del dominio y comprueba que el mapeo **no compila**. Explica
    por qué eso es la característica y no el problema.
12. Escribe un filtro de endpoint que valide automáticamente cualquier parámetro que implemente
    `IValidatable`, y compáralo con la validación explícita de la sección 5.2.
13. Mide el arranque con y sin generación de OpenAPI en tiempo de ejecución, y anota si conviene generarla
      en compilación.
14. Documenta en OpenAPI la decisión de las 340 ediciones sin ISBN, de forma que un consumidor la lea sin
    preguntar.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Almenara reporta que "faltan títulos" en su catálogo. Su recorrido son 530 llamadas
    paginadas. Enumera tres causas posibles y di cuál es más probable con `Skip`/`Take`.
16. **Diagnóstico.** El endpoint responde bien y Almenara dice que a veces recibe `500`. Los logs no
    muestran nada. Enumera cuatro causas —una es el tiempo de espera del intermediario, otra el
    `CancellationToken`— y di cómo distinguirlas.
17. **Medición.** Ejecuta la medición completa de la sección 6 y determina **los dos umbrales**. Publica el
    empate si aparece, y también si la versión que devuelve la entidad resulta más rápida.
18. **Medición.** Mide cuánto cuesta servir el volcado completo de 26.000 ediciones, en tiempo, memoria y
    bytes transferidos. Guarda el número: es la deuda 💸 que la fase 20 cobra en pesos.
19. Diseña la v2 del contrato con un cambio incompatible —por ejemplo, la disponibilidad por almacén en vez
    de un booleano— y escribe el plan de transición con sus dieciocho meses y sus cabeceras.
20. **Decisión.** Minimal APIs o controladores para CatalogAPI, con doce endpoints y previsión de llegar a
    treinta. Decide con los números de la medición **y con el costo de mantenimiento**, y di qué te haría
    cambiar.
21. **Decisión — ¿se migra, se envuelve o se deja quieto?** Los cuatro volcados CSV nocturnos
    desincronizados. Con la API funcionando, decide qué pasa con cada uno, y **qué se le dice a cada uno de
    los tres socios** — que no tienen el mismo poder de negociación que Almenara.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Diseña un contrato que parezca limpio y filtre el esquema de tres formas distintas, sin
    usar ningún nombre de 1997. Es el ejercicio que enseña a revisar un contrato ajeno.
23. **Adversarial.** Consigue que el recorrido paginado completo devuelva un catálogo **incompleto y
    plausible** —sin errores, sin huecos evidentes— y explica cómo lo detectaría el consumidor. Después
    escribe la prueba que lo impide.
24. **Diseño.** Escribe el contrato completo que Cordillera necesitaría para reemplazar los cuatro volcados:
    qué recursos, qué operaciones, qué notificaciones de cambio, y qué de eso se puede prometer hoy. Marca
    lo que necesita las fases 16, 17, 19 y 20.
25. **Defiende una decisión.** Escribe la respuesta de Clara a Almenara: qué van a poder consultar, con qué
    garantía, y **qué no se les promete todavía**. Media página, en su lenguaje, y sin comprometer un SLA
    que el sistema aún no puede sostener.

**🔥 Opcionales**

- Genera un cliente de C# desde el OpenAPI publicado y consúmelo desde una prueba. Es lo que Almenara va a
  hacer, y probarlo desde el lado del consumidor cambia cómo se ve el contrato.
- Investiga la biblioteca de versionado de API de ASP.NET Core y compárala con el `MapGroup("/v1")` de esta
  fase. Decide si aporta con doce endpoints.
- Añade `ETag` y peticiones condicionales al endpoint de una edición, y mide cuánto tráfico ahorraría con el
  patrón de consumo de Almenara. Guárdalo: es un argumento de la fase 20.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis/overview` — minimal APIs, con
  `TypedResults` y `[AsParameters]`.
- `https://learn.microsoft.com/aspnet/core/fundamentals/openapi/overview` — OpenAPI generado desde el código
  en .NET moderno, **sin anotaciones**.
- `https://learn.microsoft.com/aspnet/core/web-api/handle-errors` — `ProblemDetails` y el manejo de errores
  como respuesta.
- `https://learn.microsoft.com/aspnet/core/fundamentals/dependency-injection` — tiempos de vida, y **la
  validación de ámbitos**, que atrapa el error clásico al arrancar.
- `https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis/route-handlers` — cómo se enlazan los
  parámetros, que es donde está la mitad de las sorpresas.
- `https://learn.microsoft.com/azure/architecture/best-practices/api-design` — guía de diseño de API, con
  versionado y paginación.

**Especificación y estándares**

- `https://www.rfc-editor.org/rfc/rfc9457` — *Problem Details for HTTP APIs*. Es corto y es el formato de
  error que la fase usa.
- `https://www.rfc-editor.org/rfc/rfc8594` — la cabecera `Sunset`, para anunciar el retiro de una versión.

> ⚠️ Verifica las URLs. Y la advertencia propia de esta fase: **mucho material de ASP.NET Core es anterior a
> 2021** y por tanto solo conoce controladores —sigue siendo correcto, pero no menciona minimal APIs—; y
> mucho del material de OpenAPI describe **Swashbuckle**, la biblioteca que se usaba antes de que el SDK
> generara OpenAPI por su cuenta. Las dos cosas funcionan; saber cuál estás leyendo evita agregar una
> dependencia que ya no hace falta.

**Orden de lectura sugerido:** antes de escribir, la guía de diseño de API de Azure —es de arquitectura y no
de .NET, y decide la mitad de la fase— y el RFC 9457, que son cuatro páginas. Durante el miniproyecto, la de
minimal APIs y la de OpenAPI. Al cerrar, la de inyección de dependencias: es la preparación de la fase 16.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Existe un contrato. Tres endpoints versionados, documentados, con errores estándar y **sin un solo nombre de
1997 a la vista** — y con dos bordes en lugar de uno: el de la fase 09 protege el dominio del esquema, y el
DTO de esta fase protege al mundo del dominio. Existe también una respuesta para Clara que dice qué se
promete y **qué no se promete todavía**, que es la parte que se olvida y la única que evita comprometer un
SLA que el sistema aún no puede sostener.

Y se cobró la deuda de la fase 13 con un retorno inmediato: la regla del total de existencias la necesitaban
**las dos interfaces**, y con la lógica en el modelo de vista habrían acabado siendo dos implementaciones que
algún día discrepan.

La fase 16 es el paso natural y es la más satisfactoria del curso, porque **cobra la deuda más antigua**: la
cadena de conexión que la fase 07 puso en el `App.config` de noventa equipos, con un usuario que tiene
permiso de escritura sobre todo y una contraseña de 2017 que nadie cambió porque cambiarla significa visitar
noventa equipos. La 16 hace que ni el servicio ni el cliente tengan un secreto en disco, **con una sola ruta
de código** entre el equivalente local y el gestor de verdad. Y de paso resuelve qué hacer con la tabla de
usuarios de 2017 y su hash — incluido el paso incómodo de migrar contraseñas que nadie puede leer.

> **La señal de que quedó bien:** *"Puedo publicar la especificación y ningún nombre de 1997 aparece. Y
> cuando Clara me pregunte qué le prometemos a Almenara, mi respuesta incluye lo que todavía no."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el miniproyecto corriendo
> y `git status` limpio:
>
> ```bash
> git tag -a fase-15 -m "F15 cerrada:
> - CatalogAPI v1: 3 endpoints versionados, OpenAPI generado del codigo, errores ProblemDetails
> - DTO como decision y mapeo a mano: cero nombres de 1997 y cero enum como numero
> - validacion en el borde, con los problemas devueltos y no lanzados
> - politica de retiro escrita: 18 meses y cabecera Sunset
> - deuda de la F13 cobrada: el total de existencias vive en el dominio y lo usan las dos interfaces
> - el volcado completo sale sin paginar: deuda declarada con cobro en pesos en la F20"
> ```
>
> Esta fase **cobra una deuda y planta otra**, y las dos son cortas de explicar. La que planta tiene una
> propiedad que ninguna anterior tenía: **no se paga con código, se paga con una negociación** — retirar el
> volcado completo exige que Almenara cambie su integración, y eso solo se pide con la factura en la mano.
> Es la primera deuda del curso cuyo cobro depende de otra empresa.

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura.*

- **`INSTINTOS.md`** — abre la familia *servicios, identidad y operación* con tres entradas: devolver la
  entidad del ORM —que necesita **el JSON real con sus cinco problemas**, porque en abstracto suena a purismo
  y con el JSON delante no—, validar dentro del servicio, y el controlador con doce dependencias. La primera
  debe cerrar con la frase que la resume: **el borde de la F09 protege el dominio del esquema; el DTO protege
  al mundo del dominio.**
- **`BENCHMARKS.md`** — entrada ⏳ *F15 · Minimal APIs contra controladores, y contra el CSV de anoche*. Tiene
  una fila **no comparable en las mismas unidades** —el volcado nocturno, con sus 24 horas de desfase— y eso
  es deliberado: el competidor real no es el otro estilo de API. Conviene que el archivo lo diga, porque es
  la primera entrada con una fila así.
- **Deuda 💸 cobrada:** el total y el conteo de huérfanos, de la F13. Conviene anotar en el libro de §7.1
  que su retorno fue inmediato y previsible —dos interfaces necesitaban la misma regla— porque es el mejor
  argumento contra dejar lógica de negocio en la capa de presentación.
- **Deuda 💸 plantada:** el volcado completo sin paginar, cobro en F20 y **en pesos**. Es la primera deuda del
  curso **cuyo cobro depende de un tercero**: retirarlo exige que Almenara cambie su integración. Hay que
  anotarlo en el libro, porque cambia qué significa "pagar" una deuda.
- **Tipos nuevos para el congelamiento:** `EditionResponse`, `EditionQuery`, `CatalogPage<T>`,
  `CatalogCriteria`, `ICatalogQueries`, `EditionMapping`, `DeprecationPolicy`, `StockSummary`, **`StockLine`** —el tipo de
  lectura de existencias, hermano de `CatalogEntry`— y el espacio
  de nombres `Contracts.V1`, que es donde vive el contrato y **no debe mezclarse con el dominio**.
- **Para la fase 16:** los endpoints salen con `AllowAnonymous` declarado y comentado, así que la 16 tiene
  el sitio exacto donde poner la autenticación. Y la respuesta a Clara del miniproyecto dice qué **no** se
  promete: el SLA depende de la 19 y la 20.
- **Para la fase 17:** el correo de Almenara pide notificación de cambios, y eso es trabajo de fondo. La 17
  debería recogerlo como caso, porque un webhook es el ejemplo más claro de por qué hace falta idempotencia.
- **Para la fase 20:** el número del ejercicio 18 —cuánto cuesta servir el volcado completo— es la entrada
  directa de la factura, y el ejercicio 🔥 de `ETag` es el argumento del ahorro.
- **Riesgo detectado y resuelto:** el borrador de la sección 5.4 le pedía a `InventoryMovement` un `Title` y
  un `EditionExists` que **la entidad no tiene ni debe tener** —el título requiere un cruce con `TITULOS` y
  la existencia es un dato derivado—. Se resolvió con **`StockLine`, un tipo de lectura**, coherente con
  `CatalogEntry` de la F09: así el curso tiene **un solo patrón de lectura** y no dos. Queda anotado para el
  congelamiento.
