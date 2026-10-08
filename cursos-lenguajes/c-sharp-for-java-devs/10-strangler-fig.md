# 🌿 Fase 10 ⭐ — *Strangler fig*: la API en medio, doble escritura y vuelta atrás

> C# para desarrolladores Java senior · Fase 10 de 24 · Bloque B ⭐ — el sistema heredado y la frontera
> Depende de: 09 · Habilita: 11
> Estilo de esta fase: **mixto 🧬** — el cliente WinForms y los procedimientos siguen siendo de 2017; la
> API que se pone en medio es .NET 10. El corte entre los dos es el contenido de la fase.
> Proyecto que avanza: **SIGE + CatalogAPI**. Al terminar, existencias se escribe por los dos caminos a
> la vez, con bandera de corte, conciliación y una vuelta atrás que se ejecutó de verdad.

---

## 🎯 1. Propósito

Responder, con un procedimiento ejecutable y no con un diagrama, la pregunta que ordena el curso:
**¿esto se migra, se envuelve o se deja quieto?**

Hasta aquí se leyó el sistema, se puso la red y se midió el acceso a datos. Pero **noventa
instalaciones siguen escribiendo directo a la base con permiso sobre todo**, y mientras eso sea cierto
cualquier otra mejora es cosmética. Esta fase pone una API en medio sin apagar nada, la valida contra el
sistema vivo, y **demuestra que se puede volver atrás** — porque un procedimiento de reversión que nadie
ejecutó no es un procedimiento de reversión.

> 🧭 **La restricción que gobierna la fase, y es de Clara y no de arquitectura:** *"Ustedes me están
> pidiendo que pare la editorial dos años para que el sistema se vea mejor por dentro."* Nada de lo que
> esta fase construya puede implicar una ventana de parada. Cada paso se despliega con la editorial
> facturando, y cada paso tiene su vuelta atrás.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Existe una **API interna de existencias** en `Cordillera.Catalog.Api` que hace lo mismo que hace
      hoy el formulario contra la base, y está probada contra las fotos de la fase 08.
- [ ] La **doble escritura** funciona: un movimiento de inventario se escribe por el camino viejo y por
      el nuevo, y hay una consulta de conciliación que compara los dos estados.
- [ ] Existe una **bandera de corte por funcionalidad** que decide, sin recompilar y sin desplegar, qué
      porcentaje del tráfico va por cada camino.
- [ ] **La vuelta atrás se ejecutó de verdad**, con la editorial funcionando, y está documentada con el
      tiempo que tardó y lo que quedó inconsistente —si algo quedó—.
- [ ] Está escrito **el orden de los cortes**, con su criterio de riesgo, y quién lo firma.
- [ ] 💸 **Se cobra la deuda de la fase 08**: el *golden master* atado a la semilla se reemplaza por
      conciliación por propiedades donde la comparación tiene que resistir un cambio de datos.
- [ ] La sección del track `cv` está escrita: **Convivir**, la plataforma Java de 2004, envuelta sin
      tocarla.
- [ ] La medición de la sección 6 está escrita con su comando, y la entrada quedó en `BENCHMARKS.md`.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Mover el runtime** → fase 11. El cliente sigue en .NET Framework 4.8 durante toda esta fase, **y eso
  es deliberado**: cortar la conexión directa primero y mover el runtime después es el orden que hace
  posible las dos cosas.
- **La nube y el costo de operar dos caminos** → fase 20.
- **El outbox de verdad, con reintentos y garantías** → fase 17. Aquí la doble escritura entra **sin
  conciliación automática**, y es deuda declarada.
- **El contrato público de CatalogAPI** —versionado, OpenAPI, autenticación de socios— → fases 15 y 16.
  La API de esta fase es interna: la consume el formulario, no Almenara.
- **Migrar los 340 formularios** → Bloque C. Aquí se toca **uno**, el de existencias, y solo para que
  llame a la API en vez de a la base.

---

## 🧠 4. Concepto mínimo

### Qué es un *strangler fig*, sin la metáfora

La higuera estranguladora crece alrededor de un árbol, lo va rodeando, y cuando el árbol muere la higuera
ya tiene forma de árbol. La metáfora es bonita y **no dice cómo se hace**, así que aquí va sin ella.

Un *strangler fig* es un procedimiento con cuatro propiedades, y las cuatro son verificables:

**Primera: hay dos caminos simultáneos para la misma operación.** El viejo sigue funcionando, intacto. El
nuevo funciona al lado. Nadie eligió todavía.

**Segunda: alguien decide, en tiempo de ejecución, qué camino se usa.** No en compilación, no en
despliegue: en ejecución, y con un interruptor que se puede mover en un minuto. Sin eso, "volver atrás"
significa desplegar, y desplegar bajo presión a las tres de la tarde de un martes es cómo se convierte un
problema en un incidente.

**Tercera: se puede comparar el resultado de los dos caminos.** Mientras los dos existen, cada operación
es una oportunidad de verificar que producen lo mismo — y las diferencias que aparecen **son
información**, no ruido: casi siempre revelan una regla del sistema viejo que nadie había escrito.

**Cuarta: el camino viejo se apaga cuando la comparación deja de encontrar diferencias**, y no cuando el
cronograma lo dice. Esa es la propiedad que la mayoría de las migraciones no respeta.

> 🧠 **El modelo mental:** un *strangler fig* no es una arquitectura, es **un procedimiento de despliegue
> con dos implementaciones vivas y un interruptor**. La parte difícil no es el código nuevo: es el
> interruptor, la comparación, y tener la disciplina de no apagar nada hasta que los números lo permitan.

### El orden de los cortes lo decide el riesgo, y lo firma la presidenta

Aquí está la parte de la fase que no es técnica, y es la que más falta en los cursos.

Cuando hay que cortar cuatro módulos, el orden parece una decisión de arquitectura: *"empecemos por el
que tiene menos dependencias"*. No lo es. El orden lo decide **qué pasa si ese corte sale mal**, y eso
no lo sabe el que escribe el código.

Así se ve la conversación de verdad, y conviene leerla completa porque es el contenido:

> **Tú:** Propongo empezar por existencias. Es el módulo que tiene el borde ya mapeado de la fase
> anterior, es el que menos procedimientos toca, y la API queda lista en dos semanas.
>
> **Clara:** ¿Qué pasa si sale mal un jueves?
>
> **Tú:** El almacén no puede registrar entradas ni salidas hasta que volvamos atrás. Unos veinte
> minutos, con el interruptor.
>
> **Clara:** Veinte minutos en Bogotá, ¿y en Lima? Porque en Lima el depósito despacha hasta las seis y
> allá son las cuatro cuando aquí son las cinco.
>
> **Tú:** …
>
> **Clara:** Y si sale mal en facturación, ¿qué pasa?
>
> **Tú:** No se puede facturar. Pero facturación tiene menos volumen y el corte es más simple.
>
> **Clara:** Entonces no. Si no se puede facturar cuatro horas, eso lo veo yo en la cuenta del mes y me
> llaman tres clientes. Si el almacén no registra cuatro horas, lo anotan en un cuaderno y lo cargan
> después — eso lo han hecho siempre. **Empecemos por donde el error se puede absorber a mano.**

