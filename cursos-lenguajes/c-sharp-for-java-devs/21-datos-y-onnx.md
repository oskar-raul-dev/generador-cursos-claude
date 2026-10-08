# 📊 Fase 21 — Los datos que mienten, y ONNX

> C# para desarrolladores Java senior · Fase 21 de 24 · Bloque E — datos e IA aplicada
> Depende de: 20 · Habilita: 22
> Estilo de esta fase: **nuevo** (.NET 10, C# 14)
> Proyecto que avanza: **NightPress**, que aprende a servir una predicción además de liquidar.

---

## 🎯 1. Propósito

En 2024 Cordillera **destruyó 41.000 ejemplares**. Es un número que en la junta se menciona en voz baja, y es
el costo de equivocarse por exceso. Equivocarse por defecto cuesta distinto y no aparece en ninguna factura:
quedarse sin stock en las seis semanas que deciden la vida comercial de un libro.

Quien decide el tiraje es **Gustavo Lemos**, director comercial, treinta y un años en el negocio. Mira el
título, la portada y el mes, y acierta con una frecuencia que incomoda. No ha escrito su criterio en ninguna
parte.

Esta fase hace dos cosas, y la primera es más importante que la segunda. La primera: **separar honestamente
sell-in, sell-out y devolución**, que suena a trabajo de contabilidad y es la condición para que cualquier
número posterior signifique algo. La segunda: servir una predicción de tiraje dentro del sistema, y medirla
contra Gustavo y contra un baseline tonto, **aceptando el resultado que salga**.

> 🧭 **La regla de la fase, y es la que ordena el bloque E entero:** *un modelo no puede ser mejor que sus
> datos, y los datos de Cordillera mienten durante noventa días.* Las devoluciones llegan a rozar el 30% y
> aparecen meses después: **el número de marzo cambia en julio**. Un modelo entrenado sobre la foto de marzo
> aprende una mentira estacional y la va a repetir con una confianza que no tiene derecho a tener.

Y hay un veredicto que esta fase **no descubre, sostiene**: ML.NET existe, se presenta, y para este trabajo lo
honesto es **entrenar en Python y servir desde .NET con ONNX Runtime**. Decirlo de entrada no es rendirse: es
que la fase mide para respaldar una decisión, no para simular un suspenso que el autor ya resolvió.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Los tres conceptos de venta —**sell-in, sell-out y devolución**— están separados de verdad, por país,
      sello y canal, y hay una prueba que lo demuestra sobre datos con los tres mezclados.
- [ ] Los **tres calendarios** de los distribuidores y las **semanas ISO** de las dos plataformas quedan
      conciliados contra el mes natural de la contabilidad, con la política de asignación escrita.
- [ ] Toda cifra de venta tiene una **fecha de corte** (`AsOfDate`) adherida: no existe "las ventas de marzo",
      existe "las ventas de marzo **vistas el 30 de abril**".
- [ ] Está medida y publicada la **curva de devolución**: cuánto cambia el número de un mes a los 30, 60, 90 y
      180 días.
- [ ] **ML.NET está presentado y evaluado**, no ridiculizado: se entrena un modelo con él y se mide.
- [ ] El modelo entrenado en Python **se sirve desde .NET con ONNX Runtime**, dentro de NightPress, y la
      predicción es reproducible.
- [ ] La predicción se compara contra **Gustavo** y contra el baseline tonto —*lo mismo que el título anterior
      del mismo autor*—, y **el resultado se publica aunque pierda**.
- [ ] Está escrito qué pasa con un **autor debutante sin histórico**, que es el caso donde el modelo no tiene
      nada que decir.
- [ ] 💸 El modelo se sirve **sin versionar**, declarado, y **no se paga en este curso**, con la razón escrita.
- [ ] La predicción tiene su **costo mensual** al lado, como todo desde la fase 20.
- [ ] La medición de la sección 6 está escrita con su comando, y la entrada quedó en `BENCHMARKS.md`.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Teoría de aprendizaje automático.** Declarado fuera, y es un tema con bibliografía propia. Aquí entra la
  canalización de datos, el servicio de la predicción y **la evaluación honesta** — que es lo que le toca a
  quien escribe el sistema.
- **Elegir la arquitectura del modelo, afinar hiperparámetros o interpretar residuos.** Mismo motivo. Si el
  modelo es un gradiente potenciado o una regresión con regularización **no cambia ni una línea** de lo que
  esta fase construye, y eso es exactamente la lección.
- **Un registro de modelos.** Es la deuda declarada, y es otro curso.
- **Reentrenamiento automático.** Fuera con su razón: reentrenar sin evaluación es la forma más rápida de que
  un modelo se degrade sin que nadie lo note, y la evaluación es lo que la fase 22 construye como aparato.
- **Recuperación, agentes y modelos de lenguaje** → fase 22.
- **Corregir el histórico.** Los datos de 1997 a 2016 tienen los problemas de la fase 07 y esta fase **decide
  hasta dónde llega hacia atrás**, en vez de arreglarlos.

---

## 🧠 4. Concepto mínimo

### Los tres números que todo el mundo llama "ventas"

Esto es el 70% del valor de la fase y no tiene nada de aprendizaje automático.

**Sell-in** es lo que Cordillera le facturó al distribuidor. Entra cuando se emite la factura, y es el número
que la contabilidad reconoce.

**Sell-out** es lo que el distribuidor le vendió al lector. Llega en un archivo, con retraso, en el calendario
del distribuidor, y **es el único de los tres que se parece a la demanda real**.

**Devolución** es lo que el lector no compró y el distribuidor devuelve. En este negocio es habitual y
contractual —el libro va en consignación—, llega a rozar el 30%, y **aparece meses después del sell-in que
contradice**.

De ahí sale la propiedad que hace difícil todo lo demás: **el sell-in de marzo es una cifra provisional hasta
mitad de año**. Y lo que se hace con eso no es esperar: es **fechar la cifra**.

> 🧠 **El modelo mental de la fase, y es lo único que hay que retener:** en este dominio un número no es un
> número, es **un número y la fecha en que se miró**. *"Marzo vendió 4.200"* es una frase incompleta y produce
> discusiones que no se pueden resolver; *"marzo vendió 4.200 según lo que se sabía el 30 de abril, y 3.100
> según lo que se sabía el 31 de julio"* son dos hechos compatibles y los dos son ciertos. Un tipo que cargue
> la fecha de corte adentro convierte esa disciplina en algo que el compilador recuerda por ti.

### Los tres calendarios, y por qué esto no es un detalle

Tres distribuidores y dos plataformas digitales reportan así:

| Quién | Periodo que reporta | Cuándo llega | El problema |
|---|---|---|---|
| Distribuidor A (Colombia) | mes natural | día 10 del mes siguiente | ninguno, y es el único |
| Distribuidor B (México) | del 26 al 25 | día 5, a veces el 12 | **un mes suyo cae en dos meses contables** |
| Distribuidor C (Perú) | quincenas | irregular | dos archivos por mes, y a veces uno se repite |
| Plataforma digital 1 | **semana ISO** | lunes | una semana ISO cruza el fin de mes ocho veces al año |
| Plataforma digital 2 | semana ISO, pero empieza en domingo | martes | **no es la misma semana que la anterior** |

La contabilidad cierra por **mes natural**. Así que hay cinco calendarios que hay que llevar a uno, y **cada
forma de hacerlo produce un número distinto y defendible**. Reparto proporcional por días, asignación al mes
donde cae el cierre, asignación al mes donde cae la mayoría de los días: las tres son legítimas.

> 🧭 **La regla que sale de ahí:** cuando hay varias respuestas defendibles, **la decisión es escribirla, no
> encontrar la correcta**. La política de asignación va en un solo sitio, con nombre, y toda cifra dice qué
> política usó. Un sistema donde dos informes usan políticas distintas sin decirlo produce reuniones donde dos
> personas con razón se contradicen — y eso desgasta más que un error.

### Por qué el entrenamiento no va en .NET, dicho sin diplomacia

ML.NET existe, funciona, y **está bien hecho** para lo que resuelve: clasificar, predecir un número, detectar
anomalías, con una API tipada y entrenamiento dentro del proceso. Si el problema es de los que cubre, ahorra
una frontera entera.

Y para el problema de Cordillera no es la elección honesta, por razones que no son de calidad de la
biblioteca:

**Primera: el trabajo de este problema no es el modelo, es entender los datos.** Curva de devolución,
estacionalidad por país, el efecto de un autor con histórico contra uno sin él. Ese trabajo se hace explorando
—gráficas, cortes, hipótesis descartadas— y el ecosistema donde eso se hace con menos fricción no es .NET. No
por el lenguaje: **por las herramientas alrededor**.

**Segunda: quien va a hacerlo no es Duván.** Cordillera contrataría unas semanas a alguien que sabe de esto, y
esa persona trabaja en Python. Obligarla a aprender ML.NET para que el artefacto se quede en un ecosistema es
pagar tiempo de consultoría en aprender una herramienta que no pidió.

**Tercera, y es la que zanja: servir no es entrenar.** Un modelo entrenado se exporta a **ONNX** —un formato
abierto— y ONNX Runtime lo ejecuta desde .NET con latencia de milisegundos, sin Python en producción y sin una
llamada de red. **Lo que .NET hace excelente aquí es servir**, y eso es lo que la fase mide.

> 🧠 **La frontera que conviene tener clara:** un `.onnx` es **un grafo de operaciones con sus pesos**, no
> código. ONNX Runtime lo ejecuta igual que una consulta ejecuta un plan. Eso trae la propiedad buena —el
> artefacto es un archivo y se versiona como un archivo— y la mala: **el modelo no sabe nada del negocio**.
> Espera un vector de entrada en un orden exacto, con las mismas transformaciones que se aplicaron al entrenar,
> y si le pasas el mes como número cuando se entrenó con el mes como una-de-doce, **no falla: responde
> cualquier cosa**. Esa es la trampa de la fase y no tiene nada de exótico: es el mismo problema de un contrato
> sin tipos, en un sitio donde nadie espera un contrato.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**Primera: creer el número del primer mes.**

```text
❌ El razonamiento, y es el instinto correcto en cualquier otro dominio:
   "La consulta está bien, el dato está en la base, el total es 4.200. Marzo vendió 4.200.
    Lo pongo en el informe."
```

**Por qué falla:** porque en este negocio **el dato todavía no terminó de llegar**. El sell-in de marzo está
completo; el sell-out va con retraso y las devoluciones de marzo se van a registrar entre mayo y agosto. La
cifra no está mal calculada: **está temprano**, y no hay nada en la base que lo diga.

Y el daño no es el informe: es el modelo. Si el conjunto de entrenamiento se armó con la foto de cada mes
tomada pronto, **los meses recientes se ven mejores que los antiguos** — no porque vendieran más, sino porque
sus devoluciones no han llegado. El modelo aprende que las ventas están creciendo. No están creciendo.

```text
✅ Lo que hay que escribir en su lugar:
   La fecha de corte adherida al dato, en el tipo, y el conjunto de entrenamiento armado
   con una misma edad de observación para todas las filas: "cada mes, como se veía a los
   180 días". Aburrido, y es la diferencia entre un modelo y un adorno.
```

**Segunda: entrenar donde no se debe, por no salir del ecosistema.**

Es un reflejo con buena intención —una plataforma menos que mantener, un lenguaje menos en el repositorio— y
**es el mismo reflejo que el curso desarmó en la fase 18 con los frameworks de JavaScript, invertido**. Allí la
respuesta fue *no adoptes un ecosistema que no puedes mantener*; aquí es *no rechaces una frontera que ya
existe y es barata*.

**Dónde se rompe el paralelo con lo que traes:** en el mundo de Java el reflejo equivalente —hacer todo en la
JVM— tiene un argumento real, porque hay un ecosistema de datos maduro en la JVM. En .NET ese argumento es más
débil, y la respuesta del propio ecosistema lo admite: **ONNX Runtime es de Microsoft**, y existe precisamente
para que no tengas que entrenar aquí. Cuando la plataforma te da la puerta de salida, insistir en no usarla no
es lealtad: es trabajo extra.

> ⚰️ **Autopsia del anti-patrón: el modelo que predijo el pasado.**
>
> **El caso:** se arma el conjunto de entrenamiento con una consulta que lee `VENTAS_AAAA` tal como está hoy.
> Para 2019 eso incluye todas sus devoluciones —llegaron hace años—; para el trimestre pasado, ninguna. El
> modelo se entrena, se valida contra una partición del mismo conjunto, y **da un error de validación
> excelente**.
>
> **Lo que pasa al usarlo:** predice tirajes demasiado altos de forma sistemática. Aprendió de un histórico
> donde los meses recientes —los que más pesan en la estacionalidad— tenían las ventas infladas por
> devoluciones que no habían llegado.
>
> **El costo:** ⏳ el ejercicio 17 lo calcula con la curva de devolución real, y el número de referencia está
> en la historia: **41.000 ejemplares destruidos en 2024**. Un modelo con este defecto empuja en esa dirección,
> y lo hace con la autoridad de una cifra.
>
> **Y lo peor, que es por qué esto merece una autopsia:** la validación **no lo detecta**. El defecto está en
> los datos, y la partición de validación tiene el mismo defecto que la de entrenamiento. El modelo está
> midiendo bien su capacidad de reproducir un histórico mentiroso.
>
> **La defensa:** armar el conjunto con **edad de observación constante** —cada periodo como se veía a los N
> días— y validar **hacia adelante en el tiempo**, nunca con una partición aleatoria. Y una prueba que falle si
> alguien arma el conjunto sin fecha de corte, porque esto se vuelve a colar en el primer apuro.

### 🩻 Esto sí funciona igual

**El SQL analítico, completo, y es la mayor parte del trabajo.** Funciones de ventana, `SUM() OVER`,
`LAG`/`LEAD` para comparar con el periodo anterior, agregaciones por varias dimensiones, tablas de calendario.
Todo eso vale igual y el curso no lo explica. Si sabes escribir la consulta de cohortes en PostgreSQL, la
escribes en SQL Server con otra sintaxis de fecha y ninguna idea nueva.

El modelado dimensional también se transfiere: hechos, dimensiones, granularidad, y la disciplina de decidir el
grano **antes** de escribir la primera consulta. Y la regla de la fase 06 —primero SQL, después .NET— aplica
aquí con más fuerza que en ningún otro sitio, porque estas consultas tocan treinta tablas anuales.

Y una que ahorra una tarde: **cargar un modelo y ejecutarlo es igual que en Java.** La API de ONNX Runtime para
.NET y la de Java son casi la misma, con el mismo ciclo de vida: se carga una sesión, se reutiliza, se
desecha al final. Si ya serviste un modelo desde una aplicación de Spring, esto no te va a sorprender.

### 📖 Diccionario de traducción

| Java / datos | .NET | Dónde se rompe el paralelo |
|---|---|---|
| Spark / Flink para canalizaciones | **SQL Server + C#**, o `Microsoft.Data.Analysis` | No hay equivalente a Spark en .NET, y **al volumen de Cordillera no hace falta**: la base aguanta |
| pandas para explorar | `Microsoft.Data.Analysis` (`DataFrame`) | Existe y es mucho más pobre. **Es una de las razones de esta fase**, no un detalle |
| DJL / Tribuo | **ML.NET** | Equivalente razonable. Más maduro que DJL para lo tabular |
| ONNX Runtime para Java | **Microsoft.ML.OnnxRuntime** | Casi la misma API y el mismo ciclo de vida. El paralelo más limpio de la fase |
| `java.time` con zonas | `DateTimeOffset` + `TimeZoneInfo` | Ya visto. Aquí importa por las **semanas ISO** |
| `WeekFields.ISO` | `ISOWeek` (`System.Globalization`) | Existe y es exacto. **No lo calcules a mano**: la semana 1 de un año no siempre empieza en enero |
| JDBC + `ResultSet` para cargas grandes | `SqlBulkCopy` | Sin equivalente directo en JDBC estándar, y **es mucho más rápido** que insertar en lote |
| Micrometer para métricas de negocio | `Meter` (F19) | El error de predicción **es una métrica y va al mismo sitio** |
| un servicio de Python detrás de HTTP | **ONNX en proceso** | Sin llamada de red, sin otro despliegue, sin otra cosa que se cae de madrugada |

> ⚠️ **La fila de `ISOWeek` parece trivial y produce un error de un año entero.** La semana ISO 1 de 2027
> empieza el 4 de enero, y **el 1 de enero de 2027 pertenece a la semana 53 de 2026**. Calcular la semana
> dividiendo el día del año entre siete —que es lo que escribe cualquiera con prisa— desplaza registros entre
> años en el cambio de enero, y el desplazamiento es exactamente donde está el pico de ventas de literatura.
> `ISOWeek.GetWeekOfYear` y `ISOWeek.ToDateTime` resuelven las dos direcciones y hay que usarlos.

> 📝 **Nota de ecosistema, y esta es más honesta que cómoda.** ML.NET 5.0.0 se publicó en **noviembre de 2025**
> y es la versión estable al escribir esto: **casi un año sin una versión nueva**. No está abandonado, y su
> ritmo es claramente otro que el del resto del ecosistema. ONNX Runtime, en cambio, va en 1.30.0 de
> **septiembre de 2026**. Esos dos números dicen algo sobre dónde está la inversión, y conviene leerlo antes de
> apostar una canalización de producción a la primera.

---

## 💻 5. Código mínimo con comentarios

### 5.1 El dato que sabe cuándo se miró

```csharp
// src/modern/Cordillera.Ventas/SalesObservation.cs
//
// Este archivo es el concepto entero de la fase. Si sale bien, las trescientas líneas siguientes
// son mecánica; si sale mal, no hay modelo que lo arregle.
namespace Cordillera.Ventas;

/// <summary>
/// Una cifra de venta **con la fecha en que se observó**. No existe "las ventas de marzo": existe
/// "las ventas de marzo vistas el 30 de abril", y son otro número que "las ventas de marzo vistas
/// el 31 de julio". Las dos son ciertas.
/// </summary>
/// <remarks>
/// La fecha de corte va **dentro del tipo y no como parámetro de la consulta** a propósito: un
/// parámetro se olvida y una propiedad requerida no. Es la misma decisión que la F17 tomó con
/// <c>ConvertedMoney</c>, que lleva la tasa adentro — y por la misma razón: lo que el negocio no
/// puede perder no se deja en el aire.
/// </remarks>
public readonly record struct SalesObservation
{
    public required SalesPeriod Period { get; init; }
    public required ImprintCode? Imprint { get; init; }      // anulable: las 1.900 huérfanas de la F03
    public required CountryCode Country { get; init; }
    public required SalesChannel Channel { get; init; }

    /// <summary>Los tres conceptos, separados. **Nunca un solo campo "ventas".**</summary>
    public required SalesFigures Figures { get; init; }

    /// <summary>Cuándo se miró. Requerido: sin esto la cifra no significa nada.</summary>
    public required DateOnly AsOf { get; init; }

    /// <summary>
    /// Cuántos días pasaron entre el cierre del periodo y la observación. **Es la columna que hace
    /// comparable una fila con otra**, y la que el conjunto de entrenamiento tiene que mantener
    /// constante.
    /// </summary>
    public int ObservationAgeDays => AsOf.DayNumber - Period.EndsOn.DayNumber;

    /// <summary>
    /// La venta neta **según lo que se sabía en <see cref="AsOf"/>**. El nombre es largo a
    /// propósito: <c>Net</c> a secas invita a usarla como si fuera definitiva, y no lo es hasta
    /// que la curva de devolución se agota.
    /// </summary>
    public int NetAsObserved => Figures.SellIn - Figures.Returns;
}

/// <summary>
/// La política con que se llevan cinco calendarios a uno. **Hay varias defendibles y por eso esto
/// es un tipo y no un comentario:** toda cifra dice qué política usó, y dos informes no pueden
/// usar políticas distintas sin que se vea.
/// </summary>
public enum CalendarPolicy
{
    /// <summary>Reparto proporcional por días. Lo más fiel y lo más difícil de explicar en junta.</summary>
    ProportionalByDay,

    /// <summary>Al mes donde cae el cierre del periodo del distribuidor. Lo que hace la contabilidad.</summary>
    ByClosingMonth,

    /// <summary>Al mes donde cae la mayoría de los días. El intermedio, y el que nadie pidió.</summary>
    ByMajorityOfDays,
}
```

**Detalles con intención**

- **`AsOf` es requerido y no anulable.** Es la única defensa que funciona: una propiedad `required` obliga a
  que alguien decida, y un parámetro opcional con valor por omisión se convierte en el defecto de la autopsia
  en el primer apuro.
- **`NetAsObserved` tiene ese nombre horrible a propósito.** `Net` invitaría a tratarlo como definitivo.
  Nombrar la provisionalidad es más barato que documentarla.
- **`SalesFigures` ya existía desde la F03** con sus tres campos, y esta fase **no inventa otro tipo para lo
  mismo**. Que el modelo del Bloque A ya separara los tres conceptos es lo que hace posible esta fase; si
  hubiera un solo campo `Sales`, aquí empezaría una reescritura.
- **`CalendarPolicy` es un `enum` y no una cadena** porque la política tiene que aparecer en la firma de las
  consultas: así el compilador obliga a decidir en cada sitio, y un `switch` exhaustivo avisa cuando se agregue
  un distribuidor con un calendario nuevo.

### 5.2 La curva de devolución, que es el dato que nadie tenía

```csharp
// src/modern/Cordillera.Ventas/ReturnCurve.cs
//
// Esta es la medición más útil de la fase y no tiene nada que ver con IA: cuánto cambia el número
// de un mes a medida que pasa el tiempo. Sin esto no se puede decidir a qué edad de observación se
// arma el conjunto de entrenamiento, y tampoco se puede contestar en junta "¿ese número es firme?".
namespace Cordillera.Ventas;

/// <summary>
/// Cómo evoluciona la cifra de un periodo según cuándo se mire. Se calcula **por país y sello**,
/// porque la curva de los textos escolares en México no es la de la literatura en Colombia.
/// </summary>
public sealed record ReturnCurve
{
    public required CountryCode Country { get; init; }
    public required ImprintCode Imprint { get; init; }

    /// <summary>
    /// Proporción del sell-in que ya se devolvió, por edad de observación. Las edades son fijas
    /// —30, 60, 90, 180, 365— para que dos curvas se puedan comparar.
    /// </summary>
    public required IReadOnlyDictionary<int, double> ReturnedRatioByAge { get; init; }

    /// <summary>
    /// La edad a partir de la cual la cifra ya casi no se mueve. **Es el número que decide cómo se
    /// arma el conjunto de entrenamiento**, y en este negocio no es 30 días.
    /// </summary>
    public required int StabilizesAtDays { get; init; }
}
```

```sql
-- src/modern/Cordillera.Ventas/consultas/curva-de-devolucion.sql
--
-- ⚠️ Primero SQL y después .NET, que es la regla del curso desde la F06 y aquí importa más que en
--    cualquier otra fase: esta consulta cruza treinta tablas anuales. Optimizar el C# que la
--    consume antes de mirar el plan es teatro.
--
-- La forma del cálculo es la parte transferible: para cada periodo, la suma de devoluciones
-- REGISTRADAS HASTA una fecha de corte, contra el sell-in de ese periodo. La devolución se
-- reconoce por TIPOVENTA y su fecha propia — que es lo que permite preguntar "¿cuánto se sabía en
-- tal fecha?" sin tener una foto histórica de la tabla.
SELECT
    v.CODPAIS,
    t.CODSELLO,
    v.PERIODO,
    @EdadDias                                            AS EDAD_DIAS,
    SUM(CASE WHEN v.TIPOVENTA = 'I' THEN v.CANTIDAD ELSE 0 END) AS SELLIN,
    SUM(CASE WHEN v.TIPOVENTA = 'D'
              AND v.FECHAMOV <= DATEADD(DAY, @EdadDias, v.FECHACIE)
             THEN v.CANTIDAD ELSE 0 END)                 AS DEVUELTO_A_LA_EDAD
FROM  VENTAS_2026 v                     -- 🧬 el nombre de la tabla lleva el año adentro: F07
JOIN  TITULOS     t ON t.CODTITU = v.CODTITU
WHERE v.BORRADO <> 'S'                  -- 🧬 el borrado lógico de 1988, que EF Core filtra y aquí no
GROUP BY v.CODPAIS, t.CODSELLO, v.PERIODO;
```

**Detalles con intención**

- **La curva se calcula por país y sello, no global.** Una curva global promedia textos escolares con
  literatura y produce un número que no describe a ninguno de los dos — y es el tipo de promedio que parece un
  dato y es un artefacto.
- **Las edades son fijas.** Sin eso, dos curvas no se comparan y la tabla de la sección 6 no significa nada.
- **`StabilizesAtDays` es el entregable real.** Es lo que decide a qué edad se arma el conjunto de
  entrenamiento, y es un número que Cordillera nunca había escrito.
- **El `WHERE BORRADO <> 'S'` está a mano y marcado 🧬** porque esta consulta va por ADO.NET directo: el filtro
  global de EF Core de la fase 09 no aplica aquí, y olvidarlo es una de las tres trampas de esa fase apareciendo
  otra vez en otro sitio.

### 5.3 Servir el modelo, que es lo que .NET hace bien

```csharp
// src/modern/Cordillera.NightPress/Prediccion/OnnxPrintRunModel.cs
//
// Cuarenta líneas, y es todo lo que cuesta servir un modelo entrenado afuera. Esa brevedad es el
// argumento de la fase: la frontera con Python es barata, así que rechazarla para no salir del
// ecosistema no compra nada.
namespace Cordillera.NightPress.Prediccion;

/// <summary>
/// Ejecuta el modelo de tiraje exportado a ONNX. **La sesión se crea una vez y se reutiliza**: es
/// costosa de construir, es segura para uso concurrente, y crear una por predicción es el error
/// de rendimiento clásico con esta biblioteca — el mismo patrón que un <c>HttpClient</c>.
/// </summary>
public sealed class OnnxPrintRunModel : IPrintRunModel, IDisposable
{
    private readonly InferenceSession _session;
    private readonly FeatureEncoder _encoder;
    private readonly ModelFingerprint _fingerprint;

    public OnnxPrintRunModel(string modelPath, FeatureEncoder encoder)
    {
        _session = new InferenceSession(modelPath);
        _encoder = encoder;

        // El hash del archivo del modelo. 💸 No es versionado —esa deuda no se paga en este curso—
        //    pero es lo mínimo para que una predicción guardada diga CON QUÉ se produjo. Sin esto,
        //    un número de hace tres meses es imposible de explicar, y explicar números viejos es
        //    la mitad del trabajo (lo aprendimos en la F17 con la liquidación).
        _fingerprint = ModelFingerprint.OfFile(modelPath);
    }

    public PrintRunPrediction Predict(PrintRunRequest request)
    {
        // ⚠️ Aquí está el riesgo entero de servir un modelo, y no se parece a un bug de C#: el
        //    codificador tiene que aplicar EXACTAMENTE las transformaciones del entrenamiento, en
        //    el mismo orden. Si el mes se entrenó como una-de-doce y aquí va como número,
        //    **el modelo no falla: responde cualquier cosa**, con la misma cara de certeza.
        //
        //    Por eso FeatureEncoder se genera desde el mismo artefacto que el modelo y se verifica
        //    contra un caso de prueba con salida conocida al arrancar (ejercicio 11).
        float[] features = _encoder.Encode(request);

        using var input = OrtValue.CreateTensorValueFromMemory(
            features, [1, _encoder.FeatureCount]);

        using IDisposableReadOnlyCollection<OrtValue> outputs =
            _session.Run(new RunOptions(), new Dictionary<string, OrtValue> { ["features"] = input },
                         _session.OutputNames);

        float raw = outputs[0].GetTensorDataAsSpan<float>()[0];

        // Y aquí una decisión de dominio que el modelo no puede tomar: un tiraje es un entero, hay
        // un mínimo de imprenta, y **la predicción se redondea hacia el múltiplo de la forma de
        // impresión**. Servir el número crudo sería más "fiel" y menos útil.
        return new PrintRunPrediction
        {
            Copies = PrintRunRounding.ToPressForm(raw),
            RawOutput = raw,
            Model = _fingerprint,
            PredictedAt = TimeProvider.System.GetUtcNow(),
            // El intervalo NO lo inventa el servicio: si el modelo no lo produce, va null y quien
            // lo lea sabe que no hay. Rellenar un intervalo a ojo es peor que no tenerlo.
            Interval = null,
        };
    }

    public void Dispose() => _session.Dispose();
}
```

**El patrón a memorizar**

> **La predicción se guarda con la huella del modelo que la produjo.** Sin eso, un tiraje decidido hace tres
> meses es inexplicable: no se sabe con qué modelo salió, así que no se puede reproducir ni auditar. Es
> exactamente la lección de la fase 17 —*un número que no se puede reproducir no se puede defender*— aplicada a
> un artefacto que no es código. Y es la mitad barata del problema; la otra mitad es el versionado, que esta
> fase **declara y no paga**.

> 💸 **Deuda declarada: el modelo se sirve sin versionar, y NO se paga en este curso.**
>
> Hay un archivo `.onnx` en un directorio. No hay registro de qué datos lo entrenaron, ni con qué código, ni
> quién lo aprobó, ni cómo se vuelve al anterior si el nuevo predice peor. Sustituirlo es copiar un archivo.
>
> **Y no se paga**, con la razón escrita: resolverlo bien es **un registro de modelos** —linaje de datos,
> promoción entre entornos, comparación de candidatos, reversión— y eso es otro curso, no un apartado de este.
> Montar la mitad sería peor que declararlo: daría la sensación de estar resuelto.
>
> Lo que **sí** queda: la huella del archivo en cada predicción, de modo que cuando alguien pregunte *"¿este
> número de qué modelo salió?"* la respuesta exista, aunque sea un hash. Es la diferencia entre una deuda
> declarada y un descuido, y la fase 24 la retoma entre las que se quedan sin pagar.

**Prueba de fuego**

```powershell
dotnet run --project src\modern\Cordillera.NightPress -- predict --title 8823 --month 11 --country CO
```

Compara la salida con lo que diría Gustavo para ese título. **Pregúntale**, no lo supongas: la fase depende de
tener su número, y él está dispuesto a darlo aunque no le guste el ejercicio.

Y la mentira que te va a contar la salida si miras el lugar equivocado: **el error de validación del modelo
va a ser bueno**. Casi siempre lo es, y no dice nada sobre si sirve: dice que el modelo reproduce el histórico
con que se entrenó. Si ese histórico tiene el defecto de la autopsia, el error excelente **es la prueba de que
aprendió bien la mentira**.

---

## 📏 6. Medición

**Hipótesis:** tres, y conviene separarlas porque se responden distinto.
**(a) Sobre los datos:** la cifra de un periodo **sigue moviéndose mucho después de 90 días**, así que un
conjunto de entrenamiento armado a 30 días está sistemáticamente inflado.
**(b) Sobre las herramientas:** ML.NET y el modelo servido con ONNX dan **precisión comparable**, y se separan
en latencia y sobre todo en **esfuerzo de construcción** — que es la columna que decide y no es un número de
arnés.
**(c) Sobre el valor:** el modelo **le gana al baseline tonto** y **empata o pierde contra Gustavo en los
títulos con poco histórico**, ganándole en los que tienen serie larga.

**Condiciones:** SDK 10.0.401 · Release · Windows 11 · base del generador con semilla `19970417`, histórico de
**2016 a 2026** · ML.NET 5.0.0 · Microsoft.ML.OnnxRuntime 1.30.0, CPU, sin aceleración · el modelo de ONNX
entrenado fuera del curso y tratado como artefacto dado · validación **hacia adelante en el tiempo**: se
entrena hasta 2024 y se evalúa 2025–2026, nunca con partición aleatoria · conjunto armado con **edad de
observación constante** · 1.000 predicciones, 100 de calentamiento descartadas · arnés propio.

**Competidores:** ML.NET entrenado en proceso · el modelo de Python servido con ONNX · **el baseline tonto**
—lo mismo que el título anterior del mismo autor— · y **Gustavo**, que es el que hay que vencer.

**Los comandos:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 21 --curva-devolucion
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 21 --modelos --holdout 2025-2026
```

**Resultado:** ⏳ pendiente de ejecución en tu máquina.

**A · La curva de devolución** — el dato que decide todo lo demás

| País · sello | 30 días | 60 | 90 | 180 | 365 | Se estabiliza a |
|---|---|---|---|---|---|---|
| Colombia · literatura | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| México · texto escolar | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Perú · texto escolar | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Colombia · ensayo | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |

**B · Las herramientas**

| Opción | Error medio absoluto | Latencia p95 por predicción | Tamaño del artefacto | Esfuerzo de construcción | Costo mensual |
|---|---|---|---|---|---|
| ML.NET 5.0.0, entrenado en proceso | ⏳ | ⏳ | ⏳ | ⏳ *(cualitativo, declarado)* | **0** |
| Python → ONNX, servido en .NET | ⏳ | ⏳ | ⏳ | ⏳ | **0** |
| Un servicio de Python detrás de HTTP | ⏳ | ⏳ | n/a | ⏳ | 💲 ⏳ *(otro despliegue)* |

**C · Contra quien hay que vencer**

| Predictor | Error medio absoluto | Error en títulos con serie larga | **En debutantes sin histórico** | Sesgo (¿se pasa o se queda corto?) | Ejemplares destruidos, simulado |
|---|---|---|---|---|---|
| Baseline tonto | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Modelo (ONNX) | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| **Gustavo** | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |

> ⚖️ **Veredicto** *(expectativa, todavía sin ejecutar — `formato-de-mediciones.md` §2.6)*. Se espera que la
> tabla A muestre **movimiento significativo más allá de los 90 días**, lo que invalida cualquier conjunto
> armado a 30 y es el hallazgo más reutilizable de la fase. Se espera que la tabla B dé **empate en precisión**
> entre ML.NET y ONNX —y publicar ese empate es importante, porque significa que **la elección no es de
> calidad**: es de quién hace el trabajo y con qué herramientas—. Y se espera que la tabla C sea incómoda:
> **el modelo le gana al baseline, le gana a Gustavo en series largas, y le pierde en debutantes**.
>
> **Los cuatro umbrales que tu ejecución tiene que determinar:** (1) **a qué edad de observación se estabiliza
> la cifra**, que decide cómo se arma el conjunto y cuándo un número es firme en junta; (2) **cuánto histórico
> hace falta para que el modelo le gane a Gustavo** — el número que dice *a qué títulos aplicarlo y a cuáles
> no*; (3) **de qué lado se equivoca cada predictor**, porque los dos errores no cuestan igual: pasarse son
> ejemplares destruidos, quedarse corto son seis semanas perdidas; (4) **cuánto habría ahorrado en 2024**,
> simulado sobre el histórico, que es la única cifra que la junta va a mirar.
>
> 📝 Y una advertencia sobre la columna de esfuerzo: **es cualitativa y va declarada como tal**
> (`formato-de-mediciones.md` §2.4 permite columnas que no son números, como la F17 con "reproducible"). Es la
> columna que decide la fase, y fingir que es un número la haría menos honesta, no más.
>
> ⚠️ **Y cómo no usar la tabla C.** Si el modelo le gana a Gustavo en promedio, **eso no es un argumento para
> reemplazarlo**: es un argumento para que los dos números estén sobre la mesa cuando él decide. Gustavo tiene
> información que no está en la base —una gira, una reseña que viene, un profesor que adoptó el texto— y el
> modelo no puede tenerla. El diseño correcto es una segunda opinión, y la sección 7 lo exige.

---

## 🧱 7. Miniproyecto — la canalización que no miente, y la segunda opinión

**El encargo**

De Gustavo, y llega con una cortesía que no oculta nada:

> *"Me dijeron que vas a hacer un programa que decida los tirajes. Adelante, me parece bien que lo intenten.
> Dos cosas antes.*
>
> *La primera: yo no miro el número de ventas de un mes hasta que pasan como cuatro meses, porque antes no
> sirve. Si tu programa mira el número de marzo en abril, va a estar mirando un número que yo no miraría.*
>
> *La segunda: para un autor nuevo, sin libros anteriores, no hay nada que mirar. Yo miro la portada, de quién
> viene la recomendación, y qué más va a salir ese mes. Si tu programa saca un número para eso, quiero saber de
> dónde lo sacó."*

**Por qué duele**

Porque las dos observaciones de Gustavo son **precisamente los dos defectos técnicos de la fase**, dichos en
lenguaje de negocio y sin una palabra de estadística. La primera es la fecha de corte; la segunda es el
arranque en frío del modelo. Treinta y un años de oficio le dieron los dos.

Y duele porque el encargo obliga a construir algo más difícil que un predictor: un predictor **que sepa cuándo
no tiene nada que decir**. Un modelo que responde siempre es fácil; uno que se calla cuando no sabe exige
decidir dónde está ese límite y defenderlo.

**Datos de entrada**

| Qué | Detalle |
|---|---|
| Histórico | 2016–2026 en `VENTAS_AAAA`, con los problemas de la F07 |
| Distribuidores | 3, con mes natural · del 26 al 25 · quincenas |
| Plataformas digitales | 2, las dos en semanas ISO **que no son la misma semana** |
| Contabilidad | cierra por **mes natural** |
| Devoluciones | hasta el **30%**, llegan meses después |
| El número de la junta | **41.000 ejemplares destruidos en 2024** |
| El competidor | Gustavo, 31 años, y el baseline tonto |
| Novedades al mes | 8 títulos, de los cuales 2 o 3 son de autores sin histórico |

**Criterios de aceptación**

1. Los tres conceptos de venta están separados, y hay una prueba que lo demuestra **con datos donde vienen
   mezclados** —que es como vienen.
2. Los cinco calendarios quedan conciliados con una **política declarada** (`CalendarPolicy`), y toda cifra
   dice qué política usó.
3. **Ninguna cifra existe sin fecha de corte.** Una prueba falla si alguien construye una observación sin ella.
4. La **curva de devolución** está calculada y publicada (tabla A), y el conjunto de entrenamiento se arma a la
   edad que la curva indica — **no a 30 días**.
5. La validación es **hacia adelante en el tiempo**. Si hay una partición aleatoria en el código, el criterio
   no se cumple.
6. El modelo se sirve desde NightPress con ONNX Runtime, **la sesión se reutiliza**, y cada predicción guarda
   **la huella del modelo** que la produjo.
7. **El sistema se calla cuando no sabe.** Para un autor sin histórico suficiente, la respuesta es *"no hay
   base para predecir"* con el umbral escrito, **no un número**.
8. La predicción llega a Gustavo como **segunda opinión**: su número y el del modelo lado a lado, con la
   diferencia y de dónde sale la del modelo. No hay un flujo donde el modelo decida solo.
9. Está simulado **cuánto se habría ahorrado en 2024** con el modelo decidiendo, y está dicho honestamente qué
   supone esa simulación.
10. **Medición de cierre:** las tres tablas de la sección 6. Van en el mensaje del tag `mini-21`.

**Restricciones de estilo y alcance**

Código nuevo. **El modelo se trata como un artefacto dado**: no se elige su arquitectura ni se afinan
hiperparámetros — eso está fuera de alcance y declarado. Sin registro de modelos, que es la deuda. Sin
reentrenamiento automático.

Y una restricción que es el punto: **la canalización tiene que producir el mismo número dos veces**. Si
ejecutarla el jueves y el viernes da cifras distintas para el mismo periodo con la misma fecha de corte, está
mal, y da igual lo bueno que sea el modelo.

**La trampa**

Vas a armar el conjunto de entrenamiento con una consulta que lee `VENTAS_AAAA` como está hoy. Es lo natural:
los datos están ahí, la consulta es correcta, el total cuadra.

Y el conjunto va a estar **sesgado en el tiempo**: 2019 tiene todas sus devoluciones y el trimestre pasado
ninguna. Vas a entrenar, vas a validar, y **el error de validación va a ser bueno** — porque la partición de
validación tiene el mismo defecto. El modelo va a predecir tirajes altos de forma sistemática, empujando hacia
los 41.000 ejemplares del 2024, y con la autoridad de una cifra.

Lo que hace esta trampa peor que las demás del curso es que **no hay ningún síntoma**. No hay excepción, no hay
lentitud, no hay una prueba en rojo, y la métrica que debería detectarlo dice que todo está bien. Es prima de
las tres deudas de la fase 20 —lo que no tiene síntoma técnico— en un terreno donde ni la factura lo delata.

Cuando lo encuentres, escribe dos cosas: **cuánto cambia el error del modelo** al rearmar el conjunto con edad
de observación constante, y **qué prueba automática** habría fallado. La segunda es la que vale: la primera es
un número y la segunda es una defensa.

<details><summary>Pista 1 — el enfoque</summary>

Empieza por la curva de devolución, antes de pensar en el modelo. Es una consulta, es aburrida, y te da el
número que decide todo lo demás — incluida la respuesta a la primera observación de Gustavo.

Para los calendarios, no busques la política correcta: elige una, escríbela, y comprueba que la diferencia entre
las tres es menor que el margen de la decisión que se está tomando. Si es mayor, ahí hay un hallazgo más
importante que el modelo.

Y para el criterio 7 —callarse—, el umbral no es una opinión: se mide. Mira el error del modelo por cantidad de
histórico disponible y busca dónde deja de ser mejor que Gustavo. Ese punto es tu umbral.

</details>

<details><summary>Pista 2 — la herramienta</summary>

Para servir un modelo y la reutilización de la sesión:
`https://onnxruntime.ai/docs/get-started/with-csharp.html`

Para ML.NET, presentado en serio antes de descartarlo para este caso:
`https://learn.microsoft.com/dotnet/machine-learning/`

Para las semanas ISO, que es donde está el error silencioso:
`https://learn.microsoft.com/dotnet/api/system.globalization.isoweek`

Para cargar volúmenes grandes sin morir:
`https://learn.microsoft.com/dotnet/api/microsoft.data.sqlclient.sqlbulkcopy`

Y para la exploración, `Microsoft.Data.Analysis` — pruébalo, porque la comparación honesta con pandas es parte
del argumento de la fase y conviene tenerla de primera mano y no de oídas.

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```csharp
// El dato con su fecha, que es el concepto entero.
public readonly record struct SalesObservation { /* … AsOf requerido … */ }

// La política de calendario, explícita en la firma de cada consulta.
public enum CalendarPolicy { ProportionalByDay, ByClosingMonth, ByMajorityOfDays }

// El contrato del predictor, con la posibilidad de no responder.
public interface IPrintRunModel
{
    PrintRunPrediction Predict(PrintRunRequest request);
}

// Y la respuesta que hace posible el criterio 7: puede no haber número.
public sealed record PrintRunAdvice(
    PrintRunPrediction? Model,       // ← null cuando no hay base para predecir
    string? NoBasisReason,
    int? GustavoEstimate);           // ← la segunda opinión, lado a lado
```

</details>

**Cómo se entrega**

```powershell
dotnet test src\Cordillera.slnx -c Release
dotnet run --project src\modern\Cordillera.NightPress -- predict --title 8823 --month 11 --country CO
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 21 --curva-devolucion
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 21 --modelos --holdout 2025-2026
```

```bash
git tag -a mini-21 -m "Mini F21: curva de devolucion estabiliza a <D> dias · error modelo <M> vs Gustavo <G> vs baseline <B> · debutantes: el sistema se calla · ahorro simulado 2024 = <A> ejemplares"
```

---

## 🧪 8. Ejercicios (24)

**🟢 Fácil (1–6)**

1. Escribe la consulta que separa sell-in, sell-out y devolución para un mes, por país y sello. Compárala con
   el total que usa hoy la contabilidad y explica la diferencia.
2. Calcula la semana ISO de los primeros cinco días de enero de 2027 con `ISOWeek` y a mano dividiendo entre
   siete. Anota cuántos registros se habrían desplazado de año.
3. Construye `SalesObservation` y demuestra con una prueba que no se puede crear sin fecha de corte.
4. Calcula la curva de devolución para un país y un sello. Anota a qué edad se estabiliza.
5. Carga un modelo `.onnx` y ejecútalo una vez. Mide cuánto tarda crear la sesión y cuánto ejecutar.
6. Entrena algo mínimo con ML.NET 5.0.0 sobre los mismos datos. El ejercicio no es el resultado: es tener
   opinión propia de primera mano.

**🟡 Intermedio (7–13)**

7. Concilia los cinco calendarios con las tres políticas de `CalendarPolicy` y compara los tres totales de un
   mismo mes. Decide una y escribe por qué.
8. Arma el conjunto de entrenamiento a 30 días y a la edad que dice la curva. Compara el error del modelo en
   las dos versiones. **Es el ejercicio central de la fase.**
9. Cambia la validación aleatoria por validación hacia adelante en el tiempo y compara las métricas. Explica
   cuál de las dos te estaba mintiendo.
10. Reutiliza la sesión de ONNX en vez de crearla por predicción. Mide las dos y explica el patrón (es el mismo
    de `HttpClient`).
11. Escribe la verificación de arranque que comprueba el codificador de características contra un caso de
    prueba con salida conocida. Después rompe el orden de una característica y comprueba que la verificación lo
    detecta.
12. Guarda la huella del modelo con cada predicción y escribe la consulta que contesta *"¿este número de qué
    modelo salió?"*.
13. Mide el error del modelo por cantidad de histórico disponible y determina **el umbral por debajo del cual
    el sistema se calla**.

**🟠 Difícil (14–20)**

14. **Diagnóstico.** El modelo funcionó bien tres meses y desde enero predice de más. No cambió el código ni el
    modelo. Enumera cuatro causas plausibles y el orden en que las verificarías.
15. **Diagnóstico.** Dos informes del mismo mes dan cifras distintas y las dos consultas son correctas. Explica
    cómo pasa y qué se escribe para que no vuelva a pasar.
16. **Medición.** Ejecuta la medición completa de la sección 6, las tres tablas, con validación hacia adelante.
    Determina los cuatro umbrales.
17. **Medición.** Simula cuántos ejemplares se habrían destruido en 2024 con cada predictor, incluido Gustavo.
    Declara qué supone la simulación y dónde puede estar siendo generosa contigo.
18. Diseña la ficha de segunda opinión que Gustavo recibe: su número, el del modelo, la diferencia, y **de dónde
    sale el del modelo** en lenguaje que él acepte. Muéstrasela.
19. **Decisión.** ¿A qué títulos se le aplica el modelo y a cuáles no? Sostén la respuesta con el umbral del
    ejercicio 13, y decide qué se hace con los que quedan fuera.
20. **Decisión — ¿se migra, se envuelve o se deja quieto?** El criterio de Gustavo, que vive en su cabeza y en
    ninguna otra parte. **Y ahora la pregunta tiene la variante de la F20:** si se deja quieto, ¿cuánto cuesta
    —y qué pasa el día que se jubile?

**🔴 Muy difícil (21–24)**

21. **Adversarial.** Consigue un error de validación excelente con un modelo inútil, sin trucar nada: solo
    eligiendo cómo armar el conjunto y cómo partirlo. Después escribe las dos pruebas que lo impiden.
22. **Adversarial.** Haz que el servicio de ONNX devuelva números plausibles y equivocados cambiando **solo** el
    codificador de características, sin tocar el modelo. Explica por qué nada falla y qué lo detecta.
23. **Diseño.** Escribe qué haría falta para pagar la deuda del versionado del modelo: qué se guarda, qué se
    compara, cómo se promueve y cómo se revierte. No lo construyas — **estímalo**, y di si Cordillera debería
    hacerlo o no.
24. **Defiende una decisión ante quien no es ingeniera.** Escríbele a Clara media página: qué predice el
    sistema, **con qué confianza**, en qué casos no opina, y por qué el número de un mes cambia cuatro meses
    después. Sabiendo que ella es abogada y que va a preguntar quién responde si el tiraje sale mal.

**🔥 Opcionales**

- Compara `Microsoft.Data.Analysis` con pandas en la misma exploración. Anota cuánto tardaste en cada uno: es
  el argumento de la fase medido en tu propio tiempo.
- Mide el modelo con aceleración por GPU y sin ella. Al volumen de Cordillera probablemente no cambia nada, y
  saberlo evita una compra.
- Investiga cuánto costaría servir el modelo como un servicio de Python detrás de HTTP —despliegue,
  monitoreo, factura— y compáralo con cero. Es la fila de la tabla B que casi nadie calcula.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://onnxruntime.ai/docs/get-started/with-csharp.html` — servir un modelo desde .NET, con el ciclo de
  vida de la sesión.
- `https://learn.microsoft.com/dotnet/machine-learning/` — ML.NET. Léelo antes de descartarlo: la fase lo
  descarta **para este caso**, no en general.
- `https://learn.microsoft.com/dotnet/api/system.globalization.isoweek` — semanas ISO exactas.
- `https://learn.microsoft.com/sql/t-sql/functions/window-functions-transact-sql` — funciones de ventana, que
  es donde está la mayor parte del trabajo de la fase.
- `https://learn.microsoft.com/dotnet/api/microsoft.data.sqlclient.sqlbulkcopy` — cargas grandes.
- `https://learn.microsoft.com/dotnet/machine-learning/how-to-guides/serve-model-web-api-ml-net` — la
  alternativa que la fase no elige, documentada por quien la hizo.
- `https://onnx.ai/onnx/intro/` — qué es un `.onnx` y qué no es.

**Libros / artículos**

- *Designing Data-Intensive Applications* (Martin Kleppmann) — el capítulo de procesamiento por lotes y la
  distinción entre datos derivados y datos de origen es exactamente el marco de esta fase. **Verifica la
  edición antes de citarlo.**
- La literatura de *fugas temporales* en conjuntos de entrenamiento (*temporal leakage*) es la que describe la
  autopsia de la sección 4. No se cita un artículo concreto: busca y verifica antes de citar.

> ⚠️ Verifica las URLs. Y la advertencia propia de esta fase, que es distinta de las demás: **casi todo el
> material de aprendizaje automático asume que los datos son correctos y estáticos**. Los tutoriales usan
> conjuntos limpios donde una fila nunca cambia después de escribirse, y en Cordillera **una fila de ventas
> cambia de significado durante seis meses**. Eso no lo cubre ningún tutorial de ML.NET ni de ONNX, y es el 70%
> del trabajo. Y del otro lado: el material de ML.NET anterior a 2024 presenta capacidades que después se
> movieron o se dejaron de recomendar — mira la fecha antes de seguir un tutorial paso a paso.

**Orden de lectura sugerido:** antes de escribir, la introducción a ONNX —diez minutos y evita tratar un
`.onnx` como si fuera código—. Durante el miniproyecto, la página de `ISOWeek` **antes** de calcular una semana,
y las funciones de ventana mientras escribes la curva. Al cerrar, el capítulo de Kleppmann: se lee muy distinto
cuando ya viste una cifra cambiar cuatro meses después.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Existe una canalización que no miente: los tres conceptos de venta separados, cinco calendarios conciliados con
una política declarada, y **ninguna cifra sin la fecha en que se miró**. Eso es lo que de verdad entregó esta
fase, y es lo que se va a seguir usando dentro de cinco años, cuando el modelo sea otro.

Y quedó publicada la curva de devolución, que Cordillera nunca había escrito. Ahora hay una respuesta a la
pregunta que se hacía en cada junta sin poder resolverse: **¿ese número es firme?** Con la curva, la respuesta
tiene fecha.

El veredicto sobre las herramientas se sostuvo con datos y no con doctrina: **ML.NET existe, funciona y no es
la elección para este trabajo**, no por calidad sino porque el trabajo difícil está en entender los datos y eso
se hace en otro ecosistema — y porque **la frontera para traerlo cuesta cuarenta líneas**. Lo que .NET hace
excelente aquí es servir: sin llamada de red, sin otro despliegue, con latencia de milisegundos y costo cero.
Que la puerta de salida la haya construido Microsoft es la mejor prueba de que usarla no es desleal.

La tabla C es la que conviene no leer mal. Si el modelo le gana a Gustavo en promedio, **eso no es un argumento
para reemplazarlo**: él tiene información que no está en la base —una gira, una reseña que viene, un profesor
que adoptó el texto— y el modelo no puede tenerla. Lo que el sistema aporta es **una segunda opinión y un
sistema que sabe callarse** cuando no tiene base, que es más difícil de construir que uno que siempre responde.

Y queda una deuda que **no se paga en este curso**, dicho de frente: el modelo se sirve sin versionar. Con su
huella en cada predicción, que es lo mínimo para poder explicar un número viejo, y sin registro de modelos,
porque eso es otro curso y montar la mitad sería peor que declararlo.

La fase 22 es el paso natural y sube la apuesta del mismo problema. Ahí los datos no son números sino
**contratos escaneados**, y la pregunta —*¿tenemos los derechos en portugués de este título para Brasil?*— tiene
una propiedad que la predicción de tiraje no tenía: **una respuesta inventada no es una molestia, es una
demanda**. De modo que la cita —documento, versión y cláusula— no es una mejora: es el requisito, y si no hay
cita no hay respuesta. Y el resultado incómodo está admitido de antemano: **la búsqueda de texto completo puede
ganarle al aparato de embeddings**, y si gana, se publica.

> **La señal de que quedó bien:** *"Gustavo miró la ficha, dijo 'esto sí lo entiendo', y en el tercer título
> cambió su número por el del programa. Y en el cuarto no lo cambió, y tenía razón."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el miniproyecto corriendo y
> `git status` limpio:
>
> ```bash
> git tag -a fase-21 -m "F21 cerrada:
> - sell-in, sell-out y devolucion separados de verdad, con prueba
> - cinco calendarios conciliados con politica declarada, y semanas ISO exactas
> - ninguna cifra sin fecha de corte: AsOf requerido en el tipo
> - curva de devolucion publicada: el dato que Cordillera no tenia
> - ML.NET presentado y evaluado; el modelo se entrena en Python y se sirve con ONNX
> - medido contra Gustavo y contra el baseline tonto, y publicado aunque pierda
> - el sistema se calla cuando no tiene base para predecir
> - modelo sin versionar: deuda declarada que NO se paga en este curso"
> ```
>
> **Y el diff que muestra lo que de verdad hizo la fase:**
>
> ```bash
> git diff fase-20 fase-21 -- src/modern/Cordillera.Ventas/
> ```
>
> La mayor parte no es el modelo: es la canalización. Si tu diff está al revés —mucho de ONNX y poco de
> `SalesObservation`— la fase se entendió como una fase de IA, y es una fase de datos.

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura.*

- **`INSTINTOS.md`** — **abre la familia *datos, modelos e IA***, que hasta aquí estaba vacía. Dos entradas:
  creer el número del primer mes —con la forma corta que la hace memorable: *en este dominio un número es un
  número y la fecha en que se miró*— y entrenar donde no se debe por no salir del ecosistema, que es el reflejo
  de la F18 invertido y conviene enlazarlos. La primera necesita el detalle que la vuelve grave: **la
  validación no lo detecta**, porque la partición tiene el mismo defecto.
- **`BENCHMARKS.md`** — entrada ⏳ *F21 · La curva de devolución, y quién predice mejor el tiraje*, con tres
  tablas. **Y una nota de formato**: la tabla C compara un sistema contra **una persona**, que es un competidor
  nuevo en este archivo y perfectamente legítimo —es el statu quo, como el trabajo del Agent en la F17—. Vale
  la pena decir que el veredicto **no** autoriza a reemplazarla.
- **Deuda 💸 declarada y no pagada:** el modelo sin versionar. Ya está en el libro de §7.1 con destino
  **nunca**; conviene enriquecer la razón con lo que la fase agregó: **queda la huella del archivo en cada
  predicción**, que es la mitad barata del problema, y eso es lo que separa una deuda declarada de un descuido.
- **Tipos nuevos para el congelamiento:** `SalesObservation`, `CalendarPolicy`, `ReturnCurve`, `CountryCode`,
  `PrintRunRequest`, `PrintRunPrediction`, `PrintRunAdvice`, `PrintRunRounding`, `IPrintRunModel`,
  `OnnxPrintRunModel`, `FeatureEncoder`, `ModelFingerprint`. Y el proyecto nuevo **`Cordillera.Ventas`**, con su
  directorio `consultas/`.
- **Una decisión de alcance que conviene declarar:** esta fase crea `Cordillera.Ventas` en vez de meter la
  canalización en `Cordillera.Data`. La razón es que `Cordillera.Data` **es el borde 🧬** y la canalización no lo
  es: consume el borde. Mezclarlas haría que el proyecto que traduce generaciones también hiciera analítica, y
  eso confunde dos responsabilidades que el curso mantuvo separadas veinte fases.
- **Versiones verificadas el 13 de septiembre de 2026** y fijadas en `alcance-del-proyecto.md` §9:
  **Microsoft.ML.OnnxRuntime 1.30.0** y **Microsoft.ML 5.0.0**. El contraste de fechas —ONNX Runtime de
  septiembre de 2026, ML.NET de noviembre de 2025— **es material de la fase**, no una curiosidad: dice dónde
  está la inversión del ecosistema.
- **Para la fase 22:** el aparato de evaluación de esa fase puede reusar dos cosas de aquí — la validación hacia
  adelante en el tiempo y la disciplina de *el sistema se calla cuando no sabe*, que allí se convierte en *si no
  hay cita, no hay respuesta*. Conviene que la 22 lo diga en voz alta para que la fusión de sus dos proyectos no
  parezca que empieza de cero.
- **Para la fase 24:** tres insumos — la deuda que no se paga (con su razón), la tabla C como ejemplo de una
  medición que **gana y no autoriza a actuar**, y el ejercicio 20: el criterio de Gustavo es lo más valioso del
  sistema y es lo único que no está en ninguna base.
