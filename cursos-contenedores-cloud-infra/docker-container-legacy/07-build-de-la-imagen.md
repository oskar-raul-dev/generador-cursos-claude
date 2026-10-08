# 🏗️ Parte I · Fase 07 — Build: construir la imagen sin tratar la caché como magia negra

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`)
> **Arquitectura objetivo del laboratorio:** `linux/amd64`
> **Dockerfile canónico:** nace en esta fase, en la raíz del laboratorio
> **Dockerfile pedagógico de esta fase:** `dockerfiles/06-build.Dockerfile`
> **Tag pedagógico:** `legacy-node-toolchain:phase07`
> **Estado de la imagen al terminar:** el mismo toolchain de [F06](06-instalacion-node.md), pero ahora construido desde el `Dockerfile` canónico, con `.dockerignore` y un flujo de build reproducible
> **Código de esta fase:** [`src/07-build-de-la-imagen/`](src/07-build-de-la-imagen/)
> **Fecha de revisión de documentación externa:** 6 de septiembre de 2026 — Buildx y la referencia de `docker build`
> **Objetivo:** entender qué es realmente un build, qué es el build context y por qué ese `.` final es el argumento más caro de ignorar

---

## 1. 🧭 Dónde estamos

El toolchain está completo: Debian 10, utilidades, GCC, Python y cuatro generaciones de
Node. Hemos ejecutado `docker build` cinco veces sin explicar del todo qué hace.

Esta fase cierra esa deuda. No añade software a la imagen: **añade entendimiento sobre cómo
se produce**. Y nace el `Dockerfile` canónico, el que representa el laboratorio de verdad.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder explicar:

- Qué hace un **builder** y por qué un build no es "arrancar un contenedor".
- Las cuatro piezas que hay que separar mentalmente: Dockerfile, build context, opciones y
  resultado.
- Qué es el **build context**, qué frontera define y por qué `COPY ../algo` no funciona.
- Por qué `-f` **no** cambia el contexto.
- Para qué sirve `.dockerignore` y qué cuesta olvidarlo.
- Qué son BuildKit y Buildx, en versión introductoria.
- El flujo de build recomendado del curso.

---

## 3. 🚧 Qué NO entra todavía

Esta fase enseña a construir; la mecánica interna es de la Parte II:

- **La caché en profundidad**, las capas por dentro, tags frente a IDs frente a digests,
  reproducibilidad y build args a fondo → **[F12](12-capas-cache-y-contexto.md)**.
- **Cómo se montan las capas en runtime**, `lowerdir`, `upperdir`, whiteouts, y por qué
  borrar un archivo puede agrandar la imagen → **[F13](13-overlayfs-y-copy-on-write.md)**.
- **Multi-stage builds** de verdad → mencionados aquí, usados en **F12**.
- La construcción **multiarquitectura** con Buildx y QEMU → **[F21](21-arquitecturas-y-emulacion.md)**.
- El **troubleshooting de build** completo → **[F31](31-catalogo-de-fallos-i.md)**.

---

## 4. 🧠 Qué es realmente un build

Cuando ejecutas `docker build` no estás arrancando un contenedor normal. Estás pidiéndole a
un **builder** que procese una definición de construcción y produzca un resultado.

```mermaid
flowchart TD
    D["Dockerfile<br/>la receta"] --> C["Build context<br/>los archivos que el builder puede ver"]
    C --> O["Opciones<br/>--platform, --tag, --build-arg, --no-cache…"]
    O --> B["Builder<br/>BuildKit (Docker) · Buildah (Podman)"]
    B --> R["Resultado<br/>una imagen — pero no necesariamente"]
