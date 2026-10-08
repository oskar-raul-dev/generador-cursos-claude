# ▶️ Parte I · Fase 08 — Run: el contenedor como proceso

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · Node 10.24.1 / 12.22.12 / 14.21.3 / 16.20.2
> **Arquitectura objetivo del laboratorio:** `linux/amd64`
> **Scripts que nacen aquí:** `scripts/docker-entrypoint.sh` · `scripts/legacy-node-command`
> **Script que se retira aquí:** 🪦 `scripts/select-node` en runtime
> **Tag pedagógico:** `legacy-node-toolchain:phase08`
> **Estado de la imagen al terminar:** el toolchain con entrypoint y shims despachadores. Elegir versión de Node deja de modificar el contenedor
> **Código de esta fase:** [`src/08-run-el-contenedor-como-proceso/`](src/08-run-el-contenedor-como-proceso/)
> **Fecha de revisión de documentación externa:** 6 de septiembre de 2026 — la referencia de `docker run` y `docker exec`
> **Objetivo:** entender qué es un contenedor en ejecución, quién manda al arrancar, y pagar la deuda que dejó `select-node`

---

## 1. 🧭 Dónde estamos

Sabemos construir la imagen. Ahora hay que ejecutarla, y `docker run` tiene bastantes más
implicaciones que `docker build`.

Esta fase trata el contenedor **como proceso**: qué es exactamente, quién decide qué se
ejecuta al arrancar, cómo entrar a inspeccionarlo y cómo elegir la versión de Node sin
romperle el estado a nadie. La siguiente, **[F09](09-montar-tu-proyecto.md)**, mete tu código dentro.

```text
F07              F08  ← esta fase              F09
────             ───────────────               ───
construir        arrancar, parar,              montar tu proyecto,
la imagen        inspeccionar un               volúmenes, laboratorio
                 contenedor                    end-to-end
```

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder explicar:

- Qué hace `docker run` exactamente, y por qué crear no es lo mismo que ejecutar.
- Quién manda al arrancar: `ENTRYPOINT`, `CMD`, y qué pasa cuando conviven.
- Qué hace `exec "$@"` en un entrypoint y por qué importa.
- Foreground contra detached, y para qué sirven de verdad `-i`, `-t` y `--rm`.
- Qué es `docker exec` y por qué **no** es "entrar en la VM".
- Cómo elegir la versión de Node sin modificar el estado global del contenedor.

---

## 3. 🚧 Qué NO entra todavía

- **Bind mounts, named volumes, working directory y variables de entorno** → **[F09](09-montar-tu-proyecto.md)**, que es
  la continuación directa de esta.
- **PID 1, señales, zombies, ciclo de vida completo, restart policies y límites de
  recursos** → **[F16](16-pid1-senales-y-ciclo-de-vida.md)**.
- **UID, GID y archivos que vuelven con dueño equivocado** → **[F17](17-usuarios-permisos-y-volumenes.md)**.
- **Networking, publicación de puertos, logs y `docker attach`** → **[F18](18-networking-de-contenedores.md)**.
- **Docker frente a Podman en runtime**, comparado en serio → **[F24](24-docker-y-podman-arquitectura.md)**.
- El quoting de PowerShell y Windows → **[a08](a08-windows-y-powershell.md)**.

---

## 4. 🧠 El modelo mental de `docker run`

`docker run` hace **dos cosas**, y verlas por separado explica media docena de confusiones:

```text
docker run  =  docker create  +  docker start
                    │                 │
                    │                 └── arranca el proceso principal
                    └── crea el contenedor a partir de la imagen:
                        filesystem, configuración, red, nombre
```

Puedes hacerlo en dos pasos y comprobarlo:

```bash
docker create --name prueba legacy-node-toolchain:phase07
docker ps -a          # existe, estado Created
docker start -a prueba
```

De ahí salen cuatro hechos que conviene tener claros:

**Crear no es ejecutar.** Un contenedor creado existe, tiene ID y nombre, ocupa espacio, y no
está corriendo nada.

