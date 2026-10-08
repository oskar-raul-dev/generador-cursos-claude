# 💾 Parte I · Fase 09 — Montar tu proyecto: volúmenes y laboratorio end-to-end

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · Node 10.24.1 / 12.22.12 / 14.21.3 / 16.20.2
> **Arquitectura objetivo del laboratorio:** `linux/amd64`
> **Scripts que nacen aquí:** `scripts/run-dev.sh`
> **Tag pedagógico:** `legacy-node-toolchain:phase09`
> **Estado de la imagen al terminar:** el toolchain sin cambios. Lo que cambia es que ahora tu proyecto vive dentro
> **Código de esta fase:** [`src/09-montar-tu-proyecto/`](src/09-montar-tu-proyecto/)
> **Objetivo:** conectar tu código con el contenedor, entender por qué `node_modules` va aparte, y ejecutar el laboratorio end-to-end que junta todo lo de la Parte I

---

## 1. 🧭 Dónde estamos

[F08](08-run-el-contenedor-como-proceso.md) dejó el contenedor entendido como proceso: arranca, para, se inspecciona, y elige su
versión de Node sin tocar estado global. Lo que le falta es lo único que importa de verdad:
**tu proyecto**.

Esta fase ejecuta la decisión que [F01](01-decisiones-debian-zonas-node.md) tomó en teoría —las tres zonas, el bind mount, el named
volume— y termina con el laboratorio completo funcionando.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder:

- Montar tu proyecto real en `/workspace` y editarlo desde tu editor mientras corre dentro.
- Explicar por qué `node_modules` va en un named volume, y qué pasa exactamente si no.
- Usar `--mount` con criterio, y saber en qué se diferencia de `-v`.
- Entender por qué un mount puede **ocultar** contenido de la imagen.
- Pasar variables de entorno sin convertir un `.env` en un almacén de secretos.
- Ejecutar el ciclo completo: `npm ci`, `test`, `build`, `start`.

---

## 3. 🚧 Qué NO entra todavía

- **UID, GID, `EACCES` y los archivos que vuelven con dueño equivocado** → **[F17](17-usuarios-permisos-y-volumenes.md)**. Es la
  continuación natural de esta fase y el problema que más aparece al montar código.
- **Networking y publicación de puertos** → **[F18](18-networking-de-contenedores.md)**. Aquí montamos y ejecutamos; acceder desde
  el navegador del host es allí.
- **Logs, `docker attach` y el ciclo de vida completo** → **[F16](16-pid1-senales-y-ciclo-de-vida.md)** y **F18**.
- **El protocolo formal de validación** y el Validation Report → **[F11](11-validar-tu-proyecto.md)**.
- **Quoting en PowerShell** → **[a08](a08-windows-y-powershell.md)**.

---

## 4. 🔗 Bind mounts: tu código, dentro

Un **bind mount** conecta un directorio de tu host con una ruta del contenedor. No hay copia
ni sincronización: **es el mismo archivo visto desde dos sitios**.

```bash
docker run --rm -it \
  --platform linux/amd64 \
  --mount type=bind,src="$PWD",dst=/workspace \
  legacy-node-toolchain:phase08 \
  bash
```

Dentro, `/workspace` es tu proyecto. El archivo que guardas en VS Code está disponible al
instante para el `node` del contenedor, sin reconstruir nada. Es la **regla de oro** de [F01](01-decisiones-debian-zonas-node.md)
hecha comando.

### 4.1 `--mount` en lugar de `-v`

Verás las dos formas por todas partes:

```bash
--mount type=bind,src="$PWD",dst=/workspace     # explícito
-v "$PWD":/workspace                            # corto
```

Este curso usa `--mount` siempre, por una razón concreta y no por purismo:

> ⚠️ **`-v` crea silenciosamente lo que no existe.** Si te equivocas en la ruta del host, `-v`
> **crea un directorio vacío** y monta eso; tu contenedor arranca perfectamente con un
> `/workspace` vacío y te pasas veinte minutos preguntándote dónde está tu código. `--mount`
> con `type=bind` **falla** si el origen no existe, que es exactamente lo que quieres.

También es más legible: `src` y `dst` con nombre se leen sin contar los dos puntos.

### 4.2 Un mount puede ocultar contenido de la imagen

Este comportamiento sorprende y conviene verlo antes de sufrirlo:

