# 💀 Parte II · Fase 33 — Forense avanzado y Boss Fight

> **Curso:** Docker Legacy Node
> **Imagen de diagnóstico:** `legacy-node-toolchain:diagnostic`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · `linux/amd64`
> **Requisitos:** **[F30](30-troubleshooting-metodo-y-herramientas.md)**, **[F31](31-catalogo-de-fallos-i.md)** y **[F32](32-catalogo-de-fallos-ii.md)**. Esta fase asume el método y el catálogo
> **Estado de la imagen al terminar:** sin cambios
> **Objetivo:** las técnicas que quedan cuando el catálogo se agota — y un Boss Fight que encadena todo el curso

---

## 1. 🧭 Dónde estamos

[F30](30-troubleshooting-metodo-y-herramientas.md) dio el método, [F31](31-catalogo-de-fallos-i.md) y [F32](32-catalogo-de-fallos-ii.md) el catálogo. Esta fase es lo que queda cuando **el catálogo no
tiene tu entrada**: técnicas para investigar lo que nadie anticipó, y las tres áreas donde el
laboratorio se toca con tu máquina real.

Y termina con el Boss Fight, que es el último ejercicio de diagnóstico del curso antes del
proyecto final.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder:

- Inspeccionar una imagen ajena **sin ejecutarla**.
- Hacer arqueología de capas: qué instrucción metió qué, y cuándo.
- Diagnosticar los fallos donde el IDE, Git y el host se cruzan con el contenedor.
- Usar matrices de síntomas para cubrir el espacio de causas de forma sistemática.
- Resolver un incidente completo con causas encadenadas.

---

## 3. 🚧 Qué NO entra todavía

- **El proyecto final**, que es este método aplicado a un repositorio real y desconocido →
  **[F34](34-proyecto-final.md)**.

Y esto queda **fuera de alcance del curso entero**, declarado: análisis de malware, ingeniería
inversa de binarios más allá de `readelf` y `nm`, y forense de seguridad tras un incidente real.
Este curso enseña a diagnosticar **fallos**, no a investigar **ataques**.

---

## 4. 🔬 Inspeccionar sin ejecutar

La primera regla del forense: **una imagen que no entiendes no se arranca, se lee**.

### 4.1 Los metadatos, sin arrancar nada

```bash
docker image inspect <imagen> --format '
arquitectura : {{.Architecture}}/{{.Os}}
creada       : {{.Created}}
entrypoint   : {{json .Config.Entrypoint}}
cmd          : {{json .Config.Cmd}}
workdir      : {{.Config.WorkingDir}}
usuario      : {{.Config.User}}
capas        : {{len .RootFS.Layers}}'

docker image inspect <imagen> --format '{{json .Config.Env}}' | jq
docker image inspect <imagen> --format '{{json .Config.Labels}}' | jq
```

> ⚠️ **`.Config.Env` incluye las variables horneadas en la imagen**, y ahí es donde a veces
> aparece una credencial que alguien metió sin querer. Es lo que el script de [F30](30-troubleshooting-metodo-y-herramientas.md) §10.1 redacta,
> y es lo primero que mirarías al auditar una imagen ajena.

Y si no la tienes descargada, **Skopeo** hace lo mismo contra el registry — [F27](27-registries-por-dentro.md) §8.

### 4.2 Arqueología de capas

```bash
docker image history --no-trunc <imagen>
```

Cada línea es una instrucción del Dockerfile con su tamaño. Con eso puedes **reconstruir el
Dockerfile aproximado** de una imagen que no tiene fuentes, que es exactamente lo que vas a
hacer con cualquier imagen heredada.

```bash
# ¿de dónde vinieron los megabytes?
docker image history --format '{{.Size}}\t{{.CreatedBy}}' <imagen> \
  | sort -rh | head -10
```

### 4.3 Abrir la imagen como archivos

Cuando `history` no basta:

```bash
mkdir /tmp/forense && docker save <imagen> | tar -x -C /tmp/forense
ls /tmp/forense                       # manifest, config, blobs
jq . /tmp/forense/manifest.json
```

Ahí tienes el grafo de [F27](27-registries-por-dentro.md) §5 como archivos reales. Y para buscar dentro de una capa concreta:

