# ☸️ Fase 07 — El cluster local: dos clusters de kind, sus contextos, y por qué no hace falta otro

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 07 de 27 · Parte II — El despliegue · **media**
> **Perfil:** `minimo` y `lab` (los dos se levantan, de a uno) · `medicion` para 📏 · **Observabilidad encendida:** ninguna
> **Motor de referencia:** Docker · 🦭 kind corre igual sobre Podman; k3d no arrancó y minikube no da tres nodos
> **Servicios que toca:** ninguno: el primer despliegue es la [Fase 08](08-el-primer-despliegue.md) · **Paso de generación:** ninguno
> **Depende de:** Fase 06 · **Habilita:** [Fase 08](08-el-primer-despliegue.md)
> **Incidentes que reserva:** ninguno · **Medición:** B-07
> **Apéndices de apoyo:** [a01](a01-el-laboratorio.md), [a04](a04-kubectl-y-k9s.md), [a05](a05-diccionarios.md)
> **Fecha de verificación ejecutada:** 03/10/2026 · macOS arm64, con Docker y con Podman
> **Objetivo:** levantar los dos clusters del curso desde sus archivos, leer qué corre en cada nodo, no equivocarse nunca de cluster, y saber con B-07 por qué kind es el cluster del curso.

---

## 🧭 1. Dónde estamos

La Parte I terminó con una promesa: lo que compose no da —reemplazar lo que muere, esperar a lo
listo, repartir, nombrar— lo da un bucle de reconciliación, y ese bucle vive en un cluster. La Parte
II empieza por el cluster mismo, antes de ponerle nada encima.

La Rebotica arrancó con tres portátiles y un presupuesto de cero para infraestructura (historia
§5.3): Paracelso se aprobó con plata para el equipo y sin plata para nube. Valentina tenía que
elegir un Kubernetes que cupiera en un portátil, que funcionara con los dos motores ([Fase 05](05-los-dos-motores.md)), y
que el equipo de la Braqui, en Mac, y el Núcleo, en Windows, pudieran levantar igual. La lista
corta tenía cuatro nombres, y Germán le pidió lo de siempre:

> *"No me diga cuál le gusta, Valentina. Dígame cuál, por qué, y con qué número."*

