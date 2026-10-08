# 🎯 Alcance del proyecto
## C# para desarrolladores Java senior

Documento de encuadre. Define qué es este curso, para quién, qué produce y —tan importante—
qué **no** hace. Se lee antes de escribir cualquier fase.

> 🧭 **Este documento y `propuesta-fases-y-alcance.md` son las dos fuentes de verdad
> estructurales del curso.** `00-historia-de-cordillera.md` es la fuente de verdad
> **narrativa** y manda en todo lo que sea dominio, personajes, cifras y cronología. Cuando
> este documento y la historia se contradigan en un dato del negocio, manda la historia;
> cuando se contradigan en una decisión de forma del curso, manda éste.

---

## 1. En una frase

Un curso práctico que enseña a un desarrollador Java senior a **escribir C# como se escribe
de verdad** mientras decide, con números delante, **qué parte de un sistema heredado se migra,
qué se envuelve y qué se deja quieto**.

---

## 2. El problema que resuelve

El lector no necesita aprender a programar, ni a leer un `for`. Necesita **desaprender dos
reflejos a la vez**, y el curso está organizado alrededor de esa doble tarea.

**El primer reflejo es de lenguaje.** C# se parece a Java lo suficiente para que un senior lo
escriba el primer día y lo escriba mal durante dos años: clases con getters y setters a mano
donde había propiedades, `IEnumerable` recorrido dos veces porque nadie dijo que LINQ es
perezoso, `async` que bloquea con `.Result`, `struct` tratado como objeto, `null` que el
compilador ya te estaba avisando. Funciona todo. Nada de eso se rompe en la demo. Se rompe en
producción, seis meses después, y el causante es el reflejo, no la sintaxis.

**El segundo reflejo es de arquitectura, y es el caro.** Puesto delante de un sistema de 1997
con treinta años encima, este perfil escribe el mismo documento que escribió el protagonista
de la historia el día once: *reescribamos todo en Spring Boot*. El fracaso simétrico —no tocar
nada, envolverlo en una capa y esperar— es igual de común y cuesta lo mismo, solo que tarda
más en cobrarse.

> 🧭 **La pregunta que ordena todo el curso: ¿esto se migra, se envuelve o se deja quieto?**

Las tres respuestas son legítimas y las tres tienen un costo que se puede calcular. El curso
existe para que el lector sepa cuál está eligiendo y pueda defenderla en una junta donde la
presidenta es abogada y pregunta *"si esto se cae un martes, ¿quién lo levanta?"*.

El veredicto honesto de cierre se escribe solo: **qué debió migrarse, qué debió quedarse en
la máquina virtual de Lima veintinueve años más, y qué nunca debiste sacar de Java.**

---

## 3. Objetivo pedagógico

Al terminar, el lector puede:

- Escribir C# idiomático —propiedades, LINQ, `async`/`await` de punta a punta, nullable
  reference types, `record`, pattern matching, `IDisposable`— y **reconocer dónde su instinto
  de Java produce código que compila, funciona y es equivocado**.
- Leer un sistema .NET Framework que no escribió: 340 formularios, 700 procedimientos
  almacenados y un esquema heredado de FoxPro, y decir en qué orden se toca.
- Ejecutar una migración incremental con patrón *strangler fig* **sin apagar el sistema**,
  con vuelta atrás en cada paso.
- Construir servicios ASP.NET Core, acceso a datos con EF Core y Dapper contra un esquema
  hostil, trabajo de fondo reanudable e interfaces de escritorio, eligiendo cada herramienta
  con el costo de las alternativas.
- Decidir, servicio por servicio, si algo debe seguir en una máquina virtual o ganar algo
  como PaaS — y qué cuesta esa decisión al mes.
- **Medir** en vez de opinar: rendimiento, arranque en frío, memoria, latencia y factura, con
  un arnés consistente y competidores reales.
- Decir con datos delante cuándo .NET no era la respuesta, y cuándo la respuesta correcta era
  no hacer nada.

Lo que **NO** es objetivo: formar arquitectos de nube, certificar a nadie en Azure, enseñar
teoría de aprendizaje automático, ni convencer a nadie de abandonar la JVM.

