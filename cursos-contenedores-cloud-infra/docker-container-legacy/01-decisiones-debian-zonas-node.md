# 🧱 Parte I · Fase 01 — Decisiones cerradas: Debian, las tres zonas y Node

> **Curso:** Docker Legacy Node
> **Imagen que construiremos:** `legacy-node-toolchain`
> **Baseline que se fija aquí:** Debian 10 Buster (`debian/eol:buster`) · Node 10.24.1 / 12.22.12 / 14.21.3 / 16.20.2
> **Arquitectura:** `linux/amd64` baseline, `linux/arm64` adicional
> **Estado de la imagen al terminar:** todavía ninguna. Esta fase decide; [F02](02-dockerfile-esencial.md) empieza a escribir
> **Objetivo:** cerrar las cuatro decisiones de arquitectura que sostienen todo el laboratorio, con su porqué, para no volver a discutirlas en ninguna fase posterior

---

## 1. 🧭 Dónde estamos

[F00](00-problema-y-contrato.md) fijó el contrato: el código vive en el host, el toolchain en el contenedor, y esto es
un laboratorio local y no producción. Lo que no dijo es **cuál** contenedor, **dónde**
exactamente vive cada archivo y **qué** versiones exactas entran.

Eso es lo que se cierra aquí. Cuatro decisiones, una página por tema, cada una con el
razonamiento que la sostiene — porque cuando tu proyecto real difiera del ejemplo, el
razonamiento es lo único que te va a servir para adaptarla.

Como [F00](00-problema-y-contrato.md), esta es una fase de decisión: **no vas a ejecutar casi nada**. Es la última.
Desde [F02](02-dockerfile-esencial.md) se construye.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder defender, ante alguien que opine lo contrario:

- Por qué Debian 10 y no Debian 11, Debian 9, Ubuntu o Alpine, y por qué la imagen normal
  en lugar de `slim`.
- Qué significa `debian/eol:buster` y por qué apuntar al archivo histórico no es un
  parche sino la decisión correcta.
- Cuáles son las tres zonas del laboratorio y qué archivo vive en cada una.
- Por qué `node_modules` va en un *named volume* y por qué el volumen lleva la versión de
  Node en el nombre.
- Cuáles son las cuatro generaciones baseline y por qué las CLIs de framework pertenecen al
  proyecto y no a la imagen.

---

## 3. 🚧 Qué NO entra todavía

Esta fase decide, no implementa. Quedan fuera, con destino:

- **Cómo** se instalan las cuatro versiones de Node en una sola imagen → **[F06](06-instalacion-node.md)**.
- La discusión larga de por qué no `nvm`, no NodeSource, no compilar desde source y no
  `FROM node:10`, más `PATH`, `npx` y Yarn → **[a02](a02-estrategia-node-y-clis.md)**.
- Los comandos reales de bind mount y volumen, con sus banderas → **[F09](09-montar-tu-proyecto.md)**.
- Qué es exactamente el ABI que hace incompatibles dos `node_modules` → **[F14](14-abi-libc-y-prebuilds.md)**.
- Por qué elegimos `linux/amd64` de baseline teniendo ARM64 disponible, y qué cuesta la
  emulación → **[F21](21-arquitecturas-y-emulacion.md)**.

---

## 4. 🐧 Decisión 1: Debian 10 Buster

### 4.1 La pregunta correcta no es cuál es la más nueva

En un proyecto moderno preguntaríamos *"¿cuál es la distribución Linux con soporte más
reciente?"*. Aquí la pregunta es otra: **¿qué distribución ofrece un entorno suficientemente
cercano al stack original y reduce la fricción con Node y tooling legacy?**

Ese cambio de pregunta es lo importante de esta sección. En este laboratorio, *nuevo* no
significa automáticamente *mejor*.

Debian 10 apareció en julio de 2019, lo que lo coloca prácticamente en el centro del período
que queremos reproducir:

```text
2017 ───── 2018 ───── 2019 ───── 2020 ───── 2021
                       ▲
                  Debian 10
```

En esa época convivían de forma natural Node 10 y 12, npm 6, Python 2.7 junto a Python 3,
GCC 8, Webpack 3 y 4, Vue 2, Angular 7/8/9 y React 16. Es exactamente la lista de la que
salen los proyectos que vas a revivir.