Esta fase responde con B-07 y con los dos clusters del curso, que ya existen desde
[a01](a01-el-laboratorio.md#️-el-taskfile-tarea-por-tarea) y que aquí se miran por dentro: el de un
nodo del perfil `minimo`, que es el de todos los días, y el de tres nodos del perfil `lab`, que se
levanta, se mira y se apaga hasta la [Fase 16](16-escalado-y-rollout.md).

---

## 🎯 2. Objetivos de esta fase

1. Levantar `minimo` y `lab` desde sus archivos de kind, y explicar cada decisión de esos archivos.
2. Leer qué corre en cada nodo de `lab` y por qué un nodo alcanza para casi todo el curso.
3. Saber en qué cluster estás antes de cada comando, y provocar el error de no saberlo.
4. Medir con B-07 kind, k3d, minikube y el Kubernetes de Docker Desktop, y archivar la comparación.
5. Explicar por qué `curl localhost:8080` todavía no llega a nada.

---

## 🚫 3. Qué NO entra todavía

- Desplegar algo → [Fase 08](08-el-primer-despliegue.md).
- Los `Service` y la entrada desde el host → Fases 08 y 10.
- El reparto de réplicas entre nodos → [Fase 16](16-escalado-y-rollout.md).
- Administrar el cluster (actualizar versiones, certificados del plano de control): fuera del curso.

---

## 🧨 4. El problema, en el laboratorio

El primer impulso con dos perfiles es tenerlos los dos encendidos. Con `minimo` arriba:

```text
$ task cluster:up -- lab
task: [cluster:up] kind create cluster --config kind/cluster-lab.yaml
using docker due to KIND_EXPERIMENTAL_PROVIDER
Creating cluster "lab" ...
 ✗ Preparing nodes 📦 📦 📦
Deleted nodes: ["lab-control-plane" "lab-worker2" "lab-worker"]
ERROR: failed to create cluster: command "docker run --name lab-control-plane …" failed with error: exit status 125
…
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint lab-control-plane (58b9f892…): Bind for 127.0.0.1:8080 failed: port is already allocated
```

Los dos clusters publican el mismo puerto del host, `127.0.0.1:8080`, porque es la puerta del
`Gateway` de la [Fase 10](10-la-entrada-al-sistema.md) y el curso la quiere en el mismo sitio sin importar el perfil. **Los dos
clusters del curso no conviven: se usa uno a la vez.** Bajé `minimo` y `lab` subió en 30 segundos.

El segundo problema es más silencioso. Con `lab` recién creado, y la intención de preparar `minimo`:

```text
$ kubectl config current-context
kind-lab
$ kubectl create namespace apps
namespace/apps created
```

Ningún error. El namespace quedó en el cluster equivocado, y nada lo dice. Y el tercero, el más
raro: al borrar el cluster que estaba activo, `kubectl` se queda sin contexto y, sin que nadie se lo
pida, le habla a un servidor por defecto:

```text
$ task cluster:down -- lab
Deleted nodes: ["lab-control-plane" "lab-worker2" "lab-worker"]
$ kubectl config current-context
error: current-context is not set
$ kubectl get nodes
E1003 20:14:24.289012   45934 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"http://localhost:8080/api?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused"
…
The connection to the server localhost:8080 was refused - did you specify the right host or port?
```

`localhost:8080` es, en este laboratorio, la puerta del `Gateway`. Con un cluster arriba, un `kubectl`
sin contexto le estaría hablando a otra cosa. Las tres situaciones tienen la misma raíz: **con más de
un cluster en la máquina, la pregunta "¿dónde estoy?" va antes de cualquier comando.**

---

## ☸️ 5. Los dos clusters del curso

### 5.1 Un nodo de kind es un contenedor

```text
$ docker ps --format '{{.Names}}  {{.Image}}  {{.Ports}}' --filter label=io.x-k8s.kind.cluster
minimo-control-plane  099e049362a1  127.0.0.1:51281->6443/tcp, 127.0.0.1:8080->30080/tcp, 127.0.0.1:8443->30443/tcp
```

Kubernetes **in** Docker: cada nodo es un contenedor del motor que corre adentro un `kubelet`, un
`containerd` y, en el control-plane, la API y los controladores. Los pods que vas a crear son
contenedores dentro de ese contenedor. Es la [Fase 03](03-el-contenedor-por-dentro.md) aplicada dos veces, y explica las tres cosas que
el resto de la Parte II da por sabidas: el nodo no ve las imágenes de tu motor ([Fase 05](05-los-dos-motores.md)), un puerto
del pod no está en tu máquina, y `localhost` dentro del nodo no es `localhost` en tu Mac.

### 5.2 Los archivos, campo por campo

`kind/cluster-minimo.yaml` tiene tres decisiones, las tres con su porqué en el comentario:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: minimo
# Activa la carpeta de configuración de registries de containerd. No cambia nada hasta la Fase 19,
# y ponerla desde el principio evita recrear el cluster cuando llegue el registry con CA propia.
containerdConfigPatches:
  - |-
    [plugins."io.containerd.grpc.v1.cri".registry]
      config_path = "/etc/containerd/certs.d"
nodes:
  - role: control-plane
    # kindest/node:v1.36.4 — la última que soporta el controlador de Gateway del curso (a01).
    image: kindest/node@sha256:099e049362a1526b2db71494e1947aae99bd16290d7c895f2b7ea312e3cbfaed
    # La entrada al cluster: el host escucha solo en 127.0.0.1, en puertos sin privilegios
    # (Podman sin root no publica el 80 ni el 443), y los reenvía a dos NodePort fijos.
    extraPortMappings:
      - containerPort: 30080
        hostPort: 8080
        listenAddress: "127.0.0.1"
      # … y 30443 → 8443
```

El nodo va por digest, como cualquier imagen del curso. Los `extraPortMappings` son los que hacen
chocar a los dos clusters, y es un precio aceptado: la alternativa era un puerto distinto por perfil,
y que cada fase dijera "8080, o 8081 si estás en `lab`". `kind/cluster-lab.yaml` es el mismo archivo
con dos nodos más, `role: worker`, sin mapeos propios: el tráfico entra siempre por el control-plane.

### 5.3 Qué corre en cada nodo

```text
$ time task cluster:up -- lab
…
node/lab-control-plane condition met
node/lab-worker condition met
node/lab-worker2 condition met
real	0m30.200s
$ kubectl --context kind-lab get nodes -o wide
NAME                STATUS   ROLES           AGE   VERSION   INTERNAL-IP   …   KERNEL-VERSION            CONTAINER-RUNTIME
lab-control-plane   Ready    control-plane   23s   v1.36.4   192.168.0.5   …   7.0.12-linuxkit (arm64)   containerd://2.3.4
lab-worker          Ready    <none>          13s   v1.36.4   192.168.0.7   …   7.0.12-linuxkit (arm64)   containerd://2.3.4
lab-worker2         Ready    <none>          13s   v1.36.4   192.168.0.6   …   7.0.12-linuxkit (arm64)   containerd://2.3.4
$ kubectl --context kind-lab get pods -A -o wide
NAMESPACE            NAME                                        READY   STATUS    …   NODE
kube-system          coredns-589f44dc88-799nq                    1/1     Running   …   lab-control-plane
kube-system          coredns-589f44dc88-kbhcs                    1/1     Running   …   lab-control-plane
kube-system          etcd-lab-control-plane                      1/1     Running   …   lab-control-plane
kube-system          kindnet-b9xph                               1/1     Running   …   lab-worker
kube-system          kindnet-jmdn2                               1/1     Running   …   lab-worker2
kube-system          kindnet-wfsbn                               1/1     Running   …   lab-control-plane
kube-system          kube-apiserver-lab-control-plane            1/1     Running   …   lab-control-plane
kube-system          kube-controller-manager-lab-control-plane   1/1     Running   …   lab-control-plane
kube-system          kube-proxy-7dzrk                            1/1     Running   …   lab-worker
kube-system          kube-proxy-lm59c                            1/1     Running   …   lab-worker2
kube-system          kube-proxy-x446b                            1/1     Running   …   lab-control-plane
kube-system          kube-scheduler-lab-control-plane            1/1     Running   …   lab-control-plane
local-path-storage   local-path-provisioner-56c4685b7c-q8tdd     1/1     Running   …   lab-control-plane
```

El **control-plane** lleva el cerebro: `etcd` (donde se guarda el estado deseado), la API, el
planificador y los controladores del bucle de la [Fase 06](06-del-compose-al-cluster.md). Los **workers** llevan solo lo que todo nodo
necesita para recibir pods: `kindnet` (la red entre pods) y `kube-proxy` (los `Service`, [Fase 08](08-el-primer-despliegue.md)).
El mismo kernel en los tres (`7.0.12-linuxkit`): son tres contenedores en la misma máquina virtual.

**Un nodo alcanza para casi todo el curso**, y no por ahorro. Lo que enseña un cluster —el bucle,
los `Service`, la configuración, el estado, las sondas— funciona igual con un nodo. Lo que necesita
más de uno es poco y tiene fecha: repartir réplicas entre nodos ([Fase 16](16-escalado-y-rollout.md)), un `DaemonSet` que corre
uno por nodo ([Fase 18](18-logs.md)), y la rotura del `Gateway` cuando su proxy cae en un worker ([Fase 10](10-la-entrada-al-sistema.md)). En
reposo, `lab` le suma a la máquina virtual unos 170 MiB respecto de `minimo` ([B-00 en a01](a01-el-laboratorio.md#-la-memoria-que-ocupa-cada-perfil)):
poco, pero suficiente para no llevarlo encendido cuando no hace falta.

### 5.4 Contextos: no equivocarse de cluster

`kubectl` le habla al cluster de un **contexto**: una entrada de `~/.kube/config` con la dirección
del servidor, el usuario y, opcionalmente, un namespace. kind crea uno por cluster y lo deja activo:

```text
$ kubectl config get-contexts
CURRENT   NAME             CLUSTER          AUTHINFO         NAMESPACE
          docker-desktop   docker-desktop   docker-desktop
*         kind-lab         kind-lab         kind-lab
```

La higiene que el curso usa, y que sostiene el Taskfile: **ningún comando del laboratorio depende del
contexto activo.** Las tareas pasan `--context kind-<perfil>` en cada llamada, y los ejemplos de las
fases dicen el contexto cuando importa. El contexto activo sirve para escribir menos en la terminal;
no es una forma de decidir dónde se aplica algo. Los comandos para mirar, cambiar y fijar el
namespace de un contexto están en [a04](a04-kubectl-y-k9s.md#-en-qué-cluster-y-en-qué-namespace-estoy).

### 5.5 Y `localhost:8080`, que todavía no llega a nada

Con `minimo` arriba, el puerto ya está publicado:

```text
$ curl -sS -m 5 http://127.0.0.1:8080/
curl: (52) Empty reply from server
```

El host reenvía al `NodePort` 30080 del nodo, y en el nodo nadie escucha todavía. *"Empty reply"* no
es *"connection refused"*: la conexión llegó al contenedor del nodo y se cerró sin respuesta. Quién
escucha en ese puerto, y por qué la dirección de un pod nunca llega a tu navegador, es la [Fase 10](10-la-entrada-al-sistema.md).

> 🩻 **Esto sí funciona igual.** Un cluster de kind habla la misma API que uno gestionado: los
> manifiestos de la [Fase 08](08-el-primer-despliegue.md) aplican sin cambios en cualquier Kubernetes de la misma versión.

**Prueba de fuego.** `task cluster:up -- minimo`, `kubectl --context kind-minimo get nodes` con un
nodo `Ready`, y `curl -sS http://127.0.0.1:8080/` con `Empty reply from server`.

**El patrón a memorizar.** Un nodo de kind es un contenedor; un cluster es un contexto; y ningún
comando del laboratorio confía en el contexto activo.

---

## 🔁 6. Los otros clusters: donde no es mecánico

kind no es el único Kubernetes que cabe en un portátil, y esta es la única fase que mira los otros
tres. Instalarlos es opcional, y solo para esta fase; las versiones están en
[a01](a01-el-laboratorio.md#-versiones-fijadas), marcadas "solo F07":

```bash
brew install k3d minikube        # macOS; el Kubernetes de Docker Desktop viene con Docker Desktop
```

En la máquina del autor ya estaban instalados cuando se escribió esta fase, así que esa línea no se
ejecutó en la verificación; en Windows 11 y en Linux, los instaladores de cada proyecto. Las dos cosas:
no verificado por el autor; se confirma al hacer el curso.

- **k3d** levanta k3s, una distribución liviana, en contenedores. Es el más rápido en arrancar, y
  trae cosas de serie que el curso no quiere: un controlador de entrada (Traefik, instalado por un
  `Job` de Helm), su balanceador (`svclb-traefik`), metrics-server, y dos contenedores propios fuera
  del nodo (`k3d-b07-serverlb` y `k3d-b07-tools`). Su Kubernetes es otro: v1.35.5+k3s1.
- **minikube** con el driver de Docker o de Podman: un nodo por contenedor, como kind, y su versión
  de Kubernetes por defecto es la v1.37.0, una más nueva que la del curso.
- **El Kubernetes de Docker Desktop** se enciende en la configuración de Docker Desktop (en esta
  versión, en modo kind, con la v1.36.1). Dos sorpresas medidas: **deshabilitarlo no lo apaga** —el
  nodo siguió respondiendo `Ready` dos minutos después de quedar `State: disabled`—, y `reset-cluster`
  con Kubernetes habilitado no lo borra: lo recrea. Para apagarlo de verdad hay que deshabilitarlo y
  después borrarlo.

> 🦭 **Con Podman, solo kind pasó entero.** k3d no arrancó: *"Node k3d-b07-server-0 failed to get
> ready: error waiting for log line `k3s is up and running` … context deadline exceeded"*. minikube
> levantó un nodo, pero no tres: los workers no alcanzaron al control-plane (*"dial tcp
> 192.168.49.2:8443: connect: no route to host"*). El de Docker Desktop no existe sin Docker Desktop.

---

## 🪞 7. Tu instinto dice… y la apuesta

El instinto, en su mejor versión: *"un Kubernetes local es un Kubernetes local; kind, k3d o
minikube son lo mismo con otro nombre, y elijo el que arranque más rápido."* Es casi verdad para la
API, y falso para todo lo demás: cada uno trae otra versión, otros componentes de serie y otra
compatibilidad con Podman.

> ⚠️ **Esta vez, la apuesta no se escribió antes de medir.** B-07 se corrió antes de dejar escrita su
> hipótesis, y la regla del curso es que una apuesta escrita después no vale. No la invento ahora.
> Lo que sigue es una apuesta sobre un experimento que todavía no había corrido cuando la escribí:
> qué pasa con k3d si se le apaga lo que trae de serie.

> 🪞 **Apuesta antes de ejecutar.** k3d trae de serie un controlador de entrada (Traefik) y un
> balanceador propio. Creado con Traefik apagado (`--k3s-arg "--disable=traefik@server:0"`), su
> memoria en reposo baja más de 100 MiB respecto de los 681 MiB medidos en B-07, y queda por debajo de
> kind (651 MiB).
>
> **Resultado: ganada.** Tres corridas: 478, 366 y 463 MiB, mediana 463, contra 681 con Traefik y
> 651 de kind. Y sigue arrancando en 17 segundos.

Lo que enseña: **comparar clusters con su configuración de fábrica compara sus fábricas.** k3d sin
lo que trae de serie es más liviano que kind; con todo, más pesado. La comparación justa es la que
deja a cada uno con lo mismo encima, y eso B-07 no lo hizo para minikube ni para Docker Desktop.

---

## 📏 8. La medición: B-07

> 📏 **Medición B-07 · Los clusters locales** · un nodo, sin nada desplegado · Docker Desktop 4.92.0
> (Engine 29.8.0) y Podman 6.1.3, máquinas virtuales de 4 GiB · MacBook Pro M1 Pro, 32 GB, macOS
> arm64 · 3 corridas, con las imágenes de cada herramienta ya descargadas · verificado el 03/10/2026
>
> | | Kubernetes | un nodo listo | memoria del cluster | tres nodos |
> |---|---|---|---|---|
> | kind, Docker | 1.36.4 | 26 s (26–27) | 651 MiB (632–668) | ✅ 36,2 s |
> | kind, Podman | 1.36.4 | 30 s (29–30) | 507 MiB (403–547) | ✅ 34,9 s |
> | k3d, Docker | 1.35.5+k3s1 | 17 s (17–17) | 681 MiB (655–697) | ✅ 29,3 s |
> | k3d, Podman | — | no arrancó | — | — |
> | minikube, Docker | 1.37.0 | 39 s (38–40) | 498 MiB (494–536) | ✅ 60,7 s |
> | minikube, Podman | 1.37.0 | 36 s (35–36) | 504 MiB (496–520) | ❌ los workers no se unen |
> | Docker Desktop (modo kind) | 1.36.1 | 35 s (35–36)* | ≈ 750 MiB** | no medido |
>
> *Memoria del cluster*: lo que sube la memoria usada de la máquina virtual (`MemTotal −
> MemAvailable`) con el cluster en reposo 60 s, contra la misma máquina sin él. \* Desde `docker
> desktop start` hasta el nodo listo; el motor solo tarda 6 s (5,6–6,9). \*\* Máquina virtual con
> Kubernetes 1.358 MiB (1.352–1.363) contra 608 (587–642) sin él. Reproducir: `task measure -- B-07
> --tool kind|k3d|minikube`; el de Docker Desktop, a mano, con el procedimiento de la sección 6.

**Lo que dice, en proporciones.** Ninguno gana en todo. k3d arranca en dos tercios de lo que tarda
kind, y minikube ocupa tres cuartos de su memoria, pero tarda una vez y media en arrancar y casi el
doble en dar tres nodos. Las diferencias de memoria están en el orden de lo que trae cada uno de
serie, como mostró la apuesta. **kind es el cluster del curso** por razones que la tabla muestra y
no por velocidad: es el único que corrió entero con los dos motores, corre la versión de Kubernetes
que el curso fija, no trae nada que el curso tenga que apagar, y su archivo de configuración versiona
los puertos y los registries. La comparación queda archivada aquí: ninguna otra fase vuelve a ella.

---

## ⚰️ 9. Autopsia: el comando sin contexto

**La decisión, con su mejor argumento.** Trabajar siempre con el contexto activo: *"tengo un solo
cluster a la vez, y escribir `--context` en cada comando es ruido."*

**Por qué era razonable.** Con un cluster, el contexto activo es siempre el correcto, y así lo
enseña casi toda la documentación.

**Qué pasa después, con número.** Con dos perfiles, `kind create cluster` cambia el contexto activo
y lo dice en una línea que nadie lee (`Set kubectl context to "kind-lab"`). El namespace `apps` quedó creado en `lab` en vez de en `minimo`: **un objeto en el cluster
equivocado, cero errores**. Y al borrar el cluster activo, `kubectl` le habló a `localhost:8080`, que
en este laboratorio es la puerta de entrada de otro sistema.

**Cuánto cuesta salir, con número.** Un borrado (`kubectl --context kind-lab delete namespace apps`) y
una costumbre: `--context` explícito en todo lo que modifica, que es lo que hace el Taskfile.

**Qué lo habría cambiado.** Leer el contexto antes de aplicar: `kubectl config current-context`, o un
indicador en el prompt de la terminal.

**Antes y después, con números:** con el contexto implícito, un namespace en el cluster equivocado y
ningún aviso; con `--context` explícito, el comando falla si ese cluster no existe (*"Error in
configuration: context was not found for specified context: kind-lab"*) en vez de aplicar en otro.

---

## 📖 10. Traducción

Lo que el laboratorio te da en tu portátil, y lo que es en un cluster gestionado. Las columnas de la
nube son descriptivas y **no están verificadas en el laboratorio** 🚧: este curso no despliega en una
nube de pago.

| En el laboratorio | En la nube (OCI, Azure) | 🚧 Lo que el laboratorio no da |
|---|---|---|
| un nodo es un contenedor de kind | un nodo es una máquina virtual | que un nodo se caiga de verdad, con su disco |
| el control-plane, en tu portátil | el plano de control lo administra el proveedor | actualizar el plano de control sin parar |
| `kind create cluster` y su archivo | la consola o la CLI del proveedor, o Terraform | redes, zonas y cuentas |
| el contexto `kind-minimo` | el contexto que genera la CLI del proveedor | identidades del proveedor en el `kubeconfig` |
| `extraPortMappings` al host | un balanceador del proveedor ([Fase 10](10-la-entrada-al-sistema.md)) | una IP pública |

Las filas de esta tabla inauguran el diccionario local ⇄ nube de [a05](a05-diccionarios.md#️-local--nube).

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

Si tienes Docker Desktop con su Kubernetes ya encendido, y un solo motor, no necesitas kind para
aprender lo de la Parte II: la API es la misma. Lo pierdes en otro sitio: la versión la elige Docker
Desktop, los puertos del host no se versionan, y apagarlo exige dos pasos. Si la memoria aprieta,
minikube es tres cuartos de kind; si la paciencia aprieta, k3d sin Traefik es el más liviano y el
más rápido de los medidos, con el costo de no correr sobre Podman en esta máquina.

Y el veredicto de fondo: **un cluster de kind en un portátil no es un cluster de producción**. No
prueba nada sobre redes reales, discos que fallan o nodos que desaparecen (🚧). Prueba la API, los
objetos y el bucle, que es lo que el curso necesita.

**La pregunta del curso, para esta fase:** el contenedor te dio los nodos (cada uno es uno). El
orquestador te dio el plano de control y el bucle, todavía sin nada que reconciliar. **Te tocó a ti**
decidir cuántos nodos, qué puertos llegan al host, y en qué cluster corre cada comando.

---

## ⚠️ 13. Errores comunes y diagnóstico

**`Bind for 127.0.0.1:8080 failed: port is already allocated` al crear un cluster.** Causa: el otro
perfil (o un cluster del otro motor, [Fase 00](00-el-ambiente.md)) ya publica ese puerto. Comprobación 🩺: `task
cluster:list` con cada motor. Salida: un cluster a la vez.

**`The connection to the server localhost:8080 was refused`.** Causa: no hay contexto activo y
`kubectl` usa su servidor por defecto. Comprobación 🩺: `kubectl config current-context`. Salida:
`--context kind-minimo`, o `kubectl config use-context kind-minimo`.

**El Kubernetes de Docker Desktop sigue vivo después de deshabilitarlo.** Comprobación 🩺:
`kubectl --context docker-desktop get nodes`. Salida: deshabilitarlo, y con el motor arriba, `docker
desktop kubernetes reset-cluster`.

**minikube con Podman no une los workers.** Síntoma: `kubeadm join … connect: no route to host`.
Salida: un nodo, o kind.

---

## 📋 14. Checklist de validación

```text
[ ] task cluster:up -- minimo: un nodo Ready, y docker ps lo muestra como contenedor
[ ] task cluster:up -- lab falla con minimo arriba, y funciona después de task cluster:down -- minimo
[ ] kubectl --context kind-lab get pods -A -o wide: sabes qué corre en el control-plane y qué en los workers
[ ] kubectl config get-contexts y current-context, y el namespace creado en el cluster equivocado, borrado
[ ] curl http://127.0.0.1:8080/ con minimo arriba: Empty reply from server
[ ] sabes leer B-07 y defender kind con tres razones de la tabla
```

---

## 🧪 15. Ejercicios (20)

Un tercio son de diagnóstico; el contexto equivocado aparece más de una vez a propósito.

## 🟢 Fácil — los clusters (1–6)

### 🟢 Ejercicio 1 — El nodo, desde el motor
Levanta `minimo` y muestra su nodo como contenedor.

**Criterio:** `docker ps --filter label=io.x-k8s.kind.cluster` (o `podman ps …`) lista
`minimo-control-plane` con `127.0.0.1:8080->30080/tcp`.

<details><summary>Solución</summary>

`task cluster:up -- minimo` y el comando del criterio.
</details>

### 🟢 Ejercicio 2 — Un comando dentro del nodo
Lista los contenedores que corren dentro del nodo de `minimo`.

**Criterio:** la salida de `crictl ps` dentro del nodo, con `kube-apiserver` y `etcd`.

<details><summary>Solución</summary>

`docker exec minimo-control-plane crictl ps`. Son contenedores dentro de un contenedor.
</details>

### 🟢 Ejercicio 3 — Los contextos
Muestra los contextos de tu máquina y cuál está activo.

**Criterio:** `kubectl config get-contexts` con un `*` en `kind-minimo`.

<details><summary>Solución</summary>

`kubectl config get-contexts` y `kubectl config current-context`.
</details>

### 🟢 Ejercicio 4 — Tres nodos
Levanta `lab` (con `minimo` abajo) y cuenta los pods por nodo.

**Criterio:** `kubectl --context kind-lab get pods -A -o wide` con pods en los tres nodos, y el
recuento por nodo.

<details><summary>Solución</summary>

`task cluster:down -- minimo`, `task cluster:up -- lab`, y `kubectl --context kind-lab get pods -A -o
wide --no-headers | awk '{print $8}' | sort | uniq -c`.
</details>

### 🟢 Ejercicio 5 — El choque
Intenta levantar `minimo` con `lab` arriba.

**Criterio:** el `port is already allocated` literal.

<details><summary>Solución</summary>

`task cluster:up -- minimo` con `lab` corriendo.
</details>

### 🟢 Ejercicio 6 — La puerta vacía
Con un cluster arriba, pide `http://127.0.0.1:8080/`.

**Criterio:** `Empty reply from server`, y una frase sobre por qué no es `connection refused`.

<details><summary>Solución</summary>

`curl -sS http://127.0.0.1:8080/`. La conexión llega al nodo, que no tiene a nadie en el 30080.
</details>

## 🟡 Intermedio — contextos y topología (7–12)

### 🟡 Ejercicio 7 — El namespace en el cluster equivocado
Provoca el error de la sección 4 y arréglalo sin borrar el cluster.

**Criterio:** el namespace aparece en `kind-lab` y desaparece; en `kind-minimo` está donde debe.

<details><summary>Solución</summary>

Con `lab` activo, `kubectl create namespace apps`; después, `kubectl --context kind-lab delete
namespace apps` y `kubectl --context kind-minimo create namespace apps`.
</details>

### 🟡 Ejercicio 8 — Un namespace por defecto en el contexto
Haz que el contexto `kind-minimo` use `apps` como namespace por defecto.

**Criterio:** `kubectl config get-contexts` muestra `apps` en la columna `NAMESPACE`.

<details><summary>Solución</summary>

`kubectl config set-context kind-minimo --namespace=apps`. Útil al escribir; el Taskfile no confía en
él.
</details>

### 🟡 Ejercicio 9 — Sin contexto
Borra el cluster activo y corre `kubectl get nodes`.

**Criterio:** el `localhost:8080 was refused` literal, y la explicación de a quién le estaría hablando
si hubiera otro cluster arriba.

<details><summary>Solución</summary>

`task cluster:down -- <perfil>` y `kubectl get nodes`. Con `minimo` arriba, `localhost:8080` es su
puerta de entrada, no su API.
</details>

### 🟡 Ejercicio 10 — Dónde está la API
Encuentra en qué puerto del host escucha la API de `minimo`.

**Criterio:** el puerto de `docker ps` que va a 6443 y el `server:` del contexto, iguales.

<details><summary>Solución</summary>

`docker ps --filter name=minimo-control-plane` y `kubectl config view --minify --context kind-minimo
-o jsonpath='{.clusters[0].cluster.server}'`.
</details>

### 🟡 Ejercicio 11 — El mismo cluster con Podman
Levanta `minimo` con Podman como motor activo.

**Criterio:** `task cluster:up -- minimo` pasa con Podman y `kubectl --context kind-minimo get
nodes` muestra el nodo `Ready`.

<details><summary>Solución</summary>

`task engine:stop -- docker`, `task engine:use -- podman` y `task cluster:up -- minimo`.
</details>

### 🟡 Ejercicio 12 — k3d, una vez
Crea un cluster de k3d y lista lo que trae de serie.

**Criterio:** la lista de pods de `kube-system`, con Traefik y metrics-server, y los contenedores
propios de k3d en el motor.

<details><summary>Solución</summary>

`k3d cluster create prueba --wait`, `kubectl --context k3d-prueba get pods -A` (espera al `Job` de
Traefik) y `docker ps | grep k3d`. Bórralo con `k3d cluster delete prueba`.
</details>

## 🟠 Difícil — medir y decidir (13–17)

### 🟠 Ejercicio 13 — Tu fila de B-07
Corre B-07 con kind en tu máquina. **Predice** antes cuánto tarda y cuánto ocupa.

**Criterio:** la predicción, y la salida de `task measure -- B-07 --tool kind --runs 3`.

**Rúbrica:** la predicción escrita antes; el resultado; y la proporción contra la tabla publicada.

### 🟠 Ejercicio 14 — minikube sin lo de serie
Mide minikube con sus complementos apagados y compáralo con la tabla.

**Criterio:** tres corridas de memoria en reposo, con el comando exacto.

**Rúbrica:** qué apagaste (`minikube addons list`); las mediciones; y si cambia la conclusión de la
sección 8.

### 🟠 Ejercicio 15 — El Kubernetes de Docker Desktop, apagado de verdad
Enciende el Kubernetes de Docker Desktop, deshabilítalo, y demuestra si sigue vivo.

**Criterio:** `kubectl --context docker-desktop get nodes` después de deshabilitarlo, y el
procedimiento que lo apaga de verdad.

**Rúbrica:** las salidas; el orden correcto (deshabilitar, con el motor arriba borrar); y la memoria
de la máquina virtual antes y después.

### 🟠 Ejercicio 16 — Un indicador en el prompt
Configura tu terminal para que muestre el contexto activo.

**Criterio:** una captura (o la salida) del prompt cambiando al cambiar de contexto.

**Rúbrica:** cómo lo hiciste (un script de tu shell o una herramienta) y por qué no reemplaza a
`--context` en los scripts.

### 🟠 Ejercicio 17 — ¿Dónde caen los pods?
En `lab`, crea un `Deployment` de tres réplicas de cualquier imagen del laboratorio y mira en qué nodo
cae cada una. **Predice** antes.

**Criterio:** la predicción y `kubectl get pods -o wide`.

**Rúbrica:** la predicción; el reparto real; y por qué el planificador no pone ninguna en el
control-plane (su *taint*). La [Fase 16](16-escalado-y-rollout.md) vuelve a esto.

## 🔴 Muy difícil — el laboratorio contra la nube (18–20)

### 🔴 Ejercicio 18 — Dos clusters a la vez
Modifica una copia del archivo de `lab` para que conviva con `minimo`.

**Criterio:** los dos clusters `Ready` a la vez.

**Rúbrica:** el cambio (otros puertos del host); lo que se rompe en el curso con ese cambio (cada fase
asume 8080); y si vale la pena.

### 🔴 Ejercicio 19 — Un nodo que se cae
Detén el contenedor de `lab-worker` y observa qué hace el cluster con él.

**Criterio:** `kubectl get nodes` con el worker en `NotReady`, y el tiempo hasta que aparece así.

**Rúbrica:** el tiempo medido; lo que pasaría con sus pods (la [Fase 16](16-escalado-y-rollout.md) lo provoca con réplicas); y lo
que esto no prueba de un nodo de verdad (el disco, la red física) 🚧.

### 🔴 Ejercicio 20 — La recomendación para Germán
Escribe, en media página, qué cluster local recomendarías para La Rebotica si compras aprobara Docker
Desktop, y si no.

**Criterio:** media página, con al menos tres números de B-07.

**Rúbrica:** las dos ramas; las pérdidas de cada opción con número; y ninguna promesa sobre
producción.

---

## 📚 16. Referencias

**Documentación oficial** (las versiones de [a01](a01-el-laboratorio.md))

- kind, *Configuration*: https://kind.sigs.k8s.io/docs/user/configuration/ — nodos, `extraPortMappings`
  y `containerdConfigPatches`.
- Kubernetes, *Configure Access to Multiple Clusters*:
  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
- Kubernetes, *Kubernetes Components*: https://kubernetes.io/docs/concepts/overview/components/ — qué
  corre en el control-plane y qué en cada nodo.
- k3d: https://k3d.io/ · minikube: https://minikube.sigs.k8s.io/docs/ · Docker Desktop, Kubernetes:
  https://docs.docker.com/desktop/features/kubernetes/

**Libros**

- Marko Lukša y Kevin Conner, *Kubernetes in Action*, 2.ª edición (2026), el capítulo sobre la
  arquitectura del cluster.

**Orden de lectura sugerido:** antes, la página de componentes; durante, la de varios clusters;
después, la de configuración de kind, con los dos archivos del curso delante.

> ⚠️ Las URL y los contenidos cambian; las de Kubernetes tienen selector de versión.

---

## 🏁 17. Resultado de la fase

```text
LOS CLUSTERS DEL CURSO AL CERRAR LA FASE 07 (uno a la vez)

  minimo   1 nodo   kind-minimo   127.0.0.1:8080 → 30080 (nadie escucha todavía)   ← el de todos los días
  lab      3 nodos  kind-lab      el mismo puerto: no convive con minimo            ← F10, F16, F18, Partes III y IV

  B-07 archivada: kind, por versión, por Podman y por lo que no trae.
```

> **La señal de que quedó bien:** *"Antes de aplicar algo, sé en qué cluster estoy; y si me
> equivoco, el comando falla en vez de aplicarse en otro."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde y `git status` limpio:
>
> ```bash
> git tag -a fase-07-el-cluster-local -m "F07 cerrada: minimo y lab desde sus archivos; un cluster a la vez; contextos explícitos; B-07 con sus crudos"
> ```
>
> Commits de la fase con prefijo `f07:`, los de ejercicio `f07 ej13: …` ([convención de git](00-convencion-de-git-y-tags.md)).