```bash
tar -tvf /tmp/forense/blobs/sha256/<digest> | head -40
tar -tvf /tmp/forense/blobs/sha256/<digest> | grep -i '\.wh\.'   # ← los whiteouts de F13
```

> 🩺 **Esta técnica responde la pregunta imposible:** *"¿este archivo estuvo alguna vez en la
> imagen, aunque ahora no esté?"*. Los whiteouts te lo dicen, y es la demostración del boss
> fight de [F13](13-overlayfs-y-copy-on-write.md).

### 4.4 Un contenedor sin arrancarlo

```bash
# crear sin ejecutar, y exportar su filesystem
docker create --name forense <imagen>
docker export forense | tar -tv | head -50
docker cp forense:/etc/os-release ./
docker rm forense
```

**Nada se ejecuta.** Para una imagen en la que no confías, es la diferencia entre inspeccionar y
arriesgarte.

---

## 5. 🟦 Cuando el IDE, Git y el host se cruzan

Tres áreas donde el fallo no está ni en el contenedor ni en el proyecto, sino en la frontera.

### 5.1 IDE

**El diagnóstico sigue siendo el de [F10](10-vscode-y-debugging.md) §8:** *¿falla también desde la terminal?* Y si el
problema es del IDE, las causas frecuentes son tres:

```bash
# ¿la task apunta al contenedor correcto?
grep -o 'legacy-[a-z0-9-]*' .vscode/tasks.json | sort -u
docker ps --format '{{.Names}}'

# ¿el mapeo de rutas del debugger es correcto?
jq '.configurations[] | {localRoot, remoteRoot}' .vscode/launch.json

# ¿la extensión corre donde debe? (F19 §7)
```

### 5.2 Git

**Finales de línea** —[F32](32-catalogo-de-fallos-ii.md) §8.8—, y su prevención estructural:

```bash
file scripts/*.sh | grep CRLF
cat .gitattributes 2>/dev/null || echo "sin .gitattributes ← esa es la causa raíz"
```

**El bit de ejecución**, que Git sí versiona:

```bash
git ls-files -s scripts/ | awk '$1=="100755"{print "ejecutable: "$4} $1=="100644"{print "NO ejecutable: "$4}'
```

**Y qué se versiona.** Un `node_modules` commiteado por error, o un `.env` en el historial: [F07](07-build-de-la-imagen.md)
§6 lo excluye del build, y del repositorio hay que sacarlo aparte.

```bash
git log --all --diff-filter=A --name-only | grep -E '^\.env|node_modules/' | head
```

### 5.3 El host

**El reloj**, que produce errores de TLS incomprensibles:

```bash
date -u
docker run --rm legacy-node-toolchain:phase15 date -u
```

Si difieren mucho —la VM del motor puede desincronizarse tras suspender el portátil—, cualquier
verificación de certificado falla con mensajes que no mencionan la hora.

**El disco**, que [F31](31-catalogo-de-fallos-i.md) §4.4 cubre. **La red corporativa**, que F31 §7.6 cubre.

---

## 6. 🧾 Matrices de síntomas

Una matriz cubre el espacio de causas de forma sistemática, en lugar de ir probando.

### 6.1 "No arranca"

| | logs vacíos | logs con error | exit 0 | exit ≠ 0 |
|---|---|---|---|---|
| **inmediato** | CMD terminó ([F16](16-pid1-senales-y-ciclo-de-vida.md) §4) | leer el error | comando que acaba | 125/126/127 (F16 §9.1) |
| **tras segundos** | OOM (F16 §9.3) | error de la app | proceso que acaba | fallo de la app |
| **tras el timeout** | SIGKILL: sin handler (F16 §5.1) | — | — | — |

### 6.2 "No responde"

| | el proceso vive | el proceso murió |
|---|---|---|
| **puerto publicado** | escucha en `127.0.0.1` ([F18](18-networking-de-contenedores.md) §5) | `docker logs` |
| **puerto sin publicar** | falta `-p`, se fija al crear | las dos cosas |

### 6.3 "Falla la instalación"

| | primer intento | reintento |
|---|---|---|
| **falla igual** | lockfile, red o toolchain | causa determinista |
| **falla distinto** | red intermitente o caché | reproduce antes de reparar ([F30](30-troubleshooting-metodo-y-herramientas.md) §7) |
| **funciona** | ⚠️ había estado sucio — **no lo des por resuelto** | |

