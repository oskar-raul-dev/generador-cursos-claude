# Comandos Bash de la sesión 3a759429-f737-40e7-8978-df701a07831d, en orden. Una bitácora, no un script: no se corre entera.

# --- 2026-09-12T23:03:42 · List all files in the c-sharp course
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs && find . -type f | sort && echo "---SIZES---" && find . -type f -exec wc -l {} \;

# --- 2026-09-12T23:03:47 · Read the proposal history file
cat prompts/historia-propuesta-1-cordillera.md

# --- 2026-09-12T23:03:49 · Read rest of proposal
sed -n '40,566p' prompts/historia-propuesta-1-cordillera.md

# --- 2026-09-12T23:03:52 · Read lines 80-300
sed -n '80,300p' prompts/historia-propuesta-1-cordillera.md

# --- 2026-09-12T23:03:54 · Read lines 300-566
sed -n '300,566p' prompts/historia-propuesta-1-cordillera.md

# --- 2026-09-12T23:03:57 · List family dir and python course files
cd /Users/oskar/Developer/Learning/courses-ia-generated && ls cursos-algoritmos-lenguajes/ && echo "--- python ---" && find cursos-algoritmos-lenguajes/python-for-java-devs -type f | sort

# --- 2026-09-12T23:09:02 · Line counts of reference prompts
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-legacy/angular-16-legacy-for-backend-devs/prompts && wc -l *.md *.py | sort -n

# --- 2026-09-12T23:09:07 · Read style guide part 1
sed -n '1,430p' guia-de-estilo-y-convenciones.md

# --- 2026-09-12T23:09:09 · Read style guide part 2
sed -n '430,859p' guia-de-estilo-y-convenciones.md

# --- 2026-09-12T23:09:11 · Read scope doc part 1
sed -n '1,240p' alcance-del-proyecto.md

# --- 2026-09-12T23:09:13 · Read scope doc part 2
sed -n '240,444p' alcance-del-proyecto.md

# --- 2026-09-12T23:09:15 · Read chapter templates
sed -n '1,365p' plantillas-de-capitulo.md

# --- 2026-09-12T23:09:17 · Read phase proposal part 1
sed -n '1,220p' propuesta-fases-y-alcance.md

# --- 2026-09-12T23:09:19 · Read phase proposal part 2
sed -n '220,420p' propuesta-fases-y-alcance.md

# --- 2026-09-12T23:09:25 · Read python sibling scope doc
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/prompts && wc -l *.md && echo "=== ALCANCE ===" && sed -n '1,120p' alcance-del-proyecto.md

# --- 2026-09-12T23:09:28 · Read python scope rest
sed -n '120,260p' alcance-del-proyecto.md

# --- 2026-09-12T23:09:31 · Read miniproject format
cat formato-de-miniproyectos.md

# --- 2026-09-12T23:09:33 · Read python templates and phase prompts
cat plantillas-de-capitulo.md; echo "===== PROMPTS DE FASE ====="; cat prompts-de-fase.md

# --- 2026-09-12T23:09:36 · Read python phase proposal
cat propuesta-fases-y-alcance.md

# --- 2026-09-12T23:09:39 · Read python style guide part 1
sed -n '1,300p' guia-de-estilo-y-convenciones.md

# --- 2026-09-12T23:09:41 · Read python style guide part 2
sed -n '300,594p' guia-de-estilo-y-convenciones.md

# --- 2026-09-12T23:12:19 · Write scope document
mkdir -p /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs/prompts && cat > /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs/prompts/alcance-del-proyecto.md <<'FIN'
# 🎯 Alcance del proyecto
## C# para desarrolladores Java senior

Documento de encuadre. Define qué es este curso, para quién, qué produce y —tan importante—
qué **no** hace. Se lee antes de escribir cualquier fase.

> 🧭 **Este documento y `propuesta-fases-y-alcance.md` son las dos fuentes de verdad
> estructurales del curso.** `historia-propuesta-1-cordillera.md` es la fuente de verdad
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
**[`historia-propuesta-1-cordillera.md`](historia-propuesta-1-cordillera.md)** y es fuente de
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

Decisión cerrada, heredada del curso hermano de Python y confirmada aquí.

En los cursos de Angular del repositorio, el material de consulta —el ambiente, las
herramientas, el puente entre versiones— vive en apéndices `aNN-`. **Aquí no.** Todo lo que en
otro curso sería un apéndice es, en este, **una fase o una sección de una fase**.

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
  mecanismo principal de consolidación del curso y sustituye al cuaderno de incidentes de los
  cursos de legacy del repositorio. Su formato está en
  [`formato-de-miniproyectos.md`](formato-de-miniproyectos.md).
- **Avance de proyecto en cada fase.** Toda fase mueve al menos uno de los proyectos que
  atraviesan el curso, y lo declara en su encabezado. Una fase que no avanza nada es una fase
  que hay que replantear.
- Las **mediciones**: todo "es más rápido", "arranca antes", "consume menos" o "cuesta menos"
  se sostiene con un número producido por el arnés del curso, contra un competidor que alguien
  defendería en una revisión de código. Viven en `BENCHMARKS.md`.
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
- **Teoría de aprendizaje automático.** El repositorio tiene `cursos-ia`. Aquí entra la IA
  **aplicada**, con evaluación seria, y el resto se enlaza declarando la exclusión.
- **Apéndices de cualquier clase** (§6).
- **Un repositorio de partida.** El curso construye su código desde cero —incluido el sistema
  heredado que después se migra— igual que los cursos hermanos, y por la misma razón: quien
  lee código ajeno no distingue decisión de accidente.
- **Una suscripción de Azure de pago como requisito.** Ver §10: el curso se completa entero
  sin gastar un peso, y lo que no se puede emular se mide con precios publicados y se declara.

Si algo interesante aparece fuera de alcance, se registra como **pendiente 📌** con su destino
sugerido. No se infla la fase actual.

---

## 9. Restricciones de versiones

El curso es **autocontenido**: no depende de ningún `.csproj` externo y no verifica nada
contra un sistema que el lector no tenga.

| Herramienta | Versión | Dónde vive |
|---|---|---|
| .NET SDK | **10.x (LTS)** | Fase 00 · todo el curso |
| Lenguaje | **C# 14** | Fase 00 · todo el curso |
| El runtime heredado que se migra | **.NET Framework 4.5**, escrito como C# 2 | Bloque del sistema heredado |
| IDE principal | **Visual Studio Community** (edición y versión por cerrar) | Fase 00 |
| IDE alternativo | **VS Code + C# Dev Kit**, y **Rider** | Fase 00 |
| Paquetes | NuGet, con *Central Package Management* y `packages.lock.json` | Fase 00 · transversal |
| Base de datos | **SQL Server** en contenedor (edición Developer) | Bloque de datos |
| ORM y acceso a datos | **EF Core 10** y **Dapper** | Bloque de datos |
| Pruebas | por cerrar: xUnit o MSTest, más Testcontainers | Fase de pruebas |
| Formato y análisis | `dotnet format`, analizadores de .NET, `.editorconfig` | Fase 00 · transversal |
| Escritorio | WinForms y WPF sobre .NET 10; WinUI 3 como prototipo | Bloque de escritorio |
| Nube | Azure, emulado en local donde se pueda (§10) | Bloque de nube |

> ⚠️ **Las versiones exactas —patch incluido— se cierran en la discusión de fases y se
> escriben aquí antes de redactar la primera línea que las use.** Ninguna se da por buena de
> memoria, y ninguna se verifica contra un sistema externo. Esta tabla es la única fuente; si
> una fase necesita una dependencia nueva, se fija con su número exacto aquí primero.

---

## 10. Entornos de desarrollo

**Windows 11 es el entorno principal y declarado**, y es el único donde el curso se completa
al cien por ciento. La razón es concreta y no se disimula: **WinForms, WPF y WinUI 3 son de
Windows**, y el sistema heredado de Cordillera son 340 formularios WinForms.

**Linux amd64 y macOS Apple Silicon están soportados para todo lo demás** —lenguaje, runtime,
servicios, datos, contenedores, nube, IA— que es la mayor parte del curso. Cada fase del
bloque de escritorio lleva en su encabezado una línea explícita de *requiere Windows*, y el
resto del material no asume plataforma.

Donde una instrucción difiera entre plataformas se dan las tres, en ese orden y sin
condescendencia.

**Y la regla de la nube, que es de ambiente y no de contenido:**

> 🧭 **El curso se completa sin una suscripción de Azure de pago.** Lo que tiene emulador o
> equivalente local se usa así —SQL Server en contenedor, Azurite para Blob y colas, el
> emulador de Service Bus o una alternativa local declarada—. Lo que no lo tiene se estudia
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
- 🪦 **La empresa es Cordillera Media**, con `historia-propuesta-1-cordillera.md` como fuente
  narrativa.
- 🪦 **El código nuevo se escribe en inglés; el esquema heredado conserva sus nombres tal
  cual.** Guía de estilo §5.
- 🪦 **Todo "mejor que" lleva número**, y el competidor es una implementación defendible.
- 🪦 **La nube se mide, no se promociona**, y no requiere suscripción de pago (§10).
- 🪦 **El curso no puede apagar el sistema.** Cualquier fase cuya propuesta implique una
  ventana de parada de la editorial está mal diseñada.

Lo que sigue abierto es la **secuencia de fases**, y es exactamente la conversación que abre
[`propuesta-fases-y-alcance.md`](propuesta-fases-y-alcance.md).
FIN
wc -l /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs/prompts/alcance-del-proyecto.md

# --- 2026-09-12T23:15:55 · Write style guide
cat > /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs/prompts/guia-de-estilo-y-convenciones.md <<'FIN'
# ✍️ Guía de estilo, tono y convenciones de código
## C# para desarrolladores Java senior

Esta guía es la fuente de verdad editorial del curso. Cualquier chat que produzca un `.md` la
sigue. Su objetivo es simple: que todos los documentos se lean como escritos por la misma
mano, con la misma voz y el mismo criterio, y que todos apunten al mismo lugar — **que el
lector escriba C# sin acento de Java y sepa decidir qué se migra, qué se envuelve y qué se
deja quieto.**

Si dudas entre dos formas de escribir algo, gana la que le sirva más a alguien que el lunes
tiene que tocar un sistema que factura todos los días y no puede apagarse.

---

## 1. Principio rector

**Todo lo que se escribe apunta a una decisión que alguien va a tener que defender.**

No enseñamos C# "bonito". No formamos arquitectos de nube. Formamos criterio para mirar un
módulo de treinta años y decir *"esto se migra"*, *"esto se envuelve"* o *"esto se queda como
está tres años más"*, y sostener cualquiera de las tres con el costo de las otras dos en la
mano.

El filtro para cada párrafo es este: **¿esto ayuda a decidir, a medir o a ejecutar?** Si no,
sobra. Aunque esté muy bien escrito. Sobre todo si está muy bien escrito.

Y hay un segundo filtro, específico de este perfil: **¿el lector ya lo sabe?** Un dev Java
senior sabe qué es una interfaz, un `try/finally`, una transacción y un contenedor.
Explicárselo no es generosidad, es ruido.

---

## 2. Tono

El tono es **semiformal, colegial y directo** — senior a senior, con humor cuando cae bien.
Piensa en un colega que hizo este cruce hace tres años, se equivocó lo suficiente, y te lo
cuenta sin solemnidad y sin venderte nada.

Cómo se ve eso en la práctica:

- **Tuteo latinoamericano, siempre.** *"Mide el arranque en frío antes de pagar por AOT."*
  Nada de voseo (*"medí"*, *"fijate"*), nada de "usted", nada de impersonal permanente ("se
  debe medir…") que enfría el texto.
- **Semiformal.** Cercano, pero no chat de WhatsApp. Frases completas, puntuación correcta,
  cero abreviaturas de mensajería.
- **Humor seco y con moderación.** Un 😉 bien puesto, un chiste sobre las tres horas que
  perdiste buscando un *deadlock* que era un `.Result`. Regla práctica: **máximo un chiste por
  sección**, y si no fluye solo, se borra.
- **Honesto sobre el costo.** Cada opción gana en algo y pierde en algo, y las pérdidas se
  dicen con número: *"AOT nativo te quita 180 ms de arranque en frío y te cuesta la reflexión,
  media hora de compilación y dos bibliotecas del proyecto que dejan de funcionar"*.
- **Sin evangelismo, en ninguna dirección.** Ni *"C# es más productivo"* ni *"esto en Java
  sería más robusto"* sin la medición delante. El curso no tiene equipo.
- **Sin condescendencia hacia el código heredado.** La migración de los pasantes de 2016 fue
  barata, salió, y compró diez años. Juzgarla desde 2026 con un presupuesto que en 2016 no
  existía es la forma más común de arrogancia de ingeniero, y no entra a este curso. Cuando el
  material muestre algo feo, muestra también su fecha y su porqué.
- **Orientado a la duda real.** Anticipa el *"¿y esto por qué está así?"* y respóndelo, muchas
  veces con una 📝 **Nota de ecosistema** que dé el contexto: qué versión trajo esa API, qué
  reemplazó, y por qué lo anterior sigue vivo en medio internet y en medio Cordillera.

Lo que evitamos: promesas vacías ("vas a dominar .NET"), motivación de coach, solemnidad de
manual, folleto de nube, y explicar lo obvio para el perfil.

---

## 3. Idioma y forma de la narrativa

- **Español latinoamericano neutro**, técnico y claro, para todo lo que no es código: títulos,
  explicaciones, ejercicios, referencias, callouts.
- **Los términos del ecosistema se quedan en inglés** cuando son el nombre real de la cosa:
  *record*, *span*, *pattern matching*, *source generator*, *middleware*, *hosted service*,
  *minimal API*, *managed identity*, *cold start*, *strangler fig*. Traducirlos forzadamente
  ("higuera estranguladora") confunde más de lo que aclara y no es lo que van a leer en la
  documentación.
- **Markdown siempre.** Nada de HTML embebido salvo que no haya alternativa — la excepción
  conocida y aceptada es el `<details>` de las pistas de los miniproyectos.
- **Prosa antes que listas.** Un párrafo que explica *por qué* vale más que cinco viñetas que
  enumeran *qué*. Las listas se usan cuando la cosa es de verdad una lista — pasos
  secuenciales, ítems paralelos, opciones.
- **Listas antes que tablas en comparativas extensas.** Para comparar cuatro opciones de
  cómputo o tres estrategias de acceso a datos, una lista con subtítulos. Una tabla de siete
  columnas se lee mal en pantalla, peor en móvil, y no deja espacio para explicar el porqué de
  cada celda.

  Formato recomendado para comparativas:

  ```markdown
  **Opción B — Azure Container Apps**

  Qué es: contenedores gestionados, escalado a cero, sin cluster que operar.
  Cuándo conviene: servicios con tráfico irregular y equipo sin gente de plataforma.
  El costo: arranque en frío visible, y el amarre está en el modelo de ingreso y escalado.
  Veredicto: gana para CatalogAPI al volumen de Cordillera; pierde si el servicio nunca
  baja de diez peticiones por segundo.
  ```

- **Tablas solo para lo que de verdad es tabular y corto.** Versiones fijadas, mapeo
  concepto ⇄ concepto, matriz de decisión, tres columnas como máximo. Si necesitas explicar
  una celda, ya no es una tabla: es una lista.
- **Encabezados con emoji, con moderación.** Uno por sección de la plantilla. Un documento que
  parece un teclado de emojis pierde autoridad.

---

## 4. Pedagogía: cómo se explica

### 4.1 La regla del andamio

Todo concepto nuevo se presenta en tres tiempos, en este orden:

1. **El problema primero.** Antes de nombrar la herramienta, muestra el dolor que resuelve.
   *"El reporte histórico de ventas une treinta tablas anuales y trae 500.000 filas. Puedes
   materializar la lista y ver el proceso llegar a 1,8 GB, o puedes…"*
2. **La herramienta después.** El nombre y la definición mínima: lo justo para usarla hoy, no
   el capítulo completo de la documentación.
3. **El código que corre.** El fragmento más pequeño que demuestra el punto, con comentarios
   que explican el porqué.

Presentar la herramienta antes que el problema produce gente que sabe escribir un
`IAsyncEnumerable` pero no sabe cuándo hace falta.

### 4.2 La traducción desde Java: una vez, y después se abandona

Una propiedad es primo del par `getX`/`setX`; LINQ es primo de Streams; `async`/`await` es
primo de `CompletableFuture`; `IDisposable` con `using` es `try-with-resources`; un
`record` es primo de un `record`, y ahí el paralelo es casi honesto.

Dos límites, y los dos son estrictos: la analogía se usa **una vez, para abrir la puerta**, y
después se abandona; y **se dice explícitamente dónde se rompe**, que es donde está la
lección.

> *"Hasta acá el paralelo entre LINQ y Streams funciona. La diferencia es que un Stream se
> consume una vez y lo sabes porque te lanza `IllegalStateException`; un `IEnumerable` se
> recorre dos veces sin decir nada y ejecuta la consulta dos veces contra la base."*

Una analogía que no declara dónde se rompe es peor que ninguna: deja al lector confiado en un
modelo mental que va a fallarle en producción. **Esta es la regla que más se rompe al
escribir, y la que más caro sale.**

### 4.3 Explica el porqué, no solo el cómo

Cada decisión relevante lleva su porqué, aunque sea media línea entre paréntesis. Y cuando el
porqué es histórico —que en este curso pasa todo el tiempo—, se dice también y **con fecha**:
*"el campo se llama `VLRUNIT` porque el formato DBF limitaba el nombre a diez caracteres, y
eso se decidió en 1997; renombrarlo hoy cuesta trescientos procedimientos almacenados"*.

### 4.4 Densidad calibrada

- Un concepto nuevo por vez. Si un bloque de código introduce tres cosas desconocidas, se
  parte en tres bloques.
- Repetir lo importante está bien. Los conceptos que sostienen el curso —migrar, envolver o
  dejar quieto; qué se mide y contra qué; el sistema no se apaga— pueden reaparecer varias
  veces con otras palabras.
- **Ninguna sección teórica supera las dos pantallas sin que aparezca código.**

### 4.5 Cierra los bucles

Si abres un paréntesis pedagógico —*"esto se arregla cuando la API esté en medio"*, *"acá
dejamos deuda 💸"*— tiene que cerrarse en algún documento del curso. Un 💸 sin fase de cobro es
un error de escritura, no una licencia.

### 4.6 La regla de la medición

> 🧭 **Ninguna afirmación comparativa entra al curso sin un número producido por el arnés del
> curso.** Ni "más rápido", ni "más liviano", ni "arranca antes", ni "sale más barato".

Si la medición todavía no existe, hay dos salidas honestas: escribirla, o escribir la frase
sin el comparativo. Lo que no se hace es afirmar y prometer el número para después.

La medición incluye **siempre al competidor de verdad**: si se compara contra Spring Boot, se
compara contra una implementación que alguien defendería en una revisión de código, no contra
un ejemplo de tutorial sin pool de conexiones.

Y hay un orden obligatorio cuando el trabajo toca la base de datos:

> ⚠️ **Primero SQL, después .NET.** Con treinta tablas anuales unidas por `UNION ALL`
> generado concatenando cadenas, el primer orden de magnitud no está en el lenguaje: está en
> el plan de consulta. Optimizar C# encima de una consulta mala es teatro, y el curso lo dice
> cada vez que aplique.

### 4.7 Ninguna fase es un folleto de nube

Cada servicio gestionado que el curso adopta se mide **contra lo que reemplaza** —la tabla de
cola que ya funciona en SQL Server, la máquina virtual que ya está pagada— y declara dos
cosas: **qué cuesta al volumen real de Cordillera** y **qué tan difícil sería moverlo a otro
proveedor un martes**. Un párrafo que describa un servicio de Azure sin ninguna de las dos
cosas se borra.

---

## 5. Idioma del código fuente

> **Regla normativa y no negociable: todo el código nuevo del curso se escribe en inglés
> —variables, métodos, clases, proyectos, archivos, endpoints, constantes— y todos los
> comentarios y documentación XML se escriben en español, con tildes.** Aplica a cada
> fragmento nuevo del curso, sin excepción: fases, miniproyectos, ejercicios resueltos,
> pruebas, migraciones, `Dockerfile`, YAML de despliegue y scripts.

La razón es la de siempre: el vocabulario que el lector practica durante meses tiene que ser
el que va a leer en producción, y ningún equipo escribe `CalcularRegalias()`.

Y la contraparte importa igual: **los comentarios van en español** porque son el canal donde
se explica el *porqué* de una decisión, y ese razonamiento se lee en el idioma en que se
piensa el curso. Un comentario en inglés es un error de estilo aunque el código sea impecable.

**Los mensajes de error y de log van con los comentarios, no con el código.** Un
`throw new InvalidOperationException(...)`, un `logger.LogWarning(...)` o el detalle de un
`400` son texto dirigido a otro desarrollador: **en español, con tildes**. Los identificadores
que los rodean siguen en inglés.

**Los textos que ve el usuario van en español**, que es el idioma en que trabajan las noventa
personas de Cordillera. Sin claves de traducción y sin aparato de i18n: el grupo opera en
español en nueve países.

### 5.1 🧬 La excepción grande: el esquema heredado conserva sus nombres

> 🧭 **Ni una tabla, ni una columna, ni un procedimiento almacenado heredado se traduce, se
> corrige ni se "arregla de paso" al citarlo.** `MOVINVEN` se llama `MOVINVEN`. `VLRUNIT`,
> `FECMOVTO`, `CODEDIT`, `LIQREGAL`, `BORRADO`, `CAMPO1`, `VENTAS_2019` se escriben tal cual,
> en mayúsculas, cada vez.

No es folclore. Es que **renombrar ese esquema es exactamente la migración que el curso está
enseñando a ejecutar por partes**, y un material que lo escribe bonito en los ejemplos le
quita al lector la fricción que tiene que aprender a manejar. El día que una fase decida
renombrar algo, lo hace como paso de migración declarado, con su costo y su vuelta atrás.

De ahí sale el patrón que más aparece en el curso: **el nombre feo vive en el borde**. La
columna es `VLRUNIT`; la propiedad del modelo es `UnitPrice`; el mapeo entre las dos es
explícito, está en un solo sitio, y ese sitio es material didáctico. Cada vez que el curso
cruce esa frontera, la marca con 🧬.

### 5.2 Diccionario mínimo del dominio

Cordillera es un grupo editorial, y el dominio tiene que significar lo mismo en todo el curso:

- título (el libro como obra) → `Title`; edición → `Edition`; ISBN → `Isbn`
- sello → `Imprint`; catálogo → `Catalog`; fondo editorial → `Backlist`
- autor → `Author`; traductor → `Translator`; agente → `Agent`
- manuscrito → `Manuscript`; informe de lectura → `ReaderReport`; triaje → `Triage`
- contrato → `Contract`; cesión de derechos → `RightsAssignment`; territorio → `Territory`;
  vigencia → `Validity`, con `ValidFrom` y `ValidUntil`
- regalía → `Royalty`; liquidación → `Settlement`; impugnación → `SettlementDispute`
- tiraje → `PrintRun`; imprenta → `Printer`; orden de imprenta → `PrintOrder`
- almacén → `Warehouse`; existencias → `Stock`; movimiento de inventario →
  `InventoryMovement`
- distribuidor → `Distributor`; canal → `Channel`; punto de venta → `Retailer`
- venta al canal → `SellIn`; venta al lector → `SellOut`; devolución → `Return`
- precio → `Price`; lista de precios → `PriceList`; disponibilidad → `Availability`
- pedido → `Order`; despacho → `Shipment`
- estados de manuscrito: `received` → `triaged` → `under_review` → `accepted` | `rejected`
- estados de título: `draft` → `scheduled` → `published` → `out_of_print`

Los nombres de servicios y métodos se arman combinando estos términos con los verbos
habituales: `Get`, `Fetch`, `Create`, `Update`, `Publish`, `Settle`, `Reconcile`, `Issue`,
`Schedule`.

> ⚠️ **`Book` está prohibido** como identificador. En este dominio "libro" significa tres
> cosas que el curso nombra en el mismo párrafo —la obra, la edición concreta con su ISBN, y
> el ejemplar físico en un almacén— y confundirlas es la fuente del bug más caro de la
> historia. Siempre `Title`, `Edition` o `StockItem`.

### 5.3 Convenciones de nombrado

Las de .NET, sin creatividad: `PascalCase` para tipos, métodos, propiedades, eventos y
constantes; `camelCase` para parámetros y locales; `_camelCase` para campos privados; `I` de
prefijo para interfaces; sufijo `Async` en los métodos asíncronos; un tipo público por archivo,
con el nombre del archivo igual al del tipo.

Los puntos donde este perfil se equivoca por reflejo, y que conviene vigilar en cada revisión:

- **Nada de `IFooService` + `FooServiceImpl`.** En .NET la interfaz existe cuando hay más de
  una implementación o cuando hay que sustituirla en una prueba, no como trámite. La pareja
  interfaz-única-implementación es el olor a Java más fácil de detectar en una revisión.
- **Nada de `Manager`, `Helper`, `Util`, `Processor`.** Si el nombre no dice qué hace, el
  problema es el diseño.
- **Nada de getters y setters escritos a mano.** Existen las propiedades, y desde hace veinte
  años.
- **El espacio de nombres es el paquete.** No hace falta una clase estática para agrupar
  funciones sueltas si lo que tienes son métodos de extensión.

---

## 6. El estilo de código del curso

Aquí está la tentación grande, y en este curso tiene dos caras: escribir C# con estructura de
Java porque es lo que el lector sabe, o escribir todo con lo último del lenguaje porque
impresiona. Las dos son falsas.

### 6.1 La regla que ordena todo

> 🧭 **Código nuevo, estilo nuevo. Código heredado, se toca lo mínimo y en su propio estilo.**
> Un fix de tres líneas en un formulario de 2017 se escribe como el resto de ese formulario,
> con su `DataSet` y su C# 2. Un servicio nuevo se escribe con C# 14, nullable activado y
> `async` de punta a punta, aunque el de al lado no lo tenga.

El corolario, que es lo que el lector se lleva: **mezclar generaciones dentro de un mismo
archivo es peor que cualquiera de las dos puras**, y **modernizar mientras arreglas es cómo se
rompen otras tres cosas**.

Toda fase declara en su encabezado en qué estilo está escrita: **heredado**, **nuevo** o
**mixto 🧬**. Es lo primero que el lector necesita saber, y lo que evita que copie un patrón
del bloque de migración dentro de un servicio nuevo.

### 6.2 Qué es "estilo heredado" en SIGE

Vive en el código de 2016-2019 que el curso escribe para después migrarlo, y se reconoce por:

- **.NET Framework 4.5 y C# escrito como C# 2**: sin LINQ, sin `var`, sin genéricos más allá
  de `List<T>`, sin `async`.
- `DataSet`, `DataTable` y `SqlDataAdapter`; `SqlConnection` abierta en el manejador del botón.
- La lógica de negocio en **procedimientos almacenados**, y lo que no cupo ahí, en el
  `Click` del formulario.
- Cadena de conexión en el `App.config`, la misma para las noventa instalaciones.
- Concatenación de cadenas para armar SQL, incluido el `UNION ALL` de treinta tablas anuales.

Nada de esto se escribe con vergüenza ni con guiños de superioridad: se escribe con su fecha
al lado. Y nada se refactoriza por reflejo — se comenta que hoy se escribiría distinto, se
enlaza a la fase que lo cobra, y se sigue.

### 6.3 Qué es "estilo nuevo" en el curso

- `<Nullable>enable</Nullable>` y **advertencias como errores**, desde el primer proyecto y sin
  apagarse nunca, ni en un ejercicio ni para simplificar un ejemplo.
- `async`/`await` de punta a punta, con `CancellationToken` propagado. **Nunca `async void`
  fuera de un manejador de eventos, nunca `.Result` ni `.Wait()`.**
- LINQ donde aclara, y un bucle donde LINQ no aclara. La consulta de siete `SelectMany`
  anidados es peor que el `foreach`.
- `record` para datos inmutables y DTO; `class` para entidades con identidad; `struct` solo
  cuando hay una razón medida.
- Pattern matching y `switch` de expresión en vez de cadenas de `if` con casts.
- Inyección de dependencias del contenedor de `Microsoft.Extensions.DependencyInjection`, con
  los tiempos de vida explicados donde importen.
- `IDisposable`/`IAsyncDisposable` con `using` para todo lo que se abre, incluidos los propios.
- Errores del dominio como excepciones propias con jerarquía mínima, o un tipo de resultado
  donde el fallo sea esperado — y la decisión entre las dos se explica, no se asume.

### 6.4 Lo idiomático que este perfil no escribe solo

Cada uno aparece cuando corresponde, y **siempre con su contraejemplo en el estilo que el
lector habría escrito**, porque la lección está en la comparación:

- **Propiedades, `init` y `required`** en vez del constructor con doce parámetros y los
  setters.
- **Evaluación diferida de LINQ** en vez de materializar. Y su reverso, que es el bug más
  común del que cruza: el `IEnumerable` recorrido dos veces, que ejecuta la consulta dos veces.
- **`IAsyncEnumerable` y flujo en vez de lista completa**, que es la diferencia entre el
  reporte de 500.000 filas y el proceso de 1,8 GB.
- **Tipos por valor de verdad**: `struct`, semántica de copia, y el `record struct` que
  resuelve lo que en Java exige una clase.
- **Métodos de extensión** en vez de la clase estática `Utils`.
- **Delegados y eventos** en vez de la interfaz de un solo método con una implementación
  anónima.
- **`Span<T>` y `Memory<T>`** para el archivo de ventas del distribuidor, con su medición al
  lado y su advertencia: es la última optimización, no la primera.
- **Nullable reference types** como diálogo con el compilador, no como decoración. El `!` que
  silencia una advertencia es una deuda 💸 y se declara como tal.

### 6.5 Dinero, fechas y zona horaria

`decimal` para dinero, nunca `double`. Una liquidación trimestral de regalías con tasas de
cambio de tres distribuidores es exactamente donde el error de redondeo se vuelve una
impugnación de una traductora ocho meses después.

`DateTimeOffset` con desplazamiento explícito, nunca un `DateTime.Now` suelto donde importe el
día, y `TimeProvider` donde el tiempo tenga que poder simularse en una prueba. Cordillera
publica a medianoche en nueve husos y liquida por mes natural contra plataformas que reportan
en semanas ISO; ese conflicto es material del curso, no un detalle.

Y una regla de auditoría que sale de la historia: **una tasa de cambio usada en un cálculo se
guarda con el cálculo**. No se vuelve a consultar. Reproducir un número de hace ocho meses no
puede depender de que una API externa siga respondiendo lo mismo.

---

## 7. Marcadores y callouts

Vocabulario visual compartido por todos los documentos.

### 7.1 Marcadores de estado

- 💸 **Deuda técnica intencional.** Un atajo que se deja a propósito, declarando qué sería lo
  correcto y **en qué fase se paga**. Un 💸 sin destino es un error de escritura.
- 🔥 **Opcional o ampliación.** Fases, secciones y ejercicios fuera del camino base.
- ⭐ **Pieza central.** Las fases de las que depende la tesis del curso.
- 🧬 **Convivencia de generaciones.** Marca el sitio exacto donde el código nuevo toca al
  heredado: el borde que traduce `VLRUNIT` a `UnitPrice`, el servicio moderno que llama a un
  procedimiento almacenado de 1997, el proceso .NET 10 que habla con "el Fox" de Lima. Es el
  marcador propio de este curso y el que más se busca en un `Ctrl+F`.
- 🧱 **Miniproyecto.** Marca la sección obligatoria de cierre de cada fase.
- 📏 **Medición.** Marca un número producido por el arnés del curso, con sus condiciones.
- 🟢🟡🟠🔴 **Dificultad de ejercicios.** En este curso el piso está más arriba que en otros:
  ver §9.
- 🏷️ **Tag de progreso.** El recordatorio de cerrar la fase en git. Va una sola vez por
  documento, al final.
- 🪦 **Pendiente cerrado.** Un 📌 que se resolvió: se marca así en vez de borrarlo, con dónde
  quedó la respuesta.
- 🧨 **Rompe a propósito.** Un experimento destructivo con resultado observable.
- 🪟 **Requiere Windows.** Marca las fases y secciones del bloque de escritorio, y cualquier
  ejercicio que no se pueda hacer en Linux o macOS.

### 7.2 Callouts en blockquote

- 📝 **Nota de ecosistema.** Qué versión trajo esta API, qué reemplazó, y por qué lo anterior
  sigue vivo en el código que el lector va a encontrar por ahí.
- 📚 **Referencia rápida inline.** El enlace útil justo donde nace la duda.
- ⚠️ **Advertencia.** Algo que rompe si lo ignoras.
- 💡 **Truco o atajo** que ahorra tiempo real.
- 🧭 **Regla del curso.** Una decisión que aplica en todo el material y que el lector debería
  poder citar de memoria al terminar.
- ⚖️ **Veredicto.** Dónde esto pierde, y contra qué.
- 🧠 **Modelo mental.** La imagen que hace que el resto encaje, cuando la hay.

### 7.3 Secciones narrativas recurrentes

Micro-secciones con nombre fijo, que aparecen cuando el contenido las pide. Las cuatro
primeras son las del repositorio y **son obligatorias donde la fase las pida**:

- 🪞 **"Tu instinto de Java dice… y esta vez se equivoca."** El reflejo concreto, el código que
  produce, por qué falla aquí, y qué se escribe en su lugar. Es la sección insignia del curso.
- 🩻 **"Esto sí funciona igual."** Lo que se transfiere sin cambios. Importa tanto como lo
  anterior: sin ella, el lector desconfía de todo su oficio.
- ⚰️ **Autopsia de anti-patrón.** Un mal uso recurrente con su costo en números antes y
  después.
- 📖 **Diccionario de traducción.** Concepto ⇄ concepto, en las **dos** direcciones, con una
  tercera columna obligatoria: dónde se rompe el paralelo.
- **Detalles con intención.** Lista corta con las decisiones deliberadas de un bloque de
  código y su porqué.
- **El patrón a memorizar.** Una o dos frases que destilan la lección transferible.
- **Prueba de fuego.** Verificación concreta: qué ejecutar, qué esperar, y qué mentira te va a
  contar la salida si miras el lugar equivocado.
- **La señal de que quedó bien.** En el cierre, un criterio en forma de cita.

---

## 8. Plantilla obligatoria de cada fase (10 secciones)

Toda fase produce un `.md` con exactamente estas diez secciones, en orden. El esqueleto
rellenable está en [`plantillas-de-capitulo.md`](plantillas-de-capitulo.md).

1. **🎯 Propósito** — qué resuelve la fase y a qué decisión sirve.
2. **✅ Qué queda listo al terminar** — checklist verificable, no promesas.
3. **🚫 Qué NO entra todavía** — qué se difiere y a qué fase exacta.
4. **🧠 Concepto mínimo** — la teoría justa, anclada al dominio. Aquí caben 🪞, 🩻, 📖 y las
   📝 Notas de ecosistema.
5. **💻 Código mínimo con comentarios** — el grueso. Código ejecutable, identificadores nuevos
   en inglés, comentarios en español, escrito en el estilo declarado de la fase.
6. **📏 Medición** — el número que esta fase produce, con sus condiciones, su competidor y su
   veredicto. Las fases que no midan nada lo dicen en una línea y explican por qué.
7. **🧱 Miniproyecto** — obligatorio, uno por fase. Formato en
   [`formato-de-miniproyectos.md`](formato-de-miniproyectos.md).
8. **🧪 Ejercicios** — ver §9.
9. **📚 Referencias** — ver §10.
10. **🚀 Cierre** — qué sigue, por qué, La señal de que quedó bien y el recordatorio 🏷️ del
    tag.

Después de la décima, y fuera de lo que lee el lector, cada fase cierra con **📌 Pendientes
sugeridos**: lo que apareció al escribirla y no cabía adentro, con destino explícito. Es
material de autoría, no de lectura.

> 🧭 **No hay plantilla de apéndice porque no hay apéndices.** Es la decisión de forma del
> curso y está en `alcance-del-proyecto.md` §6. Cuando aparezca material que "sería un buen
> apéndice", los destinos legítimos son tres: sección de esta fase, fase propia, o 📌.

### 8.1 El avance de proyecto, en el encabezado y en el cuerpo

Toda fase declara en su encabezado **qué proyecto avanza** y **en qué queda ese proyecto al
terminar**. No es decoración: es lo que impide que el curso se convierta en una colección de
ejemplos sueltos.

La regla de forma: el avance se escribe en la sección 5 como parte del código de la fase, no
como un apartado aparte, y el checklist de la sección 2 incluye al menos un ítem verificable
del proyecto. Una fase que no mueve ningún proyecto está mal ubicada en la secuencia.

### 8.2 El recordatorio del tag, en el cierre

Toda fase termina con un bloque 🏷️ de forma fija, después de La señal de que quedó bien y
antes del `---` que abre los 📌:

````markdown
> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde,
> el miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-07 -m "F7 cerrada: <el checklist, en una línea por ítem>"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 07: …`), los de ejercicio su número
> (`fase 07 ej12: …`) y el miniproyecto el suyo (`fase 07 mini: …`). El miniproyecto
> terminado lleva además su propio tag anotado, `mini-07`, cuyo mensaje incluye el
> número que arrojó su medición.
````

El nombre del tag es **`fase-` + el número de dos dígitos**, no el slug del archivo. El tag
`mini-NN` existe porque un miniproyecto es un entregable comparable entre lectores: el mensaje
del tag es donde vive su número, y `git show mini-07` es la forma de recuperarlo.

---

## 9. Ejercicios

- **Cantidad: 20 mínimo, 25 ideal por fase.** El curso invierte en el miniproyecto lo que los
  cursos de legacy del repositorio invierten en volumen de ejercicios, y eso está declarado
  como divergencia: la banda del repositorio es 20-30, y aquí se usa la mitad baja a propósito.
- **El piso de dificultad está más arriba.** Para un dev Java senior, un 🟢 no es "copia el
  ejemplo": es "aplica lo de la fase a un caso que no está resuelto en el texto". La escala
  completa está calibrada para ese lector:

  | | Qué significa **en este curso** |
  |---|---|
  | 🟢 | Aplicación directa de lo de la fase a un caso nuevo del dominio. Se resuelve leyendo la fase. |
  | 🟡 | Requiere consultar documentación oficial que la fase no transcribió. |
  | 🟠 | Combina dos o más temas, o exige depurar algo que falla de forma no obvia. |
  | 🔴 | Abierto o adversarial: medir un anti-patrón, romper una garantía, defender una decisión con números. |

- **Distribución para ~25 ejercicios:** unos 6 🟢, 8 🟡, 7 🟠 y 4 🔴, más los 🔥 aparte.
- **Numeración continua con encabezado de rango:**

  ```markdown
  ## 🧪 Ejercicios (25)

  **🟢 Fácil (1–6)**
  1. ...

  **🟡 Intermedio (7–14)**
  **🟠 Difícil (15–21)**
  **🔴 Muy difícil (22–25)**
  **🔥 Opcionales**
  ```

- **Accionables y verificables.** *"Haz que el reporte histórico corra en memoria constante y
  demuéstralo midiendo el pico con el arnés de la fase"* — no *"reflexiona sobre la evaluación
  diferida"*.
- **Al menos un tercio son de diagnóstico o de medición**, no de construcción: se entrega algo
  que funciona mal y se pide localizar, explicar y cuantificar.
- **Al menos dos por fase son de decisión:** dado un módulo o un encargo, decidir si **se
  migra, se envuelve o se deja quieto**, y justificarlo con el costo de las otras dos. Es el
  músculo central del curso y no se entrena solo.
- **Al menos uno por fase, desde el bloque de migración, es de generación 🧬:** dado un
  archivo, decidir si el fix va en estilo nuevo o heredado, y justificarlo.
- **Enganchados al dominio.** Títulos, sellos, regalías, tirajes, devoluciones, manuscritos.
  Nunca `foo` y `bar`.
- **Con el identificador vigente.** Si el ejercicio nombra código, usa el nombre que ya existe
  en la fase — y si nombra el esquema heredado, lo escribe tal cual (§5.1).
- **Marcados 🪟 los que exijan Windows**, sin excepción.

---

## 10. Bibliografía y referencias

**Regla:** documentación oficial de la versión fijada primero; después las especificaciones y
notas de diseño del lenguaje cuando expliquen el porqué; después libros; después charlas y
blogs. Siempre se advierte cuando un enlace apunta a una versión distinta de la que usamos.

### 10.1 Formato

URLs completas y clicables, nunca solo el dominio. Dentro de "Referencias" se separa en
documentación oficial, especificaciones cuando apliquen, libros, video y apoyo, y una línea
final de **orden de lectura sugerido**.

### 10.2 Fuentes por defecto

- **Documentación de .NET y C#:** `https://learn.microsoft.com/dotnet/` — con la advertencia
  de fijar la versión en el selector, porque por defecto sirve la más reciente.
- **Especificación y propuestas del lenguaje:** el repositorio `dotnet/csharplang`, citado
  cuando explique una decisión de diseño y no como adorno de autoridad.
- **NuGet** para la ficha de cualquier dependencia que el curso fije.
- La documentación oficial de cada pieza del stack —EF Core, ASP.NET Core, SQL Server, los
  servicios de Azure que el curso mida— enlazada a su versión.

### 10.3 Advertencias

- Cuando se cite un libro, artículo o charla, se aclara que el título o la URL pueden haber
  cambiado y conviene verificarlos. **No se inventan números de página, ISBN ni
  identificadores de video.**
- **No usar en el código principal** APIs posteriores a la versión fijada. Aparecen como
  comparación, marcadas 🔥.
- Cuidado con el material de internet anterior a .NET Core: buena parte de lo que el lector va
  a encontrar sobre configuración, hosting, acceso a datos y despliegue describe .NET Framework
  y no aplica. Cuando eso importe, se dice — y en este curso importa seguido, porque el sistema
  heredado **es** .NET Framework y la confusión es real.

---

## 11. Coherencia de la ficción

La empresa del curso se llama **Cordillera Media** y es ficticia. Su historia completa
—personajes, cifras, cronología y reglas de negocio— vive en
[`historia-propuesta-1-cordillera.md`](historia-propuesta-1-cordillera.md), que es la fuente
de verdad narrativa. El curso **construye su software pieza por pieza**, incluido el trozo de
sistema heredado que después se migra: al terminar, el lector tiene el código en su disco y
puede abrir cualquier archivo del que el material haya hablado.

Eso impone cinco reglas.

**Regla 1 — Si el curso afirma que algo está así en SIGE, tiene que poder mostrarlo.** *"Así
lo hace el sistema"* es legítimo cuando el código está en alguna fase, y solo entonces.

**Regla 2 — Lo que Cordillera tiene y el curso no construye se cuenta como historia, no como
observación.** Hay cosas que importan y no caben en un curso: los 340 formularios, los 700
procedimientos, las cuarenta pantallas de Redacción. Se cuentan **en pasado y como contexto**:

> ✅ *"El sistema arrastra 340 formularios que nadie migró; acá construyes tres y el reflejo
> que te llevas es no tocar los otros 337 sin motivo."*
>
> ❌ *"El módulo de inventario tiene un bug en el cálculo de existencias."*

La segunda promete un código que nadie puede abrir.

**Regla 3 — La cronología es fija**, y está en §3 de la historia: 1988 dBase, 1993 FoxPro sin
red, 1995 el coaxial, 1997 Visual FoxPro 5 y el modelo de datos que llega hasta hoy, 2004 VFP
9, 2007 el fin de línea, 2015 el fin del soporte, 2016-2017 la migración de los pasantes, 2019
los ASMX, 2020 el *lift and shift*, 2026 el presente. **Ninguna decisión del sistema puede
justificarse con algo que no existía cuando se tomó**, y toda 📝 Nota de ecosistema se sitúa
dentro de esa línea.

**Regla 4 — Ningún ejercicio pide algo que solo se pueda hacer con un sistema que el lector no
tiene.** Ni "compara con cómo lo resuelve tu empresa", ni "pregúntale a tu equipo", ni
"verifica esto contra tu suscripción de Azure". Las versiones están fijadas y la nube se
emula o se declara (`alcance-del-proyecto.md` §10).

**Regla 5 — Nadie es el villano.** Wilson no es desarrollador y nunca dijo que lo fuera. Duván
sostiene solo, desde hace nueve años, algo que no diseñó. Los tres pasantes hicieron en once
meses lo que nadie más quiso hacer. El curso analiza sistemas y decisiones, no personas, y
cualquier párrafo que se lea como burla se reescribe.

> 🧭 **El corolario, que es lo que se gana:** el curso se puede tomar entero, de principio a
> fin, sin acceso a nada más que a este repositorio, un SDK de .NET y un runtime de
> contenedores. Cualquier frase que rompa eso es un error de estilo, aunque esté bien escrita.

---

## 12. Coherencia entre documentos

- **No contradecir fases anteriores.** Un fragmento de la fase 12 no puede usar una forma del
  dominio distinta a la que definió la fase 4.
- **No reescribir decisiones aprobadas** sin señalar la incompatibilidad y explicar por qué.
- **Nombres estables.** Proyectos, clases, tablas y modelos se mantienen idénticos entre
  fases. Si algo se renombra, se documenta como paso de migración y se ajustan las fases
  afectadas.
- **Fuentes de verdad, en este orden:** (1) instrucciones del proyecto y el `CLAUDE.md` del
  repositorio, (2) `alcance-del-proyecto.md`, (3) `propuesta-fases-y-alcance.md`, (4) esta
  guía, (5) `plantillas-de-capitulo.md` y `formato-de-miniproyectos.md`,
  (6) `historia-propuesta-1-cordillera.md` para todo lo narrativo, (7) entregables ya aprobados
  de fases anteriores, (8) decisiones explícitas del chat actual.
- **Autocontención.** El curso no remite a otros cursos del repositorio como material
  necesario. Puede enlazarlos como profundización opcional, declarándolo — y en particular
  **no nombra al curso hermano de Python**, con el que comparte el origen de la historia de
  Cordillera pero ninguna dependencia.

---

## 13. Checklist antes de dar por cerrado un `.md`

- [ ] Sigue la plantilla de 10 secciones, sin secciones extra ni reordenadas.
- [ ] Tono semiformal y colegial, tuteo latinoamericano, humor con moderación, cero
      condescendencia hacia el código heredado.
- [ ] No explica nada que un dev Java senior ya sabe.
- [ ] Explica el problema antes que la herramienta, y el porqué de cada decisión.
- [ ] Prosa antes que listas; listas antes que tablas en comparativas extensas.
- [ ] Todo el código compila con las versiones fijadas en `alcance-del-proyecto.md` §9.
- [ ] **Todo el código nuevo en inglés** y **todos los comentarios en español, con tildes**;
      mensajes de error y de log también en español (§5).
- [ ] **El esquema heredado aparece con sus nombres reales**, sin traducir ni corregir (§5.1),
      y cada cruce de frontera va marcado 🧬.
- [ ] El código está escrito **en el estilo declarado de su fase** (§6.1), y no mezcla
      generaciones dentro de un mismo archivo.
- [ ] Nullable activado; cero `.Result`/`.Wait()`; `CancellationToken` propagado; `decimal`
      para dinero; `DateTimeOffset` con desplazamiento explícito.
- [ ] Cada analogía con Java declara **dónde se rompe** (§4.2).
- [ ] Cada 💸 declara dónde se paga, o por qué no se paga.
- [ ] Cada afirmación comparativa tiene su 📏 con condiciones y competidor real (§4.6), y
      cuando toca la base de datos, mide **primero SQL y después .NET**.
- [ ] Ningún servicio de nube se describe sin su costo al volumen de Cordillera y sin su
      amarre (§4.7).
- [ ] **Declara el proyecto que avanza** y deja al menos un ítem verificable de ese avance en
      el checklist de la sección 2 (§8.1).
- [ ] Tiene 20-25 ejercicios con rangos 🟢🟡🟠🔴 calibrados para el perfil, un tercio de
      diagnóstico o medición, al menos dos de decisión y uno de generación 🧬.
- [ ] **Tiene su miniproyecto 🧱**, con criterios de aceptación verificables y calibrado para
      que no se resuelva copiando la fase.
- [ ] Lo que exige Windows va marcado 🪟.
- [ ] Referencias con URL completa a la versión correcta, con advertencia cuando no lo sea, y
      sin datos bibliográficos inventados.
- [ ] No contradice ninguna fase anterior, ni en pedagogía ni en nombres.
- [ ] Coherencia de la ficción (§11): nada que afirme sobre SIGE algo que el curso no pueda
      mostrar, cronología respetada, y nadie tratado como villano.
- [ ] Incluye "La señal de que quedó bien" en el cierre.
- [ ] Lleva el bloque 🏷️ del tag al final, con el número correcto (§8.2).
- [ ] **No hay ningún apéndice** ni ninguna promesa de uno.
FIN
wc -l /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs/prompts/guia-de-estilo-y-convenciones.md

# --- 2026-09-12T23:16:52 · Write chapter template
cat > /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs/prompts/plantillas-de-capitulo.md <<'FIN'
# 🧩 Plantilla de capítulo
## C# para desarrolladores Java senior

Este archivo contiene **un solo esqueleto**, el de fase, porque el curso **no tiene apéndices**
(`alcance-del-proyecto.md` §6). Se copia al abrir el chat que redacta una fase, se rellenan los
`{{placeholders}}` y se borran las notas entre llaves antes de entregar.

Junto con la guía de estilo y el alcance, forma el marco para que las fases, escritas cada una
en su chat, se lean como un solo documento.

> **Nota de coherencia:** el número de fases, sus nombres, su bloque y el proyecto que cada una
> avanza salen de `propuesta-fases-y-alcance.md`. Si alguna vez cambian, **se cambian allí
> primero** y esta plantilla después.

---

# 📐 Plantilla de fase

````markdown
# {{emoji}} Fase {{NN}} — {{Nombre}}

> C# para desarrolladores Java senior · Fase {{N}} de {{total}} · Bloque {{letra — nombre}}
> Depende de: {{fase previa}} · Habilita: {{fase siguiente}}
> Estilo de esta fase: {{heredado (.NET Framework 4.5, C# 2) | nuevo (.NET 10, C# 14) | mixto 🧬}}
> Proyecto que avanza: {{cuál, y en qué queda al terminar}}
> {{Si aplica: 🪟 **Requiere Windows.** Esta fase no se puede completar en Linux ni en macOS.}}

---

## 🎯 1. Propósito

{{Una o dos frases: qué resuelve esta fase y a qué decisión sirve. Anclar al dominio de
Cordillera. No "aprenderás X": qué vas a poder decidir o construir que antes no.}}

---

## ✅ 2. Qué queda listo al terminar

- [ ] {{resultado verificable 1}}
- [ ] {{resultado verificable 2 — al menos uno es del proyecto que avanza}}
- [ ] {{...3 a 5 ítems}}
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

{{Verificable = se comprueba ejecutando algo. "Entender X" no es un resultado verificable.}}

---

## 🚫 3. Qué NO entra todavía

- {{tema diferido}} → Fase {{M}}.
- {{...}}

{{Y si algo se difiere **fuera del curso**, se dice aquí con su razón. No hay apéndice al que
mandarlo.}}

---

## 🧠 4. Concepto mínimo

{{Solo la teoría que hace falta para escribir el código de esta fase. Prosa, no bullets. El
problema antes que la herramienta.}}

{{Aquí viven las secciones narrativas que la fase pida:}}

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

{{El reflejo concreto, el código que produce, por qué falla aquí, y qué se escribe en su lugar.
Con el contraejemplo al lado, porque la lección está en la comparación.}}

### 🩻 Esto sí funciona igual

{{Lo que se transfiere sin cambios. Importa tanto como lo anterior.}}

### 📖 Diccionario de traducción

| Java | C# / .NET | Dónde se rompe el paralelo |
|---|---|---|
| {{...}} | {{...}} | {{...}} |

{{En las dos direcciones. La tercera columna es obligatoria: una analogía sin su límite es peor
que ninguna — guía §4.2.}}

> 📝 **Nota de ecosistema.** {{Qué versión trajo esta API, qué reemplazó, y por qué lo anterior
> sigue vivo en el código que el lector va a encontrar por ahí — y en SIGE. Situada dentro de
> la cronología fija de la historia.}}

---

## 💻 5. Código mínimo con comentarios

{{El grueso de la fase. Código ejecutable, coherente con las versiones fijadas. Identificadores
nuevos en inglés, comentarios y documentación XML en español con tildes, mensajes de error y de
log en español, textos de interfaz en español.}}

{{**El avance del proyecto va aquí**, integrado en el código de la fase, no como un apartado
suelto — guía §8.1.}}

{{Estilo obligatorio — guía §6:
- **Escrito en el estilo declarado en el encabezado.** Heredado: `DataSet`, `SqlConnection` en
  el manejador del botón, C# 2, sin `async`. Nuevo: nullable activado, `async` de punta a punta
  con `CancellationToken`, `record` para datos, pattern matching, DI del contenedor.
- **Nunca las dos generaciones dentro del mismo archivo.** Los puntos de contacto van marcados
  con 🧬.
- **El esquema heredado conserva sus nombres** — `MOVINVEN`, `VLRUNIT`, `FECMOVTO`, `BORRADO`,
  `VENTAS_2019` — y el mapeo al modelo vive en un solo borde explícito (guía §5.1).
- Cero `.Result` y `.Wait()`; nada de `async void` fuera de un manejador de eventos.
- `decimal` para dinero; `DateTimeOffset` con desplazamiento explícito; la tasa de cambio usada
  en un cálculo se guarda con el cálculo.
- Nada de `IFooService` + `FooServiceImpl`, ni `Manager`, `Helper`, `Util`.}}

{{💸 Marcar cada deuda técnica intencional con una nota de dos partes: qué sería lo correcto, y
**en qué fase se paga**. Si no se paga, decirlo y explicar por qué.}}

**Detalles con intención**
- {{decisión deliberada del bloque anterior}} — {{su porqué}}.

**El patrón a memorizar**
> {{Una o dos frases con la lección transferible del fragmento.}}

**Prueba de fuego**
{{Verificación concreta: qué ejecutar, qué esperar, y qué mentira te va a contar la salida si
miras el lugar equivocado.}}

---

## 📏 6. Medición

{{El número que esta fase produce. Formato fijo, y va también a `BENCHMARKS.md`.}}

**Hipótesis:** {{la afirmación que se va a sostener o a tumbar, en una línea.}}

**Condiciones:** {{versión del SDK, máquina, tamaño del dato, número de repeticiones, qué se
mide y con qué arnés.}}

**Competidores:** {{contra qué se compara. Si el competidor es el stack de origen o el código
heredado, tiene que ser una implementación que alguien defendería en una revisión — guía §4.6.}}

**Resultado:**

| {{Opción}} | {{Métrica}} | {{Métrica 2}} |
|---|---|---|
| {{...}} | {{...}} | {{...}} |

> ⚖️ **Veredicto.** {{Qué gana, dónde pierde, y a partir de qué umbral cambia la respuesta.}}

{{Si la fase toca la base de datos, el orden es obligatorio: **primero el plan de consulta,
después .NET** — guía §4.6.}}

{{Si esta fase no mide nada, esta sección dice en una línea por qué —y esa línea tiene que ser
convincente. Una fase sin medición es la excepción, no la norma.}}

---

## 🧱 7. Miniproyecto — {{Nombre}}

{{Obligatorio, uno por fase. El formato completo, con sus reglas de calibración, está en
`formato-de-miniproyectos.md` y se sigue literal. Va aquí desarrollado, no enlazado.}}

**El encargo** · **Por qué duele** · **Datos de entrada** · **Criterios de aceptación** ·
**Restricciones de estilo y alcance** · **La trampa** · **Pistas** · **Cómo se entrega**

---

## 🧪 8. Ejercicios ({{total}})

**🟢 Fácil (1–{{a}})**
1. {{...}}

**🟡 Intermedio ({{a+1}}–{{b}})**
**🟠 Difícil ({{b+1}}–{{c}})**
**🔴 Muy difícil ({{c+1}}–{{total}})**
**🔥 Opcionales**

{{20 mínimo, 25 ideal. Escala calibrada para un dev Java senior: un 🟢 no es "copia el ejemplo",
es "aplícalo a un caso que el texto no resolvió" — guía §9. Al menos un tercio de diagnóstico o
medición, al menos dos de decisión (**¿se migra, se envuelve o se deja quieto?**) y, desde el
bloque de migración, al menos uno de generación 🧬. Lo que exija Windows va marcado 🪟.}}

---

## 📚 9. Referencias

**Documentación oficial**
- {{URL completa}} — {{nota de versión; recordar fijar la versión en el selector de
  learn.microsoft.com, que por defecto sirve la más reciente}}

**Especificación y propuestas del lenguaje** (cuando expliquen el porqué de un diseño)
- {{...}}

**Libros / artículos** (si aplican)
**Video / apoyo**

**Orden de lectura sugerido:** {{qué leer antes de escribir código → qué consultar durante → a
qué volver después}}

> ⚠️ {{URLs, títulos y contenidos pueden haber cambiado; el lector debe verificarlos. No se
> inventan páginas, ISBN ni identificadores de video. Advertir cuando un enlace describa .NET
> Framework y no .NET moderno, que en este curso pasa seguido.}}

---

## 🚀 10. Cierre y conexión con la siguiente fase

{{Qué quedó construido, en qué quedó el proyecto que avanzó, y por qué la Fase {{siguiente}} es
el paso natural: qué necesita de esta fase para existir.}}

> **La señal de que quedó bien:** {{criterio en forma de cita — cómo se siente el trabajo bien
> hecho de esta fase.}}

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-{{NN}} -m "F{{N}} cerrada: <el checklist, en una línea por ítem>"
> ```
>
> Los commits de la fase llevan su prefijo (`fase {{NN}}: …`), los de ejercicio su número
> (`fase {{NN}} ej12: …`) y el miniproyecto el suyo (`fase {{NN}} mini: …`). El miniproyecto
> terminado lleva además su tag anotado `mini-{{NN}}`, y **en el mensaje de ese tag va el
> número que arrojó su medición** — es donde se recupera después con `git show`.
>
> {{Si la fase tiene algo propio que decir sobre git —paga una deuda 💸 declarada antes y el
> diff entre dos tags es la factura, ejecuta un paso de migración con vuelta atrás— va un
> párrafo corto acá, no un bloque nuevo.}}

---

## 📌 Pendientes sugeridos

{{Material de autoría, no de lectura. Lo que apareció al escribir la fase y no cabía adentro,
con destino explícito: otra fase, un ejercicio 🔥, una medición que falta, una entrada nueva de
`BENCHMARKS.md` o una decisión de proyecto. **Nunca "un apéndice": no existen.**}}
````

---

## Recordatorios al rellenar una fase

- **Declara el estilo de la fase en el encabezado.** Es lo primero que el lector necesita
  saber, y lo que evita que copie el `DataSet` del bloque de migración dentro de un servicio
  nuevo — o al revés, que "arregle de paso" un formulario de 2017 y rompa otras tres cosas.
- **Declara el proyecto que avanza, y hazlo avanzar de verdad.** Una fase que no mueve ningún
  proyecto está mal ubicada en la secuencia y se replantea antes de escribirla.
- El número de fases y sus nombres salen de `propuesta-fases-y-alcance.md`. Ninguna fase se
  renumera por su cuenta.
- No contradecir nombres de proyectos, clases, tablas ni modelos definidos en fases previas.
  Ante la duda, revisar el entregable anterior y el diccionario de la guía §5.2.
- **Cada fase produce una medición**, y la excepción se justifica en una línea. El número va
  también a `BENCHMARKS.md`.
- **Cada fase produce un miniproyecto**, y no se resuelve copiando la fase. Si se resuelve
  copiando la fase, está mal calibrado: `formato-de-miniproyectos.md` §3.
- Las versiones salen de `alcance-del-proyecto.md` §9. Ninguna se da por buena de memoria y
  ninguna se verifica contra un sistema externo.
- Coherencia de la ficción: Cordillera es del curso. Si una fase afirma que algo está así en
  SIGE, tiene que poder mostrarlo (guía §11), la cronología es fija y nadie es el villano.
- **Si aparece material que "sería un buen apéndice"**, tiene tres destinos legítimos: sección
  de esta fase, fase propia, o 📌 con su razón escrita.
FIN
wc -l /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs/prompts/plantillas-de-capitulo.md

# --- 2026-09-12T23:17:56 · Write miniproject format
cat > /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs/prompts/formato-de-miniproyectos.md <<'FIN'
# 🧱 Formato de los miniproyectos
## C# para desarrolladores Java senior

Cada fase cierra con **un miniproyecto obligatorio**. Es la sección 7 de la plantilla y el
mecanismo principal de consolidación del curso: ocupa el lugar que en los cursos de legacy del
repositorio ocupa el cuaderno de incidentes.

Este documento define qué es, cómo se calibra y qué forma tiene. Se sigue literal.

---

## 1. Qué es un miniproyecto, y qué no

> 🧭 **Un miniproyecto es un encargo pequeño, completo y difícil, que solo se puede terminar si
> entendiste el tema de la fase — no si lo leíste.**

Tiene tres propiedades no negociables:

- **Es completo.** Entra un dato real del dominio y sale un resultado verificable. No es un
  fragmento ni un ejercicio de rellenar huecos: compila, se ejecuta, produce algo.
- **Es pequeño.** Entre dos y cinco horas de trabajo para el lector objetivo. Si necesita un
  fin de semana, es un proyecto y no cabe en una fase.
- **Es difícil**, en el sentido concreto de la §3.

Y no es ninguna de estas cosas:

- **No es el ejercicio 26.** Los ejercicios entrenan piezas; el miniproyecto integra.
- **No es el avance de proyecto de la fase.** Cada fase mueve uno de los proyectos que
  atraviesan el curso, y eso va en la sección 5, dentro del código de la fase. El miniproyecto
  es de usar y tirar: consolida el tema y se archiva con su tag.
- **No es una versión recortada de la fase.** Si el encargo se cumple copiando el código de la
  sección 5 y cambiando nombres, está mal diseñado.

---

## 2. Por qué existe, y por qué sustituye al cuaderno de incidentes

Los cursos de legacy del repositorio enseñan a **arreglar** un sistema que ya existe, y por eso
su unidad de práctica es el incidente: un síntoma, una reproducción, una causa raíz.

Este curso hace las dos cosas —construir moderno y cortar un sistema vivo—, y por eso su unidad
de práctica tiene que ser un encargo. La pregunta que el lector se hace al empezar un
miniproyecto es la misma que se va a hacer el lunes en su trabajo: *¿esto se migra, se envuelve
o se deja quieto, y qué me cuesta cada respuesta?*

Hay un segundo motivo, y es el perfil. Un dev Java senior aprende resolviendo, no leyendo. El
material puede explicar la evaluación diferida de LINQ durante cuatro páginas y el reflejo no
cambia; el reflejo cambia cuando la consulta se ejecuta dos veces contra la base y el perfilador
lo muestra.

> 📝 **Lo forense no se pierde: se absorbe.** En el bloque del sistema heredado y en el de
> migración, la forma natural del miniproyecto es **un encargo de diagnóstico**: aquí está el
> síntoma que reportó Nohora, aquí está el código, encuentra la causa, arréglala con el parche
> mínimo y escribe la prueba de regresión que falla antes y pasa después. Eso es un incidente
> con otro nombre, y cabe entero en este formato.

---

## 3. Calibración: qué significa "difícil" aquí

La audiencia sabe resolver mirando ejemplos y leyendo documentación. Calibrar para ese lector
significa cuatro cosas concretas:

1. **El texto de la fase no alcanza.** El miniproyecto exige al menos una consulta a la
   documentación oficial sobre algo que la fase mencionó pero no transcribió. Eso es
   deliberado: leer documentación es parte del oficio que el curso entrena.
2. **Hay una decisión de diseño real que el enunciado no toma.** Dos caminos defendibles, con
   costos distintos. El lector elige y justifica; la solución de referencia elige uno y explica
   por qué, sin descalificar el otro.
3. **Hay una trampa.** Un punto donde el reflejo de Java produce algo que funciona con los
   datos de ejemplo y falla con los datos reales: el `IEnumerable` recorrido dos veces, el
   `.Result` que bloquea el hilo, el `double` que redondea mal la regalía, el `DateTime.Now`
   sin zona en un cálculo que cruza nueve husos, el `catch (Exception)` que se traga el error
   que importaba.
4. **El resultado se verifica solo.** Criterios de aceptación ejecutables, no impresiones.

> ⚠️ **La prueba de calibración, y es literal:** si puedes terminar el miniproyecto copiando el
> código de la sección 5 de la fase y renombrando variables, **está mal diseñado y se
> reescribe**. No se aprueba una fase cuyo miniproyecto no pase esta prueba.

Y el límite por el otro lado: un miniproyecto que necesita un paquete que la fase no introdujo,
una suscripción de nube de pago o un servicio externo que el lector no tiene, también está mal
diseñado. La dificultad viene del problema, no del montaje.

---

## 4. La estructura, sección por sección

Es la que va desarrollada dentro de la sección 7 de cada fase.

### 4.1 El encargo

Quién lo pide, en las palabras de esa persona, y qué necesita. Sale del dominio de Cordillera y
de su gente: Nohora necesita que un libro salga, Ximena no quiere un paso más en su flujo,
Gustavo decide un tiraje, Duván necesita poder mantenerlo cuando tú no estés, Clara pregunta
quién levanta esto si se cae un martes.

En prosa, dos o tres frases, con la voz del que pide — no con la voz del profesor. *"Duván te
escribe: 'el reporte histórico del comercial se está demorando cuatro minutos y el servidor se
queda sin memoria dos de cada cinco veces. Ya lo miré y no entiendo por qué, si la consulta en
Management Studio vuelve en ocho segundos'."*

### 4.2 Por qué duele

Qué hace difícil el encargo, en una o dos frases. Es lo que separa un miniproyecto de un
ejercicio: aquí se nombra la fricción real —el volumen, el esquema hostil, la regla de negocio
que tiene tres excepciones, el dato que llega mal una vez de cada seis, el hecho de que no se
puede apagar nada—.

### 4.3 Datos de entrada

Concretos y suficientes para trabajar: un fragmento representativo, la forma de los archivos o
del esquema, los casos límite que el lector va a encontrar. **Incluye siempre al menos un caso
sucio**, del tipo que produce el mundo real y no un generador de datos de prueba — y en este
curso el caso sucio tiene nombre y apellido: la fecha en `char(8)` que trae `'00000000'`, el
movimiento de inventario cuyo título ya no existe, la tilde que se comió la intercalación en la
importación de 2017, el registro con `BORRADO = 'S'` que media consulta olvida filtrar.

Si los datos los genera un script del propio curso, se dice cómo se ejecuta. Si son un fragmento
literal, va completo en el documento — el lector no debería tener que inventárselos. **Los
nombres del esquema heredado se escriben tal cual** (guía §5.1).

### 4.4 Criterios de aceptación

Lista corta de condiciones **ejecutables**. Cada una se puede comprobar corriendo algo.

> ✅ *"Procesa el archivo de 500.000 filas con un pico de memoria administrada por debajo de
> 80 MB, medido con el arnés de la fase."*
>
> ❌ *"Usa `IAsyncEnumerable` de forma eficiente."*

Entre tres y seis criterios. Uno de ellos, siempre, es **de medición**: el miniproyecto produce
un número, y ese número es lo que va en el mensaje del tag `mini-NN`.

### 4.5 Restricciones de estilo y alcance

La regla que ata el miniproyecto al tema y al estilo de la fase. Se escribe explícita, y en este
curso tiene dos formas según el bloque:

> *"Esto es código nuevo. Nullable activado, advertencias como errores, `async` de punta a punta
> con `CancellationToken`. Si te descubres escribiendo `IRepositoryImpl`, ese es exactamente el
> reflejo que la fase está atacando."*

> *"Esto es un fix sobre código de 2017. Se escribe en el estilo de ese archivo, con su
> `DataSet` y sin `async`. Modernizar mientras arreglas es cómo se rompen otras tres cosas, y
> aquí se penaliza."*

Cuando el miniproyecto cruce la frontera entre generaciones, la restricción dice **dónde vive el
borde** y exige marcarlo 🧬.

### 4.6 La trampa

Se declara **sin resolverla**. Se nombra el punto donde el lector se va a estrellar y se le deja
el trabajo de descubrir por qué.

> *"Vas a querer materializar la consulta para poder recorrerla dos veces. Funciona con el
> fragmento de ejemplo. Con las treinta tablas anuales, no."*

Esto no es crueldad pedagógica: es que el error hay que cometerlo para que el patrón se fije. La
solución de referencia explica la trampa entera, y por eso va después.

### 4.7 Pistas (progresivas, plegadas)

Tres pistas, de menos a más concreta, cada una dentro de un `<details>` para que el lector elija
cuánto quiere que le cuenten. Es la única excepción aceptada al "markdown puro" de la guía §3.

```markdown
<details><summary>Pista 1 — el enfoque</summary>
{{Qué forma tiene la solución, sin nombrar la API.}}
</details>

<details><summary>Pista 2 — la herramienta</summary>
{{Qué parte de .NET o del stack resuelve esto, con el enlace a su documentación.}}
</details>

<details><summary>Pista 3 — el esqueleto</summary>
{{Las firmas de los dos o tres métodos, sin cuerpo.}}
</details>
```

### 4.8 Cómo se entrega

Qué proyecto, qué comando lo ejecuta, qué salida se espera, y el recordatorio del tag:

```bash
git tag -a mini-07 -m "Mini F7: <qué hace> · <el número de la medición>"
```

**El número va en el mensaje del tag.** Es lo que permite que el lector compare su resultado con
el suyo de hace tres fases, y que la solución de referencia tenga contra qué contrastarse.

Si el miniproyecto 🪟 requiere Windows, se dice aquí y se marca en el encabezado de la sección.

### 4.9 Solución de referencia

Va **al final de la fase o en un plegado**, nunca a la vista mientras se lee el encargo. Incluye
el código completo, comentado en español, y tres cosas que el código solo no dice:

- **La decisión de diseño que se tomó** y por qué, reconociendo el otro camino defendible.
- **La trampa, explicada entera**, con el número de lo que costaba el camino ingenuo.
- **Qué se habría hecho distinto si la decisión hubiera sido otra** — si en vez de migrar se
  hubiera envuelto, o si en vez de tocarlo se hubiera dejado quieto. Una o dos frases. Es el
  remate pedagógico del curso y es barato de escribir.

---

## 5. Relación con los proyectos que atraviesan el curso

Los proyectos crecen fase a fase; los miniproyectos no los tocan. Esa separación es deliberada y
evita el problema clásico del curso encadenado: **si el miniproyecto de la fase 6 modificara el
proyecto principal, quien lo hizo mal arrastraría el error hasta el final.**

El miniproyecto puede, en cambio, **usar** lo que el proyecto ya produjo —leer su salida,
consumir su API, medir contra su implementación, diagnosticar un síntoma en su código— y ahí el
enganche es legítimo y conveniente.

---

## 6. Checklist de un miniproyecto antes de darlo por bueno

- [ ] El encargo está en la voz de alguien de Cordillera, no en la del profesor.
- [ ] **No se resuelve copiando la sección 5 de la fase** (§3, la prueba literal).
- [ ] Exige al menos una consulta a documentación oficial que la fase no transcribió.
- [ ] Contiene una decisión de diseño real, con dos caminos defendibles.
- [ ] Declara su trampa sin resolverla.
- [ ] Los datos de entrada incluyen al menos un caso sucio, y el esquema heredado aparece con
      sus nombres reales.
- [ ] Tiene entre tres y seis criterios de aceptación **ejecutables**, y uno es de medición.
- [ ] Declara su restricción de estilo de forma explícita, y marca 🧬 los cruces de generación.
- [ ] Cabe en dos a cinco horas para el lector objetivo.
- [ ] No necesita paquetes que la fase no introdujo, servicios externos, ni una suscripción de
      nube de pago.
- [ ] Si requiere Windows, va marcado 🪟.
- [ ] Tiene tres pistas progresivas, plegadas.
- [ ] La solución de referencia explica la decisión, la trampa con su número, y qué habría
      cambiado si la decisión hubiera sido otra.
- [ ] No modifica ninguno de los proyectos que atraviesan el curso (§5).
- [ ] Nada de lo que pide implica apagar el sistema, ni siquiera un rato.
FIN
wc -l /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs/prompts/formato-de-miniproyectos.md

# --- 2026-09-12T23:18:29 · Write phase prompt template
cat > /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs/prompts/prompts-de-fase.md <<'FIN'
# 📍 Prompt de fase
## C# para desarrolladores Java senior

**Un chat, un archivo.** Cada fase se redacta en su propio chat y produce un único `.md`. Si un
chat no produce entregable, o sobra o se salió de alcance.

Este documento tiene **la plantilla del prompt**, que es común a todas las fases. Los prompts
rellenados, uno por fase, se agregan abajo **a medida que la secuencia de fases se cierre** en
`propuesta-fases-y-alcance.md`. Escribirlos antes sería fijar por escrito una numeración que
todavía está en discusión.

---

## 🧩 Plantilla del prompt

````markdown
Este es el chat de la **Fase {{NN}} — {{emoji}} {{Nombre}}** del curso *C# para
desarrolladores Java senior*. Su único entregable es el archivo `{{NN}}-{{slug}}.md`.

## Marco (no lo repitas, aplícalo)

Fuentes de verdad, en este orden: el `CLAUDE.md` del repositorio,
`alcance-del-proyecto.md`, `propuesta-fases-y-alcance.md`,
`guia-de-estilo-y-convenciones.md`, `plantillas-de-capitulo.md`,
`formato-de-miniproyectos.md`, `historia-propuesta-1-cordillera.md` para todo lo
narrativo, los entregables de fases anteriores, y las decisiones de este chat.

La plantilla de fase —10 secciones, el bloque 🏷️ del cierre y el bloque 📌 de autoría—
está en `plantillas-de-capitulo.md` y se sigue literal, sin secciones extra ni
reordenadas.

Recordatorio de las ocho reglas que más se rompen:

- **No expliques lo que un dev Java senior ya sabe.** Ni qué es una interfaz, ni una
  transacción, ni HTTP, ni un contenedor. Cada párrafo que lo haga se borra.
- **Código nuevo en inglés, comentarios en español con tildes.** También los mensajes
  de error y de log. Sin excepciones, ni en el `Dockerfile` ni en los scripts.
- **El esquema heredado conserva sus nombres tal cual** —`MOVINVEN`, `VLRUNIT`,
  `FECMOVTO`, `BORRADO`, `VENTAS_2019`—, sin traducir ni corregir, y el mapeo al modelo
  vive en un solo borde explícito marcado 🧬. Guía §5.1.
- **Escribe en el estilo declarado de esta fase.** Heredado significa .NET Framework 4.5
  y C# de 2017, con `DataSet` y sin `async`; nuevo significa .NET 10, nullable activado,
  `async` de punta a punta. Nunca las dos generaciones en el mismo archivo, y nunca
  modernizar un archivo heredado "de paso".
- **Cada analogía con Java declara dónde se rompe.** Una analogía sin su límite deja al
  lector confiado en un modelo mental que le va a fallar en producción.
- **Ninguna afirmación comparativa sin número.** Ni "más rápido", ni "más liviano", ni
  "sale más barato". El competidor tiene que ser una implementación defendible, y cuando
  el trabajo toca la base de datos se mide **primero el plan de consulta y después .NET**.
- **Ningún servicio de nube se describe sin su costo al volumen de Cordillera y sin su
  amarre.** El curso no es un folleto de Azure, y no exige suscripción de pago.
- **No hay apéndices.** Si aparece material que "sería un buen apéndice", los destinos
  legítimos son tres: sección de esta fase, fase propia, o 📌 con su razón escrita.

Coherencia de la ficción: la empresa es **Cordillera Media**, el sistema es **SIGE** —que
todos llaman *"el sistema"*— y el curso construye su código. Si afirmas que algo está así
en SIGE, tiene que poder mostrarse en alguna fase. La cronología de la historia es fija,
nada de lo que propongas puede apagar el sistema, y nadie es el villano. Guía §11.

## Identidad de esta fase

- Número y nombre: Fase {{NN}} de {{total}} — {{emoji}} {{Nombre}}
- Bloque: {{letra — nombre del bloque}}
- Estilo de código: {{heredado | nuevo | mixto 🧬}}
- Depende de: {{...}} · Habilita: {{...}}
- **Proyecto que avanza y en qué queda:** {{...}}
- Plataforma: {{multiplataforma | 🪟 requiere Windows}}
- Estado: {{obligatoria | 🔥 opcional}}

## Alcance

- **Propósito (una línea):** {{...}}
- **Qué entra:** {{...}}
- **Qué NO entra todavía:** {{...}} → Fases {{...}}
- **Conceptos clave a introducir:** {{...}}
- **El reflejo de Java que esta fase ataca 🪞:** {{cuál, y qué código produce}}
- **Lo que sí se transfiere 🩻:** {{...}}
- **Deuda técnica intencional 💸:** {{cuál, qué sería lo correcto, y en qué fase se paga}}
- **Medición 📏:** {{qué hipótesis, contra qué competidor, con qué métrica}}
- **Miniproyecto 🧱:** {{el encargo en una línea, quién de Cordillera lo pide, y cuál es
  la trampa}}. Sigue `formato-de-miniproyectos.md` y pasa su prueba de calibración: **no
  puede resolverse copiando la sección 5**.
- **Ejercicios:** {{total}} en total, repartidos 🟢🟡🟠🔴 según la guía §9, con al menos un
  tercio de diagnóstico o medición, al menos dos de decisión (*¿se migra, se envuelve o se
  deja quieto?*) y al menos uno de generación 🧬 si la fase está en el bloque de migración
  o después.

## Pendientes que pueden bloquear esta fase

- {{lo que haya que decidir antes de escribir, con una recomendación. Si no hay nada
  bloqueante, decirlo.}}
````

---

## Cómo se usa

1. Se copia la plantilla y se rellenan los `{{placeholders}}` con los valores de
   `propuesta-fases-y-alcance.md`. **Si un valor no está allí, no se inventa aquí**: se cierra
   allí primero.
2. El prompt rellenado se pega en un chat nuevo, junto con los documentos del marco.
3. El chat produce el `.md` de la fase, y nada más.
4. El prompt rellenado se archiva en este documento, bajo su propio encabezado `## Fase NN`,
   para que la fase se pueda reescribir después con el mismo encuadre.

---

## Prompts rellenados

> _Vacío por ahora._ Se llenan cuando la secuencia de fases quede cerrada en
> `propuesta-fases-y-alcance.md`. Fijar aquí una numeración que todavía se está discutiendo
> garantiza que algún día los dos documentos se contradigan.
FIN
wc -l /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs/prompts/prompts-de-fase.md

# --- 2026-09-12T23:22:10 · Write phase proposal
cat > /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs/prompts/propuesta-fases-y-alcance.md <<'FIN'
# 🗺️ Propuesta de fases y alcance
## C# para desarrolladores Java senior

> **Estado: propuesta abierta.** Este documento existe para **discutirse**, no para obedecerse
> todavía. Lo que está cerrado son las decisiones de §2 —vienen de `alcance-del-proyecto.md`— y
> la forma de cada fase. Lo que está abierto es la **secuencia**, y las preguntas concretas
> están en §10, cada una con una recomendación.

Consolida lo que ya se decidió, propone una columna vertebral completa, y deja escrito qué
falta acordar antes de escribir la primera fase.

---

## 1. Lo que hace distinto a este curso

Cuatro rasgos que lo separan de sus hermanos del repositorio, y que explican casi todas las
decisiones de abajo.

**El lector tiene que desaprender dos reflejos, no uno.** El de lenguaje —escribir C# con
estructura de Java— y el de arquitectura —reescribirlo todo o no tocar nada—. Los cursos
hermanos atacan uno; este ataca los dos, y por eso tiene un bloque de lenguaje *y* un bloque de
sistema heredado.

> 🧭 **La pregunta que ordena todo el material: ¿esto se migra, se envuelve o se deja quieto?**

**No hay apéndices.** Todo lo que en otro curso sería material de consulta es aquí una fase o
una sección de fase. La razón completa está en `alcance-del-proyecto.md` §6; la consecuencia
práctica es que el ambiente —SDK, Visual Studio Community, NuGet, la guía rápida del IDE— **es
la Fase 00 entera** y no una nota al pie.

**Cada fase cierra con un miniproyecto difícil, y cada fase mueve un proyecto.** El
miniproyecto ocupa el lugar del cuaderno de incidentes de los cursos de legacy; el avance de
proyecto es lo que impide que el curso se vuelva una colección de ejemplos. Las dos cosas son
obligatorias y las dos se declaran en el encabezado de la fase.

**El curso tiene una restricción que ningún otro del repositorio tiene: no puede apagar el
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
| Práctica por fase | **Un miniproyecto obligatorio**, difícil | Sustituye al cuaderno de incidentes; los ejercicios bajan a 20-25 |
| Avance por fase | **Cada fase mueve al menos un proyecto** | Una fase que no avanza nada se replantea antes de escribirse |
| Empresa | **Cordillera Media** · el sistema es **SIGE** | Todo el dominio sale de `historia-propuesta-1-cordillera.md` |
| Runtime objetivo | **.NET 10 (LTS) y C# 14** | Fijado en `alcance-del-proyecto.md` §9 |
| Runtime heredado | **.NET Framework 4.5, escrito como C# de 2017** | El curso lo escribe para después migrarlo; no se caricaturiza |
| IDE | **Visual Studio Community** principal; VS Code + C# Dev Kit y Rider como alternativas | Los tres en la Fase 00, sin apéndice |
| Esquema heredado | **Conserva sus nombres tal cual** | `MOVINVEN`, `VLRUNIT`, `BORRADO`; el mapeo vive en un borde 🧬 (guía §5.1) |
| Idioma del código | **Inglés** en lo nuevo; comentarios y mensajes en español | Guía §5 |
| Comparaciones | **Ninguna sin número** | Cada fase produce una medición 📏, y la excepción se justifica |
| Nube | **Medida contra lo que reemplaza**, sin suscripción de pago | Emulador local donde lo haya; precio publicado y declaración donde no |
| El sistema | **No se apaga nunca** | Toda migración es por partes y con vuelta atrás |

---

## 3. 🧱 Los bloques

```text
Bloque 0   El ambiente. Una fase.
Bloque A   El lenguaje y el runtime: C# sin acento de Java.
Bloque B ⭐ El sistema heredado y la frontera: leer, caracterizar, envolver, cortar, migrar.
Bloque C   El escritorio 🪟: qué pasa con los 340 formularios.
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
difíciles de enseñar. Ver §8.

**El Bloque D es donde .NET compite de frente** con lo que el lector ya sabe hacer, y donde las
mediciones dejan de ser curiosidades y empiezan a decidir arquitecturas — y facturas.

---

## 4. 🪜 La secuencia propuesta — 27 fases (00–26)

> 🧭 **Esta secuencia no es la de un curso de lenguaje con un bloque de nube pegado al final.**
> Se diseñó desde lo que este curso necesita, y la prueba está en las fases que aquí existen y
> en un tutorial de C# no tendrían sentido.

Lo que este curso necesita y otro de C# no:

- **Un sistema heredado que el propio curso escribe.** La fase 08 no enseña nada moderno: gasta
  su presupuesto en construir el trozo de SIGE que las fases 09-12 van a cortar. Sin eso, el
  bloque central sería un ensayo.
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
| 04 | 🎩 Delegados, eventos, extensiones y genéricos reificados | nuevo | la interfaz de un solo método; la clase `Utils` | modelo |
| 05 | 💥 Errores y recursos: sin checked exceptions, `IDisposable`, `using` | nuevo | el `catch (Exception)` que se traga lo que importaba | modelo |
| 06 ⭐ | ⚙️ `async`/`await` de punta a punta, `CancellationToken`, paralelismo | nuevo | `.Result`, `async void`, pensar en hilos | modelo |
| 07 | 🧠 Memoria, GC, `Span<T>` y flujo con `IAsyncEnumerable` | nuevo | optimizar sin medir; cargar el archivo entero | modelo |

### Bloque B ⭐ · el sistema heredado y la frontera

| # | Fase | Estilo | El reflejo que ataca 🪞 | Proyecto |
|---|---|---|---|---|
| 08 | 🏚️ El sistema que heredas: SIGE, su esquema y su capa de datos de 2017 | heredado | "esto está mal hecho" en vez de "esto está fechado" | **nace SIGE** |
| 09 ⭐ | 🔎 Caracterizar lo que no puedes leer: pruebas de aproximación sobre 700 procedimientos | mixto 🧬 | reescribir antes de entender | SIGE |
| 10 | 🗄️ Acceso a datos contra un esquema hostil: ADO.NET, Dapper y EF Core | mixto 🧬 | asumir que EF Core es Hibernate | **nace CatalogAPI** |
| 11 ⭐ | 🌿 *Strangler fig*: la API en medio, doble escritura, outbox y vuelta atrás | mixto 🧬 | el *big bang* de dos años y medio | SIGE + CatalogAPI |
| 12 | 🚚 Migrar el runtime: de .NET Framework 4.5 a .NET 10 | mixto 🧬 | migrar por versión en vez de por riesgo | SIGE |

### Bloque C 🪟 · el escritorio — qué pasa con los 340 formularios

| # | Fase | Estilo | El reflejo que ataca 🪞 | Proyecto |
|---|---|---|---|---|
| 13 | 🪟 WinForms sobre .NET 10: lo heredado que sigue siendo una opción legítima | mixto 🧬 | "esto hay que reescribirlo sí o sí" | SIGE cliente |
| 14 | 🎛️ WPF y MVVM: la interfaz de escritorio moderna, con binding y pruebas | nuevo | el controlador que manipula controles | SIGE cliente |
| 15 | ⚖️ WinUI 3, Blazor Hybrid y el veredicto del escritorio | nuevo | elegir por modernidad en vez de por quién lo mantiene | SIGE cliente |

### Bloque D · servicios, datos y nube

| # | Fase | Estilo | El reflejo que ataca 🪞 | Proyecto |
|---|---|---|---|---|
| 16 | 🌐 ASP.NET Core: minimal APIs, validación en el borde, versionado y contrato | nuevo | validar en el servicio en vez de en la frontera | CatalogAPI |
| 17 | 🔐 Identidad, secretos y configuración: Entra ID, Key Vault, opciones tipadas | nuevo | la cadena de conexión en el `App.config` de 90 equipos | CatalogAPI |
| 18 | 🌙 Trabajo de fondo: `IHostedService`, colas, idempotencia y reanudación | nuevo | el proceso nocturno que se reinicia desde cero | **nace NightPress** |
| 19 | 🧵 Blazor Server ⇄ WebAssembly ⇄ MVC, medidos desde tres países | nuevo | elegir el modelo de render sin medir la latencia real | **nace Redacción** |
| 20 | 🔭 Observabilidad y operación: OpenTelemetry, logs, métricas, salud | nuevo | `MessageBox.Show` y el log rotado a mano | los cuatro |
| 21 ⭐ | 🐳 Contenedor, arranque en frío y **la factura**: VM, App Service, Container Apps, AKS | nuevo | adoptar PaaS sin costear el amarre | los cuatro |

### Bloque E · datos e IA aplicada

| # | Fase | Estilo | El reflejo que ataca 🪞 | Proyecto |
|---|---|---|---|---|
| 22 | 📊 Los datos que mienten: sell-in, sell-out, devoluciones, y servir un modelo con ONNX | nuevo | entrenar donde no se debe; creer el número del primer mes | NightPress |
| 23 | 📚 AcervoRAG: recuperación con cita obligatoria, y la búsqueda que le gana a los embeddings | nuevo | montar el aparato vectorial antes de probar el full-text | **nace AcervoRAG** |
| 24 | 🤖 EditorAgent: herramientas, ficha de triaje, evaluación y el veredicto sobre Semantic Kernel | nuevo | dejar que el agente decida en vez de preparar la decisión | **nace EditorAgent** |

### Cierre

| # | Fase | Estilo | Qué hace |
|---|---|---|---|
| 25 ⚔️ | El duelo: CatalogAPI en ASP.NET Core y en Spring Boot | nuevo | Rendimiento, costo, productividad, contratación — y los empates admitidos como empates |
| 26 🏁 | ⚖️ Veredicto, defensa y qué no debió migrarse | — | La factura de 2020, "el Fox" de Lima, y las decisiones del propio curso que fueron erradas |

---

## 5. 🛠️ La Fase 00 en detalle

Es la fase que más se aparta de lo que haría un curso normal, así que conviene dejarla escrita.
**No es un setup: es la primera lección de criterio del curso**, y termina con su propio
miniproyecto como cualquier otra.

**Qué entra:**

- **El SDK y el runtime**, instalados en las tres plataformas, y el problema real de tener
  varios: `dotnet --info`, `dotnet --list-sdks`, el `global.json` que fija la versión del SDK
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
- **Los IDE alternativos**, sin condescendencia: **VS Code + C# Dev Kit** para quien vive en el
  terminal, y **Rider** con el mapa de equivalencias para quien viene de IntelliJ — dónde está
  cada cosa que ya sabía usar.
- **El mapa del ecosistema contra el de Maven**, que es la sección 🪞 de la fase:

  | Mundo Java | Mundo .NET | Dónde se rompe el paralelo |
  |---|---|---|
  | `pom.xml` / `build.gradle` | `.csproj` | Es un archivo de MSBuild: el proyecto **es** el build, no lo declara |
  | Maven Central | NuGet | Sin *groupId*; el nombre es de quien lo registra primero |
  | `~/.m2` compartido | caché global + restauración por proyecto | La reproducibilidad la da el lockfile, y hay que pedirla |
  | módulos de un `pom` padre | `.sln` y `Directory.Build.props` | La solución es del IDE; el build real es proyecto por proyecto |
  | `mvn test` | `dotnet test` | Sin ciclo de vida de fases: MSBuild ejecuta objetivos, no etapas |
  | JAR ejecutable | `dotnet publish` con sus modos | Autocontenido, dependiente del framework o AOT: tres respuestas distintas, y se eligen en la fase 21 |

**Qué NO entra:** el sistema heredado, la base de datos, los contenedores, la nube. Todo eso
llega cuando duela. La Fase 00 deja al lector con un SDK, una solución que compila, un IDE que
depura y un arnés de medición que va a usar veintiséis veces.

**Su miniproyecto 🧱** no puede ser "instala Visual Studio", porque eso no es un encargo. La
propuesta es **el arnés del curso**: una herramienta de consola que ejecuta una operación N
veces, descarta el calentamiento, reporta mediana y percentil 95, pico de memoria administrada
y asignaciones totales, y escribe el resultado en el formato que `BENCHMARKS.md` espera. Sirve
de verificación de que la fase quedó bien, de primer contacto con la CLI y la depuración, y
**es la herramienta con la que se mide todo el resto del curso**.

> 🧭 **La regla que fija esta fase:** *si no lo puedes medir con el arnés, no lo afirmas.*

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
| `async`/`await` de referencia | Fase 06, con su medición |
| EF Core de referencia | Fase 10, contra el esquema hostil, que es donde se aprende de verdad |
| Docker y despliegue | Fase 21, junto a la factura, porque separar las dos cosas es lo que produce el *lift and shift* |
| Convención de git y tags | `00-convencion-de-git-y-tags.md`, en la raíz del curso — no es apéndice, es un documento de encuadre que el lector sí lee |

---

## 7. 💼 Los proyectos que atraviesan el curso

Ninguno se toca desde los miniproyectos (`formato-de-miniproyectos.md` §5). Los cuatro
primeros salen de §8 de la historia; los dos de IA, de §9.

| # | Proyecto | Qué es en Cordillera | Nace |
|---|---|---|---|
| 1 ⭐ | **SIGE, por partes** | El sistema entero: sacar la lógica de los procedimientos, cortar la conexión directa del cliente a la base, y solo entonces mover el runtime. Es el eje | F08 |
| 2 | **CatalogAPI** | El catálogo hacia afuera, que hoy son cuatro volcados CSV nocturnos desincronizados. El ultimátum de Grupo Almenara le puso fecha | F10 |
| 3 | **Redacción** | El back-office editorial: cuarenta pantallas, roles y auditoría, con Nohora de usuaria real y Ximena vigilando que no le agregues un paso | F19 |
| 4 | **NightPress** | El cierre de regalías: reanudable, idempotente y auditable línea por línea, porque dos veces al año un autor impugna | F18 |
| 5 | **AcervoRAG** | Cuarenta y seis años de contratos de derechos, con la regla que lo hace valioso: cada respuesta cita documento, versión y cláusula, o no se emite | F23 |
| 6 | **EditorAgent** | El triaje de los 400 manuscritos no solicitados que llegan al mes. No decide: prepara para que decida una persona | F24 |

**El cliente de escritorio no es un proyecto aparte**: es el frente de SIGE, y el Bloque C
decide qué se hace con él.

---

## 8. 🪟 El escritorio: sí, y por qué

La pregunta era si el curso debía incluir escritorio. La respuesta propuesta es **sí, con un
bloque de tres fases**, y los argumentos son concretos:

- **El sistema heredado son 340 formularios WinForms.** Un curso de migración que evite el
  escritorio deja fuera la mitad del problema y termina enseñando la parte fácil.
- **La respuesta honesta a veces es "no lo toques".** WinForms sobre .NET 10 sigue siendo una
  opción legítima, y decirlo en voz alta —con la medición al lado— es exactamente el tipo de
  veredicto que el repositorio pide. Un bloque de escritorio que terminara siempre en "reescribe
  en web" no haría falta.
- **Es lo que este ecosistema permite y otros no.** Comparar WinForms, WPF, WinUI 3 y web sobre
  el mismo módulo, con el mismo arnés, es una comparación que un curso de Java no puede hacer.
- **Y hay una lección de diseño que solo aparece aquí:** noventa personas con un formulario
  abierto ocho horas al día en una oficina de Lima con mala conexión imponen restricciones que
  un backend puro no tiene.

**El precio, dicho sin adorno:** WinForms, WPF y WinUI 3 **solo corren en Windows**. Las tres
fases del bloque van marcadas 🪟, y quien esté en Linux o macOS las lee sin ejecutarlas. Es la
única parte del curso con esa propiedad, y por eso el bloque va **junto y bien delimitado** en
vez de repartido.

La forma propuesta: **el mismo módulo, implementado tres veces**. Se elige uno de los
formularios de SIGE —la consulta de existencias por almacén, que tiene búsqueda, grilla con
volumen real, edición y un reporte— y se construye en WinForms sobre .NET 10 (F13), en WPF con
MVVM (F14) y como prototipo en WinUI 3 (F15). La fase 15 cierra midiendo las cuatro opciones
—las tres de escritorio más la web que nacerá en la F19— contra lo que de verdad importa:
arranque, memoria, despliegue a 90 equipos, comportamiento con la conexión de Lima, y **quién
lo puede mantener cuando el lector se vaya**, que es la columna donde Duván decide la
discusión.

> ⚖️ El veredicto de este bloque está abierto de verdad y el curso no lo prejuzga. Lo que sí
> está decidido es que se mide antes de opinar.

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

## 10. 🚦 Las decisiones abiertas

Esto es lo que hay que acordar. Cada una lleva una recomendación; **ninguna está tomada**.

**10.1 · ¿Veintisiete fases, o se consolidan?** Es la pregunta grande. Veintisiete fases con
miniproyecto cada una son veintisiete encargos difíciles, y el curso puede quedar más largo de
lo que nadie termina. Los candidatos naturales a fusión son 04+05 (delegados y recursos), 14+15
(WPF y el veredicto del escritorio), 23+24 (los dos proyectos de IA) y 20 dentro de 21
(observabilidad y despliegue). *Recomendación: fusionar 04+05 y 23+24, y dejar el resto, para
un total de 25.* Fusionar 14+15 dejaría el veredicto del escritorio —que es el contenido del
bloque— como apéndice de una fase de WPF, y meter observabilidad dentro de la fase de la
factura produciría la fase más larga del curso.

**10.2 · ¿Cómo se le da al lector un .NET Framework real si no está en Windows?** El sistema
heredado es .NET Framework 4.5, que no corre en Linux ni en macOS, y el Bloque B es el corazón
del curso: no puede ser 🪟 entero. Tres caminos: *(a)* Bloque B solo para Windows; *(b)* escribir
el código heredado **en estilo de 2017 pero sobre .NET 10**, declarando en una sección qué
cambia de verdad en un .NET Framework real —configuración, GAC, `System.Web`, ausencia de
`Span<T>`, `HttpContext.Current`— y reservar el Framework auténtico para el bloque 🪟;
*(c)* contenedores de Windows. *Recomendación: (b).* Pierde autenticidad de runtime y conserva
lo que de verdad enseña el bloque —el esquema hostil, los procedimientos, el `DataSet`, la
conexión directa del cliente—, que no depende de la versión del runtime. La fase 12 entonces
migra *el estilo y la arquitectura*, y documenta honestamente qué parte de una migración real
de Framework a .NET 10 el curso no puede ejecutar. **Esta decisión cambia la forma de cinco
fases y conviene tomarla primero.**

**10.3 · ¿Dónde entran las pruebas?** No hay una fase llamada "testing". La propuesta las mete
en la 09, como *pruebas de caracterización* sobre los procedimientos heredados —que es su uso
más defendible y el más difícil de enseñar—, y después el curso las usa en todas las fases.
*Recomendación: mantenerlo así, y fijar el marco (xUnit o MSTest, más Testcontainers) en la
Fase 00* para que el arnés y las primeras pruebas nazcan con él. La alternativa —una fase de
pruebas al final del Bloque A— enseñaría xUnit sobre ejemplos de juguete, que es exactamente lo
que este perfil no necesita.

**10.4 · ¿Qué hace exactamente la Fase 08, y cuánto código heredado escribe el curso?** Hay
tensión real: demasiado poco y el Bloque B no tiene material; demasiado y el lector pasa dos
semanas escribiendo código de 2017 a propósito. *Recomendación: un vertical delgado y completo*
—existencias por almacén y liquidación de regalías, que son los dos que la historia usa más—
con su esquema (`MOVINVEN`, `LIQREGAL`, `VENTAS_YYYY`), seis u ocho procedimientos almacenados
de verdad, la capa de datos con `DataSet`, y el generador de datos sucios. Todo lo demás del
sistema se cuenta como historia (guía §11, Regla 2).

**10.5 · ¿El duelo contra qué, exactamente?** La fase 25 implementa CatalogAPI dos veces.
*Recomendación: Spring Boot 3, que es el stack que el lector realmente tiene*, midiendo
rendimiento, arranque en frío, memoria, líneas de código, costo mensual al volumen de
Cordillera y facilidad de contratación en el mercado del lector. Meter también Go o Node diluye
la comparación y alarga la fase.

**10.6 · ¿Cuánto pesa cada fase, y se publican horas?** Los cursos hermanos de Angular reparten
horas; el de Python decidió no publicarlas. Aquí el miniproyecto domina el tiempo real.
*Recomendación: no publicar horas por fase; publicar la estimación del miniproyecto (2-5 h) y
nada más.* Una tabla de horas que nadie puede cumplir desprestigia al resto del documento.

**10.7 · ¿El track `cv` debería estar en el camino base?** Hablarle a un sistema Java que nadie
va a apagar es la situación más común del lector después del curso, y hoy está como opcional.
*Recomendación: no moverlo entero, pero reservar una sección dentro de la fase 11* —la del
*strangler fig*— donde la pieza que se envuelve sea Convivir, el sistema Java heredado de la
adquisición de 2004. Así el camino base cubre la habilidad y el track profundiza.

**10.8 · ¿Cuánta nube, y en qué fase se emula qué?** La regla de "sin suscripción de pago" está
cerrada, pero falta el inventario: qué servicio se ejecuta con emulador local (Azurite para
Blob y colas, SQL Server en contenedor), cuál se sustituye por un equivalente local declarado
(la mensajería, la identidad) y cuál solo se estudia con precios publicados (Durable Functions,
Azure AI Search). *Recomendación: cerrar ese inventario como una tabla en
`alcance-del-proyecto.md` §10 antes de escribir la fase 17*, que es la primera que lo necesita.

**10.9 · ¿Qué versión exacta de Visual Studio Community, y qué pasa con macOS?** La edición
para macOS fue retirada, así que en macOS el curso es Rider o VS Code y hay que decirlo sin
rodeos en la Fase 00. Falta fijar la versión exacta de Visual Studio y del SDK .NET 10.
*Recomendación: fijarlas verificándolas contra las notas de versión oficiales en el momento de
escribir la Fase 00, y escribirlas en `alcance-del-proyecto.md` §9 antes de la primera línea de
código.* Ninguna se da por buena de memoria.

**10.10 · ¿El curso escribe `BENCHMARKS.md` desde la Fase 00 o al final?** Cada fase produce una
medición y el repositorio pide un archivo consolidado. *Recomendación: desde la Fase 00, con el
arnés*, y cada fase agrega su entrada al cerrarse. Dejarlo para el final garantiza que las
condiciones de las primeras mediciones se pierdan.

---

## 11. 📁 Convención de nombres de archivo

Todo ordenable por nombre, con dos dígitos. **El número del archivo es el número de la fase.**

```text
README.md
0-ESTRUCTURA-CURSO.md
00-convencion-de-git-y-tags.md
00-ambiente-visual-studio-y-ecosistema.md
01-tipos-valor-y-referencia.md
02-nullable-y-pattern-matching.md
…
26-veredicto-y-defensa.md
BENCHMARKS.md
INSTINTOS.md
src/
prompts/
```

No hay `aNN-`. El código ejecutable vive en `src/`, con un directorio por fase nombrado igual
que el documento al que pertenece, o un directorio por proyecto cuando el proyecto atraviese
varias fases — se decide al escribir la Fase 00 y se declara ahí. Los tracks opcionales, si se
escriben, llevan su propio prefijo de dos letras según la convención del `CLAUDE.md` del
repositorio.

---

## 12. 🚦 Siguiente paso

1. **Resolver §10**, empezando por 10.2 y 10.1, que son las que bloquean todo lo demás: la
   primera cambia la forma de cinco fases y la segunda, la numeración entera.
2. Con eso cerrado, congelar la tabla de §4 y escribir `0-ESTRUCTURA-CURSO.md` y el `README.md`
   del curso.
3. Rellenar los prompts de fase en `prompts-de-fase.md`, que hoy está deliberadamente vacío.
4. Escribir la Fase 00 y la Fase 01, que fijan el ambiente, el arnés y el dominio. Todo lo demás
   depende de ellas.
5. Escribir las fases 08 a 11 antes que el resto del Bloque D: son el corazón ⭐ y las que más
   pueden cambiar la forma de las anteriores.
FIN
wc -l /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs/prompts/propuesta-fases-y-alcance.md

# --- 2026-09-12T23:50:53 · Find platform references
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs/prompts && grep -n "🪟\|Linux\|macOS\|multiplataforma\|tres plataformas\|Apple Silicon\|plataforma" *.md

# --- 2026-09-12T23:51:24 · Apply Windows-only edits to five docs
python3 - <<'PY'
import io,re

def sub(path, old, new, count=1):
    s=io.open(path,encoding='utf-8').read()
    assert old in s, (path, old[:60])
    s=s.replace(old,new,count)
    io.open(path,'w',encoding='utf-8').write(s)

# ---------- alcance ----------
sub('alcance-del-proyecto.md',
"""**Windows 11 es el entorno principal y declarado**, y es el único donde el curso se completa
al cien por ciento. La razón es concreta y no se disimula: **WinForms, WPF y WinUI 3 son de
Windows**, y el sistema heredado de Cordillera son 340 formularios WinForms.

**Linux amd64 y macOS Apple Silicon están soportados para todo lo demás** —lenguaje, runtime,
servicios, datos, contenedores, nube, IA— que es la mayor parte del curso. Cada fase del
bloque de escritorio lleva en su encabezado una línea explícita de *requiere Windows*, y el
resto del material no asume plataforma.

Donde una instrucción difiera entre plataformas se dan las tres, en ese orden y sin
condescendencia.""",
"""> 🧭 **El curso es de Windows, exclusivamente. Decisión cerrada.**

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
la historia §6—. Pero el **curso** se toma en Windows.""")

sub('alcance-del-proyecto.md',
"""- 🪦 **La nube se mide, no se promociona**, y no requiere suscripción de pago (§10).""",
"""- 🪦 **La nube se mide, no se promociona**, y no requiere suscripción de pago (§10).
- 🪦 **Windows 11 exclusivamente** (§10). Sin variantes por plataforma en ningún documento.""")

sub('alcance-del-proyecto.md',
"""| Escritorio | WinForms y WPF sobre .NET 10; WinUI 3 como prototipo | Bloque de escritorio |""",
"""| Escritorio | WinForms y WPF sobre .NET 10; WinUI 3 como prototipo | Bloque de escritorio |
| Sistema operativo | **Windows 11**, con WSL 2 para los contenedores | Fase 00 · todo el curso |""")

sub('alcance-del-proyecto.md',
"""1. Clonar el repo, levantar el ambiente en su plataforma y correr la aplicación.""",
"""1. Clonar el repo, levantar el ambiente y correr la aplicación.""") if False else None

# ---------- guia de estilo ----------
sub('guia-de-estilo-y-convenciones.md',
"""- 🪟 **Requiere Windows.** Marca las fases y secciones del bloque de escritorio, y cualquier
  ejercicio que no se pueda hacer en Linux o macOS.
""","")
sub('guia-de-estilo-y-convenciones.md',
"""- **Marcados 🪟 los que exijan Windows**, sin excepción.
""","")
sub('guia-de-estilo-y-convenciones.md',
"""- [ ] Lo que exige Windows va marcado 🪟.
""","")

# ---------- plantillas ----------
sub('plantillas-de-capitulo.md',
"""> Proyecto que avanza: {{cuál, y en qué queda al terminar}}
> {{Si aplica: 🪟 **Requiere Windows.** Esta fase no se puede completar en Linux ni en macOS.}}""",
"""> Proyecto que avanza: {{cuál, y en qué queda al terminar}}""")
sub('plantillas-de-capitulo.md',
""" Lo que exija Windows va marcado 🪟.}}""","}}")

# ---------- miniproyectos ----------
sub('formato-de-miniproyectos.md',
"""
Si el miniproyecto 🪟 requiere Windows, se dice aquí y se marca en el encabezado de la sección.
""","")
sub('formato-de-miniproyectos.md',
"""- [ ] Si requiere Windows, va marcado 🪟.
""","")
sub('formato-de-miniproyectos.md',
"""- [ ] No necesita paquetes que la fase no introdujo, servicios externos, ni una suscripción de
      nube de pago.""",
"""- [ ] No necesita paquetes que la fase no introdujo, servicios externos, ni una suscripción de
      nube de pago. Todo corre en la máquina Windows del lector.""")

# ---------- prompts de fase ----------
sub('prompts-de-fase.md',
"""- Plataforma: {{multiplataforma | 🪟 requiere Windows}}
""","")
sub('prompts-de-fase.md',
"""- **No hay apéndices.** Si aparece material que "sería un buen apéndice", los destinos
  legítimos son tres: sección de esta fase, fase propia, o 📌 con su razón escrita.""",
"""- **El curso es de Windows, exclusivamente.** No escribas variantes por plataforma, ni
  notas al pie para Linux o macOS, ni marcadores de portabilidad. Todo corre en la máquina
  Windows 11 del lector, con WSL 2 para los contenedores.
- **No hay apéndices.** Si aparece material que "sería un buen apéndice", los destinos
  legítimos son tres: sección de esta fase, fase propia, o 📌 con su razón escrita.""")
print("ok")
PY

# --- 2026-09-12T23:52:09 · Update phase proposal for Windows-only
python3 - <<'PY'
import io
def sub(path, old, new):
    s=io.open(path,encoding='utf-8').read()
    assert old in s, old[:70]
    io.open(path,'w',encoding='utf-8').write(s.replace(old,new,1))

P='propuesta-fases-y-alcance.md'

sub(P,"""| El sistema | **No se apaga nunca** | Toda migración es por partes y con vuelta atrás |""",
"""| El sistema | **No se apaga nunca** | Toda migración es por partes y con vuelta atrás |
| Plataforma | **Windows 11, exclusivamente** | El legado es .NET Framework auténtico y el escritorio entra sin descuento; sin variantes por plataforma en ningún documento |""")

sub(P,"""Bloque C   El escritorio 🪟: qué pasa con los 340 formularios.""",
"""Bloque C   El escritorio: qué pasa con los 340 formularios.""")

sub(P,"""**El Bloque C es el que ningún otro ecosistema permite.** La pregunta *"¿qué hago con
trescientos cuarenta formularios y noventa personas que los usan todo el día?"* no tiene
equivalente en un curso de backend, y la respuesta honesta —*a veces, nada*— es de las más
difíciles de enseñar. Ver §8.""",
"""**El Bloque C es el que ningún otro ecosistema permite.** La pregunta *"¿qué hago con
trescientos cuarenta formularios y noventa personas que los usan todo el día?"* no tiene
equivalente en un curso de backend, y la respuesta honesta —*a veces, nada*— es de las más
difíciles de enseñar. Con el curso cerrado sobre Windows, este bloque deja de costar
portabilidad y pasa a ser simplemente una parte más del camino base. Ver §8.""")

sub(P,"""### Bloque C 🪟 · el escritorio — qué pasa con los 340 formularios""",
"""### Bloque C · el escritorio — qué pasa con los 340 formularios""")

sub(P,"""| 13 | 🪟 WinForms sobre .NET 10:""","""| 13 | 🪟 WinForms sobre .NET 10 (y lo que costó salir de Framework):""")

sub(P,"""- **El SDK y el runtime**, instalados en las tres plataformas, y el problema real de tener
  varios:""","""- **El SDK y el runtime**, y el problema real de tener varios:""")

sub(P,"""- **Los IDE alternativos**, sin condescendencia: **VS Code + C# Dev Kit** para quien vive en el
  terminal, y **Rider** con el mapa de equivalencias para quien viene de IntelliJ — dónde está
  cada cosa que ya sabía usar.""",
"""- **WSL 2 y el runtime de contenedores**, que es donde van a correr SQL Server, los emuladores
  de Azure y las pruebas con Testcontainers. Se instala aquí y no se vuelve a montar.
- **Los IDE alternativos**, sin condescendencia: **VS Code + C# Dev Kit** para quien vive en el
  terminal, y **Rider** con el mapa de equivalencias para quien viene de IntelliJ — dónde está
  cada cosa que ya sabía usar. Los dos corren en Windows, que es donde se toma el curso.""")

# --- §8 el escritorio: rewrite the "precio" paragraph ---
sub(P,"""**El precio, dicho sin adorno:** WinForms, WPF y WinUI 3 **solo corren en Windows**. Las tres
fases del bloque van marcadas 🪟, y quien esté en Linux o macOS las lee sin ejecutarlas. Es la
única parte del curso con esa propiedad, y por eso el bloque va **junto y bien delimitado** en
vez de repartido.""",
"""**Y con el curso cerrado sobre Windows, este bloque ya no cuesta nada.** En la versión anterior
de este documento el escritorio era la única parte del material que excluía lectores, y eso
obligaba a delimitarlo y a marcarlo. Ahora es una parte más del camino base, y el presupuesto
que se iba en advertencias de portabilidad se gasta en medir.""")

# --- 10.2 replace ---
sub(P,"""**10.2 · ¿Cómo se le da al lector un .NET Framework real si no está en Windows?** El sistema
heredado es .NET Framework 4.5, que no corre en Linux ni en macOS, y el Bloque B es el corazón
del curso: no puede ser 🪟 entero. Tres caminos: *(a)* Bloque B solo para Windows; *(b)* escribir
el código heredado **en estilo de 2017 pero sobre .NET 10**, declarando en una sección qué
cambia de verdad en un .NET Framework real —configuración, GAC, `System.Web`, ausencia de
`Span<T>`, `HttpContext.Current`— y reservar el Framework auténtico para el bloque 🪟;
*(c)* contenedores de Windows. *Recomendación: (b).* Pierde autenticidad de runtime y conserva
lo que de verdad enseña el bloque —el esquema hostil, los procedimientos, el `DataSet`, la
conexión directa del cliente—, que no depende de la versión del runtime. La fase 12 entonces
migra *el estilo y la arquitectura*, y documenta honestamente qué parte de una migración real
de Framework a .NET 10 el curso no puede ejecutar. **Esta decisión cambia la forma de cinco
fases y conviene tomarla primero.**""",
"""**10.2 · ¿En qué versión exacta del .NET Framework se escribe el legado?** 🪦 *La pregunta
anterior —cómo darle Framework a un lector que no está en Windows— quedó sin objeto: el curso
es de Windows (§2), el legado es auténtico y la fase 12 es una migración de verdad.* Queda la
versión. La historia dice que los pasantes escribieron sobre **4.5** en Visual Studio 2015, y
ese número es fuente de verdad narrativa; el problema es que un Visual Studio de 2026 no trae
el paquete de destino de 4.5 y compilar contra él es una pelea que no enseña nada.
*Recomendación: escribir el código contra **.NET Framework 4.8** y resolverlo dentro de la
ficción* — Wilson subió el destino a 4.8 en 2021 porque una actualización de Windows rompió un
controlador de impresión, fue el único cambio que ese código recibió en nueve años, y no arregló
nada de fondo. Es verosímil, es lo que pasa de verdad en esas empresas, y deja el `App.config`,
el `packages.config`, los `DataSet` y la ausencia de `async` exactamente donde estaban. La
alternativa —4.5 con paquetes de destino descargados aparte— compra fidelidad de número y paga
con media fase de fricción de instalación.""")

# --- 10.9 rework ---
sub(P,"""**10.9 · ¿Qué versión exacta de Visual Studio Community, y qué pasa con macOS?** La edición
para macOS fue retirada, así que en macOS el curso es Rider o VS Code y hay que decirlo sin
rodeos en la Fase 00. Falta fijar la versión exacta de Visual Studio y del SDK .NET 10.
*Recomendación: fijarlas verificándolas contra las notas de versión oficiales en el momento de
escribir la Fase 00, y escribirlas en `alcance-del-proyecto.md` §9 antes de la primera línea de
código.* Ninguna se da por buena de memoria.""",
"""**10.9 · ¿Qué versión exacta de Visual Studio Community, y con qué cargas de trabajo?** Falta
fijarla, junto con el patch exacto del SDK .NET 10. Hay un detalle que sí importa y que conviene
decidir con la versión: **una sola instalación tiene que poder abrir el legado y lo nuevo** —el
diseñador de WinForms sobre .NET Framework, el de WPF, los proyectos SDK de .NET 10 y las
herramientas de datos de SQL Server—, y eso se traduce en tres o cuatro cargas de trabajo
concretas que la Fase 00 nombra y justifica una por una. *Recomendación: fijar versión y cargas
verificándolas contra las notas de versión oficiales en el momento de escribir la Fase 00, y
escribirlas en `alcance-del-proyecto.md` §9 antes de la primera línea de código.* Ninguna se da
por buena de memoria.""")

# --- §12 siguiente paso: 10.2 no longer the blocker ---
sub(P,"""1. **Resolver §10**, empezando por 10.2 y 10.1, que son las que bloquean todo lo demás: la
   primera cambia la forma de cinco fases y la segunda, la numeración entera.""",
"""1. **Resolver §10**, empezando por 10.1, que es la que bloquea todo lo demás porque cambia la
   numeración entera, y por 10.4, que fija cuánto código heredado escribe el curso.""")
print("ok")
PY
grep -c "🪟" propuesta-fases-y-alcance.md; grep -rn "🪟" *.md | grep -v historia

# --- 2026-09-12T23:55:43 · Rewrite phase sequence to 25 phases
python3 - <<'PY'
import io,re
P='propuesta-fases-y-alcance.md'
s=io.open(P,encoding='utf-8').read()

nuevo_4 = """## 4. 🪜 La secuencia — 25 fases (00–24)

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
| 04 | 🎩 Ceremonia que sobra y ceremonia que falta: delegados, extensiones, genéricos, `IDisposable` | nuevo | la interfaz de un solo método; el `catch (Exception)` que se traga lo que importaba | modelo |
| 05 ⭐ | ⚙️ `async`/`await` de punta a punta, `CancellationToken`, paralelismo | nuevo | `.Result`, `async void`, pensar en hilos | modelo |
| 06 | 🧠 Memoria, GC, `Span<T>` y flujo con `IAsyncEnumerable` | nuevo | optimizar sin medir; cargar el archivo entero | modelo |

### Bloque B ⭐ · el sistema heredado y la frontera

| # | Fase | Estilo | El reflejo que ataca 🪞 | Proyecto |
|---|---|---|---|---|
| 07 | 🏚️ El sistema que heredas: SIGE, su esquema y su capa de datos de 2017 | heredado | "esto está mal hecho" en vez de "esto está fechado" | **nace SIGE** (existencias y regalías) |
| 08 ⭐ | 🔎 Caracterizar lo que no puedes leer: pruebas de aproximación sobre los procedimientos | mixto 🧬 | reescribir antes de entender | SIGE (entran catálogo y facturación) |
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
"""

ini = s.index("## 4. 🪜 La secuencia propuesta")
fin = s.index("## 5. 🛠️ La Fase 00 en detalle")
s = s[:ini] + nuevo_4 + "\n---\n\n" + s[fin:]

def sub(old,new):
    global s
    assert old in s, old[:70]
    s = s.replace(old,new,1)

sub("**es la herramienta con la que se mide todo el resto del curso**.",
    "**es la herramienta con la que se mide todo el resto del curso**, veinticuatro fases.")

# §7 proyectos: fases de nacimiento
sub("| 1 ⭐ | **SIGE, por partes** |","| 1 ⭐ | **SIGE, por partes** |")
s = s.replace("| F08 |","| F07 |").replace("| F10 |","| F09 |").replace("| F19 |","| F18 |").replace("| F18 |\n","| F17 |\n",1)
print("ok1")
io.open(P,'w',encoding='utf-8').write(s)
PY
grep -n "^| [0-9] \|^| [1-6] ⭐\? | \*\*" propuesta-fases-y-alcance.md | head -20; echo ---; sed -n '/## 7. 💼/,/## 8./p' propuesta-fases-y-alcance.md

# --- 2026-09-12T23:56:36 · Close decisions in phase proposal
python3 - <<'PY'
import io
P='propuesta-fases-y-alcance.md'
s=io.open(P,encoding='utf-8').read()
def sub(old,new):
    global s
    assert old in s, old[:80]
    s=s.replace(old,new,1)

sub("con Nohora de usuaria real y Ximena vigilando que no le agregues un paso | F17 |",
    "con Nohora de usuaria real y Ximena vigilando que no le agregues un paso | F18 |")
sub("porque dos veces al año un autor impugna | F18 |",
    "porque dos veces al año un autor impugna | F17 |")
sub("cada respuesta cita documento, versión y cláusula, o no se emite | F23 |",
    "cada respuesta cita documento, versión y cláusula, o no se emite | F22 |")
sub("No decide: prepara para que decida una persona | F24 |",
    "No decide: prepara para que decida una persona | F22 |")

# ---- §8 escritorio: renumerar ----
sub("""**Sí, con un
bloque de tres fases**""","""**sí, con un
bloque de tres fases** (12-14)""")
sub("""La forma propuesta: **el mismo módulo, implementado tres veces**. Se elige uno de los
formularios de SIGE —la consulta de existencias por almacén, que tiene búsqueda, grilla con
volumen real, edición y un reporte— y se construye en WinForms sobre .NET 10 (F13), en WPF con
MVVM (F14) y como prototipo en WinUI 3 (F15). La fase 15 cierra midiendo las cuatro opciones
—las tres de escritorio más la web que nacerá en la F19— contra lo que de verdad importa:""",
"""La forma propuesta: **el mismo módulo, implementado tres veces**. Se elige uno de los
formularios de SIGE —la consulta de existencias por almacén, que tiene búsqueda, grilla con
volumen real, edición y un reporte— y se construye en WinForms sobre .NET 10 (F12), en WPF con
MVVM (F13) y como prototipo en WinUI 3 (F14). La fase 14 cierra midiendo las cuatro opciones
—las tres de escritorio más la web que nacerá en la F18— contra lo que de verdad importa:""")

# ---- 10.1 cerrada ----
sub("""**10.1 · ¿Veintisiete fases, o se consolidan?** Es la pregunta grande. Veintisiete fases con
miniproyecto cada una son veintisiete encargos difíciles, y el curso puede quedar más largo de
lo que nadie termina. Los candidatos naturales a fusión son 04+05 (delegados y recursos), 14+15
(WPF y el veredicto del escritorio), 23+24 (los dos proyectos de IA) y 20 dentro de 21
(observabilidad y despliegue). *Recomendación: fusionar 04+05 y 23+24, y dejar el resto, para
un total de 25.* Fusionar 14+15 dejaría el veredicto del escritorio —que es el contenido del
bloque— como apéndice de una fase de WPF, y meter observabilidad dentro de la fase de la
factura produciría la fase más larga del curso.""",
"""**10.1 · 🪦 Cerrada: veinticinco fases.** Se fusionaron 04+05 (ceremonia y recursos) y los dos
proyectos de IA en la 22. Quedan separadas el veredicto del escritorio y la fase de la factura,
por las razones que están al pie de la tabla de §4. La numeración de §4 es la vigente y ninguna
fase se renumera por su cuenta.""")

# ---- 10.2 cerrada ----
sub("""*Recomendación: escribir el código contra **.NET Framework 4.8** y resolverlo dentro de la
ficción* — Wilson subió el destino a 4.8 en 2021 porque una actualización de Windows rompió un
controlador de impresión, fue el único cambio que ese código recibió en nueve años, y no arregló
nada de fondo. Es verosímil, es lo que pasa de verdad en esas empresas, y deja el `App.config`,
el `packages.config`, los `DataSet` y la ausencia de `async` exactamente donde estaban. La
alternativa —4.5 con paquetes de destino descargados aparte— compra fidelidad de número y paga
con media fase de fricción de instalación.""",
"""🪦 **Cerrada: .NET Framework 4.8, resuelto dentro de la ficción.** Wilson subió el destino a
4.8 en 2021 porque una actualización de Windows rompió un controlador de impresión fiscal; fue
el único cambio que ese código recibió en nueve años y no arregló nada de fondo. Es verosímil,
es lo que pasa de verdad en esas empresas, y deja el `App.config`, el `packages.config`, los
`DataSet` y la ausencia de `async` exactamente donde estaban.

> ⚠️ **Dos consecuencias que las fases deben respetar.** La historia sigue diciendo **4.5** y
> **Visual Studio 2015** para 2016-2017 (§3 de `historia-propuesta-1-cordillera.md`): ese dato
> no se toca, y el salto a 4.8 se narra como lo que fue, un parche de 2021. Y la fase 11 tiene
> que decir en voz alta que **migrar de 4.8 a .NET 10 es más fácil que migrar de 4.5**, porque
> 4.8 ya trae buena parte del camino andado — presentarlo como si fuera el caso difícil sería
> vender una migración más barata de lo que el lector va a encontrar en su empresa.""")

# ---- 10.4 cerrada ----
sub("""**10.4 · ¿Qué hace exactamente la Fase 08, y cuánto código heredado escribe el curso?** Hay
tensión real: demasiado poco y el Bloque B no tiene material; demasiado y el lector pasa dos
semanas escribiendo código de 2017 a propósito. *Recomendación: un vertical delgado y completo*
—existencias por almacén y liquidación de regalías, que son los dos que la historia usa más—
con su esquema (`MOVINVEN`, `LIQREGAL`, `VENTAS_YYYY`), seis u ocho procedimientos almacenados
de verdad, la capa de datos con `DataSet`, y el generador de datos sucios. Todo lo demás del
sistema se cuenta como historia (guía §11, Regla 2).""",
"""**10.4 · 🪦 Cerrada: cuatro módulos, escritos en dos fases.** El legado que el curso escribe
son **existencias por almacén, liquidación de regalías, catálogo y facturación**, con su esquema
real (`MOVINVEN`, `LIQREGAL`, `VENTAS_YYYY`, `CAMPO1`…`CAMPO7`), los procedimientos almacenados
que llevan la lógica, la capa de datos con `DataSet` y el generador de datos sucios. Es
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
> el módulo de inventario de Lima— se cuenta como historia (guía §11, Regla 2).""")

# ---- 10.7 renumerar referencia ----
s = s.replace("reservar una sección dentro de la fase 11* —la del\n*strangler fig*—",
              "reservar una sección dentro de la fase 10* —la del\n*strangler fig*—")
s = s.replace("**10.5 · ¿El duelo contra qué, exactamente?** La fase 25 implementa CatalogAPI dos veces.",
              "**10.5 · ¿El duelo contra qué, exactamente?** La fase 23 implementa CatalogAPI dos veces.")
s = s.replace("antes de escribir la fase 17*,\nque es la primera que lo necesita.",
              "antes de escribir la fase 16*,\nque es la primera que lo necesita.")

# ---- §12 siguiente paso ----
sub("""1. **Resolver §10**, empezando por 10.1, que es la que bloquea todo lo demás porque cambia la
   numeración entera, y por 10.4, que fija cuánto código heredado escribe el curso.""",
"""1. **Resolver lo que queda abierto en §10** — 10.3, 10.5, 10.6, 10.7, 10.8, 10.9 y 10.10. Ninguna
   bloquea ya la numeración: 10.1, 10.2 y 10.4 están cerradas y la tabla de §4 es la vigente.""")
sub("""5. Escribir las fases 08 a 11 antes que el resto del Bloque D: son el corazón ⭐ y las que más
   pueden cambiar la forma de las anteriores.""",
"""5. Escribir las fases 07 a 11 antes que el resto del Bloque D: son el corazón ⭐ y las que más
   pueden cambiar la forma de las anteriores.""")
sub("""4. Escribir la Fase 00 y la Fase 01, que fijan el ambiente, el arnés y el dominio. Todo lo demás
   depende de ellas.""",
"""4. Escribir la Fase 00 y la Fase 01, que fijan el ambiente, el arnés y el dominio. Todo lo demás
   depende de ellas.""")

# estado del encabezado
sub("""> **Estado: propuesta abierta.** Este documento existe para **discutirse**, no para obedecerse
> todavía. Lo que está cerrado son las decisiones de §2 —vienen de `alcance-del-proyecto.md`— y
> la forma de cada fase. Lo que está abierto es la **secuencia**, y las preguntas concretas
> están en §10, cada una con una recomendación.""",
"""> **Estado: secuencia acordada, detalles abiertos.** La tabla de §4 —veinticinco fases, 00 a
> 24— está **cerrada** y es la numeración vigente; también lo están las decisiones de §2 y la
> forma de cada fase. Lo que sigue abierto son los detalles de §10 marcados sin 🪦, cada uno con
> su recomendación.""")
io.open(P,'w',encoding='utf-8').write(s)
print("ok")
PY
grep -n "🪦 \*\*Cerrada\|🪦 Cerrada\|^\*\*10\." propuesta-fases-y-alcance.md

# --- 2026-09-12T23:56:42 · Check desktop section text
sed -n '279,286p' propuesta-fases-y-alcance.md

# --- 2026-09-12T23:56:44 · Check paragraph wording
sed -n '286,292p' propuesta-fases-y-alcance.md

# --- 2026-09-12T23:57:24 · Apply closures and renumbering
python3 - <<'PY'
import io
P='propuesta-fases-y-alcance.md'
s=io.open(P,encoding='utf-8').read()
def sub(old,new):
    global s
    assert old in s, old[:80]
    s=s.replace(old,new,1)

sub("con Nohora de usuaria real y Ximena vigilando que no le agregues un paso | F17 |",
    "con Nohora de usuaria real y Ximena vigilando que no le agregues un paso | F18 |")
sub("porque dos veces al año un autor impugna | F18 |",
    "porque dos veces al año un autor impugna | F17 |")
sub("cada respuesta cita documento, versión y cláusula, o no se emite | F23 |",
    "cada respuesta cita documento, versión y cláusula, o no se emite | F22 |")
sub("No decide: prepara para que decida una persona | F24 |",
    "No decide: prepara para que decida una persona | F22 |")

sub("""La pregunta era si el curso debía incluir escritorio. La respuesta propuesta es **sí, con un
bloque de tres fases**, y los argumentos son concretos:""",
"""La pregunta era si el curso debía incluir escritorio. La respuesta, ya cerrada, es **sí, con un
bloque de tres fases** (12-14), y los argumentos son concretos:""")

sub("""La forma propuesta: **el mismo módulo, implementado tres veces**. Se elige uno de los
formularios de SIGE —la consulta de existencias por almacén, que tiene búsqueda, grilla con
volumen real, edición y un reporte— y se construye en WinForms sobre .NET 10 (F13), en WPF con
MVVM (F14) y como prototipo en WinUI 3 (F15). La fase 15 cierra midiendo las cuatro opciones
—las tres de escritorio más la web que nacerá en la F19— contra lo que de verdad importa:""",
"""La forma: **el mismo módulo, implementado tres veces**. Se elige uno de los formularios de
SIGE —la consulta de existencias por almacén, que tiene búsqueda, grilla con volumen real,
edición y un reporte— y se construye en WinForms sobre .NET 10 (F12), en WPF con MVVM (F13) y
como prototipo en WinUI 3 (F14). La fase 14 cierra midiendo las cuatro opciones —las tres de
escritorio más la web que nacerá en la F18— contra lo que de verdad importa:""")

sub("""**10.1 · ¿Veintisiete fases, o se consolidan?** Es la pregunta grande. Veintisiete fases con
miniproyecto cada una son veintisiete encargos difíciles, y el curso puede quedar más largo de
lo que nadie termina. Los candidatos naturales a fusión son 04+05 (delegados y recursos), 14+15
(WPF y el veredicto del escritorio), 23+24 (los dos proyectos de IA) y 20 dentro de 21
(observabilidad y despliegue). *Recomendación: fusionar 04+05 y 23+24, y dejar el resto, para
un total de 25.* Fusionar 14+15 dejaría el veredicto del escritorio —que es el contenido del
bloque— como apéndice de una fase de WPF, y meter observabilidad dentro de la fase de la
factura produciría la fase más larga del curso.""",
"""**10.1 · 🪦 Cerrada: veinticinco fases.** Se fusionaron 04+05 (ceremonia y recursos) y los dos
proyectos de IA en la 22. Quedan separadas el veredicto del escritorio y la fase de la factura,
por las razones que están al pie de la tabla de §4. La numeración de §4 es la vigente y ninguna
fase se renumera por su cuenta.""")

sub("""*Recomendación: escribir el código contra **.NET Framework 4.8** y resolverlo dentro de la
ficción* — Wilson subió el destino a 4.8 en 2021 porque una actualización de Windows rompió un
controlador de impresión, fue el único cambio que ese código recibió en nueve años, y no arregló
nada de fondo. Es verosímil, es lo que pasa de verdad en esas empresas, y deja el `App.config`,
el `packages.config`, los `DataSet` y la ausencia de `async` exactamente donde estaban. La
alternativa —4.5 con paquetes de destino descargados aparte— compra fidelidad de número y paga
con media fase de fricción de instalación.""",
"""🪦 **Cerrada: .NET Framework 4.8, resuelto dentro de la ficción.** Wilson subió el destino a
4.8 en 2021 porque una actualización de Windows rompió un controlador de impresión fiscal; fue
el único cambio que ese código recibió en nueve años y no arregló nada de fondo. Es verosímil,
es lo que pasa de verdad en esas empresas, y deja el `App.config`, el `packages.config`, los
`DataSet` y la ausencia de `async` exactamente donde estaban.

> ⚠️ **Dos consecuencias que las fases deben respetar.** La historia sigue diciendo **4.5** y
> **Visual Studio 2015** para 2016-2017 (§3 de `historia-propuesta-1-cordillera.md`): ese dato
> no se toca, y el salto a 4.8 se narra como lo que fue, un parche de 2021. Y la fase 11 tiene
> que decir en voz alta que **migrar de 4.8 a .NET 10 es más fácil que migrar de 4.5**, porque
> 4.8 ya trae buena parte del camino andado — presentarlo como si fuera el caso difícil sería
> venderle al lector una migración más barata de la que va a encontrar en su empresa.""")

sub("""**10.4 · ¿Qué hace exactamente la Fase 08, y cuánto código heredado escribe el curso?** Hay
tensión real: demasiado poco y el Bloque B no tiene material; demasiado y el lector pasa dos
semanas escribiendo código de 2017 a propósito. *Recomendación: un vertical delgado y completo*
—existencias por almacén y liquidación de regalías, que son los dos que la historia usa más—
con su esquema (`MOVINVEN`, `LIQREGAL`, `VENTAS_YYYY`), seis u ocho procedimientos almacenados
de verdad, la capa de datos con `DataSet`, y el generador de datos sucios. Todo lo demás del
sistema se cuenta como historia (guía §11, Regla 2).""",
"""**10.4 · 🪦 Cerrada: cuatro módulos, escritos en dos fases.** El legado que el curso escribe son
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
> el módulo de inventario de Lima— se cuenta como historia (guía §11, Regla 2).""")

s = s.replace("reservar una sección dentro de la fase 11*", "reservar una sección dentro de la fase 10*")
s = s.replace("**10.5 · ¿El duelo contra qué, exactamente?** La fase 25 implementa",
              "**10.5 · ¿El duelo contra qué, exactamente?** La fase 23 implementa")
s = s.replace("antes de escribir la fase 17*", "antes de escribir la fase 16*")

sub("""1. **Resolver §10**, empezando por 10.1, que es la que bloquea todo lo demás porque cambia la
   numeración entera, y por 10.4, que fija cuánto código heredado escribe el curso.""",
"""1. **Resolver lo que sigue abierto en §10** — 10.3, 10.5, 10.6, 10.7, 10.8, 10.9 y 10.10.
   Ninguna bloquea ya la numeración: 10.1, 10.2 y 10.4 están cerradas y la tabla de §4 es la
   vigente.""")
sub("""5. Escribir las fases 08 a 11 antes que el resto del Bloque D:""",
    """5. Escribir las fases 07 a 11 antes que el resto del Bloque D:""")

sub("""> **Estado: propuesta abierta.** Este documento existe para **discutirse**, no para obedecerse
> todavía. Lo que está cerrado son las decisiones de §2 —vienen de `alcance-del-proyecto.md`— y
> la forma de cada fase. Lo que está abierto es la **secuencia**, y las preguntas concretas
> están en §10, cada una con una recomendación.""",
"""> **Estado: secuencia acordada, detalles abiertos.** La tabla de §4 —veinticinco fases, 00 a
> 24— está **cerrada** y es la numeración vigente; también lo están las decisiones de §2 y la
> forma de cada fase. Lo que sigue abierto son los puntos de §10 que no llevan 🪦, cada uno con
> su recomendación.""")
io.open(P,'w',encoding='utf-8').write(s)
print("ok")
PY
grep -n "^\*\*10\.\|^🪦 \*\*Cerrada" propuesta-fases-y-alcance.md

# --- 2026-09-12T23:57:33 · Check remaining stale references
sed -n '370,377p' propuesta-fases-y-alcance.md; echo "--- ref sweep ---"; grep -n "fase 0[89]\|fase 1[0-9]\|fase 2[0-9]\|Fase 0[89]\|F1[0-9]\|F2[0-9]\|veintis[eé]\|27 fases\|veinticuatro\|veintiséis" propuesta-fases-y-alcance.md | grep -v "^3[4-9][0-9]:.*10\."

# --- 2026-09-12T23:57:39 · Fix stale phase numbers
python3 - <<'PY'
import io
P='propuesta-fases-y-alcance.md'
s=io.open(P,encoding='utf-8').read()
s=s.replace("y se eligen en la fase 21 |","y se eligen en la fase 20 |")
s=s.replace("depura y un arnés de medición que va a usar veintiséis veces.","depura y un arnés de medición que va a usar veinticuatro veces.")
s=s.replace("**es la herramienta con la que se mide todo el resto del curso**, veinticuatro fases.","**es la herramienta con la que se mide todo el resto del curso**.")
s=s.replace("""La propuesta las mete
en la 09, como *pruebas de caracterización*""","""La propuesta las mete
en la 08, como *pruebas de caracterización*""")
s=s.replace("es de Windows (§2), el legado es auténtico y la fase 12 es una migración de verdad.*","es de Windows (§2), el legado es auténtico y la fase 11 es una migración de verdad.*")
io.open(P,'w',encoding='utf-8').write(s)
print("ok")
PY
grep -rn "fase 2[1-9]\|Fase 2[5-9]\|fases 13-15\|fase 15\|fase 19\b" *.md | grep -v historia

# --- 2026-09-12T23:57:46 · Find Framework 4.5 mentions
grep -rn "4\.5" *.md | grep -v historia-propuesta

# --- 2026-09-12T23:58:03 · Align Framework version across docs
python3 - <<'PY'
import io
def sub(p,old,new):
    s=io.open(p,encoding='utf-8').read(); assert old in s,(p,old[:60])
    io.open(p,'w',encoding='utf-8').write(s.replace(old,new,1))

sub('alcance-del-proyecto.md',
"| El runtime heredado que se migra | **.NET Framework 4.5**, escrito como C# 2 | Bloque del sistema heredado |",
"| El runtime heredado que se migra | **.NET Framework 4.8**, escrito como C# de 2017 | Bloque del sistema heredado |")

sub('alcance-del-proyecto.md',
"""- 🪦 **Windows 11 exclusivamente** (§10). Sin variantes por plataforma en ningún documento.""",
"""- 🪦 **Windows 11 exclusivamente** (§10). Sin variantes por plataforma en ningún documento.
- 🪦 **El legado se compila contra .NET Framework 4.8**, no contra el 4.5 que dice la historia.
  La historia no se toca: el salto a 4.8 se narra como el parche de 2021 que fue, y la fase de
  migración declara que salir de 4.8 es más fácil que salir de 4.5
  (`propuesta-fases-y-alcance.md` §10.2).""")

sub('guia-de-estilo-y-convenciones.md',
"""- **.NET Framework 4.5 y C# escrito como C# 2**: sin LINQ, sin `var`, sin genéricos más allá""",
"""- **.NET Framework 4.8 y C# escrito como C# de 2017**: sin LINQ, sin `var`, sin genéricos más allá""")

sub('guia-de-estilo-y-convenciones.md',
"""Nada de esto se escribe con vergüenza ni con guiños de superioridad: se escribe con su fecha
al lado.""",
"""> 📝 **Por qué 4.8 y no el 4.5 de la historia.** Los pasantes escribieron sobre 4.5 en 2016, y
> eso no cambia. Wilson subió el destino a 4.8 en 2021 porque una actualización de Windows
> rompió un controlador de impresión fiscal: fue el único cambio que ese código recibió en
> nueve años y no arregló nada de fondo. El curso compila contra 4.8 por eso, y la fase de
> migración dice en voz alta que salir de 4.8 es más fácil que salir de 4.5.

Nada de esto se escribe con vergüenza ni con guiños de superioridad: se escribe con su fecha
al lado.""")

sub('plantillas-de-capitulo.md',
"> Estilo de esta fase: {{heredado (.NET Framework 4.5, C# 2) | nuevo (.NET 10, C# 14) | mixto 🧬}}",
"> Estilo de esta fase: {{heredado (.NET Framework 4.8, C# de 2017) | nuevo (.NET 10, C# 14) | mixto 🧬}}")

sub('plantillas-de-capitulo.md',
"""- **Escrito en el estilo declarado en el encabezado.** Heredado: `DataSet`, `SqlConnection` en
  el manejador del botón, C# 2, sin `async`.""",
"""- **Escrito en el estilo declarado en el encabezado.** Heredado: .NET Framework 4.8, `DataSet`,
  `SqlConnection` en el manejador del botón, C# de 2017, sin `async`.""")

sub('prompts-de-fase.md',
"""- **Escribe en el estilo declarado de esta fase.** Heredado significa .NET Framework 4.5
  y C# de 2017, con `DataSet` y sin `async`;""",
"""- **Escribe en el estilo declarado de esta fase.** Heredado significa .NET Framework 4.8
  y C# de 2017, con `DataSet` y sin `async`;""")

sub('propuesta-fases-y-alcance.md',
"| Runtime heredado | **.NET Framework 4.5, escrito como C# de 2017** |",
"| Runtime heredado | **.NET Framework 4.8, escrito como C# de 2017** (§10.2) |")
print("ok")
PY
grep -rn "4\.5\b" *.md | grep -v historia-propuesta | grep -v "^formato-de-miniproyectos.md:135\|^guia-de-estilo-y-convenciones.md:157"

# --- 2026-09-13T00:04:10 · Close testing decision
python3 - <<'PY'
import io
P='propuesta-fases-y-alcance.md'
s=io.open(P,encoding='utf-8').read()
def sub(old,new):
    global s
    assert old in s, old[:80]
    s=s.replace(old,new,1)

sub("""**10.3 · ¿Dónde entran las pruebas?** No hay una fase llamada "testing". La propuesta las mete
en la 08, como *pruebas de caracterización* sobre los procedimientos heredados —que es su uso
más defendible y el más difícil de enseñar—, y después el curso las usa en todas las fases.
*Recomendación: mantenerlo así, y fijar el marco (xUnit o MSTest, más Testcontainers) en la
Fase 00* para que el arnés y las primeras pruebas nazcan con él. La alternativa —una fase de
pruebas al final del Bloque A— enseñaría xUnit sobre ejemplos de juguete, que es exactamente lo
que este perfil no necesita.""",
"""**10.3 · 🪦 Cerrada: no hay fase de "testing", hay tres anclas y una fase de pruebas de verdad.**

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
exactas se fijan en `alcance-del-proyecto.md` §9 al escribir la Fase 00.""")

sub("""| `async`/`await` de referencia | Fase 06, con su medición |""",
"""| `async`/`await` de referencia | Fase 05, con su medición |
| Pruebas: marco, ciclo de vida y dobles | Repartido en F00, F04 y F05; la fase de pruebas de verdad es la F08 (§10.3) |""")

sub("""| 04 | 🎩 Ceremonia que sobra y ceremonia que falta: delegados, extensiones, genéricos, `IDisposable` | nuevo | la interfaz de un solo método; el `catch (Exception)` que se traga lo que importaba | modelo |
| 05 ⭐ | ⚙️ `async`/`await` de punta a punta, `CancellationToken`, paralelismo | nuevo | `.Result`, `async void`, pensar en hilos | modelo |""",
"""| 04 | 🎩 Ceremonia que sobra y ceremonia que falta: delegados, extensiones, genéricos, `IDisposable` — y el ciclo de vida de una prueba | nuevo | la interfaz de un solo método; el `catch (Exception)` que se traga lo que importaba; `@BeforeEach` | modelo |
| 05 ⭐ | ⚙️ `async`/`await` de punta a punta, `CancellationToken`, paralelismo — y cómo se prueba | nuevo | `.Result`, `async void`, pensar en hilos | modelo |""")

sub("""| 08 ⭐ | 🔎 Caracterizar lo que no puedes leer: pruebas de aproximación sobre los procedimientos | mixto 🧬 | reescribir antes de entender | SIGE (entran catálogo y facturación) |""",
"""| 08 ⭐ | 🔎 Caracterizar lo que no puedes leer: *golden master*, Testcontainers y cobertura útil | mixto 🧬 | reescribir antes de entender; traducir JUnit línea por línea | SIGE (entran catálogo y facturación) |""")

sub("""1. **Resolver lo que sigue abierto en §10** — 10.3, 10.5, 10.6, 10.7, 10.8, 10.9 y 10.10.
   Ninguna bloquea ya la numeración: 10.1, 10.2 y 10.4 están cerradas y la tabla de §4 es la
   vigente.""",
"""1. **Resolver lo que sigue abierto en §10** — 10.5, 10.6, 10.7, 10.8, 10.9 y 10.10. Ninguna
   bloquea la escritura: 10.1, 10.2, 10.3 y 10.4 están cerradas, la tabla de §4 es la vigente y
   los prompts de las veinticinco fases ya están escritos en
   [`prompts-fases-00-24.md`](prompts-fases-00-24.md).""")
io.open(P,'w',encoding='utf-8').write(s)
print("ok")
PY

# --- 2026-09-13T00:05:19 · Write measurement format doc
cat > /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs/prompts/formato-de-mediciones.md <<'FIN'
# 📏 Formato de las mediciones
## C# para desarrolladores Java senior

El curso tiene una regla que lo sostiene entero: **ninguna afirmación comparativa entra sin un
número producido por el arnés del curso** (guía §4.6). Este documento define el arnés, la forma
de la medición y las reglas de honestidad que la hacen creíble. Es la sección 6 de cada fase.

Se sigue literal. Una medición mal hecha es peor que ninguna, porque el lector la va a citar.

---

## 1. El arnés

**Se construye en la Fase 00 y no se reemplaza nunca.** Las fases posteriores lo amplían —pico
de memoria en la 06, latencia de red en la 15, costo mensual en la 20— pero ninguna lo sustituye
por otro, y ninguna mide con algo que el lector no tenga.

Qué hace, y nada más:

- **Ejecuta la operación N veces y descarta el calentamiento.** En .NET esto no es un detalle:
  el JIT compila en el primer paso y vuelve a compilar en niveles superiores más adelante, así
  que las primeras iteraciones miden al compilador, no al código.
- **Reporta mediana y percentil 95**, nunca el promedio. El promedio de una distribución con
  pausas de GC no describe nada que le pase a un usuario.
- **Reporta asignaciones totales y pico de memoria administrada**, además del tiempo. En este
  ecosistema la mitad de las diferencias interesantes son de asignación, y el tiempo solo las
  refleja cuando el recolector ya se despertó.
- **Declara el entorno** en la propia salida: versión del SDK, configuración de compilación,
  máquina, tamaño del dato y número de repeticiones.
- **Escribe el resultado en el formato de §3**, listo para pegarse en `BENCHMARKS.md`.

> 🧭 **Que sea pequeño.** Un arnés que hay que aprender a usar deja de usarse. Si en la Fase 12
> el lector tiene que releer cómo se invoca, el arnés está mal diseñado.

**Sobre BenchmarkDotNet:** existe, es excelente y es el estándar del ecosistema. El curso lo
presenta y lo usa **donde la pregunta es de microbenchmark** —una asignación, un parseo, una
comparación de estructuras— porque ahí hacer las cosas a mano es equivocarse. Para todo lo demás
—un reporte de 500.000 filas, el arranque en frío de un contenedor, la latencia de una pantalla
desde Lima— el arnés propio es más honesto, porque mide el trabajo completo y no el fragmento.
La fase que use uno u otro dice cuál y por qué.

---

## 2. Las cinco reglas de honestidad

**2.1 · El competidor es defendible.** Se compara contra una implementación que alguien
defendería en una revisión de código: con su pool de conexiones, su índice puesto y su
configuración de producción. Medir contra un espantapájaros es la forma más común de mentir con
datos ciertos, y en un curso que compara .NET con Java es la tentación permanente.

**2.2 · Primero SQL, después .NET.** Cuando el trabajo toca la base de datos, el plan de consulta
se mide **antes** que el código. Con treinta tablas anuales unidas por `UNION ALL` generado
concatenando cadenas, el primer orden de magnitud no está en el lenguaje. Optimizar C# encima de
una consulta mala es teatro, y el curso lo dice cada vez que aplique.

**2.3 · El dato es realista y está fechado.** Los volúmenes salen de la historia: 500.000 filas
en el reporte histórico, 1.900 movimientos huérfanos, 400 manuscritos al mes, 90 instalaciones,
nueve husos. Un benchmark sobre mil filas no decide nada y lo sabe todo el mundo.

**2.4 · Se publica el empate.** Cuando dos opciones quedan dentro del ruido de la medición, el
veredicto dice *empate* y lo justifica con la dispersión. Es la palabra que menos aparece en los
cursos de tecnología y la que más falta hace — y en el duelo de la Fase 23 va a aparecer varias
veces.

**2.5 · Lo que no se puede ejecutar se declara, no se estima en silencio.** El curso no exige
suscripción de Azure de pago (`alcance-del-proyecto.md` §10). Donde la medición sea de costo o
de un servicio que no se puede levantar en local, se dice **qué precio publicado se usó, de qué
fecha, y en qué región**, y se marca el resultado como *no ejecutado*. Un número inventado
contamina las veinticinco fases.

---

## 3. La forma de la sección 6

Idéntica en todas las fases, para que se puedan comparar entre sí y volcarse a `BENCHMARKS.md`.

````markdown
## 📏 6. Medición

**Hipótesis:** {{una línea, falsable. "EF Core con seguimiento cuesta más que Dapper en la
consulta de catálogo" — no "queremos ver el rendimiento".}}

**Condiciones:** SDK {{x.y.z}} · compilación Release · {{máquina}} · {{tamaño del dato}} ·
{{repeticiones, calentamiento descartado}} · {{qué se mide y con qué}}

**Competidores:** {{qué se compara, y por qué cada uno es defendible}}

**Resultado:**

| Opción | Mediana | p95 | Asignado | Pico |
|---|---|---|---|---|
| {{...}} | {{...}} | {{...}} | {{...}} | {{...}} |

> ⚖️ **Veredicto.** {{Qué gana, dónde pierde, y **a partir de qué umbral cambia la respuesta**.
> El umbral es la parte que el lector se lleva: "por debajo de veinte mil filas la diferencia no
> justifica el cambio".}}
````

**La tercera línea del veredicto es obligatoria y es la que más se olvida:** un veredicto sin
umbral es una preferencia. *"Dapper gana"* no sirve; *"Dapper gana en lectura de lotes grandes y
la ventaja desaparece por debajo de las dos mil filas, donde el costo de mantener dos formas de
acceso a datos pesa más"* sí.

---

## 4. Las fases que no miden

Una fase sin medición es la excepción, no la norma, y lo dice en una línea convincente dentro de
la propia sección 6. En la secuencia actual hay una sola candidata razonable —la Fase 24, que es
el veredicto y consolida mediciones ajenas en vez de producir una propia— y aun así publica la
tabla acumulada.

Si al escribir una fase la medición no aparece sola, casi siempre significa una de dos cosas: la
fase no tiene una afirmación comparativa que sostener —y entonces sobra la sección— o la tiene y
no se está midiendo, que es el error que este documento existe para evitar.

---

## 5. `BENCHMARKS.md`

Vive en la raíz del curso y **nace con la Fase 00**, no al final. Cada fase agrega su entrada al
cerrarse, con el mismo formato de §3 más dos campos que solo tienen sentido en el archivo
consolidado: **la fase que la produjo** y **la fecha de ejecución**.

Dejarlo para el final garantiza que las condiciones de las primeras mediciones se pierdan, y una
medición sin sus condiciones no es una medición: es una anécdota con decimales.

Cuando una medición posterior **contradiga** a una anterior —pasa, y es sano—, la entrada vieja
no se borra: se marca 🪦 con un puntero a la nueva y una línea sobre qué cambió. El historial de
las veces que el curso se equivocó midiendo es material didáctico, no vergüenza.

---

## 6. Checklist de una medición antes de darla por buena

- [ ] La hipótesis es falsable y cabe en una línea.
- [ ] Las condiciones incluyen SDK, configuración, máquina, volumen y repeticiones.
- [ ] Se descartó el calentamiento, y se dice cuántas iteraciones.
- [ ] Se reporta mediana y p95, no promedio.
- [ ] Se reportan asignaciones y pico de memoria, no solo tiempo.
- [ ] El competidor es defendible en una revisión de código (§2.1).
- [ ] Si toca la base, el plan de consulta se midió primero (§2.2).
- [ ] El volumen sale de la historia, no de un `for` de mil (§2.3).
- [ ] Si hay empate, dice empate (§2.4).
- [ ] Lo que no se ejecutó está marcado como tal, con precio, fecha y región (§2.5).
- [ ] El veredicto declara **el umbral donde cambia la respuesta**.
- [ ] La entrada quedó agregada a `BENCHMARKS.md`.
FIN
wc -l /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs/prompts/formato-de-mediciones.md

# --- 2026-09-13T00:05:29 · Prepare section 5 for expansion
python3 - <<'PY'
import io
P='propuesta-fases-y-alcance.md'
s=io.open(P,encoding='utf-8').read()
s=s.replace("## 5. 🛠️ La Fase 00 en detalle","## 5. 🪜 Las fases, una a una\n\nEste es **el alcance literal de cada fase** y la fuente que consulta el chat que la escribe. Los\nprompts de `prompts-de-fase.md` no lo repiten: lo citan.\n\n### 🛠️ Fase 00 — Ambiente, Visual Studio y el mapa del ecosistema",1)
s=s.replace("""> 🧭 **La regla que fija esta fase:** *si no lo puedes medir con el arnés, no lo afirmas.*

---

## 6. 🧳""","""> 🧭 **La regla que fija esta fase:** *si no lo puedes medir con el arnés, no lo afirmas.*

PLACEHOLDER_FASES

---

## 6. 🧳""",1)
io.open(P,'w',encoding='utf-8').write(s)
print('ok')
PY
grep -n "PLACEHOLDER_FASES\|^## 5\.\|^### 🛠️ Fase 00" propuesta-fases-y-alcance.md

# --- 2026-09-13T00:06:26 · Add Bloque A phase details
cat > /tmp/fases_a.md <<'FIN'

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
FIN
python3 -c "
import io
s=io.open('propuesta-fases-y-alcance.md',encoding='utf-8').read()
b=io.open('/tmp/fases_a.md',encoding='utf-8').read()
s=s.replace('PLACEHOLDER_FASES', b.strip('\n')+'\n\nPLACEHOLDER_FASES',1)
io.open('propuesta-fases-y-alcance.md','w',encoding='utf-8').write(s)
print('ok')
"

# --- 2026-09-13T00:07:16 · Add Bloque B phase details
cat > /tmp/fases_b.md <<'FIN'

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
sobre código heredado, que no es el porcentaje; y el 📖 completo JUnit ⇄ xUnit.

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
FIN
python3 -c "
import io
s=io.open('propuesta-fases-y-alcance.md',encoding='utf-8').read()
b=io.open('/tmp/fases_b.md',encoding='utf-8').read()
s=s.replace('PLACEHOLDER_FASES', b.strip('\n')+'\n\nPLACEHOLDER_FASES',1)
io.open('propuesta-fases-y-alcance.md','w',encoding='utf-8').write(s)
print('ok')
"

# --- 2026-09-13T00:08:18 · Add Bloques C and D phase details
cat > /tmp/fases_c.md <<'FIN'

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

**No entra:** orquestación avanzada, declarada fuera; el repositorio tiene un curso para eso.

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
FIN
python3 -c "
import io
s=io.open('propuesta-fases-y-alcance.md',encoding='utf-8').read()
b=io.open('/tmp/fases_c.md',encoding='utf-8').read()
s=s.replace('PLACEHOLDER_FASES', b.strip('\n')+'\n\nPLACEHOLDER_FASES',1)
io.open('propuesta-fases-y-alcance.md','w',encoding='utf-8').write(s)
print('ok')
"

# --- 2026-09-13T00:08:58 · Add Bloque E and closing phase details
cat > /tmp/fases_e.md <<'FIN'

---

### 📊 Fase 21 — Los datos que mienten, y servir un modelo con ONNX

**Entra:** separar honestamente sell-in, sell-out y devolución, por país, sello y canal, con tres
distribuidores de tres calendarios y dos plataformas que reportan en semanas ISO; la canalización
que prepara los datos; ML.NET presentado y evaluado; y **servir con ONNX Runtime un modelo
entrenado en Python**.

**No entra:** teoría de aprendizaje automático, y se declara — el repositorio tiene `cursos-ia`.

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

**🧱 Miniproyecto:** implementar la contraparte en Spring Boot 3 y publicar la tabla. *La trampa:*
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
FIN
python3 -c "
import io
s=io.open('propuesta-fases-y-alcance.md',encoding='utf-8').read()
b=io.open('/tmp/fases_e.md',encoding='utf-8').read()
s=s.replace('\nPLACEHOLDER_FASES', b.rstrip('\n'),1)
io.open('propuesta-fases-y-alcance.md','w',encoding='utf-8').write(s)
print('ok')
"
grep -c "" propuesta-fases-y-alcance.md; grep -n "PLACEHOLDER" propuesta-fases-y-alcance.md; grep -c "^### " propuesta-fases-y-alcance.md

# --- 2026-09-13T00:09:03 · Verify document structure
grep -n "^### \|^## " propuesta-fases-y-alcance.md | sed -n '1,60p'

# --- 2026-09-13T00:12:18 · Write all 25 phase prompts
cat > /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs/prompts/prompts-de-fase.md <<'FIN'
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

1. El `CLAUDE.md` del repositorio.
2. `prompts/alcance-del-proyecto.md` — qué es el curso y qué no.
3. `prompts/propuesta-fases-y-alcance.md` — **§5 tiene el alcance detallado de esta fase y se
   sigue literal**; §4 tiene la numeración oficial, que no se cambia.
4. `prompts/guia-de-estilo-y-convenciones.md` — voz, código, marcadores, plantilla, ejercicios.
5. `prompts/plantillas-de-capitulo.md` — las 10 secciones, en orden, sin extras.
6. `prompts/formato-de-miniproyectos.md` — el miniproyecto y su prueba de calibración.
7. `prompts/formato-de-mediciones.md` — el arnés y la forma de la medición.
8. `prompts/historia-propuesta-1-cordillera.md` — todo lo narrativo: personajes, cifras,
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
`00-ambiente-visual-studio-y-ecosistema.md`
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
FIN
wc -l /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs/prompts/prompts-de-fase.md

# --- 2026-09-13T00:13:11 · Write framing document prompts
cat > prompts-de-documentos-de-encuadre.md <<'FIN'
# 📐 Prompts de los documentos de encuadre
## C# para desarrolladores Java senior

Los documentos que **no** son fases y que el lector sí lee. Cada uno se escribe en su propio chat
y produce un solo archivo, igual que una fase.

Van **antes** que la Fase 00, salvo `BENCHMARKS.md` e `INSTINTOS.md`, que nacen con ella y crecen
después. El orden está en [`como-escribir-el-curso.md`](como-escribir-el-curso.md).

Todos usan el **§ Marco común** de [`prompts-de-fase.md`](prompts-de-fase.md) —fuentes de verdad,
las nueve reglas, plataforma, ficción— con una diferencia: **no siguen la plantilla de diez
secciones**, porque no son fases. Cada bloque de abajo dice qué forma tiene el suyo.

---

## # `README.md` del curso

````markdown
Produce el archivo `README.md` en la raíz del curso *C# para desarrolladores Java senior*.
Aplica el § Marco común de `prompts-de-fase.md`, con esta excepción: no sigue la plantilla de
diez secciones.

**Qué es:** el escaparate. Alguien que llega al directorio decide en dos minutos si este curso
es para él. No es un índice comentado ni un resumen del alcance.

**Qué lleva, en este orden:**
- Qué es el curso en dos frases, con la pregunta que lo ordena — *¿esto se migra, se envuelve o
  se deja quieto?*
- Para quién es y para quién **no**: dev Java senior con ocho años o más; no es un curso de
  introducción a la programación ni de certificación en Azure.
- El stack fijado, con sus versiones, tomado de `alcance-del-proyecto.md` §9 — no se inventa
  ninguna.
- **Windows 11 como requisito**, dicho en el escaparate y no en una nota al pie, con su razón:
  el sistema heredado son 340 formularios WinForms sobre .NET Framework.
- El mapa de los siete bloques y las veinticinco fases, con una línea por bloque. La tabla
  detallada vive en `0-ESTRUCTURA-CURSO.md`; aquí va el mapa, no el índice.
- La empresa: Cordillera Media en un párrafo, lo justo para que se entienda el dominio.
- Cómo se trabaja: un miniproyecto obligatorio por fase, una medición por fase, y el repositorio
  con sus tags.
- El veredicto que el curso se debe a sí mismo, citado: *si al final resultara que .NET moderno
  ganó todo, el curso estaría mal escrito.*

**Qué NO lleva:** instrucciones de instalación (son la Fase 00), el detalle de las fases (es
`0-ESTRUCTURA-CURSO.md`), ni promesas de lo que el lector "va a dominar".

**Cuidado con:** escribir un índice. Un README que solo enumera archivos no ayuda a nadie a
decidir si tomar el curso.
````

---

## # `0-ESTRUCTURA-CURSO.md`

````markdown
Produce el archivo `0-ESTRUCTURA-CURSO.md` en la raíz del curso. Aplica el § Marco común de
`prompts-de-fase.md`, con esta excepción: no sigue la plantilla de diez secciones.

**Qué es:** la fuente de verdad de la estructura **para el lector** — el equivalente legible de
`prompts/propuesta-fases-y-alcance.md`, sin las decisiones abiertas ni el material de autoría.

**Qué lleva:**
- Los siete bloques, con el porqué de cada uno en un párrafo.
- La tabla de las veinticinco fases: número, nombre, estilo de código, el reflejo 🪞 que ataca y
  el proyecto que avanza. Sale literal de `propuesta-fases-y-alcance.md` §4.
- Los seis proyectos que atraviesan el curso, con la fase en que nace cada uno (§7 de la
  propuesta).
- Qué está fuera del alcance y por qué, incluidos los tracks opcionales.
- **La regla de forma:** no hay apéndices, y qué hacer cuando algo parezca uno.
- Las dependencias entre fases: qué necesita qué para existir.

**Qué NO lleva:** las decisiones abiertas de §10 de la propuesta, los 📌 de autoría, ni horas por
fase — el curso no las publica (§10.6); publica la estimación del miniproyecto, de dos a cinco
horas.

**Cuidado con:** dejar que se desincronice de la propuesta. Si al escribirlo aparece una
contradicción, se arregla **en la propuesta primero** y aquí después.
````

---

## # `00-convencion-de-git-y-tags.md`

````markdown
Produce el archivo `00-convencion-de-git-y-tags.md` en la raíz del curso. Aplica el § Marco común
de `prompts-de-fase.md`, con esta excepción: no sigue la plantilla de diez secciones.

**Qué es:** el documento que todas las fases enlazan desde su bloque 🏷️ **sin reexplicarlo**.
Corto, operativo, de consulta.

**Qué lleva:**
- Un repositorio para todo el curso, con la estructura de `src/` que fija la Fase 00.
- Commits con el prefijo de la fase: `fase 07: …`, los de ejercicio con su número
  (`fase 07 ej12: …`) y el miniproyecto con el suyo (`fase 07 mini: …`).
- Un tag anotado por fase cerrada: `fase-NN`, con el checklist de la sección 2 en el mensaje.
- Un tag anotado por miniproyecto: `mini-NN`, **con el número de su medición en el mensaje** —
  es donde se recupera después con `git show`.
- Ramas de trabajo con prefijo (`wip/`, `spike/`) para no chocar con los tags.
- Cómo se lee una factura de deuda 💸: `git diff fase-02 fase-09 -- <ruta>`, que es la forma en
  que el curso demuestra lo que costó un atajo.
- **Lo propio de este curso:** el legado y lo nuevo conviven en el mismo repositorio con dos
  runtimes. Di cómo se organizan las soluciones y por qué el tag de una fase mixta 🧬 cubre las
  dos mitades.

**Cuidado con:** enseñar git. El lector lleva años usándolo. Esto es una convención, no un
tutorial: que quepa en una pantalla y media.
````

---

## # `BENCHMARKS.md`

````markdown
Produce el archivo `BENCHMARKS.md` en la raíz del curso, en su versión inicial. Aplica el
§ Marco común de `prompts-de-fase.md` y **sigue `formato-de-mediciones.md` §5 literal**.

**Qué es:** el archivo consolidado de todas las mediciones del curso. **Nace con la Fase 00**,
vacío de resultados pero completo de forma, y cada fase agrega su entrada al cerrarse.

**Qué lleva en su versión inicial:**
- Qué es el arnés y dónde vive el código (lo escribe el miniproyecto de la Fase 00).
- Las cinco reglas de honestidad de `formato-de-mediciones.md` §2, resumidas para el lector: el
  competidor defendible, primero SQL y después .NET, el dato realista, el empate publicado, y lo
  no ejecutado declarado con precio, fecha y región.
- El formato de una entrada: hipótesis, condiciones, competidores, tabla, veredicto **con
  umbral**, más la fase que la produjo y la fecha de ejecución.
- Cómo se marca 🪦 una medición que otra posterior contradijo, sin borrarla.
- La tabla de contenidos vacía, con una fila por fase, lista para llenarse.

**Cuidado con:** inventar resultados. En su versión inicial este archivo no tiene ni un número:
los produce cada fase con el arnés en la máquina de quien escribe.
````

---

## # `INSTINTOS.md`

````markdown
Produce el archivo `INSTINTOS.md` en la raíz del curso, en su versión inicial. Aplica el § Marco
común de `prompts-de-fase.md`, con esta excepción: no sigue la plantilla de diez secciones.

**Qué es:** el documento de reflejos recurrentes — la versión consolidada y consultable de todas
las secciones 🪞 del curso. Nace con la Fase 00 y cada fase le agrega el suyo al cerrarse.

**Qué lleva:**
- El reflejo, en una línea, en las palabras en que se le ocurre al lector.
- El código que produce, mínimo.
- Por qué falla **en C#**, y qué se escribe en su lugar.
- **Dónde se rompe el paralelo con Java**, que es la columna que hace útil el documento.
- La fase donde está desarrollado.

**Cómo se organiza:** por familia —tipos, ejecución diferida, asincronía, recursos, datos,
arquitectura— y no por número de fase, porque se consulta buscando un síntoma.

**Y una sección propia de este curso:** los reflejos que **no** son de lenguaje sino de
arquitectura — *reescribámoslo todo*, *no toquemos nada*, *primero refactorizamos y luego
migramos*, *si está viejo está mal*—, que son los caros y los que el veredicto final retoma.

**Cuidado con:** convertirlo en una lista de trucos. Cada entrada explica **por qué el instinto
existía y dónde era correcto**, porque un reflejo que se ridiculiza no se desaprende.
````
FIN
wc -l prompts-de-documentos-de-encuadre.md

# --- 2026-09-13T00:13:53 · Write course operating manual
cat > como-escribir-el-curso.md <<'FIN'
# 🧭 Cómo se escribe este curso
## C# para desarrolladores Java senior

Manual de operación del directorio `prompts/`. Dice **qué documento manda sobre cuál**, **en qué
orden se escribe el curso** y **qué se hace en cada chat**. Se lee una vez, al empezar, y se
vuelve a él cuando haya dudas de proceso — no de contenido.

---

## 1. Qué hay aquí, y para qué sirve cada cosa

| Documento | Qué es | Cuándo se lee |
|---|---|---|
| [`alcance-del-proyecto.md`](alcance-del-proyecto.md) | Qué es el curso, para quién, qué no hace, versiones, plataforma | Antes de escribir cualquier cosa |
| [`propuesta-fases-y-alcance.md`](propuesta-fases-y-alcance.md) | La secuencia cerrada de 25 fases y **el alcance literal de cada una** (§5) | En cada chat de fase |
| [`guia-de-estilo-y-convenciones.md`](guia-de-estilo-y-convenciones.md) | Voz, código, marcadores, ejercicios, checklist de cierre | En cada chat, siempre |
| [`plantillas-de-capitulo.md`](plantillas-de-capitulo.md) | El esqueleto de diez secciones | Al empezar y al cerrar una fase |
| [`formato-de-miniproyectos.md`](formato-de-miniproyectos.md) | El miniproyecto 🧱 y su prueba de calibración | Al escribir la sección 7 |
| [`formato-de-mediciones.md`](formato-de-mediciones.md) | El arnés, la medición 📏 y `BENCHMARKS.md` | Al escribir la sección 6 |
| [`prompts-de-fase.md`](prompts-de-fase.md) | El marco común y los 25 bloques de fase | Al abrir cada chat |
| [`prompts-de-documentos-de-encuadre.md`](prompts-de-documentos-de-encuadre.md) | Los prompts de README, estructura, git, benchmarks e instintos | Al abrir esos chats |
| [`historia-propuesta-1-cordillera.md`](historia-propuesta-1-cordillera.md) | La empresa: personajes, cifras, cronología, deuda técnica | Siempre que el material toque el dominio |

**Orden de autoridad**, cuando dos se contradigan: (1) el `CLAUDE.md` del repositorio,
(2) `alcance-del-proyecto.md`, (3) `propuesta-fases-y-alcance.md`, (4) la guía de estilo,
(5) las plantillas y los formatos, (6) la historia para todo lo narrativo, (7) los entregables ya
escritos, (8) las decisiones del chat actual.

> 🧭 **Si una contradicción aparece al escribir, se arregla en el documento de arriba primero.**
> Parchear la fase y dejar la propuesta desactualizada es cómo empiezan las divergencias que
> nadie detecta hasta la fase doce.

---

## 2. La regla de los chats

**Un chat, un archivo.** Cada fase y cada documento de encuadre se redacta en su propio chat y
produce un único `.md`. Si un chat no produce entregable, o sobra o se salió de alcance.

Lo que se pega al abrir un chat de fase:

1. El **§ Marco común** de `prompts-de-fase.md`, tal cual.
2. El **bloque de la fase** que toca, del mismo archivo.
3. Los documentos del marco, o la instrucción de leerlos del repositorio.

El chat produce el `.md` de la fase, y nada más. Los 📌 Pendientes del final son material de
autoría: de ahí salen las entradas nuevas de `BENCHMARKS.md`, de `INSTINTOS.md` y las decisiones
que haya que subir a la propuesta.

---

## 3. El orden de escritura

**Primero el encuadre**, porque las fases lo enlazan:

1. `README.md`
2. `0-ESTRUCTURA-CURSO.md`
3. `00-convencion-de-git-y-tags.md`

**Después la Fase 00**, que es la que más decide: fija el ambiente, el arnés, el marco de pruebas
y la estructura de `src/`. Con ella nacen `BENCHMARKS.md` e `INSTINTOS.md` en su versión inicial.

**Después, en este orden:**

4. **Fases 01 a 06** (Bloque A). Fijan el modelo de dominio y la voz. Todo lo demás las cita.
5. **Fases 07 a 11** (Bloque B) ⭐. Son el corazón y las que más pueden obligar a retocar las
   anteriores. Escribirlas pronto es barato; escribirlas al final, caro.
6. **Fases 12 a 14** (Bloque C). Dependen del legado y dejan abierta la cuarta columna que
   completa la F18.
7. **Fases 15 a 20** (Bloque D).
8. **Fases 21 a 22** (Bloque E).
9. **Fases 23 y 24** (cierre). La 24 consolida y admite; va al final por definición.

> ⚠️ **La Fase 14 y la Fase 18 están acopladas**: la 14 define la metodología de la comparación
> del escritorio y deja la columna de la web abierta; la 18 la completa. Si se escriben con
> mucha distancia entre ellas, revisa la 14 antes de cerrar la 18.

---

## 4. Qué se hace al cerrar una fase

Antes de dar por bueno el `.md`:

- [ ] Pasar el **checklist de la guía §13** entero. No es un trámite: es donde se atrapan el
      código con acento de Java, el servicio de nube sin costo y el miniproyecto mal calibrado.
- [ ] Verificar la **prueba de calibración del miniproyecto** (`formato-de-miniproyectos.md` §3):
      si se resuelve copiando la sección 5, la fase se reescribe. Es bloqueante.
- [ ] Verificar el **checklist de la medición** (`formato-de-mediciones.md` §6) y agregar la
      entrada a `BENCHMARKS.md`.
- [ ] Agregar el reflejo 🪞 de la fase a `INSTINTOS.md`.
- [ ] Revisar que **cada 💸 declarado tenga fase de cobro**, y que las deudas que esta fase cobra
      estén efectivamente cobradas.
- [ ] Revisar que **el proyecto declarado en el encabezado avanzó de verdad**, con al menos un
      ítem verificable en el checklist de la sección 2.
- [ ] Subir a la propuesta cualquier decisión que afecte a otra fase, **antes** de cerrar el chat.

---

## 5. Qué sigue abierto

Las decisiones de `propuesta-fases-y-alcance.md` §10 que **no** llevan 🪦: el rival del duelo
(10.5), si se publican horas (10.6), el alcance del track `cv` (10.7), el inventario de qué se
emula y qué se declara en la nube (10.8), la versión y las cargas de trabajo de Visual Studio
(10.9) y la forma de `BENCHMARKS.md` (10.10).

Ninguna bloquea la escritura del encuadre ni del Bloque A. **La 10.8 y la 10.9 sí bloquean**: la
10.9 a la Fase 00, y la 10.8 a la Fase 16. Se cierran en la propuesta y se escriben en
`alcance-del-proyecto.md` §9 y §10 **antes** de la primera línea de código que las use.

---

## 6. Las tres cosas que más se rompen al escribir

No son reglas nuevas —todas están en la guía— sino las que en la práctica se cuelan:

**Explicarle al lector lo que ya sabe.** Pasa sobre todo en las fases del Bloque D, donde es
tentador introducir HTTP, colas o contenedores desde cero. El lector lleva ocho años con eso.

**Afirmar sin medir.** "Más rápido", "más liviano", "sale más barato" se escriben solos. Cada uno
necesita su número o desaparece el comparativo.

**Modernizar el código heredado de paso.** Un `var` aquí, un `using` allá, un nombre en inglés en
una tabla de 1997. Cada uno de esos es el error que el curso enseña a no cometer, cometido por el
propio curso.
FIN
wc -l como-escribir-el-curso.md; ls

# --- 2026-09-13T00:14:08 · Fix cross-references
python3 - <<'PY'
import io
def sub(p,old,new):
    s=io.open(p,encoding='utf-8').read(); assert old in s,(p,old[:60])
    io.open(p,'w',encoding='utf-8').write(s.replace(old,new,1))

# plantillas: citar formato-de-mediciones
sub('plantillas-de-capitulo.md',
"""{{El número que esta fase produce. Formato fijo, y va también a `BENCHMARKS.md`.}}""",
"""{{El número que esta fase produce. El formato de abajo y las reglas de honestidad están en
`formato-de-mediciones.md`; el arnés es el mismo para todo el curso y se construye en la Fase 00.
La entrada va también a `BENCHMARKS.md`.}}""")

sub('plantillas-de-capitulo.md',
"""> ⚖️ **Veredicto.** {{Qué gana, dónde pierde, y a partir de qué umbral cambia la respuesta.}}""",
"""> ⚖️ **Veredicto.** {{Qué gana, dónde pierde, y **a partir de qué umbral cambia la respuesta**.
> El umbral es obligatorio: un veredicto sin él es una preferencia — `formato-de-mediciones.md`
> §3.}}""")

# guia §8: mencionar formato-de-mediciones en la sección 6
sub('guia-de-estilo-y-convenciones.md',
"""6. **📏 Medición** — el número que esta fase produce, con sus condiciones, su competidor y su
   veredicto. Las fases que no midan nada lo dicen en una línea y explican por qué.""",
"""6. **📏 Medición** — el número que esta fase produce, con sus condiciones, su competidor y su
   veredicto. Formato y reglas de honestidad en
   [`formato-de-mediciones.md`](formato-de-mediciones.md). Las fases que no midan nada lo dicen
   en una línea y explican por qué.""")

# guia §12 fuentes de verdad: añadir formato-de-mediciones
sub('guia-de-estilo-y-convenciones.md',
"""(5) `plantillas-de-capitulo.md` y `formato-de-miniproyectos.md`,""",
"""(5) `plantillas-de-capitulo.md`, `formato-de-miniproyectos.md` y `formato-de-mediciones.md`,""")

# alcance §7: citar formato-de-mediciones
sub('alcance-del-proyecto.md',
"""- Las **mediciones**: todo "es más rápido", "arranca antes", "consume menos" o "cuesta menos"
  se sostiene con un número producido por el arnés del curso, contra un competidor que alguien
  defendería en una revisión de código. Viven en `BENCHMARKS.md`.""",
"""- Las **mediciones**: todo "es más rápido", "arranca antes", "consume menos" o "cuesta menos"
  se sostiene con un número producido por el arnés del curso, contra un competidor que alguien
  defendería en una revisión de código. El formato y las reglas de honestidad están en
  [`formato-de-mediciones.md`](formato-de-mediciones.md); los resultados, en `BENCHMARKS.md`.""")

# propuesta §12: apuntar al manual
sub('propuesta-fases-y-alcance.md',
"""3. Rellenar los prompts de fase en `prompts-de-fase.md`, que hoy está deliberadamente vacío.""",
"""3. Los prompts de las veinticinco fases ya están escritos en
   [`prompts-de-fase.md`](prompts-de-fase.md), y los del encuadre en
   [`prompts-de-documentos-de-encuadre.md`](prompts-de-documentos-de-encuadre.md). El orden de
   escritura y el procedimiento de cierre están en
   [`como-escribir-el-curso.md`](como-escribir-el-curso.md).""")
print("ok")
PY
sed -n '/## 12. 🚦 Siguiente paso/,$p' propuesta-fases-y-alcance.md

# --- 2026-09-13T00:14:21 · Rewrite next-steps section
python3 - <<'PY'
import io
P='propuesta-fases-y-alcance.md'
s=io.open(P,encoding='utf-8').read()
old=s[s.index("## 12. 🚦 Siguiente paso"):]
new="""## 12. 🚦 Siguiente paso

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
"""
io.open(P,'w',encoding='utf-8').write(s.replace(old,new))
print("ok")
PY
grep -rn "prompts-fases-00-24" *.md || echo "sin referencias rotas"; echo "=== inventario ==="; wc -l *.md | sort -n

# --- 2026-09-13T00:14:28 · Verify links and phase prompt count
grep -oE "\[\`?[^]]+\`?\]\(([a-z0-9./-]+\.md)\)" *.md | sed 's/.*(\(.*\))/\1/' | sort -u | while read f; do [ -f "$f" ] || [ -f "../$f" ] || echo "ROTO: $f"; done; echo "--- enlaces verificados ---"; grep -c "Fase 0[0-9]\|Fase 1[0-9]\|Fase 2[0-4]" prompts-de-fase.md; grep -c "^## # Fase" prompts-de-fase.md

# --- 2026-09-13T00:45:21 · Read sibling prompts README
cat /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/prompts/README.md

# --- 2026-09-13T00:46:29 · Close all open decisions
python3 - <<'PY'
import io
P='propuesta-fases-y-alcance.md'
s=io.open(P,encoding='utf-8').read()
def sub(old,new):
    global s
    assert old in s, old[:80]
    s=s.replace(old,new,1)

# ---------- 10.5 ----------
sub("""**10.5 · ¿El duelo contra qué, exactamente?** La fase 23 implementa CatalogAPI dos veces.
*Recomendación: Spring Boot 3, que es el stack que el lector realmente tiene*, midiendo
rendimiento, arranque en frío, memoria, líneas de código, costo mensual al volumen de
Cordillera y facilidad de contratación en el mercado del lector. Meter también Go o Node diluye
la comparación y alarga la fase.""",
"""**10.5 · 🪦 Cerrada: el duelo es contra Spring Boot 3, y solo contra él.** Es el stack que el
lector realmente tiene y el competidor más parejo que existe: misma generación, mismo perfil de
empresa, equipos intercambiables. Las columnas son rendimiento, arranque en frío, memoria,
líneas de código, costo mensual al volumen de Cordillera y facilidad de contratar a quien lo
mantenga. **No entra un tercer competidor**: Go o Node diluyen la comparación, alargan la fase y
no responden a ninguna pregunta que Cordillera se esté haciendo.""")

# ---------- 10.6 ----------
sub("""**10.6 · ¿Cuánto pesa cada fase, y se publican horas?** Los cursos hermanos de Angular reparten
horas; el de Python decidió no publicarlas. Aquí el miniproyecto domina el tiempo real.
*Recomendación: no publicar horas por fase; publicar la estimación del miniproyecto (2-5 h) y
nada más.* Una tabla de horas que nadie puede cumplir desprestigia al resto del documento.""",
"""**10.6 · 🪦 Cerrada: no se publican horas por fase.** Se publica **la estimación del
miniproyecto, de dos a cinco horas**, y nada más. El miniproyecto domina el tiempo real y las
horas de lectura engañan; una tabla de horas que nadie puede cumplir desprestigia al resto del
material. Es divergencia declarada frente a los cursos de Angular del repositorio, que sí las
reparten.""")

# ---------- 10.7 ----------
sub("""*Recomendación: no moverlo entero, pero reservar una sección dentro de la fase 10* —la del
*strangler fig*— donde la pieza que se envuelve sea Convivir, el sistema Java heredado de la
adquisición de 2004. Así el camino base cubre la habilidad y el track profundiza.""",
"""🪦 **Cerrada: no se mueve entero, pero el camino base cubre la habilidad.** La **fase 10** lleva
una sección donde la pieza que se envuelve es **Convivir**, el sistema Java que llegó con la
adquisición de la Universitaria del Bajío en 2004 y que nadie va a apagar. El track `cv`
profundiza —"el Fox" de Lima, el protocolo de archivo plano de los viernes, el ciclo de vida de
un sistema que sobrevive a su equipo— y sigue siendo opcional.""")

# ---------- 10.8 ----------
sub("""**10.8 · ¿Cuánta nube, y en qué fase se emula qué?** La regla de "sin suscripción de pago" está
cerrada, pero falta el inventario: qué servicio se ejecuta con emulador local (Azurite para
Blob y colas, SQL Server en contenedor), cuál se sustituye por un equivalente local declarado
(la mensajería, la identidad) y cuál solo se estudia con precios publicados (Durable Functions,
Azure AI Search). *Recomendación: cerrar ese inventario como una tabla en
`alcance-del-proyecto.md` §10 antes de escribir la fase 16*, que es la primera que lo necesita.""",
"""**10.8 · 🪦 Cerrada: el inventario está en `alcance-del-proyecto.md` §10.1.** Cada servicio de
nube que el curso toca queda clasificado en tres categorías —**ejecutable en local**,
**sustituido por un equivalente declarado** o **solo estudiado con precio publicado**— y ninguna
fase improvisa una cuarta. Los precios publicados se citan con **fecha y región**, y la región
por defecto del curso es **East US 2**, con la advertencia de que una región latinoamericana
cambia los números y el curso lo dice donde importa.""")

# ---------- 10.9 ----------
sub("""**10.9 · ¿Qué versión exacta de Visual Studio Community, y con qué cargas de trabajo?** Falta
fijarla, junto con el patch exacto del SDK .NET 10. Hay un detalle que sí importa y que conviene
decidir con la versión: **una sola instalación tiene que poder abrir el legado y lo nuevo** —el
diseñador de WinForms sobre .NET Framework, el de WPF, los proyectos SDK de .NET 10 y las
herramientas de datos de SQL Server—, y eso se traduce en tres o cuatro cargas de trabajo
concretas que la Fase 00 nombra y justifica una por una. *Recomendación: fijar versión y cargas
verificándolas contra las notas de versión oficiales en el momento de escribir la Fase 00, y
escribirlas en `alcance-del-proyecto.md` §9 antes de la primera línea de código.* Ninguna se da
por buena de memoria.""",
"""**10.9 · 🪦 Cerrada: Visual Studio Community 2026, con cuatro cargas de trabajo.** El criterio
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
> da por buena de memoria: es la regla del repositorio y no tiene excepción.""")

# ---------- 10.10 ----------
sub("""**10.10 · ¿El curso escribe `BENCHMARKS.md` desde la Fase 00 o al final?** Cada fase produce una
medición y el repositorio pide un archivo consolidado. *Recomendación: desde la Fase 00, con el
arnés*, y cada fase agrega su entrada al cerrarse. Dejarlo para el final garantiza que las
condiciones de las primeras mediciones se pierdan.""",
"""**10.10 · 🪦 Cerrada: `BENCHMARKS.md` e `INSTINTOS.md` nacen con la Fase 00.** Vacíos de
contenido pero completos de forma, y cada fase agrega su entrada al cerrarse. Dejarlos para el
final garantiza que las condiciones de las primeras mediciones se pierdan, y una medición sin
sus condiciones es una anécdota con decimales. El formato está en `formato-de-mediciones.md` §5.""")

sub("""## 10. 🚦 Las decisiones abiertas

Esto es lo que hay que acordar. Cada una lleva una recomendación; **ninguna está tomada**.""",
"""## 10. 🚦 Las decisiones, todas cerradas

🪦 **No queda ninguna decisión abierta.** Las diez se resolvieron y quedan aquí con su porqué,
porque la razón de una decisión vale más que la decisión. Lo único que sigue pendiente es
**verificar versiones exactas contra las notas oficiales al escribir la Fase 00** (§10.9), que no
es una decisión sino un trámite que no se hace de memoria.""")
io.open(P,'w',encoding='utf-8').write(s)
print("ok")
PY
grep -n "^\*\*10\." propuesta-fases-y-alcance.md

# --- 2026-09-13T00:46:53 · Add cloud inventory to scope
python3 - <<'PY'
import io
def sub(p,old,new):
    s=io.open(p,encoding='utf-8').read(); assert old in s,(p,old[:70])
    io.open(p,'w',encoding='utf-8').write(s.replace(old,new,1))

# ---------- alcance §10.1: inventario de nube ----------
sub('alcance-del-proyecto.md',
"""📝 Que .NET 10 corra en Linux y en contenedor sigue siendo cierto y el curso lo dice donde
importa —es uno de los argumentos que desarman el "esto hay que reescribirlo en otra cosa" de
la historia §6—. Pero el **curso** se toma en Windows.""",
"""📝 Que .NET 10 corra en Linux y en contenedor sigue siendo cierto y el curso lo dice donde
importa —es uno de los argumentos que desarman el "esto hay que reescribirlo en otra cosa" de
la historia §6—. Pero el **curso** se toma en Windows.

### 10.1 Qué se ejecuta, qué se sustituye y qué solo se estudia

Inventario cerrado (`propuesta-fases-y-alcance.md` §10.8). **Ninguna fase improvisa una cuarta
categoría**, y ninguna pide una tarjeta de crédito.

| Servicio | Categoría | Cómo | Fase |
|---|---|---|---|
| SQL Server | ▶️ **Ejecutable** | Contenedor, edición Developer | F07 en adelante |
| Blob Storage | ▶️ Ejecutable | Azurite en contenedor | F17 |
| Colas y tablas de Storage | ▶️ Ejecutable | Azurite | F17 |
| Azure Functions y Durable Functions | ▶️ Ejecutable | Core Tools sobre Azurite | F17 · F20 |
| Telemetría | ▶️ Ejecutable | OpenTelemetry contra un colector local en contenedor | F19 |
| Service Bus | 🔄 **Sustituido** | El emulador oficial en contenedor si está disponible; si no, la cola en tabla de SQL Server —que es además el competidor por defecto de la F17— | F17 |
| Entra ID | 🔄 Sustituido | Un proveedor OIDC en contenedor para desarrollo. El modelo, los grupos y el costo de Entra ID se estudian | F16 |
| Key Vault | 🔄 Sustituido | `dotnet user-secrets` y variables de entorno, con **una sola ruta de código** hacia el gestor real | F16 |
| Azure OpenAI | 🔄 Sustituido | Un modelo servido en local para que el flujo y la evaluación corran de verdad, **declarando** que las cifras de calidad con un modelo de frontera serán otras | F22 |
| App Service · Container Apps · AKS | 💲 **Solo estudiado** | Precio publicado, con fecha y región | F20 |
| Azure AI Search | 💲 Solo estudiado | Precio publicado. Los competidores ejecutables son el texto completo y la búsqueda vectorial del propio SQL Server | F22 |

> 🧭 **La región por defecto del curso es East US 2**, y toda cifra de costo la nombra junto con
> la fecha de consulta. Una región latinoamericana cambia los números, y el curso lo dice donde
> eso altere una decisión — que es justo lo que le pasa a Cordillera, con oficinas en tres países.

> ⚠️ Lo que cae en 💲 **se marca como no ejecutado** en su medición
> (`formato-de-mediciones.md` §2.5). Un número de nube sin fecha, región y fuente contamina las
> veinticinco fases.""")

sub('alcance-del-proyecto.md',
"""| Sistema operativo | **Windows 11**, con WSL 2 para los contenedores | Fase 00 · todo el curso |""",
"""| Sistema operativo | **Windows 11**, con WSL 2 para los contenedores | Fase 00 · todo el curso |
| IDE, versión fijada | **Visual Studio Community 2026**, cuatro cargas de trabajo | Fase 00 |""")

sub('alcance-del-proyecto.md',
"""| IDE principal | **Visual Studio Community** (edición y versión por cerrar) | Fase 00 |""",
"""| IDE principal | **Visual Studio Community 2026** | Fase 00 |""")

sub('alcance-del-proyecto.md',
"""| Pruebas | por cerrar: xUnit o MSTest, más Testcontainers | Fase de pruebas |""",
"""| Pruebas | **xUnit**, **Testcontainers** y **NSubstitute** | Fase 00 · F04 · F05 · F08 |""")
print("ok")
PY
grep -n "IDE, versión fijada\|IDE principal\|Pruebas |" alcance-del-proyecto.md

# --- 2026-09-13T00:47:25 · Add debt ledger and resolve coupling
python3 - <<'PY'
import io
def sub(p,old,new):
    s=io.open(p,encoding='utf-8').read(); assert old in s,(p,old[:70])
    io.open(p,'w',encoding='utf-8').write(s.replace(old,new,1))

# quitar la fila duplicada del IDE
sub('alcance-del-proyecto.md',
"""| IDE, versión fijada | **Visual Studio Community 2026**, cuatro cargas de trabajo | Fase 00 |
""","")

# ---------- propuesta: libro de deudas + acoplamientos ----------
sub('propuesta-fases-y-alcance.md',
"""**El cliente de escritorio no es un proyecto aparte**: es el frente de SIGE, y el Bloque C
decide qué se hace con él.""",
"""**El cliente de escritorio no es un proyecto aparte**: es el frente de SIGE, y el Bloque C
decide qué se hace con él.

### 7.1 💸 El libro de deudas

Cada 💸 declara dónde se paga (guía §7.1), y un 💸 sin destino es un error de escritura. Aquí está
el libro completo, para que ninguna se pierda y para que cada fase sepa qué le toca cobrar.

| Deuda | Nace | Se paga | Qué demuestra al cobrarse |
|---|---|---|---|
| El arnés no aísla el recolector | F00 | **F06** | Que una medición de tiempo sin asignaciones cuenta media historia |
| `Money` es un `decimal` sin moneda | F01 | **F17** | Que el tipo del dominio tiene que llevar dentro lo que el negocio no puede perder |
| Dos `!` que tapan una decisión | F02 | **F09** | Que el borde de datos es el sitio donde la nulabilidad se decide, no se silencia |
| Un `IQueryable` filtrado en memoria | F03 | **F09** | Las filas que viajaron de más, contadas |
| El `finally` escrito a mano | F04 | **F04**, a la vista | Cómo se lee y se cobra un 💸 — es el ejemplo del mecanismo |
| Dos métodos sin `CancellationToken` | F05 | **F17** | Que un proceso que no se puede detener no es reanudable |
| La cadena de conexión en 90 `App.config` | F07 | **F16** | El cobro más antiguo del curso, y el más satisfactorio |
| El acceso a datos con `DataSet` | F07 | **F09** | — |
| La conexión directa del cliente a la base | F07 | **F10** | Que mientras 90 equipos escriban en todo, lo demás es cosmético |
| El runtime 4.8 | F07 | **F11** | — |
| *Golden master* atado a una semilla | F08 | **F10** | Que comparar salidas no es lo mismo que conciliar estados |
| Doble escritura sin conciliación | F10 | **F17** | El outbox, y la divergencia medida |
| `packages.config` convertido a medias | F11 | **nunca** | Que "depende de un proveedor" es una respuesta legítima y hay que saber darla |
| Lógica de negocio en el `Click` | F12 | **F13** | Que MVVM se justifica con las pruebas corriendo, no con un diagrama |
| Lista sin virtualizar | F13 | **F14** | Qué cuesta, con 50.000 filas |
| Catálogo sin paginación | F15 | **F20** | En pesos |
| Cola en tabla en vez de mensajería | F17 | **F20** | En pesos, contra el statu quo que ya funciona |
| Telemetría sin muestreo | F19 | **F20** | En pesos |
| Sin auditoría de quién vio qué | F18 | **F19** | Que la observabilidad la vuelve barata |
| Modelo servido sin versionar | F21 | **nunca** | Que un registro de modelos es otro curso, y decirlo es mejor que fingirlo |
| Sin caché de embeddings | F22 | **F22**, a la vista | La factura de reindexar |

> 🧭 **La F20 cobra tres a la vez** —paginación, cola en tabla y muestreo— y las tres aparecen en
> la misma hoja de costos. **Esa acumulación es deliberada**: las decisiones cómodas de tres fases
> distintas se pagan juntas y en un solo número, que es exactamente lo que le pasó a Cordillera
> en 2020 y lo que nadie se atreve a decir en junta.""")

# acoplamiento F14 ↔ F18
sub('propuesta-fases-y-alcance.md',
"""> ⚖️ El veredicto de este bloque está abierto de verdad y el curso no lo prejuzga. Lo que sí
> está decidido es que se mide antes de opinar.""",
"""> ⚖️ El veredicto de este bloque está abierto de verdad y el curso no lo prejuzga. Lo que sí
> está decidido es que se mide antes de opinar.

**El acoplamiento con la F18, resuelto.** La cuarta opción —la web— nace catorce fases después de
que el bloque de escritorio la necesite, y eso tenía que quedar zanjado antes de escribir nada:

- **La F14 congela la metodología** —los cinco criterios, el módulo medido, las condiciones de
  red— **y publica la tabla con tres columnas llenas y la cuarta declarada pendiente**, no vacía
  ni estimada. El lector cierra el bloque con un veredicto provisional explícito y con la fecha
  en que se completa.
- **La F18 rellena esa columna con la misma metodología, sin rediscutirla**, y **actualiza la
  tabla de la F14**. Es **la única actualización retroactiva permitida en el curso**: cualquier
  otra sería una contradicción entre fases, y ésta está declarada de antemano en los dos sitios.
- Si el veredicto provisional de la F14 cambia al entrar la columna de la web, **la F18 lo dice y
  explica qué lo movió**. Un veredicto que cambia con un dato nuevo no es un error del curso: es
  el curso funcionando.""")
print("ok")
PY
grep -n "### 7.1 💸\|El acoplamiento con la F18" propuesta-fases-y-alcance.md

# --- 2026-09-13T00:47:48 · Update status and operating manual
python3 - <<'PY'
import io
def sub(p,old,new):
    s=io.open(p,encoding='utf-8').read(); assert old in s,(p,old[:70])
    io.open(p,'w',encoding='utf-8').write(s.replace(old,new,1))

# estado del encabezado de la propuesta
sub('propuesta-fases-y-alcance.md',
"""> **Estado: secuencia acordada, detalles abiertos.** La tabla de §4 —veinticinco fases, 00 a
> 24— está **cerrada** y es la numeración vigente; también lo están las decisiones de §2 y la
> forma de cada fase. Lo que sigue abierto son los puntos de §10 que no llevan 🪦, cada uno con
> su recomendación.""",
"""> **Estado: cerrado, listo para escribir.** Las veinticinco fases de §4 son la numeración
> vigente, las diez decisiones de §10 están tomadas, el libro de deudas de §7.1 está cuadrado y
> los dos acoplamientos —el del escritorio con la F18 (§8) y el de las deudas que convergen en la
> F20 (§7.1)— están resueltos por escrito. Lo único pendiente es **verificar versiones exactas
> contra las notas oficiales al escribir la Fase 00**, que es un trámite y no una decisión.""")

# como-escribir-el-curso §5
sub('como-escribir-el-curso.md',
"""## 5. Qué sigue abierto

Las decisiones de `propuesta-fases-y-alcance.md` §10 que **no** llevan 🪦: el rival del duelo
(10.5), si se publican horas (10.6), el alcance del track `cv` (10.7), el inventario de qué se
emula y qué se declara en la nube (10.8), la versión y las cargas de trabajo de Visual Studio
(10.9) y la forma de `BENCHMARKS.md` (10.10).

Ninguna bloquea la escritura del encuadre ni del Bloque A. **La 10.8 y la 10.9 sí bloquean**: la
10.9 a la Fase 00, y la 10.8 a la Fase 16. Se cierran en la propuesta y se escriben en
`alcance-del-proyecto.md` §9 y §10 **antes** de la primera línea de código que las use.""",
"""## 5. Qué sigue abierto: nada, salvo un trámite

Las diez decisiones de `propuesta-fases-y-alcance.md` §10 están cerradas, y los dos acoplamientos
también: el del bloque de escritorio con la F18 está resuelto en §8 de la propuesta, y la
convergencia de deudas en la F20 está cuadrada en el libro de §7.1.

Lo único pendiente **no es una decisión**: al escribir la Fase 00 hay que **verificar contra las
notas de versión oficiales** el patch exacto de Visual Studio Community 2026, del SDK .NET 10, de
xUnit, de Testcontainers y de NSubstitute, y escribirlos en `alcance-del-proyecto.md` §9 antes de
la primera línea que los use. Ninguna versión se da por buena de memoria: es la regla del
repositorio y no tiene excepción.""")

sub('como-escribir-el-curso.md',
"""> ⚠️ **La Fase 14 y la Fase 18 están acopladas**: la 14 define la metodología de la comparación
> del escritorio y deja la columna de la web abierta; la 18 la completa. Si se escriben con
> mucha distancia entre ellas, revisa la 14 antes de cerrar la 18.""",
"""> ⚠️ **La Fase 14 y la Fase 18 están acopladas, y así se resuelve** (propuesta §8): la 14
> congela la metodología y publica su tabla con tres columnas llenas y la cuarta **declarada
> pendiente**; la 18 la rellena con la misma metodología y **actualiza la tabla de la 14**. Es la
> única actualización retroactiva permitida en el curso, y está declarada en los dos sitios.""")

sub('como-escribir-el-curso.md',
"""- [ ] Revisar que **cada 💸 declarado tenga fase de cobro**, y que las deudas que esta fase cobra
      estén efectivamente cobradas.""",
"""- [ ] Revisar el **libro de deudas** (propuesta §7.1): que cada 💸 nuevo esté anotado allí con su
      fase de cobro, y que las deudas que esta fase cobra estén efectivamente cobradas, con el
      `git diff` entre los dos tags citado en el bloque 🏷️.""")
print("ok")
PY
echo ok

# --- 2026-09-13T00:48:26 · Write prompts README
cat > README.md <<'FIN'
# 🧰 `prompts/` — la maquinaria del curso
## C# para desarrolladores Java senior

Este directorio no es material del curso: es **lo que se usa para escribirlo**. El lector nunca
lo abre. Quien escribe una fase lo lee entero antes de teclear la primera línea.

> 🧭 **Estado: listo para escribir.** Las veinticinco fases tienen su alcance detallado y su
> prompt, las diez decisiones de estructura están cerradas, el libro de deudas está cuadrado y los
> dos acoplamientos están resueltos por escrito. Lo que falta es redactar el curso.

---

## 📖 Orden de lectura

Si llegas nuevo a este curso, en este orden y no en otro:

1. **[`alcance-del-proyecto.md`](alcance-del-proyecto.md)** — qué es el curso, para quién, qué
   produce y qué no hace. Incluye las dos reglas de forma que lo definen: **no hay apéndices** y
   **es de Windows, exclusivamente**. §10.1 tiene el inventario de qué se ejecuta, qué se
   sustituye y qué solo se estudia de la nube.
2. **[`propuesta-fases-y-alcance.md`](propuesta-fases-y-alcance.md)** — la estructura. §4 tiene la
   numeración oficial de las 25 fases; **§5 tiene el encargo detallado de cada una**; §7.1 tiene
   el libro de deudas 💸; §10 tiene las diez decisiones cerradas con su porqué.
3. **[`guia-de-estilo-y-convenciones.md`](guia-de-estilo-y-convenciones.md)** — voz, idioma,
   pedagogía, estilo de código, marcadores, la plantilla de 10 secciones, ejercicios, y el
   checklist de cierre.
4. **[`historia-propuesta-1-cordillera.md`](historia-propuesta-1-cordillera.md)** — la empresa del
   curso. Fuente de verdad de todo lo narrativo: personajes, cifras, cronología, reglas de negocio
   y la deuda técnica del sistema, con su fecha.

Y como referencia, cuando toque:

- **[`plantillas-de-capitulo.md`](plantillas-de-capitulo.md)** — el esqueleto de fase, que se
  sigue literal. Es uno solo: no hay plantilla de apéndice porque no hay apéndices.
- **[`formato-de-miniproyectos.md`](formato-de-miniproyectos.md)** — el miniproyecto obligatorio
  de cada fase, cómo se calibra y su prueba bloqueante.
- **[`formato-de-mediciones.md`](formato-de-mediciones.md)** — el arnés, la forma de una medición
  y las cinco reglas de honestidad.
- **[`como-escribir-el-curso.md`](como-escribir-el-curso.md)** — el manual de operación: orden de
  autoridad, orden de escritura y qué se verifica al cerrar cada fase.

---

## 🚀 Cómo abrir una sesión de escritura

**Primero los tres documentos de la raíz del curso**, cada uno en su chat, con el prompt que le
corresponde en
**[`prompts-de-documentos-de-encuadre.md`](prompts-de-documentos-de-encuadre.md)**:

1. `README.md` del curso
2. `0-ESTRUCTURA-CURSO.md`
3. `00-convencion-de-git-y-tags.md`

**Después las fases**, una por chat. El prompt se arma copiando dos cosas de
**[`prompts-de-fase.md`](prompts-de-fase.md)**: el **§ Marco común** y el bloque de esa fase.

El orden de escritura recomendado, y no es el orden de los números:

| Turno | Qué | Por qué |
|---|---|---|
| 1 | Fase **00** | Fija ambiente, arnés, marco de pruebas y estructura de `src/`. Con ella nacen `BENCHMARKS.md` e `INSTINTOS.md` |
| 2 | Fases **01** y **07** | La 01 fija el modelo de dominio que arrastran veintitrés fases; la 07 fija el esquema heredado que arrastran cinco. Equivocarse en los nombres aquí se paga en todas |
| 3 | Fases **08**, **10** y **11** | Las ⭐ del corazón. Son las que más pueden obligar a retocar el Bloque A, y descubrirlo tarde sale caro |
| 4 | Resto del **Bloque A** (02-06) y la **09** | Con el legado ya escrito, se sabe hacia dónde tienen que apuntar |
| 5 | **Bloque C** (12-14) y **Bloque D** (15-20) | En orden: cada proyecto crece sobre el anterior, y la 18 debe cerrar la tabla que la 14 dejó abierta |
| 6 | **21**, **22**, **23** y por último **24** | El cierre necesita todas las mediciones hechas |

> ⚠️ **Antes de escribir la Fase 00**, verifica contra las notas de versión oficiales el patch
> exacto de Visual Studio Community 2026, del SDK .NET 10, de xUnit, de Testcontainers y de
> NSubstitute, y escríbelos en `alcance-del-proyecto.md` §9. Es lo único pendiente del proyecto, y
> no se hace de memoria.

---

## 🗂️ Qué es cada archivo

| Archivo | Qué es | Manda sobre |
|---|---|---|
| `alcance-del-proyecto.md` | Encuadre, versiones, plataforma e inventario de nube | Todo salvo el `CLAUDE.md` del repositorio |
| `propuesta-fases-y-alcance.md` | Estructura, alcance por fase, deudas y decisiones | La guía de estilo y las plantillas |
| `guia-de-estilo-y-convenciones.md` | Voz, código y forma | Las plantillas y los formatos |
| `plantillas-de-capitulo.md` | El esqueleto de fase | — |
| `formato-de-miniproyectos.md` | La sección 7 de cada fase | — |
| `formato-de-mediciones.md` | La sección 6 y `BENCHMARKS.md` | — |
| `historia-propuesta-1-cordillera.md` | La empresa del curso | Todo lo narrativo |
| `prompts-de-documentos-de-encuadre.md` | Los 5 prompts del encuadre | — |
| `prompts-de-fase.md` | El marco común + los 25 prompts | — |
| `como-escribir-el-curso.md` | El procedimiento | — |

**Si al escribir aparece una contradicción, se arregla en el documento de arriba primero.**
Parchear la fase y dejar la propuesta desactualizada es cómo empiezan las divergencias que nadie
detecta hasta la fase doce.

---

## 🧭 Las cinco decisiones que explican todo lo demás

Si solo vas a retener cinco cosas de este directorio antes de escribir, que sean estas:

1. **La pregunta que ordena el curso es *¿esto se migra, se envuelve o se deja quieto?*** Las tres
   respuestas son legítimas y las tres tienen un costo calculable.
2. **El curso construye su propio sistema heredado** —.NET Framework 4.8, `DataSet`,
   procedimientos almacenados, esquema de 1997— para después cortarlo. El Bloque B es el corazón.
3. **Nada de lo que el curso proponga puede apagar el sistema.** Cordillera factura todos los días
   mientras el lector migra, y la vuelta atrás es requisito de diseño, no buena práctica.
4. **Cada fase produce una medición y un miniproyecto**, y avanza al menos un proyecto. Las tres
   cosas se declaran en el encabezado.
5. **Si al final .NET moderno gana todo, el curso está mal escrito.** El veredicto de la F24 está
   obligado a admitir qué no debió migrarse y qué decisiones del propio curso fueron erradas.

---

## ⚠️ Las tres cosas que más se rompen al escribir

1. **Explicar lo que el lector ya sabe.** Es un dev Java senior con ocho años o más. Cada párrafo
   sobre qué es una interfaz, una transacción o HTTP se borra, aunque esté bien escrito.
2. **Modernizar el código heredado de paso.** Un `var` aquí, un `using` allá, un nombre en inglés
   en una tabla de 1997. Cada uno de esos es el error que el curso enseña a no cometer, cometido
   por el propio curso.
3. **Afirmar sin número.** Ni "más rápido", ni "más liviano", ni "sale más barato". Si la medición
   no existe, se escribe la frase sin el comparativo. Y cuando el trabajo toca la base de datos,
   se mide **primero el plan de consulta y después .NET**.
FIN
wc -l README.md; ls

# --- 2026-09-13T00:48:30 · Verify links and leftover open items
grep -oE "\]\(([a-zA-Z0-9._/-]+\.md)\)" *.md | sed 's/.*(\(.*\))/\1/' | sort -u | while read f; do [ -f "$f" ] || echo "ROTO: $f"; done; echo "--- sin enlaces rotos ---"
grep -rn "por cerrar\|Recomendación:\|decisiones abiertas\|sigue abierto" *.md | grep -v historia | head -20

# --- 2026-09-13T00:48:42 · Fix leftover open-decision references
python3 - <<'PY'
import io
def sub(p,old,new):
    s=io.open(p,encoding='utf-8').read(); assert old in s,(p,old[:70])
    io.open(p,'w',encoding='utf-8').write(s.replace(old,new,1))

sub('alcance-del-proyecto.md',
"""Lo que sigue abierto es la **secuencia de fases**, y es exactamente la conversación que abre
[`propuesta-fases-y-alcance.md`](propuesta-fases-y-alcance.md).""",
"""**Y la secuencia de fases también está cerrada**: veinticinco fases, 00 a 24, en
[`propuesta-fases-y-alcance.md`](propuesta-fases-y-alcance.md) §4, con el alcance detallado de
cada una en §5 y las diez decisiones que la produjeron en §10. Lo único pendiente del proyecto es
verificar las versiones exactas contra las notas oficiales al escribir la Fase 00 — un trámite,
no una decisión.""")

sub('prompts-de-documentos-de-encuadre.md',
"""`prompts/propuesta-fases-y-alcance.md`, sin las decisiones abiertas ni el material de autoría.""",
"""`prompts/propuesta-fases-y-alcance.md`, sin el registro de decisiones ni el material de autoría.""")

sub('prompts-de-documentos-de-encuadre.md',
"""**Qué NO lleva:** las decisiones abiertas de §10 de la propuesta, los 📌 de autoría, ni horas por
fase — el curso no las publica (§10.6); publica la estimación del miniproyecto, de dos a cinco
horas.""",
"""**Qué NO lleva:** el registro de decisiones de §10 de la propuesta ni el libro de deudas de
§7.1 —son material de autoría—, ni horas por fase: el curso no las publica (§10.6); publica la
estimación del miniproyecto, de dos a cinco horas.""")
print("ok")
PY
wc -l *.md | sort -n | tail -12

