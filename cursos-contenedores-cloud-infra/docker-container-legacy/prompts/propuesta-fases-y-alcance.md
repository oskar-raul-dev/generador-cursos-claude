# 🗺️ Propuesta de fases, apéndices y alcance

Documento de encuadre del curso **Docker Legacy Node**. Reparte las ~219.000
palabras ya escritas en dos partes, 36 fases cortas y 16 apéndices opcionales.

> **Estado:** aprobada y **ejecutada**. Las 36 fases y los 16 apéndices existen. Este
> documento queda como la **especificación del alcance**: qué entra en cada fase y qué no.
> La revisión del 3/09/2026 midió el corte real: F08 se partió en dos y el curso pasó de
> 35 a 36 fases (ver §3)
> **Punto de partida:** 20 documentos, 82.700 líneas, ~219.000 palabras
> **Problema que resuelve:** cuatro documentos superan las 17.000 palabras (~70
> páginas cada uno) y mezclan el camino mínimo con la enciclopedia de producto
> **Fecha:** 3 de septiembre de 2026
> **Revisión del 05/10/2026:** este documento hace también de alcance del curso
> (guía §16.2). Las cifras de palabras, horas y ejercicios son las del corte, antes de
> escribir: las vigentes están en el README. En particular, §1 y §8 dicen **20 ejercicios
> por fase práctica**, y la guía §9 los recalibró después a una banda de 20 a 35 decidida
> fase por fase. `ajuste_estructura.md`, el plan que ejecutó este corte, se borró ese día
> como desechable.

---

## ✅ 1. Decisiones cerradas

Estas ya no se discuten en los chats siguientes.

| Pregunta | Decisión | Qué cambia |
|---|---|---|
| ¿Un curso o dos? | **Dos partes de un mismo curso**, numeración continua | La Parte I se puede tomar sola; la Parte II asume la Parte I hecha |
| ¿Qué es la Parte I? | **Taller**: de cero a proyecto legacy corriendo | **12 fases**, ~39.000 palabras |
| ¿Qué es la Parte II? | **Laboratorio**: cómo funciona todo por dentro | 24 fases (F12–F35), ~74.000 palabras |
| Nivel de profundidad | **Full geek, sin diluir** | Es la identidad del curso; lo que se recorta es exhaustividad de producto, no profundidad de mecanismo |
| Cobertura de productos | **A apéndices opcionales** | Harbor, GitLab, GHCR, WebStorm, Colima/Lima, Windows, air-gapped, CI |
| Tamaño objetivo de fase | **3.000–5.000 palabras** | Ninguna fase pasa de 5.000 salvo el documento de referencias. **Es lo que obligó a partir F08** |
| Numeración | **Continua `NN-tema.md` (00–35)**, apéndices `aNN-tema.md` | El directorio se ordena solo |
| Ejercicios | **20 por fase práctica**, se mantiene | Al partir una fase, sus 20 ejercicios se reparten y se completan |
| Examen del curso | **F34, proyecto final**, fase de la Parte II | No es un apéndice ni un anexo: cierra el curso y es evaluable |
| Ritmo de la prosa | **Pasada de compactación** al reescribir cada fase | Las frases sueltas de tres palabras se agrupan en párrafos |
| Soluciones y rúbricas | **Al final del proyecto** | Casi ningún curso del catálogo las tiene; se decide en el README general |
| Código ejecutable | **`src/NN-nombre-de-fase/`** | Ya fijado en la guía de estilo §5.1 |

### La tesis que ordena la división

El curso responde dos preguntas distintas a dos lectores distintos:

```text
"Necesito que este proyecto de 2018 compile hoy."
        → Parte I. Termina con el proyecto corriendo.

"¿Por qué funciona esto, y qué hago cuando no funcione?"
        → Parte II. Termina con criterio para diagnosticar solo.
```

Hoy las dos conversaciones están mezcladas dentro de los mismos archivos. Un
lector que solo quiere la primera tiene que atravesar PID namespaces, `binfmt_misc`
y manifests OCI para llegar a `npm ci`. Esa es la fricción que esta propuesta
elimina, **sin borrar una sola línea de la segunda conversación**.

---

## 📊 2. Reparto por volumen

Las palabras están medidas sobre el material existente. Las horas son
**estimaciones derivadas del volumen**, no medidas: sirven para planificar, no
para prometer.

| | Fases | Palabras | Horas est. |
|---|---|---|---|
| **Parte I — Taller** | 12 (00–11) | ~39.000 | 24h |
| **Parte II — Laboratorio** | 24 (12–35) | ~74.000 | 63h |
| **Apéndices** | 16 (a01–a16) | ~55.000 | — |
| **Ejercicios, checklists y cierres** | repartidos | ~45.000 | — |
| **Total** | **36 fases + 16 apéndices** | **~219.000** | **87h + consulta** |

Las horas de apéndices no cuentan: son consulta bajo demanda.

