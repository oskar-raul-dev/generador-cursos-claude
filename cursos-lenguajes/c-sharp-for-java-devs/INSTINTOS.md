# 🪞 INSTINTOS
## C# para desarrolladores Java senior

La versión consultable de todas las secciones 🪞 del curso: los reflejos que un desarrollador Java
senior trae puestos y que en C# producen código que **compila, funciona y es equivocado**.

Se organiza **por familia y no por número de fase**, porque se consulta buscando un síntoma: te
pasó algo raro, lo buscas aquí, y la entrada te dice dónde está desarrollado.

> 🧭 **Cada entrada explica por qué el instinto existía y dónde era correcto.** Un reflejo que se
> ridiculiza no se desaprende: se esconde. Casi todos los de esta lista son buenos hábitos de Java
> aplicados a un runtime donde la garantía que los sostenía no existe.

Nace con la fase 00 y crece con cada fase. La forma de una entrada es siempre la misma:

````markdown
### El reflejo, en las palabras en que se te ocurre

**El código que produce:** el mínimo que lo muestra.
**Por qué falla en C#:** la garantía que en Java existía y aquí no.
**Qué se escribe en su lugar:** la alternativa, corta.
**Dónde se rompe el paralelo:** la columna que hace útil esta tabla.
**Desarrollado en:** la fase.
````

---

## 🏔️ El reflejo que contiene a todos los demás

*Se escribe aquí y no al final porque los cincuenta y ocho de abajo son casos particulares de este. Lo nombró la
fase 24, cuando ya había datos para nombrarlo.*

### "Si puedo mejorarlo, mejorarlo es lo correcto"

**En qué se traduce:** lo que está viejo hay que arreglarlo; lo que está mal hecho hay que rehacerlo; y si tengo
la capacidad técnica de hacerlo, hacerlo es lo profesional.

**Por qué falla:** porque confunde **poder** con **deber**, y se salta la única pregunta que importa: *¿qué compra
esto, y a cambio de qué?* El módulo de inventario se puede migrar. "El Fox" de Lima se puede reemplazar. Los 690
procedimientos se pueden reescribir. Nada de eso está en duda **y nada de eso es un argumento**.

**Qué se pregunta en su lugar**, y es la pregunta que ordenó el curso entero desde la fase 07:

> **¿Esto se migra, se envuelve o se deja quieto?**
>
> Con la adición que la fase 20 le hizo y que la vuelve completa: **"se deja quieto" exige la cifra al lado**. Con
> cifra es una decisión; sin cifra es una omisión con buena prensa.

**Dónde se rompe el paralelo:** no es un reflejo de Java — es un reflejo de ingeniero, y por eso es el más
difícil de desaprender. Lo que cambia al pasar a un sistema de cuarenta y siete años es que **las tres respuestas
son legítimas**, y en el trabajo del que vienes casi siempre la respuesta era la primera.

**Desarrollado en:** [fase 24](24-veredicto-y-defensa.md), y presente en las veinticuatro anteriores.

---

## 🧰 Familia: el ecosistema y la herramienta

### "El IDE me resuelve el proyecto"

**El código que produce:** ninguno — produce un `.csproj` que nadie leyó, una versión de paquete
que el asistente eligió, y un `bin/` que compila en tu máquina y en ninguna otra.

**Por qué falla en C#:** porque el `.csproj` **es** el build. No lo declara, no lo describe: es un
archivo de MSBuild que se ejecuta, y el IDE solo escribe texto dentro. Todo lo que el curso pide
se puede hacer sin abrir Visual Studio, y en CI no hay Visual Studio.

**Qué se hace en su lugar:** leer las diez líneas del `.csproj` que la plantilla genera y saber qué
hace cada una; fijar el SDK con `global.json`; declarar las versiones una vez con *Central Package
Management*; y versionar el `packages.lock.json` para que la restauración sea reproducible.

**Dónde se rompe el paralelo:** `~/.m2` te daba reproducibilidad casi gratis y el `pom` era
declarativo. Aquí la caché es por máquina y **la reproducibilidad hay que pedirla**.

**Desarrollado en:** [fase 00](00-instalacion-ambiente-visual-studio-y-ecosistema.md).

---

## 🧬 Familia: tipos e igualdad

### "Le escribo los getters y los setters"

**El código que produce:** `GetName()`/`SetName(value)` a mano, treinta líneas por tipo, y un modelo
que no puede decir la diferencia entre un dato que cambia y uno que se fija al construir.

**Por qué falla en C#:** no por ser largo — por **afirmar algo falso**. Un setter público dice "esto
cambia", y en el dominio de Cordillera el nombre de un título cambia y el sello con el que se publicó
no cambia nunca. `init` y `required` dicen la diferencia y el compilador la hace cumplir.

**Qué se escribe en su lugar:** `public required string Name { get; init; }`. Y cuando hace falta
validar al asignar, la palabra clave `field` de C# 14 da acceso al campo de respaldo sin declararlo.

**Dónde se rompe el paralelo:** las propiedades de C# existen desde 2002 y no son una convención de
nombres: son un miembro del lenguaje. No hay equivalente de `init` en Java.

**Desarrollado en:** [fase 01](01-tipos-valor-y-referencia.md).

### "Sobrescribo `equals` y `hashCode`"

**El código que produce:** los dos métodos a pares, generados por el IDE, en cada tipo de valor.

**Por qué falla en C#:** por frágil de una forma que las pruebas no atrapan. El día que alguien
agregue un miembro y no toque los dos métodos, la igualdad queda mal y todo sigue compilando. Un
`record` deriva la igualdad de sus miembros, así que agregar un miembro la actualiza sola.

**Qué se escribe en su lugar:** `record` o `readonly record struct` para los valores. Y para las
entidades, `Equals` por **identidad** escrito a mano una vez — que es lo que el dominio dice: dos
títulos con los mismos datos son dos títulos.

**Dónde se rompe el paralelo:** el `record` de C# **no mira dentro de un arreglo miembro**. Dos
ediciones con exactamente los mismos contribuidores en un `Contributor[]` dejan de ser iguales, y
nadie avisa. El `record` de Java tiene el mismo comportamiento; la diferencia es que en C# el hábito
de usar `record` para todo lo hace aparecer mucho más seguido.

**Desarrollado en:** [fase 01](01-tipos-valor-y-referencia.md).

### "Todo es una referencia" — y es el silencioso

**El código que produce:**

```csharp
StockItem first = movements[0];          // ← COPIA, no referencia al elemento
first = first with { Quantity = 25 };
Console.WriteLine(movements[0].Quantity); // 10. No 25.
```

**Por qué falla en C#:** porque un `struct` se copia por valor al asignarlo, al pasarlo y al leerlo
de una colección. En Java `list.get(0)` devuelve la referencia y mutarla cambia la lista; aquí la
mutas y no cambia nada. **No hay advertencia y no hay excepción**: el programa hace algo distinto de
lo que dice.

**Qué se escribe en su lugar:** si escribes un `struct`, es `readonly`. Así la mutación no compila y
el error se vuelve visible en vez de silencioso. Y si no puede ser `readonly`, probablemente querías
una `class`.

**Dónde se rompe el paralelo:** Java tiene ocho primitivos y ni uno más; en C# puedes escribir tus
propios tipos por valor, así que la pregunta "¿esto se copia o se referencia?" aparece en **tu**
código y no solo en el de la biblioteca.

**Desarrollado en:** [fase 01](01-tipos-valor-y-referencia.md).

---

## 🕳️ Familia: ausencia y nulabilidad

### "`null` significa que no hay"

**El código que produce:** `string? Isbn` y `DateTime? PublishedOn`, donde un `null` quiere decir a
la vez "no tiene", "no se capturó", "el proceso no llegó a calcularlo" y "hubo un error".

**Por qué falla en C#:** no es del lenguaje, es del modelo — pero en C# se paga antes, porque el
compilador te obliga a decidir en cada uso qué hacer con la ausencia y no tienes nada con qué
decidir. En Cordillera 340 ediciones **no tienen** ISBN y es correcto; otras deberían tenerlo y se
perdió; y en once tablas hay `'00000000'`, que es lo que la importación de 2017 escribió donde
FoxPro tenía una fecha vacía. Son tres cosas y tres dueños distintos del arreglo.

**Qué se escribe en su lugar:** **una ausencia sin significado es `null`; una ausencia con
significado es un tipo.** `Title.Subtitle` es `string?`; una fecha del esquema heredado es
`LegacyDate` con su `LegacyDateKind`.

**Dónde se rompe el paralelo:** ninguno — este reflejo falla igual en Java. Lo que cambia es que
aquí el compilador lo saca a la superficie en la primera compilación.

**Desarrollado en:** [fase 02](02-nullable-y-pattern-matching.md).

### "Busco el equivalente de `Optional<T>`"

**El código que produce:** un `Maybe<T>` escrito a mano de ochenta líneas, con su `Map` y su
`FlatMap`, y firmas que lo devuelven en todas las capas.

**Por qué falla en C#:** porque `T?` ya es la respuesta y no cuesta nada. Para un `struct` es
`Nullable<T>` —otro `struct`, sin asignación— y para una clase **no existe en tiempo de ejecución**:
es una anotación para el compilador. Un `Maybe<T>` propio trae todo el peso de `Optional` y ninguno
de sus beneficios, porque el ecosistema entero habla `T?`.

**Qué se escribe en su lugar:** `T?`, y para encadenar, los operadores del lenguaje: `?.`, `??`,
`??=`, más pattern matching.

**Dónde se rompe el paralelo:** `Optional<T>` es **un objeto en el montón** que envuelve otro, con
métodos. `T?` no envuelve nada. Por eso el hábito de encadenar `map` no tiene traducción
idiomática — y buscarla produce código que ningún equipo de .NET escribiría.

**Desarrollado en:** [fase 02](02-nullable-y-pattern-matching.md).

### "Le pongo un `!` y sigo"

**El código que produce:** `var edition = FindEdition(id)!;` y la advertencia desaparece.

**Por qué falla en C#:** porque `!` **no comprueba nada**: le dice al compilador "confía en mí". Si
te equivocas, el `NullReferenceException` llega igual y ahora sin advertencia previa. Y lo peor no es
el fallo: es que el siguiente que lea el código no puede saber si ese `!` está porque alguien
verificó y el análisis de flujo no lo entiende, o porque alguien tenía prisa.

