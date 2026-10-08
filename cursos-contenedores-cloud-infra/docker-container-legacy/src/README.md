# 📦 `src/` — el código ejecutable del curso

Todo lo que el curso te pide **copiar y ejecutar tal cual** vive aquí como archivo de verdad,
no solo dentro de un bloque de código del `.md`. La regla que lo gobierna está en la guía de
estilo §5.1: *si cambia el archivo, cambia el `.md`, y al revés.*

Un subdirectorio por fase, con **el mismo nombre del documento**. Solo existen las fases que
tienen código; las conceptuales no aparecen.

---

## Cómo se usa

Los Dockerfiles y los scripts asumen que estás en la **raíz del laboratorio** que el curso te
hace construir —el directorio con `dockerfiles/`, `scripts/` y tu proyecto—, no dentro de
`src/`. La estructura interna de cada carpeta reproduce esa raíz, así que copiar es directo:

```bash
# desde la raíz de tu laboratorio
cp -r ruta/al/curso/src/06-instalacion-node/. .
docker build --platform linux/amd64 -f dockerfiles/05-node.Dockerfile -t legacy-node-toolchain:phase06 .
```

---

## Índice

| Fase | Qué hay | Documento |
|---|---|---|
| **02** | `dockerfiles/01-hola-mundo.Dockerfile` | [F02](../02-dockerfile-esencial.md) |
| **03** | `dockerfiles/02-utilidades.Dockerfile` | [F03](../03-apt-y-utilidades.md) |
| **04** | `dockerfiles/03-toolchain.Dockerfile`, `hello.c`, `Makefile` | [F04](../04-toolchain-de-compilacion.md) |
| **05** | `dockerfiles/04-python-node-gyp.Dockerfile` | [F05](../05-python-y-node-gyp.md) |
| **06** | `dockerfiles/05-node.Dockerfile`, `scripts/select-node` | [F06](../06-instalacion-node.md) |
| **07** | `Dockerfile` **canónico**, `.dockerignore`, `dockerfiles/06-build.Dockerfile` | [F07](../07-build-de-la-imagen.md) |
| **08** | `Dockerfile` canónico con entrypoint, `scripts/docker-entrypoint.sh`, `scripts/legacy-node-command` | [F08](../08-run-el-contenedor-como-proceso.md) |
| **09** | `scripts/run-dev.sh` | [F09](../09-montar-tu-proyecto.md) |
| **10** | `.vscode/tasks.json`, `.vscode/launch.json` | [F10](../10-vscode-y-debugging.md) |
| **11** | los **cinco fixtures** (`00-node-smoke`, `10-vue2-min`, `20-angular8-min`, `30-react16-min`, `40-svelte3-min`) y `VALIDATION-REPORT.template.md` | [F11](../11-validar-tu-proyecto.md) |
| **15** | `dockerfiles/07-native-dependencies.Dockerfile` | [F15](../15-laboratorios-dependencias-nativas.md) |
| **16** | `server.js` — el servidor que **sí** maneja `SIGTERM` y cierra ordenado | [F16](../16-pid1-senales-y-ciclo-de-vida.md) |
| **19** | `.devcontainer/devcontainer.json` | [F19](../19-dev-containers.md) |
| **21** | `dockerfiles/08-multiarch.Dockerfile` | [F21](../21-arquitecturas-y-emulacion.md) |
| **26** | `scripts/engine.sh` — la capa fina sobre Docker o Podman | [F26](../26-portabilidad-entre-motores.md) |
| **30** | `dockerfiles/09-diagnostic.Dockerfile`, `30-diagnose-container.sh`, `30-TROUBLESHOOTING-REPORT.md` | [F30](../30-troubleshooting-metodo-y-herramientas.md) |
| **a10** | `compose.yaml`, `compose.e2e.yaml` | [a10](../a10-docker-compose.md) |
| **a14** | `.github/workflows/toolchain.yml` | [a14](../a14-ci-github-actions.md) |

---

## Los cinco fixtures, y sus omisiones deliberadas