---

## 🧰 3. Parte I — Taller: un contenedor para tu proyecto legacy

**Objetivo:** al terminar la Fase 11, el lector tiene su proyecto legacy real
—Vue 2, Angular 8, React 16, Svelte 3 o lo que le hayan dado— instalando,
compilando, testeando, corriendo y depurando dentro de un contenedor, con el
código viviendo en su host.

**Lo que NO entra en la Parte I:** PID namespaces, OverlayFS, ABI, QEMU,
registries, OCI, Podman comparado, supply chain, forense. Todo eso existe y está
escrito; vive en la Parte II.

### 🧭 F00 — El problema y el contrato del laboratorio (~2.600)

**Origen:** `00-objetivos-y-restricciones.md`, comprimido.

Entra: el problema del ambiente perdido, la regla que ordena todo —**el
contenedor contiene el toolchain, no el proyecto**—, plataformas soportadas,
convención de comandos Docker/Podman, criterios de éxito y qué queda fuera.

🆕 **Sección nueva y obligatoria:** Node no publicó binarios `darwin-arm64` hasta
la rama 16.x. En un Mac con Apple Silicon, **Node 14, 12 y 10 no se pueden
instalar nativamente**. Es el argumento de una línea que convierte al contenedor
de comodidad en único camino razonable, y hoy no está escrito en ninguna parte
del curso aunque la Fase 08 tenga la evidencia a la vista.

Sale: el detalle de Cypress y Selenium (→ **a09**), los dos niveles de WebStorm
(→ **a06**).

### 🧱 F01 — Decisiones cerradas: Debian, zonas y Node (~4.500)

**Origen:** fusión comprimida de `01-seleccion-de-debian.md` (1.583),
`02-arquitectura-de-la-imagen.md` (2.128) y lo esencial de
`03-estrategia-node-y-clis-final.md` (5.657).

Entra, en una página por tema y con el porqué: por qué Debian 10 y no 11, 9,
Ubuntu o Alpine; qué es `debian/eol:buster` y por qué apunta al archivo
histórico; las tres zonas del laboratorio (host, imagen, contenedor); dónde vive
`node_modules` y por qué en un named volume; las cuatro versiones de Node
baseline; y por qué las CLIs pertenecen al proyecto y no a la imagen.

Sale a **a02** la discusión larga: por qué no `nvm`, por qué no NodeSource, por
qué no compilar desde source, riesgos de la emulación, `PATH`, `npx`, Yarn.

> 🧭 Esta fase es **de decisiones, no de construcción**. El lector no ejecuta
> nada: entiende el terreno. Es la que más se comprime respecto al original.

### 🐳 F02 — Dockerfile: las instrucciones esenciales (~4.200)

**Origen:** `04-dockerfile-final.md` líneas 1–1086 y 1869–final.

Entra: Dockerfile ≠ imagen ≠ contenedor, build time vs runtime, `FROM`, `RUN`,
`CMD`, `ENTRYPOINT`, `WORKDIR`, `COPY`, `ADD`, `ARG`, `ENV`, `LABEL`, `USER`,
forma shell vs exec, la convención incremental `dockerfiles/NN-tema.Dockerfile`
y el primer Dockerfile del curso.

Sale: root vs non-root (→ **a05**), build context, `.dockerignore`, capas, caché
y `--platform` (→ **F07** y **F11**).

### 📦 F03 — APT y la caja de herramientas (~4.000)

**Origen:** `05-utilidades-linux.md`, Parte I comprimida + Partes II, III y IV.

Entra lo operativo de APT: `update` e `install` en el mismo `RUN` y por qué,
`-y`, `--no-install-recommends`, la limpieza de `/var/lib/apt/lists` en la misma
capa y su consecuencia. Después los doce paquetes de la caja de herramientas y
Bash como shell del laboratorio.

🆕 **Sección nueva:** por qué `apt-get update` funciona sobre un archivo cuyo
`Release` está firmado con fecha expirada. `debian/eol:buster` trae
`/etc/apt/apt.conf.d/check-valid-until.conf` y
`debuerreotype-gpgv-ignore-expiration`, y eso es exactamente lo que el curso
promete explicar y hoy no explica.

Sale a **a01** el tratado: `apt` vs `apt-get` vs `apt-cache` vs `dpkg`, mirrors,
anatomía del `sources.list`, `Depends`/`Recommends`/`Suggests`, dependencias
transitivas, índices vs archivos descargados.

### 🛠️ F04 — Toolchain de compilación (~3.000)

**Origen:** `06-toolchain-de-compilacion.md` Partes I–IV, VI–XIII, XV–XVII.

Entra: por qué un proyecto JavaScript necesita un compilador, `build-essential`
y qué arrastra, GCC y G++ en versión rápida, `make` con un Makefile mínimo,
`pkg-config`, `file`, el Dockerfile de la fase y el hola mundo en C dentro del
contenedor.

