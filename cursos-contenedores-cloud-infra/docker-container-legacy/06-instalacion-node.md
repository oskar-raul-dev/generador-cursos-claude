# 🟢 Parte I · Fase 06 — Instalar Node: cuatro generaciones en una sola imagen

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · Node 10.24.1 / 12.22.12 / 14.21.3 / 16.20.2
> **Arquitectura objetivo del laboratorio:** `linux/amd64`
> **Dockerfile pedagógico de esta fase:** `dockerfiles/05-node.Dockerfile`
> **Script que nace aquí:** `scripts/select-node`
> **Tag pedagógico:** `legacy-node-toolchain:phase06`
> **Estado de la imagen al terminar:** el toolchain está completo. Cuatro Node instalados, uno activo, npm y `node-gyp` disponibles
> **Código de esta fase:** [`src/06-instalacion-node/`](src/06-instalacion-node/)
> **Objetivo:** instalar cuatro generaciones de Node desde los tarballs oficiales, verificarlas, y separar dos operaciones que casi todo el mundo confunde: instalar y activar

---

## 1. 🧭 Dónde estamos

`phase05` tiene todo lo que un addon nativo necesita para compilar: utilidades, GCC, `make`,
`pkg-config` y los dos Python. Todo menos lo principal.

Esta fase pone Node. Cuatro versiones, conviviendo en la misma imagen sin pisarse, con un
mecanismo para decidir cuál responde cuando escribes `node`. Al terminarla la imagen ya es
un toolchain de verdad — y `node-gyp`, que [F05](05-python-y-node-gyp.md) dejó apuntado, aparece por fin.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder explicar:

- Por qué instalamos desde los tarballs oficiales y no con APT, NodeSource, `nvm` o
  `FROM node:10`.
- Cómo leer el nombre de un artefacto de Node y qué te dice cada parte.
- Qué hace `--strip-components=1` y por qué sin él la ruta queda ridícula.
- Por qué las cuatro versiones viven en `/opt/node/<version>/` y no se pisan.
- La diferencia entre **instalar** y **activar** una versión, y cómo la resuelve
  `select-node`.
- Por qué verificamos el checksum de cada tarball dentro del propio build.

---

## 3. 🚧 Qué NO entra todavía

- **Checksums, SHA-256, `SHASUMS256.txt` y firmas GPG a fondo** → **[a04](a04-checksums-gpg-y-archivos.md)**. Aquí queda la
  verificación operativa que el build ejecuta, no el tratado.
- **Por qué no `nvm`, NodeSource, compilar desde source ni `FROM node:10`**, con el
  razonamiento largo, `PATH`, `npx` y Yarn → **[a02](a02-estrategia-node-y-clis.md)**. Aquí va la versión corta.
- El **despachador definitivo** que sustituye a `select-node` en runtime → **[F08](08-run-el-contenedor-como-proceso.md)**. El
  `select-node` de esta fase resuelve el build; tiene un límite y lo declaramos.
- El ABI y por qué un addon compilado para Node 10 no sirve en Node 12 → **[F14](14-abi-libc-y-prebuilds.md)**.

---

## 4. 🏺 Cuatro generaciones y su fecha de defunción

| Node | Nombre LTS | npm que trae | Fin de soporte |
|---|---|---|---|
| **10.24.1** | Dubnium | 6.14.12 | abril de 2021 |
| **12.22.12** | Erbium | 6.14.16 | abril de 2022 |
| **14.21.3** | Fermium | 6.14.18 | abril de 2023 |
| **16.20.2** | Gallium | 8.19.4 | septiembre de 2023 |

Son las últimas releases de sus ramas. Todas están fuera de soporte, y en este laboratorio
eso es el punto, no un descuido: si tu proyecto necesitara una versión mantenida, no
estarías aquí.

> ⚠️ **Node 16 rompe la simetría.** Trae **npm 8**, no npm 6. Cambia el formato del
> `package-lock.json` —v2 en lugar de v1— y la resolución de peer dependencies. Un lockfile
> de 2019 abierto con npm 8 puede reescribirse entero, y eso destruye la reproducibilidad que
> este curso intenta enseñar. **[F11](11-validar-tu-proyecto.md)** lo trata al validar; por ahora, tenlo presente.

---

## 5. 📥 Por qué tarballs oficiales

La versión corta de una discusión que **[a02](a02-estrategia-node-y-clis.md)** desarrolla entera:

**APT de Debian 10** trae Node 10.24.0 en el mejor de los casos, y una sola versión. No
sirve para cuatro.

**NodeSource** publica repositorios por versión, pero añade una dependencia externa que
tendría que seguir viva hoy, y sus repositorios de las ramas antiguas han ido
desapareciendo.

**`nvm`** está pensado para un desarrollador en su máquina: descarga en `$HOME`, se integra
con el shell mediante funciones, y dentro de un contenedor con `docker exec` esa integración
se vuelve frágil de una forma que cuesta explicar. [F08](08-run-el-contenedor-como-proceso.md) tiene una sección entera sobre por qué.

