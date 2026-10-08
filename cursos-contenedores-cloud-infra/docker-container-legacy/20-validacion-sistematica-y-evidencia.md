# 📜 Parte II · Fase 20 — Validación sistemática: arqueología, evidencia y método

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · Node 10.24.1 baseline
> **Fixtures:** `src/11-validar-tu-proyecto/`
> **Requisitos:** **[F11](11-validar-tu-proyecto.md)** (el protocolo de ocho pasos) y **[F14](14-abi-libc-y-prebuilds.md)** (dependencias nativas)
> **Fecha de verificación ejecutada:** 6 de septiembre de 2026 — la matriz de §7.1 está corrida sobre Docker 29.6.2, imagen `linux/amd64` bajo emulación en macOS Apple Silicon
> **Estado de la imagen al terminar:** sin cambios
> **Objetivo:** investigar un proyecto **antes** de ejecutarlo, producir evidencia que sirva para investigar, y reducir un problema hasta su causa mínima

---

## 1. 🧭 Dónde estamos

[F11](11-validar-tu-proyecto.md) te dio un protocolo de ocho pasos y te hizo producir un `VALIDATION-REPORT.md`. Funcionaba,
y tenía un hueco deliberado: **empezaba ejecutando**.

Esta fase pone lo que va antes y lo que va después. Antes: la arqueología, que es mirar el
proyecto y formular una hipótesis **sin tocar nada**. Después: la evidencia, la matriz, los
fallos provocados y el método de reducción.

Es la fase que convierte "probé cosas hasta que funcionó" en algo que se puede repetir y
defender.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder:

- Datar un proyecto por sus artefactos y formular una **hipótesis de Node** antes de instalar.
- Ordenar las fuentes de evidencia por fiabilidad, y saber cuál miente más.
- Producir logs que sirvan de verdad — incluido el `PIPESTATUS`, que casi nadie usa.
- Construir una **matriz de compatibilidad** de tu proyecto contra las cuatro generaciones.
- Provocar fallos a propósito para saber cómo se ven antes de sufrirlos.
- Reducir un problema hasta el caso mínimo que lo reproduce.

---

## 3. 🚧 Qué NO entra todavía

- El **método formal de diagnóstico** —hipótesis falsables, taxonomía de capas, los
  anti-patrones con nombre— → **[F30](30-troubleshooting-metodo-y-herramientas.md)**, que generaliza esto a cualquier fallo.
- El **catálogo de fallos** por síntoma → **[F31](31-catalogo-de-fallos-i.md)** y **[F32](32-catalogo-de-fallos-ii.md)**.
- El **proyecto final**, que es este método aplicado a un repositorio sin instrucciones →
  **[F34](34-proyecto-final.md)**.

---

## 4. 🛑 Regla cero: no cambies nada todavía

El reflejo natural ante un proyecto que no arranca es `npm install` y ver qué pasa. Es
comprensible y destruye información.

> 🧭 **Antes de ejecutar nada:** registra el estado exacto en el que recibiste el proyecto.
> Después ya no vas a poder.

```bash
git rev-parse HEAD                          > evidencia/commit.txt
git status --porcelain                      > evidencia/working-tree.txt
sha256sum package.json package-lock.json    > evidencia/hashes.txt
```

Ese `sha256sum` del lockfile es la línea que más rentabilidad da de toda la fase: cuando dentro
de dos horas te preguntes *"¿esto lo cambié yo?"*, tienes la respuesta.

---

## 5. 🏺 Arqueología: datar el proyecto sin ejecutarlo

Con los dos archivos que todo proyecto Node tiene, se puede llegar bastante lejos.

### 5.1 `package.json`: lo que el proyecto dice de sí mismo

```bash
jq '{engines, scripts, dependencies, devDependencies}' package.json
```

**`engines`** es la declaración explícita, y es el **nivel 1** de [F11](11-validar-tu-proyecto.md) §4: lo que el proyecto
*dice* necesitar, no lo que se ha demostrado.

```json
{ "engines": { "node": ">=8.10" } }
```

Léelo con cuidado. Eso no dice "funciona con Node 20". Dice "el autor esperaba al menos Node
8.10", y era cierto **en su día**, con las dependencias que se resolvían entonces.

**Los rangos de SemVer** son la segunda pista:

| Rango | Qué permite | Qué significa para ti |
|---|---|---|
| `4.14.1` | esa versión exacta | el autor la fijó a propósito. Respétalo |
| `~4.14.0` | parches: `4.14.x` | variación mínima |
| `^4.14.0` | menores: `4.x` | **aquí vive la sorpresa** |
| `*` o `latest` | lo que haya | sin lockfile, esto es una lotería |

