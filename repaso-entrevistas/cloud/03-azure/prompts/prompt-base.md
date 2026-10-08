# Prompt: tutorial rápido de Azure para refresco técnico y entrevistas

Genera un tutorial de repaso rápido de Microsoft Azure orientado a refrescar
conocimientos técnicos y preparar entrevistas para perfiles **Backend Senior /
Software Architect** (Java, Spring Boot).

El objetivo no es crear un curso exhaustivo de certificación, sino una
colección de **notas técnicas densas, prácticas, modulares y fáciles de
consultar** — sin relleno, pero **sin techo de longitud**. Análoga en
espíritu, tono y estructura a `01-aws/` y `02-gcp/`, pero **autocontenida**:
no asumas que el lector conoce AWS ni GCP, no introduzcas tablas de mapeo
desde otra nube ni frases de comparación con otro proveedor. Cada concepto
de Azure se explica desde cero.

**El tono, formato y convenciones editoriales exactas están definidos en
`prompts/guia-de-estilo-y-convenciones.md`.** Este documento define el
**contenido y alcance técnico** de cada capítulo; esa guía define **cómo se
escribe**. Los dos se usan juntos.

> 📝 **Estado: cerrado el 27 de septiembre de 2026.** Inventario de
> diecisiete capítulos, Bicep como IaC, evaluación sin ejercicios graduados y
> Java como lenguaje del SDK.
> Las fichas de §2 son el contrato de cada capítulo: lo que listan se cubre, y
> lo que un capítulo cubra fuera de su ficha se justifica o se mueve.

---

## 1. Formato de entrega

Estructura el contenido en **varios archivos Markdown (`.md`)**, ordenados
desde los conceptos más fundamentales hasta los temas de arquitectura y
entrevista, más un `README.md` que funcione como índice general, mapa de
estudio, resumen de servicios, tabla de "dónde se practica cada capítulo" y
orden recomendado de lectura.

```text
README.md
01-infraestructura-global-y-resource-manager.md
02-redes-vnet-nsg-y-enrutamiento.md
03-conectividad-privada-y-dns.md
04-computo-y-contenedores.md
05-balanceo-entrega-global-y-api-management.md
06-almacenamiento-storage-accounts.md
07-bases-relacionales-y-cache.md
08-cosmos-db.md
09-identidad-entra-id-y-managed-identities.md
10-autorizacion-rbac-policy-y-gobierno.md
11-secretos-cifrado-y-key-vault.md
12-identidad-de-aplicaciones-oauth-con-entra-id.md
13-mensajeria-y-eventos.md
14-observabilidad-monitor-log-analytics-app-insights.md
15-bicep-iac.md
16-orquestacion-y-cicd.md
17-resiliencia-y-well-architected.md
18-preguntas-entrevista-y-mapa-mental.md
19-respuestas.md
```

A esos archivos se suma la **serie práctica**, cuyo alcance **no se define
aquí** sino en `l00-idea-lab-practico.md`. Su inventario con nombres de
archivo vive en `README.md`.

**Reparto de responsabilidades entre los documentos rectores**:

| Documento | Define |
|---|---|
| Este `prompt-base.md` | El **contenido y alcance técnico** de los capítulos teóricos |
| `guia-de-estilo-y-convenciones.md` | **Cómo se escribe** todo el curso, teoría y práctica |
| `l00-idea-lab-practico.md` | El **alcance de la serie práctica**: qué entra al laboratorio de pago y qué no |

Cada capítulo teórico declara en su blockquote de encabezado con qué dos
documentos se toca más y **en qué lab se practica** lo que explica —o por
qué no tiene lab—. La columna "Se practica en" de cada ficha es la fuente de
esa línea; si `l00` la cambia, se corrige aquí en la misma edición.

---

## 2. Fichas de alcance por capítulo

Formato de cada ficha: **Cubrir** (lo que el capítulo explica), **Comparar**
(las distinciones que tienen que quedar claras, en bloque `text`),
**Desmontar** (las sobregeneralizaciones de entrevista que el capítulo nombra
y corrige), **Diagnóstico** cuando aplica, y **Se practica en**. Todo lo que
dependa de una fecha o de un estado de retiro va marcado *(verificar)* y se
comprueba contra Azure Updates al escribir el capítulo (§11).

### 01 — Infraestructura global y Resource Manager

**Cubrir:**

- geografías, regions, region pairs y regiones sin pareja *(verificar la
  lista vigente)*; qué hace Microsoft con la pareja (actualizaciones
  escalonadas, prioridad de recuperación) y qué **no** hace (no replica tus
  datos por ti salvo que el servicio lo ofrezca);
- Availability Zones: zonas físicas frente a **zonas lógicas por
  suscripción** (la zona 1 de tu suscripción no es necesariamente la zona 1
  de otra);
- servicios zonales, zone-redundant y no regionales (globales), con un
  ejemplo real de cada uno;
- la jerarquía completa:

```text
Tenant de Microsoft Entra ID
└── Root management group
    └── Management groups (anidables)
        └── Subscription           ← frontera de facturación, cuotas y RBAC
            └── Resource group     ← frontera de ciclo de vida
                └── Resource       ← identificado por su resource ID
```