**Qué se escribe en su lugar:** una de las cuatro respuestas legítimas — arreglar el código, arreglar
la firma, **demostrarlo con un atributo de anulabilidad** (`[NotNullWhen]`, `[MemberNotNull]`,
`[NotNullIfNotNull]`), o el `!` **con su comentario** y declarado como deuda 💸. El `!` legítimo
existe: cuando dos miembros están relacionados y el compilador los ve independientes, no hay atributo
que sirva.

**Dónde se rompe el paralelo:** `@SuppressWarnings` en Java se pone en un método o una clase; el `!`
es por expresión. Más quirúrgico, y por eso auditable: `grep -rn '!\.' src/modern/` tiene que caber
en una pantalla.

**Desarrollado en:** [fase 02](02-nullable-y-pattern-matching.md).

---

## 🔁 Familia: ejecución diferida

### "Ya usé este pipeline, ahora lo recorro otra vez" — el más caro del curso

**El código que produce:**

```csharp
IEnumerable<Edition> outOfStock = editions.Where(e => stock.QuantityFor(e.Id) == 0);
int count = outOfStock.Count();                       // recorrido 1: trabajo completo
foreach (Edition e in outOfStock) { … }               // recorrido 2: trabajo completo OTRA VEZ
```

**Por qué falla en C#:** porque funciona. Imprime lo correcto, no lanza nada, y hace el trabajo dos
veces. Si la fuente es una lista, el segundo recorrido es barato; si es un archivo, se lee dos veces;
si es una consulta a SQL Server, **son dos consultas** — y en la F09 esa consulta es un `UNION ALL`
de treinta tablas anuales.

**Qué se escribe en su lugar:** un `IEnumerable` se enumera **una vez**. Si hacen falta dos, se
materializa una vez con `[.. …]` o `ToList()` **y el comentario dice por qué**. Y para que la regla
la sostenga una prueba y no la memoria, un envoltorio que cuente enumeraciones.

**Dónde se rompe el paralelo — y es la entrada más importante de este documento:** en Java esto **no
te puede pasar**. Un `Stream` reusado lanza `IllegalStateException` y te enteras en la primera
prueba. Once años con esa red debajo forman un instinto que aquí es medio verdadero: se usa y se
puede volver a usar, y **nadie avisa**. La defensa no es una regla memorizada: es leer el tipo.
`IEnumerable<T>` en una variable local significa trabajo pendiente.

**Desarrollado en:** [fase 03](03-linq-y-evaluacion-diferida.md).

### "Traduzco el Stream operador por operador"

**El código que produce:** `GroupBy(...).ToDictionary(g => g.Key, g => (long)g.Count())` buscando el
equivalente de `Collectors.groupingBy(..., Collectors.counting())`.

**Por qué falla en C#:** no falla, sobra. Los `Collectors` de Java existen porque un `Stream` no sabe
agrupar por sí mismo y `collect` es el punto de extensión. En C# `GroupBy` devuelve
`IEnumerable<IGrouping<K,T>>`, y un `IGrouping` **es** la secuencia de sus elementos: no hay
recolector que inyectar.

**Qué se escribe en su lugar:** `GroupBy(...).ToDictionary(g => g.Key, g => g.Count())`, y en general
buscar el operador que ya existe antes de construir la maquinaria.

**Dónde se rompe el paralelo:** LINQ es de 2007 y los Streams de 2014, así que no es que uno copie al
otro: son dos diseños distintos del mismo problema. LINQ trajo consigo lambdas, métodos de extensión
y árboles de expresión, y por eso sus operadores son extensiones y **puedes escribir los tuyos** para
que se usen igual que los de la biblioteca.

**Desarrollado en:** [fase 03](03-linq-y-evaluacion-diferida.md).

### "Materializo por si acaso"

**El código que produce:** un `ToList()` en cada frontera de capa, "para estar seguro". Tres listas
intermedias para una consulta de tres pasos.

**Por qué falla en C#:** porque el miedo es legítimo —el doble recorrido— y la cura es
desproporcionada: previene el problema en todas las fronteras a la vez, que es pagar un seguro contra
incendios en cada habitación. Con 26.000 ediciones son tres asignaciones grandes y tres recorridos
donde la versión diferida hace uno.

**Qué se escribe en su lugar:** devolver `IEnumerable<T>` desde las capas que componen y materializar
**una vez**, en el sitio que consume, con el comentario que dice por qué. Y ojo con el reverso: un
`ToList()` que "arregla" el contador de recorridos **mueve el problema a la memoria**, que es
exactamente el planteamiento de la fase 06.

**Dónde se rompe el paralelo:** en Java la materialización defensiva es menos tentadora porque el
`Stream` no se puede guardar y reusar; aquí sí se puede, y de ahí sale el reflejo.

**Desarrollado en:** [fase 03](03-linq-y-evaluacion-diferida.md).

---

## 🎩 Familia: ceremonia, delegados y recursos

### "Me escribo una interfaz para poder pasar la función"

**El código que produce:** `IEditionFilter` con un método, más una clase que lo implementa, más una
instancia — para pasar un predicado.

**Por qué falla en C#:** no por verboso: por **inventar un concepto de dominio que no existe**.
`IEditionFilter` no es una idea del negocio de Cordillera, es un envoltorio para poder pasar una
función en un lenguaje que no lo permitía. Nombrar cosas que no son ideas hace que el siguiente busque
significado donde no hay.

**Qué se escribe en su lugar:** un `Func<Edition, bool>`. Y la interfaz sí va en tres casos, que el
curso usa: cuando hay **más de una implementación real** conviviendo, cuando hay que **sustituirla en
una prueba** y el doble necesita estado, y cuando la abstracción tiene **varios métodos que van
juntos**. Si tuviste que llamarla `IAlgoFilter`, era una función.

**Dónde se rompe el paralelo:** Java necesita un tipo nominal para pasar comportamiento —`Predicate<T>`
o la interfaz funcional que te escribas—. En C# `Func` y `Action` son tipos de la biblioteca y
cualquier lambda con la forma correcta encaja sin declarar nada.

**Desarrollado en:** [fase 04](04-ceremonia-delegados-y-recursos.md).

### "Esto va en una clase `Utils`"

**El código que produce:** `IsbnUtils.Format`, `IsbnUtils.IsValid`, `IsbnUtils.StripHyphens` — y a los
dos años, cuarenta métodos que no tienen nada que ver entre sí.

**Por qué falla en C#:** porque el comportamiento va donde vive el dato, y cuando el tipo no es tuyo,
**sí puedes agregarle un método**. Ahí desaparece el 80% de las razones para tener un `Utils`.

**Qué se escribe en su lugar:** el método en el tipo si es del tipo; un **método de extensión** si
extiende algo ajeno. El espacio de nombres ya agrupa: no hace falta una clase estática para eso.

**Dónde se rompe el paralelo:** en Java la clase de utilidades es la única opción cuando el tipo no es
tuyo — no puedes agregarle un método a `String`. Es una limitación del lenguaje convertida en
convención, y al cruzar la convención sobrevive a la limitación.

**Desarrollado en:** [fase 04](04-ceremonia-delegados-y-recursos.md).

### "Pongo un `catch (Exception)` para que el proceso no se caiga" — la más cara del documento

**El código que produce:**

```csharp
catch (Exception ex)
{
    _log.Warning($"Línea con problema: {ex.Message}");
}
```

**Por qué falla en C#:** porque ese bloque se traga, con la misma cara, **tres cosas distintas**: una
línea con un ISBN mal formado (dato sucio: hay que contarlo y seguir), un disco lleno (fallo del
sistema: hay que abortar) y un `NullReferenceException` propio (bug: hay que arreglarlo). Las tres
quedan como una advertencia que nadie lee, y el proceso termina "bien" con la mitad de las ventas sin
cargar. **Un programa que nunca se cae es indistinguible de uno que nunca funciona.**

**Qué se escribe en su lugar:** se atrapa lo que se sabe manejar y se deja subir lo demás. La política
por tipo de fallo, explícita y en un solo sitio. Y si de verdad hace falta un `catch` ancho, va con un
comentario que diga qué se está tragando y por qué.

**Dónde se rompe el paralelo:** en Java el compilador te obligaba a **nombrar** lo que podía fallar, y
ese trámite te hacía pensar. Sin excepciones declaradas no hay quien te lo pida, así que
`catch (Exception)` es lo que sale solo — y en C# la disciplina que sostenía el compilador la sostienes
tú.

**Desarrollado en:** [fase 04](04-ceremonia-delegados-y-recursos.md).

### "El montaje va en un `@BeforeEach` y limpio los campos"

**El código que produce:** un campo mutable en la clase de prueba y un método de montaje, con la
suposición de que hay que limpiar entre pruebas.

**Por qué falla en C#:** no falla — sobra. xUnit **construye una instancia nueva de la clase por cada
prueba**, siempre, sin configuración que lo cambie. El montaje va en el constructor y el desmontaje en
`Dispose()`. No hay estado que sobreviva, así que no hay nada que limpiar.

**Qué se escribe en su lugar:** constructor + `IDisposable`. Y cuando el montaje es de verdad caro —un
contenedor de SQL Server—, `IClassFixture<T>`: un tipo aparte, inyectado por constructor, de modo que
**si dos pruebas comparten estado se ve en la firma de la clase**.

**Dónde se rompe el paralelo:** JUnit también crea una instancia por prueba, pero convive con
`@BeforeAll` estático y con `@TestInstance(PER_CLASS)`, así que el hábito de mirar los campos
compartidos tiene sentido allá. Aquí no hay esa variante — y, en cambio, hay una que muerde: **xUnit
paraleliza las clases de prueba por omisión**, y ese es el primer fallo intermitente de todo el que
llega.

**Desarrollado en:** [fase 04](04-ceremonia-delegados-y-recursos.md).

---

## ⚙️ Familia: asincronía

### "Le pongo `.Result` y no contamino la firma" — la que cuesta producción

**El código que produce:** `return LoadAsync(path).Result;` — también `.Wait()` y
`.GetAwaiter().GetResult()`.

**Por qué falla en C#:** el hilo que llama se queda **bloqueado** sin hacer nada, y es un hilo del
grupo. Con doscientas peticiones concurrentes hacen falta doscientos hilos bloqueados, y el grupo los
crea de a poco, así que el sistema no explota: **se degrada**. La firma del problema es
**latencia alta con CPU baja**, y es el diagnóstico más difícil de hacer sin haberlo visto antes,
porque todos los indicadores parecen sanos.

