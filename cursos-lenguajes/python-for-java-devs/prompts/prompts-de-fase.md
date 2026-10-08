# 📍 Prompts de fase
## Python para desarrolladores Java senior

> ✅ **Estado: el camino base está escrito.** Las 18 fases (00–17), `BENCHMARKS.md` e
> `INSTINTOS.md` están publicados en la raíz del curso. Este documento pasa de ser **encargo** a
> ser **registro de lo que se decidió**: sigue mandando sobre cualquier revisión del camino base y
> sobre el material a la carta, pero ya no describe trabajo pendiente.
>
> **Para qué sirve todavía:** para revisar una fase, para reescribir una que quedó floja, y como
> modelo del prompt que va a necesitar el material **a la carta** — que es más ligero y tiene su
> propio encuadre en `propuestas-temas-opcionales.md`.

**Un chat, un archivo.** Cada fase se redacta en su propio chat y produce un único `.md`. Si un
chat no produce entregable, o sobra o se salió de alcance.

**Cómo se usa este documento:** se copia el **§ Marco común** y, debajo, el bloque de la fase que
toca. Los dos juntos son el prompt completo.

> 🧭 **Por qué los bloques de fase son cortos.** El alcance detallado de cada fase —qué entra, qué
> no, el reflejo 🪞, la medición 📏, el miniproyecto 🧱 y su deuda 💸— ya está escrito en
> `prompts/propuesta-fases-y-alcance.md` §5, que es la fuente de verdad. Duplicarlo aquí
> garantizaría que algún día los dos documentos se contradigan. Lo que agrega cada bloque es lo
> que allí no está: **qué se decide en ese chat, con qué hay que tener cuidado, y qué le entrega
> a la fase siguiente.**

---

## § Marco común

*Se copia tal cual al inicio de cada chat de fase.*

````markdown
Este es un chat del curso *Python para desarrolladores Java senior*. Produce **un solo archivo
`.md`**, el de su fase, y nada más.

## Fuentes de verdad, en este orden

1. `prompts/alcance-del-proyecto.md` — qué es el curso y qué no. **Es el techo: el curso es
   autocontenido y no hereda reglas de ningún archivo de fuera de esta carpeta (§0).**
2. `prompts/propuesta-fases-y-alcance.md` — **§5 tiene el alcance detallado de esta fase y se
   sigue literal**; §4 tiene la numeración oficial, que no se cambia.
3. `prompts/guia-de-estilo-y-convenciones.md` — voz, código, marcadores, plantilla, ejercicios.
4. `prompts/plantillas-de-capitulo.md` — las 10 secciones, en orden, sin extras.
5. `prompts/formato-de-miniproyectos.md` — el miniproyecto y su prueba de calibración.
6. `prompts/formato-de-mediciones.md` — el arnés y la forma de la medición.
7. `00-historia-de-aurea.md` —en la **raíz del curso**, no en `prompts/`— todo lo narrativo:
   personajes, cifras, cronología, reglas de negocio.
8. Los entregables de las fases anteriores.
9. Las decisiones explícitas de este chat.

`prompts/propuestas-fases-base-ia-datos.md` y `prompts/propuestas-temas-opcionales.md` son
material exploratorio de los tracks complementarios y opcionales: alimentan la discusión y
**pierden contra las fuentes de arriba** en cualquier contradicción. La única excepción es la §0
del primero, que sí manda sobre nombres y forma de los complementos `ia` y `ds`.

## Las siete reglas que más se rompen

- **No expliques lo que un dev Java senior ya sabe.** Ni qué es una excepción, ni un mapa, ni
  HTTP, ni una transacción. Cada párrafo que lo haga se borra, aunque esté bien escrito.
- **Código en inglés, comentarios y docstrings en español con tildes.** También los mensajes de
  error y de log. Sin excepciones.
- **Escribe en el registro de esta fase.** Bloque A: un archivo, stdlib pura, cero dependencias,
  sin clases decorativas, sin capas. Bloques B y C: layout `src/`, tipado estricto, pruebas.
  Escribir una aplicación en el Bloque A es el error que el curso enseña a no cometer, y no se
  comete en el propio material.
