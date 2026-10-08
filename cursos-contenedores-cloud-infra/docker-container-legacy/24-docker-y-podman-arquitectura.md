# 🐳🦭 Parte II · Fase 24 — Docker y Podman: dos arquitecturas para el mismo problema

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · `linux/amd64`
> **Requisitos:** **[F12](12-capas-cache-y-contexto.md)** (build), **[F16](16-pid1-senales-y-ciclo-de-vida.md)** (procesos), **[F18](18-networking-de-contenedores.md)** (red)
> **Fecha de revisión de comportamiento de productos:** 3 de septiembre de 2026
> **⚠️ Alcance de la verificación (6 de septiembre de 2026):** el barrido de verificación ejecutada del curso se corrió sobre **Docker 29.6.2** y no sobre Podman, que no estaba instalado en la máquina de referencia. **Los comandos `podman` de esta fase están contrastados contra la documentación oficial de Podman, no ejecutados**, y así se declaran por lo que pide la guía del curso: si no está verificado, se dice. Si los corres y algo no coincide, tu terminal tiene razón y este documento no.
> **Estado de la imagen al terminar:** sin cambios — el Dockerfile es el mismo para los dos motores
> **Objetivo:** comparar dos arquitecturas sin hacer fútbol: cliente/daemon frente a fork-exec, qué estandariza OCI y qué no, y por qué "la CLI es compatible" no significa "son lo mismo"

---

## 1. 🧭 Dónde estamos

Llevas veintitrés fases con `docker` en los ejemplos y una nota recurrente de que Podman existe
y no es idéntico. Esta fase es donde el curso paga esa deuda.

Y empieza declarando cómo se va a comparar, porque en este tema abunda lo contrario:

> 🥊 **No vamos a buscar un ganador.** Son dos arquitecturas con decisiones de diseño
> distintas, cada una con consecuencias reales. El objetivo es que sepas **qué cambia** y
> puedas elegir por criterio.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder:

- Dibujar la arquitectura de Docker y la de Podman, con sus piezas nombradas.
- Explicar qué es el **socket de Docker** y por qué acceder a él es tan delicado.
- Decir qué son `containerd`, un `shim`, `conmon`, `libpod`, `runc` y `crun`.
- Explicar qué estandariza **OCI** y —más importante— qué **no**.
- Traducir comandos entre los dos motores sabiendo dónde la equivalencia se rompe.
- Entender qué es un **pod** y por qué Docker no tiene el concepto.

---

## 3. 🚧 Qué NO entra todavía

- **Rootless y user namespaces**, el mayor diferenciador de Podman → **[F25](25-rootless-y-user-namespaces.md)**.
- **Portabilidad práctica**: rendimiento medido, scripts que funcionen en los dos, matriz de
  decisión → **[F26](26-portabilidad-entre-motores.md)**.
- **Compose** más allá de mencionarlo → **[a10](a10-docker-compose.md)**.

> 🗓️ **Esta fase envejece.** Los dos productos cambian rápido: piezas del stack de Docker se
> han sustituido varias veces y Podman gana funciones cada versión. **Los modelos
> arquitectónicos son estables; los detalles de implementación no.** Cuando dudes, ejecuta los
> comandos de inspección de §4.4 y §5.5 en tu máquina en lugar de fiarte del texto.

---

## 4. 🐳 Docker: cliente y servidor

Lo primero que sorprende al mirarlo de cerca: **el comando `docker` casi no hace nada**. Es un
cliente que habla con un servicio.

```mermaid
flowchart TD
    C["docker run ..."] -- "API HTTP sobre un socket Unix" --> D["dockerd<br/>el daemon: siempre corriendo, normalmente como root"]
    D --> CD["containerd<br/>gestiona el ciclo de vida y las imágenes"]
    CD --> S["containerd-shim<br/>un proceso por contenedor"]
    S --> R["runc<br/>crea el contenedor y se retira"]
    R --> P["tu proceso<br/>PID 1 del contenedor (F16)"]
```

### 4.1 El socket

```bash
ls -la /var/run/docker.sock
```
```text
srw-rw---- 1 root docker 0 sep  4 09:12 /var/run/docker.sock
```

**Es una API de control, no "un archivo cualquiera".** Todo lo que hace la CLI son peticiones
HTTP a ese socket:

```bash
curl --unix-socket /var/run/docker.sock http://localhost/version | jq
curl --unix-socket /var/run/docker.sock http://localhost/containers/json | jq
```