**Un contenedor detenido sigue existiendo.** `docker ps` no lo muestra; `docker ps -a` sí.
Conserva su filesystem y puedes volver a arrancarlo con `docker start`.

**Un contenedor eliminado ya no es ese contenedor.** `docker rm` lo borra con todo lo que
hubiera escrito dentro. Volver a hacer `docker run` de la misma imagen crea uno **nuevo**, sin
memoria del anterior. Esta distinción es la causa del clásico *"pero si ya había instalado
eso"*.

**Un contenedor está vivo mientras su proceso principal lo esté.** No hay más criterio. Si el
proceso principal termina —bien o mal—, el contenedor pasa a `Exited`. Por eso un
`docker run -d imagen` con `CMD ["bash"]` muere al instante: `bash` sin entrada que leer
termina de inmediato.

```mermaid
stateDiagram-v2
    [*] --> Created: create, desde la imagen
    Created --> Running: start
    Running --> Exited: el proceso termina
    Exited --> Running: start
    Exited --> [*]: rm, ya no existe
```

---

## 5. 🚪 `ENTRYPOINT` y `CMD`: quién manda al arrancar

[F02](02-dockerfile-esencial.md) presentó las dos instrucciones. Aquí se usan de verdad, y la simplificación útil es:

```text
ENTRYPOINT  →  el ejecutable o wrapper principal. Lo que siempre corre.
CMD         →  los argumentos por defecto que recibe.
```

Nuestro diseño:

```dockerfile
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bash"]
```

Y su combinación predeterminada es literalmente:

```text
/usr/local/bin/docker-entrypoint.sh bash
```

Lo que pases a `docker run` después del nombre de la imagen **reemplaza el `CMD`**, no el
`ENTRYPOINT`:

| Comando | Qué se ejecuta |
|---|---|
| `docker run imagen` | `docker-entrypoint.sh bash` |
| `docker run imagen node --version` | `docker-entrypoint.sh node --version` |
| `docker run --entrypoint node imagen --version` | `node --version` — el entrypoint se saltó |

> ⚠️ **`--entrypoint` sí reemplaza el `ENTRYPOINT`**, y con él te saltas toda la preparación
> que el wrapper hacía. Es útil para diagnosticar y peligroso por costumbre: si tu contenedor
> "se comporta raro" y alguien puso `--entrypoint` en el comando, ahí está la causa.

### 5.1 El entrypoint del laboratorio

📄 **`scripts/docker-entrypoint.sh`**

```bash
#!/usr/bin/env bash

set -euo pipefail

version="${NODE_VERSION:-10.24.1}"
node_home="/opt/node/${version}"

# si la versión pedida no existe, fallamos temprano y con un mensaje que ayude
if [[ ! -x "${node_home}/bin/node" ]]; then
    echo "ERROR: Node ${version} no está instalado en esta imagen." >&2
    echo "Versiones disponibles:" >&2
    find /opt/node -mindepth 1 -maxdepth 1 -type d -printf '  - %f\n' | sort >&2
    exit 64
fi

export NODE_VERSION="${version}"

# a stderr, para no contaminar la salida del comando que el usuario pidió
printf 'legacy-node-toolchain: Node %s\n' "${NODE_VERSION}" >&2

exec "$@"
```

Pequeño. **Deliberadamente pequeño.** Un entrypoint de setecientas líneas suele ser señal de
que el contenedor está intentando convertirse en un sistema operativo con sentimientos. 😄

**Detalles con intención:**

- **Valida y falla temprano**, con `exit 64` y la lista de versiones instaladas. Un contenedor
  que arranca a medias es peor que uno que no arranca.
- **El aviso va a `stderr`**, no a `stdout`. Si alguien hace
  `docker run imagen node -e 'console.log(1)' > salida.txt`, el archivo tiene que contener `1`
  y no nuestro saludo. Contaminar `stdout` rompe cualquier uso del contenedor dentro de una
  tubería.
