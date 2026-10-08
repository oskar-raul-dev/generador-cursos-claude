# 🧪 Parte II · Fase 23 — Estudios de caso y árbol de decisión multiplataforma

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** `linux/amd64` baseline · `linux/arm64` adicional
> **Requisitos:** **[F21](21-arquitecturas-y-emulacion.md)**, **[F22](22-apple-silicon-y-hosts.md)** y **[F15](15-laboratorios-dependencias-nativas.md)** (los cuatro dragones)
> **Estado de la imagen al terminar:** sin cambios
> **Fecha de revisión de documentación externa:** 6 de septiembre de 2026 — Colima, Docker Desktop y sus opciones de emulación
> **Objetivo:** poner números donde llevamos tres fases poniendo argumentos — qué pasa exactamente con los cuatro dragones en ARM64, cuánto cuesta la emulación de verdad, y un árbol de decisión que no dependa de la intuición

---

## 1. 🧭 Dónde estamos

[F21](21-arquitecturas-y-emulacion.md) dio el mecanismo, [F22](22-apple-silicon-y-hosts.md) dio las rutas. Falta la parte incómoda: **medir**.

Porque hasta ahora el curso ha dicho "los prebuilds de 2018 son mayoritariamente x64" y "la
emulación cuesta", y las dos afirmaciones son verificables. Esta fase las verifica, y termina en
un árbol de decisión que cualquiera de tu equipo puede seguir.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder:

- Decir qué hace exactamente cada uno de los cuatro dragones en ARM64, y por qué.
- Diseñar un microbenchmark honesto, con sus condiciones declaradas.
- Interpretar un resultado de rendimiento sin sacar conclusiones que los datos no sostienen.
- Construir la **matriz de validación real**: fixture × arquitectura × etapa.
- Aplicar un **árbol de decisión** que lleve de tu proyecto a una ruta concreta.

---

## 3. 🚧 Qué NO entra todavía

- **La comparación Docker frente a Podman**, con su rendimiento → **[F26](26-portabilidad-entre-motores.md)**.
- **Colima y Lima** → **[a07](a07-colima-y-lima.md)**; **Windows** → **[a08](a08-windows-y-powershell.md)**.
- **Cypress y Selenium** en ARM64 → **[a09](a09-browsers-legacy.md)**.

---

## 4. 🐉 Los cuatro dragones en ARM64

[F15](15-laboratorios-dependencias-nativas.md) los diseccionó en amd64. Aquí, qué cambia al cruzar de arquitectura.

### 4.1 `node-sass`: el ejemplo perfecto de por qué amd64 sigue vivo

`node-sass` publica prebuilds por combinación de ABI, plataforma **y arquitectura**. Y para las
versiones de la época, la cobertura de `linux-arm64` es escasa o inexistente.

```text
amd64  →  prebuild disponible  →  instala en segundos
arm64  →  no hay prebuild      →  intenta compilar LibSass desde source
```

Compilar LibSass funciona **si** tienes el toolchain —lo tienes desde [F04](04-toolchain-de-compilacion.md)— y tarda minutos en
lugar de segundos. Cuando no funciona, el error suele venir de la compilación, no de la
descarga, y por eso se diagnostica distinto.

```bash
# comprueba qué hay publicado antes de intentarlo
npm view node-sass@4.14.1 dist.tarball
# y en los releases de GitHub del paquete, busca "linux-arm64" en los artefactos
```

> 🧭 **Este caso, solo, justifica que el baseline del curso sea amd64.** No es una preferencia
> por Intel: es que en 2018 los binarios se publicaron para donde estaba la gente.

### 4.2 `canvas`: depende de las librerías, no del prebuild

`canvas` necesita Cairo, Pango y compañía — y **esas sí existen para arm64 en Debian**, porque
son paquetes de la distribución y Debian construye para todas sus arquitecturas.

```text
amd64  →  prebuild o compila; las librerías están
arm64  →  probablemente compila; las librerías TAMBIÉN están
```

Es un caso más amable que `node-sass`: en arm64 compila y funciona, siempre que la imagen tenga
las librerías de [F15](15-laboratorios-dependencias-nativas.md) §8 — que las tiene, porque `apt-get install` resuelve la arquitectura
correcta automáticamente.

