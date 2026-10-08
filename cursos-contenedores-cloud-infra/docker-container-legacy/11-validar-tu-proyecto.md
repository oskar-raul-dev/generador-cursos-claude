# 🧪 Parte I · Fase 11 — Validar tu proyecto legacy: de "parece que funciona" a un veredicto

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · Node 10.24.1 con npm 6.14.12
> **Arquitectura objetivo del laboratorio:** `linux/amd64`
> **Código de esta fase:** [`src/11-validar-tu-proyecto/`](src/11-validar-tu-proyecto/) — cinco fixtures ejecutables con sus lockfiles congelados
> **Entregable:** `VALIDATION-REPORT.md`
> **Estado de la imagen al terminar:** sin cambios — esta fase no construye, valida. Cierra la Parte I con el toolchain de [F09](09-montar-tu-proyecto.md) intacto
> **Objetivo:** definir qué significa "compatible", ejecutar un protocolo repetible sobre tu proyecto real, y producir un veredicto que se sostenga con evidencia

---

## 1. 🧭 Dónde estamos

Última fase del taller. Tienes el toolchain construido, tu proyecto montado, el ciclo
`npm ci` → `test` → `build` funcionando y el debugger conectado.

Falta lo que convierte todo eso en trabajo entregable: **decir si tu proyecto es compatible, y
poder demostrarlo**. Porque "a mí me funciona" no es un veredicto — es una anécdota.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder:

- Explicar qué significa "compatible" en siete niveles distintos, y en cuál está tu proyecto.
- Ejecutar un protocolo de validación repetible, paso a paso, sobre cualquier proyecto legacy.
- Usar los cinco fixtures del curso como control, para separar un fallo tuyo de un fallo del
  laboratorio.
- Distinguir `npm ci` de `npm install` y saber por qué el lockfile es el centro de todo.
- Producir un `VALIDATION-REPORT.md` que otra persona pueda leer y reproducir.

---

## 3. 🚧 Qué NO entra todavía

Esta fase valida; la Parte II investiga:

- **Arqueología previa** —qué mirar antes de ejecutar nada— y **evidencia**: logs que sirvan
  para investigar, con el `PIPESTATUS` de `npm ci | tee` → **[F20](20-validacion-sistematica-y-evidencia.md)**.
- La **matriz de compatibilidad** completa, los **fallos provocados** y el **método de
  reducción** del problema → **F20**.
- **Qué hacer cuando falla**: dependencias nativas, ABI, `node-gyp` → **[F14](14-abi-libc-y-prebuilds.md)**, **[F15](15-laboratorios-dependencias-nativas.md)** y
  **[F32](32-catalogo-de-fallos-ii.md)**.
- **Watch y HMR con polling**, y por qué a veces el recargado en caliente no ve tus cambios →
  se introduce aquí, se resuelve en **[F18](18-networking-de-contenedores.md)** cuando haya red.
- **Podman** para validar el mismo proyecto en dos motores → **[F26](26-portabilidad-entre-motores.md)**.

---

## 4. 🧬 Qué significa "compatible": siete niveles

La palabra "compatible" se usa como si fuera binaria y no lo es. Este es el modelo del curso,
y la utilidad práctica es que te obliga a decir **hasta dónde** llegaste:

| | Nivel | Qué demuestra | Cómo se comprueba |
|---|---|---|---|
| 1 | **Declarada** | lo que el proyecto *dice* necesitar | `engines`, README, CI histórico |
| 2 | **De instalación** | las dependencias se resuelven y compilan hoy | `npm ci` termina con 0 |
| 3 | **De tests** | la suite pasa | `npm test` |
| 4 | **De build** | se produce el artefacto | `npm run build` |
| 5 | **De runtime** | la aplicación arranca y responde | `npm start` + una petición |
| 6 | **De workflow** | se puede *desarrollar*, no solo ejecutar | watch, HMR, debugger |
| 7 | **De plataforma** | funciona en tu arquitectura y motor reales | amd64 y arm64, Docker y Podman |

