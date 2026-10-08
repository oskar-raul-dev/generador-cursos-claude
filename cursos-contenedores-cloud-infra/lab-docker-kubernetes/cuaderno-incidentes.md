# 📓 Cuaderno de incidentes
## Laboratorio de contenedores y Kubernetes local

Veintisiete fallos que vas a ver en un cluster de verdad, provocados a voluntad en uno que no cuesta
nada romper. Cada uno trae el encargo de quien lo sufre, el síntoma literal, tres pistas y la
solución. **La solución viene incluida, y abrirla antes de tiempo solo te perjudica a ti**: el
cuaderno no entrena a encontrar la respuesta, entrena el reflejo de los primeros treinta segundos.

> 📝 **Los veintisiete están completos**, cada uno con el síntoma que salió al ejecutarlo en la tanda de su fase: los
> cinco de ambiente de la [Fase 00](00-el-ambiente.md) y los de plataforma y certificados de las Fases 08 a 20. La
> Parte IV no reserva incidentes: sus fallos son de diseño (la orden huérfana, el evento repetido) y se miden en sus
> fases. Los síntomas literales son los del tag `inc/<ID>/…-roto`; con `task inc:break` sobre un laboratorio más
> avanzado pueden cambiar en detalle, y la entrada lo avisa donde se comprobó.
>
> **Fecha de verificación:** del 03/10/2026 (incidentes 05–07) al 04/10/2026 (25 y 26); el 12 y el 13, otra vez el
> 05/10/2026 sobre el laboratorio de la [Fase 26](26-idempotencia-y-outbox.md). Los 01 y 02 son de Windows y no los verificó el autor.