```

Esa última línea importa más de lo que parece: **el build es un proceso y la imagen es uno de
sus posibles resultados**. Un build puede producir también un tarball, un manifest
multiplataforma, o simplemente el ejecutar unas pruebas y no dejar nada. Verlo así evita
pensar que `docker build` y "hacer una imagen" son sinónimos.

Las cuatro piezas conviene separarlas mentalmente porque cada una se rompe distinto:

| Pieza | Qué es | Cómo se rompe típicamente |
|---|---|---|
| **Dockerfile** | la receta, texto | sintaxis, orden de instrucciones, instrucción mal entendida |
| **Build context** | los archivos visibles al builder | el archivo que quieres copiar está fuera; o mandas 2 GB sin querer |
| **Opciones** | `--platform`, `--tag`, `--build-arg` | arquitectura equivocada, arg que no llega, tag que se pisa |
| **Builder** | BuildKit o Buildah | caché, drivers, diferencias entre motores |

---

## 5. 📁 El build context: ese `.` que todo el mundo ignora

En el comando que llevas usando desde [F02](02-dockerfile-esencial.md):

```bash
docker build --platform linux/amd64 -f dockerfiles/05-node.Dockerfile -t legacy-node-toolchain:phase06 .
```

ese punto final **no significa "terminó el comando"**. Es un argumento real, y dice: *usa el
directorio actual como contexto de construcción*.

El build context es el conjunto de archivos a los que el builder tiene acceso. Y define una
**frontera de entrada**:

```text
/home/me/
├── secreto.txt          ← FUERA del contexto
└── proyecto/            ← contexto (ejecutas docker build aquí, con .)
    ├── Dockerfile
    └── scripts/
```

Desde `/home/me/proyecto`, un `COPY ../secreto.txt /tmp/` **no funciona**, y eso es una
característica de seguridad, no una limitación molesta. Sin esa frontera, cualquier
Dockerfile podría leer lo que quisiera de tu disco.

> ⚠️ **`-f` no cambia el contexto.** Son dos decisiones independientes: `-f
> dockerfiles/06-build.Dockerfile` dice *qué receta usar*, y el `.` dice *desde dónde se ve
> el mundo*. Confundirlas produce el error más frecuente del principio: mover el Dockerfile a
> un subdirectorio y descubrir que ya no encuentra los archivos que copiaba.

### 5.1 Lo que cuesta un contexto grande

Cuando lanzas el build, **el cliente empaqueta el contexto y se lo envía al builder**. Si tu
directorio tiene un `node_modules` de 400 MB y un `.git` de 200 MB, eso viaja entero antes de
que se ejecute la primera instrucción — aunque el Dockerfile no copie ni un archivo.

Y hay un problema peor que la lentitud:

> 🚨 **Un contexto grande es también una fuga potencial.** Todo lo que está en el contexto es
> accesible para el build. Un `.env` con credenciales, una clave SSH o un dump de base de
> datos que estén ahí pueden acabar dentro de la imagen con un `COPY . .` distraído — y en
> ese momento viajan con la imagen a cualquier registry donde la publiques. **[F13](13-overlayfs-y-copy-on-write.md)** te va a
> enseñar algo aún más incómodo: borrarlos en una capa posterior **no** los saca de la
> imagen.

---

## 6. 🙈 `.dockerignore`

La solución a las dos cosas anteriores es un archivo con la misma sintaxis que `.gitignore`,
que le dice al cliente qué **no** empaquetar.

📄 **`.dockerignore`**

```dockerignore
# Control de versiones
.git
.gitignore

# Dependencias locales del host — nunca deben entrar en el build
node_modules
**/node_modules

# Builds y cobertura
dist
**/dist
build
**/build
coverage
**/coverage

# Logs y temporales
*.log
tmp
**/tmp
.cache
**/.cache

# Configuración de editores y del sistema operativo
.idea
.vscode
.DS_Store
Thumbs.db

