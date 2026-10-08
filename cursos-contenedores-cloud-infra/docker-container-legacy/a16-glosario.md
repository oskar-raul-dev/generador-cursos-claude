# 📖 Apéndice a16 — Glosario

> **Curso:** Docker Legacy Node · **Apéndice opcional**
> **Requisitos:** ninguno. Es una referencia de consulta
> **Qué encontrarás:** los términos del curso definidos en una o dos frases, con la fase donde se explican de verdad

Ordenado alfabéticamente. Cada entrada dice **qué es** y, cuando el término se confunde con
otro, **con cuál** — porque la mitad de los problemas de vocabulario de este tema son pares que
se parecen.

---

## A

**ABI** — *Application Binary Interface*. El contrato entre **código ya compilado**: cómo se
pasan argumentos y cómo se disponen las estructuras en memoria. No confundir con **API**, que es
el contrato entre código fuente. Dos versiones de Node pueden compartir API y no ABI, y por eso
un addon compilado para una no carga en la otra. → **[F14](14-abi-libc-y-prebuilds.md) §5**

**addon nativo** — Un módulo de Node escrito en C o C++, compilado a un archivo `.node`, que es
una librería compartida de Linux con otra extensión. → **[F14](14-abi-libc-y-prebuilds.md) §4.2**

**air-gapped** — Un entorno sin conexión a Internet. Obliga a transportar imágenes y artefactos
a mano. → **[a13](a13-air-gapped.md)**

**APT** — El gestor de paquetes de Debian: resuelve dependencias y descarga `.deb`. No confundir
con **dpkg**, que manipula paquetes ya instalados. → **[F03](03-apt-y-utilidades.md) §4** · **[a01](a01-debian-y-apt-a-fondo.md) §1**

---

## B

**bind mount** — Conectar un directorio del host a una ruta del contenedor. **No es una copia**:
es el mismo filesystem visto desde dos sitios. → **[F09](09-montar-tu-proyecto.md) §4**

**blob** — En un registry, un trozo de datos identificado por el hash de su contenido. Las capas
y el config son blobs. → **[F27](27-registries-por-dentro.md) §5**

**build context** — El conjunto de archivos que el builder puede ver. Es el `.` final de
`docker build`. → **[F07](07-build-de-la-imagen.md) §5**

**BuildKit** — El motor de construcción de Docker. El de Podman es **Buildah**. → **[F07](07-build-de-la-imagen.md) §8** ·
**[F24](24-docker-y-podman-arquitectura.md) §11**

**`binfmt_misc`** — El mecanismo del kernel que decide llamar a QEMU cuando aparece un binario de
otra arquitectura. → **[F21](21-arquitecturas-y-emulacion.md) §7.3**

---

## C

**capa** *(layer)* — Un conjunto de cambios de filesystem, empaquetado y de solo lectura. Una
imagen es una pila de capas más su configuración. → **[F12](12-capas-cache-y-contexto.md) §6**

**capability** — Un permiso concreto del kernel —`CAP_SYS_PTRACE`, `CAP_NET_ADMIN`—. Conceder la
que hace falta es la alternativa correcta a `--privileged`. → **[F25](25-rootless-y-user-namespaces.md) §9.3**

**cgroup** — El mecanismo del kernel que limita los recursos de un grupo de procesos: memoria,
CPU. Es lo que hace efectivo `--memory`. → **[F16](16-pid1-senales-y-ciclo-de-vida.md) §9.3**

**checksum** — Un valor calculado del contenido de un archivo. Demuestra **integridad**, no
autenticidad. → **[F06](06-instalacion-node.md) §8.1** · **[a04](a04-checksums-gpg-y-archivos.md) §1**

**conmon** — El monitor por contenedor de Podman. Su equivalente en Docker es el
**containerd-shim**. → **[F24](24-docker-y-podman-arquitectura.md) §5.2**

**containerd** — El runtime de alto nivel de Docker: gestiona imágenes y ciclo de vida, y delega
la ejecución en **runc**. → **[F24](24-docker-y-podman-arquitectura.md) §4.2**

**contenedor** — Un proceso de tu sistema con una vista distinta del filesystem, la red y los
procesos. **No es una máquina virtual**: no hay kernel propio. → **[F02](02-dockerfile-esencial.md) §4**