> ⚠️ **El `^` es el que envejece mal.** `"webpack": "^4.0.0"` en 2018 resolvía la 4.16; hoy
> resolvería la 4.46, que nadie probó con tu código. **El lockfile es lo único que te salva de
> eso**, y por eso [F11](11-validar-tu-proyecto.md) §5.2 insiste tanto.

### 5.2 `package-lock.json`: lo que realmente se instaló

```bash
jq '{lockfileVersion, name}' package-lock.json
```

**`lockfileVersion` data el proyecto con sorprendente precisión:**

| Versión | Generada por | Época aproximada |
|---|---|---|
| **1** | npm 5 y 6 | 2017–2020 |
| **2** | npm 7 y 8 | 2020–2022 |
| **3** | npm 9 y posteriores | 2022 en adelante |

Un `lockfileVersion: 1` te está diciendo **npm 6**, y npm 6 te está diciendo **Node 10, 12 o
14** — que es exactamente el rango de este laboratorio. Es la pieza de datación más fiable que
vas a encontrar.

> 🩺 **Y la incoherencia que hay que buscar.** Un `lockfileVersion: 2` en un proyecto cuyo
> `package.json` habla de Angular 8 significa que **alguien lo regeneró con npm moderno** en
> algún momento. Ese lockfile ya no representa lo que el proyecto probó, y ahí tienes tu
> primera hipótesis de por qué no funciona.

### 5.3 Las otras fuentes, ordenadas por fiabilidad

```mermaid
flowchart TD
    MAS(["más fiable"]) --> A["package-lock.json<br/>lo que se instaló de verdad"]
    A --> B["el CI histórico<br/>.travis.yml, .gitlab-ci.yml, workflows: dicen qué Node usaban"]
    B --> C[".nvmrc<br/>la versión que el equipo usaba en local"]
    C --> D["engines<br/>lo que el autor esperaba"]
    D --> E["la fecha de los commits<br/>te da la época"]
    E --> F["el README<br/>a menudo desactualizado"]
    F --> G["los comentarios del código"] --> MENOS(["menos fiable"])
```

> 🧭 **El CI histórico es la joya escondida.** Un `.travis.yml` con `node_js: - "10"` es
> evidencia de que el proyecto **pasaba sus tests** con Node 10, que es mucho más fuerte que
> cualquier declaración. Búscalo siempre: `ls -a` y mira los archivos de configuración.

### 5.4 Los scripts, antes de ejecutarlos

```bash
jq -r '.scripts | to_entries[] | "\(.key)\t\(.value)"' package.json
```

Léelos buscando tres cosas:

- **Qué CLI invoca cada uno**, y si esa CLI está en `devDependencies` (bien, [F01](01-decisiones-debian-zonas-node.md) §7.2) o se
  asume global (problema).
- **Variables de entorno en el propio script** —`NODE_ENV=production`, `HOST=0.0.0.0`— que te
  dicen cómo se ejecutaba.
- **Rutas absolutas o comandos del sistema** que quizá no existan en Debian 10.

```bash
# ¿está la CLI donde debería?
ls node_modules/.bin/ | grep -E 'ng|vue-cli-service|webpack|react-scripts'
```

Si `npm run build` invoca `ng build` y no hay `ng` en `node_modules/.bin`, el proyecto asume una
CLI global — y ahí tienes otra hipótesis antes de haber ejecutado nada.

### 5.5 Escribe la hipótesis

Con todo lo anterior, **antes** de instalar:

```markdown
## Hipótesis inicial
- Node esperado: 10.x
- Evidencia: lockfileVersion 1, .travis.yml con node_js 10, @vue/cli-service 3.12
- Riesgos: node-sass 4.14.1 (nativo, caso C), engines dice >=8 pero el CI usaba 10
- Predicción: instala y construye; los tests pueden fallar por Jest y jsdom
```

Escribirla tiene dos efectos. Te obliga a mirar la evidencia, y **te da algo contra lo que
contrastar** — porque cuando la hipótesis falla, la diferencia entre lo que esperabas y lo que
pasó es el hallazgo.

---

## 6. 🧾 Evidencia: logs que sirvan para investigar

Un log que solo dice "falló" no es evidencia. Estos son los tres detalles que lo convierten en
algo útil.

### 6.1 Captura los dos canales

```bash
npm ci > install.log 2>&1
```

**`2>&1` redirige `stderr` al mismo sitio que `stdout`**, y el orden importa: `2>&1 > archivo`
**no** hace lo mismo —manda `stderr` a donde apuntaba `stdout` *antes* de la redirección, es
decir, a la terminal—. Es de los errores de shell más frecuentes.

### 6.2 Ver y guardar a la vez: `tee`

```bash
npm ci 2>&1 | tee install.log
```

`tee` escribe al archivo **y** a la pantalla. Es lo que quieres en una instalación de diez
minutos que quizá tengas que interrumpir.