### 4.2 Las cuatro alternativas y por qué se descartan

**Debian 11 Bullseye.** Perfectamente capaz de ejecutar muchos proyectos legacy, y de hecho
fue la recomendación preliminar de este laboratorio. Apareció en 2021, lo que lo aleja del
contexto original: paquetes más nuevos, cambios en Python, librerías del sistema
posteriores, compiladores distintos. En un sistema moderno eso es una ventaja; en un
laboratorio legacy es una fuente adicional de diferencias que hay que explicar. **No queda
descartada**: es la alternativa razonable para proyectos legacy más recientes.

**Debian 9 Stretch.** Tiene el mismo sentido histórico, pero nos lleva demasiado al otro
extremo. Sería la elección correcta para Node 8 o tooling de 2017–2018 muy específico.
Nuestro arco empieza en Node 10 y llega a Node 16, así que Buster queda mejor posicionado
como punto de equilibrio. Se conserva como **fallback de arqueología avanzada**. 🏺

**Ubuntu.** También sería viable: usa `glibc`, usa APT, tiene muchos paquetes y fue
comunísimo en servidores y estaciones de la época. Pero no aporta una ventaja necesaria
aquí, y Debian nos da menos decisiones adicionales, repositorios históricos bien
organizados, buena compatibilidad multi-arquitectura y relación directa con muchas imágenes
oficiales del ecosistema. La regla: *no agregamos otra distribución si Debian resuelve el
problema*.

**Alpine.** Excelente cuando el objetivo es construir imágenes pequeñas, y ese no es
nuestro objetivo. Alpine usa `musl libc` en lugar de `glibc`, y para proyectos legacy con
módulos nativos, binarios precompilados, versiones viejas de `node-gyp` y paquetes
abandonados, introducir una libc distinta agrega problemas que no necesitamos. No vamos a
ganar el campeonato mundial de "imagen de 17 MB". 😄 Vamos a recuperar el proyecto.

> 🧠 **El detalle que hay que llevarse:** los binarios oficiales de Node y la enorme mayoría
> de los prebuilds de módulos nativos asumen `glibc`. Con `musl` terminas compilando todo,
> que es exactamente el trabajo que este laboratorio existe para evitarte. **[F14](14-abi-libc-y-prebuilds.md)** explica
> el mecanismo completo.

### 4.3 Imagen normal, no `slim`

También queda cerrada esta: **no usamos `slim` como baseline**. No porque sea mala, sino
porque en una estación de desarrollo moderna el ahorro de unas decenas de megabytes no
compensa tener menos utilidades disponibles, explicar continuamente por qué falta una
herramienta y agregar pasos que no aportan al objetivo didáctico.

Vale la pena decirlo por si genera dudas: incluso la imagen Debian "normal" es
deliberadamente mínima. No estamos hablando de meter GNOME en el contenedor.

### 4.4 `debian/eol:buster` y el archivo histórico

Debian mantiene el repositorio `debian/eol` para releases fuera de soporte, cuyos paquetes
apuntan a `archive.debian.org`. La base conceptual del laboratorio es:

```dockerfile
FROM debian/eol:buster
```

Esto expresa la intención de forma honesta: sí, sabemos que es una distribución EOL, y
precisamente por eso usamos el repositorio histórico preparado para ese caso. No vamos a
disfrazar Debian 10 de distribución moderna.

Por qué importa: cuando una distribución llega al final de su ciclo, sus paquetes se
trasladan de los mirrors activos a repositorios de archivo. Un `Dockerfile` de 2019 que
contenga un `apt-get update` inocente puede fallar hoy simplemente porque la URL original
ya no sirve esa release. Es uno de los fallos más comunes al desenterrar un proyecto, y
tiene su entrada en el catálogo de **[F32](32-catalogo-de-fallos-ii.md)**.

> 🧭 **Reproducibilidad no significa únicamente fijar Node.** También significa saber de
> dónde salen los paquetes Debian, los binarios, las librerías, los checksums y las
> dependencias. Si una de esas fuentes desaparece, tu build "reproducible" se murió y no te
> avisó.

