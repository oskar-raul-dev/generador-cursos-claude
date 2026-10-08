# 🔬 Verificación de laboratorio (P11) — hallazgos

Documento de autoría: lo que se ejecutó en macOS arm64 para fijar versiones, memoria y caminos antes
de escribir `a01`. Cada hallazgo lleva fecha, el log que lo respalda (en `logs/`) y lo que cambia en
`prompts/` (traslado de P12). **No se cita desde el curso**: el curso cita `a01`.

**Máquina de referencia:** MacBook Pro (MacBookPro18,3), Apple M1 Pro, 8 núcleos, 32 GB · macOS
26.7.1 (25G241) · arm64.

**Lo que la verificación dejó en la máquina de Oskar.** En Docker, nada: al cerrar (03/10/2026,
02:05) los contenedores (26), los volúmenes (49), las imágenes y las redes coinciden con el
inventario inicial (`logs/00-docker-inventario-inicial.log`). Se borraron solo los recursos
creados en la sesión, comparando contra ese inventario, incluido el volumen anónimo del registry.
La configuración de Docker Desktop no se tocó (copia en `logs/00-docker-settings-store-original.json`).
Lo único que creció es la caché de build de Docker, que no se limpió porque `docker builder prune`
no distingue la de la sesión de la previa. En Podman queda la máquina `podman-machine-default`
(libkrun, 4 CPU, **4 GiB**), **detenida**, con imágenes de prueba: no existía antes y la usa T1.
Se borra con `podman machine rm` si no se quiere conservar.

---

## H1 · Instalación de las herramientas (03/10/2026)

Instaladas por Oskar con las instrucciones de esta sesión. Podman con el **instalador oficial**
(`podman-installer-macos-arm64.pkg`, en `/opt/podman/bin`, agregado al `PATH` por
`/etc/paths.d`), porque su documentación desaconseja Homebrew: *"It's not recommended to install via
Homebrew because it is a community-maintained package manager"*. Podman Desktop por cask; el resto
por Homebrew.

| Herramienta | Versión | Cómo |
|---|---|---|
| Docker Desktop / Engine | 4.92.0 / 29.8.0 | ya instalado |
| Podman / Podman Desktop | 6.1.3 / 1.29.3 | pkg oficial / `brew install --cask podman-desktop` |
| kind | 0.33.0 | brew |
| kubectl | 1.37.1 (brew) y 1.36.1 (Docker Desktop) | ver H3 |
| Helm / helm-diff | 4.3.0 / 3.15.15 | brew / plugin firmado, ver H2 |
| Task | 3.54.0 | brew (`go-task`) |
| k9s | 0.51.0 | brew |
| Hurl | 8.0.1 | brew (ya estaba); `--version` informa `x86_64-apple-darwin25.0` aunque el binario es arm64 |
| k6 | 2.3.0 | brew |
| hyperfine | 1.20.0 | brew |
| dive | 0.13.1 | brew |
| Python | 3.14.7 | ya instalado (brew) |

## H2 · helm-diff con Helm 4 y gpg 2.5 (03/10/2026)

Helm 4 verifica la firma de los plugins por defecto y busca la clave en `~/.gnupg/pubring.gpg`. Con
gpg 2.5 las claves viven en `public-keys.d` (keyboxd) y ese archivo no existe:

```text
Verifying plugin signature...
Error: plugin verification failed: open /Users/oskar/.gnupg/pubring.gpg: no such file or directory
```

**Salida:** exportar la clave a un anillo con el formato viejo y pasarlo con `--keyring`:

```bash
gpg --export EA17A2A206AFF8CD > ~/.gnupg/helm-diff-pubring.gpg
helm plugin install https://github.com/databus23/helm-diff/releases/latest/download/helm-diff-macos-arm64.tgz --keyring ~/.gnupg/helm-diff-pubring.gpg
```

**Traslado:** entrada de `a02` (macOS) y paso de instalación en la F00 / `a01`.

## H3 · Dos `kubectl` en el `PATH` (03/10/2026)

Docker Desktop instala su `kubectl` (1.36.1) en `~/.docker/bin` y en `/usr/local/bin`, y queda antes
que el de Homebrew (1.37.1). Brew lo advierte: *"kubectl (shadowed by /Users/oskar/.docker/bin/kubectl)"*.
Con el nodo fijado en 1.36 (H4) los dos están dentro del sesgo de versiones que admite Kubernetes
(±1 menor), así que no hace falta tocar el `PATH`. **Traslado:** `a02` (los dos `kubectl` y
`which -a kubectl`), y `a01` fija `kubectl` en la línea del nodo.

## H4 · Versiones según D17, y la que manda: Envoy Gateway (03/10/2026)

Logs: `01-versiones-*.log`. **La matriz de compatibilidad de Envoy Gateway v1.9 admite Kubernetes
v1.33–v1.36** con Gateway API v1.6.1, y kind 0.33.0 trae por defecto `kindest/node:v1.37.0`. Se fija
el nodo en **`kindest/node:v1.36.4@sha256:099e049362a1526b2db71494e1947aae99bd16290d7c895f2b7ea312e3cbfaed`**,
publicado en las notas de kind 0.33.0. Es la aplicación honesta de D17: la última estable **que
todas las piezas soportan**, no la última a secas. La regla se escribe en `a01`.

| Pieza | Versión fijada | Línea / razón |
|---|---|---|
| kind | 0.33.0 | última estable (26/08/2026) |
| Nodo de Kubernetes | v1.36.4 | ver arriba; 1.37 queda fuera de la matriz de Envoy Gateway |
| Envoy Gateway | v1.9.2 | última estable (28/09/2026); trae Gateway API **v1.6.1**, canal experimental |
| Gateway API | v1.6.1 | la que instala Envoy Gateway; no se instala aparte (la suelta es v1.6.2) |
| cert-manager / trust-manager | v1.21.2 / v0.25.0 | últimas estables |
| Prometheus | **3.13.4** | **línea LTS** (3.13, soporte hasta el 31/07/2027); la última estable es 3.15.0 |
| Grafana | 13.2.3 | última estable |
| Loki | 3.7.8 | última estable |
| Fluent Bit | 5.1.3 | última estable |
| Tempo | 3.1.0 | última estable |
| metrics-server | v0.9.0 | última estable |
| PostgreSQL | 18.6 | última mayor (sin LTS) |
| Valkey | 9.1.2 | última estable |
| NATS Server | 2.15.0 | última estable |
| cloud-provider-kind | 0.12.0 | se probó y se descarta para el puerto fijo (H6) |
| Istio | 1.31.1 | última estable (`a10`) |
| Eclipse GlassFish | 8.0.4 | última estable (`a16`; SOAP por verificar en T1b) |
| Swagger UI | 5.33.1 | última estable |
| Java (Temurin) | 25.0.4.1+1 | **LTS** (soporte hasta 30/09/2031) |
| Node.js | 24.21.0 | **LTS** (Krypton) |
| Go | 1.27.1 | última estable |
| PHP | 8.5.11 | última estable |
| Python | 3.14.8 | última estable (la de la máquina es 3.14.7) |
| Spring Boot | 4.1.1 | última estable (default de start.spring.io) |
| Laravel | 13.34.0 | última estable |
| NestJS | 12.1.2 (core) / 12.0.8 (cli) | última estable |
| React / Vite | 19.3.0 / 8.3.2 | últimas estables |

Los digests de las imágenes base se fijan en H-imágenes, al construirlas.

## H5 · kind sobre Docker: el cluster `minimo` (03/10/2026)

`kind create cluster` con el nodo 1.36.4: **22 s** la primera vez y **11,5 s** con la imagen en
caché (`logs/02-*`). Nodo `Debian GNU/Linux 13 (trixie)`, kernel `7.0.12-linuxkit (arm64)`,
`containerd://2.3.4`. VM de Docker Desktop: 8 CPU y 7.934 MiB (valor por defecto; Docker Desktop no
guarda `memoryMiB` en `settings-store.json` mientras sea el default).

Memoria en reposo (`logs/03-*`, 60 s después de `Ready`): el contenedor del nodo ocupa **627,6 MiB**,
y la memoria usada de la VM pasa de 472 a 1.104 MiB. Con Envoy Gateway y un `Gateway` programado
(`logs/06-*`) el nodo sube a **1,19 GiB**: el `kube-apiserver` pasa a 575 MiB por las CRD de Gateway
API, y Envoy Gateway suma unos **87 MiB** (controlador 39,8 + proxy 46,7).

> ⚠️ El RSS del proceso de la VM en el host (`com.apple.Virtualization.VirtualMachine`) no sirve como
> medida: pasó de 1,2 a 5,7 GB porque la VM retiene la caché de páginas. B-00 mide dentro de la VM y
> por pod.

## H6 · El puerto del host al `Gateway` (03/10/2026)

**cloud-provider-kind** 0.12.0, como contenedor en la red `kind` (`logs/05-*`): asigna la IP
`172.30.0.4` al `Service` `LoadBalancer` y el `Gateway` queda `PROGRAMMED True`, pero **desde macOS
esa IP no responde** (timeout, `curl` exit 28). Con `--enable-lb-port-mapping` sí llega, por un
**puerto efímero** (`0.0.0.0:60498->8080/tcp`), que cambia en cada creación y además escucha en
todas las interfaces. No cumple el contrato (8080 fijo).

**`extraPortMappings` + `NodePort` fijo** (`logs/07-*`): el cluster mapea `127.0.0.1:8080 → 30080` y
`127.0.0.1:8443 → 30443` en el nodo, y un `EnvoyProxy` referenciado desde la `GatewayClass` fija el
`Service` del proxy como `NodePort` 30080. `curl http://api.localhost:8080/api/pricing/hostname` →
**200**. `*.localhost` resolvió a 127.0.0.1 sin tocar `/etc/hosts` con `curl` en macOS.

**Decisión propuesta:** `extraPortMappings` con `NodePort` en los dos perfiles. Limitación que se
declara: en el perfil `lab` el mapeo va en el control-plane, así que el proxy del `Gateway` tiene que
alcanzarse por `NodePort` desde ese nodo (lo hace kube-proxy aunque el pod viva en un worker).
cloud-provider-kind se nombra en la F10 como la alternativa que se parece más a la nube, con el
puerto efímero como su costo. **Traslado:** contrato §4 y §9, ficha de la F10, `a01`.

## H7 · metrics-server en kind: el flag del incidente 17 (03/10/2026)

metrics-server v0.9.0 con su manifiesto oficial no arranca en kind (`logs/08-*`): el pod queda
`0/1` con `Readiness probe failed: HTTP probe failed with statuscode: 500`, `kubectl top nodes`
responde `error: Metrics API not available`, y el log dice:

```text
E1003 05:53:04.384902       1 scraper.go:149] "Failed to scrape node" err="Get \"https://172.30.0.2:10250/metrics/resource\": tls: failed to verify certificate: x509: cannot validate certificate for 172.30.0.2 because it doesn't contain any IP SANs" node="minimo-control-plane"
```

Con `--kubelet-insecure-tls` agregado a los `args` arranca y `kubectl top` responde (`logs/09-*`).
**Traslado:** síntoma literal del incidente 17 (formato §4) y ficha de la F16; la divergencia con
producción (el kubelet de kind firma con un certificado sin IP SAN) se declara en voz alta.

## H8 · kindnet sí aplica `NetworkPolicy` (03/10/2026)

kind 0.33.0 trae `kindest/kindnetd:v20260820-69b56db7`. Con un `default-deny-ingress` en `apps`,
la misma petición pasa de **200** a **000** (timeout) desde un pod de `default` (`logs/10-*`). **La
F20 no necesita otro CNI.** **Traslado:** contrato §9 (cerrar el ⏳), ficha de la F20, `a01`.

## H9 · Helm 4 y helm-diff (03/10/2026)

`helm diff upgrade` contra el release de Envoy Gateway muestra el diff del `Deployment`
(`replicas: 1` → `2`) con Helm 4.3.0 y helm-diff 3.15.15 (`logs/11-*`). `helm plugin list` reporta
`APIVERSION legacy`: el plugin todavía no usa la API de plugins de Helm 4, pero funciona.

## H10 · Registry local con CA propia: los tres sitios (03/10/2026)

CA con `openssl` 3.6.4, certificado del registry con SAN `lab-registry`, `localhost` y
`127.0.0.1`; `registry:3` en la red `kind`, publicado en `127.0.0.1:5001`.

1. **El motor del host.** Con Docker, el `push` a `localhost:5001` **pasa sin confiar en la CA**:
   Docker trata `127.0.0.0/8` y `::1/128` como registries inseguros por defecto (`docker info` →
   `InsecureRegistryCIDRs`). **Con Podman no**: el `push` falla con
   `tls: failed to verify certificate: x509: certificate signed by unknown authority` y se arregla
   poniendo la CA **dentro de la máquina** (`~/.config/containers/certs.d/localhost:5001/ca.crt`,
   rootless) (`logs/12-*`, `logs/38-*`). 🦭 Divergencia real para la F19 y el incidente 24.
2. **containerd en cada nodo de kind.** El `pull` de `lab-registry:5000/...` falla con el síntoma
   literal del incidente 24 (`logs/13-*`):

   ```text
   Failed to pull image "lab-registry:5000/lab/pricing:p11": failed to pull and unpack image "lab-registry:5000/lab/pricing:p11": failed to resolve reference "lab-registry:5000/lab/pricing:p11": failed to do request: Head "https://lab-registry:5000/v2/lab/pricing/manifests/p11": tls: failed to verify certificate: x509: certificate signed by unknown authority
   ```

   kind 0.33 no trae `config_path` en `/etc/containerd/config.toml` (versión 2 del formato): hay que
   pedirlo **al crear el cluster** con `containerdConfigPatches`, y después copiar `ca.crt` y un
   `hosts.toml` a `/etc/containerd/certs.d/lab-registry:5000/` de cada nodo. Con eso el `pull` pasa
   en 24–30 ms (`logs/14-*`, `logs/39-*`), igual con los dos motores.
3. **Los clientes del host** (`curl`, el navegador): `curl: (60) SSL certificate problem: unable to
   get local issuer certificate` hasta pasar `--cacert` (`logs/15-*`).

**Traslado:** los dos archivos de kind del contrato llevan `containerdConfigPatches` desde la T1
(aunque el registry llegue en la F19: crear el cluster otra vez para agregarlo sería peor); formato
del cuaderno §4 (síntoma del 24); ficha de la F19.

## H11 · La tabla de memoria (B-00), sin servicios (03/10/2026)

Medida por namespace con la suma del `workingSet` de los contenedores (`/stats/summary` del
kubelet), 45–60 s después de que todo está `Running`, más la memoria usada de la VM (`free -m`). Una
corrida por celda: **es la orden de magnitud para dimensionar la VM, no una medición publicable**;
B-00 se rehace en `a01` con tres corridas y los servicios. Logs `16`–`20`, `26`–`27`, `33`–`37`,
`45`–`46`.

| Pieza (MiB, reposo) | Docker `minimo` | Podman `minimo` |
|---|---|---|
| Plano de control + kindnet + CoreDNS + metrics-server | 810 | 676 |
| Envoy Gateway (controlador + proxy) | 87 | 80 |
| Postgres / Valkey / NATS (JetStream) | 27 / 9 / 8 | 35 en total |
| Prometheus (LTS) / Grafana / Loki / Fluent Bit / Tempo | 32 / **359** / 46 / 11 / 18 | 438 en total |
| cert-manager + trust-manager | 84 | 76 |
| Istio ambient (istiod + istio-cni + ztunnel, por nodo) | 46 + 22 + 4 | — |
| Swagger UI (contenedor suelto, fuera del cluster) | 22 | — |

| Perfil, todo encendido, sin servicios | Pods | VM usada | VM asignada |
|---|---|---|---|
| Docker `minimo` | 1.978 MiB | 2.596 MiB | 7.934 MiB (default), 1 GiB de swap |
| Docker `lab` (3 nodos) | 2.368 MiB | 2.913 MiB | 7.934 MiB |
| Podman `minimo` | 1.479 MiB | 2.088 MiB | 3.886 MiB (4 GiB), sin swap |
| Podman `lab` (3 nodos) | 1.758 MiB | 2.452 MiB | 3.886 MiB |

**Grafana es la pieza más cara de la observabilidad** (359 MiB, once veces Prometheus), y el
`kube-apiserver` crece con las CRD: con las de Gateway API ya ocupaba 575 MiB (no se midió antes de instalarlas). **La máquina
de Podman por defecto (2 GiB) no alcanza**: con todo encendido colapsa, la API responde
`Unable to connect to the server: net/http: TLS handshake timeout` y krunkit queda al 257 % de CPU
(`logs/34-*`). Con 4 GiB entran los dos perfiles sin servicios, con 1,4–1,8 GiB libres.

> ⚠️ **Lo que falta para cerrar B-00:** los cinco servicios y el patrimonio no existen todavía. B-00
> se completa en `a01` así: T1 publica las filas de infraestructura (esta tabla, en tres corridas),
> T1b agrega el perfil `legacy` (ya lo dice el plan) y **T2 agrega la fila de los servicios G0** y
> decide si `minimo` cabe en una VM de 4 GiB, que es la de un portátil de 8 GB. Ninguna otra versión
> de la promesa "cabe en 8 GB" se publica antes.

