# 🌈 Parte II · Fase 15 — Laboratorios de dependencias nativas: los cuatro dragones

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain` — esta fase **sí la modifica**
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · Node 10.24.1 baseline
> **Arquitectura objetivo del laboratorio:** `linux/amd64`
> **Dockerfile pedagógico de esta fase:** `dockerfiles/07-native-dependencies.Dockerfile`
> **Tag pedagógico:** `legacy-node-toolchain:phase15`
> **Estado de la imagen al terminar:** el toolchain gana las librerías del sistema que necesitan `canvas`, `sqlite3` y Chromium
> **Requisitos:** **[F14](14-abi-libc-y-prebuilds.md)**, imprescindible. Esta fase aplica su teoría a cuatro casos reales
> **Fecha de verificación ejecutada:** 6 de septiembre de 2026 — el dragón de `canvas` (§5) está corrido de punta a punta: el fallo sin librerías, la compilación con ellas, el `ldd` y el PNG. Docker 29.6.2, imagen `linux/amd64` bajo emulación en macOS Apple Silicon
> **Código de esta fase:** [`src/15-laboratorios-dependencias-nativas/`](src/15-laboratorios-dependencias-nativas/)
> **Objetivo:** diseccionar los cuatro paquetes que más tardes han costado en proyectos de 2018, y salir con una política de reparación que no destruya la evidencia

---

## 1. 🧭 Dónde estamos

[F14](14-abi-libc-y-prebuilds.md) te dio el mapa: cuatro casos, el ABI, glibc, los prebuilds y las cuatro herramientas de
disección. Esta fase lo aplica a los cuatro paquetes que vas a encontrarte de verdad.

Y trae la última pieza que le faltaba a la imagen: **las librerías del sistema**. [F07](07-build-de-la-imagen.md) dejó
declarado que el `Dockerfile` canónico no las llevaba porque pertenecen a esta fase. Aquí
llegan, cada una con el laboratorio que justifica su presencia.

```text
F14                        F15  ← esta fase
───                        ───────────────
el mecanismo               node-sass  → el dragón de la matriz de versiones
qué es un ABI              canvas     → el dragón de las librerías del sistema
qué es un prebuild         sqlite3    → el dragón de las dos estrategias
cómo se disecciona         Puppeteer  → el dragón que no es un addon
```

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder:

- Explicar por qué `node-sass` era una bomba de relojería y qué lo sustituyó.
- Provocar y arreglar el fallo de `canvas`, que es el caso puro de "falta una librería del
  sistema".
- Decidir, con criterio, entre un prebuild y compilar contra la librería del sistema.
- Tratar Puppeteer como lo que es: un caso D, que no se arregla como los otros tres.
- Aplicar una **política de reparación** que preserve la evidencia en lugar de borrarla.

---

## 3. 🚧 Qué NO entra todavía

- **Todo lo de ARM64**: por qué estos cuatro se comportan distinto en Apple Silicon → **[F21](21-arquitecturas-y-emulacion.md)**
  y **[F23](23-estudios-de-caso-multiplataforma.md)**.
- **Cypress y Selenium**, que son caso D como Puppeteer pero con su propia arquitectura →
  **[a09](a09-browsers-legacy.md)**.
- El **catálogo formal de fallos** en formato síntoma → causa → **[F32](32-catalogo-de-fallos-ii.md)**.
- El **método de diagnóstico** completo, con hipótesis falsables → **[F30](30-troubleshooting-metodo-y-herramientas.md)**.

---

## 4. 🩸 Dragón 1: `node-sass`, o la matriz que nadie miraba

`node-sass` daba bindings de Node para **LibSass**, la implementación en C++ de Sass:

```text
SCSS → node-sass → LibSass (C++) → CSS
```

Era la forma estándar de compilar Sass en el ecosistema de Webpack entre 2016 y 2020, y está
en el `package.json` de casi todos los proyectos Vue 2 y Angular 8 que te van a llegar.

**Y es un caso C puro** —addon precompilado— con un agravante: su compatibilidad con Node no
era flexible, era una **matriz**.

| Node | `node-sass` compatible | ABI |
|---|---|---|
| 10 | `4.9+` y `<6` | 64 |
| 12 | `4.12+` | 72 |
| 14 | `4.14+` | 83 |
| 16 | `6.0+` | 93 |

Nuestro baseline —Node 10.24.1 con `node-sass@4.14.1`— es una pareja históricamente coherente,
y por eso el fixture de [F11](11-validar-tu-proyecto.md) la usa.

> ⚠️ **Por qué esto duele tanto en la práctica.** El `package.json` de un proyecto de 2018
> suele decir `"node-sass": "^4.9.0"`, y ese `^` significa "cualquier 4.x posterior". Sin
> lockfile, `npm install` resuelve la 4.14 hoy, que quizá no existía cuando el proyecto se
> escribió. **Con** lockfile resuelve la que el autor probó. Es el argumento más concreto a
> favor de `npm ci` que da este curso.

**El fallo característico**, cuando el prebuild no existe para tu combinación:

```text
Node Sass could not find a binding for your current environment:
Linux 64-bit with Node.js 14.x

Found bindings for the following environments:
  - Linux 64-bit with Node.js 10.x
