# 🗄️ Fase 09 — Acceso a datos contra un esquema hostil

> C# para desarrolladores Java senior · Fase 09 de 24 · Bloque B ⭐ — el sistema heredado y la frontera
> Depende de: 08 · Habilita: 10
> Estilo de esta fase: **mixto 🧬** — el esquema y los procedimientos son de 1997 y no se tocan; el
> acceso a datos nuevo es .NET 10. El borde entre los dos es el contenido de la fase.
> Proyecto que avanza: **nace CatalogAPI**, de momento solo su capa de datos. El endpoint público es de
> la fase 15.

---

## 🎯 1. Propósito

Escribir el borde. Al terminar, `VLRUNIT` vive a un lado y `UnitPrice` al otro, la traducción entre los
dos está **en un solo archivo**, y ese archivo es el patrón que las quince fases siguientes van a citar.

Y decidir con números la pregunta que todo el mundo responde de memoria: **ADO.NET, Dapper o EF Core**.
No en abstracto —donde la respuesta es siempre "depende"— sino sobre este esquema, con estos datos, con
el plan de consulta medido antes.

> 🧭 **El patrón que fija esta fase, y es el más citado del curso:** *el nombre feo vive en el borde.*
> La columna es `VLRUNIT`; la propiedad es `UnitPrice`; el mapeo entre las dos es explícito, está en un
> solo sitio, y ese sitio es material didáctico marcado 🧬.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Existe `src/modern/Cordillera.Data` con **el borde en un solo lugar**: `char(8)` → `LegacyDate`,
      `VLRUNIT` → `UnitPrice`, `BORRADO` filtrado, `char(10)` recortado.
- [ ] `MOVINVEN` está mapeado a `InventoryMovement` y probado **contra SQL Server en contenedor**, con
      los datos del generador de la fase 07.
- [ ] La consulta de catálogo está implementada **tres veces** —ADO.NET, Dapper y EF Core— y las tres
      pasan las mismas pruebas.
- [ ] 💸 **Se cobran tres deudas**: los dos `!` de la fase 02 y el `IQueryable` filtrado en memoria de
      la fase 03. Las tres desaparecen en el mismo archivo.
- [ ] El filtro global de `BORRADO` está configurado, **y los tres sitios de este proyecto donde no se
      aplica están documentados y probados**.
- [ ] La tabla por año es consultable desde el modelo nuevo sin concatenar cadenas, y la decisión de
      cómo se logró está escrita con su costo.
- [ ] Las fotos de la fase 08 **siguen pasando** — o fallan donde el borde cambió algo a propósito, y
      cada fallo tiene su explicación escrita.
- [ ] La medición de la sección 6 está escrita con su comando, y la entrada quedó en `BENCHMARKS.md`.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **La API pública de CatalogAPI** —endpoints, contrato, versionado, validación en el borde HTTP— →
  fase 15. Aquí nace su capa de datos y nada más.
- **Migraciones de esquema** → fase 11. Este esquema **no se modifica en esta fase**, ni con una
  migración de EF Core ni con un `ALTER`. Lo que se decide es cómo se lee y se escribe **tal como está**.
- **Cortar la conexión directa del cliente a la base** → fase 10. Aquí el cliente WinForms sigue
  escribiendo directo; lo que se construye es la otra ruta, en paralelo.
- **El reporte histórico con su `UNION ALL`** se mide aquí —es parte de la comparación— pero **no se
  arregla**: el rediseño del reporte es de la fase 10 en adelante, con la API en medio.
- **Caché** → fase 15. Es la respuesta fácil a la mitad de los números de esta fase y por eso se
  aplaza: primero hay que saber cuánto cuesta el camino sin caché.

---

## 🧠 4. Concepto mínimo

### Qué significa "esquema hostil", operativamente

No es un insulto: es una lista de propiedades concretas que rompen las suposiciones que todo mapeador
objeto-relacional trae de fábrica. Y conviene tenerla escrita, porque cada una decide una línea de
configuración:

- **No hay llaves foráneas**, así que **no hay relaciones que descubrir**. Un ORM que genera su modelo
  desde la base no va a encontrar ninguna navegación, y las que configures a mano van a apuntar a datos
  que a veces no existen — 1.900 veces, exactamente.
- **No hay claves primarias declaradas** en varias tablas. `EXISTENC` tiene una clave compuesta lógica
  (`CODALMA`, `CODEDIT`) que nadie declaró, y `VENTAS_AAAA` tiene un `NROVENTA` único **dentro de su
  tabla** y repetido entre tablas.
- **Los tipos no dicen lo que son.** `char(8)` es una fecha, `char(1)` es un booleano o un enumerado,
  `char(10)` con relleno de espacios es un identificador que hay que recortar.
- **Hay un filtro obligatorio en todas las consultas** —`BORRADO = 'N'`— que la mitad del sistema
  olvida, y que si tú aplicas siempre vas a cuadrar distinto que el sistema viejo.
- **Una entidad está repartida en treinta tablas** por año, y el nombre de la tabla es un dato.

De ahí sale la decisión central de la fase, y se puede enunciar en una frase: **un ORM te abstrae del
SQL, no del esquema**. Lo que EF Core puede hacer es mapear cada rareza explícitamente, una por una, y
eso es trabajo de configuración que alguien escribe y mantiene. Lo que no puede hacer es que las
rarezas dejen de existir.

### Las tres herramientas, y qué pregunta responde cada una

**ADO.NET** es el acceso crudo: `SqlCommand`, `SqlDataReader`, y tú lees columna por columna. Responde
*"quiero control total y no quiero una dependencia"*, y es lo que hay debajo de las otras dos. En este
curso aparece por dos razones: es la línea base de rendimiento, y es lo que ya está en
`Sige.DataAccess`.

**Dapper** es un mapeador de resultados: tú escribes el SQL, él convierte las filas en objetos.
Responde *"el SQL lo quiero escribir yo, el bucle de lectura no"*. Con un esquema hostil tiene una
ventaja concreta: **la rareza se resuelve en el SQL**, que es donde el esquema vive, en vez de en una
capa de configuración.

**EF Core** es un mapeador objeto-relacional con seguimiento de cambios, unidad de trabajo y
traducción de consultas. Responde *"quiero un modelo de dominio y que alguien más se encargue del
SQL"*. Con un esquema hostil el costo se paga por adelantado y en configuración; el beneficio llega
cuando hay que **escribir** y cuando hay varias entidades relacionadas cambiando juntas.

> 🧠 **El modelo mental:** las tres están en una escala de **dónde vive el conocimiento del esquema**.
> En ADO.NET vive en el código que lee. En Dapper vive en el SQL. En EF Core vive en la configuración
> del modelo. Ninguna lo elimina — y la pregunta no es cuál es mejor, es **en qué archivo quieres
> abrirlo cuando algo se rompa**.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El reflejo: EF Core es Hibernate, y el ORM me va a abstraer del esquema.**

Once años con Hibernate y JPA dejan una expectativa razonable: describes las entidades con
anotaciones, el ORM genera el esquema o se adapta a él, y a partir de ahí trabajas con objetos. Y la
primera hora con EF Core la confirma, porque el modelo básico funciona igual.