- **Cada analogía con Java declara dónde se rompe.** Una analogía sin su límite deja al lector
  confiado en un modelo mental que le va a fallar en producción.
- **Ninguna afirmación comparativa sin número.** Si la medición no existe, se escribe la frase sin
  el comparativo o se escribe la medición. El competidor tiene que ser una implementación que
  alguien defendería en una revisión de código.
- **El miniproyecto no puede resolverse copiando la sección 5.** Es la prueba de calibración
  literal de `formato-de-miniproyectos.md` §3, y es bloqueante: una fase que no la pasa se
  reescribe.
- **No hay apéndices.** Si aparece material que "sería un buen apéndice", los destinos legítimos
  son tres: sección de esta fase, fase propia, o 📌 con su razón escrita.

## Coherencia de la ficción

La empresa es **Áurea**, red odontológica de diez sedes, y el curso construye su software. Si
afirmas que algo está así en Áurea, tiene que poder mostrarse en alguna fase. La cronología es
fija y **la frontera de la historia clínica no se cruza**: ningún dato clínico identificable sale
hacia un servicio externo, en ningún ejercicio ni miniproyecto. Guía §11.

## Cierre

La fase termina con el bloque 🏷️ de forma fija (guía §8.1), que pide `git tag -a fase-NN`, el tag
`mini-NN` con el número de la medición en su mensaje, y enlaza `00-convencion-de-git-y-tags.md`
**sin reexplicarlo**. Después, fuera de lo que lee el estudiante, van los 📌 Pendientes.
````

---

# Bloque A · el registro *script*

## # Fase 00

````markdown
Fase **00 — 🛠️ Ambiente, editores y el mapa del ecosistema** · archivo `00-instalacion-ambiente-editores-y-ecosistema.md`
Bloque A · Registro: — · Depende de: ninguna · Habilita: Fase 01 · Proyecto: —

Alcance literal: `propuesta-fases-y-alcance.md` §5, bloque de la Fase 00.

**Lo propio de este chat:**
- Es la fase que abre el curso: fija la voz, el nivel de condescendencia cero, y el pacto de que
  no se explica lo sabido. Lo que se permita aquí se va a repetir dieciocho veces.
- **Las tres plataformas van en el cuerpo**, sin nota al pie: Windows 11, Linux amd64 y macOS
  Apple Silicon. Donde una instrucción difiera, van las tres, en ese orden.
- Deja **plantadas y sin resolver** las dos limitaciones que la Fase 07 cobra: `pip freeze` no es
  un lockfile, y `pip` no te da un intérprete. Se nombran; no se resuelven.
- Enuncia la regla que sostiene el Bloque A: *hasta la Fase 07 no instalas nada.*
- Enlaza `00-convencion-de-git-y-tags.md`, que ya existe, y crea el repositorio del curso.

**Decide y déjalo escrito:** las cuatro extensiones exactas de VS Code, y la versión de Python con
su patch, que va a `alcance-del-proyecto.md` §9 antes de usarse.

**Cuidado con:** convertir esto en un manual de instalación. Es la primera lección de criterio;
si al leerla no hay ninguna decisión, está mal escrita.
````

## # Fase 01

````markdown
Fase **01 — 🧬 El modelo de datos** · archivo `01-modelo-de-datos.md`
Bloque A · Registro: script · Depende de: 00 · Habilita: 02 · Proyecto: **nace el CLI**

Alcance literal: `propuesta-fases-y-alcance.md` §5, bloque de la Fase 01.

**Lo propio de este chat:**
- **Nace el proyecto 1**, el CLI de Patricia, como un archivo suelto de unas cuarenta líneas. Su
  forma inicial la fija esta fase y la arrastran seis fases más: elígela con cuidado y déjala
  escrita (nombre de archivo, funciones, punto de entrada).
- **Estrena el mecanismo de deuda 💸 del curso.** El CLI lee con `open` y `split(",")`,
  deliberadamente mal, y la deuda declara su destino: **se paga en la Fase 06**. Escríbela
  visible: es el ejemplo con el que el lector aprende a leer un 💸.
