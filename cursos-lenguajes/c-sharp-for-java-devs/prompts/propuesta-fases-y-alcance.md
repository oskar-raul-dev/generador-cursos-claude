# 🗺️ Propuesta de fases y alcance
## C# para desarrolladores Java senior

> **Estado: cerrado, y el curso está escrito (13/09/2026).** Las veinticinco fases de §4 son la numeración
> vigente, las once decisiones de §10 están tomadas, el libro de deudas de §7.1 está cuadrado y
> los dos acoplamientos —el del escritorio con la F18 (§8) y el de las deudas que convergen en la
> F20 (§7.1)— están resueltos por escrito, y **los dos se cerraron en la práctica**: la F18 llenó la
> cuarta columna del veredicto y la F20 cobró las tres deudas en la misma hoja de costos. Las
> versiones están verificadas y fijadas en `alcance-del-proyecto.md` §9.
>
> 🪦 **Dos cosas cambiaron al escribir y quedaron registradas aquí, no corregidas en silencio:** la
> versión del competidor del duelo (§10.5, Spring Boot 3 → 4.1.1) y el cierre del libro de deudas
> con seis tipos de cobro atípico que no estaban previstos (§7.1). Y la **F24 §4** admite dos
> decisiones de orden de este documento que, con el curso escrito, debieron ser otras — **no se
> corrigieron**, por la regla de bloqueo de contenido que este curso se impone.

Consolida lo que se decidió, fija la columna vertebral, y —ahora que el curso está escrito— deja
registrado qué se movió al escribirlo y qué no se pudo mover.

---

## 1. Lo que hace distinto a este curso

Cuatro rasgos que lo separan de un curso de lenguaje corriente, y que explican casi todas las
decisiones de abajo.

**El lector tiene que desaprender dos reflejos, no uno.** El de lenguaje —escribir C# con
estructura de Java— y el de arquitectura —reescribirlo todo o no tocar nada—. Un curso de
lenguaje ataca uno; este ataca los dos, y por eso tiene un bloque de lenguaje *y* un bloque de
sistema heredado.

> 🧭 **La pregunta que ordena todo el material: ¿esto se migra, se envuelve o se deja quieto?**

**No hay apéndices.** Todo lo que en otro curso sería material de consulta es aquí una fase o
una sección de fase. La razón completa está en `alcance-del-proyecto.md` §6; la consecuencia
práctica es que el ambiente —SDK, Visual Studio Community, NuGet, la guía rápida del IDE— **es
la Fase 00 entera** y no una nota al pie.

**Cada fase cierra con un miniproyecto difícil, y cada fase mueve un proyecto.** El
miniproyecto ocupa el lugar del cuaderno de incidentes de un curso de sistemas heredados; el avance de
proyecto es lo que impide que el curso se vuelva una colección de ejemplos. Las dos cosas son
obligatorias y las dos se declaran en el encabezado de la fase.

**El curso tiene una restricción que casi ningún curso se impone: no puede apagar el
sistema.** Cordillera factura todos los días mientras el lector migra. Eso convierte "vuelta
atrás en cada paso" en un requisito de diseño y no en una buena práctica, y descarta de entrada
cualquier fase que proponga una ventana de parada.

---

## 2. ✅ Decisiones cerradas

No se rediscuten en los chats siguientes; se dan por hechas.

| Pregunta | Decisión | Qué cambia |
|---|---|---|
| Eje del curso | **Migrar ⇄ envolver ⇄ dejar quieto** | La estructura en bloques, con el sistema heredado como pieza central ⭐ |
| Apéndices | **No hay** | El ambiente es la Fase 00; lo que no quepa en una fase se queda fuera con su razón escrita |
| Práctica por fase | **Un miniproyecto obligatorio**, difícil | Sustituye al cuaderno de incidentes; los ejercicios se quedan en la banda propia de 20-25 |
| Avance por fase | **Cada fase mueve al menos un proyecto** | Una fase que no avanza nada se replantea antes de escribirse |
| Empresa | **Cordillera Media** · el sistema es **SIGE** | Todo el dominio sale de `00-historia-de-cordillera.md` |
| Runtime objetivo | **.NET 10 (LTS) y C# 14** | Fijado en `alcance-del-proyecto.md` §9 |
| Runtime heredado | **.NET Framework 4.8, escrito como C# de 2017** (§10.2) | El curso lo escribe para después migrarlo; no se caricaturiza |
| IDE | **Visual Studio Community** principal; VS Code + C# Dev Kit y Rider como alternativas | Los tres en la Fase 00, sin apéndice |
| Esquema heredado | **Conserva sus nombres tal cual** | `MOVINVEN`, `VLRUNIT`, `BORRADO`; el mapeo vive en un borde 🧬 (guía §5.1) |
| Idioma del código | **Inglés** en lo nuevo; comentarios y mensajes en español | Guía §5 |
| Comparaciones | **Ninguna sin número** | Cada fase produce una medición 📏, y la excepción se justifica |
| Nube | **Medida contra lo que reemplaza**, sin suscripción de pago | Emulador local donde lo haya; precio publicado y declaración donde no |
| El sistema | **No se apaga nunca** | Toda migración es por partes y con vuelta atrás |
| Plataforma | **Windows 11, exclusivamente** | El legado es .NET Framework auténtico y el escritorio entra sin descuento; sin variantes por plataforma en ningún documento |

---

## 3. 🧱 Los bloques

```text
Bloque 0   El ambiente. Una fase.
Bloque A   El lenguaje y el runtime: C# sin acento de Java.
Bloque B ⭐ El sistema heredado y la frontera: leer, caracterizar, envolver, cortar, migrar.
Bloque C   El escritorio: qué pasa con los 340 formularios.
Bloque D   Servicios, datos y nube: donde .NET compite de frente.
Bloque E   Datos e IA aplicada.
Cierre     El duelo y el veredicto.
```

**El Bloque A existe porque el reflejo de lenguaje es real y es caro.** Un senior de Java
escribe C# el primer día y lo escribe mal durante dos años, sin que nada se rompa en la demo.
Siete fases para tipos de valor, nullable, LINQ perezoso, delegados, recursos, `async` y
memoria son exactamente lo que hace falta para que el bloque siguiente no se escriba con
acento.

**El Bloque B es la pieza central del curso.** No es un trámite de modernización: es el momento
en que el lector aprende a leer un sistema que no escribió, a caracterizarlo con pruebas antes
de tocarlo, a ponerle una API en medio, y a cortar por donde se puede volver atrás. Si el curso
funciona, es el bloque que el lector cita tres años después.

**El Bloque C es el que ningún otro ecosistema permite.** La pregunta *"¿qué hago con
trescientos cuarenta formularios y noventa personas que los usan todo el día?"* no tiene
equivalente en un curso de backend, y la respuesta honesta —*a veces, nada*— es de las más
difíciles de enseñar. Con el curso cerrado sobre Windows, este bloque deja de costar
portabilidad y pasa a ser simplemente una parte más del camino base. Ver §8.

**El Bloque D es donde .NET compite de frente** con lo que el lector ya sabe hacer, y donde las
mediciones dejan de ser curiosidades y empiezan a decidir arquitecturas — y facturas.

---

## 4. 🪜 La secuencia — 25 fases (00–24)

> 🧭 **Esta secuencia no es la de un curso de lenguaje con un bloque de nube pegado al final.**
> Se diseñó desde lo que este curso necesita, y la prueba está en las fases que aquí existen y
> en un tutorial de C# no tendrían sentido.

Lo que este curso necesita y otro de C# no:

- **Un sistema heredado que el propio curso escribe.** Las fases 07 y 08 no enseñan nada
  moderno: gastan su presupuesto en construir el trozo de SIGE que las fases 09-11 van a cortar.
  Sin eso, el bloque central sería un ensayo.
- **Una fase entera para leer setecientos procedimientos que nadie leyó.** Caracterizar con
  pruebas lo que no entiendes, antes de tocarlo, es una habilidad que no aparece en ningún
  temario de lenguaje y es la que separa una migración de un incendio.
- **Un bloque de escritorio.** Porque el sistema son 340 formularios y porque la respuesta
  legítima incluye *"se quedan en WinForms sobre .NET 10"*.
- **Una fase sobre la factura.** El *lift and shift* de 2020 costó un 30% más que el centro de
  datos que reemplazó y nadie se atreve a decirlo en junta. Eso es contenido, no anécdota.

⭐ marca las piezas de las que depende la tesis del curso.

### Bloque 0 · el ambiente

| # | Fase | Estilo | El reflejo que ataca 🪞 | Proyecto |
|---|---|---|---|---|
| 00 | 🛠️ Ambiente, Visual Studio y el mapa del ecosistema | nuevo | "el IDE me resuelve el proyecto" | **nace el arnés de medición** |

### Bloque A · el lenguaje y el runtime — C# sin acento de Java

| # | Fase | Estilo | El reflejo que ataca 🪞 | Proyecto |
|---|---|---|---|---|
| 01 | 🧬 Tipos, valor y referencia, `record`, propiedades, igualdad | nuevo | getters y setters a mano; `equals`/`hashCode` | **nace el modelo de dominio** |
| 02 | 🕳️ Nullable reference types y pattern matching | nuevo | `null` como estado válido; el `!` que silencia | modelo |
| 03 ⭐ | 🔁 LINQ y evaluación diferida: `IEnumerable` frente a `IQueryable` | nuevo | materializar todo; recorrer dos veces sin saberlo | modelo |
| 04 | 🎩 Ceremonia que sobra y ceremonia que falta: delegados, extensiones, genéricos, `IDisposable` — y el ciclo de vida de una prueba | nuevo | la interfaz de un solo método; el `catch (Exception)` que se traga lo que importaba; `@BeforeEach` | modelo |
| 05 ⭐ | ⚙️ `async`/`await` de punta a punta, `CancellationToken`, paralelismo — y cómo se prueba | nuevo | `.Result`, `async void`, pensar en hilos | modelo |
| 06 | 🧠 Memoria, GC, `Span<T>` y flujo con `IAsyncEnumerable` | nuevo | optimizar sin medir; cargar el archivo entero | modelo |

### Bloque B ⭐ · el sistema heredado y la frontera

