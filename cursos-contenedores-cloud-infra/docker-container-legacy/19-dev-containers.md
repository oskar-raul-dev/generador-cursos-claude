# 📦 Parte II · Fase 19 — Dev Containers: la comodidad, ahora que sabes qué esconde

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · Node 10.24.1 baseline
> **Archivo que nace aquí:** `.devcontainer/devcontainer.json`
> **Requisitos:** **[F10](10-vscode-y-debugging.md)** (VS Code Modo A), **[F17](17-usuarios-permisos-y-volumenes.md)** (permisos) y **[F18](18-networking-de-contenedores.md)** (puertos)
> **Fecha de revisión de documentación externa:** 3 de septiembre de 2026
> **Estado de la imagen al terminar:** sin cambios — Dev Containers **reutiliza** nuestra imagen, no construye otra
> **Código de esta fase:** [`src/19-dev-containers/`](src/19-dev-containers/)
> **Objetivo:** convertir el contenedor en el ambiente completo del IDE, sabiendo exactamente qué automatiza cada línea del `devcontainer.json`

---

## 1. 🧭 Dónde estamos

[F10](10-vscode-y-debugging.md) te dio el **Modo A**: el editor en tu host, lanzando comandos con `docker exec`, todo a la
vista. Y te dijo que el Modo B —Dev Containers— llegaba después a propósito, siguiendo la regla
del curso de **primero el mecanismo, después la comodidad**.

Ese momento es ahora, y el orden importa: cada línea del `devcontainer.json` que vas a escribir
corresponde a algo que ya sabes hacer a mano. No es magia nueva; es tu `docker run` de [F09](09-montar-tu-proyecto.md)
escrito en JSON.

```text
lo que ya sabes hacer                    la línea que lo automatiza
─────────────────────                    ──────────────────────────
--mount type=bind ... dst=/workspace  →  "workspaceMount"
--mount type=volume ... node_modules  →  "mounts"
-e NODE_VERSION=10.24.1               →  "containerEnv"
--platform linux/amd64                →  "runArgs"
-p 127.0.0.1:8080:8080                →  "forwardPorts"
```

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder:

- Explicar qué hace Dev Containers y **dónde corre cada cosa** cuando lo usas.
- Escribir un `devcontainer.json` que reutilice el toolchain del curso.
- Saber por qué las extensiones se dividen en dos grupos y cuál va dónde.
- Entender por qué aparece el **socket de Docker** en los tutoriales y por qué no lo montamos.
- Manejar Git desde dentro del Dev Container sin pelearte con las credenciales.
- Decidir con criterio entre el Modo A y el Modo B.

---

## 3. 🚧 Qué NO entra todavía

- **Podman con Dev Containers**, que funciona pero con diferencias reales → **[F26](26-portabilidad-entre-motores.md)**.
- **GitHub Codespaces**, que es Dev Containers en la nube → fuera de alcance; lo que aprendes
  aquí se traslada casi entero.
- **La comparación de rendimiento** entre Modo A y Modo B en macOS → **F26**.

---

## 4. 🧠 Qué es, y dónde corre cada cosa

Dev Containers hace que **VS Code se parta en dos**: la interfaz sigue en tu máquina, y un
servidor —*VS Code Server*— se instala y corre **dentro del contenedor**.

```mermaid
flowchart LR
    subgraph HOST["TU HOST"]
        UI["VS Code (la UI)<br/>ventanas, teclas<br/>extensiones de UI"]
    end
    subgraph CT["EL CONTENEDOR"]
        SRV["VS Code Server<br/>extensiones del proyecto<br/>terminal integrada<br/>Node 10, npm, gcc…<br/>tu proyecto en /workspace"]
    end
    UI <--> SRV
```

La diferencia práctica con el Modo A es **una sola** y lo cambia todo:

> 🧭 **En Modo A, la terminal integrada es tu host.** En Modo B, la terminal integrada **es el
> contenedor**. Escribes `node --version` y responde `v10.24.1` sin `docker exec` de por medio.

De ahí sale todo lo bueno —y todo lo confuso— de esta fase.

> 📝 **Nota de época, y de suerte.** Que esto funcione sobre nuestra imagen no estaba
> garantizado: VS Code Server exige una `glibc` mínima, y Debian 10 con su 2.28 **todavía la
> cumple**. Distribuciones más antiguas ya no lo consiguen, así que un laboratorio sobre
> Stretch o Jessie no podría usar Dev Containers. Es una coincidencia conveniente que conviene
> saber que es una coincidencia.