- El 🪞 tiene dos mitades y las dos hay que escribirlas: `is` contra `==`, y "copio la lista para
  no modificar la original".

**Cuidado con:** meter clases. Esta fase no las tiene y la 03 las introduce; una `class` aquí
rompe la progresión del registro.
````

## # Fase 02

````markdown
Fase **02 ⭐ — 🔁 Secuencias perezosas** · archivo `02-secuencias-perezosas.md`
Bloque A · Registro: script · Depende de: 01 · Habilita: 03 · Proyecto: CLI

Alcance literal: `propuesta-fases-y-alcance.md` §5, bloque de la Fase 02.

**Lo propio de este chat:**
- **Aquí se construye el arnés de medición del curso**, con stdlib pura, y todas las fases
  posteriores lo amplían sin reemplazarlo. Sigue `formato-de-mediciones.md` §1: cronómetro
  monótono con repeticiones y percentiles, pico de memoria con `tracemalloc`, y declaración del
  entorno. Que sea pequeño: un arnés que hay que aprender a usar deja de usarse.
- Es fase ⭐: el hábito que ataca es el que más caro sale en Python.
- El archivo de citas del trimestre —unas 500.000 filas— se genera con un script del propio curso,
  con semilla fija. Escríbelo aquí y reutilízalo en las fases 06, 14, 15 y 16.

**Cuidado con:** enseñar `itertools` entero. Entran los seis o siete que se usan de verdad; el
resto se enlaza.
````

## # Fase 03

````markdown
Fase **03 — 🎩 Python sin ceremonia** · archivo `03-python-sin-ceremonia.md`
Bloque A · Registro: script · Depende de: 02 · Habilita: 04 · Proyecto: CLI

Alcance literal: `propuesta-fases-y-alcance.md` §5, bloque de la Fase 03.

**Lo propio de este chat, y es una fase con condiciones:**
- **Es la fase más densa del curso**, y fusiona funciones y objetos a propósito porque atacan el
  mismo reflejo: la ceremonia. Se escribe con **un solo 🪞 compartido**, no con dos, y con un
  miniproyecto que ataca el reflejo conjunto.
- **Si al redactarla no cabe, la fusión se deshace y se renumera el curso.** No se recorta el
  contenido para que quepa. Si llegas a esa conclusión, dilo en los 📌 y para: es una decisión de
  estructura, no de redacción.
- Metaclases y descriptores se nombran y se cierran en una línea cada uno. No son de este curso.

**Cuidado con:** el contraejemplo. Cada patrón pythónico va con la versión que el lector habría
escrito, lado a lado — sin condescendencia, porque esa versión no está mal en Java.
````

## # Fase 04

````markdown
Fase **04 — 💥 Errores y recursos** · archivo `04-errores-y-recursos.md`
Bloque A · Registro: script · Depende de: 03 · Habilita: 05 · Proyecto: CLI

Alcance literal: `propuesta-fases-y-alcance.md` §5, bloque de la Fase 04.

**Lo propio de este chat:**
- El 🩻 *"esto sí funciona igual"* es importante en esta fase y conviene escribirlo con ganas: el
  lector lleva once años diseñando jerarquías de excepciones y esa habilidad **se transfiere
  entera**. Lo que cambia es el contrato, no el diseño.
- `ExceptionGroup` y `except*` son el vehículo del miniproyecto, así que van con ejemplo completo
  y no de pasada.

**Cuidado con:** presentar EAFP como dogma. Tiene un costo medible y la fase lo mide; hay casos
donde comprobar antes gana, y decirlo es lo que hace creíble el resto.
````

## # Fase 05

````markdown
Fase **05 ⭐ — 🐚 El shell con esteroides** · archivo `05-shell-con-esteroides.md`
Bloque A · Registro: script · Depende de: 04 · Habilita: 06 · Proyecto: CLI

Alcance literal: `propuesta-fases-y-alcance.md` §5, bloque de la Fase 05.

