# 🧯 Parte II · Fase 31 — Catálogo de fallos I: engine, build, registry y red

> **Curso:** Docker Legacy Node
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · `linux/amd64`
> **Requisitos:** **[F30](30-troubleshooting-metodo-y-herramientas.md)**, imprescindible. Este catálogo sin el método es una lista de recetas
> **Estado de la imagen al terminar:** sin cambios
> **Fecha de revisión de documentación externa:** 6 de septiembre de 2026 — Buildx, el registry y los mensajes del motor
> **Objetivo:** el catálogo de las cuatro capas exteriores — motor, build, registry y red — con el síntoma literal, la causa, la comprobación que la confirma y la corrección

---

## 1. 🧭 Dónde estamos

[F30](30-troubleshooting-metodo-y-herramientas.md) dio el método. Estas dos fases son el catálogo, y su utilidad depende de usarlas en el orden
correcto:

> 🧭 **Sitúa la capa primero, busca la entrada después.** Buscar un mensaje de error en un
> catálogo antes de saber en qué capa estás te lleva a la entrada equivocada — porque el mismo
> mensaje aparece en capas distintas por causas distintas.

Esta fase cubre las **capas 1, 2, 5 y parte de la 3** de la taxonomía de [F30](30-troubleshooting-metodo-y-herramientas.md) §6: host, motor,
imagen y red. **[F32](32-catalogo-de-fallos-ii.md)** cubre las interiores.

**Cómo se lee cada entrada:**

```text
SÍNTOMA        el mensaje literal, como sale
CAUSA          qué lo produce de verdad
CONFIRMA       el comando que lo demuestra, antes de tocar nada
CORRIGE        el arreglo, distinguiendo parche de solución estructural
```

---

## 2. 🎯 Objetivos de esta fase

Reconocer, confirmar y corregir los fallos más frecuentes de motor, build, registry y red — y
saber cuáles de ellos **no** son un fallo sino comportamiento esperado.

---

## 3. 🚧 Qué NO entra todavía

Este catálogo es de **reconocimiento**, no de método. Cómo se investiga un fallo que no está en
ninguna lista —bisección, entorno mínimo, comparación campo a campo— es [F33](33-forense-y-boss-fight.md). Aquí cada entrada te
da el síntoma, la confirmación y la corrección, y asume que ya tienes el método de [F30](30-troubleshooting-metodo-y-herramientas.md) para
saber en qué capa estás mirando.

Tampoco entran los fallos de **APT, Node, `node-gyp`, ABI y filesystem**: son la otra mitad del
catálogo y viven en [F32](32-catalogo-de-fallos-ii.md), separados por una razón práctica —estos cinco son los que te encuentras
construyendo la imagen del curso, y los de aquí son los que te encuentras usándola.

Y no entra el arreglo de la aplicación. Si tu build falla porque tu código tiene un error de
sintaxis, el contenedor está haciendo exactamente su trabajo al decírtelo.

---

## 4. 🔌 Capa 2 — Motor

### 4.1 `Cannot connect to the Docker daemon at unix:///var/run/docker.sock`

**Causa.** El daemon no está corriendo, o tu usuario no puede hablar con el socket, o el
contexto apunta a otro sitio.

```bash
docker version                    # ¿responde el cliente y no el servidor?
docker context show && docker context ls
systemctl status docker           # en Linux
ls -la /var/run/docker.sock
groups | tr ' ' '\n' | grep docker
```

**Corrige.** Arranca el daemon, o cambia de contexto, o —lo que **no** es un arreglo trivial—
añádete al grupo `docker` sabiendo lo que concedes: [F24](24-docker-y-podman-arquitectura.md) §4.1.

> ⚠️ **En macOS y Windows este error casi siempre significa que Docker Desktop no está
> arrancado.** Antes de investigar nada, mira el icono.

### 4.2 `docker: 'buildx' is not a docker command`

**Causa.** Falta el plugin de Buildx o la instalación es antigua.

```bash
docker buildx version
ls ~/.docker/cli-plugins/
```

### 4.3 El motor responde pero todo va lentísimo

**Causa.** Recursos de la VM, no el motor. [F26](26-portabilidad-entre-motores.md) §4.