---

## 4. Perfil del lector

Un desarrollador **Java senior**, con ocho o más años de oficio. Domina orientación a objetos,
concurrencia, SQL, HTTP, pruebas, build, contenedores y despliegue. Ha leído documentación
técnica toda su vida y sabe resolver un problema mirando un ejemplo de código.

De eso se derivan dos reglas que atraviesan todo el material y que lo separan de un tutorial
de C# normal:

> 🧭 **No se explica lo que ya sabe.** Nada de qué es una clase, una interfaz, una excepción,
> una transacción o una petición HTTP. Cada párrafo que lo haga se borra, aunque esté bien
> escrito.
>
> 🧭 **La dificultad no se baja.** El lector resuelve leyendo documentación y ejemplos. Los
> ejercicios y los miniproyectos se calibran para alguien así: si un miniproyecto se puede
> terminar copiando el código de la fase, está mal diseñado.

El salto conceptual real está en seis puntos, y ahí se gasta el espacio: **el sistema de tipos
con valor y referencia de verdad**, **LINQ y la evaluación diferida**, **`async`/`await` como
modelo de todo el runtime y no como utilidad**, **nullable reference types y lo que el
compilador sí y no garantiza**, **el ecosistema MSBuild/NuGet frente a Maven**, y **cómo se
lee y se corta un sistema heredado vivo**. En lo demás, no.

Hay un séptimo punto, específico de este curso: **la interfaz de escritorio**. El lector viene
de un mundo donde "aplicación" significa servidor. Aquí hay noventa personas en nueve países
con un formulario abierto todo el día, y eso cambia decisiones de diseño que en un backend
puro no existen.

---

## 5. El dominio: Cordillera Media

El curso construye software para una empresa ficticia: **Cordillera Media**, un grupo
editorial bogotano fundado en 1979, con cuatro sellos, tres almacenes en tres países y un
sistema —**SIGE**, que todo el mundo llama *"el sistema"*— cuya genealogía va de dBase III
Plus en 1988 a Visual FoxPro, de ahí a una migración hecha por tres pasantes en 2016-2017, y
de ahí a un *lift and shift* a Azure en 2020 que costó un 30% más que el centro de datos que
reemplazó.

La historia completa vive en
**[`00-historia-de-cordillera.md`](../00-historia-de-cordillera.md)** y es fuente de
verdad para todo lo narrativo: personajes, cifras, cronología, deuda técnica y reglas de
negocio. Ninguna fase la contradice y ninguna fase la amplía por su cuenta.

Cuatro propiedades de Cordillera la hacen buena materia, y conviene tenerlas presentes al
escribir:

- **No hay salto de ecosistema que justificar.** Cordillera nunca decidió ser una casa
  Microsoft: Microsoft compró Fox Software en 1992 y la editorial ya estaba adentro. Lleva
  treinta y tres años ahí por inercia, que es como llega la mayoría. El curso no tiene que
  argumentar por qué una empresa Java se pasó a .NET, porque nunca fue una empresa Java.
- **Es dueña de su código.** Sin eso, la migración no tiene material: una empresa que licenció
  su sistema no puede migrarlo, solo puede hablarle desde afuera.
- **Cada decisión incómoda del esquema tiene un origen razonable y datable.** Los campos de
  diez caracteres, las fechas en `char(8)`, la bandera `BORRADO` y la tabla por año eran
  correctas en FoxPro y están fechadas en 1997. Esa es la diferencia entre enseñar migración y
  burlarse del código heredado.
- **La restricción es real y la fija la presidenta.** *"Ustedes me están pidiendo que pare la
  editorial dos años para que el sistema se vea mejor por dentro."* Nada de lo que el curso
  construya puede apagar el sistema.

---

## 6. La regla de forma que define este curso: **no hay apéndices**

Decisión cerrada.

Lo habitual es que el material de consulta —el ambiente, las herramientas, el puente entre
versiones— viva en apéndices `aNN-`. **Aquí no.** Todo lo que en otro curso sería un apéndice
es, en este, **una fase o una sección de una fase**.

