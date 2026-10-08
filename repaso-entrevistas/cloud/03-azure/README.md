# Azure Core Refresh — repaso para entrevistas y serie práctica de labs

> **Objetivo:** refrescar Microsoft Azure para entrevistas técnicas y conversaciones de arquitectura
> backend, Senior y Software Architect, y —en la serie práctica— encender infraestructura de verdad
> desde la CLI y desde Bicep, romperla a propósito, diagnosticarla y **destruirla con certeza**.
> **Audiencia:** perfiles con experiencia en desarrollo backend, con Java y Spring Boot como stack de
> referencia. No se asume conocimiento previo de Azure ni de ninguna otra nube: el curso es
> autocontenido y **no traduce desde AWS ni desde GCP**.
> **Alcance:** no intenta cubrir el catálogo de Azure, que pasa de los doscientos servicios. Prioriza el
> vocabulario, los mecanismos y los matices que separan a quien entiende el modelo de quien memorizó la
> lista.
> **Estado de la serie práctica:** los labs y apéndices ejecutables están redactados y verificados
> contra la documentación, pero **pendientes de correr** contra una suscripción: donde iría la salida
> literal de un comando hay un bloque `[PENDIENTE DE CORRIDA]` que dice qué debe mostrar.
> **Vigencia:** 29 de septiembre de 2026. Cada documento repite su propia fecha de revisión.

