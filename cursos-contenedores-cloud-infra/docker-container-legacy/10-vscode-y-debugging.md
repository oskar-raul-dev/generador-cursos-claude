# 🟦 Parte I · Fase 10 — VS Code y debugging: breakpoints aquí, ejecución allá

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · Node 10.24.1 baseline
> **Arquitectura objetivo del laboratorio:** `linux/amd64`
> **Archivos que nacen aquí:** `.vscode/tasks.json` · `.vscode/launch.json`
> **Tag pedagógico:** `legacy-node-toolchain:phase09` (sin cambios: esta fase no toca la imagen)
> **Fecha de revisión de documentación externa:** 3 de septiembre de 2026
> **Código de esta fase:** [`src/10-vscode-y-debugging/`](src/10-vscode-y-debugging/)
> **Estado de la imagen al terminar:** sin cambios — la imagen es la de [F09](09-montar-tu-proyecto.md); lo que cambia es que tu editor ya habla con ella
> **Objetivo:** conectar tu editor y tu debugger a un runtime que vive dentro del contenedor, sin instalar Node 10 en el host

---

## 1. 🧭 Dónde estamos

[F09](09-montar-tu-proyecto.md) dejó el proyecto corriendo dentro del contenedor y editable desde tu host. Funciona
entero desde la terminal — y eso es deliberado: **el flujo del curso no depende de tu editor**.

Esta fase añade comodidad encima. VS Code lanzando comandos con un atajo, y el debugger de
Node parando en un breakpoint de tu editor mientras el proceso corre en Debian 10 dentro del
contenedor. Sin instalar nada legacy en tu máquina.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder:

- Separar tres responsabilidades que se mezclan constantemente: el IDE, el runtime y el
  proyecto.
- Usar VS Code en **Modo A** —editor en el host, Docker a la vista— y saber por qué el curso
  empieza por ahí.
- Automatizar los comandos frecuentes con `tasks.json` sin esconder lo que ejecutan.
- Conectar el debugger de Node al contenedor con `launch.json`, y entender `localRoot` y
  `remoteRoot`.
- Distinguir "IDE roto" de "proyecto roto", que es la mitad del tiempo perdido con
  herramientas.

---

## 3. 🚧 Qué NO entra todavía

- **Dev Containers** —el contenedor como ambiente completo del IDE, extensiones dentro,
  el socket de Docker, Git dentro del contenedor— → **[F19](19-dev-containers.md)**. Esta fase es deliberadamente el
  camino sin él.
- **UID, GID y `EACCES`** cuando el IDE escribe archivos → **[F17](17-usuarios-permisos-y-volumenes.md)**.
- **WebStorm**, con sus dos niveles de integración → **[a06](a06-webstorm.md)**.
- **Networking y publicación de puertos** para ver la app en el navegador → **[F18](18-networking-de-contenedores.md)**. Aquí
  publicamos el puerto del **debugger**, que es otra cosa.
- Debugging de navegador y su relación con el de Node → mencionado aquí, desarrollado en
  **[a09](a09-browsers-legacy.md)**.

---

## 4. 🧩 Tres responsabilidades distintas

La confusión que causa más problemas en esta parte del curso:

```mermaid
flowchart LR
    IDE["EL IDE · VS Code, WebStorm, Vim<br/>edita texto, resalta sintaxis, lanza comandos,<br/>conecta un debugger. Corre en TU host, moderno."]
    PR["EL PROYECTO · package.json, src/<br/>tu código y sus dependencias. Vive en el host,<br/>se ejecuta en el contenedor."]
    RT["EL RUNTIME · Node 10 en Debian 10<br/>ejecuta tu código. Node 10 dentro del contenedor,<br/>Debian 10, glibc de 2019."]
    IDE -- "edita" --> PR
    RT -- "ejecuta" --> PR
```

**El IDE no es Node.** VS Code trae su propio Node embebido para funcionar, y no tiene nada
que ver con el que ejecuta tu proyecto. De hecho pueden coexistir cuatro runtimes distintos en
tu máquina sin que ninguno sea el que importa: el de VS Code, el que instalaste alguna vez con
`brew`, el que usa alguna extensión, y el del contenedor. Solo el último ejecuta tu código.