```bash
docker info --format '{{.NCPU}} CPU · {{.MemTotal}} bytes'
docker system df                  # ¿está el disco lleno?
```

**Corrige.** Sube los recursos de la VM. Si `system df` muestra decenas de gigabytes en caché de
build, `docker builder prune` — pero mira antes qué vas a borrar.

### 4.4 `no space left on device`

**Causa.** El disco de la VM, no el de tu máquina. Es la confusión frecuente en macOS y Windows.

```bash
docker system df -v
docker run --rm legacy-node-toolchain:phase15 df -h /
```

**Corrige.** `docker builder prune` primero, que es lo más voluminoso y lo menos valioso.
Después imágenes sin usar. **Los volúmenes al final y uno a uno**, porque ahí están tus
`node_modules` — [F30](30-troubleshooting-metodo-y-herramientas.md) §8.

---

## 5. 🏗️ Capa 5 — Build

### 5.1 `failed to read dockerfile: open Dockerfile: no such file or directory`

**Causa.** No hay `Dockerfile` en el contexto y no pasaste `-f`.

```bash
pwd && ls -la Dockerfile dockerfiles/
```

### 5.2 `COPY failed: file not found in build context`

**Causa.** Dos, y dan **el mismo mensaje**: el archivo está fuera del contexto, o lo excluye tu
`.dockerignore`.

```bash
ls -la <el archivo>                       # ¿existe?
grep -nE '<patrón>' .dockerignore         # ← la causa que nadie mira
```

> 🩺 **Comprueba siempre el `.dockerignore` antes de volverte loco con las rutas.** Es la mitad
> de los casos y el mensaje no lo menciona.

### 5.3 El build no refleja tu cambio

**Causa.** Caché, y casi nunca es un bug: tu cambio está **después** del paso que crees.

```bash
docker build --progress=plain ... 2>&1 | grep -E 'CACHED|^#[0-9]+ \['
```

**Corrige.** `--no-cache` desbloquea; entender **por qué** se reutilizó esa capa lo resuelve.
[F12](12-capas-cache-y-contexto.md) §4.

### 5.4 `E: Unable to locate package X` dentro del build

**Causa.** Falta `apt-get update` en el mismo `RUN`, o el paquete no existe en Buster.

```bash
docker run --rm debian/eol:buster \
  bash -c 'apt-get update -qq >/dev/null 2>&1 && apt-cache policy X'
```

**Corrige.** Si no existe en Buster, es un problema de época: busca el nombre que tenía entonces
o el paquete equivalente.

### 5.5 `The repository ... is no longer signed` / `Release file is not valid yet`

**Causa.** Los temporizadores de APT sobre un archivo histórico. [F03](03-apt-y-utilidades.md) §5.1.

```bash
docker run --rm debian/eol:buster \
  cat /etc/apt/apt.conf.d/check-valid-until.conf
```

**Corrige.** Usa `debian/eol:buster`, que ya lo trae. Si estás en `debian:buster`, ese es el
problema — [F01](01-decisiones-debian-zonas-node.md) §4.4.

### 5.6 `curl: (22) The requested URL returned error: 404`

**Causa.** El artefacto no existe: versión inexistente, o la arquitectura equivocada en el
nombre.

```bash
curl -sI https://nodejs.org/dist/v10.24.1/node-v10.24.1-linux-x64.tar.xz | head -1
```

> 🧭 **Y por qué el `-f` de `curl` importa:** sin él, la página de error se guarda como si fuera
> el tarball y el fallo aparece más tarde, en el `tar`, con un mensaje mucho peor. [F06](06-instalacion-node.md) §8.1.

### 5.7 `sha256sum: WARNING: 1 computed checksum did NOT match`

**Causa.** La descarga se corrompió, o el archivo cambió, o —lo más probable— descargaste otra
cosa.

```bash
file /tmp/node-downloads/*.tar.xz     # ¿es un tarball o un HTML?
```

**Y no es un fallo del build: es el build haciendo su trabajo.** [F06](06-instalacion-node.md) §8.1.

### 5.8 El build funciona con caché y falla con `--no-cache`

**Causa.** Depende de algo que la caché conservaba y que ya no está en el repositorio.