```

Fíjate en la honestidad del mensaje: te dice qué buscaba y qué encontró. **Es un error de
ABI disfrazado**, y su causa es la que [F14](14-abi-libc-y-prebuilds.md) §5.1 describió: reutilizaste artefactos de otra
generación.

Las tres salidas, en orden de preferencia:

1. **Usa la generación de Node que corresponde.** Es lo que el lockfile te está pidiendo.
2. **`npm rebuild node-sass`**, que fuerza la compilación contra tu Node actual — y aquí es
   donde el toolchain de [F04](04-toolchain-de-compilacion.md) y el Python de [F05](05-python-y-node-gyp.md) se ganan el sueldo.
3. **Migra a `sass` (Dart Sass)**, que es JavaScript puro —caso A— y elimina el problema para
   siempre. Es la solución estructural, y es un cambio de proyecto, no de laboratorio.

> 🪦 **`node-sass` está oficialmente retirado desde 2020.** Saberlo no te salva hoy: tu
> proyecto lo tiene y no lo vas a migrar esta tarde. Pero sí decide qué recomiendas cuando
> alguien pregunte "¿y esto se puede arreglar de verdad?".

---

## 5. 🎨 Dragón 2: `canvas`, o la librería que falta

`canvas` implementa la API de Canvas de HTML sobre **Cairo**, la librería de gráficos 2D de
Linux. Es un caso B/C que, cuando compila, necesita media docena de librerías del sistema con
sus cabeceras.

**Es el mejor laboratorio del curso** porque el fallo es limpio, reproducible y su
diagnóstico usa exactamente las herramientas de [F14](14-abi-libc-y-prebuilds.md) §8.

### 5.1 Primero, ver el fallo

Con la imagen de [F09](09-montar-tu-proyecto.md) —sin las librerías nuevas— fuerza la compilación:

```bash
docker exec legacy-node-dev npm install canvas@2.6.1 --build-from-source
```

El error, recortado a lo que importa:

```text
Package pixman-1 was not found in the pkg-config search path.
Perhaps you should add the directory containing `pixman-1.pc'
to the PKG_CONFIG_PATH environment variable
No package 'pixman-1' found
gyp: Call to 'pkg-config pixman-1 --libs' returned exit status 1
```

Ahí está `pkg-config` de [F04](04-toolchain-de-compilacion.md) §5.2 haciendo su trabajo: no encontró el archivo `.pc` de la
librería y falló antes de compilar nada.

### 5.2 Confirmar con `pkg-config`

```bash
docker exec legacy-node-dev pkg-config --exists cairo && echo "cairo ✅" || echo "cairo ❌ ausente"
docker exec legacy-node-dev pkg-config --exists pixman-1 && echo "pixman ✅" || echo "pixman ❌ ausente"
```

> 🩺 **La distinción que hay que tener clara**, y que [F04](04-toolchain-de-compilacion.md) §8 ya avisó: en Debian, `libcairo2`
> trae el `.so` para **ejecutar**, y `libcairo2-dev` trae las cabeceras y el `.pc` para
> **compilar**. Tener la primera y no la segunda produce exactamente este error, y el mensaje
> no menciona nunca la palabra "dev".

### 5.3 Las librerías que hacen falta

```text
libcairo2-dev     el motor de gráficos 2D
libpango1.0-dev   composición y renderizado de texto
libjpeg-dev       JPEG
libgif-dev        GIF
librsvg2-dev      SVG
```

Con ellas instaladas, la compilación funciona. Y ahora se puede diseccionar el resultado con
las herramientas de [F14](14-abi-libc-y-prebuilds.md):

```bash
docker exec legacy-node-dev bash -c '
  file  node_modules/canvas/build/Release/canvas.node
  echo "---"
  ldd   node_modules/canvas/build/Release/canvas.node | head -12
'
```

```text
node_modules/canvas/build/Release/canvas.node: ELF 64-bit LSB pie executable, x86-64,
version 1 (SYSV), dynamically linked, BuildID[sha1]=2a7c2879…, not stripped
---
	libpixman-1.so.0 => /usr/lib/x86_64-linux-gnu/libpixman-1.so.0
	libcairo.so.2 => /usr/lib/x86_64-linux-gnu/libcairo.so.2
	libpng16.so.16 => /usr/lib/x86_64-linux-gnu/libpng16.so.16
	libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1
	libpangocairo-1.0.so.0 => /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0
	libpango-1.0.so.0 => /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0
	libgobject-2.0.so.0 => /usr/lib/x86_64-linux-gnu/libgobject-2.0.so.0
	libglib-2.0.so.0 => /usr/lib/x86_64-linux-gnu/libglib-2.0.so.0
	libfreetype.so.6 => /usr/lib/x86_64-linux-gnu/libfreetype.so.6
	libjpeg.so.62 => /usr/lib/x86_64-linux-gnu/libjpeg.so.62
	libgif.so.7 => /usr/lib/x86_64-linux-gnu/libgif.so.7
	librsvg-2.so.2 => /usr/lib/x86_64-linux-gnu/librsvg-2.so.2
```

El ELF x86-64 y, debajo, la lista de librerías contra las que enlazó. **Esa lista es la razón
por la que un `node_modules` con `canvas` no es portable**: exige que en el sistema de destino
existan esas mismas librerías, con versiones compatibles.

Y fíjate en un detalle que engancha con §5.3: instalaste `libpixman` sin nombrarlo, porque
`libcairo2-dev` lo arrastró como dependencia. Las cinco librerías de la lista se convierten en
doce en el enlazado. **Lo que declaras en el `apt-get install` es la punta**; lo que acaba
enlazado es lo que `ldd` te enseña, y esa es la lista que de verdad tiene que existir en el
destino.

