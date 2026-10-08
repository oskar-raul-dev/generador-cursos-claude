"""Reemplaza los bloques `text` que son diagramas por bloques `mermaid` (D-12, guía §16.1).

Cada entrada: (archivo, línea de la valla ```text, inicio esperado de la primera línea del cuerpo,
cuerpo Mermaid). Falla sin escribir nada si alguna valla no está donde se espera.
Uso: python3 migrar_diagramas.py <carpeta-del-curso> [--aplicar]
"""
import pathlib, sys

D = []
def d(archivo, linea, inicio, cuerpo):
    D.append((archivo, linea, inicio, cuerpo.strip("\n")))

d("00-PARTE-I-taller.md", 38, "TU MÁQUINA", '''
flowchart LR
    subgraph H["TU MÁQUINA (el host)"]
        SRC["código fuente"]
        ED["editor, Git, ramas"]
    end
    subgraph C["EL CONTENEDOR"]
        WS["/workspace"]
        TC["Node 10 / 12 / 14 / 16<br/>GCC, make, pkg-config<br/>Python 2.7 y 3.7<br/>utilidades Linux"]
    end
    NM[("node_modules")]
    SRC -- "bind mount" --> WS
    NM -- "named volume" --> WS
''')

d("00-problema-y-contrato.md", 55, "Windows 11", '''
flowchart LR
    W["Windows 11"] --> N["«Instala Node 10 aquí» 😬"]
    M["macOS actual"] --> N
    A["Apple Silicon"] --> N
    L["Linux moderno"] --> N
''')

d("00-problema-y-contrato.md", 67, "HOST MODERNO", '''
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
        NPM["npm"]
        PY["Python"]
        CC["compiladores"]
        HA["herramientas auxiliares"]
    end
    H --> ENG --> C
''')

d("00-problema-y-contrato.md", 149, "Mac Apple Silicon", '''
flowchart TD
    MAC["Mac Apple Silicon"] --> N1["Node 10 nativo en macOS<br/>❌ no existe darwin-arm64 antes de la 16"]
    MAC --> N2["Node 10 vía Rosetta 2<br/>⚠️ binario Intel, emulación que no controlas"]
    MAC --> CT["contenedor Linux"]
    CT --> A1["Node 10 linux/arm64<br/>✅ binario oficial, nativo en tu CPU"]
    CT --> A2["Node 10 linux/amd64<br/>✅ binario oficial, traducido y aislado"]
''')

d("01-decisiones-debian-zonas-node.md", 175, "┌─ ZONA A", '''
flowchart TD
    A["ZONA A · HOST<br/>Git · repositorio · código fuente<br/>configuración del proyecto · editor o IDE"]
    B["ZONA B · TOOLCHAIN CONTAINER<br/>Debian 10 · Node · npm · Python<br/>compiladores · Git y utilidades<br/>dependencias del sistema"]
    C["ZONA C · BROWSER TESTING (opcional)<br/>Chromium · Firefox · Selenium standalone<br/>Xvfb · librerías gráficas"]
    A -- "bind mount" --> B
    B -. "solo si el proyecto lo pide" .-> C
''')

d("01-decisiones-debian-zonas-node.md", 209, "HOST ", '''
flowchart LR
    subgraph HOST
        W["C:\\dev\\old-vue"]
        M["/Users/oskar/dev/old-vue"]
        L["/home/me/proyecto"]
    end
    subgraph CONTENEDOR
        WS["/workspace"]
    end
    W -- "bind mount" --> WS
    M -- "bind mount" --> WS
    L -- "bind mount" --> WS
''')

d("01-decisiones-debian-zonas-node.md", 241, "código fuente", '''
flowchart LR
    H["HOST<br/>código fuente"] -- "bind mount" --> WS["/workspace"]
    V[("NAMED VOLUME<br/>node_modules")] -- "volume mount" --> NM["/workspace/node_modules"]
''')

d("02-dockerfile-esencial.md", 68, "Dockerfile ", '''
flowchart LR
    D["Dockerfile<br/>texto · receta<br/>editas con vim"] -- "docker build" --> I["imagen<br/>artefacto inmutable<br/>se guarda en tu disco"]
    I -- "docker run" --> C["contenedor<br/>proceso en ejecución<br/>arranca, vive, muere"]
''')

