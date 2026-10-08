# 🪟 Parte II · Fase 13 — OverlayFS y copy-on-write: cómo se montan juntas las capas

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`)
> **Arquitectura objetivo del laboratorio:** `linux/amd64`
> **Requisitos:** **[F12](12-capas-cache-y-contexto.md)** (capas y caché) y **[F09](09-montar-tu-proyecto.md)** (bind mounts y volumes)
> **Fecha de verificación ejecutada:** 3 de septiembre de 2026 y reverificada el 6 de septiembre de 2026 — Docker 29.6.2 con image store de containerd; la tabla A/B/C de §12 se reprodujo entera
> **Estado de la imagen al terminar:** sin cambios. Lo que cambia es que ya sabes por qué pesa lo que pesa
> **Objetivo:** entender qué mecanismo del kernel convierte una pila de capas de solo lectura en un filesystem que se puede escribir, y usar ese modelo para explicar el tamaño de tus imágenes, la salida de `docker diff` y por qué el `node_modules` del laboratorio vive donde vive

---

## 1. 🧭 Dónde estamos

**[F12](12-capas-cache-y-contexto.md)** te enseñó a mirar dentro del fósil: una imagen es un manifest, una config y una pila de capas, y cada capa es un **changeset** —un diff de filesystem empaquetado en un tar—. Con eso ya sabes leer `docker image history`, entender por qué un `RUN` mal ubicado invalida la caché y explicar que la imagen es una estructura compuesta y no un disco.

Pero quedó una pregunta abierta que el curso nunca respondió, y es justo la que separa entender una imagen de entender un contenedor:

> si las capas son diffs guardados por separado y además son de **solo lectura**, ¿cómo termina el proceso dentro del contenedor viendo un único `/` normal, en el que además puede escribir?

La respuesta no está en Docker. Está en el kernel de Linux, se llama **OverlayFS**, y es la pieza que hace que todo lo demás —el tamaño de las imágenes, la velocidad del `docker run`, `docker diff`, la decisión de montar `node_modules` en un named volume— deje de ser folklore y pase a ser consecuencia.

---

## 2. 🎯 Objetivos de esta fase

Al terminar vas a poder:

- explicar qué es un **union mount** y montar uno a mano, sin Docker de por medio;
- nombrar y reconocer `lowerdir`, `upperdir`, `workdir` y `merged`, y decir cuál de ellos es tu imagen y cuál es tu contenedor;
- describir el **copy-up** y predecir cuándo va a costar caro;
- identificar un **whiteout** en el disco y explicar por qué borrar no borra;
- leer `docker diff` y `docker ps -s` sabiendo exactamente qué te están midiendo;
- justificar con números por qué `RUN rm` en una capa posterior **no** reduce el tamaño de la imagen, y por qué escribir en un bind mount o en un volume no engorda el contenedor.

---

## 3. 🚧 Qué NO entra todavía

- Los otros storage drivers —`btrfs`, `zfs`, `devicemapper`, `vfs`— más allá de nombrarlos. `overlay2` es el driver por defecto en todo lo que vas a tocar.
- El almacén local de Podman y sus diferencias con el de Docker → **[F24](24-docker-y-podman-arquitectura.md)**.
- `virtiofs`, `gRPC-FUSE` y el costo de cruzar la frontera macOS ↔ VM. Se menciona aquí y se mide en **[F26](26-portabilidad-entre-motores.md)**.
- Rootless, user namespaces y `fuse-overlayfs` → **[F25](25-rootless-y-user-namespaces.md)**.

---

## 4. 🧠 El problema antes de la herramienta

Imagina que tienes tres directorios en disco, cada uno con parte de un sistema de archivos, y quieres que un proceso los vea como uno solo. No copiarlos: **verlos**. Y quieres que ese proceso pueda escribir sin tocar ni un byte de los tres originales, porque otros veinte procesos los están usando al mismo tiempo.

Eso es exactamente lo que necesita un motor de contenedores. Las capas de tu imagen están en disco una sola vez y las comparten todos los contenedores que arranques desde ella. Si `docker run` tuviera que copiar 180 MB de Debian por contenedor, arrancar uno tardaría lo que tarda copiar 180 MB, y diez contenedores ocuparían 1,8 GB. No es lo que ocurre: arrancar es instantáneo y diez contenedores ocupan lo que ocupa uno más lo que cada uno escriba.

La herramienta que lo permite es un **union filesystem**: un filesystem que no guarda datos propios, sino que presenta la unión de varios directorios existentes. En Linux, la implementación que usan Docker y containerd por defecto es **OverlayFS**, en el kernel desde la 3.18.

> 📝 **Nota de época.** Hubo vida antes: AUFS fue el primer driver de Docker y nunca entró al kernel mainline, y `devicemapper` fue el parche para RHEL cuando AUFS no estaba disponible. Si abres un tutorial de 2015 y ves `aufs` por todas partes, no está mal escrito: está viejo. Hoy `overlay2` es el default en la práctica totalidad de instalaciones, y los demás sobreviven en casos muy concretos.

---

## 5. 🧩 Las cuatro palabras que hay que aprenderse

OverlayFS se monta con cuatro directorios, y toda esta fase cabe en entender qué hace cada uno:

- **`lowerdir`** — una o más capas de **solo lectura**, separadas por `:`. Es tu imagen. La primera de la lista es la de arriba: si el mismo archivo existe en varias, gana la de más a la izquierda.
- **`upperdir`** — la única capa **escribible**. Es tu contenedor. Nace vacía.
- **`workdir`** — un directorio de trabajo interno que el kernel necesita para hacer atómicas ciertas operaciones. Tiene que estar en el mismo filesystem que `upperdir`, y no es asunto tuyo lo que hay dentro.
- **`merged`** — el punto de montaje, la vista unificada. Es lo que el proceso ve como `/`.

```mermaid
flowchart BT
    U["upperdir/<br/>escribible<br/>(el contenedor)"] --> M["merged/<br/>lo que ve el proceso: un / normal"]
    L["lowerdir/<br/>solo lectura, apilado<br/>lower2 : lower1 : base<br/>(las capas de la imagen)"] --> M
