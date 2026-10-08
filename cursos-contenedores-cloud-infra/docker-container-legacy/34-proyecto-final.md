# 🏆 Parte II · Fase 34 — Proyecto final: un repo de 2019 sin instrucciones

> **Curso:** Docker Legacy Node
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · Node 10.24.1 / 12.22.12 / 14.21.3 / 16.20.2
> **Requisitos:** el curso entero. Esta fase no enseña nada nuevo: te pide demostrarlo
> **Entregables:** una imagen reproducible · `VALIDATION-REPORT.md` · un veredicto razonado · la lista honesta de lo que no resolviste
> **Estado de la imagen al terminar:** la del curso queda como estaba; la que cuenta es **la tuya**, construida para el proyecto que elijas
> **Fase exenta del mínimo de 20 ejercicios**, por la razón contraria a [F00](00-problema-y-contrato.md) y [F01](01-decisiones-debian-zonas-node.md): **la fase entera es un ejercicio**
> **Objetivo:** que un repositorio de 2019 sin instrucciones y sin nadie a quien preguntarle pase de ser un problema a ser un veredicto

---

## 1. 🧭 Dónde estamos

Al final. Treinta y cuatro fases construyendo un toolchain, entendiéndolo por dentro y
aprendiendo a diagnosticarlo.

Esta fase no añade contenido. **Es el examen**, y es el punto donde demuestras que el curso
sirvió para algo.

> 🧭 **Por qué es fase y no apéndice.** Un apéndice es opcional por definición. Este no lo es:
> va numerado, cuenta en el calendario, y es lo que separa haber leído el curso de haberlo hecho.

---

## 2. 🎯 Objetivos de esta fase

Esta fase no tiene objetivos de aprendizaje nuevos: tiene **objetivos de demostración**. Al
terminar tienes que poder enseñar, con artefactos y no con afirmaciones, que:

- Puedes **datar un proyecto** que no conoces y formular una hipótesis de entorno **antes** de
  ejecutar nada, y después contrastarla con lo que pasó.
- Puedes **construir un entorno reproducible** para código que no escribiste, con las versiones
  fijadas y el porqué de cada decisión escrito al lado.
- Puedes **validar con evidencia**: los ocho pasos, el volumen limpio, los dos canales del log,
  los códigos de salida correctos y la matriz de las cuatro generaciones.
- Puedes **diagnosticar situando la capa** antes de corregir, confirmando cada hipótesis con un
  comando y sin recurrir a ningún anti-patrón.
- Puedes **emitir un veredicto** que alguien capaz de decidir entienda: con su nivel de
  compatibilidad, su condición de uso, y lo que queda abierto.

> 🧭 **Y el objetivo que engloba a los cinco:** convertir *"no sé si esto se puede mantener"* en
> una respuesta defendible. Fíjate en que **ninguno de los cinco dice "que el proyecto
> funcione"**. Esa no es la prueba, y §8.6 lo dice con puntos.

---

## 3. 🚧 Qué NO entra

Acotar el examen es parte del examen, así que estas cuatro cosas quedan **explícitamente fuera**
y no restan puntos:

- **Migrar, actualizar o arreglar el proyecto.** No vas a subir de Vue 2 a Vue 3 ni a cambiar
  `node-sass` por `sass`. El encargo es hacerlo **funcionar como está** y decir qué costaría lo
  otro, no hacerlo.
- **Producción.** Nada de multi-stage para adelgazar, usuario non-root obligatorio, healthchecks
  ni endurecimiento. Sigue siendo un laboratorio de mantenimiento local, con todo lo que el
  curso lleva veinte fases diciendo sobre eso. Si tu proyecto lo pide, va en la lista de §5.4.
- **CI.** Automatizar la validación en un pipeline es una ampliación legítima y no se evalúa
  aquí; **[a14](a14-ci-github-actions.md)** te dice cómo si te apetece.
- **Multiarquitectura**, salvo que sea la causa de un fallo que encuentres. El veredicto puede
  —y suele— decir "no verificado en arm64", y **eso es una respuesta correcta**: declarar el
  alcance vale más que ampliarlo a medias.

