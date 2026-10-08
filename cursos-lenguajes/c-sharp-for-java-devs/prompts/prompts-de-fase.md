# 📍 Prompts de fase
## C# para desarrolladores Java senior

**Un chat, un archivo.** Cada fase se redacta en su propio chat y produce un único `.md`. Si un
chat no produce entregable, o sobra o se salió de alcance.

**Cómo se usa este documento:** se copia el **§ Marco común** y, debajo, el bloque de la fase que
toca. Los dos juntos son el prompt completo.

> 🧭 **Por qué los bloques de fase son cortos.** El alcance detallado de cada fase —qué entra, qué
> no, el reflejo 🪞, la medición 📏, el miniproyecto 🧱 y su deuda 💸— ya está escrito en
> `propuesta-fases-y-alcance.md` §5, que es la fuente de verdad. Duplicarlo aquí garantizaría que
> algún día los dos documentos se contradigan. Lo que agrega cada bloque es lo que allí no está:
> **qué se decide en ese chat, con qué hay que tener cuidado, y qué le entrega a la siguiente.**

---

## § Marco común

*Se copia tal cual al inicio de cada chat de fase.*

````markdown
Este es un chat del curso *C# para desarrolladores Java senior*. Produce **un solo archivo
`.md`**, el de su fase, y nada más.

## Fuentes de verdad, en este orden

1. Las instrucciones del proyecto.
2. `prompts/alcance-del-proyecto.md` — qué es el curso y qué no.
3. `prompts/propuesta-fases-y-alcance.md` — **§5 tiene el alcance detallado de esta fase y se
   sigue literal**; §4 tiene la numeración oficial, que no se cambia.
4. `prompts/guia-de-estilo-y-convenciones.md` — voz, código, marcadores, plantilla, ejercicios.
5. `prompts/plantillas-de-capitulo.md` — las 10 secciones, en orden, sin extras.
6. `prompts/formato-de-miniproyectos.md` — el miniproyecto y su prueba de calibración.
7. `prompts/formato-de-mediciones.md` — el arnés y la forma de la medición.
8. `00-historia-de-cordillera.md` — todo lo narrativo: personajes, cifras,
   cronología, reglas de negocio, deuda técnica del sistema.
9. Los entregables de las fases anteriores.
10. Las decisiones explícitas de este chat.

## Las nueve reglas que más se rompen

- **No expliques lo que un dev Java senior ya sabe.** Ni qué es una interfaz, ni una transacción,
  ni HTTP, ni un contenedor. Cada párrafo que lo haga se borra, aunque esté bien escrito.
- **Código nuevo en inglés, comentarios en español con tildes.** También los mensajes de error y
  de log, y los textos que ve el usuario. Sin excepciones.
- **El esquema heredado conserva sus nombres tal cual** —`MOVINVEN`, `VLRUNIT`, `FECMOVTO`,
  `BORRADO`, `VENTAS_2019`—, sin traducir ni corregir, y el mapeo al modelo vive en un solo borde
  explícito marcado 🧬. Guía §5.1.
- **Escribe en el estilo declarado de esta fase.** Heredado significa .NET Framework 4.8 y C# de
  2017, con `DataSet` y sin `async`; nuevo significa .NET 10, nullable activado, `async` de punta
  a punta. Nunca las dos generaciones en el mismo archivo, y nunca modernizar un archivo heredado
  "de paso": así se rompen otras tres cosas.
- **Cada analogía con Java declara dónde se rompe.** Una analogía sin su límite deja al lector
  confiado en un modelo mental que le va a fallar en producción.
- **Ninguna afirmación comparativa sin número.** Si la medición no existe, se escribe la frase sin
  el comparativo o se escribe la medición. El competidor tiene que ser una implementación que
  alguien defendería en una revisión de código, y cuando el trabajo toca la base de datos se mide
  **primero el plan de consulta y después .NET**.
- **Ningún servicio de nube se describe sin su costo al volumen de Cordillera y sin su amarre.**
  El curso no es un folleto de Azure y no exige suscripción de pago.
- **El miniproyecto no puede resolverse copiando la sección 5.** Es la prueba de calibración
  literal de `formato-de-miniproyectos.md` §3, y es bloqueante: una fase que no la pasa se
  reescribe.
- **No hay apéndices.** Si aparece material que "sería un buen apéndice", los destinos legítimos
  son tres: sección de esta fase, fase propia, o 📌 con su razón escrita.

## Plataforma

El curso es de **Windows 11, exclusivamente**. No escribas variantes por plataforma, ni notas al
pie para Linux o macOS, ni marcadores de portabilidad. Los contenedores corren sobre WSL 2, que
se instala en la Fase 00.

