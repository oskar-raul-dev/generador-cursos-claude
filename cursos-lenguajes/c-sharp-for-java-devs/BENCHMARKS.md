# 📏 BENCHMARKS
## C# para desarrolladores Java senior

Todas las mediciones del curso, en un solo sitio y con el mismo formato, para que se puedan
comparar entre sí y para que ninguna se cite sin sus condiciones.

Este archivo **nace con la fase 00 y sin un solo número**. Los números los produces tú, en tu
máquina, con el arnés — y cuando los pegues aquí, esta se vuelve tu tabla y no la del autor.

> 🧭 **La regla que sostiene el curso: si no lo puedes medir con el arnés, no lo afirmas.** Ni
> "más rápido", ni "más liviano", ni "arranca antes", ni "sale más barato". Cuando la medición no
> existe, se escribe la frase sin el comparativo.

---

## 🔧 El arnés

Vive en `src/modern/Cordillera.Bench` (la biblioteca) y `src/modern/Cordillera.Bench.Cli` (la
herramienta), los dos escritos en la fase 00. Es el mismo para las veinticinco fases: las
posteriores lo **amplían** —colecciones por generación en la 06, latencia de red en la 18, costo
mensual en la 20— y ninguna lo sustituye.

Qué hace, y nada más: ejecuta la operación N veces, **descarta el calentamiento** porque las
primeras iteraciones miden al JIT y no al código, reporta **mediana y p95** y nunca el promedio,
reporta **asignaciones y pico de memoria administrada** además del tiempo, y **declara el
entorno** en su propia salida.

```bash
dotnet run -c Release --project src/modern/Cordillera.Bench.Cli -- --fase 06 --iterations 100
```

**Sobre BenchmarkDotNet:** existe, es excelente y es el estándar del ecosistema. El curso lo usa
**donde la pregunta es de microbenchmark** —una asignación, un parseo, una comparación de
estructuras—, porque ahí hacer las cosas a mano es equivocarse. Para el trabajo completo —un
reporte de 500.000 filas, el arranque en frío de un contenedor, una pantalla desde Lima— el arnés
propio es más honesto porque mide el trabajo y no el fragmento. Cada medición dice cuál usó.

---

## ⚖️ Las siete reglas que hacen creíble un número

1. **El competidor es defendible.** Se compara contra una implementación que alguien defendería
   en una revisión de código: con su pool de conexiones, su índice puesto y su configuración de
   producción. Medir contra un espantapájaros es la forma más común de mentir con datos ciertos.
2. **Primero SQL, después .NET.** Cuando el trabajo toca la base, el plan de consulta se mide
   **antes** que el código. Con treinta tablas anuales unidas por `UNION ALL`, el primer orden de
   magnitud no está en el lenguaje, y optimizar C# encima de una consulta mala es teatro.
3. **El dato es realista.** Los volúmenes salen de Cordillera: 500.000 filas en el reporte
   histórico, 1.900 movimientos huérfanos, 400 manuscritos al mes, 90 instalaciones, nueve husos.
   Un benchmark sobre mil filas no decide nada y lo sabe todo el mundo.
4. **Se publica el empate.** Cuando dos opciones quedan dentro del ruido, el veredicto dice
   *empate* y lo justifica con la dispersión. Es la palabra que menos aparece en los cursos de
   tecnología y la que más falta hace.
5. **Lo que no se puede ejecutar se declara.** Si la medición es de costo o de un servicio que no
   se levanta en local, dice **qué precio publicado usó, de qué fecha y en qué región**, y se
   marca *no ejecutado*. La región por defecto del curso es **East US 2**.
6. **Una cifra de costo va con precio publicado, fuente, fecha y región, o no va.** Es la regla 5
   llevada a su forma fuerte, y la agrega la **F20**, que es la única entrada del curso cuyo
   veredicto está en pesos. Un costo sin esos cuatro datos no es un dato: es un recuerdo, y no se
   puede reverificar seis meses después cuando alguien lo cuestione en una reunión de presupuesto.
   Aplica igual a las cifras de costo que aparecen dentro de otras entradas (F15, F16, F17, F19).
7. **Una comparación entre plataformas o productos publica su declaración de defendibilidad**, o no
   se publica. Qué se configuró en cada lado, con qué valor y por qué, item por item y simétrico —y
   las asimetrías que no se pueden igualar, declaradas—. La agrega la **F23**, y es la forma fuerte
   de la regla 1: sin ella, *"el competidor es defendible"* es una afirmación del autor sobre sí
   mismo; con ella, es algo que un lector puede criticar línea por línea.

> 📝 **Correspondencia con `prompts/formato-de-mediciones.md`, para que nadie busque en vano:** las
> reglas 1 a 5 de aquí son §2.1 a §2.5 allí; **la 6 es §2.7 y la 7 es §2.8**. El salto no es un
> error: §2.6 es la convención ⏳, que **veinticinco documentos publicados citan por ese número**, y
> renumerarla habría roto todas esas citas. El orden de los números refleja cuándo se descubrió cada
> regla, no su importancia.

> 🧭 **Tres de las siete nacieron de una necesidad concreta y esa procedencia es material:** la 5 de
> no poder ejecutar servicios de nube, la 6 de que la F20 tiene su veredicto en pesos, y la 7 de que
> la F23 mide contra el ecosistema en que el lector es experto. Una regla que nace de un problema se
> respeta; una que nace de una lista de buenas prácticas, no.

---

## 📖 Cómo se lee una entrada

Cada medición tiene esta forma, más dos campos que solo existen en este archivo: **la fase que la
produjo** y **la fecha en que se ejecutó**.

````markdown
### F06 · Reporte histórico: lista materializada contra IAsyncEnumerable

**Fase:** 06 · **Ejecutada:** 2026-10-04
**Hipótesis:** materializar 500.000 filas en una lista cuesta más de 1 GB de pico, y el flujo con
`IAsyncEnumerable` lo mantiene constante.
**Condiciones:** SDK 10.0.401 · Release · Windows 11 · 16 GB · 500.000 filas · 100 repeticiones,
10 de calentamiento descartadas · arnés propio
**Competidores:** lista materializada (lo que escribe el que llega de Java) contra flujo

| Opción | Mediana | p95 | Asignado | Pico |
|---|---|---|---|---|
| `List<T>` materializada | … | … | … | … |
| `IAsyncEnumerable` | … | … | … | … |

> ⚖️ **Veredicto.** … y **a partir de qué umbral cambia la respuesta**.
````

**El umbral del veredicto es obligatorio.** *"Dapper gana"* no sirve; *"Dapper gana en lotes
grandes y la ventaja desaparece por debajo de dos mil filas, donde mantener dos formas de acceso a
datos pesa más"* sí. Un veredicto sin umbral es una preferencia.

### ⏳ Las filas que todavía no se ejecutaron

Una medición se escribe completa —hipótesis, condiciones, competidores, el comando exacto y la
tabla con sus filas nombradas— y sus celdas de resultado llevan **⏳** hasta que alguien la corra.
El veredicto de una entrada ⏳ separa dos cosas: **lo que la hipótesis espera**, marcado como
expectativa, y **el umbral cuyo valor la ejecución tiene que determinar**.

> ⚠️ **Una fila ⏳ no se cita.** Ni en otra fase, ni en el veredicto final, ni como argumento de
> una decisión. Existe como encargo, no como dato. Es preferible una tabla honestamente vacía a un
> número inventado que veinticinco fases van a arrastrar.

### ⚙️ El arnés cambió en la fase 06, y eso afecta a las entradas anteriores

Hasta la fase 05 el arnés medía **tiempo**: mediana, p95 y dispersión. En la **fase 06** se cobra la
deuda de la fase 00 y pasa a medir también asignaciones, pico de memoria administrada y **colecciones
por generación**.

Consecuencia práctica: las columnas de memoria de las entradas **F01 a F05** se llenaron con un
instrumento más pobre —o a mano— y conviene reejecutarlas con el arnés completo. Si al hacerlo algún
veredicto cambia, **la entrada vieja no se borra**: se marca 🪦 con su puntero, según la regla de abajo.
Ese historial es material didáctico: es la prueba de que el instrumento también se revisa.

### 🔜 Y las columnas que todavía no se pueden ejecutar

Hay una convención más, y es distinta de ⏳. **⏳ significa "escrita y sin ejecutar"**: el comando existe y
alguien la puede correr hoy. **🔜 significa "el competidor no existe todavía"** — la medición no se puede
tomar porque lo que hay que medir aún no está construido, y la fase que lo construirá está nombrada.

Aparece **una sola vez en el curso**: la cuarta columna de la tabla del veredicto del escritorio (F14), que
compara cuatro opciones de interfaz y la web nace catorce fases después. Esa columna la completa la **F18**
con la metodología que la F14 congeló, y **se completa aquí**, en la entrada consolidada — no editando el
documento publicado de la F14. Es el mecanismo que evita el único caso del curso en que una fase tendría que
reescribir el material de otra (`prompts/propuesta-fases-y-alcance.md` §8).

> ⚠️ Una celda 🔜 **tampoco se cita**, por la misma razón que una ⏳: no hay dato. Y tiene una obligación
> adicional — **nombrar la fase que la va a llenar**. Un 🔜 sin destino es un hueco, no un encargo.

> ✅ **Y ya se llenó.** La **F18** completó la cuarta columna con la metodología congelada, y las celdas que
> decían 🔜 dicen ⏳: pasaron de *"no se puede medir"* a *"se puede medir y falta correrla"*. Quedó registrada
> la única adaptación que hubo que hacer —construir el **formulario de existencias** también en el modelo de
> render ganador, porque la F18 construye la recepción de manuscritos y el módulo medido tenía que seguir
> siendo el mismo—. Rellenar la columna con los números de otra pantalla habría sido romper la comparación
> por comodidad, y es exactamente lo que la metodología congelada existe para impedir.

### 🪦 Cuando una medición contradice a otra

Pasa, y es sano. La entrada vieja **no se borra**: se marca 🪦, se le pone un puntero a la nueva y
una línea sobre qué cambió —otra versión del SDK, otro volumen, un índice que faltaba—. El
historial de las veces que el curso se equivocó midiendo es material didáctico, no vergüenza.

---

## 🗂️ Índice de mediciones

Una fila por fase, para llenarse al cerrar cada una. La columna **Estado** dice ⏳ si la medición
está escrita pero no ejecutada, y la fecha si ya lo está.

| Fase | Qué mide | Estado |
|---|---|---|
| 00 | Costo del calentamiento: las primeras iteraciones miden al JIT, no al código | ⏳ |
| 01 | `Isbn` como `class`, `record class` y `record struct` sobre un millón de ediciones | ⏳ |
| 02 | Advertencias que produce activar el contexto anulable, y cuántas eran bugs | ⏳ |
| 03 | Cuatro formas de escribir el mismo reporte, y el costo de un recorrido | ⏳ |
| 04 | Costo de lanzar una excepción en bucle contra devolver un resultado | ⏳ |
| 05 | Throughput y número de hilos con `.Result` contra `await`, con 200 peticiones · **dato transversal: la concurrencia del codo** | ⏳ |
| 06 | Reporte de 500.000 filas: cuatro versiones, con barrido de filas | ⏳ |
| 07 | El `UNION ALL` de treinta tablas: plan, lecturas lógicas y tiempo — **línea base del Bloque B**, la entrada más citada del curso | ⏳ |
| 08 | Cobertura de línea contra cobertura de rama, y tiempo de la suite por estrategia de aislamiento | ⏳ |
| 09 | Cinco mapeadores sobre el mismo esquema — **y la comparación `IQueryable` contra SQL directo que la F03 le delegó: acoplamiento cumplido** | ⏳ |
| 10 | Latencia del camino nuevo contra el acceso directo, y divergencia medida · **dato transversal: las divergencias por día dimensionan el outbox de la F17** | ⏳ |
| 11 | Cuatro compilaciones del mismo módulo: 4.8 y los tres modos de publish de .NET 10 | ⏳ |
| 12 | El mismo formulario en 4.8 y en .NET 10, con y sin modo virtual · **dato transversal: el despliegue a 90 equipos** | ⏳ |
| 13 | WinForms contra WPF, con virtualización sana y rota · **y el conteo de pruebas sin interfaz, que no es una comparación de rendimiento** | ⏳ |
| 14 | **La tabla del veredicto del escritorio**: 4 opciones × 5 criterios. Tres columnas ⏳ y la cuarta 🔜, que la **F18** completa aquí | ⏳ + 🔜 |
| 15 | Minimal APIs contra controladores — **y contra el CSV de anoche, que es el competidor real** | ⏳ |
| 16 | El costo de la autenticación, con y sin caché de claves · **el anti-patrón gana, y publicarlo es el punto** | ⏳ |
| 17 | La liquidación completa contra el statu quo, y la cola en tabla contra la mensajería gestionada · **con columnas cualitativas** | ⏳ |
| 18 | Latencia de interacción desde Bogotá, Ciudad de México y Lima, y memoria por circuito · **y completa la cuarta columna del veredicto de la F14** | ⏳ |
| 19 | Sobrecosto de la instrumentación, y **el reparto de los cuatro segundos a los dos lados del borde 🧬** · *no compara competidores: reparte un total* | ⏳ |
| 20 | Tamaño y arranque de cinco imágenes, **la factura mensual por forma de alojamiento**, y las tres deudas en pesos | ⏳ |
| 21 | **La curva de devolución** —el dato que decide todo lo demás— y ML.NET contra ONNX, las dos contra Gustavo | ⏳ |
| 22 | Texto completo contra vectorial de SQL Server contra Azure AI Search, y **qué cuesta negarse a responder** | ⏳ |
| 23 | El duelo: CatalogAPI en ASP.NET Core contra Spring Boot, **cinco configuraciones** · *los empates son el resultado, no busques un ganador* | ⏳ |
| 24 | No produce medición propia: **consolida las veinticuatro** y verifica las reglas de este archivo | ✅ |

