# 🦭 Fase 05 — Los dos motores, sin guerra: dónde divergen Docker y Podman, y cuánto cuesta cada uno

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 05 de 27 · Parte I — El modelo y el salto · **ligera**
> **Perfil:** `minimo` para cargar imágenes · `medicion` para 📏 · **Observabilidad encendida:** ninguna
> **Motor de referencia:** los dos, que es el tema · 🦭 en toda la fase
> **Servicios que toca:** `pricing` como sujeto; los cinco para la carga al cluster · **Paso de generación:** ninguno
> **Depende de:** [Fase 04](04-empaquetar-los-cuatro-runtimes.md) · **Habilita:** [Fase 06](06-del-compose-al-cluster.md)
> **Incidentes que reserva:** ninguno · **Medición:** B-05
> **Apéndices de apoyo:** [a01](a01-el-laboratorio.md), [a02](a02-problemas-del-ambiente.md)
> **Fecha de verificación ejecutada:** 03/10/2026 · macOS arm64, con Docker y con Podman · Windows 11 y Linux: no verificados por el autor
> **Objetivo:** saber dónde divergen los dos motores con la prueba delante, medir con B-05 lo que cuesta cada uno, y cargar las cinco imágenes en un cluster de kind con cualquiera de los dos con `task images:load`.

---

## 🧭 1. Dónde estamos

Las fases anteriores dejaron a Podman en notas con 🦭: un `stop` que espera distinto, un volumen que
cambia de dueño, una imagen que viaja como archivo. Esta fase las junta en un mapa antes de que la
Parte II las necesite todas a la vez.

La razón de que el curso tenga dos motores no es técnica. Cuando Valentina pidió las licencias para
La Rebotica, compras le recordó una condición: Docker Desktop exige suscripción paga en empresas de
250 empleados o más, o con 10 millones de dólares o más de ingresos, y La Vecina tiene unas 4.200
personas. Compras no aprobó otra suscripción por puesto para un POC (historia §5.4):

> *"Si eso es un experimento, que funcione con lo que no se paga. Y si funciona, hablamos."*

Valentina armó La Rebotica para que corra igual con los dos motores. Esta fase sostiene esa
decisión: **dónde son iguales, dónde no, y cuánto cuesta cada uno en el mismo portátil**. Sin
guerra: cada motor gana en algún sitio, y lo que empata se llama empate.

---

## 🎯 2. Objetivos de esta fase

1. Mostrar en la máquina virtual de cada motor quién corre los contenedores: un demonio, o ninguno.
2. Comprobar qué significa *rootless* en cada uno y qué pasa con el puerto 80.
3. Describir la máquina virtual que pone cada motor en Windows, macOS y Linux.
4. Cargar las cinco imágenes en el cluster `minimo` con los dos motores, con `task images:load`.
5. Leer la medición B-05 y decidir con ella, no con un foro.

---

## 🚫 3. Qué NO entra todavía

- El cluster por dentro (nodos, `kubectl`, contextos) → [Fase 07](07-el-cluster-local.md). Aquí se crea y se borra solo para
  cargar imágenes y medir.
- Desplegar algo en el cluster → [Fase 08](08-el-primer-despliegue.md).
- Generar manifiestos de Kubernetes desde contenedores que corren → 🔥 ejercicio 12; produce un YAML
  que nadie despliega tal cual.

---

## 🧨 4. El problema, en el laboratorio

Con Podman como motor activo y `pricing` construido, el comando que todas las guías de kind dan
para llevar una imagen al cluster falla dos veces seguidas, por razones distintas:

```text
$ kind create cluster --config kind/cluster-minimo.yaml
ERROR: failed to create cluster: failed to get docker info: command "docker info --format '{{json .}}'" failed with error: exit status 1
…
failed to connect to the docker API at unix:///Users/oskar/.docker/run/docker.sock; check if the path is correct and if the daemon is running: …
```

kind usa Docker por defecto aunque Docker esté apagado. Hay que decirle que use Podman con una
variable, que es lo que el Taskfile hace en cada llamada desde la [Fase 00](00-el-ambiente.md):