- la suscripción como frontera de facturación, de cuotas y de RBAC; tipos
  de oferta a nivel conceptual;
- el resource group: región propia solo para metadatos, recursos en otras
  regiones, borrado en cascada, mover recursos entre grupos y sus límites;
- Azure Resource Manager: un único endpoint (`management.azure.com`), el
  formato del resource ID, resource providers y su registro, versiones de
  API por tipo de recurso, throttling de ARM;
- **control plane frente a data plane**: qué pasa por ARM y qué habla
  directamente con el servicio (el concepto que sostiene `09`, `10` y `11`);
- tags: no se heredan por defecto y cómo se consigue la herencia con Azure
  Policy (remite a `10`);
- cuotas y límites: por región y por familia de VM, cómo se piden aumentos.

**Comparar:**

```text
Region vs Availability Zone vs Region pair
Zonal vs zone-redundant vs no regional
Management group vs Subscription vs Resource group
Control plane vs data plane
Resource provider registrado vs no registrado
```

**Desmontar:** "el resource group es una carpeta"; "si mi recurso está en
una región con pareja, Azure lo replica solo"; "la zona 1 es la misma
para todos".

**Se practica en:** `L01` (suscripción, providers, resource group, tags) y
`L03` (scopes de despliegue).

### 02 — Redes: VNet, NSG y enrutamiento

**Cubrir:**

- VNet como recurso **regional**; address space, subnets, las cinco IPs que
  Azure reserva en cada subnet, delegación de subnets;
- NSG: reglas con prioridad, reglas por defecto, service tags,
  Application Security Groups, asociación a subnet y a NIC y el orden de
  evaluación cuando están las dos; effective security rules;
- rutas del sistema, User Defined Routes, route tables, tipos de next hop,
  propagación de rutas BGP;
- IP públicas: SKU Standard y el retiro de la SKU Basic *(verificar
  fecha)*; IP estática frente a dinámica;
- salida a Internet: NAT Gateway, outbound rules de Load Balancer, IP
  pública en la NIC, y **el retiro del acceso de salida por defecto**
  *(verificar fecha y alcance: VNets nuevas frente a existentes)*;
- VNet peering: no transitivo, peering global, gateway transit;
- topología hub-and-spoke; Virtual WAN a nivel conceptual;
- Azure Firewall (tiers a nivel conceptual), DDoS Protection y Azure
  Bastion como piezas del hub, sin profundizar;
- VNet flow logs y el retiro de los NSG flow logs *(verificar)*;
- IPv6 dual stack, una mención.

**Comparar:**

```text
NSG vs ASG vs Azure Firewall
System route vs UDR
NAT Gateway vs outbound rule de Load Balancer vs IP pública en la VM
VNet peering vs VPN Gateway vs Virtual WAN
NSG en subnet vs NSG en NIC
```

**Desmontar:** "la VNet es global"; "el peering es transitivo"; "una VM sin
IP pública no sale a Internet" (depende de la fecha de la VNet y de la
subnet); "un NSG es un firewall".

**Diagnóstico** (secuencia que se reutiliza en `03`):

```text
1. ¿El nombre resuelve a la IP que esperas?        (lo desarrolla 03)
2. ¿Hay ruta? effective routes / next hop
3. ¿El NSG deja pasar? effective security rules / IP flow verify
4. ¿Hay salida si hace falta? NAT Gateway o equivalente
5. ¿El servicio escucha en el puerto?
6. ¿Connection troubleshoot confirma el diagnóstico?
```

**Se practica en:** `L04`.

### 03 — Conectividad privada y DNS

**Cubrir:**

- Service Endpoints: salida por la IP pública del servicio, identidad de
  la subnet, firewall del servicio;
- Private Endpoints y Private Link: una NIC con IP privada de tu subnet,
  `publicNetworkAccess` deshabilitado, Private Link Service para exponer
  lo propio;
- **la resolución DNS de un private endpoint**, paso a paso: el CNAME a
  `privatelink.*`, la Private DNS zone, el VNet link, el resolver de Azure
  (`168.63.129.16`), y qué ve un cliente dentro y fuera de la VNet;
- Private DNS zones: VNet links, auto-registration, zonas por servicio;
- DNS Private Resolver: inbound y outbound endpoints, forwarding
  rulesets, resolución híbrida con on-premises;
- Azure DNS público: zonas, record sets, alias records, delegación desde
  el registrador;
- VPN Gateway (site-to-site, point-to-site, active-active) y ExpressRoute
  (private peering, Microsoft peering, Global Reach) a nivel conceptual.

**Comparar:**

```text
Service Endpoint vs Private Endpoint
Private Endpoint vs Private Link Service
Azure DNS público vs Private DNS zone vs DNS Private Resolver
VPN Gateway vs ExpressRoute
```

**Desmontar:** "un private endpoint funciona solo con crearlo"; "Service
Endpoint y Private Endpoint son lo mismo con otro nombre"; "si
`publicNetworkAccess` está deshabilitado, el FQDN deja de resolver".

**Diagnóstico:** el `nslookup` esperado desde dentro de la VNet, desde
fuera, y con la Private DNS zone sin vincular, con la salida literal de cada
caso.