`11-validar-tu-proyecto/` trae cinco proyectos mínimos con su `package-lock.json` congelado.
Dos cosas de ellos son decisiones y no descuidos, y conviene decirlo aquí antes de que alguien
las "arregle":

**Solo `00-node-smoke` declara `engines`.** Los cuatro de framework no lo llevan, igual que la
mayoría de los proyectos reales de 2018 — y eso es justo lo que los hace útiles. Sin `engines`
hay que **datar el proyecto por otras vías**: el `lockfileVersion`, las fechas de publicación de
sus dependencias, la sintaxis del código. Es el trabajo que piden
[F20](../20-validacion-sistematica-y-evidencia.md) §5 y el ejercicio de
[F06](../06-instalacion-node.md) titulado *"El proyecto que no dice qué Node quiere"*. Si les
añades `engines`, esos ejercicios dejan de tener sentido.

**`00-node-smoke` es el fixture de control y por eso no tiene dependencias.** Su `package-lock`
declara `lockfileVersion: 1` con cero entradas. No prueba la resolución de dependencias ni los
addons nativos: prueba que **el laboratorio funciona** —la imagen arranca, el shim de
`NODE_VERSION` conmuta, el bind mount monta y el volumen no estorba—. Es el fusible de
[F11](../11-validar-tu-proyecto.md) §5.1 y la matriz medida de
[F20](../20-validacion-sistematica-y-evidencia.md) §7.1.

> 🩺 **Y el `dist/` que el `start` de `00-node-smoke` invoca no está en el repositorio a
> propósito.** Lo produce `npm run build`; si haces `npm start` sin construir antes, obtienes un
> `MODULE_NOT_FOUND` — que es exactamente el nivel 4 contra el nivel 5 de los siete niveles de
> F11 §4, y un buen recordatorio de que el orden del protocolo no es decorativo.

---

## `all-dockerfiles/`

Copia consolidada de los **once Dockerfiles** del curso, para leerlos seguidos sin recorrer
dieciocho carpetas. La duplicación es deliberada: son archivos de decenas de líneas y sirven
para ver el laboratorio crecer de un vistazo.

```text
01-hola-mundo             F02   seis líneas: FROM, LABEL, CMD
02-utilidades             F03   + APT y las herramientas de supervivencia
03-toolchain              F04   + compilador, make, binutils
04-python-node-gyp        F05   + Python 2 y 3
05-node                   F06   + las cuatro ramas de Node y select-node
06-build                  F07   el pedagógico de F07 (idéntico a 05)
07-native-dependencies    F15   + Cairo, sqlite3 y las librerías de Chromium
08-multiarch              F21   el RUN de Node traducido a TARGETARCH
09-diagnostic             F30   imagen SEPARADA, solo herramientas de diagnóstico
10-canonico-f07           F07   ◀ el canónico, donde NACE: en la raíz del laboratorio
11-canonico-f08           F08   el canónico con entrypoint y shims
```

> 🧠 **Los dos canónicos son el hilo que hay que seguir.** El `Dockerfile` de la raíz del
> laboratorio —el que de verdad usas— nace en **F07** y cambia en **F08**; los nueve numerados
> son escalones pedagógicos que se acumulan y no se borran. `10-canonico-f07` es byte a byte
> igual que `06-build`, y eso **es** la lección de F07 §7: la fase promueve el pedagógico a
> canónico sin tocarle una línea, y lo que cambia es dónde vive y cómo se construye. Si lees el
> directorio de un tirón y saltas del `09` al `11`, te pierdes ese paso.

> 📝 **Cuatro de ellos están compuestos.** En F15, F21 y los dos canónicos, el `.md` muestra
> solo el fragmento que cambia —es lo correcto para leer, porque lo demás ya lo viste—. Aquí
> están completos y construibles, con una cabecera de tres líneas que lo declara. Los otros
> siete son copia literal del bloque de su fase.

---

## Lo que todavía no está aquí

Las **soluciones de los ejercicios** no viven en `src/` y es una decisión, no un olvido: el
curso da criterio de éxito verificable en cada ejercicio —un comando que devuelve algo
concreto— y esa es la corrección. Los scripts que los ejercicios te piden escribir son tuyos.