```csharp
// ❌ La traducción directa de la expectativa de JPA. Compila, corre, y devuelve datos equivocados.
public sealed class InventoryMovement
{
    public int Id { get; set; }
    public string EditionCode { get; set; } = string.Empty;
    public DateTime MovedOn { get; set; }          // ← char(8) no es un datetime
    public Edition Edition { get; set; } = null!;  // ← navegación a una FK que no existe
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
}

// Y la consulta que parece obvia:
var movements = await context.Movements
    .Include(m => m.Edition)                       // ← INNER JOIN: pierde 1.900 filas
    .Where(m => m.MovedOn >= new DateTime(2026, 1, 1))
    .ToListAsync(token);
```

Cuatro cosas están mal y **ninguna produce un error**:

1. **`MovedOn` como `DateTime`** contra un `char(8)`: o EF Core se niega al configurar, o alguien pone
   un conversor que revienta con `'00000000'` en la fila 210.
2. **`Include`** genera un `INNER JOIN` por omisión cuando la navegación es requerida, así que las
   1.900 filas huérfanas desaparecen del resultado. El sistema viejo usaba `LEFT JOIN` y las mostraba.
   **El reporte cuadra distinto y nadie sabe por qué.**
3. **No hay filtro de `BORRADO`**, así que la consulta trae 3.600 movimientos que el sistema considera
   borrados.
4. **`Id` como `int` autoincremental** es correcto para `MOVINVEN`, y es incorrecto para `EXISTENC`,
   `FACTDETA` y las treinta tablas de ventas, que tienen claves compuestas o no únicas. En JPA
   habrías escrito un `@IdClass`; aquí hay que configurarlo, y si no lo haces EF Core inventa una
   convención que funciona hasta que dos filas colisionan.

```csharp
// ✅ El mismo mapeo, con cada rareza declarada. Es más largo, y esa longitud ES la información:
//    cada línea de aquí es una propiedad del esquema que alguien tuvo que descubrir.
modelBuilder.Entity<InventoryMovement>(entity =>
{
    entity.ToTable("MOVINVEN");
    entity.HasKey(m => m.Id);
    entity.Property(m => m.Id).HasColumnName("NROMOVTO").ValueGeneratedOnAdd();

    // char(10) con relleno de espacios: el recorte va aquí, en un solo sitio.
    entity.Property(m => m.EditionCode)
          .HasColumnName("CODEDIT")
          .HasConversion(id => id.Value.PadRight(10), raw => new EditionId(raw.TrimEnd()));

    // char(8) a LegacyDate, con los cinco sabores de ausencia de la fase 02.
    entity.Property(m => m.MovedOn)
          .HasColumnName("FECMOVTO")
          .HasConversion(d => d.ToLegacyString(), raw => LegacyDate.FromLegacy(raw));

    // Sin navegación a Edition. No hay llave foránea, y una navegación sobre datos que no
    // existen es una promesa que el esquema no puede cumplir.
    entity.Ignore(m => m.Edition);

    // El filtro obligatorio, una vez.
    entity.HasQueryFilter(m => m.IsDeleted == false);
});
```

**Por qué falla el reflejo:** porque Hibernate y EF Core hacen lo mismo **cuando el esquema colabora**,
y este no colabora. La diferencia real no está entre los dos ORM: está entre **un esquema diseñado para
un ORM y un esquema diseñado para FoxPro en 1997**. Con el primero, la configuración es corta y el ORM
parece magia; con el segundo, la configuración **es** el trabajo, y llamarla magia es cómo se pierden
1.900 filas.

> ⚰️ **Autopsia del anti-patrón: el `Include` que cuadra distinto.**
>
> **Antes (el sistema viejo):** `SP_EXIST_ALMACEN` usa `LEFT JOIN` a `EDICION`. El reporte de Lima
> muestra 4.300 movimientos, 61 de ellos con el título en blanco porque la edición ya no existe.
>
> **Después (la versión con `Include`):** 4.239 movimientos. Los 61 desaparecieron.
>
> **Cuánto costó:** tres semanas hasta que alguien del almacén notó que el saldo del reporte nuevo no
> cuadraba con el del viejo por 340 unidades. La diferencia no estaba en el cálculo: estaba en **qué
> filas entraban a la suma**. Y el número era pequeño, lo cual lo hizo más difícil: si hubieran
> desaparecido la mitad de las filas, se habría visto el primer día.
>
> **La defensa:** las fotos de la fase 08. La prueba de caracterización de `SP_EXIST_ALMACEN` fija las
> 4.300 filas, así que la versión nueva falla la comparación **antes** de llegar a producción. Ese es el
> retorno concreto de la fase anterior, y es el primer sitio del curso donde se cobra.

### 🩻 Esto sí funciona igual

Todo tu oficio de base de datos, sin traducción: transacciones y niveles de aislamiento, índices,
planes de ejecución, estadísticas, bloqueos, y el `N+1` — que se llama igual, se produce igual y se
diagnostica igual. Si sabes leer un plan, sabes leer este.

El `N+1` merece una línea porque el mecanismo es idéntico: una consulta que trae N filas y después una
consulta por fila para cargar su relación. En Hibernate lo producías con lazy loading; en EF Core lo
produces con **lazy loading o con un `foreach` que accede a una navegación**, y el remedio es el mismo:
traerlo todo de una con la proyección correcta.

Y se transfiere la intuición de **cuándo el ORM no es la herramienta**: un reporte de agregación, una
carga masiva, una consulta con SQL específico del motor. En Java bajabas a JDBC o a una consulta nativa;
aquí bajas a Dapper o a ADO.NET, y la decisión se toma con el mismo criterio.

### 📖 Diccionario de traducción

| Java / JPA · Hibernate | C# / EF Core | Dónde se rompe el paralelo |
|---|---|---|
| `EntityManager` / `Session` | `DbContext` | Es **la unidad de trabajo y el seguimiento juntos**, y es de vida corta: uno por operación, no uno por aplicación |
| `@Entity` + anotaciones | `DbSet<T>` + configuración por API fluida | El curso usa la API fluida y no atributos: la configuración de un esquema hostil no cabe en anotaciones |
| `persistence.xml` / `application.yml` | `OnModelCreating` / `IEntityTypeConfiguration<T>` | La configuración es **código**, así que se puede probar |
| `@Id @GeneratedValue` | `HasKey` + `ValueGeneratedOnAdd` | Con claves compuestas, `HasKey(x => new { x.A, x.B })`, sin tipo aparte — no hace falta `@IdClass` |
| `@ManyToOne` / `@OneToMany` | navegaciones + `HasOne`/`WithMany` | **Sin llaves foráneas no hay nada que descubrir**, y una navegación configurada a mano miente cuando el dato no existe |
| `@Where` de Hibernate | `HasQueryFilter` | Similar, con la diferencia grande: **hay tres sitios donde no se aplica**, y están en la sección 5.3 |
| `@Convert` / `AttributeConverter` | `HasConversion` | Igual de potente y se escribe en línea. Es donde vive la mitad del borde 🧬 de este curso |
| `session.setReadOnly` / `@Transactional(readOnly)` | `AsNoTracking()` | Se pide **por consulta**, no por sesión, y la diferencia de rendimiento es la columna que mide la sección 6 |
| lazy loading por omisión | **sin lazy loading** por omisión | Si accedes a una navegación no cargada, obtienes `null` — no una consulta. **Menos `N+1` accidental** |
| `@NamedQuery` / JPQL | `IQueryable` con LINQ | Se compone y se comprueba en compilación. Y lo que no se puede traducir **no avisa**: se resuelve en memoria |
| consulta nativa (`createNativeQuery`) | `FromSql` / Dapper | `FromSql` **ignora los filtros globales**, y eso es la trampa del miniproyecto |
| `@Version` optimista | `IsRowVersion()` | Necesita una columna que este esquema **no tiene**, y agregarla es una migración: fase 11 |
| Flyway / Liquibase | migraciones de EF Core | **Aquí no se usan**: el esquema es de 1997 y EF Core no lo gobierna. La fase 11 explica esa decisión |
| `JdbcTemplate` | **Dapper** | El paralelo más cercano del ecosistema, y casi exacto en filosofía |
| `hibernate.show_sql` | `LogTo(Console.WriteLine)` + `EnableSensitiveDataLogging` | Y el SQL que imprime es el que se ejecuta, parámetros incluidos |

