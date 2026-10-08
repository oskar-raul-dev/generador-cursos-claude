# 🍎 Parte II · Fase 22 — Apple Silicon y el zoológico de hosts

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** `linux/amd64` baseline · `linux/arm64` adicional
> **Requisitos:** **[F21](21-arquitecturas-y-emulacion.md)** (arquitecturas y emulación) y **[F14](14-abi-libc-y-prebuilds.md)** (ABI)
> **Fecha de revisión de comportamiento de productos:** 3 de septiembre de 2026
> **Fecha de revisión de documentación externa:** 10 de septiembre de 2026 — la documentación de Apple sobre binarios Intel en VM Linux (§5)
> **Estado de la imagen al terminar:** sin cambios
> **Objetivo:** bajar la teoría de F21 a tu máquina real — las cinco rutas que tienes en un Mac ARM, qué motor elegir, y por qué el nombre del volumen tiene que crecer

---

## 1. 🧭 Dónde estamos

[F21](21-arquitecturas-y-emulacion.md) explicó el mecanismo. Esta fase responde la pregunta práctica: **¿qué hago yo, en mi
máquina, hoy?**

Y empieza reconociendo el punto de partida que [F00](00-problema-y-contrato.md) estableció y que conviene tener presente
otra vez:

> 🧠 **En un Mac con Apple Silicon no existe Node legacy nativo.** Node no publicó
> `darwin-arm64` antes de la 16. Así que la pregunta no es *"¿contenedor o nativo?"* — es
> **dónde ocurre la traducción y quién la administra**.

```mermaid
flowchart TD
    M["Mac Apple Silicon, proyecto con Node 10"] --> N["nvm install 10<br/>tarball darwin-x64 + Rosetta 2<br/>emulación implícita, no declarada, no reproducible"]
    M --> C["contenedor"]
    C --> A["linux/arm64<br/>binario oficial ARM64, sin traducción"]
    C --> X["linux/amd64<br/>binario oficial x86-64, traducción declarada<br/>en --platform y reproducible en cualquier host"]
```

La diferencia entre las dos ramas no es el rendimiento. Es que **la de abajo la escribes tú en
un comando, la puedes versionar y la puede repetir otra persona**.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder:

- Enumerar las **cinco rutas** de un Mac ARM y decir cuándo elegir cada una.
- Distinguir la Rosetta de las apps de macOS de la traducción dentro de la VM Linux.
- Elegir motor —Docker Desktop, Podman Desktop, Colima— con criterio, no por costumbre.
- Aplicar la convención de nombres de volumen que **incluye la arquitectura**.
- Clasificar cualquier dependencia npm en las cuatro categorías multiplataforma.

---

## 3. 🚧 Qué NO entra todavía

- **Los estudios de caso medidos** —`node-sass` y `canvas` en ARM64, con benchmarks— →
  **[F23](23-estudios-de-caso-multiplataforma.md)**.
- **Colima y Lima a fondo** → **[a07](a07-colima-y-lima.md)**. **Windows y WSL2** → **[a08](a08-windows-y-powershell.md)**.
- **La comparación seria Docker/Podman**, arquitectura contra arquitectura → **[F24](24-docker-y-podman-arquitectura.md)** y
  **[F26](26-portabilidad-entre-motores.md)**.

---

## 4. 🗺️ Las cinco rutas

No hay una respuesta única, y por eso son cinco. La elección depende de **tu proyecto
concreto**.

| | Ruta | Qué es | Cuándo |
|---|---|---|---|
| 1 | **`linux/arm64` nativo** | contenedor ARM64, sin traducción | tu proyecto es JavaScript puro o sus deps tienen prebuilds ARM64 |
| 2 | **`linux/amd64` traducido** | contenedor x86-64 sobre ARM | **el baseline del curso**: máxima compatibilidad con prebuilds de 2018 |
| 3 | **Node nativo con `nvm`** | Rosetta 2, implícito | 🚫 no recomendada aquí: emulas igual, sin declararlo |
| 4 | **VM x86-64 completa** | UTM, VMware, QEMU máquina completa | último recurso; lento, y a veces la única salida |
| 5 | **CI o máquina remota amd64** | construir y probar fuera | cuando lo local no compensa |