**Qué se escribe en su lugar:** `await`. Y si no se puede porque la firma de arriba no es asincrónica,
el problema está **en la firma de arriba**: se arregla hacia arriba hasta el punto de entrada.

**Dónde se rompe el paralelo:** en la JVM bloquear un hilo de plataforma era caro pero **previsible**,
y llevabas años dimensionando pools para eso. El grupo de hilos de .NET está diseñado bajo el supuesto
de que nadie lo bloquea, y su heurística de crecimiento es deliberadamente lenta: bloquearlo no es
ineficiente, es usar la herramienta contra su diseño.

**Desarrollado en:** [fase 05](05-async-await-y-cancelacion.md).

### "`async void` para no cambiar el tipo de retorno"

**El código que produce:** `public async void LoadAll(...)`, que compila sin una advertencia.

**Por qué falla en C#:** tres cosas a la vez. **No se puede esperar** —quien llama sigue como si
hubiera terminado—, **no se pueden atrapar sus excepciones** —el `try`/`catch` de alrededor no ve nada y
en una consola el proceso se cae— y **no se puede probar**, porque no hay forma de saber cuándo acabó.

**Qué se escribe en su lugar:** `Task`, aunque no devuelva valor.

**Dónde se rompe el paralelo, y con su excepción dentro:** `async void` **es correcto en un manejador
de eventos**, porque ahí la firma la impone el lenguaje y quien invoca es el bucle de mensajes, que no
espera a nadie. En este curso eso pasa **una vez**, en la [fase 12](12-winforms-en-net-10.md), con
los formularios de SIGE. Fuera de un manejador de eventos, es un error.

**Desarrollado en:** [fase 05](05-async-await-y-cancelacion.md).

### "Si hay que hacer tres cosas a la vez, tres hilos"

**El código que produce:** `Parallel.ForEach(files, f => LoadAsync(f).Wait());` — dos errores en una
línea.

**Por qué falla en C#:** `Parallel.ForEach` está diseñado para **trabajo de CPU**: reparte el rango
entre los núcleos y los mantiene ocupados. Con trabajo de entrada y salida ocupa un hilo por elemento
para que se quede esperando, y encima obliga a bloquear porque su delegado es sincrónico.

**Qué se escribe en su lugar:** lanzar las tareas y esperarlas juntas con `Task.WhenAll`, y limitar
**cuántas están en vuelo** con un `SemaphoreSlim` — no cuántos hilos hay, que el grupo no es tuyo.

**Dónde se rompe el paralelo:** Java resolvió el mismo problema al revés. Los **hilos virtuales** hacen
que bloquear sea baratísimo, así que el código sigue siendo secuencial; .NET eligió **colorear las
funciones**. Las dos respuestas son legítimas: los virtuales no te piden cambiar el código y esconden
dónde está la espera; `async`/`await` la hace visible en la firma y te obliga a propagarla. La
consecuencia práctica en .NET es que **la asincronía es viral y tiene que ser de punta a punta**, y el
sitio donde la cadena se rompe es donde aparece el `.Result`.

**Desarrollado en:** [fase 05](05-async-await-y-cancelacion.md).

### "Recibo el `CancellationToken` y con eso ya es cancelable"

**El código que produce:** un bucle de seis horas que recibe el token en la firma, lo propaga a todas
las llamadas de dentro… y nunca lo mira.

**Por qué falla en C#:** porque la cancelación es **cooperativa**. Nadie mata nada desde fuera, nadie
lanza una interrupción: el token es una señal y el que trabaja tiene que mirarla. Si el trabajo está en
tu bucle y tu bucle no comprueba, no hay cancelación — y el proceso nocturno que falló en la hora cinco
es exactamente ese bucle.

**Qué se escribe en su lugar:** `token.ThrowIfCancellationRequested()` en el bucle propio, **además**
de propagarlo. Y antes de eso, decidir cuál es la unidad indivisible: cancelar entre dos operaciones
que tenían que ocurrir juntas deja estado a medias, que es peor que no poder cancelar.

**Dónde se rompe el paralelo:** `Thread.interrupt()` levanta una bandera que muchas operaciones de
biblioteca consultan por ti y convierten en `InterruptedException`. Aquí la `OperationCanceledException`
la lanza **tu** código al mirar el token, así que la cobertura depende de ti y no de la biblioteca.

**Desarrollado en:** [fase 05](05-async-await-y-cancelacion.md).

---

## 🧠 Familia: memoria y flujo

> 🩻 **Esta familia empieza distinto a las demás, y conviene decirlo:** casi todo el instinto de
> recolección de basura que traes de la JVM **sirve aquí**. Generaciones, promoción, hipótesis
> generacional, el montón de objetos grandes, que las pausas importan más que el rendimiento total en
> algo interactivo, y que reducir la presión de asignación es lo que las baja. Nada de eso hay que
> desaprenderlo. Los dos reflejos de abajo son los únicos que fallan.

### "Si no cabe, le doy más memoria"

**El código que produce:** `File.ReadAllLines` y una `List<T>` con las 500.000 filas del reporte
histórico dentro.

**Por qué falla en C#:** porque "darle más memoria" funciona hasta que el proceso vive en un contenedor
con un límite, o hasta que dos reportes coinciden. Y porque **el pico no es un problema de eficiencia,
es de previsibilidad**: un proceso cuyo pico depende del tamaño del dato es un proceso que un día no
arranca, y ese día no lo eliges tú — en Cordillera cae el día de la junta.

**Qué se escribe en su lugar:** `IAsyncEnumerable<T>` y `await foreach`: se produce una fila, se
consume, se olvida. El pico deja de depender del archivo. Y ojo con el reverso: **el flujo baja el pico
y no baja el tiempo**; si el problema era la velocidad, esto no ayuda.

**Dónde se rompe el paralelo:** no hay `-Xmx` que ajustar, porque el montón crece según el sistema; en
contenedor se limita **el contenedor**. Y el tipo que expresa el flujo asincrónico no tiene equivalente
directo en Java: lo más cercano son los reactive streams, con mucho más aparato y suscripción explícita.

**Desarrollado en:** [fase 06](06-memoria-span-y-flujo.md).

### "Esto lo arreglo con `Span<T>`"

**El código que produce:** cuarenta líneas con `stackalloc` y vistas, para una operación que se ejecuta
una vez por reporte y cuyo costo real estaba en la consulta SQL.

**Por qué falla en C#:** por lo mismo que falla en Java optimizar sin medir, solo que aquí la
herramienta es más seductora porque es nueva y de verdad funciona. `Span<T>` cambia el número cuando la
operación se ejecuta **cientos de miles de veces**; no lo cambia cuando se ejecuta una.

**Qué se escribe en su lugar:** el orden. Primero el algoritmo, después el flujo, después las
asignaciones, y solo entonces la vista sobre memoria ajena — y si el trabajo toca la base de datos,
antes que todo eso, **el plan de consulta**.

**Dónde se rompe el paralelo, y es la limitación que duele:** un `Span<T>` **no puede cruzar un
`await`** ni vivir en un campo, porque un método `async` guarda en el montón las locales que sobreviven
a la espera y un `Span` apunta a memoria prestada. El trabajo con `Span` vive en un método sincrónico
que el asincrónico llama; `Memory<T>` sí cruza, a cambio de ergonomía. En Java no hay nada que se
prohíba por esta razón porque no hay un tipo que represente una vista sobre la pila.

**Desarrollado en:** [fase 06](06-memoria-span-y-flujo.md).

---

## 🗄️ Familia: datos y esquema

### "Esto está mal hecho" — y la respuesta es "esto está fechado"

**El código que produce:** ninguno. Produce **un documento de tres páginas** proponiendo normalizar el
esquema, renombrar las columnas, agregar llaves foráneas, unificar las treinta tablas de ventas y mover
la lógica de los procedimientos a servicios. Estimado: dieciocho meses.

**Por qué falla:** porque las cinco cosas son ciertas por separado y el plan completo es imposible.
Renombrar columnas obliga a tocar setecientos procedimientos que nadie leyó completos. Agregar llaves
foráneas falla al primer intento —hay 1.900 filas huérfanas— y **qué hacer con ellas es una decisión del
negocio, no tuya**. Unificar las ventas rompe los cuatro volcados CSV que tres socios consumen. Y mover
la lógica requiere entenderla, que es el trabajo que nadie ha hecho.

**Qué se hace en su lugar:** cuatro preguntas a cada cosa que incomoda. **¿De qué año es?** (el campo de
diez caracteres es del formato DBF, de 1983). **¿Qué problema resolvía?** (la bandera `BORRADO` es la
semántica de borrado de FoxPro, y en 2017 permitió que los dos sistemas leyeran los mismos datos).
**¿Qué costaría cambiarlo hoy?** — ese es el número que decide. **¿Qué se rompe si lo toco sin querer?**

**Dónde se rompe el paralelo:** ninguno. Este reflejo no es de lenguaje: es de altura. Es el mismo que
*"si está viejo está mal"* de la sección de arquitectura, visto desde el esquema en vez de desde el
sistema. Tu ventaja sobre quien lo escribió no es saber más: es **tener presupuesto y saber qué pasó
después**, y confundir las dos cosas es cómo se presenta un plan que la presidenta rechaza.

**Desarrollado en:** [fase 07](07-el-sistema-que-heredas.md).

### "Leo qué hace y lo reescribo limpio" — el paso que falla es el de leer

**El código que produce:** una prueba escrita contra lo que el **contrato** dice que debería pasar, y una
implementación nueva que la satisface.

```csharp
// ❌ Escrita contra la especificación, no contra el comportamiento.
var settlement = new SettlementCalculator().Calculate(contract, sales);
Assert.Equal(new Money(4_317_850m), settlement.Royalty);
```

**Por qué falla en C#:** no es del lenguaje — es del método, y es el reflejo más caro del Bloque B. El
reflejo no se presenta como "reescribo sin entender": se presenta como *"leo qué hace, lo escribo limpio
con pruebas de verdad, y comparo"*. Y **"leo qué hace" es el paso que no funciona**: setecientas líneas
de T-SQL con cursores anidados y SQL dinámico se leen con un 90% de exactitud, y el 10% restante son las
reglas que la empresa aplica de verdad y nadie recuerda haber escrito. En Cordillera ese 10% era que las
traducciones se liquidan sobre precio de lista por un error de 2017 — nueve años de liquidaciones.

