# 🧭 Parte I · Fase 00 — El problema y el contrato del laboratorio

> **Curso:** Docker Legacy Node
> **Imagen que construiremos:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · Node 10.24.1 / 12.22.12 / 14.21.3 / 16.20.2 · npm 6.14.12
> **Arquitectura objetivo:** `linux/amd64` baseline, `linux/arm64` adicional
> **Estado de la imagen al terminar:** ninguna todavía. Esta fase fija el contrato, no construye
> **Fecha de revisión de documentación externa:** 3 de septiembre de 2026
> **Objetivo:** entender qué problema resuelve el laboratorio, con qué regla se ordena, qué plataformas soporta y dónde están sus límites

---

## 1. 🧭 Dónde estamos

En el principio. No hay imagen, no hay `Dockerfile`, no hay nada construido, y eso es
deliberado: antes de escribir la primera línea conviene saber qué estamos intentando
conseguir y —más importante— qué **no**.

Esta fase y la siguiente son las dos únicas del curso en las que no ejecutas casi nada.
Son fases de decisión: fijan el terreno para que las nueve fases siguientes puedan
construir sin volver a discutir los cimientos cada vez.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder responder, sin mirar notas:

- Qué problema concreto resuelve meter un toolchain viejo en un contenedor, y cuál es el
  caso en que deja de ser una comodidad para volverse el único camino.
- Por qué **el contenedor contiene el toolchain y no el proyecto**, y qué consecuencias
  prácticas tiene esa regla.
- Qué motores y plataformas soporta el laboratorio, y cómo lee el curso los ejemplos con
  `docker` cuando tú usas `podman`.
- Qué se considera "proyecto compatible" y con qué lista de comprobaciones se decide.
- Qué queda explícitamente fuera del alcance, para que no lo esperes en la fase 20.

---

## 3. 🔎 El problema: el ambiente se perdió, no el código

Partimos de una situación corriente en mantenimiento de software: **tienes un proyecto
JavaScript de 2017–2020 que todavía funciona, pero el ecosistema que lo rodeaba
envejeció**. El `package.json` menciona Node 10, npm 6, Vue 2 o Angular 8 o React 16,
Webpack 4, TypeScript 3.x, y en algún rincón un módulo nativo que espera un `node-gyp`
que espera un Python 2 que espera un GCC de la época.

El problema, y conviene decirlo pronto, **no suele ser el código fuente**. El código sigue
siendo válido. Lo que se perdió es el ambiente exacto en el que ese código podía instalar
dependencias, compilar, probarse y ejecutarse.

En una máquina de hoy, la propuesta de reconstruirlo en el sistema operativo es
incómoda de entrada:

```mermaid
flowchart LR
    W["Windows 11"] --> N["«Instala Node 10 aquí» 😬"]
    M["macOS actual"] --> N
    A["Apple Silicon"] --> N
    L["Linux moderno"] --> N
```

La estrategia del curso es no pelear esa batalla. El host se queda moderno y limpio; el
entorno viejo se encapsula:

```mermaid
flowchart TD
    subgraph H["HOST MODERNO"]
        ED["editor"]
        GIT["Git"]
        SRC["código fuente"]
    end
    ENG["Docker / Podman"]
    subgraph C["CONTENEDOR LINUX"]
        D10["Debian 10"]
        NL["Node legacy"]
        NPM["npm"]
        PY["Python"]
        CC["compiladores"]
        HA["herramientas auxiliares"]
    end
    H --> ENG --> C
```

### 3.1 🍎 El caso donde el contenedor deja de ser comodidad

Todo lo anterior describe incomodidad: instalar Node 10 en una máquina de 2026 se puede
hacer, es feo, ensucia el sistema y te obliga a convivir con un gestor de versiones más.
Molesto, pero no imposible.

Hay un caso donde deja de ser cuestión de gusto, y conviene ponerlo sobre la mesa antes
que nada porque es probablemente lo que te trajo hasta aquí: **si tu máquina es un Mac con
Apple Silicon, Node 14, 12 y 10 no se pueden instalar de forma nativa. No existen.** No es
que sea difícil ni que haya que compilarlos: el proyecto Node nunca publicó binarios
`darwin-arm64` para esas ramas. El primero que los trae es **Node 16.0.0**, de abril de
2021, y para entonces las tres generaciones que nos interesan ya estaban en mantenimiento
o muertas.

