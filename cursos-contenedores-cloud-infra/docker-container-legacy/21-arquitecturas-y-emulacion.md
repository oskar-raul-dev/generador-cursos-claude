# 🧠 Parte II · Fase 21 — Arquitecturas, OCI multi-platform y emulación

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · `linux/amd64` baseline, `linux/arm64` adicional
> **Dockerfile pedagógico de esta fase:** `dockerfiles/08-multiarch.Dockerfile`
> **Requisitos:** **[F12](12-capas-cache-y-contexto.md)** (build), **[F14](14-abi-libc-y-prebuilds.md)** (ABI y binarios)
> **Fecha de revisión de documentación externa:** 6 de septiembre de 2026 — Buildx y QEMU sobre Docker 29.6.2
> **Fecha de verificación ejecutada:** 6 de septiembre de 2026 — el fallo de §7.1 y las mediciones de §7.4 están corridos sobre Docker 29.6.2 con Rosetta, en un MacBook con Apple Silicon
> **Estado de la imagen al terminar:** aprendes a construirla para dos arquitecturas
> **Código de esta fase:** [`src/21-arquitecturas-y-emulacion/`](src/21-arquitecturas-y-emulacion/)
> **Objetivo:** entender qué es una arquitectura de CPU sin diseñar silicio, cómo un tag contiene varias imágenes, y cómo tu Mac ARM ejecuta un binario x86 sin que se lo pidas

---

## 1. 🧭 Dónde estamos

Llevas veinte fases escribiendo `--platform linux/amd64` sin que nadie explicara del todo por
qué. [F00](00-problema-y-contrato.md) te dijo que Node no publicó `darwin-arm64` antes de la 16. [F01](01-decisiones-debian-zonas-node.md) fijó amd64 como
baseline. [F14](14-abi-libc-y-prebuilds.md) te enseñó que un binario pertenece a su arquitectura.

Esta fase junta las tres y añade lo que falta: **qué pasa exactamente cuando pides amd64 en una
máquina ARM**. Porque funciona, y "funciona" no es una explicación.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder:

- Explicar qué es una **ISA** y por qué `x86_64`, `amd64` y `x64` son lo mismo con tres
  nombres.
- Triangular la arquitectura de tu sistema con tres comandos y saber cuál responde qué.
- Entender qué es un **image index** de OCI: un tag que contiene varias imágenes.
- Distinguir **build platform** de **target platform**, y usar las variables de BuildKit.
- Construir una imagen para dos arquitecturas con Buildx.
- Explicar qué hace **QEMU en modo usuario** con `binfmt_misc`, y en qué se diferencia de
  emular una máquina entera.

---

## 3. 🚧 Qué NO entra todavía

- **Apple Silicon en la práctica**, Docker Desktop, Podman Desktop y las cinco rutas reales →
  **[F22](22-apple-silicon-y-hosts.md)**.
- **Los estudios de caso** —`node-sass` y `canvas` en ARM64— y los microbenchmarks →
  **[F23](23-estudios-de-caso-multiplataforma.md)**.
- **Colima y Lima** → **[a07](a07-colima-y-lima.md)**. **Windows y WSL2** → **[a08](a08-windows-y-powershell.md)**.
- **Publicar** una imagen multi-plataforma en un registry → **[F28](28-publicar-la-imagen.md)**.

---

## 4. 🧩 ISA, y los nombres que la confunden

Una **ISA** —*Instruction Set Architecture*— es el conjunto de instrucciones que una CPU
entiende. Es el contrato entre el binario y el silicio: un ejecutable contiene instrucciones de
una ISA concreta, y una CPU solo ejecuta las suyas.

**Las dos familias que te importan**, y sus alias, que son la causa de media confusión:

| Familia | Se llama también | Quién la usa |
|---|---|---|
| **x86-64** | `amd64`, `x64`, `x86_64`, `Intel 64` | PCs, servidores, Macs hasta 2020 |
| **ARM64** | `aarch64`, `arm64`, `AArch64` | Apple Silicon, Raspberry Pi 4+, AWS Graviton |

**Son el mismo hardware con distinto nombre según quién hable:**

```text
uname -m        →  x86_64        el kernel de Linux
Docker          →  amd64         la especificación OCI
Node            →  x64           process.arch
Debian          →  amd64         los paquetes .deb
```

```text
uname -m        →  aarch64
Docker          →  arm64
Node            →  arm64
Debian          →  arm64
```

> 🧭 **Y `linux/amd64` se lee en dos partes:** `linux` es el **sistema operativo** —el tipo de
> kernel y de binario— y `amd64` es la **arquitectura**. Las dos hacen falta: un binario de
> Linux ARM64 no corre en macOS ARM64 aunque la CPU sea la misma. Es exactamente lo que [F00](00-problema-y-contrato.md)
> §3.1 aprovechaba.

### 4.1 Triangula: tres comandos, tres preguntas