**El nivel 1 es el que más engaña.** Un `package.json` que declara:

```json
{ "engines": { "node": ">=8.10" } }
```

está diciendo *"este paquete espera Node 8 o superior"*. **No** está diciendo *"todas sus
dependencias transitivas siguen instalándose hoy"*, que es una afirmación completamente
distinta y mucho más difícil de sostener.

> 🧠 **Un veredicto útil nombra su nivel.** *"Compatible hasta nivel 4: instala, testea y
> construye; el dev server no arranca por X"* vale mil veces más que *"funciona"* o *"no
> funciona"*. Es lo que vas a escribir en el reporte.

---

## 5. 🧪 Los cinco fixtures, y por qué existen

En `src/11-validar-tu-proyecto/` hay cinco proyectos mínimos **ejecutables y congelados**.
No son ilustraciones: cada uno trae su `package-lock.json` versionado, generado dentro del
baseline.

| Fixture | Stack | Qué demuestra |
|---|---|---|
| `00-node-smoke` | Node puro, **cero dependencias** | Que el bind mount, los npm scripts, el build, los tests, el puerto, HTTP y `SIGTERM` funcionan **antes** de culpar a un framework |
| `10-vue2-min` | Vue 2.6.12 + Vue CLI 3.12.1 | Webpack 4 detrás del CLI, tests con Jest, dev server con HMR |
| `20-angular8-min` | Angular 8.2.14 + CLI 8.3.29 + TS 3.5.3 | Build con differential loading y dev server |
| `30-react16-min` | React 16.13.1 + react-scripts 3.4.4 | CRA 3 completo: build y tests con Jest |
| `40-svelte3-min` | Svelte 3.29.0 + Rollup 2.32.1 | Compilador propio, bundle con Rollup, servidor estático a mano |

### 5.1 Por qué se empieza sin framework

`00-node-smoke` no tiene ni una dependencia, y es el fixture más importante de los cinco.

Cuando tu proyecto Angular falla, hay dos posibilidades: el problema está en Angular, o el
problema está en tu laboratorio —el mount, el volumen, la arquitectura, los permisos—. El
fixture de control **separa esas dos hipótesis en treinta segundos**:

```text
00-node-smoke funciona   →  el laboratorio está bien. El problema es de tu proyecto.
00-node-smoke falla      →  no busques en Angular. Arregla el laboratorio primero.
```

> 🩺 **Es la primera comprobación de todo diagnóstico de esta parte del curso.** Antes de leer
> un solo log de Webpack, ejecuta el smoke test. **[F30](30-troubleshooting-metodo-y-herramientas.md)** convierte este reflejo en método.

### 5.2 La regla de oro: `npm install` una vez, `npm ci` siempre

El lockfile lo genera el autor del fixture **una sola vez**, dentro del baseline —Node
10.24.1, npm 6.14.12, `linux/amd64`—. A partir de ahí, el laboratorio usa exclusivamente:

```bash
npm ci
```

`npm ci` instala **exactamente** lo que dice el `package-lock.json`, borra `node_modules`
antes de empezar, y **falla** si el lock y el `package.json` no cuadran. `npm install` puede
resolver un árbol distinto y reescribir el lock.

> ⚠️ **Si ejecutas `npm install` sobre un fixture congelado, resuelves un árbol distinto al del
> curso y rompes justo lo que la fase intenta enseñar.** Y en tu proyecto real, lo mismo:
> reescribir un lockfile de 2019 con npm de hoy es la forma más rápida de convertir un problema
> conocido en uno nuevo.

Y el corolario que conviene tener grabado: **cuando `package-lock.json` cambie sin que hayas
tocado `package.json`, eso es el hallazgo, no un contratiempo.** Anótalo en el reporte.

---

## 6. 🚀 El protocolo de validación

Ocho pasos. Se ejecutan en orden y no se saltan, porque cada uno acota lo que puede fallar en
el siguiente.

### Paso 0 — Abre expediente

