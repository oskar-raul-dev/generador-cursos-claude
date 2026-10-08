# 🛠️ Parte I · Fase 04 — Toolchain de compilación: cuando npm saca el casco de obra

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`)
> **Arquitectura objetivo del laboratorio:** `linux/amd64`
> **Dockerfile pedagógico de esta fase:** `dockerfiles/03-toolchain.Dockerfile`
> **Tag pedagógico:** `legacy-node-toolchain:phase04`
> **Estado de la imagen al terminar:** Debian 10, doce utilidades y un toolchain C/C++ completo. Sigue sin Node ni Python
> **Código de esta fase:** [`src/04-toolchain-de-compilacion/`](src/04-toolchain-de-compilacion/)
> **Objetivo:** entender por qué un proyecto de JavaScript necesita un compilador de C, instalarlo entendiendo qué arrastra, y compilar algo de verdad dentro del contenedor

---

## 1. 🧭 Dónde estamos

`phase03` tiene la caja de herramientas: `curl`, `git`, `jq`, `vim` y compañía. Suficiente
para moverse por el contenedor, insuficiente para lo que viene.

Porque la pregunta de esta fase es la que desconcierta a casi todo el mundo:

> ¿Por qué un proyecto de **JavaScript** —un lenguaje interpretado— necesita un compilador
> de **C**?

La respuesta corta es que muchas dependencias de npm no son JavaScript. La larga ocupa esta
fase, y explica la mitad de los errores de instalación que vas a encontrarte en proyectos
de 2018.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder explicar:

- Por qué una dependencia npm puede necesitar compilarse, y por qué eso es **más** probable
  en un proyecto legacy que en uno moderno.
- Qué es `build-essential` y por qué no es "un compilador".
- Qué hacen `gcc`, `g++`, `make` y `pkg-config`, en lo justo para usarlos aquí.
- Para qué sirve `file` y por qué se vuelve imprescindible al diagnosticar.
- Compilar un programa en C dentro del contenedor, con el código viviendo en tu host.

---

## 3. 🚧 Qué NO entra todavía

- **GNU Binutils a fondo** —`ld`, `ar`, `nm`, `objdump`, `readelf`— y la anatomía de un
  binario ELF → **[a03](a03-binutils-y-elf.md)**.
- **Python y `node-gyp`**, que son el puente real entre npm y este toolchain → **[F05](05-python-y-node-gyp.md)**.
- **Los cuatro casos de "dependencia nativa"**, el ABI, `NODE_MODULE_VERSION`, glibc frente
  a musl y los prebuilds → **[F14](14-abi-libc-y-prebuilds.md)**.
- Los laboratorios de `node-sass`, `canvas`, `sqlite3` y Puppeteer → **[F15](15-laboratorios-dependencias-nativas.md)**.
- Qué pasa con todo esto en ARM64 → **[F21](21-arquitecturas-y-emulacion.md)** y **[F23](23-estudios-de-caso-multiplataforma.md)**.

---

## 4. 🧠 Por qué un proyecto JavaScript necesita un compilador

Muchísimas dependencias de npm están escritas por completo en JavaScript, y su instalación
es tan aburrida como esperarías:

```text
npm  →  descarga el paquete  →  copia archivos .js  →  listo
```

Ahí no hace falta ningún compilador. Pero algunos paquetes incluyen o dependen de código
escrito en C o C++ —los llamados **addons nativos**— y entonces el flujo se bifurca:

```mermaid
flowchart TD
    NPM["npm"] --> P["paquete con componente nativo"] --> Q{"¿hay binario precompilado compatible?"}
    Q -- "sí" --> DL["descargarlo y usarlo<br/>rápido, silencioso, y no siempre disponible"]
    Q -- "no" --> CL["compilar localmente"] --> T["toolchain C/C++<br/>lo que instalamos en esta fase"]