**`FROM node:10`** es lo que casi todo el mundo hace, y para un proyecto es razonable. Aquí
no sirve por dos motivos: te da **una** versión, no cuatro, y te ata a la Debian que esa
imagen eligiera —normalmente Stretch o Bullseye—, contradiciendo la decisión de [F01](01-decisiones-debian-zonas-node.md).

Los tarballs oficiales, en cambio, están en `nodejs.org/dist` con URL estable, existen para
todas las versiones que nos interesan, traen su `SHASUMS256.txt` al lado, y no dependen de
nadie más que del proyecto Node.

### 5.1 Leer el nombre de un artefacto

```text
node-v10.24.1-linux-x64.tar.xz
│    │        │     │   │
│    │        │     │   └── formato: tar comprimido con xz
│    │        │     └────── arquitectura: x64, arm64, armv7l…
│    │        └──────────── sistema: linux, darwin, win
│    └───────────────────── versión, con la v delante
└────────────────────────── proyecto
```

Esas cuatro coordenadas son las que decidían, en [F00](00-problema-y-contrato.md), que `node-v10.24.1-darwin-arm64.tar.xz`
sencillamente **no existe**. Aquí las usas al derecho: pedimos `linux-x64` porque es el
baseline que fijó [F01](01-decisiones-debian-zonas-node.md).

### 5.2 `--strip-components=1`

Un tarball de Node se extrae así:

```text
node-v10.24.1-linux-x64/
├── bin/     (node, npm, npx)
├── include/
├── lib/
└── share/
```

Ese directorio raíz con el nombre completo sobra, porque nosotros ya vamos a poner la versión
en la ruta. Sin `--strip-components=1` acabarías con:

```text
/opt/node/10.24.1/node-v10.24.1-linux-x64/bin/node     ← ridículo
```

Con él:

```text
/opt/node/10.24.1/bin/node                              ← lo que queremos
```

La opción le dice a `tar` que descarte el primer nivel de directorios al extraer. Es una de
esas banderas que aparecen en todos los Dockerfiles del mundo sin que nadie explique nunca
qué hacen.

---

## 6. 🌳 Una casa por versión

```text
/opt/node/
├── 10.24.1/
│   ├── bin/   (node, npm, npx)
│   ├── include/   ← las cabeceras que node-gyp necesita
│   ├── lib/
│   └── share/
├── 12.22.12/
├── 14.21.3/
└── 16.20.2/
```

**Por qué `/opt`.** En Unix es el directorio convencional para software instalado fuera del
conjunto base de la distribución. Nos viene bien porque separa con claridad lo que puso
Debian de lo que pusimos nosotros: si algún día hay que auditar la imagen, la frontera está
a la vista.

**Por qué una casa por versión.** Porque la alternativa es que Node 12 pise a Node 10 y
después Node 14 pise a Node 12, que es exactamente lo que hace una instalación normal. Aquí
las cuatro coexisten sin tocarse.

Fíjate en `include/`: ahí viven las cabeceras de C++ de cada versión de Node, y son
**distintas** entre generaciones. Es la razón física de que un addon compilado para Node 10
no funcione en Node 12 — el mecanismo completo está en **[F14](14-abi-libc-y-prebuilds.md)**.

---

## 7. 🔀 Instalar no es activar

Tenemos cuatro Node instalados. Eso responde a *"¿qué runtimes existen en la imagen?"*. Falta
la otra pregunta, que es la que importa cuando abres una shell:

> ¿cuál se ejecuta cuando escribo `node`?

Son preguntas distintas y necesitan mecanismos distintos. El nuestro son **symlinks
controlados** en `/usr/local/bin/`, que está en el `PATH` por delante de todo:

```text
/usr/local/bin/node ──▶ /opt/node/10.24.1/bin/node
/usr/local/bin/npm  ──▶ /opt/node/10.24.1/bin/npm
/usr/local/bin/npx  ──▶ /opt/node/10.24.1/bin/npx
```

Activar Node 14 es reapuntar esos tres enlaces. Mismo nombre de comando, distinto destino.

📄 **`scripts/select-node`**

```bash
#!/usr/bin/env bash

set -euo pipefail

version="${1:-${NODE_VERSION:-}}"

if [[ -z "${version}" ]]; then
    echo "ERROR: debes indicar una versión de Node." >&2
    echo "Uso: select-node <version>" >&2
    exit 2
fi

node_home="/opt/node/${version}"

# si la versión no existe, fallamos temprano y con un mensaje que ayude
if [[ ! -x "${node_home}/bin/node" ]]; then
    echo "ERROR: Node ${version} no está instalado en esta imagen." >&2
    echo "Versiones disponibles:" >&2
    find /opt/node -mindepth 1 -maxdepth 1 -type d -printf '  - %f\n' | sort >&2
    exit 3
fi

ln -sfn "${node_home}/bin/node" /usr/local/bin/node

# npx no existe en todas las generaciones: si falta, retiramos el enlace viejo
for command in npm npx; do
    if [[ -e "${node_home}/bin/${command}" ]]; then
        ln -sfn "${node_home}/bin/${command}" "/usr/local/bin/${command}"
    else
        rm -f "/usr/local/bin/${command}"
    fi
done

echo "Node activo: ${version}"
node --version
npm --version

if command -v npx >/dev/null 2>&1; then
    npx --version
fi
```