d("04-toolchain-de-compilacion.md", 68, "npm", '''
flowchart TD
    NPM["npm"] --> P["paquete con componente nativo"] --> Q{"¿hay binario precompilado compatible?"}
    Q -- "sí" --> DL["descargarlo y usarlo<br/>rápido, silencioso, y no siempre disponible"]
    Q -- "no" --> CL["compilar localmente"] --> T["toolchain C/C++<br/>lo que instalamos en esta fase"]
''')

d("05-python-y-node-gyp.md", 87, "tu proyecto Vue 2", '''
flowchart TD
    P["tu proyecto Vue 2"] -- "npm install" --> A["alguna dependencia con addon nativo"]
    A --> G["node-gyp<br/>escrito en Python"] --> MK["Makefile generado"]
    MK --> MAKE["make → g++ / gcc<br/>lo que instalamos en F04"] --> N["addon.node"]
''')

d("05-python-y-node-gyp.md", 120, "binding.gyp", '''
flowchart TD
    B["binding.gyp<br/>lo escribe el autor del paquete"] --> C["node-gyp configure<br/>lee binding.gyp, resuelve las cabeceras de Node"]
    C --> M["build/Makefile<br/>generado, no escrito a mano"] --> NB["node-gyp build"]
    NB --> MK["make<br/>F04"] --> G["g++ / gcc<br/>F04"]
    G --> R["build/Release/addon.node<br/>una librería compartida con otra extensión"]
''')

d("07-build-de-la-imagen.md", 61, "┌────", '''
flowchart TD
    D["Dockerfile<br/>la receta"] --> C["Build context<br/>los archivos que el builder puede ver"]
    C --> O["Opciones<br/>--platform, --tag, --build-arg, --no-cache…"]
    O --> B["Builder<br/>BuildKit (Docker) · Buildah (Podman)"]
    B --> R["Resultado<br/>una imagen — pero no necesariamente"]
''')

d("08-run-el-contenedor-como-proceso.md", 100, "imagen  ──create", '''
stateDiagram-v2
    [*] --> Created: create, desde la imagen
    Created --> Running: start
    Running --> Exited: el proceso termina
    Exited --> Running: start
    Exited --> [*]: rm, ya no existe
''')

d("09-montar-tu-proyecto.md", 119, "HOST ", '''
flowchart LR
    subgraph HOST
        P["tu-proyecto/"]
    end
    subgraph CT["CONTENEDOR · /workspace/"]
        PJ["package.json ← host"]
        S["src/ ← host"]
        NM["node_modules/ ← VOLUMEN, no host"]
    end
    V[("miproyecto-node10-modules")]
    P -- "bind mount" --> PJ
    P -- "bind mount" --> S
    V -- "named volume" --> NM
''')

d("10-vscode-y-debugging.md", 61, "┌─ EL IDE", '''
flowchart LR
    IDE["EL IDE · VS Code, WebStorm, Vim<br/>edita texto, resalta sintaxis, lanza comandos,<br/>conecta un debugger. Corre en TU host, moderno."]
    PR["EL PROYECTO · package.json, src/<br/>tu código y sus dependencias. Vive en el host,<br/>se ejecuta en el contenedor."]
    RT["EL RUNTIME · Node 10 en Debian 10<br/>ejecuta tu código. Node 10 dentro del contenedor,<br/>Debian 10, glibc de 2019."]
    IDE -- "edita" --> PR
    RT -- "ejecuta" --> PR
''')

d("12-capas-cache-y-contexto.md", 223, "manifest", '''
flowchart TD
    M["manifest"] --> C["config<br/>metadatos: Env, Entrypoint, Cmd, WorkingDir, Labels, arquitectura"]
    M --> L["layers[]<br/>los cambios de filesystem, cada uno un blob comprimido"]
''')