## H12 · Envoy Gateway en el perfil `lab`: `externalTrafficPolicy` (03/10/2026)

En `lab`, el proxy del `Gateway` cayó en `lab-worker2` y `http://api.localhost:8080` dio timeout
(`curl` 000): Envoy Gateway crea el `Service` con **`externalTrafficPolicy: Local`**, así que el
`NodePort` del control-plane, que es donde está el mapeo del host, no reenvía a otro nodo. Con
`externalTrafficPolicy: Cluster` en el `EnvoyProxy` responde 200 (`logs/25-*`). **Traslado:** ficha
de la F10 (es una 🧨 natural) y el `EnvoyProxy` del laboratorio.

## H13 · Rollout sin readiness: el primer 503 (03/10/2026)

Dos veces, justo después de `kubectl rollout restart` y `rollout status` en verde, la primera
petición por el `Gateway` dio `upstream connect error or disconnect/reset before headers. reset
reason: remote connection failure` **503**, y las siguientes 200 (`logs/21-*`, `logs/22-*`). El pod
de prueba no tenía sondas. Es material para la F15 y la F16, no un incidente nuevo.

## H14 · Istio ambient (03/10/2026)

Los charts están en `https://blob.istio.io/istio-release/charts`; el repositorio viejo
(`istio-release.storage.googleapis.com`) se quedó en 1.31.0-rc.0 y responde `chart "base" version
"1.31.1" not found`. Con `base`, `istiod` y `cni` en `profile=ambient` y `ztunnel`, el namespace
etiquetado con `istio.io/dataplane-mode=ambient` sigue respondiendo por el `Gateway`. Suma unos
**72 MiB en un nodo** (istiod 46, istio-cni 22, ztunnel 4; istio-cni y ztunnel son DaemonSet).
**`a10` entra en el perfil `lab`.**

## H15 · Swagger UI (03/10/2026)

`swaggerapi/swagger-ui:v5.33.1` (`sha256:c3f95bc6…`, arm64 nativo) en `127.0.0.1:8090`, con los
OpenAPI montados en `/usr/share/nginx/html/openapi` y la variable `URLS`: índice 200, spec 200,
selector con los dos contratos, **22 MiB**. Cumple D10 sin entrar al cluster (`logs/23-*`).

## H16 · Podman: la máquina, kind y sus mañas (03/10/2026)

- **Proveedor y valores por defecto:** Podman 6.1.3 en macOS usa **libkrun** (krunkit), con 4 CPU,
  2.048 MiB y 100 GiB de disco; Fedora 44, kernel 7.1.10, rootless, cgroup v2. `init` 56 s
  (descarga incluida), `start` 14 s (`logs/31-*`).
- **Convivencia:** al arrancar con Docker Desktop encendido, Podman avisa *"Another process was
  listening on the default Docker API socket address"* y deja su socket en
  `/var/folders/.../podman-machine-default-api.sock`. Es la convivencia de la F00 y la F05.
- **kind sobre Podman rootless funciona** con `KIND_EXPERIMENTAL_PROVIDER=podman`, incluido el
  `hostPort` 8080 (no es privilegiado): 27 s el primero, con descarga (`logs/32-*`). No hizo falta
  máquina rootful.
- **`podman machine stop` puede mentir:** con la máquina colapsada respondió *"Machine
  "podman-machine-default" stopped successfully"* dos veces, mientras krunkit seguía vivo y `list`
  decía *Currently running*. Salió con `kill` (SIGTERM) al proceso de krunkit. → `a02`.
- **El cluster no revive solo:** tras reiniciar la máquina, el nodo queda `Exited (0) 292 years ago`
  (sic) y la API rechaza la conexión; `podman start minimo-control-plane` lo recupera, con los pods
  en `Unknown` y `ContainerCreating` hasta que se reprograman (`logs/36-*`). → `a02`.
- **`podman compose` no tiene compose propio:** delega en el `docker-compose` de Docker Desktop
  (*"Executing external compose provider"*). Con las bases sin descargar, el build falló con
  `unable to retrieve auth token: invalid username/password` porque ese cliente le pasa a Podman las
  credenciales de Docker (`credsStore: osxkeychain`); con las bases ya bajadas con `podman pull`,
  el mismo archivo levanta y la suite pasa (`logs/52-*`, `logs/53-*`). **Traslado:** `task
  compose:up` hace `pull` de las bases con el motor activo antes de `up`; F05 y `a02`.

## H17 · Cargar imágenes al cluster con cada motor (03/10/2026)

- **Docker:** `kind load docker-image lab/pricing:<tag>` funciona con una imagen construida en
  local, y el pod reporta *"Container image "lab/pricing:p11b" already present on machine and can
  be accessed by the pod"* (`logs/43-*`). Con una imagen **multiplataforma** traída de un registry
  falla con `ctr: content digest sha256:…: not found` (Docker Desktop usa el almacén de imágenes de
  containerd); `docker save --platform linux/arm64` + `kind load image-archive` lo evita
  (`logs/42-*`, `logs/43-*`).