**copy-on-write** — Escribir sobre un archivo que viene de una capa de solo lectura copia el
archivo **entero** antes de modificarlo. Es el *copy-up* de OverlayFS. → **[F13](13-overlayfs-y-copy-on-write.md) §7**

**Cosign** — La herramienta de Sigstore para firmar imágenes. → **[F29](29-supply-chain-sbom-firma.md) §7**

---

## D

**daemon** — Un servicio permanente. `dockerd` lo es; Podman no lo necesita. → **[F24](24-docker-y-podman-arquitectura.md) §4**

**descriptor** — El objeto que une el grafo de una imagen OCI: `mediaType`, `digest` y `size`.
→ **[F27](27-registries-por-dentro.md) §5**

**Dev Container** — Un contenedor configurado como ambiente completo del IDE, descrito en
`devcontainer.json`. → **[F19](19-dev-containers.md)**

**digest** — El hash del contenido de algo, con formato `sha256:...`. **Identidad de contenido**:
inmutable, a diferencia de un **tag**. Hay cuatro digests distintos en una imagen. → **[F27](27-registries-por-dentro.md) §6**

**dpkg** — La herramienta de bajo nivel de Debian: manipula paquetes instalados y archivos
`.deb`. → **[a01](a01-debian-y-apt-a-fondo.md) §1**

---

## E

**ELF** — *Executable and Linkable Format*. El formato de los binarios de Linux: ejecutables,
librerías `.so` y los `.node` de Node. → **[a03](a03-binutils-y-elf.md) §1**

**EOL** — *End of Life*. Sin parches de seguridad y con repositorios movidos al archivo. Debian
10, Node 10, 12, 14 y 16 lo son. → **[F01](01-decisiones-debian-zonas-node.md) §4.5**

**`EXPOSE`** — Una instrucción del Dockerfile que **no publica ningún puerto**: es documentación.
→ **[F18](18-networking-de-contenedores.md) §6.1**

---

## G

**glibc** — La biblioteca C de GNU, la de Debian. Alternativa: **musl**, la de Alpine. **No son
intercambiables** para binarios compilados. → **[F14](14-abi-libc-y-prebuilds.md) §6**

---

## I

**imagen** — Un artefacto inmutable: un manifest, una configuración y una pila de capas. **No es
un contenedor**: es la plantilla de la que salen. → **[F02](02-dockerfile-esencial.md) §4**

**image index** — El documento OCI que agrupa varios manifests, uno por plataforma. Es lo que
hace que un tag apunte a varias imágenes. → **[F21](21-arquitecturas-y-emulacion.md) §5**

**image ID** — El digest que identifica una imagen **en tu máquina**. De qué es hash depende de
cómo guarde las imágenes tu motor: con el almacenamiento clásico de Docker es el objeto de
**configuración**; con el image store de containerd es el **index**. En ninguno de los dos casos
tiene por qué coincidir con el digest que verías en un registry. → **[F27](27-registries-por-dentro.md) §6.1**

---

## L

**`lowerdir`** — En OverlayFS, las capas de solo lectura: tu imagen. Frente a **`upperdir`**, la
capa escribible: tu contenedor. → **[F13](13-overlayfs-y-copy-on-write.md) §5**

---

## M

**manifest** — El documento OCI que describe **una** imagen de **una** plataforma: un descriptor
al config y la lista de descriptores a las capas. → **[F27](27-registries-por-dentro.md) §5**

**`merged`** — El punto de montaje de un overlay: la vista unificada que el proceso ve como `/`.
→ **[F13](13-overlayfs-y-copy-on-write.md) §5**

**musl** — Ver **glibc**.

---

## N

**named volume** — Un volumen gestionado por el motor, con nombre, que sobrevive al contenedor.
Donde vive `node_modules` en este curso. → **[F09](09-montar-tu-proyecto.md) §5**

**namespace** — El mecanismo del kernel que cambia **lo que un proceso ve**: procesos, red,
usuarios, filesystem. No crea nada nuevo: aísla la vista. → **[F16](16-pid1-senales-y-ciclo-de-vida.md) §4**

**`node-gyp`** — La herramienta que convierte un `binding.gyp` en un Makefile y llama al
compilador. Está escrita en **Python**, y por eso Python aparece en proyectos que no lo usan.
→ **[F05](05-python-y-node-gyp.md) §5**