**Se practica en:** `L04`.

### 04 — Cómputo y contenedores

**Cubrir:**

- Virtual Machines: familias y tamaños, availability sets frente a zonas,
  Spot, relación con managed disks (remite a `06`);
- VM Scale Sets: orquestación Flexible frente a Uniform, autoscale;
- App Service: el plan como cómputo compartido, tiers, stacks de Java
  (Java SE, Tomcat, JBoss EAP), deployment slots y swap, Always On, VNet
  integration;
- **Container Apps como eje**: environments, apps y jobs, revisiones,
  ingress, escalado con reglas KEDA, escala a cero, plan Consumption frente
  a workload profiles, Dapr en una mención;
- AKS a nivel de decisión: tiers del control plane, node pools de sistema y
  de usuario, networking a nivel conceptual, workload identity (remite a
  `09`);
- Functions: planes de hosting (Flex Consumption, Premium, Dedicated) y el
  estado del plan Consumption clásico *(verificar)*; triggers y bindings;
- Container Registry: SKUs, ACR Tasks, geo-replicación, autenticación con
  managed identity (`AcrPull`);
- **dónde correr Spring Boot hoy**, incluido el estado de retiro de Azure
  Spring Apps *(verificar fechas y qué significa para clientes existentes y
  nuevos)*; cold start de la JVM en plataformas que escalan a cero.

**Comparar:**

```text
VM vs App Service vs Container Apps vs AKS vs Functions
Container Apps app vs Container Apps job
App Service deployment slot vs revisión de Container Apps
VMSS Flexible vs Uniform
Availability set vs Availability Zone
```

**Desmontar:** "Container Apps es AKS administrado y te da la API de
Kubernetes"; "Functions siempre escala a cero y sin cold start"; "Spring
Boot en Azure es Azure Spring Apps".

**Se practica en:** `L05` (Container Apps y Container Registry). VMs, App
Service y AKS quedan fuera del tronco y `l00` dice por qué.

### 05 — Balanceo, entrega global y API Management

**Cubrir:**

- Azure Load Balancer: L4, regional, SKU Standard, frontends
  zone-redundant, health probes, reglas de balanceo, outbound rules, público
  e interno; cross-region Load Balancer en una mención;
- Application Gateway v2: L7 regional, enrutamiento por host y path,
  terminación TLS, autoscale, WAF; Application Gateway for Containers en una
  mención;
- Front Door: L7 global sobre anycast, tiers Standard y Premium, WAF,
  caché, orígenes privados por Private Link; el retiro de Front Door
  classic y de Azure CDN de Microsoft (classic) *(verificar)*;
- Traffic Manager: balanceo por DNS y sus métodos de enrutamiento;
- el árbol de decisión entre los cuatro;
- API Management: tiers (incluidos Consumption y los v2 *(verificar)*),
  políticas (`rate-limit-by-key`, `validate-jwt`, reescritura), productos y
  subscription keys, backends, self-hosted gateway.

**Comparar** (matriz ancha admitida por la guía §3):

```text
Load Balancer vs Application Gateway vs Front Door vs Traffic Manager
L4 vs L7, regional vs global, proxy vs DNS
API Management vs Application Gateway
WAF en Application Gateway vs WAF en Front Door
```

**Desmontar:** "Traffic Manager balancea tráfico" (devuelve un nombre, no
toca los paquetes); "Front Door es un CDN"; "APIM es un load balancer".

**Se practica en:** ningún lab del tronco. El ingress de Container Apps
cubre lo que el sistema del lab necesita; `l00` §4 justifica la exclusión
con precios, y §9 ofrece drills de Application Gateway y de API Management
Consumption.

### 06 — Almacenamiento: storage accounts

**Cubrir:**

- la storage account como contenedor de cuatro servicios (Blob, Files,
  Queues, Tables); tipos de cuenta; reglas de nombre y unicidad global;
- blobs: block, append y page;
- redundancia: LRS, ZRS, GRS, RA-GRS, GZRS, RA-GZRS; failover administrado
  por el cliente y lo que se pierde;
- access tiers (hot, cool, cold, archive), rehidratación, cargos por borrado
  anticipado, lifecycle management;
- protección de datos: soft-delete de blobs y contenedores, versioning,
  point-in-time restore, **immutability policies** (WORM, relevante en
  banca);
- acceso: access keys y por qué se deshabilitan, los tres tipos de SAS
  (account, service, **user delegation**), Entra ID con roles de datos
  (remite a `10`), firewall y private endpoints (remite a `03`);
- Azure Files (SMB y NFS) a nivel de decisión;
- managed disks: tipos (Standard HDD/SSD, Premium SSD, Premium SSD v2,
  Ultra), discos LRS y ZRS, snapshots;
- Data Lake Storage (hierarchical namespace) en una mención.

**Comparar:**

```text
Blob Storage vs Azure Files vs Managed Disks
LRS vs ZRS vs GRS vs GZRS (y sus RA-)
Hot vs Cool vs Cold vs Archive
Account SAS vs Service SAS vs User delegation SAS
Access key vs SAS vs Entra ID
```

**Desmontar:** "GRS me da lectura en la región secundaria" (eso es RA-GRS);
"una SAS se revoca borrándola"; "soft-delete es un backup".