# Laboratorios y experimentos del curso
labs
experimentos
```

**Por qué excluimos `.git`.** Contiene el historial completo del repositorio: puede pesar más
que el código, y guarda **todo lo que alguna vez estuvo commiteado**, incluidas las
credenciales que alguien borró en un commit posterior creyendo que las había eliminado.

**Por qué excluimos `node_modules`.** Por la razón de [F01](01-decisiones-debian-zonas-node.md): son binarios compilados para el
sistema del host. Que entren en el contexto es, en el mejor de los casos, medio gigabyte de
transferencia inútil; en el peor, un `COPY` que mete módulos de macOS en una imagen de Linux.

**Por qué excluimos `labs` y `experimentos`.** Son los directorios donde este curso te va a
pedir que rompas cosas a propósito. No tienen por qué viajar al builder.

> 💡 **Negaciones con `!`.** Igual que en `.gitignore`, puedes reincluir algo excluido:
> `dist` seguido de `!dist/keep-me.txt`. Úsalo con moderación: un `.dockerignore` con muchas
> negaciones se vuelve difícil de razonar.

---

## 7. 📄 Nace el `Dockerfile` canónico

Hasta ahora cada fase tenía su Dockerfile pedagógico numerado. Eso sigue: se acumulan y no
se sustituyen. Pero el laboratorio necesita **un** archivo que represente el estado actual, y
ese es el `Dockerfile` de la raíz.

```text
legacy-node-toolchain-lab/
├── Dockerfile                          ← 🆕 canónico. El que se construye de verdad
├── .dockerignore                       ← 🆕 completo
├── dockerfiles/
│   ├── 01-hola-mundo.Dockerfile        ← F02
│   ├── 02-utilidades.Dockerfile        ← F03
│   ├── 03-toolchain.Dockerfile         ← F04
│   ├── 04-python-node-gyp.Dockerfile   ← F05
│   ├── 05-node.Dockerfile              ← F06
│   └── 06-build.Dockerfile             ← F07, copia pedagógica del canónico
└── scripts/
    └── select-node
```

Su contenido es, ahora mismo, **idéntico al de `05-node.Dockerfile`**. Esta fase no añade
software: promueve el archivo. A partir de aquí, cuando el curso diga "reconstruye la
imagen", se refiere al canónico.

> 🧭 **Por qué dos archivos con el mismo contenido.** El canónico avanza con el laboratorio y
> siempre refleja el estado actual. Los pedagógicos son fotografías: `03-toolchain.Dockerfile`
> va a seguir mostrando la imagen sin Node dentro de veinte fases, y eso permite reconstruir
> cualquier punto del recorrido para comparar. La duplicación es deliberada.

> ⚠️ **Nota de la reestructuración.** En la versión anterior de este curso, el Dockerfile
> canónico nacía **después** del capítulo de dependencias nativas y arrastraba una veintena de
> librerías del sistema —`libcairo2-dev`, `libgtk-3-0`, `libnss3`, `sqlite3`…— para `canvas`,
> `sqlite3` y Puppeteer. En la estructura actual esas librerías pertenecen a la Parte II, donde
> se estudian con su porqué: el canónico **no las lleva** y las incorpora **[F15](15-laboratorios-dependencias-nativas.md)** cuando toca.
> El camino mínimo de la Parte I no las necesita.

Construir el canónico es más corto, porque ya no hace falta `-f`:

```bash
docker build \
  --platform linux/amd64 \
  --tag legacy-node-toolchain:phase07 \
  .
```

Sin `-f`, el builder busca un archivo llamado `Dockerfile` en la raíz del contexto. Es la
convención, y por eso el canónico se llama así.

---

## 8. ⚡ BuildKit y Buildx, en versión corta

**BuildKit** es el motor de construcción moderno de Docker, y es el que ejecuta tus builds
desde hace años aunque escribas `docker build`. Frente al builder clásico trae paralelismo
—instrucciones independientes se construyen a la vez—, una caché más inteligente, salida
mejor organizada y funciones nuevas como los *cache mounts* y los *secrets*.

Es también lo que hace que la primera línea `# syntax=docker/dockerfile:1` de nuestros
archivos tenga sentido: le dice a BuildKit qué versión del frontend de Dockerfile usar.

**Buildx** es la CLI que expone las capacidades avanzadas de BuildKit: constructores
separados, salida a distintos destinos y —lo que nos importará de verdad— construcción
multiplataforma.

```bash
docker buildx version
docker buildx ls          # qué constructores tienes disponibles
```

Con Buildx hay un detalle que confunde a mucha gente:

```bash
docker buildx build --platform linux/amd64 --load -t legacy-node-toolchain:phase07 .
```

**`--load`** es lo que trae la imagen resultante a tu almacén local. Sin él, un build de
Buildx puede terminar correctamente y dejarte con un `docker image ls` donde no aparece nada
— porque el resultado se quedó en la caché del constructor. Es un ejercicio de esta fase
justamente porque desconcierta.