Cuando algo huele a problema de arquitectura, estos tres lo sitúan:

```bash
# 1. ¿qué CPU tiene la máquina donde corre esto?
uname -m

# 2. ¿para qué arquitectura se construyó esta imagen?
docker image inspect legacy-node-toolchain:phase15 --format '{{.Architecture}}'

# 3. ¿para qué arquitectura es este binario concreto?
file /opt/node/10.24.1/bin/node
```

**Y la comprobación que lo junta todo**, desde dentro del contenedor:

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase15 \
  bash -c 'echo "kernel : $(uname -m)"
           echo "node   : $(node -p process.arch)"
           echo "dpkg   : $(dpkg --print-architecture)"
           echo "libc   : $(ldd --version | head -1)"'
```
```text
kernel : x86_64
node   : x64
dpkg   : amd64
libc   : ldd (Debian GLIBC 2.28-10+deb10u4) 2.28
```

> 🩺 **Guárdate ese bloque.** Es el `runtime.txt` del expediente de [F20](20-validacion-sistematica-y-evidencia.md) §6.5, y es lo primero
> que vas a querer comparar cuando algo funcione en una máquina y no en otra.

### 4.2 Node no es el primer sospechoso

Un matiz importante antes de seguir: **Node publica binarios para `linux-arm64` desde la
generación 10**. En cuanto a runtime, ARM64 no es un problema.

Los problemas vienen de **los amigos de Node**: los prebuilds de las dependencias nativas, que
en 2018 se publicaban mayoritariamente para `linux-x64`; los navegadores que descargan
Puppeteer y Cypress; y las herramientas antiguas que nunca publicaron ARM64.

> 🧭 **La regla que ordena esta parte del curso:** el runtime no decide la arquitectura, la
> deciden **las dependencias**. Por eso el baseline es amd64 aunque Node exista para las dos.

---

## 5. 🗂️ Un tag, varias imágenes: el image index

Cuando ejecutas `docker pull debian/eol:buster` en un Mac ARM y en un PC Intel, obtienes
**imágenes distintas** con el mismo nombre. No es magia: es una indirección del formato OCI.

```mermaid
flowchart TD
    T["tag: debian/eol:buster"] --> I["IMAGE INDEX<br/>(a veces llamado «manifest list»)"]
    I --> A["linux/amd64 → manifest → config + capas amd64"]
    I --> R["linux/arm64 → manifest → config + capas arm64"]
    I --> X["linux/386 → …"]
    I --> S["linux/s390x → …"]
```

El cliente mira su propia plataforma, elige la entrada correspondiente y descarga **solo esa**.

Míralo tú mismo:

```bash
docker manifest inspect debian/eol:buster | jq '.manifests[] | .platform'
```
```text
{ "architecture": "amd64", "os": "linux" }
{ "architecture": "arm64", "os": "linux" }
{ "architecture": "386",   "os": "linux" }
{ "architecture": "arm",   "os": "linux", "variant": "v7" }
...
```

> ⚠️ **Multi-platform NO significa "una imagen que funciona en todas partes".** Significa **un
> nombre que apunta a varias imágenes, cada una de una plataforma**. Cada una lleva binarios
> distintos y ocupa su propio espacio. La confusión es frecuente y lleva a esperar cosas que no
> pasan.

Y una distinción que confunde a mucha gente:

```bash
docker manifest inspect ...    # pregunta al REGISTRY: ¿qué plataformas hay?
docker image inspect ...       # pregunta a TU MÁQUINA: ¿qué descargué?
```

El segundo siempre te dará **una** arquitectura, porque solo tienes una descargada.

---

## 6. 🧭 Build platform contra target platform

Al construir hay **dos** plataformas en juego, y confundirlas produce Dockerfiles que solo
funcionan en la máquina de quien los escribió.

```text
BUILD PLATFORM              TARGET PLATFORM
la máquina que construye    la máquina donde correrá la imagen
tu Mac ARM64                linux/amd64
```

BuildKit expone las dos como variables automáticas, que puedes usar declarando el `ARG` sin
valor:

| Variable | Qué contiene |
|---|---|
| `TARGETPLATFORM` | `linux/amd64` — la plataforma destino completa |
| `TARGETARCH` | `amd64` — solo la arquitectura |
| `TARGETOS` | `linux` |
| `BUILDPLATFORM` | la plataforma de la máquina que construye |

```dockerfile
FROM debian/eol:buster
ARG TARGETARCH
RUN echo "construyendo para $TARGETARCH" > /etc/target-arch
```

### 6.1 El Dockerfile multiarch

Nuestro `RUN` de Node descarga `node-v${version}-linux-x64.tar.xz`, con `x64` escrito a mano.
Eso funciona en amd64 y falla en arm64. La corrección:

📄 **`dockerfiles/08-multiarch.Dockerfile`** — el fragmento que cambia

```dockerfile
ARG TARGETARCH