### 6.3 Y aquí está la trampa: `PIPESTATUS`

```bash
npm ci 2>&1 | tee install.log
echo $?      # ⚠️ este es el exit code de TEE, no de npm
```

**`$?` devuelve el estado del último comando de la tubería**, que es `tee` — y `tee` casi
siempre tiene éxito. Un script mal escrito registra `exit=0` en un paso donde npm explotó
treinta líneas antes. 😬

Las dos formas correctas:

```bash
# opción A: pipefail hace que la tubería refleje el fallo
set -o pipefail
npm ci 2>&1 | tee install.log
echo "exit=$?"

# opción B: PIPESTATUS te da el estado de CADA comando
npm ci 2>&1 | tee install.log
echo "npm=${PIPESTATUS[0]} tee=${PIPESTATUS[1]}"
```

> 🧠 **El patrón a memorizar.** Cada vez que veas `| tee` en un script de validación o de CI,
> comprueba si mira `${PIPESTATUS[0]}` o `$?`. Si es lo segundo, ese pipeline **puede estar
> reportando éxitos falsos** — y lo lleva haciendo desde que se escribió.

### 6.4 Más verbosidad cuando hace falta

```bash
npm ci --loglevel verbose 2>&1 | tee install-verbose.log
```

Y npm 6 deja además su propio log de fallos:

```bash
ls ~/.npm/_logs/
cat ~/.npm/_logs/*-debug.log | tail -100
```

> ⚠️ **Ese directorio vive en `$HOME` del contenedor.** Si el contenedor es efímero, el log
> muere con él. Cópialo antes de salir, o monta `$HOME` en algún sitio que sobreviva.

### 6.5 La convención de expediente

```text
validacion/20260904-mi-proyecto/
├── commit.txt · working-tree.txt · hashes.txt   ← §4, antes de tocar nada
├── toolchain.txt · runtime.txt                  ← F11 pasos 1 y 2
├── install.log · test.log · build.log
├── exit-codes.txt                               ← con PIPESTATUS
└── VALIDATION-REPORT.md
```

Un directorio por intento, con fecha. Cuando pruebes con otra generación de Node, es otro
directorio — y así puedes comparar.

---

## 7. 📊 La matriz de compatibilidad

Un veredicto sobre **una** combinación es un punto. Una matriz es un mapa.

```bash
for v in 10.24.1 12.22.12 14.21.3 16.20.2; do
  vol="miproyecto-node${v%%.*}-modules"
  docker volume rm "$vol" 2>/dev/null || true
  docker volume create "$vol" >/dev/null

  echo "=== Node $v"
  docker run --rm --platform linux/amd64 \
    -e NODE_VERSION="$v" \
    --mount type=bind,src="$PWD",dst=/workspace \
    --mount type=volume,src="$vol",dst=/workspace/node_modules \
    legacy-node-toolchain:phase15 \
    bash -c 'npm ci >/dev/null 2>&1; echo "  install=$?"
             npm test  >/dev/null 2>&1; echo "  test=$?"
             npm run build >/dev/null 2>&1; echo "  build=$?"'
done
```

**Detalles con intención:**

- **Un volumen limpio por generación**, por lo de [F14](14-abi-libc-y-prebuilds.md) §5.1. Sin eso, la matriz miente.
- **Silenciamos la salida y guardamos el código.** Aquí queremos el mapa, no el detalle; el
  detalle se investiga después sobre la casilla que falló.
- **Cada fila es independiente.** Ninguna hereda estado de la anterior.

El resultado es una tabla que se lee de un vistazo. Esta es **inventada a modo de ejemplo** —la
medida de verdad viene en §7.1— y muestra la forma que tiene un resultado interesante:

| Node | `npm ci` | tests | build | Veredicto |
|---|---|---|---|---|
| 10.24.1 | ✅ | ✅ | ✅ | **compatible hasta nivel 4** |
| 12.22.12 | ✅ | ✅ | ✅ | compatible |
| 14.21.3 | ✅ | ❌ | ✅ | tests fallan — investigar |
| 16.20.2 | ❌ | — | — | no instala — npm 8 y el lock v1 |

> 🧭 **Qué te da la matriz que no da un veredicto suelto:** el **rango** de generaciones
> viables, que es lo que de verdad decide si un proyecto es mantenible. Y las casillas que
> fallan te dicen dónde investigar, en lugar de dejarte con "no funciona".

### 7.1 La matriz del fixture de control, medida

Hazla también con `00-node-smoke`, que no tiene dependencias. Su lógica es la de un fusible:

```text
si el fixture de control pasa en las cuatro   → el laboratorio está bien; el problema es tuyo
si falla en alguna                            → arregla el laboratorio antes de seguir
```

