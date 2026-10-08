# 🐍 Parte I · Fase 05 — Python y node-gyp: el traductor entre npm y el mundo nativo

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`)
> **Arquitectura objetivo del laboratorio:** `linux/amd64`
> **Dockerfile pedagógico de esta fase:** `dockerfiles/04-python-node-gyp.Dockerfile`
> **Tag pedagógico:** `legacy-node-toolchain:phase05`
> **Estado de la imagen al terminar:** Debian 10, utilidades, toolchain C/C++ y los dos intérpretes de Python. Sigue sin Node
> **Código de esta fase:** [`src/05-python-y-node-gyp/`](src/05-python-y-node-gyp/)
> **Objetivo:** entender por qué aparece Python en un proyecto que no tiene una línea de Python, cómo `node-gyp` conecta npm con el compilador de [F04](04-toolchain-de-compilacion.md), y por qué la pregunta correcta nunca es "¿qué Python necesito?"

---

## 1. 🧭 Dónde estamos

`phase04` sabe compilar C y C++. Lo que no tiene es la pieza que hace que **npm** llegue
hasta ese compilador, y esa pieza —sorprendentemente— está escrita en Python.

Esta fase cierra la deuda que dejó abierta [F04](04-toolchain-de-compilacion.md): teníamos `gcc`, `g++` y `make` preparados
sin haber explicado todavía quién los llama.

```text
phase04                      phase05  ← esta fase
────────                     ────────
utilidades                   utilidades
gcc g++ make pkg-config      gcc g++ make pkg-config
                             + python2
                             + python3
                             y el mapa de cómo npm llega hasta gcc
```

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder explicar:

- Por qué un proyecto Vue 2 sin una línea de Python falla con `gyp ERR! find Python`.
- Qué es `node-gyp` y qué hace exactamente, paso a paso, hasta producir un `.node`.
- Por qué la pregunta *"¿qué versión de Python necesito?"* está mal formulada, y cuál es la
  correcta.
- Cómo se le dice a `node-gyp` qué intérprete usar, y por qué preferimos ser explícitos.
- Qué es un `binding.gyp` y cómo leerlo cuando algo falla.

---

## 3. 🚧 Qué NO entra todavía

Un aviso importante sobre esta fase: **al terminarla, `node-gyp` seguirá sin estar
instalado**, y eso es correcto. `node-gyp` llega con npm, y npm llega con Node, que es
**[F06](06-instalacion-node.md)**. Aquí preparamos el terreno y entendemos el mecanismo.

Lo demás que queda fuera:

- Instalar Node y npm, y con ellos `node-gyp` de verdad → **[F06](06-instalacion-node.md)**.
- El ABI, `NODE_MODULE_VERSION` y por qué un addon compilado para Node 10 no sirve en Node
  12 → **[F14](14-abi-libc-y-prebuilds.md)**.
- Los laboratorios reales: `node-sass`, `canvas`, `sqlite3`, Puppeteer → **[F15](15-laboratorios-dependencias-nativas.md)**.
- El catálogo completo de fallos de `node-gyp` → **[F32](32-catalogo-de-fallos-ii.md)**.
- `pyenv`, `update-alternatives` y la gestión avanzada de intérpretes → fuera de alcance,
  con la justificación en §6.3.

---

## 4. 🤔 El error absurdo: Python en un proyecto sin Python

Imagina un proyecto Vue 2 de 2018. Su código tiene JavaScript, Vue, CSS y HTML. Ni una
línea de Python. Y aun así:

```bash
npm install
```

```text
gyp ERR! find Python
gyp ERR! find Python Python is not set from command line or npm configuration
gyp ERR! find Python Python is not set from environment variable PYTHON
gyp ERR! find Python checking if "python3" can be used
gyp ERR! find Python - "python3" is not in PATH or produced an error
```

Parece absurdo hasta que sigues la cadena. Alguna dependencia —probablemente transitiva,
probablemente `node-sass`— contiene un addon nativo. Para compilarlo, npm invoca a
`node-gyp`. Y **`node-gyp` está escrito en Python**.

```mermaid
flowchart TD
    P["tu proyecto Vue 2"] -- "npm install" --> A["alguna dependencia con addon nativo"]
    A --> G["node-gyp<br/>escrito en Python"] --> MK["Makefile generado"]
    MK --> MAKE["make → g++ / gcc<br/>lo que instalamos en F04"] --> N["addon.node"]