**Qué se escribe en su lugar:** primero la foto de lo que **hace**, con el sistema viejo, tal cual — un
*golden master* que fija incluso lo que está mal. Después la comparación. Y la distinción que sostiene
todo: **correcto e igual son dos decisiones distintas, y las toman personas distintas**. Descubrir que el
sistema liquida mal es un hallazgo; corregirlo tiene efectos retroactivos y posiblemente legales.

**Dónde se rompe el paralelo:** la disciplina de pruebas se transfiere entera, y Testcontainers es
literalmente la misma biblioteca que usabas en Java. Lo que no se transfiere es la costumbre de tener una
especificación: aquí **no hay ninguna**, y el sistema en producción es la única fuente.

**Desarrollado en:** [fase 08](08-caracterizar-y-probar.md).

### "EF Core es Hibernate y el ORM me abstrae del esquema"

**El código que produce:** un modelo con `DateTime` donde hay un `char(8)`, una navegación a una llave
foránea que no existe, ninguna configuración de filtro, y un `Id` entero donde la clave es compuesta.
Compila, corre, y devuelve datos equivocados.

**Por qué falla en C#:** no falla por el ORM — **un ORM te abstrae del SQL, no del esquema**. EF Core y
Hibernate hacen lo mismo *cuando el esquema colabora*; la diferencia real está entre un esquema diseñado
para un ORM y uno diseñado para FoxPro en 1997. Con el segundo, la configuración **es** el trabajo, y
llamarla magia es cómo se pierden 1.900 filas.

**Qué se escribe en su lugar:** la configuración por API fluida, una rareza por línea, y **el borde en un
solo archivo**. Cada línea de esa configuración es una propiedad del esquema que alguien tuvo que
descubrir, y su longitud es información, no ruido.

**Dónde se rompe el paralelo — y hay una buena noticia:** EF Core **no tiene lazy loading activado**. Una
navegación no cargada es `null`, no una consulta, así que el `N+1` accidental se convierte en un
`NullReferenceException` visible. Te enteras en la primera prueba en vez de en producción.

**Desarrollado en:** [fase 09](09-acceso-a-datos-esquema-hostil.md).

### "Uso `Include` para traer la edición" — y el reporte cuadra distinto

**El código que produce:**

```csharp
await context.Movements.Include(m => m.Edition).ToListAsync(token);   // INNER JOIN
```

**Por qué falla en C#:** porque `Include` sobre una navegación requerida genera un `INNER JOIN`, y el
sistema viejo usaba `LEFT JOIN`. Las 1.900 filas huérfanas —movimientos cuya edición ya no existe—
**desaparecen del resultado**. El reporte nuevo da 340 unidades menos que el viejo, y lo que hace difícil
el diagnóstico es que la diferencia es **pequeña**: si desapareciera la mitad de las filas se vería el
primer día.

**Qué se escribe en su lugar:** sin navegación cuando no hay llave foránea, y la proyección que trae lo que
hace falta. Y la defensa real no es recordar esto: son **las pruebas de caracterización de la fase 08**,
que fijan las 4.300 filas y hacen fallar la versión nueva antes de producción.

**Dónde se rompe el paralelo:** es el mismo comportamiento que en JPA con un `join` sobre una relación
obligatoria. Lo que cambia es el contexto: aquí **las relaciones no existen en la base**, así que toda
navegación es una afirmación tuya sobre datos que a veces no la cumplen.

**Desarrollado en:** [fase 09](09-acceso-a-datos-esquema-hostil.md).

---

## 🚚 Familia: plataforma y runtime

### "Subimos de versión de a poco, como de Java 8 a 11 a 17"

**El código que produce:** un plan de tres saltos — 4.8 a .NET 6, 6 a 8, 8 a 10 — cada uno con sus notas
de compatibilidad.

**Por qué falla en C#:** porque **no hay una escalera**. .NET Framework y .NET moderno no son dos versiones
de lo mismo: son **dos implementaciones distintas** de la misma plataforma, y el salto es uno solo.
Migrar a .NET 6 primero significa hacer el trabajo difícil apuntando a un runtime ya fuera de soporte, y
después hacer otra migración encima. Una vez del otro lado, subir de .NET 6 a 10 sí es trivial.

**Qué se hace en su lugar:** un salto, a la versión LTS vigente, **un proyecto a la vez y con los dos
runtimes vivos** — que se puede, porque conviven en el mismo sistema aunque no en el mismo proceso. Y el
orden lo decide lo que duele si falla, no el grafo de dependencias.

**Dónde se rompe el paralelo:** `jdeps` y el informe de portabilidad hacen lo mismo, pero `--add-opens` y
el **paquete de compatibilidad de Windows** no son equivalentes: el segundo hace que el código *compile*, y
algunas de sus implementaciones no hacen nada.

**Desarrollado en:** [fase 11](11-migrar-el-runtime.md).

### "Hay que reescribir 250.000 líneas"

**El código que produce:** una estimación de dieciocho meses, calculada por volumen.

**Por qué falla en C#:** porque **el lenguaje es el mismo y el código de dominio pasa sin tocarse**. Un
cálculo de regalías escrito en C# 2 en 2017 compila en .NET 10 y produce el mismo número. En SIGE, ~40%
pasa intacto, ~15% cambia un paquete de acceso a datos, ~3% es configuración mecánica, ~35% son formularios
que van sobre .NET 10 — y **el 5% restante, las APIs que no existen, se lleva el 80% del esfuerzo**. Estimar
por líneas da un número diez veces mayor que la realidad.

**Qué se hace en su lugar:** correr el informe de compatibilidad, que en media hora dice cuántas llamadas a
APIs inexistentes hay y dónde. **Esa es la estimación.**

**Dónde se rompe el paralelo, y es la trampa que no tiene equivalente:** hay APIs que **compilan y
revientan** —`ConfigurationManager.AppSettings` devuelve `null`, silenciosamente— porque el paquete de
compatibilidad las declara sin implementarlas. Una API que no existe es buena noticia; una que compila y no
funciona escribe cuarenta PDF de liquidación en una carpeta del sistema.

**Desarrollado en:** [fase 11](11-migrar-el-runtime.md).

---

## 🪟 Familia: interfaz de escritorio

### "Esto hay que reescribirlo sí o sí"

**El código que produce:** ninguno. Produce **el plan de la reunión**: *"WinForms está obsoleto,
reescribamos el cliente como aplicación web, cuarenta pantallas al año, y encima nos ahorramos el
despliegue."*

**Por qué falla en C#, y son cuatro razones con números:** (1) **WinForms no está obsoleto** — está en
.NET 10, con soporte de largo plazo y sin fecha de fin de línea anunciada; que no reciba novedades no es lo
mismo que estar muerto, y el código que no cambia no las necesita. (2) Cuarenta pantallas al año sobre 340
son **ocho años y medio**, no tres, con las dos versiones conviviendo todo ese tiempo. (3) **La web no
ahorra el despliegue: lo cambia de sitio** — desaparecen noventa instalaciones y aparece un servidor que
tiene que estar disponible y el depósito de Lima con su conexión. (4) Y la que decide: quien lo mantiene es
Duván, que sabe WinForms y C#. **Una plataforma que tu único compañero no domina dura lo que dures tú.**

**Qué se hace en su lugar:** mover los 340 formularios a .NET 10 —que es mecánico— y arreglar las tres cosas
que de verdad molestan: que se congelan, que se ven borrosos y que el despliegue es manual. Semanas, no
años. Y las pantallas **nuevas** se hacen en web, porque son nuevas.

**Dónde se rompe el paralelo:** en una empresa con equipos y presupuesto, reescribir una interfaz se decide
por el roadmap de producto. Aquí se decide por **quién queda sosteniéndolo**, y el equipo son dos personas.
Eso no hace la decisión más pobre: la hace más honesta, porque el costo de mantenimiento no se puede
esconder en otro presupuesto.

**Desarrollado en:** [fase 12](12-winforms-en-net-10.md), y medido en la [14](14-veredicto-del-escritorio.md).

### "El controlador manipula los controles por su nombre"

**El código que produce:** un modelo de vista con un `DataGrid` y un `TextBlock` inyectados por
constructor, empujando datos a los controles. Compila y funciona.

**Por qué falla en C#:** porque acaba de perder **todo** lo que MVVM compraba. Ese tipo necesita un
`DataGrid` para existir, un `DataGrid` necesita un contexto de WPF, y un contexto de WPF necesita un hilo de
interfaz — así que **la prueba que querías escribir es ahora una prueba de interfaz**: lenta, frágil, y que
no corre en CI.

**Qué se escribe en su lugar:** un modelo de vista **sin un solo tipo de WPF**, que expone estado y
comandos, y una vista que se enlaza a él. Los errores se exponen **como estado y no como `MessageBox`**,
porque una ventana dentro del modelo de vista lo vuelve a hacer inejecutable.

**Dónde se rompe el paralelo — y es la prueba de si el patrón está bien aplicado:** el patrón no es la
estructura de carpetas, es **la dirección de la dependencia**. Tres carpetas llamadas `Models`,
`ViewModels` y `Views` con un `DataGrid` inyectado son MVVM en la forma y un controlador en el fondo. La
pregunta que lo decide es una sola: **¿se puede instanciar el modelo de vista en una prueba sin referenciar
WPF?**

**Desarrollado en:** [fase 13](13-wpf-y-mvvm.md).

### "El binding funciona, es declarativo" — y la etiqueta está vacía

**El código que produce:**

```xml
<TextBlock Text="{Binding Sumary}" />   <!-- y la propiedad se llama Summary -->
```

**Por qué falla en C#:** porque **no falla**. El XAML se resuelve por reflexión en tiempo de ejecución, así
que un nombre mal escrito no es un error de compilación y **no lanza nada**: WPF busca la propiedad, no la
encuentra, y deja el control con su valor por omisión. Las pruebas del modelo de vista siguen verdes —el
modelo de vista está perfecto— y la pantalla está vacía. El único rastro está en la ventana de salida del
depurador, entre cien líneas de otras cosas.

