# 🌐 Fase 10 — La entrada al sistema: una puerta compartida, una ruta por equipo, y el Siga perdiendo tráfico hasta cero

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 10 de 27 · Parte II — El despliegue · **media**
> **Perfil:** `minimo`; `lab` para la rotura · **Observabilidad encendida:** ninguna
> **Motor de referencia:** Docker · 🦭 los puertos 8080 y 8443 valen para los dos motores; cloud-provider-kind, solo verificado con Docker
> **Servicios que toca:** los cinco, y Contingencia y el portal en `legacy` · **Paso de generación:** ninguno
> **Depende de:** [Fase 09](09-los-cuatro-servicios-dentro.md) · **Habilita:** [Fase 11](11-configuracion-y-secretos.md)
> **Incidentes que reserva:** 08 · **Medición:** ninguna
> **Apéndices de apoyo:** [a01](a01-el-laboratorio.md), [a05](a05-diccionarios.md), [a16](a16-el-patrimonio.md)
> **Fecha de verificación ejecutada:** 03/10/2026 · macOS arm64 · Windows 11 y Linux: no verificados por el autor
> **Objetivo:** abrir una sola puerta al sistema con Gateway API, que cada equipo cuelgue su ruta de ella, que la página del `storefront` muestre el catálogo en el navegador, y sacarle a Contingencia el tráfico de precios hasta cero sin apagarla.

---

## 🧭 1. Dónde estamos

Los cinco servicios corren en `apps`, cada uno con su almacén, y ninguno se ve desde afuera. La página
del `storefront` pide el catálogo a `http://api.localhost:8080` y recibe `Empty reply from server`
([Fase 09](09-los-cuatro-servicios-dentro.md)): en el 8080 del host no escucha nadie todavía. Esta fase pone a alguien.

Y lo hace con una exigencia de la historia. Andrés pasó media vida poniendo sistemas delante de otros
sistemas —Contingencia delante del Siga caído, el portal delante de Contingencia (historia §1.7)—, y
cuando Valentina le mostró el plan de extraer precios, preguntó lo que pregunta alguien que ya hizo
dos migraciones sin presupuesto:

> *"Listo, `pricing` existe. ¿Y cómo le quito el tráfico a Contingencia sin apagarla un viernes?
> Porque si la apago y `pricing` falla, el lunes no hay precios en ninguna caja."*

Daniela agregó la suya, desde el portal: su página nueva tiene que leer el catálogo desde otro
nombre de host, y el navegador no se lo va a dejar hacer gratis. Las dos respuestas pasan por el mismo
sitio: **una puerta única delante del sistema**, que sepa repartir el tráfico por nombre, por ruta y
por porcentaje. En Kubernetes esa puerta es Gateway API, y en este laboratorio la implementa Envoy
Gateway.

---

## 🎯 2. Objetivos de esta fase

1. Ver por qué un `Service` `LoadBalancer` se queda en `Pending`, y qué cambia cuando alguien lo
   implementa.
2. Instalar Envoy Gateway y escribir la puerta compartida (`GatewayClass` y `Gateway`), con el
   `NodePort` fijo que llega al host.
3. Colgar de ella una `HTTPRoute` por servicio, y ver la página del `storefront` con el catálogo en el
   navegador.
4. Llevar el patrimonio al namespace `legacy` y repartir el tráfico de precios entre Contingencia y
   `pricing` hasta que Contingencia no reciba nada.
5. Leer un `Ingress` ajeno y traducirlo a Gateway API, sin desplegar ninguno.

---

## 🚫 3. Qué NO entra todavía

- TLS en la puerta (el listener de 8443) → [Fase 19](19-tls-y-certificados.md).
- La entrada como parte de un *service mesh* → [a10](a10-service-mesh.md).
- Que un servicio llame a otro por la puerta (no lo hace: se llaman por su `Service`) → [Fase 16](16-escalado-y-rollout.md).
- Instalar los controladores alternativos: se nombran y se comparan con criterio, sin medir.

---

## 🧨 4. El problema, en el laboratorio

Un `Service` `ClusterIP` existe solo dentro del cluster. El instinto de la nube dice que para llegar
desde afuera se pide un `LoadBalancer`:

```text
$ kubectl -n apps expose deploy pricing --name pricing-lb --type=LoadBalancer --port=8080 --target-port=http
service/pricing-lb exposed
$ kubectl -n apps get svc pricing-lb          # 20 segundos después
NAME         TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
pricing-lb   LoadBalancer   10.96.118.57   <pending>     8080:32264/TCP   20s
```

`<pending>`, y así se quedaría para siempre. El objeto existe; **nadie lo implementa**. En una nube, un
controlador del proveedor ve el `Service`, crea un balanceador de verdad, le pone una IP pública y la
escribe en el `status`. En kind no hay proveedor. **cloud-provider-kind** hace ese papel, como un
contenedor en la red de kind:

```text
$ docker run -d --name cloud-provider-kind --network kind -v /var/run/docker.sock:/var/run/docker.sock registry.k8s.io/cloud-provider-kind/cloud-controller-manager:v0.12.0
$ kubectl -n apps get svc pricing-lb
NAME         TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
pricing-lb   LoadBalancer   10.96.118.57   192.168.0.7   8080:32264/TCP   52s
$ curl -sS -m 8 "http://192.168.0.7:8080/health/live"
curl: (28) Connection timed out after 8003 milliseconds
```