No hace falta creerlo. El propio proyecto publica el listado de artefactos de cada release:

```bash
# ¿qué binarios de macOS publicó cada versión de nuestro baseline?
for v in v10.24.1 v12.22.12 v14.21.3 v16.20.2; do
  echo "== $v"
  curl -s "https://nodejs.org/dist/$v/SHASUMS256.txt" | grep 'darwin.*\.tar\.xz'
done
```

La salida real, verificada el 3 de septiembre de 2026:

```text
== v10.24.1
8edae5060c7513de8e764cdbb61daea5ae652b7a3a457d412a7e08c04e5202da  node-v10.24.1-darwin-x64.tar.xz
== v12.22.12
95799e1276d65b599635f839248d3b3f7d3986873da8f01902a541b9588a6c71  node-v12.22.12-darwin-x64.tar.xz
== v14.21.3
2bc2ecc27a926114827fa26b47ac9bfbd805393a867bedd157b6b052daa20f6e  node-v14.21.3-darwin-x64.tar.xz
== v16.20.2
fb87e01f0b2c8545afb8dd0769f7eb2439fb4fc8731efa956744fb0e0bc98105  node-v16.20.2-darwin-arm64.tar.xz
107ae8d56a9c0aa85c8952231ac44d5e6df7c1ea3e9a36e2ef022ae36c98ccec  node-v16.20.2-darwin-x64.tar.xz
```

Tres versiones con un solo binario de macOS —`darwin-x64`, Intel— y la cuarta con dos. La
línea `darwin-arm64` aparece por primera vez, exactamente, en `v16.0.0`.

> 🧠 **Modelo mental.** En un Mac con chip Apple, "instalar Node 10" no significa instalar
> Node 10: significa **ejecutar un binario Intel bajo Rosetta 2**, con un `nvm` que
> descarga `darwin-x64` porque es lo único que hay. Funciona bastante seguido, pero ya
> estás emulando; la única pregunta que queda es **dónde** quieres que ocurra esa
> traducción y quién la administra.

Y aquí está el giro que ordena el curso entero: ese mismo Node 10 que no existe para macOS
ARM **sí existe para Linux ARM**, y desde hace años.

```bash
curl -s https://nodejs.org/dist/v10.24.1/SHASUMS256.txt | grep 'linux-arm64.*\.tar\.xz'
```

```text
b11ce837867e50d1b2bf09da6a85336bedfa257bf92f34712aeb94360c0bcd6e  node-v10.24.1-linux-arm64.tar.xz
```

La plataforma que te falta en el host la tienes dentro del contenedor, y encima con dos
caminos en vez de uno solo impuesto por el sistema operativo:

```mermaid
flowchart TD
    MAC["Mac Apple Silicon"] --> N1["Node 10 nativo en macOS<br/>❌ no existe darwin-arm64 antes de la 16"]
    MAC --> N2["Node 10 vía Rosetta 2<br/>⚠️ binario Intel, emulación que no controlas"]
    MAC --> CT["contenedor Linux"]
    CT --> A1["Node 10 linux/arm64<br/>✅ binario oficial, nativo en tu CPU"]
    CT --> A2["Node 10 linux/amd64<br/>✅ binario oficial, traducido y aislado"]
```

En Windows, Linux y Mac Intel el contenedor es una decisión de higiene: te ahorra ensuciar
el host y te da reproducibilidad. En Apple Silicon con Node 14 o anterior es, sencillamente,
el único camino razonable.

> ⚠️ **Que esto no te haga sobreestimar el resto.** Que Node exista para `linux/arm64` no
> significa que tu proyecto entero funcione ahí: las dependencias nativas de la época
> publicaron prebuilds para `linux-x64` y poco más, y ese es un problema distinto que el
> curso trata a fondo en **[F14](14-abi-libc-y-prebuilds.md)** y **[F21](21-arquitecturas-y-emulacion.md)**. Lo que este apartado fija es más modesto y más
> importante: **el runtime deja de ser el obstáculo**.