```

Ese segundo camino es el que hay que tener preparado, y la razón es de época.

### 4.1 Por qué esto pesa más en un proyecto legacy

Un paquete moderno publica binarios precompilados para muchas combinaciones actuales de
Node, sistema operativo y arquitectura. Una dependencia de 2018 publicó binarios para las
combinaciones que existían entonces, y de ahí salen cinco formas distintas de que el camino
rápido falle:

- El binario **no existe para tu versión exacta de Node**.
- El binario **desapareció del servidor** donde estaba alojado, que muchas veces no era npm
  sino un bucket de S3 de la empresa que mantenía el paquete.
- Existe **solo para `linux-x64`**, y tú estás en ARM64.
- Existe pero **no coincide con el ABI** de tu Node, y eso produce un error en tiempo de
  ejecución, no de instalación.
- La URL de descarga es antigua y ya no responde, o responde con un HTML de error que el
  instalador guarda alegremente como si fuera un binario.

> 🧭 Por eso el laboratorio **no puede apostar a que "seguro npm encuentra un binario ya
> preparado"**. Necesita un plan B, y ese plan B empieza en `gcc`, `g++` y `make`.

Los sospechosos habituales, que vas a ver una y otra vez en proyectos de la época:
`node-sass`, `sqlite3`, `bcrypt`, `canvas`, `sharp`, `grpc`, y los addons propios que casi
toda empresa acabó escribiendo. **[F15](15-laboratorios-dependencias-nativas.md)** los disecciona uno a uno; aquí solo construimos la
base común.

---

## 5. 🧰 Qué instalamos y qué arrastra

Siete paquetes nuevos sobre lo que ya había:

```text
binutils   build-essential   file   g++   gcc   make   pkg-config
```

Y sí: **algunos son redundantes entre sí** por las dependencias de Debian. Instalar
`build-essential` ya te trae `gcc`, `g++` y `make`. La redundancia es deliberada, y la razón
es editorial más que técnica: **el Dockerfile es también documentación del toolchain**.
Alguien que lo lea dentro de dos años y vea

```dockerfile
       gcc \
       g++ \
       make \
```

entiende de un vistazo que esta imagen está preparada para compilar C y C++, sin tener que
saberse de memoria qué arrastra `build-essential`.

### 5.1 `build-essential` no es "un compilador"

El nombre despista: suena a que instalas una aplicación llamada `build-essential`. No es
así. Es un **metapaquete**: un paquete que casi no contiene archivos y cuyo único trabajo es
depender de las herramientas que Debian considera fundamentales para construir software.

En Buster eso incluye `gcc`, `g++`, `make`, `dpkg-dev` y `libc6-dev` —las cabeceras de la
biblioteca C, que es la pieza que más gente olvida y la que produce el clásico
`fatal error: stdio.h: No such file or directory`.

Puedes comprobarlo tú mismo, y merece la pena:

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase04 \
  apt-cache depends build-essential
```

### 5.2 Los cuatro que vas a usar de verdad

**`gcc` y `g++`.** GCC es una colección de compiladores, y estos son sus dos frontends
habituales. La regla práctica es suficiente para el laboratorio:

```text
.c    →  gcc
.cpp  →  g++
```

No es una verdad universal de ingeniería de compiladores, pero sí lo que necesitas para
entender qué comando ejecuta `node-gyp` cuando compila un addon.

**`make`.** Lee un `Makefile` —una lista de objetivos, con sus dependencias y los comandos
que los producen— y decide qué hay que reconstruir. Importa aquí porque **`node-gyp` genera
Makefiles y llama a `make`**: cuando veas un error de compilación de un módulo nativo, lo
que estás leyendo es salida de `make`.

**`pkg-config`.** Responde a la pregunta *"¿dónde están las cabeceras y las librerías del
paquete X, y con qué banderas hay que compilar contra él?"*, sin que nadie tenga que
adivinar rutas:

```bash
pkg-config --cflags --libs zlib
```

Es lo que usan `canvas`, `sharp` y compañía para encontrar sus dependencias del sistema.
Cuando falta, el error habla de una librería que sí está instalada — y ahí es donde se
pierde la tarde.