```

Python no aparece porque tu proyecto lo use. Aparece porque **la herramienta de construcción
lo usa**, y esa herramienta se ejecuta durante tu `npm install` sin que tú la invoques
nunca.

---

## 5. 🔩 Qué hace `node-gyp`, sin magia negra

La documentación oficial lo describe como una herramienta multiplataforma para compilar
addons nativos de Node. En términos más terrenales: **convierte una configuración de build
declarativa en los archivos que el toolchain del sistema sabe usar**.

En Linux, el recorrido completo:

```mermaid
flowchart TD
    B["binding.gyp<br/>lo escribe el autor del paquete"] --> C["node-gyp configure<br/>lee binding.gyp, resuelve las cabeceras de Node"]
    C --> M["build/Makefile<br/>generado, no escrito a mano"] --> NB["node-gyp build"]
    NB --> MK["make<br/>F04"] --> G["g++ / gcc<br/>F04"]
    G --> R["build/Release/addon.node<br/>una librería compartida con otra extensión"]
```

Ese `.node` final es una librería compartida de Linux con la extensión cambiada. Puedes
comprobarlo con la herramienta de [F04](04-toolchain-de-compilacion.md):

```bash
file build/Release/binding.node
```
```text
build/Release/binding.node: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, ...
```

> 🧠 **Modelo mental.** `node-gyp` no compila nada por sí mismo. Es un **generador de
> Makefiles** que sabe dónde están las cabeceras de tu versión de Node. Cuando falla, la
> pregunta útil es en qué eslabón de esa cadena se rompió: ¿no encontró Python? ¿no encontró
> las cabeceras de Node? ¿o el que falló fue `gcc`, que es un problema completamente
> distinto?

### 5.1 `binding.gyp`, el "Makefile conceptual"

Es un archivo JSON —con comas finales permitidas, herencia de GYP— que describe qué
compilar:

```python
{
  "targets": [
    {
      "target_name": "binding",
      "sources": [ "src/binding.cc" ],
      "include_dirs": [ "<!(node -e \"require('nan')\")" ]
    }
  ]
}
```

No hace falta que sepas escribirlo. Hace falta que sepas **leerlo**, porque cuando un módulo
nativo de 2018 no compila, este archivo te dice qué fuentes intenta compilar, contra qué
cabeceras y con qué banderas — y muchas veces la respuesta está ahí a la vista.

---

## 6. 🐍 Python 2 y Python 3 en Debian 10

### 6.1 La regla más importante de la fase

No existe una respuesta universal a *"¿qué Python necesita `node-gyp`?"*. La respuesta
correcta es:

> 🧭 **Depende de la versión de `node-gyp`.** Y en un proyecto legacy, esa versión no es la
> que tú instalaste: es la que arrastra alguna dependencia tuya en el árbol.

Tabla histórica, con versiones representativas de la documentación oficial de cada
generación:

| `node-gyp` | Python documentado | Contexto | Riesgo en legacy |
|---|---|---|---|
| 3.8.x | Python 2.7; Python 3 **no** soportado | muy común en dependencias de la segunda mitad de los 2010 | 🔴 alto si solo tienes Python 3 |
| 4.0.x | Python 2.7; Python 3 no soportado | transición previa al soporte de Python 3 | 🔴 alto |
| 5.1.x | Python 2.7 **o** 3.5–3.7 | soporte inicial de ambas familias | 🟡 importa cuál detecte |
| 7.1.x | Python 2.7 **o** 3.5–3.8 | transición fuerte hacia Python 3 | 🟡 medio |
| 8.4.x | Python 3.6–3.9 | Python 2 fuera de esta generación | 🟡 falla si fuerzas Python 2 |
| 9.4.x | Python 3.7–3.10 | moderno respecto a nuestro stack | 🟢 con Python 3 compatible |

La lectura correcta de esa tabla no es "usa Python 2 para proyectos viejos". Es que **la
compatibilidad es una combinación de versiones**: `node-gyp` × Python. Fijar una sin conocer
la otra es adivinar.

### 6.2 Por eso instalamos los dos

Nuestro laboratorio apunta a cuatro generaciones de Node y a proyectos de 2017–2020, y el
riesgo se distribuye así:

| Node objetivo | Qué esperas en el árbol de dependencias | Riesgo de Python |
|---|---|---|
| Node 10 | npm 6 y dependencias muy antiguas; `node-gyp` 3/4/5 es probable | 🔴 alto: Python 2 puede ser necesario |
| Node 12 | mezcla de dependencias antiguas y con soporte Python 3 | 🟠 medio-alto: conviene tener los dos |
| Node 14 | ecosistema ya orientado a Python 3, con restos antiguos | 🟡 medio |
| Node 16 | toolchain más moderno, pero un lockfile viejo arrastra lo que arrastre | 🟡 depende del árbol, no de Node |

La conclusión es cómoda: **instalar `python2` y `python3` cuesta poco y aumenta mucho la
capacidad de diagnóstico**. No para usarlos a la vez en la misma compilación, sino para
poder elegir el apropiado según el proyecto.

Debian 10 nos da exactamente las dos ramas que necesitamos: **Python 2.7 y Python 3.7**.

### 6.3 Lo que deliberadamente no instalamos

**`python-is-python2` o un symlink `python`.** No creamos un `/usr/bin/python` genérico. Un
comando `python` ambiguo es precisamente lo que produce los diagnósticos confusos que esta
fase quiere evitar: quieres saber **cuál** intérprete corrió, no que alguien lo decida por
ti.

**`update-alternatives`.** Puede gestionar varias implementaciones de un comando, pero aquí
añade una capa de indirección sin ganancia. Nuestra solución es más clara: quiero Python 2,
escribo `/usr/bin/python2`. Cuando un proyecto legacy falla, **la explicitud es amiga
nuestra**.

**`pyenv`.** Tendría sentido si necesitáramos 2.7.18, 3.6.15, 3.8.20 y 3.11 con selección
por proyecto. Debian 10 ya nos da lo que necesitamos, y añadir `pyenv` implicaría descargar
y compilar intérpretes, arrastrar sus dependencias de build, configurar `PATH` y shims, y
mantener otra capa de versionado. Es resolver un problema que todavía no tenemos. Si un
proyecto concreto exige una versión exacta que no está, se reconsidera en troubleshooting.

---

## 7. 🎛️ Cómo se le dice a node-gyp qué Python usar

Tres formas, de más explícita a menos. La primera es la que este curso prefiere.

**La opción `--python`**, que deja el intérprete a la vista en el propio comando:

```bash
node-gyp rebuild --python /usr/bin/python2
```

La ventaja pedagógica es enorme: leyendo el comando sabes exactamente qué Python se intentó
usar. No hay que adivinar ni revisar configuración global.

**La variable de entorno `PYTHON`**, que varias generaciones de `node-gyp` respetan:

```bash
export PYTHON=/usr/bin/python2
node-gyp rebuild
echo "$PYTHON"      # verificar
unset PYTHON        # limpiar la sesión
```

**`npm config set python`**, que escribe en el `.npmrc` del usuario. Funciona, pero es
configuración persistente e invisible: dentro de tres semanas nadie recuerda que está ahí,
y produce el clásico *"a mí me funciona y a ti no"*. Si la usas, déjala documentada.

> 🩺 **El diagnóstico que hay que hacer primero.** Antes de cambiar de Python, averigua qué
> `node-gyp` está corriendo de verdad. Cuando tengas npm ([F06](06-instalacion-node.md)):
>
> ```bash
> npm ls node-gyp
> ```
>
> Y en los logs de instalación, la línea de oro:
>
> ```text
> gyp info using node-gyp@3.8.0
> ```
>
> La pregunta es *"¿qué `node-gyp` está ejecutándose realmente?"*, no *"¿qué `node-gyp` creo
> que tengo?"*. Parece una diferencia pequeña; en legacy ahorra horas. 😄

---

## 8. 🏗️ El Dockerfile de la fase

📄 **`dockerfiles/04-python-node-gyp.Dockerfile`**

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
       python2 \
       python3 \
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

- Solo dos paquetes nuevos —`python2` y `python3`— en su sitio alfabético.
- **No hay `ENV PYTHON`.** Es deliberado: fijar el intérprete en la imagen decidiría por
  todos los proyectos que la usen, y eso contradice la regla de [F01](01-decisiones-debian-zonas-node.md) de que el toolchain no
  impone decisiones del proyecto. El intérprete se elige al ejecutar.
- Sigue partiendo de `debian/eol:buster` con la receta completa, por lo mismo que en [F04](04-toolchain-de-compilacion.md).

```bash
docker build \
  --platform linux/amd64 \
  --file dockerfiles/04-python-node-gyp.Dockerfile \
  --tag legacy-node-toolchain:phase05 \
  .