> 📚 Índice de releases y artefactos de Node: https://nodejs.org/dist/ · Notas de la
> 16.0.0, donde aparece el soporte oficial de macOS ARM64:
> https://nodejs.org/en/blog/release/v16.0.0

---

## 4. 🧰 La regla que ordena todo: el contenedor contiene el toolchain, no el proyecto

Esta regla queda fijada desde ahora y no se negocia en ninguna fase posterior:

> 🧭 **El código fuente vive en el host.** La imagen contiene la maquinaria para
> compilarlo, no el material que compila.

Dentro de la imagen van Node y sus amistades 😄: Debian, las cuatro generaciones de Node,
npm, Git, Bash, Python, `node-gyp` cuando corresponda, GCC, G++, `make`, utilidades Linux
y las librerías necesarias para compilar dependencias nativas. Fuera —en tu disco, con tu
editor y tus ramas— se queda el proyecto, y entra al contenedor por un **bind mount**.

La consecuencia práctica es la que hace útil todo el esfuerzo: **no construimos una imagen
distinta cada vez que cambia una línea de Vue o de Angular**. El mismo toolchain sirve para
repositorios distintos, y una imagen que tardó veinte minutos en construirse se amortiza en
todos los proyectos de la época que te caigan encima.

Hay una excepción interesante a la regla, y conviene anticiparla porque desconcierta a
mucha gente: **`node_modules` no vive en ninguno de los dos lados**. Va en un *named
volume*, porque contiene binarios compilados para la arquitectura del contenedor y
mezclarlos con los de tu host es una de las formas más rápidas de perder una tarde. [F01](01-decisiones-debian-zonas-node.md) lo
justifica y [F09](09-montar-tu-proyecto.md) lo monta.

---

## 5. 🖥️ Plataformas y motores soportados

El laboratorio no se casa con un producto. El flujo debe funcionar, con los ajustes que
haga falta, sobre cuatro combinaciones:

**Docker Desktop**, principalmente en Windows y macOS, que es el camino más común y el que
asumen la mayoría de los tutoriales que encontrarás fuera.

**Podman con Podman Desktop**, en Windows, macOS y Linux. No es un anexo simbólico: el
curso lo valida de verdad y le dedica tres fases completas (**[F24](24-docker-y-podman-arquitectura.md)**, **[F25](25-rootless-y-user-namespaces.md)** y **[F26](26-portabilidad-entre-motores.md)**).

**Docker sobre Colima**, especialmente interesante en macOS y Apple Silicon. Colima
proporciona una máquina virtual Linux y ejecuta el runtime de Docker; desde tu terminal,
buena parte del trabajo cotidiano se hace con la CLI de Docker de siempre. El detalle está
en **[a07](a07-colima-y-lima.md)**.

**Docker Engine o Podman directamente en Linux**, donde no hay máquina virtual de por medio
y varias cosas que en macOS son sutiles se vuelven obvias.

### 5.1 ⌨️ Cómo leer los comandos del curso

Para no triplicar cada explicación, la convención editorial es esta: **los ejemplos
principales se escriben con `docker`**, lo que cubre directamente Docker Desktop, Docker
Engine y Docker sobre Colima.

```bash
docker build ...
docker run ...
docker exec ...
docker logs ...
```

Cuando uses Podman, la traducción suele ser literal —cambiar `docker` por `podman`— pero
**el curso no asume que sean lo mismo**:

```bash
podman build ...
podman run ...
podman exec ...
podman logs ...
```

> 🧭 **Regla del curso:** cuando exista una diferencia relevante, se muestra el camino
> `podman` completo y se explica *por qué* difiere —rootless, ausencia de daemon, mapeo de
> usuarios, `--userns=keep-id`, SELinux—, nunca con una nota al pie que diga "en Podman es
> igual". Y si algo no se ha verificado en Podman, el texto lo dice.

> 💡 **Si un término te suena a jerga, no lo adivines.** El apéndice
> [a16](a16-glosario.md) es el glosario del curso: cada entrada define el término, dice
> dónde se explica a fondo y separa los pares que más se confunden —imagen y contenedor,
> tag y digest, `ENTRYPOINT` y `CMD`—. Está pensado para consultarlo a mitad de una fase,
> no para leerlo de corrido.

---

## 6. 🟢 Qué versiones y qué stacks

