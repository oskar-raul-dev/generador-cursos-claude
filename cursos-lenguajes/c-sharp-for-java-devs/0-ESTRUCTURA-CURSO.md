# 🗺️ Estructura del curso
## C# para desarrolladores Java senior

Este documento es **la fuente de verdad de la estructura**: qué bloques hay y por qué, las
veinticinco fases con lo que cada una ataca, los seis proyectos que las atraviesan, qué queda
fuera y qué necesita qué para existir. Si alguna vez el material y este documento se
contradicen, gana este documento y la fase se corrige.

---

## 🧱 1. Los siete bloques, y por qué están en este orden

**Bloque 0 · el ambiente** *(fase 00)*. En otro curso esto sería un apéndice de instalación. Aquí
es una fase entera porque el ecosistema es la mitad del salto: el SDK que responde en tu terminal
casi nunca es el que crees, `.csproj` no es `pom.xml` —es el build, no lo declara— y NuGet es
donde este perfil se estrella. Y porque de esta fase sale **el arnés de medición** que sostiene
las veinticuatro restantes: si no lo puedes medir con el arnés, no lo afirmas.

**Bloque A · el lenguaje y el runtime** *(01-06)*. C# se parece a Java lo suficiente para que lo
escribas mal durante dos años sin que nada se rompa en la demo. Este bloque ataca uno por uno los
seis reflejos que producen código que compila, funciona y es equivocado: los getters a mano donde
hay propiedades, el `null` tratado como estado válido, el `IEnumerable` recorrido dos veces, la
interfaz de un solo método, el `.Result` que bloquea, y el archivo cargado entero en memoria.
Termina fijando el modelo de dominio que arrastran todas las demás.

**Bloque B ⭐ · el sistema heredado y la frontera** *(07-11)*. El corazón del curso, y lo que no
tendría sentido en un tutorial de C#: el curso **escribe** el trozo de SIGE de 1997 —con su
esquema, sus procedimientos almacenados, su `DataSet` y su generador de datos sucios— para después
cortarlo. Antes de tocar nada lo caracteriza con pruebas, después mide tres formas de acceso a
datos contra el esquema hostil, después pone una API en medio con vuelta atrás demostrada, y solo
entonces mueve el runtime. El orden importa más que la tecnología.

**Bloque C · el escritorio** *(12-14)*. Porque el sistema son 340 formularios y porque la
respuesta honesta a veces es *"se quedan en WinForms sobre .NET 10"*. El mismo formulario se
construye tres veces y se mide contra lo que de verdad decide: arranque, memoria, despliegue a
noventa equipos, comportamiento con la conexión del depósito de Lima, y **quién lo puede mantener
cuando tú te vayas**.

**Bloque D · servicios, datos y nube** *(15-20)*. Lo que el lector ya sabe hacer en Java, hecho
aquí: contrato, identidad, trabajo de fondo, render, observabilidad. El bloque no explica HTTP ni
colas; explica dónde .NET decide distinto. Y cierra con la fase que nadie escribe: **la factura**,
donde tres atajos cómodos de tres fases distintas se pagan juntos y en un solo número.

**Bloque E · datos e IA aplicada** *(21-22)*. Los dos problemas de datos del negocio —las ventas
que mienten durante noventa días y el tiraje que alguien tiene que decidir— y los dos de IA, con
la exigencia que los hace serios: cada respuesta cita documento, versión y cláusula, o no se
emite. Con el veredicto decidido de antemano y dicho sin rodeos: para este trabajo, lo honesto es
entrenar en Python y servir desde .NET.

**Cierre** *(23-24)*. El mismo servicio implementado dos veces, en ASP.NET Core y en Spring Boot,
con los empates publicados como empates. Y el veredicto: qué no debió migrarse, y qué decisiones
del propio curso fueron erradas.

> 🧭 **Cada fase produce tres cosas y las declara en su encabezado:** una medición 📏, un
> miniproyecto 🧱 y el avance de al menos un proyecto. Una fase que no mueve ningún proyecto está
> mal ubicada.