> ⚠️ **La fila del lazy loading es la buena noticia y conviene subrayarla.** En Hibernate, acceder a una
> colección no inicializada lanza `LazyInitializationException` o dispara una consulta, y de ahí sale la
> mitad de los problemas de rendimiento de una aplicación JPA. EF Core **no tiene lazy loading
> activado**: una navegación no cargada es `null`, punto. Eso convierte el `N+1` accidental en un
> `NullReferenceException` visible, que es mucho mejor — te enteras en la primera prueba en vez de en
> producción.

> 📝 **Nota de ecosistema.** EF Core no es Entity Framework 6: es una reescritura de 2016 con otro
> modelo interno, y **buena parte del material que vas a encontrar sobre "Entity Framework" es de la
> versión vieja**, donde había lazy loading por omisión, un diseñador visual, y un archivo `.edmx`. En
> este curso esa confusión es especialmente peligrosa porque `Sige.DataAccess` es contemporáneo de EF 6
> y en cualquier tutorial de la época verías `.edmx` — así que si buscas "Entity Framework esquema
> existente" vas a encontrar la respuesta de 2013, que era generar el modelo desde la base con el
> diseñador. Hoy la respuesta es la configuración por API fluida, escrita a mano, y es más trabajo
> **a propósito**.

---

## 💻 5. Código mínimo con comentarios

### 5.1 El borde, en un solo archivo

```csharp
// src/modern/Cordillera.Data/LegacyBoundary.cs
// 🧬 ESTE ES EL BORDE. Todo lo que traduce entre el esquema de 1997 y el modelo de dominio vive
//    aquí y en ningún otro sitio. Si aparece una conversión de char(8) a fecha en otro archivo,
//    es un error de diseño y no una optimización local.
namespace Cordillera.Data;

/// <summary>
/// Las cuatro traducciones que el esquema de SIGE exige, cada una en un solo lugar.
/// </summary>
/// <remarks>
/// 💸 Aquí se cobran tres deudas del Bloque A a la vez:
///   - los dos `!` de la fase 02, que tapaban la decisión de qué hacer con CODEDIT vacío y
///     con MONEDA de tres letras. Ahora esa decisión se toma, una vez, en `EditionCodeFrom` y
///     `CurrencyFrom`.
///   - el `IQueryable` de la fase 03, que filtraba en memoria porque `Isbn.TryParse` no se puede
///     traducir a SQL. Ahora el filtro traducible va a la base y la validación va después.
///
/// Las tres facturas:
///   git diff fase-02 fase-09 -- src/fases/02-nullable-y-pattern-matching/
///   git diff fase-03 fase-09 -- src/modern/Cordillera.Domain/CatalogQueries.cs
/// </remarks>
public static class LegacyBoundary
{
    /// <summary>
    /// `char(10)` con relleno de espacios → `EditionId`. El recorte pasa aquí y **solo** aquí.
    /// </summary>
    /// <remarks>
    /// La deuda de la fase 02 era un `!` que asumía que `CODEDIT` nunca viene vacío. Con los datos
    /// de `DISMEX` era cierto; con los de `MOVINVEN` no lo es — hay 31 filas con la columna en
    /// blanco, de los ajustes de 2018. La decisión, tomada aquí: **una cadena vacía no es un
    /// identificador**, así que devuelve `null` y quien llame decide.
    /// </remarks>
    public static EditionId? EditionCodeFrom(string? raw)
    {
        string? trimmed = raw?.TrimEnd();
        return string.IsNullOrEmpty(trimmed) ? null : new EditionId(trimmed);
    }

    /// <summary>
    /// El identificador hacia la base: `char(10)` quiere sus diez caracteres. Sin esto, una
    /// comparación en SQL contra un valor de nueve caracteres no encuentra nada — y el motor **no
    /// avisa**, simplemente devuelve cero filas.
    /// </summary>
    public static string ToLegacy(this EditionId id) => id.Value.PadRight(10);

    /// <summary>
    /// `char(3)` → moneda. La otra deuda de la fase 02: el `!` asumía tres letras siempre.
    /// Hay 14 filas de `VENTAS_2003` con la columna vacía, y la decisión es tratarlas como pesos
    /// colombianos **registrando la suposición**, porque en 2003 el grupo solo vendía en Colombia.
    /// </summary>
    public static string CurrencyFrom(string? raw, out bool assumed)
    {
        string? trimmed = raw?.TrimEnd();
        assumed = string.IsNullOrEmpty(trimmed);
        return assumed ? "COP" : trimmed!;
        //                       ^ el único `!` que queda en este archivo, y es correcto:
        //                         la rama donde trimmed es null ya devolvió arriba. El análisis
        //                         de flujo no lo ve porque `assumed` y `trimmed` son dos cosas
        //                         distintas para él (fase 02, caso 3).
    }
}
```

**Detalles con intención**

- **El borde es bidireccional y eso importa.** `EditionCodeFrom` lee y `ToLegacy` escribe, y las dos
  están juntas: la mitad de los defectos de un borde salen de que alguien escribió la lectura y dejó la
  escritura para después.
- **`ToLegacy` con `PadRight` es el detalle que más tiempo cuesta descubrir.** Comparar un `char(10)`
  contra `'ED0000123'` —nueve caracteres— devuelve cero filas sin ningún error. Es el primer bug de todo
  el que llega a un esquema con `char` de ancho fijo.
- **Las suposiciones se registran, no se esconden.** `CurrencyFrom` devuelve `out bool assumed` porque
  "asumimos pesos colombianos en 14 filas de 2003" es un dato que alguien va a preguntar, y perderlo es
  peor que no haberlo asumido.

### 5.2 Las mismas tres consultas, tres veces