Las razones son tres:

- **El lector no necesita material de consulta de nivel básico.** Los apéndices existen para
  quien nunca tocó la tecnología. Aquí el equivalente no existe: quien necesite la firma de
  `IAsyncEnumerable` la lee en la documentación oficial, y el curso enlaza en vez de
  transcribir.
- **Un apéndice de herramientas envejece peor que una fase.** El ecosistema de .NET se mueve
  una versión mayor por noviembre; un apéndice "de Visual Studio" separado del contenido se
  desactualiza en silencio y nadie lo nota. Dentro de una fase, con su miniproyecto, el desfase
  se ve al primer `dotnet build`.
- **El apéndice es donde se esconde lo que no supimos ubicar.** Sin esa válvula de escape,
  cada tema tiene que ganarse un lugar en la secuencia o quedarse fuera con su razón escrita.

> 🧭 **Corolario operativo:** cuando al escribir una fase aparezca material que "sería un buen
> apéndice", hay exactamente tres destinos legítimos: una sección de esa fase, una fase propia,
> o el registro 📌 de pendientes con su razón. Nunca un archivo `aNN-`.

El ambiente de trabajo —SDK, Visual Studio Community, la CLI, NuGet, el depurador— es el
ejemplo mayor de esta regla: **es la Fase 00 completa**, con su guía rápida de IDE adentro, no
un apéndice de setup.

---

## 7. Lo que está dentro del alcance

- El **camino base obligatorio**, organizado en bloques: ambiente, el lenguaje y el runtime,
  el sistema heredado y su migración, el escritorio, los servicios y la nube, los datos y la
  IA aplicada, y el cierre.
- **Un miniproyecto por fase**, obligatorio, difícil y anclado al dominio de Cordillera. Es el
  mecanismo principal de consolidación del curso y sustituye al cuaderno de incidentes que
  sería habitual en un curso de sistemas heredados. Su formato está en
  [`formato-de-miniproyectos.md`](formato-de-miniproyectos.md).
- **Avance de proyecto en cada fase.** Toda fase mueve al menos uno de los proyectos que
  atraviesan el curso, y lo declara en su encabezado. Una fase que no avanza nada es una fase
  que hay que replantear.
- Las **mediciones**: todo "es más rápido", "arranca antes", "consume menos" o "cuesta menos"
  se sostiene con un número producido por el arnés del curso, contra un competidor que alguien
  defendería en una revisión de código. El formato y las reglas de honestidad están en
  [`formato-de-mediciones.md`](formato-de-mediciones.md); los resultados, en `BENCHMARKS.md`.
- El **duelo final** contra el stack de origen: el mismo servicio implementado en ASP.NET Core
  y en Spring Boot, con el empate admitido donde haya empate.
- Los **tracks opcionales**, declarados fuera del camino base, con su propio prefijo de archivo
  y su propia numeración.

---

## 8. Lo que está fuera del alcance

- **Enseñar a programar.** Sintaxis básica, estructuras de control y orientación a objetos se
  dan por sabidas; solo entra lo que difiere de Java de forma que produzca un error o una
  decisión distinta.
- **Certificación en Azure y catálogo de servicios.** La nube entra **medida y comparada
  contra lo que reemplaza**, nunca como folleto. Un servicio gestionado que el curso adopta
  declara su costo y su amarre.
- **Teoría de aprendizaje automático.** Es un tema con bibliografía propia. Aquí entra la IA
  **aplicada**, con evaluación seria, y el resto se enlaza declarando la exclusión.
- **Apéndices de cualquier clase** (§6).
- **Un repositorio de partida.** El curso construye su código desde cero —incluido el sistema
  heredado que después se migra—, y la razón es concreta: quien lee código ajeno no distingue
  decisión de accidente.
- **Una suscripción de Azure de pago como requisito.** Ver §10: el curso se completa entero
  sin gastar un peso, y lo que no se puede emular se mide con precios publicados y se declara.

Si algo interesante aparece fuera de alcance, se registra como **pendiente 📌** con su destino
sugerido. No se infla la fase actual.

---

## 9. Restricciones de versiones

