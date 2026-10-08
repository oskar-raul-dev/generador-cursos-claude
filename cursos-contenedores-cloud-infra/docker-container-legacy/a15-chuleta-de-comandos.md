# 🧾 Apéndice a15 — Chuleta de comandos

> **Curso:** Docker Legacy Node · **Apéndice opcional**
> **Requisitos:** ninguno. Es una referencia rápida, pensada para tener al lado
> **Fecha de revisión de documentación externa:** 6 de septiembre de 2026 — las banderas de la CLI de Docker, Buildx y Podman
> **Qué encontrarás:** los comandos que el curso usa de verdad, agrupados por lo que quieres hacer, con la fase que los explica

El curso tiene unos cinco mil bloques de código. Esta página tiene los que se repiten. **Está
pensada para imprimirse**, así que va sin rodeos: cada bloque es "quiero hacer X", y la columna
de la derecha dice dónde está el porqué.

---

## 🧭 Índice de salto rápido

| Si lo que quieres es… | Ve a |
|---|---|
| construir una imagen, con sus banderas | [Construir](#️-construir) |
| arrancar, entrar y parar contenedores | [Ejecutar](#️-ejecutar) |
| mirar qué hay dentro de una imagen o un contenedor | [Inspeccionar](#-inspeccionar) |
| algo falla y no sabes por dónde empezar | [Diagnosticar](#-diagnosticar) · [Las diez comprobaciones](#-las-diez-comprobaciones-que-más-resuelven) |
| instalar y probar un proyecto legacy | [Validar](#-validar) |
| publicar la imagen en un registry | [Publicar](#-publicar) |
| liberar espacio sin llevarte nada por delante | [Limpiar](#-limpiar-en-orden-de-daño) |
| traducir un comando a Podman | [Docker → Podman](#-docker--podman) |
| saber qué **no** hacer | [Los seis anti-patrones](#️-los-seis-anti-patrones) |
| elegir entre dos comandos que se parecen | [Cuándo usar qué](#-cuándo-usar-qué) |

> 💡 **Si estás leyendo esto en papel**, que es para lo que está pensada, los enlaces sobran y
> los títulos de arriba son los de las secciones, en el mismo orden en que aparecen.

---

## 🏗️ Construir

```bash
# el canónico, con plataforma explícita                              F07
docker build --platform linux/amd64 -t legacy-node-toolchain:phase15 .

# un Dockerfile pedagógico concreto                                  F02
docker build --platform linux/amd64 \
  -f dockerfiles/03-toolchain.Dockerfile -t legacy-node-toolchain:phase04 .

# ver la traza completa, para diagnosticar                           F07 §9
docker build --progress=plain ...

# desde cero: comprueba que el repositorio está completo             F12 §11
docker build --no-cache ...

# parametrizar el build                                              F06 §8
docker build --build-arg NODE12_VERSION= --build-arg DEFAULT_NODE_VERSION=14.21.3 ...

# multi-plataforma: --push sí, --load no                             F21 §6.2 · F28 §7.1
docker buildx build --platform linux/amd64,linux/arm64 -t <img> --push .
docker buildx build --platform linux/arm64 --load -t <img> .
```

---

## ▶️ Ejecutar

```bash
# usar y tirar                                                       F08 §7
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase15 node --version

# elegir la generación de Node por contenedor                        F08 §6
docker run --rm -e NODE_VERSION=14.21.3 <img> node --version

# shell interactiva                                                  F08 §7
docker run --rm -it <img> bash

# el toolbox persistente: proyecto + volumen + puertos               F09 §7 · F18 §6
docker volume create miproyecto-node10-amd64-modules
docker run -d --name legacy-node-dev --platform linux/amd64 \
  -e NODE_VERSION=10.24.1 \
  --mount type=bind,src="$PWD",dst=/workspace \
  --mount type=volume,src=miproyecto-node10-amd64-modules,dst=/workspace/node_modules \
  -p 127.0.0.1:3000:3000 -p 127.0.0.1:9229:9229 \
  <img> sleep infinity

# trabajar dentro                                                    F08 §8
docker exec -it legacy-node-dev bash
docker exec legacy-node-dev npm ci
docker exec -e NODE_VERSION=16.20.2 legacy-node-dev node --version
```

---

## 🔎 Inspeccionar

```bash
# estado destilado de un contenedor                                  F30 §4
docker inspect --format '
status={{.State.Status}} exit={{.State.ExitCode}} oom={{.State.OOMKilled}}
restarts={{.RestartCount}} image={{.Config.Image}}' <ct>

# montajes: la primera pregunta cuando /workspace está vacío         F09 §9
docker inspect --format '{{json .Mounts}}' <ct> | jq

# metadatos de una imagen, sin arrancarla                            F33 §4.1
docker image inspect <img> --format '{{.Architecture}}/{{.Os}} · {{.Config.WorkingDir}}'
docker image inspect <img> --format '{{json .Config.Env}}' | jq

# capas: qué instrucción metió qué, y cuánto pesa                    F12 §6 · F33 §4.2
docker image history --no-trunc <img>

# procesos, recursos, eventos                                        F30 §4
docker top <ct>
docker stats --no-stream <ct>
docker events --since 10m --filter container=<ct>

# qué escribió el contenedor en su capa escribible                   F13 §10
docker diff <ct>
docker ps -s --filter name=<ct>
```

---

## 🩺 Diagnosticar

```bash
# el protocolo de 60 segundos: TODO lectura, ningún cambio           F30 §4
date -u +"%Y-%m-%dT%H:%M:%SZ"; docker version; docker context show
docker inspect <ct>; docker logs --timestamps --tail 200 <ct>

# ¿en qué interfaz escucha? — el 70% de "no responde"                F18 §5
docker exec <ct> ss -lntp
docker port <ct>

# ¿quién soy y de quién es esto? — antes de tocar permisos           F17 §8
docker exec <ct> id
docker exec <ct> ls -ldn /workspace /workspace/node_modules

# arquitectura: los cuatro nombres del mismo hardware                F21 §4.1
docker run --rm --platform linux/amd64 <img> bash -c '
  uname -m; node -p process.arch; dpkg --print-architecture; ldd --version | head -1'

# el ABI de Node                                                     F14 §5.1
docker run --rm -e NODE_VERSION=10.24.1 <img> node -p process.versions.modules

# diseccionar un binario nativo                                      F14 §8
file <bin>
ldd <bin> | grep 'not found'
readelf -V <bin> | grep GLIBC | sort -u
nm -D --undefined-only <bin>

# depurar desde FUERA, sin modificar el contenedor                   F30 §9.1
docker run --rm -it --pid=container:<ct> --network=container:<ct> \
  legacy-node-toolchain:diagnostic bash
docker run --rm -it --pid=container:<ct> --cap-add=SYS_PTRACE \
  legacy-node-toolchain:diagnostic strace -f -p 1
```

---

## 🧪 Validar

```bash
# la evidencia, con el exit code CORRECTO                            F20 §6.3
set -o pipefail
docker exec <ct> npm ci 2>&1 | tee install.log; echo "exit=${PIPESTATUS[0]}"

# volumen limpio antes de validar                                    F11 §6
docker volume rm <vol> 2>/dev/null; docker volume create <vol>

# la matriz de las cuatro generaciones                               F20 §7
for v in 10.24.1 12.22.12 14.21.3 16.20.2; do
  vol="proj-node${v%%.*}-amd64"
  docker volume rm "$vol" 2>/dev/null; docker volume create "$vol" >/dev/null
  echo "== Node $v"
  docker run --rm --platform linux/amd64 -e NODE_VERSION="$v" \
    --mount type=bind,src="$PWD",dst=/workspace \
    --mount type=volume,src="$vol",dst=/workspace/node_modules \
    <img> bash -c 'npm ci >/dev/null 2>&1; echo "  ci=$?"
                   npm run build >/dev/null 2>&1; echo "  build=$?"'
done

# prueba de humo del toolchain                                       F07 §9
docker run --rm <img> bash -c '
  node --version; npm --version; gcc --version | head -1
  python2 --version 2>&1; python3 --version'
```

---

## 📦 Publicar

```bash
# registry local, para aprender sin tocar Internet                   F28 §5
docker run -d --name registry-local -p 127.0.0.1:5000:5000 \
  --mount type=volume,src=registry-data,dst=/var/lib/registry registry:2

docker tag <img> localhost:5000/legacy-node-toolchain:1.0.0
docker push localhost:5000/legacy-node-toolchain:1.0.0

# autenticación SIN dejar la credencial en el historial              F28 §6
echo "$TOKEN" | docker login <registry> -u <usuario> --password-stdin

# qué plataformas tiene una imagen                                   F21 §5 · F27 §5.1
docker manifest inspect <img> | jq '.manifests[].platform'

# inspeccionar remoto sin descargar                                  F27 §8
skopeo inspect docker://<registry>/<repo>:<tag> | jq '{Digest,Architecture,Created}'
skopeo list-tags docker://<registry>/<repo> | jq '.Tags'
skopeo copy docker://<origen> docker://<destino>

# el digest, que es lo que hay que guardar para un rollback          F27 §6.3
docker inspect --format '{{index .RepoDigests 0}}' <img>

# supply chain                                                       F29
syft <img> -o spdx-json > sbom.json
trivy image --severity HIGH,CRITICAL <img>
cosign sign <img>@sha256:<digest>
```

---

## 🧹 Limpiar, en orden de daño

```bash
docker builder prune            # 1. la caché de build: lo más grande, lo menos valioso
docker image prune              # 2. imágenes colgadas
docker volume rm <nombre>       # 3. UN volumen, por su nombre
docker rm -f <ct>               # 4. un contenedor
docker system df -v             # ← mira ANTES de borrar

# ⚰️ y esto NO es un primer paso                                     F30 §8
docker system prune -a --volumes
```

---

## 🦭 Docker → Podman

| Docker | Podman |
|---|---|
| `docker <cualquier cosa>` | `podman <lo mismo>` — el 90% traduce |
| `host.docker.internal` | `host.containers.internal` |
| — | `--userns=keep-id` — resuelve los permisos de [F17](17-usuarios-permisos-y-volumenes.md) |
| — | `,U` en un `--mount type=volume` |
| — | `:z` / `:Z` para SELinux |
| almacén propio | almacén propio y **distinto**: `docker save \| podman load` |

Las diferencias completas: **[F24](24-docker-y-podman-arquitectura.md) §8**.

---

## ⚰️ Los seis anti-patrones

Todos "funcionan" a veces, y por eso son peligrosos — **[F30](30-troubleshooting-metodo-y-herramientas.md) §8**:

```text
chmod -R 777                      destruye los permisos originales
--privileged                      anula todas las protecciones a la vez
rm package-lock.json              borra la fuente de verdad del proyecto
docker system prune -a --volumes  borra la evidencia y tus node_modules
npm install --force               oculta el conflicto que te informaba
reinstalar Docker                 no arregla nada
```

**La alternativa siempre es la misma:** el protocolo de 60 segundos, situar la capa, y confirmar
antes de corregir.

---

## 🚩 Las diez comprobaciones que más resuelven

| Cuando… | Ejecuta | Fase |
|---|---|---|
| algo no responde | `docker exec <ct> ss -lntp` | [F18](18-networking-de-contenedores.md) §5 |
| `EACCES` | `docker exec <ct> id` y `ls -ldn` | [F17](17-usuarios-permisos-y-volumenes.md) §8 |
| `/workspace` vacío | `docker inspect --format '{{json .Mounts}}'` | [F09](09-montar-tu-proyecto.md) §9 |
| un binario no carga | `file <bin>` | [F14](14-abi-libc-y-prebuilds.md) §8 |
| `NODE_MODULE_VERSION` | `node -p process.versions.modules` | F14 §5.1 |
| `gyp ERR!` | `npm ls node-gyp` | [F05](05-python-y-node-gyp.md) §7 |
| el build ignora tu cambio | `--progress=plain` y busca `CACHED` | [F12](12-capas-cache-y-contexto.md) §4 |
| `stop` tarda 10 segundos | `docker exec <ct> ps -ef` → ¿quién es PID 1? | [F16](16-pid1-senales-y-ciclo-de-vida.md) §6.1 |
| el contenedor engorda | `docker diff <ct>` | [F13](13-overlayfs-y-copy-on-write.md) §10 |
| "funciona en su máquina" | el bloque de arquitectura de §Diagnosticar | [F21](21-arquitecturas-y-emulacion.md) §4.1 |

---

## 🧭 Cuándo usar qué

Media chuleta son pares de comandos que hacen casi lo mismo. Aquí está cuál de los dos, y por
qué — que es lo que convierte una lista de comandos en criterio.

**`docker stop` o `docker kill`.** `stop` pide (`SIGTERM`) y espera diez segundos antes de
matar; `kill` mata directo. **Usa siempre `stop`**, y si tarda diez segundos exactos no lo
cambies por `kill`: eso es el síntoma de que tu PID 1 no maneja señales, y taparlo con `kill`
significa que tu aplicación nunca ejecuta su cierre ordenado. → [F16](16-pid1-senales-y-ciclo-de-vida.md) §6

**`docker run` o `docker exec`.** `run` crea un contenedor **nuevo** desde la imagen; `exec`
entra en uno que ya está corriendo. Si quieres mirar el estado de algo que está pasando, es
`exec`; si quieres una prueba limpia y desechable, es `run --rm`. Confundirlos produce el
clásico *"pero si acabo de instalarlo"* — lo instalaste en otro contenedor. → [F08](08-run-el-contenedor-como-proceso.md) §8

**`docker logs` o `docker attach`.** `logs` lee lo que ya salió y no toca el proceso; `attach`
te conecta a su terminal **y tu `Ctrl+C` le llega**. En un contenedor de desarrollo, `logs -f`
es lo que quieres el 95 % de las veces. → [F18](18-networking-de-contenedores.md) §9

**Bind mount o named volume.** Bind mount para **tu código**, que quieres editar desde el host;
named volume para lo que **produce el contenedor** y no quieres que cruce la frontera —
`node_modules`, cachés—. La regla mecánica está en [F13](13-overlayfs-y-copy-on-write.md) §11 y la
operativa en [F09](09-montar-tu-proyecto.md) §5.

**`docker save` o `docker export`.** `save` guarda la **imagen** con sus capas, su historia y
sus metadatos; `export` aplana el filesystem de un **contenedor** y pierde las dos cosas. Para
mover una imagen a otra máquina o a una red aislada, siempre `save`. → [a13](a13-air-gapped.md)

**`docker build` o `docker buildx build`.** El primero basta para el día a día. `buildx` hace
falta cuando quieras **varias plataformas a la vez**, exportar la caché o publicar directo con
`--push`. → [F21](21-arquitecturas-y-emulacion.md) §6

**`npm ci` o `npm install`.** `ci` respeta el lockfile y falla si no cuadra; `install` lo
**reescribe**. En un proyecto legacy, `install` es la forma más rápida de destruir la única
prueba que tienes de qué versiones funcionaban. → [F11](11-validar-tu-proyecto.md) §5.2

**Un tag o un digest.** Tag en el laboratorio, porque se lee; digest en cualquier cosa que
publiques o que sostenga un pipeline, porque no se mueve. → [F27](27-registries-por-dentro.md) §6.2

**`--platform` o dejarlo por defecto.** **Ponlo siempre.** Sin él, lo que arranca depende de tu
CPU, de lo que ofrezca el index y de qué variante tengas ya descargada — tres factores que no
controlas y que hacen que el mismo comando dé cosas distintas en dos máquinas del mismo
equipo. → [F22](22-apple-silicon-y-hosts.md) §6

> 🧭 **Y la regla que engloba a las nueve:** cuando dos comandos se parecen, casi siempre uno
> **preserva** algo —evidencia, historia, el lockfile, el cierre ordenado— y el otro no. En un
> laboratorio de legacy, elige el que preserva. Vas a necesitar eso que el otro tira.

---

## 🧪 Ejercicios (5)

Una chuleta no se estudia: se estropea de tanto usarla. Estos cinco existen para que la tuya
deje de ser la del curso y pase a ser la tuya.

### 🟢 Ejercicio 1 — Imprime y tacha

Imprime esta página. Durante la siguiente sesión de laboratorio, marca cada comando que uses
de verdad y tacha los que no toques.

**Objetivo:** al terminar, tener la lista real de los diez o doce comandos que constituyen tu
trabajo diario. Casi nunca coincide con la que uno cree.

### 🟢 Ejercicio 2 — El que falta

Busca en tu historial de shell (`history | grep -E '^ *[0-9]+ +(docker|podman)'`) los tres
comandos que más ejecutaste durante el curso y que **no** están en esta chuleta.

**Objetivo:** añadirlos a la sección que les corresponde por intención —construir, ejecutar,
inspeccionar, diagnosticar…—, con su columna de fase. Si no sabes qué fase lo explica, ese es
justo el hueco que hay que llenar.

### 🟡 Ejercicio 3 — Traduce la columna de Podman

Toma los quince comandos que más usas de la sección Docker→Podman y ejecútalos con `podman`.
Anota los que se comportan **exactamente** igual, los que cambian de salida y los que no
existen.

**Pregunta:** ¿cuántos de los tres grupos habías predicho bien antes de ejecutar? Lo que
explica cada diferencia está en [F24 §7](24-docker-y-podman-arquitectura.md) y
[F26](26-portabilidad-entre-motores.md).

### 🟠 Ejercicio 4 — El orden de daño, defendido

La sección de limpieza ordena los comandos de menos a más destructivo. Reproduce ese orden en
un entorno de pruebas y **mide** con `docker system df` cuánto libera cada paso.

**Objetivo:** dar los números y decir en qué paso concreto habrías perdido algo que te
importaba. Después escribe la línea que le añadirías a la chuleta para que a un compañero no
le pase.

### 🔴 Ejercicio 5 — Tu chuleta de equipo

Reescribe esta página para el equipo en el que trabajas: quita lo que tu contexto no usa,
añade los comandos de vuestro registry y vuestro CI, y cambia los nombres de imagen del
laboratorio por los vuestros.

**Objetivo:** que quepa en una cara, que cada comando tenga un motivo por el que está, y que
un compañero que no hizo este curso pueda usarla sin preguntar nada. Si no cabe en una cara,
sobra algo — y decidir qué sobra es el ejercicio.

---

**Vuelve a:** [`0-programa-del-curso.md`](0-programa-del-curso.md) · el glosario está en [a16](a16-glosario.md)