```csharp
// --- ADO.NET: control total, y el bucle de lectura es tuyo. Es la línea base.
public async Task<IReadOnlyList<CatalogEntry>> WithAdoNetAsync(ImprintCode imprint, CancellationToken token)
{
    const string sql = """
        SELECT E.CODEDIT, E.ISBN, E.PRECIOVTA, E.MONEDA, E.FORMATO, T.TITULO, T.CODSELLO
        FROM   EDICION E
               INNER JOIN TITULOS T ON T.CODTITULO = E.CODTITULO
        WHERE  T.CODSELLO = @sello AND E.ESTADO = 'V'
          AND  E.BORRADO = 'N' AND T.BORRADO = 'N'
        """;

    await using var connection = new SqlConnection(_connectionString);
    await using var command = new SqlCommand(sql, connection);
    command.Parameters.Add("@sello", SqlDbType.Char, 3).Value = imprint.ToString().ToUpperInvariant();

    await connection.OpenAsync(token);
    await using SqlDataReader reader = await command.ExecuteReaderAsync(token);

    List<CatalogEntry> entries = [];

    // Los índices ordinales y no los nombres: es más rápido y es más frágil. La fragilidad se
    // contiene leyéndolos una vez, arriba del bucle.
    int codeOrdinal = reader.GetOrdinal("CODEDIT");
    int isbnOrdinal = reader.GetOrdinal("ISBN");

    while (await reader.ReadAsync(token))
    {
        entries.Add(new CatalogEntry(
            Edition: LegacyBoundary.EditionCodeFrom(reader.GetString(codeOrdinal))!,
            Isbn: Isbn.TryParse(reader.IsDBNull(isbnOrdinal) ? null : reader.GetString(isbnOrdinal), out Isbn parsed)
                ? parsed
                : null,
            // … el resto de las columnas, a mano
            ));
    }

    return entries;
}
```

```csharp
// --- Dapper: el SQL es tuyo, el bucle no. La rareza se resuelve donde vive el esquema.
public async Task<IReadOnlyList<CatalogEntry>> WithDapperAsync(ImprintCode imprint, CancellationToken token)
{
    // El alias hace el mapeo: CODEDIT -> EditionCode. Sin configuración, sin conversores, y el
    // esquema y su traducción se leen juntos en la misma pantalla — que es el argumento de Dapper.
    const string sql = """
        SELECT RTRIM(E.CODEDIT) AS EditionCode,
               NULLIF(RTRIM(E.ISBN), '') AS RawIsbn,
               E.PRECIOVTA AS ListPrice,
               RTRIM(E.MONEDA) AS Currency,
               RTRIM(E.FORMATO) AS Format,
               T.TITULO AS Title
        FROM   EDICION E
               INNER JOIN TITULOS T ON T.CODTITULO = E.CODTITULO
        WHERE  T.CODSELLO = @Imprint AND E.ESTADO = 'V'
          AND  E.BORRADO = 'N' AND T.BORRADO = 'N'
        """;

    await using var connection = new SqlConnection(_connectionString);

    IEnumerable<CatalogRow> rows = await connection.QueryAsync<CatalogRow>(
        new CommandDefinition(sql, new { Imprint = imprint.ToString().ToUpperInvariant() },
                              cancellationToken: token));

    return [.. rows.Select(CatalogEntry.FromRow)];
}
```

```csharp
// --- EF Core: el modelo es tuyo, el SQL no. El costo se paga en configuración, por adelantado.
public async Task<IReadOnlyList<CatalogEntry>> WithEfCoreAsync(ImprintCode imprint, CancellationToken token) =>
    await _context.Editions
        .AsNoTracking()                      // ← lectura: sin seguimiento. Es una columna de la medición
        .Where(e => e.Imprint == imprint)    // el filtro de BORRADO lo pone el filtro global
        .Select(e => new CatalogEntry(e.Id, e.Isbn, e.ListPrice, e.Format, e.Title))
        .ToListAsync(token);
```

**Detalles con intención**

- **Las tres devuelven el mismo tipo y pasan las mismas pruebas.** Sin eso la comparación de la sección
  6 no vale: hay que medir el mismo trabajo, no tres trabajos parecidos.
- **`RTRIM` en el SQL de Dapper contra `HasConversion` en EF Core** es el mismo problema resuelto en dos
  sitios distintos, y es exactamente la elección de la sección 4: ¿dónde quieres abrir el archivo
  cuando algo se rompa?
- **La versión de EF Core es de cuatro líneas y esconde cuarenta** —las de la configuración del modelo—.
  Esa asimetría es real y la medición la registra en la columna de líneas de código, contando las dos
  cosas.
- **`AsNoTracking()` es explícito.** Es la traducción de tu `@Transactional(readOnly = true)`, pero se
  pide por consulta y no por sesión, y olvidarlo es la diferencia que la sección 6 mide.

### 5.3 El filtro global de `BORRADO`, y los tres sitios donde no se aplica

```csharp
// src/modern/Cordillera.Data/SigeContext.cs
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    // Un filtro por entidad, escrito una vez. Desde aquí, toda consulta LINQ sobre estas
    // entidades lleva `AND BORRADO = 'N'` sin que nadie lo escriba.
    modelBuilder.Entity<InventoryMovement>().HasQueryFilter(m => !m.IsDeleted);
    modelBuilder.Entity<Edition>().HasQueryFilter(e => !e.IsDeleted);
    modelBuilder.Entity<Title>().HasQueryFilter(t => !t.IsDeleted);
}
```

Y aquí está la parte que ningún tutorial menciona: **hay tres caminos en este proyecto por los que una
fila borrada entra igual**, y los tres son caminos que el curso usa.

```csharp
// (1) SQL crudo. `FromSql` NO aplica el filtro global: el filtro se traduce sobre el árbol de
//     expresión de LINQ, y aquí no hay árbol. Es el sitio que más aparece en este curso, porque
//     llamar a los procedimientos heredados es la mitad del Bloque B.
var movements = await _context.Movements
    .FromSql($"EXEC SP_EXIST_ALMACEN @CODALMA = {warehouse}")
    .ToListAsync(token);
// ↑ trae los 3.600 borrados. El procedimiento filtra por su cuenta en dos de sus tres ramas,
//   así que el resultado depende de qué rama tomó — que es el defecto de la fase 08.

// (2) Una entidad ya rastreada. `Find` consulta primero el rastreador de cambios, y si la
//     entidad está ahí la devuelve sin ir a la base y sin volver a evaluar el filtro.
var edition = await _context.Editions.FindAsync([editionId], token);
// ↑ si esa edición se cargó antes en el mismo contexto y entretanto se marcó como borrada,
//   esto devuelve la instancia vieja. Con un DbContext de vida corta el riesgo es bajo; con uno
//   que vive lo que dura una operación larga, no.

// (3) Lo que nunca se configuró. El filtro está en tres entidades, y `SalesRow` —la de las
//     treinta tablas anuales— se mapea como entidad sin clave sobre una vista, así que no tiene
//     filtro y nadie lo echa de menos hasta que un reporte suma filas anuladas.
var sales = await _context.SalesByYear.Where(s => s.Year == 2026).ToListAsync(token);
```

**El patrón a memorizar**

> **Un filtro global es una comodidad, no una garantía.** Se aplica a las consultas LINQ sobre las
> entidades donde lo configuraste, y a nada más. Todo lo que evada el árbol de expresión —SQL crudo,
> procedimientos, el rastreador de cambios, una entidad sin configurar— lo evade también. Por eso en
> este proyecto **las tres excepciones están probadas**: hay una prueba por cada una que documenta que
> la fila borrada aparece, para que nadie lo descubra en un reporte.

### 5.4 La tabla por año, convertida en algo consultable

Esta es la rareza que no se resuelve con configuración, y la fase toma una decisión explícita entre
tres caminos:

```sql
-- ✅ La decisión del curso: una VISTA que hace el UNION ALL, creada una vez, con el texto
--    estático. El motor puede cachear su plan, y EF Core la ve como una tabla más.
--
--    Cuesta: hay que recrearla cada 1 de enero. Eso es un trabajo programado de una línea, y es
--    mucho menos frágil que concatenar el nombre de la tabla en cada consulta.
CREATE VIEW V_VENTAS AS
  SELECT 1997 AS ANIO, * FROM VENTAS_1997 WHERE BORRADO = 'N'
  UNION ALL SELECT 1998, * FROM VENTAS_1998 WHERE BORRADO = 'N'
  -- … las treinta …
GO
```