```text
IMAGEN                    después del mount
/workspace/                /workspace/
  └── (vacío en F08)         ├── package.json      ← del host
                             ├── src/              ← del host
                             └── …
```

Si la imagen tuviera archivos en `/workspace`, el bind mount los **taparía**: siguen dentro de
la imagen, pero no se ven mientras el mount esté puesto. Es el mismo mecanismo que explica el
truco de la sección siguiente, y su base real —cómo se apilan los montajes— es de **[F13](13-overlayfs-y-copy-on-write.md)**.

---

## 5. 📦 El named volume de `node_modules`

Aquí está el montaje que desconcierta: **uno encima de otro**.

```bash
docker volume create miproyecto-node10-modules

docker run --rm -it \
  --platform linux/amd64 \
  --mount type=bind,src="$PWD",dst=/workspace \
  --mount type=volume,src=miproyecto-node10-modules,dst=/workspace/node_modules \
  legacy-node-toolchain:phase08 \
  bash
```

```mermaid
flowchart LR
    subgraph HOST
        P["tu-proyecto/"]
    end
    subgraph CT["CONTENEDOR · /workspace/"]
        PJ["package.json ← host"]
        S["src/ ← host"]
        NM["node_modules/ ← VOLUMEN, no host"]
    end
    V[("miproyecto-node10-modules")]
    P -- "bind mount" --> PJ
    P -- "bind mount" --> S
    V -- "named volume" --> NM
```

El segundo mount se aplica **sobre un subdirectorio del primero** y gana. Resultado: editas
tu código desde el host, y `node_modules` vive en un volumen gestionado por Docker que tu host
nunca ve.

### 5.1 Por qué, en tres razones concretas

**El host permanece limpio.** No aparecen decenas de miles de archivos Linux en tu disco, ni
tienes que decidir qué hacer con ellos al cambiar de rama.

**Los binarios pertenecen al sistema que los compiló.** Ya lo demostraste en [F04](04-toolchain-de-compilacion.md) con `file
hello`: un artefacto compilado es de su plataforma. Un `node_modules` generado en macOS y uno
generado en Debian 10 no son intercambiables, y el error que produce mezclarlos **no menciona
en ningún momento** que mezclaste dos sistemas operativos.

**Puedes cambiar de versión de Node sin contaminar nada**, y por eso el volumen lleva la
versión en el nombre:

```text
miproyecto-node10-modules
miproyecto-node12-modules
miproyecto-node14-modules
```

> ⚠️ **La trampa exacta que esto evita.** Instalas con Node 10, cambias a Node 12, y el
> `npm ci` no vuelve a compilar el addon nativo porque el volumen ya tiene algo. En tiempo de
> ejecución explota con un error sobre `NODE_MODULE_VERSION` que parece un bug del proyecto.
> El mecanismo está en **[F14](14-abi-libc-y-prebuilds.md)**; la prevención es un volumen por generación.

### 5.2 El volumen sobrevive, y eso corta en los dos sentidos

```bash
docker volume ls
docker volume inspect miproyecto-node10-modules
docker volume rm miproyecto-node10-modules
```

Un named volume **no muere con el contenedor**, aunque uses `--rm`. Es lo que hace que
`npm ci` no tenga que repetirse cada vez que arrancas.

Y es también lo que hace que un volumen contaminado te siga por más contenedores que borres.
Cuando algo huela raro con las dependencias, **borrar el volumen** es una de las primeras
comprobaciones — con la advertencia de que no es un `prune` general: borra ese volumen,
mirando su nombre.

> 🧭 **Persistencia no significa compatibilidad.** Que el volumen sobreviva no quiere decir que
> su contenido siga siendo válido para lo que vas a ejecutar ahora.

---

## 6. 📁 Working directory y variables de entorno

**`WORKDIR /workspace`** ya viene en la imagen, así que arrancas ahí. Para un monorepo donde
necesitas trabajar en un subdirectorio, `-w` lo cambia por contenedor:

```bash
docker run --rm -it \
  --mount type=bind,src="$PWD",dst=/workspace \
  -w /workspace/packages/frontend \
  legacy-node-toolchain:phase08 bash
```

**Variables de entorno** con `-e`, que es como ya elegiste la versión de Node en [F08](08-run-el-contenedor-como-proceso.md):

