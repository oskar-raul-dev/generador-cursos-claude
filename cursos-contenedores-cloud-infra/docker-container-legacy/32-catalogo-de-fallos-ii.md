# 🩺 Parte II · Fase 32 — Catálogo de fallos II: APT, Node, node-gyp, ABI y filesystem

> **Curso:** Docker Legacy Node
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · Node 10.24.1 / 12.22.12 / 14.21.3 / 16.20.2
> **Requisitos:** **[F30](30-troubleshooting-metodo-y-herramientas.md)** (el método) y **[F31](31-catalogo-de-fallos-i.md)** (las capas exteriores)
> **Estado de la imagen al terminar:** sin cambios
> **Objetivo:** el catálogo de las capas interiores — donde viven los fallos que más tiempo cuestan y que más se parecen entre sí siendo distintos

---

## 1. 🧭 Dónde estamos

[F31](31-catalogo-de-fallos-i.md) cubrió las capas exteriores, donde los mensajes suelen decir lo que pasa. Esta cubre las
**interiores** —capas 6, 7 y 8 de [F30](30-troubleshooting-metodo-y-herramientas.md) §6, más los permisos de la 3—, donde los mensajes casi
nunca mencionan la causa.

> 🩺 **La característica de esta fase:** aquí es donde un `EACCES` es en realidad un problema de
> volumen, un fallo de `npm ci` es en realidad de arquitectura, y un error de `node-gyp` es en
> realidad de Python. **Confirmar antes de corregir importa más que en ninguna otra parte del
> curso.**

Mismo formato que [F31](31-catalogo-de-fallos-i.md): síntoma literal, causa, comprobación, corrección.

---

## 2. 🎯 Objetivos de esta fase

Reconocer y confirmar los fallos de APT y Debian EOL, de Node y npm, de `node-gyp`, de ABI y
binarios nativos, y de filesystem y permisos — distinguiendo los que se parecen y no son lo
mismo.

---

## 3. 🚧 Qué NO entra todavía

Los fallos de **motor, build, registry y red** son la primera mitad del catálogo y están en [F31](31-catalogo-de-fallos-i.md).
El corte no es arbitrario: aquellos aparecen operando la imagen, y estos aparecen
construyéndola — que es donde un proyecto legacy pasa la mayor parte de su tiempo roto.

El **método** para investigar lo que no está catalogado —y las técnicas de forense sobre una
imagen ajena— es [F33](33-forense-y-boss-fight.md). Aquí sigues teniendo la red debajo: cada entrada trae síntoma,
confirmación y corrección, en ese orden y sin saltarse el paso del medio.

Y no entra reparar la dependencia rota río arriba. Si un paquete de 2018 tiene un `binding.gyp`
que ya no compila, este catálogo te dice cómo confirmarlo y qué alternativas tienes; hacerle un
fork y parchearlo es una decisión de producto, no de contenedores.

---

## 4. 🏺 APT y Debian 10 EOL

### 4.1 `E: Unable to locate package X` dentro del contenedor

**Causa.** Los índices están borrados **por diseño** —[F03](03-apt-y-utilidades.md) §4.2—, o el paquete no existe en
Buster.

```bash
apt-get update && apt-cache policy X
```

**No es un fallo:** es la consecuencia declarada de limpiar `/var/lib/apt/lists` en el mismo
`RUN`.

### 4.2 `E: Package 'X' has no installation candidate`

**Causa.** El paquete existe en el índice pero no hay versión instalable: se llamaba distinto en
2019, o está en otro componente del repositorio.

```bash
apt-cache search <palabra clave>
apt-cache policy X
```

> 📝 **En Buster muchos paquetes se llamaban distinto.** `python-is-python2` no existe;
> `libgcc-8-dev` sí y `libgcc-12-dev` no. Es arqueología de nombres, y `apt-cache search` es la
> herramienta.

### 4.3 `404 Not Found` al descargar un `.deb`

**Causa.** Índices cacheados de una capa vieja que apuntan a versiones ya rotadas del archivo.

**Corrige.** `apt-get update` en el **mismo** `RUN` que el `install`. Es exactamente el fallo
que [F03](03-apt-y-utilidades.md) §4.2 previene, y su versión más difícil de ver.

### 4.4 `Package X is not available, but is referred to by another package`

**Causa.** Falta un componente del repositorio —`contrib`, `non-free`— o el paquete se retiró.

```bash
cat /etc/apt/sources.list
```

### 4.5 El paquete instala y la librería no aparece

**Causa.** Instalaste el paquete de runtime y necesitabas el `-dev`, o al revés. [F15](15-laboratorios-dependencias-nativas.md) §5.2.

```bash
dpkg -L libcairo2 | grep -c '\.so'      # runtime: los .so
dpkg -L libcairo2-dev | grep -c '\.h'   # dev: las cabeceras
pkg-config --exists cairo && echo ok
```

