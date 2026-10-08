# ✍️ Guía de estilo, tono y convenciones
## Curso Docker Legacy Node — Laboratorio de contenedores para JavaScript legacy

Esta guía es la fuente de verdad editorial del curso. Cualquier chat que produzca
un `.md` de este proyecto la sigue. Su objetivo es simple: que las treinta y seis
fases —y todo lo que venga después— se lean como escritas por la misma mano, con
la misma voz y el mismo criterio, y que todas apunten al mismo lugar: **que el
lector entienda qué está pasando dentro del contenedor, no que copie comandos**.

Si dudas entre dos formas de escribir algo, gana la que le sirva más a alguien
que mañana tiene que revivir un proyecto de 2018 en un MacBook con chip M4 y no
sabe por dónde empezar.

> 📝 **Revisada el 05/10/2026** contra los lineamientos de producción del
> repositorio. Lo que este curso hace distinto de los valores por defecto del
> `CLAUDE.md` está declarado en §16, que se agregó después del checklist para no
> renumerar nada: §14 sigue siendo el checklist.

---

## 1. 🧭 Principio rector

**Todo lo que se escribe apunta a que alguien reconstruya y entienda un entorno
de ejecución antiguo, sin magia y sin copy/paste ciego.**

No enseñamos Docker "bonito". No formamos ingenieros de plataforma. Formamos
capacidad de **arqueología técnica**: leer un `Dockerfile` ajeno, entender por
qué una capa invalida la caché, diagnosticar por qué `node-gyp` explota en
ARM64, distinguir el síntoma de la causa y decidir con criterio si el problema
está en la imagen, en el volumen, en el motor o en el host.

El filtro para cada párrafo es este: **¿esto ayuda a construir, entender,
diagnosticar o decidir?** Si no, sobra. Aunque esté muy bien escrito. Sobre todo
si está muy bien escrito.

Y el corolario del curso, repetido tantas veces como haga falta:

> cada comando se explica. Cada decisión responde a "¿por qué estamos haciendo
> esto?".

---

## 2. 🎤 Tono

El tono es **semi formal, cálido y directo**, con humor cuando cae bien. Piensa
en un colega que ya perdió tres tardes con este problema y te lo explica con
paciencia, sin solemnidad de manual corporativo y sin palmaditas en la espalda.

Cómo se ve eso en la práctica:

- **Tuteo latinoamericano, siempre.** Le hablas al lector de "tú": *"construye
  la imagen y mira qué capa se reutiliza"*, *"si esto te suena raro, es porque
  todavía no vimos los namespaces; aguanta dos secciones"*. Nada de voseo
  (*"construí"*, *"fijate"*), nada de "usted", nada de impersonal permanente
  ("se debe configurar…") que enfría el texto.
- **Semi formal.** Cercano, pero no chat de WhatsApp. Frases completas,
  puntuación correcta, cero abreviaturas de mensajería. Un "che" no, un "ojo con
  esto" sí.
- **Humor seco y con moderación.** Un 😉 bien puesto, un chiste sobre tratar a
  Docker como agua bendita o sobre el `console.log()` hasta que el archivo
  parece árbol de Navidad. El humor sirve para desdramatizar la fricción del
  legacy, no para rellenar. Regla práctica: **máximo un chiste por sección**, y
  si no fluye solo, se borra.
- **Honesto sobre lo feo.** Estamos usando una distribución fuera de soporte, un
  Node que llegó a EOL hace años y paquetes que ya nadie parchea. Se dice tal
  cual: *"esto no es una recomendación para producción; es un laboratorio de
  mantenimiento local"*. No fingimos elegancia donde no la hay.
- **Cálido sin condescendencia.** Explicamos desde cero, pero nunca
  infantilizamos. "Como para un bebé" significa **cero ambigüedad**, no menos
  profundidad: se explica qué es Debian, qué significa `slim` y qué paquetes se
  pierden, no se dice "usa slim porque es más ligero" y listo.
- **Orientado a la duda real.** Anticipa el *"¿y esto por qué está así?"* y
  respóndelo, muchas veces con una 📝 **Nota de época** que dé el contexto
  histórico: en 2018 esa decisión tenía sentido, y explicarlo evita que el
  estudiante juzgue en vez de entender.

Lo que evitamos: promesas vacías ("vas a dominar Docker"), motivación de coach,
solemnidad de manual, recetas sin justificación y esa forma tan cómoda de
enseñar que consiste en pegar un `Dockerfile` de veinte líneas y decir "esto
funciona".

---

## 3. 🗣️ Idioma y forma de la narrativa

- **Español latinoamericano neutro**, técnico y claro, para todo lo que no es
  código o salida de terminal: títulos, explicaciones, ejercicios, referencias,
  callouts.