El laboratorio produce cuatro variantes de Node, que cubren el arco de la época:

| Generación | Versión fijada | Tag de la imagen |
|---|---|---|
| Node 10 | `10.24.1` con npm `6.14.12` | `legacy-node-toolchain:node10` |
| Node 12 | `12.22.12` | `legacy-node-toolchain:node12` |
| Node 14 | `14.21.3` | `legacy-node-toolchain:node14` |
| Node 16 | `16.20.2` | `legacy-node-toolchain:node16` |

**Node 10.24.1 es el baseline** y la prueba de concepto que atraviesa el curso. Cómo se
instalan estas cuatro versiones en una sola imagen, y cómo se elige una en tiempo de
ejecución, es materia de **[F06](06-instalacion-node.md)**.

Con esa base, el toolchain apunta a proyectos construidos sobre Vue 2, Angular 7/8/9,
React 16, las primeras versiones de Svelte, Webpack 3 y 4, Babel, TypeScript 2.x y 3.x,
ESLint y Prettier.

Ojo con lo que eso significa exactamente. **No** significa que una sola imagen garantice
mágicamente que todo paquete publicado entre 2017 y 2020 va a funcionar. Significa que el
toolchain tiene la base necesaria para diagnosticar y resolver la mayor cantidad posible de
esos casos — y que cuando uno no se resuelva, vas a saber decir por qué.

---

## 7. 🏺 Filosofía de compatibilidad, y la honestidad que la acompaña

En este curso no elegimos componentes por ser los más nuevos. Los elegimos por ser
**compatibles con el software que intentamos mantener**. Por eso aceptamos una distribución
Linux fuera de soporte cuando reproduce mejor el entorno de la época, sus paquetes siguen
disponibles en repositorios históricos, reduce fricción con herramientas antiguas y su uso
queda limitado a desarrollo y mantenimiento local.

Esa última condición no es un detalle legal, es la frontera del curso:

> ⚠️ **Una imagen legacy no es una recomendación para producción.** Debian 10 está fuera de
> soporte, Node 10 llegó a EOL en abril de 2021 y varias dependencias que vas a instalar no
> reciben parches desde hace años. Esto es un laboratorio de mantenimiento local.

No vamos a exponer un Debian antiguo a Internet como servidor de negocio y luego decir
"pero está en Docker" como si Docker fuera agua bendita. 😄 El curso te va a recordar esta
condición cada vez que aparezca la tentación de olvidarla.

---

## 8. ✍️ El flujo no depende de tu editor

Todo el laboratorio funciona con una terminal y nada más:

```bash
docker run ...
docker exec ...
npm ci
npm test
npm run build
npm start
```

Eso es deliberado. El editor modifica archivos **en el host**; los comandos de Node se
ejecutan **dentro del contenedor**. Entre los dos hay un bind mount y ninguna magia. Si
trabajas con Vim, Neovim, Notepad++, Sublime Text o un editor que quien escribe esto nunca
ha visto, el flujo es idéntico.

Sobre esa base, el curso añade después dos capas de comodidad, y en este orden: **[F10](10-vscode-y-debugging.md)** te
conecta VS Code y el debugger de Node al contenedor, y **[F19](19-dev-containers.md)** convierte el contenedor en el
ambiente completo del IDE con Dev Containers. Si usas WebStorm, su integración está en
**[a06](a06-webstorm.md)**. Ninguna de las tres es requisito de nada.

---

## 9. 🚧 Qué NO entra: alcance y límites

Lo que este curso no pretende hacer, dicho sin rodeos:

- convertir Debian 10 en una plataforma de producción moderna;
- garantizar soporte de seguridad de dependencias EOL;
- migrar automáticamente tu proyecto a Node moderno, ni reescribirlo;
- enseñar Kubernetes ni Helm;
- empezar por Docker Compose antes de que entiendas `docker run`;
- esconder los problemas detrás de una imagen de terceros que alguien mantiene por ti.

Los dos últimos merecen una aclaración porque suenan a dogma y no lo son. **Compose no es
malo**: es que oculta exactamente los conceptos que esta primera parte quiere enseñar.
Aparece cuando de verdad simplifica un escenario multi-contenedor —el caso natural es
Selenium— y tiene su apéndice propio en **[a10](a10-docker-compose.md)**.

