# ⚔️ Fase 23 — El duelo: ASP.NET Core contra Spring Boot

> C# para desarrolladores Java senior · Fase 23 de 24 · Cierre
> Depende de: 22 · Habilita: 24
> Estilo de esta fase: **nuevo** (.NET 10, C# 14) — y **Java 25 LTS** al otro lado
> Proyecto que avanza: **CatalogAPI, dos veces**.

---

## 🎯 1. Propósito

Esta es la fase que estabas esperando desde la primera página, y es también la que te va a dejar menos cómodo de
las veinticuatro.

En 2025, el día once de tu trabajo en Cordillera, escribiste un documento de tres páginas proponiendo
reescribirlo todo en Spring Boot. Ese documento tenía razones y ninguna era mala. El curso empezó quitándote ese
instinto **con aritmética y no con doctrina**: 700 procedimientos almacenados que nadie ha leído, licencias de
SQL Server ya pagadas, y un compañero que sabe C# y va a sostener esto cuando tú te vayas.

Lo que nunca se hizo fue **medirlo**. Veintitrés fases de argumentos sobre el sistema heredado, la gente y el
dinero — y ni una sola cifra sobre la pregunta que escribiste en aquel documento: *¿cuál de las dos plataformas
es mejor para esto?*

Esta fase la contesta. **El endpoint crítico de CatalogAPI, implementado dos veces**, las dos defendibles en una
revisión de código, y la comparación completa: rendimiento, arranque en frío, memoria, costo mensual al volumen
de Cordillera, líneas de código y **facilidad de contratar a quien lo mantenga en Bogotá**.

> 🧭 **La regla de la fase, y es la más incómoda del curso:** *el competidor tiene que estar escrito por alguien
> que lo defienda.* Y tú **eres** ese alguien: once años de Java, y sabes exactamente dónde se le hacen trampas
> a un benchmark de Spring Boot — el pool sin configurar, el serializador por omisión, sin caché, la JVM medida
> en su primer segundo de vida. **Que el lector sea experto en el competidor hace esta comparación más honesta
> que cualquier otra del curso**, y bastante más difícil de aprobar.

Y hay algo que esta fase **no** hace, y conviene decirlo en la primera página: **no decide por Cordillera**. La
decisión ya estaba tomada, por razones que la historia explica y que ninguna tabla mueve. Lo que la fase produce
es la respuesta a una pregunta distinta y más útil: *¿de qué tamaño era la diferencia que estábamos discutiendo?*

---

## ✅ 2. Qué queda listo al terminar

- [ ] El mismo endpoint existe **dos veces** —ASP.NET Core y Spring Boot 4.1.1—, con el **mismo contrato**, la
      **misma base** y el **mismo comportamiento**, verificado con el mismo conjunto de pruebas.
- [ ] Las dos implementaciones están **configuradas para producción**: pool de conexiones dimensionado,
      serialización elegida, caché donde corresponda, registro y chequeos de salud.
- [ ] Hay una **declaración firmada de defendibilidad**: qué se configuró en cada lado y por qué, para que nadie
      pueda decir que el competidor iba en calzoncillos.
- [ ] Están medidas las **cuatro configuraciones**: ASP.NET Core con JIT y con AOT nativo, Spring Boot en la JVM
      y como imagen nativa. **No son un tercer competidor**: son los dos mismos, compilados de dos maneras.
- [ ] La medición incluye **arranque en frío, latencia bajo carga, memoria en régimen y memoria a las ocho
      horas**.
- [ ] Está calculado el **costo mensual de cada una al volumen de Cordillera**, con la metodología de la fase 20
      —precio publicado, fuente, fecha, región—.
- [ ] Están contadas las **líneas de código** de las dos, con el criterio de conteo escrito.
- [ ] Está respondida la columna que nadie mide: **cuánto cuesta contratar a quien lo mantenga en Bogotá**, con
      la fuente de los datos.
- [ ] **Los empates están publicados como empates**, con la dispersión que los sostiene.
- [ ] Está dicho, sin ambigüedad, **qué gana cada plataforma y en qué pierde**, y **por qué la decisión de
      Cordillera no depende de esta tabla**.
- [ ] La medición de la sección 6 está escrita con su comando, y la entrada quedó en `BENCHMARKS.md`.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Un tercer competidor.** Cerrado en `propuesta-fases-y-alcance.md` §10.5 y con su razón: Go, Node o Rust
  diluyen la comparación, alargan la fase y **no responden a ninguna pregunta que Cordillera se esté haciendo**.
  El duelo es contra el stack que el lector realmente tiene.
- **Comparar ecosistemas enteros.** No se comparan los ORM, ni los marcos de pruebas, ni las bibliotecas de
  mensajería. **Un endpoint, dos implementaciones**, y todo lo demás igual. Ampliarlo produciría una tabla más
  grande y menos concluyente.
- **Reescribir Cordillera en Java.** No es el propósito ni una posibilidad: existe para medir, y las dos
  implementaciones se quedan en el repositorio como prueba.
- **Optimizar hasta el último microsegundo.** Las dos se configuran como se configuraría producción y ahí se
  detiene. Un duelo de afinado extremo mide la habilidad de quien afina, no las plataformas.
- **El veredicto del curso** → fase 24. Esta aporta la columna del rendimiento comparado; **la conclusión del
  curso no sale de aquí**.

---

## 🧠 4. Concepto mínimo

### Qué hace comparable una comparación

Casi todos los benchmarks de plataformas que vas a encontrar son inútiles, y no por mala fe: por **no haber
igualado lo que había que igualar**. Antes de una sola cifra, cinco cosas tienen que ser idénticas.

**El contrato.** Mismo endpoint, mismos parámetros, misma forma de respuesta, mismos códigos de error. El de la
fase 15, sin cambios: `GET /catalogo` con sus filtros, su paginación y su `EditionResponse`.

**Los datos.** La misma base, con el mismo volumen y los mismos índices. **Y aquí está la trampa que arruina la
mitad de estas comparaciones:** si una implementación consulta más eficientemente que la otra, estás midiendo
las consultas y no las plataformas. El SQL que ejecutan las dos tiene que ser **el mismo SQL**, y eso hay que
comprobarlo mirando el plan en las dos, no suponerlo.

**El comportamiento.** El mismo conjunto de pruebas de contrato corre contra las dos y las dos pasan. Sin eso,
puede que una sea más rápida porque hace menos.

**La configuración de producción.** Pool dimensionado, serialización elegida, compresión, caché, registro,
chequeos de salud. **En las dos.**

**El entorno.** Misma máquina, mismo contenedor base, mismos límites de CPU y memoria, misma red hacia la base.

> 🧠 **El modelo mental de la fase, y es lo que la hace difícil de aprobar:** una comparación de plataformas es
> **un experimento con una sola variable**, y esa variable es la plataforma. Todo lo demás es ruido que hay que
> fijar. Cada cosa que no igualaste es una explicación alternativa del resultado — y si tienes tres, tu tabla no
> demuestra nada por muy bonita que sea.

### El arranque en frío, que es la columna donde más se miente

Es la cifra favorita de los blogs y la más fácil de contar mal, en las dos direcciones.

**Contra la JVM:** medir el primer segundo. Una JVM arranca, carga clases, interpreta, y el compilador de tiempo
de ejecución va optimizando **durante los primeros miles de peticiones**. Medir los diez primeros segundos y
publicarlo como "rendimiento" es medir a alguien mientras se calienta. Es tan deshonesto que ni hace falta
argumentarlo: es la razón por la que el arnés de este curso descarta el calentamiento desde la fase 00.

**Y contra .NET, por simetría:** medir solo en régimen. Si el servicio escala a cero por la noche —que es
justamente lo que la fase 20 evaluó— **el arranque en frío es el rendimiento**, porque la primera petición de la
mañana es la que espera alguien. Ignorarlo porque favorece a una plataforma es la misma trampa del otro lado.

La respuesta honesta es que **son dos preguntas distintas y las dos van en la tabla, separadas**: cuánto tarda en
responder la primera petición, y cuánto tarda una vez caliente. Y una tercera que casi nadie pone: **cuántas
peticiones necesita cada una para llegar a su régimen**.

Y las dos plataformas tienen respuesta al arranque en frío, así que las cuatro configuraciones entran: **AOT
nativo** en .NET y **imagen nativa de GraalVM** en el lado de Java. Dejar fuera el AOT de uno de los dos lados
sesga exactamente la columna donde más se discute.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El reflejo: comparar contra un competidor de paja.**

Y ojo, que en esta fase el instinto va en la dirección contraria a la de las veintidós anteriores. Aquí **el
espantapájaros que te va a salir sin querer es el de .NET**, porque el ecosistema que dominas es el otro.

```text
❌ Cómo se ve, y nadie lo hace a propósito:
   Escribes el Spring Boot en dos horas, porque llevas once años haciéndolo: el pool con el
   tamaño que ya sabes que va bien, la caché donde siempre la pones, el serializador
   configurado, el índice que sabes que hace falta.
   Y el ASP.NET Core lo escribes siguiendo el tutorial.
   La tabla sale parecida. Y no mediste las plataformas: mediste tus once años.
```

**Por qué falla:** porque el conocimiento tácito no aparece en el diff. La configuración que pones sin pensarla
en la plataforma que dominas es exactamente la que se te olvida en la otra — y la diferencia entre un pool de
conexiones dimensionado y el valor por omisión puede ser un orden de magnitud bajo carga.

```text
✅ Lo que hay que hacer en su lugar:
   La declaración de defendibilidad de la sección 5.1, escrita ANTES de medir: qué se
   configuró en cada lado, con qué valor y por qué. Item por item, simétrica. Si una línea
   existe en una columna y no en la otra, la comparación está sesgada y se ve.
```

**Dónde se rompe el paralelo con lo que traes:** tu experiencia te da una ventaja real —sabes dónde se hacen
trampas a Spring Boot— y un sesgo igual de real: **sabes cuidarlo mejor**. Es el mismo problema que la fase 21
tuvo con el conjunto de entrenamiento, en otro terreno: el defecto no está en la medición, está en cómo se armó
lo que se mide.

> ⚰️ **Autopsia del anti-patrón: el benchmark que ganó por el pool.**
>
> **El caso:** se mide el endpoint en las dos plataformas con 200 clientes concurrentes. ASP.NET Core da una
> latencia p95 varias veces mejor. Se publica.
>
> **Lo que había pasado:** el pool de conexiones del lado de Java estaba en su valor por omisión —diez
> conexiones— y el del lado de .NET en cien. Con 200 clientes concurrentes, una implementación tenía diez
> conexiones para repartir y la otra cien. **La medición era correcta y no medía las plataformas: medía dos
> configuraciones de pool.**
>
> **Cómo se descubre:** mirando la base, no el código. Las conexiones activas durante la prueba son un número
> observable —y la fase 19 dejó la instrumentación para verlo—. Si una implementación abre diez y la otra cien,
> ahí está la explicación antes de mirar ninguna otra cosa.
>
> **El costo real de este error no es técnico:** es que **una tabla así no se puede retirar**. Circula, se cita,
> y la corrección no llega a la mitad de la gente que vio el gráfico. Por eso la declaración de defendibilidad
> va antes de medir y se publica con la tabla.
>
> **La defensa:** los recursos igualados y **verificados en el servidor** —conexiones, hilos, límites del
> contenedor—, y el plan de consulta comprobado en las dos. Igualar en el código no basta: hay que comprobar en
> el motor.

### 🩻 Esto sí funciona igual

**Todo.** Y esto es raro en este curso, pero es la verdad y es el hallazgo de la fase: en el terreno de un
servicio HTTP con base de datos, **las dos plataformas son la misma generación de la misma idea**. Enrutamiento,
inyección de dependencias, middleware o filtros, serialización, validación, mapeo objeto-relacional,
observabilidad, chequeos de salud, configuración por entorno, contenedores.

No hay nada en esta fase que un senior de Spring Boot tenga que aprender de nuevo para leer la implementación de
ASP.NET Core, y viceversa. Lo que cambia es el vocabulario y algunos valores por omisión.

Y eso **es una conclusión, no una introducción**: si las dos plataformas resuelven el mismo problema con las
mismas piezas, la diferencia entre ellas es pequeña comparada con la diferencia entre un equipo que domina una y
un equipo que la está aprendiendo. Que es exactamente lo que el curso lleva veintitrés fases diciendo por otros
medios.

### 📖 Diccionario de traducción

Este es el 📖 más completo del curso porque la fase lo permite: los dos lados existen en el repositorio.

| Spring Boot 4.1 | ASP.NET Core 10 | Dónde se rompe el paralelo |
|---|---|---|
| `@RestController` + `@GetMapping` | Minimal APIs, o controladores | Ya visto en la F15. Las dos formas coexisten en los dos mundos |
| `@Service`, `@Component` | registro en el contenedor, explícito | **.NET no escanea por convención**: se registra a mano. Más ruido, menos sorpresas |
| `@Transactional` | no existe equivalente | El hueco más grande entre los dos, y la F08 ya lo documentó. La transacción se abre a mano |
| Spring Data JPA con repositorios derivados | EF Core con LINQ | **Sin equivalente a los métodos derivados del nombre.** En .NET la consulta se escribe |
| Hibernate | EF Core | Muy parecidos, y con el mismo riesgo: la F09 midió lo que cuesta creerles |
| HikariCP | el pool de `Microsoft.Data.SqlClient` | Integrado, no una dependencia. **Los valores por omisión no son los mismos** — la autopsia |
| Jackson | `System.Text.Json` | Rápido y **estricto por omisión**. Jackson perdona más, y eso se nota al migrar |
| `application.yml` con perfiles | `appsettings.{Environment}.json` | Mismo modelo (F16). Los dos ceden ante variables de entorno |
| Actuator | `AddHealthChecks` + OpenTelemetry | Ver la advertencia de la F19 sobre qué revela un chequeo |
| Micrometer | `Meter` de `System.Diagnostics` | Mismo modelo; el estándar de trazas es el mismo en los dos |
| Bean Validation (`@Valid`) | anotaciones de datos, o validación explícita | Equivalente. En Blazor la misma regla vale en cliente y servidor (F18) |
| Maven / Gradle | MSBuild | Ya visto en la F00. **El `.csproj` es el build, no lo describe** |
| Tomcat embebido | Kestrel | Equivalente, y los dos se ponen detrás de algo en producción |
| GraalVM native image | **AOT nativo** | Las dos existen, las dos rompen la reflexión, y **las dos cuestan tiempo de construcción** |
| Virtual threads (Loom) | `async`/`await` | Ya visto en la F05. **Loom es más fácil de adoptar**: el código secuencial no se reescribe |
| Java 25 LTS | .NET 10 LTS | Cadencia parecida y compromisos de soporte parecidos |

> ⚠️ **La fila de los virtual threads es la única donde el competidor gana algo estructural**, y hay que decirlo
> sin rodeos: con Loom, el código bloqueante existente escala sin reescribirse; en .NET la concurrencia exige
> `async`/`await` **propagado por toda la pila de llamadas**, que es la asimetría que la fase 05 midió con "la
> concurrencia del codo". Para un sistema nuevo da casi igual; para **migrar un sistema bloqueante existente**,
> el modelo de Java es materialmente más barato de adoptar. Es la clase de ventaja que no aparece en un
> benchmark de latencia y aparece en un presupuesto.

> 📝 **Nota de ecosistema, y es un dato de la fase.** La línea vigente del competidor al escribir esto es
> **Spring Boot 4.1.1**, del 21 de agosto de 2026, sobre **Java 25 LTS**. La propuesta del curso decía "Spring
> Boot 3", que era la línea cuando se escribió — y **medir contra 3.x hoy sería el espantapájaros que esta fase
> existe para evitar**. Quedó corregido en `propuesta-fases-y-alcance.md` §10.5 en vez de corregido en silencio,
> porque una comparación que se equivoca de versión del competidor no se recupera de eso.

---

## 💻 5. Código mínimo con comentarios

### 5.1 La declaración de defendibilidad, que va antes de medir

```markdown
<!-- src/duelo/DEFENDIBILIDAD.md
     Este archivo se escribe ANTES de la primera medición y se publica CON la tabla. Es lo único
     que separa un duelo de un panfleto: item por item, simétrico, y si una línea existe en una
     columna y no en la otra, el sesgo se ve a simple vista.

     Y tiene un segundo propósito, menos noble y muy útil: cuando alguien en internet diga que tu
     Spring Boot iba mal configurado, la respuesta es un enlace. -->

| Decisión de producción | ASP.NET Core 10 | Spring Boot 4.1.1 | ¿Simétrico? |
|---|---|---|---|
| Pool de conexiones, tamaño | 50 | 50 (HikariCP) | ✅ **y verificado en el motor** |
| Tiempo de espera de conexión | 5 s | 5 s | ✅ |
| Serialización | `System.Text.Json`, generador de origen | Jackson, `afterburner` | ✅ |
| Caché de respuesta | salida, 60 s | salida, 60 s | ✅ |
| Compresión | Brotli | Brotli | ✅ |
| Registro | estructurado, nivel Warning | estructurado, nivel WARN | ✅ |
| Trazas | OpenTelemetry 1.18.0 | OpenTelemetry, misma versión de estándar | ✅ |
| Consulta SQL emitida | **plan verificado** | **plan verificado** | ✅ el mismo SQL |
| Índices de la base | los mismos | los mismos | ✅ es la misma base |
| Límites del contenedor | 2 vCPU / 2 GB | 2 vCPU / 2 GB | ✅ |
| Imagen base | `runtime-deps` reducida | `eclipse-temurin:25-jre-alpine` | ⚠️ **no son equivalentes**: ver nota |
| Calentamiento descartado | 3 s | **30 s** | ⚠️ **asimétrico a propósito**: ver nota |

**Nota sobre el calentamiento, y es la asimetría más importante del documento.** La JVM necesita más
peticiones que .NET para llegar a su régimen. Descartar el mismo tiempo en las dos **mediría a una de
ellas mientras se calienta**, que es la trampa clásica contra Java. Así que el calentamiento se
descarta **por criterio y no por reloj**: se descarta hasta que la latencia p95 se estabiliza dentro
del 5% en una ventana móvil, en cada plataforma, y **se publica cuánto tardó cada una** — que es un
dato interesante por sí mismo y está en la tabla A.

**Nota sobre las imágenes base.** No hay equivalencia exacta, y forzarla sería peor. Se elige **la más
pequeña que sea razonable en producción en cada lado**, se publican los dos tamaños, y se dice que la
comparación de tamaño es informativa y no un veredicto.
```

**Detalles con intención**

- **El archivo va en `src/duelo/`, no en ninguna de las dos implementaciones**, porque no pertenece a ninguna: es
  el protocolo del experimento.
- **"Verificado en el motor" no es adorno.** La autopsia de la sección 4 es exactamente el caso de un pool
  igualado en el código y distinto en la práctica.
- **El calentamiento asimétrico es la decisión más defendible del documento y la que más se va a discutir.**
  Descartar por criterio y no por reloj es lo único justo, y publicar cuánto tardó cada una convierte la
  asimetría en un dato en vez de un favor.

### 5.2 El mismo endpoint, en los dos idiomas

```csharp
// src/duelo/dotnet/Cordillera.Catalog.Api.Duel/Program.cs
//
// El contrato es el de la F15, sin tocar. Lo que cambia respecto a esa fase es que aquí todo está
// configurado como producción, porque la alternativa es medir un tutorial.
var builder = WebApplication.CreateSlimBuilder(args);   // ← Slim: menos servicios por omisión, arranque más rápido

builder.Services.AddDbContextPool<CatalogContext>(options =>   // ← pool de contextos, 50, simétrico con Hikari
    options.UseSqlServer(builder.Configuration.GetConnectionString("Sige"),
        sql => sql.CommandTimeout(5)), poolSize: 50);

// El generador de origen para la serialización: sin reflexión, necesario para AOT nativo, y además
// más rápido. Es la fila "serialización" de la declaración.
builder.Services.ConfigureHttpJsonOptions(o => o.SerializerOptions.TypeInfoResolver = CatalogJsonContext.Default);

builder.Services.AddOutputCache(o => o.AddBasePolicy(p => p.Expire(TimeSpan.FromSeconds(60))));
builder.Services.AddResponseCompression(o => o.EnableForHttps = true);

WebApplication app = builder.Build();
app.UseResponseCompression();
app.UseOutputCache();

// El endpoint. Diez líneas, y son las mismas diez que la F15 dejó — con la paginación que la F20
// cobró como deuda, porque servir el volcado completo aquí falsearía la comparación: mediría
// transferencia y no plataforma.
app.MapGet("/catalogo", async (
    [AsParameters] EditionQuery query,
    ICatalogQueries queries,
    CancellationToken token) =>
{
    CatalogPage<EditionResponse> page = await queries.SearchAsync(query.ToCriteria(), token);
    return Results.Ok(page);
}).CacheOutput();

app.Run();
```

```java
// src/duelo/jvm/src/main/java/media/cordillera/catalog/CatalogController.java
//
// Y la contraparte, escrita como la escribiría alguien que la defiende. Si esto te parece pobre
// comparado con lo que tú escribirías, **arréglalo**: ese es el ejercicio, y una implementación que
// el lector no firmaría invalida la fase entera.
@RestController
@RequestMapping("/catalogo")
class CatalogController {

    private final CatalogQueries queries;

    CatalogController(CatalogQueries queries) { this.queries = queries; }

    // Caché de respuesta de 60 s, simétrica con la del otro lado. Y la consulta sale de un
    // repositorio con JPQL explícito — NO de un método derivado del nombre, porque el SQL emitido
    // tiene que ser el mismo que emite EF Core y eso hay que poder comprobarlo en el plan.
    @GetMapping
    @Cacheable(value = "catalogo", key = "#query.cacheKey()")
    ResponseEntity<CatalogPage<EditionResponse>> search(@Valid EditionQuery query) {
        return ResponseEntity.ok(queries.search(query.toCriteria()));
    }
}
```

```yaml
# src/duelo/jvm/src/main/resources/application.yml
# La configuración que hace defendible la implementación. Cada línea de aquí tiene su gemela en la
# declaración de la sección 5.1, y su ausencia habría sido la autopsia de la sección 4.
spring:
  datasource:
    hikari:
      maximum-pool-size: 50        # ← simétrico, y verificado contando conexiones en el motor
      connection-timeout: 5000
  jpa:
    properties:
      hibernate.jdbc.batch_size: 50
      hibernate.default_batch_fetch_size: 50   # ← contra el N+1, que es el Include de la F09 aquí
server:
  compression:
    enabled: true
    mime-types: application/json
  tomcat:
    threads:
      max: 200                     # ← y el otro lado no tiene equivalente: ver la nota de la sección 6
```

**El patrón a memorizar**

> **El SQL emitido por las dos implementaciones tiene que ser el mismo, y eso se comprueba en el plan de
> consulta, no en el código.** Es la condición que casi ninguna comparación de plataformas cumple, y sin ella lo
> que se mide es el mapeador objeto-relacional de cada lado — que es una comparación distinta, legítima y **no la
> que dice esta tabla que está haciendo**. Un `fetch join` contra un `Include`, o un método derivado contra un
> LINQ, producen SQL distinto con la misma cara.

### 5.3 El modelo de concurrencia, que es donde la simetría se rompe

```csharp
// ⚠️ Aquí hay una asimetría real y no se puede igualar, así que se declara.
//
// Spring Boot sobre Tomcat tiene un número máximo de hilos —200 arriba— y cada petición ocupa uno
// mientras espera a la base. Con virtual threads activados (Java 21 en adelante), ese límite deja de
// ser el cuello de botella y el modelo se parece mucho más al de .NET.
//
// ASP.NET Core no tiene un número máximo de hilos por petición porque **una petición que espera no
// ocupa un hilo**: el await lo devuelve al grupo. No hay un valor equivalente que igualar.
//
// Consecuencia para la medición, y va en la tabla: se miden TRES configuraciones del lado de Java
// —hilos de plataforma, virtual threads, imagen nativa— porque la elección cambia la columna de
// concurrencia por completo, y comparar contra la configuración vieja sería el espantapájaros que
// esta fase existe para evitar.
//
// Y la lectura honesta del resultado, adelantada: cuando los dos lados usan su modelo moderno,
// **este eje deja de separarlos**. Lo que queda distinto no es la capacidad, es el costo de
// adoptarlo — y ahí Loom gana, porque no obliga a reescribir la pila de llamadas (F05).
```

**Prueba de fuego**

```powershell
docker compose -f src\duelo\compose.yml up --build
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 23 --duelo --clients 200
```

Mira la tabla y busca primero **la dispersión**, no la mediana. Si dos columnas se solapan dentro de su
dispersión, **eso es un empate** y así se publica.

Y la mentira que te va a contar la salida si miras el lugar equivocado: **va a haber una columna donde una gane
por mucho**, y va a ser tentadora. Antes de creerla, contesta dos preguntas: ¿esa columna está igualada en la
declaración de defendibilidad? ¿y esa columna importa al volumen de Cordillera? Una ventaja de 40% en una
latencia de dos milisegundos, en un sistema donde `SP_CATALOGO` se lleva segundos —lo que la fase 19 midió—, **es
ruido con buena presentación**.

---

## 📏 6. Medición

**Hipótesis:** cuatro, y una es más importante que las otras tres.
**(a)** En **latencia en régimen**, al volumen de Cordillera, las dos **empatan dentro del ruido**.
**(b)** En **arranque en frío**, .NET con JIT le gana a la JVM; con las dos variantes nativas la diferencia se
reduce mucho y **el costo se traslada al tiempo de construcción**.
**(c)** En **memoria**, .NET usa menos en régimen, y la diferencia **se traduce a un renglón de la factura solo
si el alojamiento cobra por memoria**.
**(d)** Y la importante: **la diferencia entre las dos plataformas es más pequeña que la diferencia entre un
equipo que domina una y un equipo que la está aprendiendo** — lo que hace que las columnas técnicas no decidan.

**Condiciones:** SDK 10.0.401, .NET 10 · **Spring Boot 4.1.1 sobre Java 25 LTS (Temurin)** · Release / producción
en las dos · contenedores con **2 vCPU y 2 GB** idénticos · la misma base SQL Server 2025 con los mismos índices,
generador con semilla `19970417` · **el mismo SQL verificado en el plan** · el conjunto de pruebas de contrato de
la F15 pasando en las dos · carga de 200 clientes concurrentes, que es el pico de Cordillera con margen ·
**calentamiento descartado por criterio** —hasta que el p95 se estabilice dentro del 5%— y no por reloj, con el
tiempo de cada una publicado · memoria a las **ocho horas**, igual que la F14 · precios con la metodología de la
F20: publicado, fuente, fecha, **East US 2** · arnés propio · **y la declaración de defendibilidad de la sección
5.1 publicada con la tabla**.

**Competidores:** dos plataformas, **cinco configuraciones** — ASP.NET Core (JIT) · ASP.NET Core (AOT nativo) ·
Spring Boot (hilos de plataforma) · Spring Boot (virtual threads) · Spring Boot (imagen nativa de GraalVM). Las
cinco son los dos mismos competidores compilados o configurados de distinta forma: **no hay un tercero**
(`propuesta-fases-y-alcance.md` §10.5).

**Los comandos:**

```powershell
docker compose -f src\duelo\compose.yml up --build
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 23 --duelo --clients 200
dotnet run -c Release --project src\modern\Cordillera.Costos -- --hoja duelo --region eastus2
```

**Resultado:** ⏳ pendiente de ejecución en tu máquina.

**A · Rendimiento**

| Configuración | Arranque a la 1ª respuesta | Peticiones hasta régimen | p50 en régimen | p95 | Dispersión | Memoria en régimen | Memoria a las 8 h |
|---|---|---|---|---|---|---|---|
| ASP.NET Core 10, JIT | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| ASP.NET Core 10, AOT nativo | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Spring Boot 4.1.1, hilos de plataforma | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Spring Boot 4.1.1, virtual threads | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Spring Boot 4.1.1, imagen nativa | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |

**B · Lo que cuesta construir y operar**

| Configuración | Tiempo de construcción | Tamaño de la imagen | Costo mensual al volumen real | ¿Rompe la reflexión? |
|---|---|---|---|---|
| ASP.NET Core, JIT | ⏳ | ⏳ | 💲 ⏳ | no |
| ASP.NET Core, AOT nativo | ⏳ | ⏳ | 💲 ⏳ | **sí** |
| Spring Boot, JVM | ⏳ | ⏳ | 💲 ⏳ | no |
| Spring Boot, imagen nativa | ⏳ | ⏳ | 💲 ⏳ | **sí** |

**C · Las columnas que no son de rendimiento, y que probablemente deciden**

| Criterio | ASP.NET Core 10 | Spring Boot 4.1.1 | Cómo se midió |
|---|---|---|---|
| Líneas de código del endpoint y su soporte | ⏳ | ⏳ | conteo declarado, sin generados |
| Líneas de configuración | ⏳ | ⏳ | ídem |
| Dependencias directas | ⏳ | ⏳ | del archivo de proyecto |
| **Ofertas de empleo en Bogotá** | ⏳ | ⏳ | portales, misma fecha, mismos filtros |
| **Rango salarial declarado** | ⏳ | ⏳ | ídem, con la fuente |
| ¿Lo sabe Duván? | **Sí** | No | preguntándole |
| Adoptar concurrencia en código bloqueante existente | ⏳ | ⏳ *(Loom)* | cualitativo, declarado |

> ⚖️ **Veredicto** *(expectativa, todavía sin ejecutar — `formato-de-mediciones.md` §2.6)*. Se espera **empate en
> latencia en régimen**, y publicarlo así —con la dispersión que lo sostiene— es el resultado más valioso de la
> fase: al volumen de Cordillera, el rendimiento **no es una razón para elegir**. Se espera que .NET gane
> arranque en frío y memoria, que las variantes nativas acerquen la primera columna a costa del tiempo de
> construcción, y que **la tabla C decida** — donde una fila dice "Sí" y la otra "No", y ninguna medición de
> latencia la puede contradecir.
>
> **Los cuatro umbrales que tu ejecución tiene que determinar:** (1) **de qué tamaño es la diferencia real en
> régimen**, que es la cifra que retira o confirma el documento de tres páginas del día once; (2) **cuántas
> peticiones necesita cada una para llegar a su régimen**, que es el dato que casi nadie publica y el que hace
> honesta la columna de arranque; (3) **cuánto de la ventaja de memoria se convierte en pesos** al alojamiento
> elegido en la F20 — probablemente menos de lo que parece; (4) **cuántas ofertas de cada plataforma hay en
> Bogotá**, que es la única columna que cambia de respuesta según dónde viva el lector y por eso hay que
> medirla y no copiarla.
>
> 📝 **Cómo se publican los empates** (`formato-de-mediciones.md` §2.4): si dos medianas están dentro de la
> dispersión combinada, la celda dice **empate** y se justifica con el número. No "ligeramente mejor", no una
> flecha verde. **Empate.** En esta tabla van a ser varias celdas, y son la conclusión y no un fracaso de la
> medición.
>
> ⚠️ **Y la advertencia que esta fase se debe a sí misma:** esta tabla **no decide por Cordillera**, y no porque
> sea mala. La decisión estaba tomada por 700 procedimientos almacenados que nadie ha leído, unas licencias
> pagadas y **un compañero que sabe C#** — tres razones que no aparecen en ninguna columna de A ni de B. Lo que
> la tabla contesta es de qué tamaño era la diferencia que estábamos discutiendo. Si sale empate técnico, **el
> documento del día once no estaba equivocado en los hechos: estaba equivocado en lo que importaba.**

---

## 🧱 7. Miniproyecto — escribe el competidor que defenderías

**El encargo**

No lo pide nadie de Cordillera. Lo pides tú, y lo pides por una razón que conviene admitir:

> *Llevas veintitrés fases aceptando argumentos. Buenos argumentos —700 procedimientos, las licencias, Duván—,
> y ninguno del tipo que te habría convencido el día once. Aquel documento de tres páginas no hablaba de gente:
> hablaba de plataformas, y nadie lo contestó en sus términos.*
>
> *Este miniproyecto lo contesta. Con una condición: el Spring Boot lo escribes **tú**, con once años de
> oficio, configurado como lo configurarías para producción de verdad. Si pierde, que pierda bien escrito.*

**Por qué duele**

Porque la parte difícil no es la implementación —las dos te van a salir en una tarde— sino **no hacerte trampas
al solitario en la dirección que no esperas**. El espantapájaros que te sale sin querer es el de .NET, porque la
configuración que pones sin pensarla en Spring Boot es la que se te olvida en el otro lado.

Y duele porque hay un resultado probable que no satisface a nadie: **empate técnico**. Ni la vindicación del
documento del día once, ni su refutación. Solo la constatación de que la discusión que ocupó tres páginas valía,
en números, mucho menos de lo que parecía.

**Datos de entrada**

| Qué | Detalle |
|---|---|
| El endpoint | `GET /catalogo` de la F15, con filtros y paginación |
| El contrato | `EditionResponse`, `CatalogPage<T>`, espacio `Contracts.V1` |
| La base | SQL Server 2025, semilla `19970417`, los mismos índices |
| Carga | **200 clientes concurrentes**, el pico de Cordillera con margen |
| Contenedores | **2 vCPU / 2 GB** los dos |
| Las plataformas | .NET 10 · **Spring Boot 4.1.1 / Java 25 LTS** |
| Región para precios | East US 2 |
| El documento del día once | tres páginas, 2025, proponiendo reescribirlo todo en Spring Boot |

**Criterios de aceptación**

1. Las dos implementaciones **pasan el mismo conjunto de pruebas de contrato**, el de la F15, sin adaptaciones
   por plataforma.
2. **El SQL emitido es el mismo**, y está comprobado **en el plan de consulta de las dos**. Si no lo es, la
   comparación no cuenta.
3. La **declaración de defendibilidad** está escrita **antes** de medir, es simétrica item por item, y se
   publica con la tabla.
4. Las asimetrías que no se pueden igualar están **declaradas**, no disimuladas: el calentamiento, las imágenes
   base y el modelo de concurrencia.
5. Los recursos están **verificados en el servidor**, no solo en el código: cuenta las conexiones activas en el
   motor durante la prueba, en las dos.
6. La medición cubre las **cinco configuraciones**, incluidas las dos nativas y los virtual threads.
7. **Los empates se publican como empates**, con su dispersión. Si en tu tabla no hay ni un empate, revisa —al
   volumen de Cordillera es improbable.
8. La tabla C está completa, **incluidas las dos filas del mercado laboral de tu ciudad**, con su fuente y su
   fecha.
9. Está escrito, en un párrafo, **qué habrías contestado al documento del día once con esta tabla delante** — y
   si la respuesta es "tenías razón en algo", cuál.
10. **Medición de cierre:** las tres tablas de la sección 6, con la declaración. Van en el mensaje del tag
    `mini-23`.

**Restricciones de estilo y alcance**

Las dos implementaciones son código nuevo y **las dos se quedan en el repositorio**: son la evidencia. Sin un
tercer competidor. Sin afinado extremo: configuración de producción y ahí se para. Y las dos viven en
`src/duelo/`, fuera de `modern/` y de `legacy/`, porque no son parte del sistema de Cordillera: **son un
experimento**, y mezclarlas con el código de producción confundiría las dos cosas.

**La trampa**

Vas a escribir el Spring Boot primero, porque es tu casa. Te va a salir en dos horas, con el pool en el tamaño
que ya sabes, la caché donde siempre la pones, `default_batch_fetch_size` puesto porque conoces el N+1 de
memoria, y el índice que sabes que hace falta.

Y el ASP.NET Core lo vas a escribir **siguiendo la documentación**, que es exactamente lo que hace alguien que
no lleva once años en la plataforma. Sin `AddDbContextPool`, con el serializador por reflexión en vez del
generador de origen, sin `CreateSlimBuilder`, sin caché de salida.

La tabla va a salir parecida, o incluso favorable a Java. Y **no vas a haber medido las plataformas: vas a haber
medido tus once años**. Lo peor es que la tabla va a ser correcta: los números van a ser ciertos, reproducibles
y engañosos.

Cuando lo encuentres —y la forma de encontrarlo es la declaración de defendibilidad, leída línea por línea
buscando huecos en la columna de .NET— escribe dos cosas: **cuánto cambió la tabla** al igualar de verdad, y
**cuál fue el hueco más caro**. La segunda respuesta es la lección exportable, porque es el hueco que vas a
dejar la próxima vez que evalúes una tecnología que no dominas.

<details><summary>Pista 1 — el enfoque</summary>

Escribe la declaración de defendibilidad **antes de las dos implementaciones**, como una lista de decisiones que
las dos tienen que tomar. Después impleméntalas contra esa lista. Es aburrido y es lo único que funciona: si la
escribes después, la escribes describiendo lo que hiciste.

Para el criterio 2 —el mismo SQL— captura el SQL de las dos y compáralo como texto. Si difieren, el más probable
culpable es el mapeador: un `fetch join` contra un `Include`, o un método derivado del nombre contra un LINQ
explícito. Escribe la consulta a mano en los dos lados si hace falta.

Y para el calentamiento, no elijas un número: mide. Corre la carga y grafica el p95 en el tiempo hasta que se
aplane. El punto donde se aplana es tu descarte, y es distinto en cada plataforma — eso es un dato de la tabla A,
no un inconveniente.

</details>

<details><summary>Pista 2 — la herramienta</summary>

Para AOT nativo y qué rompe:
`https://learn.microsoft.com/dotnet/core/deploying/native-aot/`

Para `CreateSlimBuilder` y qué servicios deja fuera:
`https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis/webapplication`

Para el generador de origen de `System.Text.Json`, que es requisito de AOT:
`https://learn.microsoft.com/dotnet/standard/serialization/system-text-json/source-generation`

Para la imagen nativa del otro lado: `https://docs.spring.io/spring-boot/reference/packaging/native-image/`

Y para los virtual threads en Spring Boot, que es una línea de configuración y cambia una columna entera:
`https://docs.spring.io/spring-boot/reference/features/task-execution-and-scheduling.html`

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```text
src/duelo/
  DEFENDIBILIDAD.md          ← se escribe primero, y se publica con la tabla
  compose.yml                ← las dos, con límites idénticos, contra la misma base
  contrato/
    catalogo.pruebas.http    ← el conjunto de contrato, el mismo para las dos
  dotnet/
    Cordillera.Catalog.Api.Duel/
  jvm/
    build.gradle.kts
    src/main/java/media/cordillera/catalog/
  resultados/
    duelo-<fecha>.md         ← la tabla, con la declaración adjunta
```

</details>

**Cómo se entrega**

```powershell
docker compose -f src\duelo\compose.yml up --build
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 23 --duelo --clients 200
dotnet run -c Release --project src\modern\Cordillera.Costos -- --hoja duelo --region eastus2
```

```bash
git tag -a mini-23 -m "Mini F23: p95 en regimen <A> vs <B> (empate: si/no) · arranque <C> vs <D> · <N> celdas en empate · ofertas en Bogota <O1>/<O2> · declaracion de defendibilidad publicada"
```

---

## 🧪 8. Ejercicios (24)

**🟢 Fácil (1–6)**

1. Escribe la declaración de defendibilidad completa, **antes** de implementar nada. Cuenta cuántas decisiones
   tiene: son más de las que esperabas.
2. Implementa el endpoint en ASP.NET Core con `CreateSlimBuilder` y el generador de origen. Mide arranque y
   latencia.
3. Implementa la contraparte en Spring Boot 4.1.1, configurada como la defenderías. Mide lo mismo.
4. Captura el SQL de las dos y compáralo como texto. Si difiere, arréglalo hasta que sea el mismo.
5. Cuenta las conexiones activas en el motor durante la carga, en las dos. Comprueba que el pool es de verdad
   simétrico.
6. Mide el arranque hasta la primera respuesta en las dos. Anota la diferencia sin sacar conclusiones todavía.

**🟡 Intermedio (7–13)**

7. Determina el punto de calentamiento de cada plataforma graficando el p95 en el tiempo. Publica los dos
   tiempos.
8. Activa virtual threads en el lado de Java y repite la medición de concurrencia. Anota qué columna cambió.
9. Compila ASP.NET Core con AOT nativo. Mide arranque, memoria, tamaño y **tiempo de construcción**.
10. Construye la imagen nativa del lado de Java. Mide lo mismo y compara los cuatro números.
11. Mide la memoria a las ocho horas en las dos, con una petición cada cinco minutos. Es la metodología de la
    F14.
12. Calcula el costo mensual de cada configuración al volumen de Cordillera, con la metodología de la F20.
13. Cuenta las líneas de código y de configuración de las dos, con el criterio de conteo escrito antes de
    contar.

**🟠 Difícil (14–20)**

14. **Diagnóstico.** Una implementación da un p95 cuatro veces peor y el código parece equivalente. Enumera
    cinco causas de configuración y el orden en que las verificarías. Empieza por la base.
15. **Diagnóstico.** La versión AOT nativa falla al serializar un tipo que en JIT funcionaba. Explica el
    mecanismo y arréglalo sin renunciar al AOT.
16. **Medición.** Ejecuta el duelo completo, las tres tablas, las cinco configuraciones. **Marca los empates
    como empates** y cuéntalos.
17. **Medición.** Mide las dos filas del mercado laboral en **tu** ciudad, con la misma fecha y los mismos
    filtros, y escribe la fuente. Es la única columna cuyo resultado depende de dónde vives.
18. **Adversarial sobre ti mismo.** Revisa tu declaración de defendibilidad buscando huecos **en la columna de
    .NET**. Corrígelos, vuelve a medir, y anota cuánto cambió la tabla.
19. **Decisión.** Con la tabla delante, ¿cambiarías alguna decisión del curso? Si la respuesta es no, sostenla
    con las columnas; si es sí, di cuál y qué costaría.
20. **Decisión — ¿se migra, se envuelve o se deja quieto?** La pregunta aplicada a **Convivir**, la plataforma
    en Java que vino con la adquisición de 2004 y que nunca se integró. **Y ahora tienes una tabla:** ¿cambia
    algo saber que las dos plataformas empatan en rendimiento?

**🔴 Muy difícil (21–24)**

21. **Adversarial.** Construye una versión del duelo que haga ganar a ASP.NET Core por mucho, sin mentir en
    ninguna cifra. Después otra que haga ganar a Spring Boot. Publica las dos declaraciones de defendibilidad
    lado a lado y explica qué línea de cada una lo produce.
22. **Adversarial.** Encuentra una carga realista para Cordillera en la que el ganador se invierta respecto a
    tu tabla. Si no existe, demuestra por qué no y qué tendría que cambiar del negocio.
23. **Diseño.** Escribe el documento de tres páginas que el tú de 2025 **debería** haber escrito el día once,
    con lo que sabes ahora. No es el mismo documento con la conclusión cambiada: es un documento con otras
    preguntas.
24. **Defiende una decisión ante quien no es ingeniera.** Explícale a Clara, en media página, por qué el equipo
    dedicó tiempo a implementar dos veces lo mismo y **qué compró con eso**. Sabiendo que la respuesta honesta
    incluye que el resultado fue un empate, y que un empate también es información que ella pagó.

**🔥 Opcionales**

- Repite el duelo con el endpoint que **cruza el borde 🧬** —el que llama a `SP_CATALOGO`— y compara. La
  hipótesis: la diferencia entre plataformas desaparece del todo, porque el procedimiento de 1997 domina el
  tiempo (F19). Si es así, es el mejor argumento del curso entero.
- Mide el consumo de CPU por petición en las dos y traduce a la factura. Es la columna que decide en alojamiento
  por consumo y que casi nadie mira.
- Pídele a Duván que lea las dos implementaciones y cronometra cuánto tarda en entender cada una. Es una
  medición legítima —reproducible, con condiciones— y es la fila más importante de la tabla C.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis/webapplication` — `CreateSlimBuilder` y qué
  deja fuera.
- `https://learn.microsoft.com/dotnet/core/deploying/native-aot/` — AOT nativo, sus requisitos y **qué rompe**.
- `https://learn.microsoft.com/dotnet/standard/serialization/system-text-json/source-generation` — el generador
  de origen, requisito del AOT y mejora en JIT.
- `https://docs.spring.io/spring-boot/` — la documentación del competidor, en su versión vigente. **Úsala:**
  medir contra una configuración que su propia documentación no recomendaría es el espantapájaros.
- `https://docs.spring.io/spring-boot/reference/packaging/native-image/` — la imagen nativa del otro lado.
- `https://docs.spring.io/spring-boot/reference/features/task-execution-and-scheduling.html` — virtual threads,
  una línea de configuración que cambia una columna.
- `https://openjdk.org/projects/loom/` — el modelo de concurrencia donde el competidor gana algo estructural.

**Libros / artículos**

- *Systems Performance* (Brendan Gregg) — la metodología de medir sin engañarse, y en particular por qué una
  media sin dispersión no es un resultado. **Verifica la edición antes de citarlo.**
- La literatura sobre metodología de *microbenchmarks* en la JVM —por qué hace falta calentamiento y qué
  invalida una medición— es la mejor defensa contra la trampa clásica contra Java. No se cita un texto concreto:
  verifica antes de citar.

> ⚠️ Verifica las URLs. Y la advertencia propia de esta fase, que es la más importante del curso entero:
> **casi ningún benchmark de plataformas que encuentres en internet es utilizable**. No por mala fe, sino porque
> la mayoría no iguala el pool de conexiones, no verifica el SQL emitido, mide la JVM sin calentar, o compara
> una configuración de producción contra un tutorial. La forma de detectarlo en diez segundos: **si no publica su
> declaración de defendibilidad —o algo equivalente— no tiene valor**, por bonitos que sean los gráficos. Esta
> fase publica la suya precisamente para ser criticable.

**Orden de lectura sugerido:** antes de implementar, `CreateSlimBuilder` y la documentación de configuración del
competidor — media hora, y evita la trampa—. Durante el miniproyecto, la de AOT nativo y la de imagen nativa
**antes** de compilar, porque las dos rompen la reflexión y es mejor saberlo antes. Al cerrar, el capítulo de
metodología de Gregg: se lee muy distinto cuando acabas de publicar una tabla con empates.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Existe la tabla, y existe la declaración que la hace criticable. Eso último es lo que la separa de casi todo lo
que hay publicado sobre este tema: **una comparación sin su protocolo no es una comparación, es una opinión con
gráficos**.

Y quedó el hallazgo que hace esta fase valiosa, y no es un número: **en el terreno de un servicio HTTP con base
de datos, las dos plataformas son la misma generación de la misma idea**. Enrutamiento, inyección, middleware,
serialización, mapeador, observabilidad, contenedores. No hay nada aquí que un senior de una tenga que aprender
de cero para leer la otra. Cuando dos plataformas resuelven el mismo problema con las mismas piezas, **la
diferencia entre ellas es más pequeña que la diferencia entre un equipo que domina una y un equipo que la está
aprendiendo** — que es lo que el curso llevaba veintitrés fases diciendo con gente, con procedimientos
almacenados y con facturas, y que ahora está dicho con percentiles.

Los empates se publicaron como empates, y son varios. No es un fracaso de la medición: **es el resultado**. Al
volumen de Cordillera, el rendimiento no es una razón para elegir plataforma, y saber eso con la dispersión
delante vale más que cualquier ganador.

Y donde el competidor gana algo estructural, quedó dicho sin rodeos: **los virtual threads**. No en capacidad
—cuando los dos lados usan su modelo moderno, ese eje deja de separarlos— sino **en costo de adopción**: el
código bloqueante existente escala sin reescribirse, y en .NET la concurrencia se propaga por toda la pila de
llamadas. Para un sistema nuevo da casi igual; para migrar uno viejo, es dinero. Es la clase de ventaja que no
aparece en un benchmark de latencia y aparece en un presupuesto.

Lo que esta fase **no** hizo es decidir por Cordillera, y conviene cerrar con eso porque es lo que la mantiene
honesta: la decisión estaba tomada por 700 procedimientos almacenados que nadie ha leído, unas licencias pagadas
y un compañero que sabe C#. Ninguna de las tres aparece en las tablas A ni B. Si el resultado técnico es un
empate, **el documento de tres páginas del día once no estaba equivocado en los hechos: estaba equivocado en lo
que importaba** — y esa distinción es probablemente lo más útil que este curso puede enseñar.

La fase 24 es la última y su trabajo es **admitir**. El traslado de 2020 fue un error y hay una factura que lo
cuantifica. Parte del sistema no debió migrarse, y hay que decir qué parte. La migración de los pasantes de 2016
fue, en el balance, correcta — y juzgarla desde 2026 con un presupuesto que en 2016 no existía es la forma más
común de arrogancia de ingeniero. Y hay **dos decisiones del propio curso que, con los datos delante, debieron
ser otras**, que no son un gesto de humildad sino contenido, y tienen que estar sostenidas por una medición del
propio material.

> **La señal de que quedó bien:** *"Publiqué la tabla con su declaración, un desarrollador de Java la revisó
> línea por línea buscando la trampa, y la única cosa que encontró fue una que yo ya había declarado."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el miniproyecto corriendo y
> `git status` limpio:
>
> ```bash
> git tag -a fase-23 -m "F23 cerrada:
> - el mismo endpoint dos veces, mismo contrato y mismo SQL verificado en el plan
> - declaracion de defendibilidad escrita ANTES de medir y publicada con la tabla
> - cinco configuraciones: JIT, AOT nativo, hilos de plataforma, virtual threads, imagen nativa
> - calentamiento descartado por criterio y no por reloj, con el tiempo de cada una publicado
> - empates publicados como empates, con su dispersion
> - la tabla C decide, y una de sus filas dice 'Si' y 'No'
> - y la fase NO decide por Cordillera: dice de que tamano era la diferencia"
> ```
>
> **Y el diff que a esta fase le sale al revés que a todas las demás:**
>
> ```bash
> git diff --stat fase-22 fase-23 -- src/duelo/
> ```
>
> Dos implementaciones completas y ninguna entra en producción. Es el único trabajo del curso cuyo entregable
> **es la medición y no el software**, y valía la pena por una razón que la fase 24 va a usar: *ahora la
> pregunta del día once tiene respuesta numérica, y la respuesta es que no era la pregunta.*

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura.*

- **`INSTINTOS.md`** — dos entradas para **una familia nueva, *medir y comparar***, que el curso necesitaba y no
  tenía: comparar contra un competidor de paja —**con el giro propio de esta fase: el espantapájaros que te sale
  sin querer es el de la plataforma que no dominas**— y leer una mediana sin su dispersión, que es lo que
  convierte un empate en un titular. La primera conviene enlazarla con la entrada de la F21 sobre el conjunto de
  entrenamiento: es el mismo defecto —**el sesgo está en cómo armaste lo que mides, no en la medición**— en dos
  terrenos distintos.
- **`BENCHMARKS.md`** — entrada ⏳ *F23 · El duelo, con su declaración de defendibilidad*, con tres tablas. **Y
  una regla de honestidad nueva, la séptima**: una comparación entre plataformas o productos **publica su
  declaración de defendibilidad** —qué se configuró en cada lado, con qué valor y por qué—, o no se publica. Es
  la forma fuerte de la regla 1 (*el competidor es defendible*) y es lo que la hace verificable en vez de
  declarativa.
- **Para el índice de `BENCHMARKS.md`:** la fila 23 decía *"El duelo completo: CatalogAPI en ASP.NET Core contra
  Spring Boot"*. Conviene que diga también **cinco configuraciones** y **que los empates son el resultado**,
  porque quien consulte el índice buscando un ganador tiene que ver ahí que no lo va a encontrar.
- **Corregido en la maquinaria antes de escribir, y queda registrado:** la propuesta decía **Spring Boot 3** y la
  línea vigente es **4.1.1** (21 de agosto de 2026, sobre Java 25 LTS). Quedó anotado en
  `propuesta-fases-y-alcance.md` §10.5 con la razón —medir contra una línea anterior sería el espantapájaros que
  la fase existe para evitar— y en `alcance-del-proyecto.md` §9 con su fuente. **También quedó declarado que las
  variantes de compilación no son un tercer competidor**, que era la duda razonable que §10.5 no cubría.
- **Tipos y directorios nuevos para el congelamiento:** el árbol `src/duelo/` completo, que es **el tercer
  subárbol del repositorio** y hay que declararlo: el curso tenía la regla de "dos subárboles, `legacy/` y
  `modern/`, y no hay un tercero". **Esta es la excepción y no contradice la regla**, porque la razón de aquella
  era que un directorio intermedio se convierte en el sitio donde se esconde el código a medio migrar — y
  `src/duelo/` no es código de Cordillera: es un experimento que no entra en producción. Conviene que el
  congelamiento lo diga con esas palabras.
- **Para la fase 24:** cinco insumos, y es la fase que más le aporta al cierre — el empate técnico (que sostiene
  la tesis del curso entero con números), la ventaja estructural de Loom (que es lo más cerca que el curso llega
  a decir *aquí el otro gana*), el ejercicio 23 (el documento que debió escribirse), el ejercicio 🔥 del endpoint
  que cruza el borde 🧬 —cuya hipótesis, si se confirma, es el mejor argumento del curso: **la diferencia entre
  plataformas desaparece cuando el tiempo lo domina un procedimiento de 1997**— y el ejercicio 20 sobre Convivir,
  que enlaza con lo que no debió migrarse.