## Coherencia de la ficción

La empresa es **Cordillera Media**, el sistema es **SIGE** —que todos llaman *"el sistema"*— y el
curso construye su código, incluido el trozo heredado. Si afirmas que algo está así en SIGE, tiene
que poder mostrarse en alguna fase. La cronología de la historia es fija, **nada de lo que
propongas puede apagar el sistema**, y nadie es el villano: ni Wilson, que no es desarrollador, ni
Duván, que sostiene solo lo que no diseñó, ni los tres pasantes, que hicieron en once meses lo que
nadie más quiso hacer. Guía §11.

## Cierre

La fase termina con el bloque 🏷️ de forma fija (guía §8.2), que pide `git tag -a fase-NN`, el tag
`mini-NN` con el número de la medición en su mensaje, y enlaza `00-convencion-de-git-y-tags.md`
**sin reexplicarlo**. Después, fuera de lo que lee el lector, van los 📌 Pendientes, con las
entradas que esta fase aporta a `BENCHMARKS.md` y a `INSTINTOS.md`.
````

---

# Bloque 0 · el ambiente

## # Fase 00

````markdown
Fase **00 — 🛠️ Ambiente, Visual Studio y el mapa del ecosistema** · archivo
`00-instalacion-ambiente-visual-studio-y-ecosistema.md`
Bloque 0 · Estilo: nuevo · Depende de: ninguna · Habilita: 01 · Proyecto: **nace el arnés**

Alcance literal: `propuesta-fases-y-alcance.md` §5, bloque de la Fase 00.

**Lo propio de este chat:**
- Es la fase que abre el curso: fija la voz, la condescendencia cero y el pacto de que no se
  explica lo sabido. Lo que se permita aquí se va a repetir veinticuatro veces.
- **Nace el arnés de medición**, que es el miniproyecto y la herramienta de todo el curso. Sigue
  `formato-de-mediciones.md` §1: repeticiones con descarte de calentamiento, mediana y p95,
  asignaciones y pico de memoria, y salida en el formato de `BENCHMARKS.md`. Que sea pequeño.
- **Nace `BENCHMARKS.md`** (§10.10), vacío pero con su cabecera y su formato.
- **Fija el marco de pruebas** (§10.3): xUnit y `dotnet test`, y la primera prueba del curso cubre
  la aritmética de percentiles del arnés. No es una prueba de juguete y no debe parecerlo.
- Deja **plantadas y sin resolver** las dos cosas que fases posteriores cobran: el arnés todavía
  no aísla el recolector (se amplía en la F06) y la solución todavía no tiene contenedores (llegan
  en la F08 con Testcontainers).
- Enlaza `00-convencion-de-git-y-tags.md`, que ya existe, y crea el repositorio del curso.

**Decide y déjalo escrito en `alcance-del-proyecto.md` §9 antes de usarlo:** la versión exacta de
Visual Studio Community y sus cargas de trabajo (§10.9), el patch del SDK .NET 10, y las versiones
de xUnit, Testcontainers y NSubstitute.

**Cuidado con:** convertir esto en un manual de instalación con capturas. Es la primera lección de
criterio del curso; si al leerla no hay ninguna decisión, está mal escrita.
````

---

# Bloque A · el lenguaje y el runtime

## # Fase 01

````markdown
Fase **01 — 🧬 Tipos, valor y referencia** · archivo `01-tipos-valor-y-referencia.md`
Bloque A · Estilo: nuevo · Depende de: 00 · Habilita: 02 · Proyecto: **nace el modelo de dominio**

Alcance literal: §5, bloque de la Fase 01.

**Lo propio de este chat:**
- **Nace el modelo de dominio** que arrastran veintitrés fases. Su forma la fija esta fase: elige
  con cuidado los nombres —`Title`, `Edition`, `StockItem`, `Isbn`, `Money`— y déjalos escritos.
  El diccionario de la guía §5.2 manda, y la prohibición de `Book` se respeta desde la primera
  línea.
- **Estrena el mecanismo de deuda 💸 del curso** con `Money` como `decimal` desnudo, y declara su
  cobro en la F17. Escríbela visible: es el ejemplo con el que el lector aprende a leer un 💸.
- El 🪞 tiene tres mitades y las tres se escriben: propiedades contra el par de métodos, igualdad
  estructural contra `equals`/`hashCode`, y la semántica de copia de un `struct`.

**Cuidado con:** meter LINQ o nullable. Los dos llegan en las dos fases siguientes y adelantarlos
rompe la progresión — y el compilador te va a pedir nullable, así que declara en el `.csproj` que
está activado y aplaza la explicación con una línea.
````

## # Fase 02

