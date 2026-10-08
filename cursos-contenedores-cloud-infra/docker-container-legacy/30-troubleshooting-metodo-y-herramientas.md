# 🕵️ Parte II · Fase 30 — Troubleshooting: método antes que catálogo

> **Curso:** Docker Legacy Node
> **Imagen de diagnóstico:** `legacy-node-toolchain:diagnostic`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · `linux/amd64`
> **Dockerfile pedagógico de esta fase:** `dockerfiles/09-diagnostic.Dockerfile`
> **Código de esta fase:** [`src/30-troubleshooting-metodo-y-herramientas/`](src/30-troubleshooting-metodo-y-herramientas/)
> **Requisitos:** haber recorrido la Parte II. Esta fase generaliza lo que llevas viendo
> **Estado de la imagen al terminar:** el toolchain sin cambios, más una imagen de diagnóstico separada
> **Objetivo:** un método que funcione con fallos que este curso no anticipó — porque el catálogo se acaba y el método no

---

## 1. 🧭 Dónde estamos

Llevas dieciocho fases de Parte II acumulando tablas de "síntoma → causa". Son útiles y tienen
un límite: **solo cubren lo que alguien anticipó**.

Esta fase da lo que sí escala: un método. Y lo hace en el orden correcto —**método primero,
catálogo después**—, porque un catálogo sin método produce gente que busca el mensaje de error
en Internet y prueba lo que sea que encuentre.

**[F31](31-catalogo-de-fallos-i.md)** y **[F32](32-catalogo-de-fallos-ii.md)** son el catálogo. Esta es la que hace que el catálogo no haga falta.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder:

- Ejecutar un **protocolo de 60 segundos** que recoja evidencia antes de tocar nada.
- Distinguir **síntoma**, **causa contribuyente** y **causa raíz**.
- Situar un fallo en la **taxonomía de capas** y saber cuál probar primero.
- Formular **hipótesis falsables** en lugar de intuiciones.
- Reconocer los **anti-patrones** de diagnóstico, incluidos los que ya has usado.
- Usar una imagen de diagnóstico separada y el script `diagnose-container.sh`.
- Saber **cuándo parar**.

---

## 3. 🚧 Qué NO entra todavía

- **El catálogo de fallos** por área → **[F31](31-catalogo-de-fallos-i.md)** (engine, build, registry, red) y **[F32](32-catalogo-de-fallos-ii.md)** (APT,
  Node, node-gyp, ABI, filesystem).
- **El forense avanzado** y el Boss Fight → **[F33](33-forense-y-boss-fight.md)**.
- **El proyecto final**, que aplica todo esto a un repositorio desconocido → **[F34](34-proyecto-final.md)**.

---

## 4. 🚑 El protocolo de 60 segundos

Antes de tocar nada, recoge el estado. Cuesta un minuto y es lo que te permite volver atrás.

> 💡 **Ten a mano la chuleta.** El apéndice [a15](a15-chuleta-de-comandos.md) reúne los
> comandos del curso agrupados por tarea —construir, ejecutar, inspeccionar, diagnosticar,
> validar, publicar y limpiar—, y cierra con la traducción a `podman`. Diagnosticar con la chuleta
> abierta en otra pestaña ahorra la mitad de los tropiezos de sintaxis.

```bash
CONTAINER=legacy-node-dev

# 1. cuándo y con qué
date -u +"%Y-%m-%dT%H:%M:%SZ"
docker version --format 'client {{.Client.Version}} · server {{.Server.Version}}'
docker context show

# 2. el estado del contenedor, destilado
docker inspect --format '
status  = {{.State.Status}}
running = {{.State.Running}}
exit    = {{.State.ExitCode}}
oom     = {{.State.OOMKilled}}
started = {{.State.StartedAt}}
restarts= {{.RestartCount}}
image   = {{.Config.Image}}
' "$CONTAINER"

# 3. qué dijo antes de morir
docker logs --timestamps --tail 200 "$CONTAINER"

# 4. qué le pasó al contenedor, desde fuera
docker events --since 10m --filter "container=$CONTAINER"

# 5. recursos y procesos, si sigue vivo
docker stats --no-stream "$CONTAINER"
docker top "$CONTAINER"
```

**Y recién después de eso** viene la pregunta que importa:

> 🩺 **¿Qué capa está fallando?**