```bash
docker run --rm -e NODE_VERSION=14.21.3 -e NODE_ENV=development ... 
```

Las que pases con `-e` **ganan** sobre las que la imagen declaró con `ENV`. Y para varias a la
vez, `--env-file`:

```bash
docker run --rm --env-file ./.env.docker ...
```

> 🚨 **Un `.env` no es un secret store.** Las variables de un contenedor son legibles con
> `docker inspect` por cualquiera que tenga acceso al motor, y quedan en el historial de tu
> shell. Para el laboratorio local sirve; para credenciales de verdad no, y **[F29](29-supply-chain-sbom-firma.md)** explica las
> alternativas. El script de diagnóstico de **[F30](30-troubleshooting-metodo-y-herramientas.md)** existe en parte por este problema.

Puedes comprobar qué ve el contenedor:

```bash
docker exec mi-contenedor printenv NODE_VERSION
```

---

## 7. 🧰 El patrón toolbox: un contenedor que te espera

Para trabajar de verdad no quieres un `docker run --rm` por comando. Quieres un contenedor
persistente donde entrar y salir.

```bash
docker volume create miproyecto-node10-modules

docker run -d \
  --name legacy-node-dev \
  --platform linux/amd64 \
  -e NODE_VERSION=10.24.1 \
  --mount type=bind,src="$PWD",dst=/workspace \
  --mount type=volume,src=miproyecto-node10-modules,dst=/workspace/node_modules \
  legacy-node-toolchain:phase08 \
  sleep infinity
```

El `sleep infinity` es el truco: le da al contenedor un proceso principal que no termina, así
que se queda vivo esperándote. Recuerda de [F08](08-run-el-contenedor-como-proceso.md) que **un contenedor vive mientras su proceso
principal viva**.

Y ahora trabajas con `exec`:

```bash
docker exec -it legacy-node-dev bash          # entrar
docker exec legacy-node-dev npm ci            # un comando suelto
docker exec -e NODE_VERSION=16.20.2 legacy-node-dev node --version   # con otra versión
```

> 🧠 **Dos modos, mismo toolchain.** `docker run --rm` para comandos de usar y tirar;
> contenedor persistente más `docker exec` para sesiones de trabajo. Los dos usan la misma
> imagen y no se estorban.

### 7.1 `scripts/run-dev.sh`

Automatizar **después** de entender, que es la regla del curso. Este script no hace nada que
no hayas hecho a mano en esta fase:

📄 **`scripts/run-dev.sh`**

```bash
#!/usr/bin/env bash

set -euo pipefail

IMAGE="${IMAGE:-legacy-node-toolchain:phase09}"
CONTAINER_NAME="${CONTAINER_NAME:-legacy-node-dev}"
NODE_VERSION_VALUE="${NODE_VERSION_VALUE:-10.24.1}"
PROJECT_DIR="${PROJECT_DIR:-$PWD}"
MODULES_VOLUME="${MODULES_VOLUME:-legacy-node10-modules}"

# si el contenedor ya existe lo reutilizamos: crear otro con el mismo nombre falla
if docker container inspect "${CONTAINER_NAME}" >/dev/null 2>&1; then
    echo "El contenedor ${CONTAINER_NAME} ya existe."
    echo "Iniciándolo si está detenido..."
    docker start "${CONTAINER_NAME}" >/dev/null
else
    if ! docker volume inspect "${MODULES_VOLUME}" >/dev/null 2>&1; then
        echo "Creando volumen ${MODULES_VOLUME}..."
        docker volume create "${MODULES_VOLUME}" >/dev/null
    fi

    echo "Creando ${CONTAINER_NAME} con Node ${NODE_VERSION_VALUE}..."

    docker run -d \
        --name "${CONTAINER_NAME}" \
        --platform linux/amd64 \
        -e "NODE_VERSION=${NODE_VERSION_VALUE}" \
        --mount "type=bind,src=${PROJECT_DIR},dst=/workspace" \
        --mount "type=volume,src=${MODULES_VOLUME},dst=/workspace/node_modules" \
        "${IMAGE}" \
        sleep infinity >/dev/null
fi

echo
printf 'Container: %s\n' "${CONTAINER_NAME}"
printf 'Node:      %s\n' "$(docker exec "${CONTAINER_NAME}" node --version)"
printf 'npm:       %s\n' "$(docker exec "${CONTAINER_NAME}" npm --version)"
printf 'Workspace: %s\n' "$(docker exec "${CONTAINER_NAME}" pwd)"
echo
echo "Entrar con:"
echo "  docker exec -it ${CONTAINER_NAME} bash"
```