---

## 🪜 2. Las veinticinco fases

⭐ marca las piezas de las que depende la tesis del curso. La columna **Estilo** dice en qué
generación de C# está escrito su código, y es lo primero que necesitas saber antes de copiar nada:
*heredado* es .NET Framework 4.8 y C# de 2017; *nuevo* es .NET 10 y C# 14; *mixto* 🧬 tiene las
dos, siempre en archivos distintos y con el borde marcado.

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
| 23 | ⚔️ El duelo: CatalogAPI en ASP.NET Core y en Spring Boot | nuevo | Rendimiento, costo, productividad, contratación — y los empates admitidos como empates |
| 24 | 🏁 Veredicto, defensa y qué no debió migrarse | — | La factura de 2020, "el Fox" de Lima, y las decisiones del propio curso que fueron erradas |

> 📝 **Sobre el tiempo:** el curso **no publica horas por fase**, y es una decisión tomada a
> propósito. Lo único que estima es el miniproyecto, **de dos a cinco horas**, porque es lo que
> domina el tiempo real; una tabla de horas de lectura que nadie puede cumplir desprestigia al
> resto del material.

---

## 💼 3. Los seis proyectos que atraviesan el curso

Los proyectos crecen fase a fase y son lo que impide que el curso sea una colección de ejemplos.
**Los miniproyectos no los tocan**: pueden leer su salida, consumir su API o medir contra su
implementación, pero no los modifican — así, quien resuelva mal un miniproyecto no arrastra el
error hasta el final.

| # | Proyecto | Qué es en Cordillera | Nace |
|---|---|---|---|
| 1 ⭐ | **SIGE, por partes** | El sistema entero: sacar la lógica de los procedimientos, cortar la conexión directa del cliente a la base, y solo entonces mover el runtime. Es el eje | F07 |
| 2 | **CatalogAPI** | El catálogo hacia afuera, que hoy son cuatro volcados CSV nocturnos desincronizados. El ultimátum de Grupo Almenara le puso fecha | F09 |
| 3 | **Redacción** | El back-office editorial: cuarenta pantallas, roles y auditoría, con Nohora de usuaria real y Ximena vigilando que no le agregues un paso | F18 |
| 4 | **NightPress** | El cierre de regalías: reanudable, idempotente y auditable línea por línea, porque dos veces al año un autor impugna | F17 |
| 5 | **AcervoRAG** | Cuarenta y siete años de contratos de derechos, con la regla que lo hace valioso: cada respuesta cita documento, versión y cláusula, o no se emite | F22 |
| 6 | **EditorAgent** | El triaje de los 400 manuscritos no solicitados que llegan al mes. No decide: prepara para que decida una persona | F22 |

**El cliente de escritorio no es un proyecto aparte:** es el frente de SIGE, y el Bloque C decide
qué se hace con él.

---

## 🔗 4. Qué necesita qué para existir

Las fases se leen en orden, pero conviene saber dónde están los amarres de verdad:

- **La 00 la necesitan las veinticuatro**, porque el arnés se construye ahí y ninguna fase mide
  con otra cosa.
- **La 01 la necesitan casi todas**, porque fija el modelo de dominio y sus nombres.
- **La 07 la necesitan la 08, la 09, la 10, la 11 y el Bloque C entero.** Es el sistema heredado;
  sin él, el bloque central sería un ensayo.
- **La 08 antes que la 09 y la 10**, y la regla es del oficio: primero la red, después el
  trapecio. Nada se refactoriza sin una prueba de caracterización que diga si se rompió.
- **La 09 antes que la 10**, porque no puedes poner una API en medio sin saber qué cuesta leer y
  escribir contra ese esquema.
- **La 10 antes que la 11.** Primero se corta la conexión directa del cliente a la base; mover el
  runtime antes es cambiar de casa sin haber empacado.
- **La 17 cobra tres deudas del Bloque A** —`Money` sin moneda, los dos métodos sin
  `CancellationToken`— y una de la 10, así que llega después de las cuatro por necesidad.
