# 📎 Apéndice a14 — Las GUI: qué capa mira cada una

> **Curso:** Laboratorio de contenedores y Kubernetes local · 🔥 Ampliación
> **Usado por:** [Fase 07](07-el-cluster-local.md) (el cluster es contenedores), [a04](a04-kubectl-y-k9s.md) (la terminal) · **Versiones cubiertas:** las de [a01](a01-el-laboratorio.md)
> **Memoria que suma al perfil `lab`:** 13 MiB con Headlamp dentro del cluster, en reposo; Docker Desktop y Podman Desktop corren fuera de la máquina virtual
> **Fecha de verificación ejecutada:** 05/10/2026 · macOS arm64 con Docker Desktop, cluster `lab`

**Esto no se lee de corrido.** Se entra por el índice buscando algo concreto y se sale. El curso se hace en la terminal,
con `kubectl` y k9s ([a04](a04-kubectl-y-k9s.md)), y no va a cambiar. Este apéndice es para el día en que alguien del
equipo pregunte por una interfaz gráfica: cuál mira qué, qué puede hacer, y qué esconde.

**Qué queda fuera:** Lens y sus derivados, las consolas web de los proveedores de nube, y **operar Docker Desktop y Podman
Desktop con clics**: este apéndice verificó lo que se puede verificar desde afuera (la capa que cada una mira, los
permisos de Headlamp) y dice qué no se verificó.

---

## Índice