**Todo es parametrizable por variable de entorno** con `${VAR:-default}`, así que el mismo
script sirve para cualquier proyecto y versión sin editarlo:

```bash
NODE_VERSION_VALUE=14.21.3 MODULES_VOLUME=otro-node14-modules ./scripts/run-dev.sh
```

> ⚠️ **Lo que `run-dev.sh` NO hace, y es importante.** Si el contenedor ya existe, lo
> **reutiliza tal cual**: cambiar `NODE_VERSION_VALUE` no transforma un contenedor existente,
> porque esa variable se fija al crearlo. Para cambiar de versión hay que **borrar el
> contenedor y volver a crearlo** — o usar `docker exec -e` para un comando suelto, como en
> [F08](08-run-el-contenedor-como-proceso.md). Es la clase de detalle que un script oculta y que hay que saber antes de usarlo.

---

## 8. 🔥 El laboratorio end-to-end

Aquí se junta todo. Usa tu proyecto real o el fixture de control de
`src/10-validar-tu-proyecto/00-node-smoke/`, que existe justamente para esto.

**1. Arranca el toolbox:**

```bash
./scripts/run-dev.sh
```
```text
Creando volumen legacy-node10-modules...
Creando legacy-node-dev con Node 10.24.1...

Container: legacy-node-dev
Node:      v10.24.1
npm:       6.14.12
Workspace: /workspace

Entrar con:
  docker exec -it legacy-node-dev bash
```

**2. Comprueba que ves tu proyecto y que `node_modules` es el volumen:**

```bash
docker exec legacy-node-dev bash -c 'ls package.json && df -h /workspace /workspace/node_modules | tail -2'
```

Las dos rutas aparecen en sistemas de archivos distintos. Ahí está el doble montaje.

**3. Instala:**

```bash
docker exec legacy-node-dev npm ci
```

> 🩺 **`npm ci`, no `npm install`.** `ci` instala **exactamente** lo que dice el
> `package-lock.json` y falla si el lock y el `package.json` no cuadran. `install` puede
> reescribir el lock, y en un proyecto de 2019 eso destruye la reproducibilidad que buscas. La
> única vez que se usa `install` es para **generar** el lock la primera vez.

**4. Ejecuta el ciclo:**

```bash
docker exec legacy-node-dev npm test
docker exec legacy-node-dev npm run build
```

**5. Comprueba desde el host que el build salió:**

```bash
ls dist/     # o build/, según el proyecto
```

Ese directorio está en **tu disco**, porque el build escribió en `/workspace`, que es tu
proyecto. El artefacto lo produjo un toolchain que tu máquina no tiene instalado.

**6. Limpia cuando termines:**

```bash
docker rm -f legacy-node-dev
docker volume rm legacy-node10-modules      # solo si quieres reinstalar desde cero
```

> 🔥 **Prueba de fuego.** Con el contenedor corriendo, edita un archivo fuente desde tu editor
> del host y vuelve a ejecutar `npm run build` con `docker exec`. El cambio tiene que aparecer
> sin reconstruir la imagen ni reiniciar el contenedor. Si aparece, la arquitectura de [F01](01-decisiones-debian-zonas-node.md) está
> funcionando entera.

---

## 9. ⚠️ Errores comunes y diagnóstico

**`docker: Error response from daemon: Conflict. The container name "..." is already in use`.**
Ya existe uno con ese nombre, quizá detenido. `docker ps -a` para verlo, y `docker start` o
`docker rm` según lo que quieras.

**`bind source path does not exist`.** La ruta del host no existe. Es el error que `--mount`
te da y que `-v` te ocultaría creando un directorio vacío — §4.1.

**`/workspace` está vacío dentro del contenedor.** Montaste desde el directorio equivocado.
Comprueba `pwd` en el host antes de lanzar, y recuerda que `$PWD` se expande donde ejecutas el
comando.

**`npm ci` dice `Cannot read property ... of null` o se queja del lock.** El `package-lock.json`
no cuadra con el `package.json`, o lo generó una versión de npm muy distinta. Recuerda de [F06](06-instalacion-node.md)
que Node 16 trae npm 8 y su formato de lock es v2.