**Corrige.** Encuentra qué falta. **Es un hallazgo serio:** significa que tu build no construye
desde cero, y en un CI limpio va a fallar. [F12](12-capas-cache-y-contexto.md) §11.

---

## 6. 📦 Registry

### 6.1 `denied: requested access to the resource is denied`

**Causa.** Sin autenticar, o el repositorio no es tuyo, o el token no tiene permiso de escritura.

```bash
jq '.auths | keys' ~/.docker/config.json
docker info --format '{{.IndexServerAddress}}'
```

### 6.2 `unauthorized: authentication required` tras un `login` correcto

**Causa.** El token expiró, o hiciste login en un registry distinto al del tag.

> 🩺 **Compara el registry del tag con el del `config.json`.** `miapp:v1` va a Docker Hub;
> `registro.empresa.com/miapp:v1` no.

### 6.3 `manifest unknown` / `manifest for X not found`

**Causa.** Ese tag no existe en ese repositorio.

```bash
skopeo list-tags docker://<registry>/<repo> | jq '.Tags'
```

### 6.4 `no matching manifest for linux/arm64 in the manifest list entries`

**Causa.** Esa imagen no publicó tu plataforma. **No es un fallo tuyo.**

```bash
docker manifest inspect <imagen> | jq '.manifests[].platform'
```

**Corrige.** Fuerza `--platform linux/amd64` y acepta la emulación, o busca otra imagen. [F21](21-arquitecturas-y-emulacion.md) §5.

### 6.5 `http: server gave HTTP response to HTTPS client`

**Causa.** Registry sin TLS al que el motor intenta llegar por HTTPS.

**Corrige.** Con `localhost` no ocurre. Con una IP, hay que declararlo como registry inseguro —
y pensárselo dos veces. [F28](28-publicar-la-imagen.md) §5.

### 6.6 `toomanyrequests: You have reached your pull rate limit`

**Causa.** El límite de descargas de Docker Hub. **No es tu configuración.**

**Corrige.** Autenticarse sube el límite; un registry espejo lo elimina. En CI es lo que hace
fallar builds "sin motivo" un martes por la mañana.

### 6.7 `buildx --push` falla y `--load` funciona

**Causa.** Falta autenticación, o el tag no lleva el registry destino. [F28](28-publicar-la-imagen.md) §7.1.

---

## 7. 🌐 Capa 3 — Red

### 7.1 El servidor arrancó y el navegador no responde

**Las tres causas, en orden de frecuencia:**

```bash
# 1. ¿en qué interfaz escucha?  ← el 70% de los casos
docker exec <ct> ss -lntp

# 2. ¿está publicado el puerto?
docker port <ct>

# 3. ¿sigue vivo el proceso?
docker exec <ct> ps -ef
```

Si `ss` dice `127.0.0.1:3000`, ahí acabó: [F18](18-networking-de-contenedores.md) §5.

### 7.2 `port is already allocated`

```bash
docker ps --format '{{.Names}}\t{{.Ports}}'
lsof -i :3000                     # en el host
```

**Corrige.** Otro puerto en el host, o para lo que lo ocupa. Y recuerda que **los puertos se
fijan al crear** el contenedor: hay que recrearlo.

### 7.3 `host.docker.internal: Name or service not known`

**Causa.** Linux nativo sin `--add-host`, o Podman —donde el nombre es
`host.containers.internal`—. [F18](18-networking-de-contenedores.md) §7.1 y [F24](24-docker-y-podman-arquitectura.md) §10.

### 7.4 Dos contenedores no se ven por nombre

**Causa.** Están en la red `bridge` por defecto, que no tiene DNS interno.

```bash
docker inspect --format '{{json .NetworkSettings.Networks}}' <ct> | jq 'keys'
```

**Corrige.** Una red de usuario. [F18](18-networking-de-contenedores.md) §7.

### 7.5 `ETIMEDOUT` o `ENOTFOUND` durante `npm ci`

**Causa.** Sin red, DNS roto, o un proxy corporativo de por medio.

```bash
docker run --rm legacy-node-toolchain:phase15 \
  bash -c 'getent hosts registry.npmjs.org; curl -sI https://registry.npmjs.org | head -1'
docker exec <ct> printenv | grep -i proxy
```