> 🧭 **La casilla más peligrosa es la última.** "Reintenté y funcionó" significa que había estado
> que no controlabas, y va a volver. [F30](30-troubleshooting-metodo-y-herramientas.md) §11.

### 6.4 Cómo se lee una matriz, y cómo construyes la tuya

Una matriz no se lee de arriba abajo como una lista de sospechosos. Se lee **entrando por los
dos ejes a la vez**: observas el valor de la fila, observas el valor de la columna, y la
intersección te da una causa —una sola— o un `—` que significa "esa combinación no puede pasar".

Eso es lo que la separa de una lista de causas probables. Una lista te invita a probar la primera
y, si no era, la segunda; con veinte candidatos eso son veinte intentos y ningún criterio para
parar. Una matriz de 3×4 tiene doce casillas, pero **tú solo visitas una**, porque las dos
observaciones que hiciste antes de mirarla ya descartaron las otras once. La diferencia práctica
en un incidente es entre media hora de tanteo y dos minutos de lectura.

Construir la tuya es un ejercicio mecánico, y por eso vale la pena hacerlo antes de necesitarla:

1. **Escribe el síntoma tal y como te lo van a reportar.** "No arranca", no "fallo de
   inicialización del proceso principal". La matriz tiene que servir con la información que
   llega, que siempre es pobre.
2. **Elige dos ejes que puedas observar sin arreglar nada.** El código de salida, si hay logs, si
   el proceso vive, cuánto tardó. Un eje que exige reparar algo para medirlo no sirve: para
   entonces ya destruiste la evidencia.
3. **Rellena las casillas con una causa y una referencia.** Si una casilla te sale con dos causas,
   tus ejes no discriminan lo suficiente: te falta una tercera observación, o elegiste mal.
4. **Marca con `—` lo imposible.** Las casillas vacías enseñan tanto como las llenas, porque si
   observas una de ellas en la vida real, tu modelo del sistema está mal — y esa es información
   más valiosa que cualquier causa del cuadro.

> 💡 Las tres matrices de arriba no son las únicas que existen: son las tres que cubren el 80% de
> lo que te van a reportar. La cuarta la escribes tú, con el fallo que tu equipo repite.

---

## 7. 🧬 Técnicas que quedan cuando nada encaja

### 7.1 El entorno mínimo reproducible

Reducir hasta el mínimo —[F20](20-validacion-sistematica-y-evidencia.md) §9— pero del **entorno**, no del proyecto:

```mermaid
flowchart TD
    F["tu laboratorio completo falla"] --> S1["imagen base pelada + un comando<br/>¿falla?"]
    S1 --> S2["+ el toolchain, sin montajes<br/>¿falla?"]
    S2 --> S3["+ el bind mount<br/>¿falla?"]
    S3 --> S4["+ el volumen<br/>¿falla?"]
    S4 --> S5["+ tu proyecto<br/>aquí apareció"]
```

Cada escalón añade **una** variable. El primero que falla es tu capa.

### 7.2 Bisección en el tiempo

```bash
git bisect start
git bisect bad HEAD
git bisect good <commit-que-funcionaba>
# y en cada paso, ejecuta tu validación
```

Funciona igual sobre el historial del `Dockerfile` que sobre el del proyecto. Y para las
imágenes, la bisección es entre **digests** publicados —[F27](27-registries-por-dentro.md) §6—, si los guardaste.

### 7.3 Comparar dos entornos, campo a campo

```bash
# en cada máquina
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase15 \
  bash -c 'uname -m; node --version; npm --version; node -p process.versions.modules;
           ldd --version|head -1; gcc --version|head -1; python3 --version' > entorno-$(hostname).txt

diff entorno-maquinaA.txt entorno-maquinaB.txt
```

**El `diff` de dos entornos es la técnica más rentable** cuando "funciona en su máquina". La
primera línea que difiere suele ser la causa.

### 7.4 Cuando el error no es determinista

- **Cronométralo.** Un fallo que aparece siempre a los 10 segundos es un timeout, no azar
  — [F16](16-pid1-senales-y-ciclo-de-vida.md) §6.1.
- **Cuéntalo.** Uno de cada N reintentos apunta a red o a concurrencia.
- **Correlaciónalo.** ¿Ocurre solo tras suspender el portátil? ¿Solo con red corporativa? ¿Solo
  el primer build del día?