Es el mismo razonamiento de [F11](11-validar-tu-proyecto.md) §5.1, ahora aplicado a las cuatro
generaciones a la vez. Y como esta es la única casilla del curso que garantiza que la imagen
sirve para lo que promete, aquí no vale un ejemplo: **está corrida**. Esto es lo que devuelve
el bucle de §7 sobre `src/11-validar-tu-proyecto/00-node-smoke/`, sin editar:

```text
=== Node 10.24.1
legacy-node-toolchain: Node 10.24.1
  install=0
  test=0
  build=0
=== Node 12.22.12
legacy-node-toolchain: Node 12.22.12
  install=0
  test=0
  build=0
=== Node 14.21.3
legacy-node-toolchain: Node 14.21.3
  install=0
  test=0
  build=0
=== Node 16.20.2
legacy-node-toolchain: Node 16.20.2
  install=0
  test=0
  build=0
```

Doce ceros de doce. La matriz correspondiente:

| Node | npm que trae | `npm ci` | tests | build | Veredicto |
|---|---|---|---|---|---|
| 10.24.1 | 6.14.12 | ✅ | ✅ | ✅ | **baseline del laboratorio** |
| 12.22.12 | 6.14.16 | ✅ | ✅ | ✅ | compatible |
| 14.21.3 | 6.14.18 | ✅ | ✅ | ✅ | compatible |
| 16.20.2 | 8.19.4 | ✅ | ✅ | ✅ | compatible |

> ⚠️ **Un fusible que no salta no dice que la instalación sea segura; dice que el fusible
> funciona.** `00-node-smoke` no tiene ni una dependencia y su lock declara
> `"lockfileVersion": 1` con cero entradas, así que ni siquiera pone a prueba lo que más se
> rompe al saltar de generación: la resolución de dependencias y los addons nativos. Que las
> cuatro casillas den `0` significa exactamente esto y nada más: **la imagen arranca, el shim
> de `NODE_VERSION` conmuta bien, el bind mount monta, el volumen de `node_modules` no
> estorba y `npm` sabe correr un script en las cuatro generaciones.** Es justo lo que un
> control tiene que probar.

📝 **Y fíjate en la columna del npm, que es la que explica los fallos que vas a ver luego.**
Las tres primeras generaciones traen npm 6; la 16 salta a npm 8. Ese salto es el que produce el
`npm ci` roto de la tabla de ejemplo de §7 —npm 8 es mucho menos tolerante con un lock v1 que
declara dependencias, y con los `peerDependencies` que npm 6 se saltaba en silencio—. Aquí no
salta porque no hay dependencias que resolver. En tu proyecto sí las hay, y por eso la matriz
del proyecto y la del control son dos matrices distintas.

---

## 8. 💥 Fallos provocados: conocerlos antes de sufrirlos

Provocar fallos a propósito, en un entorno controlado, es la forma barata de aprender a
reconocerlos. Estos ocho cubren casi todo lo que te vas a encontrar.

| Provocación | Qué error verás | Capa |
|---|---|---|
| Cambiar una versión en `package.json` sin tocar el lock | `npm ci` rechaza: fuera de sincronía | lockfile |
| Instalar con Node 10 y ejecutar con Node 14 | `NODE_MODULE_VERSION 64 vs 83` | ABI ([F14](14-abi-libc-y-prebuilds.md)) |
| Quitar `libcairo2-dev` e instalar `canvas` | `pkg-config` no encuentra el paquete | sistema ([F15](15-laboratorios-dependencias-nativas.md)) |
| Cortar la red durante `npm ci` | `ETIMEDOUT` o `ENOTFOUND` | red |
| Montar el directorio equivocado | `ENOENT: package.json` | montaje ([F09](09-montar-tu-proyecto.md)) |
| Correr con `--user` sin preparar el volumen | `EACCES` en `node_modules` | permisos ([F17](17-usuarios-permisos-y-volumenes.md)) |
| Arrancar el dev server en `127.0.0.1` | arranca y no responde | red ([F18](18-networking-de-contenedores.md)) |
| Construir para `arm64` y ejecutar en `amd64` | `exec format error` | arquitectura ([F21](21-arquitecturas-y-emulacion.md)) |

> 🧭 **Provócalos sobre un fixture, no sobre tu proyecto.** El objetivo es reconocer el
> mensaje, no arreglar nada. Media hora aquí ahorra horas después, porque el reconocimiento es
> instantáneo y el diagnóstico a ciegas no lo es.

---

## 9. 🔬 Reducir el problema hasta el caso mínimo

Cuando algo falla y no sabes por qué, la técnica que más rinde es **reducir**: quitar variables
hasta que quede la mínima cosa que todavía falla.