````markdown
Fase **02 — 🕳️ Nullable y pattern matching** · archivo `02-nullable-y-pattern-matching.md`
Bloque A · Estilo: nuevo · Depende de: 01 · Habilita: 03 · Proyecto: modelo

Alcance literal: §5, bloque de la Fase 02.

**Lo propio de este chat:**
- Aquí se paga la línea que la F01 dejó aplazada: qué es el contexto anulable, qué garantiza y
  **qué no** — que es la parte honesta y la que evita que el lector confíe de más.
- Es la primera fase que toca datos del sistema heredado, aunque sea de lejos. Escribe los tres
  casos que el miniproyecto distingue —`NULL`, cadena vacía y `'00000000'`— con los nombres reales
  del esquema, porque es la primera vez que el lector los ve y el hábito se fija aquí.
- Deja **dos `!` declarados como 💸** con su cobro en la F09. Que se vean: un `!` sin comentario es
  lo que este curso está enseñando a no escribir.

**Cuidado con:** escribir una fase sobre sintaxis de patrones. El contenido es el diálogo con el
compilador; los patrones son la herramienta con la que se responde.
````

## # Fase 03

````markdown
Fase **03 ⭐ — 🔁 LINQ y evaluación diferida** · archivo `03-linq-y-evaluacion-diferida.md`
Bloque A · Estilo: nuevo · Depende de: 02 · Habilita: 04 · Proyecto: modelo

Alcance literal: §5, bloque de la Fase 03.

**Lo propio de este chat:**
- Es fase ⭐ y el motivo es uno solo: **el `IEnumerable` recorrido dos veces** es el bug más caro
  que produce este perfil al cruzar, y no hay excepción que te avise. Esa comparación con el
  `IllegalStateException` de un Stream consumido es el 🪞 de la fase y tiene que quedar grabada.
- La medición necesita una base de datos y todavía no hay una. Resuélvelo con el conjunto de datos
  en memoria del generador de la F07 **o** aplazando la parte de `IQueryable` a una sección corta
  que la F09 retoma; elige una de las dos y déjalo escrito, sin inventar infraestructura.
- Deja el 💸 del `IQueryable` filtrado en memoria con su cobro en la F09.

**Cuidado con:** convertir la fase en un catálogo de operadores. Entran los que el curso usa
después, y ni uno más.
````

## # Fase 04

````markdown
Fase **04 — 🎩 Ceremonia que sobra y ceremonia que falta** · archivo
`04-ceremonia-delegados-y-recursos.md`
Bloque A · Estilo: nuevo · Depende de: 03 · Habilita: 05 · Proyecto: modelo

Alcance literal: §5, bloque de la Fase 04. Es la fusión acordada en §10.1 y trae además **el
ciclo de vida de las pruebas** (§10.3).

**Lo propio de este chat:**
- La fase tiene dos mitades y **una sola tesis que las une**: dónde C# pide menos ceremonia que
  Java —el delegado en vez de la interfaz de un método, el método de extensión en vez de `Utils`,
  la excepción sin declarar— y dónde pide más —cerrar lo que se abre, y decidir qué excepción
  atrapas—. Escribe esa tesis explícita al abrir, o la fase se lee como dos fases pegadas.
- El 📖 JUnit ⇄ xUnit va aquí, y su fila más valiosa es la instancia nueva por prueba frente al
  `@BeforeEach` sobre instancia compartida.
- El 💸 de esta fase **se paga a la vista, dentro de la misma fase**: el `finally` escrito a mano
  y su reescritura a `using`. Es el ejemplo de cómo se cobra una deuda, y el primero del curso.

**Cuidado con:** los genéricos reificados. Es el punto donde es fácil irse veinte párrafos; entra
lo que cambia para escribir código —`typeof(T)` en tiempo de ejecución, restricciones,
covarianza donde el curso la use— y el resto se enlaza.
````

## # Fase 05

````markdown
Fase **05 ⭐ — ⚙️ `async`/`await` de punta a punta** · archivo `05-async-await-y-cancelacion.md`
Bloque A · Estilo: nuevo · Depende de: 04 · Habilita: 06 · Proyecto: modelo

Alcance literal: §5, bloque de la Fase 05. Trae además **las pruebas asíncronas** (§10.3).

**Lo propio de este chat:**
- Es fase ⭐ porque `async` en .NET no es una utilidad: es el modelo del runtime entero, y todas
  las fases del Bloque D lo dan por sabido.
- **La medición de `.Result` contra `await` bajo doscientas peticiones concurrentes es la pieza
  central de la fase**, no un adorno del final. Un dev senior no cambia el reflejo porque se lo
  digan; lo cambia cuando ve el número de hilos.
