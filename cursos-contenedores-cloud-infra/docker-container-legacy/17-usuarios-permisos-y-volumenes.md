# 👤 Parte II · Fase 17 — Usuarios, permisos y volúmenes: el archivo con dueño equivocado

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · `linux/amd64`
> **Requisitos:** **[F09](09-montar-tu-proyecto.md)** (montajes) y **[F16](16-pid1-senales-y-ciclo-de-vida.md)** (namespaces). Conviene tener **[a05](a05-non-root-a-fondo.md)** a mano
> **Estado de la imagen al terminar:** sin cambios; el laboratorio sigue como `root` por lo decidido en a05
> **Fecha de revisión de documentación externa:** 6 de septiembre de 2026 — el mapeo de usuarios de Docker y de Podman
> **Objetivo:** entender por qué un archivo creado dentro del contenedor aparece en tu host como de `root`, por qué eso pasa en Linux y no en macOS, y qué opciones tienes de verdad

---

## 1. 🧭 Dónde estamos

[F16](16-pid1-senales-y-ciclo-de-vida.md) abrió el PID namespace. Esta fase abre el problema del **usuario**, que es menos elegante y
mucho más cotidiano: es el que hace que un `npm run build` deje archivos que tú no puedes
borrar sin `sudo`.

Es también el que más se manifiesta de forma **distinta según tu plataforma**, lo que produce
el clásico "a mí no me pasa" entre dos personas del mismo equipo. Aquí se explica por qué.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder:

- Explicar por qué **el UID importa y el nombre de usuario no**.
- Predecir qué ownership tendrá un archivo creado desde el contenedor, en cada plataforma.
- Usar `--user` con criterio, y saber sus tres trampas.
- Entender por qué un **named volume recién creado** pertenece a `root` y qué hacer.
- Explicar qué hacen `:z`, `:Z` y `:U` en Podman, y por qué Docker no los necesita.
- Diagnosticar un `EACCES` sin recurrir a `chmod -R 777`.

---

## 3. 🚧 Qué NO entra todavía

- **La decisión de correr como no-root**, con sus ventajas y su coste → **[a05](a05-non-root-a-fondo.md)**, que es su
  apéndice y donde está el Dockerfile completo.
- **User namespaces y rootless de verdad** —cómo Podman cambia toda esta conversación— →
  **[F25](25-rootless-y-user-namespaces.md)**.
- **El rendimiento** de los bind mounts a través de la VM en macOS y Windows → **[F26](26-portabilidad-entre-motores.md)**.
- El **catálogo de fallos** de permisos → **[F32](32-catalogo-de-fallos-ii.md)**.

---

## 4. 🔢 El UID manda, el nombre no

Es la idea que hay que interiorizar antes que nada: **Linux asocia los permisos a números**,
no a nombres. El nombre de usuario es una comodidad que vive en `/etc/passwd` para que los
humanos leamos algo legible.

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase09 id
```
```text
uid=0(root) gid=0(root) groups=0(root)
```

Ese `0` es lo que importa. `root` es solo la etiqueta que ese sistema le pone al UID 0.

La consecuencia es la clave de toda la fase:

```text
TU HOST                          EL CONTENEDOR
oskar → UID 1000                 root  → UID 0
                                 node  → UID 1000   ← ¡el mismo número!
```

**El kernel es el mismo para los dos.** Cuando un proceso del contenedor escribe en un bind
mount, el filesystem del host anota el UID del proceso — sin traducir nada, porque no hay nada
que traducir. Si el proceso es UID 0, el archivo queda de UID 0. Y tu host llama a eso `root`.

> 🧠 **Modelo mental.** Un bind mount no es una copia ni un puente: es el **mismo filesystem**
> visto desde dos namespaces que comparten el mismo kernel y la misma tabla de UID. El
> contenedor no "convierte" nada al escribir.

---

## 5. 💥 El síntoma: `sudo rm -rf dist`

En un host Linux nativo:

```bash
docker exec legacy-node-dev npm run build
ls -la dist/
```
```text
-rw-r--r-- 1 root root 41283 sep  4 10:22 dist/main.js
```

Tu editor no puede guardarlo. Tu `git clean` falla. Y empieza la tradición ancestral:

```bash
sudo rm -rf dist
```

Que funciona y **no debería ser tu flujo de trabajo normal**. 😄

### 5.1 Por qué en macOS y Windows no lo ves

Y aquí está el motivo de que dos personas del mismo equipo no se pongan de acuerdo.

```mermaid
flowchart TD
    subgraph LN["LINUX NATIVO"]
        H1["tu host"] -- "mismo kernel" --> C1["contenedor"]
        C1 -.- N1["el UID viaja tal cual<br/>→ archivos de root"]
    end
    subgraph MW["macOS / WINDOWS con Docker Desktop"]
        H2["tu host (macOS)"] -- "file sharing (virtiofs, gRPC-FUSE)" --> VM["VM Linux"] --> C2["contenedor"]
        C2 -.- N2["la capa de compartición traduce<br/>→ archivos con TU usuario"]
    end
