# 🐳 Parte I · Fase 02 — Dockerfile: las instrucciones esenciales

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`)
> **Arquitectura objetivo del laboratorio:** `linux/amd64`
> **Dockerfile pedagógico de esta fase:** `dockerfiles/01-hola-mundo.Dockerfile`
> **Tag pedagógico:** `legacy-node-toolchain:phase02`
> **Estado de la imagen al terminar:** mínima funcional — Debian 10 y nada más. Sin Node, sin Python, sin compiladores
> **Código de esta fase:** [`src/02-dockerfile-esencial/`](src/02-dockerfile-esencial/)
> **Fecha de revisión de documentación externa:** 6 de septiembre de 2026 — la CLI de Docker y la referencia de Dockerfile
> **Objetivo:** entender qué es un Dockerfile, qué instrucciones vamos a usar durante todo el curso, y construir la primera imagen del laboratorio sin copiar una sola línea a ciegas

---

## 1. 🧭 Dónde estamos

[F00](00-problema-y-contrato.md) fijó el contrato y [F01](01-decisiones-debian-zonas-node.md) cerró las decisiones. Sabemos que la base es `debian/eol:buster`,
que el código vive en el host y entra por bind mount a `/workspace`, que `node_modules` va
en un named volume, y que necesitamos cuatro generaciones de Node.

Lo que falta es el archivo que describe **cómo se construye** esa imagen. Ese archivo es el
**Dockerfile**, y esta fase va de entenderlo.

No vamos a fabricar de golpe el monstruo completo con Node, Python, GCC, `node-gyp`,
librerías nativas y media arqueología de 2018. 😄 Vamos a empezar pequeño. Muy pequeño: el
primer Dockerfile del curso será el equivalente a un "hola mundo", y crecerá una fase por
vez hasta el toolchain final.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder explicar con tus palabras:

- Qué es un Dockerfile y en qué se diferencia de una imagen y de un contenedor.
- Qué significan **build time** y **runtime**, y por qué confundirlos causa la mitad de los
  problemas del principio.
- Para qué sirven `FROM`, `RUN`, `CMD`, `ENTRYPOINT`, `WORKDIR`, `COPY`, `ADD`, `ARG`, `ENV`,
  `LABEL` y `USER`.
- Cuándo usar forma shell y cuándo forma exec, y qué tiene que ver eso con las señales.
- Qué es la convención incremental `dockerfiles/NN-tema.Dockerfile` y por qué la usamos.

Y sobre todo, el criterio que atraviesa el curso: **no deberías necesitar copiar un
Dockerfile sin entender qué hace cada línea.**

---

## 3. 🚧 Qué NO entra todavía

Esta fase enseña el vocabulario, no la construcción industrial. Quedan fuera, con destino:

- El **build context**, el `.dockerignore` y qué significa realmente el `.` final → **[F07](07-build-de-la-imagen.md)**.
- Las **capas**, la **caché** y por qué el orden de las instrucciones es una estrategia →
  **[F12](12-capas-cache-y-contexto.md)**, con su mecánica de montaje en **[F13](13-overlayfs-y-copy-on-write.md)**.
- Root frente a **non-root**: por qué empezamos como `root` y qué costaría cambiarlo →
  **[a05](a05-non-root-a-fondo.md)**.
- `--platform` en profundidad y la construcción multiarquitectura → **[F21](21-arquitecturas-y-emulacion.md)**.
- Multi-stage builds → mencionados en **F07**, usados en **F12**.

---

## 4. 🧱 Dockerfile, imagen y contenedor son tres cosas distintas

Es la confusión más común al empezar, y arrastrarla hace que todo lo demás parezca
arbitrario. Las tres cosas existen en momentos diferentes:

```mermaid
flowchart LR
    D["Dockerfile<br/>texto · receta<br/>editas con vim"] -- "docker build" --> I["imagen<br/>artefacto inmutable<br/>se guarda en tu disco"]
    I -- "docker run" --> C["contenedor<br/>proceso en ejecución<br/>arranca, vive, muere"]