---

## 📐 F00 · El costo del calentamiento

**Fase:** 00 · **Ejecutada:** ⏳ pendiente

**Hipótesis:** incluir las primeras iteraciones en la muestra infla la mediana de una operación
corta lo suficiente para invertir el resultado de una comparación entre dos alternativas parejas.

**Condiciones:** SDK 10.0.401 · compilación Release · Windows 11 · 120 repeticiones, y la misma
operación medida con 0 y con 10 de calentamiento descartadas · arnés propio y BenchmarkDotNet
sobre la misma operación.

**Competidores:** la misma operación medida de tres formas —sin descartar nada, descartando diez,
y con BenchmarkDotNet, que es el estándar del ecosistema y por tanto el competidor defendible—.

**El comando:**

```bash
dotnet run -c Release --project src/modern/Cordillera.Bench.Cli -- --fase 00
```

| Opción | Mediana | p95 | Dispersión | Asignado |
|---|---|---|---|---|
| Sin descartar calentamiento | ⏳ | ⏳ | ⏳ | ⏳ |
| Descartando 10 iteraciones | ⏳ | ⏳ | ⏳ | ⏳ |
| BenchmarkDotNet | ⏳ | ⏳ | ⏳ | ⏳ |

> ⚖️ **Veredicto** *(expectativa, todavía sin ejecutar)*. Se espera que la mediana sin descarte
> quede por encima y con una dispersión notablemente mayor, y que el arnés con descarte quede
> cerca de BenchmarkDotNet — si no queda cerca, el arnés está mal y hay que arreglarlo antes de
> seguir, que es justamente para lo que sirve esta medición.
>
> **El umbral que la ejecución tiene que determinar:** a partir de qué duración de operación deja
> de importar el calentamiento. Por debajo de ese tiempo, ninguna comparación del curso se
> publica sin descarte.

---

## 📐 F01 · `Isbn` como `class`, `record class` y `record struct`

**Fase:** 01 · **Ejecutada:** ⏳ pendiente

**Hipótesis:** implementar `Isbn` como `class` cuesta una asignación en el montón por instancia, y
sobre el catálogo completo esa diferencia es visible en pico de memoria y en tiempo de comparación;
como `readonly record struct` no asigna nada por sí mismo.

**Condiciones:** SDK 10.0.401 · Release · Windows 11 · **un millón de `Isbn`** (26.000 ediciones
reales repetidas hasta el volumen donde la diferencia se mide sin ruido) · 100 repeticiones, 10 de
calentamiento descartadas · arnés propio para la carga, BenchmarkDotNet para la comparación
individual.

**Competidores:** las tres implementaciones del mismo tipo, las tres correctas — `class` con
`Equals`/`GetHashCode` a mano (lo que produce la traducción desde Java), `record class`, y
`readonly record struct` (lo que el curso eligió).

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 01
```

| Implementación | Mediana (carga de 1M) | p95 | Asignado | Pico | Comparación (ns) |
|---|---|---|---|---|---|
| `class` con `Equals` a mano | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| `record class` | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| `readonly record struct` | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |

> ⚖️ **Veredicto** *(expectativa, sin ejecutar)*. Se esperan del orden de 24 bytes por instancia más
> la cadena en las dos versiones de referencia, y nada en el `struct` — aunque **la cadena de dentro
> sigue en el montón**: el `struct` no es gratis, es *menos*. Si `class` y `record class` quedan
> dentro del ruido, el veredicto dice **empate**, y entonces la decisión entre esas dos no es de
> rendimiento sino de cuántas líneas se mantienen.
>
> **Dos umbrales por determinar:** (1) a partir de cuántas instancias vivas la diferencia de pico
> pasa de anecdótica a decisión; (2) **a partir de qué tamaño del `struct` la copia cuesta más que la
> indirección** — lo citan la F06 y la F09.

---

## 📐 F02 · Advertencias del contexto anulable, clasificadas

**Fase:** 02 · **Ejecutada:** ⏳ pendiente

> 📝 **El instrumento de esta medición no es el arnés, es el compilador** (permitido y declarado,
> `formato-de-mediciones.md` §1). Lo que se cuenta son advertencias, clasificaciones y minutos.

**Hipótesis:** activar el contexto anulable sobre código que no lo tenía produce muchas advertencias
y **la mayoría no son bugs**: son anotaciones que faltan. La proporción de bugs reales es baja, y
ahí está todo el valor del ejercicio.

**Condiciones:** SDK 10.0.401 · el mismo código con `<Nullable>disable</Nullable>` y con `enable` ·
`Cordillera.Domain` más el importador de la F01 reescritos sin anotaciones, unas 900 líneas.

**Competidores:** no hay dos implementaciones: hay **una clasificación en tres categorías fijadas
antes de contar** — bug real, anotación faltante, ruido. El rigor está en que la haga alguien que no
escribió el código.

| Categoría | Advertencias | % del total | Minutos hasta cero |
|---|---|---|---|
| Bug real | ⏳ | ⏳ | ⏳ |
| Anotación faltante | ⏳ | ⏳ | ⏳ |
| Ruido (atributo o `!` comentado) | ⏳ | ⏳ | ⏳ |
| **Total** | ⏳ | 100% | ⏳ |

> ⚖️ **Veredicto** *(expectativa, sin ejecutar)*. Lo valioso no es el total: es que **cada bug real
> de esa columna era un `NullReferenceException` esperando turno**, y que encontrarlos costó una
> tarde de anotaciones.
>
> **El umbral por determinar:** a partir de qué proporción de ruido conviene activarlo por proyecto
> entero en vez de módulo por módulo. Ese número decide en la F09 y en la F11 si las 250.000 líneas
> de SIGE se anotan — y la respuesta esperada es que no.

---

## 📐 F03 · Cuatro formas de escribir el mismo reporte

**Fase:** 03 · **Ejecutada:** ⏳ pendiente

> 📝 **Acoplamiento declarado con la F09.** El alcance de la F03 pedía comparar `IEnumerable`,
> `IQueryable` y SQL directo, y **no hay base de datos hasta la F07**. Esta entrada mide lo que se
> puede sostener con datos en memoria; la comparación de `IQueryable` contra SQL directo es parte de
> la medición de la **F09**, con la misma metodología. Declarado en los dos sitios.

**Hipótesis:** enumerar dos veces una consulta compuesta cuesta el doble de trabajo, y materializar
en cada frontera cuesta más asignaciones que una materialización única — pero con el catálogo en
memoria las cuatro variantes quedan en el mismo orden de magnitud, y **por eso este bug llega a
producción**.

**Condiciones:** SDK 10.0.401 · Release · Windows 11 · 11.000 títulos con 26.000 ediciones en
memoria · 100 repeticiones, 10 de calentamiento descartadas · arnés propio con el contador de
enumeraciones activo.

**Competidores:** cuatro formas correctas de escribir el mismo reporte — diferida con un recorrido,
diferida con dos, materializada al final, y materializada en cada frontera.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 03
```

| Variante | Recorridos | Mediana | p95 | Asignado | Pico |
|---|---|---|---|---|---|
| Diferida, un recorrido | 1 | ⏳ | ⏳ | ⏳ | ⏳ |
| Diferida, dos recorridos | 2 | ⏳ | ⏳ | ⏳ | ⏳ |
| Materializada al final | 1 | ⏳ | ⏳ | ⏳ | ⏳ |
| Materializada en cada frontera | 1 | ⏳ | ⏳ | ⏳ | ⏳ |

La columna **Recorridos** no es expectativa: la verifica el contador. Si tu ejecución da otra cosa,
hay un recorrido escondido que encontrar.

> ⚖️ **Veredicto** *(expectativa, sin ejecutar)*. Se espera que el doble recorrido duplique el tiempo
> y que materializar en cada frontera domine las asignaciones — y que **las cuatro queden en
> milisegundos**, o sea que sobre datos en memoria ninguna diferencia justifica por sí sola una
> revisión de código.
>
> **El umbral por determinar, y es el que importa:** cuánto cuesta *un* recorrido del catálogo. En la
> F09 ese recorrido será una consulta a un `UNION ALL` de treinta tablas, y el factor entre las dos
> primeras filas **deja de ser 2× en CPU para ser 2× en consultas**.

---

## 📐 F04 · Excepción contra resultado, por proporción de fallos

**Fase:** 04 · **Ejecutada:** ⏳ pendiente

> 📝 **Instrumento: BenchmarkDotNet**, no el arnés propio. Esto es un microbenchmark de libro —una
> invocación, un millón de veces— y ahí hacer las cosas a mano es equivocarse
> (`formato-de-mediciones.md` §1).

**Hipótesis:** lanzar una excepción cuesta órdenes de magnitud más que devolver un resultado, así que
usar excepciones para un fallo que **es parte del trabajo** —el 5% de líneas sucias de un archivo de
40.000— es una decisión medible y no una preferencia de estilo.

**Condiciones:** SDK 10.0.401 · Release · Windows 11 · un millón de invocaciones de la misma operación,
con 0%, 5% y 100% de fallos · 100 repeticiones, 10 de calentamiento descartadas.

**Competidores:** excepción (`Isbn.Parse`), patrón `TryParse` (`bool` + `out`) y un tipo de resultado
con el valor o el motivo. Los tres son defendibles: el primero es lo que hace el framework para el
formulario del editor, el segundo lo que hace para el archivo, y el tercero lo que escribe quien viene
de un lenguaje funcional.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 04 --benchmarkdotnet
```

| Forma | 0% de fallos | 5% de fallos | 100% de fallos | Asignado (5%) |
|---|---|---|---|---|
| Excepción | ⏳ | ⏳ | ⏳ | ⏳ |
| `TryParse` (`bool` + `out`) | ⏳ | ⏳ | ⏳ | ⏳ |
| Tipo de resultado | ⏳ | ⏳ | ⏳ | ⏳ |

> ⚖️ **Veredicto** *(expectativa, sin ejecutar)*. Se espera **empate** con 0% de fallos —y hay que
> publicarlo así— y una separación grande ya en el 5%, porque lo caro de una excepción es capturar la
> pila, no el `throw`.
>
> **El umbral por determinar:** **a partir de qué proporción de fallos la excepción deja de ser
> aceptable**. Por debajo, un tipo de resultado es complejidad sin retorno; por encima, la excepción se
> paga en cada archivo que se carga. Lo citan la F09 y la F17.
>
> ⚠️ La columna del 100% **no es un caso realista**: está para que se vea la pendiente. Ninguna decisión
> del curso se toma con ella.

---

## 📐 F05 · `.Result` contra `await` bajo carga

**Fase:** 05 · **Ejecutada:** ⏳ pendiente

**Hipótesis:** el mismo servicio con `.Result` y con `await` atiende la misma carga con un número de
hilos radicalmente distinto, y a partir de cierta concurrencia la versión bloqueante **no se degrada
suavemente: se cae de un codo**, con la CPU casi libre.

**Condiciones:** SDK 10.0.401 · Release · Windows 11 · endpoint que consulta el catálogo con 80 ms de
latencia simulada —el tiempo que la F07 va a medir de verdad contra el `UNION ALL`— · barrido de
concurrencia en 10, 50, 100, 200 y 400 · 30 s por punto, calentamiento descartado · arnés propio, que
para trabajo completo es lo correcto.

**Competidores:** `await` de punta a punta; `.Result` en el borde (un solo `.Result` en el controlador,
que es el caso realista); `.Result` en el medio; y `Parallel.ForEach` con `.Wait()` sobre trabajo de
entrada y salida.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 05 --sweep 10,50,100,200,400
```

