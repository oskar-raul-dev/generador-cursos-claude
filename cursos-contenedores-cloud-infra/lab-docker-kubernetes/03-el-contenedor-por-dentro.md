# 🔬 Fase 03 — El contenedor por dentro: un proceso con la vista recortada, sus capas y su forma de morir

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 03 de 27 · Parte I — El modelo y el salto · **media**
> **Perfil:** compose, sin cluster · **Observabilidad encendida:** ninguna
> **Motor de referencia:** Docker · 🦭 Podman sin root mapea el `root` del contenedor a tu usuario, y con los volúmenes se comporta distinto
> **Servicios que toca:** `pricing` como sujeto; los cinco para las señales · **Paso de generación:** ninguno
> **Depende de:** Fase 02 · **Habilita:** [Fase 04](04-empaquetar-los-cuatro-runtimes.md)
> **Incidentes que reserva:** ninguno · **Medición:** ninguna
> **Apéndices de apoyo:** [a01](a01-el-laboratorio.md), [a02](a02-problemas-del-ambiente.md)
> **Fecha de verificación ejecutada:** 03/10/2026 · macOS arm64, con Docker y con Podman
> **Objetivo:** demostrar en el laboratorio que un contenedor es un proceso de la máquina virtual del motor, leer las capas de una imagen, y explicar con la salida de `docker stop` por qué dos de los cinco servicios mueren a los diez segundos.

---

## 🧭 1. Dónde estamos

La Parte 0 terminó con el sistema corriendo: el patrimonio en un perfil de compose, los cinco
servicios de G0 al lado y la suite pasando. Lo que todavía no tienes es el modelo de **qué es** eso
que levantaste, y la Parte I existe para dártelo antes de que la Parte II te lo cobre.

Valentina hizo la primera demostración de La Rebotica en la sala de arquitectura, con el portátil
conectado al televisor. La primera pregunta fue de Luz Marina, que lleva dieciocho años pensando en
dominios de WebLogic y en cuánta memoria pedirle a infraestructura para cada servidor (historia §6):

> *"Bueno, mija, ¿y a cada una de esas maquinitas cuánta memoria le asignamos?"*

Es la pregunta correcta para alguien que pasó su vida con máquinas virtuales, y la respuesta es que
**no hay maquinita**: el contenedor de `pricing` es un proceso de la máquina virtual de tu motor, con
la vista recortada. De ahí sale por qué los datos se van al recrear un contenedor, por qué una imagen
corre en los dos motores, y por qué `docker stop` mata a dos de tus cinco servicios.

---

## 🎯 2. Objetivos de esta fase

1. Encontrar el proceso de `pricing` desde adentro y desde la máquina virtual del motor, y nombrar
   qué lo aísla.
2. Mostrar que un contenedor limitado a 64 MB no sabe que tiene 64 MB, y dónde está el límite.
3. Leer las capas de una imagen con `docker history` y `dive`, y explicar por qué la capa escribible
   no sobrevive a un `--force-recreate`.
4. Llevar una imagen de Docker a Podman como archivo y correrla sin reconstruirla.
5. Predecir y medir qué hace `docker stop` con cada servicio, y qué cambia el resultado.

---

## 🚫 3. Qué NO entra todavía

- cgroups y namespaces por dentro: se nombran, se ven y se sigue.
- Achicar las imágenes, el multi-stage y las bases → [Fase 04](04-empaquetar-los-cuatro-runtimes.md).
- Las diferencias completas entre los dos motores → [Fase 05](05-los-dos-motores.md).
- El apagado limpio de cada servicio ante `SIGTERM` → [Fase 16](16-escalado-y-rollout.md), con el rollout que lo necesita.
- `securityContext` y el endurecimiento del pod → [Fase 20](20-seguridad-del-pod-y-de-la-red.md).

---

## 🧨 4. El problema, en el laboratorio

La pregunta de Luz Marina tiene una prueba directa. Le doy a un contenedor un límite de 64 MB y le
pregunto cuánta memoria tiene:

```text
$ docker run --rm --memory 64m lab/replenish free -m
              total        used        free      shared  buff/cache   available
Mem:           3916        1002        1039           3        1875        2729
Swap:          1024           0        1024
```