RUN set -euxo pipefail; \
    # Node llama a las arquitecturas distinto que Docker: amd64→x64, arm64→arm64
    case "${TARGETARCH}" in \
      amd64) node_arch='x64'   ;; \
      arm64) node_arch='arm64' ;; \
      *) echo "Arquitectura no soportada por este laboratorio: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    mkdir -p /opt/node /tmp/node-downloads; \
    for version in "${NODE10_VERSION}" "${NODE12_VERSION}" \
                   "${NODE14_VERSION}" "${NODE16_VERSION}"; do \
        [[ -n "${version}" ]] || continue; \
        archive="node-v${version}-linux-${node_arch}.tar.xz"; \
        base_url="https://nodejs.org/dist/v${version}"; \
        curl -fsSLo "/tmp/node-downloads/${archive}" "${base_url}/${archive}"; \
        curl -fsSLo "/tmp/node-downloads/SHASUMS256-${version}.txt" "${base_url}/SHASUMS256.txt"; \
        cd /tmp/node-downloads; \
        grep " ${archive}$" "SHASUMS256-${version}.txt" | sha256sum -c -; \
        mkdir -p "/opt/node/${version}"; \
        tar -xJf "/tmp/node-downloads/${archive}" -C "/opt/node/${version}" --strip-components=1; \
        "/opt/node/${version}/bin/node" --version; \
    done; \
    rm -rf /tmp/node-downloads
```

**Detalles con intención:**

- **El `case` traduce el vocabulario.** Docker dice `amd64`, Node dice `x64`. Es la clase de
  detalle que rompe un build multiarch y que no aparece en ningún error claro.
- **Falla explícitamente ante una arquitectura no soportada**, en lugar de intentar descargar
  un archivo que no existe y dar un 404 confuso.
- **La verificación de checksum sigue ahí**, y ahora comprueba el artefacto de la arquitectura
  correcta.

### 6.2 Construir las dos

```bash
# un constructor capaz de multi-plataforma
docker buildx create --name multiarch --use
docker buildx inspect --bootstrap

# las dos a la vez
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --file dockerfiles/08-multiarch.Dockerfile \
  --tag legacy-node-toolchain:phase21 \
  .
```

> ⚠️ **Un build multi-plataforma no se puede cargar en tu almacén local con `--load`**, porque
> tu almacén guarda una imagen por tag y aquí hay dos. Las opciones son `--push` a un registry
> —que es de **[F28](28-publicar-la-imagen.md)**—, o construir de una en una con `--load` para probar.

```bash
# de una en una, para probar en local
docker buildx build --platform linux/arm64 --load -t legacy-node-toolchain:arm64 .
```

---

## 7. 🌀 QEMU y `binfmt_misc`: la traducción, por dentro

Aquí está la pregunta central de la fase: **¿cómo ejecuta tu Mac ARM un contenedor amd64?**

### 7.1 Qué pasaría sin traducción

```text
CPU     → ARM64
kernel  → ARM64
binario → x86-64
```

El sistema no puede "hacer lo que pueda": el archivo contiene instrucciones que la CPU no
entiende. El resultado es el error que ya has visto:

```text
exec format error
```

> ⚠️ **Ese error solo aparece si no hay traducción registrada, y en tu máquina probablemente
> sí la hay.** Es una de esas trampas que hacen perder una tarde, así que vale la pena verla.
> Sacamos un `/bin/ls` de la imagen amd64 del laboratorio y lo ejecutamos dentro de un
> contenedor **arm64**:
>
> ```bash
> docker run --rm --platform linux/arm64 -v "$PWD:/m" debian:bookworm-slim /m/ls-amd64 --version
> ```
> ```text
> rosetta error: failed to open elf at /lib64/ld-linux-x86-64.so.2
> ```
>
> No dice `exec format error`. Dice otra cosa, y la diferencia es informativa: el kernel **sí**
> reconoció el binario x86-64 y **sí** llamó al traductor —el `binfmt_misc` de §7.3 está
> registrado para toda la VM, no por contenedor—, pero el traductor se estrelló porque el
> rootfs arm64 en el que lo metimos no tiene el enlazador dinámico de x86-64. **El intérprete
> se resolvió; las bibliotecas, no.** `exec format error` a secas es lo que verás en una
> máquina sin emulación instalada, y `rosetta error` o un fallo de `qemu-x86_64` es lo que
> verás en la tuya. Los tres significan lo mismo de fondo: metiste un binario en el sitio
> equivocado.

### 7.2 Dos QEMU distintos, y la confusión que causan

La palabra "QEMU" esconde dos escenarios muy diferentes, y confundirlos lleva a conclusiones
equivocadas sobre el rendimiento.

**A · Emulación de máquina completa** — lo que hace una VM:

```mermaid
flowchart TD
    H["host ARM64"] --> Q["QEMU emula una máquina x86-64 entera"]
    Q --> K["kernel Linux x86-64"] --> U["todo el userspace x86-64"]
