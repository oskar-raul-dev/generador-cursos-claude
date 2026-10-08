# 📚 Parte II · Fase 35 — Referencias: la biblioteca del arqueólogo de Node legacy

> **Curso:** Docker Legacy Node  
> **Imagen canónica:** `legacy-node-toolchain`  
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) + Node.js 10/12/14/16  
> **Motores:** Docker como referencia didáctica; Podman como alternativa estudiada  
> **Fecha de revisión editorial y verificación web de fuentes centrales:** **3 de septiembre de 2026**  
> **Requisitos:** ninguno. **Es un documento de consulta, no de lectura lineal**
> **Objetivo:** consolidar la bibliografía técnica del curso, enseñar a distinguir fuentes primarias, históricas y comunitarias, y dejar un mapa reutilizable para investigar software legacy sin confundir documentación moderna con evidencia histórica.
>
> 🧭 **Cómo se usa esta fase.** Nadie la lee de corrido, y no hace falta. Ve a §7 si quieres las
> veinticinco imprescindibles, a §8 si quieres una ruta guiada, a §14 si buscas las fuentes de
> una fase concreta, y a §15 si tienes una fuente y quieres saber dónde se usa.

---

## 1. 🧭 Dónde estamos

Llegamos a la última fase prevista del syllabus. Durante [F00](00-problema-y-contrato.md)–[F34](34-proyecto-final.md) fuimos agregando referencias al final de cada capítulo: Docker, Debian, Node, npm, `node-gyp`, GNU, VS Code, Podman, OCI, registries, supply chain, troubleshooting y bastante arqueología de software.

Ahora hacemos algo distinto: **las consolidamos, las clasificamos y aprendemos a usarlas**.

Esta fase NO intenta que memorices 500 URLs. Eso sería una estrategia pedagógica excelente si nuestro objetivo fuera odiar Internet. 😄

Queremos que puedas responder preguntas como:

```text
¿qué fuente tiene autoridad para este dato?
¿necesito documentación actual o histórica?
¿el README actual describe la versión que realmente tengo instalada?
¿este issue es evidencia o solo una anécdota?
¿qué release cambió el comportamiento?
¿dónde estaba la documentación en 2019?
¿cómo preservo una referencia que puede desaparecer?
```

La idea central de F35 es simple:

> **en mantenimiento legacy, saber encontrar la fuente correcta es parte del toolchain.**

---

## 2. 🎯 Objetivos de esta fase

- distinguir fuente primaria, secundaria y comunitaria;
- distinguir documentación actual de documentación histórica;
- comprender por qué una documentación técnicamente correcta puede ser incorrecta para nuestra versión;
- usar tags, releases, changelogs y commits como evidencia;
- usar Debian Archive, Debian Snapshot y Wayback Machine como herramientas de arqueología;
- evaluar un blog o video sin aceptar sus comandos por fe;
- usar Stack Overflow y GitHub Issues como pistas, no como tablas de la ley;
- localizar matrices de compatibilidad de Node, npm, ABI, Python y frameworks;
- conservar fecha, versión, tag, commit y digest junto con una referencia;
- clasificar fuentes por autoridad, estabilidad y profundidad;
- tener una ruta de lectura para principiante, intermedio y full geek;
- localizar rápidamente las fuentes principales de cualquier fase [F00](00-problema-y-contrato.md)–[F34](34-proyecto-final.md);
- usar una bibliografía técnica como herramienta de troubleshooting y no como decoración académica;
- documentar fuentes dinámicas que deben revisarse periódicamente;
- identificar fuentes de seguridad y advisories para componentes EOL;
- construir una matriz propia de evidencia para un proyecto legacy desconocido.

---

## 3. 🧾 Cómo leer las marcas de esta bibliografía

### 3.1 Autoridad de la fuente

| Marca | Tipo | Cómo la usamos |
|---|---|---|
| 🥇 | documentación / especificación oficial | primera parada para comportamiento, flags, compatibilidad y contratos |
| 🥈 | repositorio oficial / código fuente / release | evidencia primaria excelente cuando la documentación ya no existe o cambió |
| 🥉 | archivo histórico / snapshot | evidencia temporal; especialmente valiosa en software EOL |
| 📚 | libro técnico | profundidad y modelo mental; puede envejecer en detalles operativos |
| 🎓 | curso / material formativo | aprendizaje guiado; siempre contrastar flags con docs actuales |
| 🎥 | video / conferencia | intuición y contexto; la edad importa mucho |
| 📝 | artículo / tutorial | útil como explicación secundaria; verificar contra fuentes primarias |
| 💬 | issue, foro, Stack Overflow | evidencia contextual; puede revelar bugs reales, pero no constituye especificación |

### 3.2 Estabilidad temporal

| Marca | Significado |
|---|---|
| 🧱 | cambia lentamente; especificaciones, conceptos Unix, manuales estables |
| ⚡ | cambia rápido; Docker Desktop, Podman Machine, IDEs, registries, precios, CI |
| 🏺 | histórica; queremos exactamente esa versión vieja |

### 3.3 Profundidad

| Nivel | Uso |
|---|---|
| ⭐⭐⭐⭐⭐ | esencial o full geek de alto valor |
| ⭐⭐⭐⭐ | recomendado para dominar el tema |
| ⭐⭐⭐ | complemento práctico |
| ⭐⭐ | referencia secundaria / contextual |
| ⭐ | curiosidad o extensión |

Las fases se muestran al final de cada referencia como, por ejemplo: `(F05, F14, F30)`.

---

## 4. 🥇 Jerarquía de evidencia: ¿a quién le creemos?

Supón que un blog de 2026 dice:

> “`node-gyp` requiere Python 3”.

Eso puede ser correcto **hoy** y aun así ser una mala respuesta para un proyecto de 2018 que trae una copia antigua de `node-gyp`. La pregunta correcta no es “¿qué requiere node-gyp?”, sino:

```text
¿qué versión exacta de node-gyp está ejecutando este npm/paquete?
¿qué decía ESA versión?
```

En el changelog histórico de `node-gyp` podemos rastrear cuándo se añadió/normalizó soporte para Python 3. Ese dato es mucho más útil que aplicar el README de 2026 hacia atrás como si el tiempo no existiera.

### 4.1 Orden de preferencia práctico

```text
1. especificación / documentación de la versión exacta
2. release, tag, changelog o código de la versión exacta
3. documentación oficial actual que explique historia/migraciones
4. issue oficial con mantenedores y contexto reproducible
5. libro / curso / artículo técnico sólido
6. Stack Overflow / foro / Reddit / blog personal
7. “un tipo dijo que borres package-lock.json y hagas npm install”
```

El punto 7 es una fuente de energía renovable para nuevas incidencias. 😄

### 4.2 Un issue puede ser mejor que la documentación… para una pregunta distinta

La documentación describe el comportamiento soportado o esperado. Un issue puede describir:

- un bug concreto;
- una incompatibilidad con una arquitectura;
- una URL que murió;
- una combinación no soportada;
- un workaround temporal;
- la explicación de un maintainer.

Eso lo vuelve muy valioso, pero debes registrar:

```text
fecha
versión
sistema operativo
arquitectura
commit/tag
quién respondió
si el issue terminó fixed / wontfix / duplicate / stale
```

---

### 4.3 Cómo citar un issue, PR o respuesta comunitaria sin convertirla en dogma

Cuando un issue aporta una pieza importante, no guardes solo el enlace. Registra el contexto mínimo:

```text
proyecto / repositorio
issue o PR
fecha
versión afectada
arquitectura / OS
mensaje exacto o conclusión resumida
autor: maintainer, contributor o usuario
estado: open / fixed / wontfix / duplicate / stale
release o commit que introdujo/corrigió el cambio, si existe
```

Una respuesta con veinte votos puede ser útil. Un comentario de un maintainer con un commit enlazado suele ser evidencia mucho más fuerte. Y un comentario de 2017 puede ser exactamente lo que necesitas para un paquete de 2017, aunque hoy parezca arqueología egipcia con npm. 😄

---

## 5. 🏺 Arqueología técnica: cómo investigar software que el presente ya olvidó

Un proyecto legacy puede depender de artefactos de cuatro épocas distintas:

```text
código de 2018
lockfile de 2019
imagen Linux de 2020
host de 2026
```

La investigación debe reconstruir esa línea temporal.

### 5.1 Las cinco máquinas del tiempo

### A. Tags y releases Git

Busca la versión exacta del paquete, no solamente `main`.

### B. Changelog

Busca el momento donde se añadió, eliminó o cambió soporte para Node, Python, arquitectura o plataforma.

### C. Debian Archive / Sources / Snapshot

Permiten reconstruir el sistema operativo y los paquetes de una fecha concreta.

### D. Node Download Archive

Conserva releases EOL, binarios por arquitectura, checksums y material de verificación.

### E. Wayback Machine

Cuando la documentación desapareció, cambió de dominio o el README fue reescrito.

### 5.2 Regla de oro

> **No preguntes solamente “¿qué dice la documentación?”. Pregunta “¿qué decía la documentación para esta versión y en esta época?”.**

---

## 6. 🧪 Cómo evaluar un tutorial externo sin morir por copy/paste

Antes de pegar un comando de un blog, video o respuesta de Stack Overflow, revisa:

- fecha de publicación y última actualización;
- versiones exactas usadas;
- host/OS/arquitectura;
- Docker o Podman y versión;
- si usa una opción deprecada;
- si modifica `package-lock.json`;
- si desactiva TLS (`strict-ssl=false`, `-k`, etc.);
- si propone `chmod -R 777` como medicina universal;
- si hace `curl ... | sudo bash` sin explicar origen ni integridad;
- si mezcla solución de reproducción con modernización;
- si el autor enlaza documentación primaria;
- si los comentarios reportan que dejó de funcionar;
- si el resultado es reproducible desde un entorno limpio;

### 🚩 Señales de humo

```text
“borra package-lock.json”
“usa npm latest”
“desactiva SSL”
“corre privileged”
“chmod 777 y listo”
“instala Rosetta/QEMU porque sí”
“Docker y Podman son iguales”
```

Cada una puede tener un caso válido. La frase peligrosa es **“porque sí”**.

---

## 7. ⭐ Top 25 — referencias que conviene tener a mano

1. **Dockerfile reference** — https://docs.docker.com/reference/dockerfile/ ([F02](02-dockerfile-esencial.md), [F07](07-build-de-la-imagen.md), [F30](30-troubleshooting-metodo-y-herramientas.md))
2. **docker container run** — https://docs.docker.com/reference/cli/docker/container/run/ ([F08](08-run-el-contenedor-como-proceso.md), [F11](11-validar-tu-proyecto.md), [F10](10-vscode-y-debugging.md), [F30](30-troubleshooting-metodo-y-herramientas.md))
3. **Docker Build** — https://docs.docker.com/build/ ([F02](02-dockerfile-esencial.md), [F07](07-build-de-la-imagen.md), [F21](21-arquitecturas-y-emulacion.md), [F27](27-registries-por-dentro.md), [F30](30-troubleshooting-metodo-y-herramientas.md))
4. **Debian 10 Buster** — https://www.debian.org/releases/buster/ ([F01](01-decisiones-debian-zonas-node.md), [F03](03-apt-y-utilidades.md), [F21](21-arquitecturas-y-emulacion.md))
5. **Debian Snapshot** — https://snapshot.debian.org/ ([F01](01-decisiones-debian-zonas-node.md), [F03](03-apt-y-utilidades.md), [F30](30-troubleshooting-metodo-y-herramientas.md))
6. **Debian Sources** — https://sources.debian.org/ ([F03](03-apt-y-utilidades.md), [F04](04-toolchain-de-compilacion.md), [F05](05-python-y-node-gyp.md), [F14](14-abi-libc-y-prebuilds.md))
7. **Node.js previous releases** — https://nodejs.org/en/about/previous-releases ([F01](01-decisiones-debian-zonas-node.md), [F06](06-instalacion-node.md), [F14](14-abi-libc-y-prebuilds.md), [F21](21-arquitecturas-y-emulacion.md))
8. **Node.js 10.24.1 archive** — https://nodejs.org/en/download/archive/v10.24.1 ([F01](01-decisiones-debian-zonas-node.md), [F06](06-instalacion-node.md), [F14](14-abi-libc-y-prebuilds.md), [F21](21-arquitecturas-y-emulacion.md))
9. **npm 6 — npm ci** — https://docs.npmjs.com/cli/v6/commands/npm-ci/ ([F01](01-decisiones-debian-zonas-node.md), [F11](11-validar-tu-proyecto.md), [F30](30-troubleshooting-metodo-y-herramientas.md))
10. **node-gyp** — https://github.com/nodejs/node-gyp ([F05](05-python-y-node-gyp.md), [F06](06-instalacion-node.md), [F14](14-abi-libc-y-prebuilds.md), [F30](30-troubleshooting-metodo-y-herramientas.md))
11. **GNU Bash Manual** — https://www.gnu.org/software/bash/manual/ ([F03](03-apt-y-utilidades.md), [F08](08-run-el-contenedor-como-proceso.md), [F30](30-troubleshooting-metodo-y-herramientas.md))
12. **GNU Make Manual** — https://www.gnu.org/software/make/manual/ ([F04](04-toolchain-de-compilacion.md), [F05](05-python-y-node-gyp.md), [F14](14-abi-libc-y-prebuilds.md))
13. **Linux man-pages** — https://man7.org/linux/man-pages/ ([F08](08-run-el-contenedor-como-proceso.md), [F30](30-troubleshooting-metodo-y-herramientas.md))
14. **OCI Image Specification** — https://specs.opencontainers.org/image-spec/ ([F02](02-dockerfile-esencial.md), [F07](07-build-de-la-imagen.md), [F21](21-arquitecturas-y-emulacion.md), [F24](24-docker-y-podman-arquitectura.md), [F27](27-registries-por-dentro.md))
15. **OCI Runtime Specification** — https://specs.opencontainers.org/runtime-spec/ ([F08](08-run-el-contenedor-como-proceso.md), [F24](24-docker-y-podman-arquitectura.md), [F30](30-troubleshooting-metodo-y-herramientas.md))
16. **Podman documentation** — https://docs.podman.io/ ([F07](07-build-de-la-imagen.md), [F08](08-run-el-contenedor-como-proceso.md), [F21](21-arquitecturas-y-emulacion.md), [F24](24-docker-y-podman-arquitectura.md), [F30](30-troubleshooting-metodo-y-herramientas.md))
17. **Dev Container Specification** — https://containers.dev/ ([F10](10-vscode-y-debugging.md), [F24](24-docker-y-podman-arquitectura.md))
18. **Docker multi-platform builds** — https://docs.docker.com/build/building/multi-platform/ ([F21](21-arquitecturas-y-emulacion.md), [F27](27-registries-por-dentro.md), [F30](30-troubleshooting-metodo-y-herramientas.md))
19. **CNCF Distribution** — https://distribution.github.io/distribution/about/ ([F27](27-registries-por-dentro.md))
20. **Sigstore Cosign** — https://docs.sigstore.dev/cosign/signing/signing_with_containers/ ([F27](27-registries-por-dentro.md), [F30](30-troubleshooting-metodo-y-herramientas.md))
21. **Git bisect** — https://git-scm.com/docs/git-bisect ([F11](11-validar-tu-proyecto.md), [F30](30-troubleshooting-metodo-y-herramientas.md))
22. **curl documentation** — https://curl.se/docs/ ([F03](03-apt-y-utilidades.md), [F30](30-troubleshooting-metodo-y-herramientas.md))
23. **strace manual** — https://man7.org/linux/man-pages/man1/strace.1.html ([F30](30-troubleshooting-metodo-y-herramientas.md))
24. **Wayback Machine** — https://archivesupport.zendesk.com/hc/en-us/articles/360004651732-Using-The-Wayback-Machine (F35)
25. **The Linux Programming Interface** — https://www.man7.org/tlpi/index.html ([F08](08-run-el-contenedor-como-proceso.md), [F30](30-troubleshooting-metodo-y-herramientas.md), F35)

---

## 8. 🗺️ Rutas de lectura

## Ruta A — “Solo quiero usar el laboratorio sin romperlo”

1. Dockerfile reference
2. docker container run
3. Bind mounts
4. Volumes
5. Node.js 10.24.1 — Download Archive
6. npm 6 — npm ci
7. Debian 10 Buster — información de release
8. Docker Desktop troubleshooting

## Ruta B — “Quiero entender qué está pasando”

1. How Linux Works, 3rd Edition
2. Docker Deep Dive, 5th Edition
3. OCI Image Specification
4. OCI Runtime Specification
5. GNU Bash Manual
6. node-gyp — repositorio y documentación
7. Dev Container Specification
8. Podman documentation

## Ruta C — “Quiero ser arqueólogo senior y asustar a los bugs”

1. Debian Snapshot
2. Wayback Machine — guía de uso
3. The Linux Programming Interface
4. Systems Performance, 2nd Edition
5. GNU Binutils Documentation
6. strace manual
7. OCI Distribution Specification
8. Cosign — signing containers
9. Git — git bisect

---

## 9. 📚 Bibliografía técnica comentada por tema

### 9.1 Arqueología técnica y evaluación de fuentes

- 🥇🏺 ⭐⭐⭐⭐⭐ **Debian Snapshot** — https://snapshot.debian.org/ ([F01](01-decisiones-debian-zonas-node.md), [F03](03-apt-y-utilidades.md), [F30](30-troubleshooting-metodo-y-herramientas.md), F35)
  - **Para qué sirve:** Permite localizar paquetes Debian por fecha y versión; es una máquina del tiempo de paquetes, no una metáfora bonita.
  - **Temporalidad:** Histórica/estable
- 🥇🏺 ⭐⭐⭐⭐⭐ **Wayback Machine — guía de uso** — https://archivesupport.zendesk.com/hc/en-us/articles/360004651732-Using-The-Wayback-Machine (F35)
  - **Para qué sirve:** Para recuperar documentación, páginas y enlaces desaparecidos; exige verificar procedencia y fecha de captura.
  - **Temporalidad:** Histórica
- 🥇🏺 ⭐⭐⭐⭐ **Wayback Machine — Save Page Now** — https://archivesupport.zendesk.com/hc/en-us/articles/360001513491-Save-Pages-in-the-Wayback-Machine (F35)
  - **Para qué sirve:** Para preservar hoy una página que puede desaparecer mañana. Útil para documentación legacy y releases abandonadas.
  - **Temporalidad:** Histórica
- 🥇🧱 ⭐⭐⭐⭐⭐ **Git — git bisect** — https://git-scm.com/docs/git-bisect ([F11](11-validar-tu-proyecto.md), F30, F35)
  - **Para qué sirve:** Convierte “algo se rompió entre antes y ahora” en una búsqueda binaria reproducible.
  - **Temporalidad:** Estable
- 🥇🧱 ⭐⭐⭐⭐ **Semantic Versioning 2.0.0** — https://semver.org/ (F01, [F27](27-registries-por-dentro.md), F35)
  - **Para qué sirve:** Base para razonar sobre MAJOR/MINOR/PATCH, aunque un proyecto real puede aplicar SemVer imperfectamente.
  - **Temporalidad:** Estable

### 9.2 Debian, Linux y POSIX

- 🥇🏺 ⭐⭐⭐⭐⭐ **Debian 10 Buster — información de release** — https://www.debian.org/releases/buster/ (F01, F03, [F21](21-arquitecturas-y-emulacion.md), F30)
  - **Para qué sirve:** Fuente primaria para fechas, arquitecturas y estado de Debian 10.
  - **Temporalidad:** Histórica
- 🥇🏺 ⭐⭐⭐⭐⭐ **Debian Archive** — https://archive.debian.org/ (F01, F03, F30)
  - **Para qué sirve:** Repositorio histórico para releases EOL; clave cuando apt-get update deja de hablar con mirrors normales.
  - **Temporalidad:** Histórica
- 🥇🏺 ⭐⭐⭐⭐⭐ **Debian Sources** — https://sources.debian.org/ (F03, [F04](04-toolchain-de-compilacion.md), [F05](05-python-y-node-gyp.md), [F14](14-abi-libc-y-prebuilds.md), F30)
  - **Para qué sirve:** Permite inspeccionar fuentes y versiones históricas de paquetes Debian.
  - **Temporalidad:** Histórica
- 🥇🧱 ⭐⭐⭐⭐ **Debian Policy Manual** — https://www.debian.org/doc/debian-policy/ (F03, F04, F30)
  - **Para qué sirve:** Referencia normativa para entender paquetes, filesystem y convenciones Debian.
  - **Temporalidad:** Estable