- **`exec "$@"` en la última línea**, que es la pieza clave de la siguiente sección.

### 5.2 Qué hace `exec "$@"` y por qué importa

`exec` en Bash **reemplaza el proceso actual** en lugar de crear uno hijo. Sin él:

```text
PID 1  docker-entrypoint.sh
  └── PID 7  node server.js       ← tu aplicación, hija del script
```

Con `exec "$@"`:

```text
PID 1  node server.js             ← tu aplicación ES el proceso principal
```

La diferencia se cobra cuando ejecutas `docker stop`: el motor manda `SIGTERM` **al PID 1**.
En el primer caso lo recibe el script de shell, que probablemente no sabe qué hacer con él y
desde luego no se lo reenvía a su hijo; tu servidor Node se entera diez segundos después, en
forma de `SIGKILL`, sin cerrar conexiones ni ejecutar su handler de cierre.

> 🧠 **El patrón a memorizar.** Cualquier entrypoint que termine lanzando el comando del
> usuario debe hacerlo con `exec`. Es una línea, y es la diferencia entre un apagado limpio y
> uno a martillazos. **[F16](16-pid1-senales-y-ciclo-de-vida.md)** lo desarrolla entero, con zombies incluidos.

---

## 6. 🔀 Los shims despachadores: pagando la deuda de `select-node`

[F06](06-instalacion-node.md) dejó declarada una deuda 💸. `select-node` funciona, pero tiene dos límites que en runtime
duelen:

**Cambia symlinks en `/usr/local/bin/`**, lo que exige permisos de escritura ahí. En cuanto
ejecutes el contenedor como usuario no-root —que es el destino natural, ver **[a05](a05-non-root-a-fondo.md)**— deja de
funcionar.

**Cambia el estado global del contenedor.** Si activas Node 14, lo activas para **todos** los
procesos: los que ya corren, los que arranquen después, y cualquier `docker exec` que hagas
desde otra terminal. No hay forma de decir "solo este comando con Node 14".

La solución es no cambiar nada: **comandos despachadores inmutables** que deciden a dónde ir
cada vez que se ejecutan, leyendo la variable de entorno.

📄 **`scripts/legacy-node-command`**

```bash
#!/usr/bin/env bash

set -euo pipefail

command_name="$(basename "$0")"
version="${NODE_VERSION:-10.24.1}"
node_home="/opt/node/${version}"
target="${node_home}/bin/${command_name}"

if [[ ! -x "${target}" ]]; then
    echo "ERROR: ${command_name} no está disponible para Node ${version}." >&2
    echo "Ruta esperada: ${target}" >&2
    echo "Versiones instaladas:" >&2
    find /opt/node -mindepth 1 -maxdepth 1 -type d -printf '  - %f\n' | sort >&2
    exit 64
fi

exec "${target}" "$@"
```

**El truco está en `basename "$0"`.** El mismo archivo sirve para tres comandos, porque se
enlaza tres veces:

```text
/usr/local/bin/node  ──▶ legacy-node-command   →  basename = "node"
/usr/local/bin/npm   ──▶ legacy-node-command   →  basename = "npm"
/usr/local/bin/npx   ──▶ legacy-node-command   →  basename = "npx"
```

Cuando ejecutas `npm ci`, el script se ve invocado como `npm`, calcula
`/opt/node/${NODE_VERSION}/bin/npm` y hace `exec` sobre él. **No hay symlink que reapuntar y
no hay estado que cambiar**: la decisión se toma en cada invocación.

Y ahora lo que esto te permite:

```bash
# este contenedor usa Node 10
docker run --rm legacy-node-toolchain:phase08 node --version

# este otro usa Node 14, sin tocar nada
docker run --rm -e NODE_VERSION=14.21.3 legacy-node-toolchain:phase08 node --version

# y dentro de un contenedor vivo, un solo comando con otra versión
docker exec -e NODE_VERSION=16.20.2 mi-contenedor node --version
```

Esa última línea es la que `select-node` nunca pudo dar.