Fíjate en lo que **no** hay en esos cinco pasos: ningún cambio. Ni un `restart`, ni un `rm`, ni
un `prune`. Todo es lectura. Es lo que [F15](15-laboratorios-dependencias-nativas.md) §9.1 llamaba respetar la evidencia, ahora convertido
en rutina de un minuto.

---

## 5. 🩺 Síntoma no es causa

Es la distinción que separa arreglar de parchear.

```text
SÍNTOMA               lo que ves
                      "npm ci falla"

CAUSA CONTRIBUYENTE   algo que hizo falta para que ocurriera
                      "el volumen tenía módulos de otra generación"

CAUSA RAÍZ            lo que, corregido, evita que vuelva a pasar
                      "el nombre del volumen no incluye la versión de Node"
```

**Arreglar la contribuyente resuelve hoy** —borras el volumen y sigues—. **Arreglar la raíz
resuelve siempre** —cambias la convención de nombres y no vuelve a ocurrir—.

Las dos son legítimas y en momentos distintos. Cuando el equipo está parado, arreglas la
contribuyente; después, y sin excepción, vuelves a por la raíz. Es lo que [F15](15-laboratorios-dependencias-nativas.md) §9 llamaba
distinguir la corrección mínima de la solución estructural.

> ⚠️ **La trampa:** si solo arreglas contribuyentes, cada semana te encuentras el mismo problema
> con otra cara, y cada vez lo resuelves "más rápido". Eso no es experiencia: es un bucle.

---

## 6. 🧱 Taxonomía de capas

Un fallo en este laboratorio está en una de estas ocho capas. Situarlo es la mitad del trabajo.

```mermaid
flowchart TD
    P8["8 · PROYECTO<br/>tu código, package.json, lockfile"]
    P7["7 · DEPENDENCIAS<br/>node_modules, addons nativos, ABI"]
    P6["6 · RUNTIME<br/>Node, npm, Python, el toolchain"]
    P5["5 · IMAGEN<br/>capas, Dockerfile, paquetes del sistema"]
    P4["4 · CONTENEDOR<br/>proceso, PID 1, señales, límites"]
    P3["3 · MONTAJES<br/>bind mounts, volúmenes, permisos"]
    P2["2 · MOTOR<br/>Docker o Podman, daemon, VM"]
    P1["1 · HOST<br/>tu máquina, red, disco, arquitectura"]
    P8 --- P7 --- P6 --- P5 --- P4 --- P3 --- P2 --- P1
```

**La estrategia que menos tiempo pierde: prueba por los extremos, no de arriba abajo.**

```mermaid
flowchart TD
    Q{"¿funciona el fixture de control<br/>00-node-smoke?"}
    Q -- "no" --> A["el problema está en las capas 1–5<br/>tu proyecto es inocente"]
    Q -- "sí" --> B["el problema está en las capas 6–8"]
    A --> R["en cada mitad, repite: parte por el medio"]
    B --> R
```

Es una búsqueda binaria, y es la razón de que ese fixture exista desde [F11](11-validar-tu-proyecto.md) §5.1.

**Y la tabla de primera prueba por síntoma**, que te sitúa en la capa en un comando:

| Síntoma | Capa probable | Primera prueba |
|---|---|---|
| `Cannot connect to the Docker daemon` | 2 · motor | `docker version` |
| el contenedor sale al instante | 4 · contenedor | `docker logs` y `docker inspect .State` |
| `/workspace` vacío | 3 · montajes | `docker inspect --format '{{json .Mounts}}'` |
| `EACCES` | 3 · montajes | `id` dentro y `ls -ln` |
| el build falla | 5 · imagen | `--progress=plain` y leer el primer error |
| `npm ci` falla | 7 · dependencias | el log completo, y `grep` de [F15](15-laboratorios-dependencias-nativas.md) §9.4 |
| `NODE_MODULE_VERSION` | 7 · dependencias | `node -p process.versions.modules` |
| el server no responde | 3 o 4 | `ss -lntp` dentro |
| `exec format error` | 1 · host | `file` y `uname -m` |
| todo va lentísimo | 1 o 2 | `uname -m` y las capas de [F26](26-portabilidad-entre-motores.md) §4 |

---

## 7. 🧪 Hipótesis falsables

La diferencia entre diagnosticar y adivinar cabe en una frase: **una hipótesis útil se puede
demostrar falsa**.

```text
❌ "creo que es un problema del volumen"
     no dice qué comprobar, y siempre se puede seguir creyendo

✅ "si el volumen tuviera módulos de Node 10, entonces `file` sobre
    node_modules/bcrypt/**.node diría NODE_MODULE_VERSION 64 y no 83.
    Lo compruebo en un comando."
     tiene una predicción concreta y una forma de refutarla
```