Sale: GNU Binutils (`ld`, `ar`, `nm`, `objdump`, `readelf`) → **a03**. El puente
hacia `node-gyp` (Parte XIV, 1.248 palabras) se funde con **F05**, que es su
sitio natural.

### 🐍 F05 — Python y node-gyp (~4.500)

**Origen:** `07-python-y-node-gyp.md` casi entero + `06` Parte XIV.

Entra: por qué aparece Python en un proyecto Node, Python 2 y 3 en Debian 10,
`node-gyp` sin magia negra, la tabla de compatibilidad Python ↔ `node-gyp`, cómo
se selecciona el intérprete, `binding.gyp`, el Dockerfile de la fase y los
errores típicos.

Se comprime: la Parte XII *"Qué NO hacemos todavía"* (1.086 palabras) baja a una
lista con destino explícito.

### 🟢 F06 — Instalar Node: cuatro generaciones (~4.500)

**Origen:** `08-instalacion-node.md` Partes I–IV, VI–XIII, XV–XVIII.

Entra: las cuatro generaciones baseline y su EOL, por qué tarballs oficiales y
no APT / NodeSource / `nvm` / `FROM node:10`, anatomía del nombre del archivo,
`--strip-components=1`, la estructura `/opt/node`, parametrizar con `ARG`,
`select-node` y los shims, y validar las cuatro instalaciones.

Sale: la Parte V completa —checksums, SHA-256, `SHASUMS256.txt`, firmas GPG— a
**a04**, dejando en la fase solo la verificación operativa que el build ejecuta.
La Parte XIV (2.698 palabras, la deuda de `node-gyp`) se reparte entre **F05** y
**F13**.

### 🏗️ F07 — Build: construir la imagen (~3.500)

**Origen:** `10-build.md` Partes I–V, XII, XIII, XV.

Entra: el modelo mental del build, el nacimiento del `Dockerfile` canónico, el
build context y el `.dockerignore`, el primer build canónico, BuildKit y Buildx
en versión introductoria, multi-stage mencionado, y el flujo de build
recomendado.

Sale a **F11**: caché en profundidad, capas por dentro, tags/IDs/digests,
reproducibilidad y build args.

### ▶️ F08 — Run: el contenedor como proceso (~4.000)

> 🔀 **Fase partida el 3/09/2026.** La F08 original recibía **8.914 palabras** para un
> objetivo de 4.500 —las once Partes de aquí más tres huérfanas del documento original—
> y ni comprimiendo un 25% bajaba de 6.400. Es la única de
> las 35 fases originales que no cabía en el límite de 5.000 que fija §1. Se parte en
> **F08** y **F09** por la juntura natural del material: el contenedor como proceso, y el
> contenedor como sitio donde vive tu proyecto.

**Origen:** `11-run.md` Partes I, II, III, V, XIII, XVIII, XXIV (4.600 palabras).

Entra: modelo mental de `docker run`, crear no es ejecutar, los shims despachadores de
Node y por qué reemplazan a `select-node` en runtime, `ENTRYPOINT` y `CMD` —quién manda
al arrancar, shell form vs exec form—, foreground contra detached, `-i`, `-t` y `-it`,
`--rm`, `docker exec` como proceso nuevo y no como "entrar en la VM", la matriz de Node
en runtime y el modelo mental final de qué ocurre cuando ejecutas `docker run`.

Sale a la Parte II: PID 1 y señales (**F16**), ciclo de vida completo, restart policies y
límites de recursos (**F16**), `docker attach` (**F18**).

### 💾 F09 — Montar tu proyecto: volúmenes y laboratorio end-to-end (~3.800)

**Origen:** `11-run.md` Partes VI, IX, X, XX, XXI, XXII, XXIII (4.314 palabras). 🆕 Fase
nueva por el corte de F08.

Entra: bind mounts y named volumes —código aquí, `node_modules` allá, y por qué un
volumen por versión de Node—, `--mount` frente a `-v`, working directory, variables de
entorno y por qué un `.env` no es un secret store, el Dockerfile canónico de la fase, el
laboratorio end-to-end que junta todo lo anterior, los scripts auxiliares
(`run-dev.sh`, `run-dev.ps1`) y los errores clásicos de `docker run`.

Sale: UID/GID y los archivos que vuelven con dueño equivocado (**F17**), networking y
publicación de puertos (**F18**), el quoting de PowerShell (**a08**), y el catálogo
completo de fallos de runtime (**F31**).

> 🧭 **La frontera entre las dos:** F08 termina cuando sabes arrancar, parar e
> inspeccionar un contenedor. F09 empieza cuando quieres meter tu código dentro.

### 🟦 F10 — VS Code y debugging (~3.500)

**Origen:** `13-ides.md` Partes I–VI, XVI, XVIII, XIX.