> 🚨 **Y aquí está la consecuencia que [F19](19-dev-containers.md) §8 anticipó.** Quien puede hablar con ese socket
> puede pedirle a `dockerd` —que corre como root— que arranque un contenedor privilegiado que
> monte `/` del host. **Acceso al socket ≈ acceso root al host.** No es una exageración: es la
> consecuencia directa del modelo. Por eso pertenecer al grupo `docker` no es un permiso
> menor, y por eso el curso no monta el socket en el Dev Container.

### 4.2 `containerd` no es "el contenedor"

`containerd` es un runtime de alto nivel: gestiona imágenes, snapshots, redes y el ciclo de
vida. **No ejecuta procesos directamente**: delega en un runtime de bajo nivel.

### 4.3 El `shim`, y para qué existe

Por cada contenedor hay un `containerd-shim`. Su trabajo parece humilde y resuelve un problema
real:

- **Mantiene vivo el contenedor si `containerd` se reinicia.** Sin él, reiniciar el daemon
  mataría todo lo que corre.
- **Conserva `stdin`, `stdout` y `stderr`** del contenedor.
- **Recoge el código de salida** cuando el proceso termina.

`runc`, en cambio, **crea el contenedor y se va**: configura namespaces y cgroups, lanza el
proceso y termina. No se queda supervisando nada.

### 4.4 Inspecciónalo tú

```bash
docker info --format '{{.ServerVersion}} · {{.Driver}} · {{.DefaultRuntime}}'
docker version --format '{{.Server.Version}}'
ps -ef | grep -E 'dockerd|containerd|shim' | grep -v grep
```

> 📝 **El stack de Docker ha cambiado varias veces.** Ha habido épocas con `docker-containerd`,
> con `dockershim` para Kubernetes —retirado—, y ahora con el *image store* de containerd
> como opción. Si un tutorial de 2018 describe piezas que no encuentras, no está mal escrito:
> está viejo. Los comandos de arriba te dicen qué tienes tú.

---

## 5. 🦭 Podman: sin daemon central

La frase famosa es *"Podman es daemonless"*, y como toda frase famosa necesita matices.

```mermaid
flowchart TD
    C["podman run ..."] -- "fork-exec: el proceso lo lanza TU comando, con TU usuario" --> L["libpod<br/>la biblioteca donde vive la lógica"]
    L --> M["conmon<br/>un monitor por contenedor"]
    M --> R["crun o runc<br/>crea el contenedor y se retira"]
    R --> P["tu proceso"]
```

### 5.1 El modelo fork-exec

No hay un servicio central que reciba tu petición y lance el contenedor **por ti**. Tu comando
`podman` hace el trabajo directamente, y el contenedor resulta ser **descendiente de tu
proceso**, con tu usuario.

De ahí salen tres consecuencias:

- **No hay socket privilegiado por defecto**, así que no hay el problema de §4.1.
- **Rootless es natural**, no un modo especial. Es de **[F25](25-rootless-y-user-namespaces.md)**.
- **Se integra con `systemd`** de forma directa, porque los contenedores son procesos normales
  del usuario.

### 5.2 `conmon` es el equivalente al shim

Hace lo mismo que el `containerd-shim`: monitoriza el contenedor, conserva sus flujos y recoge
su código de salida. Un `conmon` por contenedor.

### 5.3 `crun` frente a `runc`

Los dos son runtimes OCI de bajo nivel e intercambiables. `runc` está escrito en Go; `crun` en
C, y es más pequeño y algo más rápido al arrancar. Podman suele usar `crun` por defecto en
Linux, Docker usa `runc`.

**Que sean intercambiables es exactamente lo que la especificación OCI promete**, y es el mejor
ejemplo de que el estándar funciona.

### 5.4 Entonces, ¿Podman no tiene servicio?

Tiene uno **opcional**: `podman system service` expone una API compatible con la de Docker, para
herramientas que esperan hablar con un socket —IDEs, Testcontainers, extensiones—.

La diferencia importante es que **es opcional y puede activarse por socket**: systemd lo arranca
cuando alguien se conecta y lo para cuando no. No hay un daemon permanente como root.

### 5.5 Inspecciónalo tú

```bash
podman info --format '{{.Version.Version}} · {{.Store.GraphDriverName}}'
podman info --format '{{.Host.OCIRuntime.Name}} · {{.Host.OCIRuntime.Version}}'
ps -ef | grep -E 'conmon|crun|runc' | grep -v grep
```