**La estructura, para que salga sola:**

```text
SI  <causa que sospecho>
ENTONCES  <esto debería observarse>
LO COMPRUEBO CON  <este comando>
```

Y las dos reglas de método que ya conoces de [F20](20-validacion-sistematica-y-evidencia.md) §9, ahora en su sitio:

> 🧭 **Una variable a la vez.** Si cambias tres cosas y funciona, no sabes cuál era, y la
> próxima vez vuelves a empezar. Es incómodo y es más rápido.

> 🧭 **Reproducir antes de reparar.** Si no puedes provocar el fallo cuando quieras, no vas a
> poder demostrar que lo arreglaste. "Ya no pasa" no es lo mismo que "está resuelto".

### 7.1 Control y experimento

Cambia **una** cosa entre dos ejecuciones y compara:

```text
CONTROL      fixture 00-node-smoke, Node 10, amd64, volumen limpio   → funciona
EXPERIMENTO  lo mismo, cambiando SOLO la versión de Node a 14        → falla
                                                                      └── ahí está
```

Si el control no funciona, no tienes un experimento: tienes dos fallos.

---

## 8. ⚰️ Los anti-patrones, con nombre y apellido

Los seis que este curso ha ido nombrando, juntos y con lo que destruye cada uno.

| Anti-patrón | Qué destruye | Qué hacer |
|---|---|---|
| `chmod -R 777` | la información de permisos original | [F17](17-usuarios-permisos-y-volumenes.md) §8: averigua qué UID escribe dónde |
| `--privileged` | todas las protecciones a la vez | [F25](25-rootless-y-user-namespaces.md) §9.3: `--cap-add` de la que falte |
| `rm package-lock.json` | la única fuente de verdad del proyecto | [F20](20-validacion-sistematica-y-evidencia.md) §5.2: averigua qué está desincronizado |
| `docker system prune -a --volumes` | imágenes, volúmenes **y la evidencia** | borra el volumen concreto, por su nombre |
| `npm install --force` | el conflicto que te estaba informando | léelo antes de forzarlo |
| reinstalar Docker | tu tiempo, y no arregla nada | el protocolo de §4 |

### 8.1 La escalera de martillos

Todos "funcionan" a veces, y ese es justo el problema. Ordénalos por daño y **empieza siempre por
arriba**:

```text
1. leer el error entero                          ← gratis, y resuelve más de lo que parece
2. leer el log completo, no las últimas líneas
3. inspeccionar estado y montajes
4. probar el fixture de control
5. reducir al caso mínimo
6. reconstruir sin caché
7. borrar UN volumen concreto
8. borrar el contenedor y recrearlo
9. …
─────────────────────────────────────────────── 
N. prune general, --privileged, chmod 777        ← el último recurso, no el primero
```

> ⚰️ **El reflejo que más caro sale** es empezar por el escalón N porque "es más rápido". Lo es
> esta vez. Y como no aprendiste nada, la próxima vez también empiezas por N.

---

## 9. 🧰 La imagen de diagnóstico

Herramientas como `strace`, `ltrace` o `gdb` son valiosísimas cuando hacen falta y **no deben
vivir en el toolchain**:

- **Engordan la imagen** que usas todos los días para algo que necesitas una vez al mes.
- **`strace` necesita `CAP_SYS_PTRACE`**, y tener la herramienta invita a conceder la capability
  "por si acaso".
- **El toolchain es para construir**, no para auditar. Mezclar propósitos hace que ninguno esté
  claro.

📄 **`dockerfiles/09-diagnostic.Dockerfile`**

```dockerfile
# syntax=docker/dockerfile:1
# Imagen SEPARADA del toolchain: herramientas de diagnóstico que no queremos
# en la imagen de trabajo diaria. Se usa puntualmente y no se publica.

FROM debian/eol:buster

LABEL org.opencontainers.image.title="legacy-node-toolchain-diagnostic"
LABEL org.opencontainers.image.description="Herramientas de diagnóstico para el laboratorio legacy"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       binutils \
       ca-certificates \
       curl \
       dnsutils \
       file \
       iproute2 \
       jq \
       less \
       lsof \
       netcat-openbsd \
       procps \
       strace \
       tcpdump \
       vim \
    && rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-c"]
CMD ["bash"]
```

