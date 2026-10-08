# 📦 Parte I · Fase 03 — APT y la caja de herramientas

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`)
> **Arquitectura objetivo del laboratorio:** `linux/amd64`
> **Dockerfile pedagógico de esta fase:** `dockerfiles/02-utilidades.Dockerfile`
> **Tag pedagógico:** `legacy-node-toolchain:phase03`
> **Estado de la imagen al terminar:** Debian 10 con doce utilidades y Bash como shell. Sigue sin Node, Python ni compiladores
> **Fecha de revisión de documentación externa:** 3 de septiembre de 2026
> **Código de esta fase:** [`src/03-apt-y-utilidades/`](src/03-apt-y-utilidades/)
> **Objetivo:** instalar la caja de herramientas con APT entendiendo cada opción, y responder la pregunta que casi ningún tutorial responde: por qué `apt-get update` funciona sobre un repositorio que se firmó hace años

---

## 1. 🧭 Dónde estamos

[F02](02-dockerfile-esencial.md) dejó una imagen que saluda. Tiene Debian 10, un `WORKDIR` y poco más: no hay `curl`
para descargar nada, no hay `git`, y si algo falla dentro del contenedor no tienes ni un
editor con el que mirar un archivo.

Esta fase pone la caja de herramientas. Es la primera vez que el Dockerfile ejecuta un
`RUN` de verdad, y ese `RUN` tiene más decisiones dentro de las que parece.

```text
phase02                          phase03  ← esta fase
────────                         ────────
Debian 10                        Debian 10
WORKDIR /workspace               WORKDIR /workspace
CMD saludo                       CMD saludo
                                 + 12 utilidades
                                 + Bash como shell del laboratorio
```

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder explicar:

- Qué hacen `apt-get update` y `apt-get install`, y por qué van en el **mismo** `RUN`.
- Qué significan `-y` y `--no-install-recommends`, y qué **no** significa el segundo.
- Por qué borramos `/var/lib/apt/lists` en la misma capa y qué consecuencia tiene.
- Qué doce paquetes instalamos y por qué cada uno.
- **Por qué APT acepta un archivo firmado hace años**, qué dos mecanismos lo permiten, y
  cuál de los dos está trabajando de verdad hoy.

---

## 3. 🚧 Qué NO entra todavía

- El tratado de APT: `apt` frente a `apt-get` frente a `apt-cache` frente a `dpkg`,
  mirrors, anatomía completa del `sources.list`, `Depends`/`Recommends`/`Suggests`,
  dependencias transitivas, y una guía de supervivencia en la shell del contenedor →
  **[a01](a01-debian-y-apt-a-fondo.md)**.
- Por qué ese `RUN` único es también una decisión de **caché** → **[F12](12-capas-cache-y-contexto.md)**.
- Por qué borrar un archivo en una capa posterior **no** reduce el tamaño de la imagen →
  **[F13](13-overlayfs-y-copy-on-write.md)**.
- El compilador, Python y Node: cada uno tiene su fase (**[F04](04-toolchain-de-compilacion.md)**, **[F05](05-python-y-node-gyp.md)**, **[F06](06-instalacion-node.md)**).

---

## 4. 📦 APT en lo justo para hoy

Un **paquete Debian** es un archivo `.deb`: binarios, archivos de configuración, metadatos
y la lista de qué otros paquetes necesita. **APT** es el sistema que resuelve esas
dependencias y los instala, y trabaja en dos tiempos que conviene no confundir.

```text
apt-get update                         apt-get install curl
──────────────                         ────────────────────
descarga los ÍNDICES:                  descarga los PAQUETES:
qué paquetes existen,                  los .deb de curl y de todo
qué versión, dónde,                    lo que curl necesite, y
qué hash                               los instala