```bash
mkdir -p validacion/$(date -u +%Y%m%d)-mi-proyecto
cd validacion/$(date -u +%Y%m%d)-mi-proyecto
```

Todo lo que sigue —logs, salidas, el reporte— vive ahí. Sin expediente, dentro de tres días
no vas a poder responder "¿qué probaste exactamente?".

### Paso 1 — Registra el toolchain

No basta con "usé la imagen del curso". Registra **cuál**:

```bash
docker image inspect legacy-node-toolchain:phase09 \
  --format '{{.Id}} · {{.Architecture}} · {{.Os}}' | tee toolchain.txt
```

### Paso 2 — Verifica el runtime

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase09 \
  bash -c 'cat /etc/os-release | head -2
           node --version
           npm --version
           node -p "process.versions.modules"
           python2 --version 2>&1
           python3 --version
           gcc --version | head -1
           uname -m' | tee runtime.txt
```

Ese `process.versions.modules` es el **ABI de Node**, y es el número que explica por qué un
addon nativo no se puede reutilizar entre generaciones. Anótalo: en **[F14](14-abi-libc-y-prebuilds.md)** es el
protagonista.

### Paso 3 — Volumen limpio

Una validación que arranca sobre un volumen poblado no valida nada:

```bash
docker volume rm miproyecto-node10-modules 2>/dev/null || true
docker volume create miproyecto-node10-modules
```

> 🧭 **Un volumen por proyecto y por versión de Node.** Es la convención de [F09](09-montar-tu-proyecto.md), y aquí se
> vuelve obligatoria: si vas a probar el mismo proyecto con Node 10 y con Node 14, son dos
> volúmenes.

### Paso 4 — `npm ci`, y para si falla

```bash
docker exec legacy-node-dev npm ci 2>&1 | tee install.log
```

**Si `npm ci` falla, no sigas.** Los pasos 5 a 8 no tienen sentido sobre una instalación
incompleta, y sus errores te van a despistar. Clasifica el fallo primero:

| Síntoma | Familia | Dónde se resuelve |
|---|---|---|
| se queja del lock, o el lock no cuadra | **lockfile** | aquí: regenerar con cuidado, §5.2 |
| `gyp ERR!`, `node-gyp`, Python | **compilación nativa** | **[F05](05-python-y-node-gyp.md)** y **[F32](32-catalogo-de-fallos-ii.md)** |
| `NODE_MODULE_VERSION`, `.node` inválido | **ABI** | **[F14](14-abi-libc-y-prebuilds.md)** |
| 404, `ETIMEDOUT`, URL que ya no responde | **red o artefacto desaparecido** | **[F31](31-catalogo-de-fallos-i.md)** |
| `EACCES`, permisos | **usuario y volumen** | **[F17](17-usuarios-permisos-y-volumenes.md)** |

### Paso 5 — Comprueba que el lock no cambió

```bash
git status --porcelain package-lock.json
```

Si aparece modificado después de un `npm ci`, algo no encaja y es información valiosa. Al
reporte.

### Paso 6 — Tests, lint y build

```bash
docker exec legacy-node-dev npm test  2>&1 | tee test.log;  echo "exit=${PIPESTATUS[0]}"
docker exec legacy-node-dev npm run lint 2>&1 | tee lint.log; echo "exit=${PIPESTATUS[0]}"
docker exec legacy-node-dev npm run build 2>&1 | tee build.log; echo "exit=${PIPESTATUS[0]}"
```

> ⚠️ **`${PIPESTATUS[0]}` y no `$?`.** En una tubería, `$?` devuelve el código de salida del
> **último** comando — que es `tee`, y `tee` casi siempre tiene éxito. Sin esto registrarías
> "exit=0" en un paso que falló. Es una trampa clásica y **[F20](20-validacion-sistematica-y-evidencia.md)** la desarrolla entera.

No todos los proyectos tienen los tres scripts. Un script que no existe se anota como **N/A**,
que no es lo mismo que "falló" ni que "pasó".

### Paso 7 — Runtime

```bash
docker exec -d legacy-node-dev npm start
sleep 5
docker exec legacy-node-dev curl -sI http://localhost:3000 | head -1
```

Acceder desde el navegador de tu host necesita publicar el puerto, que es de **[F18](18-networking-de-contenedores.md)**. Aquí
comprobamos desde dentro, que ya demuestra el nivel 5.

### Paso 8 — Workflow

El nivel 6 es el que decide si puedes **trabajar** en el proyecto o solo ejecutarlo. Edita un
archivo fuente desde tu editor con el dev server corriendo, y mira si recompila.

> 📝 **Si el watch no ve tus cambios, no es tu culpa.** Los bind mounts en Docker Desktop —
> macOS y Windows— no siempre propagan los eventos de sistema de archivos que usa `inotify`. La
> solución de la época es forzar el sondeo:
>
> ```bash
> CHOKIDAR_USEPOLLING=true npm run serve
> ```
>
> Cuesta CPU y es la respuesta correcta para este escenario. En Linux nativo no suele hacer
> falta.

---

## 7. 📋 El Validation Report

El entregable. Que exista es lo que separa una tarde de pruebas de un trabajo que alguien
puede revisar.

📄 **`VALIDATION-REPORT.template.md`** — la plantilla, tal como está en `src/`. La copias a
la raíz de tu proyecto como `VALIDATION-REPORT.md` y la rellenas.

```markdown
# Validation Report