**Detalles con intención:**

- `set -euo pipefail` — falla ante el primer error, ante una variable no definida y ante un
  fallo en medio de una tubería. En un script que manipula symlinks del sistema, seguir
  adelante tras un error es peor que parar.
- `"${1:-${NODE_VERSION:-}}"` — acepta la versión como argumento y, si no la das, cae en la
  variable de entorno. Los dos `:-` evitan que `set -u` haga explotar el script cuando no hay
  ninguna de las dos.
- **Falla temprano y con la lista de versiones disponibles.** Un `ERROR: Node 11.0.0 no está
  instalado` seguido de las cuatro que sí lo están vale por diez minutos de búsqueda.
- `ln -sfn` — `-s` symlink, `-f` sobrescribe, `-n` trata un enlace a directorio existente
  como archivo y no como directorio. Sin `-n`, reapuntar dos veces crea enlaces anidados.
- **Retirar el enlace de `npx` si no existe** evita el peor de los estados: un
  `/usr/local/bin/npx` apuntando a un archivo de otra versión.
- El script **imprime las tres versiones al final**. Es la verificación incorporada: si
  `select-node` termina bien, ya sabes qué tienes activo.

> 💸 **Deuda técnica intencional.** `select-node` modifica symlinks en `/usr/local/bin/`, y
> eso exige permisos de escritura y afecta a **todos** los procesos del contenedor. Sirve
> para el build, que es donde lo usamos, y se queda corto en runtime — cuando quieras
> ejecutar un comando con Node 14 sin cambiar el estado global del contenedor. **[F08](08-run-el-contenedor-como-proceso.md) paga
> esta deuda** con un despachador inmutable, y `select-node` se retira 🪦 en esa fase.

---

## 8. 🏗️ El Dockerfile de la fase

📄 **`dockerfiles/05-node.Dockerfile`**

```dockerfile
# syntax=docker/dockerfile:1

FROM debian/eol:buster

LABEL org.opencontainers.image.title="legacy-node-toolchain"
LABEL org.opencontainers.image.description="Toolchain de desarrollo para proyectos Node.js legacy"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash \
       binutils \
       build-essential \
       ca-certificates \
       curl \
       file \
       g++ \
       gcc \
       git \
       jq \
       less \
       make \
       pkg-config \
       procps \
       python2 \
       python3 \
       unzip \
       vim \
       wget \
       xz-utils \
       zip \
    && rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-c"]

ENV SHELL=/bin/bash

ARG NODE10_VERSION=10.24.1
ARG NODE12_VERSION=12.22.12
ARG NODE14_VERSION=14.21.3
ARG NODE16_VERSION=16.20.2
ARG DEFAULT_NODE_VERSION=10.24.1

RUN set -euxo pipefail; \
    mkdir -p /opt/node /tmp/node-downloads; \
    for version in \
        "${NODE10_VERSION}" \
        "${NODE12_VERSION}" \
        "${NODE14_VERSION}" \
        "${NODE16_VERSION}"; \
    do \
        [[ -n "${version}" ]] || continue; \
        archive="node-v${version}-linux-x64.tar.xz"; \
        base_url="https://nodejs.org/dist/v${version}"; \
        echo "==> Descargando Node ${version}"; \
        curl -fsSLo "/tmp/node-downloads/${archive}" \
            "${base_url}/${archive}"; \
        curl -fsSLo "/tmp/node-downloads/SHASUMS256-${version}.txt" \
            "${base_url}/SHASUMS256.txt"; \
        cd /tmp/node-downloads; \
        grep " ${archive}$" "SHASUMS256-${version}.txt" \
            | sha256sum -c -; \
        mkdir -p "/opt/node/${version}"; \
        tar -xJf "/tmp/node-downloads/${archive}" \
            -C "/opt/node/${version}" \
            --strip-components=1; \
        "/opt/node/${version}/bin/node" --version; \
        PATH="/opt/node/${version}/bin:${PATH}" \
            "/opt/node/${version}/bin/npm" --version; \
    done; \
    rm -rf /tmp/node-downloads

COPY scripts/select-node /usr/local/bin/select-node

RUN chmod 0755 /usr/local/bin/select-node \
    && select-node "${DEFAULT_NODE_VERSION}"

ENV NODE_VERSION=${DEFAULT_NODE_VERSION}

WORKDIR /workspace

CMD ["/bin/echo", "👋 Hola desde legacy-node-toolchain"]
```

### 8.1 Detalles con intención

**Los cinco `ARG` parametrizan el build sin tocar el archivo.** Puedes construir una imagen
solo con Node 10 y 14 pasando cadenas vacías a los otros dos, y el `[[ -n ... ]] || continue`
los salta. Es la razón de que el bucle compruebe si la versión está vacía.

**`set -euxo pipefail` en el `RUN`.** La `x` imprime cada comando antes de ejecutarlo, lo que
convierte el log del build en una traza legible. El `pipefail` es crítico aquí: sin él, el
`grep | sha256sum -c -` devolvería el código de salida del **último** comando de la tubería, y
un `grep` que no encuentra nada produciría una verificación vacía que pasa como correcta.