> 🪦 **Retiro de `select-node` en runtime.** Sigue existiendo y sigue siendo útil **durante el
> build**, donde fijar la versión por defecto es exactamente lo que queremos y el estado global
> no molesta. Lo que se retira es su uso dentro de un contenedor en marcha. Los dos mecanismos
> conviven con papeles distintos, y eso queda documentado en el Dockerfile.

---

## 7. 🖥️ Foreground, detached, y las banderas que todo el mundo copia

**Foreground es el modo natural.** `docker run imagen comando` arranca el proceso y te ata su
salida a la terminal. Cuando termina, vuelves al prompt.

**`-d` / `--detach`** lo manda al fondo y te devuelve el ID. Ojo con lo que **no** hace: no
mantiene vivo un proceso que termina. `docker run -d imagen` con `CMD ["bash"]` te devuelve un
ID y un contenedor ya muerto.

**`-i` / `--interactive`** mantiene abierto `stdin`, para poder escribirle al proceso.

**`-t` / `--tty`** asigna un pseudo-terminal, que es lo que da prompt, colores y edición de
línea.

Son cosas distintas y por eso se combinan:

| | Qué obtienes |
|---|---|
| sin banderas | el comando corre y su salida sale por pantalla |
| `-i` | puedes escribirle, pero sin prompt ni formato |
| `-t` | parece una terminal, pero no puedes escribir |
| `-it` | shell interactiva de verdad |

> ⚠️ **No uses `-t` en scripts ni en CI.** Un pseudo-TTY hace que muchos programas cambien su
> salida —barras de progreso, colores, códigos de escape— y eso ensucia los logs que después
> quieres leer. La regla: `-it` para trabajar a mano, sin banderas para automatizar. En **[F20](20-validacion-sistematica-y-evidencia.md)**
> vas a agradecer haberla seguido.

**`--rm`** elimina el contenedor al terminar. Es maravilloso para comandos de usar y tirar
—casi todos los ejemplos de este curso lo llevan— y es exactamente lo que **no** quieres
cuando algo falló y necesitas inspeccionar los restos.

---

## 8. 🧰 `docker exec`: procesos nuevos, no "entrar en la VM"

```bash
docker exec -it mi-contenedor bash
```

Se parece tanto a un `ssh` que casi todo el mundo construye el modelo mental equivocado. Lo
que realmente hace es **arrancar un proceso nuevo dentro del namespace de un contenedor que ya
está corriendo**.

Las consecuencias son concretas:

**No crea otro contenedor.** Compruébalo con `docker ps` antes y después: sigue habiendo uno.

**Necesita que el contenedor esté vivo.** Si el proceso principal terminó, no hay dónde
ejecutar nada y obtienes `Container ... is not running`.

**Un proceso de `exec` no es el principal.** Si sales de ese `bash`, el contenedor sigue
corriendo. Y si el proceso principal muere, tu `exec` muere con él aunque estuvieras a medias.

**Cada `exec` tiene su propio entorno.** Puedes pasarle `-e NODE_VERSION=14.21.3` y afecta solo
a ese proceso — que es justo lo que hacen posible los shims de §6.

```bash
docker exec mi-contenedor ps -ef
```
```text
UID   PID  PPID  CMD
root    1     0  node server.js          ← el proceso principal
root   28     0  ps -ef                  ← tu exec, sin relación de padre con el 1
```

---

## 9. 📊 La matriz de Node en runtime

Con los shims, cada contenedor decide su versión y la comprobación es la misma para las
cuatro:

```bash
for v in 10.24.1 12.22.12 14.21.3 16.20.2; do
  printf '%-10s ' "$v"
  docker run --rm --platform linux/amd64 -e NODE_VERSION="$v" \
    legacy-node-toolchain:phase08 \
    bash -c 'printf "node %s  npm %s\n" "$(node --version)" "$(npm --version)"' 2>/dev/null
done
```
```text
10.24.1    node v10.24.1  npm 6.14.12
12.22.12   node v12.22.12  npm 6.14.16
14.21.3    node v14.21.3  npm 6.14.18
16.20.2    node v16.20.2  npm 8.19.4
```