```csharp
// Y el mapeo: entidad sin clave sobre la vista. Sin clave porque NROVENTA es único dentro de su
// tabla y repetido entre tablas: declararlo como clave haría que EF Core mezclara filas distintas
// por identidad. Es la clase de defecto que no se ve hasta que dos años tienen la misma venta 412.
modelBuilder.Entity<SalesRow>(entity =>
{
    entity.HasNoKey().ToView("V_VENTAS");
    entity.Property(s => s.Year).HasColumnName("ANIO");
});
```

**Detalles con intención**

- **Los tres caminos eran:** concatenar el nombre de la tabla en el código nuevo (rechazado: es el
  defecto que el curso vino a cortar), una vista (elegido), o migrar a una tabla particionada
  (aplazado: es un cambio de esquema y el esquema no se toca hasta la fase 11, si se toca).
- **`HasNoKey()` es la decisión importante** y es contraintuitiva para quien viene de JPA, donde toda
  entidad tiene identidad. Aquí la ausencia de clave es **información correcta sobre el dato**.
- **La vista filtra `BORRADO`** porque una entidad sin clave no puede llevar filtro global, así que el
  filtro se mueve al único sitio donde se puede poner una vez. Es la excepción (3) de la sección 5.3,
  resuelta — y el hecho de que haya que resolverla en otra capa es el dato.

**Prueba de fuego**

```powershell
dotnet test src\modern\Cordillera.Data.Tests -c Release
dotnet test src\modern\Sige.Characterization.Tests -c Release
```

**Las dos suites tienen que pasar**, y la segunda es la que importa: si el borde cambió el
comportamiento del sistema, las fotos de la fase 08 fallan. Un fallo ahí no es un problema del borde —es
la red funcionando— pero **cada fallo necesita su explicación escrita**: qué cambió, si fue a propósito,
y qué le pasa al reporte que alguien mira todos los días.

Y la mentira que te va a contar la salida si miras el lugar equivocado: **el mapeo con EF Core funciona
perfecto con los datos limpios**. Si pruebas con tres filas que escribiste a mano, las cuatro rarezas
del esquema no aparecen. Aparecen con las 148.000 del generador, y en particular con las 1.900
huérfanas y las 210 con fecha `'00000000'` — que es por lo que esa base existe y por lo que las pruebas
usan Testcontainers y no dobles.

---

## 📏 6. Medición

**Y el orden es obligatorio: primero el plan, después .NET** (`formato-de-mediciones.md` §2.2). La
línea base es la de la fase 07, y esta medición se lee contra ella.

**Hipótesis:** sobre este esquema, la diferencia entre ADO.NET, Dapper y EF Core **sin seguimiento** es
menor de lo que el folclore sugiere; EF Core **con seguimiento** paga un costo medible en asignaciones
que crece con el número de filas; y el `DataSet` heredado es el más caro de los cuatro en memoria por un
margen amplio. La variable que de verdad decide no es el mapeador: es **qué tan bien está escrita la
consulta**.

**Condiciones:** SQL Server 2025 en contenedor sobre WSL 2 · base del generador con semilla `19970417` ·
SDK 10.0.401, EF Core 10.0.12, Dapper 2.1.66 · tres consultas de volúmenes distintos —el catálogo de un
sello (~6.600 filas), un movimiento por clave (1 fila), y el reporte de un año (~30.000 filas)— · 50
repeticiones con 5 de calentamiento descartadas · el plan con `SET STATISTICS IO, TIME ON`; el lado .NET
con el arnés de la fase 06, con memoria y colecciones por generación.

**Competidores:** cinco implementaciones de la **misma** consulta, las cinco correctas y las cinco
defendibles en una revisión:

- **ADO.NET** con `SqlDataReader` y lectura por ordinal.
- **Dapper** con el SQL escrito a mano y el mapeo por alias.
- **EF Core sin seguimiento** (`AsNoTracking`).
- **EF Core con seguimiento**, que es lo que alguien escribe si no lo piensa.
- **`Sige.DataAccess` con `DataSet`**, que es el statu quo y por tanto el competidor más importante: si
  el camino nuevo no le gana, no hay caso.

> 📝 **Y aquí se paga lo que la fase 03 delegó.** Esa fase midió `IEnumerable` sobre datos en memoria y
> **aplazó a esta la comparación de `IQueryable` contra SQL directo**, porque no había base de datos.
> Es el acoplamiento declarado en §8.1 de la propuesta, y se cumple en la tabla B.

**Los comandos:**

