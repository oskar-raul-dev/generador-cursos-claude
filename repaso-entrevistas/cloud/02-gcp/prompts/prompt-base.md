# Prompt: tutorial rápido de GCP para refresco técnico e entrevistas

Genera un tutorial de repaso rápido de Google Cloud Platform orientado a
refrescar conocimientos técnicos y preparar entrevistas para perfiles
**Backend Senior / Software Architect**.

El objetivo no es crear un curso exhaustivo de certificación, sino una
colección de **notas técnicas densas, prácticas, modulares y fáciles de
consultar** — sin relleno, pero **sin techo de longitud**: la guía de
estilo retiró expresamente la regla de "brevedad ante todo, 10–15 minutos
de lectura", porque producía documentos correctos donde el mecanismo
estaba y la razón no. Análoga en espíritu, tono y estructura a
`repaso-aws-entrevistas/`, pero **autocontenida**: no asumas que el
lector conoce AWS. No introduzcas tablas de mapeo AWS→GCP ni frases de
comparación con otro proveedor. Cada concepto de GCP se explica desde
cero, igual que el curso de AWS explica sus propios conceptos sin
referirse a otra nube.

**El tono, formato y convenciones editoriales exactas están definidos en
`repaso-gcp-entrevistas/prompts/guia-de-estilo-y-convenciones.md`.** Este
documento define el **contenido y alcance técnico** de cada capítulo; esa
guía define **cómo se escribe**. Ambos se usan juntos.

---

## 1. Formato de entrega

Estructura el contenido en **varios archivos Markdown (`.md`)**, separados
por categoría y ordenados desde los conceptos más fundamentales hasta los
temas de arquitectura y entrevista.

Crea además un archivo:

```text
README.md
```

que funcione como:

- índice general;
- mapa de estudio;
- guía de navegación;
- resumen de servicios;
- orden recomendado de lectura.

Usa esta numeración (ya validada, no la reordenes sin motivo fuerte):

```text
README.md
01-infraestructura-global-y-redes.md
02-computo-contenedores-y-balanceo.md
03-almacenamiento-y-bases-sql.md
04-firestore-bigtable-nosql.md
05-seguridad-iam-jerarquia-kms-secretos.md
06-cloud-dns-conectividad.md
07-pubsub-eventarc-integracion.md
08-observabilidad-auditoria-gobierno.md
09-terraform-iac.md
10-preguntas-entrevista-y-mapa-mental.md
11-resiliencia-y-well-architected.md
12-orquestacion-y-cicd.md
13-bigquery-analitica.md
14-respuestas.md
```

A esos quince archivos se suma la **serie práctica**, que ya está escrita
y cuyo alcance **no se define aquí** sino en `l00-idea-lab-practico.md`:

```text
l00-idea-lab-practico.md                                 el contrato de la serie
l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md
l02-iam-allow-policies-service-accounts-e-impersonation.md
l03-terraform-desde-la-cli.md
l04-red-vpc-firewall-y-diagnostico.md
l05-cloud-run-contrato-revisiones-y-trafico.md
l06-datos-y-eventos-firestore-pubsub-y-eventarc.md
l07-observabilidad-logs-metricas-y-auditoria.md
l08-costos-y-destruccion-verificada.md
a01-gcloud-de-supervivencia.md
a02-costos-trampas-y-recursos-huerfanos.md
a03-catalogo-de-errores-y-diagnostico.md
a04-rutina-de-recurso-cli-api-y-destruccion.md
```

**Reparto de responsabilidades entre los tres documentos rectores**, para
que un chat futuro no los confunda:

| Documento | Define |
|---|---|
| Este `prompt-base.md` | El **contenido y alcance técnico** de los capítulos teóricos `01`–`14` |
| `guia-de-estilo-y-convenciones.md` | **Cómo se escribe** todo el curso, teoría y práctica |
| `l00-idea-lab-practico.md` | El **alcance de la serie práctica**: qué entra al laboratorio de pago y qué no |

Cada archivo debe poder consultarse de forma independiente, aunque
manteniendo continuidad con los anteriores. `10` y `14` no llevan
"Preguntas rápidas"/"Referencias oficiales" propias — son excepciones de
plantilla documentadas en la guía de estilo (§6).

Cada capítulo teórico declara además, en su blockquote de encabezado, con
qué dos documentos se toca más y **en qué lab se practica** lo que explica
—o por qué no tiene lab, que en este curso también es contenido.

---

# 2. Infraestructura global de GCP

Incluir como mínimo:

- Regions;
- Zones;
- red global privada de Google (Google's global network) y su rol en
  latencia entre regiones — sin equivalente directo en el curso de otra
  nube, es diferenciador propio de GCP;
- Premium Tier vs Standard Tier de networking (a nivel conceptual: rutas
  por la red privada de Google vs por Internet público);
- relación:

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

Explicar:

- Region vs Zone;
- recursos zonales, regionales y globales (dar ejemplos de cada uno: disco
  persistente es zonal, subnet es regional, VPC e imagen son globales);
- aislamiento de fallos;
- alta disponibilidad multi-zona dentro de una región;
- estrategias multi-región;
- cuándo cada estrategia tiene sentido.

---

# 3. Networking

Cubrir:

- VPC (enfatizar que es un recurso **global**, no regional);
- modo automático vs modo personalizado de VPC (auto-mode vs custom-mode);
- CIDR;
- IPv4;
- IPv6;
- Subnets (recurso **regional**, abarca todas las zonas de su región);
- rangos de IP secundarios (alias IP ranges);
- Route Tables implícitas y rutas custom;
- longest prefix match;
- Cloud Router;
- Cloud NAT;
- IP externa efímera vs estática (reservada);
- Firewall rules (stateful, con prioridad numérica, admiten **allow y
  deny**, a diferencia de otros modelos que solo permiten reglas ALLOW);
- Hierarchical firewall policies (a nivel Organization/Folder);
- Private Google Access;
- Serverless VPC Access connector (necesario para que Cloud Run/Cloud
  Functions alcancen recursos dentro de la VPC);
- VPC Peering;
- Shared VPC (proyecto host/service projects — concepto propio de GCP sin
  equivalente directo en otras nubes, explicarlo con cuidado);
- Network Connectivity Center (hub-and-spoke a escala);
- Private Service Connect;
- Cloud VPN (Site-to-Site);
- Cloud Interconnect (Dedicated y Partner).

Explicar claramente diferencias como:

```text
VPC global vs Subnet regional
Auto-mode VPC vs Custom-mode VPC
Firewall rule vs Hierarchical firewall policy
VPC Peering vs Shared VPC vs Network Connectivity Center
Cloud VPN vs Cloud Interconnect
Private Google Access vs Private Service Connect
IPv4 vs IPv6
```

Incluir troubleshooting básico de conectividad. Por ejemplo, utilizar
esta secuencia mental:

```text
1. ¿DNS resuelve?
2. ¿La IP es correcta?
3. ¿Existe una ruta?
4. ¿El firewall rule (o hierarchical policy) permite el tráfico?
5. ¿La instancia/servicio necesita Cloud NAT o Private Google Access para salir?
6. ¿El servicio escucha realmente en el puerto?
7. ¿Connectivity Tests confirma el diagnóstico?
```

---

# 4. Cómputo

Cubrir:

- Compute Engine;
- Images (públicas y custom);
- Machine types y familias (general-purpose, compute-optimized,
  memory-optimized);
- Persistent Disk (zonal y regional);
- Managed Instance Groups (MIG);
- Instance Templates;
- Health Checks;
- escalado vertical;
- escalado horizontal (autoscaling de un MIG);
- alta disponibilidad;
- Sole-tenant nodes y Placement policies a nivel introductorio.

Explicar diferencias:

```text
Compute Engine vs Cloud Functions
Compute Engine vs containers (Cloud Run/GKE)
Scale Up vs Scale Out
Persistent Disk zonal vs regional
```

---

# 5. Load Balancing

Incluir:

- Cloud Load Balancing como stack unificado (a diferencia de productos
  separados, es una capa de balanceo global con distintos tipos de
  frontend);
- External HTTP(S) Load Balancing (global, Layer 7);
- Internal HTTP(S) Load Balancing (regional);
- Network Load Balancing (Layer 4, externo e interno);
- target proxies;
- URL maps;
- backend services;
- health checks;
- routing por host;
- routing por path;
- integración con Managed Instance Groups;
- integración con Cloud Run/GKE (Network Endpoint Groups — NEG).

Comparar:

```text
External HTTP(S) LB vs Internal HTTP(S) LB
HTTP(S) Load Balancing vs Network Load Balancing
Layer 7 vs Layer 4
```

Ejemplo:

```text
/api/users/*  → User Service (Cloud Run)
/api/orders/* → Order Service (Cloud Run)
```

---

# 6. Contenerización

Explicar el uso de containers en GCP.

Cubrir:

- Container images;
- Artifact Registry (registry de contenedores, sucesor de Container
  Registry);
- Cloud Run como **eje de la sección**: servicios (request-driven) y
  jobs (batch), scale-to-zero, concurrency por instancia, revisiones y
  tráfico dividido;
- GKE (Google Kubernetes Engine);
- GKE Autopilot vs GKE Standard (concepto propio de GCP: Autopilot
  administra los nodos, Standard da control total del node pool);
- Cloud Functions (2nd gen, construido sobre Cloud Run) para comparación;
- Cloud Build para construir y publicar imágenes.

Explicar especialmente:

```text
Cloud Run vs GKE
Cloud Run vs Cloud Functions
GKE Autopilot vs GKE Standard
Compute Engine vs Cloud Run
Artifact Registry vs Docker Hub
Containers vs Cloud Functions
```

Dejar muy claro que:

```text
Cloud Run = compute serverless para containers, request-driven o job-driven
GKE       = orquestación completa de Kubernetes, control fino
```

y que Cloud Run no reemplaza a GKE cuando se necesita control de red,
sidecars complejos, DaemonSets o recursos de Kubernetes específicos.

---

# 7. Caso recurrente: Spring Boot

Usa durante los documentos una aplicación backend Java/Spring Boot como
ejemplo recurrente.

Por ejemplo:

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

Utiliza este sistema para explicar cómo interactúan los servicios.

---

# 8. Almacenamiento

Cubrir:

- Cloud Storage;
- buckets;
- objects;
- metadata;
- versioning;
- lifecycle rules;
- storage classes (Standard, Nearline, Coldline, Archive);
- replicación multi-región a nivel introductorio;
- encryption (por defecto en reposo);
- signed URLs;
- Persistent Disk;
- Filestore.

Explicar:

```text
Object Storage
Block Storage
File Storage
```

Comparar:

```text
Cloud Storage vs Persistent Disk vs Filestore
```

Usar la analogía:

```text
Persistent Disk ≈ disco
Filestore        ≈ filesystem compartido
Cloud Storage     ≈ almacén de objetos accesible mediante API
```

---

# 9. Bases de datos SQL

Cubrir:

- Cloud SQL;
- PostgreSQL;
- MySQL;
- SQL Server;
- AlloyDB (para PostgreSQL, motor propio de alto rendimiento);
- configuración de alta disponibilidad (regional, con disco persistente
  regional y failover automático);
- Read Replicas;
- backups;
- snapshots;
- automated backups;
- point-in-time recovery;
- Cloud SQL Auth Proxy;
- connection pooling;
- Memorystore (Redis/Memcached administrado) como complemento
  introductorio.

Explicar:

```text
Cloud SQL vs AlloyDB
Alta disponibilidad regional vs Read Replica
Primary vs Replica
HA vs Scaling
```

Explicar cuándo usar una base SQL:

- relaciones complejas;
- joins;
- integridad referencial;
- transacciones;
- consultas flexibles;
- reporting operacional (no analítico — eso es BigQuery, ver sección 25).

---

# 10. Firestore, Bigtable y NoSQL

Dedicar un documento específico y con mayor profundidad a Firestore y
Bigtable.

Explicar primero:

- qué es NoSQL;
- modelo de documentos;
- modelo wide-column;
- diferencias conceptuales con SQL.

Cubrir Firestore (Native mode):

- Database;
- Collection;
- Document;
- Field;
- subcollections;
- Access Patterns;
- consultas simples y compuestas;
- índices de campo único (automáticos) y compuestos (declarados
  explícitamente);
- consistencia (fuerte para lecturas de documentos por ID y para la
  mayoría de queries; matizar los casos donde aplica eventual);
- modo de facturación (lecturas/escrituras/eliminaciones de documentos, no
  RCU/WCU);
- transactions;
- TTL policies;
- Firestore in Datastore mode (nota histórica: el modo original,
  legacy frente a Native mode);
- idempotency patterns.

Cubrir Bigtable a nivel de segunda profundidad:

- Table;
- Row key;
- Column family;
- diseño de row key y hot partitions/hotspotting;
- casos de uso (series de tiempo, IoT, analítica de alto throughput);
- cuándo Bigtable es mejor opción que Firestore (volumen y throughput
  extremos, acceso predominante por row key).

Explicar especialmente:

```text
Firestore vs Bigtable
Firestore Native mode vs Datastore mode
Firestore vs Cloud SQL
Consulta simple vs consulta compuesta (requiere índice compuesto)
Firestore vs BigQuery (operacional vs analítico)
```

Enfatizar:

> En Firestore el modelo se diseña principalmente a partir de los access
> patterns y los índices compuestos necesarios, no de las entidades
> relacionales.

Incluir ejemplos como:

```text
Collection: users/{userId}
Subcollection: users/{userId}/orders/{orderId}
```

Mostrar qué access patterns resuelve cada diseño.

---

# 11. Seguridad e IAM

Crear un documento específico de seguridad, jerarquía de recursos, KMS y
secretos.

Incluir:

## Shared Fate / Shared Responsibility

Explicar el modelo de responsabilidad compartida de Google Cloud y su
enfoque de "shared fate" (Google asume compromisos activos de
configuración segura por defecto, no solo delimita responsabilidad).

## Jerarquía de recursos

Cubrir:

- Organization;
- Folder;
- Project;
- Resource;
- herencia de políticas (allow policies e Organization Policies) hacia
  abajo en la jerarquía;
- por qué casi todo en GCP vive dentro de un Project (facturación,
  cuotas, APIs habilitadas).

```text
Organization
└── Folder (ej. "Production")
    └── Project (ej. "backend-prod")
        └── Resources (Compute Engine, Cloud Storage, ...)
```

## Cloud IAM

Cubrir:

- Members (usuarios, grupos, Service Accounts, dominios);
- Roles: primitive (Owner/Editor/Viewer), predefined y custom;
- Permissions;
- allow policies (bindings de member+role sobre un recurso, aditivas);
- IAM Conditions (condiciones sobre un binding, por tiempo/recurso/tag);
- Service Accounts;
- Workload Identity Federation (para cargas fuera de GCP) y Workload
  Identity en GKE (para Pods);
- Principle of Least Privilege;
- por qué evitar primitive roles en producción;
- IAM Deny policies (única forma explícita de negar, evaluada antes que
  cualquier allow) a nivel introductorio.

Explicar especialmente:

```text
Primitive role vs Predefined role vs Custom role
Allow policy vs Deny policy
Service Account vs usuario humano
Workload Identity Federation vs llave de Service Account descargada
```

Enfatizar que una aplicación en:

```text
Compute Engine
GKE
Cloud Run
```

debe preferir Service Accounts adjuntas (y Workload Identity en GKE) en
lugar de descargar y almacenar:

```text
service-account-key.json
```

en código, repositorios o imágenes de contenedor.

---

# 12. KMS y cifrado

Cubrir:

- Cloud KMS;
- Key rings;
- Keys (simétricas y asimétricas);
- encryption at rest (por defecto en todos los servicios de
  almacenamiento);
- encryption in transit;
- TLS;
- envelope encryption;
- Customer-Managed Encryption Keys (CMEK);
- Customer-Supplied Encryption Keys (CSEK) a nivel introductorio;
- key rotation;
- key policies (IAM sobre las keys);
- integración con Cloud Storage, Persistent Disk, Cloud SQL, Firestore y
  Secret Manager.

Explicar:

```text
Encryption at Rest
vs
Encryption in Transit
```

y:

```text
Cloud KMS
vs
Secret Manager
```

---

# 13. Secretos y configuración

Cubrir:

- Secret Manager;
- secret versions;
- rotación de credenciales;
- acceso mediante IAM;
- cifrado con Cloud KMS (Secret Manager cifra automáticamente, con opción
  de CMEK);
- Runtime Configurator / variables de entorno gestionadas a nivel
  introductorio.

Comparar:

```text
Secret Manager vs variables de entorno planas
```

---

# 14. Seguridad perimetral

Introducir:

- Cloud Armor;
- reglas de seguridad (WAF) y rate limiting;
- protección DDoS (por defecto en la red de Google, y Cloud Armor
  Managed Protection a nivel avanzado);
- Cloud CDN;
- integración de Cloud Armor con Cloud Load Balancing.

Comparar:

```text
Firewall rule vs Cloud Armor
Cloud Armor vs Cloud CDN
```

---

# 15. Gobierno organizacional

Introducir:

- Resource Manager;
- Organization Policies (constraints);
- separación de proyectos por ambiente (dev/test/prod);
- centralización de seguridad a nivel Organization/Folder.

Explicar:

```text
IAM allow policy (qué puede hacer un member)
vs
Organization Policy (qué configuraciones están permitidas en un recurso)
```

y dejar claro que una Organization Policy funciona como una restricción
de configuración a nivel de la jerarquía, no como un permiso concedido a
un member.

---

# 16. Cloud DNS

Crear un documento específico.

Explicar primero los fundamentos:

- DNS;
- domain;
- hostname;
- resolver;
- authoritative DNS;
- TTL.

Cubrir Cloud DNS:

- Managed zones;
- Public zones;
- Private zones;
- registros:
  - A;
  - AAAA;
  - CNAME;
  - MX;
  - TXT;
- routing policies disponibles (simple, weighted round robin, geolocation,
  failover);
- health checks (aclarar que, a diferencia de otras nubes, el chequeo de
  salud de Cloud DNS routing policies depende de health checks de Cloud
  Load Balancing, no de un chequeo DNS nativo independiente — señalar
  esto como matiz técnico, no como sobregeneralización a corregir con
  ⚠️).

Comparar:

```text
A vs AAAA
Public zone vs Private zone
Weighted vs Failover routing policy
Simple vs Geolocation routing policy
```

Mostrar integración:

```text
Cloud DNS
    │
    ├── Cloud Load Balancing
    ├── Cloud CDN
    └── API Gateway
```

---

# 17. Cloud CDN y certificados

Introducir:

- Cloud CDN;
- Edge caching;
- Origin (backend service);
- Cache modes y TTL;
- Google-managed SSL certificates;
- Certificate Manager;
- HTTPS en Cloud Load Balancing.

Comparar:

```text
Cloud DNS vs Cloud CDN
Cloud Load Balancing vs Cloud CDN
Certificate Manager vs Cloud KMS
```

---

# 18. API Gateway y Apigee

Introducir:

- API Gateway (serverless, orientado a backends serverless como Cloud
  Functions/Cloud Run);
- integración con Cloud Run/Cloud Functions;
- authentication/authorization a nivel general (API keys, IAM, JWT);
- throttling;
- Apigee (gestión de API a nivel enterprise: monetización, developer
  portal, analítica) como escalón superior a API Gateway.

Comparar:

```text
API Gateway vs Cloud Load Balancing
API Gateway vs Apigee
```

sin entrar todavía en detalles avanzados.

---

# 19. Mensajería y eventos

Cubrir:

## Pub/Sub

Explicar primero que Pub/Sub es el servicio unificado de mensajería de
GCP: cubre tanto el rol de cola punto-a-punto como el de pub/sub
fan-out, a diferencia de modelos que separan ambos roles en dos
servicios distintos.

- Topic;
- Publisher;
- Subscriber;
- Subscription (push y pull);
- at-least-once delivery (por defecto);
- exactly-once delivery (feature explícita, con sus condiciones);
- ordering keys (para orden dentro de una clave, no global);
- deduplication;
- Acknowledgement deadline (equivalente conceptual a un visibility
  timeout);
- retries;
- Dead-letter topics;
- retention;
- idempotencia.

Explicar:

```text
Push subscription vs Pull subscription
At-least-once vs Exactly-once delivery
Ordering key
Dead-letter topic
Idempotent Consumer
```

Ejemplo de fan-out:

```text
             Topic
          ┌───┼────┐
          ▼   ▼    ▼
        Sub  Sub  Sub
```

## Cloud Tasks

Cubrir:

- colas de tareas HTTP con control de rate y concurrencia;
- reintentos configurables;
- diferencia de propósito frente a Pub/Sub (Cloud Tasks orquesta llamadas
  HTTP puntuales controladas por el productor; Pub/Sub es fan-out
  desacoplado entre productores y consumidores).

## Eventarc

Cubrir:

- Event Bus/routing entre fuentes de eventos de GCP (Cloud Storage,
  Cloud Audit Logs, Pub/Sub) y destinos (Cloud Run, Cloud Functions,
  Workflows);
- triggers;
- event-driven architecture;
- integración con servicios de GCP.

Comparar:

```text
Pub/Sub vs Cloud Tasks vs Eventarc
Queue/Pub-Sub unificado vs Task queue vs Event routing
```

---

# 20. Procesamiento asíncrono

Usar escenarios como:

```text
POST /orders
      │
      ▼
Spring Boot (Cloud Run)
      │
      ▼
   Pub/Sub
      │
      ▼
Payment Worker (Cloud Run job)
```

Explicar:

- desacoplamiento;
- buffering;
- backpressure;
- retries;
- dead-letter topics;
- idempotencia;
- escalado de consumers (Cloud Run escala por concurrencia/mensajes
  pendientes);
- respuesta HTTP `202 Accepted`.

---

# 21. Observabilidad

Cubrir:

## Cloud Logging

- Logs;
- Log entries;
- Log buckets;
- Log sinks (para exportar a BigQuery/Cloud Storage/Pub/Sub);
- retention.

## Cloud Monitoring

- Metrics;
- Alerting policies;
- Dashboards;
- custom metrics;
- uptime checks.

## Cloud Audit Logs

- Admin Activity logs;
- Data Access logs;
- System Event logs;
- Policy Denied logs;
- quién hizo qué, cuándo y desde dónde.

## Cloud Asset Inventory

- inventario de recursos;
- historial de configuración;
- compliance.

## Networking diagnostics

- VPC Flow Logs;
- Connectivity Tests (Network Intelligence Center).

Comparar:

```text
Cloud Logging vs Cloud Monitoring
Cloud Audit Logs vs Cloud Asset Inventory
Metrics vs Logs vs Audit Events
VPC Flow Logs vs Application Logs
```

---

# 22. Infrastructure as Code

Crear un documento específico de **Terraform sobre GCP**.

Explicar primero:

```text
Infrastructure as Code
```

y por qué el capítulo usa Terraform y no Deployment Manager: Deployment
Manager es la herramienta nativa de Google, pero está en modo
mantenimiento y prácticamente no se usa en proyectos nuevos; Terraform
(con el provider `hashicorp/google`) es el estándar de facto en equipos
GCP reales y el que se pregunta en entrevistas de arquitectura. Deja esto
señalado explícitamente en el documento, no lo des por sobreentendido.

Cubrir los conceptos:

- Configuration (`.tf` files);
- Provider;
- Resource;
- State;
- HCL (HashiCorp Configuration Language).

---

# 23. Terraform básico

Cubrir los bloques fundamentales:

```hcl
terraform {}
provider "google" {}
resource "..." "..." {}
variable "..." {}
output "..." {}
```

Dejar claro que:

```text
resource
```

es el bloque central y obligatorio para definir infraestructura.

---

# 24. Terraform Resources

Ejemplo pequeño:

```hcl
resource "google_storage_bucket" "example" {
  name     = "example-app-bucket"
  location = "US"
}
```

Explicar:

```text
Resource type (google_storage_bucket)
Resource local name (example)
Arguments/Properties
```

---

# 25. Variables

Ejemplo:

```hcl
variable "environment" {
  type    = string
  default = "dev"
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment debe ser dev, test o prod."
  }
}
```

Explicar para qué sirven y cuándo usarlas.

---

# 26. Outputs

Ejemplo:

```hcl
output "bucket_name" {
  value = google_storage_bucket.example.name
}
```

Explicar:

- mostrar resultados;
- exponer valores para otros módulos o consumidores del state;
- remote state y `terraform_remote_state` a nivel introductorio.

---

# 27. Expresiones e interpolación

Cubrir como mínimo:

```text
${...} interpolation
count
for_each
Conditional expressions (a ? b : c)
Referencia entre recursos (google_compute_network.vpc.id)
```

Ejemplo:

```hcl
resource "google_storage_bucket" "app" {
  name = "${var.environment}-app-bucket"
}
```

---

# 28. Variables predefinidas del provider

Explicar:

```text
data "google_project" "current" {}
data "google_client_config" "current" {}
```

Ejemplo:

```hcl
resource "google_storage_bucket" "app" {
  name = "${data.google_project.current.project_id}-app-bucket"
}
```

---

# 29. Conditionals con count/for_each

Ejemplo:

```hcl
resource "google_project_iam_member" "prod_only" {
  count   = var.environment == "prod" ? 1 : 0
  project = var.project_id
  role    = "roles/viewer"
  member  = "group:sre@example.com"
}
```

Explicar cómo crear recursos condicionales sin un bloque `Conditions`
dedicado (a diferencia de sistemas declarativos que sí lo tienen,
Terraform resuelve esto con `count`/`for_each` y expresiones).

---

# 30. depends_on

Explicar:

- dependencias implícitas (por referencia entre atributos);
- dependencias explícitas (`depends_on`);
- cuándo `depends_on` es realmente necesario.

Evitar enseñar a usar `depends_on` innecesariamente.

---

# 31. Lifecycle de recursos

Cubrir:

```text
lifecycle {
  prevent_destroy = true
  create_before_destroy = true
  ignore_changes = [...]
}
```

Ejemplo:

```hcl
lifecycle {
  prevent_destroy = true
}
```

Explicar riesgos al destruir recursos con:

- bases de datos;
- buckets;
- datos persistentes.

---

# 32. Plan y Apply

Explicar el flujo:

```text
Configuración modificada
      │
      ▼
terraform plan
      │
      ▼
Revisión
      │
      ▼
terraform apply
```

Enfatizar que `terraform plan` permite revisar cambios antes de
aplicarlos, de forma equivalente a un change set en otros sistemas
declarativos.

---

# 33. Errores y rollback

Explicar:

- fallo durante `apply`;
- estado parcialmente aplicado;
- por qué Terraform no hace rollback automático como una transacción — el
  state queda reflejando lo que realmente se aplicó, y corregirlo requiere
  una nueva ejecución;
- importancia de un remote state con locking (ej. backend `gcs` con
  locking) para evitar corrupción por ejecuciones concurrentes.

---

# 34. Drift Detection

Explicar qué ocurre cuando alguien modifica manualmente un recurso fuera
de Terraform.

Ejemplo:

```text
Terraform state:
firewall rule permite puerto 443

Cambio manual en la consola:
puerto 22 añadido
```

Resultado al correr `terraform plan`:

```text
DRIFT DETECTADO — Terraform propone revertir el cambio manual
```

Explicar por qué mezclar IaC con cambios manuales dificulta la
administración, y mencionar `terraform import` para incorporar recursos
creados manualmente.

---

# 35. Módulos y Workspaces

Introducir:

## Módulos

Para composición y reutilización de configuración.

## Workspaces

Para manejar múltiples instancias del mismo módulo (ej. dev/test/prod)
con el mismo código.

No profundizar excesivamente.

---

# 36. Ejemplos Terraform

Incluir ejemplos pequeños y completos de:

1. bucket de Cloud Storage;
2. firewall rule;
3. Firestore database;
4. VPC;
5. subnet;
6. variables;
7. outputs.

Ejemplo objetivo:

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project_id" {
  type = string
}