**La verificación del checksum ocurre dentro del build.** No es decorativa: si la descarga se
corrompe o el archivo cambia, `sha256sum -c -` devuelve distinto de cero, el `RUN` falla y **la
imagen no se construye**. Es la diferencia entre confiar en la red y comprobarlo. El tratado
sobre hashes, `SHASUMS256.txt` y firmas GPG está en **[a04](a04-checksums-gpg-y-archivos.md)**; aquí queda lo operativo.

**`curl -fsSLo`** merece desglose: `-f` falla ante un HTTP 404 en lugar de guardar la página
de error como si fuera un tarball —el error del ejercicio 18 de [F04](04-toolchain-de-compilacion.md)—; `-s` silencioso; `-S`
pero muestra los errores; `-L` sigue redirecciones; `-o` escribe al archivo.

**Node y npm se ejecutan una vez por versión, dentro del bucle.** Es una prueba de humo
incrustada en el build: si un tarball se extrajo mal, el build muere ahí y no tres fases
después.

**Y ese `PATH=` delante del `npm` no es un adorno.** Es la línea más rara del bloque, así que
vale la pena contar de dónde sale, porque es un fallo real que costó un build:

```text
+ /opt/node/10.24.1/bin/node --version
v10.24.1
+ /opt/node/10.24.1/bin/npm --version
/usr/bin/env: 'node': No such file or directory
ERROR: process "/bin/bash -c set -euxo pipefail; ..." did not complete
successfully: exit code: 127
```

`node` funciona con su ruta absoluta y `npm` no, estando los dos en el mismo directorio. La
causa está en el primer byte de `npm`: **no es un binario, es un script de JavaScript**, y
como todo script lleva un shebang que dice quién debe interpretarlo.

```bash
head -1 /opt/node/10.24.1/bin/npm
```
```text
#!/usr/bin/env node
```

Ahí está. `env` busca `node` **en el `PATH`**, y en este punto del build el `PATH` todavía es
el de Debian: `select-node` no ha corrido, no hay symlinks en `/usr/local/bin`, y ningún
`/opt/node/*/bin` está en la variable. `env` no encuentra `node`, y el `127` —el código de
"comando no encontrado"— se lo lleva el `RUN` entero gracias al `set -e`.

Anteponer `PATH=` a un solo comando es sintaxis de shell para **una asignación que solo vive
durante esa ejecución**: no exporta nada, no afecta a la línea siguiente, y le da a `env` justo
lo que necesita para resolver el shebang.

> 🧠 **El patrón a memorizar, que te va a servir mucho más allá de este `RUN`.** Un
> `command not found` que nombra un programa que **sí existe** casi nunca es el programa que
> creías estar ejecutando: es el intérprete de su shebang. Cuando `X: No such file or
> directory` te señala algo que puedes ver con `ls`, mira el `head -1` del script antes de
> mirar cualquier otra cosa.

**Todo el ciclo va en un solo `RUN`**, incluida la limpieza de `/tmp/node-downloads`. Es el
mismo patrón de [F03](03-apt-y-utilidades.md) §4.2, y aquí pesa más: los cuatro tarballs suman más de 150 MB que se
quedarían horneados en la imagen para siempre si los borrases en una capa posterior.

**`ENV NODE_VERSION` deja constancia de la versión activa** para que cualquiera pueda
consultarla con `docker inspect` o desde dentro, sin adivinar a dónde apuntan los symlinks.

Construir:

```bash
docker build \
  --platform linux/amd64 \
  --file dockerfiles/05-node.Dockerfile \
  --tag legacy-node-toolchain:phase06 \
  .
```

Y una variante con solo dos generaciones, para ver los `ARG` trabajar:

```bash
docker build \
  --platform linux/amd64 \
  --build-arg NODE12_VERSION= \
  --build-arg NODE16_VERSION= \
  --file dockerfiles/05-node.Dockerfile \
  --tag legacy-node-toolchain:solo-10-14 \
  .
```

---

## 9. 🔥 Prueba de fuego

**Las cuatro instalaciones existen y responden:**

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase06 \
  bash -c 'for v in 10.24.1 12.22.12 14.21.3 16.20.2; do
             printf "%-10s node %s  npm %s\n" "$v" \
               "$(/opt/node/$v/bin/node --version)" \
               "$(/opt/node/$v/bin/npm --version)"
           done'
```
```text
10.24.1    node v10.24.1  npm 6.14.12
12.22.12   node v12.22.12  npm 6.14.16
14.21.3    node v14.21.3  npm 6.14.18
16.20.2    node v16.20.2  npm 8.19.4
```

Esa última línea es la advertencia de §4 hecha salida real: **npm 8**.

**La versión activa es la esperada:**

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase06 \
  bash -c 'node --version; npm --version; readlink -f $(command -v node)'
```
```text
v10.24.1
6.14.12
/opt/node/10.24.1/bin/node
```

**Cambiar de versión funciona:**

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase06 \
  bash -c 'select-node 14.21.3 && node --version'