**`EACCES: permission denied` al escribir.** Estás tocando el problema de UID/GID, y su fase es
**[F17](17-usuarios-permisos-y-volumenes.md)**. Como parche temporal el contenedor corre como root, así que suele aparecer al revés:
archivos creados dentro que en tu host aparecen como de `root`.

**Cambiaste `NODE_VERSION_VALUE` y el contenedor sigue con la versión de antes.** Es lo
declarado en §7.1: el script reutiliza el contenedor existente. Bórralo y vuelve a crearlo.

**Todo funcionaba y de golpe el módulo nativo falla.** Sospecha del volumen: probablemente
tiene binarios de otra generación de Node. Bórralo y reinstala.

---

## 10. 📋 Checklist de validación

```text
[ ] scripts/run-dev.sh existe y es ejecutable
[ ] El contenedor legacy-node-dev arranca y sobrevive
[ ] ls /workspace dentro del contenedor muestra tu proyecto
[ ] /workspace y /workspace/node_modules están en filesystems distintos
[ ] docker volume ls muestra el volumen con la versión en el nombre
[ ] npm ci termina con éxito dentro del contenedor
[ ] npm test y npm run build se ejecutan
[ ] El artefacto de build aparece en tu host
[ ] Editas un archivo en el host y el cambio se ve dentro sin reconstruir
[ ] node_modules NO aparece en tu host
[ ] docker rm -f y volume rm limpian sin dejar restos
```

---

## 11. 🧪 Ejercicios de la Fase 09 (20)

## 🟢 Fácil — montar y comprobar (1–6)

### 🟢 Ejercicio 1 — Bind mount bidireccional

Monta un directorio, crea un archivo desde el contenedor y otro desde el host, y comprueba que
los dos se ven desde ambos lados.

**Objetivo:** confirmar que no hay copia ni sincronización: es el mismo archivo.

### 🟢 Ejercicio 2 — `-v` te miente

Ejecuta un `docker run` con `-v /ruta/que/no/existe:/workspace` y después el equivalente con
`--mount`.

**Pregunta:** ¿qué hace cada uno? ¿Cuál prefieres a las tres de la mañana?

### 🟢 Ejercicio 3 — El doble montaje

Arranca el toolbox y ejecuta `df -h /workspace /workspace/node_modules`.

**Pregunta:** ¿por qué son sistemas de archivos distintos si una ruta está dentro de la otra?

### 🟢 Ejercicio 4 — El volumen sobrevive

Instala dependencias, borra el contenedor con `--rm`, crea otro con el mismo volumen y
comprueba `node_modules`.

**Objetivo:** ver que el volumen no murió con el contenedor.

### 🟢 Ejercicio 5 — Un volumen por versión

Crea dos toolbox del mismo proyecto, uno con Node 10 y otro con Node 14, cada uno con su
volumen.

**Objetivo:** comprobar que conviven sin interferirse.

### 🟢 Ejercicio 6 — Working directory de monorepo

Monta un proyecto y arranca con `-w` apuntando a un subdirectorio.

**Pregunta:** ¿desde dónde se ejecuta `npm`? ¿Qué `package.json` lee?

## 🟡 Intermedio — los dos tipos de mount (7–12)

### 🟡 Ejercicio 7 — El laboratorio completo

Ejecuta los seis pasos de §8 con el fixture `00-node-smoke`.

**Objetivo:** cerrar el ciclo `npm ci` → `test` → `build` y ver el artefacto en tu host.

### 🟡 Ejercicio 8 — Un mount que oculta

Construye una imagen que cree `/workspace/oculto.txt`. Arráncala primero sin bind mount y
después con uno.

**Pregunta:** ¿dónde está el archivo en cada caso? ¿Se borró?

### 🟡 Ejercicio 9 — `npm ci` frente a `npm install`

Modifica una versión en el `package.json` sin regenerar el lock, y ejecuta primero `npm ci` y
después `npm install`.

**Pregunta:** ¿cuál falla y cuál "arregla" el problema? ¿Por qué el que lo arregla es
peligroso en un proyecto legacy?

### 🟡 Ejercicio 10 — Variables que ganan

Arranca un contenedor con `-e NODE_VERSION=14.21.3` cuando la imagen declara `ENV
NODE_VERSION=10.24.1`, y comprueba con `printenv`.

