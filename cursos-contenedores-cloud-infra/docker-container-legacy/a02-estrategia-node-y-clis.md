# 🧰 Apéndice a02 — Estrategia de Node y CLIs, a fondo

> **Curso:** Docker Legacy Node · **Apéndice opcional**
> **Cierra los bucles de:** [F01](01-decisiones-debian-zonas-node.md) §7.2 · [F06](06-instalacion-node.md) §5 · [F08](08-run-el-contenedor-como-proceso.md) §6
> **Requisitos:** haber hecho F06 y F08, o al menos tenerlas a mano
> **Qué encontrarás:** el razonamiento largo detrás de decisiones que las fases toman en dos líneas — por qué no `nvm`, por qué no NodeSource, por qué no compilar desde source, por qué no `FROM node:10`, qué es el `PATH` y por qué `npm run` lo cambia, cuándo `npx` te ayuda y cuándo te sabotea, y por qué de momento no hay Yarn

Ningún apéndice es requisito de ninguna fase. Este existe porque [F01](01-decisiones-debian-zonas-node.md) y [F06](06-instalacion-node.md) cierran cinco
discusiones con una frase cada una, y hay lectores —probablemente tú, si estás aquí— que
quieren la discusión entera.

---

## 🧭 Índice de salto rápido

| Si tu pregunta es… | Ve a |
|---|---|
| "¿Por qué no `nvm`, que es lo que usa todo el mundo?" | [§1](#1--por-qué-no-nvm) |
| "¿Y NodeSource? Tienen repositorios oficiales" | [§2](#2--por-qué-no-nodesource) |
| "¿Por qué no compilar Node desde el código fuente?" | [§3](#3--por-qué-no-compilar-desde-source) |
| "`FROM node:10` es una línea. ¿Por qué sesenta?" | [§4](#4--por-qué-no-from-node10) |
| "¿Cómo encuentra el sistema el comando `node`?" | [§5](#5-️-el-path-y-por-qué-npm-run-lo-cambia) |
| "¿Puedo instalar `@angular/cli` global, aunque sea una vez?" | [§6](#6--clis-globales-la-excepción-y-su-precio) |
| "¿Qué hace exactamente `npx`?" | [§7](#7--npx-cómodo-y-peligroso-a-partes-iguales) |
| "¿Por qué no hay Yarn?" | [§8](#8--yarn-todavía-no) |
| "Quiero construir con otras versiones de Node" | [§9](#9-️-parametrizar-el-conjunto-de-versiones) |
| "¿Cuánto cuesta la emulación en Apple Silicon?" | [§10](#10--riesgos-de-la-emulación-lo-que-sí-importa) |

---

## 1. 🚫 Por qué no `nvm`

`nvm` es la herramienta más conocida para instalar y cambiar versiones de Node, y en una
estación de desarrollo convencional es excelente. La objeción de este laboratorio no es de
calidad: es de arquitectura.

**Ya tenemos un mecanismo de aislamiento.** Se llama contenedor. Añadir `nvm` mete una capa
más que no resuelve nada nuevo:

```mermaid
flowchart TD
    H["Host"] --> D["Docker / Podman<br/>aísla el sistema entero"] --> C["Contenedor"]
    C --> N["nvm<br/>aísla versiones de Node… dentro de algo ya aislado"] --> NO["Node"]
```

**Perdemos control sobre lo que queremos controlar.** El diseño de [F06](06-instalacion-node.md) fija explícitamente
dónde se descarga cada Node, qué archivo exacto, qué checksum se verifica, qué versiones
quedan instaladas y cuál está activa. `nvm` toma varias de esas decisiones por su cuenta, y
cuando algo falle vas a estar depurando su lógica en lugar de la tuya.

**Y hay un problema práctico serio dentro de un contenedor.** `nvm` no es un binario: es un
conjunto de funciones de shell que se cargan desde `~/.bashrc` o `~/.nvm/nvm.sh`. Eso
significa que:

- Un `docker exec contenedor node --version` **no lo encuentra**, porque `exec` no ejecuta un
  login shell y no carga el perfil.
- Funciona si haces `docker exec -it contenedor bash` y después escribes `node`, pero no si
  lanzas el comando directamente — que es exactamente como funcionan las tasks de [F10](10-vscode-y-debugging.md) y los
  scripts de [F09](09-montar-tu-proyecto.md).
- La diferencia entre las dos formas es sutil, y el error que produce (`node: command not
  found` en un contenedor donde `node` claramente existe) es de los más desconcertantes del
  mundo Docker.

> 🧠 **La comparación honesta.** `nvm` está diseñado para un desarrollador que trabaja
> interactivamente en su máquina, cambiando de proyecto a lo largo del día. Nuestro caso es
> otro: un runtime fijo por contenedor, invocado desde scripts. Los shims de [F08](08-run-el-contenedor-como-proceso.md) hacen lo
> mismo que `nvm use` sin depender del shell, y por eso funcionan igual desde `docker exec`.

**Cuándo `nvm` sí es la elección correcta:** cuando trabajas nativamente en tu host, sin
contenedores, y necesitas alternar versiones a lo largo del día. Si además tu host es Linux
x86-64, es probablemente lo más cómodo que hay.

---

## 2. 🚫 Por qué no NodeSource

NodeSource publica repositorios APT por versión de Node, y durante años fue la forma estándar
de instalar Node en Debian y Ubuntu. La instalación es de dos líneas y funciona.

**Tres razones para no usarlo aquí.**

**Añade una dependencia externa que tiene que seguir viva.** Nuestro build necesita que el
repositorio de NodeSource para Node 10 siga respondiendo hoy, con la misma URL, la misma clave
GPG y el mismo contenido. Es una apuesta sobre la infraestructura de un tercero, y las ramas
antiguas han ido desapareciendo de sus repositorios conforme llegaban a EOL — que es
exactamente el rango que nos interesa.

**Instala una versión por repositorio.** Añadir cuatro generaciones significaría cuatro
repositorios, cuatro claves y cuatro instalaciones que se pisan entre sí, porque APT instala
en las rutas del sistema. Es pelear contra el gestor de paquetes para conseguir algo que él no
está diseñado para hacer.

**Oculta el artefacto.** Con un tarball sabes exactamente qué archivo bajaste y puedes
verificar su SHA-256 contra el `SHASUMS256.txt` que publica el propio proyecto Node, como hace
[F06](06-instalacion-node.md). Con un `.deb` de un tercero, la cadena de confianza pasa por ese tercero.

**Cuándo NodeSource sí tiene sentido:** una imagen de producción con **una** versión de Node
razonablemente actual, donde quieres que el gestor de paquetes se encargue de las
actualizaciones de seguridad. Nada que ver con nuestro caso.

---

## 3. 🚫 Por qué no compilar desde source

Compilar Node desde su código fuente es perfectamente posible y da el máximo control. También
es la peor opción de las cinco para este laboratorio.

**El coste es desproporcionado.** Compilar V8 tarda entre veinte minutos y más de una hora
según la máquina, por cada versión. Multiplícalo por cuatro y cada build limpio de la imagen
se convierte en una tarde.

**Compilar Node 10 hoy es un problema en sí mismo.** Necesita una versión de GCC y de Python
compatible con las herramientas de build de 2018 — que es un problema parecido al que estamos
intentando resolver, y meta a más no poder.

**No aporta nada que necesitemos.** Compilarías desde source para aplicar un parche, cambiar
opciones de compilación o dar soporte a una plataforma sin binarios oficiales. Ninguno de los
tres es nuestro caso: los binarios oficiales existen para `linux-x64` y `linux-arm64` en las
cuatro generaciones.

**Cuándo sí:** cuando necesitas una plataforma exótica sin binarios oficiales, o cuando
investigas un bug del propio runtime. Los dos son escenarios legítimos y ninguno es un
laboratorio de mantenimiento.

---

## 4. 🚫 Por qué no `FROM node:10`

Esta es la objeción más razonable de las cinco, y merece la respuesta más cuidadosa — porque
para la mayoría de los proyectos, `FROM node:10` **es la elección correcta**.

Lo que gana: una línea en lugar de sesenta, mantenimiento ajeno, imágenes oficiales bien
construidas, y `node`, `npm` y `npx` funcionando sin que escribas nada.

**Y aun así no sirve aquí, por dos razones que no son de gusto.**

**Te da una versión, no cuatro.** El toolchain de este curso existe para atender proyectos con
generaciones distintas usando **la misma imagen**. Con `FROM node:10` necesitarías cuatro
imágenes, cada una con su toolchain de compilación duplicado, y cambiar de generación
significaría cambiar de imagen en lugar de una variable de entorno.

**Te ata a la Debian que esa imagen eligiera.** Las imágenes oficiales de Node basan cada
generación en la Debian estable del momento de su publicación, y varias se rebasan a
distribuciones más nuevas a lo largo de su vida. No controlas cuál te toca, y eso contradice
directamente la decisión de [F01](01-decisiones-debian-zonas-node.md): **la distribución es una decisión de compatibilidad, no un
detalle de implementación**. Un proyecto que compila contra `glibc` 2.28 de Buster puede
comportarse distinto sobre Bullseye o Bookworm, y averiguar por qué es exactamente el tipo de
tarde que este curso intenta evitarte.

Hay una tercera, menor pero real: las imágenes oficiales traen su propio conjunto de paquetes,
su propio usuario `node`, su propio entrypoint y sus propias decisiones. Ninguna es mala; todas
son decisiones que no tomaste tú y que tendrás que descubrir cuando algo no encaje.

> 🧭 **Cuándo `FROM node:10` es lo correcto**, y conviene decirlo claro: cuando tienes **un**
> proyecto, con **una** versión de Node, y no necesitas controlar la distribución base. Es
> decir, la enorme mayoría de los casos. Si eso te describe, usa la imagen oficial y ahórrate
> este curso — o al menos, esta parte de él. 😄

---

## 5. 🛣️ El `PATH` y por qué `npm run` lo cambia

Cuando escribes `node` en una shell, el sistema tiene que averiguar qué programa ejecutar. Lo
hace recorriendo los directorios de la variable `PATH`, en orden, y quedándose con el primero
que encuentre.

```bash
echo $PATH
```
```text
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

Eso explica el diseño de [F06](06-instalacion-node.md) y [F08](08-run-el-contenedor-como-proceso.md): los shims viven en `/usr/local/bin`, que aparece **antes**
que `/usr/bin`, así que ganan sobre cualquier `node` que pudiera instalar APT.

```bash
command -v node        # qué se ejecutaría
readlink -f $(command -v node)   # a dónde apunta de verdad
```

### 5.1 El truco de `npm run`

Aquí está la pieza que hace posible la regla de [F01](01-decisiones-debian-zonas-node.md) —las CLIs pertenecen al proyecto—.

**Durante un `npm run`, npm añade `node_modules/.bin` al principio del `PATH`.** Ese
directorio contiene enlaces a los ejecutables de todas tus dependencias.

```text
PATH normal:              /usr/local/bin:/usr/bin:/bin
PATH durante npm run:     ./node_modules/.bin:/usr/local/bin:/usr/bin:/bin
                          └────────┬────────┘
                                   └── aquí está TU versión de webpack, ng, vue-cli-service…
```

Por eso esto funciona:

```json
{ "scripts": { "build": "vue-cli-service build" } }
```

```bash
npm run build      # ✅ encuentra vue-cli-service en node_modules/.bin
vue-cli-service build   # ❌ command not found, si no está instalado global
```

Compruébalo tú mismo dentro del contenedor:

```bash
npm run env | grep '^PATH='
ls node_modules/.bin/ | head
```

> 🧠 **El patrón a memorizar.** `npm run` no es solo un atajo para no escribir rutas: es lo que
> garantiza que se ejecute **la versión que el proyecto declaró**, y no la que alguien instaló
> globalmente en la imagen hace dos años. Es la razón de que el curso lo use siempre.

---

## 6. 🌍 CLIs globales: la excepción y su precio

La regla de [F01](01-decisiones-debian-zonas-node.md) dice que las CLIs de framework son dependencias del proyecto. La regla admite
excepciones, y conviene saber cuáles.

**Casos legítimos:**

- Un proyecto muy viejo cuyos scripts asumen que `ng` o `gulp` existen globalmente, y donde
  cambiar el `package.json` no es una opción.
- Herramientas que no pertenecen a ningún proyecto en particular y que usas para inspeccionar:
  un `npm-check` o similar.
- Un flujo interno de tu empresa que lo exige y que no vas a poder cambiar hoy.

**El precio, para que la decisión sea informada:**

Instalar `npm install -g @angular/cli` en la imagen la convierte en una imagen **para ese
proyecto**. El siguiente repositorio de 2018 que te llegue probablemente use otra versión del
CLI, y entonces tienes dos opciones malas: otra imagen, o un conflicto silencioso donde el CLI
global y el local compiten y ninguno de los dos avisa.

**Si tienes que hacerlo, hazlo bien:**

```dockerfile
# ⚠️ CLI global: ata esta imagen a un proyecto concreto. Documenta por qué.
ARG ANGULAR_CLI_VERSION=8.3.29
RUN npm install -g "@angular/cli@${ANGULAR_CLI_VERSION}"
```

Con versión exacta, como `ARG` para poder cambiarla sin editar el archivo, y con el comentario
que explica por qué se aceptó la excepción. Una CLI global sin versión fijada es de las cosas
que peor envejecen.

---

## 7. ⚡ `npx`: cómodo y peligroso a partes iguales

`npx` ejecuta un binario de `node_modules/.bin` sin que tengas que añadirlo a los scripts:

```bash
npx vue-cli-service build
```

Hasta ahí es cómodo y no hay objeción. **El problema es lo que hace cuando no lo encuentra.**

> 🚨 **`npx` descarga.** Si el comando no está en `node_modules/.bin`, npx lo **busca en el
> registry, lo descarga y lo ejecuta**. En npm 6 lo hace sin preguntar de forma clara, y con la
> versión más reciente que encuentre.

Las consecuencias en un laboratorio legacy son concretas:

- Ejecutas `npx tsc` esperando el TypeScript 3.5 de tu proyecto y te ejecuta el TypeScript
  actual, que compila tu código de otra manera.
- Un comando que "funcionaba" deja de funcionar seis meses después porque la versión que
  descarga cambió — y tu lockfile no tiene nada que ver con eso.
- En una máquina sin Internet, un `npx` que antes funcionaba falla de forma incomprensible.

**La regla del curso:** `npm run` primero, siempre. `npx` solo cuando sepas que el binario está
en `node_modules/.bin`, y si quieres estar seguro, compruébalo:

```bash
ls node_modules/.bin/ | grep tsc
```

En npm 7 y posteriores `npx` pregunta antes de descargar, pero nuestro baseline es npm 6 y ahí
no lo hace.

---

## 8. 🧶 Yarn: todavía no

Yarn fue muy común en el periodo 2017–2020 y es probable que algún proyecto que te llegue
tenga un `yarn.lock` en lugar de un `package-lock.json`.

**No está en el baseline**, por una razón de alcance: cada gestor de paquetes trae su propio
formato de lock, su propia resolución y sus propios modos de fallo, y meter los dos en el
curso duplicaría el material de validación de [F11](11-validar-tu-proyecto.md) sin enseñar nada nuevo sobre contenedores.

**Qué hacer si tu proyecto usa Yarn.** La respuesta corta es que el laboratorio funciona igual:
añade Yarn a la imagen fijando la versión, y sustituye `npm ci` por `yarn install --frozen-lockfile`,
que es su equivalente exacto —instala lo que dice el lock y falla si no cuadra—.

```dockerfile
# Yarn 1.x, la generación contemporánea de nuestros proyectos objetivo
ARG YARN_VERSION=1.22.19
RUN npm install -g "yarn@${YARN_VERSION}"
```

Lo que **no** debes hacer es mezclar: un proyecto con `yarn.lock` al que le ejecutas `npm ci`
resuelve un árbol distinto, y ahí tienes un problema nuevo encima del que ya tenías.

> ⚠️ **Yarn 1 está en mantenimiento y Yarn 2+ (Berry) es otra herramienta**, con Plug'n'Play y
> un modelo de resolución distinto. Un proyecto de 2019 casi siempre quiere Yarn 1.x, y usar
> Berry sobre él es un cambio mayor, no una actualización.

---

## 9. 🛠️ Parametrizar el conjunto de versiones

[F06](06-instalacion-node.md) fija cuatro generaciones, pero eso es un **baseline predeterminado**, no una restricción
del diseño. Los cinco `ARG` del Dockerfile existen para eso:

```bash
# solo dos generaciones, imagen más pequeña y build más rápido
docker build \
  --build-arg NODE12_VERSION= \
  --build-arg NODE16_VERSION= \
  --platform linux/amd64 -t legacy-node-toolchain:solo-10-14 .

# una generación distinta a las del baseline
docker build \
  --build-arg NODE14_VERSION=14.17.0 \
  --platform linux/amd64 -t legacy-node-toolchain:node14-17 .

# otro default activo
docker build \
  --build-arg DEFAULT_NODE_VERSION=16.20.2 \
  --platform linux/amd64 -t legacy-node-toolchain:default16 .
```

La línea del bucle que hace posible vaciar una versión es esta:

```bash
[[ -n "${version}" ]] || continue;
```

**Dónde está el límite.** Puedes pedir cualquier versión que exista en `nodejs.org/dist` con
binario `linux-x64`, pero no cualquier versión funciona sobre Debian 10: las ramas modernas de
Node exigen una `glibc` más nueva que la 2.28 de Buster. Node 18 en adelante no arranca ahí, y
el error que da —algo sobre `GLIBC_2.29 not found`— es informativo si sabes leerlo y
desconcertante si no. **[F14](14-abi-libc-y-prebuilds.md)** explica el mecanismo.

---

## 10. 🐢 Riesgos de la emulación: lo que sí importa

[F01](01-decisiones-debian-zonas-node.md) fija `linux/amd64` como baseline y `linux/arm64` como variante adicional. En un Mac con
Apple Silicon eso significa emulación, y conviene saber qué cuesta de verdad.

**El coste de rendimiento es real y variable.** La traducción de x86-64 a ARM64 la hace QEMU
—o Rosetta 2, según el motor y su configuración—, y el factor depende muchísimo de la carga:
un `npm ci` mayormente de red y disco apenas lo nota; una compilación de módulo nativo con
`gcc` puede tardar varias veces más. **[F23](23-estudios-de-caso-multiplataforma.md)** mide esto con números en lugar de estimaciones.

**Los riesgos que sí importan, y no son el rendimiento:**

- **Fallos que solo aparecen bajo emulación.** Determinadas operaciones —ciertas llamadas al
  sistema, algún uso de instrucciones vectoriales— pueden fallar o comportarse distinto. Son
  raros y muy difíciles de diagnosticar si no sospechas de la capa de traducción.
- **Confundir la arquitectura de la imagen con la del host.** Es la causa del `exec format
  error` y de la mitad de los problemas de F21. Por eso el curso comprueba `uname -m` como
  rutina.
- **`node_modules` compilado bajo una arquitectura y usado en otra.** Es la razón de que el
  nombre del volumen lleve la versión, y en ARM64 conviene que lleve también la arquitectura.

**Y el argumento a favor de amd64 que decide la cuestión:** los prebuilds de las dependencias
nativas de 2018 se publicaron mayoritariamente para `linux-x64`. Construir en amd64 maximiza
la probabilidad de que `npm ci` no tenga que compilar nada — y compilar es donde de verdad se
va el tiempo, emulación o no.

> 🧭 **Cuándo cambiar a `linux/arm64`:** cuando midas que tu proyecto no necesita prebuilds
> x64, o cuando el tiempo de emulación te esté costando más que compilar los módulos nativos
> desde source. Las dos condiciones se comprueban, no se estiman. **[F22](22-apple-silicon-y-hosts.md)** y **[F23](23-estudios-de-caso-multiplataforma.md)** dan el
> método.

---

## 🧭 Guía rápida: cuándo usar qué

| Tu situación | Elige |
|---|---|
| Un proyecto, una versión de Node, sin exigencias sobre la distro | **`FROM node:NN`**. Y sáltate este apéndice |
| Varios proyectos legacy con generaciones distintas | **tarballs oficiales**, como [F06](06-instalacion-node.md) |
| Desarrollo nativo en tu host, sin contenedores | **`nvm`** |
| Producción con una versión de Node mantenida | **NodeSource** o imagen oficial |
| Plataforma exótica o investigas un bug del runtime | **compilar desde source** |
| Ejecutar un binario del proyecto | **`npm run`**, siempre |
| Ejecutar un binario que sabes que está en `node_modules/.bin` | `npx`, comprobando antes |
| El proyecto trae `yarn.lock` | **Yarn 1.x** con `--frozen-lockfile`, nunca mezclado con npm |
| Mac ARM y el proyecto tiene dependencias nativas de 2018 | **`linux/amd64`** emulado, por los prebuilds |
| Mac ARM y el proyecto es JavaScript puro | prueba **`linux/arm64`** nativo y mide |

---

## 🧪 Ejercicios (8)

### 🟢 Ejercicio 1 — El `PATH` durante `npm run`

Dentro de un contenedor con un proyecto instalado, ejecuta `npm run env | grep '^PATH='` y
compáralo con `echo $PATH`.

**Pregunta:** ¿qué directorio se añadió y en qué posición? ¿Por qué la posición importa?

### 🟢 Ejercicio 2 — `npm run` contra el binario directo

Ejecuta un binario del proyecto de las dos formas: con `npm run` y escribiendo su nombre a
secas.

**Objetivo:** ver el `command not found` y entender que no es que falte, es que no está en el
`PATH` de esa shell.

### 🟡 Ejercicio 3 — `nvm` bajo `docker exec`

Construye una imagen de prueba con `nvm` instalado. Después ejecuta
`docker exec <ct> node --version` y compáralo con entrar por `docker exec -it <ct> bash` y
escribirlo dentro.

**Objetivo:** reproducir el fallo de §1 con tus manos. Es el argumento más concreto de este
apéndice.

### 🟡 Ejercicio 4 — `npx` descarga

Con npm 6, ejecuta `npx cowsay hola` en un proyecto que no tenga esa dependencia y observa la
salida.

**Pregunta:** ¿de dónde salió el programa? ¿Qué versión ejecutaste? ¿Podrías reproducir ese
comando exacto dentro de un año?

### 🟡 Ejercicio 5 — Construye con otro conjunto de versiones

Usa los `ARG` de §9 para construir tres imágenes distintas y compara sus tamaños y su
`/opt/node`.

### 🟠 Ejercicio 6 — El límite de Debian 10

Intenta añadir Node 18.20.0 al bucle del Dockerfile de [F06](06-instalacion-node.md) y construye.

**Pregunta:** ¿falla al descargar, al extraer, o al ejecutar `node --version`? Lee el error
entero y anota la versión de `glibc` que menciona.

### 🟠 Ejercicio 7 — CLI global contra local

Instala `@angular/cli@9` globalmente en una imagen y móntale un proyecto que declare
`@angular/cli@8.3.29` en sus `devDependencies`. Ejecuta `ng version` y después
`npm run ng -- version`.

**Pregunta:** ¿cuál responde cada comando? ¿Cuál de los dos usarías en un script y por qué?

### 🔴 Ejercicio 8 — Decide para tres proyectos reales

Te llegan tres repositorios: uno con `yarn.lock` y Angular 7, uno con `package-lock.json` y
React 16 sin dependencias nativas, y uno con `node-sass` y Node 12.

**Objetivo:** para cada uno, decidir estrategia de instalación de Node, gestor de paquetes,
arquitectura y si hace falta alguna CLI global — y justificar cada decisión con una línea
usando la tabla de la guía rápida. Después di cuál de los tres construirías **primero** y por
qué.

---

## 📚 Referencias

- `nvm`: https://github.com/nvm-sh/nvm
- NodeSource — distribuciones: https://github.com/nodesource/distributions
- Construir Node desde source: https://github.com/nodejs/node/blob/main/BUILDING.md
- Imágenes oficiales de Node: https://hub.docker.com/_/node
- npm 6 — `npm run-script` y el `PATH`: https://docs.npmjs.com/cli/v6/commands/npm-run-script
- npm 6 — `npx`: https://docs.npmjs.com/cli/v6/commands/npx
- Yarn 1 — `install --frozen-lockfile`: https://classic.yarnpkg.com/en/docs/cli/install

> ⚠️ Los enlaces de npm apuntan a la v6 deliberadamente: es la que trae nuestro baseline, y su
> `npx` se comporta distinto al de npm 7+.

**Vuelve a:** [F01 §7.2](01-decisiones-debian-zonas-node.md) · [F06 §5](06-instalacion-node.md) · [F08 §6](08-run-el-contenedor-como-proceso.md)