**`NODE_MODULE_VERSION`** — El número de versión de ABI de Node para addons. 64 en Node 10, 72 en
la 12, 83 en la 14, 93 en la 16. → **[F14](14-abi-libc-y-prebuilds.md) §5.1**

---

## O

**OCI** — *Open Container Initiative*. Estandariza el **formato de imagen**, el **runtime** y el
**protocolo de registry**. **No** estandariza la CLI, el Dockerfile, las redes ni los volúmenes.
→ **[F24](24-docker-y-podman-arquitectura.md) §7**

**OverlayFS** — El union filesystem del kernel que monta las capas de una imagen como un solo
`/` escribible. → **[F13](13-overlayfs-y-copy-on-write.md)**

---

## P

**PID 1** — El proceso principal del contenedor. Tiene semántica especial: **ignora las señales
que no maneja** y **hereda los huérfanos**. → **[F16](16-pid1-senales-y-ciclo-de-vida.md) §5**

**pod** — Un grupo de contenedores que comparten namespaces, típicamente el de red. Podman lo
tiene nativo; Docker no. → **[F24](24-docker-y-podman-arquitectura.md) §10.1**

**prebuild** — Un binario ya compilado que un paquete descarga en lugar de compilar. Depende de
cinco coordenadas —paquete, ABI, sistema, arquitectura, libc— y de que el servidor siga vivo.
→ **[F14](14-abi-libc-y-prebuilds.md) §7**

**provenance** — Un documento que registra **cómo** se construyó una imagen. Responde una
pregunta distinta al **SBOM**, que dice qué contiene. → **[F29](29-supply-chain-sbom-firma.md) §6**

---

## Q

**QEMU** — El emulador que traduce instrucciones entre arquitecturas. **En modo usuario** traduce
proceso a proceso, que es lo que hacen los contenedores; en **máquina completa** emula un
ordenador entero. → **[F21](21-arquitecturas-y-emulacion.md) §7.2**

---

## R

**registry** — Un almacén de blobs con un índice, que sirve imágenes por HTTP. **No es Git**: no
tiene historia ni diffs. → **[F27](27-registries-por-dentro.md) §4**

**rootless** — Ejecutar contenedores sin privilegios de root en el host, mediante **user
namespaces**. Natural en Podman, un modo aparte en Docker. → **[F25](25-rootless-y-user-namespaces.md) §6**

**`runc` / `crun`** — Runtimes OCI de bajo nivel: crean el contenedor y se retiran. Son
intercambiables, y eso es lo que la especificación OCI promete. → **[F24](24-docker-y-podman-arquitectura.md) §5.3**

---

## S

**SBOM** — *Software Bill of Materials*: el inventario de lo que hay dentro de un artefacto. **No
es un escáner de vulnerabilidades**: es la lista de ingredientes. → **[F29](29-supply-chain-sbom-firma.md) §4**

**shim** — El proceso que monitoriza cada contenedor, conserva sus flujos y recoge su código de
salida. `containerd-shim` en Docker, **conmon** en Podman. → **[F24](24-docker-y-podman-arquitectura.md) §4.3**

**shim despachador** — En este curso, el script que decide qué versión de Node ejecutar leyendo
`NODE_VERSION`, sin cambiar estado. → **[F08](08-run-el-contenedor-como-proceso.md) §6**

**`SIGTERM` / `SIGKILL`** — La primera es una petición educada de terminar y **se puede
ignorar**; la segunda mata sin permitir limpieza y **no se puede ignorar**. `docker stop` manda
la primera y, tras el periodo de gracia, la segunda. → **[F16](16-pid1-senales-y-ciclo-de-vida.md) §6**

**Skopeo** — Herramienta para inspeccionar y copiar imágenes **sin un motor corriendo**.
→ **[F27](27-registries-por-dentro.md) §8**

---

## T

**tag** — Un nombre humano para una imagen. **Es un puntero mutable**, no una identidad: quien
controla el repositorio puede reapuntarlo. → **[F27](27-registries-por-dentro.md) §6.2**

**`tini`** — El init minúsculo que Docker inserta con `--init`: reenvía señales y recoge
huérfanos. → **[F16](16-pid1-senales-y-ciclo-de-vida.md) §8**