d("12-capas-cache-y-contexto.md", 251, "base", '''
flowchart TD
    B["base"] --> C1["capa 1: agrega A"] --> C2["capa 2: agrega B"] --> C3["capa 3: elimina A"]
''')

d("13-overlayfs-y-copy-on-write.md", 69, "                merged/", '''
flowchart BT
    U["upperdir/<br/>escribible<br/>(el contenedor)"] --> M["merged/<br/>lo que ve el proceso: un / normal"]
    L["lowerdir/<br/>solo lectura, apilado<br/>lower2 : lower1 : base<br/>(las capas de la imagen)"] --> M
''')

d("13-overlayfs-y-copy-on-write.md", 783, "IMAGEN ", '''
flowchart TD
    subgraph IMAGEN
        L["lowerdir (compartido)<br/>capas de solo lectura"]
    end
    subgraph CONTENEDOR
        U["upperdir (efímero, por contenedor)<br/>una capa escribible"]
    end
    L --> M["merged<br/>el / que ve el proceso"]
    U --> M
    BM["bind mounts y volumes<br/>se montan ENCIMA, fuera del overlay:<br/>no copy-up, no whiteouts, sobreviven al docker rm"] -. "encima" .-> M
''')

d("14-abi-libc-y-prebuilds.md", 91, "npm instala el paquete", '''
flowchart TD
    A["npm instala el paquete"] --> B["script de install (postinstall)"]
    B --> Q{"¿hay un prebuilt compatible con<br/>mi plataforma, arquitectura y ABI?"}
    Q -- "sí" --> S["descargarlo. Rápido y silencioso"]
    Q -- "no" --> N["compilar. Aquí entra el toolchain de F04"]
''')

d("15-laboratorios-dependencias-nativas.md", 295, "npm install puppeteer", '''
flowchart TD
    A["npm install puppeteer"] --> B["install.js"]
    B --> C["descarga un Chromium de una revisión concreta,<br/>de una URL concreta"] --> D["lo guarda en un caché"]
''')

d("16-pid1-senales-y-ciclo-de-vida.md", 144, "docker stop mi-contenedor", '''
sequenceDiagram
    participant S as docker stop mi-contenedor
    participant P as PID 1 del contenedor
    S->>P: t=0s · SIGTERM
    Note over P: el proceso puede cerrar ordenadamente
    Note over S,P: espera el periodo de gracia (10 segundos por defecto)
    S->>P: t=10s · si sigue vivo, SIGKILL
    Note over P: muerte inmediata, sin limpieza
''')

d("16-pid1-senales-y-ciclo-de-vida.md", 394, "        ┌──────────┐  create", '''
stateDiagram-v2
    state "periodo de gracia" as Gracia
    [*] --> Created: create, desde la imagen
    Created --> Running: start
    Running --> Gracia: stop
    Gracia --> Exited
    Running --> Paused: pause
    Exited --> Running: start
    Exited --> [*]: rm, ya no existe
''')

d("17-usuarios-permisos-y-volumenes.md", 105, "LINUX NATIVO", '''
flowchart TD
    subgraph LN["LINUX NATIVO"]
        H1["tu host"] -- "mismo kernel" --> C1["contenedor"]
        C1 -.- N1["el UID viaja tal cual<br/>→ archivos de root"]
    end
    subgraph MW["macOS / WINDOWS con Docker Desktop"]
        H2["tu host (macOS)"] -- "file sharing (virtiofs, gRPC-FUSE)" --> VM["VM Linux"] --> C2["contenedor"]
        C2 -.- N2["la capa de compartición traduce<br/>→ archivos con TU usuario"]
    end
''')

d("18-networking-de-contenedores.md", 211, "red legacy-net", '''
flowchart LR
    subgraph NET["red legacy-net"]
        WEB["web · 172.18.0.3"] -- "curl http://api<br/>el DNS de la red resuelve «api»" --> API["api · 172.18.0.2"]
    end
''')

d("19-dev-containers.md", 64, "TU HOST", '''
flowchart LR
    subgraph HOST["TU HOST"]
        UI["VS Code (la UI)<br/>ventanas, teclas<br/>extensiones de UI"]
    end
    subgraph CT["EL CONTENEDOR"]
        SRV["VS Code Server<br/>extensiones del proyecto<br/>terminal integrada<br/>Node 10, npm, gcc…<br/>tu proyecto en /workspace"]
    end
    UI <--> SRV
''')