📝 **Nota de época.** En 2019 nadie escribía `FROM debian/eol:buster`, porque Buster era la
estable del momento y `deb.debian.org` respondía perfectamente. Ese `FROM debian:buster`
era correcto entonces y es exactamente lo que falla ahora. No es que el autor original se
equivocara: es que la infraestructura se movió debajo de sus pies.

### 4.5 EOL: qué implica de verdad

Que Debian 10 esté fuera de soporte **no es un impedimento** para este uso —desarrollo,
mantenimiento, compilación, tests y ejecución local— y **sí lo es** para servir tráfico
público o servir de base a un sistema nuevo.

Las restricciones de seguridad no desaparecen por vivir dentro de un contenedor. Por eso el
laboratorio evita exponer servicios innecesarios, publicar la imagen como "segura para
producción", ejecutar contenedores privilegiados sin motivo y guardar secretos dentro de la
imagen. Sobre ese último punto hay una sorpresa desagradable esperando en **[F13](13-overlayfs-y-copy-on-write.md)**: un
secreto que borras en una capa posterior sigue viajando dentro de la imagen.

---

## 5. 🗺️ Decisión 2: las tres zonas del laboratorio

Si no definimos con precisión dónde vive cada cosa, terminamos con código copiado dentro de
imágenes, `node_modules` mezclados entre Windows y Linux, un Node moderno ejecutando por
accidente scripts legacy, y un contenedor tan lleno de cosas que parece una máquina virtual
con crisis de identidad. 😄

El laboratorio se divide en tres zonas:

```mermaid
flowchart TD
    A["ZONA A · HOST<br/>Git · repositorio · código fuente<br/>configuración del proyecto · editor o IDE"]
    B["ZONA B · TOOLCHAIN CONTAINER<br/>Debian 10 · Node · npm · Python<br/>compiladores · Git y utilidades<br/>dependencias del sistema"]
    C["ZONA C · BROWSER TESTING (opcional)<br/>Chromium · Firefox · Selenium standalone<br/>Xvfb · librerías gráficas"]
    A -- "bind mount" --> B
    B -. "solo si el proyecto lo pide" .-> C
```

La **Zona C** solo aparece cuando el proyecto la necesita, y vive en su propio contenedor,
no dentro del toolchain. Su desarrollo completo está en **[a09](a09-browsers-legacy.md)**.

### 5.1 La regla de oro y el directorio estándar

> 🥇 **Nunca necesitamos reconstruir la imagen porque cambió `src/App.vue`.**

El código se monta desde el host con un bind mount, que es exactamente el mecanismo que
Docker recomienda cuando host y contenedor comparten código durante desarrollo. El archivo
que editas en VS Code, WebStorm o Vim es **el mismo archivo** que Node ve dentro del
contenedor: no hay copia ni sincronización.

Dentro del contenedor, el proyecto siempre vive en la misma ruta:

```mermaid
flowchart LR
    subgraph HOST
        W["C:\dev\old-vue"]
        M["/Users/oskar/dev/old-vue"]
        L["/home/me/proyecto"]
    end
    subgraph CONTENEDOR
        WS["/workspace"]
    end
    W -- "bind mount" --> WS
    M -- "bind mount" --> WS
    L -- "bind mount" --> WS
```

Usar `/workspace` siempre tiene una ventaja concreta: todas las guías, scripts y ejemplos
del curso pueden hablar el mismo idioma sin preguntarte dónde tienes tú el repositorio.

```bash
cd /workspace
npm ci
npm test
npm run build
```

---

## 6. 💾 Decisión 3: `node_modules` va en un named volume

Aquí está la decisión que más desconcierta al principio y la que más problemas evita
después.

El repositorio vive en el host. Pero **no queremos que las dependencias compiladas para
Linux queden mezcladas con las del host**, y eso importa especialmente cuando el proyecto
tiene módulos como `node-sass`, `sqlite3`, `canvas` o `sharp`, que no son JavaScript sino
binarios compilados para un sistema operativo, una arquitectura y una versión de Node
concretos.

Por eso el montaje es doble:

```mermaid
flowchart LR
    H["HOST<br/>código fuente"] -- "bind mount" --> WS["/workspace"]
    V[("NAMED VOLUME<br/>node_modules")] -- "volume mount" --> NM["/workspace/node_modules"]
```

