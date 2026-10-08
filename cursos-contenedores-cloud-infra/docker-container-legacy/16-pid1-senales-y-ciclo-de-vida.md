# 🧟 Parte II · Fase 16 — PID 1, señales y ciclo de vida: por qué tu app ignora Ctrl+C

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · Node 10.24.1 baseline
> **Arquitectura objetivo del laboratorio:** `linux/amd64`
> **Código de esta fase:** [`src/16-pid1-senales-y-ciclo-de-vida/`](src/16-pid1-senales-y-ciclo-de-vida/)
> **Requisitos:** **[F08](08-run-el-contenedor-como-proceso.md)**, que usó `exec "$@"` sin explicarlo del todo
> **Fecha de verificación ejecutada:** 6 de septiembre de 2026 — el laboratorio de §7.1 y los zombies de §8 están corridos sobre Docker 29.6.2, imagen `linux/amd64` bajo Rosetta en macOS Apple Silicon
> **Estado de la imagen al terminar:** sin cambios
> **Objetivo:** entender qué hace especial al proceso 1 de un contenedor, por qué `docker stop` tarda diez segundos cuando algo va mal, y qué son exactamente los zombies

---

## 1. 🧭 Dónde estamos

[F08](08-run-el-contenedor-como-proceso.md) te dijo que el entrypoint debía terminar en `exec "$@"` y te explicó el porqué en cuatro
líneas: *el motor manda `SIGTERM` al PID 1, y si ese PID 1 es un script de shell, tu aplicación
no se entera*.

Era cierto y estaba incompleto. Esta fase abre el mecanismo entero: qué es un PID namespace,
por qué el kernel trata al proceso 1 de forma distinta a todos los demás, qué pasa exactamente
durante esos diez segundos de `docker stop`, y qué es un zombie.

Es una fase de mecanismo puro, y de las que más cambian cómo lees un contenedor.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder:

- Explicar qué es un **PID namespace** y por qué el proceso principal de tu contenedor es el 1.
- Nombrar la **semántica especial de PID 1** y las dos consecuencias que tiene para ti.
- Distinguir `SIGTERM`, `SIGINT` y `SIGKILL`, y saber cuál se puede ignorar.
- Describir qué hace `docker stop` **segundo a segundo**.
- Escribir un cierre ordenado en Node y comprobar que funciona.
- Explicar qué es un **zombie**, cuándo aparecen y qué hace `--init`.
- Manejar el ciclo de vida completo y las restart policies con criterio.

---

## 3. 🚧 Qué NO entra todavía

- **UID, GID y permisos** — el otro namespace que te va a morder → **[F17](17-usuarios-permisos-y-volumenes.md)**.
- **Network namespace**, puertos y DNS interno → **[F18](18-networking-de-contenedores.md)**.
- **User namespaces y rootless**, que cambian la ecuación entera → **[F25](25-rootless-y-user-namespaces.md)**.
- El **catálogo de fallos** de arranque y parada → **[F31](31-catalogo-de-fallos-i.md)**.

---

## 4. 🔢 PID, PID namespace, y por qué tu proceso es el 1

Un **PID** es el número que el kernel asigna a cada proceso. En un Linux normal, el 1 es el
sistema de init —`systemd` en casi todas las distribuciones modernas—, y todo lo demás
desciende de él.

En un contenedor, tu proceso es el 1. Compruébalo:

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase09 \
  bash -c 'echo "yo soy PID $$"; ps -ef'