---

## 6. 📊 Las dos arquitecturas, lado a lado

| | Docker | Podman |
|---|---|---|
| **Modelo** | cliente/servidor | fork-exec |
| **Proceso permanente** | `dockerd` + `containerd` | ninguno obligatorio |
| **Quién lanza el contenedor** | el daemon | tu propio comando |
| **Monitor por contenedor** | `containerd-shim` | `conmon` |
| **Runtime OCI** | `runc` | `crun` o `runc` |
| **Socket** | siempre, y es privilegiado | opcional, activable por socket |
| **Rootless** | posible, es un modo aparte | el modo natural |
| **Integración con systemd** | por el daemon | directa, por contenedor |
| **Concepto de pod** | no | sí, nativo |
| **Almacén local** | el suyo | el suyo, **distinto** |

> 🧭 **La diferencia que lo explica casi todo:** en Docker, el contenedor es hijo de un servicio
> del sistema. En Podman, es hijo tuyo. Casi todas las demás diferencias se derivan de ahí.

---

## 7. 🧩 OCI: qué estandariza y qué no

**OCI** —*Open Container Initiative*— es lo que permite que los dos motores construyan y
ejecuten lo mismo. Son tres especificaciones:

| Especificación | Qué define |
|---|---|
| **Image** | el formato de una imagen: manifest, config, capas, image index |
| **Runtime** | cómo se ejecuta un *filesystem bundle*: namespaces, cgroups, ciclo de vida |
| **Distribution** | el protocolo de un registry: cómo se sube y se baja |

### 7.1 Lo que OCI NO estandariza, y es la mitad del asunto

```text
✅ estandarizado          ❌ NO estandarizado
─────────────────         ───────────────────
el formato de imagen      la CLI y sus banderas
cómo se ejecuta           el almacén local en disco
el protocolo del registry el formato del Dockerfile
                          las redes y sus drivers
                          los volúmenes y su gestión
                          Compose y sus equivalentes
```

**El `Dockerfile` no es un estándar OCI.** Es un formato de Docker que Buildah y otros
implementan por compatibilidad de facto. Funciona en los dos, y no porque una especificación lo
garantice.

### 7.2 Tres niveles de portabilidad

```text
1. LA IMAGEN          🟢 totalmente portable — es OCI
   una imagen construida con Docker corre en Podman y al revés

2. EL DOCKERFILE      🟡 portable en la práctica
   los dos lo construyen; las extensiones de BuildKit no siempre

3. LOS COMANDOS       🟠 compatibles, no idénticos
   el 90% traduce cambiando el binario; el 10% restante es esta fase
```

> 🧠 **El modelo mental:** lo que **viaja** —la imagen— está estandarizado. Lo que **haces con
> ella** en tu máquina, no. Por eso puedes construir en un motor y ejecutar en el otro sin
> problema, y por eso tus scripts no son portables gratis.

---

## 8. ⌨️ Traducir comandos, y dónde se rompe

La equivalencia básica es tan directa que da confianza de más:

```bash
docker build   →  podman build
docker run     →  podman run
docker exec    →  podman exec
docker logs    →  podman logs
docker ps      →  podman ps
docker images  →  podman images
```

Hay incluso quien hace `alias docker=podman`, y funciona sorprendentemente bien.

**Y aquí es donde hay que tener cuidado:**

> ⚠️ **Banderas parecidas pueden esconder backends distintos.** Que un comando se acepte no
> significa que haga lo mismo. Las diferencias reales de este curso:

| Área | Docker | Podman | Dónde se trata |
|---|---|---|---|
| **Almacén de imágenes** | el suyo | el suyo, **separado** | §9 |
| **Volúmenes** | `docker volume` | `podman volume`, con `:U` | **[F17](17-usuarios-permisos-y-volumenes.md) §7** |
| **SELinux** | no lo gestiona | `:z` y `:Z` | **F17 §7** |
| **Usuarios** | `--user` | `--user` y `--userns=keep-id` | **[F25](25-rootless-y-user-namespaces.md)** |
| **Red** | `bridge` propio | `netavark` o `slirp4netns` | §10 |
| **Host desde el contenedor** | `host.docker.internal` | `host.containers.internal` | §10 |
| **Restart policies** | las gestiona el daemon | dependen de systemd | **[F16](16-pid1-senales-y-ciclo-de-vida.md) §10** |
| **Build** | BuildKit | Buildah | §11 |
| **Compose** | integrado | `podman-compose` o el servicio | **[a10](a10-docker-compose.md)** |