### 4.3 `sqlite3`: dos estrategias, dos resultados

La estrategia de [F15](15-laboratorios-dependencias-nativas.md) §6 cobra aquí una relevancia nueva:

```text
prebuild con SQLite incrustado  →  ¿existe para arm64? depende de la versión
compilar contra el del sistema  →  funciona en arm64: libsqlite3-dev existe para todas
```

En ARM64, la segunda estrategia pasa de ser una opción a ser **la salida fiable**.

### 4.4 Puppeteer: el que de verdad se rompe

Categoría D de [F22](22-apple-silicon-y-hosts.md) §8, y el caso más duro. `puppeteer@5.5.0` descarga una revisión de Chromium
que **no se publicó para ARM64**. No es que compile lento: es que el artefacto no existe.

Las tres salidas, con su precio:

| Salida | Coste |
|---|---|
| Ejecutar en amd64 emulado | lento, y los navegadores emulados especialmente |
| `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD` + el `chromium` de Debian arm64 | funciona, pero **no es el navegador que el proyecto probó** |
| Dejar los E2E para CI amd64 | pierdes el ciclo rápido en local |

> ⚠️ **No reemplaces el navegador en silencio.** Si sustituyes el Chromium `r818858` que
> Puppeteer esperaba por el `chromium` de Debian 10, tus tests corren contra otro navegador. A
> veces da igual y a veces explica un fallo que no entiendes. **Documéntalo en el reporte de
> validación**, siempre.

---

## 5. 📏 Microbenchmarks sin vender humo

Medir mal es peor que no medir, porque produce números que la gente cita después.

### 5.1 Las reglas mínimas

Para que dos números sean comparables:

```text
mismo host              mismos límites de CPU y memoria
mismo motor y versión   mismo proyecto y mismo lockfile
misma versión de Node   volumen limpio en cada corrida
```

Y hay que **declarar el contexto**, porque sin él el número no significa nada:

```text
hardware · versión de macOS · motor y su versión · VMM
mecanismo de traducción (QEMU o Rosetta) · CPU y RAM de la VM
```

> 🧭 **Un número sin sus condiciones no es un dato, es una anécdota.** *"npm ci tarda 3 minutos
> en ARM"* no dice nada. *"npm ci del fixture Vue 2 tarda 3m12s en linux/amd64 emulado con QEMU,
> sobre un M3 con 4 CPU y 8 GB asignados a la VM, volumen limpio"* sí.

### 5.2 Las cuatro cosas que vale la pena medir

**Arranque** — cuánto cuesta simplemente ejecutar algo:

```bash
/usr/bin/time -p docker run --rm --platform linux/amd64 \
  legacy-node-toolchain:phase15 node -e 'console.log(process.arch)'
```

**`npm ci`** — el que más se nota en el día a día, y donde pesa el I/O tanto como la CPU:

```bash
docker volume rm bench-vol 2>/dev/null; docker volume create bench-vol >/dev/null
/usr/bin/time -p docker run --rm --platform linux/amd64 \
  --mount type=bind,src="$PWD",dst=/workspace \
  --mount type=volume,src=bench-vol,dst=/workspace/node_modules \
  legacy-node-toolchain:phase15 npm ci
```

**Un build de Webpack** — CPU sostenida de JavaScript, que es donde la traducción se nota.

**Compilar un addon C++** — CPU sostenida de código nativo, el caso más desfavorable para la
emulación.

### 5.3 Cómo leer los resultados

Una tabla como la que vas a producir se lee con cuidado:

| Tarea | arm64 nativo | amd64 emulado | Factor |
|---|---|---|---|
| Arranque de contenedor | (tu número) | (tu número) | |
| `npm ci` del fixture Vue 2 | | | |
| Build de Webpack | | | |
| Compilar un addon C++ | | | |

**Lo que sí puedes concluir:** que en *tu* máquina, con *ese* motor y *esa* configuración, la
tarea X tarda N veces más emulada.

**Lo que no:** que "ARM es más rápido que Intel", que "QEMU multiplica por N" en general, ni
que el resultado se traslada a otra máquina o a otra versión del motor.

