# 🐳 Docker Legacy Node — Programa del curso

> **Curso:** Docker Legacy Node — Laboratorio de contenedores para JavaScript legacy
> **Imagen que construyes:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · Node 10.24.1 / 12.22.12 / 14.21.3 / 16.20.2 · npm 6.14.12
> **Arquitecturas:** `linux/amd64` baseline, `linux/arm64` adicional
> **Estructura:** dos partes, 36 fases numeradas y 16 apéndices opcionales
> **Objetivo:** que un proyecto de 2018 vuelva a compilar hoy, y que entiendas por qué

Este documento es el índice y el mapa de rutas. Dice qué hay, en qué orden leerlo y —lo
más útil— **qué puedes saltarte** según a qué viniste.

---

## 1. 🧭 El problema que resuelve

Te dan un repositorio de 2018. Vue 2, o Angular 8, o React 16 con `react-scripts@3`. Le
haces `npm install` en tu MacBook con chip M4 y lo que sale por la terminal es un muro
de errores de `node-gyp` que menciona un Python que ya no existe en tu sistema.

No es tu culpa, y tampoco es exactamente culpa del proyecto. Es que el entorno que ese
código necesita —un Node concreto, un compilador de la época, un Python 2, unas
librerías del sistema— **se extinguió**, y tu sistema operativo moderno no tiene forma
de resucitarlo sin romper otras cosas.

Hay un caso donde esto deja de ser una molestia y pasa a ser un muro: **Node no publicó
binarios `darwin-arm64` hasta la rama 16.x**. En un Mac con Apple Silicon, Node 14, 12 y
10 no se pueden instalar de forma nativa. No existe el archivo. El contenedor deja de
ser una comodidad y pasa a ser el único camino razonable.

La regla que ordena todo el curso, y que conviene tatuarse antes de empezar:

> 🧠 **El contenedor contiene el toolchain, no el proyecto.** Tu código sigue viviendo
> en tu máquina, con tu editor y tu Git. Lo que se mete en la imagen es la maquinaria
> para compilarlo.

---

## 2. 🗺️ Las dos partes

El curso responde dos preguntas distintas, y puedes venir solo a la primera.

```text
"Necesito que este proyecto de 2018 compile hoy."
        → Parte I — Taller.  F00 a F11.  Termina con tu proyecto corriendo.

"¿Por qué funciona esto, y qué hago cuando no funcione?"
        → Parte II — Laboratorio.  F12 a F35.  Termina con criterio para
          diagnosticar solo.
```

**La Parte I se puede tomar sola y es un curso completo.** No es una introducción ni un
resumen: es el camino entero desde una máquina limpia hasta `npm ci`, `build`, `test`,
`start` y el debugger conectado. Lo que no lleva es la explicación de por qué cada pieza
funciona como funciona.

**La Parte II asume la Parte I hecha.** No repite el taller: lo abre por dentro. PID
namespaces, OverlayFS, ABI, QEMU, manifests OCI, rootless, supply chain y forense.

| | Fases | Palabras | Ejercicios | Horas estimadas |
|---|---|---|---|---|
| **[Parte I — Taller](00-PARTE-I-taller.md)** | 12 (F00–F11) | ~51.500 | 255 | ~31 h |
| **[Parte II — Laboratorio](00-PARTE-II-laboratorio.md)** | 24 (F12–F35) | ~117.000 | 595 | ~83 h |
| **Apéndices** | 16 (a01–a16) | ~30.000 | 91 | consulta |

Las horas salen del volumen, no de un cronómetro. Sirven para planificar, no para
prometer.

---

## 3. 🧰 Parte I — Taller: un contenedor para tu proyecto legacy

> 📖 Su documento de entrada, con el recorrido y lo que no entra: [`00-PARTE-I-taller.md`](00-PARTE-I-taller.md)

Al terminar [F11](11-validar-tu-proyecto.md) tienes tu proyecto legacy real —Vue 2, Angular 8, React 16, Svelte 3 o
lo que te hayan dado— instalando, compilando, testeando, corriendo y depurando dentro de
un contenedor, con el código viviendo en tu host.

