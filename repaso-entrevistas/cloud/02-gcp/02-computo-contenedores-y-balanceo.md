# 02 — Cómputo, contenedores y balanceo

> **Objetivo:** saber elegir entre Compute Engine, Cloud Run, GKE y Cloud Functions con un
> argumento, y entender cómo encaja Cloud Load Balancing por encima de todos ellos.
> **Se asume leído:** [`01` — infraestructura global y redes](01-infraestructura-global-y-redes.md).
> **Se toca sobre todo con:** [`01`](01-infraestructura-global-y-redes.md) y
> [`12` — orquestación y CI/CD](12-orquestacion-y-cicd.md).
> **Dónde se practica:** [`L05` — Cloud Run: contrato, revisiones y tráfico](l05-cloud-run-contrato-revisiones-y-trafico.md).
> **Vigencia:** 6 de septiembre de 2026.

**Salto rápido:** [Panorama](#1--panorama-de-cómputo-en-gcp) · [Compute Engine](#2--compute-engine) · [Managed Instance Groups (MIG)](#3--managed-instance-groups-mig) ·
[Cloud Load Balancing](#5--cloud-load-balancing-como-stack-unificado) · [External HTTP(S) LB](#6--external-https-load-balancing) · [Artifact Registry](#11--container-images-y-artifact-registry) ·
[Cloud Run](#12--cloud-run) · [GKE](#13--gke--google-kubernetes-engine) · [Cloud Functions (2nd gen)](#14--cloud-functions-2nd-gen) ·
[Comparaciones](#16--comparaciones-de-contenerización) · [Arquitectura de referencia](#17--arquitectura-de-referencia) · [Preguntas rápidas](#-preguntas-rápidas)

## 1. 🧭 Panorama de cómputo en GCP

```text
Compute Engine   → VM tradicional, control total del SO
Cloud Run        → serverless para containers, request-driven o job-driven
GKE              → Kubernetes administrado, control fino
Cloud Functions  → funciones serverless, event-driven, construidas sobre Cloud Run (2nd gen)
```

Regla de entrevista:

```text
Cloud Run   → compute serverless para containers
GKE         → orquestación completa de Kubernetes
```

Ninguno reemplaza universalmente a los otros: la elección depende de
cuánto control de infraestructura necesitas y de qué tan lejos está tu
carga del modelo "container stateless request-driven".

---

# Parte I — Compute Engine

## 2. 🧱 Compute Engine

**Compute Engine** ofrece máquinas virtuales con control total del
sistema operativo. Es el recurso **zonal** por excelencia.

### Images

Una **Image** es una plantilla (SO + configuración base) usada para crear
discos de arranque. Puede ser:

- **pública**, mantenida por Google o por un proveedor (Debian, Ubuntu,
  Windows Server, etc.);
- **custom**, creada a partir de un disco/VM propio, para incluir
  software preinstalado o configuración estandarizada.

Las Images son un recurso **global**.

### Machine types y familias

| Familia | Enfoque |
|---|---|
| General-purpose (ej. `e2`, `n2`) | Balance CPU/memoria para la mayoría de cargas backend |
| Compute-optimized (ej. `c2`) | Cargas CPU-bound: procesamiento intensivo, HPC |
| Memory-optimized (ej. `m2`) | Cargas memory-bound: bases de datos in-memory grandes, analítica |

Para una app Spring Boot típica, general-purpose es el punto de partida
correcto salvo que el perfil de carga demuestre lo contrario.

### Persistent Disk

Block storage adjuntable a instancias.

| | Zonal | Regional |
|---|---|---|
| Alcance | Una sola Zone | Replicado síncronamente entre dos Zones de una Region |
| Resiliencia | Se pierde si la Zone falla | Sobrevive a la falla de una Zone |
| Uso típico | Cargas donde el failover se resuelve a otro nivel (ej. réplicas de base de datos) | Cargas que necesitan alta disponibilidad del disco mismo |

### Sole-tenant nodes y placement policies

Los **sole-tenant nodes** dedican hardware físico exclusivamente a las
VMs de un proyecto — relevante para requisitos de compliance/licenciamiento
que exigen aislamiento físico. Las **placement policies** controlan la
colocación física relativa de un grupo de VMs (compactas para baja
latencia entre ellas, o distribuidas para reducir el impacto de una falla
de hardware compartido). Son mecanismos avanzados, no necesarios para la
mayoría de arquitecturas backend.

---

## 3. 🧱 Managed Instance Groups (MIG)

Un **Managed Instance Group** administra un conjunto de instancias
idénticas creadas a partir de una **Instance Template**.

```text
Instance Template (define machine type, image, disco, metadata)
        │
        ▼
Managed Instance Group
    ├── Instance 1
    ├── Instance 2
    └── Instance 3
```

Puede ser zonal o regional (distribuido entre varias Zones de una
Region).

### Health Checks

Un MIG usa Health Checks para determinar si una instancia está sana. Una
instancia que falla el health check puede ser recreada automáticamente
(auto-healing).

### Escalado

| Tipo | Mecanismo |
|---|---|
| Vertical (scale up) | Cambiar a un machine type más grande |
| Horizontal (scale out) | Autoscaling del MIG: agregar/quitar instancias según métricas (CPU, carga del balanceador, métricas custom) |

En cloud se prefiere scale out cuando la carga lo permite: evita el
límite superior de una sola máquina y encaja naturalmente con Managed
Instance Groups y Cloud Load Balancing.

### Alta disponibilidad

Un MIG regional distribuye instancias entre varias Zones, de forma que la
pérdida de una Zone no tumba el servicio completo.

---

## 4. ⚖ Comparaciones de cómputo

```text
Compute Engine vs Cloud Functions
Compute Engine vs containers (Cloud Run/GKE)
Scale Up vs Scale Out
Persistent Disk zonal vs regional
```

| | Compute Engine | Cloud Functions |
|---|---|---|
| Unidad de despliegue | VM completa | Función individual |
| Control de SO | Total | Ninguno |
| Modelo de escalado | MIG + autoscaling | Escalado automático por invocación |
| Uso típico | Cargas que necesitan control fino de SO/red/kernel | Handlers event-driven pequeños |

---

# Parte II — Load Balancing

## 5. 🧱 Cloud Load Balancing como stack unificado

A diferencia de productos de balanceo separados por caso de uso, **Cloud
Load Balancing** es una capa unificada con distintos tipos de frontend
sobre una arquitectura común (target proxies, backend services, health
checks).

```text
Cloud Load Balancing
├── External HTTP(S) Load Balancing   (global, Layer 7)
├── Internal HTTP(S) Load Balancing   (regional, Layer 7)
└── Network Load Balancing            (Layer 4, externo e interno)
```

> 💰 **Costo.** Un load balancer no es gratis por existir: **cada forwarding rule global cuesta del
> orden de $0.025/h** —unos $18 al mes— más el tráfico procesado, y sobrevive a casi cualquier
> limpieza a mano. Es la trampa de costo número uno de los proyectos de práctica, y la razón de que
> la serie no lo use en el tronco: Cloud Run ya publica una URL HTTPS con certificado administrado
> sin cobrar por ella. Ver
> [`L00` §4](l00-idea-lab-practico.md#4--el-catálogo-completo-de-exclusiones) y
> [`A02`](a02-costos-trampas-y-recursos-huerfanos.md#3--el-catálogo-de-lo-que-cobra-por-existir).

## 6. 🧱 External HTTP(S) Load Balancing

Balanceo **global** de Layer 7 (HTTP/HTTPS). Un solo IP anycast puede
recibir tráfico de todo el mundo y enrutarlo al backend más adecuado
según proximidad y salud.

```text
Internet
   │
Cloud Load Balancing (IP global)
   │
   ├── Backend service region-a
   └── Backend service region-b
```

## 7. 🧱 Internal HTTP(S) Load Balancing

Balanceo **regional** de Layer 7 para tráfico interno dentro de la VPC
(servicio a servicio), sin exponer el frontend a Internet.

## 8. 🧱 Network Load Balancing

Balanceo de **Layer 4** (TCP/UDP), disponible en variantes externa e
interna. Útil cuando el protocolo no es HTTP(S) o cuando necesitas
preservar la IP del cliente y el procesamiento de paquetes más cercano a
la capa de transporte.

```text
External HTTP(S) LB vs Internal HTTP(S) LB
HTTP(S) Load Balancing vs Network Load Balancing
Layer 7 vs Layer 4
```

| | HTTP(S) Load Balancing | Network Load Balancing |
|---|---|---|
| Capa OSI | 7 | 4 |
| Routing por host/path | ✅ | — |
| Terminación TLS en el balanceador | ✅ | Depende de la variante (proxy vs passthrough) |
| Protocolos | HTTP/HTTPS/HTTP2/gRPC | TCP/UDP |

## 9. 🧱 Componentes: target proxies, URL maps, backend services

```text
Cliente
   │
Forwarding rule (IP + puerto)
   │
Target proxy (termina TLS si aplica)
   │
URL map (routing por host/path)
   │
Backend service
   │
Health check + backends (MIG / NEG)
```

Ejemplo de routing por path:

```text
/api/users/*  → User Service (Cloud Run)
/api/orders/* → Order Service (Cloud Run)
```

## 10. 🧱 Integración con MIG y con Cloud Run/GKE

- Con **Managed Instance Groups**: el backend service apunta directamente
  al MIG.
- Con **Cloud Run/GKE**: el backend service apunta a un **Network
  Endpoint Group (NEG)**, que expone endpoints serverless o de Pods como
  backend del balanceador.

```text
Cloud Load Balancing
   │
Backend service
   │
Serverless NEG
   │
Cloud Run service
```

---

# Parte III — Contenerización

## 11. 🧱 Container images y Artifact Registry

Una container image empaqueta la aplicación y sus dependencias.
**Artifact Registry** es el registry administrado de GCP para imágenes de
contenedor (y otros artefactos como paquetes de lenguaje). Es el sucesor
de Container Registry.

```text
Container images vs Cloud Functions
Artifact Registry vs Docker Hub
```

| | Artifact Registry | Docker Hub |
|---|---|---|
| Integración con IAM/VPC-SC de GCP | Nativa | No |
| Alcance | Regional/multi-regional dentro de un proyecto GCP | Registro público general |
| Uso típico en GCP | Registry por defecto para Cloud Run/GKE/Cloud Build | Fuente de imágenes base públicas |

## 12. 🧱 Cloud Run

**Cloud Run** es el eje de esta sección: compute serverless para
containers.

### Services (request-driven)

Reciben tráfico HTTP y escalan según demanda.

```text
Request → Cloud Run service → container
```

### Jobs (batch)

Ejecutan una tarea hasta completarse, sin exponer un endpoint HTTP.

```text
Trigger (manual, scheduler, Pub/Sub) → Cloud Run job → ejecuta y termina
```

### Scale-to-zero

Cuando no hay tráfico, un Cloud Run service puede escalar a **cero
instancias** — no se cobra cómputo en reposo. Al llegar una request nueva,
se crea una instancia (con la latencia de cold start correspondiente).

```text
Regla:
Cloud Run escala a cero por defecto.
```

### Concurrency por instancia

Cada instancia de Cloud Run puede atender **múltiples requests
concurrentes** (configurable), a diferencia de un modelo de una request
por instancia. Esto reduce el número de instancias necesarias para un
mismo throughput, siempre que la aplicación sea segura para concurrencia
dentro del mismo proceso.

### Revisiones y tráfico dividido

Cada deploy crea una **revision** inmutable. El tráfico se puede dividir
entre revisiones (ej. 90 % revision anterior, 10 % revision nueva) para
despliegues graduales/canary sin infraestructura adicional.

```text
Revision A (90 % del tráfico)
Revision B (10 % del tráfico)  ← canary
```

> 💰 **Costo.** Cloud Run **escala a cero y entonces cuesta $0.00**; se factura por vCPU-segundo,
> GiB-segundo y requests, con una cuota Always Free mensual de 2 M requests, 360.000 GiB-s y 180.000
> vCPU-s. El flag que rompe eso es `--min-instances`: una instancia mínima es vCPU y memoria
> facturando 24/7 aunque no llegue una sola petición. Y ojo con Artifact Registry, que **sí** cobra
> por acumulación: la cuota gratuita es de 0,5 GB y cada despliegue deja una imagen más. Las dos
> cosas se practican en
> [`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md#8--min-instances-el-flag-que-rompe-el-cero).

## 13. 🧱 GKE — Google Kubernetes Engine

Kubernetes administrado. Ofrece el ecosistema completo de Kubernetes:
Deployments, StatefulSets, DaemonSets, sidecars, Custom Resources,
Operators, control fino de networking (Network Policies, Service Mesh),
etc.

### GKE Autopilot vs GKE Standard

Concepto propio de GCP sin equivalente directo en otras nubes.

| | GKE Autopilot | GKE Standard |
|---|---|---|
| Administración de nodos | Google administra los nodos por completo | Tú administras el node pool (tipo de máquina, escalado, upgrades) |
| Modelo de facturación | Por recursos de Pod solicitados | Por infraestructura de nodo aprovisionada |
| Control de infraestructura | Limitado (por diseño) | Total |
| Uso típico | Cargas estándar donde no necesitas tunear el nodo | Cargas con requisitos específicos de nodo (DaemonSets privilegiados, GPUs específicas, tuning de kernel) |

```text
GKE Autopilot vs GKE Standard
```

> 💰 **Costo.** GKE cobra **$0.10 por cluster y por hora** de administración, y el Free Tier aporta
> $74.40 mensuales por cuenta de facturación aplicados a clusters zonales y Autopilot — así que el
> control plane de un solo cluster sale prácticamente cubierto. Lo que **no** cubre es lo que de
> verdad se paga: los recursos que piden tus Pods en Autopilot, o las VMs del node pool en Standard,
> encendidas aunque no haya nada desplegado. Y un `Ingress` crea un forwarding rule por su cuenta.
> El razonamiento completo de por qué GKE es un drill y no un lab está en
> [`L00` §3](l00-idea-lab-practico.md#3--el-caso-testigo-por-qué-no-montamos-un-microservicio-en-gke).

## 14. 🧱 Cloud Functions (2nd gen)

Cloud Functions de segunda generación está **construido sobre Cloud
Run**: una función es, bajo el capó, un servicio Cloud Run con un modelo
de despliegue simplificado orientado a un único handler event-driven.

```text
Cloud Run vs Cloud Functions
```

| | Cloud Run | Cloud Functions (2nd gen) |
|---|---|---|
| Unidad de despliegue | Container completo (cualquier lenguaje/runtime) | Función individual en un runtime soportado |
| Control sobre el container | Total (tu propio Dockerfile) | Limitado (Google construye el container por ti) |
| Casos de uso típicos | Servicios HTTP completos, APIs, jobs batch | Handlers pequeños event-driven (trigger de Storage, Pub/Sub, Eventarc) |

## 15. 🧱 Cloud Build

**Cloud Build** ejecuta pasos de build (compilar, testear, construir la
imagen) y publica el resultado en Artifact Registry.

```text
Código fuente
     │
     ▼
Cloud Build (build steps)
     │
     ▼
Artifact Registry (imagen)
     │
     ▼
Cloud Run / GKE (deploy)
```

## 16. ⚖ Comparaciones de contenerización

```text
Cloud Run vs GKE
Cloud Run vs Cloud Functions
GKE Autopilot vs GKE Standard
Compute Engine vs Cloud Run
Artifact Registry vs Docker Hub
Containers vs Cloud Functions
```

> Cloud Run no reemplaza a GKE cuando necesitas control de red fino,
> sidecars complejos, DaemonSets o recursos de Kubernetes específicos
> (Custom Resources, Operators, Service Mesh avanzado). Para esos casos,
> GKE sigue siendo la elección correcta aunque Cloud Run sea más simple
> de operar.

---

# Parte IV — Caso recurrente: Spring Boot

## 17. 🧭 Arquitectura de referencia

A lo largo de este curso se usa una aplicación backend Java/Spring Boot
como ejemplo recurrente:

```text
Internet
   │
Cloud DNS
   │
Cloud Load Balancing
   │
Cloud Run
   │
Spring Boot
   ├── Cloud SQL / AlloyDB
   ├── Firestore
   ├── Cloud Storage
   ├── Pub/Sub
   └── Secret Manager
```

Este diagrama sirve como referencia mental: cada documento posterior de
este curso explica cómo uno o más de estos servicios se conecta con la
aplicación Spring Boot desplegada en Cloud Run.

Cuándo esta app necesitaría GKE en lugar de Cloud Run: si necesita
sidecars complejos (ej. un proxy de service mesh con configuración
avanzada), DaemonSets, acceso a hardware específico por nodo, o control
de red que Cloud Run no expone. Fuera de esos casos, Cloud Run cubre el
95 % de un backend Spring Boot típico con menos superficie operativa.

---

## 🧠 Preguntas rápidas

1. ¿Cloud Run reemplaza a GKE en todos los casos?
2. ¿Qué diferencia a un Persistent Disk zonal de uno regional?
3. ¿Cuándo preferirías scale out sobre scale up?
4. ¿Qué diferencia a la External HTTP(S) Load Balancing de la Internal HTTP(S) Load Balancing?
5. ¿HTTP(S) Load Balancing y Network Load Balancing operan en la misma capa OSI?
6. ¿Cómo conecta un backend service de Cloud Load Balancing con Cloud Run?
7. ¿Cloud Run escala a cero por defecto?
8. ¿Qué permite la concurrency por instancia de Cloud Run?
9. ¿Para qué sirve dividir tráfico entre revisiones de Cloud Run?
10. ¿Qué diferencia a GKE Autopilot de GKE Standard?
11. ¿Cloud Functions 2nd gen está construido sobre qué servicio?
12. ¿Artifact Registry es lo mismo que Docker Hub?
13. ¿Qué le falta a Cloud Run frente a GKE cuando se necesitan DaemonSets o sidecars complejos?
14. ¿Qué hace Cloud Build en el flujo de CI de una imagen de contenedor?

---

## 📚 Referencias oficiales

- Compute Engine documentation: https://cloud.google.com/compute/docs
- Images: https://cloud.google.com/compute/docs/images
- Machine families: https://cloud.google.com/compute/docs/machine-resource
- Persistent Disk: https://cloud.google.com/compute/docs/disks
- Managed Instance Groups: https://cloud.google.com/compute/docs/instance-groups
- Autoscaling groups: https://cloud.google.com/compute/docs/autoscaler
- Cloud Load Balancing overview: https://cloud.google.com/load-balancing/docs/load-balancing-overview
- External HTTP(S) Load Balancing: https://cloud.google.com/load-balancing/docs/https
- Internal HTTP(S) Load Balancing: https://cloud.google.com/load-balancing/docs/l7-internal
- Network Load Balancing: https://cloud.google.com/load-balancing/docs/network
- Network Endpoint Groups: https://cloud.google.com/load-balancing/docs/negs
- Artifact Registry documentation: https://cloud.google.com/artifact-registry/docs
- Cloud Run documentation: https://cloud.google.com/run/docs
- Cloud Run services vs jobs: https://cloud.google.com/run/docs/overview/what-is-cloud-run
- GKE documentation: https://cloud.google.com/kubernetes-engine/docs
- GKE Autopilot overview: https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview
- Cloud Functions documentation: https://cloud.google.com/functions/docs
- Cloud Build documentation: https://cloud.google.com/build/docs
