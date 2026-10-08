# 📎 Apéndice a05 — Los diccionarios
## Laboratorio de contenedores y Kubernetes local

> **Curso:** Laboratorio de contenedores y Kubernetes local · Consulta
> **Usado por:** las fases que traen 📖 o 🌩️, empezando por la [Fase 06](06-del-compose-al-cluster.md) · **Versiones cubiertas:** las de [a01](a01-el-laboratorio.md)
> **Fecha de verificación ejecutada:** 03/10/2026 (compose ⇄ Kubernetes, en la [Fase 06](06-del-compose-al-cluster.md)) a 05/10/2026 (las filas de los apéndices 🔥) · macOS arm64; las columnas de la nube, no verificadas

**Esto no se lee de corrido.** Se entra buscando una palabra que conoces para encontrar la que
todavía no, o al revés. Son tres diccionarios, y los tres se leen **en las dos direcciones**: del
mundo que traes al que estás aprendiendo, y de vuelta, porque el día que te toque leer el sistema de
otro equipo vas a necesitar el camino contrario.

**Qué queda fuera:** precios, que cambian más rápido que este documento; y cualquier
comportamiento de un proveedor de nube que no se haya verificado, que no se promete.

> 📝 **Este apéndice creció con el curso** y está completo: el diccionario compose ⇄ Kubernetes desde la
> [Fase 06](06-del-compose-al-cluster.md), y las otras dos tablas con las filas de cada fase y de los apéndices 🔥
> que las traducen.

---

## Índice