El objeto ya tiene IP, **y esa es la lección de toda la Parte II**: un objeto no hace nada sin alguien
que lo implemente, y en la nube ese alguien te factura una IP. La segunda mitad es honesta: en macOS,
la red de kind vive dentro de la máquina virtual del motor, y su IP no llega a tu Mac. Lo que sí
publicó cloud-provider-kind en el host fue un contenedor auxiliar en un puerto que eligió Docker
(`0.0.0.0:52587->10000/tcp` en esta verificación): no es un puerto que se pueda escribir en un
contrato. Por eso el laboratorio entra por otro camino: el `NodePort` fijo que
kind ya publica en `127.0.0.1:8080` ([Fase 07](07-el-cluster-local.md)). Y una advertencia práctica: cloud-provider-kind también
implementa Gateway API, y deja creada su propia `GatewayClass` (`cloud-provider-kind`), que hay que
borrar a mano.

> 🚧 **Aquí empieza la frontera con la nube.** Un balanceador con IP pública, sus reglas de firewall y
> su factura no existen en este laboratorio. Lo que sí existe es el modelo: un `Service` que pide, y un
> controlador que cumple.

---

## 🌐 5. La puerta y las rutas, con `pricing`

### 5.1 Instalar quien implementa la puerta

```bash
task platform:gateway -- minimo
```