> 🛑 **Anti-patrón: instalar Node 10 en el host "para que el IDE lo encuentre".** Es la
> respuesta natural y es exactamente lo contrario de lo que hace este curso. Si tu host es un
> Mac con Apple Silicon, además, **no puedes** — [F00](00-problema-y-contrato.md) §3.1. El IDE no necesita el runtime: solo
> necesita saber cómo hablarle.

### 4.1 La primera prueba, antes de configurar nada

Antes de tocar un solo archivo de configuración, comprueba desde la terminal integrada de VS
Code:

```bash
docker exec legacy-node-dev bash -lc 'node --version && npm --version && uname -m'
```
```text
v10.24.1
6.14.12
x86_64
```

> ⚠️ **La terminal integrada del IDE es tu host, no el contenedor.** Es la confusión número
> uno de esta fase. Si escribes `node --version` a secas ahí, te responde el Node de tu
> máquina —o "command not found"—, y eso no dice absolutamente nada sobre tu proyecto. Todo lo
> que quieras ejecutar en el runtime legacy pasa por `docker exec`.

### 4.2 Modo A y Modo B

**Modo A — editor en el host, Docker a la vista.** VS Code corre en tu máquina y lanza
comandos al contenedor con `docker exec`. Ves todos los comandos, funciona con cualquier
editor y no necesita ninguna extensión especial. **Es el camino de esta fase.**

**Modo B — Dev Containers.** VS Code se conecta *dentro* del contenedor: sus extensiones, su
terminal y su servidor viven ahí. Es más cómodo y esconde lo que ocurre por debajo. Su fase es
**[F19](19-dev-containers.md)**, y el orden no es casual: es la regla de [F00](00-problema-y-contrato.md) §8 del curso —primero el mecanismo,
después la comodidad—.

> 📝 **Una coincidencia histórica conveniente.** Debian 10 todavía cumple los requisitos de
> glibc del servidor remoto de VS Code, así que Dev Containers funciona sobre nuestra imagen.
> No estaba garantizado: versiones más antiguas de Debian ya no lo consiguen. [F19](19-dev-containers.md) lo trata.

---

## 5. 🤖 Tasks: automatizar sin esconder

Una **task** de VS Code es un comando con nombre que puedes lanzar desde la paleta o con un
atajo. Aquí sirven para no escribir `docker exec legacy-node-dev npm ci` veinte veces al día.

📄 **`.vscode/tasks.json`**

```jsonc
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Legacy: versions",
      "type": "process",
      "command": "docker",
      "args": [
        "exec", "legacy-node-dev",
        "bash", "-lc",
        "node --version && npm --version && uname -m"
      ],
      "problemMatcher": []
    },
    {
      "label": "Legacy: npm ci",
      "type": "process",
      "command": "docker",
      "args": ["exec", "legacy-node-dev", "npm", "ci"],
      "problemMatcher": []
    },
    {
      "label": "Legacy: test",
      "type": "process",
      "command": "docker",
      "args": ["exec", "legacy-node-dev", "npm", "test"],
      "problemMatcher": []
    },
    {
      "label": "Legacy: build",
      "type": "process",
      "command": "docker",
      "args": ["exec", "legacy-node-dev", "npm", "run", "build"],
      "problemMatcher": []
    }
  ]
}
```

**Detalles con intención:**

- **`"type": "process"` y no `"shell"`.** Con `process`, VS Code ejecuta el binario con los
  argumentos tal cual y no pasa por un shell intermedio. Eso evita problemas de quoting y hace
  que la task se comporte igual en macOS, Linux y Windows — donde el shell por defecto es
  PowerShell y las reglas de comillas son otras.
- **Cada task es un `docker exec` visible.** Puedes copiarlo y ejecutarlo a mano. Eso es
  deliberado: una task que esconde su comando es una caja negra, y este curso no las quiere.
- **`problemMatcher: []`** evita que VS Code intente interpretar la salida como errores de
  compilación e inunde el panel de problemas.
- **El nombre del contenedor está escrito.** Si usas otro, cámbialo en los cuatro sitios — o
  mejor, ejecuta la primera task para comprobar antes de nada.