Clara acaba de dar el criterio correcto y no es de ingeniería: **el orden de los cortes va de menor a
mayor costo de un fallo no absorbible**. Un módulo cuyo fallo alguien puede suplir con papel es un buen
primer corte, aunque técnicamente sea más difícil. Un módulo cuyo fallo se ve en la cuenta del mes va al
final, aunque sea el más fácil.

De ahí sale el orden del curso, y ahora tiene una razón escrita:

| Orden | Módulo | Si el corte falla… | Absorbible a mano |
|---|---|---|---|
| 1.º | **Existencias** | El almacén no registra movimientos | **Sí** — se anota y se carga después. Lo han hecho siempre |
| 2.º | **Catálogo** (lectura) | Los volcados a socios salen viejos | **Sí** — un día de desfase, y ya pasa hoy |
| 3.º | **Regalías** | No se puede liquidar el trimestre | Parcialmente — tiene una ventana de días |
| 4.º | **Facturación** | No se puede facturar | **No** — se ve en la cuenta del mes y llaman los clientes |

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

Este reflejo tiene dos caras y **las dos llevan al mismo sitio**, que es lo que lo hace difícil de
ver: una parece ambiciosa y la otra parece prudente.

**Cara A: el *big bang*.**

```text
Propuesta: reescribir el sistema en dos años y medio, en microservicios, con el equipo
actual más cuatro contrataciones. Al final del segundo año se hace el corte.
```

Es la propuesta que un consultor le llevó a Clara en 2021 y que ella rechazó con la frase que define la
década. **Por qué falla:** porque el corte al final es un evento único, no ensayado, y sin vuelta atrás
—después de dos años de divergencia, el sistema viejo ya no puede recibir los datos del nuevo—. Y porque
durante veinticuatro meses el negocio no recibe nada mientras el mantenimiento del sistema viejo sigue
consumiendo a las mismas personas.

**Cara B, la prudente: "primero refactorizamos y después migramos".**

```text
Propuesta: dedicar seis meses a limpiar el código heredado —normalizar el esquema, sacar la
lógica de los procedimientos, quitar el SQL dinámico— y cuando esté limpio, migrar.
```

Suena responsable y **falla por la misma razón con otra cara**: seis meses sin entregar nada, un riesgo
grande de romper lo que funciona, y al final del semestre el sistema está igual de viejo y un poco más
frágil — porque refactorizar código heredado **sin haber cortado nada** significa tocar el sistema en
producción sin que la arquitectura haya cambiado. Es todo el riesgo y ninguno de los beneficios.

```text
✅ Lo que esta fase hace en su lugar:
   Semana 1-2   API de existencias al lado, sin que nadie la use. Riesgo: cero.
   Semana 3     Lectura por el camino nuevo, 5% del tráfico. Comparación contra el viejo.
   Semana 4     Lectura al 100%. El viejo sigue ahí, intacto.
   Semana 5-6   Escritura doble. Ninguna operación depende del camino nuevo todavía.
   Semana 7     Conciliación diaria. Se corrigen las tres diferencias que aparecieron.
   Semana 8     El camino nuevo pasa a ser la fuente. El viejo queda como respaldo.
   Semana 12    Se apaga el viejo, si la conciliación lleva cuatro semanas en cero.
```

**Por qué funciona esto y no lo otro:** porque **cada línea de arriba es reversible en minutos** y cada
una entrega algo. En la semana 3 ya hay información —la comparación— y en la semana 8 el negocio ya tiene
la conexión directa cortada. Si el proyecto se cancela en la semana 6 por una razón que nadie previó, lo
hecho hasta ahí **sirve igual**, y eso es la diferencia que ninguna presentación de *big bang* puede
ofrecer.

**Dónde se rompe el paralelo con lo que traes:** en un banco con quince personas y un comité, el
despliegue progresivo era una práctica de infraestructura que mantenía alguien más. Aquí **eres tú quien
lo escribe**, y el interruptor no viene de una plataforma: es una tabla, una consulta y un minuto de
disciplina. La técnica es la misma; el presupuesto no.

### 🩻 Esto sí funciona igual

El versionado de contrato y la compatibilidad hacia atrás, que es la mitad de esta fase. Saber que un
consumidor no se actualiza el mismo día que el productor, que un campo se agrega y no se quita, que una
respuesta puede crecer y no encogerse — todo eso vale aquí igual y con las mismas reglas.

También se transfiere el razonamiento de **idempotencia**, que aquí aparece por primera vez y se
desarrolla en la fase 17: si una operación se puede repetir sin duplicar su efecto, la vuelta atrás es
mucho más barata. Si no, cada reintento es un riesgo.

Y se transfiere algo menos técnico y más importante: la experiencia de haber visto un despliegue salir
mal. El instinto de preguntarse *"¿y si esto falla a las tres de la tarde?"* antes de escribir la primera
línea es exactamente lo que esta fase pide, y no se enseña — se trae.

### 📖 Diccionario de traducción

| Mundo Java / el banco | Este curso · .NET | Dónde se rompe el paralelo |
|---|---|---|
| *feature flag* de una plataforma | una tabla + `IOptionsMonitor` | Lo escribes tú, y la recarga en caliente la da el propio `IOptionsMonitor` sin reiniciar |
| despliegue *canary* del ingress | porcentaje de tráfico en la bandera de corte | No hay malla de servicios: el porcentaje lo decide el código que consulta la bandera |
| *blue-green* | los dos caminos vivos a la vez | Aquí no hay dos entornos: hay **dos implementaciones en el mismo proceso**, que es más barato y más íntimo |
| *shadow traffic* | doble escritura con comparación | Igual de concepto. La diferencia es que aquí la fuente de verdad **sigue siendo la vieja** hasta la semana 8 |
| `@Transactional` sobre dos recursos | **no existe** | No hay transacción distribuida. La doble escritura se resuelve con outbox (F17) o se acepta la divergencia y se concilia |
| Spring Boot Actuator | comprobaciones de salud de ASP.NET Core | Equivalente, y se desarrolla en la fase 19 |
| Testcontainers para la conciliación | Testcontainers | La misma biblioteca, otra vez |
| `RestTemplate`/`WebClient` hacia el legado | `HttpClient` con `IHttpClientFactory` | **La fábrica no es opcional**: un `HttpClient` nuevo por llamada agota los sockets, y el error aparece bajo carga |
| API de un sistema Java que no controlas | **Convivir**, envuelto y sin tocar | Es la sección del track `cv`, y es la situación más común del lector después del curso |