```

---

## 6. 🧪 Montarlo a mano, sin Docker

La mejor forma de creerlo es hacerlo. Necesitamos privilegios para montar y un directorio que **no** esté ya sobre overlay —por eso usamos un volume: no se puede poner el `upperdir` de un overlay encima de otro overlay—:

Abrimos una sesión interactiva y nos quedamos dentro, porque el resto de la Parte I continúa en este mismo contenedor:

```bash
docker volume create ovlab

docker run \
  --rm -it \
  --privileged \
  --platform linux/amd64 \
  -v ovlab:/lab \
  debian/eol:buster \
  bash
```

Ya dentro, montamos el overlay a mano:

```bash
# dentro del contenedor
mkdir -p /lab/{lower1,lower2,upper,work,merged}

# dos capas de solo lectura, con un archivo repetido a propósito
echo "de la capa 1"             > /lab/lower1/base.txt
echo "solo en la capa 1"        > /lab/lower1/borrame.txt
echo "de la capa 2 (gana esta)" > /lab/lower2/base.txt

# el union mount: lower2 va primero, así que tiene prioridad
mount -t overlay overlay \
  -o lowerdir=/lab/lower2:/lab/lower1,upperdir=/lab/upper,workdir=/lab/work \
  /lab/merged

echo "=== lo que se ve en merged ==="; ls /lab/merged
echo "=== quien gana base.txt ==="   ; cat /lab/merged/base.txt
```

Salida real:

```text
=== lo que se ve en merged ===
base.txt
borrame.txt
=== quien gana base.txt ===
de la capa 2 (gana esta)
```

Dos observaciones que valen la fase entera. La primera: `borrame.txt` solo existía en `lower1` y aparece igual, porque la unión suma archivos. La segunda: `base.txt` existía en las dos capas y **ganó la de más a la izquierda**, sin error, sin aviso y sin mezclar nada. Esa es la regla de precedencia que explica por qué un `COPY` tardío pisa un archivo que venía de la imagen base.

> 🧠 **Modelo mental.** Una capa no "reemplaza" a la anterior: la **tapa**. El archivo viejo sigue ahí abajo, ocupando espacio, intacto y inalcanzable.

---

## 7. ✍️ Copy-up: qué pasa cuando escribes

Seguimos en la misma sesión. Ahora escribimos, modificamos y borramos desde `merged`, y después miramos qué quedó en `upper`:

```bash
# dentro del contenedor, con el overlay ya montado
echo "escrito en runtime"     > /lab/merged/nuevo.txt
echo "modificado desde merged" >> /lab/merged/base.txt
rm /lab/merged/borrame.txt

ls -la /lab/upper
```

```text
-rw-r--r-- 1 root root   49 Sep  4 03:59 base.txt
c--------- 2 root root 0, 0 Sep  4 03:59 borrame.txt
-rw-r--r-- 1 root root   19 Sep  4 03:59 nuevo.txt
```

Tres archivos, tres historias distintas:

- **`nuevo.txt`** no existía en ninguna capa inferior: se crea directamente en `upperdir`. Barato.
- **`base.txt`** venía de `lower2` y lo modificamos. OverlayFS no puede escribir en una capa de solo lectura, así que hace un **copy-up**: copia el archivo **completo** a `upperdir` y aplica el cambio ahí. Compruébalo —el archivo de arriba tiene las dos líneas, y el de abajo sigue con la suya—:

  ```bash
  cat /lab/upper/base.txt   # de la capa 2 (gana esta) + modificado desde merged
  cat /lab/lower1/base.txt  # de la capa 1     ← intacto
  ```

- **`borrame.txt`** merece su propia sección, porque esa `c` del principio no es un error de formato.

> ⚠️ **La trampa de rendimiento del copy-up.** El copy-up copia el archivo entero **la primera vez que lo tocas**, aunque cambies un solo byte. Añadir una línea a un log de 2 GB heredado de la imagen copia 2 GB antes de escribir la línea. En un laboratorio con `node_modules` de 300 MB dentro de la imagen, el primer `npm rebuild` paga esa factura completa. Es una de las razones —no la única— por la que en este curso `node_modules` no vive en la imagen.

---

## 8. 👻 Whiteouts: borrar sin borrar

Volvamos a esa línea:

```text
c--------- 2 root root 0, 0 Sep  4 03:59 borrame.txt
```

La `c` significa **character device**, y sus números mayor y menor son `0, 0`. No es un archivo vacío ni un enlace roto: es un **whiteout**, la marca que OverlayFS deja en `upperdir` para decirle al kernel *"si alguien pregunta por este nombre, responde que no existe, aunque lo encuentres abajo"*.

```bash
stat -c '%n | %F' /lab/upper/borrame.txt
```

```text
/lab/upper/borrame.txt | character special file
```

Y mientras tanto, la capa inferior sigue exactamente igual:

```bash
ls /lab/lower1
```

```text
base.txt
borrame.txt
```

De ahí la frase que hay que llevarse de esta fase: **borrar un archivo en una capa superior no libera un solo byte de las inferiores**. Añade una marca. El `docker diff` que verás en la Parte II es literalmente la lectura de este directorio, y el crecimiento inexplicable de tus imágenes es la consecuencia directa de este mecanismo.

> 🧠 **El patrón a memorizar.** En un union filesystem, `rm` es una operación de **catálogo**, no de almacenamiento. Cambias lo que se ve, no lo que hay.

Cuando termines de jugar, sal de la sesión y limpia:

```bash
# dentro del contenedor
umount /lab/merged
exit