```
```text
yo soy PID 1
UID   PID  PPID  C STIME TTY   TIME     CMD
root    1     0  0 10:22 ?     00:00:00 bash -c echo "yo soy PID $$"; ps -ef
root    8     1  0 10:22 ?     00:00:00 ps -ef
```

No es que el contenedor sea una máquina con un solo proceso. Es que tiene su propio **PID
namespace**: una numeración independiente donde tu proceso empieza a contar desde 1.

```text
HOST                                    CONTENEDOR
PID  1  systemd                         PID  1  node server.js
PID  842 dockerd                        PID  8  ps -ef
PID 1337 containerd-shim
PID 1340 node server.js  ◀──── es el MISMO proceso, visto desde dos namespaces
```

**El mismo proceso tiene dos números.** Desde el host es el 1340; desde dentro es el 1. Puedes
verlo con:

```bash
docker inspect --format '{{.State.Pid}}' mi-contenedor      # su PID en el host
docker exec mi-contenedor bash -c 'ps -ef | head -2'        # su PID dentro
```

> 🧠 **Modelo mental.** Un namespace no crea nada: **cambia lo que se ve**. Es la misma idea
> que OverlayFS aplicó al filesystem en [F13](13-overlayfs-y-copy-on-write.md), ahora aplicada a la tabla de procesos. Y es la
> razón mecánica de que un contenedor no sea una máquina virtual: no hay un kernel nuevo, hay
> una vista distinta del mismo kernel.

---

## 5. 👑 La semántica especial de PID 1

El kernel trata al proceso 1 de forma distinta a todos los demás, y las dos diferencias son
exactamente las que te van a dar problemas.

### 5.1 PID 1 ignora las señales que no maneja

Un proceso normal que recibe `SIGTERM` y no tiene un handler **muere**: es el comportamiento
por defecto. El proceso 1 **no**. El kernel asume que init sabe lo que hace y no le aplica
acciones por defecto para las señales que puede capturar.

**La consecuencia práctica:** si tu PID 1 no maneja `SIGTERM` explícitamente, `docker stop` no
lo mata. Espera el periodo de gracia y después lo mata con `SIGKILL`, que no se puede ignorar.
Eso son diez segundos de espera en cada parada.

### 5.2 PID 1 hereda los huérfanos

Cuando un proceso muere dejando hijos vivos, esos hijos se **reasignan al PID 1**. Y cuando
uno de esos hijos termina, alguien tiene que recoger su código de salida — hacer *reaping*—,
o su entrada se queda en la tabla de procesos para siempre.

Ese es un **zombie**: un proceso que ya terminó pero cuya entrada nadie ha recogido. §8.

> 🧭 **Las dos consecuencias, juntas:** el proceso 1 de un contenedor tiene responsabilidades
> de sistema de init, y la mayoría de las aplicaciones no fueron escritas para eso. De ahí
> salen las dos soluciones de esta fase: manejar las señales tú, o poner un init de verdad
> con `--init`.

---

## 6. 📡 Señales: las tres que importan

Una **señal** es una notificación asíncrona que el kernel entrega a un proceso. Hay decenas;
para contenedores importan tres.

| Señal | Número | Se puede ignorar | Qué significa |
|---|---|---|---|
| **`SIGTERM`** | 15 | **sí** | "termina ordenadamente, cuando puedas" |
| **`SIGINT`** | 2 | **sí** | lo que manda `Ctrl+C` |
| **`SIGKILL`** | 9 | **no, jamás** | el kernel te mata, sin avisar ni permitir limpieza |

`SIGTERM` es una **petición educada**: el proceso puede cerrar conexiones, vaciar buffers,
terminar la petición en curso y salir. `SIGKILL` no es una petición: el proceso no se entera,
no ejecuta nada, y todo lo que tuviera en memoria se pierde.

### 6.1 Qué hace `docker stop`, segundo a segundo

```mermaid
sequenceDiagram
    participant S as docker stop mi-contenedor
    participant P as PID 1 del contenedor
    S->>P: t=0s · SIGTERM
    Note over P: el proceso puede cerrar ordenadamente
    Note over S,P: espera el periodo de gracia (10 segundos por defecto)
    S->>P: t=10s · si sigue vivo, SIGKILL
    Note over P: muerte inmediata, sin limpieza
```

Y las variantes:

```bash
docker stop mi-contenedor              # 10 s de gracia
docker stop -t 30 mi-contenedor        # 30 s, para apps que tardan en cerrar
docker stop -t 0 mi-contenedor         # SIGKILL inmediato
docker kill mi-contenedor              # SIGKILL directo, sin gracia
docker kill -s SIGHUP mi-contenedor    # cualquier señal, a mano
```

> ⚠️ **`docker kill` no es "un `stop` más rápido".** Es un mecanismo distinto: `stop` pide,
> `kill` mata. Usar `kill` por costumbre significa que tu aplicación nunca ejecuta su cierre
> ordenado — y si escribe en disco o mantiene conexiones, eso se nota.

> 🩺 **El síntoma que delata el problema.** Si `docker stop` tarda exactamente diez segundos,
> **siempre**, tu PID 1 no está manejando `SIGTERM`. No es lentitud de la aplicación: es el
> periodo de gracia agotándose entero. Cronométralo y lo sabes.

---

## 7. 🧪 El laboratorio: un servidor que sí se entera

Vamos a construir el caso correcto y después a romperlo de tres formas.

📄 **`server.js`**

```javascript
'use strict';

const http = require('http');

const host = process.env.HOST || '0.0.0.0';
const port = Number(process.env.PORT || 3000);

const server = http.createServer(function (req, res) {
  console.log(new Date().toISOString(), req.method, req.url);
  res.statusCode = 200;
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  res.end(JSON.stringify({
    ok: true,
    node: process.version,
    pid: process.pid
  }) + '\n');
});

server.listen(port, host, function () {
  console.log('Servidor escuchando en http://' + host + ':' + port);
  console.log('Node:', process.version, '· PID:', process.pid);
});

// guardia: SIGTERM y SIGINT pueden llegar los dos, o dos veces
let shuttingDown = false;

function shutdown(signal) {
  if (shuttingDown) { return; }
  shuttingDown = true;

  console.log('Recibida', signal, '- cerrando servidor...');

  server.close(function () {
    console.log('Servidor cerrado. Adiós.');
    process.exit(0);
  });

  // red de seguridad: si algo se queda colgado, no esperamos al SIGKILL
  setTimeout(function () {
    console.log('Cierre forzado tras el tiempo límite.');
    process.exit(1);
  }, 8000).unref();
}