> 📝 **Nota de ecosistema.** *Strangler fig* es un nombre que Martin Fowler le puso en 2004 a algo que la
> gente ya hacía, y el término no se traduce: en la documentación y en las conversaciones se dice
> *strangler fig* o *strangler pattern*, igual que en inglés. "Higuera estranguladora" no lo dice nadie,
> y traducirlo forzadamente deja al lector sin el término con el que va a encontrar el material.

---

## 💻 5. Código mínimo con comentarios

### 5.1 La bandera de corte, que es lo más importante de la fase

```csharp
// src/modern/Cordillera.Catalog.Api/Cutover/CutoverSwitch.cs
namespace Cordillera.Catalog.Api.Cutover;

/// <summary>
/// Decide, **en tiempo de ejecución**, qué camino atiende cada operación. Es lo que convierte la
/// vuelta atrás en un cambio de un minuto en vez de un despliegue.
/// </summary>
/// <remarks>
/// Vive en una tabla de SQL Server —la misma base, porque agregar una dependencia nueva para el
/// interruptor de emergencia sería exactamente el tipo de decisión que esta fase enseña a no
/// tomar— y se recarga cada quince segundos. Quince y no uno: un interruptor que se consulta en
/// cada petición es un `SELECT` por petición, y ese es el primer sitio donde alguien mete una
/// dependencia a la base en la ruta caliente sin darse cuenta.
/// </remarks>
public sealed class CutoverSwitch(IOptionsMonitor<CutoverOptions> options, ILogger<CutoverSwitch> log)
{
    /// <summary>
    /// Qué camino atiende esta operación. El porcentaje se resuelve con un hash del identificador
    /// de la operación y **no con un número aleatorio**: así la misma operación va siempre por el
    /// mismo camino, y un reintento no cambia de ruta a mitad.
    /// </summary>
    public CutoverPath PathFor(string operationKey)
    {
        CutoverOptions current = options.CurrentValue;

        if (!current.Enabled)
        {
            // El estado seguro por omisión es el camino viejo. Si la tabla no se puede leer, si la
            // configuración está corrupta o si nadie tocó nada, el sistema sigue funcionando como
            // funcionaba ayer. Es la decisión de diseño más importante de este archivo.
            return CutoverPath.Legacy;
        }

        if (current.Percentage >= 100)
        {
            return CutoverPath.Modern;
        }

        if (current.Percentage <= 0)
        {
            return CutoverPath.Legacy;
        }

        // Hash estable del identificador de operación, no Random: la misma clave produce siempre
        // la misma decisión, en este proceso y en el de al lado.
        int bucket = (int)(XxHash32.HashToUInt32(Encoding.UTF8.GetBytes(operationKey)) % 100);

        return bucket < current.Percentage ? CutoverPath.Modern : CutoverPath.Legacy;
    }

    /// <summary>
    /// La vuelta atrás. Una línea, sin despliegue, sin recompilar, y con su registro — porque la
    /// pregunta "¿quién lo apagó y a qué hora?" se hace siempre al día siguiente.
    /// </summary>
    public async Task RollbackAsync(string reason, string who, CancellationToken token)
    {
        log.LogWarning(
            "Vuelta atrás del corte de existencias. Motivo: {Motivo}. Ejecutada por: {Quien}.",
            reason, who);

        await _store.SetAsync(new CutoverOptions(Enabled: false, Percentage: 0), token);
    }
}

public enum CutoverPath
{
    /// <summary>El camino de 2017: el formulario escribe directo a la base.</summary>
    Legacy,

    /// <summary>El camino nuevo: el formulario llama a la API.</summary>
    Modern,
}
```

**Detalles con intención**

- **El estado seguro por omisión es el camino viejo**, y eso se decide en la primera comprobación del
  método. Si algo falla en la lectura de la bandera —la tabla no responde, el JSON está mal— el sistema
  se comporta como ayer. La alternativa —que un fallo del interruptor mande todo al camino nuevo— es cómo
  se convierte un problema de configuración en un incidente.
- **El porcentaje se resuelve con un hash y no con azar.** Con `Random`, el mismo movimiento podría ir
  por el camino nuevo en el primer intento y por el viejo en el reintento, y entonces la comparación no
  significa nada. Con un hash estable, la decisión es reproducible y **auditable**.
- **La bandera vive en la misma base.** Es deliberadamente aburrido: agregar un servicio de
  configuración distribuida para el interruptor de emergencia introduce una dependencia nueva en el
  camino crítico, que es exactamente lo que esta fase enseña a no hacer.

### 5.2 La doble escritura, y qué se hace cuando los dos caminos discrepan

```csharp
// src/modern/Cordillera.Catalog.Api/Inventory/DualWriteInventoryService.cs
/// <summary>
/// Escribe un movimiento de inventario por los dos caminos y compara. Durante la ventana de
/// convivencia **la fuente de verdad sigue siendo el camino viejo**: si el nuevo discrepa, gana el
/// viejo y la diferencia se registra.
/// </summary>
public sealed class DualWriteInventoryService(
    LegacyInventoryGateway legacy,      // 🧬 llama a SP_MOVINVEN_INS, el de 2017
    ModernInventoryRepository modern,   // el borde de la fase 09
    IDivergenceLog divergences,
    CutoverSwitch cutover)
{
    public async Task<MovementResult> RegisterAsync(MovementRequest request, CancellationToken token)
    {
        // El orden importa y no es intercambiable: **primero el viejo**. Es el que manda, así que
        // si falla, la operación falla y el camino nuevo no se ejecuta. Al revés, un fallo del
        // camino nuevo podría dejar escrito algo que el sistema oficial no tiene.
        MovementResult authoritative = await legacy.InsertMovementAsync(request, token);

        if (cutover.PathFor(request.OperationKey) == CutoverPath.Legacy)
        {
            return authoritative;
        }

        try
        {
            MovementResult shadow = await modern.InsertMovementAsync(request, token);

            if (!shadow.Equals(authoritative))
            {
                // Una diferencia NO es un error: es información. Casi siempre revela una regla del
                // sistema viejo que nadie había escrito — y de las tres que aparecieron en esta
                // fase, dos eran eso y una era un bug del camino nuevo.
                await divergences.RecordAsync(request, authoritative, shadow, token);
            }
        }
        catch (Exception ex)
        {
            // Aquí sí hay un `catch` ancho, y es el único del curso que se defiende: el camino
            // nuevo es una sombra y **no puede tumbar la operación real**. Se registra con todo el
            // detalle y se sigue. El comentario es obligatorio, y esta es su razón.
            await divergences.RecordFailureAsync(request, ex, token);
        }

        return authoritative;
    }
}
```

**El patrón a memorizar**

> **Durante la convivencia hay una sola fuente de verdad, y es la vieja.** La doble escritura no es
> "escribir en dos sitios y esperar que coincidan": es **escribir en el que manda y verificar en el
> otro**. El día que se invierte —semana 8 del plan— es una decisión explícita que se toma con los
> números de la conciliación en la mano, y tiene su propia vuelta atrás.