```sql
DBCC FREEPROCCACHE;
SET STATISTICS IO, TIME ON;
-- La consulta de catálogo, tal como la genera cada una de las cinco. El SQL de EF Core se obtiene
-- con LogTo, y se pega aquí: medir el plan de la consulta que el ORM generó de verdad, no de la
-- que uno cree que generó.
```

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 09 --rows 1,6600,30000
```

**Resultado:** ⏳ pendiente de ejecución en tu máquina.

**A · Los cinco mapeadores sobre la consulta de catálogo (~6.600 filas)**

| Implementación | Mediana | p95 | Asignado | Pico | GC 0/1/2 | Líneas de código |
|---|---|---|---|---|---|---|
| ADO.NET (`SqlDataReader`) | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Dapper | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| EF Core `AsNoTracking` | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ + config |
| EF Core con seguimiento | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ + config |
| `DataSet` (statu quo) | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |

**B · `IQueryable` contra SQL directo — lo que la fase 03 delegó**

| Camino | Filas traídas | Filas usadas | Mediana | Asignado |
|---|---|---|---|---|
| `IQueryable` con el predicado traducible | ⏳ | ⏳ | ⏳ | ⏳ |
| `IQueryable` con `Isbn.TryParse` en el predicado (la deuda de la F03) | ⏳ | ⏳ | ⏳ | ⏳ |
| SQL directo equivalente | ⏳ | ⏳ | ⏳ | ⏳ |

La columna **filas traídas contra filas usadas** es la unidad de cobro de la deuda de la fase 03, y es
deliberado: **la factura de un predicado que no se puede traducir se mide en filas que viajaron de más,
no en milisegundos.**

> ⚖️ **Veredicto** *(expectativa, todavía sin ejecutar — `formato-de-mediciones.md` §2.6)*. Se espera
> que ADO.NET y Dapper queden **empatados** dentro del ruido —y publicar ese empate es importante,
> porque la creencia de que Dapper es "casi ADO.NET" es correcta y conviene confirmarla—, que EF Core
> sin seguimiento quede cerca, que con seguimiento se separe en asignaciones más que en tiempo, y que
> el `DataSet` sea el más caro en memoria por un factor grande.
>
> **Los tres umbrales que tu ejecución tiene que determinar:** (1) **a partir de cuántas filas el
> seguimiento de EF Core deja de ser gratis**; (2) **cuántas filas de más trae el predicado no
> traducible** de la tabla B; y (3) **a partir de qué tamaño de resultado el `DataSet` deja de ser
> tolerable**, que es el número que la fase 12 va a necesitar cuando decida qué hacer con la grilla de
> los formularios.
>
> ⚠️ **Y el veredicto perezoso que esta fase tiene prohibido dar:** *"usa Dapper para leer y EF Core
> para escribir"*. Puede ser la conclusión —es una arquitectura común y defendible— pero **solo si el
> número la sostiene y solo diciendo qué cuesta**: dos formas de acceso a datos en el mismo proyecto son
> dos modelos que hay que mantener sincronizados, dos sitios donde buscar cuando algo falla, y una
> persona más que hay que capacitar. En un equipo de dos —tú y Duván— ese costo no es abstracto. Si la
> medición dice empate, **la respuesta correcta puede ser una sola herramienta, aunque no sea la más
> rápida en ninguna fila.**

---

## 🧱 7. Miniproyecto — `MOVINVEN` a un modelo limpio, con el borde en un solo sitio

**El encargo**

Duván, y esta vez con una petición concreta: *"Si vas a leer `MOVINVEN` desde lo nuevo, necesito que
cuadre con lo que muestra el formulario. No que esté mejor: que **cuadre**. El almacén de Bogotá compara
los dos todos los lunes y si dan distinto me llaman a mí. Y otra cosa: si tu versión trae el título de
la edición, ojo con los movimientos viejos que no tienen edición — el formulario los muestra con el
título en blanco y el almacén ya está acostumbrado."*

**Por qué duele**

Porque el criterio de aceptación no es *"correcto"*: es *"igual"*, y las dos cosas no coinciden. El
sistema viejo trae filas huérfanas con el título en blanco, cuenta los saldos con un `LEFT JOIN`, y en
dos de sus tres ramas filtra `BORRADO` y en la tercera no. Un mapeo **bien hecho** cuadra distinto — y
esa diferencia hay que encontrarla, medirla y **decidirla**, no descubrirla en el reporte del lunes.

Y porque el aviso de Duván sobre los movimientos sin edición es la advertencia exacta del `Include`, y
está escrito en su lenguaje: *"el almacén ya está acostumbrado"*.

**Datos de entrada**

La base del generador de la fase 07, semilla `19970417`, y en particular estos subconjuntos que hay que
manejar bien:

| Subconjunto | Cuántos | Qué tiene que pasar |
|---|---|---|
| Movimientos del almacén de Lima | **4.300** | El mismo total que devuelve `SP_EXIST_ALMACEN` |
| … huérfanos (`CODEDIT` inexistente) | **1.900** en total | **Aparecen**, con el título ausente y no con la fila ausente |
| … con `FECMOVTO = '00000000'` | **210** | `LegacyDate` con `PlaceholderFrom2017`, no una excepción y no el 1 de enero |
| … con `CODEDIT` en blanco | **31** | El `null` que la deuda de la fase 02 tapaba con un `!` |
| … con `BORRADO = 'S'` | **3.600** | **No aparecen** en el modelo nuevo… salvo por los tres caminos de la sección 5.3 |
| Ajustes con cantidad negativa | ~6% | Suman negativo, y eso es correcto |

**Criterios de aceptación**

1. `InventoryMovement` está mapeado con las cuatro rarezas resueltas **en el borde y en un solo
   archivo**, y una búsqueda en el repositorio demuestra que no hay ninguna conversión de `char(8)` a
   fecha fuera de ahí.
2. **El total del almacén de Lima coincide exactamente** con el que devuelve `SP_EXIST_ALMACEN`, y una
   prueba lo compara contra el procedimiento heredado en el mismo contenedor. Si difiere, la prueba
   explica en su mensaje por cuántas filas y por qué.
3. Los 1.900 huérfanos **aparecen** en el resultado del modelo nuevo. Una prueba lo verifica contando.
4. Las tres excepciones del filtro global están **probadas, una por una**, y cada prueba documenta en su
   nombre que la fila borrada aparece por ese camino.
5. Las fotos de la fase 08 **siguen pasando**, o cada fallo tiene su explicación escrita en el commit.
6. **Medición de cierre:** las cinco implementaciones de la tabla A sobre la consulta de existencias de
   Lima, con tiempo, asignaciones y pico. Van en el mensaje del tag `mini-09`.

**Restricciones de estilo y alcance**

🧬 Mixta. El modelo y el borde son código nuevo —nullable, `async`, `CancellationToken`—; el esquema y
los procedimientos son de 1997 y **no se tocan**: ni un `ALTER`, ni un índice, ni una migración de EF
Core. Los nombres del esquema se escriben tal cual, y **el único sitio donde aparecen es el borde**.

Sin caché —es la fase 15— y sin cambiar `Sige.DataAccess`.

**La trampa**

Vas a configurar el filtro global de `BORRADO` y vas a estar tranquilo: una línea, todas las consultas
protegidas, elegante.

Y el reporte va a traer filas borradas.

Por tres caminos distintos, y **ninguno de los tres es un bug de EF Core**: los tres están
documentados y los tres son consecuencia de cómo funciona el mecanismo. Uno lo vas a encontrar rápido
porque el curso llama a procedimientos heredados todo el tiempo. El segundo solo aparece si el contexto
vive más de lo debido. El tercero es el peor, porque **no falla: simplemente nunca se configuró**, y la
entidad en cuestión es la de las treinta tablas anuales.

Cuando los tengas los tres, escribe una prueba por cada uno **que documente el comportamiento** en vez
de arreglarlo, y después decide cuál de los tres sí vale la pena cerrar y cuál se declara. Las dos
respuestas son defendibles y el enunciado no las toma.

<details><summary>Pista 1 — el enfoque</summary>

Empieza por la prueba del criterio 2 y hazla fallar. Comparar tu resultado contra el procedimiento
heredado, en el mismo contenedor, con los mismos datos, es lo que convierte "cuadra" en algo
verificable — y el primer fallo te va a decir exactamente cuál de las cuatro rarezas te faltó.

Y para el borde: una sola clase, con las conversiones en las dos direcciones juntas. Si la escritura
queda en otro archivo, el borde ya se partió.

</details>

<details><summary>Pista 2 — la herramienta</summary>

Para las conversiones, `HasConversion` con expresiones en las dos direcciones:
`https://learn.microsoft.com/ef/core/modeling/value-conversions`

Para el filtro y **sus límites**, lee la página completa, incluida la sección de advertencias:
`https://learn.microsoft.com/ef/core/querying/filters`

Y para ver el SQL que EF Core genera de verdad —que no siempre es el que crees—, `LogTo` con
`EnableSensitiveDataLogging` en el contexto de pruebas:
`https://learn.microsoft.com/ef/core/logging-events-diagnostics/simple-logging`

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```csharp
// El borde, con las dos direcciones juntas. Es el archivo que quince fases van a citar.
public static class LegacyBoundary
{
    public static EditionId? EditionCodeFrom(string? raw);
    public static string ToLegacy(this EditionId id);
    public static LegacyDate DateFrom(string? raw);
    public static string ToLegacy(this LegacyDate date);
}

// La configuración, en su propio archivo por entidad: es larga, y esa longitud es información.
internal sealed class InventoryMovementConfiguration : IEntityTypeConfiguration<InventoryMovement>
{
    public void Configure(EntityTypeBuilder<InventoryMovement> builder);
}

// La prueba que convierte "cuadra" en verificable.
internal sealed record ReconciliationResult(
    int LegacyRowCount,
    int ModernRowCount,
    int OrphanRowCount,
    IReadOnlyList<string> DifferingKeys);
```