> 🩺 **La prueba importante es crear contenedores separados**, no cambiar la versión dentro de
> uno solo. Es lo que garantiza que dos proyectos con generaciones distintas puedan trabajar a
> la vez sin interferirse — y es la razón de todo el diseño de esta fase.

Y el fallo también está cubierto:

```bash
docker run --rm -e NODE_VERSION=11.0.0 legacy-node-toolchain:phase08 node --version
```
```text
ERROR: Node 11.0.0 no está instalado en esta imagen.
Versiones disponibles:
  - 10.24.1
  - 12.22.12
  - 14.21.3
  - 16.20.2
```

---

## 10. 🏗️ El Dockerfile de la fase

Sobre el canónico de [F07](07-build-de-la-imagen.md), se añaden los dos scripts y la pareja `ENTRYPOINT`/`CMD`:

```dockerfile
# … todo lo de F07 …

COPY scripts/select-node          /usr/local/bin/select-node
COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY scripts/legacy-node-command  /usr/local/bin/legacy-node-command

# select-node sigue sirviendo durante el BUILD para fijar la versión por defecto.
# En runtime mandan los shims: no modifican estado y respetan NODE_VERSION.
RUN chmod 0755 /usr/local/bin/select-node \
                /usr/local/bin/docker-entrypoint.sh \
                /usr/local/bin/legacy-node-command \
    && ln -sfn /usr/local/bin/legacy-node-command /usr/local/bin/node \
    && ln -sfn /usr/local/bin/legacy-node-command /usr/local/bin/npm \
    && ln -sfn /usr/local/bin/legacy-node-command /usr/local/bin/npx \
    && NODE_VERSION="${DEFAULT_NODE_VERSION}" node --version \
    && NODE_VERSION="${DEFAULT_NODE_VERSION}" npm --version

ENV NODE_VERSION=${DEFAULT_NODE_VERSION}

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bash"]
```

**Detalles con intención:**

- Los shims **sustituyen** a los symlinks directos de [F06](06-instalacion-node.md): ahora `/usr/local/bin/node` apunta
  al despachador, no a un binario concreto.
- **Los shims se validan durante el build.** Si el despachador estuviera roto, el build falla
  ahí y no tres fases después, en manos del estudiante.
- `CMD ["bash"]` en lugar del `echo` de saludo: a partir de aquí la imagen es una herramienta
  de trabajo, no una demostración.

---

## 11. ⚠️ Errores comunes y diagnóstico

**`docker run -d imagen` termina inmediatamente.** El proceso principal terminó. Con
`CMD ["bash"]` y sin `-i`, `bash` no tiene entrada que leer y sale. Comprueba con
`docker ps -a` y `docker logs`.

**`Error response from daemon: Container ... is not running`** al hacer `exec`. El contenedor
está detenido. `docker ps -a` te dice desde cuándo y `docker logs` por qué.

**`docker exec` ve una versión de Node distinta a la que esperabas.** Con los shims, `exec`
hereda el `NODE_VERSION` del contenedor salvo que le pases `-e`. Comprueba con
`docker exec mi-contenedor printenv NODE_VERSION`.

**El contenedor ignora `Ctrl+C` y tarda diez segundos en morir.** Falta el `exec` en el
entrypoint, o el `CMD` está en forma shell. Mira quién es PID 1 con `docker exec ... ps -ef`.
**[F16](16-pid1-senales-y-ciclo-de-vida.md)** entero trata de esto.

**Cambiaste la imagen y el contenedor sigue igual.** Un contenedor **no** se actualiza al
reconstruir la imagen: sigue usando la que tenía. Hay que crear uno nuevo. Es de los
malentendidos más caros del principio.

**`docker run` con `-e NODE_VERSION=...` no cambia nada.** Estás usando una imagen anterior a
esta fase, donde `/usr/local/bin/node` es un symlink directo y no un shim. Comprueba con
`readlink -f $(command -v node)`.