---

## 8. ⚠️ Errores comunes del forense

**Arrancar una imagen que no entiendes.** §4.4 la inspecciona sin ejecutar.

**Buscar en el catálogo cuando ya sabes que no está.** Ahí es donde entra §7.

**Modificar el entorno que estás investigando.** [F30](30-troubleshooting-metodo-y-herramientas.md) §9.1: depura desde fuera.

**Dar por resuelto un fallo que dejó de aparecer.** §6.3.

**Confundir correlación con causa.** "Empezó cuando actualicé X" es una hipótesis, y §7.2 la
comprueba.

---

## 9. 📋 Checklist de validación

```text
[ ] Inspeccionaste una imagen ajena sin arrancarla
[ ] Reconstruiste el Dockerfile aproximado de una imagen desde su history
[ ] Abriste una imagen con docker save y encontraste un whiteout
[ ] Exportaste el filesystem de un contenedor sin ejecutarlo
[ ] Comprobaste CRLF y el bit de ejecución en tu repositorio
[ ] Comparaste dos entornos con diff, campo a campo
[ ] Usaste las tres matrices de §6
[ ] Redujiste un fallo con el entorno mínimo de §7.1
[ ] Sabes por qué "reintenté y funcionó" no es una resolución
```

---

## 10. 🧪 Ejercicios de la Fase 33 (22)

## 🟢 Fácil — leer una imagen sin arrancarla (1–5)

### 🟢 Ejercicio 1 — Los metadatos de una imagen ajena

Elige una imagen pública y extrae los ocho campos de §4.1 sin arrancarla.

### 🟢 Ejercicio 2 — Variables horneadas

Busca `.Config.Env` en cinco imágenes públicas.

**Pregunta:** ¿alguna trae algo que no debería? Es más frecuente de lo que parece.

### 🟢 Ejercicio 3 — De dónde vienen los megas

Ejecuta el `history` ordenado por tamaño de §4.2 sobre tu toolchain.

**Pregunta:** ¿las tres capas más grandes son las que esperabas?

### 🟢 Ejercicio 4 — Reconstruye un Dockerfile

Con `history --no-trunc`, escribe el Dockerfile aproximado de una imagen pública.

**Pregunta:** ¿qué información se perdió y no puedes recuperar?

### 🟢 Ejercicio 5 — Abre una imagen

Haz `docker save` de tu toolchain, descomprímela y explora manifest, config y blobs.

## 🟡 Intermedio — comparar entornos y bisecar (6–11)

### 🟡 Ejercicio 6 — Caza un whiteout

Construye una imagen que borre un archivo en una capa posterior y encuentra su whiteout en el
tar.

**Objetivo:** cerrar el boss fight de [F13](13-overlayfs-y-copy-on-write.md) con la evidencia dentro de la imagen.

### 🟡 Ejercicio 7 — Sin ejecutar nada

Exporta el filesystem de una imagen con `create` y `export`, sin arrancarla.

### 🟡 Ejercicio 8 — Audita tu repositorio

Ejecuta las tres comprobaciones de §5.2 sobre tu proyecto.

**Pregunta:** ¿hay CRLF? ¿`.gitattributes`? ¿Algún `.env` en el historial?

### 🟡 Ejercicio 9 — El reloj desincronizado

Desincroniza el reloj de la VM del motor y ejecuta un `npm ci`.

**Objetivo:** ver un error de TLS que no menciona la hora en ningún momento.

### 🟡 Ejercicio 10 — Las tres matrices

Aplica las de §6 a tres fallos que provoques.

**Pregunta:** ¿te llevaron a la casilla correcta a la primera?

### 🟡 Ejercicio 11 — Entorno mínimo

Toma un fallo de tu proyecto y recorre la escalera de §7.1.

**Objetivo:** identificar el escalón exacto donde aparece.

## 🟠 Difícil — forense sobre lo que no documentaste (12–19)

### 🟠 Ejercicio 12 — Diff de dos entornos

Ejecuta §7.3 en dos máquinas —o en dos configuraciones de la tuya— y compara.

### 🟠 Ejercicio 13 — `git bisect` sobre el Dockerfile

Introduce un cambio que rompa el build hace varios commits y encuéntralo con bisección.

### 🟠 Ejercicio 14 — La casilla peligrosa