resource "google_compute_network" "vpc" {
  name                    = "app-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "app" {
  name          = "app-subnet"
  ip_cidr_range = "10.0.0.0/20"
  region        = "us-central1"
  network       = google_compute_network.vpc.id
}

resource "google_compute_firewall" "allow_https" {
  name    = "allow-https"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_firestore_database" "app" {
  project     = var.project_id
  name        = "(default)"
  location_id = "us-central1"
  type        = "FIRESTORE_NATIVE"
}

output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "subnet_id" {
  value = google_compute_subnetwork.app.id
}
```

Explicar bloque por bloque, pero de forma concisa.

---

# 37. Terraform vs Deployment Manager

Crear solamente una comparación introductoria.

Comparar:

| Terraform | Deployment Manager |
|---|---|
| Multi-cloud | GCP-nativo |
| HCL | YAML/Jinja2/Python templates |
| State propio (local o remoto) | Estado administrado por Google |
| Estándar de facto en equipos GCP reales | Modo mantenimiento, poco usado en proyectos nuevos |

No convertir esta sección en tutorial de Deployment Manager.

---

# 38. Google Cloud Architecture Framework

Crear un documento de resiliencia basado en los pilares del **Google
Cloud Architecture Framework** (el equivalente de GCP a un framework de
buenas prácticas de arquitectura):

- System design;
- Operational excellence;
- Security, privacy y compliance;
- Reliability;
- Cost optimization;
- Performance optimization.

Explicar trade-offs entre pilares, y cubrir patrones de resiliencia
aplicables sobre cualquier proveedor:

- circuit breaker;
- retry con backoff + jitter;
- bulkhead;
- timeout budgets;
- estrategias de Disaster Recovery (RTO/RPO) aplicadas a servicios GCP
  (ej. Cloud SQL cross-region replicas, Cloud Storage multi-region
  buckets, backups de Firestore).

---

# 39. Orquestación y CI/CD

Cubrir:

## Workflows

- Workflow;
- Steps;
- llamadas a APIs de GCP y HTTP endpoints externos;
- manejo de errores y retries dentro de un workflow.

## Cloud Build

- build triggers;
- build steps;
- integración con Artifact Registry;
- integración con repositorios (Cloud Source Repositories, GitHub,
  GitLab).

## Cloud Deploy

- delivery pipelines;
- targets (ej. dev/staging/prod);
- estrategias de despliegue (rolling, canary, blue/green a nivel
  conceptual).

Comparar:

```text
Workflows vs Eventarc + Cloud Run (orquestación explícita vs event-driven)
Cloud Build vs Cloud Deploy (construir/probar vs promover a ambientes)
```

---

# 40. BigQuery y analítica

Crear un documento específico — **sin equivalente cubierto en el curso
de referencia de otra nube**, incluido porque es un diferenciador fuerte
de GCP y aparece con frecuencia en entrevistas de arquitectura.

Cubrir:

- qué es un data warehouse serverless y en qué se diferencia de una base
  operacional (Cloud SQL/Firestore);
- Dataset;
- Table;
- Schema;
- particionado de tablas (por fecha/tiempo de ingestión);
- clustering;
- slots y el modelo de facturación (on-demand por bytes escaneados vs
  capacidad reservada);
- streaming inserts vs carga batch;
- vistas y vistas materializadas a nivel introductorio;
- BigQuery ML y BI Engine a nivel de mención, sin profundizar;
- de dónde vienen los datos en una arquitectura típica (Pub/Sub → BigQuery,
  Cloud Storage → BigQuery, Cloud Logging sinks → BigQuery).

Explicar:

```text
BigQuery vs Cloud SQL/AlloyDB (analítico vs operacional)
BigQuery vs Firestore (SQL sobre grandes volúmenes vs acceso transaccional por documento)
Particionado vs Clustering
On-demand pricing vs capacidad reservada
```

Enfatizar:

> BigQuery no reemplaza a una base operacional: está optimizado para
> escanear grandes volúmenes de datos históricos con SQL, no para
> transacciones de baja latencia sobre un registro individual.

---

# 41. Estilo general

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

Usa principalmente:

- explicaciones cortas;
- listas;
- tablas comparativas;
- diagramas ASCII;
- ejemplos pequeños;
- código;
- reglas mnemotécnicas;
- advertencias;
- escenarios;
- preguntas de entrevista.

Evita bloques de prosa excesivamente largos.

---

# 42. Formato de explicación

Para conceptos clave usar formatos similares a:

```text
Firewall rule
→ permite/deniega tráfico a nivel de red VPC
→ stateful
→ admite ALLOW y DENY, con prioridad numérica