```mermaid
flowchart TD
    T["tu proyecto entero falla"] --> Q1{"¿falla el fixture de control?"}
    Q1 -- "sí" --> LAB["el problema es el laboratorio"]
    Q1 -- "no" --> Q2["¿falla con solo las dependencias de producción?"]
    Q2 --> Q3["¿falla instalando una sola dependencia sospechosa?"]
    Q3 --> Q4["¿falla con un package.json de tres líneas?"]
    Q4 --> MIN["el caso mínimo que reproduce el fallo"]
```

**Las dos reglas de método**, que atraviesan el curso entero y que **[F30](30-troubleshooting-metodo-y-herramientas.md)** formaliza:

> 🧭 **Una variable a la vez.** Si cambias la versión de Node y el volumen y una dependencia,
> y funciona, no sabes cuál lo arregló — y la próxima vez vuelves a empezar.

> 🧭 **Reproducir antes de reparar.** Si no puedes provocar el fallo cuando quieras, no vas a
> poder demostrar que lo arreglaste. Un fallo intermitente que "ya no pasa" casi nunca está
> resuelto.

**Y el criterio de parada:** el caso mínimo es útil cuando cabe en un mensaje. Si puedes
escribir *"un `package.json` con solo `node-sass@4.14.1`, Node 14, falla con este error"*, tienes
algo que otra persona puede reproducir en dos minutos — y eso es lo que convierte un problema
tuyo en un problema resoluble.

---

## 10. 📐 Reproducibilidad: qué promete esta validación

Honestidad, como en [F12](12-capas-cache-y-contexto.md) §9. Tu `VALIDATION-REPORT.md` demuestra:

**Que en esta combinación exacta funcionó.** Imagen con su digest, versión de Node, lockfile
con su hash, arquitectura. Eso es sólido.

**Y no demuestra** que vaya a funcionar dentro de un año —las fuentes externas pueden
desaparecer, [F14](14-abi-libc-y-prebuilds.md) §7.1—, ni en otra arquitectura sin volver a medir, ni con otro motor sin
comprobarlo, ni que el proyecto esté libre de vulnerabilidades: `npm audit` sobre un proyecto
de 2018 va a devolver una lista larga, y arreglarla es otro trabajo distinto de este.

> ⚠️ **`npm audit fix` no es parte de la validación.** Reescribe el árbol de dependencias, que
> es justo lo que este protocolo intenta preservar. Si el proyecto tiene vulnerabilidades
> —las tiene—, eso es un hallazgo del reporte, no algo que arreglar a mitad de una validación.

---

## 11. ⚠️ Errores comunes y diagnóstico

**"El log dice exit=0 pero falló."** `PIPESTATUS`. §6.3, y revisa todos tus scripts.

**"Los logs están vacíos."** Falta `2>&1`, o el error salió por `stderr` y no lo capturaste.

**"El lockfile cambió y no sé cuándo."** Por eso el `sha256sum` de §4.

**"Funcionó con Node 12 pero no sé si con Node 10."** No hiciste la matriz. §7.

**"Cambié tres cosas y funcionó."** No sabes cuál. §9, y hay que volver atrás.

**"El error no se reproduce."** Falta una variable que no controlaste: el volumen, la caché, el
estado del contenedor. §9, regla de reproducir antes de reparar.

**"`npm audit` dice que hay 340 vulnerabilidades."** Es un proyecto de 2018. Es un hallazgo del
reporte, no un fallo de la validación. §10.

---

## 12. 📋 Checklist de validación

```text
[ ] Registraste commit, working tree y hashes ANTES de tocar nada
[ ] Dataste el proyecto con lockfileVersion y sabes qué npm lo generó
[ ] Buscaste el CI histórico y el .nvmrc
[ ] Escribiste la hipótesis inicial antes de instalar
[ ] Tus logs capturan stdout y stderr, y usan PIPESTATUS
[ ] Construiste la matriz 4×3 de tu proyecto
[ ] Construiste la matriz del fixture de control
[ ] Provocaste al menos cuatro de los ocho fallos de §8
[ ] Redujiste al menos un fallo a su caso mínimo
[ ] Tu reporte dice qué demuestra y qué no
```

---

## 13. 🧪 Ejercicios de la Fase 20 (25)

## 🟢 Fácil — leer antes de ejecutar (1–6)

### 🟢 Ejercicio 1 — Data cuatro proyectos

Toma los cuatro fixtures de framework y averigua su `lockfileVersion` y su `engines`.

**Pregunta:** ¿los cuatro dan la misma época? ¿Alguno tiene incoherencias?

### 🟢 Ejercicio 2 — Busca el CI histórico

En tres proyectos archivados de GitHub, busca su configuración de CI y localiza qué versiones
de Node probaban.