```

El **Dockerfile** es una receta de construcción. Es texto plano, no una máquina virtual ni
un contenedor:

```dockerfile
FROM debian/eol:buster
CMD ["/bin/echo", "Hola"]
```

La **imagen** es el resultado de ejecutar esa receta: un artefacto inmutable, con un
filesystem y un montón de metadatos, que se queda guardado en tu máquina. Puedes tener la
imagen y no tener ningún contenedor.

El **contenedor** es una instancia en ejecución de esa imagen. Puedes crear veinte
contenedores de la misma imagen, y borrarlos todos sin que la imagen se inmute.

La analogía que suele abrir la puerta: la imagen es como una plantilla y el contenedor como
la instancia. Y aquí es donde la analogía se rompe, así que la cerramos ya: **un contenedor
no es una máquina virtual**. No arranca un kernel propio ni emula hardware; es un proceso
de tu sistema operativo con una vista distinta del filesystem, de la red y de los procesos.
Los mecanismos que producen esa vista —namespaces y cgroups— son materia de **[F16](16-pid1-senales-y-ciclo-de-vida.md)**.

---

## 5. 📄 Cómo se llama el archivo, y la convención del curso

Un Dockerfile no tiene extensión obligatoria. El nombre convencional es literalmente
`Dockerfile`, sin extensión, y es el que las herramientas buscan por defecto. Pero puedes
darle cualquier nombre y pasárselo al build con `-f`.

Este curso aprovecha esa libertad con una convención propia:

```text
legacy-node-toolchain-lab/
├── dockerfiles/
│   ├── 01-hola-mundo.Dockerfile        ← F02, esta fase
│   ├── 02-utilidades.Dockerfile        ← F03
│   ├── 03-toolchain.Dockerfile         ← F04
│   ├── 04-python-node-gyp.Dockerfile   ← F05
│   └── 05-node.Dockerfile              ← F06
├── Dockerfile                          ← el canónico, nace en F07
└── .dockerignore
```

Cada fase deja su Dockerfile pedagógico, numerado y con el tema en el nombre. **No se
sustituyen entre sí: se acumulan.** Así puedes volver a construir la imagen de la fase 03
para comparar, o para ver qué se rompe si le quitas algo.

> 💡 **Por qué no `Dockerfile01`, `Dockerfile02`…** Porque el número al final se ordena mal,
> no dice de qué trata el archivo, y tu editor no le aplica el resaltado de sintaxis. Con
> `NN-tema.Dockerfile` tienes las tres cosas: orden, tema y resaltado.

El `Dockerfile` de la raíz —el canónico, sin número— nace en **[F07](07-build-de-la-imagen.md)** y es el que representa
el laboratorio de verdad. Los pedagógicos no lo reemplazan: lo acompañan.

> 🦭 **¿Y Podman?** Lee el mismo archivo. Podman construye Dockerfiles estándar y usa
> `-f` igual que Docker. Las diferencias reales aparecen en el motor, no en el formato, y
> **[F24](24-docker-y-podman-arquitectura.md)** las disecciona.

---

## 6. 🧠 Build time y runtime: dos momentos, no uno

Esta distinción vale más que varias instrucciones juntas, porque explica por qué hay
parejas que parecen redundantes y no lo son.

```text
BUILD TIME                          RUNTIME
docker build                        docker run
────────────                        ───────────
ejecuta RUN                         ejecuta CMD / ENTRYPOINT
resuelve ARG                        lee ENV
copia con COPY / ADD                monta volúmenes y bind mounts
produce → la imagen                 produce → un contenedor vivo

ocurre una vez                      ocurre cada vez que arrancas algo
```

Todo lo que pasa en build time queda **horneado en la imagen**. Todo lo que pasa en runtime
es efímero y desaparece con el contenedor, salvo que lo hayas puesto en un volumen.

De ahí sale la primera pregunta útil cuando algo no funciona: *¿esto que espero, se decidió
al construir o al ejecutar?* Media docena de errores del catálogo de **[F31](31-catalogo-de-fallos-i.md)** se resuelven
con eso.

---

## 7. 🧰 Las instrucciones que vamos a usar

Once instrucciones cubren el 95% de lo que este curso escribe. Van en el orden en que se
entienden mejor, no en orden alfabético.

### 7.1 `FROM` — de dónde arrancamos

Toda imagen parte de otra. `FROM` dice cuál:

```dockerfile
FROM debian/eol:buster
```

Ese identificador se lee en tres partes: `debian` es el usuario u organización en el
registry, `eol` es el repositorio, y `buster` es el **tag**. Es la decisión que cerró [F01](01-decisiones-debian-zonas-node.md) y
la única línea obligatoria de un Dockerfile.

### 7.2 `RUN` — ejecutar algo mientras construimos

`RUN` ejecuta un comando **durante el build**, y su resultado queda dentro de la imagen:

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends git
```

Es la instrucción con la que se instala todo. También es la que más caro sale usar mal, por
razones que **[F03](03-apt-y-utilidades.md)** empieza a explicar y **[F12](12-capas-cache-y-contexto.md)** cierra.

### 7.3 `CMD` — el comando predeterminado

`CMD` no ejecuta nada durante el build. Define **qué se ejecuta cuando arranca un
contenedor** si no le dices otra cosa:

```dockerfile
CMD ["/bin/echo", "Hola"]
```

La palabra clave es *predeterminado*. Cualquier comando que pases a `docker run` después del
nombre de la imagen lo reemplaza. `CMD` es un valor por defecto, no una prisión.

> ⚔️ **`RUN` frente a `CMD`**, que es la confusión gemela de la de §4: `RUN` ocurre al
> construir y deja huella en la imagen; `CMD` ocurre al ejecutar y no deja ninguna.

### 7.4 `ENTRYPOINT` — el ejecutable principal

`ENTRYPOINT` define el programa que el contenedor ejecuta siempre, y `CMD` pasa a ser sus
argumentos por defecto:

```dockerfile
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bash"]
```

Con eso, `docker run imagen` ejecuta el entrypoint con `bash` como argumento, y
`docker run imagen node --version` ejecuta el entrypoint con `node --version`. El
entrypoint decide qué hacer con lo que le llega.

Esta pareja es el corazón del laboratorio y merece su propia fase: **[F08](08-run-el-contenedor-como-proceso.md)** la usa para
construir el despachador que elige la versión de Node.