- Deja los dos métodos sin `CancellationToken` como 💸 con cobro en la F17.
- Menciona los hilos virtuales de Java en el 📖 —el lector los conoce— y di **dónde se rompe el
  paralelo**: son dos respuestas distintas al mismo problema, y la de .NET te obliga a colorear
  las funciones.

**Cuidado con:** `async void`. Se prohíbe aquí y se levanta la prohibición **una sola vez** en la
F12, para los manejadores de eventos de WinForms. Deja escrita la prohibición de forma que esa
excepción futura encaje sin contradecirte.
````

## # Fase 06

````markdown
Fase **06 — 🧠 Memoria, GC, `Span<T>` y flujo** · archivo `06-memoria-span-y-flujo.md`
Bloque A · Estilo: nuevo · Depende de: 05 · Habilita: 07 · Proyecto: modelo

Alcance literal: §5, bloque de la Fase 06.

**Lo propio de este chat:**
- **Cobra la deuda de la F00**: el arnés pasa a medir asignaciones y colecciones por generación.
  El diff entre el tag `fase-00` y este es la factura, y conviene decirlo en el bloque 🏷️.
- Cierra el Bloque A, así que el cierre mira hacia atrás: con seis fases, el lector ya escribe C#
  sin acento y está listo para leer código que no escribió.
- El 🩻 de esta fase es generoso a propósito: **todo el instinto de GC que el lector trae sirve**,
  y decirlo después de cinco fases corrigiéndole reflejos es un descanso merecido.

**Cuidado con:** vender `Span<T>` como la solución a todo. Es la última optimización, no la
primera, y la fase lo dice con el número al lado — y con la limitación que duele: no puede cruzar
un `await`.
````

---

# Bloque B ⭐ · el sistema heredado y la frontera

## # Fase 07

````markdown
Fase **07 — 🏚️ El sistema que heredas** · archivo `07-el-sistema-que-heredas.md`
Bloque B · Estilo: **heredado** · Depende de: 06 · Habilita: 08 · Proyecto: **nace SIGE**

Alcance literal: §5, bloque de la Fase 07. El reparto de módulos con la F08 está en §10.4.

**Lo propio de este chat:**
- **Es la única fase del curso escrita entera en estilo heredado**, y la primera vez que el lector
  ve el marcador de generación. Declara el estilo en el encabezado con todas sus letras.
- **Fija el esquema completo de los cuatro módulos** —aunque solo implementes dos— porque la F08,
  la F09 y la F10 construyen encima y renombrar después rompería tres fases. Nombres reales,
  mayúsculas, tal cual.
- **Cada decisión incómoda va junto a su año y su razón.** Es la regla de tono más importante de
  la fase: enseñar migración, no burlarse del código heredado. Si un párrafo se lee como sorna, se
  reescribe.
- **Toma la línea base de medición** del `UNION ALL` de treinta tablas. Todo el bloque se compara
  contra ese número.

**Decide y déjalo escrito:** la semilla y el volumen exacto del generador de datos sucios, porque
la F08 caracteriza contra él y la F09 mide contra él.

**Cuidado con:** arreglar algo. Nada se mejora en esta fase, ni siquiera lo que duele, ni siquiera
"de paso en un comentario". La tentación es constante y ceder aquí desarma el bloque entero.
````

## # Fase 08

````markdown
Fase **08 ⭐ — 🔎 Caracterizar lo que no puedes leer** · archivo `08-caracterizar-y-probar.md`
Bloque B · Estilo: mixto 🧬 · Depende de: 07 · Habilita: 09 · Proyecto: SIGE (+catálogo y
facturación)

Alcance literal: §5, bloque de la Fase 08. Es **la fase de pruebas del curso** (§10.3).

**Lo propio de este chat:**
- **Escribe catálogo y facturación mientras los caracteriza** (§10.4): un procedimiento, y acto
  seguido la prueba que lo fija. Explica por qué ese orden —es el de quien hereda un sistema— o el
  lector va a pensar que es un atajo de producción.
- Es fase mixta 🧬 por primera vez: el código heredado está en 4.8 y las pruebas en .NET 10. **Ese
  borde es material didáctico** y hay que marcarlo, no esconderlo.
- El determinismo es el corazón: el procedimiento de regalías llama a `GETDATE()` y hasta que eso
  no se resuelva ninguna prueba vale. Resuélvelo de la forma que un equipo real puede aplicar sin
  tocar el procedimiento.
- **Introduce Testcontainers** y el criterio de cobertura útil sobre código heredado, que no es el
  porcentaje.

**Cuidado con:** enseñar xUnit. El lector sabe probar. Lo que no sabe es **caracterizar lo que no
entiende sin romperlo**, y ahí va el presupuesto de la fase.
````