# en el host
docker volume rm ovlab
```

---

## 9. 🔎 El `/` de tu contenedor es un overlay, y te lo puede demostrar

Todo lo del laboratorio manual es lo que hace `docker run` por ti. Pregúntaselo al contenedor:

```bash
docker run \
  --rm \
  --platform linux/amd64 \
  debian/eol:buster \
  cat /proc/mounts | head -1
```

```text
overlay / overlay rw,relatime,
  lowerdir=/var/lib/desktop-containerd/.../snapshots/1816/fs:/var/lib/desktop-containerd/.../snapshots/1720/fs,
  upperdir=/var/lib/desktop-containerd/.../snapshots/1817/fs,
  workdir=/var/lib/desktop-containerd/.../snapshots/1817/work 0 0
```

Ahí están las cuatro palabras, en tu máquina, sin metáforas. Dos `lowerdir` porque esa imagen tiene dos capas, un `upperdir` recién creado para este contenedor, y `/` montado como `overlay`.

> 💡 **Truco.** Esa primera línea de `/proc/mounts` es un diagnóstico de un vistazo: si dice `overlay`, estás en un contenedor con storage driver `overlay2`. Si dijera `vfs`, sabrías que el motor está copiando capas enteras —lento y voraz— y tendrías el problema de rendimiento explicado antes de empezar a buscarlo.

📝 En macOS y Windows esos paths viven **dentro de la VM Linux** del motor, no en tu disco: `ls /var/lib/docker/overlay2` en tu Mac no va a encontrar nada. En Linux nativo sí, y ahí puedes leer el `upperdir` de un contenedor vivo con `docker inspect --format '{{.GraphDriver.Data.UpperDir}}'`.

---

## 10. 🩺 `docker diff` es leer el `upperdir`

Con lo anterior, `docker diff` deja de ser un comando curioso y pasa a ser transparente. Arranca un contenedor, tócale tres cosas y mira:

```bash
docker run -d --name ovdemo --platform linux/amd64 debian/eol:buster sleep 120

docker exec ovdemo bash -c 'rm /etc/os-release; echo x > /etc/motd; mkdir /nuevo'

docker diff ovdemo
```

```text
C /etc
C /etc/motd
D /etc/os-release
A /nuevo
```

Tres letras y ninguna magia:

- **`A`** (added) — existe en `upperdir` y no venía de abajo. Es `/nuevo`.
- **`C`** (changed) — hubo copy-up. `/etc/motd` se copió entero y se modificó; `/etc` aparece porque el directorio que lo contiene también tuvo que materializarse arriba.
- **`D`** (deleted) — hay un whiteout. El `/etc/os-release` de la imagen sigue intacto en su capa; lo que ves es la marca.

> 🩺 **Uso real en diagnóstico.** Cuando un build "funciona pero la imagen pesa 400 MB de más", o cuando un contenedor de **[F09](09-montar-tu-proyecto.md)** se comporta distinto al de ayer, `docker diff` te dice **exactamente qué tocó el proceso**. Es la forma más rápida de descubrir que algo está escribiendo dentro del contenedor lo que debería estar escribiendo en un volume.

---

## 11. 📏 `docker ps -s`: qué es `size` y qué es `virtual`

La otra lectura directa del `upperdir` es el tamaño. Montemos el escenario del laboratorio real: el proyecto por bind mount, `node_modules` en un named volume, y escrituras en tres sitios distintos.

```bash
docker run -d --name ovdemo \
  --platform linux/amd64 \
  -v "$PWD/host-src":/workspace \
  -v ovlab2:/workspace/node_modules \
  debian/eol:buster sleep 300

docker exec ovdemo bash -c '
  dd if=/dev/zero of=/tmp/relleno.bin bs=1M count=20                      # writable layer
  dd if=/dev/zero of=/workspace/node_modules/relleno.bin bs=1M count=20   # named volume
  echo cambio >> /workspace/app.js                                        # bind mount
'