> 🧭 **El orden de intento que recomienda el curso:** empieza por la **2**, que es el baseline
> y el que más probabilidades tiene de que `npm ci` no compile nada. Si el rendimiento te
> molesta, mide y prueba la **1**. La **3** solo si no usas contenedores en absoluto, y sabiendo
> que estás emulando igual. La **4** y la **5** son para casos concretos.

Y el argumento que decide entre la 1 y la 2, que [F21](21-arquitecturas-y-emulacion.md) §4.2 ya adelantó: **Node existe para las
dos; los prebuilds de 2018, no**. Ir a arm64 nativo significa que muchas dependencias nativas
tendrán que compilar — y compilar es donde de verdad se va el tiempo.

---

## 5. 🍎 Dos Rosettas, y la confusión que causan

Es una distinción sutil y merece la pena tenerla clara, porque la gente mezcla las dos.

**Rosetta 2 para apps de macOS.** Traduce binarios de macOS x86-64 para que corran en Apple
Silicon. Es lo que usa tu `nvm install 10`: descarga un `node-darwin-x64` y macOS lo traduce.

**La traducción dentro de la VM Linux.** Aquí el binario es un ELF de Linux x86-64 corriendo en
un kernel Linux ARM64. Lo puede traducir **QEMU** —lo estándar— o, si el motor lo soporta,
**Rosetta expuesta a la VM**, que Apple hizo posible con su framework de virtualización.

```mermaid
flowchart TD
    subgraph SA["CASO A · tu terminal de macOS"]
        A1["node (darwin-x64)"] --> A2["Rosetta 2 de macOS"] --> A3["CPU ARM"]
    end
    subgraph SB["CASO B · dentro de la VM Linux"]
        B1["node (linux-x64)"] --> B2["QEMU o Rosetta expuesta a la VM"] --> B3["CPU ARM"]
    end
```

**Por qué importa la diferencia:** en el caso A la emulación es **implícita** —nadie la declara
y no aparece en ningún archivo—, y en el caso B es **explícita**: está en tu `--platform`, se
versiona y se reproduce.

### 5.1 El dato de calendario, que no es el que se supone

Apple ha anunciado que el soporte de **Rosetta 2 para aplicaciones de macOS** se reduce en
versiones futuras del sistema. De ahí mucha gente deduce —y se ha escrito bastante— que la
traducción dentro de la VM Linux muere con ella, y que por tanto el baseline `linux/amd64`
tiene los días contados en un Mac.

**No es el mismo componente, y no sigue el mismo camino.** Es exactamente la distinción de §5,
y aquí es donde deja de ser una sutileza y pasa a decidir una arquitectura:

| Componente | Qué traduce | Hacia dónde va |
|---|---|---|
| Rosetta 2 para apps de macOS | binarios `darwin-x64` — el caso A | se reduce en versiones futuras del sistema |
| Traducción Intel para VM Linux | ELF `linux-x64` dentro de una VM ARM — el caso B, tu `--platform` | **se integra en el sistema en macOS 27** |

La documentación de Apple sobre binarios Intel en VM Linux lo dice sin rodeos: hasta macOS 26
esa capacidad formaba parte de Rosetta, y **macOS 27 integra la traducción de binarios Intel
directamente en el sistema, sin necesidad de instalar Rosetta** — hasta el punto de que, desde
esa versión, consultar la disponibilidad devuelve siempre "instalada" y la llamada de
instalación retorna de inmediato.

> 🧠 **La consecuencia para este laboratorio, dicha claro.** El baseline `linux/amd64` **no
> tiene fecha de caducidad anunciada** en Mac. La ruta 2 es sostenible, y la ruta 1 —arm64
> nativo— se elige por rendimiento o por curiosidad, no como plan de evacuación. Si venías con
> la idea de migrarlo todo a ARM64 antes de una fecha, puedes soltarla.

Y tres cautelas que se mantienen, porque un hecho documentado no es un contrato:

- **Apple no promete permanencia.** Documenta el comportamiento actual; no publica un compromiso
  de soporte a futuro para esta capacidad. Integrarla en el sistema es la señal más fuerte
  disponible de continuidad, pero es una inferencia razonable, no una garantía.
- **Los runtimes tienen que ponerse al día.** Docker Desktop, Podman y Colima exponen esto hoy
  con el nombre "Rosetta" —`--vz-rosetta`, la casilla *Use Rosetta*— y tendrán que actualizar
  detección y terminología. Es fricción de herramientas, no de arquitectura, pero te la vas a
  encontrar como un mensaje raro antes que como un fallo.