Entra: IDE, runtime y proyecto como tres responsabilidades distintas; VS Code
Modo A (editor en el host, Docker a la vista); tasks; Node Inspector y el
debugger conectado al contenedor; source maps; por qué Node no es Chrome; "IDE
roto" vs "proyecto roto"; y qué se versiona en Git.

Sale: Dev Containers completo → **F19**. UID/GID y `EACCES` → **F17**.
WebStorm → **a06**.

### 🧪 F11 — Validar tu proyecto legacy (~4.000)

**Origen:** `12-validacion-de-proyectos.md` Partes I, IV, V, VI, VII, VIII, XVI, XIX.

Entra: qué significa "compatible", la estructura de laboratorios, el fixture de
control sin framework, cómo se construyen los fixtures, el protocolo de
validación paso a paso, watch y HMR con polling, el Validation Report y el
checklist de cierre.

✅ **Prerequisito resuelto:** los cinco fixtures ya existen en
`src/10-validar-tu-proyecto/` con sus lockfiles congelados y validados con `npm ci` +
build + test. Al escribir la fase, el directorio se renombra a
`src/11-validar-tu-proyecto/` para seguir el número nuevo.

Sale a **F20**: arqueología previa, evidencia y logs, matriz de compatibilidad,
fallos provocados, método de reducción, `npm cache`/`audit`, reproducibilidad.

---

## 🔬 4. Parte II — Laboratorio: contenedores por dentro

**Objetivo:** que el lector entienda el mecanismo debajo de cada comodidad y
pueda diagnosticar solo. **24 fases, F12 a F35.**

### 🧬 F12 — Capas, caché y contexto de build (~4.500)
`10-build.md` Partes III, VI, VII, IX, X, XIV. Caché de verdad, capas por
dentro, tags vs IDs vs digests, hasta dónde llega la reproducibilidad, build args
y troubleshooting de build.

### 🪟 F13 — OverlayFS y copy-on-write (~2.500) 🆕
> ✅ **Ya escrita** el 3 de septiembre de 2026 como
> `19-overlayfs-y-copy-on-write.md` (numeración provisional). Al ejecutar el
> corte se renombra a `12-overlayfs-y-copy-on-write.md` y se le escriben los
> ejercicios con el reparto general.

**Fase nueva.** Es el hueco técnico más llamativo del curso actual: hay una Parte
entera dedicada a *"Capas: mirar dentro del fósil"* que explica las capas como
diffs en tar y nunca dice cómo se montan juntas en runtime. Entra: `lowerdir`,
`upperdir`, `merged`, whiteouts, dónde vive la writable layer, por qué escribir
en un bind mount no la toca, y qué implica todo eso para el tamaño de la imagen.

### 🧩 F14 — ABI, libc y prebuilds (~2.700)
`09-dependencias-nativas.md` Partes I–VII. Los cuatro casos de "dependencia
nativa", API vs ABI, `NODE_MODULE_VERSION`, glibc vs musl, prebuilds,
`node-pre-gyp`, caches y las herramientas de disección.

### 🌈 F15 — Laboratorios de dependencias nativas (~3.700)
`09` Partes VIII–XIV. `node-sass`, `canvas`, `sqlite3`, Puppeteer + Chromium,
estudios de caso y la política de reparación que no destruye la evidencia.

### 🧟 F16 — PID 1, señales y ciclo de vida (~3.100)
`11-run.md` Partes IV, XV, XVI, XVII. PID namespace, semántica especial de PID 1,
`SIGTERM`, zombies, `exec "$@"`, ciclo de vida completo, restart policies y
límites de recursos.

### 👤 F17 — Usuarios, permisos y volúmenes (~2.900)
`11` Parte VIII + `13` Parte XI + la parte de UID/GID y SELinux de `15` Parte XI.
Root, UID, GID, archivos que vuelven del contenedor con dueño equivocado,
`EACCES`, ownership de un named volume recién creado, `--user`, `:U` de Podman.

### 🌐 F18 — Networking de contenedores (~2.500)
`11` Partes XI, XII, XIV + la parte de red de `15` Parte X. Por qué el contenedor
no vive en tu `localhost`, publicación de puertos, redes, DNS interno, logs,
`attach` vs `exec`.

### 📦 F19 — Dev Containers (~3.300)
`13` Partes VII–XIII, XV, XVII. El contenedor como ambiente del IDE, extensiones
host vs contenedor, tasks y debugging desde dentro, el socket de Docker y por qué
aparece en los tutoriales, Git dentro del Dev Container, y la comparación honesta
de los dos caminos.

### 📜 F20 — Validación sistemática y evidencia (~3.400)
`12` Partes II, III, IX–XV, XVII, XX. Arqueología controlada antes de ejecutar,
logs que sirven para investigar (incluido el `PIPESTATUS` de `npm ci | tee`),
matriz de compatibilidad, fallos provocados, reducción del problema, y qué
prometemos de reproducibilidad.