## Identificación
- Proyecto:
- Commit:
- Fecha UTC:
- Framework y versión:
- Fixture de referencia usado:

## Source snapshot
- package-lock.json SHA-256:
- working tree limpio: sí/no

## Toolchain
- Imagen y tag:
- Image ID:
- Plataforma:
- Debian:
- Node:
- npm:
- Node ABI (process.versions.modules):
- Python 2 / Python 3:
- GCC:

## Hipótesis inicial
- Node esperado:
- Evidencia que la sostiene:
- Riesgos identificados:

## Resultado

| Nivel | Etapa | Comando | Exit code | Resultado |
|---|---|---|---:|---|
| 2 | Install | npm ci | | |
| 3 | Tests | npm test | | |
| 3 | Lint | npm run lint | | |
| 4 | Build | npm run build | | |
| 5 | Run | npm start | | |
| 5 | HTTP | curl -sI localhost:PORT | | |
| 6 | Watch | edición de archivo | | |

## Veredicto
- Nivel alcanzado (1–7):
- Compatible para:
- NO compatible para:

## Lo que no se pudo resolver
- (qué, por qué, y qué haría falta)

## Reproducir
- (los comandos exactos, en orden)
```

**Las dos secciones que más valen** son las dos últimas, y son las que casi nadie escribe.
*"Lo que no se pudo resolver"* con su porqué es información honesta que le ahorra el trabajo al
siguiente. Y *"Reproducir"* es lo que convierte tu conclusión en algo verificable en lugar de
una opinión.

> 🧭 Este reporte es también el entregable de **[F34](34-proyecto-final.md)**, el proyecto final. Cuanto mejor lo hagas
> ahora, menos trabajo tendrás al terminar el curso.

---

## 8. ⚠️ Errores comunes y diagnóstico

**`npm ci` dice `can only install packages when your package.json and package-lock.json are in
sync`.** Exactamente lo que dice: alguien tocó uno sin el otro. En un proyecto legacy, la
tentación de "arreglarlo" con `npm install` es fuerte y casi siempre es mala idea: primero
averigua **qué** está desincronizado.

**`npm ci` falla y el mensaje habla de `node-gyp`.** No es un problema de npm. Vete a §6 paso
4, familia "compilación nativa", y de ahí a [F05](05-python-y-node-gyp.md).

**Los tests pasan pero el build falla.** Perfectamente normal: son niveles distintos (3 y 4).
Anota los dos y sigue; tu veredicto es "compatible hasta nivel 3".

**El build funciona con Node 10 y falla con Node 16.** Casi siempre es npm 8 reescribiendo el
lock, o una API que cambió. Es un hallazgo, no un fallo del laboratorio: al reporte.

**El dev server arranca pero no responde a `curl`.** Está escuchando en `127.0.0.1` dentro del
contenedor. Los fixtures del curso ya usan `--host 0.0.0.0` por eso mismo. **[F18](18-networking-de-contenedores.md)** lo explica.

**El watch no recompila al guardar.** §6 paso 8: `CHOKIDAR_USEPOLLING=true`.

**Todo falla de forma inexplicable.** Ejecuta `00-node-smoke`. Si también falla, el problema no
está en tu proyecto.

---

## 9. 📋 Checklist de validación

```text
[ ] src/11-validar-tu-proyecto/ existe con los cinco fixtures y sus lockfiles
[ ] 00-node-smoke pasa npm ci, test, build y start dentro del contenedor
[ ] Al menos un fixture de framework validado de principio a fin
[ ] Tu proyecto real montado, con su volumen propio y limpio
[ ] Los ocho pasos del protocolo ejecutados en orden
[ ] Cada etapa tiene su log en el expediente y su exit code con PIPESTATUS
[ ] package-lock.json sin cambios tras npm ci — o el cambio, documentado
[ ] VALIDATION-REPORT.md completo, incluidas las dos últimas secciones
[ ] El veredicto nombra el nivel alcanzado, no dice solo "funciona"
[ ] Sabes qué comprobar primero cuando algo falla de forma rara
```

---

## 10. 🧪 Ejercicios de la Fase 11 (22)

## 🟢 Fácil — el protocolo, paso a paso (1–6)

### 🟢 Ejercicio 1 — El smoke test completo

Valida `00-node-smoke` de principio a fin con los ocho pasos.

**Objetivo:** tener el control funcionando y el protocolo recorrido una vez sin fricción.

### 🟢 Ejercicio 2 — El ABI de las cuatro generaciones

Ejecuta `node -p "process.versions.modules"` con las cuatro versiones.

**Pregunta:** ¿qué número da cada una? Guárdalos: son la respuesta a "por qué mi módulo nativo
dejó de funcionar".

### 🟢 Ejercicio 3 — Valida un fixture de framework

Elige el fixture más cercano a tu stack y recorre el protocolo.

**Pregunta:** ¿en qué paso tardaste más? ¿Y en cuál dudaste?

### 🟢 Ejercicio 4 — `npm ci` frente a `npm install`

Sobre una copia de un fixture, ejecuta `npm install` y mira `git status`.

**Objetivo:** ver el lockfile cambiar y entender por qué el curso lo prohíbe.

### 🟢 Ejercicio 5 — La trampa de `$?`

Ejecuta un comando que falle a través de `| tee` y compara `$?` con `${PIPESTATUS[0]}`.

**Objetivo:** comprobar que `$?` te habría mentido.

### 🟢 Ejercicio 6 — Abre tu expediente

Crea la estructura del paso 0 para tu proyecto real y registra el toolchain.

## 🟡 Intermedio — aplicarlo a proyectos reales (7–13)

### 🟡 Ejercicio 7 — Sitúa tu proyecto en los siete niveles

Sin ejecutar nada todavía, **predice** hasta qué nivel llegará tu proyecto y por qué.

**Objetivo:** tener una hipótesis antes de la evidencia, que es como se investiga.

### 🟡 Ejercicio 8 — Tu proyecto, protocolo completo

Recorre los ocho pasos sobre tu proyecto legacy real y guarda todos los logs.

**Objetivo:** el trabajo central de la fase. Llega hasta donde llegues; el veredicto honesto
incluye dónde te paraste.

### 🟡 Ejercicio 9 — Escribe el reporte

Completa el `VALIDATION-REPORT.md`, incluidas las dos últimas secciones.

**Pregunta:** ¿podría otra persona reproducir tu resultado siguiendo solo la sección
"Reproducir"? Pruébalo borrando el volumen y siguiéndola tú mismo.

### 🟡 Ejercicio 10 — El mismo proyecto, dos generaciones

Valida un fixture con Node 10 y con Node 14, cada uno con su volumen.

**Pregunta:** ¿cambia algún resultado? ¿Cambió algún lockfile?

### 🟡 Ejercicio 11 — Watch con y sin polling

Arranca el dev server de un fixture, edita un archivo, y repite con
`CHOKIDAR_USEPOLLING=true`.

**Pregunta:** ¿notaste diferencia en tu plataforma? ¿Y en el consumo de CPU?

### 🟡 Ejercicio 12 — El hash del lockfile

Calcula el SHA-256 de tu `package-lock.json` antes y después de `npm ci`.

**Pregunta:** ¿por qué el reporte pide ese hash y no solo "sí/no"?

### 🟡 Ejercicio 13 — Cronometra los cinco fixtures

Validar cuesta tiempo, y conviene saber cuánto antes de prometerle a alguien que "esto lo
miro en un rato". Mide el paso 4 —el `npm ci`— sobre los cinco fixtures, cada uno con volumen
limpio:

```bash
for p in 00-node-smoke 10-vue2-min 20-angular8-min 30-react16-min 40-svelte3-min; do
  vol="${p}-node10-modules"
  docker volume rm "$vol" >/dev/null 2>&1; docker volume create "$vol" >/dev/null
  printf '%-18s ' "$p"
  /usr/bin/time -f '%e s' docker run --rm --platform linux/amd64 \
    --mount type=bind,src="$PWD/src/11-validar-tu-proyecto/$p",dst=/workspace \
    --mount type=volume,src="$vol",dst=/workspace/node_modules \
    legacy-node-toolchain:phase09 npm ci >/dev/null