El segundo mount va **encima** del primero, sobre un subdirectorio. Si eso te parece raro
ahora mismo, es normal: **[F09](09-montar-tu-proyecto.md)** lo monta con los comandos reales y explica por qué un mount
puede ocultar contenido de otro.

Lo que ganamos, en tres puntos concretos:

**El host permanece limpio.** No dejamos miles de archivos Linux en tu filesystem, ni tienes
que decidir si añadir `node_modules` al `.gitignore` de un proyecto ajeno.

**Los módulos nativos pertenecen al Linux que los compiló.** Un `node_modules` generado en
Windows y uno generado en Debian 10 no son intercambiables aunque el `package.json` sea
idéntico, y el error que produce mezclarlos no dice en ningún momento "mezclaste dos
sistemas operativos".

**Puedes cambiar de versión de Node sin contaminar nada**, siempre que nombres los
volúmenes por proyecto **y** por generación:

```text
myproject-node10-modules
myproject-node12-modules
myproject-node14-modules
```

> ⚠️ **La trampa que esto evita.** Un addon nativo compilado para Node 10 no funciona en
> Node 12, aunque el paquete sea el mismo y la instalación no dé error. Reutilizar el
> volumen entre versiones produce fallos en tiempo de ejecución que parecen bugs del
> proyecto. El mecanismo —el ABI y el `NODE_MODULE_VERSION`— está en **[F14](14-abi-libc-y-prebuilds.md)**.

Y el corolario: **la imagen tampoco contiene `node_modules`**. La imagen tiene el toolchain
reutilizable; el volumen tiene las dependencias de un proyecto concreto; el host tiene el
código. Tres cosas, tres sitios, sin solapamiento.

---

## 7. 🟢 Decisión 4: cuatro generaciones de Node, y las CLIs son del proyecto

### 7.1 Las versiones baseline

| Node | Nombre LTS | npm incluido | Estado |
|---|---|---|---|
| **10.24.1** | Dubnium | 6.14.12 | EOL desde abril 2021 |
| **12.22.12** | Erbium | 6.14.16 | EOL desde abril 2022 |
| **14.21.3** | Fermium | 6.14.18 | EOL desde abril 2023 |
| **16.20.2** | Gallium | 8.19.4 | EOL desde septiembre 2023 |

Son las últimas releases de sus respectivas ramas. Todas están fuera de soporte, y eso aquí
no es una sorpresa ni un error: estamos construyendo deliberadamente un ambiente para
software legacy.

**Node 10.24.1 con npm 6.14.12 es el baseline** que atraviesa el curso.

> ⚠️ **Node 16 cambia una cosa importante:** trae npm 8, no npm 6. Eso altera el formato del
> `package-lock.json` (v2 en lugar de v1) y la resolución de peer dependencies. No es un
> detalle menor cuando tu proyecto tiene un lockfile de 2019, y **[F11](11-validar-tu-proyecto.md)** lo trata al validar.

### 7.2 Las CLIs pertenecen al proyecto, no a la imagen

En la época que estudiamos era frecuente trabajar con Angular CLI, Vue CLI, Webpack CLI,
TypeScript, ESLint, Prettier, Jest, Karma, Gulp y Grunt. Podríamos instalarlas globalmente
en la imagen:

```bash
npm install -g @angular/cli
```

Y entonces hay que responder inmediatamente: **¿qué versión?** ¿Angular CLI 7, 8 o 9? ¿Vue
CLI 3 o 4? ¿Webpack CLI de qué generación? La imagen terminaría imponiendo decisiones que
pertenecen al proyecto, y dejaría de servir para dos repositorios distintos — que era todo
el punto de separar el toolchain del proyecto.

> 🧭 **Regla:** las CLIs de framework se instalan como **dependencias locales del proyecto**.
> El `package.json` manda.

Un proyecto Angular que declara `"@angular/cli": "8.3.29"` en sus `devDependencies` ya te
está diciendo qué CLI necesita. Nuestro trabajo no es adivinarlo: es darle un entorno donde
`npm ci` pueda instalarlo y `npm run` pueda ejecutarlo.