| Implementación | Concurrencia | Throughput (req/s) | Latencia p95 | Hilos del proceso | CPU % |
|---|---|---|---|---|---|
| `await` de punta a punta | 200 | ⏳ | ⏳ | ⏳ | ⏳ |
| `.Result` en el borde | 200 | ⏳ | ⏳ | ⏳ | ⏳ |
| `.Result` en el medio | 200 | ⏳ | ⏳ | ⏳ | ⏳ |
| `Parallel.ForEach` + `.Wait()` | 200 | ⏳ | ⏳ | ⏳ | ⏳ |

| Concurrencia | `await`: hilos / p95 | `.Result`: hilos / p95 |
|---|---|---|
| 10 | ⏳ | ⏳ |
| 50 | ⏳ | ⏳ |
| 100 | ⏳ | ⏳ |
| 200 | ⏳ | ⏳ |
| 400 | ⏳ | ⏳ |

> ⚖️ **Veredicto** *(expectativa, sin ejecutar)*. Se espera **empate con 10 y 50** —y publicarlo explica
> por qué este bug sobrevive a las pruebas de carga tibias— y, más arriba, un número de hilos que crece
> con la concurrencia mientras la CPU se queda baja. **La CPU baja con latencia alta es la firma del
> problema**; si la CPU estuviera al 90%, el diagnóstico sería otro.
>
> **El umbral por determinar, y es el número que el lector se lleva al trabajo:** **la concurrencia del
> codo**. Comparado con el tráfico real de Cordillera, decide si un `.Result` heredado es una bomba o
> una fealdad tolerable — las dos respuestas son posibles. Lo citan la F09, la F15 y la F20.

---

## 📐 F06 · Reporte histórico: cuatro versiones, con barrido

**Fase:** 06 · **Ejecutada:** ⏳ pendiente

**Hipótesis:** materializar las 500.000 filas produce un pico proporcional al archivo y al menos una
colección de generación 2; el flujo mantiene el pico constante. **En tiempo las dos van a estar
cerca**, y ahí está la lección: el argumento del flujo no es la velocidad.

**Condiciones:** SDK 10.0.401 · Release · Windows 11 · 500.000 filas —el volumen real de
`VENTAS_1997`…`VENTAS_2026`— con barrido en 10.000, 100.000 y 500.000 · 100 repeticiones, 10 de
calentamiento descartadas · **arnés con la medición de memoria que esta fase agregó**.

**Competidores:** `List` + `Split`; `List` + parseo sobre `Span`; flujo + `Split`; flujo + `Span`. Las
cuatro son correctas, y las dos intermedias existen para poder **atribuir** la mejora a una causa y no
a las dos juntas.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 06 --rows 10000,100000,500000
```

| Versión | Mediana | p95 | Asignado | Pico | GC 0/1/2 |
|---|---|---|---|---|---|
| `List` + `Split` | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| `List` + `Span` | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Flujo + `Split` | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Flujo + `Span` | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |

| Filas | `List` + `Split`: pico / GC2 | Flujo + `Span`: pico / GC2 |
|---|---|---|
| 10.000 | ⏳ | ⏳ |
| 100.000 | ⏳ | ⏳ |
| 500.000 | ⏳ | ⏳ |

> ⚖️ **Veredicto** *(expectativa, sin ejecutar)*. Se espera pico lineal en la versión materializada y
> plano en el flujo; colecciones de generación 2 solo en las materializadas; y en tiempo, las cuatro
> mucho más cerca de lo que el entusiasmo sugiere — posiblemente **empatadas con 10.000 filas**.
>
> **Dos umbrales por determinar:** (1) a partir de cuántas filas la versión materializada produce su
> primera colección de generación 2 — el punto donde el flujo deja de ser preferencia y pasa a ser la
> respuesta; (2) **cuánto aporta `Span` por separado**, y si aporta poco, la conclusión honesta es que
> el parseo sobre `Span` **no valía la complejidad** en este caso.
>
> ⚠️ **Estos números no dicen nada sobre `SP_VENTAS_HIST`.** Cuando el origen sea la base de datos, el
> primer orden de magnitud está en el plan del `UNION ALL` de treinta tablas. Eso lo mide la F07, y en
> ese orden.

---

## 📐 F07 · Línea base del reporte histórico

**Fase:** 07 · **Ejecutada:** ⏳ pendiente · **🧭 Línea base del Bloque B: la citan la F09, la F11, la
F20 y la F24.**

**Hipótesis:** el costo del reporte histórico está dominado por el `UNION ALL` de treinta tablas y por
la compilación de un plan nuevo en cada llamada — **no** por cómo .NET recorre el resultado. Optimizar
el lado de C# encima de esta consulta no puede cambiar el orden de magnitud.

**Condiciones:** SQL Server 2025 en contenedor (`MSSQL_PID=EnterpriseDeveloper`) sobre WSL 2 · la base
del generador con semilla `19970417`, **500.000 filas repartidas en treinta tablas** · SDK 10.0.401 y
.NET Framework 4.8 para `Sige.DataAccess` · 20 repeticiones, 3 de calentamiento descartadas · plan con
`SET STATISTICS IO, TIME ON`; lado .NET con el arnés.

**Competidores:** no hay dos implementaciones compitiendo — hay **cuatro capas del mismo trabajo**,
medidas por separado para poder atribuir el costo a su causa: el plan con caché limpia y caliente, la
misma consulta con texto **estático parametrizado**, el método `GetSalesHistory` con su `DataSet`, y el
mismo procedimiento leído con `SqlDataReader`.

**Los comandos:**

```sql
DBCC FREEPROCCACHE;
SET STATISTICS IO, TIME ON;
EXEC SP_VENTAS_HIST @ANIODESDE = 1997, @ANIOHASTA = 2026, @CODSELLO = NULL;
```

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 07
```

| Capa medida | Tiempo | Lecturas lógicas | Escaneos | Asignado | Pico |
|---|---|---|---|---|---|
| Plan de `SP_VENTAS_HIST`, caché limpia | ⏳ | ⏳ | ⏳ | — | — |
| Plan de `SP_VENTAS_HIST`, caché caliente | ⏳ | ⏳ | ⏳ | — | — |
| La misma consulta, texto estático parametrizado | ⏳ | ⏳ | ⏳ | — | — |
| `GetSalesHistory` completo (`DataSet`) | ⏳ | — | — | ⏳ | ⏳ |
| El mismo procedimiento con `SqlDataReader` | ⏳ | — | — | ⏳ | ⏳ |

> ⚖️ **Veredicto** *(expectativa, sin ejecutar)*. Se espera que el tiempo del motor domine el total por
> un margen amplio, y que la diferencia entre caché limpia y caliente sea grande en la versión
> concatenada y pequeña en la estática — lo que atribuiría una parte concreta del costo a la
> concatenación y no al volumen. El `DataSet` debería pesar mucho más en memoria que el lector por
> flujo, **con una diferencia de tiempo bastante menor que la de memoria**.
>
> **Tres umbrales por determinar, y gobiernan el bloque:** (1) **qué fracción del total es el motor** —
> si pasa del 80%, cualquier trabajo en el lado .NET antes de arreglar la consulta es teatro;
> (2) **cuánto cuesta la concatenación por sí sola**; (3) **cuánto pesa el `DataSet`**, que es lo que la
> F09 necesita para decidir entre Dapper, EF Core y dejarlo quieto.
>
> 📝 **No es una condena del sistema, es un punto de partida.** Si en la F20 resulta que el reporte se
> pide una vez al mes y arreglarlo cuesta tres semanas, subir el tiempo de espera puede ser la respuesta
> correcta — que es lo que alguien hizo en 2022, y tuvo razón.

---

## 📐 F08 · Cobertura útil y costo del aislamiento

**Fase:** 08 · **Ejecutada:** ⏳ pendiente

> 📝 **Dos hipótesis en una entrada**, porque las dos salen de la misma ejecución de la suite.

**Hipótesis A:** la cobertura de línea sobre un procedimiento con cursores y ramas anidadas
**sobreestima groseramente** la protección real; la de rama es mucho menor, y la diferencia son
justamente las decisiones que cambian un número que alguien factura.

**Hipótesis B:** un contenedor por clase de prueba cuesta lo suficiente para cambiar cómo se organiza la
suite; el contenedor compartido con datos disjuntos es el compromiso correcto, con un límite medible a
partir del cual el aislamiento vuelve a ganar.

**Condiciones:** SQL Server 2025 en contenedor sobre WSL 2 · base del generador, semilla `19970417` ·
SDK 10.0.401, xUnit v3 4.0.0, Testcontainers 4.15.0 · la suite completa, ~40 pruebas sobre los cuatro
módulos · 10 ejecuciones, 2 de calentamiento descartadas · cobertura con `coverlet`, tiempos con el
arnés.

**Competidores (B):** contenedor por clase (aislamiento total); compartido con datos disjuntos (el
compromiso que la fase propone); y compartido con transacción por prueba y rollback — que es la
traducción obvia de `@Transactional` **y no funciona con este esquema**.

**Los comandos:**

```powershell
dotnet test src\modern\Sige.Characterization.Tests -c Release --collect:"XPlat Code Coverage"
reportgenerator -reports:**\coverage.cobertura.xml -targetdir:cobertura -reporttypes:Html
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 08 --strategy container-per-class,shared-disjoint,shared-transaction
```

**A · Cobertura sobre `SP_LIQREGAL_CALC`**

| Métrica | Con 2 pruebas | Con la suite completa | Ramas que deciden un pago |
|---|---|---|---|
| Cobertura de línea | ⏳ | ⏳ | — |
| Cobertura de rama | ⏳ | ⏳ | ⏳ |

**B · Tiempo de la suite por estrategia de aislamiento**

| Estrategia | Mediana | p95 | Aislamiento | Falla con este esquema |
|---|---|---|---|---|
| Contenedor por clase | ⏳ | ⏳ | total | no |
| Compartido, datos disjuntos | ⏳ | ⏳ | por convención | si dos pruebas eligen el mismo rango |
| Compartido, transacción por prueba | ⏳ | ⏳ | total en teoría | **sí** — los procedimientos abren transacciones propias |

> ⚖️ **Veredicto** *(expectativa, sin ejecutar)*. Se espera que la cobertura de línea con dos pruebas ya
> esté alta —el camino feliz atraviesa casi todo el archivo— y que la de rama se quede muy por debajo
> incluso con la suite completa. Y que el contenedor por clase sea varias veces más lento, con una
> diferencia que crece con el número de **clases** y no de pruebas.
>
> **Dos umbrales por determinar:** (1) **cuántas ramas decisorias quedan sin cubrir cuando el porcentaje
> de línea ya se ve bien** — el argumento contra la cobertura como métrica de gestión; (2) **a partir de
> cuántas clases el contenedor por clase deja de ser viable**, que decide la organización de la suite
> para las fases 09 a 11.
>
> 📝 **La tercera fila de B se publica aunque falle**, y ahí está su valor: es la traducción obvia de
> `@Transactional`, no funciona, y saber por qué evita que alguien lo intente durante dos días.

