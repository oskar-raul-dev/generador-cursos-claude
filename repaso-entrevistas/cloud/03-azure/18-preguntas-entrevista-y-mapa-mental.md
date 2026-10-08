# 18 — Azure Core: preguntas de entrevista y mapa mental

> **Objetivo:** simular una entrevista completa de Azure para un perfil Backend Senior o Software
> Architect. Las preguntas `P#` van sin respuesta inline —están, explicadas, en
> [`19`](19-respuestas.md#18--preguntas-de-entrevista)—; los escenarios de arquitectura del final sí
> conservan su solución desarrollada, porque son ejemplos resueltos y no autochequeo de memoria.
> **Se asume leído:** los capítulos [`01`](01-infraestructura-global-y-resource-manager.md) a
> [`17`](17-resiliencia-y-well-architected.md). Esta simulación no introduce material nuevo: toda
> respuesta sale de uno de ellos, y la tabla del final dice de cuál.
> **Se toca más con:** [`17`](17-resiliencia-y-well-architected.md) (los escenarios se razonan con sus
> pilares, su SLA compuesto y su RTO/RPO) y [`10`](10-autorizacion-rbac-policy-y-gobierno.md) (la
> mitad de las preguntas de nivel Senior son de autorización).
> **Dónde se practica:** en toda la serie [`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md)–[`L09`](l09-costos-y-destruccion-verificada.md). Varias de estas preguntas se contestan mucho
> mejor después de haber provocado el error a propósito en el lab que las cubre.
> **Vigencia:** 29 de septiembre de 2026.

**Salto rápido:** [Cómo usarla](#1--cómo-usar-esta-simulación) ·
[Mapa mental](#2--el-mapa-mental-las-asociaciones-obligatorias) ·
[Los dos árboles](#3--los-dos-árboles-y-el-caso-recurrente) ·
[Junior](#parte-i--junior-refresher) · [Mid](#parte-ii--mid) · [Senior](#parte-iii--senior) ·
[Architect](#parte-iv--software-architect) · [Troubleshooting](#parte-v--troubleshooting) ·
[Escenarios](#parte-vi--escenarios-de-arquitectura) ·
[Autoevaluación](#9--autoevaluación-final) · [Dónde ampliar](#-dónde-ampliar-cada-bloque)

## 1. 🧭 Cómo usar esta simulación

Una entrevista de Azure para backend rara vez pregunta "¿qué es Cosmos DB?". Pregunta por qué tu API
recibe `429` con la base casi ociosa, quién puede leer un secreto que el Owner de la suscripción no
puede leer, o qué pasa con el nombre de un Key Vault después de borrar su resource group. Las
preguntas de este documento están escritas con esa forma, y crecen en dificultad por niveles:

```text
Junior refresher   → vocabulario: si fallas aquí, relee el capítulo entero
Mid                → distinciones: dos cosas parecidas y cuándo cada una
Senior             → las sobregeneralizaciones de entrevista, desmontadas
Software Architect → decisiones con trade-off, costo y operación
Troubleshooting    → un síntoma literal y el orden en que lo diagnosticas
```

La forma de usarla que más rinde es **contestar en voz alta, con cronómetro**: un minuto para las
de Junior y Mid, dos o tres para las de Senior y Troubleshooting, cinco para las de Architect. Después
compara con [`19`](19-respuestas.md#18--preguntas-de-entrevista), que para cada `P#` da la respuesta
y, cuando la hay, la versión incorrecta que conviene no decir.

> 🧠 **Modelo mental.** Una buena respuesta de nivel Senior tiene casi siempre tres tiempos: la
> respuesta corta, el mecanismo que la explica y la excepción o el costo que la matiza. "No, Service
> Bus no garantiza exactly-once; entrega at-least-once con peek-lock; por eso el consumidor es
> idempotente y duplicate detection solo cubre al productor."

---

## 2. 🧭 El mapa mental: las asociaciones obligatorias

Si una línea de este bloque no te sale sola, esa es la pregunta que te van a hacer.

```text
Region                        → geografía y residencia de datos
Availability Zone             → aislamiento de fallos dentro de la región (lógica por suscripción)
Region pair                   → prioridad de recuperación y réplica de GRS; no replica tus recursos
Management group              → gobierno de muchas suscripciones (policies, RBAC)
Subscription                  → frontera de facturación, cuotas y acceso
Resource group                → ciclo de vida, scope de RBAC/Policy/locks y unidad de borrado
Azure Resource Manager (ARM)  → el control plane: todo az es un PUT/GET/DELETE sobre un resource ID
Resource provider             → Microsoft.App, Microsoft.Storage…; se registra por suscripción

VNet                          → red privada regional (abarca todas las zonas de su región)
Subnet                        → segmento de la VNet; privada por defecto en VNets nuevas (2026-03-31)
NSG                           → filtro stateful de 5-tupla en subnet o NIC; no es un firewall central
NAT Gateway                   → salida a Internet explícita y estable
VNet peering                  → une dos VNets; no transitivo → hub-and-spoke
Azure Firewall                → firewall centralizado, por FQDN, en el hub; cobra por hora
Service endpoint              → ruta troncal hacia un servicio entero; sigue siendo IP pública
Private endpoint              → IP privada de UNA instancia en tu subnet
Private DNS zone              → privatelink.*: hace que el nombre público resuelva a la IP privada
168.63.129.16                 → DNS, DHCP y health probes de la plataforma
VPN Gateway / ExpressRoute    → IPsec por Internet / circuito privado sin cifrado por defecto

VM / VM Scale Set             → IaaS; VMSS Flexible es la orquestación recomendada
App Service                   → PaaS web; se escala el plan; slots con swap
Container Apps                → contenedores con revisiones, KEDA y escala a cero, sin API de k8s
AKS                           → Kubernetes administrado, cuando necesitas su API
Functions (Flex Consumption)  → código disparado por eventos; el plan serverless recomendado
Container Registry            → imágenes; se tira con AcrPull + managed identity
Load Balancer                 → capa 4, regional o global
Application Gateway (+ WAF)   → capa 7 regional
Front Door                    → capa 7 global, CDN y WAF en el borde
Traffic Manager               → balanceo por DNS; no es un proxy
API Management                → gestión de APIs: validate-jwt, cuotas, productos, portal

Storage account               → Blob, Files, Queue, Table con UNA redundancia (LRS…RA-GZRS)
Azure SQL Database            → SQL Server administrado; vCore, serverless, failover groups
PostgreSQL Flexible Server    → PostgreSQL administrado; standby HA ≠ read replica
Azure Managed Redis           → caché; sustituye a Azure Cache for Redis (en retiro)
Cosmos DB                     → NoSQL distribuido; API fija al crear; partition key y RU/s

Microsoft Entra ID            → quién eres: el directorio de identidades del tenant
App registration              → definición global de una aplicación (client ID, app roles)
Service principal             → la instancia local que RECIBE los permisos
Managed identity              → service principal cuya credencial administra Azure
Workload identity federation  → confiar en un token externo (GitHub OIDC) sin secreto
Azure RBAC                    → qué puedes hacer y dónde: actions (control) y dataActions (datos)
Deny assignment               → solo lo crean Managed Applications y Deployment Stacks
PIM                           → roles elegibles, just-in-time
Azure Policy                  → cómo tienen que quedar los recursos; nunca da permisos
Resource lock                 → CanNotDelete / ReadOnly; solo control plane
Key Vault                     → secretos, claves y certificados; soft-delete + purge protection
App Configuration             → configuración y feature flags; secretos por referencia a Key Vault
Defender for Cloud            → postura de seguridad; Foundational CSPM gratuito

Storage Queues                → cola simple y barata
Service Bus                   → broker de comandos: peek-lock, DLQ, sesiones, topics
Event Grid                    → eventos discretos push, con handshake de validación
Event Hubs                    → stream particionado que se relee por consumer group

Azure Monitor                 → métricas y logs de todo
Log Analytics workspace       → donde viven los logs y se consultan con KQL
Application Insights          → telemetría de la app (agente Java = OpenTelemetry)
Activity Log                  → control plane, 90 días, sin configurar nada
Diagnostic setting            → sin él, los resource logs no se guardan
Resource Graph                → inventario actual con KQL, gratis

Bicep                         → IaC nativa; compila a ARM JSON; el estado es ARM
what-if                       → el plan de Bicep, antes de cada despliegue
Deployment Stack              → recuerda lo que gestiona, borra lo que sale y crea deny settings
Durable Functions             → orquestación en código, determinista por replay
Logic Apps                    → integración con conectores
GitHub Actions + OIDC         → despliegue sin secretos con una federated credential
Well-Architected Framework    → cinco pilares: Reliability, Security, Cost, Operations, Performance
```

---

## 3. 🧭 Los dos árboles y el caso recurrente

Media entrevista de Azure se decide en este diagrama. Hay **dos árboles que se tocan en un solo
punto**: el de identidad (Entra ID) y el de recursos (ARM). Una suscripción confía en un tenant, y
Azure RBAC cuelga role assignments de los scopes del segundo árbol apuntando a identidades del
primero.

```text
  Árbol de identidad (quién eres)          Árbol de recursos (dónde está y qué puedes hacer)
  ───────────────────────────────          ─────────────────────────────────────────────────
  Tenant de Microsoft Entra ID  ◄──confía── Root management group
   ├── usuarios y grupos                     └── management groups
   ├── app registrations                           └── subscription
   │     └── service principal ──┐                       └── resource group
   └── managed identities ───────┤                             └── recurso
         (service principals)    │
                                 └──► role assignment = principal + role definition + scope
  Roles de Entra ID                         Roles de Azure RBAC
  (Global Administrator…)                   (Owner, Contributor, Storage Blob Data Reader…)
  administran el DIRECTORIO                 administran RECURSOS y DATOS
```

Y el sistema sobre el que razonan casi todas las preguntas, el caso recurrente del curso:

```text
Internet ──► Front Door o ingress de Container Apps
                 │
            Container Apps: inv-api (Spring Boot)    inv-projector
                 │   managed identity: inv-api-id         │  inv-projector-id
     ┌───────────┼──────────────┬──────────────┐          │
     ▼           ▼              ▼              ▼          ▼
 Cosmos DB   Blob Storage   Key Vault     Service Bus ──► topic inv-events
                                                          └─ subscription inv-projector
 sin connection strings ni claves: Entra ID + un rol de datos por identidad
```

---

# Parte I — Junior refresher

Vocabulario. Cada una se contesta en una o dos frases; si necesitas más, sabes menos de lo que crees.

- **P1.** ¿Una VNet es regional o global? ¿Y una subnet?
- **P2.** ¿Qué es un resource group y qué pasa con sus recursos cuando lo borras?
- **P3.** ¿Qué diferencia a una region de una Availability Zone?
- **P4.** ¿Qué es Microsoft Entra ID y cómo se llamaba antes?
- **P5.** ¿Qué es una managed identity, en una frase?
- **P6.** ¿Qué es un NSG y a qué se asocia?
- **P7.** ¿Qué servicios contiene una storage account?
- **P8.** ¿Qué es Bicep y en qué se convierte antes de llegar a Azure?
- **P9.** ¿Container Apps escala a cero por defecto?
- **P10.** ¿Para qué sirve Key Vault?
- **P11.** ¿Qué diferencia a Service Bus de Event Grid, en una frase?
- **P12.** ¿Un budget detiene el gasto cuando se supera?

---

# Parte II — Mid

Distinciones entre dos cosas parecidas. La respuesta buena dice cuándo elegirías cada una.

- **P13.** ¿Qué diferencia a una app registration de un service principal?
- **P14.** ¿Cuándo usarías una user-assigned managed identity y cuándo una system-assigned?
- **P15.** ¿Cuáles son las tres partes de un role assignment y cómo se heredan?
- **P16.** ¿Por qué el Owner de una suscripción no puede leer un blob con Entra ID sin hacer nada más?
- **P17.** ¿Service endpoint o private endpoint: qué diferencia hay?
- **P18.** ¿Qué diferencia a LRS, ZRS, GRS y GZRS?
- **P19.** ¿App Service o Container Apps para una API Spring Boot?
- **P20.** ¿Qué cambios crean una revisión nueva en Container Apps y cómo harías un canary?
- **P21.** ¿Qué modelo de compra de Azure SQL Database recomienda Microsoft y qué te da serverless?
- **P22.** ¿Qué es 1 RU en Cosmos DB y cuál es la operación más barata?
- **P23.** ¿Peek-lock o receive-and-delete en Service Bus?
- **P24.** ¿Qué es la DLQ de Service Bus y cuándo llega un mensaje a ella?
- **P25.** ¿Qué diferencia hay entre el Activity Log y los resource logs?
- **P26.** ¿Qué te dice `what-if` antes de un despliegue de Bicep?
- **P27.** ¿Qué hace Azure Policy que Azure RBAC no hace?
- **P28.** ¿Qué dos preguntas separan Load Balancer, Application Gateway, Front Door y Traffic Manager?

---

# Parte III — Senior

Aquí viven las sobregeneralizaciones. Una respuesta de una palabra, aunque sea la correcta, se queda
corta: el entrevistador quiere el mecanismo y el matiz.

- **P29.** ¿Un rol de Entra ID es lo mismo que un rol de Azure RBAC? ¿Puede el Global Administrator borrar una VM sin hacer nada más?
- **P30.** ¿Azure RBAC tiene un deny que tú puedas escribir?
- **P31.** ¿Por qué no conviene darle roles a una managed identity a través de un grupo?
- **P32.** ¿Qué resuelve workload identity federation frente a un client secret en un pipeline?
- **P33.** ¿Por qué la partition key de Cosmos DB es la decisión que no se deshace, y qué es una hot partition?
- **P34.** ¿Qué nivel de consistencia de Cosmos DB elegirías por defecto y qué garantiza?
- **P35.** ¿Service Bus garantiza exactly-once?
- **P36.** ¿Qué problema resuelve el patrón outbox y cómo lo implementas con Cosmos DB y Service Bus?
- **P37.** ¿Qué le pasa a un Key Vault cuando borras su resource group?
- **P38.** ¿El VNet peering es transitivo? ¿Qué topología resulta de la respuesta?
- **P39.** ¿Scope delegado o app role para proteger una API, y qué claim trae cada uno?
- **P40.** ¿Qué tiene que validar siempre una API que recibe tokens de Entra ID, y qué error típico tiene Spring Boot con los clientes máquina?
- **P41.** ¿Una read replica o una secundaria geo-replicada te sirven como backup?
- **P42.** ¿Qué diferencia hay entre el modo incremental, el modo complete y un Deployment Stack?

---

# Parte IV — Software Architect

Decisiones con trade-off. La respuesta buena nombra el requisito que la dispara, el costo que añade y
la operación que exige; la mala recita un catálogo.

- **P43.** ¿Cómo organizarías management groups, suscripciones y resource groups para una empresa con varios equipos y tres ambientes?
- **P44.** ¿Cuándo justificarías AKS en lugar de Container Apps?
- **P45.** ¿Cómo diseñarías la recuperación ante desastres de una API con RTO de 15 minutos y RPO de 5 minutos?
- **P46.** ¿Zone-redundant o multi-región: cómo lo decides?
- **P47.** ¿Cómo razonarías el SLA compuesto de una cadena Front Door → Container Apps → Azure SQL, y cómo lo mejorarías?
- **P48.** ¿Cómo eliminarías todas las credenciales guardadas de una aplicación Spring Boot en Azure?
- **P49.** ¿Bicep o Terraform para una organización que usa Azure?
- **P50.** ¿Storage Queues, Service Bus, Event Grid o Event Hubs: cómo decides?
- **P51.** ¿Validas el JWT en API Management, en la API o en ambos?
- **P52.** ¿Cómo gobernarías el costo de una organización en Azure?

---

# Parte V — Troubleshooting

Un síntoma literal. Lo que se evalúa es el **orden** del diagnóstico y el comando que confirma cada
hipótesis, no adivinar la causa a la primera.

- **P53.** Tu primer despliegue de Container Apps en una suscripción nueva falla con `MissingSubscriptionRegistration`. ¿Qué pasó?
- **P54.** Acabas de asignar un rol a una managed identity y la aplicación sigue recibiendo `AuthorizationFailed`. ¿Qué miras?
- **P55.** Una app dentro de la VNet resuelve el FQDN de una storage account con private endpoint a una IP pública. ¿Qué revisas?
- **P56.** Una VM sin IP pública no llega a Internet. ¿Qué revisas?
- **P57.** Cosmos DB responde `429` aunque el consumo total de RU/s está muy por debajo de lo provisionado. ¿Qué pasa?
- **P58.** La DLQ de una subscription se llena con `MaxDeliveryCountExceeded` y no hay ninguna excepción en los logs. ¿Qué sospechas?
- **P59.** Te piden saber quién leyó un secreto de Key Vault ayer y no lo encuentras en ningún sitio. ¿Por qué?
- **P60.** Recreas un Key Vault con el mismo nombre después de borrar su resource group y falla. ¿Qué haces?
- **P61.** `az group delete` falla sobre un resource group que quieres destruir. ¿Qué dos causas del curso revisas y cómo haces el teardown?
- **P62.** Tu API Spring Boot rechaza tokens con "The iss claim is not valid" aunque el tenant es el correcto. ¿Cuál es la causa más probable?

---

# Parte VI — Escenarios de arquitectura

Los cinco escenarios que más se repiten en entrevistas de backend con Azure. Cada uno trae el
diagrama, el diseño con su porqué, lo que el entrevistador espera oír y la respuesta que conviene
evitar. No hay una única solución correcta: hay soluciones defendibles y soluciones que no se
sostienen al primer "¿y si…?".

## 4. ⚖ Escenario 1 — Una API Java que no da abasto

**Enunciado.** Una API Spring Boot recibe más solicitudes de las que puede procesar de forma
síncrona: cada orden dispara validaciones y escrituras que tardan segundos, y en los picos la API
devuelve timeouts.

```text
Cliente
  │  POST /orders
  ▼
inv-api (Container Apps)  ──── persiste la orden + evento pendiente (misma transacción)
  │  202 Accepted + Location: /orders/{id}
  ▼
Service Bus (topic o queue)          relay del outbox (change feed)
  │
  ├──► worker réplica 1 ┐
  ├──► worker réplica 2 ├── Container Apps, regla KEDA de Service Bus (0…N réplicas)
  └──► worker réplica N ┘
            │  fallo repetido
            ▼
           DLQ  ──► alerta de métrica sobre dead-lettered messages
```

**Diseño.**

- La API **deja de hacer el trabajo en el request**: valida lo barato, persiste la orden en estado
  `PENDING` y responde `202 Accepted` con la URL donde consultar el estado. El trabajo pesado pasa a
  un mensaje. El cliente deja de esperar segundos y la API deja de acumular hilos bloqueados.
- **Service Bus** y no Storage Queues, porque el trabajo es un comando de negocio que necesita DLQ
  automática, `MaxDeliveryCount`, y quizá orden por cliente con sesiones
  ([`13` §3](13-mensajeria-y-eventos.md#3--service-bus-el-broker-empresarial)).
- **Los workers escalan por mensajes pendientes**, no por CPU: una regla de KEDA de Service Bus en
  Container Apps, autenticada con la managed identity del worker, que baja a cero cuando la cola está
  vacía ([`04` §7](04-computo-y-contenedores.md#7--escalado-con-keda-y-escala-a-cero)). Sin esa regla,
  una app sin ingress se queda en cero réplicas para siempre.
- **Idempotencia en el consumidor**, porque la entrega es at-least-once: un lock que expira entrega
  el mismo mensaje otra vez. Se guarda el id del mensaje procesado junto con su efecto o se usa una
  operación naturalmente idempotente.
- **Outbox** para no perder el evento entre la escritura y la publicación: la orden y su evento
  pendiente se escriben juntos, y un relay los publica
  ([`13` §10](13-mensajeria-y-eventos.md#10--at-least-once-idempotencia-y-outbox)).
- **Backpressure con límites explícitos:** `maxReplicas` en la regla de escalado para no tumbar la
  base de abajo, y una alerta cuando los mensajes activos crecen de forma sostenida. Si la cola
  crece sin parar, la respuesta es mirar la dependencia lenta, no subir réplicas a ciegas.

**Lo que el entrevistador espera oír:** `202` y consulta de estado, cola con DLQ, escalado por
backlog, idempotencia, outbox y un límite superior de réplicas.

> Nunca respondas: "Le subo las réplicas a la API". Más réplicas síncronas trasladan el cuello de
> botella a la base y siguen devolviendo timeouts en el pico; el problema es el acoplamiento temporal,
> no la falta de cómputo.

## 5. ⚖ Escenario 2 — El monolito con la contraseña en el `.properties`

**Enunciado.** Un monolito Spring Boot corre en una VM. La contraseña de la base está en
`application.properties`, el despliegue es copiar un JAR por SSH y nadie sabe qué pasa cuando falla.
Te piden llevarlo a Azure "bien hecho".

```text
GitHub Actions ──OIDC (federated credential, sin secretos)──► Azure
  │ build una vez, imagen por digest
  ▼
Container Registry ──AcrPull (managed identity)──► Container Apps: monolith
                                                     │ user-assigned identity
                          ┌──────────────────────────┼─────────────────────────┐
                          ▼                          ▼                         ▼
                 Azure SQL / PostgreSQL        Key Vault (solo lo que     Application Insights
                 autenticación Entra ID        no admite Entra ID)        agente Java, sin tocar código
```

**Diseño.**

- **Primero la plataforma más administrada que cumpla**: el monolito se empaqueta en una imagen y va
  a **Container Apps**, o a **App Service** si el equipo prefiere desplegar el JAR y usar slots. No
  hace falta AKS: no hay un solo requisito que pida la API de Kubernetes
  ([`04` §12](04-computo-y-contenedores.md#12--la-decisión)).
- **La contraseña desaparece, no se muda.** La app usa una **user-assigned managed identity**; en
  Azure SQL se crea un usuario `FROM EXTERNAL PROVIDER` para ella y el driver JDBC se autentica con
  `ActiveDirectoryManagedIdentity` ([`07` §8](07-bases-relacionales-y-cache.md#8--autenticación-con-entra-id-y-tde)).
  PostgreSQL Flexible Server admite el mismo modelo con Entra ID.
- **Key Vault solo para lo que no admite Entra ID** —la API key de un tercero—, leído con la misma
  identidad y un rol `Key Vault Secrets User`, con fecha de expiración
  ([`11` §1](11-secretos-cifrado-y-key-vault.md#1--el-problema-la-mejor-credencial-es-la-que-no-existe)).
- **La imagen se tira con `AcrPull`** asignado a la identidad, nunca con el admin user del registry.
- **El despliegue deja de ser SSH**: un pipeline con OIDC y una federated credential, que construye
  la imagen una vez y promueve el mismo digest entre ambientes
  ([`16` §5](16-orquestacion-y-cicd.md#5--github-actions-con-oidc)).
- **Observabilidad desde el día uno** con el agente Java de Application Insights, y health probes
  reales (`/actuator/health/liveness` y `/readiness`).

**Lo que el entrevistador espera oír:** managed identity con autenticación de Entra ID en la base,
Key Vault como segunda opción y no como primera, Container Apps o App Service justificados frente a
AKS, pipeline sin secretos y observabilidad.

> Nunca respondas: "Muevo la contraseña a Key Vault y listo". Key Vault centraliza y audita el
> secreto, pero la contraseña sigue existiendo; la base admite Entra ID, así que la credencial buena es
> la que no existe.

## 6. ⚖ Escenario 3 — Un almacén para cada necesidad

**Enunciado.** Una aplicación necesita guardar usuarios, pedidos, sesiones, PDFs, imágenes, eventos
e histórico analítico. ¿Qué pones en cada sitio?

| Necesidad | Servicio | Por qué |
|---|---|---|
| Usuarios y pedidos | Azure SQL Database o PostgreSQL Flexible Server | Relaciones, transacciones multi-fila e integridad referencial |
| Sesiones | Azure Managed Redis | Latencia de milisegundos y expiración por clave; se pierde sin drama |
| PDFs e imágenes | Blob Storage | Objetos con tiers, lifecycle y user delegation SAS para descargar |
| Eventos de negocio | Service Bus (comandos) o Event Hubs (stream) | Según haya un destinatario o varios lectores que releen |
| Histórico analítico | Un almacén analítico, alimentado desde Event Hubs o Blob | Consultas de escaneo masivo que no deben cargar la base operacional |

**Diseño y matices.**

- **La base relacional se queda con lo transaccional.** Pedidos con líneas, pagos y stock que tienen
  que cuadrar en una transacción son el caso de libro de SQL. Cosmos DB entraría si el patrón de
  acceso es por clave a escala global o el esquema varía por documento; se diseña **desde los
  patrones de acceso** y la partition key ([`08` §12](08-cosmos-db.md#12--modelar-desde-los-patrones-de-acceso)).
- **Sesiones en Redis, no en la base**, porque son datos efímeros que se leen en cada petición.
  Azure Managed Redis es el destino: los tiers de Azure Cache for Redis están en retiro, y el cliente
  Java tiene que ir en modo cluster ([`07` §10](07-bases-relacionales-y-cache.md#10--caché-azure-managed-redis)).
- **PDFs e imágenes en Blob, nunca en la base.** La base guarda la ruta; el blob se entrega con una
  user delegation SAS de corta duración. Los PDFs regulatorios, con inmutabilidad; las imágenes
  viejas, a cool o cold por lifecycle.
- **Eventos:** Service Bus si son comandos o eventos que un consumidor debe procesar una vez; Event
  Hubs si son telemetría o un stream que varios sistemas leen a su ritmo y releen.
- **El histórico analítico sale de la base operacional.** El curso no cubre analítica, así que basta
  con nombrarlo: un almacén analítico de Microsoft (Microsoft Fabric) alimentado por el stream o por
  exportaciones a Blob. Lo que se defiende en la entrevista es **la separación**, no el producto.

**Lo que el entrevistador espera oír:** una razón por fila, ligada al patrón de acceso, y la
separación entre lo operacional y lo analítico.

> Nunca respondas: "Cosmos DB para todo, que escala". El criterio es el patrón de acceso de cada
> dato, y un pedido con cinco tablas relacionadas en Cosmos DB es una partition key imposible y
> transacciones que no puedes hacer.

## 7. ⚖ Escenario 4 — Un banco que no quiere nada por Internet

**Enunciado.** El área de seguridad de un banco exige que ningún dato viaje por Internet público: la
aplicación, sus bases, sus colas y sus secretos solo se hablan por red privada, y tiene que poder
demostrarse.

```text
                     Hub VNet (suscripción de conectividad)
            ┌───────────────────────────────────────────────────┐
on-prem ◄──►│ ExpressRoute/VPN   Azure Firewall   DNS Private   │
            │   Gateway          (salida por FQDN) Resolver     │
            └───────────────┬───────────────────────────────────┘
                            │ peering (no transitivo: todo pasa por el hub)
            ┌───────────────┴───────────────────────────────────┐
            │ Spoke VNet de la aplicación                        │
            │  snet-apps: Container Apps environment (ingress    │
            │             interno)                               │
            │  snet-pe:   private endpoints ─► SQL, Blob,        │
            │             Key Vault, Service Bus, Cosmos DB      │
            │  UDR 0.0.0.0/0 ─► Azure Firewall                   │
            └────────────────────────────────────────────────────┘
  Private DNS zones privatelink.* vinculadas a las VNets que resuelven
  publicNetworkAccess = Disabled en cada servicio de datos
  Azure Policy en el management group: lo hace cumplir y lo demuestra
```

**Diseño.**

- **Private endpoints para cada servicio de datos**, uno por subrecurso (blob y queue de una misma
  cuenta son dos), en una subnet dedicada de la spoke ([`03` §3](03-conectividad-privada-y-dns.md#3--private-endpoints-y-private-link)).
- **`publicNetworkAccess = Disabled`** en cada servicio. Crear el private endpoint **no cierra** el
  acceso público; hay que cerrarlo aparte.
- **El DNS es la mitad del diseño.** Private DNS zones con el nombre exacto `privatelink.*`,
  vinculadas a las VNets que resuelven, y un **DNS Private Resolver** en el hub para que on-premises
  resuelva los mismos nombres por un conditional forwarder
  ([`03` §8](03-conectividad-privada-y-dns.md#8--dns-private-resolver-y-la-resolución-híbrida)). La
  aplicación usa el FQDN público de siempre; el DNS decide la IP.
- **Hub-and-spoke con Azure Firewall**: la salida a Internet que quede (actualizaciones, APIs de
  terceros) pasa por el firewall con reglas por FQDN, forzada con una UDR `0.0.0.0/0` en las subnets
  de la spoke ([`02` §10](02-redes-vnet-nsg-y-enrutamiento.md#10--hub-and-spoke-y-azure-firewall)).
- **La aplicación entra por red privada**: el environment de Container Apps integrado en una subnet
  de la spoke con ingress interno; si hay usuarios en Internet, Front Door Premium con Private Link
  hacia el origen, de modo que el origen no tiene endpoint público
  ([`05` §4](05-balanceo-entrega-global-y-api-management.md#4--front-door)).
- **Cumplimiento demostrable con Azure Policy**, asignada en el management group de las landing
  zones: `deny` sobre los recursos de datos con acceso público habilitado, y `deployIfNotExists` para
  que cada private endpoint registre su entrada en la Private DNS zone central. El informe de
  cumplimiento de Policy es lo que se le enseña a auditoría
  ([`10` §10](10-autorizacion-rbac-policy-y-gobierno.md#10--azure-policy)).
- **ExpressRoute no cifra por defecto**: si el requisito es "cifrado en tránsito también en el
  circuito", se añade IPsec encima o MACsec en ExpressRoute Direct.

**Lo que el entrevistador espera oír:** private endpoints con `publicNetworkAccess` deshabilitado, la
cadena DNS explicada, resolución híbrida, salida controlada por el firewall del hub y Policy como
mecanismo de cumplimiento, no como documento.

> Nunca respondas: "Uso service endpoints y ya no pasa por Internet". El servicio sigue con su IP
> pública y el service endpoint abre el tipo de servicio entero, incluida la cuenta de un tercero: no
> protege contra la exfiltración.

> 💰 **Costo.** Este diseño tiene cargos base que corren aunque no haya tráfico: Azure Firewall, el
> gateway de VPN o ExpressRoute y cada private endpoint cobran por hora, y el DNS Private Resolver
> cobra una cuota mensual por cada inbound y outbound endpoint. Por eso ninguno de ellos está en el
> tronco del laboratorio salvo un private endpoint de minutos en [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md)
> ([`L00` §4](l00-idea-lab-practico.md#4--el-catálogo-completo-de-exclusiones) tiene el catálogo con
> precios verificados).

## 8. ⚖ Escenario 5 — Tres equipos, una suscripción y nadie sabe quién gasta qué

**Enunciado.** Tres equipos comparten una única suscripción. La factura sube cada mes, todos tienen
`Contributor` sobre la suscripción y nadie sabe qué recurso es de quién.

```text
Tenant root group
 └── mg-org
      ├── mg-platform ── sub-connectivity, sub-management
      └── mg-landing-zones        ◄── Policy: tags obligatorios y heredados, regiones permitidas
           ├── mg-prod ── sub-payments-prod, sub-cards-prod, sub-loans-prod
           └── mg-nonprod ── sub-payments-dev, sub-cards-dev, sub-loans-dev
                               └── budget por suscripción + action group del equipo
```

**Diseño.**

- **Suscripción por equipo y ambiente**, no una compartida. La suscripción es la frontera de
  facturación, de cuotas y de acceso: separar ahí hace que la factura venga ya repartida y que un
  error en desarrollo no toque producción ([`01` §7](01-infraestructura-global-y-resource-manager.md#7--la-suscripción)).
- **Management groups para gobernar a todas a la vez**: las policies y los role assignments que
  valen para todas se asignan una vez arriba y se heredan
  ([`10` §13](10-autorizacion-rbac-policy-y-gobierno.md#13--tags-landing-zones-y-el-fin-de-blueprints)).
- **Tags obligatorios y heredados por Policy**: los tags **no se heredan** del resource group por sí
  solos, así que se asigna una policy `deny` que exija `cost-center` y `owner` en los resource groups
  y una `modify` que los copie a los recursos, con remediation task para lo que ya existe.
- **Budgets por suscripción y por equipo, con action group**, sabiendo que **un budget solo avisa**:
  no detiene nada. Si el requisito es cortar, hace falta automatización propia disparada por la
  alerta, con el riesgo de apagar producción.
- **RBAC mínimo en el scope justo**: cada equipo, `Contributor` en sus resource groups o su
  suscripción, nunca en la de otro; los pipelines con su identidad propia por ambiente; PIM para los
  roles de Owner.

**Lo que el entrevistador espera oír:** separación por suscripción bajo management groups, tags
impuestos por Policy (no por disciplina), budgets que avisan y RBAC por scope.

> Nunca respondas: "Le pido a cada equipo que etiquete sus recursos". Sin una policy `deny` o
> `modify`, el primer recurso creado con prisa queda sin tag y sin dueño; el gobierno que depende de
> la disciplina dura hasta el primer incidente.

---

## 9. 🧪 Autoevaluación final

Si puedes explicar sin mirar cada una de estas líneas, tienes el núcleo de Azure que se pregunta en
una entrevista de backend Senior o Architect:

1. Region, Availability Zone lógica, region pair; zonal, zone-redundant y no zonal.
2. Management group → suscripción → resource group → recurso; control plane y data plane.
3. VNet regional, subnet privada, NSG stateful en subnet y NIC, NAT Gateway, peering no transitivo.
4. Service endpoint frente a private endpoint, y la cadena DNS de `privatelink`.
5. VM, App Service, Container Apps, AKS y Functions: cuánto administras tú en cada uno.
6. Load Balancer, Application Gateway, Front Door, Traffic Manager y API Management.
7. Redundancias de una storage account, tiers de acceso, SAS y Shared Key deshabilitado.
8. Azure SQL: vCore, serverless, PITR, failover groups; standby HA frente a read replica.
9. Cosmos DB: API fija, partition key, RU/s, cinco consistencias, change feed.
10. Entra ID frente a ARM; app registration, service principal y managed identity.
11. Azure RBAC: `actions` y `dataActions`, scopes, propagación, deny assignments, PIM.
12. Azure Policy frente a RBAC; locks; tags que no se heredan.
13. Key Vault con RBAC, soft-delete, purge protection y lo que sobrevive a `az group delete`.
14. Scopes delegados frente a app roles, `aud`, `iss` y versión de token en Spring Boot.
15. Storage Queues, Service Bus, Event Grid y Event Hubs; at-least-once, idempotencia y outbox.
16. Activity Log, resource logs con diagnostic settings, Log Analytics, KQL y Application Insights.
17. Bicep sin state, `what-if`, modos de despliegue y Deployment Stacks; Terraform en comparación.
18. GitHub Actions con OIDC, blue/green y canary en Container Apps.
19. HA frente a DR, SLA compuesto, RTO/RPO y las cuatro estrategias de DR.

Si alguna no sale de memoria, la respuesta explicada de la `P#` correspondiente está en
[`19`](19-respuestas.md#18--preguntas-de-entrevista), y el capítulo de origen en la tabla de abajo.

---

## 📚 Dónde ampliar cada bloque

Este documento no lleva referencias oficiales propias: es una simulación, y cada tema tiene su
capítulo con su bibliografía verificada al final. La columna de práctica nombra el lab del tronco que
lo cubre; donde no hay lab, remite al drill opcional de [`L00`](l00-idea-lab-practico.md) o dice por qué no se practica.

| Si fallaste en… | Vuelve a | Y practícalo en |
|---|---|---|
| Regiones, zonas, jerarquía, ARM, providers | [`01`](01-infraestructura-global-y-resource-manager.md) | [`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md) |
| VNet, NSG, rutas, peering | [`02`](02-redes-vnet-nsg-y-enrutamiento.md) | [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md) |
| Private endpoints y DNS | [`03`](03-conectividad-privada-y-dns.md) | [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md) |
| Cómputo y contenedores | [`04`](04-computo-y-contenedores.md) | [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) |
| Balanceo y API Management | [`05`](05-balanceo-entrega-global-y-api-management.md) | drills de [`L00` §9](l00-idea-lab-practico.md#9--ampliaciones-opcionales) |
| Storage accounts | [`06`](06-almacenamiento-storage-accounts.md) | [`L02`](l02-entra-id-rbac-y-managed-identities.md) y [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md) |
| Azure SQL, PostgreSQL y Redis | [`07`](07-bases-relacionales-y-cache.md) | drill de Azure SQL en [`L00` §9](l00-idea-lab-practico.md#9--ampliaciones-opcionales) |
| Cosmos DB | [`08`](08-cosmos-db.md) | [`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md) |
| Entra ID y managed identities | [`09`](09-identidad-entra-id-y-managed-identities.md) | [`L02`](l02-entra-id-rbac-y-managed-identities.md) |
| Azure RBAC, Policy y locks | [`10`](10-autorizacion-rbac-policy-y-gobierno.md) | [`L02`](l02-entra-id-rbac-y-managed-identities.md) y [`L03`](l03-bicep-desde-la-cli.md) |
| Key Vault y cifrado | [`11`](11-secretos-cifrado-y-key-vault.md) | [`L02`](l02-entra-id-rbac-y-managed-identities.md) y [`L09`](l09-costos-y-destruccion-verificada.md) |
| OAuth 2.0 y tokens en Spring Boot | [`12`](12-identidad-de-aplicaciones-oauth-con-entra-id.md) | [`L06`](l06-identidad-de-aplicaciones-api-protegida.md) |
| Mensajería y eventos | [`13`](13-mensajeria-y-eventos.md) | [`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md) |
| Observabilidad y KQL | [`14`](14-observabilidad-monitor-log-analytics-app-insights.md) | [`L08`](l08-observabilidad-kql-y-auditoria.md) |
| Bicep | [`15`](15-bicep-iac.md) | [`L03`](l03-bicep-desde-la-cli.md) |
| Orquestación y CI/CD | [`16`](16-orquestacion-y-cicd.md) | [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) y el drill de OIDC de [`L00` §9](l00-idea-lab-practico.md#9--ampliaciones-opcionales) |
| Resiliencia y DR | [`17`](17-resiliencia-y-well-architected.md) | ningún lab; es diseño |
| Costos, cuotas y teardown | [`L00` §6](l00-idea-lab-practico.md#6--presupuesto-y-de-dónde-sale-el-gasto-que-no-esperabas) | [`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md) y [`L09`](l09-costos-y-destruccion-verificada.md) |