🆕 **Añadido:** matriz reducida del fixture de control × las cuatro versiones de
Node. Hoy el curso valida solo Node 10.24.1 y deja las variantes 12/14/16 sin
ninguna validación ejecutada.

### 🧠 F21 — Arquitecturas, OCI multi-platform y emulación (~3.700)
`14-multiplataforma.md` Partes I–VIII. Arquitectura de CPU sin diseñar silicio,
por qué AMD64 sigue siendo el baseline, las seis dimensiones de portabilidad, un
tag con varias imágenes, build platform vs target platform, el Dockerfile
multiarch, y QEMU con `binfmt_misc`.

### 🍎 F22 — Apple Silicon y el zoológico de hosts (~2.400)
`14` Partes IX, X, XI, XV, XVI. El laboratorio principal en Apple Silicon, Docker
Desktop, Podman Desktop, `node_modules` cuando la arquitectura entra en el
nombre, y la clasificación multiplataforma de dependencias npm.
Colima y Lima → **a07**. Windows 11 → **a08**.

### 🧪 F23 — Estudios de caso y árbol de decisión (~2.900)
`14` Partes XVII–XXIII. `node-sass` y `canvas` en ARM64, matriz de validación
real, microbenchmarks sin vender humo, árbol de decisión y troubleshooting
multiplataforma.

### 🐳 F24 — Docker y Podman: dos arquitecturas (~4.700)
`15-docker-vs-podman.md` Partes I–IV, VI–IX, XIV, XV. Comparar sin hacer fútbol,
cliente/daemon vs fork-exec, OCI como terreno común, compatibilidad de CLI que no
es identidad, APIs y sockets, Buildah frente a BuildKit, los dos almacenes
locales, pods, y Compose mencionado sin esconder los fundamentos.

### 🔐 F25 — Rootless y user namespaces (~2.100)
`15` Partes V, XVI, XVII. Rootful vs rootless, user namespaces, qué gana y qué
cuesta cada modelo, threat model honesto, y por qué Engine no es Desktop.

### 🧭 F26 — Portabilidad entre motores (~4.400)
`15` Partes XII, XIII, XVIII–XXIII. Linux nativo vs Docker Desktop vs Podman
Machine, IDEs cuando la CLI funciona y el editor no, rendimiento medido,
scripts portables, validación del fixture en ambos motores, troubleshooting
cruzado y la matriz de decisión.

### 🧱 F27 — Registries por dentro (~3.600)
`16-publicacion.md` Partes I, III, IV, X. Qué es exactamente un registry,
digests como identidad de contenido, manifests, indexes, descriptors y blobs, e
inspección remota sin `pull` con Skopeo.

### 🚀 F28 — Publicar la imagen (~3.200)
`16` Partes II, V, VI, VII, IX, XI, XVII. Tags como nombres humanos, registry
local antes de tocar Internet, autenticación sin filtrar credenciales, Docker
Hub, publicación multi-platform, metadata OCI, retención y rollback.
GHCR y GitLab → **a11**.

### ✍️ F29 — Supply chain: SBOM, provenance y firma (~2.300)
`16` Partes XII–XV. Inventario de lo que metimos en la caja, cómo se construyó,
firma con Sigstore/Cosign, y la sección que evita que todo se vuelva sopa de
siglas.

### 🕵️ F30 — Troubleshooting: método y herramientas (~4.100)
`17-troubleshooting.md` Partes I, II, III, XVII. La chuleta de 60 segundos,
síntoma ≠ causa, taxonomía de capas, hipótesis falsables, una variable a la vez,
reproducir antes de reparar, los anti-patrones, la imagen de diagnóstico y
`diagnose-container.sh`.

🆕 **Corrección obligatoria al escribirla:** el script filtra `.Config.Env` en
claro vía `docker inspect` completo, anulando su propia redacción de secretos.

### 🧯 F31 — Catálogo de fallos I: engine, build, registry y red (~4.100)
`17` Partes IV, V, VI, VII, XIII.

### 🩺 F32 — Catálogo de fallos II: APT, Node, node-gyp, ABI y filesystem (~3.100)
`17` Partes VIII–XII.

### 💀 F33 — Forense avanzado y Boss Fight (~2.500)
`17` Partes XV, XVI, XVIII, XIX, XX, XXII. IDEs, Git y el host, forense
avanzado, matrices de síntomas y el Boss Fight final.

### 🏆 F34 — Proyecto final: un repo de 2019 sin instrucciones (~2.000) 🆕

**Fase nueva.** Es el examen natural del curso y hoy no existe: el Boss Fight de
F33 es de diagnóstico, no de construcción end-to-end.

El enunciado: *te entregan un repositorio de 2019 sin README, sin `.nvmrc` y sin
nadie a quien preguntarle. Produce la imagen, el reporte de validación y el
veredicto de compatibilidad.*