```

Emula CPU, memoria, dispositivos y arranca **otro kernel**. Es potente y **lento**.

**B · QEMU en modo usuario** — lo que hacen los contenedores:

```mermaid
flowchart TD
    K["kernel Linux ARM64<br/>uno solo, el nativo"] --> A["programa ARM64"] --> CPU1["CPU directa, velocidad nativa"]
    K --> X["programa x86-64"] --> Q["qemu-x86_64<br/>traduce instrucciones al vuelo"] --> CPU2["CPU ARM64"]
```

**No hay segundo kernel.** El kernel es ARM64 y las llamadas al sistema se traducen; solo se
emulan las instrucciones de CPU del proceso. Es mucho más rápido que el caso A, y sigue siendo
más lento que nativo.

### 7.3 `binfmt_misc`: quién decide llamar a QEMU

Falta la pieza que lo conecta: cuando el kernel intenta ejecutar un binario que no reconoce,
¿cómo sabe que tiene que llamar a QEMU?

**`binfmt_misc`** es un mecanismo del kernel de Linux que permite registrar manejadores para
formatos de binario, identificados por sus primeros bytes —el *magic number*—.

```mermaid
flowchart TD
    A["el kernel intenta ejecutar un ELF x86-64"] --> B["mira su tabla de binfmt_misc"]
    B --> C["«este formato lo maneja /usr/bin/qemu-x86_64»"] --> D["lanza QEMU con el binario como argumento"]
```

Puedes verlo, en Linux:

```bash
ls /proc/sys/fs/binfmt_misc/
cat /proc/sys/fs/binfmt_misc/qemu-x86_64 2>/dev/null | head -3
```

Y registrarlo, si no está:

```bash
docker run --privileged --rm tonistiigi/binfmt --install all
```

> 🧠 **El modelo mental completo, en una imagen:**
>
> ```text
> tu Mac ARM64
>     │
>     ├── VM Linux del motor (kernel ARM64)      ← virtualización, rápida
>     │       │
>     │       ├── contenedor arm64 → nativo
>     │       │
>     │       └── contenedor amd64
>     │               └── binfmt_misc → qemu-x86_64 → traducción por instrucción
> ```
>
> Hay **dos** capas: la VM que da un kernel Linux, y QEMU que traduce arquitectura. La primera
> es barata; la segunda es la que se nota.

> 📝 **Y Rosetta 2 entra en escena.** Docker Desktop en Apple Silicon puede usar **Rosetta**
> en lugar de QEMU para la traducción x86-64, y es notablemente más rápido. Es una opción de la
> configuración, y **[F23](23-estudios-de-caso-multiplataforma.md)** la mide en vez de estimarla.

### 7.4 Cuánto cuesta la traducción, medido

"Más lento que nativo" no es un dato: es una excusa para no medir. Aquí está el número, y tiene
una sorpresa dentro.

El experimento controla lo que hay que controlar: **la misma versión de Node** (16.20.2), **el
mismo script**, **el mismo host** y **la misma imagen oficial**, cambiando solo `--platform`.
Primero, una carga puramente de CPU —treinta millones de raíces cuadradas, sin tocar disco ni
red—:

```javascript
let acc = 0;
const t0 = Date.now();
for (let i = 0; i < 30000000; i++) { acc += Math.sqrt(i) % 7; }
console.log(process.arch, Math.round(acc), (Date.now() - t0) + ' ms');
```

```text
amd64 emulado    x64     6560 ms
                 x64     6541 ms
arm64 nativo     arm64    377 ms
                 arm64    331 ms
```

**Dieciocho veces más lento.** Y no es culpa de nuestra imagen: el laboratorio, con su Node
16.20.2 instalado a mano sobre Buster, da 6.484–6.537 ms, indistinguible de la imagen oficial.

Ahora la sorpresa. El mismo experimento con una carga dominada por **I/O** —escribir y releer
dos mil archivos de 4 KB—:

```text
amd64 emulado    x64      113 ms
                 x64      107 ms
arm64 nativo     arm64     77 ms
                 arm64     73 ms