- **Y hay una comprobación que te toca a ti** después de cada actualización mayor de macOS:

```bash
docker run --rm --platform linux/amd64 debian/eol:buster uname -m
```

Tiene que devolver `x86_64`, y con rendimiento de traducción —segundos en un `npm ci`— y no de
QEMU —minutos—. Si la cifra se desploma, el motor cayó al fallback y no te lo dijo: §6.4 tiene
cómo distinguirlos.

> ⚠️ **Nada de esto rehabilita la ruta 3.** `nvm` más Rosetta sigue siendo emulación implícita,
> no declarada y no reproducible, y ese defecto no depende de ninguna fecha de Apple.

---

## 6. ⚙️ Los tres motores en Apple Silicon

Los tres funcionan con este laboratorio. Se diferencian en el modelo, no en si sirven.

### 6.1 Docker Desktop

El camino más común, y el que asumen los ejemplos del curso. Usa el **Apple Virtualization
Framework** para la VM Linux, y desde hace unas versiones ofrece **Docker VMM**, un hipervisor
propio optimizado para Apple Silicon.

**La opción que más importa** para lo de esta fase está en la configuración: *Use Rosetta for
x86/amd64 emulation on Apple Silicon*. Con ella activada, los contenedores amd64 se traducen
con Rosetta en lugar de QEMU, y la diferencia se nota — **[F23](23-estudios-de-caso-multiplataforma.md)** la mide.

```bash
docker version --format '{{.Server.Os}}/{{.Server.Arch}}'
docker info --format '{{.OperatingSystem}} · {{.Architecture}}'
```

### 6.2 Podman Desktop

El segundo camino principal del curso, no un anexo. Usa `applehv` —el framework de Apple— para
su máquina, y también sabe usar Rosetta para la traducción.

```bash
podman machine list
podman machine inspect | jq '.[0].Resources'
podman version --format '{{.Server.OsArch}}'
```

Podman construye multi-plataforma con `podman build --platform`, y las diferencias reales con
Buildx están en **[F24](24-docker-y-podman-arquitectura.md)**.

### 6.3 Colima

Una VM Linux gestionada por Lima, que ejecuta el runtime de Docker. Desde tu terminal, el
trabajo cotidiano es con la CLI de Docker de siempre.

```bash
colima start --arch aarch64 --cpu 4 --memory 8
colima status
```

Es especialmente interesante en Apple Silicon porque permite elegir la arquitectura de la VM
**explícitamente** —incluso arrancar una VM x86-64 entera, que es la ruta 4—. El detalle
completo está en **[a07](a07-colima-y-lima.md)**.

> 🧭 **Cuál elegir.** Si no tienes preferencia, **Docker Desktop** y a otra cosa. Si te
> importa el modelo sin daemon o el rootless, **Podman**. Si quieres control fino de la VM o no
> quieres Docker Desktop por licencia, **Colima**. Los tres corren el laboratorio.

### 6.4 Verifica el tuyo, sea cual sea

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase15 \
  bash -c 'echo "amd64 → $(uname -m)  node $(node -p process.arch)"'

docker run --rm --platform linux/arm64 legacy-node-toolchain:arm64 \
  bash -c 'echo "arm64 → $(uname -m)  node $(node -p process.arch)"'
```
```text
amd64 → x86_64  node x64
arm64 → aarch64  node arm64
```

Si las dos responden, tu motor sabe hacer las dos cosas y ya puedes elegir por criterio en lugar
de por lo que funcione.

---

## 7. 💾 El nombre del volumen crece

Aquí está la consecuencia práctica más importante de la fase, y la que produce los fallos más
desconcertantes.

**ABI de Node y arquitectura son dos ejes independientes:**

```text
                   amd64            arm64
    Node 10   │  módulos A      │  módulos B   │
    Node 12   │  módulos C      │  módulos D   │
    Node 14   │  módulos E      │  módulos F   │
    Node 16   │  módulos G      │  módulos H   │

    ocho combinaciones, ocho node_modules distintos e incompatibles entre sí