d("20-validacion-sistematica-y-evidencia.md", 128, "más fiable", '''
flowchart TD
    MAS(["más fiable"]) --> A["package-lock.json<br/>lo que se instaló de verdad"]
    A --> B["el CI histórico<br/>.travis.yml, .gitlab-ci.yml, workflows: dicen qué Node usaban"]
    B --> C[".nvmrc<br/>la versión que el equipo usaba en local"]
    C --> D["engines<br/>lo que el autor esperaba"]
    D --> E["la fecha de los commits<br/>te da la época"]
    E --> F["el README<br/>a menudo desactualizado"]
    F --> G["los comentarios del código"] --> MENOS(["menos fiable"])
''')

d("20-validacion-sistematica-y-evidencia.md", 404, "tu proyecto entero falla", '''
flowchart TD
    T["tu proyecto entero falla"] --> Q1{"¿falla el fixture de control?"}
    Q1 -- "sí" --> LAB["el problema es el laboratorio"]
    Q1 -- "no" --> Q2["¿falla con solo las dependencias de producción?"]
    Q2 --> Q3["¿falla instalando una sola dependencia sospechosa?"]
    Q3 --> Q4["¿falla con un package.json de tres líneas?"]
    Q4 --> MIN["el caso mínimo que reproduce el fallo"]
''')

d("21-arquitecturas-y-emulacion.md", 140, "tag: debian/eol:buster", '''
flowchart TD
    T["tag: debian/eol:buster"] --> I["IMAGE INDEX<br/>(a veces llamado «manifest list»)"]
    I --> A["linux/amd64 → manifest → config + capas amd64"]
    I --> R["linux/arm64 → manifest → config + capas arm64"]
    I --> X["linux/386 → …"]
    I --> S["linux/s390x → …"]
''')

d("21-arquitecturas-y-emulacion.md", 326, "host ARM64", '''
flowchart TD
    H["host ARM64"] --> Q["QEMU emula una máquina x86-64 entera"]
    Q --> K["kernel Linux x86-64"] --> U["todo el userspace x86-64"]
''')

d("21-arquitecturas-y-emulacion.md", 340, "kernel Linux ARM64", '''
flowchart TD
    K["kernel Linux ARM64<br/>uno solo, el nativo"] --> A["programa ARM64"] --> CPU1["CPU directa, velocidad nativa"]
    K --> X["programa x86-64"] --> Q["qemu-x86_64<br/>traduce instrucciones al vuelo"] --> CPU2["CPU ARM64"]
''')

d("21-arquitecturas-y-emulacion.md", 364, "el kernel intenta", '''
flowchart TD
    A["el kernel intenta ejecutar un ELF x86-64"] --> B["mira su tabla de binfmt_misc"]
    B --> C["«este formato lo maneja /usr/bin/qemu-x86_64»"] --> D["lanza QEMU con el binario como argumento"]
''')

d("22-apple-silicon-y-hosts.md", 26, "Mac Apple Silicon, proyecto", '''
flowchart TD
    M["Mac Apple Silicon, proyecto con Node 10"] --> N["nvm install 10<br/>tarball darwin-x64 + Rosetta 2<br/>emulación implícita, no declarada, no reproducible"]
    M --> C["contenedor"]
    C --> A["linux/arm64<br/>binario oficial ARM64, sin traducción"]
    C --> X["linux/amd64<br/>binario oficial x86-64, traducción declarada<br/>en --platform y reproducible en cualquier host"]
''')

d("22-apple-silicon-y-hosts.md", 100, "CASO A", '''
flowchart TD
    subgraph SA["CASO A · tu terminal de macOS"]
        A1["node (darwin-x64)"] --> A2["Rosetta 2 de macOS"] --> A3["CPU ARM"]
    end
    subgraph SB["CASO B · dentro de la VM Linux"]
        B1["node (linux-x64)"] --> B2["QEMU o Rosetta expuesta a la VM"] --> B3["CPU ARM"]
    end
''')