- **La 20 cobra tres atajos de la 15, la 17 y la 19**, y los tres aparecen en la misma hoja de
  costos. Esa acumulación es deliberada.

Y hay un amarre que va al revés y está declarado en los dos sitios:

> ⚠️ **La 14 y la 18 están acopladas.** El veredicto del escritorio compara cuatro opciones, y la
> cuarta —la web— no existe hasta la fase 18. La **14 congela la metodología** y publica su tabla
> con tres columnas llenas y **la cuarta declarada pendiente**, no vacía ni estimada; la **18 la
> rellena con la misma metodología y actualiza la tabla de la 14**. Es la única actualización
> retroactiva que el curso permite. Si el veredicto provisional cambia al entrar la columna de la
> web, la 18 lo dice y explica qué lo movió: un veredicto que cambia con un dato nuevo no es un
> error, es el curso funcionando.

### 🪦 Dos cosas de este orden que, con el curso escrito, debieron ser otras

La fase 24 revisa las decisiones de Cordillera **y las de este curso**, y dos de ellas son de este
documento. Van aquí, y no solo allí, porque un lector que está decidiendo si invertir veinticuatro
fases tiene derecho a saberlo antes de empezar:

- **El sistema heredado debió llegar antes del Bloque A.** La evidencia es del propio material: la
  fase 03 enseña evaluación diferida y **dos de sus tres competidores no existían todavía** —hubo que
  declarar un acoplamiento (§8.1 de la propuesta) y aplazar media medición a la 09—, y la fase 06 tuvo
  que **inventar una función de búsqueda** que con el esquema real delante habría sido obvia desde la
  01. La razón de haberlo puesto en la 07 era buena —que el lector no tuviera que instalar SQL Server
  en su primera semana— y **resultó más caro que el problema que evitaba**.
- **El veredicto del escritorio debió ir después de la web**, es decir, la fase 14 al final del Bloque
  D. La evidencia es el acoplamiento de arriba: hubo que inventar una convención entera —🔜— **que se
  usa una sola vez en veinticuatro entradas**, más un mecanismo de actualización retroactiva, más una
  regla sobre dónde vive la tabla. **Tres piezas de maquinaria para una celda.** Cuando una excepción
  necesita su propia infraestructura, lo que está mal es el orden.

**Y no se corrigieron**, por la regla de bloqueo de contenido que este curso se impone: una vez
publicado, renombrar fases y reordenar bloques rompe el material y los enlaces de quien ya lo
está leyendo. Quedan escritas como lo que son —**errores documentados**— y desarrolladas en la
[fase 24](24-veredicto-y-defensa.md) §4, con lo que habría cambiado cada una.

---

## 🚫 5. Qué queda fuera, y por qué

- **Enseñar a programar.** Sintaxis, estructuras de control y orientación a objetos se dan por
  sabidas. Solo entra lo que difiere de Java de una forma que produzca un error o una decisión
  distinta.
- **Certificación en Azure y catálogo de servicios.** La nube entra medida contra lo que
  reemplaza, con su costo al volumen real y su amarre. Un párrafo que describa un servicio sin
  esas dos cosas no está en el curso.
- **Teoría de aprendizaje automático.** Entra la IA aplicada, con evaluación de verdad; la teoría
  se enlaza y la exclusión se declara.
- **Un repositorio de partida.** El curso construye su código desde cero, incluido el sistema
  heredado que después se migra. Quien lee código ajeno no distingue decisión de accidente.
- **Una suscripción de Azure de pago.** Lo que tiene emulador se ejecuta; lo que no, se estudia
  con precio publicado, fecha y región, y se marca como no ejecutado.
- **Un tercer competidor en el duelo.** Go o Node diluyen la comparación y no responden a ninguna
  pregunta que Cordillera se esté haciendo.
- **Un framework de JavaScript** en el back-office, y la razón es de la empresa: no hay equipo de
  frontend, hay dos personas que mantienen la tienda.