```

[F01](01-decisiones-debian-zonas-node.md) te hizo poner la generación de Node en el nombre del volumen. **En un host donde puedes
construir para dos arquitecturas, eso ya no basta:**

> ⚠️ **El volumen de Node 10 amd64 NO es el volumen de Node 10 arm64.** Tienen el mismo
> `NODE_MODULE_VERSION` —64 en los dos— y binarios completamente incompatibles. El error de ABI
> de [F14](14-abi-libc-y-prebuilds.md) §5.1 **no aparece**, porque el ABI coincide; lo que aparece es un `exec format error`
> o un `invalid ELF header` en el momento de cargar el addon.

**La convención que resuelve esto:**

```text
<proyecto>-node<major>-<arch>-modules
```

```text
legacy-vue2-node10-amd64-modules
legacy-vue2-node10-arm64-modules
legacy-angular8-node10-amd64-modules
legacy-angular8-node10-arm64-modules
```

Y si algún día necesitas precisión de patch en un diagnóstico especialmente delicado:

```text
legacy-vue2-node10.24.1-arm64-modules
```

```bash
docker volume create legacy-vue2-node10-amd64-modules
docker volume create legacy-vue2-node10-arm64-modules
```

> 🧭 **Nunca compares dos arquitecturas usando el mismo volumen.** Es el error que arruina
> silenciosamente cualquier comparación: crees estar midiendo arm64 y estás cargando binarios
> amd64 que quedaron de antes.

---

## 8. 🧬 Las cuatro categorías multiplataforma

Cualquier dependencia npm cae en una de estas cuatro, y saber en cuál está te dice qué esperar
en ARM64.

| | Categoría | Comportamiento en ARM64 | Ejemplos |
|---|---|---|---|
| **A** | JavaScript puro | 🟢 funciona igual, sin más | `lodash`, `vue`, `react` |
| **B** | Nativa con prebuild ARM64 | 🟢 descarga y funciona | paquetes mantenidos hoy |
| **C** | Nativa **sin** prebuild ARM64 | 🟡 compila — si tienes toolchain y las librerías | `node-sass@4`, `canvas@2` |
| **D** | Descarga un binario que no existe para ARM64 | 🔴 falla, y hay que aportarlo tú | Puppeteer 5, Cypress antiguo |

**La clasificación decide tu ruta.** Si tu proyecto es todo A y B, la ruta 1 —arm64 nativo—
funciona y es rápida. Si tiene C, funciona compilando. Si tiene D, la ruta 2 es más simple que
pelearse.

```bash
# clasifica el árbol de tu proyecto, aproximadamente
find node_modules -name '*.node' -exec sh -c \
  'printf "%-55s " "$1"; file -b "$1" | cut -d, -f2' _ {} \;