**Multi-stage builds**, otra capacidad de BuildKit, permiten usar varias etapas `FROM` y
copiar solo lo necesario de una a otra. Es la técnica estándar para reducir imágenes de
producción. Aquí la mencionamos y no la usamos, y la razón es honesta: **nuestro objetivo no
es una imagen pequeña, es un toolchain de desarrollo completo**. Descartar el compilador
después de construir sería exactamente lo contrario de lo que queremos. **[F12](12-capas-cache-y-contexto.md)** la usa para
un caso donde sí aporta.

> 🦭 **Podman construye con Buildah**, no con BuildKit. El Dockerfile es el mismo y
> `podman build` funciona igual para lo que hacemos aquí, pero la caché, los drivers y las
> extensiones de BuildKit no son idénticas. **[F24](24-docker-y-podman-arquitectura.md)** compara los dos constructores en serio;
> hasta entonces, si algo funciona en uno y no en el otro, esa fase es la respuesta.

---

## 9. 🔥 El flujo de build recomendado

Cuatro pasos que conviene convertir en rutina.

**1. Construye con tag explícito y plataforma explícita.** Nunca `latest`, siempre
`--platform`:

```bash
docker build --platform linux/amd64 -t legacy-node-toolchain:phase07 .
```

**2. Lee la salida en lugar de esperar a que termine.** Con `--progress=plain` obtienes la
traza completa en lugar del resumen compacto, y eso es lo que quieres cuando algo falla:

```bash
docker build --platform linux/amd64 --progress=plain -t legacy-node-toolchain:phase07 .
```

**3. Verifica lo que construiste**, sin dar por hecho que el build correcto implica la imagen
correcta:

```bash
docker image inspect legacy-node-toolchain:phase07 \
  --format '{{.Architecture}} · {{.Os}} · {{.Config.WorkingDir}} · {{index .Config.Labels "org.opencontainers.image.title"}}'
```
```text
amd64 · linux · /workspace · legacy-node-toolchain
```

**4. Prueba de humo**, siempre la misma, siempre después de construir:

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase07 \
  bash -c 'node --version; npm --version; gcc --version | head -1; python2 --version; python3 --version'