**Se practica en:** `L02` (roles de datos y `--allow-shared-key-access
false`) y `L03` (la cuenta declarada en Bicep).

### 07 — Bases relacionales y caché

**Cubrir:**

- la familia Azure SQL: SQL Database (single y elastic pools), SQL
  Managed Instance, SQL Server en VM, y cuándo cada uno;
- modelos de compra DTU frente a vCore; tiers General Purpose, Business
  Critical e Hyperscale; serverless con auto-pause;
- alta disponibilidad y zone redundancy; backups automáticos, PITR y
  retención de largo plazo;
- **active geo-replication frente a failover groups** (listeners de
  lectura-escritura y solo lectura); read scale-out;
- autenticación con Entra ID y managed identity (sin contraseña en la app);
  TDE;
- la oferta gratuita de Azure SQL Database *(verificar condiciones)*;
- Azure Database for PostgreSQL Flexible Server: HA con standby
  zone-redundant, read replicas, PgBouncer integrado, autenticación con
  Entra ID; MySQL Flexible Server en una mención;
- caché: Azure Managed Redis y el retiro de Azure Cache for Redis
  *(verificar)*; patrones cache-aside y write-through.

**Comparar:**

```text
SQL Database vs SQL Managed Instance vs SQL Server en VM
DTU vs vCore
General Purpose vs Business Critical vs Hyperscale
Geo-replication vs Failover group vs Read replica vs Backup
Azure SQL vs PostgreSQL Flexible Server
```

**Desmontar:** "una read replica es un backup"; "geo-replication cambia
el connection string solo" (eso lo da el failover group); "serverless
significa sin costo cuando no se usa" (el almacenamiento sigue cobrando).

**Se practica en:** ningún lab del tronco. Azure SQL tiene un drill
gratuito en `l00` §9 gracias a su oferta gratuita; el motor, PostgreSQL y
Redis se practican en contenedor.

### 08 — Cosmos DB

**Cubrir:**

- modelo de recursos: cuenta, base de datos, contenedor, item;
- las APIs (NoSQL, MongoDB en sus dos variantes, Cassandra, Gremlin, Table,
  PostgreSQL *(verificar el estado de cada una)*) y por qué se fijan al crear
  la cuenta;
- **partition key**: particiones lógicas y físicas, límite por partición
  lógica, hot partitions, claves sintéticas, hierarchical partition keys;
- Request Units: qué cuesta una lectura puntual frente a una consulta,
  throughput provisionado manual y autoscale, serverless, throughput a nivel
  de base frente a contenedor, **la oferta free tier** *(verificar RU/s,
  almacenamiento y límite por suscripción)*;
- **los cinco niveles de consistencia**, con su garantía, su latencia y su
  costo en RU;
- indexing policy: indexación automática, rutas excluidas, índices
  compuestos;
- point reads frente a consultas de una partición frente a cross-partition;
- change feed (latest version y all versions and deletes), TTL;
- escrituras multi-región y resolución de conflictos;
- transactional batch dentro de una partición lógica;
- `429` y reintentos; el cliente del SDK de Java como singleton;
- modelado desde los patrones de acceso: embeber frente a referenciar;
  Table Storage como contraste.

**Comparar** (matriz ancha admitida por la guía §3):

```text
Strong vs Bounded staleness vs Session vs Consistent prefix vs Eventual
Provisionado manual vs Autoscale vs Serverless
Point read vs consulta en partición vs cross-partition
Cosmos DB for Table vs Table Storage
Partición lógica vs partición física
```

**Desmontar:** "Cosmos DB es multi-modelo, eliges la API al consultar";
"Strong es siempre la opción segura"; "la partition key se elige por
cardinalidad y ya"; "Session consistency es consistencia por sesión HTTP".

**Se practica en:** `L07`.

### 09 — Identidad: Entra ID y managed identities

**Cubrir:**

- el tenant y sus objetos: usuarios, grupos, invitados B2B;
- **app registration (application object) frente a enterprise application
  (service principal)**; aplicaciones multi-tenant;
- credenciales de una aplicación: secretos, certificados, **federated
  credentials**;
- managed identities system-assigned y user-assigned: ciclo de vida,
  compartir, cómo obtiene el token el código (endpoint de identidad del
  host), por qué la user-assigned se prefiere cuando varias piezas comparten
  permisos;
- workload identity federation: GitHub Actions, AKS workload identity,
  otras nubes;
- tokens: access token frente a ID token, claims que importan (`aud`,
  `iss`, `tid`, `oid`, `roles`, `scp`), versiones v1 y v2 del token;
- `DefaultAzureCredential` y su cadena, en Java;
- **los roles de Entra ID frente a los roles de Azure RBAC** (se presenta
  aquí y se desarrolla en `10`); elevate access del Global Administrator;
- Conditional Access y MFA a nivel conceptual;
- el renombre de Azure AD a Microsoft Entra ID *(verificar fecha)*.

**Comparar:**

```text
App registration vs Enterprise application (service principal)
System-assigned vs User-assigned managed identity
Client secret vs Certificate vs Federated credential vs Managed identity
Access token vs ID token
Rol de Entra ID vs rol de Azure RBAC
```