**`file`.** Una herramienta minúscula que evita confusiones enormes: dice qué es realmente
un archivo, mirando su contenido en lugar de su extensión.

```bash
file /bin/ls
```
```text
/bin/ls: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, ...
```

> 🩺 **Por qué `file` vale su peso en oro.** Cuando un módulo nativo falla, la pregunta útil
> casi siempre es *"¿qué es de verdad este archivo?"*. `file` te dice si ese `.node` es un
> binario x86-64 o ARM64 —que es el diagnóstico de medio [F23](23-estudios-de-caso-multiplataforma.md)—, y si ese "tarball" que
> descargó el instalador es en realidad una página HTML de error de 400 bytes. Lo vas a usar
> mucho más de lo que parece ahora.

**`binutils`** completa el conjunto con el ensamblador y el linker que GCC llama por debajo.
Sus herramientas de inspección —`nm`, `objdump`, `readelf`— son fascinantes y no las
necesitas hoy: están en **[a03](a03-binutils-y-elf.md)**.

---

## 6. 🏗️ El Dockerfile de la fase

📄 **`dockerfiles/03-toolchain.Dockerfile`**

```dockerfile
# syntax=docker/dockerfile:1

FROM debian/eol:buster

LABEL org.opencontainers.image.title="legacy-node-toolchain"
LABEL org.opencontainers.image.description="Toolchain de desarrollo para proyectos Node.js legacy"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash \
       binutils \
       build-essential \
       ca-certificates \
       curl \
       file \
       g++ \
       gcc \
       git \
       jq \
       less \
       make \
       pkg-config \
       procps \
       unzip \
       vim \
       wget \
       xz-utils \
       zip \
    && rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-c"]

ENV SHELL=/bin/bash

WORKDIR /workspace

CMD ["/bin/echo", "👋 Hola desde legacy-node-toolchain"]
```

**Detalles con intención:**

- **Un solo `RUN`, no dos.** Podríamos separar utilidades y compiladores en dos `RUN` para
  que se lea más ordenado, y funcionaría. Pero todos estos paquetes son baseline del sistema
  y se instalan en una sola operación de APT: así hay menos capas, un único ciclo de
  descarga y limpieza de índices, y la lista completa se ve de un vistazo. La separación
  pedagógica la hace el número del archivo, no una capa extra.
- **La lista sigue en orden alfabético**, por lo mismo que en [F03](03-apt-y-utilidades.md): añadir un paquete produce
  un diff de una línea.
- **Cada Dockerfile incremental parte de `debian/eol:buster`**, no de la imagen de la fase
  anterior. Podríamos escribir `FROM legacy-node-toolchain:phase03` y sería más corto, pero
  entonces cada fase dependería de una imagen local previa y no podrías leer ni reconstruir
  una fase de forma independiente. La receta completa hasta ese punto vive en cada archivo.

Construir:

```bash
docker build \
  --platform linux/amd64 \
  --file dockerfiles/03-toolchain.Dockerfile \
  --tag legacy-node-toolchain:phase04 \
  .
```

---

## 7. 👋 Hola mundo en C dentro del contenedor

Aquí es donde la arquitectura de [F01](01-decisiones-debian-zonas-node.md) deja de ser teoría: **el archivo vive en tu host, la
compilación ocurre en el contenedor**.

Crea en tu máquina:

```text
experimentos/c-toolchain/
├── hello.c
└── Makefile
```

📄 **`hello.c`**

```c
#include <stdio.h>

int main(void) {
    printf("Hola desde C dentro del contenedor 👋\n");
    return 0;
}
```

Nada más. No hacen falta punteros triples ni árboles AVL para demostrar que GCC funciona. 😄

📄 **`Makefile`** — ojo, la indentación de las recetas es **un tabulador**, no espacios; es
el error más antiguo del mundo con `make`:

```makefile
# compilador y banderas del laboratorio
CC = gcc
CFLAGS = -Wall -Wextra -O2

hello: hello.c
	$(CC) $(CFLAGS) -o hello hello.c

.PHONY: clean
clean:
	rm -f hello
```