---

## 12. 📋 Checklist de validación

```text
[ ] scripts/docker-entrypoint.sh y scripts/legacy-node-command existen
[ ] El build valida los shims y produce legacy-node-toolchain:phase08
[ ] docker run --rm ... phase08 node --version  → v10.24.1
[ ] docker run --rm -e NODE_VERSION=16.20.2 ... node --version → v16.20.2
[ ] readlink -f $(command -v node) apunta a legacy-node-command
[ ] Una versión inexistente falla con exit 64 y lista las disponibles
[ ] El aviso del entrypoint sale por stderr: `... node -e 'console.log(1)' > f` deja solo "1"
[ ] docker exec -e NODE_VERSION=14.21.3 <ct> node --version responde v14.21.3
[ ] docker exec <ct> ps -ef muestra el proceso principal como PID 1
[ ] Puedes explicar qué hace exec "$@" y qué pasaría sin él
[ ] La matriz de §9 responde correctamente para las cuatro versiones
```

---

## 13. 🧪 Ejercicios de la Fase 08 (20)

## 🟢 Fácil — arrancar y observar (1–5)

### 🟢 Ejercicio 1 — `run` desechable

Ejecuta tres comandos distintos con `--rm` y comprueba con `docker ps -a` que no queda rastro.

**Objetivo:** interiorizar el patrón de usar y tirar que usa todo el curso.

### 🟢 Ejercicio 2 — `create` más `start`

Separa un `docker run` en sus dos mitades y observa el estado entre ambas con `docker ps -a`.

**Pregunta:** ¿qué existe después del `create` y qué falta?

### 🟢 Ejercicio 3 — `-i`, `-t`, `-it`

Ejecuta `bash` de las cuatro formas de la tabla de §7.

**Objetivo:** ver qué falla exactamente en cada combinación incompleta.

### 🟢 Ejercicio 4 — El contenedor que muere solo

Ejecuta `docker run -d legacy-node-toolchain:phase08` y después `docker ps -a`.

**Pregunta:** ¿por qué salió, y qué bandera lo mantendría vivo?

### 🟢 Ejercicio 5 — La versión por variable

Arranca cuatro contenedores, uno por generación, con `-e NODE_VERSION`.

**Objetivo:** comprobar la matriz de §9 con tus manos.

## 🟡 Intermedio — el entrypoint y los shims (6–12)

### 🟡 Ejercicio 6 — Sigue el shim

Ejecuta `readlink -f $(command -v node)` y después `cat $(readlink -f $(command -v node))`.

**Pregunta:** ¿qué encuentras al final del symlink, y en qué se diferencia de lo que había en
`phase06`?

### 🟡 Ejercicio 7 — El fallo controlado

Pide `-e NODE_VERSION=9.9.9` y lee el error y el código de salida.

**Objetivo:** confirmar que el contenedor no arranca a medias.

### 🟡 Ejercicio 8 — `stdout` limpio

Ejecuta `docker run --rm legacy-node-toolchain:phase08 node -e 'console.log(42)' > salida.txt`
y mira el archivo.

**Pregunta:** ¿aparece el saludo del entrypoint? ¿Por qué no, y qué habría pasado si el
`printf` no llevara `>&2`?

### 🟡 Ejercicio 9 — Sáltate el entrypoint

Ejecuta el mismo comando con `--entrypoint node` y compara.

**Pregunta:** ¿qué validación te perdiste? Prueba a saltarte el entrypoint pidiendo una
versión inexistente y compara los dos errores.

### 🟡 Ejercicio 10 — `exec` no crea contenedores

Arranca un contenedor con `-d` y `CMD` que sobreviva —`sleep 3000` sirve—, haz tres `docker
exec` y ejecuta `docker ps` entre ellos.

**Objetivo:** comprobar que sigue habiendo un solo contenedor.

### 🟡 Ejercicio 11 — Un `exec` con otra versión