process.on('SIGTERM', function () { shutdown('SIGTERM'); });
process.on('SIGINT',  function () { shutdown('SIGINT');  });
```

**Detalles con intención:**

- **El guardia `shuttingDown`** evita que dos señales seguidas —o un `Ctrl+C` impaciente—
  lancen dos cierres a la vez.
- **`server.close()` no cierra de golpe:** deja de aceptar conexiones nuevas y espera a que
  terminen las en curso. Eso es lo que significa "ordenado".
- **El timeout de 8 segundos, por debajo de los 10 de gracia**, para salir por nuestro pie
  antes de que llegue el `SIGKILL`. Y `.unref()` para que ese propio timer no mantenga vivo el
  proceso.

### 7.1 Compruébalo

```bash
docker run -d --name pidlab --platform linux/amd64 \
  --mount type=bind,src="$PWD/src/16-pid1-senales-y-ciclo-de-vida",dst=/workspace \
  legacy-node-toolchain:phase09 \
  node server.js

docker exec pidlab ps -ef        # ¿quién es PID 1?
time docker stop pidlab          # ¿cuánto tarda?
docker logs pidlab | tail -3
```
Y esto es lo que sale, pegado tal cual de una ejecución real:

```text
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0 24 06:05 ?        00:00:00 /opt/node/10.24.1/bin/node --no-opt -r /proc/.reset server.js
root        14     0  0 06:05 ?        00:00:00 ps -ef

docker stop pidlab  0.01s user 0.01s system 11% cpu 0.145 total

Servidor escuchando en http://0.0.0.0:3000
Node: v10.24.1 · PID: 1
Recibida SIGTERM - cerrando servidor...
Servidor cerrado. Adiós.
```

Tres cosas en esas ocho líneas. **`PID 1` es `node`**, no un shell ni el entrypoint: eso es el
`exec "$@"` haciendo su trabajo. **El `stop` tardó 0,145 segundos**, no diez. Y el servidor
alcanzó a despedirse en los logs, que es la prueba de que recibió `SIGTERM` y no `SIGKILL`.

> 🔥 **Prueba de fuego.** Ese `0.145 total` es la fase entera en un número. Si tu contenedor
> tarda diez segundos, algo de lo que viene en §7.2 te está pasando.

> 📝 **¿De dónde salen ese `--no-opt -r /proc/.reset`?** No los pusimos nosotros: el
> entrypoint hace `exec "${target}" "$@"` y nada más. Los inyecta **Rosetta**, la capa con la
> que Docker Desktop ejecuta binarios x86-64 sobre un Mac con chip M — el `/proc/.reset` es un
> archivo que Rosetta monta dentro del contenedor para desactivar optimizaciones del JIT de V8
> que su traducción no digiere bien. En un host `amd64` nativo la línea es un `node server.js`
> limpio. Es un buen recordatorio de lo que dice [F22](22-apple-silicon-y-hosts.md): la salida
> de tus comandos lleva la huella del host, y conviene reconocerla para no salir a diagnosticar
> un problema que no existe.

### 7.2 Ahora rómpelo de tres formas

**Sin handler de señales.** Quita los dos `process.on(...)` y repite. `docker stop` tarda diez
segundos y los logs no dicen nada: el proceso murió por `SIGKILL`.

**Sin `exec` en el entrypoint.** Usa un entrypoint que termine en `"$@"` a secas. Ahora
`ps -ef` muestra el script como PID 1 y `node` como su hijo. `SIGTERM` llega al script, que no
sabe qué hacer con él, y tu servidor no se entera.

**En forma shell.** Un `CMD node server.js` sin corchetes mete `/bin/sh -c` como PID 1, con
el mismo resultado que el caso anterior. Es la razón de la regla de [F02](02-dockerfile-esencial.md) §7.5.

```text
✅ exec form + handler          PID 1 = node          stop en <1s, cierre limpio
❌ sin handler                  PID 1 = node          stop en 10s, SIGKILL
❌ sin exec en el entrypoint    PID 1 = script.sh     stop en 10s, SIGKILL
❌ shell form                   PID 1 = /bin/sh -c    stop en 10s, SIGKILL
```

---

## 8. 🧟 Zombies, y qué hace `--init`

Un **zombie** —estado `Z` en `ps`— es un proceso que ya terminó pero cuya entrada sigue en la
tabla porque nadie recogió su código de salida.

En un Linux normal no los ves nunca, porque `systemd` los recoge. En un contenedor, esa
responsabilidad recae en tu PID 1, y una aplicación Node no fue escrita para hacer de init.

**Cuándo aparecen de verdad**, y aquí hay que hilar más fino de lo que se suele contar. No
basta con que tu proceso lance hijos: Node **sí** entierra a los suyos, porque `child_process`
instala su propio manejador de `SIGCHLD` y recoge el código de salida de todo lo que él mismo
arrancó. Un `spawn` en bucle no produce ni un zombie, y puedes comprobarlo.

Los zombies aparecen un piso más abajo: cuando un **nieto** se queda huérfano. Tu proceso lanza
un hijo, el hijo lanza algo en segundo plano y se muere antes que su hijo — un script de build
que arranca un watcher y termina, un `bash -c '... &'`, un wrapper que hace `exec` mal—. Ese
nieto huérfano lo adopta PID 1 por lo de §5.2, y **PID 1 es tu aplicación**, que no tiene la
menor idea de que ahora es responsable de enterrarlo.

Reproducirlo cuesta ocho líneas. `orphan.js` lanza cada 300 ms un `bash` que arranca un `sleep`
en segundo plano y se suicida:

```javascript
const { spawn } = require('child_process');