**Lo propio de este chat:**
- Es la fase que **demuestra la tesis del Bloque A**: la stdlib es el reemplazo del shell. Si al
  terminarla el lector no ha cambiado de opinión sobre cuánto viene en la caja, la fase falló.
- El binario firmador del miniproyecto es ficción del curso: **escribe también el script que lo
  simula**, con sus rarezas —mezcla `stdout` y `stderr`, un "éxito" con código distinto de cero,
  y un caso que se cuelga—. Sin ese simulador el miniproyecto no se puede hacer.
- `shell=True` se nombra, se muestra el agujero, y queda prohibido en el resto del curso.

**Cuidado con:** las rutas de Windows. Media fase se cae si los ejemplos asumen barras y `/tmp`.
````

## # Fase 06

````markdown
Fase **06 — 📦 Formatos en la caja** · archivo `06-formatos-en-la-caja.md`
Bloque A · Registro: script · Depende de: 05 · Habilita: 07 · Proyecto: CLI

Alcance literal: `propuesta-fases-y-alcance.md` §5, bloque de la Fase 06.

**Lo propio de este chat:**
- **Aquí se paga la deuda 💸 de la Fase 01**, y la fase lo muestra como factura:
  `git diff fase-01 fase-06 -- <el archivo del CLI>`. Es la primera deuda cobrada del curso y
  enseña a leer el mecanismo tanto como a usar `csv`.
- Cierra el Bloque A. Conviene un párrafo de balance: qué se construyó sin instalar nada, y cuál
  es la señal de que eso ya no alcanza — que es la puerta de la Fase 07.
- El encoding no es un detalle: el `latin-1` del export de Odontovía y el BOM de Excel son datos
  del dominio y tienen que estar en los archivos de ejemplo.

**Cuidado con:** convertir `sqlite3` en una fase de bases de datos. Es almacén local del script;
lo demás es la Fase 11.
````

---

# Bloque B · la frontera

## # Fase 07

````markdown
Fase **07 ⭐ — 🚪 Cuándo deja de ser un script** · archivo `07-cuando-deja-de-ser-un-script.md`
Bloque B · Registro: script → herramienta · Depende de: 06 · Habilita: 08 · Proyecto: **el CLI migra**

Alcance literal: `propuesta-fases-y-alcance.md` §5, bloque de la Fase 07, **incluida su tabla de
gestores y su ⚖️ veredicto, que se copian con su intención**.

**Lo propio de este chat, y es la fase de la tesis:**
- **Escríbela antes que cualquier fase del Bloque C.** Es la que más puede obligar a reescribir
  el Bloque A, y descubrirlo después de escribir ocho fases más sale caro.
- El refactor del CLI es **archivo por archivo, sin empezar de cero**. Si la fase termina con un
  proyecto nuevo en vez de con el de las seis fases anteriores, contradice su propia lección.
- **El arco de gestores va medido, no narrado.** `pip`+`pip-tools`, `uv` y Miniforge sobre el
  mismo encargo, con la columna que decide: cuántos pasos tiene que dar Patricia.
- El veredicto se escribe sin rodeos: **para este stack conda no hace falta**, su modelo es el
  correcto cuando el paquete no es Python, y eso llega en el track de datos. El gestor del curso
  de aquí en adelante es **`uv`**.
- Donde el curso use conda, usa **Miniforge con `conda-forge`**. Los canales por defecto de
  Anaconda no entran al curso, y se dice en una línea por qué.

**Decide y déjalo escrito:** la versión exacta de `uv` **y la fecha en que se verificó**, que van
a `alcance-del-proyecto.md` §9 antes de usarse. Es herramienta joven y el curso no finge lo
contrario.

**Cuidado con:** volverse un tutorial de empaquetado. La lección es *reconocer que cruzó la
línea*; las herramientas son el vehículo.
````

## # Fase 08

````markdown
Fase **08 — 🔎 El contrato del código** · archivo `08-el-contrato-del-codigo.md`
Bloque B · Registro: herramienta · Depende de: 07 · Habilita: 09 · Proyecto: CLI

