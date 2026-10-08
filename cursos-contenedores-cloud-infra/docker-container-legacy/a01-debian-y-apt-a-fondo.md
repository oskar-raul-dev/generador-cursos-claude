# 📦 Apéndice a01 — Debian y APT a fondo, y supervivencia en la shell

> **Curso:** Docker Legacy Node · **Apéndice opcional**
> **Cierra los bucles de:** [F03](03-apt-y-utilidades.md) §4 · [F31](31-catalogo-de-fallos-i.md) §4 · [F32](32-catalogo-de-fallos-ii.md) §4
> **Requisitos:** haber hecho F03. Aquí está lo que esa fase resumió en cuatro opciones
> **Qué encontrarás:** por qué Debian tiene media docena de comandos para instalar paquetes, la anatomía del `sources.list`, cómo se resuelven las dependencias de verdad, y una guía de supervivencia para cuando estés dentro del contenedor y no sepas por dónde empezar

[F03](03-apt-y-utilidades.md) te dio lo operativo: cuatro opciones de un `RUN` y por qué van juntas. Este apéndice es el
tratado, y la última sección es la que más gente agradece: **qué hacer cuando abres una shell en
Debian 10 y te sientes perdido**.

---

## 🧭 Índice de salto rápido

| Si tu pregunta es… | Ve a |
|---|---|
| "¿Por qué hay `apt`, `apt-get`, `apt-cache` y `dpkg`?" | [§1](#1--cuatro-comandos-y-una-división-que-tiene-sentido) |
| "¿De dónde saca APT los paquetes?" | [§2](#2-️-el-sourceslist-por-dentro) |
| "¿Qué es un mirror y necesito uno?" | [§3](#3--mirrors-y-por-qué-aquí-no-hacen-falta) |
| "¿`Depends`, `Recommends`, `Suggests`?" | [§4](#4--las-tres-relaciones-entre-paquetes) |
| "¿Qué se descarga exactamente y dónde queda?" | [§5](#5--índices-y-archivos-son-cosas-distintas) |
| "Estoy dentro del contenedor y no sé qué hacer" | [§6](#6--supervivencia-en-la-shell-del-contenedor) |

---

## 1. 🧰 Cuatro comandos, y una división que tiene sentido

Al principio parece que Debian repartió una sola tarea entre media docena de programas para
comprobar si estabas prestando atención. 😄 La división es histórica y tiene lógica.

| Comando | Para qué | Cuándo |
|---|---|---|
| **`apt`** | interfaz moderna y amigable | a mano, en una terminal |
| **`apt-get`** | interfaz estable y predecible | **scripts y Dockerfiles** |
| **`apt-cache`** | consultar el catálogo sin instalar | investigar antes de tocar |
| **`dpkg`** | manipular paquetes ya instalados y archivos `.deb` | inspeccionar qué hay |

**Por qué los Dockerfiles usan `apt-get` y no `apt`.** `apt` está pensado para humanos: cambia
su salida entre versiones, muestra barras de progreso y **avisa explícitamente de que no tiene
una interfaz estable para scripts**. `apt-get` sí la tiene. En un build, la previsibilidad vale
más que la comodidad.

```bash
apt-get update && apt-get install -y --no-install-recommends curl   # ✅ en un Dockerfile
apt install curl                                                     # ✅ a mano, exploratorio
```

**La regla mental que ordena los cuatro:**

```text
APT   → repositorios · dependencias · descarga
dpkg  → lo que YA está instalado · archivos .deb sueltos
```

### 1.1 Las consultas que más vas a usar

```bash
apt-cache policy curl        # ¿qué versión hay y de dónde vendría?
apt-cache show curl          # los metadatos completos
apt-cache depends curl       # de qué depende
apt-cache rdepends curl      # quién depende de él
apt-cache search json        # buscar por palabra clave

dpkg -s curl                 # ¿está instalado? ¿qué versión?
dpkg -L curl                 # qué archivos puso
dpkg -S /usr/bin/curl        # ¿de qué paquete salió este archivo?
dpkg -l | grep curl          # listar
```

> 🩺 **`dpkg -S` es la que más gente desconoce y más resuelve.** Encuentras un binario en el
> contenedor y quieres saber de dónde salió: te lo dice en un comando. Es la primera pregunta
> cuando auditas una imagen ajena — [F33](33-forense-y-boss-fight.md) §4.

---

## 2. 🗺️ El `sources.list` por dentro

APT necesita saber de dónde bajar. En Debian 10 eso vive en `/etc/apt/sources.list` y en
`/etc/apt/sources.list.d/`.

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase15 \
  cat /etc/apt/sources.list
```

Y la anatomía de una línea:

```text
deb  http://archive.debian.org/debian  buster  main contrib non-free
 │            │                           │       │
 │            │                           │       └── COMPONENTES
 │            │                           └────────── SUITE (o release)
 │            └────────────────────────────────────── URL del repositorio
 └─────────────────────────────────────────────────── TIPO: deb o deb-src
```

**`deb` frente a `deb-src`.** El primero trae paquetes binarios; el segundo, el código fuente.
En un contenedor de desarrollo casi nunca necesitas `deb-src`, y activarlo duplica el tamaño de
los índices que descargas.

**Los tres componentes de Debian**, que son una decisión de licencia y no de calidad:

| | Qué contiene |
|---|---|
| **`main`** | software libre según las directrices de Debian. Es la enorme mayoría |
| **`contrib`** | libre, pero depende de algo que no lo es |
| **`non-free`** | no libre: firmware, algunas fuentes, códecs |

**Y las suites, que confunden:**

```text
buster              la release estable, tal como salió + actualizaciones puntuales
buster-updates      cambios que no esperan al siguiente punto de release
buster/updates      seguridad — ojo con la barra, es otra cosa que buster-updates
buster-backports    versiones más nuevas recompiladas para Buster
```

> 📝 **En `debian/eol:buster` esas líneas apuntan a `archive.debian.org`** y no a
> `deb.debian.org`, que es lo que hace que el laboratorio funcione años después. [F01](01-decisiones-debian-zonas-node.md) §4.4 tomó
> esa decisión; aquí ves la línea concreta que la implementa.

---

## 3. 🌎 Mirrors, y por qué aquí no hacen falta

Un **mirror** es una copia del repositorio en otro servidor, normalmente más cerca de ti.
Debian tiene decenas por todo el mundo, y `deb.debian.org` es un redirector que te manda al que
le parece.

**Por qué este curso no los usa:** Buster está archivado, y **el archivo no se replica como los
mirrors activos**. `archive.debian.org` es la fuente, no hay copia local que buscar, y cambiar
esa URL por un mirror de tu país produce un 404.

**Y cómo evaluarías uno, si trabajaras con una release activa:**

```bash
# ¿responde y qué tal de rápido?
time curl -sI http://deb.debian.org/debian/dists/bookworm/Release | head -1

# ¿está actualizado? mira la fecha del Release
curl -s http://deb.debian.org/debian/dists/bookworm/Release | grep '^Date:'
```

> ⚠️ **Antes de tocar un `sources.list`, cópialo.** Es el archivo que más fácil se rompe y peor
> se diagnostica: un error de sintaxis produce un `apt-get update` que falla con un mensaje que
> no menciona la línea.
>
> ```bash
> cp /etc/apt/sources.list /etc/apt/sources.list.bak
> ```

---

## 4. 🌳 Las tres relaciones entre paquetes

Un paquete Debian declara qué necesita, y hay tres niveles:

| | Qué significa | ¿Lo instala APT? |
|---|---|---|
| **`Depends`** | **no funciona sin esto** | siempre |
| **`Recommends`** | "casi siempre lo querrás" | por defecto sí; con `--no-install-recommends` no |
| **`Suggests`** | "esto te podría interesar" | nunca automáticamente |

```bash
apt-cache show curl | grep -E '^(Depends|Recommends|Suggests):'
```

**Y aquí está la aclaración que [F03](03-apt-y-utilidades.md) §4.1 hizo y que conviene desarrollar:**
`--no-install-recommends` **no** es "sin dependencias". Las `Depends` se instalan igual,
incluidas sus propias `Depends` — las **transitivas**.

```text
pides:        curl
Depends:      libcurl4, zlib1g, libssl1.1 …
              └── y cada una tiene las suyas: dependencias TRANSITIVAS
Recommends:   ca-certificates      ← esto es lo que se omite
```

> ⚠️ **Y el caso que produce más confusión:** `ca-certificates` es un `Recommends` de `curl`,
> no un `Depends`. Con `--no-install-recommends`, `curl` se instala perfectamente y **falla en
> cualquier descarga HTTPS**. Por eso [F03](03-apt-y-utilidades.md) §6 lo lista explícitamente en la caja de herramientas.
> La lección general: **si un paquete no funciona tras usar la opción, mira sus `Recommends`
> antes de quitar la opción.**

### 4.1 Ver el árbol completo

```bash
apt-cache depends --recurse --no-recommends --no-suggests \
  --no-conflicts --no-breaks --no-replaces --no-enhances curl | grep -c Depends
```

Ese número es la cantidad real de paquetes que arrastra `curl`. Suele sorprender.

---

## 5. 📥 Índices y archivos son cosas distintas

Es la distinción que explica el diseño del `RUN` de [F03](03-apt-y-utilidades.md).

```mermaid
flowchart TD
    U["apt-get update"] -- "descarga los ÍNDICES:<br/>qué paquetes existen, versiones, hashes" --> L["/var/lib/apt/lists/<br/>decenas de MB de listas"]
    I["apt-get install curl"] -- "descarga los ARCHIVOS .deb<br/>y los instala" --> A["/var/cache/apt/archives/<br/>los .deb descargados"]
    I --> B["/usr/bin/curl<br/>el resultado"]
```

**Y por qué se borra solo uno.** El `RUN` del curso hace
`rm -rf /var/lib/apt/lists/*` —los índices— y no toca `/var/cache/apt/archives/`, porque las
imágenes de Debian traen configurado que APT borre los `.deb` tras instalar:

```bash
docker run --rm legacy-node-toolchain:phase15 \
  cat /etc/apt/apt.conf.d/docker-clean
```

> 🧭 **La consecuencia declarada, otra vez:** sin índices, `apt-get install` no funciona dentro
> del contenedor hasta que ejecutes `apt-get update`. Es el precio de la limpieza, y [F32](32-catalogo-de-fallos-ii.md) §4.1 lo
> recoge como "no es un fallo".

---

## 6. 🐧 Supervivencia en la shell del contenedor

Esta sección existe porque el curso asume que sabes moverte por Linux y no todo el mundo llega
con eso. **Si abriste un `docker exec -it ... bash` y no sabes por dónde empezar, es aquí.**

### 6.1 Dónde estoy y qué hay

```bash
pwd                 # dónde estoy
ls                  # qué hay
ls -la              # con detalles, incluidos los ocultos
ls -lh              # tamaños legibles
cd /workspace       # ir a otro sitio
cd -                # volver al anterior
```

### 6.2 Leer archivos

```bash
cat package.json           # el archivo entero
head -20 install.log       # las primeras 20 líneas
tail -20 install.log       # las últimas 20
tail -f install.log        # y seguir viendo lo nuevo
less install.log           # paginado: q para salir, / para buscar
```

### 6.3 Buscar

```bash
grep 'error' install.log              # líneas que lo contienen
grep -i 'error' install.log           # sin distinguir mayúsculas
grep -n 'error' install.log           # con número de línea
grep -r 'TODO' src/                   # recursivo por un directorio
grep -B5 -A5 'error' install.log      # con 5 líneas de contexto alrededor
```

> 💡 **`-B` y `-A` son las que convierten `grep` en una herramienta de diagnóstico.** El error
> importante casi nunca está solo: está rodeado de contexto.

### 6.4 Tuberías y redirección

```bash
comando | otro                # la salida de uno entra en el otro
comando > archivo             # guardar, sobrescribiendo
comando >> archivo            # guardar, añadiendo
comando 2> errores.txt        # guardar solo los errores
comando > todo.txt 2>&1       # las dos cosas al mismo archivo
comando 2>&1 | tee todo.txt   # ver Y guardar        ← F20 §6
```

> ⚠️ **El orden importa:** `> f 2>&1` manda las dos cosas al archivo; `2>&1 > f` manda `stderr`
> a la terminal y `stdout` al archivo. Es de los errores de shell más frecuentes, y [F20](20-validacion-sistematica-y-evidencia.md) §6.1 lo
> desarrolla.

### 6.5 Encontrar programas

```bash
which node          # dónde está
command -v node     # más portable, hace lo mismo
type node           # y además dice si es alias, función o binario
readlink -f $(command -v node)   # a dónde apunta de verdad, siguiendo symlinks
```

**Ese último es el que usa el curso todo el tiempo**, porque con los shims de [F08](08-run-el-contenedor-como-proceso.md) lo importante
no es dónde está `node`, sino **a qué apunta**.

### 6.6 Entorno y procesos

```bash
printenv                   # todas las variables
printenv NODE_VERSION      # una
echo "$PATH" | tr ':' '\n' # el PATH, legible

ps -ef                     # todos los procesos
ps aux                     # otro formato del mismo
top                        # en vivo — q para salir
free -h                    # memoria
df -h                      # disco
id                         # quién soy: UID y GID
```

### 6.7 Cuando no sabes usar un comando

```bash
comando --help          # lo primero, y casi siempre basta
man comando             # el manual completo
apropos <tema>          # buscar comandos por tema
```

> 🧭 **El orden práctico:** `--help` primero, `man` si necesitas el detalle, e Internet solo
> después. En un contenedor legacy, la documentación **de la versión que tienes instalada** está
> en el `man`, y la de Internet describe otra.

### 6.8 Práctica de cinco minutos

Dentro del toolchain, resuelve estas cinco:

```text
1. ¿Qué versión de Debian es esta?              (pista: /etc/os-release)
2. ¿Cuántos paquetes hay instalados?            (pista: dpkg -l)
3. ¿De qué paquete salió /usr/bin/curl?         (pista: dpkg -S)
4. ¿A qué apunta realmente el comando node?     (pista: readlink -f)
5. ¿Qué proceso es el PID 1?                    (pista: ps -ef)
```

Si las cinco te salen sin buscar, ya te mueves por el contenedor.

---

## 🧭 Guía rápida: cuándo usar qué

| Tu situación | Comando |
|---|---|
| Escribes un Dockerfile | `apt-get install -y --no-install-recommends` |
| Exploras a mano en el contenedor | `apt` o `apt-get`, da igual |
| Quieres saber qué versión hay antes de instalar | `apt-cache policy` |
| Un paquete no funciona tras instalarlo | `apt-cache show` y mira sus `Recommends` |
| Encontraste un archivo y no sabes de dónde salió | `dpkg -S` |
| Quieres saber qué puso un paquete | `dpkg -L` |
| `apt-get install` dice que no encuentra el paquete | `apt-get update` primero |
| Vas a tocar el `sources.list` | cópialo antes |
| Estás perdido en la shell | §6, y empieza por `pwd` y `ls -la` |

---

## 🧪 Ejercicios (8)

### 🟢 Ejercicio 1 — Los cuatro comandos

Para `git`, usa `apt-cache policy`, `apt-cache depends`, `dpkg -s` y `dpkg -L`.

**Pregunta:** ¿cuál te dice la versión disponible y cuál la instalada?

### 🟢 Ejercicio 2 — La anatomía de tu `sources.list`

Lee el de la imagen del curso e identifica los cuatro elementos de §2 en cada línea.

**Pregunta:** ¿qué componentes están activos? ¿Hay `deb-src`?

### 🟢 Ejercicio 3 — `dpkg -S`

Elige cinco binarios de `/usr/bin` y averigua de qué paquete salió cada uno.

### 🟡 Ejercicio 4 — Los `Recommends` que faltan

Instala `curl` con `--no-install-recommends` en una imagen limpia e intenta una descarga HTTPS.

**Objetivo:** reproducir §4 y confirmar que `ca-certificates` es un `Recommends`.

### 🟡 Ejercicio 5 — El árbol completo

Ejecuta el `apt-cache depends --recurse` de §4.1 para `build-essential`.

**Pregunta:** ¿cuántos paquetes arrastra realmente?

### 🟡 Ejercicio 6 — Índices y archivos

Ejecuta `apt-get update`, mide `/var/lib/apt/lists/`, instala algo, y mira
`/var/cache/apt/archives/`.

**Pregunta:** ¿por qué el segundo está casi vacío? Lee `/etc/apt/apt.conf.d/docker-clean`.

### 🟠 Ejercicio 7 — Rompe el `sources.list`

Añade una línea con un error de sintaxis y ejecuta `apt-get update`.

**Objetivo:** ver que el mensaje **no** menciona la línea culpable, y entender por qué §3 insiste
en copiar el archivo antes.

### 🟠 Ejercicio 8 — La práctica de supervivencia

Resuelve las cinco preguntas de §6.8 sin buscar en Internet.

**Objetivo:** comprobar que puedes moverte por el contenedor con lo de §6. Si alguna te costó,
esa es la sección que releer.

---

## 📚 Referencias

- `apt(8)` en Buster: https://manpages.debian.org/buster/apt/apt.8.en.html
- `apt-get(8)`: https://manpages.debian.org/buster/apt/apt-get.8.en.html
- `apt-cache(8)`: https://manpages.debian.org/buster/apt/apt-cache.8.en.html
- `dpkg(1)`: https://manpages.debian.org/buster/dpkg/dpkg.1.en.html
- `sources.list(5)`: https://manpages.debian.org/buster/apt/sources.list.5.en.html
- Política de Debian sobre relaciones entre paquetes: https://www.debian.org/doc/debian-policy/ch-relationships.html
- Mirrors de Debian: https://www.debian.org/mirror/list

> ⚠️ **Todos los manpages apuntan a Buster a propósito.** APT ha añadido opciones y cambiado
> comportamientos desde entonces, y en este laboratorio la referencia buena es la de la versión
> que tienes instalada.

**Vuelve a:** [F03](03-apt-y-utilidades.md) · [F31 §4](31-catalogo-de-fallos-i.md) · [F32 §4](32-catalogo-de-fallos-ii.md)