---

## 5. 🟢 Node y npm

### 5.1 `node: command not found`

**Causa.** El shim no está, el `PATH` no lo incluye, o estás en una imagen anterior a [F08](08-run-el-contenedor-como-proceso.md).

```bash
command -v node; echo "PATH=$PATH"
ls -la /usr/local/bin/node
readlink -f /usr/local/bin/node
```

### 5.2 `ERROR: Node 11.0.0 no está instalado en esta imagen` (exit 64)

**No es un fallo: es el despachador funcionando.** Pediste una versión que no está, y te lista
las que sí. [F08](08-run-el-contenedor-como-proceso.md) §6.

### 5.3 `npm ci can only install packages when your package.json and package-lock.json are in sync`

**Causa.** Alguien tocó uno sin el otro.

```bash
git log --oneline -3 -- package.json package-lock.json
jq -r '.dependencies + .devDependencies | to_entries[] | "\(.key)@\(.value)"' package.json | head
```

> ⚰️ **Y el anti-patrón que aparece aquí siempre:** `rm package-lock.json && npm install`.
> "Arregla" el error resolviendo un árbol distinto al que el proyecto probó. Averigua **qué**
> está desincronizado antes. [F30](30-troubleshooting-metodo-y-herramientas.md) §8.

### 5.4 `npm ERR! code ELIFECYCLE` en un `postinstall`

**Causa.** Un script de instalación de una dependencia falló. **El error real está más arriba en
el log**, no en esa línea.

```bash
grep -B40 'ELIFECYCLE' install.log | head -60
```

### 5.5 `Unsupported engine` o `EBADENGINE`

**Causa.** Una dependencia declara `engines` incompatible con tu Node.

**No siempre es fatal:** en npm 6 suele ser un warning. Anótalo en el reporte de [F11](11-validar-tu-proyecto.md) en lugar de
forzarlo.

### 5.6 El lockfile se reescribió solo

**Causa.** Ejecutaste `npm install` en lugar de `npm ci`, o usaste npm 8 sobre un lock v1 —[F06](06-instalacion-node.md)
§4—.

```bash
git diff --stat package-lock.json
jq .lockfileVersion package-lock.json
```

**Es el hallazgo, no el contratiempo.** [F11](11-validar-tu-proyecto.md) §5.2.

### 5.7 `SyntaxError: Unexpected token` en un archivo del proyecto

**Causa.** Sintaxis más moderna que el Node que la ejecuta. Es un fallo de **generación**, no de
código.

```bash
node --version
node --check <el archivo>
```

**Corrige.** La generación correcta, según lo que dijera la matriz de [F20](20-validacion-sistematica-y-evidencia.md) §7.

### 5.8 `npm ci` tarda diez veces más de lo normal

**Causa.** Está compilando: no había prebuild para tu combinación. [F14](14-abi-libc-y-prebuilds.md) §7.

```bash
grep -cE 'node-gyp|CXX|make' install.log
```

---

## 6. 🐍 `node-gyp` y compilación nativa

### 6.1 `gyp ERR! find Python`

**Causa.** No encuentra intérprete, o el que encuentra no le sirve.

```bash
which python python2 python3
npm ls node-gyp        # ← la pregunta que importa: ¿QUÉ node-gyp corre?
```

> 🧭 **No crees un symlink `python` como primer reflejo.** Si apunta al intérprete equivocado,
> conviertes un error claro en uno confuso. [F05](05-python-y-node-gyp.md) §10.

### 6.2 `SyntaxError: Missing parentheses in call to 'print'`

**Causa.** Un `node-gyp` de la generación 3 o 4 ejecutándose con Python 3.

**Corrige.** `--python /usr/bin/python2`. [F05](05-python-y-node-gyp.md) §7.

### 6.3 `gyp ERR! stack Error: not found: make`

**Causa.** Falta el toolchain. Ya no es un problema de Python: `node-gyp` hizo su trabajo.

```bash
which make gcc g++
```

### 6.4 `fatal error: stdio.h: No such file or directory`

**Causa.** Hay compilador y faltan las cabeceras de la biblioteca C. [F04](04-toolchain-de-compilacion.md) §8.

```bash
dpkg -l libc6-dev build-essential
```

### 6.5 `Package X was not found in the pkg-config search path`

**Causa.** Falta el paquete `-dev` de esa librería. [F15](15-laboratorios-dependencias-nativas.md) §5.2.

```bash
pkg-config --exists X && echo presente || echo ausente
apt-cache search X | grep -- -dev
```

### 6.6 `node-pre-gyp ERR! install response status 404`

**Causa.** No hay prebuild para tu combinación, o el servidor cambió. [F14](14-abi-libc-y-prebuilds.md) §7.1.