### 5.4 Y por último, que haga algo

```javascript
// labs/canvas/render.js — la prueba de que compiló Y funciona
const { createCanvas } = require('canvas');
const fs = require('fs');

const canvas = createCanvas(400, 200);
const ctx = canvas.getContext('2d');
ctx.fillStyle = '#0b3d2e';
ctx.fillRect(0, 0, 400, 200);
ctx.fillStyle = '#ffffff';
ctx.font = '24px sans-serif';
ctx.fillText('canvas funciona en Debian 10 👋', 20, 110);

fs.writeFileSync('salida.png', canvas.toBuffer('image/png'));
console.log('escrito salida.png');
```

```text
escrito salida.png
-rw-r--r-- 1 root root 5387 Sep  6 06:12 salida.png
```

Cinco kilobytes de PNG que no existían hace un minuto, generados por una librería de C de 2018
compilada dentro de un Debian sin soporte, sobre un Mac que no tiene ni Cairo ni Node 10
instalados. Ese archivo es el curso entero en 5.387 bytes. 😉

> 🔥 **Prueba de fuego.** Ejecútalo, sal del contenedor y abre `salida.png` en tu host. Si el
> texto sale como rectángulos, te faltan **fuentes** —no librerías—, que es un fallo distinto
> con el mismo aspecto. `fonts-liberation` lo arregla, y **[a09](a09-browsers-legacy.md)** explica por qué.

---

## 6. 🗄️ Dragón 3: `sqlite3`, o las dos estrategias

`sqlite3` es el mejor laboratorio para entender la decisión **prebuild contra compilar**,
porque admite las dos con resultados distintos y ambos correctos.

**Instalación normal** — descarga un prebuild que ya trae SQLite **incrustado**:

```bash
docker exec legacy-node-dev npm install sqlite3@4.2.0
docker exec legacy-node-dev bash -c '
  find node_modules/sqlite3 -name "*.node" | head -1 | xargs file
  find node_modules/sqlite3 -name "*.node" | head -1 | xargs ldd | grep -c sqlite || echo "0 → SQLite va dentro del binario"
'
```

**Compilar contra el SQLite del sistema:**

```bash
docker exec legacy-node-dev npm install sqlite3@4.2.0 --build-from-source --sqlite=/usr
docker exec legacy-node-dev bash -c '
  find node_modules/sqlite3 -name "*.node" | head -1 | xargs ldd | grep sqlite
'
```

Ahora sí aparece `libsqlite3.so.0` en el `ldd`: el addon delega en la librería del sistema en
lugar de llevarla dentro.

### 6.1 ¿Cuál es mejor?

Ninguna, y esa es la lección:

| | Prebuild con SQLite incrustado | Compilado contra el sistema |
|---|---|---|
| **Instalación** | segundos | minutos |
| **Versión de SQLite** | la que el paquete decidió, fija | la de Debian 10, y cambia si actualizas |
| **Portabilidad del `node_modules`** | mayor: menos dependencias externas | menor: exige `libsqlite3` en destino |
| **Parches de seguridad de SQLite** | dependen del paquete npm | los da la distribución |
| **Cuándo elegirla** | por defecto, y para reproducir el entorno de 2018 | cuando necesites una versión concreta de SQLite o su parcheo |

> 🧭 **Este caso NO es como `canvas`.** En `canvas` no hay elección: sin las librerías del
> sistema no compila, punto. En `sqlite3` hay dos caminos legítimos, y elegir es tu trabajo.
> Confundir los dos casos —y tratar todo fallo nativo como "me falta un paquete `-dev`"— es
> uno de los errores de diagnóstico más comunes.

---

## 7. 🎭 Dragón 4: Puppeteer, que no es un addon

Puppeteer es **caso D** de [F14](14-abi-libc-y-prebuilds.md) §4.4, y por eso se comporta distinto a los otros tres: no
compila nada. Descarga un navegador entero.

```mermaid
flowchart TD
    A["npm install puppeteer"] --> B["install.js"]
    B --> C["descarga un Chromium de una revisión concreta,<br/>de una URL concreta"] --> D["lo guarda en un caché"]
```

`puppeteer@5.5.0` —de 2020, y que declara necesitar Node ≥ 10.18.1, así que nuestro baseline
le vale— descarga la revisión `r818858` de Chromium.

**Los tres modos de fallo son los de [F14](14-abi-libc-y-prebuilds.md) §7.1 aplicados a un binario grande:**

- **La descarga falla o la URL murió.** Es un problema de infraestructura externa, no de tu
  toolchain.
- **El Chromium se descargó y no arranca.** Le faltan librerías del sistema. `ldd` sobre el
  binario del caché te lo dice en una línea.
- **El Chromium es de otra arquitectura.** El problema de **[F21](21-arquitecturas-y-emulacion.md)**.

**Y por eso su tratamiento es distinto:** no se arregla con `npm rebuild` ni con
`--build-from-source`. Se arregla saltándose la descarga y aportando tú el navegador, que es
lo que recomienda **[a09](a09-browsers-legacy.md)**:

```bash
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true npm ci
PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium node mi-script.js
```

Las librerías gráficas que necesita, y por qué cada una, están en **[a09](a09-browsers-legacy.md) §2**. Aquí solo entran
a la imagen.

---

## 8. 🏗️ El Dockerfile de la fase