## # Fase 09

````markdown
Fase **09 — 🗄️ Acceso a datos contra un esquema hostil** · archivo
`09-acceso-a-datos-esquema-hostil.md`
Bloque B · Estilo: mixto 🧬 · Depende de: 08 · Habilita: 10 · Proyecto: **nace CatalogAPI**

Alcance literal: §5, bloque de la Fase 09.

**Lo propio de este chat:**
- **Nace CatalogAPI**, de momento solo su capa de datos. El endpoint público llega en la F15.
- **Cobra tres deudas**: los dos `!` de la F02 y el `IQueryable` de la F03. Di entre qué tags se
  lee la factura.
- Aquí vive el patrón que más se repite en el resto del curso: **el nombre feo en el borde**.
  `VLRUNIT` a un lado, `UnitPrice` al otro, el mapeo en un solo sitio y marcado 🧬. Escríbelo de
  forma que las quince fases siguientes puedan citarlo.
- La comparación Dapper / EF Core / ADO.NET se mide con el plan de consulta **antes**, y el
  veredicto declara el umbral donde cambia la respuesta.

**Cuidado con:** el veredicto perezoso de "usa Dapper para leer y EF Core para escribir". Puede ser
la conclusión, pero solo si el número la sostiene y se dice qué cuesta mantener dos formas de
acceso a datos en el mismo proyecto.
````

## # Fase 10

````markdown
Fase **10 ⭐ — 🌿 *Strangler fig*** · archivo `10-strangler-fig.md`
Bloque B · Estilo: mixto 🧬 · Depende de: 09 · Habilita: 11 · Proyecto: SIGE + CatalogAPI

Alcance literal: §5, bloque de la Fase 10. Incluye la sección del track `cv` (§10.7).

**Lo propio de este chat:**
- **Es la fase que da nombre a la tesis del curso.** Aquí se responde, con un procedimiento
  ejecutable, la pregunta *¿se migra, se envuelve o se deja quieto?*
- **La vuelta atrás se ejecuta de verdad**, no se describe. Un procedimiento de reversión que
  nadie probó no es un procedimiento de reversión, y ese es el criterio de aceptación del
  miniproyecto.
- La sección del track `cv` envuelve **Convivir**, la plataforma Java de la adquisición de 2004.
  Es el momento del curso que más se parece a la vida real del lector, y conviene decirlo.
- Deja la doble escritura sin conciliación automática como 💸, con cobro en la F17.

**Cuidado con:** presentar el corte como una decisión técnica. El orden de los cortes lo decide el
riesgo del negocio, y quien lo firma es Clara. Si la fase no tiene una conversación con la
presidenta adentro, le falta la mitad.
````

## # Fase 11

````markdown
Fase **11 — 🚚 Migrar el runtime** · archivo `11-migrar-el-runtime.md`
Bloque B · Estilo: mixto 🧬 · Depende de: 10 · Habilita: 12 · Proyecto: SIGE

Alcance literal: §5, bloque de la Fase 11.

**Lo propio de este chat:**
- **Obligación declarada en §10.2:** decir en voz alta que migrar desde 4.8 es más fácil que
  migrar desde 4.5, y qué tendría de más el camino que Cordillera no tuvo que hacer. Sin eso, el
  curso vende una migración más barata de la que el lector va a encontrar en su empresa.
- Cierra el Bloque B. El cierre mira hacia atrás sobre las cinco fases y hacia adelante al
  escritorio, que es lo único del sistema que sigue sin tocarse.
- El 💸 de los dos paquetes sin equivalente **no se paga en este curso**, y hay que explicar por
  qué: depende de un proveedor, y esa es una respuesta legítima que el lector va a tener que dar
  alguna vez.

**Cuidado con:** convertirlo en un tutorial de la herramienta de actualización. La herramienta
hace el 70% y el curso vive en el 30% restante: lo que compila y revienta en tiempo de ejecución.
````

---

# Bloque C · el escritorio

## # Fase 12

````markdown
Fase **12 — 🪟 WinForms sobre .NET 10** · archivo `12-winforms-en-net-10.md`
Bloque C · Estilo: mixto 🧬 · Depende de: 11 · Habilita: 13 · Proyecto: SIGE cliente

Alcance literal: §5, bloque de la Fase 12.

**Lo propio de este chat:**
- **Levanta la prohibición de `async void` de la F05**, una sola vez y con su razón: en un
  manejador de evento es la forma correcta. Cítala explícitamente para que no parezca un descuido.
- Es la fase que tiene que sostener, sin ironía, que **quedarse en WinForms es una opción
  legítima en 2026**. Si el texto se lee como una concesión hecha a regañadientes, está mal
  escrito: el veredicto de la F14 tiene que poder salir por aquí.