Y las pruebas de navegador, Cypress y Selenium incluidos, son una capacidad adicional del
laboratorio, no parte del camino mínimo. Viven en **[a09](a09-browsers-legacy.md)**, con sus dependencias gráficas y
sus problemas de ARM64.

---

## 10. ✅ Criterios de éxito: cuándo decimos que un proyecto es compatible

Este es el contrato de validación del curso, y lo vas a ejecutar de verdad en **[F11](11-validar-tu-proyecto.md)**. Un
proyecto se considera compatible cuando puedes completar, según lo que tenga declarado:

```text
[ ] montar el código desde el host
[ ] verificar node --version
[ ] verificar npm --version
[ ] ejecutar npm ci
[ ] ejecutar unit tests
[ ] ejecutar lint
[ ] ejecutar build
[ ] ejecutar la aplicación
[ ] acceder desde el host
[ ] depurar con Node Inspector
[ ] repetir el flujo con Docker
[ ] repetir el flujo con Podman
[ ] validar macOS/Apple Silicon
[ ] ejecutar E2E cuando el proyecto lo requiera
```

No todos los proyectos tienen todos esos scripts, y varios te van a fallar en el primer
intento — de eso trata la mitad del curso. Lo importante del patrón es que convierte "creo
que funciona" en una lista que se marca o no se marca.

---

## 11. ⚠️ Errores comunes en esta fase

No hay comandos que romper todavía, pero sí tres malentendidos que se pagan caro después.

**Creer que la imagen incluye el proyecto.** Es el más frecuente y el que genera más
preguntas raras en [F09](09-montar-tu-proyecto.md): *"¿tengo que reconstruir la imagen cada vez que cambio un
archivo?"*. No. El código entra por bind mount y la imagen ni se entera.

**Asumir que Podman es Docker con otro nombre.** Comparten la especificación OCI y buena
parte de la CLI, y eso hace que el 90% de los comandos sean idénticos. El 10% restante
—rootless, permisos de volúmenes, ausencia de daemon— es exactamente donde vas a perder
tiempo si lo asumes. **[F24](24-docker-y-podman-arquitectura.md)** existe para eso.

**Leer "EOL" como "viejo pero equivalente".** Fuera de soporte significa sin parches de
seguridad, con repositorios movidos a un archivo histórico y sin garantía de que la
infraestructura siga en pie. Funciona hoy, y el curso lo verifica; no es lo mismo que estar
mantenido.

---

## 12. 📋 Checklist de validación

Esta fase se valida entendiendo, no ejecutando — con una excepción, que es el comando que
sostiene el argumento central:

```text
[ ] Puedes explicar por qué el código vive en el host y no en la imagen
[ ] Sabes en qué caso el contenedor deja de ser comodidad y pasa a ser el único camino
[ ] Ejecutaste el curl de §3.1 y viste con tus ojos que no hay darwin-arm64 antes de la 16
[ ] Sabes qué motor vas a usar y en qué plataforma
[ ] Entiendes la convención docker/podman de los ejemplos
[ ] Puedes enumerar las cuatro versiones de Node del baseline y su tag
[ ] Sabes decir tres cosas que el curso NO va a hacer
[ ] Tienes localizado tu proyecto legacy real, para trabajarlo en paralelo
```

---

## 13. 🧪 Ejercicios de la Fase 00 (4)

> 🧭 **Fase exenta del mínimo de 20.** F00 es una fase de decisión: no construye nada, así
> que su ejercicio natural no es ejecutar sino leer, decidir y rebatir. Los cuatro que
> siguen son de ese tipo y no cuentan para el mínimo del curso.

### 🟢 Ejercicio 1 — Verifica el argumento en lugar de creerlo

Ejecuta el bucle de §3.1 sobre las cuatro versiones del baseline y después repítelo sobre
`v15.14.0` y `v16.0.0`.

**Pregunta:** ¿en cuál de las dos aparece por primera vez `darwin-arm64`, y qué implica eso
para alguien que hoy intente levantar un proyecto de Angular 8 en un MacBook M4?

### 🟡 Ejercicio 2 — Sitúa tu propio caso