> ⚠️ **La task falla si el contenedor no existe.** No lo crea: `docker exec` necesita algo
> vivo. Antes de lanzar tasks, arranca el toolbox con `./scripts/run-dev.sh` de [F09](09-montar-tu-proyecto.md). Si una
> task falla con `No such container`, esa es la causa el 90% de las veces.

---

## 6. 🐞 Node Inspector: el debugger de verdad

Node trae un depurador incorporado que expone un protocolo por un puerto. VS Code se conecta
a ese puerto y ya tienes breakpoints, pila de llamadas, variables y expresiones de
seguimiento — con el proceso corriendo dentro del contenedor.

### 6.1 `--inspect` y `--inspect-brk`

```bash
node --inspect=0.0.0.0:9229 server.js       # arranca y sigue; te conectas cuando quieras
node --inspect-brk=0.0.0.0:9229 server.js   # arranca y ESPERA a que te conectes
```

`--inspect-brk` es el que quieres cuando el problema está en el arranque, porque para en la
primera línea antes de ejecutar nada.

> 🧭 **`0.0.0.0` y no `127.0.0.1`.** Por defecto el inspector escucha solo en el loopback
> **del contenedor**, y ahí tu host no llega. Hay que decirle que escuche en todas las
> interfaces del contenedor para que el puerto publicado sirva de algo. El porqué completo
> —qué es `localhost` dentro de un contenedor— es de **[F18](18-networking-de-contenedores.md)**.

### 6.2 Publicar el puerto del debugger

El contenedor tiene que exponer 9229 al host, y eso se decide **al crearlo**:

```bash
docker run -d \
  --name legacy-node-dev \
  --platform linux/amd64 \
  -e NODE_VERSION=10.24.1 \
  -p 127.0.0.1:9229:9229 \
  --mount type=bind,src="$PWD",dst=/workspace \
  --mount type=volume,src=legacy-node10-modules,dst=/workspace/node_modules \
  legacy-node-toolchain:phase09 \
  sleep infinity
```

> ⚠️ **El puerto del debugger no es el puerto de tu aplicación.** Son dos cosas distintas: tu
> app puede servir en 3000 y el inspector siempre en 9229. Si quieres las dos, publicas las
> dos.

> 🚨 **Publica el inspector en `127.0.0.1`, nunca en `0.0.0.0` del host.** Quien pueda hablar
> con el puerto del inspector **puede ejecutar código arbitrario** en ese proceso. Dentro de tu
> máquina es cómodo; expuesto a la red es un agujero. El `127.0.0.1:` del principio es lo que
> lo limita a tu equipo.

### 6.3 `launch.json`

📄 **`.vscode/launch.json`**

```jsonc
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Legacy Node 10: attach Docker",
      "type": "node",
      "request": "attach",
      "address": "localhost",
      "port": 9229,
      "localRoot": "${workspaceFolder}",
      "remoteRoot": "/workspace",
      "restart": false,
      "skipFiles": ["<node_internals>/**"]
    }
  ]
}
```

**`localRoot` y `remoteRoot` son la pieza clave**, y es donde falla casi todo el mundo la
primera vez. El mismo archivo tiene dos nombres:

```text
HOST         /Users/ana/repos/legacy-vue/src/foo.js
                            ↕  el debugger necesita traducir
CONTENEDOR   /workspace/src/foo.js
```

Sin esa traducción, VS Code recibe del inspector rutas que empiezan por `/workspace` y no
encuentra el archivo que tienes abierto — así que tus breakpoints salen grises y no paran
nunca. **Ese es el síntoma**: si un breakpoint no se activa, sospecha de estas dos líneas
antes que de nada.

**`request: "attach"` y no `"launch"`.** Con `launch`, VS Code arrancaría el proceso él mismo
— en tu host, con tu Node, que es justo lo que no queremos. Con `attach` el proceso lo arrancas
tú dentro del contenedor y el editor solo se conecta.

**`skipFiles: ["<node_internals>/**"]`** evita que el depurador entre en el código interno de
Node al hacer step. Sin él, un `step into` sobre cualquier llamada te lleva a las tripas de
Node y pierdes el hilo.

### 6.4 El ciclo completo