Alcance literal: `propuesta-fases-y-alcance.md` §5, bloque de la Fase 08.

**Lo propio de este chat:**
- Es una fusión de tipado y pruebas, y se sostiene porque el miniproyecto es uno solo: blindar el
  motor de comisiones de la Fase 03. Si al escribirla las dos mitades no se tocan, la fusión no
  estaba justificada — dilo en los 📌.
- **La medición es contar errores reales** al activar el verificador sobre el código que el propio
  lector escribió en el Bloque A. Es la más convincente del curso precisamente por eso: no se
  puede discutir con un benchmark ajeno.
- La prueba basada en propiedades verifica el invariante del dominio —lo repartido suma
  exactamente lo cobrado—, y encuentra sola el `float` donde debía ir `Decimal`.

**Cuidado con:** vender el tipado como el compilador de Java. La 📝 honesta de la guía §6.5 es
obligatoria aquí: no hay garantía en tiempo de ejecución y las bibliotecas pueden mentirte.
````

## # Fase 09

````markdown
Fase **09 ⭐ — 🎁 Entregarle la herramienta a Patricia** · archivo `09-distribucion.md`
Bloque B · Registro: herramienta · Depende de: 08 · Habilita: 10 · Proyecto: CLI

Alcance literal: `propuesta-fases-y-alcance.md` §5, bloque de la Fase 09.

**Lo propio de este chat:**
- **Es la fase que no existiría en un curso de Go**, y conviene que se note: Go entrega un binario
  y se acaba la conversación. Que el lector entienda que aquí no hay respuesta única es media
  fase.
- Cierra el Bloque B y el arco del proyecto 1: el CLI nació como archivo en la 01 y termina
  instalado en la máquina de otra persona.
- **El miniproyecto se evalúa por la justificación, no por el empaquetado.** La opción
  técnicamente mejor y la correcta para Patricia no son la misma, y esa tensión es la lección.
- Publicar en un índice de paquetes **no entra**: es del track `pk`. Se dice en la §3.

**Cuidado con:** el ejecutable congelado. Tiene costos reales —tamaño, antivirus, tiempo de
arranque— y la fase los mide en vez de recomendarlo por comodidad.
````

---

# Bloque C · el registro *aplicación*

## # Fase 10

````markdown
Fase **10 — ⚡ FastAPI y la validación en el borde** · archivo `10-fastapi.md`
Bloque C · Registro: aplicación · Depende de: 09 · Habilita: 11 · Proyecto: **nace la API**

Alcance literal: `propuesta-fases-y-alcance.md` §5, bloque de la Fase 10.

**Lo propio de este chat:**
- **Nace el proyecto 2**, la API de agenda. Fija su forma —módulos, modelos, nombres del
  dominio— porque siete fases la arrastran. Usa el diccionario de la guía §5.1 sin inventar
  términos.
- La idea que ordena la fase es **validar en la frontera una sola vez**; hacia adentro el dato ya
  es de fiar. Todo lo demás de la fase cuelga de ahí.
- `async` entra **solo lo justo** para no bloquear el bucle. La concurrencia en serio es la 14 y
  adelantarla aquí desordena las dos.

**Cuidado con:** meter reglas de negocio en el modelo de entrada. La trampa del miniproyecto es
exactamente esa, así que el material no puede cometerla.
````

## # Fase 11

````markdown
Fase **11 — 🗄️ Persistencia** · archivo `11-persistencia.md`
Bloque C · Registro: aplicación · Depende de: 10 · Habilita: 12 · Proyecto: API

Alcance literal: `propuesta-fases-y-alcance.md` §5, bloque de la Fase 11.

**Lo propio de este chat:**
- **Core contra ORM son dos herramientas distintas, no dos niveles de abstracción.** Si la fase
  las presenta como "bajo nivel y alto nivel", reproduce el malentendido que viene a corregir.