```text
$ task cluster:up -- minimo
task: [cluster:up] kind create cluster --config kind/cluster-minimo.yaml
using podman due to KIND_EXPERIMENTAL_PROVIDER
enabling experimental podman provider
…
node/minimo-control-plane condition met
$ KIND_EXPERIMENTAL_PROVIDER=podman kind load docker-image docker.io/lab/pricing --name minimo
using podman due to KIND_EXPERIMENTAL_PROVIDER
enabling experimental podman provider
ERROR: image: "docker.io/lab/pricing" not present locally
```

El cluster ya corre sobre Podman, la imagen está en Podman, y kind dice que no existe. `kind load
docker-image` le pregunta por la imagen al motor de Docker, como dice su nombre, y con Podman no hay
a quién preguntarle. La [Fase 08](08-el-primer-despliegue.md) necesita llevar imágenes al cluster en cada despliegue: esto se
resuelve aquí, una vez, y queda escondido en una tarea.

---

## 🦭 5. Dónde divergen, con `pricing`

### 5.1 Un demonio, o ninguno

Con Docker, `pricing` corriendo, la vista de procesos de la máquina virtual (el truco de `--pid=host`
de la [Fase 03](03-el-contenedor-por-dentro.md)) muestra quién lo cuida:

```text
$ docker run --rm --pid=host lab/replenish ps -o pid,ppid,user,args
PID   PPID  USER     COMMAND
  242   132 root     /usr/bin/containerd --config /etc/containerd/containerd.toml
  269   132 root     /usr/local/bin/dockerd --config-file /run/config/docker/daemon.json
  908     1 root     /usr/bin/containerd-shim-runc-v2 -namespace moby -id e9a1cbdc1912… -address /r
  930   908 65532    /pricing
…
```

`dockerd` es el demonio al que le habla tu `docker`; debajo, `containerd` maneja los contenedores, y
cada contenedor tiene su `containerd-shim`, que es su padre. Todo como `root` de la máquina virtual.
Con Podman, lo mismo:

```text
$ podman machine ssh -- ps -eo pid,ppid,user,args
    PID    PPID USER     COMMAND
  33318    1083 core     /usr/bin/podman --log-level=info system service
  33397    1083 core     /usr/bin/conmon --api-version 1 -c 6d25eb832d7d… -r /usr/bin/crun …
  33399   33397 165531   /pricing
```

No hay demonio que corra los contenedores: cada uno tiene su `conmon`, el monitor que guarda su
salida y su código de salida. El `podman system service` que aparece es el socket con la API compatible con Docker, que
existe para que herramientas como kind o el compose de Docker puedan hablarle; los contenedores no
dependen de él. Y `pricing` corre como el usuario 165531 de la máquina, no como `root`.

> 🧠 **Modelo mental.** En Docker, un servicio con privilegios corre los contenedores y tu CLI le
> pide cosas. En Podman, tu CLI los corre como procesos tuyos, cada uno con un monitor pequeño.

### 5.2 *Rootless*, de verdad

```text
$ docker info --format '{{.SecurityOptions}}'
[name=seccomp,profile=builtin name=cgroupns]
$ podman info --format '{{.Host.Security.Rootless}}'
true
```

Docker Desktop corre su motor como `root` dentro de su máquina virtual (no aparece `name=rootless`);
Podman, como un usuario sin privilegios. La [Fase 03](03-el-contenedor-por-dentro.md) mostró la consecuencia: el `root` de un
contenedor de Podman es tu usuario afuera, y los volúmenes nuevos se adaptan al usuario del
contenedor. La que más se nota en el día a día es otra:

### 5.3 El puerto 80

```text
$ docker run -d --name pricing -p 127.0.0.1:80:8080 lab/pricing
$ curl -s -o /dev/null -w '%{http_code}\n' 'http://127.0.0.1:80/health/live'
200
$ podman run -d --name pricing80 -p 127.0.0.1:80:8080 docker.io/lab/pricing
Error: cannot bind port 127.0.0.1:80: "listen tcp 127.0.0.1:80: bind: permission denied\n": with podman machine the published port is bound on the host by gvproxy, which runs unprivileged; macOS does not permit binding a privileged port (< 1024) to a specific IP address as a normal user. Publish the port without a host IP to bind all interfaces, or use a port >= 1024
```