```bash
# 1. arranca tu app con el inspector, dentro del contenedor
docker exec -it legacy-node-dev node --inspect-brk=0.0.0.0:9229 src/server.js
```
```text
Debugger listening on ws://0.0.0.0:9229/8f2c...
For help, see: https://nodejs.org/en/docs/inspector
```

```text
# 2. en VS Code: F5 con "Legacy Node 10: attach Docker" seleccionado
# 3. pon un breakpoint en src/server.js y provoca que se ejecute
```

> 🔥 **Prueba de fuego.** Con el proceso detenido en un breakpoint, abre la consola de
> depuración y evalúa `process.version`. Debe responder `v10.24.1` — el Node del contenedor,
> no el de tu host. Si responde otra cosa, estás depurando el proceso equivocado.

---

## 7. 🗺️ Source maps y por qué Node no es Chrome

Si tu proyecto se transpila —TypeScript, Babel, un bundle de Webpack— el código que **corre**
no es el que **escribiste**. Los *source maps* son el archivo que traduce entre los dos, y sin
ellos el debugger te para en una línea de un bundle minificado que no reconoces.

En un proyecto legacy hay tres cosas que comprobar cuando los breakpoints caen en sitios
raros: que el build genere source maps —en Webpack es la opción `devtool`—, que los `.map`
lleguen junto al código generado, y que `localRoot`/`remoteRoot` sigan siendo correctos para
las rutas **del código fuente original**.

**Y una distinción que ahorra confusión:** hay **dos** depuradores distintos en juego.

```text
código de servidor          →  Node Inspector, puerto 9229, este launch.json
código de navegador         →  las DevTools del navegador, u otra configuración
```

En un proyecto Vue 2 o React 16, tu componente **corre en el navegador**, no en Node. El
Inspector de Node no lo va a ver nunca. Lo que sí depuras con esta configuración es el
servidor de desarrollo, los scripts de build, los tests que corren en Node, y cualquier
herramienta del toolchain. Depurar el navegador es otra conversación, y vive en **[a09](a09-browsers-legacy.md)**.

---

## 8. 🧯 "IDE roto" contra "proyecto roto"

Es la habilidad más rentable de esta fase, y se reduce a una pregunta:

> 🩺 **¿Falla también desde la terminal, sin el IDE de por medio?**

```bash
docker exec legacy-node-dev npm run build
```

Si **falla igual**, el IDE es inocente: tienes un problema de proyecto y toda la Parte I te
sirve para diagnosticarlo. Si **funciona desde la terminal y falla desde el editor**, el
problema es de configuración del IDE: la task apunta a otro contenedor, la extensión usa otro
Node, o el `launch.json` traduce mal las rutas.

Esa comprobación cuesta diez segundos y evita horas de tocar configuración que no era la
culpable.

---

## 9. 📁 Qué se versiona en Git

Una duda razonable: ¿el `.vscode/` va al repositorio?

**Sí, y con criterio.** `tasks.json` y `launch.json` describen **cómo se trabaja en este
proyecto**, no las preferencias de nadie: qué contenedor, qué puerto, qué rutas. Es
documentación ejecutable y le ahorra media tarde al siguiente que llegue.

Lo que **no** va: `settings.json` con preferencias personales de tema o tipografía, y cualquier
archivo con rutas absolutas de tu máquina. Si un `launch.json` tiene `/Users/tunombre/` en
algún sitio, usa `${workspaceFolder}` en su lugar.

Y desde luego no van `node_modules`, `dist`, ni el `.env` — que ya están en tu `.dockerignore`
de [F07](07-build-de-la-imagen.md) y deberían estar también en el `.gitignore`.

---

## 10. ⚠️ Errores comunes y diagnóstico

**`Error response from daemon: No such container`** al lanzar una task. El toolbox no está
corriendo. `./scripts/run-dev.sh` y vuelve a intentarlo.

**Los breakpoints salen grises y nunca paran.** Casi siempre es `localRoot`/`remoteRoot`.
Comprueba que `remoteRoot` es exactamente `/workspace` y que estás abriendo en VS Code la
carpeta que montaste, no una superior.