**toolchain** — El conjunto de herramientas para construir software: compilador, enlazador,
`make`. En este curso, **lo que va en la imagen** — frente al proyecto, que va en el host.
→ **[F04](04-toolchain-de-compilacion.md)**

---

## U

**`upperdir`** — Ver **`lowerdir`**.

**user namespace** — El namespace que mapea UID del contenedor a UID del host. Es lo que hace
posible **rootless**. Se lee en `/proc/self/uid_map`. → **[F25](25-rootless-y-user-namespaces.md) §5**

---

## W

**whiteout** — La marca que OverlayFS deja para ocultar un archivo de una capa inferior. Aparece
como un *character device* `0,0`. **Borrar no borra**: añade una marca. → **[F13](13-overlayfs-y-copy-on-write.md) §8**

**writable layer** — La capa escribible de un contenedor, su `upperdir`. Muere con él. → **[F13](13-overlayfs-y-copy-on-write.md) §5**

---

## Los pares que más se confunden

| | |
|---|---|
| **imagen** y **contenedor** | plantilla y proceso — [F02](02-dockerfile-esencial.md) §4 |
| **API** y **ABI** | código fuente y código compilado — [F14](14-abi-libc-y-prebuilds.md) §5 |
| **tag** y **digest** | puntero mutable e identidad de contenido — [F27](27-registries-por-dentro.md) §6.2 |
| **image ID** y **digest del registry** | identidad local e identidad de contenido; de qué son hash depende del almacén — F27 §6.1 |
| **`RUN`** y **`CMD`** | build time y runtime — F02 §7.3 |
| **`ENTRYPOINT`** y **`CMD`** | el ejecutable y sus argumentos por defecto — [F08](08-run-el-contenedor-como-proceso.md) §5 |
| **`EXPOSE`** y **`-p`** | documentación y publicación real — [F18](18-networking-de-contenedores.md) §6.1 |
| **`exec`** y **`attach`** | proceso nuevo y el proceso principal — F18 §9 |
| **`--user`** y **`--userns`** | qué UID dentro y cómo se mapea fuera — [F25](25-rootless-y-user-namespaces.md) §7 |
| **SBOM** y **escaneo** | inventario y vulnerabilidades — [F29](29-supply-chain-sbom-firma.md) §4.1 |
| **paquete** y **paquete `-dev`** | ejecutar y compilar — [F15](15-laboratorios-dependencias-nativas.md) §5.2 |
| **glibc** y **musl** | dos libc incompatibles para binarios — F14 §6 |

---

## 🧭 Cuándo usar qué palabra

Un glosario dice qué significa cada término. Esta sección responde a la pregunta contraria, que
es la que tienes de verdad cuando escribes un informe o abres un issue: **tengo esto en la
cabeza, ¿cómo se llama?**. Elegir mal la palabra manda a quien te lee a la capa equivocada, y
eso cuesta más que no decir nada.

**Quieres decir "el archivo con las instrucciones".** Es un **`Dockerfile`**, y con esa
mayúscula y sin extensión. No es "el docker", no es "el script de build" y no es "la imagen":
la imagen es el resultado. → [F02](02-dockerfile-esencial.md) §4

**Quieres decir "eso que está corriendo".** Es un **contenedor**. Si todavía no corre, o si lo
que quieres es distribuirlo, es una **imagen**. La prueba rápida: si puedes hacerle `ps`, es un
contenedor.

**Quieres identificar una imagen sin lugar a dudas.** Di **digest**, no "versión" ni "ID". Y
si alguien te pide "el digest", pregunta **de qué**: hay cuatro. → [F27](27-registries-por-dentro.md) §6

**Quieres decir "no funciona en la otra arquitectura".** Si el binario no arranca, es un
problema de **arquitectura** (`amd64` contra `arm64`). Si arranca y se queja de una versión, es
de **ABI**. Si se queja de una librería que falta, es de **enlazado dinámico**. Son tres capas
distintas y tres arreglos distintos. → [F14](14-abi-libc-y-prebuilds.md) §5 y §6

**Quieres decir "el sitio donde vive node_modules".** Es un **named volume**, no "un volumen
montado" a secas y desde luego no "una carpeta compartida" — que es lo que sí es un **bind
mount**. La diferencia decide si sobrevive al `docker rm`. → [F09](09-montar-tu-proyecto.md) §5