- El miniproyecto es **el dominio duro de Áurea**: el plan de Arquitectura de Sonrisa con sus
  cinco fases, su responsable y sede por fase, su consentimiento por fase y su plan de pagos en
  paralelo. Lee `00-historia-de-aurea.md` §1.1 completa antes de modelar; hay reglas ahí
  que el modelo obvio no soporta.
- El bloqueo optimista de las dos auxiliares reservando las 3:40 se **planta** aquí y se resuelve
  en la 14. Declara el reenvío.

**Cuidado con:** otros motores. MySQL, Mongo y el resto son del track `db`, y nombrarlos aquí
abre una puerta que la fase no puede cerrar.
````

## # Fase 12

````markdown
Fase **12 — 🏛️ Django y el veredicto web** · archivo `12-django-y-el-veredicto-web.md`
Bloque C · Registro: aplicación · Depende de: 11 · Habilita: 13 · Proyecto: **nace el back-office**

Alcance literal: `propuesta-fases-y-alcance.md` §5, bloque de la Fase 12.

**Lo propio de este chat:**
- **Nace el proyecto 3.** Y trae el ⚖️ veredicto del curso sobre los dos registros web, con el
  criterio explícito: **son dos registros, no dos calidades.** Una fase que deje al lector con la
  impresión de que uno es mejor está mal escrita.
- Los permisos por fila y la auditoría de accesos **no son una mejora, son un requisito legal** en
  el dominio de Áurea (guía §11, última regla). El miniproyecto se juega ahí.
- La medición compara el mismo CRUD en los dos, y la columna que decide es qué hace falta para la
  pantalla número cuarenta y uno.

**Cuidado con:** el admin de Django. El lector lo subestima porque no tiene equivalente en su
mundo; la fase tiene que mostrarlo funcionando, no describirlo.
````

## # Fase 13

````markdown
Fase **13 — 🌐 Integraciones** · archivo `13-integraciones.md`
Bloque C · Registro: aplicación · Depende de: 12 · Habilita: 14 · Proyecto: API

Alcance literal: `propuesta-fases-y-alcance.md` §5, bloque de la Fase 13.

**Lo propio de este chat:**
- **La idempotencia es el corazón de la fase**, no un apartado. El reintento sobre una operación
  que no es idempotente es cómo se le cobra dos veces a un paciente, y en Áurea eso termina en una
  llamada de Clara.
- El miniproyecto pide diseñar **las dos puntas** del webhook, emisor y receptor. Es lo que separa
  entender "al menos una vez" de haberlo leído.
- Hace falta un **servidor de pruebas que falle a propósito** —lento, 500 intermitentes,
  respuestas truncadas—: escríbelo en la fase, con stdlib o con lo que ya está instalado.

**Cuidado con:** automatizar portales sin API. Es del track `au` y aquí solo se nombra como el
caso que no se cubre.
````

## # Fase 14

````markdown
Fase **14 ⭐ — 🧵 Concurrencia y el GIL** · archivo `14-concurrencia-y-gil.md`
Bloque C · Registro: aplicación · Depende de: 13 · Habilita: 15 · Proyecto: los tres

Alcance literal: `propuesta-fases-y-alcance.md` §5, bloque de la Fase 14.

**Lo propio de este chat:**
- Es la fase donde el instinto de Java es **más fuerte y más inútil**, y donde todo se decide
  midiendo. Nada de afirmaciones sobre el GIL sin su número.
- **Dos mediciones, no una:** la carga CPU-bound y la de E/S, en las mismas cuatro formas. **El
  veredicto se invierte entre las dos, y esa inversión es la lección.**
- Aquí se cierra el reenvío de la Fase 11: el estado compartido de Áurea no vive en memoria sino
  en Postgres, así que se resuelve con bloqueo optimista y una restricción, no con una primitiva
  del lenguaje.
- El free-threading se mide con la versión fijada del curso y se declara qué cambia de verdad, sin
  entusiasmo.

**Cuidado con:** medir en tu máquina y extrapolar. Áurea tiene una máquina virtual de dos núcleos
y el ganador cambia; el miniproyecto se juega exactamente ahí.
````

## # Fase 15