```
```text
Node activo: 14.21.3
v14.21.3
6.14.18
...
v14.21.3
```

**Y fallar también funciona**, que es igual de importante:

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase06 \
  bash -c 'select-node 11.0.0'; echo "exit=$?"
```
```text
ERROR: Node 11.0.0 no está instalado en esta imagen.
Versiones disponibles:
  - 10.24.1
  - 12.22.12
  - 14.21.3
  - 16.20.2
exit=3
```

**Y `node-gyp` por fin existe**, cerrando la promesa de [F05](05-python-y-node-gyp.md):

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase06 \
  bash -c 'npm ls -g --depth=0 2>/dev/null | grep -i gyp; ls /opt/node/10.24.1/lib/node_modules/npm/node_modules/node-gyp/package.json'
```

---

## 10. ⚠️ Errores comunes y diagnóstico

**El build falla en `sha256sum -c -` con `no properly formatted checksum lines found`.** El
`grep` no encontró la línea, casi siempre porque el nombre del archivo no coincide: revisa la
arquitectura del `archive`. Es exactamente el fallo que `pipefail` existe para no ocultar.

**`curl: (22) The requested URL returned error: 404`.** Esa versión no publicó ese artefacto.
Si estás construyendo para ARM64 y pediste `linux-x64`, ese es el motivo. Y si construyes para
`darwin` cualquier cosa, vuelve a [F00](00-problema-y-contrato.md). 😄

**`tar: Error is not recoverable: exiting now`.** Lo que descargaste no es un `.tar.xz`
válido. Pásale `file` encima: nueve de cada diez veces es una página HTML de error de 500
bytes. El `-f` de `curl` está justamente para evitarlo.

**`node: command not found` después de construir.** El `select-node` del build no se ejecutó
o falló. Comprueba con `ls -la /usr/local/bin/node` si el symlink existe y a dónde apunta.

**`select-node` funciona pero `docker exec` sigue viendo la versión anterior.** No es un bug:
`select-node` cambió los symlinks **en ese contenedor**, y un `docker exec` nuevo sí debería
verlo. Si no lo ve, probablemente estás en un contenedor distinto. Esta familia de confusiones
es la que motiva el despachador de **[F08](08-run-el-contenedor-como-proceso.md)**.

**El build tarda muchísimo.** Son cuatro tarballs de unos 40 MB cada uno. La primera vez se
paga; después la caché de Docker se encarga, mientras no cambies los `ARG`. **[F12](12-capas-cache-y-contexto.md)** explica
por qué cambiar un `ARG` invalida esa capa.

---

## 11. 📋 Checklist de validación

```text
[ ] dockerfiles/05-node.Dockerfile y scripts/select-node existen
[ ] El build produce legacy-node-toolchain:phase06 sin error
[ ] En el log del build se ven las cuatro verificaciones sha256sum con "OK"
[ ] /opt/node contiene exactamente cuatro directorios
[ ] Las cuatro parejas node+npm responden con su versión esperada
[ ] node --version por defecto responde v10.24.1
[ ] npm --version por defecto responde 6.14.12
[ ] readlink -f $(command -v node) apunta a /opt/node/10.24.1/bin/node
[ ] select-node 14.21.3 cambia la versión activa
[ ] select-node 11.0.0 falla con exit 3 y lista las versiones disponibles
[ ] /tmp/node-downloads NO existe en la imagen final
[ ] node-gyp está disponible dentro de npm
```

---

## 12. 🧪 Ejercicios de la Fase 06 (25)

## 🟢 Fácil — las cuatro generaciones (1–8)

### 🟢 Ejercicio 1 — Construye y pasa la prueba de fuego

Construye `phase06` y ejecuta las cinco comprobaciones de §9.

**Objetivo:** tener las cuatro generaciones instaladas y haber visto el fallo controlado de
`select-node` con una versión inexistente.

### 🟢 Ejercicio 2 — Lee el nombre de un artefacto

Abre https://nodejs.org/dist/v14.21.3/ y localiza cinco artefactos distintos.

**Pregunta:** ¿cuántas combinaciones de sistema y arquitectura publicó esa versión, y cuál
usaría nuestro Dockerfile si construyéramos para `linux/arm64`?

### 🟢 Ejercicio 3 — Sin `--strip-components`

Extrae un tarball de Node a mano dentro del contenedor, una vez con la opción y otra sin
ella, y compara las rutas resultantes.

**Objetivo:** ver con tus ojos la ruta ridícula de §5.2.

### 🟢 Ejercicio 4 — Sigue el symlink

Ejecuta `ls -la /usr/local/bin/node` y después `readlink -f $(command -v node)`.

**Pregunta:** ¿qué diferencia hay entre lo que muestran los dos comandos, y por qué el
segundo es el que de verdad responde "qué se ejecuta"?

### 🟢 Ejercicio 5 — Las cuatro npm

Ejecuta la primera comprobación de §9 y anota las cuatro versiones de npm.

**Pregunta:** ¿cuál rompe la simetría y qué consecuencia tiene sobre un `package-lock.json`
de 2019?

### 🟢 Ejercicio 6 — Cambia de versión y vuelve

Dentro de un contenedor interactivo, activa Node 16, comprueba, y vuelve a Node 10.

**Objetivo:** interiorizar que instalar y activar son operaciones distintas.

### 🟢 Ejercicio 7 — El primer programa

Escribe un `hola.js` en tu host, móntalo y ejecútalo con cada una de las cuatro versiones.

**Pregunta:** si usas sintaxis moderna —`??` o `?.`— ¿en cuáles funciona? Ahí tienes el
primer mapa práctico de qué te permite cada generación.

### 🟢 Ejercicio 8 — Pesa cada generación

Las cuatro ramas de Node no ocupan lo mismo, y conviene saber cuánto cuesta cada una antes
de discutir si sobran:

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase06 \
  bash -c 'du -sh /opt/node/*; echo "---"; du -sh /opt/node'
```