El desarrollo completo —cómo se ejecuta una CLI local, qué pinta el `PATH`, cuándo `npx` es
útil y cuándo descarga cosas que no esperabas, y por qué de momento no usamos Yarn— está en
**[a02](a02-estrategia-node-y-clis.md)**, que es opcional y bastante entretenido.

### 7.3 Una nota sobre arquitectura

El baseline del laboratorio es `linux/amd64`, y `linux/arm64` es la variante adicional.
Puede sonar contradictorio después de lo que dijo [F00](00-problema-y-contrato.md) sobre Apple Silicon, así que conviene
adelantar el porqué: los binarios de Node existen para las dos, pero **los prebuilds de las
dependencias nativas de la época casi siempre existen solo para `linux-x64`**. Elegir amd64
de baseline maximiza la probabilidad de que un `npm ci` de 2019 funcione sin compilar nada.

La discusión completa —qué cuesta la emulación, cuándo conviene arm64 nativo, y cómo se
decide caso por caso— es de **[F21](21-arquitecturas-y-emulacion.md)** y **[F23](23-estudios-de-caso-multiplataforma.md)**.

---

## 8. ⚠️ Errores comunes en esta fase

**Elegir la distribución por costumbre y no por compatibilidad.** Es el reflejo natural
—*"uso Ubuntu 24.04 porque es lo que conozco"*— y produce un laboratorio donde cada
dependencia nativa falla por una razón distinta. La pregunta de §4.1 existe para
interrumpir ese reflejo.

**Montar `node_modules` desde el host "porque es más simple".** Funciona el primer día, y
el día que aparece un módulo nativo produce un error que no menciona ni al host ni al
volumen. Es el error más caro de esta fase porque el síntoma aparece muy lejos de la causa.

**Instalar la CLI global "solo esta vez".** Suele empezar como un atajo para un proyecto y
termina con una imagen que sirve para ese proyecto y para ninguno más.

**Leer `debian/eol:buster` como una imagen de peor calidad.** Es la misma Debian 10; lo que
cambia es a qué repositorios apunta su `sources.list`. Sin ese cambio, `apt-get update`
simplemente no funciona hoy.

---

## 9. 📋 Checklist de validación

Esta fase se valida entendiendo. Las dos comprobaciones ejecutables son opcionales pero
convierten las decisiones en algo que has visto con tus ojos:

```text
[ ] Puedes decir por qué Debian 10 y no 11, 9, Ubuntu o Alpine, con un argumento por opción
[ ] Sabes qué cambia exactamente entre `debian:buster` y `debian/eol:buster`
[ ] Puedes dibujar las tres zonas y colocar en ellas: App.vue, node-sass, gcc, .git
[ ] Sabes por qué node_modules no va ni en el host ni en la imagen
[ ] Puedes nombrar las cuatro versiones baseline y decir cuál trae npm 8
[ ] Sabes explicar por qué @angular/cli no va en la imagen

Opcional, si ya tienes un motor instalado:
[ ] docker manifest inspect debian/eol:buster    → confirma que hay arm64 y amd64
[ ] docker run --rm debian/eol:buster cat /etc/apt/sources.list  → apunta a archive.debian.org
```

---

## 10. 🧪 Ejercicios de la Fase 01 (4)

> 🧭 **Fase exenta del mínimo de 20**, como [F00](00-problema-y-contrato.md): aquí se decide, no se construye. Los cuatro
> ejercicios son de lectura y criterio, y no cuentan para el mínimo del curso.

### 🟢 Ejercicio 1 — Comprueba las dos afirmaciones incómodas

Ejecuta las dos comprobaciones opcionales del checklist. La primera lista las
arquitecturas para las que existe la imagen base; la segunda muestra a qué repositorios
apunta.

**Pregunta:** ¿qué línea del `sources.list` explica por qué esta imagen sigue funcionando
años después del EOL, y qué habría pasado con un `FROM debian:buster`?

### 🟡 Ejercicio 2 — Coloca tu proyecto en las tres zonas

Toma tu proyecto legacy y clasifica diez de sus archivos o directorios reales —incluye
`package.json`, `package-lock.json`, `.git/`, `node_modules/` si existe, y cualquier
dependencia nativa que encontraras en el ejercicio 2 de [F00](00-problema-y-contrato.md)— en las zonas A, B y C.