| Fase | Qué construyes o entiendes |
|---|---|
| **F00** — [El problema y el contrato del laboratorio](00-problema-y-contrato.md) | Por qué el ambiente se perdió, la regla del toolchain, qué plataformas entran y qué queda fuera |
| **F01** — [Decisiones cerradas: Debian, zonas y Node](01-decisiones-debian-zonas-node.md) | Por qué Debian 10 y no 11, 9, Ubuntu o Alpine; las tres zonas; dónde vive `node_modules` |
| **F02** — [Dockerfile: las instrucciones esenciales](02-dockerfile-esencial.md) | `FROM`, `RUN`, `CMD`, `ENTRYPOINT`, `COPY`, `ARG`, `ENV` y tu primer Dockerfile |
| **F03** — [APT y la caja de herramientas](03-apt-y-utilidades.md) | APT sin misterio, los doce paquetes del laboratorio, y por qué un archivo firmado en 2019 todavía funciona |
| **F04** — [Toolchain de compilación](04-toolchain-de-compilacion.md) | Por qué un proyecto JavaScript necesita un compilador de C |
| **F05** — [Python y node-gyp](05-python-y-node-gyp.md) | El traductor entre npm y el mundo nativo, y por qué habla Python 2 |
| **F06** — [Instalar Node: cuatro generaciones](06-instalacion-node.md) | Cuatro versiones EOL conviviendo en una imagen, y el despachador que elige |
| **F07** — [Build: construir la imagen](07-build-de-la-imagen.md) | El build context, `.dockerignore`, el primer build canónico |
| **F08** — [Run: el contenedor como proceso](08-run-el-contenedor-como-proceso.md) | `ENTRYPOINT` y `CMD`, foreground contra detached, `docker exec` |
| **F09** — [Montar tu proyecto: volúmenes y laboratorio](09-montar-tu-proyecto.md) | Bind mounts, named volumes, el Dockerfile canónico y el laboratorio end-to-end |
| **F10** — [VS Code y debugging](10-vscode-y-debugging.md) | El debugger conectado al contenedor, source maps, "IDE roto" vs "proyecto roto" |
| **F11** — [Validar tu proyecto legacy](11-validar-tu-proyecto.md) | El protocolo de validación y el Validation Report que cierra el trabajo |

> 🚧 **Lo que NO entra en la Parte I:** PID namespaces, OverlayFS, ABI, QEMU, registries,
> OCI, Podman comparado, supply chain y forense. Todo eso existe y está escrito; vive en
> la Parte II y se anuncia con su fase exacta cada vez que aparece la tentación.

---

## 4. 🔬 Parte II — Laboratorio: contenedores por dentro

> 📖 Su documento de entrada: [`00-PARTE-II-laboratorio.md`](00-PARTE-II-laboratorio.md)

Aquí se abre cada comodidad que la Parte I te dio hecha.