---

## 9. 📦 Dos almacenes locales, y una consecuencia práctica

Cada motor guarda sus imágenes en su propio sitio, con su propio formato:

```text
Docker   → /var/lib/docker/       (o dentro de la VM en macOS/Windows)
Podman   → ~/.local/share/containers/storage/   (rootless)
           /var/lib/containers/storage/          (rootful)
```

**No se ven entre sí.** Una imagen construida con Docker **no aparece** en `podman images`,
aunque sea la misma máquina.

> 🩺 **El síntoma:** construyes con `docker build -t legacy-node-toolchain:phase15 .` y después
> `podman run legacy-node-toolchain:phase15` intenta **descargarla de Docker Hub** — y falla, o
> peor, descarga una imagen ajena con ese nombre.

Para mover una imagen entre los dos, sin registry de por medio:

```bash
docker save legacy-node-toolchain:phase15 | podman load
```

O, más limpio, construir con cada uno. **[F28](28-publicar-la-imagen.md)** enseña el camino del registry, que es el
correcto cuando hay más de una máquina.

> ⚠️ **Y una regla para las comparaciones de [F26](26-portabilidad-entre-motores.md):** no compartas `node_modules` entre motores
> durante una comparación. Aunque el ABI y la arquitectura coincidan, mezclar estados hace que
> midas cualquier cosa menos lo que crees.

---

## 10. 🌐 Redes y pods

**Las redes difieren en implementación.** Podman usa `netavark` en versiones recientes —antes
CNI—, y en rootless usa `slirp4netns` o `pasta`, que emulan la red en espacio de usuario. El
resultado funcional es parecido y el rendimiento y los detalles no son idénticos.

**Y el nombre del host cambia:**

```bash
# Docker
docker run --rm alpine ping -c1 host.docker.internal
# Podman
podman run --rm alpine ping -c1 host.containers.internal
```

Es una de esas diferencias pequeñas que rompen un script y cuestan veinte minutos.

### 10.1 Pods: el concepto que Docker no tiene

Un **pod** en Podman es un grupo de contenedores que **comparten namespaces** —típicamente el
de red— y que se gestionan como una unidad.

```bash
podman pod create --name legacy-lab -p 127.0.0.1:8080:8080
podman run -d --pod legacy-lab --name app  legacy-node-toolchain:phase15 npm start
podman run -d --pod legacy-lab --name db   postgres:11
```

Dentro del pod, `app` llega a `db` por `localhost:5432` — porque comparten el network
namespace, literalmente.

> 🧭 **Y de dónde viene la idea:** es el mismo concepto de pod de Kubernetes, que Podman
> implementa localmente. Su ventaja real es que `podman generate kube` produce un manifiesto
> desde tu pod local. Para nuestro laboratorio no hace falta —Kubernetes está fuera de
> alcance—, pero explica muchas decisiones de diseño de Podman.

---

## 11. 🏗️ Buildah frente a BuildKit

Los dos construyen imágenes desde un `Dockerfile` y llegan a resultados equivalentes por
caminos distintos.

| | BuildKit (Docker) | Buildah (Podman) |
|---|---|---|
| Cómo se invoca | `docker build`, `docker buildx` | `podman build`, o `buildah` directo |
| Caché | avanzada, con cache mounts y exportadores | más simple |
| Paralelismo | sí, entre etapas independientes | más limitado |
| Sin Dockerfile | no | **sí**: `buildah` tiene comandos propios |
| Extensiones | `--mount=type=cache`, `type=secret` | soporte parcial |

**La capacidad más distintiva de Buildah** es construir imágenes **sin Dockerfile**, con
comandos de shell:

```bash
ctr=$(buildah from debian/eol:buster)
buildah run "$ctr" -- apt-get update
buildah config --workingdir /workspace "$ctr"
buildah commit "$ctr" mi-imagen:v1
```

Es útil para generar imágenes desde un script, y es exactamente lo que un `Dockerfile` no te
deja hacer.

> ⚠️ **Las extensiones de BuildKit no son portables.** Un Dockerfile con
> `RUN --mount=type=cache` puede no funcionar igual con Buildah. El curso no las usa en el
> tronco principal, y esta es una de las razones.

---