### 7.5 Forma shell y forma exec

`RUN`, `CMD` y `ENTRYPOINT` admiten dos estilos:

```dockerfile
CMD echo hola                       # forma shell
CMD ["/bin/echo", "hola"]           # forma exec — lista JSON
```

**Para `CMD` y `ENTRYPOINT` preferimos siempre la forma exec.** No es capricho: la forma
shell envuelve tu comando en `/bin/sh -c`, que se convierte en el proceso principal del
contenedor y se queda con las señales que van dirigidas a tu programa.

> 🚨 **Por qué importa.** Cuando ejecutas `docker stop`, el motor envía `SIGTERM` al proceso
> principal para que se cierre ordenadamente. Si ese proceso es `/bin/sh -c`, la señal puede
> no llegar nunca a tu servidor Node, que entonces muere de golpe diez segundos después por
> `SIGKILL` — sin cerrar conexiones, sin vaciar buffers, sin ejecutar tu handler de cierre.
> Para un `echo` de dos milisegundos da igual; para un servidor de verdad, no. El mecanismo
> completo está en **[F16](16-pid1-senales-y-ciclo-de-vida.md)**.

### 7.6 `WORKDIR` — el directorio de trabajo

```dockerfile
WORKDIR /workspace
```

Establece el directorio en el que se ejecutan las instrucciones siguientes y en el que
arranca el contenedor. Si no existe, lo crea. Es la ruta estándar que decidió [F01](01-decisiones-debian-zonas-node.md).

### 7.7 `COPY` y `ADD` — meter archivos en la imagen

`COPY` copia archivos desde el **build context** —el directorio que le pasas al build— hacia
el filesystem de la imagen:

```dockerfile
COPY scripts/docker-entrypoint.sh /usr/local/bin/
```

`ADD` hace lo mismo y además sabe descargar URLs remotas y descomprimir ciertos formatos.
Esas capacidades extra son justo lo que lo hace impredecible cuando no las quieres.

> 🧭 **Regla del curso:** si solo necesitas copiar un archivo local, **`COPY`**. `ADD` se usa
> únicamente cuando necesitas expresamente una de sus capacidades adicionales. No usamos
> `ADD` porque tenga tres letras y `COPY` cuatro. 😄

### 7.8 `ARG` y `ENV` — las dos variables que se confunden

`ARG` define una variable **disponible durante el build** y parametrizable desde fuera:

```dockerfile
ARG NODE_VERSIONS="10.24.1 12.22.12 14.21.3 16.20.2"
```

```bash
docker build --build-arg NODE_VERSIONS="10.24.1 14.21.3" ...
```

`ENV` define una variable **que persiste en la imagen** y que el contenedor ve al arrancar:

```dockerfile
ENV NODE_VERSION=10.24.1
```

La diferencia, en una línea:

```text
ARG  → configura el BUILD.     No existe cuando el contenedor corre.
ENV  → configura el RUNTIME.   Queda escrita en la imagen y se puede leer.
```

> ⚠️ **Ninguna de las dos sirve para secretos.** Un `ARG` con un token queda en el historial
> de construcción de la imagen, y un `ENV` queda a la vista de cualquiera que ejecute
> `docker inspect`. **[F29](29-supply-chain-sbom-firma.md)** lo trata a fondo, y el script de diagnóstico de **[F30](30-troubleshooting-metodo-y-herramientas.md)** existe
> en parte por este problema.

### 7.9 `LABEL` — metadatos

```dockerfile
LABEL org.opencontainers.image.title="legacy-node-toolchain"
```

Pares clave-valor que describen la imagen. Las claves `org.opencontainers.image.*` son un
estándar OCI, no una convención inventada, y sirven para que herramientas ajenas sepan leer
tu imagen. **[F28](28-publicar-la-imagen.md)** las usa de verdad al publicar.

### 7.10 `USER` — quién ejecuta

```dockerfile
USER node
```

Cambia el usuario de las instrucciones siguientes y del contenedor al arrancar. **Nuestro
baseline se queda como `root`**, y esa es una decisión deliberada que [F01](01-decisiones-debian-zonas-node.md) dejó implícita:
un usuario no-root introduce problemas de permisos con los bind mounts que distraen del
objetivo de la Parte I. El tratado completo, con lo que se gana y lo que se rompe, está en
**[a05](a05-non-root-a-fondo.md)**; los permisos y el UID/GID en **[F17](17-usuarios-permisos-y-volumenes.md)**.

---

## 8. 👶 Nuestro primer Dockerfile

Después de toda la teoría, el archivo es sorprendentemente pequeño.

📄 **`dockerfiles/01-hola-mundo.Dockerfile`**

```dockerfile
# syntax=docker/dockerfile:1

FROM debian/eol:buster

LABEL org.opencontainers.image.title="legacy-node-toolchain"
LABEL org.opencontainers.image.description="Toolchain de desarrollo para proyectos Node.js legacy"

WORKDIR /workspace

CMD ["/bin/echo", "👋 Hola desde legacy-node-toolchain"]
```

Eso es todo. Todavía no hay Node, ni npm, ni Python, ni GCC, ni Git, ni `curl`, ni
`node-gyp`. Y está bien: esta versión sirve para aprender Dockerfile, no para compilar
Angular 8. 😄