| Fase | Qué abres |
|---|---|
| **F12** — [Capas, caché y contexto de build](12-capas-cache-y-contexto.md) | Caché de verdad, tags vs IDs vs digests, hasta dónde llega la reproducibilidad |
| **F13** — [OverlayFS y copy-on-write](13-overlayfs-y-copy-on-write.md) | `lowerdir`, `upperdir`, whiteouts y por qué borrar un archivo agranda la imagen |
| **F14** — [ABI, libc y prebuilds](14-abi-libc-y-prebuilds.md) | `NODE_MODULE_VERSION`, glibc vs musl, `node-pre-gyp` |
| **F15** — [Laboratorios de dependencias nativas](15-laboratorios-dependencias-nativas.md) | `node-sass`, `canvas`, `sqlite3`, Puppeteer |
| **F16** — [PID 1, señales y ciclo de vida](16-pid1-senales-y-ciclo-de-vida.md) | Por qué tu app ignora `Ctrl+C` y qué hace `exec "$@"` |
| **F17** — [Usuarios, permisos y volúmenes](17-usuarios-permisos-y-volumenes.md) | Archivos que vuelven del contenedor con dueño equivocado |
| **F18** — [Networking de contenedores](18-networking-de-contenedores.md) | Por qué el contenedor no vive en tu `localhost` |
| **F19** — [Dev Containers](19-dev-containers.md) | El contenedor como ambiente del IDE, y la comparación honesta de los dos caminos |
| **F20** — [Validación sistemática y evidencia](20-validacion-sistematica-y-evidencia.md) | Arqueología controlada, matriz de compatibilidad, método de reducción |
| **F21** — [Arquitecturas, OCI multi-platform y emulación](21-arquitecturas-y-emulacion.md) | Un tag con varias imágenes, QEMU y `binfmt_misc` |
| **F22** — [Apple Silicon y el zoológico de hosts](22-apple-silicon-y-hosts.md) | Dónde ocurre la traducción y quién la administra |
| **F23** — [Estudios de caso y árbol de decisión](23-estudios-de-caso-multiplataforma.md) | `node-sass` y `canvas` en ARM64, microbenchmarks sin vender humo |
| **F24** — [Docker y Podman: dos arquitecturas](24-docker-y-podman-arquitectura.md) | Cliente/daemon vs fork-exec, Buildah frente a BuildKit |
| **F25** — [Rootless y user namespaces](25-rootless-y-user-namespaces.md) | Qué gana y qué cuesta cada modelo, con threat model honesto |
| **F26** — [Portabilidad entre motores](26-portabilidad-entre-motores.md) | Scripts portables y la matriz de decisión |
| **F27** — [Registries por dentro](27-registries-por-dentro.md) | Manifests, indexes, descriptors, blobs y digests |
| **F28** — [Publicar la imagen](28-publicar-la-imagen.md) | Registry local, Docker Hub, publicación multi-platform |
| **F29** — [Supply chain: SBOM, provenance y firma](29-supply-chain-sbom-firma.md) | Qué metiste en la caja y cómo lo demuestras |
| **F30** — [Troubleshooting: método y herramientas](30-troubleshooting-metodo-y-herramientas.md) | Síntoma ≠ causa, hipótesis falsables, una variable a la vez |
| **F31** — [Catálogo de fallos I](31-catalogo-de-fallos-i.md) | Engine, build, registry y red |
| **F32** — [Catálogo de fallos II](32-catalogo-de-fallos-ii.md) | APT, Node, `node-gyp`, ABI y filesystem |
| **F33** — [Forense avanzado y Boss Fight](33-forense-y-boss-fight.md) | Matrices de síntomas y el 💀 de la fase |
| **F34** — [Proyecto final](34-proyecto-final.md) 🏆 | Un repo de 2019 sin instrucciones. El examen del curso |
| **F35** — [Referencias y arqueología técnica](35-referencias.md) | Documento de consulta, no de lectura lineal |

---

## 5. 🎨 Apéndices

Todos **opcionales**. Ninguno es requisito de ninguna fase. Aquí vive lo exhaustivo: el
tratado que se agradece por separado y que dentro de una fase la asfixia.