// el hijo lanza un NIETO en segundo plano y se muere enseguida:
// el nieto queda huérfano y lo adopta PID 1, que es quien tendrá que enterrarlo
setInterval(function () {
  spawn('/bin/bash', ['-c', '/bin/sleep 2 & exit 0']);
}, 300);
setInterval(function () {}, 1 << 30);
```

Arráncalo y cuenta los cadáveres a los quince segundos:

```bash
docker exec mi-contenedor bash -c "ps -eo pid,ppid,stat,comm | awk '\$3 ~ /Z/'"
```

```text
   15     1 Z    sleep <defunct>
   17     1 Z    sleep <defunct>
   19     1 Z    sleep <defunct>
   21     1 Z    sleep <defunct>
   23     1 Z    sleep <defunct>
zombies: 41
```

Cuarenta y uno en quince segundos, todos con `PPID 1` y todos `<defunct>`. Si esa cuenta crece
con el tiempo, tienes una fuga: cada zombie ocupa una entrada en la tabla de procesos, y esa
tabla es finita.

**La solución que Docker ofrece:**

```bash
docker run --init ...
```

Inserta un init minúsculo —basado en **`tini`**— como PID 1, que hace dos cosas: **reenvía las
señales** a tu proceso y **recoge los huérfanos**. Tu aplicación deja de ser PID 1 y con ello
pierde las responsabilidades de sistema que nunca quiso.

El mismo `orphan.js`, la misma imagen, el mismo tiempo, y añadiendo `--init` al `docker run`:

```text
  PID  PPID STAT COMMAND
    1     0 Ss   docker-init          ← tini, no tu aplicación
    7     1 Sl   node                 ← tu proceso, ahora con un padre de verdad
zombies: 0
```

De 41 a 0 cambiando una bandera. Y fíjate en que `node` no es el PID 2 sino el 7: el número
exacto depende de lo que `tini` haga al arrancar y no significa nada. Lo que importa es la
columna `PPID`, que ya no es `0`.

> 🧭 **Por qué el baseline no lo impone.** Nuestro laboratorio ejecuta Node directamente como
> PID 1 y maneja señales correctamente, así que `--init` no aporta. Conviene usarlo cuando la
> aplicación lanza muchos procesos hijos, cuando las herramientas de build crean subprocesos
> complejos, o cuando **observas zombies** — que es un criterio medible y no una precaución
> genérica.

> ⚠️ **`--init` no sustituye al handler de señales.** `tini` reenvía `SIGTERM` a tu proceso;
> si tu proceso sigue sin manejarlo, sigue muriendo por `SIGKILL` a los diez segundos. Las dos
> cosas resuelven problemas distintos y a menudo hacen falta las dos.

---

## 9. ♻️ El ciclo de vida completo

```mermaid
stateDiagram-v2
    state "periodo de gracia" as Gracia
    [*] --> Created: create, desde la imagen
    Created --> Running: start
    Running --> Gracia: stop
    Gracia --> Exited
    Running --> Paused: pause
    Exited --> Running: start
    Exited --> [*]: rm, ya no existe