no instala nada                        necesita los índices del paso anterior
→ /var/lib/apt/lists/                  → /var/cache/apt/archives/
```

Esa separación explica el error más común del mundo Docker: un `apt-get install` que falla
con *"Unable to locate package"* en una imagen donde el paquete existe perfectamente. No
existe **para APT**, porque nadie descargó los índices.

### 4.1 Las cuatro opciones de nuestro `RUN`

```dockerfile
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl git \
    && rm -rf /var/lib/apt/lists/*
```

**`&&` en vez de líneas sueltas.** Encadena los comandos y —esto es lo importante— hace que
el `RUN` falle si falla cualquiera de ellos. Con `;` en su lugar, un `update` que falla no
detendría el build y acabarías con una imagen construida sobre índices que no se
descargaron.

**`-y`** responde "sí" automáticamente a la pregunta de confirmación. No es pereza: durante
un build no hay nadie al teclado, y sin `-y` el proceso se cuelga esperando una respuesta
que nunca llega.

**`--no-install-recommends`** instala las dependencias obligatorias (`Depends`) pero no las
recomendadas (`Recommends`). Debian marca como recomendado lo que "casi siempre quieres"
—documentación, plugins, herramientas relacionadas—, y en un contenedor eso suele traducirse
en cientos de megabytes que nadie va a usar.

> ⚠️ **`--no-install-recommends` NO significa "sin dependencias".** Es un malentendido que
> produce mucha frustración: las dependencias reales se instalan igual, incluidas las
> transitivas. Lo único que se omite es la capa de *"esto también podría interesarte"*. Si
> un paquete no funciona después de usarlo, la causa suele ser que necesitaba de verdad algo
> marcado como `Recommends` — y la solución es añadirlo explícitamente, no quitar la opción.

**`rm -rf /var/lib/apt/lists/*`** borra los índices descargados, que ya cumplieron su
función. Son varias decenas de megabytes de listas de paquetes que la imagen no necesita
para funcionar.

### 4.2 Por qué todo va en un solo `RUN`

Esta es la parte que parece manía de estilo y no lo es. Compara:

```dockerfile
# ❌ mal
RUN apt-get update
RUN apt-get install -y --no-install-recommends curl
RUN rm -rf /var/lib/apt/lists/*
```

```dockerfile
# ✅ bien
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*
```

Dos problemas distintos con la versión de arriba. El primero es de **tamaño**: cada `RUN`
produce una capa, y una capa posterior que borra un archivo **no lo elimina de las
anteriores** — la imagen sigue cargando con los índices para siempre, solo que invisibles.
El segundo es de **caché**: si más adelante añades un paquete al segundo `RUN`, el primero
se reutiliza de la caché y te instala paquetes según unos índices que pueden tener meses.

Los dos mecanismos tienen su fase: la caché es de **[F12](12-capas-cache-y-contexto.md)** y el copy-on-write que explica lo
del tamaño es de **[F13](13-overlayfs-y-copy-on-write.md)**. Aquí basta con la regla.

> 🧭 **El patrón a memorizar:** *lo que se descarga, se usa y se limpia en la misma capa.*
> Vale para APT y va a volver a valer, idéntico, cuando descarguemos los tarballs de Node en
> [F06](06-instalacion-node.md).

Y su contrapartida honesta: **después de esta imagen, `apt-get install` no funciona sin un
`apt-get update` previo**, porque los índices ya no están. Es el precio de la limpieza y
conviene saberlo antes de estar dentro del contenedor preguntándote qué pasa.

---

## 5. 🔏 Por qué APT acepta un archivo firmado hace años

Aquí es donde esta fase se separa del tutorial habitual. Ya sabemos *dónde* están los
paquetes de Buster —en `archive.debian.org`, por lo que decidió [F01](01-decisiones-debian-zonas-node.md)—. Falta la otra mitad:
**por qué APT los acepta**.

### 5.1 Los dos temporizadores que juegan en contra

La seguridad de APT es una cadena que arranca en una sola firma. Cada suite publica un
archivo `Release` —o `InRelease`, el mismo contenido con la firma incrustada— donde viven
los hashes de todos los índices. APT descarga ese archivo, verifica su firma GPG contra las
claves de `/etc/apt/trusted.gpg.d/`, y solo entonces confía en los hashes. Todo lo demás
—los índices `Packages`, y después los `.deb`— se valida por hash contra ese documento
firmado.

Ese diseño lleva dos relojes incorporados, y los dos juegan en contra de una distribución
muerta:

**El campo `Valid-Until`** dentro del `Release` es una fecha de caducidad del documento,
pensada para que un atacante no pueda servirte indefinidamente una lista de paquetes vieja
—y por lo tanto vulnerable— aunque esté correctamente firmada. Si ya pasó, APT rechaza el
repositorio.

**La expiración de la clave GPG** que firmó el documento. Las claves de archivo de Debian
tienen fecha de vencimiento; cuando vencen, `gpgv` reporta `EXPKEYSIG` en lugar de `GOODSIG`
y APT lo interpreta como firma no válida.

Un repositorio activo renueva las dos cosas cada pocas horas. Un repositorio archivado, por
definición, ya no renueva nada. De ahí el error que casi todo el mundo ha visto:

```text
E: Release file for http://archive.debian.org/debian/dists/buster/InRelease
   is not valid yet (invalid for another Xd Yh) / expired
E: The repository '...' is no longer signed.
```

### 5.2 Las dos líneas que la imagen ya trae puestas

`debian/eol:buster` viene con el problema resuelto de fábrica, y la solución son dos
archivos de configuración que puedes leer tú mismo:

```bash
docker run --rm --platform linux/amd64 \
  legacy-node-toolchain:phase02 \
  sh -c 'cat /etc/apt/apt.conf.d/check-valid-until.conf; \
         cat /etc/apt/apt.conf.d/debuerreotype-gpgv-ignore-expiration'
```

Salida real, sin recortar:

```text
Acquire::Check-Valid-Until "false";

# For the sake of EOL releases (whose archive keys have often expired), we need
# a fake "gpgv" substitute that will essentially ignore *just* key expiration.
# (So we get *some* signature validation instead of using something like
# "--allow-unauthenticated" or "--force-yes" which disable security entirely
# instead.)

Apt::Key::gpgvcommand "/usr/local/bin/.debuerreotype-gpgv-ignore-expiration";
```

La primera apaga el temporizador del documento. La segunda es más interesante: no apaga la
verificación de firma, la **redirige**. En lugar del `gpgv` del sistema, APT llama a un
script que envuelve a `gpgv`, lee su salida de estado y reemplaza exactamente una cadena:

```bash
sedExpression='s/^\[GNUPG:\] EXPKEYSIG /[GNUPG:] GOODSIG /'
```

Eso es todo lo que hace. La firma se sigue verificando de verdad contra las claves de
Debian; lo único que se neutraliza es el veredicto sobre la **fecha de la clave**. Una firma
falsa sigue rechazándose, un `Release` manipulado sigue sin cuadrar, y los hashes de los
índices siguen mandando.

> 🧠 **Modelo mental.** Hay dos formas de "hacer que apt funcione" contra un archivo
> histórico. `--allow-unauthenticated`, `--force-yes` o un `[trusted=yes]` en el
> `sources.list` **apagan la verificación entera**: te tragas lo que responda el servidor. El
> truco de `debuerreotype` mantiene la criptografía intacta y desactiva solo el reloj. La
> diferencia entre las dos es la que separa un laboratorio defendible de un `curl | sudo
> bash`.

### 5.3 🩺 Comprobar cuál de los dos mecanismos trabaja hoy

Aquí el curso se separa de la explicación de blog, porque la respuesta honesta cambia con el
tiempo y se puede medir. Borramos los índices y le pedimos a APT que se comporte como si las
dos configuraciones no existieran, sobreescribiéndolas desde la línea de comandos:

```bash
docker run --rm --platform linux/amd64 \
  legacy-node-toolchain:phase02 \
  sh -c 'rm -rf /var/lib/apt/lists/*; \
         apt-get -o Acquire::Check-Valid-Until=true \
                 -o Apt::Key::gpgvcommand=gpgv \
                 update'
```

Verificado el 3 de septiembre de 2026, esto **funciona**:

```text
Get:1 http://archive.debian.org/debian buster InRelease [122 kB]
Get:2 http://archive.debian.org/debian-security buster/updates InRelease [34.8 kB]
Get:3 http://archive.debian.org/debian buster-updates InRelease [56.6 kB]
Get:4 http://archive.debian.org/debian buster/main amd64 Packages [7909 kB]
...
Fetched 8741 kB in 4s (1983 kB/s)
Reading package lists...
```

Por dos razones, y las dos se pueden verificar. Entra al contenedor con `apt-get update` ya
ejecutado:

```bash
docker run --rm -it --platform linux/amd64 legacy-node-toolchain:phase02 bash
```

**Primera razón:** cuando Debian archiva una release, regenera el `Release` **sin el campo
`Valid-Until`**, precisamente para que el archivo histórico siga siendo utilizable.

```bash
# dentro del contenedor, tras apt-get update
grep -cE '^Valid-Until:' \
  /var/lib/apt/lists/archive.debian.org_debian_dists_buster_InRelease
```
```text
0
```

**Segunda razón:** las claves de archivo de Buster todavía no han vencido. Pregúntale
directamente a `gpgv`, que es el programa que APT usa por debajo:

```bash
# dentro del contenedor
gpgv --status-fd 1 \
  --keyring /etc/apt/trusted.gpg.d/debian-archive-buster-stable.gpg \
  --keyring /etc/apt/trusted.gpg.d/debian-archive-buster-automatic.gpg \
  /var/lib/apt/lists/archive.debian.org_debian_dists_buster_InRelease \
  | grep -E 'GOODSIG|EXPKEYSIG'
```
```text
[GNUPG:] GOODSIG 648ACFD622F3D138 Debian Archive Automatic Signing Key (10/buster) <ftpmaster@debian.org>
[GNUPG:] GOODSIG DCC9EFBF77E11517 Debian Stable Release Key (10/buster) <debian-release@lists.debian.org>
```

`GOODSIG`, no `EXPKEYSIG`. Hoy, para Buster, las dos configuraciones son **una red de
seguridad que no está sosteniendo peso**.

### 5.4 Entonces, ¿sobran? No

Sobrarían si el archivo histórico fuera inmutable y las claves eternas, y no es el caso. Esa
red pasa a sostener peso en tres situaciones previsibles:

**Cuando las claves de Buster venzan.** Ya pasó con releases anteriores; es cuestión de
calendario, no de si ocurre. El día que ocurra, `apt-get update` empieza a fallar en una
imagen que no cambió nada, y la única diferencia entre seguir trabajando y quedarte parado
es ese archivo de cuatro líneas.

**Si apuntas a `snapshot.debian.org`.** Las líneas comentadas del `sources.list` llevan a
snapshots con fecha, donde sí puedes encontrar documentos con `Valid-Until` de la época,
vencidos hace años.

**Si trabajas con una release aún más vieja.** Stretch, Jessie o Wheezy tienen el problema en
su forma completa, y su imagen `debian/eol` trae la misma configuración por el mismo motivo.

> ⚠️ **Lo que esto no te da.** Que la firma verifique no significa que el paquete sea seguro:
> significa que es **auténticamente el paquete que Debian publicó en su día**, con las
> vulnerabilidades que tuviera y sin parches posteriores. La verificación demuestra origen e
> integridad, nunca ausencia de CVE.

> 💡 **El patrón a memorizar.** Cuando algo "sencillamente funciona" en una imagen base y en
> tu máquina no, la respuesta casi siempre está en `/etc/apt/apt.conf.d/`,
> `/etc/apt/preferences.d/` o un `ENV` heredado — no en magia del registry. Lee la
> configuración que trae la imagen antes de escribir la tuya.

---

## 6. 🧰 La caja de herramientas: doce paquetes

Estos son los doce, en orden alfabético — porque una lista ordenada se lee mejor, se revisa
mejor y produce diffs de Git limpios. No es una exigencia de APT, es mantenimiento.

| Paquete | Para qué lo queremos aquí |
|---|---|
| `bash` | El shell del laboratorio. Debian trae `dash` como `/bin/sh`, que no es lo mismo |
| `ca-certificates` | Sin él, cualquier descarga HTTPS falla con un error de certificado |
| `curl` | Descargar los tarballs de Node en [F06](06-instalacion-node.md), y probar servicios en [F18](18-networking-de-contenedores.md) |
| `git` | Inspeccionar el repositorio desde dentro cuando haga falta |
| `jq` | Leer `package.json` y salidas JSON sin escribir un script |
| `less` | Paginar salidas largas sin salir del contenedor |
| `procps` | `ps`, `top`, `kill`. Imprescindible cuando investiguemos PID 1 en [F16](16-pid1-senales-y-ciclo-de-vida.md) |
| `unzip` / `zip` | Artefactos comprimidos, que en proyectos legacy aparecen seguido |
| `vim` | Editar un archivo dentro del contenedor para probar algo rápido |
| `wget` | La alternativa a `curl` cuando un script de la época lo asume |
| `xz-utils` | **Obligatorio**: los tarballs oficiales de Node son `.tar.xz` |

Dos merecen una nota. **`ca-certificates`** parece prescindible hasta que lo es: sin él,
`curl https://nodejs.org` falla con un error de verificación que no menciona los
certificados en ninguna parte. Y **`xz-utils`** es la razón de que este paquete esté aquí y
no en [F06](06-instalacion-node.md): sin él, el `tar` de Debian no sabe descomprimir el formato en que Node publica
sus binarios.

> 📝 **Nota de época.** Muchos Dockerfiles de 2018 instalaban `build-essential` en esta
> misma línea "por si acaso". Nosotros lo dejamos para **[F04](04-toolchain-de-compilacion.md)**, donde tiene su propia
> justificación — y donde vas a ver cuánto pesa realmente.

---

## 7. 🐚 Bash como shell del laboratorio

Debian usa `dash` como `/bin/sh` porque es más rápido para los scripts de arranque del
sistema. Es POSIX estricto, y eso significa que no tiene arrays, ni `[[ ]]`, ni
`pipefail` — tres cosas que los scripts de este curso van a usar.

Por eso la imagen fija Bash en dos sitios:

```dockerfile
SHELL ["/bin/bash", "-c"]
ENV SHELL=/bin/bash
```

**`SHELL`** cambia el intérprete que usan los `RUN` **siguientes** en el propio Dockerfile,
lo que evita sorpresas al escribir scripts multilínea en las fases que vienen. **`ENV
SHELL`** deja constancia para los programas que consultan esa variable en runtime, y es lo
que hace que `docker exec -it ... bash` se sienta como un shell de verdad.

---

## 8. 🏗️ El Dockerfile de la fase

📄 **`dockerfiles/02-utilidades.Dockerfile`**

```dockerfile
# syntax=docker/dockerfile:1

FROM debian/eol:buster

LABEL org.opencontainers.image.title="legacy-node-toolchain"
LABEL org.opencontainers.image.description="Toolchain de desarrollo para proyectos Node.js legacy"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash \
       ca-certificates \
       curl \
       git \
       jq \
       less \
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

- Un solo `RUN` para `update`, `install` y limpieza, por §4.2.
- Un paquete por línea y en orden alfabético: añadir uno produce un diff de una línea, no de
  todo el bloque.
- `SHELL` va **después** del `RUN` de APT, porque hasta ese momento Bash podría no estar
  garantizado con la configuración que queremos.
- El `CMD` sigue siendo el saludo. Esta fase no cambia lo que hace la imagen al arrancar,
  solo lo que contiene.

Construir:

```bash
docker build \
  --platform linux/amd64 \
  --file dockerfiles/02-utilidades.Dockerfile \
  --tag legacy-node-toolchain:phase03 \
  .
```

---

## 9. 🔥 Prueba de fuego

Tres comprobaciones que cierran la fase.

**Las herramientas están y responden:**

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase03 \
  bash -c 'for t in bash curl wget git jq less ps vim zip unzip xz; do
             printf "%-8s %s\n" "$t" "$(command -v $t || echo AUSENTE)"
           done'
```
```text
bash     /bin/bash
curl     /usr/bin/curl
wget     /usr/bin/wget
git      /usr/bin/git
jq       /usr/bin/jq
less     /usr/bin/less
ps       /bin/ps
vim      /usr/bin/vim
zip      /usr/bin/zip
unzip    /usr/bin/unzip
xz       /usr/bin/xz
```

**HTTPS funciona**, que es lo que verifica que `ca-certificates` hizo su trabajo:

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase03 \
  curl -sI https://nodejs.org/dist/ | head -1
```
```text
HTTP/2 200
```

**Los índices se limpiaron**, que es la consecuencia declarada de §4.2:

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase03 \
  bash -c 'ls -1 /var/lib/apt/lists/ | wc -l'
```
```text
0
```

---

## 10. ⚠️ Errores comunes y diagnóstico

**`E: Unable to locate package <lo-que-sea>`** dentro del contenedor. Los índices están
borrados por diseño. Ejecuta `apt-get update` antes del `install`. Si además el paquete no
existe en Buster, la salida lo dirá igual — y ahí la causa es otra: Buster tiene el catálogo
de 2019, no el de hoy.

**`curl: (60) SSL certificate problem`** al descargar por HTTPS. Falta `ca-certificates`, o
lo instalaste pero en otra capa que se perdió. El error habla de certificados sin mencionar
nunca el paquete. Y si `ca-certificates` **sí** está y el error persiste, la causa suele ser
otra: un proxy corporativo que inspecciona el TLS — **[a13](a13-air-gapped.md) §4**.

**`tar: unrecognized compression format`** al abrir un `.tar.xz`. Falta `xz-utils`. Es el
que más sorprende porque `tar` sí está instalado: lo que falta es el descompresor.

**El repositorio de golpe "ya no está firmado".** Si algún día ves
`The repository ... is no longer signed`, lee §5.4: probablemente vencieron las claves de
Buster y tu imagen sigue funcionando **gracias a** los dos archivos de configuración que
hoy no hacían falta.

**`bash: [[: not found`** en un script tuyo. Lo estás ejecutando con `sh` y no con `bash`.
Comprueba el shebang del script y la forma del `RUN`.

---

## 11. 📋 Checklist de validación

```text
[ ] dockerfiles/02-utilidades.Dockerfile existe con el contenido de §8
[ ] El build termina sin error y produce legacy-node-toolchain:phase03
[ ] Las once herramientas de la prueba de fuego responden con una ruta
[ ] curl -sI https://nodejs.org/dist/ devuelve HTTP/2 200 desde dentro
[ ] /var/lib/apt/lists/ está vacío
[ ] readlink -f /proc/$$/exe dentro de un docker exec devuelve bash
[ ] Leíste los dos archivos de /etc/apt/apt.conf.d/ de §5.2 con tus ojos
[ ] Ejecutaste el experimento de §5.3 y viste que apt funciona sin esas dos opciones
[ ] Puedes explicar por qué update, install y rm van en el mismo RUN
```

---

## 12. 🧪 Ejercicios de la Fase 03 (25)

## 🟢 Fácil — reconocer APT y la caja (1–7)

### 🟢 Ejercicio 1 — Construye la fase y pasa la prueba de fuego

Construye `phase03` y ejecuta las tres comprobaciones de §9.

**Objetivo:** tener la imagen con la caja de herramientas y haber verificado las tres cosas
que la fase promete.

### 🟢 Ejercicio 2 — Cuenta los paquetes instalados

Ejecuta `dpkg -l | wc -l` en `phase02` y en `phase03`.

**Pregunta:** pediste doce paquetes. ¿Cuántos se instalaron realmente, y qué te dice la
diferencia sobre las dependencias transitivas?

### 🟢 Ejercicio 3 — Lee el `sources.list`

Ejecuta `cat /etc/apt/sources.list` dentro del contenedor.

**Pregunta:** ¿a qué dominio apunta, qué líneas están comentadas y para qué servirían?

### 🟢 Ejercicio 4 — Los índices sí desaparecieron

Ejecuta `apt-get install -y tree` dentro de `phase03` sin hacer `update` antes.

**Objetivo:** ver el error con tus ojos, entender que es una consecuencia declarada de la
limpieza y no un fallo, y resolverlo con un `apt-get update` previo.

### 🟢 Ejercicio 5 — `dash` no es `bash`

Ejecuta `sh -c 'if [[ 1 == 1 ]]; then echo si; fi'` y después lo mismo con `bash -c`.

**Pregunta:** ¿qué error da el primero y por qué el Dockerfile fija `SHELL`?

### 🟢 Ejercicio 6 — Qué instaló un paquete

Ejecuta `dpkg -L jq` y `dpkg -s jq`.

**Objetivo:** saber consultar qué archivos puso un paquete y en qué versión, que es la
primera pregunta cuando algo "está instalado pero no funciona".

### 🟢 Ejercicio 7 — Lee la configuración que salva el build

Ejecuta el comando de §5.2 y lee los dos archivos completos.

**Pregunta:** ¿cuál de los dos apaga una verificación y cuál la redirige? Explica la
diferencia en una frase.

## 🟡 Intermedio — usar APT de verdad (8–14)

### 🟡 Ejercicio 8 — Mide lo que ahorra `--no-install-recommends`

Construye dos imágenes que instalen `vim` y `git`: una con la opción y otra sin ella.
Compara con `docker image ls`.

**Pregunta:** ¿cuántos megabytes de diferencia hay, y cuántos paquetes extra aparecen en
`dpkg -l`?

### 🟡 Ejercicio 9 — Añade un paquete y observa la caché

Añade `tree` a la lista alfabética del `RUN` y reconstruye. Observa qué pasos dicen `CACHED`.

**Pregunta:** ¿se reutilizó el `RUN` de APT? ¿Y si en lugar de añadir un paquete cambias un
`LABEL` de arriba?

### 🟡 Ejercicio 10 — Sin `ca-certificates`

Construye una imagen con los doce paquetes **menos** `ca-certificates` e intenta el `curl`
HTTPS de §9.

**Objetivo:** provocar el error de certificado y comprobar que su mensaje no menciona en
ningún momento el paquete que falta. Es un patrón que se repite todo el curso.

### 🟡 Ejercicio 11 — Sin `xz-utils`

Construye una imagen sin `xz-utils` y descarga un tarball de Node con `curl`, después intenta
`tar -xJf`.

**Pregunta:** ¿por qué falla si `tar` sí está instalado? Guarda la respuesta: en [F06](06-instalacion-node.md) la vas a
necesitar.

### 🟡 Ejercicio 12 — Consulta antes de instalar

Con los índices descargados, usa `apt-cache policy git` y `apt-cache depends git`.

**Objetivo:** ver qué versión exacta de Git trae Buster y de qué depende, sin instalar nada.
Es la herramienta que usarás para decidir si un paquete de la época te sirve.

### 🟡 Ejercicio 13 — Fija la versión de un paquete

Cambia `git` por `git=1:2.20.1-2+deb10u9` en el `RUN` y reconstruye.

**Pregunta:** ¿funcionó? ¿Qué pasa si la versión que pones no existe en el archivo, y qué te
dice eso sobre pinnear paquetes Debian frente a pinnear versiones de Node?

### 🟡 Ejercicio 14 — Abre un `.deb` sin instalarlo

Un `.deb` no es magia: es un `ar` con dos tarballs dentro. Descárgalo y destrípalo sin
instalar nada:

```bash
apt-get update && apt-get download jq
ar t jq_*.deb                      # las tres piezas del paquete
dpkg -x jq_*.deb /tmp/extraido     # solo los archivos
dpkg -e jq_*.deb /tmp/control      # solo los metadatos
cat /tmp/control/control
```

**Pregunta:** ¿qué tres miembros tiene el archivo y qué hay en cada uno? Compara la lista de
`Depends:` del archivo `control` con lo que te dijo `apt-cache depends jq` en el ejercicio 12.
Y la parte útil: si estuvieras en la red aislada de **[a13](a13-air-gapped.md)** y solo pudieras
llevarte archivos, ¿te bastaría con estos `.deb`?

## 🟠 Difícil — diagnosticar y medir (15–21)

### 🟠 Ejercicio 15 — Predice antes de medir: tres `RUN` contra uno

Escribe dos Dockerfiles que instalen los mismos doce paquetes: uno con el `RUN` único y otro
con `update`, `install` y `rm` en tres `RUN` separados. **Predice cuál pesará más y cuánto**,
después mídelo.

**Objetivo:** comprobar que el `rm` de la tercera capa no reduce el tamaño, y quedarte con la
pregunta de por qué — que responde [F13](13-overlayfs-y-copy-on-write.md).

### 🟠 Ejercicio 16 — Repara un `RUN` roto

Este `RUN` falla. **Predice el error antes de construirlo:**

```dockerfile
RUN apt-get update; apt-get install --no-install-recommends curl
```

**Pregunta:** hay **tres** problemas. Uno hace que el build se cuelgue, otro hace que un fallo
pase desapercibido, y el tercero solo se nota semanas después. Identifícalos.

### 🟠 Ejercicio 17 — Desactiva la red de seguridad

Ejecuta el experimento de §5.3 pero al revés: en una imagen `debian:buster` **normal** —no
la `eol`— intenta `apt-get update`.

**Objetivo:** ver el fallo real de un `sources.list` que apunta a mirrors que ya no sirven
Buster, y entender por qué [F01](01-decisiones-debian-zonas-node.md) eligió `debian/eol:buster` y no `debian:buster`.

### 🟠 Ejercicio 18 — La caché que oculta el cambio

Construye `phase03`. Después edita solo el `LABEL` de descripción y reconstruye. Después
edita solo la lista de paquetes y reconstruye. Anota qué pasos dicen `CACHED` en cada caso.

**Pregunta:** ¿por qué un cambio en la línea 5 invalida el `RUN` de la línea 8, pero un cambio
en la línea 8 no invalida nada de antes? Formula la regla con tus palabras.

### 🟠 Ejercicio 19 — Audita la fecha de las claves

Usando `gpg --list-packets` o `apt-key list` sobre los keyrings de
`/etc/apt/trusted.gpg.d/`, averigua **cuándo vencen** las claves de Buster.

**Objetivo:** poner fecha al escenario de §5.4 y saber a partir de cuándo esos dos archivos
de configuración pasan de ser decorativos a ser imprescindibles.

### 🟠 Ejercicio 20 — Pesa los índices que borramos

El Dockerfile termina el `RUN` con `rm -rf /var/lib/apt/lists/*` y la fase dice que eso
ahorra espacio. Ponle número. Construye una imagen **sin** esa limpieza y mide dentro:

```bash
du -sh /var/lib/apt/lists/
docker image ls
```

**Pregunta:** ¿cuánto ocupan los índices y cuánto crece la imagen final? Ahora la parte que
importa: haz la limpieza en un `RUN` **posterior** en vez de en el mismo, mide otra vez y
explica por qué el número no baja. Si no puedes explicarlo todavía, es exactamente la deuda
que **[F13](13-overlayfs-y-copy-on-write.md)** §12 paga con la tabla A/B/C.

### 🟠 Ejercicio 21 — Congela el tiempo con `snapshot.debian.org`

`archive.debian.org` te da Buster tal como quedó al morir. **`snapshot.debian.org` te da
Buster tal como estaba un día concreto**, que es otra cosa y a veces es la que necesitas.
Cambia el `sources.list` de una imagen para apuntar a una fecha:

```text
deb https://snapshot.debian.org/archive/debian/20190701T000000Z/ buster main
```

Instala `git` desde ahí y compara la versión con la que te da el archivo normal.

**Pregunta:** ¿son la misma versión? ¿Y qué problema resuelve esto que `archive.debian.org` no
resuelve — es decir, en qué caso te importa el Buster **de julio de 2019** y no el Buster
final? Pista: piensa en un proyecto cuyo `package-lock.json` es de esa fecha.

## 🔴 Muy difícil — arqueología y criterio (22–25)

### 🔴 Ejercicio 22 — Revive un `apt-get` de 2019

Este fragmento es de un Dockerfile real de la época y hoy no funciona:

```dockerfile
FROM debian:buster
RUN apt-get update && apt-get install -y curl build-essential
```

**Objetivo:** hacerlo funcionar hoy con la **corrección mínima**, y después escribir cuál
sería la **solución estructural**. Son distintas, y explicar la diferencia es media lección
del curso. Documenta qué error diste primero, qué hipótesis probaste y cuál la confirmó.

### 🔴 Ejercicio 23 — Construye tu propia red de seguridad

Sin usar la imagen `debian/eol`, parte de `debian:buster` y consigue que `apt-get update`
funcione contra `archive.debian.org` **sin desactivar la verificación de firmas**. Es decir:
nada de `--allow-unauthenticated`, `--force-yes` ni `[trusted=yes]`.

**Pregunta:** ¿qué tuviste que reproducir de lo que hace `debian/eol`, y en qué se diferencia
tu solución de simplemente apagar la seguridad? Si tu respuesta incluye `trusted=yes`, vuelve
a leer §5.2.

### 🔴 Ejercicio 24 — El paquete que Buster tiene demasiado viejo

Tu proyecto legacy necesita una librería del sistema, y la versión que trae Buster es
anterior a la que el proyecto pide. Es una situación real y frecuente, y tiene **cuatro**
salidas, no una: usar la de Buster y adaptar el proyecto, traerla de `backports`, compilarla
desde fuente dentro de la imagen, o cambiar de base y renunciar a Buster.

**Objetivo:** elegir una librería concreta —`libssl-dev` sirve— y escribir las cuatro
opciones con su coste real: qué se rompe, cuánto pesa la imagen, cuánto tarda el build y qué
pasa dentro de dos años. Después **elige una y defiéndela**, sabiendo que la respuesta
correcta depende del proyecto y no existe en abstracto.

**Pregunta de cierre:** ¿cuál de las cuatro contradice la regla de [F01](01-decisiones-debian-zonas-node.md)
de "compatibilidad antes que novedad", y en qué circunstancia esa contradicción está
justificada?

### 🔴 Ejercicio 25 — Audita los doce paquetes contra un proyecto real

Los doce paquetes de §6 no salieron de una encuesta: son una apuesta sobre lo que un
proyecto de 2018 va a necesitar. Ponla a prueba con uno de verdad. Coge uno de los fixtures
de `src/11-validar-tu-proyecto/` —o tu propio proyecto, mejor— y responde con evidencia, no
con intuición:

**Objetivo:** producir tres listas. **Sobran:** paquetes de los doce que ese proyecto no toca
nunca, demostrado quitándolos y viendo que todo sigue funcionando. **Faltan:** cosas que el
proyecto necesita y no están, encontradas por el método de fallar y leer el error, no
adivinando. **Discutibles:** los que están por comodidad del humano —`vim`, `less`— y no por
necesidad de la máquina, con tu criterio sobre si un laboratorio debe llevarlos.

**Pregunta:** después de las tres listas, ¿la caja de §6 está bien calibrada para tu proyecto,
o el curso eligió para otro? Un "está bien" sin las tres listas detrás no vale.

## 🔥 Opcionales

### 🔥 Ejercicio 26 — La caja mínima

Elimina paquetes del `RUN` uno a uno y reconstruye, hasta encontrar el conjunto mínimo con el
que las fases [F04](04-toolchain-de-compilacion.md), [F05](05-python-y-node-gyp.md) y [F06](06-instalacion-node.md) podrían seguir funcionando.

**Pregunta:** ¿cuáles son de verdad imprescindibles y cuáles están por comodidad? Justifica
cada exclusión — y guarda la lista, porque en [F12](12-capas-cache-y-contexto.md) vas a poder medir cuánto pesaba cada una.

### 🔥 Ejercicio 27 — `Recommends` con nombre y apellido

Instala uno de los doce paquetes de §6 dos veces, en dos imágenes distintas: una con
`--no-install-recommends` y otra sin la bandera. Compara con `dpkg -l | wc -l` y con
`docker images` cuántos paquetes y cuántos MB de diferencia hay.

**Objetivo:** dar los dos números y nombrar **tres** paquetes concretos que entraron por
`Recommends` y que el laboratorio no necesita para nada. Si quieres el porqué completo del
mecanismo, está en [a01 §4](a01-debian-y-apt-a-fondo.md).

## 💀 Boss fight

### 💀 Ejercicio 28 — Boss fight: la imagen que dejó de construir en enero

Te entregan un Dockerfile de un equipo que llevaba dos años construyendo sin tocar nada y que
hoy falla. Es este, y el error que reportan es `Release file ... is not valid yet` seguido, en
otro intento, de `Unable to locate package procps`:

```dockerfile
FROM debian/eol:buster
RUN apt-get install -y --no-install-recommends procps vim jq
RUN apt-get install -y build-essential
```

**Objetivo:** resolverlo entero y **por capas de causa**, no a golpe de parche. Tienes que:
(1) reproducir los **dos** errores por separado y explicar por qué son distintos —uno es de
§5, el de la firma vencida y el reloj; el otro es de §4, el índice que no existe—;
(2) demostrar con `apt-cache policy` que sin `apt-get update` el índice está vacío, y con
`ls /var/lib/apt/lists/` que ese estado no sobrevive entre capas como el autor creía;
(3) arreglarlo respetando las tres reglas de §8: un solo `RUN`, `--no-install-recommends`,
y `rm -rf /var/lib/apt/lists/*` al final; (4) medir con `docker history` el tamaño antes y
después de esa limpieza, y decir el número.

**Pregunta de cierre:** si mañana el reloj del host se adelanta dos años, ¿tu versión
corregida sigue construyendo? Justifica con lo que §5 explica sobre `Check-Valid-Until`, y
di explícitamente cuál es el precio de seguridad de esa decisión.

---

## 13. 📚 Referencias

**APT y Debian**
- `apt.conf(5)`, configuración de APT en Buster: https://manpages.debian.org/buster/apt/apt.conf.5.en.html
- `apt-get(8)` en Buster: https://manpages.debian.org/buster/apt/apt-get.8.en.html
- `sources.list(5)`: https://manpages.debian.org/buster/apt/sources.list.5.en.html
- Debian Archive: https://www.debian.org/distrib/archive
- Snapshots por fecha: https://snapshot.debian.org

**Cómo se generan las imágenes EOL**
- `debuerreotype`, donde vive el script de `gpgv` de §5.2: https://github.com/debuerreotype/debuerreotype

**Buenas prácticas de Dockerfile con APT**
- https://docs.docker.com/build/building/best-practices/#apt-get

> ⚠️ **Los manpages están enlazados a la versión de Buster a propósito.** Las páginas
> `manpages.debian.org/stable/...` describen APT actual, que tiene opciones y
> comportamientos distintos. Cuando dudes de una opción en este laboratorio, la referencia
> buena es la de Buster.

**Orden de lectura sugerido:** `apt-get(8)` primero, `sources.list(5)` cuando toque el
ejercicio 3, y `apt.conf(5)` solo si quieres entender del todo §5.2.

---

## 14. 🏁 Resultado de la fase

```text
IMAGEN        legacy-node-toolchain:phase03
BASE          debian/eol:buster · Debian 10 · linux/amd64

CONTIENE      12 utilidades: bash ca-certificates curl git jq less
                             procps unzip vim wget xz-utils zip
              Bash como SHELL del build y como ENV del runtime
              WORKDIR /workspace

NO CONTIENE   Node ❌  npm ❌  Python ❌  GCC ❌  make ❌
              índices de APT (borrados a propósito)

SABES         qué hacen update e install y por qué van juntos
              qué significan -y y --no-install-recommends
              por qué APT acepta una firma de hace años
              y cuál de los dos mecanismos lo está consiguiendo hoy
```

> **La señal de que quedó bien:** *"si alguien me enseña un `apt-get` que falla en una imagen
> vieja, sé mirar `/etc/apt/apt.conf.d/` antes de proponer `--allow-unauthenticated`."*

En **[F04](04-toolchain-de-compilacion.md)** llega la pregunta que sorprende a todo el mundo: por qué un proyecto de
JavaScript necesita un compilador de C.
