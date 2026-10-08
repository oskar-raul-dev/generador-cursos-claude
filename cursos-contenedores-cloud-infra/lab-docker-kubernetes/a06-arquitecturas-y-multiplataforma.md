# 📎 Apéndice a06 — Arquitecturas y builds multiplataforma

> **Curso:** Laboratorio de contenedores y Kubernetes local · 🔥 Ampliación
> **Usado por:** [Fase 04](04-empaquetar-los-cuatro-runtimes.md) (las imágenes), [Fase 05](05-los-dos-motores.md) (los motores) · **Versiones cubiertas:** las de [a01](a01-el-laboratorio.md)
> **Memoria que suma al perfil `lab`:** ninguna; no instala nada en el cluster
> **Fecha de verificación ejecutada:** 05/10/2026 · macOS arm64 con Docker Desktop (Podman, no verificado por el autor)

**Esto no se lee de corrido.** Se entra por el índice buscando algo concreto y se sale. Resuelve una pregunta que
aparece el primer día que alguien construye en un Mac con chip de Apple y despliega en un servidor amd64, o al revés:
*"¿por qué mi contenedor tarda tanto en arrancar?"*, y su prima, *"¿por qué el pod dice que la imagen no está, si la
acabo de cargar?"*.

**Qué queda fuera:** compilar para Windows; las arquitecturas que no son ARM ni amd64; firmar y publicar imágenes
multiplataforma en un registry público.

---

## Índice