```

**Vez y media**, no dieciocho.

> 🧠 **El modelo mental que explica las dos cifras.** La emulación traduce **instrucciones de
> CPU**, no llamadas al sistema: un `write()` lo atiende el kernel ARM64 nativo a velocidad
> nativa, cruce de frontera aparte. Por eso el bucle de `Math.sqrt` paga la factura entera y el
> bucle de archivos casi no la nota. Trasladado a lo que tú vas a hacer en este laboratorio:
> **`npm ci` —que es sobre todo red y disco— se porta razonablemente bien emulado, y un
> `webpack` o un `tsc` sobre un proyecto grande —que es CPU pura— es donde vas a sufrir.** Si
> tienes que elegir dónde invertir esfuerzo en evitar la emulación, ya sabes dónde.

> ⚠️ **No extrapoles estos números a tu máquina.** Están medidos sobre Docker Desktop con
> Rosetta en Apple Silicon; con QEMU en vez de Rosetta la penalización de CPU es bastante peor,
> y en un host amd64 no hay penalización porque no hay traducción. El método —misma versión,
> mismo script, cambiar solo `--platform`, tres repeticiones— sí es trasladable, y es lo que
> **[F23](23-estudios-de-caso-multiplataforma.md)** aplica en serio.

---

## 8. 🧾 Las seis dimensiones de portabilidad

Cuando alguien dice "esto es portable", conviene preguntar en cuál de estas seis:

| | Dimensión | Ejemplo de fallo |
|---|---|---|
| 1 | **Arquitectura de CPU** | `exec format error` |
| 2 | **Sistema operativo del binario** | un ELF de Linux en macOS |
| 3 | **libc y su versión** | `GLIBC_2.29 not found` ([F14](14-abi-libc-y-prebuilds.md)) |
| 4 | **ABI del runtime** | `NODE_MODULE_VERSION` (F14) |
| 5 | **Librerías del sistema** | `cannot open shared object file` ([F15](15-laboratorios-dependencias-nativas.md)) |
| 6 | **El motor y su host** | `host.docker.internal` en Linux ([F18](18-networking-de-contenedores.md)) |

> 🧭 **"Funciona en ARM64" es demasiado impreciso** para ser útil. ¿Funciona el runtime?
> ¿Instalan las dependencias? ¿Compilan los addons nativos? ¿Arranca el navegador? Son cuatro
> preguntas distintas con cuatro respuestas distintas, y **[F23](23-estudios-de-caso-multiplataforma.md)** las responde una a una.

---

## 9. ⚠️ Errores comunes y diagnóstico

**`exec format error`.** Arquitectura equivocada. §7.1, y `file` sobre el binario lo confirma.

**El build multiarch falla al descargar Node.** El `case` de §6.1: `amd64` no es `x64`.

**`buildx` con dos plataformas y `--load`.** No se puede. §6.2.

**"Construí para arm64 y `uname -m` dice x86_64".** Falta `--platform` en el `run`. La bandera
va en los dos comandos: construir para una arquitectura no obliga a ejecutar en ella.

**Todo va lentísimo en el Mac.** Estás emulando. Comprueba con `uname -m` dentro del contenedor
y mide antes de sacar conclusiones — **[F23](23-estudios-de-caso-multiplataforma.md)**.

**`docker manifest inspect` dice "no such manifest".** Esa imagen no es multi-plataforma, o el
registry no expone el index.

**Una dependencia nativa no encuentra prebuild en ARM64.** Es lo esperado para 2018. §4.2, y
las salidas están en **[F23](23-estudios-de-caso-multiplataforma.md)**.

---

## 10. 📋 Checklist de validación

```text
[ ] Sabes que x86_64, amd64 y x64 son la misma arquitectura
[ ] Los cuatro comandos de §4.1 responden coherentemente
[ ] docker manifest inspect muestra las plataformas de la imagen base
[ ] Distingues docker manifest inspect de docker image inspect
[ ] El Dockerfile multiarch traduce amd64→x64 y falla claro ante lo demás
[ ] Construiste la imagen para linux/arm64 y arrancó
[ ] uname -m dentro responde lo que pediste con --platform
[ ] Sabes qué es binfmt_misc y quién llama a QEMU
[ ] Distingues QEMU de máquina completa de QEMU en modo usuario
[ ] Puedes enumerar las seis dimensiones de portabilidad
```

---

## 11. 🧪 Ejercicios de la Fase 21 (25)

## 🟢 Fácil — el vocabulario de la arquitectura (1–6)

### 🟢 Ejercicio 1 — Triangula tu sistema

Ejecuta los tres comandos de §4.1 en tu host y dentro del contenedor.

**Pregunta:** ¿coinciden? Si tu host es ARM y el contenedor dice `x86_64`, ¿qué está pasando?

### 🟢 Ejercicio 2 — Los cuatro nombres

Ejecuta el bloque de §4.1 y anota cómo llama cada herramienta a tu arquitectura.

**Objetivo:** ver los cuatro nombres del mismo hardware.

### 🟢 Ejercicio 3 — El index de la imagen base

Ejecuta `docker manifest inspect debian/eol:buster | jq '.manifests[].platform'`.

**Pregunta:** ¿cuántas plataformas hay? ¿Está la tuya?

### 🟢 Ejercicio 4 — Index contra image

Compara `docker manifest inspect` con `docker image inspect --format '{{.Architecture}}'` sobre
la misma imagen.

**Pregunta:** ¿por qué uno da varias respuestas y el otro una sola?

### 🟢 Ejercicio 5 — El selector en acción

Descarga la misma imagen con `--platform linux/amd64` y con `--platform linux/arm64` y compara
sus `IMAGE ID`.

**Objetivo:** confirmar que son imágenes distintas bajo el mismo nombre.

### 🟢 Ejercicio 6 — Provoca el `exec format error`

Copia un binario de un contenedor amd64 a uno arm64 e intenta ejecutarlo.

**Objetivo:** obtener el error de §7.1 en un caso controlado.

## 🟡 Intermedio — construir para las dos (7–13)

### 🟡 Ejercicio 7 — `file` sobre binarios de las dos

Ejecuta `file /opt/node/10.24.1/bin/node` en un contenedor amd64 y en uno arm64.

**Objetivo:** ver las dos salidas y reconocerlas al instante.

### 🟡 Ejercicio 8 — Las variables de BuildKit

Construye una imagen que escriba `TARGETPLATFORM`, `TARGETARCH` y `BUILDPLATFORM` en un archivo,
para las dos arquitecturas.

**Pregunta:** ¿qué contiene cada una en tu máquina? ¿Cuándo difieren `BUILD` y `TARGET`?

### 🟡 Ejercicio 9 — El `case` que hace falta

Construye el Dockerfile de [F06](06-instalacion-node.md) —con `x64` a mano— para `linux/arm64`.

**Objetivo:** ver el fallo de descarga y entender por qué el `case` de §6.1 existe.

### 🟡 Ejercicio 10 — El Dockerfile multiarch

Escribe el de §6.1 y construye para las dos arquitecturas, una a una con `--load`.

**Objetivo:** dos imágenes que funcionan, cada una con su Node correcto.

### 🟡 Ejercicio 11 — `buildx` con las dos a la vez

Intenta `--platform linux/amd64,linux/arm64 --load`.

**Pregunta:** ¿qué error da? ¿Qué alternativas tienes? §6.2.

### 🟡 Ejercicio 12 — Node en las dos

Arranca las dos imágenes y compara `node -p process.arch` y `file $(which node)`.

**Objetivo:** confirmar que Node existe y funciona nativamente en ARM64 — §4.2.

### 🟡 Ejercicio 13 — Los cuatro digests del index, a mano

El ejercicio del index te hizo listar las plataformas. Ahora recorre el grafo entero hasta las
capas, que es lo que **[F27](27-registries-por-dentro.md)** va a formalizar:

```bash
# 1. el index: coge el digest de amd64
docker manifest inspect debian/eol:buster | jq -r '.manifests[] | select(.platform.architecture=="amd64") | .digest'

