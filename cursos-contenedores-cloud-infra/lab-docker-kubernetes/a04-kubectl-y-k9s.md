# 📎 Apéndice a04 — `kubectl` y k9s
## Laboratorio de contenedores y Kubernetes local

> **Curso:** Laboratorio de contenedores y Kubernetes local · Consulta
> **Usado por:** las fases de la Parte II y la [Fase 21](21-diagnostico.md) · **Versiones cubiertas:** las de [a01](a01-el-laboratorio.md)
> **Fecha de verificación ejecutada:** 03/10/2026 a 05/10/2026 (cada entrada, con la fase que la estrena; k9s y las salidas, el 05/10/2026) · macOS arm64

**Esto no se lee de corrido.** Se entra por el índice buscando algo concreto y se sale. Es la
referencia rápida de los comandos de todos los días, ordenada por **la pregunta que te estás
haciendo** y no por el verbo, porque cuando un pod no arranca no piensas *"necesito `describe`"*:
piensas *"¿qué le pasa?"*.

**Qué queda fuera:** los objetos de Kubernetes y sus campos, que los explica la fase que los estrena;
y la administración del cluster (nodos, certificados del plano de control, actualizaciones), que
este curso no cubre.

> 📝 **Este apéndice creció con el curso** y está completo: cada fase le sumó los comandos que estrenó. Los atajos
> de k9s no van entrada por entrada: están juntos en [Lo mismo, en k9s](#-lo-mismo-en-k9s), con la pregunta a la que
> responde cada uno.

---

## Índice

- [Cómo es una entrada](#-cómo-es-una-entrada)
- [¿En qué cluster y en qué namespace estoy?](#-en-qué-cluster-y-en-qué-namespace-estoy)
- [¿Qué hay?](#-qué-hay)
- [¿Qué le pasa?](#-qué-le-pasa)
- [¿Qué dice?](#-qué-dice)
- [Quiero entrar](#-quiero-entrar)
- [Quiero llegarle desde mi máquina](#-quiero-llegarle-desde-mi-máquina)
- [Quiero depurar algo que no tiene shell](#-quiero-depurar-algo-que-no-tiene-shell)
- [Lo mismo, en k9s](#-lo-mismo-en-k9s)
- [Las salidas que conviene leer](#-las-salidas-que-conviene-leer)
- [Cuándo usar qué](#-cuándo-usar-qué)
- [Advertencias](#️-advertencias)
- [Referencias](#-referencias)
- [Ejercicios](#-ejercicios-10)

---

## 🧾 Cómo es una entrada

Cada entrada responde una pregunta concreta, con los nombres del laboratorio y nunca con ejemplos
de juguete. Siempre la misma forma:

````markdown
### La pregunta, como te la haces

```bash
kubectl … -n apps …        # el comando, con los nombres del contrato
```

```text
la salida real, recortada solo donde se dice
```

**Qué mirar:** la línea o la columna que contesta la pregunta.
**Estrenado en:** la fase.
````

---

## 🧭 ¿En qué cluster y en qué namespace estoy?

Contextos, el namespace por defecto de cada uno, y cómo no aplicar un manifiesto en el cluster
equivocado. Es lo primero que se rompe cuando hay dos clusters en la misma máquina, y en este
laboratorio hay dos perfiles.

### ¿En qué cluster estoy?

```bash
kubectl config current-context
kubectl config get-contexts
```

```text
CURRENT   NAME             CLUSTER          AUTHINFO         NAMESPACE
          docker-desktop   docker-desktop   docker-desktop
*         kind-lab         kind-lab         kind-lab
```

**Qué mirar:** el `*`. Si no hay ninguno, `current-context` dice `error: current-context is not set`, y
cualquier `kubectl` le habla a `localhost:8080`, que en este laboratorio es la puerta del `Gateway`. Queda así, por
ejemplo, después de crear y borrar otro cluster de kind ([a13](a13-respaldo-y-restauracion.md)): `kubectl config
use-context kind-lab`.
**Estrenado en:** [Fase 07](07-el-cluster-local.md).

### No depender del contexto activo

```bash
kubectl --context kind-minimo -n apps get pods
```

**Qué mirar:** si el contexto no existe, el comando falla (`context was not found for specified
context: kind-lab`) en vez de aplicarse en otro cluster. Es lo que hacen todas las tareas del Taskfile.
**Estrenado en:** [Fase 07](07-el-cluster-local.md).

### Un namespace por defecto para el contexto

```bash
kubectl config set-context kind-minimo --namespace=apps
```

**Qué mirar:** la columna `NAMESPACE` de `get-contexts`. Cómodo para escribir; los scripts no confían
en él.
**Estrenado en:** [Fase 07](07-el-cluster-local.md).

---

## 🔍 ¿Qué hay?

Listar objetos, filtrarlos por label y por namespace, y ver todo lo que corre de una vez.

### Todo lo de un servicio, de una vez

```bash
kubectl get deploy,rs,pods -l app.kubernetes.io/name=pricing
```

**Qué mirar:** la escalera: el `Deployment` (`READY 1/1`), su `ReplicaSet` con el hash del molde, y el
pod con el mismo hash en el nombre.
**Estrenado en:** [Fase 08](08-el-primer-despliegue.md).

### El sistema entero, en cualquier namespace

```bash
kubectl get pods -A -l app.kubernetes.io/part-of=lab -o wide
```

**Qué mirar:** `NAMESPACE`, `READY` (`2/2` en `catalog`, que son dos contenedores) y `NODE`.
**Estrenado en:** [Fase 09](09-los-cuatro-servicios-dentro.md).

### Detrás de un `Service`

```bash
kubectl get endpointslices -l kubernetes.io/service-name=pricing
```

**Qué mirar:** `ENDPOINTS`. `<unset>` es un `Service` sin pods detrás (incidente 06).
**Estrenado en:** [Fase 08](08-el-primer-despliegue.md).

### La configuración que recibió un pod, y la que dice el objeto

```bash
kubectl -n apps exec deploy/storefront -- printenv API_BASE_URL BRAND_NAME
kubectl -n apps get configmap storefront-config -o yaml
kubectl -n legacy get secret portal-contingencia -o jsonpath='{.data.CONTINGENCIA_SOAP_PASSWORD}' | base64 -d
```

**Qué mirar:** si el objeto y el pod dicen lo mismo. Si no, el pod arrancó antes del cambio y hace
falta `kubectl rollout restart deployment/<nombre>` (incidente 09). El `Secret` sale en base64, que se
deshace sin clave.
**Estrenado en:** [Fase 11](11-configuracion-y-secretos.md).

### Los discos, y de quién es cada uno

```bash
kubectl -n data get pvc
kubectl get pv
kubectl get storageclass
```

**Qué mirar:** el PVC en `Bound` y su `VOLUME`; el PV con su `CLAIM` (namespace/nombre); y que la
`STORAGECLASS` del PVC exista en `get storageclass`. El PV y la `StorageClass` no son de ningún
namespace.
**Estrenado en:** [Fase 12](12-estado-y-almacenamiento.md).

---

## 🩺 ¿Qué le pasa?

El estado de un objeto, sus condiciones y sus eventos: el `describe` que se lee de abajo hacia
arriba, y los eventos del namespace ordenados por tiempo.

### Por qué un pod no arranca

```bash
kubectl describe pod -l app.kubernetes.io/name=pricing
```

**Qué mirar:** `Events:`, al final, de abajo hacia arriba. `Failed to pull image …` es la imagen; un
`FailedScheduling` es el nodo; `Error: secret "…" not found`, con el pod en `CreateContainerConfigError`,
es configuración que el pod pide y no existe (incidente 10).
**Estrenado en:** [Fase 08](08-el-primer-despliegue.md); `CreateContainerConfigError`, en la [Fase 11](11-configuracion-y-secretos.md).

### Qué hicieron los controladores

```bash
kubectl get events --sort-by=.lastTimestamp | tail
```

**Qué mirar:** el orden: `SuccessfulCreate` (el `ReplicaSet`), `Scheduled` (el planificador),
`Pulled`, `Created`, `Started` (el `kubelet`). Los eventos se borran solos con el tiempo.
**Estrenado en:** [Fase 08](08-el-primer-despliegue.md).

### Si el deseo se cumplió

```bash
kubectl get deploy pricing -o jsonpath='{.metadata.generation} {.status.observedGeneration} {.status.replicas} {.status.readyReplicas}{"\n"}'
```

**Qué mirar:** generación igual a generación observada, y réplicas listas igual a las pedidas.
**Estrenado en:** [Fase 08](08-el-primer-despliegue.md).

### Por qué un pod con disco no arranca

```bash
kubectl -n data describe pvc data-postgres-0 | sed -n '/^Events:/,$p'
```

**Qué mirar:** con el pod en `Pending`, los eventos del pod dicen que espera un PVC; los del PVC dicen
por qué: `storageclass.storage.k8s.io "…" not found` es una clase que no existe (incidente 11). En
Windows, sin `sed`: `kubectl describe pvc` entero, y los eventos al final.
**Estrenado en:** [Fase 12](12-estado-y-almacenamiento.md).

### Si la puerta aceptó una ruta

```bash
kubectl -n apps get httproute pricing -o jsonpath='{.metadata.generation}{"\n"}{range .status.parents[*]}{.parentRef.name}/{.parentRef.namespace}{"\n"}{range .conditions[*]}{.type}={.status} {.reason} {.observedGeneration}{"\n"}{end}{end}'
```

**Qué mirar:** `Accepted=True` y `ResolvedRefs=True`, **con la misma generación** que el objeto. Si la
`observedGeneration` es menor, el `status` es de una versión anterior y no dice nada de la actual
(incidente 08). `ResolvedRefs=False` trae la razón: un `ReferenceGrant` que falta o un filtro que el
controlador no implementa. `RouteRulesOverlap=True` dice que otra ruta pide el mismo host y el mismo
camino en la misma puerta: gana la más vieja, y la otra no recibe nada ([Fase 14](14-helm-en-operacion.md#-8-la-rotura-la-segunda-cadena-que-se-queda-con-el-tráfico)).
**Estrenado en:** [Fase 10](10-la-entrada-al-sistema.md).

### Quién cambió un campo, y quién es su dueño

```bash
kubectl -n apps get deploy pricing -o jsonpath='{range .metadata.managedFields[*]}{.manager} {.operation}{"\n"}{end}'
```

```text
helm Apply
kubectl-client-side-apply Update
kube-controller-manager Update
kubectl-set Update
```

**Qué mirar:** cada escritor del objeto. `helm Apply` es el chart; `kubectl-set`, `kubectl-edit` o
`kubectl-patch` son cambios a mano, y son los que hacen fallar un `task deploy` con `conflict with
"kubectl-set"`. `kubectl-client-side-apply` es un `kubectl apply` de antes de Helm. Para ver qué campos
tiene cada uno, `-o yaml --show-managed-fields`.
**Estrenado en:** [Fase 13](13-helm-el-paquete.md).

### Por qué murió un contenedor que no dejó log

```bash
kubectl -n apps describe pod <pod> | sed -n '/Last State/,/Restart Count/p'
kubectl -n apps logs <pod> --previous | tail -3
docker exec minimo-control-plane dmesg | grep -i 'killed process' | tail -1   # en el nodo
```

**Qué mirar:** `Reason: OOMKilled` y `Exit Code: 137` (128 + 9: `SIGKILL`) es el kernel matando por el
límite del cgroup; el proceso no alcanza a escribir nada, y el `--previous` termina en una línea
normal. `Exit Code: 1` sin `OOMKilled` es el propio proceso saliendo con error: ahí el `--previous` sí
dice por qué (incidente 12).
**Estrenado en:** [Fase 15](15-salud-y-recursos.md).

### Por qué un pod corre y no recibe tráfico

```bash
kubectl -n apps describe pod <pod> | grep -E 'Unhealthy|Killing'
kubectl -n apps get endpointslices -l kubernetes.io/service-name=pricing -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]} ready={.conditions.ready}{"\n"}{end}'
```

**Qué mirar:** `Readiness probe failed` con el código o el error, y el endpoint en `ready=false`. Un
`Killing … failed liveness probe` es la otra sonda, la que reinicia. El porqué lo dice el log del servicio
(G4 escribe una línea por cada "no listo").
**Estrenado en:** [Fase 15](15-salud-y-recursos.md).

### Cuánta memoria usa cada contenedor, sin metrics-server

```bash
docker exec minimo-control-plane crictl stats --label io.kubernetes.pod.namespace=apps
docker exec minimo-control-plane crictl ps --label io.kubernetes.pod.namespace=apps
```

**Qué mirar:** la columna `MEM` de `stats` (el *working set*), con el nombre del contenedor de `ps` para
cada ID. Es lo que cuenta el límite. Desde la [Fase 16](16-escalado-y-rollout.md), `kubectl top pod --containers` dice lo mismo.
**Estrenado en:** [Fase 15](15-salud-y-recursos.md).

### Cuánto se prometió y cuánto queda

```bash
kubectl describe node minimo-control-plane | sed -n '/Allocated resources:/,/Events:/p'
kubectl -n apps describe resourcequota apps
```

**Qué mirar:** en el nodo, la suma de `requests` contra lo asignable (`Allocatable`): un pod que no cabe
queda `Pending` con `Insufficient memory` (incidente 15). En la cuota, `Used` contra `Hard`: un pod que
no cabe ni siquiera se crea (`exceeded quota`).
**Estrenado en:** [Fase 15](15-salud-y-recursos.md).

### Cuánto consume cada pod, y qué ve el autoescalador

```bash
kubectl top pods -n apps --containers
kubectl -n apps get hpa
kubectl -n apps describe hpa pricing | sed -n '/Conditions:/,$p'
```

**Qué mirar:** en `top`, la CPU en milicores y la memoria de cada contenedor; necesita metrics-server
(`error: Metrics API not available` es que no está, o no está listo: incidente 17). En el HPA, `TARGETS`
(`cpu: 2%/70%`, o `<unknown>` si no tiene dato) y `REPLICAS`; en `Conditions`, por qué no escala.
**Estrenado en:** [Fase 16](16-escalado-y-rollout.md).

### Si un rollout terminó, se atascó o se rindió

```bash
kubectl -n apps rollout status deployment/inventory
kubectl -n apps get deploy inventory -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}{"\n"}{end}'
kubectl -n apps rollout undo deployment/inventory
```

**Qué mirar:** `Progressing=False ProgressDeadlineExceeded` es un rollout que se rindió (incidente 16); con
`maxUnavailable: 0`, las réplicas viejas siguen atendiendo. `rollout undo` vuelve a la versión anterior
del `Deployment` (con Helm, mejor `helm rollback`).
**Estrenado en:** [Fase 16](16-escalado-y-rollout.md).

### Qué mide Prometheus, y qué descartó

```bash
task obs:status                                                    # qué piezas están encendidas
curl -s -H 'Host: prometheus.localhost' 'http://127.0.0.1:8080/api/v1/targets?state=active'
curl -s -H 'Host: prometheus.localhost' 'http://127.0.0.1:8080/api/v1/query' \
  --data-urlencode 'query=count by (job) ({__name__=~".+"})'      # series por trabajo
kubectl -n apps exec deploy/pricing -- wget -qO- localhost:8080/metrics   # lo que publica un pod (si tiene shell)
```

**Qué mirar:** en los blancos, `health` y `lastError`: `down` con 404 es un servicio sin `/metrics`; un
blanco que no aparece no pasó los `relabel_configs` (en la interfaz, `Status → Service discovery` muestra
los descartados con sus metadatos). En las series por trabajo, el que crece sin parar tiene una etiqueta
con demasiados valores. `pricing` es distroless y no tiene `wget`: se lee por la puerta o desde un pod de
prueba.
**Estrenado en:** [Fase 17](17-metricas-y-dashboards.md).

### Qué certificado se sirve, quién lo firmó y cuándo vence

```bash
echo | openssl s_client -connect 127.0.0.1:8443 -servername api.localhost -CAfile .secrets/tls/ca.crt 2>/dev/null | \
  openssl x509 -noout -issuer -enddate -ext subjectAltName
kubectl get certificate -A                                     # READY, y el Secret de cada uno
kubectl get clusterissuer,certificaterequest -A
kubectl -n gateway get gateway lab -o jsonpath='{range .status.listeners[*]}{.name}: {range .conditions[*]}{.type}={.status} {end}{"\n"}{end}'
```

**Qué mirar:** en el certificado, las cuatro preguntas de la [Fase 19](19-tls-y-certificados.md): el *issuer* contra la CA del cliente,
`notAfter` contra hoy, el SAN contra el nombre de la URL, y en el listener, `ResolvedRefs` (la clave que no
corresponde). Un `Certificate` en `False` se sigue hacia abajo: su `CertificateRequest`, y el emisor. Y
`ResolvedRefs=True` no quiere decir que el certificado valga **hoy**: se validó al cargarlo.
**Estrenado en:** [Fase 19](19-tls-y-certificados.md).

### Quién puede qué, y quién llega a dónde

```bash
kubectl auth can-i get secret/pricing-db -n apps --as=system:serviceaccount:apps:default
kubectl auth can-i --list -n apps --as=system:serviceaccount:observability:prometheus
kubectl -n apps describe networkpolicy
kubectl -n apps get pods --show-labels                       # ¿alguna política elige a este pod?
kubectl -n apps exec deploy/replenish -- node -e "require('dns').lookup('pricing',(e,a)=>console.log(e?e.code:a))"
```

**Qué mirar:** en RBAC, `--as` pregunta por una identidad sin probar con un pod; un 403 dice el usuario, el verbo y el
recurso que faltan. En la red, una conexión rechazada **no da error**: espera. La prueba es desde adentro de un pod, por
nombre y por IP: si por IP pasa y por nombre no, es el DNS (incidente 26).
**Estrenado en:** [Fase 20](20-seguridad-del-pod-y-de-la-red.md).

### A qué réplica llega cada conexión

```bash
kubectl -n apps get endpointslices -l kubernetes.io/service-name=pricing     # las réplicas que el Service conoce
docker exec lab-worker iptables-save -t nat | grep "apps/pricing:grpc ->"     # el dado de kube-proxy, por réplica
docker exec lab-worker conntrack -L -p tcp --dport 9090                       # cada conexión, y a qué pod se tradujo
task measure -- B-23 --runs 1 --rate 20 --modes client                         # las llamadas que recibió cada réplica
```

**Qué mirar:** un `Service` elige réplica al **abrir la conexión**; con HTTP/2 o gRPC, una conexión lleva todas las
llamadas. En `conntrack`, la segunda dirección `src=` es el pod al que fue a parar. Las llamadas por réplica salen del
`/metrics` de cada pod, nunca del `Service` (cada lectura caería en una distinta).
**Estrenado en:** [Fase 23](23-grpc-y-el-balanceo.md).

### Lo que instaló Helm, y con qué valores

```bash
kubectl -n apps get secrets -l owner=helm      # un Secret por revisión del release
helm -n apps history lab                       # las revisiones, con su estado
helm -n apps get values lab                    # los valores que le diste (--all: los calculados)
helm -n apps get manifest lab --revision 7     # lo que renderizó esa revisión
```

**Qué mirar:** en `history`, una revisión `failed` entre dos `deployed` es un despliegue que pudo
quedar a medias; en `get manifest`, comparar dos revisiones dice qué cambió de verdad. Y lo que creó una revisión
fallida puede quedar huérfano: Helm borra solo lo que estaba en la última revisión buena. Un objeto con la anotación
`meta.helm.sh/release-name` que no aparece en `get manifest` es uno de esos ([Fase 23](23-grpc-y-el-balanceo.md)).
**Estrenado en:** [Fase 13](13-helm-el-paquete.md).

### Qué pasa si un pod muere sin apagarse

```bash
kubectl -n apps delete pod -l app.kubernetes.io/name=inventory,app.kubernetes.io/component=backend --grace-period=0 --force
```

```text
Warning: Immediate deletion does not wait for confirmation that the running resource has been terminated. The resource may continue to run on the cluster indefinitely.
pod "inventory-6fd949c487-9qpdg" force deleted from apps namespace
```

**Qué mirar:** el objeto desaparece de la API en el acto, pero el contenedor lo mata el kubelet después, y la
advertencia lo dice: en la [Fase 24](24-la-saga-orquestada.md), siete de diez préstamos alcanzaron a terminar
igual. Un `delete` normal, en cambio, corre el `preStop` y espera el apagado: no sirve para simular una caída.
Con un `StatefulSet` no lo uses nunca: dos pods con la misma identidad pueden quedar vivos a la vez.
**Estrenado en:** [Fase 24](24-la-saga-orquestada.md).

### Qué tiene pendiente el bus

```bash
kubectl -n data exec nats-0 -- wget -qO- "http://127.0.0.1:8222/jsz?consumers=true"
```

**Qué mirar:** en `consumer_detail`, `num_pending` (mensajes que el consumidor todavía no recibió) y `num_ack_pending`
(recibidos y sin confirmar). Con `replenish` apagado, `num_pending` crece con cada venta; al volver, baja a cero. El
monitoreo HTTP de NATS (el 8222) contesta JSON sin instalar la CLI de NATS.
**Estrenado en:** [Fase 25](25-la-coreografia.md).

### Reiniciar el proceso sin borrar el pod

```bash
kubectl -n apps exec deploy/replenish -- kill 1
kubectl -n apps get pods -l app.kubernetes.io/name=replenish,app.kubernetes.io/component=backend
```

**Qué mirar:** `RESTARTS` sube en uno y el pod es el mismo: el contenedor murió y el kubelet lo arrancó otra vez, sin
`rollout` ni pod nuevo, y sin un segundo pod que se solape con el primero. Es la forma de ver un hueco sin consumidor (en
la [Fase 25](25-la-coreografia.md), un segundo bastó para perder un aviso). Solo funciona si el proceso 1 atiende
`SIGTERM` ([Fase 03](03-el-contenedor-por-dentro.md)).
**Estrenado en:** [Fase 25](25-la-coreografia.md).

### Qué pasa si el proceso muere sin apagarse

```bash
docker exec $(kubectl -n apps get pod -l app.kubernetes.io/name=inventory,app.kubernetes.io/component=backend \
  -o jsonpath='{.items[0].spec.nodeName}') pkill -9 -f inventory-0.0.1-SNAPSHOT.jar
kubectl -n apps get pods -l app.kubernetes.io/name=inventory,app.kubernetes.io/component=backend
```

**Qué mirar:** `RESTARTS` sube y el pod es el mismo. Un `SIGKILL` desde el nodo es lo más parecido a un corte de luz:
sin `preStop`, sin apagado limpio, a mitad de lo que estuviera haciendo. Desde adentro del contenedor no se puede (el
kernel no le entrega `SIGKILL` al proceso 1 de su propio espacio de procesos), y `kubectl delete --force` tampoco lo hace
(la entrada anterior). El nodo de kind es un contenedor del motor: con Podman, `podman exec`.
**Estrenado en:** [Fase 26](26-idempotencia-y-outbox.md).

---

## 📜 ¿Qué dice?

Los logs de un contenedor, del que murió antes, de todos los pods de un `Deployment`, y siguiéndolos
en vivo.

### Los logs de un servicio

```bash
kubectl logs deploy/pricing
kubectl -n apps logs deploy/catalog -c nginx --tail=20
```

**Qué mirar:** `Found 2 pods, using pod/…` durante un rollout (eligió uno); con dos contenedores, `-c`
elige cuál. **Cuidado** cuando el pod del servicio no está listo: el selector del `Deployment` también toma el pod
terminado del `Job` de migraciones, y `kubectl` puede elegir ese (`using pod/replenish-migrate-…`); con
`-l app.kubernetes.io/name=replenish,app.kubernetes.io/component=backend` no hay duda. `--previous` muestra los del contenedor que murió antes del actual.
**Estrenado en:** [Fase 08](08-el-primer-despliegue.md) y, con `-c`, [Fase 09](09-los-cuatro-servicios-dentro.md).

### Los logs de todas las réplicas, y los de un pod que ya no está

```bash
kubectl -n apps logs -l app.kubernetes.io/name=inventory,app.kubernetes.io/component=backend --all-containers --prefix --since=10m
kubectl -n apps logs -l app.kubernetes.io/name=inventory,app.kubernetes.io/component=backend --prefix --tail=-1 | grep LOAN-000049
kubectl -n apps logs <pod> --previous            # la vida anterior de un contenedor reiniciado, solo una
kubectl -n apps logs <pod> | grep '"msg":"request"' | tail -5
```

**Qué mirar:** con `-l`, las líneas de todas las réplicas, con `--prefix` para saber de cuál es cada una. Lo
de un pod borrado ya no está aquí: está en Loki si los logs estaban encendidos (`{service="inventory"} |
json | request_id="…"`, desde Grafana). Una línea que no empieza con `{` es algo que el runtime escribió en
texto. **Con `-l` y sin `--since`, `kubectl` muestra solo las últimas 10 líneas de cada pod**; para buscar algo
viejo, `--tail=-1` (en la [Fase 24](24-la-saga-orquestada.md), la réplica que compensó un préstamo no aparecía sin él).
**Estrenado en:** [Fase 18](18-logs.md); `--tail=-1`, en la [Fase 24](24-la-saga-orquestada.md).

### Una venta, por su `trace_id`

```bash
kubectl -n apps logs deploy/inventory --since=5m | grep '"uri":"/sales"'   # el trace_id de cada venta
task obs:trace -- <trace_id>                                                # la traza, como árbol de tiempos
```

**Qué mirar:** la diferencia entre un span de cliente y el de servidor que le contesta es red, TLS o conexión; la
traza dice dónde se fue el tiempo, el log dice qué pasó. Si llegan solo los spans de `catalog`, espera unos segundos:
los otros tres exportan en lotes.
**Estrenado en:** [Fase 23](23-grpc-y-el-balanceo.md).

### Lo que dice un *sidecar*

```bash
kubectl -n apps logs deploy/inventory -c outbox-relay --since=5m
kubectl -n apps get pod -l app.kubernetes.io/name=inventory,app.kubernetes.io/component=backend \
  -o jsonpath='{.items[0].spec.initContainers[*].name} {.items[0].status.initContainerStatuses[*].started}'
```

**Qué mirar:** un *sidecar* nativo es un `initContainer` con `restartPolicy: Always`: aparece en `READY` (2/2), pero sus
logs se piden con `-c` y su estado está en `initContainerStatuses`, no en `containerStatuses`. Sin `-c`, `kubectl logs`
elige el contenedor principal.
**Estrenado en:** [Fase 26](26-idempotencia-y-outbox.md).

### Lo que dijo un `Job`, y las corridas de un `CronJob`

```bash
kubectl -n apps logs job/pricing-migrate
kubectl -n legacy get cronjob braqui-traslados
kubectl -n legacy get jobs -l app.kubernetes.io/name=braqui-traslados
```

**Qué mirar:** el log del `Job` antes de que `ttlSecondsAfterFinished` lo borre; en el `CronJob`,
`LAST SCHEDULE` y `ACTIVE`; y en sus `Job`, `COMPLETIONS` y `DURATION`. Un `Job` terminado no se edita:
se borra y se crea de nuevo.
**Estrenado en:** [Fase 12](12-estado-y-almacenamiento.md).

---

## 🚪 Quiero entrar

Ejecutar un comando dentro de un contenedor que sí tiene shell, y qué hacer cuando no lo tiene.

### Un comando dentro de un contenedor

```bash
kubectl -n apps exec deploy/inventory -- env
kubectl -n apps exec deploy/catalog -c php-fpm -- ps -o pid,args
```

**Qué mirar:** con dos contenedores, `-c`. Los que no tienen shell (`pricing`) no aceptan `exec … sh`:
eso es otra entrada.
**Estrenado en:** [Fase 09](09-los-cuatro-servicios-dentro.md).

### Un pod de prueba, que se borra solo

```bash
kubectl run cliente --rm --attach --restart=Never --quiet --image=nginxinc/nginx-unprivileged@sha256:ed04ec1ff34502c339ee5c3ae3f855442398edc1d05591e2b98981dcbbd20b1e -- curl -s http://pricing:8080/health/live
```

**Qué mirar:** el namespace del cliente decide cómo resuelve el nombre corto. Dentro de un script,
`--attach` y no `-i`, o el comando se come el resto del script.
**Estrenado en:** [Fase 08](08-el-primer-despliegue.md).

---

## 🔌 Quiero llegarle desde mi máquina

Reenviar un puerto de un pod o de un `Service` al host, y cuándo eso miente sobre cómo llega el
tráfico de verdad.

### Por la puerta, y dónde quedó su proxy

```bash
curl -sS -i http://api.localhost:8080/pricing/health/live
kubectl -n gateway get pods -o wide -l gateway.envoyproxy.io/owning-gateway-name=lab
```

**Qué mirar:** un 404 con `content-length: 0` es de la puerta, no del servicio. Y la columna `NODE`
del proxy: en el perfil `lab` puede caer en un worker, y con `externalTrafficPolicy: Local` el host no
le llega.
**Estrenado en:** [Fase 10](10-la-entrada-al-sistema.md).

### Saltarse la puerta: un túnel al `Service`

```bash
kubectl -n apps port-forward svc/pricing 18080:8080        # localhost:18080 → el Service, sin la puerta
curl -s 'http://127.0.0.1:18080/prices?store=DRO-007'
```

**Qué mirar:** si por el túnel contesta y por la puerta no, el problema está entre las dos (la ruta, el listener). El
túnel lo abre el kubelet dentro del pod: se salta la puerta **y las `NetworkPolicy`**, y por eso su permiso
(`pods/portforward`) es serio.
**Estrenado en:** [Fase 21](21-diagnostico.md).

---

## 🧰 Quiero depurar algo que no tiene shell

Un contenedor efímero junto al que falla, con las herramientas que la imagen no trae.

```bash
kubectl -n apps debug <pod> --image=busybox@sha256:bdf57e528e45e4433820e045b29b4597825a1c9e38353532d90a01445013f82e \
  --target=pricing --container=dbg -- sleep 300
kubectl -n apps exec <pod> -c dbg -- ps -o pid,user,args          # los procesos del contenedor objetivo
kubectl -n apps exec <pod> -c dbg -- ls /proc/1/root/             # su sistema de archivos
kubectl -n apps exec <pod> -c jdk -- jcmd 1 VM.flags              # con un efímero del JDK sobre inventory
```

**Qué mirar:** sin `--target`, el efímero no ve los procesos. El efímero hereda el `runAsUser` del pod: con el de la
[Fase 20](20-seguridad-del-pod-y-de-la-red.md), corre como el servicio, y eso es lo que deja adjuntarse a la JVM con `jcmd` (como root, no). No se
puede quitar: vive hasta que el pod se va.
**Estrenado en:** [Fase 21](21-diagnostico.md).

---

## 🐶 Lo mismo, en k9s

k9s ([a01](a01-el-laboratorio.md)) es una terminal sobre la misma API: lo que hace `kubectl`, con una tecla. Se abre
contra un contexto y un namespace, igual que los comandos de arriba:

```bash
k9s --context kind-lab -n apps              # o --readonly, para mirar sin poder romper
```

```text
 Context: kind-lab [R]                             <0> all       <d>       Describe        <o> Show Node
 Cluster: kind-lab                                 <1> apps      <?>       Help            <f> Show PortForward
 K9s Rev: v0.51.0                                                <l>       Logs            <y> YAML
 K8s Rev: v1.36.4                                                <p>       Logs Previous
                                                                 <shift-f> Port-Forward
┌──────────────────────────────── pods(apps)[9] ────────────────────────────────┐
│ NAME↑                          PF   READY   STATUS     RESTARTS   CPU   MEM  … │
│ inventory-7dbc8c44d5-k2m6f     ●    2/2     Running           0     7   351  … │
```

| La pregunta | En `kubectl` | En k9s |
|---|---|---|
| ¿en qué cluster estoy? | `config get-contexts` | `:ctx` |
| ¿qué hay? | `get pods`, `get deploy` | `:pods`, `:deploy` (cualquier tipo, por su nombre corto) |
| …en todos los namespaces | `-A` | `0` (y `1`, `2`… para los favoritos) |
| solo lo de un servicio | `-l app.kubernetes.io/name=…` | `/inventory` (filtro), `esc` para quitarlo |
| ¿qué le pasa? | `describe` | `d` sobre la fila |
| ¿qué hicieron los controladores? | `get events --sort-by=.lastTimestamp` | `:events` |
| ¿qué dice? | `logs` · `logs --previous` | `l` · `p` (en un pod de varios contenedores, `l` los muestra todos con su nombre delante) |
| el objeto entero | `-o yaml` | `y` |
| llegarle desde mi máquina | `port-forward` | `shift-f` |
| ¿de quién es este pod? | `get … -o jsonpath='{.metadata.ownerReferences}'` | `shift-j` |
| la ayuda | `--help` | `?` |

Con `--readonly`, el contexto lleva `[R]` y desaparecen del menú los atajos que cambian algo; `ctrl-d` no hace nada.
Sin él, `[RW]`, y la vista de pods suma `s` (entrar), `e` (editar), `ctrl-d` (borrar), `ctrl-k` (matar), `a` (*attach*)
y `t` (copiar archivos). Para mirar, `--readonly`.

> ⚠️ **k9s recuerda la última vista y el namespace de cada contexto** (en su carpeta de configuración, por cluster). El
> próximo `k9s` abre donde lo dejaste, no en los pods: si abre en otro sitio, es eso.

**Qué no hace bien:** dejar el comando escrito. Un incidente se cuenta con el `kubectl` que lo mostró, no con la tecla
que lo encontró. Y la tabla no muestra los eventos que ya pasaron en la vista de pods: `:events` aparte.
**Verificado el:** 05/10/2026, con k9s manejado desde un pseudo-terminal en modo `--readonly`.

---

## 📐 Las salidas que conviene leer

**`-o wide`** suma a `get` las columnas que más se preguntan: la IP y el nodo de cada pod. Es lo primero para *"¿están
todas las réplicas en el mismo nodo?"* ([a15](a15-statefulset-de-varios-miembros.md)).

```text
$ kubectl -n apps get pods -o wide
NAME                          READY   STATUS      RESTARTS   AGE   IP            NODE          …
inventory-7dbc8c44d5-k2m6f    2/2     Running     0          60m   10.244.1.23   lab-worker2   …
```

**`-o yaml`** es el objeto entero, con `status` y `managedFields`: 210 líneas para el `Deployment` de `inventory`. Para
leerlo de una vez, no para buscar un campo; para eso, lo que sigue.

**`custom-columns`** arma una tabla con los campos que quieras. La que más se usó en el curso, qué imagen corre cada
servicio:

```text
$ kubectl -n apps get deploy -o custom-columns=NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image
NAME         IMAGE
catalog      lab/catalog:g10
inventory    lab/inventory:g13
pricing      lab/pricing:g10
replenish    lab/replenish:g13
storefront   lab/storefront:g5
```

**`jsonpath`** saca un valor, o una lista con `range`. Las cuatro que el curso repite:

```bash
# ¿el controlador vio mi último cambio, y cuántas réplicas tiene listas? (Fases 08 y 16)
kubectl -n apps get deploy inventory \
  -o jsonpath='{.metadata.generation} {.status.observedGeneration} {.status.replicas} {.status.readyReplicas}{"\n"}'
# 110 110 1 1

# ¿qué contenedores tiene el pod, y con qué imagen? (Fase 09; los sidecar nativos están en initContainers, Fase 26)
kubectl -n apps get pod -l app.kubernetes.io/name=inventory \
  -o jsonpath='{range .items[0].spec.initContainers[*]}{.name}{"  "}{.restartPolicy}{"\n"}{end}'
# outbox-relay  Always

# ¿la puerta aceptó cada ruta? (Fase 10)
kubectl -n apps get httproute \
  -o jsonpath='{range .items[*]}{.metadata.name}: {range .status.parents[*].conditions[*]}{.type}={.status} {end}{"\n"}{end}'
# inventory: Accepted=True ResolvedRefs=True

# ¿quién es dueño de cada campo? (Fase 13, a12)
kubectl -n apps get deploy inventory \
  -o jsonpath='{range .metadata.managedFields[*]}{.manager} {.operation}{"\n"}{end}'
```

> ⚠️ El `READY 2/2` de `inventory` cuenta el *sidecar* `outbox-relay`, pero `.spec.containers[*]` solo lista
> `inventory`: un *sidecar* nativo vive en `.spec.initContainers` con `restartPolicy: Always`
> ([Fase 26](26-idempotencia-y-outbox.md)). Una consulta que solo mira `containers` no lo ve.

---

## 🧭 Cuándo usar qué

| Situación | Primero | Por qué |
|---|---|---|
| un pod no arranca | `describe pod`, abajo del todo | los eventos dicen qué falta: imagen, disco, `Secret`, cuota |
| un pod corre y no recibe tráfico | `get endpointslices`, y la readiness en `describe` | el `Service` solo manda a los listos |
| un contenedor murió sin log | `describe pod` (`Last State`) y `logs --previous` | `OOMKilled` y el código de salida están en el estado |
| no sé qué cambió | `get events -A --sort-by=.lastTimestamp` y `managedFields` | lo que hicieron los controladores, y quién tocó cada campo |
| algo de la puerta no contesta | las condiciones de la `HTTPRoute` y del `Gateway` | `Accepted` y `ResolvedRefs` dicen si la ruta existe para la puerta |
| la imagen no tiene shell | `kubectl debug --target` | un contenedor efímero que ve los procesos |
| recorrer el cluster mirando | k9s, con `--readonly` | una tecla por pregunta, sin riesgo |
| contarlo en un incidente | el `kubectl` con su salida | se pega, se repite y se automatiza |

---

## ⚠️ Advertencias

- **Sin `--context`, el comando va al contexto activo**, que puede ser otro cluster o ninguno. Las tareas del Taskfile
  siempre lo pasan; tus comandos sueltos, no.
- **`kubectl delete pod` no es una caída**: el pod se despide (`preStop`, `SIGTERM`, período de gracia). Para ver una
  caída de verdad, `kill -9` al proceso desde el nodo ([Fase 26](26-idempotencia-y-outbox.md); en
  [a15](a15-statefulset-de-varios-miembros.md), 1 publicación fallida contra 47).
- **`kubectl scale` o `kubectl set` sobre algo que instaló Helm** crea una deriva que el próximo `task deploy` choca o
  deshace ([Fase 13](13-helm-el-paquete.md)): despliega con `FORCE=true` después.
- **`logs` sin `--tail` y sin `--since`** trae lo que el runtime guardó, que en un pod viejo es mucho; y sin
  `--previous`, nada del contenedor que murió.
- **`port-forward` llega a un pod**, no al `Service`: no balancea, y se corta si ese pod se va.
- **Los atajos de k9s cambian entre versiones** más que los verbos de `kubectl`; la tabla es de la 0.51.0.

---

## 📚 Referencias

- `kubectl`, *Quick Reference*: https://kubernetes.io/docs/reference/kubectl/quick-reference/
- `kubectl`, *JSONPath Support*: https://kubernetes.io/docs/reference/kubectl/jsonpath/
- `kubectl`, *Output options* (`custom-columns`, `wide`): https://kubernetes.io/docs/reference/kubectl/#output-options
- Kubernetes, *Debug Running Pods* (contenedores efímeros): https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- k9s, *Commands* y *Key Bindings*: https://k9scli.io/topics/commands/
- k9s, *Configuration* (dónde guarda su estado): https://k9scli.io/topics/config/

> ⚠️ Las URL y los contenidos cambian; la referencia de `kubectl` apunta a la versión vigente, no a la 1.36.

---

## 🧪 Ejercicios (10)

### 🟢 Ejercicio 1 — El contexto, antes que nada
Deja el contexto activo vacío (`kubectl config unset current-context`), corre `kubectl get pods` y vuelve a `kind-lab`.

**Criterio:** el error exacto sin contexto, y el `*` de vuelta en `kind-lab`.

### 🟢 Ejercicio 2 — Qué imagen corre
Con una sola línea, la imagen de cada `Deployment` de `apps` y de `apps-b`.

**Criterio:** una tabla con namespace, nombre e imagen, sin `grep`.

### 🟢 Ejercicio 3 — El mismo pod, en k9s
Encuentra en k9s el pod de `inventory`, su `describe` y sus logs, sin escribir su nombre.

**Criterio:** las tres teclas que usaste, y en qué nodo corre (sale en la fila).

### 🟡 Ejercicio 4 — El sidecar escondido
Escribe una consulta que liste **todos** los contenedores de un pod: los de `containers` y los *sidecar* nativos de
`initContainers`.

**Criterio:** para `inventory`, `inventory` y `outbox-relay`, cada uno con su imagen.

### 🟡 Ejercicio 5 — Los eventos de la última hora
Lista los eventos `Warning` de todo el cluster, del más nuevo al más viejo.

**Criterio:** el comando con `--field-selector type=Warning`, y una línea sobre el más reciente.

### 🟡 Ejercicio 6 — ¿Quién reinició?
Encuentra los pods con más reinicios en todo el cluster, ordenados.

**Criterio:** la consulta con `--sort-by` sobre `restartCount`, y la causa del primero según su `Last State`.

### 🟠 Ejercicio 7 — El dueño de un campo
Cambia a mano las réplicas de `pricing` y averigua quién es ahora el dueño de `spec.replicas`.

**Criterio:** el `manager` antes y después, y el `task deploy FORCE=true` que lo devuelve.

### 🟠 Ejercicio 8 — Una caída que se despide y una que no
Mata el pod de `replenish` con `delete` y con `kill -9` desde el nodo, mirando los logs con `-f` en otra terminal.

**Criterio:** las últimas líneas de cada caso (con y sin el apagado limpio) y el `RESTARTS` que cambia en una y no en
la otra.

### 🔴 Ejercicio 9 — Tu propio `custom-columns`
Arma una vista de los pods de `apps` con nombre, nodo, QoS, reinicios y el pedido de memoria del primer contenedor.

**Criterio:** la tabla, y los pods `BestEffort` del cluster (los hay: di de quién son).

### 🔴 Ejercicio 10 — El diagnóstico sin k9s y sin Grafana
Con la observabilidad apagada, rompe la readiness de `catalog` (un `kubectl set env` que apunte a una base que no existe)
y encuentra la causa solo con este apéndice.

**Criterio:** la secuencia de comandos, en el orden de la tabla de cuándo usar qué, hasta la línea de log que la explica;
y la deriva devuelta con `task deploy FORCE=true`.

---

> 🏷️ **Este apéndice no lleva tag propio.** No deja archivos en el repositorio: sus entradas viven
> en este documento.