**Qué se escribe en su lugar:** las tres defensas juntas, porque ninguna basta sola. **Elevar el
diagnóstico de binding a error** en desarrollo —la línea que casi nadie conoce y que convierte el fallo
silencioso en ruidoso—, declarar el tipo del contexto de datos para que el editor ayude, y **probar el
modelo de vista**: la suite cubre la lógica y el diagnóstico cubre el enlace.

**Dónde se rompe el paralelo:** en tu mundo, una referencia a algo que no existe la atrapa el compilador.
Aquí el enlace es un contrato **por nombre y en tiempo de ejecución**, más parecido a una expresión de una
plantilla JSP que a una llamada a un método. Y WinUI 3 lo arregla con `x:Bind`, que **sí** se resuelve en
compilación — es una de las ventajas reales que la tabla del veredicto registra.

**Desarrollado en:** [fase 13](13-wpf-y-mvvm.md).

### "Elijamos la plataforma más nueva, así no hay que volver a hacerlo"

**El código que produce:** una decisión de años tomada con un criterio de calendario.

**Por qué falla en C#:** porque *"la más nueva"* no es una propiedad del resultado, es una propiedad de la
fecha. Y la genealogía de la interfaz de Windows tiene **cuatro generaciones en veinticuatro años y ninguna
mató a la anterior**: WinForms (2002) sigue soportada en .NET 10; WPF (2006) se anunció como su sucesora y
no la reemplazó; UWP (2015) fue la apuesta siguiente y hoy su camino es WinUI 3; WinUI 3 (2021) es la
plataforma actual. Las tres primeras, **con soporte vigente**.

Eso no dice que WinUI 3 vaya a fracasar: dice que **"es la plataforma actual" no es un argumento
suficiente**, porque las tres anteriores también lo fueron. Y el supuesto de que migrar es un costo único es
falso con 340 pantallas: es un costo de años, con dos tecnologías conviviendo.

**Qué se hace en su lugar:** una tabla con cinco criterios, y **el quinto puede vencer a los cuatro
primeros juntos** — no por sentimentalismo, por aritmética de riesgo.

**Dónde se rompe el paralelo:** en la JVM la pregunta análoga —¿qué versión de Java?— tiene una escalera
clara y una respuesta casi siempre obvia. Aquí no hay escalera: hay cuatro opciones vivas a la vez, y
elegir es un trabajo.

**Desarrollado en:** [fase 14](14-veredicto-del-escritorio.md).

### "Si es más moderno, el despliegue también será más simple"

**El código que produce:** un prototipo terminado en una tarde y **una reunión que aprueba una tecnología
que no se puede instalar**.

**Por qué falla en C#:** porque es al revés. MSIX —de 2018— es más limpio que ClickOnce y **necesita un
certificado de firma en el que los noventa equipos confíen**: o se compra uno comercial, o se instala uno
propio en noventa equipos, o se activa el modo de desarrollador en noventa equipos. **Las tres requieren
exactamente lo que no hay**: dinero no presupuestado o permisos de administrador. Mientras que ClickOnce
—de 2002, que nadie llamaría moderno— **instala sin permisos**, porque se diseñó en una época en que los
usuarios corporativos no los tenían. La restricción de 2002 sigue siendo la de 2026.

**Qué se hace en su lugar:** medir el despliegue **antes** de la reunión, en un equipo que no sea el tuyo.
Funcionar en tu máquina no es el criterio: tú tienes permisos.

**Dónde se rompe el paralelo:** `jpackage` produce un instalador que no exige firma, así que este problema
no tiene equivalente directo en Java. Lo que sí se transfiere es la forma: **el prototipo se hizo en dos
días y ponerlo en un equipo ajeno llevó tres semanas** — proporción de uno a diez, y la reunión no tenía
ese dato.

**Desarrollado en:** [fase 14](14-veredicto-del-escritorio.md).

---

## 🌐 Familia: servicios, identidad y operación

### "Devuelvo la entidad y listo"

**El código que produce:**

```csharp
app.MapGet("/editions/{id}", async (string id, SigeContext db, CancellationToken token) =>
    await db.Editions.FindAsync([new EditionId(id)], token));
```

Y lo que el socio comercial recibe: `format: 1`, `imprint: 2`, `isDeleted: false`, `id: { "value": "…" }`.

**Por qué falla en C#:** por cinco razones y ninguna es de rendimiento. Los `enum` salen **como números**, así
que el consumidor escribe `if (format == 1)` y el día que alguien agregue un formato en medio del `enum` los
números cambian de significado; `isDeleted` es la bandera `BORRADO` de FoxPro filtrándose hacia afuera; los
identificadores salen envueltos porque son `record struct`; el identificador interno queda en la base de un
tercero; y **el contrato cambia cuando cambia la entidad**, sin que nadie lo decida.

**Qué se escribe en su lugar:** un DTO como **decisión** —cada campo está ahí porque alguien lo quiso— con
mapeo **a mano** y un `switch` exhaustivo que **deja de compilar** cuando alguien agrega un valor al `enum`
del dominio. Eso obliga a decidir cómo se llama hacia afuera, en vez de dejar que se filtre un número.

**Dónde se rompe el paralelo:** en un servicio interno devolver la entidad es una simplificación razonable y
todo el mundo la ha hecho. Lo que cambia es **quién está al otro lado**: un tercero con su propio código en
producción, para el que la v2 es una negociación y no un despliegue. Y la frase que lo resume: **el borde de
la F09 protege el dominio del esquema; el DTO protege al mundo del dominio.**

**Desarrollado en:** [fase 15](15-aspnet-core-minimal-apis.md).

### "La validación va en el servicio"

**El código que produce:** un `if (page < 1) throw new ArgumentException(...)` dentro del servicio — que
produce un `500` con una traza, porque una excepción de argumento no es una respuesta HTTP.

**Por qué falla en C#:** porque una petición mal formada **es parte del trabajo de un endpoint público** y
llega varias veces al día: es la política de errores de la F04 aplicada aquí. Y porque deja el dominio con
código de validación de entrada, que no es su trabajo.

**Qué se escribe en su lugar:** validación **en el borde**, devolviendo problemas y no lanzando, con
`ProblemDetails` (RFC 9457) como formato — un estándar, así que el consumidor programa contra él sin leer
nuestra documentación.

**Dónde se rompe el paralelo:** ASP.NET Core **no valida por omisión** los parámetros contra anotaciones como
hace Spring con `@Validated`. Hay que pedirlo, con un filtro o explícitamente. Es más trabajo y más visible, y
el precio de omitirlo es un `500` donde debía haber un `400`.

**Desarrollado en:** [fase 15](15-aspnet-core-minimal-apis.md).

### "La cadena de conexión va en el archivo de configuración"

**El código que produce:** la línea que SIGE tiene desde 2017, copiada en noventa `App.config`.

**Por qué falla en C#, y son tres razones en orden de importancia — la de "texto plano" es la menos
importante:** (1) **no se puede rotar**, y por eso la contraseña de 2017 sigue siendo la de 2026: cambiarla
significa visitar noventa equipos; (2) está en **todas las copias del archivo** —noventa discos, sus
respaldos, la imagen que sistemas clona, el correo donde alguien la mandó en 2019— y no hay forma de saber
cuántas hay; (3) **no se puede auditar**, porque leer un archivo no deja rastro.

**Qué se escribe en su lugar:** un proveedor de configuración que lea del gestor de secretos, con **una sola
ruta de código** entre el equivalente local y el real. Sin un `if` por ambiente: la diferencia está en qué
fuentes hay disponibles, porque **un camino que solo se ejerce en producción es un camino sin probar**.

**Dónde se rompe el paralelo:** Spring tiene `spring-cloud-config` y Jasypt, así que la idea se transfiere. Lo
que cambia es que en .NET **el proveedor es parte del marco**, así que el código que consume no distingue de
dónde viene el valor — y eso hace mucho más fácil cumplir la regla de la ruta única.

**Y la lección transferible, que es más grande que la técnica:** la cadena salió de los noventa equipos
**porque la F10 cortó la conexión directa a la base**, no por una decisión de seguridad. Mientras el cliente
hablara con SQL Server, tenía que tener credenciales. **La mejor forma de proteger un secreto es no
necesitarlo.**

**Desarrollado en:** [fase 16](16-identidad-secretos-y-configuracion.md).

### "Le pongo una clave en una cabecera y ya está asegurado"

**El código que produce:** `if (request.Headers["X-Api-Key"] != "almenara-2019-clave-compartida")` — y la
clave está en el código, así que está en el repositorio y en el historial.

**Por qué falla en C#:** cuatro problemas, todos de diseño. La clave está en el código; **es la misma para
todos los consumidores**, así que no se puede revocar a uno sin revocar a todos; no dice **quién** es el
portador, solo que conoce la clave; y no caduca, así que si se filtra es para siempre.

**Qué se escribe en su lugar:** autenticación delegada a quien sabe hacerla, y autorización **por políticas
con nombre** — la regla vive en un sitio y los endpoints la citan, así que cambiarla es una línea y no ciento
veinte archivos.

**Dónde se rompe el paralelo:** el razonamiento de Spring Security se transfiere entero, con otro vocabulario
—*claims* en vez de autoridades, políticas en vez de expresiones en anotaciones—. Y hay algo que Spring
Security hace y .NET no: **no hay una configuración por omisión que asegure todo**. Si un endpoint no pide
autorización, es anónimo — así que los anónimos tienen que estar **declarados**.

> 📏 Y el dato incómodo que la medición de la F16 publica: **la clave compartida es la más rápida de las
> cuatro opciones**. Comparar una cadena siempre va a ser más barato que validar una firma. Lo que la medición
> demuestra es que la diferencia es tan pequeña que **el argumento de rendimiento no existe**.

**Desarrollado en:** [fase 16](16-identidad-secretos-y-configuracion.md).

### "El proceso nocturno se reinicia desde cero"

**El código que produce:** un `foreach` sobre veintiún mil contratos con todo el progreso en memoria. Seis
horas, y si falla en la quinta empieza de nuevo.

**Por qué falla en C#:** porque a las seis horas la probabilidad de que algo falle deja de ser pequeña —un
despliegue, un reinicio, un bloqueo, una pérdida de red— y **cuanto más tarda, más caro es reiniciar**: la
ejecución que falla en la hora cinco no cuesta cinco horas, cuesta diez.

**Qué se escribe en su lugar:** lotes con el progreso **persistido en la base**, no en memoria, y una unidad
de progreso lo bastante pequeña para que perder una no duela. Es una **máquina de estados persistida** y el
bucle es un detalle.

