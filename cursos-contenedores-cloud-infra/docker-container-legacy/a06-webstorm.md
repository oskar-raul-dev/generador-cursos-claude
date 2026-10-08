# 🟣 Apéndice a06 — WebStorm con un runtime legacy en contenedor

> **Curso:** Docker Legacy Node · **Apéndice opcional**
> **Cierra el bucle de:** [F00](00-problema-y-contrato.md) §8 · [F10](10-vscode-y-debugging.md) §3
> **Requisitos:** haber hecho [F09](09-montar-tu-proyecto.md) y F10. Lo que aquí cambia es el IDE, no el laboratorio
> **Fecha de revisión de documentación externa:** 3 de septiembre de 2026
> **Qué encontrarás:** los dos caminos para trabajar con WebStorm sobre el toolchain, cuál elegir, y por qué un IDE moderno puede llevarse mal con Node 10

[F10](10-vscode-y-debugging.md) usa VS Code porque es lo más extendido, no porque sea mejor. Si tu editor es WebStorm,
todo el laboratorio funciona igual — lo único que cambia es cómo se conecta el IDE.

---

## 🧭 Índice de salto rápido

| Si tu pregunta es… | Ve a |
|---|---|
| "¿Cuál de los dos caminos elijo?" | [§1](#1--dos-caminos-y-una-recomendación) |
| "Quiero la integración nativa" | [§2](#2--nivel-a--intérprete-remoto-en-docker) |
| "Quiero algo que funcione seguro" | [§3](#3--nivel-b--modo-universal) |
| "El IDE se queja de mi Node 10" | [§4](#4--por-qué-un-ide-moderno-puede-no-amar-a-node-10) |
| "No me aparece la opción de Docker" | [§5](#5--problemas-frecuentes) |

---

## 1. 🧭 Dos caminos, y una recomendación

```mermaid
flowchart TD
    subgraph NA["NIVEL A — integración nativa"]
        A1["WebStorm"] -- "Remote Node interpreter" --> A2["Docker"] --> A3["legacy-node-toolchain"]
        A3 -.- A4["El IDE gestiona el contenedor"]
    end
    subgraph NB["NIVEL B — modo universal"]
        B1["WebStorm (solo edita)"] -- "terminal" --> B2["Docker CLI"]
        B2 --> B3["node --inspect en el contenedor"] --> B4["attach del debugger por puerto"]
    end
```

**Nivel A** es más cómodo: WebStorm sabe que tu runtime está en Docker, ejecuta scripts de npm
desde la interfaz y adjunta el depurador él solo. Depende de plugins y de que la versión de tu
IDE se lleve bien con tu Node.

**Nivel B** es el equivalente al Modo A de [F10](10-vscode-y-debugging.md): el IDE solo edita, y todo lo demás pasa por la
terminal y por `docker exec`. Menos cómodo y **siempre funciona**, porque no depende de que
ninguna integración soporte Node 10.

> 🧭 **Recomendación del curso: empieza por el Nivel B.** Es el que no te va a dejar tirado, y
> si después el Nivel A funciona en tu versión de WebStorm, mejor. Al revés —empezar por A y
> descubrir a mitad de una tarde que la integración no soporta tu runtime— duele más.

---

## 2. 🟣 Nivel A — intérprete remoto en Docker

WebStorm permite declarar un **Node.js remote interpreter** que vive dentro de un contenedor.
La idea es la misma que persigue todo este curso: el IDE en tu host, el runtime en Debian 10.

**Lo que necesitas activo**, y conviene comprobarlo antes de nada en `Settings → Plugins`:
`Node.js`, `Node.js Remote Interpreter` y `Docker`. Según la edición y la versión, alguno puede
venir desactivado.

**El flujo, en pasos:**

1. **Conecta WebStorm con Docker** en `Settings → Build, Execution, Deployment → Docker`.
   Elige el tipo según lo tuyo: Docker Desktop, Docker Engine con socket, o un contexto
   concreto. Comprueba que WebStorm lista tus imágenes.
2. **Declara el intérprete remoto** en `Settings → Languages & Frameworks → Node.js`, añadiendo
   uno de tipo Docker y apuntando a `legacy-node-toolchain:phase09`.
3. **Fija la variable de entorno `NODE_VERSION`** en la configuración del contenedor. Sin ella,
   los shims de [F08](08-run-el-contenedor-como-proceso.md) usan el valor por defecto — que es correcto, pero si tu proyecto necesita
   Node 14, hay que decirlo.
4. **Declara los montajes**: tu proyecto en `/workspace` como bind mount, y el named volume
   sobre `/workspace/node_modules`. **Este paso es el que más se olvida**, y su síntoma es un
   `npm install` que tarda muchísimo y deja archivos en tu host.

**Verificación, antes de dar nada por bueno.** Con el intérprete configurado, ejecuta desde
WebStorm algo que imprima la versión y compáralo con lo que responde la terminal:

```bash
docker exec legacy-node-dev node --version
```

Si el IDE dice una cosa y la terminal otra, el IDE está usando otro runtime. Esa comprobación
de treinta segundos ahorra tardes enteras.

---

## 3. 🛟 Nivel B — modo universal

Es exactamente el flujo de [F09](09-montar-tu-proyecto.md) y [F10](10-vscode-y-debugging.md), con WebStorm en el papel de editor.

**Ejecutar** desde la terminal integrada, que —igual que en VS Code— es tu **host**:

```bash
docker exec legacy-node-dev npm ci
docker exec legacy-node-dev npm run build
```

WebStorm permite guardar comandos frecuentes como configuraciones de ejecución de tipo *Shell
Script*, que es el equivalente a las tasks de [F10](10-vscode-y-debugging.md) §5. Mismo criterio: que el comando esté a la
vista.

**Depurar** con una configuración *Attach to Node.js/Chrome*:

| Campo | Valor |
|---|---|
| Host | `localhost` |
| Port | `9229` |
| Remote URLs / path mappings | `${workspaceDir}` → `/workspace` |

Ese último campo es el equivalente exacto de `localRoot`/`remoteRoot` de [F10](10-vscode-y-debugging.md) §6.3, y falla por
la misma razón: **si el mapeo de rutas está mal, los breakpoints no paran nunca**. Es lo primero
que hay que revisar.

Y el arranque es idéntico al de [F10](10-vscode-y-debugging.md):

```bash
docker exec -it legacy-node-dev node --inspect-brk=0.0.0.0:9229 src/server.js
```

Con el contenedor publicando `127.0.0.1:9229:9229`, como se creó en [F10](10-vscode-y-debugging.md) §6.2.

---

## 4. 🏺 Por qué un IDE moderno puede no amar a Node 10

Es la parte que conviene entender antes de pelearse con la configuración.

WebStorm, como cualquier IDE actual, está desarrollado y probado contra runtimes **vigentes**.
Su integración de Node.js asume comportamientos, formatos de salida y protocolos de una
generación muy posterior a la nuestra:

```text
lo que el IDE espera        lo que tenemos
────────────────────        ──────────────
Node 20 · 22 · 24           Node 10 · 12 · 14 · 16
```

Cuando la distancia es grande, la integración puede **funcionar parcialmente**, **funcionar por
accidente**, **fallar en validaciones internas del IDE**, **perder funcionalidades** o
**romperse con una actualización del IDE** que no tiene nada que ver con tu proyecto.

> ⚠️ **Ninguna de esas cinco es un fallo de tu laboratorio.** El toolchain sigue siendo
> correcto: `docker exec ... npm run build` funciona igual. Lo que falla es la capa de comodidad
> del editor, y por eso el curso insiste en que el flujo base no dependa de ningún IDE.

Es también la razón de la recomendación de §1. Cuando el Nivel A deje de funcionar tras una
actualización de WebStorm —que puede pasar—, el Nivel B sigue ahí y no depende de nadie.

**La comprobación que separa los dos mundos** es la de [F10](10-vscode-y-debugging.md) §8, y vale igual aquí:

> 🩺 **¿Falla también desde la terminal?** Si sí, es tu proyecto. Si no, es el IDE.

---

## 5. 🧯 Problemas frecuentes

**No aparece la opción de intérprete remoto Docker.** Falta un plugin. `Settings → Plugins` y
comprueba los tres de §2 antes de seguir buscando.

**WebStorm no ve tus imágenes.** La conexión con Docker no está bien configurada. En macOS con
Docker Desktop suele ser automático; con Colima o Podman hay que apuntar al socket correcto.
**[F26](26-portabilidad-entre-motores.md)** trata las diferencias entre motores desde el IDE.

**`npm install` tarda muchísimo y llena tu host de archivos.** Falta el named volume sobre
`node_modules` — §2, paso 4.

**Los breakpoints no paran.** El mapeo de rutas. Comprueba que el destino es exactamente
`/workspace`.

**El IDE dice una versión de Node y la terminal otra.** El intérprete remoto apunta a otro
contenedor o a otra imagen, o falta el `NODE_VERSION`. Compara los dos y quédate con lo que diga
`docker exec`.

**La indexación del IDE se vuelve lenta.** Está indexando `node_modules`. Márcalo como excluido
en la configuración del proyecto: son decenas de miles de archivos que no aportan nada al
autocompletado de tu código.

---

## 🧭 Guía rápida: cuándo usar qué

| Tu situación | Elige |
|---|---|
| Primera vez montando esto, quieres algo que funcione hoy | **Nivel B** |
| El Nivel A funciona en tu versión de WebStorm y te va bien | **Nivel A**, con la verificación de §2 hecha |
| Actualizaste WebStorm y la integración dejó de funcionar | **Nivel B**, y no pierdas la tarde |
| Necesitas depurar y nada más | **Nivel B**: el attach por puerto es idéntico en los dos |
| Tu equipo mezcla VS Code y WebStorm | **Nivel B en los dos**, y documenta los comandos, no la configuración del IDE |

---

## 🧪 Ejercicios (5)

### 🟢 Ejercicio 1 — Nivel B completo

Ejecuta el ciclo `npm ci` → `test` → `build` desde la terminal de WebStorm sobre el toolbox de
[F09](09-montar-tu-proyecto.md).

**Objetivo:** confirmar que el laboratorio no depende del editor.

### 🟢 Ejercicio 2 — El IDE dice, la terminal manda

Configura el intérprete remoto y compara la versión de Node que reporta el IDE con la de
`docker exec`.

**Pregunta:** ¿coinciden? Si no, ¿cuál de los dos está diciendo la verdad sobre lo que ejecuta
tu proyecto?

### 🟡 Ejercicio 3 — Attach desde WebStorm

Monta la configuración de depuración de §3 y para en un breakpoint del fixture
`00-node-smoke`.

**Objetivo:** el mismo resultado de [F10](10-vscode-y-debugging.md) §6.4 con otro editor, para comprobar que el mecanismo
es del runtime y no del IDE.

### 🟡 Ejercicio 4 — Rompe el mapeo de rutas

Cambia el destino del mapeo a `/app` y vuelve a intentar el breakpoint.

**Objetivo:** provocar el breakpoint que no para, para reconocerlo. Es el mismo síntoma que en
VS Code y la misma causa.

### 🟠 Ejercicio 5 — Documenta para un equipo mixto

Tu equipo usa VS Code y WebStorm. Escribe el documento de una página que sirva a los dos.

**Objetivo:** descubrir que lo que hay que documentar son **los comandos** —qué contenedor, qué
puertos, qué mapeo— y no la configuración de ningún IDE. Es la conclusión práctica de este
apéndice.

---

## 📚 Referencias

- WebStorm — intérpretes de Node.js remotos: https://www.jetbrains.com/help/webstorm/configuring-remote-node-interpreters.html
- WebStorm — Docker: https://www.jetbrains.com/help/webstorm/docker.html
- WebStorm — depuración de Node.js: https://www.jetbrains.com/help/webstorm/running-and-debugging-node-js.html

> ⚠️ **La documentación de JetBrains describe la versión actual de WebStorm**, y la interfaz de
> estas opciones cambia entre versiones anuales. Los nombres de menú de este apéndice son
> orientativos; el mecanismo —intérprete remoto, mapeo de rutas, attach por puerto— es estable.
> Enlaces revisados el 3 de septiembre de 2026.

**Vuelve a:** [F10](10-vscode-y-debugging.md) · sigue en [F19](19-dev-containers.md) si quieres el equivalente de Dev Containers