### Los tracks opcionales

Cinco áreas reales de Cordillera que dan para un track propio, **fuera del camino base** y con su
propio prefijo de archivo. Si se escriben, es después de cerrar las veinticinco fases.

- **`ui`** — el tablero de ventas que hoy es un Excel por correo, y la presentación de junta
  generada en vez de armada la noche anterior.
- **`ar`** — producción: portadas en seis formatos, PDF de imprenta contra PDF de web, EPUB para
  cuatro tiendas incompatibles y los metadatos ONIX 3.0.
- **`au`** — inteligencia comercial y QA: qué publicó la competencia y a qué precio, pruebas e2e
  de la tienda, y el servidor de la imprenta que solo habla SSH.
- **`db`** — la deuda de las adquisiciones: el MySQL de la web vieja, MongoDB con eventos de
  lectura digital y Valkey delante del catálogo, todo contra el SQL Server ya pagado.
- **`cv`** — lo que no vas a migrar: **Convivir**, la plataforma Java que llegó con la adquisición
  de 2004, y "el Fox" de Lima. Sistemas vivos a los que hay que hablarles sin tocarlos.

> 🧭 **La habilidad del track `cv` sí está en el camino base.** La fase 10 tiene una sección donde
> la pieza que se envuelve sin tocarla es Convivir, porque hablarle a un sistema Java que nadie va
> a apagar es la situación más común del lector después del curso. El track profundiza; la
> habilidad no es opcional.

---

## 📐 6. La regla de forma: no hay apéndices

Este curso **no tiene apéndices**, y no es un detalle de organización. Todo lo que en otro curso
sería material de consulta —el ambiente, las herramientas, el puente entre versiones— es aquí una
fase o una sección de una fase. Las razones son tres:

- **No hace falta material de consulta de nivel básico.** Quien necesite la firma de
  `IAsyncEnumerable` la lee en la documentación oficial, y el curso enlaza en vez de transcribir.
- **Un apéndice de herramientas envejece peor que una fase.** .NET publica una versión mayor cada
  noviembre; un apéndice "de Visual Studio" separado del contenido se desactualiza en silencio.
  Dentro de una fase, con su miniproyecto, el desfase se ve al primer `dotnet build`.
- **El apéndice es donde se esconde lo que no supimos ubicar.** Sin esa válvula de escape, cada
  tema tiene que ganarse un lugar en la secuencia o quedarse fuera con su razón escrita.

El ejemplo mayor es el ambiente: SDK, Visual Studio, la CLI, NuGet y el depurador **son la fase
00 completa**, con su miniproyecto como cualquier otra.

> 🧭 **Y si al leer el curso encuentras algo que "sería un buen apéndice", tiene tres destinos
> legítimos:** una sección de su fase, una fase propia, o quedarse fuera con su razón escrita.
> Nunca un archivo `aNN-`.

---

## 📚 7. Los documentos que acompañan a las fases

- **[`00-historia-de-cordillera.md`](00-historia-de-cordillera.md)** — la empresa: su genealogía
  desde 1988, quién es quién, las cifras del negocio y la fecha de cada decisión incómoda del
  sistema. Es la fuente de verdad de todo lo narrativo, y se lee **antes que la fase 00**: las
  veinticinco fases dan por sabido quién es Duván y por qué el esquema se congeló en 1997.
- **[`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md)** — commits, tags de fase y
  de miniproyecto, y cómo se lee la factura de una deuda 💸 con un `git diff`.
- **[`BENCHMARKS.md`](BENCHMARKS.md)** — todas las mediciones del curso con sus condiciones, su
  competidor y su veredicto. Nace con la fase 00 y crece con cada fase; cuando una medición
  posterior contradice a una anterior, la vieja no se borra: se marca 🪦.
- **[`INSTINTOS.md`](INSTINTOS.md)** — los reflejos, organizados por familia y no por fase, porque
  se consulta buscando un síntoma. Incluye los que no son de lenguaje sino de arquitectura, que
  son los caros.