> 💸 **Lo que sí es deuda declarada de esta fase.** No hay solucionario ni corrección externa:
> la rúbrica de §8 es autoevaluación. Si quieres una segunda opinión, el mejor sustituto está en
> el checklist de §10 — dárselo a otra persona y que intente reproducir tu trabajo con tu
> expediente y nada más.

---

## 4. 📜 El enunciado

> **Te entregan un repositorio de 2019. No tiene README útil, no tiene `.nvmrc`, la persona que
> lo escribió ya no está en la empresa, y nadie sabe cómo se construía.**
>
> **Tu trabajo: producir la imagen, el reporte de validación y el veredicto de
> compatibilidad.**

Eso es todo el enunciado. La ambigüedad es deliberada: **es el trabajo real**.

---

## 5. 📦 Los entregables

Cuatro, y los cuatro se evalúan.

### 5.1 Una imagen reproducible

Un `Dockerfile` que construya el entorno donde ese proyecto funciona, y que **otra persona pueda
construir mañana en otra máquina obteniendo lo mismo**.

```text
✅ versiones fijadas, sin rangos ni latest
✅ construye desde cero: comprobado con --no-cache
✅ el proyecto NO va dentro de la imagen
✅ la arquitectura está declarada
```

### 5.2 `VALIDATION-REPORT.md`

Con la estructura de **[F11](11-validar-tu-proyecto.md) §7**, ampliada con lo de **[F20](20-validacion-sistematica-y-evidencia.md)**: la datación con su evidencia, la
hipótesis inicial contrastada, la matriz de generaciones y la sección de qué no demuestra.

### 5.3 Un veredicto razonado

**Una afirmación, no una lista de logs.** Con su nivel de compatibilidad nombrado —[F11](11-validar-tu-proyecto.md) §4— y
su condición de uso.

```text
❌ "funciona"
❌ "no se puede recuperar"
✅ "compatible hasta nivel 5 con Node 10.24.1 sobre linux/amd64: instala,
    testea, construye y arranca. El nivel 6 —watch— requiere polling.
    No verificado en arm64. Riesgo abierto: 3 dependencias con prebuilds
    en servidores de terceros que podrían desaparecer."
```

### 5.4 La lista de lo que no pudiste resolver

**Es el entregable que más se olvida y el que más vale.** Por cada cosa: qué es, qué intentaste,
por qué paraste, y qué haría falta.

> 🧭 **Un trabajo honesto tiene esta sección con contenido.** Si la tuya está vacía, o tuviste
> mucha suerte, o no miraste lo suficiente. **[F30](30-troubleshooting-metodo-y-herramientas.md) §11** ya te dio permiso para parar; esto es
> donde se documenta.

---

## 6. 🚦 El procedimiento sugerido

No es obligatorio, y saltárselo suele costar caro.

```text
1. ARQUEOLOGÍA          F20 §4 y §5
   registra el estado · data el proyecto · escribe la hipótesis
   ⛔ sin ejecutar nada todavía

2. HIPÓTESIS            F20 §5.5
   qué Node, qué riesgos, qué predices que va a fallar

3. IMAGEN               F02 a F07
   parte del toolchain del curso · ajusta lo que este proyecto pida

4. VALIDACIÓN           F11 §6, los ocho pasos
   volumen limpio · evidencia con PIPESTATUS · para si npm ci falla

5. DIAGNÓSTICO          F30 · F31 · F32
   cuando falle: sitúa la capa, confirma, corrige
   una variable a la vez

6. MATRIZ               F20 §7
   las cuatro generaciones × las etapas

7. VEREDICTO            F11 §4
   el nivel alcanzado, la condición de uso, y lo que queda abierto
```

> ⚠️ **El error más común es saltarse el paso 1.** Es tentador ejecutar `npm ci` a ver qué pasa,
> y destruye la información que necesitabas para datar el proyecto.

---

## 7. 🗂️ Los tres repositorios de partida

Elige uno según lo que quieras demostrar. **El 🟡 basta para aprobarte a ti mismo**; los otros
dos son para quien quiera el examen completo.

### 7.1 🟡 Nivel intermedio — el proyecto ordenado

**Qué buscar:** un proyecto Vue 2 o React 16 de 2018–2019, archivado en GitHub, **con
`package-lock.json`**, sin dependencias nativas evidentes y con al menos un script de build.

**Qué demuestra:** el camino feliz del curso. Arqueología, imagen, validación y veredicto.