**Corrige.** `--build-from-source`, que es para lo que existe el toolchain.

### 6.7 `Node Sass could not find a binding for your current environment`

**Causa.** **Es un error de ABI disfrazado.** [F23](23-estudios-de-caso-multiplataforma.md) §4.1.

```bash
node -p process.versions.modules
ls node_modules/node-sass/vendor/
```

---

## 7. 🔩 ABI y binarios nativos

### 7.1 `NODE_MODULE_VERSION 64 ... requires NODE_MODULE_VERSION 83`

**Causa.** Reutilizaste `node_modules` entre generaciones. **El más frecuente de esta fase.**

```bash
node -p process.versions.modules
docker inspect --format '{{json .Mounts}}' <ct> | jq '.[] | select(.Destination|test("node_modules"))'
```

**Corrige.** Parche: `npm rebuild`. Raíz: **la convención de nombres del volumen**, [F09](09-montar-tu-proyecto.md) §5.1.

### 7.2 `invalid ELF header` al cargar un `.node`

**Causa.** **Arquitectura**, no ABI. Y esa es la distinción clave: el ABI puede coincidir y la
arquitectura no. [F22](22-apple-silicon-y-hosts.md) §7.

```bash
file node_modules/<paquete>/**/*.node
uname -m
```

> 🩺 **Distinguir 6.1 de 6.2 es la habilidad de esta sección.** El primero dice el número; el
> segundo no dice nada útil. `file` los separa en un segundo.

### 7.3 `version 'GLIBC_2.29' not found`

**Causa.** El binario exige una glibc más nueva que la 2.28 de Buster. [F14](14-abi-libc-y-prebuilds.md) §6.1.

```bash
ldd --version | head -1
readelf -V <el binario> | grep GLIBC | sort -u
```

**Corrige.** Compilar desde source, o un prebuild de la época. **No** subir de Debian sin
medirlo: eso cambia el baseline entero.

### 7.4 `cannot open shared object file: No such file or directory`

**Causa.** Falta una librería en **runtime** —el paquete sin `-dev`—.

```bash
ldd <el binario> | grep 'not found'
```

### 7.5 `Error loading shared library ld-linux-x86-64.so.2`

**Causa.** Un binario de glibc en un sistema musl. Estás en Alpine. [F14](14-abi-libc-y-prebuilds.md) §6.

### 7.6 El módulo carga y falla en tiempo de ejecución

**Causa.** Compiló contra una versión de librería y encontró otra en runtime.

```bash
ldd <el .node>          # ¿qué versiones resolvió realmente?
```

---

## 8. 📁 Filesystem, montajes y permisos

### 8.1 `/workspace` está vacío

**Causa.** Montaste el directorio equivocado, o `-v` creó uno vacío. [F09](09-montar-tu-proyecto.md) §4.1.

```bash
docker inspect --format '{{json .Mounts}}' <ct> | jq
```

### 8.2 `ENOENT: no such file or directory, open '/workspace/package.json'`

**Misma causa que 7.1**, con otro mensaje. Comprueba lo mismo.

### 8.3 `EACCES: permission denied, mkdir '/workspace/node_modules/.staging'`

**Causa.** El volumen pertenece a `root` y el proceso no. [F17](17-usuarios-permisos-y-volumenes.md) §6.2.

```bash
docker exec <ct> id
docker exec <ct> ls -ldn /workspace /workspace/node_modules
```

**Corrige.** Parche: `chown` del volumen. Raíz: la estrategia de usuario de [F17](17-usuarios-permisos-y-volumenes.md) §9.

### 8.4 Archivos con dueño `root` en tu host

**No es un fallo:** es Linux nativo funcionando como funciona. [F17](17-usuarios-permisos-y-volumenes.md) §5.

### 8.5 El watch no ve los cambios

**Causa.** Los eventos de `inotify` no cruzan el bind mount en Docker Desktop.

**Corrige.** `CHOKIDAR_USEPOLLING=true`. [F11](11-validar-tu-proyecto.md) §6.

### 8.6 El contenedor crece sin parar

**Causa.** Algo escribe en la writable layer: logs, cachés, artefactos.

```bash
docker diff <ct> | head -30
docker ps -s --filter name=<ct>
```

[F13](13-overlayfs-y-copy-on-write.md) §10 y §11.

### 8.7 Al recrear el contenedor perdí `node_modules`

**Causa.** Estaba en la writable layer y no en un volumen. [F13](13-overlayfs-y-copy-on-write.md) §11.

### 8.8 `no such file or directory` ejecutando un script que existe

**Causa clásica y desconcertante:** finales de línea **CRLF**. El shebang queda como
`/usr/bin/env bash\r` y el sistema busca un intérprete con un retorno de carro en el nombre.