**Salto rápido:** [Cómo se trabaja](#-cómo-se-trabaja-un-incidente) · [Índice por síntoma](#-índice-por-síntoma) · [Índice por ID](#-índice-por-id) · [Incidentes](#-incidentes) · [Retrospectiva](#-retrospectiva)

---

## 🧭 Cómo se trabaja un incidente

Se consulta **por síntoma**, no por fase: empieza por lo que ves en la pantalla, búscalo en el índice
y llega al incidente sin haber leído la fase que lo reservó. Y cada entrada se lee completa, porque
se repite entera: nada de "ver incidente 07".

### El método: siete pasos, siempre los mismos

1. **Síntoma** — lo que se ve, literal. Cópialo antes de tocar nada.
2. **Evidencia** — qué mirar en los primeros treinta segundos, y en qué orden.
3. **Hipótesis** — dos o tres, ordenadas por probabilidad.
4. **Primer comando** — el que descarta más hipótesis de una vez.
5. **Causa** — la que confirmó la evidencia, no la que sonaba bien.
6. **Corrección** — el cambio mínimo.
7. **Prevención** — qué campo, qué sonda, qué verificación o qué hábito lo evita la próxima vez.

El paso que hace útil este cuaderno es el segundo. Sin él, es una lista de errores con su arreglo;
con él, es un entrenamiento para que el próximo `CrashLoopBackOff` te cueste un minuto y no una
tarde. La [Fase 21](21-diagnostico.md) enseña el método con nombre propio, pero el cuaderno lo aplica desde el primer
incidente.

> 🧭 **Anota el síntoma antes de arreglarlo.** Reconstruir un error de memoria produce mensajes que no
> existen, y un diagnóstico sobre un mensaje inventado no enseña nada.

### Tres formas de llegar al sistema roto

1. **Desde el tag**, en tu clon del repositorio del curso: un *worktree* desacoplado sobre
   `inc/<ID>/<slug>-roto`, y despliegas como siempre desde esa carpeta. Es la forma canónica, y la
   única que garantiza el estado exacto. Los comandos están en la
   [convención de git](00-convencion-de-git-y-tags.md#-los-incidentes-en-git).
2. **Con la tarea:** `task inc:break -- <ID>` aplica sobre tu laboratorio el cambio mínimo que lo
   rompe, y `task inc:fix -- <ID>` lo revierte. Sirve cuando ya avanzaste y no quieres volver atrás. Va al cluster
   `minimo` salvo que digas otro: `task inc:break PROFILE=lab -- <ID>` si solo tienes `lab` (y `CLUSTER=lab` si en ese
   cluster corren los valores de otro perfil). Los de las Fases 16 y 19 van siempre a `lab`.
3. **A mano:** cada entrada describe el cambio en una o dos líneas, para quien quiera provocarlo sin
   herramientas. Es la que más enseña y la que más fácil sale mal.

Los incidentes de ambiente (01–04 y 27) no se provocan de ninguna de las tres formas: se describen y
se reconocen, porque romper la virtualización de tu máquina no es un ejercicio.

### Dificultad y tiempo

| | Tiempo sugerido | Cuándo abrir la primera pista |
|---|---|---|
| 🟢 | 20–30 min | cuando pasó el tiempo y no tienes una hipótesis |
| 🟡 | 30–45 min | cuando tu primera hipótesis cayó y no tienes otra |
| 🟠 | 45–90 min | cuando llevas la mitad del tiempo sin evidencia nueva |
| 🔴 | hasta 2 h | cuando ya escribiste en tu bitácora qué descartaste y por qué |

El tiempo no es una meta: existe para que sepas cuándo estás atascado de verdad.

### La bitácora es tuya

Cada entrada cierra con **📝 Tu bitácora**: qué creíste que era, cuánto tardaste y qué te hizo verlo.
La columna de estado de los índices también es tuya. Márcala en tu copia: ⬜ sin intentar, 🟡 lo
resolví con pistas, ✅ lo resolví solo.

---

## 🔎 Índice por síntoma

Empieza por lo que ves, con el texto literal o su parte reconocible. Un mismo síntoma puede llevar a
dos incidentes con causas distintas, y cuando pasa, las dos filas están aquí.

| Lo que ves | Dónde lo ves | ID |
|---|---|---|
| `HCS_E_SERVICE_NOT_AVAILABLE` / `WSL_E_DISTRO_NOT_FOUND` | al instalar WSL o crear la máquina de Podman, en Windows | [01](#-incidente-01--instalé-todo-y-wsl-no-arranca) |
| `0x80370102 No se pudo iniciar la máquina virtual porque no se instaló una característica necesaria` | al arrancar WSL, en Windows | [02](#-incidente-02--la-máquina-dice-que-no-puede-virtualizar) |
| `Error: … VM does not exist` | `podman machine start` | [03](#-incidente-03--la-máquina-de-podman-no-levanta) |
| `Cannot connect to Podman. Please verify your connection…` | cualquier comando `podman` | [03](#-incidente-03--la-máquina-de-podman-no-levanta) |
| `failed to connect to the docker API at unix://…/docker.sock` | cualquier comando `docker`, o `kind` | [04](#-incidente-04--el-cli-no-encuentra-el-motor-que-está-corriendo) |
| `❌ docker no responde` | `task engine:status` | [04](#-incidente-04--el-cli-no-encuentra-el-motor-que-está-corriendo) |
| `x509: certificate signed by unknown authority` en el **primer** `pull`, sin registry propio | `docker pull`, `podman pull`, cualquier build | [27](#-incidente-27--en-el-portátil-de-la-empresa-no-baja-ninguna-imagen) |
| `ErrImagePull` / `ImagePullBackOff`, con `pull access denied, repository does not exist` | `kubectl get pods` y `describe pod`, con una imagen propia | [05](#-incidente-05--el-pod-espera-una-imagen-que-el-cluster-nunca-vio) |
| `curl: (7) Failed to connect to <servicio>:8080 after 4 ms`, con el pod `Running` | desde otro pod, contra un `Service` | [06](#-incidente-06--el-service-existe-y-nadie-le-contesta) |
| `Could not resolve host` / `getent hosts` con código 2, con el `Service` existiendo | desde un pod, por el nombre corto | [07](#-incidente-07--inventory-no-encuentra-a-catalog-que-está-ahí) |
| `HTTP/1.1 404 Not Found` con `content-length: 0`, sin línea en el log del servicio y la ruta en `Accepted=True` | `curl` por la puerta (`api.localhost:8080`) | [08](#-incidente-08--el-navegador-recibe-404-y-ningún-pod-se-entera) |
| el `ConfigMap` con el valor nuevo y el servicio respondiendo con el viejo | `kubectl get configmap` contra la respuesta del servicio | [09](#-incidente-09--cambié-la-configuración-y-el-servicio-sigue-igual) |
| `CreateContainerConfigError`, sin logs | `kubectl get pods`; en los eventos, `secret "…" not found` | [10](#-incidente-10--el-pod-no-llega-ni-a-arrancar) |
| pod y PVC en `Pending`, sin logs; en el PVC, `storageclass.storage.k8s.io "…" not found` | `kubectl get pods,pvc` y `describe pvc` | [11](#-incidente-11--postgres-se-queda-esperando-para-siempre) |
| `CrashLoopBackOff` con un log de una línea; en `describe`, `Reason: OOMKilled` y `Exit Code: 137` | `kubectl get pods`, `logs --previous` y `describe pod` | [12](#-incidente-12--inventory-muere-sin-decir-nada) |
| `Running` con `0/1`, sin reinicios; `Readiness probe failed: … statuscode: 503` | `kubectl get pods` y los eventos del pod | [13](#-incidente-13--el-servicio-corre-y-nunca-recibe-tráfico) |
| reinicios que crecen con la carga; `Liveness probe failed: … context deadline exceeded` y `Container … failed liveness probe, will be restarted` | `kubectl get pods` y los eventos del pod | [14](#-incidente-14--kubernetes-reinicia-un-pod-que-estaba-bien) |
| `Pending` sin logs; `0/1 nodes are available: 1 Insufficient memory` | `kubectl get pods` y los eventos del pod | [15](#-incidente-15--la-réplica-nueva-no-encuentra-dónde-vivir) |
| `error: deployment "…" exceeded its progress deadline`; `READY 2/2` con `UP-TO-DATE 1`; `ProgressDeadlineExceeded` | `kubectl rollout status` y las condiciones del `Deployment` | [16](#-incidente-16--el-despliegue-se-quedó-a-la-mitad) |
| el HPA con `cpu: <unknown>`; `error: Metrics API not available`; en metrics-server, `x509: cannot validate certificate for <IP> because it doesn't contain any IP SANs` | `kubectl get hpa`, `kubectl top` y el log de metrics-server | [17](#-incidente-17--el-autoescalador-no-ve-nada) |
| `curl: (60) SSL certificate problem: certificate has expired` / `NET::ERR_CERT_DATE_INVALID`, después de días funcionando, y el listener en `ResolvedRefs=True` | `curl` o el navegador contra `https://…:8443` | [18](#-incidente-18--ayer-funcionaba-y-hoy-el-navegador-no-entra) |
| `unable to get local issuer certificate` / `x509: certificate signed by unknown authority` contra la puerta, con la CA del laboratorio en el cliente | `curl --cacert`, un cliente en Go | [19](#-incidente-19--el-cliente-no-confía-en-quien-firmó) |
| `no alternative certificate subject name matches target host name` / `NET::ERR_CERT_COMMON_NAME_INVALID`, en un nombre sí y en otro no | `curl` o el navegador | [20](#-incidente-20--el-certificado-es-válido-pero-no-para-este-nombre) |
| `SSL_ERROR_SYSCALL` en todos los nombres; en el listener, `InvalidCertificateRef … private key does not match public key` | `curl` y `kubectl get gateway -o yaml` | [21](#-incidente-21--el-gateway-rechaza-su-propio-certificado) |
| `ContainerCreating` con `MountVolume.SetUp failed … secret "…-tls" not found`; el `Certificate` en `READY False` | `kubectl get pods,certificate` y los eventos | [22](#-incidente-22--cert-manager-no-emite-nada) |
| la venta en 503 (`pricing no contesta`) con `(certificate_required) Received fatal alert`; en `pricing`, `tls: client didn't provide a certificate` | el log de `inventory` y el de `pricing` | [23](#-incidente-23--pricing-rechaza-a-inventory-con-mtls) |
| `ImagePullBackOff` con `Head "https://lab-registry:5000/v2/…": tls: failed to verify certificate: x509: certificate signed by unknown authority`, después de un `push` que pasó | `kubectl describe pod` | [24](#-incidente-24--el-cluster-no-puede-traer-imágenes-del-registry-propio) |
| `CreateContainerConfigError`, sin logs: `container has runAsNonRoot and image will run as root` (o `image has non-numeric user`) | `kubectl get pods` y el estado del contenedor | [25](#-incidente-25--endurecí-el-pod-y-dejó-de-arrancar) |
| `504` con `upstream request timeout` a los 16 s; adentro, `EAI_AGAIN` al resolver y la IP conectando, después de un *default deny* | `curl` por la puerta, y un pod del namespace | [26](#-incidente-26--cerré-la-red-y-se-rompió-todo-hasta-lo-permitido) |


---

## 📋 Índice por ID

| ID | Fase | Título | Familia | Dif. | Tiempo | Estado |
|---|---|---|---|---|---|---|
| [01](#-incidente-01--instalé-todo-y-wsl-no-arranca) | 00 | Instalé todo y WSL no arranca | 🩺 | 🟢 | 20 min | ⬜ |
| [02](#-incidente-02--la-máquina-dice-que-no-puede-virtualizar) | 00 | La máquina dice que no puede virtualizar | 🩺 | 🟢 | 20 min | ⬜ |
| [03](#-incidente-03--la-máquina-de-podman-no-levanta) | 00 | La máquina de Podman no levanta | 🩺 | 🟡 | 30 min | ⬜ |
| [04](#-incidente-04--el-cli-no-encuentra-el-motor-que-está-corriendo) | 00 | El CLI no encuentra el motor que está corriendo | 🩺 | 🟡 | 30 min | ⬜ |
| [27](#-incidente-27--en-el-portátil-de-la-empresa-no-baja-ninguna-imagen) | 00 | En el portátil de la empresa no baja ninguna imagen | 🩺 | 🟡 | 45 min | ⬜ |
| [05](#-incidente-05--el-pod-espera-una-imagen-que-el-cluster-nunca-vio) | 08 | El pod espera una imagen que el cluster nunca vio | ☸️ | 🟢 | 20 min | ⬜ |
| [06](#-incidente-06--el-service-existe-y-nadie-le-contesta) | 08 | El `Service` existe y nadie le contesta | ☸️ | 🟢 | 20 min | ⬜ |
| [07](#-incidente-07--inventory-no-encuentra-a-catalog-que-está-ahí) | 09 | `inventory` no encuentra a `catalog`, que está ahí | ☸️ | 🟡 | 30 min | ⬜ |
| [08](#-incidente-08--el-navegador-recibe-404-y-ningún-pod-se-entera) | 10 | El navegador recibe 404 y ningún pod se entera | ☸️ | 🟡 | 30 min | ⬜ |
| [09](#-incidente-09--cambié-la-configuración-y-el-servicio-sigue-igual) | 11 | Cambié la configuración y el servicio sigue igual | ☸️ | 🟢 | 20 min | ⬜ |
| [10](#-incidente-10--el-pod-no-llega-ni-a-arrancar) | 11 | El pod no llega ni a arrancar | ☸️ | 🟢 | 20 min | ⬜ |
| [11](#-incidente-11--postgres-se-queda-esperando-para-siempre) | 12 | Postgres se queda esperando para siempre | ☸️ | 🟡 | 30 min | ⬜ |
| [12](#-incidente-12--inventory-muere-sin-decir-nada) | 15 | `inventory` muere sin decir nada | ☸️ | 🟠 | 40 min | ⬜ |
| [13](#-incidente-13--el-servicio-corre-y-nunca-recibe-tráfico) | 15 | El servicio corre y nunca recibe tráfico | ☸️ | 🟡 | 30 min | ⬜ |
| [14](#-incidente-14--kubernetes-reinicia-un-pod-que-estaba-bien) | 15 | Kubernetes reinicia un pod que estaba bien | ☸️ | 🟠 | 40 min | ⬜ |
| [15](#-incidente-15--la-réplica-nueva-no-encuentra-dónde-vivir) | 15 | La réplica nueva no encuentra dónde vivir | ☸️ | 🟡 | 30 min | ⬜ |
| [16](#-incidente-16--el-despliegue-se-quedó-a-la-mitad) | 16 | El despliegue se quedó a la mitad | ☸️ | 🟠 | 40 min | ⬜ |
| [17](#-incidente-17--el-autoescalador-no-ve-nada) | 16 | El autoescalador no ve nada | ☸️ | 🟡 | 30 min | ⬜ |
| [18](#-incidente-18--ayer-funcionaba-y-hoy-el-navegador-no-entra) | 19 | Ayer funcionaba y hoy el navegador no entra | 🔐 | 🟢 | 20 min | ⬜ |
| [19](#-incidente-19--el-cliente-no-confía-en-quien-firmó) | 19 | El cliente no confía en quien firmó | 🔐 | 🟡 | 30 min | ⬜ |
| [20](#-incidente-20--el-certificado-es-válido-pero-no-para-este-nombre) | 19 | El certificado es válido, pero no para este nombre | 🔐 | 🟡 | 30 min | ⬜ |
| [21](#-incidente-21--el-gateway-rechaza-su-propio-certificado) | 19 | El `Gateway` rechaza su propio certificado | 🔐 | 🟢 | 20 min | ⬜ |
| [22](#-incidente-22--cert-manager-no-emite-nada) | 19 | cert-manager no emite nada | 🔐 | 🟠 | 40 min | ⬜ |
| [23](#-incidente-23--pricing-rechaza-a-inventory-con-mtls) | 19 | `pricing` rechaza a `inventory` con mTLS | 🔐 | 🟠 | 40 min | ⬜ |
| [24](#-incidente-24--el-cluster-no-puede-traer-imágenes-del-registry-propio) | 19 | El cluster no puede traer imágenes del registry propio | 🔐 | 🔴 | 60 min | ⬜ |
| [25](#-incidente-25--endurecí-el-pod-y-dejó-de-arrancar) | 20 | Endurecí el pod y dejó de arrancar | ☸️ | 🟡 | 30 min | ⬜ |
| [26](#-incidente-26--cerré-la-red-y-se-rompió-todo-hasta-lo-permitido) | 20 | Cerré la red y se rompió todo, hasta lo permitido | ☸️ | 🔴 | 60 min | ⬜ |

Los 27 están completos desde la [Fase 21](21-diagnostico.md), que revisó el cuaderno entero con el método. Las familias son tres: 🩺 ambiente, ☸️ plataforma y 🔐 certificados. Los IDs son
globales y no se reasignan nunca, aunque un incidente se retire, y por eso no siguen siempre el
orden de las fases.

---

## 🧪 Incidentes

### 🩺 Incidente 01 — Instalé todo y WSL no arranca

> **Fase:** 00 · **Familia:** 🩺 · **Dificultad:** 🟢 · **Tiempo sugerido:** 20 min
> **Perfil:** — (no hay cluster todavía) · **Motor de referencia:** Docker Desktop o Podman sobre WSL 2
> **Verificado el:** no verificado por el autor; se confirma al hacer el curso · Windows 11

**El encargo.** Valentina, desde el equipo de plataforma: *"Instalé Docker Desktop en el portátil
nuevo de Paracelso, reinicié como pidió, y no arranca: dice algo de WSL. Mañana llegan los otros dos
portátiles y no quiero repetir esto tres veces sin entender qué pasó."*

**Cómo llegar.** Este incidente no se provoca: se reconoce. Aparece en una máquina con Windows 11
donde las características de Windows que usa WSL 2 no quedaron activas, o quedaron a medias.

**Lo que vas a ver.**

```text
There is no distribution with the supplied name.
Error code: Wsl/Service/WSL_E_DISTRO_NOT_FOUND

The operation could not be started because a required feature is not installed.
Error code: Wsl/InstallDistro/Service/RegisterDistro/CreateVm/HCS/HCS_E_SERVICE_NOT_AVAILABLE
```

<details><summary>💡 Pista 1 — dónde mirar</summary>No en Docker Desktop ni en Podman: los dos están bien. El mensaje viene de WSL, que es quien les presta la máquina virtual.</details>
<details><summary>💡 Pista 2 — qué comparar</summary>Lo que crees que está activo contra lo que Windows dice que está activo. Hay un comando que te da el estado real de cada característica, y "activada" no siempre es uno de los valores.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>Son dos características: `Microsoft-Windows-Subsystem-Linux` y `VirtualMachinePlatform`. Mira su `State`.</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** El código de error dice `HCS`: el servicio que crea máquinas
virtuales en Windows no está disponible. Antes de reinstalar nada, comprueba el estado de las dos
características de las que depende WSL 2.

**Primer comando.** En una PowerShell de administrador:
`Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform | Select-Object FeatureName, State`,
y lo mismo con `Microsoft-Windows-Subsystem-Linux`. La línea que importa es `State`: cualquier cosa
distinta de `Enabled` es la causa.

**Causa.** Una de las dos características no quedó activada: el instalador la pidió y faltó el
reinicio (`EnablePending`), o la activación falló, o los archivos ni siquiera están en el disco
(`DisabledWithPayloadRemoved`).

**Corrección.** `dism.exe /online /enable-feature /featurename:<la que falte> /all /norestart` por
cada una, reiniciar, y `wsl --update`. Si `dism` parece colgado, mira [a02](a02-problemas-del-ambiente.md#dism-parece-colgado-en-un-porcentaje-bajo).

**Prevención.** Comprobar el `State` de las dos características **antes** de instalar los motores, y
no dar por hecho que "el instalador lo activó". Es el primer paso de la [Fase 00](00-el-ambiente.md) en Windows.

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 02 — La máquina dice que no puede virtualizar

> **Fase:** 00 · **Familia:** 🩺 · **Dificultad:** 🟢 · **Tiempo sugerido:** 20 min
> **Perfil:** — · **Motor de referencia:** cualquiera, sobre WSL 2
> **Verificado el:** no verificado por el autor; se confirma al hacer el curso · Windows 11

**El encargo.** Valentina: *"El portátil que le entregaron a Andrés para La Rebotica no arranca
ninguna máquina virtual, ni la de Docker ni la de Podman. Mesa de ayuda dice que el equipo está bien.
Es el mismo modelo que el mío, y el mío sí arranca."*

**Cómo llegar.** No se provoca: romper la virtualización de tu máquina no es un ejercicio. Aparece en
equipos donde la virtualización está apagada en el firmware, a veces por política corporativa.

**Lo que vas a ver.**

```text
Error: 0x80370102 No se pudo iniciar la máquina virtual porque no se instaló una característica necesaria.
```

Y en el Administrador de tareas, pestaña **Rendimiento**, **CPU**: `Virtualización: Deshabilitado`.

<details><summary>💡 Pista 1 — dónde mirar</summary>Fuera de Windows. Hay una pantalla antes de Windows que decide si el procesador puede virtualizar.</details>
<details><summary>💡 Pista 2 — qué comparar</summary>El Administrador de tareas de tu portátil contra el de uno que funciona: una línea de la vista de CPU es distinta.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>Intel VT-x, AMD-V o SVM, según el procesador. Y si eso está bien, el arranque del hipervisor.</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** El Administrador de tareas responde en un clic si la
virtualización está habilitada. Si dice `Deshabilitado`, ninguna configuración de Windows lo
arregla.

**Primer comando.** Ninguno en la terminal: Administrador de tareas → Rendimiento → CPU →
`Virtualización`. Si dice `Habilitado`, el segundo: `bcdedit /enum | findstr -i hypervisorlaunchtype`.

**Causa.** La virtualización del procesador está apagada en el firmware (BIOS/UEFI), o el hipervisor
de Windows no arranca (`hypervisorlaunchtype Off`).

**Corrección.** Encender Intel VT-x o AMD-V/SVM en el firmware; en un portátil corporativo, eso lo
hace mesa de ayuda, a veces con la contraseña del firmware. Si era el hipervisor: `bcdedit /set
hypervisorlaunchtype Auto` y reiniciar.

**Prevención.** Pedir el portátil con la virtualización habilitada, por escrito, cuando se solicita.
Es una línea en el formato de solicitud de equipos de la empresa, y ahorra una tarde.

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 03 — La máquina de Podman no levanta

> **Fase:** 00 · **Familia:** 🩺 · **Dificultad:** 🟡 · **Tiempo sugerido:** 30 min
> **Perfil:** — · **Motor de referencia:** Podman 🦭
> **Verificado el:** 03/10/2026 · macOS arm64 · en Windows con WSL: no verificado por el autor

**El encargo.** Valentina: *"Instalé Podman y Podman Desktop en el Mac del equipo de la Braqui para
probar La Rebotica con los dos motores. `podman --version` contesta, pero cualquier otra cosa dice
que no puede conectar. Los de la Braqui ya me miran raro."*

**Cómo llegar.** A mano: con Podman instalado, pide arrancar una máquina que no existe, o detén la
tuya y corre cualquier comando.

```bash
podman machine start rebotica
podman machine stop && podman ps
```

**Lo que vas a ver.**

```text
$ podman machine start rebotica
Error: rebotica: VM does not exist
$ podman ps
Cannot connect to Podman. Please verify your connection to the Linux system using `podman system connection list`, or try `podman machine init` and `podman machine start` to manage a new Linux VM
Error: unable to connect to Podman socket: failed to connect: dial tcp 127.0.0.1:61482: connect: connection refused
```

<details><summary>💡 Pista 1 — dónde mirar</summary>`podman --version` funciona porque no necesita a nadie: es el cliente. En macOS y Windows, los contenedores corren en otra parte.</details>
<details><summary>💡 Pista 2 — qué comparar</summary>Lo que el cliente cree que existe contra lo que existe: hay un comando que lista las máquinas y su estado.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>`podman machine list`. Si no hay ninguna, falta un paso de la instalación; si hay una detenida, falta otro.</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** En macOS y Windows, Podman es un cliente que habla con una
máquina virtual Linux. "No puede conectar" casi siempre es "no hay máquina" o "la máquina no está
corriendo". `task engine:status` te dice las dos cosas.

**Primer comando.** `podman machine list`. Si la lista está vacía, la máquina nunca se creó; si
aparece sin `Currently running`, está detenida.

**Causa.** El instalador de Podman no crea la máquina: hay que crearla (`podman machine init`) y
arrancarla (`podman machine start`). Podman Desktop lo ofrece en su asistente, y es fácil cerrarlo
antes de terminar.

**Corrección.** `podman machine init --memory 4096` (la memoria que pide [a01](a01-el-laboratorio.md#-la-memoria-que-ocupa-cada-perfil);
la de serie, 2 GiB, no alcanza) y `podman machine start`, o `task engine:use -- podman`, que la arranca.

**Prevención.** `task engine:status` como primera línea de cualquier diagnóstico: distingue "no
instalado", "no responde" y la máquina detenida. En Windows con WSL, la máquina de Podman es una
distribución más; si WSL no funciona, es el [incidente 01](#-incidente-01--instalé-todo-y-wsl-no-arranca).

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 04 — El CLI no encuentra el motor que está corriendo

> **Fase:** 00 · **Familia:** 🩺 · **Dificultad:** 🟡 · **Tiempo sugerido:** 30 min
> **Perfil:** — · **Motor de referencia:** Docker · 🦭 con Podman el mensaje cambia (incidente 03)
> **Verificado el:** 03/10/2026 · macOS arm64 · Windows 11 y Linux: no verificados por el autor

**El encargo.** Valentina: *"Docker Desktop tiene el ícono en la barra, juraría que está prendido, y
`docker ps` me dice que no encuentra nada. kind tampoco crea el cluster. ¿Qué es lo que no está
corriendo?"*

**Cómo llegar.** A mano: detén Docker Desktop (`docker desktop stop`) y corre cualquier comando de
Docker o de kind. En Linux, con Docker Engine, el otro camino es un usuario que no puede abrir el
socket.

**Lo que vas a ver.**

```text
$ docker ps
failed to connect to the docker API at unix:///Users/oskar/.docker/run/docker.sock; check if the path is correct and if the daemon is running: dial unix /Users/oskar/.docker/run/docker.sock: connect: no such file or directory
$ task engine:status
Motor activo del laboratorio: docker  (.engine.env)
  ❌ docker no responde
El motor activo (docker) no responde. Arráncalo con: task engine:use -- docker
```

<details><summary>💡 Pista 1 — dónde mirar</summary>El mensaje te dice exactamente a qué dirección intentó conectar el cliente. Esa dirección es un archivo.</details>
<details><summary>💡 Pista 2 — qué comparar</summary>La dirección del mensaje contra la que existe de verdad. `no such file or directory` y `permission denied` son dos incidentes distintos con el mismo síntoma de fondo.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>¿El motor responde, o solo su ícono está ahí? Y si responde, ¿a qué contexto está apuntando el cliente?</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** El cliente `docker` no corre contenedores: le habla a un motor por
un socket. El error dice qué socket buscó y qué pasó: `no such file or directory` es "nadie lo
creó", o sea, el motor no está corriendo; `permission denied` es "existe y no te dejan entrar".

**Primer comando.** `task engine:status`, que pregunta a cada motor si responde. Después,
`docker context ls`: la línea con `*` es el socket al que apunta tu cliente.

**Causa.** Una de tres: el motor no está corriendo aunque su ícono sí; el cliente apunta a un
contexto que no es el del motor encendido (con dos motores es fácil); o, en Linux, tu usuario no
puede abrir el socket ([a02](a02-problemas-del-ambiente.md#permission-denied-en-varrundockersock)).

**Corrección.** `task engine:use -- docker`, que lo arranca si no responde y espera a que conteste.
Si el contexto es el problema, `docker context use desktop-linux`.

**Prevención.** No preguntarle a la interfaz si el motor está vivo, sino al motor: `task
engine:status` pregunta `docker info`. Y no exportar `DOCKER_HOST` a mano al alternar motores: el
laboratorio no lo necesita, y una variable olvidada es la causa más larga de diagnosticar.

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 05 — El pod espera una imagen que el cluster nunca vio

> **Fase:** 08 · **Familia:** ☸️ · **Dificultad:** 🟢 · **Tiempo sugerido:** 20 min
> **Perfil:** `minimo` · **Motor de referencia:** Docker · 🦭 con Podman, la imagen local se llama distinto (Fase 05), y el síntoma es el mismo
> **Verificado el:** 03/10/2026 · macOS arm64

**El encargo.** Valentina, el martes de la circular: *"Construí `pricing` con el precio nuevo, le
cambié el tag en el `Deployment`, apliqué, y `kubectl` dijo `image updated`. Media hora después, las
cajas siguen con el precio viejo y en el cluster hay un pod que no arranca. Nadie me avisó de nada."*

**Cómo llegar.** `git switch --detach inc/05/image-never-loaded-roto` · o `task inc:break -- 05` · o, a
mano: `kubectl set image deployment/pricing pricing=lab/pricing:recien-construida` sin cargar esa
imagen en el nodo.

**Lo que vas a ver.**

```text
$ kubectl get pods -l app.kubernetes.io/name=pricing
NAME                       READY   STATUS             RESTARTS   AGE
pricing-7847d89564-qx42h   1/1     Running            0          53s
pricing-7bf5c97d4-lbf64    0/1     ImagePullBackOff   0          25s
$ kubectl get deploy pricing
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
pricing   1/1     1            1           2m6s
```

<details><summary>💡 Pista 1 — dónde mirar</summary>Hay dos pods y un solo <code>Deployment</code>. El que no arranca dice qué le pasa en sus eventos.</details>
<details><summary>💡 Pista 2 — qué comparar</summary>La imagen que pide el pod nuevo contra las imágenes que tiene el nodo (<code>crictl images</code> dentro del nodo).</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>El nodo no ve las imágenes de tu motor. ¿Cómo llegaron las otras?</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** `STATUS` dice `ImagePullBackOff`: el problema es la imagen, no el
código. Y `READY 1/1` en el `Deployment` dice que el servicio sigue contestando con el pod viejo:
nada se cayó, pero nada cambió.

**Primer comando.** `kubectl describe pod pricing-7bf5c97d4-lbf64`, de abajo hacia arriba. La línea
que importa:

```text
Warning  Failed  …  kubelet  spec.containers{pricing}: Failed to pull image "lab/pricing:g0": failed to pull and unpack image "docker.io/lab/pricing:g0": failed to resolve reference "docker.io/lab/pricing:g0": pull access denied, repository does not exist or may require authorization: server message: insufficient_scope: authorization failed
```

(Esa salida es de la primera vez que se vio, en la [Fase 08](08-el-primer-despliegue.md), con otro tag; con
`lab/pricing:recien-construida` dice lo mismo con ese nombre.)

**Causa.** El `kubelet` no encontró la imagen en el nodo, así que la fue a buscar a Docker Hub
(`docker.io/lab/…` es el nombre completo de `lab/…`), donde no existe. El nodo de kind tiene su propio
almacén de imágenes; lo que construyes con tu motor no llega solo.

**Corrección.** Cargar la imagen en el nodo y dejar que el `Deployment` termine el rollout:

```bash
kind load docker-image lab/pricing:recien-construida --name minimo   # o task images:load -- minimo
```

Con `task inc:fix -- 05`, el laboratorio vuelve al manifiesto del repositorio.

**Prevención.** Un tag nuevo sin `task images:load` (o sin publicarlo en un registry, [Fase 19](19-tls-y-certificados.md)) es un
rollout que no termina. El hábito: construir, cargar y aplicar, siempre los tres, y mirar `kubectl
rollout status` en vez de creerle a `image updated`.

**En la nube** 🌩️ El nodo descarga del registry del proveedor; el síntoma es el mismo cuando la imagen
no se publicó o el nodo no tiene permiso para leerla.

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 06 — El `Service` existe y nadie le contesta

> **Fase:** 08 · **Familia:** ☸️ · **Dificultad:** 🟢 · **Tiempo sugerido:** 20 min
> **Perfil:** `minimo` · **Motor de referencia:** Docker
> **Verificado el:** 03/10/2026 · macOS arm64

**El encargo.** Valentina: *"El pod de `pricing` está `Running`, el `Service` existe, y desde otro pod
`curl` me dice que no puede conectar. Lo único que hice fue ordenar las labels del `Service` para que
quedaran como las del `Deployment`."*

**Cómo llegar.** `git switch --detach inc/06/service-no-endpoints-roto` · o `task inc:break -- 06` · o,
a mano: agregar `app.kubernetes.io/component: api` al `selector` del `Service` de `pricing`.

**Lo que vas a ver.**

```text
$ kubectl run cliente --rm --attach --restart=Never --quiet --image=nginxinc/nginx-unprivileged@sha256:ed04ec1ff34502c339ee5c3ae3f855442398edc1d05591e2b98981dcbbd20b1e -- curl -sS -m 5 'http://pricing:8080/health/live'
curl: (7) Failed to connect to pricing:8080 after 4 ms: Could not connect to server
```

<details><summary>💡 Pista 1 — dónde mirar</summary>El nombre resolvió (no dice <em>Could not resolve host</em>). La conexión se rechazó en 4 ms. ¿Hay alguien detrás del <code>Service</code>?</details>
<details><summary>💡 Pista 2 — qué comparar</summary>El selector del <code>Service</code> contra las labels del pod.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary><code>kubectl get endpointslices -l kubernetes.io/service-name=pricing</code>.</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** El pod funciona y el nombre resuelve: el problema está entre los
dos. Un rechazo inmediato (milisegundos, no un timeout) es la firma de un `Service` sin endpoints.

**Primer comando.** `kubectl get endpointslices -l kubernetes.io/service-name=pricing`:

```text
NAME            ADDRESSTYPE   PORTS     ENDPOINTS   AGE
pricing-tslff   IPv4          <unset>   <unset>     98s
$ kubectl describe svc pricing | grep -E "Selector|Endpoints"
Selector:                 app.kubernetes.io/component=api,app.kubernetes.io/name=pricing
Endpoints:
```

**Causa.** El selector exige dos labels, y el pod tiene `component: backend`, no `api`. Ningún pod
cumple las dos, el `EndpointSlice` queda vacío, y `kube-proxy` escribe en el nodo una regla que rechaza
la conexión (`has no endpoints … -j REJECT`, [Fase 08](08-el-primer-despliegue.md)).

**Corrección.** El selector, con una sola label: `app.kubernetes.io/name: pricing`. Ojo: `kubectl
apply` no quita una label que agregó un `patch` (no estaba en la última configuración aplicada), así
que `task inc:fix -- 06` borra el `Service` y lo vuelve a crear desde el repositorio.

**Prevención.** Selectores mínimos, con la label que nunca cambia (contrato §4). Y, después de crear un
`Service`, mirar su `EndpointSlice`: un `Service` sin direcciones es la señal antes de que alguien
pruebe.

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 07 — `inventory` no encuentra a `catalog`, que está ahí

> **Fase:** 09 · **Familia:** ☸️ · **Dificultad:** 🟡 · **Tiempo sugerido:** 30 min
> **Perfil:** `minimo` · **Motor de referencia:** Docker
> **Verificado el:** 03/10/2026 · macOS arm64

**El encargo.** El Núcleo, por chat: *"Desplegamos `inventory` con nuestro manifiesto de siempre y
probamos que viera a `catalog` con `getent`, porque en la [Fase 16](16-escalado-y-rollout.md) lo va a llamar. No lo encuentra. Pero
`kubectl get svc -A` muestra `catalog` ahí, vivito."*

**Cómo llegar.** `git switch --detach inc/07/short-name-wrong-namespace-roto` · o `task inc:break -- 07`
· o, a mano: aplicar una copia del `Deployment` de `inventory` **sin** `namespace:` y con
`CATALOG_URL=http://catalog:8080`, sin `-n`.

**Lo que vas a ver.**

```text
$ kubectl get pods -A -l app.kubernetes.io/name=inventory
NAMESPACE   NAME                         READY   STATUS    RESTARTS   AGE
apps        inventory-5f4f7fb8c5-lvnhg   1/1     Running   0          33s
default     inventory-fb9886948-5c64s    1/1     Running   0          1s
$ kubectl -n default exec deploy/inventory -- getent hosts catalog
command terminated with exit code 2
```

<details><summary>💡 Pista 1 — dónde mirar</summary>Hay dos <code>inventory</code>. ¿Desde cuál preguntaste?</details>
<details><summary>💡 Pista 2 — qué comparar</summary>El <code>/etc/resolv.conf</code> de un pod de <code>default</code> contra el de uno de <code>apps</code>: la línea <code>search</code>.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>Prueba el nombre con el namespace: <code>catalog.apps</code>.</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** `getent hosts` sin salida y con código 2 es "el nombre no existe",
no "no contesta". Y el nombre existe en el cluster, así que la pregunta es **desde dónde** se busca.

**Primer comando.** `kubectl get pods -A -l app.kubernetes.io/name=inventory`: el `inventory` que
probaste está en `default`, no en `apps`. Desde ahí:

```text
$ kubectl -n default exec deploy/inventory -- getent hosts catalog.apps.svc.cluster.local
10.96.244.161   catalog.apps.svc.cluster.local
```

**Causa.** El manifiesto no traía `namespace:`, se aplicó sin `-n`, y cayó en el namespace del
contexto: `default`. El nombre corto `catalog` se completa con el namespace del pod que pregunta
(`catalog.default.svc.cluster.local`), y ahí no hay ningún `catalog`.

**Corrección.** Borrar el `inventory` de `default` (`task inc:fix -- 07`) y, si hacía falta un
`inventory` ahí, que use el nombre completo.

**Prevención.** `namespace:` en todos los manifiestos (los del curso lo llevan desde la [Fase 09](09-los-cuatro-servicios-dentro.md)), y
las URL de los vecinos con el nombre completo, como el `ConfigMap` `neighbors`: resuelven desde
cualquier namespace.

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 08 — El navegador recibe 404 y ningún pod se entera

> **Fase:** 10 · **Familia:** ☸️ · **Dificultad:** 🟡 · **Tiempo sugerido:** 30 min
> **Perfil:** `minimo` · **Motor de referencia:** Docker
> **Verificado el:** 03/10/2026 · macOS arm64

**El encargo.** Daniela, desde el portal: *"Las cajas de prueba dejaron de ver precios hace un rato.
Nadie desplegó `pricing`; el equipo de precios solo 'ordenó' su ruta, dice que quitó una línea que
sobraba. El pod está bien, ya lo miramos."*

**Cómo llegar.** `git switch --detach inc/08/route-wrong-parent-roto` · o `task inc:break -- 08` · o,
a mano: quitar el `namespace: gateway` del `parentRefs` de la `HTTPRoute` de `pricing` y aplicarla.

**Lo que vas a ver.**

```text
$ curl -sS -i 'http://api.localhost:8080/pricing/prices/SKU-0003?store=DRO-007' | head -3
HTTP/1.1 404 Not Found
date: Sun, 04 Oct 2026 02:05:52 GMT
content-length: 0
$ kubectl -n apps get pods -l app.kubernetes.io/name=pricing
NAME                      READY   STATUS    RESTARTS   AGE
pricing-99859bc4c-ckvkm   1/1     Running   0          18m
$ kubectl -n apps logs deploy/pricing --tail=2
2026/10/04 02:05:33 PUT /prices/SKU-0003 200
2026/10/04 02:05:33 GET /prices/SKU-0003 200
$ kubectl -n apps get httproute pricing -o jsonpath='{range .status.parents[*]}{.parentRef.name} {.parentRef.namespace}{"\n"}{range .conditions[*]}{.type}={.status} {.reason}: {.message}{"\n"}{end}{end}'
lab gateway
Accepted=True Accepted: Route is accepted
ResolvedRefs=True ResolvedRefs: Resolved all the Object references for the Route
```

<details><summary>💡 Pista 1 — dónde mirar</summary>El 404 no tiene cuerpo y el log de <code>pricing</code> no tiene la petición. ¿Quién contestó?</details>
<details><summary>💡 Pista 2 — qué comparar</summary>El <code>parentRefs</code> de la ruta en el <code>spec</code> contra el <code>parentRef</code> del <code>status</code>. Y <code>metadata.generation</code> contra <code>observedGeneration</code>.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>Un <code>parentRef</code> sin <code>namespace</code> busca la puerta en el namespace de la ruta.</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** Un 404 con `content-length: 0` y sin línea en el log del servicio
es de la puerta: la petición nunca llegó a `pricing`. Mirar el pod es mirar el sitio equivocado.

**Primer comando.** El `spec` y el `status` de la ruta, con sus generaciones:

```text
generation=4 parentRef={"group":"gateway.networking.k8s.io","kind":"Gateway","name":"lab"} status.parentRef=lab/gateway observedGeneration=3
$ kubectl -n apps get gateway
No resources found in apps namespace.
```

El `spec` apunta a una puerta `lab` **en `apps`**, que no existe. El `status` todavía habla de la de
`gateway`, y es de la generación anterior: es un `status` viejo, no una respuesta. El controlador
escribe en el `status` de las rutas que se cuelgan de **sus** puertas; esta ya no se cuelga de
ninguna, y nadie actualiza lo que quedó escrito.

**Causa.** Sin `namespace`, el `parentRef` se resuelve en el namespace de la ruta. La línea "que
sobraba" era la que cruzaba de `apps` a `gateway`.

**Corrección.** Devolver el `namespace: gateway` (`task inc:fix -- 08`). Tres segundos después,
`pricing` vuelve a contestar y `generation` y `observedGeneration` coinciden (`5` y `5`).

**Prevención.** Leer el `status` de un objeto **con su `observedGeneration`**: si es menor que
`metadata.generation`, el `status` describe una versión anterior. Y una prueba de humo por la puerta
—no al pod— después de cada cambio de ruta, como la suite de conformidad con `TARGET=cluster`.

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 09 — Cambié la configuración y el servicio sigue igual

> **Fase:** 11 · **Familia:** ☸️ · **Dificultad:** 🟢 · **Tiempo sugerido:** 20 min
> **Perfil:** `minimo` · **Motor de referencia:** Docker
> **Verificado el:** 03/10/2026 · macOS arm64

**El encargo.** Yolanda, desde Girón, por el chat de las regentes: *"Salió la circular el martes y el
salbutamol bajó a 18.000. Aquí la caja me lo sigue cobrando a 20.000. Sistemas dice que ya lo
cambiaron. ¿Cobro lo que dice la caja o lo que dice la circular?"*

**Cómo llegar.** `git switch --detach inc/09/configmap-not-reloaded-roto` · o `task inc:break -- 09` ·
o, a mano: aplicar `deploy/incidents/09-circular-de-precios.yaml`, que cambia el `ConfigMap` de los
topes, y nada más.

**Lo que vas a ver.**

```text
$ kubectl -n apps get configmap pricing-regulated-caps -o jsonpath='{.data.regulated-caps\.csv}'
SKU-0003,18000
$ curl -sS 'http://api.localhost:8080/pricing/prices/SKU-0003?store=DRO-007'
{"sku":"SKU-0003","store":"DRO-007","price":20000,"currency":"COP","regulatedCap":20000,"capped":true}
```

<details><summary>💡 Pista 1 — dónde mirar</summary>Tres sitios dicen el tope: el objeto, el archivo dentro del pod y la respuesta. ¿Cuál de los tres está atrasado?</details>
<details><summary>💡 Pista 2 — qué comparar</summary>La hora del log de arranque de <code>pricing</code> contra la hora del cambio del <code>ConfigMap</code>.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>¿Cuándo lee <code>pricing</code> su tabla?</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** El objeto ya dice 18.000, así que nadie se equivocó al cambiarlo.
La pregunta es quién no se enteró.

**Primer comando.** El archivo que ve un pod que monta el mismo `ConfigMap` (un pod testigo: `pricing`
no tiene shell), y el log de arranque de `pricing`:

```text
t=90s archivo montado: SKU-0003,18000 · pricing: {…"price":20000,…"regulatedCap":20000,"capped":true}
$ kubectl -n apps logs deploy/pricing | grep -i tope
2026/10/04 02:27:13 tope regulado encendido: 1 productos con tope
```

El archivo ya cambió (entre los 60 y los 90 segundos, en la verificación); `pricing` cargó su tabla a
las 02:27, mucho antes de la circular, y no la vuelve a leer.

**Causa.** Cambiar un `ConfigMap` no reinicia nada. El kubelet actualiza el archivo montado, y el
proceso, que lo leyó al arrancar, sigue con lo que tiene en memoria.

**Corrección.** `task inc:fix -- 09` (`kubectl -n apps rollout restart deployment/pricing`). Y cargar
de nuevo los precios: el reinicio se llevó el SQLite del `emptyDir`
(`{"error":"not_found","message":"sin precio para SKU-0003 en DRO-007"}`). Después, `"regulatedCap":18000`.
`task deploy` devuelve la tabla del repositorio.

**Prevención.** Que cada cambio de configuración lleve su reinicio, y que lo haga una herramienta, no
una persona: el hash del `ConfigMap` en la plantilla del pod ([Fase 13](13-helm-el-paquete.md)).

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 10 — El pod no llega ni a arrancar

> **Fase:** 11 · **Familia:** ☸️ · **Dificultad:** 🟢 · **Tiempo sugerido:** 20 min
> **Perfil:** `minimo` · **Motor de referencia:** Docker
> **Verificado el:** 03/10/2026 · macOS arm64

**El encargo.** Daniela, el lunes temprano: *"El portal no abre. Valentina estrenó portátil el viernes
y levantó el laboratorio de cero. Yo no he tocado nada del portal en meses. Y no hay logs: kubectl me
dice que no hay nada que mostrar."*

**Cómo llegar.** `git switch --detach inc/10/secret-missing-roto` · o `task inc:break -- 10` · o, a
mano: borrar el `Secret` `portal-contingencia` del namespace `legacy`, y el pod del portal.

**Lo que vas a ver.**

```text
$ kubectl -n legacy get pods -l app.kubernetes.io/name=portal
NAME                      READY   STATUS                       RESTARTS   AGE
portal-687b98b68c-lnv6l   0/1     CreateContainerConfigError   0          47s
```

<details><summary>💡 Pista 1 — dónde mirar</summary>Sin contenedor no hay logs. ¿Quién sí escribió algo sobre este pod?</details>
<details><summary>💡 Pista 2 — qué comparar</summary>Lo que el pod nombra en su <code>env</code> contra lo que existe en el namespace.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>Un portátil nuevo, un laboratorio levantado de cero, y una carpeta que no está en git.</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** `CreateContainerConfigError` dice que el contenedor no se pudo
**crear**: el problema está en la configuración que el pod pide, no en el programa. Por eso no hay logs.

**Primer comando.** Los eventos del pod:

```text
$ kubectl -n legacy describe pod -l app.kubernetes.io/name=portal | sed -n '/^Events:/,$p' | tail -1
  Warning  Failed     4s (x5 over 46s)  kubelet            spec.containers{portal}: Error: secret "portal-contingencia" not found
```

**Causa.** El `Secret` se crea desde `.secrets/portal-contingencia.env`, que no se versiona a propósito.
En una máquina nueva no existe hasta que alguien lo escribe, y `task legacy:up TARGET=cluster` avisa
(`⚠️ falta .secrets/portal-contingencia.env`) y sigue.

**Corrección.** Escribir el archivo y crear el `Secret` (`task inc:fix -- 10` lo crea desde el
archivo). No hace falta reiniciar: el kubelet reintenta, y el portal estuvo listo 8 segundos después.

**Prevención.** Que la falta del `Secret` detenga la instalación en vez de avisar y seguir; y saber que
Contingencia también lo lee: siguió `Running` porque sus variables se resolvieron al arrancar, y habría
caído en su próximo reinicio.

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 11 — Postgres se queda esperando para siempre

> **Fase:** 12 · **Familia:** ☸️ · **Dificultad:** 🟡 · **Tiempo sugerido:** 30 min
> **Perfil:** `minimo` · **Motor de referencia:** Docker
> **Verificado el:** 03/10/2026 · macOS arm64

**El encargo.** Andrés, por chat: *"Comercial quiere un Postgres aparte para sus reportes, para no
tocar el del sistema. Copié el manifiesto de la prueba de concepto que hicimos en la nube, le cambié el
nombre y lo apliqué. Hace media hora que dice Pending. No hay logs, no hay errores, no hay nada."*

**Cómo llegar.** `git switch --detach inc/11/pvc-storageclass-missing-roto` · o `task inc:break -- 11`
· o, a mano: aplicar `deploy/incidents/11-postgres-reportes.yaml`, un `StatefulSet` `postgres-reportes`
en `data`.

**Lo que vas a ver.**

```text
$ kubectl -n data get pods,pvc -l app.kubernetes.io/name=postgres-reportes
NAME                      READY   STATUS    RESTARTS   AGE
pod/postgres-reportes-0   0/1     Pending   0          31s

NAME                                             STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/data-postgres-reportes-0   Pending                                      oci-bv         <unset>                 31s
```

<details><summary>💡 Pista 1 — dónde mirar</summary>Un pod en <code>Pending</code> no ha corrido nunca: no tiene logs. ¿Quién decide dónde corre, y qué le falta?</details>
<details><summary>💡 Pista 2 — qué comparar</summary>La columna <code>STORAGECLASS</code> del PVC contra <code>kubectl get storageclass</code>.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>El manifiesto viene de una nube. ¿De cuál es esa clase de disco?</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** `Pending` en el pod y en el PVC a la vez: el pod espera su disco, y
el disco espera a alguien que lo cree. Los eventos del pod solo dicen lo primero:

```text
  Warning  FailedScheduling  30s   default-scheduler  0/1 nodes are available: pod has unbound immediate PersistentVolumeClaims. not found
```

**Primer comando.** Los eventos del PVC, que dicen lo segundo:

```text
$ kubectl -n data describe pvc data-postgres-reportes-0 | sed -n '/^Events:/,$p'
  Warning  ProvisioningFailed  14s (x3 over 31s)  persistentvolume-controller  storageclass.storage.k8s.io "oci-bv" not found
$ kubectl get storageclass
NAME                 PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
standard (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  77m
```

**Causa.** `storageClassName: oci-bv` es la clase de los volúmenes de bloque de OCI. En kind solo existe
`standard`. Nadie puede cumplir el pedido, y nadie da error: el PVC espera, para siempre, a una clase que
quizá alguien instale.

**Corrección.** `task inc:fix -- 11` borra el `StatefulSet` y su PVC. Para que el Postgres de reportes
exista, `storageClassName: standard` (o quitar la línea, y usar la clase por defecto). Y bajar los
`50Gi` de la nube a lo que cabe en el laboratorio. Un PVC ya creado no cambia de clase: se borra y se
crea de nuevo.

**Prevención.** Los manifiestos de un ambiente no son portables a otro sin revisar tres campos: la
`StorageClass`, el tamaño y el modo de acceso. Y ante un `Pending`, mirar el PVC antes que el pod.

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 12 — `inventory` muere sin decir nada

> **Fase:** 15 · **Familia:** ☸️ · **Dificultad:** 🟠 · **Tiempo sugerido:** 40 min
> **Perfil:** `minimo` · **Motor de referencia:** Docker
> **Verificado el:** 04/10/2026 · macOS arm64

**El encargo.** Un desarrollador del Núcleo, en el canal de La Rebotica: *"Le subimos la memoria a la
JVM para aprovechar lo que tiene el contenedor, como hacíamos en el WebLogic, y ahora `inventory` no
arranca. No hay un solo error en el log. Lo único que dice es que leyó las opciones."*

**Cómo llegar.** `git switch --detach inc/12/jvm-pretouch-oomkilled-roto` · o `task inc:break -- 12` · o, a
mano: `kubectl -n apps set env deployment/inventory JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=95
-XX:InitialRAMPercentage=95 -XX:+AlwaysPreTouch"`.

**Lo que vas a ver.**

```text
$ kubectl -n apps get pods -l app.kubernetes.io/name=inventory
NAME                         READY   STATUS             RESTARTS      AGE
inventory-6bb77d9ddc-z8vlf   1/1     Running            0             3m4s
inventory-6c4fdb899d-dzdrc   0/1     CrashLoopBackOff   3 (10s ago)   45s
$ kubectl -n apps logs pod/inventory-6c4fdb899d-dzdrc --previous
Picked up JAVA_TOOL_OPTIONS: -XX:MaxRAMPercentage=95 -XX:InitialRAMPercentage=95 -XX:+AlwaysPreTouch
```

> 📝 Si lo provocas con `task inc:break` después de la [Fase 26](26-idempotencia-y-outbox.md), el pod lleva el *sidecar*
> `outbox-relay`, que sí arranca: verás `1/2` en vez de `0/1`, con el mismo `OOMKilled` en el contenedor `inventory`
> (verificado el 05/10/2026).

<details><summary>💡 Pista 1 — dónde mirar</summary>Si el proceso no escribió nada, alguien lo mató desde afuera. ¿Quién guarda la razón por la que terminó un contenedor?</details>
<details><summary>💡 Pista 2 — qué comparar</summary>El límite de memoria del contenedor contra lo que la JVM pide al arrancar con esas tres opciones.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>¿Qué hace <code>AlwaysPreTouch</code> con el heap inicial, y de qué tamaño es ese heap?</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** El pod viejo sigue atendiendo: el rollout no lo bajó porque el nuevo
nunca estuvo listo. Un log de una línea y `CrashLoopBackOff` es un proceso que murió antes de poder
quejarse; la razón está en el estado del contenedor, no en su log.

**Primer comando.**

```text
$ kubectl -n apps describe pod/inventory-6c4fdb899d-dzdrc | sed -n '/Last State/,/Restart Count/p'
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
      Started:      Sun, 04 Oct 2026 01:13:01 -0500
      Finished:     Sun, 04 Oct 2026 01:13:01 -0500
    Ready:          False
    Restart Count:  3
```

`OOMKilled` y 137 (128 + 9, `SIGKILL`): lo mató el kernel por pasarse del límite del cgroup, en el mismo
segundo en que arrancó. `docker exec minimo-control-plane dmesg | grep -i 'killed process'` lo confirma
desde el nodo.

**Causa.** El límite de `inventory` es 512 MiB. `InitialRAMPercentage=95` le pide a la JVM un heap
inicial del 95 % de eso, unos 486 MiB, y `AlwaysPreTouch` lo **toca entero** al arrancar, página por
página, para no pagar esa latencia después. Más la memoria que no es heap (en la [Fase 15](15-salud-y-recursos.md), unos 200 MiB
en esta aplicación), el proceso pasa el límite antes de cargar Spring. Sin `AlwaysPreTouch`, con el 95 %,
`inventory` aguantó dos minutos de carga en 345 MiB: el heap grande no mata mientras nadie lo use.

**Corrección.** `task inc:fix -- 12`: quitar la variable (`kubectl -n apps set env deployment/inventory
JAVA_TOOL_OPTIONS-`, porque Helm no es dueño de ella) y volver al chart. La JVM, sin opciones, dimensiona
su heap contra el límite: 25 % por defecto.

**Prevención.** Las opciones de memoria de la JVM se eligen **contra el límite del contenedor** y nunca
copiadas de un servidor: el heap y lo que no es heap tienen que caber juntos. Si alguien quiere más heap,
`MaxRAMPercentage` moderado (por debajo de 75) y una prueba de carga mirando la memoria del contenedor,
no la del heap.

**En la nube** 🌩️ Igual: el límite es del contenedor, no del nodo. Lo único que cambia es que el nodo
suele ser más grande, y eso tienta a subir el límite en lugar de entender la cuenta.

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 13 — El servicio corre y nunca recibe tráfico

> **Fase:** 15 · **Familia:** ☸️ · **Dificultad:** 🟡 · **Tiempo sugerido:** 30 min
> **Perfil:** `minimo` · **Motor de referencia:** Docker
> **Verificado el:** 04/10/2026 · macOS arm64

**El encargo.** El equipo de la Braqui: *"Reiniciaron el portátil de La Rebotica y `replenish` quedó
`Running`, pero la lista de órdenes da 500. No hay ningún reinicio, el pod está vivo. Nosotros no
desplegamos nada."*

**Cómo llegar.** `git switch --detach inc/13/stale-db-password-roto` · o `task inc:break -- 13` · o, a
mano: reemplazar el `Secret` `replenish-db` por uno con otra contraseña (`clave-vieja`) y borrar el pod de
`replenish`, como si el nodo se hubiera reiniciado.

**Lo que vas a ver.**

```text
$ kubectl -n apps get pods -l app.kubernetes.io/name=replenish
NAME                       READY   STATUS    RESTARTS   AGE
replenish-7d6bbcf7-nt5db   0/1     Running   0          61s
$ curl -s -w " %{http_code}" http://api.localhost:8080/replenish/replenishment-orders
{"statusCode":500,"message":"Internal server error"} 500
```

<details><summary>💡 Pista 1 — dónde mirar</summary><code>Running</code> con <code>0/1</code>: el proceso vive y alguien dice que no está listo. ¿Quién lo dice, y por qué?</details>
<details><summary>💡 Pista 2 — qué comparar</summary>Lo que pregunta la readiness de <code>replenish</code> (Fase 15) contra lo que recibe el pod en <code>DATABASE_URL</code>.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>El pod nuevo leyó el <code>Secret</code> al crearse. ¿Cuándo cambió el <code>Secret</code>?</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** `0/1` sin reinicios es la readiness diciendo que no, y la liveness
diciendo que sí: el proceso está bien y lo que falla es algo que necesita para atender. Los eventos del
pod dicen qué contesta la sonda; el log, por qué.

**Primer comando.**

```text
$ kubectl -n apps describe pod -l app.kubernetes.io/name=replenish | grep Unhealthy | tail -1
  Warning  Unhealthy  5s (x7 over 35s)   kubelet            spec.containers{replenish}: Readiness probe failed: HTTP probe failed with statuscode: 503
$ kubectl -n apps logs -l app.kubernetes.io/name=replenish,app.kubernetes.io/component=backend | grep WARN | tail -1
[Nest] 1  - 10/04/2026, 6:15:56 AM   WARN [health] no listo: la base no contesta: password authentication failed for user "replenish"
```

**Causa.** El `Secret` `replenish-db` tiene una contraseña que Postgres no acepta. El pod anterior la
había leído antes del cambio y seguía conectado; el nuevo la leyó al crearse. La readiness de G4 hizo su
trabajo: el pod no puede atender y lo dice. Y el 500 que ves por la puerta no es del `Gateway`: con todos
los endpoints sin listo, Envoy entra en modo pánico y le manda el tráfico igual ([Fase 15](15-salud-y-recursos.md)). Por el
`Service`, desde adentro, la conexión se rechaza.

> ⚠️ **`logs deploy/replenish` aquí engaña.** El selector del `Deployment` es solo `app.kubernetes.io/name`, y el pod
> terminado del `Job` de migraciones lo comparte. Con el pod del servicio sin listo, `kubectl` puede elegir el de la
> migración (`Found 2 pods, using pod/replenish-migrate-…`) y mostrarte un log que no tiene nada que ver. Por eso el
> comando filtra por `component=backend`.

**Corrección.** `task inc:fix -- 13`: volver a crear los `Secret` desde `.secrets/postgres.env`
(`python3 scripts/data/credentials.py | kubectl apply -f -`) y borrar el pod, que lee el `Secret` al
crearse.

**Prevención.** Una contraseña se cambia en sus dos puntas a la vez, y las dos salen del mismo archivo
(la [Fase 11](11-configuracion-y-secretos.md), con el portal y Contingencia). Y ante un `0/1`, el log de la readiness antes que
cualquier otra cosa.

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 14 — Kubernetes reinicia un pod que estaba bien

> **Fase:** 15 · **Familia:** ☸️ · **Dificultad:** 🟠 · **Tiempo sugerido:** 40 min
> **Perfil:** `minimo` · **Motor de referencia:** Docker
> **Verificado el:** 04/10/2026 · macOS arm64

**El encargo.** Daniela, después de la prueba de carga de quincena: *"Con cuatrocientas personas
mirando el catálogo, el pod de `catalog` se reinicia solo, una y otra vez. Y cada reinicio es peor: el
99 % de las peticiones fallan. Afinaron las sondas la semana pasada para que detecten antes un cuelgue."*

**Cómo llegar.** `git switch --detach inc/14/liveness-too-strict-roto` · o `task inc:break -- 14` · o, a
mano: la liveness del contenedor `nginx` de `catalog` con `timeoutSeconds: 1` y `failureThreshold: 1`. Y
la carga: `k6 run deploy/incidents/14-carga-catalog.js` (400 usuarios, dos minutos).

**Lo que vas a ver.**

```text
30 s: reinicios nginx=2 php-fpm=0
50 s: reinicios nginx=3 php-fpm=0
81 s: reinicios nginx=4 php-fpm=0
    http_req_failed................: 99.53%  2069108 out of 2078811
```

<details><summary>💡 Pista 1 — dónde mirar</summary>Los eventos del pod dicen qué sonda falló, en qué contenedor, y por qué.</details>
<details><summary>💡 Pista 2 — qué comparar</summary>Qué contenedor se reinicia contra qué contenedor está lento. ¿Son el mismo?</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>¿Cuántas peticiones a la vez atiende PHP-FPM, y dónde espera la sonda cuando están todas ocupadas?</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** Reinicios que crecen con la carga y sin `OOMKilled`: es la liveness.
La pregunta es por qué falla una sonda que no consulta nada.

**Primer comando.**

```text
$ kubectl -n apps describe pod -l app.kubernetes.io/name=catalog | grep -E 'Unhealthy|Killing' | tail -3
  Warning  Unhealthy  43s (x5 over 113s)   kubelet            spec.containers{nginx}: Liveness probe failed: Get "http://10.244.0.108:8080/health/live": context deadline exceeded (Client.Timeout exceeded while awaiting headers)
  Normal   Killing    43s (x5 over 113s)   kubelet            spec.containers{nginx}: Container nginx failed liveness probe, will be restarted
  Warning  Unhealthy  42s (x9 over 4m14s)  kubelet            spec.containers{nginx}: Readiness probe failed: Get "http://10.244.0.108:8080/health/ready": dial tcp 10.244.0.108:8080: connect: connection refused
```

**Causa.** `/health/live` no consulta nada, pero tiene que llegar a Laravel, y para llegar pasa por
nginx y por PHP-FPM, que atiende **cinco peticiones a la vez** (`pm.max_children = 5`). Con 400 usuarios,
la sonda espera en la misma cola que ellos; con un segundo de paciencia y una sola oportunidad, la
primera espera larga reinicia nginx, que era el único proceso sano. Cada reinicio corta todo lo que
estaba en vuelo y le suma carga a la cola. La sonda mide **el tiempo de respuesta bajo carga**, y lo
confunde con un cuelgue.

**Corrección.** `task inc:fix -- 14`, que vuelve a la liveness del chart: dos segundos y tres fallos
seguidos (30 s de paciencia). Con esa liveness y los mismos 400 usuarios, la mediana subió a 1,03 s y no
hubo ni un reinicio ni una petición fallida: el servicio estaba lento, no colgado.

**Prevención.** La liveness tiene que tolerar el peor momento normal del servicio, porque su error se paga
con un reinicio: varios fallos seguidos, tiempo de espera holgado. La capacidad de PHP-FPM es un número
(`pm.max_children`) que se mide y se escala con réplicas ([Fase 16](16-escalado-y-rollout.md)), no con una sonda más nerviosa.

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 15 — La réplica nueva no encuentra dónde vivir

> **Fase:** 15 · **Familia:** ☸️ · **Dificultad:** 🟡 · **Tiempo sugerido:** 30 min
> **Perfil:** `minimo` · **Motor de referencia:** Docker
> **Verificado el:** 04/10/2026 · macOS arm64

**El encargo.** Andrés: *"Le di a Postgres la misma memoria que tiene el servidor de Oracle, para que no
le falte, y se cayó todo: los cuatro servicios dicen 0/1. Postgres ni siquiera arranca, y no hay logs."*

**Cómo llegar.** `git switch --detach inc/15/requests-too-big-roto` · o `task inc:break -- 15` · o, a
mano: en el `StatefulSet` de Postgres, `resources.requests.memory: 4Gi` (y el mismo límite).

**Lo que vas a ver.**

```text
$ kubectl -n data get pods
NAME         READY   STATUS    RESTARTS   AGE
postgres-0   0/1     Pending   0          30s
$ kubectl -n apps get pods -l app.kubernetes.io/component=backend
NAME                        READY   STATUS    RESTARTS      AGE
catalog-5b74cfcf4-mpbhr     1/2     Running   0             5m18s
inventory-84f859ffc-ssrf5   0/1     Running   0             8m59s
pricing-844465cd69-ng4dc    0/1     Running   2 (18m ago)   93m
replenish-7d6bbcf7-6zbr2    0/1     Running   0             6m45s
```

<details><summary>💡 Pista 1 — dónde mirar</summary>Un pod en <code>Pending</code> no ha corrido nunca. ¿Quién decide dónde corre, y qué le respondió?</details>
<details><summary>💡 Pista 2 — qué comparar</summary>Lo que pide el pod contra lo que el nodo puede dar: <code>Allocatable</code> y <code>Allocated resources</code>.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>¿Cuánta memoria tiene la máquina virtual entera del laboratorio?</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** Los cuatro `0/1` son la consecuencia: su readiness pregunta por la
base (G4), y la base no está. El problema es `postgres-0`, que está `Pending`: el planificador no le
encontró sitio.

**Primer comando.**

```text
$ kubectl -n data describe pod postgres-0 | sed -n '/^Events:/,$p' | tail -1
  Warning  FailedScheduling  29s   default-scheduler  0/1 nodes are available: 1 Insufficient memory. no new claims to deallocate, preemption: 0/1 nodes are available: 1 Preemption is not helpful for scheduling.
$ kubectl describe node minimo-control-plane | grep -A1 'memory:' | head -2
  memory:             4010356Ki
```

**Causa.** El nodo tiene 3,8 GiB asignables, y ya hay `requests` por 1,6 GiB. Postgres pide 4 GiB: ningún
nodo los tiene **libres para prometer**, aunque la memoria usada de verdad sea mucho menos. El
planificador reparte promesas (`requests`), no uso.

**Corrección.** `task inc:fix -- 15`: la plantilla del repositorio (`kubectl apply -f
platform/data/postgres/statefulset.yaml`) **y borrar el pod**: un `StatefulSet` no reemplaza solo un pod
que nunca estuvo listo, y con la plantilla buena aplicada, `postgres-0` siguió `Pending` 40 s después.
Los cuatro servicios vuelven solos a `1/1` en cuanto la base contesta.

**Prevención.** Los `requests` se eligen midiendo lo que el proceso usa, no copiando lo que tenía el
servidor. Y en `apps` esto no pasa igual: la cuota del namespace rechaza el pod antes de que exista
(`exceeded quota`), que es un error más temprano y más claro ([Fase 15](15-salud-y-recursos.md)).

**En la nube** 🌩️ Con un autoescalador de nodos, un `Pending` así crea un nodo nuevo, más grande o del
tamaño que se pidió, y la factura lo dice el mes siguiente.

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 16 — El despliegue se quedó a la mitad

> **Fase:** 16 · **Familia:** ☸️ · **Dificultad:** 🟠 · **Tiempo sugerido:** 40 min
> **Perfil:** `lab` · **Motor de referencia:** Docker
> **Verificado el:** 04/10/2026 · macOS arm64

**El encargo.** Un desarrollador del Núcleo, el viernes a las cinco: *"Subí la versión nueva de
`inventory` hace veinte minutos y el pipeline sigue esperando. El servicio contesta, las ventas pasan,
pero `kubectl rollout status` terminó con un error y en el tablero dice que hay una réplica vieja y una
nueva."*

**Cómo llegar.** `git switch --detach inc/16/rollout-progress-deadline-roto` · o `task inc:break -- 16` ·
o, a mano: la versión nueva de `inventory` con una `DATABASE_URL` cuya contraseña no sirve (`kubectl -n apps
set env deployment/inventory DATABASE_URL=postgres://inventory:clave-equivocada@…`).

**Lo que vas a ver.**

```text
$ kubectl -n apps rollout status deployment/inventory
Waiting for deployment "inventory" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment spec update to be observed...
error: deployment "inventory" exceeded its progress deadline
$ kubectl -n apps get deploy inventory
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
inventory   2/2     1            2           167m
```

<details><summary>💡 Pista 1 — dónde mirar</summary><code>READY 2/2</code> y <code>UP-TO-DATE 1</code>: dos pods atienden, y solo uno es de la versión nueva. ¿Cuál de los dos, y en qué estado?</details>
<details><summary>💡 Pista 2 — qué comparar</summary>Las condiciones del <code>Deployment</code> contra el estado del pod nuevo.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>¿Qué le impide al pod nuevo estar listo, y qué dice su readiness?</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** El servicio funciona: con `maxUnavailable: 0`, el rollout no bajó
ninguna réplica vieja mientras la nueva no estuviera lista. El problema es la versión nueva, y el
`Deployment` ya se rindió.

**Primer comando.**

```text
$ kubectl -n apps get pods -l app.kubernetes.io/name=inventory
NAME                         READY   STATUS    RESTARTS   AGE
inventory-68f45cfd75-258db   1/1     Running   0          167m
inventory-68f45cfd75-kllwg   1/1     Running   0          16m
inventory-f8dc4d4dc-lk4hj    0/1     Running   0          16m
$ kubectl -n apps get deploy inventory -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}{"\n"}{end}'
Available=True MinimumReplicasAvailable
Progressing=False ProgressDeadlineExceeded
$ kubectl -n apps logs pod/inventory-f8dc4d4dc-lk4hj | grep 'no listo' | tail -1
… c.c.lab.inventory.HealthController       : no listo: la base no contesta: FATAL: password authentication failed for user "inventory"
```

**Causa.** La versión nueva arranca, pero su readiness (G4) nunca dice que sí: no puede entrar a su base.
El rollout espera a que la réplica nueva esté lista para bajar una vieja, y al pasar
`progressDeadlineSeconds` (120 s en el chart) marca `ProgressDeadlineExceeded` y `rollout status` sale con
error. **El `Deployment` no vuelve atrás solo**: se queda así, mitad y mitad, hasta que alguien decida. En la
verificación, además, la condición apareció a los 16 minutos y no a los 2: el controlador tardó en
reevaluar el plazo, y no se encontró por qué. No cuentes con que el plazo se cumple al segundo.

**Corrección.** `task inc:fix -- 16`: quitar la variable que se puso a mano y volver al chart (`task deploy
FORCE=true -- lab`). O, sin saber todavía la causa, `kubectl -n apps rollout undo deployment/inventory`,
que vuelve a la versión anterior.

**Prevención.** Un rollout que no puede terminar tiene que fallar ruidoso: `progressDeadlineSeconds`, un
`rollout status` en el pipeline, y con Helm, `--wait` y `--rollback-on-failure` ([Fase 14](14-helm-en-operacion.md)), que vuelven solos
a la última revisión buena. Y `maxUnavailable: 0`, que es lo que hizo que esto fuera un incidente y no una
caída.

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 17 — El autoescalador no ve nada

> **Fase:** 16 · **Familia:** ☸️ · **Dificultad:** 🟡 · **Tiempo sugerido:** 30 min
> **Perfil:** `lab` · **Motor de referencia:** Docker
> **Verificado el:** 04/10/2026 · macOS arm64

**El encargo.** Valentina, preparando la prueba de quincena: *"Instalé metrics-server con el manifiesto
oficial, el de la página del proyecto, y le encendí el autoescalado a `pricing`. El HPA dice `<unknown>`
y no escala nunca. `kubectl top` tampoco funciona."*

**Cómo llegar.** `git switch --detach inc/17/metrics-server-kubelet-tls-roto` · o `task inc:break -- 17` ·
o, a mano: `kubectl apply -f platform/metrics-server/components.yaml` sin el `patch` que hace `task
platform:metrics`, y `pricing.autoscaling.enabled=true`.

**Lo que vas a ver.**

```text
$ kubectl -n apps get hpa
NAME      REFERENCE            TARGETS              MINPODS   MAXPODS   REPLICAS   AGE
pricing   Deployment/pricing   cpu: <unknown>/70%   1         4         1          90s
$ kubectl top pods -n apps
error: Metrics API not available
```

<details><summary>💡 Pista 1 — dónde mirar</summary>El HPA no mide nada: le pregunta a la API de métricas. ¿Quién la sirve, y está listo?</details>
<details><summary>💡 Pista 2 — qué comparar</summary>El estado del pod de metrics-server y lo que dice su log cuando intenta leer a cada nodo.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>metrics-server le habla al kubelet de cada nodo por HTTPS. ¿Qué certificado presenta el kubelet de kind?</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** `<unknown>` en el HPA y `Metrics API not available` en `top` son el
mismo síntoma: nadie está sirviendo métricas. El HPA está bien; lo que falta está en `kube-system`.

**Primer comando.**

```text
$ kubectl -n kube-system get pods -l k8s-app=metrics-server
NAME                              READY   STATUS    RESTARTS   AGE
metrics-server-5b9cdf74bf-zhkx8   0/1     Running   0          106s
$ kubectl -n kube-system logs deploy/metrics-server | grep -m1 x509
E1004 07:59:07.399227       1 scraper.go:149] "Failed to scrape node" err="Get \"https://192.168.0.7:10250/metrics/resource\": tls: failed to verify certificate: x509: cannot validate certificate for 192.168.0.7 because it doesn't contain any IP SANs" node="lab-control-plane"
```

metrics-server corre, no está listo, y su log dice por qué.

**Causa.** metrics-server lee el consumo de cada nodo del kubelet, por HTTPS y por la IP del nodo. El
kubelet de kind presenta un certificado autofirmado que no incluye esa IP: metrics-server no lo puede
validar y no lee nada. Sin lecturas, la API de métricas no tiene qué servir, y el HPA no puede calcular.

**Corrección.** `task inc:fix -- 17`, que es `task platform:metrics`: el mismo manifiesto y un `patch` que
agrega `--kubelet-insecure-tls` a los argumentos. En 45 s, `kubectl top` contesta y el HPA muestra `cpu:
2%/70%`.

**Prevención.** El flag es del laboratorio: le dice a metrics-server que no verifique un certificado, y
solo es aceptable porque el kubelet de kind es una carpeta dentro de un contenedor de tu portátil. En un
cluster de verdad, la corrección es la contraria: que el kubelet presente un certificado con sus IP, firmado
por la CA del cluster.

**En la nube** 🌩️ Los clusters gestionados traen metrics-server instalado y funcionando, y este incidente no
existe. Si lo instalas tú, el manifiesto oficial funciona sin el flag.

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 18 — Ayer funcionaba y hoy el navegador no entra

> **Fase:** 19 · **Familia:** 🔐 · **Dificultad:** 🟢 · **Tiempo sugerido:** 20 min
> **Perfil:** `lab` · **Motor de referencia:** Docker
> **Verificado el:** 04/10/2026 · macOS arm64

**El encargo.** El vicepresidente comercial, un lunes: *"Desde esta mañana el navegador dice que la página no es
segura. El viernes funcionaba. Nadie tocó nada, me juran."*

**Cómo llegar.** `git switch --detach inc/18/expired-gateway-cert-roto` · o `task inc:break -- 18` (pone a mano un
certificado de dos minutos; el síntoma aparece a los dos minutos) · o, a mano: borrar el `Certificate` `lab-tls` y
poner en el `Secret` un certificado que venza pronto.

**Lo que vas a ver.**

```text
$ curl -sS -o /dev/null --cacert .secrets/tls/ca.crt 'https://api.localhost:8443/pricing/prices?store=DRO-007'
curl: (60) SSL certificate problem: certificate has expired
```

En el navegador, `NET::ERR_CERT_DATE_INVALID`. Y por HTTP, en el 8080, todo sigue andando.

<details><summary>💡 Pista 1 — dónde mirar</summary>El error es del cliente validando al servidor. ¿Cuál de las cuatro preguntas de la cadena de confianza falló?</details>
<details><summary>💡 Pista 2 — qué comparar</summary>La fecha de vencimiento del certificado que sirve la puerta, contra la hora de ahora. Y lo que dice el `Gateway` de su listener.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>¿Quién emitió ese certificado: cert-manager, o alguien a mano?</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** "Ayer funcionaba" y "nadie tocó nada" con un error de fecha es casi siempre
un vencimiento: nadie tocó nada, y ese fue el problema. No mires la red ni los pods: mira el certificado que se
sirve.

**Primer comando.**

```text
$ echo | openssl s_client -connect 127.0.0.1:8443 -servername api.localhost -CAfile .secrets/tls/ca.crt 2>/dev/null | grep -E "Verify return|notAfter"
Verify return code: 10 (certificate has expired)
$ kubectl -n gateway get certificate lab-tls
Error from server (NotFound): certificates.cert-manager.io "lab-tls" not found
```

Vencido, y sin `Certificate`: nadie lo iba a renovar. El listener del `Gateway`, mientras tanto, dice
`Programmed=True` y `ResolvedRefs=True`: validó el certificado cuando lo cargó, cuando todavía valía.

**Causa.** Un certificado puesto a mano en el `Secret` de la puerta, sin un controlador que lo renueve. Venció
estando cargado, y la puerta lo siguió sirviendo.

**Corrección.** `task inc:fix -- 18`, que es `task platform:certs -- lab`: el `Certificate` vuelve, cert-manager ve
que el `Secret` no coincide con su `spec` y emite uno nuevo en un segundo; la puerta lo sirve sin reiniciar.

**Prevención.** Que cada certificado lo emita quien lo renueva (cert-manager), y una alerta sobre la fecha de
vencimiento (`certmanager_certificate_expiration_timestamp_seconds`), porque la puerta no avisa. Y una trampa al
reparar a mano: un certificado **ya** vencido la puerta ni lo carga, y se cae el listener HTTPS entero (la [Fase 19](19-tls-y-certificados.md),
ejercicio 15).

**En la nube** 🌩️ Con una CA pública, el mismo síntoma lo ven todos los clientes de internet a la vez. cert-manager
con ACME, o el servicio de certificados del proveedor, renuevan solos; el incidente aparece cuando la renovación
falla en silencio (un DNS que cambió, un desafío que no se puede resolver).

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 19 — El cliente no confía en quien firmó

> **Fase:** 19 · **Familia:** 🔐 · **Dificultad:** 🟡 · **Tiempo sugerido:** 30 min
> **Perfil:** `lab` · **Motor de referencia:** Docker
> **Verificado el:** 04/10/2026 · macOS arm64

**El encargo.** Daniela, del equipo del portal: *"Desde que alguien 'regeneró los certificados' el viernes, mi
`curl` contra la API falla con un error de certificado. Tengo la CA del laboratorio, la misma de siempre."*

**Cómo llegar.** `git switch --detach inc/19/unknown-ca-roto` · o `task inc:break -- 19` · o, a mano: una CA nueva
(`certs.py ca --name otra`), un certificado firmado por ella, y ese certificado en el `Secret` de la puerta sin
`Certificate`.

**Lo que vas a ver.**

```text
$ curl -sS -o /dev/null --cacert .secrets/tls/ca.crt 'https://api.localhost:8443/pricing/prices?store=DRO-007'
curl: (60) SSL certificate problem: unable to get local issuer certificate
```

Un cliente en Go (o containerd, o kubectl) dice lo mismo con otras palabras: `x509: certificate signed by unknown
authority`.

<details><summary>💡 Pista 1 — dónde mirar</summary>El certificado no venció, y el nombre está bien. Queda la primera pregunta: ¿quién lo firmó?</details>
<details><summary>💡 Pista 2 — qué comparar</summary>El *issuer* del certificado que sirve la puerta contra el *subject* de la CA que tiene el cliente.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>"Regenerar los certificados" puede querer decir regenerar la CA.</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** `unable to get local issuer certificate` es la primera pregunta: el cliente no
encuentra al firmante en su lista. Antes de tocar al cliente, mira quién firmó lo que se sirve.

**Primer comando.**

```text
$ echo | openssl s_client -connect 127.0.0.1:8443 -servername api.localhost -CAfile .secrets/tls/ca.crt 2>/dev/null | grep -E "issuer=|Verify return"
issuer=O=Droguerías La Vecina, CN=La Rebotica · CA otra
Verify return code: 21 (unable to verify the first certificate)
```

La CA del cliente es *La Rebotica · CA del laboratorio*; el certificado lo firmó *CA otra*.

**Causa.** Alguien emitió el certificado de la puerta con otra CA, que ningún cliente tiene. El certificado es
válido; el cliente, con razón, no confía en quien lo firmó.

**Corrección.** `task inc:fix -- 19`: cert-manager vuelve a emitir con el emisor del laboratorio. Lo que **no** se
hace: instalar la CA nueva en cada cliente para que el error desaparezca, salvo que de verdad se esté cambiando de
CA, y entonces se hace en todos los clientes antes de cambiar el servidor.

**Prevención.** Una sola CA por propósito, con su clave guardada en un solo lugar (el `Secret` del emisor), y los
certificados emitidos solo por el emisor. Cambiar de CA es un proyecto con orden, no un viernes.

**En la nube** 🌩️ El mismo síntoma aparece con las CA privadas de los proveedores, y con el proxy corporativo
(incidente 27): ahí el que firma "otro" es el proxy, y la CA que falta es la de la empresa.

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 20 — El certificado es válido, pero no para este nombre

> **Fase:** 19 · **Familia:** 🔐 · **Dificultad:** 🟡 · **Tiempo sugerido:** 30 min
> **Perfil:** `lab` · **Motor de referencia:** Docker
> **Verificado el:** 04/10/2026 · macOS arm64

**El encargo.** Valentina: *"La API por HTTPS anda perfecto. La página, en la misma puerta, con el mismo
certificado, no. ¿Cómo puede un certificado servir para una dirección y no para otra?"*

**Cómo llegar.** `git switch --detach inc/20/wrong-san-roto` · o `task inc:break -- 20` · o, a mano: un certificado
con solo `api.localhost` en el SAN, en el `Secret` de la puerta.

**Lo que vas a ver.**

```text
$ curl -sS -o /dev/null --cacert .secrets/tls/ca.crt https://storefront.localhost:8443/
curl: (60) SSL: no alternative certificate subject name matches target host name 'storefront.localhost'
$ curl -s -o /dev/null -w "%{http_code}\n" --cacert .secrets/tls/ca.crt 'https://api.localhost:8443/pricing/prices?store=DRO-007'
200
```

En el navegador, `NET::ERR_CERT_COMMON_NAME_INVALID`.

<details><summary>💡 Pista 1 — dónde mirar</summary>La firma y la fecha están bien: la API funciona con el mismo certificado. Queda la tercera pregunta.</details>
<details><summary>💡 Pista 2 — qué comparar</summary>Los nombres que tiene el certificado contra el nombre que escribiste en la URL.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>No mires el *Common Name*: el cliente no lo mira.</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** Un nombre funciona y otro no, con el mismo certificado: es el SAN. El mensaje lo
dice con todas las letras, y aun así se lee mal porque el CN suele tener el nombre "correcto".

**Primer comando.**

```text
$ kubectl -n gateway get secret lab-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -ext subjectAltName
X509v3 Subject Alternative Name:
    DNS:api.localhost
```

**Causa.** El certificado se emitió con un solo nombre. La puerta sirve seis, y para los otros cinco el cliente
rechaza la conexión.

**Corrección.** `task inc:fix -- 20`: el `Certificate` del repositorio lista los seis nombres en `dnsNames`, y
cert-manager emite uno nuevo.

**Prevención.** Los nombres del certificado se escriben junto a los nombres de las rutas: si alguien agrega un host a
una `HTTPRoute`, el `Certificate` de la puerta tiene que cambiar en el mismo commit.

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 21 — El `Gateway` rechaza su propio certificado

> **Fase:** 19 · **Familia:** 🔐 · **Dificultad:** 🟢 · **Tiempo sugerido:** 20 min
> **Perfil:** `lab` · **Motor de referencia:** Docker
> **Verificado el:** 04/10/2026 · macOS arm64

**El encargo.** Valentina, después de renovar a mano: *"Generé el certificado nuevo, armé el `Secret` en YAML porque
`kubectl create secret tls` me daba un error raro, lo apliqué, y ahora HTTPS no responde para ningún nombre."*

**Cómo llegar.** `git switch --detach inc/21/key-cert-mismatch-roto` · o `task inc:break -- 21` · o, a mano: un
`Secret` en YAML con el certificado de la puerta y la clave de otro certificado.

**Lo que vas a ver.**

```text
$ curl -sS -o /dev/null --cacert .secrets/tls/ca.crt 'https://api.localhost:8443/pricing/prices?store=DRO-007'
curl: (35) LibreSSL SSL_connect: SSL_ERROR_SYSCALL in connection to api.localhost:8443
```

<details><summary>💡 Pista 1 — dónde mirar</summary>No hay error de certificado: la conexión se corta antes. El cliente no llega a ver nada. ¿Qué dice la puerta de su listener?</details>
<details><summary>💡 Pista 2 — qué comparar</summary>El "error raro" de `kubectl create secret tls` era una pista.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>La cuarta pregunta, la que el cliente no ve: ¿la clave corresponde al certificado?</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** `SSL_ERROR_SYSCALL` en todos los nombres a la vez, sin mensaje de certificado: el
servidor no está sirviendo TLS. Mira el estado del listener antes que el certificado.

**Primer comando.**

```text
$ kubectl -n gateway get gateway lab -o jsonpath='{range .status.listeners[?(@.name=="https")].conditions[*]}{.type}={.status} {.reason}: {.message}{"\n"}{end}'
ResolvedRefs=False InvalidCertificateRef: No valid secrets exist: gateway/lab-tls must contain a matching tls.crt and tls.key: tls: private key does not match public key.
Programmed=False Invalid: Listener is invalid, see other Conditions for details.
```

**Causa.** El `Secret` tiene un certificado y la clave de otro. La puerta no puede probar que es dueña del
certificado, y no carga el listener. El "error raro" de `kubectl create secret tls` era exactamente este: kubectl
valida el par, y el YAML aplicado a mano no.

**Corrección.** `task inc:fix -- 21`, que devuelve el `Certificate` y deja que cert-manager
escriba el par completo. A mano, el par que corresponde: `kubectl create secret tls` con el certificado y **su** clave.

**Prevención.** Nunca armar un `Secret` TLS en YAML a mano: `kubectl create secret tls` valida el par, y cert-manager
lo escribe siempre completo. Y comparar antes de aplicar: `openssl x509 -noout -pubkey -in tls.crt` y `openssl pkey
-pubout -in tls.key` tienen que dar lo mismo.

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 22 — cert-manager no emite nada

> **Fase:** 19 · **Familia:** 🔐 · **Dificultad:** 🟠 · **Tiempo sugerido:** 40 min
> **Perfil:** `lab` · **Motor de referencia:** Docker
> **Verificado el:** 04/10/2026 · macOS arm64

**El encargo.** Valentina: *"Alguien 'limpió' el namespace de cert-manager el jueves. Hoy reinicié `pricing` y no
arranca: lleva diez minutos creando el contenedor. `inventory` no puede vender."*

**Cómo llegar.** `git switch --detach inc/22/issuer-without-ca-roto` · o `task inc:break -- 22` · o, a mano: borrar el
`Secret` `lab-ca` de `cert-manager` y el `Secret` `pricing-tls` de `apps`, y reiniciar `pricing`.

**Lo que vas a ver.**

```text
$ kubectl -n apps get pods -l app.kubernetes.io/name=pricing,app.kubernetes.io/component=backend
NAME                       READY   STATUS              RESTARTS   AGE
pricing-bf4b5f568-dl85v    0/1     ContainerCreating   0          41s
$ kubectl -n apps get certificate pricing-tls
NAME          READY   SECRET        AGE
pricing-tls   False   pricing-tls   50m
```

Y en los eventos: `MountVolume.SetUp failed for volume "tls-server" : secret "pricing-tls" not found`.

<details><summary>💡 Pista 1 — dónde mirar</summary>El pod espera un `Secret` que no existe. ¿Quién lo escribe?</details>
<details><summary>💡 Pista 2 — qué comparar</summary>El `Certificate` está en `False`. Sigue la cadena: `Certificate` → `CertificateRequest` → emisor.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>Un emisor de tipo CA necesita la CA. ¿Dónde vive?</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** `ContainerCreating` con `FailedMount` de un `Secret` que se llama como un
`Certificate`: el problema no es el pod, es quien emite. Sube por la cadena hasta el emisor.

**Primer comando.**

```text
$ kubectl get clusterissuer lab-ca -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}: {.message}{"\n"}{end}'
Ready=False ErrGetKeyPair: Error getting keypair for CA issuer: secrets "lab-ca" not found
```

Y la `CertificateRequest`, aprobada y sin emitir: `Referenced issuer does not have a Ready status condition`.

**Causa.** El `ClusterIssuer` de tipo CA firma con la clave del `Secret` `lab-ca` del namespace `cert-manager`.
Sin ese `Secret`, el emisor no está listo, ninguna solicitud se firma, y el `Secret` del certificado de `pricing`
nunca llega. Lo que ya estaba emitido seguía funcionando: el incidente apareció recién al reiniciar.

**Corrección.** `task inc:fix -- 22`, que es `task platform:certs -- lab`: el `Secret` de la CA desde `.secrets/tls/`.
Con el emisor listo, la `CertificateRequest` pendiente se firma en segundos, el kubelet monta el `Secret` en su
próximo intento y `pricing` arranca.

**Prevención.** La clave de la CA es un respaldo, no un archivo de una máquina: guardada fuera del cluster (aquí,
`.secrets/`; en una empresa, un gestor de secretos) y con su forma de volver a cargarla escrita. Y una alerta sobre
el emisor en `Ready=False`, que avisa días antes de que un reinicio lo haga visible.

**En la nube** 🌩️ Con un emisor ACME, la misma cadena se corta en el desafío (DNS o HTTP), y el síntoma es el mismo:
un `Certificate` que no llega a `Ready` y un `Secret` que no aparece.

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 23 — `pricing` rechaza a `inventory` con mTLS

> **Fase:** 19 · **Familia:** 🔐 · **Dificultad:** 🟠 · **Tiempo sugerido:** 40 min
> **Perfil:** `lab` · **Motor de referencia:** Docker
> **Verificado el:** 04/10/2026 · macOS arm64

**El encargo.** Wilson, desde logística: *"Las droguerías no pueden vender: la caja dice que precios no contesta.
Pero si abro la página, los precios están ahí."*

**Cómo llegar.** `git switch --detach inc/23/mtls-without-client-cert-roto` · o `task inc:break -- 23` · o, a mano: quitar
de `inventory` las variables del certificado y la clave del bundle `pricing`, dejando la CA.

**Lo que vas a ver.**

```text
$ curl -s -H Host:api.localhost -H Content-Type:application/json -d '{"store":"DRO-005","sku":"SKU-0001","quantity":1}' http://127.0.0.1:8080/inventory/sales
{"error":"unavailable","message":"pricing no contesta"}
```

Y `GET /pricing/prices` por la puerta, 200.

<details><summary>💡 Pista 1 — dónde mirar</summary>`pricing` contesta a la puerta y no a `inventory`. ¿Por qué puerto le habla cada uno?</details>
<details><summary>💡 Pista 2 — qué comparar</summary>El log de `inventory` en la venta, y el de `pricing` en el mismo segundo.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>En el 8443, `pricing` le pide algo al cliente antes de escucharlo.</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** "No contesta" para uno y contesta para otro: no es `pricing` caído. La puerta llega
por el 8080 en HTTP; `inventory`, por el 8443 con mTLS. Busca la línea de los dos lados.

**Primer comando.**

```text
$ kubectl -n apps logs deploy/inventory --since=1m | grep "pricing no contesta"
{…"msg":"pricing no contesta: I/O error on GET request for \"https://pricing.apps.svc.cluster.local:8443/prices/SKU-0001\": (certificate_required) Received fatal alert: certificate_required",…}
$ kubectl -n apps logs deploy/pricing --since=1m | grep handshake
{…"level":"WARN","msg":"http: TLS handshake error from 10.244.2.189:36326: tls: client didn't provide a certificate",…}
```

**Causa.** `inventory` llama al 8443 sin certificado de cliente: el bundle `pricing` quedó solo con la CA. `pricing`
exige el certificado, corta el saludo, e `inventory` traduce cualquier fallo de conexión a "no contesta" (503).

**Corrección.** `task inc:fix -- 23`: `task deploy FORCE=true`, que devuelve las variables del bundle.

**Prevención.** El chart pone las cuatro variables del bundle juntas; quitar una a mano es el incidente. Y un 503 que
dice "no contesta" esconde la causa: el log de `inventory` sí la tiene, y por eso G7 la escribe entera.

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 24 — El cluster no puede traer imágenes del registry propio

> **Fase:** 19 · **Familia:** 🔐 · **Dificultad:** 🔴 · **Tiempo sugerido:** 60 min
> **Perfil:** `lab` · **Motor de referencia:** Docker · 🦭 con Podman, el `push` también falla
> **Verificado el:** 04/10/2026 · macOS arm64 (con Podman, el 03/10/2026)

**El encargo.** Valentina: *"Subí `pricing` al registry nuevo sin problema, con Docker. Pero el pod no la puede traer.
¿Cómo va a fallar el `pull` si el `push` pasó?"*

**Cómo llegar.** `git switch --detach inc/24/registry-ca-untrusted-roto` · o `task inc:break -- 24` · o, a mano: `task
registry:up`, `task registry:push -- pricing`, quitar `/etc/containerd/certs.d/lab-registry:5000/` de los nodos, y
`pricing` con la imagen `lab-registry:5000/lab/pricing:g8`.

**Lo que vas a ver.**

```text
$ kubectl -n apps get pods -l app.kubernetes.io/name=pricing,app.kubernetes.io/component=backend
NAME                       READY   STATUS             RESTARTS   AGE
pricing-<hash>             0/1     ImagePullBackOff   0          20s
$ kubectl -n apps describe pod … | grep "Failed to pull"
Failed to pull image "lab-registry:5000/lab/pricing:g8": failed to pull and unpack image "lab-registry:5000/lab/pricing:g8":
failed to resolve reference "lab-registry:5000/lab/pricing:g8": failed to do request: Head "https://lab-registry:5000/v2/lab/pricing/manifests/g8":
tls: failed to verify certificate: x509: certificate signed by unknown authority
```

<details><summary>💡 Pista 1 — dónde mirar</summary>El mismo registry, dos clientes distintos: el que hizo el `push` y el que hace el `pull`. ¿Quién es cada uno?</details>
<details><summary>💡 Pista 2 — qué comparar</summary>Por qué el `push` del host no validó nada: `docker info`.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>El `pull` lo hace el containerd del nodo, que tiene su propia lista de CA, por registry.</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** `x509: certificate signed by unknown authority` en un `pull` del kubelet: el cliente
es el **containerd del nodo**, no tu motor ni tu máquina. Que el `push` haya pasado no prueba nada sobre él.

**Primer comando.**

```text
$ docker info --format '{{.RegistryConfig.InsecureRegistryCIDRs}}'
[::1/128 127.0.0.0/8]
$ docker exec lab-worker ls /etc/containerd/certs.d/
ls: cannot access '/etc/containerd/certs.d/': No such file or directory
```

El `push` a `localhost:5001` pasó porque Docker **no valida** registries en `127.0.0.0/8`. El nodo no tiene ninguna
configuración para `lab-registry:5000`.

**Causa.** Tres clientes, y cada uno confía por su cuenta: el motor del host (que con Docker no pregunta en
`localhost`), el containerd de cada nodo (que no tiene la CA) y los clientes del host, como `curl` (que tampoco). El
cluster no puede traer la imagen porque el segundo no confía.

**Corrección.** `task inc:fix -- 24`, que es `task registry:trust -- lab`: la CA y un `hosts.toml` en
`/etc/containerd/certs.d/lab-registry:5000/` de cada nodo. containerd lee esa carpeta en cada `pull` (la activa el
`config_path` de los archivos de kind desde la [Fase 07](07-el-cluster-local.md)): no se reinicia nada, y el pod siguiente trae la imagen en
141 ms. Para `curl`, `--cacert` o la confianza del host.

**Prevención.** La lista de los tres sitios, escrita, y la configuración de los nodos en la creación del cluster, no
después (un nodo nuevo no la tiene). Y una sola forma de llevar cada imagen al nodo: después de traer `pricing:g8`
del registry, la misma imagen cargada con `kind load` empezó a fallar con `pull access denied` en ese nodo, porque el
kubelet registró que ese digest vino de `lab-registry` (la [Fase 19](19-tls-y-certificados.md), sección 5.7).

**🦭 Con Podman**, el `push` también falla con `x509: certificate signed by unknown authority`: Podman no hace la
excepción de `localhost`. La CA va **dentro de su máquina**, en `~/.config/containers/certs.d/localhost:5001/ca.crt`.

**En la nube** 🌩️ Un registry gestionado del proveedor usa una CA pública y el problema no existe; aparece con un
registry interno de la empresa (Harbor, Nexus) con su propia CA, y la corrección son los mismos tres sitios, en los
nodos que el proveedor te deja configurar.

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 25 — Endurecí el pod y dejó de arrancar

> **Fase:** 20 · **Familia:** ☸️ · **Dificultad:** 🟡 · **Tiempo sugerido:** 30 min
> **Perfil:** `lab` · **Motor de referencia:** Docker
> **Verificado el:** 04/10/2026 · macOS arm64

**El encargo.** Valentina, después de una revisión de seguridad: *"Le puse `runAsNonRoot` a Postgres, que era lo
único que faltaba. Ahora no arranca, y ninguna venta pasa. Revertir me da miedo: la revisión dice que es
obligatorio."*

**Cómo llegar.** `git switch --detach inc/25/runasnonroot-root-image-roto` · o `task inc:break -- 25` · o, a mano: en el
`StatefulSet` de Postgres, `securityContext: {runAsNonRoot: true}` en el pod, sin `runAsUser`, y borrar `postgres-0`.

**Lo que vas a ver.**

```text
$ kubectl -n data get pod postgres-0
NAME         READY   STATUS                       RESTARTS   AGE
postgres-0   0/1     CreateContainerConfigError   0          19s
```

Sin logs: el contenedor nunca empezó. Y en `apps`, la readiness de los servicios en `503`, porque la base no contesta.

<details><summary>💡 Pista 1 — dónde mirar</summary>`CreateContainerConfigError` es antes de arrancar: no hay log. El motivo está en el estado del contenedor.</details>
<details><summary>💡 Pista 2 — qué comparar</summary>Qué usuario dice la imagen, y qué le pediste al kubelet que compruebe.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>Hay imágenes que arrancan como root y bajan de privilegios ellas mismas.</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** `CreateContainerConfigError` sin logs: el kubelet se negó a crear el contenedor. No
mires la base ni la red; mira el mensaje del estado.

**Primer comando.**

```text
$ kubectl -n data get pod postgres-0 -o jsonpath='{.status.containerStatuses[0].state.waiting.message}'
container has runAsNonRoot and image will run as root (pod: "postgres-0_data(…)", container: postgres)
$ docker image inspect postgres@sha256:5a5a84b1… --format 'User="{{.Config.User}}"'
User=""
```

**Causa.** La imagen oficial de Postgres no declara usuario: arranca como root, prepara la carpeta de datos y baja a
`postgres` (999) ella misma. `runAsNonRoot` le pide al kubelet que no arranque nada que vaya a correr como root, y sin un
`runAsUser` el kubelet ve root y se niega. La regla está bien; le faltaba decir con qué usuario.

**Corrección.** `task inc:fix -- 25`: el `StatefulSet` del repositorio, con `runAsUser: 999`, `runAsGroup: 999` y
`fsGroup: 999` (para que el volumen quede a su nombre). La imagen sabe arrancar directamente como ese usuario.

**Prevención.** Antes de exigir `runAsNonRoot`, mirar el usuario de cada imagen (`docker image inspect`): vacío o `root`,
la imagen arranca como root; un nombre, el kubelet tampoco puede comprobarlo ([Fase 20](20-seguridad-del-pod-y-de-la-red.md), sección 5.1). En los dos casos, el
número va en `runAsUser`.

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 26 — Cerré la red y se rompió todo, hasta lo permitido

> **Fase:** 20 · **Familia:** ☸️ · **Dificultad:** 🔴 · **Tiempo sugerido:** 60 min
> **Perfil:** `lab` · **Motor de referencia:** Docker
> **Verificado el:** 04/10/2026 · macOS arm64

**El encargo.** Valentina, el día que cerró la red: *"Puse el default deny y abrí exactamente lo que el sistema usa:
entre los servicios, y a Postgres. Lo revisé dos veces. Ahora la página tarda dieciséis segundos y devuelve un
error, y ni siquiera `inventory` llega a `pricing`, que está permitido."*

**Cómo llegar.** `git switch --detach inc/26/default-deny-dns-roto` · o `task inc:break -- 26` · o, a mano: borrar la
`NetworkPolicy` `allow-dns` de `apps`.

**Lo que vas a ver.**

```text
$ curl -s -H Host:api.localhost … http://127.0.0.1:8080/inventory/sales -w "\n%{http_code} en %{time_total}s\n"
upstream request timeout
504 en 16.242148s
```

<details><summary>💡 Pista 1 — dónde mirar</summary>Un timeout no es un rechazo: algo espera. Prueba desde adentro de un pod, no desde la puerta.</details>
<details><summary>💡 Pista 2 — qué comparar</summary>La misma conexión por nombre y por IP.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>¿Dónde vive el servicio que traduce nombres a IP, y lo dejaste salir hacia allá?</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** Todo da timeout, también lo permitido: no es una regla que falte para un destino,
es algo que usan todos. Desde adentro de un pod del namespace, separa el nombre de la conexión.

**Primer comando.**

```text
$ kubectl -n apps exec deploy/replenish -- node -e "require('dns').lookup('pricing',(e,a)=>console.log('lookup pricing:',e?e.code:a))"
lookup pricing: EAI_AGAIN
$ kubectl -n apps exec deploy/replenish -- node -e "…net.connect(8080, '<IP del Service pricing>')…"
por IP: conecta
```

El nombre no resuelve; la IP conecta.

**Causa.** El `default-deny` cerró también la salida hacia CoreDNS, que vive en `kube-system`. Ninguna política la vuelve
a abrir: ningún pod del namespace resuelve ningún nombre, y las conexiones permitidas, que van por nombre, nunca llegan
a intentarse. La puerta espera su propio timeout (16 s) y devuelve 504.

**Corrección.** `task inc:fix -- 26`: la política `allow-dns` (salida a `kube-system`, `k8s-app: kube-dns`, puerto 53 UDP
y TCP), aplicando el manifiesto del release tal como está. **`task deploy` no alcanza**: el hook de migraciones corre
antes que el resto del release, tampoco resuelve el nombre de Postgres, y Helm hace rollback (la [Fase 20](20-seguridad-del-pod-y-de-la-red.md), sección 9).

**Prevención.** La excepción del DNS va en el mismo archivo que el `default-deny`, antes que cualquier otra. Y cada
política nueva se prueba desde adentro de un pod (la [Fase 20](20-seguridad-del-pod-y-de-la-red.md), sección 5.5), no desde la puerta.

**En la nube** 🌩️ Igual, con un matiz: algunos clusters gestionados ponen un caché de DNS en cada nodo, con otra IP y
otras labels, y la política tiene que dejar salir hacia ese, no hacia CoreDNS.

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

### 🩺 Incidente 27 — En el portátil de la empresa no baja ninguna imagen

> **Fase:** 00 · **Familia:** 🩺 · **Dificultad:** 🟡 · **Tiempo sugerido:** 45 min
> **Perfil:** — · **Motor de referencia:** Podman 🦭 (con Docker Desktop, no reproducido)
> **Verificado el:** 03/10/2026 · macOS arm64, con Podman y un proxy local · con Docker Desktop y en Windows: no verificado por el autor

**El encargo.** La mesa de ayuda, que es la primera en enterarse: *"Nos llegaron tres casos del
equipo de Alquimia: el programa de contenedores no descarga nada. Les revisamos el internet y está
bien, el navegador abre todo. Nos dicen que es 'algo de certificados'. ¿Es el proxy?"*

**Cómo llegar.** No se provoca con las tareas del laboratorio. Se reproduce con un proxy local que
inspecciona TLS con su propia CA, como el corporativo de La Vecina; así lo reproduje, con mitmproxy
dentro de la máquina de Podman.

**Lo que vas a ver.**

```text
Error: unable to copy from source docker://alpine:3.21: initializing source docker://alpine:3.21: fetching manifest 3.21 in docker.io/library/alpine: pinging container registry registry-1.docker.io: Get "https://registry-1.docker.io/v2/": tls: failed to verify certificate: x509: certificate signed by unknown authority
```

<details><summary>💡 Pista 1 — dónde mirar</summary>El navegador abre todo y el motor no. Algo entre tu máquina e internet le presenta al motor un certificado que el navegador sí acepta.</details>
<details><summary>💡 Pista 2 — qué comparar</summary>Quién firmó el certificado que ve el navegador al abrir `https://registry-1.docker.io` contra quién debería haberlo firmado.</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>El navegador confía en la CA de la empresa porque el sistema operativo la tiene instalada. La máquina virtual del motor es otro sistema operativo.</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** `x509: certificate signed by unknown authority` en el **primer**
`pull`, sin ningún registry propio de por medio, en un equipo de empresa, es casi siempre un proxy
que inspecciona TLS. El navegador no lo nota porque la CA del proxy está en el almacén del sistema
operativo; la máquina virtual del motor tiene su propio almacén, y ahí no está.

**Primer comando.** Desde el host, `openssl s_client -connect registry-1.docker.io:443 -showcerts </dev/null | grep issuer`:
si el emisor es la CA de tu empresa y no una pública, es el proxy.

**Causa.** El proxy corporativo descifra y vuelve a cifrar el tráfico con un certificado firmado por
la CA de la empresa. La máquina virtual del motor no confía en esa CA.

**Corrección.** Instalar la CA de la empresa en el almacén de confianza **de la máquina virtual del
motor**. Con Podman en macOS: copiarla a `/etc/pki/ca-trust/source/anchors/` dentro de la máquina
(`podman machine ssh`) y correr `sudo update-ca-trust`; con eso el `pull` pasó. Con Docker Desktop,
la documentación (https://docs.docker.com/engine/network/ca-certs/) indica agregarla al almacén de
confianza del sistema —en macOS, el llavero, con «Confiar siempre»; en Windows, las entidades de
certificación raíz de confianza— y reiniciar Docker Desktop (*no verificado por el autor*). Pídele la
CA a mesa de ayuda: es pública, no un secreto. Sin proxy, el mismo comando muestra un emisor
público:

```text
issuer=C=US, O=Amazon, CN=Amazon RSA 2048 M01
```

**Prevención.** Instalar la CA de la empresa en el motor como parte de la instalación, en los
portátiles corporativos. Y no apagar la verificación de TLS para salir del paso: es la única
diferencia entre este incidente y uno peor. Su gemelo es el [incidente 24](#-índice-por-id), con el
mismo síntoma y otra causa: el registry propio con CA propia de la [Fase 19](19-tls-y-certificados.md).

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.

---

## 🪞 Retrospectiva

Para después de los veintisiete, o de los que hayas hecho. Contéstalas por escrito, en tu bitácora:

1. ¿Qué familia de síntomas reconoces ya sin pensar?
2. ¿Cuál te sigue costando, y en qué paso del método te trabas?
3. ¿Qué comando usaste más? ¿Lo habrías adivinado al empezar?
4. ¿Qué incidente te pasó "de verdad" en tu trabajo, antes o después de hacerlo aquí?
5. ¿Cuál de las prevenciones vas a adoptar el lunes?