## 12. 🐙 Compose, mencionado sin esconder los fundamentos

Docker trae Compose integrado; en Podman hay dos caminos: `podman-compose` —una implementación
aparte, con su propia cobertura— o levantar `podman system service` y usar Docker Compose
contra él.

> 🧭 **La regla del curso sigue vigente**, y ahora tiene su justificación completa: Compose es
> una capa sobre `docker run`. Si entiendes puertos ([F18](18-networking-de-contenedores.md)), volúmenes ([F09](09-montar-tu-proyecto.md)), redes (§10) y ciclo
> de vida ([F16](16-pid1-senales-y-ciclo-de-vida.md)), Compose se aprende en una tarde. Al revés, no: empezar por Compose deja huecos
> que aparecen el día que algo no funciona. Su apéndice es **[a10](a10-docker-compose.md)**.

---

## 13. ⚠️ Errores comunes y diagnóstico

**`podman run` intenta descargar una imagen que acabas de construir con Docker.** Dos almacenes.
§9.

**`host.docker.internal` no resuelve en Podman.** Es `host.containers.internal`. §10.

**Un script funciona con Docker y falla con Podman.** El 90% traduce; esto es el 10%. Mira la
tabla de §8 y localiza el área.

**Los permisos de un volumen se comportan distinto.** Es rootless y user namespaces — **[F25](25-rootless-y-user-namespaces.md)**.

**`RUN --mount=type=cache` falla con Podman.** Extensión de BuildKit. §11.

**Un contenedor con `--restart=always` no revive tras reiniciar en Podman.** No hay daemon que
lo haga: hace falta la integración con systemd. **[F16](16-pid1-senales-y-ciclo-de-vida.md) §10**.

**Las dos CLI dan versiones distintas de la misma imagen.** Comprueba el digest, no el tag —
[F12](12-capas-cache-y-contexto.md) §7.

---

## 14. 📋 Checklist de validación

```text
[ ] Puedes dibujar los dos stacks con sus piezas nombradas
[ ] Hablaste con el socket de Docker usando curl
[ ] Sabes por qué el acceso al socket equivale a acceso root
[ ] Identificaste dockerd, containerd y un shim en tu máquina
[ ] Identificaste conmon y crun o runc con Podman
[ ] Sabes qué estandariza OCI y qué no
[ ] Construiste la misma imagen con los dos motores
[ ] Comprobaste que los almacenes no se ven entre sí
[ ] Moviste una imagen de uno a otro con save y load
[ ] Creaste un pod y comprobaste que sus contenedores comparten localhost
```

---

## 15. 🧪 Ejercicios de la Fase 24 (25)

## 🟢 Fácil — ver las dos arquitecturas (1–6)

### 🟢 Ejercicio 1 — Habla con el socket

Ejecuta los dos `curl` de §4.1 y compara la salida con la de `docker version` y `docker ps`.

**Objetivo:** comprobar que la CLI es un cliente HTTP con buena presentación.

### 🟢 Ejercicio 2 — Los procesos de Docker

Con un contenedor corriendo, ejecuta el `ps -ef` de §4.4.

**Pregunta:** ¿cuántos procesos participan? ¿Cuál es el padre de tu proceso del contenedor?

### 🟢 Ejercicio 3 — Los procesos de Podman

Repite con Podman y el `ps -ef` de §5.5.

**Pregunta:** ¿quién es el padre del contenedor ahora? Es la diferencia de §5.1 hecha árbol de
procesos.

### 🟢 Ejercicio 4 — El mismo Dockerfile

Construye el canónico con los dos motores y compara tamaño y número de capas.

**Pregunta:** ¿son idénticos? Si no, ¿en qué difieren?

### 🟢 Ejercicio 5 — Los runtimes

Averigua qué runtime OCI usa cada motor en tu máquina.

**Pregunta:** ¿`runc` o `crun`? ¿Puedes cambiarlo?

### 🟢 Ejercicio 6 — Quién queda cuando cierras la sesión

La diferencia arquitectónica de esta fase se ve mejor con un experimento tonto. Arranca un
contenedor en segundo plano con cada motor, cierra la terminal entera —no el contenedor, la
terminal— y vuelve a abrir otra.

```bash
docker run -d --name vivo-d legacy-node-toolchain:phase15 sleep 600
podman run -d --name vivo-p legacy-node-toolchain:phase15 sleep 600
# cierra la terminal, abre otra
docker ps ; podman ps
```