Hierarchical firewall policy
→ se aplica a nivel Organization/Folder
→ hereda hacia todos los proyectos debajo
```

Cuando existan conceptos similares, usar tablas comparativas.

Ejemplos:

```text
Compute Engine vs Cloud Run vs GKE vs Cloud Functions
Cloud SQL vs AlloyDB
Alta disponibilidad regional vs Read Replica
Cloud Storage vs Persistent Disk vs Filestore
Firewall rule vs Hierarchical firewall policy
Pub/Sub vs Cloud Tasks vs Eventarc
Primitive role vs Predefined role vs Custom role
External HTTP(S) LB vs Internal HTTP(S) LB
VPC Peering vs Shared VPC vs Network Connectivity Center
Terraform vs Deployment Manager
Firestore vs Bigtable
Cloud DNS vs Cloud CDN
API Gateway vs Apigee
Secret Manager vs Cloud KMS
BigQuery vs Cloud SQL/AlloyDB
```

---

# 43. "Qué recordar"

Al final de cada tema importante agregar una pequeña sección:

```markdown
## Qué recordar
```

con entre 3 y 10 ideas esenciales.

Ejemplo:

```text
- VPC es un recurso global.
- Subnet es regional y abarca todas las zonas de esa región.
- Firewall rule admite ALLOW y DENY, con prioridad numérica.
- IAM allow policies son aditivas.
- Cloud Run escala a cero por defecto.
```

---

# 44. Errores frecuentes

Crear subsecciones:

```markdown
## Errores y confusiones frecuentes
```

Por ejemplo:

- creer que la VPC es un recurso regional (es global; la subnet es
  regional);
- creer que una subnet puede abarcar varias regiones (abarca todas las
  zonas de una única región);
- creer que Cloud Run reemplaza a GKE en todos los casos;
- confundir GKE Autopilot con GKE Standard;
- creer que Firestore es siempre fuertemente consistente para cualquier
  tipo de consulta;
- tratar Deployment Manager como el estándar actual de IaC en GCP;
- olvidar que las allow policies de IAM son aditivas y no existe un "deny
  explícito" salvo mediante IAM Deny policies;
- confundir primitive roles (Owner/Editor/Viewer) con predefined roles de
  least privilege;
- asumir que una VM sin IP externa no tiene salida a Internet (falta
  considerar Cloud NAT);
- confundir Cloud Armor con firewall rules de VPC;
- asumir que Pub/Sub entrega exactly-once por defecto;
- guardar llaves de Service Account (`.json`) dentro de containers o
  repositorios;
- confundir BigQuery con una base de datos operacional.

---

# 45. Preguntas de entrevista por documento

Al final de cada archivo agregar (siguiendo el formato "Preguntas
rápidas" definido en la guía de estilo, sin respuesta inline):

```markdown
## Preguntas rápidas
```

con entre **8 y 15 preguntas** de autochequeo.

Ejemplo:

```text
1. ¿Una VPC es un recurso global o regional?
2. ¿Por qué una subnet es regional y no zonal?
3. ¿Cloud Run escala a cero por defecto?
4. ¿Por qué una allow policy de IAM es aditiva?
5. ¿Qué diferencia existe entre firewall rule y hierarchical firewall policy?
```

---

# 46. Documento específico de entrevistas

Crear finalmente:

```text
10-preguntas-entrevista-y-mapa-mental.md
```

Organizar preguntas por dificultad:

```text
Junior refresher
Mid
Senior
Software Architect
Troubleshooting
Architecture scenarios
```

Incluir:

- pregunta;
- puntos que una buena respuesta debería mencionar;
- errores frecuentes.

Las preguntas `P#` de este documento **no** llevan respuesta inline — se
resuelven, explicadas, en `14-respuestas.md` (ver guía de estilo §5 y
§6). Los escenarios de arquitectura sí conservan su solución desarrollada
en el propio documento.