- 🥇🧱 ⭐⭐⭐⭐⭐ **GNU Bash Manual** — https://www.gnu.org/software/bash/manual/ (F03, [F08](08-run-el-contenedor-como-proceso.md), F30)
  - **Para qué sirve:** Shell principal del laboratorio; expansión, redirecciones, exit status, jobs y scripting.
  - **Temporalidad:** Estable
- 🥇🧱 ⭐⭐⭐⭐⭐ **POSIX.1-2024 / The Open Group Base Specifications Issue 8** — https://pubs.opengroup.org/onlinepubs/9799919799/ (F03, F08, F30, F35)
  - **Para qué sirve:** Contrato de referencia para shell, utilidades y APIs POSIX. Úsalo cuando quieras separar comportamiento POSIX de extensiones GNU/Linux.
  - **Temporalidad:** Estable
- 🥇🧱 ⭐⭐⭐⭐ **GNU Make Manual** — https://www.gnu.org/software/make/manual/ (F04, F05, F14, F30)
  - **Para qué sirve:** Para entender lo que node-gyp termina invocando cuando compila addons.
  - **Temporalidad:** Estable
- 🥇🧱 ⭐⭐⭐⭐ **GCC Online Documentation** — https://gcc.gnu.org/onlinedocs/ (F04, F14, F30)
  - **Para qué sirve:** Compilación C/C++; útil al investigar flags, errores de compilador y linking.
  - **Temporalidad:** Estable
- 🥇🧱 ⭐⭐⭐⭐ **GNU Binutils Documentation** — https://sourceware.org/binutils/docs/ (F04, F14, F30)
  - **Para qué sirve:** readelf, nm, ld, ar y amigos: la caja de rayos X de los binarios ELF.
  - **Temporalidad:** Estable
- 🥇🧱 ⭐⭐⭐⭐⭐ **man7.org — Linux man-pages** — https://man7.org/linux/man-pages/ (F08, F30)
  - **Para qué sirve:** Procesos, señales, namespaces, syscalls, sockets, /proc y prácticamente media Parte II del curso: [F16](16-pid1-senales-y-ciclo-de-vida.md), [F17](17-usuarios-permisos-y-volumenes.md), [F18](18-networking-de-contenedores.md) y [F30](30-troubleshooting-metodo-y-herramientas.md).
  - **Temporalidad:** Estable

### 9.3 Docker

- 🥇⚡ ⭐⭐⭐⭐⭐ **Dockerfile reference** — https://docs.docker.com/reference/dockerfile/ ([F02](02-dockerfile-esencial.md), [F07](07-build-de-la-imagen.md), F30)
  - **Para qué sirve:** Referencia canónica de instrucciones Dockerfile. Para flags exactos, manda sobre cualquier tutorial.
  - **Temporalidad:** Dinámica
- 🥇⚡ ⭐⭐⭐⭐⭐ **Build overview** — https://docs.docker.com/build/ (F02, F07, F21, F27, F30)
  - **Para qué sirve:** Puerta de entrada a BuildKit, Buildx, cache y builds multi-platform.
  - **Temporalidad:** Dinámica
- 🥇⚡ ⭐⭐⭐⭐⭐ **Build context** — https://docs.docker.com/build/concepts/context/ (F02, F07, F30)
  - **Para qué sirve:** Explica qué ve el builder y por qué el punto final de docker build no es decoración.
  - **Temporalidad:** Dinámica
- 🥇⚡ ⭐⭐⭐⭐⭐ **Build cache** — https://docs.docker.com/build/cache/ (F02, F07, F30)
  - **Para qué sirve:** Fundamental para diferenciar rebuild, cache hit, cache miss y rituales de limpieza innecesarios.
  - **Temporalidad:** Dinámica
- 🥇⚡ ⭐⭐⭐⭐⭐ **docker container run** — https://docs.docker.com/reference/cli/docker/container/run/ (F08, F11, [F10](10-vscode-y-debugging.md), F30)
  - **Para qué sirve:** Sintaxis y comportamiento de run; mounts, env, users, ports, resources y lifecycle.
  - **Temporalidad:** Dinámica
- 🥇⚡ ⭐⭐⭐⭐⭐ **Bind mounts** — https://docs.docker.com/engine/storage/bind-mounts/ ([F00](00-problema-y-contrato.md), F01, F08, F11, F10)
  - **Para qué sirve:** La pieza que conecta código del host con /workspace sin copiar el proyecto dentro de la imagen.
  - **Temporalidad:** Dinámica
- 🥇⚡ ⭐⭐⭐⭐⭐ **Volumes** — https://docs.docker.com/engine/storage/volumes/ (F01, F08, F11, F21, F30)
  - **Para qué sirve:** Base para aislar node_modules por proyecto, Node y arquitectura.
  - **Temporalidad:** Dinámica
- 🥇⚡ ⭐⭐⭐⭐⭐ **Networking overview** — https://docs.docker.com/engine/network/ (F08, [F24](24-docker-y-podman-arquitectura.md), F30)
  - **Para qué sirve:** Puertos, bridge, DNS y reachability; evita diagnosticar red con magia.
  - **Temporalidad:** Dinámica
- 🥇⚡ ⭐⭐⭐⭐ **Rootless mode** — https://docs.docker.com/engine/security/rootless/ (F08, F24, F30)
  - **Para qué sirve:** Contexto para privilegios y diferencias con Podman rootless.
  - **Temporalidad:** Dinámica
- 🥇⚡ ⭐⭐⭐⭐ **Docker Desktop troubleshooting** — https://docs.docker.com/desktop/troubleshoot-and-support/troubleshoot/ (F10, F21, F24, F30)
  - **Para qué sirve:** Diagnósticos del producto Desktop, especialmente importantes en macOS/Windows.
  - **Temporalidad:** Muy dinámica

### 9.4 OCI y estándares

- 🥇🧱 ⭐⭐⭐⭐⭐ **Open Container Initiative** — https://opencontainers.org/ (F02, F21, F24, F27)
  - **Para qué sirve:** Portal de la organización que mantiene Image, Runtime y Distribution specifications.
  - **Temporalidad:** Estable
- 🥇🧱 ⭐⭐⭐⭐⭐ **OCI Image Specification** — https://specs.opencontainers.org/image-spec/ (F02, F07, F21, F24, F27)
  - **Para qué sirve:** Manifests, layers, config, descriptors, digests e image indexes.
  - **Temporalidad:** Estable
- 🥇🧱 ⭐⭐⭐⭐⭐ **OCI Runtime Specification** — https://specs.opencontainers.org/runtime-spec/ (F08, F24, F30)
  - **Para qué sirve:** Lifecycle y configuración de runtime; ayuda a separar “Docker” de “contenedores”.
  - **Temporalidad:** Estable
- 🥇🧱 ⭐⭐⭐⭐⭐ **OCI Distribution Specification** — https://specs.opencontainers.org/distribution-spec/ (F27)
  - **Para qué sirve:** API para push/pull de contenido OCI; base conceptual de registries interoperables.
  - **Temporalidad:** Estable

### 9.5 Node.js y npm

- 🥇🏺 ⭐⭐⭐⭐⭐ **Node.js previous releases** — https://nodejs.org/en/about/previous-releases (F01, [F06](06-instalacion-node.md), F14, F11, F21)
  - **Para qué sirve:** Calendario y estado de ramas; imprescindible para saber qué significa EOL.
  - **Temporalidad:** Histórica/dinámica
- 🥇🏺 ⭐⭐⭐⭐⭐ **Node.js 10.24.1 — Download Archive** — https://nodejs.org/en/download/archive/v10.24.1 (F01, F06, F14, F11, F21)
  - **Para qué sirve:** Binarios oficiales, checksums y metadata de la release exacta usada por el laboratorio.
  - **Temporalidad:** Histórica
- 🥇🏺 ⭐⭐⭐⭐⭐ **Node.js 12.22.12 — Download Archive** — https://nodejs.org/en/download/archive/v12.22.12 (F01, F06, F14, F11, F21)
  - **Para qué sirve:** Binarios oficiales, checksums y metadata de la release exacta usada por el laboratorio.
  - **Temporalidad:** Histórica
- 🥇🏺 ⭐⭐⭐⭐⭐ **Node.js 14.21.3 — Download Archive** — https://nodejs.org/en/download/archive/v14.21.3 (F01, F06, F14, F11, F21)
  - **Para qué sirve:** Binarios oficiales, checksums y metadata de la release exacta usada por el laboratorio.
  - **Temporalidad:** Histórica
- 🥇🏺 ⭐⭐⭐⭐⭐ **Node.js 16.20.2 — Download Archive** — https://nodejs.org/en/download/archive/v16.20.2 (F01, F06, F14, F11, F21)
  - **Para qué sirve:** Binarios oficiales, checksums y metadata de la release exacta usada por el laboratorio.
  - **Temporalidad:** Histórica
- 🥇🏺 ⭐⭐⭐⭐⭐ **npm 6 — npm ci** — https://docs.npmjs.com/cli/v6/commands/npm-ci/ (F01, F11, F30)
  - **Para qué sirve:** Documentación de la generación de npm usada por Node 10/12/14; evita extrapolar flags de npm moderno.
  - **Temporalidad:** Histórica
- 🥇🏺 ⭐⭐⭐⭐⭐ **npm package-lock.json** — https://docs.npmjs.com/cli/v6/configuring-npm/package-lock-json/ (F01, F11, F30)
  - **Para qué sirve:** Fuente de verdad para reproducibilidad de dependencias en npm 6.
  - **Temporalidad:** Histórica
- 🥈⚡ ⭐⭐⭐⭐⭐ **node-gyp — repositorio y documentación** — https://github.com/nodejs/node-gyp (F05, F06, F14, F30)
  - **Para qué sirve:** Herramienta central para addons; usa tags/changelog históricos, no solo README actual.
  - **Temporalidad:** Dinámica + histórica
- 🥈🏺 ⭐⭐⭐⭐⭐ **node-gyp CHANGELOG** — https://github.com/nodejs/node-gyp/blob/main/CHANGELOG.md (F05, F14, F30)
  - **Para qué sirve:** Permite rastrear el momento en que cambió soporte de Python y otras compatibilidades.
  - **Temporalidad:** Histórica

### 9.6 Dependencias nativas y browsers

- 🥈🏺 ⭐⭐⭐⭐⭐ **Node Sass — repositorio archivado** — https://github.com/sass/node-sass (F01, F14, F11, F21, F30)
  - **Para qué sirve:** Matriz histórica Node/ABI y releases. Proyecto archivado, pero precisamente por eso es fuente primaria del fósil.
  - **Temporalidad:** Histórica
- 🥇🏺 ⭐⭐⭐⭐ **Sass — Node Sass is end-of-life** — https://sass-lang.com/blog/node-sass-is-end-of-life/ (F01, F14, F30)
  - **Para qué sirve:** Contexto oficial del fin de Node Sass.
  - **Temporalidad:** Histórica
- 🥈⚡ ⭐⭐⭐⭐ **node-canvas** — https://github.com/Automattic/node-canvas (F14, F21, F30)
  - **Para qué sirve:** Cairo/Pango, prebuilds y requisitos nativos.
  - **Temporalidad:** Dinámica
- 🥈⚡ ⭐⭐⭐⭐ **node-sqlite3** — https://github.com/TryGhost/node-sqlite3 (F14, F21, F30)
  - **Para qué sirve:** Caso clásico de addon nativo y binarios precompilados.
  - **Temporalidad:** Dinámica
- 🥇⚡ ⭐⭐⭐⭐ **sharp — documentación** — https://sharp.pixelplumbing.com/ (F14, F21, F30)
  - **Para qué sirve:** libvips, plataforma, arquitectura y prebuilds.
  - **Temporalidad:** Dinámica
- 🥇⚡ ⭐⭐⭐⭐ **Puppeteer** — https://pptr.dev/ (F14, F21, F30)
  - **Para qué sirve:** Browsers descargados, ejecutables, librerías y arquitectura.
  - **Temporalidad:** Muy dinámica
- 🥇⚡ ⭐⭐⭐⭐ **Cypress documentation** — https://docs.cypress.io/ (F00, F01, F14, F11, F21, F30)
  - **Para qué sirve:** Testing browser/Electron; para proyectos antiguos cruza siempre con la versión histórica instalada.
  - **Temporalidad:** Muy dinámica
- 🥈⚡ ⭐⭐⭐ **Selenium Docker** — https://github.com/SeleniumHQ/docker-selenium (F00, F01, F14, F21, F30)
  - **Para qué sirve:** Alternativa para separar navegador del toolchain base.
  - **Temporalidad:** Dinámica

### 9.7 Frameworks JavaScript legacy

- 🥇🏺 ⭐⭐⭐⭐⭐ **Vue 2 documentation** — https://v2.vuejs.org/ (F00, F11, F10)
  - **Para qué sirve:** Documentación congelada de Vue 2; mejor fuente que la guía Vue 3 para un proyecto 2018.
  - **Temporalidad:** Histórica
- 🥇🏺 ⭐⭐⭐⭐⭐ **Angular — version compatibility** — https://angular.dev/reference/versions (F00, F11)
  - **Para qué sirve:** Matriz oficial Angular/Node/TypeScript/RxJS.
  - **Temporalidad:** Dinámica con historia
- 🥇🏺 ⭐⭐⭐⭐ **React — versions archive** — https://react.dev/versions (F00, F11)
  - **Para qué sirve:** Enlaza documentación archivada de React 16/17.
  - **Temporalidad:** Histórica
- 🥇⚡ ⭐⭐⭐⭐ **Webpack documentation** — https://webpack.js.org/ (F00, F01, F11, F30)
  - **Para qué sirve:** Configuración, watch y conceptos; para Webpack 3/4 complementa con tags/changelog históricos.
  - **Temporalidad:** Dinámica
- 🥇🏺 ⭐⭐⭐⭐ **TypeScript release notes** — https://www.typescriptlang.org/docs/handbook/release-notes/overview.html (F00, F11, F10)
  - **Para qué sirve:** Permite ubicar capacidades y cambios por generación 2.x/3.x.
  - **Temporalidad:** Histórica/dinámica

### 9.8 IDEs y Dev Containers

- 🥇⚡ ⭐⭐⭐⭐⭐ **Dev Container Specification** — https://containers.dev/ (F10, F24)
  - **Para qué sirve:** Especificación independiente de una sola UI para describir entornos de desarrollo en contenedores.
  - **Temporalidad:** Dinámica
- 🥇⚡ ⭐⭐⭐⭐⭐ **VS Code — Dev Containers** — https://code.visualstudio.com/docs/devcontainers/containers (F10, F24, F30)
  - **Para qué sirve:** Referencia práctica para servidor remoto, mounts, lifecycle y troubleshooting.
  - **Temporalidad:** Muy dinámica
- 🥇⚡ ⭐⭐⭐⭐⭐ **VS Code — Node.js debugging** — https://code.visualstudio.com/docs/nodejs/nodejs-debugging (F10, F30)
  - **Para qué sirve:** Node Inspector, launch/attach, breakpoints y source maps.
  - **Temporalidad:** Dinámica
- 🥇⚡ ⭐⭐⭐ **WebStorm — remote Node interpreters** — https://www.jetbrains.com/help/webstorm/configuring-remote-node-interpreters.html (F00, F01, F10)
  - **Para qué sirve:** Integración remota cuando el IDE todavía tolera la versión Node objetivo.
  - **Temporalidad:** Muy dinámica

### 9.9 Multiplataforma

- 🥇⚡ ⭐⭐⭐⭐⭐ **Docker — Multi-platform builds** — https://docs.docker.com/build/building/multi-platform/ (F01, F02, F07, F21, F27, F30)
  - **Para qué sirve:** BUILDPLATFORM/TARGETPLATFORM, emulación y image indexes.
  - **Temporalidad:** Dinámica
- 🥇⚡ ⭐⭐⭐⭐ **Apple — Rosetta translation environment** — https://developer.apple.com/documentation/Apple-Silicon/about-the-rosetta-translation-environment (F21)
  - **Para qué sirve:** Fuente de Apple para el mecanismo de traducción en Apple Silicon.
  - **Temporalidad:** Muy dinámica
- 🥇⚡ ⭐⭐⭐⭐ **Apple — running Intel binaries in Linux VMs** — https://developer.apple.com/documentation/virtualization/running-intel-binaries-in-linux-vms (F21)
  - **Para qué sirve:** Contexto técnico para traducción x86-64 dentro de VMs Linux.
  - **Temporalidad:** Muy dinámica
- 🥇⚡ ⭐⭐⭐⭐ **QEMU** — https://www.qemu.org/docs/master/ (F21, F30)
  - **Para qué sirve:** Emulación/virtualización; útil para entender el costo y las capas cuando amd64 corre sobre arm64.
  - **Temporalidad:** Dinámica
- 🥈⚡ ⭐⭐⭐ **Colima** — https://github.com/abiosoft/colima (F00, F01, F21)
  - **Para qué sirve:** VM/runtime alternativo en macOS; revisar versión y backend actual.
  - **Temporalidad:** Muy dinámica
- 🥇⚡ ⭐⭐⭐ **Lima** — https://lima-vm.io/ (F21)
  - **Para qué sirve:** Base conceptual/tecnológica para VMs Linux en macOS.
  - **Temporalidad:** Muy dinámica

### 9.10 Podman y ecosistema

- 🥇⚡ ⭐⭐⭐⭐⭐ **Podman documentation** — https://docs.podman.io/ (F00, F01, F07, F08, F21, F24, F30)
  - **Para qué sirve:** Referencia principal de la CLI y arquitectura de Podman.
  - **Temporalidad:** Muy dinámica
- 🥇⚡ ⭐⭐⭐⭐⭐ **podman build** — https://docs.podman.io/en/stable/markdown/podman-build.1.html (F01, F02, F07, F24, F30)
  - **Para qué sirve:** Build de Containerfile/Dockerfile y diferencias de contexto/flags.
  - **Temporalidad:** Dinámica
- 🥇⚡ ⭐⭐⭐⭐⭐ **podman run** — https://docs.podman.io/en/latest/markdown/podman-run.1.html (F00, F01, F08, F24, F30)
  - **Para qué sirve:** Runtime, rootless, mounts, networking y user namespaces.
  - **Temporalidad:** Muy dinámica
- 🥇⚡ ⭐⭐⭐⭐ **Buildah** — https://buildah.io/ (F07, F24, F27)
  - **Para qué sirve:** Construcción de imágenes en el ecosistema containers.
  - **Temporalidad:** Dinámica
- 🥈⚡ ⭐⭐⭐⭐ **Skopeo** — https://github.com/containers/skopeo (F24, F27, F30)
  - **Para qué sirve:** Inspección/copia remota de imágenes y registries sin depender del almacén local.
  - **Temporalidad:** Dinámica

### 9.11 Registries y supply chain

- 🥇⚡ ⭐⭐⭐⭐⭐ **CNCF Distribution — About Registry** — https://distribution.github.io/distribution/about/ (F27)
  - **Para qué sirve:** Implementación de referencia para un registry local y conceptos push/pull.
  - **Temporalidad:** Dinámica
- 🥇⚡ ⭐⭐⭐⭐ **GitHub Container Registry** — https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry (F27)
  - **Para qué sirve:** Autenticación, push/pull, permisos y formatos soportados por GHCR.
  - **Temporalidad:** Muy dinámica
- 🥇⚡ ⭐⭐⭐⭐ **GitLab Container Registry** — https://docs.gitlab.com/user/packages/container_registry/ (F27)
  - **Para qué sirve:** Registry integrado a GitLab y su modelo de autenticación/CI.
  - **Temporalidad:** Muy dinámica
- 🥇⚡ ⭐⭐⭐⭐ **Harbor** — https://goharbor.io/docs/main/ (F27)
  - **Para qué sirve:** Registry empresarial: RBAC, scanning, replication, retention, proxy cache y garbage collection.
  - **Temporalidad:** Muy dinámica
- 🥇⚡ ⭐⭐⭐⭐⭐ **Cosign — signing containers** — https://docs.sigstore.dev/cosign/signing/signing_with_containers/ (F27, F30)
  - **Para qué sirve:** Firma, keyless/OIDC y attestations.
  - **Temporalidad:** Muy dinámica
- 🥇🧱 ⭐⭐⭐⭐ **SLSA** — https://slsa.dev/ (F27)
  - **Para qué sirve:** Modelo de provenance e integridad de supply chain.
  - **Temporalidad:** Estable
- 🥇🧱 ⭐⭐⭐⭐ **SPDX** — https://spdx.dev/ (F27)
  - **Para qué sirve:** Estándar de SBOM y licenciamiento.
  - **Temporalidad:** Estable