- **Podman:** `kind load docker-image` **no sirve** (*"image: "lab/pricing:p11" not present
  locally"*, también con el nombre completo): consulta las imágenes de Docker, no las de Podman. El
  camino es `podman save` + `kind load image-archive`. Y el nombre importa: Podman nombra
  `localhost/lab/pricing`, y un pod con `image: localhost/lab/pricing:p11` **intentó descargarla
  igual** aunque estaba en el nodo (`dial tcp [::1]:443: connect: connection refused`), no se aisló
  la causa. Construyendo con `-t docker.io/lab/pricing:<tag>` el pod que pide `lab/pricing:<tag>`
  la encuentra (`logs/41-*`, `logs/44-*`).

**Decisión propuesta:** las imágenes se construyen como `lab/<svc>:<tag>` en Docker y como
`docker.io/lab/<svc>:<tag>` en Podman (las dos quedan como `docker.io/lab/<svc>` en el nodo), y
`task images:load` usa `kind load docker-image` con Docker y `save` + `image-archive` con Podman.
Los manifiestos dicen `lab/<svc>`, igual que el contrato §3. **Traslado:** contrato §7
(`images:load`), ficha de la F08 (el incidente 05 gana una variante 🦭), `a01`.

## H18 · Imágenes base, por digest (03/10/2026)

Todas con variante `linux/arm64` nativa (`logs/49-*`). Digest del índice multiplataforma:

| Imagen | Digest |
|---|---|
| `golang:1.27.1-alpine` | `sha256:8a5910f31396cd4d89662f56c68b3ae31d374308270a1c3bd96672ee5ed43414` |
| `gcr.io/distroless/static-debian13:nonroot` | `sha256:e2e927ec666bae08560abb3c55d0659eceabb657f56b6782ab500a9fc7f555e3` |
| `eclipse-temurin:25-jdk` | `sha256:8c0a84ea11c8f6ed52600fc19f1040121f2a162998e9f50a5faebbbad9172dcc` |
| `eclipse-temurin:25-jre` | `sha256:fcd7fd7b387f94bb2ac461478a7436ad8e349924c374ea8313919624dceae636` |
| `php:8.5-fpm-alpine` | `sha256:fa01fb1645cd0fc566a5f146b099adace33b906571f972f71f2182a7c12d1cd7` |
| `php:8.5-cli-alpine` | `sha256:93684051146ec037620855feb77f278090bde45ddc030801cd3f2a7685bc4deb` |
| `composer:2` | `sha256:af98f42dfff7c68ba8d53c2164fd9fde1087b7d449514baa38c418b1f6bc4bac` |
| `node:24.21.0-alpine` | `sha256:ebfe2f90462722a7a4de65e91990e97fe0d401c70e0e762c5b53302f905ec1c1` |
| `nginxinc/nginx-unprivileged:alpine` | `sha256:26b0bf6fbf07297983cb341998d79c831508787de26627dd2a112321b9c3a4af` |
| `postgres:18.6` | `sha256:5a5a84b19854a9ffaa54082c166ff4ec27473a361e496e5ea167f298f2da9722` |
| `valkey/valkey:9.1.2` | `sha256:418652cfb58ef879d4978c33553735d7147016032d5aefaa14c828e611eb9dfd` |
| `nats:2.15.0` | `sha256:cd3fcd4ecdda44e3a66728a5334af0a959bc3979b32810e033d1c547241cd0f4` |
| `registry:3` | `sha256:ddf754342cfc8acc51a56d5d0ab6af06826461864460636d8bd5c546dab2a7b8` |
| `ghcr.io/eclipse-ee4j/glassfish:8.0.4` | `sha256:29269d033eb2b1dbdd11fef0a0b119106792e6d8a963da395066da676a2f5faa` |

`nginx-unprivileged:alpine` y `composer:2` son tags flotantes: T2 los fija en su versión exacta al
escribir los Dockerfile. Las de observabilidad, en `logs/18-*`.

**Eclipse GlassFish 8.0.4** (`logs/50-*`): imagen oficial arm64 nativa de **1 GB**, que corre con
**JDK 21.0.12**, no con el 25 del curso. Trae Metro (`webservices-osgi.jar`, `metro-glue.jar`) y
JAXB (`jakarta.xml.bind-api.jar`): **los servicios SOAP de Contingencia no necesitan nada extra**.
Su instalación vive en `/opt/gfinstall`. → `a16`, T1b.

## H19 · Python, `venv` y el seed desde el Taskfile (03/10/2026)

Taskfile de prueba en `borrador/lab/`. La variable por sistema funciona con la función `OS` de Task:

```yaml
PYTHON: '{{if eq OS "windows"}}python{{else}}python3{{end}}'
VENV_PY: '{{if eq OS "windows"}}.venv\Scripts\python.exe{{else}}.venv/bin/python{{end}}'
```

Una subtarea interna `venv` con `sources: [requirements.txt]` y `generates: ['.venv/pyvenv.cfg']`
crea el entorno una vez: primera corrida 3,6 s, segunda 0,19 s y *"Task "venv" is up to date"*
(`logs/47-*`, `logs/48-*`). El seed con `faker==40.40.0` en `es_CO` y semilla fija genera
droguerías y productos con direcciones colombianas (*"Carrera 161M # 85-49 Este"*). **Trampa
encontrada:** el `python3` del `PATH` es el de pyenv (3.13.4), no el 3.14 de Homebrew: `a01` pide
"Python 3.12 o superior" en lugar de una versión exacta, porque el `venv` hereda la del sistema.
Windows y Linux: no verificados.

## H20 · Prototipo G0 de `pricing` (03/10/2026)

Prompt en `borrador/g0/prompt-g0-pricing.md`; código generado siguiéndolo sin agregar nada
(`borrador/g0/services/pricing/`): Go solo con biblioteca estándar, `GET /health/live`,
`GET /health/ready`, `GET /prices/{sku}` con JSON fijo, 404 en lo demás, log de texto libre.
Dockerfile multi-stage `golang` → `distroless/static:nonroot`, las dos por digest. **Imagen de
15,3 MB, arm64, usuario `nonroot`**; build en 12 s. La suite Hurl (4 peticiones, incluida la de que
`/metrics` todavía da 404) **pasa contra compose con Docker y con Podman** (`logs/51-*`, `logs/53-*`).
Hurl corre en un contenedor de la misma red de compose, sin publicar puertos. **El método de `a03`
funciona**; la regla "lo que el servicio NO debe tener todavía" escrita en el prompt se respetó.

## H21 · Incidente 27: el proxy que inspecciona TLS (03/10/2026)

**Reproducible en macOS con Podman**, sin tocar Docker Desktop: mitmproxy 12.2.3 (`mitmdump`) en un
contenedor de la máquina de Podman y `HTTPS_PROXY` al hacer `pull` dentro de la máquina
(`logs/54-*`):

```text
Error: unable to copy from source docker://alpine:3.21: initializing source docker://alpine:3.21: fetching manifest 3.21 in docker.io/library/alpine: pinging container registry registry-1.docker.io: Get "https://registry-1.docker.io/v2/": tls: failed to verify certificate: x509: certificate signed by unknown authority
```

Con la CA del proxy en `/etc/pki/ca-trust/source/anchors/` de la máquina y `update-ca-trust`, el
`pull` pasa. Con Docker Desktop **no se reprodujo** (exige cambiar su proxy en la configuración):
la entrada del cuaderno lo declara. **Traslado:** formato del cuaderno §4 (síntoma literal del 27).

## H22 · Libros base (03/10/2026)

| Libro | Edición que se cita | Nota |
|---|---|---|
| Burns, Beda, Hightower y Evenson, *Kubernetes: Up and Running* | 3.ª, O'Reilly, 2022 | no hay 4.ª |
| Lukša y **Kevin Conner**, *Kubernetes in Action* | 2.ª, Manning, marzo de 2026 | **suma coautor**; la guía §11 lo nombra solo a Lukša |
| Beyer, Jones, Petoff y Murphy (eds.), *Site Reliability Engineering* | O'Reilly, 2016 | de lectura libre en https://sre.google/sre-book/table-of-contents/ |
| Newman, *Building Microservices* | 2.ª, O'Reilly, 2021 | |
| Richardson, *Microservices Patterns* | 1.ª, Manning, 2018 | la 2.ª está en MEAP (estimada para 2027): se nombra como "en preparación" |
| Majors, Fong-Jones, Miranda y **Austin Parker**, *Observability Engineering* | 2.ª, O'Reilly, 2026 | **suma coautor**; casi reescrita |

**Traslado:** guía §11 (autores y edición) y §18.

## H23 · Cifras de la historia (03/10/2026)

Verificadas contra fuentes públicas; **ninguna contradice la historia**, así que no se corrigió nada:

- **Java SE Universal Subscription:** métrica por empleado (tiempo completo, medio tiempo,
  temporales, contratistas); tramo de 3.000–9.999 empleados a **USD 10,50** por empleado al mes.
  4.200 × 10,50 × 12 = USD 529.200 al año: "del orden de medio millón" se sostiene.
- **Nubes autorizadas** (AWS, Azure, Google): dos vCPU = una licencia de procesador con
  multithreading, y **la tabla de factor de núcleo no aplica**.
- **Base en espera:** en un entorno de recuperación, el primario y el *standby* se licencian
  completos; la regla de los 10 días es solo para el nodo de *failover* de un cluster con disco
  compartido. "Pagaba licencias como si atendiera" se sostiene.
- **Sharding de Oracle:** incluido en Enterprise Edition hasta **tres shards primarios**; con más,
  cada shard exige Active Data Guard, GoldenGate o RAC. La historia (dos regiones más el central)
  no cita un costo propio del sharding, y lo que suma la base partida son los procesadores de cada
  servidor y la herramienta de replicación. Se sostiene; una fase que lo cite debe decirlo así.
- **Sun:** Oracle completó la compra en enero de 2010. ✔
- **GlassFish:** en noviembre de 2013 Oracle anunció que no habría versión comercial de GlassFish
  Server 4.x y recomendó pasar a WebLogic, cuya licencia por CPU arrancaba en el doble. ✔
- **Siebel:** admite Oracle, Microsoft SQL Server e IBM DB2 como base. Sigue vigente, con
  actualizaciones mensuales (26.1 en enero de 2026 … 26.9 el 24/09/2026). ✔
- **Docker Desktop:** suscripción paga para uso profesional en empresas con **250 empleados o más,
  o más de USD 10 millones** de ingresos anuales. ✔

Fuentes: lista de precios y FAQ de Java SE de Oracle, *Licensing Oracle Software in the Cloud
Computing Environment*, *Licensing Data Recovery Environments*, *Database Licensing Information*,
anuncio de la hoja de ruta de GlassFish (noviembre de 2013, cubierto por InfoQ y The Register), blog
de Siebel CRM de Oracle, *Docker Subscription Service Agreement*. Varias de Oracle respondieron 403
a la descarga directa y se leyeron por sus resúmenes indexados: **se vuelven a abrir a mano antes de
que una fase cite un número**.

## H24 · Lo que P11 no cubrió, y dónde se cierra

- **B-00 con servicios y con `legacy`** → T2 y T1b (H11).
- **El incidente 27 con Docker Desktop** → se declara no reproducido (H21).
- **Probar la VM de Docker a 4 GiB** → T2, cuando haya servicios que medir; hoy no cambia ninguna
  decisión.
- **Windows 11 y Linux** → no se verifican (D9).

---

## Hallazgos de T1 y T1b (03/10/2026)

Logs en `logs/t1/` y `logs/t1b/`.

- **H25 · B-00 con tres corridas y las dos VM en 4 GiB.** Docker Desktop se llevó a 4 GiB
  (`MemoryMiB: 4096` en `settings-store.json`, con `docker desktop stop` y `start`); se devuelve al
  valor por defecto al cerrar la sesión. Resultados en `a01`. Con la misma memoria, los dos motores
  ocupan lo mismo dentro de la dispersión.
- **H26 · `docker desktop status` informa `stopped` con el motor respondiendo** (29.8.0). `engine.py`
  pregunta a `docker info`. → `a02`.
- **H27 · Jakarta EE 11 no incluye JAX-WS en `jakarta.jakartaee-api`**: hace falta
  `jakarta.xml.ws-api` 4.0.3 `provided`. GlassFish publica los endpoints EJB en la raíz
  (`/PriceService/PriceService`), no bajo el contexto del WAR, y un filtro de servlet no los ve
  (se usa un `SOAPHandler`).
- **H28 · Hibernate 7.4 en GlassFish 8**: sin `SunOneJtaPlatform` (hay que escribir una
  `AbstractJtaPlatform` con JNDI) y sin descubrimiento de entidades dentro del WAR (se listan en
  `persistence.xml`).
- **H29 · Volúmenes con nombre y usuarios no root** 🦭: con Docker, el volumen nuevo se crea como
  `root` salvo que la carpeta exista en la imagen con otro dueño; GlassFish (uid 1000) no podía
  escribir. Con Podman sin root sí pudo. Material para F03 y F05; arreglado en la imagen de
  Contingencia.
- **H30 · `podman compose` con imágenes ya construidas por `podman build` funciona**: compose
  encuentra `lab/legacy-*` aunque Podman las guarde como `localhost/lab/legacy-*`.
- **H31 · Con Docker, el cluster de kind revive solo tras `docker desktop restart`**; con Podman no
  (H16).
- **H32 · Un cluster de cada motor no puede publicar a la vez el mismo puerto**: el patrimonio en
  Docker y en Podman chocaron en `127.0.0.1:8081` (`bind: address already in use`).
- **H33 · `custom/init.sh` de la imagen de GlassFish** corre antes de levantar el dominio y sirve
  para crear el pool JDBC con `asadmin multimode` (`start-domain` … `stop-domain`).

---

## Hallazgos de T2 (03/10/2026)

Logs en `logs/t2/` (y `f01/`, `f02/`).

- **H34 · `docker stop` espera 3,1–3,2 s en Docker Desktop**, cuatro mediciones, aunque la
  documentación dice 10 s; con `-t 10`, 10,16 s. Podman, con el mismo proceso, esperó 10,2 s. Los dos
  terminan en 137 porque Node como PID 1 no atiende `SIGTERM`. No se encontró de dónde sale el valor
  de Docker Desktop (ejercicio 19 de la F01). → F01, F03, F16.
- **H35 · Un perfil de compose activo también enciende los servicios sin perfil.** `--profile legacy up
  -d` levantaba los cinco servicios nuevos; en un repositorio sin ellos habría fallado al construirlos.
  Las tareas `legacy:up`, `legacy:down` y `compose:down` nombran sus servicios. En Task 3.54, la
  condición `if:` con `[ … ]` no se cumplía; con plantilla (`{{if eq .CLI_ARGS "-v"}}`), sí.
- **H36 · Lo que la generación de G0 necesitó en el prompt**: `vite preview` responde 403 al nombre
  `storefront` (`preview.allowedHosts`); la plantilla de Nest 12 deja tipos de Vitest y el build falla
  con `TS2688`; Laravel se crea con `--no-scripts` y las rutas en el grupo `api` con `apiPrefix: ''`;
  en Spring Boot 4 el *starter* web se llama `webmvc`; `create-vite` fija versiones anteriores a las
  de `a01`. → `a03`.
- **H37 · Hurl 8 declara obsoleto `includes`** sobre colecciones (`contains` lo reemplaza).
- **H38 · `depends_on` sin condición y GlassFish**: la sincronización del portal falla con `SOAP-ERROR:
  Parsing WSDL` si se corre apenas termina `legacy:up`; un minuto después funciona. → F02.
- **H39 · Dos clusters de kind en motores distintos**: el segundo falla con `listen tcp
  127.0.0.1:8080: bind: address already in use`. → F00, `a01`.
- **H40 · La Braqui se cae sin base** (`ECONNREFUSED`, `Exited (1)`): la conexión está fuera del `try`.
  Es una maña del código y la F01 no la arregla.
- **H41 · `podman system df` contó 5,4 GB de imágenes y `system prune -a` recuperó 20,07 GB** (caché de
  build y capas). → F01.
- **H42 · Los servicios de G0 en compose**: 446 MiB con Docker y 421 con Podman; `inventory` 236 y
  `pricing` 7 con Docker. → `a01` (tercera entrega de B-00).
- **H43 · La imagen de `pricing` de G0 pesa 507 MB** con una sola etapa (`golang`), contra 15,3 MB del
  prototipo multi-stage de P11. → F04.

---

## Hallazgos de T3 (03/10/2026)

Logs en `logs/t3/`; las corridas descartadas, en `logs/t3/descartada/`. Docker Desktop en 4 GiB
durante la tanda (`MemoryMiB` en `settings-store.json`), restaurado al cerrar.

- **H44 · Quién es el proceso 1 decide el `stop`.** Con `docker stop -t 10`: Go (`pricing`) y la JVM
  salen con 143 en 0,12 s; `npm exec` reenvía la señal (143); Node y `php artisan serve` como
  proceso 1 agotan el tiempo (137). El `sh -c` de busybox hace `exec` del último comando y desaparece;
  el `dash` de Ubuntu (imagen de Temurin) se queda como proceso 1 y la JVM muere con 137 sin cerrar.
  `start.sh` sin `exec`: igual. → F03.
- **H45 · `docker kill` cuenta como detención manual**: `restart: always` no actúa. Un `kill -9` desde
  la máquina virtual sí lo dispara. Un contenedor `unhealthy` nunca se reinicia. → F06.
- **H46 · Docker 29 con containerd: `DISK USAGE` suma lo comprimido y lo descomprimido.** B-04 mide
  con `dive --json` (`image.sizeBytes`) y con el tamaño del archivo de `docker save`. → F04.
- **H47 · La primera corrida de B-04 midió la caché**: el arnés agregaba siempre el mismo cambio y,
  desde la segunda corrida, BuildKit reutilizaba la capa. Corregido con un comentario único por
  corrida; los crudos malos, descartados. → F04 §8.
- **H48 · El tag `alpine` de nginx sin privilegios es la línea principal (1.31.6)**; la estable es
  1.30.5 (`1.30.5-alpine` = `stable-alpine`). `a01` corregido a la estable (D17). → F04.
- **H49 · Lo que no corre en distroless ni en Alpine.** `exec: "sh": executable file not found`; se
  depura con `--pid=container:` y `--network=container:`. El `java` de Temurin copiado a Alpine da
  `not found` (falta el cargador de glibc). → F04.
- **H50 · Podman y kind.** Sin `KIND_EXPERIMENTAL_PROVIDER`, kind busca Docker (`failed to get docker
  info`); `kind load docker-image` con Podman: `not present locally`. `task images:load` (save +
  `image-archive`) carga las cinco con los dos motores. Podman no publica `127.0.0.1:80` en macOS
  (`gvproxy` sin privilegios). → F05.
- **H51 · La huella de las máquinas virtuales en el host.** Docker recién arrancado: VM 1.244 MB y
  `com.docker.backend` ≈2,9 GB; después de trabajar, la VM retiene su asignación (4.145 MB). La de
  Podman (`krunkit`) midió 7.369 MB tras trabajar y 3.110 MB minutos después: no comparable entre
  hipervisores. → F05, B-05.
- **H52 · `podman build` de `pricing` tarda el doble** (11,1 s contra 5,2); `inventory`, +6 %. → B-05.
- **H53 · `podman machine ssh` dentro de un script con heredoc consume la entrada estándar** y corta el
  resto del script: usar `</dev/null`.
- **H54 · `podman kube play` de un `Deployment` con `replicas: 2` crea un pod** (más su contenedor
  `infra`), y nadie lo reemplaza si muere. → F06.
- **H55 · `--scale` en compose con un cliente que reutiliza conexiones** (`fetch` de Node): en cuatro
  corridas, al menos una de tres réplicas sin tráfico. Con `wget`, del 29 % al 37 %. → F06.
- **H56 · Las imágenes de `inventory` (JRE) y `pricing` (distroless) no tienen `wget` ni `curl`**: el
  `healthcheck` de compose no es posible sin agregar herramientas. → F06, F15.

---

## Hallazgos de T4 (03/10/2026)

Logs en `logs/t4/`. Docker Desktop otra vez en 4 GiB durante la tanda.

- **H57 · D33 aplicada por la sesión, por defecto** (Oskar: "aplica D33 por default"): sin `PUT /stock`;
  movimiento `COUNT` que guarda la diferencia con signo; el primer movimiento crea la existencia con
  umbral 0. Contrato validado con `openapi-spec-validator`.
- **H58 · B-07 se midió sin apuesta previa.** Error de método, declarado en la F07 y en
  `BENCHMARKS.md`; las apuestas de T4 y T5 se escribieron antes en `logs/t4/00-apuestas-antes-de-ejecutar.md`.
- **H59 · Los dos clusters del curso no conviven**: los dos publican `127.0.0.1:8080` (`Bind for
  127.0.0.1:8080 failed: port is already allocated`). Uno a la vez. → F07.
- **H60 · Sin contexto activo, `kubectl` le habla a `localhost:8080`**, que en el laboratorio es la
  puerta del `Gateway`. → F07, `a04`.
- **H61 · El Kubernetes de Docker Desktop**: se enciende con `KubernetesEnabled` en
  `settings-store.json` (con el motor detenido; si se escribe con el motor arriba, Docker Desktop lo
  pisa al detenerse); deshabilitado sigue `Ready`; `reset-cluster` con Kubernetes habilitado lo
  recrea. Dos mediciones descartadas por eso. → F07, B-07.
- **H62 · Podman: k3d no arranca y minikube no une workers** (`no route to host`). → F07.
- **H63 · k3d trae Traefik, svclb, metrics-server y dos contenedores propios**; sin Traefik, 463 MiB.
- **H64 · `kubectl run -i` dentro de un script con heredoc se come el script** (como `podman machine
  ssh`): `--attach` y `</dev/null`. Y el chequeo de seguridad de la sesión bloquea `sh -c` anidados
  en `kubectl run`: se usó un programa en Python que lanza una petición por pod.
- **H65 · `kube-proxy` (modo iptables) rechaza al instante un `Service` sin endpoints** (`-j REJECT`):
  por eso el incidente 06 falla en 4 ms. → F08.
- **H66 · Borrar el pod de `replenish` tarda 31,1 s** (los 30 s de gracia: Node no atiende `SIGTERM`);
  borrar el namespace `apps`, 36,2 s. → F09, F16.
- **H67 · G1 pasó la suite al primer intento** con los cinco servicios, en compose y en el cluster, dos
  veces seguidas. Java 25 avisa del acceso nativo de `sqlite-jdbc`.
- **H68 · El pod de `inventory` figura listo antes de abrir el puerto**: la primera petición después de
  un `rollout restart` no tuvo respuesta. → F09, F15.
- **H69 · `minimo` con los cinco servicios de G1**: 319 MiB (304–373) de *working set*; la máquina
  virtual sube 295 MiB (279–337). → `a01`.

## T5 — F10, F11 y F12 (03/10/2026)

Logs en `logs/t5/`. Docker Desktop en 4 GiB durante la tanda.

- **H70 · `LoadBalancer` en kind**: `<pending>` sin implementador; con cloud-provider-kind v0.12.0,
  IP `192.168.0.7` que no llega al host en macOS (`curl: (28)`), y un contenedor auxiliar publicado en
  un puerto que elige Docker (`52587`). Deja una `GatewayClass` `cloud-provider-kind` que hay que
  borrar. → F10.
- **H71 · Envoy Gateway rechaza `URLRewrite` dentro de un `backendRef`** (*"URLRewrite path modifier
  is not supported within BackendRef"*, 500 en esa parte del tráfico). Se resolvió con una fachada
  nginx en el pod de Contingencia (8081) y un servlet REST de precios (`PriceFacadeServlet`). → F10,
  `a16`.
- **H72 · Strangler 80/20 exacto**: 160/40 en tres corridas de 200; 50/50 → 101/99. Una conexión por
  petición. Apuesta ganada. → F10, `INSTINTOS.md`.
- **H73 · Incidente 08: el `status` de la ruta queda viejo** (`Accepted=True` de la generación 3 con
  el objeto en la 4): el controlador no escribe en rutas que ya no se cuelgan de sus puertas. → F10,
  cuaderno, `a04`.
- **H74 · `externalTrafficPolicy: Local` (el valor por defecto de Envoy Gateway) con el proxy en un
  worker del perfil `lab`**: 10 s sin bytes; con `Cluster`, 0,020 s. → F10.
- **H75 · `*.localhost` resolvió en macOS con curl, Python y `dscacheutil`.** Windows y Linux sin
  verificar. → F10.
- **H76 · CORS verificado con Chrome sin interfaz** (`--headless=new --dump-dom`): con la
  `SecurityPolicy`, la lista; sin ella, `Failed to fetch`. → F10.
- **H77 · G1 desplegado dos veces: QA ignora su `API_BASE_URL`** y pide a `api.localhost`; con CORS
  cerrado, `Failed to fetch`; con CORS abierto al origen de QA, la página de QA lista los productos de
  producción sin un error. → F11 §4.
- **H78 · G2 con la plantilla de nginx** (`/etc/nginx/templates`, `envsubst` del entrypoint): funciona
  en `nginx-unprivileged` sin script propio. Suite G2 verde dos veces en cluster y en compose. → F11, `a03`.
- **H79 · La caché del navegador congeló G1 después de desplegar G2**: `index.html` sin
  `Cache-Control`. Con `no-cache`, el mismo perfil ve el despliegue siguiente. Corregido en el prompt
  de G2. → F11 §5.3.
- **H80 · `ConfigMap` montado: el archivo cambia entre 60 y 90 s** (dos mediciones); `envFrom` y
  `subPath` no cambian nunca; `pricing` siguió con el tope viejo 393 s (apuesta ganada). El reinicio
  borra los precios del `emptyDir`. → F11 §7, incidente 09.
- **H81 · Contingencia comprueba la contraseña SOAP** (HTTP Basic): rotar solo la punta del portal
  da `No autorizado`. Las dos puntas leen ahora el mismo `Secret`. → F11 §6.2.
- **H82 · La raíz del repositorio ignora todos los `.env`**: el `.env` del portal, que `a16` describe
  como versionado, no habría llegado a git. Se agregó `!legacy/portal/.env` al `.gitignore` de `src/lab`.
  Oskar: revisar al commitear que el archivo entre.
- **H83 · Contingencia figura lista antes de desplegar su servicio SOAP** (`Parsing WSDL: Couldn't
  load`), y una petición a `pricing` durante su reinicio recibió `upstream connect error`. → F15, F16.
- **H84 · Chrome sin interfaz se cuelga con `--virtual-time-budget`** en algunas páginas: se usó un
  envoltorio en Python con perfil nuevo y tiempo límite.
- **H85 · Los servicios dejan de avanzar juntos en G2**: `STEP_TAG` pasó a `STEP_TAGS`, un tag por
  servicio (el del último paso que lo cambió). → `Taskfile.yml`, `a03`.
- **H86 · Stock fantasma con dos réplicas sobre SQLite**: seis reposiciones de 5 (todas 201); veinte
  consultas dicen 10 (7 veces) o 20 (13); un ajuste de −12 se rechaza tres veces (409) y se acepta una.
  Ningún error en los logs (solo los avisos de acceso nativo de la JVM al arrancar). → F12 §4.
- **H87 · Postgres con `StatefulSet` propio y una base por servicio**: listo en 11,5 s; el `init.sh`
  del `ConfigMap` se *sourcea* (no es ejecutable) y funciona. Credenciales generadas en
  `.secrets/postgres.env` por `scripts/data/credentials.py`. → F12, contrato.
- **H88 · Testcontainers corre dentro de un contenedor** con el socket montado y
  `TESTCONTAINERS_HOST_OVERRIDE=host.docker.internal`; trae `testcontainers/ryuk:0.14.0`. → `a01`, F12.
- **H89 · B-12**: tarea 5,45 s contra 12,70 s (2,3x); `go test` 0,10 s contra 6,24 s (59x). SQLite
  acepta un precio de 3.000.000.000 en `INTEGER`; Postgres lo rechaza. Apuesta: tiempo perdida en la
  tarea, fidelidad ganada. → F12, `BENCHMARKS.md`.
- **H90 · El build de `pricing` pasó a 270 s**: `go mod download` también baja las dependencias de
  las pruebas (Testcontainers y su cliente de Docker). Imagen: 26,4 MB. → F12; B-04 de `pricing` queda
  desactualizado.
- **H91 · El servicio antes que su esquema**: `relation "prices" does not exist (SQLSTATE 42P01)`; el
  `Job` lo arregla sin reiniciar el servicio. → F12.
- **H92 · Dos migraciones de Laravel a la vez**: una falla con `duplicate key value violates unique
  constraint "pg_class_relname_nsp_index"` al crear la tabla `migrations`. → F12.
- **H93 · `task deploy` con el `ConfigMap` de topes restaurado no reinició `pricing`** (`unchanged`):
  siguió con el tope de 18.000 en memoria. El incidente 09, otra vez, sin buscarlo. → F12, F13.
- **H94 · Contingencia `OOMKilled` tres veces por el kernel del nodo** (sin límites, QoS `BestEffort`,
  `oom_score_adj 1000`) con el sistema, el patrimonio, Postgres, QA y dos réplicas de `inventory` en
  4 GiB. Se borró QA. → F15, `a01` (el presupuesto de `minimo` con todo).
- **H95 · La Braqui y Contingencia comparten tablas**: renombrar `dispatch.address` rompe a los dos
  (`EJBException` en Contingencia, `column "address" does not exist` en la Braqui). Revertido. → F12 §9.
- **H96 · Incidente 11**: `storageclass.storage.k8s.io "oci-bv" not found`; el pod en `Pending` con
  `pod has unbound immediate PersistentVolumeClaims`. → F12, cuaderno.
- **H97 · Postgres no arregla la carrera de `inventory`**: veinte reposiciones de 1 a la vez (todas 201) dejan la existencia en 9 y 4 con dos réplicas, y en 5 y 6 con una: leer y escribir la existencia no va en una transacción, y el pool de 5 conexiones lo destapa. Deuda para la F16 (G5). → F12 §7.
- **H98 · CORS es un filtro del estándar** (`HTTPRouteCORS`, soporte extendido, canal estándar desde
  Gateway API 1.5.0) y Envoy Gateway lo implementa: mismas cabeceras que la `SecurityPolicy`, más
  `access-control-max-age: 5`. El laboratorio pasó al filtro (`catalog/httproute.yaml` y QA); se borró
  `catalog/cors.yaml`. La F10 lo cuenta; el experimento de la F11 se hizo con la `SecurityPolicy`. → F10,
  `a05`.
- **H99 · El build en frío de `pricing` pasó de 5,8 s (B-04, G0) a 398 s (G3, una corrida)**: `go mod
  download` baja también las dependencias de las pruebas. → F12 📌, B-04 a revisar.
- **H100 · Dos URL de Gateway API cambiaron de ruta** (`/api-types/httproute/` y
  `/guides/migrating-from-ingress/` dan 404): se usan las guías de `/guides/…` y `/docs/concepts/…`.

## T6 — F13 y F14 (03/10/2026)

Logs en `logs/t6/`. Docker Desktop en 4 GiB durante la tanda (backup del settings-store en el
scratchpad); apuestas escritas antes en `logs/t6/00-apuestas-antes-de-ejecutar.md`.

- **H101 · El YAML plano de la Fase 12 se repite un 96 %**: 444 líneas sin comentarios entre los
  `Deployment`, `Service`, `HTTPRoute` y `Job` de migraciones de los cuatro backends; 429 iguales a las
  de `pricing` salvo el nombre. Un `kubectl scale` a mano lo revierte el siguiente `kubectl apply`. → F13 §4.
- **H102 · Helm 4 sigue enlaces simbólicos dentro del chart** y avisa en cada comando (`level=INFO
  msg="found symbolic link in path…"`): el `nginx.conf` de `catalog` queda con una sola fuente. → F13 §6.
- **H103 · Los nombres de plantilla son globales**: los subcharts usan `lab-common`, que es dependencia
  del paraguas; un subchart solo falla con `no template "lab-common.service" associated with template
  "gotpl"`. Dependencias en `charts/` sin `repository`: `helm lint` y `helm install` las aceptan. → F13 §5.2.
- **H104 · `task chart:compare`**: 24 objetos contra 23, 117 diferencias en 14 clases, ninguna en
  selectores, puertos, imágenes, variables ni volúmenes. Suites G1 y G2 en verde con el release. → F13.
- **H105 · La mudanza de `kubectl apply` a Helm**: `invalid ownership metadata` sin tocar nada; con
  `--take-ownership`, conflicto de SSA en las cinco `HTTPRoute` con `kubectl-client-side-apply`
  (release `failed`, `Deployment` ya aplicados); con `--force-conflicts`, pasa. → F13 §9.
- **H106 · Dueños compartidos que explotan después**: el `ConfigMap` de topes con `helm` y
  `kubectl-client-side-apply` como dueños; al cambiar la tabla, upgrade `failed` a medias (el
  `Deployment` con el hash nuevo, el `ConfigMap` viejo); la revisión siguiente con `FORCE=true` no
  reinició `pricing` (el hash ya era el nuevo): `ConfigMap` en 18.000, `pricing` cobrando hasta 20.000.
  Salida: `rollout restart`. → F13 §9 (autopsia).
- **H107 · Borrar y reinstalar: 15,7 s sin servicio** (sonda cada 100 ms a `pricing` y a `/config.json`),
  `task deploy` en 19,8 s; Helm queda como único dueño. → F13 §5.7.
- **H108 · Apuesta F13 ganada**: `kubectl set image` + `task deploy` → `conflict with "kubectl-set"`; la
  imagen manual se queda. `task deploy FORCE=true` (con `--force-conflicts`) la devuelve; `inc:fix` de 05,
  06 y 08 pasó a usarlo cuando hay release. → F13 §7, `INSTINTOS.md`.
- **H109 · Hook que no corre**: `pre-upgrade` con una imagen no cargada bloquea el `--timeout` entero
  (1:33 con 90 s) y no toca ningún `Deployment`; con `--rollback-on-failure`, `Rollback to 9` solo. Los
  hooks del mismo peso corren por nombre (catalog, inventory, pricing, replenish). → F13 §8.
- **H110 · Los `Job` de los hooks sobreviven a `helm uninstall`**, y `uninstall --wait` vuelve antes de
  que se vayan los pods. El seed `post-install` no corre si la instalación falló y lo que siguió fueron
  upgrades. → F13 §13.
- **H111 · `kubectl run -i --rm` perdía la salida de la suite** en pasos cortos (G2: el pod terminaba
  antes de conectarse; el código de salida sí llegaba). `task conformance TARGET=cluster` pasó a `run`
  sin `-i`, `kubectl wait --for=jsonpath='{.status.containerStatuses[0].state.terminated}'`, `logs` y
  salida con el código del contenedor. → `Taskfile.yml`, `a01`.
- **H112 · Cada build de Docker Desktop cambia el ID de la imagen** aunque todo salga de la caché (la
  atestación de procedencia lleva fecha): `kind load` vuelve a cargar el seed en cada `task deploy`
  (unos segundos). No se cambió. → nota.
- **H113 · `pricing` sale con error al recibir `SIGTERM`** (pod viejo en `Error` en cada rollout) y un
  `PUT` justo después de `rollout restart` recibió `upstream connect error`. → F15, F16.
- **H114 · La segunda cadena se crea sin tocar plantillas**: `platform/tenants/apps-b.yaml`,
  `credentials.py --tenant tenant-b` (Secret en `apps-b`, bases `<svc>_tenant_b` creadas con `\gexec`,
  repetible) y `values-tenant-b.yaml`. Seed con 40 droguerías (320 precios). → F14 §5.6, contrato.
- **H115 · Dos cadenas con el mismo host en la misma puerta**: las dos rutas `Accepted=True` y
  `RouteRulesOverlap=True`; gana la más vieja (regla de precedencia de Gateway API). Al recrear la ruta
  de `apps`, `storefront.localhost` sirvió la página de la segunda cadena. Con hosts propios
  (`*.tenant-b.localhost`), aislado. → F14 §8.
- **H116 · Apuesta F14 de memoria ganada**: `tenant-b` suma 212 MiB (191–227) a la VM; con las dos
  cadenas, 2.831–2.901 MiB de 3.916; `task deploy TENANT=tenant-b` en 23–25 s. → F14 §7, `a01` (B-00,
  quinta entrega).
- **H117 · helm-diff sin `--three-way-merge` no ve la deriva** (compara contra el release); con él, sí.
  `task deploy:diff` lo lleva siempre. → F14 §5.1.
- **H118 · `--rollback-on-failure` también falla con deriva**: el despliegue y el rollback chocan con
  `kubectl-set` (y con `kubectl … subresource "scale"` tras un `kubectl scale`); el release queda en
  `failed`. Salida: `FORCE=true`. → F14 §7 y §13; F16 (el HPA es dueño de `replicas`).
- **H119 · Rollback de la circular equivocada en 1,2 s**, tope de vuelta al instante (apuesta ganada); el
  precio volvió porque `pricing` aplica el tope al responder. → F14 §5.3, `INSTINTOS.md`.
- **H120 · Las migraciones de una revisión fallida quedan aplicadas**: con `replicas: dos`, los cuatro
  hooks corrieron (20 s) antes de que el `Deployment` fallara y Helm volviera. → F14 §5.2.
- **H121 · Ni `helm template` ni `--dry-run=client` ni `--dry-run=server` de Helm 4 rechazan
  `replicas: dos`**; sí `kubectl apply --dry-run=server --server-side`, el diff de tres vías y el
  despliegue. `values.schema.json` lo rechaza antes de renderizar (`got string, want integer`). → F14 §5.4.
- **H122 · Perfil `lab`**: una réplica de cada backend en cada worker; el control-plane tiene la marca
  `NoSchedule`; con tres réplicas de `inventory`, 2 y 1. G1 en verde. → F14 §5.5.
- **H123 · Kustomize (v5.8.1, dentro de kubectl 1.36.1) rechaza archivos fuera de su carpeta**
  (`security; file … is not in or below …`); con `--load-restrictor LoadRestrictionsNone`, el parche de
  dos réplicas funciona. → F14 §5.7.

## T7 — F15 y F16 (04/10/2026)

Logs en `logs/t7/`. Docker Desktop en 4 GiB; apuestas escritas antes en `logs/t7/00-apuestas-antes-de-ejecutar.md`.

- **H124 · Rollout de `inventory` sin sondas**: 2,8–3,3 % de peticiones perdidas (503, 1,3–1,5 s de corte);
  con la readiness de G4, 0, 1 y 0. La que queda es el pod viejo al morir (F16). Apuesta: primera mitad
  perdida, segunda ganada. → F15 §4, §5.1.
- **H125 · G4 en los cuatro backends**: readiness por la base con un segundo de límite; `inventory` sin
  Actuator (`ApplicationAvailability` + `isValid(1)`), Hikari a 2 s; `catalog` con `PDO::ATTR_TIMEOUT`;
  `replenish` con `connectionTimeoutMillis`. Suite G4 nueva (4 archivos) y G1 en verde. → `a03`, F15.
- **H126 · Envoy manda tráfico a endpoints no listos cuando no queda ninguno** (modo pánico):
  `health_flags::/eds_status_draining` y `lb_healthy_panic: 489`; por el `Service`, `Connection refused`.
  → F15 §5.2.
- **H127 · El pool de `pg` tumba a Node** cuando Postgres corta una conexión inactiva (`Unhandled 'error'
  event … terminating connection due to administrator command`); se agregó el manejador al prompt de G4.
  → F15 §6, `a03`.
- **H128 · Con la VM al 98 %** (un build de 600 MB junto al cluster), la liveness reinició `pricing`,
  `replenish` y `storefront` sanos; el nodo sin `MemoryPressure`. → F15 §5.3.
- **H129 · Memoria medida con `crictl stats`** (reposo/carga, MiB): `pricing` 6/13, `inventory` 216/250,
  FPM 31/56, nginx 7/10, `replenish` 31/63, `storefront` 7/7, Postgres 54, Contingencia 601 (GlassFish con
  `-Xmx512m` de fábrica). → F15 §5.4, chart.
- **H130 · Límite de CPU de 50m en `pricing`**: 39–61 req/s y p95 1,39 s, contra 1.126–1.392 req/s y p95
  46–60 ms sin límite. → F15 §5.4.
- **H131 · `-Xmx4096m` con límite de 512 MiB no mató** (222–243 MiB cinco minutos); `-Xms4096m
  -Xmx4096m` sí: `OOMKilled` a los 11 s, 5 veces en 5 min, 98,5 % de fallos; Serial GC con `NewSize`
  1.431.633.920. Sin opciones: heap máximo 128 MiB, 62 MiB comprometidos, contenedor 191–296 MiB, 0 fallos
  de 1.435.095. Se agregó `-Xmx4096m` a la historia (§1.6) y la autopsia usa `-Xms` + `-Xmx`. → F15 §9.
- **H132 · NMT con `jcmd` desde un contenedor efímero no funcionó** (`AttachNotSupportedException: Unable
  to open socket file /tmp/.java_pid1`); `kind load` de la imagen del JDK por digest falla (`content digest
  … not found`). → F15 ejercicio 21, F21.
- **H133 · Incidente 12 con `MaxRAMPercentage=95`**: sin `AlwaysPreTouch` no murió (345 MiB con carga);
  con `AlwaysPreTouch`, `OOMKilled` al arrancar y una sola línea de log. → cuaderno.
- **H134 · Incidente 14 en `catalog`**: con la liveness a 1 s y un fallo, 400 usuarios (FPM con 5
  procesos) reiniciaron nginx 4 veces, 99,5 % de fallos; con la del chart (2 s, 3 fallos), 0 reinicios y
  0 fallos, mediana 1,03 s. Con `inventory` y la liveness sobre `/health/ready`, no se reprodujo. → cuaderno.
- **H135 · Incidente 15**: en `apps`, la cuota rechaza antes (`exceeded quota`); se movió a Postgres en
  `data` (`Insufficient memory`, los cuatro backends `0/1`). Un `StatefulSet` no reemplaza solo un pod
  `Pending`: hay que borrarlo. → cuaderno.
- **H136 · Cuotas**: apuesta ganada (`exceeded quota: apps-b`, La Vecina 378/378). Un `kubectl patch` a la
  cuota no dura: `task deploy TENANT=` vuelve a aplicar el archivo. Con 512 MiB en el archivo, Helm espera
  10 min 15 s y desinstala. → F15 §7 y ejercicio 14.
- **H137 · AOT cache**: entrenamiento de 1,5 s con `spring.context.exit=onRefresh`, cache de 55 MB, imagen
  639 MB contra 570; Spring en 0,47–0,55 s contra 1,12–1,17 s; `Ready` en 2–3 s en los dos casos (apuesta
  perdida). El primer intento se colgó con la VM ahogada. → F15 §6.1.
- **H138 · G5 pasó la suite al primer intento** (`inventory.g5.hurl`, 9 peticiones, dos veces) y la
  carrera de la F12 quedó cerrada: 20 reposiciones a la vez con dos réplicas dejan 20, cinco de cinco
  (`SELECT … FOR UPDATE` con Postgres; `INSERT … ON CONFLICT DO NOTHING` para el primer movimiento). El
  `RestClient.Builder` autoconfigurado no está en el starter de webmvc de Spring Boot 4: se usó
  `RestClient.builder()`. → `a03`, F16.
- **H139 · La venta desde la página**, verificada con un cliente propio del protocolo de depuración de
  Chrome (Python, solo biblioteca estándar): preflight CORS a `inventory` con `POST` y `Content-Type`,
  `Venta SALE-000005: $12.900.` → F16.
- **H140 · Apagado y rollout de `pricing` a 200 req/s** (3 corridas por caso): sin apagado limpio ni
  `preStop`, 18–39 fallidas; con apagado limpio y sin `preStop`, 24–29; con `preStop` de 5 s (con o sin
  apagado limpio), 0. Apuesta ganada. → F16.
- **H141 · Incidente 17**: metrics-server v0.9.0 sin `--kubelet-insecure-tls`: `cpu: <unknown>/70%`,
  `error: Metrics API not available`, `x509: cannot validate certificate for 192.168.0.7 because it
  doesn't contain any IP SANs`; con el flag, `kubectl top` en 45 s. Manifiesto en
  `platform/metrics-server/` con la imagen por digest; tarea `platform:metrics`. → cuaderno, F16.
- **H142 · Encender el HPA con Helm quita `replicas` del `Deployment`**: el campo deja de ser de Helm y
  vuelve al valor por defecto (de 2 a 1 en `lab`). `kubectl scale` le quita a Helm el campo (H118). → F16.
- **H143 · El HPA pide réplicas a los 31–37 s** de empezar la carga (`pricing` 37, 37 y 32; `catalog` 31;
  `replenish` 31) y están listas 5–11 s después. Apuesta (más de 60 s) perdida. → F16.
- **H144 · `pricing` con límite de 64 MiB muere `OOMKilled` a 1.500 req/s** hacia los 16 s, antes de que el
  HPA reaccione; en una corrida, el pod en `CrashLoopBackOff` dejó al HPA en `<unknown>` y no escaló nunca
  (94 % de fallos). Su pico real con 1.500 req/s fue 59–64 MiB; el límite pasó a 128 MiB. → F16, chart.
- **H145 · La cuota de `apps` de la F15 no alcanza para el perfil `lab`**: un pod de `pricing` con 512 MiB
  de límite y un `Job` de migraciones quedaron `exceeded quota`, y el hook bloqueó el upgrade. Subida a
  1.536 MiB de requests y 3 GiB de limits. → F16, `deploy/manifests/namespace.yaml`.
- **H146 · `catalog` escalado a cuatro réplicas no alcanza 400 req/s** (315/s, mediana 1,17 s): la
  capacidad de PHP-FPM son sus procesos (`pm.max_children = 5` por pod), y el CPU sube igual. `replenish`
  sostuvo 400/s con p95 de 124 ms. → F16.
- **H147 · B-16 a 300 req/s** (perfil `medicion` sobre `lab`): `pricing`, `inventory` y `replenish` cumplen
  p95 < 100 ms con una réplica; `catalog` necesita dos (147 → 45 ms) y con tres empeora (162 ms); memoria
  por réplica: 28, 208, 52 y 46 MiB (Java/Go 7,4x). Apuesta perdida en las dos mitades. → F16, `BENCHMARKS.md`.
- **H148 · Incidente 16**: la condición `ProgressDeadlineExceeded` apareció a los 16 min, no a los 120 s del
  plazo; el log del controlador tenía errores de caché (`read version … is not as new as written version`).
  No se explicó. → cuaderno.
- **H149 · El aviso sin timeout no se pierde enseguida**: con `replenish` en cero, la venta dio 201 y el
  hilo del aviso esperó; al volver `replenish`, el aviso llegó 2 min 13 s después. Venta sin `catalog`: 503
  al instante. Borrar un pod de `pricing` con `preStop`: 6,1 s. → F16 ejercicios, F22.

## T8 · F17 y F18 (04/10/2026)

- **H150 · `prom-client` 15.1.3 está deprecado** (`npm warn deprecated … replaced by
  @prometheus-io/client`); la heredera oficial, `@prometheus-io/client` 0.16.1, tiene la misma API
  (`Histogram`, `register`, `collectDefaultMetrics`) y pasó la suite sin cambios. → a03 G6, a01.
- **H151 · PHP-FPM con el almacenamiento en memoria del proceso no cuenta nada**: 0 de 200 peticiones
  en `/metrics` (dos corridas), y el `/metrics` de recién tampoco, porque se mide después de escribirlo.
  Con APCu, 200 de 200. La apuesta (menos del 30 %) se quedó corta: no es un hijo de cinco, es ninguno.
  → F17 (autopsia), a03 G6.
- **H152 · Las cuatro librerías nombran distinto la petición sin ruta**: Spring Boot 4 la etiqueta
  `uri="/**"` y no se cambia barato; `pricing`, `catalog` y `replenish` se alinearon a ese valor. Spring
  agrega `outcome`, `error` y `exception`; el contrato acepta etiquetas de más. `inventory` expone 501
  líneas en `/metrics` en reposo; `replenish`, 229. → OpenAPI, F17.
- **H153 · Las suites de G4 fallan con las imágenes de G6**, por diseño: pedían 404 en `/metrics`. Como
  con cada paso anterior, la suite de un paso valida la imagen de ese paso. → a03.
- **H154 · La VM de 4 GiB se ahogó con el perfil `lab`, Prometheus, Grafana arrancando y 10 visitas/s de
  k6**: en un minuto k6 llegó a 100 VU (`Insufficient VUs`), el servidor de API dio `TLS handshake
  timeout`, Docker dejó de responder unos 8 minutos, y los pods de `lab-worker2`, el scheduler y el
  controller-manager se reiniciaron por sondas. Dentro de la VM: carga 85, swap con 52 MB libres de 1 GiB,
  PSI de memoria `full avg60=46` y de I/O `full avg60=50`, con `MemAvailable` de 1,1 GB. En el host
  (macOS, 32 GB), 31 GB usados, 7,5 GB comprimidos y 1,3 GB de swap: el proceso de la VM tenía 7,2 GB
  residentes. Bajar Grafana a cero y esperar lo normalizó. → F17 (presupuesto), a01.
- **H155 · El Kubernetes propio de Docker Desktop estaba encendido en la máquina virtual** (contexto
  `docker-desktop`, nodo `desktop-control-plane` 1.36.1, creado hace 15 h, antes de esta sesión, y no lo
  toqué): su nodo no aparece en `docker ps` y se ve solo como un cgroup de `/sys/fs/cgroup/docker/` con
  kubelet, containerd y su plano de control; con su `cloud-provider-kind` y su registry, 764 MiB en memoria
  y 115 en swap. Es la parte de H154 que no es del curso. Cambió: a01 y el contrato piden apagarlo; las
  mediciones de la F17 siguieron con él encendido, en el cluster `lab` con una réplica por servicio.
  **Pendiente de Oskar:** confirmar si estaba encendido en P11 (B-00 lo incluiría en "cluster recién
  creado") y decidir si B-00 se repite sin él. → a01, contrato §5, F17 §5.5.
- **H156 · Memoria de la observabilidad, pieza por pieza** (cluster `lab` con valores de `minimo`, 3 ciclos):
  Prometheus sola 43–73 MiB, con Grafana 52–90; Grafana 248–254; a los 20 min con 2 visitas/s,
  Prometheus 99 y Grafana 231. La memoria usada de la VM quedó en 2.642–2.764 MiB en todos los estados:
  con swap lleno no mide nada. Apuesta: empate (Prometheus < 100 por poco; Grafana < 300). → a01 B-00
  sexta entrega, F17 §8.
- **H157 · La ruta cruda como etiqueta**: con 2.000 SKU distintos, las series de `pricing` pasaron de 123
  a 28.095 (×228) y las totales de 2.447 a 30.567; el heap de Prometheus, de 65 a 118 MiB y a 172 cinco
  minutos después. El primer intento salió con 235 SKU porque `__ITER` de k6 es por VU (se usa
  `exec.scenario.iterationInTest`). Apuesta ganada. → F17 §9.
- **H158 · El costo de instrumentar `pricing` no se pudo medir**: a 300 req/s, p95 de 38–106 ms con la VM
  en swap (en B-16 era 4 ms); medianas 1,8–2,3 ms con G5 y 1,8–2,2 con G6. Sin decidir. → F17 §7.
- **H159 · El contador que vuelve a cero**: borrar `inventory` con tráfico dejó `lab_sales_total` crudo en
  0; `increase(…[6m])` dio 32,3 contra 32,7 ventas (201 de `/sales`); ventas por minuto, nunca bajo 2,7.
  Apuesta ganada. → F17 §7, ejercicio 14.
- **H160 · El seed siembra 8 productos y ninguna existencia**: la primera versión del tráfico de fondo
  vendía 20 SKU y el 72 % de las ventas daba 422 (`catalog no conoce`). `bench/trafico/la-vecina.js` cuenta
  500 unidades de los 8 en cada droguería al empezar. Micrometer publica 69 buckets por combinación (828
  series de buckets de `inventory` contra 72 de `pricing`); cAdvisor publica 1.533–3.178 muestras por nodo y
  quedan 18 tras el `metric_relabel_configs`. → F17 §5.3, §6.
- **H161 · G7, lo que escribe cada runtime en texto**: Nest arranca con colores ANSI; Spring con banner y,
  con sqlite-jdbc, cuatro `WARNING:` de acceso nativo de Java 25 (se callan con
  `--enable-native-access=ALL-UNNAMED`); con `JAVA_TOOL_OPTIONS`, `Picked up JAVA_TOOL_OPTIONS: …`, sin
  forma de callarlo (única excepción del verificador; el chart no lo pone por defecto). PHP-FPM: línea de
  acceso en texto y avisos de arranque (`access.log = /dev/null`, `log_level = warning`); **no** envuelve las
  líneas del hijo (la imagen trae `decorate_workers_output = no`; sí trae `log_limit = 8192`). nginx: 22
  líneas de texto al arrancar (entrypoint y `[notice]`), resueltas con un `nginx-main.conf` propio y
  `NGINX_ENTRYPOINT_QUIET_LOGS=1`. Spring ignoró en silencio `rename.@timestamp`: hace falta
  `rename[@timestamp]`. Apuesta de los defectos: perdida en lo importante. → F18 §6, a03 G7.
- **H162 · Envoy Gateway pone `x-request-id` y reemplaza el del cliente** (`venta-de-prueba-f18` llegó como
  `08a30398-…`); la venta con aviso se encontró con una consulta en inventory, catalog (Laravel y nginx),
  pricing y replenish, y la línea del aviso en el hilo virtual con el mismo id. → F18 §5.3.
- **H163 · Fluent Bit: dos pods en `lab`**, por el taint `node-role.kubernetes.io/control-plane:NoSchedule`;
  5,6–7,3 MiB cada uno. Loki 91–117 MiB (107 tras reiniciar). 10 min a 2 visitas/s: 5.853 líneas, 1,29 MB,
  6 flujos. En reposo, 2 min: 253 líneas, 177 de sondas y 40 de scrapes, 54,5 KB. → F18 §8, a01.
- **H164 · `request_id` como etiqueta de Loki**: 5.001 flujos (límite 5.000), Loki 90 → 145 MiB, 429
  `maximum active stream limit exceeded`, Fluent Bit `chunk … cannot be retried` (589 y 727 líneas de
  error); en 7 min, Loki recibió 1.506 de 1.958 peticiones de pricing (y parecido en los demás): cerca de 1
  de cada 4 perdida. Con las etiquetas del chart, 0–3 % de diferencia. Apuesta ganada. → F18 §9.
- **H165 · `catalog` con `LOG_CHANNEL=stack`**: 1.000 peticiones, 0 líneas en la salida, 186.899 bytes en
  `storage/logs/laravel.log` (capa escribible). Cobra la promesa de F01. → F18 §5.1.
- **H166 · El `kubectl set image` de una medición dejó a `kubectl-set` co-dueño de la imagen de `pricing`**,
  y dos `task deploy` siguientes fallaron con conflicto (uno de ellos, el `obs:off` antes de los builds,
  sin que se notara); `FORCE=true` lo resolvió. Con la VM en swap, un build de `pricing` tardó 19 min. →
  bitácora.

## T9 · F19, F20 y F21 (04/10/2026)

- **H167 · HTTPS en la puerta**: listener `https` en el 8443 con el `Secret` `lab-tls`, y el puerto `https-8443`
  (NodePort 30443) en el patch del `EnvoyProxy`. Envoy Gateway sirvió un `Secret` cambiado en menos de 5 s sin
  reinicios. Sin listener, `curl: (35) … SSL_ERROR_SYSCALL`. → F19 §5.2.
- **H168 · Envoy Gateway y los certificados vencidos**: uno **ya** vencido no lo carga
  (`ResolvedRefs=False … certificate api.localhost has expired since …`, el listener `Programmed=False`, y
  `SSL_ERROR_SYSCALL` para todos los nombres); uno que vence **estando cargado** lo sigue sirviendo, con el
  listener en `ResolvedRefs=True`, y el cliente ve `certificate has expired` (certificado de 2 min: 200 a las
  14:49:02, rechazo a las 14:51:32). El incidente 18 se arma con el segundo. → F19 §9, cuaderno 18.
- **H169 · cert-manager v1.21.2 y trust-manager v0.25.0** por OCI con imágenes por digest (los charts aceptan
  `image.digest`); trust-manager con `defaultPackage.enabled: false`; el `Bundle` es `trust.cert-manager.io/
  v1alpha1`. El `Certificate` tomó el `Secret` hecho a mano en 1 s. Renovación de un certificado de 1 h a los 5
  min con 5 peticiones HTTPS/s: 2.226 bien, 0 mal, serial nuevo servido en el segundo de la renovación, sin
  reinicios. Memoria: 133,8 MiB los cuatro pods. Apuestas ganadas. → F19 §5.4, §8.
- **H170 · G8**: `pricing` con un 8443 mTLS (Go, `GetCertificate` que relee) e `inventory` con el *SSL bundle*
  PEM de Spring Boot 4 (`SslBundles` está en el núcleo; `ClientHttpRequestFactoryBuilder` no, porque vive en un
  módulo que el servicio no trae: `JdkClientHttpRequestFactory` con el `SSLContext`). Sin certificado de cliente:
  `tlsv13 alert certificate required` en el cliente y `tls: client didn't provide a certificate` en `pricing`, sin
  línea `request`. Costo en la venta (10/s, 3×30 s): medianas 24,7–26,9 ms con mTLS y 25,5–26,0 sin él. La
  primera tanda midió ventas sin existencia (409): descartada. → F19 §5.6, §8.
- **H171 · Registry propio**: `registry:3` por digest con certificado de la CA; Docker sube a `localhost:5001`
  sin validar (`InsecureRegistryCIDRs: [::1/128 127.0.0.0/8]`); el nodo falla con el literal del incidente 24 y
  `task registry:trust` lo arregla en 1,1 s sin reiniciar (pull en 141 ms). → F19 §5.7, cuaderno 24.
- **H172 · El kubelet y los registros de imágenes traídas**: después de traer `lab-registry:5000/lab/pricing:g8`
  a `lab-worker2`, el `Job` de migraciones con `lab/pricing:g8` (cargada con `kind load`, el mismo digest) falló
  con `pull access denied` teniendo la imagen: `/var/lib/kubelet/image_manager/pulled/` tenía un
  `ImagePulledRecord` del digest con `credentialMapping` solo para `lab-registry:5000/lab/pricing`. Recargar la
  imagen y borrar el registro no alcanzó: hizo falta `systemctl restart kubelet` en el nodo. Dos `task deploy`
  fallaron por esto y Helm hizo rollback. → F19 §5.7, cuaderno 24, a04.
- **H173 · Incidentes 19–23 provocados con `inc.py`**: 19 (`issuer=… CA otra`, `Verify return code: 21`), 20 (`no
  alternative certificate subject name matches target host name 'storefront.localhost'`, la API en 200), 21
  (`kubectl create secret tls` valida el par: `tls: private key does not match public key`; el YAML aplicado no,
  y el listener queda `InvalidCertificateRef`), 22 (`ClusterIssuer` `ErrGetKeyPair: … secrets "lab-ca" not
  found`, `CertificateRequest` con `IssuerNotReady`, el pod en `ContainerCreating` con `FailedMount`; el arreglo
  dejó un rollout en `ProgressDeadlineExceeded` que se recuperó solo), 23 (`(certificate_required) Received fatal
  alert`). → cuaderno.
- **H174 · La confianza en el llavero del host no se instaló**: es un cambio de la máquina de Oskar con
  permisos de administrador. La fase lo marca sin verificar. **Pendiente de Oskar.** → F19 §5.3.
- **H175 · `runAsNonRoot` sin números**: fallan `inventory`, `catalog` y `replenish` (`container has runAsNonRoot and
  image has non-numeric user (inventory|www-data|node), cannot verify user is non-root`); pasan `pricing` (65532) y
  `storefront` (101). Apuesta perdida. UID reales: 10001, 82, 1000; nginx de `catalog`, 101. → F20 §5.1.
- **H176 · Raíz de solo lectura**: sin `/tmp`, `inventory` no arranca (`Unable to start web server`) y el `storefront`
  tampoco (`20-envsubst-on-templates.sh: … can't create /etc/nginx/conf.d/default.conf: Read-only file system`); con
  `emptyDir` en `/tmp` (y `conf.d` en el `storefront`), G5, G7 y G8 pasan igual. `replenish` no escribe nada. → F20 §5.2.
- **H177 · G8 rompió el seed de la segunda cadena**: con `PRICING_URL` en `https` en el `ConfigMap` de vecinos, el seed
  de `tenant-b` falló con `CERTIFICATE_VERIFY_FAILED` y Helm desinstaló el release. La dirección mTLS pasó al `env`
  del `Deployment` de `inventory`. → F19 §5.6, a03 G8, contrato.
- **H178 · RBAC**: `403 secrets "db-prueba" is forbidden: User "system:serviceaccount:diagnostico:default" cannot get
  resource "secrets"…`; con un `Role` de `get` sobre ese `Secret`, 200; `can-i list secrets` sigue en `no`. Con
  `automountServiceAccountToken: false`, la carpeta del token no existe. → F20 §5.3.
- **H179 · `NetworkPolicy` con las dos cadenas** (kindnet): sin políticas, desde `apps-b`: 200, 200, 200 y conecta a
  Postgres; con ellas, timeout a `apps`, 200 a su cadena, conecta a Postgres; desde `default`, timeout a todo. Las sondas
  del kubelet siguieron pasando. Un pod del `Job` de migraciones de `inventory` terminó en `Error` al aplicar las
  políticas y el `Job` completó al reintentar (sin explicar). Apuesta ganada. → F20 §5.4, §8.
- **H180 · Incidente 26**: sin `allow-dns`, la venta por la puerta da `504` con `upstream request timeout` a los 16,2 s;
  adentro, `lookup pricing: EAI_AGAIN` y por IP conecta. `task deploy` como arreglo falló (el hook de migraciones no
  resuelve y Helm hace rollback). `helm get manifest` **no lleva el namespace**: el primer `inc:fix` aplicó el release
  entero en `default` (borrado enseguida); `inc.py` pasa `-n apps`. Apuesta ganada. → F20 §9, cuaderno 26.
- **H181 · Incidente 25**: la imagen de Postgres declara `User=""` (root) → `container has runAsNonRoot and image will
  run as root`; con `runAsUser/runAsGroup/fsGroup: 999` arranca y quedó así en `statefulset.yaml`. `inventory` tardó
  unos minutos en reconectar a la base (Hikari). La imagen `postgres@sha256:5a5a…` ya estaba en el motor del host (inventario
  inicial): no se borra al cerrar. → F20 §6, cuaderno 25.
- **H182 · Con las `NetworkPolicy`, un vecino en cero réplicas ya no se rechaza: se espera**. `catalog` en 0: la venta
  por la puerta da `504` (`upstream request timeout`) a los 15,0–15,2 s, sin línea en `inventory`; en la F16, sin
  políticas, era 503 al instante (`catalog no contesta`). Y la venta de las 17:26, dada por fallida al cliente, se
  registró con `201` y `duration_ms: 145843` cuando `catalog` volvió (el `RestClient` sin timeout esperó). → F21 §4 y
  §5.9, F20 §8, F22 (el timeout), F26 (la venta duplicada).
- **H183 · `jcmd` desde un efímero funciona** con `runAsUser` a nivel de pod (el efímero hereda 10001): `jcmd -l`,
  `VM.flags` (`MaxHeapSize=134217728`, `UseSerialGC`) y `GC.heap_info`. En la F15 no contestó porque el efímero
  corría como root. `kubectl debug` sobre `pricing` (distroless) ve `/pricing` como PID 1, como 65532. `port-forward`
  al `Service` funciona con las políticas puestas. La apuesta de F21: mitad (los procesos sí; el `jcmd` contestó).
  k9s 0.51.0: solo `k9s info`; abrirla contra el cluster no se pudo sin terminal interactiva (**pendiente de Oskar**).
  → F21 §5.7, §5.8, deuda de F15.
- **H184 · Casos de práctica de F21**: `-XX:MaxRAMPercent=75` → `Unrecognized VM option 'MaxRAMPercent=75'` en `logs
  --previous`, `Exit Code: 1`, la réplica vieja atendiendo; la ruta de `pricing` cambiada a `/precios` → 404 por la
  puerta y 200 por `port-forward`. Durante la F20 se perdió dos veces el log de un `inventory` que no arrancaba por
  leerlo después de un `task deploy` (la autopsia de F21). → F21 §5.4, §5.5, §9.

## T10 · F22 y F23 (04/10/2026)

- **H185 · La VM se volvió a saturar con las dos cadenas, cert-manager y el generador**: el `task chaos:on` falló
  (`inventory` en `ProgressDeadlineExceeded`, y el rollback no pudo llamar al *webhook* de cert-manager: `connection
  refused`); Envoy Gateway con 34 reinicios, metrics-server con 38. Se desinstaló `tenant-b` (la F20 ya había
  terminado) y la presión de memoria bajó del 54 % al 20 % en unos minutos. → bitácora.
- **H186 · La cascada sin G9** (`inventory:g8`, 50 ventas/s, 10 lecturas/s, 60 s): sin fallas, existencias p95 17,61 ms y
  ventas p95 73,41 ms; con 5 s de latencia en `catalog`, existencias med 2,39 s y p95 5,54 s con 6,64 % fallidas, ventas
  med 7,22 s y 6,95 % fallidas. Apuesta ganada. Con G9: existencias p95 10,9 ms; ventas 100 % fallidas en 3,21 ms de
  mediana; `catalog` recibió 89 peticiones en el minuto. → F22 §4, §5.5.
- **H187 · Reintentos con 50 % de errores** (10 ventas/s, 30 s): ingenuos (4 intentos, sin espera, sin circuito) 6,64 %
  fallidas y 1,85 peticiones por venta; sin reintentos, 49,83 % y 1,00; **G9, 95,68 % fallidas y 0,09**: el circuito al
  50 % se abre con 50 % de errores. *Sogamoso con lluvia* (3 s al 50 %, 20 % de errores) con G9: 87,37 % fallidas.
  Apuesta ganada; la tabla, no apostada. → F22 §5.3, §8.
- **H188 · El circuito abierto** con 100 % de errores: `catalog` recibe 0 salvo 3 llamadas de prueba cada 10 s; ventas
  con mediana de 4,79 ms. Malformada al 100 %: 503 en 0,72 s tras 3 intentos (el error de conversión se reintenta);
  colgada al 100 %: 503 en 6,36 s (3 × 2 s). Apuesta ganada. → F22 §5.4, §5.6.
- **H189 · Los tropiezos de G10 al construir**: el agente de Java bajado con `ADD --checksum` quedó con permisos 0600 y
  el usuario 10001 no podía leerlo (`Error opening zip file or JAR manifest missing`): `ADD --chmod=644`. `catalog`
  falló dos veces en `composer install`: `opentelemetry-auto-laravel` exige la extensión `opentelemetry` y su registro
  (`_register.php`) lanza en el `dump-autoload` aunque se ignore el requisito de plataforma; la extensión va también en
  la etapa de build. El JVM con el agente escribe dos líneas de texto a stdout (el aviso de CDS y `[otel.javaagent …]`)
  que rompían la suite de G7: quedan declaradas como excepciones en `logs.py`. → F23 §5.6, a03.
- **H190 · La huella de G10 en cada imagen** (`docker history`, capas sin comprimir): `pricing` +5,7 MB de binario
  (gRPC y SDK compilados, ninguna línea de Dockerfile nueva); `inventory` +20,1 MB de dependencias (gRPC) y +26,4 MB del
  agente; `catalog` +7,0 MB de `vendor` y +0,7 MB de la extensión; `replenish` **+80 MB de `node_modules`** (30 → 110 MB)
  por `auto-instrumentations-node`. Líneas de Dockerfile: Java 4 (el `ADD` y el `CMD`), PHP 2 (el `pecl install` en las
  dos etapas), Node 1, Go 0. La apuesta de "PHP agrega más líneas": perdida; la fricción de PHP fue otra (la extensión
  en las dos etapas). → F23 §5.6, §8.
- **H191 · B-23, el reparto** (3 réplicas de `pricing`, 20 ventas/s, 30 s, 3 corridas): gRPC por el `Service` normal,
  600 de 600 llamadas a una réplica en las tres (cuál, cambia por corrida); `Service` *headless* y `round_robin`,
  200/200/200. Mediana de la venta igual en los dos (23,6–25,4 ms contra 23,1–24,5). Apuesta ganada. → F23 §4, B-23.
- **H192 · HTTP ya estaba pegado desde la F19**: con gRPC apagado, el precio por el 8443 también fue 100 % a una
  réplica (1,0 · 0,998 · 1,0). El 8443 de Go negocia HTTP/2 (`ALPN: server accepted h2`, `curl` desde un efímero en el
  pod de `inventory` con su certificado) y el `HttpClient` del JDK pide HTTP/2 por defecto; una conexión establecida
  al 8443 en toda la corrida (leído en `/proc/<pid>/net/tcp*` desde el nodo). La apuesta de "HTTP/1.1 > 50 %" partía de
  una premisa falsa; corregida antes del modo `http1`. Medianas por HTTP/2: 23,4–24,0 ms (gRPC: igual). → F23 §4, §8.
- **H193 · `MaxConnectionAge` de 10 s con el `Service` normal**: la más cargada 100 %, 100 % y 70 % en 30 s (apuesta
  de 40–70 %: perdida). Las reconexiones ocurren cada ~10 s (conntrack); en 60 s, 5 de 6 cayeron en la misma réplica,
  y en 180 s, 6/6/6. El azar de kube-proxy, aparte, con 30 conexiones de `nc`: 7/13/10. La edad empareja el promedio
  largo, pero en cada instante trabaja una sola réplica. → F23 §5.4.
- **H194 · La réplica nueva** (2 → 3 réplicas a los 20 s de 60): con `round_robin` sobre el *headless*, la nueva recibió
  **0 de 1200** llamadas (grpc-java no vuelve a resolver el DNS mientras nada falle); con `round_robin` y edad de 10 s,
  237 de 1201 (lo ideal en sus 40 s, ~267). Apuestas ganadas. → F23 §5.5, §12.
- **H195 · HTTP/1.1 de verdad (`http1`: el 8080, sin mTLS)**: la más cargada 100 %, 50 % y 50 % (el pool del JDK abre una o
  dos conexiones a 20 ventas/s), y en las tres corridas una réplica quedó en **cero**. Mediana 23,1–24,0 ms. La apuesta
  corregida ("< 60 %"): ganada en la mediana, perdida en lo que importaba. → F23 §4, §8.
- **H196 · Tempo 3 no arrancó la primera vez que se encendió**: el subchart de la T8 traía `compactor:` (de Tempo 2), y
  Tempo 3.1.0 lo rechaza (`field compactor not found in type app.Config`). La retención ahora es
  `backend_worker.compaction.block_retention` (sacado de `-help-all` del binario, y probado en un contenedor aparte antes
  del cluster). Con log en `warn`, Tempo escribe un `error calling scheduler … no jobs found` cada 15 s sin que sea un
  error. → F23 §13, a01.
- **H197 · El `kubectl scale` de B-23 le deja `.spec.replicas` a kubectl**: el `task obs:on` siguiente (sin `FORCE`) falló
  con `conflict with "kubectl" with subresource "scale"`; con `FORCE=true` pasó. Y la VM se volvió a saturar con
  observabilidad completa, trazas y el agente de Java (presión de memoria `full avg300=37 %`, 800 MB de swap; el
  scheduler, metrics-server y trust-manager en `CrashLoopBackOff`). Las trazas se verificaron con Prometheus y Grafana
  apagados, consultando la API de Tempo. → bitácora, F23 §13.
- **H198 · La primera traza de una venta** (`f23-traza-01`, por `port-forward` a `inventory` porque la puerta estaba caída
  por la saturación): 11 spans y **tres servicios, no cuatro**. `inventory` (servidor, cliente HTTP a `catalog`, cliente
  gRPC, JDBC), `catalog` (servidor y su `SELECT`), `pricing` (servidor gRPC); el mismo `trace_id` en las líneas de log de
  `inventory` y `pricing`. **`replenish` no está**: el aviso sale en `Thread.ofVirtual().start(...)`, que no hereda el
  contexto (como no heredaba el MDC), y su línea de log en `inventory` sale sin `trace_id`. La venta tardó 2.416 ms, de
  ellos 1.972 ms en el span de cliente gRPC, contra 8,7 ms del servidor de `pricing`: el tiempo se fue en la conexión, con
  el cluster saturado. Ventas siguientes: 872, 320 y 341 ms en `inventory` (B-23 daba 24 ms en un cluster sano). La
  apuesta de "una traza con los cuatro servicios": perdida. Pendiente: el arreglo (propagar el contexto al hilo del aviso)
  y la verificación con el cluster sano. → F23 §5.6, §5.7.
- **H199 · Grafana y Prometheus quedaron huérfanos** en `observability`: los creó la revisión 86 (fallida) y Helm solo
  borra lo que estaba en la última revisión buena. Con `observability.metrics/dashboards` en `false`, la 91 no los tiene en
  su manifiesto y siguen corriendo (Prometheus en `CrashLoopBackOff`). Borrarlos a mano quedó **pendiente de Oskar**.
- **H200 · La traza completa, con el contexto pasado al hilo del aviso**: `inventory` envuelve la tarea del hilo virtual
  con `Context.current().wrap(...)` (la API de OpenTelemetry que gestiona Spring Boot, 1.62.0; el agente 2.32.0 la
  enlaza). La línea del aviso sale con el `trace_id` de la venta, y la traza tiene **14 spans de los cuatro servicios**,
  con el `POST` a `replenish` terminando después que la venta. Venta en caliente: 51,6 ms en total, 5,2 ms del cliente
  gRPC y 0,9 ms del servidor. La primera venta después del reinicio: 1.358 ms, de ellos 826 ms en el cliente gRPC contra
  14,3 ms del servidor (el canal se abre en la primera llamada). → F23 §5.7.
- **H201 · Tempo en reposo**: 132 MiB y 13m de CPU, media hora sin reiniciarse (apuesta de < 100 MiB: perdida); antes,
  cinco `OOMKilled` con su límite de 384 MiB mientras la VM estaba sin memoria. → F23 §7, §8.
- **H202 · Tempo caído tumba a `catalog`**: con Tempo en cero réplicas, 60 lecturas seguidas por la puerta: `catalog`
  mediana 8,8 ms (con Tempo, 26,1) pero un máximo de **15.093 ms** (el corte de la puerta); `pricing` de 3,7 a 5,9 ms y
  `replenish` de 6,0 a 13,2 ms, sin colgadas. Una venta: **503 en 3,5 s** (`catalog no contesta: … HTTP connect timed
  out`). En `php-fpm`: `Export failure … Export retry limit exceeded`, primero `cURL error 7 … after 0 ms` (el pod de
  Tempo terminando) y después `cURL error 28: Connection timed out after 10001 milliseconds`: sin pods, la `NetworkPolicy`
  convierte el rechazo en espera (como H182), y cada proceso de FPM espera 10 s al vaciar sus spans al final de la
  petición. Go, Java y Node exportan en segundo plano y no lo sienten. Apuesta (< 5 ms): perdida. → F23 §6, §9, §12.
- **H203 · Tempo caído también rompe G7**: después de la prueba de H202, `logs.py` marcó 120 líneas de `php-fpm` (el
  `Export failure` y su traza de pila) y 80 de `inventory` (`java.io.InterruptedIOException: timeout` del exportador
  OkHttp del agente, en texto plano). Con Tempo arriba y los dos pods reiniciados, G5, G7 y G8 pasan. → F23 §13.

## T11 · F24–F26 (04–05/10/2026)

Docker Desktop en su memoria por defecto (7,75 GiB para la VM; las sesiones T1–T10 la bajaban a 4 GiB para medir): T11 no
tiene mediciones de memoria del perfil, y no se reinició Docker Desktop (habría reiniciado `mdm-lab`). El Kubernetes de
Docker Desktop sigue encendido (es de Oskar). Inventario inicial en `logs/t11/00-docker-inventario-inicial.log`.

- **H204 · `task images:load PROFILE=lab` no carga nada**: la tarea toma el perfil como argumento (`-- lab`) y con la
  variable buscó el cluster `minimo` (`ERROR: no nodes found for cluster "minimo"`). El `task deploy` siguiente esperó 10
  min el hook de migración de `inventory` en `ImagePullBackOff` (`pull access denied … docker.io/lab/inventory:g11`) y
  `--rollback-on-failure` volvió a la revisión 91 solo. El segundo intento chocó con `conflict with "kubectl-set" …
  containers[name="inventory"].image` (un `kubectl set image` de una sesión anterior); con `FORCE=true` pasó. → F24 §13.
- **H205 · G7 roto por G10 en `replenish`**: `logs.py` marcó `(node:1) MetadataLookupWarning: received unexpected error =
  All promises were rejected code = UNKNOWN`, en texto plano: el detector de recursos de Google de
  `auto-instrumentations-node` busca un servidor de metadatos. Con `OTEL_NODE_RESOURCE_DETECTORS=env,host,os,process,
  serviceinstance,container` en el chart (0.24.0), G7 vuelve a pasar. → chart, F24 §6.
- **H206 · G11 pasó la suite al primer intento** (`inventory.g11.hurl`, 22 peticiones con reintentos, 2,4 s). Las suites de
  G5, G7 y G8 siguen pasando con `inventory:g11` y `replenish:g11`. La de G1 falla en cuatro archivos, por diseño: la suite
  por paso comprueba lo que todavía no existía (`/metrics` en 404 desde G6; cuatro códigos de razón en `replenish`, que
  desde G11 son cinco). → a03.
- **H207 · `register_loan` en Contingencia es una transacción**: con un destino que no existe (`DRO-099`), el tercer paso
  (el `INSERT` de la orden) viola la llave foránea y la base deshace el descuento y el movimiento: la existencia sigue en
  30 y hay un solo `LOAN_OUT`. Sin existencia (500 unidades), `RAISE EXCEPTION` en el primer paso. → F24 §4.
- **H208 · Las bases del cluster no se ven entre sí**: desde la base `inventory`, `relation "replenishment_orders" does not
  exist`; conectado como `inventory` a la base `replenish`, `permission denied for database "replenish"`. → F24 §4.
- **H209 · El préstamo feliz**: `POST /loans` contesta 202 a los 9,5 ms y la saga sigue en la misma traza: 37 spans de
  `inventory`, `replenish` y `pricing`, 60 ms de punta a punta; la llamada a `replenish` es el paso más largo (32,2 ms). →
  F24 §5.
- **H210 · `replenish` en 503 (caos al 100 %)**: `COMPENSATED` a los 355 ms; en la base, `LOAN_OUT -1` y `ADJUSTMENT +1
  LOAN_RELEASED` con la misma referencia. → F24 §5.
- **H211 · `replenish` lento crea huérfanas**: con 3 s de demora y el timeout de 2 s, seis préstamos `COMPENSATED` (2,1 s
  cada uno), la existencia intacta y **seis órdenes nuevas en `PENDING`** (RO-0032 a RO-0037): el generador las pasó
  todas después de la demora (`forwarded: 6`). → F24 §8.
- **H212 · El `preStop` salvó una saga**: con `kubectl delete pod` normal durante el despacho, el préstamo terminó
  `COMPLETED`: el `preStop` de 5 s (F16) mantuvo viva la JVM y el hilo de la saga terminó adentro. → F24 §5.
- **H213 · El orquestador muere y el barrido compensa**: con `--grace-period=0 --force`, el préstamo quedó en
  `DISPATCHED` (RO-0039 creada) y a los 37–38 s otro pod lo compensó: canceló RO-0039 y liberó la unidad (`sin terminar en
  DISPATCHED después de 30 s`). → F24 §5.
- **H214 · La compensación también falla**: 8 préstamos con un destino sin precio y `replenish` fallando el 50 %: 1 falló al
  despachar (solo se liberó la reserva), 7 despacharon; de esas 7 cancelaciones fallaron 4, quedaron en `COMPENSATING` y el
  barrido las terminó a los 34,6 s. La traza del barrido es una traza nueva (`saga sweep`). → F24 §5, §13.
- **H215 · La saga de 2020 sin compensaciones, reproducida**: con la carpeta de traslados en solo lectura, el lote de
  Contingencia confirma `DISPATCHED` y escribe `No se pudo escribir traslados_20261004_2312.txt`; la orden 3 queda
  despachada, Sogamoso con 3 unidades menos, y ningún archivo. Nadie lo deshace. → F24 §4, §9.

**Apuestas de la F24, escritas el 04/10/2026 a las 23:20, antes de ejecutar:**

1. *Sogamoso con lluvia* (`task chaos:set -- perfil sogamoso-con-lluvia`, 50 % tarda 3 s y 20 % falla) en 20 préstamos
   seguidos: ninguno sigue sin estado final a los 90 s, y las órdenes huérfanas en `replenish` son exactamente tantas como
   préstamos cuyo `DISPATCH` falló por timeout (no por 503).
2. Dos réplicas de `inventory` y el orquestador muerto con cinco préstamos a medias: ningún préstamo se compensa dos veces
   (cada `LOAN_RELEASED` aparece una sola vez por préstamo).

**Resultado de las apuestas de la F24:**

- **H216 · Apuesta 1, ganada.** 20 préstamos con *Sogamoso con lluvia*: 10 `COMPLETED`, 8 `COMPENSATED` por timeout y 2 por
  503; ninguno sin estado final. Órdenes DRO-003→DRO-008: 18 (10 de préstamos completos, **8 huérfanas en `PENDING`**,
  RO-0057 a RO-0064). Las de 503 no dejaron orden. (`logs/t11/22-apuesta-sogamoso.log`)
- **H217 · Apuesta 2, ganada con letra chica.** Diez préstamos con `replenish` demorado 1,5 s y las dos réplicas
  borradas con `--grace-period=0 --force` 0,7 s después: siete alcanzaron a terminar (el kubelet no las mató en el acto) y
  **tres** quedaron en `DISPATCHED`, no cinco. Los dos barridos de los pods nuevos corrieron con 170 ms de diferencia y se
  repartieron los tres (uno el 49 y el 51, el otro el 50); cada préstamo tiene un solo `LOAN_RELEASED` y ningún paso
  `UNDO` repetido. Trampa: `kubectl logs -l …` muestra 10 líneas por pod si no se le pide `--tail=-1`.
  (`logs/t11/23-apuesta-dos-replicas.log`)

**Apuestas de la F25, escritas el 04/10/2026 a las 23:33, antes de ejecutar:**

1. Valkey: con `replenish` reiniciándose (`kubectl rollout restart`) mientras corren 30 ventas que dejan la existencia
   bajo el umbral, a una por segundo, se pierde al menos un aviso; `inventory` lo registra como publicado "a 0
   suscriptores" y ninguna venta falla.
2. NATS: la misma prueba deja exactamente 30 órdenes, una por venta, sin pérdidas y sin duplicados.
3. NATS con `replenish` apagado 60 s: los avisos esperan en el stream y, al volver, todas las órdenes aparecen en menos
   de 5 s.

- **H218 · Versiones del bus (04/10/2026, D17)**: `valkey/valkey:9.1.2-alpine` (la 9.2 está en candidata) y
  `nats:2.15.0-alpine`, por digest; `io.valkey:valkey-java` 5.5.0 (la continuación de Jedis: `io.valkey.JedisPooled`) e
  `io.nats:jnats` 2.26.3 en Java; `iovalkey` 0.4.0 (la continuación de ioredis; el `import` por defecto no compila con
  NodeNext: `import { Valkey } from 'iovalkey'`) y `@nats-io/transport-node` y `@nats-io/jetstream` 3.4.0 en Node. En
  reposo: Valkey 10 MiB, NATS 12 MiB. → a01.
- **H219 · G12 compiló al primer intento** en los dos servicios (con el arreglo del `import` de H218). `inventory.g12.hurl`:
  Hurl 8.0.1 no acepta `!= null` en un filtro de jsonpath (`Filter error`); la suite usa el filtro `last`. → a03.
- **H220 · Apuesta 1 (Valkey), perdida**: con `kubectl rollout restart` no se perdió ningún aviso y aparecieron **10
  órdenes repetidas** en 30 ventas: durante el rollout (`maxSurge 1`, `maxUnavailable 0`) hubo dos pods suscritos, y
  pub/sub entrega a cada suscriptor (`{'1': 21, '2': 10}` avisos por cantidad de suscriptores). Con el proceso
  reiniciado dentro del mismo pod (`kubectl exec deploy/replenish -- kill 1`), 30 ventas y **29 órdenes**: el aviso de
  SALE-027208 se publicó `a 0 suscriptores`. Ninguna venta falló. (`logs/t11/30-…`, `31-…`)
- **H221 · Apuesta 2 (NATS), ganada**: el mismo `rollout restart`, 30 ventas y 30 órdenes con 30 eventos distintos: el
  consumidor durable reparte entre los dos pods en vez de duplicar. Con `kill 1`, también 30 de 30. (`33-…`, `34-…`)
- **H222 · Apuesta 3 (NATS), ganada**: con `replenish` en cero réplicas, 10 ventas dejaron 10 mensajes pendientes en el
  consumidor (`/jsz`); 60 s después, al volver, pendientes en cero 0,1 s después de que el pod quedó listo (el consumidor
  arranca antes de la readiness). (`35-…`)
- **H223 · Una latencia que no se publica**: medir el aviso como "línea de `inventory` contra línea de `replenish`" dio una
  mediana de 0,9 ms, que no significa nada: `inventory` escribe su línea después del ack del stream, cuando la orden ya
  puede estar creada. (`36-…`)
- **H224 · La traza se corta en el bus**: una venta con el aviso por NATS tiene 12 spans de `inventory`, `catalog` y
  `pricing`, y ninguno de `replenish`: nadie propaga el `traceparent` en el mensaje. El agente de Java sí instrumenta
  `jnats`, y deja ver que `inventory` pregunta por el stream en **cada** publicación (`PRODUCER
  $JS.API.STREAM.INFO.LAB_EVENTS publish`, 2,4 ms): el prompt de G12 aseguraba el stream siempre. Se corrige en G13.
  (`logs/t11/38-traza-nats.log`)
- **H225 · La línea de base por HTTP (G5)**: el mismo `kill 1` de `replenish` durante 30 ventas: 28 órdenes, 2 avisos
  perdidos con su línea `aviso a replenish perdido … I/O error`. Valkey perdió 1 (`a 0 suscriptores`), NATS 0.
  (`39-http-baseline.log`)

**Apuestas de la F26, escritas el 04/10/2026 a las 23:54, antes de ejecutar:**

1. Con G12, matar la JVM de `inventory` con `kill -9` desde el nodo durante una ráfaga de ventas que piden reposición
   deja al menos una venta confirmada en la base sin su orden en `replenish` (la escritura dual).
2. Con G12, matar `node` de `replenish` con `kill -9` durante una ráfaga deja al menos una orden repetida (mismo
   `sourceEventId`): el mensaje creó la orden y no alcanzó a confirmarse.
3. Con G13 (outbox con su publicador como *sidecar*, consumidor idempotente), las dos pruebas anteriores dejan cero
   ventas sin orden y cero órdenes repetidas.
4. Con G13, *Sogamoso con lluvia* sobre 20 préstamos deja cero órdenes huérfanas en `replenish` (la rotura de la F24).
- **H226 · Apuesta 1 (F26), ganada a la tercera**: con G12, `kill -9` a la JVM de `inventory` (desde el nodo, `pkill -9 -f
  inventory-0.0.1-SNAPSHOT.jar`) durante una ráfaga de 8 o 16 clientes: corridas 1 y 2 sin pérdidas (376 de 376, 364 de
  364); corrida 3, **387 ventas en la base, 386 respuestas `201` y 386 órdenes**: una venta confirmada, sin respuesta al
  cliente y sin aviso. La ventana entre el commit y la publicación es de milisegundos. (`logs/t11/40-…`)
- **H227 · Apuesta 2 (F26), ganada**: con G12, `kill -9` a `node` de `replenish`: una orden repetida en las corridas 1 y 3
  (991 ventas, 992 órdenes; 1.344 y 1.345). La pareja de la corrida 3: RO-4221 (`delivery: 1`, 05:00:10.863) y RO-5030
  (`delivery: 2`, 05:00:40.853, el `ack_wait` de 30 s), el mismo evento y la misma venta. En la base quedan además las diez
  parejas de la apuesta 1 de la F25 (Valkey con dos suscriptores). (`41-…`)
- **H228 · El cliente que reintenta**: con G12, el mismo `POST /loans` dos veces con `Idempotency-Key` (que G12 ignora): dos
  préstamos y dos órdenes (RO-5033, RO-5034). (`42-…`)
- **H229 · G13 pasó la suite al primer intento** (`inventory.g13.hurl`, 15 peticiones; `newUuid` de Hurl para claves nuevas
  por corrida) y siguen pasando G5, G7 (con el sidecar en el pod), G11 y G12. `nats.go` 1.54.0 y `pgx` 5.11.0 en el
  relay; `jnats` sale del `pom.xml`. (`44-…`, `45-…`)
- **H230 · Ráfagas con trazas: Tempo con 6,5 núcleos**. Las ráfagas de 16 clientes (≈ 13.000 peticiones en 10 s, la
  mayoría 503 rápidos) con las trazas encendidas dejaron a Tempo en 6.578m–6.743m de CPU y a `catalog` en
  `CrashLoopBackOff` por la sonda de vida (11 reinicios); un `task deploy` sin trazas falló con `Progress deadline
  exceeded` en `inventory` y `--rollback-on-failure` lo devolvió a la revisión con trazas. Salida: `kubectl scale
  deploy/tempo --replicas=0` y `task deploy FORCE=true`. Dos corridas de la apuesta 3 se descartaron por eso (todas las
  ventas en 503). Trampa: en `task obs:off -- traces FORCE=true`, `FORCE` queda como argumento; va antes del `--`.
- **H231 · Apuesta 3 (F26), ganada**: con G13, seis corridas válidas: `kill -9` a `inventory` 456/456, 402/402 (dos ventas
  sin respuesta al cliente, con su orden) y 487/487; a `replenish` 1.194/1.194, 1.361/1.361 y 1.476/1.476, sin repetidas.
  Como ningún `kill -9` cayó en la ventana del ack, las dos defensas se probaron aparte, de forma determinista: un evento
  ya publicado marcado como pendiente → `evento ya publicado; JetStream descartó la copia` (`Nats-Msg-Id`, dentro de la
  ventana de deduplicación); el mismo evento con otro id en el outbox → `evento repetido: ya tiene su orden` en
  `replenish`. (`46-…`, `47-…`)
- **H232 · Apuesta 4 (F26), ganada con un arreglo en medio**: *Sogamoso con lluvia*, 20 préstamos: 14 `COMPLETED` (los
  reintentos con clave salvaron 4 que en la F24 se compensaban) y 6 `COMPENSATED`. Tres quedaron en `COMPENSATING` más de
  diez minutos: la cancelación había llegado en un intento cuya respuesta se perdió, y cada reintento recibía `409 … la
  orden está en CANCELLED, no en PENDING`. **La compensación no era idempotente.** Arreglo en `replenish` (G13): cancelar
  una orden ya `CANCELLED` la devuelve con 200; el contrato lo dice. Con la lluvia parada (`chaos:set -- clear`, 00:42) y
  el arreglo desplegado, los tres terminaron a las 00:47:55. Resultado: 17 órdenes de Girón a Sogamoso, ninguna clave
  repetida, 3 canceladas (encontradas por la clave del préstamo), **cero huérfanas**. (`48-…`)

## T12 · F27 y el proyecto final (05/10/2026)

- **H233 · El proyecto final, hecho una vez de punta a punta** con un servicio de prueba, `notify` (Go, 150 líneas: un
  consumidor durable propio de `lab.inventory.stock-low`, idempotente por `eventId`, salud, `/metrics` con el histograma
  del contrato y logs JSON), en una **copia** de `src/lab` en el scratchpad, desplegada como release `lab`: contrato,
  Dockerfile, subchart de 4 archivos, una dependencia y un interruptor en el paraguas, el tag en `STEP_TAGS` y su suite.
  Build de 14,7 s; despliegue de 25 s; ningún pod de los otros cinco se recreó. (`logs/t12/01-…`)
- **H234 · Los criterios, ejecutados**: `notify.g13.hurl` pasa junto a `inventory.g13.hurl` (9 peticiones, 1,2 s); la puerta
  lo sirve en `/notify/` sin tocar `Gateway` ni los demás; Prometheus lo descubre solo (`target notify up`) y la consulta del
  panel "Peticiones por segundo" lo muestra (1,87 peticiones/s); un `rollout restart` con 4 clientes: 12.663 respuestas, todas
  200. (`02-…` a `05-…`)
- **H235 · El incidente del proyecto**: la readiness en `/health/readyz` (404): el pod nuevo nunca listo, el rollout se atascó
  (`Progress deadline exceeded`) y `--rollback-on-failure` volvió a la revisión anterior a los 2 min 17 s; el pod viejo atendió
  todo el tiempo (200 por la puerta). (`06-…`)
- **H236 · La limpieza del proyecto**: el chart original lo quita todo; queda en NATS el consumidor durable `notify-stock-low`,
  que nadie lee y que acumularía pendientes: se borró con `jsm.consumers.delete` desde el pod de `replenish`. El enunciado lo
  pide como criterio de salida. (`07-…`)

## T13 · Los apéndices 🔥 (05/10/2026)

- **H237 · a06, la emulación medida**: Docker Desktop registra Rosetta (amd64) y QEMU en `binfmt_misc`, visibles desde un
  nodo de kind. Primer 200, tres corridas: `pricing` 0,33 s nativo contra 0,46 s amd64; `inventory` 5,68 s contra **20,34
  s** (3,6x). Build sin caché de `pricing`: 23,2 s nativo, 80,1 s amd64 emulado, 28,8 s amd64 con `--platform=$BUILDPLATFORM`.
  (`logs/t13/01-…` a `05-…`)
- **H238 · a06, el build de Java emulado no termina**: `tar: … Cannot open: Function not implemented` al descomprimir Maven
  en `./mvnw dependency:go-offline` bajo emulación amd64. Con la etapa del JDK en `$BUILDPLATFORM`, 111 s (108 s el
  nativo). (`03-…`, `04-…`)
- **H239 · a06, la imagen que el kubelet no ve**: `kind load` de una imagen solo amd64 en un nodo arm64: `ErrImageNeverPull
  … is not present`; `ctr images ls` la muestra sin la etiqueta `io.cri-containerd.image=managed` y con plataforma
  `linux/amd64`, y `crictl images` no la lista. La arm64, `Ready` a los 3,0 s de arrancar el contenedor, tres corridas.
  (`06-…`, `07-…`)
- **H240 · a07, los constructores**: Buildah 1.43.4 (en contenedor, `--privileged`) falla con *overlay* sobre *overlay*
  (`fork/exec /bin/sh: invalid argument` en el primer `RUN`) y funciona con `--storage-driver vfs`; Kaniko (el repositorio
  de Google está archivado; el fork de Chainguard, 1.25.19, con imágenes de GitLab) ejecutó un `RUN` sobre una carpeta
  montada en `/out` y dejó el binario en el host. Build en frío de `pricing`: Docker 23,2 s, Buildah 37,3 s (36,5–38,8),
  Kaniko 59,8 s (57,1–61,9), ko 0.19.1 30,4 s (28,1–30,9); las capas de Buildah y Kaniko son las de Docker (binario de 24,3
  MB); ko, 35,6 MB (sin `-s -w`). Jib 3.5.2 para `inventory`: 83,9 s contra 108,3 s del Dockerfile, una corrida.
  (`logs/t13/08-…` a `13-…`)
- **H241 · a07, lo que se pierde sin Dockerfile**: las imágenes de ko y de Jib no tienen la carpeta de datos de G1 (`unable
  to open database file`; `Application run failed`), y la de Jib no pasa `--enable-native-access` (cuatro líneas `WARNING`
  en texto). La de Jib contestó 200 en `/health/live` antes de morir: la primera medición de arranque no valió y se repitió
  contra `/health/ready` con `DATA_DIR=/tmp`: 2,54 s contra 2,82 s del Dockerfile sin el agente. (`11-…`, `13-…`)
- **H242 · a08, la nativa en cinco intentos** (GraalVM CE 25.0.2, Spring Boot 4.1.1, nodos de kind detenidos para darle
  memoria): (1) `grpc-netty-shaded` y BoringSSL por JNI (`Class initialization … tcnative … failed`); (2) diferir solo SSL
  dejó un `Logger` de logback en el *heap* de la imagen; con `--initialize-at-run-time=io.grpc.netty.shaded.io.netty`,
  compiló; (3) no arrancó: los `.sql` no estaban (`Cannot read SQL script … schema-sqlite.sql`) ni la carpeta de datos;
  con `{"resources":[{"glob":"*.sql"}]}` y la carpeta, arrancó en 0,122 s; (4) 500 en cada petición: `Record components not
  available for record class …StockController…` (las respuestas son `ResponseEntity<Object>`); (5) con
  `@RegisterReflectionForBinding` de los records, funcionó. Pico de memoria de `native-image`: 5,30 a 6,04 GB.
  (`logs/t13/14-…`, `16-…`)
- **H243 · a08, la tabla**: build en frío JVM 108,3 s, AOT cache 122,1 s, nativa 263,1 s; imagen 687, 711 y 240 MB; listo
  2,28 s (2,27–2,31), 1,31 s (1,31–1,34) y 0,52 s (0,52–0,53); memoria en reposo 332, 306 y 66 MiB; después de 1.000
  peticiones 357, 337 y 77 MiB. Sin límite de memoria y sin el agente. El `Dockerfile.aot` de la F15 (G4) no compila con
  G13: le faltaba el contexto `proto`. Dos mediciones descartadas (zsh no partió los argumentos; `docker stats` con
  formato de texto dio caracteres ilegibles: se leyó en JSON). (`15-…`, `17-…`)
- **H244 · a09, el storefront con SSR** (Node con React 19.3.0 y `renderToString`, 61 líneas, imagen de 254 MB contra 82 MB
  del nginx): dos despliegues con la misma imagen y su `ConfigMap`; con la marca leída de un archivo montado en cada
  petición, un `patch` del `ConfigMap` se vio a los 68 s sin reiniciar. A 20 por segundo, tres corridas: la estática (HTML,
  `config.json`, catálogo y precios) mediana 18,2 ms y p95 20,8 ms; la SSR, 16,6 y 18,5 ms. Memoria: nginx 7 MiB; SSR 32 MiB
  sin tráfico, 71 después de las pruebas y 92 después de la carga. Con `catalog` en cero: SSR 503 (`The operation was
  aborted due to timeout`) con la readiness en 1/1; la estática, 200 en su HTML. Las dos variantes se borraron del cluster.
  (`logs/t13/18-…` a `21-…`)
- **H245 · a10, Istio ambient 1.31.1**: el repositorio `istio-release.storage.googleapis.com/charts` no tiene la 1.31.1
  (llega a 1.31.0-rc.0); `blob.istio.io`, sí. Instalado en 42 s; en reposo, 148 MiB (istiod 51, CNI 26–35 por nodo, ztunnel 3
  por nodo); la VM, +326 MiB. `apps` al mesh con una etiqueta, sin reinicios; G5 pasa; ztunnel registra HBONE al 15008 con
  identidades SPIFFE, **todas `sa/default`** (el chart no crea `ServiceAccount` por servicio); Postgres (`data`) fuera del
  mesh. (`logs/t13/22-…` a `25-…`)
- **H246 · a10, el waypoint sin red**: con `istio.io/use-waypoint`, el pod del *waypoint* no llega a istiod por la
  `NetworkPolicy` de la F20 (`dial tcp …:15012: i/o timeout`) y la venta da 503; con una regla de salida a `istio-system`
  15012, 201. Reintentos con una `HTTPRoute` de Gateway API con un `Service` como padre (`retry: {attempts: 3, codes:
  [503]}`): con el caos al 50 % sobre `catalog`, 104 errores de 200 sin reintentos; 23, 7 y 18 con ellos; 397 peticiones al
  vecino por 200 lecturas. `istio_requests_total` del *waypoint* por origen, destino y código. Memoria con *waypoint*: unos
  200 MiB. (`26-…` a `28-…`)
- **H247 · a10, sacarlo**: `helm uninstall` de los cuatro charts deja 15 CRD de Istio y tres `GatewayClass` (`istio`,
  `istio-remote`, `istio-waypoint`) creadas por istiod; se borraron a mano, y las imágenes de los nodos con `crictl rmi`.
  La venta, en 201 después. (`29-…`)
- **H248 · a11, Argo CD 3.5.3**: instalado con el manifiesto oficial y `--server-side` en 48 s, siete pods y tres CRD. Una
  `Application` contra `argocd-example-apps/guestbook` con `selfHeal`: `Synced/Healthy`; un `kubectl scale` a 3 réplicas
  volvió a 1 en 0,2 s. En reposo, **443 MiB** (controlador 215, dex 100, server 49, repo-server 31); la VM, +716 MiB.
  `kubectl delete -f` del manifiesto se llevó las CRD; imágenes borradas de los nodos. (`logs/t13/30-…` a `32-…`)
- **H249 · a12, los controladores que ya estaban**: 28 CRD (10 de Gateway API, 8 de Envoy Gateway, 3 experimentales de
  Gateway API, 7 de cert-manager y trust-manager). Un `Certificate` de prueba: su `Secret` borrado volvió en 0,4 s, con un
  `CertificateRequest` nuevo (eventos `Issuing … as Secret does not exist`). (`logs/t13/33-…`, `34-…`)
- **H250 · a12, el proxy que nadie repone**: `kubectl scale --replicas=0` del proxy de Envoy del `Gateway` `lab`:
  **Envoy Gateway no lo repuso**; su *server-side apply* del `Deployment` no incluye `spec.replicas`. La puerta quedó caída
  13 min (08:10:43 a 08:23:49 UTC), sin ninguna alarma (observabilidad apagada), hasta un `scale` a mano: 11,1 s después,
  200. **Error de método:** el primer script imprimió "de vuelta en 1/1 a los 136 s" al agotar su bucle, sin haber vuelto;
  se corrigió en el log y no se publicó. (`35-…`)
- **H251 · a13, respaldo y restauración**: el `CronJob` (`platform/data/backup/`, no aplicado por el camino base) respaldó
  las ocho bases y los roles en 14 s (`inventory.dump` 1,2 MB). `DROP DATABASE pricing`: a los 8 s, precio 500, venta 503,
  `pricing` 0/1; el `Job` de restauración (`CREATE DATABASE … OWNER pricing`, `pg_restore`) devolvió 166 precios, y a los
  12 s del desastre, precio 200 y venta 201, sin reiniciar `pricing`. El `CronJob` y su PVC se quitaron del cluster después.
  (`logs/t13/36-…`, `37-…`)
- **H252 · a13, borrar el cluster**: un cluster temporal `a13` con `extraMounts`: lo escrito en un PVC no existe en el
  cluster recreado (`No such file or directory`); lo escrito en la carpeta montada del host, sí. La segunda creación falló
  una vez por crear el pod antes de la `ServiceAccount` `default` (`serviceaccount "default" not found`); se repitió
  esperándola. (`38-…`)
- **H253 · a13, el contexto que queda vacío**: `kind create cluster --name a13` cambió el contexto actual a `kind-a13`, y
  `kind delete cluster --name a13` lo dejó **vacío** (no vuelve a `kind-lab`). Se notó al empezar a14
  (`kubectl config get-contexts` sin asterisco) y se devolvió con `kubectl config use-context kind-lab`. Pasa a las
  advertencias de a13.
- **Error de método (a14)**: `"Podman Desktop" --version` no imprime la versión: **abre la aplicación**. Se cerró el proceso
  lanzado (sin tocar la máquina de Podman, que estaba detenida). La versión se lee del `Info.plist`.
- **Apuestas a14**, antes de correr: (1) Headlamp dentro del cluster, en reposo, por debajo de 50 MiB; (2) con un token
  de la `ClusterRole` `view`, Headlamp lista pods (200) y un borrado por su proxy da 403: la GUI no puede más que su
  token; (3) el motor (lo que muestra Docker Desktop en *Containers*) ve los nodos de kind, no los pods.
- **H254 · a14, Headlamp dentro del cluster (apuesta 1, ganada)**: chart 0.45.0 en `headlamp`, 272 s hasta listo, de los
  que 4 min 30 s fueron bajar la imagen (103 MB) desde ghcr. En reposo, **13 MiB** y 1m de CPU. El chart crea por defecto
  un `ClusterRoleBinding` de su `ServiceAccount` a **`cluster-admin`** (`clusterRoleBinding.create: true`). (`39-…`)
- **H255 · a14, la GUI no puede más que su token (apuesta 2, ganada)**: por el proxy de Headlamp (`/clusters/main/…`),
  sin token: 403 (el binding a `cluster-admin` no se usó para peticiones anónimas en esta versión); con un token de
  `view`: listar pods de `apps` 200 (9 pods), listar `Secret` 403, borrar un pod de prueba 403, y el pod siguió. (`40-…`)
- **H256 · a14, las capas (apuesta 3, ganada)**: el motor ve 4 contenedores (los 3 nodos de `lab` y `mdm-lab`, que no es
  del curso); el cluster, 33 pods; `crictl` dentro de los nodos, 9 + 13 + 10 contenedores. La memoria por nodo que ve el
  motor (1,49 GiB, 748 MiB, 889 MiB) es la de todo lo que corre adentro. Docker Desktop y Podman Desktop **no se
  operaron con clics**: el apéndice lo dice. Limpieza: release, namespaces, binding, repo de Helm y la imagen del nodo.
  (`41-…`)
- **Apuestas a15**, antes de correr: (1) con `podManagementPolicy: OrderedReady` (el valor por defecto) y la readiness en
  `/healthz`, `nats-ha-0` no llega a listo porque JetStream espera quórum, y `nats-ha-1` nunca se crea: el arranque
  ordenado se traba solo; (2) con `Parallel`, los tres listos en menos de 60 s; matar al líder de un stream R3 elige otro
  en menos de 10 s, con publicaciones fallidas por unos segundos y **ninguna confirmada perdida**; (3) con dos de tres
  caídos, el stream no acepta escrituras, y al volver no falta nada; (4) cada miembro en reposo entre 15 y 30 MiB, el triple
  del de uno.
- **H257 · a15, arranque ordenado (apuesta 1, ganada)**: con `OrderedReady`, `nats-ha-0` 0/1 durante 180 s
  (`Healthcheck failed: "JetStream is still recovering meta layer"`, `Waiting for routing to be established...`, `/healthz`
  503) y `nats-ha-1` nunca se creó. Con `Parallel` y el Service headless con `publishNotReadyAddresses`, los tres listos
  en 15 s; dos quedaron en `lab-worker2` (el control-plane no recibe pods y hay dos workers: la regla de un miembro por
  nodo es `ScheduleAnyway`). (`42-…`, `43-…`)
- **H258 · a15, failover (apuesta 2, ganada a medias)**: stream `A15` R3, publicando con `nats pub -J` y `Nats-Msg-Id`
  cada ~0,1 s. **Error de método:** las dos primeras corridas publicaron sus 400 mensajes en 5,9 s, antes del corte; se
  descartaron. Con `kubectl delete pod` del líder: **1 publicación fallida** (`no responders`), 0,11 s de hueco, líder
  nuevo. Con `kill -9` del proceso del líder desde el nodo: el líder nuevo se eligió a los **5,6 s** (`08:51:08.57` corte,
  `08:51:14.18` `new stream leader` en `nats-ha-0`), **47 publicaciones fallidas** en 5,4 s. En las dos: **0 confirmadas
  perdidas**, 0 guardadas sin confirmar. El sondeo del líder por `stream info` cada ~2 s se quedó atrás de los logs y no
  se usa para el tiempo. (`44-…`, `45-…`)
- **H259 · a15, sin quórum (apuesta 3, ganada, con una sorpresa)**: `scale` a 1 durante 25 s: `nats-ha-0` solo da
  `/healthz` 503, la readiness lo saca del Service y **los clientes ni conectan** (`no servers available`): sin escrituras
  y sin lecturas. 30 publicaciones fallidas entre +12,0 y +40,8 s; de vuelta a los ~6 s del `scale` a 3. 0 confirmadas
  perdidas. (`46-…`)
- **H260 · a15, memoria (apuesta 4, perdida)**: en reposo, 11 + 9 + 9 MiB (29 MiB) contra 15 MiB del `nats-0` de un
  miembro: el doble, no el triple, y cada miembro por debajo de la apuesta. Limpieza: `StatefulSet`, PVC, `nats-box` y su
  imagen del nodo. (`47-…`)
- **H261 · a15, la deduplicación sobrevive al líder (la pregunta de la F26)**: venta `venta-1` con `Nats-Msg-Id`
  guardada con `nats-ha-0` de líder; `kill -9` al proceso; líder nuevo `nats-ha-1` en ≤ 9 s (sondeo de 1 s); la misma venta
  otra vez: `Sequence: 1 Duplicate: true`, un mensaje en el stream. La ventana de duplicados (120 s) es estado replicado
  del stream, no memoria del líder. (`48-…`)
- **H262 · T14, la suite contra el cluster**: `task conformance TARGET=cluster -- G13` sin `PROFILE` falla (`context
  "kind-minimo" does not exist`); con `PROFILE=lab`, `inventory.g13.hurl` 15 peticiones en 624 ms. La suite del cluster
  llama a los `Service` por su nombre (`cluster.env`), **no por la puerta** como decía a03; corregido. (`49-…`)
- **H263 · T14, k9s 0.51.0 verificado**: sin tmux, manejado desde Python con un pseudo-terminal y `pyte`, contra `kind-lab`
  en `--readonly`: `/` filtra, `d` describe, `l` logs (en un pod de dos contenedores, los dos con su nombre delante), `:deploy`,
  `:events`, `0` todos los namespaces, `:ctx`, `?`; `ctrl-d` no hace nada en solo lectura, y el menú de solo lectura no
  muestra `s`, `e` ni `ctrl-d` (sin `--readonly`, sí, más `ctrl-k`, `a`, `t`, `z`). **Efecto lateral:** k9s guarda la
  última vista por contexto en `~/Library/Application Support/k9s/clusters/kind-lab/kind-lab/config.yaml`; la sesión la
  dejó en `contexts` y se devolvió a pods. (`50-…`)
- **H264 · T14, las salidas**: `.spec.containers[*]` de `inventory` lista solo `inventory`; el *sidecar* `outbox-relay`
  está en `.spec.initContainers` con `restartPolicy: Always`, aunque `READY` diga 2/2. Ocho pods `BestEffort` en el
  cluster: cert-manager y trust-manager (4), `kube-proxy` (3) y el aprovisionador de volúmenes. (`51-…`)
- **H265 · T14, `inc:break` solo servía con el cluster `minimo`**: `inc.py` fijaba `kind-minimo` para los incidentes 05–15 y
  `task deploy -- minimo` para reparar; un lector que al final del curso solo tiene `lab` no podía usarlo. Ahora el
  Taskfile pasa `INC_CONTEXT` (de `CLUSTER` o `PROFILE`) e `INC_VALUES` (de `PROFILE`). Verificado con el 13 en `lab`
  (`task inc:break PROFILE=minimo CLUSTER=lab -- 13`): 0/1 `Running`, `Readiness probe failed: … statuscode: 503`, la
  puerta en 500 como dice el cuaderno; reparado. (`52-…`)
- **H266 · T14, `logs deploy/<svc>` elige el pod de la migración**: con el pod de `replenish` sin listo, `kubectl logs
  deploy/replenish` dijo `Found 2 pods, using pod/replenish-migrate-69msn` (el selector del `Deployment` es solo
  `app.kubernetes.io/name`, y el pod terminado del `Job` lo comparte). El primer comando del incidente 13 se cambió a
  `-l …,component=backend`, con una advertencia; y la entrada de logs de a04, también.
- **H267 · T14, B-04 de `pricing` con G10**: 5 + 5 builds y 10 arranques: descomprimida 26,6 MB, viaja 9,6 MB, frío 23,5 s
  (22,8–24,9), con caché 16,9 s (16,6–17,4), primer 200 en `/health/live` 0,22 s. Los 398 s de G3 (H99) no se repitieron.
  **Dos fallas del arnés, corregidas:** la ruta de G0 da 404 sin precios (`sin 200 en 120 s`; se agregó `--path`), y
  `docker save lab/pricing` sin tag exportó todos los tags del repositorio (128 MB; se fija `:latest`). (`53-…`)
- **H268 · T16, URL externas**: 316 URL de los documentos del curso (sin las internas del laboratorio), con `curl -L` y
  el destino final. Rotas y corregidas: `gateway-api.sigs.k8s.io/api-types/httproute/` y `/grpcroute/` (404; ahora
  `/reference/api-types/…`), `…/httproute/#timeouts-optional` (ahora `/guides/user-guides/http-timeouts/`) y la de
  deduplicación de NATS, que redirigía a la portada `docs.nats.io/learn/` (ahora `/learn/jetstream/publishing`). La base
  del repositorio de charts de Istio da 404 y su `index.yaml` 200, como cualquier repositorio de Helm. Otras 17
  redirecciones llegan a la página equivalente.
- **H269 · 05/10/2026, la CA en el llavero, sin instalar**: `security verify-cert -c gateway.crt -p ssl -s api.localhost`
  da `CSSMERR_TP_NOT_TRUSTED`; con `-r ca.crt` (la CA como ancla), `certificate verification successful`: falta solo la
  confianza. La fila de macOS de la F19 §5.3 usaba `remove-trusted-cert` para quitarla, que deja el certificado en el
  llavero (`man security`): se pasa a dos pasos, con `delete-certificate -Z <SHA-1>` (el nombre «La Rebotica» también
  encuentra la CA «otra» del incidente 19). La receta completa, con el llavero `login` y `-p ssl` como opción
  recomendada, vive en a01. → a01, F19 §5.3.
- **H270 · 05/10/2026, la CA instalada por Oskar** en el llavero `login` (`add-trusted-cert -r trustRoot -p ssl`): el
  `verify-cert` sin ancla pasa, con tres líneas informativas de transparencia de certificados (no aplica a una CA
  privada). Hay un solo certificado «La Rebotica» en `login`, con la misma huella SHA-1 que `ca.crt`
  (`C26947F1…64B4`), y `dump-trust-settings` muestra una sola regla de confianza, con la política SSL. Siguen sin
  ejecutar la prueba en el navegador (no hay cluster), la desinstalación y la variante del sistema. Cierra en parte H174.