**Lo que probablemente te encuentres:** el build funciona; los tests dan problemas por versiones
de Jest o jsdom; el dev server necesita `--host 0.0.0.0`.

### 7.2 🟠 Nivel difícil — el proyecto con dependencias nativas

**Qué buscar:** un proyecto de la misma época **con `node-sass`, `sqlite3`, `bcrypt` o
`canvas`** en sus dependencias.

**Qué demuestra:** lo anterior más [F14](14-abi-libc-y-prebuilds.md) y [F15](15-laboratorios-dependencias-nativas.md). La matriz de generaciones deja de ser un trámite.

**Lo que probablemente te encuentres:** un prebuild que ya no existe; un `node-gyp` que quiere
Python 2; una librería `-dev` que falta; y si estás en ARM, [F23](23-estudios-de-caso-multiplataforma.md) entero.

### 7.3 🔴 Nivel muy difícil — el proyecto sin lockfile

**Qué buscar:** un proyecto de 2017–2019 **sin `package-lock.json`**, con rangos `^` por todas
partes y dependencias nativas.

**Qué demuestra:** el problema real del legacy, porque **sin lockfile la reproducibilidad hay que
construirla**, no heredarla.

**El trabajo extra**, y es sustancial: hay que reconstruir un árbol de dependencias plausible de
la época y **justificar cada decisión**. La fecha del último commit, el CI histórico y las fechas
de publicación de cada versión en el registry son tus fuentes.

> ⚠️ **En el 🔴, generar el lockfile hoy con npm actual es la respuesta equivocada** y la primera
> que se le ocurre a todo el mundo. Resuelve un árbol de 2026 para un código de 2019. El trabajo
> es acotar a lo que existía **entonces** — con `npm install --before <fecha>` como punto de
> partida— y decir explícitamente qué certeza tiene tu reconstrucción.

### 7.4 Y una alternativa mejor que las tres

**Usa el proyecto legacy que te trajo a este curso.** Si llegaste aquí con uno, ese es tu
proyecto final: tiene el contexto real, las restricciones reales y las consecuencias reales.

---

## 8. 📊 La rúbrica

Cien puntos. Está aquí para que sepas qué se evalúa **antes** de empezar.

### 8.1 Arqueología y método — 20 puntos

| | Puntos |
|---|---|
| Registró el estado inicial antes de tocar nada | 5 |
| Dató el proyecto con evidencia —lockfileVersion, CI histórico, fechas— | 5 |
| Escribió una hipótesis inicial **antes** de ejecutar | 5 |
| Contrastó la hipótesis con el resultado y explicó la diferencia | 5 |

### 8.2 La imagen — 20 puntos

| | Puntos |
|---|---|
| Construye desde cero, verificado con `--no-cache` | 5 |
| Versiones fijadas, sin rangos ni `latest` | 5 |
| El proyecto no va dentro; el código vive en el host | 5 |
| Cada decisión no evidente tiene su porqué en un comentario | 5 |

### 8.3 Validación y evidencia — 25 puntos

| | Puntos |
|---|---|
| Los ocho pasos del protocolo, en orden | 5 |
| Volumen limpio, con la convención de nombres correcta | 5 |
| Logs con los dos canales y exit codes con `PIPESTATUS` | 5 |
| Matriz de las cuatro generaciones | 5 |
| Expediente completo y reproducible por otra persona | 5 |

### 8.4 Diagnóstico — 20 puntos

| | Puntos |
|---|---|
| Situó cada fallo en su capa antes de corregir | 5 |
| Confirmó cada hipótesis con un comando | 5 |
| Distinguió causa contribuyente de causa raíz | 5 |
| **No usó ningún anti-patrón de [F30](30-troubleshooting-metodo-y-herramientas.md) §8** | 5 |

### 8.5 Veredicto y honestidad — 15 puntos

| | Puntos |
|---|---|
| El veredicto nombra su nivel y su condición de uso | 5 |
| La lista de lo no resuelto existe y tiene contenido | 5 |
| Declara qué **no** demuestra el trabajo | 5 |

### 8.6 Cómo interpretar tu puntuación