```bash
file scripts/mi-script.sh          # → "with CRLF line terminators"
head -1 scripts/mi-script.sh | xxd | head -2
```

**Corrige.** `dos2unix`, y en el repositorio un `.gitattributes` con `* text=auto eol=lf`. Es un
fallo de Windows que aparece en Linux, y por eso cuesta tanto de ver.

### 8.9 `permission denied` ejecutando un script montado

**Causa.** Falta el bit de ejecución, o el filesystem lo perdió al cruzar la frontera.

```bash
ls -l scripts/mi-script.sh
```

**Corrige.** `chmod +x`, y en el `Dockerfile` un `chmod 0755` tras el `COPY` — que es lo que [F06](06-instalacion-node.md)
§8 ya hace.

---

## 9. 🗺️ Los que se parecen y no son lo mismo

La tabla más útil de la fase:

| Se confunden | Los distingue |
|---|---|
| `NODE_MODULE_VERSION` (6.1) y `invalid ELF header` (6.2) | el primero dice números; `file` resuelve el segundo |
| `GLIBC not found` (6.3) y `cannot open shared object` (6.4) | versión de libc contra librería ausente: `readelf` frente a `ldd` |
| paquete de runtime y paquete `-dev` (3.5, 5.5) | `pkg-config --exists` |
| `EACCES` de volumen (7.3) y de bind mount | `ls -ldn` de las **dos** rutas |
| `/workspace` vacío (7.1) y `ENOENT` (7.2) | son lo mismo: `docker inspect .Mounts` |
| falta Python (5.1) y Python incompatible (5.2) | `npm ls node-gyp` antes que nada |
| `npm ci` lento (4.8) y `npm ci` colgado | `grep node-gyp` en el log |
| script que no existe (7.8) y sin permiso (7.9) | `file` contra `ls -l` |

---

## 10. ⚠️ Errores comunes al usar este catálogo

**Buscar el síntoma y aplicar la corrección sin pasar por la confirmación.** Es el error que más
tiempo cuesta, porque los mensajes de esta mitad del catálogo se parecen muchísimo entre sí: un
`node-gyp` que falla por falta de Python y uno que falla por falta de `make` dan un muro de texto
casi idéntico. La línea de confirmación existe para que no arregles el problema equivocado y
después tengas dos.

**Instalar de más "por si acaso".** Cuando un fallo se resuelve añadiendo un paquete, la tentación
es añadir también los tres vecinos. La imagen crece, la caché se invalida más a menudo y, sobre
todo, dejas de saber cuál era la dependencia real. Añade uno, reconstruye, comprueba.

**Confundir "compila" con "funciona".** Media docena de entradas de aquí terminan en un `npm ci`
que sale con código 0 y una aplicación que peta en el primer `require`. Un addon nativo puede
compilarse contra una libc y cargarse en otra; el error solo aparece al ejecutar. Por eso el
criterio de éxito de [F20](20-validacion-sistematica-y-evidencia.md) es siempre correr algo, nunca construir algo.

**Tratar un fallo de ABI como un fallo de instalación.** Reinstalar `node_modules` sobre un
`NODE_MODULE_VERSION` equivocado no arregla nada y te consume veinte minutos por intento. Si el
mensaje menciona una versión de módulo, ve directo a §7 y no pases por §6.

**Editar dentro del contenedor y perderlo.** Cuando estás depurando un fallo de compilación es
natural tocar un archivo con `vi` para probar algo. Funciona, confirmas la causa, sales del
contenedor y se lo lleva la capa escribible. Confirma dentro, corrige en el Dockerfile.

---

## 11. 📋 Checklist de validación

```text
[ ] Provocaste al menos diez entradas de esta fase
[ ] Para cada una ejecutaste la confirmación antes de corregir
[ ] Distingues los ocho pares de §9
[ ] Sabes cuáles de las entradas NO son fallos (3.1, 4.2, 4.6, 7.4)
[ ] Ante un EACCES compruebas id y ls -ldn antes de tocar permisos
[ ] Ante un gyp ERR! compruebas npm ls node-gyp antes de tocar Python
[ ] Reconoces un CRLF en un segundo con file
```

---

## 12. 🧪 Ejercicios de la Fase 32 (30)

## 🟢 Fácil — provocar y confirmar (1–7)

### 🟢 Ejercicio 1 — Los cinco de APT

Provoca §4.1, §4.2 y §4.5 y confirma cada uno.

### 🟢 Ejercicio 2 — Los tres de Node

Provoca §5.1, §5.3 y §5.7.

**Pregunta:** ¿cuál de los tres tiene el mensaje más engañoso?

### 🟢 Ejercicio 3 — El ABI, otra vez

Provoca §7.1 y guarda el mensaje entero.