---

## 📐 F09 · Cinco mapeadores y el predicado no traducible

**Fase:** 09 · **Ejecutada:** ⏳ pendiente · **Se lee contra la línea base de la F07.**

> 📝 **Cierra el acoplamiento declarado con la F03** (propuesta §8.1): la tabla B es la comparación de
> `IQueryable` contra SQL directo que esa fase no pudo hacer por no tener base de datos.

**Hipótesis:** sobre este esquema la diferencia entre ADO.NET, Dapper y EF Core **sin seguimiento** es
menor de lo que el folclore sugiere; con seguimiento, EF Core paga un costo medible en asignaciones que
crece con las filas; y el `DataSet` heredado es el más caro en memoria por un margen amplio. **La variable
que decide no es el mapeador: es qué tan bien está escrita la consulta.**

**Condiciones:** SQL Server 2025 en contenedor sobre WSL 2 · base del generador, semilla `19970417` · SDK
10.0.401, EF Core 10.0.12, Dapper 2.1.66 · tres volúmenes: 1 fila, ~6.600 (catálogo de un sello) y ~30.000
(un año de ventas) · 50 repeticiones, 5 de calentamiento descartadas · plan con `SET STATISTICS IO, TIME
ON` **antes**; lado .NET con el arnés de la F06.

**Competidores:** ADO.NET con lectura por ordinal; Dapper con mapeo por alias; EF Core con y sin
seguimiento; y **`Sige.DataAccess` con `DataSet`**, que es el statu quo y el competidor más importante — si
el camino nuevo no le gana, no hay caso.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 09 --rows 1,6600,30000
```

**A · Los cinco mapeadores (~6.600 filas)**

| Implementación | Mediana | p95 | Asignado | Pico | GC 0/1/2 | Líneas de código |
|---|---|---|---|---|---|---|
| ADO.NET (`SqlDataReader`) | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Dapper | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| EF Core `AsNoTracking` | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ + config |
| EF Core con seguimiento | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ + config |
| `DataSet` (statu quo) | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |

**B · `IQueryable` contra SQL directo**

| Camino | Filas traídas | Filas usadas | Mediana | Asignado |
|---|---|---|---|---|
| `IQueryable` con predicado traducible | ⏳ | ⏳ | ⏳ | ⏳ |
| `IQueryable` con `Isbn.TryParse` en el predicado (deuda de la F03) | ⏳ | ⏳ | ⏳ | ⏳ |
| SQL directo equivalente | ⏳ | ⏳ | ⏳ | ⏳ |

> ⚖️ **Veredicto** *(expectativa, sin ejecutar)*. Se espera **empate entre ADO.NET y Dapper** dentro del
> ruido —y publicarlo confirma la creencia de que Dapper es "casi ADO.NET"—, EF Core sin seguimiento
> cerca, con seguimiento separándose en asignaciones más que en tiempo, y el `DataSet` el más caro en
> memoria por un factor grande.
>
> **Tres umbrales por determinar:** (1) a partir de cuántas filas el seguimiento deja de ser gratis;
> (2) **cuántas filas de más trae el predicado no traducible** —la unidad de cobro de la deuda de la F03
> son filas, no milisegundos—; (3) a partir de qué tamaño de resultado el `DataSet` deja de ser tolerable,
> que lo necesita la **F12** para la grilla de 50.000 filas.
>
> ⚠️ **Veredicto prohibido:** *"usa Dapper para leer y EF Core para escribir"* sin decir qué cuesta. Dos
> formas de acceso a datos son dos modelos que mantener, dos sitios donde buscar y una persona más que
> capacitar. En un equipo de dos, ese costo no es abstracto — **si hay empate, una sola herramienta puede
> ser la respuesta correcta aunque no gane en ninguna fila.**

---

## 📐 F10 · Latencia por camino y divergencia medida

**Fase:** 10 · **Ejecutada:** ⏳ pendiente · **Dato transversal: las divergencias por día dimensionan el
outbox de la F17.**

**Hipótesis A:** el camino nuevo —API en medio— tiene **más** latencia que el acceso directo, porque agrega
un salto de red y una serialización. La pregunta no es si es más lento: es cuánto, y si ese costo es
aceptable para lo que compra.

**Hipótesis B:** la doble escritura produce divergencias, y **la mayoría no son bugs del camino nuevo**:
son reglas del sistema viejo que nadie había escrito.

**Condiciones:** SQL Server 2025 en contenedor sobre WSL 2 · base del generador más un día sintético del
almacén de Bogotá (~1.400 movimientos, volumen real) · SDK 10.0.401 · **dos corridas: sin latencia y con
40 ms inyectados** para simular la VPN del depósito de Lima · 30 repeticiones, 5 de calentamiento
descartadas · arnés propio.

**Competidores:** acceso directo (statu quo, nueve años funcionando); API con escritura simple; API con
doble escritura —el estado real de la convivencia—; las tres con y sin latencia.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 10 --latency 0,40
```

**A · Latencia y tasa de error por camino**

| Camino | Latencia p50 | p95 | Tasa de error | Con 40 ms: p95 |
|---|---|---|---|---|
| Acceso directo (statu quo) | ⏳ | ⏳ | ⏳ | ⏳ |
| API en medio, escritura simple | ⏳ | ⏳ | ⏳ | ⏳ |
| API en medio, doble escritura | ⏳ | ⏳ | ⏳ | ⏳ |

**B · Divergencia durante la ventana de convivencia**

| Categoría | En 1.400 operaciones | Qué era |
|---|---|---|
| Regla del sistema viejo no documentada | ⏳ | Información: hay que escribirla |
| Bug del camino nuevo | ⏳ | Se arregla |
| Diferencia tolerable y declarada | ⏳ | Se documenta y se acepta |
| Fallo del camino nuevo sin escritura | ⏳ | **Dimensiona el outbox de la F17** |

> ⚖️ **Veredicto** *(expectativa, sin ejecutar)*. Se espera que el camino nuevo sea **más lento**, y que
> con la latencia de Lima inyectada la diferencia **relativa** se reduzca —porque el salto de red pasa a
> ser una fracción menor del total—, lo cual es contraintuitivo y es el hallazgo de la tabla A.
>
> **Dos umbrales por determinar:** (1) cuánta latencia adicional es aceptable para el formulario, que no
> es una pregunta técnica sino Duván mirando la grilla; (2) cuántas divergencias por día.
>
> ⚠️ **Veredicto prohibido:** *"el camino nuevo es mejor porque es más moderno"*. Es más lento y cuesta
> más operar. Lo que compra es que noventa equipos dejen de tener permiso de escritura sobre todo, que la
> lógica se pueda probar, y que el runtime se pueda mover después. **Ese intercambio es la decisión.**

---

## 📐 F11 · Cuatro compilaciones del mismo módulo

**Fase:** 11 · **Ejecutada:** ⏳ pendiente

**Hipótesis:** el mismo módulo en .NET 10 arranca más rápido y consume menos memoria que en 4.8, y el
tamaño del `publish` depende mucho más del **modo** de publicación que del runtime. Lo que hay que separar
es cuánto de la mejora es el runtime y cuánto el modo, porque se atribuyen juntas.

**Condiciones:** SDK 10.0.401 y .NET Framework 4.8 · Release · Windows 11 · el mismo módulo de facturación
emitiendo cien facturas contra la base del generador · 30 repeticiones, 5 de calentamiento descartadas ·
arranque medido en frío con la caché de disco limpia entre corridas.

**Competidores:** 4.8 tal como está (statu quo); .NET 10 dependiente del framework; autocontenido; y
autocontenido con recorte. **AOT nativo no está aquí a propósito**: es la F20, donde el arranque en frío
cuesta dinero porque algo lo cobra por segundo.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 11 --cold-start
```

| Compilación | Arranque en frío | Memoria de trabajo | Tamaño del publish | Emitir 100 facturas |
|---|---|---|---|---|
| .NET Framework 4.8 | ⏳ | ⏳ | ⏳ | ⏳ |
| .NET 10, dependiente del framework | ⏳ | ⏳ | ⏳ | ⏳ |
| .NET 10, autocontenido | ⏳ | ⏳ | ⏳ | ⏳ |
| .NET 10, autocontenido con recorte | ⏳ | ⏳ | ⏳ | ⏳ |

> ⚖️ **Veredicto** *(expectativa, sin ejecutar)*. Se espera mejor arranque y menos memoria en .NET 10, y
> mucho más peso en disco en el autocontenido a cambio de no depender de un runtime instalado. En el
> trabajo real —emitir cien facturas— se espera **empate**, porque el tiempo lo domina la base de datos.
> **Publicar ese empate es lo más importante de esta entrada:** migrar el runtime no es una optimización
> de rendimiento, y venderlo así es cómo se pierde credibilidad en la siguiente propuesta.
>
> **Dos umbrales por determinar:** (1) cuánto del arranque es el runtime y cuánto el modo de publicación;
> (2) a partir de qué tamaño el autocontenido deja de ser cómodo — lo necesita la **F20** cuando el mismo
> artefacto tenga que caber en una imagen.

---

## 📐 F12 · El mismo formulario en 4.8 y en .NET 10

**Fase:** 12 · **Ejecutada:** ⏳ pendiente · **Dato transversal: el despliegue a 90 equipos es una de las
cinco columnas del veredicto de la F14.**

**Hipótesis:** el formulario sobre .NET 10 arranca más rápido y usa menos memoria que sobre 4.8, y **el
pintado de la grilla con 50.000 filas mejora poco**, porque ahí el cuello de botella no es el runtime sino el
control y su modo de enlace.

**Condiciones:** SDK 10.0.401 y .NET Framework 4.8 · Release · Windows 11 · el mismo formulario contra la
base del generador, semilla `19970417` · grilla con **50.000 filas** · arranque en frío **en un equipo sin
SDK instalado**, caché de disco limpia · 20 repeticiones, 3 de calentamiento descartadas · arnés propio.

**Competidores:** 4.8 tal como está (statu quo, nueve años funcionando); .NET 10 sin tocar el modo de enlace;
.NET 10 con la grilla en modo virtual —para poder **atribuir** la mejora—; y .NET 10 autocontenido, que es el
caso real de los noventa equipos sin runtime instalado.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 12 --rows 50000 --cold-start
```

| Configuración | Arranque en frío | Memoria de trabajo | Pintado de 50.000 filas | Desplazamiento fluido |
|---|---|---|---|---|
| .NET Framework 4.8 | ⏳ | ⏳ | ⏳ | ⏳ |
| .NET 10, enlace igual | ⏳ | ⏳ | ⏳ | ⏳ |
| .NET 10, grilla en modo virtual | ⏳ | ⏳ | ⏳ | ⏳ |
| .NET 10 autocontenido | ⏳ | ⏳ | ⏳ | ⏳ |

| Opción de despliegue | Tamaño | Actualizar 90 equipos | Desde el depósito de Lima |
|---|---|---|---|
| ClickOnce dependiente del framework | ⏳ | ⏳ | ⏳ |
| ClickOnce autocontenido | ⏳ | ⏳ | ⏳ |

> ⚖️ **Veredicto** *(expectativa, sin ejecutar)*. Se espera mejor arranque y menos memoria en .NET 10, y
> **empate en el pintado** entre las dos primeras filas. Si el modo virtual es lo que mueve ese número, la
> conclusión honesta es que **la mejora de fluidez no vino de migrar: vino de un cambio que se podía hacer en
> 4.8 también.** Decirlo separa lo que la migración compra de lo que no.
>
> **Dos umbrales por determinar:** (1) a partir de cuántas filas el modo de enlace importa más que el
> runtime; (2) **cuánto tarda actualizar 90 equipos con el paquete autocontenido**, Lima incluido — y **no se
> estima**.

---

## 📐 F13 · WinForms contra WPF, con virtualización sana y rota

**Fase:** 13 · **Ejecutada:** ⏳ pendiente

**Hipótesis:** WPF arranca **más lento** que WinForms —inicializa un sistema de composición mayor— y a cambio
se desplaza con más fluidez con volumen, porque virtualiza por omisión.