**Corrige.** Si hay proxy, va en el build como `--build-arg` y no como `ENV` — **[a13](a13-air-gapped.md) §4.2**
explica por qué la diferencia importa el día que esa imagen salga de la oficina.

### 7.6 `unable to get local issuer certificate` / `SELF_SIGNED_CERT_IN_CHAIN`

**Causa.** Un proxy corporativo con inspección TLS, o falta `ca-certificates` — [F03](03-apt-y-utilidades.md) §10.

> ⚰️ **Y el anti-patrón que aparece siempre aquí:** `npm config set strict-ssl false` o
> `NODE_TLS_REJECT_UNAUTHORIZED=0`. Desactiva la verificación entera, no solo para tu proxy. Lo
> correcto es **añadir el certificado de la empresa** al almacén de la imagen.

**Corrige.** La receta completa está en **[a13](a13-air-gapped.md) §4**, y trae el detalle que hace que el
arreglo "a medias" parezca no funcionar: **son dos almacenes**, el del sistema y el de Node, y
tocar solo el primero deja `npm install` fallando igual que antes.

### 7.7 Los logs están vacíos

**Causa.** La aplicación escribe a un archivo, o miras el contenedor equivocado, o lo que
imprimió fue un `docker exec` — que va a tu terminal, no al log. [F18](18-networking-de-contenedores.md) §8.

---

## 8. 🖥️ Capa 1 — Host y arquitectura

### 8.1 `exec format error`

**Causa.** Arquitectura equivocada. [F21](21-arquitecturas-y-emulacion.md) §7.1.

```bash
file <el binario>
docker image inspect <imagen> --format '{{.Architecture}}'
uname -m
```

### 8.2 Todo va lentísimo en un Mac ARM

**Causa.** Emulación, o el cruce del bind mount, o las dos. **Mide antes de concluir.** [F23](23-estudios-de-caso-multiplataforma.md) §5.

```bash
docker run --rm --platform linux/amd64 <imagen> uname -m   # x86_64 → estás emulando
```

### 8.3 Falla en CI y funciona en local

**Causa.** Arquitecturas o plataformas distintas. Compara la triangulación de [F21](21-arquitecturas-y-emulacion.md) §4.1 en los
dos sitios.

---

## 9. 🗺️ Tabla de síntomas de esta fase

| Síntoma | Capa | Confirmación | Sección |
|---|---|---|---|
| `Cannot connect to the Docker daemon` | motor | `docker version` | §4.1 |
| `no space left on device` | motor | `docker system df -v` | §4.4 |
| `COPY failed: file not found` | build | `.dockerignore` | §5.2 |
| el build no refleja el cambio | build | `--progress=plain` | §5.3 |
| `Unable to locate package` | build | `apt-cache policy` | §5.4 |
| `no longer signed` | build | `apt.conf.d/` | §5.5 |
| `404` en una descarga | build | `curl -sI` | §5.6 |
| checksum no coincide | build | `file` | §5.7 |
| `denied` en un push | registry | `config.json` | §6.1 |
| `no matching manifest` | registry | `docker manifest inspect` | §6.4 |
| `toomanyrequests` | registry | — es la política del servicio | §6.6 |
| el server no responde | red | `ss -lntp` | §7.1 |
| `port is already allocated` | red | `docker ps` y `lsof` | §7.2 |
| `ETIMEDOUT` en `npm ci` | red | `getent hosts` | §7.5 |
| `SELF_SIGNED_CERT_IN_CHAIN` | red | `printenv \| grep -i proxy` | §7.6 |
| `exec format error` | host | `file` y `uname -m` | §8.1 |

---

## 10. ⚠️ Errores comunes al usar un catálogo

**Buscar el mensaje antes de situar la capa.** El mismo texto aparece en capas distintas.

**Aplicar la corrección sin la confirmación.** La columna del medio existe para que no arregles
lo que no estaba roto.

**Tratar como fallo lo que es comportamiento esperado.** §6.4, §6.6 y §5.7 no son errores tuyos.

**Parar en la corrección y no volver a la causa raíz.** [F30](30-troubleshooting-metodo-y-herramientas.md) §5.

---

## 11. 📋 Checklist de validación