**Objetivo:** comprobar que los dos siguen ahí y entender **por qué** en cada caso, que no es
el mismo motivo. Uno lo mantiene vivo un demonio que nunca dependió de tu sesión; el otro lo
mantiene un `conmon` que se desvinculó de ella a propósito.

**Pregunta:** ahora reinicia la máquina y vuelve a mirar. ¿Sobrevive alguno? La respuesta
depende de cosas que §5 explica —el servicio del demonio en un caso, la
`lingering` de systemd en el otro— y es la diferencia práctica que más se nota al pasar de un
motor al otro.

## 🟡 Intermedio — usar los dos motores (7–14)

### 🟡 Ejercicio 7 — Los dos almacenes

Construye una imagen con Docker y ejecuta `podman images`.

**Objetivo:** confirmar §9 y entender el síntoma antes de sufrirlo.

### 🟡 Ejercicio 8 — Mueve una imagen

Usa `docker save | podman load` y verifica que aparece.

### 🟡 Ejercicio 9 — Traduce tu `run-dev.sh`

Adapta el script de [F09](09-montar-tu-proyecto.md) para que funcione con Podman.

**Objetivo:** encontrar cuántas líneas hay que tocar de verdad. Suelen ser menos de las que
esperas, y las que hay son las de la tabla de §8.

### 🟡 Ejercicio 10 — El nombre del host

Prueba `host.docker.internal` y `host.containers.internal` en los dos motores.

**Objetivo:** ver las cuatro combinaciones y saber cuáles funcionan.

### 🟡 Ejercicio 11 — Un pod

Crea el pod de §10.1 con dos contenedores y comprueba que se ven por `localhost`.

**Pregunta:** ¿qué namespace comparten exactamente? Compruébalo con `ip addr` en los dos.

### 🟡 Ejercicio 12 — `podman generate kube`

Sobre el pod del ejercicio 11, ejecuta `podman generate kube`.

**Objetivo:** ver el manifiesto que produce y entender de dónde viene el concepto de pod.

### 🟡 Ejercicio 13 — Buildah sin Dockerfile

Construye una imagen mínima con los comandos de §11.

**Pregunta:** ¿en qué se parece y en qué no a escribir un Dockerfile? ¿Cuándo te vendría bien?

### 🟡 Ejercicio 14 — El árbol de procesos, lado a lado

Con un contenedor corriendo en cada motor, dibuja los dos árboles completos:

```bash
pstree -p $(pgrep -f 'dockerd|containerd' | head -1) 2>/dev/null | head -20
pstree -p $$ | head -20        # desde tu shell, con el contenedor de Podman corriendo
```

**Objetivo:** un diagrama por motor —a mano, o en Mermaid como los de esta fase— que llegue desde el proceso
más alto hasta el `sleep` de dentro del contenedor, nombrando cada eslabón: cliente, demonio,
`containerd`, `shim`, `runc` en un caso; cliente, `conmon`, `crun`/`runc` en el otro.

**Pregunta:** en uno de los dos árboles, tu contenedor **desciende de tu shell**; en el otro,
no desciende de nada tuyo. Señala cuál es cuál y explica qué consecuencia tiene eso para tres
cosas concretas: quién recibe las señales, quién es el dueño de los archivos que el contenedor
escribe, y qué pasa si el proceso de más arriba se cae.

## 🟠 Difícil — donde la compatibilidad se rompe (15–21)

### 🟠 Ejercicio 15 — El socket opcional de Podman

Levanta `podman system service` y habla con él usando el cliente de Docker.

**Objetivo:** comprobar la compatibilidad de API y entender qué habilita para IDEs y
herramientas.

### 🟠 Ejercicio 16 — Valida un fixture en los dos

Ejecuta el protocolo de [F11](11-validar-tu-proyecto.md) sobre un fixture con cada motor, con volúmenes **separados**.

**Pregunta:** ¿mismo resultado? ¿Alguna etapa se comportó distinto?

### 🟠 Ejercicio 17 — El script que solo funciona en uno

Escribe deliberadamente un script que funcione con Docker y falle con Podman, **sin** usar el
nombre del binario.

**Objetivo:** encontrar una diferencia real de la tabla de §8 y explicarla.

### 🟠 Ejercicio 18 — El socket, demostrado

En una máquina de pruebas —y solo ahí—, demuestra por qué el acceso al socket equivale a acceso
root: arranca desde un contenedor otro contenedor que monte el `/` del host.