**Condiciones:** SDK 10.0.401 · Release · Windows 11 · el mismo formulario, misma consulta, base del
generador · grilla con **50.000 filas** · arranque en frío en equipo sin SDK · 20 repeticiones, 3 de
calentamiento descartadas · fluidez medida como cuadros por segundo en un desplazamiento continuo de diez
segundos.

**Competidores:** WinForms en .NET 10; WinForms con modo virtual; WPF con virtualización activa; y **WPF con
la virtualización rota** —envolviendo la grilla en un contenedor de altura infinita—, que es la deuda 💸 de la
fase, medida aquí para saber cuánto cuesta el error.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 13 --rows 50000 --cold-start
```

| Configuración | Arranque en frío | Memoria a los 5 min | Pintado de 50.000 filas | Fluidez al desplazar |
|---|---|---|---|---|
| WinForms (.NET 10) | ⏳ | ⏳ | ⏳ | ⏳ |
| WinForms con modo virtual | ⏳ | ⏳ | ⏳ | ⏳ |
| WPF con virtualización | ⏳ | ⏳ | ⏳ | ⏳ |
| WPF con virtualización rota 💸 | ⏳ | ⏳ | ⏳ | ⏳ |

**Y la tabla que no es de rendimiento** — es el argumento de la fase, y **por eso no lleva veredicto**:

| Configuración | Pruebas que corren sin interfaz | Líneas de lógica sin cubrir |
|---|---|---|
| WinForms (fase 12) | **0** | ~60, dentro del `Click` |
| WPF con MVVM | ⏳ | ⏳ |

> ⚖️ **Veredicto** *(expectativa, sin ejecutar)*. Se espera que WinForms arranque más rápido, que WPF se
> desplace mejor, y que **las dos primeras filas empaten en fluidez** una vez que WinForms usa modo virtual —
> lo que diría que la ventaja de WPF no es la virtualización en sí sino **que viene activada por omisión**.
> Una ventaja por omisión es real, porque nadie la olvida.
>
> Y se espera que la cuarta fila sea la peor por un margen amplio: **la virtualización de WPF se pierde en
> silencio**, y una ventaja que se puede perder sin aviso hay que vigilarla.
>
> **Dos umbrales por determinar:** (1) a partir de cuántas filas la virtualización deja de ser opcional en
> cada tecnología; (2) **cuánto arranque de más cuesta WPF**, que es una columna del veredicto de la F14.

---

## 📐 F14 · La tabla del veredicto del escritorio

**Fase:** 14 · **Ejecutada:** ⏳ pendiente · **la cuarta columna la completó la F18** (ver la nota al pie de la tabla)

> 🧭 **Esta es la entrada consolidada de la tabla del veredicto, y es donde la F18 agrega su columna.** El
> documento de la fase 14 enlaza aquí y **no se edita**: es el mecanismo que evita que una fase reescriba el
> material publicado de otra (`prompts/propuesta-fases-y-alcance.md` §8). **La F18 ya agregó la suya**, y lo
> hizo aquí: el `.md` de la fase 14 quedó intacto, que era el punto del mecanismo.

**Hipótesis:** ninguna de las cuatro opciones gana en los cinco criterios, y la que gana en los técnicos **no
es la que gana en los dos últimos** —despliegue y mantenibilidad—, que son los que deciden en una empresa de
dos desarrolladores.

**Condiciones y metodología congelada.** Cambiar cualquiera de estas invalida la comparación:

- **Los cinco criterios:** arranque en frío · memoria a las **ocho horas** · 50.000 filas (pintado y
  fluidez) · despliegue a 90 equipos **sin permisos de administrador** · **quién lo puede mantener**.
- **El módulo medido:** el formulario de existencias, con búsqueda, grilla y resumen, contra la misma API.
- **El volumen:** 50.000 filas, base del generador con semilla `19970417`.
- **Las condiciones de red:** las tres oficinas reales, con el depósito de **Lima como caso adverso**.
- **La memoria:** a las ocho horas, con una consulta cada cinco minutos. No al arrancar.
- Arranque en frío en equipo **sin SDK instalado**, caché de disco limpia. 20 repeticiones, 3 de
  calentamiento descartadas para lo repetible; despliegue y jornada, una vez cada uno con su fecha.

**Los comandos:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 14 --rows 50000 --cold-start
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 14 --soak 8h
dotnet run -c Release --project src\modern\Cordillera.Ops -- deploy --measure --offices bog,mex,lim
```

### La tabla

| Criterio | WinForms (.NET 10) | WPF + MVVM | WinUI 3 | Web (Blazor) |
|---|---|---|---|---|
| **1. Arranque en frío** | ⏳ | ⏳ | ⏳ | ⏳ *(F18)* |
| **2. Memoria a las 8 horas** | ⏳ | ⏳ | ⏳ | ⏳ *(F18)* |
| **3. 50.000 filas: pintado / fluidez** | ⏳ | ⏳ | ⏳ | ⏳ *(F18)* |
| **4. Despliegue a 90 equipos sin permisos** | ⏳ | ⏳ | ⏳ | ⏳ *(F18)* |
| **5. Quién lo puede mantener** | ⏳ | ⏳ | ⏳ | ⏳ *(F18)* |

**Respaldo · despliegue**

| Opción | Empaquetado | Tamaño | Permisos de administrador | Certificado | 90 equipos | Desde Lima |
|---|---|---|---|---|---|---|
| WinForms | ClickOnce autocontenido | ⏳ | **No** | autofirmado basta | ⏳ | ⏳ |
| WPF | ClickOnce autocontenido | ⏳ | **No** | autofirmado basta | ⏳ | ⏳ |
| WinUI 3 | MSIX | ⏳ | **Sí**, salvo con certificado de confianza | **comercial o instalado** | ⏳ | ⏳ |
| Blazor Hybrid | ClickOnce o MSIX | ⏳ | según empaquetado | según empaquetado | ⏳ | ⏳ |

**Respaldo · mantenibilidad (criterio 5)** — cuatro preguntas verificables, no una impresión:

| Pregunta | WinForms | WPF | WinUI 3 | Web |
|---|---|---|---|---|
| ¿Hay diseñador visual? | **Sí** | parcial | parcial | no aplica |
| ¿Puede Duván cambiar un ancho de columna sin ayuda? | ⏳ | ⏳ | ⏳ | ⏳ *(F18)* |
| ¿Puede desplegar una corrección él solo? | ⏳ | ⏳ | ⏳ | ⏳ *(F18)* |
| ¿Cuánto le costó entender el prototipo? *(horas, preguntándole)* | ⏳ | ⏳ | ⏳ | ⏳ *(F18)* |
| ¿Se puede contratar a alguien que lo sepa, en Bogotá? | ⏳ | ⏳ | ⏳ | ⏳ *(F18)* |

> 📝 La cuarta fila **se mide preguntándole a Duván y cronometrando**. Es una medición legítima aunque no
> salga del arnés: es reproducible, tiene condiciones y responde la pregunta. Inventarla sería lo que este
> archivo prohíbe; omitirla porque "no es técnica" sería peor, **porque es la que decide**.

> ⚖️ **Veredicto provisional** *(expectativa, sin ejecutar, y parcial hasta la F18)*. Se espera que WinForms
> gane arranque y despliegue; WPF, fluidez y comprobabilidad; WinUI 3, apariencia y **binding comprobado en
> compilación** —una ventaja real sobre WPF— **y que pierda el criterio 4 por el certificado**; y Blazor
> Hybrid en medio, con la ventaja de compartir implementación con la cuarta columna.
>
> **Tres umbrales por determinar:** (1) **cuántos segundos de arranque de más justifican un cambio de
> tecnología** — pregunta de negocio, no técnica; (2) **cuánto cuesta el certificado de MSIX**, en dinero y
> en gestión, que puede descalificar a WinUI 3 sin discutir una línea de código; (3) **cuántas horas le
> cuesta a Duván cada opción**.
>
> **Y el veredicto no está prejuzgado.** Si los números dicen WinForms, dice WinForms — como resultado, no
> como concesión. La fase está escrita para que las tres respuestas sean posibles.

> 🧵 **La cuarta columna, cuatro fases después (F18).** Entró con la metodología congelada intacta y con una
> adaptación declarada: el formulario de existencias se construyó **también** en el modelo de render ganador,
> para que el módulo medido siguiera siendo el mismo. Y entró con una asimetría que conviene leer antes de
> sacar conclusiones: **la web gana el criterio 4 por definición** —no hay nada que instalar en noventa
> equipos, y el certificado que puede descalificar a WinUI 3 no existe aquí—, y **paga en los criterios 1 y 3
> desde el depósito de Lima**, que es donde está el 15% de los usuarios. Si eso alcanza para mover el
> veredicto es lo que la ejecución tiene que decidir; lo que ya se puede decir es **cuál columna cambia el
> equilibrio y por qué**.
>
> **Un cuarto umbral, que la F18 agregó:** a partir de qué latencia de ida y vuelta el modelo de render
> interactivo deja de sentirse instantáneo. Es el único umbral del curso que se determina **sintiéndolo** y no
> midiéndolo, y está justificado: la pregunta —*¿se puede trabajar ocho horas con esto?*— no la contesta un
> percentil.

---

## 📐 F15 · Minimal APIs, controladores, y el CSV de anoche

**Fase:** 15 · **Ejecutada:** ⏳ pendiente

> 📝 **Esta medición no es el tema de su fase** —el tema es el contrato— y está porque el curso mide. Si sale
> empate, **el empate es el dato útil**: la elección entre minimal APIs y controladores es de estilo y no de
> rendimiento, y saberlo evita una discusión de equipo que no lleva a nada.

**Hipótesis:** al volumen de CatalogAPI, throughput y latencia quedan dentro del ruido entre los dos estilos;
**la diferencia medible está en el arranque**, que es lo que importará en la F20 con un contenedor que escala
a cero.

**Condiciones:** SDK 10.0.401 · Release · Windows 11 · SQL Server 2025 en contenedor, base del generador con
semilla `19970417` · **el mismo endpoint implementado dos veces**, con el mismo servicio, DTO y mapeo · 200
peticiones concurrentes durante 60 s —el barrido donde la F05 encontró el codo— · arranque en frío con caché
de disco limpia · 20 repeticiones, 3 de calentamiento descartadas · arnés propio.

**Competidores:** minimal API con DTO; controlador con el mismo cuerpo; minimal API **devolviendo la entidad**
—el anti-patrón, medido—; y **el volcado CSV nocturno**, que es el statu quo y el competidor de verdad.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 15 --concurrency 200 --cold-start
```

| Implementación | Throughput (req/s) | Latencia p50 | p95 | Arranque en frío | Asignado por petición |
|---|---|---|---|---|---|
| Minimal API con DTO | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Controlador con DTO | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Minimal API devolviendo la entidad | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Volcado CSV nocturno (statu quo) | n/a | **24 h de desfase** | — | — | — |

> ⚖️ **Veredicto** *(expectativa, sin ejecutar)*. Se espera **empate** entre los dos estilos y una diferencia
> medible en arranque a favor de la minimal API. Y se espera que la tercera fila quede **igual o mejor** que la
> primera, porque saltarse el mapeo ahorra trabajo: **si es así, queda demostrado que el DTO no se defiende con
> rendimiento sino con el contrato** — y eso es más honesto que insinuar que además es rápido.
>
> **Dos umbrales por determinar:** (1) a partir de cuántos endpoints las convenciones de un controlador ahorran
> más de lo que cuestan —medida de mantenimiento, no de rendimiento—; (2) cuánto arranque de más cuesta el
> controlador, que lo usa la **F20**.
>
> 📝 **La última fila no es comparable en las mismas unidades y está a propósito:** el competidor real no es el
> otro estilo de API, **es el CSV de anoche**. Veinticuatro horas de desfase contra milisegundos es la única
> comparación que a Almenara le importa.

---

## 📐 F16 · El costo de la autenticación

**Fase:** 16 · **Ejecutada:** ⏳ pendiente

**Hipótesis:** validar un token exige la clave pública del emisor, y **descargarla en cada petición** convierte
una operación de microsegundos en una llamada de red por petición. La diferencia debe ser de órdenes de
magnitud.

**Condiciones:** SDK 10.0.401 · Release · Windows 11 · el proveedor OIDC en contenedor —el emulador declarado
en `alcance-del-proyecto.md` §10.1— sobre WSL 2 · 200 peticiones concurrentes durante 60 s · tokens firmados
con RSA · 20 repeticiones, 3 de calentamiento descartadas · arnés propio.

**Competidores:** con caché de claves (el comportamiento por omisión); sin caché; **sin autenticación** (línea
base); y **el filtro casero de clave compartida** que SIGE tiene desde 2019 — que no es una propuesta: es lo
que hay, y hay que saber cuánto "ahorra".

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 16 --concurrency 200
```