**`connect ECONNREFUSED 127.0.0.1:9229`.** Tres causas posibles, en orden de probabilidad: el
proceso no arrancó con `--inspect`; arrancó con `--inspect` sin `0.0.0.0`; o el contenedor no
publica el puerto. Comprueba con `docker port legacy-node-dev`.

**El debugger conecta pero `process.version` responde una versión moderna.** Estás conectado a
un proceso Node de tu **host**, no del contenedor. Revisa si tienes otro `node --inspect`
corriendo por ahí, y si tu `launch.json` dice `attach` y no `launch`.

**La terminal integrada no encuentra `node`.** Correcto: esa terminal es tu host. Si necesitas
el runtime, `docker exec`.

**`npm test` funciona en la terminal y falla como task.** Compara los dos comandos carácter a
carácter: casi siempre la task tiene un argumento de más o de menos, o apunta a otro
contenedor.

---

## 11. 📋 Checklist de validación

```text
[ ] El contenedor legacy-node-dev existe y publica 127.0.0.1:9229
[ ] .vscode/tasks.json con las cuatro tasks
[ ] .vscode/launch.json con la configuración de attach
[ ] La task "Legacy: versions" responde v10.24.1, 6.14.12, x86_64
[ ] Las tasks de npm ci, test y build se ejecutan desde la paleta
[ ] node --inspect-brk dentro del contenedor imprime "Debugger listening"
[ ] VS Code conecta con F5 y el proceso continúa
[ ] Un breakpoint en tu código fuente detiene la ejecución
[ ] process.version en la consola de depuración responde v10.24.1
[ ] Sabes hacer la comprobación de §8 sin pensarlo
[ ] .vscode/ está versionado y sin rutas absolutas
```

---

## 12. 🧪 Ejercicios de la Fase 10 (20)

## 🟢 Fácil — conectar el IDE (1–7)

### 🟢 Ejercicio 1 — Cuatro runtimes

En tu host, ejecuta `node --version` si existe, localiza el Node embebido de VS Code, y
compáralos con el del contenedor.

**Pregunta:** ¿cuántos Node distintos hay en tu máquina y cuál ejecuta tu proyecto?

### 🟢 Ejercicio 2 — La terminal integrada es tu host

En la terminal de VS Code ejecuta `node --version` y después `docker exec legacy-node-dev node --version`.

**Objetivo:** que la confusión de §4.1 no te vuelva a pasar.

### 🟢 Ejercicio 3 — La primera task

Crea `tasks.json` con solo "Legacy: versions" y lánzala desde la paleta.

**Objetivo:** ver la salida en el panel de VS Code y confirmar que ejecuta en el contenedor.

### 🟢 Ejercicio 4 — Las cuatro tasks

Completa el archivo y ejecuta el ciclo `npm ci` → `test` → `build` sin salir del editor.

### 🟢 Ejercicio 5 — La task sin contenedor

Para el contenedor y lanza una task.

**Objetivo:** leer el error y reconocerlo instantáneamente.

### 🟢 Ejercicio 6 — El inspector, a secas

Arranca `node --inspect-brk=0.0.0.0:9229 -e "let x=1; x++; console.log(x)"` dentro del
contenedor.

**Pregunta:** ¿qué imprime y por qué se queda esperando?

### 🟢 Ejercicio 7 — Publica el puerto

Recrea el toolbox con `-p 127.0.0.1:9229:9229` y comprueba con `docker port`.

**Pregunta:** ¿por qué hubo que **recrear** el contenedor y no bastó con reiniciarlo?

## 🟡 Intermedio — depurar de verdad (8–13)

### 🟡 Ejercicio 8 — Attach completo

Haz el ciclo de §6.4 sobre el fixture `00-node-smoke`, con un breakpoint que pare de verdad.

**Objetivo:** el primer breakpoint del curso que se ejecuta en Debian 10 desde tu editor.

### 🟡 Ejercicio 9 — `process.version` en la consola

Con el proceso detenido, evalúa `process.version`, `process.platform` y `process.arch`.

**Pregunta:** ¿coinciden con tu host? Si `process.arch` dice `x64` y tu Mac es ARM, ¿qué
significa?

### 🟡 Ejercicio 10 — `--inspect` contra `--inspect-brk`

Prueba las dos formas con un script que imprima algo en la primera línea.

