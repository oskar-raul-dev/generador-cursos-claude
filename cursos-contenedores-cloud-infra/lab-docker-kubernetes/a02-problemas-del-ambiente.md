# 📎 Apéndice a02 — Solución de problemas del ambiente
## Laboratorio de contenedores y Kubernetes local

> **Curso:** Laboratorio de contenedores y Kubernetes local · De laboratorio
> **Usado por:** la [Fase 00](00-el-ambiente.md) y cualquier fase en la que el ambiente falle · **Versiones cubiertas:** las de [a01](a01-el-laboratorio.md)
> **Fecha de verificación ejecutada:** 03/10/2026 · macOS arm64 · Windows 11 y Linux: no verificados por el autor; se confirman al hacer el curso

**Esto no se lee de corrido.** Se entra buscando el mensaje que tienes en la pantalla, y por eso
**cada entrada empieza por el síntoma literal**. Es la cola larga de la instalación: lo que falla
pocas veces, de formas raras, y que no merece un incidente propio.

**Qué queda fuera:** los cinco fallos de ambiente más comunes, que son incidentes con enunciado,
pistas y solución en el [cuaderno](cuaderno-incidentes.md): WSL que no arranca (01), la
virtualización deshabilitada (02), la máquina de Podman que no levanta (03), el CLI que no encuentra
el motor (04) y el proxy corporativo que inspecciona TLS (27). Aquí se enlazan por su número y no se
repiten. Tampoco entra lo que es contenido de una fase, como cargar imágenes al cluster con cada
motor.

> ⚠️ **Lo de Windows 11 y de Linux no lo ejecuté.** Esas entradas salen de la documentación oficial,
> que se cita en cada una, y llevan la marca *no verificado por el autor; se confirma al hacer el
> curso*. Si te pasa distinto, la entrada se corrige con lo que viste.

---

## Índice

