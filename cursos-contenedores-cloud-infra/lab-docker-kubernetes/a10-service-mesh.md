# 📎 Apéndice a10 — Service mesh: mTLS, reintentos y métricas sin tocar el código

> **Curso:** Laboratorio de contenedores y Kubernetes local · 🔥 Ampliación
> **Usado por:** [Fase 19](19-tls-y-certificados.md) (el mTLS a mano), [Fase 22](22-resiliencia-y-caos.md) (los reintentos), [Fase 23](23-grpc-y-el-balanceo.md) (el balanceo por llamada) · **Versiones cubiertas:** las de [a01](a01-el-laboratorio.md)
> **Memoria que suma al perfil `lab`:** 148 MiB con Istio ambient en reposo (istiod, el CNI y ztunnel en tres nodos), unos 200 MiB con `apps` en el mesh y un *waypoint*; la máquina virtual subió 326 MiB al instalarlo
> **Fecha de verificación ejecutada:** 05/10/2026 · macOS arm64 con Docker Desktop, cluster `lab`

**Esto no se lee de corrido.** Se entra por el índice buscando algo concreto y se sale. Tres fases del curso escribieron
a mano algo que un *service mesh* promete dar sin tocar el código: el mTLS entre `inventory` y `pricing` (cert-manager,
G8), los reintentos (Resilience4j, G9) y el reparto de llamadas gRPC (G10). Este apéndice instala **Istio en modo
ambient** (D15) en el cluster del curso y lo pone a prueba contra esas tres.

**Qué queda fuera:** el modo *sidecar* de Istio; las políticas de autorización (`AuthorizationPolicy`), que se nombran;
el mesh entre clusters.

---

## Índice

