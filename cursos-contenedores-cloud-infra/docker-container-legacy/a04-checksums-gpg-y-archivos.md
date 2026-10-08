# 🔐 Apéndice a04 — Checksums, GPG y máquinas del tiempo

> **Curso:** Docker Legacy Node · **Apéndice opcional**
> **Cierra los bucles de:** [F06](06-instalacion-node.md) §8.1 · [F35](35-referencias.md) §5
> **Requisitos:** F06 (instalación de Node) y [F03](03-apt-y-utilidades.md) (firmas de APT)
> **Qué encontrarás:** qué demuestra un checksum y qué no, cómo se verifica una firma GPG de verdad, y las cinco máquinas del tiempo que hacen posible desenterrar software que el presente ya olvidó

[F06](06-instalacion-node.md) verifica los tarballs de Node con SHA-256 dentro del build y sigue adelante. Este apéndice
explica **qué garantiza exactamente esa verificación**, cómo se sube un nivel con GPG, y dónde
buscar cuando la fuente original ya no existe.

---

## 🧭 Índice de salto rápido

| Si tu pregunta es… | Ve a |
|---|---|
| "¿Qué demuestra un checksum?" | [§1](#1--checksum-la-huella-del-contenido) |
| "¿Cómo verifico una firma de Node?" | [§2](#2--gpg-la-firma-que-dice-quién) |
| "La URL que necesito ya no existe" | [§3](#3-️-las-cinco-máquinas-del-tiempo) |
| "¿Cuánta verificación necesito?" | [§4](#4-️-niveles-de-confianza) |

---

## 1. 🔢 Checksum: la huella del contenido

Un **checksum** es un valor calculado a partir del contenido de un archivo. Cambia un solo bit y
el resultado cambia entero.

**SHA-256** produce 256 bits, que se escriben como 64 caracteres hexadecimales:

```bash
echo "hola" > hola.txt
sha256sum hola.txt
sha256sum <(echo "holb")     # cambia una letra
```

Los dos valores no se parecen en nada. Esa es la propiedad que lo hace útil.

### 1.1 Verificar contra un valor esperado

```bash
sha256sum -c checksums.txt
```
```text
node-v10.24.1-linux-x64.tar.xz: OK
```

El formato que espera es el que produce `sha256sum`: hash, dos espacios, nombre de archivo. Es
exactamente lo que hace [F06](06-instalacion-node.md):

```bash
grep " ${archive}$" "SHASUMS256-${version}.txt" | sha256sum -c -
```

**El `grep` extrae la línea del artefacto concreto** —el archivo trae los hashes de todos— y el
`-` final le dice a `sha256sum` que lea de la entrada estándar.

> ⚠️ **Y por qué `pipefail` importa aquí**, como avisó [F06](06-instalacion-node.md) §8.1: si el `grep` no encuentra nada,
> `sha256sum -c -` recibe una entrada vacía, no verifica nada, **y puede devolver cero**. Sin
> `set -o pipefail`, tu verificación es teatro.

### 1.2 Qué demuestra, y qué no

> 🧭 **Demuestra:** que el archivo que tienes es **byte a byte** el mismo que produjo ese hash.
> Cubre corrupción de red, descarga a medias, y sustitución del archivo.
>
> **No demuestra:** que ese hash sea el correcto. Si descargaste el `SHASUMS256.txt` del mismo
> sitio que el tarball, y ese sitio estuviera comprometido, **los dos serían falsos y
> coincidirían**.

Ahí es donde entra GPG.

---

## 2. 🔏 GPG: la firma que dice quién

Node publica, junto a cada release, tres archivos:

```text
SHASUMS256.txt        los hashes
SHASUMS256.txt.asc    la firma, en formato ASCII
SHASUMS256.txt.sig    la firma, binaria
```

**La cadena de confianza completa:**

```mermaid
flowchart TD
    A["una clave pública de Node en la que confías"] --> B["verificas la firma de SHASUMS256.txt"]
    B --> C["ahora sabes que los hashes son auténticos"] --> D["verificas el tarball contra su hash"]
    D --> E["sabes que el tarball es el que Node publicó"]
```

**El eslabón que hay que resolver aparte** es el primero: cómo consigues la clave de forma
fiable. Node las publica en su repositorio de *release keys*, y ahí es donde termina la
verificación automática y empieza la confianza.

### 2.1 El flujo, en comandos

```bash
# 1. importar las claves de release de Node
curl -sL https://raw.githubusercontent.com/nodejs/release-keys/main/keys.list \
  | while read -r key; do gpg --keyserver hkps://keys.openpgp.org --recv-keys "$key"; done

# 2. bajar los tres archivos
V=10.24.1
curl -fsSLO "https://nodejs.org/dist/v$V/SHASUMS256.txt"
curl -fsSLO "https://nodejs.org/dist/v$V/SHASUMS256.txt.asc"
curl -fsSLO "https://nodejs.org/dist/v$V/node-v$V-linux-x64.tar.xz"

# 3. verificar la FIRMA de los hashes
gpg --verify SHASUMS256.txt.asc SHASUMS256.txt

# 4. y ahora sí, el tarball contra su hash
grep " node-v$V-linux-x64.tar.xz$" SHASUMS256.txt | sha256sum -c -
```

**Lo que verás en el paso 3**, y hay que saber leerlo:

```text
gpg: Good signature from "Beth Griggs <...>"        ← ✅ la firma es válida
gpg: WARNING: This key is not certified with a trusted signature.   ← ⚠️ no la has firmado tú
```

> 🧭 **Ese `WARNING` no significa que la firma sea mala.** Significa que GPG no puede decidir por
> ti si esa clave pertenece a quien dice. La firma es criptográficamente correcta; **la
> identidad la decides tú** al confiar en la lista de claves de Node.
>
> Es la misma distinción de [F29](29-supply-chain-sbom-firma.md) §7.1: origen e integridad, no calidad ni identidad verificada por
> arte de magia.

### 2.2 Por qué el curso deja GPG como opcional

El baseline de [F06](06-instalacion-node.md) implementa **HTTPS + SHA-256**, y documenta GPG como endurecimiento
adicional. La razón es de alcance: hacerlo obligatorio convertiría esa fase en un curso de PKI,
keyrings, web of trust y rotación de claves.

**Cuándo sí vale la pena:** una imagen que publicas formalmente, un entorno donde la cadena de
suministro importa, o un pipeline que otros consumen. Para un laboratorio local, HTTPS más
checksum es una relación coste/beneficio razonable — **y decirlo es más honesto que fingir que
GPG es gratis**.

### 2.3 Y el eco de [F03](03-apt-y-utilidades.md)

Esto es exactamente lo mismo que hace APT, y ya lo viste: descarga un `Release` firmado, verifica
la firma contra las claves de `/etc/apt/trusted.gpg.d/`, y a partir de ahí confía en los hashes
que contiene. **La misma arquitectura, dos ecosistemas.** Si entendiste [F03](03-apt-y-utilidades.md) §5.1, ya entiendes
esto.

---

## 3. 🕰️ Las cinco máquinas del tiempo

El problema central del legacy: **la fuente original puede haber desaparecido**. Estas cinco son
las que lo resuelven, ordenadas por fiabilidad.

### 3.1 `archive.debian.org` — el archivo de Debian

Las releases fuera de soporte se trasladan aquí. Es la fuente de [F01](01-decisiones-debian-zonas-node.md) §4.4 y lo que hace que el
laboratorio funcione.

```bash
curl -sI http://archive.debian.org/debian/dists/buster/Release | head -1
```

### 3.2 `snapshot.debian.org` — Debian en una fecha concreta

Va un paso más allá: te deja apuntar al repositorio **tal como estaba un día concreto**.

```text
deb http://snapshot.debian.org/archive/debian/20190706T000000Z/ buster main
```

**Es la herramienta definitiva de reproducibilidad de Debian**, y tiene dos costes: es lento, y
sus `Release` sí traen `Valid-Until` de la época — que es donde las dos configuraciones de [F03](03-apt-y-utilidades.md)
§5.4 pasan de decorativas a imprescindibles.

### 3.3 `nodejs.org/dist` — el archivo de Node

Todas las versiones desde la 0.x, con sus artefactos, sus `SHASUMS256.txt` y sus firmas. Es la
fuente de [F06](06-instalacion-node.md) y de todo el argumento de [F00](00-problema-y-contrato.md) §3.1.

### 3.4 El registry de npm

Conserva todas las versiones publicadas, y con `--before` puedes resolver un árbol **como se
habría resuelto en una fecha**:

```bash
npm view node-sass versions --json | jq '.[-10:]'
npm view node-sass@4.14.1 dist.tarball
npm install --before 2019-06-01        # ← reconstruir un árbol de la época
```

> 🧭 **`--before` es la herramienta clave del nivel 🔴 de [F34](34-proyecto-final.md).** Un proyecto sin lockfile no se
> arregla generando uno hoy: se acota a lo que existía entonces.

### 3.5 Wayback Machine — cuando la documentación cambió

Para todo lo demás: una página de documentación que ya no dice lo que decía, un README que
cambió, un blog que desapareció.

```text
https://web.archive.org/web/2019*/https://ejemplo.com/docs
```

**Con sus limitaciones**, que hay que declarar al citar: puede faltar la captura de la fecha
exacta, los recursos —CSS, imágenes, JavaScript— a menudo no se conservan, y el sitio pudo pedir
no ser archivado.

### 3.6 La regla de oro al citar una máquina del tiempo

> 🧭 **Registra siempre tres datos:** la **URL original**, la **fecha de la captura o del
> snapshot**, y **qué limitación tiene esa fuente**. Sin los tres, tu evidencia no es
> verificable — y es lo que [F34](34-proyecto-final.md) evalúa.

---

## 4. 🎚️ Niveles de confianza

Cuánta verificación necesitas depende de qué estás haciendo. Los cuatro niveles, con su coste:

| Nivel | Qué haces | Cubre | Coste |
|---|---|---|---|
| **0** | descargar por HTTP | nada | — |
| **1** | descargar por **HTTPS** | interceptación en tránsito | gratis |
| **2** | HTTPS + **checksum** ← **el baseline del curso** | corrupción y sustitución del archivo | una línea |
| **3** | + **firma GPG** | autenticidad del origen | importar claves, entenderlas |
| **4** | + **vendorizar el artefacto** | que la fuente desaparezca | espacio y mantenimiento |

**El nivel 2 es el baseline y está justificado:** cubre lo que falla de verdad en la práctica
—descargas corrompidas, 404 guardados como tarball, artefactos cambiados— con un coste
despreciable.

**El nivel 4** es el que resuelve el problema que [F14](14-abi-libc-y-prebuilds.md) §7.1 dejó abierto: el lockfile no puede
congelar Internet, pero tú sí puedes guardar el artefacto. Su desarrollo está en **[a13](a13-air-gapped.md)**.

---

## 🧭 Guía rápida: cuándo usar qué

| Tu situación | Nivel |
|---|---|
| Laboratorio local, artefactos oficiales | **2**: HTTPS + checksum |
| Imagen que publicas o que otros consumen | **3**: añade GPG, y firma tú la imagen ([F29](29-supply-chain-sbom-firma.md)) |
| Pipeline que no puede fallar por una URL muerta | **4**: vendoriza, **[a13](a13-air-gapped.md)** |
| La URL original ya no responde | §3, empezando por la máquina del tiempo del ecosistema |
| Proyecto sin lockfile | `npm install --before <fecha>`, §3.4 |
| Citas una fuente histórica en un reporte | los tres datos de §3.6 |

---

## 🧪 Ejercicios (7)

### 🟢 Ejercicio 1 — Un bit cambia todo

Calcula el SHA-256 de un archivo, cámbiale un carácter y vuelve a calcularlo.

### 🟢 Ejercicio 2 — Verifica un tarball a mano

Descarga un tarball de Node con su `SHASUMS256.txt` y verifícalo con `sha256sum -c -`.

### 🟡 Ejercicio 3 — La verificación vacía

Cambia el `grep` para que no encuentre nada y ejecuta la tubería **sin** `pipefail`.

**Pregunta:** ¿qué código de salida devuelve? Ahí está el aviso de §1.1.

### 🟡 Ejercicio 4 — El flujo GPG completo

Ejecuta los cuatro pasos de §2.1.

**Pregunta:** ¿qué dice exactamente el `WARNING`? ¿Invalida la firma?

### 🟡 Ejercicio 5 — Un snapshot con fecha

Construye una imagen apuntando a un `snapshot.debian.org` de julio de 2019.

**Pregunta:** ¿funcionó `apt-get update`? Si no, ¿qué configuración de [F03](03-apt-y-utilidades.md) §5.2 lo salva?

### 🟠 Ejercicio 6 — `--before` en acción

Con un `package.json` sin lockfile, ejecuta `npm install --before 2019-06-01` y compara el árbol
con el que produce un `npm install` normal.

**Pregunta:** ¿cuántas versiones difieren? Es el ejercicio central del nivel 🔴 de [F34](34-proyecto-final.md).

### 🟠 Ejercicio 7 — Una ficha de evidencia histórica

Toma una referencia de documentación que haya cambiado y produce su ficha con los tres datos de
§3.6.

**Objetivo:** que otra persona pueda llegar a la misma captura sin buscar.

---

## 📚 Referencias

- Node — verificación de binarios: https://github.com/nodejs/node/blob/main/README.md#verifying-binaries
- Node — claves de release: https://github.com/nodejs/release-keys
- Utilidades SHA-2 de GNU Coreutils: https://www.gnu.org/software/coreutils/manual/html_node/sha2-utilities.html
- GnuPG: https://www.gnupg.org/documentation/
- Debian Archive: https://www.debian.org/distrib/archive
- Debian Snapshot: https://snapshot.debian.org
- npm `--before`: https://docs.npmjs.com/cli/v6/commands/npm-install
- Wayback Machine: https://web.archive.org

**Vuelve a:** [F06 §8.1](06-instalacion-node.md) · [F03 §5](03-apt-y-utilidades.md) · [F35](35-referencias.md) · sigue en [a13](a13-air-gapped.md)