| # | Fase | Estilo | El reflejo que ataca 🪞 | Proyecto |
|---|---|---|---|---|
| 07 | 🏚️ El sistema que heredas: SIGE, su esquema y su capa de datos de 2017 | heredado | "esto está mal hecho" en vez de "esto está fechado" | **nace SIGE** (existencias y regalías) |
| 08 ⭐ | 🔎 Caracterizar lo que no puedes leer: *golden master*, Testcontainers y cobertura útil | mixto 🧬 | reescribir antes de entender; traducir JUnit línea por línea | SIGE (entran catálogo y facturación) |
| 09 | 🗄️ Acceso a datos contra un esquema hostil: ADO.NET, Dapper y EF Core | mixto 🧬 | asumir que EF Core es Hibernate | **nace CatalogAPI** |
| 10 ⭐ | 🌿 *Strangler fig*: la API en medio, doble escritura, outbox y vuelta atrás | mixto 🧬 | el *big bang* de dos años y medio | SIGE + CatalogAPI |
| 11 | 🚚 Migrar el runtime: de .NET Framework 4.8 a .NET 10 | mixto 🧬 | migrar por versión en vez de por riesgo | SIGE |

### Bloque C · el escritorio — qué pasa con los 340 formularios

| # | Fase | Estilo | El reflejo que ataca 🪞 | Proyecto |
|---|---|---|---|---|
| 12 | 🪟 WinForms sobre .NET 10, y lo que de verdad cuesta salir de Framework | mixto 🧬 | "esto hay que reescribirlo sí o sí" | SIGE cliente |
| 13 | 🎛️ WPF y MVVM: la interfaz de escritorio moderna, con binding y pruebas | nuevo | el controlador que manipula controles | SIGE cliente |
| 14 | ⚖️ WinUI 3, Blazor Hybrid y el veredicto del escritorio | nuevo | elegir por modernidad en vez de por quién lo mantiene | SIGE cliente |

### Bloque D · servicios, datos y nube

| # | Fase | Estilo | El reflejo que ataca 🪞 | Proyecto |
|---|---|---|---|---|
| 15 | 🌐 ASP.NET Core: minimal APIs, validación en el borde, versionado y contrato | nuevo | validar en el servicio en vez de en la frontera | CatalogAPI |
| 16 | 🔐 Identidad, secretos y configuración: Entra ID, Key Vault, opciones tipadas | nuevo | la cadena de conexión en el `App.config` de 90 equipos | CatalogAPI |
| 17 | 🌙 Trabajo de fondo: `IHostedService`, colas, idempotencia y reanudación | nuevo | el proceso nocturno que se reinicia desde cero | **nace NightPress** |
| 18 | 🧵 Blazor Server ⇄ WebAssembly ⇄ MVC, medidos desde tres países | nuevo | elegir el modelo de render sin medir la latencia real | **nace Redacción** |
| 19 | 🔭 Observabilidad y operación: OpenTelemetry, logs, métricas, salud | nuevo | `MessageBox.Show` y el log rotado a mano | los cuatro |
| 20 ⭐ | 🐳 Contenedor, arranque en frío y **la factura**: VM, App Service, Container Apps, AKS | nuevo | adoptar PaaS sin costear el amarre | los cuatro |

### Bloque E · datos e IA aplicada

| # | Fase | Estilo | El reflejo que ataca 🪞 | Proyecto |
|---|---|---|---|---|
| 21 | 📊 Los datos que mienten: sell-in, sell-out, devoluciones, y servir un modelo con ONNX | nuevo | entrenar donde no se debe; creer el número del primer mes | NightPress |
| 22 | 🤖 IA aplicada: recuperación con cita obligatoria y triaje con herramientas | nuevo | montar el aparato vectorial antes de probar el full-text; dejar que el agente decida | **nacen AcervoRAG y EditorAgent** |

### Cierre

| # | Fase | Estilo | Qué hace |
|---|---|---|---|
| 23 ⚔️ | El duelo: CatalogAPI en ASP.NET Core y en Spring Boot | nuevo | Rendimiento, costo, productividad, contratación — y los empates admitidos como empates |
| 24 🏁 | ⚖️ Veredicto, defensa y qué no debió migrarse | — | La factura de 2020, "el Fox" de Lima, y las decisiones del propio curso que fueron erradas |

> 🪦 **Las dos fusiones que produjeron esta tabla** (decisión 10.1, cerrada): delegados y
> recursos quedaron en una sola fase —la 04—, porque las dos enseñan lo mismo desde lados
> distintos: dónde C# pide menos ceremonia que Java y dónde pide más. Y los dos proyectos de IA
> quedaron en la 22, porque comparten el aparato de evaluación y separarlos duplicaba la mitad
> del material. **No se fusionaron** 13+14, porque el veredicto del escritorio es el contenido
> del bloque y dentro de una fase de WPF se degrada a apéndice, ni 19+20, porque observabilidad
> más factura sería la fase más larga del curso.

---

## 5. 🪜 Las fases, una a una

Este es **el alcance literal de cada fase** y la fuente que consulta el chat que la escribe. Los
prompts de `prompts-de-fase.md` no lo repiten: lo citan.

### 🛠️ Fase 00 — Ambiente, Visual Studio y el mapa del ecosistema

Es la fase que más se aparta de lo que haría un curso normal, así que conviene dejarla escrita.
**No es un setup: es la primera lección de criterio del curso**, y termina con su propio
miniproyecto como cualquier otra.

**Qué entra:**

- **El SDK y el runtime**, y el problema real de tener varios: `dotnet --info`, `dotnet --list-sdks`, el `global.json` que fija la versión del SDK
  por repositorio, y por qué el SDK que responde en tu terminal casi nunca es el que crees.
- **Visual Studio Community**, que es el IDE principal del curso, con su **guía rápida de uso**
  adentro: qué cargas de trabajo instalar y cuáles no, el explorador de soluciones, el
  depurador —puntos de interrupción condicionales, ventana de inmediato, *hot reload*—, el
  explorador de pruebas, el perfilador y las ventanas de diagnóstico, y el atajo que ahorra
  cada uno. **Cuatro cosas bien, no cuarenta a medias.**
- **La CLI como la otra mitad del oficio.** `dotnet new`, `build`, `run`, `test`, `publish`, y
  la regla de que todo lo que el curso pide se puede hacer sin abrir el IDE — porque en CI no
  hay IDE.
- **La anatomía de una solución.** `.sln`, `.csproj` en formato SDK, `Directory.Build.props`,
  `.editorconfig`, y qué significa cada línea del `.csproj` que la plantilla genera. Aquí se
  fija de una vez el `<Nullable>enable</Nullable>` y las advertencias como errores.
- **NuGet completo, porque es donde este perfil se estrella.** Fuentes y `nuget.config`,
  versiones flotantes y por qué no, `PackageReference` frente al `packages.config` del sistema
  heredado, *Central Package Management* con `Directory.Packages.props`, `packages.lock.json`,
  restauración reproducible, y el cacheo local que explica el *"en mi máquina compila"*.
- **WSL 2 y el runtime de contenedores**, que es donde van a correr SQL Server, los emuladores
  de Azure y las pruebas con Testcontainers. Se instala aquí y no se vuelve a montar.
- **Los IDE alternativos**, sin condescendencia: **VS Code + C# Dev Kit** para quien vive en el
  terminal, y **Rider** con el mapa de equivalencias para quien viene de IntelliJ — dónde está
  cada cosa que ya sabía usar. Los dos corren en Windows, que es donde se toma el curso.
- **El mapa del ecosistema contra el de Maven**, que es la sección 🪞 de la fase:

  | Mundo Java | Mundo .NET | Dónde se rompe el paralelo |
  |---|---|---|
  | `pom.xml` / `build.gradle` | `.csproj` | Es un archivo de MSBuild: el proyecto **es** el build, no lo declara |
  | Maven Central | NuGet | Sin *groupId*; el nombre es de quien lo registra primero |
  | `~/.m2` compartido | caché global + restauración por proyecto | La reproducibilidad la da el lockfile, y hay que pedirla |
  | módulos de un `pom` padre | `.sln` y `Directory.Build.props` | La solución es del IDE; el build real es proyecto por proyecto |
  | `mvn test` | `dotnet test` | Sin ciclo de vida de fases: MSBuild ejecuta objetivos, no etapas |
  | JAR ejecutable | `dotnet publish` con sus modos | Autocontenido, dependiente del framework o AOT: tres respuestas distintas, y se eligen en la fase 20 |

**Qué NO entra:** el sistema heredado, la base de datos, los contenedores, la nube. Todo eso
llega cuando duela. La Fase 00 deja al lector con un SDK, una solución que compila, un IDE que
depura y un arnés de medición que va a usar veinticuatro veces.

**Su miniproyecto 🧱** no puede ser "instala Visual Studio", porque eso no es un encargo. La
propuesta es **el arnés del curso**: una herramienta de consola que ejecuta una operación N
veces, descarta el calentamiento, reporta mediana y percentil 95, pico de memoria administrada
y asignaciones totales, y escribe el resultado en el formato que `BENCHMARKS.md` espera. Sirve
de verificación de que la fase quedó bien, de primer contacto con la CLI y la depuración, y
**es la herramienta con la que se mide todo el resto del curso**.

> 🧭 **La regla que fija esta fase:** *si no lo puedes medir con el arnés, no lo afirmas.*

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

---

### 🏚️ Fase 07 — El sistema que heredas

**Estilo heredado.** Escribe el trozo de SIGE que el resto del bloque va a cortar: el **esquema
completo** de los cuatro módulos (§10.4) y **dos de ellos implementados** —existencias por
almacén y liquidación de regalías—, en .NET Framework 4.8 y C# de 2017.

**Entra:** el esquema con sus nombres reales (`MOVINVEN`, `LIQREGAL`, `VENTAS_1997`…`VENTAS_2026`,
`CAMPO1`…`CAMPO7`, `BORRADO char(1)`, fechas en `char(8)`, sin llaves foráneas); los
procedimientos almacenados que llevan la lógica; la capa de datos con `DataSet` y `SqlDataAdapter`;
la cadena de conexión en el `App.config`; el `UNION ALL` de treinta tablas construido concatenando
cadenas; y el **generador de datos sucios**.