> 🧠 **Y el número que casi nadie mide, siendo el que más importa:** el tiempo total del
> ciclo real de trabajo. Si `npm ci` tarda tres minutos más pero solo lo ejecutas una vez al
> día, y el build que ejecutas veinte veces tarda igual, la emulación te cuesta tres minutos
> diarios y no "un 40% de todo".

---

## 6. 📊 La matriz de validación real

La evidencia que junta todo el bloque: **fixture × arquitectura × etapa**.

```bash
for arch in amd64 arm64; do
  for fx in 00-node-smoke 10-vue2-min 20-angular8-min 30-react16-min 40-svelte3-min; do
    vol="bench-${fx}-node10-${arch}"
    docker volume rm "$vol" >/dev/null 2>&1 || true
    docker volume create "$vol" >/dev/null
    printf '%-8s %-18s ' "$arch" "$fx"
    docker run --rm --platform "linux/${arch}" \
      -e NODE_VERSION=10.24.1 \
      --mount type=bind,src="$PWD/src/11-validar-tu-proyecto/${fx}",dst=/workspace \
      --mount type=volume,src="$vol",dst=/workspace/node_modules \
      legacy-node-toolchain:phase15 \
      bash -c 'npm ci >/dev/null 2>&1 && printf "ci=✅ " || printf "ci=❌ "
               npm run build >/dev/null 2>&1 && printf "build=✅\n" || printf "build=❌\n"'
  done
done
```

**Detalles con intención:**

- **Volumen limpio por fixture y arquitectura**, con la convención completa de [F22](22-apple-silicon-y-hosts.md) §7. Sin eso
  la matriz miente.
- **`00-node-smoke` primero**, porque si el control falla en una arquitectura, todo lo demás de
  esa columna es ruido.
- **Silenciamos la salida**: aquí queremos el mapa. El detalle se investiga sobre la casilla que
  falle.

### 6.1 Evidencia mínima por arquitectura

Para cada columna de la matriz, guarda el bloque de triangulación de [F21](21-arquitecturas-y-emulacion.md) §4.1. Sin él, dentro
de un mes no vas a saber qué motor ni qué traducción produjeron esos resultados.

---

## 7. 🌳 El árbol de decisión

Para un proyecto **nuevo** en Apple Silicon, la respuesta sería fácil: ARM64 nativo. Nuestro
caso es legacy, y por eso hace falta el árbol.

```mermaid
flowchart TD
    P["proyecto legacy"] --> Q1{"¿tiene dependencias nativas<br/>(categoría C o D)?"}
    Q1 -- "no" --> R1["ARM64 nativo<br/>🟢 rápido y sin traducir"]
    Q1 -- "sí" --> Q2{"¿hay prebuilds ARM64<br/>para todas?"}
    Q2 -- "sí" --> R2["ARM64 nativo 🟢"]
    Q2 -- "no" --> Q3{"¿compilan en ARM64<br/>sin tocar el proyecto?"}
    Q3 -- "sí" --> R3["ARM64 nativo<br/>🟡 más lento al instalar"]
    Q3 -- "no" --> R4["AMD64 emulado<br/>🟡 el baseline del curso"]
    R4 --> Q4{"¿el rendimiento<br/>es inaceptable?"}
    Q4 -- "no" --> R5["quédate"]
    Q4 -- "sí" --> R6["CI amd64<br/>o VM completa"]
```

### 7.1 "Sin modificar el proyecto" es la frontera

Esa condición del árbol es la que separa una decisión de laboratorio de una decisión de
producto, y conviene tenerla explícita.

**Workarounds de entorno** — aceptables, son tu trabajo:

```text
instalar una librería de Debian que falta      usar un volumen separado por arquitectura
habilitar la traducción amd64                  ajustar CPU y RAM de la VM
aportar el navegador con PUPPETEER_EXECUTABLE_PATH
```

**Modificaciones del proyecto** — otra conversación, y no la de este curso:

```text
cambiar node-sass por sass                     actualizar una dependencia nativa
subir de generación de Node                    reescribir un addon con N-API
```