# 2. el manifest de esa plataforma: coge su config y su capa
docker manifest inspect debian/eol@sha256:<el-digest-de-arriba>
```

**Objetivo:** llegar a los cuatro digests —index, manifest de amd64, config y capa— y anotarlos.
Repite para `arm64` y compara.

**Pregunta:** ¿cuántos de los cuatro cambian entre amd64 y arm64, y cuántos se mantienen? La
respuesta dice exactamente qué comparten dos imágenes del mismo tag y qué no, que es la
diferencia entre "una imagen multi-plataforma" y "dos imágenes con el mismo nombre".

## 🟠 Difícil — cuando la arquitectura es la causa (14–20)

### 🟠 Ejercicio 14 — `binfmt_misc` en vivo

En Linux, lista `/proc/sys/fs/binfmt_misc/` antes y después de instalar los manejadores con
`tonistiigi/binfmt`.

**Pregunta:** ¿qué entradas aparecieron? ¿Qué pasa si las quitas?

### 🟠 Ejercicio 15 — El coste de emular

Ejecuta el mismo cómputo intensivo —una compilación, un `npm ci`— en un contenedor nativo y en
uno emulado, cronometrando.

**Pregunta:** ¿cuál es el factor? Guarda el número: **[F23](23-estudios-de-caso-multiplataforma.md)** lo mide con método.

### 🟠 Ejercicio 16 — La arquitectura escondida

Alguien te da un `node_modules` y dice que "no funciona". Sin ejecutar el proyecto, determina
para qué arquitectura se compiló.

**Objetivo:** encontrar los `.node` y pasarles `file`. Es [F14](14-abi-libc-y-prebuilds.md) §8 aplicado a este eje.

### 🟠 Ejercicio 17 — El build que solo funciona en su máquina

Escribe un Dockerfile que construya bien en amd64 y falle en arm64 por una razón **distinta**
al nombre del tarball de Node.

**Objetivo:** encontrar otra dependencia del Dockerfile con la arquitectura. Hay varias
candidatas.

### 🟠 Ejercicio 18 — Diagnostica sin `--platform`

Ejecuta un contenedor sin especificar plataforma en un Mac ARM y determina qué arquitectura
eligió y por qué.

**Pregunta:** ¿coincide con el baseline del curso? ¿Qué pasaría si un compañero con Intel
ejecutara lo mismo?

### 🟠 Ejercicio 19 — El `qemu-user-static` que falta

La emulación no es magia del motor: es un paquete que alguien instaló. Compruébalo quitándolo
de la ecuación. En una máquina Linux —o en la VM de tu motor— mira el estado de `binfmt_misc`
antes y después:

```bash
docker run --rm --privileged tonistiigi/binfmt              # ver qué hay registrado
docker run --rm --privileged tonistiigi/binfmt --install arm64
```

Después intenta ejecutar `--platform linux/arm64` con y sin el registro.

**Objetivo:** obtener el fallo **sin** emulación registrada y compararlo con el que §7.1
documenta para el caso de Rosetta. Los dos mensajes son distintos y los dos significan lo
mismo.

**Pregunta:** en tu máquina, ¿quién instaló la emulación y cuándo? Si usas Docker Desktop, la
respuesta es "el instalador, sin preguntarte", y por eso la emulación se siente como una
propiedad del motor y no como lo que es: **un paquete del host**. ¿Qué consecuencia tiene eso
para un servidor de CI recién aprovisionado?

### 🟠 Ejercicio 20 — Reproduce las dos mediciones de §7.4

La fase publica dos números medidos: **18×** de penalización en carga de CPU pura y **1,5×**
en carga de I/O. Reprodúcelos en tu máquina con el mismo método, que es lo que los hace
comparables: **misma versión de Node** en los dos lados, mismo script, mismo host, cambiando
solo `--platform`, y tres repeticiones.

**Objetivo:** tus dos factores, con las seis mediciones crudas detrás. Si tu host es amd64
nativo, el ejercicio cambia de sentido y se vuelve más interesante: mide entonces
**arm64 emulado sobre amd64**, que es la dirección contraria.

**Pregunta:** ¿te salen los mismos factores? Si no, la causa está en una de tres cosas —Rosetta
contra QEMU, el número de núcleos de la VM, o que tu carga no es tan pura como crees—.
Averigua cuál, y arréglalo o justifícalo. **Objetivo real del ejercicio:** que aprendas que un
benchmark sin sus condiciones declaradas no significa nada, que es la lección que
**[F23](23-estudios-de-caso-multiplataforma.md)** convierte en método.

## 🔴 Muy difícil — medir y decidir (21–25)

### 🔴 Ejercicio 21 — Las seis dimensiones sobre un fallo real

Toma un fallo de dependencia nativa en ARM64 y clasifícalo en una de las seis dimensiones de
§8.

**Objetivo:** demostrar que es la 5 y no la 1, que es la confusión habitual — y decir qué
comando lo distingue.

### 🔴 Ejercicio 22 — Haz el Dockerfile canónico multiarch

Convierte el `Dockerfile` canónico entero para que construya en las dos arquitecturas, no solo
el fragmento de Node.

**Objetivo:** encontrar **todas** las dependencias de arquitectura que quedan —hay más de una— y
que las dos imágenes pasen la prueba de humo de [F07](07-build-de-la-imagen.md) §9. Documenta cada punto que tuviste que
tocar.

### 🔴 Ejercicio 23 — La decisión de arquitectura de tu proyecto

Para tu proyecto legacy, decide en qué arquitectura vas a trabajar y justifícalo con las seis
dimensiones de §8.

**Objetivo:** que la justificación mencione qué dependencias concretas te empujan a una u otra,
no una preferencia. Y di qué medirías para cambiar de opinión.

### 🔴 Ejercicio 24 — La imagen multi-plataforma que publicas tú

Juntar `buildx` con un registry es donde todo esto deja de ser teoría. Levanta un registry
local, construye el canónico para **las dos** arquitecturas de una sola pasada y publícalo:

```bash
docker run -d -p 5000:5000 --name registry registry:2
docker buildx create --use --name multi
docker buildx build --platform linux/amd64,linux/arm64 \
  -t localhost:5000/legacy-node-toolchain:multi --push .