Sobre ese contenedor, ejecuta `docker exec -e NODE_VERSION=16.20.2 <ct> node --version` y
después, sin `-e`, otra vez.

**Pregunta:** ¿el primero cambió algo para el segundo? ¿Qué habría pasado con `select-node`?

### 🟡 Ejercicio 12 — El shim con otro nombre

Crea un cuarto enlace `/usr/local/bin/node-inspect` apuntando a `legacy-node-command`.

**Pregunta:** ¿qué intenta ejecutar y por qué falla? ¿Qué te dice eso sobre cómo funciona
`basename "$0"`?

## 🟠 Difícil — cuando el proceso no es el que crees (13–17)

### 🟠 Ejercicio 13 — Rompe `exec "$@"`

Construye una variante del entrypoint que termine en `"$@"` **sin** `exec`. Arranca un proceso
largo y mira `ps -ef` desde otro `exec`.

**Objetivo:** ver los dos procesos y quién es PID 1. Guarda el resultado para **[F16](16-pid1-senales-y-ciclo-de-vida.md)**.

### 🟠 Ejercicio 14 — Un contenedor que sobrevive

Averigua tres formas distintas de mantener vivo un contenedor de este toolchain sin que
ejecute una aplicación.

**Objetivo:** llegar al patrón "toolbox persistente" que [F09](09-montar-tu-proyecto.md) va a usar todo el rato.

### 🟠 Ejercicio 15 — La imagen nueva y el contenedor viejo

Arranca un contenedor persistente. Reconstruye la imagen cambiando algo visible. Sin borrar el
contenedor, haz `docker exec` y busca el cambio.

**Pregunta:** ¿está? ¿Por qué no? Formula la regla con tus palabras — es de los errores más
caros del principio.

### 🟠 Ejercicio 16 — `-t` en una tubería

Ejecuta un comando que produzca salida con y sin `-t`, redirigiendo a un archivo, y compara los
bytes con `xxd | head`.

**Objetivo:** encontrar los códigos de escape ANSI que el pseudo-TTY inyecta, y entender por
qué la regla de §7 existe.

### 🟠 Ejercicio 17 — El contenedor que se niega a parar

Arranca un contenedor con un proceso que ignore `SIGTERM` deliberadamente y ejecuta
`docker stop`, cronometrando.

**Pregunta:** ¿cuánto tardó y qué pasó al final? ¿Qué bandera de `docker stop` cambia ese
tiempo? Anota las dudas: **[F16](16-pid1-senales-y-ciclo-de-vida.md)** las responde.

## 🔴 Muy difícil — diseño y criterio (18–20)

### 🔴 Ejercicio 18 — Diagnostica sin ver el Dockerfile

Alguien te da una imagen y dice que "no arranca". Usando solo `docker image inspect`,
`docker run` con distintos comandos y `docker logs`, averigua qué `ENTRYPOINT` y `CMD` tiene y
qué le pasa.

**Objetivo:** entrenar el diagnóstico desde fuera, que es lo que harás con imágenes ajenas.

### 🔴 Ejercicio 19 — Un despachador resistente

Mejora `legacy-node-command` para que, cuando la versión pedida no exista, sugiera la instalada
**más cercana** en lugar de listarlas todas — y siga fallando con código distinto de cero.

**Objetivo:** mantener las dos propiedades que hacen bueno al original —falla temprano, mensaje
útil— mientras añades una. Y sin que el script deje de caber en una pantalla.

### 🔴 Ejercicio 20 — Defiende los shims contra `nvm`

Un compañero propone tirar los shims y meter `nvm` en la imagen: *"es el estándar, todo el
mundo lo conoce, y `nvm use 14` es más natural que una variable de entorno"*.

**Objetivo:** escribir la respuesta con los tres argumentos concretos de §6 —permisos, estado
global, y comportamiento bajo `docker exec`—, reconociendo qué gana su propuesta. Y termina
diciendo en qué contexto `nvm` sí es la elección correcta, porque lo es en el suyo.