```text
85–100   Puedes hacerte cargo de un proyecto legacy y defender tus decisiones
70–84    Sólido. Revisa dónde perdiste puntos: casi siempre es §8.5
50–69    El trabajo está; falta el método. Vuelve a F20 y F30
< 50     Probablemente ejecutaste antes de investigar. Vuelve al paso 1
```

> 🧭 **Y el criterio que atraviesa la rúbrica entera:** se evalúa el **razonamiento con
> evidencia**, no el éxito. Un proyecto que no se pudo recuperar, con el porqué documentado y la
> evidencia detrás, **puntúa más alto** que uno que funciona sin que sepas explicar por qué.

---

## 9. ⚠️ Errores comunes y diagnóstico

Dos familias distintas, y conviene no confundirlas: la primera hunde la **nota**, la segunda
hunde la **tarde**.

### 9.1 Los cinco errores de método que hunden un trabajo

**Ejecutar antes de investigar.** El paso 1 no se recupera.

**Cambiar varias cosas a la vez.** Al final funciona y no sabes por qué. [F30](30-troubleshooting-metodo-y-herramientas.md) §7.

**Usar un anti-patrón "solo esta vez".** Son cinco puntos directos, y sobre todo destruyen la
evidencia que necesitabas.

**Entregar logs en lugar de un veredicto.** Cuatrocientas líneas de salida no responden *"¿se
puede mantener esto?"*.

**Dejar vacía la lista de lo no resuelto.** Es la sección que más dice de quien la escribe.

### 9.2 Los seis fallos técnicos que vas a encontrar

Estos no son de método: son del proyecto que elegiste, y cada uno tiene su comprobación. Los
seis salen del catálogo del curso, pero aquí llegan mezclados y sin etiqueta — que es
exactamente la diferencia entre [F31](31-catalogo-de-fallos-i.md) y esto.

**El lockfile no es de la época.**

```text
npm ERR! Cannot read properties of null (reading 'matches')
```

Un `package-lock.json` con `lockfileVersion: 2` o `3` en un proyecto de 2019 significa que
alguien lo regeneró con npm moderno, y npm 6 no sabe leerlo del todo.
**Comprobación:** `jq .lockfileVersion package-lock.json` y `git log -1 --format=%ci package-lock.json`.
Si la versión es 2+ y el commit es reciente, tu lockfile no representa lo que el proyecto probó
— y eso va en la datación, no en los arreglos.

**El repositorio trae `node_modules` commiteado.**

```text
Error: The module was compiled against a different Node.js version
```

Pasaba, y más de lo que parece. El `node_modules` del repositorio se monta bajo tu bind mount y
gana al volumen si el orden de los mounts no es el que crees.
**Comprobación:** `git ls-files node_modules | head` en el host y `ls -la /workspace/node_modules` dentro.
Si `git ls-files` devuelve algo, tienes binarios de la máquina de alguien de 2019 dentro de tu
laboratorio. La corrección es de [F09](09-montar-tu-proyecto.md) §5, no de [F14](14-abi-libc-y-prebuilds.md).

**El proyecto necesita variables de entorno que nadie documentó.**

```text
Error: Cannot read property 'apiUrl' of undefined
```

El build lee un `.env` que estaba en la máquina del autor y nunca entró al repositorio.
**Comprobación:** `grep -rn 'process\.env\.' src/ | grep -oP 'process\.env\.\K\w+' | sort -u`,
y compáralo con lo que haya en `.env.example`, `.env.sample` o el CI histórico.
Las que falten van a la lista de §5.4 con un valor inventado y **declarado como inventado**.

**El proyecto depende de un servicio que ya no existe.**

```text
FetchError: request to https://api.miempresa-2019.com/v1/config failed,
reason: getaddrinfo ENOTFOUND
```

Es el muro más honesto del proyecto final, y no lo puedes arreglar.
**Comprobación:** `grep -rn 'https\?://' src/ | grep -v node_modules | sort -u` y un `curl -I`
a cada dominio. **Un proyecto cuyo backend murió sigue siendo validable hasta el nivel 4** —
instala, testea, construye—; el veredicto lo dice y el nivel 5 se declara no alcanzable. Eso es
un resultado, no un fracaso.

**Los submódulos de Git están vacíos.**

```text
sh: 1: ../shared/build.sh: not found
```

