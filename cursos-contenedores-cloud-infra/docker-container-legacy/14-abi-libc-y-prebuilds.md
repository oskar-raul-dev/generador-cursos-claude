# 🧩 Parte II · Fase 14 — ABI, libc y prebuilds: el contrato binario que no ves

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · Node 10.24.1 / 12.22.12 / 14.21.3 / 16.20.2
> **Arquitectura objetivo del laboratorio:** `linux/amd64`
> **Requisitos:** **[F05](05-python-y-node-gyp.md)** (Python y node-gyp), **[F09](09-montar-tu-proyecto.md)** (volúmenes) y **[F13](13-overlayfs-y-copy-on-write.md)** (capas y copy-up)
> **Fecha de verificación ejecutada:** 6 de septiembre de 2026 — Docker 29.6.2 sobre macOS Apple Silicon, imagen `linux/amd64` bajo emulación
> **Estado de la imagen al terminar:** sin cambios. Esta fase explica por qué las cosas se rompen, no añade software
> **Objetivo:** entender qué es realmente una "dependencia nativa" —son cuatro casos distintos, no uno—, qué contrato binario obliga a recompilar entre versiones de Node, y por qué un `node_modules` no es portable

---

## 1. 🧭 Dónde estamos

Llevas media Parte I evitando un problema que nunca se explicó del todo. [F01](01-decisiones-debian-zonas-node.md) dijo que
`node_modules` va en un named volume "porque los binarios pertenecen al sistema que los
compiló". [F09](09-montar-tu-proyecto.md) te hizo nombrar el volumen con la versión de Node. [F11](11-validar-tu-proyecto.md) te pidió anotar
`process.versions.modules` sin decirte para qué.

Esta fase junta las tres piezas. Y empieza corrigiendo la palabra que lo enturbia todo:
**"dependencia nativa" es una etiqueta demasiado grande** para cuatro cosas que fallan de
formas distintas y se arreglan de formas distintas.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder:

- Clasificar cualquier dependencia problemática en uno de **cuatro casos**, y saber que cada
  uno tiene un diagnóstico propio.
- Explicar la diferencia entre **API** y **ABI**, y por qué es la que rompe tus addons.
- Leer `NODE_MODULE_VERSION` y predecir si un `.node` va a cargar o no.
- Entender qué es `glibc`, en qué se diferencia de `musl`, y por qué Alpine complica esto.
- Saber qué son los **prebuilds**, quién los sirve, y por qué el `package-lock.json` no
  puede congelarlos.
- Usar `file`, `ldd`, `readelf` y `nm` para diseccionar un binario y decir qué le pasa.

---

## 3. 🚧 Qué NO entra todavía

- **Los laboratorios reales** —`node-sass`, `canvas`, `sqlite3`, Puppeteer— con su autopsia
  completa → **[F15](15-laboratorios-dependencias-nativas.md)**, que es la continuación directa.
- **Binutils y la anatomía ELF a fondo** —`objdump`, `readelf` sección a sección— → **[a03](a03-binutils-y-elf.md)**.
- **Todo lo de ARM64**: por qué un prebuild `linux-x64` no sirve, y qué hacer → **[F21](21-arquitecturas-y-emulacion.md)** y
  **[F23](23-estudios-de-caso-multiplataforma.md)**.
- El **catálogo de fallos** de ABI en formato diagnóstico → **[F32](32-catalogo-de-fallos-ii.md)**.

---

## 4. 🧬 Cuatro casos, no uno

Cuando alguien dice "tengo un problema con una dependencia nativa", puede estar hablando de
cuatro situaciones que solo se parecen en el síntoma.

### 4.1 Caso A — JavaScript puro

```text
npm registry → paquete .js → node_modules → Node lo ejecuta
```

Sin compilación, sin binarios, sin arquitectura. **Es portable entre todo**: sistema
operativo, arquitectura y versión de Node. Si tu proyecto es todo caso A, `node_modules`
sería portable — y ni así conviene compartirlo, porque nunca sabes si lo es hasta que
falla.

### 4.2 Caso B — Addon nativo que se compila en tu máquina

El paquete trae código C o C++ y un `binding.gyp`, y durante `npm install` se compila con el
toolchain de [F04](04-toolchain-de-compilacion.md) y [F05](05-python-y-node-gyp.md). El resultado es un archivo `.node`:

```text
canvas.node · bcrypt_lib.node · binding.node · node_sqlite3.node
```

```text
JavaScript → require('canvas') → addon.node → librerías del sistema
```

Ese `.node` es una **librería compartida de Linux con otra extensión**, como comprobaste en
[F05](05-python-y-node-gyp.md). Está compilado para una arquitectura, una libc y **una versión de ABI de Node**
concretas.

### 4.3 Caso C — Addon nativo precompilado

Compilar C++ en cada `npm install` es lento, así que muchos paquetes publican binarios ya
compilados para las combinaciones más comunes:

```mermaid
flowchart TD
    A["npm instala el paquete"] --> B["script de install (postinstall)"]
    B --> Q{"¿hay un prebuilt compatible con<br/>mi plataforma, arquitectura y ABI?"}
    Q -- "sí" --> S["descargarlo. Rápido y silencioso"]
    Q -- "no" --> N["compilar. Aquí entra el toolchain de F04"]
```

**Es el caso que más problemas da en legacy**, y §7 explica por qué.

### 4.4 Caso D — npm descarga un programa que no es un addon

Puppeteer descarga un Chromium entero. Cypress descarga un Electron. `esbuild` descarga un
binario de Go. No son addons de Node: son **programas independientes** que el paquete se baja
durante su instalación.

Fallan por razones distintas —una URL que ya no responde, una arquitectura sin binario, una
librería del sistema que falta— y se diagnostican distinto. Tienen su tratamiento en **[a09](a09-browsers-legacy.md)**
y **[F15](15-laboratorios-dependencias-nativas.md)**.

> 🧭 **La primera pregunta ante un fallo de instalación no es "¿cómo lo arreglo?" sino "¿de
> qué caso estamos hablando?"**. Un caso B se arregla con el toolchain; un caso C, con
> forzar la compilación o encontrar el prebuild correcto; un caso D, casi nunca con
> ninguna de las dos.

---

## 5. 🔢 API y ABI: la distinción que rompe todo

Una **API** describe cómo interactúa **código fuente** con otro código: funciones, tipos,
parámetros, estructuras. Si respetas la API, tu código **compila**.

Una **ABI** —Application Binary Interface— describe cómo interactúa **código ya compilado**:
cómo se pasan los argumentos, cómo se disponen las estructuras en memoria, cómo se llaman las
funciones a nivel de máquina.

La consecuencia incómoda:

```text
código fuente compatible        ✅  compila sin tocar nada
binario previamente compilado   ❌  no carga
```

Los dos pueden ser ciertos a la vez, y ese es exactamente el problema de los addons legacy.
Node 12 puede aceptar el mismo código fuente que Node 10 y aun así rechazar el `.node` que
compilaste para Node 10.

### 5.1 `NODE_MODULE_VERSION`, el número que decide

Node lleva un contador de versión de ABI para addons, visible desde JavaScript:

```bash
node -p 'process.versions.modules'
```

Para nuestras cuatro generaciones:

| Node | `NODE_MODULE_VERSION` |
|---|---|
| 10.24.1 | **64** |
| 12.22.12 | **72** |
| 14.21.3 | **83** |
| 16.20.2 | **93** |

Esa tabla no la copiamos de ningún sitio: sale de correr las cuatro generaciones con los shims
de [F08](08-run-el-contenedor-como-proceso.md), que hacen esto trivial.

```bash
for v in 10.24.1 12.22.12 14.21.3 16.20.2; do
  printf '%-10s ' "$v"
  docker run --rm --platform linux/amd64 -e NODE_VERSION="$v" \
    legacy-node-toolchain:phase09 \
    node -p 'process.version + " → module " + process.versions.modules' 2>/dev/null
done
```

Y esto es lo que imprime, tal cual, sobre la imagen del laboratorio:

```text
10.24.1    v10.24.1 → module 64
12.22.12   v12.22.12 → module 72
14.21.3    v14.21.3 → module 83
16.20.2    v16.20.2 → module 93
```

**No es un número de marketing.** Cuando Node carga un `.node`, compara el ABI con el que
espera, y si no coincide se niega:

```text
Error: The module '/workspace/node_modules/bcrypt/lib/binding/bcrypt_lib.node'
was compiled against a different Node.js version using
NODE_MODULE_VERSION 64. This version of Node.js requires
NODE_MODULE_VERSION 83. Please try re-compiling or re-installing the module.
```

> 🧠 **Ese mensaje es de los pocos honestos que vas a encontrar en el ecosistema.** Dice el
> archivo, dice los dos números y dice qué hacer. Cuando lo veas, ya sabes exactamente qué
> pasó: reutilizaste un `node_modules` compilado para otra generación — es decir,
> reutilizaste el volumen equivocado. [F09](09-montar-tu-proyecto.md) §5.1 te avisó.

Y esa es la justificación completa, por fin, de nombrar el volumen `<proyecto>-node10-modules`
y no `<proyecto>-modules`.

---

## 6. 🐧 `glibc`, `musl`, y por qué "Linux" no es suficiente

Un binario compilado no solo depende de la arquitectura y del ABI de Node. Depende también de
la **biblioteca C del sistema**, que es la que le da acceso a todo lo que hace el kernel.

**`glibc`** es la implementación estándar de GNU, la que usan Debian, Ubuntu, RHEL y la
inmensa mayoría de distribuciones. **`musl`** es una implementación alternativa, mucho más
pequeña, y es la de Alpine.