| | Apéndice | Cuándo abrirlo |
|---|---|---|
| **a01** | [Debian y APT a fondo](a01-debian-y-apt-a-fondo.md) | Cuando quieras entender `sources.list`, `Depends`/`Recommends` y sobrevivir en la shell del contenedor |
| **a02** | [Estrategia Node y CLIs a fondo](a02-estrategia-node-y-clis.md) | Cuando te preguntes por qué no usamos `nvm`, NodeSource ni `FROM node:10` |
| **a03** | [Binutils y anatomía ELF](a03-binutils-y-elf.md) | Cuando `ldd` y `readelf` dejen de ser magia |
| **a04** | [Checksums, GPG y máquinas del tiempo](a04-checksums-gpg-y-archivos.md) | Cuando quieras verificar de verdad lo que descargas |
| **a05** | [Non-root a fondo](a05-non-root-a-fondo.md) | Cuando el baseline como `root` deje de convencerte |
| **a06** | [WebStorm](a06-webstorm.md) | Si tu IDE no es VS Code |
| **a07** | [Colima y Lima](a07-colima-y-lima.md) | Si quieres Docker en macOS sin Docker Desktop |
| **a08** | [Windows 11 y PowerShell](a08-windows-y-powershell.md) | Si tu host es Windows: WSL2, rutas y quoting |
| **a09** | [Browsers legacy: Cypress y Selenium](a09-browsers-legacy.md) | Cuando los tests necesiten un navegador |
| **a10** | [Docker Compose](a10-docker-compose.md) | **Después** de entender `docker run`, para el escenario multi-contenedor |
| **a11** | [GHCR y GitLab Registry](a11-ghcr-y-gitlab.md) | Si publicas fuera de Docker Hub |
| **a12** | [Harbor](a12-harbor.md) | Si tu empresa tiene registry propio |
| **a13** | [Distribución offline / air-gapped](a13-air-gapped.md) | Si la máquina de destino no ve Internet |
| **a14** | [CI con GitHub Actions](a14-ci-github-actions.md) | Cuando quieras automatizar lo que ya sabes hacer a mano |
| **a15** | [Chuleta de comandos](a15-chuleta-de-comandos.md) | Una página imprimible, para tenerla al lado |
| **a16** | [Glosario](a16-glosario.md) | Cuando una sigla te frene |

---

## 6. 🚏 Rutas de lectura por perfil

Nadie necesita las 36 fases. Estas son las rutas que tienen sentido.

### 🔥 "Tengo un proyecto roto y una reunión en dos días"

```text
F00 → F01 → F02 → F03 → F06 → F07 → F08 → F11
```

Ocho fases, ~34.000 palabras. Saltas el toolchain de compilación ([F04](04-toolchain-de-compilacion.md)) y Python ([F05](05-python-y-node-gyp.md))
**solo si tu proyecto no tiene dependencias nativas** — y lo sabrás en [F11](11-validar-tu-proyecto.md), cuando
`npm ci` te lo diga. Si falla ahí, vuelve a F04 y F05, que es exactamente lo que te
faltaba.

### 🎓 "Estoy aprendiendo, quiero el camino completo"

```text
Parte I entera, F00 → F11, en orden.
Después Parte II, F12 → F35, también en orden.
```

Es el orden en que está escrito y en el que cada fase asume la anterior.

### 🧭 "Ya sé Docker, vine por el legacy"

```text
F01 → F03 → F04 → F05 → F06 → F14 → F15 → F20
```

Te saltas el Docker introductorio y vas a lo que este curso tiene y otros no: cuatro
generaciones de Node conviviendo, `node-gyp`, ABI y validación con evidencia.

### 🐧 "Vine por cómo funcionan los contenedores por dentro"

```text
F12 → F13 → F16 → F17 → F18 → F21 → F24 → F25 → F27
```

El recorrido de mecanismo puro: capas, OverlayFS, PID namespaces, user namespaces,
networking, emulación, arquitectura de motores y formato OCI.

### 🍎 "Tengo un Mac con Apple Silicon y todo explota"

```text
F00 §1 → F06 → F21 → F22 → F23 → F14 → F15
```

Empieza por el dato que lo explica todo (Node no publicó `darwin-arm64` antes de la 16)
y sigue por arquitecturas, emulación y dependencias nativas en ARM64.

### 🕵️ "Algo falla y necesito arreglarlo ahora"

```text
F30 §1 (la chuleta de 60 segundos) → F31 o F32 según el síntoma → F33 si se pone feo
```

[F30](30-troubleshooting-metodo-y-herramientas.md) abre con una chuleta pensada exactamente para esto: entrar, encontrar el síntoma,
salir.

---

## 7. 🧪 Cómo están hechos los ejercicios

Cada fase práctica cierra con **entre 20 y 30 ejercicios obligatorios** —calibrados fase por
fase según cuántas cosas distintas se pueden comprobar por separado—, y al menos un tercio son de
diagnóstico: se te entrega algo roto —un `Dockerfile` con las capas en mal orden, un
contenedor sin el bind mount, una imagen construida para la arquitectura equivocada— y
tienes que reproducir, localizar y explicar. Es el músculo que este curso entrena.