**Pregunta:** ¿cuánto ocupa cada generación y cuánto las cuatro juntas? Compara ese total con
la diferencia de tamaño entre `phase05` y `phase06` en `docker image ls`. ¿Cuadran los
números? Si no cuadran del todo, ¿en qué dirección falla y por qué?

## 🟡 Intermedio — instalar y verificar (9–15)

### 🟡 Ejercicio 9 — Construye una imagen con dos versiones

Ejecuta el build con `--build-arg` vaciando dos versiones, y comprueba el contenido de
`/opt/node`.

**Pregunta:** ¿cuánto más pequeña quedó la imagen? ¿Qué línea del bucle hace posible saltar
una versión vacía?

### 🟡 Ejercicio 10 — Cambia el default

Construye con `--build-arg DEFAULT_NODE_VERSION=16.20.2` y comprueba `node --version` sin
ejecutar `select-node`.

**Objetivo:** ver que el default es una decisión de build, y relacionarlo con la distinción
build time / runtime de [F02](02-dockerfile-esencial.md) §6.

### 🟡 Ejercicio 11 — Verifica un checksum a mano

Descarga un tarball y su `SHASUMS256.txt` dentro del contenedor y repite la verificación
paso a paso, sin la tubería del Dockerfile.

**Objetivo:** entender qué hace exactamente `sha256sum -c -` y qué formato espera en su
entrada.

### 🟡 Ejercicio 12 — Rompe el checksum a propósito

Descarga un tarball, modifícale un byte con `printf 'x' | dd of=archivo bs=1 seek=100 conv=notrunc`,
y vuelve a verificar.

**Objetivo:** ver el `FAILED` y comprobar que el código de salida no es cero. Es la
demostración de que la verificación del build no es decorativa.

### 🟡 Ejercicio 13 — Las cabeceras de cada versión

Compara `ls /opt/node/10.24.1/include/node/` con la misma ruta de `16.20.2`, y busca
`NODE_MODULE_VERSION` en `node_version.h` de cada una.

**Objetivo:** encontrar el número que explica por qué los addons no son intercambiables. En
[F14](14-abi-libc-y-prebuilds.md) lo vas a usar de verdad.

### 🟡 Ejercicio 14 — `npx` no está en todas partes

Comprueba si `npx` existe en las cuatro versiones instaladas.

**Pregunta:** ¿por qué el script de `select-node` retira el enlace en lugar de dejarlo
apuntando a la versión anterior? Describe el fallo que eso evitaría.

### 🟡 Ejercicio 15 — Lee `select-node` y provócale el error

El script tiene una rama de fallo escrita a propósito. Léela primero en
`scripts/select-node`, después ejecútala:

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase06 \
  select-node 9.9.9
echo "código de salida: $?"
```

**Pregunta:** ¿qué imprime, por qué canal sale —pruébalo con `2>/dev/null`— y qué código de
salida devuelve? Ahora la parte de diseño: el script podría haber devuelto `1` como todo el
mundo. **¿Qué gana usando un código concreto**, y dónde se nota esa decisión cuando el que
llama al script es un `Makefile` o un job de CI en vez de un humano?

## 🟠 Difícil — cuando la versión activa no es la que crees (16–21)

### 🟠 Ejercicio 16 — Predice qué pasa sin `pipefail`

Modifica el `RUN` quitando `pipefail` y cambiando el `grep` para que no encuentre nada
—por ejemplo, buscando un nombre de archivo equivocado—. **Predice si el build fallará o no**
antes de ejecutarlo.

**Pregunta:** ¿qué código de salida devuelve una tubería sin `pipefail`, y por qué eso
convierte una verificación de seguridad en teatro?

### 🟠 Ejercicio 17 — El tarball que era una página de error

Modifica el `RUN` para descargar una versión inexistente **quitando el `-f` de `curl`**, y
observa dónde falla el build.

**Pregunta:** ¿en qué paso muere, y qué mensaje da? Compara con lo que pasaría **con** `-f`.
¿Cuál de los dos errores prefieres a las tres de la mañana?

### 🟠 Ejercicio 18 — Symlinks anidados

Ejecuta `ln -sf` (sin `-n`) dos veces seguidas apuntando a versiones distintas, y después
`readlink -f`.

**Objetivo:** provocar el enlace anidado que la bandera `-n` evita, y entender por qué el
script la lleva.

### 🟠 Ejercicio 19 — La caché que no invalida

Construye `phase06`, después cambia solo `DEFAULT_NODE_VERSION` y reconstruye. Anota qué
pasos dicen `CACHED`.

**Pregunta:** ¿se volvieron a descargar los tarballs? ¿Por qué sí o por qué no? Formula la
regla con tus palabras y guárdala para [F12](12-capas-cache-y-contexto.md).

### 🟠 Ejercicio 20 — Las cuatro V8 y las cuatro OpenSSL

`node --version` es la punta del iceberg. Cada generación trae su propio V8, su propio
OpenSSL y su propio ABI de addons:

```bash
for v in 10.24.1 12.22.12 14.21.3 16.20.2; do
  printf '%-10s ' "$v"
  docker run --rm --platform linux/amd64 -e NODE_VERSION="$v" \
    legacy-node-toolchain:phase06 \
    node -p 'JSON.stringify({v8:process.versions.v8, ssl:process.versions.openssl, abi:process.versions.modules})'