**No entra:** ninguna mejora. Nada se arregla en esta fase, ni siquiera lo que duele.

**🪞 El reflejo:** leer esto y pensar *"está mal hecho"* en vez de *"está fechado"*. La fase
pone cada decisión junto a su año y su razón — el nombre de diez caracteres es del formato DBF,
la tabla por año es cómo se evitaba que el motor sufriera, el borrado por bandera es la semántica
de FoxPro. **🩻 Se transfiere:** SQL es SQL, y las transacciones también.

**💸 Deuda:** el módulo entero es deuda declarada, con fecha. Cada pieza dice en qué fase se
cobra: el acceso a datos en la F09, la conexión directa del cliente en la F10, el runtime en la
F11.

**📏 Medición:** el `UNION ALL` de treinta tablas — plan de consulta, lecturas lógicas y tiempo.
Es **la línea base contra la que se compara todo el bloque**, y por eso se toma aquí y no después.

**🧱 Miniproyecto:** escribir el generador de datos sucios, con semilla fija: 1.900 movimientos
cuyo título ya no existe, tildes comidas por la intercalación en los títulos peruanos, registros
con `BORRADO = 'S'` que media consulta olvida filtrar, y fechas `'00000000'`. *La trampa:*
generar datos limpios. Unos datos limpios harían fácil todo el bloque siguiente y el curso
perdería su material.

---

### 🔎 Fase 08 ⭐ — Caracterizar lo que no puedes leer

**Es la fase de pruebas del curso** (§10.3), y escribe los otros dos módulos —catálogo y
facturación— **mientras los caracteriza** (§10.4).

**Entra:** *golden master* sobre procedimientos que nadie leyó; cómo hacer determinista lo que
llama a `GETDATE()`; Testcontainers con SQL Server frente a los dobles; qué es **cobertura útil**
sobre código heredado, que no es el porcentaje; y **la mitad de integración del 📖 JUnit ⇄ xUnit**.

> 🪦 **El 📖 JUnit ⇄ xUnit va partido en dos, y se decidió al escribirlo.** El **ciclo de vida** —el
> constructor en vez de `@BeforeEach`, `[Theory]`/`[InlineData]`, `IDisposable`, el paralelismo por
> omisión— está en la **F04**, porque cae solo en la fase de `IDisposable` y repetirlo aquí sería
> relleno. La **F08** trae lo que allí no cabía: `ICollectionFixture` y `[Collection]`, Testcontainers
> —que el lector ya conoce de Java, y ahí el paralelo es casi exacto—, JaCoCo ⇄ coverlet,
> ApprovalTests ⇄ Verify, y la fila que más duele: **no existe el equivalente de `@Transactional` con
> rollback por prueba**.

**No entra:** refactorizar nada. La regla de la fase es *primero la red, después el trapecio*.

**🪞 El reflejo:** reescribir antes de entender, y traducir JUnit línea por línea. **🩻 Se
transfiere:** toda la disciplina de prueba que el lector ya tiene.

**💸 Deuda:** el *golden master* queda atado a un conjunto de datos concreto y se rompe si el
generador cambia de semilla. Se declara y se discute en la **F10**, donde la conciliación necesita
una forma más robusta de comparar.

**📏 Medición:** cobertura de línea frente a cobertura de rama sobre el procedimiento de
regalías, y el tiempo de la suite con contenedor por prueba frente a contenedor compartido.

**🧱 Miniproyecto:** caracterizar el procedimiento de liquidación —setecientas líneas— y
**encontrar la regla que la editorial cree que tiene y no aplica**. *La trampa:* el procedimiento
no es determinista, y hasta que eso no se resuelva ninguna prueba sirve de nada.

---

### 🗄️ Fase 09 — Acceso a datos contra un esquema hostil

**Entra:** ADO.NET, Dapper y EF Core midiéndose sobre el mismo esquema; mapeo explícito de
`char(8)` a `DateOnly`, de `BORRADO` a un filtro global y de la tabla por año a algo consultable;
entidades sin llaves foráneas; cuándo configurar EF Core a mano, cuándo rendirse y usar Dapper, y
cuándo lo correcto es **arreglar el esquema**.

**No entra:** la API pública (F15), las migraciones de esquema en producción (F11).

**🪞 El reflejo:** asumir que EF Core es Hibernate y que el ORM te va a abstraer de un esquema
hostil. **🩻 Se transfiere:** transacciones, índices, planes, el `N+1`.

**💸 Deuda:** se **cobran** las dos de la F02 y la de la F03 — el borde donde el `!` estaba
tapando una decisión, y el `IQueryable` que se filtraba en memoria.

**📏 Medición:** Dapper, EF Core con y sin seguimiento, y ADO.NET sobre la consulta de catálogo:
tiempo, asignaciones y líneas de código. Con el plan de consulta medido **antes**.

**🧱 Miniproyecto:** mapear `MOVINVEN` a un modelo limpio con el borde 🧬 en un solo sitio y
probarlo contra SQL Server en contenedor. *La trampa:* el filtro global de `BORRADO` que EF Core
aplica — y los tres sitios donde no lo aplica y nadie lo documenta.

---

### 🌿 Fase 10 ⭐ — *Strangler fig*

**Entra:** poner una API en medio sin apagar nada; doble escritura y conciliación; el patrón
outbox; bandera de corte por funcionalidad; **vuelta atrás demostrada**; y cómo se decide el
orden de los cortes por riesgo y no por gusto.

**No entra:** mover el runtime (F11), la nube (F20).

**🪞 El reflejo:** el *big bang* de dos años y medio —el que Clara rechazó en 2021— y su gemelo,
*"primero refactorizamos y después migramos"*. **🩻 Se transfiere:** versionado de contrato,
compatibilidad hacia atrás.

**💸 Deuda:** la doble escritura entra sin conciliación automática. Se paga en la **F17**, con el
outbox de verdad.

**📏 Medición:** latencia y tasa de error del camino nuevo frente al acceso directo, y
**divergencia medida** entre las dos escrituras durante la ventana de convivencia.

**🧱 Miniproyecto:** poner la API en medio para existencias, con doble escritura, bandera de corte
y una vuelta atrás que **se ejecuta de verdad** y se documenta. *La trampa:* la vuelta atrás que
no puedes ejecutar porque el dato que escribió el camino nuevo ya no cabe en el esquema viejo.

📝 Aquí va la sección del track `cv` (§10.7): la pieza que se envuelve sin tocarla es **Convivir**,
la plataforma Java que llegó con la adquisición de 2004.

---

### 🚚 Fase 11 — Migrar el runtime: de .NET Framework 4.8 a .NET 10

**Entra:** el `.csproj` en formato SDK; `packages.config` → `PackageReference`; el informe de
compatibilidad de APIs; qué compila y no existe en tiempo de ejecución; ASMX y `DataSet`
serializado hacia minimal APIs; qué hacer con Crystal Reports; y la migración **por riesgo**, un
proyecto a la vez, con los dos runtimes conviviendo.

**No entra:** los formularios (Bloque C), el contenedor (F20).

**🪞 El reflejo:** migrar por versión en vez de por riesgo, y creer que el código de negocio se
reescribe. **🩻 Se transfiere:** casi todo el código de dominio pasa sin tocarse, y decirlo
tranquiliza al lector.

**💸 Deuda:** un `packages.config` convertido a medias, con dos paquetes que no tienen equivalente
y se aíslan tras una interfaz. **No se paga en este curso**, y se explica por qué: la respuesta
depende de un proveedor.

**📏 Medición:** arranque, memoria y tamaño del publish del mismo servicio en 4.8 y en .NET 10.

**🧱 Miniproyecto:** migrar el módulo de facturación completo, entregando el informe de
compatibilidad y **la lista honesta de lo que no se pudo migrar**. *La trampa:*
`ConfigurationManager`, `HttpContext.Current` y las APIs que compilan contra el paquete de
compatibilidad y revientan en tiempo de ejecución.

> ⚠️ **Obligación de esta fase** (§10.2): decir en voz alta que **migrar desde 4.8 es más fácil
> que migrar desde 4.5**, y qué tendría de más el camino que Cordillera no tuvo que hacer.

---

### 🪟 Fase 12 — WinForms sobre .NET 10

**Entra:** llevar formularios de Framework a .NET 10 —diseñador, controles de terceros,
`ClickOnce` contra noventa equipos—; sacar la lógica del `Click`; mantener la interfaz viva
durante una consulta de ocho segundos; y el argumento honesto de por qué **quedarse en WinForms
es una opción legítima** en 2026.

**No entra:** MVVM (F13), el veredicto (F14).

**🪞 El reflejo:** *"esto hay que reescribirlo sí o sí"*. **🩻 Se transfiere:** el bucle de
mensajes y el hilo de interfaz son el mismo concepto de Swing o JavaFX.

**💸 Deuda:** la lógica de negocio sigue en el manejador del botón. Se paga en la **F13**, donde el
mismo formulario pasa a tener un modelo de vista comprobable.

**📏 Medición:** arranque en frío, memoria y tiempo de pintado de la grilla con 50.000 filas, en
Framework 4.8 frente a .NET 10.

**🧱 Miniproyecto:** migrar el formulario de existencias y hacer que responda durante la consulta
larga. *La trampa:* `async void` en el manejador de evento es **correcto aquí** — es la única vez
en todo el curso, y entender por qué es la lección.

---

### 🎛️ Fase 13 — WPF y MVVM

**Entra:** XAML lo justo; binding y `INotifyPropertyChanged`; comandos; el modelo de vista como
código **comprobable sin interfaz**; virtualización de listas; y qué de lo que el lector sabe de
MVC se traduce y qué no.

**No entra:** estilos y temas más allá de lo necesario; WinUI (F14).

**🪞 El reflejo:** el controlador que manipula controles por su nombre, y tratar el binding como
magia en vez de como un contrato. **🩻 Se transfiere:** separación de responsabilidades, pruebas
de lógica de presentación.

**💸 Deuda:** la lista entra sin virtualizar. Se paga en la **F14**, midiendo qué cuesta con
50.000 filas.

**📏 Medición:** el mismo formulario en WinForms y en WPF: arranque, memoria y fluidez con
50.000 filas.