- 🥇🧱 ⭐⭐⭐⭐ **CycloneDX** — https://cyclonedx.org/ (F27)
  - **Para qué sirve:** Formato SBOM orientado a seguridad y supply chain.
  - **Temporalidad:** Estable

### 9.12 Troubleshooting y seguridad

- 🥇🧱 ⭐⭐⭐⭐⭐ **curl documentation** — https://curl.se/docs/ (F03, F30)
  - **Para qué sirve:** DNS/TCP/TLS/HTTP en una sola herramienta; el estetoscopio de red del curso.
  - **Temporalidad:** Estable
- 🥇⚡ ⭐⭐⭐⭐ **OpenSSL documentation** — https://docs.openssl.org/ (F06, F30)
  - **Para qué sirve:** Certificados, TLS y debugging de handshakes.
  - **Temporalidad:** Dinámica
- 🥇🧱 ⭐⭐⭐⭐⭐ **strace manual** — https://man7.org/linux/man-pages/man1/strace.1.html (F30)
  - **Para qué sirve:** Último nivel antes de empezar a sospechar de fantasmas: syscalls observables.
  - **Temporalidad:** Estable
- 🥇⚡ ⭐⭐⭐⭐ **GitHub Advisory Database** — https://github.com/advisories/ (F14, F27, F30)
  - **Para qué sirve:** Advisories de ecosistemas open source, incluido npm.
  - **Temporalidad:** Muy dinámica
- 🥇⚡ ⭐⭐⭐⭐ **OSV** — https://osv.dev/ (F14, F27, F30)
  - **Para qué sirve:** Base de vulnerabilidades orientada a paquetes y rangos de versiones.
  - **Temporalidad:** Muy dinámica
- 🥇⚡ ⭐⭐⭐ **NVD** — https://nvd.nist.gov/ (F14, F27, F30)
  - **Para qué sirve:** Referencia CVE/NVD; útil, pero no reemplaza advisories del proveedor/proyecto.
  - **Temporalidad:** Muy dinámica
- 🥇⚡ ⭐⭐⭐⭐ **Debian Security Tracker** — https://security-tracker.debian.org/tracker/ (F01, F03, F27, F30)
  - **Para qué sirve:** Vulnerabilidades según paquetes Debian, crucial para un baseline EOL.
  - **Temporalidad:** Muy dinámica

### 9.13 RFCs y protocolos

- 🥇🧱 ⭐⭐⭐ **RFC 3986 — URI Generic Syntax** — https://www.rfc-editor.org/rfc/rfc3986 (F08, F27, F30, F35)
  - **Para qué sirve:** Sintaxis genérica de URI; útil para distinguir URL/URI, encoding y componentes durante troubleshooting.
  - **Temporalidad:** Estable
- 🥇🧱 ⭐⭐⭐⭐ **RFC 9110 — HTTP Semantics** — https://www.rfc-editor.org/rfc/rfc9110 (F08, F27, F30, F35)
  - **Para qué sirve:** Semántica HTTP moderna: métodos, status codes, headers y caching conceptual.
  - **Temporalidad:** Estable
- 🥇🏺 ⭐⭐⭐ **RFC 1034 — Domain Names: Concepts and Facilities** — https://www.rfc-editor.org/rfc/rfc1034 (F08, F24, F30, F35)
  - **Para qué sirve:** Base conceptual histórica de DNS.
  - **Temporalidad:** Histórica/estable
- 🥇🏺 ⭐⭐⭐ **RFC 1035 — Domain Names: Implementation and Specification** — https://www.rfc-editor.org/rfc/rfc1035 (F08, F24, F30, F35)
  - **Para qué sirve:** Detalles de DNS y formato/protocolo.
  - **Temporalidad:** Histórica/estable
- 🥇🧱 ⭐⭐⭐ **RFC 8446 — TLS 1.3** — https://www.rfc-editor.org/rfc/rfc8446 (F06, F27, F30, F35)
  - **Para qué sirve:** Especificación de TLS 1.3; ayuda a separar protocolo de implementación OpenSSL/curl.
  - **Temporalidad:** Estable
- 🥇🏺 ⭐⭐⭐ **RFC 5246 — TLS 1.2** — https://www.rfc-editor.org/rfc/rfc5246 (F06, F30, F35)
  - **Para qué sirve:** Referencia histórica útil porque mucho tooling legacy negocia TLS 1.2.
  - **Temporalidad:** Histórica

### 9.14 Licencias, producto y términos

- 🥇⚡ ⭐⭐ **Docker pricing / plans** — https://www.docker.com/pricing/ (F24, F27, F35)
  - **Para qué sirve:** Referencia comercial; revisar siempre antes de decisiones corporativas. No describe la arquitectura técnica del Engine.
  - **Temporalidad:** Muy dinámica
- 🥈⚡ ⭐⭐⭐⭐ **Docker Engine / Moby source** — https://github.com/moby/moby (F24, F35)
  - **Para qué sirve:** Código fuente y licencia del Engine/Moby; separa producto Docker Desktop de componentes open source.
  - **Temporalidad:** Dinámica
- 🥈⚡ ⭐⭐⭐⭐ **Podman source** — https://github.com/containers/podman (F24, F35)
  - **Para qué sirve:** Código, licencia y releases de Podman.
  - **Temporalidad:** Dinámica
- 🥈⚡ ⭐⭐⭐ **Podman Desktop source** — https://github.com/podman-desktop/podman-desktop (F24, F35)
  - **Para qué sirve:** Código/licencia del producto Desktop; no confundir con Podman CLI/libpod.
  - **Temporalidad:** Dinámica

### 9.15 Libros recomendados

- 📚 Intermedio → avanzado ⭐⭐⭐⭐ **Nigel Poulton — Docker Deep Dive, 5th Edition** — https://www.oreilly.com/library/view/docker-deep-dive/9781806024032/ (F02, F07, F08, F24, F27, F30)
  - **Para qué sirve:** Repaso moderno y estructurado de Engine, imágenes, build, red, storage, seguridad y OCI.
  - **Temporalidad:** Verificar edición
- 📚 Intermedio ⭐⭐⭐⭐ **Jeff Nickoloff & Stephen Kuenzli — Docker in Action, 2nd Edition** — https://www.manning.com/books/docker-in-action-second-edition (F02, F07, F08, F24)
  - **Para qué sirve:** Edición 2019: temporalmente cercana al ecosistema del proyecto y útil para fundamentos Docker.
  - **Temporalidad:** Verificar edición
- 📚 Intermedio → avanzado ⭐⭐⭐⭐ **Daniel Walsh — Podman in Action** — https://www.manning.com/books/podman-in-action (F24, F30)
  - **Para qué sirve:** La referencia de libro más directa para rootless Podman y su modelo diferente de Docker.
  - **Temporalidad:** Verificar edición
- 📚 Avanzado ⭐⭐⭐⭐ **Liz Rice — Container Security, 2nd Edition** — https://www.oreilly.com/library/view/container-security-2nd/9798341627697/ (F08, F24, F27, F30)
  - **Para qué sirve:** Namespaces, capabilities, seccomp, amenazas y límites reales de aislamiento.
  - **Temporalidad:** Verificar edición
- 📚 Principiante → intermedio ⭐⭐⭐⭐ **William Shotts — The Linux Command Line** — https://linuxcommand.org/tlcl.php (F03, F08, F30)
  - **Para qué sirve:** Gratis en edición Internet. Excelente para sobrevivir y luego dejar de “sobrevivir” en Bash.
  - **Temporalidad:** Verificar edición
- 📚 Principiante → intermedio ⭐⭐⭐⭐ **Brian Ward — How Linux Works, 3rd Edition** — https://nostarch.com/howlinuxworks3 (F03, F08, F21, F30)
  - **Para qué sirve:** Procesos, filesystem, red, kernel, virtualización y contenedores con buen modelo mental.
  - **Temporalidad:** Verificar edición
- 📚 Full geek ⭐⭐⭐⭐ **Michael Kerrisk — The Linux Programming Interface** — https://www.man7.org/tlpi/index.html (F08, F30)
  - **Para qué sirve:** La enciclopedia práctica de procesos, señales, syscalls, sockets y Linux/POSIX.
  - **Temporalidad:** Verificar edición
- 📚 Intermedio → avanzado ⭐⭐⭐⭐ **Nemeth et al. — UNIX and Linux System Administration Handbook, 5th Edition** — https://www.admin.com/ (F03, F08, F30)
  - **Para qué sirve:** Administración de sistemas, red, seguridad y troubleshooting con amplitud brutal.
  - **Temporalidad:** Verificar edición
- 📚 Principiante → intermedio ⭐⭐⭐⭐ **Cameron Newham — Learning the bash Shell, 3rd Edition** — https://www.oreilly.com/library/view/learning-the-bash/0596009658/ (F03, F08, F30)
  - **Para qué sirve:** Bash clásico: scripting, redirecciones, procesos y debugging de shell.
  - **Temporalidad:** Verificar edición
- 📚 Full geek ⭐⭐⭐⭐ **Brendan Gregg — Systems Performance, 2nd Edition** — https://www.pearson.com/en-us/subject-catalog/p/systems-performance/P200000000297/9780136820154 (F30)
  - **Para qué sirve:** Metodología de observabilidad, performance, tracing y experimentación. No es para leer de una sentada salvo que odies dormir.
  - **Temporalidad:** Verificar edición
- 📚 Intermedio ⭐⭐⭐⭐ **Young, Meck & Cantelon — Node.js in Action, 2nd Edition** — https://www.manning.com/books/node-js-in-action-second-edition (F01, F06, F11)
  - **Para qué sirve:** Publicado en 2017: muy útil para comprender Node en la época que queremos reproducir.
  - **Temporalidad:** Verificar edición
- 📚 Intermedio → avanzado ⭐⭐⭐⭐ **Casciaro & Mammino — Node.js Design Patterns, 3rd Edition** — https://www.packtpub.com/en-bg/product/nodejs-design-patterns-third-edition-9781839214110 (F01, F06, F11)
  - **Para qué sirve:** Edición 2020: Node internals, asincronía, módulos y patrones, temporalmente alineada con el extremo superior del curso.
  - **Temporalidad:** Verificar edición

### 9.16 Cursos, tutoriales y videos

- 🎓🧱 ⭐⭐⭐⭐⭐ **Container Training — Jérôme Petazzoni** — https://container.training/ (F02, F07, F08, F24, F30)
  - **Para qué sirve:** Material abierto, con demos y ejercicios. Excelente puente entre “sé comandos” y “entiendo contenedores”.
  - **Temporalidad:** Activo
- 🎓⚡ ⭐⭐⭐⭐ **Docker — Educational resources** — https://docs.docker.com/get-started/resources/ (F02, F07, F08)
  - **Para qué sirve:** Recursos educativos curados por Docker; úsalo para fundamentos y cruza detalles con docs.
  - **Temporalidad:** Dinámica
- 🎓🧱 ⭐⭐⭐ **NodeSchool** — https://nodeschool.io/ (F01, F06, F11)
  - **Para qué sirve:** Workshops prácticos; parte del contenido es histórico y por eso también resulta útil para contexto Node legacy.
  - **Temporalidad:** Histórica/estable
- 🎥 ⭐⭐⭐ **TechWorld with Nana — Docker Tutorial for Beginners [FULL COURSE in 3 Hours]** — https://www.youtube.com/watch?v=3c-iBn73dDE (F08)
  - **Para qué sirve:** Introducción audiovisual completa. Complemento, no sustituto de Docker Docs.
  - **Temporalidad:** Video
- 🎥🏺 ⭐⭐⭐⭐⭐ **Philip Roberts — What the heck is the event loop anyway?** — https://www.youtube.com/watch?v=8aGhZQkoFbQ (F01, F06)
  - **Para qué sirve:** Charla clásica para construir intuición sobre event loop y asincronía JavaScript.
  - **Temporalidad:** Histórica
- 🎥🏺 ⭐⭐⭐⭐ **Internet Archive — How to use the Wayback Machine** — https://www.youtube.com/watch?v=ts1tu1BiSuY (F35)
  - **Para qué sirve:** Video oficial para convertir la arqueología web en herramienta y no en ritual chamánico.
  - **Temporalidad:** Histórica
- 🎥🏺 ⭐⭐⭐⭐⭐ **Brendan Gregg — Linux Performance Tools, Velocity 2015** — https://www.youtube.com/watch?v=FJW8nGV4jxY (F30)
  - **Para qué sirve:** Observabilidad y metodología para no disparar herramientas al azar.
  - **Temporalidad:** Histórica

---

## 10. 🧬 Documentación actual vs documentación histórica

Esta tabla resume un error común y la fuente que conviene buscar:

| Caso | Fuente actual útil | Fuente histórica que manda para reproducir |
|---|---|---|
| Node 10 | página de releases/EOL actual | archive de `v10.24.1`, SHASUMS, changelog |
| npm 6 | docs npm actual para contexto | `/cli/v6/...` para comportamiento/flags |
| node-gyp antiguo | README actual para arquitectura general | tag/changelog de la versión empaquetada |
| Vue 2 | Vue actual para estado/migración | `v2.vuejs.org` y tags Vue 2 |
| React 16 | `react.dev` para archivo de versiones | `16.react.dev` / legacy docs |
| Angular 8 | docs Angular actuales para matriz histórica | release/tag/documentación de Angular 8 |
| Webpack 3/4 | webpack actual para conceptos | tags/changelog/docs históricas cuando el flag cambió |
| Docker Desktop | docs actuales | release notes/issues de la versión específica si investigas una regresión |
| Debian 10 | página de Buster + LTS | archive/snapshot/sources para paquetes concretos |
| Cypress/Puppeteer | docs actuales para arquitectura | docs/releases de la versión instalada para browser/binarios |

---

## 11. 🔐 Seguridad y EOL: una referencia no “cura” un runtime viejo

El laboratorio usa deliberadamente software EOL. Las referencias de seguridad sirven para **conocer el riesgo**, no para afirmar que el software dejó de ser vulnerable porque ahora corre dentro de un contenedor.

Fuentes base:

- **Debian Security Tracker** — https://security-tracker.debian.org/tracker/ ([F01](01-decisiones-debian-zonas-node.md), [F03](03-apt-y-utilidades.md), [F27](27-registries-por-dentro.md), [F30](30-troubleshooting-metodo-y-herramientas.md))
- **GitHub Advisory Database** — https://github.com/advisories/ ([F14](14-abi-libc-y-prebuilds.md), F27, F30)
- **OSV** — https://osv.dev/ (F14, F27, F30)
- **NVD** — https://nvd.nist.gov/ (F14, F27, F30)
- **Node.js EOL** — https://nodejs.org/en/about/eol (F01, [F06](06-instalacion-node.md), F27)

Regla práctica:

```text
lograr que arranque
    !=
hacerlo seguro para producción
```

---

## 12. 🎥 Cómo usar videos sin congelar el curso en 2019

Un video técnico puede seguir siendo excelente para conceptos y estar obsoleto para comandos.

Ejemplo: una charla vieja sobre multiarch puede explicar perfectamente manifests, emulación y Buildx, pero un flag exacto puede haber cambiado. La política será:

```text
video → modelo mental
docs actuales → sintaxis actual
release/tag histórico → reproducción legacy
```

---

## 13. 🧪 Ejercicios de la Fase 35 (9)

> 🧭 **Fase exenta del mínimo de 20** (guía de estilo §9): es un documento de consulta y no de
> lectura lineal. Estos diez son de **investigación con fuentes**, que es el ejercicio natural
> de una bibliografía.

### 🟢 Ejercicio 1 — Los artefactos de una release

En el archivo de Node, localiza `10.24.1`, identifica sus binarios Linux x64 y ARM64 y encuentra
el mecanismo de checksums.

**Objetivo:** llegar a la fuente primaria de [F06](06-instalacion-node.md) §5 por tu cuenta.

### 🟢 Ejercicio 2 — Un paquete en Debian Sources

Busca la versión de `build-essential` que traía Buster y reconstruye su cadena de dependencias.

**Pregunta:** ¿coincide con lo que te dijo `apt-cache depends` en [F04](04-toolchain-de-compilacion.md)?

### 🟡 Ejercicio 3 — La documentación que no es la tuya

Compara la documentación actual de `npm ci` con la de npm 6 y anota tres diferencias de opciones
o de contexto.

**Objetivo:** ver por qué el curso enlaza siempre a `/v6/`.

### 🟡 Ejercicio 4 — El cambio que no se aplica hacia atrás

Localiza en el changelog de `node-gyp` el cambio que convierte Python 3 en ruta soportada, y
explica por qué esa regla no vale para una versión anterior.

### 🟡 Ejercicio 5 — Documentación de una versión histórica

Toma una referencia de Webpack, Cypress o Puppeteer usada en el curso y encuentra la
documentación correspondiente a la versión de la época, no a la actual.

### 🟠 Ejercicio 6 — Una máquina del tiempo

Con Wayback Machine, encuentra una captura histórica de una documentación que haya cambiado.

**Objetivo:** registrar URL original, fecha de captura y las limitaciones de esa captura.

### 🟠 Ejercicio 7 — Ficha de evidencia de `node-sass`

Construye la ficha completa: releases, matriz Node/ABI, prebuilds, arquitecturas y estado EOL,
citando la fuente de cada dato.

### 🟠 Ejercicio 8 — Audita un blog

Escoge un artículo que recomiende "arreglar" un error de npm y audítalo con la checklist de §6.

**Objetivo:** clasificar cada afirmación como primaria, secundaria o no demostrada. La mayoría
caen en la tercera.

### 🔴 Ejercicio 9 — El mapa síntoma → fuente primaria

Construye el mapa para: TLS, DNS, ABI, libc, `node-gyp`, montajes, puertos, registry e IDE.

**Objetivo:** que cada síntoma apunte a **una** fuente primaria, no a una búsqueda.

### 💀 Ejercicio 10 — Boss fight: el expediente sin ejecutar nada

Recibes un proyecto de 2018 sin README útil. **Sin ejecutar una sola línea**, y usando solo
`package.json`, el lockfile, el historial de Git, el CI histórico, los releases, Debian Snapshot
y Wayback Machine, produce un expediente que determine: runtime probable, dependencias nativas,
navegador esperado, arquitectura y riesgos.

**Objetivo:** cada conclusión apunta a una fuente, y **cada una está marcada como prueba o como
hipótesis**. Es el paso 1 de [F34](34-proyecto-final.md) hecho a conciencia, y quien lo hace bien llega al proyecto final
con la mitad del trabajo resuelto.

---

## 14. 🗂️ Mapa fase → fuentes esenciales

> 📝 Este mapa se reagrupó al reestructurar el curso de 20 documentos a 36 fases: donde antes
> había un documento gigante —`11-run`, `17-troubleshooting`— ahora hay varias fases, y sus
> fuentes se listan juntas.

## [F00](00-problema-y-contrato.md) — El problema y el contrato

- Docker bind mounts
- Podman run
- VS Code Node containers
- Cypress browsers

## [F01](01-decisiones-debian-zonas-node.md) — Selección de Debian

- Debian 10 Buster
- Debian EOL/Archive
- Node 10 archive

## [F01](01-decisiones-debian-zonas-node.md) — Las tres zonas del laboratorio

- Bind mounts
- Volumes
- Podman mounts
- Dev tooling

## [F01](01-decisiones-debian-zonas-node.md) y [a02](a02-estrategia-node-y-clis.md) — Estrategia de Node y CLIs

- Node archives
- npm 6 docs
- SemVer
- Node Sass support

## [F02](02-dockerfile-esencial.md) — Dockerfile: instrucciones esenciales

- Dockerfile reference
- Build context
- Build cache
- OCI Image Spec

## [F03](03-apt-y-utilidades.md) — APT y la caja de herramientas

- APT/Debian docs
- GNU Bash
- Coreutils
- Debian Archive

## [F04](04-toolchain-de-compilacion.md) — Toolchain de compilación

- GCC
- GNU Make
- Binutils
- pkg-config

## [F05](05-python-y-node-gyp.md) — Python y node-gyp

- Python 2 sunset
- Python docs
- node-gyp historical docs

## [F06](06-instalacion-node.md) — Instalación de Node

- Node release archives
- SHASUMS/GPG
- tar/xz
- node-gyp

## [F14](14-abi-libc-y-prebuilds.md) y [F15](15-laboratorios-dependencias-nativas.md) — ABI, prebuilds y laboratorios nativos

- Node ABI/Node-API
- node-sass
- canvas
- sqlite3
- sharp
- Puppeteer

## [F07](07-build-de-la-imagen.md) y [F12](12-capas-cache-y-contexto.md) — Build, capas y caché