**Objetivo:** ver que la evidencia más fuerte suele estar en un archivo que nadie mira.

### 🟢 Ejercicio 3 — Lee los rangos

Extrae con `jq` todas las dependencias de un fixture y clasifícalas por tipo de rango.

**Pregunta:** ¿cuántas llevan `^`? ¿Qué pasaría sin lockfile?

### 🟢 Ejercicio 4 — El expediente

Crea la estructura de §6.5 para tu proyecto y captura los tres archivos de §4.

### 🟢 Ejercicio 5 — La trampa de `$?`

Ejecuta un comando que falle a través de `| tee` y compara `$?` con `${PIPESTATUS[0]}`.

**Objetivo:** ver la mentira con tus ojos.

### 🟢 Ejercicio 6 — `2>&1` y el orden

Prueba `cmd > f 2>&1` y `cmd 2>&1 > f` sobre un comando que escriba en los dos canales.

**Pregunta:** ¿qué acabó en el archivo en cada caso? ¿Por qué el orden importa?

## 🟡 Intermedio — hipótesis y matriz (7–13)

### 🟡 Ejercicio 7 — Los scripts, antes de correrlos

Lee los `scripts` de un fixture y predice qué CLI invoca cada uno y si está en
`node_modules/.bin`.

### 🟡 Ejercicio 8 — La hipótesis, escrita

Para tu proyecto real, escribe la hipótesis de §5.5 antes de ejecutar nada. Después valida.

**Pregunta:** ¿acertaste? Si no, ¿qué evidencia te habría hecho acertar?

### 🟡 Ejercicio 9 — La matriz de tu proyecto

Ejecuta el bucle de §7 sobre tu proyecto legacy.

**Objetivo:** la tabla 4×3 completa, con un volumen limpio por generación.

### 🟡 Ejercicio 10 — La matriz de control

Repite con `00-node-smoke`.

**Pregunta:** ¿pasa en las cuatro? Si falla alguna, ¿qué te dice eso antes de mirar tu proyecto?

### 🟡 Ejercicio 11 — Un log que sirve

Escribe el fragmento de script que ejecuta `npm ci`, guarda el log y registra el exit code
correcto.

**Objetivo:** que funcione tanto si npm falla como si no. Pruébalo en los dos casos.

### 🟡 Ejercicio 12 — El lockfile que cambió

Ejecuta `npm install` en lugar de `npm ci` sobre un fixture y compara el hash del lockfile.

**Pregunta:** ¿cuántas dependencias cambiaron de versión? Ahí está el argumento de §5.1 con
números.

### 🟡 Ejercicio 13 — La matriz del control, contra la salida real

§7.1 publica la matriz medida de `00-node-smoke`: doce ceros de doce. Reprodúcela tú y
compárala línea a línea con la que trae la fase.

**Objetivo:** obtener tus propios doce códigos de salida y, si alguno no es `0`, **arreglar el
laboratorio antes de seguir** — que es exactamente para lo que existe el fixture de control.

**Pregunta:** el ⚠️ de §7.1 dice que doce ceros significan cinco cosas concretas y **ninguna
más**. Enumera esas cinco de memoria y después compáralas con la fase. Y la que cierra el
razonamiento: tu proyecto real, ¿pasaría las cuatro casillas de `npm ci`? Si tu respuesta es
"seguramente no", explica qué tiene tu proyecto que `00-node-smoke` no tiene. Esa lista es el
mapa de lo que la matriz del control **no** cubre.

## 🟠 Difícil — evidencia que sirve (14–21)

### 🟠 Ejercicio 14 — Los logs de npm

Provoca un fallo de instalación y localiza el `debug.log` de npm dentro del contenedor.

**Pregunta:** ¿qué añade respecto a la salida que ya viste? ¿Sobrevivió al contenedor?

### 🟠 Ejercicio 15 — Verbose cuando hace falta

Repite una instalación que falla con `--loglevel verbose` y compara los dos logs.

**Objetivo:** encontrar la línea que solo aparece en el verbose y decidir si compensa el ruido.

### 🟠 Ejercicio 16 — Los ocho fallos

Provoca los ocho de §8 sobre fixtures y guarda el mensaje característico de cada uno.

**Objetivo:** un documento de referencia con ocho errores reales, tuyos, que vas a reconocer al
instante.

### 🟠 Ejercicio 17 — Reduce hasta el mínimo

Toma un fallo real —el del ejercicio 16 que más te costó— y redúcelo siguiendo §9.

**Objetivo:** llegar a un caso que quepa en cinco líneas y que otra persona pueda reproducir.

### 🟠 Ejercicio 18 — Una variable a la vez

Toma un proyecto que falle y cambia **tres** cosas a la vez hasta que funcione. Después vuelve
al estado inicial y hazlo de una en una.