**Detalles con intención:**

- `# syntax=docker/dockerfile:1` selecciona la sintaxis estable de la familia 1 para
  BuildKit. Va en la primera línea o no funciona.
- `FROM debian/eol:buster` arranca desde el archivo histórico, por lo decidido en [F01](01-decisiones-debian-zonas-node.md) §4.4.
- Los dos `LABEL` documentan qué representa la imagen usando claves OCI estándar.
- `WORKDIR /workspace` fija ya la ruta que usarán todas las fases siguientes, aunque
  todavía no haya nada montado ahí.
- `CMD` en forma exec, por lo de §7.5, aunque para un `echo` no cambie nada. Se aprende la
  buena práctica desde el principio.

### 8.1 La estructura del laboratorio

```text
legacy-node-toolchain-lab/
├── dockerfiles/
│   └── 01-hola-mundo.Dockerfile
└── .dockerignore
```

Y un `.dockerignore` inicial razonable:

```dockerignore
.git
.DS_Store
Thumbs.db
*.log
node_modules
```

Todavía no hay proyecto Node en este repositorio, pero dejamos preparada la higiene del
build context. Qué hace exactamente ese archivo y por qué importa tanto es de **[F07](07-build-de-la-imagen.md)**.

### 8.2 Construir

Desde la raíz del laboratorio:

```bash
docker build \
  --platform linux/amd64 \
  --file dockerfiles/01-hola-mundo.Dockerfile \
  --tag legacy-node-toolchain:phase02 \
  .
```

Cada parte tiene su porqué. `--platform linux/amd64` fija la arquitectura baseline que
decidió [F01](01-decisiones-debian-zonas-node.md), y en un Mac ARM es lo que hace que el resultado sea comparable con el de
cualquier otra máquina. `--file` apunta al Dockerfile pedagógico, porque no se llama
`Dockerfile`. `--tag` le pone nombre y versión pedagógica a la imagen. Y el `.` final es el
build context — de momento acéptalo como "el directorio desde el que se construye"; **[F07](07-build-de-la-imagen.md)**
lo explica y demuestra por qué es el argumento más caro de ignorar.

El tag se lee así:

```text
legacy-node-toolchain : phase02
        │                  │
        └── nombre         └── tag: esta versión pedagógica
```

No usamos `latest`, ni aquí ni en el resto del curso. Un `latest` en el tronco principal es
un error de estilo: no dice qué contiene y cambia debajo de tus pies.

Con Podman, el comando es el mismo cambiando el binario:

```bash
podman build \
  --platform linux/amd64 \
  --file dockerfiles/01-hola-mundo.Dockerfile \
  --tag legacy-node-toolchain:phase02 \
  .
```

### 8.3 Prueba de fuego

Cuatro comandos que confirman que la imagen es lo que crees:

```bash
# 1. el CMD predeterminado
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase02
```
```text
👋 Hola desde legacy-node-toolchain
```

```bash
# 2. el CMD es un valor por defecto, no una prisión
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase02 cat /etc/os-release
```
```text
PRETTY_NAME="Debian GNU/Linux 10 (buster)"
NAME="Debian GNU/Linux"
VERSION_ID="10"
VERSION="10 (buster)"
...
```

```bash
# 3. el WORKDIR está donde lo pusimos
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase02 pwd
```
```text
/workspace
```

```bash
# 4. la arquitectura es la que pedimos
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase02 uname -m
```
```text
x86_64
```

El `--rm` elimina el contenedor cuando termina. La imagen se queda: **borrar un contenedor
no borra la imagen**, y esa distinción va a ahorrarte sustos.

> 🩺 **La comprobación 4 se vuelve rutina.** En un Mac con Apple Silicon, `uname -m` dentro
> del contenedor te dice si estás donde crees. Cuando algo falle de forma inexplicable en
> **[F14](14-abi-libc-y-prebuilds.md)**, este es el primer comando que vas a ejecutar.

Y para mirar dentro de la imagen:

```bash
docker image ls
docker image inspect legacy-node-toolchain:phase02
```

La salida de `inspect` es grande porque es JSON con todos los metadatos: arquitectura,
`WorkingDir`, `Cmd`, labels, capas. No hace falta memorizarla. Lo que importa es empezar a
ver que una imagen tiene bastante más información que un filesystem comprimido.

---

## 9. ⚠️ Errores comunes y diagnóstico

**`unable to prepare context: path "." not found`** o el build no encuentra el Dockerfile.
Casi siempre es que ejecutaste el comando desde otro directorio. `-f` cambia qué archivo se
lee, **no** cambia el build context: el `.` sigue siendo relativo a donde estás parado.

**El `CMD` no se ejecuta y el contenedor arranca en una shell.** Alguien puso un
`ENTRYPOINT` en la imagen base o pasaste un comando extra al `docker run`. Compruébalo con
`docker image inspect` mirando `Entrypoint` y `Cmd`.

**Cambias el Dockerfile, reconstruyes y no ves el cambio.** Es la caché, y en esta fase el
Dockerfile es tan pequeño que casi no ocurre — pero desde [F03](03-apt-y-utilidades.md) va a ser tu compañía
permanente. `--no-cache` fuerza un build limpio, y **[F12](12-capas-cache-y-contexto.md)** explica por qué eso casi nunca es
la solución correcta.