### 🟢 Ejercicio 4 — El ELF inválido

Provoca §7.2 con un binario de otra arquitectura.

**Objetivo:** ver que **no** dice nada útil, y que `file` sí.

### 🟢 Ejercicio 5 — CRLF

Convierte un script a CRLF y ejecútalo.

**Objetivo:** ver `no such file or directory` sobre un archivo que existe, y reconocerlo para
siempre.

### 🟢 Ejercicio 6 — Los que no son fallos

Provoca §4.1, §5.2, §5.6 y §8.4.

**Objetivo:** que dejen de parecerte errores.

### 🟢 Ejercicio 7 — El script existe y no se ejecuta

`./mi-script.sh` responde `no such file or directory` y el archivo está ahí, lo ves con `ls`.
El catálogo tiene dos entradas para esto y en realidad hay **tres** causas. Provócalas:

```bash
# 1. sin bit de ejecución
echo '#!/bin/bash\necho ok' > a.sh && ./a.sh
# 2. con CRLF
printf '#!/bin/bash\r\necho ok\r\n' > b.sh && chmod +x b.sh && ./b.sh
# 3. shebang que apunta a un intérprete que no existe
printf '#!/usr/bin/zsh\necho ok\n' > c.sh && chmod +x c.sh && ./c.sh
```

**Objetivo:** anotar el mensaje **exacto** de cada uno y comprobar que dos de los tres mienten
sobre cuál es el archivo que no se encuentra.

**Pregunta:** en el caso 2, ¿de qué archivo dice el kernel que no existe? Míralo con
`file b.sh` y `cat -A b.sh`. Es la lección del catálogo entero en un solo ejemplo: **el sujeto
del mensaje de error no siempre es el archivo que ejecutaste**.

## 🟡 Intermedio — npm, node-gyp y el lockfile (8–15)

### 🟡 Ejercicio 8 — `pkg-config` decide

Instala `libcairo2` sin `libcairo2-dev` y comprueba §4.5.

### 🟡 Ejercicio 9 — `npm ls node-gyp`

En tres proyectos distintos, averigua qué versión de `node-gyp` corre de verdad.

**Pregunta:** ¿coincide con la que esperabas por la versión de Node?

### 🟡 Ejercicio 10 — Python 2 y Python 3

Provoca §6.2 y arréglalo con `--python`.

### 🟡 Ejercicio 11 — El `postinstall` que falla

Provoca §5.4 y encuentra el error real en el log.

**Pregunta:** ¿a cuántas líneas del `ELIFECYCLE` estaba?

### 🟡 Ejercicio 12 — glibc

Descarga un binario moderno e intenta ejecutarlo en Buster.

**Objetivo:** obtener §7.3 y confirmarlo con `readelf`.

### 🟡 Ejercicio 13 — El contenedor que engorda

Provoca §8.6 y localiza al culpable con `docker diff`.

### 🟡 Ejercicio 14 — El lock desincronizado

`npm ci` se niega con *"can only install packages when your package.json and package-lock.json
are in sync"*, y es de los pocos errores de npm que dice exactamente la verdad. Provócalo y
mira qué se puede hacer:

```bash
jq '.dependencies["lodash"] = "^4.17.0"' package.json > tmp && mv tmp package.json
npm ci
```

**Objetivo:** leer el error entero —que además te dice **qué** paquete está desincronizado— y
después probar las tres salidas: `npm install` para regenerar el lock, revertir el
`package.json`, y `npm ci` con el lock regenerado. Comprueba en cada caso qué le pasa al
`lockfileVersion`.

**Pregunta:** de las tres, una es peligrosa en un proyecto legacy y el curso lleva veinte fases
avisándolo. ¿Cuál y por qué? Y la que decide el criterio: si el `package.json` lo cambió un
compañero en un commit y el lock no, ¿quién tiene razón, el `package.json` o el lock? La
respuesta no es "el lock" a secas: depende de si el cambio era deliberado, y eso se averigua
con `git log`, no con npm.

### 🟡 Ejercicio 15 — El watch que no ve tus cambios

Editas un archivo en tu host, el dev server dentro del contenedor no recarga, y no hay ningún
error en ninguna parte. Es la entrada del catálogo con peor relación entre lo trivial de la
causa y lo mucho que se sufre.

**Objetivo:** provocarlo con un fixture, confirmar con **evidencia** que el archivo sí cambió
dentro del contenedor —`stat` sobre el archivo desde dentro, comparando `mtime` antes y
después— y solo entonces concluir que el problema está en la **notificación**, no en el
montaje.

Después arréglalo con polling —`CHOKIDAR_USEPOLLING=true` es la variable de la época— y mide el
coste con `docker stats` mientras el watch está activo.