Ahora monta el directorio y compila:

```bash
docker run --rm -it \
  --platform linux/amd64 \
  --mount type=bind,src="$PWD/experimentos/c-toolchain",dst=/workspace \
  legacy-node-toolchain:phase04 \
  bash
```

Dentro del contenedor:

```bash
gcc -Wall -o hello hello.c
./hello
```
```text
Hola desde C dentro del contenedor 👋
```

Y ahora con `make`, que es lo que de verdad va a ejecutar `node-gyp`:

```bash
make clean && make
./hello
```
```text
rm -f hello
gcc -Wall -Wextra -O2 -o hello hello.c
Hola desde C dentro del contenedor 👋
```

> 🔥 **Prueba de fuego.** Sal del contenedor y mira `experimentos/c-toolchain/` en tu host:
> el binario `hello` está ahí, escrito por un compilador que tu máquina no tiene instalado.
> Ejecútalo en el host. Si estás en macOS o Windows **no va a funcionar**, y esa negativa es
> justo lo que la fase quiere que veas: ese binario es un ELF de Linux. Compruébalo con
> `file hello` dentro del contenedor.

Ese detalle —un artefacto compilado pertenece al sistema que lo compiló— es exactamente el
motivo por el que `node_modules` va en un named volume y no en el host. [F01](01-decisiones-debian-zonas-node.md) lo decidió,
esto lo demuestra, y **[F14](14-abi-libc-y-prebuilds.md)** lo explica hasta el último bit.

---

## 8. ⚠️ Errores comunes y diagnóstico

**`fatal error: stdio.h: No such file or directory`.** Tienes el compilador pero no las
cabeceras de la biblioteca C. Falta `libc6-dev`, que normalmente llega con
`build-essential`. Es el error que delata a quien instaló solo `gcc` para ahorrar espacio.

**`make: *** No targets specified and no makefile found. Stop.`** No hay `Makefile` en el
directorio actual, o estás en otro directorio. Comprueba con `pwd` y `ls`.

**`Makefile:6: *** missing separator. Stop.`** Usaste espacios donde `make` exige un
tabulador. No hay negociación posible con esto desde 1976. 😄

**`Package X was not found in the pkg-config search path`.** Falta el paquete `-dev` de esa
librería, que es distinto del paquete de la librería. En Debian, `libfoo` trae el `.so` en
tiempo de ejecución y `libfoo-dev` trae las cabeceras y el archivo `.pc` que `pkg-config`
busca. Es la distinción que más tiempo hace perder al compilar módulos nativos.

**El binario compilado no se ejecuta en tu host.** No es un fallo: es un ELF de Linux
`x86-64`. `file hello` te lo confirma en una línea.

**`exec format error` al ejecutar el binario dentro del contenedor.** Compilaste en una
arquitectura y estás ejecutando en otra. Comprueba `uname -m` y el `--platform` de tu
`docker run`.

---

## 9. 📋 Checklist de validación

```text
[ ] dockerfiles/03-toolchain.Dockerfile existe con los 19 paquetes de §6
[ ] El build produce legacy-node-toolchain:phase04 sin error
[ ] gcc --version   dentro del contenedor responde 8.x
[ ] g++ --version   responde 8.x
[ ] make --version  responde 4.2.x
[ ] pkg-config --version responde
[ ] file /bin/ls    identifica un ELF 64-bit x86-64
[ ] hello.c compila con gcc y el binario imprime el saludo
[ ] make clean && make reconstruye el binario
[ ] file hello confirma que es un ELF de Linux, no un binario de tu host
[ ] apt-cache depends build-essential muestra gcc, g++, make y libc6-dev
```

---

## 10. 🧪 Ejercicios de la Fase 04 (20)

## 🟢 Fácil — reconocer el toolchain (1–6)

### 🟢 Ejercicio 1 — Construye la fase y verifica las versiones

Construye `phase04` y ejecuta los seis primeros puntos del checklist.