---

# 47. Escenarios Senior / Architect

Incluir preguntas como:

### Escenario 1

Una API Java recibe más solicitudes de las que puede procesar
síncronamente.

Preguntar:

> ¿Cómo diseñarías la arquitectura?

Esperar conceptos como:

```text
Cloud Run
Pub/Sub
workers (Cloud Run jobs)
autoscaling por concurrencia/mensajes pendientes
dead-letter topic
idempotency
backpressure
```

### Escenario 2

Una aplicación Spring Boot monolítica está desplegada directamente en una
Compute Engine.

Preguntar:

> ¿Cómo la modernizarías sin introducir complejidad innecesaria?

Esperar discutir:

```text
Container image
Artifact Registry
Cloud Run
Cloud Load Balancing
Cloud SQL
Secret Manager
Cloud Monitoring / Cloud Logging
```

y justificar si realmente se necesita GKE.

### Escenario 3

Una aplicación necesita almacenar:

- usuarios;
- pedidos;
- sesiones;
- documentos PDF;
- imágenes;
- eventos;
- histórico analítico para reporting.

Preguntar qué usar entre:

```text
Cloud SQL / AlloyDB
Firestore
Cloud Storage
Pub/Sub
BigQuery
```

y justificar cada decisión.

---

# 48. Nivel técnico objetivo