d("23-estudios-de-caso-multiplataforma.md", 231, "                    proyecto legacy", '''
flowchart TD
    P["proyecto legacy"] --> Q1{"¿tiene dependencias nativas<br/>(categoría C o D)?"}
    Q1 -- "no" --> R1["ARM64 nativo<br/>🟢 rápido y sin traducir"]
    Q1 -- "sí" --> Q2{"¿hay prebuilds ARM64<br/>para todas?"}
    Q2 -- "sí" --> R2["ARM64 nativo 🟢"]
    Q2 -- "no" --> Q3{"¿compilan en ARM64<br/>sin tocar el proyecto?"}
    Q3 -- "sí" --> R3["ARM64 nativo<br/>🟡 más lento al instalar"]
    Q3 -- "no" --> R4["AMD64 emulado<br/>🟡 el baseline del curso"]
    R4 --> Q4{"¿el rendimiento<br/>es inaceptable?"}
    Q4 -- "no" --> R5["quédate"]
    Q4 -- "sí" --> R6["CI amd64<br/>o VM completa"]
''')

d("24-docker-y-podman-arquitectura.md", 59, "docker run ...", '''
flowchart TD
    C["docker run ..."] -- "API HTTP sobre un socket Unix" --> D["dockerd<br/>el daemon: siempre corriendo, normalmente como root"]
    D --> CD["containerd<br/>gestiona el ciclo de vida y las imágenes"]
    CD --> S["containerd-shim<br/>un proceso por contenedor"]
    S --> R["runc<br/>crea el contenedor y se retira"]
    R --> P["tu proceso<br/>PID 1 del contenedor (F16)"]
''')

d("24-docker-y-podman-arquitectura.md", 139, "podman run ...", '''
flowchart TD
    C["podman run ..."] -- "fork-exec: el proceso lo lanza TU comando, con TU usuario" --> L["libpod<br/>la biblioteca donde vive la lógica"]
    L --> M["conmon<br/>un monitor por contenedor"]
    M --> R["crun o runc<br/>crea el contenedor y se retira"]
    R --> P["tu proceso"]
''')

d("25-rootless-y-user-namespaces.md", 59, "MODELO ROOTFUL", '''
flowchart TD
    subgraph RF["MODELO ROOTFUL"]
        F1["uid 0 dentro"] -- "sin traducción" --> F2["uid 0 fuera = root del host"]
        F2 -.- F3["si escapa: es root en tu máquina"]
    end
    subgraph RL["MODELO ROOTLESS"]
        L1["uid 0 dentro"] -- "user namespace" --> L2["uid 1000 fuera = tu usuario"]
        L2 -.- L3["si escapa: eres tú, ni más ni menos"]
    end
''')

d("26-portabilidad-entre-motores.md", 63, "tu comando (macOS)", '''
flowchart TD
    C["tu comando (macOS)"] --> VM["VM Linux del motor<br/>Docker Desktop, Podman Machine o Colima"]
    VM --> K["kernel Linux"]
    VM --> FS["file sharing<br/>virtiofs, gRPC-FUSE… los bind mounts pasan por aquí"]
    VM --> CT["contenedor"]
''')

d("26-portabilidad-entre-motores.md", 258, "1. ¿funciona el motor", '''
flowchart TD
    Q1{"1 · ¿funciona el motor desde la terminal?<br/>podman run --rm alpine echo ok"}
    Q1 -- "no" --> R1["el problema es el motor, no el IDE"]
    Q1 -- "sí" --> Q2{"2 · ¿existe el socket compatible?<br/>ls -la $XDG_RUNTIME_DIR/podman/podman.sock"}
    Q2 -- "no" --> R2["§7, levántalo"]
    Q2 -- "sí" --> Q3{"3 · ¿el cliente de Docker lo alcanza?<br/>DOCKER_HOST=... docker ps"}
    Q3 -- "no" --> R3["permisos o ruta del socket"]
    Q3 -- "sí" --> R4["4 · ahora sí, es configuración del IDE<br/>mira su log de Dev Containers"]
''')