- BuildKit
- Buildx
- cache
- image inspect/history
- Podman build

## [F08](08-run-el-contenedor-como-proceso.md), [F09](09-montar-tu-proyecto.md), [F16](16-pid1-senales-y-ciclo-de-vida.md), [F17](17-usuarios-permisos-y-volumenes.md) y [F18](18-networking-de-contenedores.md) — Run, montajes, PID 1, permisos y red

- docker run
- PID 1/signals
- mounts
- networking
- users/UID/GID

## [F11](11-validar-tu-proyecto.md) y [F20](20-validacion-sistematica-y-evidencia.md) — Validación y evidencia

- npm ci
- package-lock
- framework version matrices
- Git evidence

## [F10](10-vscode-y-debugging.md) y [F19](19-dev-containers.md) — VS Code, debugging y Dev Containers

- VS Code Dev Containers
- Node Inspector
- WebStorm remote Node
- Git credentials

## F21–F23 — Arquitecturas, Apple Silicon y estudios de caso

- Docker multi-platform
- OCI Image Index
- Apple virtualization/Rosetta
- QEMU
- Colima/Lima

## F24–F26 — Docker y Podman: arquitectura, rootless y portabilidad

- Docker Engine architecture
- Podman/libpod
- rootless
- Buildah
- Skopeo
- OCI

## F27–F29 — Registries, publicación y supply chain

- OCI Distribution
- registries
- Skopeo
- Cosign
- SBOM
- SLSA/provenance

## F30–F33 — Troubleshooting: método, catálogos y forense

- Docker troubleshooting
- curl/OpenSSL
- strace
- man7
- Git bisect
- advisories

## F35 — Referencias

- Wayback Machine
- Debian Snapshot
- bibliografía maestra
- evaluación de fuentes

---

## 15. 🔁 Mapa inverso: fuente → dónde se usa

§14 va de fase a fuentes. Esta tabla va al revés: **tienes una fuente abierta y quieres saber
qué partes del curso se apoyan en ella**, que es la pregunta cuando una documentación cambia y
hay que revisar qué se queda desactualizado.

| Fuente principal | Fases que se apoyan en ella |
|---|---|
| **Docker Docs** — CLI, Dockerfile, build, storage, networking | prácticamente todas; con peso en F02, F07, F08, F09, F12, F18 y F28 |
| **BuildKit y Buildx** | F07, F12, F21, F28 |
| **Podman, Buildah y Skopeo** | F24, F25, F26, F27 · [a07](a07-colima-y-lima.md) |
| **Especificaciones OCI** — image, runtime, distribution | F13, F21, F24, F27, F29 |
| **Node.js oficial y su archivo de descargas** | F00, F06, F11, F14, F20 · [a02](a02-estrategia-node-y-clis.md) |
| **npm Docs (rama v6)** | F11, F20, F32 |
| **node-gyp y GYP** | F05, F14, F15, F32 |
| **Debian: releases, Policy, Sources, Archive** | F01, F03, F04 · [a01](a01-debian-y-apt-a-fondo.md), [a04](a04-checksums-gpg-y-archivos.md) |
| **GNU, man7 y sourceware** — bash, make, gcc, binutils, man-pages | F03, F04, F05, F08, F16, F17, F25 · [a03](a03-binutils-y-elf.md) |
| **Documentación del kernel** — OverlayFS, namespaces, `binfmt_misc`, cgroups | F13, F16, F17, F21, F25 |
| **VS Code y containers.dev** | F10, F19 · [a06](a06-webstorm.md) para la alternativa |
| **Sigstore, SPDX, CycloneDX y SLSA** | F29 |
| **Registries** — Distribution Spec, GHCR, GitLab, Harbor | F27, F28 · [a11](a11-ghcr-y-gitlab.md), [a12](a12-harbor.md) |
| **Internet Archive y Debian Snapshot** | F03, F33 y **cualquier fase** cuando una fuente histórica desaparezca |

> 🧭 **Cómo usar esta tabla el día que importa.** Cuando Docker publique una versión que cambie
> el comportamiento de algo, no releas el curso entero: mira la fila, ve a esas fases y
> comprueba solo sus bloques de comando. Y si la fuente que cambió es de las que la fase declara
> en su **fecha de revisión de documentación externa**, esa fecha es exactamente la que hay que
> actualizar.

> 📝 **Por qué esta tabla está escrita a mano y no generada.** La versión anterior se produjo
> agregando las etiquetas de fase de la bibliografía, y salía sesgada: las etiquetas se
> reparten de forma muy desigual —hay fases con doscientas menciones y fases con una—, así que
> el agregado medía *cuánto se etiquetó* y no *quién usa qué*. Esta versión responde a la
> pregunta que el lector tiene. Para el detalle entrada por entrada, §18.

---

## 16. 🧰 Qué guardar en un expediente de referencia

Para una fuente que realmente condiciona una decisión técnica, guarda algo parecido a:

```yaml
title: node-gyp changelog
url: https://github.com/nodejs/node-gyp/blob/main/CHANGELOG.md
consulted: 2026-09-03
target_version: 3.8.0 / 5.x / 6.x
phase: f07,f09,f17
claim: soporte de Python por generación
evidence_type: changelog oficial
stability: historical
notes: no extrapolar README actual hacia versiones antiguas
```

Para una release o artefacto añade cuando sea posible:

- tag;
- commit SHA;
- digest;
- checksum;
- fecha de publicación;
- fecha de consulta;
- versión del producto;
- URL archivada si la fuente es frágil.

---

## 17. 🔗 Link rot: cuando el enlace muere pero el bug sigue vivo

Las referencias legacy sufren `link rot`: dominios desaparecen, documentación se reorganiza, proyectos archivan repositorios y CDNs eliminan artefactos.

Cuando una fuente desaparece:

1. busca el tag/release en el repositorio oficial;
2. busca el nombre exacto de la página;
3. revisa Wayback Machine;
4. revisa Debian Snapshot / Sources si era un paquete Debian;
5. busca el checksum o nombre exacto del artefacto;
6. registra que la nueva ubicación es un archivo histórico;
7. NO reemplaces silenciosamente una fuente histórica por documentación moderna.

---

## 18. 📦 Inventario exhaustivo deduplicado de referencias de las 36 fases

Esta parte funciona como índice forense. Se generó a partir de las URLs presentes en las fases anteriores, eliminando URLs locales/de ejemplo y unificando las fases donde aparece la misma referencia.

Las entradas de esta sección son deliberadamente más compactas. Para estudiar, usa primero la bibliografía comentada; para localizar la fuente exacta de una fase, usa este inventario.

> 🧾 **Cómo leer los nombres de esta sección.** El inventario se generó por extracción, así que
> los nombres siguen una convención propia y **deliberadamente conservadora**: cuando la entrada
> también aparece en la bibliografía comentada de §9, lleva su título verificado; cuando no,
> lleva **`Sitio — ruta`** derivado de la propia URL —`Docker Docs — engine/reference/builder`,
> `man7.org — ptrace(2)`—. Esa etiqueta no pretende ser el título de la página: es el sitio y la
> ruta, información que ya está en el enlace. **Lo hacemos así porque poner un título sin
> haberlo verificado sería inventarlo**, y §10.3 lo prohíbe. Si necesitas el título real, ábrela.
>
> Y una advertencia de lectura: casi todas las entradas llevan `F35` en su lista de fases,
> porque esta misma sección las cita. Eso no significa que la fuente se use en F35 — para saber
> **quién usa qué de verdad**, la tabla buena es la de §15.

### 18.1 Arqueología digital y preservación

- 🥉🧱 **Wayback Machine** — https://archivesupport.zendesk.com/hc/en-us/articles/360004651732-Using-The-Wayback-Machine (F35)
- 🥉🧱 **Wayback Machine — Save Page Now** — https://archivesupport.zendesk.com/hc/en-us/articles/360001513491-Save-Pages-in-the-Wayback-Machine (F35)
- 🥇🏺 **Debian Snapshot** — https://snapshot.debian.org/ (F01, F03, F30, F35)

### 18.2 Linux, Debian, POSIX y toolchain GNU

- 🥇🏺 **Debian Archive** — https://archive.debian.org/ (F03, F30, F35)
- 🥇🧱 **VS Code Docs — remote/advancedcontainers/persist-bash-history** — https://code.visualstudio.com/remote/advancedcontainers/persist-bash-history (F10, F35)
- 🥇🧱 **Debian — mirror principal de paquetes** — https://deb.debian.org/debian (F03, F35)
- 📝🧱 **Kernel Docs — admin-guide/binfmt-misc** — https://docs.kernel.org/admin-guide/binfmt-misc.html (F21, F35)
- 🥇🧱 **GCC 8.5 manual** — https://gcc.gnu.org/onlinedocs/gcc-8.5.0/gcc/ (F04, F35)
- 🥇🧱 **GCC — documentación oficial** — https://gcc.gnu.org/onlinedocs/ (F04, F30, F35)
- 📝🧱 **William Shotts — The Linux Command Line, edición Internet gratuita** — https://linuxcommand.org/tlcl.php (F03, F08, F30, F35)
- 📝🧱 **Linux man-pages** — https://man7.org/linux/man-pages/ (F14, F35)
- 📝🧱 **strace manual** — https://man7.org/linux/man-pages/man1/strace.1.html (F30, F35)
- 📝🧱 **ld.so** — https://man7.org/linux/man-pages/man8/ld.so.8.html (F14, F35)
- 📝🧱 **Linux man-pages — namespaces(7)** — https://man7.org/linux/man-pages/man7/namespaces.7.html (F08, F35)
- 📝🧱 **Linux man-pages — pid_namespaces(7)** — https://man7.org/linux/man-pages/man7/pid_namespaces.7.html (F08, F35)
- 📝🧱 **Linux man-pages — proc(5)** — https://man7.org/linux/man-pages/man5/proc.5.html (F08, F30, F35)
- 📝🧱 **Linux man-pages — signal(7)** — https://man7.org/linux/man-pages/man7/signal.7.html (F08, F30, F35)
- 📝🧱 **man7.org — man-pages de Linux** — https://man7.org/ (F30, F35)
- 📝🧱 **man7.org — ldd(1)** — https://man7.org/linux/man-pages/man1/ldd.1.html (F14, F30, F35)
- 📝🧱 **man7.org — execve(2)** — https://man7.org/linux/man-pages/man2/execve.2.html (F30, F35)
- 📝🧱 **man7.org — ptrace(2)** — https://man7.org/linux/man-pages/man2/ptrace.2.html (F30, F35)
- 📝🧱 **man7.org — wait(2)** — https://man7.org/linux/man-pages/man2/wait.2.html (F30, F35)
- 📝🧱 **man7.org — ip(8)** — https://man7.org/linux/man-pages/man8/ip.8.html (F30, F35)
- 📝🧱 **man7.org — ss(8)** — https://man7.org/linux/man-pages/man8/ss.8.html (F30, F35)
- 🥇🧱 **Debian Buster manpage — file** — https://manpages.debian.org/buster/file/file.1.en.html (F04, F35)
- 🥇🧱 **Debian Buster manpage — ld** — https://manpages.debian.org/buster/binutils-common/ld.1.en.html (F04, F35)
- 🥇🧱 **Debian Buster manpage — pkg-config** — https://manpages.debian.org/buster/pkgconf/pkg-config.1.en.html (F04, F35)
- 🥇🧱 **Debian manpage — sources.list(5) para Buster** — https://manpages.debian.org/buster/apt/sources.list.5.en.html (F03, F35)
- 🥇🧱 **Debian — formato .pc** — https://manpages.debian.org/buster/pkgconf/pc.5.en.html (F04, F35)
- 🥇🧱 **manpages.debian.org — testing/apt/apt-cache.8.en** — https://manpages.debian.org/testing/apt/apt-cache.8.en.html (F30, F35)
- 🥇🧱 **manpages.debian.org — testing/apt/apt-get.8.en** — https://manpages.debian.org/testing/apt/apt-get.8.en.html (F30, F35)
- 🥇🧱 **manpages.debian.org — testing/apt/apt.conf.5.en** — https://manpages.debian.org/testing/apt/apt.conf.5.en.html (F30, F35)
- 🥇🧱 **manpages.debian.org — testing/apt/sources.list.5.en** — https://manpages.debian.org/testing/apt/sources.list.5.en.html (F30, F35)
- 🥇🧱 **Debian Security Tracker** — https://security-tracker.debian.org/tracker/ (F01, F03, F27, F30, F35)
- 🥇🧱 **Debian Sources — build-essential 12.6 (Buster)** — https://sources.debian.org/src/build-essential/12.6/ (F04, F35)
- 🥇🧱 **Debian Sources — pkg-config 0.29-6 / Buster** — https://sources.debian.org/src/pkg-config/0.29-6/ (F04, F35)
- 🥇🧱 **Debian Sources — Python 2.7** — https://sources.debian.org/src/python2.7/ (F05, F35)
- 🥇🧱 **Debian Sources — Python 3.7** — https://sources.debian.org/src/python3.7/ (F05, F35)
- 🥇🧱 **Debian Sources — python3-defaults** — https://sources.debian.org/src/python3-defaults/ (F05, F35)
- 🥇🧱 **Lista histórica de paquetes build-essential** — https://sources.debian.org/src/build-essential/12.6/list (F04, F35)
- 🥇🧱 **Debian Sources** — https://sources.debian.org/ (F30, F35)
- 📝🧱 **ar** — https://sourceware.org/binutils/docs/binutils/ar.html (F04, F35)
- 📝🧱 **Binutils manual** — https://sourceware.org/binutils/docs/ (F04, F30, F35)
- 📝🧱 **nm** — https://sourceware.org/binutils/docs/binutils/nm.html (F04, F14, F30, F35)
- 📝🧱 **objdump** — https://sourceware.org/binutils/docs/binutils/objdump.html (F04, F35)
- 📝🧱 **readelf** — https://sourceware.org/binutils/docs/binutils/readelf.html (F04, F14, F30, F35)
- 📝🧱 **sourceware — binutils/docs/binutils** — https://sourceware.org/binutils/docs/binutils/ (F14, F35)
- 📝🧱 **sourceware — docs/binutils/c_002b_002bfilt** — https://sourceware.org/binutils/docs/binutils/c_002b_002bfilt.html (F14, F35)
- 🥇🧱 **Debian LTS FAQ — releases archivadas** — https://wiki.debian.org/LTS/FAQ (F03, F35)
- 🥇🧱 **Debian Wiki — SourcesList** — https://wiki.debian.org/SourcesList (F03, F35)
- 🥇🧱 **Debian Wiki — Apt** — https://wiki.debian.org/Apt (F30, F35)
- 📝🧱 **wiki.linuxfoundation.org — networking/iproute2** — https://wiki.linuxfoundation.org/networking/iproute2 (F30, F35)
- 📝🧱 **compatibilidad musl** — https://wiki.musl-libc.org/compatibility (F14, F35)
- 📝🧱 **FAQ musl** — https://wiki.musl-libc.org/faq.html (F14, F35)
- 🥇🏺 **Debian 10 Buster** — https://www.debian.org/releases/buster/ (F01, F30, F35)
- 🥇🧱 **Debian Administrator's Handbook — The APT Tools** — https://www.debian.org/doc/manuals/debian-handbook/apt.en.html (F03, F35)
- 🥇🧱 **Debian APT User's Guide — apt-get** — https://www.debian.org/doc/manuals/apt-guide/ch2.en.html (F03, F35)
- 🥇🧱 **Debian FAQ — Package management tools** — https://www.debian.org/doc/manuals/debian-faq/pkgtools.html (F03, F35)
- 🥇🧱 **Debian Mirrors** — https://www.debian.org/mirror/list.html (F03, F35)
- 🥇🧱 **Debian Mirrors en español** — https://www.debian.org/mirror/list.es.html (F03, F35)
- 🥇🧱 **Debian Policy Manual** — https://www.debian.org/doc/debian-policy/ (F04, F35)
- 🥇🧱 **Debian Python Policy** — https://www.debian.org/doc/packaging-manuals/python-policy/ (F05, F35)
- 🥇🧱 **Debian Reference en español — Gestión de paquetes** — https://www.debian.org/doc/manuals/debian-reference/ch02.es.html (F03, F35)
- 🥇🧱 **Debian Reference — Package management** — https://www.debian.org/doc/manuals/debian-reference/ch02.en.html (F03, F35)
- 🥇🧱 **Manual de Debian — herramientas APT en español** — https://www.debian.org/doc/manuals/debian-handbook/apt.es.html (F03, F35)
- 📝⚡ **www.freedesktop.org — wiki/Software/pkg-config** — https://www.freedesktop.org/wiki/Software/pkg-config/ (F14, F35)
- 🥇🧱 **Bash — exec builtin** — https://www.gnu.org/software/bash/manual/bash.html#Bourne-Shell-Builtins (F08, F35)
- 🥇🧱 **Bash — set** — https://www.gnu.org/software/bash/manual/bash.html#The-Set-Builtin (F08, F35)
- 🥇🧱 **Dynamic linker en glibc** — https://www.gnu.org/software/libc/manual/html_node/Dynamic-Linker.html (F14, F35)
- 🥇🧱 **GNU Bash Manual** — https://www.gnu.org/software/bash/manual/ (F03, F30, F35)
- 🥇🧱 **GNU Bash Manual** — https://www.gnu.org/software/bash/manual/bash.html (F08, F35)
- 🥇🧱 **GNU Binutils** — https://www.gnu.org/software/binutils/ (F04, F35)
- 🥇🧱 **GNU C Library** — https://www.gnu.org/software/libc/ (F14, F35)
- 🥇🧱 **GNU Coreutils** — https://www.gnu.org/software/coreutils/manual/coreutils.html (F03, F08, F35)
- 🥇🧱 **GNU libc manual** — https://www.gnu.org/software/libc/manual/ (F14, F30, F35)
- 🥇🧱 **GNU Make** — https://www.gnu.org/software/make/ (F04, F35)
- 🥇🧱 **GNU Make Manual** — https://www.gnu.org/software/make/manual/ (F04, F35)
- 🥇🧱 **GNU Make — introducción a Makefiles** — https://www.gnu.org/software/make/manual/html_node/Introduction.html (F04, F35)
- 🥇🧱 **GNU Make — variables** — https://www.gnu.org/software/make/manual/html_node/Using-Variables.html (F04, F35)
- 🥇🧱 **GNU tar manual** — https://www.gnu.org/software/tar/manual/ (F03, F06, F35)
- 🥇🧱 **GNU wget manual** — https://www.gnu.org/software/wget/manual/ (F03, F35)
- 🥇🧱 **GNU — manual/html_node/Exit-Status** — https://www.gnu.org/software/bash/manual/html_node/Exit-Status.html (F30, F35)
- 🥇🧱 **GNU — manual/html_node/Pipelines** — https://www.gnu.org/software/bash/manual/html_node/Pipelines.html (F11, F30, F35)
- 🥇🧱 **GNU — manual/html_node/Redirections** — https://www.gnu.org/software/bash/manual/html_node/Redirections.html (F11, F35)
- 🥇🧱 **GNU — software/coreutils/manual** — https://www.gnu.org/software/coreutils/manual/ (F11, F35)
- 🥇🧱 **GNU — manual/html_node/sha2-utilities** — https://www.gnu.org/software/coreutils/manual/html_node/sha2-utilities.html (F06, F35)
- 🥇🧱 **GNU — manual/html_node/tee-invocation** — https://www.gnu.org/software/coreutils/manual/html_node/tee-invocation.html (F11, F35)
- 📝🧱 **Michael Kerrisk — The Linux Programming Interface** — https://www.man7.org/tlpi/index.html (F08, F30, F35)
- 📚🧱 **Cameron Newham — Learning the bash Shell, 3rd Edition** — https://www.oreilly.com/library/view/learning-the-bash/0596009658/ (F03, F08, F30, F35)

### 18.3 Docker: imágenes, build, run, storage, red y seguridad