done
```

**Pregunta:** ordena los cinco por tiempo y compáralo con el número de entradas de su
`package-lock.json` (`jq '.dependencies | length'`). ¿Es proporcional? Si alguno se sale de la
línea, mira **qué** instala ese: la respuesta suele empezar por `node-gyp`. Guarda los cinco
números — son tu presupuesto real de validación.

## 🟠 Difícil — cuando la validación falla (14–19)

### 🟠 Ejercicio 14 — Nivel 1 contra nivel 2

Busca el `engines` de tres dependencias de tu proyecto y compáralo con lo que realmente
instaló.

**Objetivo:** encontrar al menos una discrepancia. Casi siempre la hay.

### 🟠 Ejercicio 15 — Valida los cinco

Recorre el protocolo sobre los cinco fixtures y construye tu propia tabla de resultados.

**Pregunta:** ¿alguno da N/A en algún nivel? ¿Por qué Angular 8 no tiene tests ejecutables en
este baseline?

### 🟠 Ejercicio 16 — Rompe el lockfile

Cambia a mano una versión en el `package.json` de un fixture sin tocar el lock, y ejecuta
`npm ci`.

**Objetivo:** leer el error entero y saber, sin buscarlo, a qué familia del paso 4 pertenece.

### 🟠 Ejercicio 17 — Contamina el volumen

Instala un fixture con Node 10 y ejecuta después su build con Node 14 **sobre el mismo
volumen**.

**Pregunta:** ¿falla? ¿Con qué mensaje? ¿Menciona en algún momento el volumen o la versión?
Este es el fallo que la convención de nombres de [F09](09-montar-tu-proyecto.md) previene.

### 🟠 Ejercicio 18 — Diagnostica con el control

Rompe algo del laboratorio a propósito —monta el directorio equivocado, o usa la arquitectura
contraria— y valida un fixture de framework **sin** ejecutar antes el smoke test.

**Objetivo:** perderte un rato en logs de Webpack, y después comprobar que
`00-node-smoke` te habría dado la respuesta en treinta segundos. La lección de §5.1 se aprende
mejor sufriéndola.

### 🟠 Ejercicio 19 — El nivel 4 pasa y el nivel 5 falla

Los siete niveles de §4 no son decorativos: se puede aprobar uno y suspender el siguiente, y
la diferencia entre "compila" y "sirve" es exactamente donde vive esta fase. Provócalo. Arranca
el dev server de un fixture **sin publicar el puerto**:

```bash
docker run --rm --platform linux/amd64 \
  --mount type=bind,src="$PWD/src/11-validar-tu-proyecto/30-react16-min",dst=/workspace \
  --mount type=volume,src=react16-node10-modules,dst=/workspace/node_modules \
  legacy-node-toolchain:phase09 npm start