**Pregunta:** ¿cuál era realmente? ¿Cuánto tardaste de cada forma? La segunda suele ser más
rápida, y eso sorprende.

### 🟠 Ejercicio 19 — El expediente que otro puede repetir

Escribe el expediente de un fallo real de tu proyecto siguiendo la convención de §6.5, y
después haz la única prueba que lo valida: **dáselo a alguien que no estaba** —o guárdalo tres
días y vuelve a él— y que intente reproducir el fallo **solo** con lo que hay dentro.

**Objetivo:** que la reproducción salga a la primera. Si la otra persona tiene que preguntarte
algo, ese algo es lo que le faltaba al expediente: anótalo y arréglalo.

**Pregunta:** haz la lista de lo que tuviste que añadir después de la prueba. Casi siempre
aparecen las mismas tres cosas —la versión exacta del motor, la arquitectura del host y el
estado del volumen— y casi siempre por el mismo motivo: **eran obvias para ti**. Escribe la
regla que te llevas sobre qué es "contexto obvio" en un informe técnico.

### 🟠 Ejercicio 20 — Los logs de npm, hasta el fondo

`npm ERR!` en la terminal es el resumen. El detalle está en el `debug.log`, que casi nadie
abre. Provoca un fallo de instalación real y ve a por él:

```bash
npm ci 2>&1 | tail -20
ls -t ~/.npm/_logs/ | head -3
tail -60 ~/.npm/_logs/$(ls -t ~/.npm/_logs/ | head -1)
```

**Objetivo:** encontrar en el `debug.log` **tres** cosas que no aparecían en la terminal: la
línea que dice qué estaba resolviendo cuando falló, la petición HTTP concreta si la hubo, y el
comando exacto que lanzó el `postinstall`.

**Pregunta:** ¿en qué se diferencia lo que ves con `--loglevel verbose` de lo que ya estaba en
el `debug.log`? Y la parte operativa que importa para el expediente de §6.5: **ese log vive
dentro del contenedor y muere con él.** Escribe cómo lo sacas —hay al menos dos formas— y
cuál de las dos incluirías en un script de validación.

### 🟠 Ejercicio 21 — El orden de `2>&1` importa, y aquí duele

El ejercicio fácil de redirección te hizo ver que `cmd > f 2>&1` y `cmd 2>&1 > f` no son lo
mismo. Ahora paga las consecuencias en un caso real. Escribe un script que ejecute `npm ci` y
guarde el log, **con el orden equivocado**, y úsalo para diagnosticar un fallo.

**Objetivo:** comprobar que el archivo de log resultante **no contiene el error**, aunque el
comando falló, y explicar exactamente por qué mirando el orden de las redirecciones. Después
arréglalo y compara los dos archivos.

**Pregunta:** ahora combínalo con `| tee` y con `PIPESTATUS`. Escribe la línea **correcta y
completa** que hace las cuatro cosas a la vez: muestra la salida, la guarda entera con los dos
canales, y conserva el código de salida **del comando**, no el del `tee`. Esa línea es la que
va en tu script de validación, y equivocarse en ella es la razón número uno de los CI que
"pasan" con el build roto.

## 🔴 Muy difícil — método bajo presión (22–25)

### 🔴 Ejercicio 22 — El fallo intermitente

Diseña un escenario que falle **a veces** —una caché que a veces está, un volumen que a veces
tiene restos— y determina qué lo hace intermitente.

**Objetivo:** entender por qué "ya no pasa" no es lo mismo que "está resuelto".

### 🔴 Ejercicio 23 — Amplía tu reporte con lo de esta fase

Toma el `VALIDATION-REPORT.md` que escribiste en [F11](11-validar-tu-proyecto.md) y añádele las cuatro cosas que esta fase
aporta: la datación con su evidencia, la hipótesis inicial contrastada con el resultado, la
matriz de las cuatro generaciones, y la sección honesta de qué **no** demuestra.

**Objetivo:** que la versión nueva responda una pregunta que la de [F11](11-validar-tu-proyecto.md) no podía: *"¿en qué rango
de versiones de Node es mantenible este proyecto?"*.

### 🔴 Ejercicio 24 — Audita un script de CI ajeno

Busca en GitHub un workflow de CI de un proyecto Node y audítalo: ¿usa `| tee` sin
`PIPESTATUS`? ¿`npm install` o `npm ci`? ¿fija la versión de Node? ¿guarda evidencia?

**Objetivo:** una lista de observaciones con la consecuencia concreta de cada una. Y encontrar
al menos un pipeline que pueda reportar éxitos falsos — los hay a montones.

### 🔴 Ejercicio 25 — Diseña el fallo intermitente de otro

El ejercicio de fallo intermitente te pedía diseñar uno. Este te pide lo contrario, que es más
difícil: **te dan uno y no sabes qué lo causa**.