d("27-registries-por-dentro.md", 126, "IMAGE INDEX", '''
flowchart LR
    I["IMAGE INDEX<br/>opcional: solo si es multi-plataforma"]
    I -- "para amd64" --> MA["MANIFEST (amd64)"]
    I -- "para arm64" --> MR["MANIFEST (arm64)"]
    MA -- "config" --> CB["CONFIG BLOB<br/>Env, Cmd, Entrypoint, arquitectura…"]
    MA -- "layers" --> L1["LAYER BLOB 1<br/>un tar.gz con un diff de filesystem"]
    MA -- "layers" --> L2["LAYER BLOB 2"]
    MA -- "layers" --> L3["LAYER BLOB 3"]
    MR --> O["… sus propios blobs"]
''')

d("30-troubleshooting-metodo-y-herramientas.md", 130, "┌─ 8 · PROYECTO", '''
flowchart TD
    P8["8 · PROYECTO<br/>tu código, package.json, lockfile"]
    P7["7 · DEPENDENCIAS<br/>node_modules, addons nativos, ABI"]
    P6["6 · RUNTIME<br/>Node, npm, Python, el toolchain"]
    P5["5 · IMAGEN<br/>capas, Dockerfile, paquetes del sistema"]
    P4["4 · CONTENEDOR<br/>proceso, PID 1, señales, límites"]
    P3["3 · MONTAJES<br/>bind mounts, volúmenes, permisos"]
    P2["2 · MOTOR<br/>Docker o Podman, daemon, VM"]
    P1["1 · HOST<br/>tu máquina, red, disco, arquitectura"]
    P8 --- P7 --- P6 --- P5 --- P4 --- P3 --- P2 --- P1
''')

d("30-troubleshooting-metodo-y-herramientas.md", 143, "¿funciona el fixture", '''
flowchart TD
    Q{"¿funciona el fixture de control<br/>00-node-smoke?"}
    Q -- "no" --> A["el problema está en las capas 1–5<br/>tu proyecto es inocente"]
    Q -- "sí" --> B["el problema está en las capas 6–8"]
    A --> R["en cada mitad, repite: parte por el medio"]
    B --> R
''')

d("33-forense-y-boss-fight.md", 249, "tu laboratorio completo falla", '''
flowchart TD
    F["tu laboratorio completo falla"] --> S1["imagen base pelada + un comando<br/>¿falla?"]
    S1 --> S2["+ el toolchain, sin montajes<br/>¿falla?"]
    S2 --> S3["+ el bind mount<br/>¿falla?"]
    S3 --> S4["+ el volumen<br/>¿falla?"]
    S4 --> S5["+ tu proyecto<br/>aquí apareció"]
''')

d("a01-debian-y-apt-a-fondo.md", 201, "apt-get update", '''
flowchart TD
    U["apt-get update"] -- "descarga los ÍNDICES:<br/>qué paquetes existen, versiones, hashes" --> L["/var/lib/apt/lists/<br/>decenas de MB de listas"]
    I["apt-get install curl"] -- "descarga los ARCHIVOS .deb<br/>y los instala" --> A["/var/cache/apt/archives/<br/>los .deb descargados"]
    I --> B["/usr/bin/curl<br/>el resultado"]
''')

d("a02-estrategia-node-y-clis.md", 40, "Host", '''
flowchart TD
    H["Host"] --> D["Docker / Podman<br/>aísla el sistema entero"] --> C["Contenedor"]
    C --> N["nvm<br/>aísla versiones de Node… dentro de algo ya aislado"] --> NO["Node"]
''')

d("a03-binutils-y-elf.md", 29, "┌───", '''
flowchart TD
    subgraph ELF["un archivo ELF, de arriba abajo"]
        H["ELF header<br/>qué tipo es, para qué arquitectura, dónde empieza"]
        PH["Program headers<br/>cómo cargarlo en memoria — al ejecutar"]
        S[".text · el código máquina<br/>.rodata · constantes<br/>.data / .bss · variables<br/>.dynsym / .dynstr · símbolos dinámicos — quién llama a quién<br/>.dynamic · qué librerías necesita"]
        SH["Section headers<br/>cómo enlazarlo — al compilar"]
        H --- PH --- S --- SH
    end
''')