- [Antes de buscar: el estado de los motores](#-antes-de-buscar-el-estado-de-los-motores)
- **macOS (verificado)**
  - [Helm no instala helm-diff: `pubring.gpg: no such file or directory`](#helm-no-instala-helm-diff-pubringgpg-no-such-file-or-directory)
  - [`kubectl` no es el que instalaste](#kubectl-no-es-el-que-instalaste)
  - [`docker desktop status` dice `stopped` y Docker responde](#docker-desktop-status-dice-stopped-y-docker-responde)
  - [Podman avisa que otro proceso tiene el socket de Docker](#podman-avisa-que-otro-proceso-tiene-el-socket-de-docker)
  - [El cluster deja de contestar: `TLS handshake timeout`](#el-cluster-deja-de-contestar-tls-handshake-timeout)
  - [No puedes cambiarle la memoria a la máquina de Podman](#no-puedes-cambiarle-la-memoria-a-la-máquina-de-podman)
  - [`podman machine stop` dice que paró y no paró](#podman-machine-stop-dice-que-paró-y-no-paró)
  - [`podman compose` falla con `invalid username/password`](#podman-compose-falla-con-invalid-usernamepassword)
- **Windows 11 (no verificado)**
  - [La característica dice `DisabledWithPayloadRemoved`](#la-característica-dice-disabledwithpayloadremoved)
  - [DISM parece colgado en un porcentaje bajo](#dism-parece-colgado-en-un-porcentaje-bajo)
  - [El hipervisor está apagado: `hypervisorlaunchtype Off`](#el-hipervisor-está-apagado-hypervisorlaunchtype-off)
  - [Los dos motores se pelean por `docker_engine`](#los-dos-motores-se-pelean-por-docker_engine)
  - [El CLI de Podman dice `not a supported schema`](#el-cli-de-podman-dice-not-a-supported-schema)
  - [La memoria de Docker Desktop no se cambia en Docker Desktop](#la-memoria-de-docker-desktop-no-se-cambia-en-docker-desktop)
- **Linux (no verificado)**
  - [`permission denied` en `/var/run/docker.sock`](#permission-denied-en-varrundockersock)
  - [Pods que fallan con `too many open files`](#pods-que-fallan-con-too-many-open-files)
- **Común a las tres**
  - [El cluster no revive después de reiniciar](#el-cluster-no-revive-después-de-reiniciar)
  - [`node(s) already exist for a cluster with the name`](#nodes-already-exist-for-a-cluster-with-the-name)
- [Cuándo usar qué](#-cuándo-usar-qué)
- [Referencias](#-referencias)
- [Ejercicios](#-ejercicios-8)

---

## 🩺 Antes de buscar: el estado de los motores

La primera línea de cualquier diagnóstico del ambiente es la misma, en las tres plataformas:

```bash
task engine:status
```

Te dice qué motor tiene activo el laboratorio, si cada uno **responde** (no si su interfaz dice que
está encendido: más abajo verás por qué no es lo mismo), cuánta memoria tiene su máquina virtual y en
qué estado está la máquina de Podman. Por debajo corre `scripts/engine/engine.py`, que pregunta
`docker info` y `podman info`; [a01](a01-el-laboratorio.md#-el-motor-activo) explica qué toca y qué
no. Si el motor activo no responde, la tarea termina con error y te dice cómo arrancarlo.

---

## 🍎 macOS

### Helm no instala helm-diff: `pubring.gpg: no such file or directory`

```text
Verifying plugin signature...
Error: plugin verification failed: open /Users/oskar/.gnupg/pubring.gpg: no such file or directory
```

Helm 4 verifica la firma de los plugins por defecto y busca la clave pública en el anillo con el
formato viejo de gpg, `~/.gnupg/pubring.gpg`. Las versiones recientes de gpg guardan las claves en
otro formato (`~/.gnupg/public-keys.d`) y ese archivo no existe, aunque la clave esté importada. La
salida es exportar la clave a un anillo con el formato que Helm espera y pasárselo:

```bash
gpg --export EA17A2A206AFF8CD > ~/.gnupg/helm-diff-pubring.gpg
helm plugin install https://github.com/databus23/helm-diff/releases/latest/download/helm-diff-macos-arm64.tgz \
  --keyring ~/.gnupg/helm-diff-pubring.gpg
```

```text
Verifying plugin signature...
Signed by: Fabian Ruff (helm-diff release key) <fabian@progra.de>
Using Key With Fingerprint: C5645EF47482257A1F806D2BEA17A2A206AFF8CD
Plugin Hash Verified: sha256:af2834052ba32fe8006a44a31db16cad30baf1c46f6b59160b092974578d7798
Installed plugin: diff
```

> ⚠️ No uses `--verify=false` para salir del paso: es exactamente la verificación que vale la pena
> tener. En Linux con gpg reciente debería pasar lo mismo (*no verificado por el autor*).

### `kubectl` no es el que instalaste

```text
The following kubernetes-cli executables are shadowed by other commands earlier in your PATH:
  kubectl (shadowed by /Users/oskar/.docker/bin/kubectl)
```

Docker Desktop instala su propio `kubectl` en `~/.docker/bin` y en `/usr/local/bin`, y suele quedar
antes en el `PATH` que el que instalaste. Mira cuál gana y qué versión tiene:

```bash
which -a kubectl
kubectl version --client
```

Con el nodo del laboratorio en la versión de [a01](a01-el-laboratorio.md#-versiones-fijadas), los dos
quedan dentro del sesgo de una versión menor que admite Kubernetes, y no hace falta tocar nada. Si
algún día no es así, reordena el `PATH` en tu perfil de shell; no borres el de Docker Desktop, que lo
vuelve a poner en cada actualización.

### `docker desktop status` dice `stopped` y Docker responde

```text
$ docker desktop status --format json
{
    "SessionID": "1b0b02e8-d62e-4b84-9815-a5d183d9ab69",
    "Status": "stopped"
}
$ docker version --format '{{.Server.Version}}'
29.8.0
```

En la versión de [a01](a01-el-laboratorio.md#-versiones-fijadas), el estado que informa el CLI de
Docker Desktop no siempre coincide con el del motor: dijo `stopped` con el motor contestando. Por eso
`task engine:status` no le pregunta a la interfaz sino al motor (`docker info`). Para decidir si
Docker está vivo, la pregunta es **¿responde?**, no *¿qué dice su interfaz?*

### Podman avisa que otro proceso tiene el socket de Docker

```text
Another process was listening on the default Docker API socket address.
You can still connect Docker API clients by setting DOCKER_HOST using the
following command in your terminal session:

        export DOCKER_HOST='unix:///var/folders/yc/…/podman/podman-machine-default-api.sock'
```

No es un error: es la convivencia. Si Docker Desktop ya tiene el socket por defecto, Podman deja el
suyo en otra ruta y te dice cuál. Los comandos `podman` funcionan igual; solo las herramientas que
hablan la API de Docker sin saber de Podman necesitarían ese `DOCKER_HOST`. **El laboratorio no lo
necesita**: el Taskfile llama a `podman` o a `docker` según el motor activo, y no exporta
`DOCKER_HOST` en ningún momento.

### El cluster deja de contestar: `TLS handshake timeout`

```text
Unable to connect to the server: net/http: TLS handshake timeout
```

Y en el Monitor de Actividad, `krunkit` por encima del 200 % de CPU. Lo vi con la máquina de Podman
en su tamaño por defecto (2 GiB) y el perfil `minimo` con toda la observabilidad encendida: la
máquina virtual se queda sin memoria y el servidor de API del cluster deja de contestar antes que
cualquier otra cosa. No es un problema de certificados aunque el mensaje hable de TLS: es el apretón
de manos que no termina porque el proceso del otro lado no consigue tiempo de CPU.

La salida es darle a la máquina la memoria que pide [a01](a01-el-laboratorio.md#-la-memoria-que-ocupa-cada-perfil)
(siguiente entrada), y la prevención es no encender piezas que la fase no usa.

### No puedes cambiarle la memoria a la máquina de Podman

```text
Error: unable to change settings unless vm is stopped
```

La memoria de la máquina se cambia con la máquina detenida:

```bash
podman machine stop
podman machine set --memory 4096
podman machine start
```

Si `stop` responde que paró y `set` sigue diciendo que no, mira la entrada siguiente. En Docker
Desktop, la memoria está en **Settings → Resources → Advanced → Memory limit**, y aplicarla reinicia
el motor.

### `podman machine stop` dice que paró y no paró

```text
$ podman machine stop
Machine "podman-machine-default" stopped successfully
$ podman machine list
NAME                     VM TYPE     CREATED         LAST UP            CPUS        MEMORY      DISK SIZE
podman-machine-default*  libkrun     18 minutes ago  Currently running  4           2GiB        100GiB
```

Me pasó con la máquina colapsada por falta de memoria: `stop` informó éxito dos veces y el proceso de
la máquina virtual (`krunkit`) siguió vivo. Comprueba si el proceso existe y, si existe, termínalo:

```bash
ps -axo pid,etime,comm | grep krunkit
kill <pid>          # SIGTERM bastó; SIGKILL solo si no termina en treinta segundos
podman machine list
```

`task engine:stop -- podman` hace esa comprobación después de `stop` y te avisa si la máquina
sigue encendida.

### `podman compose` falla con `invalid username/password`

```text
>>>> Executing external compose provider "/Users/oskar/.docker/bin/docker-compose". Please see podman-compose(1) for how to disable this message. <<<<

creating build container: unable to copy from source docker://golang@sha256:8a5910f31396cd4d89662f56c68b3ae31d374308270a1c3bd96672ee5ed43414: initializing source docker://golang@sha256:8a5910f31396cd4d89662f56c68b3ae31d374308270a1c3bd96672ee5ed43414: fetching manifest sha256:8a5910f31396cd4d89662f56c68b3ae31d374308270a1c3bd96672ee5ed43414 in docker.io/library/golang: unable to retrieve auth token: invalid username/password: unauthorized: incorrect username or password
```

`podman compose` no trae compose propio: delega en el primer proveedor que encuentra, y con Docker
Desktop instalado ese proveedor es el `docker-compose` de Docker. Ese cliente le pasa a Podman las
credenciales guardadas de Docker Hub, y si no le sirven, el `build` falla al bajar la imagen base. El
mismo `pull` hecho con `podman pull` funciona. La salida es bajar las imágenes base con Podman antes
de levantar compose, que es lo que hace el Taskfile con el motor activo desde la [Fase 02](02-compose-el-sistema-en-un-archivo.md).

---

## 🪟 Windows 11

> ⚠️ **Toda esta sección: no verificado por el autor; se confirma al hacer el curso.** Los mensajes
> son los de la documentación de Microsoft y de Podman, y los del material de quien preparó el
> curso en su propia máquina con Windows.

### La característica dice `DisabledWithPayloadRemoved`

```text
FeatureName : VirtualMachinePlatform
State       : DisabledWithPayloadRemoved
```

WSL 2 se apoya en dos características de Windows, `Microsoft-Windows-Subsystem-Linux` y
`VirtualMachinePlatform`. Antes de dar por hecho que están activas, mira su estado real en una
PowerShell de administrador:

```powershell
Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform | Select-Object FeatureName, State
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux | Select-Object FeatureName, State
```

`Enabled` es lo que quieres; `EnablePending` pide reiniciar; `Disabled` se arregla rápido con
`dism.exe /online /enable-feature /featurename:<nombre> /all /norestart`. `DisabledWithPayloadRemoved`
significa que los archivos de la característica no están en el disco: el mismo `dism` tiene que
descargarlos desde Windows Update antes de activarla, y por eso tarda (entrada siguiente).

### DISM parece colgado en un porcentaje bajo

La barra de progreso de `dism.exe /online /enable-feature` se queda minutos en un porcentaje bajo;
en la máquina de quien preparó el curso fue en el 14,6 %. A menudo no está colgado: está descargando la característica, o esperando a que Windows Update libere
el componente que comparten (TrustedInstaller). El trabajo lo hace `TiWorker`, no `dism`; si su CPU
sube entre una consulta y la siguiente, espera:

```powershell
Get-Process dism, TiWorker, TrustedInstaller -ErrorAction SilentlyContinue | Select-Object Name, CPU, StartTime
```

Si hay una actualización en curso en Windows Update, deja que termine y reinicia antes de reintentar.

### El hipervisor está apagado: `hypervisorlaunchtype Off`

```text
Error: 0x80370102 No se pudo iniciar la máquina virtual porque no se instaló una característica necesaria.
```

Cuando la virtualización está activa en el firmware y la característica también, la documentación de
WSL propone mirar si el hipervisor arranca con Windows:

```powershell
bcdedit /enum | findstr -i hypervisorlaunchtype
bcdedit /set hypervisorlaunchtype Auto     # en una PowerShell de administrador, y reiniciar
```

Si la virtualización del firmware es la que falta, es el incidente 02 del cuaderno.

### Los dos motores se pelean por `docker_engine`

```text
API forwarding listening on: npipe:////./pipe/docker_engine
```

Es lo que dice Podman cuando su máquina arranca y el *pipe* de la API de Docker está libre. Si
Docker Desktop ya lo tiene, Podman te pide apuntar `DOCKER_HOST` a
`npipe:////./pipe/podman-machine-default`. Es el equivalente en Windows de la entrada del socket de
macOS: los comandos `podman` y `docker` no lo necesitan, y el laboratorio tampoco.

### El CLI de Podman dice `not a supported schema`

El material previo del curso registra que una variable `CONTAINER_HOST` con un valor `npipe://`, que
queda de alternancias anteriores entre motores, rompe el CLI de Podman en Windows con un error de
esquema no soportado. La documentación de Podman para Windows no menciona esa variable. Si te pasa,
bórrala de tu usuario y abre otra terminal; `task engine:status` avisa si la encuentra definida.

```powershell
[System.Environment]::SetEnvironmentVariable("CONTAINER_HOST", $null, "User")
```

### La memoria de Docker Desktop no se cambia en Docker Desktop

Con el motor sobre WSL 2, Docker Desktop no tiene el control de memoria de las otras plataformas:
los límites de memoria, CPU y swap se configuran en la máquina virtual de WSL 2, en
`%UserProfile%\.wslconfig`, y aplican a todas las distribuciones a la vez. Por defecto, esa máquina
toma hasta la mitad de la memoria de Windows.

```ini
[wsl2]
memory=4GB
```

Para que tome el cambio, `wsl --shutdown` y volver a abrir Docker Desktop. La máquina de Podman sobre
WSL comparte esa misma configuración.

---

## 🐧 Linux

> ⚠️ **Toda esta sección: no verificado por el autor; se confirma al hacer el curso.**

### `permission denied` en `/var/run/docker.sock`

```text
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

Ese es el mensaje del cliente de Docker para Linux cuando tu usuario no puede abrir el socket (lo
reproduje con el cliente en un contenedor Linux y un usuario sin grupo; con un Docker Engine en una
máquina Linux, *no verificado por el autor*). Con Docker Engine, el socket pertenece a `root` y al grupo `docker`. La documentación oficial
propone sumar tu usuario a ese grupo:

```bash
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
```

> ⚠️ **El grupo `docker` equivale a `root`.** La documentación lo advierte con esas palabras, y
> propone el modo rootless como alternativa más restrictiva. Podman en Linux corre sin root por
> defecto y sin máquina virtual: no tiene este problema.

### Pods que fallan con `too many open files`

```text
too many open files
```

En Linux, varios nodos de kind comparten los límites de `inotify` del host, y el perfil `lab` con
la observabilidad encendida puede agotarlos. La documentación de kind propone subirlos:

```bash
sudo sysctl fs.inotify.max_user_watches=524288
sudo sysctl fs.inotify.max_user_instances=512
```

---

## 🔁 Común a las tres

### El cluster no revive después de reiniciar

```text
$ podman ps -a --format '{{.Names}} {{.Status}}'
minimo-control-plane Exited (0) 292 years ago
$ kubectl get nodes
The connection to the server 127.0.0.1:61581 was refused - did you specify the right host or port?
```

Depende del motor. **Con Docker el cluster revive solo**: Docker reinicia el contenedor del nodo con
el motor, y al minuto está `Ready` con todos sus pods `Running` (lo comprobé reiniciando Docker
Desktop con `docker desktop restart`). **Con Podman no**: después de reiniciar la máquina, el nodo
queda `Exited`, con una fecha absurda en el estado, y `kubectl` no encuentra a nadie del otro lado.
Se arranca a mano:

```bash
podman start minimo-control-plane      # en lab: también lab-worker y lab-worker2
kubectl wait --for=condition=Ready nodes --all --timeout=180s
```

Al volver, los pods pasan unos segundos por `Unknown` y `ContainerCreating` antes de reprogramarse.
Si después de eso algo sigue raro, lo más rápido es borrar el cluster y crearlo de nuevo: es
desechable por diseño, y lo que importa vive en tus archivos, no en él.

### `node(s) already exist for a cluster with the name`

```text
$ task cluster:up -- minimo
task: [cluster:up] kind create cluster --config kind/cluster-minimo.yaml
using docker due to KIND_EXPERIMENTAL_PROVIDER
ERROR: failed to create cluster: node(s) already exist for a cluster with the name "minimo"
task: Failed to run task "cluster:up": exit status 1
```

Ya hay un cluster con ese nombre **en el motor activo**. `task cluster:list` te dice cuáles existen;
si es uno viejo que no quieres, `task cluster:down -- minimo` y vuelve a crearlo. Ojo con los
motores: cada uno tiene sus propios clusters, y `kind get clusters` solo ve los del motor que le
indica `KIND_EXPERIMENTAL_PROVIDER`. Si cambiaste de motor y no ves el cluster que creaste ayer, es
que vive en el otro.

---

## 🧭 Cuándo usar qué

| Si ves… | Mira primero | Y después |
|---|---|---|
| cualquier error del motor | `task engine:status` | la entrada de tu plataforma |
| la API del cluster que no contesta | la memoria de la máquina virtual | [a01](a01-el-laboratorio.md#-la-memoria-que-ocupa-cada-perfil) |
| un error al crear el cluster | `kind get clusters` con el motor activo | si ya existe, bórralo y créalo de nuevo |
| algo de WSL o de virtualización | el cuaderno, incidentes 01 y 02 | las entradas de Windows de aquí |
| `x509` en el primer `pull` | el cuaderno, incidente 27 | — |

---

## 📚 Referencias

**Documentación oficial**

- Microsoft, *Solución de problemas del Subsistema de Windows para Linux*:
  https://learn.microsoft.com/es-es/windows/wsl/troubleshooting — los códigos de error de WSL y el
  `hypervisorlaunchtype`.
- Microsoft, *Configuración avanzada en WSL*: https://learn.microsoft.com/es-es/windows/wsl/wsl-config
  — `.wslconfig` y sus valores por defecto.
- Docker, *Settings* de Docker Desktop:
  https://docs.docker.com/desktop/settings-and-maintenance/settings/ — el límite de memoria y su
  equivalente en WSL 2.
- Docker, *Linux post-installation steps*: https://docs.docker.com/engine/install/linux-postinstall/
  — el grupo `docker` y su advertencia.
- Docker, *Rootless mode*: https://docs.docker.com/engine/security/rootless/
- Podman, *Installation*: https://podman.io/docs/installation — por qué el instalador y no Homebrew
  en macOS.
- Podman, *Podman for Windows*:
  https://github.com/podman-container-tools/podman/blob/main/docs/tutorials/podman-for-windows.md —
  la máquina sobre WSL o Hyper-V y el *pipe* de la API.
- kind, *Known Issues*: https://kind.sigs.k8s.io/docs/user/known-issues/ — `inotify` y WSL 2.
- Helm, *The Helm Plugins Guide*: https://helm.sh/docs/topics/plugins/ — la verificación de plugins
  de Helm 4.
- Kubernetes, *Version Skew Policy*: https://kubernetes.io/releases/version-skew-policy/ — por qué dos
  `kubectl` de versiones vecinas sirven.

**Orden de lectura sugerido:** ninguno; se entra por el síntoma. Antes de la [Fase 00](00-el-ambiente.md) vale la pena
leer la guía de WSL si estás en Windows.

> ⚠️ Las URL y los contenidos cambian. Las de Microsoft y Docker no fijan versión: si un paso no
> coincide con lo que ves, la versión de tu herramienta puede ser otra que la de [a01](a01-el-laboratorio.md).

---

## 🧪 Ejercicios (8)

Cortos y de consulta. Los de Windows y Linux, si tienes esa plataforma, son la mejor forma de
corregir este apéndice: anota lo que viste.

**🟢 Fácil (1–2)**

### 🟢 Ejercicio 1 — ¿Qué `kubectl` estás usando?
Encuentra todos los `kubectl` de tu `PATH` y cuál gana.

**Criterio:** `which -a kubectl` lista al menos uno, y `kubectl version --client` muestra una versión
menor 1.35, 1.36 o 1.37 (dentro del sesgo de una versión con el nodo 1.36).

<details><summary>Solución</summary>

`which -a kubectl` en macOS y Linux; en PowerShell, `Get-Command kubectl -All`. El primero de la
lista es el que corre.
</details>

### 🟢 Ejercicio 2 — El motor activo que no responde
Con Podman como motor activo (`task engine:use -- podman`), detén su máquina y corre
`task engine:status`.

**Criterio:** la tarea termina con error y su última línea dice `El motor activo (podman) no
responde. Arráncalo con: task engine:use -- podman`.

<details><summary>Solución</summary>

`podman machine stop` y `task engine:status`. Al terminar, `task engine:use -- docker` o
`task engine:use -- podman` para dejar el ambiente andando.
</details>

**🟡 Intermedio (3–5)**

### 🟡 Ejercicio 3 — El nombre que ya existe
Crea el cluster `minimo` dos veces seguidas.

**Criterio:** la segunda vez ves `node(s) already exist for a cluster with the name "minimo"`, y
`task cluster:list` muestra un solo `minimo`.

<details><summary>Solución</summary>

`task cluster:up -- minimo` dos veces. Para salir: `task cluster:down -- minimo` y crearlo de nuevo.
</details>

### 🟡 Ejercicio 4 — El cluster después de reiniciar
Con un cluster `minimo` creado, reinicia tu motor (Docker Desktop, o la máquina de Podman) y deja el
cluster respondiendo otra vez sin borrarlo.

**Criterio:** `kubectl --context kind-minimo get nodes` muestra el nodo `Ready`, y escribiste en tu
bitácora si tuviste que arrancar el nodo a mano.

<details><summary>Solución</summary>

Con Docker, espera un minuto: revive solo. Con Podman, `podman start minimo-control-plane` y
`kubectl wait --for=condition=Ready nodes --all`.
</details>

### 🟡 Ejercicio 5 — helm-diff con la firma verificada
Si todavía no tienes helm-diff, instálalo sin desactivar la verificación de firma.

**Criterio:** `helm plugin list` muestra `diff` con la versión de [a01](a01-el-laboratorio.md), y en
tu historial no hay ningún `--verify=false`.

<details><summary>Solución</summary>

La entrada de helm-diff de este apéndice: exportar la clave a un anillo con el formato viejo y pasarlo
con `--keyring`.
</details>

**🟠 Difícil (6–7)**

### 🟠 Ejercicio 6 — La interfaz contra el motor
Compara lo que dice `docker desktop status` con lo que dice `docker info`, con el motor encendido y
con el motor detenido.

**Criterio:** tu bitácora tiene las cuatro salidas, y una línea que dice cuál de las dos fuentes usa
`task engine:status` y en qué línea de `scripts/engine/engine.py` se ve.

**Rúbrica:** las cuatro salidas literales; la respuesta (`docker info`, en la función `responds`); y
una frase sobre por qué un diagnóstico pregunta al motor y no a su interfaz.

### 🟠 Ejercicio 7 — La memoria en Windows (solo si tienes Windows 11)
Limita la máquina virtual de WSL 2 a 4 GB con `.wslconfig` y comprueba que Docker Desktop la ve.

**Criterio:** `docker info --format '{{.MemTotal}}'` muestra un valor cercano a 4 GiB después de
`wsl --shutdown` y de abrir Docker Desktop otra vez.

**Rúbrica:** el `.wslconfig` usado, las dos salidas de `docker info` (antes y después), y la
corrección de este apéndice si algo no coincidió. *No verificado por el autor.*

**🔴 Muy difícil (8)**

### 🔴 Ejercicio 8 — Colapsa la máquina de Podman y recupérala
Crea una máquina de Podman de 2 GiB, levanta `minimo` con toda la observabilidad encendida (puedes
usar `task measure -- B-00 --runs 1` con Podman como motor activo) y, cuando deje de contestar,
recupérala **sin borrarla** y déjala en 4 GiB.

**Criterio:** escribiste la apuesta antes (¿colapsa o no?); tienes el síntoma literal; y al final
`podman machine list` muestra la máquina con `4GiB` y `task engine:status` responde ✅.

**Rúbrica:** la apuesta escrita antes de ejecutar; el síntoma (`TLS handshake timeout` o el que te
salga); cómo comprobaste que `stop` paró de verdad; los tres comandos de la recuperación; y qué
habrías apagado para que `minimo` entrara en 2 GiB.

---

> 🏷️ **Este apéndice no lleva tag propio.** No deja archivos en el repositorio.