docker ps -s --filter name=ovdemo --format '{{.Names}} | {{.Size}}'
```

```text
ovdemo | 21MB (virtual 154MB)
```

Sesenta megas escritos, veintiuno contados. Los números dicen todo:

- **`21MB`** es el `upperdir`: los 20 MB de `/tmp` más el ruido de metadata. **Solo eso pertenece al contenedor.**
- **`virtual 154MB`** es el `upperdir` más las capas de la imagen — y ese tramo es **compartido**: diez contenedores desde la misma imagen no ocupan 1,54 GB.
- Los 20 MB del named volume y el cambio en el bind mount **no aparecen por ningún lado**, y `docker diff` tampoco los muestra.

Y ahí está el porqué mecánico de una decisión que el curso tomó en **[F01](01-decisiones-debian-zonas-node.md)** casi como sentido común: un bind mount y un volume **no son parte del overlay**. Son montajes que se colocan encima de la vista unificada, con su propio filesystem detrás. Escribir en ellos no dispara copy-up, no engorda la writable layer, no desaparece al borrar el contenedor y —esto es lo que se nota en un `npm ci`— no paga el costo del union filesystem por cada uno de los 40.000 archivos que crea npm.

Al terminar, limpia el escenario:

```bash
docker rm -f ovdemo
docker volume rm ovlab2
```

> 🧠 **Modelo mental.** El overlay es para lo que la imagen trae. Los mounts son para lo que tú produces. Cuando dudes dónde poner algo, pregúntate si quieres que sobreviva al `docker rm`: si la respuesta es sí, no va en el overlay.

---

## 12. ⚖️ Por qué `RUN rm` no adelgaza una imagen: con números

Este es el clásico. Tres Dockerfiles que hacen "lo mismo":

```dockerfile
# A — crea 50 MB y los deja
FROM debian/eol:buster
RUN dd if=/dev/urandom of=/big.bin bs=1M count=50
```

```dockerfile
# B — crea 50 MB y los borra en la capa siguiente
FROM debian/eol:buster
RUN dd if=/dev/urandom of=/big.bin bs=1M count=50
RUN rm /big.bin
```

```dockerfile
# C — crea y borra en la MISMA capa
FROM debian/eol:buster
RUN dd if=/dev/urandom of=/big.bin bs=1M count=50 && rm /big.bin
```

Medido con `docker image inspect --format '{{.Size}}'`:

| Dockerfile | Bytes | Lectura |
|---|---|---|
| A — lo deja | 102.115.180 | la línea base |
| B — `rm` en otra capa | 102.115.651 | **471 bytes MÁS**, no menos |
| C — `rm` en la misma capa | 49.670.226 | ~52 MB menos |

> 🩺 **Si repites la medición, no esperes los mismos siete dígitos.** El relleno sale de
> `/dev/urandom`, así que cada build genera 50 MB distintos y el tar comprimido cae unos pocos
> bytes arriba o abajo: una segunda pasada dio `102.115.174` para A, con B y C idénticos al
> byte. Lo que **no** se mueve es lo que importa —el orden de magnitud de las tres filas y el
> signo de la diferencia entre A y B—. Si tu B sale unos cientos de bytes por encima de tu A,
> la medición es correcta.

B no solo no adelgaza: **engorda**, porque el whiteout también ocupa. Los 50 MB siguen en el blob de la capa anterior, que es inmutable y ya está publicado; lo único que añadiste fue una marca que dice "no lo muestres".

C funciona porque el archivo nace y muere **dentro de la misma capa**, y lo que se empaqueta es el diff resultante: el archivo nunca llegó a existir en ningún tar.

> 🧭 **La regla que sale de aquí, y que el curso ya venía aplicando.** `apt-get update && apt-get install ... && rm -rf /var/lib/apt/lists/*` va todo en **un solo `RUN`** no por elegancia ni por contar capas: porque partirlo deja los índices de APT horneados para siempre en el blob anterior. Ahora sabes por qué, y sabes medirlo.

> ⚠️ **Corolario de seguridad, que importa más que el tamaño.** Un secreto copiado en una capa y borrado en la siguiente **sigue en la imagen** y sale con cada `docker push`. `docker image history` lo delata, y cualquiera que descargue la imagen puede extraer esa capa. Un `rm` no es una forma de quitar un secreto de una imagen; la única forma es que nunca haya entrado.

---

## 13. 🧵 Lo que esto explica del laboratorio

Con el mecanismo en la mano, tres decisiones del curso dejan de ser recetas:

**`node_modules` en un named volume.** No es solo por rendimiento del cruce host↔VM. Es que 40.000 archivos pequeños creados en la writable layer significan 40.000 entradas en `upperdir`, con copy-up cada vez que un `npm rebuild` toca algo que venía de abajo, y todo eso muere con el contenedor. En un volume, npm escribe sobre un filesystem normal.

**El toolchain en la imagen, el proyecto en el host.** El toolchain es lo que quieres compartido y de solo lectura entre todos los contenedores: eso es literalmente la definición de `lowerdir`. El proyecto es lo que cambia cada minuto y debe sobrevivir: eso no puede estar en un `upperdir` efímero.

**Los contenedores son desechables.** Ahora es una afirmación técnica y no un eslogan: destruir un contenedor es borrar su `upperdir` y desmontar el overlay. Si algo importante se pierde con eso, estaba mal ubicado.

> 💡 **Prueba de fuego.** Corre tu `npm ci` habitual en el contenedor de **[F09](09-montar-tu-proyecto.md)** y, sin pararlo, mira `docker ps -s`. Si el `size` creció cientos de megas, tu `node_modules` está cayendo en la writable layer y el named volume no está haciendo lo que crees.

---

## 14. 🧊 Lo que OverlayFS no es

Tres confusiones frecuentes, cortadas de raíz:

- **No es un snapshot de bloques.** No hay LVM ni copy-on-write a nivel de disco: OverlayFS trabaja con **archivos y directorios**, y su unidad de copia es el archivo completo.
- **No es un disco virtual.** Un contenedor no tiene "su disco": tiene un montaje que apunta a directorios del host —o de la VM del motor—.
- **No es aislamiento de seguridad.** Que las capas sean de solo lectura protege la **imagen**, no al host. El aislamiento lo dan namespaces, cgroups y, si toca, user namespaces — **[F16](16-pid1-senales-y-ciclo-de-vida.md)** y **[F25](25-rootless-y-user-namespaces.md)**.

---

## 15. ⚠️ Errores comunes y diagnóstico

- **"Borré el archivo grande y la imagen pesa igual."** El `rm` está en una capa posterior. Confírmalo con `docker image history --no-trunc` y compara con la versión de un solo `RUN` (§12).
- **"El contenedor crece sin parar."** Algo está escribiendo en la writable layer: logs, caché de npm, artefactos de build. `docker diff` te dice qué, en un segundo.
- **"Al recrear el contenedor perdí `node_modules`."** Estaba en el `upperdir` y no en un volume. `docker inspect --format '{{json .Mounts}}'` confirma dónde estaba montado de verdad.
- **`mount: wrong fs type, bad option, bad superblock on overlay`** al reproducir el laboratorio de la §6. Estás intentando poner `upperdir` **encima de otro overlay**, cosa que el kernel no permite. Solución: pon los directorios en un volume o en un `tmpfs`, como hace el comando de esta fase.
- **"En mi Mac no encuentro `/var/lib/docker/overlay2`."** No existe en tu Mac: vive dentro de la VM del motor. Entra por `/proc/mounts` desde un contenedor (§9), que funciona en las tres plataformas.

---

## 16. 📋 Checklist de validación

```text
[ ] monté un overlay a mano y vi qué lowerdir gana cuando el archivo se repite
[ ] provoqué un copy-up y encontré el archivo duplicado en upperdir
[ ] identifiqué un whiteout como character device 0,0
[ ] leí el / de un contenedor en /proc/mounts y reconocí las cuatro rutas
[ ] interpreté A, C y D en docker diff sin dudar
[ ] distinguí size de virtual en docker ps -s y expliqué qué es compartido
[ ] comprobé que escribir en un volume NO aumenta el size del contenedor
[ ] medí los tres Dockerfiles de §12 y obtuve la misma dirección en los números
[ ] puedo explicar en una frase por qué un secreto borrado sigue en la imagen
```

---

## 17. 🧪 Ejercicios de la Fase 13 (28)

## 🟢 Fácil — ver el mecanismo (1–8)

### 🟢 Ejercicio 1 — Monta un overlay a mano

Reproduce el laboratorio de §6 completo, hasta ver quién gana `base.txt`.

**Objetivo:** haber montado un union filesystem con tus manos, sin Docker de por medio. Es el
ejercicio que convierte la fase en algo que entiendes en lugar de algo que leíste.

### 🟢 Ejercicio 2 — Tres `lowerdir`

Repite el montaje con **tres** capas inferiores y el mismo archivo en las tres, con contenido
distinto.

**Pregunta:** ¿cuál gana? Formula la regla de precedencia con tus palabras y comprueba qué pasa
si inviertes el orden en la opción `lowerdir=`.

### 🟢 Ejercicio 3 — Caza el whiteout

Borra un archivo desde `merged` y ejecuta `stat -c '%n | %F' /lab/upper/<archivo>`.

**Objetivo:** identificar el character device `0,0` y confirmar con `ls /lab/lower1` que el
original sigue intacto.

### 🟢 Ejercicio 4 — El `/` de tu contenedor

Ejecuta el comando de §9 sobre tres imágenes distintas: `debian/eol:buster`,
`legacy-node-toolchain:phase09` y `alpine`.

**Pregunta:** ¿cuántos `lowerdir` tiene cada una y qué relación tiene ese número con
`docker image history`?

### 🟢 Ejercicio 5 — Lee un `docker diff`

Monta el escenario de §10 y obtén las tres letras.

**Objetivo:** poder explicar `A`, `C` y `D` sin mirar la fase, incluida la razón de que `/etc`
aparezca como `C` sin que tú lo tocaras.

### 🟢 Ejercicio 6 — `size` contra `virtual`

Arranca dos contenedores de la misma imagen y mira `docker ps -s`.

**Pregunta:** ¿suman sus `virtual`? ¿Qué parte es compartida y cuál no?

### 🟢 Ejercicio 7 — El `workdir` que OverlayFS exige

Repite el montaje de §6 pero **quitando** la opción `workdir=` del `mount`:

```bash
mount -t overlay overlay -o lowerdir=/lab/lower1,upperdir=/lab/upper /lab/merged
```

**Objetivo:** leer el error literal que devuelve el kernel y comprobar con `dmesg | tail` si
dice algo más.

**Pregunta:** ¿para qué necesita OverlayFS un tercer directorio, si ya tiene el de abajo y el
de arriba? Pista: piensa en qué tiene que pasar **a medias** durante un copy-up de un archivo
de 500 MB, y qué pasaría si el sistema se apagara justo entonces. La respuesta explica también
por qué `workdir` tiene que estar en el mismo sistema de archivos que `upperdir`.

### 🟢 Ejercicio 8 — Las cuatro filas de `docker system df`

```bash
docker system df
docker system df -v | head -30
```

**Objetivo:** identificar las cuatro categorías —imágenes, contenedores, volúmenes local y
caché de build— y decir cuánto ocupa cada una y cuánto es **reclamable**.

**Pregunta:** la columna `SHARED SIZE` de las imágenes es la clave de toda esta fase. Con dos
o tres imágenes del curso descargadas, ¿cuánto es compartido y cuánto es único? Y la pregunta
que la fase ya te dejó contestar: **¿por qué la suma de los tamaños de tus imágenes es mayor
que lo que ocupan en disco?**

## 🟡 Intermedio — provocar el mecanismo (9–16)

### 🟡 Ejercicio 9 — El volumen no engorda

Escribe 50 MB en un named volume desde un contenedor y comprueba `docker ps -s` y
`docker diff`.

**Objetivo:** confirmar que los mounts están fuera del overlay, que es la mitad del porqué de
todo el diseño del laboratorio.

### 🟡 Ejercicio 10 — Mide un copy-up

Crea un archivo de 500 MB en una imagen, arranca un contenedor y añádele **un byte** con
`echo x >> archivo`, cronometrando con `time`.

**Pregunta:** ¿cuánto tardó, y cuánto tarda la segunda vez? Explica la diferencia con lo que
dice §7.

### 🟡 Ejercicio 11 — Los tres Dockerfiles

Construye A, B y C de §12 y mide con `docker image inspect --format '{{.Size}}'`.

**Pregunta:** ¿obtuviste la misma dirección en los números? ¿Cuánto pesa exactamente el
whiteout de B?

### 🟡 Ejercicio 12 — Predice antes de medir

Antes de construirlo, **predice** el tamaño de un Dockerfile que crea 50 MB en el `RUN` 1, los
borra en el 2, y crea otros 50 MB en el 3.

**Objetivo:** comprobar si tu modelo ya predice bien. Si fallaste, di en qué paso se rompió tu
razonamiento.

### 🟡 Ejercicio 13 — Encuentra el `upperdir` real

En Linux nativo, obtén el `upperdir` de un contenedor vivo con
`docker inspect --format '{{.GraphDriver.Data.UpperDir}}'` y lístalo mientras escribes dentro.

**Objetivo:** ver el `upperdir` crecer en tiempo real desde el host. Si estás en macOS o
Windows, explica por qué no puedes y qué camino te queda (§9).

### 🟡 Ejercicio 14 — El contenedor que engorda

Arranca un contenedor que escriba un log continuamente dentro de la writable layer y vigila
`docker ps -s` cada treinta segundos.

**Objetivo:** ver el número subir y localizar el culpable con `docker diff` en un solo comando.

### 🟡 Ejercicio 15 — Recrear pierde, el volumen no

Instala dependencias con `node_modules` en la writable layer —sin volumen—, borra el contenedor
y crea otro.

**Pregunta:** ¿qué se perdió? Repítelo con volumen y compara. Es la demostración de §13.

### 🟡 Ejercicio 16 — Hardlinks contra copy-up

Un detalle del copy-on-write que muerde en silencio. Construye una imagen donde dos rutas
sean el **mismo** archivo por hardlink:

```dockerfile
FROM debian/eol:buster
RUN echo "original" > /datos/a.txt \
    && ln /datos/a.txt /datos/b.txt \
    && ls -li /datos/
```

Arranca un contenedor, comprueba con `ls -li` que los dos comparten número de inodo, escribe
en `a.txt` y vuelve a mirar.

**Pregunta:** ¿siguen compartiendo inodo? ¿Cambió `b.txt` cuando escribiste en `a.txt`?
Predice la respuesta antes de mirar. **Objetivo:** entender que el copy-up trabaja sobre
**nombres**, no sobre inodos, y que un hardlink no sobrevive a la subida de capa — que es
exactamente el motivo de que ciertos gestores de paquetes que usan hardlinks para ahorrar
espacio se comporten raro dentro de contenedores.

## 🟠 Difícil — medir y diagnosticar (17–23)

### 🟠 Ejercicio 17 — El secreto que sobrevive

Construye una imagen que copie un archivo con una cadena reconocible y lo borre en el `RUN`
siguiente. Después extrae las capas con `docker save` y busca la cadena con `grep -r`.

**Objetivo:** encontrar el secreto dentro de una imagen donde el archivo "no existe". Si
hiciste el ejercicio 18 de [F07](07-build-de-la-imagen.md), esta es su segunda mitad.

### 🟠 Ejercicio 18 — Reproduce el error del laboratorio

Intenta montar el overlay de §6 **sin** el volumen, directamente sobre el filesystem del
contenedor.

**Objetivo:** provocar `wrong fs type, bad option, bad superblock on overlay`, y explicar en una
frase por qué el kernel se niega.

### 🟠 Ejercicio 19 — Adelgaza un Dockerfile ajeno

Te dan este fragmento, que produce una imagen de 900 MB:

```dockerfile
RUN curl -fsSLo /tmp/sdk.tar.gz https://ejemplo/sdk.tar.gz
RUN tar -xzf /tmp/sdk.tar.gz -C /opt
RUN rm /tmp/sdk.tar.gz
```

**Objetivo:** reescribirlo para que pese lo mínimo posible **sin cambiar el resultado**, medir
el antes y el después, y explicar con el mecanismo de §12 por qué el original pesaba de más.

### 🟠 Ejercicio 20 — Diagnostica sin preguntar

Alguien reporta: *"mi contenedor de desarrollo ocupa 4 GB y no sé por qué"*. Escribe la
secuencia de comandos que le pedirías, en orden, de la más barata a la más cara.

**Objetivo:** un procedimiento, no una respuesta. Debe empezar por `docker ps -s` y `docker
diff`, y llegar a distinguir writable layer de volúmenes en tres comandos.

### 🟠 Ejercicio 21 — Un overlay encima de otro overlay

OverlayFS puede apilarse sobre sí mismo, y hacerlo a mano deja clarísimo lo que Docker hace
por ti con cada capa. Monta el overlay de §6, y después monta un **segundo** overlay cuyo
`lowerdir` sea el `merged` del primero:

```bash
mkdir -p /lab/upper2 /lab/work2 /lab/merged2
mount -t overlay overlay2 \
  -o lowerdir=/lab/merged,upperdir=/lab/upper2,workdir=/lab/work2 /lab/merged2
```

Escribe en `/lab/merged2`, borra desde ahí un archivo que venga de `lower1`, y después
inspecciona los **dos** `upperdir`.

**Pregunta:** ¿en cuál de los dos `upper` acabó el whiteout, y qué ve alguien que mire
`/lab/merged` mientras tanto? **Objetivo:** poder explicar con este montaje por qué
`docker commit` sobre un contenedor produce una capa nueva en lugar de modificar las de
abajo.

### 🟠 Ejercicio 22 — `docker export` contra `docker save`

Los dos sacan una imagen a un tar y producen cosas muy distintas. Hazlo con la misma imagen y
compara:

```bash
docker run --name expdemo legacy-node-toolchain:phase13 true
docker export expdemo -o export.tar
docker save  legacy-node-toolchain:phase13 -o save.tar
ls -lh export.tar save.tar
tar tf export.tar | head -5
tar tf save.tar   | head -20
```

**Pregunta:** ¿cuál es más grande y por qué? Mira la **estructura** de los dos: uno tiene un
`manifest.json` y varios directorios de capa, el otro tiene un sistema de archivos plano.

**Objetivo:** decir, con una frase para cada uno, qué se pierde al usar `export` —hay dos
cosas: la historia y algo más que la imagen lleva y el contenedor no—, y en qué situación
real cada uno es el correcto. La segunda pérdida es la que convierte esto en un fallo de
**[a13](a13-air-gapped.md)** si te equivocas de comando.

### 🟠 Ejercicio 23 — El log que llenó el disco

Escenario habitual y con final feliz cuando sabes esta fase. Arranca un contenedor que
escriba sin parar **dentro** de la writable layer y vigila:

```bash
docker run -d --name loglab legacy-node-toolchain:phase13 \
  bash -c 'while true; do echo "$(date) linea de log" >> /var/log/app.log; sleep 0.01; done'
watch -n 5 'docker ps -s --filter name=loglab'
```

**Objetivo:** ver el `size` crecer, localizar el culpable **con un solo comando** —`docker
diff`— y decir a qué letra corresponde. Después arregla el escenario de las **dos** formas que
la fase permite: sacando el archivo del overlay con un mount, y limitando el crecimiento.

**Pregunta:** si en lugar de escribir en `/var/log/app.log` el proceso escribiera en `stdout`,
¿aparecería en `docker ps -s`? Averígualo, y explica dónde acaban entonces esos bytes y quién
los limita. Es una respuesta que cambia por completo dónde hay que ir a mirar.

## 🔴 Muy difícil — explicar el diseño con el mecanismo (24–28)

### 🔴 Ejercicio 24 — El storage driver importa

Averigua qué storage driver usa tu motor con `docker info --format '{{.Driver}}'` y lee la
primera línea de `/proc/mounts` desde un contenedor.

**Pregunta:** ¿coinciden? ¿Qué verías si el driver fuera `vfs`, y qué consecuencia de
rendimiento tendría? Relaciónalo con el 💡 truco de §9.

### 🔴 Ejercicio 25 — Explica el laboratorio con el mecanismo

Sin volver a leer §13, escribe la justificación **mecánica** —no de rendimiento— de las tres
decisiones del curso: `node_modules` en named volume, toolchain en la imagen y proyecto en el
host, y contenedores desechables.

**Objetivo:** que cada una mencione `lowerdir`, `upperdir`, copy-up o whiteouts. Si puedes
explicarlas sin usar ninguna de esas cuatro palabras, todavía estás repitiendo la receta en
lugar de entenderla.

### 🔴 Ejercicio 26 — Audita el tamaño de tu propia imagen

Toma `legacy-node-toolchain` y produce un informe de dónde está cada megabyte: qué capa, qué
instrucción, y si es evitable.

**Objetivo:** llegar a una lista priorizada de "esto se puede quitar y esto no", con el número
al lado de cada línea. La parte difícil es la honestidad: casi todo lo que pesa hace falta, y
decirlo es parte del informe.

### 🔴 Ejercicio 27 — Clasifica cada ruta que tu proyecto escribe

Coge tu proyecto legacy real —o un fixture— y haz el inventario completo de **todo** lo que
escribe cuando ejecutas `npm ci`, `npm test`, `npm run build` y el dev server. Sí, todo: hay
más de lo que crees, y `docker diff` te lo va a enseñar.

**Objetivo:** una tabla con una fila por ruta y cuatro columnas: **qué escribe ahí**, **dónde
vive hoy** (imagen, overlay, named volume o bind mount), **dónde debería vivir** y **el
porqué mecánico** —no "por limpieza": copy-up, whiteout, tamaño del blob o supervivencia al
`docker rm`—.

**Pregunta de cierre:** de las rutas que hoy están en el overlay, ¿cuál te está costando más
—en bytes o en tiempo de copy-up— y por qué nadie se había dado cuenta? Si tu tabla no tiene
al menos una fila donde la respuesta cambie respecto de lo que hacías antes de esta fase, no
has mirado bastante.

### 🔴 Ejercicio 28 — Mide el copy-up antes de opinar sobre él

§7 avisa de que el copy-up copia el archivo entero la primera vez que lo tocas, y que en un
`node_modules` de 300 MB dentro de la imagen eso se paga completo. Ponle números, porque la
diferencia entre "esto es lento" y "esto tarda 4,2 s la primera vez y 3 ms las siguientes" es
la diferencia entre una queja y un argumento.

**Objetivo:** construir una imagen con archivos de varios tamaños —1 MB, 50 MB, 500 MB—,
arrancar un contenedor y cronometrar **el primer byte escrito** en cada uno y el segundo:

```bash
time bash -c 'printf x >> /datos/grande.bin'   # primera vez: copy-up
time bash -c 'printf x >> /datos/grande.bin'   # segunda: ya está arriba
```

Produce la tabla de tres tamaños × dos escrituras y calcula la relación entre tamaño y tiempo
del primer acceso.

**Pregunta de cierre:** con tus números, ¿a partir de qué tamaño de archivo dejarías de
aceptar que viva en la imagen si el proceso lo va a modificar? Y la segunda mitad, que es la
que decide arquitectura: ¿cambia tu respuesta si el archivo se **lee** mucho y se **escribe**
una vez? Justifica con el mecanismo, no con la intuición.

## 🔥 Opcionales

### 🔥 Ejercicio 29 — Un overlay de tres pisos con whiteouts anidados

Monta tres capas donde la intermedia borre un archivo de la inferior y la superior lo vuelva a
crear.

**Pregunta:** ¿qué ve `merged`? ¿Y qué hay físicamente en cada directorio? Dibuja el resultado
antes de mirarlo.

### 🔥 Ejercicio 30 — `docker save` y el tar de una capa

Exporta una imagen con `docker save`, descomprímela y explora la estructura: manifest, config y
los blobs de capa.

**Objetivo:** ver el formato OCI de §6 de [F12](12-capas-cache-y-contexto.md) como archivos reales en tu disco, y encontrar el
whiteout dentro del tar de una capa (`.wh.<nombre>`).

## 💀 Boss fight

### 💀 Ejercicio 31 — Boss fight: el secreto que no se va

Te entregan una imagen publicada en la que, según su historia, alguien copió por error un
archivo de credenciales y lo borró en la capa siguiente. El equipo pregunta si basta con
"reconstruir sin esa línea y volver a publicar".

**Objetivo:** responder con evidencia, no con opinión. Tienes que: (1) **demostrar** que el
secreto sigue extraíble de la imagen publicada, con los comandos exactos; (2) explicar por qué
reconstruir y republicar **no basta** si alguien ya descargó la imagen o si el tag anterior
sigue accesible por digest; (3) enumerar lo que sí hay que hacer, en orden. Este ejercicio
encadena §8, §12 y lo que **[F27](27-registries-por-dentro.md)** dirá sobre digests — y es exactamente la conversación que vas
a tener el día que pase de verdad.

---

## 18. 📚 Referencias

- Documentación del kernel — OverlayFS (la fuente, y es legible): https://www.kernel.org/doc/html/latest/filesystems/overlayfs.html
- Docker — storage drivers y `overlay2`: https://docs.docker.com/engine/storage/drivers/overlayfs-driver/
- Docker — imágenes, capas y contenedores: https://docs.docker.com/get-started/docker-concepts/building-images/understanding-image-layers/
- OCI Image Spec — filesystem layers y whiteouts en el formato del tar: https://github.com/opencontainers/image-spec/blob/main/layer.md
- `mount(8)`, sección de overlay: https://manpages.debian.org/buster/mount/mount.8.en.html

---

## 19. 🏁 Resultado de la fase

```mermaid
flowchart TD
    subgraph IMAGEN
        L["lowerdir (compartido)<br/>capas de solo lectura"]
    end
    subgraph CONTENEDOR
        U["upperdir (efímero, por contenedor)<br/>una capa escribible"]
    end
    L --> M["merged<br/>el / que ve el proceso"]
    U --> M
    BM["bind mounts y volumes<br/>se montan ENCIMA, fuera del overlay:<br/>no copy-up, no whiteouts, sobreviven al docker rm"] -. "encima" .-> M
```

> **La señal de que quedó bien:** cuando veas crecer una imagen o un contenedor, ya no preguntas *"¿por qué pesa tanto?"* sino *"¿en qué capa entró eso, y en cuál se supone que se fue?"* — y sabes qué comando responde cada una.

---