No son intercambiables. Un binario enlazado dinámicamente contra `glibc` **no funciona** sobre
`musl`, y el error que da rara vez lo dice con claridad:

```text
Error loading shared library ld-linux-x86-64.so.2: No such file or directory
```

De ahí sale, por fin explicada del todo, la decisión de [F01](01-decisiones-debian-zonas-node.md) §4.2 de descartar Alpine: **los
binarios oficiales de Node y la enorme mayoría de los prebuilds asumen `glibc`**. Con `musl`
terminas compilándolo todo, que es el trabajo que este laboratorio existe para evitarte.

Hasta aquí el argumento vale para cualquier proyecto Node. **En uno de 2018 el problema es
además peor**, y por un motivo que conviene conocer porque cambia dónde aparece el fallo: las
versiones de `node-pre-gyp` y `prebuild-install` de la época son **anteriores a la detección de
libc**. No preguntan qué biblioteca C tiene el sistema, porque cuando se escribieron se daba
por supuesta.

La consecuencia es contraintuitiva. Lo que uno espera —"no hay prebuild para musl, pues
compilo"— es el comportamiento **moderno**. El de la herramienta vieja es otro: se descarga el
binario de glibc tan tranquila, **el `npm install` termina en verde**, y el fallo aparece más
tarde, en el primer `require()` del addon, con un mensaje que habla de `ld-linux` o de
`symbol not found` y que no menciona Alpine por ninguna parte. El problema no desaparece: se
muda a un sitio donde cuesta mucho más relacionarlo con su causa.

> ⚠️ **Y tampoco te libras de la arqueología, que suele ser el argumento con el que se defiende
> Alpine.** Para que el `node-gyp` de esa época funcione necesitas Python 2, y Alpine dejó de
> empaquetarlo después de la rama 3.12. Así que la Alpine que te serviría es una rama vieja y
> sin parches: exactamente la situación de Buster que [F01](01-decisiones-debian-zonas-node.md) §4.4 asume a cara
> descubierta, pero con menos paquetes disponibles y sin un archivo histórico equivalente al de
> Debian. Cambias un problema conocido por el mismo problema en terreno peor documentado.

Por completar el mapa, porque es la pregunta que sigue: **sí existen binarios de Node para
`musl`**, en las *unofficial builds* del propio proyecto y para varias de las ramas. Son eso,
no oficiales, y el proyecto los marca como tales. Que existan no cambia nada de lo anterior,
porque el problema nunca fue Node: son los addons de tus dependencias.

### 6.1 La versión de glibc también cuenta

No basta con que sea `glibc`: importa **qué versión**. Un binario compilado contra `glibc`
2.35 puede exigir símbolos que la 2.28 de Debian 10 no tiene:

```text
/lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.29' not found
```

Es el error que da Node 18 sobre Buster, y el que verás si intentas usar un prebuild moderno
en nuestro laboratorio. La dirección importa: **hacia atrás no funciona, hacia adelante
normalmente sí**. Un binario para `glibc` 2.28 funciona sobre 2.35; al revés no.

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase09 \
  bash -c 'ldd --version | head -1'