**🧱 Miniproyecto:** el formulario de existencias en WPF, con el modelo de vista cubierto por
pruebas **sin levantar la interfaz**. *La trampa:* el binding que falla en silencio y solo
aparece en la ventana de salida del depurador.

---

### ⚖️ Fase 14 — WinUI 3, Blazor Hybrid y el veredicto del escritorio

**Entra:** un prototipo en WinUI 3 y otro en Blazor Hybrid, lo justo para medirlos; el empaquetado
y el despliegue a noventa equipos sin permisos de administrador; y **la comparación completa**.

**No entra:** construir la cuarta opción — la web nace después, en la F18, y la comparación se
cierra con lo que esta fase deja medido.

**🪞 El reflejo:** elegir por modernidad, y suponer que lo nuevo despliega mejor. **🩻 Se
transfiere:** el criterio de evaluar herramientas por su operación y no por su sintaxis.

**📏 Medición — la grande del bloque:** cuatro opciones × arranque, memoria, despliegue a noventa
equipos, comportamiento con la conexión del depósito de Lima, y **quién lo puede mantener**. Esa
última columna es la que decide, y su nombre propio es Duván.

**🧱 Miniproyecto:** el prototipo en WinUI 3 del mismo formulario y **la tabla de decisión
firmada**, con una recomendación para Cordillera que el lector defendería ante Clara. *La trampa:*
el despliegue. El prototipo sale en una tarde; ponerlo en noventa equipos es el problema real.

---

### 🌐 Fase 15 — ASP.NET Core: minimal APIs y contrato

**Entra:** minimal APIs frente a controladores; inyección de dependencias y tiempos de vida;
validación **en el borde**; DTO distintos de las entidades; versionado de contrato; OpenAPI;
paginación y filtrado; errores como respuesta y no como excepción.

**No entra:** identidad (F16), despliegue (F20).

**🪞 El reflejo:** validar dentro del servicio, el controlador con doce dependencias inyectadas, y
devolver la entidad del ORM directamente. **🩻 Se transfiere:** HTTP, REST, contratos, idempotencia.

**💸 Deuda:** el endpoint de catálogo sale sin paginación. Se paga en la **F20**, cuando la
factura muestre lo que cuesta servir el catálogo entero cada vez.

**📏 Medición:** minimal APIs frente a controladores: throughput, latencia y tiempo de arranque.

**🧱 Miniproyecto:** el endpoint de catálogo que **Grupo Almenara podría consumir de verdad**, con
validación en el borde, versionado y contrato publicado. *La trampa:* devolver la entidad de EF
Core directamente — funciona, y te ata el esquema heredado al contrato público para siempre.

---

### 🔐 Fase 16 — Identidad, secretos y configuración

**Entra:** Entra ID para el back-office y para los socios; autenticación y autorización basada en
políticas; `IOptions` y configuración tipada por ambiente; Key Vault y el equivalente local;
rotación; y qué hacer con la tabla de usuarios de 2017 cuyo hash da pena.

**No entra:** federación con el directorio del socio, declarado fuera.

**🪞 El reflejo:** la cadena de conexión en el `App.config` de noventa equipos, y el filtro de
seguridad casero. **🩻 Se transfiere:** OAuth 2 y OIDC, que el lector ya conoce.

**💸 Deuda:** **se cobra** la de la F07 — la cadena de conexión compartida sale del disco de los
noventa equipos, que es el objetivo entero de la fase.

**📏 Medición:** costo de validar un token con caché de claves frente a sin caché, bajo carga.

**🧱 Miniproyecto:** hacer que el servicio arranque **sin ningún secreto en disco**, con el
equivalente local en desarrollo y el gestionado en la nube, sin dos rutas de código distintas.
*La trampa:* el `appsettings.Development.json` que sí se commiteó, y lo que hay que hacer cuando
ya está en el historial.

---

### 🌙 Fase 17 — Trabajo de fondo: colas, idempotencia y reanudación

**Entra:** `IHostedService` y `BackgroundService`; el patrón outbox de verdad; idempotencia por
clave de operación; procesamiento por lotes reanudable; reintentos con retroceso; y auditoría
línea por línea.

**No entra:** las funciones durables, que se estudian en la F20 con su costo.

**🪞 El reflejo:** el proceso nocturno que se reinicia desde cero —el de Cordillera tarda seis
horas y falló dos veces en la hora cinco— y el reintento que duplica el cobro. **🩻 Se
transfiere:** todo lo que el lector sabe de mensajería.

**💸 Deuda:** **se cobran** las dos de la F05 (los métodos sin `CancellationToken`) y la doble
escritura sin conciliar de la F10.

**📏 Medición:** tabla de cola en SQL Server —la que Cordillera ya tiene y funciona— frente a
Service Bus: throughput, latencia y **costo mensual al volumen real**.

**🧱 Miniproyecto:** la liquidación trimestral reanudable por lotes, idempotente y auditable, con
**la tasa de cambio guardada junto al cálculo**; el criterio de aceptación es reproducir exacto un
número liquidado ocho meses antes. *La trampa:* reanudar sin idempotencia paga dos veces las
regalías del lote que iba a medias — y a alguien le llega el dinero.

---

### 🧵 Fase 18 — Blazor Server ⇄ WebAssembly ⇄ MVC

**Entra:** los tres modelos de render, la misma pantalla en los tres; estado y ciclo de vida de un
circuito; formularios y validación compartida con el servidor; auditoría de acceso; y la latencia
medida como criterio de arquitectura.

**No entra:** un framework de JavaScript, declarado fuera con su razón: no hay equipo de frontend.

**🪞 El reflejo:** elegir el modelo de render por moda y no por latencia, y suponer que SPA es
siempre la respuesta. **🩻 Se transfiere:** formularios, validación, sesiones.

**💸 Deuda:** la primera versión entra sin rastro de auditoría de quién vio qué. Se paga en la
**F19**, donde la observabilidad lo hace barato.

**📏 Medición:** latencia de interacción desde Bogotá, Ciudad de México y el depósito de Lima
—simulada con latencia y pérdida inyectadas—, peso de la carga inicial y memoria de servidor por
usuario conectado.

**🧱 Miniproyecto:** la pantalla de recepción de manuscritos, implementada en los tres modelos y
medida. *La trampa:* Blazor Server con la conexión de Lima. Va a funcionar perfecto en tu máquina.

---

### 🔭 Fase 19 — Observabilidad y operación

**Entra:** OpenTelemetry —trazas, métricas y logs—; correlación de una petición a través de la
API hasta el procedimiento heredado; logs estructurados; muestreo; comprobaciones de salud; y qué
se alerta y qué no.

**No entra:** el costo de ingestión, que se mide en la F20 con el resto de la factura.

**🪞 El reflejo:** `print` como log —en SIGE es un `MessageBox.Show` que quedó en producción en dos
formularios— y loguearlo todo por si acaso. **🩻 Se transfiere:** métricas, trazas, percentiles.

**💸 Deuda:** la telemetría entra sin muestreo. Se paga en la **F20**, en pesos.

**📏 Medición:** sobrecosto de la instrumentación sobre la latencia del endpoint, y volumen de
telemetría generado por día al tráfico real.

**🧱 Miniproyecto:** trazar una petición de CatalogAPI hasta el procedimiento almacenado y
**encontrar dónde se van los cuatro segundos**. *La trampa:* el log estructurado que, sin que
nadie lo decidiera, está registrando datos personales de los autores.

---

### 🐳 Fase 20 ⭐ — Contenedor, arranque en frío y la factura

**Entra:** imagen multi-etapa; configuración en tiempo de arranque; publish autocontenido,
dependiente del framework y **AOT nativo**; arranque en frío; y **la comparación de la factura**:
la máquina virtual que ya tienen, App Service, Container Apps y AKS, con su costo, su esfuerzo de
operación y su amarre.

**No entra:** orquestación avanzada, declarada fuera; es una especialidad con material propio.

**🪞 El reflejo:** adoptar PaaS sin costear el amarre, y elegir Kubernetes por defecto. **🩻 Se
transfiere:** Docker entero.

**💸 Deuda:** **se cobran** tres — la paginación de la F15, la cola en tabla de la F17 y el
muestreo de la F19. Las tres aparecen en la misma factura, que es exactamente la lección.

**📏 Medición — la grande:** cuatro destinos de cómputo × costo mensual al volumen real, arranque
en frío, esfuerzo de operación y dificultad de salida. Más JIT frente a AOT nativo.

**🧱 Miniproyecto:** contenerizar CatalogAPI, medir JIT frente a AOT y producir **la hoja de costos
de las cuatro opciones**, con la conclusión incómoda de que para Cordillera AKS es casi seguro un
error. *La trampa:* AOT rompe la reflexión de dos de las bibliotecas del proyecto, y el error no
aparece hasta el tiempo de ejecución.

---

### 📊 Fase 21 — Los datos que mienten, y servir un modelo con ONNX

**Entra:** separar honestamente sell-in, sell-out y devolución, por país, sello y canal, con tres
distribuidores de tres calendarios y dos plataformas que reportan en semanas ISO; la canalización
que prepara los datos; ML.NET presentado y evaluado; y **servir con ONNX Runtime un modelo
entrenado en Python**.

**No entra:** teoría de aprendizaje automático, y se declara — es un tema con bibliografía propia.

**🪞 El reflejo:** creer el número del primer mes, y entrenar donde no se debe por no salir del
ecosistema. **🩻 Se transfiere:** SQL analítico, ventanas, agregaciones.

**💸 Deuda:** el modelo se sirve sin versionar. **No se paga en este curso** y se dice por qué:
resolverlo bien es un registro de modelos, que es otro curso.

**📏 Medición:** ML.NET frente al modelo entrenado en Python y servido con ONNX —latencia,
precisión y esfuerzo—, y las dos contra **el baseline de Gustavo**, que lleva treinta y un años
decidiendo tirajes mirando la portada y el mes.

**🧱 Miniproyecto:** la canalización que separa los tres tipos de venta con calendarios distintos y
sirve la predicción de tiraje dentro del sistema. *La trampa:* las devoluciones llegan hasta el
30% y aparecen meses después — el número de marzo cambia en julio, y un modelo entrenado sin eso
aprende una mentira estacional.