**Objetivo:** tener el toolchain y saber qué generación de GCC trae Debian 10. Anota el
número: en [F05](05-python-y-node-gyp.md) y [F15](15-laboratorios-dependencias-nativas.md) va a importar.

### 🟢 Ejercicio 2 — Compila el hola mundo

Haz el laboratorio completo de §7, con `gcc` primero y con `make` después.

**Objetivo:** compilar algo real dentro del contenedor con el código viviendo en tu host.

### 🟢 Ejercicio 3 — `file` sobre tu propio binario

Ejecuta `file hello` dentro del contenedor, y después intenta ejecutar `./hello` en tu host.

**Pregunta:** ¿qué dice exactamente `file`, y qué error da tu host? Si tu host es Linux
x86-64, ¿por qué sí funciona?

### 🟢 Ejercicio 4 — Qué arrastra `build-essential`

Ejecuta `apt-cache depends build-essential` y después `dpkg -L build-essential | head -20`.

**Pregunta:** ¿cuántos archivos propios tiene el paquete? ¿Qué te dice eso sobre qué es un
metapaquete?

### 🟢 Ejercicio 5 — `pkg-config` en acción

Ejecuta `pkg-config --cflags --libs zlib` y después `pkg-config --list-all | head -20`.

**Objetivo:** ver qué formato tienen las banderas que `pkg-config` devuelve, que son las
mismas que le vas a ver pasar a `node-gyp`.

### 🟢 Ejercicio 6 — El tabulador del `Makefile`

Sustituye el tabulador de la receta del `Makefile` por cuatro espacios y ejecuta `make`.

**Objetivo:** provocar el `missing separator` a propósito, para reconocerlo instantáneamente
cuando aparezca en la salida de un `node-gyp` de verdad.

## 🟡 Intermedio — compilar de verdad (7–12)

### 🟡 Ejercicio 7 — `.c` con `gcc`, `.cpp` con `g++`

Escribe un `hello.cpp` mínimo con `std::cout` y compílalo con `g++`. Después intenta
compilarlo con `gcc` a secas.

**Pregunta:** ¿qué error da `gcc`, y en qué etapa de la construcción aparece — al compilar o
al enlazar?

### 🟡 Ejercicio 8 — Separa compilación de enlazado

Compila `hello.c` en dos pasos: `gcc -c hello.c -o hello.o` y luego
`gcc hello.o -o hello`. Inspecciona el `.o` con `file`.

**Pregunta:** ¿en qué se diferencia lo que dice `file` del `.o` y del ejecutable final?

### 🟡 Ejercicio 9 — Un `Makefile` con dos objetivos

Amplía el `Makefile` para que construya `hello` y `hello-cpp` desde dos fuentes distintas, y
añade un objetivo `all` que haga los dos.

**Objetivo:** entender qué decide `make` cuando ejecutas `make` a secas, y qué pasa si
cambias solo uno de los dos fuentes.

### 🟡 Ejercicio 10 — Compila contra una librería del sistema

Escribe un programa de diez líneas que use `zlib` —comprimir una cadena vale— y compílalo
usando las banderas que te dé `pkg-config`.

**Pregunta:** ¿qué pasa si omites las banderas del enlazador? Lee el error entero: es
exactamente la familia de errores de `canvas` y `sharp`.

### 🟡 Ejercicio 11 — Mide lo que pesa el toolchain

Compara `docker image ls` entre `phase03` y `phase04`.

**Pregunta:** ¿cuántos megabytes añadió el toolchain? ¿Te parece un precio razonable frente
a la alternativa de que `npm ci` falle?

### 🟡 Ejercicio 12 — Redundancia deliberada

Construye una variante del Dockerfile con **solo** `build-essential`, sin `gcc`, `g++` ni
`make` explícitos, y compara el tamaño y el resultado de `gcc --version`.

**Pregunta:** ¿cambia algo funcionalmente? Si no cambia nada, ¿por qué el curso los deja
escritos igualmente? Relee §5.

## 🟠 Difícil — cuando la compilación falla (13–17)

### 🟠 Ejercicio 13 — Predice qué reconstruye `make`