Sobre el canónico, se añaden las librerías que los cuatro laboratorios justificaron:

```dockerfile
# … todo lo del canónico de F09 …

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       # canvas: Cairo, Pango y los formatos de imagen
       libcairo2-dev \
       libgif-dev \
       libjpeg-dev \
       libpango1.0-dev \
       librsvg2-dev \
       # sqlite3 compilado contra el sistema
       libsqlite3-dev \
       sqlite3 \
       # Chromium headless: NSS, X11, GTK, render y fuentes (a09 §2)
       fonts-liberation \
       libasound2 \
       libatk-bridge2.0-0 \
       libatk1.0-0 \
       libcups2 \
       libdbus-1-3 \
       libdrm2 \
       libgbm1 \
       libgtk-3-0 \
       libnspr4 \
       libnss3 \
       libx11-xcb1 \
       libxcomposite1 \
       libxdamage1 \
       libxfixes3 \
       libxrandr2 \
       libxss1 \
       xdg-utils \
    && rm -rf /var/lib/apt/lists/*
```

**Detalles con intención:**

- **Los comentarios agrupan por qué dragón**, no alfabéticamente. Es la excepción a la regla
  de orden de [F03](03-apt-y-utilidades.md): aquí el porqué importa más que el diff, porque dentro de dos años alguien
  va a preguntar "¿y esto para qué está?".
- **Un `RUN` aparte del de F03**, y esta vez sí está justificado: son paquetes de una
  categoría distinta, se añaden en una fase distinta, y separarlos permite ver en
  `docker image history` cuánto cuestan exactamente.
- **Esto engorda la imagen**, y el número está en el ejercicio 15. Es el precio de que
  `canvas` y Puppeteer funcionen sin pensar.

> 💸 **Deuda declarada.** Si tu proyecto no usa ninguno de los cuatro dragones, estas
> librerías son peso muerto. La alternativa —una variante de la imagen sin ellas— es
> perfectamente razonable y está en el ejercicio 26.

---

## 9. 🧯 Política de reparación: no destruyas la evidencia

Esta sección es, probablemente, lo más transferible de la fase entera.

### 9.1 El orden correcto

```text
1. respetar el package-lock.json
2. confirmar qué Node y qué npm están corriendo de verdad
3. identificar el paquete exacto y su versión
4. identificar de qué tipo de artefacto se trata (caso A/B/C/D)
5. identificar ABI, plataforma, arquitectura y libc
6. reproducir el fallo con evidencia guardada
7. y solo entonces, reparar
```

### 9.2 Lo que NO se hace primero

> ⚠️ **Cuatro reflejos que destruyen la evidencia** y que hay que resistir:
>
> ```bash
> rm package-lock.json          # borras la única fuente de verdad del proyecto
> rm -rf node_modules           # borras el estado que ibas a diagnosticar
> npm install --force           # ocultas el conflicto en lugar de entenderlo
> docker system prune -a        # borras imágenes, volúmenes y la caché de una vez
> ```
>
> Los cuatro "funcionan" a veces. Los cuatro te dejan sin saber qué pasaba, así que la
> próxima vez vuelves a empezar de cero.

### 9.3 El inventario inicial, en un comando

Antes de tocar nada:

```bash
docker exec legacy-node-dev bash -c '
  echo "== runtime";      node --version; npm --version
  echo "== ABI";          node -p "process.versions.modules"
  echo "== arquitectura"; uname -m
  echo "== libc";         ldd --version | head -1
  echo "== toolchain";    gcc --version | head -1; python2 --version 2>&1; python3 --version
'
```

### 9.4 Buscar las pistas en el log

Si guardaste el log de instalación —y [F11](11-validar-tu-proyecto.md) te enseñó a guardarlo—, esta línea lo destila:

```bash
grep -Ei 'node-gyp|node-pre-gyp|prebuild|binding|fallback|gyp ERR|CXX|not found|404|403|ELIFECYCLE' \
  install.log
```

Y para inventariar qué artefactos nativos hay realmente:

```bash
find node_modules -type f -name '*.node' -exec sh -c 'printf "%-60s " "$1"; file -b "$1" | cut -c1-40' _ {} \;
```

### 9.5 La tabla de arqueología rápida

| Síntoma | Capa sospechosa | Confirmación | Acción típica |
|---|---|---|---|
| `NODE_MODULE_VERSION X vs Y` | ABI de Node | `node -p process.versions.modules` | usar la generación correcta, o `npm rebuild` |
| prebuilt `404` o `403` | distribución del addon | la URL en el log | `--build-from-source` |
| `Package X was not found in pkg-config` | librería del sistema | `pkg-config --exists X` | instalar el paquete `-dev` |
| `cannot open shared object file` | librería en runtime | `ldd binario \| grep 'not found'` | instalar el paquete sin `-dev` |
| `GLIBC_2.29 not found` | versión de libc | `readelf -V binario \| grep GLIBC` | compilar desde source |
| `invalid ELF header` | arquitectura o descarga rota | `file binario` | comprobar `--platform` y la descarga |
| `Could not find Chromium` | caso D | el caché del paquete | `PUPPETEER_EXECUTABLE_PATH` |

> 🧠 **El patrón a memorizar.** Cada fila de esa tabla es un **par síntoma → comando de
> confirmación**. La diferencia entre adivinar y diagnosticar es tener ese comando antes de
> tocar nada. **[F30](30-troubleshooting-metodo-y-herramientas.md)** convierte esto en método formal.