- **Los términos del stack se quedan en inglés** cuando son el nombre real de la
  cosa: *image*, *container*, *layer*, *cache*, *build context*, *bind mount*,
  *volume*, *registry*, *digest*, *manifest*, *tag*, *entrypoint*, *namespace*,
  *cgroup*, *rootless*, *shim*, *toolchain*. Traducirlos forzadamente ("capa de
  construcción", "punto de entrada") confunde más de lo que aclara y no es lo
  que van a leer en la documentación oficial ni en los mensajes de error. Los
  que ya tienen traducción asentada —imagen, contenedor, capa, red, volumen—
  pueden alternar con naturalidad; lo importante es no inventar vocabulario.
- **Markdown siempre.** Nada de HTML embebido salvo que no haya alternativa.
- **Prosa antes que listas.** Se prefiere razonar en párrafos: un párrafo que
  explica *por qué* vale más que cinco viñetas que enumeran *qué*. Las listas se
  usan cuando la cosa es de verdad una lista — pasos secuenciales, ítems
  paralelos, opciones.
- **Nada de prosa telegrama.** Una frase corta y sola, con líneas en blanco a
  ambos lados, es un golpe de ritmo excelente: *"Y así se rompe."* Tres seguidas
  ya no son ritmo, son un telegrama, y el lector deja de encontrar el argumento
  porque no hay párrafo donde buscarlo. Regla práctica: **una frase aislada por
  sección, dos si la sección es larga**; el resto se agrupa en párrafos. Si al
  releer un bloque ves cinco líneas sueltas seguidas, tienes un párrafo mal
  escrito, no cinco énfasis.

  ```markdown
  ❌  Dos contextos distintos.

      No hay contradicción.

      Es la misma regla.

  ✅  No hay contradicción: son dos contextos distintos y la regla es la misma.
  ```

- **Diagramas en Mermaid.** Se usan sin timidez para mostrar arquitecturas,
  flujos, estados y árboles de decisión: un diagrama vale más que dos párrafos
  cuando hay capas involucradas. Van en un bloque `mermaid`, con la frase de
  antes diciendo qué mirar. Hasta el 05/10/2026 eran ASCII en bloques `text`, la
  marca de la casa de entonces; el cambio y su criterio están en §16.1.

  ````markdown
  ```mermaid
  flowchart TD
      subgraph H["HOST MODERNO"]
          ED["editor"]
          GIT["Git"]
          SRC["código fuente"]
      end
      ENG["Docker / Podman"]
      subgraph C["CONTENEDOR LINUX"]
          D10["Debian 10"]
          NL["Node legacy"]
          TC["toolchain"]
      end
      H --> ENG --> C
  ```
  ````

- **Lo que no es un diagrama se queda en `text`**: árboles de archivos, salidas
  de terminal, checklists, las fichas de «Resultado de la fase», comparativas en
  dos columnas, correspondencias `a → b` y la anatomía de un nombre
  (`node-v10.24.1-linux-x64.tar.xz` con una flecha por campo). Se leen mejor
  alineados y se copian tal cual.

- **Listas antes que tablas en comparativas extensas.** Cuando compares tres
  motores, cuatro distribuciones o cinco estrategias de instalación, **usa una
  lista con subtítulos**, no una tabla ancha. Una tabla de siete columnas se lee
  mal en pantalla, se lee peor en móvil y no deja espacio para explicar el
  porqué de cada celda. La lista sí.

  Formato recomendado para comparativas:

  ```markdown
  **Opción A — Alpine con musl**

  Qué es: imagen mínima basada en musl libc y BusyBox.
  Cuándo conviene: cuando el tamaño manda y no hay dependencias nativas.
  El costo: los binarios precompilados de Node y muchos módulos nativos
  asumen glibc; terminas compilando todo.
  Veredicto: descartada para este laboratorio.
  ```

- **Tablas solo para lo que de verdad es tabular y corto.** Versiones pinneadas,
  mapeo fase → tag, matriz motor × plataforma, tabla de decisión. Tres o cuatro
  columnas como máximo. Si necesitas explicar una celda, ya no es una tabla: es
  una lista.
- **Encabezados con emoji, con moderación.** Uno por sección numerada. Las fases
  largas se organizan en **Partes** (`# 🧠 Parte II — …`, con numeración romana)
  y dentro de cada Parte las secciones llevan numeración arábiga continua a lo
  largo de todo el documento. Un documento que parece un teclado de emojis
  pierde autoridad.
- **Salida de terminal literal.** Cuando se muestra lo que imprime un comando,
  se muestra tal como sale, en bloque `text`, sin embellecer y sin recortar la
  parte incómoda. El error real enseña más que el error editado.

---

## 4. 🎓 Pedagogía: cómo se explica

Esta sección es la que más define el curso. El público es amplio —estudiantes,
juniors, frontend, backend, ingenieros con experiencia— y la regla que los
cubre a todos es la misma: **nunca asumir conocimientos previos**. No porque el
lector sea incapaz, sino porque las explicaciones detalladas reducen la
ambigüedad.

### 4.1 La regla del andamio

Todo concepto nuevo se presenta en tres tiempos, en este orden:

1. **El problema primero.** Antes de nombrar la herramienta, muestra el dolor
   que resuelve. *"Instalaste tres paquetes en tres `RUN` distintos y ahora
   cambiar el último invalida la caché de… ninguno. ¿Seguro que eso es lo que
   querías?"*
2. **La herramienta después.** Ahora sí, el nombre y la definición mínima.
   Definición mínima significa: lo justo para usarla hoy, no el capítulo
   completo de la documentación.
3. **El comando que corre.** El fragmento más pequeño que demuestra el punto,
   con su salida esperada y comentarios que explican el porqué.

Presentar la herramienta antes que el problema produce estudiantes que saben
escribir `--no-install-recommends` pero no saben cuándo hace falta.

### 4.2 Nada de cajas negras prematuras

El curso enseña primero el mecanismo y después la comodidad. Por eso, en el
tronco principal:

- primero `docker build`, `docker run`, `docker exec`, `docker logs`, `docker
  volume`; **después**, y solo cuando simplifique de verdad un escenario
  multi-contenedor, Docker Compose;
- primero la terminal y el bind mount; **después** Dev Containers como capa de
  comodidad, nunca como requisito;
- nada de Kubernetes ni Helm: quedan explícitamente fuera de alcance.

No es que esas herramientas sean malas. Es que ocultan los conceptos que el
curso quiere enseñar, y cuando el estudiante los entiende, las capas superiores
se aprenden en una tarde.

### 4.3 Analogías, con fecha de caducidad

Las analogías se usan **una vez, para abrir la puerta**, y después se abandonan:
una imagen es como una plantilla y el contenedor como la instancia; una capa se
parece a un commit. Y siempre se dice dónde se rompe la analogía (*"hasta acá el
paralelo funciona; la diferencia es que una capa es un diff de sistema de
archivos y no guarda historia de autoría"*). Una analogía que no se cierra
genera bugs conceptuales que aparecen cinco fases después.

Cuidado especial con la analogía más peligrosa del tema: **un contenedor no es
una máquina virtual**. Si aparece, se desmonta en el mismo párrafo.

### 4.4 Explica el porqué, no solo el cómo

Un paso sin justificación es un paso que el estudiante no puede adaptar cuando
su proyecto real difiera del ejemplo. Cada decisión relevante lleva su porqué,
aunque sea media línea entre paréntesis: por qué `&&` y no dos `RUN`, por qué
limpiar `/var/lib/apt/lists` en la misma capa, por qué `exec "$@"` en el
entrypoint, por qué fijamos `10.24.1` y no `10.x`.

Y cuando el porqué es histórico y no técnico —que en legacy pasa seguido—, se
dice también: *"esto está así porque en 2018 `node-gyp` solo hablaba Python 2, y
hoy sigue siendo verdad para ese proyecto porque no vas a migrarlo"*.

### 4.5 Densidad calibrada

- Un concepto nuevo por vez. Si un bloque de código introduce tres cosas
  desconocidas, se parte en tres bloques.
- Repetir lo importante está bien. Los conceptos que sostienen el curso —imagen
  vs contenedor, capas y caché, qué vive en el host y qué en el contenedor,
  arquitectura de CPU, EOL— reaparecen varias veces con otras palabras. La
  repetición espaciada funciona; la enciclopedia no.
- Ninguna sección teórica supera las dos pantallas sin que aparezca un comando,
  un diagrama o una salida real.

### 4.6 Cierra los bucles

Si abres un paréntesis pedagógico —*"esto lo vemos en la Fase 11"*, *"por ahora
lo dejamos como deuda 💸"*— tiene que cerrarse en algún documento del curso. Un
pendiente que nunca se resuelve es ruido, y el lector deja de confiar en las
promesas del texto. El mapa de referencias cruzadas entre fases es parte del
producto, no un adorno.

---

## 5. 💻 Idioma del código, comandos y archivos

> **Regla normativa y no negociable: todo lo que se ejecuta o se versiona se
> escribe en inglés —nombres de archivo, rutas, variables de entorno, tags,
> etiquetas OCI, scripts, identificadores, targets— y todos los comentarios se
> escriben en español.** Aplica a cada fragmento del proyecto sin excepción:
> `Dockerfile`, scripts de shell, YAML de CI, JSON de configuración, fixtures y
> ejercicios resueltos.

La razón es la misma que en cualquier proyecto real: los comandos, las opciones
y los mensajes de error están en inglés, y el vocabulario que el estudiante
practica durante el curso tiene que ser el que va a escribir en su terminal.

La contraparte importa igual: **los comentarios van siempre en español**, porque
son el canal donde se explica el *porqué* de una decisión rara, y ese
razonamiento tiene que leerse en el idioma en que se piensa el curso. Un
comentario en inglés en este proyecto es un error de estilo, aunque el
`Dockerfile` que acompaña esté impecable.

Cómo se reparte:

- **En inglés:** nombres de archivo y directorio (`dockerfiles/`, `scripts/`,
  `fixtures/`), nombres de script (`docker-entrypoint.sh`,
  `diagnose-container.sh`, `validate-project.sh`), variables de entorno
  (`NODE_VERSION`, `LEGACY_NODE_HOME`), build args, nombres de imagen y tags
  (`legacy-node-toolchain:node10`), etiquetas OCI, nombres de stage, nombres de
  red y de volumen, funciones y variables de shell.
- **En español:** los comentarios (`# limpiamos los índices en la misma capa
  para no dejarlos horneados en la imagen`), y toda la narrativa, ejercicios,
  títulos, diagramas y callouts.

> ⚠️ **Caso mixto frecuente.** Un script lleva su lógica y sus variables en
> inglés y sus comentarios y mensajes de diagnóstico pedagógicos en español:
> `# si la versión no existe, fallamos temprano y con un mensaje claro` seguido
> de `echo "Versión de Node no soportada: ${version}" >&2`.

### 5.1 Convenciones de nombrado del laboratorio

- **Dockerfiles pedagógicos:** `dockerfiles/NN-tema.Dockerfile` con numeración
  de dos dígitos y tema en kebab-case en inglés o en el término técnico usual.
  Los nueve del curso, con la fase que los introduce:
  `01-hola-mundo` (F02), `02-utilidades` (F03), `03-toolchain` (F04),
  `04-python-node-gyp` (F05), `05-node` (F06), `06-build` (F07),
  `07-native-dependencies` (F15), `08-multiarch` (F21) y `09-diagnostic` (F30).
- **Dockerfile canónico:** `Dockerfile` en la raíz, desde la **Fase 07**. Los
  pedagógicos no lo reemplazan: lo acompañan.
- **Scripts:** `scripts/` en kebab-case, con extensión cuando aplique
  (`scripts/docker-entrypoint.sh`, `scripts/select-node`,
  `scripts/legacy-node-command`, `scripts/validate-project.sh`).
- **Imagen:** `legacy-node-toolchain`.
- **Tags pedagógicos por fase:** `legacy-node-toolchain:phaseNN`.
- **Tags de variante Node:** `legacy-node-toolchain:node10`, `:node12`,
  `:node14`, `:node16`.
- **Documentos del curso:** `NN-tema.md`, dos dígitos, kebab-case en español
  (`08-instalacion-node.md`, `15-docker-vs-podman.md`).
- **Código real del curso:** vive en `src/`, con **un subdirectorio por fase que
  use el mismo nombre del documento** — `src/30-troubleshooting-metodo-y-herramientas/`
  para `30-troubleshooting-metodo-y-herramientas.md`. Solo se crea el subdirectorio de las fases donde
  aplique: las fases conceptuales no lo tienen.
- **Estructura interna de `src/NN-tema/`:** **reproduce la raíz del laboratorio
  del estudiante**, no una lista plana. Si el documento llama al archivo
  `dockerfiles/05-node.Dockerfile`, en `src/` está en
  `src/06-instalacion-node/dockerfiles/05-node.Dockerfile`, de modo que un
  `cp -r src/06-instalacion-node/. .` deja el laboratorio listo. El prefijo de
  fase (`30-diagnose-container.sh`) se usa solo para los archivos **sueltos** en
  la raíz del subdirectorio, que no cuelgan de `dockerfiles/` ni de `scripts/`.
- **`src/all-dockerfiles/`:** copia consolidada de los Dockerfiles del curso,
  para leerlos seguidos. La duplicación es deliberada.
- **Regla de sincronía:** todo bloque de código que el estudiante deba ejecutar
  tal cual —Dockerfiles, scripts, fixtures, plantillas de reporte— existe como
  archivo en `src/NN-tema/` y su versión en el `.md` es una copia idéntica. Si
  cambia uno, cambia el otro. **Excepción documentada:** cuando el `.md` muestra
  a propósito solo *el fragmento que cambia* sobre el canónico (F08, F15, F21),
  el archivo de `src/` está completo y lleva una cabecera de tres líneas que lo
  declara.
- **Puntero desde el documento:** toda fase o apéndice con código lleva en su
  blockquote de cabecera la línea
  `> **Código de esta fase:** [\`src/NN-tema/\`](src/NN-tema/)`.

### 5.2 Versiones fijadas (baseline del laboratorio)

Estas versiones son la referencia del curso completo. Si un documento necesita
otra, lo declara explícitamente y explica por qué.

| Componente | Versión fijada |
|---|---|
| Base | Debian 10 Buster — `debian/eol:buster` |
| Arquitectura baseline | `linux/amd64` (adicional: `linux/arm64`) |
| Node baseline | `10.24.1` con npm `6.14.12` |
| Nodes disponibles | `10.24.1`, `12.22.12`, `14.21.3`, `16.20.2` |
| Compilador | GCC/G++ 8 de Debian 10 |
| Python | 2.7 y 3.7 de Debian 10 |
| Motor de referencia | Docker (alternativo: Podman) |

**Nunca uses rangos donde el curso fija una versión exacta.** Un `10.x` en un
ejemplo destruye la reproducibilidad que el curso entero intenta enseñar.

---

## 6. 🏺 Manejo del legacy y del EOL

Acá está la tentación grande: escribir el `Dockerfile` *moderno y correcto* en
vez del que resuelve el problema real. No lo hacemos.

- **Compatibilidad antes que novedad.** No elegimos componentes por ser los más
  nuevos, sino por ser compatibles con el software que intentamos mantener. Una
  distribución fuera de soporte es aceptable si reproduce mejor el entorno de la
  época, sus paquetes siguen disponibles en archivos históricos y su uso queda
  limitado a desarrollo y mantenimiento local.
- **El EOL se nombra, siempre.** Cada vez que aparezca Debian 10, Node 10 o
  Python 2, se recuerda que están fuera de soporte y qué implica: sin parches de
  seguridad, con repositorios movidos al archivo, sin garantías. La honestidad
  acá no es opcional; es parte del contenido.
- **No es producción y se dice.** Ninguna sección puede dejar la impresión de
  que esta imagen es un artefacto para exponer a Internet. Docker no es agua
  bendita. 😄
- **Todo pinneado.** Versiones exactas, digests cuando importan, tags que no se
  muevan. Un `latest` en el tronco principal del curso es un error de estilo.
- **Reproducir el error antes de arreglarlo.** Cuando algo falla —`node-gyp`,
  una dependencia nativa, un binario que no existe para ARM64— se muestra el
  fallo real, con su salida, y solo después la corrección. El error editado no
  enseña.
- **Corrección mínima vs solución estructural.** Cada vez que aparece un fix, se
  distingue el parche que desbloquea hoy de la solución que uno haría con calma.
  Es una de las lecciones más transferibles del curso.
- **El contenedor contiene el toolchain, no el proyecto.** El código fuente vive
  en el host y se conecta por bind mount. Ningún ejemplo puede contradecir esta
  regla sin declararlo explícitamente como excepción y justificarla.

---

## 7. 🧷 Marcadores, callouts y encabezado de fase

Vocabulario visual compartido por todos los documentos, para que el lector lo
reconozca de un vistazo.

### 7.1 Bloque de encabezado obligatorio

Toda fase abre con el título y, justo debajo, un blockquote de metadatos que
fija el contrato del documento. Los campos varían según la fase, pero `Curso` y
`Objetivo` no faltan nunca:

```markdown
# 🏗️ Parte I · Fase 07 — Build: construir la imagen sin tratar la caché como magia negra

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`)
> **Arquitectura objetivo del laboratorio:** `linux/amd64`
> **Dockerfile pedagógico de esta fase:** `dockerfiles/06-build.Dockerfile`
> **Tag pedagógico:** `legacy-node-toolchain:phase07`
> **Estado de la imagen al terminar:** …
> **Objetivo:** …
```

Cuando el documento cite documentación externa que cambia seguido —registries,
Buildx, Podman—, se añade **`Fecha de revisión de documentación externa:`** con
la fecha en que se verificaron los enlaces.

El título de la fase es descriptivo y con carácter: `Fase NN — Tema: la promesa
concreta del documento`. Nada de `Fase 07 — Build` a secas.

### 7.2 Marcadores de estado

- 💸 **Deuda técnica intencional.** El atajo que se deja a propósito porque
  resolverlo ahora distraería. Se declara, se explica por qué se acepta y se
  dice en qué fase se paga (o que no se paga).
- 🔥 **Opcional o ampliación.** Secciones y ejercicios fuera del alcance base. En
  ejercicios es además el escalón por encima de 🔴: mini proyectos y voltaje extra.
- 💀 **Boss fight.** El ejercicio que cierra una fase —o el curso— y solo se
  resuelve encadenando todo lo anterior. **Uno por fase como máximo**, y solo si la
  fase da para tanto. No es un 🔴 con mejor nombre: un boss combina varios
  mecanismos y suele empezar con un sistema roto que hay que diagnosticar entero.
- ⭐ **Valoración bibliográfica, y solo eso.** De una a cinco estrellas para decir
  cuánto vale una referencia, **exclusivamente en F35** y siempre con su leyenda
  visible en el propio documento. **No es un nivel de dificultad y no gradúa
  ejercicios jamás** — para eso está la escala de §9. Tampoco marca ya "pieza
  central" de una fase: ese sentido se declaró en su día, no lo usó ni un
  documento, y se retira para que `⭐` tenga un único significado en todo el curso.
  Si necesitas señalar lo más formativo de una fase, dilo con palabras.
- 🟢🟡🟠🔴 **Dificultad de ejercicios.** Fácil, intermedio, difícil, muy difícil.
  La escala completa, con 🔥 y 💀, está en §9.
- 🚧 **Fuera de alcance por ahora**, con destino explícito.

### 7.3 Callouts en blockquote

- 📝 **Nota de época.** Contexto histórico de una decisión que hoy se ve rara.
- 📚 **Referencia rápida inline.** El enlace útil justo donde nace la duda, sin
  esperar a la sección de referencias.
- ⚠️ **Advertencia.** Algo que rompe si lo ignoras: arquitectura equivocada,
  `node_modules` compartido entre host y contenedor, caché que oculta el cambio,
  repositorio EOL que ya no responde.
- 💡 **Truco o atajo** que ahorra tiempo real.
- 🧠 **Modelo mental.** La frase que hay que llevarse, no el detalle.
- 🩺 **Diagnóstico.** El comando que confirma o descarta una hipótesis.
- 🪦 **Retiro.** Cuando algo cumple su función y sale del laboratorio.
- 🧭 **Principio.** La regla que ordena una decisión o una frontera entre fases.
- 🚨 **Seguridad.** Lo que expone secretos o el host: un `ARG` con una
  contraseña, el socket de Docker montado, un puerto publicado en `0.0.0.0`.
- 🦭 **¿Y Podman?** La nota corta cuando Podman difiere y la diferencia no
  merece la ruta completa de §11.
- ⚰️ **Autopsia.** Un anti-patrón recurrente, con lo que cuesta.

No hace falta usarlos todos en cada documento. Se usan cuando aportan.

### 7.4 Secciones narrativas recurrentes

Micro-secciones con nombre fijo, que aparecen cuando el contenido las pide:

- **Dónde estamos.** Apertura de fase: qué dejó la anterior y qué falta.
- **Detalles con intención.** Lista corta con las decisiones deliberadas de un
  bloque de código y su porqué.
- **El patrón a memorizar.** Una o dos frases que destilan la lección
  transferible del fragmento.
- **Prueba de fuego.** Verificación manual concreta, incrustada en el flujo y no
  en los ejercicios: *"reconstruye cambiando solo la última línea y confirma que
  las capas anteriores dicen `CACHED`"*.
- **Mini-repaso.** Cuando la sección usa algo que el lector quizá no domina
  —permisos POSIX, señales, `PATH`, glibc—, un repaso exprés antes de entrar al
  comando, con su 📚 a la documentación oficial.
- **La señal de que quedó bien.** En el cierre, un criterio en forma de cita que
  describe cómo se siente el trabajo bien hecho: *"si borro la imagen y
  reconstruyo mañana en otra máquina, obtengo exactamente el mismo entorno"*.

---

## 8. 🧱 Plantilla obligatoria de cada fase

Toda fase produce un `.md` con esta estructura, y la recorre con **secciones `##`
numeradas planas**. Las **Partes** en romanos (`# 🧠 Parte II — …`) son la
excepción, no la norma: solo aparecen por encima de ~4.000 palabras, que con fases
de 3.000–5.000 es casi ninguna. Cuando aparezcan, la numeración arábiga de
secciones sigue siendo continua a lo largo del documento.

> 📝 Los documentos originales del curso —de 8.000 a 19.000 palabras— se
> organizaban en 15 a 26 Partes cada uno. Esa estructura **no se hereda al cortar**:
> una fase de 4.000 palabras con Partes romanas se lee como un libro fingiendo ser
> un capítulo.

1. **Título + bloque de metadatos** — §7.1.
2. **🧭 Dónde estamos** — qué quedó de la fase anterior, qué falta, y el diagrama
   del estado actual de la imagen.
3. **🎯 Objetivos de esta fase** — qué se va a entender y qué va a existir al
   terminar. Verificable, no aspiracional.
4. **🚧 Qué NO entra todavía** — qué se difiere y a qué fase exacta.
5. **Cuerpo de la fase** — el grueso, en Partes temáticas. Cada concepto sigue
   la regla del andamio (§4.1): problema, herramienta, comando con salida. Acá
   caben Notas de época, Mini-repasos, Detalles con intención, El patrón a
   memorizar y Prueba de fuego.
6. **⚠️ Errores comunes y diagnóstico** — qué se rompe típicamente en esta fase,
   con el error literal, la causa y la comprobación que lo confirma.
7. **📋 Checklist de validación** — comprobaciones ejecutables, en bloque `text`
   con casillas, que dejan la fase cerrada.
8. **🧪 Ejercicios** — ver §9.
9. **📚 Referencias** — ver §10.
10. **🏁 Resultado de la fase** — el contrato que queda fijado, normalmente como
    diagrama o bloque `text`, más La señal de que quedó bien.

Después de la última sección, y fuera de lo que lee el estudiante, cada fase
puede cerrar con **📌 Pendientes sugeridos**: lo que apareció al escribirla y no
cabía adentro, con destino explícito (otra fase, un ejercicio 🔥 o una decisión
de proyecto). Es material de autoría, no de lectura, y por eso va al final.

La Fase 35 (Referencias) y los dieciséis apéndices no siguen esta plantilla:
usan índice de salto rápido, secciones cortas, una guía final de "cuándo usar
qué" y de 5 a 10 ejercicios cortos.

---

## 9. 🧪 Ejercicios

- **Cantidad: 20 mínimo y 35 máximo por fase práctica, calibrado fase por fase.**
  El mínimo no se negocia en ninguna fase que construya, ejecute o diagnostique
  algo. El máximo tampoco: por encima de 35 la sección deja de ser un aparato de
  práctica y pasa a ser un banco de preguntas.

  **Y la cifra concreta se decide por el contenido de la fase, no por su longitud.**
  La pregunta que la fija es *"¿cuántas cosas distintas enseña esta fase que se
  puedan comprobar por separado?"*. Una fase con cuatro mecanismos independientes
  —cuatro dragones de dependencias nativas, cuatro generaciones de Node, un
  catálogo de fallos con veinte entradas— pide más ejercicios que una fase que
  desarrolla un solo mecanismo a fondo, aunque las dos ocupen lo mismo. Como
  referencia de calibración, no como plantilla:

  | Cuántos ejercicios | Cuándo |
  |---|---|
  | **20** | la fase desarrolla **un** mecanismo, o es sobre todo criterio y decisión |
  | **24–25** | varios mecanismos entrelazados, o mucha superficie de comando |
  | **28–30** | catálogo, o tres o más laboratorios independientes dentro de la fase |
  | **32–35** | excepcional; hay que poder justificarlo con la lista de lo que se comprueba |

  > ⚠️ **La cantidad no arregla un aparato flojo.** Subir de 20 a 28 solo tiene
  > sentido si los ocho nuevos comprueban **algo que ninguno de los veinte
  > comprobaba**. Si al escribirlos te sale una variante de otro ejercicio, el
  > número correcto era 20. Vale mucho más una fase de 20 bien graduados que una
  > de 30 con diez de relleno, y el checklist de §14 se pasa contra eso.

  📝 **De dónde viene el cambio.** Esta guía pedía antes "25–30 ideal en las
  densas", una banda escrita cuando los documentos del curso tenían de 8.000 a
  19.000 palabras. Tras el corte a 36 fases ninguna pasa de ~5.000, así que
  "denso" dejó de significar lo mismo y la banda se recalibró a una decisión
  editorial por fase. Es el mismo motivo por el que §8 retiró las Partes en
  romanos.

  📏 **Y una precisión sobre la banda de 3.000–5.000 palabras que §8 menciona:
  se mide sobre el CUERPO de la fase, no sobre el archivo entero.** El aparato
  de ejercicios añade entre 1.300 y 2.800 palabras encima, así que una fase con
  el cuerpo en 3.500 y 28 ejercicios ronda las 6.200 en total y **está bien**.
  Si alguna vez auditas longitudes, corta el documento por el encabezado de
  `🧪 Ejercicios` antes de contar: lo que la banda vigila es la densidad de la
  prosa, no el peso del archivo.
- **Exenciones declaradas.** Quedan fuera del mínimo, y solo estas cuatro fases:
  **F00** y **F01**, que son **fases de decisión** —el lector no ejecuta nada, entiende
  el terreno—; **F35**, el **documento de referencias**, que es consulta y no lectura
  lineal; y **F34**, el **proyecto final**, por la razón contraria: la fase entera es
  un ejercicio. En las fases de decisión el ejercicio natural es leer un `Dockerfile`
  ajeno y justificar o rebatir una decisión; conviene incluir tres o cuatro de ese
  tipo aunque no cuenten para el mínimo.
- **La escala de dificultad, completa.** Seis escalones, y los dos últimos son
  gamificación deliberada: el curso premia a quien quiera seguir bajando al sótano.

  | | Nivel | Qué pide |
  |---|---|---|
  | 🟢 | Fácil | Reconocer y reproducir lo que la fase acaba de mostrar |
  | 🟡 | Intermedio | Aplicar el patrón a un caso nuevo, con algo de generalización |
  | 🟠 | Difícil | Combinar patrones, diagnosticar, decidir entre alternativas |
  | 🔴 | Muy difícil | Abierto o adversarial: se entrega algo roto y hay que razonarlo |
  | 🔥 | Extra | Mini proyectos y ampliaciones fuera del alcance base |
  | 💀 | Boss fight | Encadena toda la fase (o todo el curso) en un solo trabajo |

  **🔥 y 💀 no cuentan para el mínimo.** Son voltaje adicional, y una fase puede
  cerrarse sin ninguno de los dos.
- **El 💀 se decide, no se reparte.** Un boss fight sale de preguntarse *"¿hay en
  esta fase un trabajo que solo se resuelva encadenando todo lo anterior?"*, y en
  bastantes fases la respuesta honesta es que no. Una fase de criterio, de
  comparación entre productos o de lectura de documentación no tiene boss, y
  ponerle uno produce justo lo que §7.2 prohíbe: **un 🔴 con mejor nombre**. La
  señal de que el 💀 está bien puesto es que empiece con un sistema roto o un
  encargo completo, que cruce al menos tres secciones de la fase y que se pueda
  entregar como artefacto —un informe, una imagen que arranca, un `Dockerfile`
  reparado—. Si al escribirlo te cabe en tres líneas, no era un boss.
- **Distribución equilibrada, en proporciones y no en números fijos.** Alrededor
  de **30 % 🟢, 30 % 🟡, 25 % 🟠 y 15 % 🔴**, con margen de un escalón arriba o
  abajo según la fase. No cargues todo en fácil. Los 🔥 van aparte y el 💀, si lo
  hay, va solo y al final.

  | Obligatorios | 🟢 | 🟡 | 🟠 | 🔴 |
  |---|---|---|---|---|
  | 20 | 6 | 6 | 5 | 3 |
  | 25 | 7 | 8 | 6 | 4 |
  | 28 | 8 | 9 | 7 | 4 |
  | 30 | 9 | 9 | 7 | 5 |

  > 🧭 **Esa tabla es un punto de partida, no una casilla que rellenar.** Si dos
  > fases seguidas tienen exactamente el mismo reparto, lo más probable es que la
  > segunda no se haya graduado: se haya copiado. Una fase que se pasa la mitad
  > del tiempo rompiendo cosas —un catálogo de fallos, la de troubleshooting—
  > carga hacia 🟠 y 🔴; una que introduce vocabulario nuevo carga hacia 🟢. **La
  > desviación deliberada respecto de la tabla es señal de que se calibró.**
- **⭐ no gradúa ejercicios.** Las fases viejas lo hacían, de `⭐` a `⭐⭐⭐⭐⭐`; eso es
  residuo y se convierte a 🟢🟡🟠🔴🔥💀 **con criterio, ejercicio por ejercicio**, no
  contando estrellas. Un reemplazo mecánico produce justo la distribución
  desequilibrada que este apartado prohíbe. Fuera de los ejercicios, `⭐` tiene un
  único uso legítimo y está en §7.2: la valoración bibliográfica de F35.
- **Agrupados por dificultad, con encabezado de rango**, así:

  ```markdown
  # 🧪 Ejercicios de la Fase 06 (25)

  ## 🟢 Fácil — reconocer el toolchain (1–7)

  ### 🟢 Ejercicio 1 — Construir la fase

  ...

  **Objetivo:** …

  ## 🟡 Intermedio — usar el compilador de verdad (8–15)
  ...

  ## 🟠 Difícil — cuando la compilación falla (16–21)
  ...

  ## 🔴 Muy difícil — arqueología y diagnóstico (22–25)
  ...

  ## 🔥 Opcionales y mini proyectos
  ...

  ## 💀 Boss fight
  ...
  ```

  El título lleva el conteo de los **obligatorios**; 🔥 y 💀 no suman ahí.
- **Cada ejercicio cierra con su criterio.** Una línea **`Objetivo:`** con lo que
  el estudiante debe haber entendido, o una **`Pregunta:`** que solo se puede
  responder habiendo hecho el ejercicio. Nunca "construye una imagen" a secas.
- **Accionables y verificables.** *"Cambia el orden de dos `RUN` y demuestra con
  `docker build` cuántas capas se invalidan en cada caso"* — no *"reflexiona
  sobre la caché"*.
- **Al menos un tercio son de diagnóstico**, no de construcción: se entrega algo
  roto —un `Dockerfile` con las capas en mal orden, un contenedor sin el bind
  mount, una imagen construida para la arquitectura equivocada— y se pide
  reproducir, localizar y explicar. Es el músculo que este curso entrena.
- **Enganchados al laboratorio.** Se usan la imagen, los tags, los scripts y los
  fixtures que ya existen en el curso, con sus nombres vigentes
  (`legacy-node-toolchain:phase06`, no "tu imagen"). Nunca `foo` y `bar`.
- **Predecir antes de ejecutar.** En los ejercicios 🟠 y 🔴 conviene pedir
  explícitamente que el estudiante anticipe el resultado y después compare. Es
  donde se descubren los modelos mentales rotos.

---

## 10. 📚 Bibliografía y referencias

**Regla:** documentación oficial de la versión que usamos primero; después
especificaciones y estándares (OCI, POSIX, RFC); después libros; después blogs y
videos. Siempre se advierte cuando un enlace apunta a una versión distinta de la
que usamos, que con Docker y Node pasa casi siempre.

### 10.1 Formato

URLs completas y clicables, nunca solo el dominio. En la sección "Referencias"
de cada fase se agrupa por tema y, cuando la fase lo justifique, se cierra con
una línea de **orden de lectura sugerido**.

Cuando una fase se apoya en documentación que cambia con frecuencia —registries,
Buildx, Podman, acciones de CI—, se declara en el encabezado la **fecha de
revisión** de esos enlaces.

### 10.2 Fuentes oficiales por tema

- **Docker:** https://docs.docker.com — Dockerfile reference, build, storage,
  networking.
- **BuildKit / Buildx:** https://docs.docker.com/build/
- **Podman:** https://docs.podman.io/en/latest/ · Podman Desktop:
  https://podman-desktop.io/docs
- **OCI (image, runtime, distribution):** https://opencontainers.org y sus
  repositorios de especificación.
- **Debian 10 Buster:** https://www.debian.org/releases/buster/ · archivo
  histórico: https://archive.debian.org · snapshots:
  https://snapshot.debian.org
- **Node.js:** https://nodejs.org/en/download y el archivo de descargas
  https://nodejs.org/dist/ para versiones EOL. Advertir que
  https://nodejs.org/api documenta versiones muy posteriores a las nuestras.
- **npm 6:** https://docs.npmjs.com — advertir diferencias con npm 7+
  (`package-lock` v1 vs v2, resolución de peer dependencies).
- **node-gyp:** https://github.com/nodejs/node-gyp
- **VS Code Dev Containers:** https://code.visualstudio.com/docs/devcontainers/containers
- **WebStorm:** https://www.jetbrains.com/help/webstorm/
- **Colima:** https://github.com/abiosoft/colima
- **Cypress:** https://docs.cypress.io · **Selenium Docker:**
  https://github.com/SeleniumHQ/docker-selenium

### 10.3 Advertencias

- Cuando se cite un artículo, libro o video específico, se aclara que el título
  o la URL pueden haber cambiado y que conviene verificarlos. **No se inventan
  números de página, ISBN, identificadores de video ni fechas de publicación.**
- **La documentación oficial de hoy no describe el software de 2018.** Cada vez
  que se enlace algo actual para explicar un componente EOL, se advierte la
  brecha y, si existe, se enlaza también la versión histórica.
- Un issue de GitHub o una respuesta de Stack Overflow pueden ser mejor fuente
  que la documentación **para una pregunta distinta**: los usamos citando fecha,
  versión y contexto, nunca como dogma.

---

## 11. 🐳🦭 Convención Docker / Podman

El curso no se casa con un producto, pero tampoco pretende que sean idénticos.

- **Los ejemplos principales se escriben con `docker`.** Eso cubre Docker
  Desktop, Docker Engine y Docker sobre Colima.
- **Cuando la diferencia importa, se muestra el camino `podman` completo**, no
  una nota al pie. Y se explica *por qué* difieren: rootless, ausencia de daemon,
  mapeo de usuarios, `--userns=keep-id`, comportamiento de volúmenes en SELinux.
- **Nunca escribas "en Podman es igual" sin haberlo verificado.** Si no está
  verificado, se dice que no está verificado.
- **Fase 24 es la dueña de la comparación**, y F25 y F26 la continúan con rootless
  y portabilidad. Los demás documentos remiten a ellas en vez de reabrir la
  discusión.
- Lo mismo vale para las plataformas del host: cuando un comando cambia entre
  Windows, macOS Intel, Apple Silicon y Linux, se muestran las variantes
  relevantes; cuando no cambia, no se infla el documento repitiéndolo.

---

## 12. 🔗 Coherencia entre documentos

- **No contradecir fases anteriores.** Un fragmento de la Fase 09 no puede usar
  una estructura de directorios distinta a la que definió la Fase 02.
- **La imagen es incremental y acumulativa.** Cada fase declara en su encabezado
  el estado de la imagen al terminar, y ese estado tiene que encadenar con el de
  la fase siguiente. Si una fase rompe la cadena, lo dice explícitamente.
- **Nombres estables.** Archivos, scripts, tags, variables de entorno y rutas se
  mantienen idénticos entre fases. Si algo se renombra, se documenta el cambio y
  se ajustan las fases afectadas (el caso de `select-node`, que nace en la Fase 06,
  → `legacy-node-command`, que lo sustituye en runtime en la Fase 08, es el
  precedente de cómo hacerlo bien).
- **Las versiones no se contradicen.** El baseline de §5.2 manda. Cualquier
  desviación se declara con ⚠️ en el documento que la introduce.
- **Fuentes de verdad, en este orden:** (1) `prompts/propuesta-fases-y-alcance.md`,
  que dice qué entra en cada fase; (2) esta guía, que dice cómo se escribe;
  (3) `00-problema-y-contrato.md`, el contrato técnico del laboratorio;
  (4) fases ya escritas y aprobadas; (5) decisiones explícitas del chat actual,
  que valen hasta que se trasladan arriba. El `CLAUDE.md` del repositorio va por
  encima de todos como valor por defecto, y esta guía lo reemplaza donde §16 lo
  declara. La idea original del curso (`idea_tutorial.md`) se borró el
  05/10/2026: ya estaba absorbida en §1–§4.

---

## 13. 🕵️ Documentos de diagnóstico e incidentes

Cuando una fase documenta un fallo real —y varias lo hacen—, la estructura es
esta:

1. Síntoma, en palabras de quien lo sufre.
2. Pasos de reproducción exactos, con versiones, motor, arquitectura y host.
3. Evidencia observable: salida literal del comando, logs, `docker inspect`,
   códigos de salida.
4. Capa sospechosa: host, motor, imagen, contenedor, volumen, proyecto.
5. Hipótesis falsable y la prueba que la confirma o la descarta.
6. Causa raíz, hasta la línea del `Dockerfile` o el paquete concreto.
7. Corrección aplicada, distinguiendo parche mínimo de solución estructural.
8. Prevención: comprobación, pin, script de validación o checklist.

Dos reglas de método que atraviesan todo el curso y que conviene repetir en
estos documentos: **una variable a la vez** y **reproducir antes de reparar**.
Y los anti-patrones de diagnóstico se nombran sin piedad: `chmod -R 777`,
`--privileged`, borrar `package-lock.json`, `docker system prune -a --volumes`
como primer reflejo, o reinstalar Docker esperando que la fe resuelva el
problema.

El tono acá baja un punto de humor. Un análisis de causa raíz es sereno y
analítico —no acartonado, pero tampoco el lugar para el chiste.

---

## 14. ✅ Checklist antes de dar por cerrado un `.md`

- [ ] Tiene título descriptivo y bloque de metadatos completo (§7.1).
- [ ] Sigue la plantilla de fase (§8), con Partes si es una fase larga.
- [ ] Tono semi formal y cálido, tuteo latinoamericano, humor con moderación.
- [ ] Explica el problema antes que la herramienta, y el porqué de cada decisión.
- [ ] **Ningún comando queda sin explicar.** Ni las opciones.
- [ ] Prosa antes que listas; listas antes que tablas en comparativas extensas;
      diagramas en Mermaid donde hay capas o flujo, y `text` solo para lo que no
      es diagrama (§3, §16.1).
- [ ] Sin prosa telegrama: como mucho una o dos frases aisladas por sección, el
      resto en párrafos (§3).
- [ ] Todos los comandos corren con las versiones fijadas de §5.2, sin rangos ni
      `latest`.
- [ ] **Todo lo ejecutable y versionable en inglés**, **todos los comentarios en
      español** (§5).
- [ ] Nombres de archivos, scripts, tags y variables coherentes con las fases
      anteriores (§12).
- [ ] Se recuerda la condición EOL y se aclara que esto no es producción (§6).
- [ ] Los errores se muestran con su salida real antes de corregirlos.
- [ ] Marca 💸 la deuda intencional (con destino) y 🔥 lo opcional.
- [ ] Tiene **entre 20 y 35 ejercicios obligatorios**, con la cifra justificada por
      lo que la fase enseña (§9) y no heredada de la fase anterior; rangos 🟢🟡🟠🔴
      equilibrados en proporción y **distintos de los de la fase vecina**; más 🔥 y
      💀 **si la fase los pide** (esos dos no cuentan para el mínimo); al menos un
      tercio de diagnóstico; cada uno con su `Objetivo:` o `Pregunta:`.
- [ ] Ningún ejercicio gradúa con `⭐`: esa escala es residuo y se convierte a
      🟢🟡🟠🔴🔥💀 con criterio (§9).
- [ ] Checklist de validación ejecutable antes del cierre.
- [ ] Referencias con URL completa, agrupadas por tema, con advertencia cuando
      apunten a una versión distinta de la que usamos.
- [ ] Diferencias Docker/Podman verificadas, no asumidas (§11).
- [ ] Incluye "La señal de que quedó bien" en el cierre.

---

## 15. 📌 Pendientes que afectan a esta guía

Anotados acá para no bloquear la escritura, pero conviene resolverlos:

- 🪦 **`README.md` del curso. Resuelto:** existe y presenta el curso, sus dos
  partes y las rutas de entrada. El índice completo sigue siendo
  `0-programa-del-curso.md`, y el `README.md` remite a él.
- 🪦 **Numeración de secciones heterogénea. Resuelto:** con fases de 3.000–5.000
  palabras, **las Partes en romanos desaparecen del tronco**. La regla que rige
  desde ahora es la de §8: `##` numerado plano por defecto, y Partes solo por
  encima de ~4.000 palabras, que en la práctica es casi ninguna fase. Las Partes
  de los documentos viejos no se heredan al cortar.
- 🪦 **Ejercicios en las fases conceptuales. Resuelto** en §9, ahora con las fases
  nombradas: quedan exentas **F00**, **F01**, **F34** y **F35**. El resto mantiene
  el mínimo de 20 obligatorios.
- 🪦 **Escala de dificultad. Resuelto** en §7.2 y §9: 🟢🟡🟠🔴 obligatorios, más 🔥 y
  💀 fuera del mínimo, con la banda de cantidad y el reparto en proporciones.
- 🪦 **El tercer significado de `⭐`. Resuelto** en §7.2: se midió el árbol y `⭐` no
  aparecía en **ningún** documento publicado fuera de F35, así que el sentido de
  "pieza central" estaba declarado y muerto. Se retira, y `⭐` queda como escala de
  valoración bibliográfica de F35 y nada más.
- 🪦 **Apéndices. Resuelto:** `prompts/propuesta-fases-y-alcance.md` §5 define
  dieciséis, todos opcionales, con su origen y su volumen. Siguen el formato de
  apéndice de §8.
- 🪦 **`src/`. Resuelto:** el código ejecutable del curso vive en
  `src/NN-nombre-de-fase/`, con la estructura de la raíz del laboratorio del
  estudiante, y se duplica en `src/all-dockerfiles/` para quien quiera leer los
  Dockerfiles seguidos. La convención completa está en §5.1.

El curso está cerrado y no tiene plan de producción: lo que queda abierto está en
§16.4. Esta guía no lleva backlog.

---

## 16. 🧾 Excepciones a los lineamientos del repositorio

> 📝 **Sección agregada el 05/10/2026**, en la revisión del curso contra los
> lineamientos de producción del repositorio. Va después del checklist para no
> renumerar: el resto del `prompts/` y `check-course.sh` citan esta guía por
> número de sección. El curso es anterior a esos lineamientos; casi todo lo que
> aquí se declara ya era su práctica, y desde ahora está escrito como decisión.

El `CLAUDE.md` del repositorio da **valores por defecto**, y esta guía los
reemplaza donde lo declara: la regla general, el valor de este curso y por qué.
Lo que esta sección no menciona se hereda tal cual.

| Regla general del repositorio | Lo que hace este curso | Por qué |
|---|---|---|
| Comentarios dentro del código en inglés | **En español** (§5); identificadores, rutas y tags en inglés | El comentario es el canal del *porqué*, y el curso piensa en español |
| Audiencia que no necesita lo básico | **Nada se da por sabido** (§4): ni Docker, ni Linux | El lector llega por un proyecto roto, no por Docker; el README pide un lenguaje y terminal, nada más |
| Forma de lección setup → conceptos → antipatrones → traducción → ejercicios → veredicto | **La plantilla de diez secciones de §8**, cerrada con «La señal de que quedó bien» | Es un taller incremental sobre una sola imagen. El veredicto honesto no es por fase: F00 §7 y §9 fijan dónde no sirve (producción, migrar el proyecto) y F23 decide entre ARM64 nativo y AMD64 emulado |
| 20–30 ejercicios por sección, 🟢🟡🟠🔴 | **20 a 35 obligatorios** con 🔥 y 💀 encima, y cuatro fases exentas (§9). Publicado: de 20 a 30 | La cifra la fija lo que la fase enseña; 35 es el techo, no la meta |
| Ejercicios con solución de referencia o rúbrica | **Sin solucionario**: cada ejercicio cierra con `Objetivo:` o `Pregunta:`; solo F34 trae rúbrica | Decisión de la propuesta §8, tomada al cortar el curso; la autoverificación es esa línea |
| `0-ESTRUCTURA-CURSO.md` antes de la primera lección | **`0-programa-del-curso.md`**, con las rutas de lectura por perfil | El curso lo escribió con ese nombre y lo citan el README y las entradas de Parte; renombrarlo rompe el bloqueo de contenido |
| `BENCHMARKS.md` e `INSTINTOS.md` | **No existen.** Las mediciones van en su fase, con condiciones declaradas (F23, F26); los instintos, en las Notas de época | El curso mide poco y en contexto; un documento aparte quedaría casi vacío |
| Diccionario de traducción en los dos sentidos | **No aplica**: no hay paradigma de origen. Hace su papel el glosario (a16) | El curso enseña un entorno, no traduce de otro |
| Diagramas a criterio de quien escribe | **Mermaid**, con las excepciones de §16.1 (D-12) | Pedido explícito del autor en la revisión del 05/10/2026 |
| Fecha de vigencia en cada encabezado | **Solo donde hubo verificación ejecutada** (ocho documentos) o revisión de documentación externa (§7.1) | Una fecha en un documento que no se reverificó promete algo que no se hizo |
| Emoji en `###` con moderación | **Igual**, y además los títulos de ruta y de bloque de `0-programa-del-curso.md` y de las entradas de Parte | Son navegación, no adorno |
| `.gitignore` centralizado | **En la raíz del curso**, porque hay código en `src/` de varias fases | Se sostiene solo, para cuando el curso viaje a su propio repositorio |

### 16.1 D-12 · Diagramas en Mermaid

**Decidido el 05/10/2026 por el autor, en la revisión del curso.** Todo
diagrama —arquitectura, flujo, secuencia, estados, árbol de decisión, capas— va
en un bloque `mermaid`. Se quedan en `text` los árboles de archivos, las salidas
de terminal, los checklists, las fichas de «Resultado de la fase» (`IMAGEN …`,
`SABES …`), las comparativas en dos columnas, las correspondencias `a → b`, las
líneas de tiempo y la anatomía de un nombre: no son diagramas, y alineados en
monoespaciado se leen mejor.

La revisión convirtió **58 diagramas en 36 documentos**, y cada uno se dibujó con
`mmdc` antes de publicarlo. Tres criterios para los que vengan:

- **`flowchart TD`** para cadenas y árboles de decisión; **`LR`** para lo que
  cruza la frontera host ↔ contenedor; **`subgraph`** para las zonas (host,
  contenedor, VM).
- **`stateDiagram-v2`** para el ciclo de vida de un contenedor (F08, F16) y
  **`sequenceDiagram`** para lo que ocurre en el tiempo (`docker stop` en F16).
  Al convertir el de F16 se corrigió un error del ASCII: `start` sobre un
  contenedor `Exited` lo lleva a `Running`, no a `Created`.
- **Caracteres que Mermaid interpreta**: `<…>` se escribe `#lt;…#gt;`, `|`
  dentro de un nodo `#124;` y `#` delante de una palabra `#35;`. Las rutas de
  Windows se escriben tal cual dentro de comillas.

### 16.2 Documentos de `prompts/` y lo que hace su papel

El curso es anterior a las plantillas de producción y está cerrado, así que no
se crean a posteriori. Esto es lo que cumple cada función:

- **Alcance y propuesta:** `propuesta-fases-y-alcance.md`, que es a la vez el
  alcance (qué entra y qué no en cada fase) y la propuesta. Sus cifras de
  palabras y de ejercicios son las del 03/09/2026, antes de escribir; las
  vigentes están en el README.
- **Plan de producción:** no hay. Lo fue `ajuste_estructura.md`, que se borró el
  05/10/2026 como desechable: la migración que describía ya estaba ejecutada y
  sus decisiones viven en la propuesta y en esta guía.
- **Diccionario de términos:** §3 (qué se queda en inglés) y el glosario a16.
- **Contrato de nombres:** §5.1 (archivos, imagen, tags, scripts) y §5.2
  (versiones fijadas).
- **Plantillas de capítulo:** §8 (fase), §8 al final (apéndice) y §9 (ejercicios).
- **Formatos propios:** §13 (incidentes), y en `src/` las plantillas que usa el
  lector: `VALIDATION-REPORT.template.md` (F11) y `30-TROUBLESHOOTING-REPORT.md`
  (F30).
- **Prompts de fase:** no se conservaron; el curso ya no se escribe por fases.
- **Callouts heredados:** seis de un solo uso (🥇, ⚔️, 🛑, 🥊, 🗓️, 🧾) quedan
  como están; el verificador los tolera y no se usan en texto nuevo.

### 16.3 Verificación

Tres herramientas, desde la raíz del curso, y ninguna toca Docker:

```bash
python3 prompts/verificar-corpus.py                 # validaciones base + aviso DIAGRAMA
python3 prompts/verificar-corpus.py --publicacion   # además, lo que exige el repositorio público
bash prompts/check-course.sh                        # las trece comprobaciones de integridad
```

- `verificar-corpus.py` es la subclase del perfil `courses-ia` de
  `verificador_base.py` (copia de la base de los lineamientos), con los callouts
  de §7 y el encabezado de §7.1. Su aviso `DIAGRAMA` marca un bloque `text` con
  esquinas de caja o flechas verticales; un diagrama dibujado solo con `├─` y
  `│` se le escapa, y se revisa a mano.
- `--publicacion` agrega los errores de la etapa de publicación: ningún enlace a
  `prompts/` ni mención de material privado en un documento publicado.
- `check-course.sh` cubre lo que la base no ve: ejercicios numerados y su
  conteo, la banda de §9, las citas `FNN §x.y`, los punteros a `src/` y el
  índice contra el árbol. Su explicación está en `explicacion_script_integridad.md`.

### 16.4 Lo que queda abierto

- **El apéndice a17, compilar Node desde fuente**, está diseñado pero no
  escrito: el curso publica salidas reales y hace falta una sesión de
  laboratorio antes. El protocolo está fuera del curso, en el borrador de
  complemento de `propuestas-cursos/`, y ningún documento publicado lo enlaza.
- **Los comandos `podman` de F24, F25 y F26** están contrastados con la
  documentación oficial, no ejecutados, y sus cabeceras lo declaran.

Los dos se cierran en la pasada del autor como lector: tomar el curso desde
cero, montar todos los contenedores y rehacer todas las pruebas. Sus reglas,
lo que pide atención en cada tramo y dos decisiones que esperan al autor (el
solucionario y la matriz de F11) están en
[`pendientes-a-futuro.md`](pendientes-a-futuro.md).