```
```text
v10.24.1
6.14.12
gcc (Debian 8.3.0-6) 8.3.0
Python 2.7.16
Python 3.7.3
```

> 🔥 **Prueba de fuego de la fase.** Reconstruye sin cambiar nada y observa la salida: casi
> todos los pasos deben decir `CACHED` y el build entero debe tardar segundos. Después toca
> una sola línea del `LABEL` de descripción y reconstruye. **Predice qué pasos se invalidan
> antes de mirar.** Si tu predicción falla, tienes un modelo mental que arreglar — y **[F12](12-capas-cache-y-contexto.md)**
> es donde se arregla.

---

## 10. ⚠️ Errores comunes y diagnóstico

**`ERROR: failed to solve: failed to read dockerfile: open Dockerfile: no such file or
directory`.** No hay `Dockerfile` en el contexto y no pasaste `-f`. Comprueba con `pwd` y
`ls`.

**`COPY failed: file not found in build context`.** El archivo existe en tu disco pero está
fuera del contexto, o lo está excluyendo tu `.dockerignore`. Las dos causas dan el mismo
mensaje, y la segunda es la que más tiempo hace perder: comprueba tu `.dockerignore` antes de
volverte loco con las rutas.

**El build tarda una eternidad en "sending build context".** Tu contexto pesa. Mira qué estás
mandando y arregla el `.dockerignore`. Si el número que aparece ahí supera unos pocos
megabytes en este laboratorio, algo se coló.

**`buildx` termina bien pero `docker image ls` no muestra la imagen.** Falta `--load`. §8.

**Cambiaste el Dockerfile y el build no refleja el cambio.** Es la caché. `--no-cache` fuerza
un build limpio, pero antes de usarlo conviene entender **por qué** se reutilizó esa capa —
`--no-cache` es un martillo y **[F12](12-capas-cache-y-contexto.md)** te da el destornillador.

**El build funciona en tu máquina y falla en la de un compañero.** Sospecha del contexto, no
del Dockerfile: `.dockerignore` distinto, un archivo sin commitear, o la ruta desde la que
cada uno ejecuta el comando.

---

## 11. 📋 Checklist de validación

```text
[ ] Existe Dockerfile en la raíz del laboratorio
[ ] Existe .dockerignore con las exclusiones de §6
[ ] Existe dockerfiles/06-build.Dockerfile como copia pedagógica
[ ] docker build --platform linux/amd64 -t legacy-node-toolchain:phase07 .  funciona sin -f
[ ] La línea de contexto del build reporta un tamaño pequeño (pocos MB, no cientos)
[ ] docker image inspect confirma amd64 · linux · /workspace
[ ] La prueba de humo de §9 imprime las cinco versiones
[ ] Un segundo build sin cambios dice CACHED en casi todos los pasos
[ ] Puedes explicar qué hace el `.` final y por qué -f no lo cambia
[ ] Sabes qué pasa si olvidas --load con buildx
```

---

## 12. 🧪 Ejercicios de la Fase 07 (20)

## 🟢 Fácil — construir y mirar (1–6)

### 🟢 Ejercicio 1 — Promueve el canónico y construye

Crea el `Dockerfile` de la raíz, el `.dockerignore` de §6 y construye `phase07` sin usar
`-f`. Pasa la prueba de humo.

**Objetivo:** tener el laboratorio con su estructura definitiva.

### 🟢 Ejercicio 2 — Mide tu contexto

Ejecuta el build con `--progress=plain` y localiza la línea que reporta el tamaño del
contexto. Después renombra temporalmente `.dockerignore` y repite.

**Pregunta:** ¿cuánto creció? ¿Qué directorio era el culpable?

### 🟢 Ejercicio 3 — El punto es un argumento

Ejecuta `docker build --platform linux/amd64 -t prueba:v1` sin el `.` final.

**Objetivo:** leer el error y confirmar que el punto no es decorativo.

### 🟢 Ejercicio 4 — `-f` no cambia el contexto

Desde la raíz, construye con `-f dockerfiles/01-hola-mundo.Dockerfile .`. Después
**entra** en `dockerfiles/` e intenta `docker build -f 01-hola-mundo.Dockerfile .`.

**Pregunta:** ¿funcionan los dos? ¿Qué cambia entre ellos y por qué importaría si el
Dockerfile copiara archivos?

### 🟢 Ejercicio 5 — Inspecciona lo que construiste

Ejecuta el `docker image inspect --format` de §9 sobre `phase07` y sobre `phase02`.

**Pregunta:** ¿en qué se diferencian los metadatos, y qué campo te diría si construiste para
la arquitectura equivocada?

### 🟢 Ejercicio 6 — `docker image history`

Ejecuta `docker image history legacy-node-toolchain:phase07`.

**Pregunta:** ¿cuántas capas tiene? ¿Cuál es la más grande y por qué no te sorprende?

## 🟡 Intermedio — la caché y el contexto (7–13)

### 🟡 Ejercicio 7 — Fuera del contexto

Añade `COPY ../algo.txt /tmp/` al Dockerfile y construye.

**Objetivo:** ver el error de frontera de §5 y entender que es una protección.

### 🟡 Ejercicio 8 — Segundo build, todo cacheado

Construye dos veces seguidas sin cambiar nada y cronometra las dos.

**Pregunta:** ¿qué proporción del tiempo se ahorró, y qué pasos no dijeron `CACHED`?

### 🟡 Ejercicio 9 — Predice la invalidación

Antes de ejecutar nada, **predice** qué pasos se invalidan en cada caso: (a) cambias el
`LABEL` de descripción; (b) añades un paquete al `RUN` de APT; (c) cambias
`DEFAULT_NODE_VERSION`; (d) editas `scripts/select-node`. Después compruébalo.

**Objetivo:** descubrir dónde falla tu modelo mental de la caché, que es el propósito de [F12](12-capas-cache-y-contexto.md).

### 🟡 Ejercicio 10 — El `.dockerignore` que te muerde

Añade `scripts` a tu `.dockerignore` y reconstruye.

**Objetivo:** provocar un `COPY failed` cuyo mensaje no menciona el `.dockerignore` en ningún
momento. Es una de las causas más difíciles de ver del curso.

### 🟡 Ejercicio 11 — `--progress=plain` frente al resumen

Construye con `--no-cache` las dos veces: una con la salida por defecto y otra con
`--progress=plain`.

**Objetivo:** decidir cuál quieres tener a mano cuando algo falle, y por qué.

### 🟡 Ejercicio 12 — Construye con Podman

Construye el canónico con `podman build` y compara la salida y el tiempo.

**Pregunta:** ¿qué diferencias notas en el formato de la salida? ¿Produjo una imagen
equivalente? Comprueba con `podman image inspect`.

### 🟡 Ejercicio 13 — Dos tags, una imagen

Construye con `-t legacy-node-toolchain:phase07` y después vuelve a construir, sin cambios,
con `-t legacy-node-toolchain:probando`.

**Pregunta:** mira los `IMAGE ID`. ¿Cuántas imágenes hay realmente? ¿Qué es entonces un tag?

## 🟠 Difícil — diagnosticar el build (14–17)

### 🟠 Ejercicio 14 — Buildx sin `--load`

Construye con `docker buildx build` **sin** `--load` y después ejecuta `docker image ls`.

**Pregunta:** ¿dónde está la imagen? Vuelve a construir con `--load` y compara.

### 🟠 Ejercicio 15 — El secreto que viaja

Crea un `.env` con una cadena reconocible en la raíz del laboratorio, **quítalo** del
`.dockerignore`, añade `COPY . /tmp/ctx/` al Dockerfile y construye. Después busca la cadena
dentro de la imagen.

**Objetivo:** comprobar de primera mano lo de §5.1. Guarda esta imagen: en **[F13](13-overlayfs-y-copy-on-write.md)** vas a
descubrir que borrar el archivo en una capa posterior no lo saca de ahí.

### 🟠 Ejercicio 16 — El build que funciona solo en tu máquina

Construye correctamente el canónico. Después mueve `scripts/select-node` fuera del proyecto y
reconstruye **con la caché activa**. Después reconstruye con `--no-cache`.

**Pregunta:** ¿por qué el primero funcionó y el segundo no? ¿Qué te dice eso sobre confiar en
un build cacheado como prueba de que el repositorio está completo?

### 🟠 Ejercicio 17 — Reconstruye una fase antigua

Usando los Dockerfiles pedagógicos, reconstruye `phase03` y `phase06` y compara sus tamaños y
su número de capas.

**Objetivo:** comprobar el valor de conservar las fotografías, y poner números a lo que costó
cada fase.

## 🔴 Muy difícil — auditoría y criterio (18–20)

### 🔴 Ejercicio 18 — Contexto mínimo

Reorganiza el laboratorio para que el build use un contexto lo más pequeño posible sin perder
nada necesario. Mide el antes y el después.

**Pregunta:** ¿qué necesita de verdad el builder de tu repositorio? La respuesta suele ser
sorprendentemente poco.

### 🔴 Ejercicio 19 — Audita un build ajeno

Busca un proyecto en GitHub con Dockerfile y sin `.dockerignore` — abundan.

**Objetivo:** estimar qué viajaría en su contexto, identificar al menos un archivo que no
debería estar ahí, y escribir el `.dockerignore` que le falta con una línea de justificación
por bloque.

### 🔴 Ejercicio 20 — Defiende no usar multi-stage

Un revisor propone convertir el laboratorio a multi-stage: una etapa que compila y otra final
que solo lleva Node, para reducir la imagen "de 1,2 GB a 200 MB".

**Objetivo:** escribir la respuesta que reconozca que técnicamente tiene razón sobre el
tamaño, y después explique por qué aquí sería un error — con al menos dos escenarios concretos
del curso que dejarían de funcionar. Y termina diciendo **en qué caso** su propuesta sí sería
la correcta, porque ese caso existe.

## 🔥 Opcionales

### 🔥 Ejercicio 21 — Un multi-stage de juguete

Escribe un Dockerfile de dos etapas que compile el `hello.c` de [F04](04-toolchain-de-compilacion.md) en la primera y copie
solo el binario a una segunda etapa basada en `debian/eol:buster`.

**Pregunta:** ¿cuánto ocupa la imagen final frente a la que lleva el compilador? ¿Y funciona
el binario? Comprueba con `ldd`.

### 🔥 Ejercicio 22 — `SOURCE_DATE_EPOCH`

Investiga qué es y construye dos veces la misma imagen fijándolo.

**Pregunta:** ¿obtuviste el mismo digest? Si no, ¿qué más habría que fijar? Guarda las dudas:
son exactamente las de **[F12](12-capas-cache-y-contexto.md)**.

## 💀 Boss fight

### 💀 Ejercicio 23 — Boss fight: el build de 900 MB que debería pesar 2

Te reportan que `docker build` en el laboratorio de un compañero tarda cuatro minutos en la
línea `Sending build context to Docker daemon` antes de ejecutar nada, y que la imagen
resultante contiene su `node_modules` de macOS. Tienes acceso a su directorio.

**Objetivo:** convertirlo en un caso cerrado, con números en las dos puntas. Tienes que:
(1) **medir** el contexto antes de tocar nada —`du -sh`, y el tamaño que reporta el propio
build— y decir cuáles son los tres directorios que se llevan el 95%; (2) explicar por qué
`.git` y `node_modules` son problemas **distintos**, uno de tamaño y otro de corrección, con
la razón de §6 para cada uno; (3) escribir el `.dockerignore` que resuelve ambos y **volver a
medir**, dando la reducción en MB y en segundos; (4) demostrar con `docker build --no-cache
--progress=plain` que el contexto que viaja ahora es el que dices, y no solo confiar en que
el archivo existe; (5) probar que el `node_modules` del host **ya no** entra, buscándolo
dentro de la imagen.

**Pregunta:** tu compañero propone en lugar de todo esto hacer `COPY package.json .` y
`COPY src/ .` para "copiar solo lo necesario". ¿Resuelve el problema? Contesta separando
las dos cosas que §5 separa —lo que **viaja** y lo que se **copia**— y di qué arregla su
propuesta y qué deja exactamente igual.

---

## 13. 📚 Referencias

**Build y contexto**
- Conceptos de build: https://docs.docker.com/build/concepts/overview/
- Build context: https://docs.docker.com/build/concepts/context/
- `.dockerignore`: https://docs.docker.com/build/concepts/context/#dockerignore-files
- Referencia de `docker build`: https://docs.docker.com/reference/cli/docker-buildx-build/

**BuildKit y Buildx**
- BuildKit: https://docs.docker.com/build/buildkit/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/

**Podman**
- `podman build`: https://docs.podman.io/en/latest/markdown/podman-build.1.html
- Buildah: https://buildah.io/

> ⚠️ **La documentación de Docker describe la versión actual del builder.** Casi todo lo de
> esta fase es estable desde hace años, pero la salida exacta de los comandos y algunas
> banderas de Buildx han cambiado. Fecha de revisión de estos enlaces: 3 de septiembre de
> 2026.

**Orden de lectura sugerido:** *Build context* primero, que es el concepto que más se
malentiende; el resto cuando los ejercicios lo pidan.

---

## 14. 🏁 Resultado de la fase

```text
ESTRUCTURA    Dockerfile              ← canónico, en la raíz
              .dockerignore           ← completo
              dockerfiles/01…06       ← fotografías por fase
              scripts/select-node

IMAGEN        legacy-node-toolchain:phase07
              contenido idéntico a phase06 — esta fase no añade software
              construida desde el canónico, sin -f

SABES         qué hace un builder y qué son las cuatro piezas
              qué es el build context y qué frontera define
              por qué -f no cambia el contexto
              qué cuesta un contexto grande, en tiempo y en riesgo
              qué son BuildKit y Buildx, y qué hace --load
              el flujo de build recomendado, en cuatro pasos
```

> **La señal de que quedó bien:** *"antes de ejecutar `docker build` sé exactamente qué
> archivos van a viajar al builder, y si algo no aparece dentro de la imagen sé si mirar el
> Dockerfile o el `.dockerignore`."*

En **[F08](08-run-el-contenedor-como-proceso.md)** dejamos de construir y empezamos a ejecutar: `docker run`, `ENTRYPOINT`, `CMD`, y
el despachador que paga la deuda 💸 que dejó `select-node`.
