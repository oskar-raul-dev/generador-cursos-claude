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

- **.NET Framework 4.8 y C# escrito como C# de 2017**: sin LINQ, sin `var`, sin genéricos más allá
  de `List<T>`, sin `async`.
- `DataSet`, `DataTable` y `SqlDataAdapter`; `SqlConnection` abierta en el manejador del botón.
- La lógica de negocio en **procedimientos almacenados**, y lo que no cupo ahí, en el
  `Click` del formulario.
- Cadena de conexión en el `App.config`, la misma para las noventa instalaciones.
- Concatenación de cadenas para armar SQL, incluido el `UNION ALL` de treinta tablas anuales.

> 📝 **Por qué 4.8 y no el 4.5 de la historia.** Los pasantes escribieron sobre 4.5 en 2016, y
> eso no cambia. Wilson subió el destino a 4.8 en 2021 porque una actualización de Windows
> rompió un controlador de impresión fiscal: fue el único cambio que ese código recibió en
> nueve años y no arregló nada de fondo. El curso compila contra 4.8 por eso, y la fase de
> migración dice en voz alta que salir de 4.8 es más fácil que salir de 4.5.

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
primeras son las canónicas y **son obligatorias donde la fase las pida**:

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
   veredicto. Formato y reglas de honestidad en
   [`formato-de-mediciones.md`](formato-de-mediciones.md). Las fases que no midan nada lo dicen
   en una línea y explican por qué.
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

- **Cantidad: la banda de este curso es 20 mínimo, 25 ideal por fase**, y la razón está en el
  presupuesto de horas del lector y no en una costumbre heredada. Una fase se consolida con **el
  miniproyecto**, que pide de dos a cinco horas; los ejercicios lo preparan y lo repasan, no
  compiten con él. Pasar de 25 obliga a rellenar con variaciones del mismo problema —que es lo
  que un dev Java senior abandona en el ejercicio 14— y bajar de 20 deja reflejos de la fase sin
  un ejercicio que los ataque. **Veinticinco es el techo, no la meta:** una fase con 22 bien
  calibrados está mejor que una con 25 donde tres son relleno.
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
[`00-historia-de-cordillera.md`](../00-historia-de-cordillera.md), que es la fuente
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
- **Fuentes de verdad, en este orden:** (1) las instrucciones del proyecto,
  (2) `alcance-del-proyecto.md`, (3) `propuesta-fases-y-alcance.md`, (4) esta
  guía, (5) `plantillas-de-capitulo.md`, `formato-de-miniproyectos.md` y `formato-de-mediciones.md`,
  (6) `00-historia-de-cordillera.md` para todo lo narrativo, (7) entregables ya aprobados
  de fases anteriores, (8) decisiones explícitas del chat actual.
- **Autocontención.** El curso no remite a ningún otro curso como material necesario, ni
  siquiera para nombrarlo. Lo que haga falta se explica aquí o se enlaza a documentación
  oficial; nada del material publicado supone que el lector tenga acceso a otra cosa.

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
- [ ] Referencias con URL completa a la versión correcta, con advertencia cuando no lo sea, y
      sin datos bibliográficos inventados.
- [ ] No contradice ninguna fase anterior, ni en pedagogía ni en nombres.
- [ ] Coherencia de la ficción (§11): nada que afirme sobre SIGE algo que el curso no pueda
      mostrar, cronología respetada, y nadie tratado como villano.
- [ ] Incluye "La señal de que quedó bien" en el cierre.
- [ ] Lleva el bloque 🏷️ del tag al final, con el número correcto (§8.2).
- [ ] **No hay ningún apéndice** ni ninguna promesa de uno.

---

## 14. Excepciones a los lineamientos del repositorio

> 📝 **Sección agregada el 05/10/2026**, en la revisión del curso contra los lineamientos de
> producción del repositorio. Va después del checklist para no renumerar nada (§13 sigue siendo el
> checklist, y así lo citan los demás documentos de `prompts/`). Esta guía se escribió antes de que
> esos lineamientos existieran: lo que aquí se declara ya era la práctica del curso, y desde ahora
> está escrito como decisión.

El `CLAUDE.md` del repositorio da **valores por defecto**, y la guía de un curso los reemplaza cuando
lo declara: la regla general, el valor nuevo y por qué. Lo que esta sección no menciona se hereda tal
cual. **Esto matiza la cascada de §12**: las "instrucciones del proyecto" que encabezan esa lista dan
el valor por defecto, y cada excepción de esta sección manda sobre ellas.

| Regla general del repositorio | Lo que hace este curso | Por qué |
|---|---|---|
| Comentarios dentro del código en inglés | **En español, con tildes**, igual que los mensajes de error y de log (§5) | El comentario es el canal del *porqué*, y el curso piensa en español; los identificadores siguen en inglés |
| 20–30 ejercicios por sección | **20 mínimo, 25 techo** (§9) | El miniproyecto 🧱 consolida la fase; pasar de 25 es relleno |
| Cada ejercicio con solución de referencia o rúbrica | **Sin solución ni rúbrica publicadas.** La evaluación verificable de cada fase es el miniproyecto, con sus criterios de aceptación (`formato-de-miniproyectos.md`); los ejercicios son enunciados accionables (§9) | Decisión del 05/10/2026: 619 soluciones duplicarían el curso, y para este lector el criterio del ejercicio está en su enunciado y en la medición que pide |
| Apéndices `aNN-` | **Ninguno** (alcance §6) | Todo es fase o sección de fase |
| Diagramas a criterio de quien escribe | **Mermaid** para los diagramas; ASCII en `text` solo para árboles de archivos, muestras de datos y salidas (D-12, abajo) | Pedido explícito del autor en la revisión del 05/10/2026 |

### 14.1 D-12 · Diagramas en Mermaid

**Decidido el 05/10/2026 por el autor, en la revisión del curso.** Todo diagrama del curso —flujo,
árbol de decisión, secuencia, categorías con su correspondencia— va en un bloque `mermaid`, con una
frase antes que diga qué mirar en él. Quedan en bloque `text` los árboles de archivos, las muestras de
datos (CSV, ancho fijo), las salidas de terminal y las listas con formato, que no son diagramas.

La revisión convirtió los dos que había: el árbol de decisión de la fase 24 (§5.1) y las tres
categorías de APIs de la fase 11 (§5.2). Las demás piezas en `text` se revisaron y se quedan como
están, por ser de las clases de arriba.

### 14.2 Lo que el curso no tiene, y por qué

- **Plan de producción:** el curso se escribió antes de que los lineamientos lo pidieran y está
  cerrado; no se reconstruye.
- **Diccionario de términos y contrato de nombres** con esos nombres de archivo: hacen ese papel
  §5.2 de esta guía (el diccionario del dominio) y `congelamiento-de-nombres.md` (los nombres
  técnicos congelados). No se renombran, por el bloqueo de contenido.
- **Verificador:** `prompts/verificar-corpus.py`, subclase del perfil `courses-ia` de
  `prompts/verificador_base.py`, con los callouts y marcadores de §7. Se corre desde la raíz del
  curso con `python3 prompts/verificar-corpus.py`.
