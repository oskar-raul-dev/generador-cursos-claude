# 🔁 Fase 03 ⭐ — LINQ y evaluación diferida

> C# para desarrolladores Java senior · Fase 03 de 24 · Bloque A — el lenguaje y el runtime
> Depende de: 02 · Habilita: 04
> Estilo de esta fase: **nuevo** (.NET 10, C# 14)
> Proyecto que avanza: **el modelo de dominio**. Al terminar, `Cordillera.Domain` tiene sus consultas
> de catálogo y ventas compuestas, y una forma de **demostrar** cuántas veces se ejecutó cada una.

---

## 🎯 1. Propósito

Que no escribas nunca el bug más caro que produce este cruce. Es uno y es concreto: **recorrer dos
veces un `IEnumerable` y ejecutar el trabajo dos veces sin que nada te avise**. En Java el Stream
consumido te lanza `IllegalStateException` y te enteras en la primera prueba; aquí el segundo
recorrido funciona perfecto, devuelve lo correcto, y cobra el doble.

Esta fase es ⭐ por eso, y por lo que viene después: cuando en la fase 09 ese mismo `IEnumerable` sea
un `IQueryable` contra un `UNION ALL` de treinta tablas anuales, recorrerlo dos veces no cuesta el
doble de CPU — cuesta dos consultas.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Puedes decir, mirando una firma, **cuándo se ejecuta** el trabajo que describe una consulta.
- [ ] El modelo tiene las consultas de catálogo y de ventas compuestas y **probadas**, incluidas las
      de agrupación por sello y canal.
- [ ] Existe una forma de **demostrar con una prueba** cuántas veces se enumeró una fuente, y hay al
      menos una prueba que fallaría si alguien introdujera una segunda enumeración.
- [ ] Sabes qué operadores materializan, y cada materialización del modelo está **a propósito y
      comentada**.
- [ ] Sabes qué es un árbol de expresión, puedes imprimirlo, y sabes decir por qué `IQueryable` no es
      "`IEnumerable` con base de datos".
- [ ] La medición de la sección 6 está escrita con su comando, y la entrada quedó en `BENCHMARKS.md`.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **EF Core** → fase 09. Aquí `IQueryable` se explica y se inspecciona, pero **no se mide contra una
  base de datos**, porque no hay base de datos hasta la fase 07 y este curso no inventa
  infraestructura para una medición. Ver la nota de la sección 6: es una decisión declarada, no un
  olvido.
- **`IAsyncEnumerable`** → fase 06, con el reporte de 500.000 filas y el pico de memoria.
- **`async` en una consulta** → fase 05. Aquí todo es sincrónico.
- **El catálogo completo de operadores.** Entran los que el curso usa después y ni uno más: quedan
  fuera `Zip`, `SelectMany` anidado, `Aggregate` con semilla, y los operadores de conjunto más allá
  de `Distinct`. Si los necesitas, están en la documentación.
- **La sintaxis de consulta** (`from … where … select`). Se muestra una vez para que la reconozcas
  en código ajeno y el curso usa la sintaxis de método en todo lo demás, con su razón escrita.

---

## 🧠 4. Concepto mínimo

Un `IEnumerable<T>` no es una colección: **es la promesa de que alguien te va a poder dar elementos
uno por uno si se lo pides**. Eso es lo que hace `GetEnumerator()`, y es lo único que garantiza.

De ahí salen las dos propiedades que hay que tener presentes siempre:

**Los operadores no hacen nada.** `Where`, `Select`, `OrderBy` devuelven un objeto nuevo que
*recuerda* qué había que hacer. El trabajo ocurre cuando alguien enumera —un `foreach`, un
`ToList`, un `Count`—, y no antes. Componer una consulta de ocho operadores no cuesta
prácticamente nada; enumerarla cuesta todo.

**Enumerar es repetible, y nadie lo impide.** El mismo `IEnumerable` se puede recorrer dos, tres o
cien veces, y cada recorrido **vuelve a hacer el trabajo completo**. Si la fuente es una lista en
memoria, el segundo recorrido es baratísimo. Si la fuente es un archivo, se lee dos veces. Si es una
consulta a SQL Server, **son dos consultas**.

```csharp
// Esto es la fase entera en seis líneas.
IEnumerable<Edition> outOfStock = editions
    .Where(e => stock.QuantityFor(e.Id) == 0);     // no se ejecutó nada

Console.WriteLine($"agotadas: {outOfStock.Count()}");   // recorrido 1: consulta completa
foreach (Edition edition in outOfStock)                  // recorrido 2: consulta completa OTRA VEZ
{
    Console.WriteLine(edition.Isbn);
}
```

Dos recorridos, dos ejecuciones, cero advertencias. Y el resultado impreso es **correcto**, que es lo
que lo hace difícil de encontrar: no hay un síntoma, hay una factura.

> 🧠 **El modelo mental que hace encajar todo:** un `IEnumerable` es **una receta**, no un plato. Se
> puede copiar, pasar, guardar y componer con otras recetas sin cocinar nada. Cada vez que alguien
> tiene hambre —cada enumeración— se cocina de nuevo, con los ingredientes que haya **en ese
> momento**. De ahí sale la segunda sorpresa: si la fuente cambió entre los dos recorridos, los dos
> resultados son distintos y los dos son correctos.

Y la segunda mitad de la fase: hay otra interfaz que se parece y no es lo mismo.

**`IQueryable<T>` no describe *cómo* obtener los elementos: describe *qué* se quiere.** Sus
operadores no reciben delegados sino **árboles de expresión** — la lambda no se compila a código, se
compila a una estructura de datos que representa la lambda. Eso permite que un proveedor la lea, la
entienda y la traduzca a otra cosa: a SQL, por ejemplo.

```csharp
// La misma lambda, dos cosas completamente distintas según el tipo del parámetro.
Func<Edition, bool> code = e => e.ListPrice > new Money(50_000m);        // código ejecutable
Expression<Func<Edition, bool>> tree = e => e.ListPrice > new Money(50_000m);  // datos inspeccionables

Console.WriteLine(tree);
// e => (e.ListPrice > new Money(50000))  ← se puede leer, recorrer y traducir
```

Y de ahí sale el problema que define la fase 09 y que aquí solo se nombra: **un árbol de expresión
que el proveedor no sabe traducir tiene que resolverse de otra manera**, y "de otra manera" casi
siempre significa traer filas y filtrar en memoria. Sin advertencia, sin error, y con el mismo
resultado correcto.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El grande, y es el motivo de que esta fase sea ⭐: el `IEnumerable` recorrido dos veces.**

En Java esto no te puede pasar. Un `Stream` se consume una vez y el runtime te lo dice a la cara:

```java
// Java: la segunda operación terminal lanza IllegalStateException. Te enteras en la primera
// prueba que escribas, y el hábito se forma solo.
Stream<Edition> outOfStock = editions.stream().filter(e -> stock.quantityFor(e.id()) == 0);
long count = outOfStock.count();
outOfStock.forEach(System.out::println);   // IllegalStateException: stream has already been operated upon
```

Once años con esa red debajo forman un instinto: *"un pipeline se usa y se tira, y si me equivoco me
avisan"*. Aquí la mitad de ese instinto es correcta y la otra mitad es falsa — **se usa y se puede
volver a usar, y nadie avisa**:

```csharp
// ❌ C#: compila, funciona, imprime lo correcto, y hace el trabajo dos veces.
IEnumerable<Edition> outOfStock = editions.Where(e => stock.QuantityFor(e.Id) == 0);
int count = outOfStock.Count();
foreach (Edition e in outOfStock) { Console.WriteLine(e.Isbn); }
```

```csharp
// ✅ Dos opciones, y la elección es del caso, no del gusto.

// (a) Si necesitas los elementos más de una vez: materializa UNA vez, a propósito y comentado.
//     El `Count` sale de la lista, no de la fuente.
List<Edition> outOfStock = [.. editions.Where(e => stock.QuantityFor(e.Id) == 0)];
Console.WriteLine($"agotadas: {outOfStock.Count}");   // propiedad de la lista, no operador de LINQ
foreach (Edition e in outOfStock) { Console.WriteLine(e.Isbn); }

// (b) Si solo necesitas recorrerlos una vez: no materialices, y no preguntes el conteo antes.
int count = 0;
foreach (Edition e in editions.Where(e => stock.QuantityFor(e.Id) == 0))
{
    count++;
    Console.WriteLine(e.Isbn);
}
Console.WriteLine($"agotadas: {count}");
```

**Por qué falla el reflejo:** porque el lenguaje eliminó el error y con él la señal. La defensa no es
memorizar una regla: es aprender a leer un tipo. `IEnumerable<T>` en una variable local **significa
trabajo pendiente**, y si esa variable se usa dos veces, el trabajo se hace dos veces.

> 🧭 **La regla del curso:** un `IEnumerable` se enumera **una vez**. Si hace falta dos, se
> materializa una vez, con `[.. …]` o `ToList()`, **y el comentario dice por qué**.

**Segunda mitad: traducir Streams línea por línea.**

```java
// Java, y es idiomático
Map<String, Long> porSello = editions.stream()
    .collect(Collectors.groupingBy(Edition::imprint, Collectors.counting()));
```

```csharp
// ❌ La traducción mecánica. Funciona y es el doble de largo de lo necesario.
Dictionary<ImprintCode, long> porSello = editions
    .GroupBy(e => e.Imprint)
    .ToDictionary(g => g.Key, g => (long)g.Count());

// ✅ Lo idiomático en C#: el agrupamiento ya trae los elementos dentro, no hace falta
//    recolectarlos con una estrategia aparte.
Dictionary<ImprintCode, int> porSello = editions
    .GroupBy(e => e.Imprint)
    .ToDictionary(g => g.Key, g => g.Count());
```

**Dónde se rompe el paralelo:** los `Collectors` de Java existen porque un `Stream` **no** sabe
agrupar por sí mismo; `collect` es el punto de extensión que lo permite. En C#, `GroupBy` devuelve
`IEnumerable<IGrouping<TKey, TElement>>` y un `IGrouping` **es** una secuencia de sus elementos, así
que el "recolector" no hace falta. Buscar el equivalente de `Collectors` produce código que funciona
y que ningún equipo de .NET escribiría.

**Tercera mitad: materializar "por si acaso".**

```csharp
// ❌ El reflejo defensivo: convertir a lista en cada frontera "para estar seguro".
public List<Edition> GetActive() => [.. _editions.Where(e => e.IsActive)];
public List<Edition> ByImprint(ImprintCode code) => [.. GetActive().Where(e => e.Imprint == code)];
public List<Edition> Cheap() => [.. ByImprint(ImprintCode.Com).Where(e => e.ListPrice < new Money(40_000m))];
```

Tres listas intermedias para una consulta. Con 26.000 ediciones son tres asignaciones grandes y
tres recorridos completos; la versión diferida hace **un** recorrido y no asigna ninguna lista.

**Por qué falla el reflejo:** porque el miedo es al problema anterior —el doble recorrido— y la
materialización sí lo previene. Pero lo previene **en todas las fronteras a la vez**, que es como
pagar un seguro contra incendios en cada habitación. La regla sana: devolver `IEnumerable<T>` desde
las capas que componen, y materializar **una vez**, en el sitio que consume.

### 🩻 Esto sí funciona igual

Map, filter, reduce, y el hábito de componer transformaciones en vez de escribir bucles con
acumuladores. Todo eso se transfiere y además se escribe casi igual: `map`→`Select`,
`filter`→`Where`, `sorted`→`OrderBy`, `distinct`→`Distinct`, `anyMatch`→`Any`, `findFirst`→
`FirstOrDefault`, `limit`→`Take`, `skip`→`Skip`.

También se transfiere lo importante: que una consulta bien compuesta se lee mejor que el bucle
equivalente, y que el bucle equivalente es mejor cuando la consulta necesita cuatro operadores
anidados para expresar algo que un `for` dice en tres líneas. El criterio de cuándo parar es el
mismo que ya tienes.

Y la pereza en sí misma no es nueva: `Stream` de Java también es perezoso, y también ejecuta al
llegar la operación terminal. La diferencia no es el modelo, **es qué pasa cuando pides la operación
terminal dos veces**.

### 📖 Diccionario de traducción

| Java | C# / .NET | Dónde se rompe el paralelo |
|---|---|---|
| `Stream<T>` | `IEnumerable<T>` | Se puede recorrer **muchas veces**, y cada vez hace el trabajo entero. Nadie lanza nada |
| `.stream()` | nada: la colección ya lo es | No hay paso de conversión. Un `List<T>` **es** un `IEnumerable<T>` |
| operación terminal (`collect`, `count`) | operador que materializa (`ToList`, `Count`) | No hay dos categorías en el tipo: `Count()` y `Where()` se ven igual en la firma y una ejecuta |
| `IllegalStateException` al reusar | **nada** | Es la diferencia que esta fase existe para enseñar |
| `Collectors.groupingBy` | `GroupBy` | `IGrouping` ya es la secuencia de sus elementos: no hace falta recolector |
| `Collectors.toMap` | `ToDictionary` | Lanza con clave duplicada igual que Java, y el mensaje sí dice **cuál** |
| `Optional<T>` de `findFirst` | `FirstOrDefault()` → `T?` | Devuelve `default(T)`: para un `struct` eso es **cero**, no ausencia. Ojo con `Money` |
| `parallelStream()` | `AsParallel()` (PLINQ) | Existe, y el curso lo usa **una vez** en la fase 05 para mostrar que casi nunca es la respuesta |
| `stream().mapToInt().sum()` | `Sum(x => …)` | Sin variantes primitivas del pipeline: los genéricos son reificados y no hay boxing que evitar |
| `Iterable` con `Iterator` propio | `yield return` | El compilador genera la máquina de estados: escribir un iterador perezoso son dos líneas |
| — | `IQueryable<T>` | **No tiene equivalente.** Lo más cercano es Criteria API o JPQL tipado, y ninguno es el mismo mecanismo |

> ⚠️ **La fila de `FirstOrDefault` muerde con el modelo de la fase 01.** `editions.FirstOrDefault()`
> sobre una secuencia vacía devuelve `null` porque `Edition` es una clase; pero
> `prices.FirstOrDefault()` sobre una secuencia vacía de `Money` devuelve **`new Money(0)`**, que es
> un importe válido de cero pesos. No hay ausencia que detectar. Para tipos por valor, el par
> correcto es `Any()` primero, o `FirstOrDefault()` sobre una secuencia de `Money?`.

> 📝 **Nota de ecosistema.** LINQ llegó en 2007 con C# 3, ocho años antes de los Streams de Java, y
> trajo consigo tres cosas que el lenguaje no tenía: expresiones lambda, métodos de extensión y
> árboles de expresión. Los tres existen **por** LINQ, y eso explica su forma: `Where` no es un
> método de `IEnumerable`, es un método de extensión en `System.Linq.Enumerable`, y por eso puedes
> escribir tus propios operadores que se usen igual que los de la biblioteca. Lo verás en la fase 04.
>
> Y explica algo que vas a encontrar en código ajeno: la **sintaxis de consulta**, que es de la misma
> versión y hoy se usa poco.
>
> ```csharp
> // Sintaxis de consulta: reconócela, no la escribas. El curso usa la de método.
> var query = from e in editions
>             where e.ListPrice > new Money(50_000m)
>             group e by e.Imprint into byImprint
>             select new { byImprint.Key, Count = byImprint.Count() };
> ```
>
> El curso usa la sintaxis de método porque compone mejor con lo demás —un `Where` se agrega a una
> variable existente— y porque es la única que sirve para escribir operadores propios. La de consulta
> gana en exactamente un caso: los `join` múltiples con proyección, que en este curso no aparecen.

---

## 💻 5. Código mínimo con comentarios

### 5.1 Las consultas del catálogo, compuestas

```csharp
// src/modern/Cordillera.Domain/CatalogQueries.cs
namespace Cordillera.Domain;

/// <summary>
/// Las consultas del catálogo, como métodos de extensión sobre la secuencia. Se componen entre
/// ellas y **ninguna ejecuta nada**: cada una devuelve una receta.
/// </summary>
/// <remarks>
/// Son extensiones y no métodos de un repositorio porque en la fase 09 las mismas expresiones van
/// a tener que servir sobre `IQueryable` contra SQL Server. Escribirlas así desde ahora es lo que
/// va a permitir reusar la mitad; la otra mitad no se va a poder traducir, y esa es la lección de
/// la 09.
/// </remarks>
public static class CatalogQueries
{
    /// <summary>Las ediciones publicadas y no descatalogadas.</summary>
    public static IEnumerable<Edition> Available(this IEnumerable<Edition> editions) =>
        editions.Where(e => e.Status == TitleStatus.Published);

    public static IEnumerable<Edition> OfImprint(this IEnumerable<Edition> editions, ImprintCode imprint) =>
        editions.Where(e => e.Imprint == imprint);

    public static IEnumerable<Edition> PricedOver(this IEnumerable<Edition> editions, Money floor) =>
        editions.Where(e => e.ListPrice > floor);

    /// <summary>
    /// Las que hay que ir a buscar al archivo físico: deberían tener ISBN y no lo tienen. Es la
    /// consulta que la fase 02 hizo posible — antes de tipar la ausencia, esta pregunta no se
    /// podía escribir.
    /// </summary>
    public static IEnumerable<Edition> MissingIsbn(this IEnumerable<Edition> editions) =>
        editions.Where(e => e.IsbnStatus == IsbnStatus.Missing);
}
```

```csharp
// Y así se usan. La composición no cuesta nada; el foreach cuesta todo.
IEnumerable<Edition> query = catalog
    .Available()
    .OfImprint(ImprintCode.Com)
    .PricedOver(new Money(40_000m));

// Hasta aquí no se ha leído un solo elemento. Se puede pasar esta variable a otro método, guardarla
// en un campo o agregarle otro Where, y sigue sin costar nada.
```

**Detalles con intención**

- **Devuelven `IEnumerable<T>` y no `List<T>`**, a propósito: la composición es el punto. La
  materialización la decide quien consume, una vez.
- **Cada método es una sola expresión.** Cuando una consulta necesita un cuerpo con lógica, casi
  siempre es porque el nombre está mintiendo sobre lo que hace.
- **`Available()` compara con `TitleStatus.Published`** y no con una cadena, porque el modelo de la
  fase 01 ya resolvió eso. Es la primera vez que se cobra el trabajo de haber tipado bien.

### 5.2 Qué ejecuta y qué no: la tabla que hay que tener en la cabeza

```csharp
// Diferidos: devuelven una receta. Componer es gratis.
//   Where · Select · OrderBy · ThenBy · Skip · Take · GroupBy · Join · Distinct · Concat
//   Reverse · SelectMany · Cast · OfType · DefaultIfEmpty · Chunk
//
// Ejecutan al ser llamados: recorren la fuente AHORA.
//   ToList · ToArray · ToDictionary · ToHashSet · Count · Sum · Min · Max · Average
//   Any · All · Contains · First · FirstOrDefault · Last · Single · ElementAt · Aggregate
//
// Y los dos casos que sorprenden:
//   OrderBy es diferido, pero cuando se enumera necesita TODA la fuente antes de dar el primer
//   elemento. Es perezoso y no es incremental, y con 500.000 filas eso se nota en memoria (F06).
//
//   GroupBy es diferido, y también consume la fuente entera al primer elemento: para saber qué
//   grupos hay, hay que haber visto todo.
```

> 💡 **El truco para leerlo sin memorizar la lista:** si el tipo de retorno es `IEnumerable<T>`,
> `IOrderedEnumerable<T>` o `IEnumerable<IGrouping<K,T>>`, es diferido. Si devuelve un valor
> concreto —`int`, `List<T>`, `Edition`, `bool`— ejecutó. La firma lo dice; no hay que recordarlo.

### 5.3 Cómo se demuestra cuántas veces se ejecutó

Esta es la parte que convierte la regla en algo verificable, y es lo que se usa en el resto del
curso. El truco es una fuente que cuenta:

```csharp
// El generador perezoso más simple del curso: `yield return` hace que el compilador escriba la
// máquina de estados. Y el contador de la clausura dice cuántas veces alguien lo recorrió.
int enumerations = 0;

IEnumerable<Edition> CountingSource()
{
    enumerations++;   // se incrementa al EMPEZAR cada recorrido, no al crear la secuencia

    foreach (Edition edition in catalog)
    {
        yield return edition;
    }
}

IEnumerable<Edition> query = CountingSource().Available().OfImprint(ImprintCode.Com);

Console.WriteLine(enumerations);      // 0 — no se ha recorrido nada, ni siquiera una vez

int total = query.Count();
Console.WriteLine(enumerations);      // 1

foreach (Edition e in query) { }
Console.WriteLine(enumerations);      // 2 ← la factura
```

**Prueba de fuego**

```csharp
// Esto es lo que hay que ejecutar y mirar, porque la línea 3 es contraintuitiva.
int calls = 0;
IEnumerable<int> numbers = Enumerable.Range(1, 5).Select(n => { calls++; return n * 2; });

Console.WriteLine(calls);                    // 0  — Select no hizo nada
Console.WriteLine(numbers.First());          // 2
Console.WriteLine(calls);                    // 1  — solo el primer elemento: la pereza es real
Console.WriteLine(numbers.Count());          // 5
Console.WriteLine(calls);                    // 6  — 1 + 5: volvió a proyectar todo
```

Y la mentira que te va a contar la salida si miras el lugar equivocado: **`Count()` sobre una
`List<T>` no recorre nada** —usa la propiedad— así que si pruebas esto con una lista en vez de con
un generador, el contador no se mueve y vas a concluir que el problema no existe. Es exactamente lo
que pasa cuando alguien "comprueba" en una prueba unitaria con datos en memoria algo que en
producción va contra una base de datos.

### 5.4 `IQueryable`, lo justo para saber que es otra cosa

```csharp
using System.Linq.Expressions;

// La misma consulta, escrita igual, sobre dos interfaces distintas.
IQueryable<Edition> queryable = catalog.AsQueryable();

IQueryable<Edition> filtered = queryable.Where(e => e.ListPrice > new Money(50_000m));

// Y aquí está la diferencia: se puede leer lo que se pidió, porque es una estructura de datos.
Console.WriteLine(filtered.Expression);
// System.Collections.Generic.List`1[...].Where(e => (e.ListPrice > new Money(50000)))

// El tipo del argumento de Where es lo que cambia todo:
//   IEnumerable<T>.Where(Func<T, bool>)                 ← código compilado, se ejecuta
//   IQueryable<T>.Where(Expression<Func<T, bool>>)      ← árbol de datos, se traduce
```

**El patrón a memorizar**

> `IEnumerable` dice **cómo**; `IQueryable` dice **qué**. Por eso un `IQueryable` puede convertirse
> en SQL y un `IEnumerable` no: el primero es una descripción y el segundo ya es una
> implementación. Y por eso el momento en que un `IQueryable` se degrada a `IEnumerable` —una
> llamada a `AsEnumerable()`, un `foreach`, o un operador que el proveedor no supo traducir— es el
> momento en que el resto del filtrado **pasa a hacerse en tu proceso, con las filas ya traídas**.

> 💸 **Deuda declarada: un `IQueryable` que se filtra en memoria.**
>
> ```csharp
> // 💸 F09 — `Isbn.TryParse` no se puede traducir a SQL: es un método propio, y ningún proveedor
> // sabe qué hace. Al llegar aquí, el proveedor trae las filas y filtra en el proceso. Hoy la
> // fuente es una lista en memoria y no se nota nada; en la fase 09 la fuente son 26.000 filas de
> // EDICION y la diferencia es medible. Lo correcto es filtrar por una expresión traducible y
> // validar el ISBN después, sobre lo que ya se trajo.
> IEnumerable<Edition> WithValidIsbn(IQueryable<Edition> editions) =>
>     editions.Where(e => Isbn.TryParse(e.IsbnRaw, out _));
> ```
>
> **Se paga en la fase 09**, midiendo **las filas que viajaron de más** — que es la unidad correcta
> para esta deuda, y no los milisegundos. La factura será
> `git diff fase-03 fase-09 -- src/modern/Cordillera.Domain/CatalogQueries.cs`.
>
> **Por qué se deja:** porque hoy no hay proveedor que la traduzca ni base de datos contra la que
> medirla, y escribir la solución completa sin poder demostrar el problema convertiría la lección en
> doctrina. En la fase 09 el problema se ve con un número.

---

## 📏 6. Medición

> 📝 **Una decisión declarada sobre esta medición.** El alcance de la fase pide comparar la misma
> consulta con `IEnumerable`, con `IQueryable` y con SQL directo, y **para las dos últimas hace falta
> una base de datos que no existe hasta la fase 07**. Este curso no inventa infraestructura para
> medir. Así que la medición de esta fase mide **lo que aquí sí se puede sostener con datos** —el
> costo del doble recorrido y el de materializar por si acaso, sobre el catálogo en memoria— y la
> comparación de `IQueryable` contra SQL directo queda declarada como **parte de la medición de la
> fase 09**, que la ejecuta con el mismo formato. Es el mismo mecanismo que usa el bloque de
> escritorio entre la F14 y la F18, y está declarado en los dos sitios.

**Hipótesis:** enumerar dos veces una consulta compuesta cuesta el doble de trabajo, y materializar
en cada frontera cuesta más asignaciones que una materialización única al final — pero **con el
catálogo en memoria las tres opciones quedan en el mismo orden de magnitud**, y esa es justamente la
razón por la que este bug llega a producción.

**Condiciones:** SDK 10.0.401 · Release · Windows 11 · el catálogo vivo de Cordillera, **11.000
títulos con 26.000 ediciones**, en memoria · 100 repeticiones con 10 de calentamiento descartadas ·
arnés propio, con el contador de enumeraciones de la sección 5.3 activado para verificar el número de
recorridos de cada variante.

**Competidores:** cuatro formas de escribir el mismo reporte, todas correctas, todas defendibles en
una revisión por alguien distinto:

- **Diferida, un recorrido** — lo que el curso enseña.
- **Diferida, dos recorridos** — el `Count()` antes del `foreach`. Es el bug.
- **Materializada al final** — un `ToList()` en el sitio que consume.
- **Materializada en cada frontera** — el reflejo defensivo, tres listas intermedias.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 03
```

**Resultado:** ⏳ pendiente de ejecución en tu máquina.

| Variante | Recorridos | Mediana | p95 | Asignado | Pico |
|---|---|---|---|---|---|
| Diferida, un recorrido | 1 | ⏳ | ⏳ | ⏳ | ⏳ |
| Diferida, dos recorridos | 2 | ⏳ | ⏳ | ⏳ | ⏳ |
| Materializada al final | 1 | ⏳ | ⏳ | ⏳ | ⏳ |
| Materializada en cada frontera | 1 | ⏳ | ⏳ | ⏳ | ⏳ |

La columna **Recorridos** no es una expectativa: es un hecho que el contador verifica, y si tu
ejecución da otra cosa, hay un recorrido escondido que encontrar.

> ⚖️ **Veredicto** *(expectativa, todavía sin ejecutar — `formato-de-mediciones.md` §2.6)*. Se espera
> que el doble recorrido duplique el tiempo y que materializar en cada frontera domine las
> asignaciones. Y se espera que **las cuatro queden en milisegundos**, o sea: sobre datos en memoria
> ninguna de estas diferencias justifica por sí sola una revisión de código.
>
> **El umbral que tu ejecución tiene que determinar, y es el que importa:** cuánto cuesta *un*
> recorrido del catálogo. Ese número es el que hay que multiplicar cuando la fuente deje de ser una
> lista: en la fase 09 el mismo recorrido será una consulta a un `UNION ALL` de treinta tablas, y el
> factor entre las dos columnas de arriba **deja de ser 2× en CPU y se convierte en 2× en consultas**.
> Guarda el número: la fase 09 lo cita.

---

## 🧱 7. Miniproyecto — el reporte de ventas por sello y canal, con su recorrido demostrado

**El encargo**

Gustavo te llama: *"Necesito ventas por sello y por canal del trimestre, y necesito que cuadre con lo
que me manda contabilidad, que no cuadra nunca. Lo que tengo hoy es una hoja que armó Nohora y que
tarda un rato largo en abrir. Y una cosa más: la última vez que pedí un reporte así, el que lo hizo
me dijo que «la consulta es pesada». Quiero saber qué tan pesada, y quiero saber si es pesada una vez
o es pesada tres veces."*

**Por qué duele**

Porque el reporte tiene tres totales que se calculan sobre el mismo conjunto —total por sello, total
por canal y participación de cada sello en cada canal— y la forma natural de escribirlo recorre la
fuente tres veces sin que se vea. Y porque Gustavo hizo, sin saberlo, **la pregunta central de esta
fase**, así que el entregable tiene que poder responderla con un número y no con una opinión.

**Datos de entrada**

Las ventas del trimestre, como salen del volcado que hoy alimenta la hoja de Nohora. **Los nombres
de las columnas son los del esquema** (`VENTAS_2026`), porque de ahí vienen.

```text
FECVENTA;CODEDIT;CODCLIEN;CODALMA;CODDISTR;CANTIDAD;VLRUNIT;VLRTOTAL;MONEDA;CANALVTA;TIPOVENTA
20260112;ED00001234;CL00000341;BOG;;12;68000.00;816000.00;COP;L;I
20260115;ED00001235;CL00000019;MEX;DISMEX;300;95000.00;28500000.00;MXN;C;I
20260118;ED00001236;CL00000019;MEX;DISMEX;-45;42000.00;-1890000.00;MXN;C;D
20260120;ED00001237;CL00000502;BOG;;3;55000.00;165000.00;COP;W;O
20260122;ED00001238;CL00000771;LIM;;7;38000.00;266000.00;PEN;L;I
20260125;ED00009999;CL00000341;BOG;;5;38000.00;190000.00;COP;L;I
20260131;ED00001240;CL00000088;MEX;DISMEX;150;68000.00;10200000.00;MXN;P;O
20260203;ED00001241;CL00000341;BOG;;9;110000.00;980000.00;COP;L;I
```

Lo que tiene de traicionero, y todo sale del negocio:

- **Tres `TIPOVENTA` distintos** conviviendo: `I` sell-in (venta al canal), `O` sell-out (venta al
  lector) y `D` devolución. **Sumarlos juntos da un número que no significa nada**, y es
  exactamente el número que hoy no cuadra con contabilidad.
- **Cantidades negativas** en las devoluciones, que son correctas y no hay que filtrar.
- **Tres monedas.** `Money` todavía no lleva moneda —es la deuda 💸 de la fase 01— así que el
  reporte **no puede sumar importes de monedas distintas**, y tiene que decir cómo lo resuelve.
- **`ED00009999`** no existe en el catálogo: es una de las 1.900 filas huérfanas. Aparece en ventas
  y no tiene sello, así que no cabe en ninguna fila del reporte por sello.
- **La última fila** tiene `VLRTOTAL` que no es `CANTIDAD * VLRUNIT`: 9 × 110.000 son 990.000, no
  980.000. Hay un descuento que la tabla no guarda. **No se corrige**: se reporta.

**Criterios de aceptación**

1. El reporte sale por consola y en CSV, con ventas por sello, por canal y el cruce de los dos,
   **separando sell-in, sell-out y devolución en columnas distintas**. Un total que los mezcle es un
   criterio no cumplido.
2. Una prueba demuestra que **la fuente se enumera exactamente una vez** para producir el reporte
   completo, y esa prueba **falla** si alguien agrega un `Count()` o un `Any()` en medio.
3. Las filas huérfanas y las de `VLRTOTAL` inconsistente aparecen en una sección aparte con su
   conteo. Ninguna fila se descarta en silencio.
4. El reporte declara qué hace con las tres monedas, y lo que haga **no es sumarlas**.
5. Toda materialización del código tiene un comentario que dice por qué está. Si no hay ninguna,
   también vale, y entonces el comentario está en el commit.
6. **Medición de cierre:** el tiempo y las asignaciones de producir el reporte completo sobre el
   volcado del trimestre, más **el número de enumeraciones**, medidos con el arnés. Van en el mensaje
   del tag `mini-03`.

**Restricciones de estilo y alcance**

Código nuevo. LINQ **sí**, y es el punto de la fase — pero cada operador que materializa se justifica.
Sin `IAsyncEnumerable` —fase 06— y sin paquetes.

El instrumento del criterio 2 lo escribes tú, y tiene que servir para el resto del curso: un envoltorio
reutilizable que cuente enumeraciones sobre cualquier `IEnumerable<T>`, no un contador pegado a este
reporte. La sección 5.3 te muestra la idea en seis líneas con una clausura; **eso no es lo que se pide**.

**La trampa**

Vas a escribir el reporte con tres agrupaciones —una por sello, una por canal, una cruzada— y va a
quedar limpio, legible y correcto. Y va a recorrer la fuente tres veces.

Vas a intentar arreglarlo con un `ToList()` al principio, y el contador va a decir 1, y vas a pensar
que ya está.

No está: acabas de mover el problema. Con este volcado la lista cabe en memoria sin dolor, pero
**el reporte histórico de la fase 06 son 500.000 filas** y ahí esa lista es el problema que esa fase
viene a resolver. La pregunta que tienes que contestar es la incómoda: *¿se puede producir un reporte
con tres agrupaciones distintas en un solo recorrido y sin materializar la fuente?* Se puede, y la
respuesta no es LINQ — es lo que LINQ hace por debajo.

Cuando llegues ahí, escribe en tres líneas qué elegiste y qué sacrificaste: hay dos caminos
defendibles y uno de los dos te deja un código bastante menos bonito.

<details><summary>Pista 1 — el enfoque</summary>

Separa tres cosas que la versión natural mezcla: **de dónde vienen las filas**, **cómo se acumulan**
y **cómo se presentan**. En cuanto acumular sea explícito, la pregunta de cuántos recorridos hacen
falta se responde sola.

Y para el instrumento del criterio 2: lo que envuelve una secuencia y cuenta recorridos es un tipo
que implementa `IEnumerable<T>` y delega. Son unas veinte líneas.

</details>

<details><summary>Pista 2 — la herramienta</summary>

Para un solo recorrido con varias agrupaciones, mira `Aggregate` con un acumulador propio, y también
`yield return` para escribir tu propio operador:
`https://learn.microsoft.com/dotnet/csharp/iterators`

Y lee con atención la diferencia entre `IGrouping<K,T>` y `ILookup<K,T>` —uno es diferido y el otro
está materializado— porque decide cuál de los dos caminos eliges:
`https://learn.microsoft.com/dotnet/api/system.linq.ilookup-2`

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```csharp
// El instrumento reutilizable. Cuenta cada vez que alguien empieza a recorrer.
public sealed class CountingEnumerable<T>(IEnumerable<T> source) : IEnumerable<T>
{
    public int Enumerations { get; private set; }
    public IEnumerator<T> GetEnumerator();
    System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator();
}

// La clave del reporte cruzado, y la razón de que sea un record struct.
internal readonly record struct ReportKey(ImprintCode? Imprint, SalesChannel Channel);

// El acumulador: lo que se lleva de una fila a la siguiente en un solo recorrido.
internal sealed class SalesTotals
{
    public void Add(SalesRow row);
    public IReadOnlyDictionary<ReportKey, SalesFigures> ByImprintAndChannel { get; }
    public int Orphans { get; }
    public int InconsistentTotals { get; }
}

internal readonly record struct SalesFigures(int SellIn, int SellOut, int Returns);
```

</details>

**Cómo se entrega**

```powershell
dotnet test src\Cordillera.slnx -c Release
dotnet run -c Release --project src\fases\03-linq-y-evaluacion-diferida\mini -- datos\ventas-2026-t1.csv
```

```bash
git tag -a mini-03 -m "Mini F3: ventas por sello y canal en 1 recorrido · <N> filas en <X> ms, <Y> MB asignados, enumeraciones=1"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Agrega a `CatalogQueries` la consulta de las ediciones descatalogadas de un sello, componiéndola
   con las que ya existen. Demuestra con el contador que componerla no enumera nada.
2. Escribe la consulta que cuenta ediciones por formato (`Td`, `Tb`, `Eb`, `Au`) con `GroupBy` y
   `ToDictionary`, y explica en una línea por qué `ToDictionary` ejecuta.
3. Reemplaza un `foreach` con acumulador del miniproyecto de la fase 02 por la consulta LINQ
   equivalente, y di cuál de las dos versiones dejarías en el curso y por qué.
4. Demuestra con el contador de la sección 5.3 que `OrderBy` consume la fuente completa antes de
   devolver el primer elemento.
5. Escribe una consulta con `Take(5)` sobre el catálogo y demuestra que solo se proyectaron cinco
   elementos, no 26.000.
6. Encuentra en el modelo un sitio donde `FirstOrDefault()` sobre un tipo por valor podría
   confundirse con ausencia, y arréglalo. Es la advertencia del 📖.

**🟡 Intermedio (7–14)**

7. Escribe tu propio operador `WhereAvailable` como método de extensión con `yield return`, y
   demuestra que es perezoso con el contador. Compáralo con la versión que usa `Where`.
8. Escribe la consulta que cruza ediciones con existencias por almacén usando `Join`, y después la
   misma con `GroupJoin`. Di en qué se diferencia el resultado y cuál sirve para el reporte.
9. Convierte una consulta de la sección 5.1 a `IQueryable`, imprime su `Expression`, y señala en la
   salida dónde aparece cada operador que compusiste.
10. Escribe una consulta que use un método propio en el predicado, conviértela a `IQueryable` e
    imprime el árbol. Explica qué tendría que hacer un proveedor con ese nodo.
11. Mide con el arnés la diferencia entre `editions.Count()` y `editionsList.Count` sobre 26.000
    elementos. Explica el resultado y di qué implica para el criterio 2 del miniproyecto.
12. Escribe una consulta que devuelva resultados **distintos** en dos enumeraciones consecutivas sin
    que la fuente cambie de tamaño, y explica el mecanismo.
13. Usa `Chunk(1000)` para procesar el catálogo por lotes y demuestra que sigue siendo un solo
    recorrido. Anota para qué va a servir en la fase 17.
14. Reescribe la consulta del reporte con sintaxis de consulta (`from … group … into …`), compárala
    con la de método, y di en qué caso concreto de este curso la preferirías.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Te entregan un servicio donde un reporte tarda exactamente el doble de lo
    esperado. La consulta es correcta y los datos son los esperados. Encuentra el doble recorrido
    con el contador, y escribe la prueba que habría evitado el bug.
16. **Diagnóstico.** Un método devuelve `IEnumerable<Edition>` construido con `yield return` a partir
    de un archivo abierto en un `using`. El primer recorrido funciona y el segundo lanza. Explica qué
    pasó y cuáles son las dos formas correctas de diseñar esa firma.
17. **Medición.** Ejecuta la medición de la sección 6 completa, con las cuatro variantes y el
    contador activo. Publica la tabla con su veredicto y **el costo de un recorrido**, que es el
    número que la fase 09 va a citar.
18. **Medición.** Compara `GroupBy` + `ToDictionary` contra un `Dictionary` acumulado en un solo
    `foreach`, sobre las ventas del trimestre. Reporta tiempo y asignaciones, y di a partir de
    cuántas filas la diferencia justifica escribir el bucle.
19. Escribe un operador `CountingWhere` que cuente cuántas veces se evaluó el predicado, y úsalo para
    demostrar, sobre una consulta de cuatro operadores compuestos, en qué orden se evalúan los
    predicados. El resultado sorprende: explícalo.
20. **Decisión — ¿se migra, se envuelve o se deja quieto?** Nohora tiene una macro de Excel de 600
    líneas que produce hoy este reporte y que usan tres sellos. Tu reporte hace lo mismo mejor.
    Decide qué pasa con la macro, y sostén la decisión con el costo de las otras dos — incluido el
    costo de que Nohora no pueda corregir un registro a las siete de la tarde.
21. **Decisión — ¿se migra, se envuelve o se deja quieto?** Las consultas de `CatalogQueries` están
    escritas sobre `IEnumerable`. En la fase 09 la mitad va a tener que funcionar sobre `IQueryable`
    contra SQL Server. Decide hoy: se reescriben todas como `Expression`, se duplican en dos juegos,
    o se deja así y se resuelve allá. Di qué cuesta cada opción.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Escribe una consulta LINQ correcta cuya enumeración tenga un efecto secundario
    observable, y demuestra que enumerarla dos veces produce un estado inconsistente en el dominio.
    Después arréglala **sin** materializar.
23. **Adversarial.** Consigue que una consulta diferida capture una variable que cambia entre la
    composición y la enumeración, de forma que el resultado sea correcto según el código y
    equivocado según el negocio. Es el bug de captura de clausura, y en el Bloque D aparece de verdad.
24. **Diseño y medición.** Produce el reporte del miniproyecto con **tres agrupaciones en un solo
    recorrido y sin materializar la fuente**, y mídelo contra la versión de tres recorridos y contra
    la versión materializada. Determina el umbral de filas a partir del cual la versión de un
    recorrido justifica su complejidad.
25. **Defiende una decisión.** Duván lee tu reporte y dice: *"esto antes era un `foreach` con tres
    contadores y lo entendía cualquiera; ahora hay cuatro métodos de extensión y un acumulador"*.
    Tiene parte de razón. Responde por escrito, media página, diciendo qué ganaste, qué perdiste, y
    en qué caso concreto le darías la razón y volverías al `foreach`.

**🔥 Opcionales**

- Implementa `ILookup<K,T>` a mano para el reporte y compáralo con `GroupBy`. Anota cuándo un lookup
  materializado es la herramienta correcta.
- Investiga `AsParallel()` sobre el reporte del trimestre, mídelo, y **guarda el resultado**: la fase
  05 lo va a usar para mostrar por qué el paralelismo de datos casi nunca es la respuesta en trabajo
  de entrada/salida.
- Lee la implementación de `Enumerable.Where` en el repositorio de `dotnet/runtime` y encuentra la
  optimización que hace cuando la fuente ya es un arreglo. Anota qué implica para tus mediciones.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://learn.microsoft.com/dotnet/csharp/linq/` — LINQ desde el principio, con la distinción
  entre ejecución diferida e inmediata.
- `https://learn.microsoft.com/dotnet/csharp/linq/standard-query-operators/` — qué hace cada
  operador **y si es diferido o no**. Es la tabla de la sección 5.2, en su fuente.
- `https://learn.microsoft.com/dotnet/csharp/iterators` — `yield return` y la máquina de estados que
  genera el compilador. Es la lectura del miniproyecto.
- `https://learn.microsoft.com/dotnet/api/system.linq.iqueryable-1` — `IQueryable` y su `Expression`.
- `https://learn.microsoft.com/dotnet/csharp/advanced-topics/expression-trees/` — árboles de
  expresión: qué son, cómo se recorren y cómo se construyen. Media página basta para esta fase; la
  fase 09 vuelve.
- `https://learn.microsoft.com/dotnet/api/system.linq.ilookup-2` — `ILookup` frente a `IGrouping`.

**Especificación y propuestas del lenguaje**

- `https://github.com/dotnet/csharplang/blob/main/spec/expressions.md#anonymous-function-expressions`
  — por qué la misma lambda puede compilarse a un delegado o a un árbol de expresión según el tipo
  de destino. Es el mecanismo que hace posible `IQueryable`, y se lee en diez minutos.

**Libros / artículos**

- Los artículos de Jon Skeet sobre reimplementar LINQ operador por operador ("Edulinq") son la mejor
  explicación que existe de la pereza en `IEnumerable`. El título y la URL pueden haber cambiado;
  búscalo por autor y tema, y verifica antes de citarlo.

> ⚠️ Verifica las URLs. Y la advertencia propia de esta fase: **gran parte del material sobre LINQ
> que vas a encontrar habla de LINQ to SQL o de Entity Framework 6**, que son anteriores a EF Core y
> traducen distinto. Lo que digan sobre pereza sigue valiendo; lo que digan sobre qué se traduce a
> SQL, no.

**Orden de lectura sugerido:** antes de escribir, la página de LINQ y la tabla de operadores —hay que
saber qué ejecuta—. Durante el miniproyecto, la de iteradores. Después, la de árboles de expresión:
es la única de las tres que se entiende mejor cuando ya te peleaste con un predicado que no se pudo
traducir, y eso pasa en la fase 09.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Las consultas del catálogo están compuestas, probadas, y hay una forma de **demostrar** cuántas veces
se ejecutan — que es lo que convierte la regla de esta fase en algo que una prueba sostiene en vez de
algo que alguien recuerda. Queda una deuda 💸 declarada, el `IQueryable` que filtra en memoria, y
queda un número pendiente de ejecutar que la fase 09 va a citar: **cuánto cuesta un recorrido del
catálogo**.

La fase 04 es el paso natural por dos razones que salen de aquí. La primera: el miniproyecto te hizo
escribir un método de extensión y un iterador con `yield return`, y los dos son piezas de un tema más
grande —delegados, extensiones y genéricos— que es donde C# pide **menos** ceremonia que Java. La
segunda: prometí en la fase 01 y en la 02 el número de lo que cuesta usar excepciones para el flujo
normal, y la fase 04 es donde llega, junto con `IDisposable` y el ciclo de vida de una prueba. Es la
fase de la ceremonia que sobra y la que falta.

> **La señal de que quedó bien:** *"Leo una firma que devuelve `IEnumerable<T>` y sé que no ha pasado
> nada todavía; y si la variable se usa dos veces, sé cuánto va a costar antes de ejecutarlo."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el miniproyecto
> corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-03 -m "F3 cerrada:
> - CatalogQueries compuestas, diferidas y probadas
> - CountingEnumerable: el número de recorridos es verificable con una prueba
> - reporte por sello y canal en un solo recorrido, con sell-in, sell-out y devolución separados
> - deuda 💸 del IQueryable filtrado en memoria declarada, con cobro en F09
> - medición de las cuatro variantes escrita, con el costo de un recorrido pendiente de ejecutar"
> ```
>
> Los commits llevan su prefijo (`fase 03: …`), los ejercicios el suyo, y el miniproyecto el tag
> `mini-03` con sus números **incluido el de enumeraciones**, que en esta fase es parte de la
> medición y no un detalle. La convención está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
>
> Esta fase **no cobra deuda y planta una**, la tercera con destino en la fase 09. Cuando llegues
> allá vas a cobrar tres seguidas —dos `!` de la F02 y este `IQueryable`— y las tres desaparecen en
> el mismo archivo: el borde 🧬. Que tres deudas de tres fases distintas se paguen en un solo sitio
> es el argumento de por qué el borde va concentrado.

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura.*

- **`INSTINTOS.md`** — tres entradas en una familia nueva, *ejecución diferida*: el `IEnumerable`
  recorrido dos veces —que es **la entrada más importante del documento hasta ahora** y debería
  quedar primera en su familia—, los Streams traducidos línea por línea, y materializar por si
  acaso. La primera necesita el contraste explícito con el `IllegalStateException` de Java: sin eso,
  el lector no entiende por qué nunca le había pasado.
- **`BENCHMARKS.md`** — entrada ⏳ *F03 · Cuatro formas de escribir el mismo reporte*. Y una nota en
  el índice: la comparación `IQueryable` contra SQL directo **está declarada como parte de la
  medición de la F09**, con la misma metodología. Si la 09 no la recoge, esta fase queda debiendo un
  número que su propio alcance prometía.
- **Deuda 💸 registrada:** `IQueryable` filtrado en memoria, cobro en F09, y la unidad de cobro son
  **filas que viajaron de más**, no milisegundos. Conviene que el libro de deudas de la propuesta
  §7.1 diga la unidad, porque es lo que hace la factura convincente.
- **Decisión declarada que sube a la propuesta:** la medición de esta fase **no mide `IQueryable`
  contra SQL** y la delega a la F09. Es el segundo acoplamiento declarado del curso, después del de
  la F14 con la F18, y debería figurar en §8 de la propuesta junto al otro.
- **Tipo nuevo para el congelamiento:** `CountingEnumerable<T>` nace en el miniproyecto y lo van a
  usar la 06, la 09 y la 17 para el mismo propósito. Hay que decidir si vive en
  `Cordillera.Bench` —donde encaja, porque es un instrumento de medición— o en un proyecto de
  utilidades de prueba. Se resuelve al escribir la 06.
- **Para la fase 05:** el ejercicio 🔥 de `AsParallel()` deja un número guardado que la 05 necesita
  para su argumento sobre `Parallel.ForEach` en trabajo de entrada/salida.
- **Para la fase 06:** la trampa del miniproyecto —el `ToList()` que "arregla" el contador y mueve el
  problema a la memoria— es literalmente el planteamiento de la fase 06. Conviene que la 06 la cite
  y la cierre.