d("a03-binutils-y-elf.md", 64, "hello.c", '''
flowchart TD
    C["hello.c"] -- "cpp · preprocesador:<br/>resuelve #35;include y #35;define" --> I["hello.i"]
    I -- "cc1 · compilador: C → ensamblador" --> S["hello.s"]
    S -- "as · ENSAMBLADOR (Binutils)" --> O["hello.o<br/>objeto: código máquina con símbolos sin resolver"]
    O -- "ld · ENLAZADOR (Binutils)" --> E["hello<br/>ejecutable ELF"]
''')

d("a03-binutils-y-elf.md", 177, "1. file <bin>", '''
flowchart TD
    S1{"1 · file #lt;bin#gt;<br/>¿es un ELF? ¿de qué arquitectura?"}
    S1 -- "no es ELF" --> R1["la descarga falló (F04 §10)"]
    S1 -- "otra arquitectura" --> R2["F21 §7"]
    S1 -- "ELF de tu arquitectura" --> S2{"2 · ldd #lt;bin#gt; #124; grep 'not found'<br/>¿le falta alguna librería?"}
    S2 -- "sí" --> R3["instala el paquete (sin -dev): F15 §5"]
    S2 -- "no" --> S3{"3 · readelf -V #lt;bin#gt; #124; grep GLIBC #124; sort -u<br/>¿exige una glibc más nueva que 2.28?"}
    S3 -- "sí" --> R4["F14 §6.1"]
    S3 -- "no" --> S4["4 · nm -D --undefined-only #lt;bin#gt;<br/>¿qué símbolo falta exactamente?<br/>búscalo con nm -D --defined-only en la librería sospechosa"]
''')

d("a04-checksums-gpg-y-archivos.md", 88, "una clave pública", '''
flowchart TD
    A["una clave pública de Node en la que confías"] --> B["verificas la firma de SHASUMS256.txt"]
    B --> C["ahora sabes que los hashes son auténticos"] --> D["verificas el tarball contra su hash"]
    D --> E["sabes que el tarball es el que Node publicó"]
''')

d("a06-webstorm.md", 28, "NIVEL A", '''
flowchart TD
    subgraph NA["NIVEL A — integración nativa"]
        A1["WebStorm"] -- "Remote Node interpreter" --> A2["Docker"] --> A3["legacy-node-toolchain"]
        A3 -.- A4["El IDE gestiona el contenedor"]
    end
    subgraph NB["NIVEL B — modo universal"]
        B1["WebStorm (solo edita)"] -- "terminal" --> B2["Docker CLI"]
        B2 --> B3["node --inspect en el contenedor"] --> B4["attach del debugger por puerto"]
    end
''')

d("a07-colima-y-lima.md", 37, "tu terminal (macOS)", '''
flowchart TD
    T["tu terminal (macOS)"] -- "docker / nerdctl" --> C["Colima<br/>configura el runtime y expone el socket"]
    C --> L["Lima<br/>gestiona la VM"] --> VM["VM Linux<br/>vz de Apple, o QEMU"]
    VM --> R["containerd o Docker Engine"] --> CT["tus contenedores"]
''')

d("a07-colima-y-lima.md", 113, "Mac ARM64", '''
flowchart TD
    M["Mac ARM64"] --> Q["QEMU emula una MÁQUINA x86-64 completa<br/>emulación de máquina, F21 §7.2 caso A"]
    Q --> K["kernel Linux x86-64"] --> C["contenedores amd64<br/>NATIVOS dentro de esa VM"]
''')