> ⚖️ El veredicto de esta fase está decidido de antemano y el curso lo dice sin rodeos: para este
> trabajo, lo honesto es entrenar en Python y servir desde .NET.

---

### 🤖 Fase 22 — IA aplicada: recuperación con cita y triaje con herramientas

**Nacen los dos proyectos de IA** (§10.1): AcervoRAG y EditorAgent comparten el aparato de
evaluación, y por eso comparten fase.

**Entra:** ingesta de contratos escaneados; fragmentación y recuperación; **la cita obligatoria**
—documento, versión y cláusula, o no se responde—; un agente con herramientas que llama a
CatalogAPI; la ficha de triaje estructurada; y **evaluación de verdad**, con conjunto de prueba y
métricas.

**No entra:** afinado de modelos; entrenamiento; y el aparato de agentes más allá de lo que este
caso necesita.

**🪞 El reflejo:** montar el aparato vectorial antes de probar si la búsqueda de texto completo ya
resolvía, y dejar que el agente **decida** en vez de preparar la decisión de una persona.
**🩻 Se transfiere:** contratos, evaluación, pruebas.

**💸 Deuda:** sin caché de embeddings. Se paga a la vista, dentro de la misma fase, midiendo la
factura de reindexar.

**📏 Medición:** búsqueda de texto completo de SQL Server, búsqueda vectorial del propio SQL Server
y Azure AI Search: precisión y exhaustividad sobre un conjunto de treinta preguntas reales de
derechos, latencia y costo. **Con la posibilidad admitida de que el texto completo gane.**

**🧱 Miniproyecto:** el sistema que responde *"¿tenemos los derechos en portugués de este título
para Brasil?"* citando la cláusula, o **se niega a responder**. *La trampa:* la pregunta cuya
respuesta correcta es "no tenemos esos derechos" — el recuperador siempre encuentra algo parecido,
y una alucinación sobre un contrato no es una molestia: es una demanda, y la presidenta es
abogada.

📝 Aquí va el veredicto sobre **Semantic Kernel**: cuándo aporta orquestación real y cuándo es una
capa que te cobra abstracción sin devolverte nada frente a llamar al SDK directamente.

---

### ⚔️ Fase 23 — El duelo: ASP.NET Core contra Spring Boot

**Entra:** el endpoint crítico de CatalogAPI implementado **dos veces**, con las dos
implementaciones defendibles en una revisión de código, y la comparación completa: rendimiento,
arranque en frío, memoria, costo mensual al volumen de Cordillera, líneas de código, y facilidad
de contratar a quien lo mantenga en el mercado del lector.

**No entra:** un tercer competidor. Diluye la comparación y alarga la fase (§10.5).

**🪞 El reflejo:** comparar contra un competidor de paja, que es el reflejo de todo el que quiere
que gane su equipo. **🩻 Se transfiere:** todo — es el terreno donde el lector es experto, y eso
hace la comparación más honesta, no menos.

**📏 Medición:** la del curso entero, consolidada. Y **los empates se publican como empates**
(`formato-de-mediciones.md` §2.4): al volumen de Cordillera varias columnas van a quedar dentro
del ruido, y esa es la conclusión, no un fracaso de la medición.

**🧱 Miniproyecto:** implementar la contraparte en Spring Boot (4.1.1, ver §10.5) y publicar la tabla. *La trampa:*
escribir un Spring Boot que tú no defenderías — sin pool configurado, sin caché, con el
serializador por defecto — y creer que mediste algo.

---

### 🏁 Fase 24 — Veredicto, defensa y qué no debió migrarse

**Entra:** la revisión de todas las decisiones del curso con los datos en la mano; el árbol de
decisión ⚖️ de cuándo **no** usar lo que el curso enseña; el checklist que el lector se lleva al
trabajo; y la tabla consolidada de `BENCHMARKS.md`.

**Lo que esta fase está obligada a admitir**, y sale de §14 de la historia:

- El *lift and shift* de 2020 fue un error, cuantificado con la factura y sin absolver a nadie
  —tampoco a quien lo aprobó por miedo, que es la razón real por la que se hizo así—.
- **Parte del sistema no debió migrarse.** El módulo de inventario funciona, no cambia, y "el Fox"
  de Lima lleva veintinueve años funcionando y puede llevar tres más.
- **La migración de los pasantes de 2016 fue, en el balance, correcta.** Fue barata, salió, y
  compró diez años.
- Y **dos decisiones del propio curso que, con los datos delante, debieron ser otras.**

**📏 Medición:** no produce una propia; consolida las veinticuatro anteriores y marca 🪦 las que
una medición posterior contradijo.

**🧱 Miniproyecto:** el documento de defensa ante la junta — qué se migró, qué no, qué costó, qué
queda pendiente y con qué riesgo—, en el lenguaje de Clara y no en el de un ingeniero. *La trampa:*
escribir un informe donde .NET moderno gana todo. Si sale así, está mal hecho, y el curso lo dice
en su última línea.

---

## 6. 🧳 Qué se absorbió de lo que habría sido apéndice

Para que la decisión de "sin apéndices" sea auditable, conviene dejar la lista de lo que en
otro curso habría tenido su `aNN-` y dónde quedó aquí:

| Habría sido apéndice | Dónde vive |
|---|---|
| Instalación del SDK y gestión de versiones | Fase 00 |
| Guía rápida de Visual Studio y su depurador | Fase 00 |
| Rider y VS Code para quien viene de IntelliJ | Fase 00 |
| NuGet, lockfiles y *Central Package Management* | Fase 00 |
| Diccionario Java ⇄ C# | 📖 repartido: cada fase trae el suyo, del tema que enseña |
| `async`/`await` de referencia | Fase 05, con su medición |
| Pruebas: marco, ciclo de vida y dobles | Repartido en F00, F04 y F05; la fase de pruebas de verdad es la F08 (§10.3) |
| EF Core de referencia | Fase 09, contra el esquema hostil, que es donde se aprende de verdad |
| Docker y despliegue | Fase 20, junto a la factura, porque separar las dos cosas es lo que produce el *lift and shift* |
| Convención de git y tags | `00-convencion-de-git-y-tags.md`, en la raíz del curso — no es apéndice, es un documento de encuadre que el lector sí lee |

---

## 7. 💼 Los proyectos que atraviesan el curso

Ninguno se toca desde los miniproyectos (`formato-de-miniproyectos.md` §5). Los cuatro
primeros salen de §8 de la historia; los dos de IA, de §9.

| # | Proyecto | Qué es en Cordillera | Nace |
|---|---|---|---|
| 1 ⭐ | **SIGE, por partes** | El sistema entero: sacar la lógica de los procedimientos, cortar la conexión directa del cliente a la base, y solo entonces mover el runtime. Es el eje | F07 |
| 2 | **CatalogAPI** | El catálogo hacia afuera, que hoy son cuatro volcados CSV nocturnos desincronizados. El ultimátum de Grupo Almenara le puso fecha | F09 |
| 3 | **Redacción** | El back-office editorial: cuarenta pantallas, roles y auditoría, con Nohora de usuaria real y Ximena vigilando que no le agregues un paso | F18 |
| 4 | **NightPress** | El cierre de regalías: reanudable, idempotente y auditable línea por línea, porque dos veces al año un autor impugna | F17 |
| 5 | **AcervoRAG** | Cuarenta y seis años de contratos de derechos, con la regla que lo hace valioso: cada respuesta cita documento, versión y cláusula, o no se emite | F22 |
| 6 | **EditorAgent** | El triaje de los 400 manuscritos no solicitados que llegan al mes. No decide: prepara para que decida una persona | F22 |

**El cliente de escritorio no es un proyecto aparte**: es el frente de SIGE, y el Bloque C
decide qué se hace con él.

### 7.1 💸 El libro de deudas

Cada 💸 declara dónde se paga (guía §7.1), y un 💸 sin destino es un error de escritura. Aquí está
el libro completo, para que ninguna se pierda y para que cada fase sepa qué le toca cobrar.