---

## 5. 🥇 La regla de esta fase: reutilizar nuestra imagen

Casi todos los tutoriales de Dev Containers empiezan con un `Dockerfile` propio dentro de
`.devcontainer/`, o con una imagen de la galería de Microsoft.

**Nosotros no.** El `devcontainer.json` de este curso apunta a `legacy-node-toolchain`, la
imagen que llevas once fases construyendo.

Por dos razones:

**Una sola definición del entorno.** Si el Dev Container construyera su propia imagen, tendrías
dos toolchains que mantener sincronizados y que divergirían en la primera prisa. El día que
algo falle solo en el IDE, no sabrías si es el IDE o la otra imagen.

**Lo que funciona en la terminal funciona en el IDE, por construcción.** Es la propiedad que
hace útil el diagnóstico de [F10](10-vscode-y-debugging.md) §8 —*"¿falla también desde la terminal?"*—. Con dos imágenes
distintas, esa pregunta deja de discriminar.

---

## 6. 📄 El `devcontainer.json`

📄 **`.devcontainer/devcontainer.json`**

```jsonc
{
  "name": "Legacy Node 10 - Vue 2",

  // reutilizamos el toolchain del curso: una sola definición del entorno
  "image": "legacy-node-toolchain:phase15",

  "workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind",
  "workspaceFolder": "/workspace",

  // node_modules en named volume, con la generación de Node en el nombre (F01, F14)
  "mounts": [
    "source=legacy-vue2-node10-modules,target=/workspace/node_modules,type=volume"
  ],

  "containerEnv": {
    "NODE_VERSION": "10.24.1"
  },

  // --platform por el baseline de F01; --init por los zombies de F16
  "runArgs": [
    "--platform=linux/amd64",
    "--init"
  ],

  "forwardPorts": [8080, 3000, 9229],

  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.defaultProfile.linux": "bash",
        "typescript.tsdk": "node_modules/typescript/lib",
        "vetur.useWorkspaceDependencies": true
      },
      "extensions": [
        "dbaeumer.vscode-eslint",
        "octref.vetur",
        "esbenp.prettier-vscode"
      ]
    }
  }
}
```

> ⚠️ **Es un ejemplo pedagógico, no una plantilla universal.** Antes de fijar una extensión o
> un `setting` en un proyecto real, comprueba que corresponde a las versiones y convenciones de
> **ese** repositorio. `vetur` es de Vue 2; en un proyecto React sobra y estorba.

### 6.1 Línea por línea

**`image`** — reutiliza el toolchain. También existe `build` para construir desde un Dockerfile
propio y `dockerComposeFile` para escenarios multi-contenedor; ninguno hace falta aquí.

**`workspaceMount` y `workspaceFolder`** — es el bind mount de [F09](09-montar-tu-proyecto.md) con otra sintaxis.
`${localWorkspaceFolder}` es la carpeta que abriste en VS Code, y `/workspace` es la ruta
estándar que fijó [F01](01-decisiones-debian-zonas-node.md).

**`mounts`** — el named volume sobre `node_modules`, exactamente por lo de [F14](14-abi-libc-y-prebuilds.md) §5.1. **El
nombre lleva la generación de Node** y eso no es cosmética: si abres el mismo proyecto con
Node 14, necesitas otro volumen o vas a reproducir el error de ABI.

**`containerEnv`** — las variables del contenedor. `NODE_VERSION` es lo que leen los shims de
[F08](08-run-el-contenedor-como-proceso.md) para decidir qué Node responde.

**`runArgs`** — lo que no cabe en las otras claves, y va directo a `docker run`. Aquí van dos:
`--platform` por el baseline de [F01](01-decisiones-debian-zonas-node.md), y `--init` por lo de [F16](16-pid1-senales-y-ciclo-de-vida.md) §8 — que en un IDE tiene sentido,
porque las herramientas de build lanzan bastantes subprocesos.

**`forwardPorts`** — VS Code publica esos puertos al host automáticamente, y además **te avisa
cuando un proceso empieza a escuchar en uno**. Es una de las comodidades reales del Modo B: se
acabó el `-p` olvidado de [F18](18-networking-de-contenedores.md).

**`customizations.vscode`** — settings y extensiones **del proyecto**, versionados en Git. Es
donde el `devcontainer.json` deja de ser un `docker run` y empieza a aportar algo propio.

---

## 7. 🧩 Extensiones: dos grupos, y por qué