```text
[ ] Sitúas la capa antes de buscar en el catálogo
[ ] Provocaste al menos ocho de las entradas de §9
[ ] Para cada una, ejecutaste la confirmación antes de la corrección
[ ] Distingues las tres entradas que NO son fallos tuyos
[ ] Sabes por qué COPY failed tiene dos causas con el mismo mensaje
[ ] Sabes por qué strict-ssl false es un anti-patrón y qué hacer en su lugar
```

---

## 12. 🧪 Ejercicios de la Fase 31 (28)

## 🟢 Fácil — provocar y confirmar (1–7)

### 🟢 Ejercicio 1 — Cuatro fallos de build

Provoca §5.1, §5.2, §5.4 y §5.6, y confirma cada uno con su comando.

### 🟢 Ejercicio 2 — El `.dockerignore` que esconde

Provoca el `COPY failed` de las **dos** formas de §5.2.

**Pregunta:** ¿se distinguen por el mensaje? ¿Qué comando los separa?

### 🟢 Ejercicio 3 — Los tres de red

Provoca §7.1 con sus tres causas y diagnostica cada una en un comando.

### 🟢 Ejercicio 4 — `no matching manifest`

Busca una imagen sin `linux/arm64` e intenta usarla en ARM.

**Objetivo:** reconocer que no es un fallo tuyo, y saber comprobarlo antes.

### 🟢 Ejercicio 5 — El disco de la VM

Ejecuta `docker system df -v` y compáralo con el `df -h` de tu host.

**Pregunta:** ¿son el mismo disco? En macOS, ¿dónde está realmente?

### 🟢 Ejercicio 6 — El checksum que salva

Corrompe un tarball descargado y reconstruye.

**Objetivo:** ver el build fallar **a propósito** y entender que eso es correcto.

### 🟢 Ejercicio 7 — El puerto ocupado

Provoca §7.2 y resuélvelo sin matar lo que no toca.

## 🟡 Intermedio — las causas que se parecen (8–13)

### 🟡 Ejercicio 8 — La confirmación primero

Toma cinco entradas y, para cada una, ejecuta **solo** la confirmación. Predice la corrección
antes de leerla.

### 🟡 Ejercicio 9 — El proxy corporativo

Simula un proxy con inspección TLS y provoca §7.6.

**Objetivo:** resolverlo **añadiendo el certificado** a la imagen, no desactivando `strict-ssl`.

### 🟡 Ejercicio 10 — DNS roto

Arranca un contenedor con un DNS inválido con `--dns` y ejecuta `npm ci`.

**Pregunta:** ¿qué error da? ¿Se distingue de no tener red?

### 🟡 Ejercicio 11 — Sin caché, sin build

Provoca §5.8 y explica qué faltaba.

**Objetivo:** entender por qué es un hallazgo y no un contratiempo.

### 🟡 Ejercicio 12 — Registry sin TLS

Levanta el registry local en una IP en lugar de `localhost` y provoca §6.5.

### 🟡 Ejercicio 13 — El límite de descargas de Docker Hub

Es la entrada del catálogo que más gente ha sufrido sin entenderla, porque el mensaje llega
cuando ya llevas media hora de build. Provócala o, si no puedes, reconstruye su diagnóstico.

```bash
curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:ratelimitpreview/test:pull" \
  | jq -r .token > /tmp/t
curl -sI -H "Authorization: Bearer $(cat /tmp/t)" \
  https://registry-1.docker.io/v2/ratelimitpreview/test/manifests/latest \
  | grep -i ratelimit
```

**Objetivo:** leer las cabeceras `RateLimit-Limit` y `RateLimit-Remaining` y decir cuántas
descargas te quedan y en qué ventana. Después repite **autenticado** con `docker login` y
compara los números.

**Pregunta:** el límite se cuenta por **pulls de manifest**, no por gigabytes. Con eso en la
mano, ¿por qué un CI que construye veinte veces al día desde la misma IP compartida lo agota y
tu portátil no? Y la de diseño: enumera las tres formas de no chocar con esto —autenticarse,
un espejo, o una imagen base propia— y di cuál corresponde a cada tamaño de equipo.

## 🟠 Difícil — cuando el síntoma engaña (14–22)

### 🟠 Ejercicio 14 — El paquete que no existe en Buster

Intenta instalar un paquete que solo exista en Debian 12.