Un `git clone` sin `--recursive` deja los directorios de submódulo creados y vacíos, y el
error que sale no menciona la palabra "submódulo" en ningún momento.
**Comprobación:** `cat .gitmodules 2>/dev/null` y `git submodule status`. Un `-` delante del
hash significa "no inicializado".

**El proyecto es un monorepo y elegiste el directorio equivocado.**

```text
npm ERR! enoent ENOENT: no such file or directory, open '/workspace/package.json'
```

**Comprobación:** `find . -name package.json -not -path '*/node_modules/*' -maxdepth 3`. Si
salen varios, mira el raíz a ver si declara `workspaces`. Un monorepo de 2019 con npm 6 **no
tiene workspaces funcionales** —llegaron con npm 7— y eso cambia por completo el trabajo: cada
paquete se instala por separado. Si te pasa esto en el nivel 🟡, cambia de repositorio; no era
el examen que querías.

> 🩺 **El patrón que comparten los seis.** En ninguno el mensaje de error nombra la causa. Es
> lo mismo que el curso lleva demostrando desde [F03](03-apt-y-utilidades.md), y aquí llega sin
> el aviso previo: **lee el mensaje, sitúa la capa, y después busca la comprobación**. Si en
> algún momento te ves probando cosas, vuelve al protocolo de 60 segundos de
> [F30](30-troubleshooting-metodo-y-herramientas.md) §4.

---

## 10. 📋 Checklist de validación

Dos listas. La primera se ejecuta contra la máquina y **no admite opinión**: cada línea es un
comando cuya salida decide si pasas o no.

```bash
# 1. la imagen construye desde cero, sin caché
docker build --no-cache --platform linux/amd64 -t proyecto-final:v1 . && echo "OK 1"

# 2. ninguna versión lleva rango ni latest
! grep -nE ':(latest|[0-9]+\.x)|\^[0-9]|~[0-9]' Dockerfile && echo "OK 2"

# 3. el proyecto NO está dentro de la imagen
! docker run --rm proyecto-final:v1 test -e /workspace/package.json && echo "OK 3"

# 4. el volumen sigue la convención de nombres con la generación
docker volume ls --format '{{.Name}}' | grep -qE '\-node(10|12|14|16)\-modules$' && echo "OK 4"

# 5. el expediente tiene sus tres piezas
test -f VALIDATION-REPORT.md && test -d evidencia && ls evidencia/*.log >/dev/null && echo "OK 5"

# 6. el reporte declara arquitectura y versión de Node
grep -qE 'linux/(amd64|arm64)' VALIDATION-REPORT.md && \
grep -qE '1[0246]\.[0-9]+\.[0-9]+' VALIDATION-REPORT.md && echo "OK 6"

# 7. la matriz de las cuatro generaciones está completa
grep -c -E '10\.24\.1|12\.22\.12|14\.21\.3|16\.20\.2' VALIDATION-REPORT.md   # debe dar 4 o más
```

La segunda es de criterio y la contestas tú, honestamente:

```text
[ ] Registré el estado inicial antes de ejecutar nada
[ ] Escribí la hipótesis antes de instalar, y la contrasté después
[ ] Los ocho pasos del protocolo, con su evidencia
[ ] Los exit codes usan PIPESTATUS y no $?
[ ] Cada fallo tiene capa, confirmación, causa contribuyente y causa raíz
[ ] No usé ningún anti-patrón de F30 §8
[ ] Cada decisión no evidente del Dockerfile tiene su porqué en un comentario
[ ] El veredicto nombra nivel y condición de uso, y cabe en un párrafo
[ ] La lista de lo no resuelto tiene contenido
[ ] Declaré qué NO demuestra este trabajo
[ ] Otra persona podría reproducirlo siguiendo solo el expediente
```

> 🔥 **Prueba de fuego, y es la única que de verdad valida el trabajo.** Dale el expediente a
> alguien —o déjalo reposar tres días y vuelve— y reconstruye el entorno **siguiendo solo lo que
> está escrito**, sin tu memoria. Todo lo que tengas que recordar de cabeza es un hueco del
> expediente. Anótalos y arréglalos: esa lista suele ser corta y siempre es reveladora.

---

## 11. 📚 Referencias

Esta fase no trae bibliografía propia: su bibliografía **es el curso**. Lo que sigue es el
orden en que conviene tener las fases abiertas mientras trabajas.