```

Docker Desktop introduce una máquina virtual y un mecanismo de compartición de archivos que
**traduce** parte de estas interacciones. El resultado es cómodo y engañoso: todo aparece con
tu usuario y el problema parece no existir.

> ⚠️ **No asumas que un problema de ownership observado en Linux se reproduce byte a byte en
> macOS, ni al revés.** Y la dirección peligrosa es esta: desarrollas en macOS sin notar nada,
> y el problema aparece en el CI Linux o en el portátil Linux de un compañero. Es de los
> fallos que más caro salen porque llegan tarde.

---

## 6. 👤 `--user`, y sus tres trampas

Docker permite cambiar el usuario al arrancar, sin tocar la imagen:

```bash
docker run --rm \
  --user "$(id -u):$(id -g)" \
  --mount type=bind,src="$PWD",dst=/workspace \
  legacy-node-toolchain:phase09 \
  bash -c 'id; touch /workspace/creado.txt; ls -ln /workspace/creado.txt'
```

La sintaxis acepta `nombre`, `UID`, `UID:GID` o `nombre:grupo`. **Usa números**: el nombre solo
funciona si existe en el `/etc/passwd` **del contenedor**, y el UID de tu host casi nunca está
ahí.

Y ahí empiezan las tres trampas.

### 6.1 Un UID que no existe en `/etc/passwd`

```bash
docker run --rm --user 1000:1000 legacy-node-toolchain:phase09 id
```
```text
uid=1000 gid=1000 groups=1000
```

Fíjate: **no hay nombre entre paréntesis**. El proceso corre con ese UID pero el sistema no
sabe quién es. Las consecuencias:

- `whoami` falla con `cannot find name for user ID 1000`.
- `$HOME` no está definido, así que npm intenta escribir su caché en `/` y falla.
- Herramientas que consultan el usuario dan errores raros.

**El parche del laboratorio** es declarar el `HOME` a mano:

```bash
docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp ...
```

### 6.2 El named volume pertenece a `root`

Esta es la que sorprende y la que más tiempo hace perder. Un volumen recién creado tiene
ownership `root:root`, **y no hereda el usuario del contenedor**:

```text
npm ERR! Error: EACCES: permission denied, mkdir '/workspace/node_modules/.staging'
```

El bind mount funciona —es tuyo en el host— y el volumen no. Como el volumen está montado
**encima** de `node_modules`, el error aparece exactamente ahí.

La solución es prepararlo una vez, desde un contenedor **con** privilegios:

```bash
docker run --rm \
  --mount type=volume,src=miproyecto-node10-modules,dst=/vol \
  legacy-node-toolchain:phase09 \
  chown -R "$(id -u):$(id -g)" /vol