Ejecuta `make` dos veces seguidas sin tocar nada. Después haz `touch hello.c` y ejecútalo
otra vez. **Predice el resultado antes de cada ejecución.**

**Pregunta:** ¿qué usa `make` para decidir si hay que reconstruir? Guarda la respuesta: la
caché de Docker usa una idea emparentada y la vas a ver en [F12](12-capas-cache-y-contexto.md).

### 🟠 Ejercicio 14 — El paquete `-dev` que falta

Intenta compilar el programa del ejercicio 10 en una imagen donde hayas quitado `zlib1g-dev`
del `RUN`.

**Objetivo:** ver que la librería está presente en tiempo de ejecución pero faltan las
cabeceras, y aprender a leer ese error concreto.

### 🟠 Ejercicio 15 — Diagnostica sin las cabeceras

Construye una imagen con `gcc` pero **sin** `build-essential` ni `libc6-dev` e intenta
compilar `hello.c`.

**Objetivo:** provocar el `stdio.h: No such file or directory`, y explicar en dos frases por
qué el compilador está presente y aun así no puede compilar el programa más simple del
mundo.

### 🟠 Ejercicio 16 — El archivo que no era lo que decía

Descarga con `curl` una URL que devuelva un 404 guardando la salida en `paquete.tar.xz`
—por ejemplo `curl -o paquete.tar.xz https://nodejs.org/dist/v99.0.0/inexistente.tar.xz`— y
después intenta `tar -xJf paquete.tar.xz`.

**Objetivo:** ver el error críptico que produce, y comprobar que `file paquete.tar.xz` lo
explica en una línea. Este patrón exacto rompe instalaciones de módulos nativos
constantemente.

### 🟠 Ejercicio 17 — Arquitectura cruzada

Construye `phase04` para `linux/arm64` con `--platform`, compila `hello.c` dentro, y ejecuta
`file hello`.

**Pregunta:** ¿qué dice ahora `file`? Si copias ese binario a un contenedor `amd64` y lo
ejecutas, ¿qué error da y por qué?

## 🔴 Muy difícil — arqueología y criterio (18–20)

### 🔴 Ejercicio 18 — Lee un error de `node-gyp` sin tener `node-gyp`

Busca en un issue de GitHub la salida completa de un fallo de compilación de `node-sass` o
`bcrypt` — hay miles.

**Pregunta:** identifica en esa salida qué líneas vienen de `make`, cuáles de `gcc` y cuál es
el primer error real (que casi nunca es el último de la salida). Es la habilidad que más
tiempo te va a ahorrar en [F05](05-python-y-node-gyp.md) y [F15](15-laboratorios-dependencias-nativas.md).

### 🔴 Ejercicio 19 — Reconstruye el toolchain mínimo para un módulo real

Elige `bcrypt@3.0.6` —una dependencia habitual de la época— y averigua, **sin instalarlo**,
qué necesita para compilar: lee su `binding.gyp` en GitHub y su `package.json`.

**Objetivo:** producir la lista de paquetes Debian que harían falta, y contrastarla con los
diecinueve que instala nuestra imagen. ¿Sobra alguno? ¿Falta alguno?

### 🔴 Ejercicio 20 — Defiende el toolchain frente a la imagen pequeña

Un compañero propone: *"quita `build-essential` y el resto de compiladores; casi todos los
paquetes traen prebuilds y la imagen bajaría 200 MB"*.

**Objetivo:** escribir la respuesta con datos, no con opinión. Tiene que incluir el tamaño
real medido en el ejercicio 11, al menos dos escenarios concretos de §4.1 en que el prebuild
no está disponible, y la condición bajo la cual tu compañero tendría razón. Esa condición
existe — encuéntrala.

## 🔥 Opcionales

### 🔥 Ejercicio 21 — Una librería estática a mano

Compila dos archivos `.c` a objetos, empaquétalos con `ar rcs libmini.a *.o` y enlaza un
programa contra la librería resultante.