Construye un fallo que desaparezca al reintentar y averigua qué estado lo causaba.

### 🟠 Ejercicio 15 — La imagen sin fuentes

Alguien te da una imagen y ninguna documentación.

**Objetivo:** producir un informe de una página —qué contiene, cómo se construyó, qué ejecuta,
qué riesgos tiene— **sin arrancarla ni una vez**.

### 🟠 Ejercicio 16 — El fallo que el catálogo no tiene

Provoca algo que **no** esté en [F31](31-catalogo-de-fallos-i.md) ni en [F32](32-catalogo-de-fallos-ii.md) y diagnostícalo solo con el método.

**Objetivo:** demostrar que el método funciona sin catálogo, y añadir la entrada al tuyo.

### 🟠 Ejercicio 17 — Intermitente de verdad

Diseña un fallo que ocurra una de cada tres veces y determina por qué.

**Objetivo:** cronometrar, contar y correlacionar — §7.4.

### 🟠 Ejercicio 18 — El secreto en una capa antigua

Investiga si un archivo estuvo alguna vez en una imagen usando solo el tar de sus capas.

**Objetivo:** la técnica de §4.3, sobre una imagen que tú preparaste antes y olvidaste.

### 🟠 Ejercicio 19 — La imagen que nadie puede reconstruir

Te dan una imagen publicada, sin repositorio, sin `Dockerfile` y sin la persona que la
construyó. La pregunta del negocio es simple y desagradable: **¿podemos volver a producir
esto?**

**Objetivo:** responderla con evidencia, usando solo las herramientas de §4. Recorre las cuatro
preguntas en este orden: **de qué base parte** —¿el digest de la imagen base sigue existiendo en
su registry?—; **qué instaló** y si esas versiones siguen siendo obtenibles hoy; **qué copió
desde un contexto** que no tienes; y **qué descargó de internet** durante el build, mirando los
`RUN` del `history`.

Entrega un veredicto de tres estados: **reproducible**, **reproducible con esfuerzo** —
diciendo cuál— o **irrecuperable**, y para el último enumera exactamente qué se ha perdido.

**Pregunta:** casi siempre el punto de no retorno es el mismo: un `COPY` de archivos que no
están en ningún repositorio. ¿Es tu caso? Y la que enlaza con lo que el curso viene diciendo
desde [F07](07-build-de-la-imagen.md): si esa imagen se hubiera construido con las etiquetas OCI
de [F28](28-publicar-la-imagen.md) §8 —revisión de Git, fuente, fecha—, ¿cuántas de tus cuatro
preguntas habrían sido triviales?

## 🔴 Muy difícil — informe y transmisión (20–22)

### 🔴 Ejercicio 20 — El informe que otro pueda seguir

Toma el mejor diagnóstico que hayas hecho en el curso y reescribe su informe para alguien que no
estuvo.

**Objetivo:** que pueda reproducir el fallo, seguir tu razonamiento y llegar a la misma
conclusión sin preguntarte nada. Es el criterio que **[F34](34-proyecto-final.md)** va a evaluar, y practicarlo aquí sale
más barato.

### 🔴 Ejercicio 21 — Tu manual de forense

Escribe la página que consultarías cuando el catálogo no tenga tu entrada.

**Objetivo:** que las técnicas estén ordenadas por coste, empiece por inspeccionar sin ejecutar,
y termine por cuándo parar — [F30](30-troubleshooting-metodo-y-herramientas.md) §11.

### 🔴 Ejercicio 22 — El informe que cambió una decisión

El curso te ha hecho escribir informes de diagnóstico. Este es sobre el otro tipo de informe:
el que **alguien tiene que leer para decidir algo**, y que fracasa si es correcto pero no se
entiende.

**Objetivo:** coge el hallazgo más importante de todo tu paso por el curso —el proyecto no es
mantenible en la generación que creíais, o migrar a arm64 nativo cuesta más de lo que ahorra, o
la imagen no es reproducible— y escribe **dos versiones** del mismo informe.

**Versión técnica:** para alguien que va a reproducir tu trabajo. Comandos, salidas, versiones,
digests.
**Versión de decisión:** una página, para quien paga. Empieza por la recomendación, no por el
método. Cuantifica en tiempo o en dinero. Da alternativas con su coste. Y declara
explícitamente **qué no sabes**, que es lo que separa un informe honesto de una venta.