````markdown
Fase **15 — 🌙 El proceso nocturno** · archivo `15-el-proceso-nocturno.md`
Bloque C · Registro: aplicación · Depende de: 14 · Habilita: 16 · Proyecto: **nace el batch**

Alcance literal: `propuesta-fases-y-alcance.md` §5, bloque de la Fase 15.

**Lo propio de este chat:**
- **Nace el proyecto 4.** Y tiene una relación deliberada con el proyecto 1: **el batch importa
  el CLI como biblioteca**. La misma validación que Patricia corre a mano es la que corre
  desatendida a las dos de la mañana sobre las diez sedes. Ese es el momento en que el curso
  demuestra para qué servía empaquetar bien en la Fase 07 — dilo explícitamente.
- La auditoría **línea por línea** —qué se sumó, con qué tasa, bajo qué cláusula— es requisito del
  dominio, no adorno: el miniproyecto exige reproducir un número de hace ocho meses.
- El patrón *outbox* entra porque la cola no sustituye a la transacción, y ese es el punto.

**Cuidado con:** comparar Celery, RQ y `arq` como si fuera una reseña. Se eligen con criterio y se
declara el costo del elegido.
````

## # Fase 16

````markdown
Fase **16 — 🔭 Operación y rendimiento** · archivo `16-operacion-y-rendimiento.md`
Bloque C · Registro: aplicación · Depende de: 15 · Habilita: 17 · Proyecto: los cuatro

Alcance literal: `propuesta-fases-y-alcance.md` §5, bloque de la Fase 16.

**Lo propio de este chat, y es una fusión con condición:**
- **Dos bloques 📏 separados**, nunca uno promediado: el costo de la observabilidad, y el perfil
  del cierre nocturno. Si al redactar el perfilado queda como nota al pie de la observabilidad, la
  fusión falló: dilo en los 📌 y propón la separación.
- La regla que ordena la mitad de rendimiento es **primero SQL, después Python**. El miniproyecto
  no se aprueba si el lector optimiza antes de perfilar, y el material tiene que predicar con el
  ejemplo: la primera mejora grande del cierre no está en Python.
- La seguridad que entra es la que muerde en este ecosistema: `pickle`, `yaml.load`, `shell=True`
  —que la Fase 05 ya prohibió— y la cadena de suministro.

**Cuidado con:** las salidas de emergencia. Vectorización, Cython y extensiones nativas se nombran
con su costo y su umbral, no como recomendación.
````

## # Fase 17

````markdown
Fase **17 🏁 ⭐ — ⚔️ El duelo y el veredicto** · archivo `17-el-duelo-y-el-veredicto.md`
Bloque C · Registro: aplicación · Depende de: 16 · Habilita: — · Proyecto: **la API ×2**

Alcance literal: `propuesta-fases-y-alcance.md` §5, bloque de la Fase 17.

**Lo propio de este chat, y cierra el curso:**
- **El Spring Boot del duelo tiene que ser bueno.** Un competidor de paja invalida la medición y
  el lector —que lleva once años escribiendo Spring— lo va a notar en diez segundos. Si no está
  bien configurado, la fase no está lista.
- **El miniproyecto es la defensa del capstone**, y el veredicto general ocupa su propia sección.
  Si el veredicto termina siendo un párrafo de cortesía al pie de una tabla, la fusión falló.
- El contenedor entra **solo con lo justo para medir** arranque en frío y costo. No hay fase de
  contenedores ni de orquestación, y lo demás **queda declarado fuera sin enlazarse a ninguna
  parte** (`alcance-del-proyecto.md` §0).
- **El empate se llama empate.** Va a haber columnas empatadas y decirlo es el punto.
- La frase que cierra el curso ya está escrita y se respeta: *si al final resultara que Python
  ganó todo, el curso estaría mal escrito.*

**Al terminar esta fase:** consolida `BENCHMARKS.md` con las mediciones de las 18 fases
(`formato-de-mediciones.md` §4) y escribe `INSTINTOS.md` con los reflejos recurrentes que
aparecieron, que es material del repositorio y no de una fase.
````