```

Todo lo que aparezca ahí es categoría B o C, y su arquitectura te dice cuál.

---

## 9. ⚠️ Errores comunes y diagnóstico

**`exec format error` al cargar un addon, con el ABI correcto.** Volumen contaminado entre
arquitecturas. §7.

**`npm ci` tarda muchísimo en arm64.** Estás compilando categoría C. Es esperado, y **[F23](23-estudios-de-caso-multiplataforma.md)**
pone números.

**El prebuild descarga y no funciona.** Bajó el de x64. `file` sobre el `.node` lo confirma en
un segundo.

**"En arm64 funciona más rápido pero falla un test".** Perfectamente posible: son entornos
distintos. Por eso la matriz de [F20](20-validacion-sistematica-y-evidencia.md) §7 debería tener una columna más.

**Docker Desktop parece ignorar `--platform`.** Comprueba que la imagen tiene esa plataforma en
su index, y `uname -m` dentro para confirmar qué te dio.

**Puppeteer no arranca en arm64.** Categoría D. **[a09](a09-browsers-legacy.md) §6** tiene las tres salidas.

**Todo funciona en mi Mac y falla en el CI.** El CI es amd64 y tú estabas en arm64 nativo — o
al revés. Es la razón de declarar `--platform` siempre.

---

## 10. 📋 Checklist de validación

```text
[ ] Sabes cuál de las cinco rutas estás usando, y por qué
[ ] Distingues la Rosetta de macOS de la traducción dentro de la VM
[ ] Tu motor arranca contenedores amd64 y arm64, comprobado con §6.4
[ ] Sabes si tu Docker Desktop usa Rosetta o QEMU
[ ] Tus volúmenes llevan generación de Node Y arquitectura en el nombre
[ ] Clasificaste las dependencias nativas de tu proyecto en A, B, C o D
[ ] Provocaste la contaminación cruzada de volúmenes y viste su error
[ ] Sabes qué ruta usarías si tu proyecto tuviera una dependencia categoría D
```

---

## 11. 🧪 Ejercicios de la Fase 22 (22)

## 🟢 Fácil — conocer tu host (1–6)

### 🟢 Ejercicio 1 — Qué motor tienes

Ejecuta los comandos de §6 correspondientes a tu motor y anota versión, arquitectura y sistema.

### 🟢 Ejercicio 2 — Las dos arquitecturas

Ejecuta las dos comprobaciones de §6.4.

**Pregunta:** ¿responden las dos? ¿Cuál tardó más en arrancar?

### 🟢 Ejercicio 3 — Node no existe nativo

Comprueba en `nodejs.org/dist/v10.24.1/` que no hay `darwin-arm64`, y que sí hay
`linux-arm64`.

**Objetivo:** volver al argumento de [F00](00-problema-y-contrato.md) §3.1 ahora que entiendes el mecanismo entero.

### 🟢 Ejercicio 4 — Qué hace tu `nvm`

Si tienes `nvm` en un Mac ARM, instala Node 10 y ejecuta `node -p process.arch` y
`file $(which node)`.

**Pregunta:** ¿qué arquitectura es? ¿Quién lo está traduciendo?

### 🟢 Ejercicio 5 — Rosetta o QEMU

Busca en la configuración de tu Docker Desktop la opción de Rosetta y anota si está activa.

### 🟢 Ejercicio 6 — Clasifica tu proyecto

Ejecuta el `find` de §8 sobre tu `node_modules` y clasifica lo que encuentres.

**Pregunta:** ¿cuántos artefactos nativos hay? ¿De qué arquitectura son?

## 🟡 Intermedio — las dos arquitecturas en paralelo (7–13)

### 🟡 Ejercicio 7 — Dos volúmenes

Crea los dos volúmenes de §7 con la convención completa.

### 🟡 Ejercicio 8 — El mismo proyecto, dos arquitecturas

Instala un fixture en arm64 y en amd64, cada uno con su volumen, y compara los tiempos.

**Objetivo:** la primera medición honesta de la diferencia, en tu máquina.

### 🟡 Ejercicio 9 — Un fixture de cada categoría

Instala en arm64 un paquete de cada categoría de §8 y anota qué pasó con cada uno.

**Objetivo:** la tabla comprobada en tu máquina en lugar de leída.

### 🟡 Ejercicio 10 — Rosetta contra QEMU

Con Docker Desktop, activa y desactiva Rosetta y repite el ejercicio 8.

**Pregunta:** ¿cuánto cambió? Guarda los números: son la materia prima de **[F23](23-estudios-de-caso-multiplataforma.md)**.

### 🟡 Ejercicio 11 — Prueba otro motor

Instala Podman Desktop o Colima y ejecuta la comprobación de §6.4.

**Pregunta:** ¿funcionó igual? ¿Qué comando tuviste que cambiar?

### 🟡 Ejercicio 12 — La VM por dentro

Averigua cuántos CPU y cuánta RAM tiene la VM de tu motor, y cámbialo.

**Pregunta:** ¿afecta al tiempo del ejercicio 8? ¿Dónde está el cuello de botella?

### 🟡 Ejercicio 13 — El contenedor que arrancó en la arquitectura que no pediste

En un Mac ARM, `docker run` sin `--platform` no siempre te da lo que crees, y el aviso —cuando
aparece— es fácil de perderse entre el resto de la salida. Prepara el diagnóstico:

```bash
docker run --rm debian/eol:buster uname -m          # sin pedir nada
docker run --rm --platform linux/amd64 debian/eol:buster uname -m
docker image inspect debian/eol:buster --format '{{.Architecture}}'
```

**Objetivo:** determinar, para **cada** imagen que tengas descargada, en qué arquitectura se
ejecutaría hoy si la arrancaras sin `--platform`, y con qué regla lo decide el motor. Hay tres
factores en juego: lo que el index ofrece, lo que tu máquina es, y **cuál de las variantes ya
tienes en el almacén local**.

**Pregunta:** el tercer factor es el que produce el fallo desconcertante. Si un compañero
descargó primero la variante amd64 y tú la arm64, el mismo `docker run` sin `--platform` os da
imágenes distintas **con el mismo tag y el mismo comando**. Comprueba que es así y escribe la
línea que tiene que aparecer en cualquier informe de fallo para que esto no os cueste una
tarde.

## 🟠 Difícil — cuando la arquitectura es la causa (14–19)

### 🟠 Ejercicio 14 — Contamina a propósito

Instala en amd64 y ejecuta en arm64 **reutilizando el volumen**.

**Objetivo:** obtener el error de §7 y comprobar que **no** menciona la arquitectura ni el
volumen.

### 🟠 Ejercicio 15 — La matriz con arquitectura

Amplía la matriz de [F20](20-validacion-sistematica-y-evidencia.md) §7 con una columna más: las dos arquitecturas.

**Objetivo:** una tabla 4×2×3 de tu proyecto. Es la evidencia real de en qué combinaciones
es viable.

### 🟠 Ejercicio 16 — El `node_modules` misterioso

Alguien te pasa un `node_modules` sin decirte de dónde salió. Determina generación de Node y
arquitectura.

**Objetivo:** dos comandos y una conclusión. Es [F14](14-abi-libc-y-prebuilds.md) §8 más lo de esta fase.

### 🟠 Ejercicio 17 — El fallo que solo pasa en el CI

Configura tu laboratorio en arm64 nativo y ejecuta la validación en un contenedor amd64,
simulando el CI.

**Objetivo:** encontrar la primera diferencia y decir si es de la dimensión 1 o de la 5 de
[F21](21-arquitecturas-y-emulacion.md) §8.

### 🟠 Ejercicio 18 — Categoría D en ARM64

Instala Puppeteer 5 en arm64 y diagnostica el fallo hasta la causa.

**Pregunta:** ¿falla al descargar o al ejecutar? Aplica la salida de **[a09](a09-browsers-legacy.md) §6** y comprueba que
funciona.

### 🟠 Ejercicio 19 — Diagnostica una máquina que no es la tuya

El caso real de un equipo mixto: alguien reporta que el laboratorio "va lentísimo" y no sabes
ni qué máquina tiene. Sin verla, tienes que averiguar en cuál de las cinco rutas de §4 está.

**Objetivo:** escribir el bloque de comandos —uno solo, copiable— que le mandarías, y que
tiene que responder a **seis** preguntas: qué CPU tiene el host, qué motor y qué versión, si
hay emulación activa y de qué tipo, cuántos recursos tiene la VM, en qué arquitectura corre la
imagen que usa, y dónde vive su `node_modules`.

Pruébalo contigo mismo primero y comprueba que la salida cabe en un mensaje.

**Pregunta:** con esa salida delante, construye el **árbol de decisión** que va de las seis
respuestas a una de las cinco rutas de §4. Y responde a la que separa este ejercicio de una
lista de comandos: de las seis preguntas, ¿cuáles **descartan** rutas enteras de un plumazo y
cuáles solo afinan? Ordena tu bloque para que las que más descartan salgan primero — es lo
mismo que hace el protocolo de 60 segundos de
[F30](30-troubleshooting-metodo-y-herramientas.md), aplicado aquí.

## 🔴 Muy difícil — convención y migración (20–22)

### 🔴 Ejercicio 20 — Elige la ruta con datos

Para tu proyecto real, ejecuta la validación en las rutas 1 y 2 y compara: tiempo, qué compiló,
qué falló.

**Objetivo:** una recomendación con tres datos, no con una intuición.

### 🔴 Ejercicio 21 — Migra tus volúmenes a la convención nueva

Tienes volúmenes creados en [F09](09-montar-tu-proyecto.md) con el formato `<proyecto>-node<major>-modules`, sin
arquitectura. Migra los de un proyecto a la convención de §7 **sin perder las instalaciones que
siguen siendo válidas**.

**Pregunta:** ¿puedes saber de qué arquitectura es cada volumen existente sin reinstalarlo?
Investígalo con `docker run` y `file` antes de decidir cuáles conservas y cuáles rehaces.

### 🔴 Ejercicio 22 — La convención de nombres definitiva

Diseña la convención completa de tu equipo: contenedores, volúmenes e imágenes, para seis
proyectos × tres generaciones de Node × dos arquitecturas.

**Objetivo:** que sea legible, que evite colisiones, y que permita borrar todo lo de un proyecto
sin tocar lo demás. Escribe el comando que hace ese borrado y compruébalo.

## 🔥 Opcionales

### 🔥 Ejercicio 23 — Una VM x86-64 completa

Con Colima o UTM, arranca una VM x86-64 en tu Mac ARM y ejecuta el laboratorio dentro.

**Pregunta:** ¿cuánto más lento que la ruta 2? Ahí tienes la diferencia entre los dos QEMU de
[F21](21-arquitecturas-y-emulacion.md) §7.2, medida.

### 🔥 Ejercicio 24 — El árbol de decisión

Convierte §4 en un diagrama de decisión con preguntas concretas —"¿tiene dependencias
categoría D?"— que lleve a una ruta.

**Objetivo:** algo que un compañero pueda seguir sin haber leído la fase.

## 💀 Boss fight

### 💀 Ejercicio 25 — Boss fight: el equipo de tres máquinas

Tu equipo tiene un Mac M3, un PC Linux Intel y un Windows con WSL2. El proyecto legacy tiene una
dependencia de categoría C y otra de categoría D.

**Objetivo:** producir **una** configuración que funcione en las tres, con su justificación. Vas
a tener que decidir arquitectura, motor, convención de volúmenes y qué hacer con la dependencia
D — y algunas decisiones van a incomodar a alguien. La entrega es el `run-dev.sh` que funciona
en las tres, el `README` de dos párrafos que lo explica, y **la lista de lo que sacrificaste en
cada plataforma**, que es la parte honesta y la que más vale.

---

## 12. 📚 Referencias

**Motores en Apple Silicon**
- Docker Desktop en Mac: https://docs.docker.com/desktop/setup/install/mac-install/
- Rosetta para emulación x86 en Docker Desktop: https://docs.docker.com/desktop/settings-and-maintenance/settings/
- Podman Desktop: https://podman-desktop.io/docs
- Podman machine: https://docs.podman.io/en/latest/markdown/podman-machine.1.html
- Colima: https://github.com/abiosoft/colima

**Apple**
- Apple Virtualization Framework: https://developer.apple.com/documentation/virtualization
- Binarios Intel en VM Linux — la fuente de §5.1, con lo de macOS 27: https://developer.apple.com/documentation/virtualization/running-intel-binaries-in-linux-vms

> ⚠️ **Esta es la fase del curso que más rápido envejece.** Docker Desktop, Podman Desktop y
> Colima cambian varias veces al año, y el estado de Rosetta depende de decisiones de Apple. Los
> **mecanismos** de [F21](21-arquitecturas-y-emulacion.md) son estables; los nombres de las opciones y el comportamiento exacto de
> los productos, no. Verifica antes de decidir. Enlaces revisados el 3 de septiembre de 2026.

**Orden de lectura sugerido:** la documentación de tu motor primero, y la de Rosetta para Linux
si el ejercicio 10 te dio una diferencia grande.

---

## 13. 🏁 Resultado de la fase

```text
EL PUNTO DE PARTIDA   en Apple Silicon no hay Node legacy nativo
                      la pregunta es DÓNDE ocurre la traducción y quién la administra