Pídele a alguien que prepare un escenario que falle *a veces* —tiene material de sobra: una
caché que a veces está, un volumen que a veces se reutiliza, una dependencia que resuelve
distinto según el día, un `postinstall` que depende de la red— y **que no te diga cuál es**.

**Objetivo:** llegar a la causa aplicando las dos reglas del método —una variable a la vez, y
reproducir antes de reparar— y documentando cada hipótesis con la prueba que la descartó. Mide
además la **tasa**: ¿falla 1 de cada 3 o 1 de cada 20? Ese número cambia la estrategia entera.

**Pregunta de cierre:** ¿cuántas ejecuciones necesitaste para estar razonablemente seguro de
que lo arreglaste, y cómo decidiste ese número? Un intermitente que "ya no falla" después de
dos intentos no está arreglado: está en silencio. Escribe el criterio de cierre que usarías
para dar un intermitente por resuelto ante tu equipo.

## 🔥 Opcionales

### 🔥 Ejercicio 26 — Automatiza la matriz

Escribe `scripts/compatibility-matrix.sh` que produzca la tabla de §7 en Markdown, lista para
pegar en el reporte.

**Objetivo:** automatizar después de entender. Y que registre los exit codes correctamente,
porque si no, la tabla miente.

### 🔥 Ejercicio 27 — La bisección del lockfile

Con un proyecto que falla, usa `git bisect` sobre el historial del `package-lock.json` para
encontrar cuándo dejó de funcionar.

**Pregunta:** ¿qué commit lo rompió? Es reducción de §9 aplicada al tiempo en lugar de al
espacio.

## 💀 Boss fight

### 💀 Ejercicio 28 — Boss fight: el proyecto que solo funciona a veces

Te dan un proyecto que instala correctamente en la máquina de un compañero y falla en la tuya
tres de cada cinco veces, con errores distintos cada vez.

**Objetivo:** aplicar la fase entera. Datar el proyecto y formular la hipótesis; producir
evidencia comparable de las dos máquinas; construir la matriz; reducir hasta el caso mínimo; y
**demostrar** cuál es la variable que cambia entre ejecuciones. Termina con un reporte que
otra persona pueda seguir para reproducir el fallo **a voluntad** — porque un fallo intermitente
que sabes provocar ya está medio resuelto, y uno que no, no está resuelto en absoluto.

---

## 14. 📚 Referencias

**npm 6**
- `npm ci`: https://docs.npmjs.com/cli/v6/commands/npm-ci
- `package-lock.json` y `lockfileVersion`: https://docs.npmjs.com/cli/v6/configuring-npm/package-lock-json
- Rangos de SemVer: https://docs.npmjs.com/cli/v6/using-npm/semver

**Shell**
- `PIPESTATUS`: https://www.gnu.org/software/bash/manual/bash.html#index-PIPESTATUS
- `set -o pipefail`: https://www.gnu.org/software/bash/manual/bash.html#The-Set-Builtin
- `tee(1)`: https://manpages.debian.org/buster/coreutils/tee.1.en.html

**Node**
- Calendario de releases, para datar: https://github.com/nodejs/Release

> ⚠️ **La tabla de `lockfileVersion` de §5.2 no está en la documentación de npm 6**, porque las
> versiones 2 y 3 son posteriores. Está construida a partir de las notas de release de npm 7 y
> 9, y es verificable abriendo cualquier lockfile.

**Orden de lectura sugerido:** `PIPESTATUS` antes del ejercicio 5, y la documentación de
`package-lock.json` antes del 12.

---

## 15. 🏁 Resultado de la fase

```text
ANTES DE EJECUTAR   registrar commit, working tree y hash del lockfile
                    datar con lockfileVersion, CI histórico y .nvmrc
                    escribir la hipótesis, para tener contra qué contrastar

EVIDENCIA           2>&1 para los dos canales
                    | tee para ver y guardar
                    ${PIPESTATUS[0]} porque $? es el de tee
                    un expediente por intento, con fecha

MAPA                matriz 4 generaciones × 3 etapas
                    la del fixture de control decide si el problema es tuyo

MÉTODO              provocar los fallos antes de sufrirlos
                    reducir hasta el caso mínimo
                    una variable a la vez · reproducir antes de reparar
```

> **La señal de que quedó bien:** *"puedo decir qué versión de Node necesita un proyecto antes
> de instalarlo — y cuando me equivoco, sé qué evidencia me faltó mirar."*

En **[F21](21-arquitecturas-y-emulacion.md)** cambiamos de eje otra vez: arquitecturas de CPU, imágenes multi-plataforma y cómo tu
Mac ARM ejecuta un binario x86 sin que se lo pidas.