Las extensiones de VS Code se dividen en dos según dónde necesitan correr, y confundirlas
produce el clásico *"la instalé y no hace nada"*.

| | Corre en | Ejemplos |
|---|---|---|
| **UI extensions** | tu **host** | temas, iconos, atajos, mapas de teclado |
| **Workspace extensions** | el **contenedor** | ESLint, Prettier, TypeScript, Vetur, depuradores |

La regla es sencilla: **si la extensión necesita leer tu código o ejecutar una herramienta del
proyecto, va en el contenedor**. ESLint necesita el `eslint` de tu `node_modules`; si corriera
en tu host, usaría otro — o ninguno.

Por eso van declaradas en `customizations.vscode.extensions`: al abrir el Dev Container, VS
Code las instala **dentro**, y al siguiente que clone el repositorio le pasa lo mismo sin que
nadie se lo explique.

> 💡 **El síntoma de tenerlo mal.** ESLint no subraya nada, o subraya cosas raras. Abre el panel
> de extensiones: las de workspace aparecen en una sección separada cuando estás en un Dev
> Container. Si la tuya está en la de local, ahí tienes la causa.

---

## 8. 🐳 El socket de Docker: por qué aparece y por qué no lo montamos

En muchos tutoriales de Dev Containers verás esto:

```jsonc
"mounts": ["source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"]
```

**Qué hace:** le da al contenedor acceso al motor de Docker de tu host, para que pueda
construir imágenes y lanzar otros contenedores desde dentro.

**Cuándo tiene sentido:** cuando tu Dev Container es el entorno desde el que construyes
imágenes, o cuando corres tests que levantan contenedores.

**Por qué el curso no lo hace**, y conviene decirlo claro:

> 🚨 **Montar el socket de Docker equivale a dar acceso root al host.** Quien puede hablar con
> el socket puede arrancar un contenedor privilegiado que monte `/` del host. No es una
> exageración: es la consecuencia directa del modelo de Docker rootful, y **[F25](25-rootless-y-user-namespaces.md)** lo trata en
> serio.

Y en nuestro caso no aporta: el laboratorio construye la imagen **desde tu host**, no desde
dentro del Dev Container. La comodidad no compensa el agujero.

Si en algún proyecto lo necesitas de verdad, la conversación honesta es sobre el modelo de
seguridad completo, y esa está en **[F25](25-rootless-y-user-namespaces.md)**.

---

## 9. 🌿 Git dentro del Dev Container

La terminal del Modo B es el contenedor, así que `git` es el `git` de Debian 10 — que existe,
porque [F03](03-apt-y-utilidades.md) lo instaló. Pero hay dos cosas que **no** están dentro: tu configuración y tus
credenciales.

**La configuración.** VS Code copia automáticamente tu `user.name` y `user.email` al
contenedor. Compruébalo antes de tu primer commit:

```bash
git config --get user.name
git config --get user.email
```

Un commit con el autor equivocado es incómodo de arreglar después.

**Las credenciales.** VS Code reenvía tu agente SSH y tu credential helper al contenedor, así
que `git push` suele funcionar sin configurar nada. Cuando no funciona, la causa suele ser una
de tres: el agente SSH no está corriendo en tu host, la clave tiene passphrase y no está
cargada, o estás usando HTTPS con un helper que el contenedor no ve.

> ⚠️ **La alternativa que hay que evitar:** copiar tu clave privada dentro de la imagen o del
> contenedor. Es cómodo una vez y es un problema para siempre — y por [F13](13-overlayfs-y-copy-on-write.md) sabes que si acaba en
> una capa, ahí se queda.

**Y el `.gitignore`.** Con Dev Containers, `.devcontainer/devcontainer.json` **sí se versiona**:
describe cómo se trabaja en el proyecto, igual que el `.vscode/` de [F10](10-vscode-y-debugging.md) §9. Lo que no va son
las preferencias personales.

---

## 10. ⚖️ Modo A y Modo B, comparados

| | Modo A ([F10](10-vscode-y-debugging.md)) | Modo B (Dev Containers) |
|---|---|---|
| Dónde está el editor | host | host, con servidor dentro |
| La terminal integrada es | tu host | el contenedor |
| Cómo ejecutas | `docker exec` explícito | directamente |
| Extensiones | en tu host | dentro, declaradas en el JSON |
| Puertos | `-p` a mano | `forwardPorts`, con aviso |
| Qué ves | todos los comandos | el resultado |
| Qué aprendes | el mecanismo | el flujo |
| Si algo falla | sabes dónde mirar | hay una capa más entre tú y la causa |
| Funciona con | cualquier editor | VS Code y compatibles |
| Rendimiento en macOS | el del bind mount | el del bind mount, más el servidor dentro |