```

---

## 9. 🔥 Prueba de fuego

**Los dos intérpretes están y son los esperados:**

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase05 \
  bash -c 'python2 --version; python3 --version; command -v python || echo "python: AUSENTE (correcto)"'
```
```text
Python 2.7.16
Python 3.7.3
python: AUSENTE (correcto)
```

Que `python` a secas no exista **es el resultado que buscamos**, no un fallo. Lo dice §6.3.

**Los dos ejecutan código, y se distinguen:**

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase05 \
  bash -c 'python2 -c "print \"hola desde Python 2\""; python3 -c "print(\"hola desde Python 3\")"'
```
```text
hola desde Python 2
hola desde Python 3
```

Esa diferencia de sintaxis —`print` como sentencia frente a `print()` como función— es
exactamente la que produce el error de §10 cuando un script de `node-gyp` antiguo cae en
manos de Python 3.

**`node-gyp` todavía no existe, y eso es correcto:**

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase05 \
  bash -c 'command -v node-gyp || echo "node-gyp: AUSENTE — llega con npm en F06"'
```

---

## 10. ⚠️ Errores comunes y diagnóstico

**`Can't find Python executable "python"`.** El reflejo es crear un symlink
`/usr/bin/python`. **No lo hagas todavía.** Primero averigua qué `node-gyp` corre: si es
3.x o 4.x querrá Python 2, y si es 8.x o superior querrá Python 3. Un symlink apuntando al
intérprete equivocado convierte un error claro en uno confuso.