**Dónde se rompe el paralelo — y es la fila que cambia la estimación:** **no existe un equivalente estándar de
Spring Batch.** Hay `BackgroundService` para hospedar, Polly para la resiliencia, Quartz.NET o Hangfire para
la programación — y ninguna cubre la máquina de estados por lotes con su repositorio de ejecuciones. Se
escribe a mano, en unas doscientas líneas: **menos marco, más decisión, y todo el diseño visible.**

**Desarrollado en:** [fase 17](17-trabajo-de-fondo.md).

### "Ya es reanudable" — y es la máquina de duplicar pagos

**El código que produce:**

```csharp
if (run.LastCompletedBatch is { } last) { batches = batches.Skip(last); }
```

**Por qué falla en C#:** porque el lote 340 **se procesó a medias**: se escribieron 180 de sus 200
liquidaciones y el proceso murió antes de marcarlo como completo. La siguiente ejecución reanuda en el 340
—correctamente, porque el lote no se marcó— y **vuelve a escribir esas 180**. A ciento ochenta autores les
llega el pago dos veces. Y lo peor: **el proceso termina bien**, los totales cuadran con lo que el proceso cree
que hizo, y el descubrimiento llega por tesorería tres semanas después.

**Qué se escribe en su lugar:** **la idempotencia primero y la reanudación después**, en ese orden. Una clave
de operación compuesta por el negocio —periodo + contrato— **impuesta por una restricción única en la base**,
no comprobada antes de insertar, que eso es una carrera. Con la clave puesta, reanudar en un lote a medias es
seguro por construcción.

**Dónde se rompe el paralelo:** en Spring Batch la reanudación viene con transacción —el progreso se marca en
la misma transacción que escribe los resultados, así que un lote a medias no existe—. Aquí hay que
construirlo, y **si se construye la mitad, el resultado es peor que no tener nada**: sin reanudación un fallo
obliga a reiniciar y alguien lo nota; con reanudación sin idempotencia, nadie lo nota.

**Desarrollado en:** [fase 17](17-trabajo-de-fondo.md).

### "Elijamos el modelo de render por lo que se usa hoy"

**El código que produce:** una aplicación entera en Blazor Server, decidida en dos días porque escribirla es
genuinamente rápido —el componente habla con la base sin API intermedia— y aprobada porque en la demo se vio
instantánea.

**Por qué falla en C#:** porque en Blazor Server **cada interacción es un viaje de ida y vuelta**, y el estado
de la sesión vive en el servidor dentro de un *circuito*. Con la conexión de la oficina donde está el
desarrollador eso no se nota. Con la del depósito de Lima, el filtro se siente pegajoso y —lo peor— una pérdida
de paquetes moderada **tira el circuito y el usuario pierde lo que estaba escribiendo**. Y hay un costo que no
se ve en la demo: el circuito **exige sesiones adheridas**, así que escalar no es agregar instancias.

**Qué se escribe en su lugar:** la misma pantalla en los modelos candidatos —el componente es el mismo archivo,
lo único que cambia es el registro de dependencias— y **la latencia de las oficinas reales inyectada desde el
primer día de desarrollo**, con pérdida de paquetes incluida. Es una línea de configuración y cambia la
decisión.

**Dónde se rompe el paralelo:** el dato que desarma el reflejo es que **los tres modelos son indistinguibles en
la oficina del desarrollador**. No es que uno sea malo: es que la diferencia solo aparece donde nadie está
midiendo, y por eso esta decisión se toma mal tan a menudo. Y donde falla la analogía con JSF —que es el
paralelo más cercano— es que aquí el marco gestiona la reconexión, así que el fallo no es un error visible: es
un formulario que se perdió.

> 📏 Y el número de la F18 que hay que tener a mano: **cuántos milisegundos de ida y vuelta hacen falta para
> que deje de sentirse instantáneo**. Es el único umbral del curso que se determina sintiéndolo, y está
> justificado: la pregunta —*¿se puede trabajar ocho horas con esto?*— no la contesta un percentil.

**Desarrollado en:** [fase 18](18-blazor-server-wasm-mvc.md).

### "MVC clásico está obsoleto"

**El código que produce:** una SPA descartando de entrada la opción que mejor tolera una conexión mala, para
cuarenta pantallas de formularios y listas.

**Por qué falla en C#:** porque MVC renderiza en el servidor y **solo paga en la navegación**: si la red es
mala, la página tarda en llegar y después se usa sin problema. Para CRUD con interactividad modesta —que es
exactamente lo que son cuarenta pantallas de back-office— eso es la opción más robusta que existe. Y la SPA
tiene un costo que se paga donde más duele: **la carga inicial**, varios megabytes descargados desde la
oficina con la peor conexión, y **una API para todo**, que es código que hay que escribir y mantener.

**Qué se escribe en su lugar:** elegir con la tabla, no con la fecha. Y desde .NET 8 la pregunta ya no es
excluyente: hay **modo de render por componente**, así que se puede empezar en el servidor y mover una pantalla
concreta. Lo que no se puede es mezclar sin datos, que es la forma más fácil de acabar con lo peor de dos.

**Dónde se rompe el paralelo — y es la fila que decide:** en el mundo de Java, la elección entre Thymeleaf y
una SPA se resuelve casi siempre a favor de la SPA **porque el equipo de frontend existe y es otro equipo**.
Cuando no hay otro equipo, el criterio cambia de *"qué produce mejor experiencia"* a *"qué pueden mantener dos
personas"*. Es el mismo reflejo de la F12 con WinForms, una capa más arriba.

**Desarrollado en:** [fase 18](18-blazor-server-wasm-mvc.md).

### "Registro todo por si acaso"

**El código que produce:** `INFO` en cada paso, el objeto completo como parámetro estructurado, y ochenta
millones de líneas al mes.

**Por qué falla en C#:** por tres razones de tamaño creciente. El costo, que la F20 convierte en una línea de
factura con el mismo mecanismo de crecimiento que un `SELECT *`. La utilidad: **un registro que nadie lee no es
observabilidad, es basura con fecha**, y buscar las tres líneas que importan entre ochenta millones es el
problema que la observabilidad venía a resolver. Y la peor, que casi nadie nombra: **registrar todo es la forma
más fácil de filtrar datos personales**. `logger.LogInformation("… {Manuscript}", manuscript)` serializa el
objeto entero —el autor, su correo, el monto del anticipo— y **pasa la revisión de código porque se ve bien**.

**Qué se escribe en su lugar:** la señal correcta para cada pregunta —métrica para saber que algo pasa, traza
para saber dónde, registro para el contexto puntual— y el identificador de traza en cada línea, que es lo que
conecta las tres. Para los datos sensibles, un tipo que **solo exponga lo registrable**, de modo que pasar el
objeto completo no compile: una regla que depende de que alguien se acuerde falla el día que hay prisa.

**Dónde se rompe el paralelo:** los niveles, el registro estructurado y el criterio de qué merece una alerta se
transfieren completos. Lo que cambia es el destino: la telemetría suele tener **retención más larga, controles
más flojos y más gente con acceso** que la base de datos original, así que un dato personal que llega ahí está
peor guardado que donde vive.

**Desarrollado en:** [fase 19](19-observabilidad-y-operacion.md).

### "Instrumento lo nuevo, que es donde estoy trabajando"

**El código que produce:** OpenTelemetry impecable en los proyectos modernos, y un muro donde empieza el
sistema heredado. El tramo dice `EXEC SP_CATALOGO — 3.800 ms` y ahí se acaba.

**Por qué falla en C#:** porque la instrumentación automática **se detiene exactamente donde está el problema**.
Si el 80% del tiempo vive en un procedimiento de 1997, una traza que solo ve lo moderno mide el 20% con
precisión exquisita — y lleva a la conclusión falsa de que el código nuevo es el problema, **porque es el único
que se ve**.

**Qué se escribe en su lugar:** cruzar el borde a mano, y hay tres formas legítimas: instrumentar el motor con
eventos extendidos correlacionados por `sp_set_session_context`; envolver el procedimiento en tramos propios; o
—y a veces es la respuesta— **no cruzarlo y medir por fuera**, cuando la decisión ya está tomada y el detalle
no la cambia.

**Dónde se rompe el paralelo:** en Java la propagación entre servicios es casi automática porque todos los
servicios son tuyos y usan el mismo agente. Aquí hay **un borde donde la instrumentación automática se termina**
y pasar al otro lado es artesanía deliberada. **Ninguna documentación lo presenta como patrón**, porque ningún
tutorial contempla un sistema de 1997 debajo de uno de 2026.

**Desarrollado en:** [fase 19](19-observabilidad-y-operacion.md).

### "El tramo del API dice 4.100 ms, entonces el API se lleva 4.100"

**El código que produce:** ninguno — produce una tarde optimizando la capa equivocada.

**Por qué falla en C#:** porque **un tramo padre incluye el tiempo de sus hijos**. La fila del API no dice "el
API tardó eso": dice "todo lo que pasó dentro de la petición tardó eso". El trabajo propio de una capa es su
duración **menos** la de sus hijos, y olvidar la resta es cómo se culpa a la capa de arriba de lo que hizo la
de abajo.

**Qué se escribe en su lugar:** leer una traza como un árbol y restar. Y en una tabla que reparte un total
—como la de la F19— **comprobar que las filas suman**: si no suman, falta un tramo por instrumentar, y ese
tramo que falta es probablemente el interesante.

**Dónde se rompe el paralelo:** no se rompe, y ahí está el problema. Es idéntico en los dos mundos, se enseña en
ninguno, y es el error de lectura de trazas más común que existe.

**Desarrollado en:** [fase 19](19-observabilidad-y-operacion.md).

### "La imagen se construye una vez, el tamaño da igual"

**El código que produce:** un `Dockerfile` de una etapa con el SDK dentro, y una imagen de cientos de
megabytes que nadie volvió a mirar.

**Por qué falla en C#:** porque el tamaño **se paga muchas veces, no una**. Poco en almacenamiento del
registro; bastante en **transferencia cada vez que un nodo descarga la imagen** —cada despliegue, cada escalado,
cada reinicio—; y en **tiempo de arranque**, que determina cuánto tarda un despliegue y cuánto tarda en
recuperarse una instancia caída. Y hay una razón que no es de dinero: una imagen con intérprete de comandos,
herramientas de red y un compilador dentro es **superficie de ataque** que la aplicación no necesita.