> 🧭 **Cuál usar, sin dogma.** Si trabajas solo y ya entiendes el mecanismo, el Modo B es más
> cómodo y no pierdes nada. Si trabajas en equipo, el Modo B **documenta el entorno en un
> archivo versionado**, que vale mucho. Y si algo se rompe, vuelve al Modo A un rato: quita una
> capa de en medio y suele bastar para ver la causa.
>
> Lo que **no** recomienda este curso es empezar por el Modo B sin haber hecho el A. No por
> purismo: porque cuando el Dev Container falle —y va a fallar—, sin el Modo A no tienes con
> qué comparar.

---

## 11. ⚠️ Errores comunes y diagnóstico

**El Dev Container tarda muchísimo la primera vez.** Está instalando VS Code Server y las
extensiones dentro. Es normal la primera vez; si pasa **siempre**, el contenedor se está
recreando en cada apertura.

**`npm install` llena de archivos tu host.** Falta el `mounts` del volumen. §6.1.

**ESLint o Prettier no hacen nada.** La extensión está instalada en el host y no en el
contenedor. §7.

**Los puertos no se abren solos.** Falta `forwardPorts`, o el proceso escucha en `127.0.0.1`
dentro del contenedor — que es [F18](18-networking-de-contenedores.md) §5 otra vez, y `forwardPorts` no lo arregla.

**Archivos con dueño `root` en el host.** Estás en Linux nativo y el contenedor corre como
root. Es [F17](17-usuarios-permisos-y-volumenes.md), y aquí se soluciona igual: `remoteUser` en el JSON, o el usuario en la imagen de
**[a05](a05-non-root-a-fondo.md)**.

**"En la terminal integrada funciona y en una tarea no."** Comprueba que la tarea no lleva un
`docker exec` heredado del Modo A: dentro del Dev Container ya estás en el contenedor, y ese
`docker exec` intentaría hablar con un motor que no está ahí.

**Node responde una versión que no esperabas.** `containerEnv.NODE_VERSION` mal puesto, o el
contenedor se creó antes de que lo cambiaras. Reconstruye el Dev Container desde la paleta.

**Cambié el `devcontainer.json` y no pasa nada.** Hay que reconstruir explícitamente:
*Dev Containers: Rebuild Container*.

---

## 12. 📋 Checklist de validación

```text
[ ] .devcontainer/devcontainer.json existe y apunta a legacy-node-toolchain
[ ] Al abrir el Dev Container, la terminal integrada responde node → v10.24.1
[ ] docker ps desde tu HOST muestra el contenedor que VS Code creó
[ ] node_modules NO aparece en tu host: está en el volumen
[ ] Las extensiones del proyecto aparecen instaladas en el contenedor
[ ] npm ci, test y build funcionan desde la terminal integrada, sin docker exec
[ ] El dev server arranca y VS Code te avisa del puerto
[ ] El debugger de F10 sigue funcionando desde dentro
[ ] git config muestra tu nombre y correo dentro del contenedor
[ ] El socket de Docker NO está montado, y sabes por qué
[ ] Puedes decir qué línea del JSON sustituye a qué opción de docker run
```

---

## 13. 🧪 Ejercicios de la Fase 19 (20)

## 🟢 Fácil — abrir el Dev Container (1–6)

### 🟢 Ejercicio 1 — Tu primer Dev Container

Escribe el `devcontainer.json` de §6 adaptado a tu proyecto y ábrelo.

**Objetivo:** llegar a una terminal integrada que responda `v10.24.1`.

### 🟢 Ejercicio 2 — La terminal cambió de lado

Compara `node --version`, `uname -m` y `pwd` en la terminal del Modo A y en la del Modo B.

**Pregunta:** ¿qué responde cada una? Es la diferencia de §4 en tres comandos.

### 🟢 Ejercicio 3 — El contenedor existe

Con el Dev Container abierto, ejecuta `docker ps` **desde tu host**.

**Pregunta:** ¿qué imagen usa? ¿Qué montajes tiene? Compruébalo con `docker inspect`.

### 🟢 Ejercicio 4 — El volumen hace su trabajo

Ejecuta `npm ci` desde la terminal integrada y mira si aparece `node_modules` en tu host.

**Objetivo:** confirmar que el `mounts` del JSON hace lo mismo que el `--mount` de [F09](09-montar-tu-proyecto.md).