```

> 🧭 **Es un paso de preparación, no un arreglo.** Se hace una vez por volumen, igual que
> `docker volume create`. Ponlo en tu `run-dev.sh` y no vuelves a pensar en ello.

### 6.3 APT y el sistema dejan de ser escribibles

Con `--user`, cualquier `apt-get install`, cualquier escritura en `/usr/local/bin` y cualquier
`select-node` dejan de funcionar. Los shims de [F08](08-run-el-contenedor-como-proceso.md) **sí** siguen funcionando, porque solo leen
— y esa es una de las razones por las que ese diseño era mejor, como cuenta **[a05](a05-non-root-a-fondo.md) §3**.

---

## 7. 🦭 Podman: `:z`, `:Z`, `:U` y `--userns=keep-id`

Podman cambia el problema de raíz, y conviene saber de qué van esas banderas que verás en
tutoriales.

**`--userns=keep-id`** hace que tu UID del host se mapee al mismo UID dentro del contenedor. Es
la respuesta directa al problema de esta fase, y Docker no tiene equivalente exacto.

**`:U`** en un montaje le dice a Podman que ajuste el ownership del volumen al usuario del
contenedor **automáticamente**. Resuelve §6.2 en una letra:

```bash
podman run --rm --mount type=volume,src=mivol,dst=/vol,U ...
```

**`:z` y `:Z`** son de **SELinux**, no de permisos POSIX, y ahí está la confusión más común:

| | Qué hace | Cuándo |
|---|---|---|
| `:z` | reetiqueta el contenido como **compartido** entre contenedores | varios contenedores usan el mismo directorio |
| `:Z` | reetiqueta como **privado** de este contenedor | un solo contenedor |

Solo importan en sistemas con SELinux activo —Fedora, RHEL, CentOS—. En Debian y Ubuntu no
hacen nada. Y `:Z` sobre un directorio que también usa el host puede reetiquetarlo y romperte
cosas fuera del contenedor, así que no es una bandera para poner "por si acaso".

> ⚠️ **En Podman rootless, `root` dentro del contenedor es tu usuario fuera.** Los user
> namespaces mapean el UID 0 del contenedor a tu UID real. El problema de §5 desaparece solo, y
> aparece otro distinto: los archivos que **el host** creó pueden no ser escribibles desde
> dentro. **[F25](25-rootless-y-user-namespaces.md)** trata el modelo entero.

---

## 8. 🩺 Diagnosticar un `EACCES` sin `chmod 777`

El anti-patrón por excelencia:

```bash
chmod -R 777 .        # ⚰️ no
```

"Funciona" porque le da permisos a todo el mundo sobre todo, destruye la información de
permisos original, y deja un repositorio con archivos ejecutables que no deberían serlo. Y la
próxima vez que pase, no vas a saber más que ahora.

**El procedimiento que sí sirve**, en cuatro comandos:

```bash
# 1. ¿quién soy dentro del contenedor?
docker exec mi-contenedor id

# 2. ¿de quién es lo que intento tocar?
docker exec mi-contenedor ls -ln /workspace /workspace/node_modules

# 3. ¿qué está montado y de qué tipo?
docker inspect --format '{{json .Mounts}}' mi-contenedor | jq