El lector objetivo es:

```text
Backend Senior
Software Architect
Java / Spring Boot Developer
Cloud refresher
GCP interview preparation
```

Asume conocimientos previos de:

- programación;
- Java;
- HTTP;
- REST;
- Linux;
- containers;
- SQL;
- redes básicas;
- sistemas distribuidos.

No gastar demasiado espacio explicando conceptos elementales de
programación.

El propósito es **refrescar GCP**, no enseñar informática desde cero, ni
enseñar otra nube como punto de comparación.

---

# 49. Profundidad

Utiliza aproximadamente esta prioridad:

```text
⭐⭐⭐⭐⭐ imprescindible para entrevista
⭐⭐⭐⭐ importante
⭐⭐⭐ útil
⭐⭐ conocimiento complementario
⭐ referencia
```

Priorizar profundidad en:

- VPC;
- Subnets;
- Firewall rules;
- Cloud IAM (incluida la jerarquía Organization/Folder/Project);
- Cloud Storage;
- Cloud SQL;
- Firestore;
- Cloud Run;
- GKE;
- Cloud Load Balancing;
- Cloud DNS;
- Pub/Sub;
- Cloud Logging / Cloud Monitoring;
- Terraform;
- BigQuery.

Dar menor profundidad a servicios especializados que no sean necesarios
para construir el mapa mental principal (ej. Apigee, BigQuery ML, Sole-
tenant nodes).