**Pregunta:** ¿por qué `inotify` no cruza la frontera en un bind mount sobre macOS o Windows y
sí funciona en Linux nativo? Y la de criterio: el polling arregla el síntoma y consume CPU
continuamente. Con tu medición delante, ¿a partir de cuántos archivos vigilados dejarías de
recomendarlo, y qué harías en su lugar?

## 🟠 Difícil — cuando el mensaje apunta mal (16–24)

### 🟠 Ejercicio 16 — Los ocho pares

Provoca los dos miembros de al menos cuatro pares de §9 y confirma que los distingues.

**Objetivo:** el ejercicio central de la fase.

### 🟠 Ejercicio 17 — Permisos: las dos rutas

Provoca §8.3 y comprueba `ls -ldn` de `/workspace` **y** de `/workspace/node_modules`.

**Objetivo:** ver que solo una de las dos es el problema.

### 🟠 Ejercicio 18 — El disfraz

Provoca §6.7 y demuestra que es un error de ABI, no de `node-sass`.

### 🟠 Ejercicio 19 — Tres capas de distancia

Construye un fallo cuyo síntoma esté en la capa 8 y la causa en la 3.

**Objetivo:** recorrerlo con el método de [F30](30-troubleshooting-metodo-y-herramientas.md), documentando qué descartaste.

### 🟠 Ejercicio 20 — El `.gitattributes` que faltaba

Simula un equipo mixto Windows/Linux y provoca §8.8 a través de Git.

**Objetivo:** llegar a la solución estructural —`.gitattributes`— y no solo a `dos2unix`.

### 🟠 Ejercicio 21 — El prebuild que devolvió un 404

`node-pre-gyp ERR! install response status 404` es la forma que tiene un proyecto de 2018 de
decirte que el bucket donde vivía su binario ya no está. Provócalo apuntando a una URL que no
existe:

```bash
npm install <paquete> --<paquete>_binary_host_mirror=https://example.invalid/nope/
```

**Objetivo:** leer el log completo y localizar las **dos** líneas que importan: la URL que
intentó y —esto es lo que casi nadie ve— si después de fallar **intentó compilar** o se rindió.
El comportamiento cambia según el paquete y decide por completo tu estrategia.

**Pregunta:** si intentó compilar y falló, tienes **dos** errores encadenados en el mismo log y
el segundo suele tapar al primero. ¿Cuál de los dos es la causa raíz? Y la parte que enlaza con
[F15](15-laboratorios-dependencias-nativas.md): con el toolchain completo en la imagen, un 404
de prebuild debería ser un contratiempo y no un muro. Comprueba si es tu caso, y si no lo es,
averigua qué le falta a tu imagen.

### 🟠 Ejercicio 22 — El módulo que carga y revienta después

Peor que un módulo que no carga es uno que carga. `require()` funciona, los tests pasan, y a
los diez minutos de uso el proceso muere con un `Segmentation fault` sin traza de JavaScript.

**Objetivo:** provocar el escenario —un `.node` que enlaza contra una versión de librería del
sistema distinta de la que se usó al compilarlo suele bastar— y aprender a reconocerlo. La
clave es que un `SIGSEGV` en un proceso Node **casi nunca es de tu código**: es del binario
nativo.

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase15 \
  bash -c 'node app.js; echo "salida: $?"'