> 💸 **Deuda declarada: la doble escritura entra sin conciliación automática.**
>
> Lo que hay es un registro de divergencias y **una consulta que alguien ejecuta**. Lo que falta es lo
> difícil: qué pasa cuando el camino nuevo falla después de que el viejo escribió —queda una operación
> en el sistema oficial que la sombra no tiene— y cómo se repara sin intervención manual. La respuesta
> correcta es el **patrón outbox** con reintentos idempotentes, y se construye en la **fase 17**.
>
> La factura será `git diff fase-10 fase-17 -- src/modern/Cordillera.Catalog.Api/Inventory/`.
>
> **Por qué se deja:** porque durante la ventana de convivencia la divergencia es **tolerable y medible**
> —la fuente de verdad es la vieja, así que una sombra incompleta no daña nada— y porque construir el
> outbox antes de saber **cuántas** divergencias hay al día sería dimensionar a ciegas. La medición de
> la sección 6 produce ese número, y la fase 17 lo usa.

### 5.3 El cobro de la deuda de la fase 08: conciliar estados, no comparar salidas

```csharp
// 💸 Cobro de la deuda de la fase 08. Allí las fotos comparaban la salida literal de un
//    procedimiento contra un archivo, y eso ataba las pruebas a la semilla `19970417`: cambiar un
//    dato del generador invalidaba todas a la vez, con un diff enorme que no decía qué pasó.
//
//    La conciliación de esta fase no puede depender de eso: los datos cambian todos los días,
//    porque el sistema está en producción. Así que se compara por **propiedades** — invariantes
//    que tienen que cumplirse con cualquier conjunto de datos.
//
//    La factura: git diff fase-08 fase-10 -- src/modern/Sige.Characterization.Tests/
public sealed record ReconciliationReport(
    int OperationsCompared,
    int Matching,
    IReadOnlyList<Divergence> Divergences)
{
    /// <summary>
    /// Las cuatro invariantes que se verifican, y ninguna menciona un número concreto: así la
    /// conciliación vale hoy, mañana y con los datos de producción.
    /// </summary>
    public static IReadOnlyList<Invariant> Invariants =>
    [
        // 1. Para cada edición y almacén, el saldo de EXISTENC coincide con la suma de MOVINVEN
        //    no borrados. (Ojo: hoy NO se cumple en 47 casos, y eso es un hallazgo de la fase 07
        //    que esta conciliación vuelve a encontrar sola — buena señal.)
        new("saldo-consistente", …),

        // 2. Todo movimiento escrito por el camino nuevo existe en el viejo con el mismo
        //    NROMOVTO, cantidad y fecha.
        new("sombra-completa", …),

        // 3. La suma de cantidades por almacén es igual en los dos caminos.
        new("total-por-almacen", …),

        // 4. Ningún movimiento del camino nuevo tiene un CODEDIT que el viejo no tenga.
        new("sin-codigos-inventados", …),
    ];
}
```

**Detalles con intención**

- **Las invariantes no mencionan números.** Es la diferencia entera con las fotos de la fase 08, y es lo
  que las hace útiles en producción: una foto vale para una base congelada; una invariante vale para
  cualquiera.
- **La invariante 1 falla hoy, en 47 casos**, y el informe lo dice. Es el defecto de `SP_MOVINVEN_INS`
  que la fase 07 escribió a propósito, reencontrado por una herramienta distinta. Cuando dos métodos
  independientes encuentran el mismo defecto, el defecto existe.
- **Las fotos de la fase 08 no se borran.** Siguen sirviendo para lo que sirven —detectar un cambio de
  comportamiento con datos fijos— y la conciliación sirve para lo otro. El cobro de la deuda no es
  reemplazar: es **dejar de usar la foto donde la foto no llegaba**.

### 5.4 🧩 El track `cv` en el camino base: envolver Convivir sin tocarlo

Aquí está el momento del curso que más se parece a la vida real del lector después del curso, y conviene
decirlo así: **la mitad de las empresas que adoptan .NET moderno lo hacen con algo en Java al lado que
nadie va a apagar.**

**Convivir** es la plataforma que llegó con la adquisición de la Universitaria del Bajío en 2004.
Corre en Java, gestiona las suscripciones institucionales de las universidades mexicanas, y nunca se
integró del todo. Tiene tres propiedades que la hacen un caso de libro:

- **Funciona.** Factura, cierra periodos, y sus usuarios están conformes.
- **Nadie del equipo actual lo escribió** y no hay presupuesto para reescribirlo.
- **Habla un protocolo que no elegiste:** SOAP sobre HTTP, con un WSDL de 2004, tipos con nombres en
  inglés y fechas en un formato propio.

```csharp
// src/modern/Cordillera.Catalog.Api/Convivir/ConvivirGateway.cs
/// <summary>
/// La frontera con Convivir. **No se migra y no se toca**: se envuelve, y el envoltorio es el único
/// sitio del sistema que sabe que existe.
/// </summary>
/// <remarks>
/// Esta clase es la respuesta a la tercera opción de la pregunta del curso —"se deja quieto"— con la
/// pieza que la hace viable: un adaptador delgado, con su propio modelo de datos, que traduce en la
/// frontera y **no deja que el vocabulario de Convivir entre al dominio**.
///
/// Lo que NO hace, y es deliberado: no intenta ser genérico, no abstrae "un proveedor de
/// suscripciones", y no tiene una interfaz con una sola implementación (fase 04). Hay un sistema
/// Java al otro lado y solo uno.
/// </remarks>
public sealed class ConvivirGateway(HttpClient http, ILogger<ConvivirGateway> log)
{
    public async Task<InstitutionalSubscription?> FindSubscriptionAsync(
        string institutionTaxId,
        CancellationToken token)
    {
        // SOAP a mano. Sin generador de cliente: el WSDL de 2004 produce un cliente que no compila
        // en .NET 10, y arreglarlo cuesta más que escribir las dos peticiones que hacen falta.
        // Eso es una decisión medida, no pereza — y está en el ejercicio 19.
        string envelope = BuildEnvelope(institutionTaxId);

        using var content = new StringContent(envelope, Encoding.UTF8, "text/xml");
        content.Headers.Add("SOAPAction", "urn:convivir:ConsultarSuscripcion");

        using HttpResponseMessage response = await http.PostAsync("/convivir/ws/suscripciones", content, token);

        if (!response.IsSuccessStatusCode)
        {
            // Convivir devuelve 500 con un cuerpo SOAP Fault cuando la institución no existe, en
            // vez de 404. No se arregla: se traduce, aquí, y el resto del sistema nunca lo sabe.
            log.LogInformation(
                "Convivir respondió {Codigo} para el NIT {Nit}; se interpreta como no encontrada.",
                (int)response.StatusCode, institutionTaxId);

            return null;
        }

        return ParseSubscription(await response.Content.ReadAsStringAsync(token));
    }
}
```

**Detalles con intención**