```
```text
ldd (Debian GLIBC 2.28-10+deb10u4) 2.28
```

Anota ese `2.28`: es el techo de compatibilidad de todo lo que metas en esta imagen. El
`+deb10u4` es el número de revisión del paquete de Debian —el cuarto parche de seguridad que
Buster llegó a publicar para su glibc— y **no cambia el ABI**: sigue siendo la 2.28. Si tu
salida trae otro sufijo, no te preocupes; el número que importa es el de después del guion.

---

## 7. 📥 Prebuilds: el atajo que envejece mal

Los prebuilds existen por una razón sensata: compilar `canvas` tarda minutos y requiere un
toolchain que la mayoría de los usuarios no tiene. Publicar binarios ya compilados hace que
`npm install` sea rápido y silencioso para casi todo el mundo.

**El nombre del archivo cuenta la historia entera:**

```text
bcrypt_lib-v3.0.6-node-v64-linux-x64-glibc.tar.gz
│          │      │        │     │   │
│          │      │        │     │   └── la libc
│          │      │        │     └────── arquitectura
│          │      │        └──────────── plataforma
│          │      └───────────────────── ABI de Node: 64 = Node 10
│          └──────────────────────────── versión del paquete
└─────────────────────────────────────── el addon
```

Cinco coordenadas. Si **una** no coincide con tu entorno, no hay prebuild y toca compilar.

**Los dos sistemas que los gestionan**, y vas a ver los dos en proyectos de la época:

- **`node-pre-gyp`** — el veterano. Descarga desde una URL configurada en el `package.json`,
  que muy a menudo apunta a un bucket S3 de quien mantiene el paquete.
- **`prebuild` + `prebuild-install`** — el sucesor. Descarga desde los *releases* de GitHub,
  que es una URL algo más duradera.

### 7.1 El problema estructural

> ⚠️ **Un prebuilt NO es parte del paquete npm.** Lo que `npm install` descarga del registry
> es el código y un script de instalación. Ese script, después, va a **otro sitio** a por el
> binario. Son dos descargas de dos infraestructuras distintas.

Y de ahí la frase que hay que llevarse de esta sección:

> 🧠 **El lockfile no puede congelar Internet.** Tu `package-lock.json` fija qué versión de
> `bcrypt` instalar y el hash de su tarball del registry. **No fija** de dónde saldrá el
> binario, ni garantiza que ese servidor siga vivo, ni que siga sirviendo el mismo archivo.
> Es el agujero de reproducibilidad más grande que tiene un proyecto Node de 2018, y no es
> culpa de npm.

Cuando el prebuild falla —404, servidor muerto, arquitectura ausente—, el paquete cae al plan
B: compilar. Y ahí es donde tu imagen necesita el toolchain de **[F04](04-toolchain-de-compilacion.md)** y el Python de **[F05](05-python-y-node-gyp.md)**.
Por eso están.

### 7.2 Los cuatro cachés donde termina cada cosa

Cuando algo "ya estaba instalado" y aun así falla, suele ser porque hay un caché de por medio.
Estos son los cuatro:

| Caché | Dónde | Qué guarda |
|---|---|---|
| **npm** | `~/.npm/_cacache` | tarballs del registry y metadatos |
| **node-gyp** | `~/.cache/node-gyp/<version>` | las cabeceras de Node para compilar |
| **prebuilds** | varía por herramienta | los binarios descargados |
| **Puppeteer y similares** | `~/.cache/puppeteer` o dentro del paquete | el navegador descargado |

> 🩺 **Por qué importa saberlo.** Un `npm ci` que "no vuelve a intentarlo" casi siempre está
> leyendo de uno de estos cuatro. Y si tu contenedor no monta `$HOME` en ningún sitio
> persistente, esos cachés mueren con él — lo que a veces es lo que quieres y a veces explica
> por qué cada build tarda lo mismo.

---

## 8. 🔬 Las cuatro herramientas de disección

Cuando un binario no carga, estas cuatro responden qué le pasa. Son de [F04](04-toolchain-de-compilacion.md) y aquí se usan en
serio.

**`file` — ¿qué es esto realmente?**

```bash
file node_modules/bcrypt/lib/binding/bcrypt_lib.node
```
```text
ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, not stripped
```

Te da arquitectura y tipo en una línea. Si dice `ARM aarch64` y estás en amd64, ahí acabó el
diagnóstico. Si dice `HTML document`, la descarga falló y guardó una página de error.

**`ldd` — ¿qué librerías necesita y cuáles faltan?**

```bash
ldd node_modules/canvas/build/Release/canvas.node | grep 'not found'
```

Cada línea es un paquete `-dev` que falta. Es el comando que resuelve la mitad de los fallos
de `canvas` y de Puppeteer.

**`readelf` — ¿contra qué versión de glibc se compiló?**

```bash
readelf -V node_modules/bcrypt/lib/binding/bcrypt_lib.node | grep GLIBC | sort -u
```

Te dice qué símbolos versionados exige. Si aparece `GLIBC_2.29` y tu imagen tiene 2.28, ya
tienes la causa del `version not found`.

**`nm` — ¿qué símbolos exporta o le faltan?**

```bash
nm -D --undefined-only node_modules/.../addon.node | head
```

El más fino de los cuatro, y el que menos vas a necesitar. Está en **[a03](a03-binutils-y-elf.md)** con su contexto.

> 🩺 **El orden de diagnóstico:** `file` primero —arquitectura y tipo—, `ldd` después
> —dependencias que faltan—, `readelf` si sospechas de glibc, y `nm` solo si los tres
> anteriores no explicaron nada. En ese orden resuelves nueve de cada diez casos con los dos
> primeros.

---

## 9. 📋 Decisiones cerradas que esta fase justifica

Tres cosas que el curso decidió antes de poder explicarlas, y que ahora quedan cerradas:

**El volumen lleva la versión de Node en el nombre** porque el ABI cambia entre generaciones
(§5.1). No es organización: es corrección.

**La base es Debian con `glibc`, no Alpine con `musl`** porque los prebuilds de la época
asumen `glibc` (§6). No es preferencia: es dónde existen los binarios.

**El toolchain de compilación va en la imagen aunque "casi nunca haga falta"** porque el plan
B de todo caso C es compilar, y el plan B se activa precisamente cuando estás desenterrando
algo viejo (§7.1). No es exceso: es el seguro que hace que el resto funcione.

---

## 10. ⚠️ Errores comunes y diagnóstico

**`NODE_MODULE_VERSION 64 ... requires 83`.** Reutilizaste un `node_modules` de otra
generación. Borra el volumen y reinstala con la versión correcta. §5.1.

**`invalid ELF header`.** Lo que hay ahí no es un binario válido para tu plataforma, o no es
un binario en absoluto. `file` en un segundo.

**`GLIBC_2.29 not found`.** El binario exige una glibc más nueva que la 2.28 de Buster. O
compilas desde source, o buscas un prebuild de la época. §6.1.

**`cannot open shared object file`.** Falta un paquete del sistema. `ldd | grep 'not found'`
te lo dice. §8.

**`node-pre-gyp ERR! install response status 404`.** El prebuild no existe para tu
combinación, o el servidor cambió. Fuerza la compilación con `--build-from-source`.

**"Funciona en mi máquina y no en el contenedor."** Compara las cinco coordenadas de §7:
plataforma, arquitectura, ABI de Node, libc y versión del paquete. Una de las cinco difiere.

**"Instalé y sigue fallando igual."** Alguno de los cuatro cachés de §7.2. Bórralo
explícitamente, no con un `prune` general.

---

## 11. 📋 Checklist de validación

```text
[ ] Puedes clasificar una dependencia en el caso A, B, C o D
[ ] Explicas la diferencia entre API y ABI sin usar la palabra "compatible"
[ ] Sabes los cuatro NODE_MODULE_VERSION del baseline, y los comprobaste
[ ] Reconoces el error de ABI y sabes qué lo causó exactamente
[ ] Sabes qué glibc trae tu imagen y por qué es un techo
[ ] Puedes leer el nombre de un prebuild y decir sus cinco coordenadas
[ ] Sabes por qué el lockfile no cubre los prebuilds
[ ] Localizas los cuatro cachés y sabes borrar uno sin borrar los demás
[ ] Diseccionaste un .node real con file, ldd y readelf
```

---

## 12. 🧪 Ejercicios de la Fase 14 (25)

## 🟢 Fácil — el contrato binario (1–7)

### 🟢 Ejercicio 1 — Los cuatro ABI

Ejecuta el bucle de §5.1 y anota los cuatro números.

**Objetivo:** tener la tabla comprobada, no leída.

### 🟢 Ejercicio 2 — Clasifica diez dependencias

Toma el `package-lock.json` de tu proyecto y clasifica diez dependencias en los casos A, B, C
o D de §4.

**Pregunta:** ¿cuántas son caso A? Suele ser la enorme mayoría, y eso ya te dice cuánto riesgo
real tienes.

### 🟢 Ejercicio 3 — Disecciona un `.node`

Instala `bcrypt` en el toolchain y pásale `file`, `ldd` y `readelf -V` a su `.node`.

**Objetivo:** ver las tres salidas sobre un binario real y saber qué te dice cada una.

### 🟢 Ejercicio 4 — La glibc de tu imagen

Ejecuta `ldd --version` dentro del contenedor y busca qué glibc trae Debian 11 y 12.

**Pregunta:** ¿qué ganarías y qué perderías subiendo de base? Relaciónalo con [F01](01-decisiones-debian-zonas-node.md) §4.2.

### 🟢 Ejercicio 5 — Lee un nombre de prebuild

Busca en los releases de GitHub de `bcrypt` o `sqlite3` los artefactos de una versión de 2019.

**Objetivo:** identificar las cinco coordenadas de §7 en nombres reales, y ver para cuántas
combinaciones publicaron.

### 🟢 Ejercicio 6 — Encuentra los cachés

Dentro del contenedor, localiza los cuatro directorios de §7.2 después de un `npm ci`.

**Pregunta:** ¿cuáles existen? ¿Qué pasa con ellos al borrar el contenedor?

### 🟢 Ejercicio 7 — Un `.node` es una librería

Compara `file` sobre un `.node` y sobre un `.so` cualquiera del sistema.

**Objetivo:** confirmar que son el mismo tipo de archivo, y que la extensión es convención.

## 🟡 Intermedio — provocarlo y arreglarlo (8–13)

### 🟡 Ejercicio 8 — Provoca el error de ABI

Instala una dependencia nativa con Node 10, y después ejecuta la aplicación con Node 14
**reutilizando el mismo volumen**.

**Objetivo:** obtener el mensaje de `NODE_MODULE_VERSION` completo y guardarlo. Es el error más
característico de esta fase.

### 🟡 Ejercicio 9 — Arréglalo de dos formas

Sobre el fallo del ejercicio 8, arréglalo primero borrando el volumen y reinstalando, y después
con `npm rebuild`.

**Pregunta:** ¿funcionan los dos? ¿Cuál es más rápido y cuál más fiable? ¿Cuál usarías en CI?

### 🟡 Ejercicio 10 — Sin toolchain

Construye una imagen con Node pero **sin** `build-essential` ni Python, e intenta instalar una
dependencia caso C forzando la compilación.

**Objetivo:** ver el fallo y confirmar por qué el toolchain está en la imagen (§9).

### 🟡 Ejercicio 11 — Alpine y musl

Intenta ejecutar el mismo `.node` compilado en Debian dentro de un contenedor Alpine.

**Objetivo:** obtener el error de `ld-linux` y comprobar de primera mano el argumento de §6.

### 🟡 Ejercicio 12 — `readelf` contra glibc

Descarga un prebuild moderno de cualquier addon y pásale `readelf -V | grep GLIBC`.

**Pregunta:** ¿exige algún símbolo posterior a 2.28? Si sí, ya sabes que no funcionaría en
nuestra imagen — y lo sabes **antes** de instalarlo.

### 🟡 Ejercicio 13 — N-API: el addon que no se rompe

§5 dice que un `.node` compilado para Node 10 no carga en Node 12, y es verdad… **salvo si el
addon se compiló contra N-API**, que es una capa de ABI estable pensada exactamente para
evitar esta fase. Compruébalo. Instala un addon N-API moderno con Node 10 y después ejecútalo
con las otras tres generaciones **sin reinstalar nada**:

```bash
npm install sqlite3@5.1.6      # sqlite3 5.x usa N-API
node -e 'require("sqlite3"); console.log("carga en", process.version)'
```

**Pregunta:** ¿cargó en las cuatro? Ahora repite con un addon que **no** use N-API y compara.
Y la parte de criterio: si N-API resuelve el problema, **¿por qué este curso existe?** La
respuesta tiene fecha: mira cuándo se estabilizó N-API y compárala con la fecha de las
dependencias de tu proyecto de 2018.

## 🟠 Difícil — diseccionar el binario (14–20)

### 🟠 Ejercicio 14 — Fuerza la compilación

Instala una dependencia con `--build-from-source` y compara el tiempo con la instalación normal.

**Pregunta:** ¿cuánto tarda cada una? ¿Qué apareció en el log que antes no estaba?

### 🟠 Ejercicio 15 — El caché que miente

Instala una dependencia, borra `node_modules` pero **no** el caché de npm, y reinstala
cronometrando.

**Pregunta:** ¿de dónde salió tan rápido? ¿Qué comando lo habría evitado?

### 🟠 Ejercicio 16 — Diagnostica cuatro binarios

Prepara cuatro `.node` rotos de formas distintas: uno de otra arquitectura, uno de otro ABI,
uno al que le falte una librería del sistema, y uno que en realidad sea un HTML de error.

**Objetivo:** diagnosticar los cuatro usando solo `file`, `ldd` y `readelf`, y decir en cada
caso cuál de los tres dio la respuesta.

### 🟠 Ejercicio 17 — El prebuild que ya no está

Busca un paquete de 2018 cuyo `package.json` apunte a un bucket S3 para sus prebuilds y
comprueba si esa URL sigue viva.

**Pregunta:** ¿responde? Si no, ¿qué le pasaría hoy a un `npm ci` de ese proyecto? Es §7.1 en
un caso real.

### 🟠 Ejercicio 18 — La matriz de ABI de tu proyecto

Instala tu proyecto real con las cuatro generaciones de Node, cada una en su volumen, y
construye la matriz de qué funciona y qué no.

**Objetivo:** producir la evidencia que **[F20](20-validacion-sistematica-y-evidencia.md)** te va a pedir formalmente, y descubrir en qué
generaciones tu proyecto es viable de verdad.

### 🟠 Ejercicio 19 — Los símbolos que tu `.node` exige

`ldd` te dice qué **librerías** hacen falta. No te dice qué **versión** de esas librerías, que
es lo que de verdad rompe. Para eso hay que bajar a los símbolos:

```bash
readelf --dyn-syms node_modules/<addon>/build/Release/<addon>.node \
  | grep -o 'GLIBC_[0-9.]*' | sort -u
