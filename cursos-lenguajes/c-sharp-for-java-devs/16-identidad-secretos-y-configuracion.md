# 🔐 Fase 16 — Identidad, secretos y configuración

> C# para desarrolladores Java senior · Fase 16 de 24 · Bloque D — servicios, datos y nube
> Depende de: 15 · Habilita: 17
> Estilo de esta fase: **nuevo** (.NET 10, C# 14)
> Proyecto que avanza: **CatalogAPI**. Al terminar, ni el servicio ni el cliente tienen un secreto en disco,
> y los noventa `App.config` dejaron de ser un problema de seguridad.

---

## 🎯 1. Propósito

Cobrar **la deuda más antigua del curso**, y conviene recordar cómo se plantó porque el cobro se entiende
mejor así. En la fase 07, el `App.config` de SIGE llevaba esto:

```xml
<add name="SigeConnection"
     connectionString="Data Source=SRVSQL01;Initial Catalog=SIGE;User ID=sigeapp;Password=Sige2017*;Connect Timeout=120" />
```

Texto plano. Un usuario con permiso de escritura sobre todo. **Copiado tal cual a noventa instalaciones**. Y
la razón por la que esa contraseña es de 2017 no es negligencia: es que cambiarla significa visitar noventa
equipos, y nadie ha tenido dos semanas para eso.

Esta fase hace que **ni el servicio ni el cliente tengan un secreto en disco**, con **una sola ruta de
código** entre el equivalente local y el gestor de verdad. Y resuelve la otra mitad del problema: la tabla de
usuarios de 2017, con su hash que da pena, y el paso incómodo de migrar contraseñas que nadie puede leer.

> 🧭 **La regla de la fase:** *un secreto que está en un archivo ya se filtró, solo que todavía no te
> enteraste.* Está en noventa discos, en el respaldo de esos discos, en el repositorio si alguien lo
> commiteó, y en el correo donde alguien lo mandó una vez. La pregunta no es cómo protegerlo mejor: es **cómo
> dejar de tenerlo**.

---

## ✅ 2. Qué queda listo al terminar

- [ ] 💸 **Se cobra la deuda de la fase 07.** La cadena de conexión **no está en ningún `App.config`**, y
      `git diff fase-07 fase-16 -- src/legacy/Sige.DataAccess/App.config` lo demuestra.
- [ ] El servicio **arranca sin ningún secreto en disco**: ni en `appsettings`, ni en variables de entorno
      escritas a mano, ni en el repositorio.
- [ ] Hay **una sola ruta de código** entre el equivalente local de desarrollo y el gestor de secretos real.
      Si hay dos, la fase no está cerrada.
- [ ] La API valida tokens y autoriza **por política**, no por rol pegado a cada endpoint, y los endpoints
      que la fase 15 dejó anónimos ahora lo están **a propósito y declarado**.
- [ ] La configuración está **tipada y validada al arrancar**: una clave que falta **impide el arranque** en
      vez de producir un `null` en la petición número cuatrocientos.
- [ ] Está decidido y escrito qué se hace con la **tabla de usuarios de 2017**, incluido el plan de migración
      de contraseñas que nadie puede leer.
- [ ] Está cerrado el inventario de **qué se emula y qué se declara** para esta fase, sin improvisar: OIDC en
      contenedor, secretos con el equivalente local, y el costo de Entra ID **estudiado con su precio**.
- [ ] La medición de la sección 6 está escrita con su comando, y la entrada quedó en `BENCHMARKS.md`.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Federación con el directorio del socio.** Declarado fuera: que Almenara autentique a sus empleados contra
  su propio directorio y Cordillera confíe en él es un proyecto conjunto entre dos áreas de sistemas, y el
  curso no lo simula. Lo que sí entra es **cómo se autentica Almenara como organización**.
- **El costo total de identidad en la nube** → fase 20, con el resto de la factura. Aquí cada pieza declara su
  precio; la suma y la comparación con las alternativas son de allí.
- **Auditoría de quién vio qué** → fase 19, y es deuda de la 18.
- **Rotación automatizada con su proceso de operación** → se implementa la rotación, y el proceso programado
  que la ejecuta es de la fase 17.
- **Cifrado de datos en reposo y en tránsito más allá de lo que el servicio necesita.** Fuera: es
  configuración de infraestructura y el curso no tiene infraestructura hasta la fase 20.

---

## 🧠 4. Concepto mínimo

### Las tres cosas distintas que esta fase junta

Se confunden todo el tiempo y se resuelven de formas distintas, así que conviene separarlas de entrada:

**Configuración** es lo que cambia entre ambientes y **no es secreto**: la URL del servicio, el tamaño de
página por omisión, el tiempo de espera. Vive en archivos, se versiona, y el problema que tiene es de
**composición**: qué gana cuando dos fuentes dicen cosas distintas.

**Secretos** son lo que no puede estar en un archivo: contraseñas, cadenas de conexión, claves de firma. El
problema que tienen no es de composición sino de **custodia**: quién los tiene, quién los puede leer, y qué
pasa cuando hay que cambiarlos.

**Identidad** es quién está al otro lado: una persona del back-office, un socio comercial, o un proceso.
Su problema es de **confianza**: en quién confías para que te diga quién es alguien, y qué haces con esa
afirmación.

Las tres se juntan aquí por una razón práctica: **las tres se resuelven en el arranque del servicio**, y las
tres tienen la misma propiedad — si algo falta, es mejor que el servicio no arranque que que falle en la
petición cuatrocientos.

### El modelo de configuración: composición ordenada

ASP.NET Core compone la configuración de varias fuentes, **en orden**, y la última gana. El orden por omisión
es este, y es casi todo lo que hay que saber:

```text
1. appsettings.json                     ← se versiona. Nada secreto.
2. appsettings.{Environment}.json       ← se versiona. Nada secreto. Y ojo con esto (sección 5.4).
3. secretos de usuario                  ← SOLO en desarrollo. Fuera del repositorio, en el perfil del usuario.
4. variables de entorno                 ← lo que el contenedor o el servicio inyecta.
5. argumentos de línea de comandos      ← lo último, para depurar.
```

Y **la pieza que hace posible el objetivo de la fase**: un proveedor de configuración es una interfaz, así
que se puede agregar uno que lea de un gestor de secretos. Cuando eso pasa, **el código que consume la
configuración no cambia** — sigue pidiendo `configuration["Sige:ConnectionString"]` — y de dónde sale es un
detalle del arranque.

Eso es la "una sola ruta de código" del checklist, y es literal: en desarrollo el valor viene de los secretos
de usuario, en producción del gestor, **y el código que lo usa es el mismo**. La alternativa —un `if` que
decide de dónde leer según el ambiente— es el error que esta fase existe para no cometer, porque significa
que el camino de producción **nunca se ejerce en desarrollo**.

### Identidad: qué es un token y qué garantiza

El lector conoce OAuth 2 y OIDC, así que aquí solo va lo que decide código:

Un token de acceso es **una afirmación firmada por alguien en quien confías**. Tu servicio no valida
contraseñas: valida una firma, y de ahí saca quién es el portador y qué puede hacer. Validar esa firma
requiere la clave pública del emisor, y esa clave **se descarga y se cachea** — porque descargarla en cada
petición es lo que la medición de la sección 6 mide.

Y la autorización tiene dos formas, y una escala y la otra no:

```csharp
// ❌ Rol pegado a cada endpoint. Con doce endpoints funciona; con ciento veinte, cada cambio de
//    política de la empresa es un recorrido por ciento veinte archivos.
app.MapGet("/v1/editions", GetEditions).RequireAuthorization(policy => policy.RequireRole("Partner"));

// ✅ Política con nombre. La regla vive en un sitio, los endpoints la citan, y cambiarla es una línea.
app.MapGet("/v1/editions", GetEditions).RequireAuthorization("ReadCatalog");
```

> 🧠 **El modelo mental:** un token es **un pase con fecha firmado por una autoridad**. Tu servicio no
> pregunta quién eres: comprueba que el pase es auténtico y lee lo que dice. De ahí salen las dos cosas que
> hay que decidir: **en qué autoridad confías** —y cuántas— y **qué haces con un pase válido cuyo portador no
> tiene permiso**, que es un `403` y no un `401`.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**Primera: la cadena de conexión en el archivo de configuración.**

Es el reflejo de once años de `application.properties`, y **no es un reflejo de Java**: es un reflejo de la
industria entera, y todavía es la forma más común de desplegar un servicio.

```properties
# ❌ Lo que hay en la mitad de los repositorios del mundo. Y en los noventa equipos de Cordillera.
spring.datasource.url=jdbc:sqlserver://SRVSQL01;databaseName=SIGE
spring.datasource.username=sigeapp
spring.datasource.password=Sige2017*
```

**Por qué falla, y son tres razones que no se ven hasta que pasan:**

1. **Un secreto en un archivo está en todas las copias del archivo.** Noventa discos, el respaldo de esos
   discos, la imagen del equipo que sistemas clona para el empleado nuevo, y el correo donde alguien lo mandó
   en 2019. **No hay forma de saber cuántas copias hay.**
2. **No se puede rotar.** Cambiar la contraseña significa cambiar noventa archivos, y por eso la de 2017
   sigue siendo la de 2026. La imposibilidad de rotar **es** el problema de seguridad, más que el texto plano.
3. **Y no se puede auditar.** ¿Quién leyó esa cadena? Nadie lo sabe, porque leer un archivo no deja rastro.

```csharp
// ✅ El servicio pide la configuración y no sabe de dónde viene. En desarrollo, de los secretos de
//    usuario; en producción, del gestor. Una ruta de código, dos orígenes.
builder.Configuration.AddAzureKeyVault(vaultUri, credential);   // en producción
// … y en desarrollo, `dotnet user-secrets`, que el SDK ya compuso en el orden de arriba.

// Y el consumo, idéntico en los dos casos:
string connectionString = builder.Configuration.GetConnectionString("Sige")
    ?? throw new InvalidOperationException("Falta la cadena de conexión.");
```

**Dónde se rompe el paralelo:** Spring tiene `spring-cloud-config` y Jasypt para lo mismo, así que la idea se
transfiere. Lo que cambia es que en .NET **el proveedor de configuración es parte del marco** y no una
dependencia aparte: agregar el gestor de secretos es una línea en el arranque, y el resto del código no
distingue. Eso hace mucho más fácil cumplir la regla de la ruta única.

**Segunda: el filtro de seguridad casero.**

```csharp
// ❌ Lo que escribió alguien en SIGE en 2019 para "asegurar" los ASMX, y lo que se escribe cuando
//    uno cree que la autenticación es una comprobación más.
app.Use(async (context, next) =>
{
    string? key = context.Request.Headers["X-Api-Key"];

    if (key != "almenara-2019-clave-compartida")   // ← y está en el código
    {
        context.Response.StatusCode = 401;
        return;
    }

    await next();
});
```

**Cuatro problemas, y los cuatro son de diseño y no de implementación:** la clave está en el código, así que
está en el repositorio y en el historial; **es la misma para todos los consumidores**, así que no se puede
revocar a uno sin revocar a todos; no dice **quién** es el portador, solo que conoce la clave; y no caduca,
así que si se filtra es para siempre.

```csharp
// ✅ La autenticación delegada a quien sabe hacerla, y la autorización por política.
builder.Services.AddAuthentication()
    .AddJwtBearer(options =>
    {
        options.Authority = builder.Configuration["Identity:Authority"];
        options.Audience = "cordillera.catalog";
        // Y la clave de firma NO se configura: se descarga del emisor y se cachea. Eso es lo que
        // la medición de la sección 6 mide, y la razón por la que hay que pensarlo.
    });

builder.Services.AddAuthorization(options =>
{
    // La política, en un sitio. Los endpoints la citan por nombre.
    options.AddPolicy("ReadCatalog", policy => policy
        .RequireAuthenticatedUser()
        .RequireClaim("scope", "catalog.read"));
});
```

**Dónde se rompe el paralelo:** el razonamiento de Spring Security se transfiere entero —filtros, cadena,
autoridades— con una diferencia de vocabulario que importa: en .NET las afirmaciones se llaman *claims* y la
autorización se expresa como **políticas con nombre** en vez de expresiones en anotaciones. Y hay algo que
Spring Security hace y .NET no: **no hay una configuración por omisión que asegure todo**. Si un endpoint no
pide autorización, es anónimo. Por eso el checklist exige que los anónimos lo estén **declarado**.

### 🩻 Esto sí funciona igual

OAuth 2 y OIDC, completos. Flujos, tokens, `scope`, el token de refresco, el descubrimiento del emisor, la
validación de la firma, los tiempos de expiración: todo eso vale aquí igual y el curso no lo explica. Si
configuraste un servidor de recursos con Spring Security, la conversación es la misma con otros nombres.

También se transfiere el criterio de **qué va en un token y qué no**: que un token no es un contenedor de
datos del usuario, que crece y viaja en cada petición, y que meter ahí la lista de permisos de alguien con
cuarenta roles es cómo se acaba con cabeceras de ocho kilobytes.

Y la disciplina de **validar la configuración al arrancar**, que probablemente ya tengas de Spring Boot con
`@ConfigurationProperties` y `@Validated`. Aquí el mecanismo es `IOptions` con validación, y la propiedad
importante es la misma: **fallar al arrancar es mejor que fallar en la petición cuatrocientos**.

### 📖 Diccionario de traducción

| Java / Spring | .NET | Dónde se rompe el paralelo |
|---|---|---|
| `application.properties` / `.yml` | `appsettings.json` | La composición de fuentes es **explícita y ordenada**, y agregar una fuente es una línea |
| perfiles (`spring.profiles.active`) | `ASPNETCORE_ENVIRONMENT` + `appsettings.{Env}.json` | Mismo concepto; el nombre del ambiente es una cadena libre y `Development` tiene comportamiento especial |
| `@ConfigurationProperties` + `@Validated` | `IOptions<T>` + `ValidateOnStart` | **Hay que pedir `ValidateOnStart`**: sin él la validación ocurre en el primer uso, no al arrancar |
| `@Value("${clave}")` | `IConfiguration["clave"]` o `IOptions<T>` | El curso usa `IOptions<T>`: tipado, validable y comprobable sin el contenedor |
| Jasypt / `spring-cloud-config` | proveedor de configuración + gestor de secretos | **El proveedor es parte del marco**: el código que consume no distingue de dónde viene |
| — | `dotnet user-secrets` | **No tiene equivalente directo.** Guarda secretos de desarrollo fuera del repositorio, en el perfil del usuario, sin configurar nada |
| Spring Security con su cadena de filtros | middleware de autenticación y autorización | Equivalente. Y **no hay aseguramiento por omisión**: lo que no pide autorización es anónimo |
| `GrantedAuthority` / `hasRole()` | *claims* / `RequireClaim` | Un rol es un *claim* más. Las políticas con nombre son la unidad, y escalan mejor que la anotación por endpoint |
| `@PreAuthorize("hasRole('X')")` | `.RequireAuthorization("PolicyName")` | La regla vive en un sitio y el endpoint la cita. Cambiarla es una línea, no ciento veinte |
| `401` contra `403` | igual | Y el error clásico es el mismo: devolver `401` cuando el token es válido y el permiso falta |
| `BCryptPasswordEncoder` | `PasswordHasher<T>` de ASP.NET Core Identity | Equivalente en propósito; aquí el algoritmo por omisión es PBKDF2 con iteraciones configurables |
| Keycloak en un contenedor para desarrollo | **un proveedor OIDC en contenedor** | Es exactamente lo que este curso hace (`alcance-del-proyecto.md` §10.1), y la experiencia se transfiere |

> ⚠️ **La fila de `ValidateOnStart` merece atención porque es la diferencia entre esta fase y un fallo en
> producción.** `IOptions<T>` con anotaciones de validación **no valida al arrancar por omisión**: valida la
> primera vez que alguien pide las opciones, que puede ser en la petición número cuatrocientos y a las tres
> de la mañana. Agregar `.ValidateOnStart()` mueve ese fallo al arranque, donde el despliegue lo detecta.
> Es una línea y casi nadie la escribe.

> 📝 **Nota de ecosistema, y es la que explica el estado del sistema heredado.** El modelo de configuración de
> .NET moderno —fuentes compuestas, `IOptions`, proveedores— **no existía en .NET Framework**: allí había
> `ConfigurationManager` leyendo un `App.config` con secciones XML, y eso es todo. Por eso la cadena de SIGE
> está donde está: en 2017 **no había otro sitio razonable donde ponerla** sin escribir infraestructura
> propia. La fase 11 ya encontró la otra cara de esto —`ConfigurationManager` compila en .NET 10 y devuelve
> `null` en silencio— y ahora se ve por qué: no es que la API se rompiera, es que **el modelo entero cambió**.

---

## 💻 5. Código mínimo con comentarios

### 5.1 El cobro: la cadena sale de los noventa equipos

```xml
<!-- src/modern/Sige.Forms/App.config — DESPUÉS
     💸 Cobro de la deuda de la fase 07, y es el más viejo del curso.
     La factura: git diff fase-07 fase-16 -- src/legacy/Sige.DataAccess/App.config -->
<configuration>
  <appSettings>
    <!-- Lo que queda: configuración que NO es secreta. La URL de la API, que ya no es la base. -->
    <add key="CatalogApiUrl" value="https://catalogo.cordillera.local" />
    <add key="AmbienteSige" value="PRODUCCION" />
  </appSettings>

  <!-- Y aquí está el cobro: la sección connectionStrings ya no existe.
       El cliente **no habla con la base de datos**: habla con la API de la fase 10, que se
       autentica con la identidad del usuario de Windows. Noventa equipos dejaron de tener
       credenciales de escritura sobre todo, y el corte de la fase 10 es lo que lo hizo posible. -->
</configuration>
```

**Y conviene decir en voz alta por qué este cobro funcionó**, porque es el argumento del Bloque B entero:

> 🧭 **La cadena de conexión no salió de los noventa equipos por una decisión de seguridad: salió porque la
> fase 10 cortó la conexión directa a la base.** Mientras el cliente hablara con SQL Server, **tenía que
> tener credenciales** — se pueden proteger mejor, cifrar, mover a un almacén del sistema operativo, pero
> tienen que estar ahí. El problema no era dónde estaba el secreto: era **que hiciera falta un secreto**.
>
> Y ese es el patrón general, y vale más que la técnica de esta fase: **la mejor forma de proteger un
> secreto es no necesitarlo.**

### 5.2 Una sola ruta de código, dos orígenes

```csharp
// src/modern/Cordillera.Catalog.Api/Program.cs
var builder = WebApplication.CreateBuilder(args);

// La composición de fuentes. El SDK ya agregó appsettings, el del ambiente, los secretos de usuario
// en desarrollo, las variables de entorno y los argumentos — en ese orden. Aquí se agrega **una**
// fuente más, y solo cuando hay un gestor configurado.
if (builder.Configuration["Secrets:VaultUri"] is { } vaultUri)
{
    // En producción esto apunta al gestor real; en el contenedor de desarrollo, al emulador
    // declarado en el inventario (`alcance-del-proyecto.md` §10.1). Y en la máquina de un
    // desarrollador **no está configurado**, así que esta línea no se ejecuta y los secretos
    // vienen de `dotnet user-secrets`.
    //
    // Lo importante es lo que NO hay: ningún `if (env.IsDevelopment())` decidiendo de dónde leer.
    // La diferencia está en qué fuentes hay disponibles, no en dos caminos de código — porque un
    // camino que solo se ejerce en producción es un camino sin probar.
    builder.Configuration.AddSecretsProvider(new Uri(vaultUri), builder.Environment);
}

// La configuración tipada, validada, y validada **al arrancar**.
builder.Services.AddOptions<SigeOptions>()
    .Bind(builder.Configuration.GetSection(SigeOptions.Section))
    .ValidateDataAnnotations()
    .ValidateOnStart();          // ← la línea que casi nadie escribe y que mueve el fallo al arranque

WebApplication app = builder.Build();
```

```csharp
// src/modern/Cordillera.Catalog.Api/Configuration/SigeOptions.cs
/// <summary>
/// La configuración del servicio, tipada. Se puede instanciar y validar en una prueba sin levantar
/// el contenedor — es la misma propiedad que el modelo de vista de la fase 13.
/// </summary>
public sealed class SigeOptions
{
    public const string Section = "Sige";

    /// <summary>
    /// La cadena de conexión. Viene del gestor de secretos o de los secretos de usuario, **nunca de
    /// un archivo versionado**, y si falta el servicio no arranca.
    /// </summary>
    [Required(AllowEmptyStrings = false)]
    public string ConnectionString { get; init; } = string.Empty;

    [Required]
    [Url]
    public string IdentityAuthority { get; init; } = string.Empty;

    [Range(1, 200)]
    public int DefaultPageSize { get; init; } = 50;

    /// <summary>
    /// Cuánto se cachean las claves públicas del emisor. Es el parámetro que la medición de la
    /// sección 6 barre, y el valor por omisión del marco es razonable — el punto es saber que
    /// existe, porque el día que el emisor rote sus claves, este número es cuánto tarda el servicio
    /// en darse cuenta.
    /// </summary>
    [Range(1, 1440)]
    public int SigningKeyCacheMinutes { get; init; } = 60;
}
```

**Detalles con intención**

- **No hay un `if` por ambiente.** Es la regla del checklist y el motivo es concreto: un camino de código que
  solo se ejerce en producción es un camino sin probar, y se descubre roto en el despliegue.
- **`ValidateOnStart` es explícito**, porque sin él la validación ocurre en el primer uso. La diferencia es
  entre un despliegue que falla y un `500` a las tres de la mañana.
- **El tiempo de caché de las claves está en la configuración y documentado.** No para ajustarlo: para que
  cuando el emisor rote sus claves, alguien sepa dónde mirar.

### 5.3 Identidad: dos clases de consumidor, dos políticas

Cordillera tiene dos tipos de cliente y no se autentican igual, y confundirlos es el error de diseño de esta
fase:

```csharp
// src/modern/Cordillera.Catalog.Api/Security/AuthorizationSetup.cs
builder.Services.AddAuthorization(options =>
{
    // 1. El back-office: personas de Cordillera. Nohora, Ximena, Duván. Se autentican con la
    //    identidad corporativa y sus permisos vienen de sus grupos.
    options.AddPolicy("EditorialStaff", policy => policy
        .RequireAuthenticatedUser()
        .RequireClaim("groups", "cordillera-editorial", "cordillera-sistemas"));

    // 2. Los socios comerciales: Almenara y los otros tres. **No son personas**: son organizaciones
    //    con un proceso que llama a la API cada hora. Se autentican como cliente, no como usuario,
    //    y su permiso es un `scope` y no un grupo.
    options.AddPolicy("ReadCatalog", policy => policy
        .RequireAuthenticatedUser()
        .RequireClaim("scope", "catalog.read"));

    // Y la política que hace explícito lo que la fase 15 dejó anónimo: el volcado completo sigue
    // siendo público durante la transición del CSV, **y está declarado**. No es un olvido: es una
    // decisión con fecha, y la fase 20 la va a cobrar en pesos junto con la paginación.
    options.AddPolicy("PublicDuringCsvTransition", policy => policy.RequireAssertion(_ => true));
});
```

```csharp
// Y en los endpoints, la política por nombre. Cambiar la regla es una línea, no ciento veinte.
v1.MapGet("/editions", GetEditions).RequireAuthorization("ReadCatalog");
v1.MapGet("/editions/{isbn}", GetEdition).RequireAuthorization("ReadCatalog");
v1.MapGet("/editions/all", GetAllEditions).RequireAuthorization("PublicDuringCsvTransition");
```

**El patrón a memorizar**

> **Una persona y un proceso no se autentican igual, y tratarlos igual es el error que produce una clave
> compartida.** Una persona tiene una sesión, un segundo factor y una baja el día que se va de la empresa. Un
> proceso tiene una credencial de cliente, no tiene sesión, y su baja es revocar esa credencial. **Si los dos
> usan el mismo mecanismo, el que sobra es el de la persona** — y el resultado es una cuenta de servicio con
> contraseña que alguien anota en un correo.

### 5.4 La tabla de usuarios de 2017, y el paso incómodo

```sql
-- Lo que hay, de la fase 07:
CREATE TABLE USUARIOS (
  CODUSUA  char(10)     NOT NULL,
  NOMBRE   varchar(60)  NULL,
  CLAVE    varchar(32)  NULL,   -- MD5 sin sal. 32 caracteres hexadecimales.
  ROL      char(2)      NULL,
  BORRADO  char(1)      NULL
);
```

**MD5 sin sal** significa tres cosas concretas: se puede revertir con una tabla precalculada para cualquier
contraseña común, dos usuarios con la misma contraseña tienen el mismo hash —así que se ve a simple vista
quién comparte contraseña—, y **no se puede migrar a un algoritmo mejor sin la contraseña original**, que
nadie tiene.

Y aquí está el paso incómodo, que es la parte que los tutoriales omiten:

```text
Las cuatro formas de migrar contraseñas que no se pueden leer, con su costo real:

  a) Forzar restablecimiento a los 90 usuarios
     → Dos días de soporte, y funciona. Es lo que hace la mayoría, y es lo correcto aquí.

  b) Rehashear en el próximo inicio de sesión
     → Elegante: cuando el usuario entra, tienes la contraseña en claro un instante y la
       vuelves a hashear bien. Pero deja el MD5 vivo indefinidamente para quien no entre —y en
       Cordillera hay cuentas que no se usan desde 2021—, así que hay que ponerle fecha de corte.

  c) Rehashear el hash: PBKDF2 sobre el MD5 existente
     → Compatible sin tocar al usuario, y **no arregla el problema**: la entropía sigue siendo la
       del MD5 original. Sirve como medida transitoria y hay que decir que es transitoria.

  d) Migrar a identidad corporativa y borrar la tabla
     → Es la respuesta de esta fase, y la que el curso elige: las noventa personas ya tienen una
       cuenta corporativa. La tabla de usuarios de 2017 **no se migra: se jubila.**

Y la decisión, escrita: (d) para las personas, con (a) como camino para las cuatro cuentas de
servicio que no son personas — que pasan a ser credenciales de cliente, no usuarios.
```

> 💸 **Lo que esta fase NO resuelve y declara:** la tabla `USUARIOS` **no se borra**, porque
> `SP_FACTURA_EMITIR` y tres procedimientos más escriben `CODUSUA` como campo de auditoría, y borrar la tabla
> rompería la integridad referencial que nadie declaró pero que el código asume. Se queda **sin la columna
> `CLAVE`** —esa sí se borra, y es el cambio de esquema más satisfactorio del curso— y con las filas como
> registro histórico de quién hizo qué.
>
> Es el único cambio de esquema que el curso hace en las veinticinco fases, y por eso conviene notarlo: **no
> se hizo para mejorar el diseño, se hizo porque una columna con noventa hashes MD5 es un riesgo**. Ese es el
> criterio para tocar un esquema de 1997.

### 5.5 El archivo que sí se commiteó

```powershell
# La trampa de esta fase, que ya ocurrió en la mitad de los repositorios del mundo:
git log --all --full-history -- "**/appsettings.Development.json"
```

Si ese comando devuelve algo con una contraseña adentro, **el secreto está comprometido y quitarlo del último
commit no sirve de nada**: está en el historial, en cada clon, y en el respaldo del servidor de git.

```text
Qué se hace, en este orden y sin saltarse el primero:

  1. ROTAR el secreto. Primero. Antes de tocar el historial, antes de avisar a nadie. Un secreto
     filtrado es un secreto que hay que cambiar, y todo lo demás es limpieza cosmética.
  2. Quitarlo del código y del archivo, y mover el valor al gestor.
  3. Decidir si se reescribe el historial. Y la respuesta honesta casi siempre es NO:
     reescribir el historial de un repositorio compartido obliga a que todos vuelvan a clonar,
     rompe las referencias de los tags —incluidos los `fase-NN` de este curso— y **no elimina las
     copias que ya existen**. Si el secreto ya se rotó, el valor del historial es cero.
  4. Agregar el archivo al `.gitignore` y una comprobación en CI que rechace el patrón.

Y el paso que casi nadie da: 5. escribir en qué otro sitio estaba ese secreto. Si estaba en el
`appsettings`, probablemente también está en un correo, en un ticket, y en el portapapeles de
alguien.
```

**Prueba de fuego**

```powershell
# El servicio tiene que arrancar sin secretos y fallar ruidosamente.
$env:Sige__ConnectionString=""
dotnet run --project src\modern\Cordillera.Catalog.Api
# Debe fallar AL ARRANCAR con: "El campo ConnectionString es obligatorio." — no en la primera
# petición, y no con un NullReferenceException.

# Y la comprobación del checklist:
git grep -n "Password=" -- "*.json" "*.config" "*.cs"
```

Y la mentira que te va a contar la salida si miras el lugar equivocado: **el servicio va a arrancar
perfectamente en tu máquina con los secretos de usuario configurados**, y eso no prueba nada sobre
producción. Lo que hay que comprobar es lo contrario: **que arranque en un entorno limpio, sin secretos, y
falle con un mensaje que diga qué falta**. Un servicio que arranca en tu máquina y no en el servidor es el
resultado normal de esta fase mal hecha.

---

## 📏 6. Medición

**Hipótesis:** validar un token exige la clave pública del emisor, y **descargarla en cada petición** —en vez
de cachearla— convierte una operación de microsegundos en una llamada de red por petición. La diferencia tiene
que ser de órdenes de magnitud, y el número importa por una razón concreta: es el argumento de por qué el
tiempo de caché de claves es una decisión y no un detalle.

**Condiciones:** SDK 10.0.401 · Release · Windows 11 · el proveedor OIDC en contenedor —el emulador declarado
en `alcance-del-proyecto.md` §10.1— sobre WSL 2 · **200 peticiones concurrentes durante 60 segundos**, que es
el barrido donde la fase 05 encontró el codo · tokens firmados con RSA, que es lo habitual · 20 repeticiones
con 3 de calentamiento descartadas · arnés propio.

**Competidores:** cuatro configuraciones del mismo endpoint autenticado:

- **Con caché de claves** (el comportamiento por omisión del marco). Es el camino sano.
- **Sin caché de claves**, forzando la descarga en cada validación. Es el anti-patrón, y se mide para saber
  cuánto cuesta.
- **Sin autenticación**, que es la línea base: cuánto cuesta la autenticación en sí.
- **Con el filtro casero de clave compartida** de la 🪞. No es una propuesta: es lo que hay en SIGE desde
  2019, y hay que saber cuánto "ahorra" para poder decir que el ahorro no compensa.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 16 --concurrency 200
```

**Resultado:** ⏳ pendiente de ejecución en tu máquina.

| Configuración | Throughput (req/s) | Latencia p50 | p95 | Llamadas al emisor | Asignado por petición |
|---|---|---|---|---|---|
| Con caché de claves | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Sin caché de claves | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Sin autenticación (línea base) | ⏳ | ⏳ | ⏳ | 0 | ⏳ |
| Clave compartida en cabecera (SIGE 2019) | ⏳ | ⏳ | ⏳ | 0 | ⏳ |

> ⚖️ **Veredicto** *(expectativa, todavía sin ejecutar — `formato-de-mediciones.md` §2.6)*. Se espera que la
> versión con caché quede **muy cerca de la línea base sin autenticación** —validar una firma es trabajo de
> CPU y es barato— y que sin caché la latencia se degrade por un factor grande, con una llamada al emisor por
> petición. Y se espera que **la clave compartida sea la más rápida de las cuatro**.
>
> Ese último resultado es el importante y hay que publicarlo sin adornos: **el anti-patrón gana la medición**.
> Comparar una cadena es más rápido que validar una firma, y siempre lo va a ser. Lo que la medición
> demuestra es que **la diferencia es tan pequeña que el argumento de rendimiento no existe** — y entonces la
> decisión se toma donde corresponde: en revocabilidad, caducidad, auditoría y saber quién está al otro lado.
>
> **Los dos umbrales que tu ejecución tiene que determinar:** (1) **cuánto cuesta la autenticación por
> petición**, que es el número que hay que tener a mano cuando alguien proponga quitarla "por rendimiento"; y
> (2) **cuánto tarda el servicio en reaccionar a una rotación de claves** con el tiempo de caché por omisión
> — que es el otro lado de la misma decisión y el que importa el día que el emisor rote.

---

## 🧱 7. Miniproyecto — que el servicio arranque sin un secreto en disco

**El encargo**

Wilson, y es el encargo que lleva nueve años esperando: *"La clave de `sigeapp` es de 2017 y yo sé que
debería cambiarla. No la he cambiado porque está en noventa `App.config` y cambiarla significa visitar
noventa equipos o mandar un correo pidiéndole a cada uno que abra un archivo, y eso último ya lo intenté una
vez y acabé yendo a doce escritorios. Si vas a arreglar esto, necesito dos cosas: **que se pueda cambiar sin
visitar a nadie**, y que si algún día se filtra, yo pueda saber quién la usó."*

**Por qué duele**

Porque las dos condiciones de Wilson son las dos propiedades que un secreto en un archivo **no puede tener**,
y no por estar mal guardado: por estar en un archivo. Un secreto en noventa discos no se puede rotar ni
auditar, y ninguna cantidad de cifrado lo arregla.

Y porque la solución completa depende de algo que esta fase no hizo: **el corte de la fase 10**. Si el cliente
siguiera hablando con la base, tendría que tener credenciales y lo único posible sería protegerlas mejor. Que
este encargo se pueda cumplir es el retorno del Bloque B, y conviene notarlo al entregarlo.

**Datos de entrada**

| Qué | Detalle |
|---|---|
| `App.config` en noventa equipos | Con la cadena en texto plano y `sigeapp` con escritura sobre todo |
| `USUARIOS` | 90 filas de personas con MD5 sin sal, más **4 cuentas de servicio** |
| … sin usar desde 2021 | **11 cuentas**, que siguen activas |
| Los cuatro socios comerciales | Almenara y tres más. Hoy comparten **una clave en una cabecera**, desde 2019 |
| El proveedor OIDC | En contenedor, el emulador declarado en `alcance-del-proyecto.md` §10.1 |
| El gestor de secretos | Sustituido: `dotnet user-secrets` en desarrollo, con **una sola ruta de código** hacia el real |
| Entra ID | 💲 **Solo estudiado**, con su precio por usuario al mes, fecha y región |

**Criterios de aceptación**

1. El servicio **arranca sin ningún secreto en disco** y **falla al arrancar** con un mensaje que nombra la
   clave que falta. Comprobado en un entorno limpio, no en tu máquina configurada.
2. **Una sola ruta de código** entre el equivalente local y el gestor real. Una búsqueda de
   `IsDevelopment()` en el código de configuración devuelve cero resultados.
3. La cadena de conexión **no aparece en ningún `App.config`**, y el `git diff fase-07 fase-16` lo demuestra.
4. Los cuatro socios tienen **credenciales independientes y revocables**: revocar a uno no afecta a los
   otros tres, comprobado con una prueba.
5. La columna `CLAVE` de `USUARIOS` **está borrada**, con su script de migración, y el plan para las 4 cuentas
   de servicio y las 11 sin usar está escrito.
6. Existe la respuesta a las dos preguntas de Wilson: **cómo se rota sin visitar a nadie** —con el
   procedimiento, ejecutado una vez— y **cómo se sabe quién la usó**.
7. **Medición de cierre:** las cuatro filas de la tabla, con el costo por petición de la autenticación. Van en
   el mensaje del tag `mini-16`.

**Restricciones de estilo y alcance**

Código nuevo. **Cero `if (env.IsDevelopment())` en la configuración de secretos**: la diferencia entre
ambientes está en **qué fuentes hay disponibles**, no en dos caminos de código.

El proveedor OIDC es el del contenedor y el gestor de secretos es el equivalente local — los dos están en el
inventario cerrado, y **ninguna parte del miniproyecto requiere una suscripción de pago**. Lo que no se puede
ejecutar —el precio de Entra ID por usuario al mes— se declara con su fecha y su región.

**La trampa**

Vas a configurar los secretos de usuario, el servicio va a arrancar, la autenticación va a funcionar, y vas a
estar satisfecho. Y **el `appsettings.Development.json` de tu repositorio va a tener la cadena de conexión
adentro**, porque en algún momento de la fase 15 la pusiste ahí para probar rápido.

Vas a quitarla del archivo y commitear. **Y el secreto seguirá comprometido**, porque está en el historial de
git, en cada clon que alguien haya hecho, y en el respaldo del servidor.

El primer paso no es limpiar el historial: **es rotar el secreto**. Y después viene la decisión incómoda de si
vale la pena reescribir el historial —y la respuesta casi siempre es no, porque rompe los tags `fase-NN` de
este curso, obliga a todos a volver a clonar, y **no elimina las copias que ya existen**—.

Cuando te pase, escribe los cinco pasos en orden y, sobre todo, el quinto: **en qué otros sitios estaba ese
secreto**. Si estuvo en un `appsettings`, estuvo en un correo, en un ticket y en el portapapeles de alguien.

<details><summary>Pista 1 — el enfoque</summary>

Empieza por el criterio 1 y hazlo fallar: borra tus secretos de usuario y arranca. Si el servicio arranca,
hay un valor por omisión escondido en algún sitio, y encontrarlo es la mitad del trabajo.

Para el criterio 2, la pregunta útil no es "cómo decido de dónde leer" sino **"cómo hago que el código no
tenga que decidir"**. La respuesta está en el orden de composición de fuentes.

</details>

<details><summary>Pista 2 — la herramienta</summary>

Para los secretos de desarrollo, `dotnet user-secrets` — y no tiene equivalente en Java, así que vale leer la
página:
`https://learn.microsoft.com/aspnet/core/security/app-secrets`

Para la validación al arrancar, `IOptions` con `ValidateOnStart`. **La línea que casi nadie escribe:**
`https://learn.microsoft.com/dotnet/core/extensions/options-validation`

Para la autenticación por token y la caché de claves:
`https://learn.microsoft.com/aspnet/core/security/authentication/configure-jwt-bearer-authentication`

Y para el hash de las cuentas de servicio, `PasswordHasher<T>` — que usa PBKDF2 con iteraciones
configurables, no MD5.

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```csharp
// La configuración tipada y validada. Se prueba sin contenedor.
public sealed class SigeOptions
{
    public const string Section = "Sige";
    [Required(AllowEmptyStrings = false)] public string ConnectionString { get; init; } = "";
    [Required, Url] public string IdentityAuthority { get; init; } = "";
}

// El proveedor, que se agrega **solo si hay gestor configurado** — sin un `if` por ambiente.
public static class SecretsProviderExtensions
{
    public static IConfigurationBuilder AddSecretsProvider(
        this IConfigurationBuilder builder, Uri vaultUri, IHostEnvironment environment);
}

// La rotación, que es lo que Wilson pidió: un comando, sin visitar a nadie.
internal static class SecretCommands
{
    public static Task<int> Rotate(string secretName, string who, CancellationToken token);
    public static Task<int> WhoUsed(string secretName, DateOnly since, CancellationToken token);
}
```

</details>

**Cómo se entrega**

```powershell
dotnet user-secrets set "Sige:ConnectionString" "<la cadena>" --project src\modern\Cordillera.Catalog.Api
dotnet test src\Cordillera.slnx -c Release
dotnet run --project src\modern\Cordillera.Ops -- secrets --rotate Sige:ConnectionString --who "tu nombre"
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 16 --concurrency 200
```

```bash
git tag -a mini-16 -m "Mini F16: cero secretos en disco · cadena fuera de 90 App.config · 4 socios con credenciales revocables · columna CLAVE borrada · autenticacion cuesta <X> ms/peticion"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Configura `dotnet user-secrets` y demuestra que el valor no está en el árbol del repositorio. Busca dónde
   quedó.
2. Agrega `ValidateOnStart` a una opción obligatoria y demuestra que el servicio falla al arrancar en vez de
   en la primera petición.
3. Escribe la política `ReadCatalog` y aplícala a un endpoint. Comprueba que sin token devuelve `401` y con
   token sin el `scope` devuelve `403`.
4. Levanta el proveedor OIDC en contenedor, emite un token, y valida su firma contra el servicio.
5. Busca en el historial de git cualquier archivo de configuración con una contraseña. Documenta el resultado
   aunque sea negativo.
6. Escribe el script que borra la columna `CLAVE` de `USUARIOS` y verifica que los cuatro procedimientos que
   usan `CODUSUA` siguen funcionando.

**🟡 Intermedio (7–14)**

7. Implementa el proveedor de configuración del gestor de secretos y demuestra que el código que consume no
   cambia entre los dos orígenes.
8. Provoca a propósito un `if (env.IsDevelopment())` en la configuración de secretos, y después quítalo.
   Explica qué riesgo introducía.
9. Emite credenciales independientes para los cuatro socios y revoca una. Demuestra con una prueba que las
   otras tres siguen funcionando.
10. Mide cuánto tarda el servicio en reaccionar a una rotación de claves del emisor con el tiempo de caché
    por omisión. Es el segundo umbral de la medición.
11. Implementa el rehasheo en el próximo inicio de sesión —la opción (b) de la sección 5.4— y explica por qué
    necesita una fecha de corte.
12. Escribe la comprobación de CI que rechaza un commit con un patrón de secreto. Prueba que funciona con un
    commit de prueba.
13. Configura el mismo servicio con Entra ID y con el proveedor en contenedor, y demuestra que **el código de
    la aplicación es idéntico**. Anota qué cambió: solo configuración.
14. Consulta el precio publicado de Entra ID por usuario al mes, con su fecha y su región, y calcula el costo
    para 340 empleados. Ponlo en la tabla de la fase 20.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** El servicio arranca en tu máquina y falla en el servidor con "unauthorized". El token es
    válido. Enumera cuatro causas —una es la audiencia, otra el reloj desincronizado— y di cómo distinguirlas.
16. **Diagnóstico.** Un socio reporta `401` intermitente, una vez cada tantas horas. Explica la causa más
    probable relacionada con la caché de claves y cómo se confirma.
17. **Medición.** Ejecuta la medición completa y determina **los dos umbrales**. Publica el resultado de la
    clave compartida **aunque gane**, y escribe el párrafo que explica por qué eso no la hace correcta.
18. **Medición.** Mide el costo de emitir y validar tokens con firma RSA contra firma simétrica, y di cuándo
    cada una es apropiada — incluido qué implica compartir una clave simétrica con cuatro socios.
19. Diseña la rotación completa de la cadena de conexión sin ventana de parada: cómo conviven la clave vieja y
    la nueva, cuánto tiempo, y cómo se sabe que nadie usa la vieja antes de revocarla.
20. **Decisión.** Entra ID contra el proveedor OIDC propio en contenedor, para las 340 personas de Cordillera.
    Decide con el precio, el amarre y quién lo opera, y di **qué se pierde** con cada opción.
21. **Decisión — ¿se migra, se envuelve o se deja quieto?** Las 11 cuentas sin usar desde 2021 y las 4 de
    servicio. Decide qué pasa con cada grupo, y qué se rompe si borras una que resulta que sí se usaba.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Consigue que el servicio arranque **sin** el secreto y funcione hasta la primera petición
    que lo necesite. Después arréglalo, y explica por qué el fallo temprano es mejor aunque parezca peor.
23. **Adversarial.** Escribe una configuración que parezca segura y filtre el secreto de tres formas distintas
    —en un log, en un mensaje de error y en una respuesta de diagnóstico—. Es el catálogo que hay que revisar
    en cualquier servicio.
24. **Diseño.** Escribe el plan completo de identidad de Cordillera: las 340 personas, los 4 socios, las
    cuentas de servicio, los 90 equipos, y qué pasa el día que alguien se va de la empresa. Con su costo.
25. **Defiende una decisión.** Wilson pregunta por qué hay que pagar por identidad corporativa si la tabla
    `USUARIOS` "funciona desde 2017". Respóndele en media página, en su lenguaje, con el precio real y con lo
    que pasa el día que se vaya un empleado — que es la pregunta que la tabla no puede responder.

**🔥 Opcionales**

- Investiga las identidades administradas de Azure y escribe por qué son la mejor respuesta a esta fase **y
  por qué el curso no las puede ejecutar**: no hay suscripción. Declara qué costaría.
- Implementa la auditoría de acceso a secretos —quién leyó qué y cuándo— y compárala con lo que ofrece el
  gestor real. Es la segunda pregunta de Wilson.
- Prueba `Microsoft.Data.SqlClient` con un token de acceso en vez de usuario y contraseña. Es el final del
  camino de esta fase: **una cadena de conexión sin contraseña**.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://learn.microsoft.com/aspnet/core/fundamentals/configuration/` — el modelo de configuración y el
  **orden de composición** de las fuentes.
- `https://learn.microsoft.com/aspnet/core/security/app-secrets` — `dotnet user-secrets`, que no tiene
  equivalente directo en Java.
- `https://learn.microsoft.com/dotnet/core/extensions/options-validation` — validación de opciones, y
  `ValidateOnStart`.
- `https://learn.microsoft.com/aspnet/core/security/authentication/configure-jwt-bearer-authentication` —
  validación de tokens y la caché de claves del emisor.
- `https://learn.microsoft.com/aspnet/core/security/authorization/policies` — autorización por políticas, que
  es lo que escala.
- `https://learn.microsoft.com/aspnet/core/security/data-protection/introduction` — protección de datos, que
  es lo que cifra las cookies y los tokens de la propia aplicación.
- `https://learn.microsoft.com/entra/identity-platform/` — la plataforma de identidad, para la parte
  estudiada. **Con su precio en la página de precios, que se cita con fecha y región.**
- `https://learn.microsoft.com/azure/key-vault/general/overview` — el gestor de secretos real, sustituido en
  este curso por el equivalente local.

**Especificación y estándares**

- `https://www.rfc-editor.org/rfc/rfc6749` y `https://openid.net/specs/openid-connect-core-1_0.html` — OAuth 2
  y OIDC. El lector los conoce; se citan para la parte de los flujos de cliente.

> ⚠️ Verifica las URLs. Y dos advertencias propias de esta fase. La primera: **todo el material de
> configuración anterior a .NET Core describe `ConfigurationManager` y `App.config`**, que es el mundo de
> SIGE y no el del servicio nuevo — es el único bloque del curso donde los dos modelos conviven en el mismo
> repositorio, así que hay que saber cuál se está leyendo. La segunda: **los precios de la nube cambian y las
> páginas se reorganizan**; cualquier cifra de esta fase se cita con **fecha y región**, y la región por
> omisión del curso es East US 2.

**Orden de lectura sugerido:** antes de escribir, la página de configuración completa —el orden de
composición decide la mitad de la fase— y la de secretos de usuario. Durante el miniproyecto, la de
validación de opciones y la de autenticación por token. Al cerrar, la de políticas de autorización: es la que
evita que el proyecto acabe con ciento veinte endpoints anotados a mano.

---

## 🚀 10. Cierre y conexión con la siguiente fase

**Se cobró la deuda más antigua del curso.** La cadena de conexión que la fase 07 puso en el `App.config` de
noventa equipos ya no está en ninguno, el servicio arranca sin un secreto en disco, los cuatro socios tienen
credenciales que se pueden revocar una por una, y la columna `CLAVE` con noventa hashes MD5 **está borrada** —
el único cambio de esquema que este curso hace en veinticinco fases, y por una razón que no es de diseño.

Y conviene notar por qué el cobro fue posible, porque es el argumento del Bloque B en una frase: **la cadena
salió de los noventa equipos porque la fase 10 cortó la conexión directa a la base**. Mientras el cliente
hablara con SQL Server tenía que tener credenciales; se podían proteger mejor, pero tenían que estar. **La
mejor forma de proteger un secreto es no necesitarlo**, y eso no se resuelve en la fase de seguridad: se
resuelve en la de arquitectura.

La fase 17 es el paso natural y es la que más deudas cobra del curso: **tres a la vez**. Los dos métodos sin
`CancellationToken` de la fase 05 —justificados con el argumento de que "tardan milisegundos"—, la doble
escritura sin conciliación de la fase 10, y `Money` como un `decimal` desnudo de la fase 01, que por fin
cruza tres divisas y no puede seguir sin llevar la moneda dentro. Nace **NightPress**, el cierre de regalías
que hoy tarda seis horas, falló dos veces en la hora cinco, y cuando falla se reinicia desde cero. Y su
criterio de aceptación es el de la historia: **reproducir exacto un número liquidado ocho meses antes**, que
hoy cuesta tres días de arqueología entre respaldos.

> **La señal de que quedó bien:** *"Wilson puede cambiar la clave de la base sin visitar un solo escritorio, y
> si algún día se filtra, sabe quién la usó."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el miniproyecto corriendo y
> `git status` limpio:
>
> ```bash
> git tag -a fase-16 -m "F16 cerrada:
> - cero secretos en disco, y el servicio falla AL ARRANCAR si falta uno
> - una sola ruta de codigo entre el equivalente local y el gestor real
> - politicas con nombre, y los endpoints anonimos declarados a proposito
> - cuatro socios con credenciales independientes y revocables
> - columna CLAVE borrada: el unico cambio de esquema del curso, y por riesgo y no por diseno
> - deuda de la F07 cobrada: la cadena salio de los 90 App.config"
> ```
>
> **Y la factura, que es la más satisfactoria del curso** — y son **dos caminos**, porque el formulario se
> movió a `modern/` en la fase 12 y la capa de datos sigue en `legacy/`:
>
> ```bash
> git diff fase-07 fase-16 -- src/legacy/Sige.DataAccess/App.config
> git diff fase-07 fase-16 -- src/modern/Sige.Forms/App.config
> ```
>
> Nueve fases de distancia, y lo que muestra es **una sección que desaparece**. No se movió a otro sitio: dejó
> de hacer falta. Es la deuda más antigua, la de cobro más largo, y la única cuyo pago consistió en **quitar
> una necesidad** en vez de satisfacerla mejor.

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura.*

- **`INSTINTOS.md`** — dos entradas en la familia *servicios, identidad y operación*: la cadena de conexión en
  el archivo de configuración —que necesita las **tres razones** por las que falla, porque "está en texto
  plano" es la menos importante de las tres: la que decide es que **no se puede rotar**— y el filtro de
  seguridad casero con sus cuatro problemas de diseño. La primera debe cerrar con **la mejor forma de
  proteger un secreto es no necesitarlo**, que es la lección transferible.
- **`BENCHMARKS.md`** — entrada ⏳ *F16 · El costo de la autenticación, con y sin caché de claves*. Tiene una
  propiedad que conviene señalar en el archivo: **el anti-patrón gana la medición**, y publicarlo así es el
  punto — la clave compartida es más rápida y la decisión no se toma por rendimiento. Es el primer sitio del
  curso donde un número favorece a lo que el material recomienda no hacer, y eso lo hace más creíble.
- **Deuda 💸 cobrada: la más antigua del curso** (F07 → F16), con nueve fases de distancia. Conviene anotar en
  el libro de §7.1 que su pago fue **quitar una necesidad y no satisfacerla mejor**, y que fue posible por el
  corte de la F10 — porque eso hace que la deuda sea un argumento de arquitectura y no de seguridad.
- **Cambio de esquema, el único del curso:** se borra la columna `USUARIOS.CLAVE`. Hay que anotarlo en
  `congelamiento-de-nombres.md` §1.6, porque el esquema es fuente de verdad y esta fase lo modifica — con su
  razón: **noventa hashes MD5 son un riesgo, no un defecto de diseño**, y ese es el criterio para tocar un
  esquema de 1997.
- **Tipos nuevos para el congelamiento:** `SigeOptions`, `SecretsProviderExtensions`, `SecretCommands`, y las
  políticas `EditorialStaff`, `ReadCatalog` y `PublicDuringCsvTransition` — la última con su fecha de retiro,
  porque es la que la F20 cobra junto con la paginación.
- **Para la fase 17:** la rotación necesita un proceso programado que la ejecute, y eso es trabajo de fondo.
  Y las cuentas de servicio que quedan son las que NightPress va a usar.
- **Para la fase 19:** la segunda pregunta de Wilson —*"si se filtra, ¿quién la usó?"*— se responde a medias
  aquí y del todo con la auditoría de la 19. Conviene que la 19 la cite.
- **Para la fase 20:** el precio de Entra ID por usuario al mes, con fecha y región, es una fila de la factura.
  Y la política `PublicDuringCsvTransition` es la que hay que retirar cuando el volcado completo se pagine.
- **Riesgo detectado y resuelto:** el `App.config` vive en **dos sitios** desde la F12 —el formulario se movió
  a `modern/` y la capa de datos sigue en `legacy/`— y la factura del bloque 🏷️ solo citaba uno, así que el
  cobro parecía más pequeño de lo que fue. Ahora cita los dos caminos. Es el tipo de detalle que aparece
  cuando un proyecto cruza de subárbol y conviene revisarlo en cada `git diff` del resto del curso.