| Configuración | Throughput (req/s) | Latencia p50 | p95 | Llamadas al emisor | Asignado por petición |
|---|---|---|---|---|---|
| Con caché de claves | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Sin caché de claves | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Sin autenticación (línea base) | ⏳ | ⏳ | ⏳ | 0 | ⏳ |
| Clave compartida en cabecera (SIGE 2019) | ⏳ | ⏳ | ⏳ | 0 | ⏳ |

> ⚖️ **Veredicto** *(expectativa, sin ejecutar)*. Se espera que la versión con caché quede **muy cerca de la
> línea base** —validar una firma es trabajo de CPU y es barato— y que sin caché la latencia se degrade por un
> factor grande.
>
> **Y se espera que la clave compartida sea la más rápida de las cuatro.** Es el primer sitio del curso donde
> **un número favorece al anti-patrón**, y publicarlo así es el punto: comparar una cadena siempre va a ser
> más rápido que validar una firma. Lo que la medición demuestra es que **la diferencia es tan pequeña que el
> argumento de rendimiento no existe**, y entonces la decisión se toma donde corresponde — revocabilidad,
> caducidad, auditoría y saber quién está al otro lado.
>
> **Dos umbrales por determinar:** (1) **cuánto cuesta la autenticación por petición**, que es el número que
> hay que tener a mano cuando alguien proponga quitarla "por rendimiento"; (2) **cuánto tarda el servicio en
> reaccionar a una rotación de claves** con el tiempo de caché por omisión.

---

## 📐 F17 · La liquidación completa, y la cola contra la mensajería

**Fase:** 17 · **Ejecutada:** ⏳ pendiente

> 📝 **Esta entrada tiene columnas cualitativas —reanudable, cancelable, reproducible— con valores "No".** Es
> deliberado y conviene decirlo: **una tabla de medición puede tener columnas que no son números**, y en esta
> entrada son las que deciden. El statu quo gana o empata en duración y pierde las tres.

**Hipótesis:** la cola en tabla de SQL Server —que Cordillera ya tiene y funciona— sostiene el volumen de
NightPress con holgura, y la mensajería gestionada gana en throughput máximo y en funcionalidad de operación **a
un costo mensual que al volumen real no se justifica**.

**Condiciones:** SQL Server 2025 en contenedor sobre WSL 2 · el emulador de mensajería declarado en
`alcance-del-proyecto.md` §10.1 · base del generador, semilla `19970417`, **21.000 contratos y el trimestre
completo** · SDK 10.0.401 · 10 ejecuciones de la liquidación, 2 de calentamiento descartadas · arnés propio con
memoria y colecciones por generación.

**Competidores:** el trabajo del SQL Server Agent con los tres procedimientos —**el statu quo, y el que hay que
vencer**—; NightPress por lotes sin cola; con cola en tabla; y con mensajería gestionada.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 17 --contracts 21000
```

**A · La liquidación completa**

| Implementación | Duración total | Reanudable | Cancelable | Reproducible a 8 meses | Pico de memoria |
|---|---|---|---|---|---|
| Agent + procedimientos (statu quo) | ⏳ | **No** | **No** | **No** | ⏳ |
| NightPress por lotes, sin cola | ⏳ | Sí | Sí | Sí | ⏳ |
| NightPress con cola en tabla | ⏳ | Sí | Sí | Sí | ⏳ |
| NightPress con mensajería gestionada | ⏳ | Sí | Sí | Sí | ⏳ |

**B · La cola: throughput, latencia y costo mensual**

| Opción | Mensajes/s | Latencia p95 | Cola de fallidos | Costo mensual al volumen real | Amarre |
|---|---|---|---|---|---|
| Tabla en SQL Server | ⏳ | ⏳ | hay que construirla | **0** (la base ya está pagada) | ninguno |
| Mensajería gestionada | ⏳ | ⏳ | incluida | 💲 ⏳ *(precio publicado, fecha y región: East US 2)* | moderado |

> 💲 El costo de la fila gestionada **se marca como no ejecutado** (`formato-de-mediciones.md` §2.5): el
> throughput se mide contra el emulador, el precio se cita publicado con su fecha y su región.

> ⚖️ **Veredicto** *(expectativa, sin ejecutar)*. Se espera que NightPress **le gane con holgura al statu quo
> en las cuatro columnas cualitativas** y que la duración total sea **parecida o incluso peor**, porque los
> lotes, la auditoría y las claves de idempotencia son trabajo adicional. Publicarlo así es el punto:
> **NightPress no es más rápido, es reanudable y auditable**, y eso es lo que se compró.
>
> **Tres umbrales por determinar:** (1) a partir de cuántos mensajes por segundo la tabla deja de servir;
> (2) **cuánto cuesta la auditoría línea por línea**, que es el precio de poder responderle al abogado;
> (3) **cuánto tarda reproducir un número de hace ocho meses** — hoy son tres días y el objetivo es segundos.
>
> 📝 Y la columna que decide no es numérica: **"reproducible a 8 meses"** tiene tres "No" en la primera fila,
> y ese es el argumento del proyecto entero.

---

## 📐 F18 · Los tres modelos de render, desde tres oficinas

**Fase:** 18 · **Ejecutada:** ⏳ pendiente

> 🧭 **Esta entrada tiene una obligación doble:** mide los tres modelos de render **y completa la cuarta
> columna de la entrada de la F14** de más arriba. Lo segundo se hace allí, en la entrada consolidada, con la
> metodología congelada y sin tocar el documento publicado de la fase 14.

**Hipótesis:** los tres modelos son **indistinguibles con la conexión de Bogotá** —y publicar ese empate es la
mitad del valor de la entrada, porque explica por qué esta decisión se toma mal tan a menudo— y con la del
depósito de Lima **Blazor Server se degrada de forma cualitativa y no gradual**: el filtro se siente pegajoso y
el circuito se cae. MVC y WebAssembly siguen usables por razones distintas — MVC porque solo paga en la
navegación, WebAssembly porque ya pagó todo al principio.

**Condiciones:** SDK 10.0.401 · Release · Windows 11 · **la misma pantalla de recepción de manuscritos en los
tres modelos**, el mismo componente en los dos de Blazor · base del generador, semilla `19970417`, lista de
**400 manuscritos** (el volumen real de un mes) · **los tres perfiles de red medidos en las tres oficinas** e
inyectados por middleware, con latencia **y pérdida de paquetes** · 20 repeticiones, 3 de calentamiento
descartadas · memoria de servidor con **90 circuitos simultáneos**, que es el número de personas de Cordillera
· arnés propio.

**Competidores:** Blazor Server, Blazor WebAssembly y ASP.NET Core MVC. Y el escritorio de las F12–F14 como
cuarta referencia, que es lo que justifica la obligación doble.

**Los comandos:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 18 --profiles bog,mex,lim
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 18 --circuits 90
```

**A · Latencia de interacción por oficina** — desde que el usuario teclea hasta que la interfaz responde

| Modelo | Bogotá | Ciudad de México | **Lima** | Carga inicial | Circuitos caídos en 8 h |
|---|---|---|---|---|---|
| Blazor Server | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Blazor WebAssembly | ⏳ | ⏳ | ⏳ | ⏳ | n/a |
| MVC clásico | ⏳ | ⏳ | ⏳ | ⏳ | n/a |

**B · Costo en el servidor**

| Modelo | Memoria por usuario conectado | Con 90 usuarios | Sesiones adheridas | Peticiones por interacción |
|---|---|---|---|---|
| Blazor Server | ⏳ | ⏳ | **obligatorias** | 1 |
| Blazor WebAssembly | ~0 | ~0 | no | solo datos |
| MVC clásico | ⏳ *(sesión)* | ⏳ | según sesión | 1 por navegación |

> ⚖️ **Veredicto** *(expectativa, sin ejecutar)*. Se espera **empate en Bogotá** entre los tres, separación
> clara en Lima, la peor carga inicial para WebAssembly por un margen amplio, y que Blazor Server tenga la
> peor latencia de interacción y **la única columna de circuitos caídos que no es cero**.
>
> **Tres umbrales por determinar:** (1) **a partir de qué latencia de ida y vuelta Blazor Server deja de
> sentirse instantáneo**, que decide por oficina; (2) **cuánta memoria cuestan 90 circuitos**, que decide si
> hace falta un servidor más y es una fila de la factura de la F20; (3) **cuánta pérdida de paquetes hace
> falta para tirar un circuito** — que es lo que le pasa a Nohora en Lima y **no aparece en ninguna medición
> de latencia**.
>
> 📝 **La columna de Lima no es una columna más.** El 15% de los usuarios está ahí, y una herramienta inusable
> para el 15% de la gente no tiene un problema menor: va a tener dos versiones o ninguna.
>
> ⚠️ Y dos criterios de esta fase **no están en esta tabla y pesan más que ella**: que Nohora pueda corregir un
> registro a las siete de la tarde sin pedir permiso, y que el flujo de Ximena no gane ni un paso. Una opción
> que falle esos dos está mal **aunque gane las dos tablas**, y eso no es sentimentalismo: una herramienta que
> no se usa no tiene ningún rendimiento. Lo citan la **F20** (sesiones adheridas y memoria) y la **F24**.

---

## 📐 F19 · Dónde se van los cuatro segundos, y qué cuesta saberlo

**Fase:** 19 · **Ejecutada:** ⏳ pendiente

> 📝 **Esta entrada tiene un formato que no aparece en ninguna otra del curso: la tabla A no compara
> competidores, reparte un total.** Es legítimo y conviene decirlo, porque la pregunta no es *"cuál de estas
> opciones es mejor"* sino *"de estos cuatro segundos, cuántos son de cada capa"*. Un reparto tiene una
> obligación propia que una comparación no tiene: **las filas tienen que sumar el total**, y si no suman, falta
> un tramo por instrumentar.

**Hipótesis:** de los cuatro segundos de la consulta del catálogo, **la mayor parte está del otro lado del
borde 🧬** —dentro de `SP_CATALOGO`, código de 1997— y no en el código moderno. Y una segunda, que decide si la
fase es sostenible: **instrumentar cuesta menos del 5% de latencia**, con el viaje extra de
`sp_set_session_context` incluido.

**Condiciones:** SDK 10.0.401 · Release · Windows 11 · la consulta `/catalogo?anio=2026` contra la base del
generador con semilla `19970417` · exportador OTLP a un recolector local, **sin muestreo** · 30 repeticiones, 3
de calentamiento descartadas · sesión de eventos extendidos activa en el motor, **con su costo medido aparte**
· arnés propio.