El curso es **autocontenido**: no depende de ningún `.csproj` externo y no verifica nada
contra un sistema que el lector no tenga.

> 🪦 **Trámite cerrado el 12 de septiembre de 2026.** Los patch de abajo se verificaron contra
> las notas de versión oficiales y las fichas de NuGet ese día, no de memoria. La columna
> *Verificado* dice contra qué. Cuando una de estas piezas avance —el SDK avanza una vez al mes y
> Visual Studio cada semana—, **se actualiza aquí primero** y después en las fases que la citen.

| Herramienta | Versión fijada | Dónde vive |
|---|---|---|
| .NET SDK | **10.0.401**, del canal 10.0 (LTS) — trae runtime, ASP.NET Core y Desktop **10.0.12** | Fase 00 · todo el curso |
| Lenguaje | **C# 14** (`<LangVersion>` no se toca: la trae el `net10.0`) | Fase 00 · todo el curso |
| El runtime heredado que se migra | **.NET Framework 4.8**, escrito como C# de 2017 | Bloque del sistema heredado |
| IDE principal | **Visual Studio Community 2026, 18.10.0** (canal Stable, build 12201.205) | Fase 00 |
| IDE alternativo | **VS Code + C# Dev Kit**, y **Rider** | Fase 00 |
| Paquetes | NuGet, con *Central Package Management* y `packages.lock.json` | Fase 00 · transversal |
| Base de datos | **SQL Server 2025** en contenedor — `mcr.microsoft.com/mssql/server:2025-latest` con `MSSQL_PID=EnterpriseDeveloper` | Bloque de datos |
| ORM | **EF Core 10.0.12** (`Microsoft.EntityFrameworkCore.SqlServer`) | Bloque de datos |
| Acceso a datos directo | **Dapper 2.1.66** | Bloque de datos |
| Hash estable entre procesos | **System.IO.Hashing 10.0.12** (`XxHash32`) | F10 · la bandera de corte |
| Resiliencia (reintentos, retroceso, cortacircuitos) | **Microsoft.Extensions.Resilience 10.10.0**, que envuelve Polly 8.7.0 | F17 · el outbox y los reintentos |
| Observabilidad | **OpenTelemetry 1.18.0** — la familia alineada: `OpenTelemetry.Extensions.Hosting`, `.Instrumentation.AspNetCore`, `.Instrumentation.Http`, `.Instrumentation.SqlClient`, `.Instrumentation.Runtime` y `.Exporter.OpenTelemetryProtocol` | F19 · la fase entera |
| Marco de pruebas | **xUnit v3 4.0.0** (`xunit.v3`) | Fase 00 · F04 · F05 · F08 |
| Ejecutor de pruebas | **xunit.runner.visualstudio 4.0.0** y **Microsoft.NET.Test.Sdk 18.10.0** | Fase 00 · transversal |
| Base real en pruebas | **Testcontainers 4.15.0** (`Testcontainers.MsSql`) | F08 en adelante |
| Dobles de prueba | **NSubstitute 6.2.0** | F04 · F05 · F08 |
| Formato y análisis | `dotnet format`, analizadores de .NET, `.editorconfig` | Fase 00 · transversal |
| Escritorio | WinForms y WPF sobre .NET 10; WinUI 3 como prototipo | Bloque de escritorio |
| Sistema operativo | **Windows 11**, con WSL 2 para los contenedores | Fase 00 · todo el curso |
| Nube | Azure, emulado en local donde se pueda (§10) | Bloque de nube |
| Aprendizaje automático | **Microsoft.ML.OnnxRuntime 1.30.0** para servir, y **Microsoft.ML 5.0.0** presentado y evaluado | F21 |
| IA aplicada | **Microsoft.Extensions.AI 10.10.0**; **Microsoft.SemanticKernel 1.80.1** estudiado y descartado con umbral | F22 |
| El competidor del duelo | **Spring Boot 4.1.1** (21 de agosto de 2026) sobre **Java 25 LTS**, con imagen nativa de GraalVM como variante | F23 |

**Dónde se verificó cada cosa**, para que el lector pueda repetir la comprobación:

- SDK y runtime — las notas de versión de `dotnet/core`: `https://github.com/dotnet/core/blob/main/release-notes/10.0/README.md`.
  El 10.0.401 salió el 8 de septiembre de 2026 y es el primer SDK que un `global.json` del curso fija.
- Visual Studio — el historial de versiones oficial:
  `https://learn.microsoft.com/visualstudio/releases/2026/release-history`. **Dato que la Fase 00
  tiene que decir en voz alta:** la edición Community solo se soporta en el canal Stable y **en su
  última versión**, así que el número de la tabla es el que había, no el que el lector va a tener.
  Lo que no cambia son las cuatro cargas de trabajo de §10.9 de la propuesta.
- EF Core, Dapper, xUnit, Testcontainers, NSubstitute y `System.IO.Hashing` — su ficha en
  `https://www.nuget.org/packages/<paquete>`.
- **ONNX Runtime, ML.NET, `Microsoft.Extensions.AI` y Semantic Kernel** — sus fichas de NuGet, verificadas el
  13 de septiembre de 2026. **El contraste de fechas es material del curso y no una curiosidad:** ONNX Runtime
  1.30.0 es de septiembre de 2026 y ML.NET 5.0.0 de noviembre de 2025 — casi un año sin versión nueva—, y eso
  dice dónde está la inversión del ecosistema. `Microsoft.Extensions.AI` y Semantic Kernel son, de las
  dependencias que este documento fija, **las dos que van a envejecer más rápido**.
- **Spring Boot** — el historial oficial de versiones: `https://spring.io/projects/spring-boot`. La línea
  vigente al escribir la F23 es **4.1.1**, y medir contra una anterior sería el espantapájaros que esa fase
  existe para evitar (`propuesta-fases-y-alcance.md` §10.5).
- **OpenTelemetry** — las fichas de los seis paquetes en NuGet. **La familia entera va a 1.18.0**, publicada el
  21 de agosto de 2026, y conviene decir por qué importa: los paquetes de instrumentación se versionan juntos y
  **mezclar versiones de la familia produce errores de resolución de tipos** que no se parecen a un problema de
  versiones. Las cinco instrumentaciones que el curso usa —AspNetCore, Http, SqlClient, Runtime y el exportador
  OTLP— están todas en estado estable en esa versión; **no todas lo estuvieron siempre**, y material de 2023 o
  2024 las cita como *beta* con razón para su fecha.
- La imagen de SQL Server — `https://mcr.microsoft.com/product/mssql/server/about`. En 2025 los
  valores de `MSSQL_PID` cambiaron de nombre: la edición de desarrollo ya no es `Developer` sino
  **`EnterpriseDeveloper`**, y ese detalle rompe los `docker run` copiados de tutoriales de 2019.

> ⚠️ **Esta tabla es la única fuente de versiones del curso.** Si una fase necesita una dependencia
> nueva, se fija con su número exacto aquí primero, con la fecha en que se verificó y el enlace a su
> ficha. Ninguna se da por buena de memoria, y ninguna se verifica contra un sistema externo que el
> lector no tenga.

> 📝 **Dos números se dejaron deliberadamente un escalón atrás.** El día de la verificación
> aparecían recién publicados `xunit.v3` 4.0.1 y `Dapper` 2.1.86, los dos con cero descargas. Un
> curso no fija un paquete de horas de vida: se quedan 4.0.0 y 2.1.66, que es lo que un equipo
> prudente tendría en su `Directory.Packages.props` ese día, y la Fase 00 explica ese criterio
> porque es parte del oficio.

---

## 10. Entornos de desarrollo

> 🧭 **El curso es de Windows, exclusivamente. Decisión cerrada.**

**Windows 11 es el único entorno soportado**, y el material se escribe para él sin nota al pie,
sin bloques condicionales por plataforma y sin marcadores de portabilidad. Las razones son dos
y las dos son del contenido, no de la comodidad del autor:

- **El sistema heredado de Cordillera son 340 formularios WinForms sobre .NET Framework**, y
  ninguna de esas dos cosas existe fuera de Windows. Un curso que evitara el escritorio para
  ser multiplataforma dejaría fuera la mitad del problema que vino a enseñar.
