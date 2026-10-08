# 🐳 Docker Legacy Node

> Un laboratorio de contenedores para resucitar proyectos JavaScript de 2018.
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · Node 10.24.1 / 12.22.12 / 14.21.3 / 16.20.2 · npm 6.14.12
> **Arquitecturas:** `linux/amd64` de referencia, `linux/arm64` cubierto aparte
> **Volumen:** 36 fases + 16 apéndices · ~204.000 palabras · 941 ejercicios · 86 archivos en [`src/`](src/)

---

## Qué resuelve

Te dan un repositorio de 2018 —Vue 2, Angular 8, React 16 con `react-scripts@3`— le haces
`npm install` en tu MacBook con Apple Silicon y sale un muro de errores de `node-gyp` sobre un
Python que ya no existe en tu sistema.

El entorno que ese código necesita se extinguió, y tu sistema operativo moderno no puede
resucitarlo sin romper otras cosas. Y hay un caso donde deja de ser molestia y pasa a ser muro:
**Node no publicó binarios `darwin-arm64` hasta la rama 16.x**, así que en un Mac M-algo las
ramas 14, 12 y 10 no se instalan de forma nativa. No existe el archivo.

La regla que ordena el curso entero:

> 🧠 **El contenedor contiene el toolchain, no el proyecto.** Tu código sigue en tu máquina, con
> tu editor y tu Git. En la imagen va la maquinaria para compilarlo.

---

## Para quién es

Desarrolladores con al menos un lenguaje encima y nociones de terminal. **No** se asume Docker
previo: la Parte I lo enseña desde `docker --version`. Sí se asume que sabes qué es `npm install`
y que tienes un proyecto legacy real —o ganas de usar uno de los cinco fixtures del curso.

Si ya sabes Docker, la ruta *"Ya sé Docker, vine por el legacy"* del
[programa](0-programa-del-curso.md) te ahorra ocho fases.

---

## Cómo está organizado

El curso son dos preguntas distintas, y puedes venir solo a la primera.

| | Fases | Palabras | Ejercicios | Estimado |
|---|---|---|---|---|
| **[Parte I — Taller](00-PARTE-I-taller.md)** | 12 · [F00](00-problema-y-contrato.md)–[F11](11-validar-tu-proyecto.md) | ~51.500 | 255 | ~31 h |
| **[Parte II — Laboratorio](00-PARTE-II-laboratorio.md)** | 24 · [F12](12-capas-cache-y-contexto.md)–[F35](35-referencias.md) | ~117.000 | 595 | ~83 h |
| **Apéndices** · [a01](a01-debian-y-apt-a-fondo.md)–[a16](a16-glosario.md) | 16 | ~30.000 | 91 | consulta |

**[Parte I — Taller](00-PARTE-I-taller.md).** El camino entero desde una máquina limpia hasta tu
proyecto haciendo `npm ci`, `build`, `test`, `start` y el debugger de VS Code conectado. Es un
curso completo por sí solo: no es una introducción ni un resumen. Lo que no lleva es el porqué.

**[Parte II — Laboratorio](00-PARTE-II-laboratorio.md).** Abre por dentro lo que la Parte I te
hizo usar: capas y [OverlayFS](13-overlayfs-y-copy-on-write.md),
[ABI y libc](14-abi-libc-y-prebuilds.md), [PID 1 y señales](16-pid1-senales-y-ciclo-de-vida.md),
[namespaces y rootless](25-rootless-y-user-namespaces.md),
[QEMU y multiarquitectura](21-arquitecturas-y-emulacion.md),
[manifests OCI y registries](27-registries-por-dentro.md),
[supply chain](29-supply-chain-sbom-firma.md), y un catálogo de fallos
—[I](31-catalogo-de-fallos-i.md) y [II](32-catalogo-de-fallos-ii.md)— con
[método forense](33-forense-y-boss-fight.md). Cierra con un
[proyecto final](34-proyecto-final.md) evaluado sobre 100 puntos.

**Apéndices.** Todos opcionales, ninguno es requisito de ninguna fase. Ahí vive lo exhaustivo:
[Debian y APT a fondo](a01-debian-y-apt-a-fondo.md), [WebStorm](a06-webstorm.md),
[Colima](a07-colima-y-lima.md), [Windows/PowerShell](a08-windows-y-powershell.md),
[Compose](a10-docker-compose.md), [Harbor](a12-harbor.md),
[air-gapped](a13-air-gapped.md), [CI](a14-ci-github-actions.md),
[chuleta de comandos](a15-chuleta-de-comandos.md) y [glosario](a16-glosario.md).