- El despliegue a noventa equipos aparece aquí por primera vez y vuelve en la F14. Deja el dato
  medido, no estimado.

**Cuidado con:** el diseñador. Entra lo que rompe al migrar —controles de terceros, recursos,
`ClickOnce`—, no un recorrido por la caja de herramientas.
````

## # Fase 13

````markdown
Fase **13 — 🎛️ WPF y MVVM** · archivo `13-wpf-y-mvvm.md`
Bloque C · Estilo: nuevo · Depende de: 12 · Habilita: 14 · Proyecto: SIGE cliente

Alcance literal: §5, bloque de la Fase 13.

**Lo propio de este chat:**
- **Cobra la deuda de la F12**: la lógica sale del `Click` y pasa a un modelo de vista que se
  prueba sin levantar la interfaz. Ese es el argumento entero de MVVM y se demuestra con las
  pruebas corriendo, no con un diagrama.
- El lector conoce MVC. Di dónde el paralelo funciona y **dónde se rompe**: aquí la vista observa
  al modelo y nadie llama a nadie, que es justo lo que hace difícil de depurar un binding roto.
- Deja la lista sin virtualizar como 💸, con cobro medido en la F14.

**Cuidado con:** XAML. Entra lo mínimo para que el binding se entienda; estilos, plantillas y
temas quedan fuera con su razón escrita — no hay apéndice al que mandarlos.
````

## # Fase 14

````markdown
Fase **14 — ⚖️ WinUI 3, Blazor Hybrid y el veredicto del escritorio** · archivo
`14-veredicto-del-escritorio.md`
Bloque C · Estilo: nuevo · Depende de: 13 · Habilita: 15 · Proyecto: SIGE cliente

Alcance literal: §5, bloque de la Fase 14.

**Lo propio de este chat:**
- **La medición es la fase.** Cuatro opciones × cinco criterios, y la columna que decide es *quién
  lo puede mantener* — que tiene nombre propio, Duván, y es la razón por la que una opción
  técnicamente superior puede perder.
- La web todavía no existe: nace en la F18. Mide las tres de escritorio con rigor y **deja la
  cuarta columna abierta con su criterio ya definido**, para que la F18 la complete sin rediscutir
  la metodología.
- El veredicto **no está prejuzgado**. Si los números dicen WinForms, el veredicto dice WinForms.

**Cuidado con:** dejar el despliegue para el final. Es donde se decide de verdad —noventa equipos,
sin permisos de administrador— y el prototipo bonito que no se puede instalar no compite.
````

---

# Bloque D · servicios, datos y nube

## # Fase 15

````markdown
Fase **15 — 🌐 ASP.NET Core: minimal APIs y contrato** · archivo `15-aspnet-core-minimal-apis.md`
Bloque D · Estilo: nuevo · Depende de: 14 · Habilita: 16 · Proyecto: CatalogAPI

Alcance literal: §5, bloque de la Fase 15.

**Lo propio de este chat:**
- **El encargo tiene fecha y remitente**: el correo de cuatro líneas de Grupo Almenara pidiendo
  API real con SLA o buscan otro proveedor. La fase se escribe desde ahí, no desde "vamos a ver
  minimal APIs".
- El contrato público **no puede filtrar el esquema heredado**. Es la continuación directa del
  borde 🧬 de la F09 y conviene enlazarlo.
- Deja la falta de paginación como 💸 con cobro en la F20, en pesos.

**Cuidado con:** la comparación minimal APIs contra controladores. Es legítima y hay que medirla,
pero no es el tema de la fase; el tema es el contrato.
````

## # Fase 16

````markdown
Fase **16 — 🔐 Identidad, secretos y configuración** · archivo
`16-identidad-secretos-y-configuracion.md`
Bloque D · Estilo: nuevo · Depende de: 15 · Habilita: 17 · Proyecto: CatalogAPI

Alcance literal: §5, bloque de la Fase 16.

**Lo propio de este chat:**
- **Cobra la deuda más antigua del curso**: la cadena de conexión que la F07 puso en el
  `App.config` de noventa equipos. Es el cobro más satisfactorio del material y hay que dejar que
  se note.
- Es la primera fase que necesita decidir **qué se emula y qué se declara** (§10.8). Cierra el
  inventario en `alcance-del-proyecto.md` §10 antes de escribir el código, y no lo improvises aquí.
- La tabla de usuarios de 2017 con el hash que da pena: di qué se hace con ella, incluido el paso
  incómodo de la migración de contraseñas sin poder leerlas.

**Cuidado con:** un recorrido por el catálogo de identidad de Azure. Entra lo que Cordillera
necesita para el back-office y para los socios, y cada pieza con su costo y su amarre.
````

