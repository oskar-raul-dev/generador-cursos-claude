# 🚀 Fase 08 — El primer despliegue, en YAML plano: `pricing` en el cluster, campo por campo

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 08 de 27 · Parte II — El despliegue · **densa** ⭐
> **Perfil:** `minimo` · **Observabilidad encendida:** ninguna
> **Motor de referencia:** Docker · 🦭 la carga de imágenes cambia (`task images:load`, Fase 05); el resto, igual
> **Servicios que toca:** `pricing`, en G0, en el namespace `default` a propósito · **Paso de generación:** ninguno
> **Depende de:** [Fase 07](07-el-cluster-local.md) · **Habilita:** [Fase 09](09-los-cuatro-servicios-dentro.md)
> **Incidentes que reserva:** 05, 06 · **Medición:** ninguna
> **Apéndices de apoyo:** [a04](a04-kubectl-y-k9s.md), [a05](a05-diccionarios.md)
> **Fecha de verificación ejecutada:** 03/10/2026 · macOS arm64
> **Objetivo:** desplegar `pricing` con un `Deployment` y un `Service` escritos a mano, ver el bucle de reconciliación reemplazar un pod borrado, y llamar a `pricing` por su nombre desde otro pod.

---

## 🧭 1. Dónde estamos

El cluster `minimo` está arriba y vacío ([Fase 07](07-el-cluster-local.md)). La [Fase 06](06-del-compose-al-cluster.md) prometió un bucle que mantiene un
estado deseado; esta fase le entrega el primero: **un servicio, con dos objetos escritos a mano**, sin
ninguna herramienta que genere nada.

El primero es `pricing`, y no por ser el más chico. En la reunión del orden de extracción (historia
§5.4), Luz Marina puso la circular de precios sobre la mesa: un precio que el Ministerio cambia un
martes tiene que estar en las 263 cajas, y en el Siga eso exige desplegarlo entero en una ventana de
fin de semana (historia §3). Valentina lo dijo sin rodeos:

> *"Si hay un pedazo que tiene que poder salir un martes sin esperar al domingo, es precios. Y es el
> mío, así que si se rompe, que se rompa conmigo."*

`pricing` es el piloto de todo patrón nuevo, y este es el más importante de todos: **pasar de un
`docker run` a un objeto que el cluster mantiene vivo.** Hoy se despliega la imagen de G0 —el precio
fijo de 12.900 pesos—, en el namespace `default` a propósito: la [Fase 09](09-los-cuatro-servicios-dentro.md) lo lleva a su sitio, con los
otros cuatro y su almacén.

---

## 🎯 2. Objetivos de esta fase

1. Escribir el `Deployment` y el `Service` de `pricing`, con el porqué de cada campo.
2. Leer la escalera `Deployment` → `ReplicaSet` → `Pod`, y explicar por qué casi nunca se escribe un
   `Pod`.
3. Ver el bucle de reconciliación en vivo: borrar el pod, y cronometrar cuánto tarda en volver.
4. Llamar a `pricing` por su nombre desde otro pod, y saber de dónde sale ese nombre.
5. Usar `describe`, `logs` y `events` para leer un pod que no arranca, y provocar los incidentes 05 y
   06 con `task inc:break`.

---

## 🚫 3. Qué NO entra todavía

- Los otros cuatro servicios, los namespaces y las labels como mecanismo → [Fase 09](09-los-cuatro-servicios-dentro.md).
- Llegar a `pricing` desde el navegador → [Fase 10](10-la-entrada-al-sistema.md).
- Variables y configuración → [Fase 11](11-configuracion-y-secretos.md); sondas → [Fase 15](15-salud-y-recursos.md); réplicas y rollouts → [Fase 16](16-escalado-y-rollout.md).
- Helm, Kustomize o cualquier generador → [Fase 13](13-helm-el-paquete.md). Hoy, todo a mano.

---

## 🧨 4. El problema, en el laboratorio

En compose, `pricing` era una línea con `build:` y otra con `image:`. En el cluster no hay `build:`
([Fase 04](04-empaquetar-los-cuatro-runtimes.md)): hay un objeto que pide una imagen por nombre. El primer intento, con el manifiesto de la
sección 5 aplicado tal cual:

```text
$ kubectl apply -f deploy/manifests/pricing/
deployment.apps/pricing created
service/pricing created
$ kubectl wait --for=condition=Available deploy/pricing --timeout=60s
error: timed out waiting for the condition on deployments/pricing
$ kubectl describe pod -l app.kubernetes.io/name=pricing
…
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  60s                default-scheduler  Successfully assigned default/pricing-866c98cc74-rpsgs to minimo-control-plane
  Normal   Pulling    22s (x3 over 60s)  kubelet            spec.containers{pricing}: Pulling image "lab/pricing:g0"
  Warning  Failed     21s (x3 over 59s)  kubelet            spec.containers{pricing}: Failed to pull image "lab/pricing:g0": failed to pull and unpack image "docker.io/lab/pricing:g0": failed to resolve reference "docker.io/lab/pricing:g0": pull access denied, repository does not exist or may require authorization: server message: insufficient_scope: authorization failed
  Warning  Failed     21s (x3 over 59s)  kubelet            spec.containers{pricing}: Error: ErrImagePull
  Normal   BackOff    7s (x3 over 59s)   kubelet            spec.containers{pricing}: Back-off pulling image "lab/pricing:g0"
  Warning  Failed     7s (x3 over 59s)   kubelet            spec.containers{pricing}: Error: ImagePullBackOff
```