### 9.1 Depurar desde fuera, antes de entrar

```bash
# comparte el PID namespace del contenedor problemático: ves SUS procesos
docker run --rm -it \
  --pid=container:legacy-node-dev \
  --network=container:legacy-node-dev \
  legacy-node-toolchain:diagnostic \
  bash
```

Dentro tienes `ps`, `ss`, `lsof` y `tcpdump` viendo **los procesos y la red del contenedor
problemático**, sin haberle instalado nada y sin modificarlo.

> 🧭 **"Debug desde fuera" antes de "entrar y tocar".** Instalar herramientas dentro del
> contenedor que estás diagnosticando lo modifica, y con eso pierdes parte de lo que querías
> observar. Este patrón evita justo eso.

Y para `strace`, que necesita el permiso:

```bash
docker run --rm -it \
  --pid=container:legacy-node-dev \
  --cap-add=SYS_PTRACE \
  legacy-node-toolchain:diagnostic \
  strace -f -p 1
```

**`--cap-add=SYS_PTRACE`, no `--privileged`.** Es el ejemplo canónico de [F25](25-rootless-y-user-namespaces.md) §9.3.

---

## 10. 📜 El script de diagnóstico

`src/30-troubleshooting-metodo-y-herramientas/30-diagnose-container.sh` automatiza el protocolo
de §4 y produce un informe.

**Lo que recoge:** versión y contexto del motor, estado del contenedor, montajes, últimas
líneas de log, eventos recientes, procesos y estadísticas, más la triangulación de arquitectura
de [F21](21-arquitecturas-y-emulacion.md) §4.1.

### 10.1 El detalle que hace útil el script: redacción de secretos

> 🚨 **Un `docker inspect` completo incluye `.Config.Env` en claro**, con todas las variables
> de entorno: tokens, URLs de base de datos con contraseña, claves de API. Un informe de
> diagnóstico que se comparte en un chat con eso dentro es una fuga.

El script aplica **deny by default**:

```text
conserva el NOMBRE de cada variable, que es la evidencia útil
tapa el VALOR, salvo una allowlist corta: PATH, HOME, HOSTNAME, NODE_VERSION…
```

```text
"Env": [
    "NPM_TOKEN=<redacted>",
    "MY_DB_URL=<redacted>",
    "NODE_VERSION=10.24.1",
    "PATH=/usr/local/bin:/usr/bin"
]
```

**Deny by default y no allowlist de sospechosos**, y la diferencia importa: una lista de nombres
"peligrosos" —`TOKEN`, `PASSWORD`, `SECRET`— deja pasar todo lo demás, incluida la variable que
alguien llamó `MY_DB_URL`.

> ⚠️ **Lo que la redacción NO cubre**, y hay que saberlo: secretos pasados como **argumento** de
> un comando —visibles en `docker top`— y secretos que la propia aplicación escribió en sus
> **logs**. Revisa el informe antes de compartirlo. Ninguna redacción automática sustituye a
> mirar.

### 10.2 El informe

`30-TROUBLESHOOTING-REPORT.md` es la plantilla del expediente, con la misma estructura que la
guía de estilo §13 fija para cualquier documento de incidente:

```text
1. Síntoma, en palabras de quien lo sufre
2. Pasos de reproducción exactos: versiones, motor, arquitectura, host
3. Evidencia observable: salida literal, logs, inspect, códigos de salida
4. Capa sospechosa: host · motor · imagen · contenedor · volumen · proyecto
5. Hipótesis falsable, y la prueba que la confirma o la descarta
6. Causa raíz, hasta la línea del Dockerfile o el paquete concreto
7. Corrección aplicada, distinguiendo parche mínimo de solución estructural
8. Prevención: comprobación, pin, script o entrada de checklist
```

---

## 11. 🛑 Cuándo detenerse

Un apartado que casi ningún material incluye y que ahorra tardes enteras.

**Para cuando:**

- Llevas más de una hora **sin una hipótesis nueva**. Estás probando cosas, no diagnosticando.
- Has empezado a repetir intentos que ya hiciste.
- El coste de seguir supera el de un rodeo: usar la otra arquitectura, otra generación de Node,
  o ejecutarlo en CI.
- **No puedes reproducirlo.** Sin reproducción no hay diagnóstico posible; lo que toca es
  conseguir la reproducción, no seguir intentando arreglos.

**Y qué hacer al parar**, que no es rendirse:

```text
escribe lo que sabes y lo que descartaste, con la evidencia
declara el rodeo como deuda 💸, con su coste
y vuelve mañana, o pásaselo a alguien con el expediente hecho
```

> 🧭 **Un expediente bien hecho vale más que una hora más de intentos.** Quien lo retome
> —tú mañana, o un compañero— empieza donde lo dejaste en lugar de desde cero. Y muchas veces,
> escribirlo es lo que hace aparecer la hipótesis que faltaba.

---

## 12. ⚠️ Errores comunes del propio método

**Empezar a cambiar cosas antes de leer.** El protocolo de §4 dura un minuto.

**Leer solo las últimas líneas del error.** En una salida de `node-gyp` o de Webpack, el primer
error es la causa y los siguientes son consecuencia. [F04](04-toolchain-de-compilacion.md) §10 ya lo avisaba.

**Buscar el mensaje en Internet como primer paso.** Sirve **después** de saber en qué capa
estás; antes, te lleva a soluciones de otro problema con el mismo mensaje.

**Cambiar varias cosas "para ir más rápido".** §7.

**No guardar la evidencia.** Cuando el fallo desaparece sin que sepas por qué, lo único que te
queda es lo que registraste.

**Compartir un informe con secretos dentro.** §10.1.

---

## 13. 📋 Checklist de validación

```text
[ ] Ejecutaste el protocolo de 60 segundos sobre un contenedor real
[ ] Distingues síntoma, causa contribuyente y causa raíz con un ejemplo tuyo
[ ] Puedes situar un fallo en la taxonomía de ocho capas
[ ] Formulaste una hipótesis con la estructura SI / ENTONCES / LO COMPRUEBO
[ ] Usaste el fixture de control como búsqueda binaria
[ ] Construiste la imagen de diagnóstico
[ ] Diagnosticaste desde fuera con --pid=container:
[ ] Usaste strace con --cap-add=SYS_PTRACE y no con --privileged
[ ] El script de diagnóstico redacta secretos: comprobado con una variable de prueba
[ ] Puedes nombrar los seis anti-patrones y qué destruye cada uno
[ ] Sabes cuándo parar
```

---

## 14. 🧪 Ejercicios de la Fase 30 (25)

## 🟢 Fácil — el protocolo y la taxonomía (1–5)

### 🟢 Ejercicio 1 — El protocolo de 60 segundos

Ejecútalo sobre un contenedor sano y sobre uno que acabas de romper.

**Pregunta:** ¿qué campo del `inspect` te dice más rápido qué pasó?

### 🟢 Ejercicio 2 — Síntoma, contribuyente, raíz

Toma tres fallos que ya provocaste en fases anteriores y descompón cada uno en los tres niveles.

**Objetivo:** que la causa raíz sea siempre una decisión, no un accidente.

### 🟢 Ejercicio 3 — Sitúa diez síntomas

Con la tabla de §6, sitúa diez errores que hayas visto en el curso.

**Pregunta:** ¿cuántos se resolvían con la primera prueba de su fila?

### 🟢 Ejercicio 4 — Una hipótesis falsable

Escribe tres hipótesis con la estructura de §7 para un fallo que tengas ahora.

### 🟢 Ejercicio 5 — La imagen de diagnóstico

Constrúyela y compara su tamaño con el toolchain.

**Pregunta:** ¿cuánto habría engordado la imagen de trabajo diaria?

## 🟡 Intermedio — las herramientas del método (6–12)

### 🟡 Ejercicio 6 — La búsqueda binaria

Rompe algo en la capa 3 y diagnostícalo usando solo el fixture de control como discriminador.

**Objetivo:** llegar a la mitad correcta en un comando.

### 🟡 Ejercicio 7 — Desde fuera

Comparte el PID namespace de un contenedor y ejecuta `ps -ef` desde la imagen de diagnóstico.

**Objetivo:** ver sus procesos sin haberle instalado nada.

### 🟡 Ejercicio 8 — `strace` sobre PID 1

Con `--cap-add=SYS_PTRACE`, traza el proceso principal de un contenedor durante un `docker stop`.

**Objetivo:** ver la llegada de `SIGTERM` a nivel de syscall. Es [F16](16-pid1-senales-y-ciclo-de-vida.md) §6 desde otro ángulo.

### 🟡 Ejercicio 9 — Sin la capability

Repite sin `--cap-add`.

**Pregunta:** ¿qué error da? ¿Y con `--privileged` funciona? ¿Qué has concedido de más?