- 📝🧱 **containerd — sitio oficial** — https://containerd.io/ (F24, F35)
- 🥇🧱 **Docker bind mounts** — https://docs.docker.com/engine/storage/bind-mounts/ (F00, F01, F08, F11, F10, F24, F35)
- 🥇🧱 **Docker build best practices** — https://docs.docker.com/build/building/best-practices/ (F02, F03, F04, F05, F07, F35)
- 🥇🧱 **Docker CLI — detach keys** — https://docs.docker.com/reference/cli/docker/ (F08, F24, F35)
- 🥇🧱 **Docker Concepts — Sharing local files** — https://docs.docker.com/get-started/docker-concepts/running-containers/sharing-local-files/ (F08, F35)
- 🥇⚡ **Docker Desktop — problemas conocidos en Apple Silicon y emulación AMD64** — https://docs.docker.com/desktop/troubleshoot-and-support/troubleshoot/known-issues/ (F01, F35)
- 🥇🧱 **Docker Hub usage** — https://docs.docker.com/docker-hub/usage/ (F27, F35)
- 🥇🧱 **Docker multi-platform builds** — https://docs.docker.com/build/building/multi-platform/ (F01, F02, F04, F05, F21, F27, F30, F35)
- 🥇🧱 **Docker — Bind mounts** — https://docs.docker.com/get-started/workshop/06_bind_mounts/ (F08, F35)
- 🥇🧱 **Docker — Build cache** — https://docs.docker.com/build/cache/ (F02, F03, F07, F24, F30, F35)
- 🥇🧱 **Docker — Build checks** — https://docs.docker.com/reference/build-checks/ (F02, F35)
- 🥇🧱 **Docker — Build context** — https://docs.docker.com/build/concepts/context/ (F02, F07, F35)
- 🥇🧱 **Docker — Build variables (ARG, ENV)** — https://docs.docker.com/build/building/variables/ (F02, F06, F30, F35)
- 🥇🧱 **Docker — container command index** — https://docs.docker.com/reference/cli/docker/container/ (F08, F35)
- 🥇🧱 **Docker — Containerize an application** — https://docs.docker.com/get-started/workshop/02_our_app/ (F08, F35)
- 🥇🧱 **Docker — desarrollo Node dentro de contenedores** — https://docs.docker.com/guides/nodejs/develop/ (F01, F35)
- 🥇🧱 **Docker — docker attach** — https://docs.docker.com/reference/cli/docker/container/attach/ (F08, F35)
- 🥇⚡ **Docker — docker buildx build** — https://docs.docker.com/reference/cli/docker/buildx/build/ (F02, F07, F27, F35)
- 🥇🧱 **Docker — docker container create** — https://docs.docker.com/reference/cli/docker/container/create/ (F08, F35)
- 🥇🧱 **Docker — docker container ls / docker ps** — https://docs.docker.com/reference/cli/docker/container/ls/ (F08, F35)
- 🥇🧱 **Docker — docker container restart** — https://docs.docker.com/reference/cli/docker/container/restart/ (F08, F35)
- 🥇🧱 **Docker — docker container rm** — https://docs.docker.com/reference/cli/docker/container/rm/ (F08, F35)
- 🥇🧱 **Docker — docker container run** — https://docs.docker.com/reference/cli/docker/container/run/ (F08, F11, F10, F30, F35)
- 🥇🧱 **Docker — docker container start** — https://docs.docker.com/reference/cli/docker/container/start/ (F08, F35)
- 🥇🧱 **Docker — docker container wait** — https://docs.docker.com/reference/cli/docker/container/wait/ (F08, F30, F35)
- 🥇🧱 **Docker — docker exec** — https://docs.docker.com/reference/cli/docker/container/exec/ (F08, F11, F10, F35)
- 🥇🧱 **Docker — docker kill** — https://docs.docker.com/reference/cli/docker/container/kill/ (F08, F35)
- 🥇🧱 **Docker — docker logs** — https://docs.docker.com/reference/cli/docker/container/logs/ (F08, F11, F30, F35)
- 🥇🧱 **Docker — docker network** — https://docs.docker.com/reference/cli/docker/network/ (F08, F35)
- 🥇🧱 **Docker — docker port** — https://docs.docker.com/reference/cli/docker/container/port/ (F08, F35)
- 🥇🧱 **Docker — docker stats** — https://docs.docker.com/reference/cli/docker/container/stats/ (F08, F30, F35)
- 🥇🧱 **Docker — docker stop** — https://docs.docker.com/reference/cli/docker/container/stop/ (F08, F35)
- 🥇🧱 **Docker — docker update** — https://docs.docker.com/reference/cli/docker/container/update/ (F08, F35)
- 🥇🧱 **Docker — Dockerfile overview** — https://docs.docker.com/build/concepts/dockerfile/ (F02, F35)
- 🥇🧱 **Docker — Educational resources y entrenamiento** — https://docs.docker.com/get-started/resources/ (F02, F07, F08, F35)
- 🥇🧱 **Docker — Getting Started Workshop** — https://docs.docker.com/get-started/workshop/ (F08, F35)
- 🥇🧱 **Docker — guía de Node.js** — https://docs.docker.com/guides/nodejs/ (F01, F35)
- 🥇🧱 **Docker — JSON arguments recommended** — https://docs.docker.com/reference/build-checks/json-args-recommended/ (F02, F35)
- 🥇🧱 **Docker — logging drivers** — https://docs.docker.com/engine/logging/configure/ (F08, F35)
- 🥇🧱 **Docker — multiple processes / --init** — https://docs.docker.com/engine/containers/multi-service_container/ (F08, F35)
- 🥇🧱 **Docker — Networking overview** — https://docs.docker.com/engine/network/ (F08, F11, F24, F30, F35)
- 🥇🧱 **Docker — Optimizing cache** — https://docs.docker.com/build/cache/optimize/ (F02, F07, F35)
- 🥇🧱 **Docker — Persist data** — https://docs.docker.com/get-started/workshop/05_persisting_data/ (F08, F35)
- 🥇🧱 **Docker — Port publishing and mapping** — https://docs.docker.com/engine/network/port-publishing/ (F08, F11, F30, F35)
- 🥇🧱 **Docker — Resource constraints** — https://docs.docker.com/engine/containers/resource_constraints/ (F08, F35)
- 🥇🧱 **Docker — Running containers** — https://docs.docker.com/engine/containers/run/ (F08, F30, F35)
- 🥇🧱 **Docker — Start containers automatically / restart policies** — https://docs.docker.com/engine/containers/start-containers-automatically/ (F08, F35)
- 🥇🧱 **Docker — storage overview** — https://docs.docker.com/engine/storage/ (F08, F11, F35)
- 🥇🧱 **Docker — View container logs** — https://docs.docker.com/engine/logging/ (F08, F35)
- 🥇🧱 **Docker — Volumes** — https://docs.docker.com/engine/storage/volumes/ (F08, F11, F10, F24, F35)
- 🥇🧱 **Docker — Writing a Dockerfile** — https://docs.docker.com/get-started/docker-concepts/building-images/writing-a-dockerfile/ (F02, F35)
- 🥇🧱 **Dockerfile reference** — https://docs.docker.com/reference/dockerfile/ (F02, F03, F04, F05, F06, F07, F08, F21, F35)
- 🥇🧱 **Dockerfile — CMD** — https://docs.docker.com/reference/dockerfile/#cmd (F08, F35)
- 🥇🧱 **Dockerfile — ENTRYPOINT** — https://docs.docker.com/reference/dockerfile/#entrypoint (F08, F35)
- 🥇🧱 **Dockerfile — EXPOSE** — https://docs.docker.com/reference/dockerfile/#expose (F08, F35)
- 🥇🧱 **Dockerfile — HEALTHCHECK** — https://docs.docker.com/reference/dockerfile/#healthcheck (F08, F35)
- 🥇🧱 **Dockerfile — shell vs exec form** — https://docs.docker.com/reference/dockerfile/#shell-and-exec-form (F08, F35)
- 🥇🧱 **Dockerfile — USER** — https://docs.docker.com/reference/dockerfile/#user (F08, F35)
- 🥇🧱 **Dockerfile — WORKDIR** — https://docs.docker.com/reference/dockerfile/#workdir (F08, F35)
- 🥇⚡ **Docker Docs — build/buildkit** — https://docs.docker.com/build/buildkit/ (F07, F24, F35)
- 🥇⚡ **Docker Docs — build/buildx** — https://docs.docker.com/build/buildx/ (F24, F30, F35)
- 🥇⚡ **Docker Docs — desktop** — https://docs.docker.com/desktop/ (F24, F35)
- 🥇⚡ **Docker Docs — desktop/features/networking** — https://docs.docker.com/desktop/features/networking/ (F24, F35)
- 🥇⚡ **Docker Docs — desktop/features/vmm** — https://docs.docker.com/desktop/features/vmm/ (F21, F24, F35)
- 🥇⚡ **Docker Docs — desktop/settings-and-maintenance/settings** — https://docs.docker.com/desktop/settings-and-maintenance/settings/ (F21, F24, F35)
- 🥇⚡ **Docker Docs — cli/docker/buildx** — https://docs.docker.com/reference/cli/docker/buildx/ (F07, F35)
- 🥇⚡ **Docker Docs — buildx/imagetools/inspect** — https://docs.docker.com/reference/cli/docker/buildx/imagetools/inspect/ (F21, F27, F35)
- 🥇⚡ **Docker Docs — subscription/desktop-license** — https://docs.docker.com/subscription/desktop-license/ (F24, F35)
- 🥇⚡ **Docker Desktop troubleshooting** — https://docs.docker.com/desktop/troubleshoot-and-support/troubleshoot/ (F30, F35)
- 🥇🧱 **Rootless mode** — https://docs.docker.com/engine/security/rootless/ (F24, F35)
- 🥇🧱 **Build overview** — https://docs.docker.com/build/ (F24, F30, F35)
- 🥇🧱 **Docker Docs — build/builders** — https://docs.docker.com/build/builders/ (F07, F30, F35)
- 🥇🧱 **Docker Docs — build/builders/drivers** — https://docs.docker.com/build/builders/drivers/ (F07, F35)
- 🥇🧱 **Docker Docs — build/building/multi-stage** — https://docs.docker.com/build/building/multi-stage/ (F07, F35)
- 🥇🧱 **Docker Docs — build/building/secrets** — https://docs.docker.com/build/building/secrets/ (F07, F24, F30, F35)
- 🥇🧱 **Docker Docs — build/cache/backends** — https://docs.docker.com/build/cache/backends/ (F07, F35)
- 🥇🧱 **Docker Docs — build/cache/invalidation** — https://docs.docker.com/build/cache/invalidation/ (F07, F30, F35)
- 🥇🧱 **Docker Docs — concepts/context/#dockerignore-files** — https://docs.docker.com/build/concepts/context/#dockerignore-files (F07, F35)
- 🥇🧱 **Docker Docs — concepts/context/#named-contexts** — https://docs.docker.com/build/concepts/context/#named-contexts (F07, F35)
- 🥇🧱 **Docker Docs — build/concepts/overview** — https://docs.docker.com/build/concepts/overview/ (F07, F35)
- 🥇🧱 **Docker Docs — build/metadata/attestations** — https://docs.docker.com/build/metadata/attestations/ (F27, F30, F35)
- 🥇🧱 **Docker Docs — metadata/attestations/sbom** — https://docs.docker.com/build/metadata/attestations/sbom/ (F27, F30, F35)
- 🥇🧱 **Docker Docs — metadata/attestations/slsa-provenance** — https://docs.docker.com/build/metadata/attestations/slsa-provenance/ (F27, F30, F35)
- 🥇🧱 **Docker Docs — compose** — https://docs.docker.com/compose/ (F24, F35)
- 🥇🧱 **Docker Docs — manage/hub-images/push** — https://docs.docker.com/docker-hub/repos/manage/hub-images/push/ (F27, F35)
- 🥇🧱 **Docker Docs — docker-hub/usage/pulls** — https://docs.docker.com/docker-hub/usage/pulls/ (F27, F35)
- 🥇🧱 **Docker Docs — engine** — https://docs.docker.com/engine/ (F24, F30, F35)
- 🥇🧱 **Docker Docs — engine/cli/proxy** — https://docs.docker.com/engine/cli/proxy/ (F30, F35)
- 🥇🧱 **Docker Docs — containers/resource_constraints/#cpu** — https://docs.docker.com/engine/containers/resource_constraints/#cpu (F08, F35)
- 🥇🧱 **Docker Docs — containers/run/#runtime-privilege-and-linux-capabilities** — https://docs.docker.com/engine/containers/run/#runtime-privilege-and-linux-capabilities (F24, F35)
- 🥇🧱 **Docker Docs — engine/containers/runmetrics** — https://docs.docker.com/engine/containers/runmetrics/ (F30, F35)
- 🥇🧱 **Docker Docs — engine/daemon** — https://docs.docker.com/engine/daemon/ (F24, F35)
- 🥇🧱 **Docker Docs — engine/daemon/alternative-runtimes** — https://docs.docker.com/engine/daemon/alternative-runtimes/ (F24, F35)
- 🥇🧱 **Docker Docs — engine/daemon/embedded-containerd** — https://docs.docker.com/engine/daemon/embedded-containerd/ (F24, F35)
- 🥇🧱 **Docker Docs — engine/daemon/logs** — https://docs.docker.com/engine/daemon/logs/ (F30, F35)
- 🥇🧱 **Docker Docs — engine/daemon/proxy** — https://docs.docker.com/engine/daemon/proxy/ (F30, F35)
- 🥇🧱 **Docker Docs — engine/daemon/troubleshoot** — https://docs.docker.com/engine/daemon/troubleshoot/ (F30, F35)
- 🥇🧱 **Docker Docs — engine/manage-resources/contexts** — https://docs.docker.com/engine/manage-resources/contexts/ (F24, F30, F35)
- 🥇🧱 **Docker Docs — network/drivers/bridge** — https://docs.docker.com/engine/network/drivers/bridge/ (F24, F30, F35)
- 🥇🧱 **Docker Docs — network/drivers/host** — https://docs.docker.com/engine/network/drivers/host/ (F30, F35)
- 🥇🧱 **Docker Docs — engine/security** — https://docs.docker.com/engine/security/ (F24, F35)
- 🥇🧱 **Docker Docs — engine/security/certificates** — https://docs.docker.com/engine/security/certificates/ (F30, F35)
- 🥇🧱 **Docker Docs — engine/security/protect-access** — https://docs.docker.com/engine/security/protect-access/ (F10, F35)
- 🥇🧱 **Docker Docs — security/rootless/troubleshoot** — https://docs.docker.com/engine/security/rootless/troubleshoot/ (F24, F35)
- 🥇🧱 **Docker Docs — engine/security/trust** — https://docs.docker.com/engine/security/trust/ (F27, F35)
- 🥇🧱 **Docker Docs — engine/security/userns-remap** — https://docs.docker.com/engine/security/userns-remap/ (F24, F35)
- 🥇🧱 **Docker Docs — storage/bind-mounts/#bind-mounting-over-existing-data** — https://docs.docker.com/engine/storage/bind-mounts/#bind-mounting-over-existing-data (F08, F35)
- 🥇🧱 **Docker Docs — storage/bind-mounts/#syntax** — https://docs.docker.com/engine/storage/bind-mounts/#syntax (F08, F35)
- 🥇🧱 **Docker Docs — engine/storage/containerd** — https://docs.docker.com/engine/storage/containerd/ (F24, F35)
- 🥇🧱 **Docker Docs — get-started/docker-overview** — https://docs.docker.com/get-started/docker-overview/ (F24, F35)
- 🥇🧱 **Docker Docs — reference/build-checks/from-platform-flag-const-disallowed** — https://docs.docker.com/reference/build-checks/from-platform-flag-const-disallowed/ (F21, F35)
- 🥇🧱 **Docker Docs — docker/container/inspect** — https://docs.docker.com/reference/cli/docker/container/inspect/ (F30, F35)
- 🥇🧱 **Docker Docs — container/run/#add-entries-to-container-hosts-file---add-host** — https://docs.docker.com/reference/cli/docker/container/run/#add-entries-to-container-hosts-file---add-host (F08, F35)
- 🥇🧱 **Docker Docs — container/run/#allocate-a-pseudo-tty--t---tty** — https://docs.docker.com/reference/cli/docker/container/run/#allocate-a-pseudo-tty--t---tty (F08, F35)
- 🥇🧱 **Docker Docs — container/run/#clean-up---rm** — https://docs.docker.com/reference/cli/docker/container/run/#clean-up---rm (F08, F35)
- 🥇🧱 **Docker Docs — container/run/#detached-mode--d---detach** — https://docs.docker.com/reference/cli/docker/container/run/#detached-mode--d---detach (F08, F35)
- 🥇🧱 **Docker Docs — container/run/#pid-settings---pid** — https://docs.docker.com/reference/cli/docker/container/run/#pid-settings---pid (F08, F35)
- 🥇🧱 **Docker Docs — container/run/#publish-all-exposed-ports--p---publish-all** — https://docs.docker.com/reference/cli/docker/container/run/#publish-all-exposed-ports--p---publish-all (F08, F35)
- 🥇🧱 **Docker Docs — container/run/#set-working-directory--w---workdir** — https://docs.docker.com/reference/cli/docker/container/run/#set-working-directory--w---workdir (F08, F35)
- 🥇🧱 **Docker Docs — container/run/#specify-an-init-process** — https://docs.docker.com/reference/cli/docker/container/run/#specify-an-init-process (F08, F35)
- 🥇🧱 **Docker Docs — cli/docker/image** — https://docs.docker.com/reference/cli/docker/image/ (F07, F24, F35)
- 🥇🧱 **Docker Docs — docker/image/history** — https://docs.docker.com/reference/cli/docker/image/history/ (F07, F35)
- 🥇🧱 **Docker Docs — docker/image/inspect** — https://docs.docker.com/reference/cli/docker/image/inspect/ (F07, F21, F35)
- 🥇🧱 **Docker Docs — docker/image/load** — https://docs.docker.com/reference/cli/docker/image/load/ (F24, F35)
- 🥇🧱 **Docker Docs — docker/image/ls** — https://docs.docker.com/reference/cli/docker/image/ls/ (F07, F35)
- 🥇🧱 **Docker Docs — docker/image/pull** — https://docs.docker.com/reference/cli/docker/image/pull/ (F07, F30, F35)
- 🥇🧱 **Docker Docs — docker/image/push** — https://docs.docker.com/reference/cli/docker/image/push/ (F27, F30, F35)
- 🥇🧱 **Docker Docs — docker/image/save** — https://docs.docker.com/reference/cli/docker/image/save/ (F24, F35)
- 🥇🧱 **Docker Docs — docker/image/tag** — https://docs.docker.com/reference/cli/docker/image/tag/ (F07, F27, F35)
- 🥇🧱 **Docker Docs — cli/docker/inspect** — https://docs.docker.com/reference/cli/docker/inspect/ (F11, F35)
- 🥇🧱 **Docker Docs — cli/docker/login** — https://docs.docker.com/reference/cli/docker/login/ (F27, F30, F35)
- 🥇🧱 **Docker Docs — docker/manifest/inspect** — https://docs.docker.com/reference/cli/docker/manifest/inspect/ (F21, F35)
- 🥇🧱 **Docker Docs — docker/system/events** — https://docs.docker.com/reference/cli/docker/system/events/ (F30, F35)
- 🥇🧱 **Docker Docs — reference/compose-file** — https://docs.docker.com/reference/compose-file/ (F24, F35)
- 🥇🧱 **Docker Docs — security/access-tokens** — https://docs.docker.com/security/access-tokens/ (F27, F35)
- 🥈⚡ **GitHub — docker/buildx** — https://github.com/docker/buildx (F07, F24, F35)
- 🥈⚡ **GitHub — docker/setup-buildx-action** — https://github.com/docker/setup-buildx-action (F27, F35)
- 🥈⚡ **GitHub — moby/buildkit** — https://github.com/moby/buildkit (F07, F24, F35)
- 🥈🧱 **Docker Engine / Moby source** — https://github.com/moby/moby (F07, F24, F35)
- 📝🧱 **Debian EOL images** — https://hub.docker.com/r/debian/eol (F01, F02, F03, F35)
- 📝🧱 **Debian EOL tags** — https://hub.docker.com/r/debian/eol/tags (F02, F35)
- 📝🧱 **Imagen oficial Debian** — https://hub.docker.com/_/debian (F01, F02, F35)
- 📝🧱 **Play with Docker classroom/labs** — https://training.play-with-docker.com/ (F08, F35)
- 📝⚡ **Docker Hub pricing / Personal** — https://www.docker.com/pricing/ (F24, F27, F35)

### 18.4 OCI y estándares de contenedores