**Objetivo:** entender el riesgo de primera mano. **No lo hagas en una máquina que te importe**,
y borra todo después.

### 🟠 Ejercicio 19 — La caché no se traduce

Construye con Docker, reconstruye tocando una línea, y anota qué pasos dijeron `CACHED`. Repite
con Podman.

**Pregunta:** ¿coinciden paso a paso? ¿Qué implica eso para un pipeline que asume una caché
concreta?

### 🟠 Ejercicio 20 — El mismo `docker run`, traducido y roto

Coge el `docker run` más largo de tu laboratorio —el toolbox de
[F09](09-montar-tu-proyecto.md), con sus dos mounts, su `-e` y su `-w`— y ejecútalo tal cual con
`podman run`, sin cambiar ni una letra.

**Objetivo:** hacer inventario de lo que pasa. Habrá tres categorías: opciones que funcionan
idénticas, opciones que funcionan **pero con otro resultado** —los permisos de los archivos que
el contenedor escribe son el caso clásico—, y opciones que fallan directamente.

Para cada elemento de las dos últimas categorías, di **por qué** con lo que sabes de §5 y de
[F25](25-rootless-y-user-namespaces.md).

**Pregunta:** "la CLI es compatible" es cierto y es insuficiente. Reescribe esa frase de forma
que sea a la vez cierta y útil para alguien que va a migrar mañana. Tiene que caber en dos
líneas y mencionar en qué nivel está la compatibilidad y en cuál no.

### 🟠 Ejercicio 21 — Dos almacenes que no se ven

Construye la misma imagen con los dos motores y demuestra con evidencia que **no comparten
nada**:

```bash
docker images legacy-node-toolchain
podman images legacy-node-toolchain
docker system df ; podman system df
```

**Objetivo:** enseñar que la misma imagen ocupa espacio **dos veces** en tu disco, y decir
cuánto en total. Después localiza dónde vive cada almacén en tu máquina y comprueba que son
rutas distintas.

**Pregunta:** ahora mueve una imagen de uno a otro con `docker save | podman load` y compara
los digests de las dos copias. ¿Son el mismo? Si lo son, ¿por qué entonces no se ven entre
ellas — es un problema de formato o de ubicación? La respuesta separa dos ideas que se
confunden todo el tiempo: **el formato OCI es un estándar; el almacén local no lo es**, y §9 lo
explica.

## 🔴 Muy difícil — migración y criterio (22–25)

### 🔴 Ejercicio 22 — Un contenedor huérfano

Con Podman, arranca un contenedor en foreground y mata el proceso `podman` del padre desde otra
terminal.

**Pregunta:** ¿sobrevivió el contenedor? ¿Quién lo mantiene vivo? Ahí está `conmon` haciendo su
trabajo — y compáralo con hacer lo mismo contra `dockerd`.

### 🔴 Ejercicio 23 — Explica el socket a alguien que no lo ve

Tu equipo quiere añadir a todo el mundo al grupo `docker` "para que no tengan que usar `sudo`".

**Objetivo:** escribir la explicación de tres párrafos que diga qué están concediendo realmente,
con la cadena de razonamiento de §4.1 —no con "es inseguro"—, y qué alternativas hay. Una de
ellas es Podman rootless, y ahí ya estás abriendo **[F25](25-rootless-y-user-namespaces.md)**.

### 🔴 Ejercicio 24 — Audita tus scripts

Revisa todos los scripts del laboratorio y clasifica cada comando en portable, portable con
ajuste, o específico de motor.

**Objetivo:** una tabla y la decisión de qué harías con cada uno. Es la preparación de **[F26](26-portabilidad-entre-motores.md)**.

### 🔴 Ejercicio 25 — La prueba de fuego de la portabilidad

Antes de que **[F26](26-portabilidad-entre-motores.md)** te dé el script y la matriz, intenta
resolverlo tú. Tu laboratorio tiene que funcionar en los dos motores sin que quien lo use tenga
que saber cuál está usando.

**Objetivo:** conseguir que el ciclo completo de un fixture —construir, instalar, testear,
construir el proyecto y arrancar el dev server— funcione con los dos motores, y escribir la
lista de **todas** las cosas que tuviste que resolver. Los sospechosos habituales: el nombre
del binario, los permisos de los archivos del bind mount, el nombre del host desde dentro, y
el comportamiento de los named volumes.