done
```

**Antes de ejecutarlo, predice** cuál de los tres números crees que más problemas te va a dar
al cambiar de generación en un proyecto real.

**Pregunta:** de los tres, ¿cuál rompe un `node_modules` ya instalado, cuál rompe una conexión
TLS contra un servidor viejo y cuál solo cambia qué sintaxis de JavaScript puedes escribir?
Guarda la tabla: **[F14](14-abi-libc-y-prebuilds.md)** la convierte en la explicación completa.

### 🟠 Ejercicio 21 — El `PATH` contra el symlink: quién gana

Los shims de `/usr/local/bin` no son la única forma de que un `node` esté disponible, y
cuando hay dos mecanismos a la vez conviene saber cuál manda. Con el symlink apuntando a
10.24.1, mete otra generación en el `PATH` por delante:

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase06 bash -c '
  echo "symlink apunta a: $(readlink -f $(command -v node))"
  export PATH="/opt/node/16.20.2/bin:$PATH"
  echo "ahora node es:     $(command -v node)"
  node --version
  hash -r
  node --version'
```

**Predice las tres salidas de `node --version` antes de ejecutarlo.**

**Pregunta:** ¿qué mecanismo ganó y por qué? ¿Para qué sirvió el `hash -r` — y qué te dice su
existencia sobre por qué a veces cambias algo en el `PATH` y el shell "no se entera"? Es un
clásico que vas a volver a sufrir fuera de este curso.

## 🔴 Muy difícil — arqueología y criterio (22–25)

### 🔴 Ejercicio 22 — Arqueología: qué Node necesita tu proyecto

Toma tu proyecto legacy real. Sin ejecutar `npm ci`, decide qué generación de Node le
corresponde usando tres fuentes: el campo `engines`, la versión del framework principal, y la
fecha del `package-lock.json`.

**Objetivo:** producir una decisión razonada con su evidencia. En **[F11](11-validar-tu-proyecto.md)** vas a comprobar si
acertaste, y en **[F20](20-validacion-sistematica-y-evidencia.md)** esto se convierte en un método formal.

### 🔴 Ejercicio 23 — Reproduce el fallo de la máquina del tiempo

`nodejs.org/dist` sigue en pie hoy. Diseña —y documenta— qué le pasaría a este Dockerfile si
mañana desapareciera, y propón **dos** estrategias de mitigación con su coste: una que
funcione para tu equipo y otra que funcione para una máquina sin Internet.

**Objetivo:** llegar por tu cuenta a las ideas que **[F28](28-publicar-la-imagen.md)** y **[a13](a13-air-gapped.md)** desarrollan. La
reproducibilidad depende de fuentes que no controlas, y eso hay que decidirlo antes de que
duela.

### 🔴 Ejercicio 24 — Defiende los tarballs contra `FROM node:10`

Un revisor propone: *"esto son sesenta líneas de Dockerfile para hacer lo que hace un
`FROM node:10`. Simplifica."*

**Objetivo:** escribir una respuesta que reconozca lo que su propuesta gana de verdad —es más
corta, la mantiene otro, y para un proyecto único sería la elección correcta— y después
demuestre con **tres hechos concretos** por qué no sirve aquí. Uno de los tres tiene que
mencionar qué Debian trae `node:10` y qué consecuencia tiene sobre lo decidido en [F01](01-decisiones-debian-zonas-node.md).

### 🔴 Ejercicio 25 — El proyecto que no dice qué Node quiere

Te dan un repositorio de 2018 sin `engines` en el `package.json`, sin `.nvmrc`, sin
`Dockerfile` y sin configuración de CI. Nadie del equipo original sigue en la empresa. Tienes
que decidir con cuál de las cuatro generaciones se trabaja, **sin ejecutar `npm ci`** — porque
todavía no sabes cuál elegir y cada intento te contamina el `node_modules`.

**Objetivo:** llegar a una generación concreta y defenderla con al menos **cuatro pruebas
independientes**, cada una con el comando que la produce. Tienes de dónde sacarlas: el
`lockfileVersion` del `package-lock.json`, las fechas de publicación de dos o tres
dependencias clave —`npm view <paquete> time`, que funciona sin instalar nada—, la sintaxis
de JavaScript que usa el código fuente, y lo que las propias dependencias declaran en sus
`engines`.

**Pregunta de cierre:** si las cuatro pruebas no apuntan a la misma generación —que es lo
normal—, ¿cuál pesa más y por qué? Escribe la regla de desempate que usarías, y di qué harías
distinto si el proyecto tuviera dependencias nativas.