**Desmontar:** "una managed identity no es un service principal";
"el Global Administrator ve todos los recursos"; "un client secret en Key
Vault es tan bueno como una managed identity".

**Se practica en:** `L02`.

### 10 — Autorización: Azure RBAC, Policy y gobierno

**Cubrir:**

- Azure RBAC: security principal, role definition (`actions`,
  `notActions`, `dataActions`, `notDataActions`, `assignableScopes`), role
  assignment, scope y herencia;
- roles built-in clave (Owner, Contributor, Reader, User Access
  Administrator, Role Based Access Control Administrator) y roles de datos
  (`Storage Blob Data *`, `Key Vault Secrets User`, los de Cosmos DB y
  Service Bus);
- custom roles; conditions (ABAC) en Storage y conditions de delegación;
- **deny assignments**: quién los crea (Managed Applications, Deployment
  Stacks) y por qué tú no;
- propagación de role assignments y caché de tokens; límites de role
  assignments por suscripción *(verificar)*;
- Privileged Identity Management: eligible frente a active, activación
  just-in-time;
- Azure Policy: definición, initiative, assignment, efectos (`deny`,
  `audit`, `modify`, `append`, `deployIfNotExists`, `auditIfNotExists`,
  `denyAction`, `disabled`), remediation tasks, exemptions, cuándo se evalúa;
- **Policy frente a RBAC**: qué puedes hacer frente a cómo tiene que quedar;
- resource locks (`CanNotDelete` y `ReadOnly`) y las sorpresas de
  `ReadOnly` sobre operaciones `POST` del control plane;
- tags como gobierno: herencia con Policy, atribución de costos;
- landing zones del Cloud Adoption Framework a nivel conceptual;
- el retiro de Azure Blueprints y sus sustitutos (Template Specs,
  Deployment Stacks) *(verificar fecha)*.

**Comparar:**

```text
Azure RBAC vs Azure Policy
Owner vs Contributor vs User Access Administrator
actions vs dataActions
Role assignment vs Deny assignment
CanNotDelete vs ReadOnly
Eligible vs Active (PIM)
```

**Desmontar:** "el Owner de la suscripción puede leer los datos del blob";
"el role assignment surte efecto al instante"; "Azure Policy da permisos";
"un lock `ReadOnly` solo impide borrar".

**Diagnóstico:** cómo se lee un `AuthorizationFailed` (principal, acción y
scope están en el mensaje) y cómo se comprueba qué roles tiene un principal
en un scope.

**Se practica en:** `L02` (RBAC) y `L03` (locks, Deployment Stacks con deny
settings, una policy asignada al resource group).

### 11 — Secretos, cifrado y Key Vault

**Cubrir:**

- Key Vault: secretos, claves y certificados; tiers Standard y Premium;
  Managed HSM a nivel conceptual;
- modelo de autorización: **Azure RBAC (recomendado) frente a access
  policies (legado)**;
- **soft-delete obligatorio y purge protection irreversible**; el nombre
  retenido durante la retención; recover frente a purge;
- redes: firewall del vault y private endpoints;
- consumo desde la app: Key Vault references en App Service y Container
  Apps, Spring Cloud Azure como property source, caché y rotación;
  eventos de expiración vía Event Grid;
- cifrado en reposo: claves administradas por la plataforma frente a
  customer-managed keys, TDE con CMK, doble cifrado;
- App Configuration: configuración y feature flags, labels, referencias a
  Key Vault;
- Defender for Cloud a nivel conceptual (postura gratuita frente a planes de
  pago); Microsoft Sentinel en una mención.

**Comparar:**

```text
Key Vault vs App Configuration
Azure RBAC vs access policies en Key Vault
Soft-delete vs Purge protection
Platform-managed key vs Customer-managed key
Secreto en Key Vault vs managed identity sin secreto
```

**Desmontar:** "si guardas el secreto en Key Vault ya estás seguro" (la
mejor credencial es la que no existe); "borrar el vault libera el nombre";
"purge protection se puede desactivar después".

**Se practica en:** `L02` (vault con RBAC) y `L09` (soft-delete y purge en
el teardown).

### 12 — Identidad de aplicaciones: OAuth 2.0 con Entra ID

**Cubrir:**

- el escenario: una API Spring Boot protegida, un cliente humano y un
  cliente máquina;
- registro de la API: Application ID URI, **scopes delegados frente a app
  roles**, consentimiento de usuario y de administrador;
- flujos: authorization code con PKCE, client credentials, on-behalf-of;
  device code en una mención;
- una managed identity como cliente de tu propia API (app role asignado al
  service principal de la identidad);
- validación del token en Spring Boot: resource server, `issuer-uri` del
  endpoint v2.0, validación de audiencia, mapeo de `scp` y `roles` a
  authorities; Spring Cloud Azure como alternativa *(versiones exactas
  verificadas)*;
- trampas: tokens v1 frente a v2 (`requestedAccessTokenVersion`), validación
  del issuer en APIs multi-tenant, grupos en el token y el overage;
- APIM con `validate-jwt` como validación en el borde (remite a `05`);
- Microsoft Entra External ID para identidades de clientes y el estado de
  Azure AD B2C *(verificar)*.