Entra: el enunciado con las restricciones, los entregables exigidos —imagen
reproducible, `VALIDATION-REPORT.md`, veredicto razonado y la lista de lo que no
se pudo resolver con su porqué—, la rúbrica de evaluación, y tres repos de
partida de dificultad creciente 🟡 🟠 🔴.

Recorre en un solo trabajo todo lo que el curso enseñó: arqueología del
`package.json`, elección de la generación de Node, construcción de la imagen,
`npm ci` con su evidencia, diagnóstico de lo que falle y decisión honesta sobre
qué queda fuera del alcance.

> 🧭 **Por qué es fase y no apéndice:** un apéndice es opcional por definición, y
> este es el punto donde el estudiante demuestra que el curso sirvió. Va numerado
> y cuenta en el calendario.

### 📚 F35 — Referencias y arqueología técnica (~14.000)
`18-referencias.md` sin cambios. Es un documento de consulta, no de lectura
lineal; su tamaño no es un problema porque nadie lo lee de corrido.

---

## 🎨 5. Apéndices

Todos **opcionales**. Ninguno es requisito de ninguna fase. Aquí vive lo
exhaustivo: el tratado que un lector agradece y que dentro de una fase la asfixia.

| Apéndice | Contenido | Origen | Palabras |
|---|---|---|---|
| **a01 Debian y APT a fondo** | `apt`/`apt-get`/`apt-cache`/`dpkg`, mirrors, `sources.list`, `Depends`/`Recommends`/`Suggests`, dependencias transitivas, índices vs archivos | `05` Parte I | ~1.800 |
| **a02 Estrategia Node y CLIs a fondo** | Por qué no `nvm`, NodeSource, source ni `FROM node:10`; `PATH`; `npx`; Yarn; riesgos de emulación; parametrización | `03` | ~4.000 |
| **a03 Binutils y anatomía ELF** | `ld`, `ar`, `nm`, `objdump`, `readelf`, `ldd`, `file` sobre binarios reales | `06` Parte V + `09` Parte VI | ~600 |
| **a04 Checksums, GPG y máquinas del tiempo** | SHA-256, `SHASUMS256.txt`, firmas, `archive.debian.org`, `snapshot.debian.org`, Wayback | `08` Parte V + `18` §5 | ~1.500 |
| **a05 Non-root a fondo** | Usuario no-root, UID/GID, qué se rompe, cuándo vale la pena | `04` §28–33 | ~1.200 |
| **a06 WebStorm** | Nivel A integración nativa, Nivel B modo universal, por qué un IDE moderno puede no amar a Node 10 | `13` Parte XIV | ~1.000 |
| **a07 Colima y Lima** | VM Linux en macOS, perfiles, `virtiofs`, arm64 vs amd64, explicación full geek | `14` Partes XII–XIII | ~700 |
| **a08 Windows 11 y PowerShell** | WSL2, rutas, quoting en PowerShell frente a Bash y Zsh | `14` Parte XIV + `11` Parte VII | ~700 |
| **a09 Browsers legacy: Cypress y Selenium** | Cypress con Electron o Chromium fijado, Selenium en contenedor aparte, dependencias gráficas, ARM64 | `00` §14–16 + `09` Parte XI + `17` Parte XIV | ~1.200 |
| **a10 Docker Compose** 🆕 | Compose **después** de entender `docker run`, para el escenario multi-contenedor de Selenium. Cierra el bucle que abre F00 y nunca se cerraba | nuevo | ~1.500 |
| **a11 GHCR y GitLab Registry** | Los dos registries gestionados alternativos, con sus flujos de autenticación | `16` Partes VIII y VIII-B | ~1.000 |
| **a12 Harbor** | Registry empresarial: proyectos, cuotas, replicación, escaneo, políticas | `16` Parte XVI | ~1.350 |
| **a13 Distribución offline / air-gapped** | `save`/`load`, transporte, verificación en destino | `16` Parte XVIII | ~200 |
| **a14 CI con GitHub Actions** | Automatizar la publicación después de dominar el camino manual | `16` Parte XIX | ~1.200 |
| **a15 Chuleta de comandos** 🆕 | Una página imprimible. El curso tiene ~5.700 bloques de código y ninguna referencia rápida | nuevo | ~800 |
| **a16 Glosario** 🆕 | Imagen, contenedor, capa, digest, manifest, ABI, libc, namespace, cgroup, rootless… | nuevo | ~800 |

> 🧭 **Criterio para mandar algo a un apéndice:** si el texto enseña *cómo
> funciona un mecanismo*, se queda en la fase. Si enseña *cómo se usa un
> producto concreto*, se va al apéndice. Harbor es el caso de manual: un registry
> se entiende con uno solo bien diseccionado —manifest, index, descriptor, blob,
> digest—; los otros cinco son cobertura de catálogo.

---

## 🔀 6. Mapa de trazabilidad: de dónde sale cada cosa