**Competidores:** cuatro configuraciones de instrumentación — ninguna, automática, con el cruce del borde, y
con el cruce más los eventos extendidos activos.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 19 --escenario catalogo-2026
```

**A · El reparto de los cuatro segundos**

| Tramo | Duración (mediana) | % del total | Generación |
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

> ⚖️ **Veredicto** *(expectativa, sin ejecutar)*. Se espera que la tabla A muestre **la mayor parte del tiempo
> dentro del procedimiento de 1997** y el trabajo propio del API como una fracción pequeña — lo cual convierte
> *"el catálogo está lento"* en una decisión sobre `SP_CATALOGO` y no en una optimización de C#. Se espera que
> la instrumentación automática sea prácticamente gratis, que el cruce del borde cueste un viaje de ida y
> vuelta visible pero pequeño, y que **los eventos extendidos sean el único componente con costo serio** —
> razón por la cual se activan para diagnosticar y se apagan.
>
> **Tres umbrales por determinar:** (1) **qué porcentaje del total vive del otro lado del borde**, que es
> argumento de presupuesto para la F20 y probablemente decide el destino de `SP_CATALOGO`; (2) cuánto cuesta el
> viaje extra de `sp_set_session_context`, y si vale dejarlo permanente o solo bajo bandera; (3) **cuántos
> gigabytes genera una hora sin muestreo**, que es directamente una línea de la factura de la **F20** y el dato
> con el que se elige el porcentaje de muestreo, en vez de poner 10% porque suena razonable.
>
> ⚠️ **Cómo no leer esta tabla.** Un tramo padre **incluye el tiempo de sus hijos**: la fila del API no dice
> "el API tardó eso", dice "todo lo que pasó dentro de la petición tardó eso". El trabajo propio de una capa es
> su duración **menos** la de sus hijos, y olvidarlo es cómo se culpa a la capa equivocada. Es el error de
> lectura de trazas más común y está en `INSTINTOS.md`.

---

## 📐 F20 · El tamaño de las imágenes y la factura mensual

**Fase:** 20 · **Ejecutada:** ⏳ pendiente

> 💲 **Esta es la única entrada del curso cuyo veredicto está en pesos**, y por eso agrega la sexta regla de
> honestidad de este archivo: cada cifra de costo va con **precio publicado, fuente, fecha y región** —East US
> 2— o no va. La mitad de las celdas de abajo son costos, y ninguna se escribe de memoria.

**Hipótesis:** dos, de naturaleza distinta. **Técnica:** la imagen reducida y autocontenida es varias veces más
pequeña que la imagen por omisión con SDK y arranca más rápido, y **la imagen de Windows del módulo que la F11
no migró es de otro orden de magnitud**. **Económica:** para el tráfico de Cordillera, los contenedores
administrados son más baratos que un orquestador y que la máquina virtual actual, y la diferencia **se amplía
al sumar el costo de operación de las dos personas**.

**Condiciones:** SDK 10.0.401 · Release · imágenes construidas con caché limpia · región **East US 2** para
todas las cifras · precios de las páginas oficiales de Azure con **fecha de consulta registrada por línea** ·
volumen del generador, semilla `19970417`, y el volumen real declarado de Cordillera · arranque medido como
tiempo hasta responder el primer chequeo de salud, 10 repeticiones con 2 de calentamiento descartadas · arnés
propio para lo técnico, `Cordillera.Costos` para lo económico.

**Competidores:** cinco imágenes base, y tres formas de alojamiento más el centro de datos de 2019 como
referencia histórica.

**Los comandos:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 20 --imagenes
dotnet run -c Release --project src\modern\Cordillera.Costos -- --hoja completa --region eastus2
```

**A · El tamaño de las imágenes**

| Imagen | Tamaño | Arranque hasta el primer chequeo | ¿Intérprete de comandos? |
|---|---|---|---|
| `sdk:10.0` *(el error de principiante)* | ⏳ | ⏳ | sí |
| `aspnet:10.0` *(por omisión, correcta)* | ⏳ | ⏳ | sí |
| `runtime-deps:10.0-noble-chiseled` + autocontenido | ⏳ | ⏳ | **no** |
| ídem + recortado | ⏳ | ⏳ | no |
| **`framework/aspnet:4.8-windowsservercore`** *(el módulo sin migrar)* | ⏳ | ⏳ | sí |

**B · La factura mensual, por forma de alojamiento**

| Forma | Cómputo | Base de datos | Salida | Telemetría | **Total** | Operación (h/mes) | Amarre |
|---|---|---|---|---|---|---|---|
| Contenedores administrados | 💲 ⏳ | 💲 ⏳ | 💲 ⏳ | 💲 ⏳ | 💲 ⏳ | ⏳ | bajo |
| Orquestador (AKS) | 💲 ⏳ | 💲 ⏳ | 💲 ⏳ | 💲 ⏳ | 💲 ⏳ | ⏳ | bajo en el estándar, **alto en las horas aprendidas** |
| Máquina virtual *(como hoy)* | 💲 ⏳ | 💲 ⏳ | 💲 ⏳ | 💲 ⏳ | 💲 ⏳ | ⏳ | bajo |
| Centro de datos propio *(2019, referencia)* | 💲 ⏳ | 💲 ⏳ | **0** | **0** | 💲 ⏳ | ⏳ | ninguno, y **sin respaldo eléctrico** |

**C · Las tres deudas, en pesos al mes**

| Deuda | De la fase | Costo mensual del atajo | Costo de pagarla | Veredicto |
|---|---|---|---|---|
| Volcado completo del catálogo, descargado cada hora | 15 | 💲 ⏳ | 💲 ⏳ | ⏳ |
| Cola en tabla contra mensajería administrada | 17 | **0** en factura / ⏳ h en operación | 💲 ⏳ | ⏳ |
| Telemetría sin muestreo | 19 | 💲 ⏳ | ⏳ *(menos visibilidad)* | ⏳ |

> ⚖️ **Veredicto** *(expectativa, sin ejecutar)*. Se espera una diferencia grande en la tabla A entre la imagen
> con SDK y la reducida, y **un salto de orden de magnitud con la de Windows** — que es el argumento económico
> para terminar la migración que la F11 dejó en un módulo de cuatro, llegando nueve fases tarde con el precio
> puesto. Se espera que la tabla B favorezca los contenedores administrados, con la diferencia ampliándose en
> la última columna. Y se espera que la tabla C tenga **un veredicto incómodo para el instinto de ingeniería**:
> que la cola en tabla gane para este volumen, y que la paginación del catálogo se pague sola.
>
> **Cuatro umbrales por determinar:** (1) **a partir de qué tráfico el orquestador empieza a convenir** — el
> número que hace defendible decir *"Kubernetes no, todavía"* en vez de *"Kubernetes no"*; (2) cuánto cuesta al
> mes el volcado completo del catálogo, que decide si la paginación de la F15 es una mejora o una urgencia; (3)
> **qué porcentaje de muestreo sostiene la pregunta de la F19 al precio publicado** — muestrear por debajo de
> lo que la pregunta exige es pagar por telemetría inútil; (4) **cuánta capacidad se está pagando sin usar**,
> que es la columna que explica el 30% de 2020 y la que hay que revisar cada mes.
>
> ⚠️ **La advertencia de honestidad más importante de este archivo, porque esta tabla se puede usar para mentir
> en las dos direcciones: la fila del centro de datos propio no incluye el riesgo.** No tenía respaldo eléctrico
> confiable y la copia de la base se guardaba en un disco externo en la oficina de al lado. Comparar solo el
> total es la misma deshonestidad que comparar solo la latencia. **Si esta tabla se usa para argumentar que el
> traslado de 2020 fue un error, está mal usada** — salió un 30% por encima *y* eliminó un riesgo que nadie
> había costeado. Lo que faltó en 2020 no fue prudencia: fue que nadie puso las dos columnas en la misma hoja,
> que es exactamente lo que esta entrada hace.
>
> 📝 Y una nota sobre lo que la tabla B **no** muestra: el punto de equilibrio. Un ahorro mensual que tarda
> dieciocho meses en recuperar la inversión de contenerizar es un ahorro distinto del que aparece en la fila.
> Y hay un supuesto escondido que la tabla no señala: **la máquina virtual actual no se apaga** mientras el
> módulo de reportes siga en .NET Framework 4.8. La arquitectura moderna no la elimina: la duplica. Lo citan la
> **F24** y el ejercicio 19 de la F20.

---

## 📐 F21 · La curva de devolución, y quién predice mejor el tiraje

**Fase:** 21 · **Ejecutada:** ⏳ pendiente

> 📝 **Esta entrada tiene un competidor que no es software: es una persona.** Gustavo Lemos lleva treinta y un
> años decidiendo tirajes mirando el título, la portada y el mes. Es legítimo y es el statu quo —igual que el
> trabajo del SQL Server Agent en la F17—, y hay que decir una cosa antes de la tabla: **el veredicto no autoriza
> a reemplazarlo**. Si el modelo gana en promedio, lo que eso justifica es poner los dos números sobre la mesa
> cuando él decide.

**Hipótesis:** tres. **(a)** la cifra de un periodo sigue moviéndose **mucho después de 90 días**, así que un
conjunto de entrenamiento armado a 30 está sistemáticamente inflado; **(b)** ML.NET y el modelo servido con ONNX
dan precisión comparable y se separan en **esfuerzo de construcción**, que no es un número de arnés; **(c)** el
modelo le gana al baseline tonto, le gana a Gustavo en títulos con serie larga y **le pierde en debutantes**.

**Condiciones:** SDK 10.0.401 · Release · Windows 11 · base del generador, semilla `19970417`, histórico
**2016–2026** · ML.NET 5.0.0 · Microsoft.ML.OnnxRuntime 1.30.0, CPU · el modelo de ONNX entrenado fuera del curso
y tratado como artefacto dado · **validación hacia adelante en el tiempo** —se entrena hasta 2024 y se evalúa
2025–2026, nunca con partición aleatoria— · conjunto armado con **edad de observación constante** · 1.000
predicciones, 100 de calentamiento descartadas · arnés propio.

**Competidores:** ML.NET en proceso · Python → ONNX servido en .NET · un servicio de Python detrás de HTTP · el
baseline tonto (*lo mismo que el título anterior del mismo autor*) · **y Gustavo**.

**Los comandos:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 21 --curva-devolucion
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 21 --modelos --holdout 2025-2026
```

**A · La curva de devolución** — el dato que decide todo lo demás, y que Cordillera nunca había escrito

| País · sello | 30 días | 60 | 90 | 180 | 365 | Se estabiliza a |
|---|---|---|---|---|---|---|
| Colombia · literatura | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| México · texto escolar | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Perú · texto escolar | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Colombia · ensayo | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |

**B · Las herramientas**

| Opción | Error medio absoluto | Latencia p95 | Tamaño del artefacto | Esfuerzo de construcción | Costo mensual |
|---|---|---|---|---|---|
| ML.NET 5.0.0, en proceso | ⏳ | ⏳ | ⏳ | ⏳ *(cualitativo, declarado)* | **0** |
| Python → ONNX, servido en .NET | ⏳ | ⏳ | ⏳ | ⏳ | **0** |
| Servicio de Python por HTTP | ⏳ | ⏳ | n/a | ⏳ | 💲 ⏳ *(otro despliegue)* |

**C · Contra quien hay que vencer**

| Predictor | Error medio absoluto | Serie larga | **Debutantes** | Sesgo | Ejemplares destruidos, simulado |
|---|---|---|---|---|---|
| Baseline tonto | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Modelo (ONNX) | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| **Gustavo** | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |

> ⚖️ **Veredicto** *(expectativa, sin ejecutar)*. Se espera **movimiento significativo más allá de los 90 días**
> en la tabla A —que invalida cualquier conjunto armado a 30 y es el hallazgo más reutilizable de la fase—,
> **empate en precisión** entre ML.NET y ONNX en la B —lo que significa que la elección no es de calidad, es de
> quién hace el trabajo—, y una tabla C incómoda: el modelo gana en series largas y pierde en debutantes.
>
> **Cuatro umbrales por determinar:** (1) a qué edad de observación se estabiliza la cifra, que decide cómo se
> arma el conjunto y **cuándo un número es firme en junta**; (2) cuánto histórico hace falta para que el modelo le
> gane a Gustavo, que dice a qué títulos aplicarlo; (3) **de qué lado se equivoca cada predictor**, porque
> pasarse son ejemplares destruidos y quedarse corto son seis semanas perdidas; (4) cuánto habría ahorrado en
> 2024, que es la única cifra que la junta va a mirar —referencia: **41.000 ejemplares destruidos**—.
>
> 📝 La columna de esfuerzo de la tabla B **es cualitativa y va declarada** (§2.4, como "reproducible" en la
> F17). Es la columna que decide la fase, y fingir que es un número la haría menos honesta.
>
> ⚠️ Y el error de validación **no es una métrica de esta tabla a propósito**: con un conjunto sesgado en el
> tiempo, un error de validación excelente es la prueba de que el modelo aprendió bien una mentira. Lo cita la
> **F24**.

---

## 📐 F22 · Tres formas de recuperar, y qué cuesta negarse a responder

**Fase:** 22 · **Ejecutada:** ⏳ pendiente

> ⚠️ **Dos avisos de lectura antes de las tablas.** El primero: el modelo de lenguaje y el de embeddings son
> **locales y sustituidos** (`alcance-del-proyecto.md` §10.1), así que las cifras de calidad con un modelo de
> frontera serán otras — **probablemente mejores en redacción y no necesariamente en la última columna**, porque
> un modelo mejor también es más persuasivo al equivocarse. Lo que estas tablas miden es **el diseño del
> sistema**, y por eso son transferibles. El segundo: **la columna de afirmación falsa no se puede promediar con
> las demás**. Una exhaustividad mediocre hace que alguien baje al archivo; una afirmación falsa produce una
> cesión doble. No son errores del mismo tipo.

**Hipótesis:** **(a)** el vectorial gana en preguntas parafraseadas y **el texto completo gana en las que citan
un término contractual exacto**, que son más de las que uno esperaría; **(b)** el vectorial **dentro del SQL
Server ya pagado** es competitivo contra un servicio administrado, que tiene que ganarse su factura con calidad
medible; **(c)** la tasa de afirmación falsa **solo baja a cero con la verificación determinista** — ninguna
variante de instrucción al modelo la elimina.

**Condiciones:** SDK 10.0.401 · Release · Windows 11 · SQL Server 2025 en contenedor, con texto completo y con el
tipo `vector` nativo · `Microsoft.Extensions.AI` 10.10.0 · modelo local (§10.1) · corpus: los contratos del
generador, semilla `19970417`, **47 años** · conjunto de **30 preguntas reales** escritas por Clara, de las que
**10 tienen respuesta negativa o exigen negarse** · **5 ejecuciones del conjunto completo**, porque la salida no
es determinista · arnés propio.

**Competidores:** texto completo de SQL Server · vectorial de SQL Server 2025 · las dos combinadas · **Azure AI
Search, solo estudiado** con precio publicado (💲, §2.5).

**Los comandos:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.IA.Evaluacion -- run --suite derechos --repeats 5
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 22 --reindexar
```