---

## 10. ⚠️ Errores comunes y diagnóstico

**`node-sass` falla tras cambiar de Node.** ABI. §4, y el arreglo correcto es usar la
generación del lockfile, no forzar la instalación.

**`canvas` compila y luego el texto sale como cajas.** Faltan fuentes, no librerías. §5.4.

**`sqlite3` instala rápido y falla al ejecutar en otra máquina.** El prebuild trae SQLite
dentro, pero el `.node` sigue exigiendo la arquitectura y el ABI correctos. §6.

**Puppeteer instala y `launch()` falla.** Librerías del sistema del navegador, o el sandbox
corriendo como root. §7 y [a09](a09-browsers-legacy.md) §7.

**"Reinstalé todo y sigue igual."** Uno de los cuatro cachés de [F14](14-abi-libc-y-prebuilds.md) §7.2.

**"Funcionaba ayer."** Casi siempre es el volumen: alguien lo reutilizó con otra generación de
Node. `docker volume inspect` y el nombre te lo dicen.

---

## 11. 📋 Checklist de validación

```text
[ ] El build produce legacy-node-toolchain:phase15 con las librerías nuevas
[ ] Reprodujiste el fallo de canvas SIN las librerías, y leíste el error de pkg-config
[ ] canvas compila con phase15 y produce un PNG legible en tu host
[ ] file y ldd sobre canvas.node muestran ELF x86-64 y sus dependencias
[ ] sqlite3 instalado de las dos formas, y sabes distinguirlas con ldd
[ ] Puedes decir cuándo elegirías cada estrategia de sqlite3
[ ] node-sass 4.14.1 instala y compila SCSS con Node 10
[ ] Provocaste el error de binding de node-sass cambiando de generación
[ ] Puppeteer arranca Chromium con PUPPETEER_EXECUTABLE_PATH
[ ] Tienes el inventario de §9.3 guardado para tu proyecto real
```

---

## 12. 🧪 Ejercicios de la Fase 15 (28)

## 🟢 Fácil — los cuatro dragones, en vivo (1–7)

### 🟢 Ejercicio 1 — Construye phase15 y mide

Construye la imagen de §8 y compara su tamaño con `phase09`.

**Pregunta:** ¿cuánto cuestan las librerías de los cuatro dragones? ¿Te parece razonable?

### 🟢 Ejercicio 2 — El fallo de canvas, en vivo

Con `phase09`, ejecuta §5.1 y guarda el error completo.

**Objetivo:** ver un fallo de `pkg-config` real y localizar en el mensaje qué paquete falta.

### 🟢 Ejercicio 3 — Confírmalo con `pkg-config`

Ejecuta las dos comprobaciones de §5.2 en `phase09` y en `phase15`.

**Objetivo:** obtener la respuesta binaria que confirma la hipótesis, sin instalar nada.

### 🟢 Ejercicio 4 — canvas dibuja

Compila `canvas` en `phase15` y ejecuta el script de §5.4.

**Objetivo:** abrir el PNG en tu host. Es la prueba de que un toolchain de 2019 dentro de un
contenedor produjo un artefacto real.

### 🟢 Ejercicio 5 — Las dos caras de sqlite3

Instala `sqlite3` de las dos formas de §6 y compara los `ldd`.

**Pregunta:** ¿en cuál aparece `libsqlite3.so.0` y por qué?

### 🟢 Ejercicio 6 — node-sass con su pareja

Instala `node-sass@4.14.1` con Node 10 y compila un `.scss` mínimo.

**Objetivo:** ver funcionar la combinación que el fixture Vue 2 de [F11](11-validar-tu-proyecto.md) usa.

### 🟢 Ejercicio 7 — El inventario

Ejecuta el comando de §9.3 y guarda su salida.

**Objetivo:** tener la foto del entorno antes de cualquier diagnóstico. Es el paso 0 de todo lo
que viene.

## 🟡 Intermedio — provocar y confirmar la carencia (8–16)

### 🟡 Ejercicio 8 — Rompe node-sass a propósito

Instala `node-sass` con Node 10 y ejecútalo después con Node 14 sobre el mismo volumen.

**Objetivo:** obtener el mensaje de binding completo, y arreglarlo de las **dos** formas de §4
midiendo cuál tarda menos.

### 🟡 Ejercicio 9 — Solo la librería, sin las cabeceras

Construye una imagen con `libcairo2` pero **sin** `libcairo2-dev` e intenta compilar `canvas`.

**Pregunta:** ¿qué error da? ¿Menciona en algún momento la palabra "dev"? Es la trampa de §5.2.

### 🟡 Ejercicio 10 — Disecciona los cuatro

Instala los cuatro dragones y pásale `file` y `ldd` al artefacto de cada uno.

**Objetivo:** una tabla con cuatro filas —paquete, tipo de artefacto, dependencias externas— y
la conclusión de cuál sería más frágil al mover el `node_modules`.

### 🟡 Ejercicio 11 — Puppeteer sin descargar

Aplica la estrategia de §7 con el `chromium` de Debian y ejecuta una captura de pantalla.

**Pregunta:** ¿qué versión de navegador usaste realmente? ¿Coincide con la que Puppeteer 5.5
esperaba?

### 🟡 Ejercicio 12 — Grep sobre un log real

Guarda el log de un `npm ci` que falle y aplica el `grep` de §9.4.