- [Las reglas de los tres diccionarios](#-las-reglas-de-los-tres-diccionarios)
- [compose ⇄ Kubernetes](#-compose--kubernetes)
- [`Ingress` ⇄ Gateway API](#-ingress--gateway-api)
- [Local ⇄ nube](#️-local--nube)
- [Cuándo usar qué](#-cuándo-usar-qué)
- [Referencias](#-referencias)
- [Ejercicios](#-ejercicios-6)

---

## 🧭 Las reglas de los tres diccionarios

- **Las dos direcciones, siempre.** Una tabla que solo traduce hacia Kubernetes está a medias.
- **Lo que no tiene traducción, se dice.** Una celda vacía no es una omisión: lleva *sin
  equivalente* y una línea de por qué, porque ahí suele estar la lección.
- **Una fila, una fase.** Cada fila dice en qué fase se desarrolla, para que la traducción no
  reemplace a la explicación.
- **Los nombres son los del laboratorio**: los servicios, los namespaces y las rutas del curso, no
  ejemplos genéricos.

---

## 🐳 compose ⇄ Kubernetes

Del archivo que ya sabes escribir a los objetos que lo reemplazan, y de vuelta. Es el diccionario
que más vas a usar en la Parte II.

### De compose a Kubernetes

| En compose | En Kubernetes | Lo que cambia | Fase |
|---|---|---|---|
| un servicio de `services:` | un `Deployment` y un `Service` | lo que corre y el nombre que lo encuentra son dos objetos distintos | 08 |
| `image:` | `containers[].image`, por digest | el nodo no ve las imágenes de tu motor: hay que cargarlas o publicarlas | 08 |
| `build:` | *sin equivalente* | el cluster no construye: recibe imágenes hechas | 04, 08 |
| `ports:` (publicar en el host) | `Service` `ClusterIP`, y la entrada por un `Gateway` | nada se publica en tu máquina; se expone dentro y se entra por una puerta | 08, 10 |
| el nombre del servicio en la red del proyecto | el DNS del cluster: `pricing.apps.svc.cluster.local` | el nombre lleva namespace, y lo resuelve un `Service`, no el motor | 08, 09 |
| `environment:` | `env`, o `envFrom` desde un `ConfigMap` o un `Secret` | la configuración es un objeto aparte, y cambiarlo no reinicia nada | 09, 11 |
| `volumes:` con nombre | `PersistentVolumeClaim`, que cumple una `StorageClass` con un `PersistentVolume` | el disco lo pide el pod y lo da el cluster; en kind, una carpeta del nodo que no sobrevive a `kind delete cluster` | 12 |
| un servicio de base de datos (`image: postgres`) con su volumen | un `StatefulSet` con `volumeClaimTemplates` y un `Service` headless | cada réplica, su disco y su nombre estable (`postgres-0.postgres.data…`) | 12 |
| el `.sql` en `docker-entrypoint-initdb.d` | lo mismo, desde un `ConfigMap` | corre una vez, con la carpeta de datos vacía | 12 |
| migrar al arrancar el contenedor | un `Job` de migraciones, antes del rollout | una sola ejecución: dos réplicas que migran a la vez compiten (`duplicate key value`) | 12 |
| `docker compose run --rm seed` | un `Job` | se reintenta solo hasta `backoffLimit`, y no se puede volver a aplicar con otro contenido | 12 |
| `cron` dentro de un contenedor | un `CronJob` | `concurrencyPolicy` y `activeDeadlineSeconds` hacen lo que hacía el archivo de bloqueo | 12 |
| `volumes:` con carpeta del host | un `ConfigMap` montado, o `hostPath` (casi nunca) | la carpeta es del nodo, no de tu portátil | 11, 12 |
| `depends_on:` | *sin equivalente* | nadie espera a nadie: cada servicio tolera que el otro no esté, y la readiness dice cuándo puede atender | 06, 15 |
| `healthcheck:` | `livenessProbe`, `readinessProbe` y `startupProbe` | la sonda la hace el kubelet desde afuera, y separa "vivo" de "listo" | 06, 15 |
| `restart: always` | el controlador del `Deployment` | no reinicia un contenedor: reemplaza pods hasta tener los que pediste, siempre | 06, 08 |
| `--scale` o `deploy.replicas` | `replicas:` del `Deployment` | el `Service` reparte entre las réplicas listas | 06, 16 |
| `network_mode: service:catalog` | dos contenedores en el mismo pod | en compose es una excepción; en Kubernetes es la unidad | 04, 09 |
| `entrypoint:` · `command:` | `command:` · `args:` | los nombres están cruzados: el `command` de Kubernetes reemplaza el `ENTRYPOINT` | 08 |
| `mem_limit` · `cpus` | `resources.limits`, y además `resources.requests` | lo que se le promete al planificador es otro número; pasar el de memoria es `OOMKilled`, y el de CPU frena aunque el nodo esté ocioso | 15 |
| `stop_grace_period` | `terminationGracePeriodSeconds` | lo mismo, y cuenta en cada rollout | 16 |
| *sin equivalente* | `lifecycle.preStop` | una pausa antes de `SIGTERM`, para que la puerta deje de mandar tráfico: sin ella, un rollout con carga perdió 18–39 peticiones de 8.000 | 16 |
| `docker stats` | `kubectl top` (con metrics-server) | la misma lectura, por pod y por contenedor | 16 |
| `docker stats`, guardado en el tiempo | cAdvisor, leído por Prometheus por el proxy de la API | la misma lectura de los cgroups, con historia y consultable; cada nodo publica miles de series y conviene quedarse con las que se miran | 17 |
| la lista de contenedores a vigilar, escrita a mano | `kubernetes_sd_configs` con `relabel_configs` | Prometheus le pregunta a la API qué pods hay, y las labels del contrato deciden a cuáles va | 17 |
| `docker logs` | `kubectl logs` | lo mismo, y se va con el pod: lo que no recogió un recolector, no existe después de un rollout | 18 |
| un archivo de log con `logrotate` | stdout, que el runtime guarda y el kubelet rota | un archivo propio dentro del contenedor no lo ve nadie y crece en su capa escribible | 18 |
| el certificado y la clave en un volumen de nginx | un `Secret` `kubernetes.io/tls` referido desde el listener del `Gateway` | la puerta lo relee sola cuando cambia | 19 |
| `certbot` en un cron, o el recordatorio en el calendario | cert-manager: `ClusterIssuer` y `Certificate` | renueva antes de vencer; el `Secret` lo escribe él | 19 |
| la CA copiada en cada imagen | trust-manager: un `Bundle` que escribe un `ConfigMap` por namespace | la CA cambia en un solo lugar | 19 |
| `insecure-registries` en el `daemon.json` | `certs.d/<registry>/hosts.toml` y `ca.crt` en el containerd de cada nodo | el motor del host y el de cada nodo son clientes distintos | 19 |
| `user:` en el servicio | `securityContext.runAsUser` con `runAsNonRoot` | el cluster lo exige, y necesita el número: con un nombre, no arranca | 20 |
| `read_only: true` y `tmpfs:` | `readOnlyRootFilesystem` y un `emptyDir` donde se escribe | lo mismo, por contenedor | 20 |
| `docker inspect` | `kubectl describe` | incluye los eventos del objeto | 21 |
| `docker events` | `kubectl events` | duran una hora y cubren todos los objetos | 21 |
| `docker run --pid=container:<id>` con herramientas | `kubectl debug --target` (un contenedor efímero) | queda en el pod hasta que el pod se va, y hereda su `runAsUser` | 21 |
| `-p` para probar un puerto | `kubectl port-forward` | se salta la puerta y las `NetworkPolicy` | 21 |
| el timeout del pool del servidor de aplicaciones | el timeout del cliente HTTP, en el código | nadie lo pone por ti: sin él, un vecino lento ocupa los hilos de todos (la cascada) | 22 |
| `restart: on-failure` | el reinicio del kubelet | reinicia lo que muere, no lo que tarda | 22 |
| `init: true` | *sin equivalente directo* | el proceso 1 sigue siendo asunto de la imagen | 03 |
| `profiles:` | namespaces separados, o valores del chart | lo que se enciende es un paquete, no una lista de servicios | 13 |
| `compose.override.yaml`, o varios `-f` | `values.yaml` y `values-<perfil>.yaml`, con varios `-f` | el override reemplaza claves; un valor alimenta una plantilla | 13 |
| `docker compose config` | `helm template` | ver lo que se va a aplicar sin aplicarlo; Helm no escribe el namespace | 13 |
| `docker compose up -d` | `helm upgrade --install` | cada despliegue es una revisión guardada en el cluster | 13 |
| `depends_on: {condition: service_completed_successfully}` | un *hook* `pre-install,pre-upgrade` | el hook detiene el release entero hasta terminar, no solo un servicio | 13 |
| `docker compose down` | `helm uninstall` | los `Job` de los hooks no son del release y quedan | 13 |
| `git diff` antes de `up -d` | `helm diff upgrade --three-way-merge` (`task deploy:diff`) | compara contra lo vivo; sin `--three-way-merge`, contra el release, y no ve lo cambiado a mano | 14 |
| `git revert` y `up -d` | `helm rollback` | una revisión nueva igual a una vieja; el archivo de valores y los datos no vuelven | 14 |
| dos proyectos con `-p` | dos releases en dos namespaces | comparten la puerta del cluster: con el mismo host, las rutas compiten y gana la más vieja | 14 |
| `compose.override.yaml` (sin plantillas) | Kustomize (`kubectl kustomize`, `apply -k`) | parches sobre YAML plano; sin releases, rollback ni hooks | 14 |
| el archivo `.env` del proyecto | un `ConfigMap` para lo que se puede ver y un `Secret` para lo que no | el `Secret` es base64, no cifrado: lo protegen los permisos, no el formato | 11 |
| `secrets:` (un archivo montado en `/run/secrets/`) | un `Secret` montado como carpeta, o como variables con `secretKeyRef` | si el `Secret` falta, el contenedor ni se crea: `CreateContainerConfigError` | 11 |
| `up -d` después de cambiar la configuración | `kubectl rollout restart` | en compose, cambiar y reiniciar son un gesto; aquí, dos, y el segundo nadie lo hace solo | 11 |
| `build.args` (un `ARG` del Dockerfile) | *sin equivalente* | lo que se decide al construir no lo cambia ningún objeto del cluster: por eso G2 lee su configuración al arrancar | 11 |
| el agente de APM instalado en el servidor | OpenTelemetry en la imagen, las variables `OTEL_*` en el chart, y Tempo en `observability` | la instrumentación viaja con la imagen; a dónde manda, y si manda, lo decide el despliegue | 23 |

### De Kubernetes a compose

Lo que vas a encontrar en un cluster ajeno, y cómo se vería (o por qué no se ve) en un `compose.yaml`:

| En Kubernetes | En compose | Por qué | Fase |
|---|---|---|---|
| `Namespace` | *sin equivalente*; a lo sumo, otro proyecto | compose no separa nombres, permisos ni cuotas dentro de un proyecto | 09 |
| `ServiceAccount` y RBAC | *sin equivalente* | en compose nadie le pide permiso a nadie: quien tiene el socket tiene todo; en el cluster, un pod sin permiso recibe un 403 de la API | 20 |
| el planificador | *sin equivalente* | compose corre en una máquina; no decide dónde | 07, 16 |
| el bucle de reconciliación | `up -d`, cuando tú lo corres | compose reconcilia una vez, al llamarlo; el cluster, todo el tiempo | 06 |
| `Job` y `CronJob` | `run --rm`, y el cron de la máquina | compose no programa nada | 12 |
| `StatefulSet` con varias réplicas | *sin equivalente* | compose no da a cada réplica un disco y un nombre propios | 12 |
| `PersistentVolume` y `StorageClass` | *sin equivalente*: el volumen lo crea el motor | en el cluster, el disco lo da un provisionador; en compose, tu disco | 12 |
| `DaemonSet` | *sin equivalente*; a lo sumo, un contenedor más con la carpeta de logs del motor montada | hay una sola máquina; en el cluster, un pod por nodo donde pueda correr (los *taints* cuentan) | 18 |
| `HorizontalPodAutoscaler` | *sin equivalente* | `--scale` es a mano | 16 |
| `NetworkPolicy` | redes separadas en el archivo | la red de compose deja hablar a todos con todos; la política elige por labels, y solo protege si la red del cluster la aplica (kindnet sí) | 20 |
| `ResourceQuota` y `LimitRange` | *sin equivalente* | | 15 |
| `Gateway` y `HTTPRoute` | un proxy más en el archivo | la entrada es un objeto de la plataforma, no un contenedor que tú agregas | 10 |
| un `ConfigMap` montado como carpeta, que se actualiza solo | un volumen de solo lectura con un archivo del host | en compose el archivo cambia cuando alguien lo edita; en el cluster, cuando el kubelet sincroniza (60–90 s en la verificación) | 11 |
| `Secret` | un archivo fuera de git, montado con `secrets:` | es lo mismo, con permisos de por medio | 11 |
| un release de Helm y sus revisiones | *sin equivalente* | compose no recuerda qué aplicó ni con qué valores: lo recuerdan git y quien lo corrió | 13 |
| los dueños de cada campo (`managedFields`) | *sin equivalente* | en compose el último que corre `up` gana, sin conflicto ni aviso | 13 |
| un `Service` `ClusterIP` delante de varias réplicas | *sin equivalente*: el cliente llega al contenedor por su nombre | es una IP virtual que elige réplica **al abrir cada conexión**; con HTTP/2 o gRPC, una conexión lleva todo el tráfico (B-23: 100 % a una réplica) | 23 |
| un `Service` *headless* (`clusterIP: None`) | *sin equivalente* | el DNS contesta con la IP de cada pod listo, y el cliente reparte; si no vuelve a preguntar, no ve las réplicas nuevas | 23 |
| un `ServiceMonitor` del operador de Prometheus | *sin equivalente*; a lo sumo, un `scrape_config` con los nombres de compose | es un `scrape_config` generado: un trabajo con `kubernetes_sd_configs` de rol `endpoints` y un `keep` sobre las labels | 17 |

---

## 🚪 `Ingress` ⇄ Gateway API

> ⚠️ **Esta tabla es para leer clusters ajenos, no para desplegar.** El laboratorio no crea ningún
> objeto `Ingress`: la entrada al sistema es Gateway API. Pero vas a encontrar `Ingress` en casi
> todos los clusters que heredes, con anotaciones que no eran portables entre controladores, y
> necesitas leerlos y traducirlos.

Cada campo y cada anotación común, con su equivalente en `Gateway` o `HTTPRoute`, y lo que no tiene
traducción porque era una extensión de un controlador concreto.

### De `Ingress` a Gateway API

| En `Ingress` | En Gateway API | Lo que cambia | Fase |
|---|---|---|---|
| `ingressClassName: nginx` (o la anotación `kubernetes.io/ingress.class`) | `parentRefs` hacia una `Gateway` (`lab`, en `gateway`) de una `GatewayClass` (`eg`) | la clase y la puerta son dos objetos, y la puerta es de plataforma, no de cada equipo | 10 |
| un `Ingress` por servicio, todos con el mismo controlador | una `HTTPRoute` por servicio, en `apps`, colgada de una sola `Gateway` | cada equipo escribe su ruta sin tocar la puerta | 10 |
| `rules[].host: api.localhost` | `HTTPRoute.spec.hostnames: ["api.localhost"]` | igual, en otro sitio | 10 |
| `paths[].path: /pricing` con `pathType: Prefix` | `matches[].path` con `type: PathPrefix`, `value: /pricing` | igual | 10 |
| la anotación de reescritura del controlador (`rewrite-target`) | el filtro `URLRewrite` con `ReplacePrefixMatch: /`, del estándar | deja de depender del controlador | 10 |
| las anotaciones de *canary* con un porcentaje | `weight` en cada `backendRef` (el 80/20 del *strangler*) | del estándar, y sin un segundo `Ingress` | 10 |
| la anotación de CORS del controlador | el filtro `CORS` de la `HTTPRoute` | es del estándar, con soporte extendido: la implementación decide si lo trae (Envoy Gateway, sí) | 10 |
| un backend en otro namespace | *sin equivalente*: `Ingress` solo apunta a `Service` de su namespace | en Gateway API se puede, con `namespace` en el `backendRef` y un `ReferenceGrant` del destino | 10 |
| `defaultBackend` | una regla sin `matches`, o nada: la puerta contesta 404 sin cuerpo | el 404 de la puerta se distingue del del servicio (incidente 08) | 10 |
| `spec.tls` con `secretName`, en cada `Ingress` | un *listener* `HTTPS` de la `Gateway` con `certificateRefs` | el certificado es de la puerta, no de cada ruta: los equipos no tocan `Secret` de TLS | 19 |
| la anotación de timeout del controlador (`proxy-read-timeout`) | `timeouts.request` en la regla de la `HTTPRoute` | del estándar; el curso lo nombra y deja el de Envoy (15 s) | 22 |
| la anotación de reintentos del controlador | `retry` en la regla de la `HTTPRoute` (canal experimental) | del estándar, pero no todos los controladores lo implementan; [a10](a10-service-mesh.md) lo usó entre servicios, con Istio | 22, a10 |
| la anotación que declara el backend como gRPC | `GRPCRoute`, con `matches` por servicio y método | un tipo de ruta propio, no una anotación; el curso la nombra y no la usa | 23 |

### De Gateway API a `Ingress`

| En Gateway API | En `Ingress` | Lo que se pierde | Fase |
|---|---|---|---|
| `GatewayClass` + `Gateway` | `IngressClass` y el controlador instalado | la puerta como objeto: en `Ingress` no hay dónde escribir quién puede colgarse | 10 |
| `allowedRoutes` de la `Gateway` | *sin equivalente* | cualquier namespace puede crear un `Ingress` para la clase | 10 |
| `ReferenceGrant` | *sin equivalente* | no hay backends en otro namespace que autorizar | 10 |
| `weight` en `backendRefs` | anotaciones propias de cada controlador, si las tiene | la portabilidad: el mismo YAML hace otra cosa con otro controlador | 10 |
| `URLRewrite` | anotación propia de cada controlador | la portabilidad | 10 |
| `status.parents[].conditions` (`Accepted`, `ResolvedRefs`) | `status.loadBalancer` y los eventos del controlador | saber si la ruta se aceptó, y por qué no | 10 |
| `GRPCRoute` | una anotación del controlador sobre un `Ingress` HTTP | enrutar por servicio y método de gRPC | 23 |
| `timeouts` y `retry` en la regla | anotaciones propias de cada controlador | la portabilidad, otra vez | 22 |

> ⚠️ El controlador de `Ingress` más usado, ingress-nginx, se retiró en marzo de 2026. Las
> anotaciones de las filas son las de ese controlador, para reconocerlas; ninguna se verificó en el
> laboratorio.

---

## 🌩️ Local ⇄ nube

Lo que el laboratorio te da en tu portátil, y lo que es esa misma pieza en un cluster gestionado.
Las columnas de la nube son **OCI y Azure**, las dos que discute Droguerías La Vecina en su
[historia](00-historia-de-la-vecina.md); el diccionario no recomienda ninguna.

| En el laboratorio | En OCI | En Azure | 🚧 Lo que el laboratorio nunca te da |
|---|---|---|---|
| un cluster de kind en tu portátil | un cluster gestionado de Kubernetes (OKE) | un cluster gestionado de Kubernetes (AKS) | el plano de control que administra otro, con su acuerdo de servicio |
| un nodo es un contenedor | un nodo es una máquina virtual de cómputo | un nodo es una máquina virtual de un conjunto de escalado | que un nodo se caiga de verdad, con su disco y su red |
| el contexto `kind-minimo` | el contexto que genera la CLI del proveedor (`oci`) | el contexto que genera la CLI del proveedor (`az`) | identidades del proveedor dentro del `kubeconfig` |
| `extraPortMappings` al host | un balanceador del proveedor, con IP pública | un balanceador del proveedor, con IP pública | una IP pública y lo que cuesta |
| un `Service` `LoadBalancer` en `<pending>`, o con la IP de cloud-provider-kind que no llega al host | el controlador del proveedor crea un balanceador y escribe su IP en el `status` | lo mismo, con el balanceador de Azure | el balanceador que llega desde internet |
| la `Gateway` `lab` con su proxy en `NodePort` 30080 | la misma `Gateway`, con su proxy detrás de un `Service` `LoadBalancer` del proveedor | lo mismo; Azure ofrece además su propio controlador de Gateway API | un balanceador por puerta, y su costo mensual |
| `*.localhost`, que resuelve solo a tu máquina | un nombre en un DNS del proveedor (o del de la empresa) apuntando a la IP del balanceador | lo mismo | el DNS público y su certificado |
| la `StorageClass` `standard` (una carpeta del nodo) | la clase de volúmenes de bloque del proveedor (`oci-bv`) | la clase de discos administrados del proveedor | un disco que sobrevive al cluster, con su costo por GB y su zona |
| Postgres en un `StatefulSet` escrito a mano | un servicio gestionado de Postgres del proveedor | lo mismo | respaldos, réplicas y actualizaciones que hace otro |
| un nodo de 3,8 GiB asignables; un pod que no cabe queda `Pending` | grupos de nodos con autoescalado: un pod `Pending` por `requests` crea un nodo | lo mismo, con el autoescalador de nodos de AKS | la factura de un nodo nuevo, que se decide por promesas (`requests`) y no por uso |
| Prometheus y Grafana en el namespace `observability`, con dos días en un `emptyDir` | un servicio gestionado de Prometheus y uno de Grafana | lo mismo, con los gestionados de Azure | retención por meses, y una factura por serie guardada y por consulta: cada etiqueta con muchos valores se paga todos los meses |
| Fluent Bit como `DaemonSet` y Loki con dos días en un `emptyDir` | el agente de logs del proveedor, y su servicio de logs | lo mismo, con el servicio de logs de Azure | retención larga, y una factura por GB ingerido y guardado: las sondas también se pagan |
| Tempo con un día en un `emptyDir`, y OpenTelemetry en los cuatro servicios | el servicio de trazas del proveedor, que recibe OTLP | lo mismo, con el de Azure | retención y muestreo, y una factura por span: guardar el 100 % de las trazas, como el laboratorio, no se paga en producción |
| la saga del préstamo escrita a mano en `inventory`: su estado en dos tablas y un barrido cada 30 s | un motor de flujos de trabajo del proveedor (Oracle anunció OCI Workflow en disponibilidad limitada; Oracle Integration orquesta integraciones): el estado y los reintentos los guarda el servicio | Durable Functions (orquestaciones con estado) o Logic Apps | un orquestador que no muere con tu pod; pero las compensaciones, el orden de los pasos y qué hacer con un vecino que no contesta los sigues escribiendo tú |
| Valkey pub/sub y NATS JetStream en `data`, un proceso cada uno | el servicio de colas o de *streaming* del proveedor (OCI Queue, OCI Streaming) | Service Bus (colas y temas) o Event Hubs | un bus replicado en varias zonas que no pierde lo confirmado; la idempotencia del consumidor sigue siendo tuya |
| la cabecera `Nats-Msg-Id` (JetStream descarta la copia dentro de su ventana) y `processed_events` en `replenish` | la deduplicación del servicio de colas, donde la tenga | la detección de duplicados de Service Bus, con su ventana | ninguna deduplicación del bus cubre al consumidor fuera de su ventana: la tabla de procesados sigue siendo tuya |
| cert-manager con una CA propia, para `*.localhost` | cert-manager con ACME, o el servicio de certificados del proveedor, con una CA pública | lo mismo, con el de Azure | un dominio público verificable desde internet; adentro, la CA propia sigue valiendo para el mTLS |
| un portátil arm64 que emula amd64 con Rosetta ([a06](a06-arquitecturas-y-multiplataforma.md)) | nodos arm64 (las formas Ampere A1) o amd64, a elección por grupo de nodos | máquinas virtuales Arm64 o amd64, también por grupo de nodos | una imagen multiplataforma que se prueba en la arquitectura de producción, no emulada |
| Istio ambient instalado con Helm ([a10](a10-service-mesh.md)) | Istio instalado por ti en OKE | un complemento de AKS basado en Istio, que el proveedor actualiza | un plano de control del mesh que actualiza otro; el costo en memoria sigue en tus nodos |
| Argo CD instalado con su manifiesto ([a11](a11-gitops-de-lectura.md)) | Argo CD o Flux, instalados por ti | la extensión de GitOps de AKS (Flux) | el controlador como servicio; el repositorio, las ramas y la promoción siguen siendo tuyos |
| `pg_dump` en un `CronJob`, a un PVC del mismo cluster ([a13](a13-respaldo-y-restauracion.md)) | los respaldos de los volúmenes de bloque, o los del Postgres gestionado | Azure Backup para AKS, o los del Postgres gestionado | un respaldo fuera del cluster y fuera de la zona; la restauración probada sigue siendo tuya |

Las columnas de la nube son descriptivas y **no están verificadas en el laboratorio**: este curso no
despliega en una nube de pago. Filas de los apéndices [a06](a06-arquitecturas-y-multiplataforma.md), [a10](a10-service-mesh.md),
[a11](a11-gitops-de-lectura.md) y [a13](a13-respaldo-y-restauracion.md), y de las fases [07](07-el-cluster-local.md),
[10](10-la-entrada-al-sistema.md), [12](12-estado-y-almacenamiento.md), [15](15-salud-y-recursos.md), [17](17-metricas-y-dashboards.md), [18](18-logs.md), [19](19-tls-y-certificados.md), [20](20-seguridad-del-pod-y-de-la-red.md), [23](23-grpc-y-el-balanceo.md), [24](24-la-saga-orquestada.md), [25](25-la-coreografia.md) y [26](26-idempotencia-y-outbox.md).

> 📝 AWS y Google Cloud tienen equivalentes para casi todas las filas, y se nombran al pie de cada
> una cuando la diferencia importa (para la saga: Step Functions en AWS, Workflows en Google Cloud; para el bus, SQS y SNS en AWS, Pub/Sub en Google Cloud). No tienen columna porque la historia no los discute.

---

## 🧭 Cuándo usar qué

| Si tienes… | Y necesitas… | Abre |
|---|---|---|
| un `compose.yaml` que funciona | saber qué objetos lo reemplazan | compose ⇄ Kubernetes |
| un cluster ajeno con `Ingress` | entender qué hace su entrada | `Ingress` ⇄ Gateway API |
| algo que funciona en el laboratorio | saber qué pieza es en la nube y en qué se diferencia | local ⇄ nube |

---

## 📚 Referencias

- Docker, *Compose file reference*: https://docs.docker.com/reference/compose-file/ — la columna de compose.
- Kubernetes, *Ingress*: https://kubernetes.io/docs/concepts/services-networking/ingress/ — para leer los que heredes.
- Gateway API, *Migrating from Ingress*: https://gateway-api.sigs.k8s.io/guides/getting-started/migrating-from-ingress/
- Kubernetes, *ConfigMaps*, *Secrets*, *Persistent Volumes*, *StatefulSets*, *Jobs* y *CronJob*: las páginas
  de cada concepto en https://kubernetes.io/docs/concepts/
- Gateway API, *HTTPRoute* (`timeouts`, `retry`, filtros): https://gateway-api.sigs.k8s.io/reference/api-types/httproute/ ·
  *GRPCRoute*: https://gateway-api.sigs.k8s.io/reference/api-types/grpcroute/
- Oracle, *Container Engine for Kubernetes (OKE)*: https://docs.oracle.com/en-us/iaas/Content/ContEng/home.htm
- Microsoft, *Azure Kubernetes Service (AKS)*: https://learn.microsoft.com/azure/aks/

> ⚠️ Las URL y los contenidos cambian; cada referencia avisa si apunta a otra versión.

---

## 🧪 Ejercicios (6)

### 🟢 Ejercicio 1 — De vuelta a compose
Toma el `Deployment`, el `Service` y el `ConfigMap` de `pricing` del cluster (`kubectl get … -o yaml`) y escribe el
servicio de compose equivalente.

**Criterio:** `pricing` arriba en compose con ese servicio, y la lista de lo que no pudiste traducir, con su fila de la
tabla.

### 🟢 Ejercicio 2 — Un `Ingress` heredado
Traduce este `Ingress` a una `HTTPRoute` del laboratorio:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: pricing
  namespace: apps
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
    - host: api.localhost
      http:
        paths:
          - path: /precios(/|$)(.*)
            pathType: ImplementationSpecific
            backend: {service: {name: pricing, port: {number: 8080}}}
```

**Criterio:** la `HTTPRoute` aceptada por la puerta (`Accepted=True`) y `curl http://api.localhost:8080/precios/prices/SKU-0003?store=DRO-007`
con 200; y qué hiciste con la expresión regular, que Gateway API no tiene.

### 🟡 Ejercicio 3 — Lo que se pierde al volver
Escribe el `Ingress` que más se parezca a la `HTTPRoute` de `inventory` del chart, para un controlador que no conoces.

**Criterio:** cada campo que no pudiste escribir sin una anotación, con la fila de "De Gateway API a `Ingress`" que lo
explica.

### 🟡 Ejercicio 4 — Una fila con su número
Elige una fila de local ⇄ nube y ponle el costo mensual de su columna de OCI y de Azure, con la calculadora de cada
proveedor y la fecha.

**Criterio:** los dos números con su fecha y su enlace, y la frase de la columna 🚧 reescrita con ellos.

### 🟠 Ejercicio 5 — El diccionario de la segunda cadena
La segunda cadena de la [Fase 14](14-helm-en-operacion.md) vive en `apps-b`. Escribe las filas de local ⇄ nube que
cambian cuando son diez cadenas y no dos.

**Criterio:** al menos tres filas nuevas o cambiadas, cada una con su fase del curso.

### 🔴 Ejercicio 6 — La oferta del proveedor
Un proveedor le ofrece a La Vecina "Kubernetes gestionado con todo incluido". Usa las tres preguntas de la
[Fase 27](27-el-veredicto-y-el-proyecto-final.md#️-5-el-diccionario-local--nube-consolidado) y la columna 🚧 para leer la
oferta.

**Criterio:** media página: qué filas de la tabla cubre la oferta, cuáles deja en manos del equipo, y la que más
cuesta de las que deja.

---

> 🏷️ **Este apéndice no lleva tag propio.** No deja archivos en el repositorio: sus filas viven en
> este documento.