- **La decisión libera el bloque central.** Sin la restricción de portabilidad, el sistema
  heredado se escribe sobre .NET Framework auténtico —con su `App.config`, su `packages.config`
  y sus roturas de API reales—, y la fase de migración es una migración de verdad y no una
  simulación del estilo.

Lo que el lector necesita en su máquina, además del SDK y del IDE: **WSL 2 con un runtime de
contenedores**, que es donde corren SQL Server, los emuladores de Azure y el arnés de medición
cuando toca aislarlo. Se instala y se explica en la Fase 00.

📝 Que .NET 10 corra en Linux y en contenedor sigue siendo cierto y el curso lo dice donde
importa —es uno de los argumentos que desarman el "esto hay que reescribirlo en otra cosa" de
la historia §6—. Pero el **curso** se toma en Windows.

### 10.1 Qué se ejecuta, qué se sustituye y qué solo se estudia

Inventario cerrado (`propuesta-fases-y-alcance.md` §10.8). **Ninguna fase improvisa una cuarta
categoría**, y ninguna pide una tarjeta de crédito.

| Servicio | Categoría | Cómo | Fase |
|---|---|---|---|
| SQL Server | ▶️ **Ejecutable** | Contenedor, edición Developer | F07 en adelante |
| Telemetría | ▶️ Ejecutable | OpenTelemetry contra un colector local en contenedor | F19 |
| Service Bus | 🔄 **Sustituido** | El emulador oficial en contenedor si está disponible; si no, la cola en tabla de SQL Server —que es además el competidor por defecto de la F17— | F17 |
| Entra ID | 🔄 Sustituido | Un proveedor OIDC en contenedor para desarrollo. El modelo, los grupos y el costo de Entra ID se estudian | F16 |
| Key Vault | 🔄 Sustituido | `dotnet user-secrets` y variables de entorno, con **una sola ruta de código** hacia el gestor real | F16 |
| Azure OpenAI | 🔄 Sustituido | Un modelo servido en local para que el flujo y la evaluación corran de verdad, **declarando** que las cifras de calidad con un modelo de frontera serán otras | F22 |
| App Service · Container Apps · AKS | 💲 **Solo estudiado** | Precio publicado, con fecha y región | F20 |
| Azure AI Search | 💲 Solo estudiado | Precio publicado. Los competidores ejecutables son el texto completo y la búsqueda vectorial del propio SQL Server | F22 |

> 🪦 **Tres servicios estaban en este inventario y no entraron, y el curso lo dice en vez de
> disimularlo:** Blob Storage, las colas y tablas de Storage, y Azure Functions con Durable
> Functions, los tres planeados como ejecutables sobre Azurite para la F17 y la F20. La F17 se
> escribió con `IHostedService` y **una cola en tabla de SQL Server** —medida contra mensajería
> administrada—, y esa decisión resultó ser la lección de la fase: el atajo con su número al lado
> y su condición de salida escrita. Meter Azurite encima habría sido un cuarto competidor sin
> pregunta que lo pidiera. Quedan como 📌 pendientes con destino, no como deuda.

> 🧭 **La región por defecto del curso es East US 2**, y toda cifra de costo la nombra junto con
> la fecha de consulta. Una región latinoamericana cambia los números, y el curso lo dice donde
> eso altere una decisión — que es justo lo que le pasa a Cordillera, con oficinas en tres países.

> ⚠️ Lo que cae en 💲 **se marca como no ejecutado** en su medición
> (`formato-de-mediciones.md` §2.5). Un número de nube sin fecha, región y fuente contamina las
> veinticinco fases.

**Y la regla de la nube, que es de ambiente y no de contenido:**

> 🧭 **El curso se completa sin una suscripción de Azure de pago.** Lo que tiene emulador o
> equivalente local se usa así —SQL Server en contenedor, el emulador de Service Bus o una
> alternativa local declarada, un proveedor OIDC en contenedor, un modelo servido en
> local—. Lo que no lo tiene se estudia
> con precios publicados, se declara como no ejecutable, y se dice qué costaría ejecutarlo.
> Ningún miniproyecto exige una tarjeta de crédito.