</details>

**Cómo se entrega**

```powershell
dotnet test src\modern\Cordillera.Data.Tests -c Release
dotnet test src\modern\Sige.Characterization.Tests -c Release
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 09
```

```bash
git tag -a mini-09 -m "Mini F9: MOVINVEN mapeado con el borde en un solo sitio · cuadra con SP_EXIST_ALMACEN en 4.300 filas · Dapper <X> ms / EF Core <Y> ms / DataSet <Z> ms"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Mapea `ALMACEN` a `Warehouse` con la API fluida y escribe la prueba que verifica los tres almacenes
   contra la base del contenedor.
2. Compara un `char(10)` con un valor de nueve caracteres y demuestra con una consulta que devuelve cero
   filas sin ningún error. Después arréglalo con `PadRight` en el borde.
3. Activa `LogTo` en el contexto y pega el SQL que EF Core genera para la consulta de catálogo. Señala
   dónde aparece el filtro global.
4. Escribe la misma consulta con Dapper y con EF Core, y cuenta las líneas de cada una **incluyendo la
   configuración**. Anota los dos números.
5. Usa `AsNoTracking` y sin él sobre la misma consulta de 6.600 filas, y mide la diferencia de
   asignaciones con el arnés.
6. Escribe la prueba que demuestra que los 1.900 movimientos huérfanos aparecen en tu consulta, y la que
   demuestra que con `Include` desaparecen.

**🟡 Intermedio (7–14)**

7. Configura la clave compuesta de `EXISTENC` (`CODALMA`, `CODEDIT`) y explica en tres líneas qué habría
   pasado si la hubieras dejado a la convención.
8. Mapea `V_VENTAS` como entidad sin clave y demuestra con una prueba por qué declarar `NROVENTA` como
   clave mezclaría filas de años distintos.
9. Escribe un `HasConversion` para `BORRADO` (`char(1)` → `bool`) y verifica qué SQL genera una
   comparación sobre él. ¿Se traduce, o se filtra en memoria?
10. Provoca un `N+1` con EF Core sin lazy loading —hay que hacerlo a propósito— y explica por qué en
    Hibernate habría sido accidental.
11. Ejecuta un procedimiento heredado con `FromSql` y demuestra con una prueba que el filtro global no
    se aplicó. Después escribe la versión que sí filtra.
12. Mide el costo de `Isbn.TryParse` dentro de un predicado `IQueryable` contra filtrarlo después, y
    reporta **filas traídas** en las dos versiones. Es la factura de la deuda de la fase 03.
13. Escribe la conversión de `char(8)` a `LegacyDate` en el borde y prueba los cinco sabores de la fase
    02 contra las filas reales del generador.
14. Cambia una edición a `BORRADO = 'S'` mientras el `DbContext` la tiene rastreada, vuelve a
    consultarla con `Find`, y documenta qué devuelve y por qué.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** El reporte nuevo de existencias de Lima da 340 unidades menos que el viejo. Escribe
    el procedimiento de diagnóstico: qué compararías primero, con qué consulta, y en qué orden
    descartarías las cuatro causas posibles.
16. **Diagnóstico.** Una consulta de EF Core que funcionaba empieza a tardar diez veces más después de
    que alguien agregó un `Where` con un método propio. Explica el mecanismo, demuéstralo con el SQL
    generado, y di cómo lo habrías detectado antes.
17. **Medición.** Ejecuta la medición completa de la sección 6, las dos tablas, con el plan de consulta
    medido antes. Publica los **tres umbrales** y el empate si lo hay.
18. **Medición.** Determina cuánto cuesta la vista `V_VENTAS` frente a concatenar el nombre de la tabla
    en el código, con la caché de planes limpia y caliente. Es el número que justifica la decisión de la
    sección 5.4.
19. Implementa la escritura: un `INSERT` en `MOVINVEN` con EF Core y otro con `SP_MOVINVEN_INS`.
    Compara qué garantiza cada uno sobre `EXISTENC` y explica por qué el procedimiento no se puede
    reemplazar todavía.
20. **Decisión — ¿se migra, se envuelve o se deja quieto?** `Sige.DataAccess` tiene cuarenta métodos con
    `try`/`finally` escrito a mano y `DataSet`. Ahora existe una alternativa medida. Decide qué se hace
    con esos cuarenta métodos, y sostén la decisión con los números de la tabla A. *(La respuesta
    correcta probablemente sea "nada", y hay que poder defenderla.)*
21. **Decisión — ¿se migra, se envuelve o se deja quieto?** Las treinta tablas anuales podrían unificarse
    en una tabla particionada. Tienes la vista funcionando y medida. Decide, y calcula qué tocaría la
    unificación: cuántos procedimientos, cuántos volcados, cuánta ventana de parada.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Escribe una consulta con EF Core que devuelva un resultado **correcto según el
    modelo y equivocado según el negocio**, usando solo las rarezas del esquema. Después escribe la
    prueba de caracterización que lo habría atrapado.
23. **Adversarial.** Consigue que el filtro global de `BORRADO` se evada por un **cuarto** camino, que no
    sea ninguno de los tres de la sección 5.3. Documéntalo y agrégalo a la lista del proyecto.
24. **Diseño y medición.** El borde de esta fase resuelve cuatro rarezas. Diseña el borde completo para
    **las cuatro tablas de los cuatro módulos** —qué conversiones hacen falta, cuáles se repiten, cuáles
    son específicas— y mide cuánto crece el archivo. Ese tamaño es el argumento de la fase 11 sobre
    cuánto del esquema vale la pena arreglar de verdad.
25. **Defiende una decisión.** Duván pregunta por qué hay dos formas de leer `MOVINVEN` en el mismo
    repositorio y cuál debería usar él. Respóndele por escrito, media página, con los números de la
    medición — y si tu respuesta es "dos formas está bien", explica cómo evitas que en dos años haya
    cuatro.

**🔥 Opcionales**

- Investiga los generadores de consultas compiladas de EF Core (`EF.CompileAsyncQuery`) y mide si aportan
  algo en la consulta de catálogo. Anota el resultado para la fase 20, donde AOT lo va a volver relevante.
- Escribe el mismo borde con un generador de origen que produzca el mapeo a partir del DDL. **No lo
  integres**: anota cuánto código eliminaría y qué riesgo introduce.
- Prueba `Microsoft.Data.SqlClient` con `AccessToken` en vez de usuario y contraseña. Guárdalo: es
  literalmente lo que la fase 16 necesita.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://learn.microsoft.com/ef/core/modeling/` — modelado con la API fluida, que es lo que este curso
  usa en vez de atributos.
- `https://learn.microsoft.com/ef/core/modeling/value-conversions` — `HasConversion`, donde vive la
  mitad del borde 🧬.
- `https://learn.microsoft.com/ef/core/querying/filters` — filtros globales **y sus advertencias**. La
  sección de limitaciones es la lectura del miniproyecto.
- `https://learn.microsoft.com/ef/core/querying/tracking` — seguimiento y `AsNoTracking`, con lo que
  cuesta cada uno.
- `https://learn.microsoft.com/ef/core/querying/sql-queries` — `FromSql`, y qué **no** se aplica a una
  consulta cruda.
- `https://learn.microsoft.com/ef/core/modeling/keyless-entity-types` — entidades sin clave, para la
  vista de las treinta tablas.