Debajo, tres pasos: Envoy Gateway con su chart, en la versión de [a01](a01-el-laboratorio.md#-versiones-fijadas)
(trae las definiciones de Gateway API); los tres objetos de `platform/gateway/`; y una espera a que la
puerta esté programada:

```text
task: [platform:gateway] helm upgrade --install eg oci://docker.io/envoyproxy/gateway-helm --version v1.9.2 -n gateway --create-namespace --kube-context kind-minimo --wait --timeout 10m
task: [platform:gateway] kubectl --context kind-minimo apply -f platform/gateway/
envoyproxy.gateway.envoyproxy.io/nodeport created
gateway.gateway.networking.k8s.io/lab created
gatewayclass.gateway.networking.k8s.io/eg created
task: [platform:gateway] kubectl --context kind-minimo -n gateway wait --for=condition=Programmed gateway/lab --timeout=300s
gateway.gateway.networking.k8s.io/lab condition met
```

Helm se usa aquí como instalador de un componente de terceros, sin explicarlo: el curso lo enseña en
la [Fase 13](13-helm-el-paquete.md), con su propio chart.

### 5.2 Tres objetos, tres dueños

```yaml
# El tipo de entrada del laboratorio: lo implementa Envoy Gateway, con la configuración de envoyproxy.yaml.
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: eg
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
  parametersRef:
    group: gateway.envoyproxy.io
    kind: EnvoyProxy
    name: nodeport
    namespace: gateway
```

La **`GatewayClass`** dice qué controlador implementa las puertas de esta clase, como una
`StorageClass` dice quién da discos. Sus parámetros son un `EnvoyProxy`, un objeto propio de Envoy
Gateway, que fija cómo se publica el proxy:

```yaml
      envoyService:
        type: NodePort
        # Cluster, y no el Local que pone Envoy Gateway por defecto: en el perfil lab el proxy puede caer en
        # un worker, y el NodePort del control-plane (el único mapeado al host) tiene que reenviarle.
        externalTrafficPolicy: Cluster
        patch:
          type: StrategicMerge
          value:
            spec:
              ports:
                - name: http-8080
                  port: 8080
                  nodePort: 30080
```

`NodePort` 30080, fijo: es el puerto al que kind reenvía el `127.0.0.1:8080` del host. Y la
**`Gateway`**, la puerta en sí:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: lab
  namespace: gateway
spec:
  gatewayClassName: eg
  listeners:
    - name: http
      protocol: HTTP
      port: 8080
      # Qué namespaces pueden colgar rutas de esta puerta: los del sistema, y ninguno más.
      allowedRoutes:
        namespaces:
          from: Selector
          selector:
            matchExpressions:
              - key: kubernetes.io/metadata.name
                operator: In
                values: [apps, legacy, apps-b]
```

Al programarla, Envoy Gateway creó un proxy y su `Service`:

```text
$ kubectl -n gateway get pods,svc
NAME                                              READY   STATUS      RESTARTS   AGE
pod/envoy-gateway-8656bcc8b4-6zbvc                1/1     Running     0          2m40s
pod/envoy-gateway-lab-2c82546a-84487c975b-8n86q   2/2     Running     0          11s

NAME                                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                                            AGE
service/envoy-gateway                ClusterIP   10.96.231.20   <none>        18000/TCP,18001/TCP,18002/TCP,19001/TCP,9443/TCP   2m40s
service/envoy-gateway-lab-2c82546a   NodePort    10.96.216.40   <none>        8080:30080/TCP                                     11s
```

Dos piezas, y conviene no confundirlas: `envoy-gateway` es el **controlador**, que lee los objetos de
Gateway API y configura; `envoy-gateway-lab-…` es el **proxy** (un Envoy), por donde pasa el tráfico.
Sin rutas, el proxy contesta lo único que sabe:

```text
$ curl -sS -i -m 5 http://api.localhost:8080/pricing/health/live | head -3
HTTP/1.1 404 Not Found
date: Sun, 04 Oct 2026 02:05:32 GMT
content-length: 0
```

### 5.3 La ruta de `pricing`, escrita por su equipo

```yaml
# La ruta de pricing, escrita por su equipo (Fase 10): api.localhost/pricing/… llega a pricing sin el prefijo.
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: pricing
  namespace: apps
spec:
  # De qué puerta cuelga: el Gateway compartido, en otro namespace.
  parentRefs:
    - name: lab
      namespace: gateway
  hostnames: ["api.localhost"]
  rules:
    - matches:
        - path: {type: PathPrefix, value: /pricing}
      filters:
        # El servicio no sabe de prefijos: /pricing/health/live le llega como /health/live.
        - type: URLRewrite
          urlRewrite:
            path: {type: ReplacePrefixMatch, replacePrefixMatch: /}
      backendRefs:
        - name: pricing
          port: 8080
```

`task deploy` aplica las rutas junto con los servicios. La puerta las acepta, y lo escribe en el
`status` de cada ruta:

```text
$ kubectl -n apps get httproute
NAME         HOSTNAMES                  AGE
catalog      ["api.localhost"]          0s
inventory    ["api.localhost"]          0s
pricing      ["api.localhost"]          0s
replenish    ["api.localhost"]          0s
storefront   ["storefront.localhost"]   0s
$ kubectl -n apps get httproute pricing -o jsonpath='{range .status.parents[0].conditions[*]}{.type}={.status} {.reason}{"\n"}{end}'
Accepted=True Accepted
ResolvedRefs=True ResolvedRefs
$ curl -sS -m 5 -X PUT -H 'Content-Type: application/json' -d '{"store":"DRO-007","price":21900}' http://api.localhost:8080/pricing/prices/SKU-0003
{"sku":"SKU-0003","store":"DRO-007","price":21900,"currency":"COP","regulatedCap":null,"capped":false}
```

Desde tu máquina, por primera vez, **con un nombre y no con una dirección de pod**. El camino entero:

```mermaid
flowchart LR
    CURL["curl"] --> H["127.0.0.1:8080"]
    H --> N["nodo de kind :30080<br/>NodePort"]
    N --> E["proxy Envoy<br/>del Gateway"]
    E -- "HTTPRoute pricing:<br/>api.localhost + /pricing<br/>reescribe a /" --> S["Service pricing<br/>ClusterIP"]
    S --> P["pod pricing"]
```

### 5.4 El reparto de papeles

Lo que Gateway API agrega sobre lo anterior no es sintaxis: es **quién escribe qué**. Plataforma
escribe la `GatewayClass` y la `Gateway` una vez, y decide qué namespaces pueden colgar rutas
(`allowedRoutes`). Cada equipo escribe la `HTTPRoute` de su servicio, en su namespace, sin tocar la
puerta ni pedir permiso para cambiar su ruta. Es la misma regla de la reunión de los cuatro equipos de
la [Fase 02](02-compose-el-sistema-en-un-archivo.md) —cada servicio tiene su dueño—, llevada a la entrada.

### 5.5 `.localhost`, y por qué a veces tu `curl` no llega

Los nombres `*.localhost` no están en ningún DNS: los clientes los resuelven a la máquina local por
convención. En macOS, en esta verificación, resolvieron igual `curl`, Python y el resolutor del
sistema:

```text
$ python3 -c "import socket;print(socket.getaddrinfo('api.localhost',8080)[0][4])"
('127.0.0.1', 8080)
$ dscacheutil -q host -a name api.localhost
name: localhost
ipv6_address: ::1

name: localhost
ip_address: 127.0.0.1
```

Hay clientes y sistemas donde no pasa —algunas configuraciones de Linux y algunas herramientas que
usan su propio resolutor—, y entonces la salida es una línea en `/etc/hosts` o la cabecera `Host` a
mano (`curl -H 'Host: api.localhost' http://127.0.0.1:8080/…`). Lo de Windows 11 y Linux no lo verificó
el autor; se confirma al hacer el curso.

> 🩻 **Esto sí funciona igual.** Los `Service` de la [Fase 08](08-el-primer-despliegue.md) no cambian: la puerta les manda tráfico a
> ellos, no a los pods. Lo que se agregó está delante, y si mañana se cambia de controlador, los
> servicios no se enteran.

**Prueba de fuego.** `curl -sS http://api.localhost:8080/pricing/health/live` con `{"status":"live"}`, y
`kubectl -n apps get httproute pricing -o jsonpath='{.status.parents[0].conditions[0].status}'` con
`True`.

**El patrón a memorizar.** Una clase dice quién implementa; una puerta dice dónde se escucha y quién
puede colgarse; una ruta, de cada equipo, dice qué nombre y qué ruta van a qué `Service`.

---

## 🔁 6. Los otros tres, y el patrimonio

**`inventory` y `replenish`** siguen a `pricing` sin sorpresas: su ruta es la misma con otro prefijo.

**`catalog` y el navegador.** La página del `storefront` vive en `storefront.localhost`, y pide el
catálogo a `api.localhost`: otro origen. El navegador solo le entrega la respuesta a la página si la
respuesta lo autoriza con cabeceras CORS. Es política de la puerta, no código de `catalog`, y Gateway
API la trae como un filtro más de la ruta, junto al `URLRewrite`:

```yaml
        # La página del storefront vive en otro origen: el navegador solo le entrega la respuesta si la
        # puerta lo autoriza. Es un filtro del estándar (HTTPRouteCORS, soporte extendido).
        - type: CORS
          cors:
            allowOrigins: ["http://storefront.localhost:8080"]
            allowMethods: [GET]
```

"Soporte extendido" quiere decir que el estándar lo define y cada implementación decide si lo trae:
Envoy Gateway, sí. La primera versión de esta fase usó la política propia de Envoy Gateway para lo
mismo (`SecurityPolicy`), con el mismo resultado; el filtro del estándar se la ganó porque viaja a otra
implementación sin cambios.

Con el filtro, y sin él, la misma página en Chrome sin interfaz (`--headless=new --dump-dom`; esta
salida es de la verificación repetida en la [Fase 12](12-estado-y-almacenamiento.md), con el catálogo ya sembrado):

```text
=== con el filtro CORS del estándar
<main><h1>Droguerías La Vecina</h1><p class="lema">Siempre llega.</p><h2>Catálogo</h2><ul><li><strong>Acetaminofén 500 mg</strong> · venta libre · <code>SKU-0001</code></li><li><strong>Ibuprofeno 400 mg</strong> · venta libre · <code>SKU-0002</code></li>…</ul></main>
=== sin el filtro (la ruta del repositorio, menos el filtro)
<main><h1>Droguerías La Vecina</h1><p class="lema">Siempre llega.</p><h2>Catálogo</h2><p class="aviso">No se pudo cargar el catálogo desde http://api.localhost:8080 (Failed to fetch).</p></main>
```

`curl` no ve ninguna diferencia, porque `curl` no aplica CORS: la petición llega, `catalog` contesta,
y es el navegador el que descarta la respuesta. Por eso la cabecera se verifica con el `Origin`:

```text
$ curl -sS -i -H 'Origin: http://storefront.localhost:8080' http://api.localhost:8080/catalog/products | grep -i "access-control\|HTTP/"
HTTP/1.1 200 OK
access-control-allow-origin: http://storefront.localhost:8080
$ curl -sS -i -H 'Origin: http://otra.localhost:8080' http://api.localhost:8080/catalog/products | grep -i "access-control\|HTTP/"
HTTP/1.1 200 OK
```

**`storefront`** tiene su propio nombre de host y una ruta sin prefijo (`hostnames:
["storefront.localhost"]`). La página dice el nombre de la casa y lista el catálogo: por fin, lo que
prometía la [Fase 02](02-compose-el-sistema-en-un-archivo.md).

### 6.1 🏚️ El patrimonio detrás de la misma puerta: el *strangler*

`task legacy:up TARGET=cluster` lleva Contingencia, su base y el portal al namespace `legacy`: las
mismas imágenes de [a16](a16-el-patrimonio.md), cargadas en el nodo, con los `.sql` de la base como
`ConfigMap`. Contingencia desplegó en 8,9 segundos, y sigue contestando SOAP como siempre.

Sacarle tráfico sin apagarla exige tres cosas que esta fase construyó, y ninguna es Kubernetes:

1. **Que el viejo y el nuevo contesten la misma pregunta.** Contingencia sabe precios, pero por SOAP.
   Le agregué una fachada REST con la forma del contrato de `pricing` (`GET /prices/{sku}?store=`), que
   además marca sus respuestas con la cabecera `X-Contestado-Por: contingencia` para poder contarlas.
   Y como Contingencia la sirve bajo su contexto (`/contingencia/prices/…`) y la puerta **no** puede
   reescribir la ruta de un solo backend —Envoy Gateway lo rechaza: *"URLRewrite path modifier is not
   supported within BackendRef"*, y esa parte del tráfico volvió como 500—, la traducción la hace un
   nginx en el mismo pod de Contingencia, en el 8081: la fachada.
2. **Que el nuevo sepa lo mismo.** Un `Job` copió los 64 precios de las ocho droguerías de Contingencia
   a `pricing` (`precios migrados: 64`). Sin ese paso, la mitad de las cajas vería precios distintos según
   a quién le tocara.
3. **Permiso para cruzar namespaces.** La ruta vive en `apps` y Contingencia en `legacy`: el dueño del
   destino lo autoriza con un `ReferenceGrant`.

Y la ruta de precios, con los dos backends y sus pesos:

```yaml
      backendRefs:
        - name: pricing
          port: 8080
          weight: 20
        # Contingencia, por su fachada (8081): la misma pregunta, /prices/…, que le llega a pricing.
        - name: contingencia
          namespace: legacy
          port: 8081
          weight: 80
```

Los pesos se mueven con un `patch`, y en cada paso se cuenta quién contestó 200 peticiones (sección
7). Al final, la ruta del repositorio vuelve a tener un solo backend: `pricing`. Contingencia sigue
encendida, contestando su SOAP al portal, sin recibir una sola petición de precios por la puerta. **Es
la forma de sacarle tráfico a un sistema sin apagarlo**, y es lo que Paracelso tiene que hacer con el
Siga de verdad.

---

## 🪞 7. Tu instinto de compose dice… y la apuesta

El instinto, en su mejor versión: *"para exponer un servicio, publico su puerto"*. En compose era
`ports:`, uno por servicio que se mira desde afuera. En un cluster, el equivalente directo
—un `NodePort` o un `LoadBalancer` por servicio— funciona, y multiplica puertos, IPs y facturas. La
puerta compartida cambia la pregunta: no "qué puerto", sino "qué nombre y qué ruta", y permite algo que
ningún puerto da: **repartir por porcentaje**.

> 🪞 **Apuesta antes de ejecutar.** Con la `HTTPRoute` de precios repartida 80/20 entre Contingencia y
> `pricing`, de 200 peticiones `pricing` recibe entre el 15 % y el 25 %.
>
> **Resultado: ganada, y con una exactitud que no esperaba.** Tres corridas de 200: Contingencia 160 y
> `pricing` 40, las tres. Con 50/50, 101 y 99. Con 100/0, `pricing` 200. Y las 200 respuestas de cada
> corrida dijeron el mismo precio, 22.200, porque la migración del paso 2 ya había copiado los datos.

```text
80/20 corrida 1 {'contingencia': 160, 'pricing': 40} precios: {22200: 200}
80/20 corrida 2 {'contingencia': 160, 'pricing': 40} precios: {22200: 200}
80/20 corrida 3 {'contingencia': 160, 'pricing': 40} precios: {22200: 200}
50/50 {'contingencia': 101, 'pricing': 99} precios: {22200: 200}
100/0 {'pricing': 200} precios: {22200: 200}
```

La exactitud tiene una explicación que conviene no generalizar: el cliente de la prueba abre una
conexión por petición, y el proxy reparte cada una por su peso. Con conexiones largas, el reparto se
mide distinto (la [Fase 06](06-del-compose-al-cluster.md) lo vio en compose, y la [Fase 23](23-grpc-y-el-balanceo.md) lo vuelve a ver con gRPC).

---

## 🧨 8. La rotura: el proxy en un worker

En el perfil `lab`, el proxy del `Gateway` puede caer en cualquier worker, y el mapeo del host está
solo en el control-plane. **El cambio exacto:** `externalTrafficPolicy: Local` en el `EnvoyProxy`, que
es el valor que Envoy Gateway pone si no se le dice otro.

```text
$ kubectl --context kind-lab -n gateway get pods -o wide -l gateway.envoyproxy.io/owning-gateway-name=lab
NAME                                          READY   STATUS    RESTARTS   AGE   IP           NODE
envoy-gateway-lab-2c82546a-84487c975b-6st97   2/2     Running   0          24s   10.244.2.2   lab-worker
$ time curl -sS -m 10 http://api.localhost:8080/pricing/health/live
curl: (28) Operation timed out after 10010 milliseconds with 0 bytes received
real	0m10.031s
```

**El síntoma literal**, arriba: diez segundos esperando y ningún byte. Con `Local`, un `NodePort` solo
reenvía a pods de **su mismo nodo**, y el proxy está en otro. El control-plane recibe la conexión del
host y no tiene a quién dársela. **Para salir:** `externalTrafficPolicy: Cluster`, que es lo que dice
el `EnvoyProxy` del laboratorio:

```text
$ time curl -sS -m 10 http://api.localhost:8080/pricing/health/live
{"status":"live"}
real	0m0.020s
```

Lo que se pierde con `Cluster`, y se dice en voz alta: el nodo que recibe reenvía a otro nodo, y en
ese salto **la IP de origen del cliente se reemplaza por la del nodo**. Un servicio que necesite saber
desde qué IP lo llaman no la va a ver. En el laboratorio no importa; en producción, a veces sí, y por
eso `Local` es el valor por defecto.

---

## ⚰️ 9. Autopsia: un `LoadBalancer` por servicio

**La decisión, con su mejor argumento.** Exponer cada servicio con su propio `LoadBalancer`: *"es lo
que hace la nube, es una línea (`type: LoadBalancer`), y cada equipo tiene su IP."*

**Por qué era razonable.** En un cluster gestionado funciona exactamente así, y es lo más parecido a
publicar puertos en compose.

**Qué pasa después, con número.** En el laboratorio, la IP que asignó cloud-provider-kind no llegó al
host (`Connection timed out after 8003 milliseconds`), y la alternativa publica un puerto efímero
distinto en cada creación. En la nube llega, pero se multiplica: cinco servicios, cinco balanceadores,
cinco IPs públicas, cinco facturas, y el CORS, los prefijos y los porcentajes resueltos —o no— en cada
servicio por separado. Y el *strangler* de la sección 6.1 no se puede hacer: no hay un sitio donde
repartir el tráfico de una misma ruta entre dos sistemas.

**Cuánto cuesta salir, con número.** Una puerta y cinco rutas: un `Gateway`, un balanceador (el del
`Gateway`) y cinco `HTTPRoute` que escribe cada equipo.

**Qué lo habría cambiado.** Preguntar *¿cuántas puertas necesita este sistema, y quién decide qué pasa
por cada una?*

**Antes y después, con números:** un `LoadBalancer` por servicio son cinco IPs (y, en este laboratorio,
ninguna que llegue al host); la puerta compartida es una, en `127.0.0.1:8080`, con el reparto 80/20
medido en la sección 7.

---

## 📖 10. Traducción

**`Ingress`, solo para leer.** Vas a encontrar `Ingress` en casi todos los clusters que heredes. El
controlador más usado, ingress-nginx, se retiró en marzo de 2026, y sus anotaciones nunca fueron
portables entre controladores: el mismo `Ingress` hacía cosas distintas según quién lo implementara.
Este curso no despliega ninguno. Así se lee uno y se traduce:

| En `Ingress` | En Gateway API |
|---|---|
| `ingressClassName: nginx` | `parentRefs` hacia una `Gateway` de una `GatewayClass` |
| `rules[].host` | `HTTPRoute.spec.hostnames` |
| `paths[].path` con `pathType: Prefix` | `matches[].path` con `type: PathPrefix` |
| la anotación de reescritura de un controlador | el filtro `URLRewrite`, del estándar |
| la anotación de pesos para un *canary* | `weight` en cada `backendRef`, del estándar |
| una anotación de CORS | el filtro `CORS` de la ruta, del estándar (soporte extendido) |
| *sin equivalente* | `allowedRoutes` y `ReferenceGrant`: quién puede colgarse y a qué puede apuntar |

El diccionario completo, con las direcciones de ida y vuelta, en [a05](a05-diccionarios.md#-ingress--gateway-api).

**Las otras implementaciones**, con lo que ganan y lo que pierden. La tabla es de criterio, sale de la
documentación de cada proyecto y no de una medición: solo Envoy Gateway se instaló.

| Implementación | Gana | Pierde |
|---|---|---|
| **Envoy Gateway** (la del curso) | implementa el estándar sin anotaciones propias; su proxy es el Envoy de muchos mesh y balanceadores | sus extensiones viven en objetos propios (`EnvoyProxy`, `SecurityPolicy`), que no son portables |
| **Traefik** | liviano, y entiende `Ingress` y Gateway API con el mismo controlador | su propio modelo de configuración convive con el estándar |
| **NGINX Gateway Fabric** | la continuidad para un equipo que viene de NGINX | otra pieza que aprender si no venías de ahí |
| **kgateway** | Envoy con funciones de *API gateway* encima | más superficie que la que este curso necesita |
| **Istio, Cilium** | la entrada como parte del mesh o del CNI | traen todo lo demás de ese mesh o de ese CNI ([a10](a10-service-mesh.md)) |

🌩️ En la nube, la `Gateway` pide un balanceador del proveedor con IP pública, y ese es su costo
mensual. Las filas están en [a05](a05-diccionarios.md#️-local--nube).

---

## 🩺 11. Incidentes de esta fase

- **[08 — El navegador recibe 404 y ningún pod se entera](cuaderno-incidentes.md#-incidente-08--el-navegador-recibe-404-y-ningún-pod-se-entera).**
  `HTTP/1.1 404 Not Found` con `content-length: 0`, el pod de `pricing` `Running` y sin una línea nueva
  en su log, y la ruta diciendo `Accepted=True`.

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

**Para un servicio, una puerta es demasiado.** Gateway API suma dos piezas que corren todo el tiempo
—el controlador y el proxy— y en este laboratorio Envoy Gateway ocupa unos 93 MiB en reposo ([B-00 en
a01](a01-el-laboratorio.md#-la-memoria-que-ocupa-cada-perfil)), además de cuatro tipos de objeto que
aprender. Si tienes un solo servicio que mirar desde afuera, un `NodePort` o un proxy inverso delante
alcanzan.

**La puerta paga cuando hay varios equipos, varios nombres y una migración**: el reparto de papeles
de la sección 5.4, el CORS en un solo sitio y, sobre todo, el 80/20 de la sección 7. Sin la puerta,
el *strangler* habría sido un cambio de DNS a todo o nada.

**Y la fachada del *strangler* no es gratis**: alguien tuvo que escribir una interfaz REST para un
sistema que solo hablaba SOAP, y copiar sus datos. Esa es la parte cara de sacar algo del Siga, y
ninguna plataforma la hace sola.

**La pregunta del curso, para esta fase:** el contenedor te dio los procesos. El orquestador te dio el
objeto `Gateway` y la API para describir rutas, y nada más: **la implementación la puso Envoy Gateway**,
que instalaste tú. Y **te tocó a ti** la fachada, la migración de datos y la decisión de cuándo mover
los pesos.

---

## ⚠️ 13. Errores comunes y diagnóstico

**Aparece una `GatewayClass` que nadie creó (`cloud-provider-kind`).** Causa: cloud-provider-kind
también implementa Gateway API. Salida: `kubectl delete gatewayclass cloud-provider-kind` cuando
termines con él.

**`URLRewrite path modifier is not supported within BackendRef`** en el `status` de una ruta
(`ResolvedRefs=False`), y 500 en una parte del tráfico. Causa: reescritura de ruta en un solo
backend, que Envoy Gateway no implementa. Salida: reescribir en la regla, o una fachada.

**`Failed to fetch` en la página, y `curl` funciona.** Es CORS: `curl` no lo aplica y el navegador sí.
Comprobación 🩺: `curl -i -H 'Origin: http://storefront.localhost:8080' …` y buscar
`access-control-allow-origin`.

**Diez segundos y ningún byte en `lab`.** Es la rotura de la sección 8.

---

## 📋 14. Checklist de validación

```text
[ ] un LoadBalancer en <pending>, y con cloud-provider-kind una IP que no llega al host (y su GatewayClass, borrada)
[ ] task platform:gateway -- minimo: la Gateway lab en Programmed
[ ] task deploy: cinco HTTPRoute con Accepted=True
[ ] curl a api.localhost:8080/pricing/…, /inventory/…, /catalog/… y /replenish/… responde
[ ] la página de storefront.localhost:8080 lista el catálogo en el navegador
[ ] Contingencia en legacy, la fachada respondiendo, y el reparto 80/20 → 100/0 contado
[ ] la rotura de externalTrafficPolicy en lab, y su arreglo
```

---

## 🧪 15. Ejercicios (20)

Un tercio son de diagnóstico; varios trabajan con el patrimonio.

## 🟢 Fácil — la puerta (1–6)

### 🟢 Ejercicio 1 — La puerta, de cero
Instala Envoy Gateway y la puerta en `minimo`.

**Criterio:** `kubectl -n gateway get gateway lab` con `PROGRAMMED True`.

<details><summary>Solución</summary>

`task platform:gateway -- minimo`.
</details>

### 🟢 Ejercicio 2 — Las rutas
Aplica las rutas y comprueba que las cinco quedan aceptadas.

**Criterio:** `Accepted=True` en las cinco.

<details><summary>Solución</summary>

`task deploy -- minimo` y, por cada ruta, el `jsonpath` de 5.3.
</details>

### 🟢 Ejercicio 3 — Los cuatro backends
Pide `/health/live` de los cuatro backends por la puerta.

**Criterio:** cuatro `{"status":"live"}`.

<details><summary>Solución</summary>

`curl -s http://api.localhost:8080/<svc>/health/live` con los cuatro nombres.
</details>

### 🟢 Ejercicio 4 — El catálogo en el navegador
Crea dos productos y abre `http://storefront.localhost:8080`.

**Criterio:** la página los lista.

<details><summary>Solución</summary>

Dos `POST` a `http://api.localhost:8080/catalog/products` y el navegador. Sin navegador, el `--dump-dom`
de Chrome de la sección 6.
</details>

### 🟢 Ejercicio 5 — El controlador y el proxy
Muestra los dos pods de `gateway` y di cuál pasa tráfico.

**Criterio:** los dos pods, y el que tiene el `NodePort`.

<details><summary>Solución</summary>

`kubectl -n gateway get pods,svc`. El proxy es `envoy-gateway-lab-…`, con el `Service` `NodePort` 8080:30080.
</details>

### 🟢 Ejercicio 6 — `Pending`
Crea un `Service` `LoadBalancer` para `catalog` sin cloud-provider-kind.

**Criterio:** `EXTERNAL-IP <pending>` dos minutos después.

<details><summary>Solución</summary>

`kubectl -n apps expose deploy catalog --name catalog-lb --type=LoadBalancer --port=8080
--target-port=http`. Bórralo al terminar.
</details>

## 🟡 Intermedio — rutas y nombres (7–12)

### 🟡 Ejercicio 7 — Una ruta nueva
Agrega a `pricing` una ruta `api.localhost/precios/…` (en español) que llegue al mismo servicio.

**Criterio:** `curl http://api.localhost:8080/precios/health/live` responde.

<details><summary>Solución</summary>

Una segunda regla en la `HTTPRoute` de `pricing` con `PathPrefix /precios` y el mismo `URLRewrite`.
</details>

### 🟡 Ejercicio 8 — CORS, a mano
Comprueba con `curl` qué orígenes autoriza la puerta para `catalog`.

**Criterio:** la cabecera `access-control-allow-origin` con el origen del `storefront`, y sin ella con
otro.

<details><summary>Solución</summary>

Los dos `curl` con `Origin` de la sección 6.
</details>

### 🟡 Ejercicio 9 — La fachada por dentro
Llama a la fachada de Contingencia sin pasar por la puerta.

**Criterio:** `X-Contestado-Por: contingencia` y un precio.

<details><summary>Solución</summary>

Un pod cliente en `legacy` con `curl -i http://contingencia:8081/prices/SKU-0003?store=DRO-007`.
</details>

### 🟡 Ejercicio 10 — El strangler, en tu máquina
Repite el reparto 80/20 → 50/50 → 100/0 y cuenta.

**Criterio:** tu tabla de quién contestó en cada paso.

<details><summary>Solución</summary>

`kubectl apply -f deploy/strangler/pricing-80-20.yaml`, el script de conteo de la sección 7 (cualquier
cliente que cuente la cabecera), y los `patch` de los pesos. Al terminar, `task deploy`.
</details>

### 🟡 Ejercicio 11 — Un namespace que no puede colgarse
Crea una `HTTPRoute` en `default` hacia la puerta. **Predice** su estado.

**Criterio:** la predicción y el `status` de la ruta.

<details><summary>Solución</summary>

La puerta solo admite rutas de `apps`, `legacy` y `apps-b`: la ruta queda sin aceptar
(`NotAllowedByListeners`). Bórrala.
</details>

### 🟡 Ejercicio 12 — Sin `ReferenceGrant`
Borra el `ReferenceGrant` y mira la ruta del strangler.

**Criterio:** `ResolvedRefs=False` con su razón, y qué pasa con la parte del tráfico de Contingencia.

<details><summary>Solución</summary>

`kubectl -n legacy delete referencegrant apps-a-contingencia`, el `status` de la ruta, y un conteo.
Restáuralo con `kubectl apply -f deploy/legacy/referencegrant.yaml`.
</details>

## 🟠 Difícil — diagnosticar (13–17)

### 🟠 Ejercicio 13 — El incidente 08
Provoca el incidente 08 con la tarea y diagnostícalo sin el cuaderno. **Predice** la causa.

**Criterio:** la causa y el comando que la confirmó.

**Rúbrica:** las hipótesis en orden; por qué el pod no sirve de nada aquí; y la trampa del `status`
(compara generaciones).

### 🟠 Ejercicio 14 — La IP que se pierde
Muestra que, con `externalTrafficPolicy: Cluster`, el servicio no ve la IP del cliente.

**Criterio:** la IP de origen que ve el proxy (en su log) con `Cluster`, y una frase sobre qué vería
con `Local`.

**Rúbrica:** el log del proxy (`kubectl -n gateway logs …`); la IP que aparece; y en qué servicio de La
Vecina importaría.

### 🟠 Ejercicio 15 — Un 404 de la puerta o del servicio
Provoca un 404 de la puerta y uno de `pricing`, y distínguelos sin mirar el código.

**Criterio:** los dos 404 literales, y el criterio que los separa.

**Rúbrica:** el de la puerta no tiene cuerpo (`content-length: 0`); el de `pricing` trae
`{"error":"not_found"}`; y el log de `pricing` solo tiene el segundo.

### 🟠 Ejercicio 16 — La migración que faltó
Repite el strangler **sin** el `Job` de migración, con `pricing` vacío. **Predice** qué ven las cajas.

**Criterio:** la predicción, y el conteo de respuestas 200 y 404.

**Rúbrica:** el 20 % de 404; y por qué la migración de datos es la parte del strangler que ninguna
plataforma hace.

### 🟠 Ejercicio 17 — El rechazo de Envoy Gateway
Reproduce el `URLRewrite path modifier is not supported within BackendRef`.

**Criterio:** el mensaje en el `status` y el código de las respuestas.

**Rúbrica:** la ruta que lo provoca; la proporción de 500; y por qué la API lo aceptó y el controlador
no (la conformidad es por controlador).

## 🔴 Muy difícil — el patrimonio (18–20)

### 🔴 Ejercicio 18 — El portal detrás de la puerta
Publica el portal en `portal.localhost`, con su propia ruta en `legacy`.

**Criterio:** `http://portal.localhost:8080` muestra el portal.

**Rúbrica:** la ruta; si hizo falta tocar la `Gateway` (no: `legacy` ya está permitido); y qué
tendrías que agregar al contrato antes de dejarlo así (el host).

### 🔴 Ejercicio 19 — El strangler de un segundo servicio
Diseña el strangler de `inventory` desde el `StockService` de Contingencia.

**Criterio:** un documento corto con la fachada, la migración y los pasos de pesos.

**Rúbrica:** la fachada (qué operaciones, y por qué solo lectura al principio); la migración (y por qué
las existencias son más difíciles que los precios: cambian mientras migras); y el criterio para pasar
de un peso al siguiente.

### 🔴 Ejercicio 20 — Una puerta de otro proyecto
Instala, en un cluster aparte, otra implementación de Gateway API de la tabla y aplica las mismas rutas.

**Criterio:** las rutas aceptadas y `api.localhost` respondiendo con la otra implementación.

**Rúbrica:** qué objetos cambiaron (la `GatewayClass` y el `EnvoyProxy`) y cuáles no (las `HTTPRoute`,
con su filtro CORS si la otra implementación trae ese soporte extendido); y lo que eso dice del estándar.

---

## 📚 16. Referencias

**Documentación oficial** (las versiones de [a01](a01-el-laboratorio.md))

- Gateway API, *Introduction* y los papeles: https://gateway-api.sigs.k8s.io/docs/concepts/roles-and-personas/
- Gateway API, *HTTP routing*: https://gateway-api.sigs.k8s.io/guides/user-guides/http-routing/
- Envoy Gateway, documentación: https://gateway.envoyproxy.io/docs/ — `EnvoyProxy`.
- Gateway API, *HTTP CORS*: https://gateway-api.sigs.k8s.io/guides/user-guides/http-cors/
- Kubernetes, *Service* (`externalTrafficPolicy`): https://kubernetes.io/docs/concepts/services-networking/service/
- cloud-provider-kind: https://github.com/kubernetes-sigs/cloud-provider-kind
- MDN, *Cross-Origin Resource Sharing*: https://developer.mozilla.org/es/docs/Web/HTTP/Guides/CORS

**Libros**

- Sam Newman, *Building Microservices*, 2.ª edición (2021), el capítulo de migración y el patrón
  *strangler fig*.

**Orden de lectura sugerido:** antes, la introducción de Gateway API (los papeles y personas); durante, la guía
de *HTTP routing*; después, el capítulo de Newman sobre el *strangler*, con la sección 6.1 delante.

> ⚠️ Las URL y los contenidos cambian; las de Envoy Gateway tienen selector de versión.

---

## 🏁 17. Resultado de la fase

```text
LA ENTRADA AL CERRAR LA FASE 10 (minimo)

  127.0.0.1:8080 ──► NodePort 30080 ──► proxy Envoy (Gateway lab, namespace gateway)
     storefront.localhost/        ──► storefront
     api.localhost/pricing/…      ──► pricing      (antes: 80 % Contingencia → hoy: 0 %)
     api.localhost/inventory/…    ──► inventory
     api.localhost/catalog/…      ──► catalog      (+ CORS para storefront.localhost)
     api.localhost/replenish/…    ──► replenish
  legacy: contingencia (+ fachada :8081) · contingencia-db · portal   — encendidos, sin tráfico de precios
```

> **La señal de que quedó bien:** *"Le saco tráfico a un sistema moviendo un número, sin apagarlo, y
> sé que el sistema nuevo contesta lo mismo antes de mandarle la primera petición."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde y `git status` limpio:
>
> ```bash
> git tag -a fase-10-la-entrada-al-sistema -m "F10 cerrada: Envoy Gateway con NodePort fijo; una HTTPRoute por servicio; CORS para el storefront; patrimonio en legacy con su fachada; strangler 80/20 a 0/100; incidente 08"
> ```
>
> Y el par del incidente: `inc/08/route-wrong-parent-roto` e `inc/08/route-wrong-parent-fix`. Commits
> con prefijo `f10:` ([convención de git](00-convencion-de-git-y-tags.md)).

---

## 📌 Pendientes sugeridos

- **`a16`:** la fachada REST de Contingencia (`PriceFacadeServlet`) y su nginx son de esta fase;
  conviene nombrarlas en el apéndice del patrimonio como lo que se le agregó para sacarlo.
- **F19:** el listener de 8443 en la misma `Gateway`.