---

## 11. El eje que ordena el final del curso

El curso cierra con el **veredicto**: dónde .NET moderno no era la respuesta, y dónde no hacer
nada era la respuesta correcta. No es un gesto de humildad — es el contenido. Un lector que
sale sabiendo migrar pero incapaz de decir *"este módulo funciona, no cambia, y gastarle seis
meses es orgullo de ingeniería"* no aprendió a decidir, aprendió a preferir.

Por eso el servicio central se implementa **dos veces**, en ASP.NET Core y en el stack de
origen del lector, y por eso el curso se obliga a admitir por escrito, con la factura en la
mano, que el *lift and shift* de 2020 fue un error y que la migración de los pasantes de 2016
fue, en el balance, correcta.

> ⚖️ Si al final del curso resultara que .NET moderno ganó todo, el curso estaría mal escrito.

---

## 12. Criterios de éxito

El curso funciona si quien lo termina puede:

1. Escribir C# que un equipo de .NET aceptaría en una revisión, sin acento de Java.
2. Leer un sistema heredado que no escribió y proponer un orden de corte defendible.
3. Ejecutar un paso de migración con vuelta atrás, sin apagar nada.
4. Elegir entre WinForms, WPF, web y un híbrido con el costo de las cuatro en la mano.
5. Medir su propio código y el del competidor con el mismo arnés, y publicar el empate cuando
   haya empate.
6. Terminar cada fase con su miniproyecto funcionando, sin haber copiado el código de la fase.
7. Nombrar dos decisiones del curso que, con los datos delante, debieron ser otras.

---

## 13. Decisiones cerradas

- 🪦 **Sin apéndices.** Todo es fase o sección de fase (§6).
- 🪦 **Un miniproyecto obligatorio por fase**, difícil, anclado a Cordillera, con criterios de
  aceptación verificables.
- 🪦 **Cada fase avanza al menos un proyecto** y lo declara en su encabezado.
- 🪦 **La Fase 00 es el ambiente completo**: SDK, Visual Studio Community con su guía rápida
  de uso, la CLI, NuGet y los IDE alternativos.
- 🪦 **La empresa es Cordillera Media**, con `00-historia-de-cordillera.md` como fuente
  narrativa.
- 🪦 **El código nuevo se escribe en inglés; el esquema heredado conserva sus nombres tal
  cual.** Guía de estilo §5.
- 🪦 **Todo "mejor que" lleva número**, y el competidor es una implementación defendible.
- 🪦 **La nube se mide, no se promociona**, y no requiere suscripción de pago (§10).
- 🪦 **Windows 11 exclusivamente** (§10). Sin variantes por plataforma en ningún documento.
- 🪦 **El legado se compila contra .NET Framework 4.8**, no contra el 4.5 que dice la historia.
  La historia no se toca: el salto a 4.8 se narra como el parche de 2021 que fue, y la fase de
  migración declara que salir de 4.8 es más fácil que salir de 4.5
  (`propuesta-fases-y-alcance.md` §10.2).
- 🪦 **El curso no puede apagar el sistema.** Cualquier fase cuya propuesta implique una
  ventana de parada de la editorial está mal diseñada.
- 🪦 **D-12 · Diagramas en Mermaid** (decidido el 05/10/2026, en la revisión del curso contra los
  lineamientos del repositorio). Los árboles de archivos, las muestras de datos y las salidas
  siguen en `text`. Guía de estilo §14.1, junto con las demás excepciones declaradas.

**Y la secuencia de fases también está cerrada**: veinticinco fases, 00 a 24, en
[`propuesta-fases-y-alcance.md`](propuesta-fases-y-alcance.md) §4, con el alcance detallado de
cada una en §5 y las once decisiones que la produjeron en §10. 🪦 El trámite de versiones se cerró
el 12 de septiembre de 2026 y está en §9 con su fecha y su fuente; los nombres del esquema y del
modelo se congelaron antes de la primera fase en `congelamiento-de-nombres.md`.