**Salto rápido:** [Cómo está organizado](#cómo-está-organizado) ·
[Orden de lectura](#orden-de-lectura-recomendado) · [Capítulos teóricos](#capítulos-teóricos) ·
[Dónde se practica](#dónde-se-practica-cada-capítulo) · [Serie práctica](#serie-práctica-labs-y-apéndices) ·
[Mapa mental](#mapa-mental-de-una-aplicación-típica) · [Asociaciones](#asociaciones-que-conviene-memorizar) ·
[Qué queda fuera](#qué-queda-fuera-del-curso) · [Regla de estudio](#regla-de-estudio)

---

## Cómo está organizado

Treinta y cinco documentos en dos bloques que se leen bien por separado y mucho mejor juntos.

```text
CAPÍTULOS TEÓRICOS  01–17        se leen      → reconocer, explicar, comparar, decidir
  + 18 simulación                se ensaya    → preguntas P# por nivel y escenarios resueltos
  + 19 solucionario              se consulta
                    │
                    │  cada capítulo dice DÓNDE SE PRACTICA lo que explica
                    ▼
SERIE PRÁCTICA      L00          el contrato: qué entra al laboratorio de pago y qué no
                    L01–L09      se ejecutan  → encender, romper, diagnosticar, destruir
                    A01–A05      se consultan → CLI, costos, errores, la rutina de recurso, KQL
```

Tres reglas de lectura que conviene conocer antes de empezar:

- **Ningún documento lleva la respuesta junto a la pregunta.** Todas las "Preguntas rápidas" y las
  `P#` de la simulación se responden, explicadas, en [`19`](19-respuestas.md).
- **Cada capítulo teórico declara dónde se practica**, y cada lab declara qué capítulo lo sostiene.
  Cuando algo **no** tiene lab, el capítulo dice por qué y dónde se practica en su lugar.
- **Los labs son acumulativos y declaran su costo.** La serie completa cuesta **menos de un dólar** si
  se hace seguida, y cada lab escribe su teardown junto a cada recurso, así que abandonarla a mitad no
  deja nada encendido sin avisar.

---

## Orden de lectura recomendado

```text
Semana de repaso para una entrevista      Serie práctica completa
─────────────────────────────────────     ─────────────────────────────────────
01 → 09 → 10 → 02 → 03                    L00 → A01
04 → 06 → 08 → 13                         L01 → L02 → L03 → L04 → L05
11 → 12 → 14 → 15 → 16 → 17               L06 → L07 → L08 → L09
07 → 05                                   A02, A03, A04, A05 cuando hagan falta
18 (en voz alta, con cronómetro)
```

- La columna izquierda empieza por la **jerarquía de scopes y los dos planos de autorización**
  (`01`, `09`, `10`): son lo que más se pregunta y lo que más se malinterpreta, y todo lo demás se apoya
  en ellos.
- La derecha es el orden obligatorio de los labs, que son acumulativos.
- Si vienes con poco tiempo para la práctica, el recorrido mínimo que sigue enseñando algo es
  [`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md) → [`L02`](l02-entra-id-rbac-y-managed-identities.md)
  → [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) → [`L09`](l09-costos-y-destruccion-verificada.md).

---

## Capítulos teóricos

1. **[Infraestructura global y Resource Manager](01-infraestructura-global-y-resource-manager.md)**
   - Regions, Availability Zones y region pairs; management group → suscripción → resource group; ARM, control plane y data plane, resource providers, tags y cuotas.
2. **[Redes: VNet, NSG y enrutamiento](02-redes-vnet-nsg-y-enrutamiento.md)**
   - VNet regional, subnets privadas, NSG y ASG, UDR, NAT Gateway, salida por defecto, peering, hub-and-spoke y Azure Firewall.
3. **[Conectividad privada y DNS](03-conectividad-privada-y-dns.md)**
   - Service endpoints frente a private endpoints, Private DNS zones, `168.63.129.16`, DNS Private Resolver, VPN Gateway y ExpressRoute.
4. **[Cómputo y contenedores](04-computo-y-contenedores.md)**
   - VMs y VM Scale Sets, App Service, Container Apps con revisiones y KEDA, AKS a nivel de decisión, Functions, Container Registry, y dónde correr Spring Boot hoy.
5. **[Balanceo, entrega global y API Management](05-balanceo-entrega-global-y-api-management.md)**
   - Load Balancer, Application Gateway con WAF, Front Door, Traffic Manager y las políticas de API Management.
6. **[Almacenamiento: storage accounts](06-almacenamiento-storage-accounts.md)**
   - Blobs, redundancia de LRS a RA-GZRS, failover, tiers y lifecycle, protección e inmutabilidad, claves frente a SAS frente a Entra ID, Files y managed disks.
7. **[Bases relacionales y caché](07-bases-relacionales-y-cache.md)**
   - Azure SQL Database (vCore, serverless, HA, PITR, failover groups, Entra ID, TDE), PostgreSQL Flexible Server y Azure Managed Redis.
8. **[Cosmos DB](08-cosmos-db.md)**
   - APIs fijas por cuenta, partition key, Request Units, modos de throughput, los cinco niveles de consistencia, change feed, multi-región y el SDK de Java.
9. **[Identidad: Entra ID y managed identities](09-identidad-entra-id-y-managed-identities.md)**
   - Tenant, app registration frente a service principal, managed identities, workload identity federation, tokens y `DefaultAzureCredential`.
10. **[Autorización: Azure RBAC, Policy y gobierno](10-autorizacion-rbac-policy-y-gobierno.md)**
    - Role assignments, `actions` y `dataActions`, propagación, deny assignments, PIM, Azure Policy, locks, tags y landing zones.
11. **[Secretos, cifrado y Key Vault](11-secretos-cifrado-y-key-vault.md)**
    - Key Vault con RBAC, soft-delete y purge protection, Key Vault references, rotación, customer-managed keys, App Configuration y Defender for Cloud.
12. **[Identidad de aplicaciones: OAuth 2.0 con Entra ID](12-identidad-de-aplicaciones-oauth-con-entra-id.md)**
    - Proteger una API Spring Boot: scopes frente a app roles, consentimiento, flujos, una managed identity como cliente y las trampas de la validación del JWT.
13. **[Mensajería y eventos](13-mensajeria-y-eventos.md)**
    - Storage Queues, Service Bus (peek-lock, DLQ, sesiones, duplicate detection), Event Grid, Event Hubs, idempotencia y outbox.
14. **[Observabilidad: Azure Monitor, Log Analytics y Application Insights](14-observabilidad-monitor-log-analytics-app-insights.md)**
    - Métricas y logs, Activity Log, diagnostic settings, KQL, el agente Java de Application Insights, alertas y Resource Graph.
15. **[Bicep e Infrastructure as Code](15-bicep-iac.md)**
    - ARM como estado, Bicep, `what-if`, scopes y modos de despliegue, Deployment Stacks, Azure Verified Modules, drift, y Terraform en comparación.
16. **[Orquestación y CI/CD](16-orquestacion-y-cicd.md)**
    - Durable Functions, Logic Apps, GitHub Actions con OIDC, Azure Pipelines y estrategias de despliegue.
17. **[Resiliencia y Azure Well-Architected Framework](17-resiliencia-y-well-architected.md)**
    - Alta disponibilidad frente a recuperación, SLA compuesto, zonas frente a regiones, patrones de resiliencia, RTO/RPO y DR servicio por servicio.
18. **[Preguntas de entrevista y mapa mental](18-preguntas-entrevista-y-mapa-mental.md)**
    - La simulación: el mapa de asociaciones, 62 preguntas `P#` en cinco niveles y cinco escenarios de arquitectura resueltos.
19. **[Respuestas](19-respuestas.md)**
    - El solucionario centralizado de los capítulos, la simulación, los labs y los apéndices, con el enunciado copiado literal.

### Dónde se practica cada capítulo

Cada capítulo lo declara en su propio encabezado; esta es la vista de conjunto. Que un tema **no** tenga
lab no es un hueco: es una decisión de costo justificada en
[`L00` §4](l00-idea-lab-practico.md#4--el-catálogo-completo-de-exclusiones), y los productos excluidos
tienen un drill opcional en [`L00` §9](l00-idea-lab-practico.md#9--ampliaciones-opcionales).

| Capítulo | Se practica en | Si no, por qué |
|---|---|---|
| [`01`](01-infraestructura-global-y-resource-manager.md) jerarquía y ARM | [`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md), [`L03`](l03-bicep-desde-la-cli.md) | — |
| [`02`](02-redes-vnet-nsg-y-enrutamiento.md) redes | [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md) | Azure Firewall y el peering entre regiones quedan en teoría: cargo base alto |
| [`03`](03-conectividad-privada-y-dns.md) conectividad privada | [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md) | VPN Gateway y ExpressRoute no tienen lab |
| [`04`](04-computo-y-contenedores.md) cómputo | [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) | VMs, App Service y AKS: no enseñan nube o tienen drill |
| [`05`](05-balanceo-entrega-global-y-api-management.md) balanceo y APIM | drills de `L00` §9 | Application Gateway y Front Door tienen cargo base |
| [`06`](06-almacenamiento-storage-accounts.md) storage | [`L02`](l02-entra-id-rbac-y-managed-identities.md), [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md), [`A04`](a04-rutina-de-recurso-cli-api-y-destruccion.md) | — |
| [`07`](07-bases-relacionales-y-cache.md) SQL y caché | drill gratuito de Azure SQL en `L00` §9 | El motor se aprende en un contenedor local |
| [`08`](08-cosmos-db.md) Cosmos DB | [`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md) | — |
| [`09`](09-identidad-entra-id-y-managed-identities.md) identidad | [`L02`](l02-entra-id-rbac-y-managed-identities.md), [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) | Workload identity federation, en el drill de OIDC |
| [`10`](10-autorizacion-rbac-policy-y-gobierno.md) autorización | [`L02`](l02-entra-id-rbac-y-managed-identities.md), [`L03`](l03-bicep-desde-la-cli.md) | PIM exige Entra ID P2 |
| [`11`](11-secretos-cifrado-y-key-vault.md) Key Vault | [`L02`](l02-entra-id-rbac-y-managed-identities.md), [`L05`](l05-container-apps-revisiones-trafico-y-escala.md), [`L09`](l09-costos-y-destruccion-verificada.md) | Managed HSM cobra por hora |
| [`12`](12-identidad-de-aplicaciones-oauth-con-entra-id.md) OAuth con Entra ID | [`L06`](l06-identidad-de-aplicaciones-api-protegida.md) | — |
| [`13`](13-mensajeria-y-eventos.md) mensajería | [`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md) | Event Grid es un drill; Event Hubs se sustituye por Kafka en local |
| [`14`](14-observabilidad-monitor-log-analytics-app-insights.md) observabilidad | [`L08`](l08-observabilidad-kql-y-auditoria.md), [`A05`](a05-kql-de-supervivencia.md) | — |
| [`15`](15-bicep-iac.md) Bicep | [`L03`](l03-bicep-desde-la-cli.md) | Terraform queda en comparación |
| [`16`](16-orquestacion-y-cicd.md) CI/CD | [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) (canary) | GitHub Actions con OIDC es un drill gratuito |
| [`17`](17-resiliencia-y-well-architected.md) resiliencia | ninguno | Es un capítulo de diseño; un DR real cuesta dinero de verdad |

Y al revés: el trabajo de costo y destrucción de
[`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md) y
[`L09`](l09-costos-y-destruccion-verificada.md) **no tiene capítulo teórico**, porque solo se aprende
pagando. Su documento de referencia es [`A02`](a02-costos-trampas-y-recursos-huerfanos.md).

---

## Serie práctica: labs y apéndices

La parte teórica se lee; esta se ejecuta contra una suscripción real. Empieza siempre por el encuadre,
que define **qué entra en el laboratorio de pago y qué no**, el presupuesto y cómo se garantiza que no
quede nada encendido.

- **[`L00` — Introducción a la serie práctica](l00-idea-lab-practico.md)**
  - El contrato: doctrina de reparto entre nube y contenedor local, catálogo de exclusiones
    justificadas, el sistema de inventario que se construye, presupuesto, emuladores y lo que mienten, y
    ampliaciones opcionales.

Los labs son **acumulativos y en orden**. Cada uno declara su costo, su duración y qué deja encendido
al terminar.

| Lab | Tema | Costo | Duración |
|---|---|---|---|
| [`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md) | Suscripción, CLI aislada, providers, tags y budget | $0.00 | 60–90 min |
| [`L02`](l02-entra-id-rbac-y-managed-identities.md) | Entra ID, Azure RBAC, plano de datos y managed identities | $0.00 | 2–3 h |
| [`L03`](l03-bicep-desde-la-cli.md) | Bicep, `what-if`, modo complete, lock, Policy y Deployment Stack | $0.00 | 2–3 h |
| [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md) | VNet, NSG, NAT Gateway, private endpoint y DNS | ~$0.07 | 2–3 h |
| [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) | Container Apps: revisiones, canary, escala y Key Vault reference | ~$0.17 por día de registry | 3 h |
| [`L06`](l06-identidad-de-aplicaciones-api-protegida.md) | Una API protegida: scopes, app roles y validación del JWT | $0.00 | 2–3 h |
| [`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md) | Cosmos DB y Service Bus: idempotencia, `429` y DLQ | ~$0.32 por día de Service Bus | 3–4 h |
| [`L08`](l08-observabilidad-kql-y-auditoria.md) | Observabilidad: KQL, auditoría y alertas | $0.00 | 2–3 h |
| [`L09`](l09-costos-y-destruccion-verificada.md) | Costos y destrucción verificada en capas | $0.00 | 2 h |

> 💰 **Los dos cargos que corren solos** son el Container Registry (por día, desde `L05`) y el
> namespace de Service Bus (por hora, desde `L07`). Hacer `L05`–`L09` en pocos días es lo que mantiene la
> serie por debajo de un dólar; cada lab dice qué borrar si pausas.

Los apéndices no tienen orden ni prerrequisitos: se consultan desde cualquier lab.

- **[`A01` — `az` de supervivencia](a01-az-de-supervivencia.md)** — el perfil aislado con
  `AZURE_CONFIG_DIR`, login y suscripción activa, defaults, `--output`, `--query`, operaciones largas,
  `--debug`, `az rest`, tokens y extensiones.
- **[`A02` — Costos, trampas y recursos huérfanos](a02-costos-trampas-y-recursos-huerfanos.md)** — qué
  es gratis de verdad, qué cobra por existir, qué sobrevive a cada borrado y cómo se verifica un
  teardown.
- **[`A03` — Catálogo de errores y diagnóstico](a03-catalogo-de-errores-y-diagnostico.md)** — cada
  error del curso, por capa, con la causa, el comando que la confirma y la corrección.
- **[`A04` — Rutina de recurso: CLI, API y destrucción](a04-rutina-de-recurso-cli-api-y-destruccion.md)** —
  la pieza que se *hace*: crear, inspeccionar, modificar, destruir y verificar cualquier recurso, desde
  `az`, desde la API y desde el SDK de Java.
- **[`A05` — KQL de supervivencia](a05-kql-de-supervivencia.md)** — los operadores que resuelven el 90 %
  de los diagnósticos, recetas para la aplicación, la auditoría, el costo y el inventario, y las trampas
  que no dan error.

---

## Mapa mental de una aplicación típica

```text
Usuarios
   │
   ▼
Azure DNS
   │
   ▼
Front Door (global, WAF)   ─── o el ingress de Container Apps en un despliegue sencillo
   │
   ├────────────────────┐
   ▼                    ▼
Container Apps       Container Apps
eastus2              centralus
(Spring Boot)        (Spring Boot)
   │  managed identity: ni una credencial guardada
   │
   ├──────────────┬──────────────┬──────────────┬──────────────┐
   ▼              ▼              ▼              ▼              ▼
Azure SQL      Cosmos DB     Blob Storage    Service Bus     Key Vault
(failover      (multi-       (GZRS)          (comandos,      (solo lo que no
 group)         región)                       DLQ)            admite Entra ID)
                                                 │
                                                 ▼
                                            Workers (KEDA, 0 → N)

Entra ID (quién eres) + Azure RBAC y Policy (qué puedes y cómo tiene que quedar) sobre todo.
VNet regional con private endpoints y Private DNS zones debajo de los datos.
Azure Monitor, Log Analytics y Application Insights observando todo; Bicep describiéndolo.
```

> 📝 **Este es el mapa de una aplicación típica, no el del laboratorio.** El sistema que construye la
> serie práctica es deliberadamente más pequeño: una región, sin Front Door ni Azure SQL, y Container
> Apps publicando su propio FQDN HTTPS con certificado administrado sin cobrar por él. La diferencia está
> explicada en [`L00` §5](l00-idea-lab-practico.md#5--el-sistema-que-vas-a-construir).

---

## Asociaciones que conviene memorizar

| Necesidad | Servicio o concepto |
|---|---|
| Geografía y residencia de datos | Region |
| Aislamiento de fallos dentro de la región | Availability Zone |
| Gobierno de muchas suscripciones | Management group |
| Frontera de facturación, cuotas y acceso | Suscripción |
| Ciclo de vida y unidad de borrado | Resource group |
| Plano de gestión de todos los recursos | Azure Resource Manager |
| Red privada (alcance regional) | VNet |
| Filtro stateful por subnet o NIC | NSG |
| Salida a Internet explícita | NAT Gateway |
| Firewall centralizado | Azure Firewall |
| IP privada para una instancia de un servicio | Private endpoint |
| DNS de los private endpoints | Private DNS zone (`privatelink.*`) |
| Contenedores con revisiones y escala a cero | Container Apps |
| Aplicación web sin contenedores, con slots | App Service |
| Kubernetes administrado | AKS |
| Código disparado por eventos | Functions (Flex Consumption) |
| Registry de imágenes | Container Registry |
| Capa 4 regional o global | Load Balancer |
| Capa 7 regional con WAF | Application Gateway |
| Capa 7 global, CDN y WAF | Front Door |
| Balanceo por DNS | Traffic Manager |
| Gestión de APIs | API Management |
| Objetos, archivos, colas simples | Storage account (Blob, Files, Queue) |
| SQL Server administrado | Azure SQL Database |
| PostgreSQL administrado | PostgreSQL Flexible Server |
| Caché | Azure Managed Redis |
| NoSQL distribuido | Cosmos DB |
| Identidades y tokens | Microsoft Entra ID |
| Identidad sin secreto para un recurso | Managed identity |
| Confianza en un token externo (CI/CD) | Workload identity federation |
| Qué puede hacer quién y dónde | Azure RBAC |
| Cómo tienen que quedar los recursos | Azure Policy |
| Protección contra borrado | Resource lock / Deployment Stack |
| Secretos, claves y certificados | Key Vault |
| Configuración y feature flags | App Configuration |
| Comandos con DLQ y sesiones | Service Bus |
| Eventos discretos, push | Event Grid |
| Streams con varios lectores | Event Hubs |
| Logs consultables con KQL | Log Analytics workspace |
| Telemetría de la aplicación | Application Insights |
| Quién hizo qué en el control plane | Activity Log |
| Inventario de recursos | Resource Graph |
| IaC nativa | Bicep |
| Orquestación en código | Durable Functions |
| Integración con conectores | Logic Apps |
| Marco de evaluación de arquitectura | Azure Well-Architected Framework |
| Identidad de clientes finales | Microsoft Entra External ID |

---

## Qué queda fuera del curso

El curso prioriza lo que construye el mapa mental de un backend en Azure. Quedan fuera, y se nombran en
una línea donde un escenario lo pide, sin enseñarlos:

- **analítica**: Microsoft Fabric, Synapse, Data Explorer, Databricks;
- **IA y Machine Learning**;
- **IoT**;
- **escritorios virtuales**.

Y reciben menos profundidad los servicios especializados que no hacen falta para ese mapa: Virtual WAN,
Managed HSM, SQL Managed Instance, Batch, HPC y Sentinel.

---

## Regla de estudio

Para cada servicio intenta contestar seis preguntas. Las cinco primeras te sirven para la entrevista;
la sexta es la que separa a quien ha operado de quien ha leído.

1. **¿Qué problema resuelve?**
2. **¿Es zonal, zone-redundant, regional o global?**
3. **¿Qué plano lo autoriza: control plane con Azure RBAC, o data plane con qué rol?**
4. **¿Cuál es la alternativa más parecida y en qué se diferencia?**
5. **¿Qué fallo o requisito de seguridad cambia el diseño?**
6. **¿Cobra por existir o por uso, y qué queda vivo —o soft-deleted— cuando lo borro?**

La sexta tiene su propio documento: [`A02` — costos, trampas y recursos
huérfanos](a02-costos-trampas-y-recursos-huerfanos.md). Y para cualquier servicio que te intimide antes
de una entrevista, existe un procedimiento fijo —crear, inspeccionar, modificar, destruir, verificar, y
repetirlo desde el SDK— en [`A04` — rutina de recurso](a04-rutina-de-recurso-cli-api-y-destruccion.md).

---

## Referencias oficiales base

- Availability Zones: https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview
- Azure Resource Manager: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/overview
- Virtual Network: https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview
- Elegir un servicio de cómputo: https://learn.microsoft.com/en-us/azure/architecture/guide/technology-choices/compute-decision-tree
- Container Apps: https://learn.microsoft.com/en-us/azure/container-apps/overview
- Cosmos DB: https://learn.microsoft.com/en-us/azure/cosmos-db/overview
- Service Bus: https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-overview
- Microsoft Entra: https://learn.microsoft.com/en-us/entra/fundamentals/what-is-entra
- Azure RBAC: https://learn.microsoft.com/en-us/azure/role-based-access-control/overview
- Azure Monitor: https://learn.microsoft.com/en-us/azure/azure-monitor/fundamentals/overview
- Bicep: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview
- Azure Well-Architected Framework: https://learn.microsoft.com/en-us/azure/well-architected/
- Calculadora de precios: https://azure.microsoft.com/en-us/pricing/calculator/