# 4. ¿y en el host?
ls -ln .
```

Con esas cuatro salidas, el diagnóstico sale solo:

| Lo que ves | La causa | El arreglo |
|---|---|---|
| proceso UID 1000, directorio UID 0 | el volumen está sin preparar | §6.2 |
| proceso UID 0, archivos en el host de `root` | corres como root en Linux nativo | `--user`, o [a05](a05-non-root-a-fondo.md) |
| `uid=1000` sin nombre y npm falla | UID sin entrada en `/etc/passwd` | `-e HOME=/tmp`, §6.1 |
| en macOS todo bien, en CI falla | la traducción de Docker Desktop | §5.1 |
| Podman, SELinux activo, `Permission denied` sin más | falta `:z` o `:Z` | §7 |

> 🧭 **La regla:** antes de cambiar permisos, averigua **qué UID** intenta escribir **dónde**.
> El 90% de los `EACCES` de este laboratorio se explican con los dos primeros comandos.

---

## 9. 🧰 Las tres estrategias, comparadas

| | Cómo | Ventaja | Coste |
|---|---|---|---|
| **Root** (el baseline) | no hacer nada | todo funciona, cero fricción | archivos de `root` en Linux nativo |
| **`--user` al ejecutar** | `--user "$(id -u):$(id -g)"` | sin tocar la imagen, ownership correcto | hay que preparar el volumen y declarar `HOME`; APT deja de funcionar |
| **Usuario en la imagen** | `USER` con `ARG` de UID/GID | limpio y reproducible para el equipo | hay que reconstruir por cada UID distinto; el detalle está en **[a05](a05-non-root-a-fondo.md) §4** |

> 🧭 **Qué elegir, sin dramatismo.** En macOS o Windows con Docker Desktop, **quédate en
> root**: no vas a notar el problema y añades complejidad sin ganancia. En Linux nativo, si te
> molestan los archivos de `root`, `--user` con el volumen preparado. Y en CI o en cualquier
> cosa que publiques, non-root sin discusión — ahí el precio se paga con gusto.

---

## 10. ⚠️ Errores comunes y diagnóstico

**`EACCES: permission denied, mkdir '/workspace/node_modules/...'`.** El volumen sin preparar.
§6.2, y es el más frecuente de largo.

**`whoami: cannot find name for user ID 1000`.** UID sin entrada en `/etc/passwd`. No siempre
rompe nada, pero es la pista de §6.1.

**npm falla al escribir su caché.** `$HOME` inexistente. `-e HOME=/tmp`.

**Los archivos aparecen de `root` en mi host.** Correcto y esperado en Linux nativo. §5.

**"A mí no me pasa."** Vuestra plataforma difiere. §5.1, y conviene comprobarlo en los dos
sitios antes de discutir.

**`apt-get install` falla dentro del contenedor.** Estás con `--user`. §6.3.

**En Podman, `Permission denied` sobre un bind mount que existe y es tuyo.** SELinux. Prueba
`:z` y comprueba con `ls -Z`.

**`chmod -R 777` "lo arregló".** Ocultó el síntoma. Vuelve a §8 y averigua qué UID intentaba
escribir dónde, porque va a repetirse.

---

## 11. 📋 Checklist de validación

```text
[ ] id dentro del contenedor te dice uid=0(root) en el baseline
[ ] Creaste un archivo desde el contenedor y comprobaste su dueño en el host
[ ] Sabes si tu plataforma traduce el UID o no, y lo comprobaste
[ ] --user "$(id -u):$(id -g)" produce archivos con tu usuario
[ ] Provocaste el EACCES del volumen sin preparar
[ ] Preparaste un volumen con chown y el EACCES desapareció
[ ] Sabes qué pasa con $HOME cuando el UID no está en /etc/passwd
[ ] Los shims de Node siguen funcionando con --user, y select-node no
[ ] Puedes ejecutar el diagnóstico de §8 de memoria
[ ] Sabes qué hacen :z, :Z y :U, y en qué sistemas importan
```

---

## 12. 🧪 Ejercicios de la Fase 17 (20)

## 🟢 Fácil — quién eres dentro (1–6)

### 🟢 Ejercicio 1 — Quién eres dentro

Ejecuta `id` en el contenedor y en tu host, y compara los números.

**Pregunta:** ¿coinciden? ¿Qué UID tiene `root` y qué UID tienes tú?

### 🟢 Ejercicio 2 — El archivo con dueño equivocado

Crea un archivo desde el contenedor en un bind mount y míralo con `ls -ln` en el host.

**Objetivo:** ver el resultado en **tu** plataforma. Si sale con tu usuario, ya sabes que
Docker Desktop está traduciendo.

### 🟢 Ejercicio 3 — `--user` en acción

Repite el ejercicio 2 con `--user "$(id -u):$(id -g)"`.

**Pregunta:** ¿cambió el dueño? ¿Y qué dice `id` ahora dentro del contenedor?

### 🟢 Ejercicio 4 — El UID sin nombre

Con `--user 1000:1000`, ejecuta `id`, `whoami` y `echo $HOME`.

**Objetivo:** ver las tres respuestas y entender de dónde viene cada rareza de §6.1.

### 🟢 Ejercicio 5 — El volumen nace de root

Crea un volumen nuevo, móntalo y ejecuta `ls -ldn` sobre su punto de montaje.

**Pregunta:** ¿de quién es? ¿Cambia si el contenedor corre con `--user`?

### 🟢 Ejercicio 6 — Prepara el volumen

Aplica el `chown` de §6.2 y repite el ejercicio 7.

**Objetivo:** confirmar que un solo comando de preparación lo resuelve.

## 🟡 Intermedio — UID, GID y el bind mount (7–12)

### 🟡 Ejercicio 7 — El `EACCES` clásico

Con `--user` y un volumen sin preparar, ejecuta `npm ci`.

**Objetivo:** obtener el error de §6.2 completo y saber reconocerlo al instante.

### 🟡 Ejercicio 8 — `HOME` y el caché de npm

Con `--user` sin `-e HOME`, ejecuta `npm ci` y busca en el error dónde intentaba escribir.

**Pregunta:** ¿qué ruta era? ¿Por qué esa y no otra?

### 🟡 Ejercicio 9 — Los shims sobreviven

Con `--user`, prueba `select-node 14.21.3` y después `NODE_VERSION=14.21.3 node --version`.

**Pregunta:** ¿cuál funciona? Relaciónalo con la deuda que [F08](08-run-el-contenedor-como-proceso.md) pagó y explica por qué los shims
eran mejor diseño incluso antes de que existiera este problema.

### 🟡 Ejercicio 10 — Escribe desde los dos lados

Con el bind mount montado, crea un archivo desde el host y otro desde el contenedor, y después
intenta modificar cada uno **desde el otro lado**.

**Objetivo:** construir la tabla de qué puede escribir quién, en tu plataforma.

### 🟡 Ejercicio 11 — Un usuario en la imagen

Construye la variante non-root de **[a05](a05-non-root-a-fondo.md) §4.1** con tu UID y valida un fixture.

**Objetivo:** el camino completo, para comparar su fricción con la de `--user`.

### 🟡 Ejercicio 12 — Podman con `keep-id`

Si tienes Podman, ejecuta el ejercicio 2 con `--userns=keep-id`.

**Pregunta:** ¿de quién es el archivo? ¿Necesitaste `--user`? Anota la diferencia: **[F25](25-rootless-y-user-namespaces.md)** la
explica entera.

## 🟠 Difícil — cuando el permiso no es lo que parece (13–17)

### 🟠 Ejercicio 13 — APT con `--user`

Intenta `apt-get update` con `--user`.

**Objetivo:** ver el fallo y entender por qué el `USER` de [a05](a05-non-root-a-fondo.md) §4.1 va al final del Dockerfile.

### 🟠 Ejercicio 14 — El grupo también cuenta

Con `--user "$(id -u):0"` —tu UID pero grupo root— repite el ejercicio 2.

**Pregunta:** ¿qué cambió? ¿Qué te dice eso sobre por qué se pasan los dos números?

### 🟠 Ejercicio 15 — Diagnostica sin tocar permisos

Prepara tres escenarios rotos —volumen sin preparar, UID sin `/etc/passwd`, y bind mount de un
directorio ajeno— y diagnostica cada uno con los cuatro comandos de §8.

**Objetivo:** llegar a la causa **sin ejecutar un solo `chmod`**, y decir qué comando la
confirmó en cada caso.

### 🟠 Ejercicio 16 — El fallo que solo aparece en CI

Desarrolla algo en macOS o Windows que deje archivos desde el contenedor, y ejecuta lo mismo en
un contenedor Linux nativo o en un runner de CI.

**Objetivo:** reproducir el escenario de §5.1 —el que llega tarde y caro— y proponer una
comprobación que lo habría detectado antes.

### 🟠 Ejercicio 17 — Mide el daño de `chmod -R 777`

Sobre una copia de un proyecto, guarda los permisos originales con `getfacl -R` o
`find . -printf '%m %p\n'`, aplica `chmod -R 777` y compara.

**Pregunta:** ¿cuántos archivos cambiaron de modo? ¿Cuántos son ahora ejecutables sin serlo?
¿Podrías restaurarlos sin la copia? Ahí está el costo real del atajo.

## 🔴 Muy difícil — convención de equipo (18–20)

### 🔴 Ejercicio 18 — El volumen compartido entre dos usuarios

Monta el mismo volumen en dos contenedores con UID distintos y haz que los dos escriban.

**Pregunta:** ¿qué falla? ¿Qué estrategia de las tres de §9 lo resolvería, y qué te cuesta?

### 🔴 Ejercicio 19 — Automatiza la preparación

Extiende el `run-dev.sh` de [F09](09-montar-tu-proyecto.md) para que prepare el ownership del volumen automáticamente la
primera vez, funcione con y sin `--user`, y no rompa nada en macOS donde no hace falta.

**Objetivo:** que el script detecte la plataforma o el modo en lugar de asumirlo, y que su
salida diga qué hizo y por qué. Un script que "arregla permisos" en silencio es exactamente lo
que esta fase enseña a no hacer.

### 🔴 Ejercicio 20 — La decisión para tu equipo

Tu equipo mezcla macOS, Windows y Linux, y comparte un repositorio.

**Objetivo:** elegir una de las tres estrategias de §9 —o una combinación— y justificarla con
lo que cada plataforma sufre de verdad. Tiene que incluir qué pone en el `run-dev.sh`, qué pone
en el `README`, y qué comprobación evita que el problema llegue al CI.

## 🔥 Opcionales

### 🔥 Ejercicio 21 — Lee `/proc/self/uid_map`

Dentro de un contenedor Docker y dentro de uno de Podman rootless, ejecuta
`cat /proc/self/uid_map`.

**Pregunta:** ¿en qué se diferencian? Ahí está el user namespace de **[F25](25-rootless-y-user-namespaces.md)** en tres números.

### 🔥 Ejercicio 22 — SELinux en vivo

En una máquina con SELinux —Fedora en una VM sirve—, monta un bind mount con y sin `:z` y
compara con `ls -Z`.

**Objetivo:** ver la etiqueta cambiar y entender que es un mecanismo aparte de los permisos
POSIX, no una variante de ellos.

## 💀 Boss fight

### 💀 Ejercicio 23 — Boss fight: el pipeline que falla solo los martes

Un CI Linux falla intermitentemente con `EACCES` al construir. En local, en tres máquinas
distintas —dos macOS y una Linux—, funciona siempre. El equipo lleva semanas poniendo
`chmod -R 777` en el pipeline y quiere quitarlo.

**Objetivo:** las causas son **dos**, encadenadas: una de esta fase y otra de [F13](13-overlayfs-y-copy-on-write.md). Diagnostica
las dos con evidencia, propón el arreglo real, y explica por qué `chmod -R 777` hacía que
funcionara **a veces** y no siempre — que es la parte que más cuesta razonar y la que convence
al equipo de quitarlo.

---

## 13. 📚 Referencias

**Permisos y usuarios en Linux**
- `credentials(7)`, UID y GID: https://manpages.debian.org/buster/manpages/credentials.7.en.html
- `chown(1)`: https://manpages.debian.org/buster/coreutils/chown.1.en.html
- `user_namespaces(7)`: https://manpages.debian.org/buster/manpages/user_namespaces.7.en.html

**Docker**
- `docker run --user`: https://docs.docker.com/reference/cli/docker-container-run/#user
- Dockerfile `USER`: https://docs.docker.com/reference/dockerfile/#user
- File sharing en Docker Desktop: https://docs.docker.com/desktop/settings-and-maintenance/settings/#file-sharing

**Podman**
- `--userns=keep-id`: https://docs.podman.io/en/latest/markdown/podman-run.1.html#userns-mode
- Opciones de montaje `:z`, `:Z`, `:U`: https://docs.podman.io/en/latest/markdown/podman-run.1.html#volume-v-source-volume-host-dir-container-dir-options

> ⚠️ **`user_namespaces(7)` es densa y no hace falta hoy.** Está aquí porque es la referencia
> real de lo que **[F25](25-rootless-y-user-namespaces.md)** explica, y porque el ejercicio 23 la roza. Léela cuando llegues a esa
> fase, no antes.

**Orden de lectura sugerido:** `credentials(7)` primero, que en dos páginas explica por qué el
UID manda; las opciones de Podman cuando hagas el ejercicio 12.

---

## 14. 🏁 Resultado de la fase

```text
LA REGLA        el UID manda, el nombre es cosmética
                el bind mount es el MISMO filesystem, sin traducción

EL SÍNTOMA      Linux nativo   → archivos de root, sudo rm -rf
                macOS/Windows  → traducido por Docker Desktop, no lo ves
                                 y por eso aparece en CI

TRES ESTRATEGIAS  root            cero fricción · archivos de root en Linux
                  --user          ownership correcto · volumen a preparar,
                                  HOME a declarar, APT deja de funcionar
                  USER en imagen  limpio para el equipo · reconstruir por UID

DIAGNÓSTICO     id · ls -ln · docker inspect .Mounts · ls -ln en el host
                nunca chmod -R 777 como primer reflejo

PODMAN          --userns=keep-id resuelve el problema de raíz
                :U prepara el volumen · :z y :Z son SELinux, no POSIX
```

> **La señal de que quedó bien:** *"ante un `EACCES` no toco permisos: averiguo qué UID intenta
> escribir dónde, y con eso ya sé cuál de las cinco causas es."*

En **[F18](18-networking-de-contenedores.md)** cerramos la trilogía de namespaces con el que más preguntas genera: la red. Por qué
`localhost` dentro del contenedor no es tu `localhost`, y qué hace realmente `-p`.