Podman publica con un proceso tuyo (`gvproxy`), y macOS no le deja tomar un puerto privilegiado en
una dirección concreta. El mensaje propone publicar en todas las interfaces, que en un portátil de
empresa abre el servicio a la red de la oficina. **Por eso el laboratorio entra siempre por 8080 y 8443**, en
`127.0.0.1`, con los dos motores ([Fase 10](10-la-entrada-al-sistema.md)).

### 5.4 La máquina virtual de cada uno, en cada plataforma

Sin kernel Linux no hay contenedores de Linux ([Fase 03](03-el-contenedor-por-dentro.md)). Cambia quién lo pone:

| Plataforma | Docker | Podman |
|---|---|---|
| Windows 11 | Docker Desktop sobre WSL 2 | `podman machine` sobre WSL 2 (o Hyper-V) |
| macOS Apple Silicon | Docker Desktop, con el marco de virtualización de Apple | `podman machine` con libkrun (`krunkit`) |
| Linux amd64 | Docker Engine nativo, sin máquina virtual (o Docker Desktop, con una) | nativo, sin máquina virtual, sin root |

Solo la fila de macOS está verificada por el autor; las de Windows 11 y Linux salen de la
documentación de cada motor y **no están verificadas por el autor; se confirman al hacer el curso**.
En Linux, Podman no tiene máquina que encender ni dimensionar.

### 5.5 Llevar las imágenes al cluster: `task images:load`

La salida al problema de la sección 4 tiene dos partes, y las dos las encontró la verificación de
laboratorio (D32). Con Podman, la imagen **viaja como archivo**: `podman save` y `kind load
image-archive`. Y se **construye con el nombre completo** `docker.io/lab/<svc>`, porque Podman, si
no se le dice, la nombra `localhost/lab/<svc>` ([Fase 01](01-primer-contenedor-y-dockerfile.md)), y un pod que pide `lab/pricing` busca
`docker.io/lab/pricing`. La tarea lo esconde:

```yaml
  images:load:
    cmds:
      - cmd: mkdir -p .images
        if: '{{if eq .ENGINE "podman"}}true{{else}}false{{end}}'
      # Docker: kind lee la imagen del motor. Podman: kind no ve sus imágenes ("not present locally"),
      # así que viajan como archivo, y ya se llaman docker.io/lab/<svc> como las pide el pod (D32, Fase 05).
      - for: {var: SERVICES, split: ' '}
        cmd: >-
          {{if eq .ENGINE "podman"}}podman save -o .images/{{.ITEM}}.tar {{.IMAGE_PREFIX}}/{{.ITEM}} &&
          kind load image-archive .images/{{.ITEM}}.tar --name {{.PROFILE}} && rm .images/{{.ITEM}}.tar{{else}}kind
          load docker-image {{.IMAGE_PREFIX}}/{{.ITEM}} --name {{.PROFILE}}{{end}}
```

Con Podman, después de `task build:all` y `task cluster:up -- minimo`:

```text
$ time task images:load -- minimo
task: [images:load] mkdir -p .images
task: [images:load] podman save -o .images/pricing.tar docker.io/lab/pricing && kind load image-archive .images/pricing.tar --name minimo && rm .images/pricing.tar
…
real	0m20.666s
$ podman exec minimo-control-plane crictl images | grep -E "IMAGE|lab/"
IMAGE                                           TAG                  IMAGE ID            SIZE
docker.io/lab/catalog                           latest               7c1a83bfc9e39       132MB
docker.io/lab/inventory                         latest               714f136dd462c       397MB
docker.io/lab/pricing                           latest               26d5d5e0d77be       9.41MB
docker.io/lab/replenish                         latest               4fdc9f71ef99b       182MB
docker.io/lab/storefront                        latest               0a6c2117f27b0       55.7MB
```

Y con Docker, la misma tarea corre `kind load docker-image`:

```text
$ time task images:load -- minimo
task: [images:load] kind load docker-image lab/pricing --name minimo
using docker due to KIND_EXPERIMENTAL_PROVIDER
Image: "lab/pricing" with ID "sha256:686e1a36…" not yet present on node "minimo-control-plane", loading...
…
real	0m17.702s
$ docker exec minimo-control-plane crictl images | grep -E "IMAGE|lab/"
docker.io/lab/catalog                           latest               cd443347a3f3e       43.6MB
docker.io/lab/inventory                         latest               aca6f078dce33       136MB
docker.io/lab/pricing                           latest               4abb5ea99f8db       3.43MB
…
```