```

El proceso arranca y dice que escucha. Desde tu host, abre esa URL: no responde.

**Objetivo:** demostrar con **dos** comprobaciones que el proceso está bien y el problema es
otro — una desde dentro del contenedor con `curl`, y otra desde el host con `docker port`—, y
solo después arreglarlo. Escribe el veredicto de nivel 5 como lo pondrías en el reporte.

**Pregunta:** ¿es esto un fallo del proyecto, del laboratorio o del comando? De las tres
respuestas solo una es correcta, y confundirlas es el error que **[F18](18-networking-de-contenedores.md)**
existe para curar.

## 🔴 Muy difícil — veredicto y defensa (20–22)

### 🔴 Ejercicio 20 — Un fixture con dependencia nativa

Añade `node-sass@4.14.1` al fixture Vue 2, regenera el lock **dentro del baseline**, y valida.

**Pregunta:** ¿instaló desde prebuild o compiló? ¿Cómo lo sabes? Busca en `install.log` las
líneas que lo delatan. Es el ensayo general de **[F15](15-laboratorios-dependencias-nativas.md)**.

### 🔴 Ejercicio 21 — El veredicto que contradice tu hipótesis

Recupera la predicción que hiciste en el ejercicio 7 y compárala con lo que obtuviste en el 8.

**Objetivo:** si acertaste, explica **por qué** acertaste — qué evidencia lo sostenía— y no
"tenía buen ojo". Si fallaste, encuentra el dato que te habría hecho predecir bien y di en qué
paso del protocolo aparece. Un método que no mejora tus predicciones no es un método, es un
ritual.

### 🔴 Ejercicio 22 — Valida un proyecto que no es tuyo

Busca en GitHub un proyecto Vue 2, Angular 8 o React 16 archivado, sin instrucciones útiles, y
recorre el protocolo completo.

**Objetivo:** producir un `VALIDATION-REPORT.md` de un proyecto sobre el que no tienes contexto
previo — que es exactamente el trabajo real. Documenta también qué **no** pudiste determinar.

## 🔥 Opcionales

### 🔥 Ejercicio 23 — Automatiza el protocolo

Escribe `scripts/validate-project.sh` que ejecute los ocho pasos y genere el esqueleto del
reporte con los datos que se pueden capturar solos.

**Objetivo:** automatizar **después** de entender, como manda el curso. Lo que el script no
puede rellenar —la hipótesis, el veredicto, lo no resuelto— déjalo como plantilla.

### 🔥 Ejercicio 24 — La matriz reducida

Valida `00-node-smoke` contra las cuatro generaciones de Node y construye la matriz completa.

**Pregunta:** ¿pasa en las cuatro? Si algo cambia con Node 16, ya sabes por dónde mirar. Esta
matriz es un pendiente declarado del curso y **[F20](20-validacion-sistematica-y-evidencia.md)** la retoma.

## 💀 Boss fight

### 💀 Ejercicio 25 — Boss fight: el veredicto defendible

Toma el reporte del ejercicio 22 y entrégaselo a alguien —o déjalo reposar tres días y vuelve—
con esta pregunta: *"¿podrías tomar una decisión de negocio con esto?"*.

**Objetivo:** que el reporte responda las tres preguntas que haría quien decide: **¿se puede
mantener este proyecto hoy?**, **¿cuánto cuesta ponerlo a andar?**, y **¿qué riesgo queda
abierto?**. Si tu reporte tiene todos los logs y no responde a esas tres, tienes evidencia sin
conclusión — que es el error más común de esta fase. Reescríbelo hasta que las responda sin
perder la honestidad sobre lo que no sabes.

---

## 11. 📚 Referencias

**npm 6**
- `npm ci`: https://docs.npmjs.com/cli/v6/commands/npm-ci
- `package-lock.json`: https://docs.npmjs.com/cli/v6/configuring-npm/package-lock-json
- `engines`: https://docs.npmjs.com/cli/v6/configuring-npm/package-json#engines

**Node**
- Versiones de ABI (`process.versions`): https://nodejs.org/docs/latest-v10.x/api/process.html#process_process_versions
- Calendario de releases: https://github.com/nodejs/Release

**Watch y polling**
- Chokidar y `usePolling`: https://github.com/paulmillr/chokidar#performance

**Shell**
- `PIPESTATUS` en el manual de Bash: https://www.gnu.org/software/bash/manual/bash.html#index-PIPESTATUS

> ⚠️ **Los enlaces de npm apuntan a la v6 deliberadamente.** La documentación actual describe
> npm 9 y 10, cuyo `npm ci` y cuyo formato de lock se comportan distinto. En un proyecto de
> 2019 esa diferencia no es académica.

**Orden de lectura sugerido:** la documentación de `package-lock.json` v6 antes del ejercicio
12, y `PIPESTATUS` antes del 6.

---

## 12. 🏁 Resultado de la fase — y del taller

```text
CÓDIGO        src/11-validar-tu-proyecto/
                00-node-smoke     ← el control, cero dependencias
                10-vue2-min · 20-angular8-min
                30-react16-min · 40-svelte3-min
              todos con package-lock.json congelado en el baseline