Ningún contenido se pierde. Esta tabla es el contrato de la migración.

| Documento actual | Palabras | Se reparte en |
|---|---|---|
| `00-objetivos-y-restricciones.md` | 2.682 | **F00** · a09 · a06 |
| `01-seleccion-de-debian.md` | 1.583 | **F01** |
| `02-arquitectura-de-la-imagen.md` | 2.128 | **F01** · a09 |
| `03-estrategia-node-y-clis-final.md` | 5.657 | **F01** · **a02** |
| `04-dockerfile-final.md` | 8.346 | **F02** · F07 · F12 · **a05** |
| `05-utilidades-linux.md` | 10.646 | **F03** · **a01** |
| `06-toolchain-de-compilacion.md` | 6.711 | **F04** · F05 · **a03** |
| `07-python-y-node-gyp.md` | 7.632 | **F05** |
| `08-instalacion-node.md` | 11.466 | **F06** · F05 · F14 · **a04** |
| `09-dependencias-nativas.md` | 9.860 | **F14** · **F15** · a03 · a09 |
| `10-build.md` | 10.941 | **F07** · **F12** |
| `11-run.md` | 18.659 | **F08** · **F16** · **F17** · **F18** · a08 |
| `12-validacion-de-proyectos.md` | 10.988 | **F10** · **F20** |
| `13-ides.md` | 13.726 | **F09** · **F19** · F17 · **a06** |
| `14-multiplataforma.md` | 13.167 | **F21** · **F22** · **F23** · **a07** · **a08** |
| `15-docker-vs-podman.md` | 18.977 | **F24** · **F25** · **F26** · F17 · F18 |
| `16-publicacion.md` | 17.798 | **F27** · **F28** · **F29** · **a11** · **a12** · **a13** · **a14** |
| `17-troubleshooting.md` | 18.701 | **F30** · **F31** · **F32** · **F33** |
| `18-referencias.md` | 14.067 | **F35** · a04 |

### Contenido nuevo que hay que escribir

| Qué | Dónde | Palabras est. |
|---|---|---|
| ✅ Node sin binario `darwin-arm64` antes de la 16 | F00, reforzado en F06 y F22 | ~400 · **escrito 03/09/2026** |
| ✅ `check-valid-until.conf` y la firma vencida de APT | F03 | ~500 · **escrito 03/09/2026** |
| ✅ OverlayFS y copy-on-write | **F13**, fase completa | ~2.500 · **escrita 03/09/2026** en `19-overlayfs-y-copy-on-write.md`, sin ejercicios |
| Matriz del fixture de control × 4 versiones de Node | F20 | ~400 |
| Compose para el escenario Selenium | a10 | ~1.500 |
| Chuleta de comandos | a15 | ~800 |
| Glosario | a16 | ~800 |
| Documento de entrada de cada Parte | `README` de parte | ~1.000 |
| Proyecto final con rúbrica y tres repos | **F34**, fase completa | ~2.000 |
| 🆕 F09, la fase que nace del corte de F08 | **F09** | ~0 · es reparto, no escritura |
| | **Total nuevo** | **~9.900** |

Es decir: **el 95% del trabajo es reorganizar, no escribir**.

---

## 📁 7. Convención de nombres

Todo ordenable por nombre, dos dígitos en fases y apéndices:

```text
0-programa-del-curso.md          ← índice y cruce perfil × fases
00-PARTE-I-taller.md                  ← entrada de la Parte I
00-PARTE-II-laboratorio.md            ← entrada de la Parte II
00-problema-y-contrato.md
01-decisiones-debian-zonas-node.md
02-dockerfile-esencial.md
03-apt-y-utilidades.md
04-toolchain-de-compilacion.md
05-python-y-node-gyp.md
06-instalacion-node.md
07-build-de-la-imagen.md
08-run-el-contenedor-como-proceso.md      ← 🔀 antes «08-run-tu-proyecto»
09-montar-tu-proyecto.md                  ← 🆕 del corte de F08
10-vscode-y-debugging.md
11-validar-tu-proyecto.md
12-capas-cache-y-contexto.md
13-overlayfs-y-copy-on-write.md
14-abi-libc-y-prebuilds.md
15-laboratorios-dependencias-nativas.md
16-pid1-senales-y-ciclo-de-vida.md
17-usuarios-permisos-y-volumenes.md
18-networking-de-contenedores.md
19-dev-containers.md
20-validacion-sistematica-y-evidencia.md
21-arquitecturas-y-emulacion.md
22-apple-silicon-y-hosts.md
23-estudios-de-caso-multiplataforma.md
24-docker-y-podman-arquitectura.md
25-rootless-y-user-namespaces.md
26-portabilidad-entre-motores.md
27-registries-por-dentro.md
28-publicar-la-imagen.md
29-supply-chain-sbom-firma.md
30-troubleshooting-metodo-y-herramientas.md
31-catalogo-de-fallos-i.md
32-catalogo-de-fallos-ii.md
33-forense-y-boss-fight.md
34-proyecto-final.md
35-referencias.md
a01-debian-y-apt-a-fondo.md
a02-estrategia-node-y-clis.md
...
a16-glosario.md
src/00-problema-y-contrato/      ← solo donde aplique
src/02-dockerfile-esencial/
...
```