---

## Por dónde empezar

👉 **[`0-programa-del-curso.md`](0-programa-del-curso.md)** — el índice completo, con las seis
rutas de lectura por perfil. Si solo abres un archivo, que sea ese.

Si tienes prisa y un proyecto roto:

```text
F00 → F01 → F02 → F03 → F06 → F07 → F08 → F11
```

[F00](00-problema-y-contrato.md) · [F01](01-decisiones-debian-zonas-node.md) ·
[F02](02-dockerfile-esencial.md) · [F03](03-apt-y-utilidades.md) ·
[F06](06-instalacion-node.md) · [F07](07-build-de-la-imagen.md) ·
[F08](08-run-el-contenedor-como-proceso.md) · [F11](11-validar-tu-proyecto.md)

Ocho fases, ~34.000 palabras, y al final tu proyecto compila. Si `npm ci` falla en
[F11](11-validar-tu-proyecto.md) por una dependencia nativa, vuelves a
[F04](04-toolchain-de-compilacion.md) y [F05](05-python-y-node-gyp.md) — que era justo lo que te
faltaba.

Y si lo que se rompió es urgente, el atajo es otro:
[F30](30-troubleshooting-metodo-y-herramientas.md) trae un protocolo de sesenta segundos, y los
catálogos [F31](31-catalogo-de-fallos-i.md) y [F32](32-catalogo-de-fallos-ii.md) están ordenados
por síntoma para que busques el mensaje de error literal.

---

## Cómo se estudia

Cada fase práctica trae **entre 20 y 30 ejercicios obligatorios** —la cifra la fija lo que la
fase enseña, no su longitud—, en escala 🟢🟡🟠🔴 y con el reparto calibrado fase por fase. Encima
van los extra 🔥 y un 💀 *boss fight*, que no cuentan para el mínimo. No son de relleno: tienen
criterio de éxito verificable —un comando que debe devolver algo concreto, no "haz una cosa"— y
**al menos un tercio son de diagnóstico**: se te entrega algo roto y tienes que reproducirlo,
situarlo y explicarlo.

El código ejecutable vive en [`src/`](src/), un directorio por fase que lo necesita, con los
[once Dockerfiles consolidados](src/all-dockerfiles/) para leerlos seguidos y los cinco fixtures
—Node liso, Vue 2, Angular 8, React 16, Svelte 3— con los que puedes hacer el curso si no tienes
un proyecto propio a mano.

> ⚠️ **Esto no es una imagen para producción, y el curso lo repite sin adornos.** Debian 10,
> Node 10–16 y Python 2 están fuera de soporte: sin parches y con los repositorios movidos al
> archivo. Es un laboratorio de mantenimiento local, y la honestidad sobre eso es parte del
> contenido, no una nota al pie.

---

## Qué está verificado, y qué no

El curso mide en lugar de suponer, y declara la diferencia. Ocho documentos llevan en su cabecera
una **fecha de verificación ejecutada**, con la salida real pegada debajo:
[F12](12-capas-cache-y-contexto.md), [F13](13-overlayfs-y-copy-on-write.md),
[F14](14-abi-libc-y-prebuilds.md), [F15](15-laboratorios-dependencias-nativas.md),
[F16](16-pid1-senales-y-ciclo-de-vida.md), [F20](20-validacion-sistematica-y-evidencia.md),
[F21](21-arquitecturas-y-emulacion.md) y [F27](27-registries-por-dentro.md).

Y lo que **no** está verificado también se dice: los comandos `podman` de
[F24](24-docker-y-podman-arquitectura.md), [F25](25-rootless-y-user-namespaces.md) y
[F26](26-portabilidad-entre-motores.md) están contrastados contra la documentación oficial pero
**no ejecutados**, y sus cabeceras lo declaran.

---

## Estándares editoriales

Prosa en español latinoamericano neutro con tuteo; **código, identificadores y APIs en inglés**,
comentarios de código en español. Los diagramas de arquitectura y de flujo están en Mermaid, que
GitHub dibuja directamente; los árboles de archivos, las salidas de terminal y las fichas de cierre
de cada fase siguen en texto plano, porque así se leen y se copian mejor.