**Qué se escribe en su lugar:** construcción en varias etapas —SDK en la de construcción, nunca en la final— y
la base más pequeña que sirva: `runtime-deps` reducida con un ejecutable autocontenido. El tamaño se mide como
cualquier otra métrica del curso.

**Dónde se rompe el paralelo:** el razonamiento JDK⇄JRE se transfiere entero. Lo que no tiene equivalente es
que **.NET Framework 4.8 solo corre en Windows**, y una imagen de Windows Server es de otro orden de magnitud
que una de Linux: gigabytes contra megabytes. Eso convierte un módulo sin migrar en una fila de la factura, y es
el argumento económico que le faltaba a la F11.

> ⚠️ Y el efecto secundario que hay que haber sufrido una vez: la imagen reducida **no trae intérprete de
> comandos**, así que no puedes entrar a mirar cuando algo falla. Es exactamente la razón por la que la F19
> existe: si no puedes entrar, tenías que haber instrumentado. Y el recorte **rompe la reflexión**, con un
> fallo que aparece solo en producción y no en tu máquina.

**Desarrollado en:** [fase 20](20-contenedor-y-la-factura.md).

### "Kubernetes, que es el estándar"

**El código que produce:** un clúster para cuatro cosas en producción, mantenido por las dos personas que
además arreglan el cierre de regalías cuando falla.

**Por qué falla en C#:** no falla técnicamente — y ahí está la trampa. Kubernetes funciona y resuelve problemas
reales. El error es suponer que **el umbral donde empieza a convenir está más abajo de donde está**: agrega un
plano de control que hay que actualizar, nodos que **se pagan encendidos aunque no haya tráfico**, una capa de
red que hay que depurar cuando falla, y un vocabulario que alguien tiene que aprender *además* de mantener el
sistema heredado.

**Qué se escribe en su lugar:** la opción más simple que sirva —contenedores administrados, para este tamaño— y
**el umbral de tráfico escrito** a partir del cual la respuesta cambiaría. Un "no lo necesitamos" sin umbral es
un prejuicio; con umbral es una decisión con fecha de revisión.

**Dónde se rompe el paralelo — y es la fila que decide:** en el mundo de Java la infraestructura suele ser de
otro equipo, así que su costo de operación no sale de tu presupuesto ni entra en tu decisión. Aquí **sale del
mismo par de manos**, y eso lo vuelve el criterio dominante. Es la misma lógica que la F18 aplicó a los
frameworks de JavaScript, con tres ceros más. **El orquestador cobra dos veces**: en la factura y en las horas,
y la segunda factura no aparece en ninguna calculadora.

**Desarrollado en:** [fase 20](20-contenedor-y-la-factura.md).

### "Evalúo la arquitectura y después vemos cuánto cuesta"

**El código que produce:** una propuesta técnicamente impecable que alguien tiene que firmar sin saber qué
paga.

**Por qué falla en C#:** porque **lo que no tiene síntoma técnico solo aparece en la factura, y crece con el
éxito**. Las tres deudas que la F20 cobra son el mismo mecanismo con distinta ropa: el volcado completo del
catálogo que un integrador descarga cada hora, la telemetría sin muestreo, la cola en tabla. Las tres
funcionan. Ninguna aparece en una traza, en una prueba ni en un percentil. Y las tres **cuestan más el día que
al negocio le vaya mejor**, que es exactamente el mecanismo que hizo que un traslado a la nube saliera un 30%
por encima del centro de datos.

**Qué se escribe en su lugar:** la factura como parte del diseño, con cada línea marcada por **cómo crece**
—fija, por petición, por gigabyte, por usuario— y cada cifra con precio publicado, fuente, fecha y región. Y la
columna incómoda: **cuánta capacidad se está pagando sin usar**. Una máquina al 8% de CPU cuesta igual que al
80%, y un nodo vacío igual que uno lleno.

**Dónde se rompe el paralelo:** no hay nada específico de .NET aquí, y eso es lo que lo hace peligroso: se
delega en un área que no diseñó el sistema. Lo que sí cambia respecto al centro de datos es que **allí el
desperdicio ya estaba comprado**; en la nube es una cuota mensual. Y un servidor olvidado, que en el centro de
datos no le costaba a nadie, en la nube factura cinco años.

> 📏 Y el corolario que la F20 agrega a la trilogía del curso: **"se deja quieto" ahora exige la cifra al
> lado**. Un "se deja quieto" con su costo escrito es una decisión; sin la cifra es una omisión.

**Desarrollado en:** [fase 20](20-contenedor-y-la-factura.md).

---

## 📊 Familia: datos, modelos e IA

### "El número está en la base, entonces el número es ese"

**El código que produce:** la consulta correcta, el total correcto, y un conjunto de entrenamiento envenenado.

```csharp
// La foto de cada mes, tomada hoy. Parece obvio y es el defecto.
var entrenamiento = await db.Ventas.GroupBy(v => v.Periodo).Select(/* … */).ToListAsync();
```

**Por qué falla en C#:** no falla en C# — falla en este dominio, y por eso es más peligroso. En un negocio con
devoluciones, **el dato todavía no terminó de llegar**: el sell-in de marzo está completo y las devoluciones de
marzo se registran entre mayo y agosto. La cifra no está mal calculada, **está temprano**, y no hay nada en la
base que lo diga.

Y el daño no es el informe: es que **los meses recientes se ven mejores que los antiguos** —no porque vendieran
más, sino porque sus devoluciones no han llegado—, así que el modelo aprende que las ventas están creciendo. No
están creciendo.

**Qué se escribe en su lugar:** la fecha de corte **adherida al dato, en el tipo y requerida**, y el conjunto
armado con **edad de observación constante**: cada periodo como se veía a los N días. En este dominio un número
no es un número: **es un número y la fecha en que se miró**.

**Dónde se rompe el paralelo:** nada de esto es de plataforma, y ahí está la trampa. Es la misma disciplina que
la F17 aplicó al dinero —`ConvertedMoney` lleva la tasa adentro— en otro terreno: **lo que el negocio no puede
perder no se deja en el aire**.

> 📏 Y lo que hace a este reflejo peor que los demás: **la validación no lo detecta**. La partición de validación
> tiene el mismo defecto que la de entrenamiento, así que un error de validación excelente **es la prueba de que
> el modelo aprendió bien la mentira**. Sin síntoma, sin excepción, sin prueba en rojo.

**Desarrollado en:** [fase 21](21-datos-y-onnx.md).

### "Lo entrenamos aquí, para no salir del ecosistema"

**En qué se traduce:** una canalización de aprendizaje automático escrita en C# porque el repositorio es de C#.

**Por qué falla:** porque el trabajo difícil de este problema **no es el modelo, es entender los datos** —curva
de devolución, estacionalidad por país, el efecto de un autor con histórico contra uno sin él— y eso se hace
explorando, en el ecosistema donde explorar tiene menos fricción. Y porque **quien lo va a hacer no es tu
compañero**: es alguien contratado unas semanas que trabaja en Python, y obligarla a aprender otra herramienta es
pagar consultoría en aprendizaje.

**Qué se escribe en su lugar:** entrenar afuera, **exportar a ONNX y servir desde .NET en proceso** — cuarenta
líneas, sin llamada de red, sin otro despliegue, con latencia de milisegundos. Servir es lo que esta plataforma
hace excelente.

**Dónde se rompe el paralelo — y es la fila que lo desarma:** en la JVM el reflejo equivalente tiene un
argumento real, porque hay un ecosistema de datos maduro ahí. En .NET es más débil, y **la propia plataforma lo
admite**: ONNX Runtime es de Microsoft y existe para que no tengas que entrenar aquí. Cuando la plataforma te da
la puerta de salida, insistir en no usarla no es lealtad, es trabajo extra.

> 📚 Es el reflejo de la F18 **invertido** —*no adoptes un ecosistema que no puedes mantener*— y conviene leer los
> dos juntos: la pregunta no es cuántas plataformas tocas, es **quién va a mantener cada una**.

**Desarrollado en:** [fase 21](21-datos-y-onnx.md).

### "Montemos el aparato vectorial" — sin probar si el texto completo ya resolvía

**En qué se traduce:** embeddings, índice vectorial y una factura de reindexación, para un corpus donde quien
pregunta usa las mismas palabras que el documento.

**Por qué falla:** porque una parte grande de estas preguntas **no es semántica, es terminológica**. Un contrato
de derechos dice "portugués", "Brasil", "exclusiva", "vigencia", y quien pregunta también, porque trabaja en el
negocio. El texto completo encuentra eso rápido, barato, **sin reindexar nada** y con una explicación de por qué
encontró cada resultado — que en un asunto legal vale más de lo que parece.

**Qué se escribe en su lugar:** las formas candidatas medidas sobre **el mismo conjunto de preguntas**, y el
resultado publicado aunque gane la aburrida. Y antes de eso: mirar si el motor que ya está pagado tiene búsqueda
vectorial nativa, porque desde SQL Server 2025 la tiene y **no exige infraestructura nueva**.

**Dónde se rompe el paralelo:** la elección entre Lucene y un índice vectorial se transfiere entera. Lo que
cambia es que aquí **la opción barata vive en la base que ya se respalda y que tu compañero sabe operar**, y eso
mueve el umbral.

> 📏 Y la factura que este reflejo no ve: los embeddings **se recalculan enteros cada vez que cambia el modelo de
> embeddings**. La caché no sirve de nada justo el día que más falta hace.

**Desarrollado en:** [fase 22](22-ia-aplicada.md).

### "Que el agente decida lo obvio y nos deje los casos dudosos"

**En qué se traduce:** un agente que archiva el 90% de los manuscritos y pasa el 10% a una persona.

**Por qué falla:** porque **los dos errores no cuestan igual y uno de los dos es invisible**. Pasarle a Ximena un
manuscrito mediocre le cuesta dos minutos. Archivar en silencio uno bueno le cuesta un libro que publica otra
editorial — y **nadie se va a enterar nunca**, así que ninguna métrica de producción lo va a mostrar. Un sistema
cuyo peor error no es observable **no puede tener autonomía**: la medición que lo justificaría no existe.