**Comparar:**

```text
Scope delegado vs App role
Authorization code + PKCE vs Client credentials vs On-behalf-of
Validar en la API vs validar en APIM
Entra ID (workforce) vs Entra External ID (customers)
```

**Desmontar:** "el ID token sirve para llamar a la API"; "si el token es
válido, el cliente está autorizado"; "los app roles son lo mismo que los
roles de Azure RBAC".

**Se practica en:** `L06`.

### 13 — Mensajería y eventos

**Cubrir:**

- el problema primero: comandos, eventos discretos y streams no son lo
  mismo;
- Storage Queues: lo mínimo, cuándo bastan;
- Service Bus: tiers, queues y topics con subscriptions y filtros,
  peek-lock frente a receive-and-delete, lock duration y renovación,
  `MaxDeliveryCount`, **DLQ incluida en cada entidad**, duplicate detection,
  sessions para orden por clave, scheduled messages, transacciones;
- Event Grid: push, system topics y custom topics, esquemas (Event Grid y
  CloudEvents), **handshake de validación del webhook**, reintentos y
  dead-letter a un blob, filtros; namespaces con MQTT y pull en una mención
  *(verificar)*;
- Event Hubs: particiones, consumer groups, checkpointing, retención,
  capture, endpoint compatible con Kafka;
- entrega at-least-once, idempotencia del consumidor y outbox;
- autenticación con managed identity y roles de datos (`Azure Service Bus
  Data Sender/Receiver`).

**Comparar** (matriz ancha admitida por la guía §3):

```text
Storage Queues vs Service Bus vs Event Grid vs Event Hubs
Queue vs Topic + subscription
Peek-lock vs Receive-and-delete
Sessions vs particiones
Push (Event Grid) vs pull (Service Bus, Event Hubs)
```

**Desmontar:** "Service Bus garantiza exactly-once"; "duplicate detection
hace idempotente al consumidor"; "Event Hubs es una cola"; "Event Grid
garantiza orden".

**Se practica en:** `L07` (Service Bus). Event Grid tiene un drill
gratuito en `l00` §9; Event Hubs se sustituye por Kafka en local.

### 14 — Observabilidad: Azure Monitor, Log Analytics y Application Insights

**Cubrir:**

- Azure Monitor como plataforma: métricas, logs, alertas, action groups;
- Log Analytics workspace: tablas, planes de tabla *(verificar)*,
  retención, costo por ingesta;
- **KQL** lo justo para diagnosticar (`where`, `summarize`, `project`,
  `extend`, `join`, `render`), con remisión a `A05`;
- Application Insights basado en workspace: el agente Java y OpenTelemetry,
  request/dependency/exception, sampling, correlación distribuida;
- **diagnostic settings**: nada de lo que un recurso registra llega al
  workspace si no se configuran;
- Activity Log: quién hizo qué en el control plane, y su retención;
- alertas: métricas, logs, activity log; costo por regla *(verificar)*;
- Azure Resource Graph para inventario;
- Network Watcher (remite a `02`); Service Health y Resource Health.

**Comparar:**

```text
Métricas vs Logs
Activity Log vs Resource logs vs Application Insights
Diagnostic setting vs agente
Log Analytics vs Resource Graph
Alerta de métrica vs alerta de log
```

**Desmontar:** "Azure registra todo por defecto"; "el Activity Log registra
las lecturas de datos"; "Application Insights es otra herramienta aparte de
Azure Monitor".

**Se practica en:** `L08`.

### 15 — Bicep e Infrastructure as Code

**Cubrir:**

- ARM como control plane y **como estado**: no hay archivo de state; lo
  desplegado es la verdad;
- plantillas ARM JSON y por qué nadie las escribe a mano;
- Bicep: parámetros, variables, recursos con versión de API fija,
  `existing`, outputs, loops y condiciones, módulos, `.bicepparam`;
- scopes de despliegue (resource group, suscripción, management group,
  tenant);
- `what-if` antes de cada despliegue; modos incremental y **complete** y el
  peligro del segundo;
- Deployment Stacks: recursos administrados como conjunto, `deny settings`
  (un deny assignment, remite a `10`), borrado de lo que sale del stack;
- Template Specs; Azure Verified Modules; `azd` en una mención;
- drift: cómo se detecta sin state (what-if) y qué pasa con un cambio hecho
  en el portal;
- **Terraform con el provider `azurerm` en una sola sección comparativa**:
  state propio, plan, multi-cloud; cuándo gana cada uno.

**Comparar:**

```text
ARM JSON vs Bicep vs Terraform
Modo incremental vs complete
what-if vs terraform plan
Deployment vs Deployment Stack
Módulo local vs Template Spec vs Azure Verified Module
```

**Desmontar:** "Bicep tiene state como Terraform"; "el modo complete solo
agrega lo que falta"; "si lo borro del Bicep, se borra en Azure" (depende del
modo o del stack).

**Se practica en:** `L03`.

### 16 — Orquestación y CI/CD

**Cubrir:**

- Durable Functions: orquestadores, actividades, patrones (chaining,
  fan-out/fan-in, human interaction), replay y sus reglas;