### 🟡 Ejercicio 10 — El script, con secretos

Arranca un contenedor con `NPM_TOKEN=npm_supersecret123` y `MY_DB_URL=postgres://u:p@h/db`,
ejecuta el script y busca las dos cadenas en el informe.

**Objetivo:** cero apariciones, y `NODE_VERSION` visible. Es la verificación de §10.1.

### 🟡 Ejercicio 11 — Red desde fuera

Con `--network=container:`, usa `ss` y `tcpdump` para ver el tráfico de un contenedor.

**Objetivo:** diagnosticar un problema de [F18](18-networking-de-contenedores.md) sin tocar el contenedor afectado.

### 🟡 Ejercicio 12 — Un informe completo

Escribe un `TROUBLESHOOTING-REPORT.md` con los ocho puntos de §10.2 para un fallo real.

## 🟠 Difícil — método contra reflejo (13–20)

### 🟠 Ejercicio 13 — Rompe la redacción

Pasa un secreto **como argumento** de un comando y busca si aparece en el informe.

**Objetivo:** confirmar el aviso de §10.1 sobre lo que la redacción no cubre.

### 🟠 Ejercicio 14 — El primer error, no el último

Toma una salida larga de fallo de `node-gyp` y localiza el primer error real.

**Pregunta:** ¿a cuántas líneas del final estaba?

### 🟠 Ejercicio 15 — La escalera, medida

Toma un fallo y resuélvelo dos veces: bajando la escalera de §8.1 desde arriba, y saltando
directamente al escalón N.

**Pregunta:** ¿cuál tardó menos? ¿Y en cuál sabes ahora qué pasaba?

### 🟠 Ejercicio 16 — Diagnostica a ciegas

Pídele a alguien que rompa el laboratorio de una forma que no conozcas y diagnostícalo aplicando
la fase entera, documentando cada paso.

**Objetivo:** llegar a la causa raíz sin haber destruido evidencia.

### 🟠 Ejercicio 17 — El que no se reproduce

Diseña un fallo intermitente y trabájalo hasta poder provocarlo a voluntad.

**Objetivo:** practicar la regla de §7. Lo difícil no es arreglarlo: es conseguir reproducirlo.

### 🟠 Ejercicio 18 — Anti-patrón contra método

Toma un fallo de permisos y resuélvelo con `chmod -R 777` y con el método de [F17](17-usuarios-permisos-y-volumenes.md) §8.

**Pregunta:** ¿qué sabes después de cada uno? ¿Cuál se va a repetir la semana que viene?

### 🟠 Ejercicio 19 — El diagnóstico que destruyó la evidencia

Los anti-patrones no se combaten con moralina, se combaten con números. Prepara un fallo de
permisos y resuélvelo **dos veces**, sobre copias idénticas del escenario.

**Primera pasada, a lo bruto:** `chmod -R 777`, `rm -rf node_modules`, `docker system prune -a`
y reinstalar. Cronométralo.
**Segunda pasada, con método:** el protocolo de 60 segundos, una hipótesis, la comprobación, y
la corrección mínima. Cronométralo también.

**Objetivo:** la tabla de las dos pasadas con cuatro columnas: **tiempo**, **si el problema se
resolvió**, **si sabes por qué** y **qué información destruiste**. La última columna es la que
importa, y suele estar vacía en la primera pasada porque ni te enteraste de lo que perdiste:
enuméralo explícitamente —los permisos originales, el `node_modules` que era la evidencia, las
capas cacheadas de tres horas de build—.

**Pregunta:** la pasada a lo bruto puede salir **más rápida** esta vez. ¿Cambia eso el
veredicto? Responde pensando en la segunda ocurrencia del mismo fallo dentro de dos semanas, y
formula la regla que te llevas en una frase.

### 🟠 Ejercicio 20 — La capa equivocada

El error más caro del diagnóstico no es no encontrar la causa: es encontrarla **en la capa
equivocada** y arreglar algo que no estaba roto. Provócalo a propósito.

**Objetivo:** construir tres escenarios donde el síntoma **apunte** claramente a una capa y la
causa esté en otra. Tienes material en todo el curso: un `npm ci` que falla y parece del
proyecto pero es del volumen contaminado; un contenedor que "no tiene red" y en realidad
escucha en `127.0.0.1`; un build que "no compila" y en realidad trae una caché de otra rama.

Para cada uno, escribe tres cosas: **a qué capa apunta el síntoma**, **en qué capa está la
causa**, y **la comprobación de una línea** que descarta la capa equivocada en el primer
minuto.