> 🧭 **Las segundas son legítimas y a menudo la respuesta correcta a largo plazo.** Pero son
> una decisión de producto, con su prueba y su riesgo, no un ajuste de tu entorno. Mézclalas y
> ya no sabrás si el proyecto funcionaba o si lo hiciste funcionar cambiándolo.

---

## 8. 🧯 Troubleshooting multiplataforma

Los seis que vas a encontrar, con su comando de confirmación:

| Síntoma | Causa probable | Confirmación |
|---|---|---|
| `exec format error` | binario de otra arquitectura | `file` sobre él |
| `invalid ELF header` al cargar un `.node` | volumen contaminado entre arquitecturas | `file` sobre el `.node` |
| `npm ci` tarda 10× más | compilando por falta de prebuild | busca `node-gyp` en el log |
| prebuild `404` en arm64 | no existe para esa arquitectura | los releases del paquete |
| Chromium no arranca | no hay binario arm64 | `file` sobre el ejecutable |
| funciona en local y falla en CI | arquitecturas distintas | `uname -m` en los dos |

> 🩺 **Cuatro de los seis se confirman con `file`.** Es la herramienta más rentable de esta
> parte del curso, y es la misma de [F04](04-toolchain-de-compilacion.md) §5.2.

---

## 9. ⚠️ Errores comunes y diagnóstico

**"ARM64 es más lento".** Casi nunca. Lo lento es la **emulación**, y arm64 nativo suele ser
rápido. Si mediste arm64 nativo y salió lento, sospecha del volumen o de que estabas compilando.

**"Medí y da 3×".** ¿Con qué motor, qué traducción y qué tarea? §5.1.

**La matriz da resultados distintos cada vez.** No estás limpiando volúmenes.

**"Cambié a arm64 y ahora falla un test".** Son entornos distintos; puede ser legítimo. Redúcelo
con [F20](20-validacion-sistematica-y-evidencia.md) §9 antes de concluir.

**"En arm64 tarda más `npm ci` pero el build va igual".** Es lo esperado: la instalación compila
y el build es JavaScript. Ahí está la lectura de §5.3.

**Puppeteer "funciona" en arm64 con el Chromium de Debian.** Funciona, y no es el navegador del
proyecto. §4.4.

---

## 10. 📋 Checklist de validación

```text
[ ] Sabes qué hace cada uno de los cuatro dragones en ARM64
[ ] Mediste las cuatro tareas de §5.2 en las dos arquitecturas
[ ] Declaraste las condiciones de cada medición
[ ] La matriz de §6 está completa para los cinco fixtures
[ ] Guardaste la triangulación de arquitectura por columna
[ ] Recorriste el árbol de §7 con tu proyecto y llegaste a una ruta
[ ] Puedes distinguir un workaround de entorno de una modificación del proyecto
[ ] Sabes qué cuatro de los seis síntomas de §8 se confirman con file
```

---

## 11. 🧪 Ejercicios de la Fase 23 (20)

## 🟢 Fácil — los cuatro dragones en las dos arquitecturas (1–5)

### 🟢 Ejercicio 1 — `node-sass` en las dos

Instala `node-sass@4.14.1` en amd64 y en arm64, cronometrando.

**Pregunta:** ¿cuál descargó y cuál compiló? Búscalo en el log.

### 🟢 Ejercicio 2 — Busca el prebuild ARM64

En los releases de GitHub de `node-sass`, busca artefactos `linux-arm64` para la 4.14.1.

**Objetivo:** confirmar §4.1 con la fuente, no con el curso.

### 🟢 Ejercicio 3 — `canvas` en arm64

Instala `canvas@2.6.1` en arm64 con la imagen de [F15](15-laboratorios-dependencias-nativas.md).

**Pregunta:** ¿funcionó? ¿Tuviste que instalar algo más?

### 🟢 Ejercicio 4 — `sqlite3` de las dos formas en arm64

Repite [F15](15-laboratorios-dependencias-nativas.md) §6 en arm64.

**Pregunta:** ¿siguen funcionando las dos estrategias? ¿Cuál se vuelve más fiable?

### 🟢 Ejercicio 5 — Puppeteer se rompe

Instala `puppeteer@5.5.0` en arm64 y lee el error.

**Objetivo:** confirmar que falla al **descargar**, no al compilar. Es la diferencia de categoría.