- Logic Apps: Consumption frente a Standard, conectores, cuándo un flujo
  sin código es la respuesta correcta;
- GitHub Actions hacia Azure **con OIDC** (federated credential, sin
  secretos), `azure/login`, permisos mínimos del principal de despliegue;
- Azure Pipelines: stages, service connections con workload identity
  federation, environments y approvals;
- estrategias de despliegue: deployment slots de App Service, revisiones
  de Container Apps con reparto de tráfico, blue/green y canary;
- promoción entre ambientes y la separación por suscripción.

**Comparar:**

```text
Durable Functions vs Logic Apps
GitHub Actions vs Azure Pipelines
Service principal con secreto vs federated credential en CI
Deployment slot vs revisión de Container Apps
Blue/green vs canary
```

**Desmontar:** "el pipeline necesita un client secret"; "swap de slots es
downtime cero siempre" (warm-up, settings pegados al slot).

**Se practica en:** el reparto de tráfico entre revisiones, en `L05`;
GitHub Actions con OIDC, en un drill gratuito de `l00` §9.

### 17 — Resiliencia y Azure Well-Architected Framework

**Cubrir:**

- los cinco pilares (Reliability, Security, Cost Optimization, Operational
  Excellence, Performance Efficiency) y sus trade-offs;
- zonas frente a regiones: qué resiliencia da cada una y a qué costo;
- SLA compuesto: cómo se calcula y por qué baja al encadenar servicios;
- patrones: retry con backoff y jitter (y los reintentos que ya hace el
  SDK de Azure), circuit breaker, bulkhead, timeout budgets, queue-based
  load leveling, throttling;
- DR con RTO y RPO sobre servicios de Azure: failover groups de SQL,
  RA-GZRS, multi-región de Cosmos DB, Front Door delante de dos regiones;
- Azure Chaos Studio en una mención; Azure Advisor.

**Comparar:**

```text
Alta disponibilidad vs Disaster recovery
Zone-redundant vs Multi-región
Backup & restore vs Pilot light vs Warm standby vs Active-active
RTO vs RPO
```

**Desmontar:** "multi-región es siempre más resiliente" (y más caro, y más
complejo de operar); "el SLA de un servicio es el SLA de mi sistema".

**Se practica en:** ningún lab; es un capítulo de diseño.

### 18 — Preguntas de entrevista y mapa mental

Ver §7.

### 19 — Respuestas

Solucionario centralizado. Formato heredado de `02-gcp/14-respuestas.md`:
Parte I (capítulos, con `18` al final y sus `P#` por nivel) y Parte II
(serie práctica); entrada `N. **enunciado literal** respuesta explicada`.

---

## 3. Caso recurrente: Spring Boot

Usa durante los documentos una aplicación backend Java/Spring Boot como
ejemplo recurrente:

```text
Internet
   │
Azure DNS
   │
Front Door (o ingress de Container Apps)
   │
Container Apps
   │
Spring Boot  ── managed identity ──┐
   ├── Azure SQL / PostgreSQL       │  sin connection strings
   ├── Cosmos DB                    │  con secretos: todo vía
   ├── Blob Storage                 │  Entra ID + Azure RBAC
   ├── Service Bus                  │
   └── Key Vault  ◄─────────────────┘
```

El hilo conductor de seguridad es que **la app no guarda ni una
credencial**: cada dependencia se alcanza con la managed identity, y los
capítulos muestran qué rol de datos hace falta en cada una.

---

## 4. Estilo general

El contenido debe sentirse como una:

```text
chuleta técnica ampliada
+
tutorial rápido
+
mapa mental
+
referencia arquitectónica
+
guía de preparación para entrevistas
```

Usa principalmente explicaciones cortas, listas, tablas comparativas,
diagramas ASCII, ejemplos pequeños, código, reglas mnemotécnicas,
advertencias, escenarios y preguntas de entrevista.

---

## 5. Formato de explicación

Para conceptos clave usar formatos similares a:

```text
NSG
→ filtra tráfico a nivel de subnet o de NIC
→ stateful
→ reglas ALLOW y DENY con prioridad numérica; gana la primera que coincide
→ si hay NSG en subnet y en NIC, el tráfico tiene que pasar los dos

Azure Firewall
→ recurso administrado, centralizado, con cargo por hora
→ filtra por FQDN, inspecciona, se pone en el hub
```

Cuando existan conceptos similares, usar tablas comparativas; las fichas de
§2 listan las comparaciones obligatorias de cada capítulo.

---

## 6. "Qué recordar" y errores frecuentes

Al final de cada tema importante, entre 3 y 10 ideas esenciales. Y en cada
capítulo, una sección de errores frecuentes que recoge las entradas
**Desmontar** de su ficha. Errores transversales que más de un capítulo
retoma:

- creer que `az group delete` deja la suscripción limpia (soft-delete,
  `NetworkWatcherRG`, role assignments en scopes superiores, objetos de
  Entra ID que viven en el tenant);
- guardar access keys o connection strings en app settings en vez de usar
  managed identity;
- asumir que un budget detiene el gasto (solo avisa);
- confundir roles de Entra ID con roles de Azure RBAC.

---

## 7. Preguntas y documento de entrevista