**En Apple Silicon, `uname -m` responde `aarch64` en vez de `x86_64`.** Olvidaste
`--platform linux/amd64` en el `run`, o en el `build`, o en los dos. La bandera hay que
ponerla en ambos: construir para amd64 no obliga a ejecutar en amd64.

**`exec format error` al arrancar.** La imagen es de una arquitectura y el motor intenta
correrla en otra sin emulación disponible. Es el síntoma clásico de mezclar plataformas, y
**[F21](21-arquitecturas-y-emulacion.md)** lo trata entero.

---

## 10. 📋 Checklist de validación

```text
[ ] Existe dockerfiles/01-hola-mundo.Dockerfile con las seis líneas de §8
[ ] Existe .dockerignore en la raíz del laboratorio
[ ] docker build ... --tag legacy-node-toolchain:phase02 .   termina sin error
[ ] docker image ls muestra legacy-node-toolchain con tag phase02
[ ] docker run --rm ... phase02                    imprime el saludo
[ ] docker run --rm ... phase02 cat /etc/os-release confirma Debian 10 (buster)
[ ] docker run --rm ... phase02 pwd                imprime /workspace
[ ] docker run --rm ... phase02 uname -m           imprime x86_64
[ ] Puedes explicar cada una de las seis líneas del Dockerfile sin mirar la fase
[ ] Puedes decir qué instrucciones actúan en build time y cuáles en runtime
```

---

## 11. 🧪 Ejercicios de la Fase 02 (25)

## 🟢 Fácil — reconocer el vocabulario (1–7)

### 🟢 Ejercicio 1 — Construye y ejecuta

Crea la estructura de §8.1, escribe el Dockerfile y ejecuta los cuatro comandos de la prueba
de fuego.

**Objetivo:** tener la primera imagen del curso construida y verificada, y haber visto las
cuatro salidas con tus ojos.

### 🟢 Ejercicio 2 — Imagen y contenedor no son lo mismo

Ejecuta el contenedor **sin** `--rm`, después `docker ps -a` para verlo detenido, después
`docker rm <id>` para borrarlo, y por último `docker image ls`.

**Pregunta:** ¿desapareció la imagen al borrar el contenedor? ¿Y cuántos contenedores
distintos puedes crear de una sola imagen?

### 🟢 Ejercicio 3 — `CMD` no es una prisión

Ejecuta la imagen pasándole tres comandos distintos: `whoami`, `ls -la /`, y
`echo "otro mensaje"`.

**Objetivo:** comprobar que el `CMD` del Dockerfile es un valor por defecto y que el
argumento de `docker run` lo reemplaza.

### 🟢 Ejercicio 4 — Cambia el WORKDIR

Copia el Dockerfile a `dockerfiles/01b-workdir.Dockerfile`, cambia `WORKDIR` a `/app`,
construye con el tag `legacy-node-toolchain:ej04` y ejecuta `pwd`.

**Objetivo:** confirmar que `WORKDIR` crea el directorio si no existe, y entender por qué el
curso fija `/workspace` en todas partes.

### 🟢 Ejercicio 5 — Lee los metadatos

Ejecuta `docker image inspect legacy-node-toolchain:phase02` y localiza cuatro campos:
`Architecture`, `Os`, `Config.WorkingDir` y `Config.Labels`.

**Pregunta:** ¿coincide `Architecture` con lo que respondió `uname -m` dentro del contenedor?

### 🟢 Ejercicio 6 — El tag no es la imagen

Ejecuta `docker tag legacy-node-toolchain:phase02 mi-prueba:v1` y después `docker image ls`.

**Pregunta:** ¿cuántas imágenes hay realmente? Mira la columna `IMAGE ID` antes de responder.

### 🟢 Ejercicio 7 — Construye con Podman

Si tienes Podman instalado, construye la misma imagen con `podman build` y ejecútala.

**Objetivo:** comprobar de primera mano que el Dockerfile es el mismo y que la diferencia
está en el motor, no en el formato. Si no tienes Podman, anota este ejercicio como pendiente
para [F24](24-docker-y-podman-arquitectura.md).

## 🟡 Intermedio — usar las instrucciones de verdad (8–15)

### 🟡 Ejercicio 8 — `RUN` sí deja huella

Añade `RUN echo "construido el $(date)" > /etc/build-info` al Dockerfile, reconstruye con
tag `ej08` y ejecuta `cat /etc/build-info`.

**Pregunta:** si creas dos contenedores de esa imagen con una hora de diferencia, ¿muestran
fechas distintas? ¿Por qué?

### 🟡 Ejercicio 9 — `ENV` sobrevive, `ARG` no

Escribe un Dockerfile con `ARG SABOR=vainilla` y `ENV COLOR=azul`, y un
`CMD ["/bin/sh","-c","echo ARG=$SABOR ENV=$COLOR"]`.

**Pregunta:** ¿cuál de las dos variables aparece vacía al ejecutar, y por qué? Predice la
respuesta antes de construir.