Abre el `package.json` del proyecto legacy que te trajo aquí y localiza tres cosas: el
campo `engines` si existe, la versión del framework principal, y cualquier dependencia con
`node-gyp`, `node-sass`, `canvas` o `sqlite3` en el nombre.

**Objetivo:** saber, antes de construir nada, en qué generación de Node cae tu proyecto y si
va a necesitar el toolchain de compilación de [F04](04-toolchain-de-compilacion.md) y [F05](05-python-y-node-gyp.md) — o si vas a poder saltártelas.

### 🟠 Ejercicio 3 — Rebate una decisión ajena

Este `Dockerfile` circula en tutoriales de proyectos legacy:

```dockerfile
FROM node:10
WORKDIR /app
COPY . .
RUN npm install
CMD ["npm", "start"]
```

**Pregunta:** enumera las cuatro decisiones que contradicen el contrato que acaba de fijar
esta fase, y para cada una di qué problema concreto va a causar. Pista: mira el tag, mira
qué se copia dentro de la imagen, mira el comando de instalación y mira qué falta para que
esto sea reproducible dentro de seis meses.

### 🟠 Ejercicio 4 — Defiende la decisión incómoda

Un compañero revisa el plan del curso y objeta: *"usar Debian 10, que está fuera de
soporte, es una irresponsabilidad; usemos Debian 12 y ya"*.

**Objetivo:** construir la respuesta honesta, que no es "no tienes razón". Tiene que incluir
en qué tiene razón, cuál es la condición bajo la cual la decisión es aceptable, y qué
tendría que cambiar en el proyecto para que su objeción pasara a ser correcta.

---

## 14. 📚 Referencias

**Node.js y sus artefactos**
- Índice de releases y binarios publicados: https://nodejs.org/dist/
- Notas de la v16.0.0, con el soporte oficial de macOS ARM64: https://nodejs.org/en/blog/release/v16.0.0
- Calendario de releases y fechas de EOL: https://github.com/nodejs/Release

**Motores de contenedores**
- Docker — Bind mounts: https://docs.docker.com/engine/storage/bind-mounts/
- Podman — `podman run`: https://docs.podman.io/en/latest/markdown/podman-run.1.html
- Podman Desktop — compatibilidad con Docker: https://podman-desktop.io/docs/migrating-from-docker/managing-docker-compatibility
- Colima — preguntas frecuentes: https://github.com/abiosoft/colima/blob/main/docs/FAQ.md

> ⚠️ **La documentación oficial de hoy no describe el software de 2018.** Los enlaces de
> Docker y Podman apuntan a versiones muy posteriores a las que usaban los proyectos que
> vas a revivir. Sirven para entender los mecanismos, no para saber cómo se comportaba la
> herramienta en la época.

**Orden de lectura sugerido:** el índice de `nodejs.org/dist` primero, porque es el que
sostiene el argumento de §3.1 y se comprueba en dos minutos. El resto, cuando la fase
correspondiente los pida.

---

## 15. 🏁 Resultado de la fase

No hay imagen todavía. Lo que queda fijado es el contrato:

```text
Código          host, siempre
node_modules    named volume, nunca compartido con el host
Runtime         contenedor Linux
Base            Debian 10 Buster (debian/eol:buster) — EOL, declarado
Node            10.24.1 / 12.22.12 / 14.21.3 / 16.20.2
Motores         Docker Desktop · Podman Desktop · Docker sobre Colima
                Docker Engine o Podman en Linux
Arquitectura    linux/amd64 baseline · linux/arm64 adicional
Editores        cualquiera por consola · VS Code (F10) · WebStorm (a06)
Testing         unitario dentro del contenedor
                E2E y navegador como capacidad adicional (a09)
Uso             desarrollo y mantenimiento local — NO producción
```

> **La señal de que quedó bien:** *"puedo explicarle a alguien, en dos minutos y sin
> abrir la terminal, por qué mi código no va dentro de la imagen y qué gano con eso."*

En **[F01](01-decisiones-debian-zonas-node.md)** cerramos las decisiones que sostienen ese contrato: por qué Debian 10 y no otra,
qué son exactamente las tres zonas del laboratorio, y por qué las CLIs de framework
pertenecen al proyecto y no a la imagen.