- [Ambient: un mesh sin proxy en cada pod](#ambient-un-mesh-sin-proxy-en-cada-pod)
- [Instalarlo, y lo que pesa](#instalarlo-y-lo-que-pesa)
- [mTLS con una etiqueta](#mtls-con-una-etiqueta)
- [Capa 7: el waypoint, y la red que lo deja sin configuración](#capa-7-el-waypoint-y-la-red-que-lo-deja-sin-configuración)
- [Reintentos sin tocar el código](#reintentos-sin-tocar-el-código)
- [Métricas por servicio y por código](#métricas-por-servicio-y-por-código)
- [Sacarlo](#sacarlo)
- [Linkerd y Cilium](#linkerd-y-cilium)
- [Cuándo usar qué](#-cuándo-usar-qué)
- [Referencias](#-referencias)
- [Ejercicios](#-ejercicios-6)

---

## Ambient: un mesh sin proxy en cada pod

Un mesh clásico pone un proxy al lado de cada pod (*sidecar*), que intercepta todo lo que entra y sale. Ambient lo parte
en dos capas:

- **ztunnel**, un proceso por nodo (un `DaemonSet`), que lleva el tráfico de los pods del mesh por un túnel con mTLS
  (HBONE, al puerto 15008) y le pone a cada extremo una identidad. Es capa 4: conexiones, no peticiones.
- **El *waypoint***, un Envoy por namespace o por servicio, opcional, para lo que es capa 7: reintentos, rutas por
  cabecera, métricas por código HTTP. Solo pasa por él el tráfico de quien lo pide.

Un pod entra al mesh con una etiqueta en su namespace, sin reiniciarse: el CNI de Istio redirige su tráfico desde
adentro de su propia red.

## Instalarlo, y lo que pesa

Cuatro charts de Helm, en la versión de [a01](a01-el-laboratorio.md), desde el repositorio vigente de Istio:

```bash
R=https://blob.istio.io/istio-release/charts
helm install istio-base base     --repo $R -n istio-system --create-namespace --version 1.31.1 --wait
helm install istiod    istiod    --repo $R -n istio-system --version 1.31.1 --set profile=ambient --wait
helm install istio-cni cni       --repo $R -n istio-system --version 1.31.1 --set profile=ambient --wait
helm install ztunnel   ztunnel   --repo $R -n istio-system --version 1.31.1 --wait
```

```text
instalado en 42 s
istio-cni-node-8246f     1m    35Mi
istiod-574cc458f-z9ftp   5m    51Mi
ztunnel-9zc7n            6m    3Mi          (y uno igual en cada uno de los otros dos nodos)
total: 148 MiB
```

> ⚠️ **El repositorio viejo no tiene la versión.** `istio-release.storage.googleapis.com/charts`, el que aparece en muchas
> guías, dejó de recibir versiones en la 1.31.0-rc.0: `chart "base" version "1.31.1" not found`. El de `blob.istio.io`,
> sí.

Para comparar: cert-manager y trust-manager, que hacen el mTLS a mano de la [Fase 19](19-tls-y-certificados.md), quedaron
por debajo de 150 MiB. El mesh en reposo pesa lo mismo; con el *waypoint* y tráfico, unos 200 MiB.

## mTLS con una etiqueta

```bash
kubectl label namespace apps istio.io/dataplane-mode=ambient
```

Ningún pod se reinició, la venta siguió en `201` y la suite de G5 pasó. En el log de ztunnel, cada conexión entre
servicios del namespace ya va por el túnel, con identidades:

```text
info access connection complete src.workload="inventory-7dbc8c44d5-fxwrl" src.namespace="apps"
  src.identity="spiffe://cluster.local/ns/apps/sa/default" dst.addr=10.244.2.2:15008 dst.hbone_addr=10.244.2.2:9090
  dst.service="pricing-grpc.apps.svc.cluster.local" dst.workload="pricing-f9d6cf87-dzh9k" dst.identity="spiffe://cluster.local/ns/apps/sa/default"
info access connection complete src.workload="catalog-9b8c4ccf9-4rwnx" src.namespace="apps"
  dst.addr=10.244.2.7:5432 dst.workload="postgres-0" dst.namespace="data" direction="outbound"
```

Dos cosas que la línea dice sin decirlas:

- **Todos los servicios tienen la misma identidad**: `sa/default`. El chart del curso no crea una `ServiceAccount` por
  servicio (la [Fase 20](20-seguridad-del-pod-y-de-la-red.md) les quitó el token, no les dio una propia). El mTLS cifra,
  pero no distingue a `inventory` de `catalog`: una política de autorización por identidad no tendría con qué decidir.
  El mTLS a mano de la [Fase 19](19-tls-y-certificados.md) sí distinguía: cada certificado decía el nombre de su servicio.
- **Postgres no está en el mesh** (`data` no tiene la etiqueta), y su conexión va sin identidad. El mesh protege lo que
  se le pone adentro.

El gRPC de `inventory` a `pricing` ya iba con el mTLS de G8; ahora va además por el túnel: dos capas de TLS, una del código
y otra del mesh. Con el mesh, la del código sobra; sacarla es quitar G8.

## Capa 7: el waypoint, y la red que lo deja sin configuración

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata: {name: waypoint, namespace: apps, labels: {istio.io/waypoint-for: service}}
spec:
  gatewayClassName: istio-waypoint
  listeners: [{name: mesh, port: 15008, protocol: HBONE}]
```

```bash
kubectl label namespace apps istio.io/use-waypoint=waypoint
```

Y el sistema se cayó:

```text
waypoint-65dd67d75c-flq8x   0/1   Running   0     40s
error cache resource:default failed to sign: create certificate: rpc error: code = Unavailable desc = connection error:
  desc = "transport: Error while dialing: dial tcp 10.96.73.138:15012: i/o timeout"
venta por la puerta: 503
```

El *waypoint* es un pod más del namespace `apps`, y la `NetworkPolicy` de la [Fase 20](20-seguridad-del-pod-y-de-la-red.md)
le cierra toda salida que no esté escrita: no llega a istiod (15012), no recibe certificado ni configuración, y como el
namespace ya está apuntado a él, **todo el tráfico entre servicios queda en un proxy que no está listo**. Una política más,
y volvió:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: allow-waypoint-istiod, namespace: apps}
spec:
  podSelector: {matchLabels: {gateway.networking.k8s.io/gateway-name: waypoint}}
  policyTypes: [Egress]
  egress:
    - to: [{namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: istio-system}}}]
      ports: [{protocol: TCP, port: 15012}]
```

```text
venta por la puerta: 201
```

La lección es la de la [Fase 20](20-seguridad-del-pod-y-de-la-red.md) con otro actor: **el mesh es software que corre en tu red, y tu red lo tiene que dejar
hablar**. Con ztunnel no pasó, porque vive en `istio-system`; con el *waypoint*, que vive en el namespace de la
aplicación, sí.

## Reintentos sin tocar el código

El generador de caos de la [Fase 22](22-resiliencia-y-caos.md) delante de `catalog`, con la mitad de las respuestas en 503,
y un pod cliente del mesh que lo lee 200 veces. Primero sin nada; después con una `HTTPRoute` de Gateway API cuyo padre es
el `Service` `chaos`, que el *waypoint* aplica:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata: {name: chaos-reintentos, namespace: apps}
spec:
  parentRefs: [{group: "", kind: Service, name: chaos, port: 8080}]
  rules:
    - backendRefs: [{name: chaos, port: 8080}]
      retry: {attempts: 3, codes: [503]}
```

| | 503 de 200 lecturas |
|---|---|
| sin reintentos | 104 |
| con la `HTTPRoute` de reintentos, tres corridas | 23 · 7 · 18 |

Y el costo, el mismo que midió la [Fase 22](22-resiliencia-y-caos.md): en la tercera corrida, las 200 lecturas del cliente fueron **397 peticiones al
vecino**, 1,99 veces la carga. El mesh no cambia la aritmética de los reintentos; cambia dónde se escriben. Y no sabe lo
que `Guard` sabía en G9: que un `POST` a `replenish` no se reintenta, o cuándo abrir un circuito porque el vecino está
degradado. Esas reglas, en el mesh, hay que escribirlas por ruta; en el código, por llamada.

## Métricas por servicio y por código

El *waypoint* cuenta cada petición que pasa por él, con su origen, su destino y su código, en el formato de Prometheus
([Fase 17](17-metricas-y-dashboards.md)), en el puerto 15020 (recortada a las etiquetas que importan):

```text
istio_requests_total{source_workload="a10-cliente",destination_service_name="chaos",response_code="200"} 648
istio_requests_total{source_workload="a10-cliente",destination_service_name="chaos",response_code="503"} 104
istio_requests_total{source_workload="a10-cliente",destination_service_name="chaos",response_code="503"} 48
```

Son las 800 lecturas del cliente, después de los reintentos: lo que vio el cliente, no lo que recibió el vecino. Es lo
que G6 escribió a mano en los cuatro servicios, con dos diferencias: sale para cualquier servicio que pase por el
*waypoint*, en cualquier lenguaje; y no sabe nada del negocio (`lab_sales_total` sigue siendo del código).

## Sacarlo

```bash
kubectl label namespace apps istio.io/use-waypoint- istio.io/dataplane-mode-
helm uninstall ztunnel istio-cni istiod istio-base -n istio-system
kubectl delete namespace istio-system
```

La venta siguió en `201` y ningún pod se reinició. Pero `helm uninstall` dejó dos cosas: **15 CRD** de Istio y **tres
`GatewayClass`** (`istio`, `istio-remote`, `istio-waypoint`) que istiod crea solo. Hay que borrarlas a mano. Y las imágenes
de Istio quedan en los nodos de kind hasta que alguien las borre.

## Linkerd y Cilium

No se instalaron (D15); se nombran con lo que los distingue:

- **Linkerd** usa un proxy por pod escrito en Rust, más liviano que Envoy, y da mTLS automático con identidad por
  `ServiceAccount` desde el primer día. Su costo es el del modelo *sidecar*: un proceso más en cada pod y un reinicio
  para entrar al mesh. Las versiones estables las distribuye la empresa que lo creó; el proyecto publica versiones *edge*.
- **Cilium** hace el mesh desde el CNI con eBPF, y un Envoy por nodo para la capa 7. Su costo es reemplazar la red del
  cluster: en kind, sacar kindnet. Si el cluster ya usa Cilium como CNI, es el mesh que menos piezas suma.

## 🧭 Cuándo usar qué

| Situación | Opción | Por qué |
|---|---|---|
| cuatro servicios, un equipo, mTLS en una llamada | a mano, como la [Fase 19](19-tls-y-certificados.md) | dos certificados y una CA; menos piezas que operar que un mesh |
| mTLS entre todos, en cualquier lenguaje, sin tocar el código | ambient con ztunnel | 148 MiB, una etiqueta y ningún reinicio |
| reintentos, rutas y métricas HTTP para muchos servicios | ambient con *waypoint*, y la `NetworkPolicy` que lo deja hablar con istiod | lo mismo que G9 y G6, por ruta y no por servicio |
| reintentos que dependen del negocio (no reintentar un `POST`, circuitos) | en el código, como G9 | el mesh no sabe qué operación es idempotente |
| autorización por servicio | un mesh, después de darle a cada servicio su `ServiceAccount` | con `sa/default` para todos, no hay identidad que autorizar |

## ⚠️ Advertencias

- Con las `NetworkPolicy` del curso, el *waypoint* necesita su regla de salida a istiod; sin ella, todo el tráfico entre
  servicios cae.
- Tres corridas de reintentos con una sola `HTTPRoute`; la cantidad exacta de 503 varía corrida a corrida, como el azar
  del generador.
- La memoria es una lectura de `kubectl top` por pieza.

## 📚 Referencias

- Istio, *Ambient mode overview*: https://istio.io/latest/docs/ambient/overview/
- Istio, *Install with Helm* (ambient): https://istio.io/latest/docs/ambient/install/helm/
- Istio, *Use a waypoint proxy*: https://istio.io/latest/docs/ambient/usage/waypoint/
- Istio, *Ambient and Kubernetes NetworkPolicy*: https://istio.io/latest/docs/ambient/usage/networkpolicy/
- Gateway API, GEP-1731 (*HTTPRoute Retries*): https://gateway-api.sigs.k8s.io/geps/gep-1731/
- Linkerd: https://linkerd.io/2/overview/ · Cilium, *Service Mesh*: https://docs.cilium.io/en/stable/network/servicemesh/

> ⚠️ Las URL y los contenidos cambian.

## 🧪 Ejercicios (6)

### Ejercicio 1 — Instalar, y medir
Instala ambient como en este apéndice y mide su memoria en reposo.

**Criterio:** los siete pods de `istio-system` en `Running` y la suma de `kubectl top`, comparada con los 148 MiB de aquí.

### Ejercicio 2 — Una identidad por servicio
Dale a cada servicio su `ServiceAccount` en el chart y mira el log de ztunnel.

**Criterio:** `src.identity` distinta para `inventory` y `pricing` en la misma conexión.

### Ejercicio 3 — La política que el mesh entiende
Con identidades propias, escribe una `AuthorizationPolicy` que solo deje a `inventory` llegar al 9090 de `pricing`.

**Criterio:** una llamada desde `catalog` al 9090 rechazada, y la venta en `201`.

### Ejercicio 4 — Sin la regla del waypoint
Reproduce la caída de la sección del *waypoint* quitando `allow-waypoint-istiod`.

**Criterio:** el `failed to sign … 15012: i/o timeout` en el log del *waypoint* y una venta en 503; y vuelta a `201` al
restaurarla.

### Ejercicio 5 — El reparto de gRPC, por el mesh
Con `global.grpc.balancing: service` (la conexión de HTTP/2 en una réplica, [Fase 23](23-grpc-y-el-balanceo.md)) y
`pricing` en tres réplicas, pasa `pricing` por un *waypoint* y repite B-23.

**Criterio:** el reparto por réplica con y sin *waypoint*, y la mediana de la venta en los dos casos.

### Ejercicio 6 — G8 o el mesh
En media página: ¿La Vecina debería sacar el mTLS de su código y dejárselo al mesh?

**Criterio:** la media página, con lo que cada uno da (identidad por servicio, reintentos por negocio) y lo que cuesta
(memoria, la regla de red, una pieza más que actualizar).

---

> 🏷️ **Este apéndice no lleva tag propio.**