### 🟡 Ejercicio 10 — Pasa un build arg

Reconstruye el Dockerfile del ejercicio 9 con `--build-arg SABOR=chocolate` y busca el valor
con `docker image inspect`.

**Objetivo:** entender que `ARG` parametriza el build desde fuera, y ver dónde queda
registrado — que es la razón por la que no sirve para secretos.

### 🟡 Ejercicio 11 — `ENTRYPOINT` más `CMD`

Escribe un Dockerfile con `ENTRYPOINT ["/bin/echo"]` y `CMD ["hola"]`. Ejecútalo sin
argumentos, y después con `docker run <imagen> adios`.

**Objetivo:** ver que `CMD` se comporta como argumento por defecto del `ENTRYPOINT`, que es
exactamente el patrón que usará el despachador de Node en [F08](08-run-el-contenedor-como-proceso.md).

### 🟡 Ejercicio 12 — `COPY` desde el build context

Crea un archivo `saludo.txt` en la raíz del laboratorio, cópialo a `/workspace/` con `COPY`,
reconstruye y léelo desde dentro del contenedor.

**Pregunta:** ¿qué pasa si intentas copiar un archivo que está **fuera** del directorio desde
el que ejecutas `docker build`? Prueba con `COPY ../algo /tmp/` y lee el error entero.

### 🟡 Ejercicio 13 — Forma shell contra forma exec

Construye dos imágenes idénticas salvo por el `CMD`: una con `CMD sleep 300` y otra con
`CMD ["sleep", "300"]`. Arranca las dos con `-d` y ejecuta
`docker exec <id> ps -ef` en cada una.

**Objetivo:** ver con tus ojos el `/bin/sh -c` extra que aparece como PID 1 en la versión
shell. Es el proceso que se queda con las señales.

### 🟡 Ejercicio 14 — `USER` cambia quién eres

Añade `RUN useradd -m dev` y `USER dev` al final del Dockerfile, reconstruye y ejecuta
`whoami` y después `touch /workspace/prueba.txt`.

**Pregunta:** ¿qué falla, y qué te dice eso sobre por qué el laboratorio se queda como
`root` en la Parte I?

### 🟡 Ejercicio 15 — Los metadatos que sí viajan

Añade al Dockerfile tres etiquetas con el espacio de nombres de OCI —el mismo que usa la
imagen canónica desde [F07](07-build-de-la-imagen.md)—, reconstruye con tag `ej15` y recupéralas:

```dockerfile
LABEL org.opencontainers.image.title="mi-prueba"
LABEL org.opencontainers.image.description="Aprendiendo LABEL"
LABEL org.opencontainers.image.licenses="MIT"
```

```bash
docker image inspect legacy-node-toolchain:ej15 --format '{{json .Config.Labels}}' | jq
```

**Pregunta:** las tres `LABEL` son tres instrucciones, así que ¿cuántas capas añaden a la
imagen y cuánto pesan? Compruébalo con `docker image history` y explica por qué el resultado
no contradice lo que dice §7.9.

## 🟠 Difícil — diagnosticar y medir (16–21)

### 🟠 Ejercicio 16 — Diagnostica un build roto

Este Dockerfile no construye. **Predice qué error dará antes de ejecutarlo**, después
constrúyelo y compara:

```dockerfile
FROM debian/eol:buster
WORKDIR /workspace
COPY app.js .
CMD ["node", "app.js"]
```

**Pregunta:** hay **dos** problemas distintos, y solo uno aparece al construir. ¿Cuál es el
segundo y en qué momento se manifestaría?

### 🟠 Ejercicio 17 — El contenedor que muere de inmediato

Construye una imagen con `CMD ["bash"]` y ejecútala con `docker run -d <imagen>`. Después
`docker ps` y `docker ps -a`.

**Pregunta:** el contenedor aparece como `Exited (0)` casi al instante. ¿Por qué? ¿Y qué
bandera del `run` cambia ese comportamiento? Pista: tiene que ver con STDIN.

### 🟠 Ejercicio 18 — La arquitectura equivocada

En una máquina ARM (o forzándolo con `--platform linux/arm64`), construye la imagen para una
plataforma y ejecútala pidiendo la otra.

**Objetivo:** provocar el `exec format error` o ver la advertencia de emulación, y aprender a
reconocerlo. Es uno de los síntomas más desorientadores del curso y lo vas a volver a ver en
[F21](21-arquitecturas-y-emulacion.md).

### 🟠 Ejercicio 19 — `ADD` no es `COPY` con otro nombre

§7.7 dice que uses `COPY` salvo que sepas exactamente por qué quieres `ADD`. Este ejercicio
te hace ver ese "exactamente por qué". Crea un tar en la raíz del laboratorio y copia el mismo
archivo de las dos formas:

```bash
mkdir -p paquete && echo "contenido" > paquete/dato.txt
tar -czf paquete.tar.gz paquete/
```

```dockerfile
COPY paquete.tar.gz /con-copy/
ADD  paquete.tar.gz /con-add/
```

**Pregunta:** entra al contenedor y mira qué hay en `/con-copy` y en `/con-add`. ¿Por qué son
distintos? Y la parte que importa: ¿en qué situación ese comportamiento de `ADD` es
**exactamente lo que no querías** al copiar un artefacto de tu proyecto?