Las cinco quedan en el nodo como `docker.io/lab/<svc>` con los dos motores (los tamaños de `crictl`
difieren porque cada carga los cuenta distinto; para comparar vale la columna "viaja" de B-04). La
[Fase 08](08-el-primer-despliegue.md) usa esta tarea sin pensar en qué motor está activo.

> 🩻 **Esto sí funciona igual.** Los Dockerfile de la [Fase 04](04-empaquetar-los-cuatro-runtimes.md) construyen sin cambios con los dos, el
> mismo `compose.yaml` levanta el sistema con los dos ([Fase 02](02-compose-el-sistema-en-un-archivo.md)), los clusters de kind son los mismos
> archivos, y las imágenes pasan de uno a otro porque son OCI ([Fase 03](03-el-contenedor-por-dentro.md)). Lo que diverge es la
> plomería alrededor, no el contenedor.

**El patrón a memorizar.** Cuando un comando del ecosistema dice "docker" en su nombre, pregúntate
si le habla al motor de Docker o al formato. `kind load docker-image` le habla al motor; `kind load
image-archive`, al formato, y por eso sirve con los dos.

---

## 🔁 6. Los otros tres: donde no es mecánico

Aquí no hay diferencias por runtime: las cinco imágenes se cargan, corren y publican igual con los
dos motores. La única es de tiempo, y está en B-05: el build en frío de `pricing` se duplica con
Podman; el de `inventory`, casi no cambia.

---

## 🪞 7. Tu instinto de compose dice… y la apuesta

El instinto, en su mejor versión: *"Podman es Docker sin demonio: los mismos comandos, las mismas
imágenes. Si funciona en uno, funciona en el otro, y con la misma memoria cuesta lo mismo."* La
primera mitad es casi toda verdad, y las secciones 5.1 a 5.5 dicen dónde no. La segunda es la que
B-05 tenía que medir:

> 🪞 **Apuesta antes de ejecutar.** Con las dos máquinas virtuales en 4 GiB, los dos motores empatan
> en memoria en reposo (dentro de la dispersión); Podman crea el cluster `minimo` más de un 20 % más
> lento que Docker; y el build en frío de `pricing` queda dentro de un 15 % entre los dos.
>
> **Resultado: perdida en las tres.** En reposo no empatan: recién arrancados, la máquina virtual de
> Podman ocupa un 19 % más en el host, pero los demás procesos de Docker Desktop suman 3.184 MB contra
> 38 de Podman. El cluster tardó con Podman un 12 % más, no un 20. Y el build en frío de `pricing` con
> Podman tardó más del doble (11,1 s contra 5,2), mientras el de `inventory` quedó dentro de un 6 %.

Lo que la apuesta perdida enseña: **"el mismo motor con otro nombre" falla justo donde el motor no es
el contenedor**. Lo que corre adentro empata; lo que lo rodea —la interfaz, la máquina virtual, el
constructor de imágenes— es distinto, y cuesta distinto.

---

## 📏 8. La medición: B-05

> 📏 **Medición B-05 · Los dos motores** · cluster `minimo` · Docker Desktop 4.92.0 (Engine 29.8.0) y
> Podman 6.1.3 (máquina con libkrun), las dos máquinas virtuales en 4 GiB, **un motor encendido a la
> vez** · kind 0.33.0, nodo 1.36.4 · MacBook Pro M1 Pro, 32 GB, macOS arm64 · 5 corridas; la huella,
> 5 lecturas cada 10 s · verificado el 03/10/2026
>
> | | Docker | Podman |
> |---|---|---|
> | crear el cluster `minimo` (s) | 25,8 (25,1–26,7) | 29,0 (28,7–29,6) |
> | build en frío de `pricing` (s) | 5,2 (5,2–6,5) | 11,1 (11,1–11,9) |
> | build en frío de `inventory` (s) | 93,2 (91,9–96,4) | 99,1 (93,6–102,1) |
> | host, recién arrancado: máquina virtual (MB) | 1.244 (1.244–1.246) | 1.479 (1.479–1.479) |
> | host, recién arrancado: los demás procesos (MB) | 3.184 (2.564–3.200) | 38 (37–38) |
> | host, después de trabajar: máquina virtual (MB) | 4.145 (4.145–4.145) | 7.369 (7.247–7.369) |
> | host, después de trabajar: los demás procesos (MB) | 415 (402–429) | 48 (48–48) |
>
> Mediana, con mínimo y máximo. La huella es el `phys_footprint` de macOS (lo que muestra el Monitor
> de Actividad como memoria), tras 60 s de reposo. *Después de trabajar*: tras las quince
> creaciones y builds de la medición. Reproducir, con el motor que se mide como activo y el otro
> apagado: `task measure -- B-05`