## 🟡 Intermedio — medir con método (6–12)

### 🟡 Ejercicio 6 — Arranque, medido

Ejecuta el comando de arranque de §5.2 en las dos arquitecturas, tres veces cada una.

**Pregunta:** ¿cuánta variación hay entre corridas? ¿Es significativa la diferencia?

### 🟡 Ejercicio 7 — Declara tus condiciones

Escribe el bloque de contexto de §5.1 para tu máquina.

**Objetivo:** tenerlo listo para acompañar a cualquier número que produzcas.

### 🟡 Ejercicio 8 — Las cuatro tareas

Mide las cuatro de §5.2 en las dos arquitecturas y construye la tabla de §5.3.

**Objetivo:** tus propios factores, con tus condiciones declaradas.

### 🟡 Ejercicio 9 — Rosetta cambia el número

Repite el ejercicio 8 con Rosetta activada y desactivada.

**Pregunta:** ¿en qué tarea se nota más? ¿Cambia tu conclusión?

### 🟡 Ejercicio 10 — La matriz completa

Ejecuta el bucle de §6 sobre los cinco fixtures.

**Objetivo:** la tabla 5×2×2 completa. Anota cuánto tardó entera.

### 🟡 Ejercicio 11 — El control primero

Si algún fixture falló en una arquitectura, comprueba antes `00-node-smoke` en esa misma.

**Objetivo:** aplicar el reflejo de [F11](11-validar-tu-proyecto.md) §5.1 en un caso donde de verdad discrimina.

### 🟡 Ejercicio 12 — Sin limpiar volúmenes

Ejecuta la matriz **reutilizando** volúmenes entre arquitecturas.

**Pregunta:** ¿qué resultados cambiaron? ¿Cuáles eran falsos?

## 🟠 Difícil — diagnosticar la casilla roja (13–17)

### 🟠 Ejercicio 13 — El ciclo real

Cronometra tu ciclo de trabajo completo de una mañana —arrancar, instalar una vez, construir
diez veces— en las dos arquitecturas.

**Pregunta:** ¿cuánto te cuesta la emulación **al día**? Compara con el factor bruto del
ejercicio 8. Es la lectura de §5.3.

### 🟠 Ejercicio 14 — Recorre el árbol

Aplica §7 a tu proyecto legacy real y anota en qué rama saliste y con qué evidencia.

### 🟠 Ejercicio 15 — Los seis síntomas

Provoca los seis de §8 y confirma cada uno con su comando.

**Objetivo:** que cuatro se resuelvan con `file` y saber cuáles son los otros dos.

### 🟠 Ejercicio 16 — El navegador sustituido

Ejecuta la misma suite E2E con el Chromium de Puppeteer en amd64 y con el de Debian en arm64.

**Pregunta:** ¿pasan los mismos tests? Si alguno difiere, ¿es un bug o una diferencia de
navegador? Ahí está el aviso de §4.4 hecho experimento.

### 🟠 Ejercicio 17 — Un benchmark que engaña

Diseña deliberadamente una medición que dé un factor exagerado —por ejemplo, sin limpiar
cachés, o midiendo la primera corrida contra la quinta.

**Objetivo:** entender cómo se producen los números inflados que circulan por Internet, para
reconocerlos.

## 🔴 Muy difícil — informe y veredicto (18–20)

### 🔴 Ejercicio 18 — La casilla que falla

Toma la casilla roja de tu matriz y redúcela hasta el caso mínimo con [F20](20-validacion-sistematica-y-evidencia.md) §9.

**Objetivo:** pasar de "Angular falla en arm64" a "esta dependencia concreta, por esta razón".

### 🔴 Ejercicio 19 — Rebate un benchmark ajeno

Busca en un blog o en una charla un benchmark de "Docker en Apple Silicon" y audítalo con las
reglas de §5.1.

**Objetivo:** enumerar qué condiciones **no** declara, decir qué conclusiones no se sostienen
con lo que muestra, y proponer la medición que sí las sostendría. La mayoría de los que
encuentres van a fallar en al menos tres de las reglas.

### 🔴 Ejercicio 20 — El informe de rendimiento