| | Nivel | Qué pide |
|---|---|---|
| 🟢 | Fácil | Reconocer y reproducir lo que la fase acaba de mostrar |
| 🟡 | Intermedio | Aplicar el patrón a un caso nuevo |
| 🟠 | Difícil | Combinar patrones, diagnosticar, decidir |
| 🔴 | Muy difícil | Abierto o adversarial |
| 🔥 | Extra | Mini proyectos, fuera del mínimo |
| 💀 | Boss fight | Encadena toda la fase. Uno por fase como máximo |

Cuatro fases no llevan los 20: **[F00](00-problema-y-contrato.md)** y **[F01](01-decisiones-debian-zonas-node.md)** porque son de decisión y ahí el
ejercicio natural es leer un `Dockerfile` ajeno y rebatir una decisión; **[F35](35-referencias.md)** porque es
consulta; y **[F34](34-proyecto-final.md)** por la razón contraria — la fase entera es un ejercicio.

---

## 8. ⚠️ Antes de empezar, tres honestidades

**Esto no es producción.** Construyes sobre Debian 10, que salió de soporte, con un Node
que llegó a EOL hace años y paquetes que ya nadie parchea. Es un laboratorio de
mantenimiento local, y el curso te lo va a recordar cada vez que haga falta. Docker no es
agua bendita. 😄

**Todo va pinneado.** Versiones exactas, digests donde importan, tags que no se mueven. Un
`latest` en el tronco de este curso es un error, no un atajo.

**Los errores se muestran antes de arreglarlos.** Cuando algo falla —`node-gyp`, una
dependencia nativa, un binario que no existe para ARM64— verás el fallo real con su
salida completa, y solo después la corrección. El error editado no enseña.

---

## 9. 📌 Estado del curso

El curso está **completo y navegable**: las 36 fases y los 16 apéndices de este índice
existen, están escritos y se citan entre sí con **enlaces que resuelven** —unos 1.700, todos
comprobados—. Puedes empezar por cualquiera de las seis rutas de §6 sin encontrarte un
documento vacío ni un enlace muerto.

**Qué está medido y qué no.** Ocho documentos llevan en su cabecera una **fecha de verificación
ejecutada**, con la salida real del comando pegada debajo en lugar de un ejemplo:
[F12](12-capas-cache-y-contexto.md), [F13](13-overlayfs-y-copy-on-write.md),
[F14](14-abi-libc-y-prebuilds.md), [F15](15-laboratorios-dependencias-nativas.md),
[F16](16-pid1-senales-y-ciclo-de-vida.md), [F20](20-validacion-sistematica-y-evidencia.md),
[F21](21-arquitecturas-y-emulacion.md) y [F27](27-registries-por-dentro.md). Y lo contrario
también se declara: los comandos `podman` de [F24](24-docker-y-podman-arquitectura.md),
[F25](25-rootless-y-user-namespaces.md) y [F26](26-portabilidad-entre-motores.md) están
contrastados contra la documentación oficial **pero no ejecutados**, y sus cabeceras lo dicen.

Lo que todavía **no** encontrarás son las **soluciones y rúbricas de los ejercicios**. Cada
ejercicio trae su criterio de éxito —una línea `Objetivo:` o una `Pregunta:` que solo se
responde habiéndolo hecho—, y con eso puedes autoevaluarte, pero no hay un solucionario. Es
un pendiente conocido, común a todos los cursos de este repositorio.

> ⚠️ **Lo que sí se mueve bajo tus pies es el mundo exterior.** El baseline del laboratorio
> —Debian 10 Buster, Node 10/12/14/16, npm 6— está fuera de soporte y por eso mismo no
> cambia: `debian/eol:buster` y `https://nodejs.org/dist/` son archivos históricos. Lo que
> sí cambia es la documentación de lo moderno: Docker, Buildx, Podman, los registries y las
> acciones de CI publican versiones nuevas cada pocos meses. Las fases que dependen de esas
> fuentes declaran en su cabecera la **fecha de revisión de documentación externa**; si la
> que lees tiene ya unos meses, verifica el comando contra la documentación del día antes de
> dar por rota una explicación.