**Pregunta:** las tres comprobaciones que acabas de escribir, ¿están en tu protocolo de 60
segundos de §4? Si no, añádelas. Un protocolo de triaje no sirve para encontrar la causa:
sirve para **descartar capas rápido**, y estas tres son justo eso.

## 🔴 Muy difícil — comunicar y transmitir (21–25)

### 🔴 Ejercicio 21 — Audita tu propio historial

Revisa tu historial de shell de las últimas semanas de curso y busca cuántas veces usaste alguno
de los seis anti-patrones de §8.

**Objetivo:** el ejercicio incómodo de la fase. Por cada aparición, escribe qué habrías hecho con
el método y qué información perdiste. Nadie llega a esta fase con la lista vacía, y ese es el
punto.

### 🔴 Ejercicio 22 — Tu chuleta de 60 segundos

Escribe la versión de §4 adaptada a **tu** proyecto y a tu entorno, en una página.

**Objetivo:** que la puedas ejecutar de memoria a las tres de la mañana, y que la salida quepa
en una pantalla.

### 🔴 Ejercicio 23 — El post-mortem sin culpables

Todo el curso te ha entrenado para diagnosticar. Este ejercicio es sobre lo que pasa después,
que es donde el trabajo técnico se convierte —o no— en algo que sirve al equipo.

Toma el peor incidente que hayas tenido en el curso —el que más tiempo te costó— y escribe su
post-mortem con la estructura de §13 de la guía del curso: síntoma, reproducción, evidencia,
capa sospechosa, hipótesis, causa raíz, corrección distinguiendo parche de solución
estructural, y prevención.

**Y ahora la parte difícil, que es la que da nombre al ejercicio:** escríbelo entero **sin una
sola frase que atribuya el fallo a una persona o a su descuido**. Nada de "no se dio cuenta de
que", "olvidó", "debería haber". Cada vez que te salga una, sustitúyela por la pregunta de
sistema equivalente: ¿qué hacía que ese error fuera fácil de cometer y difícil de detectar?

**Pregunta de cierre:** compara las dos versiones —la que te salió primero y la reescrita— y di
cuál produce mejores acciones de prevención. La sección de prevención de la segunda suele tener
cosas accionables donde la primera tenía "tener más cuidado", y esa diferencia es todo el
argumento.

### 🔴 Ejercicio 24 — El fallo que solo le pasa a otro

El escenario más incómodo del oficio: alguien tiene un problema que tú no puedes reproducir,
está en otra ciudad, y cada ida y vuelta de preguntas cuesta una hora.

**Objetivo:** diseñar el **paquete de diagnóstico remoto** que le pedirías. Un solo mensaje,
sin idas y vueltas, que le pida exactamente lo necesario para que tú puedas trabajar sin él.
Tiene que incluir: qué ejecutar —y el script de §5 ya hace la mitad—, qué archivos adjuntar,
qué **no** hacer antes de mandártelo, y cómo declarar sus condiciones al modo de
[F23](23-estudios-de-caso-multiplataforma.md) §5.1.

Después póntelo a prueba de verdad: pídeselo a alguien con un fallo real, o simúlalo pidiéndole
a un compañero que rompa su laboratorio y te mande solo el paquete.

**Pregunta de cierre:** ¿cuántas rondas de preguntas necesitaste **después** del paquete? Cada
ronda extra es un hueco de tu paquete: nómbralos y arréglalo. Y responde a la que decide el
diseño: ¿qué preferirías, un paquete grande que casi nadie ejecuta entero, o uno pequeño que
todo el mundo manda? Justifica con lo que acabas de medir.

### 🔴 Ejercicio 25 — Enseña el método, no la respuesta

La prueba final de que entiendes un método es que otra persona pueda usarlo sin ti.

**Objetivo:** coge a alguien —un compañero, alguien que empieza— y siéntate a su lado mientras
diagnostica un fallo del laboratorio que tú preparaste y él no conoce. **Tu única regla: no
puedes decirle la causa ni ningún comando concreto.** Solo puedes hacerle preguntas de método:
¿qué capa estás mirando?, ¿qué hipótesis tienes?, ¿qué comprobación la descartaría?, ¿cambiaste
una cosa o tres?

Anota dos listas mientras lo hace: **dónde se atascó** y **qué pregunta tuya lo desatascó**.

