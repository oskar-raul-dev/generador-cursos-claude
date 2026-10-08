
---

### 🧬 Fase 01 — Tipos, valor y referencia, `record`, propiedades, igualdad

**Entra:** `class` frente a `struct` y qué significa de verdad la semántica de copia; propiedades
con `init` y `required`; `record` y `record struct`; igualdad estructural frente a igualdad de
referencia; `readonly`; sobrecarga de operadores donde el dominio la pide.

**No entra:** nullable (F02), LINQ (F03), genéricos más allá de lo obvio (F04).

**🪞 El reflejo:** el par `getTitle()`/`setTitle()` escrito a mano, `equals` y `hashCode`
sobrescritos a pares, y la creencia de que todo es referencia. **🩻 Se transfiere:** herencia,
interfaces, visibilidad, el diseño de objetos entero.

**💸 Deuda:** `Money` nace como un `decimal` desnudo, sin moneda. Se paga en la **F17**, cuando
la liquidación de regalías cruce tres monedas y el tipo tenga que llevarla dentro.

**📏 Medición:** `Isbn` como `class`, `record class` y `record struct` sobre un lote de un millón
de ediciones: asignaciones, pico de memoria y tiempo de comparación.

**🧱 Miniproyecto:** modelar `Title`, `Edition` y `StockItem` con igualdad correcta y un `Isbn`
que se valide al construirse, alimentado por el CSV del distribuidor mexicano. *La trampa:* el
`record` te da igualdad estructural gratis — hasta que dentro hay un arreglo, y entonces dos
ediciones idénticas dejan de ser iguales y nadie te avisa.

---

### 🕳️ Fase 02 — Nullable reference types y pattern matching

**Entra:** el contexto anulable y qué garantiza el compilador (y qué no); `?`, `!`, `??`,
`is not null`; `switch` de expresión; patrones de propiedad, de tipo y de lista; el análisis de
flujo y por qué a veces "sabe" más que tú.

**No entra:** validación en el borde de una API (F15), el esquema heredado (F07).

**🪞 El reflejo:** tratar `null` como un estado válido del dominio, traducir `Optional<T>`
mecánicamente, y silenciar con `!` lo que el compilador estaba diciendo bien. **🩻 Se
transfiere:** la disciplina de contratos que el lector ya escribe en javadoc.

**💸 Deuda:** dos `!` en el borde de datos, con el comentario de por qué están y su fecha de
cobro en la **F09**, cuando el mapeo del esquema heredado tenga un sitio donde decidirlo bien.

**📏 Medición:** cuántas advertencias produce activar el contexto anulable sobre el modelo de la
F01, **cuántas de esas eran bugs de verdad**, y cuánto tarda en apagarse el ruido.

**🧱 Miniproyecto:** convertir el resultado crudo de un procedimiento heredado —donde todo llega
anulable— en un modelo donde la ausencia significa algo, distinguiendo tres cosas que el sistema
confunde: `NULL`, la cadena vacía y el `'00000000'` que la importación de 2017 dejó en once
tablas. *La trampa:* el compilador te garantiza menos de lo que crees — los datos entran desde
fuera y el contexto anulable no los revisa.

---

### 🔁 Fase 03 ⭐ — LINQ y evaluación diferida

**Entra:** `IEnumerable` frente a `IQueryable`; ejecución diferida y ejecución inmediata; el
árbol de expresión y qué se traduce a SQL y qué no; `Select`, `Where`, `GroupBy`, `Join`; los
operadores que materializan y cuándo hacerlo a propósito.

**No entra:** EF Core como tal (F09), `IAsyncEnumerable` (F06).

**🪞 El reflejo:** Streams de Java traducidos línea por línea, materializar "por si acaso", y el
grande: **recorrer dos veces un `IEnumerable`** y ejecutar la consulta dos veces sin que nada lo
avise. En Java te lo dice una `IllegalStateException`; aquí, nadie. **🩻 Se transfiere:**
map/filter/reduce y el hábito de componer.

**💸 Deuda:** un `IQueryable` que se filtra en memoria porque el predicado no se puede traducir.
Se paga en la **F09**, midiendo las filas que viajaron de más.

**📏 Medición:** la misma consulta de catálogo resuelta con `IEnumerable`, con `IQueryable` y con
SQL directo: filas traídas, tiempo y asignaciones.

**🧱 Miniproyecto:** el reporte de ventas por sello y canal, escrito de forma que se pueda
demostrar **cuántas veces se ejecutó la consulta**. *La trampa:* el `.Count()` en medio del
pipeline, que parece gratis y vuelve a golpear la base.