**Objetivo:** comprobar que esa línea encuentra la causa raíz sin leer las 4.000 líneas de
salida.

### 🟡 Ejercicio 13 — Las fuentes no son librerías

La 🔥 prueba de fuego de §5.4 lo avisa de pasada y merece su propio ejercicio, porque es un
fallo que se diagnostica mal el 100 % de las veces. Construye una imagen igual que `phase15`
pero **sin** `fonts-liberation`, compila `canvas` y ejecuta el `render.js`.

**Objetivo:** obtener un PNG donde el texto sale como rectángulos —o no sale— mientras
`canvas` compila e importa **sin un solo error**. Guarda las dos imágenes lado a lado.

**Pregunta:** ¿en qué se diferencia este fallo de todos los demás de la fase? Fíjate en que no
hay mensaje de error, ni código de salida distinto de cero, ni nada en `ldd`. Escribe cómo lo
habrías diagnosticado si te llegara como *"el PDF que genera el servicio sale con cuadraditos"*,
y qué comando —`fc-list`— lo confirma en un segundo.

### 🟡 Ejercicio 14 — Del error de `ldd` al paquete de Debian

`ldd` te dice qué falta con el nombre del **archivo**, no con el del **paquete**, y entre los
dos hay un paso que mucha gente resuelve a base de buscar en internet. Hazlo bien. Provoca el
fallo primero:

```bash
ldd node_modules/canvas/build/Release/canvas.node | grep 'not found'
```

Ahora traduce ese `.so` al paquete que lo trae, con la base de datos que ya tienes dentro:

```bash
dpkg -S libpixman-1.so.0            # si el paquete está instalado
apt-file search libpixman-1.so.0    # si no lo está — instala apt-file y actualiza primero
```

**Objetivo:** convertir una lista de tres `.so` que faltan en una lista de tres paquetes de
Debian que instalar, sin abrir el navegador ni una sola vez.

**Pregunta:** ¿por qué `dpkg -S` no encuentra nada cuando el paquete **no** está instalado, y
qué está consultando entonces `apt-file`? La respuesta es la diferencia entre "lo que tengo" y
"lo que existe", y es la misma que separa `dpkg` de `apt` en [a01](a01-debian-y-apt-a-fondo.md).

### 🟡 Ejercicio 15 — Cuánto pesa cada dragón

Construye cuatro imágenes, cada una con las librerías de un solo dragón, y mide.

**Pregunta:** ¿cuál es el más caro? ¿Cambiaría tu decisión sobre incluirlos todos?

### 🟡 Ejercicio 16 — El fixture Vue 2 con node-sass

Añade `node-sass@4.14.1` al fixture de `src/11-validar-tu-proyecto/10-vue2-min/`, regenera el
lock dentro del baseline y valida.

**Pregunta:** ¿instaló desde prebuild o compiló? Búscalo en el log. Es la continuación del
ejercicio 20 de [F11](11-validar-tu-proyecto.md).

## 🟠 Difícil — diagnosticar y medir (17–24)

### 🟠 Ejercicio 17 — Cuatro fallos, cuatro causas

Provoca los cuatro primeros síntomas de la tabla de §9.5, cada uno a propósito, y confirma cada
uno con su comando.

**Objetivo:** que la tabla deje de ser una referencia y pase a ser algo que ya ejecutaste.

### 🟠 Ejercicio 18 — Diagnostica a ciegas

Pídele a alguien que rompa una instalación de una de estas cuatro formas sin decirte cuál, y
diagnostícalo siguiendo §9.1.

**Objetivo:** llegar a la causa sin haber borrado nada, y poder decir qué comando la confirmó.

### 🟠 Ejercicio 19 — El anti-patrón, medido

Rompe una instalación y "arréglala" con `rm -rf node_modules && rm package-lock.json && npm install`.

**Pregunta:** ¿funcionó? ¿Qué versiones tienes ahora? Compara el lockfile nuevo con el
original: ¿cuántos paquetes cambiaron de versión sin que tú lo pidieras? Ahí está el costo real
del atajo de §9.2.

### 🟠 Ejercicio 20 — La imagen mínima para tu proyecto

Determina qué librerías de §8 necesita **tu** proyecto real, y construye la variante mínima.

**Objetivo:** justificar cada exclusión con evidencia —`npm ci` verde y la aplicación
arrancando—, no con suposiciones.

### 🟠 Ejercicio 21 — Chromium como root, y por qué se queja

Ejecuta Puppeteer con el `chromium` de Debian dentro del contenedor, como `root`, tal cual:

```bash
node -e 'require("puppeteer-core").launch({executablePath:"/usr/bin/chromium"})
  .then(b=>b.close()).catch(e=>console.error(e.message))'
```

**Objetivo:** leer el error del sandbox entero y **no** limitarte a añadir `--no-sandbox`
porque lo dice el primer resultado de búsqueda. Averigua qué es el sandbox de Chromium, qué
protege, y por qué se niega a funcionar cuando el proceso es root.

Después arréglalo de las **dos** formas: con `--no-sandbox`, y creando un usuario sin
privilegios que lo ejecute. Comprueba que las dos funcionan.

**Pregunta:** ¿cuál de las dos elegirías para este laboratorio y cuál para un servicio que
renderiza HTML que le llega de fuera? Son respuestas distintas, y la diferencia es la
superficie de ataque: explícala en dos frases. **[a09](a09-browsers-legacy.md)** tiene el
contexto completo; aquí basta con que la decisión sea tuya y esté razonada.