- 🥈🧱 **org.opencontainers.image.source=""** — https://github.com/ORG/REPO (F27, F35)
- 🥈⚡ **GitHub — opencontainers/image-spec · blob/main/annotations.md** — https://github.com/opencontainers/image-spec/blob/main/annotations.md (F27, F35)
- 🥈⚡ **GitHub — opencontainers/image-spec · blob/main/image-layout.md** — https://github.com/opencontainers/image-spec/blob/main/image-layout.md (F24, F35)
- 🥈🧱 **GitHub — opencontainers/distribution-spec** — https://github.com/opencontainers/distribution-spec (F27, F30, F35)
- 🥈🧱 **GitHub — opencontainers/image-spec** — https://github.com/opencontainers/image-spec (F27, F30, F35)
- 🥈🧱 **GitHub — opencontainers/runc** — https://github.com/opencontainers/runc (F24, F35)
- 🥈🧱 **GitHub — opencontainers/runtime-spec** — https://github.com/opencontainers/runtime-spec (F30, F35)
- 🥇🧱 **Open Container Initiative — portal oficial** — https://opencontainers.org/ (F02, F07, F21, F24, F27, F35)
- 🥇🧱 **OCI annotations** — https://specs.opencontainers.org/image-spec/annotations/ (F02, F27, F35)
- 🥇🧱 **OCI Distribution Specification** — https://specs.opencontainers.org/distribution-spec/ (F27, F35)
- 🥇🧱 **OCI Image Specification** — https://specs.opencontainers.org/image-spec/ (F02, F07, F21, F24, F27, F35)
- 🥇🧱 **OCI Runtime Specification** — https://specs.opencontainers.org/runtime-spec/ (F08, F24, F30, F35)
- 🥇🧱 **OCI Specs — image-spec/config** — https://specs.opencontainers.org/image-spec/config/ (F07, F35)
- 🥇🧱 **OCI Specs — image-spec/descriptor** — https://specs.opencontainers.org/image-spec/descriptor/ (F07, F35)
- 🥇🧱 **OCI Specs — image-spec/image-index** — https://specs.opencontainers.org/image-spec/image-index/ (F21, F27, F30, F35)
- 🥇🧱 **OCI Specs — image-spec/layer** — https://specs.opencontainers.org/image-spec/layer/ (F07, F35)
- 🥇🧱 **OCI Specs — image-spec/manifest** — https://specs.opencontainers.org/image-spec/manifest/ (F07, F21, F27, F30, F35)

### 18.5 Podman, Buildah, Skopeo y ecosistema containers

- 📝🧱 **Buildah** — https://buildah.io/ (F07, F24, F35)
- 🥇🧱 **Podman build** — https://docs.podman.io/en/stable/markdown/podman-build.1.html (F01, F02, F35)
- 🥇⚡ **Podman run** — https://docs.podman.io/en/latest/markdown/podman-run.1.html (F00, F01, F08, F24, F35)
- 🥇⚡ **Podman — podman attach** — https://docs.podman.io/en/latest/markdown/podman-attach.1.html (F08, F35)
- 🥇⚡ **Podman — podman exec** — https://docs.podman.io/en/latest/markdown/podman-exec.1.html (F08, F35)
- 🥇⚡ **Podman — podman kill** — https://docs.podman.io/en/latest/markdown/podman-kill.1.html (F08, F35)
- 🥇⚡ **Podman — podman logs** — https://docs.podman.io/en/latest/markdown/podman-logs.1.html (F08, F35)
- 🥇⚡ **Podman — podman machine** — https://docs.podman.io/en/stable/markdown/podman-machine.1.html (F08, F30, F35)
- 🥇⚡ **Podman — podman restart** — https://docs.podman.io/en/latest/markdown/podman-restart.1.html (F08, F35)
- 🥇⚡ **Podman — podman rm** — https://docs.podman.io/en/latest/markdown/podman-rm.1.html (F08, F35)
- 🥇⚡ **Podman — podman start** — https://docs.podman.io/en/latest/markdown/podman-start.1.html (F08, F35)
- 🥇⚡ **Podman — podman stop** — https://docs.podman.io/en/latest/markdown/podman-stop.1.html (F08, F35)
- 🥇⚡ **Podman — podman volume** — https://docs.podman.io/en/latest/markdown/podman-volume.1.html (F08, F24, F35)
- 🥇⚡ **Podman Docs — latest/_static/api** — https://docs.podman.io/en/latest/_static/api.html (F24, F35)
- 🥇⚡ **Podman Docs — latest/markdown/podman-build.1** — https://docs.podman.io/en/latest/markdown/podman-build.1.html (F07, F21, F24, F35)
- 🥇⚡ **Podman Docs — latest/markdown/podman-compose.1** — https://docs.podman.io/en/latest/markdown/podman-compose.1.html (F24, F35)
- 🥇⚡ **Podman Docs — latest/markdown/podman-create.1** — https://docs.podman.io/en/latest/markdown/podman-create.1.html (F24, F35)
- 🥇⚡ **Podman Docs — latest/markdown/podman-import.1** — https://docs.podman.io/en/latest/markdown/podman-import.1.html (F24, F35)
- 🥇⚡ **Podman Docs — latest/markdown/podman-info.1** — https://docs.podman.io/en/latest/markdown/podman-info.1.html (F24, F35)
- 🥇⚡ **Podman Docs — latest/markdown/podman-load.1** — https://docs.podman.io/en/latest/markdown/podman-load.1.html (F24, F35)
- 🥇⚡ **Podman Docs — latest/markdown/podman-login.1** — https://docs.podman.io/en/latest/markdown/podman-login.1.html (F27, F35)
- 🥇⚡ **Podman Docs — latest/markdown/podman-machine-init.1** — https://docs.podman.io/en/latest/markdown/podman-machine-init.1.html (F24, F35)
- 🥇⚡ **Podman Docs — latest/markdown/podman-machine-inspect.1** — https://docs.podman.io/en/latest/markdown/podman-machine-inspect.1.html (F24, F35)
- 🥇⚡ **Podman Docs — latest/markdown/podman-machine-start.1** — https://docs.podman.io/en/latest/markdown/podman-machine-start.1.html (F24, F35)
- 🥇⚡ **Podman Docs — latest/markdown/podman-machine.1** — https://docs.podman.io/en/latest/markdown/podman-machine.1.html (F24, F35)
- 🥇⚡ **Podman Docs — latest/markdown/podman-manifest.1** — https://docs.podman.io/en/latest/markdown/podman-manifest.1.html (F21, F35)
- 🥇⚡ **Podman Docs — latest/markdown/podman-network.1** — https://docs.podman.io/en/latest/markdown/podman-network.1.html (F24, F35)
- 🥇⚡ **Podman Docs — latest/markdown/podman-pod-create.1** — https://docs.podman.io/en/latest/markdown/podman-pod-create.1.html (F24, F35)
- 🥇⚡ **Podman Docs — latest/markdown/podman-pod.1** — https://docs.podman.io/en/latest/markdown/podman-pod.1.html (F24, F35)
- 🥇⚡ **Podman Docs — latest/markdown/podman-push.1** — https://docs.podman.io/en/latest/markdown/podman-push.1.html (F27, F35)
- 🥇⚡ **Podman Docs — latest/markdown/podman-save.1** — https://docs.podman.io/en/latest/markdown/podman-save.1.html (F24, F35)
- 🥇⚡ **Podman Docs — latest/markdown/podman-system-connection.1** — https://docs.podman.io/en/latest/markdown/podman-system-connection.1.html (F24, F35)
- 🥇⚡ **Podman Docs — latest/markdown/podman-system-service.1** — https://docs.podman.io/en/latest/markdown/podman-system-service.1.html (F24, F35)
- 🥇⚡ **Podman Docs — latest/markdown/podman-unshare.1** — https://docs.podman.io/en/latest/markdown/podman-unshare.1.html (F24, F35)
- 🥇⚡ **Podman Docs — latest/markdown/podman.1** — https://docs.podman.io/en/latest/markdown/podman.1.html (F24, F35)
- 🥇🧱 **Podman documentation** — https://docs.podman.io/ (F24, F35)
- 🥇🧱 **Podman Docs — en/stable** — https://docs.podman.io/en/stable/ (F30, F35)
- 🥇🧱 **Podman Docs — stable/markdown/podman-events.1** — https://docs.podman.io/en/stable/markdown/podman-events.1.html (F30, F35)
- 🥇🧱 **Podman Docs — stable/markdown/podman-inspect.1** — https://docs.podman.io/en/stable/markdown/podman-inspect.1.html (F30, F35)
- 🥇🧱 **Podman Docs — stable/markdown/podman-logs.1** — https://docs.podman.io/en/stable/markdown/podman-logs.1.html (F30, F35)
- 🥇🧱 **Podman Docs — stable/markdown/podman-machine-inspect.1** — https://docs.podman.io/en/stable/markdown/podman-machine-inspect.1.html (F30, F35)
- 🥇🧱 **Podman Docs — stable/markdown/podman-stats.1** — https://docs.podman.io/en/stable/markdown/podman-stats.1.html (F30, F35)
- 🥈⚡ **GitHub — containers/buildah · blob/main/docs/buildah-build.1.md** — https://github.com/containers/buildah/blob/main/docs/buildah-build.1.md (F24, F35)
- 🥈⚡ **GitHub — containers/podman · blob/main/docs/tutorials/basic_networking.md** — https://github.com/containers/podman/blob/main/docs/tutorials/basic_networking.md (F24, F35)
- 🥈⚡ **GitHub — containers/podman · blob/main/docs/tutorials/rootless_tutorial.md** — https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md (F24, F35)
- 🥈⚡ **GitHub — containers/podman · blob/main/troubleshooting.md** — https://github.com/containers/podman/blob/main/troubleshooting.md (F30, F35)
- 🥈⚡ **GitHub — containers/skopeo · blob/main/docs/skopeo-copy.1.md** — https://github.com/containers/skopeo/blob/main/docs/skopeo-copy.1.md (F27, F35)
- 🥈⚡ **GitHub — containers/skopeo · blob/main/docs/skopeo-inspect.1.md** — https://github.com/containers/skopeo/blob/main/docs/skopeo-inspect.1.md (F27, F35)
- 🥈⚡ **Podman Desktop source** — https://github.com/podman-desktop/podman-desktop (F24, F35)
- 🥈🧱 **Skopeo** — https://github.com/containers/skopeo (F27, F35)
- 🥈🧱 **GitHub — containers/aardvark-dns** — https://github.com/containers/aardvark-dns (F24, F35)
- 🥈🧱 **GitHub — containers/buildah** — https://github.com/containers/buildah (F07, F24, F35)
- 🥈🧱 **GitHub — containers/crun** — https://github.com/containers/crun (F24, F35)
- 🥈🧱 **GitHub — containers/image** — https://github.com/containers/image (F27, F35)
- 🥈🧱 **GitHub — containers/netavark** — https://github.com/containers/netavark (F24, F35)
- 🥈🧱 **Podman source** — https://github.com/containers/podman (F24, F35)
- 🥈🧱 **GitHub — containers/storage** — https://github.com/containers/storage (F24, F27, F35)
- 📝⚡ **Podman Desktop Docker compatibility** — https://podman-desktop.io/docs/migrating-from-docker/managing-docker-compatibility (F00, F01, F24, F35)
- 📝⚡ **Podman Desktop — docs/intro** — https://podman-desktop.io/docs/intro (F24, F35)
- 📝⚡ **Podman Desktop — docs/migrating-from-docker/customizing-docker-compatibility** — https://podman-desktop.io/docs/migrating-from-docker/customizing-docker-compatibility (F24, F35)
- 📝⚡ **Podman Desktop — docs/podman/creating-a-podman-machine** — https://podman-desktop.io/docs/podman/creating-a-podman-machine (F24, F35)
- 📝⚡ **Podman Desktop — docs/podman/rosetta** — https://podman-desktop.io/docs/podman/rosetta (F21, F24, F35)
- 📝🧱 **Podman** — https://podman.io/ (F07, F24, F35)
- 📝🧱 **Podman — docs** — https://podman.io/docs (F30, F35)
- 📚🧱 **Daniel Walsh — Podman in Action** — https://www.manning.com/books/podman-in-action (F24, F30, F35)

### 18.6 Node.js, npm, npx y versionado

- 🥇🧱 **VS Code — Node.js in a container** — https://code.visualstudio.com/docs/containers/quickstart-node (F00, F01, F35)
- 🥇🧱 **VS Code — Node.js debugging** — https://code.visualstudio.com/docs/nodejs/nodejs-debugging (F10, F35)
- 🥇🧱 **Acerca de npm** — https://docs.npmjs.com/about-npm/ (F01, F35)
- 🥇🧱 **Documentación npm** — https://docs.npmjs.com/ (F01, F30, F35)
- 🥇🧱 **Estructura de carpetas y node_modules/.bin** — https://docs.npmjs.com/files/folders.html (F01, F35)
- 🥇🧱 **npm ci — documentación npm 6** — https://docs.npmjs.com/cli/v6/commands/npm-ci/ (F01, F11, F30, F35)
- 🥇🧱 **npm run-script — documentación npm 6** — https://docs.npmjs.com/cli/v6/commands/npm-run-script/ (F01, F11, F35)
- 🥇🧱 **npx / npm exec** — https://docs.npmjs.com/cli/npm-exec/ (F01, F35)
- 🥇🧱 **Versiones de npm CLI** — https://docs.npmjs.com/about-npm-versions/ (F01, F35)
- 🥇🧱 **npm package-lock.json** — https://docs.npmjs.com/cli/v6/configuring-npm/package-lock-json/ (F11, F30, F35)
- 🥇🧱 **npm Docs — v6/commands/npm-audit** — https://docs.npmjs.com/cli/v6/commands/npm-audit/ (F11, F35)
- 🥇🧱 **npm Docs — v6/commands/npm-cache** — https://docs.npmjs.com/cli/v6/commands/npm-cache/ (F11, F30, F35)
- 🥇🧱 **npm Docs — v6/commands/npm-ls** — https://docs.npmjs.com/cli/v6/commands/npm-ls/ (F11, F35)
- 🥇🧱 **npm Docs — v6/configuring-npm/folders** — https://docs.npmjs.com/cli/v6/configuring-npm/folders/ (F11, F35)
- 🥇🧱 **npm Docs — v6/configuring-npm/package-json** — https://docs.npmjs.com/cli/v6/configuring-npm/package-json/ (F11, F30, F35)
- 🥇🧱 **npm Docs — v6/using-npm/config** — https://docs.npmjs.com/cli/v6/using-npm/config/ (F11, F30, F35)
- 🥇🧱 **npm Docs — v6/using-npm/scripts** — https://docs.npmjs.com/cli/v6/using-npm/scripts/ (F11, F30, F35)
- 🥇🧱 **Node.js previous releases** — https://nodejs.org/en/about/previous-releases (F06, F11, F21, F30, F35)
- 🥇🏺 **Archivo de Node 12.22.12** — https://nodejs.org/en/download/archive/v12.22.12 (F01, F35)
- 🥇🏺 **Archivo de Node 14.21.3** — https://nodejs.org/en/download/archive/v14.21.3 (F01, F35)
- 🥇🏺 **Archivo de Node 16.20.2** — https://nodejs.org/en/download/archive/v16.20.2 (F01, F35)
- 🥇🧱 **Node.js — sitio oficial** — https://nodejs.org (F03, F35)
- 🥇🧱 **Descargas oficiales de Node.js** — https://nodejs.org/en/download (F01, F35)
- 🥇🧱 **Introducción oficial a Node.js** — https://nodejs.org/en/learn (F01, F35)
- 🥇🏺 **Node.js 10 HTTP API** — https://nodejs.org/download/release/v10.24.1/docs/api/http.html (F08, F35)
- 🥇🏺 **Node.js 10.24.1 archive** — https://nodejs.org/download/release/v10.24.1/ (F06, F08, F11, F21, F30, F35)
- 🥇🏺 **Node.js 10.24.1 archive** — https://nodejs.org/en/download/archive/v10.24.1 (F01, F35)
- 🥇🏺 **Node.js 10.24.1 full documentation** — https://nodejs.org/download/release/v10.24.1/docs/api/all.html (F08, F35)
- 🥇🧱 **Node.js 10.x process API / signals** — https://nodejs.org/download/release/v10.24.0/docs/api/process.html#process_signal_events (F08, F35)
- 🥇🧱 **Node.js EOL** — https://nodejs.org/en/about/eol (F06, F11, F21, F30, F35)
- 🥇🧱 **Node.js native addons** — https://nodejs.org/api/addons.html (F04, F05, F06, F14, F35)
- 🥇🧱 **Node.js release archive** — https://nodejs.org/download/release/ (F06, F14, F08, F35)
- 🥇⚡ **Node.js — docs/latest-v10.x/api** — https://nodejs.org/docs/latest-v10.x/api/ (F11, F35)
- 🥇⚡ **Node.js — latest-v10.x/api/debugger** — https://nodejs.org/docs/latest-v10.x/api/debugger.html (F10, F35)
- 🥇🏺 **Node.js — dist/v10.24.1/SHASUMS256** — https://nodejs.org/dist/v10.24.1/SHASUMS256.txt (F06, F35)
- 🥇🏺 **Node.js — v10.24.1/docs/api** — https://nodejs.org/download/release/v10.24.1/docs/api/ (F30, F35)
- 🥇🏺 **Node.js — docs/api/addons** — https://nodejs.org/download/release/v10.24.1/docs/api/addons.html (F06, F35)
- 🥇🏺 **Node.js — download/release/v12.22.12** — https://nodejs.org/download/release/v12.22.12/ (F06, F21, F30, F35)
- 🥇🏺 **Node.js — download/release/v14.21.3** — https://nodejs.org/download/release/v14.21.3/ (F06, F21, F30, F35)
- 🥇🏺 **Node.js — download/release/v16.20.2** — https://nodejs.org/download/release/v16.20.2/ (F06, F21, F30, F35)
- 🥇🧱 **Node.js — api/debugger** — https://nodejs.org/api/debugger.html (F10, F35)
- 🥇🧱 **Node.js — api/process** — https://nodejs.org/api/process.html (F30, F35)
- 📝🧱 **🎓🧱 ⭐⭐⭐ NodeSchool** — https://nodeschool.io/ (F01, F06, F11, F35)
- 🥇⚡ **r2.nodejs.org — latest-v10.x/api/addons** — https://r2.nodejs.org/docs/latest-v10.x/api/addons.html (F06, F14, F35)
- 📝🧱 **Semantic Versioning 2.0.0** — https://semver.org/ (F01, F11, F27, F35)
- 📚🧱 **Young, Meck & Cantelon — Node.js in Action, 2nd Edition (2017)** — https://www.manning.com/books/node-js-in-action-second-edition (F01, F06, F11, F35)
- 📝🧱 **npm registry — package/@angular/cli?activeTab=versions** — https://www.npmjs.com/package/@angular/cli?activeTab=versions (F11, F35)
- 📚🧱 **Casciaro & Mammino — Node.js Design Patterns, 3rd Edition (2020)** — https://www.packtpub.com/en-bg/product/nodejs-design-patterns-third-edition-9781839214110 (F01, F06, F11, F35)

### 18.7 Python y soporte de build

- 🥇🧱 **Python Developer Guide — versiones soportadas** — https://devguide.python.org/versions/ (F05, F35)
- 🥇🧱 **Python 2.7 — documentación histórica** — https://docs.python.org/2.7/ (F05, F35)
- 🥇🧱 **Python — documentación oficial** — https://docs.python.org/3/ (F05, F35)
- 🥇🧱 **Python 2 sunset** — https://www.python.org/doc/sunset-python-2/ (F05, F35)
- 📝🧱 **www.udemy.com — course/complete-python-bootcamp** — https://www.udemy.com/course/complete-python-bootcamp/ (F05, F35)
- 📝🧱 **www.udemy.com — course/python-guia-de-inicio** — https://www.udemy.com/course/python-guia-de-inicio/ (F05, F35)

### 18.8 Dependencias nativas, ABI, browsers y testing