```

**Pregunta:** ¿qué código de salida devuelve un proceso que muere por `SIGSEGV`, y cómo lo
distingues de un `process.exit(139)` cualquiera? Después responde a lo que hace útil el
ejercicio: nombra las **tres** comprobaciones que harías antes de sospechar de tu propio código
—`ldd` sobre los `.node`, el `NODE_MODULE_VERSION`, y las versiones de las librerías del
sistema— y di en qué orden, y por qué en ese orden.

### 🟠 Ejercicio 23 — `npm ci` diez veces más lento

Sin errores, sin fallos: simplemente tarda diez minutos donde antes tardaba uno. El catálogo lo
lista y merece medirse, porque tiene cuatro causas y solo una es "la red va mal".

**Objetivo:** provocar y medir las cuatro por separado: el `node_modules` en el **overlay** en
vez de en un volumen —lo de [F13](13-overlayfs-y-copy-on-write.md)—; el `node_modules` en un
**bind mount** cruzando la frontera host-VM; la **emulación** de arquitectura de
[F21](21-arquitecturas-y-emulacion.md) §7.4; y la **caché de npm** vacía en cada ejecución.

Cronometra las cuatro contra la configuración correcta del laboratorio y monta la tabla.

**Pregunta:** ¿cuál de las cuatro te costó más segundos? Y la pregunta que separa medir de
adivinar: de las cuatro, ¿cuáles se pueden diagnosticar **sin cronómetro**, mirando solo cómo
se arrancó el contenedor? Escribe esas comprobaciones — son las que van en el protocolo de 60
segundos, porque cuestan un `docker inspect` y no diez minutos de espera.

### 🟠 Ejercicio 24 — `EBADENGINE`: aviso o muro

`Unsupported engine` sale por pantalla en rojo y mucha gente lo trata como un error fatal
cuando casi nunca lo es. Averigua cuándo sí.

**Objetivo:** provocar el aviso instalando con una generación de Node fuera del rango
`engines` de un paquete, y comprobar que **la instalación continúa**. Después fuerza el
comportamiento contrario:

```bash
npm ci --engine-strict
# o en .npmrc
echo 'engine-strict=true' > .npmrc && npm ci
```

**Pregunta:** con `engine-strict` apagado —el default— npm avisa y sigue. ¿Qué gana y qué
pierde cada una de las dos configuraciones en un proyecto de 2018? Y la observación que enlaza
con [F20](20-validacion-sistematica-y-evidencia.md) §5.1: el campo `engines` es el **nivel 1**
de evidencia, el más débil. Entonces, ¿qué sentido tiene fallar el build por él? Defiende una
postura y di en qué tipo de proyecto cambiarías de opinión.

## 🔴 Muy difícil — del catálogo al criterio (25–30)

### 🔴 Ejercicio 25 — Diagnostica sin corregir

Toma cinco fallos y llega a la causa raíz de todos **sin arreglar ninguno**.

**Objetivo:** separar diagnóstico de reparación, que es lo que permite priorizar.

### 🔴 Ejercicio 26 — Las cuatro que no son fallos

Escribe, para las cuatro entradas que esta fase marca como comportamiento esperado —§4.1, §5.2,
§5.6 y §8.4—, la explicación que le darías a alguien que acaba de encontrárselas y cree que
rompió algo.

**Objetivo:** que cada una diga qué decisión del laboratorio la produce, en qué fase se tomó, y
qué habría que cambiar para que dejara de ocurrir. Tres de las cuatro son consecuencias
deliberadas de decisiones que tú entiendes; poder explicarlas es la prueba de que las entiendes.

### 🔴 Ejercicio 27 — El árbol de decisión de `npm ci`

Escribe el árbol que, partiendo de un `npm ci` fallido, llegue a la causa en el menor número de
comandos.

**Objetivo:** que cubra las cinco familias de [F11](11-validar-tu-proyecto.md) §6 y que ninguna rama tenga más de tres pasos.
Compáralo con el que escribiste en [F05](05-python-y-node-gyp.md) §12 y anota qué te faltaba entonces.

### 🔴 Ejercicio 28 — Un `node_modules` contaminado y sus cuatro caras

Reutilizar el volumen de `node_modules` entre generaciones de Node produce **cuatro** entradas
distintas de este catálogo, y quien no lo sabe las diagnostica como cuatro problemas separados.

**Objetivo:** provocar deliberadamente la contaminación —instalar con una generación y ejecutar
con otra— sobre un proyecto que tenga a la vez JavaScript puro, un addon compilado, un addon
con prebuild y un paquete que descarga un binario. Los cuatro casos de
[F14](14-abi-libc-y-prebuilds.md) §4 en un solo `node_modules`.

Anota **qué mensaje da cada uno**. Vas a obtener cuatro textos completamente distintos: uno
habla de `NODE_MODULE_VERSION`, otro de un binding que no encuentra, otro no falla en absoluto,
y el cuarto revienta en tiempo de ejecución.

**Pregunta de cierre:** los cuatro tienen la misma causa y la misma corrección —volumen limpio y
reinstalar—. Escribe la **comprobación única** que los identifica a todos de una vez, en un
comando, antes de leer ningún mensaje de error. Si la tienes, acabas de convertir cuatro
entradas del catálogo en una sola línea de tu protocolo de triaje, y eso es exactamente lo que
esta fase pretende que sepas hacer.

### 🔴 Ejercicio 29 — El proyecto que solo falla la segunda vez

El fallo que funciona la primera vez y rompe la segunda es el más desconcertante del
catálogo, porque contradice la intuición de que reintentar no puede empeorar las cosas.

**Objetivo:** construir **tres** escenarios de este tipo con material del curso, y para cada uno
explicar qué estado quedó de la primera ejecución que estropea la segunda. Tienes de dónde
elegir: un `node_modules` a medio instalar tras un fallo, una caché de npm con un artefacto
corrupto, un lockfile reescrito por un `npm install` accidental, un volumen con permisos de
otro UID, o un contenedor viejo con el mismo nombre.

Para cada uno: el comando que lo deja en ese estado, el síntoma de la segunda pasada, y la
comprobación que lo revela.

**Pregunta de cierre:** los cinco candidatos tienen algo en común: **el estado sobrevive fuera
del contenedor**. Haz la lista de todos los sitios donde tu laboratorio guarda estado que
sobrevive a un `docker rm` —hay al menos cuatro— y escribe, para cada uno, cómo se limpia y
cómo se comprueba que está limpio. Ese checklist es la respuesta larga a la pregunta *"¿por qué
a veces borrar todo y empezar de cero sí funciona?"*, y saberla te evita tener que hacerlo.

### 🔴 Ejercicio 30 — Traduce el catálogo a tu stack

Este catálogo está escrito para Vue 2, Angular 8, React 16 y Svelte 3 sobre Node 10–16. Tu
proyecto real se parece, pero no es eso.

**Objetivo:** producir la versión del catálogo para **tu** stack concreto, en tres pasos.
**Primero**, marca cuáles de las entradas de esta fase te aplican tal cual, cuáles te aplican
con otro mensaje —porque tu herramienta lo redacta distinto— y cuáles no te aplican en
absoluto. **Segundo**, añade las tuyas: los fallos que has tenido y que aquí no están, con el
formato completo del catálogo. **Tercero**, y es lo que lo convierte en útil, ordena el
resultado por **frecuencia real en tu proyecto**, no por tema.

**Pregunta de cierre:** cuenta cuántas entradas del curso sobrevivieron sin cambios. Si son
muchas, la razón es que la mayoría de estos fallos no son de Vue ni de Angular: son de
**Node, npm, node-gyp, el compilador y el sistema de archivos**, que es la capa que este curso
eligió enseñar en lugar de los frameworks. Si son pocas, tienes un stack interesante y
deberías escribir sobre él.

## 🔥 Opcionales

### 🔥 Ejercicio 31 — Amplía la tabla de pares

Añade a §9 tres pares que te hayan confundido a ti.

### 🔥 Ejercicio 32 — El script de triaje

Escribe un script que, dado un contenedor, ejecute las comprobaciones de §7 y §8 y diga qué
encontró.

**Objetivo:** que respete la política de secretos de [F30](30-troubleshooting-metodo-y-herramientas.md) §10.1.

## 💀 Boss fight

### 💀 Ejercicio 33 — Boss fight: el proyecto de los cinco fallos

Te dan un proyecto legacy con cinco problemas simultáneos, uno de cada sección de esta fase.

**Objetivo:** diagnosticarlos y corregirlos **en el orden correcto** — porque algunos enmascaran
a otros y arreglarlos en mal orden hace que dos parezcan uno. Documenta el orden que elegiste y
por qué, qué confirmación usaste en cada uno, y cuáles eran causa contribuyente y cuál era la
raíz común. Si al final tienes cinco correcciones independientes, probablemente te falta ver que
dos de ellas tenían el mismo origen.

---

## 13. 📚 Referencias

- APT en Buster: https://manpages.debian.org/buster/apt/apt-get.8.en.html
- npm 6, errores comunes: https://docs.npmjs.com/common-errors
- `node-gyp`: https://github.com/nodejs/node-gyp
- Versiones de ABI de Node: https://nodejs.org/en/download/releases/
- `ldd(1)` y `readelf(1)`: https://manpages.debian.org/buster/manpages/ld.so.8.en.html
- Errores de Node: https://nodejs.org/docs/latest-v10.x/api/errors.html

> ⚠️ **Los mensajes exactos varían entre versiones de npm y de las herramientas.** La causa y la
> comprobación siguen valiendo aunque el texto difiera.

---

## 14. 🏁 Resultado de la fase

```text
APT             índices borrados por diseño · nombres de 2019 · runtime vs -dev

NODE Y NPM      shims y PATH · lock desincronizado · ELIFECYCLE (el error está arriba)
                lockfile reescrito = hallazgo · sintaxis moderna = generación equivocada

NODE-GYP        ¿qué node-gyp corre? antes que nada
                Python ausente ≠ Python incompatible
                si falla make o gcc, ya no es Python

ABI             NODE_MODULE_VERSION → generación · invalid ELF → arquitectura
                GLIBC not found → versión de libc · cannot open → librería ausente

FILESYSTEM      /workspace vacío y ENOENT son lo mismo
                EACCES: mira las DOS rutas
                watch sin eventos → polling · contenedor que engorda → docker diff
                CRLF: "no such file" sobre un archivo que existe

OCHO PARES      que se parecen y no son lo mismo — §9
```

> **La señal de que quedó bien:** *"ante un `EACCES` no toco permisos, ante un `gyp ERR!` no
> toco Python, y ante un `no such file` sobre un archivo que veo, ejecuto `file`."*

En **[F33](33-forense-y-boss-fight.md)** dejamos el catálogo y subimos de nivel: forense avanzado, las matrices de síntomas, y
el Boss Fight que encadena todo el curso.