### 🟠 Ejercicio 22 — El quinto dragón: aplícale el método a `sharp`

La fase te da cuatro autopsias. La prueba de que aprendiste el **método** y no las cuatro
respuestas es hacer la quinta solo. `sharp@0.25.4` —de la época— es un caso C con librería del
sistema por debajo, `libvips`, y su propia forma de fallar.

**Objetivo:** recorrer los cinco pasos que la fase aplica a cada dragón, **en este orden**:
(1) provocar el fallo con la imagen sin preparar y guardar el error literal;
(2) decidir de qué caso de [F14](14-abi-libc-y-prebuilds.md) §4 se trata, justificándolo;
(3) confirmar la carencia con la herramienta adecuada — `pkg-config`, `ldd` o el log del
`postinstall`, y di por qué elegiste esa;
(4) instalar lo mínimo que lo resuelva, nombrando cada paquete;
(5) demostrar que **funciona**, no solo que compila: redimensiona una imagen de verdad.

**Pregunta de cierre:** ¿en cuál de los cuatro dragones se parece más `sharp`, y en qué se
diferencia? Si tu respuesta es "en ninguno", vuelve al paso 2.

### 🟠 Ejercicio 23 — Los dos síntomas que te faltan

El ejercicio de "cuatro fallos, cuatro causas" te hizo provocar los primeros de la tabla de
arqueología rápida de §9.5. Quedan los últimos, que son los más difíciles de provocar a
propósito precisamente porque son los que aparecen solos.

**Objetivo:** provocar cada uno de los síntomas restantes de esa tabla, uno por uno, y para
cada uno registrar tres cosas: **el comando exacto** que lo provoca, **el mensaje literal**
completo —sin recortar la parte incómoda— y **la comprobación de una línea** que lo distingue
de los demás síntomas de la tabla.

**Pregunta:** al terminar tendrás la tabla de §9.5 entera reproducida por ti. Compara tus
mensajes con los que la fase dice y anota cualquier diferencia: versiones distintas dan textos
distintos, y saber cuánto varían es parte de saber leerlos. ¿Alguno de los síntomas resultó
ser **dos** causas distintas con el mismo mensaje? Ese es el que te va a costar una tarde en
producción.

### 🟠 Ejercicio 24 — El orden de las librerías y la caché

El `Dockerfile` de §8 pone el `apt-get` de las librerías del sistema **después** del bloque de
Node. Podría ir antes. Mide qué cambia.

Construye las dos variantes y, en cada una, cronometra tres reconstrucciones: sin tocar nada,
cambiando solo la lista de librerías, y cambiando solo `DEFAULT_NODE_VERSION`.

**Objetivo:** una tabla de 2 × 3 con los seis tiempos y, en cada celda, qué pasos dijeron
`CACHED`.

**Pregunta:** ¿qué orden gana? Ojo, porque la respuesta correcta **depende de qué cambia más a
menudo en tu vida real**, y eso es justo lo que dice la regla de [F12](12-capas-cache-y-contexto.md)
§5. Termina justificando el orden que el curso eligió — o proponiendo cambiarlo, si tus números
dicen otra cosa. Las dos respuestas valen si traen los seis tiempos detrás.

## 🔴 Muy difícil — estrategia y riesgo (25–28)

### 🔴 Ejercicio 25 — Decide entre prebuild y source, con datos

Para `sqlite3` en tu proyecto real, decide cuál de las dos estrategias de §6 usarías y
**demuéstralo**: mide tiempo de instalación, comprueba qué versión de SQLite acabas usando en
cada caso, y verifica si el `node_modules` resultante sobreviviría a moverlo a otra máquina.

**Objetivo:** una decisión con tres datos detrás, no con una preferencia. Y di explícitamente
qué tendría que cambiar para que eligieras la otra.

### 🔴 Ejercicio 26 — La política de reparación de tu equipo

Redacta el documento de una página que tu equipo seguiría ante un fallo de dependencia nativa.

**Objetivo:** que empiece por el inventario y no por el arreglo, que incluya los cuatro
anti-patrones de §9.2 con su porqué, y que sea lo bastante corto como para que alguien lo lea
de verdad a las tres de la mañana.

### 🔴 Ejercicio 27 — La imagen de runtime que no puede compilar

Todo este curso construye una imagen de **desarrollo**, con compilador dentro, y lo dice sin
complejos. Pero llega el día en que hay que entregar una imagen de **runtime**: sin `gcc`, sin
Python, sin las cabeceras `-dev`, y que sin embargo ejecute un proyecto con los cuatro
dragones dentro.

**Objetivo:** conseguirlo, y hay dos caminos legítimos. Uno es **multi-stage**: una etapa
compila con `phase15` y otra copia solo lo necesario. El otro es **vendorizar**: guardar los
`.node` ya compilados y montarlos. Implementa **al menos uno** de los dos hasta que la
aplicación arranque, y describe el otro con detalle suficiente para que otra persona lo
implemente.

Mide las dos imágenes: la de desarrollo y la de runtime.

**Pregunta de cierre:** ¿qué librerías del sistema **sí** tienen que quedarse en la imagen de
runtime y cuáles no? La respuesta la da `ldd` sobre los `.node`, y la trampa es el par
`libfoo` / `libfoo-dev`, que §5.2 ya te enseñó a distinguir. Si tu imagen de runtime pesa más
de la mitad que la de desarrollo, algo te sobra: encuéntralo.