- **El envoltorio traduce las rarezas del otro sistema y no las propaga.** Que Convivir devuelva 500 en
  vez de 404 es un hecho del mundo; que el dominio de Cordillera lo sepa sería un error de diseño.
- **No hay abstracción especulativa.** Es una clase concreta para un sistema concreto, y cuando aparezca
  el segundo —si aparece— se extrae la interfaz con dos implementaciones reales delante.
- **La decisión de escribir el SOAP a mano está medida**, no supuesta: el ejercicio 19 pide comparar las
  dos opciones. Es el tipo de decisión pequeña que, mal tomada, cuesta una semana.

> 🧭 **Y la regla que se lleva el lector, que es el corazón de la tercera respuesta:** *un sistema que
> funciona, que nadie de tu equipo escribió y que nadie va a apagar no es un problema de migración: es
> una dependencia externa.* Se le habla por un contrato, se traduce en la frontera, y se le exige lo
> mismo que a cualquier servicio de un tercero: tiempo límite, reintentos, y un registro de lo que
> respondió. Tratarlo como código propio pendiente de arreglar es cómo se pierden dos años.

**Prueba de fuego**

```powershell
# La vuelta atrás, ejecutada. No descrita: ejecutada, y cronometrada.
dotnet run --project src\modern\Cordillera.Ops -- cutover --status
dotnet run --project src\modern\Cordillera.Ops -- cutover --percentage 50
dotnet run --project src\modern\Cordillera.Ops -- cutover --rollback --reason "prueba de reversión" --who "tu nombre"
dotnet run --project src\modern\Cordillera.Ops -- reconcile --since "2026-04-15"
```

Y la mentira que te va a contar la salida si miras el lugar equivocado: **la vuelta atrás va a parecer
instantánea**, porque el comando termina en un segundo. Lo que tarda es que los procesos vivos vuelvan a
leer la bandera —hasta quince segundos— y lo que de verdad importa es **qué pasa con las operaciones que
estaban a mitad de camino en ese momento**. Cronometrar el comando es medir lo fácil; el número que hay
que reportar es **desde que decides volver atrás hasta que la última operación en vuelo terminó por el
camino viejo**.

---

## 📏 6. Medición

**Hipótesis A:** el camino nuevo —API en medio, con el borde de la fase 09— tiene latencia **mayor** que
el acceso directo del formulario a la base, porque agrega un salto de red y una serialización. La
pregunta no es si es más lento: es **cuánto**, y si ese costo es aceptable para lo que compra.

**Hipótesis B:** la doble escritura produce divergencias durante la ventana de convivencia, y **la
mayoría no son bugs del camino nuevo**: son reglas del sistema viejo que nadie había escrito. El número
de divergencias por día es el que dimensiona el outbox de la fase 17.

**Condiciones:** SQL Server 2025 en contenedor sobre WSL 2 · base del generador, semilla `19970417`, más
el tráfico sintético de un día de operación del almacén —unos 1.400 movimientos, el volumen real de
Bogotá— · SDK 10.0.401 · la API y el gateway heredado en el mismo equipo, y **también con 40 ms de
latencia inyectada** para simular la VPN del depósito de Lima · 30 repeticiones con 5 de calentamiento
descartadas · arnés propio.

**Competidores:**

- **Acceso directo**, que es el statu quo: el formulario llama a `SP_MOVINVEN_INS`. Es el competidor que
  hay que vencer o al menos empatar, y es completamente defendible: lleva nueve años funcionando.
- **API en medio, escritura simple** por el camino nuevo.
- **API en medio, doble escritura** — el estado real durante la convivencia, que es el que se va a
  desplegar.
- Y las tres, **otra vez, con la latencia de Lima inyectada**, porque una medición hecha solo en la
  máquina local diría que todo está bien.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 10 --latency 0,40