**Lo que dice, en proporciones.** Crear el cluster cuesta un 12 % más con Podman: casi un empate en
algo que se hace una vez al día. El build en frío de una imagen pequeña cuesta el doble con Podman, y
el de una grande, un 6 % más: el constructor de Podman paga un costo fijo por build que en `pricing`
pesa y en `inventory` se diluye. **Docker gana en tiempo de build y de cluster; Podman gana, por
mucho, en lo que corre alrededor de la máquina virtual**: 38 MB contra 3.184 recién arrancado.

**La memoria, con dos advertencias.** La primera: los 3.184 MB de Docker recién arrancado son casi
todos de un proceso, `com.docker.backend`; al final de la medición, todos juntos sumaban 415, y no
averigüé qué hace ese proceso al arrancar. La segunda, más importante: **una máquina virtual que trabajó no le
devuelve la memoria al host**. La de Docker quedó en 4.145 MB, su asignación entera. La de Podman
midió 7.369 MB a los 60 segundos, más que los 4 GiB que tiene asignados, y unos minutos después
`footprint` la daba en 3.110 MB: cómo cuenta macOS la memoria de cada hipervisor no es comparable
entre los dos, y no lo fuerzo a parecerlo. Lo que sí se sostiene: **después de un build o un
cluster, cuenta con que la asignación entera de la máquina virtual está ocupada en tu portátil**, y
por eso [a01](a01-el-laboratorio.md#-la-memoria-que-ocupa-cada-perfil) dimensiona con 4 GiB.

> ⚠️ **No sumes las dos columnas.** Cada motor se midió con el otro apagado, que es como recomienda
> trabajar el curso (sección 9).

---

## ⚰️ 9. Autopsia: los dos motores encendidos, por si acaso

**La decisión, con su mejor argumento.** Dejar Docker y Podman encendidos todo el día: *"así pruebo
en los dos sin esperar a que arranque ninguno, y si uno falla, sigo con el otro."*

**Por qué era razonable.** Los dos conviven sin conflicto en la instalación ([Fase 00](00-el-ambiente.md)), y arrancar una
máquina virtual cuesta medio minuto que uno no quiere esperar cada vez.

**Qué pasa después, con número.** Dos máquinas virtuales de 4 GiB ocupan, después de trabajar, las
dos asignaciones enteras en el host (sección 8): 8 GiB de un portátil de 16 se van en motores. Y el
día que alguien levanta un cluster con cada uno, el segundo no arranca, porque los dos quieren el
8080 del host:

```text
Command Output: Error: something went wrong with the request: "listen tcp 127.0.0.1:8080: bind: address already in use\n"
```

Es el mismo error de la [Fase 00](00-el-ambiente.md), y el mensaje no dice cuál de los dos motores
tiene el puerto.

**Cuánto cuesta salir, con número.** Un comando: `task engine:use -- <motor>` activa uno y avisa si
el otro sigue encendido; `task engine:stop -- <motor>` lo apaga. Cambiar de motor cuesta lo que
tarde en arrancar la máquina virtual del otro.

**Qué lo habría cambiado.** Una pregunta antes de abrir el portátil: *¿con qué motor voy a trabajar
hoy?* `task engine:status` la contesta.

**Antes y después, con números:** con los dos encendidos y trabajando, hasta dos asignaciones
completas de 4 GiB en el host y el puerto 8080 en disputa; con uno, una asignación y ningún choque.

---

## 📖 10. Traducción

| En Docker | En Podman | Lo que cambia |
|---|---|---|
| `dockerd` y `containerd` como `root` | un `conmon` por contenedor, como tu usuario | no hay servicio central que pueda caerse con todos los contenedores |
| `-p 127.0.0.1:80:…` funciona (Docker Desktop) | `permission denied` en macOS | el laboratorio usa 8080 y 8443 con los dos |
| imagen local `lab/pricing` | `localhost/lab/pricing`, salvo que la nombres | el curso construye `docker.io/lab/<svc>` con Podman |
| `kind load docker-image` | `podman save` y `kind load image-archive` | `task images:load` elige por ti |
| `docker compose` | `podman compose`, que delega en otro programa | [Fase 02](02-compose-el-sistema-en-un-archivo.md) |

🌩️ En un cluster gestionado no hay ni uno ni otro: los nodos corren containerd o CRI-O, y tu
motor solo sirve para construir. Por eso el curso no elige "el motor de producción".

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

**Cuándo no te hacen falta los dos.** Si tu empresa ya paga Docker Desktop, o si trabajas en Linux
con Docker Engine, mantener Podman solo para este curso es una máquina virtual más que cuidar;
puedes saltarte los 🦭. Si no puedes pagar Docker Desktop, Podman alcanza para todo el laboratorio,
con el doble de tiempo en los builds de imágenes chicas y la plomería de la sección 5 resuelta en el
Taskfile.

Y una pérdida que conviene decir en voz alta: **trabajar con dos motores cuesta atención**. Cada
divergencia de la sección 5 es un error que el otro motor no da, y que alguien del equipo va a
encontrar sin haber leído esta fase.

**La pregunta del curso, para esta fase:** el contenedor te dio un formato que los dos motores
corren igual. El orquestador, todavía nada. **Te tocó a ti** la plomería: con qué nombre se
construye, cómo llega la imagen al cluster, qué puerto se puede publicar y cuántas máquinas
virtuales caben en tu portátil.

---

## ⚠️ 13. Errores comunes y diagnóstico

**kind busca Docker con Docker apagado.** Síntoma: `failed to get docker info`. Causa: kind usa
Docker si no le dices otra cosa. Comprobación 🩺: `echo $KIND_EXPERIMENTAL_PROVIDER`. Salida: usar
las tareas del Taskfile, que la fijan.

**`not present locally` con la imagen construida.** Síntoma: `kind load docker-image` falla con
Podman. Causa: le pregunta al motor de Docker. Salida: `task images:load`.

**`permission denied` al publicar el 80 o el 443 con Podman.** Causa: el proceso que publica es tuyo.
Salida: 8080 y 8443, como el resto del laboratorio.

**El cluster de Podman no revive tras reiniciar la máquina.** Síntoma: el nodo queda `Exited` y la
API rechaza conexiones. Es una diferencia conocida con Docker, que sí lo revive; está en
[a02](a02-problemas-del-ambiente.md).

---

## 📋 14. Checklist de validación

```text
[ ] ves dockerd y containerd en la VM de Docker, y conmon por contenedor en la de Podman
[ ] podman info dice rootless true, y publicar el 80 con Podman falla con permission denied
[ ] kind sin KIND_EXPERIMENTAL_PROVIDER falla con Docker apagado, y sabes por qué
[ ] task images:load -- minimo carga las cinco imágenes con los dos motores
[ ] crictl images en el nodo muestra docker.io/lab/<svc> con cualquiera de los dos
[ ] sabes leer B-05 y decir en qué gana cada motor
```

---

## 🧪 15. Ejercicios (12)

La medición es opcional de ejecutar: si tienes un solo motor, los ejercicios que piden los dos se
hacen con la tabla publicada.

## 🟢 Fácil — los dos lados (1–4)

### 🟢 Ejercicio 1 — ¿Quién cuida a `pricing`?
Con tu motor, muestra el proceso padre de `pricing` en la máquina virtual.

**Criterio:** el padre es `containerd-shim-runc-v2` (Docker) o `conmon` (Podman).

<details><summary>Solución</summary>

Docker: `docker run --rm --pid=host lab/replenish ps -o pid,ppid,user,args`. Podman: `podman machine
ssh -- ps -eo pid,ppid,user,args`. En Linux, sin máquina virtual, `ps` en el host (no verificado por
el autor; se confirma al hacer el curso).
</details>

### 🟢 Ejercicio 2 — *Rootless* o no
Averigua si tu motor corre sin root.

**Criterio:** la salida de `podman info --format '{{.Host.Security.Rootless}}'` o la de `docker info
--format '{{.SecurityOptions}}'`, y una frase que la interprete.

<details><summary>Solución</summary>

Los comandos del criterio. Si en Docker aparece `name=rootless`, estás en el modo sin root de Docker
Engine, que el curso no usa.
</details>

### 🟢 Ejercicio 3 — Las cinco en el nodo
Carga las cinco imágenes en el cluster `minimo`.

**Criterio:** `crictl images` en el nodo lista las cinco como `docker.io/lab/<svc>`.

<details><summary>Solución</summary>

`task build:all`, `task cluster:up -- minimo`, `task images:load -- minimo` y `<motor> exec
minimo-control-plane crictl images | grep lab/`. Al terminar, `task cluster:down -- minimo`.
</details>

### 🟢 Ejercicio 4 — El 80
Intenta publicar `pricing` en el 80 de `127.0.0.1` con tu motor.

**Criterio:** el `200` o el `permission denied` literal.

<details><summary>Solución</summary>

`<motor> run -d --name pricing80 -p 127.0.0.1:80:8080 <imagen de pricing>`, y bórralo después.
</details>

## 🟡 Intermedio — la plomería (5–8)

### 🟡 Ejercicio 5 — Sin la tarea
Carga `inventory` en el cluster con Podman sin usar `task images:load`.

**Criterio:** los dos comandos, y `inventory` en `crictl images`.

<details><summary>Solución</summary>

`podman save -o inventory.tar docker.io/lab/inventory` y `KIND_EXPERIMENTAL_PROVIDER=podman kind load
image-archive inventory.tar --name minimo`. En PowerShell, `$env:KIND_EXPERIMENTAL_PROVIDER="podman"`
antes (no verificado por el autor; se confirma al hacer el curso).
</details>

### 🟡 Ejercicio 6 — El nombre que no llega
Construye `pricing` con Podman **sin** `docker.io/` delante, cárgalo con `image-archive` y mira cómo
queda en el nodo.

**Criterio:** `crictl images` muestra `localhost/lab/pricing`, y una frase sobre qué buscaría un pod
que pide `lab/pricing`.

<details><summary>Solución</summary>

`podman build -t lab/pricing services/pricing`, `podman save` y `kind load image-archive`. El pod
buscaría `docker.io/lab/pricing`, que no es esa: la [Fase 08](08-el-primer-despliegue.md) lo ve como un error de descarga.
</details>

### 🟡 Ejercicio 7 — Cambiar de motor bien
Pasa del motor que tengas activo al otro y deja el primero apagado.

**Criterio:** `task engine:status` muestra un solo motor que responde, y es el nuevo.

<details><summary>Solución</summary>

`task engine:stop -- <actual>` y `task engine:use -- <otro>`. Si `engine:use` avisa que el otro
sigue encendido, no lo apagaste.
</details>

### 🟡 Ejercicio 8 — Tu fila de B-05
Corre B-05 con tu motor (una corrida basta para empezar).

**Criterio:** `task measure -- B-05 --runs 1` imprime su resumen, y el crudo queda en
`bench/b05/results/`.

<details><summary>Solución</summary>

El comando del criterio, con el otro motor apagado. En Windows y Linux la huella del host no se mide
(es de macOS); el resto, sí.
</details>

## 🟠 Difícil — medir y explicar (9–11)

### 🟠 Ejercicio 9 — El build que se duplica
Averigua dónde se van los seis segundos de más del build en frío de `pricing` con Podman. **Predice**
antes en qué paso.

**Criterio:** la duración de cada paso con los dos motores (`--progress=plain` en Docker; la salida
normal de `podman build`).

**Rúbrica:** la predicción; los tiempos por paso; y una conclusión honesta, aunque sea "es el costo
fijo de escribir capas".

### 🟠 Ejercicio 10 — La memoria que no vuelve
Mide la huella de la máquina virtual de tu motor recién arrancado, después de un build de
`inventory`, y media hora más tarde. **Predice** si baja sola.

**Criterio:** tres lecturas con su hora.

**Rúbrica:** las lecturas; la predicción contra el resultado; y qué harías en un portátil de 8 GB
(reiniciar el motor al terminar, o darle menos memoria y medir si alcanza).

### 🟠 Ejercicio 11 — `restart: always` sin demonio
Levanta `pricing` con `--restart always` en los dos motores, reinicia la máquina virtual de cada uno,
y mira qué contenedor vuelve. **Predice** antes.

**Criterio:** `ps` de cada motor después del reinicio.

**Rúbrica:** la predicción; el resultado; y por qué un motor sin demonio necesita a alguien más
(systemd) para cumplir esa política. La [Fase 06](06-del-compose-al-cluster.md) vuelve sobre esto.

## 🔴 Muy difícil — el puente (12)

### 🔴 Ejercicio 12 — 🔥 Del contenedor al manifiesto
Con Podman, genera el manifiesto de un `pricing` que corre (`podman kube generate`) y explica cada
campo que **no** usarías en un cluster.

**Criterio:** el YAML generado, y una lista de los campos que quitarías o cambiarías.

**Rúbrica:** al menos `hostPort` y `hostIP` (que atan el pod a un nodo y a un puerto), la etiqueta
`app: pricing-pod` en vez de las del contrato, y la ausencia de un `Deployment`: es un `Pod` suelto,
que nadie reemplaza si muere. Es el YAML que nadie despliega tal cual, y la [Fase 08](08-el-primer-despliegue.md) escribe el bueno.

---

## 📚 16. Referencias

**Documentación oficial** (sin versión fija)

- kind, *Quick Start*, la sección de cargar imágenes y la de proveedores:
  https://kind.sigs.k8s.io/docs/user/quick-start/ — `kind load docker-image` e `image-archive`.
- kind, *Rootless* y Podman: https://kind.sigs.k8s.io/docs/user/rootless/
- Podman, `podman machine`: https://docs.podman.io/en/latest/markdown/podman-machine.1.html
- Podman, la arquitectura sin demonio y `conmon`: https://github.com/containers/conmon
- Docker, *Docker Desktop license agreement*: https://docs.docker.com/subscription-billing/desktop-license/ —
  la condición de las 250 personas o los 10 millones de dólares.

**Orden de lectura sugerido:** antes, la página de la licencia (la razón de esta fase); durante, la
de kind; después, el `README` de `conmon`, que explica en una pantalla qué hace el proceso que en
Podman reemplaza al demonio.

> ⚠️ Las URL y los contenidos cambian, y ninguna de estas fija versión.

---

## 🏁 17. Resultado de la fase

```text
EL LABORATORIO AL CERRAR LA FASE 05

  motor activo (uno a la vez)        task engine:status · engine:use · engine:stop
  ├── Docker  dockerd + containerd (root en su VM)    build rápido · 3,2 GB de procesos al arrancar
  └── Podman  conmon por contenedor (sin root)        build de imágenes chicas, el doble · 38 MB alrededor
          │
          ▼ task images:load -- minimo
  cluster minimo (kind)  →  docker.io/lab/{pricing,inventory,catalog,replenish,storefront}
```

> **La señal de que quedó bien:** *"Cambio de motor con un comando, cargo las imágenes al cluster con
> otro, y sé decir en qué gana cada uno con un número."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde y `git status` limpio:
>
> ```bash
> git tag -a fase-05-los-dos-motores -m "F05 cerrada: task images:load con los dos motores; imágenes docker.io/lab/<svc> en el nodo; task measure -- B-05 con sus crudos"
> ```
>
> Commits de la fase con prefijo `f05:`, los de ejercicio `f05 ej09: …` ([convención de git](00-convencion-de-git-y-tags.md)).

---

## 📌 Pendientes sugeridos

- **F08:** usar `task images:load` y agregar la imagen de nginx de `catalog` a la carga cuando entre
  el pod de dos contenedores (F09).