**Qué se escribe en su lugar:** el sistema ordena, prioriza y prepara; **la persona descarta**. Y la garantía no
es el prompt: es que **no exista una herramienta que archive**. Un agente no puede hacer aquello para lo que no
le diste herramienta — el principio de menor privilegio de la F16 en un sitio donde casi nadie lo aplica.

**Dónde se rompe el paralelo:** el instinto de automatizar el camino feliz y escalar excepciones asume que un
error se detecta y se corrige. Aquí **el error caro es el silencioso**, y eso invierte el diseño.

**Desarrollado en:** [fase 22](22-ia-aplicada.md).

### "Le digo en el prompt que cite la cláusula"

**En qué se traduce:** una instrucción bien escrita, y una respuesta con forma de cita que nadie comprueba.

**Por qué falla:** porque un modelo al que le pides que cite **produce algo con forma de cita**. El caso que
cuesta dinero no es la referencia inventada —esa se detecta—: es **la cita real que no responde la pregunta**. La
cláusula 7 del contrato de 1994 cede portugués **para Portugal**; existe, es real, habla de portugués, y no dice
nada sobre Brasil. Cualquier verificación que solo compruebe que la referencia resuelve, da verde.

**Qué se escribe en su lugar:** **la cita no se le pide al modelo, se verifica después** — y no se verifica que
exista, se verifica que **cubra los términos de la pregunta**: idioma, territorio y vigencia, los tres, de forma
determinista y con los términos extraídos en la ingesta. Lo que el modelo produce es un borrador; **lo que sale
es lo que la verificación aprueba**.

**Dónde se rompe el paralelo:** no se rompe — **es la F08 otra vez**. No se confía en que algo se comporte bien,
se compara su salida contra una referencia. Que el mismo patrón resuelva la caracterización de un procedimiento
de 1997 y la cita de un contrato es la mejor señal de que es un patrón y no un truco.

> 🧭 **El corolario, y es lo más transferible del bloque E:** la calidad del sistema **no es la calidad del
> modelo**, es la calidad de la verificación. Esa la escribes tú, la pruebas con xUnit, y no cambia cuando el
> proveedor actualice.

**Desarrollado en:** [fase 22](22-ia-aplicada.md).

---

## 📐 Familia: medir y comparar

*Nace en la fase 23, y es la familia que el curso necesitaba desde la 00 sin saberlo: los dos reflejos de abajo
no producen un bug, producen **una tabla que circula y no se puede retirar**.*

### "El competidor lo configuro rápido, que lo importante es el mío"

**En qué se traduce:** una comparación donde una implementación tiene el pool dimensionado, la caché puesta y el
índice correcto, y la otra sigue el tutorial.

**Por qué falla:** porque **el conocimiento tácito no aparece en el diff**. La configuración que pones sin
pensarla en la plataforma que dominas es exactamente la que se te olvida en la otra, y la diferencia entre un
pool de cincuenta conexiones y el valor por omisión puede ser un orden de magnitud bajo carga. La medición sale
correcta, reproducible **y engañosa**: no mediste las plataformas, mediste tus once años.

**Qué se escribe en su lugar:** la **declaración de defendibilidad antes de medir** —qué se configuró en cada
lado, con qué valor y por qué, item por item, simétrica—, publicada con la tabla. Y los recursos **verificados en
el servidor**, no en el código: cuenta las conexiones activas en el motor durante la prueba.

**Dónde se rompe el paralelo — y es el giro que hace útil esta entrada:** en este curso el espantapájaros que te
sale sin querer **es el de .NET**, porque el ecosistema que dominas es el otro. El reflejo no es "quiero que gane
el mío": es "no sé qué le falta al que no conozco".

> 📚 Es el mismo defecto que la F21 encontró en el conjunto de entrenamiento: **el sesgo no está en la medición,
> está en cómo armaste lo que mides**.

**Desarrollado en:** [fase 23](23-el-duelo.md).

### "Esta salió mejor" — y las dos están dentro del ruido

**En qué se traduce:** un titular, una flecha verde, o un "ligeramente mejor" donde el dato honesto es **empate**.

**Por qué falla:** porque una mediana sin dispersión no es un resultado. Si dos medianas caen dentro de la
dispersión combinada, lo que la medición dice es que **no las distingue** — y eso es información, no un fracaso.
Al volumen de Cordillera, varias columnas del duelo empataron, y saberlo vale más que cualquier ganador: significa
que **la decisión dependía de otra cosa**, y conviene averiguar de qué.

**Qué se escribe en su lugar:** la palabra **empate**, con el número que la sostiene. Es la palabra que menos
aparece en los cursos de tecnología y la que más falta hace.

**Dónde se rompe el paralelo:** ninguno, y ahí está el problema: es idéntico en los dos mundos y se enseña en
ninguno.

**Desarrollado en:** [fase 23](23-el-duelo.md), y es la regla §2.4 de `formato-de-mediciones.md`.

---

## 🏛️ Los reflejos de arquitectura

Esta sección es propia de este curso y es la que importa más, porque estos reflejos **no producen
un bug: producen un proyecto de dos años que se cancela**. Ninguno es de lenguaje, todos son de
criterio, y el veredicto de la fase 24 los retoma uno por uno.

### "Reescribámoslo todo"

> 📚 Su versión de método —*"leo qué hace y lo reescribo limpio"*, donde el paso que falla es el de
> leer— está en la familia *datos y esquema*.

**En qué se traduce:** un documento de tres páginas, escrito el día once, proponiendo rehacer el
sistema en el stack que uno domina.

**Por qué falla:** porque la lógica de negocio de la editorial está en setecientos procedimientos
almacenados que nadie ha leído completos, y **reescribir el lenguaje no ahorra ni una hora de ese
trabajo**: añade una frontera más que cruzar. Las licencias ya están pagadas, y la persona que va a
sostener el resultado sabe C#.

**Dónde era correcto:** cuando el sistema es chico, cuando el dominio se entiende entero, o cuando
la plataforma está muerta de verdad y no solo vieja. Esas tres condiciones existen, y el curso no
finge lo contrario.

**La alternativa concreta**, que es lo que hace desmontable este reflejo: un plan de doce semanas donde
**cada paso es reversible en minutos y cada uno entrega algo** — API al lado sin usar, lectura al 5%,
lectura al 100%, escritura doble, conciliación, inversión de la fuente de verdad, y apagado del viejo
cuando la conciliación lleve cuatro semanas en cero. Si el proyecto se cancela en la semana 6, lo hecho
sirve igual. Ninguna presentación de *big bang* puede ofrecer eso.

**Desarrollado en:** [fase 10](10-strangler-fig.md), y revisado en la 24.

### "No toquemos nada, envolvámoslo"

**En qué se traduce:** una capa de servicios encima del sistema, sin cortar nada, esperando que el
problema se resuelva solo.

**Por qué falla:** es el fracaso simétrico del anterior y cuesta lo mismo, solo que tarda más en
cobrarse. Mientras noventa instalaciones tengan permiso de escritura sobre todo con la misma cadena
de conexión, **cualquier otra mejora es cosmética**.

**Dónde era correcto — y el curso tiene su caso, porque sin él esta entrada se lee como que envolver
siempre está mal:** **Convivir**, la plataforma Java que llegó con la adquisición de 2004. Funciona, nadie
del equipo actual la escribió, y nadie va a apagarla. La fase 10 la envuelve tras un adaptador delgado y la
trata por lo que es: **una dependencia externa**. Se le habla por un contrato, se traduce en la frontera, y
se le exige lo mismo que a cualquier servicio de un tercero — tiempo límite, reintentos y registro.
Tratarla como código propio pendiente de arreglar es cómo se pierden dos años.

Lo mismo vale para "el Fox" de Lima y para el proceso de reportes en 4.8 que la fase 11 deja corriendo
indefinidamente. **Tres veces el curso responde "se deja quieto", y las tres con su razón escrita.**

**Desarrollado en:** [fase 10](10-strangler-fig.md) y [fase 11](11-migrar-el-runtime.md), y revisado en la 24.

### "Primero refactorizamos, después migramos"

**Por qué falla:** porque refactorizar sin una red de pruebas de caracterización es reescribir a
ciegas, y montar la red es más barato **antes** de tocar nada. Primero la red, después el trapecio.

**Desarrollado en:** fase 08.

### "Si está viejo, está mal"

> 📚 Su versión concreta, a la altura del esquema y con las cuatro preguntas que la desarman, está en
> la familia *datos y esquema*: **"esto está mal hecho" — y la respuesta es "esto está fechado"**.

**Por qué falla:** porque cada decisión incómoda del esquema tiene un origen razonable y datable.
El campo de diez caracteres es del formato DBF, la tabla por año era cómo se evitaba que el motor
sufriera, el borrado por bandera es la semántica de FoxPro. Están **fechadas**, no mal hechas, y la
diferencia entre esas dos lecturas es la diferencia entre migrar y romper.

**Desarrollado en:** fase 07.

### "Esto se va a PaaS porque es lo moderno"

**Por qué falla:** porque un servicio gestionado se adopta con su costo al volumen real y con su
amarre medidos, no con su folleto. Cordillera ya hizo esto una vez, en 2020, y la factura quedó un
30% por encima del centro de datos que reemplazó.

**Desarrollado en:** fase 20, y es el corazón del veredicto de la 24.

---

## 🏁 Cierre del documento

Cincuenta y nueve reflejos en catorce familias, y **ninguno se inventó para rellenar**: cada uno nació de una
fase que se topó con él. Por eso hay familias con seis entradas y familias con dos, y **las que quedaron cortas se
quedan así** — igualarlas habría significado inventar reflejos, que es exactamente lo que este documento no
puede hacer si quiere seguir sirviendo para consultarlo con un síntoma en la mano.

La forma de usarlo después del curso es la que tenía desde la fase 00: **te pasó algo raro, lo buscas por el
síntoma, y la entrada te dice dónde está desarrollado**. Y si un reflejo te sigue pareciendo correcto después de
leer por qué falla, anótalo: puede que tengas razón en tu contexto, y ese es un dato mejor que estar de acuerdo.

> 🧭 **Y la propiedad que tienen los cincuenta y nueve en común, que es la conclusión del curso:** casi todos son
> **hábitos buenos de Java apoyados en una garantía que aquí no existe o existe de otra forma**. No eran errores
> — eran conocimiento con una dependencia que nadie te había dicho. Aprender esta plataforma no fue aprender a
> programar otra vez: fue **aprender dónde están las garantías**.