- [La arquitectura es parte de la imagen](#la-arquitectura-es-parte-de-la-imagen)
- [Correr una imagen de otra arquitectura: la emulación](#correr-una-imagen-de-otra-arquitectura-la-emulación)
- [Construir para otra arquitectura: emular el compilador o no](#construir-para-otra-arquitectura-emular-el-compilador-o-no)
- [Una imagen, dos arquitecturas](#una-imagen-dos-arquitecturas)
- [En el cluster: la imagen que el kubelet no ve](#en-el-cluster-la-imagen-que-el-kubelet-no-ve)
- [El diagnóstico, en treinta segundos](#el-diagnóstico-en-treinta-segundos)
- [Cuándo usar qué](#-cuándo-usar-qué)
- [Referencias](#-referencias)
- [Ejercicios](#-ejercicios-6)

---

## La arquitectura es parte de la imagen

Un contenedor comparte el kernel de la máquina ([Fase 03](03-el-contenedor-por-dentro.md)), así que sus binarios tienen
que ser de la arquitectura de esa máquina: un binario amd64 no corre en un procesador ARM sin alguien que lo traduzca. Por
eso una imagen dice para qué plataforma es:

```text
$ docker image inspect lab/pricing:a06-amd64 --format '{{.Os}}/{{.Architecture}}'
linux/amd64
```

Las imágenes base del curso están fijadas por el digest de su **índice** ([a01](a01-el-laboratorio.md)): una lista con
una variante por plataforma. El motor elige la de la máquina, y por eso el mismo `FROM` funciona en un Mac con chip de
Apple y en un servidor amd64.

## Correr una imagen de otra arquitectura: la emulación

Docker Desktop en macOS registra en su máquina virtual dos traductores: **Rosetta** para amd64 y QEMU para el resto (se
ven en `/proc/sys/fs/binfmt_misc/` de cualquier contenedor privilegiado, incluido un nodo de kind). Con eso, `--platform
linux/amd64` corre:

```text
$ docker run --rm --platform linux/amd64 <una imagen multiplataforma> uname -m
x86_64
```

Corre, pero no gratis. El primer `200` en `/health/live`, desde `docker run`, tres corridas por imagen (la imagen
`inventory` del paso G13, sin base de datos y con el SQLite de G1):

| | arm64 (nativo) | amd64 (Rosetta) | proporción |
|---|---|---|---|
| `pricing` (Go) | 0,33 s (0,32–0,42) | 0,46 s (0,45–0,62) | 1,4x |
| `inventory` (Java) | 5,68 s (5,44–5,72) | 20,34 s (20,16–21,09) | **3,6x** |

Go casi no lo siente: un binario compilado se traduce una vez. La JVM, sí: además de traducir el intérprete, traduce lo
que el compilador JIT genera mientras arranca. **Un servicio de Java emulado arranca casi cuatro veces más lento**, y si su
sonda de arranque se midió con la imagen nativa ([Fase 15](15-salud-y-recursos.md)), el kubelet lo mata antes de que
termine.

> 🦭 **Podman:** su máquina virtual en macOS también puede usar Rosetta, según la versión y la configuración. No verificado
> por el autor; la medición de esta sección es solo de Docker Desktop.

## Construir para otra arquitectura: emular el compilador o no

`docker buildx build --platform linux/amd64` construye una imagen amd64 en un Mac ARM. Con el Dockerfile tal cual, **cada
`RUN` del build corre emulado**, el compilador incluido. Sin caché, tres corridas:

| | arm64 (nativo) | amd64, todo emulado | amd64, compilando en nativo |
|---|---|---|---|
| `pricing` (Go) | 23,2 s (23,2–32,6) | 80,1 s (73,1–83,8) | 28,8 s (27,8–29,0) |
| `inventory` (Java), una corrida | 108,3 s | **falló** | 111,0 s |

El de Java no fue lento: **no terminó**. El wrapper de Maven descomprime su distribución con `tar`, y bajo emulación:

```text
#18 6.141 tar: apache-maven-3.9.16/lib/error_prone_annotations.license: Cannot open: Function not implemented
#18 6.318 failed to untar
#18 ERROR: process "/bin/sh -c ./mvnw -q -B dependency:go-offline" did not complete successfully: exit code: 1
```

La emulación no implementa todas las llamadas al sistema, y un build la ejercita más que una aplicación. La salida es
**no emular el compilador**: la etapa de build corre en la plataforma de la máquina (`$BUILDPLATFORM`) y produce para la
de destino (`$TARGETARCH`); solo la etapa final, la que se copia, es de la arquitectura de destino. En `pricing`, dos
líneas:

```dockerfile
FROM --platform=$BUILDPLATFORM golang@sha256:8a5910f… AS build
ARG TARGETOS TARGETARCH
# …
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -trimpath -ldflags="-s -w" -o /out/pricing .
```

En `inventory`, una: `FROM --platform=$BUILDPLATFORM` en la etapa del JDK. El bytecode de Java no tiene arquitectura; el
`.jar` que sale del Mac es el mismo que saldría de un servidor amd64, y la etapa final copia ese `.jar` sobre el JRE de la
plataforma de destino. El *sidecar* del outbox ([Fase 26](26-idempotencia-y-outbox.md)), que es Go, lleva las dos líneas
de `pricing`.

> ⚠️ **Lo que no se puede compilar cruzado.** Una extensión nativa (las de PHP que `catalog` compila, la biblioteca nativa
> de `sqlite-jdbc`) depende de la arquitectura de destino, y su etapa tiene que correr emulada o en una máquina de esa
> arquitectura. Es la razón por la que `catalog` es el más difícil de los cuatro para esto.

## Una imagen, dos arquitecturas

Con el almacén de imágenes de containerd (el de Docker Desktop en la versión de [a01](a01-el-laboratorio.md)), un solo
build produce las dos variantes bajo un solo nombre:

```text
$ docker buildx build --platform linux/amd64,linux/arm64 -f <el Dockerfile con las dos líneas> -t lab/pricing:a06-multi --load services/pricing
$ docker image ls --tree          # recortada
lab/pricing:a06-multi      1046ac93260d   49.9MB   19.9MB
├─ linux/amd64             4dca0d5d3ef9   10.3MB   10.3MB
└─ linux/arm64             3e1e099b4755   39.6MB    9.59MB
```

Con la caché caliente del build anterior, 23,1 s para las dos. Es la forma de publicar una imagen que corra igual en el
portátil de Valentina y en el servidor amd64 del datacenter de Bogotá.

## En el cluster: la imagen que el kubelet no ve

En kind la sorpresa es la contraria a la lentitud. `kind load docker-image lab/inventory:a06-cross-amd64` carga la imagen
amd64 en el nodo arm64 sin quejarse, y el pod no arranca:

```text
a06-inventory   0/1     ErrImageNeverPull   0          15s
  Warning  ErrImageNeverPull  …  Container image "lab/inventory:a06-cross-amd64" is not present with pull policy of Never
```

Está y no está. containerd la tiene; el kubelet, que pregunta por la plataforma del nodo, no la ve:

```text
$ docker exec lab-worker ctr -n k8s.io images ls | grep a06
docker.io/lab/inventory:a06-arm64          io.cri-containerd.image=managed  linux/arm64
docker.io/lab/inventory:a06-cross-amd64    -                                linux/amd64
$ docker exec lab-worker crictl images | grep a06
docker.io/lab/inventory   a06-arm64   742fab8a36cc6   203MB
```

La de arm64, en el mismo nodo y con la misma sonda, estuvo `Ready` 3,0 s después de arrancar el contenedor, en las tres
corridas. En un cluster que baja las imágenes de un registry, el síntoma de una imagen de una sola arquitectura que no es
la del nodo es un `ImagePullBackOff` por plataforma, no un pod lento.

## El diagnóstico, en treinta segundos

```bash
docker image inspect <imagen> --format '{{.Os}}/{{.Architecture}}'      # ¿de qué arquitectura es?
docker image ls --tree | grep -A3 <imagen>                              # ¿tiene más de una?
docker exec <contenedor> uname -m                                       # ¿cómo corre? x86_64 en un Mac ARM: emulada
kubectl get node -o jsonpath='{.items[*].status.nodeInfo.architecture}' # la del cluster
docker exec <nodo> ctr -n k8s.io images ls | grep <imagen>              # en kind: ¿está, y para qué plataforma?
```

Un arranque tres o cuatro veces más lento que en la máquina de al lado, en Java, es casi siempre esto.

## 🧭 Cuándo usar qué

| Situación | Opción | Por qué |
|---|---|---|
| desarrollas y corres en la misma arquitectura | nada: el índice de la base elige solo | el caso del laboratorio |
| necesitas probar la imagen del servidor amd64 en un Mac ARM | `--platform linux/amd64`, sabiendo que Java arranca 3,6x más lento | sirve para comprobar que corre, no para medirla |
| publicas para servidores de otra arquitectura | `FROM --platform=$BUILDPLATFORM` y compilación cruzada | 28,8 s contra 80,1 s en Go; en Java, la diferencia entre terminar y no terminar |
| publicas para las dos | `--platform linux/amd64,linux/arm64`, un solo nombre | el registry entrega a cada máquina la suya |
| hay extensiones nativas | la etapa que las compila, en la arquitectura de destino (emulada o en una máquina propia) | no hay compilación cruzada para todo |

## ⚠️ Advertencias

- Las mediciones son de Docker Desktop con Rosetta; con QEMU (otras máquinas virtuales, otros motores) la emulación suele
  ser bastante más lenta, y no se midió.
- Un benchmark corrido en una imagen emulada no dice nada de la nativa. Antes de medir, `uname -m`.
- El almacén de imágenes de containerd es el que permite guardar las dos variantes juntas; con el almacén clásico de
  Docker, `--load` de varias plataformas no funciona y hay que pasar por un registry.

## 📚 Referencias

- Docker, *Multi-platform builds*: https://docs.docker.com/build/building/multi-platform/
- Docker, *Build variables* (`BUILDPLATFORM`, `TARGETOS`, `TARGETARCH`): https://docs.docker.com/build/building/variables/
- Docker Desktop, *Settings* (la emulación con Rosetta): https://docs.docker.com/desktop/settings-and-maintenance/settings/
- kind, *Loading an image into your cluster*: https://kind.sigs.k8s.io/docs/user/quick-start/#loading-an-image-into-your-cluster
- Apple, *About the Rosetta translation environment*: https://developer.apple.com/documentation/apple-silicon/about-the-rosetta-translation-environment

> ⚠️ Las URL y los contenidos cambian.

## 🧪 Ejercicios (6)

### Ejercicio 1 — ¿De qué arquitectura es?
Inspecciona las imágenes base de los cinco servicios y di cuáles tienen variante amd64 y arm64.

**Criterio:** una tabla con la imagen y sus plataformas, sacada de `docker buildx imagetools inspect` o de `docker image ls --tree`.

### Ejercicio 2 — Java, emulado
Repite la tabla de arranque con `replenish` (Node).

**Criterio:** tres corridas nativas y tres emuladas, y la proporción comparada con la de Go y la de Java.

### Ejercicio 3 — `pricing`, cruzado
Aplica las dos líneas de `$BUILDPLATFORM` al Dockerfile de `pricing` en tu repositorio y construye para amd64.

**Criterio:** el build en menos de la mitad del tiempo del emulado, y `uname -m` dentro de la imagen resultante,
corrida con `--platform linux/amd64`, dice `x86_64`.

### Ejercicio 4 — La sonda que mata
Despliega en compose la imagen amd64 de `inventory` con un `healthcheck` de 10 s de gracia, y explica el resultado.

**Criterio:** el contenedor `(unhealthy)` antes de estar listo, y la cuenta: 20,3 s de arranque contra 10 s de gracia.

### Ejercicio 5 — `catalog`, el difícil
Intenta construir `catalog` para amd64 con `$BUILDPLATFORM` en todas sus etapas, y explica dónde falla.

**Criterio:** el error de la etapa que compila las extensiones de PHP, y una propuesta de qué etapa dejar emulada.

### Ejercicio 6 — Para el datacenter de Bogotá
Publica `pricing` multiplataforma en el registry propio de la [Fase 19](19-tls-y-certificados.md) y comprueba que el nodo
la baja en su arquitectura.

**Criterio:** `docker buildx imagetools inspect` contra el registry muestra dos plataformas, y el pod corre con
`uname -m` igual a la del nodo.

---

> 🏷️ **Este apéndice no lleva tag propio.**