Notas:

- Se elimina el sufijo `-final` de `03-estrategia-node-y-clis-final.md`, que es
  residuo de borrador.
- La frontera entre partes **no va en el nombre del archivo**: va en el título
  del documento (`# 🐳 Parte I · Fase 02 — …`) y en `0-programa-del-curso.md`.
  Así el orden alfabético sigue siendo el orden de lectura.
- Cada fase que produzca código ejecutable tiene su `src/NN-mismo-nombre/`, según
  la guía de estilo §5.1.

---

## 🧪 8. Ejercicios

Se mantiene el contrato actual: **20 por fase práctica**, con rangos
🟢🟡🟠🔴 y al menos un tercio de diagnóstico.

Al partir un documento, sus ejercicios se reparten entre las fases herederas y
se completan hasta 20 en cada una. Los documentos con más ejercicios por escribir
son los que nacen de fases hoy gigantes: `11-run.md` aporta 20 y genera **cinco**
fases tras el corte de F08; `17-troubleshooting.md` aporta 19 y genera cuatro.

**Las fases de decisión** (F00, F01) y el documento de referencias (F35) quedan
formalmente exentos del mínimo de 20: su ejercicio natural es leer y decidir, no
ejecutar. **F34 también queda exento**, por la razón contraria: la fase entera es
un ejercicio. Esto hay que escribirlo en la guía de estilo §9, que hoy lo deja
ambiguo.

### 🪦 Soluciones y rúbricas

**Decisión tomada: se dejan para el final del proyecto.** Casi ningún curso del
catálogo las tiene, y bloquear la reestructuración por ellas sería caro. Cuando
se aborden, la decisión afecta a todos los cursos a la vez y por eso se documenta
en el **README general del repositorio**, no aquí.

Lo que sí se hace ahora, porque no cuesta nada: cada ejercicio conserva su línea
`Objetivo:` o `Pregunta:`, que es la única forma de autoverificación que el curso
tiene hoy.

---

## 🚦 9. Orden de ejecución propuesto

```text
1. Aprobar esta propuesta
2. Escribir 0-programa-del-curso.md (índice y rutas de lectura)
3. Parte I completa, en orden F00 → F11
   (los fixtures ya existen en src/10-validar-tu-proyecto/; se renombra a 11- al
   escribir la fase)
4. Apéndices que la Parte I necesita: a02, a05, a06
5. Parte II, en orden F12 → F35
   (F13 es contenido nuevo: se escribe entera)
6. Apéndices restantes
7. a15 chuleta y a16 glosario
8. README.md del curso
9. Soluciones y rúbricas (decisión de catálogo, README general)
   La rúbrica de F34 es la excepción: se escribe con la fase, porque sin ella
   el proyecto final no es evaluable.
```

**Riesgo principal de la migración:** las referencias cruzadas. El curso actual
se cita a sí mismo constantemente (*"esto lo vemos en la Fase 11"*, *"como
preparó la Fase 09"*). Con 20 documentos pasando a 36 + 16, cada una de esas
referencias hay que reapuntarla. Conviene hacer un barrido de `Fase NN` al
terminar cada parte, no al final de todo.

---

## 📌 10. Lo que esta propuesta NO cambia

- **La profundidad.** Ni una sola explicación de mecanismo se recorta. Lo que se
  mueve a apéndices es cobertura de producto.
- **El baseline técnico.** Debian 10 `debian/eol:buster`, Node 10.24.1 / 12.22.12
  / 14.21.3 / 16.20.2, npm 6.14.12, `linux/amd64` baseline con `linux/arm64`
  adicional. Verificado y funcionando; no se toca.
- **El reparto de Podman.** Está bien calibrado: 104 comandos en el documento que
  lo compara y entre 1 y 18 en los demás. No es un anexo olvidado ni una
  duplicación paralizante.
- **La convención de fixtures.** Volumen por proyecto **y** por versión de Node,
  `npm install` una vez para generar el lock y `npm ci` siempre después. Es
  correcto y está verificado.
- **El tono.** Semi formal, tuteo latinoamericano, humor con moderación, honesto
  sobre el EOL.

La guía de estilo cambia en dos puntos por esta propuesta:

- **§3** gana la regla de compactación: las frases sueltas de tres palabras
  separadas por líneas en blanco se agrupan en párrafos. Funcionan como golpe de
  ritmo en dosis pequeñas; usadas en cadena convierten la prosa en telegrama.
- **§9** declara la exención de ejercicios para F00, F01, F34 y F35.