Para cada una, apunta las **tres** salidas posibles: detectar el motor y bifurcar, usar solo
el subconjunto que funciona en los dos, o declarar que no se soporta.

**Pregunta de cierre:** ¿cuántas de tus soluciones son bifurcaciones y cuántas son subconjunto
común? Un script lleno de `if [ "$ENGINE" = "podman" ]` funciona y es un pasivo. Escribe el
criterio que usarías para decidir cuándo bifurcar y cuándo renunciar a una opción — y después
compáralo con el que propone [F26](26-portabilidad-entre-motores.md) §5.

## 🔥 Opcionales

### 🔥 Ejercicio 26 — Lee la especificación de runtime

Lee la OCI Runtime Specification y localiza qué define exactamente un *filesystem bundle*.

**Pregunta:** ¿qué dos archivos lo forman? Ahora entiendes por qué `runc` y `crun` son
intercambiables.

### 🔥 Ejercicio 27 — `runc` a mano

Crea un bundle OCI y arráncalo con `runc` directamente, sin Docker ni Podman.

**Objetivo:** ver el nivel más bajo del stack y comprobar que un contenedor es, literalmente, un
directorio y un JSON.

## 💀 Boss fight

### 💀 Ejercicio 28 — Boss fight: la migración de motor

Tu equipo tiene que dejar Docker Desktop por licencia y pasar a Podman. Tienes el laboratorio
entero: imágenes, volúmenes, scripts, `devcontainer.json` y un pipeline de CI.

**Objetivo:** producir el plan de migración completo — qué se mueve y cómo, qué scripts hay que
tocar y por qué, qué se comporta distinto y qué hay que **verificar en lugar de asumir**. La
parte que separa un buen plan de uno malo es la lista de **verificaciones**: por cada cosa que
"debería funcionar igual", el comando que lo comprueba. Y termina diciendo qué se pierde y qué
se gana, honestamente, porque las dos listas tienen contenido.

---

## 16. 📚 Referencias

**Arquitectura**
- Docker Engine: https://docs.docker.com/engine/
- API del Engine: https://docs.docker.com/reference/api/engine/
- containerd: https://containerd.io/docs/
- Podman: https://docs.podman.io/en/latest/
- Buildah: https://buildah.io/
- conmon: https://github.com/containers/conmon
- crun: https://github.com/containers/crun · runc: https://github.com/opencontainers/runc

**OCI**
- Las tres especificaciones: https://opencontainers.org
- Image: https://github.com/opencontainers/image-spec
- Runtime: https://github.com/opencontainers/runtime-spec
- Distribution: https://github.com/opencontainers/distribution-spec

**Seguridad**
- Por qué el socket importa: https://docs.docker.com/engine/security/

> ⚠️ **Todo lo de esta fase se verifica en tu máquina.** Los productos cambian, y los comandos
> de §4.4 y §5.5 te dicen qué tienes tú hoy. Enlaces revisados el 3 de septiembre de 2026.

**Orden de lectura sugerido:** la página de OCI primero, que en cinco minutos explica por qué
los dos motores son compatibles; la Runtime Specification solo si haces el ejercicio 28.

---

## 17. 🏁 Resultado de la fase

```text
DOCKER      cliente → dockerd → containerd → shim → runc → tu proceso
            un daemon permanente, normalmente root
            el socket es una API de control: acceso ≈ root en el host

PODMAN      podman (fork-exec) → libpod → conmon → crun/runc → tu proceso
            sin daemon obligatorio; el contenedor es hijo TUYO
            servicio opcional, activable por socket
            pods nativos, integración directa con systemd

OCI         estandariza  imagen · runtime · protocolo de registry
            NO estandariza  CLI · almacén local · Dockerfile · redes · volúmenes

PORTABILIDAD  la imagen  🟢 total
              el Dockerfile  🟡 en la práctica
              los comandos  🟠 compatibles, no idénticos

Y LO PRÁCTICO  dos almacenes que no se ven: docker save | podman load
               host.docker.internal ≠ host.containers.internal
```

> **La señal de que quedó bien:** *"cuando algo funciona en un motor y no en el otro, sé en cuál
> de las nueve áreas de la tabla mirar — y sé que la imagen no es el problema, porque esa sí
> está estandarizada."*

En **[F25](25-rootless-y-user-namespaces.md)** entramos en el mayor diferenciador de los dos modelos, y el que más consecuencias
tiene: rootless y user namespaces.