## # Fase 17

````markdown
Fase **17 — 🌙 Trabajo de fondo** · archivo `17-trabajo-de-fondo.md`
Bloque D · Estilo: nuevo · Depende de: 16 · Habilita: 18 · Proyecto: **nace NightPress**

Alcance literal: §5, bloque de la Fase 17.

**Lo propio de este chat:**
- **Cobra tres deudas**: los `CancellationToken` de la F05, la doble escritura de la F10 y el
  `Money` sin moneda de la F01, que ahora cruza tres divisas.
- El criterio de aceptación del miniproyecto es el de la historia: **reproducir exacto un número
  liquidado ocho meses antes**, que hoy en Cordillera cuesta tres días de arqueología entre
  respaldos. La tasa de cambio se guarda con el cálculo, y esa es la regla que el lector se lleva.
- La comparación cola-en-tabla contra Service Bus incluye **el costo mensual**, no solo el
  throughput. La tabla ya existe y funciona: el competidor por defecto es el statu quo.

**Cuidado con:** las funciones durables. Se nombran y se aplazan a la F20, donde se miden con su
precio. Meterlas aquí sin costo sería el folleto que la guía prohíbe.
````

## # Fase 18

````markdown
Fase **18 — 🧵 Blazor Server ⇄ WebAssembly ⇄ MVC** · archivo `18-blazor-server-wasm-mvc.md`
Bloque D · Estilo: nuevo · Depende de: 17 · Habilita: 19 · Proyecto: **nace Redacción**

Alcance literal: §5, bloque de la Fase 18.

**Lo propio de este chat:**
- **Completa la cuarta columna de la tabla del escritorio** (F14) con la misma metodología. Cítala
  y no la rediscutas.
- Las usuarias son Nohora y Ximena, y sus criterios son de negocio: que Nohora pueda corregir un
  registro mal grabado a las siete de la tarde sin llamar a nadie, y que Ximena no reciba un paso
  más en su flujo. Una herramienta que falle esos dos criterios está mal aunque gane la medición.
- La latencia se **simula e inyecta** —Bogotá, Ciudad de México, Lima—, no se estima.

**Cuidado con:** el entusiasmo por Blazor Server. Es cómodo de escribir y tiene un problema real
con la conexión del depósito de Lima; la fase existe para que eso se vea antes de comprometerse.
````

## # Fase 19

````markdown
Fase **19 — 🔭 Observabilidad y operación** · archivo `19-observabilidad-y-operacion.md`
Bloque D · Estilo: nuevo · Depende de: 18 · Habilita: 20 · Proyecto: los cuatro

Alcance literal: §5, bloque de la Fase 19.

**Lo propio de este chat:**
- **Cobra la deuda de auditoría de la F18** y deja la telemetría instrumentada en los cuatro
  proyectos.
- La traza tiene que **cruzar el borde 🧬**: de la petición HTTP al procedimiento almacenado
  heredado. Ese es el material que distingue esta fase de cualquier tutorial de OpenTelemetry.
- Deja la falta de muestreo como 💸 con cobro en la F20. Es la tercera deuda que se cobra en la
  misma factura, y esa acumulación es deliberada.

**Cuidado con:** los datos personales en el log estructurado. La trampa del miniproyecto es
exactamente esa, y la fase tiene que dejar la regla escrita sin convertirse en una charla legal.
````

## # Fase 20

````markdown
Fase **20 ⭐ — 🐳 Contenedor, arranque en frío y la factura** · archivo
`20-contenedor-y-la-factura.md`
Bloque D · Estilo: nuevo · Depende de: 19 · Habilita: 21 · Proyecto: los cuatro

Alcance literal: §5, bloque de la Fase 20.

**Lo propio de este chat:**
- **Es la fase que nadie enseña y la que más se va a citar.** El *lift and shift* de 2020 costó un
  30% más que el centro de datos que reemplazó, y aquí se cuantifica con la factura en la mano,
  sin absolver a nadie — tampoco a quien lo aprobó por miedo.
- **Cobra tres deudas a la vez** —paginación (F15), cola en tabla (F17), muestreo (F19)— y las tres
  aparecen en la misma hoja de costos. Que se vea la suma.
- Toda cifra de nube va con precio publicado, fecha y región, y marcada como no ejecutada
  (`formato-de-mediciones.md` §2.5).

**Cuidado con:** AKS. La conclusión probable es que para Cordillera es un error, y hay que
sostenerla con el costo de operación y no con una opinión sobre Kubernetes.
````

---

# Bloque E · datos e IA aplicada

## # Fase 21