**Sintaxis de Python 2 ejecutada con Python 3.** Se reconoce al instante:

```text
File "gyp_main.py", line 45
    print "Building..."
          ^
SyntaxError: Missing parentheses in call to 'print'
```

Un `node-gyp` de la generación 3 o 4 corriendo sobre Python 3.7. La solución es apuntar a
`/usr/bin/python2`, no "arreglar" el script.

**Python 2 funciona pero `node-gyp` lo rechaza.** El caso inverso: una generación 8.x o
posterior exige Python 3 y falla si fuerzas el 2. Confirma con `npm ls node-gyp` antes de
tocar nada.

**`node-gyp: command not found`** en esta fase. Esperado y correcto. Llega en [F06](06-instalacion-node.md).

**`gyp ERR! stack Error: not found: make`** o un error de `gcc`. Ese ya no es un problema de
Python: significa que `node-gyp` hizo su trabajo y falló el toolchain de [F04](04-toolchain-de-compilacion.md). Vuelve a esa
fase y comprueba el checklist.

> 🧭 **El patrón a memorizar:** cuando falla la instalación de un módulo nativo, hay
> **cuatro** eslabones posibles y cada uno tiene un arreglo distinto — Python, `node-gyp`,
> las cabeceras de Node, o el compilador. Leer el mensaje para saber cuál se rompió vale más
> que conocerse los cuatro arreglos de memoria.

---

## 11. 📋 Checklist de validación

```text
[ ] dockerfiles/04-python-node-gyp.Dockerfile existe con los 21 paquetes de §8
[ ] El build produce legacy-node-toolchain:phase05 sin error
[ ] python2 --version responde 2.7.x
[ ] python3 --version responde 3.7.x
[ ] `python` a secas NO existe (comprobado, y sabes por qué)
[ ] Los dos intérpretes ejecutan su print característico
[ ] node-gyp NO está instalado (esperado en esta fase)
[ ] Puedes dibujar la cadena npm → node-gyp → make → gcc → .node
[ ] Puedes explicar por qué "¿qué Python necesito?" es la pregunta equivocada
[ ] Sabes qué comando te dice qué node-gyp corre de verdad
```

---

## 12. 🧪 Ejercicios de la Fase 05 (20)