```

**Resultado:** ⏳ pendiente de ejecución en tu máquina.

**A · Latencia y tasa de error por camino**

| Camino | Latencia p50 | p95 | Tasa de error | Con 40 ms inyectados: p95 |
|---|---|---|---|---|
| Acceso directo (statu quo) | ⏳ | ⏳ | ⏳ | ⏳ |
| API en medio, escritura simple | ⏳ | ⏳ | ⏳ | ⏳ |
| API en medio, doble escritura | ⏳ | ⏳ | ⏳ | ⏳ |

**B · Divergencia medida durante la ventana de convivencia**

| Categoría de divergencia | Cuántas en 1.400 operaciones | Qué era |
|---|---|---|
| Regla del sistema viejo no documentada | ⏳ | Información: hay que escribirla |
| Bug del camino nuevo | ⏳ | Se arregla |
| Diferencia tolerable y declarada | ⏳ | Se documenta y se acepta |
| Fallo del camino nuevo sin escritura | ⏳ | **El número que dimensiona el outbox de la F17** |

> ⚖️ **Veredicto** *(expectativa, todavía sin ejecutar — `formato-de-mediciones.md` §2.6)*. Se espera que
> el camino nuevo sea **más lento** que el directo, y que con la latencia de Lima inyectada la diferencia
> relativa se **reduzca** —porque el salto de red pasa a ser una fracción menor del total—, lo cual es
> contraintuitivo y es el hallazgo interesante de la tabla A.
>
> **Los dos umbrales que tu ejecución tiene que determinar:** (1) **cuánta latencia adicional es
> aceptable** para el formulario de existencias, que no es una pregunta técnica — es Duván mirando la
> grilla y diciendo si se siente igual; y (2) **cuántas divergencias por día**, que es lo que la fase 17
> necesita para dimensionar el outbox.
>
> Y el veredicto que esta fase **no** puede dar: *"el camino nuevo es mejor porque es más moderno"*. Es
> más lento y cuesta más operar. Lo que compra es que noventa equipos dejen de tener permiso de
> escritura sobre todo, que la lógica se pueda probar, y que el runtime se pueda mover después. **Ese
> intercambio es la decisión, y se defiende con los números de arriba y no con el adjetivo.**

---

## 🧱 7. Miniproyecto — la API en medio para existencias, con la vuelta atrás ejecutada

**El encargo**

Clara, en una reunión de treinta minutos de la que sales con tres frases apuntadas: *"Entiendo que hay
que sacar a los noventa equipos de la base. Lo que no voy a aprobar es una fecha de corte donde si algo
sale mal esperamos a que ustedes lo arreglen. Quiero saber tres cosas: **quién aprieta el botón para
volver atrás, cuánto tarda, y cómo sabemos que funcionó**. Y quiero que lo prueben antes, no el día."*

**Por qué duele**

Porque las tres preguntas de Clara son de operación y no de código, y la tercera es la difícil: *"cómo
sabemos que funcionó"* no se responde con un log. Se responde con una conciliación que corre después de
la vuelta atrás y dice, con datos, que el sistema quedó consistente — o **qué quedó inconsistente y
cuánto**, que también es una respuesta válida si el número es pequeño y alguien lo puede arreglar a mano.

Y porque la vuelta atrás tiene una trampa que no se ve hasta que se ejecuta.

**Datos de entrada**

La base del generador, más un día sintético de operación del almacén de Bogotá:

| Qué | Cuánto | Detalle |
|---|---|---|
| Movimientos del día | **1.400** | El volumen real de Bogotá: entradas, salidas y ajustes |
| … de ellos, ajustes con cantidad negativa | ~90 | Válidos, y el camino nuevo tiene que aceptarlos |
| … con `CODEDIT` que no existe | **12** | El almacén registra contra una edición que se dio de baja |
| Operaciones durante la ventana de vuelta atrás | **al menos 20** | Las que están en vuelo cuando se aprieta el botón |
| Latencia inyectada, segunda corrida | **40 ms** | La VPN del depósito de Lima |

**Criterios de aceptación**

1. La API de existencias atiende lectura y escritura, y **el formulario de SIGE la consume** en vez de
   llamar a la base — con la bandera de corte decidiendo, sin recompilar.
2. La bandera acepta `0`, un porcentaje y `100`, y **el estado seguro por omisión es el camino viejo**.
   Una prueba lo demuestra corrompiendo la configuración.
3. La doble escritura funciona y hay un **informe de divergencias** con las cuatro categorías de la
   tabla B, clasificadas a mano por ti.
4. **La vuelta atrás se ejecuta de verdad**, con tráfico en vuelo, y se reporta: quién la ejecutó, cuánto
   tardó **desde la decisión hasta que la última operación en vuelo terminó**, y el resultado de la
   conciliación posterior. Un procedimiento descrito y no ejecutado **no cumple este criterio**.
5. La conciliación verifica **invariantes, no números fijos** —es el cobro de la deuda de la fase 08— y
   corre contra la base después de la vuelta atrás.
6. **Medición de cierre:** las tres latencias de la tabla A con y sin los 40 ms, y el conteo de
   divergencias por categoría. Van en el mensaje del tag `mini-10`.

**Restricciones de estilo y alcance**

🧬 Mixta y con el borde marcado. La API es .NET 10; el formulario que la consume sigue siendo .NET
Framework 4.8 y **se toca lo mínimo**: cambiar la llamada a la base por una llamada HTTP es el único
cambio permitido en ese archivo. Nada de modernizar el formulario de paso — eso es el Bloque C.

El esquema **no se modifica**, salvo la tabla de la bandera de corte, que es nueva y se declara. Sin
outbox —es la fase 17— y sin caché.

**La trampa**

Vas a implementar la vuelta atrás, la vas a probar con el sistema en reposo, y va a funcionar en un
segundo.

Después la vas a probar **con tráfico en vuelo**, y vas a descubrir el problema real: hay operaciones que
el camino nuevo ya empezó y que escribieron algo que **el esquema viejo no puede representar**. Si tu
API generó un identificador con un formato nuevo, si registró una fecha con precisión que `char(8)` no
tiene, si aceptó un campo que la tabla no tiene columna para guardar — esa operación **no se puede
deshacer hacia atrás**, y la vuelta atrás deja un hueco.

No es un caso raro: es el problema central de toda migración incremental, y tiene un nombre —*la vuelta
atrás asimétrica*—. Cuando lo encuentres, la pregunta no es cómo arreglarlo: es **qué restricción tenías
que haberte impuesto desde el principio** para que no pasara. Escríbela en una línea, y compárala con la
que el curso impone sin decirlo en el código de la sección 5.2.

<details><summary>Pista 1 — el enfoque</summary>

Tres piezas, y la tercera es la que suele faltar: la **bandera** (decide), el **servicio de doble
escritura** (ejecuta y compara), y el **procedimiento de operación** — los comandos que una persona
ejecuta a las tres de la tarde de un martes, con su salida legible. Ese tercero no es código de
producción y es el que Clara va a evaluar.

Para la trampa: piensa en qué escribe el camino nuevo que el viejo no podría leer. La restricción que
buscas empieza con "durante la ventana de convivencia, el camino nuevo no puede…".

</details>

<details><summary>Pista 2 — la herramienta</summary>

Para la bandera con recarga en caliente, `IOptionsMonitor<T>` con un proveedor de configuración propio
sobre la tabla:
`https://learn.microsoft.com/aspnet/core/fundamentals/configuration/#custom-configuration-provider`

Para el hash estable del porcentaje, `System.IO.Hashing.XxHash32` — no `string.GetHashCode()`, que **no
es estable entre procesos** y haría que dos instancias de la API decidieran distinto para la misma clave.
Ese detalle es una fuente de divergencia real.

Y para el consumo desde el formulario de 4.8, `HttpClient` con `IHttpClientFactory` no está disponible
allí: mira qué implica y por qué un `HttpClient` estático es la respuesta correcta **en ese lado**.

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```csharp
// La bandera, y su estado seguro por omisión.
public sealed record CutoverOptions(bool Enabled, int Percentage)
{
    public static CutoverOptions Safe => new(Enabled: false, Percentage: 0);
}

// El servicio de doble escritura: el viejo manda, el nuevo verifica.
public interface IInventoryWriter
{
    Task<MovementResult> RegisterAsync(MovementRequest request, CancellationToken token);
}

// El procedimiento de operación, que es lo que Clara evalúa.
internal static class CutoverCommands
{
    public static Task<int> Status(CancellationToken token);
    public static Task<int> SetPercentage(int percentage, string who, CancellationToken token);
    public static Task<int> Rollback(string reason, string who, CancellationToken token);
    public static Task<int> Reconcile(DateOnly since, CancellationToken token);
}

// Y el informe que responde la tercera pregunta de Clara.
public sealed record RollbackReport(
    DateTimeOffset DecidedAt,
    DateTimeOffset LastInFlightCompletedAt,
    int OperationsInFlight,
    ReconciliationReport AfterRollback);
```

</details>

**Cómo se entrega**

```powershell
dotnet test src\Cordillera.slnx -c Release
dotnet test src\modern\Sige.Characterization.Tests -c Release
dotnet run --project src\modern\Cordillera.Ops -- cutover --percentage 50
# … con tráfico en vuelo …
dotnet run --project src\modern\Cordillera.Ops -- cutover --rollback --reason "ensayo" --who "tu nombre"
dotnet run --project src\modern\Cordillera.Ops -- reconcile --since "2026-04-15"
```

