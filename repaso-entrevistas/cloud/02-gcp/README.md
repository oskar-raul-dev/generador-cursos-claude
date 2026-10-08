# GCP Core Refresh — repaso para entrevistas y serie práctica de labs

> **Objetivo:** refrescar Google Cloud para entrevistas técnicas y conversaciones de arquitectura
> backend/Senior/Architect, y —en la serie práctica— encender infraestructura de verdad desde la
> CLI y desde Terraform, romperla a propósito, diagnosticarla y **destruirla con certeza**.
> **Audiencia:** perfiles de IT con experiencia en desarrollo backend. No se asume conocimiento
> previo de GCP ni de ninguna otra nube: el curso es autocontenido y **no traduce desde AWS**.
> **Alcance:** no intenta cubrir el catálogo de GCP, que pasa de los doscientos productos.
> Prioriza el vocabulario, los mecanismos y los matices que separan a quien entiende el modelo de
> quien memorizó la lista.
> **Vigencia:** 6 de septiembre de 2026.

**Salto rápido:** [Cómo está organizado](#cómo-está-organizado) ·
[Capítulos teóricos](#capítulos-teóricos) · [Serie práctica](#serie-práctica-labs-y-apéndices) ·
[Mapa mental](#mapa-mental-de-una-aplicación-típica) ·
[Asociaciones](#asociaciones-que-conviene-memorizar) · [Regla de estudio](#regla-de-estudio)

---

## Cómo está organizado

Veintiocho documentos en dos bloques que se leen bien por separado y mucho mejor juntos.

```text
CAPÍTULOS TEÓRICOS  01–13        se leen      → reconocer, explicar, comparar, decidir
  + 14 solucionario              se consulta
                    │
                    │  cada capítulo dice DÓNDE SE PRACTICA lo que explica
                    ▼
SERIE PRÁCTICA      L00          el contrato: qué entra al laboratorio de pago y qué no
                    L01–L08      se ejecutan  → encender, romper, diagnosticar, destruir
                    A01–A04      se consultan → CLI, costos, errores, la rutina de recurso
```

Tres reglas de lectura que conviene conocer antes de empezar:

- **Ningún documento lleva la respuesta junto a la pregunta.** Todas las "Preguntas rápidas" se
  responden, explicadas, en [`14`](14-respuestas.md).
- **Cada capítulo teórico declara dónde se practica**, y cada lab declara qué capítulo lo sostiene.
  Cuando algo **no** tiene lab, el capítulo dice por qué y dónde se practica en su lugar.
- **Los labs son acumulativos y declaran su costo.** La serie completa cuesta **menos de $1** y
  cada lab cierra con su propio teardown, así que abandonarla a mitad no deja nada encendido.

---

## Capítulos teóricos

1. **[Infraestructura global y redes](01-infraestructura-global-y-redes.md)**
   - Regions, Zones, VPC global, subnets regionales, Shared VPC, firewall rules, Cloud Router, Cloud NAT, Private Google Access, VPC Peering y Private Service Connect.
2. **[Cómputo, contenedores y balanceo](02-computo-contenedores-y-balanceo.md)**
   - Compute Engine, imágenes, Managed Instance Groups, Cloud Run, GKE, Cloud Functions y Cloud Load Balancing.
3. **[Almacenamiento y bases SQL](03-almacenamiento-y-bases-sql.md)**
   - Cloud Storage, Persistent Disk, Filestore, Cloud SQL, AlloyDB, alta disponibilidad, read replicas y Memorystore.
4. **[Firestore, Bigtable y NoSQL](04-firestore-bigtable-nosql.md)**
   - Firestore (Native mode), modelo de documentos, access patterns, índices, Bigtable, diseño de row key y hot partitions.
5. **[Seguridad, IAM, jerarquía, KMS y secretos](05-seguridad-iam-jerarquia-kms-secretos.md)**
   - Cloud IAM (roles, bindings, allow policies), jerarquía Organization → Folder → Project, Service Accounts, Workload Identity, Cloud KMS, Secret Manager, Cloud Armor y Organization Policies.
6. **[Cloud DNS, CDN, API management y conectividad](06-cloud-dns-conectividad.md)**
   - Managed zones, registros, routing policies, Cloud CDN, certificados administrados, API Gateway, Apigee, Cloud VPN, Cloud Interconnect y Private Service Connect.
7. **[Pub/Sub, Eventarc e integración](07-pubsub-eventarc-integracion.md)**
   - Topics, subscriptions push/pull, ordering keys, dead-letter topics, Cloud Tasks, Eventarc e idempotencia.
8. **[Observabilidad, auditoría y gobierno](08-observabilidad-auditoria-gobierno.md)**
   - Cloud Logging, Cloud Monitoring, Cloud Audit Logs, Cloud Asset Inventory y VPC Flow Logs.
9. **[Terraform e Infrastructure as Code](09-terraform-iac.md)**
   - HCL, providers, resources, state, plan/apply, módulos, drift y por qué Terraform (no Deployment Manager) es el estándar de facto en GCP.
10. **[Preguntas de entrevista y mapa mental](10-preguntas-entrevista-y-mapa-mental.md)**
    - Comparaciones rápidas, preguntas tipo entrevista y escenarios de arquitectura.
11. **[Resiliencia y Google Cloud Architecture Framework](11-resiliencia-y-well-architected.md)**
    - Los pilares del framework, circuit breaker, retry con backoff+jitter, bulkhead, timeout budgets y estrategias de Disaster Recovery (RTO/RPO).
12. **[Orquestación y CI/CD](12-orquestacion-y-cicd.md)**
    - Workflows, Cloud Build, Cloud Deploy y estrategias de despliegue.
13. **[BigQuery y analítica](13-bigquery-analitica.md)**
    - Datasets, slots, partitioning, clustering, streaming inserts y cuándo un data warehouse reemplaza a una base operacional.
14. **[Respuestas](14-respuestas.md)**
    - Solucionario centralizado: respuestas explicadas a las "Preguntas rápidas" de `01`–`09`/`11`–`13`, a las preguntas `P#` de [`10`](10-preguntas-entrevista-y-mapa-mental.md) y a las de la serie práctica ([`L00`](l00-idea-lab-practico.md), labs y apéndices). Ningún otro documento lleva la respuesta junto a la pregunta.


### Dónde se practica cada capítulo

Cada capítulo lo declara en su propio encabezado; esta es la vista de conjunto. Que un tema **no**
tenga lab no es un hueco: es una decisión de costo justificada en
[`L00` §4](l00-idea-lab-practico.md#4--el-catálogo-completo-de-exclusiones).

| Capítulo | Se practica en | Si no, por qué |
|---|---|---|
| [`01`](01-infraestructura-global-y-redes.md) redes | [`L04`](l04-red-vpc-firewall-y-diagnostico.md) | — |
| [`02`](02-computo-contenedores-y-balanceo.md) cómputo | [`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md) | GKE y las VMs son drills: no enseñan nube |
| [`03`](03-almacenamiento-y-bases-sql.md) storage y SQL | [`L03`](l03-terraform-desde-la-cli.md) (buckets) | Cloud SQL factura por hora y no tiene Always Free |
| [`04`](04-firestore-bigtable-nosql.md) NoSQL | [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) | — |
| [`05`](05-seguridad-iam-jerarquia-kms-secretos.md) IAM y seguridad | [`L02`](l02-iam-allow-policies-service-accounts-e-impersonation.md) | — |
| [`06`](06-cloud-dns-conectividad.md) DNS y conectividad | [`L04`](l04-red-vpc-firewall-y-diagnostico.md) (parcial) | Un forwarding rule global cuesta ~$0.025/h |
| [`07`](07-pubsub-eventarc-integracion.md) mensajería | [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) | — |
| [`08`](08-observabilidad-auditoria-gobierno.md) observabilidad | [`L07`](l07-observabilidad-logs-metricas-y-auditoria.md) | — |
| [`09`](09-terraform-iac.md) Terraform | [`L03`](l03-terraform-desde-la-cli.md) | — |
| [`11`](11-resiliencia-y-well-architected.md) resiliencia | [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) (reintentos) | Un DR real cuesta dinero de verdad |
| [`12`](12-orquestacion-y-cicd.md) CI/CD | [`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md) (canary) | Cloud Build y Cloud Deploy quedan como drill |
| [`13`](13-bigquery-analitica.md) BigQuery | drill opcional | El sistema del lab es transaccional |

Y al revés: todo el trabajo de costo y destrucción de
[`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md) y
[`L08`](l08-costos-y-destruccion-verificada.md) **no tiene capítulo teórico**, porque solo se
aprende pagando. Su documento de referencia es
[`A02`](a02-costos-trampas-y-recursos-huerfanos.md).

---

## Serie práctica: labs y apéndices

La parte teórica se lee; esta se ejecuta contra un proyecto real. Empieza siempre por el
encuadre, que define **qué entra en el laboratorio de pago y qué no**, el presupuesto y cómo se
garantiza que no quede nada encendido.

- **[`L00` — Introducción a la serie práctica](l00-idea-lab-practico.md)**
  - El contrato: doctrina de reparto entre nube y contenedor local, catálogo de exclusiones
    justificadas, el sistema que se construye, presupuesto y ampliaciones opcionales.

Los labs son **acumulativos y en orden**. Cada uno declara su costo, su duración y qué deja
encendido al terminar.

| Lab | Tema | Costo | Duración |
|---|---|---|---|
| [`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md) | Proyecto, jerarquía, `gcloud`, APIs y presupuesto | $0.00 | 60–90 min |
| [`L02`](l02-iam-allow-policies-service-accounts-e-impersonation.md) | IAM: allow policies, service accounts e impersonation | $0.00 | 2–3 h |
| [`L03`](l03-terraform-desde-la-cli.md) | Terraform desde la CLI | $0.00 | 2–3 h |
| [`L04`](l04-red-vpc-firewall-y-diagnostico.md) | Red: VPC, firewall y Private Google Access | $0.00 | 2–3 h |
| [`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md) | Cloud Run: contrato, revisiones y tráfico | centavos | 3 h |
| [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) | Datos y eventos: Firestore, Pub/Sub y Eventarc | centavos | 3–4 h |
| [`L07`](l07-observabilidad-logs-metricas-y-auditoria.md) | Observabilidad: logs, métricas, alertas y auditoría | $0.00 | 2–3 h |
| [`L08`](l08-costos-y-destruccion-verificada.md) | Costos y destrucción verificada | $0.00 | 2 h |

Los apéndices no tienen orden ni prerrequisitos: se consultan desde cualquier lab.

- **[`A01` — `gcloud` de supervivencia](a01-gcloud-de-supervivencia.md)** — configuraciones,
  autenticación y ADC, impersonation, `--format`, `--filter`, `--flatten`, `--log-http`.
- **[`A02` — Costos, trampas y recursos huérfanos](a02-costos-trampas-y-recursos-huerfanos.md)** —
  qué cobra por existir, qué sobrevive a cada borrado y cómo se verifica un teardown.
- **[`A03` — Catálogo de errores y diagnóstico](a03-catalogo-de-errores-y-diagnostico.md)** —
  `SERVICE_DISABLED`, `PERMISSION_DENIED`, el 403 de una push subscription, cuotas y red, con el
  comando que confirma cada causa.
- **[`A04` — Rutina de recurso: CLI, API y destrucción](a04-rutina-de-recurso-cli-api-y-destruccion.md)** —
  la única pieza del curso que se *hace*: crear, inspeccionar, modificar, destruir y verificar
  cualquier recurso, desde `gcloud` y desde el SDK.

---

## Mapa mental de una aplicación típica

```text
Usuarios
   │
   ▼
Cloud DNS
   │
   ▼
Cloud Load Balancing (global)
   │
   ├───────────────┐
   ▼               ▼
Cloud Run       Cloud Run
region-a        region-b
   │               │
   └───────┬───────┘
           │
     ┌─────┼──────────┬─────────────┐
     ▼     ▼          ▼             ▼
 Cloud SQL Firestore Cloud Storage  Pub/Sub
   SQL      NoSQL      Objects     Async work
     │                                 │
     └──────────────┐                  ▼
                    │                Worker
                    ▼              (Cloud Run job)
          Cloud Logging/Monitoring

IAM alrededor de todos los recursos, atado a la jerarquía Organization/Folder/Project.
VPC (global)/subnets (regionales)/firewall rules debajo de los workloads de red.
Terraform puede describir gran parte de la infraestructura.
```

> 📝 **Este es el mapa de una aplicación típica, no el del laboratorio.** El sistema que construye
> la serie práctica es deliberadamente más pequeño y **no lleva load balancer**: Cloud Run ya
> publica una URL HTTPS con certificado administrado sin cobrar por ella, mientras que un
> forwarding rule global cuesta del orden de $0.025/h. La diferencia está explicada en
> [`L00` §5](l00-idea-lab-practico.md#5--el-sistema-que-vas-a-construir).

---

## Asociaciones que conviene memorizar

| Necesidad | Servicio/concepto |
|---|---|
| Región geográfica | Region |
| Aislamiento de fallos | Zone |
| Red virtual (alcance global) | VPC |
| Segmento de red regional | Subnet |
| Firewall stateful de red | Firewall rules |
| Reglas de firewall a nivel Organization/Folder | Hierarchical firewall policies |
| VM | Compute Engine |
| Imagen de VM | Image |
| Block storage | Persistent Disk |
| Object storage | Cloud Storage |
| File storage compartido | Filestore |
| Registry de contenedores | Artifact Registry |
| Compute serverless para containers (default) | Cloud Run |
| Kubernetes administrado | GKE |
| Functions serverless | Cloud Functions |
| API administrada | API Gateway / Apigee |
| CDN/edge cache | Cloud CDN |
| Certificados TLS administrados | Google-managed SSL certificates |
| SQL administrado | Cloud SQL / AlloyDB |
| NoSQL document/key-value | Firestore |
| NoSQL wide-column a gran escala | Bigtable |
| Cache administrado | Memorystore |
| Queue + Pub/Sub unificado | Pub/Sub |
| Cola de tareas HTTP con rate control | Cloud Tasks |
| Event routing entre servicios administrados | Eventarc |
| DNS | Cloud DNS |
| L7 load balancing (global) | Cloud Load Balancing (HTTP(S)) |
| L4 load balancing | Network Load Balancing |
| Identidad y autorización | Cloud IAM |
| Jerarquía de recursos | Organization → Folder → Project |
| Cifrado/keys | Cloud KMS |
| Secretos | Secret Manager |
| Métricas/logs | Cloud Monitoring / Cloud Logging |
| Auditoría de API | Cloud Audit Logs |
| Inventario y compliance de recursos | Cloud Asset Inventory |
| IaC de facto en GCP | Terraform |
| Framework de evaluación de arquitectura | Google Cloud Architecture Framework |
| Orquestación de workflows serverless | Workflows |
| Identidad de usuario final de una app | Identity Platform / Firebase Authentication |
| Streaming de datos con múltiples lectores | Pub/Sub (ordering keys) / Dataflow |
| Data warehouse analítico serverless | BigQuery |

---

## Regla de estudio

Para cada servicio intenta contestar seis preguntas. Las cinco primeras te sirven para la
entrevista; la sexta es la que separa a quien ha operado de quien ha leído.

1. **¿Qué problema resuelve?**
2. **¿Es zonal, regional o global?**
3. **¿Quién administra la infraestructura: Google o yo?**
4. **¿Cuál es la alternativa más parecida y en qué se diferencia?**
5. **¿Qué fallo o requisito de seguridad cambia el diseño?**
6. **¿Cobra por existir o por uso, y qué queda vivo cuando lo borro?**

La sexta tiene su propio documento: [`A02` — costos, trampas y recursos
huérfanos](a02-costos-trampas-y-recursos-huerfanos.md).

Y para cualquier servicio que te intimide antes de una entrevista, existe un procedimiento fijo
—crear, inspeccionar, modificar, destruir, verificar, y repetirlo desde el SDK— en
[`A04` — rutina de recurso](a04-rutina-de-recurso-cli-api-y-destruccion.md).

---

## Referencias oficiales base

- Regions and zones: https://cloud.google.com/compute/docs/regions-zones
- Virtual Private Cloud (VPC) overview: https://cloud.google.com/vpc/docs/vpc
- Compute Engine documentation: https://cloud.google.com/compute/docs
- Cloud Run documentation: https://cloud.google.com/run/docs
- Google Kubernetes Engine documentation: https://cloud.google.com/kubernetes-engine/docs
- Firestore documentation: https://cloud.google.com/firestore/docs
- Cloud DNS documentation: https://cloud.google.com/dns/docs
- Identity and Access Management documentation: https://cloud.google.com/iam/docs
- Terraform Google Cloud provider: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- BigQuery documentation: https://cloud.google.com/bigquery/docs