### 🟠 Ejercicio 20 — Pesa el build context

El build context no es "tu carpeta": es lo que el cliente **empaqueta y envía** al builder
antes de leer la primera instrucción. Mídelo. Crea un archivo grande en la raíz del
laboratorio y construye:

```bash
dd if=/dev/urandom of=basura.bin bs=1M count=200
docker build --platform linux/amd64 --no-cache \
  -f dockerfiles/01-hola-mundo.Dockerfile -t legacy-node-toolchain:ej20 .
```

Fíjate en la primera línea del build, la de `transferring context`. Después crea un
`.dockerignore` con `basura.bin` dentro y repite.

**Pregunta:** ¿cuánto tardó cada build y cuántos bytes se transfirieron en cada uno? El
Dockerfile no menciona `basura.bin` por ningún lado: ¿por qué le importaba al build? Guarda
los dos números — **[F12](12-capas-cache-y-contexto.md)** los usa para explicar el mecanismo.

### 🟠 Ejercicio 21 — Dos `CMD` y dos `ENTRYPOINT`: quién gana

Escribe un Dockerfile con **dos** `CMD` y **dos** `ENTRYPOINT`, en este orden:

```dockerfile
FROM debian/eol:buster
CMD ["echo", "primero"]
ENTRYPOINT ["/bin/echo", "uno"]
CMD ["echo", "segundo"]
ENTRYPOINT ["/bin/echo", "dos"]
```

**Antes de construir, predice** dos cosas: qué imprimirá `docker run` sin argumentos, y qué
devolverán `Config.Cmd` y `Config.Entrypoint` en el `inspect`. Después construye, ejecútalo y
compara.

**Pregunta:** ¿cuál de las cuatro instrucciones sobrevivió y cuál es la regla? Ahora mira
`docker image history` y responde la segunda mitad: si las cuatro instrucciones **sí**
aparecen en el historial pero solo dos tienen efecto, ¿qué te dice eso sobre la diferencia
entre lo que la imagen **registra** y lo que la imagen **hace**?

## 🔴 Muy difícil — criterio y predicción (22–25)

### 🔴 Ejercicio 22 — Reconstruye el Dockerfile desde el `inspect`

Alguien te pasa una imagen sin su Dockerfile. Usando solo `docker image inspect` y
`docker image history`, escribe el Dockerfile que la produjo.

**Objetivo:** entrenar la lectura inversa, que es lo que vas a hacer con cualquier imagen
ajena que te toque mantener.

### 🔴 Ejercicio 23 — Audita un Dockerfile real

Busca en GitHub un `Dockerfile` de un proyecto Node de 2018 o 2019 —hay miles— y audítalo
contra lo que sabes: ¿usa forma exec o shell? ¿`ADD` donde debería ir `COPY`? ¿Fija la
versión base o usa un tag móvil? ¿Copia el proyecto dentro de la imagen? ¿Corre como root?

**Objetivo:** producir una lista de cinco observaciones, cada una con la consecuencia
concreta. No basta con decir "está mal": hay que decir qué se rompe y cuándo.

### 🔴 Ejercicio 24 — Defiende una decisión que parece mala

Tu Dockerfile de esta fase usa `debian/eol:buster`, corre como `root` y no fija la imagen
base por digest. Un revisor te rechaza el PR por las tres cosas.

**Objetivo:** escribir la respuesta que acepta lo que el revisor tiene razón, explica la
condición bajo la cual cada decisión es correcta **en este contexto**, y dice qué tendría que
cambiar para que el revisor pasara a tener razón. Las tres respuestas son distintas: una es
deliberada y definitiva, otra es deuda 💸 que se paga en [a05](a05-non-root-a-fondo.md), y la tercera es deuda que se
paga en [F12](12-capas-cache-y-contexto.md).

### 🔴 Ejercicio 25 — Predice el `inspect` entero antes de construir

Este es el examen final de §7, y se hace con papel antes que con terminal. Te damos el
Dockerfile:

```dockerfile
FROM debian/eol:buster
ARG VERSION=1.0
ENV APP_ENV=produccion
WORKDIR /srv
RUN useradd -m operador
USER operador
WORKDIR datos
LABEL org.opencontainers.image.version="${VERSION}"
ENTRYPOINT ["/bin/echo"]
CMD ["sin argumentos"]
```

**Sin construirlo**, escribe el valor exacto que tendrán estos seis campos del
`docker image inspect`: `Config.Env`, `Config.WorkingDir`, `Config.User`, `Config.Labels`,
`Config.Entrypoint` y `Config.Cmd`. Hay tres trampas deliberadas: el segundo `WORKDIR` es
relativo, el `ARG` se usa dentro de un `LABEL`, y `Config.Env` no contiene solo lo que tú
declaraste.

**Objetivo:** construir después, comparar campo por campo y escribir una línea por cada
acierto y por cada fallo diciendo **qué regla de §7 lo explica**. Un fallo aquí es un modelo
mental roto que te va a costar una tarde en la Parte II; encontrarlo ahora es gratis.

## 🔥 Opcionales

### 🔥 Ejercicio 26 — El Dockerfile más pequeño que arranca