- 📝🧱 **app.unpkg.com — sqlite3@5.0.2/files/README** — https://app.unpkg.com/sqlite3@5.0.2/files/README.md (F14, F35)
- 📝🧱 **Cypress browser launching** — https://docs.cypress.io/app/references/launching-browsers (F00, F01, F21, F35)
- 📝🧱 **Cypress documentation** — https://docs.cypress.io/ (F30, F35)
- 📝🧱 **Cypress Docs — app/get-started/install-cypress** — https://docs.cypress.io/app/get-started/install-cypress (F30, F35)
- 📝🧱 **docs.gtk.org — Pango** — https://docs.gtk.org/Pango/ (F14, F35)
- 🥈🧱 **actual** — https://github.com/nodejs/node-gyp (F04, F05, F06, F14, F30, F35)
- 🥈🧱 **Cypress Docker images** — https://github.com/cypress-io/cypress-docker-images (F01, F21, F35)
- 🥈🧱 **historial** — https://github.com/puppeteer/puppeteer (F14, F21, F30, F35)
- 🥈🧱 **node-gyp 3.8.0** — https://github.com/nodejs/node-gyp/tree/v3.8.0 (F05, F35)
- 🥈🧱 **node-gyp 4.0.0** — https://github.com/nodejs/node-gyp/tree/v4.0.0 (F05, F35)
- 🥈🧱 **node-gyp 5.1.0** — https://github.com/nodejs/node-gyp/tree/v5.1.0 (F05, F35)
- 🥈🧱 **node-gyp 7.1.2** — https://github.com/nodejs/node-gyp/tree/v7.1.2 (F05, F35)
- 🥈🧱 **node-gyp 8.4.1** — https://github.com/nodejs/node-gyp/tree/v8.4.1 (F05, F35)
- 🥈🧱 **node-gyp 9.4.0** — https://github.com/nodejs/node-gyp/tree/v9.4.0 (F05, F35)
- 🥈⚡ **node-gyp changelog** — https://github.com/nodejs/node-gyp/blob/main/CHANGELOG.md (F05, F35)
- 🥈🧱 **node-sass — releases y entornos soportados** — https://github.com/sass/node-sass/releases (F01, F14, F21, F35)
- 🥈🧱 **node-sass — repositorio histórico y política de soporte** — https://github.com/sass/node-sass (F01, F14, F21, F30, F35)
- 🥈🧱 **Selenium Docker** — https://github.com/SeleniumHQ/docker-selenium (F00, F01, F21, F30, F35)
- 🥈⚡ **GitHub — nodejs/node-gyp · blob/main/docs/Force-npm-to-use-global-node-gyp.md** — https://github.com/nodejs/node-gyp/blob/main/docs/Force-npm-to-use-global-node-gyp.md (F06, F30, F35)
- 🥈⚡ **GitHub — nodejs/node-gyp · blob/main/docs/Updating-npm-bundled-node-gyp.md** — https://github.com/nodejs/node-gyp/blob/main/docs/Updating-npm-bundled-node-gyp.md (F06, F14, F30, F35)
- 🥈⚡ **GitHub — nodejs/node-gyp · tree/main/docs** — https://github.com/nodejs/node-gyp/tree/main/docs (F30, F35)
- 🥈🧱 **node-canvas** — https://github.com/Automattic/node-canvas (F14, F21, F30, F35)
- 🥈🧱 **node-sqlite3** — https://github.com/TryGhost/node-sqlite3 (F14, F21, F30, F35)
- 🥈🧱 **GitHub — Automattic/node-canvas · issues/1662** — https://github.com/Automattic/node-canvas/issues/1662 (F21, F35)
- 🥈🧱 **GitHub — Automattic/node-canvas · wiki/Installation:-Ubuntu-and-other-Debian-based-systems** — https://github.com/Automattic/node-canvas/wiki/Installation:-Ubuntu-and-other-Debian-based-systems (F14, F35)
- 🥈🧱 **GitHub — grpc/grpc-node** — https://github.com/grpc/grpc-node (F14, F30, F35)
- 🥈🧱 **GitHub — kelektiv/node.bcrypt.js** — https://github.com/kelektiv/node.bcrypt.js (F14, F30, F35)
- 🥈🧱 **GitHub — kelektiv/node.bcrypt.js · blob/master/CHANGELOG.md** — https://github.com/kelektiv/node.bcrypt.js/blob/master/CHANGELOG.md (F14, F35)
- 🥈🧱 **GitHub — lovell/sharp** — https://github.com/lovell/sharp (F30, F35)
- 🥈🧱 **GitHub — mapbox/node-pre-gyp** — https://github.com/mapbox/node-pre-gyp (F14, F35)
- 🥈🧱 **GitHub — nodejs/node-gyp#command-options** — https://github.com/nodejs/node-gyp#command-options (F06, F14, F35)
- 🥈🧱 **GitHub — prebuild/prebuild-install** — https://github.com/prebuild/prebuild-install (F14, F35)
- 🥈🧱 **GitHub — puppeteer/puppeteer · issues/679** — https://github.com/puppeteer/puppeteer/issues/679 (F14, F35)
- 🥈🧱 **GitHub — puppeteer/puppeteer · releases/tag/v5.5.0** — https://github.com/puppeteer/puppeteer/releases/tag/v5.5.0 (F14, F21, F35)
- 🥈🧱 **GitHub — sass/node-sass · issues/3334** — https://github.com/sass/node-sass/issues/3334 (F21, F35)
- 🥈🧱 **GitHub — sass/node-sass · releases/tag/v4.14.1** — https://github.com/sass/node-sass/releases/tag/v4.14.1 (F21, F35)
- 📝🧱 **googlechromelabs.github.io — chrome-for-testing** — https://googlechromelabs.github.io/chrome-for-testing/ (F21, F35)
- 📝🧱 **gRPC — sitio oficial** — https://grpc.io/ (F14, F35)
- 🥇🧱 **Node.js — api/n-api** — https://nodejs.org/api/n-api.html (F14, F35)
- 🥇⚡ **documentación histórica Node 10** — https://r2.nodejs.org/docs/latest-v10.x/api/n-api.html (F06, F14, F35)
- 📝🧱 **Sass — Node Sass is end-of-life** — https://sass-lang.com/blog/node-sass-is-end-of-life/ (F01, F14, F35)
- 📝🧱 **Sass** — https://sass-lang.com/ (F14, F35)
- 📝🧱 **Sass — documentation** — https://sass-lang.com/documentation/ (F14, F35)
- 📝🧱 **sharp — documentación** — https://sharp.pixelplumbing.com/ (F14, F21, F30, F35)
- 📝🧱 **sharp — changelog/v0.25.2** — https://sharp.pixelplumbing.com/changelog/v0.25.2/ (F21, F35)
- 📝🧱 **sharp — install** — https://sharp.pixelplumbing.com/install/ (F14, F35)
- 📝🧱 **Cairo — sitio oficial** — https://www.cairographics.org/ (F14, F35)
- 📝🧱 **npm registry — package/@grpc/grpc-js** — https://www.npmjs.com/package/@grpc/grpc-js (F14, F35)
- 📝🧱 **www.selenium.dev — documentation** — https://www.selenium.dev/documentation/ (F30, F35)

### 18.9 Frameworks y tooling JavaScript legacy

- 📝🧱 **Angular — version compatibility** — https://angular.dev/reference/versions (F11, F35)
- 📝🧱 **Vue CLI — documentación** — https://cli.vuejs.org/ (F11, F35)
- 📝🧱 **Create React App** — https://create-react-app.dev/ (F11, F35)
- 📝🧱 **Create React App — docs/advanced-configuration** — https://create-react-app.dev/docs/advanced-configuration/ (F11, F35)
- 🥈🧱 **GitHub — sveltejs/rollup-plugin-svelte** — https://github.com/sveltejs/rollup-plugin-svelte (F11, F35)
- 🥈🧱 **GitHub — sveltejs/rollup-plugin-svelte · blob/master/CHANGELOG.md** — https://github.com/sveltejs/rollup-plugin-svelte/blob/master/CHANGELOG.md (F11, F35)
- 🥈🧱 **GitHub — sveltejs/template** — https://github.com/sveltejs/template (F11, F35)
- 🥈🧱 **GitHub — webpack-contrib/mini-css-extract-plugin** — https://github.com/webpack-contrib/mini-css-extract-plugin (F14, F35)
- 🥈🧱 **GitHub — webpack-contrib/sass-loader** — https://github.com/webpack-contrib/sass-loader (F14, F35)
- 🥈🧱 **GitHub — webpack-contrib/sass-loader · blob/master/CHANGELOG.md** — https://github.com/webpack-contrib/sass-loader/blob/master/CHANGELOG.md (F14, F35)
- 📝🧱 **marketplace.visualstudio.com — items?itemName=Vue.volar** — https://marketplace.visualstudio.com/items?itemName=Vue.volar (F10, F35)
- 🥉🧱 **React — versions archive** — https://react.dev/versions (F35)
- 📝🧱 **unpkg.com — react-scripts@3.4.4/package.json** — https://unpkg.com/react-scripts@3.4.4/package.json (F11, F35)
- 📝🧱 **Vue 2 documentation** — https://v2.vuejs.org/ (F11, F35)
- 📝🧱 **v2.vuejs.org — lts** — https://v2.vuejs.org/lts/ (F10, F35)
- 📝🧱 **v3.cli.vuejs.org — guide/installation** — https://v3.cli.vuejs.org/guide/installation.html (F11, F35)
- 📝🧱 **webpack 4 — documentación** — https://v4.webpack.js.org/ (F14, F35)
- 📝🧱 **v4.webpack.js.org — configuration/watch** — https://v4.webpack.js.org/configuration/watch/ (F11, F35)
- 📝🧱 **Vue — vetur** — https://vuejs.github.io/vetur/ (F10, F35)
- 📝🧱 **Vue — vetur/guide/FAQ** — https://vuejs.github.io/vetur/guide/FAQ.html (F10, F35)
- 📝🧱 **Vue — vetur/guide/intellisense** — https://vuejs.github.io/vetur/guide/intellisense.html (F10, F35)
- 📝🧱 **Vue — vetur/guide/setup** — https://vuejs.github.io/vetur/guide/setup.html (F10, F35)
- 📝🧱 **Webpack — Watch y watchOptions.poll** — https://webpack.js.org/configuration/watch/ (F01, F11, F35)
- 📝🧱 **Webpack documentation** — https://webpack.js.org/ (F14, F35)
- 🥇⚡ **JetBrains — help/webstorm/eslint** — https://www.jetbrains.com/help/webstorm/eslint.html (F10, F35)
- 🥇⚡ **JetBrains — help/webstorm/settings-languages-typescript** — https://www.jetbrains.com/help/webstorm/settings-languages-typescript.html (F10, F35)
- 📝🧱 **TypeScript release notes** — https://www.typescriptlang.org/docs/handbook/release-notes/overview.html (F35)

### 18.10 IDEs, Dev Containers, Git y flujo de desarrollo

- 🥇⚡ **VS Code — Dev Containers** — https://code.visualstudio.com/docs/devcontainers/containers (F24, F30, F35)
- 🥇🧱 **Dev Container Specification** — https://containers.dev/ (F10, F24, F30, F35)
- 🥇🧱 **containers.dev — supporting** — https://containers.dev/supporting.html (F10, F24, F35)
- 📝🧱 **man.openbsd.org — ssh-agent** — https://man.openbsd.org/ssh-agent (F10, F35)
- 🥇⚡ **WebStorm remote Node runtimes** — https://www.jetbrains.com/help/webstorm/configuring-remote-node-interpreters.html (F00, F01, F10, F24, F35)
- 🥇⚡ **WebStorm supported Node versions** — https://www.jetbrains.com/help/webstorm/supported-node-js-versions.html (F01, F35)
- 🥇⚡ **JetBrains — help/webstorm** — https://www.jetbrains.com/help/webstorm/ (F30, F35)
- 🥇⚡ **JetBrains — help/webstorm/configure-node-js-remote-interpreter** — https://www.jetbrains.com/help/webstorm/configure-node-js-remote-interpreter.html (F10, F35)
- 🥇⚡ **JetBrains — help/webstorm/configuring-javascript-debugger** — https://www.jetbrains.com/help/webstorm/configuring-javascript-debugger.html (F10, F35)
- 🥇⚡ **JetBrains — help/webstorm/debugging-code** — https://www.jetbrains.com/help/webstorm/debugging-code.html (F10, F35)
- 🥇⚡ **JetBrains — help/webstorm/debugging-javascript-in-chrome** — https://www.jetbrains.com/help/webstorm/debugging-javascript-in-chrome.html (F30, F35)
- 🥇⚡ **JetBrains — help/webstorm/developing-node-js-applications** — https://www.jetbrains.com/help/webstorm/developing-node-js-applications.html (F10, F30, F35)
- 🥇⚡ **JetBrains — help/webstorm/docker** — https://www.jetbrains.com/help/webstorm/docker.html (F24, F30, F35)
- 🥇⚡ **JetBrains — help/webstorm/installing-and-removing-external-software-using-node-package-manager** — https://www.jetbrains.com/help/webstorm/installing-and-removing-external-software-using-node-package-manager.html (F10, F35)
- 🥇⚡ **JetBrains — help/webstorm/node-js-interpreters** — https://www.jetbrains.com/help/webstorm/node-js-interpreters.html (F10, F35)
- 🥇⚡ **JetBrains — help/webstorm/run-debug-configuration-node-js-remote-debug** — https://www.jetbrains.com/help/webstorm/run-debug-configuration-node-js-remote-debug.html (F10, F35)
- 🥇⚡ **JetBrains — help/webstorm/settings-tools-terminal** — https://www.jetbrains.com/help/webstorm/settings-tools-terminal.html (F10, F35)
- 🥇⚡ **JetBrains — help/webstorm/starting-the-debugger-session** — https://www.jetbrains.com/help/webstorm/starting-the-debugger-session.html (F10, F35)
- 🥇⚡ **JetBrains — help/webstorm/terminal-emulator** — https://www.jetbrains.com/help/webstorm/terminal-emulator.html (F10, F35)

### 18.11 Multiplataforma, virtualización y emulación

- 📝🧱 **Apple — Rosetta translation environment** — https://developer.apple.com/documentation/Apple-Silicon/about-the-rosetta-translation-environment (F21, F35)
- 🥈🧱 **Colima** — https://github.com/abiosoft/colima (F01, F21, F35)
- 🥈⚡ **Colima FAQ** — https://github.com/abiosoft/colima/blob/main/docs/FAQ.md (F00, F01, F35)
- 🥈⚡ **GitHub — abiosoft/colima · blob/main/cmd/start.go** — https://github.com/abiosoft/colima/blob/main/cmd/start.go (F21, F35)
- 🥈⚡ **GitHub — abiosoft/colima · blob/main/embedded/defaults/colima.yaml** — https://github.com/abiosoft/colima/blob/main/embedded/defaults/colima.yaml (F21, F35)
- 🥈🧱 **GitHub — docker/setup-qemu-action** — https://github.com/docker/setup-qemu-action (F27, F35)
- 🥈🧱 **GitHub — lima-vm/lima** — https://github.com/lima-vm/lima (F21, F35)
- 📝🧱 **lima-vm.io — docs/config/vmtype** — https://lima-vm.io/docs/config/vmtype/ (F21, F35)
- 📝🧱 **Lima** — https://lima-vm.io/ (F21, F35)
- 📝🧱 **QEMU — sitio oficial** — https://www.qemu.org/ (F21, F35)
- 📝🧱 **www.qemu.org — master/user/main** — https://www.qemu.org/docs/master/user/main.html (F21, F35)
- 📝🧱 **QEMU** — https://www.qemu.org/docs/master/ (F35)

### 18.12 Registries, publicación y supply chain

- 📝⚡ **Azure Container Registry pricing** — https://azure.microsoft.com/pricing/details/container-registry/ (F27, F35)
- 📝⚡ **Artifact Registry pricing** — https://cloud.google.com/artifact-registry/pricing (F27, F35)
- 📝⚡ **cloud.google.com — artifact-registry/docs** — https://cloud.google.com/artifact-registry/docs (F27, F35)
- 🥇🧱 **CycloneDX — SBOM standard** — https://cyclonedx.org/ (F27, F35)
- 🥇⚡ **GitHub Container Registry — documentación** — https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry (F27, F35)
- 🥇🧱 **GitHub Docs — secure-your-work/use-artifact-attestations/use-artifact-attestations** — https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations (F27, F35)
- 🥇⚡ **Authenticate** — https://docs.gitlab.com/user/packages/container_registry/authenticate_with_container_registry/ (F27, F35)
- 🥇⚡ **Build/push** — https://docs.gitlab.com/user/packages/container_registry/build_and_push_images/ (F27, F35)
- 🥇⚡ **GitLab Container Registry** — https://docs.gitlab.com/user/packages/container_registry/ (F27, F35)
- 🥇⚡ **GitLab Docs — packages/container_registry/container_repository_protection_rules** — https://docs.gitlab.com/user/packages/container_registry/container_repository_protection_rules/ (F27, F35)
- 🥇⚡ **GitLab Docs — packages/container_registry/immutable_container_tags** — https://docs.gitlab.com/user/packages/container_registry/immutable_container_tags/ (F27, F35)
- 🥇⚡ **GitLab Docs — packages/container_registry/protected_container_tags** — https://docs.gitlab.com/user/packages/container_registry/protected_container_tags/ (F27, F35)
- 🥇⚡ **GitLab Docs — packages/container_registry/reduce_container_registry_storage** — https://docs.gitlab.com/user/packages/container_registry/reduce_container_registry_storage/ (F27, F35)
- 🥇⚡ **Sigstore Cosign** — https://docs.sigstore.dev/cosign/signing/signing_with_containers/ (F27, F30, F35)
- 🥇⚡ **Sigstore Docs** — https://docs.sigstore.dev/ (F27, F30, F35)
- 🥇⚡ **Sigstore Docs — cosign/signing/overview** — https://docs.sigstore.dev/cosign/signing/overview/ (F27, F30, F35)
- 🥇⚡ **Sigstore Docs — cosign/system_config/installation** — https://docs.sigstore.dev/cosign/system_config/installation/ (F27, F30, F35)
- 🥇⚡ **Sigstore Docs — cosign/verifying/attestation** — https://docs.sigstore.dev/cosign/verifying/attestation/ (F30, F35)
- 🥇⚡ **Sigstore Docs — cosign/verifying/verify** — https://docs.sigstore.dev/cosign/verifying/verify/ (F30, F35)
- 🥇⚡ **Sigstore Docs — quickstart/quickstart-cosign** — https://docs.sigstore.dev/quickstart/quickstart-cosign/ (F27, F35)
- 🥈⚡ **GitHub — sigstore/cosign-installer** — https://github.com/sigstore/cosign-installer (F27, F35)
- 🥈🧱 **GitHub — anchore/syft** — https://github.com/anchore/syft (F27, F35)
- 🥈🧱 **GitHub — in-toto/attestation** — https://github.com/in-toto/attestation (F27, F35)
- 🥇⚡ **Harbor** — https://goharbor.io/docs/ (F27, F35)
- 🥇⚡ **Harbor** — https://goharbor.io/ (F27, F35)
- 🥇⚡ **Harbor — cli-docs/cli-docs/harbor-project-robot-create** — https://goharbor.io/cli-docs/cli-docs/harbor-project-robot-create/ (F27, F35)
- 🥇⚡ **Harbor — docs/main/administration** — https://goharbor.io/docs/main/administration/ (F27, F35)
- 🥇⚡ **Harbor — main/administration/configure-project-quotas** — https://goharbor.io/docs/main/administration/configure-project-quotas/ (F27, F35)
- 🥇⚡ **Harbor — main/administration/configure-proxy-cache** — https://goharbor.io/docs/main/administration/configure-proxy-cache/ (F27, F35)
- 🥇⚡ **Harbor — main/administration/configuring-replication** — https://goharbor.io/docs/main/administration/configuring-replication/ (F27, F35)
- 🥇⚡ **Harbor — main/administration/garbage-collection** — https://goharbor.io/docs/main/administration/garbage-collection/ (F27, F35)
- 🥇⚡ **Harbor — main/administration/sbom-integration** — https://goharbor.io/docs/main/administration/sbom-integration/ (F27, F35)
- 🥇⚡ **Harbor — main/administration/vulnerability-scanning** — https://goharbor.io/docs/main/administration/vulnerability-scanning/ (F27, F35)
- 🥇⚡ **Harbor — main/working-with-projects/create-projects** — https://goharbor.io/docs/main/working-with-projects/create-projects/ (F27, F35)
- 🥇⚡ **Harbor — working-with-projects/working-with-images/deleting-tags** — https://goharbor.io/docs/main/working-with-projects/working-with-images/deleting-tags/ (F27, F35)
- 🥇⚡ **Harbor** — https://goharbor.io/docs/main/ (F27, F35)
- 📝⚡ **Microsoft Learn — azure/container-registry** — https://learn.microsoft.com/azure/container-registry/ (F27, F35)
- 📝🧱 **oss.anchore.com — guides/sbom/formats** — https://oss.anchore.com/docs/guides/sbom/formats/ (F27, F35)
- 📝🧱 **oss.anchore.com — guides/sbom/getting-started** — https://oss.anchore.com/docs/guides/sbom/getting-started/ (F27, F35)
- 📝⚡ **Registry de npm — endpoint público** — https://registry.npmjs.org/ (F08, F11, F30, F35)
- 🥇🧱 **SLSA** — https://slsa.dev/ (F27, F35)
- 🥇🧱 **SPDX** — https://spdx.dev/ (F27, F35)
- 📝🧱 **spdx.github.io — spdx-spec** — https://spdx.github.io/spdx-spec/ (F27, F35)
- 📝🧱 **Trivy — sitio oficial** — https://trivy.dev/ (F27, F35)