```

Los comandos, con lo que hace falta saber de cada uno:

| Comando | Qué hace | Detalle |
|---|---|---|
| `docker create` | crea sin arrancar | existe, ocupa espacio, no corre nada |
| `docker start` | arranca | `-a` para quedarte enganchado a su salida |
| `docker stop` | `SIGTERM` + gracia + `SIGKILL` | §6.1 |
| `docker restart` | `stop` seguido de `start` | mismo contenedor, mismo `upperdir` |
| `docker kill` | `SIGKILL` directo, o `-s` para otra señal | sin gracia |
| `docker rm` | elimina el contenedor detenido | y su writable layer, [F13](13-overlayfs-y-copy-on-write.md) |
| `docker rm -f` | `kill` + `rm` en un paso | el más usado y el que más se lamenta |
| `docker wait` | bloquea hasta que termine y devuelve su exit code | útil en scripts |

### 9.1 Los códigos de salida que confunden

El exit code de un contenedor es normalmente el de su proceso principal. Salvo tres que son
del motor y no de tu programa:

| Código | Significa |
|---|---|
| **125** | falló el propio `docker run` — una opción mal escrita, por ejemplo |
| **126** | el comando existe pero **no se puede ejecutar**: sin permiso de ejecución |
| **127** | el comando **no existe** dentro del contenedor |

> 🩺 **Distinguirlos ahorra tiempo.** Un 127 no es un bug de tu aplicación: es un `PATH` o una
> ruta mal escrita. Un 126 casi siempre es un `chmod +x` que falta. Y un 125 significa que tu
> programa ni llegó a arrancar.

### 9.2 Restart policies

```bash
docker run --restart=no             ...   # por defecto: no reinicia
docker run --restart=on-failure:3   ...   # solo si sale con código ≠ 0, hasta 3 veces
docker run --restart=always         ...   # siempre, incluso al reiniciar el motor
docker run --restart=unless-stopped ...   # siempre, salvo que tú lo pararas
```

**`always` frente a `unless-stopped`** es la distinción que importa: con `always`, un
contenedor que tú paraste vuelve a arrancar cuando reinicies Docker. Con `unless-stopped`,
respeta tu decisión.

> ⚠️ **Una restart policy puede esconder un bug.** Un contenedor que muere y revive cada
> treinta segundos parece "funcionando" en `docker ps`. Comprueba la columna de estado —dice
> `Restarting`— y mira `docker inspect --format '{{.RestartCount}}'`. Es de los fallos más
> difíciles de ver porque el sistema parece sano.

### 9.3 Límites de recursos

**Sin límites explícitos, un contenedor puede usar toda la RAM y toda la CPU del host** — o de
la VM del motor, en macOS y Windows.

```bash
docker run --memory=512m --cpus=1.5 ...
docker stats                     # consumo en tiempo real
```

Si un proceso supera el límite de memoria, el kernel lo mata por **OOM**, y eso aparece como
una muerte súbita sin mensaje claro:

```bash
docker inspect --format '{{.State.OOMKilled}}' mi-contenedor
```

> 🩺 Ese `true` responde de un vistazo la pregunta *"¿por qué se murió sin decir nada?"*. En
> Docker Desktop hay **otra capa de límites** además: los de la VM, configurables en la
> interfaz. Un contenedor con `--memory=8g` en una VM de 4 GB no va a tener 8 GB.

---

## 10. ⚠️ Errores comunes y diagnóstico

**`docker stop` tarda siempre diez segundos.** No manejas `SIGTERM`. §7.2, y el diagnóstico es
`docker exec ... ps -ef` para ver quién es PID 1.

**`Ctrl+C` no para el contenedor en foreground.** O el proceso ignora `SIGINT`, o estás
enganchado sin TTY. Prueba con `docker stop` desde otra terminal.

**El contenedor muere sin log.** Puede ser OOM: comprueba `.State.OOMKilled`. O `SIGKILL` tras
la gracia, que tampoco deja rastro.

**Exit code 127 y "el comando está ahí".** Está en tu host, no en el contenedor. O no está en
el `PATH` del proceso.

**Zombies acumulándose.** §8, y `--init` si la aplicación lanza hijos.

**El contenedor "funciona" pero la app se reinicia sola.** Restart policy escondiendo un
crash. §9.2.

**En Podman, la restart policy se comporta distinto.** Podman no tiene daemon, así que
`always` depende de la integración con systemd del host. Es una de las diferencias reales, y
**[F24](24-docker-y-podman-arquitectura.md)** la trata.

---

## 11. 📋 Checklist de validación

```text
[ ] ps -ef dentro del contenedor muestra tu proceso como PID 1
[ ] docker inspect --format '{{.State.Pid}}' da un número distinto: el del host
[ ] El servidor de §7 responde y registra su PID
[ ] docker stop tarda menos de un segundo y el log muestra el cierre ordenado
[ ] Quitaste el handler y comprobaste que tarda exactamente 10 segundos
[ ] Quitaste el exec del entrypoint y viste el script como PID 1
[ ] Provocaste al menos un zombie y lo viste con estado Z
[ ] --init cambia quién es PID 1: comprobado con ps -ef
[ ] Distingues los exit codes 125, 126 y 127
[ ] Sabes comprobar si un contenedor murió por OOM
[ ] Sabes la diferencia entre always y unless-stopped
```

---

## 12. 🧪 Ejercicios de la Fase 16 (25)

## 🟢 Fácil — ver el proceso 1 (1–6)

### 🟢 Ejercicio 1 — Quién es PID 1

Arranca un contenedor y compara `ps -ef` dentro con
`docker inspect --format '{{.State.Pid}}'`.

**Pregunta:** ¿son el mismo proceso? ¿Por qué tiene dos números?

### 🟢 Ejercicio 2 — El servidor que se despide

Monta el laboratorio de §7 y comprueba el cierre ordenado con `time docker stop`.

**Objetivo:** ver el `real 0m0.4s` y los dos mensajes de cierre en los logs.

### 🟢 Ejercicio 3 — Quita el handler

Comenta los dos `process.on(...)` y repite.

**Objetivo:** cronometrar los diez segundos exactos y confirmar que los logs no dicen nada.

### 🟢 Ejercicio 4 — Las tres señales

Manda `SIGTERM`, `SIGINT` y `SIGKILL` con `docker kill -s` y observa qué hace el servidor con
cada una.

**Pregunta:** ¿cuál no produjo ningún mensaje de cierre y por qué era inevitable?

### 🟢 Ejercicio 5 — El periodo de gracia

Compara `docker stop`, `docker stop -t 30` y `docker stop -t 0` sobre el servidor sin handler.

**Objetivo:** entender que el número es tuyo y qué implica ponerlo a cero.

### 🟢 Ejercicio 6 — Los tres códigos

Provoca un 125, un 126 y un 127 deliberadamente.

**Objetivo:** reconocerlos al instante. El 126 necesita un script sin `chmod +x`.

## 🟡 Intermedio — señales y ciclo de vida (7–13)

### 🟡 Ejercicio 7 — `docker stats`

Arranca el servidor, hazle peticiones y mira `docker stats` en otra terminal.

**Pregunta:** ¿cuánta memoria usa Node en reposo? ¿Y qué límite tiene si no pusiste ninguno?

### 🟡 Ejercicio 8 — Rompe `exec "$@"`

Construye una imagen con un entrypoint que termine en `"$@"` sin `exec` y compara `ps -ef` y
el tiempo de `docker stop` con el original.

**Objetivo:** cerrar por fin la promesa que [F08](08-run-el-contenedor-como-proceso.md) §5.2 dejó abierta, con la evidencia delante.

### 🟡 Ejercicio 9 — Forma shell contra forma exec

Construye dos imágenes con `CMD node server.js` y `CMD ["node","server.js"]`.

**Pregunta:** ¿quién es PID 1 en cada una? ¿Cuál cierra ordenadamente?

### 🟡 Ejercicio 10 — Fabrica un zombie

Escribe un script Node que lance un hijo con `spawn`, no lo espere, y se quede vivo. Búscalo
con el comando de §8.

**Objetivo:** ver un proceso en estado `Z` con tus ojos.

### 🟡 Ejercicio 11 — `--init` al rescate

Repite el ejercicio 10 con `docker run --init` y compara `ps -ef`.

**Pregunta:** ¿quién es PID 1 ahora? ¿Desaparecieron los zombies?

### 🟡 Ejercicio 12 — `--init` no es un handler

Con `--init` pero **sin** el handler de señales, cronometra `docker stop`.

**Objetivo:** comprobar el aviso de §8: siguen siendo diez segundos. Son dos problemas
distintos.

### 🟡 Ejercicio 13 — Cierre con petición en curso

Añade un `setTimeout` de cinco segundos a una ruta del servidor. Lanza una petición y ejecuta
`docker stop` mientras se procesa.

**Pregunta:** ¿la petición terminó? ¿Cuánto tardó el stop? Eso es lo que significa "cierre
ordenado" en la práctica.

## 🟠 Difícil — cuando la parada no es limpia (14–20)

### 🟠 Ejercicio 14 — OOM a propósito

Arranca con `--memory=64m` un script que reserve memoria en un bucle.

**Objetivo:** provocar el OOM kill y confirmarlo con `.State.OOMKilled`.

### 🟠 Ejercicio 15 — El contenedor que revive

Arranca con `--restart=always` un contenedor cuyo proceso muera a los cinco segundos.

**Pregunta:** ¿qué muestra `docker ps`? ¿Y `RestartCount`? Explica por qué este fallo es
difícil de ver en un panel de monitorización.

### 🟠 Ejercicio 16 — `always` contra `unless-stopped`

Arranca dos contenedores, uno con cada política, párrelos a mano y reinicia el motor de Docker.

**Pregunta:** ¿cuál volvió? ¿Cuál usarías para un servicio de desarrollo?

### 🟠 Ejercicio 17 — Diagnostica una parada lenta

Alguien reporta que sus contenedores "tardan mucho en parar". Escribe la secuencia de
comprobaciones, de la más barata a la más cara.

**Objetivo:** un procedimiento que empiece por cronometrar y por `ps -ef`, y que distinga las
tres causas de §7.2 en tres comandos.

### 🟠 Ejercicio 18 — El PID desde los dos lados

En Linux nativo, encuentra el proceso de tu contenedor en el host con `ps -ef` y mándale un
`SIGTERM` **desde el host** con `kill`.

**Pregunta:** ¿qué pasó dentro del contenedor? ¿Qué te dice eso sobre qué es realmente un
contenedor? Si estás en macOS, explica por qué no puedes hacerlo y dónde vive ese proceso.

### 🟠 Ejercicio 19 — `STOPSIGNAL`: cuando la señal correcta no es `SIGTERM`

`docker stop` manda `SIGTERM` porque es la convención, pero no todo el software de Unix está
de acuerdo: `nginx` recarga con `SIGHUP` y termina limpio con `SIGQUIT`, y hay demonios que
usan `SIGUSR1`. Docker deja cambiarlo, en el `Dockerfile` o en el `run`.

Escribe un servidor que **solo** maneje `SIGQUIT` —ignorando `SIGTERM` a propósito— y
compruébalo en tres pasos: primero `docker stop` a secas, después
`docker run --stop-signal=SIGQUIT`, y por último con `STOPSIGNAL SIGQUIT` en el Dockerfile.

**Objetivo:** cronometrar los tres y explicar por qué el primero tarda diez segundos y los
otros dos no.

**Pregunta:** `docker image inspect` te dice qué `StopSignal` lleva la imagen. Compruébalo, y
después responde lo que de verdad importa: **si alguien arranca tu imagen sin leer su
documentación, ¿se cierra bien?** La diferencia entre poner la señal en el `Dockerfile` y
ponerla en el `run` es exactamente esa, y es un argumento de diseño, no de sintaxis.

### 🟠 Ejercicio 20 — Nietos, no hijos: dónde nacen los zombies de verdad

§8 lo dice y conviene comprobarlo, porque contradice lo que se repite en casi todos los
artículos sobre `--init`. Escribe **dos** scripts y ejecútalos quince segundos cada uno:

```javascript
// hijos.js — lanza hijos directos y no los espera
const { spawn } = require('child_process');
setInterval(() => spawn('/bin/true'), 300);
setInterval(() => {}, 1 << 30);
```

```javascript
// nietos.js — el hijo lanza un nieto en segundo plano y se muere
const { spawn } = require('child_process');
setInterval(() => spawn('/bin/bash', ['-c', '/bin/sleep 2 & exit 0']), 300);
setInterval(() => {}, 1 << 30);
```

Cuenta los zombies en cada caso con
`ps -eo pid,ppid,stat,comm | awk '$3 ~ /Z/'`.

**Antes de ejecutar, predice** cuál de los dos genera zombies.

**Pregunta:** uno de los dos da cero y el otro da decenas. ¿Por qué? La respuesta está en qué
hace `child_process` de Node con `SIGCHLD` y a quién adopta PID 1 según §5.2. Y el corolario
práctico: cuando alguien te diga *"tu app lanza procesos, necesitas `--init`"*, ¿en qué caso
tiene razón?

## 🔴 Muy difícil — diseño del apagado (21–25)

### 🔴 Ejercicio 21 — Decide el periodo de gracia con datos

Mide cuánto tarda de verdad tu aplicación en cerrar ordenadamente bajo carga: con peticiones en
curso, con una escritura a medias, con una conexión abierta.

**Objetivo:** proponer un `-t` justificado con la medición, y explicar qué pasa exactamente si
lo pones más bajo. "Diez segundos porque es el defecto" no es una respuesta.

### 🔴 Ejercicio 22 — El cierre ordenado de tu proyecto

Añade a tu proyecto legacy real un cierre ordenado que cierre lo que haya que cerrar:
conexiones a base de datos, peticiones en curso, escrituras pendientes.

**Objetivo:** que `docker stop` tarde lo que tarde el trabajo real y no diez segundos fijos. Y
documenta qué se perdía antes en cada parada.

### 🔴 Ejercicio 23 — `HEALTHCHECK`: el contenedor que está vivo y no sirve

`docker ps` dice `Up 3 hours` y el servicio lleva dos horas devolviendo error 500. El estado
que Docker conoce es "el proceso no ha terminado", que es una pregunta distinta de "el
servicio funciona".

**Objetivo:** añadir un `HEALTHCHECK` al servidor de §7 que compruebe de verdad que responde,
y después **romperlo por dentro sin matar el proceso** —haz que el handler de la ruta lance una
excepción, o cierra la conexión a un recurso del que dependa— para ver a `docker ps` pasar a
`(unhealthy)`.

```dockerfile
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -fsS http://localhost:3000/ || exit 1
```

Explica las cuatro opciones: por qué existe `start-period` y qué pasaría sin ella en un
proyecto legacy cuyo arranque tarda cuarenta segundos.

**Pregunta de cierre:** un `HEALTHCHECK` que falla **no** para el contenedor ni lo reinicia,
solo cambia una etiqueta. Compruébalo. Entonces, ¿para qué sirve? Responde nombrando quién
lee ese estado, y cierra con la pregunta de diseño: ¿qué debe comprobar el healthcheck de tu
proyecto, y qué **no** debe comprobar nunca? Un healthcheck que consulta la base de datos de
otro equipo convierte el problema de ellos en una caída tuya.

### 🔴 Ejercicio 24 — El proceso ajeno que no puedes arreglar

Toda la fase asume que puedes editar el código de PID 1. A veces no puedes: es un binario de
terceros, sin fuentes, que ignora `SIGTERM` y tarda sus diez segundos religiosamente. Tu
`docker stop` de una imagen así multiplicado por cuarenta contenedores es un despliegue de
siete minutos.

**Objetivo:** enumerar **todas** las salidas que esta fase te ha dado y evaluarlas contra este
caso concreto, una por una: `STOPSIGNAL` con otra señal, `--init`, un wrapper que haga de PID 1
y traduzca señales, `--stop-timeout` corto, y aceptar el `SIGKILL`. Para cada una: si aplica o
no, qué cuesta, y **qué se pierde** —porque con `SIGKILL` se pierde algo concreto y hay que
saber decir qué—.

Después implementa la que elijas y demuestra con `time docker stop` que el número bajó.

**Pregunta de cierre:** una de las opciones de la lista es "no hacer nada y documentarlo".
¿En qué circunstancia es la correcta? Defínela con un criterio medible, no con "si no
importa".

### 🔴 Ejercicio 25 — El worker con trabajo en vuelo

El servidor de §7 cierra limpio porque no tenía nada a medias. Un worker de una cola sí lo
tiene, y ahí el cierre ordenado deja de ser cortesía y pasa a ser corrección: si matas el
proceso a mitad de un trabajo, o lo pierdes o lo duplicas.

**Objetivo:** escribir un worker que procese trabajos de tres segundos en un bucle y darle un
apagado correcto que cumpla las cuatro cosas: **deja de aceptar** trabajo nuevo al recibir
`SIGTERM`, **termina** el que tiene en vuelo, **devuelve a la cola** lo que no le dio tiempo a
empezar, y **sale con 0**. Demuestra cada una con evidencia en los logs.

Después mide: ¿cuánto tarda tu apagado en el peor caso? Compáralo con el periodo de gracia por
defecto de `docker stop` y ajusta uno de los dos.

**Pregunta de cierre:** ¿qué pasa si llega un **segundo** `SIGTERM` mientras estás cerrando —o
un `SIGINT` a la vez, que es lo que ocurre en una terminal—? El servidor de §7 tiene una
guarda `shuttingDown` justo para eso: explica qué problema evita y qué habría pasado sin ella.
Y la pregunta que decide el diseño: un segundo `SIGTERM`, ¿debería acelerar el cierre o
ignorarse? Defiende tu respuesta.

## 🔥 Opcionales

### 🔥 Ejercicio 26 — Lee `tini`

`tini` cabe en unas trescientas líneas de C. Léelo y localiza las dos cosas que hace.

**Pregunta:** ¿cuántas líneas dedica al reenvío de señales y cuántas al reaping? Sabiendo eso,
¿te parece razonable que Docker lo inserte con una bandera?

### 🔥 Ejercicio 27 — Un supervisor mínimo

Escribe un PID 1 en Bash que lance tu servidor, reenvíe `SIGTERM` y recoja huérfanos.

**Objetivo:** entender por qué existe `tini` intentando reemplazarlo. La parte del reaping es
sorprendentemente incómoda en shell, y descubrir por qué es la lección.

## 💀 Boss fight

### 💀 Ejercicio 28 — Boss fight: el contenedor que se niega a morir

Te dan un contenedor que: tarda diez segundos en parar, deja zombies, y a veces vuelve a
arrancar solo después de que lo pares.

**Objetivo:** los **tres** problemas son independientes y tienen tres causas distintas de esta
fase. Encuéntralos con evidencia —no con hipótesis—, arregla cada uno por separado, y demuestra
con una medición que cada arreglo resolvió solo su problema. Documenta qué comando confirmó
cada causa. Si resuelves este, un contenedor no vuelve a "portarse raro" al pararlo.

---

## 13. 📚 Referencias

**Señales y procesos**
- `signal(7)`, la referencia del kernel: https://manpages.debian.org/buster/manpages/signal.7.en.html
- `pid_namespaces(7)`: https://manpages.debian.org/buster/manpages/pid_namespaces.7.en.html
- `kill(1)`: https://manpages.debian.org/buster/procps/kill.1.en.html

**Docker**
- `docker stop` y el periodo de gracia: https://docs.docker.com/reference/cli/docker-container-stop/
- Especificar un proceso init: https://docs.docker.com/reference/cli/docker-container-run/#init
- Restart policies: https://docs.docker.com/engine/containers/start-containers-automatically/
- Límites de recursos: https://docs.docker.com/engine/containers/resource_constraints/

**Node**
- Eventos de proceso y señales: https://nodejs.org/docs/latest-v10.x/api/process.html#process_signal_events
- `server.close()`: https://nodejs.org/docs/latest-v10.x/api/net.html#net_server_close_callback

**tini**
- https://github.com/krallin/tini

**Orden de lectura sugerido:** `signal(7)` primero —es corta y explica de dónde sale todo lo
demás—, y `pid_namespaces(7)` cuando quieras entender el ejercicio 18.

---

## 14. 🏁 Resultado de la fase

```text
PID NAMESPACE   tu proceso es el 1 dentro, y otro número fuera
                el mismo proceso, dos vistas del mismo kernel

PID 1           ignora las señales que no maneja  → stop de 10 s
                hereda los huérfanos              → zombies

SEÑALES         SIGTERM  petición educada, ignorable
                SIGINT   lo que manda Ctrl+C
                SIGKILL  no se puede ignorar, no permite limpieza

docker stop     SIGTERM → 10 s de gracia → SIGKILL

LO QUE HACE     exec "$@" en el entrypoint     para que tu app SEA el PID 1
QUE FUNCIONE    handler de SIGTERM en la app   para que se entere
                --init                          si lanza hijos y deja zombies
```

> **La señal de que quedó bien:** *"cuando un `docker stop` tarda diez segundos, ya no espero:
> sé que es el periodo de gracia agotándose y sé en qué de tres sitios mirar."*

En **[F17](17-usuarios-permisos-y-volumenes.md)** seguimos con namespaces, pero con el que produce el problema más cotidiano de todos:
usuarios, permisos, y los archivos que salen del contenedor con dueño equivocado.
