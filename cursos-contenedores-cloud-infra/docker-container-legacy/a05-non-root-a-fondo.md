# 👑 Apéndice a05 — Non-root a fondo

> **Curso:** Docker Legacy Node · **Apéndice opcional**
> **Cierra el bucle de:** [F02](02-dockerfile-esencial.md) §7.10 · [F01](01-decisiones-debian-zonas-node.md) §4.5
> **Requisitos:** haber hecho [F09](09-montar-tu-proyecto.md), porque el problema aparece al montar volúmenes
> **Fecha de revisión de documentación externa:** 6 de septiembre de 2026 — `--user`, `--userns` y sus equivalentes en Podman
> **Qué encontrarás:** por qué el laboratorio corre como `root`, qué cuesta esa decisión, qué se rompe exactamente al cambiarla, y cómo hacerlo bien si decides pagar el precio

El curso toma esta decisión en dos líneas y sigue adelante. Aquí está el razonamiento
completo, con lo que se gana y lo que se pierde en cada dirección.

---

## 🧭 Índice de salto rápido

| Si tu pregunta es… | Ve a |
|---|---|
| "¿Por qué root, si todo el mundo dice que está mal?" | [§1](#1--por-qué-el-laboratorio-corre-como-root) |
| "¿Qué riesgo estoy asumiendo de verdad?" | [§2](#2-️-el-precio-de-root-sin-dramatizar) |
| "¿Qué se rompe si cambio a non-root?" | [§3](#3--qué-se-rompe-exactamente) |
| "Quiero hacerlo. ¿Cómo?" | [§4](#4-️-cómo-hacerlo-bien) |
| "¿Y con Podman?" | [§5](#5--podman-cambia-la-conversación) |

---

## 1. 👑 Por qué el laboratorio corre como `root`

Es una decisión deliberada, no un descuido, y no significa "root siempre es mejor".

**APT funciona sin fricción.** `RUN apt-get install ...` no necesita `sudo` ni configuración
adicional. Añadir un usuario intermedio significa instalar `sudo`, configurarlo, y explicar por
qué en cada fase.

**Podemos escribir en las rutas del sistema.** `/opt/node`, `/usr/local/bin` y `/etc` son
exactamente donde el toolchain de [F06](06-instalacion-node.md) y [F08](08-run-el-contenedor-como-proceso.md) instala sus cosas. Con un usuario sin privilegios,
cada una de esas escrituras necesita una decisión y un `chown`.

**Menos fricción con tooling antiguo.** Software de 2018 asume con frecuencia que ciertas rutas
son escribibles durante la instalación. Nuestro objetivo es reproducir un ambiente viejo
introduciendo la **menor cantidad posible de variables nuevas** — y los permisos son una
variable nueva bastante grande.

**Y una razón pedagógica.** Si el primer Dockerfile del curso tuviera que resolver a la vez
UID, GID, `sudo`, ownership de volúmenes y permisos de bind mount, el "hola mundo" de [F02](02-dockerfile-esencial.md)
acabaría necesitando terapia. 😄 El curso va por capas: primero el mecanismo, después el
endurecimiento.

---

## 2. ⚠️ El precio de root, sin dramatizar

Trabajar como root tiene costos reales y conviene nombrarlos.

**Menor principio de mínimo privilegio.** Un proceso comprometido dentro del contenedor tiene
todos los permisos dentro de ese contenedor. En un laboratorio local que no expone servicios,
el riesgo es acotado; no es cero.

**Los archivos que creas salen con dueño `root`.** Es el efecto que más molesta en la práctica
y el que más gente encuentra. Con un bind mount en Linux:

```bash
docker exec legacy-node-dev touch /workspace/generado.txt
ls -la generado.txt     # en tu host
```
```text
-rw-r--r-- 1 root root 0 sep  4 10:22 generado.txt
```

Un archivo que tu usuario del host no puede editar sin `sudo`, creado por un `npm run build`
que ni siquiera sabías que escribía ahí. **[F17](17-usuarios-permisos-y-volumenes.md)** trata esto entero.

> 📝 **En macOS y Windows con Docker Desktop no lo notas**, porque la capa de virtualización
> traduce los UID y todo aparece con tu usuario. Es cómodo y engañoso: el mismo comando en
> Linux nativo o en CI deja archivos de `root`, y ahí es donde el problema aparece — a menudo
> en el peor momento.

**Y la separación que hay que tener clara:** root **dentro** del contenedor no es root en tu
host. Docker aísla esos espacios de usuario. Pero con Docker rootful, el proceso del motor sí
corre como root en el host, y una fuga del contenedor sería grave. Podman rootless cambia esa
ecuación por completo — §5.

---

## 3. 💥 Qué se rompe exactamente

Si añades `USER node` al final del Dockerfile de [F09](09-montar-tu-proyecto.md) y reconstruyes, esto es lo que encuentras,
en el orden en que aparece.

**`npm ci` falla con `EACCES` sobre el named volume.** Es el más inmediato y el menos obvio: un
volumen recién creado pertenece a `root`, y tu usuario no puede escribir en él. El volumen no
hereda el usuario del contenedor.

```text
npm ERR! Error: EACCES: permission denied, mkdir '/workspace/node_modules/.staging'
```

**No puedes instalar nada más con APT.** Cualquier `RUN apt-get install` posterior al `USER`
falla. Se resuelve poniendo el `USER` al final, después de todas las instalaciones — que es
justo lo que hay que recordar.

**`select-node` deja de funcionar.** Modifica symlinks en `/usr/local/bin/`, que pertenece a
root. Los shims de [F08](08-run-el-contenedor-como-proceso.md) **sí** siguen funcionando, porque solo leen: es una de las razones por
las que ese diseño es mejor, y aquí se ve.

**El `$HOME` puede no existir.** Si usas `--user 1000:1000` con un UID que no está en
`/etc/passwd`, el proceso arranca sin directorio home válido, y npm intenta escribir su caché
en `/` — con el `EACCES` correspondiente.

**Herramientas antiguas que asumen escritura.** Algunos paquetes de la época escriben en rutas
del sistema durante su instalación. Cuando ocurre, el error casi nunca menciona los permisos de
forma clara.

---

## 4. 🛠️ Cómo hacerlo bien

Si decides pagar el precio, este es el camino que funciona.

### 4.1 Crear el usuario, al final

```dockerfile
# … todo el toolchain, APT incluido …

ARG APP_UID=1000
ARG APP_GID=1000

RUN groupadd --gid "${APP_GID}" dev \
    && useradd --uid "${APP_UID}" --gid "${APP_GID}" --create-home --shell /bin/bash dev \
    && mkdir -p /workspace \
    && chown -R "${APP_UID}:${APP_GID}" /workspace

USER dev
WORKDIR /workspace
```

Los `ARG` para el UID y el GID no son decorativos: en Linux quieres que **coincidan con los de
tu usuario del host**, porque eso hace que los archivos del bind mount tengan dueño correcto en
los dos lados.

```bash
docker build \
  --build-arg APP_UID="$(id -u)" \
  --build-arg APP_GID="$(id -g)" \
  --platform linux/amd64 -t legacy-node-toolchain:nonroot .
```

### 4.2 Resolver el ownership del volumen

Es el paso que casi todo el mundo olvida. Un volumen recién creado pertenece a `root`, así que
hay que prepararlo **una vez**, desde un contenedor con privilegios:

```bash
docker volume create miproyecto-node10-modules

docker run --rm \
  --mount type=volume,src=miproyecto-node10-modules,dst=/vol \
  legacy-node-toolchain:nonroot-build \
  chown -R 1000:1000 /vol
```

A partir de ahí, el contenedor non-root puede escribir en él.

### 4.3 Alternativa sin reconstruir: `--user`

Si no quieres tocar la imagen, `docker run --user` cambia el usuario al arrancar:

```bash
docker run --rm -it \
  --user "$(id -u):$(id -g)" \
  --mount type=bind,src="$PWD",dst=/workspace \
  legacy-node-toolchain:phase09 bash
```

Es rápido y tiene las trampas de §3: UID sin entrada en `/etc/passwd`, `$HOME` inexistente y el
volumen sin preparar. Para el volumen, la solución es la de §4.2; para el `$HOME`, pasar
`-e HOME=/tmp` suele bastar en un laboratorio.

---

## 5. 🦭 Podman cambia la conversación

Con **Podman rootless**, el motor no corre como root en tu host y los UID del contenedor se
mapean a tu usuario mediante user namespaces. El resultado práctico es que **`root` dentro del
contenedor es tu usuario fuera**, así que buena parte del problema de ownership desaparece
sola.

Podman además tiene una opción que Docker no tiene y que resuelve §4.2 en una palabra:

```bash
podman run --rm \
  --mount type=volume,src=mivol,dst=/vol,U \
  ...
```

Esa `U` le dice a Podman que ajuste el ownership del volumen al usuario del contenedor
automáticamente.

> 🧭 **La comparación seria** —qué gana y qué cuesta cada modelo, con su threat model— está en
> **[F25](25-rootless-y-user-namespaces.md)**. Aquí basta con saber que la respuesta a "¿debo correr non-root?" depende de qué
> motor uses, y que en Podman rootless la pregunta es bastante menos urgente.

---

## 🧭 Guía rápida: cuándo vale la pena

| Tu situación | Recomendación |
|---|---|
| Laboratorio local, Docker Desktop en macOS o Windows | **Quédate en root.** No notarás el problema y añades complejidad sin ganancia |
| Laboratorio local, Linux nativo, y te molestan los archivos de `root` | **`--user "$(id -u):$(id -g)"`** al ejecutar, con el volumen preparado |
| Trabajo en equipo con un repositorio compartido | **Usuario en la imagen con `ARG` de UID/GID**, §4.1 |
| CI, o cualquier cosa que publique la imagen | **Non-root, sin discusión.** Aquí el precio se paga con gusto |
| Podman rootless | **Root dentro del contenedor está bien.** Ya estás aislado por user namespaces |
| Vas a exponer un servicio | Vuelve a leer [F01](01-decisiones-debian-zonas-node.md) §4.5: esta imagen no es para eso |

---

## 🧪 Ejercicios (6)

### 🟢 Ejercicio 1 — El archivo con dueño equivocado

En Linux nativo, crea un archivo desde el contenedor en el bind mount y mira su dueño desde el
host. Repítelo en macOS o Windows si tienes acceso.

**Pregunta:** ¿por qué el resultado es distinto? ¿Cuál de los dos te va a morder en CI?

### 🟢 Ejercicio 2 — `--user` sin preparar nada

Ejecuta el toolbox de [F09](09-montar-tu-proyecto.md) añadiendo `--user "$(id -u):$(id -g)"` e intenta `npm ci`.

**Objetivo:** provocar el `EACCES` del volumen y reconocerlo.

### 🟡 Ejercicio 3 — Prepara el volumen

Aplica §4.2 y repite el ejercicio 2.

**Pregunta:** ¿por qué hizo falta un contenedor con privilegios para arreglar algo que va a usar
un contenedor sin ellos?

### 🟡 Ejercicio 4 — El `USER` en el sitio equivocado

Pon `USER dev` **antes** del `RUN` de APT y construye.

**Objetivo:** ver el fallo y deducir por qué el `USER` va siempre al final.

### 🟠 Ejercicio 5 — Los shims sobreviven, `select-node` no

Con la imagen non-root, prueba `select-node 14.21.3` y después `NODE_VERSION=14.21.3 node --version`.

**Pregunta:** ¿cuál funciona? Relaciónalo con la deuda 💸 que [F08](08-run-el-contenedor-como-proceso.md) pagó y explica por qué el
diseño de los shims era mejor incluso antes de que existiera este problema.

### 🔴 Ejercicio 6 — La imagen non-root completa

Convierte el `Dockerfile` canónico a non-root y valida un fixture completo de [F11](11-validar-tu-proyecto.md) con ella.

**Objetivo:** llegar al final de los ocho pasos del protocolo. Documenta cada cosa que tuviste
que ajustar. Si llegas al nivel 6 sin `sudo` ni `chmod 777`, lo hiciste bien.

---

## 📚 Referencias

- Dockerfile — `USER`: https://docs.docker.com/reference/dockerfile/#user
- Docker — `docker run --user`: https://docs.docker.com/reference/cli/docker-container-run/
- Podman — user namespaces y `:U`: https://docs.podman.io/en/latest/markdown/podman-run.1.html
- Docker — seguridad del daemon: https://docs.docker.com/engine/security/

**Vuelve a:** [F02 §7.10](02-dockerfile-esencial.md) · [F09](09-montar-tu-proyecto.md) · sigue en [F17](17-usuarios-permisos-y-volumenes.md)