---

### 🎩 Fase 04 — Ceremonia que sobra y ceremonia que falta

**Entra:** delegados, `Func`/`Action`, expresiones lambda y eventos; métodos de extensión;
genéricos reificados y qué cambia frente al borrado de tipos de Java; excepciones sin `checked`;
`IDisposable`, `using`, `IAsyncDisposable` y por qué los finalizadores casi nunca son la
respuesta. **Y el ciclo de vida de una prueba** (§10.3): instancia nueva por prueba,
`IClassFixture`, `[Theory]`/`[InlineData]`.

**No entra:** `async` (F05), inyección de dependencias (F15).

**🪞 El reflejo:** la interfaz de un solo método con su implementación anónima, la clase estática
`Utils`, el `catch (Exception)` que se traga lo que importaba, y el `@BeforeEach` sobre una
instancia compartida. **🩻 Se transfiere:** `try-with-resources` es `using`, casi exacto — y la
excepción se dice dónde se rompe: aquí nadie te obliga a declarar nada.

**💸 Deuda:** la conexión que se cierra en un `finally` escrito a mano, como la escribiría el
lector el primer día, con su reescritura a `using` en la misma fase. Es una deuda que **se paga
a la vista**, y sirve de ejemplo de cómo se lee un 💸.

**📏 Medición:** costo de lanzar una excepción en bucle frente a devolver un resultado, un millón
de veces — el número que decide cuándo una excepción es control de flujo caro.

**🧱 Miniproyecto:** un lector de los archivos de venta de los tres distribuidores, con
`IDisposable` correcto, política de errores explícita por tipo de fallo, y cierre garantizado si
se cancela a mitad. *La trampa:* uno de los recursos es `IAsyncDisposable`, y el `using`
sincrónico lo acepta sin quejarse y no lo cierra como crees.

---

### ⚙️ Fase 05 ⭐ — `async`/`await` de punta a punta

**Entra:** `Task`, `ValueTask`, el modelo de continuaciones; `CancellationToken` propagado;
`async` en la cadena completa y por qué romperla cuesta; paralelismo con límite; `Channel<T>` de
entrada; y **cómo se prueba código asíncrono** (§10.3).

**No entra:** el trabajo de fondo con colas (F17), la UI (F12).

**🪞 El reflejo:** `.Result` y `.Wait()`, `async void`, pensar en hilos en vez de en tareas, y
traducir `CompletableFuture` mecánicamente. **🩻 Se transfiere:** el razonamiento sobre
concurrencia, los límites de recursos, la idea de backpressure.

**💸 Deuda:** dos métodos sin `CancellationToken`, declarados. Se pagan en la **F17**, cuando el
cierre nocturno tenga que poder detenerse a mitad.

**📏 Medición:** throughput y número de hilos del mismo servicio con `.Result` frente a `await`,
bajo doscientas peticiones concurrentes. Es la medición que vuelve inolvidable la regla.

**🧱 Miniproyecto:** consolidar los archivos de los tres distribuidores en paralelo, con límite de
concurrencia configurable y cancelación limpia, y medir dónde deja de mejorar. *La trampa:*
`Parallel.ForEach` sobre trabajo de entrada/salida, que parece la herramienta obvia y es la
equivocada.

---

### 🧠 Fase 06 — Memoria, GC, `Span<T>` y flujo

**Entra:** generaciones del recolector y qué significa una pausa; asignaciones y cómo verlas;
`Span<T>` y `Memory<T>`; `stackalloc`; `IAsyncEnumerable` para procesar sin materializar;
`ArrayPool`.

**No entra:** AOT nativo (F20), perfilado de producción (F19).

**🪞 El reflejo:** optimizar sin medir, y cargar el archivo entero porque en la JVM con más heap
funcionaba. **🩻 Se transfiere:** todo el instinto de GC que el lector ya tiene; se dice
explícitamente que aquí sirve.

**💸 Deuda:** se **cobra** la de la F00 — el arnés pasa a medir asignaciones y colecciones por
generación, que hasta ahora no hacía.

**📏 Medición:** el reporte histórico de 500.000 filas, con lista materializada frente a
`IAsyncEnumerable`: pico de memoria, colecciones de generación 2 y tiempo hasta la primera fila.

**🧱 Miniproyecto:** parsear el archivo de ventas de 500.000 líneas sin asignar una cadena por
campo, y sostener el pico por debajo de un umbral medido. *La trampa:* `string.Split` asigna en
cada línea — y `Span<T>` no puede cruzar un `await`, que es justo lo que vas a querer hacer.