| Deuda | Nace | Se paga | Qué demuestra al cobrarse |
|---|---|---|---|
| El arnés no aísla el recolector | F00 | **F06** | Que una medición de tiempo sin asignaciones cuenta media historia. **Es la única deuda del curso que se cobra extendiendo el instrumento** y no cambiando código medido, y por eso su factura abarca seis fases |
| `Money` es un `decimal` sin moneda | F01 | **F17** | Que el tipo del dominio tiene que llevar dentro lo que el negocio no puede perder. **Dieciséis fases de distancia y un diff de treinta líneas:** es el mejor argumento de que una deuda declarada no crece — lo que crece es el costo de no declararla, y de eso no hay diff |
| Dos `!` que tapan una decisión | F02 | **F09** | Que el borde de datos es el sitio donde la nulabilidad se decide, no se silencia |
| Un `IQueryable` filtrado en memoria | F03 | **F09** | Las filas que viajaron de más, contadas. **La unidad de cobro son filas, no milisegundos** — es lo que hace la factura convincente |
| El `finally` escrito a mano | F04 | **F04**, a la vista | Cómo se lee y se cobra un 💸 — es el ejemplo del mecanismo, y su factura queda escrita en el bloque 🏷️ de la fase |
| Cierre sincrónico del escritor de auditoría | **F04, en su miniproyecto** | **F05** | Que un tipo con `IDisposable` y `IAsyncDisposable` no se cierra igual de las dos formas: el `using` sincrónico compila, no se queja y pierde el búfer pendiente |
| Dos métodos sin `CancellationToken` | F05 | **F17** | Que un proceso que no se puede detener no es reanudable. El argumento con que se justifican —*"tarda milisegundos"*— **es parte del material**: la F17 lo cita textualmente para desmontarlo, porque la duración no es una propiedad del método sino de los datos |
| La cadena de conexión en 90 `App.config` | F07 | **F16** | El cobro más antiguo del curso, y el más satisfactorio. Su pago consistió en **quitar una necesidad y no en satisfacerla mejor**, y fue posible por el corte de la F10 — así que es un argumento de arquitectura y no de seguridad. La factura son **dos caminos**: `legacy/Sige.DataAccess` y `modern/Sige.Forms` |
| El acceso a datos con `DataSet` | F07 | **F09** | **Se cobra sin tocar el código viejo:** la alternativa se construye al lado y se mide. Su factura es un `git diff` **vacío a propósito**, y es el primer sitio del curso donde *"se envuelve"* es la respuesta y hay que poder mostrarlo |
| La conexión directa del cliente a la base | F07 | **F10** | Que mientras 90 equipos escriban en todo, lo demás es cosmético |
| El runtime 4.8 | F07 | **F11** | **Se cobra en parte y a propósito:** un módulo de cuatro. Las otras tres partes son decisión y no pendiente, y la fase lo dice — si no, la tabla sugiere que quedó a medias por falta de tiempo |
| ↳ *las cuatro de la F07 nacen en el mismo tag* | F07 | F09·F10·F11·F16 | Y por eso las cuatro facturas son comparables entre sí: `git diff fase-07 fase-NN` mide cada corte contra el mismo punto de partida |
| *Golden master* atado a una semilla | F08 | **F10** | Que comparar salidas no es lo mismo que conciliar estados. Su factura es **código agregado y no borrado**: las fotos siguen sirviendo para lo que sirven, y lo que se agregó es la conciliación por invariantes para lo que no alcanzaban. **Es la única deuda del curso que vive en las pruebas y no en el sistema**, y sirve para decir que una suite frágil se paga igual que un módulo frágil |
| Doble escritura sin conciliación | F10 | **F17** | El outbox, y la divergencia medida. **La deuda trae su propia unidad de medida:** la categoría *"fallo del camino nuevo sin escritura"* de la medición de la F10 es lo que dimensiona el outbox |
| `packages.config` convertido a medias | F11 | **nunca** | Que "depende de un proveedor" es una respuesta legítima y hay que saber darla. **La forma concreta es la parte reutilizable:** aislar tras una interfaz —`IReportRenderer`— y dejar el proceso viejo corriendo en 4.8 indefinidamente |
| Lógica de negocio en el `Click` | F12 | **F13** | Que MVVM se justifica con las pruebas corriendo, no con un diagrama. **Es la deuda de distancia más corta del curso** —una fase— y a propósito: el diff entre los dos tags es el argumento entero del patrón, y solo es legible porque la migración de runtime fue un commit aparte |
| El total y el conteo de huérfanos, calculados en el modelo de vista | F13 | **F15** | Que la lógica de negocio no es de la pantalla: el modelo de vista debería **pedirla**, no calcularla. Nace como hallazgo de un ejercicio de la F13 y se declara en vez de quedar como curiosidad |
| Lista sin virtualizar | F13 | **F14** | Qué cuesta, con 50.000 filas. **Se cobra midiendo el error y no arreglándolo**: es el tercer tipo de cobro atípico del curso, después del diff vacío de la F09 y el código agregado de la F10 |
| Catálogo sin paginación | F15 | **F20** | En pesos. **Es la única deuda del curso cuyo cobro depende de un tercero:** retirar el volcado completo exige que Almenara cambie su integración, y eso solo se pide con la factura en la mano |
| Cola en tabla en vez de mensajería | F17 | **F20** | En pesos, contra el statu quo que ya funciona. **Y es la deuda que puede terminar en "el atajo se queda"**: si al volumen de Cordillera la tabla gana, el diff queda vacío a propósito y la deuda se paga *entendiendo el costo* en vez de eliminándolo. Eso **confirma que el cuarto tipo de cobro existe** y no era una excepción de la F09 |
| Telemetría sin muestreo | F19 | **F20** | En pesos. **El porcentaje no se elige por gusto:** sale del volumen medido por la F19 y del precio publicado, y tiene un piso que no es económico — *cuánto muestreo soporta la pregunta que la telemetría tiene que contestar*. Muestrear por debajo de eso es pagar por telemetría inútil, que es peor que no pagar |
| Sin auditoría de quién vio qué | F18 | **F19** | Que la observabilidad la vuelve barata. **Es el único cobro del curso de una deuda que se abarató por esperar** —un quinto tipo, y el mejor argumento de que el orden de las fases no es arbitrario—: con la telemetría montada, la auditoría de acceso son veinte líneas; escrita en la F18 habría costado diez veces más y se habría tirado aquí. Con un límite que hay que decir en voz alta: **la respuesta solo existe hacia adelante**, y la pregunta del incidente de marzo —qué vio ese traductor en dos años— no se reconstruye |
| Modelo servido sin versionar | F21 | **nunca** | Que un registro de modelos es otro curso, y decirlo es mejor que fingirlo. **Y la mitad barata sí se hace:** queda la huella del archivo en cada predicción, de modo que *"¿este número de qué modelo salió?"* tiene respuesta. Eso separa una deuda declarada de un descuido |
| Sin caché de embeddings | F22 | **F22**, a la vista | La factura de reindexar. **Distancia cero, pagada con un decorador en el mismo tag** — sexto tipo de cobro atípico, y el contraste con `Money` (dieciséis fases) dice que la distancia de una deuda es una decisión y no una consecuencia. Y el pago dejó el hallazgo: **la caché no sirve de nada el día que cambia el modelo de embeddings**, que es justo cuando más falta hace |

> 📝 **Una deuda nació en un miniproyecto y no en la sección 5** —el cierre sincrónico de la F04— y
> eso no estaba previsto. 🪦 **Queda permitido y declarado como norma:** una deuda que nace donde el
> lector se estrella se entiende mejor que una que se le señala. La condición es la misma que para las
> demás: destino escrito y cobro verificable.

> 🧭 **La F20 cobra tres a la vez** —paginación, cola en tabla y muestreo— y las tres aparecen en
> la misma hoja de costos. **Esa acumulación es deliberada**: las decisiones cómodas de tres fases
> distintas se pagan juntas y en un solo número, que es exactamente lo que le pasó a Cordillera
> en 2020 y lo que nadie se atreve a decir en junta.
>
> **Y lo que une a las tres, que es la lección y quedó escrito así en la fase:** ninguna tiene
> síntoma técnico. Las tres funcionan, ninguna aparece en una traza, en una prueba ni en un
> percentil, y **las tres crecen con el uso** — así que el día que a Cordillera le vaya mejor, las
> tres cuestan más. Es el mismo mecanismo del 30% de 2020 operando sobre código de 2026, y esa
> simetría es el punto entero de la F20.

> 🏁 **Cerrado al escribir la F24: veintitrés deudas y todas con estado final.** Veintiuna pagadas
> —tres de ellas en una sola factura, la de la F20— y **dos que no se pagan nunca, con su razón
> escrita**: el
> `packages.config` de Crystal Reports (F11), porque el proveedor no da una versión moderna, y el
> modelo sin versionar (F21), porque un registro de modelos es otro curso. Que las dos aparezcan en
> el documento de defensa de la F24 **con su riesgo y su cifra** es lo que las convierte en
> decisiones en vez de omisiones.
>
> Y el recuento final de tipos de cobro atípico es **seis**, ninguno planeado: diff vacío a propósito
> (F09), código agregado en vez de quitado (F10), pagar midiendo el error (F13→F14), parcial a
> propósito (F11), **abaratada por esperar** (F18→F19) y **distancia cero con un decorador** (F22).
> Que los seis aparecieran solos, al escribir, es el mejor argumento de que el libro de deudas era
> una buena idea: si las deudas se hubieran pagado todas igual, no habría hecho falta el libro.

> 🧭 **Y con la F20 el libro gana cinco tipos de cobro atípico, no cuatro.** Los cuatro que ya
> estaban —diff vacío a propósito (F09), código agregado en vez de quitado (F10), pagar midiendo el
> error (F13→F14), parcial a propósito (F11)— más el que aporta la F19: **la deuda que se abarató
> por esperar**. Ese quinto justifica retroactivamente el orden del curso, y conviene que la F24 lo
> retome: no todas las deudas conviene pagarlas temprano, y saber cuáles es criterio, no pereza.

---

## 8. 🪟 El escritorio: sí, y por qué

La pregunta era si el curso debía incluir escritorio. La respuesta, ya cerrada, es **sí, con un
bloque de tres fases** (12-14), y los argumentos son concretos:

- **El sistema heredado son 340 formularios WinForms.** Un curso de migración que evite el
  escritorio deja fuera la mitad del problema y termina enseñando la parte fácil.
- **La respuesta honesta a veces es "no lo toques".** WinForms sobre .NET 10 sigue siendo una
  opción legítima, y decirlo en voz alta —con la medición al lado— es exactamente el tipo de
  veredicto que este curso existe para producir. Un bloque de escritorio que terminara siempre en
  "reescribe en web" no haría falta.
- **Es lo que este ecosistema permite y otros no.** Comparar WinForms, WPF, WinUI 3 y web sobre
  el mismo módulo, con el mismo arnés, es una comparación que un curso de Java no puede hacer.
- **Y hay una lección de diseño que solo aparece aquí:** noventa personas con un formulario
  abierto ocho horas al día en una oficina de Lima con mala conexión imponen restricciones que
  un backend puro no tiene.

**Y con el curso cerrado sobre Windows, este bloque ya no cuesta nada.** En la versión anterior
de este documento el escritorio era la única parte del material que excluía lectores, y eso
obligaba a delimitarlo y a marcarlo. Ahora es una parte más del camino base, y el presupuesto
que se iba en advertencias de portabilidad se gasta en medir.

La forma: **el mismo módulo, implementado tres veces**. Se elige uno de los formularios de
SIGE —la consulta de existencias por almacén, que tiene búsqueda, grilla con volumen real,
edición y un reporte— y se construye en WinForms sobre .NET 10 (F12), en WPF con MVVM (F13) y
como prototipo en WinUI 3 (F14). La fase 14 cierra midiendo las cuatro opciones —las tres de
escritorio más la web que nacerá en la F18— contra lo que de verdad importa:
arranque, memoria, despliegue a 90 equipos, comportamiento con la conexión de Lima, y **quién
lo puede mantener cuando el lector se vaya**, que es la columna donde Duván decide la
discusión.

> ⚖️ El veredicto de este bloque está abierto de verdad y el curso no lo prejuzga. Lo que sí
> está decidido es que se mide antes de opinar.