````markdown
Fase **21 — 📊 Los datos que mienten, y ONNX** · archivo `21-datos-y-onnx.md`
Bloque E · Estilo: nuevo · Depende de: 20 · Habilita: 22 · Proyecto: NightPress

Alcance literal: §5, bloque de la Fase 21.

**Lo propio de este chat:**
- **El veredicto está decidido de antemano y se dice sin rodeos:** ML.NET existe, se presenta, y
  para este trabajo lo honesto es entrenar en Python y servir desde .NET con ONNX Runtime. La
  fase mide para sostenerlo, no para descubrirlo.
- **El competidor es Gustavo**, treinta y un años decidiendo tirajes mirando título, portada y mes.
  Más un baseline tonto —*lo mismo que el título anterior del mismo autor*—. Si el modelo no le
  gana a los dos, el resultado se publica igual.
- Cordillera destruyó 41.000 ejemplares en 2024. Ese número es el costo del error por exceso y
  conviene que esté en la fase.

**Cuidado con:** enseñar aprendizaje automático. Está fuera de alcance y declarado; entra la
canalización de datos, el servicio de la predicción y la evaluación honesta.
````

## # Fase 22

````markdown
Fase **22 — 🤖 IA aplicada** · archivo `22-ia-aplicada.md`
Bloque E · Estilo: nuevo · Depende de: 21 · Habilita: 23 · Proyecto: **nacen AcervoRAG y
EditorAgent**

Alcance literal: §5, bloque de la Fase 22. Es la fusión acordada en §10.1.

**Lo propio de este chat:**
- Los dos proyectos comparten fase **porque comparten el aparato de evaluación**. Escribe ese
  aparato una vez, y que cada proyecto lo use: si la fase se lee como dos fases pegadas, la fusión
  está mal ejecutada.
- **La cita obligatoria es el requisito, no una mejora**: documento, versión y cláusula, o no se
  responde. Una alucinación sobre un contrato de derechos no es una molestia, es una demanda — y
  Clara es abogada.
- **EditorAgent no decide**: prepara para que decida una persona. El error de descartar en
  silencio un buen libro es el más caro y el único que nunca vas a poder medir en producción.
- Admite el resultado incómodo: **la búsqueda de texto completo puede ganarle al aparato de
  embeddings**, y si gana, se publica.

**Cuidado con:** Semantic Kernel. El veredicto va en esta fase y tiene que ser específico: cuándo
aporta orquestación real y cuándo es una capa que te cobra abstracción sin devolverte nada.
````

---

# Cierre

## # Fase 23

````markdown
Fase **23 — ⚔️ El duelo** · archivo `23-el-duelo.md`
Cierre · Estilo: nuevo · Depende de: 22 · Habilita: 24 · Proyecto: CatalogAPI ×2

Alcance literal: §5, bloque de la Fase 23.

**Lo propio de este chat:**
- **El lector es experto en el competidor.** Eso hace la comparación más honesta y también más
  difícil de aprobar: cualquier atajo en la implementación de Spring Boot lo va a detectar.
  Escríbela como la escribiría alguien que la defiende.
- **Los empates se publican como empates**, con la dispersión que los sostiene. Es la palabra que
  menos aparece en los cursos de tecnología y la que más falta hace.
- Las columnas no son solo técnicas: costo mensual al volumen de Cordillera, y facilidad de
  contratar a quien lo mantenga.

**Cuidado con:** dejar que la fase decida por la empresa. El duelo informa; la decisión de
Cordillera ya estaba tomada por razones que la historia explica, y la fase lo reconoce.
````

## # Fase 24

````markdown
Fase **24 — 🏁 Veredicto, defensa y qué no debió migrarse** · archivo `24-veredicto-y-defensa.md`
Cierre · Estilo: — · Depende de: 23 · Habilita: ninguna · Proyecto: los seis

Alcance literal: §5, bloque de la Fase 24.

**Lo propio de este chat:**
- Es la última fase del curso y **su trabajo es admitir**. Las cuatro admisiones obligatorias
  están en §5 y salen de §14 de la historia; ninguna se suaviza.
- **Dos decisiones del propio curso que debieron ser otras.** No son un gesto de humildad: son el
  contenido, y tienen que ser específicas y estar sostenidas por una medición del propio material.
- Consolida `BENCHMARKS.md` y marca 🪦 las mediciones que una posterior contradijo. El historial
  de los errores del curso es material didáctico.
- Cierra `INSTINTOS.md`, el documento de reflejos recurrentes que las fases fueron alimentando.

**Cuidado con:** el tono triunfal. La última línea del curso dice que si .NET moderno hubiera
ganado todo, el curso estaría mal escrito. Todo lo anterior tiene que hacer que esa línea sea
creíble.
````
