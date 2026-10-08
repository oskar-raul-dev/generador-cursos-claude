# 🔬 Apéndice a03 — GNU Binutils y anatomía de un ELF

> **Curso:** Docker Legacy Node · **Apéndice opcional**
> **Cierra los bucles de:** [F04](04-toolchain-de-compilacion.md) §5.2 · [F14](14-abi-libc-y-prebuilds.md) §8
> **Requisitos:** F04 (el toolchain) y F14 (ABI y binarios)
> **Qué encontrarás:** qué hay dentro de un binario de Linux y cuáles de las herramientas de Binutils te sirven de verdad para diagnosticar un módulo nativo

[F14](14-abi-libc-y-prebuilds.md) §8 te dio cuatro herramientas y el orden en que usarlas. Este apéndice explica **qué están
mirando** y añade las que quedaron fuera.

---

## 🧭 Índice de salto rápido

| Si tu pregunta es… | Ve a |
|---|---|
| "¿Qué es exactamente un ELF?" | [§1](#1--qué-es-un-elf) |
| "¿Cómo llega un `.c` a ser un ejecutable?" | [§2](#2-️-las-cuatro-etapas-y-qué-herramienta-actúa-en-cada-una) |
| "¿Qué me dice `readelf` que no me diga `file`?" | [§3](#3--las-herramientas-que-de-verdad-usarás) |
| "Un `.node` no carga y no sé por qué" | [§4](#4--el-recetario-de-diagnóstico) |

---

## 1. 🧱 Qué es un ELF

**ELF** —*Executable and Linkable Format*— es el formato de los binarios de Linux. Ejecutables,
librerías compartidas, objetos intermedios y volcados de memoria: todos son ELF.

```mermaid
flowchart TD
    subgraph ELF["un archivo ELF, de arriba abajo"]
        H["ELF header<br/>qué tipo es, para qué arquitectura, dónde empieza"]
        PH["Program headers<br/>cómo cargarlo en memoria — al ejecutar"]
        S[".text · el código máquina<br/>.rodata · constantes<br/>.data / .bss · variables<br/>.dynsym / .dynstr · símbolos dinámicos — quién llama a quién<br/>.dynamic · qué librerías necesita"]
        SH["Section headers<br/>cómo enlazarlo — al compilar"]
        H --- PH --- S --- SH
    end
```

**Y el dato que explica medio [F14](14-abi-libc-y-prebuilds.md):** el ELF header dice **para qué arquitectura** es el binario,
y `.dynamic` dice **contra qué librerías** enlazó. Esas dos son las que fallan cuando un módulo
nativo no carga.

**Los tres tipos que vas a ver:**

| | Qué es | Extensión típica |
|---|---|---|
| `EXEC` / `DYN` | un ejecutable | ninguna, o `.out` |
| `DYN` compartido | una librería | `.so` |
| `REL` | un objeto intermedio | `.o` |

> 🧠 **Un `.node` de Node es un `DYN` compartido**, con otra extensión. Es lo que [F05](05-python-y-node-gyp.md) §5 decía y
> aquí lo puedes verificar tú: `file` lo llama *"shared object"*.

---

## 2. 🏗️ Las cuatro etapas, y qué herramienta actúa en cada una

```mermaid
flowchart TD
    C["hello.c"] -- "cpp · preprocesador:<br/>resuelve #35;include y #35;define" --> I["hello.i"]
    I -- "cc1 · compilador: C → ensamblador" --> S["hello.s"]
    S -- "as · ENSAMBLADOR (Binutils)" --> O["hello.o<br/>objeto: código máquina con símbolos sin resolver"]
    O -- "ld · ENLAZADOR (Binutils)" --> E["hello<br/>ejecutable ELF"]
```

**`gcc` no compila: orquesta.** Llama a los cuatro y por eso parece uno solo. Compruébalo:

```bash
gcc -v hello.c -o hello 2>&1 | grep -E 'cc1|as |collect2|ld'
```

Y párate en cada etapa:

```bash
gcc -E hello.c -o hello.i    # solo preprocesar
gcc -S hello.c -o hello.s    # hasta ensamblador — legible
gcc -c hello.c -o hello.o    # hasta objeto
gcc hello.o -o hello         # solo enlazar
```

**`as` y `ld` son de Binutils**, y esa es la respuesta a por qué el paquete está en la imagen de
[F04](04-toolchain-de-compilacion.md) aunque nunca lo invoques directamente.

---

## 3. 🔧 Las herramientas que de verdad usarás

De la docena que trae Binutils, estas cinco resuelven el 95% de los casos.

### 3.1 `file` — la primera, siempre

```bash
file build/Release/binding.node
```
```text
ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked,
BuildID[sha1]=..., not stripped
```

**Arquitectura, tipo y si está stripped, en una línea.** Técnicamente no es de Binutils, y es la
que más veces resuelve el diagnóstico.

### 3.2 `ldd` — qué librerías necesita

```bash
ldd build/Release/canvas.node
ldd build/Release/canvas.node | grep 'not found'    # ← la línea útil
```

Muestra las librerías compartidas y **contra cuál resolvió cada una**. Si algo dice
`not found`, ahí está la causa.

> ⚠️ **`ldd` ejecuta código.** Sobre un binario en el que no confías, usa
> `objdump -p <bin> | grep NEEDED`, que solo lee.

### 3.3 `readelf` — el detalle

```bash
readelf -h <bin>                          # el header: arquitectura, tipo
readelf -d <bin> | grep NEEDED            # qué librerías, sin ejecutar nada
readelf -V <bin> | grep GLIBC | sort -u   # qué versiones de glibc exige
```

**La tercera es la que responde el `GLIBC_2.29 not found` de [F14](14-abi-libc-y-prebuilds.md) §6.1**, y lo hace **antes** de
intentar ejecutar el binario.

### 3.4 `nm` — los símbolos

```bash
nm -D <bin>                        # símbolos dinámicos
nm -D --undefined-only <bin>       # los que espera de fuera
nm -D --defined-only <bin>         # los que ofrece
```

Sirve cuando un módulo carga y falla con `undefined symbol`: te dice qué símbolo falta, y con
`--defined-only` sobre la librería sospechosa compruebas si lo tiene.

> ⚠️ **Si el binario está *stripped*, `nm` no encuentra casi nada.** Los prebuilds suelen venir
> stripped para pesar menos, y `file` te lo dice.

### 3.5 `objdump` — cuando lo demás no basta

```bash
objdump -p <bin> | grep NEEDED     # como ldd, pero sin ejecutar
objdump -h <bin>                   # las secciones y sus tamaños
objdump -d <bin> | head -40        # desensamblar
```

El desensamblado casi nunca hace falta en este curso. Las dos primeras sí.

### 3.6 Y las que existen y no vas a usar

`ar` empaqueta objetos en librerías estáticas `.a`; `strip` quita símbolos; `strings` extrae
texto legible —útil para buscar una URL o una versión dentro de un binario—; `size` da el tamaño
por sección.

---

## 4. 🩺 El recetario de diagnóstico

El orden de [F14](14-abi-libc-y-prebuilds.md) §8, con lo que responde cada paso:

```mermaid
flowchart TD
    S1{"1 · file #lt;bin#gt;<br/>¿es un ELF? ¿de qué arquitectura?"}
    S1 -- "no es ELF" --> R1["la descarga falló (F04 §10)"]
    S1 -- "otra arquitectura" --> R2["F21 §7"]
    S1 -- "ELF de tu arquitectura" --> S2{"2 · ldd #lt;bin#gt; #124; grep 'not found'<br/>¿le falta alguna librería?"}
    S2 -- "sí" --> R3["instala el paquete (sin -dev): F15 §5"]
    S2 -- "no" --> S3{"3 · readelf -V #lt;bin#gt; #124; grep GLIBC #124; sort -u<br/>¿exige una glibc más nueva que 2.28?"}
    S3 -- "sí" --> R4["F14 §6.1"]
    S3 -- "no" --> S4["4 · nm -D --undefined-only #lt;bin#gt;<br/>¿qué símbolo falta exactamente?<br/>búscalo con nm -D --defined-only en la librería sospechosa"]
```

**Los tres primeros resuelven casi todo.** El cuarto es para el caso raro en que el módulo carga
y falla después.

---

## 🧭 Guía rápida: cuándo usar qué

| Tu pregunta | Herramienta |
|---|---|
| ¿Qué es este archivo? | `file` |
| ¿Le falta una librería? | `ldd \| grep 'not found'` |
| ¿Qué librerías necesita, sin ejecutarlo? | `readelf -d` u `objdump -p` |
| ¿Qué glibc exige? | `readelf -V \| grep GLIBC` |
| ¿Qué símbolo le falta? | `nm -D --undefined-only` |
| ¿Está stripped? | `file` te lo dice |
| ¿Qué versión trae dentro? | `strings <bin> \| grep -i version` |
| ¿No confío en este binario? | `readelf` y `objdump`, nunca `ldd` |

---

## 🧪 Ejercicios (6)

### 🟢 Ejercicio 1 — Las cuatro etapas

Compila el `hello.c` de [F04](04-toolchain-de-compilacion.md) parándote en cada etapa de §2 y mira los cuatro archivos.

**Pregunta:** ¿cuál es legible? ¿Cuál pesa más?

### 🟢 Ejercicio 2 — El header de tres binarios

Ejecuta `readelf -h` sobre `/bin/ls`, un `.so` del sistema y un `.o` tuyo.

**Objetivo:** ver los tres tipos de §1.

### 🟡 Ejercicio 3 — `ldd` contra `readelf -d`

Compara las dos salidas sobre el mismo binario.

**Pregunta:** ¿qué da `ldd` que no da `readelf`? ¿Por qué eso implica que ejecuta algo?

### 🟡 Ejercicio 4 — La glibc de un prebuild

Descarga un prebuild moderno de un addon y ejecuta `readelf -V | grep GLIBC`.

**Objetivo:** saber si funcionaría en Buster **antes** de instalarlo.

### 🟠 Ejercicio 5 — El símbolo que falta

Provoca un `undefined symbol` compilando contra una versión de librería y ejecutando con otra.

**Objetivo:** encontrar el símbolo con `nm -D --undefined-only` y confirmar su ausencia en la
librería.

### 🟠 Ejercicio 6 — Disecciona un `.node` real

Toma el `canvas.node` de [F15](15-laboratorios-dependencias-nativas.md) y pásale las cinco herramientas.

**Objetivo:** una ficha completa —arquitectura, librerías, glibc, símbolos, stripped o no— y la
conclusión de en qué sistemas funcionaría.

---

## 📚 Referencias

- GNU Binutils: https://sourceware.org/binutils/docs/
- `readelf(1)`: https://manpages.debian.org/buster/binutils-common/readelf.1.en.html
- `nm(1)`: https://manpages.debian.org/buster/binutils-common/nm.1.en.html
- `objdump(1)`: https://manpages.debian.org/buster/binutils-common/objdump.1.en.html
- `ld.so(8)`, el enlazador dinámico: https://manpages.debian.org/buster/manpages/ld.so.8.en.html
- La especificación ELF: https://refspecs.linuxfoundation.org/elf/elf.pdf

**Vuelve a:** [F04 §5.2](04-toolchain-de-compilacion.md) · [F14 §8](14-abi-libc-y-prebuilds.md)