**Objetivo:** descubrir que casi todo es zona A, que la zona B no contiene nada tuyo, y que
`node_modules` es el único que no encaja limpiamente en ninguna. Esa incomodidad es
exactamente la razón del named volume.

### 🟠 Ejercicio 3 — Rebate un Dockerfile ajeno

Este fragmento aparece en muchos tutoriales de "dockerizar tu app de Angular":

```dockerfile
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y nodejs npm
RUN npm install -g @angular/cli@latest
WORKDIR /app
COPY . .
RUN npm install
```

**Pregunta:** identifica las cinco decisiones que contradicen lo cerrado en esta fase. Para
cada una, di qué error concreto va a producir y en qué momento aparecerá — al construir, al
instalar o en tiempo de ejecución. La quinta es la más sutil y tiene que ver con `@latest`.

### 🟠 Ejercicio 4 — Defiende el named volume ante un escéptico

Un compañero propone simplificar: *"montemos el proyecto entero con bind mount,
`node_modules` incluido; así puedo abrir las dependencias en mi editor y es un mount menos
que explicar"*.

**Objetivo:** construir la respuesta que reconozca lo que su propuesta gana de verdad —es
más simple y sí permite inspeccionar dependencias— y después describa el escenario exacto en
que se rompe: qué proyecto, qué dependencia, qué comando y qué mensaje de error vería. Si
no puedes describir el escenario concreto, todavía no entiendes la decisión.

---

## 11. 📚 Referencias

**Debian y su archivo histórico**
- Debian 10 Buster, página de la release: https://www.debian.org/releases/buster/
- Archivo histórico de paquetes: https://archive.debian.org
- Snapshots por fecha, para reproducir un estado concreto: https://snapshot.debian.org
- Imágenes EOL en Docker Hub: https://hub.docker.com/r/debian/eol

**Almacenamiento y montajes**
- Docker — Bind mounts: https://docs.docker.com/engine/storage/bind-mounts/
- Docker — Volumes: https://docs.docker.com/engine/storage/volumes/

**Node y npm**
- Calendario de releases y fechas de EOL: https://github.com/nodejs/Release
- npm 6, documentación: https://docs.npmjs.com

> ⚠️ **Dos advertencias sobre estos enlaces.** La documentación de npm en `docs.npmjs.com`
> describe versiones muy posteriores a la 6 que usamos: úsala para entender conceptos, no
> para comportamiento exacto. Y `archive.debian.org` es infraestructura de archivo, no un
> mirror con garantías de disponibilidad: si un día responde lento, no es tu red.

**Orden de lectura sugerido:** la página de Buster para situarte, el archivo histórico para
entender de dónde vienen los paquetes, y los dos enlaces de almacenamiento justo antes de
empezar [F09](09-montar-tu-proyecto.md), que es donde los vas a usar.

---

## 12. 🏁 Resultado de la fase

Sigue sin haber imagen. Lo que hay son cuatro decisiones cerradas que ninguna fase posterior
vuelve a discutir:

```text
BASE          debian/eol:buster — Debian 10, imagen normal, no slim
              EOL declarado · paquetes desde archive.debian.org

ZONAS         A · host        → código, Git, editor
              B · contenedor  → Debian, Node ×4, npm, Python, compiladores
              C · opcional    → navegadores y Selenium, en su propio contenedor

RUTAS         proyecto        → /workspace          (bind mount desde el host)
              node_modules    → /workspace/node_modules  (named volume)
              volumen         → <proyecto>-node<NN>-modules

NODE          10.24.1 · 12.22.12 · 14.21.3 · 16.20.2
              baseline 10.24.1 con npm 6.14.12
              CLIs de framework → dependencias del proyecto, nunca de la imagen

ARQUITECTURA  linux/amd64 baseline · linux/arm64 adicional
```

> **La señal de que quedó bien:** *"si mañana me dan otro proyecto legacy, distinto
> framework y distinta CLI, uso exactamente la misma imagen y solo cambia el nombre del
> volumen."*

En **[F02](02-dockerfile-esencial.md)** dejamos de decidir y empezamos a escribir: qué es un `Dockerfile`, en qué se
diferencia de una imagen y de un contenedor, y las instrucciones que vamos a usar durante
todo el curso.