nm -D node_modules/<addon>/build/Release/<addon>.node | grep ' U ' | head -20
```

**Objetivo:** obtener la lista de versiones de `GLIBC_` que el binario exige y compararla con
la 2.28 de tu imagen. La versión más alta de esa lista es el suelo real de compatibilidad del
addon, y suele ser más baja de lo que la gente teme.

**Pregunta:** haz lo mismo con un prebuild **moderno** descargado de los releases de GitHub de
cualquier addon popular. ¿Qué `GLIBC_` pide? Si pide una superior a 2.28, acabas de predecir
—sin ejecutarlo— el error `version 'GLIBC_2.29' not found` de §6.1. Compruébalo ejecutándolo
y da la vuelta de honor.

### 🟠 Ejercicio 20 — El mismo addon, compilado cuatro veces

Compila **el mismo** addon con las cuatro generaciones, cada una en su volumen limpio, y
guarda los cuatro `.node` fuera del contenedor. Después compáralos entre sí:

```bash
ls -l *.node                       # tamaños
md5sum *.node                      # ¿alguno coincide?
for f in *.node; do printf '%-18s ' "$f"; readelf -p .comment "$f" | head -3 | tail -1; done
```

**Antes de mirar, predice:** ¿serán los cuatro del mismo tamaño? ¿Alguno tendrá el mismo
hash?

**Pregunta:** los cuatro salen del mismo código fuente y del mismo compilador. Explica **cada**
diferencia que encuentres nombrando su causa: las cabeceras de `/opt/node/<v>/include/node/`
que viste en [F06](06-instalacion-node.md) §6, el `NODE_MODULE_VERSION` incrustado, y los flags
que `node-gyp` deriva de la versión. **Objetivo:** que "hay que recompilar por versión" deje de
ser una regla que obedeces y pase a ser algo que puedes demostrar con `readelf`.

## 🔴 Muy difícil — riesgo y presupuesto (21–25)

### 🔴 Ejercicio 21 — Predice sin instalar

Dado un `package-lock.json` que no conoces, **predice** qué dependencias van a necesitar
compilación, sin ejecutar `npm ci`.

**Objetivo:** llegar a un método —buscar `binding.gyp`, `install` scripts, `node-pre-gyp` en el
árbol— y después comprobar cuánto acertaste.

### 🔴 Ejercicio 22 — Explica el diseño con el mecanismo

Sin releer §9, escribe la justificación mecánica de las tres decisiones del curso: el volumen
por versión, Debian en vez de Alpine, y el toolchain siempre presente.

**Objetivo:** que cada una mencione ABI, libc o prebuilds. Si puedes explicarlas sin esas tres
palabras, todavía estás repitiendo la receta.

### 🔴 Ejercicio 23 — El informe de riesgo binario

Para tu proyecto legacy real, produce un informe de una página que responda: **¿qué
dependencias binarias tiene, de qué infraestructura externa dependen, y qué pasaría si esa
infraestructura desapareciera mañana?**

**Objetivo:** una lista con nombre, caso (A/B/C/D), origen del binario y un plan de mitigación
por cada riesgo alto. Es material directo para el `VALIDATION-REPORT.md` de [F11](11-validar-tu-proyecto.md) y para el
proyecto final de **[F34](34-proyecto-final.md)**.

### 🔴 Ejercicio 24 — El `node_modules` que llegó en un tarball

Un compañero te pasa un `node_modules.tar.gz` de 400 MB con un "a mí me funciona, ahórrate el
`npm ci`". No sabes con qué Node lo instaló, ni en qué sistema, ni cuándo.

**Objetivo:** decidir si es utilizable **antes** de intentar usarlo, con evidencia y sin
ejecutar la aplicación. Tienes todas las herramientas de §8: localiza los `.node` dentro del
tarball, pásales `file` para la arquitectura, `readelf` para el `NODE_MODULE_VERSION` y para
los símbolos de glibc, y busca los `.bin` que puedan ser binarios descargados en lugar de
addons —el caso D de §4.4—.

Produce un veredicto con tres apartados: **funciona / no funciona / no se puede saber**, cada
uno con las rutas concretas que lo sustentan.

**Pregunta de cierre:** aunque el veredicto sea "funciona", ¿lo usarías? Da la respuesta
pensando en lo que este `node_modules` **no** trae: la garantía de que corresponde al
`package-lock.json` de tu repositorio. Explica cómo comprobarías eso, y por qué es un problema
distinto del ABI.

### 🔴 Ejercicio 25 — El presupuesto de cambiar de generación

Tu jefe pregunta: *"¿cuánto costaría pasar este proyecto de Node 10 a Node 14?"*. La respuesta
"depende" no vale. Constrúyela con esta fase.

**Objetivo:** para tu proyecto real, producir un presupuesto en tres columnas. **Dependencias
que no se enteran** (caso A de §4.1, JavaScript puro): cuéntalas. **Dependencias que hay que
recompilar** (casos B y C): cuéntalas, y para cada una di si existe prebuild para el nuevo
`NODE_MODULE_VERSION` o si habrá que compilar — con `npm view <paquete> versions` y los
releases de su repositorio como fuente. **Dependencias que se rompen de verdad**: las que ya
no tienen versión compatible, y qué habría que sustituir.

Termina con dos números: **cuántas horas** de trabajo estimas y **qué riesgo** queda sin
cubrir.

**Pregunta de cierre:** ahora repite el ejercicio para saltar a Node 16, y explica por qué el
salto 14→16 puede salir más caro que el 10→14 aunque sea "una generación menos". La respuesta
no está en el ABI: está en [F06](06-instalacion-node.md) §4, y es el npm.

## 🔥 Opcionales

### 🔥 Ejercicio 26 — Compila un addon a mano

Escribe un addon de Node mínimo —una función que sume dos números— con su `binding.gyp`, y
compílalo con `node-gyp` para las cuatro generaciones.

**Objetivo:** obtener cuatro `.node` y comprobar con `readelf` que son distintos. Es la
demostración definitiva de §5.

### 🔥 Ejercicio 27 — Vendoriza un prebuild

Descarga el prebuild de una dependencia, guárdalo en tu repositorio, y configura la instalación
para que lo use en lugar de descargarlo.

**Pregunta:** ¿qué ganaste en reproducibilidad y qué costo asumiste? Es la mitigación real del
riesgo de §7.1, y su versión completa está en **[a13](a13-air-gapped.md)**.

## 💀 Boss fight

### 💀 Ejercicio 28 — Boss fight: el `.node` que carga en una imagen y no en la otra

Te entregan un `node_modules` ya instalado, con un addon compilado dentro, y dos imágenes: la
del curso sobre Debian 10 y una sobre Alpine. El addon carga en una y en la otra lanza
`Error relocating ... symbol not found`. En una tercera prueba, sobre la imagen del curso pero
con otra versión de Node activa, el mensaje cambia a `NODE_MODULE_VERSION 64 ... requires 83`.

**Objetivo:** demostrar que son **dos incompatibilidades distintas** y que sabes distinguirlas
sin adivinar. Tienes que: (1) reproducir los dos errores y clasificarlos, uno como problema de
**libc** (§6) y otro de **ABI de Node** (§5); (2) diseccionar el `.node` con las cuatro
herramientas de §8 —`file`, `ldd`, `readelf -d` y `nm -D`— y señalar en la salida el dato
exacto que delata cada incompatibilidad; (3) decir qué `NODE_MODULE_VERSION` corresponde a
cada rama del laboratorio y comprobarlo con `node -p "process.versions.modules"`; (4) arreglar
los dos casos y explicar por qué uno se arregla recompilando y el otro **no** se arregla así;
(5) revisar si ese paquete publica prebuilds y, con §7, decir de qué cinco coordenadas depende
que te sirva alguno.

**Pregunta:** un compañero propone commitear `node_modules` al repositorio "para que no haya
que compilar nunca más". Con lo de esta fase, ¿en qué momento exacto le explota, y qué error
verá?

---

## 13. 📚 Referencias

**ABI de Node**
- Tabla de `NODE_MODULE_VERSION`: https://nodejs.org/en/download/releases/
- `process.versions`: https://nodejs.org/docs/latest-v10.x/api/process.html#process_process_versions
- N-API, la alternativa que resuelve esto y que tus dependencias de 2018 no usan: https://nodejs.org/api/n-api.html

**Prebuilds**
- `node-pre-gyp`: https://github.com/mapbox/node-pre-gyp
- `prebuild-install`: https://github.com/prebuild/prebuild-install
- `node-gyp`: https://github.com/nodejs/node-gyp

**libc y binarios**
- glibc, versiones y compatibilidad: https://sourceware.org/glibc/wiki/Release
- musl frente a glibc: https://wiki.musl-libc.org/functional-differences-from-glibc.html
- `ldd(1)`: https://manpages.debian.org/buster/manpages/ldd.1.en.html
- `readelf(1)`: https://manpages.debian.org/buster/binutils-common/readelf.1.en.html

> ⚠️ **N-API merece una nota.** Existe precisamente para que un addon compilado sobreviva a
> los cambios de versión de Node, y funciona. Tus dependencias de 2018 en su mayoría **no lo
> usan**, así que saberlo no te salva hoy — pero explica por qué este problema es mucho menor
> en un proyecto moderno.

**Orden de lectura sugerido:** la tabla de releases de Node primero, que es donde vive el
`NODE_MODULE_VERSION` de cada versión; el resto cuando un diagnóstico concreto lo pida.

---

## 14. 🏁 Resultado de la fase

```text
CUATRO CASOS   A · JavaScript puro          portable
               B · addon que compilas       atado a arch + libc + ABI
               C · addon precompilado       depende de infraestructura externa
               D · programa descargado      otra familia entera (a09)

EL CONTRATO    NODE_MODULE_VERSION   10→64  12→72  14→83  16→93
               glibc de la imagen    2.28 — es tu techo
               cinco coordenadas de un prebuild: paquete · ABI · SO · arch · libc

SABES          por qué el volumen lleva la versión de Node en el nombre
               por qué la base es Debian y no Alpine
               por qué el toolchain está en la imagen aunque "casi nunca haga falta"
               que el lockfile no puede congelar Internet
               diseccionar un binario con file, ldd, readelf y nm
```

> **La señal de que quedó bien:** *"ante un fallo de dependencia nativa, lo primero que hago
> no es buscar el error en Internet: es `file` sobre el binario y comparar las cinco
> coordenadas."*

En **[F15](15-laboratorios-dependencias-nativas.md)** aplicamos todo esto a los cuatro dragones clásicos: `node-sass`, `canvas`,
`sqlite3` y Puppeteer, con su autopsia completa y la política de reparación que no destruye la
evidencia.