**El acoplamiento con la F18, resuelto.** La cuarta opción —la web— nace catorce fases después de
que el bloque de escritorio la necesite, y eso tenía que quedar zanjado antes de escribir nada:

- **La F14 congela la metodología** —los cinco criterios, el módulo medido, las condiciones de
  red— **y publica la tabla con tres columnas llenas y la cuarta declarada pendiente**, no vacía
  ni estimada. El lector cierra el bloque con un veredicto provisional explícito y con la fecha
  en que se completa.
- **La F18 rellena esa columna con la misma metodología, sin rediscutirla.** Es **la única
  actualización retroactiva permitida en el curso**: cualquier otra sería una contradicción entre
  fases, y ésta está declarada de antemano en los dos sitios.
- 🪦 **Y el mecanismo quedó decidido al escribir la F14:** la tabla del veredicto **se consolida en
  `BENCHMARKS.md`** y el documento de la F14 enlaza a esa entrada. La F18 completa la columna
  **allí**, no editando el `.md` publicado de la F14. Así el material que el lector leyó no cambia
  bajo sus pies y la tabla sí crece — que es exactamente cómo funciona una medición consolidada, y
  evita el único caso del curso en que una fase tendría que editar el documento de otra.
- La metodología congelada es: **los cinco criterios, el módulo medido (el formulario de
  existencias), el volumen (50.000 filas), las condiciones de red (las tres oficinas, con Lima como
  caso adverso) y la memoria medida a las ocho horas.** Si la F18 cambia alguna, las tres columnas
  de la F14 quedan incomparables y la tabla no vale nada.
- Si el veredicto provisional de la F14 cambia al entrar la columna de la web, **la F18 lo dice y
  explica qué lo movió**. Un veredicto que cambia con un dato nuevo no es un error del curso: es
  el curso funcionando.

> ✅ **Cerrado en la práctica, no solo en el plan.** La F18 completó la columna en la entrada
> consolidada de `BENCHMARKS.md` —las celdas 🔜 pasaron a ⏳— y el `.md` de la F14 quedó intacto, que
> era el punto del mecanismo. Hubo **una adaptación, declarada**: la F18 construye la recepción de
> manuscritos, y el módulo medido de la F14 es el formulario de existencias, así que esa pantalla se
> construye **también** en el modelo de render ganador. Rellenar la columna con los números de otra
> pantalla habría sido romper la comparación por comodidad — que es exactamente lo que la
> metodología congelada existe para impedir, y por eso la adaptación consiste en trabajo adicional
> y no en una excepción.
>
> Y la F18 agregó **un cuarto umbral** a la entrada de la F14: a partir de qué latencia de ida y
> vuelta un modelo de render interactivo deja de sentirse instantáneo. Es el único umbral del curso
> que se determina **sintiéndolo** y no midiéndolo, y está justificado en la propia fase: la pregunta
> —*¿se puede trabajar ocho horas con esto?*— no la contesta un percentil. 🪦 Queda declarado como
> legítimo, con la misma condición que la fila de "¿cuánto le costó a Duván?": condiciones escritas y
> resultado reproducible.

### 8.1 🔗 El otro acoplamiento declarado: la F03 con la F09

El mismo mecanismo, por la misma razón, en otro sitio del curso. El alcance de la **F03** pide
comparar la misma consulta con `IEnumerable`, con `IQueryable` y con SQL directo — y **no hay base de
datos hasta la F07**, así que dos de los tres competidores no existen cuando esa fase se escribe. El
curso no inventa infraestructura para medir.

- **La F03 mide lo que puede sostener con datos**: las cuatro formas de escribir el mismo reporte
  sobre el catálogo en memoria, con el número de recorridos verificado por un contador. Y publica el
  dato que la F09 va a necesitar: **cuánto cuesta un recorrido del catálogo**.
- **La F09 completa la comparación** de `IQueryable` contra SQL directo con la misma metodología, y
  **cobra allí la deuda 💸** del predicado que no se pudo traducir. Su entrada de `BENCHMARKS.md` lo
  dice.
- Si la F09 no la recoge, la F03 queda debiendo un número que su propio alcance prometía, y eso es un
  defecto del curso y no una simplificación.

> 🧭 **Son los dos únicos acoplamientos declarados del curso** —F14 con F18, F03 con F09— y los dos
> están escritos en las dos fases. Cualquier tercero que aparezca al escribir se declara aquí antes
> de cerrar el chat, o es una contradicción entre fases disfrazada de continuidad.

---

## 9. 🧩 Tracks opcionales

Fuera del camino base y declarados como tales. Salen de §12 de la historia, cada uno es un área
real de Cordillera, y se escriben —si se escriben— después de cerrar el camino base, con el
mismo criterio de forma: sin apéndices, un miniproyecto por fase, su propio prefijo de archivo.

| Track | El área que lo pide | Lo que necesita |
|---|---|---|
| `ui` | Comercial y dirección | El tablero de ventas que hoy es un Excel por correo, y la presentación de junta **generada** |
| `ar` | Producción | Portadas en seis formatos, PDF de imprenta contra PDF de web, EPUB para cuatro tiendas incompatibles, y los metadatos ONIX 3.0 |
| `au` | Inteligencia comercial y QA | Qué publicó la competencia y a qué precio, pruebas e2e de la tienda, y el servidor de la imprenta que solo habla SSH |
| `db` | La deuda de las adquisiciones | El MySQL de la web vieja, MongoDB con eventos de lectura digital, y Valkey delante del catálogo — todo contra el SQL Server ya pagado |
| `cv` | Lo que no vas a migrar | **Convivir**, la plataforma Java de la Universitaria del Bajío, y **"el Fox"** de Lima: sistemas vivos a los que hay que hablarles sin tocarlos |

📝 El track `cv` es el que más se parece a la vida real del lector después del curso. Está como
opcional, pero conviene discutir si una versión reducida debería entrar al camino base: la
mitad de las empresas que adoptan .NET moderno lo hacen con algo en Java al lado que nadie va a
apagar. Ver §10.7.

---

## 10. 🚦 Las decisiones, todas cerradas

🪦 **No queda ninguna decisión abierta.** Las once se resolvieron y quedan aquí con su porqué,
porque la razón de una decisión vale más que la decisión. Lo único que sigue pendiente es
**verificar versiones exactas contra las notas oficiales al escribir la Fase 00** (§10.9), que no
es una decisión sino un trámite que no se hace de memoria.

**10.1 · 🪦 Cerrada: veinticinco fases.** Se fusionaron 04+05 (ceremonia y recursos) y los dos
proyectos de IA en la 22. Quedan separadas el veredicto del escritorio y la fase de la factura,
por las razones que están al pie de la tabla de §4. La numeración de §4 es la vigente y ninguna
fase se renumera por su cuenta.

**10.2 · ¿En qué versión exacta del .NET Framework se escribe el legado?** 🪦 *La pregunta
anterior —cómo darle Framework a un lector que no está en Windows— quedó sin objeto: el curso
es de Windows (§2), el legado es auténtico y la fase 11 es una migración de verdad.* Queda la
versión. La historia dice que los pasantes escribieron sobre **4.5** en Visual Studio 2015, y
ese número es fuente de verdad narrativa; el problema es que un Visual Studio de 2026 no trae
el paquete de destino de 4.5 y compilar contra él es una pelea que no enseña nada.
🪦 **Cerrada: .NET Framework 4.8, resuelto dentro de la ficción.** Wilson subió el destino a
4.8 en 2021 porque una actualización de Windows rompió un controlador de impresión fiscal; fue
el único cambio que ese código recibió en nueve años y no arregló nada de fondo. Es verosímil,
es lo que pasa de verdad en esas empresas, y deja el `App.config`, el `packages.config`, los
`DataSet` y la ausencia de `async` exactamente donde estaban.

> ⚠️ **Dos consecuencias que las fases deben respetar.** La historia sigue diciendo **4.5** y
> **Visual Studio 2015** para 2016-2017 (§3 de `00-historia-de-cordillera.md`): ese dato
> no se toca, y el salto a 4.8 se narra como lo que fue, un parche de 2021. Y la fase 11 tiene
> que decir en voz alta que **migrar de 4.8 a .NET 10 es más fácil que migrar de 4.5**, porque
> 4.8 ya trae buena parte del camino andado — presentarlo como si fuera el caso difícil sería
> venderle al lector una migración más barata de la que va a encontrar en su empresa.

**10.3 · 🪦 Cerrada: no hay fase de "testing", hay tres anclas y una fase de pruebas de verdad.**

Una fase dedicada al final del Bloque A enseñaría xUnit sobre ejemplos de juguete, que es
exactamente lo que este perfil no necesita: ya sabe qué es una prueba unitaria, ya usó JUnit y
Mockito diez años. Y dejarlo todo para la F08 llegaría demasiado tarde: seis fases de código sin
una sola prueba contradicen al propio curso. El reparto cerrado es este, y cada pieza cae donde
duele:

- **F00 fija el marco y escribe la primera prueba.** xUnit y `dotnet test`, integrados en el IDE
  y en la CLI. La primera prueba no es de juguete: cubre **el arnés de medición**, que tiene
  aritmética de percentiles y descarte de calentamiento y es exactamente la clase de código que
  se rompe en silencio. Desde ahí, todo el código del curso nace con pruebas.
- **F04 trae el ciclo de vida**, porque es la fase de `IDisposable` y el paralelo cae solo:
  xUnit **construye una instancia nueva de la clase por cada prueba** y limpia con `IDisposable`
  o `IAsyncLifetime`, en vez del `@BeforeEach`/`@AfterEach` sobre una instancia compartida. Ahí
  van también `IClassFixture` frente a `@BeforeAll`, y `[Theory]`/`[InlineData]` frente a
  `@ParameterizedTest`. Es el 📖 más útil del Bloque A y encaja con el tema de la fase.
- **F05 trae las pruebas asíncronas**, porque es la fase de `async`: probar código que devuelve
  `Task`, probar cancelación, y por qué el `.Result` que la fase prohíbe aparece en tantas
  suites de pruebas ajenas.
- **F08 es la fase de pruebas de verdad**, y es donde está el contenido que nadie enseña:
  caracterización con *golden master* sobre setecientos procedimientos que nadie leyó,
  determinismo —el procedimiento de regalías llama a `GETDATE()`—, la base real en contenedor
  con Testcontainers frente a los dobles, y el criterio de **cobertura útil** sobre código
  heredado, que no es el porcentaje.