**El método, por orden de uso**

- Arqueología, evidencia y matriz — **[F20](20-validacion-sistematica-y-evidencia.md)** §4 a §7
- El protocolo de ocho pasos y los siete niveles — **[F11](11-validar-tu-proyecto.md)** §4 y §6
- Triaje, hipótesis falsables y anti-patrones — **[F30](30-troubleshooting-metodo-y-herramientas.md)** §4, §7 y §8
- Forense sobre lo que no documentaste — **[F33](33-forense-y-boss-fight.md)**

**Cuando algo falle, por capa**

- Motor, build, registry y red — **[F31](31-catalogo-de-fallos-i.md)**
- APT, Node, node-gyp, ABI y filesystem — **[F32](32-catalogo-de-fallos-ii.md)**
- Dependencias nativas, los cuatro casos — **[F14](14-abi-libc-y-prebuilds.md)** y **[F15](15-laboratorios-dependencias-nativas.md)**
- Arquitectura y emulación — **[F21](21-arquitecturas-y-emulacion.md)**, **[F22](22-apple-silicon-y-hosts.md)** y **[F23](23-estudios-de-caso-multiplataforma.md)**

**Para construir la imagen**

- El Dockerfile, instrucción a instrucción — **[F02](02-dockerfile-esencial.md)** §7
- APT y los repositorios EOL — **[F03](03-apt-y-utilidades.md)**
- Toolchain, Python y node-gyp — **[F04](04-toolchain-de-compilacion.md)** y **[F05](05-python-y-node-gyp.md)**
- Las cuatro generaciones de Node — **[F06](06-instalacion-node.md)**
- Build, contexto y caché — **[F07](07-build-de-la-imagen.md)** y **[F12](12-capas-cache-y-contexto.md)**
- Volúmenes y bind mounts — **[F09](09-montar-tu-proyecto.md)**

**Fuentes externas que vas a necesitar de verdad**

- El registry de npm, para datar versiones: `npm view <paquete> time` —
  https://docs.npmjs.com/cli/v6/commands/npm-view
- Archivo histórico de Node: https://nodejs.org/dist/
- Archivo de Debian: https://archive.debian.org y https://snapshot.debian.org
- Wayback Machine, para READMEs y documentación que ya no está:
  https://web.archive.org

> ⚠️ **La documentación de npm y de Node que encuentres hoy describe versiones muy posteriores
> a las tuyas.** Con npm 6 en particular, asegúrate de estar leyendo `/cli/v6/`. El inventario
> completo, ordenado y valorado está en **[F35](35-referencias.md)**.

**Orden de lectura sugerido:** [F20](20-validacion-sistematica-y-evidencia.md) §4 y §5 **antes** de tocar el repositorio; [F11](11-validar-tu-proyecto.md) §6 cuando
vayas a instalar; [F30](30-troubleshooting-metodo-y-herramientas.md) §4 la primera vez que algo falle; y F11 §4 al final, para nombrar el
nivel del veredicto.

---

## 12. 🎓 Y después

Cuando termines, dos cosas.

**Guarda el expediente.** Es la plantilla de todos los que vengan, y el segundo proyecto legacy
te va a costar la mitad.

**Y responde una última pregunta**, que es la que cierra el curso:

> **¿Qué habrías hecho con este proyecto antes de la Fase 00?**

La distancia entre esa respuesta y lo que acabas de entregar es el curso.

---

## 13. 🏁 Resultado

```text
ENTREGAS        una imagen reproducible
                un VALIDATION-REPORT.md con su evidencia
                un veredicto con nivel y condición de uso
                la lista honesta de lo que quedó abierto

DEMUESTRAS      que puedes tomar un proyecto legacy sin documentación
                y convertirlo en una decisión defendible

Y SI NO SE PUDO RECUPERAR
                también es un resultado — el bueno, si sabes decir por qué
```

> **La señal de que quedó bien:** *"puedo entregarle esto a quien decide, y con ello puede
> responder si mantener este proyecto es viable, cuánto cuesta y qué riesgo queda — sin
> preguntarme nada más."*

En **[F35](35-referencias.md)** queda el documento de consulta: referencias, arqueología técnica y dónde seguir
buscando cuando este curso se quede corto.