**A · Recuperar y responder** — sobre las 30 preguntas

| Forma de recuperar | Precisión | Exhaustividad | Cita sólida | Se negó cuando debía | **Afirmación falsa** | Latencia p95 |
|---|---|---|---|---|---|---|
| Texto completo (SQL Server) | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Vectorial (SQL Server 2025) | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Las dos combinadas | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Azure AI Search | 💲 no ejecutado | 💲 | 💲 | 💲 | 💲 | 💲 |

**B · Lo que cuesta el aparato vectorial**

| Concepto | Sin caché | Con caché | Costo mensual |
|---|---|---|---|
| Indexar 47 años, una vez | ⏳ | ⏳ | 💲 ⏳ |
| **Reindexar al cambiar el modelo de embeddings** | ⏳ | ⏳ *(la caché no sirve)* | 💲 ⏳ |
| Embeddings de una consulta | ⏳ | ⏳ | 💲 ⏳ |
| Almacenamiento del índice | — | — | 💲 ⏳ |
| Azure AI Search, el mismo corpus | 💲 no ejecutado | — | 💲 ⏳ |

**C · La verificación, con y sin**

| Configuración | Cita sólida | Afirmación falsa | Se negó cuando debía |
|---|---|---|---|
| Solo instrucción al modelo | ⏳ | ⏳ | ⏳ |
| + la cita tiene que resolver | ⏳ | ⏳ | ⏳ |
| + **cubrir idioma, territorio y vigencia** | ⏳ | ⏳ **(objetivo: 0)** | ⏳ |

> ⚖️ **Veredicto** *(expectativa, sin ejecutar)*. Se espera **reparto y no ganador** en la tabla A —y publicar
> que el texto completo gana en un tipo de pregunta es la mitad del valor de la entrada, porque es el resultado
> que el entusiasmo descarta sin medir—; que la B muestre que **la caché no sirve de nada el día que cambia el
> modelo de embeddings**, que es justo cuando más falta hace; y que la C sea la más clara: la afirmación falsa
> solo llega a cero en la última fila.
>
> **Cuatro umbrales por determinar:** (1) qué tipo de pregunta gana cada recuperador —probablemente "las dos"—;
> (2) **cuánto cuesta reindexar 47 años**, que es el precio de cambiar de modelo de embeddings y hay que saberlo
> antes de elegir el primero; (3) cuánta calidad compra Azure AI Search por su factura; (4) **cuántas
> afirmaciones falsas quedan con la verificación completa** — y si no es cero, el sistema no sale a producción,
> que es un veredicto posible.

---

## 📐 F23 · El duelo, con su declaración de defendibilidad

**Fase:** 23 · **Ejecutada:** ⏳ pendiente

> 🧭 **Esta entrada agrega la séptima regla de honestidad de este archivo y la cumple:** la **declaración de
> defendibilidad** —qué se configuró en cada lado, con qué valor y por qué— se escribe **antes** de medir, vive
> en `src/duelo/DEFENDIBILIDAD.md` y **se publica con la tabla**. Sin ella, "el competidor es defendible" es una
> afirmación del autor sobre sí mismo.

**Hipótesis:** **(a)** en latencia en régimen, al volumen de Cordillera, las dos **empatan dentro del ruido**;
**(b)** en arranque en frío .NET con JIT le gana a la JVM, y con las dos variantes nativas la diferencia se reduce
mucho **a costa del tiempo de construcción**; **(c)** .NET usa menos memoria, y eso se traduce a pesos **solo si
el alojamiento cobra por memoria**; **(d)** la diferencia entre las dos plataformas es **más pequeña que la
diferencia entre un equipo que domina una y un equipo que la está aprendiendo**.

**Condiciones:** .NET 10 (SDK 10.0.401) · **Spring Boot 4.1.1 sobre Java 25 LTS (Temurin)** · producción en las
dos · contenedores de **2 vCPU y 2 GB** idénticos · la misma base SQL Server 2025 con los mismos índices, semilla
`19970417` · **el mismo SQL, verificado en el plan de las dos** · el conjunto de pruebas de contrato de la F15
pasando en las dos · **200 clientes concurrentes** · **calentamiento descartado por criterio y no por reloj**
—hasta que el p95 se estabilice dentro del 5%—, con el tiempo de cada una publicado · memoria a las **ocho
horas** (metodología de la F14) · precios con la metodología de la F20, East US 2 · recursos **verificados en el
motor**, no solo en el código.

**Competidores:** dos plataformas, **cinco configuraciones** — ASP.NET Core JIT · ASP.NET Core AOT nativo ·
Spring Boot con hilos de plataforma · Spring Boot con virtual threads · Spring Boot como imagen nativa. **No hay
un tercer competidor** (`propuesta-fases-y-alcance.md` §10.5); las variantes de compilación no lo son.

**Los comandos:**

```powershell
docker compose -f src\duelo\compose.yml up --build
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 23 --duelo --clients 200
dotnet run -c Release --project src\modern\Cordillera.Costos -- --hoja duelo --region eastus2
```

**A · Rendimiento**

| Configuración | Arranque a la 1ª respuesta | Peticiones hasta régimen | p50 | p95 | Dispersión | Memoria en régimen | Memoria a las 8 h |
|---|---|---|---|---|---|---|---|
| ASP.NET Core 10, JIT | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| ASP.NET Core 10, AOT nativo | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Spring Boot 4.1.1, hilos de plataforma | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Spring Boot 4.1.1, virtual threads | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Spring Boot 4.1.1, imagen nativa | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |

**B · Construir y operar**

| Configuración | Tiempo de construcción | Tamaño de imagen | Costo mensual al volumen real | ¿Rompe la reflexión? |
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
| **Ofertas de empleo en Bogotá** | ⏳ | ⏳ | portales, misma fecha y filtros |
| **Rango salarial declarado** | ⏳ | ⏳ | ídem, con la fuente |
| ¿Lo sabe Duván? | **Sí** | No | preguntándole |
| Adoptar concurrencia en código bloqueante existente | ⏳ | ⏳ *(Loom)* | cualitativo, declarado |

> ⚖️ **Veredicto** *(expectativa, sin ejecutar)*. Se espera **empate en latencia en régimen**, y publicarlo así
> —con la dispersión que lo sostiene— es el resultado más valioso de esta entrada: al volumen de Cordillera,
> **el rendimiento no es una razón para elegir plataforma**. Se espera que .NET gane arranque y memoria, que las
> variantes nativas acerquen la primera columna a costa del tiempo de construcción, y que **decida la tabla C**,
> donde una fila dice "Sí" y "No" y ninguna latencia la contradice.
>
> **Cuatro umbrales por determinar:** (1) de qué tamaño es la diferencia real en régimen; (2) **cuántas
> peticiones necesita cada una para llegar a su régimen**, el dato que casi nadie publica y el que hace honesta
> la columna de arranque; (3) cuánto de la ventaja de memoria se convierte en pesos al alojamiento de la F20;
> (4) cuántas ofertas de cada plataforma hay en la ciudad del lector — la única columna cuya respuesta cambia
> según dónde viva.
>
> 📝 **Los empates se publican como empates** (§2.4): si dos medianas caen dentro de la dispersión combinada, la
> celda dice **empate** y se justifica con el número. No "ligeramente mejor", no una flecha. En esta tabla van a
> ser varias celdas, **y son la conclusión**.
>
> ⚠️ **Y esta tabla no decide por Cordillera.** La decisión estaba tomada por 700 procedimientos almacenados que
> nadie ha leído, unas licencias pagadas y un compañero que sabe C# — tres razones que no aparecen en ninguna
> columna de A ni de B. Lo que la tabla contesta es **de qué tamaño era la diferencia que se estaba
> discutiendo**. Lo cita la **F24**, admisión 4.
>
> 🔥 Y hay una medición opcional que, si se confirma, es el mejor argumento del curso entero: repetir el duelo con
> el endpoint que **cruza el borde 🧬** —el que llama a `SP_CATALOGO`—. Hipótesis: la diferencia entre plataformas
> **desaparece**, porque el procedimiento de 1997 domina el tiempo (F19).

---

## 🧮 F24 · Consolidación: el estado de las veinticuatro

**Fase:** 24 · **No produce medición propia.** Verifica que este archivo cumpla sus propias reglas.

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- consolidate --input BENCHMARKS.md
```

| Verificación | Resultado al publicarse el curso | Qué significa |
|---|---|---|
| Entradas totales | **25** | una por fase, y la F24 no tiene propia |
| Escritas completas —hipótesis, condiciones, competidores, comando, filas— | **25** | el encargo está entero |
| Ejecutadas | **0** | los números los pone quien las corre |
| **Citas ilegales** —una fase que use una fila ⏳ o 🔜 como argumento— | **0** ✅ | es la verificación que protegía al curso de mentirse |
| Celdas 🔜 sin llenar | **0** ✅ | hubo una, la cuarta columna de la F14, y la llenó la F18 |
| Entradas marcadas 🪦 | **0** | ver abajo: no es que el curso no se equivocara |

> 🪦 **Por qué no hay ningún 🪦, dicho para que no se lea mal.** No es que ninguna medición haya contradicho a
> otra: es que **nada se ha ejecutado**. Las veinticuatro tablas están escritas completas y sus veredictos son
> **expectativas marcadas como tales** (§2.6), no resultados. **Ninguna cifra de este curso es inventada porque
> ninguna cifra de este curso existe todavía.**
>
> El primer 🪦 va a aparecer cuando alguien ejecute dos mediciones y la segunda contradiga a la primera. Cuando
> pase, la vieja **no se borra**: se marca, se le pone el puntero y se escribe qué cambió.
>
> Y la política para cuando eso ocurra, escrita antes de que a alguien se le ocurra otra cosa: **los números van
> aquí, con su fecha y su máquina** — no en los `.md` de las fases, que siguen enlazando a este archivo. Es el
> mismo mecanismo que la F14 y la F18 usaron para una sola columna, aplicado a las veinticuatro entradas.

> 🧭 **Y el dato que resume el archivo:** hay **una sola medición del curso que no está en ⏳**, y es esta —la
> verificación de arriba—, porque es la única que no necesita ejecutar código de Cordillera para dar un
> resultado. Que la última entrada del archivo sea la que comprueba las otras veinticuatro es deliberado.