## 🟢 Fácil — los dos intérpretes (1–5)

### 🟢 Ejercicio 1 — Construye y verifica los dos intérpretes

Construye `phase05` y ejecuta las tres comprobaciones de §9.

**Objetivo:** tener los dos Python y haber confirmado que `python` a secas no existe.

### 🟢 Ejercicio 2 — La sintaxis que rompe

Ejecuta `python3 -c 'print "hola"'` y lee el error entero.

**Objetivo:** reconocer el `SyntaxError: Missing parentheses` a primera vista. Lo vas a ver
en logs de `npm install` reales.

### 🟢 Ejercicio 3 — Dónde están los intérpretes

Ejecuta `ls -la /usr/bin/python*` dentro del contenedor.

**Pregunta:** ¿cuáles son symlinks y a qué apuntan? ¿Hay algún `python` sin número?

### 🟢 Ejercicio 4 — Dos Python, dos versiones de pip

Comprueba si `pip` y `pip3` existen en la imagen.

**Pregunta:** ¿están? ¿Los necesita `node-gyp`? Justifica por qué el curso no los instala.

### 🟢 Ejercicio 5 — Mide el coste

Compara el tamaño de `phase04` y `phase05` con `docker image ls`.

**Pregunta:** ¿cuánto cuestan los dos intérpretes, y te parece caro frente a lo que evitan?

## 🟡 Intermedio — seguir la cadena (6–12)

### 🟡 Ejercicio 6 — Lee un `binding.gyp` real

Busca el `binding.gyp` de `bcrypt` o de `sqlite3` en GitHub.

**Objetivo:** identificar los tres campos que siempre están: `target_name`, `sources` e
`include_dirs`. No hace falta entenderlo entero.

### 🟡 Ejercicio 7 — Traza la cadena hacia atrás

Sin ejecutar nada, escribe de memoria la cadena desde `npm install` hasta `addon.node`,
nombrando qué herramienta actúa en cada paso.

**Pregunta:** ¿cuáles de esos pasos ya están instalados en `phase05` y cuáles faltan?

### 🟡 Ejercicio 8 — Sé explícito a mano

Escribe un script de shell que reciba `2` o `3` como argumento y ejecute un
`python -c` con el intérprete correspondiente, fallando con un mensaje claro si recibe otra
cosa.

**Objetivo:** practicar el patrón de explicitud de §6.3, que es el mismo que usará el
despachador de Node en [F08](08-run-el-contenedor-como-proceso.md).

### 🟡 Ejercicio 9 — La variable `PYTHON`

Exporta `PYTHON=/usr/bin/python2` dentro del contenedor, comprueba con `echo`, y después
`unset`.

**Pregunta:** ¿esa variable sobrevive si sales y vuelves a entrar con `docker exec`? ¿Y si
reinicias el contenedor? La respuesta importa en [F09](09-montar-tu-proyecto.md).

### 🟡 Ejercicio 10 — Un `binding.gyp` de juguete

Escribe un `binding.gyp` mínimo con un solo target y un `sources` que apunte a un `.cc`
inexistente.

**Objetivo:** tenerlo preparado para [F06](06-instalacion-node.md), cuando ya haya `node-gyp` de verdad y puedas ver
qué error da exactamente.

### 🟡 Ejercicio 11 — Compila un `.node` a mano

Sin `node-gyp`, compila una librería compartida con
`gcc -shared -fPIC -o falso.node falso.c` y examínala con `file`.

**Objetivo:** comprobar que un `.node` no tiene nada de mágico: es un objeto compartido ELF
con otra extensión.

### 🟡 Ejercicio 12 — Python 3.7 no es Python 3.11

Comprueba con `python3 --version` y busca en la documentación de `node-gyp` 10 qué versiones
de Python soporta.

**Pregunta:** si un proyecto arrastra `node-gyp` 10, ¿le sirve el Python 3.7 de Buster? ¿Qué
harías?

## 🟠 Difícil — cuando el intérprete es el equivocado (13–17)

### 🟠 Ejercicio 13 — Simula la decisión de `node-gyp`

Dado un proyecto ficticio cuyo log dice `gyp info using node-gyp@5.1.0`, y usando la tabla
de §6.1, decide qué intérprete usarías y con qué comando exacto.