**Objetivo:** entender qué es un archivo `.a` y por qué `binutils` está en la lista. Si te
engancha, **[a03](a03-binutils-y-elf.md)** es tu apéndice.

### 🔥 Ejercicio 22 — Compara `gcc` con `cc`

Ejecuta `which cc`, `ls -la $(which cc)` y `cc --version`.

**Pregunta:** ¿qué es `cc` exactamente en Debian, y por qué muchos `Makefile` de la época lo
usan en lugar de `gcc`?

## 💀 Boss fight

### 💀 Ejercicio 23 — Boss fight: el toolchain mínimo, defendido con números

Alguien de tu equipo propone quitar `build-essential` de la imagen "porque ocupa 200 MB y
casi ningún proyecto lo usa". Te toca decidir con evidencia, no con opinión.

**Objetivo:** entregar un informe con cuatro partes. **(1) El coste:** construye dos
variantes de `03-toolchain.Dockerfile`, una con el toolchain y otra sin él, y da el tamaño de
cada una con `docker images` y el desglose por capa con `docker history`. **(2) El alcance:**
usa `dpkg -L build-essential` y `apt-cache depends build-essential` para enumerar qué arrastra
de verdad, y separa lo que es compilador de lo que es cabecera. **(3) La prueba de fallo:**
en la imagen sin toolchain, compila `hello.c` de §7 y captura el error exacto; después
instala **solo** los paquetes que ese error pide y mide cuánto creció — la pregunta real no es
"con o sin", es "cuánto de esos 200 MB era imprescindible". **(4) El veredicto:** una
recomendación de tres líneas que diga en qué caso tu compañero tiene razón.

**Pregunta:** ¿en qué punto exacto del curso —fase y sección— se convierte esa recomendación
en un error caro? Responde con la referencia y con el fallo concreto que aparecería.

---

## 11. 📚 Referencias

**GCC y el toolchain GNU**
- Documentación de GCC 8, la de Buster: https://gcc.gnu.org/onlinedocs/gcc-8.3.0/gcc/
- Manual de GNU Make: https://www.gnu.org/software/make/manual/make.html
- `pkg-config`, guía: https://people.freedesktop.org/~dbn/pkg-config-guide.html

**Debian**
- `build-essential` en Buster: https://packages.debian.org/buster/build-essential
- Política de Debian sobre paquetes `-dev`: https://www.debian.org/doc/debian-policy/ch-sharedlibs.html

**Hacia dónde va esto**
- `node-gyp`, que usa todo lo de esta fase: https://github.com/nodejs/node-gyp

> ⚠️ **El enlace de GCC apunta deliberadamente a la 8.3**, que es la de Debian 10. La
> documentación de GCC actual describe una versión con opciones y diagnósticos distintos, y
> en un laboratorio legacy eso confunde más de lo que ayuda.

**Orden de lectura sugerido:** el manual de `make` mientras haces los ejercicios 9 y 10, y la
guía de `pkg-config` justo antes del 11. GCC solo cuando necesites una bandera concreta.

---

## 12. 🏁 Resultado de la fase

```text
IMAGEN        legacy-node-toolchain:phase04
BASE          debian/eol:buster · Debian 10 · linux/amd64

CONTIENE      12 utilidades (F03)
              + binutils build-essential file g++ gcc make pkg-config
              Bash como shell · WORKDIR /workspace

NO CONTIENE   Node ❌  npm ❌  Python ❌  node-gyp ❌

PUEDES        compilar C y C++ dentro del contenedor
              ejecutar Makefiles
              identificar cualquier binario con file
              leer un error de compilación y saber quién lo emitió
```

> **La señal de que quedó bien:** *"si mañana `npm install` me falla compilando un módulo
> nativo, sé que la salida que estoy leyendo viene de `make` y de `gcc`, y sé buscar el
> primer error de verdad en lugar del último."*

En **[F05](05-python-y-node-gyp.md)** aparece la pieza que conecta npm con todo esto, y trae consigo la sorpresa más
famosa del legacy: **`node-gyp` habla Python. Python 2.**