**Pregunta:** ¿cómo averiguas su nombre en 2019, o su equivalente?

### 🟠 Ejercicio 15 — Amplía la tabla

Añade a §9 tres síntomas que hayas encontrado tú y que no estén.

### 🟠 Ejercicio 16 — El mismo mensaje, dos capas

Encuentra un mensaje de error que aparezca en **dos** capas distintas por causas distintas.

**Objetivo:** demostrar por qué situar la capa va antes de buscar en el catálogo.

### 🟠 Ejercicio 17 — Falla solo en CI

Construye algo que funcione en local y falle en un runner limpio.

**Objetivo:** llegar a §5.8 o a §8.3, y proponer la comprobación que lo detectaría antes.

### 🟠 Ejercicio 18 — El disco lleno, bien resuelto

Llena el disco de la VM y libéralo **sin** un `prune -a --volumes`.

**Pregunta:** ¿cuánto liberaste con `builder prune`? ¿Hizo falta tocar volúmenes?

### 🟠 Ejercicio 19 — Los logs vacíos, tres causas

`docker logs` no devuelve nada y el contenedor está corriendo. El catálogo lo lista como una
entrada; en realidad son **tres situaciones distintas** con el mismo síntoma, y confundirlas
manda tu diagnóstico a la capa equivocada.

**Objetivo:** provocar las tres por separado y encontrar, para cada una, la comprobación que la
distingue en un solo comando. Las tres son: el proceso escribe en un **archivo** en lugar de a
`stdout`; el proceso escribe a `stdout` pero está **buffereado** y no ha hecho flush; y el
motor está usando un **log driver** que no es `json-file`, así que `docker logs` no tiene nada
que enseñar.

```bash
docker inspect --format '{{.HostConfig.LogConfig.Type}}' mi-contenedor
docker exec mi-contenedor ls -l /proc/1/fd/1 /proc/1/fd/2
```

**Pregunta:** la segunda es la más traicionera porque **se arregla sola** en cuanto el buffer se
llena, y entonces parece un problema intermitente. ¿Cómo lo confirmas sin esperar? Y la de
fondo: ¿por qué el buffering cambia según haya o no una TTY, y qué relación tiene eso con la
opción `-t` de [F08](08-run-el-contenedor-como-proceso.md)?

### 🟠 Ejercicio 20 — `--push` funciona y `--load` no