**Pregunta:** ¿hay una sola respuesta correcta para la generación 5.1? ¿Qué harías si el
primero que pruebas falla?

### 🟠 Ejercicio 14 — Fija `ENV PYTHON` y arrepiéntete

Construye una variante de la imagen con `ENV PYTHON=/usr/bin/python2`.

**Pregunta:** ¿qué le pasaría a un proyecto que necesita `node-gyp` 8.x usando esa imagen?
Relaciona la respuesta con la regla de [F01](01-decisiones-debian-zonas-node.md) sobre las CLIs.

### 🟠 Ejercicio 15 — El symlink que empeora las cosas

Crea `ln -s /usr/bin/python3 /usr/bin/python` en el contenedor e imagina un proyecto con
`node-gyp` 3.8.

**Pregunta:** ¿qué error verá el usuario ahora, y por qué es **más difícil** de diagnosticar
que el `Can't find Python executable` original?

### 🟠 Ejercicio 16 — Reconstruye la decisión desde un `package-lock.json`

Toma el `package-lock.json` de tu proyecto legacy —o el del fixture Vue 2 de
`src/10-validar-tu-proyecto/10-vue2-min/`— y busca en él `node-gyp`.

**Pregunta:** ¿qué versión aparece? ¿Es la que esperabas viendo la versión de Node del
proyecto? Si no aparece ninguna, ¿qué significa eso?

### 🟠 Ejercicio 17 — Predice el intérprete correcto

Para cada uno de estos tres escenarios, **predice** qué Python hace falta y justifícalo, y
después búscalo en la documentación de esa versión de `node-gyp` para comprobar:

1. Proyecto Angular 8 con Node 10 y `node-sass@4.14.1` en el lockfile.
2. Proyecto React 16 con Node 16 y un lockfile regenerado en 2023.
3. Proyecto Vue 2 con Node 12 y `sqlite3@4.2.0`.

## 🔴 Muy difícil — criterio y diagnóstico abierto (18–20)

### 🔴 Ejercicio 18 — Diagnostica cuatro logs

Busca en GitHub cuatro logs de fallo de instalación de módulos nativos y clasifica cada uno
según el eslabón que se rompió: Python ausente, Python incompatible, cabeceras de Node
ausentes, o error de compilación.

**Objetivo:** entrenar la clasificación de §10, que es el músculo real de esta fase. Anota
para cada uno la línea exacta que te permitió decidir.

### 🔴 Ejercicio 19 — El proyecto que necesita los dos

Diseña —sobre el papel— un escenario en el que un mismo `npm install` necesite **Python 2
para una dependencia y Python 3 para otra**, y explica por qué eso puede ocurrir en un
proyecto real de 2019.

**Objetivo:** llegar a la conclusión incómoda de que `--python` es una opción por invocación
de `node-gyp`, no global, y razonar qué estrategia usarías. Esta situación existe y es una de
las razones de que el laboratorio instale los dos intérpretes.

### 🔴 Ejercicio 20 — Escribe la guía de diagnóstico

Redacta un árbol de decisión de una página que, partiendo de un fallo de `npm install` en un
módulo nativo, lleve al eslabón roto en el menor número de comandos posible.

**Objetivo:** tiene que empezar por *"¿qué `node-gyp` corre de verdad?"* y no por *"instala
Python 2"*. Guárdalo: en **[F30](30-troubleshooting-metodo-y-herramientas.md)** vas a compararlo con el método formal del curso y verás qué
te faltaba.

## 🔥 Opcionales

### 🔥 Ejercicio 21 — GYP antes de node-gyp

Investiga qué es GYP, de dónde salió y por qué un proyecto de Node acabó usando el sistema
de build de Chromium.

**Pregunta:** ¿qué explica esa historia sobre por qué `binding.gyp` tiene esa sintaxis tan
peculiar? Es una 📝 nota de época excelente para contarle a alguien.

### 🔥 Ejercicio 22 — Un `binding.gyp` mínimo, de cero

Escribe un addon nativo de juguete: un `binding.gyp`, un `.cc` de diez líneas que exporte una
función que sume dos números, y un `index.js` que la llame. Compílalo con `node-gyp rebuild`
dentro del contenedor y ejecútalo.