### 🟢 Ejercicio 5 — El puerto se abre solo

Arranca el dev server y observa el aviso de VS Code.

**Pregunta:** ¿en qué puerto del host lo publicó? ¿Coincide con `forwardPorts`?

### 🟢 Ejercicio 6 — Dónde vive cada extensión

Abre el panel de extensiones con el Dev Container activo.

**Objetivo:** identificar las dos secciones de §7 y en cuál está cada una de las tuyas.

## 🟡 Intermedio — configurarlo de verdad (7–13)

### 🟡 Ejercicio 7 — Traduce el JSON a `docker run`

Escribe el `docker run` equivalente a tu `devcontainer.json`, opción por opción.

**Objetivo:** comprobar que no hay magia. Si alguna línea no sabes traducirla, ahí tienes lo
que te falta por entender.

### 🟡 Ejercicio 8 — Cambia la generación de Node

Modifica `containerEnv.NODE_VERSION` a `14.21.3` **sin** cambiar el volumen, reconstruye y
ejecuta la aplicación.

**Objetivo:** provocar el error de ABI de [F14](14-abi-libc-y-prebuilds.md) §5.1 desde el IDE, y arreglarlo cambiando también
el nombre del volumen.

### 🟡 Ejercicio 9 — Sin `mounts`

Quita el volumen del JSON y ejecuta `npm ci`.

**Pregunta:** ¿dónde acabó `node_modules`? ¿Cuánto tardó comparado con el ejercicio 4?

### 🟡 Ejercicio 10 — `runArgs` de verdad

Añade `--memory=512m` a `runArgs` y comprueba con `docker inspect` desde el host.

**Objetivo:** ver que `runArgs` es un pasadizo directo a `docker run`, con todo lo que eso
permite.

### 🟡 Ejercicio 11 — El debugger desde dentro

Configura el `launch.json` para depurar **desde** el Dev Container.

**Pregunta:** ¿qué cambia respecto al de [F10](10-vscode-y-debugging.md)? Pista: `localRoot` y `remoteRoot` dejan de tener
que traducir nada.

### 🟡 Ejercicio 12 — Git dentro

Haz un commit desde la terminal integrada.

**Objetivo:** comprobar el autor con `git log -1 --format='%an <%ae>'` antes de que sea tarde.

### 🟡 Ejercicio 13 — Mide el arranque

Cronometra la primera apertura del Dev Container y la segunda.

**Pregunta:** ¿qué se cachea entre las dos? Si la segunda tarda lo mismo, ¿qué lo estaría
impidiendo?

## 🟠 Difícil — cuando el Modo B esconde el fallo (14–17)

### 🟠 Ejercicio 14 — `postCreateCommand`

Investiga esa clave y úsala para ejecutar `npm ci` automáticamente al crear el contenedor.

**Pregunta:** ¿es buena idea? ¿Qué pasa cuando falla? Justifica si lo dejarías o no.

### 🟠 Ejercicio 15 — Un JSON para cada generación

Crea dos configuraciones —Node 10 y Node 14, cada una con su volumen— y alterna entre ellas.

**Objetivo:** ver que el Dev Container hereda entera la disciplina de [F14](14-abi-libc-y-prebuilds.md), y que el JSON es un
buen sitio para dejarla escrita.

### 🟠 Ejercicio 16 — La tarea heredada

Deja una task del Modo A —con su `docker exec`— y ejecútala dentro del Dev Container.

**Objetivo:** ver el fallo y explicar por qué. Es un error frecuentísimo al migrar de modo.

### 🟠 Ejercicio 17 — El puerto que `forwardPorts` no salva

Configura el dev server para escuchar en `127.0.0.1` dentro del contenedor, con
`forwardPorts` puesto.

**Pregunta:** ¿funciona? ¿Por qué `forwardPorts` no lo arregla? Relaciónalo con [F18](18-networking-de-contenedores.md) §5.

## 🔴 Muy difícil — decidir por el equipo (18–20)

### 🔴 Ejercicio 18 — Modo A contra Modo B como diagnóstico

Rompe algo del proyecto y diagnostícalo primero desde el Modo B y después desde el Modo A.

**Objetivo:** comprobar en qué caso la capa extra del IDE te estorbó, y formular cuándo
conviene bajar al Modo A.

### 🔴 Ejercicio 19 — Justifica cada extensión

Revisa las extensiones que tu equipo tiene instaladas y decide, una a una, si van en el
`devcontainer.json` del proyecto o se quedan como preferencia personal de cada uno.