docker manifest inspect localhost:5000/legacy-node-toolchain:multi
```

**Objetivo:** obtener un index con **dos** entradas y demostrar que funciona de las dos formas:
`docker pull --platform` de cada una, comprobando `node -p process.arch` dentro.

**Pregunta de cierre:** ese `--push` no es un detalle: con `--load` no habrías podido. Explica
por qué el almacén local no puede guardar una imagen de dos plataformas de la misma forma que
lo hace un registry — y qué relación tiene eso con el `.Descriptor` que
[F27](27-registries-por-dentro.md) §6.1 te hace mirar. Termina diciendo cuánto tardó cada mitad
del build y cuál de las dos se emuló.

### 🔴 Ejercicio 25 — El coste real de emular tu proyecto

Los números de §7.4 son de un microbenchmark. Tu proyecto no es un microbenchmark. Mide lo que
de verdad te va a costar la emulación en un día de trabajo.

**Objetivo:** cronometrar tu ciclo completo —`npm ci`, `npm test`, `npm run build`, y el
arranque del dev server hasta que sirve la primera petición— en las **dos** arquitecturas, con
volumen limpio en cada una y tres repeticiones. Cuatro tareas × dos arquitecturas × tres
repeticiones.

Con la tabla delante, calcula el factor de cada tarea por separado y **no** un factor global:
la gracia es que van a ser muy distintos, y saber cuál es cuál decide dónde invertir.

**Pregunta de cierre:** si tu jornada tiene, pongamos, un `npm ci` y quince `npm run build`,
¿cuántos minutos al día te cuesta la emulación? Convierte ese número en la decisión que
importa: ¿compensa el trabajo de hacer el proyecto funcionar en arm64 nativo —con los dragones
de [F23](23-estudios-de-caso-multiplataforma.md) que eso implica— o compensa emular y seguir?
Defiende la respuesta con tus minutos, no con una opinión sobre la emulación.

## 🔥 Opcionales

### 🔥 Ejercicio 26 — Emulación de máquina completa

Arranca una VM x86-64 con QEMU en una máquina ARM y compara el arranque con el de un contenedor
emulado.

**Objetivo:** sentir en la práctica la diferencia entre los dos QEMU de §7.2.

### 🔥 Ejercicio 27 — Rosetta contra QEMU

En un Mac con Apple Silicon, activa y desactiva la opción de Rosetta en Docker Desktop y repite
el ejercicio 15.

**Pregunta:** ¿cuánto cambia? Guarda los números para **[F23](23-estudios-de-caso-multiplataforma.md)**.

## 💀 Boss fight

### 💀 Ejercicio 28 — Boss fight: la imagen que miente sobre sí misma

Te dan una imagen etiquetada como multi-plataforma que, en ARM64, arranca pero falla al ejecutar
una dependencia nativa. El equipo cree que "el multiarch no funciona".

**Objetivo:** demostrar con evidencia que **la imagen sí es correcta** —el index tiene las dos
plataformas, el binario de Node es ARM64 nativo— y que el problema está en otra de las seis
dimensiones. Localiza cuál, di qué comando lo prueba, y propón las dos salidas posibles con su
coste. La parte difícil no es el diagnóstico: es explicarle al equipo por qué "construir para
ARM64" y "funcionar en ARM64" son afirmaciones distintas.

---

## 12. 📚 Referencias

**OCI y multi-plataforma**
- Image Index en la especificación: https://github.com/opencontainers/image-spec/blob/main/image-index.md
- Docker — multi-platform builds: https://docs.docker.com/build/building/multi-platform/
- Variables automáticas de BuildKit: https://docs.docker.com/reference/dockerfile/#automatic-platform-args-in-the-global-scope
- `docker manifest`: https://docs.docker.com/reference/cli/docker-manifest/

**Emulación**
- QEMU: https://www.qemu.org/docs/master/
- `binfmt_misc` en el kernel: https://docs.kernel.org/admin-guide/binfmt-misc.html
- Los manejadores que instala Docker: https://github.com/tonistiigi/binfmt

**Node**
- Artefactos por plataforma: https://nodejs.org/dist/

> ⚠️ **La documentación de `binfmt_misc` del kernel es de la versión actual.** El mecanismo es
> viejo y estable desde hace décadas; lo que ha cambiado es cómo lo configuran las herramientas.

**Orden de lectura sugerido:** *Multi-platform builds* de Docker primero, y la especificación
del image index cuando el ejercicio 3 te deje con curiosidad.

---

## 13. 🏁 Resultado de la fase

```text
ISA             x86-64 = amd64 = x64 = x86_64
                ARM64  = aarch64 = arm64
                linux/amd64 → sistema operativo + arquitectura, las dos importan

IMAGE INDEX     un tag → varias imágenes, una por plataforma
                el cliente elige la suya al descargar
                multi-platform ≠ "una imagen que funciona en todas partes"

BUILD           TARGETARCH y BUILDPLATFORM son variables de BuildKit
                el case amd64→x64 traduce el vocabulario de Docker al de Node
                buildx con dos plataformas no admite --load

EMULACIÓN       exec format error = arquitectura equivocada
                QEMU máquina completa ≠ QEMU modo usuario
                binfmt_misc es quien decide llamar a QEMU
                en Apple Silicon hay DOS capas: la VM y la traducción

SEIS DIMENSIONES  CPU · SO del binario · libc · ABI · librerías · motor
```

> **La señal de que quedó bien:** *"cuando algo falla en ARM64, no digo 'es el multiarch': digo
> cuál de las seis dimensiones falló, y tengo el comando que lo prueba."*

En **[F22](22-apple-silicon-y-hosts.md)** bajamos de la teoría a tu máquina: Apple Silicon en la práctica, las cinco rutas
reales, y qué pasa con `node_modules` cuando la arquitectura entra en el nombre.