**Objetivo:** que el `.node` que sale exista, cargue y devuelva el resultado correcto. Guarda
ese archivo: es el material con el que **[F14](14-abi-libc-y-prebuilds.md)** te va a pedir que diseccciones un binario de
verdad, y tiene mucha más gracia cuando es tuyo.

## 💀 Boss fight

### 💀 Ejercicio 23 — Boss fight: el `npm install` que pide un Python que no existe

Te dan un `package.json` con una dependencia nativa y un contenedor donde `npm install` falla
con un muro de texto que menciona `gyp ERR!`, `Could not find any Python installation to use`
y, más abajo, algo sobre `stack Error: not found: make`. El equipo lleva dos días añadiendo
paquetes al azar.

**Objetivo:** diagnosticar **en orden** y sin instalar nada hasta haber confirmado la causa.
Tienes que: (1) separar los **dos** fallos que ese muro contiene y decir cuál se resuelve en
esta fase y cuál en **[F04](04-toolchain-de-compilacion.md)**; (2) demostrar con `which python python2 python3` y
`node-gyp configure --verbose` qué está buscando exactamente node-gyp y por qué no lo
encuentra, apoyándote en §6; (3) resolverlo **de las tres formas** de §7 —`PYTHON`,
`npm config set python` y `--python`— y explicar cuál de las tres sobrevive a un
`npm ci` en CI y cuál no, con la evidencia de por qué; (4) dejarlo arreglado en el Dockerfile
de §8 y **volver a romperlo a propósito** apuntando a un Python que no existe, para confirmar
que sabes reconocer el mensaje.

**Pregunta:** un proyecto cuyo `package.json` no menciona Python por ninguna parte, ¿por qué
lo necesita? Contesta con la cadena completa, desde `binding.gyp` hasta el Makefile, tal y
como la explica §5.

---

## 13. 📚 Referencias

**node-gyp**
- Repositorio y README actual: https://github.com/nodejs/node-gyp
- Generaciones históricas, útiles para la tabla de §6.1:
  https://github.com/nodejs/node-gyp/tree/v3.8.0 ·
  https://github.com/nodejs/node-gyp/tree/v5.1.0 ·
  https://github.com/nodejs/node-gyp/tree/v8.4.1

**GYP y binding.gyp**
- Documentación de GYP: https://gyp.gsrc.io/docs/UserDocumentation.md

**Python en Debian 10**
- `python2` en Buster: https://packages.debian.org/buster/python2
- `python3` en Buster: https://packages.debian.org/buster/python3

> ⚠️ **El README actual de `node-gyp` describe la versión 10 y superiores**, que exige
> Python moderno y no dice nada útil sobre las generaciones 3 y 4 que vas a encontrarte en
> un lockfile de 2018. Para esas, la fuente buena es el `README` del **tag** correspondiente,
> que es la razón de que los enlaces de arriba apunten a tags y no a `main`.

**Orden de lectura sugerido:** el README de `node-gyp` v3.8.0 primero —es corto y describe el
mundo del que vienen tus proyectos—, y la documentación de GYP solo si haces el ejercicio 23.

---

## 14. 🏁 Resultado de la fase

```text
IMAGEN        legacy-node-toolchain:phase05
BASE          debian/eol:buster · Debian 10 · linux/amd64

CONTIENE      12 utilidades (F03)
              toolchain C/C++ (F04)
              + python2 (2.7.16) y python3 (3.7.3)
              sin `python` genérico, a propósito
              sin ENV PYTHON, a propósito

NO CONTIENE   Node ❌  npm ❌  node-gyp ❌   ← los tres llegan juntos en F06

SABES         por qué Python aparece en un proyecto sin Python
              qué hace node-gyp paso a paso
              que la compatibilidad es node-gyp × Python, no Python a secas
              cómo elegir el intérprete de forma explícita
              en qué eslabón se rompió un fallo de módulo nativo
```

> **La señal de que quedó bien:** *"ante un `gyp ERR!` no busco el mensaje en Google: miro
> primero qué versión de `node-gyp` corrió y decido desde ahí."*

En **[F06](06-instalacion-node.md)** llegan por fin Node, npm y —con ellos— `node-gyp`. Cuatro generaciones en una sola
imagen, y un despachador que decide cuál está activa.
