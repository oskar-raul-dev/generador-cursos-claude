# 📎 Apéndice a07 — Construir imágenes sin Docker

> **Curso:** Laboratorio de contenedores y Kubernetes local · 🔥 Ampliación
> **Usado por:** [Fase 04](04-empaquetar-los-cuatro-runtimes.md) (las imágenes y B-04) · **Versiones cubiertas:** las de [a01](a01-el-laboratorio.md)
> **Memoria que suma al perfil `lab`:** ninguna; los constructores corren en contenedores sueltos y se van
> **Fecha de verificación ejecutada:** 05/10/2026 · macOS arm64 con Docker Desktop

**Esto no se lee de corrido.** Se entra por el índice buscando algo concreto y se sale. Contesta una pregunta que llega con
el primer pipeline de integración continua: *"¿cómo construyo la imagen donde no hay un daemon de Docker?"*, y su
variante, *"¿necesito un Dockerfile?"*.

**Qué queda fuera:** firmar imágenes y generar su inventario de componentes (SBOM), que son exclusiones del curso;
Buildpacks; construir dentro del cluster con un `Pod` (se nombra, no se arma).

---

## Índice

- [Cuatro constructores, dos familias](#cuatro-constructores-dos-familias)
- [Buildah: el Dockerfile, sin daemon](#buildah-el-dockerfile-sin-daemon)
- [Kaniko: el Dockerfile, en un contenedor sin privilegios](#kaniko-el-dockerfile-en-un-contenedor-sin-privilegios)
- [ko: Go, sin Dockerfile](#ko-go-sin-dockerfile)
- [Jib: Java, sin Dockerfile](#jib-java-sin-dockerfile)
- [La comparación, con el arnés de B-04](#la-comparación-con-el-arnés-de-b-04)
- [Lo que se pierde sin Dockerfile](#lo-que-se-pierde-sin-dockerfile)
- [Cuándo usar qué](#-cuándo-usar-qué)
- [Referencias](#-referencias)
- [Ejercicios](#-ejercicios-6)

---

## Cuatro constructores, dos familias

Una imagen es un manifiesto y unas capas en formato OCI ([Fase 03](03-el-contenedor-por-dentro.md)); cualquier programa
que las escriba bien construye una imagen. Hay dos familias:

- **Los que leen un Dockerfile**, sin el daemon de Docker: **Buildah** (de la familia de Podman) y **Kaniko** (pensado para
  correr dentro de un contenedor, en un pipeline).
- **Los que no usan Dockerfile** y arman la imagen desde el código: **ko** para Go y **Jib** para Java. No ejecutan ningún
  `RUN`: compilan con la herramienta del lenguaje y ponen el resultado sobre una base.

Las versiones de los cuatro están en [a01](a01-el-laboratorio.md). Todos corrieron en contenedores, para no instalar nada
en la máquina.

## Buildah: el Dockerfile, sin daemon

```bash
docker run --rm --privileged -v "$PWD/services/pricing:/src:ro" -v "$PWD/out:/kout" quay.io/buildah/stable:v1.43.4 \
  sh -c "buildah --storage-driver vfs bud -t lab/pricing:a07-buildah /src &&
         buildah --storage-driver vfs push lab/pricing:a07-buildah docker-archive:/kout/buildah.tar:lab/pricing:a07-buildah"
docker load -i out/buildah.tar
```

Dos detalles que no estaban en ningún tutorial y salieron del laboratorio. **Dentro de un contenedor, Buildah necesita
`--storage-driver vfs`**: con el *overlay* de siempre, sobre el *overlay* del contenedor, el primer `RUN` falla así:

```text
[1/2] STEP 4/8: RUN go mod download
process failed to start with error: fork/exec /bin/sh: invalid argument
Error: building at STEP "RUN go mod download": exit status 1
```

Y necesita `--privileged`: para ejecutar los `RUN` arma sus propios espacios de nombres. En un pipeline, ese privilegio es
la discusión. En Linux, fuera de un contenedor y sin privilegios, Buildah es lo que Podman usa por debajo
([Fase 05](05-los-dos-motores.md)); no verificado por el autor.

## Kaniko: el Dockerfile, en un contenedor sin privilegios

Kaniko ejecuta cada `RUN` **en su propio sistema de archivos**, sin espacios de nombres nuevos: por eso no pide
privilegios. Su repositorio original lo archivó Google en junio de 2025; lo mantiene un fork de Chainguard, con los
mismos autores, y las imágenes públicas de ese fork las publica un proyecto de GitLab:

```bash
docker run --rm --entrypoint /kaniko/executor \
  -v "$PWD/services/pricing:/workspace:ro" -v "$PWD/out:/kout" \
  registry.gitlab.com/gitlab-ci-utils/container-images/kaniko:v1.25.19-debug \
  --context dir:///workspace --dockerfile /workspace/Dockerfile \
  --no-push --tar-path /kout/kaniko.tar --destination lab/pricing:a07-kaniko
```

La primera corrida tuvo una sorpresa que es la naturaleza de Kaniko: el resultado se montó en `/out`, y el Dockerfile de
`pricing` compila en `/out/pricing`. Kaniko corrió ese `RUN` **sobre el sistema de archivos del contenedor**, que incluía
el montaje, y dejó el binario y la carpeta `data/` en la carpeta del host. Monta el resultado en una ruta que el
Dockerfile no use.

## ko: Go, sin Dockerfile

```bash
KO_DOCKER_REPO=lab/pricing-ko \
KO_DEFAULTBASEIMAGE=gcr.io/distroless/static-debian13@sha256:e2e927ec… \
ko build --push=false --tarball=out/ko.tar --platform=linux/arm64 --bare .
```

ko compila con `go build` y pone el binario sobre la base, la misma `distroless` de [a01](a01-el-laboratorio.md). Sin
Docker, sin Dockerfile, y con la plataforma como argumento (por defecto construye para amd64: en un Mac ARM, hay que
pedirla).

## Jib: Java, sin Dockerfile

```bash
./mvnw -B -DskipTests compile com.google.cloud.tools:jib-maven-plugin:3.5.2:buildTar \
  -Djib.from.image=eclipse-temurin@sha256:fcd7fd7b… -Djib.from.platforms=linux/arm64 \
  -Djib.to.image=lab/inventory:a07-jib -Djib.container.user=10001
docker load -i target/jib-image.tar
```

Jib separa la imagen en capas que cambian a distinto ritmo —dependencias, recursos, clases— sin que nadie lo escriba,
que es lo que el Dockerfile de `inventory` hace a mano con el `.jar` por capas de Spring Boot
([Fase 04](04-empaquetar-los-cuatro-runtimes.md)). El contrato gRPC tuvo que estar donde Maven lo espera
(`src/main/proto/`): sin el contexto de build `proto` de `task build`, Jib no tiene cómo recibirlo de afuera.

## La comparación, con el arnés de B-04

Build en frío (cada constructor en un contenedor nuevo) y primer `200`, tres corridas salvo donde se dice:

| | Build en frío | Capas | La capa del binario | Primer 200 |
|---|---|---|---|---|
| `pricing`, Dockerfile con Docker (la referencia, [a06](a06-arquitecturas-y-multiplataforma.md)) | 23,2 s (23,2–32,6) | 15 | 24,3 MB | 0,34 s (0,33–0,39) |
| `pricing`, Buildah (`vfs`) | 37,3 s (36,5–38,8) | 14 | 24,3 MB | 0,32 s (0,32–0,34) |
| `pricing`, Kaniko | 59,8 s (57,1–61,9) | 15 | 24,3 MB | 0,32 s (0,32–0,33) |
| `pricing`, ko | 30,4 s (28,1–30,9) | 15 | **35,6 MB** | 0,36 s (0,31–0,37) |
| `inventory`, Dockerfile con Docker, una corrida | 108,3 s | 14 | — | 2,82 s (2,56–2,85)\* |
| `inventory`, Jib, una corrida | 83,9 s | 10 | — | 2,54 s (2,51–2,63)\* |

\* Primer 200 en `/health/ready`, sin el agente de OpenTelemetry y con `DATA_DIR=/tmp` en la de Jib (sección siguiente).

**Lo que dice la tabla.** Los que leen el Dockerfile producen **la misma imagen**: las mismas capas de la base y la misma
capa de 24,3 MB del binario. (El tamaño total que informa Docker para la de Buildah, 57,7 MB contra 39,6 MB, sale de cómo
cuenta el archivo importado; las capas son iguales, y no separé por qué.) Lo que cambia es el costo: **Buildah dentro de un
contenedor tardó 1,6 veces lo que Docker, y Kaniko 2,6 veces**: los dos sin la caché de BuildKit, y `vfs` copia capas
enteras donde *overlay* no copia nada. ko tardó apenas más que Docker, pero su binario pesa 11,3 MB más (sin
`-ldflags="-s -w"`, ko no quita los símbolos de depuración: se configura en `.ko.yaml`). Jib fue **más rápido** que el
Dockerfile, sin daemon y sin privilegios. Arrancan igual: la forma de construir no cambia lo que corre.

No hay entrada nueva en `BENCHMARKS.md`: el resultado confirma B-04 (el peso de la imagen lo decide lo que se copia, no
quién lo copia).

## Lo que se pierde sin Dockerfile

ko y Jib construyen el binario y lo ponen sobre una base. **Todo lo demás que el Dockerfile hacía, se pierde**, y en el
laboratorio rompió las dos:

```text
$ docker run --rm lab/pricing-ko:latest
{"level":"INFO","msg":"no se pudo crear el esquema: unable to open database file (14)","service":"pricing"}

$ docker logs a07-jibcheck
WARNING: A restricted method in java.lang.System has been called
WARNING: java.lang.System::load has been called by org.sqlite.SQLiteJDBCLoader in an unnamed module (…)
{…,"msg":"Application run failed","level":"ERROR","stack_trace":"…UncategorizedScriptException: Failed to execute database script…"}
```

La carpeta de datos de G1 con su dueño (`COPY --chown` en `pricing`, `mkdir` y `chown` en `inventory`) no existe, y la
opción `--enable-native-access` que el `CMD` de `inventory` pasaba para que la JVM no escriba en texto
([Fase 18](18-logs.md)) tampoco. La de Jib, además, alcanzó a contestar `200` en `/health/live` antes de morir: una sonda de
vida no lo habría visto ([Fase 15](15-salud-y-recursos.md)). Con `DATA_DIR=/tmp` las dos arrancan; en el cluster, con
Postgres, la carpeta no hace falta. Y lo que el Dockerfile de `inventory` agrega encima —el agente de OpenTelemetry, el
publicador del outbox— hay que llevarlo a la configuración de Jib.

## 🧭 Cuándo usar qué

| Situación | Opción | Por qué |
|---|---|---|
| tienes Docker o Podman donde construyes | el motor, con BuildKit | el más rápido de la tabla, y con caché |
| un pipeline sin daemon, en Linux | Buildah | el mismo Dockerfile; dentro de un contenedor, con `vfs` y `--privileged` |
| un pipeline que no da privilegios | Kaniko (el fork mantenido) | sin privilegios; 2,6 veces más lento sin caché, y su repositorio original está archivado |
| un servicio de Go | ko | sin Dockerfile ni daemon; configura `-s -w` y lo que el Dockerfile hacía aparte |
| un servicio de Java con Maven o Gradle | Jib | capas por ritmo de cambio, sin daemon, y más rápido que el Dockerfile en este laboratorio |
| el Dockerfile hace algo más que copiar el binario | un constructor de Dockerfile | ko y Jib no lo van a hacer |

## ⚠️ Advertencias

- Kaniko de `gcr.io/kaniko-project/executor` es la imagen del repositorio archivado: ya no recibe parches.
- Construir con `--privileged` en un cluster compartido es darle al pipeline el nodo entero.
- Las mediciones son de un portátil, con los constructores en contenedores de Docker Desktop; en un Linux nativo, Buildah
  no necesita `vfs` y el número cambia (no verificado por el autor).

## 📚 Referencias

- Buildah: https://buildah.io/ y *buildah-build*: https://github.com/containers/buildah/blob/main/docs/buildah-build.1.md
- Kaniko, el fork mantenido: https://github.com/chainguard-forks/kaniko · sus imágenes públicas:
  https://gitlab.com/gitlab-ci-utils/container-images/kaniko · el repositorio original, archivado:
  https://github.com/GoogleContainerTools/kaniko
- ko: https://ko.build/ y su configuración (`.ko.yaml`, `ldflags`): https://ko.build/configuration/
- Jib para Maven: https://github.com/GoogleContainerTools/jib/tree/master/jib-maven-plugin

> ⚠️ Las URL y los contenidos cambian.

## 🧪 Ejercicios (6)

### Ejercicio 1 — Buildah, en tu máquina
Construye `pricing` con Buildah en un contenedor, como en la sección de Buildah, y cárgala.

**Criterio:** `docker image inspect lab/pricing:a07-buildah --format '{{.Architecture}}'` dice `arm64` (o la de tu máquina),
y la imagen contesta 200 en `/health/live`.

### Ejercicio 2 — El error del *overlay*
Quita `--storage-driver vfs` y reproduce el error del primer `RUN`.

**Criterio:** `fork/exec /bin/sh: invalid argument` en `STEP 4/8`, y una frase que explique por qué `vfs` lo evita.

### Ejercicio 3 — ko, con los símbolos fuera
Agrega un `.ko.yaml` a `pricing` con `-s -w` en `ldflags` y repite el build.

**Criterio:** la capa del binario de la imagen de ko igual a la del Dockerfile (24,3 MB), en `docker history`.

### Ejercicio 4 — ko, sin la carpeta de datos
Haz que la imagen de ko arranque sin `DATA_DIR=/tmp`.

**Criterio:** `docker run --rm lab/pricing-ko:latest` contesta 200 en `/health/live` y no escribe `unable to open database
file`. **Pista:** la carpeta `kodata/` de ko, o un `DATA_DIR` por defecto que exista en la base.

### Ejercicio 5 — Jib, completo
Lleva a la configuración de Jib lo que el Dockerfile de `inventory` hace aparte: la carpeta de datos, la opción
`--enable-native-access` y el agente de OpenTelemetry.

**Criterio:** la imagen de Jib pasa la suite de G7 en el cluster ([Fase 18](18-logs.md)): ninguna línea fuera de JSON.

### Ejercicio 6 — Kaniko, sin privilegios, en el cluster
Corre Kaniko como un `Pod` en el namespace `default` del cluster `lab`, construyendo `pricing` desde un `ConfigMap` o un
volumen, con el endurecimiento de la [Fase 20](20-seguridad-del-pod-y-de-la-red.md).

**Criterio:** el pod termina `Completed` sin `privileged: true`, y el tar resultante carga con `docker load`.

---

> 🏷️ **Este apéndice no lleva tag propio.**