**Pregunta:** ¿con cuál llegas a tiempo de ver esa línea en un breakpoint?

### 🟡 Ejercicio 11 — Breakpoint condicional

Pon un breakpoint dentro de un bucle que solo pare cuando el índice supere cierto valor.

**Objetivo:** usar una función del debugger que ahorra el 90% de los `console.log` en bucles.

### 🟡 Ejercicio 12 — Depura los tests

Arranca la suite de tests con `--inspect-brk` en lugar del comando normal y conéctate.

**Pregunta:** ¿qué tuviste que cambiar en el comando de npm? Pista: `node --inspect-brk
node_modules/.bin/...`.

### 🟡 Ejercicio 13 — Dos puertos a la vez

Recrea el toolbox publicando 3000 y 9229, arranca una app que sirva en 3000 con el inspector
activo.

**Objetivo:** tener la app y el debugger simultáneamente, y ver que son cosas separadas.

## 🟠 Difícil — cuando el breakpoint no para (14–17)

### 🟠 Ejercicio 14 — Rompe `remoteRoot`

Cambia `remoteRoot` a `/app` y vuelve a intentar el breakpoint.

**Objetivo:** provocar el breakpoint gris a propósito, para reconocer el síntoma.

### 🟠 Ejercicio 15 — El inspector que no escucha

Arranca con `node --inspect=127.0.0.1:9229` en lugar de `0.0.0.0` e intenta conectar.

**Pregunta:** ¿qué error da? ¿Por qué `127.0.0.1` dentro del contenedor no es tu `127.0.0.1`?
Anota la duda: **[F18](18-networking-de-contenedores.md)** la responde entera.

### 🟠 Ejercicio 16 — Source maps ausentes

Depura código transpilado con los source maps desactivados en la configuración de build, y
después con ellos activados.

**Objetivo:** ver dónde para el debugger en cada caso y entender qué traduce exactamente el
`.map`.

### 🟠 Ejercicio 17 — Depura un fixture real

Toma el fixture Vue 2 de `src/10-validar-tu-proyecto/10-vue2-min/` y depura **el servidor de
desarrollo**, no el componente.

**Pregunta:** ¿qué puedes inspeccionar y qué no? Relaciónalo con §7 y explica por qué tu
`App.vue` no para en un breakpoint del Inspector de Node.

## 🔴 Muy difícil — documentar y decidir (18–20)

### 🔴 Ejercicio 18 — ¿IDE roto o proyecto roto?

Rompe deliberadamente tres cosas, una cada vez: (a) el nombre del contenedor en `tasks.json`;
(b) el script `build` del `package.json`; (c) el `remoteRoot`. Para cada una, aplica la
comprobación de §8.

**Objetivo:** confirmar que la pregunta de §8 distingue correctamente los tres casos, y anotar
qué síntoma tiene cada uno.

### 🔴 Ejercicio 19 — Documenta el entorno para tu equipo

Escribe el `README-dev.md` que acompañaría a tu `.vscode/`: qué contenedor hace falta, qué
puertos, qué tasks existen y qué hacer cuando un breakpoint no para.

**Objetivo:** que alguien que llega mañana al proyecto pueda depurar en quince minutos sin
preguntarte nada. Es el entregable que **[F34](34-proyecto-final.md)** te va a pedir de verdad.

### 🔴 Ejercicio 20 — Defiende el Modo A

Un compañero propone saltar directo a Dev Containers: *"esto son dos archivos de configuración
y un `docker exec` en cada task; con Dev Containers abres la carpeta y ya está"*.

**Objetivo:** escribir la respuesta reconociendo que tiene razón en comodidad, y explicando qué
se aprende en el Modo A que el Modo B esconde — con al menos dos situaciones concretas de
diagnóstico donde saber lo del Modo A te salva. Y termina diciendo cuándo pasarías tú a Modo B,
porque el curso lo hace en [F19](19-dev-containers.md).

## 🔥 Opcionales

### 🔥 Ejercicio 21 — Tasks con dependencias

Encadena las tasks para que "Legacy: build" ejecute antes "Legacy: npm ci" automáticamente,
usando `dependsOn`.