> 🧭 **La regla que queda escrita:** desde la F00, ninguna fase entrega código sin pruebas, y
> ninguna fase dedica una sección a "cómo se escriben pruebas" salvo las cuatro de arriba.

**Marco fijado:** **xUnit** como framework —su ciclo de vida por instancia es además el mejor
contraste pedagógico con JUnit—, **Testcontainers** para la base real desde la F08, y
**NSubstitute** para los dobles, con una línea honesta sobre por qué no Moq. Las versiones
exactas se fijan en `alcance-del-proyecto.md` §9 al escribir la Fase 00.

**10.4 · 🪦 Cerrada: cuatro módulos, escritos en dos fases.** El legado que el curso escribe son
**existencias por almacén, liquidación de regalías, catálogo y facturación**, con su esquema real
(`MOVINVEN`, `LIQREGAL`, `VENTAS_YYYY`, `CAMPO1`…`CAMPO7`), los procedimientos almacenados que
llevan la lógica, la capa de datos con `DataSet` y el generador de datos sucios. Es
deliberadamente ancho: da material para que el *strangler fig* de la F10 corte de verdad y para
que la comparación de acceso a datos de la F09 tenga contra qué medirse.

> 🧭 **Pero no se escribe todo en la fase 07**, o sería la fase más pesada del curso y el lector
> pasaría dos semanas escribiendo código de 2017 antes de tocar nada moderno. El reparto:
>
> - **F07 escribe el esquema completo y dos módulos**, existencias y regalías — los dos que la
>   historia usa más y los que alimentan a NightPress.
> - **F08 escribe catálogo y facturación *mientras los caracteriza*.** Para entonces el lector
>   ya sabe escribir en estilo 2017, así que escribir un procedimiento y acto seguido cubrirlo
>   con una prueba de aproximación cuesta menos que escribirlo antes — y enseña más, porque la
>   prueba se escribe contra código que acabas de leer y todavía no entiendes del todo. Es
>   además el orden real de quien hereda un sistema.
>
> Lo que el curso **no** escribe —los otros 336 formularios, los 690 procedimientos restantes,
> el módulo de inventario de Lima— se cuenta como historia (guía §11, Regla 2).

**10.5 · 🪦 Cerrada: el duelo es contra Spring Boot, y solo contra él.** Es el stack que el
lector realmente tiene y el competidor más parejo que existe: misma generación, mismo perfil de
empresa, equipos intercambiables. Las columnas son rendimiento, arranque en frío, memoria,
líneas de código, costo mensual al volumen de Cordillera y facilidad de contratar a quien lo
mantenga. **No entra un tercer competidor**: Go o Node diluyen la comparación, alargan la fase y
no responden a ninguna pregunta que Cordillera se esté haciendo.

> 🪦 **Corregido al escribir la fase 23: la versión es Spring Boot 4.1.1, no 3.x.** Esta decisión se
> escribió cuando 3.x era la línea vigente, y al llegar a la fase el competidor real es **4.1.1 (21
> de agosto de 2026) sobre Java 25 LTS**. Medir contra una línea anterior sería exactamente el
> espantapájaros que la fase existe para evitar, y el lector —que es experto en el competidor— lo
> detectaría en la primera tabla. **La decisión de fondo no cambia** —un solo competidor, y es el
> stack que el lector tiene—; cambia el número de versión, y queda registrado aquí en vez de
> corregido en silencio.
>
> **Las variantes de compilación no son un tercer competidor.** ASP.NET Core con JIT y con AOT
> nativo, y Spring Boot en la JVM y como imagen nativa, son **cuatro configuraciones de los dos
> mismos competidores**, y entran las cuatro: dejar fuera el AOT de uno de los dos lados sesgaría
> el arranque en frío, que es la columna donde más se miente.

**10.6 · 🪦 Cerrada: no se publican horas por fase.** Se publica **la estimación del
miniproyecto, de dos a cinco horas**, y nada más. El miniproyecto domina el tiempo real y las
horas de lectura engañan; una tabla de horas que nadie puede cumplir desprestigia al resto del
material. Es divergencia declarada frente a la práctica habitual de otros cursos, que sí las
reparten.

**10.7 · ¿El track `cv` debería estar en el camino base?** Hablarle a un sistema Java que nadie
va a apagar es la situación más común del lector después del curso, y hoy está como opcional.
🪦 **Cerrada: no se mueve entero, pero el camino base cubre la habilidad.** La **fase 10** lleva
una sección donde la pieza que se envuelve es **Convivir**, el sistema Java que llegó con la
adquisición de la Universitaria del Bajío en 2004 y que nadie va a apagar. El track `cv`
profundiza —"el Fox" de Lima, el protocolo de archivo plano de los viernes, el ciclo de vida de
un sistema que sobrevive a su equipo— y sigue siendo opcional.

**10.8 · 🪦 Cerrada: el inventario está en `alcance-del-proyecto.md` §10.1.** Cada servicio de
nube que el curso toca queda clasificado en tres categorías —**ejecutable en local**,
**sustituido por un equivalente declarado** o **solo estudiado con precio publicado**— y ninguna
fase improvisa una cuarta. Los precios publicados se citan con **fecha y región**, y la región
por defecto del curso es **East US 2**, con la advertencia de que una región latinoamericana
cambia los números y el curso lo dice donde importa.

**10.9 · 🪦 Cerrada: Visual Studio Community 2026, con cuatro cargas de trabajo.** El criterio
que decide es que **una sola instalación tiene que poder abrir el legado y lo nuevo**: el
diseñador de WinForms sobre .NET Framework 4.8, el de WPF, los proyectos en formato SDK de
.NET 10 y las herramientas de datos de SQL Server. Las cargas son **desarrollo de escritorio de
.NET**, **desarrollo web y ASP.NET**, **almacenamiento y procesamiento de datos** y **desarrollo
de aplicaciones de Windows** (para el prototipo de WinUI 3 de la F14), más el paquete de destino
de .NET Framework 4.8 como componente individual. La Fase 00 las nombra y justifica una por una
— cuatro, no catorce.

> ⚠️ **El patch exacto se verifica al escribir la Fase 00**, contra las notas de versión
> oficiales, y se escribe en `alcance-del-proyecto.md` §9 **antes** de la primera línea que lo
> use. Aplica igual al SDK de .NET 10 y a xUnit, Testcontainers y NSubstitute. Ninguna versión se
> da por buena de memoria: es una regla del curso y no tiene excepción.

**10.10 · 🪦 Cerrada: `BENCHMARKS.md` e `INSTINTOS.md` nacen con la Fase 00.** Vacíos de
contenido pero completos de forma, y cada fase agrega su entrada al cerrarse. Dejarlos para el
final garantiza que las condiciones de las primeras mediciones se pierdan, y una medición sin
sus condiciones es una anécdota con decimales. El formato está en `formato-de-mediciones.md` §5.

**10.11 · 🪦 Cerrada: los nombres se congelan antes de la primera fase, y el C# heredado va en
inglés.** El esquema completo de los cuatro módulos, el modelo de dominio, el borde 🧬 que traduce
entre los dos y la estructura de `src/` están en
[`congelamiento-de-nombres.md`](congelamiento-de-nombres.md), que se escribió antes de la F00
justamente porque veintitrés fases arrastran esos nombres. Ahí queda cerrada también la única
pregunta de idioma que la guía §5 no resolvía sola: **los identificadores de C# del legado se
escriben en inglés igual que los del código nuevo**, y lo que lo hace de 2017 es el estilo
—`DataSet`, `SqlConnection` en el `Click`, sin `var`, sin LINQ, sin `async`— no el idioma. El
esquema, los comentarios, los mensajes y los textos de pantalla siguen en español.

---

## 11. 📁 Convención de nombres de archivo

Todo ordenable por nombre, con dos dígitos. **El número del archivo es el número de la fase.**

```text
README.md
0-ESTRUCTURA-CURSO.md
00-convencion-de-git-y-tags.md
00-instalacion-ambiente-visual-studio-y-ecosistema.md
01-tipos-valor-y-referencia.md
02-nullable-y-pattern-matching.md
…
24-veredicto-y-defensa.md
BENCHMARKS.md
INSTINTOS.md
src/
prompts/
```

No hay `aNN-`. El código ejecutable vive en `src/`, con un directorio por fase nombrado igual
que el documento al que pertenece, o un directorio por proyecto cuando el proyecto atraviese
varias fases — se decide al escribir la Fase 00 y se declara ahí. Los tracks opcionales, si se
escriben, llevan su propio prefijo de dos letras, que es la convención de nombres de este
curso.

---

## 12. 🚦 Siguiente paso

El procedimiento completo —qué se escribe en qué orden y qué se verifica al cerrar cada fase—
está en [`como-escribir-el-curso.md`](como-escribir-el-curso.md). En corto:

1. **Cerrar 10.9 antes de la Fase 00 y 10.8 antes de la Fase 16.** Son las dos únicas decisiones
   abiertas que bloquean código; las demás —10.5, 10.6, 10.7 y 10.10— se pueden resolver sobre la
   marcha. La numeración de §4 ya está cerrada y no se rediscute.
2. Escribir el encuadre que las fases enlazan: `README.md`, `0-ESTRUCTURA-CURSO.md` y
   `00-convencion-de-git-y-tags.md`, con los prompts de
   [`prompts-de-documentos-de-encuadre.md`](prompts-de-documentos-de-encuadre.md).
3. Escribir la **Fase 00**, que fija ambiente, arnés, marco de pruebas y estructura de `src/`, y
   con la que nacen `BENCHMARKS.md` e `INSTINTOS.md`.
4. Escribir las **fases 01 a 06**, que fijan el modelo de dominio y la voz.
5. Escribir las **fases 07 a 11** antes que el Bloque D: son el corazón ⭐ y las que más pueden
   obligar a retocar lo anterior. Hacerlo pronto es barato; al final, caro.

Los prompts de las veinticinco fases están en [`prompts-de-fase.md`](prompts-de-fase.md), uno por
chat, con el marco común al principio.