**Pregunta de cierre:** las preguntas que funcionaron son, casi con seguridad, mejores
candidatas para tu chuleta de §4 que los comandos que ibas a poner. ¿Cuáles añadirías? Y la
observación que cierra la fase: si tuviste que morderte la lengua para no dar la respuesta,
enhorabuena — eso es exactamente lo que separa a alguien que resuelve incidentes de alguien
que forma gente que los resuelve.

## 🔥 Opcionales

### 🔥 Ejercicio 26 — Mejora el script

Añade al script de diagnóstico dos secciones que hoy no tiene y que a ti te harían falta.

**Objetivo:** que sigan respetando la política deny by default.

### 🔥 Ejercicio 27 — `strace` a fondo

Traza un `npm ci` completo y busca en qué syscalls pasa más tiempo.

**Pregunta:** ¿es CPU, disco o red? Ahí tienes por qué `npm ci` va lento en macOS — [F26](26-portabilidad-entre-motores.md) §4.2.

## 💀 Boss fight

### 💀 Ejercicio 28 — Boss fight: el incidente completo

Alguien rompe tres cosas a la vez en tu laboratorio, en tres capas distintas, sin decirte
cuáles.

**Objetivo:** aplicar la fase entera y producir el `TROUBLESHOOTING-REPORT.md` con los ocho
puntos, para los tres. La dificultad real no es encontrarlos: es **no dejar que un fallo te haga
sacar conclusiones falsas sobre otro** —porque un `npm ci` que falla por permisos parece un
problema de dependencias, y arreglarlo "por ahí" te aleja—. Documenta, por cada uno, qué
hipótesis descartaste y con qué comando. Si el informe permite a otra persona reproducir los
tres fallos y sus tres arreglos, has terminado.

---

## 15. 📚 Referencias

**Diagnóstico de contenedores**
- `docker inspect`: https://docs.docker.com/reference/cli/docker-inspect/
- `docker events`: https://docs.docker.com/reference/cli/docker-events/
- `docker stats`: https://docs.docker.com/reference/cli/docker-stats/
- `docker top`: https://docs.docker.com/reference/cli/docker-top/

**Herramientas del sistema**
- `strace(1)`: https://manpages.debian.org/buster/strace/strace.1.en.html
- `ss(8)`: https://manpages.debian.org/buster/iproute2/ss.8.en.html
- `lsof(8)`: https://manpages.debian.org/buster/lsof/lsof.8.en.html
- `capabilities(7)`: https://manpages.debian.org/buster/manpages/capabilities.7.en.html

> ⚠️ **`strace` no funciona igual en macOS y Windows**, porque el contenedor corre dentro de una
> VM Linux y el trazado ocurre ahí dentro. Funciona, y lo que traza es el proceso dentro de la
> VM, no en tu sistema.

**Orden de lectura sugerido:** `docker inspect` para conocer los campos que el protocolo usa;
`strace` solo cuando lo necesites, que no es a menudo.

---

## 16. 🏁 Resultado de la fase

```text
PROTOCOLO 60s   fecha · versiones · inspect destilado · logs · events · stats · top
                todo LECTURA, ningún cambio

TRES NIVELES    síntoma ≠ causa contribuyente ≠ causa raíz
                la contribuyente resuelve hoy; la raíz resuelve siempre

OCHO CAPAS      host · motor · montajes · contenedor · imagen
                runtime · dependencias · proyecto
                y el fixture de control parte el problema por la mitad

HIPÓTESIS       SI <causa> ENTONCES <observación> LO COMPRUEBO CON <comando>
                una variable a la vez · reproducir antes de reparar

ANTI-PATRONES   chmod 777 · --privileged · rm lock · prune -a
                install --force · reinstalar Docker
                la escalera de martillos: empieza por arriba

HERRAMIENTAS    imagen de diagnóstico SEPARADA
                --pid=container: para depurar desde fuera
                --cap-add=SYS_PTRACE, nunca --privileged
                el script redacta secretos: deny by default

Y SABER PARAR   sin hipótesis nueva en una hora · sin reproducción
                escribe el expediente y toma el rodeo
```

> **La señal de que quedó bien:** *"ante un error que no había visto nunca, mi primer minuto es
> siempre el mismo — y al terminarlo sé en qué capa estoy sin haber cambiado nada."*

En **[F31](31-catalogo-de-fallos-i.md)** empieza el catálogo: los fallos de engine, build, registry y red, con su síntoma
literal, su causa y la comprobación que la confirma.