### 18.13 Seguridad, EOL y vulnerabilidades

- 🥈🧱 **GitHub Advisory Database** — https://github.com/advisories/ (F14, F27, F30, F35)
- 🥇🧱 **NVD** — https://nvd.nist.gov/ (F14, F27, F30, F35)
- 🥇🧱 **OSV** — https://osv.dev/ (F14, F27, F30, F35)

### 18.14 Troubleshooting, red, observabilidad y performance

- 📝🧱 **console.log('Servidor escuchando en  + host + ':' + port);** — http://' (F08, F35)
- 📝🧱 **Servidor escuchando en** — http://0.0.0.0:3000 (F08, F35)
- 📝🧱 **access.redhat.com — solutions/8367** — https://access.redhat.com/solutions/8367 (F06, F35)
- 📝⚡ **ECR pricing** — https://aws.amazon.com/ecr/pricing/ (F27, F35)
- 🥇⚡ **VS Code Docs — docs/devcontainers/attach-container** — https://code.visualstudio.com/docs/devcontainers/attach-container (F10, F35)
- 🥇⚡ **VS Code Docs — docs/devcontainers/create-dev-container** — https://code.visualstudio.com/docs/devcontainers/create-dev-container (F10, F35)
- 🥇⚡ **VS Code Docs — docs/devcontainers/faq** — https://code.visualstudio.com/docs/devcontainers/faq (F10, F35)
- 🥇⚡ **VS Code Docs — docs/devcontainers/tips-and-tricks** — https://code.visualstudio.com/docs/devcontainers/tips-and-tricks (F30, F35)
- 🥇⚡ **VS Code Docs — docs/devcontainers/tutorial** — https://code.visualstudio.com/docs/devcontainers/tutorial (F30, F35)
- 🥇🧱 **VS Code Docs — api/advanced-topics/remote-extensions** — https://code.visualstudio.com/api/advanced-topics/remote-extensions (F10, F35)
- 🥇🧱 **VS Code Docs — configure/extensions/extension-marketplace** — https://code.visualstudio.com/docs/configure/extensions/extension-marketplace (F10, F35)
- 🥇🧱 **VS Code Docs — docs/containers/troubleshooting** — https://code.visualstudio.com/docs/containers/troubleshooting (F30, F35)
- 🥇🧱 **VS Code Docs — docs/debugtest/debugging** — https://code.visualstudio.com/docs/debugtest/debugging (F10, F35)
- 🥇🧱 **VS Code Docs — docs/debugtest/debugging-configuration** — https://code.visualstudio.com/docs/debugtest/debugging-configuration (F10, F35)
- 🥇🧱 **VS Code Docs — docs/nodejs/browser-debugging** — https://code.visualstudio.com/docs/nodejs/browser-debugging (F10, F35)
- 🥇🧱 **VS Code Docs — docs/nodejs/debugging-recipes** — https://code.visualstudio.com/docs/nodejs/debugging-recipes (F10, F35)
- 🥇🧱 **VS Code Docs — docs/nodejs/nodejs-tutorial** — https://code.visualstudio.com/docs/nodejs/nodejs-tutorial (F10, F35)
- 🥇🧱 **VS Code Docs — docs/reference/tasks-appendix** — https://code.visualstudio.com/docs/reference/tasks-appendix (F10, F35)
- 🥇🧱 **VS Code Docs — docs/remote/faq** — https://code.visualstudio.com/docs/remote/faq (F10, F35)
- 🥇🧱 **VS Code Docs — docs/remote/linux** — https://code.visualstudio.com/docs/remote/linux (F10, F35)
- 🥇🧱 **VS Code Docs — docs/terminal/profiles** — https://code.visualstudio.com/docs/terminal/profiles (F10, F35)
- 🥇🧱 **VS Code Docs — docs/terminal/shell-integration** — https://code.visualstudio.com/docs/terminal/shell-integration (F10, F35)
- 🥇🧱 **VS Code Docs — remote/advancedcontainers/add-nonroot-user** — https://code.visualstudio.com/remote/advancedcontainers/add-nonroot-user (F10, F35)
- 🥇🧱 **VS Code Docs — remote/advancedcontainers/docker-options** — https://code.visualstudio.com/remote/advancedcontainers/docker-options (F24, F35)
- 🥇🧱 **VS Code Docs — remote/advancedcontainers/improve-performance** — https://code.visualstudio.com/remote/advancedcontainers/improve-performance (F10, F35)
- 🥇🧱 **VS Code Docs — remote/advancedcontainers/overview** — https://code.visualstudio.com/remote/advancedcontainers/overview (F10, F24, F35)
- 🥇🧱 **VS Code Docs — remote/advancedcontainers/sharing-git-credentials** — https://code.visualstudio.com/remote/advancedcontainers/sharing-git-credentials (F10, F35)
- 📝🧱 **Compose Specification** — https://compose-spec.io/ (F24, F35)
- 📝🧱 **Jérôme Petazzoni — Container Training, materiales abiertos** — https://container.training/ (F02, F07, F08, F24, F30, F35)
- 📝🧱 **curl documentation** — https://curl.se/docs/ (F03, F30, F35)
- 📝🧱 **Apple — running Intel binaries in Linux VMs** — https://developer.apple.com/documentation/virtualization/running-intel-binaries-in-linux-vms (F21, F35)
- 📝🧱 **CNCF Distribution** — https://distribution.github.io/distribution/about/ (F27, F35)
- 📝🧱 **OCI Distribution — distribution/about/configuration** — https://distribution.github.io/distribution/about/configuration/ (F27, F35)
- 📝🧱 **OCI Distribution — distribution/about/deploying** — https://distribution.github.io/distribution/about/deploying/ (F27, F35)
- 📝🧱 **OCI Distribution — distribution/spec/api** — https://distribution.github.io/distribution/spec/api/ (F30, F35)
- 📝⚡ **docs.aws.amazon.com — latest/userguide/what-is-ecr** — https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html (F27, F35)
- 🥇🧱 **GitHub Packages billing** — https://docs.github.com/en/billing/concepts/product-billing/github-packages (F27, F35)
- 🥇🧱 **GitHub Docs — actions/tutorials/authenticate-with-github_token** — https://docs.github.com/en/actions/tutorials/authenticate-with-github_token (F27, F35)
- 🥇🧱 **GitHub Docs — tutorials/publish-packages/publish-docker-images** — https://docs.github.com/en/actions/tutorials/publish-packages/publish-docker-images (F27, F35)
- 🥇🧱 **GitHub Docs — packages/learn-github-packages/about-permissions-for-github-packages** — https://docs.github.com/en/packages/learn-github-packages/about-permissions-for-github-packages (F27, F35)
- 📝🧱 **OpenSSL documentation** — https://docs.openssl.org/ (F30, F35)
- 📝🧱 **Project Quay — documentación** — https://docs.projectquay.io/ (F27, F35)
- 🥇🧱 **Git documentation** — https://git-scm.com/doc (F03, F35)
- 🥇🧱 **Git — git bisect** — https://git-scm.com/docs/git-bisect (F11, F30, F35)
- 🥇🧱 **Git — en/v2/Customizing-Git-Git-Configuration** — https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration (F10, F35)
- 🥇🧱 **Git — docs/gitcredentials** — https://git-scm.com/docs/gitcredentials (F10, F35)
- 🥈🧱 **Artefactos de imágenes Debian EOL** — https://github.com/debuerreotype/docker-debian-eol-artifacts (F03, F35)
- 🥈🧱 **Debuerreotype — generador de rootfs Debian usado para las imágenes oficiales** — https://github.com/debuerreotype/debuerreotype (F03, F35)
- 🥈🧱 **pyenv** — https://github.com/pyenv/pyenv (F05, F35)
- 🥈⚡ **GitHub — devcontainers/cli** — https://github.com/devcontainers/cli (F24, F30, F35)
- 🥈⚡ **GitHub — nodejs/node · blob/main/README.md#verifying-binaries** — https://github.com/nodejs/node/blob/main/README.md#verifying-binaries (F06, F35)
- 🥈🧱 **GitHub — actions/attest** — https://github.com/actions/attest (F27, F35)
- 🥈🧱 **GitHub — BretFisher/container.training** — https://github.com/BretFisher/container.training (F30, F35)
- 🥈🧱 **GitHub — containers/conmon** — https://github.com/containers/conmon (F24, F35)
- 🥈🧱 **GitHub — distribution/distribution** — https://github.com/distribution/distribution (F27, F35)
- 🥈🧱 **GitHub — docker/build-push-action** — https://github.com/docker/build-push-action (F27, F35)
- 🥈🧱 **GitHub — docker/login-action** — https://github.com/docker/login-action (F27, F35)
- 🥈🧱 **GitHub — docker/metadata-action** — https://github.com/docker/metadata-action (F27, F35)
- 🥈🧱 **GitHub — fsevents/fsevents** — https://github.com/fsevents/fsevents (F14, F35)
- 🥈🧱 **GitHub — lsof-org/lsof** — https://github.com/lsof-org/lsof (F30, F35)
- 🥈🧱 **GitHub — nodejs/release-keys** — https://github.com/nodejs/release-keys (F06, F35)
- 🥈🧱 **GitHub — notaryproject/notary** — https://github.com/notaryproject/notary (F27, F35)
- 🥈🧱 **GitHub — paulmillr/chokidar** — https://github.com/paulmillr/chokidar (F14, F11, F35)
- 🥈🧱 **GitHub — prebuild/prebuild** — https://github.com/prebuild/prebuild (F14, F35)
- 📝🧱 **GYP documentation** — https://gyp.gsrc.io/docs/UserDocumentation.md (F05, F35)
- 📝🧱 **GYP input format** — https://gyp.gsrc.io/docs/InputFormatReference.md (F05, F35)
- 📝🧱 **help.sonatype.com — en/oci-repositories** — https://help.sonatype.com/en/oci-repositories.html (F27, F35)
- 📝🧱 **I** — http://host.containers.internal:8000 (F24, F35)
- 📝🧱 **I** — http://host.docker.internal:8000 (F24, F35)
- 📝🧱 **host.docker.internal:PUERTO** — http://host.docker.internal:PUERTO/ (F30, F35)
- 📝🧱 **in-toto — sitio oficial** — https://in-toto.io/ (F27, F35)
- 📝🧱 **jq manual** — https://jqlang.org/manual/ (F03, F35)
- 📝🧱 **Microsoft Learn — powershell** — https://learn.microsoft.com/powershell/ (F11, F35)
- 📝🧱 **Microsoft Learn — module/microsoft.powershell.core/get-help** — https://learn.microsoft.com/powershell/module/microsoft.powershell.core/get-help (F11, F35)
- 📝🧱 **musl** — https://musl.libc.org/ (F14, F35)
- 📚🧱 **Brian Ward — How Linux Works, 3rd Edition** — https://nostarch.com/howlinuxworks3 (F03, F08, F21, F30, F35)
- 📝🧱 **passt.top/passt/about** — https://passt.top/passt/about/ (F24, F35)
- 📝🧱 **phase15-web** — http://phase15-web (F24, F35)
- 📝🧱 **podcast.bretfisher.com — episodes/troubleshooting-docker-swarm-networking-and-dns** — https://podcast.bretfisher.com/episodes/troubleshooting-docker-swarm-networking-and-dns (F30, F35)
- 📝🧱 **Puppeteer** — https://pptr.dev/ (F14, F30, F35)
- 📝🧱 **Puppeteer — guides/configuration** — https://pptr.dev/guides/configuration (F14, F35)
- 📝🧱 **Puppeteer — troubleshooting** — https://pptr.dev/troubleshooting (F14, F21, F35)
- 📝🧱 **Rollup — documentación** — https://rollupjs.org/ (F11, F35)
- 📝🧱 **SELinux — wiki del proyecto** — https://selinuxproject.org/ (F24, F35)
- 📝🧱 **'s| \** — http://servidor-antiguo/debian|https://otro-servidor/debian|g' (F03, F35)
- 📝🧱 **XZ Utils** — https://tukaani.org/xz/ (F03, F35)
- 📚🧱 **UNIX and Linux System Administration Handbook, 5th Edition** — https://www.admin.com/ (F03, F08, F30, F35)
- 📝🧱 **www.baeldung.com — linux/sha-256-from-command-line** — https://www.baeldung.com/linux/sha-256-from-command-line (F06, F35)
- 📝🧱 **Brendan Gregg — blog/2015-12-03/linux-perf-60s-video** — https://www.brendangregg.com/blog/2015-12-03/linux-perf-60s-video.html (F30, F35)
- 📝🧱 **Brendan Gregg — blog/2020-03-08/lisa2019-linux-systems-performance** — https://www.brendangregg.com/blog/2020-03-08/lisa2019-linux-systems-performance.html (F30, F35)
- 📝🧱 **Brendan Gregg — linuxperf** — https://www.brendangregg.com/linuxperf.html (F30, F35)
- 📝🧱 **libvips — sitio oficial** — https://www.libvips.org/ (F14, F35)
- 📚🧱 **Jeff Nickoloff & Stephen Kuenzli — Docker in Action, 2nd Edition** — https://www.manning.com/books/docker-in-action-second-edition (F02, F07, F08, F24, F35)
- 📚🧱 **Liz Rice — Container Security, 2nd Edition** — https://www.oreilly.com/library/view/container-security-2nd/9798341627697/ (F08, F24, F27, F30, F35)
- 📚🧱 **Nigel Poulton — Docker Deep Dive, 5th Edition** — https://www.oreilly.com/library/view/docker-deep-dive/9781806024032/ (F02, F07, F08, F24, F27, F30, F35)
- 📚🧱 **Brendan Gregg — Systems Performance, 2nd Edition** — https://www.pearson.com/en-us/subject-catalog/p/systems-performance/P200000000297/9780136820154 (F30, F35)
- 📝🧱 **Nexus Community Edition** — https://www.sonatype.com/products/nexus-community-edition-download (F27, F35)
- 📝🧱 **SQLite — c3ref/intro** — https://www.sqlite.org/c3ref/intro.html (F14, F35)
- 📝🧱 **SQLite — docs** — https://www.sqlite.org/docs.html (F14, F35)
- 📝🧱 **SQLite — quickstart** — https://www.sqlite.org/quickstart.html (F14, F35)
- 📝🧱 **tcpdump y libpcap — sitio oficial** — https://www.tcpdump.org/ (F30, F35)
- 📝🧱 **www.usenix.org — lisa19/presentation/gregg-linux** — https://www.usenix.org/conference/lisa19/presentation/gregg-linux (F30, F35)
- 📝🧱 **Vim documentation** — https://www.vim.org/docs.php (F03, F35)

### 18.15 Videos y charlas

- 🎥🧱 **Fireship — 100+ Docker Concepts you Need to Know** — https://www.youtube.com/watch?v=rIrNIzy6U_g (F01, F02, F35)
- 🎥🧱 **Internet Archive — How to use the Wayback Machine** — https://www.youtube.com/watch?v=ts1tu1BiSuY (F35)
- 🎥🧱 **mCoding — Docker Tutorial for Beginners** — https://www.youtube.com/watch?v=b0HMimUb4f0 (F01, F02, F35)
- 🎥🧱 **Philip Roberts / JSConf EU — What the heck is the event loop anyway?** — https://www.youtube.com/watch?v=8aGhZQkoFbQ (F01, F06, F35)
- 🎥🧱 **ProgrammingKnowledge — Docker Tutorial for Beginners - Port Mapping | -p option | Docker EXPOSE Ports** — https://www.youtube.com/watch?v=uYpeaN9sYVw (F08, F35)
- 🎥🧱 **ProgrammingKnowledge — How to Compile and Run C program Using GCC on Ubuntu (Linux)** — https://www.youtube.com/watch?v=oLjN6jAg-sY (F04, F35)
- 🎥🧱 **ProgrammingKnowledge — How to Make a Makefile (C++ / C)** — https://www.youtube.com/watch?v=i3tYp88YHbI (F04, F35)
- 🎥🧱 **ProgrammingKnowledge — Linux Command Line Tutorial For Beginners 1 — Introduction** — https://www.youtube.com/watch?v=YHFzr-akOas (F03, F35)
- 🎥🧱 **TechWorld with Nana — Docker Tutorial for Beginners [FULL COURSE in 3 Hours]** — https://www.youtube.com/watch?v=3c-iBn73dDE (F08, F35)
- 🎥🧱 **The Builder — MakeFile Tutorial** — https://www.youtube.com/watch?v=U1I5UY_vWXI (F04, F35)
- 🎥🧱 **tutoriaLinux — Linux Sysadmin Basics 05 — Package Management with apt-get** — https://www.youtube.com/watch?v=8P-Vek7Vtgg (F03, F35)
- 🎥⚡ **🎥⚡ www.youtube.com/@sigstore** — https://www.youtube.com/@sigstore (F27, F35)
- 🎥🧱 **🎥🧱 www.youtube.com/@cncf** — https://www.youtube.com/@cncf (F27, F35)
- 🎥🧱 **🎥🧱 www.youtube.com/@DockerInc** — https://www.youtube.com/@DockerInc (F24, F27, F35)
- 🎥🧱 **🎥🧱 www.youtube.com/@RedHatDevelopers** — https://www.youtube.com/@RedHatDevelopers (F24, F35)
- 🎥🧱 **🎥🧱 www.youtube.com/watch** — https://www.youtube.com/watch?v=rfscVS0vtbw (F05, F35)
- 🎥🧱 **🎥🧱 www.youtube.com/watch** — https://www.youtube.com/watch?v=DMtFhACPnTY (F06, F35)
- 🎥🧱 **🎥🧱 www.youtube.com/watch** — https://www.youtube.com/watch?v=b4b8ktEV4Bg (F06, F35)
- 🎥🧱 **🎥🧱 www.youtube.com/watch** — https://www.youtube.com/watch?v=Za36qHbrf3g (F07, F24, F35)
- 🎥🧱 **🎥🧱 www.youtube.com/watch** — https://www.youtube.com/watch?v=lYu_Acpjaq0 (F10, F35)
- 🎥🧱 **🎥🧱 www.youtube.com/watch** — https://www.youtube.com/watch?v=cDJrQ4IzZ_M (F21, F35)
- 🎥🧱 **🎥🧱 www.youtube.com/watch** — https://www.youtube.com/watch?v=jtc28pCkN0k (F21, F35)
- 🎥🧱 **🎥🧱 www.youtube.com/watch** — https://www.youtube.com/watch?v=CbmEDXq7es0 (F30, F35)
- 🎥🧱 **🎥🧱 www.youtube.com/watch** — https://www.youtube.com/watch?v=FJW8nGV4jxY (F30, F35)
- 🎥🧱 **🎥🧱 www.youtube.com/watch** — https://www.youtube.com/watch?v=fhBHvsi0Ql0 (F30, F35)

---

## 19. ✅ Checklist editorial para futuras revisiones de F35

- [ ] revisar primero fuentes ⚡
- [ ] comprobar redirecciones o 404 de deep links
- [ ] confirmar que las versiones históricas siguen accesibles
- [ ] actualizar versiones de Docker/Podman/VS Code/WebStorm solo en referencias dinámicas
- [ ] no sustituir URLs históricas por latest sin dejar la referencia antigua
- [ ] revisar cambios de licenciamiento/precios por separado de conceptos técnicos
- [ ] verificar nuevos mecanismos de firma/SBOM/provenance
- [ ] mantener la fecha de revisión visible
- [ ] conservar las fases asociadas a cada referencia
- [ ] registrar nuevas referencias en la categoría temática correcta y no duplicarlas

---

## 20. 🏁 Cierre del curso — por ahora

Después de F00–F34 ya construimos, ejecutamos, validamos, depuramos, comparamos motores, trabajamos con arquitecturas, publicamos el toolchain y diagnosticamos lo que se rompe. F35 agrega una última habilidad: **poder reconstruir el razonamiento cuando el mundo externo cambie**.

No necesitas memorizar cada flag.

Necesitas saber:

```text
qué estás intentando demostrar
qué versión tienes realmente
qué fuente tiene autoridad
qué evidencia pertenece a esa versión
cómo falsar tu hipótesis
cómo dejar el resultado reproducible para el siguiente pobre diablo
```

Ese “siguiente pobre diablo” probablemente seas tú dentro de seis meses. Sé amable con tu yo futuro. 😄

> **Fin provisional del curso base.** Los apéndices, fixtures específicos de frameworks y nuevos laboratorios pueden crecer desde aquí sin cambiar la filosofía central: reproducibilidad, evidencia y comprensión antes que copy/paste.