## 🔥 Opcionales

### 🔥 Ejercicio 21 — Reescribe el entrypoint en `sh` puro

Convierte `docker-entrypoint.sh` a POSIX `sh` estricto, sin `[[ ]]` ni `pipefail`.

**Pregunta:** ¿qué tuviste que cambiar y qué perdiste? ¿Justifica eso la decisión de [F03](03-apt-y-utilidades.md) de
poner Bash en la imagen?

### 🔥 Ejercicio 22 — Un tercer shim: `yarn`

Añade `yarn` al despachador de §6 sin tocar `legacy-node-command`: solo el enlace simbólico y
lo que haga falta en el Dockerfile. Comprueba que `NODE_VERSION=14.21.3 yarn --version`
resuelve la versión correcta y que `NODE_VERSION` sin valor sigue cayendo en el defecto.

**Objetivo:** demostrar que el patrón de §6 **escala por convención** —el basename manda— y
decir qué línea del script tendrías que tocar si el binario **no** viviera dentro del árbol de
Node. Es la prueba de que entendiste el despachador y no solo lo copiaste.

## 💀 Boss fight

### 💀 Ejercicio 23 — Boss fight: el contenedor que miente

Te dan un contenedor corriendo donde `node --version` responde `v10.24.1`, pero un script que
ejecutas dentro con `npm run build` usa claramente otra versión —lo delata un error de sintaxis
moderna que Node 10 no soporta—.

**Objetivo:** encontrar las **tres** capas donde puede estar la discrepancia —el shim, la
variable de entorno del proceso frente a la del contenedor, y el `PATH` del proceso que lanza
npm—, y determinar cuál es con evidencia, no con hipótesis. Documenta cada comando que usaste y
qué descartó. Si resuelves este, `docker exec` ya no te va a sorprender nunca.

---

## 14. 📚 Referencias

**Ejecución de contenedores**
- `docker run`: https://docs.docker.com/reference/cli/docker-container-run/
- `docker exec`: https://docs.docker.com/reference/cli/docker-container-exec/
- `ENTRYPOINT` y `CMD` en la referencia de Dockerfile: https://docs.docker.com/reference/dockerfile/#entrypoint
- Cómo interactúan las dos: https://docs.docker.com/reference/dockerfile/#understand-how-cmd-and-entrypoint-interact

**Shell**
- `exec` en el manual de Bash: https://www.gnu.org/software/bash/manual/bash.html#index-exec
- Parámetros especiales, incluido `"$@"`: https://www.gnu.org/software/bash/manual/bash.html#Special-Parameters

**Podman**
- `podman run`: https://docs.podman.io/en/latest/markdown/podman-run.1.html

**Orden de lectura sugerido:** la tabla de interacción `CMD`/`ENTRYPOINT` de Docker primero
—es la mejor referencia que existe sobre eso—, y el `exec` de Bash antes del ejercicio 13.

---

## 15. 🏁 Resultado de la fase

```text
IMAGEN        legacy-node-toolchain:phase08

NUEVO         scripts/docker-entrypoint.sh   valida, avisa por stderr, exec "$@"
              scripts/legacy-node-command    despachador por basename
              /usr/local/bin/{node,npm,npx} → shims, no symlinks a binarios
              ENTRYPOINT + CMD ["bash"]

RETIRADO 🪦   select-node en runtime. Sigue vivo durante el build.

PUEDES        arrancar, parar, inspeccionar y eliminar contenedores con criterio
              elegir la versión de Node por contenedor, o por comando
              entrar con docker exec sabiendo qué es y qué no es
              explicar quién es PID 1 y por qué importa
```

> **La señal de que quedó bien:** *"puedo tener dos contenedores del mismo toolchain corriendo
> a la vez, uno con Node 10 y otro con Node 16, sin que ninguno sepa del otro."*

En **[F09](09-montar-tu-proyecto.md)** metemos tu proyecto dentro: bind mounts, named volumes, y el laboratorio end-to-end
que junta todo lo que llevamos.