Una de las entradas del catálogo que parece un bug del motor y es una consecuencia
arquitectónica. Reprodúcela:

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t prueba:multi --load .
```

**Objetivo:** obtener el error literal y explicarlo **sin usar la palabra "limitación"**. La
explicación real está en [F27](27-registries-por-dentro.md) §5: el almacén local tiene que
guardar algo, y ese algo tiene una forma concreta que no admite dos plataformas de la misma
manera que un registry.

Después comprueba las tres salidas: `--push` a un registry, `--load` con **una** plataforma, y
`--output type=oci,dest=...` a un tar.

**Pregunta:** si tu Docker usa el image store de containerd —compruébalo con `docker info`—,
puede que `--load` **sí** funcione. Averigua si es tu caso. Y responde a lo que eso implica:
cuando el mismo comando funciona en tu máquina y falla en la de un compañero **con la misma
versión de Docker**, ¿qué has aprendido sobre qué hay que declarar al reportar un fallo?

### 🟠 Ejercicio 21 — `host.docker.internal` no resuelve

El contenedor necesita hablar con algo que corre en tu host y el nombre mágico no responde.
Provócalo en Linux, que es donde pasa:

```bash
docker run --rm legacy-node-toolchain:phase15 getent hosts host.docker.internal
```

**Objetivo:** obtener el fallo y después arreglarlo de las **tres** formas: con
`--add-host=host.docker.internal:host-gateway`, usando la IP del bridge, y usando
`--network host`. Comprueba las tres.

**Pregunta:** ¿por qué el nombre funciona sin más en Docker Desktop y no en Docker sobre Linux?
La respuesta está en que en un caso hay una VM en medio y en el otro no, y quien inventa ese
nombre es la VM. Y la de portabilidad, que enlaza con [F24](24-docker-y-podman-arquitectura.md):
¿cuál es el equivalente en Podman, y por qué un script que use el nombre de Docker a secas no
es portable ni entre motores ni entre sistemas operativos?

### 🟠 Ejercicio 22 — El motor responde y todo va lentísimo

El síntoma más difícil del catálogo, porque no hay error: todo funciona, solo que mal. Es
también donde más gente reinstala Docker por fe. Constrúyete el procedimiento que lo evita.

**Objetivo:** una lista ordenada de comprobaciones que, en menos de cinco minutos, distinga
entre las cinco causas habituales: **disco de la VM lleno**, **poca RAM o pocos CPU asignados
a la VM**, **emulación de arquitectura** actuando sin que lo pidieras, **el bind mount
cruzando la frontera host-VM**, y **la caché de build agotada**. Cada comprobación con su
comando y con el número que la confirma o la descarta.

Después provoca al menos **dos** de las cinco y comprueba que tu lista las separa bien.

**Pregunta:** cuatro de las cinco causas se miden con `docker system df`, `docker info`,
`docker image inspect --format '{{.Architecture}}'` y una medición de I/O. ¿Cuál es la quinta y
por qué necesita un experimento en vez de una consulta? Es la lección de fondo: **algunas
causas se consultan y otras se miden**, y tratar de consultar una que hay que medir es lo que
convierte cinco minutos en una tarde.

## 🔴 Muy difícil — construir tu propio catálogo (23–28)

### 🔴 Ejercicio 23 — La cadena de tres

Provoca un fallo cuya causa esté tres capas más abajo del síntoma.

**Objetivo:** recorrer la taxonomía de [F30](30-troubleshooting-metodo-y-herramientas.md) §6 hacia abajo, documentando qué descartaste.

### 🔴 Ejercicio 24 — Los tres que no son fallo tuyo

Provoca las tres entradas que §10 marca como comportamiento esperado y escribe, para
cada una, cómo se lo explicarías a alguien que cree que rompió algo.

**Objetivo:** la explicación tiene que decir **por qué** el sistema se comporta así —no "es
normal"— y qué haría falta para que sí fuera un problema tuyo.

### 🔴 Ejercicio 25 — Tu catálogo

Escribe el catálogo de los cinco fallos que **tú** has tenido más veces en este curso, con el
mismo formato de síntoma → confirmación → corrección que usan §4 a §7.

**Objetivo:** que la comprobación sea un comando que puedas copiar, y la corrección distinga
parche de solución estructural.

### 🔴 Ejercicio 26 — El síntoma que tienen cuatro causas

Recorre el catálogo entero y busca el mensaje de error que aparezca asociado al **mayor número
de causas distintas**. Hay varios candidatos, y encontrarlo es la mitad del ejercicio.

**Objetivo:** para ese síntoma, escribir el **árbol de decisión** completo: la primera pregunta
que parte el espacio en dos, y así hasta llegar a cada causa. Cada nodo del árbol tiene que ser
un comando con una respuesta binaria, no un "mira a ver si".

Después mídelo: provoca las cuatro causas en orden aleatorio, recorre tu árbol, y anota
**cuántas comprobaciones** necesitaste en cada caso.

**Pregunta de cierre:** un árbol bien ordenado resuelve el caso medio en menos pasos que uno
mal ordenado, y el criterio para ordenarlo no es la probabilidad de cada causa sino **cuánto
espacio descarta cada pregunta**. Reordena tu árbol con ese criterio y vuelve a medir. ¿Bajó el
número? Explica por qué la pregunta más informativa no suele ser la de la causa más
frecuente.

### 🔴 Ejercicio 27 — El catálogo que no cubre tu caso

Un catálogo es una herramienta con un borde, y saber dónde está ese borde es más útil que
memorizarlo. Provoca un fallo **real** de tu proyecto o de tu entorno que **no** esté en
ninguna de las entradas de esta fase.

**Objetivo:** escribir su entrada con el formato exacto del catálogo —síntoma literal, causas
posibles ordenadas por frecuencia, comprobación que confirma cada una, corrección mínima y
prevención— y, además, la parte que un catálogo no suele traer: **por qué no estaba**. ¿Es
demasiado específico de tu stack? ¿Es nuevo? ¿O es que el curso lo dio por evidente?

**Pregunta de cierre:** de las tres respuestas anteriores, la tercera es la interesante. Repasa
el catálogo buscando **supuestos no declarados** —cosas que solo son ciertas en Docker
Desktop, o solo en amd64, o solo con el image store de containerd— y haz la lista. Un catálogo
con sus supuestos declarados vale el doble que uno que finge ser universal.

### 🔴 Ejercicio 28 — Ordena el catálogo por coste, no por tema

Esta fase agrupa los fallos por **dónde ocurren** —engine, build, registry, red—, que es lo
lógico para escribirlo y no necesariamente lo mejor para usarlo a las tres de la madrugada.

**Objetivo:** reordenar el catálogo entero por **coste de diagnóstico**: cuánto tarda de media
alguien que sabe en llegar a la causa. Ponles a todas una estimación en minutos, agrúpalas en
tres bandas —"un comando", "cinco minutos", "esto es una tarde"— y ordena.

**Pregunta de cierre:** compara tu orden con el original y responde a tres cosas. ¿Qué entradas
subieron mucho, es decir, cuáles son baratas de descartar y estaban enterradas? Con eso, ¿cómo
reescribirías el protocolo de 60 segundos de [F30](30-troubleshooting-metodo-y-herramientas.md)
§4? Y la que decide si el ejercicio sirvió: ¿qué versión del catálogo te llevarías a un
incidente real, la tuya o la del curso, y por qué? Las dos respuestas son defendibles y por
motivos distintos: una se usa mejor, la otra se estudia mejor.

## 🔥 Opcionales

### 🔥 Ejercicio 29 — Automatiza las confirmaciones

Escribe un script que, dado un síntoma, ejecute su comando de confirmación.

### 🔥 Ejercicio 30 — El registry espejo

Configura un espejo de Docker Hub para evitar §6.6.

**Pregunta:** ¿cuánto tarda un `pull` frío ahora?

## 💀 Boss fight

### 💀 Ejercicio 31 — Boss fight: el pipeline caído

Un CI que funcionaba lleva tres días fallando. Los síntomas van cambiando: un día
`toomanyrequests`, otro `COPY failed`, otro `no space left on device`.

**Objetivo:** los tres síntomas son **consecuencia de dos causas**, una de esta fase y otra de
[F12](12-capas-cache-y-contexto.md). Diagnostica sin acceso interactivo al runner —solo tienes los logs—, propón la corrección, y
escribe **las comprobaciones que el pipeline debería tener** para que el próximo fallo se
diagnostique solo. La parte difícil es que los síntomas cambian de día en día, y eso hace pensar
en tres problemas donde hay dos.

---

## 13. 📚 Referencias

- `docker inspect`, `events`, `system df`: https://docs.docker.com/reference/cli/docker/
- Solución de problemas de Docker Desktop: https://docs.docker.com/desktop/troubleshoot-and-support/troubleshoot/
- Límites de descarga de Docker Hub: https://docs.docker.com/docker-hub/download-rate-limit/
- Redes: https://docs.docker.com/engine/network/
- Registry: https://distribution.github.io/distribution/

> ⚠️ **Los mensajes de error cambian entre versiones.** Los de esta fase son los habituales en
> las versiones actuales; si el tuyo difiere en el texto exacto, la causa y la comprobación
> siguen valiendo.

---

## 14. 🏁 Resultado de la fase

```text
CÓMO SE USA     sitúa la capa (F30 §6) → busca la entrada → CONFIRMA → corrige
                nunca al revés

MOTOR           daemon, contexto, recursos de la VM, disco de la VM
BUILD           contexto y .dockerignore · caché · APT · descargas · checksums
REGISTRY        autenticación · manifest · plataforma · TLS · rate limit
RED             en qué interfaz escucha · publicación · DNS · proxy · certificados
HOST            arquitectura · emulación · diferencias con el CI

TRES QUE NO SON FALLO TUYO
                no matching manifest · toomanyrequests · checksum que no cuadra
```

> **La señal de que quedó bien:** *"leo un mensaje de error y antes de buscarlo ya sé en qué
> capa estoy y qué comando lo va a confirmar."*

En **[F32](32-catalogo-de-fallos-ii.md)** sigue el catálogo con las capas interiores: APT, Node, `node-gyp`, ABI y filesystem —
donde viven los fallos que más tiempo cuestan.