**Quieres decir "se quedó sin recoger".** Un proceso terminado que nadie enterró es un
**zombie**; uno cuyo padre murió antes es un **huérfano**. El segundo es la causa del primero
en un contenedor, y decir "zombie" cuando quieres decir "huérfano" hace que te recomienden
`--init` cuando el problema era otro. → [F16](16-pid1-senales-y-ciclo-de-vida.md) §8

**Quieres decir "el servidor donde están las imágenes".** Es un **registry**. Dentro tiene
**repositories**, y cada uno tiene **tags**. "Repositorio" a secas, en una conversación sobre
contenedores, se confunde con el de Git en menos de dos frases. → [F27](27-registries-por-dentro.md) §4.1

**Quieres decir "la lista de lo que hay dentro".** Es un **SBOM**. Si lo que quieres es la
lista de lo que está **mal**, es un **escaneo de vulnerabilidades**. Y si quieres saber **cómo
se construyó**, es la **provenance**. Tres preguntas, tres artefactos. → [F29](29-supply-chain-sbom-firma.md) §8

**Quieres decir "corre sin ser root".** Cuidado, porque hay dos cosas distintas: **non-root**
es que el proceso *dentro* del contenedor no sea `root` ([a05](a05-non-root-a-fondo.md));
**rootless** es que el *motor* no corra como `root` ([F25](25-rootless-y-user-namespaces.md)).
Se pueden tener las dos, una, o ninguna, y confundirlas es la fuente número uno de discusiones
de seguridad que no llegan a ningún sitio.

> 🧭 **La regla que ordena todas las anteriores:** cuando dudes entre dos términos, elige el
> que nombra **la capa donde está el problema**, no la que tienes delante. El síntoma casi
> siempre aparece una capa por encima de la causa, y el vocabulario es lo primero que manda a
> quien te ayuda al sitio correcto — o al equivocado.

---

## 🧪 Ejercicios (5)

Un glosario se verifica usándolo, no leyéndolo. Estos cinco te obligan a hacerlo.

### 🟢 Ejercicio 1 — Sin mirar

Tapa la columna de definiciones y explica en voz alta, en una frase, estos ocho términos:
capa, digest, manifest, ABI, namespace, cgroup, rootless y whiteout.

**Objetivo:** identificar cuáles no supiste, ir a la fase que la entrada indica y releer solo
esa sección. Es la ruta de repaso más barata que tiene el curso.

### 🟢 Ejercicio 2 — Demuestra un par

Elige tres filas de la tabla de pares confundibles y **demuestra la diferencia con un
comando**, no con una explicación: por ejemplo, que un tag puede reapuntarse y un digest no.

**Objetivo:** una salida de terminal por par, con la línea exacta que evidencia la diferencia.

### 🟡 Ejercicio 3 — El término que falta

Recorre las tres últimas fases que hiciste y anota los términos técnicos que el curso usa y
que este glosario **no** define.

**Objetivo:** escribir la entrada que falta con el mismo formato —qué es, con qué se confunde,
y la fase donde se explica— y decir si su ausencia era un olvido o si el término no merecía
entrada.

### 🟠 Ejercicio 4 — La cadena de una imagen

Explica, encadenando entradas de este glosario, todo lo que ocurre desde que escribes
`docker push` hasta que otra persona hace `docker pull` en otra arquitectura. Tienes que usar
al menos: registry, blob, manifest, image index, descriptor, digest y tag.

**Objetivo:** que la explicación no tenga saltos —cada término se apoya en el anterior— y que
señales el punto exacto donde interviene el image index. Contrasta con
[F27 §5](27-registries-por-dentro.md) y [F21 §5](21-arquitecturas-y-emulacion.md).

### 🔴 Ejercicio 5 — Explícaselo a quien no hizo el curso

Elige los cinco términos que más te costaron y escribe, para cada uno, la explicación que le
darías a un compañero que sabe programar pero nunca usó contenedores. Sin metáforas de
mudanzas ni de cajas.

**Objetivo:** que cada explicación se apoye en algo que esa persona ya sabe —procesos,
archivos, permisos, enlaces simbólicos— y que termine con una consecuencia práctica, no con
una definición. Si no puedes, todavía no lo entiendes del todo.

---

**Vuelve a:** [`0-programa-del-curso.md`](0-programa-del-curso.md) · la chuleta de comandos está en [a15](a15-chuleta-de-comandos.md)