```bash
git tag -a mini-10 -m "Mini F10: API en medio con doble escritura y vuelta atrás ejecutada · rollback en <X> s con <N> operaciones en vuelo · <M> divergencias en 1.400 operaciones"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Implementa la bandera de corte con `IOptionsMonitor` y demuestra con una prueba que el valor cambia
   sin reiniciar el proceso.
2. Escribe la prueba que verifica que una configuración corrupta deja el sistema en el camino viejo.
3. Reemplaza el hash estable por `Random` y demuestra con una prueba que la misma clave puede ir por
   caminos distintos en dos llamadas. Después restaura el hash.
4. Escribe la consulta de conciliación de la invariante 3 —la suma por almacén en los dos caminos— y
   ejecútala contra la base del generador.
5. Cambia el formulario de existencias para que llame a la API en vez de a la base, tocando **una sola
   línea** de ese archivo. Anota cuál.
6. Ejecuta la vuelta atrás con el sistema en reposo y cronométrala. Anota el número: es la mitad fácil
   del criterio 4.

**🟡 Intermedio (7–14)**

7. Implementa el porcentaje de tráfico y verifica con 1.000 claves que la distribución real se acerca a
   la configurada. Reporta la desviación.
8. Registra una divergencia a propósito —haz que el camino nuevo filtre `BORRADO` donde el viejo no— y
   clasifícala en las cuatro categorías de la tabla B.
9. Inyecta 40 ms de latencia y repite la medición de latencia del camino nuevo. Explica por qué la
   diferencia **relativa** con el acceso directo baja.
10. Escribe la invariante 1 —saldo consistente— y ejecútala. Debería fallar en 47 casos: explica por qué
    eso es una buena señal y no un error de tu código.
11. Haz que el camino nuevo falle después de que el viejo escribió, y demuestra con la conciliación que
    el hueco se detecta. Ese es el número que dimensiona el outbox.
12. Convierte una de las fotos de la fase 08 en una verificación por invariantes y compara qué detecta
    cada una. Es el cobro de la deuda, en pequeño.
13. Implementa el envoltorio de Convivir con una petición SOAP a mano y prueba el caso del 500 que
    significa "no encontrada".
14. Usa `IHttpClientFactory` en la API y un `HttpClient` estático en el formulario de 4.8. Explica por
    qué la respuesta correcta es distinta en cada lado.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Después de subir el corte al 50%, el almacén reporta que "a veces el movimiento
    aparece dos veces". Enumera tres causas posibles, di cuál es más probable con esta implementación, y
    escribe la prueba que la confirma.
16. **Diagnóstico.** La conciliación reporta 300 divergencias de un día para otro sin que nadie haya
    desplegado. Encuentra las dos causas más probables *(una tiene que ver con dos instancias de la API
    y el hash; la otra con la bandera leída a destiempo)*.
17. **Medición.** Ejecuta la medición completa, las dos tablas, con y sin latencia inyectada, y determina
    **los dos umbrales**. Publica el veredicto incluyendo que el camino nuevo es más lento.
18. **Medición.** Mide el costo de la propia bandera: cuánto añade consultar el interruptor por
    operación, con recarga cada 15 segundos y con recarga por petición. El segundo número es el
    argumento de por qué no se consulta cada vez.
19. Compara generar el cliente de Convivir desde el WSDL contra escribir las dos peticiones a mano.
    Reporta el tiempo que te llevó cada una y qué pasa cuando el WSDL cambia.
20. **Decisión — ¿se migra, se envuelve o se deja quieto?** Aplica el criterio de Clara —de menor a mayor
    costo de un fallo no absorbible— a los cuatro módulos y **defiende un orden distinto al del curso**
    si los datos de tu implementación lo sostienen.
21. **Decisión — ¿se migra, se envuelve o se deja quieto?** Convivir tiene un módulo de reportes que
    duplica el 40% de lo que hace el catálogo de SIGE. Decide qué se hace con esa duplicación, y qué
    cuesta cada camino cuando la Universitaria del Bajío pida un reporte nuevo.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Haz que la vuelta atrás deje el sistema inconsistente, aprovechando la asimetría del
    esquema. Documenta la secuencia exacta y después escribe la restricción que lo impide.
23. **Adversarial.** Consigue que la doble escritura duplique un movimiento en el sistema oficial —el
    viejo— sin que el registro de divergencias lo note. *(Pista: mira qué pasa con un reintento del
    formulario cuando la API tarda más que su tiempo límite.)*
24. **Diseño.** Escribe el plan de corte completo de los cuatro módulos, con sus doce semanas, sus
    banderas, sus criterios de avance y sus vueltas atrás — el documento que Clara firmaría. Incluye qué
    pasa si el proyecto se cancela en la semana 6.
25. **Defiende una decisión.** Clara pregunta por qué el sistema quedó **más lento** después de tu
    trabajo, y tiene la medición de la tabla A delante. Respóndele en media página, en su lenguaje, sin
    usar la palabra "moderno" ni una sola vez.

**🔥 Opcionales**

- Investiga las banderas de funcionalidad gestionadas —Azure App Configuration con Feature Management— y
  compáralas con la tabla de esta fase. Anota el costo y el amarre: la fase 20 lo va a necesitar.
- Escribe la doble escritura al revés —el nuevo manda y el viejo verifica— y anota qué garantías
  pierdes. Es la semana 8 del plan, y verla implementada explica por qué es una decisión aparte.
- Implementa la conciliación como un proceso continuo en vez de un comando, y guárdalo: es la mitad de
  lo que la fase 17 va a construir.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://learn.microsoft.com/azure/architecture/patterns/strangler-fig` — el patrón, descrito por
  Microsoft con sus condiciones y sus contraindicaciones.
- `https://learn.microsoft.com/aspnet/core/fundamentals/configuration/` — configuración y proveedores
  propios, con `IOptionsMonitor` y la recarga en caliente.
- `https://learn.microsoft.com/dotnet/core/extensions/httpclient-factory` — `IHttpClientFactory`, y por
  qué un `HttpClient` por llamada agota los sockets.
- `https://learn.microsoft.com/dotnet/api/system.io.hashing.xxhash32` — hash estable entre procesos, que
  es lo que `string.GetHashCode()` **no** garantiza.
- `https://learn.microsoft.com/azure/architecture/patterns/transactional-outbox` — el outbox, que es la
  deuda de esta fase y el contenido de la 17.
- `https://learn.microsoft.com/dotnet/framework/wcf/` — cliente SOAP en .NET Framework, para el lado de
  Convivir. Y la advertencia: **WCF no está en .NET moderno**; su sucesor parcial es CoreWCF, y eso
  importa para la fase 11.

**Libros / artículos**

- El artículo original de Martin Fowler sobre *StranglerFigApplication* en `martinfowler.com` es corto y
  sigue siendo la mejor descripción del patrón. Verifica la URL: el sitio ha reorganizado enlaces.
- *Monolith to Microservices*, de Sam Newman — los capítulos sobre patrones de descomposición y doble
  escritura cubren exactamente esta fase, y con más casos. Verifica edición antes de citarlo.
- *Refactoring Databases*, de Ambler y Sadalage — la parte de cambios de esquema compatibles hacia atrás
  es lo que hace posible la vuelta atrás simétrica.