Redacta el informe que le entregarías a tu equipo respondiendo: *"¿deberíamos trabajar en arm64
nativo o en amd64 emulado?"*.

**Objetivo:** con tus mediciones, tus condiciones declaradas, y una recomendación que diga
explícitamente **para qué proyectos** vale y para cuáles no. Y que incluya el coste diario real,
no solo el factor.

## 🔥 Opcionales

### 🔥 Ejercicio 21 — La quinta ruta

Configura un runner de CI amd64 —GitHub Actions vale— que ejecute tu validación, y compara el
tiempo total con hacerlo en local emulado.

**Pregunta:** ¿compensa? ¿Qué pierdes en el ciclo de desarrollo?

### 🔥 Ejercicio 22 — Migra un dragón

Sustituye `node-sass` por `sass` en un fixture y repite la matriz.

**Pregunta:** ¿cambia la rama del árbol en la que sales? Ahí tienes, medido, lo que vale
modernizar una sola dependencia.

## 💀 Boss fight

### 💀 Ejercicio 23 — Boss fight: el veredicto multiplataforma

Toma tu proyecto legacy y produce el veredicto completo de arquitectura: matriz de los cinco
niveles de compatibilidad × dos arquitecturas, mediciones de las cuatro tareas, el recorrido del
árbol con su evidencia, y la recomendación final.

**Objetivo:** la parte difícil no es medir: es **el apartado de "qué no probé y por qué"**. Un
informe honesto de este tipo tiene siempre casillas sin cubrir —porque medir todo cuesta
demasiado— y decir cuáles son y qué riesgo dejan abierto es lo que lo hace útil en lugar de
tranquilizador. Si tu informe no tiene ese apartado, todavía no está terminado.

---

## 12. 📚 Referencias

**Los paquetes**
- `node-sass`, releases y artefactos: https://github.com/sass/node-sass/releases
- `canvas`, instalación en Linux: https://github.com/Automattic/node-canvas/wiki/Installation:-Ubuntu-and-other-Debian-based-systems
- `sqlite3`: https://github.com/TryGhost/node-sqlite3
- Puppeteer, solución de problemas: https://pptr.dev/troubleshooting

**Medición**
- `time(1)`: https://manpages.debian.org/buster/time/time.1.en.html
- Docker — límites de recursos: https://docs.docker.com/engine/containers/resource_constraints/

**Multi-plataforma**
- Docker — multi-platform: https://docs.docker.com/build/building/multi-platform/

> ⚠️ **Ningún número de esta fase viene dado.** El curso da el método y las condiciones a
> declarar; los resultados los produces tú en tu máquina. Cualquier tabla de rendimiento que
> encuentres —aquí o fuera— sin sus condiciones al lado es una anécdota.

**Orden de lectura sugerido:** los releases de `node-sass` mientras haces el ejercicio 2, que
es donde el argumento de §4.1 se vuelve tuyo.

---

## 13. 🏁 Resultado de la fase

```text
LOS CUATRO EN ARM64   node-sass  sin prebuild → compila, y a veces falla
                      canvas     las librerías de Debian SÍ existen para arm64
                      sqlite3    compilar contra el sistema pasa a ser la salida fiable
                      Puppeteer  el navegador no existe: hay que aportarlo (a09)

MEDIR BIEN            mismas condiciones, declaradas siempre
                      arranque · npm ci · build · addon C++
                      un número sin condiciones es una anécdota
                      el coste real es el del ciclo diario, no el factor bruto

MATRIZ                fixture × arquitectura × etapa, con volumen limpio
                      el control primero, siempre

ÁRBOL                 sin nativas → arm64 · con prebuilds → arm64
                      compila sin tocar el proyecto → arm64 (más lento)
                      si no → amd64 emulado, el baseline
                      y "sin modificar el proyecto" es la frontera del árbol
```

> **La señal de que quedó bien:** *"cuando alguien dice que ARM va lento, le pregunto qué midió
> y en qué condiciones — y si no lo sabe, lo medimos juntos en veinte minutos."*

En **[F24](24-docker-y-podman-arquitectura.md)** cambiamos de eje por última vez en este bloque: Docker y Podman, dos arquitecturas
distintas para el mismo problema, comparadas sin hacer fútbol.
