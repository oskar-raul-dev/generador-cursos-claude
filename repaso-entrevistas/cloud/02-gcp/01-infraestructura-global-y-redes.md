# 01 — Infraestructura global y redes

> **Objetivo:** fijar el vocabulario de red de GCP y las tres propiedades que más se preguntan
> en entrevista: qué es global, qué es regional y qué es zonal.
> **Se asume leído:** nada. Es el primer documento del curso.
> **Se toca sobre todo con:** [`06` — DNS, CDN y conectividad](06-cloud-dns-conectividad.md) y
> [`05` — IAM y jerarquía de recursos](05-seguridad-iam-jerarquia-kms-secretos.md).
> **Dónde se practica:** [`L04` — red, firewall y diagnóstico](l04-red-vpc-firewall-y-diagnostico.md),
> que monta esta VPC con Terraform y la diagnostica sin enviar un paquete.
> **Vigencia:** 6 de septiembre de 2026.

**Salto rápido:** [Jerarquía mental](#1--jerarquía-mental) · [Region](#2--region) · [Zone](#3--zone) ·
[Zonal, regional, global](#4--recursos-zonales-regionales-y-globales) · [VPC](#7--vpc--virtual-private-cloud) · [Subnet](#9--subnet) ·
[Cloud NAT](#12--cloud-nat) · [Firewall rules](#14--firewall-rules) · [Private Google Access](#16--private-google-access) ·
[VPC Peering](#18--vpc-peering) · [Shared VPC](#19--shared-vpc) · [Private Service Connect](#21--private-service-connect) ·
[Comparaciones clave](#24--comparaciones-clave) · [Troubleshooting](#25--troubleshooting-básico-de-conectividad) · [Preguntas rápidas](#-preguntas-rápidas)

## 1. 🧭 Jerarquía mental

```text
GCP
└── Organization
    └── Project
        └── VPC (alcance global)
            ├── Region A
            │   └── Subnet (regional, multi-zona)
            │       ├── Zone A
            │       └── Zone B
            └── Region B
                └── Subnet (regional, multi-zona)
```

Regla de entrevista:

```text
VPC    = global
Subnet = regional (abarca todas las zonas de su región)
```

Casi todo lo que despliegas — VMs, discos, clusters, buckets, bases de datos —
vive dentro de un **Project**. El Project es también la unidad de
facturación, cuotas y APIs habilitadas: antes de usar cualquier servicio
GCP hay que habilitar su API a nivel de Project.

---

## 2. 🧱 Region

Una **Region** es un área geográfica independiente (ej. `us-central1`,
`europe-west1`, `southamerica-east1`) donde Google opera infraestructura.

### Selección de Region

Considera:

- cercanía a usuarios y latencia;
- disponibilidad del servicio o feature requerido (no todos los servicios
  ni todas las features están en todas las regiones);
- requisitos regulatorios/residencia de datos;
- costo;
- estrategia de disaster recovery.

---

## 3. 🧱 Zone

Una **Zone** es un dominio de aislamiento de fallos dentro de una Region
(ej. `us-central1-a`, `us-central1-b`, `us-central1-c`). Cada Region tiene
varias Zones.

```text
Zone = failure isolation boundary
```

Un diseño de alta disponibilidad distribuye workloads entre varias Zones
de una misma Region:

```text
             Cloud Load Balancing
            /                    \
       Zone A                   Zone B
        │                          │
   Managed Instance Group    Managed Instance Group
        \                          /
         \                        /
          Cloud SQL (HA regional)
```

---

## 4. 🧱 Recursos zonales, regionales y globales

Cada recurso de GCP tiene un alcance fijo. Reconocer el alcance de un
recurso es una de las preguntas más frecuentes de entrevista:

| Alcance | Ejemplos |
|---|---|
| Zonal | Compute Engine instance, Persistent Disk (zonal), Managed Instance Group zonal |
| Regional | Subnet, Cloud SQL instance, Managed Instance Group regional, Cloud Run service, Persistent Disk regional |
| Global | VPC, Image, Snapshot, Organization Policy, Cloud Load Balancing (HTTP(S)) |

> No asumas que "administrado por Google" implica automáticamente
> "global". Cloud SQL es un servicio completamente administrado y, aun
> así, una instancia de Cloud SQL es un recurso regional.

---

## 5. 🧱 Red global privada de Google

Google opera su propia red de fibra privada entre datacenters y puntos de
presencia (edge) en todo el mundo. Es un diferenciador estructural de GCP:
buena parte del tráfico entre regiones, y del tráfico hacia los edge
points de Google, puede viajar por esta red privada en lugar de por
Internet público.

```text
Cliente ──► Edge de Google (POP más cercano) ──► Red privada de Google ──► Region destino
```

Esto reduce hops, congestión y variabilidad de latencia comparado con
depender exclusivamente de tránsito por Internet público entre el
cliente y el datacenter.

---

## 6. ⚖ Premium Tier vs Standard Tier

El **Network Service Tier** decide qué camino toma el tráfico de salida
hacia/desde recursos con IP externa.

| Tier | Camino | Latencia/consistencia | Costo |
|---|---|---|---|
| Premium Tier | Entra/sale por la red privada de Google lo antes posible | Menor variabilidad, mejor rendimiento | Mayor |
| Standard Tier | Se comporta como tránsito de Internet público típico | Rendimiento comparable a un ISP normal | Menor |

Regla mental:

```text
Premium Tier  → rutas por la red privada de Google
Standard Tier → rutas por Internet público
```

Premium Tier es el default para la mayoría de recursos nuevos. Standard
Tier existe como opción de menor costo para tráfico donde la variabilidad
de latencia es aceptable.

---

# Parte II — Networking

## 7. 🧱 VPC — Virtual Private Cloud

Una **VPC** en GCP es una red virtual de **alcance global**. Esto es lo
primero que rompe la intuición de quien viene de un modelo de red
regional: la misma VPC puede tener subnets en `us-central1`,
`europe-west1` y `asia-east1` simultáneamente, sin peering ni gateway
adicional entre esas subnets.

```text
VPC: app-vpc (global)
├── Subnet us-central1   10.0.0.0/20
├── Subnet europe-west1  10.0.16.0/20
└── Subnet asia-east1    10.0.32.0/20
```

Recursos en subnets distintas de la misma VPC se comunican por defecto
usando IP privada, incluso entre regiones distintas, sujeto a firewall
rules.

### Auto-mode vs Custom-mode

| | Auto-mode VPC | Custom-mode VPC |
|---|---|---|
| Subnets | Se crea una subnet automáticamente por región, con rangos predefinidos | Tú decides qué regiones tienen subnet y qué rangos CIDR usar |
| Uso típico | Pruebas rápidas, demos | Producción |
| Control de direccionamiento | Bajo | Alto |

> En producción se usa casi siempre custom-mode: auto-mode asigna rangos
> predefinidos en todas las regiones, lo cual complica evitar
> solapamientos cuando más adelante necesitas VPC Peering o Shared VPC.

---

## 8. 🧱 CIDR, IPv4 e IPv6

Las subnets se definen con rangos CIDR:

```text
10.0.0.0/20
```

| CIDR | Direcciones matemáticas |
|---:|---:|
| `/16` | 65.536 |
| `/20` | 4.096 |
| `/24` | 256 |
| `/28` | 16 |
| `/32` | 1 |

Evita rangos superpuestos entre VPCs si más adelante planeas conectarlas
mediante VPC Peering, Shared VPC o Network Connectivity Center — ninguno
de esos mecanismos resuelve solapamiento de CIDR por ti.

GCP soporta subnets **dual-stack** (IPv4 + IPv6) y también subnets
IPv6-only para ciertos casos de uso. Para la mayoría de arquitecturas
backend típicas, IPv4 sigue siendo el modelo dominante; IPv6 se vuelve
relevante en cargas con requisitos específicos de direccionamiento o
exposición pública a gran escala.

---

## 9. 🧱 Subnet

Una **subnet** es un recurso **regional**: abarca todas las Zones de su
región, no una sola.

```text
VPC (global)
└── Subnet us-central1  10.0.0.0/20   ← regional
    ├── Zone us-central1-a
    ├── Zone us-central1-b
    └── Zone us-central1-c
```

Una VM en `us-central1-a` y otra en `us-central1-b` pueden compartir la
misma subnet si esa subnet corresponde a `us-central1`.

### Rangos de IP secundarios (alias IP ranges)

Una subnet puede tener, además de su rango primario, uno o más rangos
secundarios. Se usan típicamente para:

- asignar rangos de Pods y de Services en GKE sin depender de rangos
  primarios adicionales por subnet;
- dar a una VM múltiples direcciones IP internas (alias IP) sin necesitar
  una interfaz de red distinta.

```text
Subnet 10.0.0.0/20
├── rango primario     10.0.0.0/20   → VMs
└── rango secundario   10.4.0.0/14   → Pods de GKE
```

---

## 10. 🧱 Route tables implícitas y rutas custom

Cada VPC tiene rutas implícitas del sistema para tráfico dentro de sus
propios rangos de subnet (`local`), más las rutas que agregues.

```text
Destino          → Next hop
10.0.0.0/20      → local (subnet us-central1)
10.0.16.0/20     → local (subnet europe-west1)
0.0.0.0/0        → default internet gateway (si aplica)
```

GCP selecciona rutas por **longest prefix match**: entre rutas que
coinciden con el destino, gana la más específica (el prefijo más largo).

Las rutas pueden apuntar a distintos next hops: default internet gateway,
una instancia, un Cloud Router, un túnel VPN, o un Network Connectivity
Center hub, entre otros.

---

## 11. 🧱 Cloud Router

**Cloud Router** es el componente que habilita **routing dinámico**
mediante BGP entre tu VPC y redes externas (on-premises vía VPN/
Interconnect, u otras VPC vía Network Connectivity Center).

```text
VPC ── Cloud Router ── BGP ── on-premises router
```

También es un prerequisito de **Cloud NAT**: Cloud NAT se configura sobre
una región y se asocia a un Cloud Router de esa región, aunque el NAT en
sí no depende de sesiones BGP.

---

## 12. 🧱 Cloud NAT

Problema:

```text
VM sin IP externa → necesita descargar paquetes o llamar una API externa
```

Solución:

```text
VM sin IP externa (privada)
        │
        ▼
   Cloud NAT
        │
        ▼
     Internet
```

Cloud NAT permite que recursos sin IP externa **inicien** conexiones
salientes hacia Internet, sin exponer un endpoint alcanzable desde
afuera. Es un servicio administrado y distribuido — no es una instancia
NAT que administres tú.

> No asumas que una VM sin IP externa no tiene salida a Internet. Sin
> Cloud NAT (u otra ruta de salida configurada), efectivamente no la
> tiene; con Cloud NAT configurado, sí puede salir, solo que no puede
> recibir conexiones entrantes iniciadas desde Internet.

> 💰 **Costo.** Cloud NAT **cobra por hora de gateway y por GiB procesado**: existe, luego factura.
> Antes de montar uno, pregúntate si el destino es Internet de verdad o son las APIs de Google —
> para lo segundo está Private Google Access (§16), que no tiene cargo adicional. La serie práctica
> evita Cloud NAT por esa razón y practica la alternativa en
> [`L04` §7](l04-red-vpc-firewall-y-diagnostico.md#7--private-google-access-en-lugar-de-cloud-nat).

---

## 13. ⚖ IP externa efímera vs estática (reservada)

| | Efímera | Estática (reservada) |
|---|---|---|
| Ciclo de vida | Ligada al recurso mientras existe | Independiente del recurso, hasta liberarla explícitamente |
| Costo si está sin usar | No aplica (se libera con el recurso) | Se cobra mientras esté reservada y sin asignar |
| Uso típico | VMs efímeras, pruebas | Endpoints estables, DNS, whitelisting de IP en terceros |

> 💰 **Costo.** La asimetría que sorprende a todo el mundo: **una IP externa reservada y no
> adjunta se cobra a una tarifa mayor que una en uso**, porque es un recurso escaso retenido sin
> motivo. Es el estado en que quedan después de un experimento a medias, y la trampa número dos del
> catálogo de [`A02`](a02-costos-trampas-y-recursos-huerfanos.md#3--el-catálogo-de-lo-que-cobra-por-existir).

---

## 14. 🧱 Firewall rules

Las **firewall rules** de VPC controlan tráfico a nivel de red.

```text
Firewall rule
→ opera a nivel de VPC (se define sobre la VPC, se aplica según tags/service accounts)
→ stateful
→ admite ALLOW y DENY
→ tiene prioridad numérica (0-65535; menor número = mayor prioridad)
→ tiene dirección (ingress/egress)
```

A diferencia de modelos de firewall que solo permiten reglas ALLOW, las
firewall rules de VPC admiten explícitamente reglas **DENY**, evaluadas
junto con las ALLOW según prioridad numérica.

Ejemplo:

```text
Priority 1000  DENY   ingress  from 0.0.0.0/0  tcp:22
Priority 2000  ALLOW  ingress  from 35.235.240.0/20  tcp:22   (IAP range)
Priority 65534 ALLOW  ingress  from 10.0.0.0/8  all protocols (default implícita)
```

### Stateful

Si una conexión permitida entra, el tráfico de respuesta de esa conexión
se permite automáticamente sin necesitar una regla explícita para el
sentido contrario.

### Reglas implícitas por defecto

Toda VPC tiene, antes de cualquier regla que definas:

```text
Implicit DENY  ingress  from 0.0.0.0/0  all protocols  (prioridad más baja)
Implicit ALLOW egress   to   0.0.0.0/0  all protocols  (prioridad más baja)
```

Es decir: por defecto todo el ingress está denegado y todo el egress está
permitido, hasta que agregues reglas explícitas.

---

## 15. 🧱 Hierarchical firewall policies

Además de las firewall rules a nivel VPC, existen **hierarchical firewall
policies**, que se asocian a nivel **Organization** o **Folder** y
heredan hacia todos los proyectos y VPCs debajo en la jerarquía.

```text
Organization
└── Hierarchical firewall policy
    └── Folder "Production"
        └── Project "backend-prod"
            └── VPC firewall rules (nivel Project)
```

Se usan para guardrails centrales (ej. "nunca permitir SSH desde
`0.0.0.0/0` en ningún proyecto de Production") que un equipo de proyecto
individual no puede sobrescribir libremente.

Regla mental:

```text
Firewall rule               → nivel VPC, la administra el equipo del proyecto
Hierarchical firewall policy → nivel Organization/Folder, guardrail central
```

---

## 16. 🧱 Private Google Access

Permite que VMs **sin IP externa** alcancen las APIs y servicios públicos
de Google (Cloud Storage, BigQuery, Pub/Sub, etc.) usando rutas internas,
sin salir por Internet ni necesitar Cloud NAT para ese tráfico específico.

```text
VM sin IP externa
      │  (Private Google Access habilitado en la subnet)
      ▼
  APIs de Google (storage.googleapis.com, etc.)
```

Se habilita a nivel de subnet.

---

## 17. 🧱 Serverless VPC Access connector

Cloud Run y Cloud Functions son servicios serverless que, por defecto, no
tienen una interfaz de red dentro de tu VPC. El **Serverless VPC Access
connector** es el puente necesario para que esas cargas alcancen recursos
que solo existen dentro de la VPC (una VM, una IP privada de Cloud SQL vía
private IP, un recurso on-premises vía VPN/Interconnect).

```text
Cloud Run
    │
    ▼
Serverless VPC Access connector
    │
    ▼
   VPC (recursos con IP privada)
```

> No confundas esto con conectividad hacia servicios que ya son
> alcanzables por API pública (como Cloud Storage): para eso no necesitas
> el connector.

> 💰 **Costo.** Un connector de Serverless VPC Access **factura por instancia y por hora mientras
> exista**, aunque no pase tráfico. Por eso solo se monta cuando el destino tiene **IP privada dentro
> de tu red**; para hablar con APIs de Google desde Cloud Run no hace falta ninguno. La serie
> práctica no lo usa, y explica por qué en
> [`L04` §10](l04-red-vpc-firewall-y-diagnostico.md#10--lo-que-el-lab-no-monta-y-por-qué).

---

## 18. 🧱 VPC Peering

Conecta dos VPC (de cualquier proyecto) mediante direccionamiento
privado.

```text
VPC-A ←→ VPC-B
```

Reglas importantes:

- puede ser entre proyectos distintos e incluso entre distintas
  organizaciones;
- requiere que ambos lados configuren el peering;
- no admite CIDR superpuestos;
- **no es transitivo**.

```text
B ←→ A ←→ C
```

no implica

```text
B ←→ C
```

---

## 19. 🧱 Shared VPC

**Shared VPC** es un concepto propio de GCP sin equivalente directo en
otros proveedores de nube, y aparece con frecuencia en entrevistas de
arquitectura sobre organizaciones con múltiples equipos.

Un proyecto **host** posee la VPC; uno o más proyectos **service**
conectan recursos (VMs, GKE, etc.) a las subnets de esa VPC del host,
sin tener ellos mismos su propia VPC.

```text
Host Project
└── VPC compartida
    ├── Subnet us-central1
    └── Subnet europe-west1

Service Project A ──► usa subnets del Host Project
Service Project B ──► usa subnets del Host Project
```

Con esto, un equipo de networking centraliza el diseño de red (rangos,
firewall, conectividad híbrida) mientras cada equipo de producto
administra sus propios recursos de cómputo dentro de esa red compartida,
con IAM independiente por proyecto de servicio.

Regla mental:

```text
VPC Peering → conexión punto a punto entre VPCs distintas, cada una con su propia identidad
Shared VPC  → varios proyectos comparten la misma VPC de un proyecto host
```

---

## 20. 🧱 Network Connectivity Center

**Network Connectivity Center (NCC)** es un hub administrado para
conectar múltiples VPCs y redes on-premises a escala, evitando construir
un mesh manual de VPC Peering entre docenas de VPCs.

```text
        VPC-A
          │
VPC-B ─── NCC hub ─── VPC-C
          │
       on-premises (vía VPN/Interconnect)
```

Regla mental:

```text
VPC Peering → conexión directa uno a uno
NCC         → hub-and-spoke a escala
```

---

## 21. 🧱 Private Service Connect

**Private Service Connect (PSC)** permite consumir un servicio (propio,
de un tercero, o administrado por Google) de forma privada, mediante una
IP interna en tu VPC, sin exponer el tráfico a Internet ni depender de
VPC Peering entre consumidor y productor.

```text
VPC consumidor
    │
    ▼
PSC endpoint (IP interna)
    │
    ▼
Servicio productor (otra VPC, otro proyecto, o servicio de Google)
```

Es el mecanismo recomendado cuando un equipo productor de servicio no
quiere hacer peering directo con cada consumidor (lo cual expondría toda
su VPC), sino publicar un endpoint privado puntual.

---

## 22. 🧱 Cloud VPN

**Cloud VPN** conecta tu VPC con una red externa (on-premises, otra nube)
mediante túneles IPsec sobre Internet.

```text
VPC ── túnel IPsec ── router on-premises
```

La modalidad **HA VPN** ofrece un SLA de disponibilidad alto mediante
múltiples túneles activos y Cloud Router con BGP.

---

## 23. 🧱 Cloud Interconnect

**Cloud Interconnect** ofrece conectividad privada dedicada entre tu red
on-premises y la red de Google, sin atravesar Internet público.

| Modalidad | Descripción |
|---|---|
| Dedicated Interconnect | Conexión física dedicada directamente a la red de Google, en un punto de colocación compartido |
| Partner Interconnect | Conectividad a través de un proveedor de servicio partner, útil cuando no se justifica una conexión dedicada |

Regla mental:

```text
Cloud VPN         → túneles cifrados sobre Internet, rápido de aprovisionar
Cloud Interconnect → conectividad dedicada privada, mayor throughput/consistencia, más lento de aprovisionar
```

---

## 24. ⚖ Comparaciones clave

```text
VPC global vs Subnet regional
Auto-mode VPC vs Custom-mode VPC
Firewall rule vs Hierarchical firewall policy
VPC Peering vs Shared VPC vs Network Connectivity Center
Cloud VPN vs Cloud Interconnect
Private Google Access vs Private Service Connect
IPv4 vs IPv6
```

| Necesidad | Private Google Access | Serverless VPC Access | Private Service Connect |
|---|---|---|---|
| VM sin IP externa → APIs públicas de Google | ✅ | — | — |
| Cloud Run/Functions → recurso dentro de tu VPC | — | ✅ | — |
| Consumir un servicio privado de otro proyecto/VPC | — | — | ✅ |

---

## 25. 🩺 Troubleshooting básico de conectividad

```text
1. ¿DNS resuelve?
2. ¿La IP es correcta?
3. ¿Existe una ruta?
4. ¿El firewall rule (o hierarchical policy) permite el tráfico?
5. ¿La instancia/servicio necesita Cloud NAT o Private Google Access para salir?
6. ¿El servicio escucha realmente en el puerto?
7. ¿Connectivity Tests confirma el diagnóstico?
```

**Connectivity Tests**, dentro de Network Intelligence Center, analiza
estáticamente la configuración de red (rutas, firewall, peering) para
determinar si existe un path válido entre origen y destino, y en qué
punto se bloquearía, sin necesidad de enviar tráfico real.

**VPC Flow Logs** registra metadata del tráfico IP real entre interfaces
(origen, destino, puertos, protocolo, acción) — útil para confirmar qué
tráfico efectivamente ocurrió, a diferencia de Connectivity Tests, que es
análisis estático.

---

## 🧠 Preguntas rápidas

1. ¿Una VPC es un recurso global o regional?
2. ¿Una subnet puede abarcar dos regiones?
3. ¿Qué diferencia a una Zone de una Region?
4. ¿Un Persistent Disk zonal puede adjuntarse a una VM de otra zona?
5. ¿Qué camino toma el tráfico bajo Premium Tier frente a Standard Tier?
6. ¿Auto-mode VPC es recomendable para producción?
7. ¿Qué significa "longest prefix match"?
8. ¿Una VM sin IP externa tiene salida a Internet por definición?
9. ¿Las firewall rules de VPC admiten reglas DENY?
10. ¿Qué diferencia una firewall rule de una hierarchical firewall policy?
11. ¿Para qué sirve el Serverless VPC Access connector?
12. ¿VPC Peering es transitivo?
13. ¿Qué problema resuelve Shared VPC que VPC Peering no resuelve igual de bien?
14. ¿Cuándo usarías Network Connectivity Center en lugar de peering directo?
15. ¿Qué diferencia a Private Google Access de Private Service Connect?

---

## 📚 Referencias oficiales

- Regions and zones: https://cloud.google.com/compute/docs/regions-zones
- Google's network infrastructure: https://cloud.google.com/docs/geography-and-regions
- Network Service Tiers: https://cloud.google.com/network-tiers/docs/overview
- Virtual Private Cloud (VPC) overview: https://cloud.google.com/vpc/docs/vpc
- Subnets: https://cloud.google.com/vpc/docs/subnets
- Alias IP ranges: https://cloud.google.com/vpc/docs/alias-ip
- Routes: https://cloud.google.com/vpc/docs/routes
- Cloud Router: https://cloud.google.com/network-connectivity/docs/router
- Cloud NAT: https://cloud.google.com/nat/docs/overview
- Firewall rules overview: https://cloud.google.com/firewall/docs/firewalls
- Hierarchical firewall policies: https://cloud.google.com/firewall/docs/firewall-policies
- Private Google Access: https://cloud.google.com/vpc/docs/private-google-access
- Serverless VPC Access: https://cloud.google.com/vpc/docs/serverless-vpc-access
- VPC Peering: https://cloud.google.com/vpc/docs/vpc-peering
- Shared VPC overview: https://cloud.google.com/vpc/docs/shared-vpc
- Network Connectivity Center overview: https://cloud.google.com/network-connectivity/docs/network-connectivity-center/concepts/overview
- Private Service Connect overview: https://cloud.google.com/vpc/docs/private-service-connect
- Cloud VPN overview: https://cloud.google.com/network-connectivity/docs/vpn/concepts/overview
- Cloud Interconnect overview: https://cloud.google.com/network-connectivity/docs/interconnect/concepts/overview
- Connectivity Tests: https://cloud.google.com/network-intelligence-center/docs/connectivity-tests/concepts/overview
- VPC Flow Logs: https://cloud.google.com/vpc/docs/flow-logs