- [Tres capas, tres pantallas](#tres-capas-tres-pantallas)
- [Lo que ve el motor](#lo-que-ve-el-motor)
- [Headlamp: el cluster en el navegador](#headlamp-el-cluster-en-el-navegador)
- [La GUI no puede más que su token](#la-gui-no-puede-más-que-su-token)
- [Docker Desktop y Podman Desktop](#docker-desktop-y-podman-desktop)
- [Cuándo una GUI esconde lo que tienes que ver](#cuándo-una-gui-esconde-lo-que-tienes-que-ver)
- [Cuándo usar qué](#-cuándo-usar-qué)
- [Referencias](#-referencias)
- [Ejercicios](#-ejercicios-5)

---

## Tres capas, tres pantallas

El laboratorio tiene tres capas, y cada GUI mira una:

| Capa | Qué hay | En la terminal | En una GUI |
|---|---|---|---|
| el motor | contenedores, imágenes, volúmenes, la máquina virtual | `docker`, `podman` | Docker Desktop, Podman Desktop |
| el orquestador | pods, `Deployment`, `Service`, eventos | `kubectl`, k9s | Headlamp (y la sección de Kubernetes de Podman Desktop) |
| la aplicación | trazas, métricas, logs | `task obs:*` | Grafana ([Fase 17](17-metricas-y-dashboards.md)) |

La confusión más común es pedirle a una pantalla lo que vive en otra capa.

## Lo que ve el motor

La [Fase 07](07-el-cluster-local.md) lo dijo: un nodo de kind es un contenedor. Desde el motor, el cluster entero son
tres contenedores:

```text
$ docker ps --filter label=io.x-k8s.kind.cluster=lab --format '{{.Names}}\t{{.Image}}\t{{.Status}}'
lab-worker          099e049362a1   Up 50 minutes
lab-control-plane   099e049362a1   Up 50 minutes
lab-worker2         099e049362a1   Up 50 minutes
contenedores en el motor, en total: 4         (el cuarto no es del curso)
pods en el cluster: 33
```

Los 32 contenedores de los pods corren **dentro** de los nodos, en su propio containerd, y el motor no los ve:

```text
$ docker exec lab-worker crictl ps -q | wc -l
13                                       (y 9 en el control-plane, 10 en lab-worker2)
```

Lo que Docker Desktop muestra en su lista de contenedores es lo que muestra `docker ps`: tres nodos. La memoria que pinta
por contenedor (1,49 GiB el control-plane, 748 y 889 MiB los workers) es la de **todo** lo que corre adentro: un nodo
que sube no dice qué pod subió. Esa pregunta es del orquestador.

## Headlamp: el cluster en el navegador

Headlamp es una interfaz web para Kubernetes, del proyecto `kubernetes-sigs`. Corre como aplicación de escritorio (con tu
`kubeconfig`) o **dentro del cluster**, que es lo que se verificó:

```bash
helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
helm install headlamp headlamp/headlamp --version 0.45.0 -n headlamp --create-namespace --wait
kubectl -n headlamp port-forward svc/headlamp 38411:80      # un puerto alto, libre
```

```text
listo en 272 s      (4 min 30 s fueron bajar la imagen, 103 MB, desde ghcr)
headlamp-56bb65b857-jt6sl   1m   13Mi
```

Trece MiB en reposo: la GUI del cluster pesa menos que cualquier servicio del curso. Al entrar, pide un token.

> ⚠️ **El chart crea un `ClusterRoleBinding` de su `ServiceAccount` a `cluster-admin`** (`clusterRoleBinding.create: true`
> por defecto). En la prueba de abajo no se usó para las peticiones sin token, pero el permiso está ahí, en un pod
> expuesto por la red. Para el laboratorio: `--set clusterRoleBinding.create=false`, y que cada quien entre con su token.

## La GUI no puede más que su token

Headlamp no tiene permisos propios para lo que muestra: reenvía cada petición a la API **con el token de quien entró**, y
la API decide ([Fase 20](20-seguridad-del-pod-y-de-la-red.md), RBAC). Con un token de la `ClusterRole` `view`, por el
mismo proxy que usa la página:

```text
$ kubectl -n headlamp create token lector --duration=1h        # una ServiceAccount con view
sin token: listar pods de apps                  403
token view: listar pods de apps                 200 · 9 pods
token view: listar los Secret de apps           403
token view: borrar un pod de prueba             403   (y el pod siguió ahí)
```

Es la propiedad que importa de una GUI de cluster: **un botón de borrar no es un permiso.** Dale a cada persona un token
con lo que le toca, y la interfaz hereda los límites. Al revés también: entrar con el `kubeconfig` de administrador de
kind es darle a cada clic el poder de `cluster-admin`.

## Docker Desktop y Podman Desktop

Las dos son la cara gráfica del motor, y las dos están en la máquina del autor (las versiones, en [a01](a01-el-laboratorio.md)).
**Ninguna se operó con clics para este apéndice.** Lo que sigue es lo que se verificó desde la terminal, más lo que dice
su documentación, separado:

- **Verificado:** las dos muestran la capa del motor; lo que Docker Desktop lista como contenedores es lo de `docker ps`
  (arriba). La máquina virtual de cada una es la que mide la tabla de memoria de [a01](a01-el-laboratorio.md), y en esta
  máquina conviven: Docker Desktop corriendo y la máquina de Podman detenida.
- **Según su documentación, no verificado aquí:** Docker Desktop trae su propio Kubernetes (el de la
  [Fase 07](07-el-cluster-local.md)) y lo administra desde su configuración; Podman Desktop tiene una sección de
  Kubernetes que lee los contextos de tu `kubeconfig` y lista sus pods, y una extensión para crear clusters de kind.

Lo útil de las dos es lo que la terminal hace incómodo: ver cuánta memoria y disco tiene la máquina virtual, limpiar
imágenes viejas con el ojo encima, cambiar los recursos de la máquina. Lo que cuidar: un "limpiar todo" desde la GUI es
un `prune` sin filtro, y se lleva lo de otros proyectos que compartan el motor.

## Cuándo una GUI esconde lo que tienes que ver

- **El comando.** El curso pide en cada fase el comando y su salida, porque eso se repite, se pega en un incidente y se
  automatiza. Un clic no se pega en un `Taskfile`.
- **Los eventos que ya pasaron.** Una lista de pods en verde no muestra el `OOMKilled` de hace diez minutos; `kubectl
  describe` y `kubectl get events` sí ([Fase 21](21-diagnostico.md)).
- **La capa equivocada.** Un nodo de kind "usando 1,5 GiB" en Docker Desktop no es un problema del motor; es el
  control-plane con Prometheus adentro.
- **Los permisos.** Con el `kubeconfig` de administrador, la GUI no avisa que lo que haces lo puede hacer cualquiera que
  tenga tu sesión abierta.

## 🧭 Cuándo usar qué

| Situación | Opción | Por qué |
|---|---|---|
| hacer el curso, un incidente, algo que se repite | `kubectl` y k9s | el comando queda escrito, se pega y se automatiza |
| mostrar el cluster a alguien que no usa la terminal | Headlamp, con un token de `view` | 13 MiB, y no puede romper nada que su token no deje |
| ver la máquina virtual, el disco y las imágenes del motor | Docker Desktop o Podman Desktop | es su capa, y la muestran mejor que `docker system df` |
| saber qué pod está gastando la memoria de un nodo | `kubectl top pods`, k9s o Headlamp | el motor solo ve el nodo |

## ⚠️ Advertencias

- Una instalación de Headlamp y una corrida de permisos; los 272 s hasta listo son de la red de ese día.
- Que Headlamp no use su `cluster-admin` sin token es de la versión 0.45.0 y su configuración por defecto; no lo des por
  hecho en otra.
- Docker Desktop y Podman Desktop cambian de pantallas entre versiones más que sus CLI; por eso el curso no depende de
  ninguna.

## 📚 Referencias

- Headlamp: https://headlamp.dev/docs/latest/ · *In-cluster installation*: https://headlamp.dev/docs/latest/installation/in-cluster/
- Kubernetes, *Using RBAC Authorization* (los roles `view`, `edit`, `admin`): https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles
- Docker Desktop: https://docs.docker.com/desktop/
- Podman Desktop, *Working with Kubernetes*: https://podman-desktop.io/docs/kubernetes
- kind, *Known issues* (los nodos como contenedores): https://kind.sigs.k8s.io/docs/user/known-issues/

> ⚠️ Las URL y los contenidos cambian.

## 🧪 Ejercicios (5)

### Ejercicio 1 — Las tres capas
Para un mismo pod de `inventory`, encuéntralo en las tres capas: el nodo en el motor, el pod en el cluster, el contenedor
con `crictl` dentro del nodo.

**Criterio:** los tres comandos con su salida, y el nombre del nodo que los une.

### Ejercicio 2 — Headlamp sin `cluster-admin`
Instala Headlamp con `clusterRoleBinding.create=false` y entra con un token de `view`.

**Criterio:** `kubectl get clusterrolebinding | grep headlamp` vacío, y la página mostrando los pods de `apps`.

### Ejercicio 3 — El botón que no funciona
Con el token de `view`, intenta borrar un pod desde la interfaz de Headlamp.

**Criterio:** el mensaje que muestra la interfaz, y el 403 que lo explica. (La interfaz no la verificó el autor: es lo
que este ejercicio comprueba.)

### Ejercicio 4 — Un rol a la medida
Crea un `Role` en `apps` que deje ver pods y logs, y reiniciar un `Deployment` (`patch`), sin borrar nada. Entra a
Headlamp con un token de ese rol.

**Criterio:** un reinicio que funciona y un borrado que da 403, desde la interfaz o por el proxy.

### Ejercicio 5 — ¿GUI para el equipo de La Vecina?
La mesa de ayuda quiere poder ver si los servicios de Paracelso están arriba sin pedirle a nadie la terminal. Escribe
la recomendación.

**Criterio:** media página: qué GUI, con qué token y qué permisos, cuánto pesa, y qué no va a poder ver (las tres capas).

---

> 🏷️ **Este apéndice no lleva tag propio.**