MÉTODO        siete niveles de compatibilidad
              protocolo de ocho pasos
              VALIDATION-REPORT.md como entregable

TIENES        tu proyecto legacy instalando, testeando, construyendo,
              ejecutándose y depurándose dentro de un contenedor
              con el código viviendo en tu host

Y SABES       decir hasta qué nivel llega, con evidencia
```

> **La señal de que quedó bien:** *"si borro la imagen y el volumen y reconstruyo mañana en otra
> máquina, obtengo exactamente el mismo entorno — y tengo un documento que se lo demuestra a
> quien pregunte."*

---

## 13. 🎓 Fin de la Parte I

Aquí termina el taller. Empezaste con un proyecto que no compilaba en tu máquina y terminas
con un entorno reproducible, un flujo de trabajo completo y un veredicto documentado. Si solo
querías eso, ya está: **puedes parar aquí y el curso ha cumplido**.

Lo que la Parte I te dio hecho, la Parte II lo abre por dentro:

| Lo que te habrás preguntado | Dónde se responde |
|---|---|
| ¿Por qué borrar un archivo agranda la imagen? | **[F12](12-capas-cache-y-contexto.md)** y **[F13](13-overlayfs-y-copy-on-write.md)** |
| ¿Qué es exactamente `NODE_MODULE_VERSION`? | **[F14](14-abi-libc-y-prebuilds.md)** |
| ¿Por qué `node-sass` es así? | **[F15](15-laboratorios-dependencias-nativas.md)** |
| ¿Por qué mi app ignora `Ctrl+C`? | **[F16](16-pid1-senales-y-ciclo-de-vida.md)** |
| ¿Por qué este archivo salió con dueño `root`? | **[F17](17-usuarios-permisos-y-volumenes.md)** |
| ¿Por qué `localhost` no funciona? | **[F18](18-networking-de-contenedores.md)** |
| ¿Cómo corre un binario x86 en mi Mac ARM? | **[F21](21-arquitecturas-y-emulacion.md)** |
| ¿Docker o Podman? | **[F24](24-docker-y-podman-arquitectura.md)** |
| Algo falla y no sé por dónde empezar | **[F30](30-troubleshooting-metodo-y-herramientas.md)** |

La entrada está en [`00-PARTE-II-laboratorio.md`](00-PARTE-II-laboratorio.md), y empieza en **[F12](12-capas-cache-y-contexto.md)**
abriendo la caja que más se usa sin entender: las capas y la caché.