Cada archivo cierra con **Preguntas rápidas** según la guía de estilo §8.2,
sin respuesta inline.

`18-preguntas-entrevista-y-mapa-mental.md` organiza preguntas `P#` por
dificultad —Junior refresher, Mid, Senior, Software Architect,
Troubleshooting— con los puntos que una buena respuesta debería mencionar
y los errores frecuentes, más un bloque de escenarios de arquitectura. Las
`P#` se resuelven en el solucionario; los escenarios conservan su solución
desarrollada.

Escenarios mínimos:

1. **Una API Java recibe más solicitudes de las que puede procesar
   síncronamente.** Esperar: Container Apps, Service Bus, workers escalados
   por KEDA según mensajes pendientes, DLQ, idempotencia, backpressure.
2. **Un monolito Spring Boot corre en una VM con la contraseña de la base en
   un `.properties`.** Esperar: imagen en Container Registry, Container Apps
   o App Service, Azure SQL/PostgreSQL con autenticación de Entra ID,
   managed identity, Key Vault para lo que no admita Entra ID, Application
   Insights; y justificar si realmente hace falta AKS.
3. **Una aplicación necesita almacenar usuarios, pedidos, sesiones, PDFs,
   imágenes, eventos e histórico analítico.** Elegir entre Azure SQL,
   Cosmos DB, Blob Storage, Azure Managed Redis, Service Bus/Event Hubs y un
   almacén analítico, y justificar cada decisión.
4. **Un banco exige que ningún dato salga por Internet público.** Esperar:
   Private Endpoints, Private DNS zones, `publicNetworkAccess` deshabilitado,
   hub-and-spoke con Azure Firewall, Azure Policy que lo haga cumplir.
5. **Tres equipos comparten una suscripción y nadie sabe quién gasta qué.**
   Esperar: suscripciones por ambiente o equipo bajo management groups,
   tags heredados por Policy, budgets, RBAC por resource group.

---

## 8. Nivel técnico objetivo

El lector objetivo es Backend Senior, Software Architect, Java / Spring Boot
Developer, preparando una entrevista que incluye Azure. Asume conocimientos
previos de programación, Java, HTTP, REST, Linux, containers, SQL, redes
básicas, OAuth 2.0 a nivel de usuario y sistemas distribuidos. El propósito
es **refrescar Azure**, no enseñar informática desde cero, ni enseñar otra
nube como punto de comparación.

---

## 9. Profundidad

Priorizar profundidad en:

- jerarquía de scopes, control plane y data plane (`01`);
- VNet, NSG, Private Endpoints y su DNS (`02`, `03`);
- Entra ID, managed identities, Azure RBAC y Policy (`09`, `10`);
- Container Apps y App Service (`04`);
- Storage accounts y su redundancia (`06`);
- Azure SQL Database (`07`);
- Cosmos DB (`08`);
- Service Bus y Event Grid (`13`);
- Log Analytics y Application Insights (`14`);
- Key Vault (`11`);
- Bicep (`15`).

Dar menor profundidad a servicios especializados que no sean necesarios
para construir el mapa mental principal (Virtual WAN, Managed HSM, SQL
Managed Instance, Batch, HPC, Sentinel).

**Queda fuera del curso, y se declara así en el README:** analítica
(Microsoft Fabric, Synapse, Data Explorer, Databricks), IA y Machine
Learning, IoT, virtual desktop. No es el perfil del curso; nombrarlos en
una línea donde un escenario lo pida está bien, enseñarlos no.

---

## 10. Fuentes

Utiliza principalmente **documentación oficial de Microsoft**
(`https://learn.microsoft.com/en-us/azure/`), las páginas de pricing y la
Azure Retail Prices API para verificar precios. La única excepción es la
sección comparativa de Terraform en `15`, que puede citar el registry del
provider `azurerm` — ver la guía de estilo §10.1.

Evita como fuente principal blogs no oficiales, artículos SEO, respuestas de
Stack Overflow y material de certificación de terceros.

---

## 11. Exactitud temporal

Azure renombra y retira servicios con frecuencia. Las fichas de §2 marcan
*(verificar)* cada afirmación que depende de una fecha. Por tanto:

- verifica el estado actual de cada servicio contra Azure Updates y su
  página de retiro antes de afirmarlo;
- indica cuando una práctica o herramienta haya cambiado, con la fecha de
  efecto;
- distingue "cerrado para clientes nuevos" de "apagado";
- evita repetir reglas antiguas como absolutas;
- especifica cuando una característica nueva modifique una regla común de
  entrevista.

---

## 12. Resultado esperado

Una colección de archivos `.md` que pueda utilizarse indistintamente como
repaso rápido de Azure, chuleta técnica, material de estudio, referencia
diaria, preparación para entrevistas y base para discusión de arquitectura.

La prioridad debe ser:

```text
claridad
>
estructura
>
capacidad de consulta rápida
>
profundidad útil
>
exhaustividad de certificación
```

No produzcas una enciclopedia de todos los servicios de Azure. Construye
primero un mapa mental sólido de los servicios fundamentales y cómo se
relacionan, con la misma disciplina editorial que los cursos hermanos pero
sin depender de ellos como referencia explícita dentro del texto.