**Objetivo:** una lista corta y defendible. El criterio es el de §7 —¿necesita leer el código o
ejecutar una herramienta del proyecto?—, y la respuesta honesta suele dejar fuera más de las que
la gente espera.

### 🔴 Ejercicio 20 — El Dev Container de tu equipo

Escribe el `devcontainer.json` definitivo para tu proyecto legacy, con extensiones, settings,
puertos y volumen justificados uno a uno.

**Objetivo:** que un compañero clone el repositorio, abra la carpeta, acepte el aviso, y esté
trabajando en cinco minutos sin preguntarte nada. Escribe también qué **no** pusiste y por qué
— el socket de Docker, por ejemplo.

## 🔥 Opcionales

### 🔥 Ejercicio 21 — `remoteUser` y los permisos

Añade `"remoteUser": "dev"` con el usuario de **[a05](a05-non-root-a-fondo.md)** y comprueba el ownership de los archivos
que crea el IDE.

**Pregunta:** ¿resolvió el problema de [F17](17-usuarios-permisos-y-volumenes.md)? ¿Qué tuviste que preparar antes en el volumen?

### 🔥 Ejercicio 22 — La especificación

Lee la Dev Container Specification y busca tres claves que este curso no usa pero que serían
útiles en tu proyecto.

**Objetivo:** descubrir que es un estándar abierto, no una función de VS Code — y que otras
herramientas lo implementan.

## 💀 Boss fight

### 💀 Ejercicio 23 — Boss fight: el Dev Container que miente

Te dan un proyecto con Dev Container donde: la terminal integrada dice Node 10, pero
`npm run build` falla con un error de sintaxis moderna; el `node_modules` aparece en el host
pese a haber un `mounts` declarado; y las extensiones de lint no marcan nada.

**Objetivo:** los tres problemas son independientes y cada uno tiene su causa —una en el
`PATH` del proceso que lanza npm, otra en la sintaxis del `mounts`, y otra en dónde está
instalada la extensión—. Diagnostícalos **usando el Modo A para comparar**, que es la técnica
que esta fase enseña, y explica en cada caso qué comando descartó las otras hipótesis. Si
resuelves este, un Dev Container deja de ser una caja negra.

---

## 14. 📚 Referencias

**Dev Containers**
- Guía de VS Code: https://code.visualstudio.com/docs/devcontainers/containers
- Referencia de `devcontainer.json`: https://containers.dev/implementors/json_reference/
- La especificación, que es abierta: https://containers.dev
- Extensiones dentro y fuera: https://code.visualstudio.com/api/advanced-topics/remote-extensions
- Credenciales de Git: https://code.visualstudio.com/remote/advancedcontainers/sharing-git-credentials

**Seguridad**
- Por qué montar el socket de Docker es delicado: https://docs.docker.com/engine/security/

> ⚠️ **La documentación de VS Code describe la versión actual del editor**, y las claves de
> `devcontainer.json` han ido creciendo. Las que usa esta fase son estables desde hace años.
> Enlaces revisados el 3 de septiembre de 2026.

**Orden de lectura sugerido:** la referencia de `devcontainer.json` mientras escribes el tuyo,
y el artículo de extensiones remotas si el ejercicio 6 te dejó dudas.

---

## 15. 🏁 Resultado de la fase

```text
NUEVO           .devcontainer/devcontainer.json — versionado en Git

QUÉ AUTOMATIZA  workspaceMount  →  el bind mount de F09
                mounts          →  el named volume, con la generación en el nombre
                containerEnv    →  NODE_VERSION, que leen los shims de F08
                runArgs         →  --platform (F01) y --init (F16)
                forwardPorts    →  los -p de F18, con aviso automático
                customizations  →  extensiones y settings del proyecto

QUÉ NO HACE     no construye otra imagen: reutiliza el toolchain
                no monta el socket de Docker, y sabes por qué
                no arregla un servidor que escucha en 127.0.0.1

EL CRITERIO     Modo A para entender y para diagnosticar
                Modo B para trabajar y para documentar el entorno del equipo
```

> **La señal de que quedó bien:** *"puedo traducir mi `devcontainer.json` a un `docker run`
> línea por línea — y por eso, cuando falla, sé dónde mirar."*

En **[F20](20-validacion-sistematica-y-evidencia.md)** cerramos el bloque de "qué es un contenedor en ejecución" volviendo a la validación:
cómo se investiga un proyecto **antes** de ejecutarlo, y cómo se produce evidencia que sirva.