Casi cuatro gigas: la memoria de la máquina virtual de Docker Desktop, que en este laboratorio tiene
4 GiB ([a01](a01-el-laboratorio.md#-la-memoria-que-ocupa-cada-perfil)). El límite existe, pero no
está donde `free` lo busca:

```text
$ docker run --rm --memory 64m --cpus 0.5 lab/replenish cat /sys/fs/cgroup/memory.max /sys/fs/cgroup/cpu.max
67108864
50000 100000
$ docker run --rm lab/replenish cat /sys/fs/cgroup/memory.max
max
```

Los 64 MB están en un archivo del **cgroup** del proceso, y medio procesador, como "50 milisegundos
de cada 100". Una máquina virtual ve lo que le asignas; un contenedor ve la máquina entera y el
kernel le corta el paso cuando cruza la línea. Un programa que dimensiona su memoria leyendo `/proc/meminfo` se equivoca
dentro de un contenedor; la JVM de Java 25 lee el cgroup, y aun así la [Fase 15](15-salud-y-recursos.md) la va a ver morir
por memoria. La razón empieza aquí.

> 🧠 **Modelo mental.** Un contenedor es **un proceso** del sistema operativo de otra máquina, al
> que el kernel le recorta lo que ve (namespaces) y le limita lo que gasta (cgroups).

---

## 🔬 5. El contenedor por dentro, con `pricing`

### 5.1 Un proceso, con dos números

Desde adentro, `pricing` es el proceso 1 y está solo:

```text
$ docker compose -f compose/compose.yaml exec pricing ps
PID   USER     TIME  COMMAND
    1 root      0:00 /app/pricing
   11 root      0:00 ps
```

Desde afuera, es uno más. En macOS y en Windows los contenedores corren dentro de la máquina virtual
del motor, así que "afuera" es esa máquina. Un contenedor con `--pid=host` comparte su vista de
procesos y la deja leer (uso la imagen de `replenish` solo porque trae `ps`):

```text
$ docker inspect lab-pricing-1 --format '{{.State.Pid}}'
8019
$ docker run --rm --pid=host lab/replenish ps -o pid,ppid,user,args      # recortada a los cinco procesos 1
PID   PPID  USER     COMMAND
 7818  7793 root     java -jar target/inventory-0.0.1-SNAPSHOT.jar
 7894  7864 root     php artisan serve --host=0.0.0.0 --port=8080
 7951  7926 root     {MainThread} node dist/main.js
 8019  7993 root     /app/pricing
 8080  8057 root     npm exec vite preview --host 0.0.0.0 --port 8080 --strictPort
```

Ahí están los cinco servicios de G0, como procesos vecinos de la misma máquina. `pricing` es el 1
para sí mismo y el 8019 para la máquina. Lo que hace la diferencia son los **namespaces**: el kernel
le asigna al proceso su propia tabla de procesos, su propia red, su propio sistema de archivos y su
propio nombre de host. Se ven comparando el proceso 1 de la máquina con el de `pricing`:

```text
$ docker run --rm --pid=host --privileged lab/replenish sh -c 'for n in pid net mnt uts; do echo $(readlink /proc/1/ns/$n) $(readlink /proc/8019/ns/$n); done'
pid:[4026531836] pid:[4026532978]
net:[4026531833] net:[4026532980]
mnt:[4026531832] mnt:[4026532975]
uts:[4026531838] uts:[4026532976]
```

A la izquierda, los namespaces del proceso 1 de la máquina; a la derecha, los de `pricing`. Cada
número distinto es un namespace distinto. Y el **cgroup** es el otro mecanismo: el grupo al que
pertenece el proceso, donde viven el `memory.max` y el `cpu.max` de la sección anterior. Hasta aquí
llega el curso con los dos: se nombran, se ven, y se sigue.

### 5.2 Un solo kernel

La segunda prueba de que no hay máquina dentro del contenedor:

```text
$ docker run --rm lab/replenish uname -r
7.0.12-linuxkit
$ uname -r          # en el Mac
25.6.0
```

Todos los contenedores de Docker Desktop comparten el kernel Linux de su máquina virtual, y por eso
un contenedor arranca en lo que tarda en crearse un proceso, no un sistema operativo:

```text
$ hyperfine --warmup 2 --runs 10 'docker run --rm lab/pricing true'
  Time (mean ± σ):     234.6 ms ±  12.8 ms    [User: 15.8 ms, System: 11.7 ms]
  Range (min … max):   220.4 ms … 268.3 ms    10 runs
```

Un cuarto de segundo para crear un contenedor, correr `true` y borrarlo. Y **la imagen no trae
kernel**: por eso en macOS y en Windows siempre hay una máquina virtual de por medio.

### 5.3 La imagen y sus capas

Una imagen es una pila de capas de solo lectura, una por cada instrucción del Dockerfile que cambia
archivos, más la configuración (el `CMD`, las variables, el usuario):

```text
$ docker history lab/pricing
IMAGE          CREATED        CREATED BY                                      SIZE      COMMENT
2678e06a7700   12 hours ago   CMD ["/app/pricing"]                            0B        buildkit.dockerfile.v0
<missing>      12 hours ago   EXPOSE [8080/tcp]                               0B        buildkit.dockerfile.v0
<missing>      12 hours ago   RUN /bin/sh -c go build -o pricing . # build…   107MB     buildkit.dockerfile.v0
<missing>      12 hours ago   COPY go.mod main.go ./ # buildkit               16.4kB    buildkit.dockerfile.v0
<missing>      12 hours ago   WORKDIR /app                                    8.19kB    buildkit.dockerfile.v0
…
<missing>      2 weeks ago    COPY /target/ / # buildkit                      290MB     buildkit.dockerfile.v0
…
<missing>      2 weeks ago    ADD alpine-minirootfs-3.24.2-aarch64.tar.gz …   9.31MB    buildkit.dockerfile.v0
```

Abajo, la imagen base `golang`: Alpine y los 290 MB del compilador. Arriba, el Dockerfile de G0, con
una capa que llama la atención: **107 MB para producir un binario**.

```text
$ docker run --rm lab/pricing sh -c 'du -sh /root/.cache/go-build /app/pricing /usr/local/go'
92.9M	/root/.cache/go-build
8.6M	/app/pricing
276.6M	/usr/local/go
$ docker images lab/pricing
IMAGE                ID             DISK USAGE   CONTENT SIZE   EXTRA
lab/pricing:latest   2678e06a7700        507MB         99.6MB   U
```

El binario que corre pesa 8,6 MB; lo demás es el compilador y su caché, que viajan a cada máquina y
no se usan después del build. `CONTENT SIZE` es lo que viaja por la red, comprimido; `DISK USAGE`, lo
que ocupa descomprimido. Achicarlo es la [Fase 04](04-empaquetar-los-cuatro-runtimes.md).

**`dive` se estrena aquí**, porque la [Fase 04](04-empaquetar-los-cuatro-runtimes.md) lo usa para medir. Abierto sin argumentos muestra cada
capa con sus archivos; en modo no interactivo, un resumen:

```text
$ CI=true dive lab/pricing
  efficiency: 99.9402 %
  wastedBytes: 407269 bytes (407 kB)
  userWastedPercent: 0.1199 %
…
Result:PASS [Total:3] [Passed:2] [Failed:0] [Warn:0] [Skipped:1]
```

Eficiencia del 99,94 % en una imagen de 507 MB que podría pesar 15: `dive` mide lo que se
**desperdicia entre capas**, no lo que la imagen trae sin necesitarlo. Eso lo decides tú.

### 5.4 La capa que sí se escribe

Encima de las capas de la imagen, cada contenedor tiene **una capa escribible propia**. Todo lo que
el proceso escribe fuera de un volumen va ahí:

```text
$ docker exec lab-pricing-1 sh -c 'echo "precio de prueba" > /tmp/nota.txt'
$ docker diff lab-pricing-1
C /tmp
A /tmp/nota.txt
$ docker compose -f compose/compose.yaml up -d --force-recreate pricing
 Container lab-pricing-1 Started
$ docker exec lab-pricing-1 cat /tmp/nota.txt
cat: can't open '/tmp/nota.txt': No such file or directory
```

`docker diff` lista lo que cambió respecto de la imagen. Recrear el contenedor crea una capa
escribible nueva y vacía, y la nota se fue con la anterior. Por eso Postgres guarda en un volumen
desde la [Fase 01](01-primer-contenedor-y-dockerfile.md), y es el mecanismo del experimento 🧨 de la [Fase 12](12-estado-y-almacenamiento.md).

### 5.5 OCI: la imagen es un archivo

Una imagen no es de Docker: es un formato abierto, el de la **Open Container Initiative**, con un
manifiesto, una configuración y una lista de capas, cada una identificada por el hash de su
contenido. Guardada como archivo, se carga en Podman sin reconstruir nada:

```text
$ docker save lab/pricing -o pricing-g0.tar
$ tar -tf pricing-g0.tar | head -3
blobs/
blobs/sha256/
blobs/sha256/057882bd9dc54237caf0f7fd63808ccda1fb2d24c672a1b0592d5296d6645215
$ podman load -i pricing-g0.tar
Loaded image: docker.io/lab/pricing:latest
$ podman run -d --name pricing -p 127.0.0.1:18080:8080 lab/pricing
$ curl -s 'http://127.0.0.1:18080/prices/SKU-0003?store=DRO-007'
{"currency":"COP","price":12900,"sku":"SKU-0003","store":"DRO-007"}
```

Un detalle que confunde: Podman la lista con el ID `0bbb532fd078` y Docker con `2678e06a7700`. Los
dos hashes están en el archivo; Podman muestra el de la configuración, y Docker, con su almacén de
containerd, el del índice que la envuelve. Por eso el curso fija las imágenes por **digest**, el hash
del manifiesto en el registry, y no por el ID que muestra tu motor.

> 🩻 **Esto sí funciona igual.** Una imagen construida con Docker corre en Podman, en kind y en
> cualquier cluster, porque todos hablan OCI. Construir con un motor y correr con otro no rompe
> nada, y la [Fase 08](08-el-primer-despliegue.md) lo usa cada vez que carga una imagen al cluster.

### 5.6 El proceso 1 y las señales, con `pricing`

`docker stop` le manda `SIGTERM` al proceso 1, espera, y si sigue vivo le manda `SIGKILL`. La Braqui
murió así en la [Fase 01](01-primer-contenedor-y-dockerfile.md), con 137 (128 + 9). `pricing` no:

```text
$ time docker stop -t 10 lab-pricing-1
lab-pricing-1

real	0m0.119s
user	0m0.015s
sys	0m0.010s
$ docker inspect lab-pricing-1 --format '{{.State.ExitCode}}'
143
```

143 es 128 + 15: lo terminó el `SIGTERM`, en 0,12 segundos. Paso `-t 10` a propósito, porque el valor por defecto de
Docker Desktop no es el de la documentación (la [Fase 01](01-primer-contenedor-y-dockerfile.md) midió 3,1 segundos). Y que `pricing` salga
rápido **no quiere decir que salga bien**: su G0 no instala manejador de señales, el runtime de Go
muere en el acto, y una petición a medio contestar se corta. En un rollout con tráfico eso es un
error para el cliente. Es deuda 💸, y se cobra en la [Fase 16](16-escalado-y-rollout.md).

### 5.7 Usuarios, permisos y el bucle que se reinicia solo

Los cinco servicios de G0 corren como `root` dentro del contenedor (`docker run --rm lab/pricing id`
dice `uid=0(root)`), porque sus Dockerfile no dicen `USER`. La [Fase 04](04-empaquetar-los-cuatro-runtimes.md) lo cambia, y cambiarlo trae
el reinicio en bucle más frustrante de la Parte II. Lo provoco antes, simulando el SQLite que la
[Fase 09](09-los-cuatro-servicios-dentro.md) guarda en un volumen, con `replenish` corriendo como `node`, el usuario de su imagen base:

```text
$ docker run --rm --user node -v replenish-datos:/var/lib/replenish lab/replenish sh -c "touch /var/lib/replenish/replenish.db"
touch: /var/lib/replenish/replenish.db: Permission denied
$ docker run --rm -v replenish-datos:/var/lib/replenish lab/replenish ls -ld /var/lib/replenish
drwxr-xr-x    2 root     root          4096 Oct  3 21:34 /var/lib/replenish
$ docker run -d --name replenish-bucle --restart on-failure --user node -v replenish-datos:/var/lib/replenish \
    lab/replenish sh -c 'touch /var/lib/replenish/replenish.db && node dist/main.js'
$ docker ps -a --filter name=replenish-bucle --format '{{.Names}}  {{.Status}}'      # 20 segundos después
replenish-bucle  Restarting (1) 6 seconds ago
$ docker inspect replenish-bucle --format 'RestartCount={{.RestartCount}}'
RestartCount=8
```

El volumen nuevo nació de `root`, y con una política de reinicio el `Permission denied` se volvió
ocho reinicios en veinte segundos, cada uno esperando un poco más. En Kubernetes eso se llama
`CrashLoopBackOff`. La salida está en la imagen: **un volumen con nombre que nace vacío copia el
contenido y el dueño de la carpeta de la imagen donde se monta**. Contingencia necesitó el mismo
arreglo para escribir sus traslados ([a16](a16-el-patrimonio.md)).

```dockerfile
FROM lab/replenish
# La carpeta de los datos existe en la imagen y es del usuario que corre: el volumen la hereda.
RUN mkdir -p /var/lib/replenish && chown node:node /var/lib/replenish
USER node
```

```text
$ docker run --rm -v replenish-datos:/var/lib/replenish lab-f03/replenish-nonroot sh -c 'id; touch /var/lib/replenish/replenish.db && ls -l /var/lib/replenish'
uid=1000(node) gid=1000(node) groups=1000(node),1000(node)
-rw-r--r--    1 node     node             0 Oct  3 21:35 replenish.db
```

> 🦭 **Con Podman sin root, el mismo `--user 1000 -v …` funciona**: Podman le cambia el dueño al
> volumen nuevo para que coincida con el usuario del contenedor, y Docker no. Y el `root` del
> contenedor **no es root** en la máquina:
>
> ```text
> $ podman top pricing user huser pid args
> USER        HUSER       PID         COMMAND
> root        501         1           /app/pricing
> ```
>
> `root` adentro, tu usuario (501) afuera. Lo que eso significa para el laboratorio es la [Fase 05](05-los-dos-motores.md).

**El patrón a memorizar.** Un contenedor es un proceso de la máquina del motor, con su tabla de
procesos, su red y su sistema de archivos recortados, y su memoria limitada por un archivo del
cgroup. Lo que escribe en su capa se va con él; lo que necesita durar va en un volumen, y el volumen
hereda el dueño de la carpeta de la imagen.

---

## 🔁 6. Los otros tres: donde no es mecánico

Ver un proceso, leer capas y escribir en un volumen es igual con los cuatro runtimes. **Lo que no es
mecánico es cómo muere cada uno.** Apagué los cinco servicios de G0 tres veces, con `docker stop -t
10`:

| Servicio | Proceso 1 | `stop` (3 corridas) | Código |
|---|---|---|---|
| `pricing` | `/app/pricing` (Go) | 0,12 – 0,14 s | 143 |
| `inventory` | `java -jar …` | 0,12 – 0,14 s | 143 |
| `catalog` | `php artisan serve` | 10,12 – 10,17 s | 137 |
| `replenish` | `node dist/main.js` | 10,13 – 10,15 s | 137 |
| `storefront` | `npm exec vite preview` | 0,14 – 0,16 s | 143 |

- **`inventory`** sale rápido y **bien**: la JVM instala su manejador de `SIGTERM`, y Spring Boot
  cierra con cortesía (`Commencing graceful shutdown` y `Graceful shutdown complete` en el log).
- **`replenish`** espera los diez segundos y muere con `SIGKILL`. Node como proceso 1 no tiene
  manejador, y el kernel no le aplica al proceso 1 de un namespace la acción por defecto de una señal
  que no atiende: la ignora.
- **`catalog`** llega a 137 por lo mismo con otro programa: `php artisan serve` es el proceso 1, lanza
  el servidor de PHP como hijo (`php -S`) y no atiende la señal.
- **`storefront`** sale rápido aunque su servidor sea Node: el proceso 1 es `npm exec` (lo que corre
  `npx`), que atiende `SIGTERM` y se la pasa a su hijo.

Dos de cinco, muertos por la fuerza. La regla no es "Node malo, Java bueno": **el que recibe la
señal es el proceso 1, y lo que importa es quién es**.

### 6.1 La forma del `CMD` también decide

Hay una cuarta variable, y no es el lenguaje: **la forma del `CMD`**. La [Fase 01](01-primer-contenedor-y-dockerfile.md) dejó la regla de
escribirlo siempre en forma JSON sin demostrarla. La demostración es la rotura de la sección 8, con
`inventory`.

### 6.2 `--init`: un proceso 1 que sí sabe serlo

Para el caso de `replenish`, donde el programa no atiende la señal, el motor ofrece un proceso 1
mínimo que la reenvía:

```text
$ docker run -d --name replenish-init --init lab/replenish
$ docker exec replenish-init ps -o pid,ppid,args
PID   PPID  COMMAND
    1     0 /sbin/docker-init -- docker-entrypoint.sh node dist/main.js
    7     1 {MainThread} node dist/main.js
   16     0 ps -o pid,ppid,args
$ time docker stop -t 10 replenish-init
replenish-init

real	0m0.117s
user	0m0.016s
sys	0m0.008s
$ docker inspect replenish-init --format '{{.State.ExitCode}}'
143
```

`docker-init` (tini) es el proceso 1 y le pasa el `SIGTERM` a Node, que muere por la señal sin
esperar diez segundos. Es un parche, **no el arreglo**: que cada servicio atienda `SIGTERM` y
termine lo que tiene en vuelo llega con el paso G5, en la [Fase 16](16-escalado-y-rollout.md). Hasta entonces, esta tabla es la
deuda 💸 declarada.

---

## 🪞 7. Tu instinto de la máquina virtual dice… y la apuesta

El instinto, en su mejor versión: *"`docker stop` es apagar la máquina: el apagado le avisa a cada
proceso, y si alguno se cuelga, a los diez segundos se corta la luz."* En una máquina virtual es
cierto, porque un sistema de arranque (systemd, el servicio de Windows, el script de WebLogic)
recibe el aviso y lo reparte. En un contenedor no hay sistema de arranque: hay un proceso 1, y lo que
haga con la señal es todo lo que pasa.

> 🪞 **Apuesta antes de ejecutar.** `inventory` (la JVM instala su manejador de `SIGTERM`) sale en
> menos de un segundo con 143. `pricing` (Go como PID 1) también sale enseguida, pero con código 2:
> el runtime de Go muere ante la señal sin apagado limpio. `replenish`, `catalog` y `storefront`
> agotan los diez segundos y mueren con 137, porque Node y el `sh -c` como PID 1 no atienden la
> señal.
>
> **Resultado: perdida en dos de cinco.** `inventory`, `replenish` y `catalog` salieron como dije.
> `pricing` salió enseguida, pero con 143 y no con 2: murió por la señal misma. Y `storefront` salió
> en 0,15 segundos con 143, porque su proceso 1 no es Node ni `sh` sino `npm exec`, que reenvía la
> señal. Lo apostado sobre `sh -c` era el instinto de la [Fase 01](01-primer-contenedor-y-dockerfile.md); la imagen de Alpine ya había
> reemplazado el `sh` antes de que llegara la señal.

La apuesta perdida enseña más: **no se puede predecir cómo muere un contenedor leyendo
su lenguaje**. Hay que mirar el proceso 1, y cambia con el shell de la imagen, con el envoltorio
(`npm`, `artisan`, un `start.sh`) y con la forma del `CMD`.

---

## 🧨 8. La rotura: el `CMD` en forma de texto

Esta fase no tiene medición; tiene una rotura. **El cambio exacto:** en `inventory`, que con `CMD
["java", "-jar", "target/inventory-0.0.1-SNAPSHOT.jar"]` se detiene en 0,12 segundos, cambio solo la
forma:

```dockerfile
FROM lab/inventory
CMD java -jar target/inventory-0.0.1-SNAPSHOT.jar
```

**El síntoma literal** (y en las tres corridas del registro, 10,14 segundos y 137):

```text
$ docker image inspect lab-f03/inventory-shell --format '{{json .Config.Cmd}}'
["/bin/sh","-c","java -jar target/inventory-0.0.1-SNAPSHOT.jar"]
$ docker run -d --name inventory-shell lab-f03/inventory-shell
$ docker exec inventory-shell ps -o pid,ppid,args
    PID    PPID COMMAND
      1       0 /bin/sh -c java -jar target/inventory-0.0.1-SNAPSHOT.jar
      7       1 java -jar target/inventory-0.0.1-SNAPSHOT.jar
     56       0 ps -o pid,ppid,args
$ time docker stop -t 10 inventory-shell
inventory-shell

real	0m10.151s
user	0m0.021s
sys	0m0.013s
$ docker inspect inventory-shell --format '{{.State.ExitCode}}'
137
```

La forma de texto se guarda como `/bin/sh -c "…"`, y en la imagen de Temurin `/bin/sh` es `dash`,
que se queda como proceso 1 con Java de hijo y no le pasa el `SIGTERM` a nadie. El log no tiene las
dos líneas de `GracefulShutdown`: la JVM nunca se enteró. **Para salir:** volver a la forma JSON, o,
si el arranque necesita un script, que termine con `exec` (sección 9).

> ⚠️ **No siempre pasa, y eso es lo peligroso.** Con `replenish`, sobre Alpine, la misma forma de
> texto dejó a Node como proceso 1, porque el `sh` de busybox se reemplaza por el último comando
> cuando puede; con `node dist/main.js || echo "…"`, `sh` se queda. La forma JSON no depende del
> shell de la imagen.

---

## ⚰️ 9. Autopsia: el script de arranque que se quedó con el proceso 1

**La decisión, con su mejor argumento.** Al llevar un servicio Java a un contenedor, el equipo
conserva su script de arranque, el que arma las opciones de la JVM y llama a `java`: *"así arranca
desde hace diez años, y las opciones de memoria no se tocan"*. En La Vecina ese script existe, y
carga el `-Xmx` que se copia de servidor en servidor desde la migración a WebLogic (historia §1.6).

**Por qué era razonable.** En el servidor lo lanzaba un sistema de arranque que sabía apagarlo, y el
script nunca recibía señales. Moverlo tal cual es la forma más segura de no cambiar la JVM.

**Qué pasa después, con número.** Con `inventory` y un `start.sh` que termina en `java $JAVA_OPTS
-jar …`, el contenedor arranca y pasa cualquier prueba. Al detenerlo, `sh start.sh` es el proceso 1 y
Java su hijo: cada detención, despliegue o reinicio cuesta el tiempo de gracia completo y una JVM
muerta a la fuerza, sin una línea de cierre. En la Parte II, eso es por cada réplica de cada rollout.

**Cuánto cuesta salir, con número.** Una palabra: la última línea pasa a `exec java $JAVA_OPTS -jar
…`, y `exec` reemplaza al shell por Java, que queda como proceso 1.

**Qué lo habría cambiado.** Preguntar *¿quién es el proceso 1?* al mover el script. El script no
estaba mal: estaba escrito para un mundo en el que alguien más recibía la señal.

**Antes y después, con números:** `docker stop -t 10` de `inventory` con `start.sh` sin `exec`: 10,13
a 10,14 segundos y 137, tres de tres. Con `exec`: 0,12 a 0,15 segundos y 143, con las dos líneas del
apagado de Spring en el log.

---

## 📖 10. Traducción

La que hace falta en esta fase no es compose ⇄ Kubernetes (esa es la [Fase 06](06-del-compose-al-cluster.md)) sino la del mundo de
servidores del que viene Luz Marina, en las dos direcciones:

| En una máquina virtual | En un contenedor | Lo que cambia |
|---|---|---|
| memoria asignada a la máquina | `memory.max` del cgroup | el proceso ve la máquina entera; el kernel lo corta al cruzar |
| el sistema de arranque reparte el apagado | el proceso 1 recibe `SIGTERM` | si el proceso 1 no la atiende, nadie la atiende |
| el disco de la máquina | la capa escribible | se va con el contenedor; lo que dura va en un volumen |
| *sin equivalente* | el namespace | no hay otra máquina: hay una vista recortada de la misma |

🌩️ En un cluster gestionado la tabla no cambia: los nodos son máquinas virtuales, y cada pod es un
grupo de procesos con sus namespaces y su cgroup. Lo único que cambia es quién elige el kernel.

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

El aislamiento de un contenedor es **más débil que el de una máquina virtual**: los cinco servicios
comparten un kernel, y con Docker el `root` de cada contenedor es el `root` de la máquina virtual.
Para correr código no confiable, para separar clientes que no se deben ver, o para una carga que
necesita otro kernel, la máquina virtual sigue siendo la respuesta.

Y el costo que esta fase midió: **los servicios que no atienden `SIGTERM` pagan diez segundos y una
muerte a la fuerza por cada detención**. Con un solo contenedor reiniciado una vez al mes, eso no le
importa a nadie, y un servicio del sistema operativo con su unidad de systemd apaga igual de bien.

**La pregunta del curso, para esta fase:** el contenedor te dio aislamiento por namespaces, límites
por cgroup, un formato de imagen que corre en cualquier motor, y el reinicio automático. No te dio
ningún apagado: quién es el proceso 1, si atiende `SIGTERM` y qué escribe donde, **te sigue tocando
a ti**.

---

## ⚠️ 13. Errores comunes y diagnóstico

**`free` o `top` muestran la memoria equivocada.** Síntoma: 3.916 MB con un límite de 64. Causa:
leen `/proc/meminfo`, que es de la máquina. Comprobación 🩺: `docker exec <contenedor> cat
/sys/fs/cgroup/memory.max`, que es el número que manda.

**El contenedor tarda exactamente el tiempo de gracia en detenerse.** Síntoma: `stop` tarda 10
segundos (o 3, con el valor por defecto de Docker Desktop) y sale con 137. Comprobación 🩺: `docker
exec <contenedor> ps -o pid,ppid,args`, y mirar quién es el 1. Salida: forma JSON, `exec` en el
script, o `--init` como parche.

**`Permission denied` en un volumen recién creado**, con `Restarting (1)` en `docker ps`. Causa: la
imagen corre sin `root` y la carpeta no existe en la imagen. Comprobación 🩺: `docker run --rm -v
<volumen>:/ruta <imagen> ls -ld /ruta`. Salida: crear la carpeta en el Dockerfile con su dueño.

---

## 📋 14. Checklist de validación

```text
[ ] el proceso de pricing, con su número adentro (1) y en la máquina virtual
[ ] con --memory 64m, free -m muestra la máquina y memory.max dice 67108864
[ ] docker history y dive sobre lab/pricing, y sabes qué capa pesa 107 MB y por qué
[ ] lab/pricing pasó de Docker a Podman como archivo y contestó
[ ] la tabla de stop de los cinco servicios, medida en tu máquina
[ ] inventory con CMD en forma de texto tarda el tiempo de gracia; con forma JSON, no
[ ] el volumen con Permission denied, y funcionando con la carpeta creada en la imagen
```

---

## 🧪 15. Ejercicios (20)

Un tercio son de diagnóstico, y la mayoría usa un servicio distinto de `pricing`: las señales son
donde los runtimes se separan.

## 🟢 Fácil — mirar por dentro (1–6)

### 🟢 Ejercicio 1 — Los dos números de `inventory`
Encuentra el número de proceso de `inventory` dentro de su contenedor y en la máquina virtual.

**Criterio:** tienes los dos números, y el de adentro es 1.

<details><summary>Solución</summary>

`docker compose -f compose/compose.yaml exec inventory ps -o pid,args` y `docker inspect
lab-inventory-1 --format '{{.State.Pid}}'`.
</details>

### 🟢 Ejercicio 2 — El límite que no se ve
Corre `lab/catalog` con `--memory 128m` y muestra lo que dicen `free -m` y el cgroup.

**Criterio:** `free -m` muestra la memoria de la máquina virtual y `memory.max` dice `134217728`.

<details><summary>Solución</summary>

`docker run --rm --memory 128m lab/catalog sh -c 'free -m; cat /sys/fs/cgroup/memory.max'`.
</details>

### 🟢 Ejercicio 3 — Las capas de `replenish`
Muestra las capas de `lab/replenish` y di cuál es la más grande de las que agregó su Dockerfile.

**Criterio:** la salida de `docker history lab/replenish` y el nombre de la instrucción, con su
tamaño.

<details><summary>Solución</summary>

`docker history lab/replenish`. Las del Dockerfile de G0 son las de arriba hasta `WORKDIR /app`; la
más grande es la de `npm ci` o la de `npm run build`, según tu caché.
</details>

### 🟢 Ejercicio 4 — Lo que cambió
Escribe un archivo en `/tmp` de `catalog` y muéstralo con `docker diff`.

**Criterio:** `docker diff lab-catalog-1` lista tu archivo con `A`.

<details><summary>Solución</summary>

`docker exec lab-catalog-1 sh -c 'echo prueba > /tmp/nota.txt'` y `docker diff lab-catalog-1`.
</details>

### 🟢 Ejercicio 5 — Un kernel
Compara el kernel que ve `pricing` con el que ve `inventory`.

**Criterio:** `uname -r` devuelve lo mismo en los dos contenedores, y no es el de tu sistema
operativo (salvo en Linux sin máquina virtual).

<details><summary>Solución</summary>

`docker exec lab-pricing-1 uname -r` y `docker exec lab-inventory-1 uname -r`.
</details>

### 🟢 Ejercicio 6 — `dive` sobre otro
Corre `dive` en modo no interactivo sobre `lab/storefront`.

**Criterio:** tienes la eficiencia y los bytes desperdiciados, copiados de la salida.

<details><summary>Solución</summary>

`CI=true dive lab/storefront`. En Windows, `$env:CI="true"; dive lab/storefront` (no verificado por el
autor; se confirma al hacer el curso).
</details>

## 🟡 Intermedio — señales y permisos (7–12)

### 🟡 Ejercicio 7 — La tabla de `stop`, en tu máquina
Mide `docker stop -t 10` de los cinco servicios, tres veces cada uno.

**Criterio:** tu tabla con tiempo y código de salida de cada uno, y una frase si alguno no coincide
con la de la sección 6.

<details><summary>Solución</summary>

`task compose:up`, esperar a que arranquen, y por cada servicio `time docker stop -t 10
lab-<svc>-1` y `docker inspect lab-<svc>-1 --format '{{.State.ExitCode}}'`. Entre corridas,
`docker compose -f compose/compose.yaml up -d`.
</details>

### 🟡 Ejercicio 8 — El valor por defecto de tu motor
Mide `docker stop` de `replenish` **sin** `-t`.

**Criterio:** el tiempo medido, tres veces, y el código 137.

<details><summary>Solución</summary>

`time docker stop lab-replenish-1`, tres veces, con `up -d` entre medio. En Docker Desktop salen
alrededor de 3 segundos; en Podman, alrededor de 10. Es lo que midió la [Fase 01](01-primer-contenedor-y-dockerfile.md).
</details>

### 🟡 Ejercicio 9 — `--init` para `catalog`
Corre `lab/catalog` con `--init` y mide su `stop`.

**Criterio:** el `stop` baja de 10 segundos a menos de uno, y `ps` dentro del contenedor muestra
`docker-init` como proceso 1.

<details><summary>Solución</summary>

`docker run -d --name catalog-init --init lab/catalog`, `docker exec catalog-init ps -o
pid,ppid,args` y `time docker stop -t 10 catalog-init`.
</details>

### 🟡 Ejercicio 10 — El volumen de `inventory`
Repite el `Permission denied` de 5.7 con `inventory`, que corre sobre Ubuntu: crea un usuario en una
imagen derivada y escribe en un volumen nuevo en `/var/lib/inventory`.

**Criterio:** el `Permission denied` literal, y después el archivo creado con la carpeta creada en
la imagen.

<details><summary>Solución</summary>

Una imagen `FROM lab/inventory` con `RUN useradd -u 1001 inventory && mkdir -p /var/lib/inventory`,
sin `chown`, falla; con `chown inventory /var/lib/inventory` y `USER inventory`, funciona. El
volumen hay que borrarlo entre una prueba y otra: el dueño se copia solo cuando el volumen nace.
</details>

### 🟡 Ejercicio 11 — De Docker a Podman, con `catalog`
Lleva `lab/catalog` a Podman como archivo y córrela.

**Criterio:** `podman images` la lista, y `curl` contra el puerto que publicaste devuelve los dos
productos de G0.

<details><summary>Solución</summary>

`docker save lab/catalog -o catalog.tar`, `podman load -i catalog.tar`, `podman run -d -p
127.0.0.1:18081:8080 lab/catalog` y `curl -s http://127.0.0.1:18081/products`.
</details>

### 🟡 Ejercicio 12 — `root` adentro, ¿quién afuera?
Corre `pricing` en Podman y en Docker, y averigua con qué usuario corre el proceso en la máquina
virtual de cada motor.

**Criterio:** con Podman, `podman top <contenedor> user huser` muestra `root` y tu usuario; con
Docker, el proceso es `root` también afuera.

<details><summary>Solución</summary>

`podman top <contenedor> user huser pid args`; para Docker, `docker run --rm --pid=host
lab/replenish ps -o pid,user,args` y buscar `/app/pricing`.
</details>

## 🟠 Difícil — predecir antes de ejecutar (13–17)

### 🟠 Ejercicio 13 — El script de `replenish`
Escribe un `start.sh` para `replenish` que imprima una línea y arranque Node, primero sin `exec` y
después con `exec`. **Predice** el tiempo de `stop` de cada uno.

**Criterio:** la predicción escrita, y los dos tiempos medidos con su código.

**Rúbrica:** la predicción; `ps` dentro de cada contenedor; los dos tiempos; y por qué con `exec`
Node sigue muriendo con 143 y no cierra con cortesía (no tiene manejador, y eso es la [Fase 16](16-escalado-y-rollout.md)).

### 🟠 Ejercicio 14 — ¿Dónde está el shell?
Construye una imagen `FROM lab/replenish` con `CMD node dist/main.js` y otra con `CMD node
dist/main.js || echo "replenish terminó con error"`. **Predice** cuál deja a `sh` como proceso 1.

**Criterio:** la predicción escrita, y `ps` de las dos.

**Rúbrica:** la predicción; las dos salidas de `ps`; los dos tiempos de `stop`; y la explicación del
`exec` implícito del `sh` de busybox.

### 🟠 Ejercicio 15 — El que reinicia en bucle
Reproduce el bucle de 5.7 y mide cuánto espera el motor entre un reinicio y el siguiente.

**Criterio:** `RestartCount` a los 10, 20 y 40 segundos, y una conclusión sobre cómo crece la espera.

**Rúbrica:** las tres lecturas; la conclusión (la espera crece); y qué harías para ver el error sin
esperar a que se repita (`docker logs` del contenedor).

### 🟠 Ejercicio 16 — 64 MB para Java
Corre `lab/inventory` con `--memory 64m`. **Predice** si arranca.

**Criterio:** la predicción escrita, el estado del contenedor (`docker inspect … {{.State.OOMKilled}}
{{.State.ExitCode}}`) y las últimas líneas del log.

**Rúbrica:** la predicción; la evidencia; y si la JVM se quejó por sí misma o la mató el kernel. No
busques el arreglo: es la [Fase 15](15-salud-y-recursos.md).

### 🟠 Ejercicio 17 — El peso que no se usa
Calcula qué porcentaje de `lab/pricing` es el binario que corre.

**Criterio:** el tamaño del binario, el de la imagen y el porcentaje.

**Rúbrica:** los dos números con su comando (`du -sh /app/pricing` y `docker images`); el porcentaje;
y qué tres cosas de la imagen esperas que la [Fase 04](04-empaquetar-los-cuatro-runtimes.md) deje fuera.

## 🔴 Muy difícil — el laboratorio roto (18–20)

### 🔴 Ejercicio 18 — Dos de cinco
Sin tocar el código de ningún servicio, consigue que los cinco de G0 terminen `docker stop -t 10` en
menos de un segundo.

**Criterio:** la tabla de la sección 6 medida de nuevo, con los cinco por debajo de un segundo.

**Rúbrica:** qué cambiaste y dónde (compose, el `CMD`, `init: true`); la tabla; y por qué esto no es
todavía un apagado limpio para ninguno salvo `inventory`.

### 🔴 Ejercicio 19 — El sistema de arranque que no está
Corre en un contenedor de Ubuntu (la imagen de `inventory`) dos procesos de larga vida lanzados por
un `sh` como proceso 1, y detén el contenedor.

**Criterio:** `ps` con los tres procesos, el tiempo de `stop`, y el log de los dos procesos (o su
ausencia) al morir.

**Rúbrica:** el montaje; la evidencia; y la explicación de por qué un contenedor con varios procesos
necesita un proceso 1 que reparta señales, que es lo que hace el sistema de arranque de una máquina
virtual y lo que `catalog` va a necesitar en la [Fase 04](04-empaquetar-los-cuatro-runtimes.md) si alguien mete nginx y PHP-FPM en la misma
imagen.

### 🔴 Ejercicio 20 — El volumen de otro motor
Explica, con evidencia, por qué el mismo `--user 1000 -v datos:/var/lib/replenish` falla en Docker y
funciona en Podman sin root.

**Criterio:** las dos salidas, y el dueño del archivo creado visto desde la máquina virtual de
Podman.

**Rúbrica:** las dos ejecuciones; `podman machine ssh -- ls -ln <ruta del volumen>` con el dueño
numérico que ve la máquina (un número de subusuario, no 1000); y una explicación de qué es un
espacio de usuarios mapeado, en tus palabras y en un párrafo.

---

## 📚 16. Referencias

**Documentación oficial** (sin versión fija)

- Docker, *Dockerfile reference*, la forma de texto y la forma JSON:
  https://docs.docker.com/reference/dockerfile/#shell-and-exec-form — la diferencia del `CMD`.
- Docker, `docker container run`, la opción `--init`:
  https://docs.docker.com/reference/cli/docker/container/run/#init
- Docker, *Start containers automatically*: https://docs.docker.com/engine/containers/start-containers-automatically/
  — las políticas de reinicio y la espera creciente.
- Podman, *Basic setup and use of Podman in a rootless environment*:
  https://github.com/podman-container-tools/podman/blob/main/docs/tutorials/rootless_tutorial.md
- `dive`: https://github.com/wagoodman/dive · `tini`: https://github.com/krallin/tini — el proceso 1
  mínimo que usa `--init`, con la explicación de por qué existe.

**Especificaciones**

- OCI Image Format Specification: https://github.com/opencontainers/image-spec/blob/main/spec.md
- Las páginas del manual de Linux `namespaces(7)` y `pid_namespaces(7)`:
  https://man7.org/linux/man-pages/man7/namespaces.7.html y
  https://man7.org/linux/man-pages/man7/pid_namespaces.7.html — la segunda dice por qué el proceso 1
  ignora las señales que no atiende.

**Libros**

- Marko Lukša y Kevin Conner, *Kubernetes in Action*, 2.ª edición (2026), los capítulos iniciales
  sobre contenedores: la explicación de namespaces y cgroups que este curso no da.

**Orden de lectura sugerido:** antes, nada; durante, la página de la forma JSON del Dockerfile;
después, el `README` de `tini`, que explica en una pantalla el problema del proceso 1 mejor que
cualquier capítulo.

> ⚠️ Las URL y los contenidos cambian, y las de Docker y Podman no fijan versión.

---

## 🏁 17. Resultado de la fase

```text
LO QUE SABES DE CADA CONTENEDOR DEL SISTEMA, AL CERRAR LA FASE 03

  máquina virtual del motor (un kernel Linux)
  ├── pricing      proceso 1 = el binario     stop 0,12 s · 143 · muere en seco      💸 F16
  ├── inventory    proceso 1 = la JVM          stop 0,12 s · 143 · cierra con cortesía
  ├── catalog      proceso 1 = artisan serve   stop 10 s   · 137 · lo mata el motor    💸 F04 y F16
  ├── replenish    proceso 1 = node            stop 10 s   · 137 · lo mata el motor    💸 F16
  └── storefront   proceso 1 = npm exec        stop 0,15 s · 143 · muere en seco      💸 F04
       todos como root, con su capa escribible y sin volumen propio
```

El sistema sigue igual que en la [Fase 02](02-compose-el-sistema-en-un-archivo.md): esta fase no cambió ningún archivo de `src/lab/`. Cambió lo
que sabes de él.

> **La señal de que quedó bien:** *"Antes de preguntar cuánta memoria tiene un contenedor, pregunto
> cuál es su proceso 1 y qué dice su cgroup."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde y `git status` limpio:
>
> ```bash
> git tag -a fase-03-el-contenedor-por-dentro -m "F03 cerrada: el proceso de pricing visto desde la VM; memory.max contra free; capas con history y dive; pricing de Docker a Podman por archivo; la tabla de stop de los cinco servicios; CMD en forma de texto contra JSON; volumen sin root"
> ```
>
> Commits de la fase con prefijo `f03:`, los de ejercicio `f03 ej17: …` ([convención de git](00-convencion-de-git-y-tags.md)).

---

## 📌 Pendientes sugeridos

- La [Fase 04](04-empaquetar-los-cuatro-runtimes.md) tiene que cerrar dos filas de la tabla de la sección 17: `catalog` deja de correr con
  `artisan serve` (pasa a PHP-FPM y nginx en dos contenedores) y `storefront` deja `npm exec` por
  nginx. Las dos cambian su proceso 1, y la tabla de `stop` se vuelve a medir allí.
- La [Fase 16](16-escalado-y-rollout.md) cobra la deuda de la columna 💸 con el paso G5, y cita esta tabla como el "antes".