**Objetivo:** confirmar la precedencia y relacionarla con la distinción build/runtime de [F02](02-dockerfile-esencial.md).

### 🟡 Ejercicio 11 — Inspecciona los mounts

Ejecuta `docker inspect --format '{{json .Mounts}}' legacy-node-dev | jq`.

**Pregunta:** ¿qué información tiene cada mount, y cuál te diría si un volumen es el que crees?

### 🟡 Ejercicio 12 — Parametriza `run-dev.sh`

Úsalo con tres combinaciones distintas de proyecto, versión y volumen, sin editar el archivo.

**Objetivo:** ver el patrón `${VAR:-default}` trabajando y entender por qué el script no tiene
argumentos posicionales.

## 🟠 Difícil — cuando el contenedor no ve lo que crees (13–17)

### 🟠 Ejercicio 13 — Contamina un volumen a propósito

Instala dependencias con Node 10 y después arranca un contenedor con Node 14 **reutilizando el
mismo volumen** y ejecuta la aplicación.

**Objetivo:** provocar el fallo de §5.1 y leer su mensaje. No menciona ni volúmenes ni
versiones. Guárdalo para [F14](14-abi-libc-y-prebuilds.md).

### 🟠 Ejercicio 14 — Read-only

Monta el proyecto con `,readonly` en el `--mount` de bind e intenta escribir.

**Pregunta:** ¿en qué situación querrías esto? ¿Sigue funcionando `npm ci`? ¿Por qué?

### 🟠 Ejercicio 15 — El contenedor que no ve tu código

Alguien reporta que `/workspace` está vacío. Sin ver su comando, escribe la lista ordenada de
comprobaciones que le pedirías, de la más barata a la más cara.

**Objetivo:** construir un procedimiento de diagnóstico, no una respuesta. Debe empezar por
`docker inspect --format '{{json .Mounts}}'`.

### 🟠 Ejercicio 16 — El volumen fantasma

Ejecuta `docker run` **sin** crear antes el volumen, usando un nombre nuevo en `type=volume`.

**Pregunta:** ¿falla? ¿Qué hace Docker? Compara con lo que hace `--mount type=bind` ante un
origen inexistente y explica por qué el comportamiento es distinto.

### 🟠 Ejercicio 17 — Predice antes de ejecutar

Antes de probarlo, **predice** qué contiene `/workspace/node_modules` en cada caso: (a) bind
mount solo; (b) bind mount más volumen vacío; (c) bind mount más volumen ya poblado; (d)
volumen sin bind mount.

**Objetivo:** descubrir cuál de los cuatro tenías mal. Casi todo el mundo falla el (b).

## 🔴 Muy difícil — convención y criterio (18–20)

### 🔴 Ejercicio 18 — Arqueología de un `npm ci` que falla

Toma el fixture Vue 2 de `src/10-validar-tu-proyecto/10-vue2-min/` y ejecútalo con Node 16 en
lugar de Node 10.

**Objetivo:** documentar qué falla, en qué momento, y si la causa es el lock, la versión de npm
o una dependencia. Es el ensayo general de **[F11](11-validar-tu-proyecto.md)**.

### 🔴 Ejercicio 19 — Diseña la convención de nombres

Tu equipo va a mantener seis proyectos legacy con tres generaciones de Node.

**Objetivo:** diseñar la convención de nombres de contenedores y volúmenes que evite colisiones
y permita saber de un vistazo a qué proyecto y versión pertenece cada uno. Después escribe el
comando que borra todos los volúmenes de un proyecto sin tocar los de los demás — y comprueba
que funciona.

### 🔴 Ejercicio 20 — Defiende el named volume, otra vez

Un compañero, después de perder una tarde con el doble montaje, propone: *"montemos todo con un
solo bind mount, `node_modules` incluido, y ya está"*.

**Objetivo:** esta vez no basta con argumentar — **demuéstralo**. Diseña y ejecuta un
experimento reproducible con un módulo nativo que falle de una forma y funcione de la otra, y
documenta el resultado con la salida real. Si no consigues que falle, tu argumento no es sólido
y hay que revisarlo.

## 🔥 Opcionales

### 🔥 Ejercicio 21 — `run-dev` para PowerShell

Escribe el equivalente del script para PowerShell, con su quoting de rutas.