d("a08-windows-y-powershell.md", 29, "❌ C:", '''
flowchart TD
    subgraph MAL["❌ el proyecto en el filesystem de WINDOWS"]
        W["C:\\Users\\tu-usuario\\proyectos\\legacy-app"] -- "cada acceso desde el contenedor<br/>cruza una frontera cara" --> W2["WSL2 → Docker → contenedor"]
    end
    subgraph BIEN["✅ el proyecto en el filesystem de LINUX"]
        L["\\\\wsl$\\Ubuntu\\home\\tu-usuario\\proyectos\\legacy-app<br/>o, desde dentro de WSL2: /home/tu-usuario/proyectos/legacy-app"] -- "sin cruce" --> L2["Docker → contenedor"]
    end
''')

d("a09-browsers-legacy.md", 33, "OPCIÓN A", '''
flowchart TD
    subgraph OA["OPCIÓN A — todo en una imagen"]
        A["legacy-node-toolchain<br/>+ Node + tests<br/>+ Chromium<br/>+ 25 librerías gráficas"]
    end
    subgraph OB["OPCIÓN B — contenedor aparte"]
        B1["legacy-node-toolchain<br/>tests"] -- "WebDriver / CDP" --> B2["selenium/standalone-*<br/>o browserless/chrome"]
    end
''')

d("a09-browsers-legacy.md", 190, "┌───", '''
flowchart TD
    A["legacy-node-toolchain<br/>tus tests"] -- "WebDriver, puerto 4444" --> B["selenium/standalone-chrome<br/>navegador + driver"]
''')

d("a09-browsers-legacy.md", 238, "npm install puppeteer", '''
flowchart TD
    A["npm install puppeteer"] --> B["install.js"]
    B --> C["descarga un Chromium concreto,<br/>de una URL concreta"] --> D["lo guarda en un caché local"]
''')

d("a09-browsers-legacy.md", 312, "1. ¿Existe", '''
flowchart TD
    Q1{"1 · ¿existe el ejecutable del navegador?<br/>which chromium · ls del caché de Puppeteer o Cypress"}
    Q1 -- "no" --> R1["problema de descarga o de instalación"]
    Q1 -- "sí" --> Q2{"2 · ¿es de la arquitectura correcta?<br/>file /ruta/al/binario"}
    Q2 -- "no" --> R2["§6"]
    Q2 -- "sí" --> Q3{"3 · ¿le faltan librerías?<br/>ldd /ruta/al/binario #124; grep 'not found'"}
    Q3 -- "sí" --> R3["§2, instala los paquetes que falten"]
    Q3 -- "no" --> Q4{"4 · ¿arranca a mano?<br/>/ruta/al/binario --headless --no-sandbox --dump-dom https://example.com"}
    Q4 -- "no" --> R4["lee su error: suele ser /dev/shm o el sandbox"]
    Q4 -- "sí" --> R5["5 · ahora sí, el problema está por encima:<br/>en Cypress, Selenium o tus tests"]
''')

def main():
    raiz = pathlib.Path(sys.argv[1]); aplicar = "--aplicar" in sys.argv
    por_archivo = {}
    for a, l, ini, cuerpo in D:
        por_archivo.setdefault(a, []).append((l, ini, cuerpo))
    problemas, nuevos = [], {}
    for a, entradas in por_archivo.items():
        lineas = (raiz / a).read_text(encoding="utf-8").split("\n")
        for l, ini, cuerpo in sorted(entradas, reverse=True):
            i = l - 1
            if lineas[i].strip() != "```text" or not lineas[i + 1].startswith(ini):
                problemas.append(f"{a}:{l}: no coincide ({lineas[i]!r} / {lineas[i+1]!r})")
                continue
            j = i + 1
            while lineas[j].strip() != "```":
                j += 1
            sangria = lineas[i][: len(lineas[i]) - len(lineas[i].lstrip())]
            lineas[i:j + 1] = [sangria + "```mermaid"] + [sangria + c if c else c for c in cuerpo.split("\n")] + [sangria + "```"]
        nuevos[a] = "\n".join(lineas)
    if problemas:
        print("\n".join(problemas)); return 1
    if aplicar:
        for a, t in nuevos.items():
            (raiz / a).write_text(t, encoding="utf-8")
    print(f"{len(D)} diagramas en {len(por_archivo)} archivos" + (" — aplicado" if aplicar else " — sin aplicar"))
    return 0

if __name__ == "__main__":
    sys.exit(main())