**Pregunta:** ¿mejora el flujo o esconde información útil? No hay una respuesta correcta;
justifica la tuya.

### 🔥 Ejercicio 22 — Depuración remota sin VS Code

Conecta al inspector usando `chrome://inspect` del navegador o el cliente `node inspect`.

**Objetivo:** comprobar que el protocolo es del runtime, no del editor — y que tu configuración
no depende de VS Code.

## 💀 Boss fight

### 💀 Ejercicio 23 — Boss fight: el breakpoint que no para

Te llaman porque el debugger "no funciona". Adjuntan tres síntomas de tres compañeros
distintos: a uno el breakpoint le sale hueco y nunca se dispara; a otro el proceso arranca y
el IDE dice `connect ECONNREFUSED 127.0.0.1:9229`; al tercero el breakpoint sí para, pero en
una línea que no corresponde al código que escribió.

**Objetivo:** los tres son fallos **distintos** y hay que tratarlos como tales. Para cada uno:
reprodúcelo a propósito en tu laboratorio, di en qué capa está la causa aplicando el triaje de
§8 —¿IDE, contenedor o proyecto?—, y arréglalo con la evidencia del arreglo. Las tres causas
son: el mapeo de rutas del `launch.json` entre host y contenedor (§6), el
`--inspect=0.0.0.0:9229` y su publicación (§6, y lo que **[F18](18-networking-de-contenedores.md)** dirá sobre `127.0.0.1`), y
los source maps de §7. Después escribe la **tabla de tres filas** —síntoma, comprobación,
causa— que le pasarías al equipo para que la próxima vez no te llamen.

**Pregunta:** de las tres, ¿cuál seguiría fallando exactamente igual si cambiaras VS Code por
WebStorm ([a06](a06-webstorm.md))? Justifica cuál es del IDE y cuáles no lo son.

---

## 13. 📚 Referencias

**VS Code**
- Tasks: https://code.visualstudio.com/docs/editor/tasks
- Depuración: https://code.visualstudio.com/docs/editor/debugging
- Node.js en un contenedor: https://code.visualstudio.com/docs/containers/quickstart-node
- Variables como `${workspaceFolder}`: https://code.visualstudio.com/docs/reference/variables-reference

**Node Inspector**
- Guía oficial de depuración: https://nodejs.org/en/learn/getting-started/debugging
- Referencia del protocolo: https://chromedevtools.github.io/devtools-protocol/

**Puertos**
- Publicación de puertos en Docker: https://docs.docker.com/engine/network/#published-ports

> ⚠️ **La documentación de VS Code describe la versión actual del editor**, que cambia varias
> veces al año. Los nombres de opciones de `launch.json` que usa esta fase son estables desde
> hace mucho, pero si algo no coincide, la referencia manda sobre el curso. Enlaces revisados
> el 3 de septiembre de 2026.

**Orden de lectura sugerido:** la guía de depuración de VS Code antes del ejercicio 8, y la
referencia de variables cuando escribas tu propio `launch.json` para otro proyecto.

---

## 14. 🏁 Resultado de la fase

```text
IMAGEN        sin cambios — esta fase no toca el toolchain

NUEVO         .vscode/tasks.json     cuatro comandos frecuentes, visibles
              .vscode/launch.json    attach al inspector del contenedor
              el toolbox publica 127.0.0.1:9229

FLUJO         editas en el host
              ejecutas con docker exec, desde la terminal o desde una task
              depuras con breakpoints en tu editor
              el proceso corre en Debian 10 con Node 10.24.1

SABES         que el IDE, el runtime y el proyecto son tres cosas
              qué traducen localRoot y remoteRoot, y qué pasa si están mal
              por qué el inspector escucha en 0.0.0.0 y se publica en 127.0.0.1
              distinguir "IDE roto" de "proyecto roto" en diez segundos
```

> **La señal de que quedó bien:** *"pongo un breakpoint en mi editor moderno y para en un
> proceso de Node 10 que corre en un Debian de 2019 — y mi máquina no tiene ninguno de los
> dos instalado."*

En **[F11](11-validar-tu-proyecto.md)**, la última fase del taller, convertimos todo esto en un veredicto: qué significa que
tu proyecto sea "compatible", y cómo se demuestra con evidencia.