Construye la imagen más pequeña que puedas que aún permita ejecutar `echo`, midiendo con
`docker image ls`. Prueba `debian/eol:buster`, `debian:12-slim`, `alpine` y `busybox`.

**Pregunta:** ¿cuál es la diferencia de tamaño, y por qué el curso elige deliberadamente la
más grande de las cuatro? Vuelve a [F01](01-decisiones-debian-zonas-node.md) §4.2 si dudas.

### 🔥 Ejercicio 27 — `ENTRYPOINT` y `CMD`, las cuatro combinaciones

Construye cuatro imágenes que se diferencien solo en cómo declaran su comando: solo `CMD` en
forma exec, solo `ENTRYPOINT` en forma exec, las dos juntas, y `CMD` en forma shell. Ejecuta
cada una sin argumentos y después con `bash -c 'echo hola'` al final del `docker run`.

**Objetivo:** completar una tabla de cuatro filas que diga, para cada combinación, qué proceso
acaba siendo PID 1 y qué pasa con el argumento que pasaste. Es la tabla que **[F08](08-run-el-contenedor-como-proceso.md)** va a dar
por sabida.

## 💀 Boss fight

### 💀 Ejercicio 28 — Boss fight: el Dockerfile que alguien escribió a ciegas

Te pasan este archivo y te piden que digas si sirve. No lo construyas todavía.

```dockerfile
FROM debian:latest
RUN apt-get install -y curl
CMD echo "listo"
ENTRYPOINT ["/bin/bash", "-c"]
WORKDIR /app
COPY . .
```

**Objetivo:** producir un informe de seis puntos, uno por línea, que para cada una diga
**qué hace realmente**, **qué creía quien la escribió** y **cómo se demuestra la diferencia
con un comando**. Tienes que cubrir, como mínimo: por qué `latest` sobre Debian rompe la
promesa de §4 de [F01](01-decisiones-debian-zonas-node.md); por qué ese `apt-get install` va a fallar y qué línea le falta antes
(§4 de [F03](03-apt-y-utilidades.md) lo dirá con nombre y apellido, pero aquí ya puedes anticiparlo); qué pasa cuando
`ENTRYPOINT` aparece **después** de `CMD` y cómo se combinan de verdad los dos (§7.3); por
qué `WORKDIR` después de `COPY . .` no hace lo que el autor esperaba; y qué entra en esa
copia sin `.dockerignore`.

**Después** construye la imagen y demuestra cada punto con evidencia: `docker inspect` sobre
`Config.Cmd` y `Config.Entrypoint`, `docker history`, y el error real del `apt-get`. Cierra
con la versión corregida y con **una frase por corrección** explicando qué instrucción de §7
resolvía cada cosa. Si tu informe predijo correctamente los seis fallos antes de construir,
esta fase quedó.

---

## 12. 📚 Referencias

**Dockerfile**
- Referencia completa de instrucciones: https://docs.docker.com/reference/dockerfile/
- Buenas prácticas oficiales: https://docs.docker.com/build/building/best-practices/
- `.dockerignore`: https://docs.docker.com/build/concepts/context/#dockerignore-files

**Imágenes y OCI**
- Especificación de imagen OCI: https://github.com/opencontainers/image-spec
- Claves de anotación estándar (`org.opencontainers.image.*`): https://github.com/opencontainers/image-spec/blob/main/annotations.md

**Podman**
- `podman build`: https://docs.podman.io/en/latest/markdown/podman-build.1.html

> ⚠️ **La referencia oficial describe la versión actual del formato**, que tiene
> instrucciones y comportamientos que no existían cuando se escribieron los Dockerfiles que
> vas a mantener. Sirve para entender qué hace cada instrucción hoy; no asumas que el
> proyecto de 2018 que estás leyendo disponía de todo eso.

**Orden de lectura sugerido:** la referencia de instrucciones mientras haces los ejercicios
8 a 14, y las buenas prácticas justo antes de [F07](07-build-de-la-imagen.md), cuando el Dockerfile empiece a crecer.

---

## 13. 🏁 Resultado de la fase

```text
IMAGEN        legacy-node-toolchain:phase02
BASE          debian/eol:buster · Debian 10 · linux/amd64
CONTIENE      Debian 10 y nada más
              WORKDIR /workspace
              dos LABEL con claves OCI
              CMD de saludo, en forma exec
NO CONTIENE   Node ❌  npm ❌  Python ❌  GCC ❌  Git ❌  curl ❌

ARCHIVOS      dockerfiles/01-hola-mundo.Dockerfile
              .dockerignore

SABES         qué es un Dockerfile y en qué se diferencia de imagen y contenedor
              qué hace cada una de las once instrucciones que usaremos
              qué ocurre en build time y qué en runtime
              por qué forma exec y no forma shell
```

> **La señal de que quedó bien:** *"puedo borrar el Dockerfile, escribirlo de memoria línea
> a línea, y explicar por qué cada una está ahí."*

En **[F03](03-apt-y-utilidades.md)** la imagen deja de ser un saludo: instalamos la caja de herramientas con APT y
descubrimos por qué `apt-get update` sigue funcionando sobre un repositorio cuyo `Release`
se firmó hace años.