**Pregunta:** ¿qué tres cosas cambian respecto a Bash? Compara con **[a08](a08-windows-y-powershell.md)** cuando exista.

### 🔥 Ejercicio 22 — Mide el coste del bind mount

Cronometra `npm ci` con `node_modules` en volumen y con `node_modules` en bind mount, en tu
plataforma.

**Pregunta:** ¿hay diferencia? En macOS y Windows suele haberla, y bastante. ¿Qué te dice eso
sobre dónde ocurre realmente la traducción? Guarda los números para **[F26](26-portabilidad-entre-motores.md)**.

## 💀 Boss fight

### 💀 Ejercicio 23 — Boss fight: el proyecto que compila en el contenedor y no en el host

Montas tu proyecto legacy real, entras, haces `npm ci` y todo funciona. Sales, y en tu host
el mismo proyecto ya no arranca: `Error: Cannot find module` o un `.node` que se niega a
cargar. Tu compañero, que hizo lo mismo en su Mac, reporta lo contrario: le funciona fuera y
no dentro.

**Objetivo:** explicar el mecanismo completo y dejarlo blindado. Tienes que: (1) reproducir
**las dos** direcciones del problema y capturar los dos errores; (2) demostrar con `ls -la`
desde el host y desde el contenedor **dónde** está cada `node_modules` y por qué el named
volume de §5 es la pieza que lo resuelve —incluye la salida de `docker volume inspect`;
(3) probar qué pasa si montas el proyecto **sin** el named volume: haz `npm ci` dentro y
comprueba desde el host qué apareció en tu directorio, con qué dueño y con qué binarios;
(4) medir el coste, ejecutando el mismo `npm ci` con y sin volumen y dando los dos tiempos;
(5) dejar `run-dev.sh` de §7 verificando la condición antes de arrancar, de modo que el
error no pueda volver a pasar en silencio.

**Pregunta:** ¿por qué el bind mount de §4 sí es correcto para el código fuente y no lo es
para `node_modules`? La respuesta tiene que apoyarse en lo que un `.node` es —**[F14](14-abi-libc-y-prebuilds.md)** lo
formalizará—, no en "porque va más rápido".

---

## 12. 📚 Referencias

**Almacenamiento**
- Bind mounts: https://docs.docker.com/engine/storage/bind-mounts/
- Volumes: https://docs.docker.com/engine/storage/volumes/
- `--mount` frente a `-v`: https://docs.docker.com/engine/storage/#choose-the-right-type-of-mount

**Comandos**
- `docker volume`: https://docs.docker.com/reference/cli/docker-volume/
- `docker run` — opciones de mount y entorno: https://docs.docker.com/reference/cli/docker-container-run/

**npm**
- `npm ci`: https://docs.npmjs.com/cli/v6/commands/npm-ci

> ⚠️ **El enlace de `npm ci` apunta a la v6 a propósito**, que es la que trae nuestro baseline.
> La documentación de npm actual describe comportamientos de la v9 y v10 que no aplican a un
> lockfile de 2019.

**Orden de lectura sugerido:** *Choose the right type of mount* primero, que resuelve la duda
`-v` contra `--mount` de una vez; el resto según lo pidan los ejercicios.

---

## 13. 🏁 Resultado de la fase

```text
IMAGEN        legacy-node-toolchain:phase09  (sin cambios respecto a phase08)
NUEVO         scripts/run-dev.sh

MONTAJES      tu-proyecto/  ──bind────▶ /workspace
              <vol>-nodeNN  ──volume──▶ /workspace/node_modules

FUNCIONA      npm ci · npm test · npm run build dentro del contenedor
              el artefacto aparece en tu host
              editas en tu editor y el cambio se ve al instante
              dos versiones de Node conviven con sus volúmenes separados

PENDIENTE     acceder desde el navegador del host      → F18
              archivos con dueño equivocado            → F17
              el protocolo formal de validación        → F11
```

> **La señal de que quedó bien:** *"trabajo con mi editor de siempre, en mi repositorio de
> siempre, y todo lo que se ejecuta lo hace un toolchain que mi máquina no tiene instalado —
> y mi host sigue igual de limpio que ayer."*

En **[F10](10-vscode-y-debugging.md)** conectamos VS Code y el debugger: breakpoints en tu editor, ejecución dentro del
contenedor.