- `https://learn.microsoft.com/ef/core/logging-events-diagnostics/simple-logging` — ver el SQL que se
  genera de verdad.
- `https://github.com/DapperLib/Dapper` — Dapper: la documentación cabe en una página, y eso es parte
  de su argumento.
- `https://learn.microsoft.com/sql/relational-databases/views/views` — vistas, y cuándo el motor puede
  usar sus índices.

**Libros / artículos**

- *Refactoring Databases*, de Ambler y Sadalage, es el catálogo de cómo se cambia un esquema en
  producción por partes. Es la preparación de la fase 10 y de la 11; verifica edición antes de citarlo.

> ⚠️ Verifica las URLs, y **fija la versión en el selector de learn.microsoft.com**: la documentación de
> EF Core cambia entre versiones mayores y varias de estas páginas tienen diferencias reales entre EF
> Core 8, 9 y 10. Y la advertencia grande de esta fase: **casi todo el material sobre "Entity Framework
> con base de datos existente" es de EF 6 o anterior**, donde la respuesta era generar el modelo con un
> diseñador y un archivo `.edmx`. Eso no existe en EF Core, y buscar esa respuesta te va a llevar a
> 2013.

**Orden de lectura sugerido:** antes de escribir, la página de conversiones de valor y la de filtros
globales completa —con sus advertencias, que son la mitad de la fase—. Durante el miniproyecto, la de
consultas crudas y la de entidades sin clave. Al cerrar, la de seguimiento: se lee distinto cuando ya
tienes la columna de asignaciones delante.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Existe el borde, y existe en un solo archivo. `VLRUNIT` y `UnitPrice` conviven sin que ninguno invada el
territorio del otro, y las cuatro rarezas del esquema están resueltas donde se pueden mantener. Se
cobraron tres deudas del Bloque A **en el mismo sitio**, que era el argumento: un borde concentrado es
más barato que tres decisiones dispersas. Y hay una tabla que dice, con números, cuál de las tres
herramientas conviene aquí — incluida la posibilidad de que la respuesta honesta sea "una sola, aunque
no gane en ninguna fila".

También hay algo que no estaba en el plan de la fase y que conviene mirar: las fotos de la fase 08
**sirvieron**. El `Include` que perdía 1.900 filas se atrapó antes de producción, y eso es el retorno
concreto de haber puesto la red primero.

La fase 10 es el paso natural y es la ⭐ que da nombre a la tesis del curso. Hasta ahora se leyó, se
midió y se mapeó — pero **el cliente WinForms sigue escribiendo directo a la base con permiso sobre
todo**, y mientras eso sea cierto, todo lo demás es cosmético. La 10 pone una API en medio **sin apagar
nada**: doble escritura, bandera de corte por funcionalidad, conciliación, y una vuelta atrás que **se
ejecuta de verdad** y no se describe. Y el orden de los cortes no lo decide la arquitectura: lo decide
el riesgo del negocio, y lo firma Clara.

> **La señal de que quedó bien:** *"Puedo decir en qué archivo vive cada rareza del esquema, y cuando el
> reporte nuevo no cuadra con el viejo, sé si es un error mío o una decisión que alguien tiene que
> tomar."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el miniproyecto
> corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-09 -m "F9 cerrada:
> - el borde 🧬 en un solo archivo: char(8), char(10), BORRADO y la moneda
> - MOVINVEN mapeado y cuadrando con SP_EXIST_ALMACEN en 4.300 filas
> - las cinco implementaciones medidas, con el plan de consulta antes
> - filtro global de BORRADO configurado y sus tres agujeros probados
> - V_VENTAS: las treinta tablas consultables sin concatenar cadenas
> - deudas de la F02 (dos !) y de la F03 (IQueryable) cobradas"
> ```
>
> **Esta es la fase que más deudas cobra hasta ahora, y las tres facturas se leen juntas:**
>
> ```bash
> git diff fase-02 fase-09 -- src/fases/02-nullable-y-pattern-matching/
> git diff fase-03 fase-09 -- src/modern/Cordillera.Domain/CatalogQueries.cs
> git diff fase-07 fase-09 -- src/legacy/Sige.DataAccess/
> ```
>
> La tercera es la interesante y es **vacía a propósito**: la deuda del `DataSet` de la fase 07 **no se
> cobró tocando `Sige.DataAccess`**, se cobró construyendo la alternativa al lado y midiéndola. Un diff
> vacío donde uno esperaba un cambio es la forma que tiene este curso de decir *"se envuelve, no se
> migra"* — y el ejercicio 20 te pide defenderlo.

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura.*

- **`INSTINTOS.md`** — dos entradas en la familia *datos y esquema*: "EF Core es Hibernate y el ORM me
  abstrae del esquema", y el `Include` que cuadra distinto —que merece entrada propia porque el
  mecanismo es específico y el síntoma es una diferencia **pequeña** en un total, que es lo que lo hace
  difícil—. La primera necesita la frase que la resume: **un ORM te abstrae del SQL, no del esquema**.
- **`BENCHMARKS.md`** — entrada ⏳ *F09 · Cinco mapeadores y el predicado no traducible*, con dos tablas.
  La tabla B **cierra el acoplamiento declarado con la F03** (§8.1 de la propuesta) y conviene que el
  índice lo diga, para que se vea que la promesa se cumplió.
- **Deudas 💸 cobradas: tres.** Los dos `!` de la F02 y el `IQueryable` de la F03. Y una cuarta que se
  cobró **sin código**: el `DataSet` de la F07, resuelto construyendo la alternativa al lado. Conviene
  anotar en el libro de §7.1 que esa factura es un **diff vacío a propósito**, porque es el primer sitio
  del curso donde "se envuelve" es la respuesta y hay que poder mostrarlo.
- **Tipos nuevos para el congelamiento:** `CatalogEntry`, `CatalogRow`, `SigeContext`,
  `LegacyBoundary`, `InventoryMovementConfiguration`, `ReconciliationResult`, y la vista `V_VENTAS`.
  `CatalogEntry` es el que importa: es el tipo de lectura que la F01 aplazó, y la F15 lo va a necesitar
  para el contrato público.
- **Para la fase 10:** el ejercicio 19 —comparar la escritura con EF Core contra `SP_MOVINVEN_INS`— es
  el planteamiento de la doble escritura. Y el `ReconciliationResult` del miniproyecto es el germen de la
  conciliación que la 10 necesita.
- **Para la fase 11:** el ejercicio 24 mide cuánto crece el borde si se hace para los cuatro módulos
  completos. Ese número es el argumento de la 11 sobre cuánto del esquema vale la pena arreglar **de
  verdad** frente a cuánto conviene seguir traduciendo.
- **Para la fase 12:** el umbral (3) —a partir de qué tamaño de resultado el `DataSet` deja de ser
  tolerable— es entrada directa de la decisión sobre la grilla de 50.000 filas.
- **Para la fase 15:** la caché se aplazó a propósito y está anotado en la sección 3. Si la 15 la
  introduce sin citar los números de aquí, se pierde la comparación.
- **Riesgo detectado:** esta fase asume que las fotos de la F08 cubren `SP_EXIST_ALMACEN` con el total de
  Lima. La F08 lo tiene como ejercicio 2, no como parte de su miniproyecto. Conviene moverlo al
  checklist de la F08 o el criterio 2 de este miniproyecto no tiene contra qué compararse.