**Pregunta de cierre:** dale la segunda a alguien que no haya hecho el curso y pídele que te
diga, sin releerla, **qué le estás pidiendo que decida**. Si duda, el informe falla — y
reescríbelo hasta que no dude. La lección que cierra la Parte II: un diagnóstico que nadie
entiende no ha resuelto nada, solo ha cambiado el problema de sitio.

## 🔥 Opcionales

### 🔥 Ejercicio 23 — El saboteador

Escribe el script que introduce fallos al azar en un laboratorio, para que otros hagan el
ejercicio 21.

**Objetivo:** que cada sabotaje sea reversible y quede registrado en un archivo que el
diagnosticador no ve.

### 🔥 Ejercicio 24 — Forense sobre una imagen pública popular

Elige una imagen muy descargada y audítala entera con las técnicas de §4.

**Pregunta:** ¿qué encontraste que no esperabas? ¿La usarías en tu pipeline?

## 💀 Boss fight

### 💀 Ejercicio 25 — Boss Fight: el laboratorio saboteado

**El último ejercicio de diagnóstico del curso.** Alguien —un compañero, o tú mismo con un
script que lo haga al azar— introduce **cinco fallos simultáneos** en tu laboratorio, uno en
cada uno de estos ámbitos: la imagen, un volumen, la red, el proyecto, y el propio host o motor.
No sabes cuáles ni cuántos son de cada tipo.

**Restricciones, que son lo que lo hace un boss fight:**

```text
❌ nada de prune general, chmod 777, --privileged ni reinstalar Docker
❌ no puedes reconstruir la imagen desde cero hasta haber diagnosticado
✅ tienes el método (F30), los catálogos (F31, F32) y el forense de esta fase
✅ tienes que producir el TROUBLESHOOTING-REPORT.md de los cinco
```

**Objetivo.** Encontrar los cinco, con la evidencia de cada uno, y —lo que de verdad se evalúa—
**el orden en que los abordaste y por qué**. Algunos enmascaran a otros: un fallo de red hace que
un problema de dependencias parezca de red, y un fallo de volumen hace que uno de proyecto
parezca de ABI. Documenta, por cada fallo: el síntoma inicial, las hipótesis que descartaste con
su comando, la causa contribuyente, la causa raíz, y la prevención.

**Y la última pregunta, que es la que cierra la Parte II:** de los cinco, **¿cuántos habrías
diagnosticado en la Fase 11, antes de la Parte II?** Esa diferencia es lo que has aprendido en
veintidós fases, y conviene ponerle nombre antes de ir al proyecto final.

---

## 11. 📚 Referencias

- `docker image history`: https://docs.docker.com/reference/cli/docker-image-history/
- `docker save` y `export`: https://docs.docker.com/reference/cli/docker-image-save/
- Whiteouts en el formato de capa OCI: https://github.com/opencontainers/image-spec/blob/main/layer.md
- `git bisect`: https://git-scm.com/docs/git-bisect
- `gitattributes(5)`: https://git-scm.com/docs/gitattributes
- Skopeo: https://github.com/containers/skopeo

**Orden de lectura sugerido:** el formato de capa OCI antes del ejercicio 6, y `gitattributes`
antes del 8.

---

## 12. 🏁 Resultado de la fase

```text
SIN EJECUTAR    inspect · history · save + tar · create + export
                los whiteouts responden "¿estuvo esto alguna vez aquí?"

LAS FRONTERAS   IDE   ¿falla también desde la terminal?
                Git   CRLF · bit de ejecución · qué se versionó
                host  reloj · disco · red corporativa

MATRICES        no arranca · no responde · falla la instalación
                y la casilla peligrosa: "reintenté y funcionó"

CUANDO NADA ENCAJA
                entorno mínimo, un escalón por vez
                bisección en el tiempo
                diff de dos entornos, campo a campo
                cronometrar · contar · correlacionar
```

> **La señal de que quedó bien:** *"me dan una imagen desconocida y un fallo que no está en
> ningún catálogo, y sé por dónde empezar — sin arrancar nada y sin destruir evidencia."*

Aquí termina el bloque de diagnóstico, y con él **el contenido técnico del curso**. En **[F34](34-proyecto-final.md)**
solo queda demostrarlo: un repositorio de 2019, sin instrucciones y sin nadie a quien
preguntarle.