## 🔥 Opcionales

### 🔥 Ejercicio 26 — Añade una quinta generación

Extiende el Dockerfile con Node 8.17.0 y comprueba si funciona sobre Debian 10.

**Pregunta:** ¿instala? ¿ejecuta? ¿Qué te dice eso sobre hasta dónde llega el rango de este
laboratorio, y qué habría que cambiar para bajar más?

### 🔥 Ejercicio 27 — Verificación GPG completa

Implementa la verificación de firma de `SHASUMS256.txt.asc` usando las claves de release de
Node, y añádela al `RUN`.

**Objetivo:** cerrar por tu cuenta el nivel de confianza que **[a04](a04-checksums-gpg-y-archivos.md)** describe. Documenta qué
tuviste que instalar y cuánto creció la imagen.

## 💀 Boss fight

### 💀 Ejercicio 28 — Boss fight: cuatro Node, un solo contenedor, cero sorpresas

Te piden demostrar que la imagen cumple lo que promete: cuatro generaciones instaladas, una
activa, y ninguna interferencia entre ellas.

**Objetivo:** producir una matriz de evidencia de 4×4 y un veredicto. Para **cada** una de las
cuatro versiones —10.24.1, 12.22.12, 14.21.3 y 16.20.2— tienes que registrar: la salida de
`node --version` y `npm --version` tras activarla con `select-node`, la ruta real que devuelve
`readlink -f $(which node)`, el `NODE_MODULE_VERSION` que reporta
`node -p "process.versions.modules"`, y el resultado de instalar el fixture `00-node-smoke`
con esa versión. Después: (1) demuestra con `ls /opt/node/` que las cuatro conviven y que
activar una **no borra** las otras —es la distinción de §7—; (2) rompe la verificación a
propósito, alterando un byte del `SHASUMS256.txt` de §5 antes del `sha256sum -c`, y captura
el fallo de build; (3) explica por qué el orden de las capas de §8 hace que cambiar
`DEFAULT_NODE_VERSION` **no** obligue a volver a descargar 400 MB de tarballs.

**Pregunta:** si mañana nodejs.org retira los tarballs de la rama 10, ¿qué parte de tu imagen
deja de ser reconstruible y qué parte no? Di exactamente qué harías hoy para que eso no te
alcance.

---

## 13. 📚 Referencias

**Node.js**
- Índice de releases y artefactos: https://nodejs.org/dist/
- Verificación de binarios: https://github.com/nodejs/node/blob/main/README.md#verifying-binaries
- Claves de release: https://github.com/nodejs/release-keys
- Calendario de releases y EOL: https://github.com/nodejs/Release

**Herramientas**
- `tar(1)` en Buster: https://manpages.debian.org/buster/tar/tar.1.en.html
- `curl(1)`: https://curl.se/docs/manpage.html
- Utilidades SHA-2 de GNU Coreutils: https://www.gnu.org/software/coreutils/manual/html_node/sha2-utilities.html

**npm 6**
- Documentación: https://docs.npmjs.com

> ⚠️ **Dos advertencias.** `nodejs.org/api` documenta versiones muy posteriores a las
> nuestras: para saber qué API existía en Node 10, usa el selector de versión de esa misma
> página. Y `docs.npmjs.com` describe npm actual, no npm 6 — las diferencias en
> `package-lock` y peer dependencies son reales y las vas a sufrir en [F11](11-validar-tu-proyecto.md).

**Orden de lectura sugerido:** el índice de `nodejs.org/dist` mientras haces el ejercicio 2, y
la sección de verificación de binarios antes del ejercicio 26.

---

## 14. 🏁 Resultado de la fase

```text
IMAGEN        legacy-node-toolchain:phase06
BASE          debian/eol:buster · Debian 10 · linux/amd64

CONTIENE      utilidades (F03) · toolchain C/C++ (F04) · python2 y python3 (F05)
              /opt/node/10.24.1  → node v10.24.1  npm 6.14.12
              /opt/node/12.22.12 → node v12.22.12 npm 6.14.16
              /opt/node/14.21.3  → node v14.21.3  npm 6.14.18
              /opt/node/16.20.2  → node v16.20.2  npm 8.19.4
              /usr/local/bin/{node,npm,npx} → symlinks a la versión activa
              /usr/local/bin/select-node
              ENV NODE_VERSION=10.24.1

DEUDA 💸      select-node cambia estado global del contenedor.
              Se paga en F08 con un despachador inmutable.

EL TOOLCHAIN ESTÁ COMPLETO. Lo que queda es aprender a construirlo
y a ejecutarlo bien.
```

> **La señal de que quedó bien:** *"puedo pedirle a esta imagen cualquiera de las cuatro
> generaciones de Node, y si le pido una que no tiene, me lo dice claramente en lugar de
> fallar de forma rara tres comandos después."*

En **[F07](07-build-de-la-imagen.md)** dejamos de añadir cosas al Dockerfile y aprendemos a **construirlo**: el build
context, el `.dockerignore`, y el nacimiento del `Dockerfile` canónico del laboratorio.