CINCO RUTAS           1 arm64 nativo · 2 amd64 traducido (baseline)
                      3 nvm + Rosetta (no recomendada) · 4 VM completa · 5 CI remoto

DOS ROSETTAS          apps de macOS ≠ traducción dentro de la VM Linux
                      la primera es implícita; la segunda va en tu --platform
                      y van a sitios distintos: la segunda se INTEGRA en macOS 27,
                      así que el baseline amd64 no tiene fecha de caducidad

TRES MOTORES          Docker Desktop · Podman Desktop · Colima
                      los tres corren el laboratorio; eliges por modelo, no por si sirve

VOLÚMENES             <proyecto>-node<major>-<arch>-modules
                      ABI y arquitectura son EJES DISTINTOS: ocho combinaciones

CUATRO CATEGORÍAS     A puro · B prebuild ARM64 · C compila · D no existe para ARM64
                      la categoría de tus dependencias decide tu ruta
```

> **La señal de que quedó bien:** *"sé en qué ruta estoy, la elegí con datos, y mis volúmenes
> llevan la arquitectura en el nombre — así que ya no tengo fallos que 'aparecen y desaparecen'
> al cambiar de plataforma."*

En **[F23](23-estudios-de-caso-multiplataforma.md)** ponemos números: `node-sass` y `canvas` en ARM64, la matriz de validación real, y
microbenchmarks sin vender humo.