El nodo no tiene la imagen, y la fue a buscar a Docker Hub, donde no existe. Es el
[incidente 05](cuaderno-incidentes.md#-incidente-05--el-pod-espera-una-imagen-que-el-cluster-nunca-vio),
y su análisis vive en el cuaderno. Lo que importa aquí es lo que enseña sobre el modelo: **el
cluster no ve las imágenes de tu motor**. Las imágenes viajan al nodo con `task images:load` ([Fase 05](05-los-dos-motores.md)),
o desde un registry ([Fase 19](19-tls-y-certificados.md)). Para la imagen de G0:

```text
$ kind load docker-image lab/pricing:g0 --name minimo
Image: "lab/pricing:g0" with ID "sha256:7db924e5…" not yet present on node "minimo-control-plane", loading...
$ kubectl rollout restart deploy/pricing
$ kubectl rollout status deploy/pricing --timeout=90s
deployment "pricing" successfully rolled out
$ kubectl logs deploy/pricing
Found 2 pods, using pod/pricing-7847d89564-b85jb
2026/10/04 01:16:31 pricing escuchando en :8080
```

La segunda lección del mismo intento está en los eventos: **nadie te avisó**. `apply` dijo `created`,
y el pod se quedó reintentando la descarga con esperas cada vez más largas (`BackOff`). En compose, un
`up` que no encuentra la imagen falla en tu cara. En un cluster, el deseo queda guardado y el bucle
insiste, y lo que pasa se lee en los eventos, no en la salida de `apply`.

Los eventos dicen además **cómo** insiste. `Pulling … (x3 over 60s)` y `Back-off pulling image … (x3
over 59s)`: tres intentos en un minuto, con una espera que crece entre uno y otro, la misma idea que
el `Restarting` de la [Fase 03](03-el-contenedor-por-dentro.md) con otro nombre. Y `kubectl wait` se rindió a los 60 segundos que le di,
pero el cluster no: si nadie corrige el deseo, el pod seguirá en `ImagePullBackOff` mañana. Por eso el
reflejo, cuando algo "no arranca", no es volver a aplicar, sino leer: `kubectl get pods` dice que algo
está mal, `kubectl describe pod` dice qué, y el último evento casi siempre dice por qué. La sección 5.5
deja esos tres comandos como hábito.

---

## 🚀 5. El `Deployment` y el `Service`, con `pricing`

### 5.1 El `Deployment`, campo por campo

```yaml
# pricing, el primer despliegue (Fase 08). Escrito a mano, campo por campo.
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pricing
  # Sin namespace a propósito en la Fase 08: cae en `default`. La Fase 09 lo lleva a `apps`.
  labels:
    app.kubernetes.io/name: pricing
    app.kubernetes.io/part-of: lab
    app.kubernetes.io/component: backend
spec:
  # Una réplica: el perfil minimo. Las réplicas de verdad son de la Fase 16.
  replicas: 1
  # El selector usa solo el nombre: una label de más y el Deployment no encuentra sus pods (contrato §4).
  selector:
    matchLabels:
      app.kubernetes.io/name: pricing
  template:
    metadata:
      labels:
        app.kubernetes.io/name: pricing
        app.kubernetes.io/part-of: lab
        app.kubernetes.io/component: backend
        app.kubernetes.io/version: "g0"
    spec:
      containers:
        - name: pricing
          # La imagen cargada en el nodo con task images:load; el tag nombra el paso de generación.
          image: lab/pricing:g0
          # IfNotPresent: usa la del nodo. Con :latest el valor por defecto sería Always, y el nodo
          # intentaría bajarla de Docker Hub, donde no existe.
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 8080   # el puerto del contrato (§3)
```

Tres partes. `metadata` dice cómo se llama y qué etiquetas lleva **el `Deployment`**. `spec.replicas`
es el deseo: cuántos pods. Y `spec.template` es **el molde de cada pod**, con sus propias labels y sus
contenedores. Entre las dos está `spec.selector`, el campo que más errores produce de toda la Parte II:
dice qué pods son de este `Deployment`, **por sus labels**, y tiene que coincidir con las del molde.
Los selectores del curso usan solo `app.kubernetes.io/name` (contrato), y la razón se ve en el
incidente 06.

**Las cuatro labels, y cuál decide.** Las labels del curso son las recomendadas por Kubernetes y
ninguna inventada (contrato): `app.kubernetes.io/name` dice qué servicio es, `part-of` a qué sistema
pertenece, `component` qué papel cumple (`backend`, `frontend`, `database`…) y `version`, solo en el
molde, el tag legible de la imagen. Las cuatro sirven para buscar (`kubectl get pods -l
app.kubernetes.io/part-of=lab` lista todo el sistema), y **solo una decide**: la del selector. Las otras
tres se pueden cambiar sin consecuencias; la del selector, como muestra la sección 8, no se puede
cambiar nunca. Por eso el selector usa la que nunca va a cambiar de valor: el nombre del servicio.
`version` va en el molde y no en el selector a propósito: si estuviera en el selector, cada versión
nueva sería otro `Deployment`.

**El tag es el paso, no `latest`.** La imagen se pide como `lab/pricing:g0`. Con `latest` (o sin tag),
el valor por defecto de `imagePullPolicy` es `Always`, y el nodo intentaría descargarla de Docker Hub
cada vez, aunque la tuviera. El tag del paso de generación cambia cuando cambia el código del paso,
que es la regla de la autopsia de la [Fase 04](04-empaquetar-los-cuatro-runtimes.md): el nombre no se reutiliza para otro contenido.

### 5.2 La escalera: `Deployment`, `ReplicaSet`, `Pod`

```text
$ kubectl get deploy,rs,pods -l app.kubernetes.io/name=pricing
NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/pricing   0/1     1            0           0s

NAME                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/pricing-866c98cc74   1         1         0       0s

NAME                           READY   STATUS              RESTARTS   AGE
pod/pricing-866c98cc74-rpsgs   0/1     ContainerCreating   0          0s
```

Escribiste un objeto y aparecieron tres. El **`Deployment`** guarda el deseo y la historia de
versiones; por cada versión del molde crea un **`ReplicaSet`**, cuyo único trabajo es que haya
exactamente `N` pods de ese molde; y el `ReplicaSet` crea los **`Pod`**. El sufijo `866c98cc74` es el
hash del molde: cuando el molde cambia, nace un `ReplicaSet` nuevo con otro hash, y así funciona un
rollout ([Fase 16](16-escalado-y-rollout.md)). Se vio con el `rollout restart` de la sección 4: el pod nuevo era
`pricing-7847d89564-…`, de otro `ReplicaSet`.

Cada eslabón tiene su controlador, y los tres vuelven a crear lo que falta. Hasta el `ReplicaSet`:

```text
$ kubectl delete rs -l app.kubernetes.io/name=pricing --wait=false
replicaset.apps "pricing-866c98cc74" deleted from default namespace
$ kubectl get rs,pods -l app.kubernetes.io/name=pricing          # 3 segundos después
NAME                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/pricing-866c98cc74   1         1         1       3s

NAME                           READY   STATUS    RESTARTS   AGE
pod/pricing-866c98cc74-8gzpn   1/1     Running   0          3s
```

Mismo nombre, porque el molde no cambió. **Por eso casi nunca se escribe un `Pod`**: un pod suelto no
tiene a nadie arriba que lo vuelva a crear (la autopsia de la sección 9 lo mide).

### 5.3 El bucle, en vivo

La [Fase 06](06-del-compose-al-cluster.md) dibujó el bucle; aquí se ve:

```text
$ kubectl delete pod/pricing-7847d89564-b85jb --wait=false
pod "pricing-7847d89564-b85jb" deleted from default namespace
$ kubectl get pods -l app.kubernetes.io/name=pricing
NAME                       READY   STATUS              RESTARTS   AGE
pricing-7847d89564-b85jb   1/1     Terminating         0          12s
pricing-7847d89564-qx42h   0/1     ContainerCreating   0          0s
$ kubectl get events --sort-by=.lastTimestamp | tail -8
15s         Normal    SuccessfulCreate          replicaset/pricing-7847d89564   Created pod: pricing-7847d89564-b85jb
15s         Normal    Pulled                    pod/pricing-7847d89564-b85jb    Container image "lab/pricing:g0" already present on machine and can be accessed by the pod
3s          Normal    Scheduled                 pod/pricing-7847d89564-qx42h    Successfully assigned default/pricing-7847d89564-qx42h to minimo-control-plane
3s          Normal    Killing                   pod/pricing-7847d89564-b85jb    Stopping container pricing
3s          Normal    SuccessfulCreate          replicaset/pricing-7847d89564   Created pod: pricing-7847d89564-qx42h
2s          Normal    Pulled                    pod/pricing-7847d89564-qx42h    Container image "lab/pricing:g0" already present on machine and can be accessed by the pod
2s          Normal    Created                   pod/pricing-7847d89564-qx42h    Container created
2s          Normal    Started                   pod/pricing-7847d89564-qx42h    Container started
```

El pod borrado todavía está terminando y su reemplazo ya se está creando. Los eventos cuentan el
bucle en orden: el `ReplicaSet` ve uno de menos (`SuccessfulCreate`), el planificador le busca nodo
(`Scheduled`), y el `kubelet` del nodo lo arranca (`Pulled`, `Created`, `Started`). Nadie corrió `up
-d`. **El bucle es eso: un deseo guardado y tres controladores que no paran de compararlo con lo que
hay.**

### 5.4 El `Service`: un nombre estable delante de pods que cambian

Cada pod nuevo tiene otra dirección IP. Quien llame a `pricing` no puede perseguirlas; necesita un
nombre que no cambie:

```yaml
# El nombre estable de pricing dentro del cluster (Fase 08).
apiVersion: v1
kind: Service
metadata:
  name: pricing
  labels:
    app.kubernetes.io/name: pricing
    app.kubernetes.io/part-of: lab
    app.kubernetes.io/component: backend
spec:
  # ClusterIP: una dirección virtual solo dentro del cluster. La entrada desde afuera es la Fase 10.
  type: ClusterIP
  # A qué pods les manda el tráfico: los que tengan esta label, y solo esta.
  selector:
    app.kubernetes.io/name: pricing
  ports:
    - name: http
      port: 8080          # el puerto del Service
      targetPort: http    # el puerto con nombre del contenedor
```

```text
$ kubectl get svc pricing
NAME      TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
pricing   ClusterIP   10.96.34.233   <none>        8080/TCP   76s
$ kubectl get endpointslices -l kubernetes.io/service-name=pricing
NAME            ADDRESSTYPE   PORTS   ENDPOINTS    AGE
pricing-tslff   IPv4          8080    10.244.0.7   77s
```

El `Service` tiene una dirección virtual que no cambia (`10.96.34.233`), y un **`EndpointSlice`** con
las direcciones reales de los pods que su selector encuentra. Cuando un pod muere y otro nace, el
`EndpointSlice` cambia y el `Service`, no. Otro bucle más: el controlador de endpoints, mirando
labels.

**La IP del `Service` no está en ninguna parte.** Ningún pod ni ninguna interfaz tiene
`10.96.34.233`. Es una regla: `kube-proxy`, que corre en cada nodo ([Fase 07](07-el-cluster-local.md)), la escribe en el nodo
cada vez que cambia un `EndpointSlice`. En el nodo de `minimo`, recién creado el `Service` y antes de
que su pod estuviera listo:

```text
$ docker exec minimo-control-plane iptables-save | grep "default/pricing"
-A KUBE-SERVICES -d 10.96.47.146/32 -p tcp -m comment --comment "default/pricing:http has no endpoints" -m tcp --dport 8080 -j REJECT --reject-with icmp-port-unreachable
```

Y unos segundos después, con el pod listo:

```text
-A KUBE-SEP-UNPFBB6NCG72R6PY -p tcp -m comment --comment "default/pricing:http" -m tcp -j DNAT --to-destination 10.244.0.26:8080
-A KUBE-SERVICES -d 10.96.47.146/32 -p tcp -m comment --comment "default/pricing:http cluster IP" -m tcp --dport 8080 -j KUBE-SVC-Y6BNEJXEJHQHRZNQ
-A KUBE-SVC-Y6BNEJXEJHQHRZNQ -m comment --comment "default/pricing:http -> 10.244.0.26:8080" -j KUBE-SEP-UNPFBB6NCG72R6PY
```

(Otro `Service`, otra IP: la creé de nuevo para mirarla.) Un paquete a la IP del `Service` se
reescribe en el nodo hacia la IP de un pod (`DNAT`). Sin pods detrás, la regla es otra: **rechazar en
el acto**. Esa diferencia es la que se ve en el incidente 06: un `Service` sin endpoints no hace
esperar, contesta "no" en milisegundos. Este es el modo `iptables` de `kube-proxy`, el que usa kind; no
hay que tocarlo, pero saber que existe explica por qué sus reglas cambian cada vez que un pod nace o muere.

**¿Cómo se llaman entre sí mis servicios?** Por el DNS del cluster. Desde un pod cualquiera (uso la
imagen de nginx sin privilegios del laboratorio, solo porque trae `curl`):

```text
$ kubectl run cliente --rm --attach --restart=Never --quiet --image=nginxinc/nginx-unprivileged@sha256:ed04ec1ff34502c339ee5c3ae3f855442398edc1d05591e2b98981dcbbd20b1e -- curl -s 'http://pricing:8080/prices/SKU-0003?store=DRO-007'
{"currency":"COP","price":12900,"sku":"SKU-0003","store":"DRO-007"}
$ kubectl run cliente --rm --attach --restart=Never --quiet --image=nginxinc/nginx-unprivileged@sha256:ed04ec1ff34502c339ee5c3ae3f855442398edc1d05591e2b98981dcbbd20b1e -- cat /etc/resolv.conf
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5
```

`pricing` a secas funciona porque el pod busca primero en `default.svc.cluster.local`: el nombre
completo es `pricing.default.svc.cluster.local`, y la parte del medio es **el namespace**. Por eso la
[Fase 06](06-del-compose-al-cluster.md) decía que el nombre del cluster lleva namespace: un pod de otro namespace tendría que decir
`pricing.default`. La [Fase 09](09-los-cuatro-servicios-dentro.md) lo convierte en un incidente.

### 5.5 `describe`, `logs` y `events`: los tres primeros comandos

Se estrenaron arriba, donde hicieron falta, y se quedan para siempre:

- **`kubectl describe pod <pod>`** se lee **de abajo hacia arriba**: los eventos están al final, y ahí
  está casi siempre la respuesta (la sección 4 la tenía en `Failed to pull image`).
- **`kubectl logs deploy/pricing`** elige un pod del `Deployment` y lo dice (`Found 2 pods, using
  pod/…`); con `--previous`, los del contenedor que murió antes del actual.
- **`kubectl get events --sort-by=.lastTimestamp`** cuenta qué hicieron los controladores, en orden.

Las variantes y lo que conviene mirar en cada salida están en [a04](a04-kubectl-y-k9s.md#-qué-le-pasa).

### 5.6 El objeto se lee desde el cluster, y un cambio se ve antes de aplicarlo

Un manifiesto no se escribe de memoria. El propio cluster explica cada campo, con la documentación de
**su** versión:

```text
$ kubectl explain deployment.spec.selector
GROUP:      apps
KIND:       Deployment
VERSION:    v1

FIELD: selector <LabelSelector>

DESCRIPTION:
    Label selector for pods. Existing ReplicaSets whose pods are selected by
    this will be the ones affected by this deployment. It must match the pod
    template's labels.
…
```

`It must match the pod template's labels`: la regla de 5.1, dicha por la API. Y cuando el objeto ya
existe, lo que importa no es lo que escribiste sino lo que el cluster **hizo** con eso, que vive en
`status`:

```text
$ kubectl get deploy pricing -o jsonpath='{range .status.conditions[*]}{.type}{"\t"}{.status}{"\t"}{.reason}{"\t"}{.message}{"\n"}{end}'
Available	True	MinimumReplicasAvailable	Deployment has minimum availability.
Progressing	True	NewReplicaSetAvailable	ReplicaSet "pricing-866c98cc74" has successfully progressed.
$ kubectl get deploy pricing -o jsonpath='{.metadata.generation} {.status.observedGeneration} {.status.replicas} {.status.readyReplicas}{"\n"}'
1 1 1 1
```

`spec` es el deseo; `status` es lo que el controlador observó. Los cuatro números de la segunda
consulta son el bucle en una línea: la **generación** sube cada vez que cambia el deseo, y la
**generación observada** dice hasta cuál llegó el controlador. Cuando son iguales y las réplicas
listas son las pedidas, el deseo se cumplió.

Antes de cambiar el deseo, se mira qué va a cambiar. Con una copia del manifiesto pidiendo dos
réplicas:

```text
$ kubectl diff -f pricing-dos-replicas/
…
-  generation: 1
+  generation: 2
…
-  replicas: 1
+  replicas: 2
$ kubectl apply -f pricing-dos-replicas/
deployment.apps/pricing configured
service/pricing unchanged
$ kubectl get deploy pricing -o jsonpath='{.metadata.generation} {.status.observedGeneration} {.status.replicas} {.status.readyReplicas}{"\n"}'
2 2 2 1
$ kubectl get endpointslices -l kubernetes.io/service-name=pricing          # un segundo después
NAME            ADDRESSTYPE   PORTS   ENDPOINTS                 AGE
pricing-rh5r6   IPv4          8080    10.244.0.24,10.244.0.25   1s
```

`diff` compara el manifiesto con lo que vive en el cluster y muestra solo lo que cambia, sin tocar
nada. El `apply` siguiente cambió `replicas`, y la consulta lo agarró a mitad de camino: generación
2 observada, dos réplicas y una lista. Un segundo después, el `Service` ya tenía dos direcciones detrás.
`pricing` vuelve a una réplica al aplicar el manifiesto del repositorio: el perfil `minimo` es de
una réplica, y las de verdad son de la [Fase 16](16-escalado-y-rollout.md).

> 💡 **`kubectl diff` antes de cada `apply` que no escribiste tú.** Es la única forma de saber qué va a
> cambiar en un cluster compartido, y es exactamente lo que hace `helm diff` en la [Fase 14](14-helm-en-operacion.md).

### 5.7 `task inc:break`: romper a voluntad

Desde esta fase, cada incidente de plataforma se puede provocar sobre el laboratorio que ya corre:

```bash
task inc:break -- 06
```

Debajo, `python3 scripts/incidents/inc.py break 06`, que aplica el cambio mínimo que produce el
incidente y lo dice (`Incidente 06: roto.`). `task inc:fix -- 06` vuelve a aplicar los manifiestos del
repositorio, que son el estado correcto. La forma canónica de llegar a un incidente sigue siendo su
tag (`inc/06/…-roto`), explicada en el [cuaderno](cuaderno-incidentes.md#-cómo-se-trabaja-un-incidente).

> 🩻 **Esto sí funciona igual.** El contenedor de `pricing` es el mismo de la [Fase 04](04-empaquetar-los-cuatro-runtimes.md): la misma imagen,
> el mismo proceso 1, el mismo puerto. Kubernetes no lo cambia; lo envuelve en un pod.

**Prueba de fuego.**

```text
$ kubectl rollout status deploy/pricing
deployment "pricing" successfully rolled out
$ kubectl run cliente --rm --attach --restart=Never --quiet --image=nginxinc/nginx-unprivileged@sha256:ed04ec1ff34502c339ee5c3ae3f855442398edc1d05591e2b98981dcbbd20b1e -- curl -s http://pricing.default.svc.cluster.local:8080/health/live
{"status":"live"}
```

**El patrón a memorizar.** Un `Deployment` guarda el deseo, un `ReplicaSet` cuenta pods, un `Service`
pone un nombre delante de los pods que su selector encuentra; y todo se une por labels.

---

## 🔁 6. Los otros tres: donde no es mecánico

En esta fase entra solo `pricing`, a propósito: el patrón se construye entero con el piloto. Lo que
no va a ser mecánico en la [Fase 09](09-los-cuatro-servicios-dentro.md) ya se ve venir: `catalog` son **dos contenedores en un pod**, como
en compose con `network_mode` ([Fase 04](04-empaquetar-los-cuatro-runtimes.md)); `inventory` tarda un segundo en abrir el puerto y su pod va a
estar `Running` antes de poder atender ([Fase 15](15-salud-y-recursos.md)); y los cuatro van a necesitar un sitio para su
almacén.

---

## 🪞 7. Tu instinto de compose dice… y la apuesta

El instinto, en su mejor versión: *"si borro el contenedor, se fue; para tenerlo de nuevo, `up -d`."*
En compose es exactamente así ([Fase 06](06-del-compose-al-cluster.md), `Exited (137)` hasta el próximo `up`). En un cluster, borrar
el pod es pedirle al `ReplicaSet` que cree otro.

> 🪞 **Apuesta antes de ejecutar.** Borrando el pod de `pricing`, el `Deployment` tiene un pod nuevo
> en `Running` en menos de 5 segundos, cinco veces de cinco.
>
> **Resultado: ganada, con margen.** Cinco borrados seguidos, desde el `delete` hasta un pod nuevo
> `Running` y listo: 0,49, 0,55, 0,57, 0,56 y 0,56 segundos.

El margen tiene trampa, y conviene decirla: **listo, aquí, quiere decir que el proceso arrancó**. La
readiness de G0 es trivial y `pricing` abre el puerto en milisegundos. Con `inventory`, el mismo
reemplazo va a estar "listo" antes de poder atender, y medio segundo va a ser mentira. Es la [Fase 15](15-salud-y-recursos.md).

---

## 🧨 8. La rotura: cambiar el selector

Esta fase no mide; rompe. **El cambio exacto:** agregarle una label al selector de un `Deployment` que
ya existe, por ejemplo para que coincida con `component: backend`:

```text
$ kubectl patch deploy pricing --type=merge -p '{"spec":{"selector":{"matchLabels":{"app.kubernetes.io/name":"pricing","app.kubernetes.io/component":"backend"}}}}'
The Deployment "pricing" is invalid: spec.selector: Invalid value: {"matchLabels":{"app.kubernetes.io/component":"backend","app.kubernetes.io/name":"pricing"}}: field is immutable
```

**El síntoma literal**, arriba: el selector de un `Deployment` **no se cambia nunca**. Es el campo que
une al `Deployment` con sus `ReplicaSet` y sus pods, y cambiarlo dejaría huérfanos. **Para salir:**
borrar el `Deployment` y crearlo de nuevo con el selector nuevo, que en producción es un corte. Por eso
el selector se decide una vez, mínimo, y el contrato lo fija en una sola label.

---

## ⚰️ 9. Autopsia: el pod suelto

**La decisión, con su mejor argumento.** Escribir un `Pod` y no un `Deployment`: *"es lo que más se
parece a un `docker run`, son diez líneas menos, y para un servicio con una réplica no necesito
réplicas."* Es lo primero que aparece en cualquier tutorial, y `kubectl run` crea exactamente eso.

**Por qué era razonable.** Funciona: un `Pod` con la imagen de `pricing` arranca, responde y pasa
cualquier prueba, igual que el del `Deployment`.

**Qué pasa después, con número.**

```text
$ kubectl apply -f pod-suelto.yaml
pod/pricing-suelto created
$ kubectl wait --for=condition=Ready pod/pricing-suelto --timeout=60s
pod/pricing-suelto condition met
$ kubectl delete pod pricing-suelto
pod "pricing-suelto" deleted from default namespace
$ kubectl get pods          # 5 segundos después
NAME                       READY   STATUS    RESTARTS   AGE
pricing-866c98cc74-n6f7p   1/1     Running   0          8s
```

El pod suelto se fue, y no volvió: en la lista solo queda el del `Deployment`. Nadie lo reemplaza si
se borra, si su nodo se cae o si lo desaloja la falta de memoria. Es el contenedor de compose sin
`restart:`, en un cluster.

**Cuánto cuesta salir, con número.** Unas diez líneas: envolver el mismo `spec` del pod en
`spec.template` de un `Deployment`, con su `selector` y sus `replicas`.

**Qué lo habría cambiado.** Preguntar *¿quién vuelve a crear esto si desaparece?* Para un `Pod`
suelto, nadie. Para un trabajo que tiene que terminar, un `Job` ([Fase 12](12-estado-y-almacenamiento.md)); para un servicio, un
`Deployment`.

**Antes y después, con números:** borrado el pod suelto, 0 pods de reemplazo; borrado el pod del
`Deployment`, uno nuevo listo en 0,49–0,57 segundos.

---

## 📖 10. Traducción

| En compose | En Kubernetes | Lo que cambia |
|---|---|---|
| un servicio | `Deployment` + `Service` | el que corre y el nombre que lo encuentra son dos objetos |
| `image:` con `build:` | `image:` con un tag que el nodo tiene | el cluster no construye; la imagen se carga o se publica |
| `docker compose up -d` | `kubectl apply -f` | el deseo queda guardado y el bucle insiste solo |
| `docker compose logs pricing` | `kubectl logs deploy/pricing` | elige un pod del `Deployment` |
| el nombre `pricing` en la red | `pricing.default.svc.cluster.local` | el nombre lleva namespace |
| *sin equivalente* | `ReplicaSet` | cuenta pods de una versión del molde |

El diccionario completo, en las dos direcciones, en [a05](a05-diccionarios.md#-compose--kubernetes).
🌩️ En un cluster gestionado, este `Deployment` y este `Service` se aplican tal cual; lo que cambia es
de dónde sale la imagen (el registry del proveedor) y cómo se entra desde afuera ([Fase 10](10-la-entrada-al-sistema.md)).

---

## 🩺 11. Incidentes de esta fase

- **[05 — El pod espera una imagen que el cluster nunca vio](cuaderno-incidentes.md#-incidente-05--el-pod-espera-una-imagen-que-el-cluster-nunca-vio).**
  `ErrImagePull` → `ImagePullBackOff`, y en los eventos `pull access denied, repository does not exist
  or may require authorization`.
- **[06 — El `Service` existe y nadie le contesta](cuaderno-incidentes.md#-incidente-06--el-service-existe-y-nadie-le-contesta).**
  `curl: (7) Failed to connect to pricing:8080 after 4 ms: Could not connect to server`, con el pod
  `Running`.

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

Para un servicio en una máquina, lo de esta fase es más trabajo que compose: dos objetos y treinta
líneas de YAML donde había cuatro, una imagen que hay que llevar al nodo a propósito, y fallos que no
se ven en la salida de `apply` sino en los eventos. El primer intento de esta fase tardó un minuto
entero en mostrar que la imagen no estaba, donde `docker compose up` habría fallado en un segundo.

Lo que se compra con eso es el bucle: un pod borrado vuelve en medio segundo sin que nadie corra
nada, y un nombre estable delante de pods que cambian. Si tu servicio no necesita ninguna de las dos
cosas, un contenedor con `restart: unless-stopped` en una máquina alcanza.

**La pregunta del curso, para esta fase:** el contenedor te dio el proceso y su imagen. El
orquestador te dio el `ReplicaSet` que lo reemplaza, el `Service` que lo nombra y el DNS que lo
encuentra. **Te tocó a ti** llevar la imagen al nodo, escribir cada campo, y elegir un selector que no
vas a poder cambiar.

---

## ⚠️ 13. Errores comunes y diagnóstico

**`kubectl run -i` dentro de un script se come el resto del script.** Síntoma: el script termina
después del primer `kubectl run`. Causa: `-i` lee la entrada estándar, que en un script con *heredoc*
es el script mismo. Salida: `--attach` en vez de `-i`, y `</dev/null` al final.

**`warning: couldn't attach to pod/cliente, falling back to streaming logs`.** Aparece con pods que
terminan muy rápido: el comando ya corrió y `kubectl` muestra su salida desde los logs. La salida
sale repetida; no es un error.

**`Found 2 pods, using pod/…` en `kubectl logs deploy/…`.** Durante un rollout hay dos pods; `logs`
elige uno. Salida: `kubectl logs <pod>` con el nombre exacto, o esperar a que termine el rollout.

**El pod queda `Pending` sin eventos de descarga.** Causa: no hay nodo que lo acepte (recursos,
*taints*). Comprobación 🩺: `kubectl describe pod`, la línea `FailedScheduling`. Es la [Fase 15](15-salud-y-recursos.md).

---

## 📋 14. Checklist de validación

```text
[ ] kubectl apply -f deploy/manifests/pricing/: el Deployment y el Service, creados
[ ] kubectl get deploy,rs,pods muestra la escalera, y sabes de dónde sale el hash del ReplicaSet
[ ] borrar el pod: uno nuevo listo en menos de un segundo, y los eventos que lo cuentan
[ ] curl a pricing y a pricing.default.svc.cluster.local desde otro pod, con la misma respuesta
[ ] el selector del Deployment no se puede cambiar, y sabes por qué
[ ] task inc:break -- 05 y task inc:break -- 06 dan sus síntomas, e inc:fix los repara
```

---

## 🧪 15. Ejercicios (24)

La mitad son de diagnóstico. Antes de cada 🟠 y 🔴, la predicción por escrito.

## 🟢 Fácil — el primer despliegue (1–7)

### 🟢 Ejercicio 1 — `pricing`, en limpio
Despliega `pricing` de cero en `minimo`, con la imagen ya cargada.

**Criterio:** `kubectl rollout status deploy/pricing` termina con `successfully rolled out`.

<details><summary>Solución</summary>

`task images:load -- minimo` (o `kind load docker-image lab/pricing:<tag> --name minimo`),
`kubectl apply -f deploy/manifests/pricing/` y el `rollout status`.
</details>

### 🟢 Ejercicio 2 — La escalera
Muestra el `Deployment`, su `ReplicaSet` y su pod en un solo comando.

**Criterio:** las tres secciones de `kubectl get deploy,rs,pods -l app.kubernetes.io/name=pricing`.

<details><summary>Solución</summary>

El comando del criterio.
</details>

### 🟢 Ejercicio 3 — Borra el pod
Borra el pod de `pricing` y mira cómo vuelve.

**Criterio:** un pod nuevo con otro nombre, y el evento `SuccessfulCreate` del `ReplicaSet`.

<details><summary>Solución</summary>

`kubectl delete pod -l app.kubernetes.io/name=pricing` y `kubectl get events --sort-by=.lastTimestamp
| tail`.
</details>

### 🟢 Ejercicio 4 — Por su nombre
Llama a `pricing` desde otro pod, con el nombre corto y con el completo.

**Criterio:** las dos respuestas iguales.

<details><summary>Solución</summary>

Los dos `kubectl run cliente --rm --attach --restart=Never …` de 5.4.
</details>

### 🟢 Ejercicio 5 — Las direcciones de verdad
Muestra la IP del `Service` y la del pod, y di cuál cambia al borrar el pod.

**Criterio:** `kubectl get svc pricing` y `kubectl get endpointslices -l
kubernetes.io/service-name=pricing`, antes y después de borrar el pod.

<details><summary>Solución</summary>

La del `Service` no cambia; la del `EndpointSlice` sí.
</details>

### 🟢 Ejercicio 6 — Los logs
Muestra los logs de `pricing` después de llamarlo tres veces.

**Criterio:** tres líneas `GET /prices/… 200`.

<details><summary>Solución</summary>

Tres `curl` desde un pod cliente y `kubectl logs deploy/pricing`.
</details>

### 🟢 Ejercicio 7 — Un incidente con la tarea
Provoca el incidente 06 con la tarea y repáralo.

**Criterio:** el `EndpointSlice` sin direcciones después de `task inc:break -- 06`, y con su dirección
después de `task inc:fix -- 06`.

<details><summary>Solución</summary>

Los dos comandos del criterio y `kubectl get endpointslices -l kubernetes.io/service-name=pricing`
después de cada uno. El porqué está en el cuaderno.
</details>

## 🟡 Intermedio — leer el cluster (8–14)

### 🟡 Ejercicio 8 — `describe` de abajo hacia arriba
Despliega `pricing` con un tag que no existe y encuentra la causa solo con `describe`.

**Criterio:** la línea `Failed to pull image` literal.

<details><summary>Solución</summary>

`kubectl set image deploy/pricing pricing=lab/pricing:no-existe` y `kubectl describe pod -l
app.kubernetes.io/name=pricing`. Repara con `kubectl apply -f deploy/manifests/pricing/`.
</details>

### 🟡 Ejercicio 9 — El rollout que no rompe
Con el ejercicio 8 a medias, comprueba si `pricing` sigue contestando.

**Criterio:** el pod viejo `Running`, el nuevo en `ImagePullBackOff`, y un `curl` que contesta.

<details><summary>Solución</summary>

El `Deployment` no baja el pod viejo hasta que el nuevo esté listo ([Fase 16](16-escalado-y-rollout.md)). `kubectl get pods` y el
`curl` desde un pod cliente.
</details>

### 🟡 Ejercicio 10 — El resolv.conf
Explica cada línea del `/etc/resolv.conf` de un pod.

**Criterio:** la salida, y una frase por línea.

<details><summary>Solución</summary>

`search` (los dominios que se prueban, empezando por el namespace del pod), `nameserver` (el `Service`
de CoreDNS) y `ndots:5` (cuántos puntos necesita un nombre para no probar los `search` primero).
</details>

### 🟡 Ejercicio 11 — Con Podman
Despliega `pricing` con Podman como motor.

**Criterio:** `task images:load -- minimo` y el `rollout status` en verde con Podman.

<details><summary>Solución</summary>

El mismo procedimiento con `task engine:use -- podman`; la tarea de carga cambia por debajo ([Fase 05](05-los-dos-motores.md)).
</details>

### 🟡 Ejercicio 12 — El `ReplicaSet` viejo
Haz dos `rollout restart` seguidos y cuenta los `ReplicaSet`.

**Criterio:** `kubectl get rs` con un `ReplicaSet` en 1 y los viejos en 0.

<details><summary>Solución</summary>

El `Deployment` guarda los viejos (hasta `revisionHistoryLimit`) para poder volver atrás ([Fase 16](16-escalado-y-rollout.md)).
</details>

### 🟡 Ejercicio 13 — Las labels del pod
Muestra las labels del pod de `pricing` y explica cuál usa el `Service`.

**Criterio:** `kubectl get pods --show-labels`, y la que coincide con el selector del `Service`.

<details><summary>Solución</summary>

`app.kubernetes.io/name=pricing`. Además lleva `pod-template-hash`, que agrega el `ReplicaSet`.
</details>

### 🟡 Ejercicio 14 — `inventory` a mano
Escribe un `Deployment` y un `Service` para `inventory` en `default`, copiando el patrón.

**Criterio:** `curl` a `inventory:8080/health/live` desde un pod cliente responde `{"status":"live"}`.

<details><summary>Solución</summary>

Los mismos dos archivos, con `inventory` en lugar de `pricing` y la imagen de `inventory` cargada en el
nodo. Bórralo al terminar: la [Fase 09](09-los-cuatro-servicios-dentro.md) lo pone en su sitio.
</details>

## 🟠 Difícil — predecir y explicar (15–20)

### 🟠 Ejercicio 15 — Cronometra el bucle con Java
Repite la apuesta de la sección 7 con tu `inventory` del ejercicio 14. **Predice** el tiempo.

**Criterio:** cinco mediciones hasta `Running` y listo, y una más hasta que `/health/live` responde.

**Rúbrica:** la predicción; las dos series; y por qué "listo" y "responde" difieren con Java y no con Go.

### 🟠 Ejercicio 16 — El selector, la otra mitad
Cambia una label del **molde** (no del selector) para que no coincida con el selector. **Predice** qué
dice `apply`.

**Criterio:** la predicción y el error literal.

**Rúbrica:** el error (`selector does not match template labels`); y por qué el API lo rechaza antes de
guardar nada.

### 🟠 Ejercicio 17 — El incidente 05, sin la tarea
Provoca el incidente 05 a mano, como le pasaría a alguien que construyó una versión nueva y se olvidó
de cargarla.

**Criterio:** un tag nuevo construido, el manifiesto que lo pide, y el `ImagePullBackOff`.

**Rúbrica:** los pasos; el síntoma; y qué hábito del Taskfile lo previene.

### 🟠 Ejercicio 18 — Lo que el `Service` no ve
Crea un segundo `Deployment` con las mismas labels que `pricing` pero otra imagen. **Predice** a quién
le llega el tráfico.

**Criterio:** la predicción y diez `curl` desde un pod cliente con su resultado.

**Rúbrica:** el `EndpointSlice` con dos direcciones; el reparto; y por qué el selector mínimo es una
promesa de que nadie más va a usar esa label.

### 🟠 Ejercicio 19 — `kubectl run` es un pod suelto
Crea `pricing` con `kubectl run` y borra su pod. **Predice** si vuelve.

**Criterio:** la predicción y `kubectl get pods` después del borrado.

**Rúbrica:** el resultado; el `kind` del objeto que creó `kubectl run` (`kubectl get pod … -o yaml`); y
cuándo un pod suelto es lo correcto (una prueba que se borra sola, como el cliente de esta fase).

### 🟠 Ejercicio 20 — Los eventos se van
Mide cuánto tiempo guarda el cluster los eventos de un pod.

**Criterio:** la hora del evento más viejo de `kubectl get events` en dos momentos separados por al
menos una hora.

**Rúbrica:** el resultado; y qué implica para un incidente de anoche (los eventos ya no están; la Fase
18 trae los logs).

## 🔴 Muy difícil — el laboratorio roto (21–24)

### 🔴 Ejercicio 21 — Tres incidentes juntos
Provoca a la vez los incidentes 05 y 06 y repáralos en el orden que los encontraría alguien que solo
ve "no contesta".

**Criterio:** `pricing` contestando al final, y tu bitácora con el orden de las hipótesis.

**Rúbrica:** las hipótesis en orden; el comando que descartó cada una; y el tiempo total.

### 🔴 Ejercicio 22 — Sin `Service`
Llama a `pricing` sin `Service`, por la IP del pod, y borra el pod.

**Criterio:** la llamada que funciona antes y la que falla después.

**Rúbrica:** por qué la IP del pod no es una dirección; y qué tendrías que construir tú para no
necesitar un `Service`.

### 🔴 Ejercicio 23 — El selector cambiado de verdad
Cambia el selector de `pricing` sin tener `pricing` caído más de diez segundos.

**Criterio:** el `Deployment` con el selector nuevo, y una serie de `curl` cada segundo sin más de
diez fallos seguidos.

**Rúbrica:** el procedimiento (un segundo `Deployment` con el selector nuevo antes de borrar el
viejo); los fallos medidos; y por qué la sección 8 dice que se decide una vez.

### 🔴 Ejercicio 24 — La circular de precios, por el cluster
Cambia el precio fijo de G0 en una copia de `pricing`, construye una imagen con otro tag, y llévala al
cluster sin que el `Service` deje de contestar.

**Criterio:** el precio nuevo respondiendo, y una serie de `curl` cada medio segundo durante el
cambio, sin errores.

**Rúbrica:** los pasos (tag nuevo, carga, `set image` o `apply`); la serie; y qué te faltó para que
fuera un martes de verdad (las sondas de la [Fase 15](15-salud-y-recursos.md) y el rollout de la 16).

---

## 📚 16. Referencias

**Documentación oficial** (la versión 1.36 de [a01](a01-el-laboratorio.md))

- Kubernetes, *Deployments*: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Kubernetes, *ReplicaSet*: https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/
- Kubernetes, *Service*: https://kubernetes.io/docs/concepts/services-networking/service/
- Kubernetes, *DNS for Services and Pods*: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/
- Kubernetes, *Images*, `imagePullPolicy`: https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy

**Libros**

- Brendan Burns, Joe Beda, Kelsey Hightower y Lachlan Evenson, *Kubernetes: Up and Running*, 3.ª
  edición (2022), los capítulos de pods, `ReplicaSet` y `Deployment`.

**Orden de lectura sugerido:** antes, la página de `Deployment` hasta "Updating a Deployment";
durante, la de `Service`; después, la de DNS, con tu `/etc/resolv.conf` delante.

> ⚠️ Las URL y los contenidos cambian; las de Kubernetes tienen selector de versión.

---

## 🏁 17. Resultado de la fase

```text
EL CLUSTER AL CERRAR LA FASE 08 (minimo, namespace default)

  Service pricing (ClusterIP 10.96.x.x:8080)
        │ selector: app.kubernetes.io/name=pricing
        ▼
  EndpointSlice ──► pod pricing-<hash>-<id>   lab/pricing:g0   1/1 Running
                        ▲
  Deployment pricing ──► ReplicaSet pricing-<hash> (1 de 1) ── el bucle: lo borras, vuelve en 0,5 s
```

> **La señal de que quedó bien:** *"Borro el pod sin miedo, porque sé quién lo vuelve a crear; y sé
> leer en los eventos por qué un pod no arranca."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde y `git status` limpio:
>
> ```bash
> git tag -a fase-08-el-primer-despliegue -m "F08 cerrada: Deployment y Service de pricing a mano en default; el bucle en vivo; DNS del cluster; task inc:break; incidentes 05 y 06"
> ```
>
> Y los pares de los incidentes: `inc/05/image-never-loaded-roto` e `inc/05/image-never-loaded-fix`,
> `inc/06/service-no-endpoints-roto` e `inc/06/service-no-endpoints-fix`. Commits de la fase con
> prefijo `f08:`, los de ejercicio `f08 ej17: …` ([convención de git](00-convencion-de-git-y-tags.md)).

---

## 📌 Pendientes sugeridos

- **F16:** el ejercicio 9 (el rollout que no baja el pod viejo) es la entrada natural a
  `maxUnavailable` y `maxSurge`.
- **F15:** la apuesta de la sección 7 con `inventory` (el ejercicio 15) es el "antes" de las sondas.