> ⚠️ Verifica las URLs. Y la advertencia propia de esta fase: **mucho material sobre *strangler fig*
> asume que ya tienes malla de servicios, entrega continua y observabilidad**, y describe el patrón como
> una configuración de infraestructura. Aquí no hay nada de eso todavía —la observabilidad es la fase 19
> y el contenedor la 20— y el patrón funciona igual con una tabla y un `IOptionsMonitor`. Que la versión
> sofisticada exista no significa que sea el punto de partida.

**Orden de lectura sugerido:** antes de escribir, el artículo de Fowler y la página del patrón de
Microsoft —media hora entre los dos—. Durante el miniproyecto, la de configuración y la de
`IHttpClientFactory`. Al cerrar, la del outbox: se lee mucho mejor cuando ya tienes el número de
divergencias por día delante, y es la preparación de la fase 17.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Hay una API en medio, hay dos caminos vivos, hay un interruptor que alguien puede mover en un minuto, y
**hay una vuelta atrás que se ejecutó de verdad** con su número: desde la decisión hasta que la última
operación en vuelo terminó. Hay un informe de divergencias que separó las reglas no documentadas de los
bugs propios, y hay un orden de cortes con un criterio de riesgo que firmó la presidenta.

Y hay una respuesta a la tercera opción de la pregunta del curso, que es la que más cuesta dar: **Convivir
se deja quieto**, envuelto tras un adaptador delgado, tratado como la dependencia externa que es. No
porque no se pueda migrar: porque funciona, nadie del equipo lo escribió, y el presupuesto tiene mejores
destinos.

La fase 11 es el paso natural y el orden es la mitad del argumento: **ahora que el cliente ya no escribe
directo a la base, mover el runtime es posible**. Al revés no lo era — cambiar de .NET Framework a .NET
10 con noventa instalaciones escribiendo en todo habría sido cambiar de casa sin haber empacado. La 11
convierte el `.csproj` al formato SDK, pasa `packages.config` a `PackageReference`, lleva los ASMX de
2019 a minimal APIs, y hace lo que ninguna herramienta hace: **decide el orden por riesgo y no por
versión**, y publica la lista honesta de lo que no se pudo migrar.

> **La señal de que quedó bien:** *"Puedo decirle a Clara quién aprieta el botón, cuánto tarda y cómo
> sabemos que funcionó — y lo probé un martes, no el día del corte."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el miniproyecto
> corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-10 -m "F10 cerrada:
> - API de existencias en medio, con el formulario consumiéndola
> - bandera de corte con recarga en caliente y estado seguro por omisión
> - doble escritura con el camino viejo como fuente de verdad, y registro de divergencias
> - vuelta atrás EJECUTADA con tráfico en vuelo, con su tiempo y su conciliación posterior
> - conciliación por invariantes: deuda del golden master de la F08 cobrada
> - Convivir envuelto sin tocarlo: la tercera respuesta del curso, implementada"
> ```
>
> **Esta fase cobra la deuda de las pruebas de la fase 08**, y la factura es de un tipo que no se había
> visto:
>
> ```bash
> git diff fase-08 fase-10 -- src/modern/Sige.Characterization.Tests/
> ```
>
> Lo que muestra no es código borrado: es **código agregado al lado**. Las fotos siguen ahí y siguen
> sirviendo para lo que sirven; lo que se agregó es la conciliación por invariantes para lo que las fotos
> no alcanzaban. Cobrar una deuda no siempre es borrar: a veces es dejar de usar una herramienta fuera
> de su alcance.
>
> Y una nota propia de esta fase: **el tag `fase-10` es el punto de no retorno del Bloque B.** A partir
> de aquí el formulario habla con la API, así que `git diff fase-07 fase-10 -- src/legacy/Sige.Forms/`
> muestra el único cambio que este curso le hizo al cliente heredado — una línea— y ese diff de una
> línea es el resumen de toda la fase.

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura.*

- **`INSTINTOS.md`** — dos entradas para la sección de **arquitectura**, que ya las tiene esbozadas
  desde la fase 00 y ahora tienen fase donde apuntar: *"reescribámoslo todo"* y *"no toquemos nada,
  envolvámoslo"*. Hay que actualizar las dos con lo que esta fase aporta: el plan de doce semanas
  reversible como alternativa concreta al *big bang*, y **Convivir como el caso donde "se deja quieto"
  es la respuesta correcta** — sin ese ejemplo, la segunda entrada se lee como que envolver siempre está
  mal, y no es así.
- **`BENCHMARKS.md`** — entrada ⏳ *F10 · Latencia por camino y divergencia medida*, con dos tablas. El
  número de divergencias por día **lo necesita la F17** para dimensionar el outbox, así que conviene
  marcarlo en el índice como dato transversal.
- **Deuda 💸 cobrada:** el *golden master* atado a la semilla (F08 → F10), y la factura es **código
  agregado y no borrado**. Conviene anotarlo en el libro de §7.1 porque es el segundo tipo de cobro
  atípico del curso, después del diff vacío de la F09.
- **Deuda 💸 plantada:** la doble escritura sin conciliación automática, cobro en F17, **con su número**:
  la categoría "fallo del camino nuevo sin escritura" de la tabla B es lo que dimensiona el outbox. Ya
  está en el libro; conviene anotar que la deuda trae su propia unidad de medida.
- **Tipos nuevos para el congelamiento:** `CutoverSwitch`, `CutoverOptions`, `CutoverPath`,
  `DualWriteInventoryService`, `LegacyInventoryGateway`, `IDivergenceLog`, `ReconciliationReport`,
  `Invariant`, `RollbackReport`, `ConvivirGateway`, `InstitutionalSubscription`, y el proyecto
  **`Cordillera.Ops`** — que es nuevo y no estaba en la estructura de `src/`: es la herramienta de
  operación, y hay que agregarla al árbol del congelamiento.
- **Para la fase 11:** esta fase deja el formulario llamando a la API y el runtime todavía en 4.8. Ese es
  exactamente el punto de partida que la 11 necesita, y conviene que lo diga: el orden no es casual.
- **Para la fase 17:** el outbox tiene su número de entrada y el ejercicio 🔥 de conciliación continua
  tiene media implementación. Y la doble escritura invertida —el ejercicio 🔥 del medio— es la semana 8
  del plan, que la 17 puede retomar.
- **Para la fase 19:** la conciliación produce el primer dato operativo del curso que alguien querría ver
  en un tablero. La 19 debería citarlo como caso.
- **Para la fase 24:** el ejercicio 24 —el plan completo de doce semanas, con qué pasa si se cancela en
  la semana 6— es material directo del veredicto final.
- **Riesgo detectado y resuelto:** la fase usa `XxHash32` de `System.IO.Hashing`, que es un paquete de
  NuGet y no estaba fijado. Quedó en `Directory.Packages.props` y en `alcance-del-proyecto.md` §9 como
  **10.0.12**, verificado contra su ficha. De paso se fijaron EF Core, Dapper, Testcontainers y
  NSubstitute, que las fases 08 y 09 usan y que tampoco estaban declarados centralmente.