### 🔴 Ejercicio 28 — El artefacto que ya no se puede descargar

El caso D de [F14](14-abi-libc-y-prebuilds.md) §4.4 tiene una bomba de relojería: la
instalación depende de que una URL siga viva. Puppeteer descarga su Chromium, Cypress su
Electron, `node-sass` su binding. **Esas URLs son de 2018 y algunas ya no responden.**

**Objetivo:** para tu proyecto real, encontrar **todos** los paquetes que descargan algo
durante la instalación —los `postinstall` e `install` del `package-lock.json` son el sitio
donde buscar— y, para cada uno, comprobar hoy si su URL sigue respondiendo. Un `curl -I` basta.

Después diseña la estrategia de supervivencia: qué artefactos hay que guardar, dónde, cómo se
verifican al restaurarlos —checksums, [a04](a04-checksums-gpg-y-archivos.md)— y cómo se le dice
a cada paquete que use la copia local en lugar de salir a internet. Cada uno tiene su variable:
`PUPPETEER_SKIP_DOWNLOAD`, `SASS_BINARY_PATH`, `npm_config_<paquete>_binary_host_mirror`.

**Pregunta de cierre:** si mañana desaparecieran las tres URL a la vez, ¿cuánto tardarías en
reconstruir tu proyecto? Da un número en horas. Si el número es "no podría", acabas de
encontrar el riesgo más grande de tu proyecto legacy, y es el mismo que
**[a13](a13-air-gapped.md)** existe para eliminar.

## 🔥 Opcionales

### 🔥 Ejercicio 29 — Migra a Dart Sass

Sustituye `node-sass` por `sass` en un fixture y compara: tiempo de instalación, tiempo de
compilación y tamaño del `node_modules`.

**Pregunta:** ¿qué se rompió al migrar? Normalmente algo se rompe, y saber qué es la diferencia
entre recomendarlo y recomendarlo con conocimiento.

### 🔥 Ejercicio 30 — `canvas` sin las `-dev`

Averigua qué paquetes `-dev` puedes quitar **después** de compilar `canvas` sin romper la
ejecución.

**Objetivo:** entender la diferencia entre dependencias de compilación y de runtime, que es la
base de los multi-stage builds de [F12](12-capas-cache-y-contexto.md). ¿Cuánto adelgazaría la imagen?

## 💀 Boss fight

### 💀 Ejercicio 31 — Boss fight: el proyecto con los cuatro

Construye un proyecto que use `node-sass`, `canvas`, `sqlite3` y Puppeteer a la vez, con
versiones de la época, y consigue que `npm ci`, los tests y el arranque funcionen en el
laboratorio.

**Objetivo:** el examen de la fase. Documenta, por cada dragón: qué caso es, si compiló o
descargó, contra qué enlazó y qué tuviste que añadir. Y termina con la pregunta honesta: **¿qué
parte de este trabajo sería innecesaria si el proyecto se modernizara, y qué parte no?** Si
llegas al final con los cuatro funcionando y esa respuesta escrita, las dependencias nativas ya
no te van a dar sustos.

---

## 13. 📚 Referencias

**Los cuatro paquetes**
- `node-sass` y su matriz de compatibilidad: https://github.com/sass/node-sass#node-version-support-policy
- Dart Sass, el sucesor: https://sass-lang.com/dart-sass/
- `canvas` y sus dependencias de compilación: https://github.com/Automattic/node-canvas/wiki/Installation:-Ubuntu-and-other-Debian-based-systems
- `sqlite3` de Node: https://github.com/TryGhost/node-sqlite3
- Puppeteer v5.5.0: https://github.com/puppeteer/puppeteer/releases/tag/v5.5.0

**Librerías del sistema**
- Cairo: https://www.cairographics.org
- Paquetes de Debian 10: https://packages.debian.org/buster/

> ⚠️ **`node-sass` está archivado y su README actual apunta a Dart Sass.** La matriz de §4
> sigue siendo válida para las versiones que tu proyecto usa; para todo lo demás, el proyecto
> está muerto y el enlace es histórico.

**Orden de lectura sugerido:** la matriz de `node-sass` primero, que resuelve el dragón más
frecuente; la wiki de instalación de `canvas` cuando hagas el ejercicio 2.

---

## 14. 🏁 Resultado de la fase

```text
IMAGEN         legacy-node-toolchain:phase15
NUEVO          librerías de canvas, sqlite3 y Chromium — 23 paquetes

LOS CUATRO     node-sass  caso C · matriz de ABI · retirado en 2020
               canvas     caso B/C · exige librerías -dev del sistema
               sqlite3    caso C · dos estrategias legítimas, tú eliges
               Puppeteer  caso D · no compila: descarga un navegador

MÉTODO         inventario antes de reparar
               cuatro anti-patrones que destruyen la evidencia
               tabla síntoma → comando de confirmación → acción
```

> **La señal de que quedó bien:** *"cuando una dependencia nativa falla, mi primer comando no
> arregla nada — recoge evidencia. Y con esa evidencia sé cuál de las siete filas de la tabla
> es antes de tocar el proyecto."*

En **[F16](16-pid1-senales-y-ciclo-de-vida.md)** cambiamos de terreno: dejamos el filesystem y las dependencias, y entramos en qué es
un contenedor **como proceso**: PID 1, señales, zombies y por qué tu aplicación ignora
`Ctrl+C`.