---

# 50. Fuentes

Utiliza principalmente **documentación oficial de Google Cloud**
(`https://cloud.google.com/`).

La única excepción es el capítulo de Terraform (`09-terraform-iac.md`),
que también puede citar `https://registry.terraform.io/providers/hashicorp/google/latest/docs`
como fuente primaria, porque Terraform no es nativo de Google — ver la
guía de estilo §8.

Antes de afirmar detalles que puedan haber cambiado, verifica la
documentación actual.

Evita usar como fuente principal:

- blogs no oficiales;
- artículos SEO;
- respuestas de Stack Overflow;
- material de certificación de terceros,

cuando exista documentación oficial de Google Cloud.

Al final de cada archivo agregar:

```markdown
## Referencias oficiales
```

con enlaces relevantes a:

```text
https://cloud.google.com/
```

Priorizar enlaces específicos de cada servicio.

---

# 51. Exactitud temporal

GCP cambia servicios y características con frecuencia, y además
renombra productos más seguido que otras nubes (ejemplo histórico:
Stackdriver → Cloud Operations Suite → nombres actuales Cloud Logging /
Cloud Monitoring). Por tanto:

- verifica conceptos actuales;
- indica cuando una práctica o herramienta haya cambiado o esté en modo
  mantenimiento (como Deployment Manager frente a Terraform);
- evita repetir reglas antiguas como absolutas;
- distingue características legacy (ej. Datastore mode) de las actuales
  (Firestore Native mode);
- especifica cuando una característica nueva modifique una regla común de
  entrevista.

---

# 52. Resultado esperado

El resultado final debe ser una colección de archivos `.md` que pueda
utilizarse indistintamente como:

```text
repaso rápido de GCP
chuleta técnica
material de estudio
referencia diaria
preparación para entrevistas
base para discusión de arquitectura
```

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

No produzcas una enciclopedia de todos los servicios GCP.

Construye primero un mapa mental sólido de los servicios fundamentales y
cómo se relacionan, siguiendo la misma disciplina editorial que
`repaso-aws-entrevistas/` pero sin depender de ese curso como referencia
explícita dentro del texto.
